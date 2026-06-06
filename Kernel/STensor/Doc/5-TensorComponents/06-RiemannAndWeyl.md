# TensorComponents — Riemann and Weyl

`mGRG`Einstein`` 패키지의 `Einstein.m`에서 제공하는 Riemann 텐서와 Weyl 텐서 간의 변환 함수이다.

---

### RiemannToWeyl / WeylToRiemann

#### 설명 (Details)

Weyl 텐서 $C_{abc}{}^d$는 Riemann 텐서 $R_{abc}{}^d$와 다음 관계가 있다:

$$C_{abcd} \equiv R_{abcd} + \left(-\frac{1}{n-2}\left(g_{ac} R_{bd} - g_{ad} R_{bc} + g_{bd} R_{ac} - g_{bc} R_{ad}\right) + \frac{1}{(n-1)(n-2)}\,R\left(g_{ac} g_{bd} - g_{ad} g_{bc}\right)\right)$$

여기서 $n$은 시공간의 차원이다.

이 관계를 이용하여 `RiemannToWeyl`과 `WeylToRiemann`이 Riemann과 Weyl 사이의 변환을 수행한다. 이 함수들은 `Einstein.m`에서 정의되며, `<< mGRG`Einstein``으로 로드할 수 있다.

#### 참고 (See Also)

`RiemannToGamma`, `Tsimplify`, `WeylCD`
