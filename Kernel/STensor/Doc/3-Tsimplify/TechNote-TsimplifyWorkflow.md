# Tech Note: Tsimplify 사용 워크플로 (Tsimplify Usage Workflow)

텐서 표현식을 대칭성과 인덱스 축약을 이용하여 단순화하는 Tsimplify의 사용법을 다룬다. 인덱스 쌍 재배열(DnUpPair/UpDnPair), 인덱스 정렬(TindexSort), 단순화 규칙(BDinvgRule, KdeltaSumRule, EpsilonProductRule), 그리고 Tsimplify 자체의 실전 워크플로를 포함한다.

> 자세한 함수 설명은 `01-IndexPairReordering.md`, `02-TindexSort.md`, `03-SimplificationRules.md`, `04-Tsimplify.md` 참고.

---

## 1. 개요 -- Tsimplify 모듈의 구성

Tsimplify 모듈은 텐서 표현식의 단순화를 위한 도구 모음이다. 각 도구의 역할은 다음과 같다:

| 도구 | 역할 | 적용 방식 |
|------|------|---------|
| DnUpPair | up-dn 인덱스 쌍을 dn-up으로 재배열 | 함수 호출 |
| UpDnPair | dn-up 인덱스 쌍을 up-dn으로 재배열 | 함수 호출 |
| TindexSort | 대칭성 기반 인덱스 표준 정렬 | 함수 호출 |
| BDinvgRule | 역 계량 텐서의 기저 도함수 변환 | `/. BDinvgRule[]` |
| KdeltaSumRule | 크로네커 델타 trace → 차원 | `/. KdeltaSumRule[]` |
| EpsilonProductRule | Epsilon 텐서 곱 → 델타 조합 | `/. EpsilonProductRule[]` |
| Tsimplify | 종합 단순화 (TensorReduce 기반) | 함수 호출 |

핵심 관계: **TindexSort**는 단일 텐서의 인덱스만 정렬하고, **Tsimplify**는 여러 텐서의 곱과 합까지 포함하여 종합적으로 단순화한다. 단순화 규칙들은 Tsimplify가 처리하지 않는 특수한 변환을 담당한다.

---

## 2. 인덱스 쌍 재배열 워크플로

DnUpPair와 UpDnPair는 축약된 인덱스 쌍의 up/dn 순서를 재배열한다. 이는 계량 텐서를 이용한 인덱스 올리기/내리기의 효과를 가진다.

```wolfram
<< mGRG`STensor`
Tdefine[Z, "*"]; Tdefine[v, 1]

(* up-dn 쌍을 dn-up으로 *)
Z[ub, lc, ld, lb]
DnUpPair[%]
(* Z^a_cda → Z_acd^a *)

(* dn-up 쌍을 up-dn으로 *)
Z[lb, lc, ld, ub]
UpDnPair[%]
(* Z_acd^a → Z^a_cda *)
```

### 연산자와 함께 사용

계량 텐서에 대해 공변 도함수가 아니면 의미가 없다. 그러나 공변 도함수가 아님에도 동작하게 하려면 `CovDs` 옵션을 사용한다.

```wolfram
CD[ua, CD[ub, Z[la, lb, lc, ud]]]
DnUpPair[%]
(* ∇^a∇^bZ_abc^d → ∇_a∇_bZ^ab_c^d *)

(* BD 포함 *)
CD[ua, BD[la, Z[ub, ld, le, lf]]] × v[lb]
DnUpPair[%]
(* ∇_a ∂^aZ^b_def v_b  - 인덱스는 b는 변경 안 됨 *)

DnUpPair[%%, CovDs -> {CD, BD}]
(* ∇_a ∂^aZ_bdef v^b  - 인덱스 a와 b 모두 변경됨 *)
```

---

## 3. TindexSort를 이용한 표준화

TindexSort는 각 텐서의 대칭성에 따라 인덱스를 표준 순서로 정렬한다. Tsimplify보다 가볍고 빠르다.

```wolfram
Tdefine[A, "-ba"]; Tdefine[S, "ba"]

(* 반대칭 텐서: 인덱스 교환 시 부호 변환 *)
{A[la, lb], A[lb, la], A[ua, la]}
TindexSort /@ %
(* {A_ab, -A_ab, 0} *)

(* 대칭 텐서: 인덱스 교환 시 동일 *)
{S[la, lb], S[lb, la]}
TindexSort /@ %
(* {S_ab, S_ab} *)
```

### 성분 인덱스에 대한 정렬

```wolfram
{A[-2, -1], A[1, -1], A[1, 1], A[-1, -1], A[2, 1]}
TindexSort /@ %
(* {-A_12, -A_1^1, 0, 0, -A^12} *)
```

### 연산자 인덱스의 대칭

BD 연산자의 연속 미분은 인덱스 교환에 대해 대칭이다. CD도 torsion-free인 경우 대칭이다.

