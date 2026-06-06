# IndexNotation — Kind 시스템

Kind는 인덱스의 종류(IndexKind), 차원, 좌표계, 공변 미분, 계량 텐서 등을 관리한다. 구현의 편리성을 위해 Kind와 IndexKind에 동일한 이름을 사용한다. 사용자 입장에서는 Kind 개념만 고려하면 된다.

---

## Kind 정의

---

### DefKind

#### 함수 시그니처

```wolfram
DefKind[kind, {"a", "b", ...}]
DefKind[kind, {"a", "b", ...}, dimension]
```

#### 설명 (Details)

새로운 Kind를 인덱스 문자 집합과 함께 정의한다.

- 내부적으로 `defIndexKind`를 호출한 후 Kind 속성을 설정한다.
- `DefKind`는 `SetIndices`를 자동 호출하므로 별도로 `SetIndices`를 호출할 필요는 없다.
- 이미 정의된 Kind를 다시 정의하면 에러 메시지가 출력된다. 재정의하려면 먼저 `UndefKind`를 호출해야 한다.
- 세 번째 인자 `dimension`을 지정하면 `GetDimension[kind] = dimension`이 자동으로 설정된다.
- `DefaultKind`가 아닌 Kind의 경우, `GetEpsilon`, `GetStructuref`, `GetTorsion`은 `EpsilonKind`, `StructurefKind`, `TorsionKind` 형태의 심볼로 자동 생성된다.
- Kind 개념의 사용 예: 일반상대론의 표준 표기법으로 `Latin` 문자 (a, b, c, ...)는 Abstract 인덱스, `Greek` 문자 ($\mu$, $\nu$, $\rho$, ...)는 시공간 성분 인덱스, `Latin` 문자 (i, j, k,...)는 공간 성분 인덱스.

#### 예제 (Examples)

```wolfram
DefKind[Greek, Alphabet["Greek"]]

GetIndices[Greek]
(* {lα, lβ, ..., lω, uα, uβ, ..., uω} *)

GetEpsilon[Greek]
(* EpsilonGreek *)

DefinedKindQ[Greek]
(* True *)
```

```wolfram
(* 차원을 함께 지정 *)
DefKind[Capital, {"A", "B", "C"}, 3]

GetDimension[Capital]
(* 3 *)
```

#### 참고 (See Also)

`UndefKind`, `DefinedKindQ`, `SetIndices`, `SetDefaultKind`

---

### UndefKind

#### 함수 시그니처

```wolfram
UndefKind[kind]
```

#### 설명 (Details)

지정된 Kind의 정의를 제거한다.

- 기본적으로 `DefaultKind`는 `Latin`으로 설정되어 있고, `DefaultKind`로 설정된 kind는 제거할 수 없다. 따라서, `Latin`을 제거하려면 `SetDefaultKind`를 사용하여 `DefaultKind`를 변경한 후 제거해야 한다.
- Kind 제거 시 연관된 `GetEpsilon`, `GetStructuref`, `GetTorsion` 값과 `CoordinateBasisQ` 정의도 함께 제거된다.

#### 예제 (Examples)

```wolfram
UndefKind[Greek]
DefinedKindQ[Greek]
(* False *)

UndefKind[Latin]  (* Latin이 DefaultKind인 경우 *)
(* Msg: Cannot remove the Latin kind. *)
```

#### 참고 (See Also)

`DefKind`, `DefinedKindQ`, `SetDefaultKind`

---

### DefinedKindQ

#### 함수 시그니처

```wolfram
DefinedKindQ[kind]
```

#### 설명 (Details)

`kind`가 정의된 Kind이면 `True`를 반환한다.

- 내부적으로 `definedKindList`에 `kind`가 포함되어 있는지 확인한다.
- 심볼이 아닌 인자에 대해서는 항상 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
DefinedKindQ[Latin]
(* True *)

DefinedKindQ[Greek]  (* 정의되지 않은 경우 *)
(* False *)

