---
title: "Overview"
weight: 1
---

## Pre-View
---
드라이버는 장치와 운영체제가 서로 통신할 수 있도록 해주는 소프트웨어 구성요소이다. 장치를 사용하기 위해선 커널 수준의 권한이 필요하기 때문에 자연스레 드라이버는 커널 레벨의 특권 수준을 가진다. 때문에 드라이버에서 보안 결함이 존재할 경우 일반적인 유저 권한 애플리케이션과는 달리 Windows 커널 권한이 침해되는 심각한 문제로 이어질 수 있다. 

그동안 Windows 드라이버의 보안성 증진을 위한 많은 노력들이 있었지만, 유저 권한 소프트웨어에 비해 퍼징 (Fuzzing은 자동으로 인풋 값을 생성하고 프로그램에 주입하여 결함 여부를 확인하는 기술이다. 인간이 예상하기 어려운 소프트웨어의 결함을 발견하고 안정성과 보안성을 테스트하기 위해 다양한 방면에 활용되고 있다.)과 같은 효율적인 기술의 적용에 많은 어려움을 겪어왔다. 

드라이버는 커널 메모리에 로드되기 때문에, 드라이버의 안정성 테스트를 진행하기 위해서는 반드시 커널 영역에 접근해야 한다. 이 커널 구성요소를 대상으로 퍼징을 진행하는 것이 굉장히 어려우며, 특히나 커버리지 가이디드 퍼징을 커널 영역에 적용하는 것에는 더더욱 어렵다. 

또한 커널 수준에서 드라이버는 IRP(I/O Request Packet)라는 구조체를 이용하여 애플리케이션의 요구들을 처리한다. 좀 더 구체적으로 이야기하면, 드라이버의 내부에 존재하는 DeviceIOControl 함수가 외부에서 보내온 IRP에 담긴 핸들러 코드인 IOCTL CODE에 해당하는 각 루틴을 처리한다. 이때 각 루틴에 대한 inputBuffer 내용과 inputBufferLength등 다양한 constraint 들에 의해 루틴에 대한 접근 여부가 결정된다. 게다가 드라이버 내부 루틴에서 특정 루틴의 실행으로 말미암아 다른 루틴에서 사용되는 전역변수의 값이 세팅되는 등의 경우가 존재하는데, 이를 ordering dependency라고 표현한다. 이처럼 드라이버를 대상으로 원할한 퍼징을 진행하기 위해서는 하나의 IOCTL 처리 루틴에 접근하기 위한 Constraints와 여러 IOCTL 처리 루틴들 간의 ordering dependency를 알아내야 한다.

또한 커버리지 가이디드 퍼징을 커널 레벨에 적용하기 위해선 커널레벨 에서의 커버리지 계측, Driver interface에 대한 고려가 선행되어야 한다. 그동안 커널과 드라이버를 대상으로한 퍼징이 어려웠던 이유는 위와 같은 이유 때문이다. 이에 driverThru팀은 이 두가지 문제를 해결한 간편하고 신속한 드라이버 퍼징 프레임워크를 개발해, 드라이버의 보안성 향상과 안전한 사이버 세상의 도래에 이바지하고자 한다.

#
#
#
#
#

## IREC

---

퍼징은 프로그램의 구석구석에 존재하는 루틴에 접근해보는 것 즉, 커버리지를 넓히는 것이 굉장히 중요하다. 만약 드라이버의 인터페이스 정보가 없으면 IOCTL 처리 루틴에 대한 제약 조건을 해결하지 못하여 접근할 수 없는 루틴이 발생하고, 이는 곧 퍼징에서 커버리지를 원할히 넓힐 수 없다는 것을 의미한다. 즉, 드라이버의 구조적인 특징으로 인해 드라이버 인터페이스 정보에 대한 분석 없이는 효율적인 퍼징이 불가능하다.   

게다가 드라이버는 제조사마다, 드라이버마다 고유한 constraints 값을 가지고 있기 때문에 드라이버를 퍼징에 적용하기 위해서는 각 드라이버들이 가지고 있는 고유한 contraint 들을 전부 일일히 찾아주어야 한다. 드라이버는 `.sys` 파일 형태로 제공되는 클로즈드 소스가 대부분이므로, Reverse Engineering과 같은 기술을 이용해 interface를 복원해야 하는데, 매 퍼징을 시작할때마다 이러한 과정을 수동으로 하는 것은 매우 비효율적이며 불가능에 가깝다.  설령 이것이 가능하다고 한들, 결국 인간이 손으로 진행해야하는 작업이기 때문에 실수와 오탐이 존재하지 않으리란 보장은 없다.

