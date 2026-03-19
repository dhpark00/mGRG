# mGRG 소개

Wolfram 언어로 구현한 인덱스를 갖는 (`General Relativity and Gravitation` 분야) 텐서의 다양한 연산

- mPerm: 텐서의 대칭 표현을 위한 순열군

- STensor: Symbolic 텐서 연산

- Einstein: 일반상대론에서의 텐서 성분 계산

# mGRG 설치

1. 직접 설치

      1. 원하는 로컬 폴더에 `mGRG/*.*` 복사

      2. Paclet 폴더 설정: Mathematica 노트북에서 다음 명령을 실행

            `PacletDirectoryLoad[".../로컬 폴더/mGRG"]`

      3. 패키지 로드: Mathematica에서

            << mGRG\`STensor\`
  
            또는

            << mGRG\`Einstein\`

2. PacletInstall 방법

      1. Release 페이지에서 paclet 파일에 마우스 우클릭하여 '링크 주소 복사' 클릭

      2. Mathematica에서

            `PacletInstall["복사한 링크 주소 붙여넣기"]`

# License

이 패키지는 학술 및 연구 목적으로 자유롭게 사용할 수 있습니다.