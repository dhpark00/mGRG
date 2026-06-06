# IndexNotation — 인덱스 객체 (Indexed Objects)

Object는 IndexedObject와 ScalarFunction으로 나뉜다. IndexedObject는 Operator와 Operand(Tensor, DiffForm 등)로 나뉜다. 함수의 옵션으로 `HeadQs`를 사용하여 특정 유형의 Object만 대상으로 할 수 있다.

```
ObjectQ |- IndexedObjectQ |- IndexedOperatorQ
        |                 |- IndexedOperandQ  |- IndexedTensorQ
        |                                     |- DiffFormQ
        |
        |- ScalarFunctionQ
```

---

## 객체 타입 판별

---

### ObjectQ

#### 함수 시그니처

```wolfram
ObjectQ[name]
```

#### 설명 (Details)

`name`이 정의된 인덱스 객체 또는 스칼라 함수이면 `True`를 반환한다.

- `IndexedObjectQ[name]` 또는 `ScalarFunctionQ[name]`이 `True`이면 `ObjectQ[name]`도 `True`이다.
- 정의되지 않은 심볼에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
DefTensor[T[la, lb], "ba"]
ObjectQ /@ {T, Sin, Power, hello}
(* {True, True, True, False} *)
```

#### 참고 (See Also)

`IndexedObjectQ`, `ScalarFunctionQ`, `IndexedOperandQ`, `IndexedOperatorQ`

---

### IndexedObjectQ

#### 함수 시그니처

```wolfram
IndexedObjectQ[name]
```

#### 설명 (Details)

`name`이 정의된 인덱스 객체(텐서, 미분 형식, 또는 연산자)이면 `True`를 반환한다.

- `IndexedOperandQ`(텐서, 미분 형식)와 `IndexedOperatorQ`(CD, LD 등)를 모두 포함한다.
- 스칼라 함수(`Sin`, `Cos` 등)에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
IndexedObjectQ /@ {Metricg, CD, Sin, hello}
(* {True, True, False, False} *)
```

#### 참고 (See Also)

`ObjectQ`, `IndexedOperandQ`, `IndexedOperatorQ`

---

### IndexedOperandQ

#### 함수 시그니처

```wolfram
IndexedOperandQ[name]
```

#### 설명 (Details)

`name`이 인덱스를 갖는 피연산자(텐서 또는 미분 형식)이면 `True`를 반환한다.

- `IndexedTensorQ`와 `DiffFormQ`를 모두 포함한다.
- 연산자(`CD`, `LD` 등)에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
DefTensor[T[la, lb], "ba"]
IndexedOperandQ /@ {T, Metricg, CD, Sin}
(* {True, True, False, False} *)
```

#### 참고 (See Also)

`IndexedTensorQ`, `DiffFormQ`, `IndexedObjectQ`

---

### IndexedTensorQ

#### 함수 시그니처

```wolfram
IndexedTensorQ[name]
```

#### 설명 (Details)

`name`이 정의된 인덱스 텐서이면 `True`를 반환한다.

- `DefTensor`(또는 별칭으로 `Tdefine`)로 정의된 텐서와 시스템 내장 텐서(`Metricg`, `Epsilon`, `Kdelta` 등)를 포함한다.
- 미분 형식(`DiffFormQ`)에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
DefTensor[T[la, lb], "ba"]
IndexedTensorQ /@ {T, Metricg, Kdelta, CD}
(* {True, True, True, False} *)
```

#### 참고 (See Also)

`IndexedOperandQ`, `DiffFormQ`, `DefTensor`

---

### DiffFormQ

#### 함수 시그니처

```wolfram
DiffFormQ[name]
```

#### 설명 (Details)

`name`이 정의된 미분 형식이면 `True`를 반환한다.

