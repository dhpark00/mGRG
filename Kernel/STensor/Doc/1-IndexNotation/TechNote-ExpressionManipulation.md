# Tech Note: 텐서 표현식 조작 (Manipulating Tensor Expressions)

mGRG의 STensor 모듈은 텐서 표현식을 자동으로 전개하고, 인덱스를 탐색하며,
대칭화와 더미 인덱스 처리를 수행하는 도구를 제공한다.
이 Tech Note에서는 표현식 조작의 전체 워크플로를 다룬다:
설정, 표현식 작성, 전개, 인덱스 조작, 더미 처리, 구문 검증 순서로 진행한다.

> 자세한 함수 설명은 `06-ExpressionUtils.md`, `07-IndexOperations.md`, `08-SyntaxAndFlags.md` 참고.

---

## 1. 텐서 표현식의 자동 처리

mGRG는 Mathematica의 `$Post` 메커니즘을 통해 모든 출력을 자동으로 후처리한다.
사용자는 대부분 이 과정을 의식하지 않지만, 성능 최적화나 디버깅을 위해
내부 동작을 이해하고 제어할 수 있어야 한다.

### 자동 처리 파이프라인

`AutoFlag`가 `On`이면(기본값), 매 출력마다 내부 함수 `postEval`이 실행된다.
처리 순서는 다음과 같다:

```
출력 표현식
    |
    v
[1] SyntaxCheckFlag == On ?  -->  SyntaxCheck 실행
    |                             오류 발견 시 ErrorT로 감싸서 즉시 반환
    v
[2] ExpandObject 실행         -->  인덱스 객체를 포함하는 곱 표현식을 전개
    |
    v
[3] 각 항(term)마다:
    |-- MarkErrorFlag == Off ?  -->  ErrorT -> Identity (오류 표시 제거)
    |-- ResetDummiesFlag == On ?  -->  ResetDummies (더미 인덱스 정규화)
    |
    v
최종 출력
```

`postEval`은 패턴 객체가 없고(`FreePatternQ`), 인덱스 객체가 포함된 표현식에만 동작한다.
일반 수식이나 문자열 등에는 영향을 주지 않는다.

### 실질적 의미

따라서 사용자가 `(R[la, lc] + F[la, lc]) v[uc]`를 입력하면,
자동으로 `R[la, lb] v[ub] + F[la, lb] v[ub]`로 전개되고
더미 인덱스도 정규 순서(`la`, `lb`, `lc`, ...)로 재배치된다.

---

## 2. 텐서 표현식 전개와 분석

### 설정

이 Tech Note의 모든 예제는 다음 설정을 전제한다:

```wolfram
<< mGRG`STensor`

(* 텐서 정의 *)
Tdefine[R, "ba"]                        (* 대칭 텐서 R_{ab} = R_{ba} *)
Tdefine[F, "-ba"]                       (* 반대칭 텐서 F_{ab} = -F_{ba} *)
Tdefine[scR[], PrintAs -> "\[ScriptCapitalR]"]  (* 스칼라 텐서 *)
Tdefine[v, 1]                           (* 벡터 v_a *)

(* 공변 도함수 연산자 정의 *)
defineOperator[CovD, "\[Del]", CD]      (* CovD = nabla *)
```

`Tdefine`(별칭: `DefTensor`)은 텐서의 이름, 대칭성, Kind를 등록한다.
`defineOperator`는 STensor 모듈의 내부 함수로 CD 타입의 공변 도함수 연산자를 정의한다.

### ExpandObject: 텐서 곱의 전개

`ExpandObject`는 인덱스 객체를 포함하는 곱을 합으로 분배한다.
일반적인 `Expand`와 달리, 인덱스 구조를 보존하면서 전개한다.

```wolfram
expr = (a + b) (CovD[lc, R[la, lb]] + CovD[lc, F[la, lb]]) * (R[ua, ub] + F[ua, ub]) * scR[]

ExpandObject[expr]
(* --> 8개의 항으로 전개:
       a scR[] CovD[lc, F[la,lb]] F[ua,ub] + a scR[] CovD[lc, R[la,lb]] F[ua,ub] + ... *)
```

