# TensorComponents — Misc. Commands

`mGRG`STensor`` 패키지의 `TensorComponents.m`에서 제공하는 기타 유틸리티 함수들이다.

---

### CommutatorVectors

#### 함수 시그니처

```wolfram
CommutatorVectors[vecList, kind]
```

#### 설명 (Details)

벡터들의 commutator를 얻는다. 인자는 벡터의 리스트 또는 두 개의 벡터이다. 이 함수를 사용하려면 `SetCoordinates` 함수를 이용하여 좌표계를 초기화하여야 한다. 옵션으로 simplification을 위한 함수가 있다.

기본 kind는 `DefaultKind`이다.

#### 예제 (Examples)

```wolfram
SetCoordinates[{t, x}]

v1 = {t, x}; v2 = {x, t}; v3 = {t, x^2};

CommutatorVectors[{v1, v2, v3}]
(* [V_1,V_3] = {0, x²}
   [V_2,V_3] = {x - x², -t + 2tx} *)

CommutatorVectors[v1, v2]
(* {0, 0} *)

CommutatorVectors[v1, v3]
(* {0, x²} *)

ClearCoordinates[]  (* 기본 설정으로 복귀 *)
```

---

### LineElement

#### 함수 시그니처

```wolfram
LineElement[coSys, metric, simpCmd]
```

#### 설명 (Details)

좌표계와 metric의 입력을 받아 line element를 표시해 준다. 옵션으로 simplification 함수가 있고, default는 `Together`이다.

#### 예제 (Examples)

```wolfram
coSys = {t, r, θ, ϕ};
metric = {{-e^(2a[t,r]), 0, 0, 0}, {0, e^(2b[t,r]), 0, 0},
          {0, 0, r², 0}, {0, 0, 0, r² Sin[θ]²}};

LineElement[coSys, metric]
(* ds² = e^(2b[t,r]) dr² - e^(2a[t,r]) dt² + r² dθ² + r² dϕ² Sin[θ]² *)
```

---

### SetConstantMetric / ClearConstantMetric (Experimental)

#### 함수 시그니처

```wolfram
SetConstantMetric[diag, coSys, kind]
ClearConstantMetric[kind]
```

#### 설명 (Details)

`SetConstantMetric`은 DefaultKind의 Metricg를 상수 계량 텐서로 설정한다. `ClearConstantMetric`은 해당 설정을 해제한다.

- `diag`는 대각선 요소의 리스트 (예: `{-1, 1, 1, 1}`) 또는 전체 계량 행렬이 될 수 있다.
- `coSys`는 좌표계이다.
- `kind`는 기본적으로 `DefaultKind`이다.

##### 인자가 없는 경우

인자 없이 호출하면 현재 설정된 차원, Sig, 좌표계 정보를 기반으로 동작한다:

```wolfram
SetConstantMetric[]

MetricCompatibleQ[BD, Metricg]
(* True *)

mGRG`STensor`Private`constantMetricQ[DefaultKind]
(* True *)

BD[la, Metricg[lb, lc]]
(* 0 *)

{GammaCD[la, lb, lc], RiemannCD[la, lb, lc, ld], RicciCD[la, lb], ScalarCD[]}
(* {0, 0, 0, 0} *)

ClearConstantMetric[]

MetricCompatibleQ[BD, Metricg]
(* False *)
```

##### 인자가 상수 벡터인 경우

DefaultKind에서 상수(+1 또는 -1) 벡터 (계량 텐서의 대각선 표현)으로부터 시공간 차원과 Sig, 좌표계, 계량 텐서 성분, volume-form 성분을 결정하고 Metricg를 상수 계량 텐서로 설정한다:

```wolfram
SetConstantMetric[{-1, 1}]

Show[DefaultKind]
(* Kind: Latin, Dimension: 2, Sig: 1, Coordinates: x1 x2,
   CoordinateBasisQ: True, EvaluateBDFlag: False *)

Table[Metricg[-i, -j], {i, 2}, {j, 2}] // MatrixForm
(* (-1  0)
   ( 0  1) *)

{Epsilon[-1, -2], Epsilon[-2, -1], Epsilon[1, 2], Epsilon[2, 1]}
(* {1, -1, -1, 1} *)

BD[la, Metricg[lb, lc]]
(* 0 *)

{GammaCD[la, lb, lc], RiemannCD[la, lb, lc, ld], RicciCD[la, lb], ScalarCD[]}
(* {0, 0, 0, 0} *)

