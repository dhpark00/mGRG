# IndexNotation — 인덱스 (Indices)

인덱스는 (IndexType, Lower/Upper, IndexKind)에 따라 구별된다. 인덱스에 대한 연산을 하는 함수는 옵션으로 `IndexQs`를 가질 수 있다; 이 옵션을 갖는 함수는 그 옵션으로 주어진 질의함수들을 모두 만족하는 인덱스에 대해서만 작용한다.

---

## 인덱스 종류 판별 (Index Type)

---

### RegularIndexQ

#### 함수 시그니처

```wolfram
RegularIndexQ[index]
```

#### 설명 (Details)

`index`가 `SetIndices`로 정의된 정규(non-dummy) 심볼릭 인덱스이면 `True`를 반환한다.

- 더미 인덱스(`NewDummy`로 생성)나 성분 인덱스(정수)는 `False`를 반환한다.
- 정의되지 않은 심볼도 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
RegularIndexQ /@ {hello, dhpark, la, lo, ua, uo}
(* {False, False, True, True, True, True} *)
```

#### 참고 (See Also)

`DummyIndexQ`, `ComponentIndexQ`, `TensorialIndexQ`, `SetIndices`

---

### DummyIndexQ

#### 함수 시그니처

```wolfram
DummyIndexQ[index]
```

#### 설명 (Details)

`index`가 시스템이 생성한 더미 인덱스이면 `True`를 반환한다.

- 더미 인덱스는 `NewDummy` 명령으로 생성되거나 프로그램이 자동으로 생성한 인덱스이다.
- 정규 인덱스나 성분 인덱스에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
NewDummy[Latin]
(* {lLatin$10322, uLatin$10322} *)

DummyIndexQ /@ %
(* {True, True} *)
```

#### 참고 (See Also)

`RegularIndexQ`, `NewDummy`, `TensorialIndexQ`

---

### ComponentIndexQ

#### 함수 시그니처

```wolfram
ComponentIndexQ[index]
```

#### 설명 (Details)

`index`가 성분 인덱스(0이 아닌 정수)이면 `True`를 반환한다.

- 성분 인덱스는 0을 제외한 정수로 표현된다.
- 음의 정수는 하첨자(covariant), 양의 정수는 상첨자(contravariant)이다.
- 0은 성분 인덱스가 아니다.

#### 예제 (Examples)

```wolfram
ComponentIndexQ /@ {-1, -2, 0, 1, 2}
(* {True, True, False, True, True} *)
```

#### 참고 (See Also)

`TensorialIndexQ`, `DnIndexQ`, `UpIndexQ`

---

### TensorialIndexQ

#### 함수 시그니처

```wolfram
TensorialIndexQ[index]
```

#### 설명 (Details)

`index`가 심볼릭 인덱스(정규 또는 더미)이면 `True`를 반환한다. 성분 인덱스와 구분된다.

- `RegularIndexQ` 또는 `DummyIndexQ`가 `True`이면 `TensorialIndexQ`도 `True`이다.
- 성분 인덱스(정수)에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
TensorialIndexQ /@ {-1, la, ub}
(* {False, True, True} *)
```

#### 참고 (See Also)

`RegularIndexQ`, `DummyIndexQ`, `ComponentIndexQ`

---

## 상/하 첨자 (Lower/Upper)

---

### DnIndexQ

#### 함수 시그니처

```wolfram
DnIndexQ[index]
```

#### 설명 (Details)

`index`가 유효한 하첨자(covariant) 인덱스이면 `True`를 반환한다.

- 심볼의 이름이 `"l"`(소문자 ell)로 시작하면 하첨자이다.
- 음의 정수도 하첨자이다.
- 유효하지 않은 인덱스(정의되지 않은 심볼 등)에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
Select[{-1, la, lμ, lA, 1, ua, uμ, uA}, DnIndexQ]
(* {-1, la} *)
```

> **참고:** 위의 예에서 `lμ`, `lA` 등은 해당 Kind가 정의되었으면 결과가 다를 수 있다. 기본적으로는 Latin Kind만 정의되어 있다.

#### 참고 (See Also)

`UpIndexQ`, `FlipIndex`, `ToDnIndex`

---

### UpIndexQ

#### 함수 시그니처

```wolfram
UpIndexQ[index]
```

#### 설명 (Details)

`index`가 유효한 상첨자(contravariant) 인덱스이면 `True`를 반환한다.

