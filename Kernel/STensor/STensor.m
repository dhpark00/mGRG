(* ::Package:: *)
(* :Context: mGRG`STensor` *)
(* :Author: Park, Dal-Ho *)
(* :Summary: A package for symbolic tensor calculus. *)
(* :Package Version: 2026.01 *)
(* :Mathematica Version: 12.2+ *)

(* Note for Predefined Structures:
  - LD[v, expr] is NOT properly defined when expr contains non-tensorial operators, such as BD.
    Use FreeQ[expr, BD | Alternatives @@ nonTensorList].
  - In mGRG, BD is THE special operator in the sense of Wald's book.
  - g^bd LD[v, R[a,b,c,d]] =!= LD[v, R[a,c]] because LD[v, g^bd] =!= 0 in general.
    This is so because LD[v, T[a,b,c]] =!= (LD[v, T])[a,b,c].
  - Use SetDelayed when DefaultKind lies in RHS. (NB: DefaultKind can be changed by SetDefaultKind[])
  - Tsimplify is only for symmetric metrics.
  - The type of indexed objects are defined by its shape (index-kinds and updns). See KindOf[].
    For an example
        ymF: {{Latin,-1}, {Latin,-1}, {Greek,+1}}
    But,
        Kdelta: All
        Metricg, CD, and Epsilon: DefaultKind
  - In SetCoordinates, it is NOT necessary to protect the coordinate names. (2020.12.26)
 *)

(********************************************************************)
BeginPackage["mGRG`STensor`", {"mGRG`mPerm`"}]

(********************************************************************)
(************************* IndexNotation.m **************************)
(********************************************************************)

(*************************** Utilities ******************************)
AllQoptions::usage = "AllQoptions[qHead][name, optL] checks if 'name' satisfies all conditions in the option list 'optL'. 'qHead' is typically HeadQs or IndexQs."
ConstantQ::usage = "ConstantQ[x] returns True if x is a number or a numeric symbol or a constant symbol, and False otherwise."
FreePatternQ::usage = "FreePatternQ[expr] checks if 'expr' contains pattern objects."
PositiveIntegerQ::usage = "PositiveIntegerQ[n] yields True if n is a positive integer, and False otherwise."
SignOfTerm::usage = "SignOfTerm[expr] returns -1 if a symbolic 'term' has a leading minus sign (e.g., -x), and 1 otherwise."
SymbolJoin::usage  = "SymbolJoin[s1, s2, ...] joins symbols or strings into a single symbol."

(* Options *)
CovDs::usage = "An option for specifying which covariant derivatives to consider."
HeadQs::usage = "An option for specifying heads of expressions to which a function should be applied."
IndexQs::usage = "An option for specifying which indices to target in an operation."

(***** messages *****)
Msg::err  = "`1` `2` `3` `4`"
Msg::warn = "`1` `2` `3` `4`"
Msg::note = "`1` `2` `3` `4` `5`"
General::invalid = "`1` is not a valid `2`.";

(**************************** Indices *******************************)
ComponentIndexQ::usage = "ComponentIndexQ[index] returns True if 'index' is a component index (a non-zero integer)."
DummyIndexQ::usage     = "DummyIndexQ[index] returns True if 'index' is a system-generated dummy index."
RegularIndexQ::usage   = "RegularIndexQ[index] returns True if 'index' is a regular, non-dummy, symbolic index, typically defined with SetIndices."

DnIndexQ::usage = "DnIndexQ[index] returns True if 'index' is a valid lower (covariant) index, and False otherwise."
UpIndexQ::usage = "UpIndexQ[index] returns True if 'index' is a valid upper (contravariant) index, and False otherwise."

AddIndices::usage  = "AddIndices[{\"c1\", \"c2\", ...}, ikind] adds new index characters to an existing index kind."
DropIndices::usage = "DropIndices[{\"c1\", \"c2\", ...}, ikind] removes specified index characters from an existing index kind."
GetIndices::usage  = "GetIndices[ikind] returns all defined indices of the specified index kind."
SetIndices::usage  = "SetIndices[{\"a\", \"b\", ...}, ikind] defines a new set of indices of a specified index kind."

IndexToKind::usage = "IndexToKind[idx] returns the kind of 'idx', and NonKind otherwise."
KindIndexQ::usage  = "KindIndexQ[ikind] returns a pure function that checks if an index belongs to the specified 'ikind'."
OneDimKindQ::usage = "OneDimKindQ[ikind] returns True if 'ikind' is a one-dimensional index kind."

NewDummy::usage = "NewDummy[ikind] generates a new unique dummy index of the specified index kind."

