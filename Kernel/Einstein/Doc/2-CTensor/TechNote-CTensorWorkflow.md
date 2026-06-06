# Tech Note: 성분 텐서 계산 워크플로 (CTensor Calculation Workflow)

InitCTensor, Tcalc, Show, ClearCTensor를 이용한 성분 텐서 계산의 실전 워크플로를 다룬다. 좌표/비좌표 기저 선택, 사전 정의 계량 활용, 곡률 텐서의 단계별 계산을 포함한다.

> 자세한 함수 설명은 `01-InitCTensor.md`, `02-Tcalc.md`, `03-Geodesic.md`, `04-ShowAndCsimplify.md` 참고.

---

## 1. 개요 -- CTensor 계산 파이프라인

CTensor 모듈의 표준 워크플로는 다음 순서를 따른다:

```
InitCTensor → Tcalc → Show → ClearCTensor
```

| 단계     | 함수                                 | 역할            |
| ------ | ---------------------------------- | ------------- |
| 1. 초기화 | `InitCTensor[coSys, metric, opts]` | 좌표계, 계량 설정    |
| 2. 계산  | `Tcalc[tensor]`                    | 곡률 텐서 등 성분 계산 |
| 3. 확인  | `Show[tensor]`                     | 결과 표시         |
| 4. 해제  | `ClearCTensor[]`                   | 환경 초기화        |

초기화 시 옵션(`GammaCD`, `RicciCD` 등)으로 사전 계산을 지정하면 2단계를 건너뛸 수 있다. 사전 정의 계량 파일을 사용하면 1단계도 간소화된다.

### 기저 선택 가이드

| 상황 | 기저 | InitCTensor 호출 |
|------|------|----------------|
| 일반적인 GR 계산 | 좌표 기저 | `InitCTensor[coSys, metric]` |
| Orthonormal frame | 비좌표 기저 | `InitCTensor[coSys, metric, basisM]` |
| 잘 알려진 시공간 | 파일 로드 | `InitCTensor["MetricName"]` |

---

## 2. 좌표 기저에서의 초기화와 계산

좌표 기저는 가장 일반적인 사용 방식이다. 좌표계와 계량 행렬만으로 초기화한다.

### 2차원 예제

```wolfram
coSys = {t, x};
metric = {{-E^(2 ρ[t, x]), 0}, {0, E^(2 ρ[t, x])}};

InitCTensor[coSys, metric, RicciCD → True, FourDimensionQ → False];
```

`FourDimensionQ → False`는 4차원이 아닌 시공간에서 필수이다. 생략하면 오류가 발생한다:

```wolfram
InitCTensor[coSys, metric, RicciCD → True]
(* Msg: It is assumed a four-dimensional spacetime.
   But the number of coordinates is not four!
   Use FourDimensionQ → False option *)
(* $Failed *)
```

### 초기화 후 상태 확인

```wolfram
Show[DefaultKind]
(* InitCTensorFlag: True
   Dimension: 2, Coordinates: t x
   CoordinateBasisQ: True, EvaluateBDFlag: True *)
```

`InitCTensorFlag`가 `True`로 변경되고, `EvaluateBDFlag`도 `True`가 되어 편도함수가 자동으로 전개된다.

### 좌표 기저의 특징

좌표 기저에서는 구조 상수가 항상 0이다:

```wolfram
Show[Structuref]
(* f_{ab}^c = 0 *)
```

Christoffel 기호는 계량 텐서의 편미분으로부터 결정된다:

$$\Gamma_{ab}{}^c = \frac{1}{2} g^{cd}(\partial_a g_{bd} + \partial_b g_{ad} - \partial_d g_{ab})$$

---

## 3. 비좌표 기저에서의 초기화와 계산

비좌표 기저(orthonormal frame 등)를 사용하려면 기저 행렬 `basisM`을 추가로 전달한다.

### Orthonormal Basis인 경우의 설정 사례

$e_a{}^A = h_a{}^\mu \partial_\mu{}^A$ 에서 `basisM` = $h_a{}^\mu$:

```wolfram
coSys = {t, x};
metric = {{-1, 0}, {0, 1}};
basisM = {{E^(-ρ[t, x]), 0}, {0, E^(-ρ[t, x])}};

InitCTensor[coSys, metric, basisM, RicciCD → True, FourDimensionQ → False];
```

