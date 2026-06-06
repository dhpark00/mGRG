# CovariantStructures — 미분 연산자 정의 (Derivative Operators)

`mGRG`STensor`` 패키지의 `CovariantStructures.m`에서 제공하는 미분 연산자 정의 및 관련 함수들이다.

---

### DerivativeOperatorQ

#### 함수 시그니처

```wolfram
DerivativeOperatorQ[opName]
```

#### 설명 (Details)

`opName`이 `DefDerivativeOperator`로 정의된 미분 연산자인지 묻는다. 정의된 미분 연산자이면 `True`, 아니면 `False`를 반환한다.

- 기본 공변 도함수 `CD`는 항상 `True`를 반환한다.
- `BD`(편미분)와 `LD`(리 도함수)는 `DefDerivativeOperator`로 정의된 것이 아니므로 `False`를 반환한다.

#### 예제 (Examples)

```wolfram
DerivativeOperatorQ /@ {CD, BD, LD}
(* {True, False, False} *)

DefDerivativeOperator[CovD, "D"]
DerivativeOperatorQ[CovD]
(* True *)

UndefDerivativeOperator[CovD]
DerivativeOperatorQ[CovD]
(* False *)
```

#### 참고 (See Also)

`DefDerivativeOperator`, `UndefDerivativeOperator`, `CD`, `BD`, `LD`

---

### DefDerivativeOperator

#### 함수 시그니처

```wolfram
DefDerivativeOperator[covD, prtStr, kind, opts]
```

#### 설명 (Details)

CD type의 미분 연산자를 정의한다. 인자는 연산자 이름, 옵션으로 출력을 위한 문자열, 그리고 연산자가 속한 Kind이다.

- `prtStr`은 출력 형식에 사용할 문자열이다. 생략하면 연산자 이름을 기본 출력으로 사용한다.
- `kind`는 연산자가 속한 Kind이다. 생략하면 `DefaultKind`를 사용한다.
- 옵션으로 `TorsionFreeQ`를 지정할 수 있다. 기본값은 `True`이다.
- 정의 시 관련 `IndexedObject`가 자동으로 생성된다: `GammaCovD`, `RiemannCovD`, `RicciCovD`. Kind에 계량 텐서가 있고 차원이 설정되어 있으면 `ScalarCovD`도 정의된다.
- 정의되는 연산자는 선형 미분 연산자이고, 라이프니츠 규칙을 만족한다.
- 크로네커 델타는 상수 텐서이다: `CovD[la, Kdelta[lb, uc]]` → `0`.
- 연속된 미분 연산자는 인덱스를 연속해서 입력한다: `CovD[la, ub, RicciCovD[lc, ud]]` → `CovD[la, CovD[ub, RicciCovD[lc, ud]]]`.

#### 예제 (Examples)

```wolfram
DefDerivativeOperator[CovD, "D"]
CovD[la, T[lb, lc]]
(* D_a T_bc *)

(* 관련 텐서 자동 정의 확인 *)
{GammaCovD[la, lb, uc], RiemannCovD[la, lb, lc, ud], RicciCovD[la, lb]}

(* Kind 지정 *)
DefDerivativeOperator[GCovD, "D", Greek]

(* TorsionFreeQ 옵션 *)
DefDerivativeOperator[CovD, "D", TorsionFreeQ -> False]
TorsionFreeQ[CovD]
(* False *)
```

#### 참고 (See Also)

`UndefDerivativeOperator`, `DerivativeOperatorQ`, `TorsionFreeQ`, `CD`

---

### UndefDerivativeOperator

#### 함수 시그니처

```wolfram
UndefDerivativeOperator[covD]
```

#### 설명 (Details)

정의된 미분 연산자를 제거한다. 연산자에 연결된 `Gamma`, `Riemann`, `Ricci`, `Scalar` 텐서도 함께 제거된다.

- 기본적인 공변 도함수인 `CD`는 제거하지 못한다 (예약된 이름).

#### 예제 (Examples)

```wolfram
UndefDerivativeOperator[CovD]
DerivativeOperatorQ[CovD]
(* False *)

UndefDerivativeOperator[CD]
(* Msg: Reserved name CD cannot be removed *)
```

#### 참고 (See Also)

`DefDerivativeOperator`, `DerivativeOperatorQ`, `CD`

---

### TorsionFreeQ

#### 함수 시그니처

```wolfram
TorsionFreeQ[covD]
```

#### 설명 (Details)

미분 연산자 `covD`가 torsion-free인지 묻는다. `True`이면 torsion이 없고, `False`이면 torsion이 있다.

- `DefDerivativeOperator`로 미분 연산자를 정의할 때 기본적으로 `TorsionFreeQ -> True`를 가정한다. `TorsionFreeQ -> False` 옵션으로 변경 가능하다.
- Torsion이 있는 경우 Affine Connection과 리치 텐서는 아무런 대칭도 없다.

#### 예제 (Examples)

```wolfram
DefDerivativeOperator[CovD, "D"]
TorsionFreeQ[CovD]
(* True *)

DefDerivativeOperator[CovD, "D", TorsionFreeQ -> False]
TorsionFreeQ[CovD]
(* False *)

(* Torsion이 있을 때 대칭성 확인 *)
GetSymmetry /@ {GammaCovD, RicciCovD}
(* {GenSet[], GenSet[]}  — 대칭 없음 *)
```

#### 참고 (See Also)

`DefDerivativeOperator`, `Torsion`, `GammaCD`, `RicciCD`

---

### CoordinateBasisQ

#### 함수 시그니처

```wolfram
CoordinateBasisQ[kind]
```

#### 설명 (Details)

지정한 `kind`에 연결된 기저가 좌표 기준(Coordinate Basis)인지 묻는다.

- `MetricSpaceQ`와 `CoordinateBasisQ`는 Kind에 속한 성질이다.
- 기본적으로 정의된 Latin Kind에는 계량 텐서 `Metricg`가 있고, 좌표 기준(Coordinate Basis)으로 설정되었다.
- 좌표 기준이 아닌 경우 구조 상수 `Structuref`가 활성화된다.

#### 예제 (Examples)

```wolfram
CoordinateBasisQ /@ {Latin, Capital}
(* {True, False} *)
```

#### 참고 (See Also)

`MetricSpaceQ`, `DefDerivativeOperator`, `CD`, `Structuref`
