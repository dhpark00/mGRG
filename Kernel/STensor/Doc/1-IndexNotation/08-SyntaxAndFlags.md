# IndexNotation — 구문 검사 및 플래그 (Syntax Checking and Flags)

자동 후처리(`postEval`), 구문 검사(`SyntaxCheck`), 오류 표시(`ErrorT`), 스칼라 래퍼(`Tscalar`), 그리고 전역 플래그(`On`/`Off`)를 다룬다.

---

## 자동 후처리 (Automatic Post-Processing)

---

### postEval

#### 설명 (Details)

`postEval`은 `$Post`에 등록되어 Mathematica 출력마다 자동으로 실행되는 내부 함수이다. `AutoFlag`가 `On`이면 활성화된다.

처리 순서:

1. `SyntaxCheckFlag`가 `On`이면 `SyntaxCheck`를 실행하여 오류가 있으면 즉시 반환
2. `ExpandObject`로 인덱스 객체를 전개한 뒤, 각 항(term)마다
   - `MarkErrorFlag`가 `Off`이면 `ErrorT`를 제거 (`ErrorT -> Identity`)
   - `ResetDummiesFlag`가 `On`이면 `ResetDummies`로 더미 인덱스 정규화

`postEval`은 패턴 객체가 없고 (`FreePatternQ`), 인덱스 객체가 포함된 표현식에만 동작한다.

#### 참고 (See Also)

`AutoFlag`, `SyntaxCheck`, `ResetDummies`, `ExpandObject`

---

## 구문 검사 (Syntax Checking)

---

### SyntaxCheck

#### 함수 시그니처

```wolfram
SyntaxCheck[expr]
SyntaxCheck[expr, HeadQs -> {headQ1, ...}]
```

#### 설명 (Details)

`expr`의 인덱스 구문을 검사한다. `Listable` 속성을 가진다.

검사 항목:

- **자유 인덱스 일치**: `Plus` 표현식의 각 항이 동일한 자유 인덱스를 가지는지 확인. 불일치 시 `"incompatible free indices"` 오류
- **중복 인덱스**: `DuplicatedIndicesQ`를 사용하여 같은 항 안에서 인덱스가 중복되는지 확인
- **연산자 인덱스 유효성**: CD 타입 연산자의 인덱스가 유효한지, 메트릭 공간이 아닌 경우 하향 인덱스인지 확인
- **스칼라 함수 인자**: `ScalarFunctionQ` 함수의 인자가 스칼라(자유 인덱스 없음)인지 확인
- **Tscalar 인자 수**: `Tscalar`은 정확히 1개의 인자만 허용
- **Epsilon 인덱스 수**: `Epsilon`의 인덱스 수가 차원과 일치하는지 확인
- **인덱스 개수**: `IndexedOperandQ` 객체의 인덱스 수가 `GetRank`와 일치하는지 확인

오류가 발견되면 해당 부분을 `ErrorT`로 감싸서 반환한다. 오류가 없으면 원래 표현식을 그대로 반환한다.

#### 예제 (Examples)

```wolfram
(* Plus의 각 항에서 자유 인덱스가 불일치하면 오류 *)
SyntaxCheck[v[la] + T[la, lb]]
(* → Msg::err: incompatible free indices: {la} and {la, lb} *)
(* → ErrorT[v[la] + T[la, lb]] *)

(* 중복 인덱스 검출 *)
SyntaxCheck[T[la, la]]
(* → ErrorT[T][la, la]  -- (la가 두 번 나타남) *)

(* 정상 표현식 *)
SyntaxCheck[v[la] w[ua]]
(* → v[la] w[ua]  -- (오류 없음) *)
```

#### 참고 (See Also)

`ErrorT`, `SyntaxCheckFlag`, `DuplicatedIndicesQ`, `FindFreeTensorialIndices`

---

### ErrorT

#### 설명 (Details)

구문 오류가 있는 표현식을 감싸는 래퍼이다. `ErrorT`로 감싸진 표현식은 빨간색으로 출력된다.

두 가지 형태가 있다:

| 형태 | 용도 |
|------|------|
| `ErrorT[oName][args...]` | 특정 인덱스 객체의 오류 (예: 잘못된 인덱스를 가진 텐서) |
| `ErrorT[expr]` | 일반 표현식의 오류 (예: 자유 인덱스 불일치) |

`MarkErrorFlag`가 `Off`이면 `postEval`에서 `ErrorT -> Identity`로 치환되어 오류 표시가 제거된다.

#### 예제 (Examples)

```wolfram
(* 빨간색으로 표시됨 *)
ErrorT[v][la, la]

(* MarkErrorFlag가 Off이면 ErrorT가 제거됨 *)
Off[MarkErrorFlag]
v[la, la]  -- (* ErrorT 없이 출력 *)
```

