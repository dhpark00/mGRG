# TensorComponents — RiemannToGamma

`mGRG`STensor`` 패키지의 `TensorComponents.m`에서 제공하는 곡률 텐서를 connection 계수로 전개하는 함수이다.

---

### RiemannToGamma

#### 함수 시그니처

```wolfram
RiemannToGamma[expr, curvRL, covD]
```

#### 설명 (Details)

곡률 텐서 $R_{abc}{}^d$, Ricci 텐서 $R_{ab}$, Scalar 곡률 $R$을 connection $\Gamma_{ab}{}^c$로 바꾼다. 옵션으로 바꿀 텐서의 리스트와 공변 도함수의 이름이 있다.

$$R_{abc}{}^d \equiv -\left(D_a \Gamma_{bc}{}^d - D_b \Gamma_{ac}{}^d + \Gamma_{ap}{}^d \Gamma_{bc}{}^p - \Gamma_{bp}{}^d \Gamma_{ac}{}^p - f_{ab}{}^p \Gamma_{pc}{}^d\right) = R_{abc}{}^d \big|_\text{Wald} = R^d{}_{cba} \big|_\text{MTW}$$

- `curvRL`을 생략하면 Riemann, Ricci, Scalar 모두 전개된다.
- `curvRL`에 리스트로 전개할 텐서를 지정할 수 있다 (예: `{RicciCD}`, `{ScalarCD}`).
- `covD`를 생략하면 기본 공변 도함수 CD가 사용된다.
- Connection 계수는 proper 텐서가 아니므로 텐서 연산자가 있는 경우는 바꾸지 않는다.

#### Non-coordinate basis에서

```wolfram
Off[CoordinateBasisFlag]

RiemannToGamma[RiemannCD[la, lb, lc, ud]]
(* -∂̂_aΓ_bc^d + ∂̂_bΓ_ac^d - Γ_ae^d Γ_bc^e + Γ_ac^e Γ_be^d + Γ_ec^d f_ab^e *)
```

#### Coordinate basis에서

```wolfram
On[CoordinateBasisFlag]

RiemannToGamma[RiemannCD[la, lb, lc, ud]]
(* -∂_aΓ_bc^d + ∂_bΓ_ac^d - Γ_ae^d Γ_bc^e + Γ_ac^e Γ_be^d *)
```

#### 다양한 인덱스 배치

```wolfram
RiemannToGamma[RiemannCD[la, lb, lc, ld]]
(* -Γ_aed Γ_bc^e + Γ_ac^e Γ_bed - ∂_aΓ_bc^e g_de + ∂_bΓ_ac^e g_de *)

RiemannToGamma[RiemannCD[la, lb, uc, ud]]
(* Γ_a^ce Γ_b^d_c - Γ_ae^d Γ_b^ce - ∂_aΓ_be^d g^be g^cf + ∂_eΓ_ac^d g^be g^cf *)

RiemannToGamma[RiemannCD[la, ub, lc, ld]]
(* -Γ_ae^b_e Γ_b^d - Γ_aed Γ_ec^b g^be + ... *)

RiemannToGamma[RiemannCD[la, ub, uc, ud]]
(* Γ_a^ce Γ_b^d_e - Γ_ae^d Γ_bce - ... *)

RiemannToGamma[RiemannCD[ua, lb, lc, ld]]
(* Γ_bed Γ_c^a_e - Γ_bc^e Γ_aed + ∂_bΓ_ec^f g_df g^ae - ∂_eΓ_bc^f g_df g^ae *)
```

#### 텐서 연산자와 함께 사용

Connection 계수는 proper 텐서가 아니므로 텐서 연산자가 있는 경우는 바꾸지 않는다:

```wolfram
CD[ld, RiemannCD[la, lb, lc, ud]]
RiemannToGamma[%]
(* ∇_dR_abc^d → ∇_dR_abc^d  (변환 안 됨) *)

BD[ld, RiemannCD[la, lb, lc, ud]]
RiemannToGamma[%]
(* ∂_dR_abc^d → -∂_d∂_aΓ_bc^d + ∂_d∂_bΓ_ac^d + ∂_dΓ_be^d Γ_ac^e - ... *)
```

#### Ricci 텐서

같은 함수를 이용한다:

```wolfram
RiemannToGamma[RicciCD[la, lb]]
(* -∂_aΓ_cb^c + ∂_cΓ_ab^c - Γ_ac^d Γ_db^c + Γ_ab^c Γ_dc^d *)

RiemannToGamma[RicciCD[la, ub]]
(* Γ_a^bc Γ_dc^d - Γ_ac^d Γ_d^bc - ∂_aΓ_cd^c g^bd + ∂_cΓ_ad^c g^bd *)

RiemannToGamma[RicciCD[ua, lb]]
(* Γ_cd^c Γ_a^d_b - Γ_cb^d Γ_a^d_c - ∂_cΓ_db^c g^ac + ∂_cΓ_db^c g^ad *)

RiemannToGamma[RicciCD[ua, ub]]
(* -Γ_c^bd Γ_a^d_c + Γ_cd^c Γ^abd - ∂_cΓ_de^d g^ac g^be + ∂_cΓ_de^c g^ad g^be *)
```

**BD와 함께 사용:**

```wolfram
BD[lb, RicciCD[la, ub]]
RiemannToGamma[%]
(* ∂_bR_a^b → (완전 전개) *)
```

#### Ricci 텐서만 전개

`curvRL` 옵션에서 지정:

```wolfram
RiemannCD[ua, ub, lc, ld] × RicciCD[la, lb]
RiemannToGamma[%, {RicciCD}]
(* R_ab R^ab_cd → Γ_ab^e Γ_fe^f R^ab_cd - ... (Ricci만 전개, Riemann은 그대로) *)
```

#### Scalar 곡률

```wolfram
RiemannToGamma[ScalarCD[]]
(* Γ_a^ab Γ_cb^c - Γ_ab^c Γ_c^ab - ∂_aΓ_bc^b g^ac + ∂_aΓ_bc^a g^bc *)

BD[la, ScalarCD[]]
RiemannToGamma[%]
(* ∂_aR → (완전 전개) *)
```

#### Scalar 곡률만 전개

```wolfram
ScalarCD[] × RicciCD[la, lb]
RiemannToGamma[%, {ScalarCD}]
(* R_ab R → Γ_cd^c Γ_ed^e R_ab - ... (Scalar만 전개, Ricci는 그대로) *)
```

#### 다른 공변 도함수 지정

```wolfram
SetDefaultKind[Capital]
DefDerivativeOperator[CovD, "𝒟", Latin, TorsionFreeQ → False]

ScalarCD[] × RicciCovD[la, lb] × RicciCovD[lc, ua, ld, ub]
RiemannToGamma[%, {RicciCovD}, CovD]
(* R[𝒟]_ab R[𝒟]_c^a_d^b R → Γ[𝒟]_ab^e Γ[𝒟]_fe^f R[𝒟]_c^a_d^b R - ... *)

UndefDerivativeOperator[CovD];
SetDefaultKind[Latin]  (* 기본 설정 *)
```

#### 참고 (See Also)

`CDtoBD`, `GammaToMetric`, `CommuteCD`