DefinedKindQ[123]
(* False *)
```

#### 참고 (See Also)

`CheckKind`, `DefKind`

---

### CheckKind

#### 함수 시그니처

```wolfram
CheckKind[kind]
CheckKind[{kind1, kind2, ...}]
```

#### 설명 (Details)

`kind`가 정의된 Kind이면 `True`를 반환하고, 아니면 에러 메시지와 함께 `False`를 반환한다.

- `DefinedKindQ`와 거의 동일하지만, 정의되지 않았을 때 에러 메시지를 출력한다.
- 리스트 입력 시 모든 Kind가 정의되어 있어야 `True`를 반환한다.

#### 예제 (Examples)

```wolfram
CheckKind[Latin]
(* True *)

CheckKind[undefinedKind]
(* General::invalid: undefinedKind is not a valid kind. *)
(* False *)

CheckKind[{Latin, Greek}]  (* Greek이 정의되지 않은 경우 *)
(* False *)
```

#### 참고 (See Also)

`DefinedKindQ`, `DefKind`

---

### KindMatchQ

#### 함수 시그니처

```wolfram
KindMatchQ[kind1, kind2]
```

#### 설명 (Details)

두 Kind가 호환 가능하면 `True`를 반환한다.

- `All`은 모든 Kind와 호환된다.
- `NonKind`는 어떤 Kind와도 호환되지 않는다.
- 같은 Kind끼리만 호환되며, 서로 다른 두 Kind는 호환되지 않는다.

#### 예제 (Examples)

```wolfram
{KindMatchQ[All, Latin], KindMatchQ[Capital, All], KindMatchQ[Latin, Capital]}
(* {True, True, False} *)

KindMatchQ[NonKind, Latin]
(* False *)