이에 (DRIFT?, URF???)를 개발한 driverThru 팀은 커널 퍼징의 효율을 높이고 드라이버의 보안성 증진을 위해 수많은 드라이버들의 구조를 신속하고 간편하게 복원할 수 있는 도구를 개발하고자 했다.

그렇게 탄생 한것이 바로 [IREC(Interface RECovery)](https://github.com/kirasys/madcore) 이다.  IRREC 도구는 Symbolic Execution을 이용한 angr 프레임워크를 이용하여 wdm 드라이버의 `.sys` 파일을 대상으로 해당 드라이버의 고유한 IOCTL CODE들, InBufferLength, OutBufferLength와 같은 constraints 정보를 `.json` 파일의 형태로 자동으로 뽑아준다. 이렇게 생성된 `.json` 파일은 추후 IRPT(I/O Request & intel-PT based Fuzzer?)의 실행루틴에서 kAFL의 agent에 해당하는 코드로 자동으로 변환된다. IRREC을 이용하여 wdm 드라이버의 Constraints 를 아주 손쉽고 빠르게 뽑아낼 수 있다.
#
#
#
#
#
## Fuzzer

---

kAFL: Hardware-Assisted Feedback Fuzzing for OS Kernels에서는 커널 영역의 interrupts, kernel threads, statefulness, and similar mechanisms 으로 인한 non-determinism가 커널퍼징을 더욱 어렵게 한다고 이야기하기도 했다. 커널 영역은 유저 랜드에서는 다른 메모리 구조를 가지고 있을 뿐더러 interrupt등과 같은 예상치 못한 다양한 요청에 의해 실행 흐름이 변환될 수 있기 때문에, 특정 타겟의 영역(? 범위?)에만 집중해서 퍼징 테스트를 진행하기 쉽지 않다는 것이다.

또한 퍼징 루틴의 실행으로 커버리지 증감에 대한 피드백을 받기 위해선 계측이 필요하다. 코드가 공개된 오픈 소스 유저랜드 프로그램 같은 경우 AFL instrumentation과 같은 코드를 컴파일 하는 기법을 이용해 손쉽게 계측을 할 수 있다. 하지만 Windows 커널은 클로즈드 소스이기 때문에, 코드에 내부를 수정하는 instrumentation 기법을 이용하는 것이 불가능하다.

이에 KAFL에서 사용한 intel-PT 기술을 차용하여 커버리지 증감에 대한 계측을 진행했다. kAFL에서 개발한 KVM-PT와 QEMU-PT및 hypercall 통신 기술을 이용하여 타겟 드라이버가 로드된 VM과 뮤테이션을 진행하는 퍼저간의 의사소통을 구현했다.
##### ![diy](/images/kaflfig.png)
kAFL: Hardware-Assisted Feedback Fuzzing for OS Kernels에서는 커널 영역의 interrupts, kernel threads, statefulness, and similar mechanisms 으로 인한 non-determinism가 커널퍼징을 더욱 어렵게 한다고 이야기하기도 했다. 커널 영역은 유저 랜드에서는 다른 메모리 구조를 가지고 있을 뿐더러 interrupt등과 같은 예상치 못한 다양한 요청에 의해 실행 흐름이 변환될 수 있기 때문에, 특정 타겟의 영역(? 범위?)에만 집중해서 퍼징 테스트를 진행하기 쉽지 않다는 것이다.

또한 퍼징 루틴의 실행으로 커버리지 증감에 대한 피드백을 받기 위해선 계측이 필요하다. 코드가 공개된 오픈 소스 유저랜드 프로그램 같은 경우 AFL instrumentation과 같은 코드를 컴파일 하는 기법을 이용해 손쉽게 계측을 할 수 있다. 하지만 Windows 커널은 클로즈드 소스이기 때문에, 코드에 내부를 수정하는 instrumentation 기법을 이용하는 것이 불가능하다.

이에 KAFL에서 사용한 intel-PT 기술을 차용하여 커버리지 증감에 대한 계측을 진행했다. kAFL에서 개발한 KVM-PT와 QEMU-PT및 hypercall 통신 기술을 이용하여 타겟 드라이버가 로드된 VM과 뮤테이션을 진행하는 퍼저간의 의사소통을 구현했다.

### Brute-Force OneCode Fuzzer

그렇게 DriverThru팀에서 개발된 첫번째 퍼저가 바로 Brute-Force OneCode Fuzzer이다.  Brute-Force OneCode Fuzzer는 IRREC에서 뽑아준 constraints 만을 고려하여 단일 IOCTL CODE를 driver에게 전송한다. 하지만 한번의 퍼징 루틴에서 하나의 IOCTL CODE만을 전송하기 때문에 해당 패이로드만으로 드라이버 루틴간의 dependency 충족을 기대하기 힘들다. 더구나 kAFL은 커버리지 확장에 기존 루틴들이 기여한 바가 클지라도 가장 최근의 퍼징 루틴에 의한 피드백 결과만을 반영한다. 이전의 퍼징루틴에 의해 충족된 dependency로 말미암아 마지막으로 실행된 퍼징 루틴이 커버리지가 늘어난 것일 지라도, 피드백을 반영하는 과정에서 기존의 루틴의 기여도는 전부 무시되는 것이다.

이렇듯 Brute-Force OneCode Fuzzer는 퍼징 중 IOCTL 처리 루틴간의 dependency 충족을 전적으로 운에 의존하며, 설령 운이 좋게도 발견한 결함을 재현하기 위해서는 퍼징 중 드라이버에 전송했던 모든 패이로드를 전부 드라이버에 전달해야 한다는 치명적인 단점이 존재한다.

### Brute-Force MultiCode Fuzzer

Brute-Force OneCode Fuzzer의 치명적인 문제를 해결하기 위해서 개발한 driverThru팀의 두번째 퍼저가 바로 Brute-Force MultiCode Fuzzer이다. Brute-Force MultiCode Fuzzer는 OneCode Fuzzer의 치명적인 단점인 단일 IOCTL CODE처리로 인한 피드백 반영 불가 문제를 해결하기 위해 뮤테이션에 의해 생성된 패이로드를 디코딩한 뒤 여러개의 IOCTL CODE로 분해하여 Target Driver에 전송했다.  또한 드라이버의 상태가 기존의 퍼징 루틴에 의해 영향 받는 것을 차단하고 Driver로 전달하는 단일 패이로드만으로 IOCTL 처리 루틴간의 dependency를 충족시키기 위해 매 퍼징 루틴마다 드라이버의 상태를 초기화 하는 로직을 추가하였다. 이를 통해 여러 IOCTL 처리 루틴간의 dependency 충족으로 말미암아 증가한 커비리지에 대한 피드백 정보를 받는 것이 가능해졌다.

허나 Brute-Force MultiCode Fuzzer에도 단점이 존재했다. Brute-Force MultiCode Fuzzer는 퍼저에 의해 뮤테이션이 완벽하게 종료된 패이로드를 IOCTL CODE와 그에 따른 inputBeffer로 디코드하는 방식을 이용했다. 퍼저가 뮤테이션 단계에서 패이로드의 구조를 이해하지 않은 것이 Brute-Force MultiCode Fuzzer의 치명적인 단점이다. 이를 바꾸어 이야기 하면, IOCTL CODE와 inputBuffer를 퍼저가 능동적으로 구분하여 뮤테이션을 진행하지 못한다는 것이다. Brute-Force라는 단어가 퍼저의 이름에 들어간 이유는 바로 이러한 이유 때문이다. 퍼저는 패이로드를 생성할때, Driver interface를 전혀 고려하지 않고 뮤테이션을 진행한다는 점에서 분명한 운적 요소(Lucky!)가 존재하기 때문이다.

### IRPT

DriverThru팀은 효율적인 드라이버 퍼징 프레임워크 구축이라는 관점에서 Brute-Force MultiCode Fuzzer 또한 이상적으로 추구하는 Driver의 안정성 테스트를 위한 퍼저에 적합하지 않다고 판단했다. 이에 퍼저가 무작위로 만든 하나의 패이로드를 여러개의 IOCTL CODE로 보내는 것 을 넘어, 각 IOCTL CODE와 그에 따른 inputBuffer, IOCTL CODE의 전송 순서 등의 dependency를 퍼저가 능동적으로 고려하여 각각의 뮤테이션을 진행하는 기술을 구현할 수 있으면 좋겠다고 생각했고, 이를 위해 새롭게 개발한 퍼저가 바로 IRPT이다.
##### ![diy](/images/irptfig.png)
DriverThru팀은 효율적인 드라이버 퍼징 프레임워크 구축이라는 관점에서 Brute-Force MultiCode Fuzzer 또한 이상적으로 추구하는 Driver의 안정성 테스트를 위한 퍼저에 적합하지 않다고 판단했다. 이에 퍼저가 무작위로 만든 하나의 패이로드를 여러개의 IOCTL CODE로 보내는 것 을 넘어, 각 IOCTL CODE와 그에 따른 inputBuffer, IOCTL CODE의 전송 순서 등의 dependency를 퍼저가 능동적으로 고려하여 각각의 뮤테이션을 진행하는 기술을 구현할 수 있으면 좋겠다고 생각했고, 이를 위해 새롭게 개발한 퍼저가 바로 IRPT이다.



{{< button "./compose/" "DRIFT Docs" >}}

{{< button "./clarity/" "Clarity Theme Docs" >}}