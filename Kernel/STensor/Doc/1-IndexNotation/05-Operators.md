# IndexNotation — 연산자 및 특수 심볼 (Operators and Special Symbols)

연산자는 CD(공변 도함수), LD(리 도함수), XD(외미분), XP(외적) 네 가지 타입이 있다. 각 타입에 따라 인자의 형태와 출력이 다르다.

---

## 연산자 타입

새로운 연산자를 (내부 함수 `defineOperator`로) 정의할 때 세 번째 인자로 사용하는 연산자 타입이다. 연산자 타입에 따라 인자 구조와 출력 형태가 결정된다. 그러나, 각각의 연산자가 피연산자에 작용하는 실제 방식은 따로이 정의해야 한다.

---

### CD Type (공변 도함수형)

#### 설명 (Details)

첫 번째 인자는 인덱스, 두 번째 인자가 피연산자인 연산자 타입이다. Kind를 지정하지 않으면 `DefaultKind`가 사용된다.

#### 예제 (Examples)

```wolfram
mGRG`STensor`Private`defineOperator[CovD, "\[Del]", CD]
CovD[la, T[ua, ub]]
(* ∇_a T^ab *)

(* 다른 Kind의 연산자 *)
mGRG`STensor`Private`defineOperator[BasisD, "D", CD, Greek]
BasisD[lμ, T[ua, ub]]
(* D_μ T^ab *)
```

---

### LD Type (리 도함수형)

#### 설명 (Details)

첫 번째 인자는 벡터 이름(심볼)이고, 두 번째 인자가 피연산자이다. 인덱스가 붙은 형태가 아닌 벡터의 이름만을 사용한다. LD 연산자의 Kind는 첫 번째 인자(벡터)의 Kind와 동일하다.

#### 예제 (Examples)

```wolfram
mGRG`STensor`Private`defineOperator[LieD, "\[ScriptCapitalL]", LD]
Tdefine[V, 1, PrintAs -> "ξ"]
LieD[V, T[ua, ub]]
(* ℒ_V T^ab *)
```

---

### XD Type (외미분형)

#### 설명 (Details)

인자로 피연산자만 있는 연산자 타입으로, 굵은 글꼴로 출력된다.

#### 예제 (Examples)

```wolfram
mGRG`STensor`Private`defineOperator[BOX, "□", XD]
BOX[T[ua, ub]]
(* □ T^ab *)
```

---

### XP Type (외적형)

#### 설명 (Details)

여러 개의 피연산자가 있는 연산자 타입이다. XP 타입 연산자의 출력 형태는 자동으로 정의되지 않으므로 별도로 `MakeBoxes`를 정의해야 한다.

#### 예제 (Examples)

```wolfram
mGRG`STensor`Private`defineOperator[ExtP, "∧", XP]
ExtP /: MakeBoxes[ExtP[args__], StandardForm] := MakeBoxes[Wedge[args]]
ExtP[T[ua, ub], S[lc, ld]]
(* T^ab ∧ S_cd *)
```

---

### defineOperator

#### 함수 시그니처

```wolfram
mGRG`STensor`Private`defineOperator[opName, printStr, opType]
mGRG`STensor`Private`defineOperator[opName, printStr, opType, kind]
```

#### 설명 (Details)

세 번째 인자로 주어진 연산자 타입의 연산자를 새로 정의하는 내부 함수이다.

- `opName`은 연산자의 심볼 이름이다.
- `printStr`은 출력 시 사용할 문자열이다 (예: `"\[Del]"`, `"\[ScriptCapitalL]"`).
- 연산자 타입(`opType`)은 `CD`, `LD`, `XD`, `XP` 중 하나이다.
- `kind`를 지정하지 않으면 `DefaultKind`가 사용된다.
- 정의된 연산자에 대해 `IndexedObjectQ`와 `IndexedOperatorQ`가 `True`로 설정된다.

#### 참고 (See Also)

`CD`, `LD`, `XD`, `XP`, `IndexedOperatorQ`

---

## 사전 정의된 연산자

---

### CD

#### 함수 시그니처

```wolfram
CD[index, expr]
```

#### 설명 (Details)

기본 공변 도함수 연산자이다.

- `index`는 하첨자 또는 (계량 텐서가 설정된 경우) 상첨자 인덱스이다.
- `expr`은 피연산자(텐서 표현식)이다.
- `DefaultKind`에 속한다.
- 출력 형태는 `∇`이다.
- `SetDefaultKind[]` 호출 시 자동으로 정의된다.
- 메트릭 호환성: `CD[index, Metricg[a, b]]`는 기본적으로 `0`이 되도록 설정되었다 (메트릭 호환).

#### 예제 (Examples)

```wolfram
CD[la, T[ub]]
(* ∇_a T^b *)

