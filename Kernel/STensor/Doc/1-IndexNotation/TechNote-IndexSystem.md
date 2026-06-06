# Tech Note: 인덱스 체계 (Index System)

이 문서는 mGRG의 인덱스 체계를 워크플로 중심으로 설명한다. 기호 텐서 계산을 시작하기 전에 인덱스를 어떻게 설정하고 관리하는지, 여러 Kind를 동시에 사용하는 방법은 무엇인지를 다룬다. 자세한 함수 설명은 `02-Indices.md` 및 `03-Kind.md` 참고.

---

## 1. 인덱스 체계 개요

mGRG에서 모든 텐서 인덱스는 세 가지 속성으로 분류된다.

| 속성              | 설명                                | 예시                                                          |
| --------------- | --------------------------------- | ----------------------------------------------------------- |
| **IndexType**   | 인덱스의 생성 방식                        | RegularIndex, DummyIndex, ComponentIndex                    |
| **Lower/Upper** | 공변(covariant) / 반변(contravariant) | 접두사 `l` (lower), 접두사 `u` (upper), `-1` (lower), `2` (upper) |
| **IndexKind**   | 인덱스가 속하는 종류                       | `Latin`, `Greek`, `Capital` 등                               |

### IndexType

인덱스는 생성 방식에 따라 세 가지 유형으로 나뉜다.

- **RegularIndex**: 사용자가 `SetIndices` 또는 `DefKind`로 정의한 심볼릭 인덱스. 텐서 표현식에서 자유 인덱스(free index)로 주로 사용된다.

  ```wolfram
  RegularIndexQ /@ {la, lb, ua, ub}
  (* {True, True, True, True} *)
  ```

- **DummyIndex**: 시스템이 `NewDummy`로 자동 생성하는 인덱스. 수축(contraction) 연산에서 내부적으로 사용되며, `lLatin$123` 형태의 이름을 가진다.

  ```wolfram
  NewDummy[Latin]
  (* {lLatin$10322, uLatin$10322} *)

  DummyIndexQ /@ %
  (* {True, True} *)
  ```

- **ComponentIndex**: 0이 아닌 정수. 성분 계산에서 특정 좌표 성분을 지정한다.

  ```wolfram
  ComponentIndexQ /@ {-1, -2, 0, 1, 2}
  (* {True, True, False, True, True} *)
  ```

세 유형은 상호 배타적이다. `TensorialIndexQ`는 RegularIndex와 DummyIndex를 모두 포함하며, ComponentIndex는 제외한다.

### Lower/Upper 구분

심볼릭 인덱스는 접두사로 상/하를 구분한다:

- **`l` 접두사** = lower (covariant, 아래 첨자): `la`, `lb`, `lmu` 등
- **`u` 접두사** = upper (contravariant, 위 첨자): `ua`, `ub`, `umu` 등

성분 인덱스는 부호로 구분한다: 음의 정수 = lower (`-1`, `-2`), 양의 정수 = upper (`1`, `2`). `0`은 유효한 인덱스가 아니다.

```wolfram
Select[{-1, la, 1, ua, ub}, DnIndexQ]
(* {-1, la} *)

Select[{-1, la, 1, ua, ub}, UpIndexQ]
(* {1, ua, ub} *)
```

`FlipIndex`로 상/하를 전환할 수 있다.

```wolfram
FlipIndex /@ {-1, la, 1, ua}
(* {1, ua, -1, la} *)
```

### IndexKind

모든 인덱스는 하나의 Kind에 속한다. `IndexToKind`로 확인할 수 있다.

```wolfram
IndexToKind[la]
(* Latin *)

IndexToKind[-1]   (* 성분 인덱스는 DefaultKind에 속함 *)
(* Latin *)

IndexToKind[hello]   (* 정의되지 않은 심볼 *)
(* NonKind *)
```

---

## 2. Kind 정의와 관리

### Kind의 개념

Kind는 미분기하학에서의 tangent bundle과 유사한 개념이다. 시공간의 접다발, 게이지 군의 Lie 대수, 내부 공간 등 서로 다른 "인덱스의 세계"를 구분한다. 각 Kind는 고유한 인덱스 집합, 차원, 좌표계, 메트릭 시그니처를 가진다.

### 기본 Kind: Latin

mGRG를 로딩하면 `Latin` Kind가 미리 정의되어 있고, `DefaultKind`로 설정된다.

```wolfram
<< mGRG`STensor`

DefinedKindQ[Latin]
(* True *)

DefaultKind
(* Latin *)

GetIndices[Latin]
(* {la, lb, lc, ..., lz, ua, ub, uc, ..., uz} *)
```

