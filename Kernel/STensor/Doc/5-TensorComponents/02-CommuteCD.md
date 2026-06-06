# TensorComponents — CommuteCD

`mGRG`STensor`` 패키지의 `TensorComponents.m`에서 제공하는 공변 도함수 교환 함수이다.

---

### CommuteCD

#### 함수 시그니처

```wolfram
CommuteCD[{a, b}, expr, covD]
```

#### 설명 (Details)

Covariant derivative가 두 번 이상 연속해서 작용할 때, 원래의 표현과 같으면서 두 CovD의 인덱스를 교환시킨 표현을 준다. 첫 번째 인자는 뒤 바꿀 두 개의 인덱스로 이루어진 리스트이고, 두 번째 인자는 임의의 표현이다. 옵션으로 공변 도함수의 이름이 있다.

$$(\nabla_a \nabla_b - \nabla_b \nabla_a + t_{ab}{}^p \nabla_p)\, T_c{}^d = \text{(riemannSign)}\left(R_{abc}{}^p T_p{}^d - R_{abp}{}^d T_c{}^p\right)$$

- 뒤 바꿀 두 개의 인덱스는 연속해서 있어야 한다.
- CD의 인덱스가 아니면 영향이 없다.
- 텐서 표현이 아닌 것에도 영향이 없다.

#### Torsion-Free가 아닌 경우

```wolfram
TorsionFreeQ[CD] = False;

expr = CD[la, lb, T[lc, ud]]
CommuteCD[{la, lb}, expr]
(* ∇_a∇_bT_c^d → ∇_b∇_aT_c^d - R_abe^d T_c^e + R_abc^e T_e^d - ∇_eT_c^d t_ab^e *)
```

#### Torsion-Free인 경우

```wolfram
TorsionFreeQ[CD] = True;

CommuteCD[{la, lb}, expr]
(* ∇_a∇_bT_c^d → ∇_b∇_aT_c^d - R_abe^d T_c^e + R_abc^e T_e^d *)
```

#### 다양한 인덱스 배치

```wolfram
expr = CD[la, ub, lc, F[lb, ud]]
CommuteCD[{la, ub}, expr]
(* ∇_a∇^b∇_cF_b^d → 결과에 Riemann 텐서가 등장 *)

(* 연속하지 않은 인덱스를 지정하면 변환 안 됨 *)
CommuteCD[{la, lc}, expr]
(* ∇_a∇^b∇_cF_b^d → ∇_a∇^b∇_cF_b^d  (변환 안 됨) *)
```

#### 벡터 및 스칼라에 대한 적용

```wolfram
CD[la, lb, v[uc]]
CommuteCD[{la, lb}, %]
(* ∇_a∇_bv^c → ∇_b∇_av^c - R_abd^c v^d  (기본적으로 torsion-free) *)

CD[la, lb, f[]]
CommuteCD[{la, lb}, %]
(* ∇_a∇_bf → ∇_b∇_af  (스칼라에는 Riemann 항 없고, 기본적으로 torsion-free) *)
```

#### BD를 포함하는 표현

```wolfram
expr = CD[la, BD[ub, CD[lc, F[lb, ud]]]]
CommuteCD[{la, ub}, expr]
(* ∇_a∂^b∇_cF_b^d → ∇_a∂^b∇_cF_b^d  (텐서 표현이 아니면 영향 없음) *)

expr = CD[la, ld, BD[ub, CD[lc, F[lb, ud]]]]
CommuteCD[{lb, ud}, expr]
(* 텐서 표현이 아니므로 영향 없음 *)
```

#### 다른 공변 도함수 지정 (옵션)

```wolfram
SetDefaultKind[Capital]
DefDerivativeOperator[CovD, "𝒟", Capital, TorsionFreeQ → False]
Tdefine[V[lA], 1]

{CovD[lA, lB, ξ[ua]], CovD[lA, lB, V[uC]]}  (* ξ의 Kind는 Latin *)
CommuteCD[{lA, lB}, #, CovD] & /@ %
(* {𝒟_B𝒟_Aξ^a - 𝒟_Cξ^a t_AB^C, 𝒟_B𝒟_AV^C - 𝒟_DV^C t_AB^D - R[𝒟]_ABC^C V^D} *)

UndefTensor[V]; UndefDerivativeOperator[CovD]
SetDefaultKind[Latin]
```

#### 참고 (See Also)

`CDtoBD`, `RiemannToGamma`, `LDtoCD`
