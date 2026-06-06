# Tech Note: 텐서와 연산자 정의 (Defining Tensors and Operators)

> 자세한 함수 설명은 `04-IndexedObjects.md` 및 `05-Operators.md` 참고

이 Tech Note는 mGRG의 STensor 모듈에서 텐서, 연산자, 기타 인덱스 객체를 정의하고 사용하는
전체 워크플로를 안내한다. Kind 설정부터 텐서 정의, 대칭성 지정, 연산자 정의, 속성 확인까지
연결된 예제를 통해 설명한다.

---

## 1. 인덱스 객체의 계층 구조

STensor에서 다루는 모든 객체는 다음 계층 구조를 따른다.

```
Object -----+-- IndexedObject ----+-- IndexedOperand ---+-- IndexedTensor (텐서)
            |                     |                     +-- DiffForm (미분 형식)
            |                     +-- IndexedOperator (연산자: CD, LD, XD, XP)
            +-- ScalarFunction (스칼라 함수: Tscalar, Sin, Log, ...)
```

각 수준에 대응하는 질의 함수(predicate)가 있다.

| 질의 함수              | 대상                                         |
| ------------------ | ------------------------------------------ |
| `ObjectQ`          | 모든 정의된 객체 (IndexedObject + ScalarFunction) |
| `IndexedObjectQ`   | 인덱스를 갖는 객체 (텐서 + 연산자 + 미분 형식)              |
| `IndexedOperandQ`  | 피연산자 (텐서 + 미분 형식)                          |
| `IndexedTensorQ`   | 텐서                                         |
| `DiffFormQ`        | 미분 형식                                      |
| `IndexedOperatorQ` | 연산자 (CD, LD 등)                             |
| `ScalarFunctionQ`  | 스칼라 함수 (Sin, Cos, Log, Tscalar 등)          |

이 질의 함수들은 `HeadQs` 옵션을 통해 특정 종류의 객체만 선택적으로 대상으로 지정하는 데
사용할 수 있다.

```wolfram
(* 텐서만 대상으로 전개 *)
ExpandObject[expr, HeadQs -> {IndexedTensorQ}]

(* 연산자가 없는 항인지 검사 *)
FreeObjectQ[expr, HeadQs -> {IndexedOperatorQ}]
```

---

## 2. 텐서 정의 워크플로

### 2.1 환경 설정

텐서를 정의하기 전에 패키지를 로드하고 Kind를 설정해야 한다.

```wolfram
<< mGRG`STensor`
```

패키지 로드 시 `Latin` Kind가 자동으로 `DefaultKind`로 설정되며,
라틴 소문자 인덱스(`la`, `lb`, `lc`, ..., `ua`, `ub`, `uc`, ...)를 바로 사용할 수 있다.

추가 Kind가 필요하면 `DefKind`로 정의한다.

```wolfram
(* 그리스 문자 Kind 정의 *)
DefKind[Greek, Alphabet["Greek"]]

(* 대문자 Kind 정의 (차원 함께 지정) *)
DefKind[Capital, {"A", "B", "C", "D", "E", "F"}, 6]
```

`DefKind`는 내부적으로 `SetIndices`를 호출한다.

차원을 명시적으로 설정한다.

```wolfram
SetDimension[4]          (* DefaultKind (Latin)의 차원 *)
SetDimension[4, Greek]   (* Greek Kind의 차원 *)
```

### 2.2 스칼라 (Rank 0)

인덱스가 없는 랭크-0 텐서를 정의한다.

```wolfram
DefTensor[f[]]
f[]
(* f *)

(* 출력 이름 지정 *)
DefTensor[scR[], PrintAs -> "R"]
scR[]
(* R *)
```

`Tdefine`은 `DefTensor`의 별칭이다. 동일하게 사용할 수 있다.

```wolfram
Tdefine[phi[], PrintAs -> "\[CurlyPhi]"]
phi[]
(* phi *)
```

### 2.3 벡터 (Rank 1)

인덱스 하나를 갖는 벡터를 정의한다.

```wolfram
(* 공변 벡터 — 인덱스 shape 명시 *)
DefTensor[v[la], "a"]
v[la]
(* v_a *)

v[ua]
(* v^a *)
```

인덱스 shape을 생략하고 rank 숫자로 지정할 수도 있다. 이 경우 모든 인덱스가
`DefaultKind`의 아래 첨자로 설정된다.

```wolfram
(* rank 숫자로 지정 + 출력 이름 *)
Tdefine[xi, 1, PrintAs -> "\[Xi]"]
xi[la]
(* xi_a *)
```

### 2.4 2계 텐서와 대칭성

