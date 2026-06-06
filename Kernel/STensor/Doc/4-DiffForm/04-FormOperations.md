# DiffForm — 미분 형식 연산 (ApplyXD, CollectForm, FtoC, CoordRep)

`mGRG`STensor`` 패키지의 `DiffForm.m`에서 제공하는 미분 형식의 연산 및 변환 함수들이다. DiffForm 모듈은 실험적(Experimental) 기능이다.

---

### ApplyXD

#### 함수 시그니처

```wolfram
ApplyXD[expr]
```

#### 설명 (Details)

외미분 `XD`를 표현식에 명시적으로 적용하여, 정의된 좌표에 대한 기저 도함수 `BD`로 전개한다.

- 좌표가 설정되어 있어야 한다 (`SetCoordinates`).
- `EvaluateBDFlag`가 `On`이면 BD가 실제로 계산된다. 기본 설정은 `Off`이다.

#### 예제 (Examples)

```wolfram
SetCoordinates[{t, r, θ, ϕ}]
SetAttributes[{m}, Constant]

expr = {(1 - 2 m/r)^(1/2) XD[t], (1 - 2 m/r)^(-1/2) XD[r],
        r XD[θ], r Sin[θ] XD[ϕ]}

(* EvaluateBDFlag Off *)
expr // ApplyXD
(* 각 항에 대해 XD를 BD로 전개 *)

(* EvaluateBDFlag On *)
On[EvaluateBDFlag]
expr // ApplyXD
(* BD가 실제로 계산된 결과 *)

Off[EvaluateBDFlag]  (* 기본 설정 *)
ClearCoordinates[]
```

#### 참고 (See Also)

`XD`, `FtoC`, `BD`, `SetCoordinates`, `EvaluateBDFlag`

---

### CollectForm

#### 함수 시그니처

```wolfram
CollectForm[expr]
```

#### 설명 (Details)

표현식에서 동일한 미분 형식 항들을 모은다. Mathematica의 `Collect`가 일반 대수 표현식에서 동작하는 것과 유사하게, 미분 형식 표현식에 대해 동작한다.

#### 예제 (Examples)

```wolfram
Tdefine[ξ[ua]]; Fdefine[w1, 1]; Fdefine[w2, 2]; Fdefine[x[ua], 0]

expr = IP[ξ, XD[w1]]
FtoC[expr, {la, lb, lc}] × XD[x[ua]] ∧ XD[x[ub]] ∧ XD[x[uc]]

(* SumDum 후 CollectForm *)
SumDum[%, {1, 3}]
CollectForm[%]
(* dx^3 (...) + dx^2 (...) + dx^1 (...) *)
```

#### 참고 (See Also)

`FtoC`, `CoordRep`, `XD`, `SumDum`

---

### FtoC (Form to Component)

#### 함수 시그니처

```wolfram
FtoC[expr]
FtoC[expr, {indices}]
```

#### 설명 (Details)

미분 형식 표현을 대응하는 반대칭 텐서(indexed-tensor) 성분 표현으로 변환한다.

- `FtoC[expr]`는 기본 인덱스를 자동으로 할당하여 변환한다.
- `FtoC[expr, {indices}]`는 지정된 인덱스를 사용하여 변환한다.
- 모든 미분 형식 연산자 (XP, XD, IP, LD, HodgeStar, CoXD)의 텐서 성분 표현을 생성한다.
- `TorsionFreeQ[CD]`의 설정에 따라 XD의 텐서 표현이 달라진다:
  - `True` (기본): $d\omega$는 공변 도함수 CD로 표현
  - `False`: $d\omega$는 기저 도함수 BD로 표현
- `XDtoCDfrag` 플래그가 `On`이면 (기본 상태) XD를 CD로 변환한다.

#### 예제 (Examples)

##### p-form

```wolfram
Tdefine[f[]]; Tdefine[ξ[ua]]; Tdefine[T[la, lb]]
Fdefine[w0, 0]; Fdefine[w1, 1]; Fdefine[w2, 2]; Fdefine[w3, 3]; Fdefine[w4, 4]
Fdefine[α[la], 1]; Fdefine[β[la], 1]
Fdefine[ω[ua], 2]; Fdefine[Ω[ua, ub], 2, "-ba"]

(* 기본 변환 *)
f T[la, lb]
% // FtoC
(* f T_ab *)

ξ[ua] × T[lb, lc] w1
% // FtoC
(* T_bc w1_d ξ^a *)

T[la, lb] × ω[uc]
% // FtoC
(* T_ab ω_de^c *)
```

##### XD (Exterior Derivative)

