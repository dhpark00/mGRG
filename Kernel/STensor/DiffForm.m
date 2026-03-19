(********************************************************************)
(**************************** DiffForm.m ****************************)
(********************************************************************)

(********************************************************************)
BeginPackage["mGRG`STensor`", {"mGRG`mPerm`"}]
(********************************************************************)

(********************************************************************)
Begin["`Private`"]

(******************** Define differential forms *********************)
(*
    DiffForm은 항상 DefaultKind에서 정의된다.
    만일 DefaultKind를 변경하면 이미 정의된 DiffForm은 다른 Kind를 갖게 되므로 내부 동작에서 문제가 발생한다.
    (예를 들면, Kind에 따라 차원이 다르므로 차원과 관련된 DiffForm의 연산 결과가 달라질 수 있다.)
    따라서 DiffForm 연산 도중에 DefaultKind를 변경하면 안된다.
*)
UndefForm[fName_?DiffFormQ] := (
        fName/: MakeBoxes[fName[args___], StandardForm] =.;
        fName/: MakeBoxes[fName, StandardForm] =.;
        fName/: getDegree[fName] =.;
        fName/: getDnupL[fName] =.;
        fName/: getKindL[fName] =.;
        fName/: getGenSet[fName] =.;
        fName/: getRank[fName] =.;
        fName/: getPrtStr[fName] =.;
        fName/: getType[fName] =.;
        fName/: IndexedOperandQ[fName] =.;
        fName/: IndexedObjectQ[fName] =.;
    )
UndefForm[___] := Message[UndefForm::usage]

DefForm = Fdefine  (* alias *)

(* no shapes *)
Fdefine[fName_Symbol,   p_Integer?NonNegative, opts:OptionsPattern[]] := Fdefine[fName[], p, opts]
Fdefine[fName_Symbol[], p_Integer?NonNegative, opts:OptionsPattern[]] := defineForm[fName, p, "", {}, {}, opts]

(* various shapes *)
Fdefine[fName_Symbol[shapes:((_Symbol)..)], p_Integer?NonNegative,               opts:OptionsPattern[]] := Fdefine[fName[shapes], p, ToString[Length @ {shapes}], opts]
Fdefine[fName_Symbol[shapes:((_Symbol)..)], p_Integer?NonNegative, permS_String, opts:OptionsPattern[]] := defineForm[fName, p, permS, IndexToKind /@ {shapes}, dnupState /@ {shapes}, opts]
Fdefine[___] := Message[Fdefine::usage]

(*** Local Functions ***)

Options[defineForm] = {PrintAs -> Automatic};

