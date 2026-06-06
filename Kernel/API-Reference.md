# mGRG API Reference

이 파일은 mGRG 패키지의 모든 전역(public) 함수와 심볼의 사용법을 정리한 것이다.

---

## 1. mPerm — 부호 순열 대수

**패키지**: `mGRG`mPerm``

텐서의 인덱스 대칭성을 표현하기 위한 순열군 패키지. 부호 순열(signed permutation)을 `CyclesPhased` 형태 `{Cycles[{...}], sign}`으로 표현.

### 헤드(Head) / 자료구조

| 심볼 | 설명 |
|------|------|
| `Imag[n1, n2, ...]` | 순열의 이미지 리스트 표현. `PermutationList`의 결과에 해당. |
| `GenSet[p1, p2, ...]` | 순열군의 생성원(generator) 집합. 각 `p1, p2, ...`는 `CyclesPhased` 형태. |

### 변환 함수

| 함수                        | 사용법                                                                             |
| ------------------------- | ------------------------------------------------------------------------------- |
| `ToCycl[s * Imag[ns...]]` | `Imag` 표현 또는 일반 리스트를 `CyclesPhased` 형태 `{Cycles[...], sign}`으로 변환. `s`는 부호(±1). |
| `ToCycl[imagL_List]`      | 정수 리스트(이미지 리스트)를 `CyclesPhased`로 변환.                                            |
| `ToImag[perm]`            | `CyclesPhased` 순열을 `Imag` 표현으로 변환. 길이는 `PermMax[perm]`.                         |
| `ToImag[perm, len]`       | 지정된 길이 `len`으로 패딩하여 `Imag` 표현으로 변환.                                             |
| `ToImag[cyclL_List, len]` | 사이클 리스트(예: `{{1,3},{2,4}}`)를 `Imag` 표현으로 변환.                                    |

### 순열 연산

| 함수 | 사용법 |
|------|--------|
| `PermMax[perm]` | 순열 `perm`이 이동시키는 가장 큰 원소를 반환. `CyclesPhased`, `Imag`, `GenSet` 모두 지원. |
| `InversePerm[perm]` | 순열의 역원을 반환. `CyclesPhased`와 `Imag` 형태 모두 지원. |
| `PermuteList[list, perm]` | 리스트 `list`를 순열 `perm`에 따라 재배열. |

### 군론 함수

| 함수 | 사용법 |
|------|--------|
| `MakePermGroup[gs, len]` | `GenSet` `gs`로부터 `len`개 원소에 작용하는 순열군의 모든 원소를 생성. `len` 생략 시 `PermMax[gs]` 사용. 결과는 `CyclesPhased` 리스트. |
| `Orbits[pts, gs, len]` | 점 리스트 `pts`의 `GenSet` `gs` 작용에 의한 궤도(orbit)를 계산. |
| `PermMemberQ[perm, len, gs]` | 순열 `perm`이 `GenSet` `gs`가 생성하는 군의 원소인지 검사. `len`이 순열의 최대 원소보다 작으면 오류. |

---

## 2. STensor — 심볼릭 텐서 연산 엔진

**패키지**: `mGRG`STensor``
**의존**: `mGRG`mPerm``

### 2.1 유틸리티 함수

| 함수                          | 사용법                                                                  |
| --------------------------- | -------------------------------------------------------------------- |
| `AllQoptions[qs][name, qL]` | `name`이 리스트 `qL`의 모든 조건을 만족하는지 검사. `qs`는 `HeadQs` 또는 `IndexQs`.      |
| `ConstantQ[x]`              | `x`가 숫자, 수치 심볼, 또는 `Constant` 속성을 가진 심볼이면 `True`.                    |
| `FreePatternQ[expr]`        | `expr`에 패턴 객체(`Pattern`, `Blank` 등)가 없으면 `True`.                     |
| `PositiveIntegerQ[n]`       | `n`이 양의 정수이면 `True`.                                                 |
| `SignOfTerm[expr]`          | 심볼릭 항이 음의 부호(예: `-x`)를 가지면 `-1`, 아니면 `1`. 주의: `SignOfTerm[-1]`은 `1`. |
| `SymbolJoin[s1, s2, ...]`   | 심볼이나 문자열들을 하나의 심볼로 결합. 리스트 입력도 가능: `SymbolJoin[{s1, s2}]`.           |

#### 옵션 키

| 옵션 | 설명 |
|------|------|
| `CovDs` | 적용할 공변 도함수를 지정하는 옵션. |
| `HeadQs` | 함수가 적용될 표현식의 Head를 지정하는 옵션. 기본값은 보통 `{IndexedObjectQ}`. |
| `IndexQs` | 대상 인덱스를 지정하는 옵션. |

#### 메시지

| 메시지 | 형식 |
|--------|------|
| `Msg::err` | `` "`1` `2` `3` `4`" `` — 에러 메시지 (4개 슬롯) |
| `Msg::warn` | `` "`1` `2` `3` `4`" `` — 경고 메시지 (4개 슬롯) |
| `Msg::note` | `` "`1` `2` `3` `4` `5`" `` — 알림 메시지 (5개 슬롯) |
| `General::invalid` | `` "`1` is not a valid `2`." `` |

---

### 2.2 인덱스 체계

#### 인덱스 종류 판별

| 함수                       | 사용법                                                                |
| ------------------------ | ------------------------------------------------------------------ |
| `ComponentIndexQ[index]` | `index`가 성분 인덱스(0이 아닌 정수)이면 `True`.                                |
| `DummyIndexQ[index]`     | `index`가 시스템이 생성한 더미 인덱스이면 `True`.                                 |
| `RegularIndexQ[index]`   | `index`가 `SetIndices`로 정의된 정규 심볼릭 인덱스이면 `True`.                    |
| `DnIndexQ[index]`        | `index`가 유효한 하첨자(covariant) 인덱스이면 `True`. 심볼은 `l` 접두사, 정수는 음수.     |
| `UpIndexQ[index]`        | `index`가 유효한 상첨자(contravariant) 인덱스이면 `True`. 심볼은 `u` 접두사, 정수는 양수. |
| `TensorialIndexQ[index]` | `index`가 심볼릭 인덱스(정규 또는 더미)이면 `True`. 성분 인덱스와 구분.                   |

#### 인덱스 Kind 관리

