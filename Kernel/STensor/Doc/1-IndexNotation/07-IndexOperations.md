# IndexNotation — 인덱스 연산 (Index Operations)

인덱스를 갖는 표현의 인덱스를 탐색, 대칭화, 더미 인덱스 처리 등의 연산을 수행하는 함수들이다.

---

## 인덱스 탐색

---

### FindIndices

#### 함수 시그니처

```wolfram
FindIndices[term]
FindIndices[term, opts]
```

#### 설명 (Details)

한 개의 항(`term`)의 (Kind에 부합하는) 모든 인덱스를 리스트로 반환한다.

- 옵션으로 `IndexQs`와 `HeadQs`가 있다.
- `IndexedObject`가 아닌 표현은 기본적으로 무시된다.
- `ScalarFunction`은 기본적으로 무시되지만, `HeadQs -> {ObjectQ}` 옵션으로 포함시킬 수 있다.

#### 예제 (Examples)

```wolfram
term = (a + b) CovD[la, F[ua, lb]] * R[-1, uC]
FindIndices[term]
(* {la, ua, lb, -1}  —— uC는 Latin Kind가 아니므로 제외 *)

FindIndices[term, IndexQs -> {TensorialIndexQ}]
(* {la, ua, lb} *)

FindIndices[term, HeadQs -> {IndexedOperandQ}]
(* {-1}  -— 연산자를 Head로 갖는 표현은 제외 *)
```

#### 참고 (See Also)

`FindIndicesAll`, `FindFreeTensorialIndices`, `IndexQs`, `HeadQs`

---

### FindFreeTensorialIndices

#### 함수 시그니처

```wolfram
FindFreeTensorialIndices[term]
FindFreeTensorialIndices[term, opts]
```

#### 설명 (Details)

한 개의 항(term)에서 자유(비수축) 텐서 인덱스를 반환한다.

- 수축된(contracted) 더미 인덱스 쌍은 제외된다.
- 옵션으로 `IndexQs`, `HeadQs`가 있다.

#### 예제 (Examples)

```wolfram
term = (a + b) CovD[la, F[ua, lb]] * R[-1, uc]
FindFreeTensorialIndices[term]
(* {lb, uc} *)

FindFreeTensorialIndices[term, IndexQs -> {UpIndexQ}]
(* {uc} *)
```

#### 참고 (See Also)

`FindFreeTensorialIndicesAll`, `FindIndices`, `IndexQs`, `HeadQs`

---

### FindIndicesAll

#### 함수 시그니처

```wolfram
FindIndicesAll[term]
```

#### 설명 (Details)

인덱스 유효성 검사 없이 모든 Kind의 모든 인덱스를 반환한다.

- `FindIndices`와 달리, Kind에 부합하는지 여부를 확인하지 않는다.

#### 예제 (Examples)

```wolfram
term = (a + b) CovD[lA, F[ua, lB]] * R[-1, uA]
FindIndicesAll[term]
(* {lA, ua, lB, -1, uA} *)
```

#### 참고 (See Also)

`FindIndices`, `FindFreeTensorialIndicesAll`

---

### FindFreeTensorialIndicesAll

#### 함수 시그니처

```wolfram
FindFreeTensorialIndicesAll[term]
```

#### 설명 (Details)

유효성 검사 없이 자유 텐서 인덱스를 반환한다.

- `FindFreeTensorialIndices`와 달리, Kind 유효성을 확인하지 않는다.

#### 예제 (Examples)

```wolfram
term = (a + b) CovD[lA, F[ua, lB]] * R[-1, uA]
{FindIndicesAll[term], FindFreeTensorialIndicesAll[term]}
(* {{lA, ua, lB, -1, uA}, {ua, lB}} *)
```

#### 참고 (See Also)

`FindFreeTensorialIndices`, `FindIndicesAll`

---

## 인덱스 대칭화

---

### AntisymmetrizeIndices

#### 함수 시그니처

```wolfram
AntisymmetrizeIndices[expr, {i1, i2, ...}]
AntisymmetrizeIndices[expr, {i1, i2, ...}, opts]
```

#### 설명 (Details)

지정된 인덱스에 대해 반대칭화를 수행한다.

- 옵션으로 `HeadQs`가 있다.
- 내부적으로 모든 순열을 생성하므로, 인덱스 수가 많으면 연산 시간에 주의해야 한다.
- 결과는 `1/n!` 계수가 곱해진 부호 교대 합이다.

#### 예제 (Examples)

```wolfram
AntisymmetrizeIndices[F[la, lb], {la, lb}]
(* 1/2 (F[la, lb] - F[lb, la]) *)

CovD[uc, CovD[la, F[ub, lc]]]
AntisymmetrizeIndices[%, {la, ub, lc}]
(* 1/6 (-CovD[uc, CovD[la, F[lc, ub]]] + CovD[uc, CovD[la, F[ub, lc]]] + ...) *)
```

#### 참고 (See Also)

`SymmetrizeIndices`, `HeadQs`

---

### SymmetrizeIndices

#### 함수 시그니처