FlipIndex::usage = "FlipIndex[index] changes an upper index to a lower index and vice-versa."
ToDnIndex::usage = "ToDnIndex[index] converts an upper index to its corresponding lower index. It has no effect on lower or non-tensorial indices."
ToUpIndex::usage = "ToUpIndex[index] converts a lower index to its corresponding upper index. It has no effect on upper or non-tensorial indices."

IndexOrderedQ::usage = "IndexOrderedQ[indexList] returns True if the list of indices is canonically sorted. IndexOrderedQ[list1, list2] returns True if list1 is ordered before or is the same as list2."
IndexSort::usage     = "IndexSort[indexList] sorts a list of indices into a canonical order."

PairIndexQ::usage = "PairIndexQ[index1, index2] returns True if index1 and index2 form a valid upper/lower pair. PairIndexQ[{{i1,j1}, {i2,j2}, ...}] checks if all given pairs are valid index pairs."
TakePairs::usage  = "TakePairs[indexList] finds pairs of identical upper and lower indices in 'indexList'."

DuplicatedIndicesQ::usage = "DuplicatedIndicesQ[indexL] returns True if there are any duplicated tensorial indices in 'indexL', and False otherwise."
TensorialIndexQ::usage    = "TensorialIndexQ[index] returns True if 'index' is a symbolic index (regular or dummy), as opposed to a component index."
UpupDndnIndexQ::usage     = "UpupDndnIndexQ[indexL] returns True if indices in indexL are all dn or all up."

(***** Exported Symbols *****)

DefaultKind::usage = "DefaultKind represents the default kind (usually Latin) used when no kind is explicitly specified."
NonKind::usage     = "NonKind represents the absence of a valid kind. It is returned by IndexToKind when an index is not associated with any defined kind."
Latin::usage       = "A predefined index kind for Latin character indices like a, b, c, ..."

(************************ Kind Structures ***************************)
CheckKind::usage    = "CheckKind[kind] returns True if 'kind' is a defined kind, and returns False with an error message otherwise. It can also be applied to a list of kinds, returning True only if all kinds in the list are defined."
DefinedKindQ::usage = "DefinedKindQ[kind] returns True if 'kind' is a defined kind."
DefKind::usage      = "DefKind[kind, {\"a\", \"b\", ...}] defines a new Kind with a set of indices."
UndefKind::usage    = "UndefKind[kind] removes the definition of the specified kind."

GetEpsilon::usage    = "GetEpsilon[kind] returns the Levi-Civita tensor (volume form) associated with the specified 'kind'."
GetMetric::usage     = "GetMetric[kind] returns the unique metric tensor associated with the specified 'kind'."
GetStructuref::usage = "GetStructuref[kind] returns the structure constants tensor associated with the specified 'kind'."
GetTorsion::usage    = "GetTorsion[kind] returns the torsion tensor associated with the specified 'kind'."

KindMatchQ::usage = "KindMatchQ[kind1, kind2] returns True if the two kinds are compatible, and False otherwise. The special kind 'All' is compatible with any other kind, while 'NonKind' is not compatible with any kind."

GetCoordinates::usage   = "GetCoordinates[kind] returns the coordinates of the specified kind."
SetCoordinates::usage   = "SetCoordinates[coSys, kind] sets the coordinates for the specified 'kind'. Use SetCoordinates[coSys, basis, kind] for a non-coordinate basis."
ClearCoordinates::usage = "ClearCoordinates[kind] removes the coordinate definitions for the specified 'kind'."

CoordinateBasisQ::usage = "CoordinateBasisQ[kind] returns True if the basis associated with 'kind' is a coordinate basis."

GetDimension::usage   = "GetDimension[kind] returns the dimension of the specified kind."
SetDimension::usage   = "SetDimension[n, kind] sets the dimension for the specified 'kind' to 'n'."
ClearDimension::usage = "ClearDimension[kind] removes the dimension definition for the specified 'kind'."

GetSig::usage         = "GetSig[kind] returns the number of minus in metric's eigenvalues of the specified kind."
SetSig::usage   = "SetSig[s, kind] sets the signature parameter 's' (number of minus signs in the metric signature) for the specified 'kind'."
ClearSig::usage = "ClearSig[kind] removes the signature definition for the specified 'kind'."

ValidIndexQ::usage   = "ValidIndexQ[index, kind] returns True if 'index' is a valid index for the specified 'kind'. It checks for index kind compatibility for symbolic indices and dimension bounds for component indices."
ValidIndicesQ::usage = "ValidIndicesQ[indexList, kind] returns True if all indices in 'indexList' are valid for the specified 'kind' and there are no duplicated symbolic indices."

(***** Exported Symbols *****)