| 함수                                      | 사용법                                                                                                                                                     |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SetIndices[{"a", "b", ...}, ikind]`    | 인덱스 Kind에 속하는 인덱스 문자들을 정의. 각 문자에 대해 `la, ua` 등의 심볼이 자동 생성되며, `DnIndexQ`, `UpIndexQ`, `RegularIndexQ` 등이 설정됨. **주의**: 실행 시 해당 `l*/u*` 심볼의 기존 모든 정의가 지워짐. |
| `AddIndices[{"c1", "c2", ...}, ikind]`  | 인덱스  Kind에 새 인덱스 문자를 추가. **주의**: `SetIndices`와 마찬가지로 `l*/u*` 심볼의 기존 정의 삭제.                                                                              |
| `DropIndices[{"c1", "c2", ...}, ikind]` | 인덱스 Kind에 지정되었던 인덱스 문자를 제거.                                                                                                                             |
| `GetIndices[ikind]`                     | 지정된 인덱스 Kind의 모든 정의된 인덱스를 반환. `GetIndices[All]`은 모든 종류의 인덱스를 반환.                                                                                        |
| `IndexToKind[idx]`                      | 인덱스 `idx`의 Kind를 반환. 해당하는 Kind가 없으면 `NonKind`. 성분 인덱스(정수)는 `DefaultKind`.                                                                               |
| `KindIndexQ[ikind]`                     | 인덱스가 Kind `ikind`에 속하는지 검사하는 순수 함수를 반환. 예: `Select[idxList, KindIndexQ[Latin]]`.                                                                        |
| `OneDimKindQ[ikind]`                    | Kind가 1차원 인덱스 종류이면 `True`.                                                                                                                              |

#### 인덱스 변환

| 함수                 | 사용법                                                                                           |
| ------------------ | --------------------------------------------------------------------------------------------- |
| `FlipIndex[index]` | 상첨자를 하첨자로, 하첨자를 상첨자로 변환.                                                                      |
| `ToDnIndex[index]` | 상첨자를 하첨자로 변환. 이미 하첨자이면 변화 없음.                                                                 |
| `ToUpIndex[index]` | 하첨자를 상첨자로 변환. 이미 상첨자이면 변화 없음.                                                                 |
| `NewDummy[ikind]`  | 지정된 Kind의 고유한 더미 인덱스를 생성. 결과는 `{dnIndex, upIndex}` 쌍으로, `dummy[[1]]`은 하첨자, `dummy[[2]]`는 상첨자. |

#### 인덱스 정렬 및 검사

| 함수 | 사용법 |
|------|--------|
| `IndexOrderedQ[indexList]` | 인덱스 리스트가 정규 순서로 정렬되어 있는지 검사. `IndexOrderedQ[list1, list2]`는 `list1`이 `list2` 이전 순서인지 검사. |
| `IndexSort[indexList]` | 인덱스 리스트를 정규 순서로 정렬. |
| `PairIndexQ[i1, i2]` | `i1`과 `i2`가 유효한 상/하 쌍인지 검사. `PairIndexQ[{{i1,j1}, {i2,j2}, ...}]`은 여러 쌍을 동시에 검사. |
| `TakePairs[indexList]` | 인덱스 리스트에서 동일한 상/하 쌍을 찾아 반환. |
| `DuplicatedIndicesQ[indexL]` | 텐서 인덱스 리스트에 중복된 인덱스가 있으면 `True`. |
| `UpupDndnIndexQ[indexL]` | 인덱스 리스트의 인덱스가 모두 상첨자이거나 모두 하첨자이면 `True`. |

#### Kind 구조

| 함수                               | 사용법                                                                   |
| -------------------------------- | --------------------------------------------------------------------- |
| `DefKind[kind, {"a", "b", ...}]` | 새로운 Kind를 인덱스 문자 집합과 함께 정의.                                           |
| `UndefKind[kind]`                | 지정된 Kind의 정의를 제거. `DefaultKind`는 제거 불가.                               |
| `CheckKind[kind]`                | 정의된 Kind이면 `True`, 아니면 에러 메시지와 함께 `False`. 리스트 입력도 가능.                |
| `DefinedKindQ[kind]`             | 정의된 Kind이면 `True`.                                                    |
| `KindMatchQ[kind1, kind2]`       | 두 Kind가 호환 가능하면 `True`. `All`은 모든 Kind와 호환, `NonKind`는 어떤 Kind와도 비호환. |

#### Kind 속성

| 함수                               | 사용법                                                                                          |
| -------------------------------- | -------------------------------------------------------------------------------------------- |
| `SetCoordinates[coSys, kind]`    | 지정된 Kind에 좌표계 설정. `SetCoordinates[coSys, basis, kind]`는 비좌표 기저을 설정. 좌표 이름을 `Protect`할 필요 없음. |
| `GetCoordinates[kind]`           | 지정된 Kind의 좌표를 반환.                                                                            |
| `ClearCoordinates[kind]`         | 지정된 Kind의 좌표 정의를 제거.                                                                         |
| `CoordinateBasisQ[kind]`         | 지정된 Kind의 기저가 좌표 기저이면 `True`. 인자 없이 `CoordinateBasisQ[]`는 `DefaultKind` 사용.                  |
| `SetDimension[n, kind]`          | 지정된 Kind의 차원을 `n`으로 설정. `kind` 생략 시 `DefaultKind`.                                           |
| `GetDimension[kind]`             | 지정된 Kind의 차원을 반환. `kind` 생략 시 `DefaultKind`.                                                 |
| `ClearDimension[kind]`           | 지정된 Kind의 차원 정의를 제거.                                                                         |
| `SetSig[s, kind]`                | 메트릭 시그니처의 음수 고유값 개수 `s`를 설정. `kind` 생략 시 `DefaultKind`.                                      |
| `GetSig[kind]`                   | 메트릭 시그니처 값(음수 고유값 개수)을 반환.                                                                   |
| `ClearSig[kind]`                 | 시그니처 정의를 제거.                                                                                 |
| `ValidIndexQ[index, kind]`       | `index`가 `kind`에 대해 유효한지 검사. 심볼릭 인덱스는 Kind 호환성, 성분 인덱스는 차원 범위를 검사.                           |
| `ValidIndicesQ[indexList, kind]` | 모든 인덱스가 유효하고 심볼릭 인덱스에 중복이 없는지 검사.                                                            |

#### Kind 관련 텐서 조회

| 함수 | 사용법 |
|------|--------|
| `GetMetric[kind]` | 지정된 Kind의 고유 메트릭 텐서를 반환. |
| `GetEpsilon[kind]` | 지정된 Kind의 레비-치비타 텐서(체적 형식)를 반환. |
| `GetStructuref[kind]` | 지정된 Kind의 구조 상수 텐서를 반환. |
| `GetTorsion[kind]` | 지정된 Kind의 비틀림 텐서를 반환. |

#### 전역 심볼

| 심볼 | 설명 |
|------|------|
| `DefaultKind` | 기본 인덱스 종류. `SetDefaultKind[]`로 변경 가능. |
| `NonKind` | 유효한 Kind가 아닌 경우의 반환값. |
| `Latin` | 사전 정의된 라틴 문자 인덱스 종류 (`a, b, c, ...`). |

---

### 2.3 텐서 정의 및 조작

#### 텐서 정의

| 함수                                              | 사용법                                                                                                                                                                                 |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DefTensor[tensor[indices], "symmetryString"]`  | 새 텐서를 정의. `indices`는 Kind와 상/하를 결정하는 심볼릭 인덱스, `"symmetryString"`은 대칭 문자열. 예: `DefTensor[T[la, lb], "+ab"]`는 Latin Kind의 rank-2 대칭 텐서, `DefTensor[F[la, lb], "-ab"]`는 반대칭 rank-2 텐서. |
| `Tdefine`                                       | `DefTensor`의 별칭.                                                                                                                                                                    |
| `UndefTensor[tensor]`                           | 텐서의 모든 정의를 제거.                                                                                                                                                                      |
| `DefTensor[tensor, "symStr", PrintAs -> "str"]` | `PrintAs` 옵션으로 출력 문자열 지정.                                                                                                                                                           |

