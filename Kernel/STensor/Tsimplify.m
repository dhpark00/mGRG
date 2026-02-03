(********************************************************************)
(**************************** Tsimplify.m ***************************)
(********************************************************************)

(********************************************************************)
BeginPackage["mGRG`STensor`", {"mGRG`mPerm`"}]
(********************************************************************)

(***** debugging *****)
$dndn::usage = ""
$upup::usage = ""
$dnup::usage = ""
$updn::usage = ""

(********************************************************************)
Begin["`Private`"]
(********************************************************************)

(************************ DnUpPair/UpDnPair *************************)

(* pairs to dn-up/up-dn (Lower-Upper/Upper-Lower) if possible *)
SetAttributes[{DnUpPair, UpDnPair}, HoldAll]

DnUpPair[expr_Plus, args___]     := DnUpPair[#, args]& /@ expr
DnUpPair[expr_,     opts___Rule] := pairDrv[expr, DnUpPair, opts]
DnUpPair[___]                    := Message[DnUpPair::usage]

UpDnPair[expr_Plus, args___]     := UpDnPair[#, args]& /@ expr
UpDnPair[expr_,     opts___Rule] := pairDrv[expr, UpDnPair, opts]
UpDnPair[___]                    := Message[UpDnPair::usage]


    pairDrv[expr_, cmd_, opts___Rule] :=
        With[ {cOptL = FilterRules[{opts}, CovDs]},
            (* check covariant-derivative option *)
            If [cOptL =!= {} && !AllTrue[CovDs /. cOptL, IndexedOperatorQ],
                Message[Msg::err, "not defined operator(s)", CovDs /. cOptL, "", ""]; Return[expr]
            ];

            With[ {rcExpr = ExpandObject[expr, opts]},
                If [Head[rcExpr] === Plus,
                    cmd[rcExpr, opts],
                (* else *)
                    ForEachTerm[rcExpr, dnupTerm, FilterRules[{opts}, HeadQs], cOptL, If [cmd === DnUpPair, True, False]]
                ]
            ]
        ]

        dnupTerm[term_, hOptL_List, cOptL_List, bDnUp_] :=
            Module[{ordTerm, oTerm, oTermNew},
                {ordTerm, oTerm} = SplitTerm[term, hOptL];
                If [oTerm === 1, Return[term]];

                (* check indices: for markPairs *)
                If [DuplicatedIndicesQ[indicesOf[oTerm, {HeadQs -> {IndexedObjectQ}}], True], Return[ordTerm * ErrorT[oTerm]]];

                oTermNew = resetDummiesTerm[oTerm, {}, hOptL];  (* prepare for markPairs *)
                If [MemberQ[checkOperatorArg[#, True]& /@ toList[oTermNew], False], Return[ordTerm * ErrorT[oTerm]]];

                With[{markedTermL = markPairs[toList[oTermNew], hOptL, cOptL, False]},
                    If [markedTermL === toList[oTermNew], Return[term]];  (* No pairs found *)

                    (* count dn-up/up-dn pairs which will be up-dn/dn-up. *)
                    With[{cntMark = If [bDnUp, $upup, $dndn]},
                        (* 2026.01.24 현재 반대칭 메트릭은 사용하지 않으므로 metricSymmetry는 항상 +1 *)
                        With[{sign = Times @@ (If [MetricSpaceQ[#] && metricSymmetry[#] === -1,
                                                   (-1)^(Count[markedTermL /. {cntMark[_][#][a_] :> $forPairCNT[#][a]}, $forPairCNT[#][_], Infinity] / 2),
                                               (* else *)
                                                   1
                                               ]& /@ definedKindList)},  (* Calculate sign factor for anti-symmetric metrics *)

                            (* dn-up/up-dn with the multiplication mSym^nUpDn/mSym^nDnUp *)
                            ordTerm * sign * (Times @@ markedTermL /. { $dndn[_][_][idx_] :> If [bDnUp, idx,            FlipIndex[idx]], $dnup[_][_][idx_] :> idx,
                                                                        $upup[_][_][idx_] :> If [bDnUp, FlipIndex[idx], idx],            $updn[_][_][idx_] :> idx })
                        ]
                    ]
                ]
            ]

(* check the argument of operators. Used in markPairs.
   If called the markPairs with 'withCheck == False',
   it should be *explicitely* called this function before the calling the markPairs.
 *)
checkOperatorArg[(opName_?IndexedOperatorQ)[arg_, expr___], withMsg_:False] :=  (* See syntaxCheckObject *)
    Switch [getType[opName],
        CD,
            If [!checkOperatorArg[expr, withMsg], Return[False]];
            If [!ValidIndexQ[arg, KindOf[opName, arg], withMsg], Return[False]];
            If [!DnIndexQ[arg] && !MetricSpaceQ[IndexToKind @ arg],
                If [withMsg, Message[Msg::err, "The index of", opName, "is not down:", arg]];
                Return[False]
            ];
            If [DuplicatedIndicesQ[Join[{arg}, FindIndices[expr]], withMsg], Return[False]];
            True,
        LD,
            If [!checkOperatorArg[expr, withMsg], Return[False]];
            If [!vectorNameQ[arg],
                If [withMsg, Message[Msg::err, "non-vector:", arg, "", ""]];
                False,
            (* else *)
                True
            ],
        XD,
            If [!checkOperatorArg[arg, withMsg], False, True],
        XP,
            With[{rcExpr = checkOperatorArg /@ {arg, expr}},
                If [!FreeQ[rcExpr, ErrorT], Return[False]];
                If [DuplicatedIndicesQ[Flatten @ (FindIndices /@ {arg, expr}), True], Return[False]];
                True
            ]
    ]
checkOperatorArg[___] := True

(* mark pairs of a reset-dummied term according to moveQ and KindMatchQ:
      if  moveQ and (dn,up) --> $dndn[uniqSym][kind][idx]
      if  moveQ and (up,dn) --> $upup[uniqSym][kind][idx]
      if !moveQ and (dn,up) --> $dnup[uniqSym][kind][idx]
      if !moveQ and (up,dn) --> $updn[uniqSym][kind][idx]
 *)
markPairs[tTermL_List, hOptL_List, cOptL_List, withCheck_:True] := (
        (* It is DANGER if NOT checking by withCheck == False. *)
        If [withCheck, If [MemberQ[checkOperatorArg[#, True]& /@ tTermL, False], Return[tTermL]]];

        With[{pairL = TakePairs @ FindIndices[Times @@ tTermL, Sequence @@ hOptL]},  (* contracted pairs in the format {dn, up} in tTerm *)
            If [pairL === {}, Return[tTermL]];

            Module[{rcL = tTermL},
                Do [
                    With[{dnPos = First @ Position[tTermL, pairL[[i,1]]],
                          upPos = First @ Position[tTermL, pairL[[i,2]]],
                          uniqSym = Unique["m"],
                          kind = IndexToKind @ pairL[[i,1]]},
                        With[{ccOptL = {CovDs -> DeleteDuplicates @ Join[If [cOptL =!= {}, cOptL[[1,2]], {}],
                                                                         If [MetricSpaceQ[kind], getCovDs[GetMetric @ kind], {}]]}},

                            If [dnPos[[1]] === upPos[[1]],  (* BD[lp, BD[la, T[lb, up]] or T[lp, up] *)
                                If [MetricSpaceQ[kind] && moveQobject[tTermL[[dnPos[[1]]]], {dnPos, upPos}, ccOptL],
                                    If [OrderedQ[{dnPos, upPos}],  (* if dn-up pair *)
                                        rcL = rcL /. {pairL[[i,1]] -> $dndn[uniqSym][kind][pairL[[i,1]]], pairL[[i,2]] -> $dndn[uniqSym][kind][pairL[[i,2]]]},
                                    (* else *)
                                        rcL = rcL /. {pairL[[i,1]] -> $upup[uniqSym][kind][pairL[[i,1]]], pairL[[i,2]] -> $upup[uniqSym][kind][pairL[[i,2]]]}
                                    ],
                                (* else *)
                                    If [OrderedQ[{dnPos, upPos}],
                                        rcL = rcL /. {pairL[[i,1]] -> $dnup[uniqSym][kind][pairL[[i,1]]], pairL[[i,2]] -> $dnup[uniqSym][kind][pairL[[i,2]]]},
                                    (* else *)
                                        rcL = rcL /. {pairL[[i,1]] -> $updn[uniqSym][kind][pairL[[i,1]]], pairL[[i,2]] -> $updn[uniqSym][kind][pairL[[i,2]]]}
                                    ]
                                ],
                            (* else *)
                                If [MetricSpaceQ[kind] && moveQterm[tTermL[[ dnPos[[1]] ]], dnPos, ccOptL]  \
                                                       && moveQterm[tTermL[[ upPos[[1]] ]], upPos, ccOptL],
                                    If [dnPos[[1]] < upPos[[1]],  (* if dn-up pair *)
                                        rcL = rcL /. {pairL[[i,1]] -> $dndn[uniqSym][kind][pairL[[i,1]]], pairL[[i,2]] -> $dndn[uniqSym][kind][pairL[[i,2]]]},
                                    (* else *)
                                        rcL = rcL /. {pairL[[i,1]] -> $upup[uniqSym][kind][pairL[[i,1]]], pairL[[i,2]] -> $upup[uniqSym][kind][pairL[[i,2]]]}
                                    ],
                                (* else *)
                                    If [dnPos[[1]] < upPos[[1]],  (* if dn-up pair *)
                                        rcL = rcL /. {pairL[[i,1]] -> $dnup[uniqSym][kind][pairL[[i,1]]], pairL[[i,2]] -> $dnup[uniqSym][kind][pairL[[i,2]]]},
                                    (* else *)
                                        rcL = rcL /. {pairL[[i,1]] -> $updn[uniqSym][kind][pairL[[i,1]]], pairL[[i,2]] -> $updn[uniqSym][kind][pairL[[i,2]]]}
                                    ]
                                ]
                            ]
                        ]
                    ],
                    {i, Length[pairL]}
                ];
                rcL
            ]
        ]
    )

    (* for an object *)
    moveQobject[(      _?IndexedOperandQ)[___],     {_,        _},     _List]       := True (* T[up,lp] *)
    moveQobject[(opName_?IndexedOperatorQ)[args__], {dnPos_, upPos_},  ccOptL_List] :=      (* CD[up, T[lp,lb] *)
        With[{dnLevel0 = Length[dnPos], upLevel0 = Length[upPos]},
            If [dnLevel0 === Depth[opName[args]] === upLevel0, Return[True]];  (* CD[ua, T[lp, up] *)
            With[{dnLevel = If [dnLevel0 < upLevel0, upLevel0, dnLevel0],      (* swap *)
                  upLevel = If [dnLevel0 < upLevel0, dnLevel0, upLevel0]},

                (* Find the number of CovD from upLevel - 1 to dnLevel - 2. Are they all in covOpL? *)
                Length[ Position[opName[args], Alternatives @@ (CovDs /. ccOptL), {upLevel - 1, dnLevel - 2}] ] === (dnLevel - upLevel)
            ]
        ]
    moveQobject[___] := False

    (* for a product of objects *)
    moveQterm[(      _?IndexedOperandQ)[___],     _,    _List]       := True (* aT[lp,lb] * bT[up,lc] *)
    moveQterm[(opName_?IndexedOperatorQ)[args__], pos_, ccOptL_List] :=      (* CD[la, aT[lp,lc]] * bT[up,ud] *)
        With[{lev = Length[pos]},
            (* 2026.01.24 현재 TsimplifyPatternMatching 함수는 사용하지 않으므로 필요없는 코드 *)
            (* special treatment of BD index for dnupTermList in TsimplifyPatternMatching *)
            If [$BDSPECIALQ === True,
                With[{expr = Level[opName[args], {lev - 2}]},
                    If [Length[expr] === 1, If [Head[expr[[1]]] === BD, Return[False]],
                    (* else *)              If [Head[expr[[2]]] === BD, Return[False]]]
                ]
            ];

            If [lev === 2, Return[True]];

            (* Find the number of CovD from 1 to lev - 2. Are they all in covOpL? *)
            Length[ Position[opName[args], Alternatives @@ (CovDs /. ccOptL), {1, lev - 2}] ] === (lev - 2)
        ]
    moveQterm[___] := False

(*************************** TindexSort *****************************)
 
Options[TindexSort] = {Verbose -> False}
TindexSort[lst_List, opts___Rule] := TindexSort[#, opts]& /@ lst
TindexSort[expr_,    opts___Rule] :=
    With[{saveHoptL = Options[HeadQs]},
        Options[HeadQs] = {HeadQs  -> {ObjectQ}};  (* (A[-1,-1])^2 => 0 *)
        With[{rc = ForEachObject[expr, FilterRules[{opts}, HeadQs], indexSortObject]},
            Options[HeadQs] = saveHoptL;
            rc
        ]
    ]
TindexSort[expr_, ___] := expr
TindexSort[___]        := Message[TindexSort::usage]

    indexSortObject[obj_] := (
            If [checkOperatorArg[obj, True] === False, Return[ErrorT[obj]]];

            With[{signANDobjL = dnupTermList[{obj}, {}, False]},  (* oName[ua,...,la] -> {mSym^npairs, oName[la,...,ua]} *)
                With[{xSym = xSymmetryOf[xSort[First @ signANDobjL[[2]]]] /. {Tscalar -> Identity}},  (* NB: Tscalar removed *)
                    With[{indexL = #[[2]]& /@ xSym[[3]]},
                        If [vanishingObjectQ[xSym, xSym[[4]]] === True, Return[0]];

                        With[{minSymW = getMinSymW[xSym[[4]], indexL]},
                            signANDobjL[[1]] * minSymW[[2]] * (xSym[[2]] /. toSlotRules[0, Permute[indexL, minSymW[[1]]]])
                        ]
                    ]
                ]
            ]
        )

        getMinSymW[gs_, aIndexL_] :=
            With[{allSymL = MakePermGroup[gs]},
                If [allSymL === {}, Return[{Cycles[{{}}], 1}]];

                tmpF[symL_, iL_] := {Permute[aIndexL, symL[[1]]], iL[[1]]};
                With[{minPos = Sort[MapIndexed[tmpF, allSymL], IndexOrderedQ[#1[[1]], #2[[1]]]&] [[1,2]]},
                    {allSymL[[minPos, 1]], allSymL[[minPos,2]]}  (* {minSym, minW} *)
                ]
            ]

        vanishingObjectQ[xSym_, gs_] :=
            With[{indexL0 = #[[2]]& /@ xSym[[3]]},
                If [vanishingBDQ[flattenCDtype[xSym[[2]] /. xSym[[3]]], indexL0, gs] === True, Return[True]];

                With[{indexL = toDnIfPossible /@ indexL0},  (* to dn non-component indices: F_a^a or F_{11} -> 0 but F_1^1 \neq 0 *)
                    With[{len = Length[indexL],
                          pairL = Select[Split @ Sort @ indexL, (Length[#] >= 2)&]},  (* get paired or repeated indices *)
                        Catch[
                            Do [
                                With[{idx = pairL[[i,1]]},
                                    If [Head[idx] === List,
                                        (* paired indices: F[la,ua] or S[la,ua] *)
                                        With[{sym = {Cycles[{Flatten[Position[indexL, idx], 1]}], -idx[[1]]}},
                                            If [PermMemberQ[sym, len, gs], Throw[True]]
                                        ],
                                    (* else *)
                                        (* repeated indices: R[-1,-2,-2,-2] --> {2,3,4} *)
                                        With[{posL = Flatten[Position[indexL, idx], 1]},
                                            (* {Cycles[{{2,3}}], -1}, {Cycles[{{2,4}}], -1}, {Cycles[{{3,4}}], -1} *)
                                            With[{sym = {#, -1}& /@ (Cycles[{#}]& /@ Select[Flatten[Outer[List, posL, posL], 1], (#[[1]] < #[[2]])&])},
                                                If [Or @@ (PermMemberQ[#, len, gs]& /@ sym), Throw[True]]
                                            ]
                                        ]
                                    ]
                                ],
                                {i, Length[pairL]}
                            ];
                            False
                        ]
                    ]
                ]
            ]
        vanishingObjectQ[___] := False

            (* return {sym of metric, dn-index} if possible *)
            toDnIfPossible[idx_?TensorialIndexQ] :=
                With[ {kind = IndexToKind[idx]},
                    If [MetricSpaceQ[kind],  (* ToDn is possible *)
                        With[{mSym = metricSymmetry[kind]},
                            If [mSym =!= 0,      (* metric has a symmetry *)
                                If [DnIndexQ[idx],  Return[{mSym, idx}],
                                (* else *)          Return[{mSym, ToDnIndex[idx]}]]
                            ]
                        ]
                    ];
                    idx
                ]
            toDnIfPossible[idx_] := idx

        vanishingBDQ[{pre___, BD, a_, mid___, BD, b_, post___, tens_, {___, c_, ___, d_, ___}}, indexL_, gs_] := (
                If [CoordinateBasisQ[IndexToKind @ a] && DnIndexQ[a] && DnIndexQ[b] && (PairIndexQ[{a,c}, {b,d}] || PairIndexQ[{a,d}, {b,c}]),
                    Module[{cPos = Position[indexL, c], dPos = Position[indexL, d]},
                        If [PermMemberQ[{Cycles[{Flatten @ {cPos, dPos}}], -1}, Length @ indexL, gs], Return[True]]
                    ]
                ];
                False
            )

        (* CD[a, BD[b, T[indices]]] -> {{CD, a}, {BD, b}, T, {indices}} *)
        flattenCDtype[(oName_?IndexedOperandQ)[args___]]         := {oName, {args}}
        flattenCDtype[(opName_?IndexedOperatorQ)[arg_, expr___]] :=
            Switch [getType[opName],
                CD, Join[{opName, arg}, flattenCDtype[expr]],
                LD, flattenCDtype[expr],
                XD, flattenCDtype[arg],
                XP, {}
            ]
        flattenCDtype[___] := {}

(* cf: dnupTerm[term, hOptL, cOptL, bDnUp] *)
dnupTermList[termL_, cOptL_List, withCheck_, toPatternQ_:False] :=
    Block[{$BDSPECIALQ = True},
        With[{rcL = markPairs[termL, {}, cOptL, withCheck]},
            If [rcL === termL, Return[{1, termL}]];  (* errors or no pairs *)

            (* count up-dn pairs which will be dn-up. *)
            (* 2026.01.24 현재 반대칭 메트릭은 사용하지 않으므로 metricSymmetry는 항상 +1 *)
            With[{sign =
                    Times @@ (
                        If [MetricSpaceQ[#] && metricSymmetry[#] === -1,
                            (-1)^(Count[rcL /. {$upup[_][#][a_] :> $forPairCNT[#][a]}, $forPairCNT[#][_], Infinity] / 2),
                        (* else *)
                            1
                        ]& /@ definedKindList)},
                (* dn-up with the multiplication mSym^nUpDn, and clear markPairs symbols `$xxxx` *)
                If [toPatternQ === True,
                    {sign, rcL /.{$dndn[s_][_][_] :> Pattern[Evaluate[s], Blank[]],      $upup[s_][_][_] :> Pattern[Evaluate[s], Blank[]],
                                  $dnup[s_][_][_] :> Pattern[Evaluate[s], Blank[$dnup]], $updn[s_][_][_] :> Pattern[Evaluate[s], Blank[$updn]]}},
                (* else *)
                    {sign, rcL /. {$dndn[_][_][a_] :> a, $upup[_][_][a_] :> FlipIndex[a],
                                   $dnup[_][_][a_] :> a, $updn[_][_][a_] :> a}}
                ]
            ]
        ]
    ]

(********************** Simplification Rules ************************)

(* \pd_a g^{bc} -> -g^{bd} g^{ce} \pd_a g_{de} for a metric *)
BDinvgRule[]        := BDinvgRule[Metricg]
BDinvgRule[metric_] := {
        BD[a_, metric[b_, c_]] :>
            With[{kind = KindOf @ metric},
                With[{bDnUp = NewDummy[kind], cDnUp = NewDummy[kind]},
                    -metric[b, bDnUp[[2]]] * metric[c,cDnUp[[2]]] * BD[a, metric[bDnUp[[1]],cDnUp[[1]]]
                ]
            ]
        ] /; AllTrue[{b,c}, TensorialIndexQ] && AllTrue[{b,c}, UpIndexQ]
    } /; MetricQ[metric]

KdeltaSumRule[]      := KdeltaSumRule[DefaultKind]
KdeltaSumRule[kind_] := {  (* even for an antisymmetric metric *)
        Kdelta[a_, b_] :> GetDimension[kind] /; ValidIndexQ[a, kind] && PairIndexQ[a, b]
    }

EpsilonProductRule[]      := EpsilonProductRule[DefaultKind]
EpsilonProductRule[kind_] := {  (* NB: GetSig[kind] = (dim - signature)/2 is the number of minus *)
        GetEpsilon[kind][indices1__] GetEpsilon[kind][indices2__] :>
            (-1)^(GetSig[kind]) * Length[{indices1}]! * antisymmetrizeKdeltaProduce[{indices1}, {indices2}, kind]  \
            /; ValidIndicesQ[Join[{indices1}, {indices2}], kind] && Length[{indices1}] === Length[{indices2}]
    }

    antisymmetrizeKdeltaProduce[indexL1_, indexL2_, kind_] :=
        With[{saveKdeltaFlag = flagTable[KdeltaFlag], metric = GetMetric[kind]},
            flagTable[KdeltaFlag] = False;   (* Off absorbKdelta *)
            (* anti-symmetrize and then explicitly metric -> Kdelta when updn|dnup *)
            With[{rc = AntisymmetrizeIndices[Times @@ Thread[metric[indexL1, indexL2]], indexL1] /. (metric[a_,b_] /; !UpupDndnIndexQ[{a,b}]) :> Kdelta[a,b]},
                flagTable[KdeltaFlag] = saveKdeltaFlag;
                Absorb[rc, metric] /. KdeltaSumRule[]
            ]
        ]

(**************************** Tsimplify *****************************)

Options[Tsimplify] = {Verbose -> False}
Attributes[Tsimplify] = {Listable}
Tsimplify[expr_, opts___Rule] :=
    With[{cOptL = FilterRules[{opts}, CovDs]},
        (* check covariant-derivative option *)
        If [cOptL =!= {} && !AllTrue[CovDs /. cOptL, IndexedOperatorQ],
            Message[Msg::err, "not defined operator(s)", CovDs /. cOptL, "", ""]; Return[expr]
        ];

        With[{verb = Verbose /. {opts} /. Options[Tsimplify]},
            If [verb, Print["Tsimplify input: ", expr]];
            Block[{$AssumSymL = {}},
                tSimplifyAux[expr, FilterRules[{opts}, HeadQs], cOptL, verb]
            ]
        ]
    ]
Tsimplify[___] := Message[Tsimplify::usage]

    tSimplifyAux[expr_, hOptL_, cOptL_, verb_] :=
        With[{rcExpr = ForEachTerm[ExpandObject[expr], tReduceTerm, hOptL, cOptL, verb]},
            If [verb && expr =!= rcExpr, Print["After tReduceTerm: ", rcExpr]];
            rcExpr
        ]

tReduceTerm[aTerm_, hOptL_List, cOptL_List, verb_] :=
    With[{ordANDoTerm = SplitTerm[aTerm, hOptL]},
        If [ordANDoTerm[[2]] === 1, Return[ordANDoTerm[[1]]]];

        tReduceTermProcess[xSort[ordANDoTerm[[2]], Sequence @@ cOptL], ordANDoTerm[[1]], ordANDoTerm[[2]], cOptL, verb]
    ]

(* for products with scalars: *)
tReduceTermProcess[xTensorTimes[],                             ordTerm_, ___]     := ordTerm
tReduceTermProcess[xTensorTimes[pre___, s1_xNoIndex, post___], ordTerm_, opts___] := tReduceTermProcess[s1, 1, opts]  \
                                                                                     * tReduceTermProcess[xTensorTimes[pre, post], ordTerm, opts]

(* for scalars without indices *)
tReduceTermProcess[xNoIndex[$flattenOTHER[other_]],           ordTerm_, ___] := ordTerm * other
tReduceTermProcess[xNoIndex[xObject[obj_, _, {_, _, _, {}}]], ordTerm_, ___] := ordTerm * obj

tReduceTermProcess[flatTerm_, ordTerm_, oTerm_, cOptL_List, verb_] :=
    With[{xSym0 = xSymmetryOf[flatTerm, Sequence @@ cOptL]},  (* for sorting oTerm *)
        If [verb,
            Print["flatTerm: ", flatTerm];
            Print["xSym: ", xSym0]
        ];

        With[{oTermL = toList[xSym0[[2]] /. xSym0[[3]]]},
            If [!FreeQ[xSym0[[2]], _errObject], Return[ordTerm * Times @@ oTermL]];
            If [verb, Print["oTermL: ", oTermL]];

            With[{indexL0 = #[[2]]& /@ xSym0[[3]]},
                (* 2026.01.24 현재 반대칭 메트릭은 사용하지 않으므로 필요없는 코드 *)
                If [!AllTrue[Union[IndexToKind /@ ToDnIndex /@ (takePairs @ indexL0)], (MetricSpaceQ[#] && metricSymmetry[#] === 1)&],
                    Message[Msg::err, "Non-symmetric metric when contracting indices.", "", "", ""]; Return[ordTerm * oTerm]  (* only for symmetric metrics *)
                ];

                (* reduce symmetries due to $dnup/$updn indices *)
                With[{markedTermL = markPairs[oTermL, {}, cOptL, False]},
                    With[{xSym = ReplacePart[xSym0, 4 -> reduceSymByMark[xSym0[[4]], markedTermL, indexL0]]},
                        If [verb, Print["After reducing symmetries, xSym[[4]]: ", xSym[[4]]]];

Off[Symbol::symname];  (* Why NOT work in MMA 14.2? *)
                       (* in case flattenObject returns $flattenOTHER *)
                        With[{name = SymbolJoin[SymbolJoin[#[[2]]]& /@ ( (flattenObject[#, cOptL]& /@ oTermL)  \
                                                                         /. $flattenOTHER[obj_] :> {1, obj}
                                                                       )]},
On[Symbol::symname];
                            prepareSymbolicTensor[name, indexL0, xSym[[4]]];
                            If [verb,
                                Print["After preparing SymbolicTensors"];
                                Print["    Assumptions: ", TableForm @ $AssumSymL];
                                Print["    indices: ", indexL0]
                            ];

                            With[{resultReduce = doTensorReduce[name, xSym, indexL0, verb]}, (* resultReduce = {sign, result, sortedFreeL} *)
                                If [resultReduce[[2]] === 0,    Return[0]];
                                If [resultReduce[[3]] === Null, Return[ordTerm * oTerm]];  (* internal error *)

                                (* interpret TensorContract *)
                                With[{resultContract = postTensorContract[resultReduce[[2]], metricStatesOf[flatTerm], indexL0, resultReduce[[1]], verb]},

                                    (* interpret TensorTranspose *)
                                    Module[{indexL = resultContract[[1]],
                                            sortedFreeL = postTensorTranspose[resultContract[[2]], resultReduce[[3]], resultReduce[[1]], verb]},
                                        If [sortedFreeL =!= {},
                                            Do [
                                                If [indexL[[i]] === 0,
                                                    indexL[[i]] = sortedFreeL[[1]]; sortedFreeL = Drop[sortedFreeL, 1]
                                                ],
                                                {i, Length[indexL]}
                                            ]
                                        ];

                                        resultReduce[[1]] * ordTerm * Times @@ (toList[xSym[[2]]] /. toSlotRules[0, indexL])
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]

    (* If not $upup/$dndn, reduce permutation symmetries. E.g.
           A[la,lb] BD[lc,S[ua,ub]] === 0 because sym[A] = -{1,2} and sym[S] = +{1,2}
           A[la,ub] BD[lc,S[ua,lb]] =!= 0 because sym[A] =  {} and sym[S] = {}  <== $dnup, $updn and !upupdndn[{la,ub}] *)
    reduceSymByMark[gsArg_, markedTermL_, indexL_] :=
        Module[{gs = gsArg, j},
            With[{markedIndexL        = Join @@ (allIndicesObject     /@ markedTermL),
                  markedIndexLOperand = Join @@ (indicesOperandMarked /@ markedTermL)},
                With[{posL = Flatten @ (Position[markedIndexL, #]& /@ markedIndexLOperand)},
                    Do [
                        For [j = 1, j <= Length[gs], ++j,  (* (2025.10.29) Don't convert to Table form. *)
                            With[{cycL = gs[[j,1,1]]},
                                (* if a sym includes markedIdx, and the indices in the sym is not upupdndn, drop the sym in gs *)
                                If [AnyTrue[cycL, MemberQ[#, posL[[i]]]&] && !UpupDndnIndexQ[indexL[[ cycL[[ Position[cycL, posL[[i]]][[1,1]] ]] ]]],
                                    gs = Drop[gs, {j}]; j--
                                ]
                            ]
                        ],
                        {i, Length[posL]}
                    ]
                ]
            ];
            gs
        ]

        (* all indices of a 'xSorted' term *)
        allIndicesObject[(      _?IndexedOperandQ)[indices__]]      := {indices}
        allIndicesObject[(opName_?IndexedOperatorQ)[arg_, expr___]] :=
            Switch [getType[opName],
                CD, Join[{arg}, allIndicesObject[expr]],
                LD, allIndicesObject[expr],
                XD, allIndicesObject[arg],  (* expr === Null *)
                XP, Flatten @ Map[allIndicesObject&, {arg, expr}]
            ]
        allIndicesObject[_] := {}

        (* get $updn/$dnup indices in operands *)
        indicesOperandMarked[(      _?IndexedOperandQ)[indices__]]      := {indices}[[ Flatten[Position[{indices}, _$updn[_][_] | _$dnup[_][_]], 1] ]]
        indicesOperandMarked[(opName_?IndexedOperatorQ)[arg_, expr___]] :=
            Switch [getType[opName],
                CD, indicesOperandMarked[expr],
                LD, indicesOperandMarked[expr],
                XD, indicesOperandMarked[arg],  (* expr === Null *)
                XP, Flatten @ (indicesOperandMarked /@ {arg, expr})
            ]
        indicesOperandMarked[_] := {}

    prepareSymbolicTensor[name_, idxL_, gs_] :=  (* symmetries for TensorReduce *)
        If [!MemberQ[#[[1]]& /@ $AssumSymL, name],
            With[{kindL = IndexToKind /@ idxL},
                AppendTo[$AssumSymL, Element[name, Arrays[kindL, List @@ gs]]]
            ]
        ]

    doTensorReduce[name_, xSym_, idxL_, verb_] :=
        Module[{indexL = idxL, sortedIndexL},
            (* repeated component indices *)
            With[{repeatL = Select[Flatten /@ (Position[indexL, #]& /@ (Union @ Select[indexL, ComponentIndexQ])), (Length[#] =!= 1)&]},
                If [verb && repeatL =!= {}, Print["positions of repeated indices: ", repeatL]];

                (* If repeated anti-sym indices *)
                If [repeatedIndicesZeroQ[xSym[[4]], xSym[[1]], repeatL], Return[{1, 0, indexL}]];

                (* repeated indices -> temporary unique indices *)
                With[{uniqueL0 = (Unique["zz" <> ToString[#]]& /@ #)& /@ repeatL},
                    Do [
                        Do [
                            indexL = ReplacePart[indexL, repeatL[[i,j]] -> $UNIQUE[ uniqueL0[[i,j]][indexL[[ repeatL[[i,j]] ]]] ]],
                            {j, Length[repeatL[[i]]]}
                        ],
                        {i, Length[repeatL]}
                    ];

                    With[{uniqueL = Cases[indexL, $UNIQUE[a_] :> a], pairL = TakePairs[indexL]},
                        indexL = indexL /. $UNIQUE -> Identity;
                        If [verb && uniqueL =!= {}, Print["unique repeated indices: ", uniqueL]];

                        If [verb, Print["In doTensorReduce, contracted pairs: ", pairL]];
                        With[{sortedIndexL0 = sortIndicesProper[indexL, Flatten @ pairL]},  (* sorted free-indices *)
                            If [verb,
                                Print["In doTensorReduce, after sortIndicesProper"];
                                Print["    original indices: ", indexL];
                                Print["    sorted indices: ", sortedIndexL0]
                            ];

                            (* TensorTranspose *)
                            With[{resultTranspose = TensorTranspose[name, indexL /. MapIndexed[Rule[#1, First @ #2]&, sortedIndexL0]]},
                                If [verb, Print["After TensorTranspose: ", resultTranspose]];

                                (* TensorContract *)
                                With[{contL = (Flatten @ {Position[indexL, #[[1]]], Position[indexL, #[[2]]]})& /@ pairL},
                                    With[{resultContract = TensorContract[resultTranspose, contL]},
                                        If [verb, Print["After TensorContract: ", resultContract]];

                                        (* perform TensorReduce *)
                                        If [verb, Print["Calling TensorReduce..."]];
                                        With[{resultReduce = TensorReduce[resultContract, Assumptions -> $AssumSymL]},
                                            If [verb, Print["In doTensorReduce, after TensorReduce: ", resultReduce]];
                                            If [resultReduce === 0 || MatchQ[resultReduce, _SymbolicZerosArray], Return[{1, 0, Null}]];  (* after ver 14.1 *)

                                            (* pick up a sign *)
                                            With[{sign = SignOfTerm[resultReduce]},
                                                With[{result = sign * resultReduce},
                                                    (* restore the repeated indices from the uniqueL *)
                                                    sortedIndexL = dropPairs @ sortedIndexL0;
                                                    If [uniqueL =!= {},
                                                        (sortedIndexL = sortedIndexL /. # -> #[[1]])& /@ uniqueL;
                                                        If [verb, Print["After restoring the repeated indices, the sorted free-indices: ", sortedIndexL]]
                                                    ];

                                                    {sign, result, sortedIndexL}
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]

        repeatedIndicesZeroQ[gs_GenSet, len_Integer, repeatL_] :=
            With[{sym = {Cycles[{#}], -1}& /@ Flatten[Partition[Sort @ #, 2, 1]& /@ repeatL, 1]},
                Or @@ (PermMemberQ[#, len, gs]& /@ sym)
            ]

    postTensorContract[result_, mStateL_, indexL_, sign_, verb_] :=
        Module[{idxL = ConstantArray[0, Length[indexL]]},
            With[{pairL = takePairsProper[indexL]},  (* NOT TakePairs *)
                If [verb, Print["metric states: ", mStateL]];

                With[{contL = Cases[{result}, TensorContract[_, cts_]:> cts, Infinity]},
                    If [contL =!= {},
                        Do [
                            (* dummy pair for the kind of the contracted index *)
                            With[{dumpairL = NewDummy @ IndexToKind @ indexL[[ contL[[1,i,1]] ]],
                                  moveQ = AllTrue[(#[[3]]& /@ mStateL)[[ contL[[1,i]] ]], (# === 1)&]},
                                (* If moveQ, {dn, up}        : A[la,ub] CD[lc, S[ua,lb]] => A[lp,lq] CD[lc, S[up,uq]].
                                   Otherwise, original dn/up : A[la,ub] BD[lc, S[ua,lb]] => A[lp,uq] BD[lc, S[up,lq]] *)
                                idxL[[ contL[[1,i]] ]] = If [moveQ || DnIndexQ[pairL[[i,1]]], dumpairL, dumpairL[[{2,1}]]]
                            ],
                            {i, Length[contL[[1]]]}
                        ]
                    ];
                    If [verb,
                        Print["In postTensorContract, idxL: ", idxL];
                        If [contL =!= {}, Print["After postTensorContract: ", sign * result /. TensorContract[arg_, _] :> arg]]
                    ];

                    {idxL, result /. TensorContract[arg_, _] :> arg}
                ]
            ]
        ]

    postTensorTranspose[result_, sortedIndexL_, sign_, verb_] :=
        With[{transL = Cases[{result}, TensorTranspose[_, imag_]:> imag, Infinity]},
            With[{sortedL = If [transL =!= {}, PermuteList[sortedIndexL, InversePerm @ (Imag @@ transL[[1]])], sortedIndexL]},
                If [verb,
                    Print["In postTensorTranspose, free-indices: ", sortedL];
                    If [transL =!= {}, Print["After postTensorTranspose: ", sign * result /. TensorTranspose[arg_, _]:> arg]];
                ];

                sortedL
            ]
        ]

(* sort indices with ignoring non-moveQ contracted indices *)
sortIndicesProper[indexL_, contL_] :=
    With[{sortedL = IndexSort @ Select[indexL, !MemberQ[contL, #]&],
          posL = Flatten @ Position[If [MemberQ[contL, #], #, $FREE[#]]& /@ indexL, _$FREE]},  (* positions of free (or moveQ-contracted) indices *)
        ReplacePart[indexL, Thread @ Rule[posL, sortedL]]
    ]

toList[term_xTTimes] := List @@ term
toList[term_Times]   := List @@ term
toList[other_]       := {other}

(********************************************************************)

End[] (* End Private Context *)

EndPackage[]