Epsilon::usage    = "Epsilon[idx, idx, ...] represents the Levi-Civita tensor."
Structuref::usage = "Structuref[up, dn, dn] represents the structure constants for a non-coordinate basis in DefaultKind. It is defined only when `CoordinateBasisQ` is `False`."
Torsion::usage    = "Torsion[up, dn, dn] represents the torsion tensor in DefaultKind. It is defined for each index kind."

(************************* Indexed Objects **************************)
(********** Defining IndexedObject **********)

(* Objects *)
RemoveIndexedObject::usage = "RemoveIndexedObject[oName] removes all definitions associated with the indexed object 'oName'. It does not work on reserved names."
ObjectQ::usage             = "ObjectQ[name] returns True if 'name' is a defined indexed object or a scalar function, and False otherwise."
IndexedObjectQ::usage      = "IndexedObjectQ[name] returns True if 'name' is a defined indexed object (like a tensor or an operator), and False otherwise."
IndexedOperandQ::usage     = "IndexedOperandQ[name] returns True if 'name' is an indexed operand (an object that takes indices, like a tensor or differential form), and False otherwise."
IndexedTensorQ::usage      = "IndexedTensorQ[name] returns True if 'name' is a defined indexed tensor, and False otherwise."
DiffFormQ::usage           = "DiffFormQ[name] returns True if 'name' is a defined differential form, and False otherwise."
IndexedOperatorQ::usage    = "IndexedOperatorQ[name] returns True if 'name' is a defined indexed operator (like CD or LD), and False otherwise."
ScalarFunctionQ::usage     = "ScalarFunctionQ[name] returns True if 'name' is a scalar function (e.g., Sin, Cos, or Tscalar), which can take scalar arguments."

(* Define Tensors *)
DefTensor::usage   = "DefTensor[tensor[indices], \"symmetryString\"] defines a new tensor with specified index kinds and symmetry."
Tdefine::usage     = "Alias of DefTensor"
UndefTensor::usage = "UndefTensor[tensor] removes all definitions associated with a tensor."

AllPermutations::usage = "AllPermutations[permS] generates a string representing all permutations and their weights implied by the symmetry string permS. It is useful for visualizing the full symmetry of a tensor."
DnupAt::usage          = "DnupAt[name, pos] returns the up/down state (-1 for down, +1 for up) of the index at position 'pos' for the specified indexed object."
GetRank::usage         = "GetRank[tensor] returns the rank of a defined tensor."
GStoString::usage      = "GStoString[gs, len] converts a generator set gs into its string representation for a tensor of rank len. If len is omitted, the maximum rank from the generator set is used."
KindOf::usage          = "KindOf[obj, pos] returns the kind of the object 'obj' at a given index position 'pos'. For an indexed object expression like T[a,b], KindOf[T[a,b], a] returns the kind of index 'a'."

(* Index Symmetries *)
GetSymmetry::usage = "GetSymmetry[tensor] returns the symmetry generator set of a defined tensor."
SetSymmetry::usage = "SetSymmetry[tensor, \"symmetryString\"] sets the index symmetry for a defined tensor."

(***** Exported Symbols *****)

(* Wrappers *)
ErrorT::usage  = "ErrorT[expr] is a wrapper for expressions with errors, causing expr to be displayed in red."
Tscalar::usage = "A wrapper for scalar quantities to protect them from tensor operations."

(* Predefined Indexed Objects *)
Kdelta::usage = "Kdelta[up, dn] represents the Kronecker delta tensor."

(* Operator Types *)
CD::usage = "CD[index, expr] represents an operator like the covariant derivative operator acting on 'expr'."
LD::usage = "LD[vector, expr] represents an operator like the Lie derivative with respect to 'vector' acting on 'expr'."
XD::usage = "XD[expr] represents an operator like the exterior derivative"
XP::usage = "XP[args,..] represents an operator like the exterior product"

(* Predefined Tensorial Operators: BD, CD, and LD *)
BD::usage = "BD[aIndex, expr] represents the basis derivative of 'expr' with respect to the basis vector associated with 'aIndex'. For a coordinate basis, this is equivalent to a partial derivative. For a non-coordinate basis, it is defined via the basis matrix. BD[kind][aIndex, expr] can be used to specify the derivative for a particular kind."

(* Option for Tdefine and Fdefine *)
PrintAs::usage = "An option for Tdefine and DefForm that specifies the string to be used when displaying the tensor or form."

(********** Utils for indexed objects **********)

ExpandObject::usage  = "ExpandObject[expr] expands expressions containing indexed objects, distributing products over sums."
FreeObjectQ::usage   = "FreeObjectQ[expr] returns True if 'expr' is free of indexed objects, and False otherwise."
ForEachTerm::usage   = "ForEachTerm[expr, f, args...] applies the function 'f' to each term of a sum or equation in 'expr'."
ForEachObject::usage = "ForEachObject[expr, hOptL, f, args...] applies 'f' to each indexed object in 'expr' that satisfies the head options 'hOptL'."
SplitTerm::usage     = "SplitTerm[term, hOptL] splits a term into {scalarPart, tensorPart}, separating indexed objects defined by 'hOptL' from other factors."