**대칭 문자열 형식**:
- `"+ab"` : a↔b 교환 시 부호 +1 (대칭)
- `"-ab"` : a↔b 교환 시 부호 -1 (반대칭)
- `"-bacd-abdc+cdab"` : 여러 대칭성의 조합 (예: 곡률 텐서)
- 숫자 문자열(예: `"4"`)은 대칭성 없는 랭크-4 텐서

#### 텐서 속성 조회

| 함수                              | 사용법                                                                     |
| ------------------------------- | ----------------------------------------------------------------------- |
| `GetRank[tensor]`               | 텐서의 랭크(인덱스 개수)를 반환. 임의의 랭크는 `-1`을 반환.                                   |
| `GetSymmetry[tensor]`           | 텐서의 대칭 생성원 집합(`GenSet`)을 반환.                                            |
| `SetSymmetry[tensor, "symStr"]` | 텐서의 인덱스 대칭을 재설정.                                                        |
| `DnupAt[name, pos]`             | 인덱스 위치 `pos`에서의 상/하 상태 반환 (`-1` = 하, `+1` = 상).                         |
| `KindOf[obj, pos]`              | 객체 `obj`의 인덱스 위치 `pos`에서의 Kind를 반환. `KindOf[T[a,b], a]`은 인덱스 `a`의 Kind. |
| `AllPermutations[permS]`        | 대칭 문자열 `permS`에 의해 생성되는 모든 순열과 가중치를 문자열로 생성.                            |
| `GStoString[gs, len]`           | 대칭 생성원 집합 (`GenSet`) `gs`를 랭크 `len`의 문자열 표현으로 변환.                       |

#### 객체 타입 판별

| 함수                           | 사용법                                           |
| ---------------------------- | --------------------------------------------- |
| `ObjectQ[name]`              | `name`이 정의된 인덱스 객체 또는 스칼라 함수이면 `True`.        |
| `IndexedObjectQ[name]`       | `name`이 정의된 인덱스 객체(텐서 또는 연산자)이면 `True`.       |
| `IndexedOperandQ[name]`      | `name`이 인덱스를 갖는 피연산자(텐서 또는 미분 형식)이면 `True`.   |
| `IndexedTensorQ[name]`       | `name`이 정의된 인덱스 텐서이면 `True`.                  |
| `DiffFormQ[name]`            | `name`이 정의된 미분 형식이면 `True`.                   |
| `IndexedOperatorQ[name]`     | `name`이 정의된 인덱스 연산자(CD, LD 등)이면 `True`.       |
| `ScalarFunctionQ[name]`      | `name`이 스칼라 함수(Sin, Cos, Tscalar 등)이면 `True`. |
| `RemoveIndexedObject[oName]` | 인덱스 객체 `oName`의 모든 정의를 제거. 예약된 이름에는 작동하지 않음.  |

#### 사전 정의된 심볼

| 심볼                       | 설명                                                 |
| ------------------------ | -------------------------------------------------- |
| `Kdelta[up, dn]`         | 크로네커 델타 텐서. Kind는 `All` (모든 Kind에서 작동).            |
| `Metricg[dn, dn]`        | 기본 메트릭 텐서. Kind는 `DefaultKind`.                    |
| `Epsilon[idx, idx, ...]` | 레비-치비타 텐서.                                         |
| `Structuref[up, dn, dn]` | 비좌표 기저의 구조 상수. `CoordinateBasisQ`가 `False`일 때만 정의. |
| `Torsion[up, dn, dn]`    | 비틀림 텐서.                                            |
| `ErrorT[expr]`           | 에러가 있는 표현식의 래퍼. 출력시 붉은색으로 표시.                      |
| `Tscalar`                | 스칼라 양을 텐서 연산으로부터 보호하는 래퍼.                          |

#### 연산자

| 연산자 | 사용법 |
|--------|--------|
| `CD[index, expr]` | 공변 도함수. `index`는 하첨자, `expr`은 텐서 표현식. |
| `LD[vector, expr]` | 리 도함수. `vector`는 벡터 이름, `expr`은 텐서 표현식. **주의**: `expr`에 `BD`가 포함되면 제대로 동작하지 않음. `FreeQ[expr, BD]`로 먼저 확인할 것. |
| `BD[index, expr]` | 기저 도함수(편미분). 좌표 기저에서는 편도함수, 비좌표 기저에서는 기저 행렬을 통해 정의. `BD[kind][index, expr]`로 특정 Kind 지정 가능. |
| `XD[expr]` | 외미분 연산자 (exterior derivative). |
| `XP[args, ...]` | 외적 연산자 (exterior/wedge product). |

---

### 2.4 인덱스 표현식 조작

#### 인덱스 찾기

| 함수                                  | 사용법                                   |
| ----------------------------------- | ------------------------------------- |
| `FindIndices[expr]`                 | 표현식의 유효한 인덱스 모두를 리스트로 반환.             |
| `FindIndicesAll[expr]`              | 인덱스 유효성 검사 없이 모든 인덱스를 반환.             |
| `FindFreeTensorialIndices[expr]`    | 자유(free) 텐서 인덱스를 반환.                  |
| `FindFreeTensorialIndicesAll[expr]` | 유효성 검사 없이 자유 텐서 인덱스를 반환.              |
| `NoIndexQ[expr]`                    | `expr`이 스칼라이거나 자유 텐서 인덱스가 없으면 `True`. |

