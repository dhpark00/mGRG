# Tech Note: 좌표 변환 워크플로 (Coordinate Transformation Workflow)

Pushforward, Pullback, PushTensor, Ttransform을 이용한 텐서의 좌표 변환 워크플로를 다룬다. 벡터/covector/혼합 텐서 변환, 계량 텐서 변환, Jacobian 행렬 직접 계산과의 비교를 포함한다.

> 자세한 함수 설명은 `08-PushforwardPullback.md`, `09-Ttransform.md` 참고.

---

## 1. 개요 -- 좌표 변환 함수의 선택 가이드

| 상황                         | 함수                       | 비고                                   |
| -------------------------- | ------------------------ | ------------------------------------ |
| 벡터(위 인덱스) 변환               | `Pushforward`            | $\xi'^a = M_i{}^a \xi^i$             |
| covector(아래 인덱스) 변환        | `Pullback`               | $\omega_i = M_i{}^a \omega'_a$       |
| 혼합 인덱스 텐서 ($M$과 $N$ 모두 필요) | `PushTensor`             | $T'^a{}_b = M_i{}^a N_b{}^j T^i{}_j$ |
| 미분동형사상 (성분 알려진 텐서)         | `Ttransform`             | 양방향, 성분값 직접 대입                       |
| 순수 위/아래 인덱스 텐서             | `Pushforward`/`Pullback` | rank-2도 가능                           |

핵심 선택 기준:
- **인덱스가 모두 같은 방향** → `Pushforward` 또는 `Pullback`
- **위/아래 인덱스가 섞인 텐서** → `PushTensor` (forM과 forN 모두 필요)
- **이미 성분값을 알고 있고 미분동형사상에 따른 새 좌표계의 값을 구하고 싶을 때** → `Ttransform`

---

## 2. Jacobian 행렬과 변환 공식

좌표 변환 $\{x\} \to \{y\}$에서 행렬 $M$과 $N$:

$$M_i{}^a \equiv \frac{\partial y^a}{\partial x^i}, \quad N_a{}^i \equiv \frac{\partial x^i}{\partial y^a}$$

mGRG에서 Jacobian 행렬을 직접 계산하는 방법:

```wolfram
fromCoSys = {x, y}; toCoSys = {u, v};
forM = {u → x^2 + y^2, v → z^2 - y^2};

(* Jacobian: MM[i, a] = ∂(toCoSys_a)/∂(fromCoSys_i) *)
MM = Table[D[toCoSys /. forM, fromCoSys[[i]]],
  {i, Length[fromCoSys]}] // Simplify
```

**Notation**: `MM`이 Jacobian 행렬이며, mGRG에서는 $[M^T]$로 표기한다 (전치 규약에 주의).

---

## 3. Pushforward: 벡터 변환

### 기본 사용법

```wolfram
fromCoSys = {x, y}; toCoSys = {u, v};
forM = {u → Log[x^2 + y^2], v → x/y};

(* 벡터 {a, b}를 {x,y}에서 {u,v}로 변환 *)
Pushforward[{a, b}, fromCoSys, toCoSys /. forM]
(* {2(ax+by)/(x²+y²), (-bx+ay)/y²} *)

(* Jacobian 행렬을 직접 사용한 동일 계산 *)
Transpose[MM].{a, b} // Simplify
(* 동일 결과 *)
```

### 곡선의 접선벡터

$\{x = t^2, y = t^3, z = t^3\}$의 접선벡터를 구하려면:

```wolfram
fromCoSys = {t}; toCoSys = {x, y, z};
forM = {x → t^2, y → t^3, z → t^3};

Pushforward[{1}, fromCoSys, toCoSys /. forM]
(* {2t, 3t², 3t²} *)
```

### 접평면의 기저

곡면 $z = x^3 - 3xy^2$의 접평면 기저:

```wolfram
fromCoSys = {x, y}; toCoSys = {x, y, z};
forM = {x → x, y → y, z → x^3 - 3x y^2};

Pushforward[{1, 0}, fromCoSys, toCoSys /. forM]
(* {1, 0, 3(x² - y²)} *)

Pushforward[{0, 1}, fromCoSys, toCoSys /. forM]
(* {0, 1, -6xy} *)
```

---

## 4. Pullback: covector와 텐서 변환

### 기본 사용법

Pullback은 covector (1-form)를 변환한다. 방향이 Pushforward와 반대임에 주의:

```wolfram
fromCoSys = {x, y}; toCoSys = {u, v, w};
forM = {u → x + 2y, v → 3x + 4y, w → 5x + 6y};

Pullback[{v, w, u}, fromCoSys, toCoSys /. forM]
(* {5u + v + 3w, 2(3u + v + 2w)} *)

% /. forM // Simplify
(* {23x + 32y, 32x + 44y} *)
```

### rank-2 텐서의 Pullback

행렬(2-form 또는 계량 텐서)을 Pullback할 수 있다:

```wolfram
(* 구면좌표에서의 2-form *)
fromCoSys = {r, θ, ϕ}; toCoSys = {x, y, z};
forM = {x → r Cos[θ] Sin[ϕ], y → r Sin[θ] Sin[ϕ], z → r Cos[θ]};

Pullback[{{0, z, -y}, {-z, 0, x}, {y, -x, 0}},
  fromCoSys, toCoSys /. forM]
% /. forM // Simplify
(* {{0, 0, 0}, {0, 0, -r³Cos[θ]Cos[ϕ]Sin[ϕ]}, {0, r³..., 0}} *)
```

### 유도 계량 (Induced Metric)

매핑 $\{u, v\} \to \{x, y, z\}$에서 토러스의 유도 계량:

```wolfram
fromCoSys = {u, v}; toCoSys = {x, y, z};
forM = {x → (a + b Sin[v]) Cos[u],
        y → (a + b Sin[v]) Sin[u], z → b Cos[v]};

(* 유클리드 계량의 Pullback = 유도 계량 *)
Pullback[{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}},
  fromCoSys, toCoSys /. forM]
(* {{(a + b Sin[v])², 0}, {0, b²}} *)
```

---

## 5. PushTensor: 혼합 인덱스 텐서 변환

PushTensor는 상하 인덱스가 섞인 텐서를 변환한다. `forM` (순방향)과 `forN` (역방향) 모두 필요하다.

### 기본 사용법

```wolfram
fromCoSys = {x, y, z}; toCoSys = {u, v, w};
forM = {u → x y, v → y, w → x z};
forN = {x → u/v, y → v, z → w v/u};

(* {ua, lb} -- 위 인덱스 a는 forM, 아래 인덱스 b는 forN으로 변환 *)
PushTensor[{ua, lb}, {{1, 0, 0}, {0, 0, 0}, {0, 0, 0}},
  fromCoSys, toCoSys, forM, forN] /. forN
(* {{1, -u/v, 0}, {0, 0, 0}, {w/u, -w/v, 0}} *)
```

### 순수 아래 인덱스 텐서

```wolfram
forN = {};
PushTensor[{la, lb},
  {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}},
  toCoSys, fromCoSys, forN, forM]
(* (Pushforward '반대' 방향인) Pullback과 동일 결과 *)
```

---

## 6. Ttransform: 미분동형사상에 의한 계량 변환

Ttransform은 이미 **성분값을 알고 있는 텐서**를 이용하여 변환을 수행한다.

### 두 가지 방향

```wolfram
Tdefine[leftT, "ba"]; Tdefine[rightT, "ba"]

(* leftT ← rightT: 알고 있는 오른쪽 좌표계의 성분으로부터 왼쪽 좌표계의 성분을 구함 *)
Ttransform[leftT, rightT[la, lb], leftCoSys, rightCoSys /. forM, Simplify]

(* leftT → rightT: 알고 있는 왼쪽 좌표계의 성분으로부터 오른쪽 좌표계의 성분을 구함 *)
Ttransform[left[la, lb], rightT, leftCoSys, rightCoSys /. forM, Simplify]
```