```wolfram
(* torsion-free *)
XD[w1]
% // FtoC
(* dw1 → ∇_a w1_b - ∇_b w1_a *)

(* torsion 있는 경우 *)
TorsionFreeQ[CD] = False;
XD[w1] // FtoC
(* dw1 → ∂_a w1_b - ∂_b w1_a *)
TorsionFreeQ[CD] = True;  (* 기본 설정 *)
```

##### XP (Exterior Product)

```wolfram
XP[XD[x], XD[y]]
% // FtoC
(* dx∧dy → -∇_a y ∇_b x + ∇_a x ∇_b y *)

XP[w1, w2]
% // FtoC
(* w1∧w2 → w1_c w2_ab - w1_b w2_ac + w1_a w2_bc *)
```

##### LD (Lie Derivative)

```wolfram
LD[ξ, w0] // FtoC
(* 𝓛_ξ w0 → ∇_a w0 ξ^a *)

LD[ξ, w1] // FtoC
(* 𝓛_ξ w1 → 𝓛_ξ w1_a *)

LD[ξ, ω[ua]] // FtoC
(* 𝓛_ξ ω^a → 𝓛_ξ ω_bc^a *)

LD[ξ, w1 ∧ w2] // FtoC
(* 라이프니츠 규칙 적용 후 텐서 성분 표현 *)
```

##### HodgeStar

```wolfram
SetDimension[3]; SetSig[0];

HodgeStar[XD[x]] // FtoC
(* *dx → ∇_c x ε^c_ab *)

HodgeStar[w1] // FtoC
(* *w1 → ε^c_ab w1_c *)

HodgeStar[ω[ua]] // FtoC
(* *ω^a → 1/2 ε^cd_b ω_cd^a *)

HodgeStar[XP[XD[x], XD[y]]] // FtoC
(* *dx∧dy → -1/2 ∇_b y ∇_c x ε^bc_a + 1/2 ∇_b x ∇_c y ε^bc_a *)
```

##### CoXD (Codifferential)

```wolfram
SetDimension[3]; SetSig[0];

CoXD[w1] // FtoC
(* δw1 → -∇^a w1_a *)

CoXD[w2] // FtoC
(* δw2 → -∇^b w2_ba *)

CoXD[w3] // FtoC
(* δw3 → -∇^c w3_cab *)

(* CoXDRule을 통한 검증 *)
CoXD[w1] /. CoXDRule[]
(* -*d*w1 *)

-HodgeStar[XD[HodgeStar[w1]]] // FtoC
(* EpsilonProductRule, Absorbg 적용 후 -∇^a w1_a *)
```

#### 참고 (See Also)

`CoordRep`, `CollectForm`, `ApplyXD`, `XD`, `XP`, `IP`, `LD`, `HodgeStar`, `CoXD`

---

### CoordRep (Coordinate Representation)

#### 함수 시그니처

```wolfram
CoordRep[form, coSys]
CoordRep[form, n]
```

#### 설명 (Details)

미분 형식의 좌표 표현(coordinate representation)을 제공한다.

- `CoordRep[form, coSys]`는 좌표계 `coSys`를 사용하여 미분 형식을 좌표 기저 $dx^i$로 표현한다.
- `CoordRep[form, n]`은 일반적인 $n$차원 공간에서의 표현을 제공한다. 차원은 `DefaultKind`의 Latin Kind를 기본으로 사용한다.
- 내부적으로 `FtoC`, `SumDum`, `TindexSort`, `CollectForm`을 조합하여 사용한다.

#### 예제 (Examples)

```wolfram
Tdefine[v, 1]; Tdefine[ξ[ua]]
Fdefine[w1, 1]; Fdefine[w2, 2]; Fdefine[x[ua], 0]

(* IP[ξ, XD[w1]]의 좌표 표현 *)
CoordRep[IP[ξ, XD[w1]], 3]
(* dx^3 (...) + dx^2 (...) + dx^1 (...) *)

(* XP[w1, w2]의 좌표 표현 *)
CoordRep[XP[w1, w2], 3]
(* (w1_1 w2_23 - w1_2 w2_13 + w1_3 w2_12) dx^1∧dx^2∧dx^3 *)

(* Indexed form *)
SetDimension[3]
Fdefine[ω[ua], 2]

ω[ua] // FtoC
(* ω_bc^a *)

CoordRep[ω[ua]]
(* dx^2∧dx^3 ω_23^a + dx^1∧dx^3 ω_13^a + dx^1∧dx^2 ω_12^a *)
```

#### 참고 (See Also)

`FtoC`, `CollectForm`, `SumDum`, `TindexSort`, `SetCoordinates`