#### 인덱스 대칭화

| 함수 | 사용법 |
|------|--------|
| `SymmetrizeIndices[expr, {i1, i2, ...}]` | 지정된 인덱스에 대해 대칭화. |
| `AntisymmetrizeIndices[expr, {i1, i2, ...}]` | 지정된 인덱스에 대해 반대칭화. |

#### 더미 인덱스 조작

| 함수                                          | 사용법                                                                                            |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `Dum[expr]`                                 | 표현식에서 가능한 모든 더미 인덱스 쌍을 수축.                                                                     |
| `DumFresh[expr]`                            | 모든 더미 인덱스들 각각을 새롭고 고유한 ID를 갖는 더미 인덱스로 교체.                                                      |
| `ResetDummies[expr, opts]`                  | 더미 인덱스를 정규형(`la, lb, ...`)으로 재명명. 옵션: `HeadQs`, `IndexQs`. **주의**: `Plus` 표현식의 항 순서가 변경될 수 있음. |
| `SplitIndices[expr, {i, i1, i2, ...}, ...]` | 인덱스 `i`를 `i1, i2, ...`로 교체한 표현식 리스트 생성. `Table`의 심볼릭 버전.                                       |
| `SumDum[expr, {i1, i2}, kind]`              | 지정된 Kind의 더미 인덱스 쌍에 대해 `i1`~`i2` 범위에서 수치 합산 (Einstein Summation).                              |
| `SumDum[expr, {i, i1, i2, ...}, ...]`       | 인덱스 `i`를 `i1, i2, ...`로 교체하여 합산.                                                               |
| `SumDum[expr, {kind1, kind2, ...}]`         | Kaluza-Klein 분해: `kind1` 인덱스를 `kind2` 등으로 분할하여 합산.                                             |

#### 기타 유틸리티

| 함수                                       | 사용법                                                     |
| ---------------------------------------- | ------------------------------------------------------- |
| `ExpandObject[expr]`                     | 인덱스 객체를 포함하는 표현식을 전개(곱을 합으로 분배).                        |
| `FreeObjectQ[expr]`                      | `expr`에 인덱스 객체가 없으면 `True`.                             |
| `ForEachTerm[expr, f, args...]`          | 합이나 등식의 각 항에 함수 `f`를 적용.                                |
| `ForEachObject[expr, hOptL, f, args...]` | 표현식의 각 인덱스 객체에 `f`를 적용. `hOptL`은 Head 옵션.               |
| `SplitTerm[term, hOptL]`                 | 항을 `{scalarPart, tensorPart}`로 분리.                      |
| `RuleUnique[lhs, rhs, cond]`             | 더미 인덱스를 자동 처리하는 지연(delayed) 규칙 `lhs :> rhs /; cond` 생성. |
| `SyntaxCheck[expr]`                      | 자유 인덱스 불일치 등의 구문 오류를 검사.                                |
참고로 `ForEachObject` 함수에서 리스트 인자 `hOptL`이 하는 역할은 다음 코드로 이해:

```wolfram
ForEachObject[name[args1], {hOpts}, f, args2]
(* f[name[args1], args2] /; AllQoptions[HeadQs][name, {hOpts}] *)
```

#### 플래그 (On/Off 토글)

| 플래그 | 설명 |
|--------|------|
| `AutoFlag` | 자동 후처리(구문 검사, 더미 인덱스 리셋) 제어. |
| `CoordinateBasisFlag` | 기저가 좌표 기저인지 제어. `On[CoordinateBasisFlag]` 또는 `On[CoordinateBasisFlag[kind]]`. |
| `MarkErrorFlag` | 에러 표현식을 빨간색으로 표시할지 제어. |
| `ResetDummiesFlag` | 출력 시 더미 인덱스 자동 리셋 제어. |
| `SyntaxCheckFlag` | 출력 시 자동 구문 검사 제어. |

---

### 2.5 공변 구조 (CovariantStructures.m)

#### 메트릭 정의/해제

| 함수 | 사용법 |
|------|--------|
| `DefMetric[metric, prtStr, kind]` | 메트릭 텐서를 정의. `prtStr` (출력 문자열)과 `kind`는 선택. 역메트릭 관계(`g^ac g_cb = δ^a_b`)가 자동 설정됨. |
| `UndefMetric[metric]` | 메트릭 정의와 관련 속성을 모두 제거. |
| `MetricQ[metric]` | `metric`이 정의된 메트릭이면 `True`. |
| `MetricSpaceQ[kind]` | 지정된 Kind가 메트릭 공간이면 `True`. |

#### 도함수 연산자 정의/해제

| 함수                                                | 사용법                                                                                                                          |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `DefDerivativeOperator[CovD, prtStr, kind, opts]` | 새 도함수 연산자 `CovD`를 정의. 자동으로 접속 계수(`GammaCovD`)와 곡률 텐서(`RiemannCovD`, `RicciCovD`, `ScalarCovD`)가 심볼로 생성됨. 옵션: `TorsionFreeQ`. |
| `UndefDerivativeOperator[covD]`                   | 도함수 연산자와 관련 텐서(접속 계수, 곡률 텐서 등)를 모두 제거.                                                                                       |
| `DerivativeOperatorQ[opName]`                     | `opName`이 정의된 도함수 연산자이면 `True`.                                                                                              |
| `TorsionFreeQ[covD]`                              | `covD`가 비틀림 자유(torsion-free)이면 `True`.                                                                                       |

#### 메트릭 호환성

| 함수 | 사용법 |
|------|--------|
| `SetMetricCompatible[covD, metric]` | `covD`가 `metric`과 호환됨을 선언 (`∇g = 0`). 체적 형식의 공변 상수성도 포함. |
| `ClearMetricCompatible[covD, metric]` | 메트릭 호환성 속성을 제거. |
| `MetricCompatibleQ[op, metric]` | `op`가 `metric`과 호환되면 `True`. |

#### DefaultKind 관리

| 함수                     | 사용법                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `SetDefaultKind[kind]` | 기본 Kind를 변경. `Metricg`, `CD`, `Epsilon` 등 기본 객체가 새 Kind로 재연결됨. **주의**: 대입 연산식의 RHS에 `DefaultKind`를 사용할 때는 `SetDelayed(:=)` 사용. |

#### 인덱스 올리기/내리기

