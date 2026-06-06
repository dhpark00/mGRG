# TensorComponents — GammaToMetric

`mGRG`STensor`` 패키지의 `TensorComponents.m`에서 제공하는 connection 계수를 계량 텐서 표현으로 변환하는 함수이다.

---

### GammaToMetric

#### 함수 시그니처

```wolfram
GammaToMetric[expr, covD]
```

#### 설명 (Details)

임의의 표현에 있는 metric-connection $\Gamma_{ab}{}^c$를 계량 텐서 표현으로 변환한다. 옵션으로 공변 도함수의 이름이 있다.

$$\Gamma_{ab}{}^c = g^{cd}\,\Gamma_{abd} = \Gamma^c{}_{ba} \big|_\text{MTW, Wald}$$

$$\Gamma_{abc} \equiv \frac{1}{2}\left(D_a\, g_{bc} + D_b\, g_{ac} - D_c\, g_{ab} + f_{abc} + f_{cba} + t_{abc} + t_{cba} + t_{cab}\right)$$

- `covD`를 생략하면 기본 공변 도함수 CD가 사용된다.
- Covariant derivative를 AffineCD로 변환한 후 다시 Metricg의 표현으로 변환시키는 경우에 활용한다.

#### Torsion-Free가 아니고 Non-coordinate basis에서

```wolfram
TorsionFreeQ[CD] = False;
Off[CoordinateBasisFlag]

GammaToMetric[GammaCD[la, lb, lc]]
(* 1/2 ∂̂_ag_bc + 1/2 ∂̂_bg_ac - 1/2 ∂̂_cg_ab
   + 1/2 f_abc + 1/2 f_cab + 1/2 f_cba
   + 1/2 t_abc + 1/2 t_cab + 1/2 t_cba *)
```

#### Torsion-Free가 아니고 Coordinate basis에서

```wolfram
On[CoordinateBasisFlag]

GammaToMetric[GammaCD[la, lb, lc]]
(* 1/2 ∂_ag_bc + 1/2 ∂_bg_ac - 1/2 ∂_cg_ab
   + 1/2 t_abc + 1/2 t_cab + 1/2 t_cba *)
```

#### Torsion-Free이고 Coordinate basis에서

```wolfram
TorsionFreeQ[CD] = True;

GammaToMetric[GammaCD[la, lb, lc]]
(* 1/2 ∂_ag_bc + 1/2 ∂_bg_ac - 1/2 ∂_cg_ab *)
```

#### 인덱스가 올라간 경우

```wolfram
GammaToMetric[GammaCD[la, lb, uc]]
(* 1/2 ∂_ag_bd g^cd + 1/2 ∂_bg_ad g^cd - 1/2 ∂_dg_ab g^cd *)

GammaToMetric[GammaCD[la, ub, lc]]
(* 1/2 ∂_ag_dc g^bd - 1/2 ∂_cg_ad g^bd + 1/2 ∂_dg_ac g^bd *)

GammaToMetric[GammaCD[ua, lb, lc]]
(* 1/2 ∂_bg_dc g^ad - 1/2 ∂_cg_db g^ad + 1/2 ∂_dg_bc g^ad *)

GammaToMetric[GammaCD[ua, lb, uc]]
(* -1/2 ∂_dg_eb g^ae g^cd + 1/2 ∂_bg_de g^ad g^ce + 1/2 ∂_dg_be g^ad g^ce *)

GammaToMetric[GammaCD[ua, ub, lc]]
(* 1/2 ∂_dg_ec g^ae g^bd - 1/2 ∂_cg_de g^ad g^be + 1/2 ∂_dg_ec g^ad g^be *)

GammaToMetric[GammaCD[ua, ub, uc]]
(* -1/2 ∂_dg_ef g^ae g^bf g^cd + 1/2 ∂_dg_ef g^ae g^bd g^cf + 1/2 ∂_dg_ef g^ad g^be g^cf *)
```

#### CDtoBD → GammaToMetric 연쇄 적용

```wolfram
CD[la, lb, F[ua, ub]]
CDtoBD[%]
CDtoBD[%]
(* 2단계에 걸쳐 완전 전개 *)

% // Tsimplify
(* -1/2 ∂_ag_bc ∂_dg^cb F^ad *)

% /. BDinvgRule[]
(* 1/2 ∂_ag_bc ∂_dg_ef F^ad g^bf g^ce *)

% // Tsimplify
(* 0 *)
```

#### 다른 공변 도함수와 Metric 지정

```wolfram
SetDefaultKind[Capital]
Off[CoordinateBasisFlag[Latin]];
DefDerivativeOperator[CovD, "𝒟", Latin];
DefMetric[Phi, "Φ", Latin]

(* CovD와 Phi는 아직 서로 관련이 없다 *)
GammaCovD[la, lb, lc]
GammaToMetric[%, CovD]
(* Msg: CovD is not metric-compatible with Phi *)

SetMetricCompatible[CovD, Phi]

GammaCovD[la, lb, lc]
GammaToMetric[%, CovD]
(* Γ[𝒟]_abc → 1/2 ∂̂_aΦ_bc + 1/2 ∂̂_bΦ_ac - 1/2 ∂̂_cΦ_ab + 1/2 f_abc + 1/2 f_cab + 1/2 f_cba *)

ClearMetricCompatible[CovD, Phi]; UndefMetric[Phi]; UndefDerivativeOperator[CovD]
SetDefaultKind[Latin];
On[CoordinateBasisFlag[Latin]]  (* 기본 설정 *)
```

#### 참고 (See Also)

`CDtoBD`, `RiemannToGamma`, `BDinvgRule`
