(********************************************************************)
(************************ TensorComponents.m ************************)
(********************************************************************)

(********************************************************************)
BeginPackage["mGRG`STensor`", {"mGRG`mPerm`"}]
(********************************************************************)

(********************************************************************)
Begin["`Private`"]

(********************** Component Operations ************************)

(***** CDtoBD *****)
CDtoBD[expr_]                            := CDtoBD[expr, CD]
CDtoBD[expr_, covD_?DerivativeOperatorQ] := ForEachObject[ExpandObject[expr], {}, cdToBDTensor, covD, KindOf[covD]]
CDtoBD[___] := Message[CDtoBD::usage]

    cdToBDTensor[covD_[a_, expr_], covD_, kind_] :=
        With[{indexL = dropPairs @ Select[FindIndices @ expr, KindIndexQ[kind]],  (* remove contracted indices *)
              gamSymb = getDerOp[Gamma][covD],
              dummy = NewDummy[kind]},
            If [indexL =!= {},
                With[{doF = If [DnIndexQ[indexL[[#2]]], #1 - gamSymb[a, indexL[[#2]], dummy[[2]]]  * (expr /. indexL[[#2]] -> dummy[[1]]),
                               (* else *)               #1 + gamSymb[a, dummy[[1]],  indexL[[#2]]] * (expr /. indexL[[#2]] -> dummy[[2]])]&},

                    Fold[doF, BD[a, expr], Range[Length @ indexL]]
                ],
            (* else *)
                BD[a, expr]
            ]
        ] /; !FreeObjectQ[expr] && FreeQ[expr, BD | Alternatives @@ nonTensorList]
    cdToBDTensor[covD_[a_, expr_], covD_, kind_] := BD[a, cdToBDTensor[expr, covD, kind]] /; FreeObjectQ[expr]
    cdToBDTensor[BD[a_, expr_],    covD_, kind_] := BD[a, cdToBDTensor[expr, covD, kind]]
    cdToBDTensor[expr_,              ___]        := expr

(***** CommuteCD *****)
CommuteCD[idxL_List, expr_]                            := CommuteCD[idxL, expr, CD]
CommuteCD[idxL_List, expr_, covD_?DerivativeOperatorQ] :=
    With[ {kind = KindOf[covD]},
        If [!ValidIndicesQ[idxL, kind], Return[expr]];

        ForEachObject[ExpandObject[expr], {}, commuteCDTensor, idxL, covD, kind]
    ] /; Length[idxL] === 2 && AllTrue[idxL, RegularIndexQ]
CommuteCD[___] := Message[CommuteCD::usage]

    commuteCDTensor[opName_[a_, expr_],          {_, _},   covD_, _]     := opName[a, expr]  (* do nothing *)                                                      \
                                                                            /; !FreeQ[expr, BD | Alternatives @@ nonTensorList]  (* for BD or improper tensors *)  \
                                                                               || (opName === covD && FreeQ[expr, covD])         (* for one CovD *)                \
                                                                               || FreeObjectQ[expr]
    commuteCDTensor[covD_[c_, expr_],            {a_, b_}, covD_, kind_] := covD[c, commuteCDTensor[expr, {a, b}, covD, kind]] /; a =!= c && b =!= c
    commuteCDTensor[covD_[a_, covD_[b_, expr_]], {a_, b_}, covD_, kind_] := commuteCDTensorAux[a, b, expr, covD, kind] /; ObjectQ[Head[expr]]
    commuteCDTensor[covD_[b_, covD_[a_, expr_]], {a_, b_}, covD_, kind_] := commuteCDTensorAux[b, a, expr, covD, kind] /; ObjectQ[Head[expr]]
    commuteCDTensor[LD[aV_, expr_],              {a_, b_}, CD,    kind_] := LD[aV, commuteCDTensor[{a, b}, expr, CD, kind]]
    commuteCDTensor[expr_,                       ___]                    := expr

        commuteCDTensorAux[a_, b_, expr_, covD_, kind_] :=
            Module[{rc = covD[b, covD[a, expr]]},  (* CovD[a,b, T]] = CovD[b,a, T]] + ... *)
                (* get indices and then remove contracted indices *)
                With[{indexL = dropPairs @ Select[FindIndices @ expr, KindIndexQ[kind]]},
                    If [indexL =!= {},
                        With[{dummy = NewDummy[kind], rSymb = getDerOp[Riemann][covD]},
                            Do [
                                With[{aIndex = indexL[[i]]},
                                    If [DnIndexQ[aIndex], rc = rc - (riemannSign) * rSymb[a, b, aIndex, dummy[[2]]] * (expr /. aIndex -> dummy[[1]]),
                                    (* else *)            rc = rc + (riemannSign) * rSymb[a, b, dummy[[1]], aIndex] * (expr /. aIndex -> dummy[[2]])]
                                ],
                                {i, Length[indexL]}
                            ]
                        ]
                    ]
                ];

                If [!TorsionFreeQ[covD],
                    With[{dummy = NewDummy[kind]},
                        rc -= GetTorsion[kind][a, b, dummy[[2]]] covD[dummy[[1]], expr]
                    ]
                ];
                rc
            ]

(***** GammaToMetric *****)
GammaToMetric[expr_]                            := GammaToMetric[expr, CD]
GammaToMetric[expr_, covD_?DerivativeOperatorQ] :=
    With[{kind = KindOf[covD]},
        If [!MetricSpaceQ[kind], Message[Msg::err, kind, "is not a metric space", "", ""]; Return[expr]];
        With[{metric = GetMetric[kind]},
            If [!MetricCompatibleQ[covD, metric],  (* TODO: Q_{abc} === \cd_a g_{bc} =!= 0일 때 Q_{abc}를 이용해서 수정 *)
                Message[Msg::err, covD, "is not metric-compatible with", metric, ""]; Return[expr],
            (* else *)
                ForEachObject[ExpandObject[expr], {}, gammaToMetricTensor, covD, metric, kind]
            ]
        ]
    ]
GammaToMetric[___] := Message[GammaToMetric::usage]

    gammaToMetricTensor[tName_[a_, b_, c_], covD_, metric_, kind_] :=
        Module[{rc},
            Switch [DnIndexQ /@ {a, b, c},
                {True,  True,  True},
                    rc = dndndnGamma[a, b, c, metric],
                {True,  True,  False},
                    With[{p = NewDummy[kind]},
                        rc = metric[c, p[[2]]] * dndndnGamma[a, b, p[[1]], metric]],
                {True,  False, True},
                    With[{p = NewDummy[kind]},
                        rc = metric[b, p[[2]]] * dndndnGamma[a, p[[1]], c, metric]],
                {True,  False, False},
                    With[{p = NewDummy[kind], q = NewDummy[kind]},
                        rc = metric[b, p[[2]]] * metric[c, q[[2]]] * dndndnGamma[a, p[[1]], q[[1]], metric]],
                {False, True,  True},
                    With[{p = NewDummy[kind]},
                        rc = metric[a, p[[2]]] * dndndnGamma[p[[1]], b, c, metric]],
                {False, True,  False},
                    With[{p = NewDummy[kind], q = NewDummy[kind]},
                        rc = metric[a, p[[2]]] * metric[c, q[[2]]] * dndndnGamma[p[[1]], b, q[[1]], metric]],
                {False, False, True},
                    With[{p = NewDummy[kind], q = NewDummy[kind]},
                        rc = metric[a, p[[2]]] * metric[b, q[[2]]] * dndndnGamma[p[[1]], q[[1]], c, metric]],
                {False, False, False},
                    With[{p = NewDummy[kind], q = NewDummy[kind], r = NewDummy[kind]},
                        rc = metric[a, p[[2]]]*metric[b, q[[2]]]*metric[c, r[[2]]] * dndndnGamma[p[[1]], q[[1]], r[[1]], metric]]
            ];

            If [!CoordinateBasisQ[kind],
                With[{fSymb = GetStructuref[kind]},
                    rc += ( fSymb[a, b, c] + fSymb[c, a, b] + fSymb[c, b, a] ) / 2]
            ];
            If [!TorsionFreeQ[covD],
                With[{tSymb = GetTorsion[kind]},
                    rc += ( tSymb[a, b, c] + tSymb[c, a, b] + tSymb[c, b, a] ) / 2]
            ];
            rc
        ] /; tName === getDerOp[Gamma][covD]
    gammaToMetricTensor[BD[a_, expr_], covD_, metric_, kind_] := BD[a, gammaToMetricTensor[expr, covD, metric, kind]]
    gammaToMetricTensor[expr_, ___]                           := expr

        dndndnGamma[a_, b_, c_, metric_] := ( BD[a, metric[b, c]] + BD[b, metric[a, c]] - BD[c, metric[a, b]] ) / 2

(***** LDtoCD: LD to torsion-free CD *****)
LDtoCD[expr_]                            := LDtoCD[expr, CD]
LDtoCD[expr_, BD]                        := ForEachObject[ExpandObject[expr], {}, ldToCDTensor, BD]
LDtoCD[expr_, covD_?DerivativeOperatorQ] := If [TorsionFreeQ[covD], ForEachObject[ExpandObject[expr], {}, ldToCDTensor, covD],
                                            (* else *)              Message[Msg::warn, covD, "is not torsion-free", "", ""]; expr]
LDtoCD[___]                              := Message[LDtoCD::usage]

    ldToCDTensor[LD[aV_, expr_],    _]     := LD[aV, expr] /; !FreeQ[expr, BD | Alternatives @@ nonTensorList] || FreeObjectQ[expr]  (* for BD or improper tensors *)
    ldToCDTensor[BD[a_,  expr_],    covD_] := BD[a, expr]  /; covD =!= BD  (* improper tensor *)
    ldToCDTensor[covD_[a_,  expr_], covD_] := covD[a, ldToCDTensor[expr, covD]] /; covD === BD || FreeQ[expr, BD | Alternatives @@ nonTensorList] || FreeObjectQ[expr]
    ldToCDTensor[LD[aV_, expr_],    covD_] :=
        With[{kind = KindOf[aV]},
             If [!KindMatchQ[kind, KindOf @ aV],
                 LD[aV, expr],  (* do nothing *)
             (* else *)
                With[{dummy = NewDummy[kind]},
                    (* get indices and then remove contracted indices *)
                    With[{indexL = Select[dropPairs @ Select[FindIndices @ expr, KindIndexQ[kind]], ValidIndexQ[#, kind]&],
                          rc = aV[dummy[[2]]] * covD[dummy[[1]], expr]},  (* LD_V T = V^p \del_p T + ... *)
                        If [indexL =!= {},
                            With[{doF = With[{aIndex = indexL[[#2]]},
                                            If [DnIndexQ[aIndex], #1 + covD[aIndex, aV[dummy[[2]]]] * (expr /. aIndex -> dummy[[1]]),
                                            (* else *)            #1 - covD[dummy[[1]], aV[aIndex]] * (expr /. aIndex -> dummy[[2]])]
                                        ]&},

                                Fold[doF, rc, Range[Length @ indexL]]
                            ],
                        (* else *)
                            rc
                        ]
                    ]
                ]
             ]
        ] /; vectorNameQ[aV]
    ldToCDTensor[expr_, ___] := expr

(***** RiemannToGamma *****)
(* If curvRL === {}, convert all. But, if curvRL =!= {}, convert only those contained in curvRL. *)
RiemannToGamma[expr_]                                         := RiemannToGamma[expr, {}]
RiemannToGamma[expr_,              covD_Symbol]               := RiemannToGamma[expr, {},     covD]
RiemannToGamma[expr_, curvRL_List]                            := RiemannToGamma[expr, curvRL, CD]
RiemannToGamma[expr_, curvRL_List, covD_?DerivativeOperatorQ] :=
    ForEachObject[ExpandObject[expr], {}, riemannToGammaTensor, curvRL, covD, KindOf[covD]]  \
    /; And @@ (MemberQ[{getDerOp[Riemann][covD], getDerOp[Ricci][covD], getDerOp[Scalar][covD]}, #]& /@ curvRL)
RiemannToGamma[___] := Message[RiemannToGamma::usage]

    riemannToGammaTensor[opName_[a_,  expr_],    _,       _,     _]     := opName[a,  expr] /; DerivativeOperatorQ[opName]  (* do nothing *)
    riemannToGammaTensor[LD[aV_, expr_],         _,       _,     _]     := LD[aV, expr]                                     (* do nothing *)
    riemannToGammaTensor[BD[a_,  expr_],         curvRL_, covD_, kind_] := BD[a, riemannToGammaTensor[expr, curvRL, covD, kind]]
    riemannToGammaTensor[tName_[a_, b_, c_, d_], curvRL_, covD_, kind_] :=
        riemannToGammaAux[a, b, c, d, covD, kind] /; tName === getDerOp[Riemann][covD] && (curvRL === {} || MemberQ[curvRL, tName])
    riemannToGammaTensor[tName_[a_, b_],         curvRL_, covD_, kind_] :=
        With[{dummy = NewDummy[kind]},
            riemannToGammaAux[a, dummy[[1]], b, dummy[[2]], covD, kind]
        ] /; tName === getDerOp[Ricci][covD] && (curvRL === {} || MemberQ[curvRL, tName])
    riemannToGammaTensor[tName_[],               curvRL_, covD_, kind_] :=
        With[{dummy1 = NewDummy[kind], dummy2 = NewDummy[kind]},
            riemannToGammaAux[dummy1[[1]], dummy2[[1]], dummy1[[2]], dummy2[[2]], covD, kind]
        ] /; tName === getDerOp[Scalar][covD] && (curvRL === {} || MemberQ[curvRL, tName])
    riemannToGammaTensor[expr_, ___] := expr

        riemannToGammaAux[a_, b_, c_, d_, covD_, kind_] := -riemannToGammaAux[b, a, c, d, covD, kind] /; UpIndexQ[a] && DnIndexQ[b]  (* ordering to {dn, up, _, _} *)
        riemannToGammaAux[a_, b_, c_, d_, covD_, kind_] := -riemannToGammaAux[a, b, d, c, covD, kind] /; UpIndexQ[c] && DnIndexQ[d]  (* ordering to {_, _, dn, up} *)
        riemannToGammaAux[a_, b_, c_, d_, covD_, kind_] :=
            Module[{rc},
                With[{gamSymb = getDerOp[Gamma][covD]},
                    If [AllTrue[{a, b, c}, DnIndexQ] && UpIndexQ[d],  (* if not need the metric *)
                        rc = dndndnupDerGamma[a, b, c, d, gamSymb],
                    (* else *)
                        If [!MetricSpaceQ[kind], Return[ getDerOp[Riemann][covD][a, b, c, d] ]];  (* do nothing *)

                        With[{metric = GetMetric[kind]},
                            Switch [Map[DnIndexQ, {a, b, c, d}],
                                {True,  True,  True,  True},
                                    With[{p = NewDummy[kind]},
                                        rc = metric[d, p[[1]]] * dndndnupDerGamma[a, b, c, p[[2]], gamSymb]],
                                {True,  True,  False, False},
                                    With[{p = NewDummy[kind]},
                                        rc = metric[c, p[[2]]] * dndndnupDerGamma[a, b, p[[1]], d, gamSymb]],
                                {True,  False, True,  False},
                                    With[{p = NewDummy[kind]},
                                        rc = metric[b, p[[2]]] * dndndnupDerGamma[a, p[[1]], c, d, gamSymb]],
                                {True,  False, True,  True},
                                    With[{p = NewDummy[kind], q = NewDummy[kind]},
                                        rc = metric[b, p[[2]]] * metric[d, q[[1]]] * dndndnupDerGamma[a, p[[1]], c, q[[2]], gamSymb]],
                                {True,  False, False, False},
                                    With[{p = NewDummy[kind], q = NewDummy[kind]},
                                        rc = metric[b, p[[2]]] * metric[c, q[[2]]] * dndndnupDerGamma[a, p[[1]], q[[1]], d, gamSymb]],
                                {False, False, True,  False},
                                    With[{p = NewDummy[kind], q = NewDummy[kind]},
                                        rc = metric[a, p[[2]]] * metric[b, q[[2]]] * dndndnupDerGamma[p[[1]], q[[1]], c, d, gamSymb]],
                                {False, False, True,  True},
                                    With[{p = NewDummy[kind], q = NewDummy[kind], r = NewDummy[kind]},
                                        rc = metric[a,p[[2]]]*metric[b,q[[2]]]*metric[d,r[[1]]]*dndndnupDerGamma[p[[1]], q[[1]], c, r[[2]], gamSymb]],
                                {False, False, False, False},
                                    With[{p = NewDummy[kind], q = NewDummy[kind], r = NewDummy[kind]},
                                        rc = metric[a,p[[2]]]*metric[b,q[[2]]]*metric[c,r[[2]]]*dndndnupDerGamma[p[[1]], q[[1]], r[[1]], d, gamSymb]]
                            ]
                        ]
                    ];

                    With[{p = NewDummy[kind]},
                        rc += gamSymb[a, p[[1]], d] * gamSymb[b, c, p[[2]]] - gamSymb[b, p[[1]], d] * gamSymb[a, c, p[[2]]]
                    ];

                    If [!CoordinateBasisQ[kind],
                        With[{p = NewDummy[kind]},
                            rc -= GetStructuref[kind][a, b, p[[2]]] * gamSymb[p[[1]], c, d]
                        ]
                    ];
                    (riemannSign) * rc
                ]
            ]

            dndndnupDerGamma[a_, b_, c_, d_, gam_] := BD[a, gam[b, c, d]] - BD[b, gam[a, c, d]]

(****************** Set/Clear Tensor Components *********************)

SetAttributes[SetComponents, HoldFirst]
SetComponents[(tName_?IndexedOperandQ)[indices___], expr_] :=  (* set one component *)
    With[{indexL = {indices}},
        If [indexL === {}, tName[] = expr; Return[]];

        If [!checkComponentIndices[tName, indexL], Return[]];

        (* generates all symmetries of tName and then convert to Imag notation *)
        With[{len = Length[indexL]},
            With[{tSymL0 = MakePermGroup[getGenSetOf[tName[indices]], len]},
                If [tSymL0 === {},
                    tName[indices] = expr,
                (* else *)
                    With[{tSymL = ToImag[#, len]& /@ tSymL0},
                        (tName[ Sequence @@ indexL[[ List @@ (SignOfTerm[#] * #) ]] ] = SignOfTerm[#] * expr)& /@ tSymL
                    ]
                ]
            ]
        ];
    ] /; AllTrue[{indices}, ComponentIndexQ]
SetComponents[(tName_?IndexedOperandQ)[indices___], cTable_List] :=  (* set all components *)
    With[{nRank = GetRank[tName], len = Length[{indices}]},
        If [nRank =!= -1 && len =!= nRank, Message[Msg::err, "invalid number of indices", {indices}, "with rank", nRank]; Return[]];
        If [len =!= ArrayDepth[cTable], Message[Msg::err, "incompatible components", "for a rank", len, ""]; Return[]];

        tableToComponents[tName, len, dnupListFrom[indices], cTable];
    ] /; AllTrue[{indices}, TensorialIndexQ]
SetComponents[___] := Message[SetComponents::usage]

SetAttributes[ClearComponents, HoldAll]
ClearComponents[(tName_?IndexedOperandQ)[indices___]] :=  (* clear one component *)
    With[{indexL = {indices}},
        If [indexL === {} && ValueQ[tName[]], tName[] =.; Return[]];
        If [!checkComponentIndices[tName, indexL], Return[]];

        (* generates all symmetries of tName with ignoring the sign and then convert to Imag notation *)
        With[{len = Length[indexL]},
            With[{tSymL0 = {#[[1]], 1}& /@ MakePermGroup[getGenSetOf[tName, len]]},
Off[Unset::norep];
                If [tSymL0 === {},
                    tName[indices] =.,
                (* else *)
                    With[{tSymL = ToImag[#, len]& /@ tSymL0},
                        (* drop duplicate indices of tName: {1,1}[[1,2]] == {1,1}[[2,1]] *)
                        (tName[ Sequence @@ # ] =.)& /@ DeleteDuplicates[ indexL[[List @@ #]]& /@ tSymL ]
                    ]
                ]
            ]
        ];
On[Unset::norep];
    ] /; AllTrue[{indices}, ComponentIndexQ]
ClearComponents[(tName_?IndexedOperandQ)[indices___]] :=  (* clear all components *)
    Module[{dims = {}},
        With[{len = Length[{indices}]},
            Catch[
                Do [
                    With[{n = GetDimension[KindOf[tName, i]]},
                        If [!PositiveIntegerQ[n],
                            Message[Msg::err, "need to set dimension for the index", {indices}[[i]], "", ""]; Throw[Null]
                        ];
                        AppendTo[dims, n]
                    ],
                    {i, len}
                ];

                clearComponents[tName, len, dims, dnupListFrom[indices]]
            ]
        ]
    ] /; AllTrue[{indices}, TensorialIndexQ]
ClearComponents[(tName_?IndexedOperandQ)[indices___], dims_?VectorQ] :=  (* clear all components *)
    With[{len = Length[{indices}]},
        Catch[
            If [len =!= Length[dims], Message[Msg::err, "invalid format for the dimensions", dims, "", ""]; Throw[Null]];
            Do [
                With[{n = GetDimension[KindOf[tName, i]]},
                    If [PositiveIntegerQ[n] && dims[[i]] > n,
                        Message[Msg::err, "invalid input", dims[[i]], "for the dimension", n]; Throw[Null]
                    ]
                ],
                {i, len}
            ];

            clearComponents[tName, len, dims, dnupListFrom[indices]];
        ]
    ] /; AllTrue[{indices}, TensorialIndexQ]
ClearComponents[___] := Message[ClearComponents::usage]

checkComponentIndices[tName_, indexL_List] :=
    With[{nRank = GetRank[tName], len = Length[indexL]},
        Catch [
            If [nRank =!= -1 && len =!= nRank,
                Message[Msg::err, "incompatible number of indices", indexL, "with rank", nRank]; Throw[False]
            ];

            Do [
                If [!ValidIndexQ[indexL[[i]], KindOf[tName, i], True],  Throw[False]],
                {i, Length[indexL]}
            ];

            True
        ]
    ]

clearComponents[tName_, len_, dims_, dnupL_] :=
    With[{tIndexL = Table[Unique["m"], {i, len}]},  (* dummy indices for Table *)
        With[{expr1 = Inner[List, tIndexL, dims, Sequence]},
Off[Unset::norep];
            Table[ tName[Sequence @@ (dnupL * tIndexL)] =., Evaluate[expr1] ];  (* clear all components *)
On[Unset::norep];
        ]
    ]

dnupListFrom[args___] := dnupState /@ {args}

(* set components in Table-format *)
tableToComponents[tName_, 0,    {},     value_]  := (tName[] = value;)
tableToComponents[tName_, len_, dnupL_, cTable_] :=
    With[{dims = Dimensions[cTable]},
        Catch [
            Do [
                With[{n = GetDimension[KindOf[tName, i]]},
                    If [PositiveIntegerQ[n] && dims[[i]] > n,
                        Message[Msg::err, "invalid input for a ", i, "th dimension", n]; Throw[Null]
                    ]
                ],
                {i, len}
            ];

            With[{tIndexL = Table[Unique["m"], {i, len}]},  (* dummy indices for Table *)
                With[{expr1 = Hold[cTable[[ Sequence @@ tIndexL ]]],
                      expr2 = Inner[List, tIndexL, dims, Sequence]},
                    (* set values to the corresponding tensor components *)
                    Table[ tName[Sequence @@ (dnupL * tIndexL)] = ReleaseHold[expr1], Evaluate[expr2] ];
                ]
            ]
        ]
    ]

(******************** Coordinate Transformation ********************)

(*
  {x} -> {y}
    trM = (\pd y / \pd x) /. (rightRule or forM)
  {x} <- {y}
    trN = (\pd x / \pd y) /. (leftRule  or forN)


  \xi'^a = trM_i^{\ a} \xi^i                      <== Pushforward
  \o_i   = trM_i^{\ a} \o'_a                      <== PullBack
  \o'_a  = trN_a^{\ i} \o_i                       <== PushTensor
  T'^a_{\ b} = trM_i^{\ a} trN_b^{\ j} T^i_{\ j}  <== PushTensor

  Notation: trM_i^{\ a} \equiv [Jacobian Matrix]^a_{\ i}, i.e. Jacobian Matrix = trM^T
 *)

Pushforward[fromV_?VectorQ, coSys_?VectorQ, newCoSys_?VectorQ, simpCmd_:Simplify] :=
    With[{trM = Table[D[newCoSys, coSys[[i]]], {i, Length[coSys]}] // simpCmd},
        Transpose[trM] . fromV // simpCmd
    ]
Pushforward[fromM_?MatrixQ, coSys_?VectorQ, newCoSys_?VectorQ, simpCmd_:Simplify] :=
    With[{trM = Table[D[newCoSys, coSys[[i]]], {i, Length[coSys]}] // simpCmd},
        Transpose[trM] . fromM . trM // simpCmd
    ]
Pushforward[fromT_?ArrayQ, coSys_?VectorQ, newCoSys_?VectorQ, simpCmd_:Simplify] :=
    With[{trM = Table[D[newCoSys, coSys[[i]]], {i, Length[coSys]}] // simpCmd},
        pushpull[fromT, Transpose[trM], Length[coSys], Length[newCoSys], simpCmd]
    ] /; ArrayDepth[fromF] > 2

Pullback[fromF_?VectorQ, coSys_?VectorQ, newCoSys_?VectorQ, simpCmd_:Simplify] :=
    With[{trM = Table[D[newCoSys, coSys[[i]]], {i, Length[coSys]}] // simpCmd},
        trM . fromF // simpCmd
    ]
Pullback[fromM_?MatrixQ, coSys_?VectorQ, newCoSys_?VectorQ, simpCmd_:Simplify] :=
    With[{trM = Table[D[newCoSys, coSys[[i]]], {i, Length[coSys]}] // simpCmd},
        trM . fromM . Transpose[trM] // simpCmd
    ]
Pullback[fromT_?ArrayQ, coSys_?VectorQ, newCoSys_?VectorQ, simpCmd_:Simplify] :=
    With[{trM = Table[D[newCoSys, coSys[[i]]], {i, Length[coSys]}] // simpCmd},
        pushpull[fromT, trM, Length[newCoSys], Length[coSys], simpCmd]
    ] /; ArrayDepth[fromF] > 2

PushTensor[updnL_?VectorQ, fromT_?ArrayQ, coSys_?VectorQ, newCoSys_?VectorQ, forM_List, forN_List, simpCmd_:Simplify] := (
        (* check the rank *)
        If [Length[updnL] =!= ArrayDepth[fromT], Message[Msg::err, "incompatible ranks between", updnL, "and", fromT]; Return[$Failed]];

        With[{trM = Table[D[newCoSys /. forM, coSys[[i]]], {i, Length[coSys]}] // simpCmd,
              trN = Table[D[coSys /. forN, newCoSys[[i]]], {i, Length[newCoSys]}] // simpCmd},
            pushTensor[updnL, fromT, trM, trN, Length[coSys], Length[newCoSys], simpCmd]
        ]
    )

    pushpull[fromT_?ArrayQ, trM_?MatrixQ, fromDim_Integer, toDim_Integer, simpCmd_] := (* Pushforward or Pullback *)
        Module[{rcL},
            With[{rank = ArrayDepth[fromT]},
                With[{idxL = Unique /@ (("i" <> #)& /@ ToString /@ Range[rank])},
                    rcL = pushpullAUX[fromT, idxL];
                    Do [
                        rcL = Table[Sum[trM[[a, m]] (rcL /. {idxL[[i]] -> m}), {m, fromDim}], {a, toDim}] // simpCmd,
                        {i, rank, 1, -1}
                    ];
                    rcL
                ]
            ]
        ]

    pushTensor[updnL_?VectorQ, fromT_?ArrayQ, trM_?MatrixQ, trN_?MatrixQ, fromDim_Integer, toDim_Integer, simpCmd_] :=
        Module[{rcL},
            With[{rank = ArrayDepth[fromT]},
                With[{idxL = Unique /@ (("i" <> #)& /@ ToString /@ Range[rank])},
                    rcL = pushpullAUX[fromT, idxL];
                    Do [
                        If [DnIndexQ[updnL[[i]]],
                            rcL = Table[Sum[trN[[a, m]] (rcL /. {idxL[[i]] -> m}), {m, fromDim}], {a, toDim}] // simpCmd,
                        (* else *)
                            rcL = Table[Sum[Transpose[trM][[a, m]] (rcL /. {idxL[[i]] -> m}), {m, fromDim}], {a, toDim}] // simpCmd
                        ],
                        {i, rank, 1, -1}
                    ];
                    rcL
                ]
            ]
        ]

        pushpullAUX[fromT_, idxL:{__Integer}] := fromT[[Sequence @@ idxL]]

(* For diffeomorphic transformations *)
Ttransform[fromT:(fromTname_?IndexedTensorQ)[indices__], toTname_Symbol?IndexedTensorQ,
           leftCoSys_?VectorQ,                           rightCoSys_?VectorQ, simpCmd_:Simplify] :=
    With[{nDim = Length[leftCoSys]},
        If [!checkTtransform[fromTname, toTname, nDim, leftCoSys, rightCoSys], Return[$Failed]];

        With[{matM = Table[D[rightCoSys, leftCoSys[[i]]], {i, nDim}]},
            With[{upM = Transpose[matM] // simpCmd,  (* contravariant, -> *)
                  dnM = Inverse[matM] // simpCmd},   (* covariant,     -> *)
                tTransformAUX[fromT, toTname, upM, dnM, nDim, simpCmd];
            ]
        ]
    ]
Ttransform[toTname_Symbol?IndexedTensorQ, fromT:(fromTname_?IndexedTensorQ)[indices__],
           leftCoSys_?VectorQ,            rightCoSys_?VectorQ, simpCmd_:Simplify] :=
    With[{nDim = Length[leftCoSys]},
        If [!checkTtransform[fromTname, toTname, nDim, leftCoSys, rightCoSys], Return[$Failed]];

        With[{matM = Table[D[rightCoSys, leftCoSys[[i]]], {i, nDim}]},
            With[{invDnM = matM // simpCmd,                       (* covariant,     <- *)
                  invUpM = Transpose[Inverse[matM]] // simpCmd},  (* contravariant, <- *)
                tTransformAUX[fromT, toTname, invUpM, invDnM, nDim, simpCmd];
            ]
        ]
    ]
Ttransform[___] := Message[Ttransform::usage]

    checkTtransform[fromTname_, toTname_, nDim_, leftCoSys_, rightCoSys_] := (
            (* check the rank *)
            If [GetRank[fromTname] =!= GetRank[toTname], Message[Msg::err, "incompatible ranks between", fromTname, "and", toTname]; Return[False]];

            If [nDim =!= Length[rightCoSys],  (* diffeomorphic *)
                Message[Msg::err, "incompatible coordinate systems between", leftCoSys, "and", rightCoSys]; Return[False]
            ];
            True
        )

    tTransformAUX[fromT:_[indices__], toTname_, upM_, dnM_, fromDim_, simpCmd_] :=
    (* NB: only considered dn/up signature, i.e., contracted pairs are not considered. *)
        Module[{rcL = fromT},
            With[{toDim = fromDim,  (* diffeomorphic *)
                  aIndexL = {indices}},
                Do [
                    If [DnIndexQ[aIndexL[[i]]],
                        (* prepare for Table generation: i-th indices -> component indices *)
                        rcL = rcL /. {aIndexL[[i]] -> -m};
                        rcL = Table[ Sum[dnM[[a, m]] rcL, {m, fromDim}], {a, toDim} ] // simpCmd,
                    (* else *)
                        rcL = rcL /. {aIndexL[[i]] -> m};
                        rcL = Table[ Sum[upM[[a, m]] rcL, {m, fromDim}], {a, toDim} ] // simpCmd
                    ],
                    {i, Length[aIndexL], 1, -1}
                ];
                SetComponents[toTname[indices], rcL // simpCmd];
            ]
        ]

(****************************** Misc. ******************************)

(***** CommutatorVectors *****)
CommutatorVectors[vecList_?MatrixQ] := CommutatorVectors[vecList, DefaultKind]
CommutatorVectors[vecList_?MatrixQ, kind_Symbol] := (
        If [!CheckKind[kind], Return[$Failed]];
        If [!VectorQ[GetCoordinates[kind]], Message[Msg::err, "need to run SetCoordinates[..]", "", "", ""]; Return[$Failed]];

        (* return commutation relations between two or more vectors *)
        With[{nDim = GetDimension[kind]},
            If [!AllTrue[vecList, (Length[#] === nDim)&], Message[Msg::err, "invalid number of components.", "", "", ""]; Return[$Failed]];

            With[{nV = Length[Transpose[vecList][[1]]],  (* # of vectors *)
                  nullV = Table[0, {i, nDim}]},          (* null vector *)
                Module[{rc},
                    Do [
                        Do [
                            rc = commutatorTwoVectors[vecList[[i]], vecList[[j]], nDim, kind];
                            If [rc =!= nullV, Print[Sequence[Subscript["[V", i], ",", Subscript["V", j], "] = ", rc]]],
                            {j, i + 1, nV}
                        ],
                        {i, nV - 1}
                    ]
                ]
            ]
        ]
    )
CommutatorVectors[v1_?VectorQ, v2_?VectorQ]              := CommutatorVectors[v1, v2, DefaultKind]
CommutatorVectors[v1_?VectorQ, v2_?VectorQ, kind_Symbol] := (
        If [!CheckKind[kind], Return[$Failed]];
        If [!VectorQ[GetCoordinates[kind]], Message[Msg::err, "need to run SetCoordinates[..]", "", "", ""]; Return[$Failed]];

        With[{nDim = GetDimension[kind]},
            If [!(nDim == Length[v1] == Length[v2]), Message[Msg::err, "incompatible vectors", "", "", ""]; Return[$Failed]];
            commutatorTwoVectors[v1, v2, nDim, kind]
        ]
    )
CommutatorVectors[___] := Message[CommutatorVectors::usage]

    (* commutator between two vectors: v1 = {comp1, comp2,...} *)
    commutatorTwoVectors[v1_List, v2_List, nDim_, kind_] :=
            Table[
                Sum[ v1[[j]] * bdD[j, v2[[i]], kind] - v2[[j]] * bdD[j, v1[[i]], kind], {j, nDim}],
                {i, nDim}
            ] // Together

(***** LineElement *****)
LineElement[coSys_?VectorQ, metric_?SquareMatrixQ, simpCmd_:Together] :=
    With[{nDim = Length[coSys]},
        If [nDim =!= Length[metric[[1]]], Message[Msg::err, "incompatible metric with", coSys, "", ""]; Return[$Failed]];

        (* print line element *)
        Module[{rc},
            rc = Sum[
                If [i === j,
                    metric[[i, j]] * Row[{"d", Superscript[coSys[[i]], "2"]}],
                (* else *)
                    2 * metric[[i, j]] * Row[{"d", coSys[[i]], "d", coSys[[j]]}]
                ], {i, nDim}, {j, i, nDim}
            ];

            Row[{"d", Superscript["s", "2"], " = ", rc // simpCmd}]
        ]
    ]
LineElement[___] := Message[LineElement::usage]

(************* Flat SpaceTimes in Cartesian Coordinates ************) (* Experimental *)

SetConstantMetric[]            := SetConstantMetric[DefaultKind]
SetConstantMetric[kind_Symbol] := (
            If [!MetricSpaceQ[kind], Message[Msg::err, kind, "is not a metric space.", "", ""]; Return[$Failed]];
            constantMetricQ[kind] = True;
            SetMetricCompatible[BD, GetMetric[kind]];
            setZeroCurv[kind];
        )

SetConstantMetric[argL_List]              := SetConstantMetric[argL, DefaultKind]
SetConstantMetric[argL_List, kind_Symbol] :=
    With[{coSys = SymbolJoin /@ Table[{"x", ToString[i]}, {i, First @ Dimensions[argL]}]},
        SetConstantMetric[argL, coSys, kind]
    ] /; VectorQ[argL, (# == -1 || # == 1)&] || (SquareMatrixQ[argL] && VectorQ[Flatten @ argL, NumericQ])

SetConstantMetric[argL_List, coSys_?VectorQ]              := SetConstantMetric[argL, coSys, DefaultKind]
SetConstantMetric[argL_List, coSys_?VectorQ, kind_Symbol] :=
    With[{n = First @ Dimensions[argL]},
        If [!MetricSpaceQ[kind],     Message[Msg::err, kind, "is not a metric space.", "", ""];       Return[$Failed]];
        If [!CoordinateBasisQ[kind], Message[Msg::err, kind, "is not in coordinate basis.", "", ""];  Return[$Failed]];
        If [n =!= Length[coSys],     Message[Msg::err, "incompatible arguments:", vec, "and", coSys]; Return[$Failed]];

        GetDimension[kind] = n;
        SetCoordinates[coSys, kind];

        (* m + p = n, -m + p = signature, m = (n - signature)/2 *)
        With[{signature = If [VectorQ[argL], Total[argL], Total[Eigenvalues[argL]]]},
            With[{s = (n - signature)/2,
                  metric = GetMetric[kind],
                  matg = If [VectorQ[argL], DiagonalMatrix[argL], argL],
                  epsilon = GetEpsilon[kind],
                  tSymL = ToImag[#, n]& /@ MakePermGroup[symToGenSet["Antisymmetric", n], n]},

                SetSig[s, kind];  (* Assumption: vec == {-1 or +1,..} *)

                constantMetricQ[kind] = True;
                SetMetricCompatible[BD, metric];
                setZeroCurv[kind];

                tableToComponents[metric, 2, {-1,-1}, matg];
                tableToComponents[metric, 2, { 1, 1}, Inverse @ matg];

                (epsilon[ Sequence @@ (-Range[n])[[ List @@ (SignOfTerm[#] * #) ]] ] =          SignOfTerm[#])& /@ tSymL;
                (epsilon[ Sequence @@ ( Range[n])[[ List @@ (SignOfTerm[#] * #) ]] ] = (-1)^s * SignOfTerm[#])& /@ tSymL;
                epsilon[args:(_Integer ..)] := 0 /; Length[{args}] === n && Length[Abs[{args}]] =!= Length[Union[Abs[{args}]]]
            ]
        ]
    ] /;  VectorQ[argL, (# == -1 || # == 1)&] || (SquareMatrixQ[argL] && VectorQ[Flatten @ argL, NumericQ]) && VectorQ[coSys, AtomQ]
SetConstantMetric[___] := Message[SetConstantMetric::usage]

    setZeroCurv[kind_] := setZeroCurvDerOp /@ getDerOperators[kind]

        setZeroCurvDerOp[derOp_] := (
            getDerOp[Gamma]  [derOp][a_, b_, c_]     := 0;  (* Cartesian Coordinates *)
            getDerOp[Riemann][derOp][a_, b_, c_, d_] := 0;
            getDerOp[Ricci]  [derOp][a_, b_]         := 0;
            getDerOp[Scalar] [derOp][]               := 0;
        )

ClearConstantMetric[]            := ClearConstantMetric[DefaultKind]
ClearConstantMetric[kind_Symbol] :=
    With[{metric = GetMetric[kind], n = GetDimension[kind]},
        If [PositiveIntegerQ[n],
			With[{epsilon = GetEpsilon[kind],
                  tSymL = ToImag[#, n]& /@ MakePermGroup[symToGenSet["Antisymmetric", n], n]},

                epsilon[args:(_Integer ..)] =. /; Length[{args}] === n && Length[Abs[{args}]] =!= Length[Union[Abs[{args}]]];

	            (epsilon[ Sequence @@ (-Range[n])[[ List @@ (SignOfTerm[#] * #) ]] ] =.)& /@ tSymL;
	            (epsilon[ Sequence @@ ( Range[n])[[ List @@ (SignOfTerm[#] * #) ]] ] =.)& /@ tSymL;

                clearComponents[metric, 2, {n, n}, {-1,-1}];
                clearComponents[metric, 2, {n, n}, { 1, 1}];

                ClearSig[kind];
                ClearCoordinates[kind]
			]
        ];

        clearZeroCurv[kind];
        ClearMetricCompatible[BD, metric];
        constantMetricQ[kind] = False;

        (* restore Tensors in DefaultKind *)
        If [kind === DefaultKind, SetDefaultKind[DefaultKind]]
    ] /; MetricSpaceQ[kind] && constantMetricQ[kind] === True
ClearConstantMetric[___] := Message[ClearConstantMetric::usage]

    clearZeroCurv[kind_] := clearZeroCurvDerOp /@ getDerOperators[kind]

        clearZeroCurvDerOp[derOp_] := (
            getDerOp[Gamma]  [derOp][a_, b_, c_]     =.;
            getDerOp[Riemann][derOp][a_, b_, c_, d_] =.;
            getDerOp[Ricci]  [derOp][a_, b_]         =.;
            getDerOp[Scalar] [derOp][]               =.;
        )

(********************************************************************************)

initTensorGRG[] := (
        (* the sign convention of RiemannCD *)
        riemannSign = -1;

        (***** End of initTensorGRG *****)
		loadedTensorGRG = True;  (* guard reloding *)
    )
initTensorGRG[]

(********************************************************************************)

End[] (* End Private Context *)

EndPackage[]