| 함수                             | 사용법                                                                                          |
| ------------------------------ | -------------------------------------------------------------------------------------------- |
| `Absorb[expr, metric, opts]`   | 두 번째 인자인 rank-2 대칭 텐서 `metric`을 `expr`에 흡수하여 인덱스를 올리거나 내림. 옵션: `IndexQs`, `HeadQs`, `CovDs`. |
| `Absorbg[expr, opts]`          | `Absorb[expr, Metricg, opts]`의 축약형.                                                          |
| `PutMetric[expr, index, opts]` | 지정된 인덱스를 그 인덱스의 Kind에 지정된 메트릭으로 올리거나 내림.                                                     |
| `PullOutMetric[expr, opts]`    | 인덱스의 상/하 상태를 사전 정의된 형태로 변환하고, 해당 메트릭 텐서를 분리.                                                 |

#### 호지 쌍대

| 함수 | 사용법 |
|------|--------|
| `DualStar[expr, {indices}]` | 텐서 `expr`의 호지 쌍대를 `indices`를 사용하여 계산. |

#### 사전 정의된 곡률 텐서 심볼

| 심볼                          | 설명                              |
| --------------------------- | ------------------------------- |
| `GammaCD[dn, dn, up]`       | 기본 공변 도함수 CD의 접속 계수 (크리스토펠 기호). |
| `RiemannCD[dn, dn, dn, up]` | 리만 곡률 텐서.                       |
| `RicciCD[dn, dn]`           | 리치 텐서.                          |
| `ScalarCD[]`                | 리치 스칼라.                         |

#### 추가 플래그

| 플래그               | 설명                                                                                 |
| ----------------- | ---------------------------------------------------------------------------------- |
| `EvaluateBDFlag`  | 기저 도함수(BD)를 성분으로 평가할지 제어. `On[EvaluateBDFlag]` 또는 `On[EvaluateBDFlag[kind]]`.      |
| `InitCTensorFlag` | CTensor 환경이 초기화되었는지 나타냄. `InitCTensor`가 `True`로, `ClearCTensor`가 `False`로 설정.      |
| `KdeltaFlag`      | 크로네커 델타 자동 흡수 제어. `On`이면 `Kdelta[a,-b] T[b]` → `T[a]`, `g[a,-b]` → `Kdelta[a,-b]`. |
| `MetricgFlag`     | 기본 메트릭 `Metricg`의 정의 제어.                                                           |

---

### 2.6 Tsimplify — 텐서 단순화 (Tsimplify.m)

#### 주요 함수

| 함수 | 사용법 |
|------|--------|
| `Tsimplify[expr, opts]` | 대칭성과 인덱스 수축을 이용한 텐서 표현식 단순화. **대칭 메트릭에서만 동작**. 옵션: `Verbose -> True`로 단계별 정보 출력, `HeadQs`, `IndexQs`, `CovDs`. |
| `TindexSort[expr]` | 텐서의 인덱스를 대칭성에 기반한 정규 순서로 정렬. |

#### 인덱스 쌍 순서 통일

| 함수                     | 사용법                                                  |
| ---------------------- | ---------------------------------------------------- |
| `DnUpPair[expr, opts]` | 모든 가능한 상-하 인덱스 쌍을 하-상 순서로 변환. 옵션: `HeadQs`, `CovDs`. |
| `UpDnPair[expr, opts]` | 모든 가능한 하-상 인덱스 쌍을 상-하 순서로 변환. 옵션: `HeadQs`, `CovDs`. |

#### 단순화 규칙

| 함수 | 사용법 |
|------|--------|
| `BDinvgRule[metric]` | 역메트릭의 기저 도함수에 대한 변환 규칙. `metric` 생략 시 `Metricg`. |
| `EpsilonProductRule[kind]` | 두 레비-치비타 텐서의 곱에 대한 단순화 규칙. `kind` 생략 시 `DefaultKind`. |
| `KdeltaSumRule[kind]` | 크로네커 델타의 대각합(trace)을 차원으로 치환하는 규칙. `kind` 생략 시 `DefaultKind`. 예: `Kdelta[la,ua]` → `n`. |

#### 옵션

| 옵션 | 설명 |
|------|------|
| `Verbose` | `True`이면 계산 단계별 정보를 출력. `Tsimplify`와 `InitCTensor` 등에서 사용. |

---

### 2.7 미분 형식 (DiffForm.m)

#### 정의/해제

| 함수                                          | 사용법                                                               |
| ------------------------------------------- | ----------------------------------------------------------------- |
| `DefForm[f, p, opts]`                       | `p`-형식 `f`를 정의. 옵션: `PrintAs -> "str"`. `p > Dimension`이면 자동으로 0. |
| `DefForm[f[indices...], p, "symStr", opts]` | 인덱스를 가진 텐서값(tensor-valued) `p`-형식을 대칭성 문자열과 함께 정의.                |
| `Fdefine`                                   | `DefForm`의 별칭.                                                    |
| `UndefForm[f]`                              | 미분 형식의 모든 정의를 제거.                                                 |

**주의**: 미분 형식은 항상 `DefaultKind`에서 정의됨. DiffForm 연산 도중에 `DefaultKind`를 변경하면 안 됨.

#### 연산자

| 연산자                | 사용법                                                                                                                         |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| `XD[expr]`         | 외미분(exterior derivative). `XD[XD[expr]] = 0` (d² = 0).                                                                      |
| `XP[a, b, ...]`    | 외적(wedge product). p-형식 교환 시 `(-1)^(deg_a * deg_b)` 부호. `p > Dimension`이면 자동으로 0. `Wedge` 연산자(Notebook에서 ESC ^ ESC)와 자동 연동. |
| `IP[vector, form]` | 내부 곱(interior product). 벡터 `vector`와 미분 형식의 수축. 결과는 (p-1)-형식. `IP[v, IP[v, expr]] = 0` (ι² = 0).                            |
| `HodgeStar[pForm]` | 호지 쌍대(`*`로 출력). p-형식을 (n-p)-형식으로 변환.                                                                                        |
| `CoXD[pForm]`      | 코미분(codifferential). `(-1)^(np+n+1) * d *`에 해당.                                                                             |

#### 변환 규칙

| 함수 | 사용법 |
|------|--------|
| `CoXDRule[]` | 코미분을 외미분과 호지 쌍대로 표현하는 규칙. |
| `LDtoXDRule[]` | 카르탄 공식에 의한 리 도함수 규칙: `LD_v = IP_v ∘ XD + XD ∘ IP_v`. |

#### 유틸리티