KindMatchQ[Latin, Latin]
(* True *)
```

#### 참고 (See Also)

`DefinedKindQ`, `DefaultKind`, `NonKind`, `All`

---

## 전역 심볼

---

### DefaultKind

#### 함수 시그니처

```wolfram
DefaultKind
```

#### 설명 (Details)

기본 인덱스 Kind를 나타낸다. `SetDefaultKind`로 변경할 수 있다.

- 기본값은 `Latin`이다.
- Kind 인자를 생략하는 대부분의 함수(`SetDimension`, `SetCoordinates`, `SetSig` 등)에서 `DefaultKind`가 자동으로 사용된다.

#### 참고 (See Also)

`SetDefaultKind`, `Latin`, `NonKind`

---

### NonKind

#### 함수 시그니처

```wolfram
NonKind
```

#### 설명 (Details)

유효한 Kind가 아닌 경우의 반환값이다.

- `IndexToKind`가 인덱스를 어떤 Kind에도 연결할 수 없을 때 반환한다.
- `KindMatchQ`에서 `NonKind`는 어떤 Kind와도 호환되지 않는다.

#### 참고 (See Also)

`DefaultKind`, `KindMatchQ`, `IndexToKind`

---

### Latin

#### 함수 시그니처

```wolfram
Latin
```

#### 설명 (Details)

인덱스 Kind가 라틴 문자(`a`, `b`, `c`, ...)인 사전 정의된 Kind이다.

- 기본적으로 `DefaultKind`로 설정되어 있다.
- `Latin`이 `DefaultKind`일 때 `UndefKind[Latin]`는 유효한 명령이 아니다.

#### 참고 (See Also)

`DefaultKind`, `DefKind`

---

## 좌표계 (Coordinates)

---

### SetCoordinates

#### 함수 시그니처

```wolfram
SetCoordinates[coSys]
SetCoordinates[coSys, kind]
SetCoordinates[coSys, basisM]
SetCoordinates[coSys, basisM, kind]
```

#### 설명 (Details)

지정된 Kind에 좌표계를 설정한다.

- `kind`를 생략하면 `DefaultKind`가 사용된다.
- `coSys`는 심볼들의 리스트여야 한다.
- 좌표계 설정 시 차원(`GetDimension`)도 좌표 개수에 따라 자동으로 설정된다.
- 이미 차원이 설정되어 있으면 좌표 개수와 일치하는지 검사한다.
- 좌표 기저(coordinate basis)의 경우 `SetCoordinates[coSys]` 또는 `SetCoordinates[coSys, kind]`를 사용한다.
- 비좌표 기저(non-coordinate basis)의 경우 `SetCoordinates[coSys, basisM]` 또는 `SetCoordinates[coSys, basisM, kind]`를 사용하며, `basisM`은 정방 행렬이어야 한다.
- 좌표 기저 모드에서 비좌표 기저 형식을 호출하면 에러가 발생하고, 그 반대도 마찬가지이다.

#### 예제 (Examples)

```wolfram
SetCoordinates[{t, x, y, z}]
GetCoordinates[]
(* {t, x, y, z} *)
```

```wolfram
(* 비좌표 기저 *)
Off[CoordinateBasisFlag]
basisM = {{-ρ[t,x], 0, 0, 0}, {0, -ρ[t,x], 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1}};
SetCoordinates[{t, x, y, z}, basisM]
```

#### 참고 (See Also)

`GetCoordinates`, `ClearCoordinates`, `CoordinateBasisQ`

---

### GetCoordinates

#### 함수 시그니처

```wolfram
GetCoordinates[]
GetCoordinates[kind]
```

#### 설명 (Details)

지정된 Kind의 좌표를 반환한다.

- `kind`를 생략하면 `DefaultKind`가 사용된다.

#### 예제 (Examples)

```wolfram
SetCoordinates[{t, r, θ, ϕ}]
GetCoordinates[]
(* {t, r, θ, ϕ} *)
```

#### 참고 (See Also)

`SetCoordinates`, `ClearCoordinates`

---

### ClearCoordinates

#### 함수 시그니처

```wolfram
ClearCoordinates[kind]
```

#### 설명 (Details)

지정된 Kind의 좌표 정의를 제거한다.

- `kind`를 생략하면 `DefaultKind`가 사용된다.
- 좌표 제거 시 `GetDimension`과 `GetCoordinates`의 값이 함께 제거된다.
- 비좌표 기저인 경우, 기저 행렬(`basisMatrix`)도 함께 제거된다.

#### 참고 (See Also)

`SetCoordinates`, `GetCoordinates`

---

## 차원 (Dimension)

---

### SetDimension

#### 함수 시그니처

```wolfram
SetDimension[num]
SetDimension[num, kind]
```

#### 설명 (Details)

지정된 Kind의 차원을 `num`으로 설정한다.

- `kind`를 생략하면 `DefaultKind`가 사용된다.
- `num`은 양의 정수여야 한다.
- 차원을 기호 값으로 설정하려면 `GetDimension[kind] = n` 형태로 직접 대입한다.

#### 예제 (Examples)

```wolfram
SetDimension[4]
GetDimension[]
(* 4 *)

