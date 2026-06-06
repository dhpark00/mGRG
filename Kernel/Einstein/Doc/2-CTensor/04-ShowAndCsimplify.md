# Einstein/CTensor — Show / Csimplify

`mGRG`Einstein`` 패키지의 `CTensor.m`에서 제공하는 표시 및 단순화 함수이다.

---

### Show

#### 함수 시그니처

```wolfram
Show[tensor]
Show[tensor, simpCmd]
```

#### 설명 (Details)

`Show[tensor]`는 계산된 텐서의 0이 아닌 독립 성분을 표시한다. `simpCmd`를 지정하면 출력 전에 해당 함수로 단순화한다.

표시 가능한 대상:

| 대상            | 출력 내용                            |
| ------------- | -------------------------------- |
| `DefaultKind` | 현재 Kind 상태 (플래그, 차원, 좌표, 기저)     |
| `LineElement` | 선요소 $ds^2$                       |
| `Metricg`     | 계량 텐서 성분                         |
| `Structuref`  | 구조 상수 $f_{ab}{}^c$               |
| `GammaCD`     | Christoffel 기호 $\Gamma_{ab}{}^c$ |
| `RiemannCD`   | Riemann 텐서 $R_{abcd}$            |
| `RicciCD`     | Ricci 텐서 $R_{ab}$                |
| `ScalarCD`    | Ricci 스칼라 $R$                    |

#### 예제 (Examples)

```wolfram
InitCTensor["Schwarzschild"]

Show[DefaultKind]
(* AutoFlag: True, ..., InitCTensorFlag: True, ...
   Kind: Latin, Dimension: 4, Sig: Any
   Coordinates: t r θ ϕ
   CoordinateBasisQ: True, EvaluateBDFlag: True *)

Show[LineElement, Simplify]
(* ds² = dr²/(1-2GM/r) + (-1+2GM/r) dt² + r²(dθ² + dϕ² Sin[θ]²) *)

Show[Metricg]
(* Symmetry: g_{(ab)}
   g_tt = -1 + 2GM/r
   g_rr = 1/(1-2GM/r)
   g_θθ = r²
   g_ϕϕ = r² Sin[θ]² *)
```

대칭성 정보(`Symmetry`)가 자동으로 함께 출력된다.

---

### Csimplify / CsimplifyMore

#### 함수 시그니처

```wolfram
Csimplify[expr]
CsimplifyMore[expr, assumptions]
```

#### 설명 (Details)

`Csimplify`는 성분 텐서 계산에서 사용되는 기본 단순화 함수이다. 기본 동작은 `Together`와 유사하다.

`CsimplifyMore`는 `Simplify`에 가정(assumptions)을 추가한 강화된 단순화이다. `InitCTensor`에서 `SimplifyMore → True` 옵션을 설정하면 기본 단순화 방법이 `CsimplifyMore`로 변경된다.

##### 다형성 (Polymorphism)

`Csimplify`는 다형적(polymorphic)이다. `CTensor.m`에서 기본 정의를 제공하지만, 사용자의 필요에 따라 재정의할 수 있다. 아래 예시에서는 사전 정의 파일인 `Schwarzschild.m`에 삼각함수 단순화에 더욱 효율적인 `Csimplify`로 재정의하는  것을 보여 준다:

```wolfram
(* Schwarzschild.m에서의 재정의 예시 *)
SetOptions[Together, Trig → True];
Csimplify[expr_] := Together[expr]
```

`InitCTensor["MetricName"]`으로 계량을 로드하면 해당 계량의 `Csimplify`가 활성화된다.

##### CsimplifyRules

`CsimplifyRules`는 계량별 치환 규칙을 담는 변수이다. 사용자가 확장할 수 있다:

```wolfram
(* 계량 파일에서 설정하는 패턴 *)
CsimplifyRules = {rule1, rule2, ...};
```

#### 참고 (See Also)

`Tcalc`, `InitCTensor`, `Show`