#### 참고 (See Also)

`SyntaxCheck`, `MarkErrorFlag`

---

### Tscalar

#### 함수 시그니처

```wolfram
Tscalar[expr]
```

#### 설명 (Details)

스칼라 표현을 위한 래퍼이다. 텐서 연산으로부터 보호하기 위해 사용한다. 마젠타색 괄호 `(`, `)`로 표시된다.

자동 규칙:

- `Tscalar[expr_Plus]` → 각 항에 `Tscalar`을 적용 (분배)
- `Tscalar[c_?ConstantQ]` → `c` (상수는 그대로)
- `Tscalar[... * symbol * ...]` → `symbol * Tscalar[나머지]` (일반 심볼 추출)
- `Tscalar[... * sfName[arg] * ...]` → `sfName[arg] * Tscalar[나머지]` (스칼라 함수 추출)

#### 예제 (Examples)

```wolfram
(* 스칼라를 보호 *)
Tscalar[x + y]
(* → Tscalar[x] + Tscalar[y] *)

(* 상수는 추출됨 *)
Tscalar[2 x]
(* → 2 x *)
```

#### 참고 (See Also)

`ScalarFunctionQ`, `ConstantQ`

---

## 플래그 (Flags)

mGRG의 플래그는 `flagTable[key]`에 저장되며, Mathematica 내장 `On`/`Off`를 오버로드하여 제어한다.

---

### AutoFlag

#### 설명 (Details)

자동 후처리(`postEval`)의 활성화 여부를 제어한다.

| 상태 | 동작 |
|------|------|
| `On[AutoFlag]` (기본값) | `$Post = postEval` 등록. 모든 출력에 자동 후처리 적용 |
| `Off[AutoFlag]` | `$Post =.` 해제. 자동 후처리 비활성화 |

`AutoFlag`는 다른 모든 플래그의 상위 스위치이다. `Off[AutoFlag]`이면 `SyntaxCheckFlag`, `ResetDummiesFlag`, `MarkErrorFlag` 등이 설정되어 있어도 실행되지 않는다.

#### 예제 (Examples)

```wolfram
Off[AutoFlag]   (* 자동 후처리 중지 *)
v[lb] w[lb]     (* ResetDummies 등이 적용되지 않음 *)
On[AutoFlag]    (* 다시 활성화 *)
```

#### 참고 (See Also)

`postEval`, `SyntaxCheckFlag`, `ResetDummiesFlag`, `MarkErrorFlag`

---

### SyntaxCheckFlag

#### 설명 (Details)

자동 구문 검사의 활성화 여부를 제어한다.

| 상태 | 동작 |
|------|------|
| `On[SyntaxCheckFlag]` | 모든 출력에서 `SyntaxCheck` 자동 실행 |
| `Off[SyntaxCheckFlag]` (기본값) | 자동 구문 검사 비활성화 |

**기본값이 `Off`이다.** 성능상의 이유로 자동 구문 검사는 기본적으로 꺼져 있다. 수동으로 `SyntaxCheck[expr]`을 호출하여 검사할 수 있다.

#### 참고 (See Also)

`SyntaxCheck`, `AutoFlag`

---

### MarkErrorFlag

#### 설명 (Details)

오류 표시 여부를 제어한다.

| 상태 | 동작 |
|------|------|
| `On[MarkErrorFlag]` (기본값) | `ErrorT`로 감싸진 표현식이 빨간색으로 표시됨 |
| `Off[MarkErrorFlag]` | `ErrorT -> Identity`로 치환되어 오류 표시 제거 |

#### 참고 (See Also)

`ErrorT`, `AutoFlag`

---

### ResetDummiesFlag

#### 설명 (Details)

더미 인덱스 자동 리셋 여부를 제어한다.

| 상태 | 동작 |
|------|------|
| `On[ResetDummiesFlag]` (기본값) | 출력 시 더미 인덱스를 정규 형태로 자동 리셋 |
| `Off[ResetDummiesFlag]` | 더미 인덱스를 그대로 유지 |

**주의**:
- `ResetDummies`로 인해 `Plus` 표현식의 항 순서가 내부 순서와 달라질 수 있다.
- 출력을 변수에 할당하려면 한 줄 명령 `var = prevCmd`를 사용하지 말고, (`ResetDummies`와 Mathematica의 동작 방식 때문에) 두 줄로 다음과 같이 사용해야 함:

```wolfram
prevCmd
var = %
```

#### 참고 (See Also)

`ResetDummies`, `AutoFlag`

---

### CoordinateBasisFlag

#### 함수 시그니처

```wolfram
On[CoordinateBasisFlag]
On[CoordinateBasisFlag[kind]]
Off[CoordinateBasisFlag]
Off[CoordinateBasisFlag[kind]]
```

#### 설명 (Details)