CD[ua, T[lb, lc]]
(* ∇^a T_bc *)
```

#### 참고 (See Also)

`BD`, `LD`, `CDtoBD`, `defineOperator`

---

### BD

#### 함수 시그니처

```wolfram
BD[index, expr]
BD[kind][index, expr]
```

#### 설명 (Details)

기저 도함수(편미분) 연산자이다.

- Kind가 `All`로 설정되어 있어 모든 Kind에서 사용 가능하다.
- 좌표 기저(`CoordinateBasisQ`가 `True`)에서는 편도함수 `∂`로 표시된다.
- 비좌표 기저에서는 $\hat{\partial}$ (hat 기호 포함)로 표시된다.
- `BD[kind][index, expr]`로 특정 Kind를 지정할 수 있다.
- `EvaluateBDFlag`가 `On`이면 텐서 성분으로 간주하고, (가능하다면) 그 값을 평가된다.

#### 예제 (Examples)

```wolfram
BD[la, T[ub]]
(* ∂_a T^b  (좌표 기저일 때) *)
(* ∂̂_a T^b  (비좌표 기저일 때) *)

BD[Greek][lμ, T[ua, ub]]
(* ∂[Greek]_μ T^ab *)
```

#### 참고 (See Also)

`CD`, `CDtoBD`, `EvaluateBDFlag`, `CoordinateBasisFlag`

---

### LD

#### 함수 시그니처

```wolfram
LD[vector, expr]
```

#### 설명 (Details)

리 도함수 연산자이다.

- `vector`는 벡터의 이름(심볼)이다. 인덱스가 붙은 형태가 아니다.
- `expr`은 피연산자(텐서 표현식)이다.
- Kind는 첫 번째 인자(벡터)의 Kind와 동일하다.
- 출력 형태는 `ℒ`이다.
- **주의**: `expr`에 `BD`가 포함되면 (적절한 텐서 표현이 아니어서) 제대로 동작하지 않는다. 사용 전에 `FreeQ[expr, BD]`로 확인할 것.

#### 예제 (Examples)

```wolfram
DefTensor[v[la]]
LD[v, T[ua, ub]]
(* ℒ_v T^ab *)

(* BD가 포함된 경우 — 주의 *)
FreeQ[expr, BD]  (* True인지 확인 후 사용 *)
LD[v, expr]
```

#### 참고 (See Also)

`CD`, `LDtoCD`, `defineOperator`

---

### XD

#### 함수 시그니처

```wolfram
XD[expr]
```

#### 설명 (Details)

외미분(exterior derivative) 연산자이다.

- `expr`은 미분 형식(differential form) 표현식이다.
- 인덱스 인자가 없으며, 피연산자만 받는다.
- 출력 형태는 굵은 `d`이다.
- `DiffForm.m`에서 정의된다.

#### 예제 (Examples)

```wolfram
DefForm[omega[la], 1, PrintAs -> "\[Omega]"]
XD[omega[la]]
(* d ω_a *)
```

#### 참고 (See Also)

`XP`, `ApplyXD`, `CoXD`, `DegreeForm`

---

### XP

#### 함수 시그니처

```wolfram
XP[arg1, arg2, ...]
```

#### 설명 (Details)

외적(exterior/wedge product) 연산자이다.

- 여러 개의 미분 형식을 인자로 받는다.
- `DiffForm.m`에서 정의된다.
- Mathematica의 `Wedge`는 자동으로 `XP`로 변환된다.

#### 예제 (Examples)

```wolfram
XP[omega[la], sigma[lb]]
(* ω_a ∧ σ_b *)