(****************** Operations on Indexed Expressions ***************)
(* Find indices from a term *)
FindIndices::usage    = "FindIndices[term] returns a list of all indices present in 'term'."
FindIndicesAll::usage = "FindIndicesAll[term] returns a list of all indices in 'term', without checking for index validity."

FindFreeTensorialIndices::usage    = "FindFreeTensorialIndices[term] returns a list of free (uncontracted) tensorial indices in 'term'."
FindFreeTensorialIndicesAll::usage = "FindFreeTensorialIndicesAll[term] returns a list of all free tensorial indices in 'term', without checking for index validity."

(* Utilities for indexed exprs *)
NoIndexQ::usage = "NoIndexQ[expr] returns True if 'expr' is a scalar or contains no free tensorial indices."

(* Reordering indices of IndexedObjects *)
AntisymmetrizeIndices::usage = "AntisymmetrizeIndices[expr, {i1, i2, ...}] returns the expression antisymmetrized with respect to the list of indices."
SymmetrizeIndices::usage     = "SymmetrizeIndices[expr, {i1, i2, ...}] returns the expression symmetrized with respect to the list of indices."

(* Dummy Operations *)
Dum::usage          = "Dum[expr] contracts all possible dummy index pairs in 'expr'."
DumFresh::usage     = "DumFresh[expr] renames all dummy indices in 'expr' to new unique indices."
ResetDummies::usage = "ResetDummies[expr, opts] renames dummy indices in 'expr' to a canonical form (e.g., la, lb, ...), avoiding conflicts with existing free indices. Options like HeadQs and IndexQs can be used to control which parts of the expression are processed."
SplitIndices::usage = "SplitIndices[expr, {i, i1, i2, ...}, {j, j1, j2, ...}, ...] acts as a symbolic version of Table, creating a list of expressions by replacing index 'i' with 'i1', 'i2', etc., index 'j' with 'j1', 'j2', etc., and so on. It is useful for generating lists of tensor components or related expressions."
SumDum::usage       = "SumDum[expr, {i1, i2}, kind] performs a numeric summation over all dummy index pairs of the specified 'kind' from i1 to i2.\nSumDum[expr, {i, i1, i2, ...}, ...] performs a symbolic summation by replacing index 'i' with 'i1', 'i2', etc., and summing the results.\nSumDum[expr, {kind1, kind2, ...}] performs a Kaluza-Klein style decomposition, summing over indices of 'kind1' by splitting them into indices of 'kind2', etc."

(* RuleUnique *)
RuleUnique::usage = "RuleUnique[lhs, rhs, cond] creates a delayed rule (lhs :> rhs /; cond) that automatically handles dummy indices on the right-hand side."

(* SyntaxCheck *)
SyntaxCheck::usage = "SyntaxCheck[expr] checks 'expr' for syntactical errors like free indices mismatch."

(* Flags *)
AutoFlag::usage            = "A flag that controls whether automatic post-processing, such as syntax checking and dummy index resetting, is performed on each output."
CoordinateBasisFlag::usage = "A flag that controls whether the basis for a specific kind is a coordinate basis. Use On[CoordinateBasisFlag] or On[CoordinateBasisFlag[kind]]."
MarkErrorFlag::usage       = "A flag that controls whether expressions with errors are marked in red. When On, expressions wrapped in ErrorT are displayed in red."
ResetDummiesFlag::usage    = "A flag that controls whether dummy indices in an expression are automatically reset to a canonical form in the output."
SyntaxCheckFlag::usage     = "A flag that controls whether automatic syntax checking is performed on each output to find errors like mismatched free indices."

(********************************************************************)
(********************** CovariantStructures.m ***********************)
(********************************************************************)

(***** Derivative Operators *****)
DerivativeOperatorQ::usage     = "DerivativeOperatorQ[opName] returns True if opName is a defined derivative operator, and False otherwise."
DefDerivativeOperator::usage   = "DefDerivativeOperator[covD, prtStr, kind, opts] defines a new derivative operator 'covD'. The print string 'prtStr' and the Kind 'kind' are optional, defaulting to the operator's name and DefaultKind, respectively. Options like TorsionFreeQ can be specified."
UndefDerivativeOperator::usage = "UndefDerivativeOperator[covD] removes the defined derivative operator 'covD' and all associated tensors like its connection coefficients and curvature tensors."