`DefaultKind`인 `Latin`은 삭제할 수 없다. Kind 인자를 생략하는 대부분의 함수(`SetDimension`, `SetCoordinates`, `SetSig` 등)는 자동으로 `DefaultKind`를 사용한다.

### DefKind로 새 Kind 정의하기

`DefKind[kindName, charList]`는 새로운 Kind를 정의하면서 동시에 인덱스를 설정한다. 내부적으로 `SetIndices`를 호출하므로 별도 호출이 필요 없다.

```wolfram
DefKind[Greek, Alphabet["Greek"]]

GetIndices[Greek]
(* {l\[Alpha], l\[Beta], ..., l\[Omega], u\[Alpha], u\[Beta], ..., u\[Omega]} *)

IndexToKind[l\[Mu]]
(* Greek *)
```

세 번째 인자로 차원을 함께 지정할 수도 있다.

```wolfram
DefKind[Capital, {"A", "B", "C", "D", "E"}, 5]

GetDimension[Capital]
(* 5 *)
```

이미 정의된 Kind를 다시 정의하면 에러가 발생한다. 재정의가 필요하면 먼저 `UndefKind`를 호출한다.

```wolfram
UndefKind[Greek]
DefKind[Greek, Alphabet["Greek"]]   (* UndefKind 후 재정의 가능 *)
```

### Kind 속성 설정

Kind를 정의한 후 차원, 좌표계, 시그니처를 설정한다. 이 세 가지는 독립적이므로 필요한 것만 설정하면 된다.

```wolfram
(* 차원 설정 *)
SetDimension[4, Greek]

(* 좌표계 설정 — 좌표 개수가 차원과 일치해야 한다 *)
SetCoordinates[{t, r, \[Theta], \[Phi]}, Greek]

(* 메트릭 시그니처 설정 — 음의 고유값 개수 *)
SetSig[1, Greek]
```

`DefaultKind`에 대해서는 Kind 인자를 생략할 수 있다.

```wolfram
SetDimension[4]             (* Latin에 적용 *)
SetCoordinates[{t, x, y, z}]
SetSig[1]
```

차원을 기호 값으로 설정해야 하는 경우(예: 일반 차원 $n$)에는 직접 대입한다.

```wolfram
GetDimension[Greek] = n;
```

---

## 3. 여러 Kind를 동시에 사용하는 워크플로

일반 상대론에서 게이지 이론이나 Kaluza-Klein 이론을 다룰 때, 시공간 인덱스와 내부 공간 인덱스를 구분해야 한다. mGRG에서는 여러 Kind를 정의하여 이를 처리한다.

### 예제: 시공간 + 게이지 군 인덱스

```wolfram
(* 1. 패키지 로딩 *)
<< mGRG`STensor`

(* 2. Greek Kind 정의 — 시공간 인덱스 *)
DefKind[Greek, Alphabet["Greek"]]
SetDimension[4, Greek]
SetCoordinates[{t, r, \[Theta], \[Phi]}, Greek]
SetSig[1, Greek]

(* 3. Capital Kind 정의 — 게이지 군 인덱스 *)
DefKind[Capital, ToUpperCase /@ Alphabet[], 3]

(* 4. 인덱스 확인 *)
GetIndices[Greek]
(* {l\[Alpha], l\[Beta], ..., u\[Alpha], u\[Beta], ...} *)

GetIndices[Capital]
(* {lA, lB, lC, ..., lZ, uA, uB, ..., uZ} *)

(* 5. 인덱스의 Kind 질의 *)
IndexToKind[l\[Mu]]
(* Greek *)

IndexToKind[lA]
(* Capital *)

(* 6. Kind 호환성 검사 *)
KindMatchQ[Greek, Capital]
(* False — 서로 다른 Kind는 호환되지 않는다 *)

KindMatchQ[All, Greek]
(* True — All은 모든 Kind와 호환 *)
```

이 설정 후에 텐서를 정의할 때 각 인덱스의 Kind를 자연스럽게 구분할 수 있다.

```wolfram
(* 시공간 벡터 *)
DefTensor[v[l\[Alpha]]]

(* 게이지 장 — 시공간 인덱스 + 게이지 인덱스 *)
DefTensor[A[l\[Mu], lA]]
```

### Kind 필터링

`KindIndexQ`를 사용하면 특정 Kind의 인덱스만 선별할 수 있다. 이 함수는 순수 함수를 반환하므로 `Select`, `TakePairs` 등과 조합하여 사용한다.