대칭 문자열로 인덱스의 교환 대칭을 설정한다.

```wolfram
(* 대칭 — "ba"는 1<->2 교환 시 부호 + (기본값) *)
DefTensor[h[la, lb], "ba"]
(* 또는 명시적으로 *)
DefTensor[h[la, lb], "+ba"]

(* 반대칭 — "-ba"는 1<->2 교환 시 부호 - *)
DefTensor[F[la, lb], "-ba"]

(* 대칭 없음 — 알파벳 순서 "ab"는 항등 순열 *)
DefTensor[T[la, lb], "ab"]
```

### 2.5 고계 텐서와 복합 대칭

여러 대칭 생성원을 이어붙여 복합 대칭을 지정한다.

```wolfram
(* 리만 텐서: R_{abcd} *)
DefTensor[CurvR, 4, "-bacd-abdc+cdab", PrintAs -> "R"]
```

이 대칭 문자열의 의미는 다음과 같다.

| 생성원 | 순열 | 부호 | 의미 |
|--------|------|------|------|
| `"-bacd"` | 1<->2 | -1 | 첫째-둘째 인덱스 반대칭 |
| `"-abdc"` | 3<->4 | -1 | 셋째-넷째 인덱스 반대칭 |
| `"+cdab"` | (12)<->(34) | +1 | 앞 쌍과 뒷 쌍 교환 대칭 |

### 2.6 임의 Rank 텐서

rank를 고정하지 않는 텐서도 정의할 수 있다.

```wolfram
(* 임의 rank, 대칭 없음 *)
DefTensor[S, "*"]
{S[], S[la], S[la, ub], S[la, ub, lc]}
(* {S, S_a, S_a^b, S_a^b_c} *)

(* 임의 rank, 완전 대칭 *)
DefTensor[Sym, "*+"]

(* 임의 rank, 완전 반대칭 *)
DefTensor[Anti, "*-"]
```

고정 rank에서도 완전 대칭/반대칭을 지정할 수 있다.

```wolfram
DefTensor[W, "4+"]   (* rank 4, 완전 대칭 *)
DefTensor[A, "3-"]   (* rank 3, 완전 반대칭 *)
```

---

## 3. 대칭 문자열 체계

대칭 문자열은 인덱스 순열을 알파벳으로 인코딩한 것이다.

### 3.1 기본 규칙

- 알파벳 순서가 인덱스 위치를 나타낸다: `a`=1번, `b`=2번, `c`=3번, `d`=4번, ...
- `"abc..."` (알파벳 순서)는 항등 순열 = 대칭 없음
- `+` 접두사: 해당 순열에 대해 대칭 (부호 +1). `+`는 생략 가능
- `-` 접두사: 해당 순열에 대해 반대칭 (부호 -1)
- 여러 대칭 생성원을 이어붙임: `"-bacd-abdc+cdab"`

### 3.2 대칭 문자열과 GenSet의 관계

대칭 문자열은 내부적으로 `GenSet`(생성원 집합)의 `CyclesPhased` 표현으로 변환된다.

| 대칭 문자열 | GenSet 표현 | 의미 |
|-------------|------------|------|
| `"ab"` | `GenSet[]` | 대칭 없음 |
| `"+ba"` 또는 `"ba"` | `GenSet[{Cycles[{{1,2}}], 1}]` | 1<->2 대칭 |
| `"-ba"` | `GenSet[{Cycles[{{1,2}}], -1}]` | 1<->2 반대칭 |
| `"+bac"` | `GenSet[{Cycles[{{1,2}}], 1}]` | 1<->2 대칭 (3은 고정) |
| `"-bac-acb"` | `GenSet[{Cycles[{{1,2}}], -1}, {Cycles[{{2,3}}], -1}]` | 인접 쌍들 반대칭 |

### 3.3 특수 표현

| 문자열 | 의미 |
|--------|------|
| `"*"` | 임의 rank, 대칭 없음 |
| `"*+"` | 임의 rank, 완전 대칭 |
| `"*-"` | 임의 rank, 완전 반대칭 |
| `"4"` | rank 4, 대칭 없음 |
| `"4+"` | rank 4, 완전 대칭 |
| `"4-"` | rank 4, 완전 반대칭 |

### 3.4 순열 확인

`AllPermutations`로 대칭 생성원이 만들어내는 모든 순열과 부호를 확인할 수 있다.

```wolfram
AllPermutations["-ba"]
(* "+ab-ba" *)

AllPermutations["+ba"]
(* "+ab+ba" *)

(* 리만 텐서의 대칭 — 8개 순열 *)
AllPermutations["-bacd-abdc+cdab"]
(* "+abcd-abdc-bacd+badc+cdab-cdba-dcab+dcba" *)
```