### HeadQs 옵션으로 전개 대상 제한

모든 것을 전개할 필요가 없는 경우, `HeadQs` 옵션으로 전개 대상을 제한할 수 있다.

```wolfram
(* 연산자(CovD)만 전개, 텐서 합은 유지 *)
ExpandObject[expr, HeadQs -> {IndexedOperatorQ}]
(* --> (a + b) scR[] CovD[lc, F[la, lb]] (R[ua, ub] + F[ua, ub])
     + (a + b) scR[] CovD[lc, R[la, lb]] (R[ua, ub] + F[ua, ub])  *)
```

`HeadQs`의 기본값은 `{IndexedObjectQ}`이며, 이는 모든 인덱스 객체(텐서와 연산자 모두)를
전개 대상으로 삼는다. `{IndexedOperatorQ}`로 설정하면 연산자 부분만 전개되는 것이다.

### SplitTerm: 항의 분리

항을 `{스칼라부분, 텐서부분}`으로 분리한다.

```wolfram
SplitTerm[a scR[] R[la, lb]]
(* --> {a scR[], R[la, lb]} *)

(* 연산자가 포함된 텐서 부분만 분리 *)
SplitTerm[a R[la, lb] CovD[lc, scR[]], {HeadQs -> {IndexedOperatorQ}}]
(* --> {a R[la, lb], CovD[lc, scR[]]} *)
```

### ForEachTerm과 ForEachObject: 항별/객체별 처리

```wolfram
ForEachTerm[a R[la, lb] + b F[la, lb], func]
(* --> func[a R[la, lb]] + func[b F[la, lb]] *)

ForEachObject[a R[lb, ub] + v[la] v[ua], {}, func]
(* --> a func[R[lb, ub]] + func[v[la]] func[v[ua]] *)
(* 스칼라 계수 a는 인덱스 객체가 아니므로 func가 적용되지 않는다 *)
```

---

## 3. 인덱스 탐색

### FindIndices: 모든 인덱스 찾기

한 개의 항(term)에 나타나는 모든 (Kind에 부합하는) 인덱스를 리스트로 반환한다.

```wolfram
FindIndices[R[la, lb] * F[lc, ud]]
(* --> {la, lb, lc, ud} *)

(* 연산자의 인덱스도 포함 *)
FindIndices[CovD[la, F[ub, lc]]]
(* --> {la, ub, lc} *)
```

`IndexQs` 옵션으로 특정 종류의 인덱스만 필터링할 수 있다:

```wolfram
expr = CovD[la, F[ua, lb]] * R[-1, uc]

FindIndices[expr]
(* --> {la, ua, lb, -1} *)

(* 텐서 인덱스만 (성분 인덱스 -1 제외) *)
FindIndices[expr, IndexQs -> {TensorialIndexQ}]
(* --> {la, ua, lb} *)

(* 피연산자(operand)의 인덱스만 *)
FindIndices[expr, HeadQs -> {IndexedOperandQ}]
(* --> {-1} *)
```

### FindFreeTensorialIndices: 자유 인덱스만 찾기

수축된 더미 인덱스 쌍을 제외하고, 자유(비수축) 텐서 인덱스만 반환한다.

```wolfram
(* 완전히 수축된 표현식 *)
FindFreeTensorialIndices[R[la, lb] * R[ua, ub]]
(* --> {} *)

(* 자유 인덱스가 있는 표현식 *)
FindFreeTensorialIndices[CovD[la, R[lb, lc]]]
(* --> {la, lb, lc} *)

(* 위 인덱스만 필터 *)
expr = CovD[la, F[ua, lb]] * R[-1, uc]
FindFreeTensorialIndices[expr, IndexQs -> {UpIndexQ}]
(* --> {uc} *)
```

### FindIndicesAll / FindFreeTensorialIndicesAll

Kind 유효성 검사 없이 모든 인덱스를 반환하는 버전이다. 여러 Kind가 혼재된 표현식에 유용하다.

