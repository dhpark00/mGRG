# IndexNotation — 표현식 유틸리티 (Expression Utilities)

인덱스 객체를 포함하는 표현식을 분석하고 조작하기 위한 유틸리티 함수들이다.

---

### ExpandObject

#### 함수 시그니처

```wolfram
ExpandObject[expr]
ExpandObject[expr, HeadQs -> {headQ1, ...}]
```

#### 설명 (Details)

인덱스 객체를 포함하는 표현식을 전개한다. 곱(Times)을 합(Plus)으로 분배하되, 인덱스 객체의 구조를 보존하면서 전개한다.

- `Listable` 속성을 가지므로 리스트에 자동으로 매핑된다.
- 옵션 `HeadQs`를 사용하여 전개 대상을 제한할 수 있다. 기본값은 `{IndexedObjectQ}`이다.
- `HeadQs -> {IndexedOperatorQ}`로 설정하면 연산자(`CD` 등)가 포함된 표현만 전개한다.

#### 예제 (Examples)

```wolfram
expr = (a + b) (CD[lc, R[la, lb]] + CD[lc, F[la, lb]]) (R[ua, ub] + F[ua, ub]) scalarR[]

ExpandObject[expr]
(* (a+b) scalarR[] CD[lc, F[la,lb]] F[ua,ub]
 + (a+b) scalarR[] CD[lc, R[la,lb]] F[ua,ub]
 + (a+b) scalarR[] CD[lc, F[la,lb]] R[ua,ub]
 + (a+b) scalarR[] CD[lc, R[la,lb]] R[ua,ub] *)

ExpandObject[expr, HeadQs -> {IndexedOperatorQ}]
(* 연산자(CD)를 갖는 부분만 전개하고, 나머지 인덱스 객체의 합은 전개하지 않는다. *)
```

#### 참고 (See Also)

`FreeObjectQ`, `ForEachTerm`, `HeadQs`, `IndexedObjectQ`, `IndexedOperatorQ`

---

### FreeObjectQ

#### 함수 시그니처

```wolfram
FreeObjectQ[expr]
FreeObjectQ[expr, HeadQs -> {headQ1, ...}]
```

#### 설명 (Details)

`expr`에 인덱스 객체가 없으면 `True`를 반환한다.

- `Listable` 속성을 가지므로 리스트에 자동으로 매핑된다.
- 옵션 `HeadQs`의 기본값은 `{IndexedObjectQ}`이다. `IndexedObjectQ`를 만족하는 Head가 하나도 없으면 `True`를 반환한다.
- `HeadQs -> {ObjectQ}`로 설정하면 `ScalarFunction`도 인덱스 객체로 간주한다.
- `Tscalar` 와 같은 `ScalarFunction`은 기본적으로 인덱스 객체로 취급되지 않으므로 `FreeObjectQ`가 `True`를 반환한다.

#### 예제 (Examples)

```wolfram
expr = {scalarR[] R[la, lb] + a F[la, lb], a b}

FreeObjectQ /@ expr
(* {False, True} *)

(* Tscalar는 ScalarFunction이므로 기본 옵션에서는 인덱스 객체가 아니다 *)
FreeObjectQ[Tscalar[a R[la, lb] R[ua, ub]]]
(* True *)

(* HeadQs -> {ObjectQ}로 설정하면 ScalarFunction도 인덱스 객체로 간주한다 *)
FreeObjectQ[Tscalar[a R[la, lb] R[ua, ub]], HeadQs -> {ObjectQ}]
(* False *)
```

#### 참고 (See Also)

`ExpandObject`, `NoIndexQ`, `HeadQs`, `IndexedObjectQ`, `ObjectQ`

---

### ForEachTerm

#### 함수 시그니처

```wolfram
ForEachTerm[expr, f, args...]
```

#### 설명 (Details)

합(`Plus`)이나 등식(`Equal`)의 각 항에 함수 `f`를 적용한다.

- `expr`이 `Plus` 또는 `Equal`이면, 각 항에 대해 재귀적으로 `ForEachTerm`을 적용한다.
- `expr`이 단일 항이면 `f[expr, args...]`를 반환한다.
- 내부적으로 `Dum`, `DumFresh`, `ResetDummies`, `Symmetrize` 등 많은 함수에서 항별 처리를 위해 사용된다.

#### 예제 (Examples)

```wolfram
ForEachTerm[c == a d + b e, func, arg1, arg2]
(* func[c, arg1, arg2] == func[a d, arg1, arg2] + func[b e, arg1, arg2] *)

ForEachTerm[x + y + z, f]
(* f[x] + f[y] + f[z] *)

ForEachTerm[x y, f]
(* f[x y] *)
```

#### 참고 (See Also)

`ForEachObject`, `ExpandObject`

---

### ForEachObject

#### 함수 시그니처

```wolfram
ForEachObject[expr, hOptL, f, args...]
```

#### 설명 (Details)

표현식의 각 인덱스 객체에 함수 `f`를 적용한다. `hOptL`은 `HeadQs` 옵션 리스트이다.

