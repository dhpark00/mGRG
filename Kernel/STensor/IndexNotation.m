(********************************************************************)
(************************* IndexNotation.m **************************)
(********************************************************************)

(* Implementation Note:
  - Symmetries should NOT mix dn/up, and different kind of indices. (See checkSymKindDnup.)
  - Shapes of IndexedObjects are defined by IndexKind and Dn/Up for each indices.
  - NB: SetIndices[..] 또는 AddIndices[..] 함수가 실행되면 l* 또는 u* 형태의 심볼에 설정되었던 모든 기억이 지워짐.
  - NB: Due to the ResetDummies, the Plus expressions are RE-ORDERED in the Output phase, which are in general different from the internal order.
    So, to assign the output to a variable the assignment command should be positioned after the running of the previous command, e.g.
        prevCmd
        var = %
 *)
(* Long-term TODO:
  - Introduce TP[obj1, obj2, ...] for non-commutating or anti-commutating indexed objects
 *)

(********************************************************************)
BeginPackage["mGRG`STensor`", {"mGRG`mPerm`"}]

(********************************************************************)
Begin["`Private`"]

(********************************************************************)
(**************************** Utilities *****************************)
(********************************************************************)

(* checks if 'name' satisfies all conditions in the option list 'optL'. 'qHead' is typically HeadQs or IndexQs. *)
AllQoptions[qHead_][name_, optL_List] := AllTrue[qHead /. optL /. Options[qHead], #[name] &] /; MemberQ[{HeadQs, IndexQs}, qHead]

(* True if x is a number or a numeric symbol or a constant symbol. Otherwise False. *)
ConstantQ[_Integer | _Rational | _Real | _Complex] := True
ConstantQ[c_]                                      := NumericQ[c] || constantSymbolQ[c]

    constantSymbolQ[s_Symbol] := MemberQ[Attributes[s], Constant]
    constantSymbolQ[_]        := False

(* checks if 'expr' contains pattern objects. *)
FreePatternQ[expr_] := FreeQ[expr,
                             xSlot|Slot|Pattern|PatternSequence|Blank|BlankSequence|BlankNullSequence|Condition|PatternTest|Repeated|RepeatedNull]

(* In MMA12.0+, PositiveIntegerQ[n_] := Element[n, PositiveIntegers] *)
PositiveIntegerQ[n_Integer?Positive] := True
PositiveIntegerQ[___]                := False

(* returns -1 if a symbolic term 'term' has a leading minus sign (e.g., -x), and 1 otherwise. (cf: SignOfTerm[-1] = 1) *)
SignOfTerm[-term_] := -1
SignOfTerm[_]      :=  1

(* joins symbols or strings into a single symbol *)
SymbolJoin[symbL_List] := Symbol @ StringJoin[ToString /@ symbL]
SymbolJoin[symbs__]    := SymbolJoin[{symbs}]

(********************************************************************)
(* for automatic thread on Equal *)
(*
Unprotect[Equal];
listableQ[f_] := MemberQ[Attributes(f), Listable]
Equal /: lhs:f_Symbol?listableQ[___, _Equal, ___] := Thread[ Unevaluated[lhs], Equal ]
Unprotect[Equal];
 *)

(********************************************************************)
(***************************** Indices ******************************)
(********************************************************************)

(*****
    IndexType
        |- RegularIndexQ[la/ua]        ^= True
        |- DummyIndexQ[l..$../u..$..]  ^= True : produced internally by NewDummy
        |- ComponentIndexQ
            Input:
                numeric:  ...,-2,-1,1,2,...,
                symbolic: (TODO in CTensor) l0, l1, ..., u0, u1, ...
                          (TODO in CTensor) -t, x, -y, z with coordinates (t, x, y, z)
            Output: 1,2,..., or 0, 1, 2, ...

    Lower/Upper

        DnIndexQ[la] ^= True
        UpIndexQ[ua] ^= True

    Examples of IndexKind
        Latin   : la,  ua,..., lo, uo, lp, up,..., lz, uz
        Greek   : l\[alpha], u\[alpha], ..., l\[mu], u\[mu],..., l\[xi], u\[xi],..., l\[Omega], u\[Omega]
        Capital : lA, uA,..., lO, uO, lP, uP,..., lZ, uZ

        BarLatin : lba, uba,..., lbo, ubo, lbp, ubp,..., lbz, ubz
        DotLatin : lda, uda,..., ldo, udo, ldp, udp,..., ldz, udz
        HatLatin : lha, uha,..., lho, uho, lhp, uhp,..., lhz, uhz

    getCharacters[ikind] = {...}

    IndexToKind[la/ua] ^= IndexKind
 *****)

(********** Basic Functions for Indices **********)

(*** index types ***)
ComponentIndexQ[n_Integer]  := True /; n != 0
ComponentIndexQ[___]        := False

DummyIndexQ[___]   := False  (* See NewDummy for any other symbols *)
RegularIndexQ[___] := False  (* See setIndices for any other symbols *)

(*** index dn/up ***)
DnIndexQ[n_Integer] := n < 0
(* DnIndexQ[a_Symbol] : see setIndices and NewDummy *)
DnIndexQ[a_String]  := StringStartsQ[a, "l"] (* MMA12.2+ *)
DnIndexQ[___]       := False

UpIndexQ[a_Integer] := a > 0
(* UpIndexQ[a_Symbol] : see setIndices and NewDummy *)
UpIndexQ[a_String]  := StringStartsQ[a, "u"]
UpIndexQ[___]       := False

(********** Index Kinds **********)

(* return IndexKind -- for a component-index or a symbol-index
          NonKind   -- otherwise *)
IndexToKind[0,        ___]    := NonKind
IndexToKind[_Integer]         := DefaultKind
IndexToKind[_Integer, ikind_] := ikind
(* IndexToKind[_Symbol] : see setIndices *) (* TODO: symbolic components? *)
IndexToKind[idx_String]         := (* NB: This function fully checks the format of the dummy-index structure. *)
    With[{strL = StringSplit[StringDrop[idx, 1], "$"]},          (* when idx = lKIND$123, strL = {KIND, 123} *)
        If [Length[strL] === 2 && IntegerQ[ToExpression @ strL[[2]]],
            With[{ikind = Symbol @ strL[[1]]},
                If [DefinedKindQ[ikind], ikind,
                (* else *)               NonKind]
            ],
        (* else *)
            NonKind
        ]
    ] /; DnIndexQ[idx] || UpIndexQ[idx]
IndexToKind[___] := NonKind

(* is an index associated with ikind? *)
KindIndexQ[ikind_?DefinedKindQ] := (IndexToKind[#] === ikind&)
KindIndexQ[_]                   := (False&)

(* is one-dimensional IndexKind? *) (* TODO: 1D가 꼭 필요한가? *)
(* See setIndices for any other symbols *)
OneDimKindQ[__] := False

(**********)

checkIndexCharacters[charL_List, ikinds_List:definedKindList] :=
    If [IntersectingQ[(getCharacters /@ ikinds) // Flatten, charL],
        Message[Msg::err, charL, "includes character(s) which are already defined.", "", ""]; False,
    (* else *)
        True
    ]

checkName[oName_] := (
        If [MemberQ[reservedNameList, oName],          Message[Msg::err, oName, "is reserved!", "", ""];              Return[False]];
        If [MemberQ[Flatten @ GetIndices[All], oName], Message[Msg::err, oName, "is used as an index name!", "", ""]; Return[False]];
        True
    )

(* defines a new IndexKind with a set of indices *)
defIndexKind[ikind_Symbol, charL:{___String}] := (
        If [!checkName[ikind], Return[False]];
        If [DefinedKindQ[ikind], Message[Msg::err, ikind, "is already defined. Do UndefKind[", ikind, "] first."]; Return[False]];
        If [!checkIndexCharacters[charL], Return[False]];

        AppendTo[definedKindList, ikind];
        setIndices[charL, ikind];
        True
    )

undefIndexKind[ikind_Symbol] := (
        If [ikind === DefaultKind, Message[Msg::err, ikind, "is DefaultKind which cannot be removed.", "", ""]; Return[]];
        If [!DefinedKindQ[ikind], Return[]];

        If [OneDimKindQ[ikind] =!= False, OneDimKindQ[ikind] =.;];  (* TODO: 1D가 필요한 예제 *)
        setIndices[{}, ikind];  (* Unprotect ikind's indices *)
        definedKindList = DeleteCases[definedKindList, ikind];
    )

(* return ComponentIndexQ -- for a component index
          IndexKind       -- for a (non-component and regular) tensorial index
          NonKind         -- otherwise *)
(* NB: only for ValidIndexQ *)
indexClass[_?ComponentIndexQ]          := ComponentIndexQ
indexClass[idx_Symbol?TensorialIndexQ] := IndexToKind[idx]
indexClass[___]                        := NonKind

(* internal engine for setting up index properties *)
setIndices[charL:{___String}, ikind_Symbol, appendQ_:False] := (
    If [!CheckKind[ikind], Return[$Failed]];

    (* Unprotect and TagUnset previously introduced regular-index symbols, if not appending *)
    If [!appendQ,
        If [Head[getCharacters[ikind]] === List && getCharacters[ikind] =!= {},  (* guard re-set *)
            With[{lsymL = Symbol["Global`l" <> #]& /@ getCharacters[ikind],
                  usymL = Symbol["Global`u" <> #]& /@ getCharacters[ikind]},

                Unprotect @@ lsymL; Unprotect @@ usymL;

                (# /: DnIndexQ[#] =.)& /@ lsymL;
                (# /: UpIndexQ[#] =.)& /@ usymL;

                (# /: RegularIndexQ[#] =.)& /@ Join[lsymL, usymL];
                (# /: IndexToKind[#] =.)&   /@ Join[lsymL, usymL];
            ]
        ]
    ];

    (* Clear index symbols. NB: Clear in String form to suppress evaluating *)
    (* NB: THE SYMBOLS having the form 'l*' and 'u*' will be CLEARED all! *)
    Clear /@ (("Global`l" <> #)& /@ charL); Clear /@ (("Global`u" <> #)& /@ charL);

    With[{lsymL = Symbol["Global`l" <> #]& /@ charL,
          usymL = Symbol["Global`u" <> #]& /@ charL},

        (* TagSet to index symbols *)
        (# /: DnIndexQ[#] = True)& /@ lsymL; (# /: DnIndexQ[#] = False)& /@ usymL;
        (# /: UpIndexQ[#] = True)& /@ usymL; (# /: UpIndexQ[#] = False)& /@ lsymL;

        (# /: RegularIndexQ[#] = True)& /@ Join[lsymL, usymL];
        (# /: IndexToKind[#] = ikind)&  /@ Join[lsymL, usymL];

        (* Protect index symbols *)
        Protect @@ lsymL; Protect @@ usymL
    ];

    (* update the list of all characters for the ikind *)
    getCharacters[ikind] = If [appendQ, Join[getCharacters[ikind], charL],  (* AddIndices *)
                           (* else *)   charL];                             (* SetIndices *)

    (* update the 1D ikind property *) (* TODO: 1D가 꼭 필요한가? *)
    OneDimKindQ[ikind] = (Length[getCharacters[ikind]] === 1);
)

(********** SetIndices, AddIndices, DropIndices, and GetIndices **********)

AddIndices[char_String,      ikind_Symbol] := AddIndices[{char}, ikind]
AddIndices[charL:{__String}, ikind_Symbol] :=
    If [checkIndexCharactersKind[charL, ikind],
        setIndices[Complement[charL, getCharacters[ikind]], ikind, True]
    ] /; DefinedKindQ[ikind]
AddIndices[___] := Message[AddIndices::usage]

DropIndices[char_String,      ikind_] := DropIndices[{char}, ikind]
DropIndices[charL:{__String}, ikind_] := setIndices[Complement[getCharacters[ikind], charL], ikind] /; DefinedKindQ[ikind]

SetIndices[{},               ikind_Symbol] := setIndices[{}, ikind]
SetIndices[charL:{__String}, ikind_Symbol] := If [checkIndexCharactersKind[charL, ikind], setIndices[charL, ikind]] /; DefinedKindQ[ikind]
SetIndices[__] := Message[SetIndices::usage]

(* get all regular indices in String form *)
GetIndices[All]          := Join[GetIndices /@ definedKindList]
GetIndices[ikind_Symbol] := Flatten[{SymbolJoin["l", #]& /@ getCharacters[ikind],
                                     SymbolJoin["u", #]& /@ getCharacters[ikind]}] /; DefinedKindQ[ikind]
GetIndices[__] := Message[GetIndices::usage]

(**********)

(* checkIndexCharacters with Complement[definedKindList, {ikind}] *)
checkIndexCharactersKind[charL_, ikind_] := checkIndexCharacters[charL, DeleteCases[definedKindList, ikind]]

(********** Utils for Indices **********)

(* gives an unique dummy pair in the form: {dn,up}  *)
NewDummy[ikind_?OneDimKindQ] := {SymbolJoin["l", #]& /@ getCharacters[ikind],
                                 SymbolJoin["u", #]& /@ getCharacters[ikind]} // Flatten
NewDummy[ikind_Symbol]       :=
    Module[{str},
        If [!CheckKind[ikind], Return[$Failed]];

        str = ToString[Unique[ikind]];
        With[{dn = Symbol @ ("l" <> str), up = Symbol @ ("u" <> str)},
            (* TagSet to the index symbols *)
            dn /: DummyIndexQ[dn] = True;
            dn /: DnIndexQ[dn]    = True;
            dn /: IndexToKind[dn]   = ikind;

            up /: DummyIndexQ[up] = True;
            up /: UpIndexQ[up]    = True;
            up /: IndexToKind[up]   = ikind;
  
            SetAttributes[Evaluate[{dn, up}], Temporary];
            {dn, up}
        ]
    ]

(* dn <-> up *)
FlipIndex[a_Integer]         := -a
FlipIndex[a_Symbol]          := Symbol[ FlipIndex[ToString @ a] ]
FlipIndex[a_String?DnIndexQ] := StringReplacePart[a, "u", {1,1}]
FlipIndex[a_String?UpIndexQ] := StringReplacePart[a, "l", {1,1}]
FlipIndex[a_]                := a

(* up -> dn *)
ToDnIndex[a_?UpIndexQ] := FlipIndex[a]
ToDnIndex[a_]          := a  (* if not UpIndexQ *)

(* dn -> up *)
ToUpIndex[a_?DnIndexQ] := FlipIndex[a]
ToUpIndex[a_]          := a  (* if not DnIndexQ *)

IndexOrderedQ[idxL1_?VectorQ, idxL2_?VectorQ] :=  (* rule1 *) (* 주의: 규칙 선언의 순서를 유지할 것 *)
    With[{len1 = Length[idxL1], len2 = Length[idxL2]},
        If [len1 =!= len2,
            len1 < len2,
        (* else *)
            Catch[
                Do[
                    If [idxL1[[i]] =!= idxL2[[i]], Throw[ IndexOrderedQ[{idxL1[[i]], idxL2[[i]]}] ]],
                    {i, len1}
                ];
                True
            ]
        ]
    ]
IndexOrderedQ[idxL_?VectorQ] := idxL === IndexSort[idxL]  (* rule2 *)

IndexSort[{}]          := {}
IndexSort[{a_}]        := {a}
IndexSort[indexL_List] :=
    With[{pairIndexSort = takePairs[indexL], lexIndexSort = Union[ToUpIndex /@ indexL]},
        Last /@
            Sort[  (* 네 가지 우선 순위에 따른 인덱스 정렬 *)
                {
                    typeIndexSort[#],                           (* (Tensorial/Component) and Kind *)
                    MemberQ[pairIndexSort, #],                  (* Free/Dummy *)
                    Position[lexIndexSort, ToUpIndex[#], {1}],  (* Lexicographic *)
                    UpIndexQ[#],                                (* Dn/Up *)
                    #
                }& /@ indexL
            ]
    ]

    typeIndexSort[a_Symbol?TensorialIndexQ] :=
        With[{ikind = IndexToKind[a]},
            If [ikind === NonKind,
                1.0,
            (* else *)
                1.0 + 0.1 * (First @ Flatten @ Position[definedKindList, ikind])
            ]
        ]
    typeIndexSort[_Integer?ComponentIndexQ] := 7  (* numeric ComponentIndexQ *)
    typeIndexSort[_]                        := 9  (* any others *)

PairIndexQ[_Integer,         _]        := False
PairIndexQ[_,                _Integer] := False
PairIndexQ[a_Symbol,         b_Symbol] := False /; OneDimKindQ[IndexToKind @ a] || OneDimKindQ[IndexToKind @ b]
PairIndexQ[a_Symbol,         b_Symbol] := strPairQ[ToString @ a, ToString @ b]
PairIndexQ[pairs:({_, _}..)]           := And @@ (PairIndexQ[#[[1]], #[[2]]]& /@ {pairs})
PairIndexQ[___]                        := False

    strPairQ[a_String, b_String] := If [StringDrop[a, 1] === StringDrop[b, 1], True,
                                    (* else *)                                 False] /; !UpupDndnIndexQ[{a, b}]
    strPairQ[_, _] := False

(* gives contracted pairs in the form: {{dn,up},..}. *) (* 주목: 인덱스의 원래 순서를 유지하지 않음 *)
TakePairs[indexL_?VectorQ, iOpts___Rule] :=  (* {ub, la, lc, ud, lb, ua} => {{lb,ub}, {la,ua}} *)
    With[{idxL = Select[indexL, AllQoptions[IndexQs][#, {iOpts}]&]},
        {#, ToUpIndex[#]}& /@ Union[ToDnIndex /@ takePairs[idxL]]
    ]
TakePairs[___] := (Message[TakePairs::usage]; {})

(* are the tensorial indices duplicated? *)
DuplicatedIndicesQ[indexL_List, withMsg_:False] :=
    With[{idxL = Select[indexL, TensorialIndexQ]},
        If [Length[DeleteDuplicates[idxL]] =!= Length[idxL],
            If [withMsg, Message[Msg::err, "duplicated indices:", idxL, "", ""]];
            True,
        (* else *)
            False
        ]
    ]
DuplicatedIndicesQ[___] := False

(* is a non-component index? *)
TensorialIndexQ[a_]  := RegularIndexQ[a] || DummyIndexQ[a]
TensorialIndexQ[___] := False

(* are all dn or all up? *)
UpupDndnIndexQ[aIndexL_List] := SameQ @ (Sequence @@ Map[UpIndexQ, aIndexL])

(**********)

(* dn => -1, up => +1 *)
dnupState[idx_] := If [UpIndexQ[idx], 1, -1]

(* take free-tensorial indices. *)
takeTensorialFrees[indexL_List] := dropPairs @ Select[indexL, TensorialIndexQ]

(* drop or take not-sorted pairs from the indices *)
dropPairs      [indexL_List] := Select[indexL, !inPairQ[indexL, #]&]
takePairs      [indexL_List] := DeleteDuplicates @ Select[indexL, inPairQ[indexL, #]&]  (* 예: {ub, la, lc, ud, lb, ua} => {ub,la, lb, ua}} *)
takePairsProper[indexL_List] :=  (* 예: {ub, la, lc, ud, lb, ua} => {{ub,lb}, {la,ua}} *)
    With[{pairL = takePairs[indexL]},  (* 주목: TakePairs 함수와는 달리 인덱스 원래의 순서를 유지함 *)
        With[{tmpL =
                Fold[
                    Join,
                    {},
                    If [inPairQ[Drop[pairL, #], pairL[[#]]], {pairL[[#]]},
                    (* else *)                               {}]& /@ Range[Length[pairL]]
                ]},

            {#, FlipIndex[#]}& /@ tmpL
        ]
    ]

    inPairQ[indexL_, a_] :=
        With[{fa = FlipIndex[a]},  (* NB: When 'a' is NOT an index, FlipIndex[a] == a. *)
            TensorialIndexQ[a] && !OneDimKindQ[IndexToKind @ a] && (fa =!= a && MemberQ[indexL, fa])
        ]

(************************* Kind Structures **************************)

CheckKind[kindL_List] := And @@ (CheckKind /@ kindL)
CheckKind[kind_]      := DefinedKindQ[kind] || (Message[General::invalid, kind, "kind"]; False)

DefinedKindQ[kind_Symbol] := MemberQ[definedKindList, kind]
DefinedKindQ[___]         := False

DefKind[kind_Symbol, charL:{___String}, dimension_:Null] := (
        If [!defIndexKind[kind, charL], Return[$Failed]];

        (* properties of the 'kind' *)
        If [dimension =!= Null, GetDimension[kind] = dimension];

        (* predefined tensors *)
        If [Length[charL] > 1,  (* For non-1D *)
            (* define Epsilon, Structuref, and Torsion associated with the kind *)
            If [kind =!= DefaultKind,
                defineOperand[SymbolJoin[Epsilon, kind], "*-",   {kind}, {-1},        IndexedTensorQ, PrintAs -> "\[Epsilon][" <> ToString[kind] <> "]"];
                defineOperand[SymbolJoin[Torsion, kind], "-bac", {kind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> "t[" <> ToString[kind] <> "]"];
                GetEpsilon[kind]    = SymbolJoin[Epsilon, kind];
                GetStructuref[kind] = SymbolJoin[Structuref, kind];
                GetTorsion[kind]    = SymbolJoin[Torsion, kind],
            (* else *)
                defineOperand[Epsilon, "*-",   {kind}, {-1},        IndexedTensorQ, PrintAs -> "\[Epsilon]"];
                defineOperand[Torsion, "-bac", {kind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> "t"];
                GetEpsilon[kind]    = Epsilon;
                GetStructuref[kind] = Structuref;
                GetTorsion[kind]    = Torsion
            ],
        (* else *)
            GetEpsilon[kind]    = Null;
            GetStructuref[kind] = Null;
            GetTorsion[kind]    = Null
        ];

        getDerOperators[kind] = {};
        MetricSpaceQ[kind] = False;
        GetMetric[kind]    = Null;

        With[{flag = If [MemberQ[{True, False}, CoordinateBasisQ[kind]],  CoordinateBasisQ[kind],
                     (* else *)                                           False]},
            If [flag, On[CoordinateBasisFlag[kind]], Off[CoordinateBasisFlag[kind]]]
        ];
        flagTable[EvaluateBDFlag[kind]] = False;
    )

UndefKind[Latin]       := ( Message[Msg::err, "Cannot remove the Latin kind.", "", "", ""]; )
UndefKind[kind_Symbol] := (
        If [kind === DefaultKind, Message[Msg::err, "DefaultKind cannot be removed."]; Return[$Failed]];
        If [!DefinedKindQ[kind], Return[]];

        (* no need to call ClearDimension[kind] because the 'kind' will be removed. *)
        undefIndexKind[kind];

        (* clear properties *)
        removeObject /@ {GetEpsilon[kind], GetStructuref[kind], GetTorsion[kind]};
        GetEpsilon[kind]    =.;
        GetStructuref[kind] =.;
        GetTorsion[kind]    =.;

        getDerOperators[kind]  =.;
        MetricSpaceQ[kind]     =.;
        CoordinateBasisQ[kind] =.;

        flagTable[EvaluateBDFlag[kind]] =.;

        definedKindList = DeleteCases[definedKindList, kind];

        (* finally remove kind *) 
        If [kind =!= Dot, Remove[kind]];
    )

(* are two kinds compatible with each other? *)
KindMatchQ[NonKind,      _]            := False
KindMatchQ[_,            NonKind]      := False
KindMatchQ[All,          _]            := True
KindMatchQ[_,            All]          := True
KindMatchQ[kind1_Symbol, kind2_Symbol] := kind1 === kind2
KindMatchQ[__]                         := False

(********** Coordinates, Dimension, and Sig **********)

SetCoordinates[coSys_ /; VectorQ[coSys, AtomQ]]              := SetCoordinates[coSys, DefaultKind]
SetCoordinates[coSys_ /; VectorQ[coSys, AtomQ], kind_Symbol] := (
        If [!CheckKind[kind], Return[$Failed]];
        If [!CoordinateBasisQ[kind],
            Message[Msg::err, "use SetCoordinates[coSys, basis] for non-coordinate basis", "", "", ""]; Return[$Failed]
        ];

        With[{nDim = Length[coSys], kDim  = GetDimension[kind]},
            If [PositiveIntegerQ[kDim] && nDim =!= kDim,
                Message[Msg::err, "incompatible number of coordinates with dimension", kDim, "", ""]; Return[$Failed]
            ];
            GetCoordinates[kind] = coSys;
            GetDimension[kind]   = nDim;
        ];
    )
SetCoordinates[coSys_ /; VectorQ[coSys, AtomQ], basis_List?SquareMatrixQ]              := SetCoordinates[coSys, basis, DefaultKind]
SetCoordinates[coSys_ /; VectorQ[coSys, AtomQ], basis_List?SquareMatrixQ, kind_Symbol] := (
        If [!CheckKind[kind], Return[$Failed]];
        If [CoordinateBasisQ[kind],
            Message[Msg::err, "Use SetCoordinates[coSys] for coordinate basis", "", "", ""]; Return[$Failed]
        ];

        With[{nDim = Length[coSys]},
            If [nDim =!= Length[basis[[1]]],
                Message[Msg::err, "incompatible number of elements between coSys and basis", "", "", ""]; Return[$Failed]
            ];

            With[ {kDim = GetDimension[kind]},
                If [PositiveIntegerQ[kDim] && nDim =!= kDim,
                    Message[Msg::err, "incompatible number of coordinates with dimension", kDim, "", ""]; Return[$Failed]]
            ];

            GetCoordinates[kind] = coSys;
            GetDimension[kind]   = nDim;
            basisMatrix[kind]    = basis;  (* basis matrix h_a^{\mu}, where \xi_a = h_a^\mu \pd_\mu *)
        ];
    )
SetCoordinates[__] := Message[SetCoordinates::usage]

ClearCoordinates[kind_Symbol] := (
        If [CheckKind[kind] && VectorQ[GetCoordinates[kind], AtomQ],
            GetDimension[kind]   =.;
            GetCoordinates[kind] =.;
            If [!CoordinateBasisQ[kind], basisMatrix[kind] =.]
        ];
    )
ClearCoordinates[__] := Message[ClearCoordinates::usage]

SetDimension[n_?PositiveIntegerQ]              := SetDimension[n, DefaultKind]
SetDimension[n_?PositiveIntegerQ, kind_Symbol] := (
        If [!CheckKind[kind], Return[$Failed]];

        GetDimension[kind] = n;
    )
SetDimension[__] := Message[SetDimension::usage]

ClearDimension[kind_Symbol] := (
        If [!CheckKind[kind], Return[$Failed]];

        If [ValueQ[GetDimension[kind]], GetDimension[kind] =.];
    )
ClearDimension[__] := Message[ClearDimension::usage]

(* sig is the number of negative eigenvalues of the metric *)
SetSig[sig_Integer]              := SetSig[sig, DefaultKind]
SetSig[sig_Integer, kind_Symbol] := (
        If [!CheckKind[kind], Return[$Failed]];

        GetSig[kind] = sig;
    )
SetSig[__] := Message[SetSig::usage]

ClearSig[kind_Symbol] := (
        If [!CheckKind[kind], Return[$Failed]];

        If [ValueQ[GetSig[kind]], GetSig[kind] =.];
    )
ClearSig[__] := Message[ClearSig::usage]

(********** Show **********)

Unprotect[Show]
Show[kind_?DefinedKindQ] := (
        With[{flagStrL0 =
                If [kind === DefaultKind,
                    {"AutoFlag", "MarkErrorFlag", "ResetDummiesFlag", "SyntaxCheckFlag",
                     "KdeltaFlag", "MetricgFlag",
                     "InitCTensorFlag", "TorsionFreeQ of CD", "----------"},
                 (* else *)
                    {}
                ],
              flagL0 =
                If [kind === DefaultKind,
                    {flagTable[AutoFlag], flagTable[MarkErrorFlag], flagTable[ResetDummiesFlag], flagTable[SyntaxCheckFlag],
                     flagTable[KdeltaFlag], flagTable[MetricgFlag],
                     flagTable[InitCTensorFlag], TorsionFreeQ[CD], "-----"},
                (* else *)
                    {}
                ]},
            With[{flagStrL1 = Join[flagStrL0, {"Kind", "Dimension", "Sig", "Coordinates", "CoordinateBasisQ", "EvaluateBDFlag"}],
                  flagL1 = Join[flagL0,
                                {kind},
                                With[{nDim = GetDimension[kind]}, If [PositiveIntegerQ[nDim], {nDim}, {"Any"}]],
                                With[{sig  = GetSig[kind]}, If [IntegerQ[sig],          {sig},  {"Any"}]],
                                If [VectorQ[GetCoordinates[kind]], {GetCoordinates[kind]}, {"none"}],
                                {CoordinateBasisQ[kind]},
                                {flagTable[EvaluateBDFlag[kind]]}]},
                TableForm[Transpose[{flagStrL1, flagL1}]]
            ]
        ]
    )
Protect[Show]

(********** Check Indices **********)

(* Check consistency of an index (and each of aIndexL) with the second argument 'indexClass' *)
ValidIndexQ[aIndex_]                                         := ValidIndexQ[aIndex, DefaultKind, False]
ValidIndexQ[aIndexL_List,            class_, withMsg_:False] := AllTrue[aIndexL, ValidIndexQ[#, class, withMsg]&]
ValidIndexQ[0,                       _,      withMsg_:False] := ( If [withMsg, Message[General::invalid, 0, "component index"]]; False )
ValidIndexQ[aIndex_?ComponentIndexQ, kind_,  withMsg_:False] :=
    With[{nDim = GetDimension[kind]},
        If [PositiveIntegerQ[nDim] && Abs[aIndex] > nDim,
            If [withMsg, Message[Msg::err, "The value of a component index", Abs[aIndex], "is larger than the dimension", nDim]];
            False,
        (* else *)
            True
        ]
    ] /; kind =!= NonKind
ValidIndexQ[aIndex_, class_, withMsg_:False] :=
    compatibleIndexKindQ[aIndex, class] || (If [withMsg, Message[General::invalid, aIndex, "index"]]; False)
ValidIndexQ[___] := False

    (* 주목: Component 인덱스는 모든 IndexKind의 인덱스들과 서로 부합한다 *)
    compatibleIndexKindQ[aIndex_,                 ComponentIndexQ] := compatibleKindQ[aIndex, All]
    compatibleIndexKindQ[aIndex_,                 All]             := IndexToKind[aIndex] =!= NonKind
    compatibleIndexKindQ[aIndex_?ComponentIndexQ, _Symbol]         := True
    compatibleIndexKindQ[aIndex_Symbol,           kind_Symbol]     := (IndexToKind[aIndex] === kind)  \
                                                                      || MemberQ[GetCoordinates[kind], aIndex] (* TODO: 꼭 필요한가? *)
    compatibleIndexKindQ[___]                                      := False

(* Check mutual-validity of indices. return False with a corresponding message when withMsg == True. *)
ValidIndicesQ[indexL_List]                         := ValidIndicesQ[indexL, DefaultKind, False]
ValidIndicesQ[indexL_List, class_, withMsg_:False] := (
        If[!ValidIndexQ[indexL, class, withMsg], Return[False]];
        !DuplicatedIndicesQ[indexL, withMsg]
    )
ValidIndicesQ[___] := False

(********************************************************************)
(************************** IndexedObject ***************************)
(********************************************************************)

(*****
    ObjectQ |- IndexedObjectQ |- IndexedOperatorQ
            |                 |- IndexedOperandQ  |- IndexedTensorQ
            |                                     |- DiffFormQ
            |                                     |- IndexedSpinorQ (TODO: QFT using ToCanonical)
            |                                     |- IndexedSymbolQ (TODO: Symbolize and colourize)
            |
            |- ScalarFunctionQ

    Tensors:

        IndexedObjectQ[oName]  ^= True
        IndexedOperandQ[oName] ^= True

        getType  [oName] ^= IndexedTensorQ
        getDnupL [oName] ^= dnupL
        getGenSet[oName] ^= GenSet
        getKindL [oName] ^= kindL
        getPrtStr[oName] ^= prtStr
        getRank  [oName] ^= nRank

            dnupL = |- {}         for zero rank tensors
                    |- {dnup}     for one, or arbitrary rank tensors with all the 'same' dnup
                    |- {dnup,...} for fixed rank tensors with different dnups

                    dnup = -1 or +1

            kindL = |- {kind}     for zero, one, or arbitrary rank tensors with all the 'same' kind
                    |- {kind,...} for fixed rank tensors with various kinds

                    kind = one of the definedKindList

            oName[indices]

                number of indices === (nRank or arbitrary)

    Diff. Forms:

        IndexedObjectQ[fName]  ^= True
        IndexedOperandQ[fName] ^= True

        getType  [oName] ^= DiffFormQ
        getDegree[fName] ^= formDegree
        getDnupL [fName] ^= dnupL
        getGenSet[fName] ^= GenSet
        getKindL [fName] ^= kindL
        getPrtStr[fName] ^= prtStr
        getRank  [fName] ^= nRank

            fName[indices]

    Indexed Operators:

        IndexedObjectQ[opName]   ^= True
        IndexedOperatorQ[opName] ^= True

        getType  [opName] ^= opType
        getKindL [opName] ^= kindL
        getPrtStr[opName] ^= prtStr

            opType:
                CD: opName[index, expr] like the covariant derivative
                LD: opName[vName, expr] like the Lie derivative
                XD: opName[expr]        like the exterior derivative
                XP: opName[expr,...]    like the exterior product

            opName[arg, expr,...]

    ScalarFunctionQ === Tscalar, Power, Log, Sin, ...
 *****)

(********** Indexed ObjectQ *************)

(* remove indexed objects if not reserved *)
RemoveIndexedObject[oName_Symbol?IndexedObjectQ] := (
        If [MemberQ[reservedNameList, oName], Message[Msg::err, "Reserved name", oName, "cannot be removed!", ""]; Return[]];
        removeObject[oName];
  )
RemoveIndexedObject[nameL:{_Symbol..}] := ( Map[RemoveIndexedObject, nameL]; )

removeObject[oName_?IndexedObjectQ] := ( Unprotect[oName]; Remove[oName]; )

(* is oName defined? *)
ObjectQ[oName_Symbol] := IndexedObjectQ[oName] || ScalarFunctionQ[oName]
ObjectQ[___]          := False

    IndexedObjectQ[___] := False

        IndexedOperandQ[___] := False

            IndexedTensorQ[tName_?IndexedOperandQ] := getType[tName] === IndexedTensorQ
            IndexedTensorQ[___]                    := False

            DiffFormQ[fName_?IndexedOperandQ] := getType[fName] === DiffFormQ
            DiffFormQ[___]                    := False

        IndexedOperatorQ[___] := False

    (* Tscalar, Power, Log, Sin, Cos, Tan, ... *)
    ScalarFunctionQ[f_Symbol] := MemberQ[Attributes[f], NumericFunction] && f =!= Plus && f =!= Times
    ScalarFunctionQ[Tscalar]  := True;
    ScalarFunctionQ[___]      := False;

(********* Defining Tensors ************)

DefTensor = Tdefine  (* alias *)

UndefTensor[oName_?IndexedTensorQ] := (
        oName/: MakeBoxes[oName[args___], StandardForm] =.;
        oName/: getDnupL[oName] =.;
        oName/: getGenSet[oName] =.;
        oName/: getKindL[oName] =.;
        oName/: getPrtStr[oName] =.;
        oName/: getRank[oName] =.;
        oName/: getType[oName] =.;
        oName/: IndexedOperandQ[oName] =.;
        oName/: IndexedObjectQ[oName] =.;
    )
UndefTensor[___] := Message[UndefTensor::usage]

(* zero-rank *)
Tdefine[oName_Symbol,                opts:OptionsPattern[]] := Tdefine[oName[], opts]
Tdefine[oName_Symbol,   kind_Symbol, opts:OptionsPattern[]] := Tdefine[oName[], kind, opts]
Tdefine[oName_Symbol[],              opts:OptionsPattern[]] := Tdefine[oName[], DefaultKind, opts]
Tdefine[oName_Symbol[], kind_Symbol, opts:OptionsPattern[]] := tDefineOperand[oName, "", {kind}, {}, IndexedTensorQ, opts]

(* finite rank and any symmetric *)
Tdefine[oName_Symbol, nRank_Integer?Positive,              opts:OptionsPattern[]] := Tdefine[oName, nRank, DefaultKind, opts]
Tdefine[oName_Symbol, nRank_Integer?Positive, kind_Symbol, opts:OptionsPattern[]] := Tdefine[oName, ToString @ nRank, kind, opts]
Tdefine[oName_Symbol, permS_String,                        opts:OptionsPattern[]] := Tdefine[oName, permS, DefaultKind, opts]
Tdefine[oName_Symbol, permS_String,           kind_Symbol, opts:OptionsPattern[]] :=
    tDefineOperand[oName, permS, {kind}, If [permS === "", {}, {-1}], IndexedTensorQ, opts]  (* updnL의 default는 {-1} *)

Tdefine[oName_Symbol[shapes:((_Symbol)..)],                         opts:OptionsPattern[]] := Tdefine[oName[shapes], ToString @ Length[{shapes}], opts]
Tdefine[oName_Symbol[shapes:((_Symbol)..)], nRank_Integer?Positive, opts:OptionsPattern[]] := Tdefine[oName[shapes], ToString @ nRank, opts]
Tdefine[oName_Symbol[shapes:((_Symbol)..)], permS_String,           opts:OptionsPattern[]] :=
    tDefineOperand[oName, permS, IndexToKind /@ {shapes}, dnupState /@ {shapes}, IndexedTensorQ, opts] /; permS =!= ""  (* permS === ""이면 인덱스가 없다는 의미  *)

Tdefine[___] := Message[Tdefine::usage]

    tDefineOperand[oName_, permS_String, kindL_List, dnupL_List, oType_, opts:OptionsPattern[]] := (
        If [!checkName[oName], Return[$Failed]];
        defineOperand[oName, permS, kindL, dnupL, oType, opts]
    )

(* full permmutation-weights in string format *)
AllPermutations[permS_String] :=
    Module[{nRank, gs},
        {nRank, gs} = toRankAndGenSet[permS];

        If [gs === "Error", Return[$Failed]];  (* errors in permS *)
        If [nRank === -1, Message[Msg::err, "Arbitrary rank!", "", "", ""]; Return[$Failed]];

        toPermWeightStr[MakePermGroup[symToGenSet[gs, nRank]], nRank]
    ]
AllPermutations[___] := Message[AllPermutations::usage]

(* get dnup at pos *)
DnupAt[oName_?IndexedOperandQ, pos_Integer?Positive] :=
    With [{dnupL = getDnupL[oName]},
        If [Length[dnupL] > 1, dnupL[[Min[pos, getRank @ oName]]],
        (* else *)             dnupL[[1]]]  (* zero-rank or arbitrary rank, or all the same shape *)
    ]

GetRank[oName_?IndexedOperandQ] := getRank[oName]

GStoString[gs_GenSet]              := toPermWeightStr[List @@ gs, PermMax @ gs]
GStoString[gs_GenSet, len_Integer] := toPermWeightStr[List @@ gs, len]

    toPermWeightStr[{},         nRank_Integer] := StringJoin @@ Alphabet[][[Range[nRank]]]
    toPermWeightStr[permW_List, nRank_Integer] := StringJoin @@ Map[toOnePermWeightStr[#, nRank]&, permW]

        toOnePermWeightStr[onePermW_List, nRank_] :=  (* onePermW -> onePermS *)
            With[ {str = StringJoin @@ Map[Alphabet[][[#]]&, PermutationList[onePermW[[1]], nRank]]},
                If [onePermW[[2]] === -1, "-" <> str,
                (* else *)                "+" <> str]
            ]

(* Returns the kind of an IndexedOperand according to the second argument 'idx'.
   See pairQabsorb, putMetricObject, combTwoIndices. *)
KindOf[Kdelta[idx1_, idx2_], idx_] := If [MemberQ[{idx1, idx2}, idx], IndexToKind[idx], All]
KindOf[(oName_?IndexedOperandQ)[indices___], idx_] :=
    With[{pos = Position[{indices}, idx]},
        If [pos =!= {}, KindOf[oName, First @ Flatten @ pos],
        (* else *)      KindOf[oName]]  (* when not in *)
    ]

(* Retruns the kind of indexed objects: (Kdelta, BD), (Epsilon, Metricg, Torsion, CD), and LD-type are special
   NB: KindOf[opName, arg]에서 arg는 LD-type 연산자에 대해서만 의미 있음. *)
KindOf[oName_Symbol]      := KindOf[oName, 1]
KindOf[Kdelta]            := All
KindOf[Kdelta, idx_, ___] := With [{kind = IndexToKind[idx]}, If [kind =!= NonKind, kind, All]]
KindOf[BD]                := All
KindOf[BD,     idx_, ___] := With [{kind = IndexToKind[idx]}, If [kind =!= NonKind, kind, All]]
KindOf[Epsilon, __]       := DefaultKind
KindOf[Metricg, __]       := DefaultKind
KindOf[Torsion, __]       := DefaultKind
KindOf[CD,      idx_]     := If [RegularIndexQ[idx] && IndexToKind[idx] =!= DefaultKind, NonKind, DefaultKind]
KindOf[oName_?IndexedOperandQ, pos_Integer?Positive] :=
    With [{kindL = getKindL[oName],
           len = If [DiffFormQ[oName], getDegree[oName] + getRank[oName],
                 (* else *)            getRank[oName]]},

        If [Length[kindL] > 1, kindL[[Min[pos, len]]],
        (* else *)             kindL[[1]]]  (* zero-rank or arbitrary rank, or all the same shape *)
    ]
KindOf[opName_?IndexedOperatorQ, arg_, ___] := If [getType[opName] === LD, KindOf[arg], getKindL[opName][[1]]]
KindOf[___] := DefaultKind  (* for protecting illegal use *)

(**********)

Options[defineOperand] = {PrintAs -> Automatic};

defineOperand[oName_, permS_String, kindL_List, dnupL_List, oType_, OptionsPattern[]] :=
    Module[{prtStr, nRank, gs, modKindL, modDnupL},
        If [OptionValue[PrintAs] =!= Automatic && !StringQ[OptionValue[PrintAs]],
            Message[Msg::err, OptionValue[PrintAs], "is not a String!", "", ""]; Return[$Failed]
        ];
        prtStr = OptionValue[PrintAs] /. Automatic -> ToString[oName];

        If [permS === "",  (* scalar *)
            getDnupL[oName] ^= dnupL; getGenSet[oName] ^= GenSet[]; getKindL[oName] ^= kindL; getRank[oName] ^= 0,
        (* else *)
            {nRank, gs} = toRankAndGenSet[permS];
            If [gs === "Error", Return[$Failed]];  (* errors in permS *)
  
            (* NB: nRank == -1이면 임의의 랭크 *)
            modKindL = If [nRank > 1 && Length[kindL] === 1, ConstantArray[First @ kindL, nRank], (* all the same kind *)
                       (* else *)                            kindL];
            modDnupL = If [nRank > 1 && Length[dnupL] === 1, ConstantArray[First @ dnupL, nRank], (* all the same up/dn *)
                       (* else *)                            dnupL];

            (* check the consistency between permS, kindL, and dnupL *)
            If [checkDefineOperandArgs[gs, nRank, modKindL, modDnupL, permS] === $Failed, Return[$Failed]];

            (* after checking the consistency: re-set modKindL and modDnupL *)
            If [nRank > 1 && Length[DeleteDuplicates @ kindL] === 1, modKindL = Take[kindL, 1]];
            If [nRank > 1 && Length[DeleteDuplicates @ dnupL] === 1, modDnupL = Take[dnupL, 1]];

            getDnupL[oName] ^= modDnupL; getGenSet[oName] ^= gs; getKindL[oName] ^= modKindL; getRank[oName] ^= nRank; 
        ];

        getType[oName] ^= oType; getPrtStr[oName] ^= prtStr;
        IndexedObjectQ[oName] ^= True; IndexedOperandQ[oName] ^= True;

        (* custom formatting *)
        If [oType == IndexedTensorQ,  (* only for indexed tensors *)
            oName /: MakeBoxes[oName[args___], StandardForm] := makeTensorBox[oName, {args}, prtStr]
        ]
    ]

    checkDefineOperandArgs[gs_, nRank_, modKindL_, modDnupL_, permS_] :=
        If [nRank =!= -1,  (* finite rank *)
            If [Length[modKindL] =!= 1,  (* if the indices have various shapes *)
                If [nRank =!= Length[modKindL],
                    Message[Msg::err, "incompatible ranks between ", modKindL, "and", permS]; Return[$Failed]
                ];

                (* Objects with dnupL == {} are special. Otherwise, Length[modKindL] === Length[modDnupL] *)
                If [modDnupL =!= {} && Length[modDnupL] =!= 1,
                    With[{errnum = checkSymKindDnup[gs, nRank, modKindL, modDnupL]},
                        Which[
                            errnum === -1, Message[Msg::err, "incompatible between", permS, "and", modKindL],
                            errnum === -2, Message[Msg::err, "incompatible between", permS, "and", modDnupL],
                            errnum === -3, Message[Msg::err, "incompatible lengths:", modKindL, "and", modDnupL]
                        ];
                        If [MemberQ[{-1, -2, -3}, errnum], Return[$Failed]]
                    ]
                ]
            ]
        ]

        checkSymKindDnup[GenSet[], _,      _,      _]      := 0
        checkSymKindDnup[sym_,     nRank_, kindL_, dnupL_] :=
            With[{gs = symToGenSet[sym, nRank]},
                If [gs === GenSet[], Return[0]];

                With[{sameL1 = Select[GatherBy[Range @ Length[kindL], kindL[[#]]&], Length[#] > 1 &]},  (* 2025.12.23 by Notebook Assistant *)
                    If [And @@ ((Union[Flatten @ Orbits[#, gs, nRank]] =!= Union[#])& /@ sameL1), Return[-1]]
                ];

                With[{sameL2 = Select[GatherBy[Range @ Length[dnupL], dnupL[[#]]&], Length[#] > 1 &]},
                    If [And @@ ((Union[Flatten @ Orbits[#, gs, nRank]] =!= Union[#])& /@ sameL2), Return[-2]]
                ];

                If [Length[kindL] =!= Length[dnupL], Return[-3]];

                0  (* OK *)
            ]

    makeTensorBox[oName_, argL_List, prtStr_] := interpretBox[oName @@ argL,
        If [argL === {},
            prtStr,
        (* else *)
            With[{idxL = Transpose[
                    With[{rc = indexCharSpace[#]},
                        If [IndexToKind[#] =!= NonKind && UpIndexQ[#], rc[[{2, 1}]],
                        (* else *)                                      rc[[{1, 2}]]]
                    ]& /@ argL]},

                SubsuperscriptBox[prtStr, TemplateBox[idxL[[1]], "RowDefault"],
                                          TemplateBox[idxL[[2]], "RowDefault"]]
            ]
        ]
    ]

defineOperator[opName_Symbol, prtStr_String, opType_Symbol]        := defineOperator[opName, prtStr, opType, DefaultKind]  (* NB: delayed evaluation of DefaultKind *)
defineOperator[opName_Symbol, prtStr_String, opType_Symbol, kind_] := (
        If [opType =!= XP,  (* XP-type 연산자의 출력 방법은 따로 정의해야 함 *)
            opName/: MakeBoxes[opName[arg_, expr___], StandardForm] :=
                interpretBox[opName[arg, expr],
                    Switch [opType,
                        CD, TemplateBox[{If[IndexToKind[arg] =!= NonKind && UpIndexQ[arg], SuperscriptBox,
                                         (* else *)                                         SubscriptBox][prtStr, First @ indexCharSpace[arg]], MakeBoxes[expr, StandardForm]},
                                        "RowDefault"],
                        LD, TemplateBox[{ToBoxes @ Subscript[prtStr, arg], MakeBoxes[expr, StandardForm]}, "RowDefault"],
                        XD, TemplateBox[{StyleBox[prtStr, FontWeight -> "Bold"], TemplateBox[MakeBoxes[#, StandardForm]& /@ {arg, expr}, "RowDefault"]},
                                        "RowDefault"]
                    ]
                ]
        ];

        IndexedObjectQ[opName] ^= True; IndexedOperatorQ[opName] ^= True;
        getType[opName] ^= opType; getKindL[opName] ^= {kind}; getPrtStr[opName] ^= prtStr;
    )

SetAttributes[interpretBox, HoldFirst];
interpretBox[expr_, box_] :=  (***** from xTensor *****)
    InterpretationBox[
        StyleBox[box, AutoSpacing -> False, ShowAutoStyles -> False],
        expr,
        Editable->False
    ]

(* 인덱스 출력을 위해 적절한 'List[출력 모양, 공백]'을 반환 *)
indexCharSpace[a_Integer] :=  (* ComponentType *)
    With[ {n = Abs[a]},
        If [n > 9,
            If [n > 99, {UnderscriptBox[n, "_"], ToBoxes @ Invisible[111]},  (* three spaces when n >= 100 *)
            (* else *)  {UnderscriptBox[n, "_"], ToBoxes @ Invisible[11]}],  (* two spaces, otherwise *)
        (* else *)
            {n, ToBoxes @ Invisible[1]}
        ]
    ]
indexCharSpace[a_Symbol] := indexCharSpace[ToString[a]] /; IndexToKind[a] =!= NonKind     (* for the indices introduced in SetIndices[] *)
indexCharSpace[a_String] := indexCharSpaceAux[StringDrop[a,1]] /; DnIndexQ[a] || UpIndexQ[a]
indexCharSpace[arg_]     := indexCharSpaceAux[ToString @ arg]  (* for any others *)

    indexCharSpaceAux[arg_String] :=
        If [StringLength[arg] === 1 || dummyStringQ[arg],
            {arg, ToBoxes @ Invisible[1]},
        (* else *)
            With [{str = StringDrop[arg, 1]},
                Switch [StringTake[arg, {1}],  (* for decorating indices *)
                    "b", {OverscriptBox[str, "_"],            ToBoxes @ Invisible[1]},  (* Bar *)
                    "d", {OverscriptBox[str, "."],            ToBoxes @ Invisible[1]},  (* Dot *)
                    "h", {OverscriptBox[str, "^"],            ToBoxes @ Invisible[1]},  (* Hat *)
                    _,   {StyleBox[arg, FontColor -> Orange], ToBoxes @ Invisible[2]}
                ]
            ]
        ]

        dummyStringQ[str_String] :=
            With[{strL = StringSplit[str, "$"]},  (* when str = something$123, strL = {something, 123} *)
                If [Length[strL] === 2 && IntegerQ[ToExpression @ strL[[2]]], True,
                (* else *)                                                    False]
            ]

(* 문자열 형태의 대칭 표현을 GenSet 형태로 변환 *)
symToGenSet["Antisymmetric", len_] := GenSet @@ ({Cycles[{#}],-1}& /@ Partition[Range @ len, 2, 1])
symToGenSet["Symmetric",     len_] := GenSet @@ ({Cycles[{#}], 1}& /@ Partition[Range @ len, 2, 1])
symToGenSet["Nosymmetric",  _]     := GenSet[]
symToGenSet[gs_GenSet,       _]    := gs

(* permS -> {nRank, GenSet}, {nRank | -1, "Symmetric" | "Antisymmetric" | "Nosymmetric"}, or {-1, "Error"}. 여기서 -1은 임의의 랭크를 의미 *)
toRankAndGenSet[permS_String] :=
    Module[{droppedStrL, strL, nRank},
        (* drop ' ', '+', '-' *)
        droppedStrL = Select[Characters[permS], (StringPosition[" +-", #] === {})&];
        If [droppedStrL === {}, Return[{0, GenSet[]}]];  (* zero rank when permS == "" *)

        If [AllTrue[droppedStrL, DigitQ] || droppedStrL === {"*"},  (* 특별한 경우: is droppedStrL "num" or "*"? *)
            Return[toRankAndGenSetSpecial[permS]],
        (* else *)
            (* permS의 특별한 경우에 대한 처리를 끝낸 후에는 ' ', '+', '-' 문자를 제외하면 모두 영문 소문자로 구성되어야 함 *)
            droppedStrL = Select[Characters[permS], (StringPosition[" +-", #] === {})&];  (* drop ' ', '+', '-' *)
            If [!AllTrue[droppedStrL, (LetterQ[#] && LowerCaseQ[#])&], Return[{-1, "Error"}]];

            (* " abc- bac +cab" -> {"abc", "-", " ", " ", "bac", " ", " ", "+", "cab"}
                                -> {"abc", "-", "bac", "+", "cab"} *)
            strL = Select[StringSplit[permS, {" " -> "", "+" -> "+", "-" -> "-"}], (# =!= "") &];
            If [strL === {}, Return[{0, GenSet[]}]];

            (* {"abc", "-", "bac", "+", "cab"} -> {"+", "abc", "-", "bac", "+", "cab"} *)
            If [strL[[1]] =!= "+" && strL[[1]] =!= "-", strL = Join[{"+"}, strL]];

            (* {"+", "abc", "-", "bac", "+", "cab"} -> {{"+", "abc"}, {"-", "bac"}, {"+", "cab"}}
                                                    -> {"+abc", "-bac", "+cab"} *)
            strL = StringJoin /@ Partition[strL, 2];
            nRank = (StringLength @ strL[[1]]) - 1;

            (* check consistency with the rank *)
            If [AnyTrue[strL, (StringLength[#] =!= nRank + 1)&],
                Message[General::invalid, permS, "perm; it has inconsistent rank"]; Return[ {-1, "Error"} ]
            ];

            (* {"+abc", "-bac", "+cab"} -> {Imag[{1,2,3}]}, -Imag[{2, 1, 3}], Imag[{3, 1, 2}]} *)
            With[{imagL = stringToImag /@ strL},
                If [MemberQ[imagL, Null], Return[ {-1, "Error"} ] ];

                (* 동일한 순열인데 weight가 다른가? *)
                If [Length[imagL] > 1 && Length[imagL] =!= Length[Plus @@ imagL],
                    Message[General::invalid, permS, "perm; it has inconsistent weights"]; Return[{-1, "Error"}]
                ];

                With[{permL = ToCycl /@ imagL},
Off[Arrays::symm0];
                    With[{rc = Arrays[ConstantArray[nRank, nRank], permL][[3]]},
On[Arrays::symm0];
                        If [rc === ZeroSymmetric[{}],
                            Message[General::invalid, permS, "perm; it has inconsistent weights"]; Return[ {-1, "Error"} ]
                        ];

                        {nRank, GenSet @@ DeleteDuplicates[permL]}
                    ]
                ]
            ]
        ]
    ]

    (* String -> Imag or Null *)
    stringToImag[permS_String] :=
        With[{strL = Select[Characters[permS], (StringPosition[" +-", #] === {})&]},  (* drop ' ', '+', '-' *)
            If [strL === {}, Return[ Imag[] ]];

            (* String -> Imag List *)  (* 참고: {d,s,a} -> {2,3,1} because Sort[{d,s,a}] == {a,d,s} *)
            With[{imagL = strL /. MapIndexed[Rule[#1, First @ #2]&, Sort[strL]]},
                If [!PermutationListQ[imagL], Message[General::invalid, permS, "perm"]; Return[]];

                (* if First[permS] === "-" *)
                If [Select[Characters[permS], (StringPosition[" ", #] === {})&][[1]] === "-",
                    (* 2025.01.29: 대칭군을 구성하기 위한 필수 조건 *)
                    If [Signature[imagL] =!= -1, Message[General::invalid, permS, "signed perm"]; Return[]];

                    -Imag @@ imagL,
                (* else *)
                    Imag @@ imagL
                ]
            ]
        ]

    (* permS에서 ' ' 문자 또는 문자열 마지막의 '+'나 '-' 문자를 제거한 후 숫자나 '*'만 남는 특별한 경우의 toRankAndGenSet *)
    toRankAndGenSetSpecial[permS_String] :=
        Module[{strL, mostL, symStr},
            strL = Select[Characters[permS], (# =!= " ")&]; (* get non-space characters from permS *)
            If [Length[strL] === 0, Return[{0, GenSet[]}]];

            Switch [Last[strL],
                "+", symStr = "Symmetric";     mostL = Most[strL],
                "-", symStr = "Antisymmetric"; mostL = Most[strL],
                _,   symStr = "Nosymmetric";   mostL = strL
            ];

            If [mostL === {"*"},        Return[{-1, symStr}]];
            If [AllTrue[mostL, DigitQ], Return[{ToExpression[StringJoin @@ mostL], symStr}]];
            Return[{-1, "Error"}]
        ]

(********** Index Symmetries **********)

GetSymmetry[oName_?IndexedOperandQ] := getGenSet[oName]

SetSymmetry[oName_Symbol?IndexedOperandQ, permS_String] :=
    Module[{nRank, gs},
        {nRank, gs} = toRankAndGenSet[permS];
        If [gs === "Error", Message[Msg::err, "invalid format: ", permS, "", ""]; Return[$Failed]];
        If [nRank =!= getRank[oName], Message[Msg::err, "incompatible rank: ", nRank, "", ""]; Return[$Failed]];

        getGenSet[oName] ^= gs;
    ]

(* generate GenSet according to the number of indices *)
getGenSetOf[Kdelta[idx1_, idx2_]]                := GenSet[{Cycles[{{1, 2}}],  1}]  (* $\delta^a_{\ b} === +\delta_b^{\ a} === \delta^a_b$ *)
getGenSetOf[(oName_?IndexedOperandQ)[idices___]] := getGenSetOf[oName, Length @ {idices}]
getGenSetOf[oName_?IndexedOperandQ, len_Integer] :=
    With[ {nRank = getRank[oName], gs = symToGenSet[getGenSet @ oName, len]},
        If [len =!= nRank,
            If [DiffFormQ[oName] && len === getDegree[oName] + nRank,  (* p-form as a tensor *)
                Join[symToGenSet["Antisymmetric", getDegree[oName]],
                     gs /. Cycles[{cycs__}] :> Cycles[{cycs} + getDegree[oName]]],
            (* else *)
                selectSlots[gs, If [nRank === -1, len, Min[len, nRank]]]  (* according to the # of indices *)
            ],
        (* else *)
            gs
        ]
    ]

    selectSlots[gs_GenSet, len_Integer] := Select[selectCycls[#, len]& /@ gs, (#[[1]] =!= Cycles[{}])&]

        selectCycls[{Cycles[cycl_],-1}, len_] := {Cycles[Select[cycl, allSmallerEqual[#, len]&]],-1}
        selectCycls[{Cycles[cycl_], 1}, len_] := {Cycles[Select[cycl, allSmallerEqual[#, len]&]], 1}

            allSmallerEqual[lst_List, len_Integer] := AllTrue[lst, (# <= len)&]

(********** Tscalar/ErrorT **********)

Tscalar/: MakeBoxes[Tscalar[expr_], StandardForm] :=
    interpretBox[Tscalar[expr],
        TemplateBox[{
            StyleBox["(", FontColor -> RGBColor[1, 0, 1]],
            MakeBoxes[expr, StandardForm],
            StyleBox[")", FontColor -> RGBColor[1, 0, 1]]
        }, "RowDefault"]
    ]

ErrorT/: MakeBoxes[ErrorT[oName_][args___], StandardForm] := interpretBox[ErrorT[oName][args], StyleBox[MakeBoxes[oName[args], StandardForm], FontColor -> Red]]
ErrorT/: MakeBoxes[ErrorT[oTerm_],          StandardForm] := interpretBox[ErrorT[oTerm],       StyleBox[MakeBoxes[oTerm,       StandardForm], FontColor -> Red]]

(* rules *)
Tscalar[expr_Plus] := Map[Tscalar, expr] /; FreePatternQ[expr]

Tscalar[c_?ConstantQ]                                      := c
Tscalar[pre_. * expr_Symbol                      * post_.] := expr        * Tscalar[pre post] /; FreePatternQ[{pre, expr, post}]
Tscalar[pre_. * c_?ConstantQ                     * post_.] := c           * Tscalar[pre post] /; FreePatternQ[{pre, c, post}]
Tscalar[pre_. * (sfName_?ScalarFunctionQ)[arg__] * post_.] := sfName[arg] * Tscalar[pre post] /; FreePatternQ[{pre, arg, post}]

(********** Utils for indexed objects **********)

(* expand indexed objects satisfying 'hOpts' *)
SetAttributes[ExpandObject, Listable]
ExpandObject[expr_, opts___Rule] := Expand[ wrapObject[expr, $FOREXPAND, Sequence @@ FilterRules[{opts}, HeadQs]], $FOREXPAND ] /. $FOREXPAND -> Identity
ExpandObject[args___]            := args

(* is free of indexed objects? *) (* NB: Default option for HeadQs is IndexedObjectQ *)
SetAttributes[FreeObjectQ, Listable]
FreeObjectQ[expr_, opts___Rule] := FreeQ[ wrapObject[expr, $FORFREE, Sequence @@ FilterRules[{opts}, HeadQs]], $FORFREE ]
FreeObjectQ[___]                := True

(* applies a function 'f' to each term of an expression. *)
ForEachTerm[expr:(_Plus | _Equal), f_, args___] := ForEachTerm[#, f, args] & /@ expr
ForEachTerm[expr_, f_, args___]                 := f[expr, args]

(* visit each objects in 'expr' and then act 'f' with arguments 'args' and 'hOptL' *)
(* NB: Default option for HeadQs is IndexedObjectQ *)
ForEachObject[expr_Plus,       hOptL_, f_, args___] := ForEachObject[#, hOptL, f, args]& /@ expr  (* each term *)
ForEachObject[expr_Equal,      hOptL_, f_, args___] := ForEachObject[#, hOptL, f, args]& /@ expr
ForEachObject[expr_Times,      hOptL_, f_, args___] := ForEachObject[#, hOptL, f, args]& /@ expr  (* each factor *)
ForEachObject[expr:name_[___], hOptL_, f_, args___] := f[expr, args] /; AllQoptions[HeadQs][name, hOptL]
ForEachObject[expr_,           _,      _,      ___] := expr

(* return {non-indexed objects, indexed objects} of a term: Apply[Times, {non-indexed objects, indexed objects}] === aTerm *)
SplitTerm[aTerm_Times,         hOptL_List:{}] := Times @@ Map[SplitTerm[#, hOptL]&, List @@ aTerm]
SplitTerm[aTerm:(oName_[___]), hOptL_List:{}] := {1, aTerm} /; AllQoptions[HeadQs][oName, hOptL]
SplitTerm[expr_, ___]                         := {expr, 1}

(* wrap indexed objects in expr with wrapSymb *)
SetAttributes[wrapObject, Listable]
wrapObject[expr_, wrapSymb_Symbol, opts___Rule] := ForEachObject[expr, FilterRules[{opts}, HeadQs], wrapWith, wrapSymb]

    wrapWith[expr_, wrapSymb_] := wrapSymb[expr]

(********************************************************************)
(****************** Operations on Indexed Expressions ***************)
(********************************************************************)

(********** FindIndices **********)

(* find un-sorted (free-)indices from a term. The indices are aware of the object's kindness. *)
FindIndices[term_,              opts___Rule] := indicesOf[term, {opts}]
FindFreeTensorialIndices[term_, opts___Rule] :=
    With[{indexL1 = indicesOf[term, FilterRules[{opts}, Except @ IndexQs]]},  (* find indices without considering IndexQs *)
        With[{indexL2 = dropPairs @ Select[indexL1, TensorialIndexQ]},        (* drop pairs from selected tensorial indices *)
            Select[indexL2, AllQoptions[IndexQs][#, {opts}]&]                 (* finally, consider IndexQs *)
        ]
    ]

(* find all kinds of un-sorted (free-)indices from a term *)
FindIndicesAll[term_,              opts___Rule] := indicesOf[term, {opts}, True]
FindFreeTensorialIndicesAll[term_, opts___Rule] := dropPairs @ Select[DeleteDuplicates @ FindIndicesAll[term, opts], TensorialIndexQ]

(* return all/compatible indices satisfying optL *)
indicesOf[expr_Plus,          optL_, allQ_:False] := Flatten @ Map[indicesOf[#, optL, allQ]&, List @@ expr]
indicesOf[expr_Equal,         optL_, allQ_:False] := Flatten @ Map[indicesOf[#, optL, allQ]&, List @@ expr]
indicesOf[expr_Times,         optL_, allQ_:False] := Flatten @ Map[indicesOf[#, optL, allQ]&, List @@ expr]
indicesOf[expr:(oName_[___]), optL_, allQ_:False] := indicesOfObject[expr, optL, allQ] /; AllQoptions[HeadQs][oName, optL]
indicesOf[___]                                    := {}

    Options[indicesOfObject] = {$FormDropIndices -> False}

    indicesOfObject[(oName_?IndexedOperandQ)[indices__], optL_, allQ_] :=
        With[{nRank = GetRank[oName], indexL0 = Select[{indices}, AllQoptions[IndexQs][#, optL]&]},
            With[{indexL = 
                    If [DiffFormQ[oName] && nRank =!= 0 && ($FormDropIndices /. optL /. Options[indicesOfObject]),
                        Drop[indexL0, -nRank],  (* See dualStarTerm *)
                    (* else *)
                        indexL0
                    ]},

                If [allQ,
                    indexL,
                (* else *)
                    With[{newIdxL =
                            If [IndexedTensorQ[oName] && nRank =!= -1 && Length[indexL] =!= nRank,
                                Take[indexL, Min[Length[indexL], nRank]],
                            (* else *)
                                indexL
                            ]},

                        (* NB: When DiffFormQ[oName], returns only the indices in the indexed-form: Omega[lmu, lnu, la, ub] => {la, lb} *)
                        (* TODO: check when DiffFormQ[oName] *)
                        Select[newIdxL, ValidIndexQ[#, KindOf[oName, First @ Flatten @ Position[{indices}, #]]]&]
                    ]
                ]
            ]
        ]
    indicesOfObject[(opName_?IndexedOperatorQ)[arg_, expr___], optL_, allQ_] :=
        With[{hOptL0 = FilterRules[optL, HeadQs], modOptL0 = FilterRules[optL, Except @ HeadQs]},
            With[{hOptL = If [hOptL0 =!= {}, {HeadQs -> DeleteCases[hOptL0[[1,2]], IndexedOperatorQ]},  (* remove IndexedOperatorQ from hOptL *)
                          (* else *)         hOptL0]},

                With[{modOptL = If [hOptL0 =!= {}, Join[modOptL0, hOptL],
                                (* else *)         modOptL0]},

                    Switch [getType[opName],
                        CD, If [allQ || ValidIndexQ[arg, KindOf[opName, arg]],
                                Join[ Select[{arg}, AllQoptions[IndexQs][#, optL]&], indicesOf[expr, modOptL, allQ] ],
                            (* else *)
                                indicesOf[expr, modOptL, allQ]
                            ],
                        LD, indicesOf[expr, modOptL, allQ],
                        XD, indicesOf[arg, modOptL, allQ],  (* expr === Null *)
                        XP, Flatten @ Map[indicesOf[#, modOptL, allQ]&, {arg, expr}]
                    ]
                ]
            ]
        ]
    indicesOfObject[(_?ScalarFunctionQ)[args___], optL_, allQ_] := Flatten @ Map[indicesOf[#, optL, allQ]&, {args}]
    indicesOfObject[_,                          _,     _]       := {}

(* Scalar === indexed scalar f[] || Fully contracted tensor product || ScalarFunction *)
NoIndexQ[(_?scalarNameQ)[]]  := True
NoIndexQ[expr_, opts___Rule] :=
    If [ScalarFunctionQ[Head[expr]],
        True,
    (* else *)
        If [!FreeObjectQ[expr, Sequence @@ FilterRules[{opts}, HeadQs]],
            FindFreeTensorialIndices[expr, opts] === {},  (* f[] or a fully contracted tensor product *)
        (* else *) (* if FreeObjectQ *) (* 2025.01.31 *)
            True
        ]
    ]

    (* is an indexed scalar? *)
    scalarNameQ[oName_?IndexedTensorQ] := GetRank[oName] === 0
    scalarNameQ[___]                   := False

(* is an indexed vector? *)
vectorNameQ[oName_?IndexedTensorQ] := GetRank[oName] === 1
vectorNameQ[fName_?DiffFormQ]      := MetricSpaceQ[KindOf @ fName] && getDegree[fName] === 1
vectorNameQ[___]                   := False

(* reordering indices of IndexedObject *)
AntisymmetrizeIndices[expr_, indexL_?VectorQ, opts___Rule] := symmetrizeAux[expr, indexL, True, opts]
AntisymmetrizeIndices[___]                                 := Message[AntisymmetrizeIndices::usage]

SymmetrizeIndices[expr_, indexL_?VectorQ, opts___Rule] := symmetrizeAux[expr, indexL, False, opts]
SymmetrizeIndices[___]                                 := Message[SymmetrizeIndices::usage]

    symmetrizeAux[expr_, indexL_, antiQ_, opts___Rule] := (
            If [!ValidIndicesQ[indexL, All, True], Return[expr]];
            ForEachTerm[ExpandObject[expr, opts], symmetrizeTerm, indexL, FilterRules[{opts}, HeadQs], antiQ]
        )

        symmetrizeTerm[aTerm_, symIndexL_, hOptL_List, antiQ_] :=
            Module[{ordTerm, oTerm},
                {ordTerm, oTerm} = SplitTerm[aTerm, hOptL];
                ordTerm * symmetrizeTermAux[oTerm, symIndexL, antiQ, FindIndicesAll[oTerm, Sequence @@ hOptL]]
            ]

            symmetrizeTermAux[oTerm_, symIndexL_, antiQ_, indexL_] :=
                If [!AllTrue[symIndexL, (MemberQ[indexL, #])&],  (* if no symIndex in oTerm *)
                    Message[Msg::warn, symIndexL, "is not a subset of", indexL, ""]; oTerm,
                (* else *)
                    With[{sIndexL = Sort[symIndexL]},
                        With[{allSymL = Permutations @ sIndexL},                                (* all possible permutations of symIndexL: may be long *)
                            With[{rc = oTerm /. (Inner[Rule, sIndexL, #, List]& /@ allSymL)},   (* List of re-ordered oTerms *)
                                If [antiQ === True,
                                    Dot[(Signature[#]& /@ allSymL), rc] / (Length[symIndexL]!), (* Antisymmetrize *)
                                (* else *)
                                    (Plus @@ rc) / (Length[symIndexL]!)
                                ]
                            ]
                        ]
                    ]
                ]

(********************************************************************)
(****************** Operations on Indexed Expressions ***************)
(********************************************************************)

(******** Dummy Operations *********)

SetAttributes[Dum, Listable]
Dum[expr_, opts___Rule] := ForEachTerm[ExpandObject[expr, opts], dumTerm, RegularIndexQ, FilterRules[{opts}, IndexQs], FilterRules[{opts}, HeadQs]]
Dum[___]                := Message[Dum::usage]

SetAttributes[DumFresh, Listable]
DumFresh[expr_, opts___Rule] := ForEachTerm[ExpandObject[expr, opts], dumTerm, TensorialIndexQ, FilterRules[{opts}, IndexQs], FilterRules[{opts}, HeadQs]]
DumFresh[___]                := Message[DumFresh::usage]

dumTerm[aTerm_, selectQ_, iOptL_List, hOptL_List] :=
    Module[{ordTerm, oTerm},
        {ordTerm, oTerm} = SplitTerm[aTerm, hOptL];

        (* get indices obeying selectQ and iOpts *)
        With[{indexL = Select[indicesOf[oTerm, Join[iOptL, hOptL]], selectQ]},
            If [indexL === {}, Return[aTerm]];
            ordTerm * dumTermAux[oTerm, indexL]
        ]
    ]

    dumTermAux[oTerm_, {}]      := oTerm
    dumTermAux[oTerm_, {_}]     := oTerm
    dumTermAux[oTerm_, indexL_] :=
        With[{pairL = TakePairs @ indexL},
            If [pairL === {}, Return[oTerm]];

            With[{dummyL = NewDummy[IndexToKind @ First @ #]& /@ pairL},
                oTerm /. MapThread[Rule, {Flatten[pairL, 1], Flatten[dummyL, 1]}]
            ]
        ]

(* reset dummy indices *)
SetAttributes[ResetDummies, Listable]
Options[ResetDummies] = {All -> True}
ResetDummies[expr_, opts___Rule] := ForEachTerm[ExpandObject[expr, opts], resetDummiesTerm, FilterRules[{opts}, IndexQs], FilterRules[{opts}, HeadQs], opts]
ResetDummies[expr___]            := expr

resetDummiesTerm[aTerm_, iOptL_List, hOptL_List, opts___Rule] :=
    With[ {ordANDoTerm = SplitTerm[aTerm, hOptL]},
        With[{oTerm = If [All /. {opts} /. Options[ResetDummies],
                          (* get ALL kinds of contracted indices WITHOUT considering the kindness of indexed objects,
                             and then locally Dum to KEEP the order of dummyL *)
                          dumTermAllIndices[ordANDoTerm[[2]], indicesOf[ordANDoTerm[[2]], hOptL, True]],
                      (* else *)
                          ordANDoTerm[[2]]
                      ]},

            With[{indexL = indicesOf[oTerm, hOptL, True]},  (* for getting all kinds of "dummy" indices *)
                With[{dummyL0 = Select[indexL, DummyIndexQ]},
                    With[{dummyL = If [iOptL =!= {}, Flatten @ (Select[dummyL0, #]& /@ iOptL[[1,2]]),
                                   (* else *)        dummyL0]},

                        If [dummyL === {}, Return[aTerm]];

                        (* reset ALL kinds of contracted indices WITH considering the kindness of indexed objects *)
                        ordANDoTerm[[1]] * resetDummiesTermAux[oTerm, dummyL, Complement[Select[indexL, TensorialIndexQ], dummyL]]
                    ]
                ]
            ]
        ]
    ]

    dumTermAllIndices[oTerm_, {}]      := oTerm
    dumTermAllIndices[oTerm_, {_}]     := oTerm
    dumTermAllIndices[oTerm_, indexL_] :=
        With[{pairL = TakePairs @ indexL},
            If [pairL === {},
                oTerm,
            (* else *)
                With[ {dummyL = NewDummy[IndexToKind @ #[[1]]]& /@ pairL},
                    oTerm /. MapThread[Rule, {Flatten[pairL, 1], Flatten[dummyL, 1]}]
                ]
            ]
        ]

    resetDummiesTermAux[oTerm_, {},      _]      := oTerm
    resetDummiesTermAux[oTerm_, dummyL_, freeL_] := oTerm /. Flatten[reOrderRuleEachKind[Select[dummyL, KindIndexQ[#]],
                                                                                         remainingIndicesKind[freeL, #]]& /@ definedKindList]

        (* return indices from kind's getCharacters, which do not contain the freeL's indices *)
        remainingIndicesKind[freeL_, oneDkind_] := getCharacters[oneDkind] /; OneDimKindQ[oneDkind]
        remainingIndicesKind[freeL_, kind_]     :=
            With[{allIdx = getCharacters[kind],
                  freeChrs = StringDrop[#, 1]& /@ (ToString /@ Select[freeL, KindIndexQ[kind]])},

                Select[allIdx, (Not @ MemberQ[freeChrs, #])&]  (* to keep the order of the added indices *)
            ]

        reOrderRuleEachKind[{},      _]           := {}
        reOrderRuleEachKind[dummyL_, remainingL_] :=
            With[{splitL =
                    (* split "lKind$num" and "uc into {"lKind", "num"} and {"u", "c"}, respecively *)       (* {lKind$3,uKind$3,lc,uc} --> {{lKind,3},{uKind,3},{l,c},{u,c}} *)
                    If [DummyIndexQ[#], StringSplit[#, "$"],
                    (* else *)          {StringTake[#, 1], StringDrop[#, 1]}]& /@ (ToString /@ dummyL)},
                With[{chrL = DeleteDuplicates @ Map[#[[2]]&, splitL]},                                      (* --> {3,c} *)
                    (* Check Length[remainingL] >= Length[dummyL]? If not, return {}. *)
                    If [Length[remainingL] < Length[chrL],
                        With[{kind = IndexToKind @ First @ dummyL, len = Length[chrL]},
                            Message[Msg::note, "In", kind, "it needs to add, at least,", len, "more indices. Use AddIndices[num, kind]."];
                            Return[{}]
                        ]
                    ];

                    With[{newL = Map[ SymbolJoin, splitL /. MapThread[Rule, {chrL, Take[remainingL, Length @ chrL]}] ]},  (* --> {la,ua,lb,ub} *)
                        MapThread[Rule, {dummyL, newL}]                                                                   (* --> {lKind$3->la,uKind$3->ua,lc->lb,uc->ub} *)
                    ]
                ]
            ]

(* Table in Symbolic mode *)
SplitIndices[expr_, argLs:(({_, _, ___}?VectorQ)..)] :=
    With[{ruleL = MapThread[Composition[List, Rule], #]& /@ ({Table[#[[1]], Length[Rest[#]]], Rest[#]}& /@ {argLs})},
        Fold[ReplaceAll[#1, #2]&, expr, Reverse @ ruleL]  (* NB: Reversed for producing Table format *)
    ]

(* numeric SumDum *)
SumDum[expr_, {i1_Integer?Positive, i2_Integer?Positive},              opts___Rule] := SumDum[expr, {i1, i2}, DefaultKind, opts]
SumDum[expr_, {i1_Integer?Positive, i2_Integer?Positive}, kind_Symbol, opts___Rule] := (
        If [!CheckKind[kind], Return[expr]];

        (* set IndexQs to ValidIndexQ if no index options *)
        With[{iOptL = {IndexQs -> {ValidIndexQ[#, kind]&}}},
            sumDumWithoutKind[expr, {i1, i2}, iOptL, opts]
        ]
    )

    sumDumWithoutKind[expr_, {i1_, i2_}, iOptL_, opts___] :=
        With[{hOptL0 = FilterRules[{opts}, HeadQs]},
            With[{hOptL = hOptsWithObjectQ[hOptL0]},
                If [i1 < i2, ForEachTerm[ExpandObject[expr, opts], sumDumNumericTerm, {i1, i2}, iOptL, hOptL],
                (* else *)   expr]
            ]
        ]

(* numeric SumDum in component mode *)
SumDum[expr_,              opts___Rule] := SumDum[expr, DefaultKind, opts]
SumDum[expr_, kind_Symbol, opts___Rule] := (
        If [!CheckKind[kind], Return[expr]];

        With[{nDim = GetDimension[kind]},
            If [!PositiveIntegerQ[nDim],
                Message[Msg::warn, "Component mode of SumDum requires Dimension for", kind, ". Use SetDimension.", ""]; Return[expr]
            ];

            SumDum[expr, {1, nDim}, kind, opts]
        ]
    )

    (* numeric dummy sum of a term. return sum of them *)
    sumDumNumericTerm[aTerm_, {i1_, i2_}, iOptL_List, hOptL_List] :=
        With[{ordANDoTerm = SplitTerm[aTerm, hOptL]},
            If [ordANDoTerm[[2]] === 1, aTerm,
            (* else *)                  ordANDoTerm[[1]] * sumDumNumericAux[ordANDoTerm[[2]], {i1, i2}, iOptL, hOptL]]
        ]

        sumDumNumericAux[oTerm_, {i1_, i2_}, iOptL_, hOptL_] :=
            With[ {pairL = TakePairs @ FindIndices[oTerm, Sequence @@ Join[iOptL, hOptL]]},
              If [pairL === {},
                  oTerm,
              (* else *)
                    With[{rcL =
                            With[{doTable = Table[#1 /. {pairL[[#2,1]] -> -j, pairL[[#2,2]] -> j},  (* prepare for Table generation *)
                                                  {j, i1, i2}]&},                                   (* dummy indices -> component indices *)

                                Fold[doTable, oTerm, Range[Length @ pairL]]
                            ]},

                      If [rcL === oTerm, oTerm, Plus @@ Flatten[rcL, Length[pairL] - 1]]
                    ]
              ]
          ]

(* symbolic SumDum *)
SumDum[expr_, argLs:({_, _, __}?VectorQ).., opts___Rule] :=
    If [AllTrue[{argLs}, VectorQ[#, DefinedKindQ]&],
        (* SumDum in Kaluza-Klein mode *)
        sumDumKaluzaKlein[expr, argLs, opts],
    (* else *)
        If [AllTrue[{argLs}, VectorQ[#, DnIndexQ]&],
            (* SumDum in the symbolic mode *)
            With[{rangeL = {argLs}, hOptL0 = FilterRules[{opts}, HeadQs]},
                With[{hOptL = hOptsWithObjectQ[hOptL0]},
                    ForEachTerm[ExpandObject[expr, opts], sumDumSymbolicTerm, rangeL, hOptL]
                ]
            ],
        (* else *)
            Message[Msg::err, "invalid input in", argLs, ". It should be a list of lower indices.", ""]; Return[expr]
        ]
    ]
SumDum[___] := Message[SumDum::usage]

    (* symbolic SumDum of a term in usual mode. return sum of them *)
    sumDumSymbolicTerm[aTerm_, rangeL_, hOptL_List] :=
        With[{ordANDoTerm = SplitTerm[aTerm, hOptL]},
            ordANDoTerm[[1]] * sumDumSymbolicIndexedTerm[ordANDoTerm[[2]], rangeL, hOptL]
        ]

    (* symbolic SumDum in Kaluza-Klein mode *)
    sumDumKaluzaKlein[expr_, kindL_List, hOpts___Rule] := (
        If [Length[Union @ kindL] < 3,
            Message[Msg::err, "Kaluza-Klein mode requires, at least, three different non-component Kinds.", "", "", ""]; Return[expr]
        ];
        If [!CheckKind[kindL], Return[expr]];

        With[{hOptL0 = FilterRules[{hOpts}, HeadQs]},
            (* to avoid the cases, e.g., Log[V[la]V[ua]] => Log[V[-1]V[1]] + Log[V[-2]V[2]] + ... *)
            With[{hOptL = hOptsWithObjectQ[hOptL0]},
                ForEachTerm[ExpandObject[expr, hOpts], sumDumKaluzaKleinTerm, kindL, hOptL]
            ]
        ]
    )

        sumDumKaluzaKleinTerm[aTerm_, kindL_, hOptL_List] :=
            With[{ordANDoTerm = SplitTerm[aTerm, hOptL]},
                (* consider kind-indices only *)
                ordANDoTerm[[1]] * sumDumKaluzaKleinTermAux[ordANDoTerm[[2]], Drop[kindL, 1], {IndexQs -> {ValidIndexQ[#, First @ kindL]&}}, hOptL]
            ]

            sumDumKaluzaKleinTermAux[oTerm_, subKindL_, iOptL_, hOptL_] :=
                With[{rcTerm = dumTerm[oTerm, RegularIndexQ, iOptL, hOptL]},  (* Dum *)
                    With[{dummyIndexL =                                       (* get kind dummy indices*)
                              Select[
                                  Select[indicesOf[rcTerm, hOptL, True], AllQoptions[IndexQs][#, iOptL]&],
                                  (DummyIndexQ[#] && DnIndexQ[#])&
                              ]},

                        Module[{rangeL = {}},
                            (* generate rangeL for calling sumDumSymbolicIndexedTerm *)
                            Do [
                                rangeL = Join[rangeL, {Join[{dummyIndexL[[i]]}, Map[NewDummy[#][[1]]&, subKindL]]}],
                                {i, Length[dummyIndexL]}
                            ];

                            sumDumSymbolicIndexedTerm[rcTerm, rangeL, hOptL]
                        ]
                    ]
                ]

(* for avoiding the cases, e.g., Log[V[la]V[ua]] =!=> Log[V[-1]V[1]] + Log[V[-2]V[2]] + ..., in SumDum *)
hOptsWithObjectQ[hOptL_List] :=
    If [hOptL =!= {},
        With[{modL = DeleteCases[hOptL[[1,2]], ObjectQ]},
            If [modL =!= {}, {HeadQs -> modL},  (* drop ObjectQ in hOptL, if exists *)
            (* else *)       {}]
        ],
    (* else *)
        hOptL
    ]

sumDumSymbolicIndexedTerm[oTerm_, rangeL_, hOptL_] :=
    With[{indexL = Select[FindIndicesAll[oTerm, Sequence @@ hOptL], TensorialIndexQ]},  (* neglect kinds of objects in oTerm *)
        Module[{newRangeL = {}},
            (* get rangeL of dummy indices *)
            Do [
                If [Position[indexL, rangeL[[i,1]]] === {},
                    Message[Msg::warn, "no compatible index:", rangeL[[i,1]], "in", oTerm]; Continue[],
                (* else *)
                    If [Position[indexL, FlipIndex[rangeL[[i,1]]]] === {},
                        Message[Msg::warn, "not dummy index:", rangeL[[i,1]], "in", indexL]; Continue[]
                    ]
                ];
                newRangeL = Join[newRangeL, {rangeL[[i]]}],
                {i, Length[rangeL]}
            ];
            If [newRangeL === {}, Return[oTerm]];

            Module[{rcL = oTerm, ruleL},
                (* substitution *)
                Do [
                    (* {{la, ua}, {-1,1}, {li, ui},...} for {la, -1, li,...} *)
                    With[{aRangeL = Map[{#, FlipIndex[#]}&, newRangeL[[i]]]},
                        ruleL = {};
                        Do [
                            ruleL = Join[ruleL, { {aRangeL[[1,1]] -> aRangeL[[j,1]], aRangeL[[1,2]] -> aRangeL[[j,2]]} }],
                            {j, 2, Length[aRangeL]}
                        ];
                        rcL = Map[(rcL /. #)&, ruleL]
                    ],
                    {i, Length[newRangeL]}
                ];

                If [rcL === oTerm, oTerm,  (* not summed *)
                (* else *)         Plus @@ Flatten[rcL, Length[newRangeL] - 1]]
            ]
        ]
    ]

(********** RuleUnique **********)

SetAttributes[RuleUnique, HoldAll]
RuleUnique[lhs_, rhs_, cond_:True] := ruleUnique[lhs, Evaluate[Dum[rhs]], cond]
RuleUnique[___]                    := (Message[RuleUnique::usage]; {})

    SetAttributes[ruleUnique, HoldAll]
    ruleUnique[lhs_, rhs_, True]  := RuleDelayed[lhs, DumFresh[rhs]]
    ruleUnique[lhs_, rhs_, cond_] := RuleDelayed[lhs, DumFresh[rhs] /; cond]


(********** SyntaxCheck **********)

SetAttributes[SyntaxCheck, {Listable}]

(* Check expr satisfying HeadQs *)
SyntaxCheck[aPlus_Plus, opts___Rule] :=
    With[{hOpts = Sequence @@ FilterRules[{opts}, HeadQs]},
        Catch[
            Module[{rcExpr = ExpandObject[aPlus, hOpts]},
                If [!FreeQ[rcExpr[[1]] = syntaxCheckTerm[rcExpr[[1]], {hOpts}], ErrorT], Throw[rcExpr]];

                With[{freeIndexL1 = FindFreeTensorialIndices[rcExpr[[1]], hOpts]},  (* get free-indices of 1st term *)
                    Do[
                        If [!FreeQ[rcExpr[[i]] = syntaxCheckTerm[rcExpr[[i]], {hOpts}], ErrorT], Throw[rcExpr]];

                        (* the same free-indices? *)
                        With[{freeIndexL2 = FindFreeTensorialIndices[rcExpr[[i]], hOpts]},
                            If [Sort[freeIndexL1] =!= Sort[freeIndexL2],
                                Message[Msg::err, "incompatible free indices:", freeIndexL1, "and", freeIndexL2]; Throw[ErrorT @ rcExpr]
                            ]
                        ],
                        {i, 2, Length[rcExpr]}
                    ]
                ]
            ];
            aPlus  (* no error *)
        ]
    ] /; FreePatternQ[aPlus]
SyntaxCheck[aTerm_, opts___Rule] :=
    With[{hOpts = Sequence @@ FilterRules[{opts}, HeadQs]},
        With[{expr = ExpandObject[aTerm, hOpts]},
            If[Head[expr] === Plus, Return[SyntaxCheck[expr, hOpts]],
            (* else *)              Return[syntaxCheckTerm[expr, {hOpts}]]]
        ]
    ] /; FreePatternQ[aTerm]
SyntaxCheck[expr_, ___Rule] := expr
SyntaxCheck[___]            := Message[SyntaxCheck::usage]

    syntaxCheckTerm[aTerm_, hOptL_List] :=
        With[{modhOptL =
                (* for considering all exprs having the pattern f_[___] when hOptL === {} *)
                If [hOptL === {}, {HeadQs -> {True&}},
                (* else *)        hOptL]},

            With[{ordANDoTerm = SplitTerm[aTerm, modhOptL]},
                If [ordANDoTerm[[2]] === 1, Return[aTerm]];

                (* check objects *)
                With[{oTerm = ForEachObject[ordANDoTerm[[2]], modhOptL, syntaxCheckObject]},
                    If [!FreeQ[oTerm, ErrorT], Return[oTerm]];  (* there are errors *)
                    If [DuplicatedIndicesQ[indicesOf[oTerm, modhOptL], True], Return[ErrorT @ oTerm]];
                ];

                aTerm  (* no-errors *)
            ]
        ]

        (* hOptL == {} in this function *)
        syntaxCheckObject[oName:ErrorT[_][___]] := syntaxCheckObject[oName //. ErrorT -> Identity]

        syntaxCheckObject[(oName_?IndexedOperandQ)[]] :=
            If [GetRank[oName] =!= 0,  (* scalar *)
                Message[Msg::err, "invalid number of indices for", oName, "", ""]; ErrorT[oName][],
            (* else *)
                oName[]  (* no errors *)
            ]
        syntaxCheckObject[(oName_?IndexedOperandQ)[aIndices__]] :=
            If [!checkObject[oName, {aIndices}, True],
                ErrorT[oName][aIndices],
            (* else *)
                With [{kind = KindOf @ oName},
                    With[{nDim = GetDimension[kind]},  (* check number of indices of Epsilon[..] *)
                        If [oName === GetEpsilon[kind] && PositiveIntegerQ[nDim] && Length[{aIndices}] =!= nDim,
                            Message[Msg::err, "invalid number of indices", {aIndices}, "for", oName]; ErrorT[oName][aIndices],
                        (* else *)
                            oName[aIndices]
                        ]
                    ]
                ]
            ]
        syntaxCheckObject[(opName_?IndexedOperatorQ)[arg_, expr___]] :=
            Switch [getType[opName],
                CD,
                    With[{rcExpr = SyntaxCheck[{expr}]},
                        If [!FreeQ[rcExpr, ErrorT], Return[opName[arg, Sequence @@ rcExpr]]];
                        If [!ValidIndexQ[arg, KindOf[opName, arg], True], Return[ErrorT[opName][arg, expr]]];
                        If [!DnIndexQ[arg] && !MetricSpaceQ[IndexToKind @ arg],
                            Message[Msg::err, "The index of", opName, "is not down:", arg]; Return[ErrorT[opName][arg, expr]]
                        ];
                        If [DuplicatedIndicesQ[Join[{arg}, FindIndices[expr]], True], Return[ErrorT[opName][arg, expr]]];
                        opName[arg, expr]
                    ],
                LD,
                    With[{rcExpr = SyntaxCheck[{expr}]},
                        If [!FreeQ[rcExpr, ErrorT], Return[opName[arg, Sequence @@ rcExpr]]];
                        If [!checkFirstArgLD[opName, arg], Return[ErrorT[opName][arg, expr]]];
                        opName[arg, expr]
                    ],
                XD,
                    With[{rcExpr = SyntaxCheck[arg]},
                        If [!FreeQ[rcExpr, ErrorT], Return[opName[rcExpr, expr]]];
                        opName[arg, expr]
                    ],
                XP,
                    With[{rcExpr = SyntaxCheck /@ {arg, expr}},
                        If [!FreeQ[rcExpr, ErrorT], Return[opName[Sequence @@ rcExpr]]];
                        If [DuplicatedIndicesQ[Flatten @ (findIndices /@ {arg, expr}), True], Return[ErrorT[opName][arg, expr]]];
                        opName[arg, expr]
                    ]
            ]

            (* check 1st argument of LD-type operator *)
            checkFirstArgLD[LD, aV_] :=  (* check LD *)
                If [!vectorNameQ[aV], Message[Msg::err, "non-vector:", aV, "", ""]; False,
                (* else *)            True]
            checkFirstArgLD[opName_, arg_] := (* check LD-type operator *)
                If [Head[arg] =!= Symbol, Message[Msg::err, "non-symbolic argument", arg, "for an operator", opName]; False,
                (* else *)                True]

        syntaxCheckObject[(sfName_?ScalarFunctionQ)[arg_, expr___]] := (
                If [sfName === Tscalar && {expr} =!= {},
                    Message[Msg::err, "too many arguments", Length[{expr}] + 1, ". One argument is required.", ""]; Return[ErrorT[sfName][arg, expr]]
                ];

                With[{rcExpr = SyntaxCheck[#, HeadQs -> {ObjectQ}]& /@ {arg, expr}},
                    (* check each argument *)
                    If [!FreeQ[rcExpr, ErrorT], Return[sfName[Sequence @@ rcExpr]]];

                    If [FindFreeTensorialIndices[arg, HeadQs -> {ObjectQ}] =!= {},
                        Message[Msg::err, "non-scalar expression", arg, "", ""]; Return[ErrorT[sfName][arg, expr]],
                    (* else *)
                        If [{expr} =!= {} && MemberQ[FindFreeTensorialIndices[#, HeadQs -> {ObjectQ}]& /@ {expr}, {__}],
                            Message[Msg::err, "non-scalar expression:", expr, "", ""]; Return[ErrorT[sfName][arg, expr]]
                        ]
                    ]
                ];
                sfName[arg, expr];
            )
        syntaxCheckObject[sName_[args___]] :=
            With[{rcExpr = SyntaxCheck[#, HeadQs -> {ObjectQ}]& /@ {args}},
                If [!FreeQ[rcExpr, ErrorT], Return[sName[Sequence @@ args]]];
                If [Flatten[FindFreeTensorialIndices[#, HeadQs -> {ObjectQ}]& /@ {args}] =!= {},
                    Message[Msg::err, "non-scalar expression:", {args}, "in", sName]; Return[ErrorT[sName][args]]
                ];
                sName[args]
            ] /; !ObjectQ[sName] && MemberQ[FreeObjectQ[{args}, HeadQs -> {ObjectQ}], False]

checkObject[oName_?IndexedOperandQ, aIndexL_List, withMsg_:False] :=
    Catch[
        With[{nRank = GetRank[oName], len = Length[aIndexL]},
            (* check # of indices for indexedObjects including indexed DiffForms *)
            If [nRank =!= -1 && nRank =!= len,
                If [!DiffFormQ[oName] || (DiffFormQ[oName] && getDegree[oName] + nRank =!= len),
                    If [withMsg, Message[Msg::err, "invalid number of indices for", oName, ": ", aIndexL]];
                    Throw[False]
                ]
            ];

            Switch [oName,
                Kdelta,
                    (* check the kind, which is all the same *)
                    If [Length[DeleteDuplicates @ (IndexToKind /@ aIndexL)] =!= 1 && IndexToKind[First @ aIndexL] =!= NonKind,
                        If [withMsg, Message[Msg::err, "Kdelta has wrong-kind indices:", aIndexL, "", ""]]; Return[False]
                    ];

                    If [UpupDndnIndexQ[aIndexL],  (* check dn/up states which are all-dn/all-up *)
                        If [withMsg, Message[Msg::err, "Kdelta has wrong-dn/up indices:", aIndexL, "", ""]]; Return[False]
                    ],
                _,
                    (* check validity and dn/up states for each index *)
                    Do[
                        With[{kind = If [DiffFormQ[oName] && len > nRank,
                                         If [i > len - nRank, KindOf[oName, i - (len - nRank)],
                                         (* else *)           DefaultKind],
                                     (* else *)
                                         KindOf[oName, i]
                                     ]},

                            If [!ValidIndexQ[aIndexL[[i]], kind, withMsg], Throw[False]];

                            If [!MetricSpaceQ[kind],
                                With[{dnup = If [DiffFormQ[oName] && len > nRank,
                                                 If [i > len - nRank, DnupAt[oName, i - (len - nRank)],
                                                 (* else *)           -1],
                                             (* else *)
                                                 DnupAt[oName, i]
                                             ]},

                                    If [dnupState[aIndexL[[i]]] =!= dnup,
                                        If [withMsg, Message[Msg::err, oName, "has wrong-dn/up indices:", aIndexL, ""]]; Throw[False]
                                    ]
                                ]
                            ]
                        ],
                        {i, len}
                    ]
            ];

            If [DuplicatedIndicesQ[aIndexL, withMsg], Return[False]];
            True  (* no errors *)
        ]
    ]

(********************************************************************)
(********************************************************************)
(********************************************************************)

(********** postEval **********)

SetAttributes[postEval, {HoldAll, Listable}];
postEval[expr_] := (
        If [flagTable[SyntaxCheckFlag],
            With[{rcExpr = SyntaxCheck[expr]},
                If [!FreeQ[rcExpr, ErrorT], Return[rcExpr]]  (* there are errors *)
            ]
        ];

        ForEachTerm[ExpandObject[expr], canObject] /. $PROTECTEXPANDING -> Identity  (* See CollectForm for $PROTECTEXPANDING *)
    ) /; FreePatternQ[expr] && (!FreeObjectQ[expr] || !FreeQ[expr, ErrorT])  (* ErrorT is NOT an object *)
postEval[expr_, ___] := expr /. $PROTECTEXPANDING -> Identity

    canObject[term_] := Module[{rcTerm = term},
        If [!flagTable[MarkErrorFlag], rcTerm = rcTerm /. ErrorT -> Identity];
        If [flagTable[ResetDummiesFlag], rcTerm = ResetDummies[rcTerm, HeadQs -> {IndexedObjectQ}]];
        rcTerm /. $flattenOTHER[other_] :> other
    ]

(********** On/Off **********)

Unprotect[Off]  (* turn off a flag *)
Off[AutoFlag]         := (flagTable[AutoFlag] = False; $Post =.;)
Off[MarkErrorFlag]    := (flagTable[MarkErrorFlag] = False;)
Off[ResetDummiesFlag] := (flagTable[ResetDummiesFlag] = False;)
Off[SyntaxCheckFlag]  := (flagTable[SyntaxCheckFlag] = False;)

Off[CoordinateBasisFlag]        := Off[CoordinateBasisFlag[DefaultKind]]
Off[CoordinateBasisFlag[kind_]] := (
        If [!CheckKind[kind], Return[$Failed]];

        (* update all GammaDerOp's symmetry *)
        If [CoordinateBasisQ[kind] === True,  (* previously *)
            defineOperand[
                getDerOp[Gamma][#], "abc", {kind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["\[CapitalGamma]", #]
            ]& /@ getDerOperators[kind]
        ];

        (* define Structuref *)
        If [kind === DefaultKind,
            defineOperand[Structuref, "-bac", {kind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> "f"];
            GetStructuref[kind] = Structuref,
        (* else *)
            defineOperand[SymbolJoin[Structuref, kind], "-bac", {kind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> "f"];
            GetStructuref[kind] = SymbolJoin[Structuref, kind]
        ];

        CoordinateBasisQ[kind] = False;
    )
Protect[Off]

Unprotect[On]  (* turn on a flag *)
On[AutoFlag]         := (flagTable[AutoFlag] = True; $Post = postEval;)
On[MarkErrorFlag]    := (flagTable[MarkErrorFlag] = True;)
On[ResetDummiesFlag] := (flagTable[ResetDummiesFlag] = True;)
On[SyntaxCheckFlag]  := (flagTable[SyntaxCheckFlag] = True;)

On[CoordinateBasisFlag]        := On[CoordinateBasisFlag[DefaultKind]]
On[CoordinateBasisFlag[kind_]] := (
        If [!CheckKind[kind], Return[$Failed]];

        (* update all GammaDerOp's symmetry *)
        If [CoordinateBasisQ[kind] === False,
            defineOperand[
                getDerOp[Gamma][#], If [TorsionFreeQ[#], "+bac", "abc"], {kind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["\[CapitalGamma]", #]
            ]& /@ getDerOperators[kind]
        ];

        (* clear Structuref[kind] *)
        GetStructuref[kind] = Null;
        If [kind === DefaultKind,
            If [IndexedTensorQ[Structuref], Clear[Structuref]],
        (* else *)
            If [IndexedTensorQ[SymbolJoin[Structuref, kind]], removeObject @ SymbolJoin[Structuref, kind]]
        ];

        CoordinateBasisQ[kind] = True;
   )
Protect[On]

(********************************************************************)

initIndexNotation[] := (
        (***** Default Options *****)
        Options[HeadQs]  = {HeadQs  -> {IndexedObjectQ}};  (* for selecting Heads to exclude ScalarFunctions. *)
        Options[IndexQs] = {IndexQs -> {True&}};           (* for selecting indices *)
        reservedNameList = {HeadQs, IndexQs};

        (* When reloading, Unprotect and TagUnset previously introduced index symbols *)
        If [ValueQ[loadedIndexNotation], setIndices[{}, #]& /@ definedKindList];

        (***** Indices *****)
        Unprotect[DefaultKind];
        DefaultKind := Latin;  (* for ValidIndexQ *)
        Protect[DefaultKind];

        definedKindList = {};        (* initialize *)
        DefKind[Latin, Alphabet[]];  (* pre-defined Kind *)
        reservedNameList = Join[reservedNameList, {All, Latin}];

        (* DefKind/UndefKind *)
        reservedNameList = Join[reservedNameList, {Epsilon, Structuref, Torsion}];

        (***** Defining Indexed Objects *****)
        reservedNameList = Join[reservedNameList, {C, D, E, I, N, O}];  (* Protected names in Mathematica *)
        reservedNameList = Join[reservedNameList, {CD, LD, XD, XP}];    (* Operator Types *)
        reservedNameList = Join[reservedNameList, {Tscalar, ErrorT}];   (* Predefined ScalarFunction and ErrorT *)

        (* Predefined Indexed Objects: Kdelta. *)
        defineOperand[Kdelta, "2",  {DefaultKind}, {-1, 1}, IndexedTensorQ, PrintAs -> "\[Delta]"];  (* \delta_a^{\ b} *)
        Kdelta[i_Integer, j_Integer] := KroneckerDelta[i, -j];
        reservedNameList = Join[reservedNameList, {Kdelta}];

        (***** Off *****)
        Off[General::spell1];
        Off[General::spell];

        (* Default Flags *)
        On[AutoFlag];
        On[MarkErrorFlag];
        On[ResetDummiesFlag];
        Off[SyntaxCheckFlag];

        (* initial CoordinateBasisFlag of DefaultKind *)
		On[CoordinateBasisFlag[DefaultKind]];

        (***** End of initIndexNotation *****)
        reservedNameList = DeleteDuplicates[reservedNameList];
        loadedIndexNotation = True;
    )
initIndexNotation[];

(********************************************************************)
End[] (* End Private Context *)
EndPackage[]