- `DefForm` (또는 별칭으로 `Fdefine`) 으로 정의된 미분 형식에 대해서만 `True`를 반환한다.
- 일반 텐서에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
DiffFormQ /@ {Metricg, CD, Sin}
(* {False, False, False} *)
```

#### 참고 (See Also)

`IndexedTensorQ`, `IndexedOperandQ`

---

### IndexedOperatorQ

#### 함수 시그니처

```wolfram
IndexedOperatorQ[name]
```

#### 설명 (Details)

`name`이 정의된 인덱스 연산자(CD, LD 등)이면 `True`를 반환한다.

- 연산자 타입: `CD`(공변 미분), `LD`(리 미분), `XD`(외미분), `XP`(외적) 등이 있다.
- 텐서나 스칼라 함수에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
IndexedOperatorQ /@ {CD, LD, Metricg, Sin}
(* {True, True, False, False} *)
```

#### 참고 (See Also)

`IndexedObjectQ`, `IndexedOperandQ`

---

### ScalarFunctionQ

#### 함수 시그니처

```wolfram
ScalarFunctionQ[name]
```

#### 설명 (Details)

`name`이 스칼라 함수이면 `True`를 반환한다.

- `NumericFunction` 속성을 가진 심볼(`Sin`, `Cos`, `Log`, `Power` 등)이 해당한다.
- `Tscalar`도 스칼라 함수로 취급된다.
- `Plus`와 `Times`는 `NumericFunction` 속성을 갖지만 스칼라 함수에서 제외된다.
- 인덱스 객체(텐서, 연산자)에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
ScalarFunctionQ /@ {Tscalar, Power, Log, CD}
(* {True, True, True, False} *)

ScalarFunctionQ /@ {Sin, Cos, Plus, Times}
(* {True, True, False, False} *)
```

#### 참고 (See Also)

`ObjectQ`, `Tscalar`

---

### RemoveIndexedObject

#### 함수 시그니처

```wolfram
RemoveIndexedObject[oName]
RemoveIndexedObject[{name1, name2, ...}]
```

#### 설명 (Details)

인덱스 객체의 모든 정의를 제거한다.

- 예약된 이름(`Metricg`, `Kdelta`, `Epsilon`, `CD` 등)에는 작동하지 않으며, 오류 메시지가 출력된다.
- 리스트를 입력하면 각 객체에 대해 순차적으로 제거를 수행한다.
- 제거된 심볼은 `IndexedObjectQ` 등의 모든 판별 함수에서 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
DefTensor[T[la, lb], "ba"]
IndexedObjectQ[T]
(* True *)

RemoveIndexedObject[T]
IndexedObjectQ[T]
(* False *)
```

#### 참고 (See Also)

`UndefTensor`, `IndexedObjectQ`

---

## 텐서 정의

---

### DefTensor (Tdefine)

#### 함수 시그니처

```wolfram
DefTensor[tensor[indices], "symmetryString"]
DefTensor[tensor, "symmetryString"]
DefTensor[tensor, nRank]
DefTensor[tensor, nRank, kind]
DefTensor[tensor[indices], "symmetryString", PrintAs -> "str"]
```

#### 설명 (Details)

새 텐서를 정의한다. `Tdefine`은 `DefTensor`의 별칭이다.

**대칭성 문자열 (symmetry string):**

| 문자열                 | 의미                  |
| ------------------- | ------------------- |
| `"+ba"`             | 대칭 (a,b 교환 시 부호 +)  |
| `"-ba"`             | 반대칭 (a,b 교환 시 부호 -) |
| `"-bacd-abdc+cdab"` | 여러 대칭성 생성원의 조합      |
| `4` 또는 `"4"`        | 대칭성 없는 랭크 4 텐서      |
| `"4+"`              | 완전 대칭 랭크 4 텐서       |
| `"4-"`              | 완전 반대칭 랭크 4 텐서      |
| `"*"`               | 임의 rank, 대칭 없음      |
| `"*+"`              | 임의 rank, 완전 대칭      |
| `"*-"`              | 임의 rank, 완전 반대칭     |