- 심볼의 이름이 `"u"`로 시작하면 상첨자이다.
- 양의 정수도 상첨자이다.
- 유효하지 않은 인덱스(정의되지 않은 심볼 등)에 대해서는 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
Select[{-1, la, lμ, lA, 1, ua, uμ, uA}, UpIndexQ]
(* {1, ua} *)
```

#### 참고 (See Also)

`DnIndexQ`, `FlipIndex`, `ToUpIndex`

---

## 인덱스 Kind 관리

---

### IndexToKind

#### 함수 시그니처

```wolfram
IndexToKind[idx]
```

#### 설명 (Details)

인덱스 `idx`의 종류(Kind)를 반환한다. 해당하는 종류가 없으면 `NonKind`를 반환한다.

- 성분 인덱스(0이 아닌 정수)는 `DefaultKind`에 속한다.
- 0은 유효한 인덱스가 아니므로 `NonKind`를 반환한다.
- 정의되지 않은 심볼도 `NonKind`를 반환한다.

#### 예제 (Examples)

```wolfram
{IndexToKind[la], IndexToKind[ua]}
(* {Latin, Latin} *)

IndexToKind /@ {nonIndex, 0}
(* {NonKind, NonKind} *)

IndexToKind /@ {-1, 0, 2}
(* {Latin, NonKind, Latin} *)
```

#### 참고 (See Also)

`KindIndexQ`, `DefaultKind`, `SetDefaultKind`

---

### KindIndexQ

#### 함수 시그니처

```wolfram
KindIndexQ[ikind]
```

#### 설명 (Details)

인덱스가 `ikind`에 속하는지 검사하는 순수 함수(pure function)를 반환한다.

- 반환되는 함수는 `IndexToKind[#] === ikind &` 형태이다.
- 다른 판별 함수(`DnIndexQ` 등)와 조합하여 복합 조건을 만들 수 있다.
- `IndexQs` 옵션에 전달하는 용도로 자주 사용된다.

#### 예제 (Examples)

```wolfram
KindIndexQ[Latin]
(* IndexToKind[#1] === Latin & *)

KindIndexQ[Latin] /@ NewDummy[Latin]
(* {True, True} *)

KindIndexQ[Latin][#] && DnIndexQ[#] & /@ {la, ub}
(* {True, False} *)
```

#### 참고 (See Also)

`IndexToKind`, `IndexQs`, `TakePairs`

---

### OneDimKindQ

#### 함수 시그니처

```wolfram
OneDimKindQ[ikind]
```

#### 설명 (Details)

`ikind`가 1차원 인덱스 종류이면 `True`를 반환한다.

- 인덱스로 사용할 수 있는 문자가 한 개이면 1차원 Kind이다.
- 1D Kind의 더미 인덱스는 정규 인덱스와 동일하다.

#### 예제 (Examples)

```wolfram
(* Zero Kind를 1개의 문자 "0"으로 정의했다고 가정 *)
OneDimKindQ[Zero]
(* True *)
```

#### 참고 (See Also)

`NewDummy`, `DefKind`

---

### GetIndices

#### 함수 시그니처

```wolfram
GetIndices[ikind]
GetIndices[All]
```

#### 설명 (Details)

지정된 인덱스 Kind의 모든 정의된 Regular 인덱스를 반환한다.

- `GetIndices[ikind]`는 해당 Kind의 하첨자와 상첨자를 모두 반환한다.
- `GetIndices[All]`은 모든 Kind의 인덱스를 반환한다.

#### 예제 (Examples)

```wolfram
GetIndices[Latin]
(* {la, lb, lc, ..., lz, ua, ub, uc, ..., uz} *)

GetIndices[All]
(* {{la, lb, ..., uz}, ...} *)
```

#### 참고 (See Also)

`SetIndices`, `AddIndices`, `DropIndices`

---

### SetIndices

#### 함수 시그니처

```wolfram
SetIndices[{"a", "b", ...}, ikind]
```

#### 설명 (Details)

새로운 인덱스 문자들을 정의한다.

- **주의:** 실행 시 해당 `l*/u*` 심볼의 기존 모든 정의가 지워진다.
- 빈 리스트 `{}`를 사용하면 해당 Kind의 모든 인덱스가 제거된다.
- 각 문자열에 대해 `l` 접두사(하첨자)와 `u` 접두사(상첨자) 심볼이 생성된다.

#### 예제 (Examples)

```wolfram
SetIndices[{"a", "b"}, Latin]
GetIndices[Latin]
(* {la, lb, ua, ub} *)

(* 원래의 정의로 복귀 *)
SetIndices[Alphabet[], Latin]
```

#### 참고 (See Also)

`AddIndices`, `DropIndices`, `GetIndices`, `DefKind`

---

### AddIndices

#### 함수 시그니처

```wolfram
AddIndices[{"c1", "c2", ...}, kind]
```

#### 설명 (Details)

기존 Kind에 새 인덱스 문자를 추가한다.

- 다른 Kind에서 이미 사용 중인 인덱스는 추가할 수 없다.
- 이미 등록된 인덱스를 또 추가하면 무시된다.

#### 예제 (Examples)

```wolfram
AddIndices[ToString /@ {C, D, E}, Capital]
GetIndices[Capital]
(* {lA, lB, lC, lD, lE, uA, uB, uC, uD, uE} *)
```

#### 참고 (See Also)

`SetIndices`, `DropIndices`, `GetIndices`

---

### DropIndices

#### 함수 시그니처

```wolfram
DropIndices[{"c1", "c2", ...}, kind]
DropIndices["c", kind]
```

#### 설명 (Details)

기존 Kind에서 지정된 인덱스 문자를 제거한다.

- 단일 문자열 또는 문자열 리스트를 입력할 수 있다.
- 해당 문자에 대응하는 `l*/u*` 심볼이 Kind에서 제거된다.

#### 예제 (Examples)

```wolfram
DropIndices["t", Latin]
(* Latin Kind에서 "t" 문자에 해당하는 lt, ut가 제거됨 *)

DropIndices[{"x", "y", "z"}, Latin]
```

#### 참고 (See Also)

`SetIndices`, `AddIndices`, `GetIndices`

---

## 더미 인덱스 (Dummy Indices)

---

### NewDummy

#### 함수 시그니처

```wolfram
NewDummy[kind]
```

#### 설명 (Details)

지정된 Kind의 고유한 더미 인덱스를 생성한다. 결과는 `{dnIndex, upIndex}` 쌍이다.

- 매번 호출할 때마다 고유한 인덱스가 생성된다 (`$ModuleNumber` 기반).
- 1D Kind의 더미 인덱스는 정규 인덱스와 동일하다.
- 생성된 인덱스는 `DummyIndexQ`가 `True`를 반환한다.

#### 예제 (Examples)

```wolfram
NewDummy[Latin]
(* {lLatin$34127, uLatin$34127} *)

(* 1D Kind *)
NewDummy[Zero]
(* {l0, u0} *)
```

#### 참고 (See Also)

`DummyIndexQ`, `OneDimKindQ`

---

## 인덱스 올리기와 내리기

---

### FlipIndex

#### 함수 시그니처

```wolfram
FlipIndex[index]
```

#### 설명 (Details)

상첨자를 하첨자로, 하첨자를 상첨자로 변환한다.

- 심볼릭 인덱스의 경우 `l` 접두사와 `u` 접두사를 교환한다.
- 성분 인덱스의 경우 부호를 반전한다.
- 두 번 적용하면 원래 인덱스로 돌아온다.

#### 예제 (Examples)

```wolfram
FlipIndex /@ {-1, la, lμ, lA}
(* {1, ua, uμ, uA} *)

FlipIndex /@ %
(* {-1, la, lμ, lA} *)
```

#### 참고 (See Also)

`ToDnIndex`, `ToUpIndex`, `DnIndexQ`, `UpIndexQ`

---

### ToDnIndex

#### 함수 시그니처

```wolfram
ToDnIndex[index]
```

#### 설명 (Details)

상첨자를 하첨자로 변환한다. 이미 하첨자이면 변화 없음.

- 상첨자 심볼릭 인덱스(`u*`)를 하첨자(`l*`)로 변환한다.
- 양의 정수를 음의 정수로 변환한다.
- 이미 하첨자인 인덱스에 대해서는 그대로 반환한다.

#### 예제 (Examples)

```wolfram
ToDnIndex /@ {1, ua, uμ, uA}
(* {-1, la, lμ, lA} *)
```

#### 참고 (See Also)

`ToUpIndex`, `FlipIndex`, `DnIndexQ`

---

### ToUpIndex

#### 함수 시그니처

```wolfram
ToUpIndex[index]
```

#### 설명 (Details)

하첨자를 상첨자로 변환한다. 이미 상첨자이면 변화 없음.

- 하첨자 심볼릭 인덱스(`l*`)를 상첨자(`u*`)로 변환한다.
- 음의 정수를 양의 정수로 변환한다.
- 이미 상첨자인 인덱스에 대해서는 그대로 반환한다.

#### 예제 (Examples)

```wolfram
ToUpIndex /@ {-1, la, lμ, lA}
(* {1, ua, uμ, uA} *)
```

#### 참고 (See Also)

`ToDnIndex`, `FlipIndex`, `UpIndexQ`

---

## 인덱스 정렬

---

### IndexOrderedQ

#### 함수 시그니처

```wolfram
IndexOrderedQ[indexList]
IndexOrderedQ[list1, list2]
```

#### 설명 (Details)

인덱스 리스트가 정규 순서로 정렬되어 있는지 검사한다.

- 단일 리스트: 리스트 내의 인덱스들이 순서대로 되어 있으면 `True`.
- 두 리스트: `list1`이 `list2` 이전 순서이면 `True`.
- 우선 순위: Tensorial/Component, Free/Dummy, Lexicographic, Lower/Upper 순.

#### 예제 (Examples)

```wolfram
IndexOrderedQ[{la, lb}]
(* True *)

IndexOrderedQ[{la, ua}]
(* True *)

IndexOrderedQ[{la, lb, lc}, {la, lc, lb}]
(* True *)
```

#### 참고 (See Also)

`IndexSort`

---

### IndexSort

#### 함수 시그니처

```wolfram
IndexSort[indexList]
```

#### 설명 (Details)

인덱스 리스트를 정규 순서로 정렬한다.

- Mathematica의 `Sort`와는 다른 순서를 준다.
- 정렬 우선 순위: Tensorial > Component, Free > Dummy, Lexicographic, Lower > Upper.

#### 예제 (Examples)

```wolfram
idxL = {-1, ub, lb, lLatin$34211, 1, ua, la, uLatin$34211}
IndexSort[idxL]
(* {la, ua, lb, ub, lLatin$34211, uLatin$34211, -1, 1} *)

Sort[idxL]
(* {-1, 1, la, lb, lLatin$34211, ua, ub, uLatin$34211} *)
```

#### 참고 (See Also)

`IndexOrderedQ`

---


---
## 인덱스 쌍

---

### PairIndexQ

#### 함수 시그니처

```wolfram
PairIndexQ[i1, i2]
PairIndexQ[{i1, j1}, {i2, j2}, ...]
```

#### 설명 (Details)

`i1`과 `i2`가 유효한 상/하 쌍인지 검사한다.

- 같은 문자의 하첨자/상첨자 쌍이면 `True`.
- 여러 쌍을 동시에 검사할 수 있다 (모든 쌍이 유효해야 `True`).
- 1D Kind의 인덱스와 성분 인덱스는 쌍이 될 수 없다.

#### 예제 (Examples)

```wolfram
{PairIndexQ[la, ua], PairIndexQ[la, ub], PairIndexQ[la, la]}
(* {True, False, False} *)

PairIndexQ[{la, ua}, {lμ, uμ}, {lA, uA}]
(* True *)
```

#### 참고 (See Also)

`TakePairs`, `FlipIndex`

---

### TakePairs

#### 함수 시그니처

```wolfram
TakePairs[indexList]
TakePairs[indexList, opts]
```

#### 설명 (Details)

인덱스 리스트에서 상/하 쌍을 찾아 `{{dn, up}, ...}` 형태로 반환한다.

- 옵션 `IndexQs`를 사용하여 특정 Kind의 인덱스만 대상으로 할 수 있다.

#### 예제 (Examples)

```wolfram
TakePairs[{-1, la, lμ, lA, 1, ua, uμ, uA}]
(* {{la, ua}, {lA, uA}, {lμ, uμ}} *)

TakePairs[idxL, IndexQs -> {KindIndexQ[Latin]}]
(* {{la, ua}} *)
```

#### 참고 (See Also)

`PairIndexQ`, `IndexQs`, `KindIndexQ`

---


---
## 기타

---

### DuplicatedIndicesQ

#### 함수 시그니처

```wolfram
DuplicatedIndicesQ[indexL]
DuplicatedIndicesQ[indexL, True]
```

#### 설명 (Details)

텐서 인덱스 리스트에 중복된 인덱스가 있으면 `True`를 반환한다.

- 성분 인덱스(정수)의 중복은 검사하지 않는다.
- 두 번째 인자가 `True`이면 중복 발견 시 메시지를 출력한다.

#### 예제 (Examples)

```wolfram
DuplicatedIndicesQ[{-1, 1, 1}]
(* False *)

DuplicatedIndicesQ[{la, lb, ua, la}]
(* True *)
```

#### 참고 (See Also)

`TensorialIndexQ`

---

### UpupDndnIndexQ

#### 함수 시그니처

```wolfram
UpupDndnIndexQ[indexL]
```

#### 설명 (Details)

인덱스 리스트의 인덱스가 모두 상첨자이거나 모두 하첨자이면 `True`를 반환한다.

- 상/하 첨자가 섞여 있으면 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
UpupDndnIndexQ /@ {{la, lb, lc}, {la, ub, lc}, {ua, ub, ua}}
(* {True, False, True} *)
```

#### 참고 (See Also)

`DnIndexQ`, `UpIndexQ`
