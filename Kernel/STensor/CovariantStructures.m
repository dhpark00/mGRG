(********************************************************************)
(********************** CovariantStructures.m ***********************)
(********************************************************************)

(********************************************************************)
BeginPackage["mGRG`STensor`", {"mGRG`mPerm`"}]

(********************************************************************)
Begin["`Private`"]

(*********** generic rules of linear derivative operators ***********)

derivativeRules[derD_Symbol, argCheck_:(True&)] := (
        (* update definedDerivativeList *)
        If [!MemberQ[definedDerivativeList, derD], AppendTo[definedDerivativeList, derD]];

        derD[arg_, expr_Plus]  := Map[derD[arg, #]&, expr] /; FreePatternQ[{arg, expr}] && argCheck[arg];  (* Linear *)
        derD[arg_, expr_Times] :=                                                                          (* Leibnitz rule *)
            With[{expd = ExpandObject[expr]},
                Switch [Head[expd],
                    Plus,  Map[derD[arg, #]&, expd],
                    Times, With[{rcL = Map[derD[arg, #]&, List @@ expd]},
                               Sum[ReplacePart[expd, i -> rcL[[i]]], {i, 1, Length[expd]}]
                           ],
                    _,     derD[arg, expd]
                ]
            ] /; FreePatternQ[{arg, expr}] && argCheck[arg];
        derD[arg_, c_?ConstantQ] := 0 /; FreePatternQ[{arg, c}] && argCheck[arg];                          (* Derivation *)

        (* derD[_, Kronecka Delta] --> 0 *)
        derD[arg_, Kdelta[a_, b_]] := 0 /; FreePatternQ[{arg, a, b}] && !UpupDndnIndexQ[{a, b}]  \
                                           && Switch [getType[derD],
                                                  CD, ValidIndicesQ[{arg, a, b}, KindOf[derD, arg]],
                                                  LD, If [derD === LD, vectorNameQ[arg] && ValidIndicesQ[{a, b}, KindOf[derD, arg]],
                                                      (* else *)       False],
                                                  _,  False
                                              ];  (* derD가 합당한 CD-type 연산자이거나 합당한 LD 연산자이면 True이고, 그렇지 않으면 False. *)

        (* Scalar functions *)
        derD[arg_, (sf_?ScalarFunctionQ)[expr_]] := sf'[expr] * derD[arg, DumFresh[expr]] /; sf =!= Tscalar;
        derD[arg_, Power[expr1_, expr2_]]        := DumFresh[expr2] * Power[expr1, expr2 - 1] * derD[arg, DumFresh[expr1]]  \
                                                    + Power[expr1, expr2] * Log[DumFresh[expr1]] * derD[arg, DumFresh[expr2]];
    )

(*********** Covariant Structure of the Kinds
	(* kind's properties *)
    MetricSpaceQ[kind]    = True | False
    constantMetricQ[kind] = False | True

    getDerOperators[kind] = {derOp,...}  <-- derivative operators
    GetEpsilon[kind]      = Epsilon or SymbolJoin[Epsilon, kind]
    GetMetric[kind]       = metric       <-- kind's unique metric
    GetStructuref[kind]   = Structuref or SymbolJoin[Structuref, kind]
    GetTorsion[kind]      = Torsion or SymbolJoin[Torsion, kind]

	(* derOp's properties *)
    TorsionFreeQ[derOp]      = True | False
    getDerOp[Gamma][derOp]   = SymbolJoin[Gamma,   derOp];
    getDerOp[Ricci][derOp]   = SymbolJoin[Ricci,   derOp];
    getDerOp[Riemann][derOp] = SymbolJoin[Riemann, derOp];
    getDerOp[Scalar][derOp]  = SymbolJoin[Scalar,  derOp];

	(* metric's properties *)
    MetricQ[metric]                  = True | False
    getCovDs[metric]                 = {torFreeCovD, torCovD}  <-- unique (up to torsion) metric-compatible covDs
    getMetricSymmetry[metric]        = +1  <-- symmetric only

    MetricCompatibleQ[derOp, metric] = True | False

	In 'DefaultKind', 'CD' is the covariant derivative compatible with the metric 'Metricg'.
 ***********)

(*********************** Derivative Operators ***********************)

(* is defined by DefDerivativeOperator? *)
DerivativeOperatorQ[opName_Symbol?IndexedOperatorQ] := MemberQ[getDerOperators[KindOf @ opName], opName]
DerivativeOperatorQ[___]                            := False

(* define a derivative operator *)
DefDerivativeOperator[derOp_Symbol,                             opts:OptionsPattern[]] := DefDerivativeOperator[derOp, ToString[derOp], DefaultKind, opts]
DefDerivativeOperator[derOp_Symbol, prtStr_String,              opts:OptionsPattern[]] := DefDerivativeOperator[derOp, prtStr,          DefaultKind, opts]
DefDerivativeOperator[derOp_Symbol,                kind_Symbol, opts:OptionsPattern[]] := DefDerivativeOperator[derOp, ToString[derOp], kind,        opts]
DefDerivativeOperator[derOp_Symbol, prtStr_String, kind_Symbol, opts:OptionsPattern[]] := (
        If [!checkName[derOp] || !CheckKind[kind], Return[$Failed]];

        defineDerOp[derOp, prtStr, kind, opts];
    )
DefDerivativeOperator[___] := Message[DefDerivativeOperator::usage]

UndefDerivativeOperator[derOp_Symbol?DerivativeOperatorQ] :=
    With[ {kind = KindOf[derOp]},
        (* protect CD *)
        If [MemberQ[reservedNameList, derOp], Message[Msg::err, "Reserved name", derOp, "cannot be removed!", ""]; Return[$Failed]];

		If [MetricSpaceQ[kind],
		    With[ {metric = GetMetric[kind]},
		        If [MetricCompatibleQ[derOp, metric],
        	       Message[Msg::warn, derOp, "was a member of metric-compatible derivatives of", metric, ""];
        	       ClearMetricCompatible[derOp, metric]
		        ]
		    ]
        ];

        (* update definedDerivativeList for Kdelta *)
        definedDerivativeList = DeleteCases[definedDerivativeList, derOp];

        (* update non-tensors *)
        nonTensorList = DeleteCases[nonTensorList, getDerOp[derOp, Gamma]];

        (* remove symbol-joined tensors *)
        removeObject @ getDerOp[Gamma]  [derOp];
        removeObject @ getDerOp[Riemann][derOp];
        removeObject @ getDerOp[Ricci]  [derOp];
        If [MetricSpaceQ[kind] && derOp =!= CD,
            removeObject @ getDerOp[Scalar][derOp]
        ];

        (* update kind's getDerOperators property *)
        getDerOperators[kind] = DeleteCases[getDerOperators[kind], derOp];

		(* remove derOp *)
        removeObject[derOp];
    ]
UndefDerivativeOperator[___] := Message[UndefDerivativeOperator::usage]

Options[defineDerOp] = {TorsionFreeQ -> True};

defineDerOp[derOp_Symbol, prtStr_String, kind_, OptionsPattern[]] :=
    With[ {oldKind = KindOf[derOp]},
        (* check the option *)
        If [!BooleanQ[OptionValue[TorsionFreeQ]], Message[Msg::err, OptionValue[TorsionFreeQ], "is not a Boolean!", "", ""]; Return[$Failed]];

        (* update oldKind's getDerOperators property *)
        If [oldKind =!= kind,
            If [derOp =!= CD && DerivativeOperatorQ[derOp],
                getDerOperators[oldKind] = DeleteCases[getDerOperators[oldKind], derOp];
            ]
        ];

        (* update kind's getDerOperators property *)
        getDerOperators[kind] = Union[getDerOperators[kind], {derOp}];

        (* define CD-type operator *)
        defineOperator[derOp, prtStr, CD, kind];
        TorsionFreeQ[derOp] = OptionValue[TorsionFreeQ];

        (* joined symbols *)
        getDerOp[Gamma]  [derOp] = SymbolJoin[Gamma,   derOp];
        getDerOp[Riemann][derOp] = SymbolJoin[Riemann, derOp];
        getDerOp[Ricci]  [derOp] = SymbolJoin[Ricci,   derOp];

        (* define indexed objects having the joined-names *)
        defineOperand[getDerOp[Gamma][derOp],
        	          If [CoordinateBasisQ[kind] && TorsionFreeQ[derOp], "+bac", "abc"],  (* symmetric or no-symmetry *)
        	          {kind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["\[CapitalGamma]", derOp]];
        Switch[MetricSpaceQ[kind],
            True,
                (* joined symbol: g^{ab} R_{ab} == R *)
                getDerOp[Scalar][derOp] = SymbolJoin[Scalar, derOp];
                defineOperand[getDerOp[Scalar][derOp], "", {kind}, {}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", derOp]];

                If [TorsionFreeQ[derOp],
                    defineOperand[getDerOp[Riemann][derOp], "-bacd-abdc+cdab", {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", derOp]];
                    defineOperand[getDerOp[Ricci][derOp],   "+ba",             {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", derOp]],  (* symmetric *)
                (* else *)
                    defineOperand[getDerOp[Riemann][derOp], "-bacd-abdc", {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", derOp]];
                    defineOperand[getDerOp[Ricci][derOp],   "ab",         {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", derOp]]  (* no symmetry *)
                ],
            False,
                defineOperand[getDerOp[Riemann][derOp], "-bacd", {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", derOp]];
                defineOperand[getDerOp[Ricci][derOp],   "ab",    {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", derOp]]  (* no symmetry *)
        ];

        (* update non-tensors *)
        nonTensorList = Union[nonTensorList, {getDerOp[Gamma][derOp]}];

        (* Rules for symbol-joined tensors *)
        With [{kkind = If [derOp === CD, DefaultKind, kind]},  (* delayed evaluation for the DefaultKind *)
            getDerOp[Riemann][derOp][a_, b_, c_, d_] :=  getDerOp[Ricci][derOp][b,d] /; FreePatternQ[{a, b, c, d}] && ValidIndicesQ[{a,b,c,d}, kkind] && PairIndexQ[a,c];
            getDerOp[Riemann][derOp][a_, b_, c_, d_] := -getDerOp[Ricci][derOp][b,c] /; FreePatternQ[{a, b, c, d}] && ValidIndicesQ[{a,b,c,d}, kkind] && PairIndexQ[a,d];
            getDerOp[Riemann][derOp][a_, b_, c_, d_] := -getDerOp[Ricci][derOp][a,d] /; FreePatternQ[{a, b, c, d}] && ValidIndicesQ[{a,b,c,d}, kkind] && PairIndexQ[b,c];
            getDerOp[Riemann][derOp][a_, b_, c_, d_] :=  getDerOp[Ricci][derOp][a,c] /; FreePatternQ[{a, b, c, d}] && ValidIndicesQ[{a,b,c,d}, kkind] && PairIndexQ[b,d];
            If [MetricSpaceQ[kkind],
                getDerOp[Ricci][derOp][a_, b_] := getDerOp[Scalar][derOp][] /; FreePatternQ[{a, b}] && ValidIndicesQ[{a,b}, kkind] && PairIndexQ[a,b];
            ]
        ];

        (* Rules for the derOp *)
        derivativeRules[derOp];
        derOp[opIndex_, moreIndices__, expr_] := Fold[derOp[#2, #1]&, expr, Reverse[{opIndex, moreIndices}]] /; FreePatternQ[{opIndex, moreIndices, expr}];
    ]

prtStrJoinDerOp[prtStr_String, CD]           := prtStr                                    (* predefined covariant derivative *)
prtStrJoinDerOp[prtStr_String, derOp_Symbol] := prtStr <> "[" <> getPrtStr[derOp] <> "]"  (* symbol-joining covariant derivative *)

(****************************** Metrics *****************************)

(* define a unique metric for each kind *)
DefMetric[metric_Symbol]                             := DefMetric[metric, ToString[metric], DefaultKind]
DefMetric[metric_Symbol, prtStr_String]              := DefMetric[metric, prtStr, DefaultKind]
DefMetric[metric_Symbol,                kind_Symbol] := DefMetric[metric, ToString[metric], kind]
DefMetric[metric_Symbol, prtStr_String, kind_Symbol] := (
        If [!checkName[metric] || !CheckKind[kind], Return[$Failed]];

        (* Protect Metricg *)
        If [flagTable[MetricgFlag] && kind === DefaultKind,
            Message[Msg::err, "Use On[MetricgFlag] or Off[MetricgFlag] to change the metric state of DefaultKind", kind, "", ""]; Return[$Failed]
        ];

        defineMetric[metric, prtStr, "+ba", kind, If [MetricSpaceQ[kind], GetMetric[kind], Null]];
    )
DefMetric[___] := Message[DefMetric::usage]

UndefMetric[metric_Symbol?MetricQ] :=
	With [{kind = KindOf[metric]},
        If [(metric =!= Metricg && MemberQ[reservedNameList, metric]) || (metric === Metricg && flagTable[MetricgFlag]),
            Message[Msg::err, "UndefMetric:", "Reserved name", metric, "cannot be removed!"]; Return[$Failed]
        ];

		(* un-set kind's properties related with the metric *)
		MetricSpaceQ[kind] = False;
        GetMetric[kind]    = Null;  (* Don't Unset *)

        (* See defineDerOp when MetricSpaceQ[kind] == False *) 
        With[{undefObj = (
                (* remove symbol-joined tensors *)
                If [!MemberQ[reservedNameList, #], removeObject @ getDerOp[Scalar][#]];

                defineOperand[getDerOp[Riemann][#], "-bacd", {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", #]];
                defineOperand[getDerOp[Ricci][#],   "ab",    {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", #]]
            )&},

            undefObj /@ getDerOperators[kind]
        ];

        (**** un-set properties of metric *****)

       	(* unlink from the metric-compatible covDs *)
		unsetMetricCompatible[#, metric, kind]& /@ getCovDs[metric];
		getCovDs[metric] = {};

		MetricQ[metric] = False;
        getMetricSymmetry[metric] =.;

        If [metric === Metricg,  (* if called from Off[MetricgFlag], *)
            ClearAll @ Metricg,  (* remove all values associated with Metricg *)
        (* else *)
            removeObject @ metric
        ];
   	]

(* See defineMetric for any other symbols *)
MetricSpaceQ[___] := False
MetricQ[___]      := False

defineMetric[metric_Symbol, prtStr_String, permS_String, kind_Symbol, oldg_:Null] := (
        (* check metric's rank *)
        If [toRankAndGenSet[permS][[1]] =!= 2, Message[Msg::err, metric, "is not a rank-2 tensor", "", ""]; Return[$Failed]];

        (* define metric as a tensor *)
        defineOperand[metric, permS, {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStr];
        If [!IndexedTensorQ[metric], Return[$Failed]];  (* errors in defineOperand *)

        If [oldg =!= Null && oldg =!= metric, Message[Msg::warn, oldg, "will be replaced with a new metric", metric, ""]];

        (* setup for MetricSpaceQ and GetMetric *)
        MetricSpaceQ[kind] = True;    (* kind's unique metric *)
        GetMetric[kind]    = metric;

        (**** setup properties of metric *****)

        (* setup metric symmetry *)
        getMetricSymmetry[metric] = +1;

        (* The kind of Metricg is always DefaultKind. Delayed evaluation of DefaultKind is required. *)
        (* g_a^{\ b} => delta_a^b and g^a_{\ b} => delta^a_b *)
       	metric[a_, b_] := Kdelta[a, b] /; flagTable[KdeltaFlag] && FreePatternQ[{a, b}] && AllTrue[{a, b}, TensorialIndexQ] \
           	                              && !UpupDndnIndexQ[{a, b}] && ValidIndicesQ[{a, b}, If [metric === Metricg, DefaultKind, kind]];

		MetricQ[metric]  = True;
		getCovDs[metric] = {};

        If [oldg === Null,  (* if there was NOT a previous metric *)
            (* See defineDerOp when MetricSpaceQ[kind] == True *)
            With[{defObj = (
                    getDerOp[Scalar][#] = SymbolJoin[Scalar, #];
                    defineOperand[getDerOp[Scalar][#], "", {kind}, {}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", #]];

                    If [TorsionFreeQ[#],
                        defineOperand[getDerOp[Riemann][#], "-bacd-abdc+cdab", {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", #]];
                        defineOperand[getDerOp[Ricci][#],   "+ba",             {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", #]],  (* symmetric *)
                    (* else *)
                        defineOperand[getDerOp[Riemann][#], "-bacd-abdc", {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", #]];
                        defineOperand[getDerOp[Ricci][#],   "ab",         {kind}, {-1}, IndexedTensorQ, PrintAs -> prtStrJoinDerOp["R", #]]  (* no symmetry *)
                    ];

                    getDerOp[Ricci][#][a_, b_] := getDerOp[Scalar][#][] /; FreePatternQ[{a, b}] && ValidIndexQ[{a,b}, kind] && PairIndexQ[a,b];
                )&},
                defObj /@ getDerOperators[kind]
            ] 
        ];
    )

metricSymmetry[metric_?MetricQ]    := getMetricSymmetry[metric]
metricSymmetry[kind_?MetricSpaceQ] := getMetricSymmetry[GetMetric[kind]]
metricSymmetry[___]                := +1  (* default *)

(*********************** Covariant Derivatives **********************)

(* Is cdName covariantly compatible with metric? *)  (* NB: 함수 정의의 순서 유지 필수 *)
(* NB: MetricCompatibleQ[cdName, idx, cOptL] 대신에 covariantNameQ[cdName, IndexToKind[idx], cOptL]을 사용해야 함. *)
MetricCompatibleQ[cdName_Symbol, metric_Symbol?MetricQ, cOptL_List:{}] := MemberQ[Join[If[cOptL =!= {}, cOptL[[1,2]], {}], getCovDs[metric]], cdName]
MetricCompatibleQ[cdName_Symbol,                        cOptL_List:{}] := covariantNameQ[cdName, KindOf[cdName], cOptL]
MetricCompatibleQ[cdName_Symbol, arg_,                  cOptL_List:{}] := covariantNameQ[cdName, KindOf[cdName, arg], cOptL] /; getType[cdName] == CD
MetricCompatibleQ[___] := False

SetMetricCompatible[BD,                        metric_?MetricQ] := setMetricCompatible[BD, metric, KindOf[metric]]
SetMetricCompatible[covD_?DerivativeOperatorQ, metric_?MetricQ] :=
	With [{kind = KindOf[metric]},
		If [!KindMatchQ[kind, KindOf[covD]],
		    Message[Msg::err, "Non-compatible kinds of", covD, "and", metric]; Return[$Failed]
		];

        setMetricCompatible[covD, metric, kind];
    ]
SetMetricCompatible[___] := Message[SetMetricCompatible::usage]

    setMetricCompatible[covD_, metric_, kind_] := (
        If [MetricCompatibleQ[covD, metric], Return[]];  (* covD is already metric-compatible with the metric. *)

        (* NB: (2025.09.27) When the metric is symmetric, the metric-compatible covDs should be unique, up to the torsion.
           (See Wald, Theorem 3.1.1 for a torsion-free derivative in coordinate basis.)
           When TorsionFreeQ[covD1] = True and TorsionFreeQ[covD2] = False, getCovDs[metric] === {covD1, covD2}
        If [Or @@ ((#[[2]] >= 2)& /@ Tally[TorsionFreeQ /@ getCovDs[metric]]),
            Message[Msg::err, "TorsionFreeQ of", covD, "is", TorsionFreeQ[covD], "and that type of a derivative is already included."];
            getCovDs[metric] = DeleteCases[getCovDs[metric], covD];
            Return[]
        ];
         *)

        getCovDs[metric] = Union[getCovDs[metric], {covD}];

        (* set metric and volume-form to be covariant constants of covD *)
        With [{volForm = GetEpsilon[kind]},
            covD[opIndex_, metric[a_, b_]]     := 0 /; FreePatternQ[{opIndex, a, b}] && AllTrue[{a, b}, TensorialIndexQ] && ValidIndicesQ[{opIndex, a, b}, kind];
            covD[opIndex_, volForm[indices__]] := 0 /; FreePatternQ[{opIndex, indices}]  \
                                                       && AllTrue[{indices}, TensorialIndexQ] && ValidIndicesQ[{opIndex, indices}, kind]  \
                                                       && (PositiveIntegerQ[GetDimension[kind]] && Length[{indices}] == GetDimension[kind])
        ];
    )

ClearMetricCompatible[BD,                        metric_?MetricQ] := clearMetricCompatible[BD,   metric, KindOf[metric]]
ClearMetricCompatible[covD_?DerivativeOperatorQ, metric_?MetricQ] := clearMetricCompatible[covD, metric, KindOf[metric]]
ClearMetricCompatible[___] := Message[ClearMetricCompatible::usage]

    clearMetricCompatible[covD_, metric_, kind_] := (
        If [!MetricCompatibleQ[covD, metric],
            Message[Msg::warn, covD, "is not a member of", metric, "-compatible derivatives."]; Return[]
        ];

        getCovDs[metric] = DeleteCases[getCovDs[metric], covD];
        unsetMetricCompatible[covD, metric, kind];
    )

covariantNameQ[opName_?IndexedOperatorQ, kind_, cOptL_] :=
    If [MetricSpaceQ[kind],
        MetricCompatibleQ[opName, GetMetric[kind], cOptL],
    (* else *)
        MemberQ[If [cOptL =!= {}, cOptL[[1,2]], {}], opName]  (* (2025.11.18) Absorb에서 옵션이 'CovDs -> {BD}'인 경우를 다룰 때 필요 *)
    ]

(* un-set metric and volume-form to be covariant constants of covD *)
unsetMetricCompatible[covD_, metric_, kind_] :=
    With [{volForm = GetEpsilon[kind]},
        covD[opIndex_, metric[a_, b_]]     =. /; FreePatternQ[{opIndex, a, b}] && AllTrue[{a, b}, TensorialIndexQ] && ValidIndicesQ[{opIndex, a, b}, kind];
        covD[opIndex_, volForm[indices__]] =. /; FreePatternQ[{opIndex, indices}]  \
                                                 && AllTrue[{indices}, TensorialIndexQ] && ValidIndicesQ[{opIndex, indices}, kind]  \
                                                 && (PositiveIntegerQ[GetDimension[kind]] && Length[{indices}] == GetDimension[kind]);
    ]

(**************************** DefaultKind ***************************)

(* alias *)
CoordinateBasisQ[] := CoordinateBasisQ[DefaultKind]

GetCoordinates[]   := GetCoordinates[DefaultKind]
ClearCoordinates[] := ClearCoordinates[DefaultKind]

GetDimension[]   := GetDimension[DefaultKind]
ClearDimension[] := ClearDimension[DefaultKind]

GetMetric[] := GetMetric[DefaultKind]
GetSig[]    := GetSig[DefaultKind]
ClearSig[]  := ClearSig[DefaultKind]

NewDummy[] := NewDummy[DefaultKind]

SetDefaultKind[kind_Symbol] := (
        If [kind =!= DefaultKind,  (* if changing the DefaultKind *)
            If [!CheckKind[kind], Return[$Failed]];

            (* NB: DiffForm 연산 도중에 DefaultKind를 변경하면 안됨. *)

            (* reset the rules for RiemannCD in previous DefaultKind. cf: defineDerOp *)
            Unset[RiemannCD[a_, b_, c_, d_]]; (* FreePatternQ[{a, b, c, d}] && ValidIndexQ[a, DefaultKind] && PairIndexQ[a,c]; *)
            Unset[RicciCD[a_, b_]];           (* FreePatternQ[{a, b}]       && ValidIndexQ[a, DefaultKind] && PairIndexQ[a,b]; *)

            (* CD, Metricg, Torsion, and Epsilon were in previous DefaultKind *)
            (* cf: UndefDerivativeOperator and UndefMetric *)
            If [MetricSpaceQ[DefaultKind],
                With [{metric = GetMetric[DefaultKind]},
                    If [MetricCompatibleQ[CD, metric], ClearMetricCompatible[CD, metric]];
                    If [metric === Metricg,
                        GetMetric[DefaultKind]    = Null;
                        MetricSpaceQ[DefaultKind] = False;
                    ]
                ]
            ];

            getDerOperators[DefaultKind] = DeleteCases[getDerOperators[DefaultKind], CD];  (* update kind's getDerOperators property *)

            defineOperand[SymbolJoin[Epsilon, DefaultKind], "*-",   {DefaultKind}, {-1},        IndexedTensorQ, PrintAs -> "\[Epsilon][" <> ToString[DefaultKind] <> "]"];
            defineOperand[SymbolJoin[Torsion, DefaultKind], "-bac", {DefaultKind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> "t["          <> ToString[DefaultKind] <> "]"];
            GetEpsilon[DefaultKind] = SymbolJoin[Epsilon, DefaultKind];
            GetTorsion[DefaultKind] = SymbolJoin[Torsion, DefaultKind];

            If [!CoordinateBasisQ[DefaultKind],
                defineOperand[SymbolJoin[Structuref, DefaultKind], "-bac", {DefaultKind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> "f"];
                GetStructuref[DefaultKind] = SymbolJoin[Structuref, DefaultKind],
            (* else *)
                GetStructuref[DefaultKind] = Null
            ];

            (* update DefaultKind *)
            Unprotect[DefaultKind];
            DefaultKind := kind;
            Protect[DefaultKind];
        ];

        (* CD, Metricg, Torsion, and Epsilon are always in DefaultKind *)
        defineOperand[Epsilon, "*-",   {kind}, {-1},        IndexedTensorQ, PrintAs -> "\[Epsilon]"];
        defineOperand[Torsion, "-bac", {kind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> "t"];
        GetEpsilon[kind] = Epsilon;
        GetTorsion[kind] = Torsion;

        defineDerOp[CD, "\[Del]", kind];
        If [flagTable[MetricgFlag],
            On[MetricgFlag],  (* side-effect: SetMetricCompatible[CD, Metricg] *)
        (* else *)
            Off[MetricgFlag]
        ];

        If [!CoordinateBasisQ[kind],
            defineOperand[Structuref, "-bac", {kind}, {-1, -1, 1}, IndexedTensorQ, PrintAs -> "f"];
            GetStructuref[kind] = Structuref,
        (* else *)
            GetStructuref[kind] = Null
        ];
    )
SetDefaultKind[___] := Message[SetDefaultKind::usage]

(****************** Predefined Tensorial Operators ******************)

(***** basis derivative *****)

BD[opIndex_, moreIndices__, expr_] := Fold[BD[#2, #1]&, expr, Reverse[{opIndex, moreIndices}]] /; FreePatternQ[{opIndex, moreIndices, expr}]

(* evaluate component expr if EvaluateBDFlag is On *)
BD[opIndex_?ComponentIndexQ, expr_] := bdComponentEval[opIndex, expr, DefaultKind]                                    \
    /; flagTable[EvaluateBDFlag[DefaultKind]] && FreePatternQ[{opIndex, expr}] && FreeObjectQ[expr]                   \
       && PositiveIntegerQ[GetDimension[DefaultKind]] && Abs[opIndex] <= GetDimension[DefaultKind]                    \
       && VectorQ[GetCoordinates[DefaultKind]]                                                                        \
       && ( CoordinateBasisQ[DefaultKind] || (!CoordinateBasisQ[DefaultKind] && MatrixQ[basisMatrix[DefaultKind]]) )  \
       && ( DnIndexQ[opIndex] || (UpIndexQ[opIndex] && MetricSpaceQ[DefaultKind]) )
BD[kind_Symbol][opIndex_?ComponentIndexQ, expr_] := bdComponentEval[opIndex, expr, kind]                            \
    /; DefinedKindQ[kind] && flagTable[EvaluateBDFlag[kind]] && FreePatternQ[{opIndex, expr}] && FreeObjectQ[expr]  \
       && PositiveIntegerQ[GetDimension[kind]] && Abs[opIndex] <= GetDimension[kind]                                \
       && VectorQ[GetCoordinates[kind]]                                                                             \
       && ( CoordinateBasisQ[kind] || (!CoordinateBasisQ[kind] && MatrixQ[basisMatrix[kind]]) )                     \
       && ( DnIndexQ[opIndex] || (UpIndexQ[opIndex] && MetricSpaceQ[kind]) )

BD[opIndex_Symbol, expr_] := bdComponentEval[-Position[GetCoordinates[DefaultKind], opIndex][[1,1]], expr, DefaultKind]  \
	/; flagTable[EvaluateBDFlag[DefaultKind]] && FreePatternQ[{opIndex, expr}] && FreeObjectQ[expr]                      \
       && VectorQ[GetCoordinates[DefaultKind]]                                                                           \
  	   && ( CoordinateBasisQ[DefaultKind] || (!CoordinateBasisQ[DefaultKind] && MatrixQ[basisMatrix[DefaultKind]]) )     \
	   && MemberQ[GetCoordinates[DefaultKind], opIndex]
BD[kind_Symbol][opIndex_Symbol, expr_] := bdComponentEval[-Position[GetCoordinates[kind], opIndex][[1,1]], expr, kind]  \
    /; DefinedKindQ[kind] && flagTable[EvaluateBDFlag[kind]] && FreePatternQ[{opIndex, expr}] && FreeObjectQ[expr]      \
       && VectorQ[GetCoordinates[kind]]                                                                                 \
       && ( CoordinateBasisQ[kind] || (!CoordinateBasisQ[kind] && MatrixQ[basisMatrix[kind]]) )                         \
       && MemberQ[GetCoordinates[kind], opIndex]

    bdComponentEval[opIndex_, expr_, kind_] :=
        If [DnIndexQ[opIndex],
            bdD[Abs[opIndex], expr, kind],
        (* else *)  (* V^a === g^{ab} V_b; V_a === g_{ab} V^b *)
            Sum[ GetMetric[kind][opIndex,m] bdD[m, expr, kind], {m, GetDimension[kind]} ]
    ]

bdD[a_, expr_]        := bdD[a, expr, DefaultKind]
bdD[a_, expr_, kind_] := (* basis derivative: D_a = h_a^mu \pd_mu *)
    If [CoordinateBasisQ[kind], D[expr, GetCoordinates[kind][[a]]],  (* ordinary derivative *)
    (* else *)                  Sum[basisMatrix[kind][[a,mu]] D[expr, GetCoordinates[kind][[mu]]], {mu, GetDimension[kind]}] ]

(***** Lie derivative *****)
LD[aV_, aV_[a_]] := 0 /; UpIndexQ[a] && TensorialIndexQ[a] && vectorNameQ[aV] && ValidIndexQ[a, KindOf @ aV]

(***************************** On / Off *****************************)

Unprotect[Off]  (* turn off a flag *)
Off[EvaluateBDFlag]        := (flagTable[EvaluateBDFlag[DefaultKind]] = False;)
Off[EvaluateBDFlag[kind_]] := (
        If [!CheckKind[kind], Return[$Failed]];

        flagTable[EvaluateBDFlag[kind]] = False;
    )
Off[KdeltaFlag]     := (flagTable[KdeltaFlag] = False;)
Off[MetricgFlag]    := (
        flagTable[MetricgFlag] = False;
        UndefMetric[Metricg];
    )
Protect[Off]

Unprotect[On]  (* turn on a flag *)
On[EvaluateBDFlag]        := (flagTable[EvaluateBDFlag[DefaultKind]] = True;)
On[EvaluateBDFlag[kind_]] := (
        If [!CheckKind[kind], Return[$Failed]];

        flagTable[EvaluateBDFlag[kind]] = True;
    )
On[KdeltaFlag]     := (flagTable[KdeltaFlag] = True;)
On[MetricgFlag]    := (
        flagTable[MetricgFlag] = True;
        defineMetric[Metricg, "g", "+ba", DefaultKind];  (* default symmetric metric *)
        SetMetricCompatible[CD, Metricg];
    )
Protect[On]

(************************** Absorb Kdelta ***************************)

(* Kdelta_a^b T_b or Kdelta^a_b T^b *)
Kdelta/: Kdelta[a_, b_] * (oName_?IndexedOperandQ)[pre___, c_, post___] :=
    oName[pre, a, post] /; flagTable[KdeltaFlag] && FreePatternQ[{a,b, oName, pre, c, post}]  \
                           && !UpupDndnIndexQ[{a, b}] && ValidIndicesQ[{a, b}, indexClass @ a] && PairIndexQ[b,c]
(* Kdelta_a^b T^a or Kdelta^a_b T_a *)
Kdelta/: Kdelta[a_, b_] * (oName_?IndexedOperandQ)[pre___, c_, post___] :=
    oName[pre, b, post] /; flagTable[KdeltaFlag] && FreePatternQ[{a,b, oName, pre, c, post}]  \
                           && !UpupDndnIndexQ[{a, b}] && ValidIndicesQ[{a, b}, indexClass @ a] && PairIndexQ[a,c]

(* Kdelta_a^b derOp[_b, T] *)
Kdelta/: Kdelta[a_, b_] * (opName_?IndexedOperatorQ)[c_, expr_] :=
    opName[a, expr] /; flagTable[KdeltaFlag] && FreePatternQ[{a, b, opName, c, expr}]  \
                       && !UpupDndnIndexQ[{a, b}] && ValidIndicesQ[{a, b}, indexClass @ a] && PairIndexQ[b, c]
(* Kdelta_a^b derOp[^a, T] *)
Kdelta/: Kdelta[a_, b_] * (opName_?IndexedOperatorQ)[c_, expr_] :=
    opName[b, expr] /; flagTable[KdeltaFlag] && FreePatternQ[{a, b, opName, c, expr}]  \
                       && !UpupDndnIndexQ[{a, b}] && ValidIndicesQ[{a, b}, indexClass @ a] && PairIndexQ[a, c]

(* Kdelta_a^b opName[c, T^a]. NB: opName[_, Kdelta] === 0 for all operators in definedDerivativeList. *)
Kdelta/: Kdelta[a_, b_] * (opName_?IndexedOperatorQ)[pre___, expr_, post___] := (
    opName[pre, Kdelta[a, b] * expr, post] ) /; flagTable[KdeltaFlag] && FreePatternQ[{a, b, opName, pre, expr, post}]                               \
                                              && !UpupDndnIndexQ[{a, b}] && covariantNameQ[opName, IndexToKind[a], {CovDs -> definedDerivativeList}] \
                                              && ValidIndicesQ[{a, b}, indexClass @ a] && absorbKdeltaQ[expr, a, b]

    absorbKdeltaQ[expr_, a_, b_] :=
        With[ {idxL = FindIndices[expr, IndexQs -> {TensorialIndexQ}]},
            MemberQ[idxL, FlipIndex @ a] || MemberQ[idxL, FlipIndex @ b]
        ]

(************************ Absorb and Absorbg ************************)

SetAttributes[Absorb, HoldAll]

(* NB: aMetric can be any symmetric rank-2 tensor. *)
Absorb[expr_, aMetric_Symbol?IndexedOperandQ, opts___Rule] :=
    With[ {hOptL = FilterRules[{opts}, HeadQs], cOptL = FilterRules[{opts}, CovDs], mKind = KindOf @ aMetric},
        (* aMetric should be a rank-2 tensor *)
        If [getRank[aMetric] =!= 2,
            Message[Msg::warn, aMetric, "is not a rank-2 tensor. It has rank", getRank @ aMetric, ""]; Return[expr]
        ];

        With[{mSym = Switch [GetSymmetry @ aMetric,  (* for a 'general' rank-2 tensor *)
                         GenSet[{Cycles[{{1,2}}],-1}], -1,
                         "Antisymmetric",              -1,
                         GenSet[{Cycles[{{1,2}}], 1}],  1,
                         "Symmetric",                   1,
                         _,                             0
                     ]},

            (* aMetric should be symmetric *)
            If [mSym =!= +1, Message[Msg::warn, aMetric, "should be symmetric.", "", ""]; Return[expr]];

            (* aMetric should satisfy HeadQs option *)
            If [hOptL =!= {} && !AllQoptions[HeadQs][aMetric, hOptL],
                Message[Msg::warn, aMetric, "does not satisfy the option", HeadQs /. hOptL, ""]; Return[expr]
            ];

            (* check covariant-derivative option *)
            If [cOptL =!= {} && !AllTrue[CovDs /. cOptL, IndexedOperatorQ],
                Message[Msg::err, "not defined operator(s)", CovDs /. cOptL, "", ""]; Return[expr]
            ];

            absorb[expr, aMetric, mKind, mSym, FilterRules[{opts}, IndexQs], hOptL, cOptL]
        ]
    ]
Absorb[___] := Absorb::usage

Absorbg[expr_, opts___Rule] := Absorb[expr, Metricg, opts]
Absorbg[___]                := Absorbg::usage

absorb[expr_, aMetric_, mKind_, mSym_, iOptL_List, hOptL_List, cOptL_List] :=
    ExpandObject[expr, Sequence @@ hOptL] //. absorbRuleWith[aMetric, mKind, mSym, iOptL, hOptL, cOptL]

    (* mSym = +1 only *)
    absorbRuleWith[aMetric_, mKind_, mSym_, iOptL_List, hOptL_List, cOptL_List] := {
        (* 1. No operators or inside of scalarFunction: g_{ab} T^b or Tscalar[g_{ab} R^{ab}]^2 *)
        (* g_{ab} T^b *)
        aMetric[a_, b_] * (tName_?IndexedOperandQ)[pre___, c_, post___] :>
            tName[pre, a, post] /; AllQoptions[HeadQs][tName, hOptL] && ValidIndicesQ[{a, b}, mKind]  \
                                    && pairQabsorb[tName[pre, c, post], {b,c}, mKind, iOptL],

        (* g_{ba} T^b *)
        aMetric[a_, b_] * (tName_?IndexedOperandQ)[pre___, c_, post___] :>
            mSym * tName[pre, b, post] /; AllQoptions[HeadQs][tName, hOptL] && ValidIndicesQ[{a, b}, mKind]  \
                                          && pairQabsorb[tName[pre, c, post], {a,c}, mKind, iOptL],

        (* 2. Matching with the index of CD-type operator: g_{ab} \pd^b T *)
        (* g_{ab} \pd^b T *)
        aMetric[a_, b_] * (opName_?IndexedOperatorQ)[c_, expr_] :>
            opName[a, expr] /; AllQoptions[HeadQs][opName, hOptL] && ValidIndicesQ[{a, b}, mKind]  \
                               && KindMatchQ[mKind, KindOf[opName, c]] && pairQabsorb[opName, {b,c}, iOptL],

        (* g_{ba} \pd^b T *)
        aMetric[a_, b_] * (opName_?IndexedOperatorQ)[c_, expr_] :>
            mSym * opName[b, expr] /; AllQoptions[HeadQs][opName, hOptL] && ValidIndicesQ[{a, b}, mKind]  \
                                      && KindMatchQ[mKind, KindOf[opName, c]] && pairQabsorb[opName, {a,c}, iOptL],

        (* 3. Not matching with the CD-type operators: *)
        (* g_{ab} CD[lc, T] --> CD[lc, g_{ab} T] *)
        aMetric[a_, b_] * (opName_?IndexedOperatorQ)[c_, expr_, post___] :>
            opName[c, aMetric[a, b] * expr //. absorbRuleWith[aMetric, mKind, mSym, iOptL, hOptL, cOptL], post]          \
            /; UpupDndnIndexQ[{a, b}] && ValidIndicesQ[{a, b}, mKind] && KindMatchQ[mKind, KindOf[opName, c]]            \
               && MetricCompatibleQ[opName, aMetric, cOptL] && ValidIndexQ[c, mKind] && AllQoptions[HeadQs][opName, hOptL]  \
               && absorbQ[expr, {a, b}, mKind, iOptL, hOptL, cOptL]
    }

    (* is raising or lowering possible *)
    (* g_{ab} T^b or g_{ab} T^a *)
    absorbQ[(tName_?IndexedOperandQ)[args__], {a_, b_}, mKind_, iOptL_, hOptL_, _] :=
        If [   (Or @@ (pairQabsorb[tName[args], {b, #}, mKind, iOptL]& /@ {args}))  \
            || (Or @@ (pairQabsorb[tName[args], {a, #}, mKind, iOptL]& /@ {args})),
            True,
        (* else *)
            False
        ] /; AllQoptions[HeadQs][tName, hOptL]

    (* g_{ab} \pd^b T or g_{ab} \pd^a T *)
    absorbQ[(opName_?IndexedOperatorQ)[c_, _], {a_, b_}, mKind_, iOptL_, hOptL_, _] :=
        True /; AllQoptions[HeadQs][opName, hOptL] && KindMatchQ[mKind, KindOf[opName, c]]      \
                && (pairQabsorb[opName, {b, c}, iOptL] || (pairQabsorb[opName, {a, c}, iOptL]))

    (* g_{ab} \pd_c T *)
    absorbQ[(opName_?IndexedOperatorQ)[arg_, __], {_, _}, mKind_, _, hOptL_, cOptL_] :=
        False /; !AllQoptions[HeadQs][opName, hOptL] || !MetricCompatibleQ[opName, GetMetric[mKind], cOptL] || !KindMatchQ[mKind, KindOf[opName, arg]]

    (* g_{ab} CD[lc, T] *)
    absorbQ[(opName_?IndexedOperatorQ)[arg_, expr__], {a_, b_}, mKind_, iOptL_, hOptL_, cOptL_] :=
        absorbQ[expr, {a, b}, mKind, iOptL, hOptL, cOptL] /; AllQoptions[HeadQs][opName, hOptL] && KindMatchQ[mKind, KindOf[opName, arg]]  \
                                                             && getType[opName] === CD && MetricCompatibleQ[opName, GetMetric[mKind], cOptL]

    (* g_{ab} d(T^b) *)
    absorbQ[(opName_?IndexedOperatorQ)[expr_], {a_, b_}, mKind_, iOptL_, hOptL_, cOptL_] :=
        absorbQ[expr, {a, b}, mKind, iOptL, hOptL, cOptL] /; AllQoptions[HeadQs][opName, hOptL] && KindMatchQ[mKind, KindOf[opName, expr]]  \
                                                             && getType[opName] === XD && MetricCompatibleQ[opName, GetMetric[mKind], cOptL]

    (* g_{ab} XP[..., T^b, ...] *)
    absorbQ[(opName_?IndexedOperatorQ)[pre___, expr_, ___], {a_, b_}, mKind_, iOptL_, hOptL_, cOptL_] :=
        absorbQ[expr, {a, b}, mKind, iOptL, hOptL, cOptL] /; AllQoptions[HeadQs][opName, hOptL] && KindMatchQ[mKind, KindOf[opName, pre, expr]]  \
                                                             && getType[opName] === XP && MetricCompatibleQ[opName, GetMetric[mKind], cOptL]

    absorbQ[___] := False

        (* g^{ab} R_{ab} -> R_a^a and g^{ab} \pd_b -> \pd^a *)
        pairQabsorb[(tName_?IndexedOperandQ)[indices___], {a_, b_?TensorialIndexQ}, mKind_, iOptL_] := KindMatchQ[mKind, KindOf[tName[indices], b]]  \
                                                                                                       && pairQabsorbAux[{a, b}, iOptL]
        pairQabsorb[opName_?IndexedOperatorQ,             {a_, b_?TensorialIndexQ},         iOptL_] := pairQabsorbAux[{a, b}, iOptL] && (getType[opName] === CD)
        pairQabsorb[___]                                                                            := False

            pairQabsorbAux[{a_, b_}, iOptL_] := PairIndexQ[a, b] && (And @@ Map[AllQoptions[IndexQs][#, iOptL]&, {a, b}])


(****************** PutMetric and PullOutMetric *********************)

PutMetric[expr_, idx_?TensorialIndexQ, opts___Rule] := (
        (* Free 인덱스에 대해서만 적용하게 하려면 주석 제거:
        If [!MemberQ[FindFreeTensorialIndices[expr, opts], idx], Message[Msg::err, idx, "is not a free index!", "", ""]; Return[$Failed]];
        *)

        With[{kind = IndexToKind[idx]},
            If [MetricSpaceQ[kind],
                ForEachObject[expr, FilterRules[{opts}, HeadQs], putMetricObject, idx, kind, GetMetric[kind], opts],
            (* else *)
                expr
            ]
        ]
    )
PutMetric[___] := PutMetric::usage

    putMetricObject[(oName_?IndexedOperandQ)[indices__], idx_, kind_, metric_, ___] :=
        With[{indexL = {indices}},
            If [MemberQ[indexL, idx] && KindMatchQ[kind, KindOf[oName[indices], idx]],
                With[{pos = Position[indexL, idx][[1,1]], pair = NewDummy[kind]},
                    If [DnIndexQ[idx], metric[idx, pair[[1]]] * (oName @@ ReplacePart[indexL, pos -> pair[[2]]]),
                    (* else *)         metric[idx, pair[[2]]] * (oName @@ ReplacePart[indexL, pos -> pair[[1]]])]
                ],
            (* else *)
                oName[indices]
            ]
        ]
    putMetricObject[(opName_?IndexedOperatorQ)[arg_, expr___], idx_, kind_, metric_, opts___] :=
        Switch [getType[opName],
            CD, If [arg === idx,
                    With[ {pair = NewDummy[kind]},
                        If [DnIndexQ[idx], metric[idx, pair[[1]]] * opName[pair[[2]], expr],
                        (* else *)         metric[idx, pair[[2]]] * opName[pair[[1]], expr]]
                    ],
                (* else *)
                    opName[arg, putMetricObject[expr, idx, kind, metric, opts]]
                ],
            LD, If [MemberQ[FindIndicesAll[expr, opts], idx] && FreeQ[expr, BD | Alternatives @@ nonTensorList],
                    opName[arg, putMetricObject[expr, idx, kind, metric, opts]],
                (* else *)
                    opName[arg, expr]
                ],
            XD, opName[putMetricObject[arg, idx, kind, metric, opts], expr],  (* XD-type 연산자의 두 번째 인자 이상은 의미 없으므로 '첫 번째' 인자에만 적용.  *)
            XP, opName[Sequence @@ (putMetricObject[#, idx, kind, metric, opts]& /@ {arg, expr})]
        ]
    putMetricObject[obj_, _, _, _, ___] := obj

(***** PullOutMetric *****)

PullOutMetric[expr_, opts___Rule] := ForEachObject[expr, FilterRules[{opts}, HeadQs], pullOutMetricObject, opts]
PullOutMetric[___] := PullOutMetric::usage

    pullOutMetricObject[(oName_?IndexedOperandQ)[indices__], ___] :=
        With[{indexL = {indices}},
            With[{dnupL = DnupAt[oName, #]& /@ Range[Length @ indexL]},
                With[{doF = If [dnupL[[#2]] =!= dnupState[#1[[2,#2]]],
                                With[{kind = IndexToKind @ #1[[2,#2]]},
                                    If [MetricSpaceQ[kind],
                                        With[{pair = NewDummy[kind]},
                                            If [DnIndexQ[#1[[2,#2]]],
                                                {#1[[1]] * GetMetric[kind][#1[[2,#2]], pair[[1]]], ReplacePart[#1[[2]], #2 -> pair[[2]]]},
                                            (* else *)
                                                {#1[[1]] * GetMetric[kind][#1[[2,#2]], pair[[2]]], ReplacePart[#1[[2]], #2 -> pair[[1]]]}
                                            ]
                                        ],
                                    (* else *)
                                        #1
                                    ]
                                ],
                            (* else *)
                                #1
                            ]&},

                    With[{rc = Fold[doF, {1, indexL}, Range[Length @ indexL]]},
                        rc[[1]] * oName[Sequence @@ rc[[2]]]
                    ]
                ]
            ]
        ]

    pullOutMetricObject[(opName_?IndexedOperatorQ)[arg_, expr___], ___] :=
        Switch [getType[opName],
            CD, If [UpIndexQ[arg],
                    With[{kind = If [opName === BD, IndexToKind[arg], KindOf[opName, arg]]},
                        If [MetricSpaceQ[kind],
                            With[{pair = NewDummy[kind]},
                                GetMetric[kind][arg, pair[[2]]] * opName[pair[[1]], pullOutMetricObject @ expr]
                            ],
                        (* else *)
                            opName[arg, pullOutMetricObject @ expr]
                        ]
                    ],
                (* else *)
                    opName[arg, pullOutMetricObject @ expr]
                ],
            LD, opName[arg, pullOutMetricObject @ expr],
            XD, opName[pullOutMetricObject @ arg, expr],
            XP, opName[Sequence @@ (pullOutMetricObject /@ {arg, expr})]
        ]
    pullOutMetricObject[obj_, ___] := obj

(*************** ************* DualStar *****************************)

DualStar[expr_]                  := DualStar[expr, {}, DefaultKind]
DualStar[expr_, {}]              := DualStar[expr, {}, DefaultKind]
DualStar[expr_,     kind_Symbol] := DualStar[expr, {}, kind]
DualStar[expr_, {}, kind_Symbol] := dualStar[Dum @ expr, {}, kind]

DualStar[expr_, indexL:{(_Symbol | _String | _Integer)..}]              := DualStar[expr, indexL, IndexToKind @ indexL[[1]]]
DualStar[expr_, indexL:{(_Symbol | _String | _Integer)..}, kind_Symbol] := dualStar[Dum @ expr, indexL, kind] /; DeleteDuplicates[IndexToKind /@ indexL] === {kind}
DualStar[___] := DualStar::usage

    dualStar[expr_, indexL_List, kind_Symbol] :=
        With[{tmpTerm = If [Head[expr] === Plus, expr[[1]], expr], nDim = GetDimension[kind]},
            (* $FormDropIndices -> True for non-zero rank diff. forms *)
            With[{freeL = Select[FindFreeTensorialIndicesAll[tmpTerm, IndexQs -> {KindIndexQ[kind]}, $FormDropIndices -> True],
                                 (DnIndexQ[#] || UpIndexQ[#])&]},
                If [PositiveIntegerQ[nDim] && Length[freeL] > nDim,
                    Message[Msg::err, "Invalid numbers of free indices: ", freeL, "", ""]; Return[$Failed]
                ];

                If [Intersection[Join[freeL, FlipIndex /@ freeL], indexL] =!= {},
                    Message[Msg::err, "ill-formed indices: ", indexL, "", ""]; Return[$Failed]
                ];

                (* epsIndexL은 expr의 <free 인덱스>로부터 유추하여 얻은 인덱스와 사용자가 입력한 indexL의 합이다. *)
                With[{epsIndexL = Join[FlipIndex /@ freeL, indexL], eps = GetEpsilon[kind]},
                    If [Length[epsIndexL] < 2 || (PositiveIntegerQ[nDim] && Length[epsIndexL] =!= nDim),
                        Message[Msg::err, "Invalid numbers of indices: ", indexL, "", ""]; Return[$Failed]
                    ];

                    (1/Length[freeL]!) * expr * eps[Sequence @@ epsIndexL]
                ]
            ]
        ]

(********************************************************************)
End[] (* End Private Context *)
EndPackage[]
