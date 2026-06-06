# Tech Note: 인덱스 올리기와 내리기 (Raising and Lowering Indices)

계량 텐서를 사용하여 텐서 인덱스를 올리고 내리는 워크플로를 다룬다. Absorb, Absorbg, PutMetric, PullOutMetric의 사용법과 옵션, 그리고 DualStar를 이용한 Hodge 쌍대 계산을 포함한다.

> 자세한 함수 설명은 `07-Absorb.md` 참고.

---

## 1. 개요 -- 인덱스 올리기/내리기의 원리

미분기하학에서 계량 텐서를 사용하여 공변 인덱스(lower, 아래 첨자)와 반변 인덱스(upper, 위 첨자)를 전환한다. mGRG에서는 두 가지 방향의 연산을 제공한다:

- **흡수 (Absorb)**: 표현식에 있는 rank-2 대칭 텐서를 인덱스에 흡수시킨다. 인덱스가 올라가거나 내려간다.
- **삽입 (PutMetric)**: 특정 인덱스에 계량 텐서를 곱하여 올리거나 내린다.

| 함수 | 작용 범위 | 방향 |
|------|-----------|------|
| Absorb / Absorbg | 전체 표현식 | 계량 텐서 제거 (인덱스에 흡수) |
| PutMetric | 하나의 인덱스 | 계량 텐서 삽입 (인덱스 전환) |
| PullOutMetric | 전체 표현식 | 텐서의 인덱스를 정의 시의 기본 위치로 되돌림 |

---

## 2. Absorb를 사용한 일괄 흡수

`Absorb[expr, g]`는 표현식에서 rank-2 대칭 텐서 `g`를 찾아 인덱스에 흡수시킨다. 계량 텐서뿐 아니라 **임의의 rank-2 대칭 텐서**에 사용할 수 있다.

```wolfram
Tdefine[g, "+ba"]
Tdefine[F, "-ba"]

(* 기본 사용 *)
{F[la, lb] * g[ub, uc], RicciCD[la, lb] * g[ua, ub]}
Absorb[%, g]
(* {F_a^c, R} *)

(* 여러 계량 텐서를 한 번에 흡수 *)
R4[la, lb, lc, ld] * g[ua, ue] * g[ub, uf]
Absorb[%, g]
(* R4^ef_cd *)

(* 합(Plus)에 대한 Absorb *)
(R[la, lb] + F[la, lb]) g[ua, ub]
Absorb[%, g]
(* F_a^a + R_a^a *)
```

Absorb는 축약(contraction)이 가능한 인덱스 쌍을 자동으로 찾아 흡수한다. 축약이 불가능한 경우에는 변화가 없다.

---

## 3. Absorbg -- Metricg 전용 단축 명령

`Absorbg[expr]`는 `Absorb[expr, Metricg]`의 단축 명령이다. DefaultKind의 기본 계량 텐서인 Metricg를 흡수한다.

```wolfram
(* Absorbg = Absorb[expr, Metricg] *)
{F[la, lb] * Metricg[ub, uc], RicciCD[la, lb] * Metricg[ua, ub]}
Absorbg[%]
(* {F_a^c, R} *)
```

`MetricgFlag`가 `On`이어야 동작한다 (기본 상태에서는 항상 `On`).

---

## 4. PutMetric -- 특정 인덱스 올리기/내리기

`PutMetric[expr, idx]`는 표현식의 특정 인덱스에 계량 텐서를 삽입하여 올리거나 내린다. Absorb와 반대 방향의 연산이다.

```wolfram
Tdefine[T, "*"]; Tdefine[v, 1]
expr = T[ub, lc, ld, lb]
(* T^a_cda  -- 출력 시에 ResetDummies가 자동 호출되어 인덱스가 조정됨 *)

(* ua 인덱스를 내리기 *)
PutMetric[expr, ua]
(* g^ab T_bcda *)

% // Absorbg
(* g^ab T_bcda -> T^a_cda *)

(* la 인덱스를 올리기 *)
PutMetric[expr, la]
(* g_ab T^a_cd^b *)
```

연산자가 있는 경우에도 사용할 수 있다:

```wolfram
(* 공변 도함수가 있는 표현식 *)
CD[ua, CD[ub, T[la, lb, lc, ud]]]
PutMetric[%, la]
PutMetric[%%, ub]
```

**주의사항**: PutMetric의 두 번째 인자인 인덱스 이름은 `ResetDummies`가 자동 호출된 **이후**의 출력 기준으로 결정된다. 화면에 표시된 인덱스 이름을 기준으로 지정해야 한다.

---

## 5. PullOutMetric -- 기본 위치로 되돌리기

`PullOutMetric[expr]`은 텐서의 인덱스를 정의 시의 기본 위치(default slot position)로 되돌린다. 기본 위치가 아닌 인덱스에는 계량 텐서가 명시적으로 나타난다.

```wolfram
(* 두 인덱스 모두 기본 위치가 위 첨자인 T를 정의 *)
Tdefine[T[ua, ub]]

(* 기본 위치가 위 첨자인 T를 아래로 놓으면 *)
T[la, ub]
% // PullOutMetric
(* g_ac T^cb — 계량 텐서가 명시적으로 나타남 *)

% // Absorbg
(* T_a^b — 다시 흡수하면 원래대로 *)

T[la, lb]
% // PullOutMetric
(* g_ac g_bd T^cd *)

% // Absorbg
(* T_ab *)
```

