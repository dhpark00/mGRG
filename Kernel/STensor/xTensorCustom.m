(********************************************************************************)
(******************************** xTensorCustom.m *******************************)
(********************************************************************************)

(********************************************************************************)
(* Customizing xTensor's functions for STensor
  1. An expression is passed to `flattenObject`.
  2. `flattenObject` recursively traverses the expression, converting each part into an `xObject`.
  3. The resulting `xObject`s are passed to `xSort` to establish a canonical order.
  4. The sorted structure is then passed to `xSymmetryOf` to determine its full index symmetry.
  5. Finally, `Tsimplify` use this structured information to perform simplifications.
*)

(********************************************************************)
BeginPackage["mGRG`STensor`", {"mGRG`mPerm`"}]
(********************************************************************)

(***** for debugging *****)
xObject::usage           = ""

xCommutingObjects::usage = ""
xNoIndex::usage          = ""
xTensorTimes::usage      = ""

xSlot::usage             = ""  (* used in FreePatternQ *)
xTTimes::usage           = ""
xSymmetry::usage         = ""

(********************************************************************)
Begin["`Private`"]

errObject/: MakeBoxes[errObject[obj_], StandardForm] := interpretBox[errObject[obj], ToBoxes @ obj]

(************************* flattenObject ****************************)
(*****
    `xObject` holds a flattened, unambiguous representation of a tensor expression:
        xObject[obj, nameL, {indexL, freeL, dummyL, metricStateL}]

        - obj: The original expression fragment this xObject represents.
        - nameL: A list of all heads involved (e.g., {CD, Riemann} for CD[a, Riemann[...]]).
        - indexL: All indices present in their original order.
        - freeL: A list of free (non-contracted) indices.
        - dummyL: A list of dummy (contracted) indices.
        - metricStateL: A list of states for each index, crucial for raising/lowering.

        Each 'metricState' is {upDown, metric, moveFlag}:
        - {+1|-1, Null,   0}     : No metric available or blocked by non-metric-compatible derivatives. Index cannot be raised/lowered and metric cannot be moved out.
        - {+1|-1, metric, 0}     : A metric exists, but is blocked (e.g., by a non-compatible derivative). Index can be raised/lowered and metric cannot be moved out.
        - {+1|-1, metric, +1|-1} : A metric exists. Index can be raised/lowered and metric can be moved out.

        계량 텐서가 없으면 moveFlag은 아무런 역할을 하지 않는다. 그러나 계량 텐서가 있으면 0/+1/-1 값을 갖는다.
            0:     계량 텐서로 up/dn은 가능하지만 비공변 도함수의 작용 때문에 계량 텐서가 도함수 밖으로 이동 불가능
            +1/-1: 계량 텐서가 그에 따른 대칭 부호를 가지고 공변 도함수만 작용한 경우로 계량 텐서가 도함수 밖으로 이동 가능
 *****)

(* computes the metric state for a given index associated with an object or a CD-type operator *)
metricState[idx_?TensorialIndexQ, oName_, cOptL_] :=
    With[{kind = IndexToKind[idx]},
        With[{metric = GetMetric[kind]},
            Which[
                oName === Kdelta,        {dnupState[idx], metric, 0},  (* Kdelta의 metricSymmetry는 0. *)
                IndexedOperandQ[oName],  {dnupState[idx], metric, metricSymmetry[kind]},
                IndexedOperatorQ[oName], {dnupState[idx], metric, If [covariantNameQ[oName, kind, cOptL], metricSymmetry[kind], 0]},
                True,                    {dnupState[idx], Null,   0}  (* internal error *)
            ]
        ]
    ]
metricState[idx_?ComponentIndexQ, _, _] := {dnupState[idx], Null, 0} (* NB: component indices can NOT be contracted, so {_, Null, 0} *)
metricState[___]                        := {Null, Null, 0}