TorsionFreeQ::usage = "TorsionFreeQ[covD] is a property that is True if the derivative 'covD' is torsion-free, and False otherwise. It can be set as an option in DefDerivativeOperator."

(* Exported Symbols *)
(*
Gamma::usage     = ""  <-- Mathematica's builtin function
*)
GammaCD::usage   = "GammaCD[up, dn, dn] represents the connection coefficients (Christoffel symbols) associated with the default covariant derivative CD."
Ricci::usage     = "Ricci is a base name used to construct Ricci tensors for specific derivative operators. For the default derivative CD, the Ricci tensor is RicciCD."
RicciCD::usage   = "RicciCD[dn, dn] represents the Ricci tensor."
Riemann::usage   = "Riemann is a base name used to construct Riemann curvature tensors for specific derivative operators. For the default derivative CD, the Riemann tensor is RiemannCD."
RiemannCD::usage = "RiemannCD[up, dn, dn, dn] represents the Riemann curvature tensor."
Scalar::usage    = "Scalar is a base name used to construct Ricci scalars for specific derivative operators. For the default derivative CD, the Ricci scalar is ScalarCD."
ScalarCD::usage  = "ScalarCD[] represents the Ricci scalar, which is the trace of the Ricci tensor with respect to the metric."

(***** Metrics *****)
MetricQ::usage     = "MetricQ[metric] returns True if 'metric' is a defined metric tensor, and False otherwise."
DefMetric::usage   = "DefMetric[metric, prtStr, kind] defines a metric tensor. The optional arguments are 'prtStr' for the print string and 'kind' for the kind of the metric."
UndefMetric::usage = "UndefMetric[metric] removes the definition of the metric tensor 'metric' and all associated properties. It also updates related derivative operators and curvature tensors."

MetricSpaceQ::usage = "MetricSpaceQ[kind] returns True if the specified 'kind' is a metric space, and False otherwise."

(* Exported Symbols *)
Metricg::usage = "Metricg[dn, dn] represents the default metric tensor."

(***** Covariant Derivatives *****)
MetricCompatibleQ::usage = "MetricCompatibleQ[op, metric] returns True if the operator 'op' is compatible with the 'metric' (i.e., the covariant derivative of the metric with respect to the operator is zero), and False otherwise."
SetMetricCompatible::usage   = "SetMetricCompatible[covD, metric] declares that the covariant derivative 'covD' is compatible with the 'metric', meaning the covariant derivative of the metric with respect to 'covD' is zero. This also implies the volume form is covariantly constant."
ClearMetricCompatible::usage = "ClearMetricCompatible[covD, metric] removes the metric-compatibility property between the covariant derivative 'covD' and the 'metric'."

(***** DefaultKind *****)
SetDefaultKind::usage = "SetDefaultKind[kind] sets the default kind for all subsequent operations. This affects which indices, metrics, and derivatives are used by default."

(***** On/Off Flags *****)
EvaluateBDFlag::usage  = "A flag that controls whether basis derivatives (BD) are evaluated to components. Use On[EvaluateBDFlag] or On[EvaluateBDFlag[kind]]."
InitCTensorFlag::usage = "A flag that indicates whether the component tensor calculation environment (CTensor) is initialized. It is set to True by InitCTensor and False by ClearCTensor."
KdeltaFlag::usage      = "A flag that controls automatic index substitution rules involving Kdelta. When On, expressions like Kdelta[a, -b] T[b] are simplified to T[a], and the mixed metric g[a, -b] is converted to Kdelta[a, -b]."
MetricgFlag::usage     = "A flag that controls the definition of the default metric tensor Metricg. When On, Metricg is defined as a metric tensor and made compatible with the default covariant derivative CD."

(***** Absorb *****)
Absorb::usage  = "Absorb[expr, metric, opts] absorbs the rank-2 tensor 'metric' into 'expr' to raise or lower indices. Options like IndexQs, HeadQs, and CovDs control which indices, objects, and derivatives are affected."
Absorbg::usage = "Absorbg[expr, opts] is a shorthand for Absorb[expr, Metricg, opts], using the default metric tensor `Metricg`."

(***** PutMetric and PullOutMetric *****)
PutMetric::usage     = "PutMetric[expr, index, opts] explicitly raises or lowers the specified 'index' in 'expr' by multiplying with the appropriate metric tensor."
PullOutMetric::usage = "PullOutMetric[expr, opts] converts 'up/dn' states of indices in 'expr' to pre-defined ones, pulling out the corresponding metric tensors."

(***** Hodge Dual *****)
DualStar::usage = "DualStar[expr, {indices}] computes the Hodge dual of tensor 'expr' using 'indices'."

(********************************************************************)
(**************************** Tsimplify *****************************)
(********************************************************************)

