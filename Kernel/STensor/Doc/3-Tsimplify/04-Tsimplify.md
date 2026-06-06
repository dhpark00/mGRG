# Tsimplify — 텐서 단순화 (Tsimplify)

`mGRG`STensor`` 패키지의 `Tsimplify.m`에서 제공하는 핵심 텐서 단순화 함수이다.

---

### Tsimplify

#### 함수 시그니처

```wolfram
Tsimplify[expr, opts]
```

#### 설명 (Details)

Mathematica의 내장 함수 `TensorReduce`를 이용하여 텐서 표현식에 인덱스 대칭을 적용하고 축약하여 단순화한다.

- 옵션으로 `HeadQs`와 `CovDs`가 있다.
- 내부적으로 `ExpandObject`로 텐서 표현을 전개한 후, `ForEachTerm`을 이용하여 각각의 항을 단일항의 조합으로 분해하고, 각 항을 단순화한다.
- 대칭 계량 텐서만을 다룬다.
- 서로 다른 Kind의 인덱스를 가진 텐서 곱에서도 동작한다. 같은 Kind 내에서만 축약이 적용된다.
- `TorsionFreeQ[CD]`가 `True`이면 CD의 연속 미분에서 인덱스 교환이 가능하다 ($A^{[ab]} \nabla_a \nabla_b f = 0$).

#### 예제 (Examples)

##### 단일 텐서

```wolfram
Tdefine[T, "*"]; Tdefine[f[]]; Tdefine[v, "a"]
Tdefine[A, "-ba"]; Tdefine[B, "ab"]; Tdefine[S, "ba"]

(* 반대칭 텐서의 대칭성 적용 *)
{A[ua, ub], A[lb, ub], A[lb, la], S[ub, ua], S[ua, la]}
% // Tsimplify
(* {A^ab, 0, -A_ab, S^ab, S^a_a} *)

(* 성분 인덱스 *)
{S[1, 1], A[1, 1], A[1, -1]}
% // Tsimplify
(* {S^11, 0, -A_1^1} *)
```

##### 연산자가 포함된 표현

```wolfram
(* CD 연산자 *)
{CD[la, lb, A[ub, ua], CD[la, lb, S[ua, ub]], CD[la, lc, A[ua, ub]]}
% // Tsimplify
(* {-∇_a∇_bA^ab, ∇_a∇_bS^ab, -∇_a∇_cA^ba} *)

(* BD 연산자 — 기본적으로 Tsimplify 대상 *)
{BD[la, lb, A[ua, ub]], BD[ua, lb, A[la, ub]]}
% // Tsimplify
(* {0, ∂^a∂_bA_a^b *)

(* CovDs 옵션 *)
expr = S[la, ub] × BD[lc, A[ua, lb]]
Tsimplify[expr]
(* 단순화 없음 *)

Tsimplify[expr, CovDs -> {CD, BD}]
(* 0 -- CovDs 옵션으로 BD 포함 시 추가 단순화 *)
```

##### 두 텐서의 곱

```wolfram
(* 반대칭 × 대칭 = 0 *)
A[la, lb] × S[ua, ub]
% // Tsimplify
(* 0 *)

(* 여러 텐서와 연산자의 조합 *)
{S[la, lb] × BD[lc, A[ua, ub]],
 S[la, ub] × CD[lc, A[ua, lb]],
 S[la, ub] × BD[lc, A[ua, lb]]}
% // Tsimplify
(* {0, 0, ∂_cA^a_b S_a^b} *)
```

##### TorsionFreeQ에 따른 동작

```wolfram
(* Torsion이 있는 경우 *)
TorsionFreeQ[CD] = False;
expr = {CD[la, lb, f[]] × A[ua, ub],
        CD[la, lb, S[lc, ld]] × A[ua, ub]}
expr // Tsimplify
(* {A_ab ∇^a∇^bf, A_ab ∇^a∇^bS_cd}  — 0이 아님 *)

(* Torsion이 없는 경우 *)
TorsionFreeQ[CD] = True;
expr // Tsimplify
(* {0, A_ab ∇^a∇^bS_cd} *)
```

##### 여러 Kind

```wolfram
SetDefaultKind[Capital]
Tdefine[A[lA, lB], "-ba"]; Tdefine[S[lA, lB], "ba"]

(* 같은 Kind 내 축약 *)
{S[la, ub] × CD[lc, A[ua, lb]],
 S[la, uB] × CD[lc, A[ua, lB]],
 S[lA, uB] × CD[lC, A[uA, lB]]}
% // Tsimplify
(* {∇_cA^a_b S_a^b, ∇_cA^a_A S_a^A, 0} *)

SetDefaultKind[Latin]  (* 기본 설정으로 복귀 *)
```

##### 세 개 이상의 텐서

```wolfram
{A[ua, ub] × v[la] × v[lb],
 A[ua, lb] × v[la] × v[ub]}
% // Tsimplify
(* {0, 0} *)

{A[la, lb] × B[ua, lc] × B[ub, uc],
 A[la, lb] × B[ua, lc] × B[ub, ud]}
% // Tsimplify
(* {0, A_ab B^a_c B^bd} *)

{A[ua, lb] × BD[la, f[]] × BD[ub, f[]],
 A[ua, lb] × CD[la, v[lc]] × CD[ub, v[uc]]}
% // Tsimplify
(* {0, 0} *)
```

##### 합이 포함된 표현 (Multi-Terms)

```wolfram
(* 동일항 합산 *)
{B[la, ua] + B[ua, la],
 CD[la, lb, B[ua, ub]] + CD[lc, ld, B[uc, ud]]}
% // Tsimplify
(* {2 B_a^a, 2 ∇_a∇_bB^ab} *)

(* Riemann 텐서 포함 *)
{S[la, uc] × S[lc, lb] + S[le, la] × S[lb, ue],
 RiemannCD[la, lb, ld, le] × S[ua, ue]
  + RiemannCD[lb, le, lc, ld] × S[ue, uc]}
% // Tsimplify
(* {2 S_ac S_b^c, -2 R_badc S^ac} *)
```

##### HeadQs 옵션

```wolfram
expr = Tscalar[A[uc, ud] × A[lc, ld]]^2 Tscalar[A[la, lb] × A[ub, ua]]
Tsimplify[expr]
(* 변화 없음 *)

(* 스칼라 표현에도 작용하도록 HeadQs 옵션 조정 *)
Tsimplify[expr, HeadQs -> {ObjectQ}]
(* -Tscalar[A[la, lb] × A[ua, ub]]^3 *)
```

#### 참고 (See Also)

`TindexSort`, `DnUpPair`, `UpDnPair`, `BDinvgRule`, `KdeltaSumRule`, `EpsilonProductRule`, `ExpandObject`
