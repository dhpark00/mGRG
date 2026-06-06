# DiffForm — 미분 형식 연산자 (XP, IP, XD, LD, LDtoXDRule)

`mGRG`STensor`` 패키지의 `DiffForm.m`에서 제공하는 미분 형식의 기본 연산자들이다.

---

### XP (Exterior Product)

#### 함수 시그니처

```wolfram
XP[form1, form2]
form1 ∧ form2
```

#### 설명 (Details)

XP type의 exterior product(외적, 웨지 곱) 연산자이다. `∧` (Wedge) 기호로도 입력할 수 있다.

- 0-form은 자동으로 XP에서 제거되고, 순서도 자동적으로 조정된다.
- `DefaultKind`의 공간 차원이 고려된다: 차원 $n$에서 $(p+q)$-form의 차수가 $n$을 초과하면 0이 된다.
- Indexed DiffForm에 대해서도 동작한다.
- Indexed form에 대한 자동적인 단순화는 이루어지지 않는다.
- 결합 법칙(associativity)은 기본적으로 적용되지 않는다. `FtoC` 함수의 구현을 위해 규칙 `XP[pre, XP[args], post] := XP[pre, args, post]`은 자동적으로 적용되지 않으므로, 별도의 규칙 `XPflattenRules`를 내부적으로 정의하였다.

#### 예제 (Examples)

```wolfram
Fdefine[f, 0]; Fdefine[α, 1]; Fdefine[β, 2]; Fdefine[γ, 3]

(* 기본 사용 *)
{XP[f, f], XP[f, α], XP[β, α], XP[α, α], XP[β, β]}
(* {f², f α, α∧β, 0, β∧β} *)

(* Wedge 기호 입력 *)
{f ∧ f, f ∧ α, β ∧ α, α ∧ α, β ∧ β}
(* {f², f α, α∧β, 0, β∧β} *)

(* 차원 설정 시 *)
SetDimension[2]
{α ∧ f, α ∧ β}
(* {f α, 0} — 차수 3 > 차원 2이므로 0 *)
ClearDimension[]

(* Indexed DiffForm *)
Fdefine[f[la], 0]; Fdefine[α[la], 1]; Fdefine[β[la], 2]
{f[la] ∧ α[lb], β[la] ∧ α[lb], α[lb] ∧ α[la], β[la] ∧ β[lb]}
(* {f_a α_b, α_b∧β_a, -α_a∧α_b, β_a∧β_b} *)
```

#### 참고 (See Also)

`IP`, `XD`, `FtoC`, `DefForm`

---

### IP (Interior Product)

#### 함수 시그니처

```wolfram
IP[vector, form]
```

#### 설명 (Details)

LD type의 interior product(내부 곱, 또는 내부 도함수) 연산자이다. 벡터 `vector`와 미분 형식 `form`의 내부 곱을 계산한다. 결과는 차수가 1 낮은 미분 형식이다.

- $\iota_v \iota_v \omega = 0$: 같은 벡터로 두 번 내부 곱을 취하면 0이다.
- 0-form과 $p \geq 1$인 p-form의 곱인 경우, 0-form은 자동적으로 IP에서 제거된다.
- 선형 연산자이다: `IP[v, a XD[α] + b β] = b ι_v β + a ι_v dα`.
- 라이프니츠 규칙을 따른다: $\iota_v(\alpha \wedge \beta) = (\iota_v \alpha) \wedge \beta + (-1)^p \alpha \wedge (\iota_v \beta)$.

#### 예제 (Examples)

```wolfram
Tdefine[v, 1]
Fdefine[f, 0]; Fdefine[α, 1]; Fdefine[β, 2]; Fdefine[γ, 3]

(* 기본 사용 *)
IP[v, #] & /@ {f, α, β, γ}
(* {ι_v f, ι_v α, ι_v β, ι_v γ} *)

(* ι_v ι_v ω = 0 *)
{IP[v, IP[v, α]], IP[v, IP[v, β]], IP[v, IP[v, γ]]}
(* {ι_v ι_v α, 0, 0} *)

(* 0-form 자동 제거 *)
{IP[v, f], IP[v, f α]}
(* {ι_v f, f ι_v α} *)

(* 선형성 *)
IP[v, a XD[α] + b β]
(* b ι_v β + a ι_v dα *)

(* 라이프니츠 규칙 *)
IP[v, #] & /@ {f ∧ f, f ∧ α, β ∧ α, β ∧ β}
(* {ι_v f², f ι_v α, β ι_v α - α∧ι_v β, 2 ι_v β∧β} *)
```

