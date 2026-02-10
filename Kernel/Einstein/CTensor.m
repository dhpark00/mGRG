(********************************************************************)
(**************************** CTensor.m *****************************)
(********************************************************************)

(********************************************************************)
BeginPackage["mGRG`Einstein`", {"mGRG`STensor`", "mGRG`mPerm`"}]

(********************************************************************)
Begin["`Private`"]

(************ Default of Exported Functions and Variables ***********)

Csimplify[expr_] := Together[ expr /. CsimplifyRules ] /. CsimplifyRules
CsimplifyMore[expr_, assump_:(True&)] := Simplify[ expr /. CsimplifyRules, assump ] /. CsimplifyRules

CsimplifyRules = {}
MetricPath     = "mGRG`Einstein`Metrics`"

(************************ Set/ClearCTensor **************************)

SetCTensor = InitCTensor  (* alias *)

InitCTensor[coSys_ /; VectorQ[coSys, AtomQ], metric_?SquareMatrixQ,                       opts:OptionsPattern[]] := initCTensor[coSys, metric, False, opts] (* coordinate basis *)
InitCTensor[coSys_ /; VectorQ[coSys, AtomQ], metric_?SquareMatrixQ, basis_?SquareMatrixQ, opts:OptionsPattern[]] := initCTensor[coSys, metric, basis, opts] (* non-coordinate basis *)
InitCTensor[fileName_String] := Get[MetricPath <> fileName <> "`"];
InitCTensor[___] := Message[InitCTensor::usage]

    Options[initCTensor] = {SimplifyMore -> False, Verbose -> False, GammaCD -> False, RicciCD -> False, RiemannCD -> False, InitCTensor -> False, FourDimensionQ -> True}

	initCTensor[coSys_, metric_, basis_, opts:OptionsPattern[]] := (
            If [mGRG`STensor`Private`flagTable[InitCTensorFlag] && OptionValue[InitCTensor] == False,
                Message[Msg::warn, "CTensor is already initialized.", "Use InitCTensor -> True option if you want to re-initialize CTensor, or ClearCTensor[] to clear CTensor.", "", ""]; Return[]
            ];

            If [!TorsionFreeQ[CD], Message[Msg::err, "CTensor requires a torsion-free connection.", "", "", ""]; Return[$Failed]];
        	If [basis === False && !(Length[coSys] === Length[metric[[1]]]),  (* coordinate basis *)
       			Message[Msg::err, "incompatible number of elements in coSys and metric", "", "", ""]; Return[$Failed]
       		];
        	If [basis =!= False && !(Length[coSys] === Length[metric[[1]]] === Length[basis[[1]]]),  (* non-coordinate basis *)
       			Message[Msg::err, "incompatible number of elements between coSys, metric, and basis", "", "", ""]; Return[$Failed]
       		];

            nDimension = Length[coSys];
            If [OptionValue[FourDimensionQ] && nDimension =!= 4,
                Message[Msg::err, "It is assumed a four-dimensional spacetime.", "But the number of coordinates is not four!", "Use FourDimensionQ -> False option ", ""];
                Return[$Failed]
            ];

            With[{startTime = TimeUsed[]},
                (* 1: parse options *)
                defaultCTensor[simpMethod] = If [OptionValue[SimplifyMore], CsimplifyMore, Csimplify];
                defaultCTensor[Verbose]    = OptionValue[Verbose];

                (* 2: setup environment *)
                mGRG`STensor`Private`flagTable[InitCTensorFlag]             = True;
                mGRG`STensor`Private`flagTable[EvaluateBDFlag[DefaultKind]] = True;

                If [basis === False,
                    On[CoordinateBasisFlag];
                    mGRG`STensor`Private`basisMatrix[DefaultKind] = IdentityMatrix[nDimension];
                    inverseBasisMatrix       = IdentityMatrix[nDimension],
                (* else *)
                    Off[CoordinateBasisFlag];
                    mGRG`STensor`Private`basisMatrix[DefaultKind] = basis;  (* basis matrix: \xi_a = h_a^{\mu} \pd_{\mu} *)
                    inverseBasisMatrix       = Inverse[basis] // CsimplifyMore
                ];

                (* metric, coordinates, and dimension *)
                cMetric = metric; mGRG`STensor`Private`tableToComponents[Metricg, 2, {-1, -1}, cMetric];
                GetCoordinates[DefaultKind] = coSys;
                SetDimension[nDimension];

                (* 3: trigger initial calculations based on options *)
                With[{calcGammaQ   = OptionValue[GammaCD],
                      calcRicciQ   = OptionValue[RicciCD],
                      calcRiemannQ = OptionValue[RiemannCD]},

                    (* initialize calc table *)
                    cTensorTable[Structuref] = False;
                    cTensorTable[cInvMetric] = False;
                    cTensorTable[bdMetric]   = False;
                    cTensorTable[GammaCD]    = False;
                    cTensorTable[RiemannCD]  = False;
                    cTensorTable[RicciCD]    = False;
                    cTensorTable[ScalarCD]   = False;
                    cTensorTable[WeylCD]     = False;

                    Tcalc[Structuref];
                    If [calcRicciQ || calcRiemannQ,
                        Tcalc[RiemannCD];
                        If [calcRicciQ, Tcalc[RicciCD]; Tcalc[ScalarCD]],
                    (* else *)
                        If [calcGammaQ, Tcalc[GammaCD]]
                    ];

                    If [defaultCTensor[Verbose], Print["Total setup time: ", Round[TimeUsed[] - startTime, 0.01], "s"]]
                ]
            ]
        )