```wolfram
Tdefine[f[]]

(* BD: 항상 대칭 *)
{BD[lb, ua, A[ub, la]], BD[ub, la, A[lb, ua]], BD[lb, la, A[ub, ua]]}
TindexSort /@ %
(* {-∂_b∂^aA_a^b, -∂^b∂_aA^a_b, 0} *)

(* CD: torsion-free이면 대칭 *)
CD[lb, la, f[]]
% // TindexSort
(* ∇_a∇_bf *)
```

---

## 4. 단순화 규칙 활용

### BDinvgRule -- 역 계량 텐서의 도함수

역 계량 텐서 $g^{bc}$의 기저 도함수를 $\partial_a g_{de}$로 변환한다.

$$\partial_a g^{bc} = -g^{bd} g^{ce} \partial_a g_{de}$$

```wolfram
{BD[la, Metricg[ub, uc]], BD[la, Metricg[lb, lc]]}
% /. BDinvgRule[]
(* {-∂_a g_de g^bd g^ce, ∂_a g_bc} *)
```

이 규칙은 Tsimplify와 함께 사용하면 효과적이다:

```wolfram
Tdefine[A, "-ba"]

(* A^[ab] ∂_a g_pq ∂_b g^pq = 0 을 증명 *)
expr = {A[ua, ub] × BD[la, Metricg[lc, ld]] × BD[lb, Metricg[uc, ud]],
        A[ua, ub] × CD[le, BD[la, Metricg[lc, ld]]] ×
         CD[ue, BD[lb, Metricg[uc, ud]]]}
Tsimplify[expr]
(* 변화 없음. 단순화에 실패 *)

(* 규칙을 적용한 후의 Tsimplify 연산 *)
Tsimplify[expr /. BDinvgRule[]]
(* {0, 0} *)
```

### KdeltaSumRule -- 크로네커 델타의 trace

```wolfram
(* 축약된 Kdelta → 차원 *)
Kdelta[la, ua]
% /. KdeltaSumRule[]
(* GetDimension[Latin] *)

(* 다른 Kind 지정 *)
Kdelta[lA, uA]
% /. KdeltaSumRule[Capital]
(* GetDimension[Capital] *)
```

### EpsilonProductRule -- Epsilon 텐서 곱

두 Epsilon 텐서의 곱을 크로네커 델타의 반대칭 조합으로 전개한다. DualStar의 이중 적용 결과를 단순화할 때 유용하다.

```wolfram
SetDimension[4]; SetSig[1];
Tdefine[A, "*-"]

(* DualStar 이중 적용 → EpsilonProductRule로 단순화 *)
DualStar[A[ua, ub], {lc, ld}]
DualStar[%, {ue, uf}]
% /. EpsilonProductRule[]
% // TindexSort
(* -A^ef *)

(* rank-3 텐서에 대한 DualStar *)
DualStar[A[ua, ub, uc], {ld}]
DualStar[%, {ue, uf, ug}]
% /. EpsilonProductRule[]
% // TindexSort
(* A^efg *)

ClearDimension[]; ClearSig[];
```

---

## 5. Tsimplify 핵심 워크플로

### 기본 사용법

Tsimplify는 대칭성을 이용하여 텐서 표현식을 최소 표현으로 단순화한다.

```wolfram
Tdefine[A, "-ba"]; Tdefine[S, "ba"]; Tdefine[v, "a"]
Tdefine[B, "ab"]; Tdefine[F, "-ba"]; Tdefine[f[]]

(* 반대칭 × 대칭 = 0 *)
A[la, lb] × S[ua, ub]
% // Tsimplify
(* 0 *)

(* A^[ab] v_a v_b = 0 *)
A[ua, ub] × v[la] × v[lb]
% // Tsimplify
(* 0 *)

(* A^[ab] ∇_a ∇_b f = 0 (torsion-free) *)
A[ua, ub] × CD[la, f[]] × CD[lb, v[uc]]
% // Tsimplify
(* 0 *)
```

### CovDs 옵션

BD는 기본적으로 공변 연산자가 아니지만 `CovDs` 옵션으로 포함시킬 수 있다.

```wolfram
expr1 = S[la, ub] × CD[lc, A[ua, lb]]
expr2 = S[la, ub] × BD[lc, A[ua, lb]]

Tsimplify[expr1]
(* 0 *)

Tsimplify[expr2]
(* ∂_cA^a_b S_a^b  — BD 내부는 처리 안 됨 *)

Tsimplify[expr, CovDs -> {CD, BD}]
(* 0  — BD를 공변연산자로 취급하여 단순화 *)
```

### TorsionFreeQ에 따른 동작

```wolfram
(* Torsion이 없으면 A^[ab] ∇_a ∇_b f = 0 *)
TorsionFreeQ[CD] = False;
expr = {CD[la, lb, f[]] × A[ua, ub],
        CD[la, lb, S[lc, ld]] × A[ua, ub]}
expr // Tsimplify
(* {A_ab ∇^a∇^bf, A_ab ∇^a∇^bS_cd} *)

TorsionFreeQ[CD] = True;
expr // Tsimplify
(* {0, A_ab ∇^a∇^bS_cd} *)
```

