# TensorComponents — LDtoCD

`mGRG`STensor`` 패키지의 `TensorComponents.m`에서 제공하는 Lie 도함수를 공변 도함수로 변환하는 함수이다.

---

### LDtoCD

#### 함수 시그니처

```wolfram
LDtoCD[expr, covD]
```

#### 설명 (Details)

Lie derivative를 covariant derivative로 바꾼다.

$$\mathcal{L}_v T_a{}^b = v^p \nabla_p T_a{}^b + (\nabla_a v^p) T_p{}^b - (\nabla_p v^b) T_a{}^p$$

- `covD`를 생략하면 기본 torsion-free 공변 도함수 CD가 사용된다.
- covD가 Torsion-Free 아니면 변환되지 않는다 (경고 메시지 출력).
- 텐서 표현이 아니거나 covD와 부합되지 않는 것은 변환되지 않는다.
- 좌표 기준계(coordinate basis)에서 torsion-free이면 $\Gamma_{ab}{}^c = \Gamma_{(ab)}{}^c$이므로 $\mathcal{L}_v \xi_a = v^b \partial_b \xi_a + \xi_b \partial_a v^b$.

#### Torsion-Free가 아닌 경우

```wolfram
TorsionFreeQ[CD] = False;

LDtoCD[LD[v, t[ua, ub]]]
(* Msg: CD is not torsion-free *)
(* 𝓛_vt[ua,ub] → 𝓛_vt[ua,ub]  (변환 안 됨) *)
```

#### Torsion-Free인 경우

```wolfram
TorsionFreeQ[CD] = True;

LD[v, ξ[la]]
% // LDtoCD
(* 𝓛_vξ_a → ∇_bξ_a v^b + ∇_av^b ξ_b *)
```

**좌표 기준계에서 CDtoBD로 추가 전개:**

```wolfram
CoordinateBasisQ[DefaultKind]
(* True *)

CDtoBD[%%]
% // Tsimplify
(* ∂_bξ_a v^b + ∂_av^b ξ_b *)
```

**다양한 텐서에 적용:**

```wolfram
LD[v, T[la, ub]]
% // LDtoCD
(* 𝓛_vT_a^b → -∇_cv^b T_a^c + ∇_av^c T_c^b + ∇_cT_a^b v^c *)

CD[1, LD[v, T[ua, ub]]]
% // LDtoCD
(* ∇^1𝓛_vT^ab → ∇^1v^c ∇_cT^ab - ∇^1T^cb ∇_cv^a - ∇^1T^ac ∇_cv^b
   - ∇^1∇_cv^a T^cb - ∇^1∇_cv^b T^ac + ∇^1∇_cT^ab v^c *)
```

**LD 안에 있는 CD:**

```wolfram
LD[v, CD[la, T[ua, ub]]]
% // LDtoCD
(* 𝓛_v∇_aT^ab → -∇_aT^ac ∇_cv^b + ∇_a∇_c T^cb v^a *)
```

**텐서 곱 표현:**

```wolfram
LD[v, T[lb, lc] × CD[la, T[ua, ub]]]
% // LDtoCD
(* ∇_aT^ab 𝓛_vT_bc + 𝓛_v∇_aT^ab T_bc
   → (완전 전개된 형태) *)
```

#### 다른 CovD 지정

```wolfram
DefDerivativeOperator[CovD, "D", Latin]

expr = LD[v, T[la, lb]]
LDtoCD[expr]
(* 𝓛_vT_ab → ∇_bv^c T_ac + ∇_av^c T_cb + ∇_cT_ab v^c *)

LDtoCD[expr, CovD]
(* 𝓛_vT_ab → D_bv^c T_ac + D_av^c T_cb + D_cT_ab v^c *)

LDtoCD[expr, BD]
(* 𝓛_vT_ab → ∂_bv^c T_ac + ∂_av^c T_cb + ∂_cT_ab v^c *)
```

#### 비좌표 기준계에서의 참고

비좌표 기준계(non-coordinate basis)에서:

```wolfram
Off[CoordinateBasisFlag]
LDtoCD[expr]
CDtoBD[%]
% // Tsimplify
(* ∂̂_bv^c T_ac + ∂̂_av^c T_cb + ∂̂_cT_ab v^c
   + Γ_bcd T_a^d v^c + Γ_acd T_b^d v^c - Γ_cbd T_a^d v^c - Γ_cad T_b^d v^c *)
```

좌표 기준계(coordinate basis)에서:

```wolfram
On[CoordinateBasisFlag]
LDtoCD[expr]
CDtoBD[%]
% // Tsimplify
(* ∂_bv^c T_ac + ∂_av^c T_bc + ∂_cT_ab v^c *)
```

#### 변환되지 않는 경우

텐서 표현이 아니거나 CovD와 부합되지 않는 것은 변환되지 않는다:

```wolfram
LD[v, something[la]]
% // LDtoCD
(* 𝓛_vsomething_a → 𝓛_vsomething_a  (변환 안 됨) *)

LD[v, BD[la, f[]]]
% // LDtoCD
(* 𝓛_v∂_af → 𝓛_v∂_af  (변환 안 됨) *)
```

**BD, CovD 내부의 LD:**

```wolfram
LD[v, BD[la, f[]]]
LDtoCD[%, BD]
(* 𝓛_v∂_af → 𝓛_v∂_af  (BD는 텐서 연산자가 아니므로 변환 안 됨) *)

BD[la, LD[v, f[]]]
% // LDtoCD
(* ∂_a𝓛_vf → ∂_a𝓛_vf  (변환 안 됨) *)

BD[la, LD[v, f[]]]
LDtoCD[%, BD]
(* ∂_a𝓛_vf → ∂_av^b ∂_bf + ∂_a∂_bf v^b *)

CovD[la, LD[v, f[]]]
% // LDtoCD
(* D_a𝓛_vf → D_a𝓛_vf  (변환 안 됨) *)

CD[la, LD[v, f[]]]
LDtoCD[%, CovD]
(* ∇_a𝓛_vf → ∇_a𝓛_vf  (CovD와 CD가 다르므로 변환 안 됨) *)

CovD[la, LD[v, f[]]]
LDtoCD[%, CovD]
(* D_a𝓛_vf → D_av^b D_bf + D_aD_bf v^b *)
```

#### 참고 (See Also)

`CDtoBD`, `CommuteCD`, `LD`