ClearCTensor[] :=
    If [mGRG`STensor`Private`flagTable[InitCTensorFlag],
        If [cTensorTable[cInvMetric],
            mGRG`STensor`Private`clearComponents[Metricg, 2, {nDimension, nDimension}, {1,1}];
            cTensorTable[cInvMetric] = False
        ];
        If [cTensorTable[bdMetric], Clear[bdMetric]; cTensorTable[bdMetric] = False];

        If [cTensorTable[Structuref],
            mGRG`STensor`Private`clearComponents[Structuref, 3, {nDimension, nDimension, nDimension}, {-1,-1,-1}];
            mGRG`STensor`Private`clearComponents[Structuref, 3, {nDimension, nDimension, nDimension}, {-1,-1, 1}];
            cTensorTable[Structuref] = False
        ];

        If [cTensorTable[GammaCD],
            mGRG`STensor`Private`clearComponents[GammaCD, 3, {nDimension, nDimension, nDimension}, {-1,-1,-1}];
            mGRG`STensor`Private`clearComponents[GammaCD, 3, {nDimension, nDimension, nDimension}, {-1,-1, 1}];
            cTensorTable[GammaCD] = False
        ];

        If [cTensorTable[RicciCD],
            mGRG`STensor`Private`clearComponents[RicciCD, 2, {nDimension, nDimension}, {-1,-1}];
            cTensorTable[RicciCD] = False
        ];
        If [cTensorTable[RiemannCD],
            mGRG`STensor`Private`clearComponents[RiemannCD, 4, {nDimension, nDimension, nDimension, nDimension}, {-1,-1,-1,-1}];
            cTensorTable[RiemannCD] = False
        ];
        If [cTensorTable[ScalarCD], ScalarCD[] =.; cTensorTable[ScalarCD] = False];
        If [cTensorTable[WeylCD],
            mGRG`STensor`Private`clearComponents[WeylCD, 4, {nDimension, nDimension, nDimension, nDimension}, {-1,-1,-1,-1}];
            cTensorTable[WeylCD] = False
        ];

        inverseBasisMatrix =.;
        mGRG`STensor`Private`basisMatrix[DefaultKind] =.;
        mGRG`STensor`Private`clearComponents[Metricg, 2, {nDimension, nDimension}, {-1,-1}];

        ClearDimension[];
        GetCoordinates[DefaultKind] =.;
        cMetric =.;

        mGRG`STensor`Private`flagTable[InitCTensorFlag]             = False;
        mGRG`STensor`Private`flagTable[EvaluateBDFlag[DefaultKind]] = False;  (* initSTensor's default *)

        nDimension =.;
        defaultCTensor[Verbose] =.;
        defaultCTensor[simpMethod] =.;
    ]

(***************************** Tcalc ********************************)

SetAttributes[Tcalc, HoldFirst]

(* GammaCD[la,lb,lc] and GammaCD[la,lb,uc] *)
Tcalc[GammaCD, simpCmd_:defaultCTensor[simpMethod]] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] := (
        If [!cTensorTable[cInvMetric], calcInvMetric[simpCmd]];
        If [!cTensorTable[bdMetric],   calcBdMetric[simpCmd]];

        (* GammaCD[la,lb,lc] *)
        With[{startTime = TimeUsed[]},
            If [CoordinateBasisQ[],  (* symmetric: la <-> lb *)
                Table[ GammaCD[-a,-b,-c] = ( bdMetric[[a,b,c]] + bdMetric[[b,a,c]] - bdMetric[[c,a,b]] ) / 2 // simpCmd,
                       {a, nDimension}, {b, a, nDimension}, {c, nDimension} ];
                Table[ GammaCD[-a,-b,-c] = GammaCD[-b,-a,-c], {a, 2, nDimension}, {b, 1, a - 1}, {c, nDimension} ],
            (* else *)  (* non-coordinate basis *)
                If [!cTensorTable[Structuref], Tcalc[Structuref, simpCmd]];

                mGRG`STensor`Private`tableToComponents[GammaCD, 3, {-1,-1,-1},
                                                       Table[ bdMetric[[a,b,c]] + bdMetric[[b,a,c]] - bdMetric[[c,a,b]]  \
                                                       + Structuref[-a,-b,-c] + Structuref[-c,-a,-b] + Structuref[-c,-b,-a],
                                                       {a, nDimension}, {b, nDimension}, {c, nDimension} ] / 2 // simpCmd]
            ];
            With[{elapsedTime = Round[TimeUsed[] - startTime, 0.01]},
                If [defaultCTensor[Verbose],
                    Print["Calculated ", Subscript["\[CapitalGamma]", "abc"], " using ", simpCmd, " in ", elapsedTime, "s"]
                ]
            ]
        ];

        (* GammaCD[la,lb,uc] *)
        With[{startTime = TimeUsed[]},
            If [CoordinateBasisQ[],  (* symmetric: la <-> lb *)
                Table[ GammaCD[-a,-b,c] = Sum[GammaCD[-a,-b,-m] Metricg[c,m], {m, nDimension} ] // simpCmd,
                       {a, nDimension}, {b, a, nDimension}, {c, nDimension} ];
                Table[ GammaCD[-a,-b,c] = GammaCD[-b,-a,c], {a, 2, nDimension}, {b, 1, a - 1}, {c, nDimension} ],
            (* else *)
                mGRG`STensor`Private`tableToComponents[GammaCD, 3, {-1,-1,1},
                                                       Table[ Sum[GammaCD[-a,-b,-m] Metricg[c,m], {m, nDimension} ],
                                                       {a, nDimension}, {b, nDimension}, {c, nDimension} ] // simpCmd]
            ];
            With[{elapsedTime = Round[TimeUsed[] - startTime, 0.01]},
                If [defaultCTensor[Verbose],
                    Print["Calculated ", Subsuperscript["\[CapitalGamma]", "ab", "  c"], " using ", simpCmd, " in ", elapsedTime, "s"]
                ]
            ]
        ];
        cTensorTable[GammaCD] = True;
    )

(* RicciCD[la,lb] *)
Tcalc[RicciCD, simpCmd_:defaultCTensor[simpMethod]] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] := (
        If [!cTensorTable[cInvMetric], calcInvMetric[simpCmd]];
        If [!cTensorTable[RiemannCD],  Tcalc[RiemannCD, simpCmd]];

        With[{startTime = TimeUsed[]},
            Table[ RicciCD[-a,-b] = Sum[ Metricg[c,d] RiemannCD[-a,-c,-b,-d], {c, nDimension}, {d, nDimension} ] // simpCmd,
                   {a, nDimension}, {b, a, nDimension}];
            Table[ RicciCD[-a,-b] = RicciCD[-b,-a],  {a, 2, nDimension}, {b, 1, a - 1}];  (* symmetric: la <-> lb *)

            With[{elapsedTime = Round[TimeUsed[] - startTime, 0.01]},
                If [defaultCTensor[Verbose],
                    Print["Calculated ", Subscript["R", "ab"], " using ", simpCmd, " in ", elapsedTime, "s"]
                ]
            ]
        ];
        cTensorTable[RicciCD] = True;
    )

(* RiemannCD[la,lb,lc,ld] *)
Tcalc[RiemannCD, simpCmd_:defaultCTensor[simpMethod]] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] := (
        If [!cTensorTable[bdMetric], calcBdMetric[simpCmd]];
        If [!cTensorTable[GammaCD],  Tcalc[GammaCD, simpCmd]];

        With[{startTime = TimeUsed[]},
            Table[ RiemannCD[-a,-a,-b,-c] = 0, {a, nDimension}, {b, nDimension}, {c, nDimension} ];  (* anti-symmetric *)
            Table[ RiemannCD[-b,-c,-a,-a] = 0, {a, nDimension}, {b, nDimension}, {c, nDimension} ];  (* anti-symmetric *)

            If [CoordinateBasisQ[],
                Table[
                    RiemannCD[-a,-b,-c,-d] = (mGRG`STensor`Private`riemannSign) * (
                                             mGRG`STensor`Private`bdD[a, bdMetric[[c,b,d]] - bdMetric[[d,b,c]]] / 2    \
                                             - mGRG`STensor`Private`bdD[b, bdMetric[[c,a,d]] - bdMetric[[d,a,c]]] / 2  \
                                             + Sum[ GammaCD[-a,-c,-m] GammaCD[-b,-d,m] - GammaCD[-b,-c,-m] GammaCD[-a,-d,m], {m, nDimension} ]) // simpCmd,
                    {a, nDimension}, {b, a + 1, nDimension}, {c, a, nDimension}, {d, c + 1, nDimension}
                ],
            (* else *)
                Table[
                    RiemannCD[-a,-b,-c,-d] = (mGRG`STensor`Private`riemannSign) * (
                                             Sum[ Metricg[-d,-m] (mGRG`STensor`Private`bdD[a, GammaCD[-b,-c,m]]         \
                                                                  - mGRG`STensor`Private`bdD[b, GammaCD[-a,-c,m]])      \
                                             + GammaCD[-a,-m,-d] GammaCD[-b,-c,m] - GammaCD[-b,-m,-d] GammaCD[-a,-c,m]  \
                                             - Structuref[-a,-b,m] GammaCD[-m,-c,-d], {m, nDimension} ]) // simpCmd,
                    {a, nDimension}, {b, a + 1, nDimension}, {c, a, nDimension}, {d, c + 1, nDimension}
                ]
            ];

            (* symmetric: (la,lb)(lc,ld) <-> (lc,ld)(la,lb) *)
            Table[ RiemannCD[-a,-b,-c,-d] =  RiemannCD[-c,-d,-a,-b],
                   {a, 2, nDimension}, {b, a + 1, nDimension}, {c, 1, a - 1}, {d, c + 1, nDimension} ];

            (* anti-symmetric: la <-> lb *)
            Table[ RiemannCD[-a,-b,-c,-d] = -RiemannCD[-b,-a,-c,-d],
                   {a, 2, nDimension}, {b, 1, a - 1}, {c, nDimension}, {d, c + 1, nDimension} ];

            (* anti-symmetric: lc <-> ld *)
            Table[ RiemannCD[-a,-b,-c,-d] = -RiemannCD[-a,-b,-d,-c],
                   {a, nDimension}, {b, a + 1, nDimension}, {c, 2, nDimension}, {d, 1, c - 1} ];

            (* symmetric: la <-> lb and lc <-> ld *)
            Table[ RiemannCD[-a,-b,-c,-d] =  RiemannCD[-b,-a,-d,-c],
                   {a, 2, nDimension}, {b, 1, a - 1}, {c, 2, nDimension}, {d, 1, c - 1} ];

            With[{elapsedTime = Round[TimeUsed[] - startTime, 0.01]},
                If [defaultCTensor[Verbose],
                    Print["Calculated ", Subscript["R", "abcd"], " using ", simpCmd, " in ", elapsedTime, "s"]
                ]
            ]
        ];
        cTensorTable[RiemannCD] = True;
    )

(* calculate a component of RiemannCD[-a,-b,-c,-d] *)
Tcalc[RiemannCD[i_Integer, j_Integer, k_Integer, l_Integer], simpCmd_:defaultCTensor[simpMethod]] :=
    Module[{rc},
        With[{a = -i, b = -j, c = -k, d = -l},
            If [a > nDimension, Message[Msg::err, a, " in ", nDimension, "dimension."]; Return[$Failed]];
            If [b > nDimension, Message[Msg::err, b, " in ", nDimension, "dimension."]; Return[$Failed]];
            If [c > nDimension, Message[Msg::err, c, " in ", nDimension, "dimension."]; Return[$Failed]];
            If [d > nDimension, Message[Msg::err, d, " in ", nDimension, "dimension."]; Return[$Failed]];

            If [!cTensorTable[bdMetric], calcBdMetric[simpCmd]];
            If [!cTensorTable[GammaCD],  Tcalc[GammaCD, simpCmd]];

            With[{startTime = TimeUsed[]},
                If [CoordinateBasisQ[],
                    rc = mGRG`STensor`Private`bdD[a, bdMetric[[c,b,d]] - bdMetric[[d,b,c]]] / 2    \
                         - mGRG`STensor`Private`bdD[b, bdMetric[[c,a,d]] - bdMetric[[d,a,c]]] / 2  \
                         + Sum[ GammaCD[-a,-c,-m] GammaCD[-b,-d,m] - GammaCD[-b,-c,-m] GammaCD[-a,-d,m], {m, nDimension} ] // simpCmd,
                (* else *)
                    rc = Sum[ Metricg[-d,-m] (mGRG`STensor`Private`bdD[a, GammaCD[-b,-c,m]]              \
                                              - mGRG`STensor`Private`bdD[b, GammaCD[-a,-c,m]])           \
                              + GammaCD[-a,-m,-d] GammaCD[-b,-c,m] - GammaCD[-b,-m,-d] GammaCD[-a,-c,m]  \
                              - Structuref[-a,-b,m] GammaCD[-m,-c,-d], {m, nDimension} ] // simpCmd
                ];
                rc = (mGRG`STensor`Private`riemannSign) * rc;

                RiemannCD[-a,-b,-c,-d] =  rc;
                RiemannCD[-b,-a,-c,-d] = -rc;
                RiemannCD[-a,-b,-d,-c] = -rc;
                RiemannCD[-b,-a,-d,-c] =  rc;
                RiemannCD[-c,-d,-a,-b] =  rc;
                RiemannCD[-d,-c,-a,-b] = -rc;
                RiemannCD[-c,-d,-b,-a] = -rc;
                RiemannCD[-d,-c,-b,-a] =  rc;

                With[{elapsedTime = Round[TimeUsed[] - startTime, 0.01]},
                    If [defaultCTensor[Verbose],
                        Print["Calculated ", printCTensor[RiemannCD, {-1,-1,-1,-1}, {a,b,c,d}], " using ", simpCmd, " in ", elapsedTime, "s"]
                    ]
                ]
            ]
        ];
    ] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] && AllTrue[{i, j, k, l}, DnIndexQ] && i != j && k != l