reCheckMetricStates[der_, {indexL_, freeL_, dummyL_, mStates_}, cOptL_] := {indexL, freeL, dummyL, metricDerState[#, der, cOptL]& /@ mStates}

    (* modification of metricState induced by a derivative *)
    metricDerState[{updn_, metric_, mSign_}, der_, cOptL_] := {updn, metric, mSign} /; dnupDerQ[der, metric, cOptL]  (* keep metricState *)
    metricDerState[{updn_, _,       _},      _,    _]      := {updn, Null,   0}

        dnupDerQ[{opName_, arg___}, metric_, cOptL_] :=  (* can dn/up by a metric? Is opName metric-compatible? *)
            With [ {opType = getType[opName], mKind = KindOf[metric], opKind = KindOf[opName, arg]},
                MetricCompatibleQ[opName, metric, cOptL] && ( (opType === CD && KindMatchQ[opKind, mKind] && ValidIndexQ[arg, mKind])  \
                                                              || (opType === LD || opType === XD) )
            ]

flattenObject[expr_Plus,  _]      := $flattenOTHER[expr]  (* flattenObject is not for Plus expressions *)
flattenObject[expr_Times, cOptL_] := flattenObject[#, cOptL]& /@ xTensorTimes @@ expr

(* for indexed operands *)
flattenObject[(oName_?IndexedOperandQ)[indices___], cOptL_] :=
    With[{indexL = {indices}},
        If [!checkObject[oName, indexL], Return[errObject[ErrorT[oName][indices]]]];
  
        xObject[
            oName[indices],
            {oName},
            {indexL, dropPairs[indexL], takePairs[indexL], metricState[#, oName, cOptL]& /@ indexL}  (* NB: freeL includes components indices *)
        ]
    ]

(* for indexed operators *)
flattenObject[(opName_?IndexedOperatorQ)[arg_, expr___], cOptL_] :=
    Switch [getType[opName],
        CD, If [!ValidIndexQ[arg, KindOf[opName, arg]], Return[errObject[ErrorT[opName][arg, expr]]]];  (* check validity of the index of a CD-type operator *)
            If [DuplicatedIndicesQ @ Join[{arg}, FindIndices @ expr], Return[errObject[ErrorT[opName][arg, expr]]]];
            addDerivative[CD, {opName, arg}, flattenObject[expr, cOptL], cOptL],
        LD, addDerivative[LD, {opName, arg}, flattenObject[expr, cOptL], cOptL],
        XD, addDerivative[XD, {opName},      flattenObject[arg,  cOptL], cOptL],
        XP, If [DuplicatedIndicesQ[Flatten @ (FindIndices /@ {arg, expr})], Return[errObject[ErrorT[opName][arg, expr]]]];  (* check validity of indices *)
            $flattenOTHER[opName[arg, expr]]  (* XP operators are not canonicalized for now *)
    ]

    (* helper to add a derivative layer to an existing xObject *)
    addDerivative[CD, {opName_, opIndex_}, xObject[obj_, nameL_, inds_], cOptL_] :=
        xObject[
            opName[opIndex, obj],
            Join[{opName}, nameL],
            prependIndex[opName, opIndex, reCheckMetricStates[{opName, opIndex}, inds, cOptL], cOptL]
        ]

        prependIndex[op_,  idx_, {indexL_, freeL_, dummyL_, mStates_}, cOptL_] :=
            With[{pidx = FlipIndex[idx]},
                Which[
                    TensorialIndexQ[idx] && MemberQ[freeL, pidx],  (* idx is contracted with the index in free indices *)
                        {Prepend[indexL, idx], DeleteCases[freeL, pidx], Prepend[Prepend[dummyL, pidx], idx], Prepend[mStates, metricState[idx, op, cOptL]]},
                    True,                                          (* idx is free or a component index *)
                        {Prepend[indexL, idx], Prepend[freeL, idx], dummyL, Prepend[mStates, metricState[idx, op, cOptL]]}
                ]
            ]

    addDerivative[LD, {opName_, vName_}, xObject[obj_, nameL_, inds_], cOptL_] :=
        xObject[
            opName[vName, obj],
            Join[{opName, vName}, nameL],
            reCheckMetricStates[{opName, vName}, inds, cOptL]
        ]

    addDerivative[XD, {opName_}, xObject[obj_, nameL_, inds_], cOptL_] :=
        xObject[
            opName[obj],
            Join[{opName}, nameL],
            reCheckMetricStates[{opName}, inds, cOptL]
        ]

    addDerivative[_, {opName_, arg___}, errObject[obj_],       _] := errObject[ErrorT[opName][arg, obj]]
    addDerivative[_, {opName_, arg___}, $flattenOTHER[other_], _] := $flattenOTHER[opName[arg, other]]

flattenObject[Tscalar[expr_], cOptL_] :=
    If [FindFreeTensorialIndices[expr, HeadQs -> {ObjectQ}] =!= {},
        Return[errObject[ErrorT[Tscalar][expr]]],
    (* else *)
        With [{expr1 = scalarCan[expr, cOptL]},
            xObject[Tscalar[expr1], {expr1}, {{}, {}, {}, {}}]
        ]
    ]

(* Scalar-function of a single argument: e.g., Log[x] *)
flattenObject[(sf_?ScalarFunctionQ)[expr_], cOptL_] :=
    If [FindFreeTensorialIndices[expr, HeadQs -> {ObjectQ}] =!= {}, Return[errObject[ErrorT[sf][expr]]],
    (* else *)                                                      addHead1A[sf, flattenObject[Tscalar @ expr, cOptL]]]

    addHead1A[head_, xObject[obj_, nameL_, inds_]] := xObject[head[obj], Join[{head}, nameL], inds]

(* Scalar-function of two arguments: e.g., Power[x, n] *)
flattenObject[(sf_?ScalarFunctionQ)[expr1_, expr2_], cOptL_] :=
    If [FindFreeTensorialIndices[expr1, HeadQs -> {ObjectQ}] =!= {},
        Return[errObject[ErrorT[sf][expr1, expr2]]],
    (* else *)
        If [FindFreeTensorialIndices[expr2, HeadQs -> {ObjectQ}] =!= {},
            Return[errObject[ErrorT[sf][expr1, expr2]]],
        (* else *)
            With[{rcExpr1 = scalarCan[Tscalar @ expr1, cOptL], rcExpr2 = scalarCan[Tscalar @ expr2, cOptL]},
                xObject[sf[Tscalar[rcExpr1], Tscalar[rcExpr2]], Join[{sf}, {rcExpr1}, {rcExpr2}], {{}, {}, {}, {}}]
            ]
        ]
    ]

flattenObject[err_errObject, _]       := err
flattenObject[other_$flattenOTHER, _] := other                 (* one identity of $flattenOTHER *)
flattenObject[other_,              _] := $flattenOTHER[other]  (* wrap $flattenOTHER *)

scalarCan[expr_, cOptL_] := ResetDummies[Tsimplify[expr, Sequence @@ cOptL], HeadQs -> {ObjectQ}]

(****************************** xSort *******************************)

xSort[expr_Plus, opts___] := xSort[#, opts]& /@ expr
xSort[expr_,     opts___] := objectSort @ markNoIndex[flattenObject[expr, FilterRules[{opts}, CovDs]]]

    markNoIndex[obj:xObject[_, _, {_, {}, {}, _}]] := xNoIndex[obj]  (* no free/dummy indices *)
    markNoIndex[obj_xObject]                       := obj
    markNoIndex[err_errObject]                     := err
    markNoIndex[$flattenOTHER[other_]]             := xNoIndex[other]
    markNoIndex[expr_xTensorTimes]                 := markNoIndex /@ expr
    markNoIndex[expr_]                             := (Message[Msg::warn, "markNoIndex:", "not properly processed,", expr, ""]; expr)

    (* sort and mark xCommutingObjects *)
    objectSort[expr_]             := expr /; MemberQ[{xObject, xNoIndex, errObject, $flattenOTHER}, Head[expr]]
    objectSort[expr_xTensorTimes] :=
        Block[{$freesForSorting = freeIndicesOf[expr]},
            breakCommutings /@ Split[Sort[expr, objectOrderQ], objectOrderEqualQ]
        ]
    objectSort[expr_] := (Message[Msg::warn, "objectSort:", "not properly processed,", expr, ""]; expr)

        breakCommutings[xTensorTimes[x_]]  := x
        breakCommutings[xTensorTimes[x__]] := xCommutingObjects[x]

        freeIndicesOf[xObject[_, _, {_, frees_, _, _}]] := frees
        freeIndicesOf[_xNoIndex]                        := {}
        freeIndicesOf[_errObject]                       := {}
        freeIndicesOf[_$flattenOTHER]                   := {}
        freeIndicesOf[expr_xCommutingObjects]           := dropPairs[Join @@ List @@ (freeIndicesOf /@ expr)]  (* include component indices as free indices *)
        freeIndicesOf[expr_xTensorTimes]                := dropPairs[Join @@ List @@ (freeIndicesOf /@ expr)]

        objectOrderQ     [obj1_, obj2_] := Order[objectOrderItems[obj1], objectOrderItems[obj2]] >= 0;
        objectOrderEqualQ[obj1_, obj2_] := Order[objectOrderItems[obj1], objectOrderItems[obj2]] == 0;

            (* selected items for sorting *)
            objectOrderItems[xObject[_, nameL_, {idxL_, free_, _, ms_}]] :=
                With[{frees = Intersection[free, $freesForSorting]},
                    {nameL, Length[idxL], -Length[frees], mStateOrderItems /@ ms}
                ]
            objectOrderItems[xNoIndex[_]] := {{" "}, -Infinity, Infinity, Null} (* sort scalars first *)

                mStateOrderItems[{dnup_, Null,    _}] := dnup    (* keep dn/up *)
                mStateOrderItems[{_,     metric_, _}] := metric  (* neglect dn/up *)

xUnSort[xObject[obj_, _, _]]    := obj
xUnSort[xNoIndex[obj_]]         := xUnSort[obj]
xUnSort[expr_xCommutingObjects] := Times @@ (xUnSort /@ expr)
xUnSort[expr_xTensorTimes]      := Times @@ (xUnSort /@ expr)
xUnSort[errObject[obj_]]        := obj
xUnSort[$flattenOTHER[other_]]  := other
xUnSort[other_]                 := other

(****************** metricStatesOf and xSymmetryOf ******************)

(* extract metricStates from xSorted objects *)
metricStatesOf[xObject[_, _, {_, _, _, mStateL_}]]         := mStateL
metricStatesOf[xNoIndex[_]]                                := {}
metricStatesOf[expr_xCommutingObjects | expr_xTensorTimes] := Flatten[metricStatesOf /@ (List @@ expr), 1]

(*
    xSymmetry[
        the number of slots,
        expr with all indices replaced by slot numbers,
        a list of rules xSlot[n] -> index,
        a Generating Set of expr
    ]
 *)

Format[xSlot[n_Integer]] := "\[FilledCircle]" <> ToString[n]

(* to keep the order of the (already sorted) tensors. *)
SetAttributes[xTTimes, Flat]
xTTimes[1, x__] := xTTimes[x]

(* generates a list of rules xSlot[i] -> index, assuming that there are already n slots *)
toSlotRules[n_Integer, indexL_List] := MapIndexed[Rule[xSlot @@ (n + #2), #1]&, indexL]

emptySymmetry[x_]            := xSymmetry[0,             x, {},                   GenSet[]]
emptySymmetry[x_, inds_List] := xSymmetry[Length @ inds, x, toSlotRules[0, inds], GenSet[]]

(* moves the points by 'd' *)
displaceSlots[gs_GenSet,                         d_Integer] := gs /. (Cycles[{cycs__}] :> Cycles[{cycs} + d])
displaceSlots[xSymmetry[n_, expr_, slotL_, gs_], d_Integer] := xSymmetry[n + d, Sequence @@ ({expr, slotL} /. xSlot[x_] :> xSlot[x + d]), displaceSlots[gs, d]]
displaceSlots[expr_,                             d_Integer] := expr /. xSlot[x_] :> xSlot[x + d]

xSymmetryOf[(oName_?IndexedOperandQ)[indices___], ___] :=
    With[{len = Length[{indices}]},
        xSymmetry[len, oName @@ (First /@ #), #, getGenSetOf[oName[indices]]]& @ toSlotRules[0, {indices}]
    ]
xSymmetryOf[(opName_?IndexedOperatorQ)[arg_, expr___], opts___] :=
    Switch [getType[opName],
        CD, cdTypeSymmetryOf[{opName[arg]}, expr, opts],
        LD, MapAt[opName[arg, #]&, xSymmetryOf[expr, opts], 2],
        XD, MapAt[opName, xSymmetryOf[arg, opts], 2],
        XP, MapAt[opName, emptySymmetry[{arg, expr}], 2]
    ]

    cdTypeSymmetryOf[{cds__}, opName_[ind_, expr_], opts___] := cdTypeSymmetryOf[Join[{opName[ind]}, {cds}], expr, opts] /; IndexedOperatorQ[opName] && getType[opName] === CD
    cdTypeSymmetryOf[{cds__}, expr_,                opts___] := processDerStack[Append[xSymmetryOf[expr, opts], tmpCovD[cds]], opts]

        (* recursively processes a stack of derivatives to determine their combined symmetry. *)
        (* Rule 1: If there are no more derivatives, return the symmetry *)
        processDerStack[xSymmetry[n_, expr_, rules_, gs_, tmpCovD[]], ___] := xSymmetry[n, expr, rules, gs]

        (* Rule 2: If the first covd cannot commute, remove it *)
        processDerStack[xSymmetry[n_, expr_, rules_, gs_, tmpCovD[covd_[a_], y___]], opts___] :=
            processDerStack[
                Append[
                    displaceSlots[xSymmetry[n, covd[xSlot[0], expr], Join[{xSlot[0] -> a}, rules], gs], 1],
                    tmpCovD[y]
                ],
                opts
            ] /; (covD =!= BD && DerivativeOperatorQ[covD])  \
                 || (covD === BD && !covariantNameQ[BD, IndexToKind[a], FilterRules[{opts}, CovDs]] && UpIndexQ[a])  (* CD[la, T] or BD[ua, T] *)

        (* Rule 3: If the first and second derivatives are different, remove the first *)
        processDerStack[xSymmetry[n_, expr_, rules_, gs_, tmpCovD[covd1_[a1_], covd2_[a2_], y___]], opts___] :=
            processDerStack[
                Append[
                    displaceSlots[xSymmetry[n, covd1[xSlot[0], expr], Join[{xSlot[0] -> a1}, rules], gs], 1],
                    tmpCovD[covd2[a2], y]
                ],
                opts
            ] /; covd1 =!= covd2

        (* Rule 4: Two identical covariant derivatives of a scalar commute if the derivative is torsion-free. *)
        processDerStack[xSymmetry[n_, expr_, rules_, gs_, tmpCovD[covd_[a1_], covd_[a2_], y___]], opts___] :=
            With[{xSym = displaceSlots[xSymmetry[n, covd[xSlot[-1], covd[xSlot[0], expr]], Join[{xSlot[-1] -> a2, xSlot[0] -> a1}, rules], gs], 2]},
                processDerStack[
                    Append[
                        ReplacePart[xSym, 4 -> Join[GenSet[{Cycles[{{1,2}}], 1}], xSym[[4]]]],
                        tmpCovD[y]
                    ],
                    opts
                ]
            ] /; DerivativeOperatorQ[covd] && TorsionFreeQ[covd] && AllTrue[{a1, a2}, TensorialIndexQ]  \
                 && NoIndexQ[expr /. rules] && ValidIndexQ[{a1, a2}, KindOf[covd]]                      \
                 && ( (DnIndexQ[a1] && DnIndexQ[a2]) || covariantNameQ[covd, IndexToKind[a1], FilterRules[{opts}, CovDs]] );

        (* Rule 5: Other torsionful derivatives *)
        processDerStack[xSymmetry[n_, expr_, rules_, gs_, tmpCovD[covd_[a_], y___]], opts___] :=
            processDerStack[
                Append[
                    displaceSlots[xSymmetry[n, covd[xSlot[0], expr], Join[{xSlot[0] -> a}, rules], gs], 1],
                    tmpCovD[y]
                ],
                opts
            ] /; DerivativeOperatorQ[covd] && !TorsionFreeQ[covd]

        (* Drivers for the three remaining cases *)
        (* Rule 6: *)
        processDerStack[xSymmetry[n_, expr_, rules_, gs_, tmpCovD[y:covd_[_].., covd1_[a_], z___]], opts___] :=
            processDerStackSym[xSymmetry[n, expr, rules, gs, tmpCovD[y], tmpCovD[covd1[a], z]], opts] /; covd =!= covd1

        (* Rule 7-1: *)
        processDerStack[xSymmetry[n_, expr_, rules_, gs_, tmpCovD[y:covd_[_].., covd_[a_],  z___]], opts___] :=
            processDerStackSym[xSymmetry[n, expr, rules, gs, tmpCovD[y], tmpCovD[covd[a], z]],  opts] /; !covariantNameQ[covd, IndexToKind[a], FilterRules[{opts}, CovDs]] && UpIndexQ[a]

        (* Rule 7-2: *)
        processDerStack[xSymmetry[n_, expr_, rules_, gs_, tmpCovD[y:_[_]..]], opts___] := processDerStackSym[xSymmetry[n, expr, rules, gs, tmpCovD[y], tmpCovD[]], opts]

            (* If there are several BD derivatives that can commute, give gs *)
            processDerStackSym[xSymmetry[n_, expr_, rules_, gs_, tmpCovD[y__], tmpCovD[z___]], opts___] :=
                With[{opName = Head[First @ {y}],
                      inds = Apply[Identity, {y}, {1}],
                      newSym = displaceSlots[xSymmetry[n, expr, rules, gs], Length @ {y}]},

                    Module[{newGS = newSym[[4]]},
                        (* BD[..., la, lB, lc, ..., T] *)
                        With[{slotRules = toSlotRules[0, Reverse @ inds]},
                            With[{modSlotRules = If [!covariantNameQ[opName, IndexToKind[First @ inds], FilterRules[{opts}, CovDs]], Select[slotRules, DnIndexQ[#[[2]]]&],
                                                 (* else *)                                                                          slotRules]},

                                If [Length[modSlotRules] >= 2 && opName === BD,
                                    With[{sortedL = SplitBy[modSlotRules, (IndexToKind @ #[[2]])&]},  (* CoordinateBasisQ[kind] *)
                                        With[{slots = First /@ First /@ #},
                                            If [Length[slots] >= 2 && CoordinateBasisQ[IndexToKind[#[[1,2]]]], newGS = Join[symmetricGS[slots], newGS]]
                                        ]& /@ sortedL
                                    ]
                                ]
                            ];

                            processDerStack[
                                xSymmetry[
                                    n + Length[inds],
                                    Last @ FoldList[opName[#2,#1]&, newSym[[2]], Reverse[xSlot /@ (First /@ First /@ slotRules)]],
                                    Join[slotRules, newSym[[3]]],
                                    newGS,
                                    tmpCovD[z]
                                ],
                                opts
                            ]
                        ]
                    ]
                ]

                symmetricGS[inds_] := GenSet @@ ({Cycles[{#}], 1}& /@ Partition[Sort @ inds, 2, 1])

xSymmetryOf[x:(_?ScalarFunctionQ)[___],    ___]     := emptySymmetry[x]
xSymmetryOf[err_errObject,                 ___]     := emptySymmetry[err]
xSymmetryOf[other_$flattenOTHER,           ___]     := emptySymmetry[other]
xSymmetryOf[xObject[obj_, _, _],           opts___] := xSymmetryOf[obj, opts]
xSymmetryOf[expr_xTensorTimes,             opts___] := Fold[joinSymmetries, emptySymmetry[1], xSymmetryOf[#, opts]& /@ expr]
xSymmetryOf[xNoIndex[obj_],                ___]     := emptySymmetry[obj]
xSymmetryOf[xNoIndex[xObject[obj_, _, _]], ___]     := emptySymmetry[obj]
xSymmetryOf[xCommutingObjects[obj__],      opts___] :=
    With[{nObj = Length @ {obj}, sym = Fold[joinSymmetries, emptySymmetry[1], xSymmetryOf[#, opts]& /@ xTensorTimes[obj]]},
        With[{nsTotal = Length @ sym[[3]]},  (* Number of slots in the expression *)
            (* combine both the symmetries of the objects themselves with the symmetries obtained by commutation. *)
            With[{gs = Join[Last @ sym, commutingCycles[nsTotal, nsTotal / nObj]]},
                ReplacePart[sym, 4 -> gs]
            ]
        ]
    ]
xSymmetryOf[term_,                         opts___] := xSymmetryOf[xSort[term, opts], opts]

    (* We need to combine both the symmetries of the objects themselves and the symmetries obtained by commutation.
       There are nsTotal indices, with tensors having ns indices (hence ns must be a divisor of nsTotal) *)
    commutingCycles[ns_Integer,      ns_Integer] := GenSet[]
    commutingCycles[nsTotal_Integer, ns_Integer] :=
        Join[
            commutingCycles[nsTotal - ns, ns],
            GenSet[{Cycles @ Transpose[{Range[nsTotal - 2 ns + 1, nsTotal - ns], Range[nsTotal - ns + 1, nsTotal]}], 1}]
        ]

    (* Joins two xSymmetry objects together for composite expressions.
       Note that slots of the first Symmetry are kept and slots of the second are shifted n1 places.
       The resulting second argument of xSymmetry has head xTTimes. *)
    joinSymmetries[xSymmetry[n1_, expr1_, rules1_, gs1_], xSymmetry[n2_, expr2_, rules2_, gs2_]] :=
        xSymmetry[
            n1 + n2,
            xTTimes[expr1, displaceSlots[expr2, n1]],
            Join[rules1,   displaceSlots[rules2, n1]],
            Join[gs1,      displaceSlots[gs2, n1]]
        ]

(********************************************************************)

End[] (* End Private Context *)

EndPackage[]
