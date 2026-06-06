# TensorComponents — Pushforward, Pullback, PushTensor

`mGRG`STensor`` 패키지의 `TensorComponents.m`에서 제공하는 좌표 변환 함수들이다.

---

### Pushforward

#### 함수 시그니처

```wolfram
Pushforward[fromT, fromCoSys, toCoSys, simpCmd]
```

#### 설명 (Details)

벡터 또는 텐서 `fromT`를 좌표계 `fromCoSys`에서 `toCoSys`로 pushforward한다. `simpCmd`는 선택적 simplification 함수이다.

$\{x\} \to \{y\}$의 변환에서:

$$M_i{}^a = \frac{\partial y^a}{\partial x^i} \equiv J^a{}_i, \quad \xi'^a = M_i{}^a \xi^i, \quad \xi' = M^T \xi$$

$$T'^{ab} = M_i{}^a M_j{}^b T^{ij}, \quad T' = M^T \, T \, M$$

$$T'^{abc} = M_i{}^a M_j{}^b M_k{}^c T^{ijk}$$

Notation: [Jacobian matrix] = $M^T$

#### 예제 (Examples)

**Maple's Differential Geometry: Pushforward Ex 1**

```wolfram
fromCoSys = {x, y}; toCoSys = {u, v};
forM = {u → Log[x^2 + y^2], v → x/y};

(* 직접 연산 방법 *)
MM = Table[D[toCoSys /. forM, fromCoSys[[i]]], {i, Length[fromCoSys]}] // Simplify
(* {{2x/(x²+y²), 1/y}, {2y/(x²+y²), -x/y²}} *)

Transpose[MM].{a, b} // Simplify
(* {2(ax+by)/(x²+y²), (-bx+ay)/y²} *)

(* 함수 호출 방법 *)
Pushforward[{a, b}, fromCoSys, toCoSys /. forM]
(* {2(ax+by)/(x²+y²), (-bx+ay)/y²} *)
```

**Pushforward Ex 4 — 극좌표 변환:**

```wolfram
fromCoSys = {x, y}; toCoSys = {r, θ};
leftRule = {x → r Cos[θ], y → r Sin[θ]};
forM = {r → √(x²+y²), θ → ArcTan[y/√(x²+y²), x/√(x²+y²)]};

Pushforward[{y/x, -2}, fromCoSys, toCoSys /. forM]
% /. leftRule // FullSimplify
(* {-r Sin[θ]/√r², (Cos[θ] + Sec[θ])/r} *)
```

**Pushforward Ex 5 — 곡선의 접선벡터:**

```wolfram
fromCoSys = {t}; toCoSys = {x, y, z};
forM = {x → t^2, y → t^3, z → t^3};

Pushforward[{1}, fromCoSys, toCoSys /. forM]
(* {2t, 3t², 3t²} *)
```

**Pushforward Ex 6 — 접평면의 기저:**

```wolfram
fromCoSys = {x, y}; toCoSys = {x, y, z};
forM = {x → x, y → y, z → x^3 - 3x y^2};

Pushforward[{1, 0}, fromCoSys, toCoSys /. forM]
(* {1, 0, 3(x² - y²)} *)

Pushforward[{0, 1}, fromCoSys, toCoSys /. forM]
(* {0, 1, -6xy} *)
```

---

### PushTensor

#### 함수 시그니처

```wolfram
PushTensor[updnL, fromT, fromCoSys, toCoSys, forM, forN, simpCmd]
```

#### 설명 (Details)

텐서 `fromT`를 `fromCoSys`에서 `toCoSys`로 변환한다. `updnL`은 인덱스의 variance(상/하)를 지정한다. `forM`과 `forN`은 변환 규칙이다.

$\{x\} \to \{y\}$의 변환에서:

$$M_i{}^a = \frac{\partial y^a}{\partial x^i}, \quad N_a{}^i = \frac{\partial x^i}{\partial y^a}$$

$$\xi'^a = M_i{}^a \xi^i, \quad \xi' = M^T \xi$$

$$\omega'_a = N_a{}^i \omega_i, \quad \omega' = N \omega$$

$$T'^a{}_b = M_i{}^a N_b{}^j T^i{}_j, \quad T' = M^T \, T \, N^T$$

$$T'_a{}^b = N_a{}^i M_j{}^b T_i{}^j, \quad T' = N \, T \, M$$

#### 예제 (Examples)

**Maple's Differential Geometry: PushPullTensor Ex 1**

```wolfram
fromCoSys = {x, y, z}; toCoSys = {u, v, w};
forM = {u → x y, v → y, w → x z};
forN = {x → u/v, y → v, z → w v/u};

PushTensor[{ua, lb}, {{1, 0, 0}, {0, 0, 0}, {0, 0, 0}},
  fromCoSys, toCoSys, forM, forN] /. forN
(* {{1, -u/v, 0}, {0, 0, 0}, {w/u, -w/v, 0}} *)

PushTensor[{ua}, {1, 0, 0}, fromCoSys, toCoSys, forM, forN] /. forN
(* {v, 0, vw/u} *)

PushTensor[{ua}, {0, 1, 0}, fromCoSys, toCoSys, forM, forN] /. forN
(* {u/v, 1, 0} *)

PushTensor[{ua}, {0, y, 0}, fromCoSys, toCoSys, forM, forN] /. forN
(* {u, v, 0} *)
```