```wolfram
SymmetrizeIndices[expr, {i1, i2, ...}]
SymmetrizeIndices[expr, {i1, i2, ...}, opts]
```

#### 설명 (Details)

지정된 인덱스에 대해 대칭화를 수행한다.

- 옵션으로 `HeadQs`가 있다. `HeadQs -> {ObjectQ}`로 `ScalarFunction` 내의 인덱스도 처리 가능하다.
- 결과는 `1/n!` 계수가 곱해진 순열 합이다.

#### 예제 (Examples)

```wolfram
SymmetrizeIndices[F[la, lb], {la, lb}]
(* 1/2 (F[la, lb] + F[lb, la]) *)
```

#### 참고 (See Also)

`AntisymmetrizeIndices`, `HeadQs`

---

## 더미 인덱스 처리

---

### Dum

#### 함수 시그니처

```wolfram
Dum[expr]
Dum[expr, opts]
```

#### 설명 (Details)

표현식에서 수축된 첨자 쌍을 더미 인덱스 표현으로 바꾼다.

- Kind에 부합하는 위/아래 첨자 쌍이 더미 인덱스가 아니면 더미 인덱스로 바꾼다.
- 이미 더미 인덱스인 경우는 효과가 없다.
- 옵션: `IndexQs`, `HeadQs`.

#### 예제 (Examples)

```wolfram
expr = A R[la, ua] * CurvR[lc, ld, uc, ud] +
    a CovD[lA, CurvR[la, lb, uc, ud]] * CovD[uA, CurvR[ua, ub, lc, ld]]
Dum[expr]
(* 인덱스 쌍이 더미 인덱스로 변환됨 *)

(* 특정 Kind만 대상 *)
Dum[CR[lA, uA] * R[la, ua], IndexQs -> {KindIndexQ[Capital]}]
```

#### 참고 (See Also)

`DumFresh`, `ResetDummies`, `IndexQs`, `HeadQs`

---

### DumFresh

#### 함수 시그니처

```wolfram
DumFresh[expr]
```

#### 설명 (Details)

모든 더미 인덱스를 새로운 고유 더미 인덱스로 교체한다.

- `Dum`은 이미 더미인 경우 무시하지만, `DumFresh`는 이미 더미인 경우에도 새로운 더미 인덱스로 교체한다.
- `RuleUnique`의 우변에서 자동으로 사용된다.

#### 예제 (Examples)

```wolfram
Dum[expr]      (* 인덱스 쌍을 더미로 *)
DumFresh[%]    (* 더미 인덱스인 경우에도 새 더미 인덱스로 교체 *)
```

#### 참고 (See Also)

`Dum`, `ResetDummies`, `RuleUnique`

---

### ResetDummies

#### 함수 시그니처

```wolfram
ResetDummies[expr]
ResetDummies[expr, opts]
```

#### 설명 (Details)

더미 인덱스를 정규형(`la`, `lb`, ...)으로 재명명한다.

- 옵션 `All -> True` (기본값): 더미 인덱스 쌍과 모든 정규 인덱스 쌍을 재조정한다.
- 옵션 `All -> False`: 프로그램이 생성한 더미 인덱스만 재조정한다.
- 옵션 `HeadQs`로 처리 대상을 제한할 수 있다.
- **주의**: `Plus` 표현식의 항 순서가 (Mathematica 자체의 정렬 방식 때문에) 변경될 수 있다.

#### 예제 (Examples)

```wolfram
expr = Dum[A R[la, ua] * CurvR[lc, ld, uc, ud] + ...]
ResetDummies[expr]
(* 프로그램이 생성한 더미 인덱스 뿐만 아니라 (Kind와 무관하게) 모든 인덱스 쌍들을 재조정하여 정규 인덱스로 바꿈 *)

ResetDummies[expr, All -> False]
(* 프로그램이 생성한 더미 인덱스만 리셋, 정규 인덱스 쌍은 유지 *)

ResetDummies[expr, HeadQs -> {IndexedOperatorQ}]
(* 연산자 표현만 리셋 *)
```

#### 참고 (See Also)

`Dum`, `DumFresh`, `ResetDummiesFlag`

---

### SplitIndices

#### 함수 시그니처

```wolfram
SplitIndices[expr, {i, i1, i2, ...}]
SplitIndices[expr, {i, i1, i2, ...}, {j, j1, j2, ...}, ...]
```

#### 설명 (Details)

인덱스 `i`를 `i1`, `i2`, ...로 교체한 표현식 리스트를 생성한다. `Table`의 심볼릭 버전이다.

- 여러 인덱스를 동시에 분할할 수 있으며, 결과는 다차원 리스트가 된다.
- Kaluza-Klein 분해나 (3+1) decomposition에 유용하다.

#### 예제 (Examples)

