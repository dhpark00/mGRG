(********************************************************************)
(**************************** Variation.m ***************************)
(********************************************************************)

(********************************************************************)
BeginPackage["mGRG`STensor`", {"mGRG`mPerm`"}]
(********************************************************************)

(********************************************************************)
Begin["`Private`"]

(********************* Variational Derivative ***********************)
(* TODO: 많은 예제를 통한 좀 더 철저한 테스트 필요. *)

Options[VD] = {BD -> {BD}, IndependentVD -> {}, ByPartsVD -> False};

VD[arg_, expr_, opts___Rule] := VD[arg, DumFresh[expr], 1, opts] /; FreePatternQ[{arg, expr, opts}]

(* define XP-type operator VD *)
VD/: MakeBoxes[VD[arg_, expr_, 1,     opts___Rule], StandardForm] := interpretBox[VD[arg, expr, 1, opts],
        TemplateBox[{"[", "(",
                     SubscriptBox["\[Delta]", MakeBoxes[arg, StandardForm]], MakeBoxes[expr, StandardForm], ")", "]"}, "RowDefault"]
    ]
VD/: MakeBoxes[VD[arg_, expr_, rest_, opts___Rule], StandardForm] := interpretBox[VD[arg, expr, rest, opts],
        TemplateBox[{"[", MakeBoxes[rest, StandardForm], "(",
                     SubscriptBox["\[Delta]", MakeBoxes[arg, StandardForm]], MakeBoxes[expr, StandardForm], ")", "]"}, "RowDefault"]
    ]

(* Linear *)
VD[arg_, expr_Plus, rest_, opts___Rule] := VD[arg, #, rest, opts]& /@ expr

(* Leibnitz rule *)
VD[arg_, expr_Times, rest_, opts___Rule] := Sum[varDtake[arg, rest, List @@ expr, cnt, opts], {cnt, Length @ expr}]

    varDtake[arg_, rest_, lst_List, n_Integer, opts___Rule] := VD[arg, lst[[n]], Times @@ ReplacePart[lst, n -> rest], opts]

(* Derivation *)
VD[_,     _?ConstantQ,         _,         ___Rule] := 0
VD[arg_, c_?ConstantQ * expr_, rest_, opts___Rule] := c * VD[arg, expr, rest, opts]

(* Scalar functions *)
VD[arg_, (sf_?ScalarFunctionQ)[expr_], rest_, opts___Rule] := VD[arg, DumFresh[expr], sf'[expr] * rest, opts] /; sf =!= Tscalar
VD[arg_, Power[expr1_, expr2_],      rest_, opts___Rule] := (
          VD[arg, DumFresh[expr1], DumFresh[expr2] * Power[expr1, expr2 - 1]  * rest, opts]
        + VD[arg, DumFresh[expr2], Power[expr1, expr2] * Log[DumFresh[expr1]] * rest, opts]
    )

(* Remove Tscalar head because the results are in general not a scalar *)
VD[arg_, Tscalar[expr_], rest_, opts___Rule] := VD[arg, DumFresh[expr], rest, opts]

(* expr including a metric wrt the same metric *)
VD[metric_[a_, b_], (metric_Symbol?MetricQ)[c_, d_], rest_, ___Rule] :=
    With [{fa = FlipIndex[a], fb = FlipIndex[b]},
        mSign[a, b, c, d] * rest * (metric[fa, c]*metric[fb, d] + metricSymmetry[metric] * metric[fa, d]*metric[fb, c])/2
    ]

    mSign[a_, b_, c_, d_] :=  1 /; UpupDndnIndexQ[{a, b, c, d}]
    mSign[a_, b_, c_, d_] := -1 /; UpupDndnIndexQ[{a, b}] && UpupDndnIndexQ[{c, d}] && !UpupDndnIndexQ[{a, c}]
    mSign[_,  _,  _,  _]  :=  0

(* expr including a tensor wrt the same tensor. Place indices in delta at proper positions. *)
VD[t_[i1___], (t_?IndexedOperandQ)[i2___], rest_, ___Rule] :=
    With[{idxL = FlipIndex /@ {i1}},
        imposeSymmetry[Inner[combTwoIndices[#1, #2, t[i2]]&, idxL, {i2}, Times], idxL, getGenSetOf[t[i1]]] * rest
    ] /; Length[{i1}] === Length[{i2}]
VD[t_[i1___], (t_?IndexedOperandQ)[i2___], _,     ___Rule] := (
        Message[Msg::warn, "Different lengths of indices:", Length @ {i1}, "and", Length @ {i2}]; t[i2]
    ) /; Length[{i1}] =!= Length[{i2}]

    combTwoIndices[a_, b_,  _[___]]   := (
            Message[Msg::warn, "Different kinds of indices:", a, "and", b]; ErrorT[Kdelta][a, b]
        ) /; IndexToKind[a] =!= NonKind && IndexToKind[a] =!= IndexToKind[b]
    combTwoIndices[a_, b_,  _[___]]   := Kdelta[a, b] /; !UpupDndnIndexQ[{a,b}]
    combTwoIndices[a_, b_, t_[i2___]] := With [{kind = KindOf[t[i2], b]},
                                             If [MetricSpaceQ[kind],
                                                 GetMetric[kind],
                                             (* else *)
                                                 Message[Msg::warn, "No metric for", kind, "", ""]; ErrorT[Kdelta]
                                             ][a, b]
                                         ] /; UpupDndnIndexQ[{a,b}]
    combTwoIndices[a_, b_,  _[___]]   := Null[a, b]

    imposeSymmetry[expr_, idxL_List, gs_GenSet] :=
        With [{gr =  MakePermGroup[gs, Length @ idxL]},
            If [gr === {}, expr,
            (* else *)     Plus @@ (permuteIndices[expr, idxL, #]& /@ gr) / Length[gr]]
        ]

        permuteIndices[expr_, {},        _]     := expr
        permuteIndices[expr_, {_},       _]     := expr
        permuteIndices[expr_, idxL_List, perm_] := perm[[2]] * (expr /. Inner[Rule, idxL, PermuteList[idxL, perm], List])

(* a tensor wrt a different tensor *)
VD[t1_[___], (t2_?IndexedTensorQ)[___], _, opts___Rule] := 0 /; t1 =!= t2 && MemberQ[IndependentVD /. {opts} /. Options[VD], t2]

(* integration by parts *)
(* TODO: 경우에 따라서 total derivatives가 중요할 수도 있음. 옵션으로 그 항을 저장/출력 가능하게 코딩 *)
VD[t_, (pd_Symbol?IndexedOperatorQ)[ind_, expr_], rest_, opts___Rule] :=
    -VD[t, expr, pd[ind, rest], opts] /; (ByPartsVD /. {opts} /. Options[VD]) && MemberQ[BD /. {opts} /. Options[VD], pd]

(* simplification rules *)
VD[_, _, 0, ___Rule] := 0

(********************************************************************************)

initVariation[] := (
        (* VD *)
        defineOperator[VD, "\[Delta]", XP];
        reservedNameList = Join[reservedNameList, {VD}];

        (***** End of initVariation *****)
        reservedNameList = DeleteDuplicates[reservedNameList];
        loadedVariation = True;  (* guard reloding *)
    )
initVariation[]

(********************************************************************)

End[] (* End Private Context *)

EndPackage[]
