# Tsimplify — 단순화 규칙 (BDinvgRule, KdeltaSumRule, EpsilonProductRule)

`mGRG`STensor`` 패키지의 `Tsimplify.m`에서 제공하는 단순화 변환 규칙들이다.

---

### BDinvgRule

#### 함수 시그니처

```wolfram
BDinvgRule[metric]
```

#### 설명 (Details)

역 계량 텐서(inverse metric)의 기저 도함수(basis derivative)에 대한 변환 규칙을 제공한다. 인자를 생략하면 기본 계량 텐서 `Metricg`에 대한 규칙이다.

- `/.` (ReplaceAll)로 적용하여 사용한다.
- $\partial_a g^{bc} = -g^{bd} g^{ce} \partial_a g_{de}$ 관계를 이용한다.
- 특정 rank-2 대칭 텐서에 대한 규칙으로도 동작할 수 있다.

#### 예제 (Examples)

```wolfram
(* 기본 Metricg에 대한 규칙 *)
{BD[la, Metricg[ub, uc]], BD[la, Metricg[lb, lc]]}
% /. BDinvgRule[]
(* {-∂_a g_de g^bd g^ce, ∂_a g_bc} *)

(* 특정 계량 텐서에 대한 규칙 *)
{BD[la, Metricg[ub, uc]], BD[la, Metricg[lb, lc]]}
% /. BDinvgRule[Metricg]
(* {-∂_a g_de g^bd g^ce, ∂_a g_bc} *)
```

#### 참고 (See Also)

`Tsimplify`, `Metricg`, `BD`, `GammaToMetric`

---

### KdeltaSumRule

#### 함수 시그니처

```wolfram
KdeltaSumRule[kind]
```

#### 설명 (Details)

크로네커 델타의 trace(축약)를 해당 Kind의 차원으로 대체하는 변환 규칙을 제공한다. `kind`를 생략하면 `DefaultKind`에 대해 동작한다.

- `/.` (ReplaceAll)로 적용하여 사용한다.
- 축약되지 않은 크로네커 델타 (예: `Kdelta[la, ub]`)에는 적용되지 않는다.
- 축약된 크로네커 델타 (예: `Kdelta[la, ua]`)를 `GetDimension[kind]`로 대체한다.
- 특정 Kind를 지정하면 해당 Kind의 인덱스에만 적용된다.

#### 예제 (Examples)

```wolfram
(* 축약되지 않은 경우 — 변화 없음 *)
Kdelta[la, ub]
% /. KdeltaSumRule[]
(* δ_a^b → δ_a^b *)

(* 축약된 경우 — 차원으로 대체 *)
Kdelta[la, ua]
% /. KdeltaSumRule[]
(* δ^a_a → GetDimension[Latin] *)

Kdelta[ua, la]
% /. KdeltaSumRule[]
(* δ^a_a → GetDimension[Latin] *)

(* 다른 Kind의 인덱스 — 기본 규칙으로는 변화 없음 *)
Kdelta[lA, uA]
% /. KdeltaSumRule[]
(* δ^A_A — DefaultKind가 아니므로 변화 없음 *)

(* 특정 Kind 지정 *)
Kdelta[lA, uA]
% /. KdeltaSumRule[Capital]
(* GetDimension[Capital] *)
```

#### 참고 (See Also)

`Kdelta`, `GetDimension`, `SetDimension`, `EpsilonProductRule`

---

### EpsilonProductRule

#### 함수 시그니처

```wolfram
EpsilonProductRule[kind]
```

#### 설명 (Details)

두 Levi-Civita 텐서의 곱을 단순화하는 변환 규칙을 제공한다. `kind`를 생략하면 `DefaultKind`에 대해 동작한다.

- `/.` (ReplaceAll)로 적용하여 사용한다.
- 같은 Kind의 두 Epsilon 텐서의 곱을 크로네커 델타의 반대칭 조합으로 전개한다.
- 다른 Kind의 Epsilon 텐서 곱에는 적용되지 않는다.
- 차원(`GetDimension`)과 부호(`GetSig`)가 결과에 반영된다.
- `TindexSort`와 함께 사용하면 최종 단순화가 가능하다.
- 공식: R. M. Wald, *General Relativity*, 식 (B.2.14)
$$
  \epsilon^{a_1 \dots a_j a_{j+1} \dots a_n} \epsilon_{a_1 \dots a_j b_{j+1} \dots b_n} = (-1)^s j! (n-j)! \delta^{[a_{j+1}}_{b_{j+1}} \dots \delta^{a_n]}_{b_n}
$$

#### 예제 (Examples)

```wolfram
Format[GetSig[Latin]] = s; Format[GetDimension[Latin]] = n;

(* 기본 사용 *)
Epsilon[ua, ub] × Epsilon[lc, ld]
% /. EpsilonProductRule[]
(* -(-1)^s δ_c^b δ_d^a + (-1)^s δ_c^a δ_d^b *)

(* 더 많은 인덱스 *)
Epsilon[ua, ub, up] × Epsilon[lc, ld, lp]
% /. EpsilonProductRule[]
(* 크로네커 델타의 반대칭 조합 *)

(* 다른 Kind의 Epsilon — 적용 안 됨 *)
Epsilon[ua, ub] × EpsilonGreek[lμ, lν]
% /. EpsilonProductRule[]
(* 변화 없음 *)

(* 특정 Kind 지정 *)
EpsilonGreek[uμ, uν] × EpsilonGreek[lρ, lσ]
% /. EpsilonProductRule[Greek]
(* 크로네커 델타 조합으로 전개 *)

(* DualStar와 함께 사용하는 예제 *)
SetDimension[4]; SetSig[1];
Tdefine[A, "*-"]

DualStar[A[ua, ub], {lc, ld}]
DualStar[%, {ue, uf}]
% /. EpsilonProductRule[]
% // TindexSort
(* -A^ef *)
```

#### 참고 (See Also)

`Epsilon`, `KdeltaSumRule`, `DualStar`, `Tsimplify`, `GetSig`