---

## 4. 혼합 Kind 텐서

여러 Kind의 인덱스를 갖는 텐서를 정의할 수 있다. 이 경우 인덱스 shape을
명시적으로 지정해야 한다.

```wolfram
(* Greek 아래 첨자 + Greek 위 첨자 + Latin 위 첨자 *)
DefTensor[YMF[lmu, lnu, ua], "-bac", PrintAs -> "F"]
YMF[lmu, lnu, ua]
(* F_mu nu^a *)
```

대칭 설정은 **같은 Kind, 같은 위/아래(up/down)** 사이에서만 가능하다. 위 예에서
`"-bac"`의 1<->2 반대칭은 첫째(Greek 아래 첨자)와 둘째(Greek 아래 첨자) 사이에 적용되며,
셋째(Latin 위 첨자)와는 교환 대칭이 불가하다.

### 4.1 속성 조회

```wolfram
(* Kind 조회 *)
{KindOf[YMF, 1], KindOf[YMF, 2], KindOf[YMF, 3]}
(* {Greek, Greek, Latin} *)

(* 위/아래 상태 조회 *)
{DnupAt[YMF, 1], DnupAt[YMF, 2], DnupAt[YMF, 3]}
(* {-1, -1, 1} *)

(* rank 조회 *)
GetRank[YMF]
(* 3 *)
```

양-밀스 게이지 이론의 더 완전한 예를 보면 다음과 같다.

```wolfram
DefKind[Greek, Alphabet["Greek"]]
SetDimension[4, Greek]

(* 게이지 퍼텐셜: A_mu^a *)
Tdefine[YMA[lmu, ua], PrintAs -> "A"]

(* 필드 텐서: F_mu nu^a (mu <-> nu 반대칭) *)
Tdefine[YMF[lmu, lnu, ua], "-bac", PrintAs -> "F"]

(* 구조 상수: f_ab^c (a <-> b 반대칭) *)
Tdefine[fabc[la, lb, uc], "-bac", PrintAs -> "f"]
```

---

## 5. 연산자 정의

STensor는 네 가지 타입의 연산자를 지원한다.

| 타입   | 의미     | 인자 구조                   | 예                                   |
| ---- | ------ | ----------------------- | ----------------------------------- |
| `CD` | 공변 도함수 | `op[index, expr]`       | `CD[la, T[ub]]` = nabla_a T^b       |
| `LD` | 리 도함수  | `op[vector, expr]`      | `LD[v, T[ub]]` = L_v T^b            |
| `XD` | 외미분    | `op[expr]`              | `XD[omega]` = d omega               |
| `XP` | 외적     | `op[expr1, expr2, ...]` | `XP[omega, sigma]` = omega /\ sigma |

### 5.1 사전 정의된 연산자

패키지 로드 시 다음 연산자가 자동으로 정의된다.

- **`CD`**: 기본 공변 도함수. `DefaultKind`에 속한다.
- **`BD`**: 기저 도함수(편미분). Kind는 `All`이다.
- **`LD`**: 리 도함수. Kind는 첫 번째 인자(벡터)의 Kind에 따른다.

```wolfram
(* 공변 도함수 *)
CD[la, T[ub]]
(* nabla_a T^b *)

CD[ua, Metricg[lb, lc]]
(* 0  — 메트릭 호환 *)

(* 기저 도함수 *)
BD[la, T[ub]]
(* partial_a T^b *)

(* 리 도함수 *)
DefTensor[v[la], "a"]
LD[v, T[ua, ub]]
(* L_v T^ab *)
```

**주의**: `LD[v, expr]`에서 `expr`에 `BD`가 포함되면 올바르게 동작하지 않는다.
사용 전에 `FreeQ[expr, BD]`로 확인할 것.

### 5.2 사용자 도입 연산자

`mGRG`STensor`Private`defineOperator`로 새로운 연산자 기호을 도입할 수 있다.

```wolfram
(* CD 타입 — 공변 도함수형 *)
mGRG`STensor`Private`defineOperator[CovD, "\[Del]", CD]
CovD[la, T[ua, ub]]
(* Del_a T^ab *)
```

CD 타입은 Kind를 지정할 수 있다. Kind를 지정하지 않으면 `DefaultKind`가 사용된다.