**PushPullTensor Ex 2 — 스테레오그래픽 사영 ($S^3$):**

```wolfram
fromCoSys = {u, v, w}; toCoSys = {x1, x2, x3, x4};
forM = {x1 → 2u/(u²+v²+w²+1), x2 → 2v/(u²+v²+w²+1),
        x3 → 2w/(u²+v²+w²+1), x4 → (u²+v²+w²-1)/(u²+v²+w²+1)};
forN = {};

PushTensor[{la, lb}, {{1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1}},
  toCoSys, fromCoSys, forN, forM]
(* {{4/(1+u²+v²+w²)², 0, 0}, {0, 4/(1+u²+v²+w²)², 0}, {0, 0, 4/(1+u²+v²+w²)²}} *)

(* Pullback 함수를 이용한 동일한 연산 *)
Pullback[{{1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {0, 0, 0, 1}},
  fromCoSys, toCoSys /. forM]
(* {{4/(1+u²+v²+w²)², 0, 0}, {0, 4/(1+u²+v²+w²)², 0}, {0, 0, 4/(1+u²+v²+w²)²}} *)
```

---

### Pullback

#### 함수 시그니처

```wolfram
Pullback[fromT, fromCoSys, toCoSys, simpCmd]
```

#### 설명 (Details)

covector 또는 텐서 `fromT`를 좌표계 `fromCoSys`에서 `toCoSys`로 pullback한다. `simpCmd`는 선택적 simplification 함수이다.

$\{x\} \to \{y\}$의 변환에서:

$$M_i{}^a = \frac{\partial y^a}{\partial x^i}, \quad \omega_i = M_i{}^a \omega'_a, \quad \omega = M \, \omega'$$

$$T_{ij} = M_i{}^a M_j{}^b T'_{ab} = M_i{}^a T'_{ab} (M^T)^b{}_j, \quad T = M \, T' M^T$$

$$T_{ijk} = M_i{}^a M_j{}^b M_k{}^c T'_{abc}$$

Notation: [Jacobian matrix] = $M^T$

#### 예제 (Examples)

**Maple's Differential Geometry: Pullback Ex 1**

```wolfram
fromCoSys = {x, y}; toCoSys = {u, v, w};
forM = {u → x + 2y, v → 3x + 4y, w → 5x + 6y};

Pullback[{v, w, u}, fromCoSys, toCoSys /. forM]
% /. forM // Simplify
(* {5u + v + 3w, 2(3u + v + 2w)} *)
(* {23x + 32y, 32x + 44y} *)
```

**PushTensor of 1-form for $\{y\} \to \{x\}$ corresponds to Pullback for $\{x\} \to \{y\}$:**

```wolfram
forN = {};
PushTensor[{la}, {v, w, u}, toCoSys, fromCoSys, forN, forM]
% /. forM // Simplify
(* {5u + v + 3w, 2(3u + v + 2w)} *)
(* {23x + 32y, 32x + 44y} *)
```

**Pullback Ex 3 — 구면좌표 2-form:**

```wolfram
fromCoSys = {r, θ, ϕ}; toCoSys = {x, y, z};
forM = {x → r Cos[θ] Sin[ϕ], y → r Sin[θ] Sin[ϕ], z → r Cos[θ]};

Pullback[{{0, z, -y}, {-z, 0, x}, {y, -x, 0}}, fromCoSys, toCoSys /. forM]
% /. forM // Simplify
(* {{0, 0, 0}, {0, 0, -r³Cos[θ]Cos[ϕ]Sin[ϕ]}, {0, r³Cos[θ]Cos[ϕ]Sin[ϕ], 0}} *)
```

**Lesson 8 — Pullback/PushTensor 비교:**

```wolfram
fromCoSys = {x, y, z}; toCoSys = {u, v};
forM = {u → x^2 + y^2, v → z^2 - y^2};

Pullback[{v/2, -(u/2)}, fromCoSys, toCoSys /. forM]
% /. forM // Simplify
(* {vx, (u+v)y, -uz} *)
(* {x(-y²+z²), y(x²+z²), -(x²+y²)z} *)

(* 위와 동일한 연산 *)
forN = {};
PushTensor[{la}, {v/2, -(u/2)}, toCoSys, fromCoSys, forN, forM]
% /. forM // Simplify
```

**Lesson 9 — 토러스의 유도 계량:**

```wolfram
fromCoSys = {u, v}; toCoSys = {x, y, z};
forM = {x → (a + b Sin[v]) Cos[u], y → (a + b Sin[v]) Sin[u], z → b Cos[v]};

Pullback[{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}, fromCoSys, toCoSys /. forM]
(* {{(a + b Sin[v])², 0}, {0, b²}} *)

(* 위와 동일한 연산 *)
forN = {};
PushTensor[{la, lb}, {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}, toCoSys, fromCoSys, forN, forM]
```

#### 참고 (See Also)

`Pushforward`, `PushTensor`, `Ttransform`
