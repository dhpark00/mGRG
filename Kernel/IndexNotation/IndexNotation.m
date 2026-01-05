(* ::Package:: *)
(* :Context: mGRG`IndexNotation` *)
(* :Author: Park, Dal-Ho *)
(* :Summary: Core implementation for manipulating indexed objects. *)
(* :Package Version: 2025.12 *)
(* :Mathematica Version: 12.2+ *)

(* Implementation Note:
  - Symmetries should NOT mix dn/up, and different kind of indices. (See checkSymKindDnup.)
  - Shapes of IndexedObjects are defined by IndexKind and Dn/Up for each indices.
  - NB: SetIndices[..] 또는 AddIndices[..] 함수가 실행되면 l* 또는 u* 형태의 심볼에 설정되었던 모든 기억이 지워짐.
  - NB: Due to the ResetDummies, the Plus expressions are RE-ORDERED in the Output phase, which are in general different from the internal order.
    So, to assign the output to a variable the assignment command should be positioned after the running of the previous command, e.g.
        prevCmd
        var = %
 *)
(* Long-term TODO:
  - Introduce TP[obj1, obj2, ...] for non-commutating or anti-commutating indexed objects
 *)

(********************************************************************)
BeginPackage["mGRG`IndexNotation`", {"mGRG`mPerm`"}]

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

(***** Kind *****)

CheckKind::usage    = "CheckKind[kind] returns True if 'kind' is a defined kind, and returns False with an error message otherwise. It can also be applied to a list of kinds, returning True only if all kinds in the list are defined."
DefinedKindQ::usage = "DefinedKindQ[kind] returns True if 'kind' is a defined kind."
DefKind::usage      = "DefKind[kind, {\"a\", \"b\", ...}] defines a new Kind with a set of indices."
UndefKind::usage    = "UndefKind[kind] removes the definition of the specified kind."

GetDimension::usage = "GetDimension[kind] returns the dimension of the specified kind."

KindMatchQ::usage = "KindMatchQ[kind1, kind2] returns True if the two kinds are compatible, and False otherwise. The special kind 'All' is compatible with any other kind, while 'NonKind' is not compatible with any kind."

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

(* Index Symmetries *)
GetSymmetry::usage = "GetSymmetry[tensor] returns the symmetry generator set of a defined tensor."
SetSymmetry::usage = "SetSymmetry[tensor, \"symmetryString\"] sets the index symmetry for a defined tensor."

(***** Exported Symbols *****)

(* Wrappers *)
ErrorT::usage  = "ErrorT[expr] is a wrapper for expressions with errors, causing expr to be displayed in red."
Tscalar::usage = "A wrapper for scalar quantities to protect them from tensor operations."

(* Operator Types *)
CD::usage = "CD[index, expr] represents an operator like the covariant derivative operator acting on 'expr'."
LD::usage = "LD[vector, expr] represents an operator like the Lie derivative with respect to 'vector' acting on 'expr'."
XD::usage = "XD[expr] represents an operator like the exterior derivative"
XP::usage = "XP[args,..] represents an operator like the exterior product"

(* Option for Tdefine and Fdefine *)
PrintAs::usage = "An option for Tdefine and DefForm that specifies the string to be used when displaying the tensor or form."

(********** Utils for indexed objects **********)

ExpandObject::usage  = "ExpandObject[expr] expands expressions containing indexed objects, distributing products over sums."
FreeObjectQ::usage   = "FreeObjectQ[expr] returns True if 'expr' is free of indexed objects, and False otherwise."
ForEachTerm::usage   = "ForEachTerm[expr, f, args...] applies the function 'f' to each term of a sum or equation in 'expr'."
ForEachObject::usage = "ForEachObject[expr, hOptL, f, args...] applies 'f' to each indexed object in 'expr' that satisfies the head options 'hOptL'."
SplitTerm::usage     = "SplitTerm[term, hOptL] splits a term into {scalarPart, tensorPart}, separating indexed objects defined by 'hOptL' from other factors."

(********************************************************************)
Begin["`Private`"]

If[$VersionNumber < 12.2, Throw @ Message[General::version, "10.4", $VersionNumber]]

(**************************** Utilities *****************************)
<< mGRG`IndexNotation`Utilities`

(***************************** Indices ******************************)
<< mGRG`IndexNotation`Indices`

(************************** IndexedObject ***************************)
<< mGRG`IndexNotation`IndexedObjects`

(********************************************************************)

initIndexNotation[] := (
        (***** Default Options *****)
        Options[HeadQs]  = {HeadQs  -> {IndexedObjectQ}};  (* for selecting Heads to exclude ScalarFunctions. *)
        Options[IndexQs] = {IndexQs -> {True&}};           (* for selecting indices *)
        reservedNameList = {HeadQs, IndexQs};

        (* When reloading, Unprotect and TagUnset previously introduced index symbols *)
        If [ValueQ[loadedIndexNotation], setIndices[{}, #]& /@ definedKindList];

        (***** Indices *****)
        Unprotect[DefaultKind];
        DefaultKind := Latin;  (* for ValidIndexQ *)
        Protect[DefaultKind];

        definedKindList = {};        (* initialize *)
        DefKind[Latin, Alphabet[]];  (* pre-defined Kind *)
        reservedNameList = Join[reservedNameList, {All, Latin}];

        (***** Defining Indexed Objects *****)
        reservedNameList = Join[reservedNameList, {C, D, E, I, N, O}];  (* Protected names in Mathematica *)
        reservedNameList = Join[reservedNameList, {CD, LD, XD, XP}];    (* Operator Types *)
        reservedNameList = Join[reservedNameList, {Tscalar, ErrorT}];   (* Predefined ScalarFunction and ErrorT *)

        (***** End of initIndexNotation *****)
        reservedNameList = DeleteDuplicates[reservedNameList];
        loadedIndexNotation = True;
    )
initIndexNotation[];

(********************************************************************)
End[] (* End Private Context *)
EndPackage[]
