(********************************************************************)
(************************** Hypersurface.m **************************)
(********************************************************************)

(********************************************************************)
BeginPackage["mGRG`STensor`", {"mGRG`mPerm`"}]
(********************************************************************)

(********************************************************************)
Begin["`Private`"]

(************************ Exported Functions ************************)

DefHypersurface[subKind_Symbol, normSign_Integer: -1] := (
        If [!CheckKind[subKind], Return[$Failed]];
        If [!MemberQ[{-1, 1}, normSign], Message[Msg::err, "Unsupported norm for NormalV:", normSign, "Must be -1 or 1."]; Return[$Failed]];
        If [!MetricSpaceQ[DefaultKind], Message[Msg::err, "The spacetime (of DefaultKind) must be a metric space to define a hypersurface."]; Return[$Failed]];

        (*--- 1. Define Geometric Objects ---*)

        (* intrinsic covariant derivative *)
        DefDerivativeOperator[SubCD, "D", subKind];

        (* induced metric *)
        DefMetric[SubMetric, "\[Gamma]", subKind];
        SetMetricCompatible[SubCD, SubMetric];

        (* extrinsic curvature tensor *)
        defineOperand[ExtrinsicK, "+ba", {subKind}, {-1}, IndexedTensorQ, PrintAs -> "K"];

        (* projector tensor (embedding basis) from spacetime to hypersurface *)
        defineOperand[SubBasis, "ab", {subKind, DefaultKind}, {-1, 1}, IndexedTensorQ, PrintAs -> "h"];

        (* normal vector field to the hypersurface *)
        defineOperand[NormalV, "a", {DefaultKind}, {1}, IndexedTensorQ, PrintAs -> "n"];

        (*--- 2. Algebraic Identities ---*)

        (* normalization of the normal vector: n^a * n_a = normSign *)
        NormalV/: NormalV[a_] NormalV[b_] := normSign /; FreePatternQ[{a, b}] && ValidIndicesQ[{a, b}, DefaultKind] && PairIndexQ[a, b];

        (* orthogonality of the projector and the normal vector: h_a^b * n_b = 0 *)
        NormalV/: SubBasis[a_, b_] NormalV[c_] := 0 /; FreePatternQ[{a, b, c}] && ValidIndexQ[a, subKind] && ValidIndicesQ[{b, c}, DefaultKind] && PairIndexQ[b, c];

        (* projector property: h_a^c * h_b^d * g_cd = \gamma_ab *)
        SubBasis/: SubBasis[a_, b_] SubBasis[c_, d_] :=
            SubMetric[a, c] /; FreePatternQ[{a, b, c, d}] && ValidIndicesQ[{a, c}, subKind] && ValidIndicesQ[{b, d}, DefaultKind] && PairIndexQ[b, d];

        (* completeness relation: \gamma_ab = h_a^c h_b^d g_cd *)
        SubBasis/: SubBasis[a_, b_] SubBasis[c_, d_] Metricg[e_, f_] :=
            SubMetric[a, c] /; FreePatternQ[{a, b, c, d, e, f}] && ValidIndicesQ[{a, c}, subKind] && ValidIndicesQ[{b, d, e, f}, DefaultKind] \
                               && ((PairIndexQ[b, e] && PairIndexQ[d, f]) || (PairIndexQ[b, f] && PairIndexQ[d, e]));

        (*--- 3. Derivative Rules (Gauss-Weingarten Equations) ---*)

        derivativeRules[TangentialD];
  
        (* Gauss equation: *)
        TangentialD[a_, SubBasis[b_, c_]] :=
            With[{dummy = NewDummy[subKind]},
                With[{affine = getDerOp[Gamma][SubCD]},
                    affine[a, b, dummy[[2]]] SubBasis[dummy[[1]], c] - normSign ExtrinsicK[a, b] NormalV[c]
                ]
            ] /; ValidIndicesQ[{a, b}, subKind] && ValidIndexQ[c, DefaultKind];

        (* Weingarten (Shape) Equation: *)
        TangentialD[a_, NormalV[b_]] :=
            With[{dummy = NewDummy[subKind]},
                ExtrinsicK[a, dummy[[2]]] SubBasis[dummy[[1]], b]
            ] /; ValidIndexQ[a, subKind] && ValidIndexQ[b, DefaultKind];

        (* Tangential derivative on scalars *)
        TangentialD[a_, expr_] := BD[a, expr] /; ValidIndexQ[a, subKind] && NoIndexQ[expr, IndexQs -> { !(KindIndexQ[DefaultKind][#]&) }];
)

(********************************************************************)

End[ ] (* end the private context *)

EndPackage[ ]  (* end the package context *)

(********************************************************************)