### 좌표 기저와의 차이

| 항목                 | 좌표 기저  | 비좌표 기저                     |
| ------------------ | ------ | -------------------------- |
| `CoordinateBasisQ` | `True` | `False`                    |
| `Structuref`       | 0      | $\neq 0$                   |
| 계량 성분              | 일반 함수  | 상수 (orthonormal 시 $\pm 1$) |
| Geodesic           | 사용 가능  | 사용 불가                      |

### 구조 상수의 역할

비좌표 기저에서는 구조 상수가 접속 계수 계산에 포함된다:

```wolfram
Show[Structuref]
(* Symmetry: f_{(ab)}^c
   f_12^1 = e^{-ρ[t,x]} ρ^{(0,1)}[t,x]
   f_12^2 = -e^{-ρ[t,x]} ρ^{(1,0)}[t,x] *)
```

### 결과의 일치성

좌표 기저와 비좌표 기저에서 물리적 불변량(스칼라)은 동일하다:

```wolfram
(* 좌표 기저 *)
Show[ScalarCD]
(* R = -2 e^{-2ρ[t,x]} (ρ^{(0,2)}[t,x] - ρ^{(2,0)}[t,x]) *)

(* 비좌표 기저 *)
Show[ScalarCD]
(* R = -2 e^{-2ρ[t,x]} (ρ^{(0,2)}[t,x] - ρ^{(2,0)}[t,x]) *)
(* — 동일 *)
```

---

## 4. 사전 정의 계량 파일 사용

### 파일 로드

```wolfram
InitCTensor["Schwarzschild"]
(* Coordinate System = {t, r, θ, ϕ} *)
```

