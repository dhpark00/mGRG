# Einstein/CTensor — InitCTensor / ClearCTensor

`mGRG`Einstein`` 패키지의 `CTensor.m`에서 제공하는 성분 텐서 초기화 및 해제 함수이다.

---

### InitCTensor (SetCTensor)

#### 함수 시그니처

```wolfram
InitCTensor[coSys, metric, opts]
InitCTensor[coSys, metric, basisM, opts]
InitCTensor["MetricName"]
```

`SetCTensor`는 `InitCTensor`의 별칭(alias)이다.

#### 설명 (Details)

`InitCTensor`는 성분 텐서 계산을 위한 환경을 초기화한다. `coSys`는 좌표계 리스트, `metric`은 계량 행렬이다. 옵션으로 곡률 텐서의 사전 계산과 단순화 수준을 설정할 수 있다.

초기화 시 다음이 설정된다:

- Dimension, Coordinates, CoordinateBasisQ
- `InitCTensorFlag` → `True`
- `EvaluateBDFlag` → `True`
- 계량 텐서 성분 (`Metricg`)

##### 좌표 기저 (Coordinate Basis)

두 인자(`coSys`, `metric`)만 전달하면 좌표 기저로 초기화된다:

```wolfram
coSys = {t, x};
metric = {{-E^(2 ρ[t, x]), 0}, {0, E^(2 ρ[t, x])}};

InitCTensor[coSys, metric, RicciCD → True, FourDimensionQ → False]
```

좌표 기저에서는 `CoordinateBasisQ → True`, `Structuref` = 0이다.

##### 비좌표 기저 (Non-Coordinate Basis)

세 번째 인자로 기저 행렬 `basisM`을 전달하면 비좌표 기저로 초기화된다:

```wolfram
coSys = {t, x};
metric = {{-1, 0}, {0, 1}};
basisM = {{E^(-ρ[t, x]), 0}, {0, E^(-ρ[t, x])}};

InitCTensor[coSys, metric, basisM, RicciCD → True, FourDimensionQ → False]
```

Orthonormal Basis ($e_a^A = h_a^\mu \partial_\mu^A$)에서 `basisM` = $h_a^\mu$이다. 비좌표 기저에서는 `CoordinateBasisQ → False`, `Structuref` ≠ 0이다.

#### 옵션

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `SimplifyMore` | `False` | `True`로 설정하면 `CsimplifyMore`를 기본 단순화 방법으로 사용 |
| `Verbose` | `False` | `True`로 설정하면 계산 단계와 소요 시간을 출력 |
| `GammaCD` | `False` | `True`로 설정하면 초기화 시 Christoffel 기호를 사전 계산 |
| `RiemannCD` | `False` | `True`로 설정하면 초기화 시 Riemann 텐서까지 사전 계산 |
| `RicciCD` | `False` | `True`로 설정하면 초기화 시 Ricci 텐서까지 사전 계산 |
| `FourDimensionQ` | `True` | `True`이면 4차원 시공간을 강제. 다른 차원에서는 `False`로 설정 |

#### 예제 (Examples)

##### 좌표 기저 초기화

```wolfram
coSys = {t, x};
metric = {{-E^(2 ρ[t, x]), 0}, {0, E^(2 ρ[t, x])}};

InitCTensor[coSys, metric, RicciCD → True, FourDimensionQ → False];
Show[DefaultKind]
(* Kind: Latin, Dimension: 2, Coordinates: t x,
   CoordinateBasisQ: True, EvaluateBDFlag: True *)

Show[LineElement]
(* ds² = -e^{2ρ[t,x]} (dt² - dx²) *)

Show[Metricg]
(* Symmetry: g_{(ab)}
   g_tt = -e^{2ρ[t,x]}
   g_xx =  e^{2ρ[t,x]} *)
```

##### 좌표 기저 — 곡률 텐서 출력

```wolfram
Show[Structuref]
(* f_{ab}^c = 0 *)

Show[GammaCD]
(* Symmetry: Γ_{(ab)}^c
   Γ_tt^t = ρ^{(1,0)}[t,x],  Γ_tt^x = ρ^{(0,1)}[t,x], ...  *)

Show[RiemannCD]
(* Symmetry: R_{(ab)(cd)} = R_{(cd)(ab)}
   R_txtx = e^{2ρ[t,x]} (ρ^{(0,2)}[t,x] - ρ^{(2,0)}[t,x]) *)

Show[RicciCD]
(* Symmetry: R_{(ab)}
   R_tt = ρ^{(0,2)}[t,x] - ρ^{(2,0)}[t,x]
   R_xx = -ρ^{(0,2)}[t,x] + ρ^{(2,0)}[t,x] *)

Show[ScalarCD]
(* R = -2 e^{-2ρ[t,x]} (ρ^{(0,2)}[t,x] - ρ^{(2,0)}[t,x]) *)
```

