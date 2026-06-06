# Tech Note: 텐서 표현식 전개 워크플로 (Tensor Expansion Workflow)

공변 도함수, connection 계수, 곡률 텐서를 단계별로 전개하는 워크플로를 다룬다. CDtoBD, GammaToMetric, RiemannToGamma, CommuteCD, LDtoCD의 조합 사용법과 좌표/비좌표 기준계에서의 차이를 포함한다.

> 자세한 함수 설명은 `01-CDtoBD.md`, `02-CommuteCD.md`, `03-GammaToMetric.md`, `04-LDtoCD.md`, `05-RiemannToGamma.md` 참고.

---

## 1. 개요 -- 전개 함수들의 계층 구조

TensorComponents 모듈의 전개 함수들은 추상도가 높은 표현에서 낮은 표현으로 단계적으로 변환한다:

```
LD (Lie 도함수)
  ↓ LDtoCD
CD (공변 도함수)
  ↓ CDtoBD
BD + Gamma (기저 도함수 + connection)
  ↓ GammaToMetric
BD + Metricg (기저 도함수 + 계량 텐서)
```

곡률 텐서도 별도의 경로로 전개된다:

```
Riemann / Ricci / Scalar (곡률 텐서)
  ↓ RiemannToGamma
BD + Gamma (기저 도함수 + connection)
  ↓ GammaToMetric
BD + Metricg (기저 도함수 + 계량 텐서)
```

각 단계는 독립적으로 적용할 수 있으며, 필요한 깊이까지만 전개하면 된다.

---

## 2. CDtoBD 단계별 전개

CDtoBD는 한 번 호출할 때마다 **가장 바깥쪽** 공변 도함수 하나만 전개한다. 중첩된 공변 도함수는 여러 번 호출해야 완전히 전개된다.

```wolfram
(* 1단계: 바깥쪽 CD만 전개 *)
CD[la, lb, v[uc]]
CDtoBD[%]
(* ∇_a∇_bv^c → ∂_a∇_bv^c - ∇_dv^c Γ_ab^d + ... *)

(* 2단계: 안쪽 CD도 전개 *)
CDtoBD[%]
(* → ∂_a∂_bv^c - ... (완전 전개) *)
```

### CDtoBD 2회 적용의 의미

```wolfram
CD[la, lb, v[uc]] - CD[lb, la, v[uc]]
CDtoBD[%]
(* 1단계: ∂_a∇_bv^c - ∂_b∇_av^c + connection 항들 *)

CDtoBD[%]
(* 2단계: 모든 CD가 BD와 Gamma로 전개됨.
   이 시점에서 Riemann 텐서의 정의가 드러남 *)
```

이는 $[\nabla_a, \nabla_b]\omega_c = \frac{1}{2} R_{abc}{}^d \omega_d$를 직접 확인하는 과정이다.

---

## 3. GammaToMetric와 기준계 선택

GammaToMetric의 결과는 **좌표 기준계(coordinate basis)** 여부와 **torsion-free** 여부에 따라 달라진다.

### 4가지 경우의 Christoffel 기호

| Torsion-Free | Coordinate Basis | 결과 |
|:---:|:---:|:---|
| No | No | $\frac{1}{2}(\hat\partial_a g_{bc} + \hat\partial_b g_{ac} - \hat\partial_c g_{ab}) + f + t$ 항 |
| No | Yes | $\frac{1}{2}(\partial_a g_{bc} + \partial_b g_{ac} - \partial_c g_{ab}) + t$ 항 |
| Yes | No | $\frac{1}{2}(\hat\partial_a g_{bc} + \hat\partial_b g_{ac} - \hat\partial_c g_{ab}) + f$ 항 |
| Yes | Yes | $\frac{1}{2}(\partial_a g_{bc} + \partial_b g_{ac} - \partial_c g_{ab})$ ← 가장 단순 |

여기서 $f_{abc}$는 구조 함수(structure function), $t_{abc}$는 torsion이다.

