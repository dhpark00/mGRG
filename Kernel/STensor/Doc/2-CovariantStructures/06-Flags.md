# CovariantStructures — On/Off 플래그 (Flags for Tensorial Expressions)

`On`/`Off` 명령으로 텐서 표현식의 자동 처리 동작을 제어하는 플래그들이다.

---

### EvaluateBDFlag

#### 설명 (Details)

성분 입력에 대한 `BD` 연산을 자동으로 실행시키려면 `On` 시키고, 그렇지 않으면 `Off` 시킨다.

- 실제로 성분 입력에 대해 `BD` 연산을 실행하려면 `SetCoordinates`로 좌표계를 설정해야 한다.
- 성분 연산을 `DefaultKind`가 아닌 다른 Kind에서 실행시키려면 그 Kind 이름을 사용해야 한다: `BD[Capital][-1, fun[x]]`.

#### 예제 (Examples)

```wolfram
Off[EvaluateBDFlag]
BD[-1, fun[x]]
(* ∂_1 fun[x] *)

On[EvaluateBDFlag]
SetCoordinates[{t, x}]
{BD[-1, fun[x]], BD[-2, fun[x]]}
(* {0, fun'[x]} *)

(* 다른 Kind *)
{BD[Capital][-1, fun[x]], BD[Capital][-2, fun[x]]}
(* {∂[Capital]_1 fun[x], ∂[Capital]_2 fun[x]}  -- Capital Kind에 좌표계가 없으므로 실행되지 않음 *)
```

#### 참고 (See Also)

`On`, `Off`, `BD`, `SetCoordinates`, `flagTable`

---

### KdeltaFlag

#### 설명 (Details)

`KdeltaFlag`이 `On`인 경우 `Kdelta` 텐서와의 인덱스 쌍(contracted pair)이 자동적으로 조정된다. 기본적으로는 `On`이다.

- 연산자가 있는 경우에도 `Kdelta`와의 인덱스 쌍이 조정된다.
- `Kdelta`의 인덱스 두 개가 모두 동일한 Kind에 있어야 재조정된다.

#### 예제 (Examples)

```wolfram
Off[KdeltaFlag]
{F[la, lb] × Kdelta[ub, lc], R[la, lb] × Kdelta[lc, ub]}
(* {F_ab δ^b_c, δ_c^b R_ab} *)

On[KdeltaFlag]
{F[la, lb] × Kdelta[ub, lc], R[la, lb] × Kdelta[lc, ub]}
(* {F_ac, R_ac} *)

(* 연산자 포함 *)
Kdelta[ub, ld] × CovD[la, F[lb, lc]]
(* ∇_a F_dc *)

Kdelta[ub, ld] × BD[la, F[lb, lc]]
(* ∂_a F_dc *)

(* 여러 개의 Kdelta *)
Kdelta[ua, lg] × Kdelta[ub, lf] × R4[la, lb, lc, ld]]]
(* R4_gfcd *)

(* 다른 Kind는 수축(contraction)되지 않음 *)
{F[la, lB] × Kdelta[uB, lc], R[la, ub] × Kdelta[uA, lB]}
(* {F_aA δ^A_c, R_a^b δ^A_B} *)
```

#### 참고 (See Also)

`On`, `Off`, `Kdelta`, `flagTable`

---

### MetricgFlag

#### 설명 (Details)

`DefaultKind`에서 기본 계량 텐서 `Metricg`를 허용하려면 `On` 시키고, 그렇지 않으면 `Off` 시킨다. 기본적으로는 `On`이다.

- `DefaultKind`에 새로운 계량 텐서를 도입하려면 먼저 `MetricgFlag`을 `Off` 시켜서 `Metricg`를 삭제해야 한다.

#### 예제 (Examples)

```wolfram
Off[MetricgFlag]
GetMetric /@ {Latin, Greek, Capital}
(* {Null, Null, Null} *)

{Metricg[la, lb], Epsilon[la, lb, lc]}
(* {Metricg[la, lb], ε_abc} — Metricg는 일반 심볼 *)

On[MetricgFlag]
GetMetric[Latin]
(* Metricg *)

{Metricg[la, lb], Epsilon[la, lb, lc]}
(* {g_ab, ε_abc} *)

GetSymmetry[Metricg]
(* GenSet[{Cycles[{{1, 2}}], 1}] — 대칭 *)
```

#### 참고 (See Also)

`On`, `Off`, `Metricg`, `flagTable`, `CoordinateBasisFlag`