`MetricPath` (기본값: `mGRG`Einstein`Metrics``)에서 `Schwarzschild.m` 파일을 로드한다.

### 사용 가능한 사전 정의 계량

| 파일명 | 시공간 |
|--------|--------|
| `"Schwarzschild"` | Schwarzschild 블랙홀 |
| `"Kerr"` | Kerr 회전 블랙홀 |
| `"KerrNewman"` | Kerr-Newman 대전 회전 블랙홀 |
| `"ReissnerNordstrom"` | Reissner-Nordstrom 대전 블랙홀 |
| `"RobertsonWalker"` | FLRW 우주론 계량 |

### 계량 파일의 내부 구조

각 계량 파일은 다음 패턴을 따른다:

1. `CsimplifyRules` 설정 (계량별 치환 규칙)
2. `Csimplify[]` 재정의 (계량별 단순화 전략)
3. 상수 선언 (`SetAttributes[_, Constant]`)
4. `Metricg` 성분 채우기 (`Table`로)
5. `InitCTensor[coSys, metric, opts]` 호출

### 커스텀 계량 파일 경로

```wolfram
MetricPath
(* mGRG`Einstein`Metrics` *)

(* 다른 경로를 사용하려면 *)
MetricPath = "/path/to/my/metrics/";
InitCTensor["MyMetric"]
```

---

## 5. Tcalc을 이용한 단계별 계산

`InitCTensor`의 옵션으로 사전 계산하지 않은 경우, `Tcalc`으로 개별적으로 계산한다.

### 표준 계산 순서

```wolfram
InitCTensor[coSys, metric]   (* 초기화만 — 곡률 사전 계산 없음 *)

Tcalc[GammaCD]               (* 1. Christoffel 기호 *)
Tcalc[RicciCD]               (* 2. Ricci 텐서 (내부적으로 Riemann도 계산) *)
Tcalc[ScalarCD]              (* 3. Ricci 스칼라 *)
Tcalc[RiemannCD]             (* 4. Riemann 텐서 (필요 시) *)
```

### simpCmd로 단순화 제어

```wolfram
(* 기본: Csimplify 사용 *)
Tcalc[GammaCD]

(* Simplify 사용 — 더 강력하지만 느림 *)
Tcalc[RiemannCD, Simplify]
(* Calculated R_abcd using Simplify in 0.02s *)
```

Schwarzschild에서 기본 `Csimplify`와 `Simplify`의 차이:

```wolfram
(* Csimplify (기본) — 정리되지 않은 형태 *)
Tcalc[RiemannCD]
Show[RiemannCD]
(* R_tθtθ = (-2G²M² + GMr)/r²
   R_tϕtϕ = (-2G²M²+2G²M²Cos[2θ]-GMrCos[2θ]+GMr)/(2r²) *)

(* Simplify — 깔끔한 형태 *)
Tcalc[RiemannCD, Simplify]
Show[RiemannCD]
(* R_tθtθ = -GM(2GM-r)/r²
   R_tϕtϕ = -GM(2GM-r)Sin[θ]²/r² *)
```

### 개별 성분 계산

특정 성분만 필요하면 인덱스를 직접 지정할 수 있다:

```wolfram
Tcalc[RiemannCD[-1, -2, -1, -2]]; RiemannCD[-1, -2, -1, -2]
(* Calculated R_trtr using Csimplify in 0.s *)
(* -2GM/r³ *)
```

---

## 6. 측지선 방정식 계산

### 기본 워크플로

```wolfram
coSys = {t, r, θ, ϕ};
metric = {{-(1-2GM/r), 0, 0, 0},
          {0, 1/(1-2GM/r), 0, 0},
          {0, 0, r^2, 0},
          {0, 0, 0, r^2 Sin[θ]^2}};

SetCTensor[coSys, metric, GammaCD → True]

(* 각 좌표 성분별 측지선 방정식 *)
Geodesic[1, Simplify]    (* t 성분 *)
(* -2GM ṙ ṫ/(2GMr - r²) + ẗ *)

Geodesic[2, Simplify]    (* r 성분 *)
(* GM ṙ²/(2GMr-r²) + GM(-2GM+r)ṫ²/r³
   + (2GM-r)θ̇² + r̈ + (2GM-r)ϕ̇² Sin[θ]² *)

Geodesic[3, Simplify]    (* θ 성분 *)
(* 2ṙθ̇/r + θ̈ - Cos[θ]ϕ̇²Sin[θ] *)

Geodesic[4, Simplify]    (* ϕ 성분 *)
(* 2ṙϕ̇/r + 2Cot[θ]θ̇ϕ̇ + ϕ̈ *)
```

각 결과를 0으로 놓으면 측지선 미분방정식이 된다:

$$\ddot{x}^\mu + \Gamma_{\alpha\beta}{}^\mu \dot{x}^\alpha \dot{x}^\beta = 0$$

### 주의사항

- **좌표 기저 전용**: `Geodesic`은 좌표 기저에서만 동작한다.
- **GammaCD 성분 계산 필수**: 최소한 `GammaCD → True` 옵션이 필요하다.
- 인자 `comp`는 좌표계에서의 순서 (1, 2, 3, ...)이다.

---

## 7. 환경 관리: ClearCTensor와 계량 전환

### ClearCTensor의 효과

```wolfram
ClearCTensor[];
Show[DefaultKind]
(* InitCTensorFlag: False
   Dimension: Any, Sig: Any, Coordinates: none
   CoordinateBasisQ: True, EvaluateBDFlag: False *)
```

해제 후 모든 텐서 성분이 기호적 표현으로 돌아간다:

```wolfram
{Metricg[-1, -1], Metricg[1, 1]}
(* {g_11, g^11} *)
```

### 계량 전환 시 반드시 ClearCTensor 호출

```wolfram
(* 올바른 전환 워크플로 *)
InitCTensor["Schwarzschild"]
(* ... 계산 ... *)
ClearCTensor[]                   (* 반드시 해제 *)
InitCTensor["RobertsonWalker"]   (* 새 계량 초기화 *)

(* 잘못된 워크플로 — ClearCTensor 누락 *)
InitCTensor["Schwarzschild"]
InitCTensor["RobertsonWalker"]   (* 이전 성분이 잔존할 수 있음! *)
```

### 내부 상태 확인

`ClearCTensor` 전후의 내부 변수 상태:

```wolfram
(* 초기화 후 *)
{InitCTensorFlag, EvaluateBDFlag}
(* {True, True} *)

ClearCTensor[];

(* 해제 후 *)
{InitCTensorFlag, EvaluateBDFlag}
(* {False, False} *)
```

`ClearCTensor`는 역기저 행렬(`inverseBasisMatrix`), 성분 계량(`cMetric`), 차원 정보(`nDimension`) 등의 내부 변수도 함께 초기화한다.