```wolfram
expr = CovD[lA, F[ua, lB]] * R[-1, uA]
{FindIndicesAll[expr], FindFreeTensorialIndicesAll[expr]}
(* --> {{lA, ua, lB, -1, uA}, {ua, lB}} *)
```

### NoIndexQ: 스칼라 판별

```wolfram
NoIndexQ /@ {scR[], R[la, lb] R[ua, ub], R[la, lb]}
(* --> {True, True, False} *)
```

---

## 4. 인덱스 대칭화

### AntisymmetrizeIndices: 반대칭화

지정된 인덱스에 대해 반대칭화를 수행한다. 결과에 `1/n!` 계수가 곱해진다.

```wolfram
AntisymmetrizeIndices[F[la, lb], {la, lb}]
(* --> 1/2 (F[la, lb] - F[lb, la]) *)
```

F가 이미 반대칭(`"-ba"`)으로 정의되었으므로, `Tsimplify`를 적용하면
원래 표현으로 돌아온다:

```wolfram
AntisymmetrizeIndices[F[la, lb], {la, lb}] // Tsimplify
(* --> F[la, lb] *)
```

공변 도함수를 포함하는 더 복잡한 표현도 반대칭화할 수 있다:

```wolfram
AntisymmetrizeIndices[CovD[uc, CovD[la, F[ub, lc]]], {la, ub, lc}]
(* --> 1/6 * (3! = 6개 항의 부호 교대 합) *)
```

### SymmetrizeIndices: 대칭화

부호 교대 없이 모든 순열의 합을 취한다.

```wolfram
SymmetrizeIndices[R[la, lb], {la, lb}]
(* --> 1/2 (R[la, lb] + R[lb, la]) *)
```

R이 대칭(`"ba"`)으로 정의되었으므로:

```wolfram
SymmetrizeIndices[R[la, lb], {la, lb}] // Tsimplify
(* --> R[la, lb] *)
```

### HeadQs 옵션의 활용

`ScalarFunction` 안의 인덱스도 대칭화 대상에 포함하려면
`HeadQs -> {ObjectQ}`를 사용한다:

```wolfram
(* 기본: ScalarFunction 내부는 무시 *)
SymmetrizeIndices[Tscalar[R[la, lb] * R[ua, ub]], {la, lb}]
(* --> Tscalar[R[la, lb]]  (경고 메시지. 출력은 변화 없음) *)

(* ObjectQ로 ScalarFunction 내부도 처리 *)
SymmetrizeIndices[Tscalar[R[la, lb] * R[ua, ub]], {la, lb}, HeadQs -> {ObjectQ}]
(* --> 1/2 (Tscalar[R[la, lb] * R[ua, ub]] + Tscalar[R[lb, la] * R[ua, ub]]) *)
```

---

## 5. 더미 인덱스 처리

더미 인덱스(dummy index)는 위/아래 쌍으로 수축되는 인덱스이다.
mGRG는 더미 인덱스를 자동으로 관리하지만, 수동 제어가 필요한 경우도 있다.

### Dum: 인덱스 쌍을 더미로 변환

`Dum`은 Kind에 부합하는 위/아래 인덱스 쌍이 (시스템 내부 표현을 갖는) 더미 인덱스가 아닌 경우,
(시스템 내부 표현을 갖는) 더미 인덱스로 교체한다.

```wolfram
expr = R[la, ua] * F[lb, ub]
Dum[expr]
(* --> R[lLatin$1, uLatin$1] * F[lLatin$2, uLatin$2] *)
(* la/ua와 lb/ub가 각각 시스템 내부 표현의 더미 인덱스 쌍으로 교체됨 *)
```

여러 Kind가 혼재된 경우, `IndexQs` 옵션으로 특정 Kind만 처리할 수 있다:

```wolfram
expr = CR[lA, uA] * R[la, ua]

(* Capital Kind 인덱스만 더미로 변환 *)
Dum[expr, IndexQs -> {KindIndexQ[Capital]}]
(* --> CR[lCapital$1, uCapital$1] * R[la, ua] *)
(* Latin 인덱스 la, ua는 변환되지 않음 *)
```

### DumFresh: 모든 인덱스를 새 더미로 교체

