(* ::Package:: *)
(* :Context: mGRG`Einstein` *)
(* :Author: Park, Dal-Ho *)
(* :Summary: A package for doing tensor calculus in General Relativity. *)
(* :Package Version: 2026.01 *)
(* :Mathematica Version: 12.2+ *)

BeginPackage["mGRG`Einstein`", {"mGRG`STensor`", "mGRG`mPerm`"}]

RiemannToWeyl::usage = "RiemannToWeyl[expr] converts the Riemann tensor in 'expr' to the Weyl tensor."
WeylToRiemann::usage = "WeylToRiemann[expr] converts the Weyl tensor in 'expr' to the Riemann tensor."

(***** Exported Symbols *****)
WeylCD::usage = "WeylCD[up, dn, dn, dn] represents the Weyl conformal curvature tensor."

(***************************** CTensor ******************************)

ClearCTensor::usage = "ClearCTensor[] clears all previously calculated tensor components and resets the CTensor environment."
InitCTensor::usage  = "InitCTensor[coSys, metric, <basis>, opts] initializes the environment for component tensor calculations. `coSys` is a list of coordinates, and `metric` is the metric matrix. An optional `basis` matrix can be provided for non-coordinate bases. Options allow for pre-calculation of curvature components and setting the simplification level."
SetCTensor::usage   = "SetCTensor is an alias for InitCTensor."
Tcalc::usage        = "Tcalc[tensor, simpCmd] calculates the components of a given `tensor` (e.g., GammaCD, RicciCD, RiemannCD). An optional simplification command `simpCmd` can be specified."

Geodesic::usage = "Geodesic[comp, simpCmd] calculates the geodesic equation for the specified component `comp`. It is only available for coordinate bases. `simpCmd` is an optional simplification function."

Csimplify::usage      = "A simplification function for component tensor expressions."
CsimplifyMore::usage  = "CsimplifyMore[expr, assump] is a more powerful simplification function that uses Simplify with optional assumptions `assump`."

(***** Exported Symbols *****)
CsimplifyRules::usage = "CsimplifyRules is a list of user-defined simplification rules used by Csimplify and CsimplifyMore."
MetricPath::usage     = "MetricPath specifies the directory path for loading predefined metric files with InitCTensor."

(* Options for IniTCTensor *)
FourDimensionQ::usage = "FourDimensionQ is an option for InitCTensor. If True (the default), it enforces that the spacetime is four-dimensional. Set to False to allow for calculations in other dimensions."
SimplifyMore::usage   = "SimplifyMore is an option for InitCTensor. If set to True, it uses CsimplifyMore as the default simplification method for calculations."

(**************************** CTensorNP *****************************)

BasisNP::usage        = "BasisNP[metric, simpCmd] generates a Newman-Penrose null tetrad {l, n, m, m-bar} from a 4x4 metric matrix. 'simpCmd' is an optional simplification function."
ClearCTensorNP::usage = "ClearCTensorNP[] clears all definitions and calculated components related to the Newman-Penrose formalism, resetting the NP environment."
InitCTensorNP::usage  = "InitCTensorNP[coSys, nullVectors, opts] initializes the environment for Newman-Penrose formalism calculations. 'coSys' is a list of 4 coordinates, and 'nullVectors' is the 4x4 null tetrad matrix {l, n, m, m-bar}. Options can be used to control re-initialization and simplification."
RotateNP::usage       = "RotateNP[nullVectors, classN, p1, p2, simpCmd] performs a Lorentz rotation on the given 'nullVectors'. 'classN' specifies the rotation type (1: null rotation about l, 2: null rotation about n, 3: spin-boost). 'p1' and 'p2' are rotation parameters. 'simpCmd' is an optional simplification function."
SetCTensorNP::usage   = "SetCTensorNP is an alias for InitCTensorNP."

(***** Exported Symbols *****)
PetrovType::usage       = "PetrovType is a symbol representing the Petrov classification of the Weyl tensor. Use Show[PetrovType] to display the classification (e.g., Type D, N, etc.) based on the calculated Weyl scalars."
LambdaNP::usage         = "LambdaNP represents the NP scalar related to the Ricci scalar, defined as R/24. Its value is calculated automatically by InitCTensorNP."
PhiNP::usage            = "PhiNP[i, j] represents the components of the trace-free part of the Ricci tensor in the NP formalism. Use Show[PhiNP] to display all components."
PsiNP::usage            = "PsiNP[i] represents the five complex Weyl scalars (Psi0 to Psi4) in the NP formalism. Use Show[PsiNP] to display their values."
SpinCoefficients::usage = "SpinCoefficients is a symbol representing the 12 complex spin coefficients (e.g., kappa, rho, sigma, tau). Use Show[SpinCoefficients] to display their values."

(********************************************************************)
Begin["`Private`"]

RiemannToWeyl[expr_] := expr /. riemannToWeylRule[RiemannCD, Metricg, GetDimension[], WeylCD, RicciCD, ScalarCD]
RiemannToWeyl[___]   := Message[RiemannToWeyl::usage]

    riemannToWeylRule[riemann_, metric_, nDim_, weyl_, ricci_, scalar_] := {
            riemann[a_,b_,c_,d_] :>
                weyl[a,b,c,d] + (mGRG`STensor`Private`riemannSign) * (
                    - (metric[a,c] ricci[b,d] - metric[a,d] ricci[b,c]
                       + metric[b,d] ricci[a,c] - metric[b,c] ricci[a,d]) / (nDim - 2)
                    + scalar[] (metric[a,c] metric[b,d] - metric[a,d] metric[b,c]) / (nDim-1) / (nDim-2)
                )
        }

WeylToRiemann[expr_] := expr /. weylToRiemannRule[WeylCD, GetMetric[], GetDimension[], RiemannCD, RicciCD, ScalarCD]
WeylToRiemann[___]   := Message[WeylToRiemann::usage]

    weylToRiemannRule[weyl_, metric_, nDim_, riemann_, ricci_, scalar_] := {
            weyl[a_,b_,c_,d_] :>
                riemann[a,b,c,d] - (mGRG`STensor`Private`riemannSign) * (
                    - (metric[a,c] ricci[b,d] - metric[a,d] ricci[b,c]
                       + metric[b,d] ricci[a,c] - metric[b,c] ricci[a,d]) / (nDim - 2)
                    + scalar[] (metric[a,c] metric[b,d] - metric[a,d] metric[b,c]) / (nDim-1) / (nDim-2)
                )
        }

(*************************** CTensor ********************************)
<< mGRG`Einstein`CTensor`

(************************** CTensorNP *******************************)
<< mGRG`Einstein`CTensorNP`  (* Experimental *)

(********************************************************************)

initEinstein[] := (
        (* torsion-free *)
        TorsionFreeQ[CD] = True;

        (* WeylCD *)
        DefTensor[WeylCD, "-bacd-abdc+cdab", PrintAs -> "C"];

        (***** End of initEinstein *****)
        initEinstein = True;  (* guard reloding *)
    )
initEinstein[];

(********************************************************************)
End[]

EndPackage[]
