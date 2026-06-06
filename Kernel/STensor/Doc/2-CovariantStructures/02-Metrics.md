# CovariantStructures — 계량 텐서 (Metrics)

`mGRG`STensor`` 패키지의 `CovariantStructures.m`에서 제공하는 계량 텐서 정의 및 관련 함수들이다.

---

### MetricQ

#### 함수 시그니처

```wolfram
MetricQ[metric]
```

#### 설명 (Details)

`metric`이 `DefMetric`으로 정의된 계량 텐서인지 묻는다. 정의된 계량 텐서이면 `True`, 아니면 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
MetricQ /@ {Metricg, Phi}
(* {True, False} *)
```

#### 참고 (See Also)

`DefMetric`, `UndefMetric`, `Metricg`

---

### DefMetric

#### 함수 시그니처

```wolfram
DefMetric[metric, prtStr, kind]
```

#### 설명 (Details)

계량 텐서를 정의한다. 인자는 계량 텐서의 이름, 옵션으로 출력을 위한 문자열, 계량 텐서가 속한 Kind이다.

- 각각의 Kind마다 한 개의 계량 텐서만 허용된다.
- `DefaultKind`에서는 이름이 `Metricg`인 계량 텐서가 항상 정의되어 있다. 따라서 `DefaultKind`에서 다른 계량 텐서를 정의하려면 기본 계량 텐서인 `Metricg`를 먼저 제거해야 한다. (`MetricgFlag`을 `Off` 시켜서 `Metricg`를 삭제한다.)
- 계량 텐서의 인덱스가 '위-아래' 또는 '아래-위' 첨자이면서 적합한 Kind이면 자동으로 상수 텐서인 `Kdelta`로 바뀐다.

#### 예제 (Examples)

```wolfram
(* DefaultKind를 Capital로 옮기고 Latin에 별도 계량 텐서 정의 *)
DefKind[Capital, ToUpperCase /@ Alphabet[]]
SetDefaultKind[Capital]
DefDerivativeOperator[CovD, "D", Latin]
DefMetric[Phi, "Φ", Latin]

MetricSpaceQ /@ {Latin, Capital}
(* {True, True} *)

MetricQ /@ {Phi, Metricg}
(* {True, True} *)

(* 계량 텐서와 Kdelta *)
{Phi[la, lb], Phi[la, ub], Phi[lA, uB]}
(* {Φ_ab, δ_a^b, Φ_A^B} *)

