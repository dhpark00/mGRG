# DiffForm — Hodge 쌍대와 코미분 (HodgeStar, DegreeForm, ZeroDegreeQ, CoXD, CoXDRule)

`mGRG`STensor`` 패키지의 `DiffForm.m`에서 제공하는 Hodge 쌍대, 차수 질의, 코미분 관련 함수들이다.

---

### HodgeStar

#### 함수 시그니처

```wolfram
HodgeStar[pForm]
```

#### 설명 (Details)

p-form의 Hodge 쌍대(Hodge dual)를 계산한다. 결과는 $(n-p)$-form이다 ($n$은 다양체의 차원).

- 참고: R. M. Wald, Appendix B.2, Problem 4.2.a.
- $s$는 계량 텐서 $g_{ab}$의 부호(signature)에서 마이너스의 개수이다.
- 이중 쌍대 공식: $**\alpha = (-1)^{s+p(n+1)} \alpha$, $*^{-1} \equiv (-1)^{s+p(n+1)} *$.
- `DegreeForm`으로 차수를 확인할 수 있다.
- `FtoC`를 통해 텐서 성분 표현으로 변환할 수 있다.
- 차원이 설정되어 있어야 한다 (`SetDimension`). 설정되지 않으면 `$Failed`를 반환한다.

#### 예제 (Examples)

```wolfram
Tdefine[v, 1]
Fdefine[f, 0]; Fdefine[a, 1]; Fdefine[b, 2]
Fdefine[α[la], 1]; Fdefine[β[la], 1]
Fdefine[ω[ub], 2]
Fdefine[Ω[ua, ub], 2, "-ba"]

(* 기본 사용 *)
HodgeStar /@ {f, a, b}
(* {*f, *a, *b} *)

HodgeStar /@ {α[la], β[la], ω[ub], Ω[la, lb]}
(* {*α_a, *β_a, *ω^b, *Ω_ab} *)

(* 이중 쌍대 *)
GetDimension[DefaultKind] = n; GetSig[DefaultKind] = s;

HodgeStar /@ HodgeStar /@ {α[la], β[la], ω[ub], Ω[la, lb]}
(* {(-1)^(1+n+s) α_a, (-1)^(1+n+s) β_a, (-1)^(2(1+n)+s) ω^b, (-1)^(2(1+n)+s) Ω_ab} *)

(* FtoC로 텐서 성분 변환 *)
SetDimension[3]; SetSig[0];

HodgeStar[XD[x]]
% // FtoC
(* *dx → ∇_c x ε^c_ab *)

HodgeStar[w1]
% // FtoC
(* *w1 → ε^c_ab w1_c *)

HodgeStar[ω[ua]]
% // FtoC
(* *ω^a → 1/2 ε^cd_b ω_cd^a *)
```

#### 참고 (See Also)

`CoXD`, `CoXDRule`, `DegreeForm`, `ZeroDegreeQ`, `FtoC`, `Epsilon`

---

### DegreeForm

#### 함수 시그니처

```wolfram
DegreeForm[expr]
```

#### 설명 (Details)

미분 형식 표현식의 차수(degree)를 반환한다. 기본 미분 형식뿐 아니라 exterior product (`XP`), exterior derivative (`XD`), interior product (`IP`), Hodge dual (`HodgeStar`), codifferential (`CoXD`)의 차수도 계산한다.

#### 예제 (Examples)

```wolfram
Fdefine[ω[ua], 2]

{ω[ua], ω[lb, ua], ω[lb, lc, ua]}
DegreeForm /@ %
(* {2, 0, 0} *)

(* HodgeStar 연산 후의 차수 *)
DegreeForm /@ (HodgeStar /@ {α[la], β[la], ω[la], Ω[la, lb]})
(* {-1 + n, -1 + n, -2 + n, -2 + n} *)

(* CoXD 후 차수 *)
DegreeForm /@ (CoXD /@ {α[la], β[la], ω[la], Ω[la, lb]})
(* {0, 0, 1, 1} *)
```

#### 참고 (See Also)

`ZeroDegreeQ`, `HodgeStar`, `DefForm`

---

### ZeroDegreeQ

#### 함수 시그니처

```wolfram
ZeroDegreeQ[expr]
```