```wolfram
(* 특정 Kind의 공변 도함수 *)
mGRG`STensor`Private`defineOperator[DCap, "D", CD, Capital]
DCap[lA, T[uB, uC]]
(* D_A T^BC *)
```

LD 타입 연산자 기호을 도입한다.

```wolfram
(* LD 타입 — 리 도함수형 *)
mGRG`STensor`Private`defineOperator[LieD, "\[ScriptCapitalL]", LD]
Tdefine[xi, 1, PrintAs -> "\[Xi]"]
LieD[xi, T[ua, ub]]
(* L_xi T^ab *)
```

XD 타입과 XP 타입의 연산자 기호을 도입한다.

```wolfram
(* XD 타입 — 외미분형 *)
mGRG`STensor`Private`defineOperator[extD, "d", XD]
extD[omega[la]]
(* d omega_a *)

(* XP 타입 — 외적형 *)
mGRG`STensor`Private`defineOperator[wedge, "\[Wedge]", XP]
```

새로 도입한 연산자는 `IndexedOperatorQ`가 `True`가 되고, 기본적인 입출력 형태가 설정된다.
그러나 그 연산자가 실제 연산을 하는 방법은 *따로이* 코딩해야 한다.

```wolfram
IndexedOperatorQ /@ {CovD, LieD, extD, wedge}
(* {True, True, True, True} *)
```


---

## 6. 미리 정의된 특수 객체

STensor는 다음 특수 객체를 자동으로 정의한다.

### 6.1 크로네커 델타 (`Kdelta`)

```wolfram
KindOf[Kdelta]
(* All *)

Kdelta[la, ub]
(* delta_a^b *)

(* 성분 인덱스를 넣으면 KroneckerDelta로 평가 *)
Kdelta[1, -1]
(* 1 *)

Kdelta[1, -2]
(* 0 *)
```

`Kdelta`의 Kind는 `All`이므로 모든 Kind의 인덱스에서 사용할 수 있다.
`KdeltaFlag`가 `On`(기본값)이면 인덱스 축약이 자동 수행된다.

### 6.2 메트릭 텐서 (`Metricg`)

`DefaultKind`의 계량은 `Metricg`이고, 대칭 텐서이다.

```wolfram
Metricg[la, lb]
(* g_ab *)

Metricg[ua, ub]
(* g^ab *)

(* 공변 도함수와 호환: 메트릭의 공변 도함수는 0 *)
CD[la, Metricg[lb, lc]]
(* 0 *)
```

### 6.3 레비-치비타 텐서 (`Epsilon`)

```wolfram
(* DefaultKind *)
SetDimension[4]
Epsilon[la, lb, lc, ld]
(* epsilon_abcd *)

(* 다른 Kind의 Epsilon *)
GetEpsilon[Greek]
(* EpsilonGreek  -- Greek Kind가 정의되었을 때 *)
```

완전 반대칭이며, `CD[index, Epsilon[...]] = 0`이다.

### 6.4 스칼라 래퍼 (`Tscalar`)

인덱스 객체로 구성된 표현식을 스칼라로 다루기 위한 래퍼이다.

```wolfram
Tscalar[T[la, lb] * T[ua, ub]]
(* (T_ab T^ab) *)

(* 거듭제곱은 먼저 Tscalar로 감싸야 함 *)
Tscalar[T[la, lb] * T[uc, ud]]^2
(* (T_ab T^cd)^2 *)

(* 스칼라 함수와 상수는 자동 추출 *)
Sinh[Tscalar[f[] T[la, lb] * T[ua, ub]]]
(* Sinh[f (T_ab T^ab)] *)
```

### 6.5 에러 래퍼 (`ErrorT`)

프로그램 동작 중 오류가 발견되면 자동으로 감싸지며, 빨간색으로 표시된다.

```wolfram
ErrorT[T[la, lb]]
(* T_ab  — 빨간색으로 표시 *)
```

---

## 7. 객체 속성 조회

### 7.1 기본 속성

```wolfram
DefTensor[R, 4, "-bacd-abdc+cdab", PrintAs -> "R"]

(* rank *)
GetRank[R]
(* 4 *)

(* 위/아래 상태: -1=아래 첨자, +1=위 첨자 *)
{DnupAt[R, 1], DnupAt[R, 2], DnupAt[R, 3], DnupAt[R, 4]}
(* {-1, -1, -1, -1} *)

(* Kind *)
{KindOf[R, 1], KindOf[R, 2], KindOf[R, 3], KindOf[R, 4]}
(* {Latin, Latin, Latin, Latin} *)
```

### 7.2 대칭성 조회 및 변경

