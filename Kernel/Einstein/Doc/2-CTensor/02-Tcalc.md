# Einstein/CTensor — Tcalc

`mGRG`Einstein`` 패키지의 `CTensor.m`에서 제공하는 성분 텐서 계산 함수이다.

---

### Tcalc

#### 함수 시그니처

```wolfram
Tcalc[tensor]
Tcalc[tensor, simpCmd]
```

#### 설명 (Details)

`Tcalc[tensor]`는 주어진 텐서의 성분을 계산한다. `simpCmd`는 선택적 단순화 함수이다 (예: `Simplify`).

계산 가능한 텐서:

| 텐서           | 기호                | 설명                     |
| ------------ | ----------------- | ---------------------- |
| `Structuref` | $f_{ab}{}^c$      | 구조 상수 (비좌표 기저에서 존재)    |
| `GammaCD`    | $\Gamma_{ab}{}^c$ | Christoffel 기호 (접속 계수) |
| `RicciCD`    | $R_{ab}$          | Ricci 텐서               |
| `ScalarCD`   | $R$               | Ricci 스칼라 (스칼라 곡률)     |
| `RiemannCD`  | $R_{abcd}$        | Riemann 곡률 텐서          |

이 함수를 사용하려면 `InitCTensor`로 먼저 성분 텐서를 초기화해야 한다.

##### 계산 의존성

각 텐서의 계산은 하위 텐서에 의존한다. `Tcalc`은 필요한 하위 텐서를 자동으로 계산한다:

```
GammaCD   ← g^{ab}, ∂_a g_{bc}  (+ Structuref for non-coordinate basis)
RicciCD   ← RiemannCD (내부적으로 R_{abcd}를 먼저 계산)
ScalarCD  ← RicciCD
RiemannCD ← GammaCD
```

#### 예제 (Examples)

##### 기본 사용법 — Schwarzschild 시공간

```wolfram
coSys = {t, r, θ, ϕ};
metric = {{-(1 - 2GM/r), 0, 0, 0},
          {0, 1/(1 - 2GM/r), 0, 0},
          {0, 0, r^2, 0},
          {0, 0, 0, r^2 Sin[θ]^2}};

InitCTensor[coSys, metric, Verbose → True]
(* Total setup time: 0.s *)
```

##### Structure constant

```wolfram
Tcalc[Structuref]
Show[Structuref]
(* f_{ab}^c = 0 *)
```

좌표 기저에서는 항상 0이다.

##### Christoffel 기호

```wolfram
Tcalc[GammaCD]
(* Calculated g^ab using Csimplify in 0.01s
   Calculated ∂_a g_bc using Csimplify in 0.s
   Calculated Γ_abc using Csimplify in 0.s
   Calculated Γ_{ab}^c using Csimplify in 0.s *)

Show[GammaCD]
(* Symmetry: Γ_{(ab)}^c
   Γ_tt^r = (-2G²M² + GMr)/r³
   Γ_tr^t = -GM/((2GM-r)r)
   Γ_rr^r = GM/((2GM-r)r)
   Γ_rθ^θ = 1/r
   Γ_rϕ^ϕ = 1/r
   Γ_θθ^r = 2GM - r
   Γ_θϕ^θ = Cot[θ]
   Γ_ϕϕ^r = (2GM - r - 2GM Cos[2θ] + r Cos[2θ])/2
   Γ_ϕϕ^θ = -Sin[2θ]/2 *)
```

##### 곡률 텐서

```wolfram
Tcalc[RicciCD]
(* Calculated R_abcd using Csimplify in 0.01s
   Calculated R_ab using Csimplify in 0.01s *)

Show[RicciCD]
(* Symmetry: R_{(ab)}
   R_ab = 0 *)

Tcalc[ScalarCD]
Show[ScalarCD]
(* R = 0 *)
```

Schwarzschild는 진공해이므로 Ricci 텐서와 스칼라 곡률이 모두 0이다.

##### Riemann 텐서 — 개별 성분 계산

```wolfram
Tcalc[RiemannCD[-1, -2, -1, -2]]
(* Calculated R_trtr using Csimplify in 0.s *)

RiemannCD[-1, -2, -1, -2]
(* -2GM/r³ *)
```

특정 성분만 지정하여 계산할 수 있다.

##### simpCmd 지정

```wolfram
Tcalc[RiemannCD, Simplify]
(* Calculated R_abcd using Simplify in 0.02s *)

Show[RiemannCD]
(* Symmetry: R_{(ab)(cd)} = R_{(cd)(ab)}
   R_trtr = -2GM/r³
   R_tθtθ = -GM(2GM-r)/r²
   R_tϕtϕ = -GM(2GM-r)Sin[θ]²/r²
   R_rθrθ = GM/(2GM-r)
   R_rϕrϕ = GM Sin[θ]²/(2GM-r)
   R_θϕθϕ = 2GMr Sin[θ]² *)
```

`Simplify`를 지정하면 기본 `Csimplify` 대신 Mathematica의 `Simplify`를 사용한다.

#### 참고 (See Also)

`InitCTensor`, `ClearCTensor`, `Show`, `Csimplify`