(* ScalarCD[] *)
Tcalc[ScalarCD, simpCmd_:defaultCTensor[simpMethod]] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] := (
        If [!cTensorTable[cInvMetric], calcInvMetric[simpCmd]];
        If [!cTensorTable[RicciCD],    Tcalc[RicciCD, simpCmd]];

        With[{startTime = TimeUsed[]},
            ScalarCD[] = Sum[ Metricg[a,b] RicciCD[-a,-b], {a, nDimension}, {b, nDimension}] // simpCmd;
            With[{elapsedTime = Round[TimeUsed[] - startTime, 0.01]},
                If [defaultCTensor[Verbose], Print["Calculated R using ", simpCmd, " in ", elapsedTime, "s"]]
            ]
        ];
        cTensorTable[ScalarCD] = True;
    )

(* structure constants f[la,lb,uc] and f[la,lb,lc] *)
Tcalc[Structuref, simpCmd_:defaultCTensor[simpMethod]] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] :=
    With[{startTime = TimeUsed[]},
        If [CoordinateBasisQ[],
            With[{stConst = Table[ 0, {a, nDimension}, {b, nDimension}, {c, nDimension} ]},
                mGRG`STensor`Private`tableToComponents[Structuref, 3, {-1,-1,-1}, stConst];
                mGRG`STensor`Private`tableToComponents[Structuref, 3, {-1,-1, 1}, stConst]
            ],
        (* else *)
            With[{bdh = Table[ mGRG`STensor`Private`bdD[a, mGRG`STensor`Private`basisMatrix[DefaultKind][[b,c]]],
                               {a, nDimension}, {b, nDimension}, {c, nDimension} ] // simpCmd},
                (* anti-symmetric *)
                Table[ Structuref[-a,-a,c] = Structuref[-a,-a,-c] = 0, {a, nDimension}, {c, nDimension} ];

                Table[ Structuref[-a,-b,c] = Sum[ inverseBasisMatrix[[mu,c]] (bdh[[a,b,mu]] - bdh[[b,a,mu]]), {mu, nDimension} ] // simpCmd,
                       {a, nDimension}, {b, a + 1, nDimension}, {c, nDimension} ];

                Table[ Structuref[-a,-b,-c] = Sum[Metricg[-c,-m] Structuref[-a,-b,m], {m, nDimension}] // simpCmd,
                       {a, nDimension}, {b, a + 1, nDimension}, {c, nDimension} ];

                Table[ Structuref[-a,-b,c] = -Structuref[-b,-a,c]; Structuref[-a,-b,-c] = -Structuref[-b,-a,-c],
                       {a, 2, nDimension}, {b, 1, a - 1}, {c, nDimension} ]
            ]
        ];
        With[{elapsedTime = Round[TimeUsed[] - startTime, 0.01]},
            If [!CoordinateBasisQ[] && defaultCTensor[Verbose],
                Print["Calculated ", Subsuperscript["f", "ab", "  c"], " and ", Subscript["f", "abc"], " using ", simpCmd, " in ", elapsedTime, "s"]
            ]
        ];
        cTensorTable[Structuref] = True;
    ]


