# CovariantStructures — DefaultKind 설정 (SetDefaultKind and KindOf)

`mGRG`STensor`` 패키지의 `CovariantStructures.m`에서 제공하는 DefaultKind 설정 및 Kind 조회 함수들이다.

---

### SetDefaultKind

#### 함수 시그니처

```wolfram
SetDefaultKind[kind]
```

#### 설명 (Details)

모든 후속 연산에 대한 기본 Kind를 설정한다. 이 설정은 어떤 인덱스, 계량 텐서, 도함수가 기본으로 사용되는지에 영향을 준다.

- `DefaultKind`의 기본값은 `Latin`으로 설정되어 있다.
- `DefaultKind`를 변경하면 `CD`, `Metricg`, `Epsilon`도 그 Kind를 따라간다.
- `KindOf /@ {CD, Metricg, Epsilon}` 결과가 `DefaultKind`에 따라 바뀐다.

#### 예제 (Examples)

```wolfram
DefaultKind
(* Latin *)

mGRG`STensor`Private`getDerOperators[DefaultKind]
(* {CD} *)

{MetricSpaceQ[DefaultKind], GetMetric[DefaultKind]}
(* {True, Metricg} *)

SetDefaultKind[Greek]
DefaultKind
(* Greek *)

KindOf /@ {CD, Metricg, Epsilon}
(* {Greek, Greek, Greek} *)

(* 기본 설정으로 복귀 *)
SetDefaultKind[Latin]
```

#### 참고 (See Also)

`DefaultKind`, `KindOf`, `DefKind`, `CD`, `Metricg`, `Epsilon`

---

### KindOf

#### 함수 시그니처

```wolfram
KindOf[obj]
KindOf[obj, pos]
KindOf[obj[indices], idx]
```

#### 설명 (Details)

객체 `obj`의 Kind를 반환한다. 두 번째 인자 `pos`가 주어지면 해당 인덱스 위치의 Kind를 반환한다.

- `T[a,b]`와 같은 인덱스 표현식에서 `KindOf[T[a,b], a]`는 인덱스 `a`의 Kind를 반환한다.
- 객체의 종류에 따라 Kind 결정 방식이 다르다.

##### Kdelta

Kdelta 자체의 Kind는 `All`이다 (모든 Kind에서 사용). 그러나 실제 `Kdelta`의 Kind는 사용한 인덱스로부터 결정된다.

```wolfram
{KindOf[Kdelta[la, ub], la], KindOf[Kdelta[la, ub], ub], KindOf[Kdelta[la, ub], lc]}
(* {Latin, Latin, All} *)

{KindOf[Kdelta], KindOf[Kdelta, la], KindOf[Kdelta, lA]}
(* {All, Latin, Capital} *)
```

##### Epsilon and Metricg

항상 `DefaultKind`에 속한다.

```wolfram
(* DefaultKind가 Capital인 상태 *)
{KindOf[Metricg], KindOf[Metricg, 2], KindOf[Metricg, 3]}
(* {Capital, Capital, Capital} *)

{KindOf[Epsilon], KindOf[Epsilon, 2], KindOf[Epsilon, 3]}
(* {Capital, Capital, Capital} *)
```

##### Operand (DefTensor로 정의한 텐서)

정의한 바대로 Kind를 유추한다.

```wolfram
DefTensor[H[la, lμ]]
{KindOf[H[la, lμ], la], KindOf[H[la, lμ], lμ]}
(* {Latin, Greek, Latin} *)

KindOf[H[la, lμ], lC]
(* Latin -- 첫 번째 인자의 Kind *)

(* 두 번째 인자가 숫자이면 그 숫자에 해당하는 인덱스의 Kind *)
{KindOf[H], KindOf[H, 2]}
(* {Latin, Greek} *)
```

##### BD

`Kdelta`와 동일하게 모든 Kind에서 사용한다. `BD`의 Kind는 사용한 인덱스 Kind로 결정한다.

```wolfram
{KindOf[BD], KindOf[BD, la], KindOf[BD, lμ]}
(* {All, Latin, Greek} *)
```

##### CD

`CD` 연산자는 항상 `DefaultKind`에 속한다.

```wolfram
(* DefaultKind가 Capital인 상태 *)
{KindOf[CD], KindOf[CD, la], KindOf[CD, lμ], KindOf[CD, 1], KindOf[CD, 2]}
(* {Capital, NonKind, NonKind, Capital, Capital} *)
```

##### Operator (LD type이 아닌)

내부 함수 `defineOperator`로 연산자를 정의할 때 설정한 Kind이다.

##### LD type Operator

첫 번째 인자가 LD type의 '연산자 이름'이면 두 번째 인자의 Kind로 결정한다.

#### 참고 (See Also)

`DefaultKind`, `IndexToKind`, `DefKind`, `SetDefaultKind`