```wolfram
idxL = {l\[Alpha], l\[Beta], lA, lB, u\[Alpha], uA}

Select[idxL, KindIndexQ[Greek]]
(* {l\[Alpha], l\[Beta], u\[Alpha]} *)

(* Greek Kind의 아래 첨자만 선별 *)
Select[idxL, KindIndexQ[Greek][#] && DnIndexQ[#] &]
(* {l\[Alpha], l\[Beta]} *)

(* TakePairs에서 특정 Kind만 대상으로 쌍 찾기 *)
TakePairs[idxL, IndexQs -> {KindIndexQ[Greek]}]
(* {{l\[Alpha], u\[Alpha]}} *)
```

---

## 4. 인덱스 조작

### 더미 인덱스 생성

수축(contraction) 연산을 수행할 때는 `NewDummy`로 고유한 더미 인덱스 쌍을 생성한다. 매번 호출할 때마다 새로운 인덱스가 생성되므로 충돌이 없다.

```wolfram
NewDummy[Latin]
(* {lLatin$34127, uLatin$34127} *)

NewDummy[Latin]
(* {lLatin$34128, uLatin$34128} — 항상 다른 번호 *)

NewDummy[Greek]
(* {lGreek$34129, uGreek$34129} *)
```

생성된 더미 인덱스는 `DummyIndexQ`로 확인할 수 있다.

```wolfram
{dn, up} = NewDummy[Latin];
{DummyIndexQ[dn], RegularIndexQ[dn], TensorialIndexQ[dn]}
(* {True, False, True} *)
```

### 인덱스 문자 변경과 추가

기존 Kind의 인덱스 문자를 변경하거나 추가할 수 있다.

**`SetIndices`**: 기존 인덱스를 완전히 교체한다. **주의**: 해당 `l*/u*` 심볼에 할당된 기존 값이 모두 삭제된다.

```wolfram
(* Latin Kind의 인덱스를 a, b, c만 남기기 *)
SetIndices[{"a", "b", "c"}, Latin]
GetIndices[Latin]
(* {la, lb, lc, ua, ub, uc} *)

(* 원래대로 복구 *)
SetIndices[Alphabet[], Latin]
```

**`AddIndices`**: 기존 인덱스를 유지하면서 새 문자를 추가한다.

```wolfram
DefKind[Capital, {"A", "B"}]
AddIndices[{"C", "D", "E"}, Capital]
GetIndices[Capital]
(* {lA, lB, lC, lD, lE, uA, uB, uC, uD, uE} *)
```

**`DropIndices`**: 특정 문자를 Kind에서 제거한다.

```wolfram
DropIndices[{"D", "E"}, Capital]
GetIndices[Capital]
(* {lA, lB, lC, uA, uB, uC} *)
```

> **주의**: `SetIndices`를 호출하면 해당 심볼(`la`, `ua` 등)의 `DownValues`, `UpValues` 등이 초기화된다. 텐서 정의나 규칙을 설정한 후에는 함부로 호출하지 않는 것이 좋다.

### 인덱스 유효성 검사

`ValidIndexQ`를 사용하면 인덱스가 특정 Kind에서 유효한지 확인할 수 있다.

```wolfram
(* DefaultKind(Latin) 기준으로 검사 *)
indexL = {-1, la, lA, 1, ua, uA, laa, uaa}
ValidIndexQ /@ indexL
(* {True, True, False, True, True, False, False, False} *)
```

`lA`는 Capital Kind의 인덱스이므로 `DefaultKind`(Latin) 기준으로는 유효하지 않다. `All`을 사용하면 Kind에 무관하게 형식만 검사한다.

```wolfram
Select[indexL, ValidIndexQ[#, All] &]
(* {-1, la, lA, 1, ua, uA} *)
```

`ValidIndicesQ`는 리스트 전체에 대해 유효성과 중복 여부를 동시에 검사한다.

```wolfram
ValidIndicesQ[{la, lb, uc}]
(* True *)

ValidIndicesQ[{la, la, ub}]
(* False — la가 중복 *)
```

---

## 5. 1D Kind와 특수 Kind

### 1차원 Kind

인덱스 문자가 한 개인 Kind는 `OneDimKindQ`를 만족한다. 1D Kind의 특징은 더미 인덱스가 별도로 생성되지 않고 정규 인덱스와 동일하다는 점이다.

```wolfram
DefKind[Zero, {"0"}]

OneDimKindQ[Zero]
(* True *)

NewDummy[Zero]
(* {l0, u0} — 정규 인덱스와 동일 *)
```

1D Kind에서는 `PairIndexQ`가 항상 `False`를 반환한다. 1차원이므로 수축 연산이 의미가 없기 때문이다.

```wolfram
PairIndexQ[l0, u0]
(* False *)
```

### 기호가 붙는 Kind

mGRG에서는 '접두사로 꾸며진 인덱스'로 출력하는 Kind를 정의할 수 있다.

