# TensorComponents — SetComponents / ClearComponents

`mGRG`STensor`` 패키지의 `TensorComponents.m`에서 제공하는 텐서 성분값 설정 및 제거 함수이다.

---

### SetComponents

#### 함수 시그니처

```wolfram
SetComponents[tensor[indices], values]
```

#### 설명 (Details)

텐서의 성분값을 대입한다. 첫 번째 인자가 성분 텐서가 아닌 경우 두 번째 인자는 Table 표현이어야 한다.

- `values`는 단일 표현식, 한 성분의 값, 또는 모든 성분에 대한 리스트/테이블이 될 수 있다.
- See MathTensor by L. Parker and S. M. Christenson, chapter 4.

#### 예제 (Examples)

**단일 성분 대입:**

```wolfram
Tdefine[e, 1]; Tdefine[b, 1]; Tdefine[F, "-ba"]

SetComponents[F[1, 1], 0];
SetComponents[F[2, 2], 0];
SetComponents[F[3, 3], 0];
SetComponents[F[4, 4], 0]

SetComponents[F[1, 4], -e[1]];
SetComponents[F[2, 4], -e[2]];
SetComponents[F[3, 4], -e[3]]

{F[1, 4], F[2, 4], F[3, 4]}
(* {-e^1, -e^2, -e^3} *)
```

**자기장 성분 대입:**

```wolfram
SetComponents[F[1, 2], b[3]];
SetComponents[F[1, 3], -b[2]];
SetComponents[F[2, 3], b[1]]

{F[1, 2], F[1, 3], F[2, 3]}
(* {b^3, -b^2, b^1} *)
```

**Table로 모든 성분 대입:**

```wolfram
metric = {{1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, -1}};
SetComponents[Metricg[la, lb], metric]
```

**계량 텐서를 이용한 인덱스 내림:**

```wolfram
Metricg[la, lc] × Metricg[lb, ld] × F[uc, ud]
dnF = Table[SumDum[%, {1, 4}], {la, -1, -4, -1}, {lb, -1, -4, -1}]
(* F^cd g_ac g_bd의 성분값 테이블 *)

SetComponents[F[la, lb], dnF]

{F[-1, -4], F[-2, -3], F[-1, -2]}
(* {e^1, b^1, b^3} *)
```

**불변량 계산:**

```wolfram
F[la, lb] × F[ua, ub]
SumDum[%, {1, 3}]
(* 2b^1² + 2b^2² + 2b^3² *)
```

**SetComponents 없이 함수로 정의:**

```wolfram
dnF2[la_, lb_] := SumDum[Metricg[la, lc] × Metricg[lb, ld] × F[uc, ud], {1, 4}]

{dnF2[-1, -4], dnF2[-2, -3], dnF2[-1, -2]}
(* {e^1, b^1, b^3} *)
```

**방정식 유도 (Maxwell):**

```wolfram
eq1[lb_, ua_, ub_] := BD[lb, F[ua, ub]] /; PairIndexQ[{lb, ub}];
eq2[la_, lb_, lc_] := BD[la, F[lb, lc]] + BD[lb, F[lc, la]] + BD[lc, F[la, lb]]

(* 가우스 법칙 *)
gaussLaw = BD[la, F[4, ua]]
SumDum[gaussLaw, {1, 3}]
(* ∂_3e^3 + ∂_2e^2 + ∂_1e^1 *)

(* Maxwell 방정식들 *)
SumDum[eq1[lb, 1, ub], {1, 4}]
(* -∂_4e^1 - ∂_3b^2 + ∂_2b^3 *)

SumDum[eq1[lb, 2, ub], {1, 4}]
(* -∂_4e^2 + ∂_3b^1 - ∂_1b^3 *)

SumDum[eq1[lb, 4, ub], {1, 4}]
(* ∂_3e^3 + ∂_2e^2 + ∂_1e^1 *)

(* Bianchi 항등식 *)
eq2[-1, -2, -3]
(* ∂_3b^3 + ∂_2b^2 + ∂_1b^1 *)

eq2[-1, -2, -4]
(* ∂_4b^3 - ∂_2e^1 + ∂_1e^2 *)
```