| 함수                      | 사용법                                                            |
| ----------------------- | -------------------------------------------------------------- |
| `ApplyXD[expr]`         | 외미분 `XD`를 좌표에 대한 기저 도함수 `BD`로 전개.                              |
| `CollectForm[expr]`     | 동일한 미분 형식 부분을 가진 항을 모음.                                        |
| `DegreeForm[expr]`      | 미분 형식의 차수를 반환.                                                 |
| `ZeroDegreeQ[expr]`     | 0-형식(스칼라)이거나 미분 형식이 아니면 `True`.                                |
| `FtoC[expr, {indices}]` | 미분 형식을 반대칭 인덱스 텐서로 변환. 옵션인 인덱스를 사용하면 그 인덱스 개수가 형식의 차수와 일치해야 함. |
| `CoordRep[form, coSys]` | 미분 형식의 좌표 표현. `CoordRep[form, n]`은 `n`차원 일반 공간에서의 표현.          |

#### 플래그

| 플래그 | 설명 |
|--------|------|
| `XDtoCDfrag` | `On`이면 `XD`를 기본 공변 도함수 `CD`로 변환 (비틀림 자유일 때). `Off`이면 `BD`로 변환. |

---

### 2.8 텐서 성분 (TensorComponents.m)

#### 도함수 전개

| 함수                                   | 사용법                                                                                                                           |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| `CDtoBD[expr, covD]`                 | 공변 도함수 `covD`를 기저 도함수 `BD` + 접속 계수로 전개. `covD` 생략 시 `CD`.                                                                     |
| `CommuteCD[{a, b}, expr, covD]`      | 인덱스 `a, b`에 대한 공변 도함수를 교환. 결과에 리만 텐서와 (covD가 torsion-free가 아닐 경우) 비틀림 텐서가 나타남. `a, b`는 `RegularIndexQ`여야 함. `covD` 생략 시 `CD`. |
| `GammaToMetric[expr, covD]`          | 접속 계수를 메트릭의 도함수(`BD`), (비좌표 기저인 경우) 구조 상수, (covD가 torsion-free가 아닐 경우) 비틀림 텐서로 표현. `covD` 생략 시 `CD`. covD가 메트릭 호환 도함수이어야 함.   |
| `LDtoCD[expr, covD]`                 | 리 도함수 `LD`를 공변 도함수 `covD`로 변환. `covD`는 torsion-free여야 함. `LDtoCD[expr, BD]`로 기저 도함수 변환도 가능. `covD` 생략 시 `CD`.                 |
| `RiemannToGamma[expr, curvRL, covD]` | 곡률 텐서(리만, 리치, 스칼라)를 접속 계수의 도함수로 전개. `curvRL`은 변환할 곡률 텐서 리스트 (빈 리스트 `{}`면 모두 변환). `curvRL`, `covD` 생략 가능.                      |

#### 성분 설정/해제

| 함수                                       | 사용법                                                                                                                                                  |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SetComponents[tensor[indices], values]` | 텐서의 성분을 설정. 성분 인덱스로 한 개의 성분 설정: `SetComponents[T[-1,-2], expr]` (대칭성에 의한 모든 관련 성분도 자동 설정). 심볼릭 인덱스로 전체 성분 테이블 설정: `SetComponents[T[la,lb], matrix]`. |
| `ClearComponents[tensor[indices]]`       | 텐서의 성분을 해제. 성분 인덱스로 한 성분 해제, 심볼릭 인덱스로 전체 해제.                                                                                                         |

#### 좌표 변환

| 함수                                                                  | 사용법                                                                                                                   |
| ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `Pushforward[fromT, fromCoSys, toCoSys, simpCmd]`                   | 벡터/텐서의 밀기(pushforward). `fromT`는 벡터(`VectorQ`), 행렬(`MatrixQ`), 또는 일반 배열(`ArrayQ`). `simpCmd`는 단순화 함수 (기본 `Simplify`). |
| `Pullback[fromT, fromCoSys, toCoSys, simpCmd]`                      | 공벡터/텐서의 당김(pullback). `simpCmd` 기본값 `Simplify`.                                                                       |
| `PushTensor[updnL, fromT, fromCoSys, toCoSys, forM, forN, simpCmd]` | 일반 텐서 변환. `updnL`은 각 인덱스의 반변/공변 상태. `forM`은 순방향 변환 규칙, `forN`은 역방향 변환 규칙.                                             |
| `Ttransform[leftT, rightT, leftCoSys, rightCoSys, simpCmd]`         | 미분동형사상(diffeomorphism)에 의한 텐서 변환. 좌표 변환: `leftCoSys` $\to$ `rightCoSys`.                                              |

#### 기타

| 함수 | 사용법 |
|------|--------|
| `CommutatorVectors[vecList, kind]` | 벡터장 리스트의 교환자를 계산. `kind` 기본값 `DefaultKind`. |
| `LineElement[coSys, metric, simpCmd]` | 좌표계 `coSys`와 메트릭 행렬 `metric`에 대한 선소(line element) `ds²`을 생성. `simpCmd`는 단순화 함수. |
| `SetConstantMetric[diag, coSys, kind]` | 상수 메트릭으로 평탄 시공간 설정. `diag`는 대각 성분 리스트(예: `{-1,1,1,1}`) 또는 전체 메트릭 행렬. `kind` 기본값 `DefaultKind`. |
| `ClearConstantMetric[kind]` | 상수 메트릭 정의를 해제. `kind` 기본값 `DefaultKind`. |

---

### 2.9 변분 도함수 (Variation.m)

| 함수 | 사용법 |
|------|--------|
| `VD[arg, expr]` | `expr`의 `arg`에 대한 변분 도함수. |

**옵션**:

| 옵션                    | 기본값     | 설명                              |
| --------------------- | ------- | ------------------------------- |
| `IndependentVD -> {}` | `{}`    | 독립 텐서 리스트. 이 리스트의 텐서에 대한 변분은 0. |
| `ByPartsVD -> False`  | `False` | `True`이면 지정된 도함수에 대해 부분적분 수행.   |

**핵심 규칙**:
- 선형성: `VD[arg, a + b] = VD[arg, a] + VD[arg, b]`
- 라이프니츠: `VD[arg, a * b]` = 곱의 미분
- 메트릭 변분: `VD[g[a,b], g[c,d]]` → 크로네커 델타 조합 (메트릭 대칭성 고려)
- 같은 텐서 변분: `VD[T[i1...], T[i2...]]` → 대칭성이 부과된 크로네커 델타 곱
- 다른 독립 텐서: `VD[T1[...], T2[...]] = 0` (IndependentVD에 T2가 포함될 때)
- 상수: `VD[_, constant] = 0`
- 스칼라 함수: `VD[arg, f[expr]] = f'[expr] * VD[arg, expr]`

