# Tech Note: 미분 형식 워크플로 (Differential Forms Workflow)

DiffForm 모듈을 사용하여 미분 형식을 정의하고, 외대수(exterior calculus) 연산을 수행하며, 텐서 성분 표현 및 좌표 표현으로 변환하는 워크플로를 다룬다.

> 자세한 함수 설명은 `01-DefiningForms.md`, `02-FormOperators.md`, `03-HodgeAndCodifferential.md`, `04-FormOperations.md` 참고.

---

## 1. 개요 -- DiffForm 모듈의 구성

DiffForm 모듈은 미분기하학의 외대수(exterior calculus)를 기호적으로 다루기 위한 도구 모음이다.

| 범주 | 함수/연산자 | 역할 |
|------|-----------|------|
| 정의 | DefForm/Fdefine, UndefForm | 미분 형식 정의/제거 |
| 질의 | DiffFormQ, DegreeForm, ZeroDegreeQ | 미분 형식 여부, 차수 확인 |
| 외대수 연산 | XP (∧), IP (ι), XD (d), LD (𝓛) | 외적, 내부 곱, 외미분, 리 도함수 |
| Hodge/코미분 | HodgeStar (*), CoXD (δ) | Hodge 쌍대, 코미분 |
| 변환 규칙 | LDtoXDRule, CoXDRule | 카르탕 공식, 코미분 전개 |
| 텐서 변환 | FtoC | 미분 형식 → 반대칭 텐서 성분 |
| 좌표 변환 | ApplyXD, CoordRep, CollectForm | 좌표 기저 전개, 좌표 표현 |

핵심 워크플로: **Fdefine**으로 미분 형식을 정의 → **XP, XD, IP** 등으로 외대수 연산 → **FtoC**로 텐서 성분 표현 변환 (또는 **CoordRep**으로 좌표 표현).

---

## 2. 미분 형식 정의 워크플로

### 스칼라 (0-form)

```wolfram
<< mGRG`STensor`

(* 0-form 정의 *)
Fdefine[f, 0]

(* 0-form은 인덱스 없이 사용 *)
{f, f[], f[la]}
(* {f, f, f[la]} — f[la]는 잘못된 인덱스 수 *)
```

### 보통의 p-form

```wolfram
(* 1-form, 2-form, 3-form *)
Fdefine[α, 1]
Fdefine[β, 2]
Fdefine[γ, 3]

(* 차수 확인 *)
DegreeForm /@ {α, β, γ}
(* {1, 2, 3} *)
```

### 텐서-값(tensor-valued) p-form (Indexed DiffForm)

인덱스를 가진 미분 형식을 정의할 때는 대칭 문자열이 필요하다.

```wolfram
(* 랭크 2, 반대칭, 차수 1인 미분 형식 *)
Fdefine[A[la, lb], 1, "-ba"]

(* 랭크 2, 위 첨자, 차수 2인 미분 형식 *)
Fdefine[Ω[ua, ub], 2, "-ba"]

(* PrintAs 옵션으로 출력 문자열 설정 *)
Fdefine[A[la, lb, lc], 1, "3+", PrintAs -> "α"]
```

### cross-Kind 인덱스

```wolfram
(* Greek Kind의 인덱스를 가진 미분 형식 *)
Fdefine[A[lμ, lν], 1, "-ba"]
{A[lν, lμ], A[la, lν, lμ]}  (* DefauldKind는 Latin *)
```

---

## 3. 외대수 연산

### 외적 (Wedge Product, XP)

```wolfram
Fdefine[f, 0]; Fdefine[α, 1]; Fdefine[β, 2]; Fdefine[γ, 3]

(* ∧ 기호로 입력 *)
{f ∧ α, α ∧ β, α ∧ α, β ∧ β}
(* {f α, α∧β, 0, β∧β} *)

(* 차원에 의한 자동 소멸 *)
SetDimension[2]
α ∧ β
(* 0 — 차수 3 > 차원 2 *)
ClearDimension[]
```

### 외미분 (Exterior Derivative, XD)