- 대칭성은 동일한 Kind, 동일한 상/하 사이에서만 가능하다.
- 텐서 이름이 인덱스 이름이나 예약된 이름과 같으면 오류가 발생한다.
- 인덱스 'shape'을 명시하지 않는 경우 모든 인덱스가 `DefaultKind`의 하첨자로 설정된다.
- 인덱스 'shape' 예: `la` == {lower, Latin}, u$\mu$ == {upper, Greek}, uA == {upper, Capital}
- `PrintAs` 옵션으로 출력 시 표시되는 문자열을 지정할 수 있다.

#### 예제 (Examples)

**Rank 0 (스칼라):**

```wolfram
DefTensor[s[]]
s[]
(* s *)

DefTensor[s[], PrintAs -> "f"]
s[]
(* f *)

(* Greek가 DefKind로 정의된 Kind인 경우의 스칼라 *)
DefTensor[\[Lambda][], Greek]
```

**고정 Rank, 동일 Shape:**

```wolfram
DefTensor[tens, 3, PrintAs -> "T"]
tens[la, lb, lc]
(* T_abc  -- 세 개의 인덱스 shape 모두 {lower, Latin} *)

DefTensor[tens, "3-", PrintAs -> "T"]  (* 완전 반대칭 *)
tens[la, lb, lc]
(* T_abc *)
```

**고정 Rank, 다양한 Shape:**

```wolfram
DefTensor[tens[la, uA]]  (* 하첨자 Latin + 상첨자 Capital *)
tens[la, uB]
(* tens_a^B *)

DefTensor[tens[la, lb, uA], "-bac", PrintAs -> "T"]
tens[la, lb, uC]
(* T_ab^C *)
```

**임의 Rank:**

```wolfram
DefTensor[tens, "*"]
{tens[], tens[la], tens[la, lb], tens[la, lb, lc]}
(* {tens, tens_a, tens_ab, tens_abc} *)

DefTensor[S, "*+"]  (* 임의 rank 완전 대칭 *)
```

**양-밀스 게이지 이론 예:**

```wolfram
DefKind[Greek, Alphabet["Greek"]]
Tdefine[YMA[l\[Mu], ua], PrintAs -> "A"]
YMA[l\[Mu], ua]
(* A_\[Mu]^a *)

Tdefine[YMF[l\[Mu], l\[Nu], ua], "-bac", PrintAs -> "F"]
YMF[l\[Mu], l\[Nu], ua]
(* F_\[Mu]\[Nu]^a *)
```

#### 참고 (See Also)

`UndefTensor`, `DefKind`, `GetRank`, `GetSymmetry`, `SetSymmetry`

---

### UndefTensor

#### 함수 시그니처

```wolfram
UndefTensor[tensor]
```

#### 설명 (Details)

텐서의 모든 정의를 제거한다.

- `DefTensor`로 정의된 텐서의 내부 속성(대칭성, Kind, 랭크, 출력 문자열 등)을 모두 제거한다.
- 제거 후에는 `IndexedTensorQ`, `IndexedObjectQ` 등이 `False`를 반환한다.
- `IndexedTensorQ`가 `True`인 객체에 대해서만 작동하며, 그렇지 않으면 사용법 메시지가 출력된다.

#### 예제 (Examples)

```wolfram
DefTensor[tens[la, uA], 2, PrintAs -> "T"]
tens[la, uB]
(* T_a^B *)

UndefTensor[tens]
tens[la, uB]
(* tens[la, uB]  — 더 이상 포맷팅되지 않음 *)
```

#### 참고 (See Also)

`DefTensor`, `RemoveIndexedObject`

---

## 텐서 속성 설정 및 조회

---

### GetRank

#### 함수 시그니처

```wolfram
GetRank[tensor]
```

#### 설명 (Details)

텐서의 랭크(인덱스 개수)를 반환한다.