---

### 2.10 초곡면 기하학 (Hypersurface.m) — Experimental

| 함수 | 사용법 |
|------|--------|
| `DefHypersurface[subKind, normSign]` | 초곡면의 기하학적 객체를 정의. `subKind`는 초곡면 Kind 심볼, `normSign`은 법선 벡터 노름 (`-1` = 공간적, `+1` = 시간적, 기본값 `-1`). `DefaultKind`가 메트릭 공간이어야 함. |
| `TangentialD[a, expr]` | 초곡면의 접선 방향 도함수. `a`는 `subKind` 인덱스. |

**자동 정의되는 심볼**:

| 심볼 | 설명 |
|------|------|
| `SubMetric[a, b]` | 유도 메트릭 (제1기본형식). `subKind` 인덱스. |
| `SubCD[a, expr]` | `SubMetric`과 호환되는 내재 공변 도함수. |
| `ExtrinsicK[a, b]` | 외곡률 텐서 (제2기본형식). 대칭 (`"+ba"`). |
| `NormalV[a]` | 법선 벡터. `DefaultKind` 인덱스. 자동 정규화: `n^a n_a = normSign`. |
| `SubBasis[a, b]` | 사영 텐서 (초곡면 임베딩 기저). `a`는 `subKind`, `b`는 `DefaultKind` 인덱스. |

**자동 설정되는 항등식**:
- `NormalV[a] NormalV[b] = normSign` (쌍인덱스일 때)
- `SubBasis[a, b] NormalV[c] = 0` (직교성)
- `SubBasis[a, b] SubBasis[c, d] = SubMetric[a, c]` (사영 성질, `b,d`가 쌍일 때)
- 가우스 방정식과 바인가르텐 방정식 (`TangentialD` 규칙)

---

## 3. Einstein — 일반상대론의 성분 연산 

**패키지**: `mGRG`Einstein``
**의존**: `mGRG`STensor``, `mGRG`mPerm``

### 3.1 Einstein.m — 바일 텐서 변환

| 함수 | 사용법 |
|------|--------|
| `RiemannToWeyl[expr]` | 표현식의 리만 텐서(`RiemannCD`)를 바일 텐서(`WeylCD`) + 리치 텐서 + 리치 스칼라로 분해. |
| `WeylToRiemann[expr]` | 표현식의 바일 텐서(`WeylCD`)를 리만 텐서로 복원. |

| 심볼                       | 설명                                             |
| ------------------------ | ---------------------------------------------- |
| `WeylCD[dn, dn, dn, up]` | 바일 텐서. 대칭성: `"-bacd-abdc+cdab"`. 출력 문자열 `"C"`. |

---

### 3.2 CTensor.m — 성분 텐서 계산

#### 초기화/해제

| 함수                                        | 사용법                                                                                     |
| ----------------------------------------- | --------------------------------------------------------------------------------------- |
| `InitCTensor[coSys, metric, opts]`        | 성분 텐서 계산 환경을 초기화. `coSys`는 좌표 리스트 (예: `{t, r, θ, φ}`), `metric`은 정방 메트릭 행렬. 좌표 기저로 설정됨. |
| `InitCTensor[coSys, metric, basis, opts]` | 비좌표 기저로 초기화. `basis`는 기저 행렬 (`ξ_a = h_a^μ ∂_μ`).                                        |
| `InitCTensor["MetricName"]`               | 사전 정의된 메트릭 파일을 로딩. 예: `InitCTensor["Schwarzschild"]`. `MetricPath`로 경로 제어.              |
| `SetCTensor`                              | `InitCTensor`의 별칭.                                                                      |
| `ClearCTensor[]`                          | 모든 계산된 텐서 성분을 초기화하고 CTensor 환경을 리셋. 새 메트릭으로 전환 시 먼저 호출 필수.                              |

**`InitCTensor` 옵션**:

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `SimplifyMore` | `False` | `True`이면 `CsimplifyMore`를 기본 단순화로 사용. |
| `Verbose` | `False` | `True`이면 계산 단계와 소요 시간을 출력. |
| `GammaCD` | `False` | `True`이면 초기화 시 접속 계수를 자동 계산. |
| `RicciCD` | `False` | `True`이면 초기화 시 리만→리치→스칼라를 자동 계산. |
| `RiemannCD` | `False` | `True`이면 초기화 시 리만 텐서를 자동 계산. |
| `FourDimensionQ` | `True` | `True`이면 4차원을 강제. `False`로 설정하면 다른 차원 허용. |
| `InitCTensor` | `False` | `True`이면 이미 초기화된 상태에서도 재초기화 허용. |

#### 성분 계산

| 함수                          | 사용법                                      |
| --------------------------- | ---------------------------------------- |
| `Tcalc[tensor]`             | 지정된 텐서의 성분을 계산. 의존성이 있는 텐서는 자동으로 먼저 계산됨. |
| `Tcalc[tensor, simpCmd]`    | 단순화 함수 `simpCmd`를 지정하여 계산.               |
| `Tcalc[RiemannCD[i,j,k,l]]` | 리만 텐서의 특정 성분만 계산.                        |

**의존성 체인**: `Tcalc[ScalarCD]` → `Tcalc[RicciCD]` → `Tcalc[RiemannCD]` → `Tcalc[GammaCD]`

**`Tcalc`에 전달 가능한 텐서**:

| 텐서           | 계산 내용                                   |
| ------------ | --------------------------------------- |
| `Structuref` | 구조 상수 `f_{ab}{}^c` (비좌표 기저에서).          |
| `GammaCD`    | 접속 계수 `Γ_{abc}` 및 `Γ_{ab}{}^c`.         |
| `RiemannCD`  | 리만 곡률 텐서 `R_{abcd}`. 대칭성에 의한 독립 성분만 계산. |
| `RicciCD`    | 리치 텐서 `R_{ab}`.                         |
| `ScalarCD`   | 리치 스칼라 `R`.                             |
| `WeylCD`     | 바일 텐서 `C_{abcd}`. 3차원 이상에서만 정의.         |

#### 단순화

| 함수                            | 사용법                                                                                 |
| ----------------------------- | ----------------------------------------------------------------------------------- |
| `Csimplify[expr]`             | 성분 표현식의 단순화. 기본: `Together[expr /. CsimplifyRules] /. CsimplifyRules`. 사용자가 재정의 가능. |
| `CsimplifyMore[expr, assump]` | 더 강력한 단순화. `Simplify`와 가정 `assump`를 사용. `assump` 기본값은 `True&`.                      |
| `CsimplifyRules`              | 사용자 정의 단순화 규칙 리스트. 예: `{Cos[θ]^2 -> 1 - Sin[θ]^2}`.                                 |

