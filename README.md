# mTensor

Wolfram 언어로 구현한 인덱스를 갖는 (`General Relativity and Gravitation` 분야) 텐서의 다양한 연산

# mTensor 설치

저장소 전체를 압축한 `mTensor-master.zip`을 `<Mathematica 설치 폴더>/AddOns/Applications/mTensor`에 푼다.

* **반대칭 메트릭 텐서**가 포함된 텐서 표현을 Canonicalization할 필요가 있어서 MathLink 라이브러리인 `xPermCPP64`를 사용하려면 `...\mTensor\mPerm\LibraryResources\src` 폴더에 있는 파일들을 이용하여 각각의 운영 체제 (Windows, Mac-Arm, Linux-x64)에 맞는 바이너리 파일을 빌드한 후 `...\mTensor\mPerm\LibraryResources` 폴더에 위치시킨다.
