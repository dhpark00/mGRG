# CovariantStructures — 기본 연산자 (Pre-defined Tensorial Operators)

`mGRG`STensor`` 패키지의 `CovariantStructures.m`에서 제공하는 기본 텐서 연산자들이다.

---

### BD (기저 도함수 / Ordinary Derivative)

#### 함수 시그니처

```wolfram
BD[idx, expr]
BD[kind][idx, expr]
```

#### 설명 (Details)

`BD[idx, expr]`은 인덱스 `idx`에 연관된 기저 벡터에 대한 `expr`의 기저 도함수를 나타낸다. 좌표 기준에서는 편미분과 동치이다. 비좌표 기준에서는 기저 행렬을 통해 정의된다. `BD[kind][idx, expr]`을 사용하면 특정 Kind에 대한 도함수를 지정할 수 있다.

- CD type의 편미분 연산자이다.
- 좌표 기준과 비좌표 기준의 출력 표현에 차이가 있다: 좌표 기준에서는 `∂`로, 비좌표 기준에서는 $\hat{\partial}$로 출력된다.
- `BD`는 선형 미분 연산자로 라이프니츠 규칙을 만족한다.
- `Kdelta`는 상수 텐서이다.
- `IndexedObject`의 `Log`나 `Power`는 `ScalarFunction`이므로 편미분 연산을 한다.
- 스칼라 표현은 `Tscalar`로 둘러 싸야 한다.
- `BD`는 모든 종류의 Kind에서 사용된다.
- `DefaultKind`가 아닌 경우의 성분을 `BD`의 인자로 사용하려면 명시적으로 그 Kind를 표시해야 한다: `BD[Capital][-1, CF[uA, uB]]`.
- `DefaultKind`를 비좌표 기준으로 설정하려면 `Off[CoordinateBasisFlag]`.
- 연속한 미분은 인자를 연속해서 쓰면 된다.

#### 예제 (Examples)

```wolfram
CoordinateBasisQ[Latin]
(* True *)

{BD[-1, v[lb]], BD[la, v[lb]]}
(* {∂_1 v_b, ∂_a v_b} *)

(* Kdelta는 상수 *)
{Metricg[lb, uc], Metricg[lb, lc]}
BD[la, #] & /@ %
(* {0, ∂_a g_bc} *)

(* ScalarFunction 연산 *)
{BD[la, Log[f[]]], BD[la, f[]^2], BD[la, E^f[]], BD[la, x^f[]]}
(* {∂_a f / f, 2 ∂_a f f, e^f ∂_a f, x^(1+f) ∂_a x f + x^f ∂_a f Log[x]} *)

(* 비좌표 기준 *)
Off[CoordinateBasisFlag]
{F[ua, ub], RicciCD[ua, ub]}
BD[lb, la, #] & /@ %
(* {∂̂_a ∂̂_b F^ba, ∂̂_a ∂̂_b R^ba} -- Dummy 인덱스의 자동적인 조정 결과 *)
On[CoordinateBasisFlag]
```

#### 참고 (See Also)

`CD`, `LD`, `Tscalar`, `CoordinateBasisQ`, `EvaluateBDFlag`

---

### CD (공변 도함수 / Covariant Derivative)

#### 함수 시그니처

```wolfram
CD[aIndex, expr]
```

#### 설명 (Details)

CD type의 미분 연산자이다. `Metricg`에 대한 공변 도함수이다.

- Volume-form에 대해서는 시공간에 차원이 설정되었고 그 차원과 인덱스의 개수가 일치한 경우에만 공변 도함수가 역할을 한다.
- 선형 미분 연산자로 라이프니츠 규칙을 만족한다.
- `IndexedObject`의 `Log`나 `Power`는 `ScalarFunction`이다. 스칼라 표현은 `Tscalar`로 둘러 싸야 한다.
- 연속한 미분은 인자를 연속해서 쓰면 된다.
- `CD`는 항상 `DefaultKind`의 공변 연산자이다.

#### 예제 (Examples)

```wolfram
{CD[la, v[ua]], CD[1, v[la]], CD[-1, v[1]]}
(* {∇_a v^a, ∇^1 v_a, ∇_1 v^1} *)

(* Metricg에 대한 공변 도함수 *)
{Metricg[lb, lc], Epsilon[lb, lc, ld, le], Metricg[-1, lc]}
CD[la, #] & /@ %
(* {0, ∇_a ε_bcde, ∇_a g_1c} *)

SetDimension[4]
CD[la, #] & /@ {Epsilon[lb, lc, ld], Epsilon[lb, lc, ld, le]}
(* {∇_a ε_bcd, 0} *)
ClearDimension[]

(* 라이프니츠 규칙 *)
c1 RicciCD[la, lb] + c2 F[la, lc] × RicciCD[uc, lb]
CD[ua, %]
(* c1 ∇^a R_ab + c2 ∇^a R^c_b F_ac + c2 ∇^a F_ac R^c_b *)

(* ScalarFunction *)
{CD[la, Log[f[]]], CD[la, f[]^2], CD[la, E^f[]], CD[la, x^f[]]}
(* {∇_a f / f, 2 ∇_a f f, e^f ∇_a f, x^(1+f) ∇_a x f + x^f ∇_a f Log[x]} *)

(* 연속 미분 *)
CD[la, lb, lc, F[ld, le]]
(* ∇_a ∇_b ∇_c F_de *)
```

#### 참고 (See Also)

`BD`, `LD`, `DefDerivativeOperator`, `CDtoBD`, `Metricg`, `Tscalar`

---

### LD (리 도함수 / Lie Derivative)

#### 함수 시그니처

```wolfram
LD[v, expr]
```

#### 설명 (Details)

LD type의 Lie 도함수이다. `v`는 벡터 이름(심볼)이다.

- 선형 연산자로 라이프니츠 규칙을 만족한다.
- `Kdelta`는 상수 텐서이다.
- `IndexedObject`의 `Log`나 `Power`는 `ScalarFunction`이다.
- `LD`의 Kind는 첫 번째 인자인 벡터의 Kind이다.
- **주의**: `LD[v, expr]`은 `expr`에 `BD`가 포함된 경우 제대로 정의되지 않는다.

#### 예제 (Examples)

```wolfram
{LD[v, v[la]], LD[v, v[ua]], LD[v, v[1]]}
(* {ℒ_v v_a, 0, ℒ_v v^1} *)

LD[v, RiemannCD[la, lb, ub, uc]]
(* -ℒ_v R_a^c *)

(* 라이프니츠 규칙 *)
c1 RicciCD[la, lb] + c2 F[la, lc] × RicciCD[uc, lb]
LD[v, %]
(* c1 ℒ_v R_ab + c2 F_ac ℒ_v R^c_b + c2 ℒ_v F_ac R^c_b *)

(* Kdelta 상수 *)
{Metricg[lb, uc], Metricg[lb, lc]}
LD[v, #] & /@ %
(* {0, ℒ_v g_bc} *)

(* 인자의 Kind를 고려. v가 DefaultKind일 때 *)
{LD[v, v[lA]], LD[v, v[uA]], LD[v, v[ua]]}
(* {ℒ_v v_A, ℒ_v v^A, 0} *)
```

#### 참고 (See Also)

`CD`, `BD`, `LDtoCD`, `DefDerivativeOperator`, `Tscalar`
