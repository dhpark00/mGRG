# Tech Note: DefaultKind 시스템 (DefaultKind System and Kind Switching)

DefaultKind 메커니즘과, DefaultKind를 전환할 때 CD, Metricg, Epsilon 등 시스템 객체가 어떻게 반응하는지를 설명한다. 여러 Kind를 동시에 활용하는 실전 예제를 포함한다.

> 자세한 함수 설명은 `04-SetDefaultKind.md`, `02-Metrics.md` 참고.

---

## 1. DefaultKind의 역할

DefaultKind는 Kind 인자를 생략할 때 사용되는 기본 Kind이다.

- 패키지 로딩 시 **Latin**이 DefaultKind로 설정된다.
- **CD**, **Metricg**, **Epsilon**은 항상 DefaultKind에 속한다.
- `SetDimension`, `SetCoordinates`, `SetSig` 등에서 Kind를 생략하면 DefaultKind가 사용된다.

```wolfram
<< mGRG`STensor`

DefaultKind
(* Latin *)

(* Kind를 생략하면 DefaultKind 사용 *)
SetDimension[4]               (* = SetDimension[4, Latin] *)
SetCoordinates[{t, x, y, z}]  (* = SetCoordinates[{t, x, y, z}, Latin] *)
```

DefaultKind는 "어떤 Kind에서 작업할 것인가"를 결정하는 전역 설정이다. 여러 Kind를 사용하는 프로젝트에서는 `SetDefaultKind`로 작업 대상 Kind를 전환한다.

---

## 2. DefaultKind 전환 워크플로

`SetDefaultKind`로 DefaultKind를 전환하면, CD, Metricg, Epsilon이 자동으로 새 Kind에 속하게 된다.

```wolfram
(* 초기 상태 *)
DefaultKind
(* Latin *)

{mGRG`STensor`Private`getDerOperators[DefaultKind], GetMetric[DefaultKind], GetEpsilon[DefaultKind]}
(* {{CD}, Metricg, Epsilon} *)

KindOf /@ {CD, Metricg, Epsilon}
(* {Latin, Latin, Latin} *)

(* Greek으로 전환 *)
SetDefaultKind[Greek]
DefaultKind
(* Greek *)

