# CovariantStructures — 기본 텐서 (Pre-defined Tensors)

`mGRG`STensor`` 패키지의 `CovariantStructures.m`에서 제공하는 기본 텐서들이다. `Kdelta`, `Epsilon`, `Torsion`, `Structuref`는 각각의 Kind마다 `DefKind` 명령으로부터 생성된다.

---

### Kdelta

#### 함수 시그니처

```wolfram
Kdelta[lowerIdx, upperIdx]
Kdelta[upperIdx, lowerIdx]
```

#### 설명 (Details)

크로네커 델타 텐서이다.

- `Kdelta`는 모든 Kind에서 사용 가능하다.
- `Kdelta` 인덱스는 '아래-위' 또는 '위-아래' 첨자인 경우만 의미가 있다. 계량 텐서의 인덱스가 '아래-위' 또는 '위-아래'이면 자동으로 `Kdelta`로 바뀐다.
- `Kdelta` 인덱스가 '아래-아래' 또는 '위-위'이면 잘못된 표현으로 간주한다 (`SyntaxCheck`에서 경고).
- `Kdelta`는 상수 텐서이다: 모든 미분 연산자에 대해 0을 반환한다.
- `Kdelta`의 성분 값은 대각선이 아닌 영역에서는 0이고, 대각선 요소의 값은 +1이다.
- `Kdelta`의 인덱스 순서는 의미가 없다: $\delta_a{}^b \equiv \delta^b{}_a$.

#### 예제 (Examples)

```wolfram
Table[Kdelta[-i, j], {i, 3}, {j, 3}] // MatrixForm
(* 3×3 단위 행렬 *)

{Metricg[la, lb], Metricg[la, ub], Metricg[ua, lb], Metricg[uA, lb], Metricg[ua, ub]}
(* {g_ab, δ_a^b, δ^a_b, g^A_b, g^ab} *)

(* 상수 텐서 확인 *)
{CD[la, Kdelta[lb, uc]], BD[la, Kdelta[lb, uc]], LD[v, Kdelta[lb, uc]]}
(* {0, 0, 0} *)
```

#### 참고 (See Also)

`Metricg`, `DefMetric`, `Epsilon`

---

### Epsilon

#### 함수 시그니처

```wolfram
Epsilon[la, lb, lc, ld]
```

#### 설명 (Details)

Levi-Civita 텐서(체적 형식, volume form)이다.

- `DefaultKind`에서의 이름은 `Epsilon`이지만, 각 Kind마다 그에 따른 이름을 갖는다: 예로 `Greek`가 Kind로 정의되었으면  그 이름은 `EpsilonGreek`이다.
- Epsilon 텐서는 rank가 `DefaultKind`의 차원과 동일한 완전 반대칭 텐서이다. `DefaultKind`의 차원이 설정되지 않았으면 임의의 rank를 갖는다.
- `Metricg`와 `Epsilon`은 `CD`에 대해 공변 상수이다.
- Volume-form에 대해서는 시공간에 차원이 설정되었고, 그 차원과 인덱스의 갯수가 일치한 경우에만 공변 도함수가 역할을 한다.

#### 예제 (Examples)

```wolfram
{Metricg[la, lb], Epsilon[la, lb, lc, ld]}
(* {g_ab, ε_abcd} *)

SetDimension[4]
CD[la, #] & /@ {Metricg[lb, lc], Epsilon[lb, lc, ld], Epsilon[lb, lc, ld, le]}
(* {0, ∇_a ε_bcd, 0} *)
```

#### 참고 (See Also)

`GetEpsilon`, `Metricg`, `DefKind`, `SetDimension`

---

### Torsion

#### 함수 시그니처

```wolfram
Torsion[la, lb, uc]
```

#### 설명 (Details)

비틀림 텐서(Torsion tensor)이다. 각각의 Kind마다 `DefKind` 명령으로부터 생성된다.

- `TorsionFreeQ`가 `True`인 미분 연산자에서는 torsion이 나타나지 않는다.
- `DefaultKind`에서의 이름은 `Torsion`이지만, 각 Kind마다 그에 따른 이름을 갖는다: 예로 `Greek`가 Kind로 정의되었으면  그 이름은 `TorsionGreek`이다.

#### 예제 (Examples)

```wolfram
{Torsion[la, lb, uc], TorsionGreek[lμ, lν, uρ]}
(* {t_ab^c, t[Greek]_μν^ρ} *)
```

#### 참고 (See Also)

`TorsionFreeQ`, `DefDerivativeOperator`, `Structuref`

---

### Structuref

#### 함수 시그니처

```wolfram
Structuref[la, lb, uc]
```

#### 설명 (Details)

구조 상수(Structure constants)이다. 좌표 기준이 아닐 때에만 `IndexedObject`로 존재한다.

- 좌표 기준(Coordinate Basis)에서는 구조 상수가 0이므로 비활성 상태이다.
- `CoordinateBasisFlag`를 `Off`하면 구조 상수가 활성화된다.

#### 예제 (Examples)

```wolfram
Off[CoordinateBasisFlag[Latin]]
Structuref[la, lb, uc]
(* f_ab^c *)

On[CoordinateBasisFlag[Latin]]
Structuref[la, lb, uc]
(* Structuref[la, lb, uc]  — 좌표 기준에서는 비활성 *)
```

#### 참고 (See Also)

`CoordinateBasisQ`, `Torsion`, `DefKind`

---

### Metricg

#### 함수 시그니처

```wolfram
Metricg[la, lb]
Metricg[ua, ub]
Metricg[la, ub]
```

#### 설명 (Details)

기본 계량 텐서이다. `Metricg`와 `Epsilon`은 항상 `DefaultKind`에 속한다.

- `DefaultKind`를 변경하면 `CD`, `Metricg`, `Epsilon`도 변경된 `DefaultKind`에 속하게 된다.
- `Metricg`의 인덱스가 '위-아래' 또는 '아래-위'이면서 적합한 Kind이면 자동으로 `Kdelta`로 변한다.
- `Metricg[ua, lb]` → $\delta^a{}_b$ (같은 Kind), `Metricg[la, uB]` → $g_a{}^B$ (다른 Kind).
- `Metricg`는 `CD`에 대해 공변 상수이다. 그러나 다른 Kind의 인덱스에 대해서는 공변 상수가 아니다.

#### 예제 (Examples)

```wolfram
{Metricg[la, lb], Metricg[ua, lb], Metricg[ua, ub]}
(* {g_ab, δ^a_b, g^ab} *)

Metricg[-1, 2]
(* g_1^2 *)

CD[lc, #] & /@ {Metricg[la, lb], Metricg[lA, lB]}
(* {0, ∇_c g_AB} *)
```

#### 참고 (See Also)

`DefMetric`, `SetMetricCompatible`, `DefKind`, `Kdelta`, `Epsilon`