`DumFresh`는 이미 더미인 인덱스도 포함하여 모든 텐서 인덱스를
새로운 (시스템 내부의 고유한 값을 갖는) 더미 인덱스로 교체한다.

```wolfram
DumFresh[R[la, lb] * R[ua, lc]]
(* --> R[lLatin$3, lb] * R[uLatin$3,lc] *)
```

`DumFresh`는 `RuleUnique`의 내부에서 사용되어, 규칙 적용 시 더미 인덱스 충돌을 방지한다:

```wolfram
aRule = RuleUnique[b[la_, ub_], a[la] a[ub] a[lc] a[uc], PairIndexQ[{la, ub}]]
b[la, ua] * b[lb, ub] /. aRule
(* --> a[la] a[ua] a[lX$5] a[uX$5] * a[lb] a[ub] a[lX$6] a[uX$6] *)
```

### ResetDummies: 더미 인덱스 정규화

(시스템 내부 표현의) 더미 인덱스를 정규 순서(`la`, `lb`, `lc`, ...)로 재명명한다.

```wolfram
expr = R[lLatin$1, uLatin$1] * CurvR[lLatin$2, lLatin$3, uLatin$2, uLatin$3]
ResetDummies[expr]
(* --> R[la, ua] CurvR[lb, lc, ub, uc] *)
```

`All -> False` 옵션은 프로그램 생성 더미만 재조정하고 사용자가 입력한 수축된 인덱스는 유지한다.

**주의**: `ResetDummies`는 (Mathematica가 내부적으로) `Plus`의 항 순서를 변경할 수 있으므로,
출력을 변수에 할당할 때는 `%`를 사용하는 것이 안전하다:

```wolfram
ResetDummies[complexExpr]
result = %
```

### SumDum: 더미 인덱스에 대한 합산

더미 인덱스 쌍을 수치 성분으로 전개하여 합산한다 (Einstein summation).
성분 계산(component calculation)에 필수적인 함수이다.

**성분 모드** (인자 없이 호출):

```wolfram
SetDimension[4]

SumDum[R[la, ua]]
(* --> R[-1, 1] + R[-2, 2] + R[-3, 3] + R[-4, 4] *)
(* 하향 인덱스는 음의 정수, 상향 인덱스는 양의 정수 *)
```

**수치 합산** (범위 지정): `SumDum[expr, {1, 3}]`은 모든 Kind의 더미를 1~3으로 합산.
`SumDum[expr, {1, 3}, Capital]`은 Capital Kind만 합산한다.

**기호 합산**: `SumDum[R[la, ua], {la, li, lj}]`은 `la`를 `li`, `lj`로 대치하여 합산한다.

---

## 6. 구문 검사

### 수동 구문 검사: SyntaxCheck

`SyntaxCheck`는 텐서 표현식의 인덱스 구문을 검사한다.
오류가 발견되면 해당 부분을 `ErrorT`로 감싸서 반환한다.

**중복 인덱스 검출:**

```wolfram
SyntaxCheck[R[la, la]]
(* --> Msg::err: duplicated indices *)
(* --> ErrorT[R][la, la] *)
```

**자유 인덱스 불일치:**

```wolfram
SyntaxCheck[a scR[] F[lb, lc] + b R[lb, la]]
(* --> Msg::err: incompatible free indices: {lb, lc} and {la, lb} *)
(* --> ErrorT[a scR[] F[lb, lc] + b R[lb, la]] *)
```

`Plus` 표현식의 각 항은 동일한 자유 인덱스를 가져야 한다.
첫 번째 항의 자유 인덱스 `{lb, lc}`와 두 번째 항의 `{la, lb}`가 불일치한다.

**정상 표현식:**

```wolfram
SyntaxCheck[v[la] R[lb, lc]]
(* --> v[la] R[lb, lc]  (오류 없음, 그대로 반환) *)
```

### ErrorT: 오류 래퍼

`ErrorT`로 감싸진 표현식은 빨간색으로 표시된다. `SyntaxCheck`는 이 외에도 연산자 인덱스 유효성, 스칼라 함수 인자, `Tscalar` 인자 수, Epsilon 인덱스 수, 텐서 인덱스 개수 등을 검사한다.