DnUpPair::usage = "DnUpPair[expr, opts] converts all possible up-dn index pairs in 'expr' to dn-up pairs. This is equivalent to raising the lower index and lowering the upper index of each pair."
UpDnPair::usage = "UpDnPair[expr, opts] converts all possible dn-up index pairs in 'expr' to up-dn pairs. This is equivalent to lowering the upper index and raising the lower index of each pair."
 
BDinvgRule::usage         = "BDinvgRule[metric] provides a transformation rule for the basis derivative of an inverse metric. The metric defaults to Metricg."
EpsilonProductRule::usage = "EpsilonProductRule[kind] provides a rule to simplify the product of two Levi-Civita tensors for the specified kind. The kind defaults to DefaultKind."
KdeltaSumRule::usage      = "KdeltaSumRule[kind] provides a rule to replace the trace of a Kronecker delta (e.g., Kdelta[la,ua]) with the dimension of the specified kind. The kind defaults to DefaultKind."

TindexSort::usage = "TindexSort[expr] sorts the indices of a tensor expression into a canonical order based on its symmetries."                                             (* xSymmetryOf, xSort *)
Tsimplify::usage  = "Tsimplify[expr, opts] simplifies a tensor expression by applying symmetries and contracting indices. It is primarily designed for symmetric metrics."  (* metricStatesOf, xSymmetryOf, xSort, flattenObject *)

Verbose::usage = "Verbose is an option for functions like Tsimplify and InitCTensor. If set to True, it prints detailed information about the calculation steps or timing."

(********************************************************************)
(**************************** DiffForm ******************************)
(********************************************************************)

DefForm::usage   = "DefForm[f, p, opts] defines a p-form f.\nDefForm[f[indices...], p, sym, opts] defines a tensor-valued p-form with index symmetries given by the string 'sym'. The option PrintAs -> \"str\" can be used to set the output string."
Fdefine::usage   = "Fdefine is an alias for DefForm."
UndefForm::usage = "UndefForm[f] removes all definitions associated with the differential form f."

IP::usage        = "IP[vector, form] represents the interior product (or interior derivative) of a differential form 'form' with a vector 'vector'. The result is a form of one degree lower."
HodgeStar::usage = "HodgeStar[pForm] computes the Hodge dual of a p-form, resulting in an (n-p)-form, where n is the dimension of the manifold."
CoXD::usage      = "CoXD[pForm] represents the codifferential operator acting on a p-form."

CoXDRule::usage   = "CoXDRule[] provides a transformation rule that expresses the codifferential operator CoXD in terms of the exterior derivative XD and the Hodge star operator HodgeStar."
LDtoXDRule::usage = "LDtoXDRule[] provides a transformation rule for the Lie derivative LD based on Cartan's magic formula, expressing it in terms of the exterior derivative XD and the interior product IP."

ApplyXD::usage     = "ApplyXD[expr] explicitly applies the exterior derivative XD to an expression by expanding it in terms of basis derivatives BD with respect to the defined coordinates."
CollectForm::usage = "CollectForm[expr] collects terms in an expression that have the same differential form part, similar to how Collect works for standard algebraic expressions."
DegreeForm::usage  = "DegreeForm[expr] returns the degree of a differential form expression. It correctly computes the degree for base forms, exterior products (XP), exterior derivatives (XD), interior products (IP), Hodge duals (HodgeStar), and codifferentials (CoXD)."
ZeroDegreeQ::usage = "ZeroDegreeQ[expr] returns True if 'expr' is a 0-form (a scalar) or not a differential form expression, and False otherwise."
FtoC::usage        = "FtoC[expr] or FtoC[expr, {indices}] converts a differential form expression 'expr' into its corresponding antisymmetric indexed-tensor representation."

CoordRep::usage = "CoordRep[form, coSys] gives the coordinate representation of the differential 'form' using the coordinate system 'coSys'.\nCoordRep[form, n] gives the representation in a generic n-dimensional space, with the dimension defaulting to that of the Latin kind."

XPflattenRules::usage = "XPflattenRules is a list of transformation rules that flattens nested exterior products XP."

(* Flags *)
XDtoCDfrag::usage = "A flag that, when On, allows the exterior derivative XD to be converted into the default covariant derivative CD during tensor conversion via ToTensor, provided the connection is torsion-free. If Off, it is converted to the basis derivative BD."

(********************************************************************)
(************************ Tensor Components *************************)
(********************************************************************)