SetDimension[3, Capital]
GetDimension[Capital]
(* 3 *)
```

```wolfram
(* 기호 차원 설정 *)
GetDimension[Greek] = n;
GetDimension[Greek]
(* n *)
```

#### 참고 (See Also)

`GetDimension`, `ClearDimension`

---

### GetDimension

#### 함수 시그니처

```wolfram
GetDimension[]
GetDimension[kind]
```

#### 설명 (Details)

지정된 Kind의 차원을 반환한다.

- `kind`를 생략하면 `DefaultKind`가 사용된다.
- `GetDimension`은 `OwnValues`가 아닌 `DownValues`로 저장되므로, 기호 값 설정 시 `GetDimension[kind] = n` 형태를 사용한다.

#### 참고 (See Also)

`SetDimension`, `ClearDimension`

---

### ClearDimension

#### 함수 시그니처

```wolfram
ClearDimension[kind]
```

#### 설명 (Details)

지정된 Kind의 차원 정의를 제거한다.

- `kind`가 정의된 Kind인지 `CheckKind`로 먼저 검사한다.
- 값이 설정되어 있는 경우에만 제거한다.

#### 참고 (See Also)

`SetDimension`, `GetDimension`

---

## 시그니처 (Signature)

---

### SetSig

#### 함수 시그니처

```wolfram
SetSig[s]
SetSig[s, kind]
```

#### 설명 (Details)

메트릭 시그니처의 음수 고유값 개수 `s`를 설정한다.

- `kind`를 생략하면 `DefaultKind`가 사용된다.
- `s`는 정수여야 한다.
- Sig는 계량 텐서를 대각선 단위 행렬 형태로 만들었을 때 음수의 개수이다 (참고: Wald (1984), 88페이지).
- 예를 들어, 시그니처 $(-,+,+,+)$인 경우 `s = 1`이다.
- 기호 값 설정은 `GetSig[kind] = s` 형태를 사용한다.

#### 예제 (Examples)

```wolfram
SetSig[1]
GetSig[]
(* 1 *)
```

#### 참고 (See Also)

`GetSig`, `ClearSig`

---

### GetSig

#### 함수 시그니처

```wolfram
GetSig[]
GetSig[kind]
```

#### 설명 (Details)

지정된 Kind의 시그니처 파라미터를 반환한다.

- `kind`를 생략하면 `DefaultKind`가 사용된다.

#### 참고 (See Also)

`SetSig`, `ClearSig`

---

### ClearSig

#### 함수 시그니처

```wolfram
ClearSig[kind]
```

#### 설명 (Details)

지정된 Kind의 시그니처 정의를 제거한다.

- `kind`가 정의된 Kind인지 `CheckKind`로 먼저 검사한다.
- 값이 설정되어 있는 경우에만 제거한다.

#### 참고 (See Also)

`SetSig`, `GetSig`

---

## 인덱스 유효성 검사

---

### ValidIndexQ

#### 함수 시그니처

```wolfram
ValidIndexQ[index]
ValidIndexQ[index, kind]
ValidIndexQ[indexList, kind]
```

#### 설명 (Details)

`index`가 `kind`에 대해 유효한지 검사한다.

- 심볼릭 인덱스는 Kind 호환성(`KindMatchQ`)을 검사한다.
- 성분 인덱스는 차원 범위 내에 있는지 검사한다.
- `0`은 유효한 인덱스가 아니다.
- `kind`를 생략하면 `DefaultKind`가 사용된다.
- `All`을 사용하면 Kind와 무관하게 인덱스의 형식만 검사한다.
- 리스트를 전달하면 모든 원소에 대해 개별 검사한다.

#### 예제 (Examples)

```wolfram
indexL = {-1, la, lA, 1, ua, uA, laa, uaa}
ValidIndexQ /@ indexL
(* {True, True, False, True, True, False, False, False}  -- 기본 Kind로 `Latin`만 정의된 경우 *)