#### Check (유효성 검사)

```wolfram
SetDimension[4]

SetComponents[F[1, 5], some]
(* Msg: The value of a component index 5 is larger than the dimension 4 *)

SetComponents[F[1, -5], some]
(* Msg: The value of a component index 5 is larger than the dimension 4 *)

ClearDimension[]

SetComponents[F[la], {some1, some2}]
(* Msg: invalid number of indices (la) with rank 2 *)

SetComponents[F[la, lb], {some1, some2}]
(* Msg: incompatible components for a rank 2 *)

SetComponents[F[la, lb], {{1, 2, 3}, {4, 5, 6}}];
Table[F[-i, -j], {i, 2}, {j, 3}] // MatrixForm
(* (1 2 3)
   (4 5 6) *)
```

**SetDimension에 따른 ClearComponents 동작:**

```wolfram
SetDimension[2]
ClearComponents[F[la, lb]]
Table[F[-i, -j], {i, 2}, {j, 3}] // MatrixForm
(* (F_11  F_12  3 )
   (F_21  F_22  6 ) — 차원 밖의 값은 남아 있음 *)

SetDimension[3]
ClearComponents[F[la, lb]]
Table[F[-i, -j], {i, 2}, {j, 3}] // MatrixForm
(* (F_11  F_12  F_13)
   (F_21  F_22  F_23) — 모두 클리어 *)
```

**차원 없이 성분 대입:**

```wolfram
ClearDimension[]
SetComponents[F[la, lb], {{1, 2}, {3, 4}, {5, 6}}]
Table[F[-i, -j], {i, 3}, {j, 2}] // MatrixForm
(* (1 2)
   (3 4)
   (5 6) *)

ClearComponents[F[la, lb]]
(* Msg: need to set dimension for the index la *)

ClearComponents[F[la, lb], {3, 2}]
Table[F[-i, -j], {i, 3}, {j, 2}] // MatrixForm
(* (F_11  F_12)
   (F_21  F_22)
   (F_31  F_32) *)
```

**차원과 Table 크기 불일치:**

```wolfram
SetDimension[2]
SetComponents[F[la, lb], {{1, 2}, {3, 4}, {5, 6}}]
Table[F[-i, -j], {i, 2}, {j, 2}] // MatrixForm
(* (1 2)
   (3 4) *)

ClearComponents[F[la, lb], {3, 2}]
(* Msg: invalid input 3 for the dimension 2 *)
```

---

### ClearComponents

#### 함수 시그니처

```wolfram
ClearComponents[tensor[indices]]
ClearComponents[tensor[indices], dims]
```

#### 설명 (Details)

텐서의 성분값을 제거한다. 인자가 성분 텐서인 경우는 그 성분의 값만 제거하고, 아닌 경우는 모든 성분의 값을 제거한다.

- 특정 성분 인덱스를 지정하면 해당 성분(과 대칭적 동치인 성분)만 제거된다.
- 일반 인덱스를 지정하면 모든 성분이 제거된다.
- `dims`에 차원 정보를 명시적으로 지정할 수 있다 (차원이 설정되지 않은 경우).

#### 예제 (Examples)

```wolfram
(* 특정 성분만 제거 *)
ClearComponents[F[la, lb], {4, 4}]

{F[-2, -1], F[1, 3]}
(* {F_21, -b^2} — F[4,4]만 제거됨 *)

(* 대칭성 있는 성분 제거 *)
ClearComponents[F[1, 3]]

{F[1, 3], F[2, 3]}
(* {F^13, b^1} — F[1,3]과 F[3,1] = -F[1,3]이 제거됨 *)

(* 인덱스 타입별 제거 *)
ClearComponents[F[ua, ub], {4, 4}]

F[2, 3]
(* F^23 — 상인덱스 성분 제거됨 *)

(* Metricg 성분 제거 *)
ClearComponents[Metricg[la, lb], {4, 4}]
```

#### 참고 (See Also)

`SetComponents`, `SumDum`, `Show`