```wolfram
(* Torsion-Free이고 Coordinate basis -- 가장 흔한 경우 *)
TorsionFreeQ[CD] = True;
On[CoordinateBasisFlag]

GammaToMetric[GammaCD[la, lb, lc]]
(* 1/2 ∂_ag_bc + 1/2 ∂_bg_ac - 1/2 ∂_cg_ab *)

(* Non-coordinate basis에서는 structure function이 추가됨 *)
Off[CoordinateBasisFlag]

GammaToMetric[GammaCD[la, lb, lc]]
(* 위 결과 + 1/2 f_abc + 1/2 f_cab + 1/2 f_cba *)
```

### 인덱스가 올라간 Christoffel

$\Gamma_{ab}{}^c = g^{cd}\Gamma_{abd}$이므로, 인덱스가 올라간 Christoffel을 GammaToMetric로 전개하면 역계량 텐서 $g^{cd}$가 함께 등장한다:

```wolfram
GammaToMetric[GammaCD[la, lb, uc]]
(* 1/2 ∂_ag_bd g^cd + 1/2 ∂_bg_ad g^cd - 1/2 ∂_dg_ab g^cd *)
```

---

## 4. RiemannToGamma 선택적 전개

RiemannToGamma는 기본적으로 Riemann, Ricci, Scalar를 **모두** 전개한다. 특정 텐서만 전개하려면 두 번째 인자에 리스트를 지정한다.

```wolfram
(* Riemann, Ricci, Scalar 모두 전개 *)
RiemannToGamma[expr]

(* Ricci만 전개, Riemann은 그대로 *)
RiemannToGamma[expr, {RicciCD}]

(* Scalar만 전개 *)
RiemannToGamma[expr, {ScalarCD}]
```

### 실전 예: 선택적 전개가 필요한 상황

Riemann과 Ricci가 곱해진 표현에서 Ricci만 connection으로 전개하고 Riemann은 상위 수준에서 유지하고 싶을 때:

```wolfram
RiemannCD[ua, ub, lc, ld] × RicciCD[la, lb]
RiemannToGamma[%, {RicciCD}]
(* R_ab R^ab_cd → Ricci만 Gamma로 전개, Riemann은 R^ab_cd 그대로 *)
```

### 주의: BD와 CD의 차이

Connection 계수는 텐서가 아니므로, CD(공변 도함수) 아래의 곡률 텐서는 전개되지 않고 BD(기저 도함수) 아래의 곡률 텐서만 전개된다:

```wolfram
CD[ld, RiemannCD[la, lb, lc, ud]]
RiemannToGamma[%]
(* ∇_dR_abc^d → ∇_dR_abc^d  (변환 안 됨!) *)

BD[ld, RiemannCD[la, lb, lc, ud]]
RiemannToGamma[%]
(* ∂_dR_abc^d → -∂_d∂_aΓ_bc^d + ∂_d∂_bΓ_ac^d + ...  (전개됨) *)
```

---

## 5. CommuteCD로 공변 도함수 순서 교환

CommuteCD는 연속된 두 공변 도함수의 순서를 교환하면서 Riemann 텐서(와 torsion)를 자동으로 생성한다.

### 기본 패턴

```wolfram
CD[la, lb, v[uc]]
CommuteCD[{la, lb}, %]
(* ∇_a∇_bv^c → ∇_b∇_av^c - R_abd^c v^d *)
```

### 제약 조건

1. **연속한 인덱스여야 한다**: `{la, lc}`처럼 건너뛴 인덱스는 동작하지 않는다.
2. **스칼라에는 Riemann 항이 없다**: torsion-free인 경우 $\nabla_a\nabla_b f = \nabla_b\nabla_a f$.

```wolfram
(* 스칼라 -- Riemann 항 없음 *)
CD[la, lb, f[]]
CommuteCD[{la, lb}, %]
(* ∇_a∇_bf → ∇_b∇_af *)

(* 연속하지 않은 인덱스 -- 변환 안 됨 *)
expr = CD[la, ub, lc, F[lb, ud]]
CommuteCD[{la, lc}, expr]
(* 변환 안 됨 *)
```

---

## 6. LDtoCD와 Lie 도함수 처리

### Torsion-Free 조건 필수

LDtoCD는 **torsion-free** 공변 도함수만 처리한다. Torsion이 있으면 경고 후 변환하지 않는다.

```wolfram
TorsionFreeQ[CD] = False;
LDtoCD[LD[v, t[ua, ub]]]
(* Msg: CD is not torsion-free → 변환 안 됨 *)

TorsionFreeQ[CD] = True;
LDtoCD[LD[v, t[ua, ub]]]
(* → 공변 도함수 표현으로 변환 *)
```