Select[indexL, ValidIndexQ[#, All] &]
(* {-1, la, lA, 1, ua, uA} *)
```

#### 참고 (See Also)

`ValidIndicesQ`, `KindMatchQ`, `ComponentIndexQ`, `TensorialIndexQ`

---

### ValidIndicesQ

#### 함수 시그니처

```wolfram
ValidIndicesQ[indexList]
ValidIndicesQ[indexList, kind]
```

#### 설명 (Details)

모든 인덱스가 유효하고 심볼릭 인덱스에 중복이 없는지 검사한다.

- `ValidIndexQ`로 각 인덱스의 유효성을 먼저 검사한 후, 심볼릭 인덱스의 중복 여부를 추가로 검사한다.
- `kind`를 생략하면 `DefaultKind`가 사용된다.

#### 예제 (Examples)

```wolfram
ValidIndicesQ[{la, ua}]
(* True *)

ValidIndicesQ[{la, la}]
(* False — 중복 *)

ValidIndicesQ[{la, lA}, All]
(* True *)
```

#### 참고 (See Also)

`ValidIndexQ`, `CheckKind`

---

## Kind 조회 함수

---

### GetMetric

#### 함수 시그니처

```wolfram
GetMetric[kind]
```

#### 설명 (Details)

지정된 Kind의 고유 메트릭 텐서를 반환한다.

- `DefKind` 시점에 초기값은 `Null`로 설정된다.
- 메트릭은 `DefMetric` 함수로 정의해야 한다.

#### 참고 (See Also)

`GetEpsilon`, `GetStructuref`, `GetTorsion`

---

### GetEpsilon

#### 함수 시그니처

```wolfram
GetEpsilon[kind]
```

#### 설명 (Details)

지정된 Kind의 레비-치비타 텐서(체적 형식)를 반환한다.

- `DefaultKind`의 경우 `Epsilon`, 다른 Kind의 경우 `EpsilonKind` 형태의 심볼이 반환된다.

#### 예제 (Examples)

```wolfram
GetEpsilon[Greek]
(* EpsilonGreek *)
```

#### 참고 (See Also)

`GetMetric`, `GetStructuref`, `GetTorsion`

---

### GetStructuref

#### 함수 시그니처

```wolfram
GetStructuref[kind]
```

#### 설명 (Details)

지정된 Kind의 구조 상수 텐서를 반환한다.

- `DefaultKind`의 경우 `Structuref`, 다른 Kind의 경우 `StructurefKind` 형태의 심볼이 반환된다.
- 비좌표 기저에서만 의미가 있다. 구조 상수 텐서 `Structuref`는 `f`로 출력된다.

#### 참고 (See Also)

`GetMetric`, `GetEpsilon`, `GetTorsion`, `CoordinateBasisQ`

---

### GetTorsion

#### 함수 시그니처

```wolfram
GetTorsion[kind]
```

#### 설명 (Details)

지정된 Kind의 비틀림 텐서를 반환한다.

- `DefaultKind`의 경우 `Torsion`, 다른 Kind의 경우 `TorsionKind` 형태의 심볼이 반환된다.
- 공변 도함수가 torsion-free이면 의미없다. 비틀림 텐서의 이름은 `t`로 출력된다.

#### 참고 (See Also)

`GetMetric`, `GetEpsilon`, `GetStructuref`

---

### CoordinateBasisQ

#### 함수 시그니처

```wolfram
CoordinateBasisQ[]
CoordinateBasisQ[kind]
```

#### 설명 (Details)

`kind`의 기저가 좌표 기저이면 `True`를 반환한다.

- 인자 없이 호출하면 `DefaultKind`가 사용된다.
- `CoordinateBasisFlag`를 `Off`/`On`하여 좌표 기저 여부를 전환할 수 있다.

#### 참고 (See Also)

`SetCoordinates`, `GetStructuref`

---

## Kind 정보 표시

---

### Show

#### 함수 시그니처

```wolfram
Show[kind]
Show[DefaultKind]
```

#### 설명 (Details)

Kind의 플래그, 차원, 시그니처, 좌표계 등의 정보를 테이블 형태로 표시한다.

- 정의된 Kind(`DefinedKindQ`를 만족하는)에 대해서만 동작한다.
- `DefaultKind`인 경우 기본 플래그 설정도 함께 표시된다.

#### 예제 (Examples)

```wolfram
SetDimension[4]
SetSig[1]
SetCoordinates[{t, r, θ, ϕ}]
Show[DefaultKind]
(*
AutoFlag          False
MarkErrorFlag     True
...
Kind              Latin
Dimension         4
Sig               1
Coordinates       t, r, θ, ϕ
CoordinateBasisQ  True
*)
```

#### 참고 (See Also)

`DefKind`, `SetDimension`, `SetSig`, `SetCoordinates`
