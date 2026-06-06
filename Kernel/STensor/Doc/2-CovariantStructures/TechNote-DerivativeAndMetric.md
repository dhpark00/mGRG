# Tech Note: 미분 연산자와 계량 텐서 (Derivative Operators and Metrics)

CovariantStructures 모듈에서 미분 연산자(connection)와 계량 텐서(metric)를 정의하고, 이들 사이의 호환성(compatibility)을 설정하는 워크플로를 다룬다. 미분 연산자 정의 시 자동 생성되는 텐서들, 계량 텐서의 Kdelta 관계, 그리고 여러 Kind에서의 동작을 포함한다.

> 자세한 함수 설명은 `01-DerivativeOperators.md`, `02-Metrics.md` 참고.

---

## 1. 개요 -- 미분 연산자와 계량 텐서의 관계

CovariantStructures.m은 IndexNotation.m 위에 미분기하학적 구조를 구축한다. 핵심 관계는 다음 세 가지이다:

- **미분 연산자(connection)**: 공변 도함수를 정의한다. 정의하면 connection coefficients(Gamma), Riemann, Ricci, Scalar 텐서가 자동 생성된다.
- **계량 텐서(metric)**: 인덱스의 올리기/내리기를 가능하게 한다. 정의하면 Kdelta 관계와 대칭성이 자동 설정된다.
- **호환성(compatibility)**: 미분 연산자가 계량 텐서를 공변 상수(covariantly constant)로 만드는 관계이다.

패키지 로딩 시 DefaultKind(기본: Latin)에는 이미 기본 객체가 정의되어 있다:

- **CD**: DefaultKind에 기본 정의된 공변 도함수
- **Metricg**: DefaultKind의 기본 계량 텐서

```wolfram
(* 패키지 로딩 후 기본 상태 *)
KindOf[CD]
(* Latin *)

KindOf[Metricg]
(* Latin *)

CD[lc, Metricg[la, lb]]
(* 0 — CD와 Metricg는 이미 호환 *)
```

---

## 2. 미분 연산자 정의 워크플로

`DefDerivativeOperator`로 새로운 공변 도함수를 정의하면, 관련 텐서가 자동으로 생성된다.