### 구면좌표 계량 변환 예제

```wolfram
leftCoSys = {r, θ, ϕ}; rightCoSys = {x, y, z};
forM = {x → r Sin[θ] Cos[ϕ], y → r Sin[θ] Sin[ϕ], z → r Cos[θ]};

(* 알고 있는 오른쪽 좌표계의 성분 *)
SetComponents[rightT[la, lb], {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}];

(* 구면좌표계 계량 ← 데카르트 좌표계 계량 *)
Ttransform[leftT, rightT[la, lb], leftCoSys, rightCoSys /. forM, Simplify];
Table[leftT[-i, -j], {i, 3}, {j, 3}]
(* {{1, 0, 0}, {0, r², 0}, {0, 0, r² Sin[θ]²}} *)

(* 역방향 검증 *)
Ttransform[leftT[la, lb], rightT, leftCoSys, rightCoSys /. forM, Simplify];
Table[rightT[-i, -j], {i, 3}, {j, 3}]
(* {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}} — 원래의 단위행렬과 동일 *)
```

### Simple Shear 변환

```wolfram
leftCoSys = {x, y, z}; rightCoSys = {x + K y, y, z};

SetComponents[rightT[la, lb], {{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}];

Ttransform[leftT, rightT[la, lb], leftCoSys, rightCoSys];
Table[leftT[-i, -j], {i, 3}, {j, 3}]
(* {{1, K, 0}, {K, 1+K², 0}, {0, 0, 1}} *)
```

---

## 7. Pushforward와 Pullback의 이중성

PushTensor of 1-form for $\{y\} \to \{x\}$는 Pullback for $\{x\} \to \{y\}$에 대응된다:

```wolfram
fromCoSys = {x, y}; toCoSys = {u, v, w};
forM = {u → x + 2y, v → 3x + 4y, w → 5x + 6y};

(* Pullback *)
Pullback[{v, w, u}, fromCoSys, toCoSys /. forM]
(* {5u + v + 3w, 2(3u + v + 2w)} *)

% /. forM // Simplify
(* {23x + 32y, 32x + 44y} *)

(* PushTensor with reversed coordinate systems *)
forN = {};
PushTensor[{la}, {v, w, u}, toCoSys, fromCoSys, forN, forM]
% /. forM // Simplify
(* {23x + 32y, 32x + 44y}  - 위와 동일 결과 *)
```

---

## 8. 실전 예제 모음

### 스테레오그래픽 사영 ($S^2$)

```wolfram
fromCoSys = {u, v}; toCoSys = {x, y, z};
forM = {x → 2u/(1+u²+v²), y → 2v/(1+u²+v²), z → (u²+v²-1)/(1+u²+v²)};

(* 벡터 {a, b}의 Pushforward *)
Pushforward[{a, b}, fromCoSys, toCoSys /. forM]
(* 3D 공간에서의 벡터 성분 *)
```

### Maple's ’s Diﬀerential Geometry Lesson 8 -- Pullback과 Pushforward 비교

```wolfram
fromCoSys = {x, y, z}; toCoSys = {u, v};
forM = {u → x^2 + y^2, v → z^2 - y^2};

(* Pullback *)
Pullback[{v/2, -u/2}, fromCoSys, toCoSys /. forM]
% /. forM // Simplify
(* {x(-y²+z²), y(x²+z²), -(x²+y²)z} *)

(* PushTensor로 동일한 결과 *)
forN = {};
PushTensor[{la}, {v/2, -u/2}, toCoSys, fromCoSys, forN, forM]
% /. forM // Simplify
(* 동일 결과 *)
```
