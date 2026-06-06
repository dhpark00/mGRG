# Einstein/CTensor — Geodesic

`mGRG`Einstein`` 패키지의 `CTensor.m`에서 제공하는 측지선 방정식 계산 함수이다.

---

### Geodesic

#### 함수 시그니처

```wolfram
Geodesic[comp]
Geodesic[comp, simpCmd]
```

#### 설명 (Details)

`Geodesic[comp]`는 지정된 좌표 성분 `comp`에 대한 측지선 방정식을 계산한다. `comp`는 좌표계에서의 순서 (정수)이다. `simpCmd`는 선택적 단순화 함수이다.

**제한**: 좌표 기저(Coordinate Basis)에서만 사용 가능하다. 비좌표 기저에서는 사용할 수 없다.

이 함수를 사용하려면 `InitCTensor`로 성분 텐서를 초기화해야 한다 (최소한 `GammaCD → True` 옵션 필요).

측지선 방정식:

$$\ddot{x}^\mu + \Gamma_{\alpha\beta}{}^\mu \dot{x}^\alpha \dot{x}^\beta = 0$$

`Geodesic[comp]`는 위 식의 좌변을 반환한다.

#### 예제 (Examples)

#### Schwarzschild 시공간

```wolfram
coSys = {t, r, θ, ϕ};
metric = {{-(1 - 2GM/r), 0, 0, 0},
          {0, 1/(1 - 2GM/r), 0, 0},
          {0, 0, r^2, 0},
          {0, 0, 0, r^2 Sin[θ]^2}};

SetCTensor[coSys, metric, GammaCD → True]

Geodesic[1, Simplify]
(* -2GM ṙ ṫ/(2GM r - r²) + ẗ *)

Geodesic[2, Simplify]
(* GM ṙ²/(2GM r - r²) + GM(-2GM+r) ṫ²/r³
   + (2GM-r) θ̇² + ṙ̈ + (2GM-r) ϕ̇² Sin[θ]² *)

Geodesic[3, Simplify]
(* 2 ṙ θ̇/r + θ̈ - Cos[θ] ϕ̇² Sin[θ] *)

Geodesic[4, Simplify]
(* 2 ṙ ϕ̇/r + 2 Cot[θ] θ̇ ϕ̇ + ϕ̈ *)
```

각 성분의 결과를 0으로 놓으면 측지선 미분방정식이 된다.

#### 참고 (See Also)

`InitCTensor`, `Tcalc`, `GammaCD`