(* Wedge 표기와 호환 *)
Wedge[omega[la], sigma[lb]]
(* XP[omega[la], sigma[lb]]로 변환 *)
```

#### 참고 (See Also)

`XD`, `DegreeForm`, `CollectForm`

---

## 특별하게 사전 정의된 텐서

---

### Kdelta

#### 함수 시그니처

```wolfram
Kdelta[up, dn]
```

#### 설명 (Details)

크로네커 델타 텐서이다.

- Kind는 `All`이다 (모든 Kind에서 작동).
- 성분 인덱스를 넣으면 Mathematica 심볼인 `KroneckerDelta`로 평가된다.
- `KdeltaFlag`가 `On`이면 `Kdelta`를 이용한 인덱스 축약이 자동으로 수행된다 (기본값: `On`).
- 출력 형태는 `δ`이다.

#### 예제 (Examples)

```wolfram
KindOf[Kdelta]
(* All *)

Kdelta[la, ub]
(* δ_a^b *)

(* 성분 인덱스 *)
Kdelta[1, -2]
(* KroneckerDelta[1, 2] => 0 *)

Kdelta[1, -1]
(* KroneckerDelta[1, 1] => 1 *)
```

#### 참고 (See Also)

`KdeltaFlag`, `KdeltaSumRule`, `Metricg`

---

### Metricg

#### 함수 시그니처

```wolfram
Metricg[dn, dn]
```

#### 설명 (Details)

기본 메트릭 텐서이다.

- Kind는 `DefaultKind`이다.
- 대칭성: `Metricg[a, b] = Metricg[b, a]`이다 (대칭 텐서).
- `SetDefaultKind[]` 호출 시 자동으로 정의된다.
- `MetricgFlag`가 `On`이면 메트릭이 활성화된다 (기본값: `On`).
- CD와 메트릭 호환: 기본적으로 `CD[index, Metricg[a, b]] = 0`으로 설정된다. `ClearMetricCompatible`로 취소할 수 있다.
- 출력 형태는 `g`이다.

#### 예제 (Examples)

```wolfram
Metricg[la, lb]
(* g_ab *)

Metricg[ua, ub]
(* g^ab *)

(* 공변 도함수와의 호환성 *)
CD[la, Metricg[lb, lc]]
(* 0 *)
```

#### 참고 (See Also)

`Kdelta`, `MetricgFlag`, `DefMetric`, `GetMetric`, `Absorbg`

---

### Epsilon

#### 함수 시그니처

```wolfram
Epsilon[idx, idx, ...]
```

#### 설명 (Details)

레비-치비타 텐서(volume-form)이다.

- Kind는 `DefaultKind`이다.
- 완전 반대칭 텐서이다.
- 차원이 설정되면 해당 차원의 rank를 가진다. 차원이 미설정이면 임의 rank(`"*-"`)이다.
- 다른 Kind에 대해서는 `DefKind`를 통해 별도로 정의된다 (`SymbolJoin[Epsilon, kind]`).
- `GetEpsilon[kind]`로 특정 Kind의 레비-치비타 텐서를 얻을 수 있다.
- CD와 호환: `CD[index, Epsilon[...]] = 0`이다 (공변 상수).
- 출력 형태는 `ε`이다.

#### 예제 (Examples)

```wolfram
SetDimension[4]
Epsilon[la, lb, lc, ld]
(* ε_abcd *)

