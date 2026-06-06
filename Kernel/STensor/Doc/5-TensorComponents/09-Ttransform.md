# TensorComponents — Ttransform

`mGRG`STensor`` 패키지의 `TensorComponents.m`에서 제공하는 미분동형사상(diffeomorphism)에 대한 좌표 변환 함수이다.

---

### Ttransform

#### 함수 시그니처

```wolfram
Ttransform[leftT, rightT, leftCoSys, rightCoSys, simpCmd]
```

#### 설명 (Details)

좌표 변환에 따른 텐서 성분의 변환 값을 얻는다. 첫 번째와 두 번째 인자는 관련된 텐서 표현 또는 텐서 이름이고, 세 번째와 네 번째 인자는 두 좌표계에 대한 리스트 표현이다. 옵션으로 simplification을 위한 함수가 올 수 있다. 텐서에 대한 인자는 성분값을 알고 있는 경우는 텐서 표현, 변환된 값을 알고 싶은 경우는 텐서의 이름을 사용한다.

$\{x\} \to \{y\}$의 변환에서:

$$M_a{}^b = \frac{\partial y^b}{\partial x^a}, \quad N_a{}^b = \frac{\partial x^b}{\partial y^a}$$

$$(T')^{ab} = M_c{}^a M_d{}^b T^{cd}, \quad \omega'_{ab} = N_a{}^c N_b{}^d \omega_{cd}$$

$$T' = M^T T \, M, \quad \omega' = N \, \omega \, N^T$$

Notation: [Jacobian matrix] = $M^T$

For diffeomorphism, $N = M^{-1}$.

#### 예제 (Examples) 1

**Familiar Calculation — 구면좌표 계량 변환:**

```wolfram
leftCoSys = {r, θ, ϕ}; rightCoSys = {x, y, z};
forM = {x → r Sin[θ] Cos[ϕ], y → r Sin[θ] Sin[ϕ], z → r Cos[θ]};

MM = Table[D[rightCoSys /. forM, leftCoSys[[i]]], {i, Length[leftCoSys]}]
```

**rightT 성분을 알고 leftT 성분을 모르는 경우: leftT ← rightT$_{ab}$**

```wolfram
Tdefine[leftT, "ba"]; Tdefine[rightT, "ba"]

SetComponents[rightT[la, lb], {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}];

(* Jacobian 행렬로 계산 *)
MM.{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}.Transpose[MM] // Simplify
(* {{1, 0, 0}, {0, r², 0}, {0, 0, r² Sin[θ]²}} *)

(* Ttransform으로 계산 *)
Ttransform[leftT, rightT[la, lb], leftCoSys, rightCoSys /. forM, Simplify];
Table[leftT[-i, -j], {i, 3}, {j, 3}]
(* {{1, 0, 0}, {0, r², 0}, {0, 0, r² Sin[θ]²}} *)
```

**leftT$_{ab}$ → rightT:**

```wolfram
Inverse[MM].{{1, 0, 0}, {0, r², 0}, {0, 0, r² Sin[θ]²}}.
  Transpose[Inverse[MM]] // Simplify
(* {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}} *)

Ttransform[leftT[la, lb], rightT, leftCoSys, rightCoSys /. forM, Simplify];
Table[rightT[-i, -j], {i, 3}, {j, 3}]
(* {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}} *)
```

**leftT ← rightT$^{ab}$:**

```wolfram
Transpose[Inverse[MM]].{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}.
  Inverse[MM] // Simplify
(* {{1, 0, 0}, {0, 1/r², 0}, {0, 0, Csc[θ]²/r²}} *)

Ttransform[leftT, rightT[ua, ub], leftCoSys, rightCoSys /. forM, Simplify];
Table[leftT[i, j], {i, 3}, {j, 3}]
(* {{1, 0, 0}, {0, 1/r², 0}, {0, 0, Csc[θ]²/r²}} *)
```

**leftT$^{ab}$ → rightT:**

```wolfram
Transpose[MM].{{1, 0, 0}, {0, 1/r², 0}, {0, 0, Csc[θ]²/r²}}.MM // Simplify
(* {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}} *)

Ttransform[leftT[ua, ub], rightT, leftCoSys, rightCoSys /. forM, Simplify];
Table[rightT[i, j], {i, 3}, {j, 3}]
(* {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}} *)
```

#### 예제 (Examples) 2

See MathTensor, section 8.2

```wolfram
leftCoSys = {x, y, z}; rightCoSys = {x + K y, y, z};

MM = Table[D[rightCoSys, leftCoSys[[i]]], {i, 3}]
(* {{1, 0, 0}, {K, 1, 0}, {0, 0, 1}} *)
```

**leftT ← rightT$_{ab}$:**

```wolfram
SetComponents[rightT[la, lb], {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}];

MM.{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}.Transpose[MM]
(* {{1, K, 0}, {K, 1+K², 0}, {0, 0, 1}} *)

Ttransform[leftT, rightT[la, lb], leftCoSys, rightTCoSys];
Table[leftT[-i, -j], {i, 3}, {j, 3}]
(* {{1, K, 0}, {K, 1+K², 0}, {0, 0, 1}} *)
```

**leftT ← rightT$^{ab}$:**

```wolfram
SetComponents[rightT[ua, ub], {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}];

Transpose[Inverse[MM]].{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}.Inverse[MM]
(* {{1+K², -K, 0}, {-K, 1, 0}, {0, 0, 1}} *)

Ttransform[leftT, rightT[ua, ub], leftCoSys, rightCoSys];
Table[left[i, j], {i, 3}, {j, 3}]
(* {{1+K², -K, 0}, {-K, 1, 0}, {0, 0, 1}} *)
```

**leftT$^{ab}$ → rightT:**

```wolfram
Transpose[MM].{{1+K², -K, 0}, {-K, 1, 0}, {0, 0, 1}}.MM // Simplify
(* {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}} *)

Ttransform[leftT[ua, ub], rightT, leftCoSys, rightCoSys];
Table[rightT[i, j], {i, 3}, {j, 3}]
(* {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}} *)
```

#### 참고 (See Also)

`Pushforward`, `Pullback`, `PushTensor`