#### 측지선

| 함수 | 사용법 |
|------|--------|
| `Geodesic[comp, simpCmd]` | `comp`번째 좌표 성분의 측지선 방정식을 생성. 좌표 기저에서만 사용 가능. `simpCmd`는 단순화 함수. |

#### 기타 심볼

| 심볼 | 설명 |
|------|------|
| `MetricPath` | 사전 정의된 메트릭 파일의 경로. 기본값 `"mGRG`Einstein`Metrics`"`. |

#### Show를 이용한 텐서 성분 표시

`Show[tensor]`로 계산된 텐서의 0이 아닌 성분을 표시 (Mathematica의 `Show`를 오버로딩):

| 호출 | 표시 내용 |
|------|-----------|
| `Show[Metricg]` | 메트릭 텐서의 0이 아닌 성분. |
| `Show[GammaCD]` | 접속 계수의 0이 아닌 성분. |
| `Show[RiemannCD]` | 리만 텐서의 0이 아닌 독립 성분. |
| `Show[RicciCD]` | 리치 텐서의 0이 아닌 성분. |
| `Show[ScalarCD]` | 리치 스칼라 값. |
| `Show[WeylCD]` | 바일 텐서의 0이 아닌 독립 성분. |
| `Show[Structuref]` | 구조 상수의 0이 아닌 성분. |
| `Show[LineElement]` | 선소 `ds²`. `Show[LineElement, simpCmd]`로 단순화 함수 지정 가능. |
| `Show[tName[indices]]` | 임의의 인덱스 텐서의 모든 성분 표시. `indices`는 심볼릭 인덱스로 상/하 상태 지정. |

---

### 3.3 CTensorNP.m — 뉴먼-펜로즈 형식론 (Experimental)

4차원 시공간 전용.

#### 초기화/해제

| 함수                                        | 사용법                                                                                                                                                                                                                  |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `InitCTensorNP[coSys, nullVectors, opts]` | NP 형식론 환경 초기화. `coSys`는 4개 좌표 리스트, `nullVectors`는 4×4 null tetrad 행렬 `{l, n, m, m̄}`. NP 메트릭 `{{0,-1,0,0},{-1,0,0,0},{0,0,0,1},{0,0,1,0}}`이 자동 설정됨. 구조 상수, 접속 계수, 스핀 계수, 리만 텐서, 리치 텐서, $Ψ_i$, $Φ_{ij}$가 순서대로 자동 계산됨. |
| `SetCTensorNP`                            | `InitCTensorNP`의 별칭.                                                                                                                                                                                                 |
| `ClearCTensorNP[]`                        | NP 관련 모든 정의와 계산 결과를 초기화.                                                                                                                                                                                             |

**`InitCTensorNP` 옵션**:

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `SimplifyMore` | `False` | `True`이면 `CsimplifyMore` 사용. |
| `InitCTensor` | `False` | `True`이면 재초기화 허용. |

#### Null tetrad 생성

| 함수                         | 사용법                                                                                                             |
| -------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `BasisNP[metric, simpCmd]` | 4×4 메트릭에서 NP null tetrad `{l, n, m, m̄}`를 자동 생성. `simpCmd`는 단순화 함수 (기본 `Csimplify`). 역메트릭의 성분 구조에 따라 알고리즘이 분기됨. |

#### 로렌츠 회전

| 함수                                               | 사용법                                                                                                                                                                                    |
| ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RotateNP[nullVectors, classN, p1, p2, simpCmd]` | null tetrad에 로렌츠 회전을 적용. `classN`은 회전 유형: `1` = `l`에 대한 null 회전, `2` = `n`에 대한 null 회전, `3` = 스핀-부스트. `p1`, `p2`는 회전 파라미터 (복소 파라미터 = `p1 + I*p2`). `simpCmd`는 단순화 함수 (기본 `Csimplify`). |

#### 출력 심볼

| 심볼                 | 설명                                                                                 |
| ------------------ | ---------------------------------------------------------------------------------- |
| `PsiNP[i]`         | 바일 스칼라 (`i` = 0~4). Ψ₀~Ψ₄. `Show[PsiNP]`로 표시.                                      |
| `PhiNP[i, j]`      | 리치 텐서의 비대각합 부분의 NP 성분. Φ₀₀, Φ₀₁, Φ₀₂, Φ₁₁, Φ₁₂, Φ₂₂. `Show[PhiNP]`로 표시.            |
| `LambdaNP`         | $\Lambda = -(R_{12} - R_{34})/12$.                                                 |
| `SpinCoefficients` | 12개 복소 스핀 계수의 총칭. `Show[SpinCoefficients]`로 α, β, γ, ε, κ, λ, μ, ν, π, ρ, σ, τ 표시. |
| `PetrovType`       | 페트로프 분류. `Show[PetrovType]`로 타입 표시 (I, II, III, D, N, O).                          |

---

### 3.4 사전 정의된 메트릭 (`.../Kernel/Einstein/Metrics/`)

`InitCTensor["MetricName"]`으로 로딩 가능한 메트릭들:

| 메트릭 이름                | 파일                    | 설명                 |
| --------------------- | --------------------- | ------------------ |
| `"Schwarzschild"`     | `Schwarzschild.m`     | 슈바르츠실트 시공간.        |
| `"Kerr"`              | `Kerr.m`              | 커 시공간.             |
| `"KerrNewman"`        | `KerrNewman.m`        | 커-뉴먼 시공간.          |
| `"ReissnerNordstrom"` | `ReissnerNordstrom.m` | 라이스너-노르드스트룀 시공간.   |
| `"RobertsonWalker"`   | `RobertsonWalker.m`   | 로버트슨-워커 시공간 (우주론). |

**메트릭 파일 구조** (새 메트릭 추가 시 템플릿):
```wolfram
(* 1. 단순화 규칙 *)
CsimplifyRules = {규칙들...}

(* 2. Csimplify 재정의 *)
Csimplify[expr_] := ...

(* 3. 상수 선언 *)
SetAttributes[G, Constant]; SetAttributes[M, Constant]

(* 4. 메트릭 성분 설정 *)
Table[Metricg[-i,-j] = 0, {i, 4}, {j, 4}]
Metricg[-1,-1] = ...

(* 5. 초기화 *)
InitCTensor[{t, r, θ, φ}, Table[Metricg[-i,-j], ...], opts]
```