#### 설명 (Details)

표현식이 0-form(스칼라)인지 또는 미분 형식 표현식이 아닌지를 판단한다. `True`이면 0-form이거나 미분 형식이 아닌 것이고, `False`이면 0이 아닌 차수의 미분 형식이다.

#### 예제 (Examples)

```wolfram
(* HodgeStar 후 확인 *)
ZeroDegreeQ /@ (HodgeStar /@ {α[la], β[la], Ω[la, lb]})
(* {False, False, True} — 차원 2일 때 *)

(* 차원 설정 해제 시 *)
ClearDimension[]
ZeroDegreeQ /@ (HodgeStar /@ {α[la], β[la], ω[ua], Ω[la, lb]})
(* {False, False, False, False} — 차원 미정이면 모두 False *)

(* ω의 인덱스에 따른 차수 *)
{ω[ua], ω[lb, ua], ω[lb, lc, ua]}
DegreeForm /@ %
ZeroDegreeQ /@ %%
(* {2, 0, 0} *)
(* {False, True, True} *)
```

#### 참고 (See Also)

`DegreeForm`, `HodgeStar`, `DefForm`

---

### CoXD (Codifferential)

#### 함수 시그니처

```wolfram
CoXD[pForm]
```

#### 설명 (Details)

p-form에 작용하는 코미분(codifferential) 연산자이다. `CoXDRule`로 전개할 수 있다.

- 공식: $\delta\omega = (-1)^{s+pn} * d * \omega = (-1)^p *^{-1} d *\omega$, $\delta\delta = 0$.
- $s$는 계량 텐서 부호의 마이너스 개수이다.
- torsion-free CD에 대해: $(\delta\omega)_{a \ldots b} = -\nabla^p \omega_{pa \ldots b}$.
- `CoXD`를 두 번 적용하면 0이다.

#### 예제 (Examples)

```wolfram
Tdefine[v, 1]; Fdefine[f, 0]; Fdefine[A, 1]; Fdefine[B, 2]
Fdefine[α[la], 1]; Fdefine[β[la], 1]
Fdefine[ω[ua], 2]; Fdefine[Ω[ua, ub], 2, "-ba"]

GetDimension[DefaultKind] = n; GetSig[DefaultKind] = s;

(* 기본 사용 *)
CoXD /@ {f, A, B}
(* {0, δA, δB} *)

CoXD /@ {α[la], β[la], ω[la], Ω[la, lb]}
(* {δα_a, δβ_a, δω_a, δΩ_ab} *)

(* CoXDRule로 전개 *)
CoXD[ω[ua]]
% /. CoXDRule[]
(* δω^a → (-1)^(2n+s) *d*ω^a *)

(* CoXD ∘ CoXD = 0 *)
CoXD /@ CoXD /@ {f, A, B}
(* {0, 0, 0} *)

(* FtoC로 텐서 성분 표현 *)
SetDimension[3]; SetSig[0];

CoXD[w1] // FtoC
(* δw1 → -∇^a w1_a *)

CoXD[w2] // FtoC
(* δw2 → -∇^b w2_ba *)

CoXD[w3] // FtoC
(* δw3 → -∇^c w3_cab *)
```

#### 참고 (See Also)

`CoXDRule`, `XD`, `HodgeStar`, `FtoC`

---

### CoXDRule

#### 함수 시그니처

```wolfram
CoXDRule[]
```

#### 설명 (Details)

코미분(codifferential)을 Hodge 쌍대와 외미분의 조합으로 전개하는 변환 규칙을 제공한다. `/.` (ReplaceAll)로 적용하여 사용한다.

$$\delta\omega = (-1)^{s+pn} * d * \omega$$

#### 예제 (Examples)

```wolfram
GetDimension[DefaultKind] = n; GetSig[DefaultKind] = s;

CoXD[ω[ua]]
% /. CoXDRule[]
(* δω^a → (-1)^(2n+s) *d*ω^a *)

(* 0-form의 CoXD *)
SetDimension[3]; SetSig[0]
CoXD[XD[x]]
% /. CoXDRule[]
(* δdx → -*d*dx *)
```

#### 참고 (See Also)

`CoXD`, `HodgeStar`, `XD`, `FtoC`