#### 참고 (See Also)

`XP`, `XD`, `LD`, `LDtoXDRule`, `FtoC`

---

### XD (Exterior Derivative)

#### 함수 시그니처

```wolfram
XD[form]
```

#### 설명 (Details)

XD type의 exterior derivative(외미분) 연산자이다. 미분 형식의 외미분을 계산한다.

- 선형 미분 연산자이다: `XD[-α] = -dα`, `XD[a β] = a dβ + da∧β`.
- Indexed DiffForm에 대해서도 동작한다.
- 곱에 대한 라이프니츠 규칙: `XD[β[la] ∧ α[ua]] = dα^a ∧ β_a - α^a ∧ dβ_a`.
- `Power`, `Log` 같은 `ScalarFunction`의 XD도 처리한다: `XD[f²] = df²`, `XD[Log[f]] = dLog[f]`.
- `Tscalar`의 XD: `XD[Tscalar[f]] = df`.

#### 예제 (Examples)

```wolfram
Fdefine[f, 0]; Fdefine[α, 1]; Fdefine[β, 2]; Fdefine[γ, 3]

(* 기본 사용 *)
{XD[f], XD[-α], XD[a β]}
(* {df, -dα, a dβ + da∧β} *)

(* Indexed DiffForm *)
Fdefine[f[la], 0]; Fdefine[α[la], 1]; Fdefine[β[la], 2]
{XD[f[la]], XD[-α[la]], XD[a β[la]]}
(* {df_a, -dα_a, a dβ_a + da∧β_a} *)

(* 곱에 대한 XD *)
XD[β[la] ∧ α[ua]]
(* dα^a ∧ β_a - α^a ∧ dβ_a *)

(* ScalarFunction의 XD *)
Fdefine[f, 0]
XD[f^2]
(* df² *)

XD[Log[f]]
(* dLog[f] *)

XD[Tscalar[f]]
(* df *)
```

#### 참고 (See Also)

`XP`, `IP`, `CoXD`, `ApplyXD`, `FtoC`

---

### LD (Lie Derivative for Forms)

#### 함수 시그니처

```wolfram
LD[vector, form]
```

#### 설명 (Details)

텐서를 위한 LD 연산자는 미분 형식에 대해서도 동일하게 작용한다. 벡터 `vector`에 의한 미분 형식 `form`의 리 도함수를 계산한다.

- 선형 연산자이다.
- 곱에 대한 라이프니츠 규칙을 따른다: `LD[v, α ∧ β] = 𝓛_v α ∧ β + α ∧ 𝓛_v β`.
- `LDtoXDRule`을 사용하여 카르탕 공식 $\mathcal{L}_v \omega = d(\iota_v \omega) + \iota_v d\omega$로 변환할 수 있다.

#### 예제 (Examples)

```wolfram
Tdefine[v, 1]
Fdefine[f[la], 0]; Fdefine[α[la], 1]; Fdefine[β[la], 2]

(* 기본 사용 *)
{LD[v, f[la]], LD[v, α[ua]], LD[v, β[1]]}
(* {𝓛_v f_a, 𝓛_v α^a, 𝓛_v β^1} *)

(* 곱에 대한 라이프니츠 규칙 *)
{LD[v, α[la] ∧ β[lb]], LD[v, XD[α[la]]]}
(* {𝓛_v α_a ∧ β_b + α_a ∧ 𝓛_v β_b, 𝓛_v dα_a} *)

(* 선형성 *)
LD[v, c1 XD[α[la]] + c2 β[la]]
(* c1 𝓛_v dα_a + c2 𝓛_v β_a *)
```

#### 참고 (See Also)

`LDtoXDRule`, `XD`, `IP`, `FtoC`

---

### LDtoXDRule

#### 함수 시그니처

```wolfram
LDtoXDRule[]
```

#### 설명 (Details)

카르탕 공식(Cartan's magic formula)을 적용하는 변환 규칙을 제공한다. `/.` (ReplaceAll)로 적용하여 사용한다.

$$\mathcal{L}_v \omega = d(\iota_v \omega) + \iota_v d\omega$$

#### 예제 (Examples)

```wolfram
Tdefine[ξ[ua]]
Fdefine[ω[ua], 2]

LD[ξ, ω[ua]]
% /. LDtoXDRule[]
(* 𝓛_ξ ω^a → ι_ξ dω^a + d ι_ξ ω^a *)
```

#### 참고 (See Also)

`LD`, `XD`, `IP`, `FtoC`