(* Phi는 CovD에 대한 공변 상수로 설정되지 않았음 *)
{Phi[la, lb], Phi[la, ub], Phi[-1, 2]}
CovD[lc, #] & /@ %
(* {D_c Φ_ab, 0, D_c Φ_1^2} *)
```

#### 참고 (See Also)

`UndefMetric`, `MetricQ`, `MetricSpaceQ`, `Metricg`, `Kdelta`

---

### UndefMetric

#### 함수 시그니처

```wolfram
UndefMetric[metric]
```

#### 설명 (Details)

정의된 계량 텐서 `metric`과 그에 연결된 모든 속성을 제거한다. 관련 미분 연산자 및 곡률 텐서도 함께 갱신된다.

#### 예제 (Examples)

```wolfram
UndefMetric[Phi]
MetricQ[Phi]
(* False *)
```

#### 참고 (See Also)

`DefMetric`, `MetricQ`

---

### MetricSpaceQ

#### 함수 시그니처

```wolfram
MetricSpaceQ[kind]
```

#### 설명 (Details)

`DefKind`로 정의한 Kind가 계량 공간(metric space)인지 묻는다. 해당 Kind에 계량 텐서가 정의되어 있으면 `True`, 아니면 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
MetricSpaceQ /@ {Latin, Greek}
(* {True, False} *)
```

#### 참고 (See Also)

`DefMetric`, `GetMetric`, `CoordinateBasisQ`

---

### GetMetric

#### 함수 시그니처

```wolfram
GetMetric[kind]
```

#### 설명 (Details)

지정한 `kind`에 연결된 **유일한** 계량 텐서를 반환한다. 계량 텐서가 정의되어 있지 않으면 `Null`을 반환한다.

#### 예제 (Examples)

```wolfram
GetMetric /@ {Latin, Greek}
(* {Metricg, Null} *)
```

#### 참고 (See Also)

`DefMetric`, `MetricSpaceQ`, `GetEpsilon`

---

### GetEpsilon

#### 함수 시그니처

```wolfram
GetEpsilon[kind]
```

#### 설명 (Details)

지정한 `kind`에 연결된 Levi-Civita 텐서(체적 형식, volume form)를 반환한다. 각 Kind마다 고유한 Epsilon 텐서가 존재한다.

#### 예제 (Examples)

```wolfram
GetEpsilon /@ {Latin, Greek}
(* {Epsilon, EpsilonGreek} -- Greek가 Kind로 정의된 경우 *)
```

#### 참고 (See Also)

`Epsilon`, `GetMetric`, `DefKind`

---

### MetricCompatibleQ

#### 함수 시그니처

```wolfram
MetricCompatibleQ[op, opts]
MetricCompatibleQ[op, metric, opts]
MetricCompatibleQ[op, idx, opts]
```

#### 설명 (Details)

첫 번째 인자인 공변 도함수 `op`와 그 공변 도함수가 속한 Kind의 유일한 계량 텐서 `metric`이 서로 부합하는가를 묻는다. 즉, 공변 도함수로 계량 텐서를 미분하면 0이 되는지 여부를 반환한다.

- `CovDs` 옵션으로 임의의 연산자를 (임시로) 공변 도함수로 지정할 수 있다.
- 두 번째 인자가 인덱스이면 첫 번째 인자는 CD type 연산자인 경우만 다룬다.

#### 예제 (Examples)

```wolfram
MetricCompatibleQ /@ {CD, BD, LD}
(* {True, False, False} *)

MetricCompatibleQ[#, Metricg] & /@ {CD, BD, LD}
(* {True, False, False} *)

MetricCompatibleQ[#, {CovDs -> {BD, LD}}] & /@ {CD, BD, LD}
(* {True, True, True} *)
```

#### 참고 (See Also)

`SetMetricCompatible`, `ClearMetricCompatible`, `DefMetric`

---

### SetMetricCompatible

#### 함수 시그니처

```wolfram
SetMetricCompatible[covD, metric]
```

#### 설명 (Details)

공변 도함수 `covD`가 계량 텐서 `metric`과 부합(compatible)하도록 설정한다. 이는 `covD`로 `metric`을 미분하면 0이 됨을 의미한다. 체적 형식(volume form)도 공변 상수가 된다.

#### 예제 (Examples)

```wolfram
DefMetric[Phi, "Φ", Latin]
SetMetricCompatible[CovD, Phi]
(* Phi가 CovD에 대해 공변 상수 *)

{Phi[la, lb], Phi[la, ub], Phi[-1, 2]}
CovD[lc, #] & /@ %
(* {0, 0, D_c Φ_1^2} *)
```

#### 참고 (See Also)

`ClearMetricCompatible`, `MetricCompatibleQ`, `DefMetric`

---

### ClearMetricCompatible

#### 함수 시그니처

```wolfram
ClearMetricCompatible[covD, metric]
```

#### 설명 (Details)

공변 도함수 `covD`와 계량 텐서 `metric` 사이의 metric-compatibility 속성을 제거한다. 제거 후에는 `covD`로 `metric`을 미분해도 0이 되지 않는다.

#### 예제 (Examples)

```wolfram
ClearMetricCompatible[CovD, Phi]
{CovD[la, Phi[lb, lc]], CovD[la, EpsilonLatin[lb, lc, ld]]}
(* {D_a Φ_bc, D_a ε[Latin]_bcd} *)
```

#### 참고 (See Also)

`SetMetricCompatible`, `MetricCompatibleQ`, `DefDerivativeOperator`, `Metricg`, `Kdelta`, `Epsilon`