```wolfram
(* 선형성과 라이프니츠 규칙 *)
{XD[f], XD[-α], XD[a β]}
(* {df, -dα, a dβ + da∧β} *)
```

### 내부 곱 (Interior Product, IP)

```wolfram
Tdefine[v, 1]

(* ι_v ι_v ω = 0 *)
{IP[v, IP[v, α]], IP[v, IP[v, β]]}
(* {ι_v ι_v α, 0} *)

(* 라이프니츠 규칙 *)
IP[v, #] & /@ {f ∧ f, f ∧ α, β ∧ α}
(* {ι_v f², f ι_v α, β ι_v α - α∧ι_v β} *)
```

### 리 도함수 (Lie Derivative, LD)

```wolfram
(* 미분 형식에 대한 LD *)
{LD[v, α[la]], LD[v, α[ua]]}
(* {𝓛_v α_a, 𝓛_v α^a} *)

(* 카르탕 공식으로 변환 *)
LD[v, α]
% /. LDtoXDRule[]
(* 𝓛_v α → ι_v dα + d ι_v α *)
```

---

## 4. FtoC를 이용한 텐서 성분 변환

`FtoC`는 미분 형식 표현을 반대칭 텐서 인덱스 표현으로 변환하는 핵심 함수이다.

### 기본 사용법

```wolfram
Tdefine[f[]]; Tdefine[T[la, lb]]
Fdefine[w0, 0]; Fdefine[w1, 1]; Fdefine[w2, 2]

(* p-form → 반대칭 텐서 *)
w1 // FtoC
(* w1_a *)

w2 // FtoC
(* w2_ab *)

(* 곱이 포함된 경우 *)
T[la, lb] w1 // FtoC
(* T_ab w1_c *)
```

### XD의 텐서 표현

torsion-free 조건에 따라 달라진다:

```wolfram
(* torsion-free: CD 사용 *)
XD[w1] // FtoC
(* ∇_a w1_b - ∇_b w1_a *)

(* torsion 있음: BD 사용 *)
TorsionFreeQ[CD] = False;
XD[w1] // FtoC
(* ∂_a w1_b - ∂_b w1_a *)
TorsionFreeQ[CD] = True;  (* 기본 설정 *)
```

### XP의 텐서 표현

```wolfram
XP[w1, w2] // FtoC
(* w1_c w2_ab - w1_b w2_ac + w1_a w2_bc *)

(* 좌표 기저에서 *)
XP[XD[x], XD[y]] // FtoC
(* -∇_a y ∇_b x + ∇_a x ∇_b y *)
```

### LD, IP의 텐서 표현

```wolfram
Tdefine[ξ[ua]]

(* LD *)
LD[ξ, w0] // FtoC
(* ∇_a w0 ξ^a *)

LD[ξ, w1] // FtoC
(* 𝓛_ξ w1_a *)

(* IP *)
IP[ξ, w1] // FtoC
(* w1_a ξ^a *)

IP[ξ, XD[w1]] // FtoC
(* -∇_a w1_b ξ^b + ∇_b w1_a ξ^b *)
```

---

## 5. Hodge 쌍대와 코미분

### HodgeStar

차원과 부호 설정이 필요하다.

```wolfram
SetDimension[3]; SetSig[0];

(* 0-form의 Hodge 쌍대 *)
HodgeStar[x] // FtoC
(* *x → x ε_abc *)

(* 1-form의 Hodge 쌍대 *)
HodgeStar[w1] // FtoC
(* *w1 → ε^c_ab w1_c *)

(* 2-form의 Hodge 쌍대 *)
HodgeStar[w2] // FtoC
(* *w2 → 1/2 ε^bc_a w3_bc *)
```

### CoXD (코미분)

```wolfram
(* 0-form: δf = 0 *)
(* 1-form: δω_... = -∇^p ω_p... *)
CoXD[w1] // FtoC
(* -∇^a w1_a *)

CoXD[w2] // FtoC
(* -∇^b w2_ba *)

CoXD[w3] // FtoC
(* -∇^c w3_cab *)
```

### CoXDRule을 이용한 검증