### 여러 Kind에서의 Tsimplify

다른 Kind의 인덱스가 섞인 표현식에서도 동작한다. 같은 Kind 내의 인덱스 쌍에 대해서만 축약이 적용된다.

```wolfram
SetDefaultKind[Capital]
Tdefine[A[lA, lB], "-ba"]; Tdefine[S[lA, lB], "ba"]

{S[la, ub] × CD[lC, A[ua, lb]],       (* 같은 Latin Kind — 0 아님 *)
 S[la, uB] × CD[lC, A[ua, lB]],       (* cross-Kind — 0 아님 *)
 S[lA, uB] × CD[lC, A[uA, lB]]}       (* 같은 Capital Kind — 0 *)
% // Tsimplify
(* {∇_CA^a_b S_a^b, ∇_CA^a_A S_a^A, 0} *)

SetDefaultKind[Latin]
```

### Riemann 텐서 예제

```wolfram
(* Riemann 텐서의 대칭성을 이용한 단순화 *)
RiemannCD[la, lb, ld, le] × S[ua, ue] + RiemannCD[lb, le, lc, ld] × S[ue, uc]
% // Tsimplify
(* -2 R_badc S^ac *)
```

### Tscalar를 포함한 표현

```wolfram
expr = Tscalar[A[uc, ud] × A[lc, ld]]^2 Tscalar[A[la, lb] × A[ub, ua]]
Tsimplify[expr]
(* (A_ab A^ba)(A_cd A^cd)^2  - 변화 없음 *)

(* HeadQs 옵션으로 조정 *)
Tsimplify[expr, HeadQs -> {ObjectQ}]
(* -(A_ab A^ab)^3 *)
```

### 반복된 성분 인덱스

반대칭 텐서에서 반복된 성분 인덱스는 0이다.

```wolfram
Tdefine[H, "3-"]

H[2, 1, 3] // Tsimplify
(* -H^123 *)

H[1, 1, 3] // Tsimplify
(* 0 *)

H[1, 3, 1] // Tsimplify
(* 0 *)
```

---

## 6. Tsimplify의 한계와 보완 전략

### Tsimplify가 처리하지 못하는 경우

1. **제1 비앙키 항등식** ($R_{[abc]d} = 0$): Riemann 텐서의 대칭성 생성자(`-bacd`, `-abdc`, `+cdab`)에 포함되지 않으므로 Tsimplify만으로는 증명할 수 없다.

2. **$\partial_a g^{bc}$ 형태**: 역 계량 텐서의 도함수는 Tsimplify가 직접 처리하지 않는다. `BDinvgRule`을 먼저 적용해야 한다.

3. **비대칭 계량 텐서**: Tsimplify는 대칭 계량 텐서만을 지원한다.

### 보완 전략

| 상황 | 보완 방법 |
|------|---------|
| $\partial_a g^{bc}$ 포함 | `expr /. BDinvgRule[]` 후 `Tsimplify` |
| $\delta^a_a$ → 차원 | `expr /. KdeltaSumRule[]` |
| $\epsilon \cdot \epsilon$ 곱 | `expr /. EpsilonProductRule[]` |
| Riemann → Gamma 전개 | `RiemannToGamma[expr]` |
| $\nabla$ → $\partial + \Gamma$ 전개 | `CDtoBD[expr]` |
| $\Gamma$ → $\partial g$ 전개 | `GammaToMetric[expr]` |

### 실전 조합 예제

```wolfram
(* A^[ab] ∂_a g_pq ∂_b g^pq = 0 증명 *)
Tdefine[A, "-ba"]

expr = A[ua, ub] × BD[la, Metricg[lc, ld]] × BD[lb, Metricg[uc, ud]]

(* Step 1: BDinvgRule 적용 *)
expr /. BDinvgRule[]

(* Step 2: Tsimplify로 단순화 *)
Tsimplify[%]
(* 0 *)
```

---

## 요약

1. **DnUpPair/UpDnPair는 축약된 인덱스 쌍의 up/dn 순서를 재배열한다.** `CovDs` 옵션으로 BD 등을 포함할 수 있다.
2. **TindexSort는 단일 텐서의 인덱스를 대칭성에 따라 표준 정렬한다.** 반대칭 텐서의 trace가 0인지 확인한다.
3. **BDinvgRule은 역 계량 텐서의 기저 도함수를 변환한다.** Tsimplify 전에 적용한다.
4. **KdeltaSumRule은 크로네커 델타의 trace를 차원으로 대체한다.**
5. **EpsilonProductRule은 Epsilon 텐서 곱을 델타 조합으로 전개한다.** DualStar 이중 적용 후 사용한다.
6. **Tsimplify는 대칭 계량 텐서 기반의 종합 단순화 함수이다.** TensorReduce를 내부적으로 활용한다.