(* WeylCD[la,lb,lc,ld] *)
Tcalc[WeylCD, simpCmd_:defaultCTensor[simpMethod]] := (
        If [!cTensorTable[RiemannCD], Tcalc[RiemannCD, simpCmd]];
        If [!cTensorTable[RicciCD],   Tcalc[RicciCD, simpCmd]];
        If [!cTensorTable[ScalarCD],  Tcalc[ScalarCD, simpCmd]];

        With[{startTime = TimeUsed[]},
            Table[ WeylCD[-a,-a,-b,-c] = 0, {a, nDimension}, {b, nDimension}, {c, nDimension} ];  (* anti-symmetric *)
            Table[ WeylCD[-b,-c,-a,-a] = 0, {a, nDimension}, {b, nDimension}, {c, nDimension} ];  (* anti-symmetric *)

            Table[
                WeylCD[-a,-b,-c,-d] =
                    RiemannCD[-a,-b,-c,-d]
                    - (mGRG`STensor`Private`riemannSign) * (
                        - (Metricg[-a,-c] RicciCD[-b,-d] - Metricg[-a,-d] RicciCD[-b,-c]
                           + Metricg[-b,-d] RicciCD[-a,-c] - Metricg[-b,-c] RicciCD[-a,-d]) / (nDimension - 2)
                        + ScalarCD[] (Metricg[-a,-c] Metricg[-b,-d] - Metricg[-a,-d] Metricg[-b,-c]) / (nDimension-1) / (nDimension-2)
                      ) // simpCmd,
               {a, nDimension}, {b, a + 1, nDimension}, {c, a, nDimension}, {d, c + 1, nDimension} ];

            (* symmetric: (la,lb)(lc,ld) <-> (lc,ld)(la,lb) *)
            Table[ WeylCD[-a,-b,-c,-d] = WeylCD[-c,-d,-a,-b],
                   {a, 2, nDimension}, {b, a + 1, nDimension}, {c, 1, a - 1}, {d, c + 1, nDimension} ];

            (* anti-symmetric: la <-> lb *)
            Table[ WeylCD[-a,-b,-c,-d] = -WeylCD[-b,-a,-c,-d],
                   {a, 2, nDimension}, {b, 1, a - 1}, {c, nDimension}, {d, c + 1, nDimension} ];

            (* anti-symmetric: lc <-> ld *)
            Table[ WeylCD[-a,-b,-c,-d] = -WeylCD[-a,-b,-d,-c],
                   {a, nDimension}, {b, a + 1, nDimension}, {c, 2, nDimension}, {d, 1, c - 1} ];

            (* symmetric: la <-> lb and lc <-> ld *)
            Table[ WeylCD[-a,-b,-c,-d] = WeylCD[-b,-a,-d,-c], {a, 2, nDimension}, {b, 1, a - 1}, {c, 2, nDimension}, {d, 1, c - 1} ];

            With[{elapsedTime = Round[TimeUsed[] - startTime, 0.01]},
                If [defaultCTensor[Verbose], Print["Calculated ", Subscript["C", "abcd"], " using ", simpCmd, " in ", elapsedTime, "s"]]
            ]
        ];
        cTensorTable[WeylCD] = True;
    ) /; mGRG`STensor`Private`flagTable[InitCTensorFlag] && nDimension > 2

(***** Local Functions *****)

calcBdMetric[simpCmd_:defaultCTensor[simpMethod]] :=
(* calculate bdD[la, Metricg[lb,lc]] *)
    With[{startTime = TimeUsed[]},
        bdMetric = Table[0, {a, nDimension}, {b, nDimension}, {c, nDimension} ];
        Table[ bdMetric[[a,b,c]] = mGRG`STensor`Private`bdD[a, cMetric[[b,c]]] // simpCmd, {a, nDimension}, {b, nDimension}, {c, b, nDimension} ];
        Table[ bdMetric[[a,b,c]] = bdMetric[[a,c,b]], {a, nDimension}, {b, 2, nDimension}, {c, 1, b - 1} ];  (* symmetric: lb <-> lc *)
        cTensorTable[bdMetric] = True;
        With[{elapsedTime = Round[TimeUsed[] - startTime, 0.01]},
            If [defaultCTensor[Verbose],
                Print["Calculated ", Subscript["\[PartialD]", "a"], Subscript["g", "bc"], " using ", simpCmd, " in ", elapsedTime, "s"]
            ]
        ];
    ]

calcInvMetric[simpCmd_:defaultCTensor[simpMethod]] :=
(* inverse metric *)
    With[{startTime = TimeUsed[]},
        mGRG`STensor`Private`tableToComponents[Metricg, 2, {1,1}, Inverse[cMetric] // simpCmd];
        cTensorTable[cInvMetric] = True;
        With[{elapsedTime = Round[TimeUsed[] - startTime, 0.01]},
            If [defaultCTensor[Verbose],
                Print["Calculated ", Superscript["g", "ab"], " using ", simpCmd, " in ", elapsedTime, "s"]
            ]
        ];
    ]

(****************************** Show ********************************)

Unprotect[Show];

Show[GammaCD] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] :=
    Module[{jStart, isAllZero = True, i},
        If [!cTensorTable[GammaCD], Message[Msg::warn, "not calculated", "", "", ""]; Return[]];

        With[{jStart =
                If [CoordinateBasisQ[],
                    Print[Row[{"Symmetry: ", Subsuperscript["\[CapitalGamma\]", "(ab)", "    c"]}]];
                    i,
                (* else *)
                    1
                ]},

            For [i = 1, i <= nDimension, ++i,
                Do [
                    Do [
                        If [GammaCD[-i,-j,k] =!= 0,
                            isAllZero = False;
                            Print[Row[{printCTensor[GammaCD, {-1,-1,1}, {i,j,k}], " = ", GammaCD[-i,-j,k]}]]
                        ],
                        {k, nDimension}
                    ],
                    {j, jStart, nDimension}
                ]
            ];

            If [isAllZero === True,
                Print[Row[{Subsuperscript["\[CapitalGamma\]", "ab", "  c"], " = ", "0"}]]
            ]
        ]
   ]

Show[LineElement, simpCmd_:Together] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] := LineElement[GetCoordinates[], cMetric, simpCmd]

Show[Metricg] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] := (
        Print[Row[{"Symmetry: ", Subscript["g", "(ab)"]}]];
        Do [
            Do [
                If [Metricg[-i,-j] =!= 0,
                    Print[Row[{printCTensor[Metricg, {-1,-1}, {i,j}], " = ", Metricg[-i,-j]}]]
                ],
                {j, i, nDimension}
            ],
            {i, nDimension}
        ]
    )

Show[RicciCD] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] :=
    Module[{isAllZero = True},
        If [!cTensorTable[RicciCD], Message[Msg::warn, "not calculated", "", "", ""]; Return[]];

        Print[Row[{"Symmetry: ", Subscript["R", "(ab)"]}]];
        Do [
            Do [
                If [RicciCD[-i,-j] =!= 0,
                    isAllZero = False;
                    Print[Row[{printCTensor[RicciCD, {-1,-1}, {i,j}], " = ", RicciCD[-i,-j]}]]
                ],
                {j, i, nDimension}
            ],
            {i, nDimension}
        ];

        If [isAllZero === True, Print[SequenceForm[Subscript["R", "ab"], " = ", "0"]]]
    ]

Show[RiemannCD] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] :=
    Module[{isAllZero = True},
        If [!cTensorTable[RiemannCD], Message[Msg::warn, "not calculated", "", "", ""]; Return[]];

        Print[Row[{"Symmetry: ", Subscript["R", "[ab][cd]"], " = ", Subscript["R", "[cd][ab]"]}]];
        Do [
            Do [
                Do [
                    Do [
                        If [RiemannCD[-i,-j,-k,-l] =!= 0,
                            isAllZero = False;
                            Print[Row[{printCTensor[RiemannCD, {-1,-1,-1,-1}, {i,j,k,l}], " = ", RiemannCD[-i,-j,-k,-l]}]]
                        ],
                        {l, k + 1, nDimension}
                    ],
                    {k, i, nDimension}
                ],
                {j, i + 1, nDimension}
            ],
            {i, nDimension}
        ];

        If [isAllZero === True, Print[Row[{Subscript["R", "abcd"], " = ", "0"}]]]
    ]

Show[ScalarCD] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] := (
        If [!cTensorTable[ScalarCD], Message[Msg::warn, "not calculated", "", "", ""]; Return[]];

        Print[Row[{printCTensor[ScalarCD, {}, {}], " = ", ScalarCD[]}]]
    )

