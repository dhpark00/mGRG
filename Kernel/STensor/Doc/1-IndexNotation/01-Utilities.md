# IndexNotation — 유틸리티 함수 (Utilities)

`mGRG`STensor`` 패키지의 `IndexNotation.m`에서 제공하는 범용 유틸리티 함수들이다.

---
## 함수
### AllQoptions

#### 함수 시그니처

```wolfram
AllQoptions[qHead][name, optL]
```

#### 설명 (Details)

`name`이 옵션 리스트 `optL`의 모든 조건을 만족하는지 검사한다. `qHead`는 `HeadQs` 또는 `IndexQs`를 사용한다.

- `HeadQs`는 표현식의 Head를 지정하는 옵션이다.
- `IndexQs`는 대상 인덱스를 지정하는 옵션이다.

`optL` 안에서 `qHead` 키에 대응하는 값은 판별 함수들의 리스트이며, 모든 판별 함수가 `True`를 반환해야 전체 결과가 `True`가 된다.

#### 예제 (Examples)

```wolfram
AllQoptions[HeadQs][RicciCD, {HeadQs -> {IndexedTensorQ}}]
(* True *)

AllQoptions[IndexQs][la, {IndexQs -> {DnIndexQ}}]
(* True *)
```

#### 참고 (See Also)

`HeadQs::usage`: "An option for specifying heads of expressions to which a function should be applied."
`IndexQs::usage`: "An option for specifying which indices to target in an operation."

---

### ConstantQ

#### 함수 시그니처

```wolfram
ConstantQ[x]
```

#### 설명 (Details)

`x`가 숫자, 수치 심볼, 또는 `Constant` 속성을 가진 심볼이면 `True`를 반환한다.

- 정수, 유리수, 실수, 복소수는 모두 `True`를 반환한다.
- `NumericQ`가 `True`인 심볼도 `True`를 반환한다.
- `Constant` 속성을 가진 심볼도 `True`를 반환한다.

#### 예제 (Examples)

```wolfram
ConstantQ /@ {1, 2/3, 3.14, 2 + 3I}
(* {True, True, True, True} *)

SetAttributes[c, Constant]
ConstantQ[c]
(* True *)
```

#### 참고 (See Also)

`NumericQ`

---

### FreePatternQ

#### 함수 시그니처

```wolfram
FreePatternQ[expr]
```

#### 설명 (Details)

`expr`에 패턴 객체가 없으면 `True`를 반환한다.

검사 대상에는 `Slot`, `Pattern`, `PatternSequence`, `Blank`, `BlankSequence`, `BlankNullSequence`, `Condition`, `PatternTest`, `Repeated`, `RepeatedNull` 등이 포함된다.

#### 예제 (Examples)

```wolfram
FreePatternQ /@ {a, a : True, PatternSequence[a, b_, c], _, __, ___}
(* {True, False, False, False, False, False} *)
```

---

### PositiveIntegerQ

#### 함수 시그니처

```wolfram
PositiveIntegerQ[n]
```

#### 설명 (Details)

`n`이 양의 정수이면 `True`를 반환한다. 0, 음의 정수, 실수, 심볼은 모두 `False`이다.

#### 예제 (Examples)

```wolfram
PositiveIntegerQ /@ {1, 0, -1, 3.14, some}
(* {True, False, False, False, False} *)
```

---

### SignOfTerm

#### 함수 시그니처

```wolfram
SignOfTerm[expr]
```

#### 설명 (Details)

심볼릭 항이 음의 부호(예: `-x`)를 가지면 `-1`을, 아니면 `1`을 반환한다.

> **주의:** `SignOfTerm[-1]`은 `1`이다. `-1`은 음의 부호를 가진 심볼릭 항이 아니라 숫자이기 때문이다.

#### 예제 (Examples)

```wolfram
SignOfTerm /@ {-a, b, -1, 1}
(* {-1, 1, 1, 1} *)
```

---

### SymbolJoin

#### 함수 시그니처

```wolfram
SymbolJoin[s1, s2, ...]
SymbolJoin[{s1, s2, ...}]
```

#### 설명 (Details)

심볼이나 문자열들을 하나의 심볼로 결합한다.

- 리스트 입력도 가능하다: `SymbolJoin[{s1, s2}]`.
- 결과의 Head는 항상 `Symbol`이다.

#### 예제 (Examples)

```wolfram
SymbolJoin[{a, b, c}]
(* abc *)

SymbolJoin[a, b, c]
(* abc *)

SymbolJoin[a, "b", c]
(* abc *)

% // Head
(* Symbol *)
```

---

## 옵션 키 (Option Keys)

| 옵션        | 설명                                                   |
| --------- | ---------------------------------------------------- |
| `HeadQs`  | 함수가 적용될 표현식의 Head를 지정하는 옵션. 기본값은 `{IndexedObjectQ}`. |
| `IndexQs` | 대상 인덱스를 지정하는 옵션.                                     |
| `CovDs`   | 적용할 공변 도함수를 지정하는 옵션.                                 |

---

## 메시지 (Messages)

| 메시지 | 형식 |
|--------|------|
| `Msg::err` | `` "`1` `2` `3` `4`" `` — 에러 메시지 (4개 슬롯) |
| `Msg::warn` | `` "`1` `2` `3` `4`" `` — 경고 메시지 (4개 슬롯) |
| `Msg::note` | `` "`1` `2` `3` `4` `5`" `` — 알림 메시지 (5개 슬롯) |