##### 비좌표 기저 초기화

```wolfram
coSys = {t, x};
metric = {{-1, 0}, {0, 1}};
basisM = {{E^(-ρ[t, x]), 0}, {0, E^(-ρ[t, x])}};

InitCTensor[coSys, metric, basisM, RicciCD → True, FourDimensionQ → False];
Show[DefaultKind]
(* Kind: Latin, Dimension: 2, Coordinates: t x,
   CoordinateBasisQ: False, EvaluateBDFlag: True *)

Show[LineElement]
(* ds² = -dt² + dx² *)

Show[Metricg]
(* g_11 = -1, g_22 = 1 *)

Show[Structuref]
(* Symmetry: f_{(ab)}^c
   f_12^1 = e^{-ρ[t,x]} ρ^{(0,1)}[t,x]
   f_12^2 = -e^{-ρ[t,x]} ρ^{(1,0)}[t,x] *)

Show[RiemannCD]
(* R_1212 = e^{-2ρ[t,x]} (ρ^{(0,2)}[t,x] - ρ^{(2,0)}[t,x]) *)

Show[ScalarCD]
(* R = -2 e^{-2ρ[t,x]} (ρ^{(0,2)}[t,x] - ρ^{(2,0)}[t,x]) *)
```

##### 4차원이 아닌 경우 오류

```wolfram
InitCTensor[coSys, metric, RicciCD → True]
(* Msg: It is assumed a four-dimensional spacetime. But the number of coordinates is not four!
   Use FourDimensionQ → False option *)
(* $Failed *)
```

---

### InitCTensor from a File

#### 설명 (Details)

좌표계, metric, InitCTensor 명령, 옵션 등을 포함한 파일이 `MetricPath/filename.m`에 있을 때, 파일 이름을 입력으로 받아 성분 텐서를 초기화한다. `MetricPath`의 기본값은 `mGRG`Einstein`Metrics``이다.

#### 예제 (Examples)

```wolfram
MetricPath
(* mGRG`Einstein`Metrics` *)

Timing[InitCTensor["Schwarzschild"]]
(* Coordinate System = {t, r, θ, ϕ}
   {0.042113, Null} *)

Show[LineElement, Simplify]
(* ds² = dr²/(1-2GM/r) + (-1+2GM/r) dt² + r²(dθ² + dϕ² Sin[θ]²) *)

Show[Metricg]
(* g_tt = -1 + 2GM/r,  g_rr = 1/(1-2GM/r),
   g_θθ = r²,  g_ϕϕ = r² Sin[θ]² *)
```

사용 가능한 사전 정의 계량: Schwarzschild, Kerr, KerrNewman, ReissnerNordstrom, RobertsonWalker.

`MetricPath`의 값을 변경하면 다른 위치의 파일을 사용할 수 있다.

---

### ClearCTensor

#### 함수 시그니처

```wolfram
ClearCTensor[]
```

#### 설명 (Details)

`ClearCTensor[]`는 이전에 계산된 모든 성분 텐서를 해제하고 CTensor 환경을 초기 상태로 되돌린다.

해제 후 상태:

| 항목 | 값 |
|------|------|
| `InitCTensorFlag` | `False` |
| `EvaluateBDFlag` | `False` |
| Dimension | `Any` |
| Sig | `Any` |
| Coordinates | `none` |

**중요**: 다른 계량으로 전환하기 전에 반드시 `ClearCTensor[]`를 호출해야 한다.

#### 예제 (Examples)

```wolfram
ClearCTensor[];
Show[DefaultKind]
(* InitCTensorFlag: False
   Dimension: Any, Sig: Any, Coordinates: none
   CoordinateBasisQ: True, EvaluateBDFlag: False *)

{Metricg[-1, -1], Metricg[1, 1]}
(* {g_11, g^11} *)
(* — 성분값이 아닌 기호적 표현으로 돌아감 *)
```

#### 참고 (See Also)

`InitCTensor`, `Tcalc`, `Show`