```wolfram
(* 단일 인덱스 분할 *)
SplitIndices[Cg[lA, lB], {lA, lalpha, lbeta}]
(* {Cg[lalpha, lB], Cg[lbeta, lB]} *)

(* 다중 인덱스 분할 *)
SplitIndices[Cg[lA, lB], {lA, lalpha, la}, {lB, lbeta, lb}]
(* {{Cg[lalpha, lbeta], Cg[lalpha, lb]}, {Cg[la, lbeta], Cg[la, lb]}} *)

(* (3+1)-decomposition *)
DefKind[Zero, {"0"}]
SplitIndices[g[lmu, lnu], {lmu, l0, li}, {lnu, l0, lj}]
(* {{g[l0, l0], g[l0, lj]}, {g[li, l0], g[li, lj]}} *)
```

#### 참고 (See Also)

`SumDum`, `DefKind`

---

### SumDum

#### 함수 시그니처

```wolfram
SumDum[expr, {i1, i2}, kind]
SumDum[expr, {i, i1, i2, ...}, ...]
SumDum[expr, {kind1, kind2, ...}]
SumDum[expr]
```

#### 설명 (Details)

지정된 더미 인덱스 쌍에 대해 합산을 수행한다. 세 가지 모드가 있다.

**수치 합산 (Numeric Summation)**: `SumDum[expr, {n, m}, kind]` -- 지정된 Kind의 더미 인덱스 쌍을 숫자 `n`부터 숫자 `m`까지의 값으로 각각 대치한 후 합산한다. `kind`를 생략하면 모든 Kind에 대해 합산한다.

**기호 합산 (Symbolic Summation)**: `SumDum[expr, {i, i1, i2, ...}, ...]` -- 인덱스 `i`를 `i1`, `i2`, ...로 각각 대치하여 합산한다.

**Kaluza-Klein 합산**: `SumDum[expr, {kind, subkind1, subkind2}]` -- `kind` 인덱스를 `subkind1`, `subkind2`로 분할하여 합산한다.

**성분 모드 (Component Mode)**: `SumDum[expr]` -- 인자 없이 호출하면 `DefaultKind`의 차원에 따라 성분 합산한다.

- `ScalarFunction`에 대해서는 `HeadQs -> {ObjectQ}` 옵션을 사용해도 (구현 방식의 한계로) `SumDum`이 동작하지 않는다.

#### 예제 (Examples)

**수치 합산**:

```wolfram
expr = a R[la, ua] * CovD[lA, R[lmu, uA]] * CR[lB, uB]
SumDum[expr, {1, 3}]
(* 수치 인덱스 1~3으로 합산 *)

SumDum[expr, {1, 3}, Capital]
(* Capital Kind 인덱스만 합산 *)
```

**성분 모드**:

```wolfram
GetDimension[DefaultKind] = 2;
SumDum[g[la, ua]]
(* g[l2, u2] + g[l1, u1] *)
```

**기호 합산**:

```wolfram
SumDum[expr, {la, li, lj}]
(* la를 li, lj로 각각 대치하여 합산 *)

SumDum[CurvR[lmu, lnu, lrho, lsigma] * CurvR[umu, unu, urho usigma],
    {lmu, l0, li}, {lnu, l0, lj}, {lrho, l0, lk}, {lsigma, l0, ll}]
(* 16개 항의 합 *)
```

**Kaluza-Klein 합산**:

```wolfram
SumDum[a CR[lA, uA] * R[la, ua], {Capital, Latin, Greek}]
(* a CR[lalpha, ualpha] R[la, ua] + a CR[la, ua] R[lb, ub] *)

SumDum[a CR[lA, lB] * Cg[uA, uB], {Capital, Latin, Greek}]
(* a Cg[ua, ub] CR[la, lb] + a Cg[ua, ualpha] CR[la, lalpha] + a Cg[ualpha, ua] CR[lalpha, la] + a Cg[ualpha, ubeta] CR[lalpha, lbeta] *)
```

#### 참고 (See Also)

`SplitIndices`, `Dum`, `DumFresh`, `DefKind`

---

### RuleUnique

#### 함수 시그니처

```wolfram
RuleUnique[lhs, rhs]
RuleUnique[lhs, rhs, cond]
```

#### 설명 (Details)

더미 인덱스를 자동 처리하는 지연(delayed) 규칙 `lhs :> rhs /; cond`를 생성한다.

- 정확한 출력의 형태는 `lhs :> DumFresh[rhs] /; cond`이다.
- 규칙이 적용될 때마다 `DumFresh`가 우변의 더미 인덱스를 새로운 고유 더미 인덱스로 교체하므로, 동일 규칙을 여러 번 적용해도 더미 인덱스가 충돌하지 않는다.
- `cond`를 생략하면 조건 없는 지연 규칙이 생성된다.
#### 예제 (Examples)

```wolfram
rule = RuleUnique[B[la_, ub_], A[la] * A[ub] * A[lc] * A[uc], PairIndexQ[{la, ub}]]
(* B[la_, ub_] :> DumFresh[A[la] A[ub] A[lc] A[uc]] /; PairIndexQ[{la, ub}] *)

expr1 = B[la, ua] * B[lb, ub]
expr1 /. rule
(* A[la] A[ua] A[lc] A[uc] A[lb] A[ub] A[ld] A[ud] *)
(* 각 B에 대해 고유한 더미 인덱스가 생성됨 *)
```

#### 참고 (See Also)

`DumFresh`, `PairIndexQ`