Show[Structuref] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] :=
    If [CoordinateBasisQ[],
        Print[Row[{Subsuperscript["f", "ab", "  c"], " = ", "0"}]],
    (* else *)
        Module[{isAllZero = True},
            If [!cTensorTable[Structuref], Message[Msg::warn, "not calculated", "", "", ""]; Return[]];

            Print[Row[{"Symmetry: ", Subsuperscript["f", "[ab]", "    c"]}]];

            Do [
                Do [
                    Do [
                        If [Structuref[-i,-j,k] =!= 0,
                            isAllZero = False;
                            Print[Row[{printCTensor[Structuref, {-1,-1,1}, {i,j,k}], " = ", Structuref[-i,-j,k]}]]
                        ],
                        {k, nDimension}
                    ],
                    {j, i + 1, nDimension}
                ],
                {i, nDimension}
            ];

            If [isAllZero === True, Print[Row[{Subsuperscript["f", "ab", "  c"], " = ", "0"}]]]
        ]
    ]

Show[WeylCD] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] :=
    Module[ {isAllZero = True},
        If [nDimension <= 2, Message[Msg::warn, "WeylCD is not defined in ", nDimension, "dimension.",  ""]; Return[]];
        If [!cTensorTable[WeylCD], Message[Msg::warn, "not calculated", "", "", ""]; Return[]];

        Print[Row[{"Symmetry: ", Subscript["C", "[ab][cd]"]}]];
        Do [
            Do [
                Do [
                    Do [
                        If [WeylCD[-i,-j,-k,-l] =!= 0,
                            isAllZero = False;
                            Print[Row[{printCTensor[WeylCD, {-1,-1,-1,-1}, {i,j,k,l}], " = ", WeylCD[-i,-j,-k,-l]}]]
                        ],
                        {l, k + 1, nDimension}
                    ],
                    {k, nDimension}
                ],
                {j, i + 1, nDimension}
            ],
            {i, nDimension}
        ];

        If [isAllZero === True, Print[Row[{Subscript["C", "abcd"], " = ", "0"}]]]
    ]

