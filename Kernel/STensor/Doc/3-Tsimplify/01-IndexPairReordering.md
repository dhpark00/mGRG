# Tsimplify — 인덱스 쌍 재배열 (DnUpPair, UpDnPair)

`mGRG`STensor`` 패키지의 `Tsimplify.m`에서 제공하는 인덱스 쌍 재배열 함수들이다.

---

### DnUpPair

#### 함수 시그니처

```wolfram
DnUpPair[expr, opts]
```

#### 설명 (Details)

표현식에서 가능한 모든 up-dn 인덱스 쌍을 dn-up 쌍으로 변환한다. 이는 각 쌍의 위 첨자(upper index)와 아래 첨자(lower index)를 서로 바꾸는 것과 동일하다.

- 옵션으로 `HeadQs`와 `CovDs`가 있다.
- 공변 도함수가 아닌 연산자(BD 등)의 인덱스는 기본적으로 재배열 대상에서 제외된다. `CovDs -> {CD, BD}` 옵션으로 포함 가능하다.
- `CovDs` 옵션으로 지정하는 연산자는 미리 정의되어 있어야 한다.
- 잘못된 인덱스 입력(중복 인덱스 등)에 대해 경고 메시지를 출력한다.

#### 예제 (Examples)

```wolfram
Tdefine[Z, "*"]; Tdefine[v, 1]

(* 인덱스 쌍이 한 텐서 안에 있는 경우 *)
Z[ub, lc, ld, lb]
DnUpPair[%]
(* Z^b_cdb → Z_acd^a  -- 인덱스가 자동 재조정됨 *)

(* 연산자가 있는 경우 *)
BD[ua, CD[ub, Z[la, lb, lc, ud]]]
DnUpPair[%]
(* ∂^a∇^bZ_abc^d → ∂^a∇_bZ_a^b_c^d *)

CD[ua, CD[ub, Z[la, lb, lc, ud]]]
DnUpPair[%]
(* ∇^a∇^bZ_abc^d → ∇_a∇_bZ^ab_c^d *)

(* LD가 포함된 경우 *)
CD[ua, LD[v, Z[la, ud, le, lf]]] × v[ld]
DnUpPair[%]
(* ∇^a𝓛_vZ_a^d_ef v_d → ∇^a𝓛_vZ_a^b_ef v_b  -- 인덱스가 자동 재조정됨 *)

(* CovDs 옵션 *)
CD[ua, BD[la, Z[ub, ld, le, lf]]] × v[lb]
DnUpPair[%]
(* ∇^a∂_aZ^b_def v_b → ∇_a∂^aZ^b_def v_b *)

DnUpPair[%%, CovDs -> {CD, BD}]
(* ∇_a∂^aZ_bdef v^b *)

(* 잘못된 입력 시 경고 *)
BD[ua, CD[ub, Z[lc, lb, ld, ue]]] × v[lb]
DnUpPair[%]
(* Msg: duplicated indices: {ua, ub, lc, lb, ld, ue, lb} *)
```

#### 참고 (See Also)

`UpDnPair`, `Tsimplify`, `TindexSort`

---

### UpDnPair

#### 함수 시그니처

```wolfram
UpDnPair[expr, opts]
```

#### 설명 (Details)

표현식에서 가능한 모든 dn-up 인덱스 쌍을 up-dn 쌍으로 변환한다. 이는 각 쌍의 아래 첨자(lower index)와 위 첨자(upper index)를 서로 바꾸는 것과 동일하다. `DnUpPair`의 역연산이다.

- 옵션으로 `HeadQs`와 `CovDs`가 있다.
- 공변 도함수가 아닌 연산자의 인덱스는 기본적으로 재배열 대상에서 제외된다.
- `CovDs` 옵션으로 BD 등 비공변 연산자의 인덱스도 재배열 대상에 포함할 수 있다.
- 잘못된 인덱스 입력(중복 인덱스 등)에 대해 경고 메시지를 출력한다.

#### 예제 (Examples)

```wolfram
Tdefine[Z, "*"]; Tdefine[v, "a"]

(* 인덱스 쌍이 한 텐서 안에 있는 경우 *)
Z[lb, lc, ld, ub]
UpDnPair[%]
(* Z_bcd^b → Z^a_cda  -- 인덱스 자동 재조정 *)

(* 연산자가 있는 경우 *)
BD[la, CD[lb, Z[ua, ub, lc, ud]]]
UpDnPair[%]
(* ∂_a∇_bZ^ab_c^d → ∂_a∇^bZ^a_bc^d *)

CD[la, CD[lb, Z[ua, ub, lc, ud]]]
UpDnPair[%]
(* ∇_a∇_bZ^ab_c^d → ∇^a∇^bZ_abc^d *)

(* LD가 포함된 경우 *)
CD[la, LD[v, Z[ua, ld, le, lf]]] × v[ud]
UpDnPair[%]
(* ∇_a𝓛_vZ^a_def v^d → ∇_a𝓛_vZ^a_bef v^b  -- 인덱스 자동 재조정 *)

(* CovDs 옵션 *)
CD[la, BD[ua, Z[lb, ld, le, lf]]] × v[ub]
UpDnPair[%]
(* ∇^a∂_aZ_bdef v^b *)

UpDnPair[%%, CovDs -> {CD, BD}]
(* ∇^a∂_aZ^b_def v_b *)

(* 잘못된 입력 시 경고 *)
BD[la, CD[lb, Z[lc, ub, ld, ue]]] × v[ub]
UpDnPair[%]
(* Msg: duplicated indices: {la, lb, lc, ub, ld, ue, ub} *)
```

#### 참고 (See Also)

`DnUpPair`, `Tsimplify`, `TindexSort`