- 정의된 `IndexedOperandQ` 객체(텐서, 미분 형식)에 대해서만 동작한다.
- 임의 rank 텐서(`"*"` 등으로 정의)의 경우 `-1`을 반환한다.
- 스칼라 텐서(rank 0)의 경우 `0`을 반환한다.

#### 예제 (Examples)

```wolfram
Tdefine[F[l\[Mu], l\[Nu], ua], "-bac", PrintAs -> "\[ScriptCapitalF]"]
GetRank[F]
(* 3 *)

DefTensor[s[]]
GetRank[s]
(* 0 *)

DefTensor[T, "*"]
GetRank[T]
(* -1  -- 임의 랭크 *)
```

#### 참고 (See Also)

`DefTensor`, `DnupAt`, `KindOf`

---

### DnupAt

#### 함수 시그니처

```wolfram
DnupAt[name, pos]
```

#### 설명 (Details)

인덱스 위치 `pos`에서의 상/하 상태를 반환한다.

- `-1`은 하첨자(covariant), `+1`은 상첨자(contravariant)를 나타낸다.
- `pos`가 랭크보다 크면 마지막 인덱스의 상태를 반환한다.
- `IndexedOperandQ`가 `True`인 객체에 대해서만 동작한다.

#### 예제 (Examples)

```wolfram
Tdefine[F[l\[Mu], l\[Nu], ua], "-bac", PrintAs -> "\[ScriptCapitalF]"]
{DnupAt[F, 1], DnupAt[F, 2], DnupAt[F, 3]}
(* {-1, -1, 1} *)
```

#### 참고 (See Also)

`GetRank`, `DnIndexQ`, `UpIndexQ`

---

### GetSymmetry

#### 함수 시그니처

```wolfram
GetSymmetry[tensor]
```

#### 설명 (Details)

텐서의 대칭성 생성원 집합(`GenSet`)을 반환한다.

- `GenSet[]`(빈 생성원 집합)은 대칭성이 없음을 의미한다.
- 각 생성원은 `{Cycles[...], sign}` 형태의 `CyclesPhased` 표현이다.
- `IndexedOperandQ`가 `True`인 객체에 대해서만 동작한다.

#### 예제 (Examples)

```wolfram
Tdefine[T, "abc"]
GetSymmetry[T]
(* GenSet[] — 대칭 없음 *)

SetSymmetry[T, "acb"]
GetSymmetry[T]
(* GenSet[{Cycles[{{2, 3}}], 1}] *)
```

#### 참고 (See Also)

`SetSymmetry`, `AllPermutations`, `GStoString`, `DefTensor`

---

### SetSymmetry

#### 함수 시그니처

```wolfram
SetSymmetry[tensor, "symmetryString"]
```

#### 설명 (Details)

텐서의 인덱스 대칭성을 재설정한다.

- 기존 대칭성을 완전히 대체한다.
- 대칭성 문자열의 형식은 `DefTensor`와 동일하다.
- `IndexedOperandQ`가 `True`인 객체에 대해서만 동작한다.

#### 예제 (Examples)

```wolfram
Tdefine[T, "abc"]
GetSymmetry[T]
(* GenSet[] *)

SetSymmetry[T, "+bac"]
GetSymmetry[T]
(* GenSet[{Cycles[{{1, 2}}], 1}] *)
```

#### 참고 (See Also)

`GetSymmetry`, `DefTensor`, `AllPermutations`

---

### AllPermutations

#### 함수 시그니처

```wolfram
AllPermutations[permS]
```

#### 설명 (Details)

대칭성 문자열에 의해 생성되는 모든 순열과 가중치를 문자열 형식으로 생성한다.

- 대칭 생성원으로부터 전체 대칭 그룹을 계산하고, 각 순열의 부호를 `+`/`-`로 표시한다.
- 임의 rank(`"*"` 등)에는 사용할 수 없다.

#### 예제 (Examples)

```wolfram
AllPermutations["-bacd-abdc+cdab"]
(* "+abcd-abdc-bacd+badc+cdab-cdba-dcab+dcba" *)

AllPermutations["+ba"]
(* "+ab+ba" *)

AllPermutations["-ba"]
(* "+ab-ba" *)
```