CDtoBD::usage         = "CDtoBD[expr, covD] expands all covariant derivatives 'covD' in 'expr' into base derivatives and connection coefficients. If 'covD' is omitted, the default covariant derivative CD is used."
CommuteCD::usage      = "CommuteCD[{a, b}, expr, covD] commutes the covariant derivatives with indices 'a' and 'b' in 'expr', expressing the result in terms of the Riemann and torsion tensors. If 'covD' is omitted, the default CD is used."
GammaToMetric::usage  = "GammaToMetric[expr, covD] expresses Christoffel symbols (connection coefficients) in 'expr' in terms of derivatives of the metric. If 'covD' is omitted, the default CD is used."
LDtoCD::usage         = "LDtoCD[expr, covD] converts the Lie derivative LD in 'expr' into covariant derivatives 'covD'. If 'covD' is omitted, the default torsion-free covariant derivative CD is used."
RiemannToGamma::usage = "RiemannToGamma[expr, curvRL, covD] expands curvature tensors (Riemann, Ricci, or Scalar) in 'expr' into derivatives of Christoffel symbols. 'curvRL' is a list of curvature tensors to expand. If 'curvRL' is omitted, all are expanded. If 'covD' is omitted, CD is used."

SetComponents::usage   = "SetComponents[tensor[indices], values] sets the components of a 'tensor'. 'values' can be a single expression for one component or a list/table for all components."
ClearComponents::usage = "ClearComponents[tensor[indices]] clears the components of a 'tensor'. If specific indices are given, only that component (and its symmetric equivalents) is cleared. If general indices are given, all components are cleared."

Pushforward::usage     = "Pushforward[fromT, fromCoSys, toCoSys, simpCmd] computes the pushforward of a vector or tensor 'fromT' from coordinate system 'fromCoSys' to 'toCoSys'. 'simpCmd' is an optional simplification function."
Pullback::usage        = "Pullback[fromT, fromCoSys, toCoSys, simpCmd] computes the pullback of a covector or tensor 'fromT' from coordinate system 'fromCoSys' to 'toCoSys'. 'simpCmd' is an optional simplification function."
PushTensor::usage      = "PushTensor[updnL, fromT, fromCoSys, toCoSys, forM, forN, simpCmd] transforms the tensor 'fromT' from 'fromCoSys' to 'toCoSys'. 'updnL' specifies the variance of indices. 'forM' and 'forN' are transformation rules."
Ttransform::usage      = "Ttransform[leftT, rightT, leftCoSys, rightCoSys, simpCmd] transforms the components of tensors bewteen two coordinate systems. 'simpCmd' is an optional simplification function."

CommutatorVectors::usage = "CommutatorVectors[vecList, kind] computes the commutator of vector fields given in 'vecList' for the manifold 'kind'. The default kind is DefaultKind."
LineElement::usage       = "LineElement[coSys, metric, simpCmd] generates the line element 'ds^2' for a given coordinate system 'coSys' and metric matrix. 'simpCmd' is an optional simplification function."

SetConstantMetric::usage   = "SetConstantMetric[diag, coSys, kind] sets up a flat spacetime with a constant metric. 'diag' can be a list of diagonal elements (e.g., {-1, 1, 1, 1}) or a full metric matrix. 'coSys' is the coordinate system. The default kind is DefaultKind."
ClearConstantMetric::usage = "ClearConstantMetric[kind] clears the definitions for a flat spacetime with a constant metric for the specified 'kind'. The default kind is DefaultKind."

(********************************************************************)
(**************************** Variation *****************************)
(********************************************************************)

VD::usage = "VD[arg, expr] represents the variational derivative of 'expr' with respect to 'arg'."

(***** Options for VD *****)
ByPartsVD::usage     = "An option for VD that, when set to True, enables integration by parts for specified derivative operators."
IndependentVD::usage = "An option for VD that specifies a list of tensors to be considered independent of the variation. The variational derivative of an independent tensor with respect to another tensor will be zero."

(********************************************************************)
(************************** Hypersurface ****************************)
(********************************************************************)

DefHypersurface::usage = "DefHypersurface[subKind, normSign] defines the geometric objects for a hypersurface. 'subKind' is a symbol for the kind on the hypersurface, and 'normSign' specifies the norm of the normal vector (-1 for spacelike, +1 for timelike)."
TangentialD::usage = "TangentialD[a, expr] represents the tangential derivative of 'expr' along the direction of the index 'a' on the hypersurface."

(***** Exported Symbols *****)
ExtrinsicK::usage = "ExtrinsicK[a, b] represents the extrinsic curvature tensor (or second fundamental form) of the hypersurface."
NormalV::usage = "NormalV[a] represents the normal vector to the hypersurface."
SubBasis::usage = "SubBasis[a, b] is the projector tensor that maps vectors from the ambient spacetime to the hypersurface."
SubCD::usage = "SubCD[a, T] represents the intrinsic covariant derivative on the hypersurface, compatible with the induced metric SubMetric."
SubMetric::usage = "SubMetric[a, b] represents the induced metric (or first fundamental form) on the hypersurface."