`MarkErrorFlag`가 `Off`이면 `ErrorT -> Identity`로 치환되어 오류 표시가 제거된다.

### 자동 구문 검사

성능상의 이유로 자동 구문 검사는 기본적으로 꺼져 있다:

```wolfram
On[SyntaxCheckFlag]
(* 이후 모든 출력에서 SyntaxCheck가 자동 실행됨 *)

R[la, la]
(* --> 자동으로 ErrorT[R][la, la] 표시 *)

Off[SyntaxCheckFlag]
(* 자동 구문 검사 비활성화 (기본값 복원) *)
```

---

## 7. 플래그 제어

mGRG의 플래그는 `flagTable[key]`에 저장되며,
Mathematica 내장 `On`/`Off`를 오버로드하여 제어한다.

### AutoFlag: 전체 자동 처리

다른 모든 플래그의 상위 스위치이다.
`Off[AutoFlag]`이면 `SyntaxCheckFlag`, `ResetDummiesFlag`, `MarkErrorFlag` 등이
설정되어 있어도 실행되지 않는다.

```wolfram
Off[AutoFlag]
(* $Post 해제 -- 모든 자동 처리 중지 *)
(* ExpandObject, ResetDummies 등이 출력에 적용되지 않음 *)

v[la] + v[lb]   (* 자유 인덱스 불일치지만 오류 표시 없음 *)

On[AutoFlag]
(* $Post = postEval 등록 -- 자동 처리 재개 *)
```

### 개별 플래그

```wolfram
(* 자동 구문 검사 -- 기본 Off *)
On[SyntaxCheckFlag]     (* 모든 출력에서 SyntaxCheck 자동 실행 *)
Off[SyntaxCheckFlag]    (* 비활성화 *)

(* 오류 표시 -- 기본 On *)
On[MarkErrorFlag]       (* ErrorT를 빨간색으로 표시 *)
Off[MarkErrorFlag]      (* ErrorT -> Identity, 오류 표시 제거 *)

(* 더미 인덱스 자동 리셋 -- 기본 On *)
On[ResetDummiesFlag]    (* 출력 시 더미 인덱스를 정규 형태로 자동 리셋 *)
Off[ResetDummiesFlag]   (* 더미 인덱스를 그대로 유지 *)
```

### CoordinateBasisFlag: 기저 선택

좌표 기저(coordinate basis)와 비좌표 기저(non-coordinate basis)를 전환한다.

```wolfram
(* 기본: 좌표 기저 *)
On[CoordinateBasisFlag]
CoordinateBasisQ[Latin]
(* --> True *)
(* GammaCD는 처음 두 인덱스에 대해 대칭 (TorsionFree일 때) *)

(* 비좌표 기저로 전환 *)
Off[CoordinateBasisFlag]
CoordinateBasisQ[Latin]
(* --> False *)
(* 구조 상수 텐서 Structuref가 자동으로 정의됨 *)
(* GammaCD의 대칭성이 "abc" (대칭 없음)로 변경됨 *)

(* 특정 Kind만 전환할 수도 있다 *)
Off[CoordinateBasisFlag[Greek]]
(* Greek Kind만 비좌표 기저, Latin은 좌표 기저 유지 *)

On[CoordinateBasisFlag]
(* 좌표 기저 복귀 -- Structuref 제거 *)
```

### 플래그 기본값 요약

| 플래그 | 기본값 | 설명 |
|--------|--------|------|
| `AutoFlag` | `On` | 자동 후처리 활성 |
| `MarkErrorFlag` | `On` | 오류 빨간색 표시 |
| `ResetDummiesFlag` | `On` | 더미 인덱스 자동 리셋 |
| `SyntaxCheckFlag` | `Off` | 자동 구문 검사 비활성 |
| `CoordinateBasisFlag` | `On` | 기본 Kind는 좌표 기저 |

### 현재 설정 확인: Show

`Show[kind]`는 해당 Kind의 현재 상태(플래그, 차원, 좌표 등)를 테이블 형식으로 표시한다.