(* Kind를 지정한 경우 *)
GetEpsilon[Latin]
(* DefaultKind가 Latin이면 Epsilon, 그렇지 않으면 EpsilonLatin *)
```

#### 참고 (See Also)

`GetEpsilon`, `EpsilonProductRule`, `Metricg`

---

### Structuref

#### 함수 시그니처

```wolfram
Structuref[dn, dn, up]
```

#### 설명 (Details)

비좌표 기저의 구조 상수 텐서이다.

- Kind는 `DefaultKind`이다.
- 반대칭 텐서이다 (하첨자 두 개에 대해).
- `CoordinateBasisQ`가 `True`이면 정의되지 않는다 (좌표 기저에서 구조 상수는 0).
- `CoordinateBasisFlag`를 `Off`로 설정해야 비좌표 기저 모드가 된다.
- `GetStructuref[kind]`로 특정 Kind의 구조 상수를 얻을 수 있다.
- 출력 형태는 `f`이다.

#### 예제 (Examples)

```wolfram
Off[CoordinateBasisFlag]
Structuref[la, lb, uc]
(* f_ab{}^c *)

On[CoordinateBasisFlag]
Structuref[la, lb, uc]
(* Structuref[la, lb, uc]  — 평가되지 않음 *)
```

#### 참고 (See Also)

`CoordinateBasisFlag`, `GetStructuref`, `Torsion`

---

### Torsion

#### 함수 시그니처

```wolfram
Torsion[dn, dn, up]
```

#### 설명 (Details)

비틀림 텐서이다.

- Kind는 `DefaultKind`이다.
- 반대칭 텐서이다 (하첨자 두 개에 대해).
- 다른 Kind에 대해서는 `DefKind`를 통해 별도로 정의된다 (`SymbolJoin[Torsion, kind]`).
- `GetTorsion[kind]`로 특정 Kind의 비틀림 텐서를 얻을 수 있다.
- 출력 형태는 `t`이다.

#### 예제 (Examples)

```wolfram
Torsion[la, lb, uc]
(* t_ab{}^c *)

GetTorsion[Latin]
(* Torsion 또는 TorsionLatin *)
```

#### 참고 (See Also)

`Structuref`, `GetTorsion`, `CD`

---

## 스칼라 래퍼

---

### Tscalar

#### 함수 시그니처

```wolfram
Tscalar[expr]
```

#### 설명 (Details)

스칼라 양을 텐서 연산으로부터 보호하는 래퍼이다.

- `IndexedObject`로 구성된 표현 전체를 스칼라로 다루기 위해 사용한다.
- 중첩된 `Tscalar`는 자동으로 정리된다.
- `Tscalar[expr + ...]`는 각 항에 자동으로 분배된다.
- 상수(`ConstantQ`가 `True`)는 자동으로 `Tscalar` 밖으로 추출된다.
- `ScalarFunctionQ`를 만족하는 함수(예: `Sin`, `Cos`, `Log`)도 자동으로 밖으로 추출된다.
- 일반 심볼(`Symbol`)도 자동으로 밖으로 추출된다.
- 거듭제곱 연산을 하려면 먼저 `Tscalar`로 감싸야 한다.

#### 예제 (Examples)

```wolfram
Sinh[Tscalar[T[la, lb] * T[ua, ub]]]
(* Sinh[(T_ab T^ab)] *)

Tscalar[a Sin[f[]] Log[f[]]]
(* a Log[f] Sin[f]  — 자동으로 추출됨 *)

(* Power 연산을 하려면 먼저 Tscalar로 감싸야 함 *)
Tscalar[T[la, lb] * T[uc, ud]]^2
(* (T_ab T^cd)^2 *)
```

#### 참고 (See Also)

`ScalarFunctionQ`, `ConstantQ`, `ErrorT`

---

### ErrorT

#### 함수 시그니처

```wolfram
ErrorT[expr]
```

#### 설명 (Details)

에러가 있는 표현식의 래퍼이다.

- `ErrorT`로 감싼 표현식을 빨간색으로 출력한다.
- `ObjectQ[ErrorT]`와 `ScalarFunctionQ[ErrorT]`는 모두 `False`이다.
- 프로그램 동작 중 오류 발견 시 자동으로 감싼다.
- `MarkErrorFlag`가 `On`이면 활성화된다.

#### 예제 (Examples)

```wolfram
ErrorT[A]
(* A  — 빨간색으로 출력 *)

ErrorT[T[la, lb]]
(* T_ab  — 빨간색으로 출력 *)
```

#### 참고 (See Also)

`MarkErrorFlag`, `Tscalar`