```wolfram
(* 대칭성 GenSet 조회 *)
GetSymmetry[R]
(* GenSet[{Cycles[{{1,2}}], -1}, {Cycles[{{3,4}}], -1}, {Cycles[{{1,3},{2,4}}], 1}] *)

(* GenSet을 문자열로 변환 *)
GStoString[GetSymmetry[R], GetRank[R]]
(* "-bacd-abdc+cdab" *)

(* 모든 순열 확인 *)
AllPermutations["-bacd-abdc+cdab"]
(* "+abcd-abdc-bacd+badc+cdab-cdba-dcab+dcba" *)
```

인덱스 대칭을 나중에 변경할 수도 있다.

```wolfram
DefTensor[T[la, lb, lc], "abc"]  (* 대칭 없음 *)
GetSymmetry[T]
(* GenSet[] *)

SetSymmetry[T, "-bac"]           (* 1<->2 반대칭으로 변경 *)
GetSymmetry[T]
(* GenSet[{Cycles[{{1,2}}], -1}] *)
```

### 7.3 객체 제거

```wolfram
DefTensor[temp[la, lb], "-ba"]
IndexedTensorQ[temp]
(* True *)

RemoveIndexedObject[temp]
IndexedTensorQ[temp]
(* False *)
```

`RemoveIndexedObject`는 메모리에서 그 객체를 제거한다. 따라서 예약된 이름(`Metricg`, `Kdelta`, `Epsilon`, `CD` 등)에는
작동하지 않는다. `UndefTensor`는 정의된 텐서 객체의 속성을 제거한다.

---

## 8. 완전한 워크플로 예제

전자기학에서 사용하는 텐서들을 정의하고 조작하는 전체 워크플로이다.

```wolfram
(* ===== 1. 패키지 로드 ===== *)
<< mGRG`STensor`

(* ===== 2. 환경 설정 ===== *)
SetDimension[4]
SetSig[1]                            (* 시그니처 (-,+,+,+) *)
SetCoordinates[{t, x, y, z}]

(* ===== 3. 텐서 정의 ===== *)

(* 전자기 텐서 F_ab (반대칭) *)
DefTensor[Fem[la, lb], "-ba", PrintAs -> "F"]

(* 벡터 퍼텐셜 A_a *)
DefTensor[Apot[la], "a", PrintAs -> "A"]

(* 전류 밀도 J^a *)
DefTensor[Jcur[ua], "a", PrintAs -> "J"]

(* 스칼라장 phi *)
DefTensor[phi[]]

(* ===== 4. 속성 확인 ===== *)

GetRank[Fem]                         (* 2 *)
GetSymmetry[Fem]                     (* GenSet[{Cycles[{{1,2}}], -1}] *)
AllPermutations["-ba"]               (* "+ab-ba" *)

IndexedTensorQ /@ {Fem, Apot, Jcur, phi}
(* {True, True, True, True} *)

(* ===== 5. 텐서 표현식 ===== *)

(* 공변 도함수 *)
CD[la, Fem[lb, lc]]
(* nabla_a F_bc *)

(* 리 도함수 *)
DefTensor[xi, 1, PrintAs -> "\[Xi]"]
LD[xi, Fem[la, lb]]
(* L_xi F_ab *)

(* 스칼라 래핑 *)
Tscalar[Fem[la, lb] * Fem[ua, ub]]
(* (F_ab F^ab) *)

(* ===== 6. 정리 ===== *)
UndefTensor /@ {Fem, Apot, Jcur, phi, xi}
```

---

## 9. 요약

줄임말: SP = mGRG`STensor`Private`

| 작업               | 함수                                           | 예                                   |
| ---------------- | -------------------------------------------- | ----------------------------------- |
| Kind 정의          | `DefKind`                                    | `DefKind[Greek, Alphabet["Greek"]]` |
| 차원 설정            | `SetDimension`                               | `SetDimension[4]`                   |
| 텐서 정의 (shape 명시) | `DefTensor` / `Tdefine`                      | `DefTensor[F[la, lb], "-ba"]`       |
| 텐서 정의 (rank 숫자)  | `DefTensor` / `Tdefine`                      | `DefTensor[T, 3]`                   |
| 연산자 정의           | `SP`defineOperator`                          | `SP`defineOperator[D, "D", CD]`     |
| 속성 조회            | `GetRank`, `GetSymmetry`, `KindOf`, `DnupAt` | `GetRank[T]`                        |
| 대칭성 변경           | `SetSymmetry`                                | `SetSymmetry[T, "+ba"]`             |
| 순열 확인            | `AllPermutations`                            | `AllPermutations["-ba"]`            |
| 객체 제거            | `RemoveIndexedObject` / `UndefTensor`        | `RemoveIndexedObject[T]`            |
| 타입 판별            | `ObjectQ`, `IndexedTensorQ`, ...             | `IndexedTensorQ[T]`                 |
