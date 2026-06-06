# DiffForm — 미분 형식 정의 (DiffFormQ, DefForm, Fdefine, UndefForm, SyntaxCheck)

`mGRG`STensor`` 패키지의 `DiffForm.m`에서 제공하는 미분 형식 정의 및 질의 함수들이다.

---

### DiffFormQ

#### 함수 시그니처

```wolfram
DiffFormQ[name]
```

#### 설명 (Details)

인자로 주어진 이름이 `DefForm` (또는 `Fdefine`)으로 정의된 미분 형식인지를 판단하는 질의함수이다. 정의된 미분 형식이면 `True`, 아니면 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
Fdefine[f, 1]
DiffFormQ /@ {f, A}
(* {True, False} *)

UndefForm[f]
DiffFormQ[f]
(* False *)
```

#### 참고 (See Also)

`DefForm`, `Fdefine`, `UndefForm`

---

### DefForm

#### 함수 시그니처

```wolfram
DefForm[f, p, opts]
DefForm[f[indices...], p, sym, opts]
```

#### 설명 (Details)

새로운 `IndexedObject`인 미분 형식(Differential Form)을 정의한다.

- 첫 번째 형태 `DefForm[f, p]`는 p-form `f`를 정의한다. 인덱스가 없는 보통의 미분 형식이 된다.
- 두 번째 형태 `DefForm[f[indices...], p, sym]`는 인덱스를 가진 텐서-값 p-form을 정의한다. `sym`은 대칭 문자열이다.
- `p`는 미분 형식의 차수(degree)이다. 0이면 스칼라(0-form), 1이면 1-form, 2이면 2-form 등이다.
- 인덱스 랭크가 0이고 차수가 0이 아닌 미분 형식을 정의할 때는 대칭 문자열이 필요 없다.
- 인덱스 랭크가 0이 아닌 미분 형식을 정의하려면 대칭 문자열을 입력해야 한다.
- 옵션으로 `PrintAs -> "str"`을 사용하여 출력 문자열을 설정할 수 있다. 출력 문자열이 없으면 미분 형식의 이름이 출력 문자열로 사용된다.
- 잘못된 인덱스 개수의 확인은 **출력될 때** 자동적으로 진행된다. 오류 메시지를 출력하려면 `SyntaxCheck` 함수를 사용한다.

#### 예제 (Examples)

```wolfram
(* 0-form (스칼라) *)
Fdefine[α, 1]
{α, α[], α[la], α[la, lb]}
(* {α, α, α_a, α[la,lb]} — 네 번째는 인덱스 수가 잘못되어 빨간색으로 출력 *)

(* 랭크 2, 차수 1인 미분 형식 *)
Fdefine[α[la, lb], 1]
{α, α[la], α[la, lb], α[lμ, la, lb], α[la, lb, lc, ld]}
(* {α, α[la], α_ab, α_μab, α[la,lb,lc,ld]} *)

(* 랭크 3, 완전 대칭, 차수 1 *)
Fdefine[A[la, lb, lc], 1, "3+", PrintAs -> "α"]
{A, A[], A[la], A[la, lb], α_bac, α_dabc}

(* 랭크 2, 완전 반대칭, 차수 1 *)
Fdefine[A[la, lb], 1, "2-", PrintAs -> "α"]
{A[lb, la], A[lc, lb, la]}
(* {α_ba, α_cba} *)

(* 랭크 2, 위 첨자, 차수 1 *)
Fdefine[A[ua, ub], 1, PrintAs -> "α"]
{A[ua, ub], A[lc, ua, ub]}
(* {α^ab, α_c^ab} *)

(* Greek-Kind 인덱스 *)
Fdefine[A[lμ, lν], 1, "-ba"]
{A[lν, lμ], A[lα, lν, lμ]}
(* {A_νμ, A_ανμ} *)
```

#### 참고 (See Also)

`Fdefine`, `UndefForm`, `DiffFormQ`, `SyntaxCheck`

---

### Fdefine

#### 함수 시그니처

```wolfram
Fdefine[f, p, opts]
Fdefine[f[indices...], p, sym, opts]
```

#### 설명 (Details)

`DefForm`의 별칭(alias)이다. `DefForm`과 완전히 동일하게 동작한다.

#### 참고 (See Also)

`DefForm`, `UndefForm`, `DiffFormQ`

---

### UndefForm

#### 함수 시그니처

```wolfram
UndefForm[name]
```

#### 설명 (Details)

`DefForm` (또는 `Fdefine`)으로 정의된 미분 형식을 제거한다. 제거 후 `DiffFormQ`는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
Fdefine[A[la, lb], 1]
DiffFormQ[A]
(* True *)

UndefForm[A]
DiffFormQ[A]
(* False *)
```

#### 참고 (See Also)

`DefForm`, `Fdefine`, `DiffFormQ`

---

### SyntaxCheck

#### 함수 시그니처

```wolfram
SyntaxCheck[expr]
```

#### 설명 (Details)

미분 형식의 인덱스 개수가 올바른지 확인하고, 잘못된 경우 오류 메시지를 출력한다. 잘못된 인덱스 개수의 확인은 출력 시 자동으로 진행되지만, 오류 메시지는 프로그램 구조 때문에 출력되지 않는다. 오류 메시지를 명시적으로 확인하려면 `SyntaxCheck`를 사용한다.

- 심볼 형태의 입력 (`IndexedObject`가 아닌)에 대해서는 `SyntaxCheck`가 반응하지 않는다.
- `IndexedObject` 형태의 입력에 대해서만 인덱스 수를 검사한다.

#### 예제 (Examples)

```wolfram
Fdefine[f, 0]
{f, f[], f[la]}  (* 첫 번째는 심볼 형태의 입력이다. *)
(* {f, f, f[la]} *)

f[la] // SyntaxCheck
(* Msg: invalid number of indices for f: (la) *)

Fdefine[A, 1]
{A, A[la], A[la, lb], A[la, lb, lc]}
(* {A, A_a, A[la,lb], A_abc} *)

A[la, lb] // SyntaxCheck
(* Msg: invalid number of indices for A: (la, lb) *)

(* 심볼 형태 — SyntaxCheck 무반응 *)
A // SyntaxCheck
(* A *)

A[] // SyntaxCheck
(* Msg: invalid number of indices for A *)
```

#### 참고 (See Also)

`DefForm`, `Fdefine`, `DiffFormQ`