ClearConstantMetric[]
```

##### 인자가 상수 벡터와 좌표계인 경우

DefaultKind에서 상수 벡터와 좌표계를 입력으로 받아 시공간 차원과 Sig, 계량 텐서 성분, 볼륨 폼 성분을 결정하고 Metricg를 상수 계량 텐서로 설정한다:

```wolfram
SetConstantMetric[{-1, 1, 1}, {t, x, y}]

Show[DefaultKind]
(* Kind: Latin, Dimension: 3, Sig: 1, Coordinates: t x y,
   CoordinateBasisQ: True, EvaluateBDFlag: False *)

Table[Metricg[-i, -j], {i, 3}, {j, 3}] // MatrixForm
(* (-1  0  0)
   ( 0  1  0)
   ( 0  0  1) *)

ClearConstantMetric[]
```

**상수 벡터와 좌표계의 차원이 일치해야 한다:**

```wolfram
SetConstantMetric[{-1, 1, 1}, {t, x}]
(* Msg: incompatible arguments: mGRG`STensor`Private`vec and {t, x} *)
(* $Failed *)
```

##### 인자가 수치 행렬인 경우

기준 벡터가 Null 벡터인 경우:

```wolfram
SetConstantMetric[{{0, -1}, {-1, 0}}]

Show[DefaultKind]
(* Kind: Latin, Dimension: 2, Sig: 1, Coordinates: x1 x2,
   CoordinateBasisQ: True, EvaluateBDFlag: False *)

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

##### 마지막 인자가 Kind인 경우

계량 텐서 공간이어야 한다:

```wolfram
SetConstantMetric[{-1, 1, 1}, Greek]
(* Msg: Greek is not a metric space. *)
(* $Failed *)

DefMetric[eta, "η", Greek]

(* 좌표 기준 벡터이어야 한다 *)
SetConstantMetric[{-1, 1, 1}, Greek]
(* Msg: Greek is not in coordinate basis. *)
(* $Failed *)

On[CoordinateBasisFlag[Greek]]

(* 인자가 상수 벡터, 좌표계, kind인 경우 *)
SetConstantMetric[{-1, 1, 1}, {t, x, y}, Greek]

Show[Greek]
(* Kind: Greek, Dimension: 3, Sig: 1, Coordinates: t x y,
   CoordinateBasisQ: True, EvaluateBDFlag: False *)

Table[eta[-i, -j], {i, 3}, {j, 3}] // MatrixForm
(* (-1  0  0)
   ( 0  1  0)
   ( 0  0  1) *)

mGRG`STensor`Private`constantMetricQ[Greek]
(* True *)

BD[lμ, eta[uν, uρ]]
(* 0 *)
```

**공변 도함수가 정의된 공간:**

```wolfram
DefDerivativeOperator[CovD, "D", Greek];
SetMetricCompatible[CovD, eta]

SetConstantMetric[{-1, 1, 1}, {t, x, y}, Greek]

{GammaCovD[lμ, lν, lρ],
 RiemannCovD[lμ, lν, lρ, lσ], RicciCovD[lμ, lν], ScalarCovD[]}
(* {0, 0, 0, 0} *)

ClearConstantMetric[Greek]
```

##### Special Relativity (Minkowski SpaceTime)를 위한 설정

```wolfram
SetIndices[ToString /@ {a, b, c, d, e, f, g}, Latin];
DefKind[LatinSpace, ToString /@ {i, j, k, l, m, n}]

DefMetric[η, Greek]

On[CoordinateBasisFlag[Greek]]
SetConstantMetric[{1, 1, 1, -1}, {x, y, z, t}, Greek]

Show[Greek]
(* Kind: Greek, Dimension: 4, Sig: 1, Coordinates: x y z t,
   CoordinateBasisQ: True, EvaluateBDFlag: False *)

DefKind[Zero, {"0"}];
zeroRule = {l0 → -4, u0 → 4};

Tdefine[x, 1]

{x[l0], x[-1], x[-2], x[-3], x[u0], x[1], x[2], x[3]}
(* {x_0, x_1, x_2, x_3, x^0, x^1, x^2, x^3} *)

% /. zeroRule
(* {x_4, x_1, x_2, x_3, x^4, x^1, x^2, x^3} *)

UndefKind[Zero];
UndefKind[LatinSpace];
SetIndices[Alphabet[], Latin]  (* 기본 설정으로 복귀 *)
```

#### 참고 (See Also)

`SetComponents`, `ClearComponents`, `InitCTensor`, `Show`