특정 Kind의 기저(basis)가 좌표 기저(coordinate basis)인지를 제어한다. Kind를 생략하면 `DefaultKind`에 적용된다. **기본값은 `On`이다.**

`On[CoordinateBasisFlag[kind]]` 실행 시:

- `CoordinateBasisQ[kind] = True` 설정
- `GammaCD`(연결 계수)의 대칭성이 갱신됨: `TorsionFreeQ`이면 `"+bac"` (처음 두 인덱스 대칭)
- `Structuref[kind]`가 제거됨 (좌표 기저에서는 구조 함수가 0)

`Off[CoordinateBasisFlag[kind]]` 실행 시:

- `CoordinateBasisQ[kind] = False` 설정
- `GammaCD`의 대칭성이 `"abc"` (대칭 없음)으로 변경
- `Structuref` (또는 `SymbolJoin[Structuref, kind]`)가 정의됨

#### 예제 (Examples)

```wolfram
(* 좌표 기저 사용 (기본값) *)
On[CoordinateBasisFlag]
CoordinateBasisQ[Latin]
(* → True *)

(* 비좌표 기저로 전환 *)
Off[CoordinateBasisFlag]
CoordinateBasisQ[Latin]
(* → False *)
(* Structuref 텐서가 정의됨 *)
```

#### 참고 (See Also)

`CoordinateBasisQ`, `GetStructuref`, `Structuref`, `TorsionFreeQ`

---

## 플래그 기본값 요약

내부 초기화 함수 `initIndexNotation[]` 실행 시 설정되는 기본값:

| 플래그                                | 기본값   | 설명             |
| ---------------------------------- | ----- | -------------- |
| `AutoFlag`                         | `On`  | 자동 후처리 활성      |
| `MarkErrorFlag`                    | `On`  | 오류 빨간색 표시      |
| `ResetDummiesFlag`                 | `On`  | 더미 인덱스 자동 리셋   |
| `SyntaxCheckFlag`                  | `Off` | 자동 구문 검사 비활성   |
| `CoordinateBasisFlag[DefaultKind]` | `On`  | 기본 Kind는 좌표 기저 |

추가로 `Off[General::spell1]`과 `Off[General::spell]`이 설정되어 철자 경고가 억제된다.

---

## 현재 설정 확인

### Show[kind]

`Show[kind]`는 해당 Kind의 현재 상태를 테이블 형식으로 표시한다. `DefaultKind`인 경우 모든 전역 플래그(`AutoFlag`, `MarkErrorFlag`, `ResetDummiesFlag`, `SyntaxCheckFlag`, `KdeltaFlag`, `MetricgFlag`, `InitCTensorFlag`, `TorsionFreeQ[CD]`)도 함께 표시된다.

표시 항목:

- 전역 플래그 (DefaultKind인 경우)
- Kind 이름
- Dimension
- Sig (시그니처)
- Coordinates
- CoordinateBasisQ
- EvaluateBDFlag

#### 예제 (Examples)

```wolfram
Show[Latin]
(* →
  AutoFlag            True
  MarkErrorFlag       True
  ResetDummiesFlag    True
  SyntaxCheckFlag     False
  KdeltaFlag          ...
  MetricgFlag         ...
  InitCTensorFlag     ...
  TorsionFreeQ of CD  ...
  ----------          -----
  Kind                Latin
  Dimension           Any
  Sig                 Any
  Coordinates         none
  CoordinateBasisQ    True
  EvaluateBDFlag      False
*)
```

#### 참고 (See Also)

`DefKind`, `GetDimension`, `GetSig`, `GetCoordinates`, `CoordinateBasisQ`

---

## 초기화

### initIndexNotation

#### 설명 (Details)

`IndexNotation.m`이 로딩될 때 자동으로 실행되는 내부 초기화 함수이다. 다음을 수행한다:

1. 옵션 기본값 설정: `HeadQs -> {IndexedObjectQ}`, `IndexQs -> {True&}`
2. 이전 로딩 시 등록된 인덱스 심볼 정리
3. `DefaultKind := Latin` 설정
4. `DefKind[Latin, Alphabet[]]`으로 기본 Kind 정의
5. 예약 이름 등록 (`C`, `D`, `E`, `I`, `N`, `O`, `CD`, `LD`, `XD`, `XP`, `Tscalar`, `ErrorT` 등)
6. `Kdelta` (크로네커 델타) 정의
7. 기본 플래그 설정 (`On[AutoFlag]`, `On[MarkErrorFlag]`, `On[ResetDummiesFlag]`, `Off[SyntaxCheckFlag]`, `On[CoordinateBasisFlag[DefaultKind]]`)

재로딩 시에는 이전에 등록된 인덱스 심볼들이 먼저 정리(`setIndices[{}, kind]`)된 후 다시 초기화된다.
