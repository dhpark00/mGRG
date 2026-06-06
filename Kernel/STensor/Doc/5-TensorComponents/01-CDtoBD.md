# TensorComponents — CDtoBD

`mGRG`STensor`` 패키지의 `TensorComponents.m`에서 제공하는 공변 도함수 전개 함수이다.

---

### CDtoBD

#### 함수 시그니처

```wolfram
CDtoBD[expr, covD]
```

#### 설명 (Details)

Covariant derivative를 BD(basis derivative)와 affine connection 계수를 이용한 표현으로 변환한다. 옵션으로 공변 도함수의 이름이 있다.

$$\nabla_a T_b{}^c = D_a T_b{}^c - \Gamma_{ab}{}^p T_p{}^c + \Gamma_{ap}{}^c T_b{}^p$$

- `covD`를 생략하면 기본 공변 도함수 CD가 사용된다.
- 연속 적용하면 중첩된 공변 도함수를 단계별로 전개할 수 있다.
- 텐서가 아닌 표현의 Lie derivative는 의미가 없으므로 LD 안에 있는 CD는 변환되지 않는다.
- 옵션으로 다른 공변 도함수를 지정할 수 있다.

#### 예제 (Examples)

**기본 사용법:**

```wolfram
CD[la, F[lb, lc]]
CDtoBD[%]
(* ∇_aF_bc → ∂_aF_bc - F_dc Γ_ab^d - F_bd Γ_ac^d *)
```

**연속 적용 (중첩된 공변 도함수):**

```wolfram
CD[la, lb, v[uc]] - CD[lb, la, v[uc]]
CDtoBD[%]
(* ∇_a∇_bv^c - ∇_b∇_av^c
   → ∂_a∇_bv^c - ∂_b∇_av^c - ∇_dv^c Γ_ab^d + ∇_dv^c Γ_ba^d - ∇_av^d Γ_bd^c + ∇_bv^d Γ_ad^c *)

CDtoBD[%]
(* → ∂_a∂_bv^c - ∂_b∂_av^c - ... (완전 전개) *)
```

**LD 안의 CD는 변환 안 됨:**

```wolfram
LD[v, CD[la, F[lb, lc]]]
CDtoBD[%]
(* 𝓛_v∇_aF_bc → 𝓛_v∇_aF_bc  (변환 안 됨) *)
```

**다른 공변 도함수 지정 (옵션):**

```wolfram
Tdefine[ξ[ua]]  (* ξ의 Kind는 Latin *)

SetDefaultKind[Capital]  (* CD의 Kind는 Capital *)
DefDerivativeOperator[CovD, "𝒟", Greek]  (* CovD의 Kind는 Greek *)
Tdefine[V[uμ]]  (* V의 Kind는 Greek *)

{CovD[lμ, ξ[ua]], CovD[lμ, V[uν]]}
CDtoBD[#, CovD] & /@ %
(* {𝒟_μξ^a, 𝒟_μV^ν} → {∂̂_μξ^a, ∂̂_μV^ν + Γ[𝒟]_μα^ν V^α} *)

UndefTensor[V]; UndefDerivativeOperator[CovD]
SetDefaultKind[Latin]  (* 기본 설정 *)
```

#### 참고 (See Also)

`GammaToMetric`, `RiemannToGamma`, `LDtoCD`, `CommuteCD`