(********************************************************************)
Begin["`Private`"]

(************************ Index Notation ****************************)
<< mGRG`STensor`IndexNotation`

(*********************** Covariant Structures ***********************)
<< mGRG`STensor`CovariantStructures`

(***************************** Tsimplify ****************************)
<< mGRG`STensor`xTensorCustom`
<< mGRG`STensor`Tsimplify`

(************************ Differential Forms ************************)
<< mGRG`STensor`DiffForm`  (* Experimental *)

(************************ Tensor Components *************************)
<< mGRG`STensor`TensorComponents`

(**************************** Variation *****************************)
<< mGRG`STensor`Variation`  (* Experimental *)

(************************** Hypersurface ****************************)
<< mGRG`STensor`Hypersurface` (* Experimental *)

(********************************************************************)

initSTensor[] := (
        (***** set DefaultKind, and define CD, Metricg, Structuref *****)
        (* initialize *)
        getDerOperators[DefaultKind] = {};  (* See DefKind[] *)
        definedDerivativeList        = {};  (* See derivativeRules and absorb Kdelta *)
        nonTensorList                = {};  (* for non-Tensorial indexed objects *)

        flagTable[MetricgFlag] = True;
        SetDefaultKind[DefaultKind];  (* NB: The default symmetric 'Metricg' will be defined. *)
        reservedNameList = Join[reservedNameList, {Metricg}];

        (* option for specifying covariant derivatives *)
        reservedNameList = Join[reservedNameList, {CovDs}];

        (* symbols for the covariant derivatives *)
        reservedNameList = Join[reservedNameList, {
            Gamma,   Ricci,   Riemann,   Scalar,
            GammaCD, RicciCD, RiemannCD, ScalarCD
        }];

        (***** initialize Flag Table *****)
        flagTable[EvaluateBDFlag[DefaultKind]] = False;

        flagTable[InitCTensorFlag] = False;
		flagTable[KdeltaFlag]      = True;  (* absorb Kdelta *)
        flagTable[MetricgFlag]     = True;  (* Metricg is defined on DefaultKind *)

        (***** Predefined Operators *****)
		defineOperator[BD, "\[PartialD]", CD, All];
        derivativeRules[BD];
        BD/: MakeBoxes[BD[arg_, expr___], StandardForm] := interpretBox[BD[arg, expr],
                Module[{kind = IndexToKind[arg]},
                    TemplateBox[
                        {
                            If[kind =!= NonKind && UpIndexQ[arg], SuperscriptBox, SubscriptBox][
                                If [kind === NonKind,  (* NB: if MemberQ[{t,x,y,...}, arg] == True, IndexToKind[arg] => NonKind *)
                                    OverscriptBox["\[PartialD]", "^"],
                                (* else *)
                                    If [CoordinateBasisQ[kind], "\[PartialD]", OverscriptBox["\[PartialD]", "^"]]
                                ], First @ indexCharSpace[arg]
                            ],
                            MakeBoxes[expr, StandardForm]
                        }, "RowDefault"
                    ]
                ]
            ];
        BD/: MakeBoxes[BD[kind_][arg_, expr___], StandardForm] := interpretBox[BD[arg, expr],
                TemplateBox[
                    {
                        If [kind =!= NonKind && UpIndexQ[arg], SuperscriptBox, SubscriptBox][
                            If [kind === NonKind,
                                RowBox[{OverscriptBox["\[PartialD]", "^"], "[", ToString[kind], "]"}],
                            (* else *)
                                If [CoordinateBasisQ[kind],
                                    "\[PartialD]" <> "[" <> ToString[kind] <> "]",
                                (* else *)
                                    RowBox[{OverscriptBox["\[PartialD]", "^"], "[", ToString[kind], "]"}]
                                ]
                            ], First @ indexCharSpace[arg]
                        ],
                        MakeBoxes[expr, StandardForm]
                    }, "RowDefault"
                ]
            ];

        reservedNameList = Join[reservedNameList, {BD}];

        (* LD *)
        defineOperator[LD, "\[ScriptCapitalL]", LD];  (* NB: The kind of LD is that of the first argument. *)
        derivativeRules[LD, vectorNameQ];

        (* Initialize numAntisymmetricMetrics which is used in DefMetric, UndefMetric, and indexSortObject. *)
        If [!ValueQ[loadedSTensor], numAntisymmetricMetrics = 0];

        (***** End of initSTensor *****)
        reservedNameList = DeleteDuplicates[reservedNameList];
        loadedSTensor = True;  (* guard reloding *)
    )
initSTensor[];

(********************************************************************)
End[] (* End Private Context *)
EndPackage[]