#### 참고 (See Also)

`GetSymmetry`, `GStoString`, `DefTensor`

---

### GStoString

#### 함수 시그니처

```wolfram
GStoString[gs]
GStoString[gs, len]
```

#### 설명 (Details)

자료형이 `GenSet`인 `gs`를 문자열 표현으로 변환한다.

- `len`을 생략하면 생성원 집합에서 최대 랭크를 자동으로 결정한다.
- `len`을 명시하면 해당 랭크에 대한 문자열 표현을 생성한다.
- 생성원(generator)만 출력하며, 전체 순열은 `AllPermutations`를 사용한다.

#### 예제 (Examples)

```wolfram
{rank, GS} = mGRG`STensor`Private`toRankAndGenSet["-bacd-abdc+cdab"]
GStoString[GS, rank]
(* "-bacd-abdc+cdab" *)
```

#### 참고 (See Also)

`GetSymmetry`, `AllPermutations`

---

### KindOf

#### 함수 시그니처

```wolfram
KindOf[obj]
KindOf[obj, pos]
KindOf[obj[indices], idx]
```

#### 설명 (Details)

객체 `obj`의 인덱스 위치 `pos`에서의 Kind를 반환한다.

- 인자 없이 이름만 사용하면 첫 번째 인덱스의 Kind를 반환한다.
- `pos`가 랭크보다 크면 마지막 인덱스의 Kind를 반환한다.
- `obj[indices]` 형태에서 특정 인덱스 `idx`를 지정하면 해당 인덱스의 위치에 대응하는 Kind를 반환한다.

**특수 객체의 Kind:**

| 객체 | Kind |
|------|------|
| `Kdelta` | `All` (모든 Kind에서 사용 가능) |
| `BD` | `All` (모든 Kind에서 사용 가능) |
| `Epsilon`, `Metricg`, `Torsion` | `DefaultKind` |
| `CD` | `DefaultKind` |
| LD-type 연산자 | 인자의 Kind에 따라 결정 |

#### 예제 (Examples)

```wolfram
Tdefine[F[l\[Mu], l\[Nu], ua], "-bac", PrintAs -> "\[ScriptCapitalF]"]
{KindOf[F, 1], KindOf[F, 2], KindOf[F, 3]}
(* {Greek, Greek, Latin} *)

KindOf[F[l\[Mu], l\[Nu], ua], l\[Mu]]
(* Greek *)

KindOf[Kdelta]
(* All *)

KindOf[CD]
(* Latin *)  (* DefaultKind가 Latin인 경우 *)
```

#### 참고 (See Also)

`IndexToKind`, `DefKind`, `DefaultKind`, `GetRank`

---

## HeadQs 옵션

---

### HeadQs

#### 함수 시그니처

```wolfram
HeadQs -> {testFunc1, testFunc2, ...}
```

#### 설명 (Details)

`HeadQs`는 여러 함수에서 사용되는 옵션으로, 특정 유형의 Object만 대상으로 지정할 때 사용한다.

- 기본값은 `{IndexedObjectQ}`로, 모든 인덱스 객체를 대상으로 한다.
- 리스트에 포함된 모든 판별 함수를 `And` 조건으로 적용한다.
- `ExpandObject`, `FreeObjectQ`, `IndicesOf` 등의 함수에서 사용할 수 있다.

#### 예제 (Examples)

```wolfram
(* IndexedTensorQ인 객체에 대해서만 Expand *)
ExpandObject[expr, HeadQs -> {IndexedTensorQ}]

(* 텐서가 없는 항인지 검사 *)
FreeObjectQ[expr, HeadQs -> {IndexedTensorQ}]
```

#### 참고 (See Also)

`IndexQs`, `ObjectQ`, `IndexedObjectQ`, `IndexedTensorQ`, `ExpandObject`, `FreeObjectQ`