BD 등의 연산자에도 적용된다:

```wolfram
(* BD의 인덱스 *)
BD[lc, T[ua, ub]]
% // PullOutMetric
(* ∂_c T^ab — 이미 기본 위치이므로 변화 없음 *)

BD[uc, T[ua, ub]]
% // PullOutMetric
(* g^cd ∂_d T^ab *)

% // Absorbg
(* ∂^c T^ab *)
```

---

## 6. Absorb와 PutMetric의 옵션 활용

### CovDs 옵션

BD와 LD는 기본적으로 공변 연산자가 아니므로 Absorb에서 통과하지 않는다. `CovDs -> {BD}`로 임시 포함할 수 있다.

```wolfram
g[ub, ud] * BD[la, F[lb, lc]]
(* BD는 공변 연산자가 아니므로 변화 없음 *)

Absorb[%, g, CovDs -> {BD}]
(* ∂_a F^d_c *)
```

CovDs 옵션 없이 같은 표현식을 처리하면, BD 내부의 인덱스는 흡수되지 않는다.

### IndexQs 옵션

특정 Kind의 인덱스만 대상으로 Absorb를 수행한다.

```wolfram
(RicciCD[lA, lb] + F[lA, lb]) Metricg[uA, uB]
Absorb[%, Metricg, IndexQs -> {KindIndexQ[Latin]}]
(* Latin Kind 인덱스만 흡수 *)
```

### HeadQs 옵션

특정 유형의 객체만 대상으로 지정한다.

```wolfram
(* 특정 텐서에만 Absorb 적용 *)
Absorb[expr, g, HeadQs -> {(# === F &)}]
```

---

## 7. DualStar -- Hodge 쌍대

`DualStar[expr, indices]`는 Epsilon 텐서를 사용하여 Hodge 쌍대를 계산한다.

```wolfram
Tdefine[A, "*-"]

(* 기본 사용 *)
DualStar[A[ua, lb], {lc, ld}]
(* 1/2 A^a_b ε^b_a cd  -- 입력한 인덱스 갯수가 총 4개이다 *)

(* 다른 rank *)
DualStar[A[ua, lb, ud, uc], {le}]
(* 1/24 A^a_b^d^c ε^b_a dce  -- 입력한 인덱스 갯수가 총 5개이다 *)
```

차원이 설정되어 있으면 인덱스 수의 유효성을 검사한다:

```wolfram
(* 차원 설정 시 유효성 검사 *)
SetDimension[4]
DualStar[A[ua, lb], {lc}]
(* $Failed — 인덱스 겟수가 4개가 아니므로 부적합 *)

DualStar[A[ua, lb], {lc, ld}]
(* 1/2 A^a_b ε^b_a cd — 유효 *)
ClearDimension[]
```

다른 Kind에서의 사용:

```wolfram
(* 다른 Kind *)
Tdefine[CA, "*", Capital]
DualStar[CA[uA], {lB}, Capital]
(* CA^A ε[Capital]_A^B *)
```

---

## 8. 실전 워크플로

### 아인슈타인 텐서 구성과 인덱스 조작

```wolfram
(* 아인슈타인 텐서를 위한 사용자 함수 정의 *)
EinsteinG[la_, lb_] := RicciCD[la, lb] - 1/2 Metricg[la, lb] * ScalarCD[]

(* 인덱스 하나 올리기 *)
EinsteinG[la, lb] * Metricg[ua, uc]
Absorbg[%]
(* R^c_b - 1/2 δ^c_b R *)

(* 양쪽 다 올리기 *)
EinsteinG[la, lb] * Metricg[ua, uc] * Metricg[ub, ud]
Absorbg[%]
(* R^cd - 1/2 g^cd R *)
```

### PutMetric을 사용한 단계별 조작

특정 인덱스만 선택적으로 올리거나 내릴 때는 PutMetric을 사용한다.

```wolfram
(* Riemann 텐서의 특정 인덱스만 조작 *)
RiemannCD[la, lb, lc, ud]

(* 4번째 인덱스를 내리기 *)
PutMetric[%, ud]
(* g^de R_abce *)

% // Absorbg
(* R_abc^d *)
```

---

## 요약

1. **Absorb는 rank-2 대칭 텐서를 표현식에 흡수시킨다** -- 계량 텐서뿐 아니라 임의의 rank-2 대칭 텐서에 사용 가능.
2. **Absorbg는 `Absorb[expr, Metricg]`의 단축 명령이다.**
3. **PutMetric은 하나의 인덱스에 대해 계량 텐서를 삽입한다** -- Absorb와 반대 방향.
4. **PullOutMetric은 텐서의 인덱스를 정의 시의 기본 위치로 되돌린다.**
5. **CovDs 옵션으로 BD/LD를 공변 연산자로 임시 포함할 수 있다.**
6. **IndexQs 옵션으로 특정 Kind의 인덱스만 대상으로 할 수 있다.**
7. **DualStar는 Hodge 쌍대를 계산한다** -- Epsilon 텐서를 사용한다.