Show[tName_[indices___]] :=
(* display one tensor *)
(* TODO: consider symmetries and contraction, in general, in Show[tName] *)
    Module[{indexL = {}, value},
        With[{dnupL = mGRG`STensor`Private`dnupListFrom[indices]},
            Do [
                indexL = Join[indexL, {Table[j, {j, nDimension}]}],
                {i, Length[{indices}]}
            ];

            (* get all possible combinations of component indices *)
            indexL = Flatten[Outer[List, Sequence @@ Table[indexL[[i]], {i, Length[indexL]}]], 1];
            indexL = Flatten[indexL, TensorRank[indexL] - 2];

            Do [
                value = tName[Sequence @@ (dnupL * indexL[[i]])];
                If [value =!= 0, Print[Row[{printCTensor[tName, dnupL, indexL[[i]]], " = ", value}]]],
                {i, Length[indexL]}
            ]
        ]
    ] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] && IndexedTensorQ[tName] && AllTrue[{indices}, TensorialIndexQ]

Protect[Show];

(***** Local Functions *****)

printCTensor[tName_, dnupL_, posL_] :=
    Module[{upL = {}, dnL = {}},
        With[{coSys = ToString /@ GetCoordinates[]},
            Do [
                If [dnupL[[i]] === -1,
                    If [CoordinateBasisQ[], AppendTo[dnL, coSys[[posL[[i]]]]],
                    (* else *)              AppendTo[dnL, posL[[i]]]];
                    AppendTo[upL, " "],
                (* else *)
                    AppendTo[dnL, " "];
                    If [CoordinateBasisQ[], AppendTo[upL, coSys[[posL[[i]]]]],
                    (* else *)              AppendTo[upL, posL[[i]]]]
                ],

                {i, Length[dnupL]}
            ];

            Subsuperscript[ToExpression @ mGRG`STensor`Private`getPrtStr[tName], Row[dnL], Row[upL]]
        ]
    ]

(************************ Misc. for CTensor **************************)

Geodesic[comp_Integer?Positive, simpCmd_:defaultCTensor[simpCmd]] /; mGRG`STensor`Private`flagTable[InitCTensorFlag] :=
(* print geodesic equation *)
    Module[{rc},
        If [comp > nDimension, Message[Msg::err, comp, "is incompatible with dimension", nDimension, ""]; Return[$Failed]];
        If [!CoordinateBasisQ[], Message[Msg::err, "coordinate basis only", "", "", ""]; Return[$Failed]];

        With[{coSys = ToString /@ GetCoordinates[]},
            rc = Overscript[coSys[[comp]], ".."];
            Do [
                Do [
                    If [i === j, rc +=   GammaCD[-i,-j,comp] OverDot[coSys[[i]]] OverDot[coSys[[j]]],
                    (* else *)   rc += 2 GammaCD[-i,-j,comp] OverDot[coSys[[i]]] OverDot[coSys[[j]]]],

                    {j, i, nDimension}
                ],
                {i, nDimension}
            ];
            rc // simpCmd
        ]
    ]
Geodesic[___] := Message[Geodesic::usage]

(********************************************************************)

End[ ] (* end the private context *)

EndPackage[ ]  (* end the package context *)

(********************************************************************)