```wolfram
(* CoXD = (-1)^{s+pn} * d * *)
CoXD[w1] /. CoXDRule[]
(* -*d*w1 *)

(* FtoC로 확인 *)
-HodgeStar[XD[HodgeStar[w1]]] // FtoC
% /. EpsilonProductRule[]
% // Absorbg
(* -∇^a w1_a  <-- 'CoXD[w1] // FtoC'와 동일*)

ClearDimension[]; ClearSig[];  (* 기본 설정 *)
```

---

## 6. 좌표 표현과 ApplyXD

### CoordRep

`CoordRep`은 미분 형식을 좌표 기저 $dx^i \wedge dx^j \wedge \ldots$로 전개한다.

```wolfram
Fdefine[w1, 1]; Fdefine[w2, 2]

(* 3차원 일반 표현 *)
CoordRep[XP[w1, w2], 3]
(* (w1_1 w2_23 - w1_2 w2_13 + w1_3 w2_12) dx^1∧dx^2∧dx^3 *)

(* Indexed form *)
SetDimension[3]
Fdefine[ω[ua], 2]
CoordRep[ω[ua]]
(* dx^2∧dx^3 ω_23^a + dx^1∧dx^3 ω_13^a + dx^1∧dx^2 ω_12^a *)
```

### ApplyXD

`ApplyXD`는 좌표가 설정된 상태에서 XD를 명시적으로 전개한다.

```wolfram
SetCoordinates[{t, r, θ, ϕ}]
SetAttributes[{m}, Constant]

expr = {(1 - 2 m/r)^(1/2) XD[t], (1 - 2 m/r)^(-1/2) XD[r],
        r XD[θ], r Sin[θ] XD[ϕ]} // ApplyXD
(* {√(1-2m/r) dt, dr/√(1-2m/r), r dθ, r Sin[θ] dϕ} *)

(* EvaluateBDFlag를 켜면 BD가 실제로 계산됨 *)
On[EvaluateBDFlag]
expr // ApplyXD
(* 미분이 실제로 수행된 결과 *)

Off[EvaluateBDFlag]  (* 기본 설정 *)
ClearCoordinates[]
```

---

## 7. 실전 예제: Laplace-deRham 연산자

Laplace-deRham 연산자 $\Delta = -(\delta d + d\delta)$를 구성하고, FtoC로 텐서 표현을 확인한다.

```wolfram
SetDimension[3]; SetSig[0];
Fdefine[w0, 0]; Fdefine[w1, 1]

(* Laplace-deRham 정의 *)
Δ[expr_] := -(CoXD[XD[expr]] + XD[CoXD[expr]])

(* 0-form에 적용 *)
Δ[w0]
% // FtoC
(* -δdw0 → ∇^a ∇_a w0 *)

(* 1-form에 적용 *)
Δ[w1]
% // FtoC
(* -δdw1 - dδw1 → ∇_a∇_b w1^b - ∇^b ∇_a w1_b + ∇^b ∇_b w1_a *)

ClearDimension[]; ClearSig[];
```

---

## 요약

1. **Fdefine/DefForm으로 p-form을 정의한다.** 인덱스가 있으면 대칭 문자열이 필요하다.
2. **XP(∧), XD(d), IP(ι), LD(𝓛)는 외대수의 기본 연산자이다.** 선형성과 라이프니츠 규칙을 자동 적용한다.
3. **HodgeStar(*)는 p-form을 (n-p)-form으로 변환한다.** 차원 n과 시그니처 s 설정이 필요하다.
4. **CoXD(δ)는 코미분 연산자이다.** CoXDRule로 $\delta = (-1)^{s+pn} * d *$로 전개된다.
5. **LDtoXDRule은 카르탕 공식 $\mathcal{L}_v = d \circ \iota_v + \iota_v \circ d$를 적용한다.**
6. **FtoC는 미분 형식을 반대칭 텐서 성분으로 변환하는 핵심 함수이다.** torsion-free 조건에 따라 CD 또는 BD를 사용한다.
7. **CoordRep과 ApplyXD는 좌표 기저 표현을 제공한다.**