```wolfram
<< mGRG`STensor`

(* 1. 새 미분 연산자 정의 *)
DefDerivativeOperator[CovD, "D"]

(* 2. 자동 생성된 텐서 확인 *)
mGRG`STensor`Private`getDerOp[#][CovD] & /@ {Gamma, Riemann, Ricci}
(* {GammaCovD, RiemannCovD, RicciCovD} *)

(* 3. 스칼라 곡률 확인 — Kind에 차원이 설정되어 있어야 함 *)
mGRG`STensor`Private`getDerOp[Scalar][CovD]
(* ScalarCovD — 계량 텐서가 있고 차원이 설정된 경우 *)

(* 4. Kind 확인 *)
KindOf[CovD]
(* Latin — DefaultKind *)

(* 5. 선형성과 라이프니츠 규칙 확인 *)
c1 RicciCovD[la, lb] + c2 F[la, lc] × RicciCovD[uc, lb]
CovD[ua, %]
(* 라이프니츠 규칙으로 전개됨 *)
```

### TorsionFreeQ 옵션

기본값은 `True`이다. `False`로 설정하면 Gamma와 Ricci에 대칭이 없어진다.

```wolfram
(* 비틀림이 있는 연산자 *)
DefDerivativeOperator[TorsionCovD, TorsionFreeQ -> False]

(* Gamma에 대칭이 없음 *)
mGRG`STensor`Private`getDerOp[Gamma][TorsionCovD]
(* GammaTorsionCovD — 첫 두 인덱스에 대칭 없음 *)
```

### 다른 Kind에 미분 연산자 정의

```wolfram
(* Greek Kind에 연산자 정의 *)
DefDerivativeOperator[GCovD, "D", Greek]

KindOf[GCovD]
(* Greek *)
```

---

## 3. 계량 텐서 정의 워크플로

DefaultKind에는 `Metricg`가 이미 정의되어 있다. 다른 Kind에 계량 텐서를 정의하거나, DefaultKind에 새 계량 텐서를 도입하는 방법을 설명한다.

### DefaultKind에 새 계량 텐서 도입

DefaultKind에 새 계량 텐서를 도입하려면 먼저 `MetricgFlag`를 끄고, 새 계량 텐서를 정의한 후, 작업이 끝나면 복구해야 한다.

```wolfram
(* DefaultKind에 다른 계량 텐서 도입 *)
Off[MetricgFlag]
DefMetric[h]
MetricQ[h]
(* True *)

(* h와 Kdelta 관계 *)
{h[la, lb], h[la, ub], h[lA, uB]}
(* {h_ab, δ_a^b, h_A^B} *)

(* 공변 도함수 설정 *)
SetMetricCompatible[CD, h]
mGRG`STensor`Private`getCovDs[h]
(* {CD} *)

(* 복구 *)
UndefMetric[h]
On[MetricgFlag]
GetMetric[Latin]
(* Metricg *)
```

### 다른 Kind에 계량 텐서 정의

```wolfram
(* Greek Kind에 계량 텐서 정의 *)
DefMetric[Phi, "Φ", Greek]

MetricQ[Phi]
(* True *)

KindOf[Phi]
(* Greek *)

GetMetric[Greek]
(* Phi *)
```

### 주의사항

- 각 Kind마다 계량 텐서는 **하나만** 허용된다.
- 이미 계량 텐서가 있는 Kind에 새로 정의하면 에러가 발생한다.

---

## 4. 계량 호환성 (Metric Compatibility) 설정

`SetMetricCompatible[covD, metric]`은 공변 도함수가 계량 텐서를 공변 상수로 만드는 관계를 설정한다.

```wolfram
DefMetric[Phi, "Φ", Latin]
SetMetricCompatible[CovD, Phi]

(* 공변 상수 확인 *)
{Phi[la, lb], Phi[la, ub], Phi[-1, 2]}
CovD[lc, #] & /@ %
(* {0, 0, D_c Φ_1^2}  -- 두 번째는 δ_a^b로 바뀌어 미분 결과가 0 *)
```

### Epsilon에 대한 효과

계량 호환성 설정은 Epsilon(volume form)에도 적용된다.

```wolfram
(* Epsilon도 공변 상수 *)
SetDimension[3, Latin]
CovD[la, #] & /@ {Epsilon[lb, lc], EpsilonLatin[lb, lc, ld]}
(* {D_a ε_bc, 0}  -- 첫 번째 Epsilon의 인덱스 갯수는 설정된 차원과 다름 *)
```

### 호환성 해제

```wolfram
ClearMetricCompatible[CovD, Phi]

(* 더 이상 공변 상수가 아님 *)
CovD[lc, Phi[la, lb]]
(* D_c Φ_ab *)
```

---

## 5. 여러 Kind에서의 미분 연산자와 계량 텐서

DefaultKind를 전환하여 여러 Kind에 독립적인 미분기하학적 구조를 설정할 수 있다.

```wolfram
(* DefaultKind를 Capital로 이동 *)
SetDefaultKind[Capital]

(* Latin Kind에 별도의 연산자와 계량 텐서 정의 *)
DefDerivativeOperator[CovD, "D", Latin]
DefMetric[Phi, "Φ", Latin]
SetMetricCompatible[CovD, Phi]

(* CD는 DefaultKind(Capital)의 연산자 *)
KindOf[CD]
(* Capital *)

(* CovD는 Latin의 연산자 *)
KindOf[CovD]
(* Latin *)

(* CD는 Capital Kind의 Metricg를 공변 상수로 가짐 *)
CD[lA, Metricg[lB, lC]]
(* 0 *)

(* CD는 Latin Kind의 Phi와는 무관 *)
CD[la, Phi[lb, lc]]
(* ∇_a Φ_bc *)

(* Latin으로 복귀 *)
SetDefaultKind[Latin]
```

---

## 6. 정리와 제거

### 미분 연산자 제거

```wolfram
(* 연산자와 관련 텐서 모두 제거 *)
UndefDerivativeOperator[CovD]
```

`UndefDerivativeOperator`는 Gamma, Riemann, Ricci, Scalar 텐서를 모두 함께 제거한다.

### 계량 텐서 제거

```wolfram
(* 계량 텐서와 관련 속성 제거 *)
UndefMetric[Phi]
```

### 예약된 이름

CD는 예약된 이름이므로 제거할 수 없다.

```wolfram
(* 예약된 이름 확인 *)
mGRG`STensor`Private`reservedNameList
(* {CD, BD, Metricg, Epsilon, ...} *)

(* CD 제거 시도 — 실패 *)
UndefDerivativeOperator[CD]
(* 에러: CD는 예약된 이름 *)
```

---

## 요약

1. **DefDerivativeOperator는 Gamma, Riemann, Ricci, Scalar를 자동 생성한다.**
2. **DefMetric은 Kdelta 관계와 대칭성을 자동 설정한다.**
3. **SetMetricCompatible로 공변 상수 관계를 설정한다.**
4. **각 Kind마다 계량 텐서는 하나만 허용된다.**
5. **CD와 Metricg는 항상 DefaultKind에 속한다.**
6. **UndefDerivativeOperator/UndefMetric으로 정리한다. CD는 제거 불가.**
