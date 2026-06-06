# Tsimplify — 인덱스 정렬 (TindexSort)

`mGRG`STensor`` 패키지의 `Tsimplify.m`에서 제공하는 인덱스 정렬 함수이다.

---

### TindexSort

#### 함수 시그니처

```wolfram
TindexSort[expr]
```

#### 설명 (Details)

텐서 표현식을 구성하는 각각의 텐서에 독립적으로 작용하여, 각 텐서의 대칭성에 기반한 표준 순서(canonical order)로 인덱스를 정렬한다.

- 텐서 인덱스의 순열 대칭 때문에 자동으로 0이 되는가를 확인한다. 만일 0이 아니면 `MakePermGroup` 함수를 이용하여 **모든 가능한** 인덱스 표현을 얻고, `IndexOrderedQ` 함수를 이용하여 최소가 되는 인덱스 표현을 구한다.
- 각각 한 개의 텐서만을 대상으로 하기 때문에 과도한 대칭에 의한 연산 시간의 지수적 증가를 걱정할 필요는 없다.
- 성분 인덱스(정수)에 대해서도 동작한다.
- BD 연산자의 인덱스 대칭도 처리한다.
- (Torsion-free인 경우, 함수에 작용하는) 연속한 CD 연산자의 인덱스 대칭도 처리한다.

#### 예제 (Examples)

```wolfram
Tdefine[e, "*-"]; Tdefine[A, "-ba"]; Tdefine[S, "ba"]

(* 반대칭 텐서 *)
{A[la, lb], A[lb, la], A[ua, la]}
TindexSort /@ %
(* {A_ab, -A_ab, 0} *)

{e[], e[la], e[lb, la], e[lc, lb, la], e[ua, lb, la]}
TindexSort /@ %
(* {e, e_a, -e_ab, -e_abc, 0} *)

(* 반대칭 텐서의 성분 인덱스 *)
{A[-2, -1], A[1, -1], A[1, 1], A[-1, -1], A[2, 1]}
TindexSort /@ %
(* {-A_12, -A^1_1, 0, 0, -A^12} *)

(* 대칭 텐서 *)
{S[la, lb], S[lb, la], S[ua, la]}
TindexSort /@ %
(* {S_ab, S_ab, S^a_a} *)

(* BD 연산자의 인덱스 대칭 *)
{BD[lb, ua, A[ub, la]], BD[lb, la, A[ub, ua]]}
TindexSort /@ %
(* {∂_a∂^bA^a_b, 0}  -- 첫 번째 표현은 인덱스가 자동 재조정된 결과임 *)

(* CD 연산자의 인덱스 대칭 *)
Tdefine[f[]]
CD[lb, la, f[]]
% // TindexSort
(* ∇_b∇_af → ∇_a∇_bf  -- CD는 기본적으로 torsion-free *)

(* Kind가 비좌표-기준일 때의 BD 연산 *)
BD[lB, lA, f[]]
% // TindexSort
(* ∂_B∂_Af → ∂_B∂_Af *)
```

#### 참고 (See Also)

`Tsimplify`, `DnUpPair`, `UpDnPair`, `GetSymmetry`
