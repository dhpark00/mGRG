# CovariantStructures — 인덱스 올리기/내리기 (Absorb, PutMetric, PullOutMetric, DualStar)

`mGRG`STensor`` 패키지의 `CovariantStructures.m`에서 제공하는 인덱스 올리기/내리기 및 Hodge 쌍대 관련 함수들이다.

---

### Absorb

#### 함수 시그니처

```wolfram
Absorb[expr, sym2T, opts]
```

#### 설명 (Details)

(계량 텐서일 필요는 없는) rank 2인 대칭 텐서 `sym2T`를 이용하여 인덱스를 올리거나 내릴 때 사용한다.

- 첫 번째 인자는 임의의 표현이고, 두 번째 인자는 rank-2 텐서의 이름이다. 옵션으로 `IndexQs`, `HeadQs`, `CovDs`가 있다.
- `expr`에 포함된 연산자가 두 번째 인자에 대해 공변 연산자가 아니어도 `CovDs` 옵션으로 공변 연산자로 지정할 수 있다.
- `IndexQs`에 대한 옵션이 없으면 두 번째 인자의 Kind와 동일한 인덱스 쌍만 `Absorb`에서 고려한다.
- `IndexedObject`의 `Log`와 `Power`는 `ScalarFunction`이다.

#### 예제 (Examples)

```wolfram
Tdefine[g, "+ba"]

{F[la, lb] × g[ub, uc], RicciCD[la, lb] × g[ua, ub]}
Absorb[%, g]
(* {F_a^c, R} *)

(* BD 연산자 포함 — 기본적으로 공변 연산자가 아님 *)
g[ua, ub] × BD[lb, F[la, ld]]
Absorb[%, g]
(* ∂^a F_ad *)

(* CovDs 옵션으로 BD 포함 *)
g[ub, ud] × BD[la, F[lb, lc]]
Absorb[%, g, CovDs -> {BD}]
(* ∂_a F^d_c *)

(* IndexQs 옵션 *)
Absorb[expr, phi, IndexQs -> {KindIndexQ[Latin]}]
```

#### 참고 (See Also)

`Absorbg`, `PutMetric`, `PullOutMetric`, `Metricg`, `MetricgFlag`

---

### Absorbg

#### 함수 시그니처

```wolfram
Absorbg[expr, opts]
```

#### 설명 (Details)

`Absorb[expr, Metricg, opts]`의 축약형이다. 기본 계량 텐서 `Metricg`를 이용하여 인덱스를 올리거나 내릴 때 사용한다. `Metricg`가 존재해야 하므로 `MetricgFlag`이 `On`이어야 한다.

#### 예제 (Examples)

```wolfram
{F[la, lb] × Metricg[ub, uc], RicciCD[la, lb] × Metricg[ua, ub]}
Absorbg[%]
(* {F_a^c, R} *)
```

#### 참고 (See Also)

`Absorb`, `Metricg`, `MetricgFlag`, `PutMetric`

---

### PutMetric

#### 함수 시그니처

```wolfram
PutMetric[expr, index, opts]
```

#### 설명 (Details)

`Absorbg`와 반대로, 계량 텐서를 이용하여 하나의 인덱스를 올리거나 내릴 때 사용한다.

- `PutMetric`의 두 번째 인자인 내리거나 올릴 인덱스의 이름은 (`ResetDummies`가 자동 호출되므로) **출력을 마친 이후**에나 결정됨을 기억하자.
- CD type 연산자의 첫 번째 인자는 아래 첨자가 기본 위치인 인덱스이다.
- LD type의 연산자가 텐서가 아닌 표현에 작용하면 적절한 텐서 연산이 아니므로 `PutMetric`은 아무런 효과가 없다.

#### 예제 (Examples)

```wolfram
Tdefine[T, "*"]
T[ub, lc, ld, lb]
(* T^a_cda  -- 더미 인덱스 자동 조정 결과 *)
expr = %;

PutMetric[expr, ua]
(* g^ab T_bcda *)

% // Absorbg
(* T^a_cda *)

PutMetric[expr, la]
(* g_ab T^a_cd^b *)

% // Absorbg
(* T^a_cda *)
```

#### 참고 (See Also)

`PullOutMetric`, `Absorb`, `Absorbg`, `Metricg`

---

### PullOutMetric

#### 함수 시그니처

```wolfram
PullOutMetric[expr, opts]
```

#### 설명 (Details)

텐서를 정의할 때 설정된 위/아래 첨자의 위치로 (계량 텐서를 사용하여) 되돌린다. 위/아래 첨자를 특별히 정하지 않았으면 기본적으로 아래 첨자로 지정된다.

#### 예제 (Examples)

```wolfram
Tdefine[T[ua, ub]]
(* 기본 위치는 (up, up) *)

T[ua, ub]
% // PullOutMetric
(* T^ab -- 이미 기본 위치 *)

T[la, ub]
% // PullOutMetric
(* g_ac T^cb *)

% // Absorbg
(* T_a^b *)

T[la, lb]
% // PullOutMetric
(* g_ac g_bd T^cd *)

% // Absorbg
(* T_ab *)
```

#### 참고 (See Also)

`PutMetric`, `Absorb`, `Absorbg`, `Metricg`

---

### DualStar

#### 함수 시그니처

```wolfram
DualStar[expr, {freeIndices}, kind]
```

#### 설명 (Details)

텐서 표현식의 Hodge 쌍대(Hodge dual)를 계산한다. 참고: R. M. Wald, Chap.4 Problems 2-(a).

$$*(\alpha_{a_1 \ldots a_p}) = (*\alpha)^{b_1 \ldots b_{n-p}} = \frac{1}{p!} \alpha_{a_1 \ldots a_p} \epsilon^{a_1 \ldots a_p b_1 \ldots b_{n-p}}$$

- `DualStar`의 두 번째 인자는 출력될 `Epsilon` 텐서의 인덱스 중에서 Free 인덱스에 해당한다. 그 인덱스의 적절함은 사용자의 몫이다.
- 임의 차원에서의 `DualStar` 연산에서는 입력한 Free 인덱스를 바탕으로 `Epsilon` 텐서의 인덱스의 갯수가 자동 조정된다.
- Kind의 차원이 설정된 경우는 입력한 Free 인덱스의 갯수가 적합해야 한다.
- `kind` 인자를 사용하면 해당 Kind의 `Epsilon`을 사용한다.

#### 예제 (Examples)

```wolfram
Tdefine[A, "*-"]

DualStar[A[ua, lb], {lc, ld}]
(* 1/2 A^a_b ε_a^b_cd *)

DualStar[A[ua, lb, ud], {lc, le}]
(* 1/6 A^a_b^d ε_a^b_dce *)

DualStar[A[ua, lb, ud, uc], {le}]
(* 1/24 A^a_b^cd ε_a^b_cde  -- 인덱스 자동 재조정 *)

DualStar[A[ua, lb], {lc}]
(* 1/2 A^a_b ε_a^b_c *)

(* 차원 설정 시 유효성 검사 *)
SetDimension[4]
DualStar[A[ua, lb], {lc}]
(* Msg: Invalid numbers of indices: {lc} → $Failed *)

DualStar[A[ua, lb], {lc, ld}]
(* 1/2 A^a_b ε_a^b_cd *)
ClearDimension[]

(* Capital Kind *)
Tdefine[CA, "*", Capital]
DualStar[CA[uA], {lB}, Capital]
(* CA^A ε[Capital]_AB *)
```

#### 참고 (See Also)

`Epsilon`, `Metricg`, `Absorbg`, `MetricgFlag`