| Kind 이름 | 접두사 규칙 | 인덱스 예시 |
|-----------|------------|-----------|
| BarLatin | `"b" <> char` | `lba`, `uba`, `lbb`, `ubb`, ... |
| DotLatin | `"d" <> char` | `lda`, `uda`, `ldb`, `udb`, ... |
| HatLatin | `"h" <> char` | `lha`, `uha`, `lhb`, `uhb`, ... |

이러한 Kind는 일반적인 `DefKind` 호출로 정의한다.

```wolfram
(* Bar가 붙은 라틴 인덱스 *)
DefKind[BarLatin, "b" <> # & /@ Alphabet[]]
SetDimension[4, BarLatin]

GetIndices[BarLatin]
(* {lba, lbb, lbc, ..., lbz, uba, ubb, ubc, ..., ubz} *)

IndexToKind[lba]
(* BarLatin *)
```

### (3+1) 분해를 위한 Kind 설정 예제

시공간을 시간 방향과 공간 방향으로 분해하는 (3+1) ADM 형식론에서는 여러 Kind가 필요하다.

```wolfram
<< mGRG`STensor`

(* 4차원 시공간: Latin Kind (기본) *)
SetDimension[4]
SetCoordinates[{t, x, y, z}]
SetSig[1]

(* 시간 방향: 1D Kind *)
DefKind[Zero, {"0"}]

(* 3차원 공간: HatLatin Kind *)
DefKind[HatLatin, "h" <> # & /@ Alphabet[]]
SetDimension[3, HatLatin]
SetCoordinates[{x, y, z}, HatLatin]
SetSig[0, HatLatin]

(* 확인 *)
OneDimKindQ[Zero]
(* True *)

GetDimension[HatLatin]
(* 3 *)

IndexToKind[l0]
(* Zero *)

IndexToKind[lha]
(* HatLatin *)
```

이 설정으로 4차원 텐서를 시간 성분과 공간 성분으로 분리하여 다룰 수 있다.

---

## 6. Show[kind]로 현재 설정 확인

`Show[kind]`를 호출하면 해당 Kind의 현재 상태를 테이블 형태로 확인할 수 있다.

```wolfram
SetDimension[4]
SetSig[1]
SetCoordinates[{t, r, \[Theta], \[Phi]}]

Show[DefaultKind]
(*
AutoFlag          False
MarkErrorFlag     True
...
Kind              Latin
Dimension         4
Sig               1
Coordinates       t, r, \[Theta], \[Phi]
CoordinateBasisQ  True
*)
```

`DefaultKind`에 대해 호출하면 전역 플래그 설정(`AutoFlag`, `MarkErrorFlag` 등)도 함께 표시된다. 일반 Kind에 대해서는 해당 Kind의 속성만 표시된다.

```wolfram
Show[Greek]
(*
Kind              Greek
Dimension         4
Sig               1
Coordinates       t, r, \[Theta], \[Phi]
CoordinateBasisQ  True
*)
```

여러 Kind를 동시에 사용할 때는 각 Kind의 `Show`를 호출하여 설정이 올바른지 확인하는 것이 좋다.

---

## 요약: 인덱스 설정 워크플로

전형적인 인덱스 설정 순서를 정리하면 다음과 같다.

```wolfram
(* 1. 패키지 로딩 *)
<< mGRG`STensor`

(* 2. DefaultKind(Latin) 설정 *)
SetDimension[4]
SetCoordinates[{t, r, \[Theta], \[Phi]}]
SetSig[1]

(* 3. 추가 Kind 정의 (필요한 경우) *)
DefKind[Greek, Alphabet["Greek"]]
SetDimension[4, Greek]

DefKind[Capital, ToUpperCase /@ Alphabet[], 3]

(* 4. 설정 확인 *)
Show[DefaultKind]
Show[Greek]
Show[Capital]

(* 5. 텐서 정의로 진행 *)
DefTensor[v[la]]
DefTensor[F[la, lb], "-ba"]
```

핵심 원칙:

1. **`DefKind`는 `SetIndices`를 포함한다** -- 별도로 `SetIndices`를 호출하지 않는다.
2. **`DefaultKind` 인자 생략** -- Kind를 지정하지 않으면 항상 `DefaultKind`(기본값: `Latin`)가 사용된다.
3. **`SetIndices` 호출 시 기존 값이 삭제된다** -- 텐서 정의 후에는 주의해서 사용한다.
4. **1D Kind는 특별하다** -- 더미 인덱스가 정규 인덱스와 동일하고, `PairIndexQ`가 항상 `False`이다.
5. **`Show[kind]`로 확인** -- 설정이 올바른지 항상 확인한다.

---

> 자세한 함수 시그니처와 옵션은 `02-Indices.md` 및 `03-Kind.md` 참고.