```wolfram
Show[Latin]
(* --> AutoFlag, MarkErrorFlag, ResetDummiesFlag, SyntaxCheckFlag,
       Kind, Dimension, Sig, Coordinates, CoordinateBasisQ 등이 표시됨 *)
```

---

## 8. 실전 예제: 텐서 항등식 검증 워크플로

텐서 항등식을 검증할 때, 여러 함수를 조합하는 전형적인 워크플로를 소개한다.

### 예제 1: 대칭 텐서의 대칭화 확인

대칭 텐서 `R[la, lb]`(`"ba"` 대칭)에 대해, 대칭화가 항등 연산임을 확인한다.

```wolfram
<< mGRG`STensor`
Tdefine[R, "ba"]

(* 대칭화 *)
sym = SymmetrizeIndices[R[la, lb], {la, lb}]
(* --> 1/2 (R[la, lb] + R[lb, la]) *)

(* Tsimplify로 대칭성을 이용한 단순화 *)
Tsimplify[sym]
(* --> R[la, lb]  (원래 표현과 동일) *)
```

### 예제 2: 반대칭 텐서의 대칭화 = 0

반대칭 텐서 `F[la, lb]`(`"-ba"` 대칭)의 대칭화는 0이 되어야 한다.

```wolfram
Tdefine[F, "-ba"]

sym = SymmetrizeIndices[F[la, lb], {la, lb}]
(* --> 1/2 (F[la, lb] + F[lb, la]) *)

Tsimplify[sym]
(* --> 0 *)
```

### 예제 3: 리만 텐서의 대칭성 확인

`CurvR`(대칭 문자열 `"-bacd-abdc+cdab"`)의 인덱스 대칭성을 확인한다.

```wolfram
Tdefine[CurvR, "-bacd-abdc+cdab"]

(* 처음 두 인덱스에 대한 반대칭 확인 *)
expr = CurvR[la, lb, lc, ud]
anti12 = AntisymmetrizeIndices[expr, {la, lb}]
(* --> 1/2 (CurvR[la, lb, lc, ud] - CurvR[lb, la, lc, ud]) *)

(* "-bacd" 대칭으로 인해 원래 표현과 같아야 함 *)
Tsimplify[anti12]
(* --> CurvR[la, lb, lc, ud] *)
```

### 예제 4: SplitIndices와 SumDum을 이용한 성분 분해

```wolfram
SetDimension[4]
expr = R[la, ua]

SumDum[expr]
(* --> R[-1, 1] + R[-2, 2] + R[-3, 3] + R[-4, 4] *)

SplitIndices[R[la, lb], {la, l1, l2, l3, l4}]
(* --> {R[l1, lb], R[l2, lb], R[l3, lb], R[l4, lb]} *)
```

---

### 성능 팁

- `SyntaxCheckFlag`는 기본적으로 `Off`이다. 디버깅이 필요할 때만 `On`으로 전환하라.
- `ResetDummies`는 `Plus` 항의 순서를 바꿀 수 있으므로, 순서가 중요한 비교 작업 전에는 `Off[ResetDummiesFlag]`를 고려하라.
- 인덱스가 많은 반대칭화(`AntisymmetrizeIndices`)는 `n!`개의 항을 생성하므로, n이 클 때 연산 시간에 주의하라.

---
## 참고 파일

> - `06-ExpressionUtils.md` -- `ExpandObject`, `FreeObjectQ`, `ForEachTerm`, `ForEachObject`, `SplitTerm`, `NoIndexQ`
> - `07-IndexOperations.md` -- `FindIndices`, `FindFreeTensorialIndices`, `AntisymmetrizeIndices`, `SymmetrizeIndices`, `Dum`, `DumFresh`, `ResetDummies`, `SplitIndices`, `SumDum`, `RuleUnique`
> - `08-SyntaxAndFlags.md` -- `postEval`, `SyntaxCheck`, `ErrorT`, `Tscalar`, `AutoFlag`, `SyntaxCheckFlag`, `MarkErrorFlag`, `ResetDummiesFlag`, `CoordinateBasisFlag`, `Show`
