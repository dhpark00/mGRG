# Tech Note: 상수 계량 텐서 설정 워크플로 (Constant Metric Setup Workflow)

SetConstantMetric / ClearConstantMetric를 이용한 평탄 시공간 설정 워크플로를 다룬다. 인자 형태별 동작 차이, 다중 Kind에서의 설정, 특수상대론 환경 구성을 포함한다.

> 자세한 함수 설명은 `10-MiscCommands.md` 참고.

---

## 1. 개요 -- SetConstantMetric의 역할

`SetConstantMetric`은 평탄 시공간(flat spacetime)을 위한 상수 계량 텐서를 설정한다. 설정 후 자동으로 다음이 성립한다:

| 효과                                                  | 값      |
| --------------------------------------------------- | ------ |
| `MetricCompatibleQ[BD, Metricg]`                    | `True` |
| `mGRG`STensor`Private`constantMetricQ[DefaultKind]` | `True` |
| `BD[la, Metricg[lb, lc]]`                           | `0`    |
| `GammaCD[la, lb, lc]`                               | `0`    |
| `RiemannCD[la, lb, lc, ld]`                         | `0`    |
| `RicciCD[la, lb]`                                   | `0`    |
| `ScalarCD[]`                                        | `0`    |

`ClearConstantMetric`은 이 모든 설정을 해제하여 일반적인 (비상수) 계량 텐서 상태로 되돌린다.

---

## 2. 인자 형태별 동작 정리

| 호출 형태 | 자동 결정 항목 | 비고 |
|----------|-------------|------|
| `SetConstantMetric[]` | - | 기존 차원/좌표 정보 사용 |
| `SetConstantMetric[{-1, 1}]` | Dimension, Sig, Coordinates, Epsilon | 대각선 벡터에서 추론 |
| `SetConstantMetric[{-1, 1, 1}, {t, x, y}]` | Dimension, Sig, Epsilon | 좌표계 명시 |
| `SetConstantMetric[{{0, -1}, {-1, 0}}]` | Dimension, Sig, Coordinates, Epsilon | Null 기저 가능 |
| `SetConstantMetric[diag, Greek]` | 위와 동일하되 Greek kind에 적용 | 계량 공간 + 좌표 기준계 필요 |
| `SetConstantMetric[diag, coSys, Greek]` | 위와 동일 | Kind + 좌표계 명시 |

---

## 3. 인자 없이 호출

현재 설정된 차원과 좌표 정보를 유지하면서 계량 텐서를 상수로 설정한다:

```wolfram
SetConstantMetric[]

MetricCompatibleQ[BD, Metricg]  (* True *)
mGRG`STensor`Private`constantMetricQ[DefaultKind]   (* True *)
BD[la, Metricg[lb, lc]]  (* 0 *)

{GammaCD[la, lb, lc], RiemannCD[la, lb, lc, ld], RicciCD[la, lb], ScalarCD[]}
(* {0, 0, 0, 0} *)

ClearConstantMetric[]

MetricCompatibleQ[BD, Metricg]  (* False *)
mGRG`STensor`Private`constantMetricQ[DefaultKind]   (* False *)
BD[la, Metricg[lb, lc]]  (* ∂_ag_bc  -- 다시 일반 표현 *)
```

---

## 4. 대각선 벡터로 호출

상수(+1 또는 -1) 벡터로 시공간의 차원, Sig, 좌표계, 계량 텐서, 볼륨 폼(Epsilon)을 모두 자동 설정한다:

```wolfram
SetConstantMetric[{-1, 1}]

Show[DefaultKind]
(* Kind: Latin, Dimension: 2, Sig: 1,
   Coordinates: x1 x2,
   CoordinateBasisQ: True, EvaluateBDFlag: False *)

Table[Metricg[-i, -j], {i, 2}, {j, 2}] // MatrixForm
(* (-1  0)
   ( 0  1) *)

(* Epsilon 텐서도 자동 설정 *)
{Epsilon[-1, -2], Epsilon[-2, -1], Epsilon[1, 2], Epsilon[2, 1]}
(* {1, -1, -1, 1} *)

ClearConstantMetric[]
```

해제 후 `Show[DefaultKind]`에서 Dimension이 `Any`, Coordinates가 `none`으로 돌아간다.

---

## 5. 대각선 벡터 + 좌표계로 호출

좌표계를 명시적으로 지정한다:

```wolfram
SetConstantMetric[{-1, 1, 1}, {t, x, y}]

Show[DefaultKind]
(* Kind: Latin, Dimension: 3, Sig: 1,
   Coordinates: t x y,
   CoordinateBasisQ: True, EvaluateBDFlag: False *)

{GammaCD[la, lb, lc], RiemannCD[la, lb, lc, ld], RicciCD[la, lb], ScalarCD[]}
(* {0, 0, 0, 0} *)

ClearConstantMetric[]
```

**상수 벡터와 좌표계의 차원은 일치해야 한다:**

```wolfram
SetConstantMetric[{-1, 1, 1}, {t, x}]
(* Msg: incompatible arguments *)
(* $Failed *)
```

---

## 6. 수치 행렬로 호출 (Null 기저)

대각선이 아닌 상수 행렬도 사용할 수 있다. Null 기저를 정의할 때 유용하다:

```wolfram
SetConstantMetric[{{0, -1}, {-1, 0}}]