- `expr`이 `Plus` 또는 `Equal`이면 각 항에 대해 재귀적으로 적용한다.
- `expr`이 `Times`이면 각 인자(factor)에 대해 재귀적으로 적용한다.
- `expr`이 `hOptL`의 `HeadQs` 조건을 만족하는 인덱스 객체이면 `f[expr, args...]`를 적용한다.
- 위 조건 중 어느 것도 해당하지 않으면 `expr`을 그대로 반환한다 (스칼라 계수 등).
- 기본 `HeadQs` 값은 `{IndexedObjectQ}`이다.

#### 예제 (Examples)

```wolfram
ForEachObject[f[] == v[la] v[ua] + a R[lb, ub], {}, func, arg1, arg2]
(* func[f[], arg1, arg2] == a func[R[lb, ub], arg1, arg2]
   + func[v[la], arg1, arg2] func[v[ua], arg1, arg2] *)

(* 스칼라 계수 a는 인덱스 객체가 아니므로 f가 적용되지 않는다. *)
```

#### 참고 (See Also)

`ForEachTerm`, `SplitTerm`, `HeadQs`, `AllQoptions`

---

### SplitTerm

#### 함수 시그니처

```wolfram
SplitTerm[term]
SplitTerm[term, hOptL]
```

#### 설명 (Details)

항을 `{scalarPart, tensorPart}`로 분리한다. `Apply[Times, {scalarPart, tensorPart}]`는 원래의 항과 동일하다.

- 두 번째 인자 `hOptL`은 `HeadQs` 옵션 리스트이다. 기본값은 `{}`이며, 이 경우 `HeadQs`의 기본 옵션인 `{IndexedObjectQ}`가 적용된다.
- `Times` 표현식의 경우, 각 인자에 대해 재귀적으로 `SplitTerm`을 적용한 후 결과를 곱한다.
- 인덱스 객체(Head가 `HeadQs` 조건을 만족)는 `{1, term}`을 반환한다. 그렇지 않으면 `{term, 1}`을 반환한다.
- `HeadQs -> {IndexedOperatorQ}`로 설정하면 연산자만 텐서 부분으로 분리할 수 있다.
- `HeadQs -> {ObjectQ}`로 설정하면 `ScalarFunction`도 텐서 부분에 포함된다.

#### 예제 (Examples)

```wolfram
SplitTerm[a R[la, lb]]
(* {a, R[la, lb]} *)

SplitTerm[a R[la, lb] CD[lc, scalarR[]]]
(* {a, R[la, lb] CD[lc, scalarR[]]} *)

(* 연산자와 나머지를 분리 *)
SplitTerm[a R[la, lb] CD[lc, scalarR[]], {HeadQs -> {IndexedOperatorQ}}]
(* {a R[la, lb], CD[lc, scalarR[]]} *)

(* ScalarFunction도 텐서 부분에 포함 *)
SplitTerm[a Tscalar[R[la, lb] R[ua, ub]], {HeadQs -> {ObjectQ}}]
(* {a, Tscalar[R[la, lb] R[ua, ub]]} *)
```

#### 참고 (See Also)

`ForEachObject`, `FreeObjectQ`, `HeadQs`, `IndexedObjectQ`, `IndexedOperatorQ`

---

### NoIndexQ

#### 함수 시그니처

```wolfram
NoIndexQ[expr]
NoIndexQ[expr, HeadQs -> {headQ1, ...}]
```

#### 설명 (Details)

`expr`이 스칼라이거나 자유 텐서 인덱스(free tensorial index)가 없으면 `True`를 반환한다.

- 인덱스가 없는 스칼라 텐서 `f[]`는 `True`를 반환한다.
- 완전히 수축된 텐서 곱(fully contracted tensor product)도 자유 인덱스가 없으므로 `True`를 반환한다.
- `ScalarFunction`(예: `Tscalar`, `Log`)은 항상 `True`를 반환한다.
- 인덱스 객체가 없는 표현식(`FreeObjectQ`가 `True`)도 `True`를 반환한다.
- 텐서의 Kind에 맞지 않는 인덱스는 유효하지 않은(invalid) 인덱스로 간주되어 무시된다.

#### 예제 (Examples)

```wolfram
NoIndexQ /@ {scalarR[], R[la, lb] R[ua, ub]}
(* {True, True} *)

(* ScalarFunction은 항상 True *)
NoIndexQ /@ {Tscalar[R[la, lb]], Log[R[la, ub]]}
(* {True, True} *)

(* 자유 인덱스가 있으면 False *)
NoIndexQ[R[la, lb]]
(* False *)

(* R이 Latin Kind로 정의된 경우, Greek 인덱스는 유효하지 않으므로 무시된다 *)
NoIndexQ /@ {R[lα, lβ], R[lA, lB]}
(* {True, True} *)
```

#### 참고 (See Also)

`FreeObjectQ`, `FindFreeTensorialIndices`, `ScalarFunctionQ`