### 좌표 기준계에서의 최종 결과

Torsion-free이고 좌표 기준계에서는 LDtoCD → CDtoBD → Tsimplify를 연쇄 적용하면 Christoffel 기호가 상쇄되어 가장 간결한 결과를 얻는다:

```wolfram
TorsionFreeQ[CD] = True;
On[CoordinateBasisFlag]

LD[v, ξ[la]]
% // LDtoCD
CDtoBD[%]
% // Tsimplify
(* 𝓛_vξ_a → ∇_bξ_a v^b + ∇_av^b ξ_b → ∂_bξ_a v^b + ∂_av^b ξ_b *)
```

### CovD 지정으로 다른 도함수 사용

LDtoCD의 옵션으로 두 번째 인자에 `CovD`, `BD` 등을 지정하면 해당 도함수로 직접 전개된다:

```wolfram
expr = LD[v, T[la, lb]]

LDtoCD[expr]       (* CD로 전개 -- 기본값 *)
LDtoCD[expr, CovD] (* CovD로 전개 *)
LDtoCD[expr, BD]   (* BD로 직접 전개 -- connection 없이 *)
```

---

## 7. 완전 전개 파이프라인: CDtoBD → GammaToMetric → Tsimplify

가장 일반적인 전개 워크플로는 다음 파이프라인이다:

```
(원래 표현)
  → CDtoBD (반복)     : CD → BD + Gamma
  → GammaToMetric    : Gamma → ∂g
  → Tsimplify        : 대칭성 기반 단순화
```

### 실전 예: 공변 도함수의 교환자가 0임을 증명

```wolfram
CD[la, lb, F[ua, ub]]
CDtoBD[%]        (* 1단계 *)
CDtoBD[%]        (* 2단계 -- 완전 전개 *)

% // Tsimplify
(* -1/2 ∂_ag_bc ∂_dg^cb F^ad *)

% /. BDinvgRule[]
(* 1/2 ∂_ag_bc ∂_dg_ef F^ad g^bf g^ce *)

% // Tsimplify
(* 0 *)
```

이 결과는 대칭 계량에서 $F^{ab}$가 반대칭이므로 특정 항이 소거됨을 보여준다.

### BDinvgRule의 역할

`BDinvgRule[]`은 역계량 텐서의 기저 도함수를 계량 텐서의 기저 도함수로 변환한다:

$$\partial_a g^{bc} = -g^{bd} g^{ce} \partial_a g_{de}$$

이 규칙은 CDtoBD와 GammaToMetric 사이에서 자주 사용된다.

---

## 8. 사용자 정의 공변 도함수와의 조합

CDtoBD, CommuteCD, GammaToMetric, LDtoCD, RiemannToGamma는 모두 마지막 인자로 공변 도함수의 이름을 받는다. 이를 통해 기본 CD가 아닌 사용자 정의 공변 도함수를 처리할 수 있다.

### 설정 방법

```wolfram
SetDefaultKind[Capital]
DefDerivativeOperator[CovD, "𝒟", Latin]
DefMetric[Phi, Latin]
```

### 함수별 사용

```wolfram
(* CDtoBD *)
CDtoBD[CovD[la, V[ub]], CovD]

(* CommuteCD *)
CommuteCD[{la, lb}, expr, CovD]

(* GammaToMetric -- Latin Kind의 Metric인 Phi와 호환성 필요 *)
SetMetricCompatible[CovD, Phi]
GammaToMetric[GammaCovD[la, lb, lc], CovD]

(* LDtoCD *)
LDtoCD[LD[v, T[la, lb]], CovD]

(* RiemannToGamma *)
RiemannToGamma[RicciCovD[la, lb], {RicciCovD}, CovD]
```

### 주의: GammaToMetric은 MetricCompatible 설정 필요

```wolfram
GammaCovD[la, lb, lc]
GammaToMetric[%, CovD]
(* Msg: CovD is not metric-compatible with Phi *)

SetMetricCompatible[CovD, Phi]
GammaToMetric[GammaCovD[la, lb, lc], CovD]
(* 정상 변환 *)
```