Table[Metricg[-i, -j], {i, 2}, {j, 2}] // MatrixForm
(* ( 0  -1)
   (-1   0) *)

{Epsilon[-1, -2], Epsilon[-2, -1], Epsilon[1, 2], Epsilon[2, 1]}
(* {1, -1, -1, 1} *)

BD[la, Metricg[lb, lc]]
(* 0 *)

{GammaCD[la, lb, lc], RiemannCD[la, lb, lc, ld], RicciCD[la, lb], ScalarCD[]}
(* {0, 0, 0, 0} *)

ClearConstantMetric[]
```

---

## 7. 다른 Kind에서의 설정

DefaultKind가 아닌 다른 Kind에 상수 계량 텐서를 설정하려면 마지막 인자로 Kind를 지정한다.

### 전제 조건

1. **계량 텐서 공간**이어야 한다 (`DefMetric`으로 설정).
2. **좌표 기준계**이어야 한다 (`On[CoordinateBasisFlag[kind]]`).

```wolfram
(* 실패 -- 계량 공간이 아님 *)
SetConstantMetric[{-1, 1, 1}, Greek]
(* Msg: Greek is not a metric space. → $Failed *)

DefMetric[eta, "η", Greek]

(* 실패 -- 좌표 기준계가 아님 *)
SetConstantMetric[{-1, 1, 1}, Greek]
(* Msg: Greek is not in coordinate basis. → $Failed *)

On[CoordinateBasisFlag[Greek]]

(* 성공 *)
SetConstantMetric[{-1, 1, 1}, {t, x, y}, Greek]

Show[Greek]
(* Kind: Greek, Dimension: 3, Sig: 1,
   Coordinates: t x y,
   CoordinateBasisQ: True, EvaluateBDFlag: False *)

Table[eta[-i, -j], {i, 3}, {j, 3}] // MatrixForm
(* (-1  0  0)
   ( 0  1  0)
   ( 0  0  1) *)

mGRG`STensor`Private`constantMetricQ[Greek]  (* True *)
BD[lμ, eta[uν, uρ]]  (* 0 *)

ClearConstantMetric[Greek]
```

### 공변 도함수와 함께 사용

다른 Kind의 공변 도함수를 정의하고 상수 계량과 연결할 수 있다:

```wolfram
DefDerivativeOperator[CovD, "D", Greek]
SetMetricCompatible[CovD, eta]

SetConstantMetric[{-1, 1, 1}, {t, x, y}, Greek]

{GammaCovD[lμ, lν, lρ],
 RiemannCovD[lμ, lν, lρ, lσ], RicciCovD[lμ, lν], ScalarCovD[]}
(* {0, 0, 0, 0} *)

ClearConstantMetric[Greek]

(* 해제 후 *)
(* CovD는 상수 계량이 아닌 eta의 공변 도함수 *)
{GammaCovD[lμ, lν, lρ],
 RiemannCovD[lμ, lν, lρ, lσ], RicciCovD[lμ, lν], ScalarCovD[]}
(* {Γ[D]_μνρ, R[D]_μνρσ, R[D]_μν, R[D]} — 다시 일반 표현 *)
```

---

## 8. 특수상대론 환경 구성 (Minkowski SpaceTime)

특수상대론을 위한 민코프스키 시공간을 다음과 같이 구성한다:

```wolfram
(* 1. Latin과 공간 인덱스를 위한 Kind 정의 *)
SetIndices[ToString /@ {a, b, c, d, e, f, g}, Latin];
DefKind[LatinSpace, ToString /@ {i, j, k, l, m, n}]

(* 2. Greek Kind에 시공간 계량 정의 *)
DefMetric[η, Greek]

(* 3. 좌표 기준계 설정 및 상수 계량 *)
On[CoordinateBasisFlag[Greek]]
SetConstantMetric[{1, 1, 1, -1}, {x, y, z, t}, Greek]

Show[Greek]
(* Kind: Greek, Dimension: 4, Sig: 1,
   Coordinates: x y z t,
   CoordinateBasisQ: True *)
```

### 0번째 인덱스의 처리

특수상대론에서 0번째 인덱스(시간)를 별도로 다루려면 'Zero' Kind를 정의한다:

```wolfram
DefKind[Zero, {"0"}];
zeroRule = {l0 → -4, u0 → 4};

Tdefine[x, 1]

{x[l0], x[-1], x[-2], x[-3], x[u0], x[1], x[2], x[3]}
(* {x_0, x_1, x_2, x_3, x^0, x^1, x^2, x^3} *)

(* 성분값으로 변환 *)
% /. zeroRule
(* {x_4, x_1, x_2, x_3, x^4, x^1, x^2, x^3} *)
```

### 정리

```wolfram
UndefKind[Zero];
UndefKind[LatinSpace];
SetIndices[Alphabet[], Latin]  (* default *)
```

---

## 9. 주의사항과 오류 처리

### 해제하지 않으면 누적된다

`ClearConstantMetric[]`을 호출하지 않으면 이전 설정이 유지된다. 특히 다른 Kind에 대해서는 `ClearConstantMetric[kind]`로 kind를 명시해야 한다.

### 행렬 인자에서의 Sig 자동 추론

수치 행렬을 인자로 줄 때, Sig는 행렬의 고유값 부호로부터 자동으로 결정된다.