{mGRG`STensor`Private`getDerOperators[DefaultKind], GetMetric[DefaultKind], GetEpsilon[DefaultKind]}
(* {{CD}, Metricg, Epsilon} *)

KindOf /@ {CD, Metricg, Epsilon}
(* {Greek, Greek, Greek} *)

(* Latin으로 복귀 *)
SetDefaultKind[Latin]
```

핵심: DefaultKind를 전환해도 CD, Metricg, Epsilon이라는 **이름**은 변하지 않는다. 그러나 이들이 속하는 **Kind**가 바뀐다.

---

## 3. DefaultKind와 시스템 객체의 관계

각 객체가 DefaultKind 전환에 어떻게 반응하는지 정리한다.

| 객체 | Kind 소속 | DefaultKind 전환 시 행동 |
|------|-----------|----------------------|
| CD | DefaultKind | 항상 DefaultKind에 속함. Kind 전환 시 자동으로 따라감 |
| Metricg | DefaultKind | 항상 DefaultKind에 속함. 해당 Kind에 계량 텐서가 있으면 활성화 |
| Epsilon | DefaultKind | 항상 DefaultKind에 속함 |
| Kdelta | All | 모든 Kind에서 사용. DefaultKind 변경에 영향 없음 |
| BD | All | 모든 Kind에서 사용. DefaultKind 변경에 영향 없음 |
| 성분 인덱스 (정수) | DefaultKind | DefaultKind에 속함. 전환하면 성분 인덱스의 Kind도 바뀜 |

### Cross-Kind 계량 텐서 동작

DefaultKind에 따라 Metricg의 동작이 달라진다.

```wolfram
(* DefaultKind = Latin *)
{Metricg[la, ub], Metricg[lA, uB]}
(* {δ_a^b, g_A^B} *)
(* Latin Kind의 인덱스는 Kdelta로 변환, Capital Kind는 그대로 *)

CD[lc, #] & /@ {Metricg[la, lb], Metricg[lA, lB]}
(* {0, ∇_c g_AB} *)
(* Latin Kind의 Metricg만 공변 상수 *)
```

같은 Metricg라도 인덱스의 Kind에 따라 다르게 동작한다:

- DefaultKind와 **같은** Kind의 인덱스: Kdelta 관계 적용, 공변 상수
- DefaultKind와 **다른** Kind의 인덱스: 일반 텐서처럼 동작

```wolfram
(* DefaultKind를 Capital로 전환하면 반대가 됨 *)
SetDefaultKind[Capital]

{Metricg[la, ub], Metricg[lA, uB]}
(* {g_a^b, δ_A^B} *)
(* 이제 Capital Kind의 인덱스가 Kdelta로 변환됨 *)

SetDefaultKind[Latin]
```

---

## 4. 여러 Kind를 활용한 실전 예제

시공간 인덱스(Greek)와 내부 공간 인덱스(Latin)를 동시에 사용하는 게이지 이론 설정 예제이다.

```wolfram
<< mGRG`STensor`

(* 시공간: Greek Kind *)
DefKind[Greek, Alphabet["Greek"]]
SetDefaultKind[Greek]
SetDimension[4, Greek]

(* 내부 공간: Latin Kind (DefaultKind에서 떼어냄) *)
DefDerivativeOperator[CovD, "D", Latin]
DefMetric[Phi, "Φ", Latin]

(* 게이지 장 텐서 정의 *)
Tdefine[A[lμ, ua]]
Tdefine[YMF[lμ, lν, ua], "-bac", PrintAs -> "F"]

(* CD는 Greek Kind (DefaultKind)의 공변 도함수 *)
KindOf[CD]
(* Greek *)

(* CovD는 Latin Kind의 공변 도함수 *)
KindOf[CovD]
(* Latin *)
```

이 설정에서 각 연산자는 자신의 Kind에 속하는 인덱스에만 작용한다:

```wolfram
(* CD는 Greek 인덱스에 대한 공변 도함수 *)
CD[lμ, A[lν, ua]]
(* ∇_μ A_ν^a — Greek 인덱스를 공변 미분 *)

(* CovD는 Latin 인덱스에 대한 공변 도함수 *)
CovD[la, A[lμ, ub]]
(* D_a A_μ^b — Latin 인덱스를 공변 미분 *)

(* Metricg는 Greek Kind의 계량 텐서 *)
CD[lμ, Metricg[lν, lρ]]
(* 0 *)

(* Phi는 Latin Kind의 계량 텐서 *)
CovD[la, Phi[lb, lc]]
(* D_a Φ_bc — 호환성을 설정하지 않으면 0이 아님 *)

SetMetricCompatible[CovD, Phi]
CovD[la, Phi[lb, lc]]
(* 0 *)
```

작업이 끝나면 복귀한다:

```wolfram
(* 정리 *)
UndefDerivativeOperator[CovD]
UndefMetric[Phi]
SetDefaultKind[Latin]
```

---

## 요약

1. **DefaultKind는 Kind 인자 생략 시의 기본값이다.**
2. **CD, Metricg, Epsilon은 항상 DefaultKind를 따른다** -- `SetDefaultKind`로 전환하면 자동으로 이동한다.
3. **Kdelta와 BD는 All이므로** DefaultKind 전환에 영향받지 않는다.
4. **성분 인덱스(정수)의 Kind는 DefaultKind이다** -- DefaultKind를 전환하면 성분 인덱스의 Kind도 바뀐다.
5. **Cross-Kind 연산에 주의** -- `Metricg[lA, uB]`는 DefaultKind가 Latin이면 Kdelta가 되지 않는다.