defineForm[fName_Symbol, p_Integer, permS_String, idxKindL_List, dnupL_List, opts:OptionsPattern[]] :=
    With[{rankAndGS = toRankAndGenSet[permS]},
        If [rankAndGS[[2]] === "Error", Message[Msg::err, "invalid:", permS, "", ""]; Return[$Failed]];
        If [rankAndGS[[1]] =!= -1 && rankAndGS[[1]] =!= Length[idxKindL],
            Message[Msg::err, "incompatible arguments for the length of indices", "", "", ""]; Return[$Failed]
        ];
        If[!checkName[fName], Return[$Failed]];

		With [{n = GetDimension[kind]},
	        If [PositiveIntegerQ[n] && p > n,
	        	Message[Msg::warn, "degree", p, "exceeds dimension", n];
	            fName[args___] := 0 /; FreePatternQ[{args}];
	            Return[]
	        ]
		];

        getDegree[fName] ^= p;
        defineOperand[fName, permS, idxKindL, dnupL, DiffFormQ, opts];
        getKindL[fName] ^= Join[Table[DefaultKind, {p}], idxKindL];  (* for indexed DiffForms *)

        (* custom formatting for differential forms *)
        With[{prtStr = OptionValue[PrintAs] /. Automatic -> ToString[fName]},
            fName/: MakeBoxes[fName,          StandardForm] := makeFormBox[fName, p, prtStr];
            fName/: MakeBoxes[fName[args___], StandardForm] := makeIndexedFormBox[fName, {args}, p, prtStr]
        ];
    ]

        makeFormBox[fName_, p_, prtStr_] :=
            interpretBox[fName,
                With[{rank = getRank[fName]},
                    If [rank === 0,
                        StyleBox[prtStr, FontWeight -> "Bold"],  (* as a DiffForm *)
                    (* else *)
                        (* errMsg[rank];  <-- comment out to stop further interpreting *)
                        With[{str = ToString @ fName},
                            StyleBox[MakeBoxes[str, StandardForm], FontColor -> Red]  (* error *)
                        ]
                    ]
                ]
            ]

        makeIndexedFormBox[fName_, {args___}, p_, prtStr_] :=
            interpretBox[fName[args],
                With[{len = Length[{args}], rank = getRank[fName]},
                    If [len === 0,
                        If [rank === 0 || rank === -1,
                            StyleBox[prtStr, FontWeight -> "Bold"],  (* as a DiffForm *)
                        (* else *)
                            (* errMsg[rank];  <-- comment out to stop further interpreting *)
                            With[{str = ToString @ fName},
                                StyleBox[MakeBoxes[str[args], StandardForm], FontColor -> Red]  (* error *)
                            ]
                        ],
                    (* else *)
                        With[{idxL = Transpose[
                                        With[ {rc = indexCharSpace[#]},
                                            If [IndexToKind[#] =!= NonKind && UpIndexQ[#],
                                                rc[[{2, 1}]],
                                            (* else *)
                                                rc[[{1, 2}]]
                                            ]
                                        ]& /@ {args}
                                     ]},

                            If [rank === -1 || len === rank,  (* as a DiffForm *)
                                SubsuperscriptBox[StyleBox[prtStr, FontWeight -> "Bold"],
                                                  TemplateBox[idxL[[1]], "RowDefault"], TemplateBox[idxL[[2]], "RowDefault"]],
                            (* else *)
                                If [len === rank + p,  (* as an ordinary indexed tensor *)
                                    SubsuperscriptBox[prtStr, TemplateBox[idxL[[1]], "RowDefault"], TemplateBox[idxL[[2]], "RowDefault"]],
                                (* else *)
                                    (* errMsg[rank];  <-- comment out to stop further interpreting *)
                                    With[{str = ToString @ fName},
                                        StyleBox[MakeBoxes[str[args], StandardForm], FontColor -> Red]  (* error *)
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]

            errMsg[rank_] :=
                If [p === 0,
                    Message[Msg::err, "requires", rank, "indices.", ""],
                (* else *)
                    With[{str = ToString[rank] <> " or " <> ToString[rank + p]},
                        Message[Msg::err, "requires", str, "indices.", ""]
                    ]
                ]

(******************** Operators on DiffForms ************************)

(*** Local Constants ***)
formOpList = {XP, XD, IP, HodgeStar, CoXD}  (* used on freeFormQ *)

(*** exterior product ***)
defineOperator[XP, "", XP]

(* automatically convert Wedge to XP for diff. forms *)
(* NB: 1) Alias of Wedge is ESC ^ ESC in Notebook environment.
       2) Without the context Global`, the symbol Wedge is in Private in Ver. 4.1
          In Ver. 6, Wedge is in System` *)
If [$VersionNumber >= 6.0, Wedge[a_, b__] := XP[a, b] /; FreePatternQ[{a, b}] && !AllTrue[{a, b}, freeFormQ]]

(* formatting operator XP *)
XP/: MakeBoxes[XP[arg1_, args__], StandardForm] := interpretBox[XP[arg1, args],
        TemplateBox[
            MakeBoxes[#, StandardForm]& /@ (Flatten @ Fold[List[#1, "\[Wedge]", #2]&, arg1, {args}]),
            "RowDefault"
        ]
    ]

(* rules *)
XP[expr_]                           := expr /; FreePatternQ[expr]
XP[pre___, expr_Plus,  post___]     := Map[XP[pre, #, post] &, expr] /; FreePatternQ[{pre, expr, post}]
XP[pre___, expr_Times, post___]     := XP[pre, Sequence @@ expr, post] /; FreePatternQ[{pre, expr, post}]
(* comment out due to ftocRec
XP[pre___, XP[args__], post___]     := XP[pre, args, post] /; FreePatternQ[{pre, args, post}]

(2026.03.20) XP 표현을 단순화하기 위한 규칙을 따로 설정:
XPsimpRules = {XP[pre___, XP[args__], post___] :> XP[pre, args, post] /; FreePatternQ[{pre, args, post}]};
*)
XP[]                                := 1
XP[pre___, a_, post___]             := a * XP[pre, post] /; FreePatternQ[{pre, a, post}] && ZeroDegreeQ[a]
XP[args__]                          := 0 /; FreePatternQ[{args}] && PositiveIntegerQ[GetDimension[DefaultKind]] && (Plus @@ Map[DegreeForm, {args}]) > GetDimension[DefaultKind]
XP[pre___, a_, mid___, a_, post___] := 0 /; FreePatternQ[{pre, a, mid, post}] && OddQ[DegreeForm[a]]
XP[args__]                          :=
    With[{fL = {args}},
        Catch[
            With[{doXP =
                    With[{signANDfL = exteriorProduct[fL[[#2]], #1[[2]]]},
                        If [signANDfL[[1]] === 0, Throw[0]];
                        {#1[[1]] * signANDfL[[1]], signANDfL[[2]]}
                    ]&},
                With[{rcL = Fold[doXP, {1, {}}, Range[Length[fL], 1, -1]]},
                    rcL[[1]] * XP[Sequence @@ rcL[[2]]]
                ]
            ]
        ]
    ] /; FreePatternQ[{args}] && !OrderedQ[{args}, formOrderedQ]

    (* return {sign, fL}. fL is sorted *)
    exteriorProduct[aF_, {}]      := {1, {aF}}
    exteriorProduct[aF_, fL_List] := (* insert aF to fL and sort in accending order. return {sign, rcFL} *)
        Module[{rcFL = fL, rcDeg = 0},
            With[{aDeg = DegreeForm[aF]},
                Do [
                    With[{bDeg = DegreeForm @ fL[[i]]},
                        (* if ordered, insert *)
                        If [formOrderedWithQ[aF, aDeg, fL[[i]], bDeg],
                            rcFL = Insert[fL, aF, i]; Break[]
                        ];
                        rcDeg += bDeg
                    ],
                    {i, Length[fL]}
                ];

                If [rcFL === fL, rcFL = Append[fL, aF]];
                {(-1)^(aDeg * rcDeg), rcFL}
            ]
        ]

(*** interior product ***)
defineOperator[IP, "\[Iota]", LD]

(* rules *)
IP[v_, 0]                := 0 /; FreePatternQ[{v}] && vectorNameQ[v]
IP[v_, IP[v_, expr_]]    := 0 /; FreePatternQ[{v, expr}] && vectorNameQ[v] && DegreeForm[expr] >= 2
IP[v_, expr_Plus]        := Map[IP[v, #]&, expr] /; FreePatternQ[{v, expr}]
IP[v_, a_ * expr_]       := a IP[v, expr] /; FreePatternQ[{v, expr}] && ZeroDegreeQ[a] && DegreeForm[expr] >= 1
IP[v_, XP[pre_, post__]] := XP[IP[v, pre], post] + (-1)^DegreeForm[pre] XP[pre, IP[v, post]] /; FreePatternQ[{v, pre, post}] && vectorNameQ[v]
(*
IP[v_, expr_] := If [DegreeForm[expr] == 0, ErrorT[IP[v, expr]]]
*)

(*** exterior derivative ***)
defineOperator[XD, "d", XD]

(* rules *)
XD[expr_Plus] := Map[XD, expr] /; FreePatternQ[expr]
XD[a_ * b_]   := XP[XD[a], b] + XP[a, XD[b]] /; FreePatternQ[{a, b}]  (* a and b are any exprs. *)
XD[XD[expr_]] := 0 /; FreePatternQ[expr]
XD[XP[fs__]]  := (
        If [PositiveIntegerQ[GetDimension[DefaultKind]],
            If [DegreeForm[XP[fs]] >= GetDimension[DefaultKind], Return[0]] (* when p > Dimension *)
        ];

        With[{fL = {fs}},
            With[{doXD = With[{deg = DegreeForm[fL[[#2]]]},
                            { #1[[1]] + deg, If [Head[fL[[#2]]] =!= XD, #1[[2]] + (-1)^(#1[[1]] * deg) XP[XD[fL[[#2]]], XP[Sequence @@ Drop[fL, {#2}]]],
                                             (* else *)                 #1[[2]]] }
                         ]&},
                Fold[doXD, {0, 0}, Range[Length[fL]]] [[2]]
            ]
        ]
    ) /; FreePatternQ[{fs}]

(* comment out:
XD[fName_Symbol]    := XD[fName[]] /; FreePatternQ[fName] && DiffFormQ[fName]
 *)
XD[fName_[args___]] := 0 /; FreePatternQ[{fName, args}]  \
                            && ( DiffFormQ[fName] && (PositiveIntegerQ[GetDimension[DefaultKind]] && DegreeForm[fName[args]] >= GetDimension[DefaultKind]) )
XD[_?ConstantQ]     := 0

(*** LD ***)
LD[v_, XP[fs__]] :=
    With[{rcL = Map[LD[v, #]&, {fs}]},
        Sum[ReplacePart[XP[fs], i -> rcL[[i]]], {i, 1, Length[{fs}]}]
    ]

LDtoXDRule[] = {
        LD[v_, aF_] :> IP[v, XD[aF]] + XD[IP[v, aF]] /; FreePatternQ[{v, aF}] && vectorNameQ[v] && !freeFormQ[aF]
    }

(*** HodgeStar ***)
defineOperator[HodgeStar, "*", XD]

(* rules *)
HodgeStar[expr_Plus]        := Map[HodgeStar, expr] /; FreePatternQ[expr]
HodgeStar[HodgeStar[expr_]] :=
    With[{n = GetDimension[DefaultKind], s = GetSig[DefaultKind], p = DegreeForm[expr]},
        (-1)^(s + p*(n+1)) * expr /; FreePatternQ[expr]
    ]
HodgeStar[s_. * expr_]      := -HodgeStar[Abs[s] * expr] /; FreePatternQ[{s, expr}] && Negative[s]

(*** Co-differential ***)
defineOperator[CoXD, "\[Delta]", XD]

(* rules *)
CoXD[expr_Plus]   := Map[CoXD, expr] /; FreePatternQ[expr]
CoXD[CoXD[expr_]] := 0 /; FreePatternQ[expr]
CoXD[expr_]       := 0 /; FreePatternQ[expr] && ZeroDegreeQ[expr]
CoXD[s_. * expr_] := -CoXD[Abs[s] * expr] /; FreePatternQ[{s, expr}] && Negative[s]

CoXDRule[] = {
        CoXD[expr_] :>
            With[{n = GetDimension[DefaultKind], s = GetSig[DefaultKind], p = DegreeForm[expr]},
                (-1)^(s + p*n) HodgeStar[XD[HodgeStar[expr]]]
            ]
    }

(******************** Operations on DiffForms ***********************)

(*** apply XD to an expr ***)
ApplyXD[expr_List] := Map[ApplyXD, expr] /; FreePatternQ[expr]
ApplyXD[expr_]     :=
	With[{rcExpr = ExpandObject[expr]},
		If [Head[rcExpr] === Plus, applyXDTerm /@ rcExpr, applyXDTerm[rcExpr]]
	] /; VectorQ[GetCoordinates[DefaultKind]]
ApplyXD[expr__] := XD[expr]

	applyXDTerm[term_] :=
		With[{ordANDfTerm = splitForm[term]},
			Plus @@ ((BD[#, ordANDfTerm[[1]]] * XP[XD[#], ordANDfTerm[[2]]])& /@ GetCoordinates[DefaultKind])	+ ordANDfTerm[[1]] * XD[ordANDfTerm[[2]]]
		]

(*** CollectForm ***)
CollectForm[expr_, opts___] :=
    Module[{rcExpr = ExpandObject[expr, opts]},
        If [Head[rcExpr] === Plus,
            rcExpr = Append[#, False]& /@ splitForm /@ (List @@ rcExpr);  (* {{ord, form, False} ..} *)
            Do [
                With[{posL = Position[rcExpr[[i+1 ;; -1]], rcExpr[[i,2]]][[All,1]] + i},
                	Do [
                    	If [rcExpr[[posL[[j]],3]] =!= True, rcExpr[[i,1]] += rcExpr[[posL[[j]],1]]];
                    	rcExpr[[posL[[j]],3]] = True,  (* mark *)
                    	{j, Length[posL]}
                	]
                ],
               	{i, Length[rcExpr]}
            ];
            rcExpr = (#[[1]] * #[[2]])& /@ Select[rcExpr, (#[[3]] =!= True)&];  (* {ord * form, ..} *)
            $PROTECTEXPANDING[Plus @@ rcExpr],
        (* else *)
            rcExpr
        ]
    ]

(*** return degree of a form ***)
DegreeForm[fName_Symbol]     := If [getRank[fName] =!= 0,              0, getDegree[fName]] /; DiffFormQ[fName]
DegreeForm[fName_[args___]]  := If [getRank[fName] =!= Length[{args}], 0, getDegree[fName]] /; DiffFormQ[fName]
DegreeForm[XD[expr_]]        := 1 + DegreeForm[expr]
DegreeForm[XP[args__]]       := Total[DegreeForm /@ {args}]
DegreeForm[LD[_, expr_]]     := DegreeForm[expr]
DegreeForm[IP[_, expr_]]     := DegreeForm[expr] - 1
DegreeForm[HodgeStar[expr_]] := GetDimension[DefaultKind] - DegreeForm[expr]
DegreeForm[CoXD[expr_]]      := DegreeForm[expr] - 1
DegreeForm[expr_Times]       := Total[DegreeForm /@ (List @@ expr)]
DegreeForm[___]              := 0

(*** is expr zero-form or non-form? ***)
ZeroDegreeQ[fName_Symbol]     := DegreeForm[fName]       === 0 /; DiffFormQ[fName]
ZeroDegreeQ[fName_[args___]]  := DegreeForm[fName[args]] === 0 /; DiffFormQ[fName]
ZeroDegreeQ[XD[_]]            := False
ZeroDegreeQ[XP[__]]           := False
ZeroDegreeQ[LD[_, expr_]]     := ZeroDegreeQ[expr]
ZeroDegreeQ[IP[_, expr_]]     := DegreeForm[expr] === 1
ZeroDegreeQ[HodgeStar[expr_]] := DegreeForm[expr] === GetDimension[DefaultKind]
ZeroDegreeQ[CoXD[expr_]]      := DegreeForm[expr] === 1
ZeroDegreeQ[_]                := True   (* non-form or function of zero-form *)

(***** Local Functions *****)

(* ordered by degree *)
formOrderedQ[aF_, bF_] := formOrderedWithQ[aF, DegreeForm[aF], bF, DegreeForm[bF]]

formOrderedWithQ[_,               aDeg_, _,               bDeg_] := True  /; aDeg < bDeg
formOrderedWithQ[_,               aDeg_, _,               bDeg_] := False /; aDeg >  bDeg
formOrderedWithQ[fName_,          _,     XD[_],           _]     := False /; DiffFormQ[fName]
formOrderedWithQ[fName_[___],     _,     XD[_],           _]     := False /; DiffFormQ[fName]
formOrderedWithQ[XD[_],           _,     fName_,          _]     := True  /; DiffFormQ[fName]
formOrderedWithQ[XD[_],           _,     fName_[___],     _]     := True  /; DiffFormQ[fName]
formOrderedWithQ[fName_[args___], _,     fName_[brgs___], _]     := IndexOrderedQ[{args}, {brgs}] /; DiffFormQ[fName]
formOrderedWithQ[op_[aF_],        _,     op_[bF_],        _]     := formOrderedQ[aF, bF] /; MemberQ[formOpList, op]
formOrderedWithQ[aName_[___],     _,     bName_[___],     _]     := OrderedQ[{aName, bName}]
formOrderedWithQ[aF_,             _,     bF_,             _]     :=
	If [VectorQ[GetCoordinates[DefaultKind]] && SubsetQ[GetCoordinates[DefaultKind], {aF, bF}],  (* Ordering with the coordinate systems *)
		Position[GetCoordinates[DefaultKind], aF][[1,1]] <= Position[GetCoordinates[DefaultKind], bF][[1,1]],
	(* else *)
		OrderedQ[{aF, bF}]
	]

freeFormQ[LD[_?vectorNameQ, expr_]] := freeFormQ[expr]  (* LD is both the tensor and the diff. form operator *)
freeFormQ[_?DiffFormQ]              := False
freeFormQ[expr_]                    := FreeObjectQ[expr, HeadQs -> {(DiffFormQ[#] || MemberQ[formOpList, #])&}]
freeFormQ[___]                      := True

splitForm[term_Times]      := Times @@ Map[splitForm, List @@ term]
splitForm[fName_[args___]] := If [getRank[fName] =!= Length[{args}], {fName[args], 1}, {1, fName[args]}] /; DiffFormQ[fName]  (* cover fname[components] *)
splitForm[fOp_[arg_]]      := {1, fOp[arg]} /; MemberQ[formOpList, fOp]
splitForm[term_]           := {1, term} /; !freeFormQ[term]  (* cover fname *)
splitForm[expr_]           := {expr, 1}

(***** FtoC *****)

(*****************************************************************************)
(**************************** with Gemini 3.1 ********************************)
(*****************************************************************************)

(***** 1. DegreeForm[expr] => degree of expr *****)

(***** 2. AntisymmetrizeIndices: 완전 반대칭화(Totally Antisymmetric) *****)

(***** 3. 재귀적 FtoC 마스터 함수 (외부 호출용) *****)
FtoC[expr_Plus] := FtoC /@ expr;
FtoC[expr_] :=
    With[{rcExpr = ExpandObject[expr], n = GetDimension[DefaultKind]},
        If [!FreeQ[rcExpr, HodgeStar], If [!PositiveIntegerQ[n], Message[Msg::err, "Need to SetDimension[]","", "", ""]; Return[$Failed]]];

        If [Head[rcExpr] === Plus,
            FtoC /@ rcExpr,
        (* else *) (* a term *)
            With[{idxL = FindIndicesAll[rcExpr, IndexQs -> {KindIndexQ[DefaultKind]}]},  (* all indices of the "term" (including non-zero rank diff. forms *)
                Module[{p = DegreeForm[rcExpr], dnL},
(* comment out
                    If[p == 0, Return[rcExpr]];
*)

                    (* DefaultKind의 dn-인덱스를 idxL을 고려하여 자동 생성 *)
                    dnL = Complement[SymbolJoin["l", #]& /@ getCharacters[DefaultKind], ToDnIndex /@ idxL];
                    If [p > Length[dnL], Message[Msg::err, "Too few available indices: ", dnL, "", ""]; Return[$Failed]];

                    ftocRec[rcExpr, Take[dnL, p]]
                ]
            ]
        ]
    ];

(************************************************************************)
(* [ FtoC Recursive Engine ]
   참고: 이 블록의 '재귀적 지표 분배(Recursive Distribution)' 알고리즘은
   xAct 패키지의 xForm 모듈이 사용하는 파싱 아키텍처를 STensor에 이식한 것임.        *)
(************************************************************************)

(* 사용자가 수동으로 인덱스 리스트를 지정하고 싶을 때의 오버로딩: 수동으로 입력된 인덱스의 정당성은 <확인하지 않음>. *)
FtoC[expr_, dnL_List] := ftocRec[expr, dnL];

(***** 4. ftocRec 재귀 분배 로직 (Recursive Logic) *****)

(* 선형성 (Plus 분배) *)
ftocRec[expr_Plus, dnL_List] := ftocRec[#, dnL] & /@ expr;

(* 스칼라 곱 (0-form은 독립적으로 FtoC) *)
ftocRec[f_ * A_, dnL_List] /; DegreeForm[f] == 0 := FtoC[f] * ftocRec[A, dnL];

(* XD *)
ftocRec[XD[A_], dnL_List] :=
    With[{derOp = If[TorsionFreeQ[CD] && flagTable[XDtoCDfrag], CD, BD]},
        Length[dnL] * TindexSort @ AntisymmetrizeIndices[ derOp[ dnL[[1]], ftocRec[A, Rest[dnL]] ], dnL ]
    ];

(* XP (2항) *)
ftocRec[XP[A_, B_], dnL_List] :=
    Module[{p = DegreeForm[A], q = DegreeForm[B], idxA, idxB},
        idxA = Take[dnL, p];
        idxB = Drop[dnL, p];
        (Factorial[p + q] / (Factorial[p] * Factorial[q])) * TindexSort @ AntisymmetrizeIndices[ ftocRec[A, idxA] * ftocRec[B, idxB], dnL ]
    ];

(* XP (다항 결합: XP[A,B,C,...] -> XP[A, XP[B,C,...]]) *)
ftocRec[XP[A_, B_, CC__], dnL_List] := ftocRec[XP[A, XP[B, CC]], dnL];

(* Base Case: 단일 텐서에 도달하면 STensor 규칙대로 폼 지표를 맨 앞에 삽입 *)
ftocRec[A_Symbol[],       {}]       := A;
ftocRec[A_Symbol[idx___], dnL_List] := A[Sequence @@ dnL, idx];
ftocRec[A_Symbol,         {}]       := A;
ftocRec[A_Symbol,         dnL_List] := A[Sequence @@ dnL];

(*****************************************************************************)
(*****************************************************************************)
(*****************************************************************************)

(* 나머지 표현들 *)
ftocRec[LD[v_, f_],    {}]   := With[{pair = NewDummy[]}, v[pair[[2]]] CD[pair[[1]], f]] /; vectorNameQ[v] && ZeroDegreeQ[f];
ftocRec[LD[v_, expr_], dnL_List] := LD[v, ftocRec[expr, dnL]] /; dnL =!= {};
ftocRec[IP[v_, expr_], dnL_List] :=
    If [DegreeForm[expr] == 0,
        IP[v, expr],  (* wrong operation *)
    (* else *)
        With[{pair = NewDummy[]},
            With[{idxL = Prepend[dnL, pair[[1]]]},
                v[pair[[2]]] * (TindexSort @ AntisymmetrizeIndices[ ftocRec[expr, idxL], idxL ])
            ]
        ]
    ];

ftocRec[HodgeStar[expr_], dnL_List] :=
    Module[{n = GetDimension[DefaultKind], p, downL, upL, freeL},
        If [!PositiveIntegerQ[n], Message[Msg::err, "Need to SetDimension[]","", "", ""]; Return[HodgeStar[expr]]];

        p = DegreeForm[expr];
        If [Length[dnL] =!= n - p, Message[Msg::err, "invalid number of indices", dnL, "for", HodgeStar[expr]]; Return[$Failed]];

        If [p === 0,
            dualStarFtoC[ ftocRec[expr, {}], dnL ],
        (* else *)
            {downL, upL} = Transpose @ Table[NewDummy[], p];
            dualStarFtoC[ ftocRec[expr, downL], Join[upL, dnL]]
        ]
    ];
ftocRec[CoXD[expr_], dnL_List] :=
    With[{pair = NewDummy[]},
        -CD[pair[[2]], ftocRec[expr, Prepend[dnL, pair[[1]]]]]
    ];
ftocRec[expr_, __] := expr  (* any others *)

    (* cf: DualStar[expr, indexL] 함수의 indexL은 eps 인덱스의 일부분이지만, dualStarFtoC[expr, indexL] 함수의 indexL은 eps 인덱스의 전부. *)
    dualStarFtoC[expr_, indexL_] :=
        With[{rcExpr = ExpandObject[Dum[expr]]},
            With[{tmpTerm = If [Head[rcExpr] === Plus, rcExpr[[1]], rcExpr], n = GetDimension[DefaultKind]},
                If [Length[indexL] < 2 || (PositiveIntegerQ[n] && Length[indexL] =!= n),
                    Message[Msg::err, "Invalid numbers of indices: ", indexL, "", ""]; Return[]
                ];

                (* $FormDropIndices -> True for non-zero rank diff. forms *)
                With[{freeL = Select[FindFreeTensorialIndicesAll[tmpTerm, IndexQs -> {KindIndexQ[DefaultKind]}, $FormDropIndices -> True],
                                     (DnIndexQ[#] || UpIndexQ[#])&]},

                    If [PositiveIntegerQ[n] && Length[freeL] > n,
                        Message[Msg::err, "Invalid numbers of free indices: ", freeL, "", ""]; Return[]
                    ];

                    If [freeL =!= {} && (Intersection[freeL, indexL] =!= {} || Intersection[FlipIndex /@ freeL, indexL] === {}),
                        Message[Msg::err, "Ill-formed indices: ", indexL, "", ""]; Return[]
                    ];

                    With[{eps = GetEpsilon[DefaultKind]},
                        (1/Length[freeL]!) * rcExpr * eps[Sequence @@ indexL]
                    ]
                ]
            ]
        ];

(*****************************************************************************)
(********************** old version (to be deleted) **************************)
(*****************************************************************************)

    fToC[expr_, indexL_List] :=
        With[{rcExpr = ExpandObject[expr], n = GetDimension[DefaultKind]},
            If [!FreeQ[rcExpr, HodgeStar], If [!PositiveIntegerQ[n], Message[Msg::err, "Need to SetDimension[]","", "", ""]; Return[]]];
            If [PositiveIntegerQ[n], If [Length[indexL] > n, Message[Msg::err, "Invalid numbers of indices: ", indexL, "", ""]; Return[]]];

            With[{term = If [Head[rcExpr] === Plus, rcExpr[[1]], rcExpr]},
            	With[{freeL = FindFreeTensorialIndicesAll[term, IndexQs -> {KindIndexQ[DefaultKind]}]},  (* all free indices of the "term" (including non-zero rank diff. forms *)
            		If [Intersection[Join[freeL, FlipIndex /@ freeL], indexL] =!= {},
                		Message[Msg::err, "invalid indices: ", indexL, "for free indices", freeL]; Return[]
            		];
            		If [PositiveIntegerQ[n],
                        If [Length[freeL] > n, Message[Msg::err, "Invalid numbers of free indices: ", freeL, "", ""]; Return[]]
            		];

            		If [Head[rcExpr] === Plus, f2cTerm[#, indexL]& /@ rcExpr, f2cTerm[rcExpr, indexL]]
            	]
            ]
        ]

        f2cTerm[term_, indexL_] :=
            With[{ordANDfTerm = splitForm[term]},
            	If [ordANDfTerm[[2]] === 1, Return[term]];

            	If [DegreeForm[ordANDfTerm[[2]]] =!= Length[indexL],
                    Message[Msg::err, "invalid number of indices", indexL, "for", ordANDfTerm[[2]]]; Return[]
                ];

            	With[{rcL0 = If [Head[ordANDfTerm[[2]]] === Times, List @@ ordANDfTerm[[2]], List[ordANDfTerm[[2]]]]},  (* {A1, A2, ...} *)
					With[{doL =
							With[{p = DegreeForm[#1[[1,#2]]]},
                				{ReplacePart[#1[[1]], #2 -> f2cObject[#1[[1,#2]], Take[#1[[2]], p]]],  (* update rcL0 *)
                                 Drop[#1[[2]], p]}                                                     (* update indexL *)
							]&},
						With[{rcL = Fold[doL, {rcL0, indexL}, Range[Length @ rcL0]]},
							ordANDfTerm[[1]] * (Times @@ rcL[[1]])
						]
					]
            	]
            ]

            f2cObject[fName_Symbol,    indexL_] := fName[Sequence @@ indexL]       /; DiffFormQ[fName]
            f2cObject[fName_[args___], indexL_] := fName[Sequence @@ indexL, args] /; DiffFormQ[fName]
            f2cObject[XD[expr_],       indexL_] :=
                With[{op = If[TorsionFreeQ[CD] && flagTable[XDtoCDfrag], CD, BD]},
                    Length[indexL] * (TindexSort @ AntisymmetrizeIndices[op[First @ indexL, FtoC[expr, Drop[indexL, 1]]], indexL])
                ]

            f2cObject[XP[args__],      indexL_] :=
                With[{rcL0 = {args}},
                    With[{doL =
                            With[{ip = DegreeForm[#1[[1,#2]]]},
                                {ReplacePart[#1[[1]], #2 -> (1/Factorial[ip]) * FtoC[#1[[1,#2]], Take[#1[[2]], ip]]],  (* update rcL0 *)
                                 Drop[#1[[2]], ip]}                                                                    (* update indexL *)
                            ]&},
                        With[{rcL = Fold[doL, {rcL0, indexL}, Range[Length @ rcL0]]},
                            Factorial[Length @ indexL] * TindexSort @ AntisymmetrizeIndices[Times @@ rcL[[1]], indexL]
                        ]
                    ]
                ]
            f2cObject[LD[v_, f_],      {}]      := With[{pair = NewDummy[]}, v[pair[[2]]] CD[pair[[1]], f]] /; vectorNameQ[v] && ZeroDegreeQ[f]
            f2cObject[LD[v_, expr_],   indexL_] := LD[v, FtoC[expr, indexL]] /; indexL =!= {}
            f2cObject[IP[v_, expr_],   indexL_] :=
                With[{pair = NewDummy[]},
                    With[{fIndexL = Prepend[indexL, pair[[1]]]},
                    	v[pair[[2]]] * (TindexSort @ AntisymmetrizeIndices[FtoC[expr, fIndexL], fIndexL])  (* NB: f2cObject but not "FtoC" *)
                    ]
                ]
            f2cObject[HodgeStar[expr_], indexL_] :=
                Module[{n = GetDimension[DefaultKind], p, dnL, upL, freeL},
                    If [!PositiveIntegerQ[n], Message[Msg::err, "Need to SetDimension[]","", "", ""]; Return[HodgeStar[expr]]];

                    p = DegreeForm[expr];
                    If [Length[indexL] =!= n - p, Message[Msg::err, "invalid number of indices", indexL, "for", HodgeStar[expr]]; Return[]];

                    If [p === 0,
                        dualStarFtoC[FtoC[expr, {}], indexL],
                    (* else *)
                        {dnL, upL} = Transpose @ Table[NewDummy[], p];
                        dualStarFtoC[FtoC[expr, dnL], Join[upL, indexL]]
                    ]
                ]
            f2cObject[CoXD[expr_],     indexL_] :=
                With[{pair = NewDummy[]},
                    -CD[pair[[2]], FtoC[expr, Prepend[indexL, pair[[1]]]]]
                ]
            f2cObject[expr_, _, _] := expr

(*****************************************************************************)
(*****************************************************************************)
(*****************************************************************************)

(*****************************************************************************)
(********************* CtoF by Gemini 3.1 (incomplete) ***********************)
(*****************************************************************************)

CtoF[expr_] := expr //. {
        (*=========================================================*)
        (* [우선순위 1순위] 3항 규칙: 가장 먼저 매칭되어야 함 *)
        (*=========================================================*)
        (* 규칙 1: 2-form XD (3항 대칭) *)
        c1_. * op1_[mu_?formIdxQ, A_[nu_?formIdxQ, rho_?formIdxQ, idxA___]]
        + c2_. * op2_[nu_?formIdxQ, A_[mu_?formIdxQ, rho_?formIdxQ, idxA___]]
        + c3_. * op3_[rho_?formIdxQ, A_[mu_?formIdxQ, nu_?formIdxQ, idxA___]] /; (c1 == -c2 == c3) && (op1 === op2 === op3) && (op1 === BD || op1 === CD)
            :> c1 * XD[A[idxA]],

        (* 규칙 2: 1-form과 2-form의 XP (3항 대칭) *)
        c1_. * A_[mu_?formIdxQ, idxA___] * B_[nu_?formIdxQ, rho_?formIdxQ, idxB___]
        + c2_. * A_[nu_?formIdxQ, idxA___] * B_[mu_?formIdxQ, rho_?formIdxQ, idxB___]
        + c3_. * A_[rho_?formIdxQ, idxA___] * B_[mu_?formIdxQ, nu_?formIdxQ, idxB___] /; (c1 == -c2 == c3)
            :> c1 * XP[A[idxA], B[idxB]],

        (*=========================================================*)
        (* [우선순위 2순위] 2항 규칙: 3항 매칭이 실패한 후 작동 *)
        (*=========================================================*)
        (* 규칙 3: 1-form 외미분 (2항 반대칭) *)
        c1_. * op1_[mu_?formIdxQ, A_[nu_?formIdxQ, idxA___]]
        + c2_. * op2_[nu_?formIdxQ, A_[mu_?formIdxQ, idxA___]] /; (c1 == -c2) && (op1 === op2) && (op1 === BD || op1 === CD)
            :> c1 * XD[A[idxA]],

        (* 규칙 4: 1-form 쐐기곱 (2항 반대칭) *)
        c1_. * A_[mu_?formIdxQ, idxA___]*B_[nu_?formIdxQ, idxB___]
        + c2_. * A_[nu_?formIdxQ, idxA___] * B_[mu_?formIdxQ, idxB___] /; (c1 == -c2)
            :> c1 * XP[A[idxA], B[idxB]]
    };

    formIdxQ[idx_] := KindIndexQ[DefaultKind][idx];

(*****************************************************************************)
(*****************************************************************************)
(*****************************************************************************)

(***** CoordRep *****)

CoordRep[form_, coSys_List] :=
    With[{p = DegreeForm[form], n = Length[coSys]},
        If [p == 0 || n == 0, form, coordRep[form, p, n, coSys]]
    ]

CoordRep[form_, n_:GetDimension[Latin]] :=
    With[{p = DegreeForm[form]},
        If [p == 0,
            form,
        (* else *)
            If [!PositiveIntegerQ[n],
                Message[Msg::err, "Dimension", n, "is required to be a positive integer!", ""];
                form,
            (* else *)
                coordRep[form, p, n]
            ]
        ]
    ]

    coordRep[form_, p_, n_, coSys_:{}] :=
        With[{pairL = Table[NewDummy[Latin], {p}]},
            If [!DiffFormQ[coordX],
                defineForm[coordX, 0, "a", {Latin}, {1}, PrintAs -> "x"]  (* Fdefine[coordX[ua], 0] *)
            ];

            If [coSys === {},
                clearComponents[coordX, 1, {n}, {1}],
            (* else *)
                tableToComponents[coordX, 1, {1}, coSys]  (* SetComponents[coordX[ua], coSys] *)
            ];

            With[{rc = (1/p!) FtoC[form, #[[1]]& /@ pairL] ( XP @@ (XD /@ coordX /@ (#[[2]]& /@ pairL)) )},
            	CollectForm @ TindexSort @ (SumDum[rc, {1, n}, Latin])
            ]
        ]

Unprotect[Off]  (* turn off a flag *)
Off[XDtoCDfrag] := (flagTable[XDtoCDfrag] = False;)
Protect[Off]

Unprotect[On]  (* turn on a flag *)
On[XDtoCDfrag] := (flagTable[XDtoCDfrag] = True;)
Protect[On]

(********************************************************************************)

initDiffForm[] := (
        (***** Flag Table *****)
        flagTable[XDtoCDfrag] = True;

        (***** Predefined Operators *****)
        reservedNameList = Union[reservedNameList, {IP, HodgeStar, CoXD}];
    )
initDiffForm[]

End[] (* End Private Context *)

EndPackage[]

(********************************************************************)
