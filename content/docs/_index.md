---
title: "Overview"
weight: 1
---

## Pre-View
---
Driver is software components that intermediate communication between a device and an Operating System. Since kernel level privileges are required to use the device, the driver has the kernel level privilege level as well. If there are security flaws in the driver, unlike user land applications, it can lead to serious problems in which Windows kernel privileges are violated.

There have been many efforts to improve the security of Windows drivers, but there have been many difficulties in applying effective testing techniques such as fuzzing (Fuzzing is a technique that automatically generates inputs and injects them into a program to check for bugs and software defects. It is used in various fields to test stability and security by detecting defects that are difficult for humans to predict.) compared to user land applications.

Since the driver is loaded into kernel memory, we must access the kernel space to test driver stability. It is very difficult to apply fuzzing to this kernel component. Especially, it is even more difficult to apply coverage-guided fuzzing to the kernel.

At the kernel level, the driver handles application requests in the form of a structure called **`IRP(I/O Request Packet)`**. More specifically, the `DispatchDeviceControl` that exists inside the driver handles each routine corresponding to the IOCTL CODE, which is the handler code contained in the IRP sent from the outside of the driver. At this time, access to the routine is determined by various constraints such as `inputBuffer` contents and `inputBufferLength` for each routine.

In addition, there are cases in which the execution of other routines must precede the execution of a specific routine in the driver. The typical case mentioned above is a case where a global variable set in one routine is used in another routine. We express this situation as an ordering dependency between IOCTL routines. In order to apply fuzzing to Driver without problem, information about the driver interface is required: that satisfies the constraints and dependencies of IOCTL CODE.

Even in order to apply coverage-guided fuzzing to the kernel level, coverage measurement at the kernel level and consideration of the driver interface must be preceded. These causes have made it difficult to fuzz the kernel and driver. So, team driverThru tried to solve these two problems. As we continued our research, we found several ways to solve them, and developed a simple and fast driver fuzzing framework applying these solutions. We hope this tool is useful for improving the stability of Windows drivers and kernel environments.
#
#
#
#
#

## IREC

---

Even in order to apply coverage-guided fuzzing to the kernel level, coverage measurement at the kernel level and consideration of the driver interface must be preceded. These causes have made it difficult to fuzz the kernel and driver. So, team driverThru tried to solve these two problems. As we continued our research, we found several ways to solve them, and developed a simple and fast driver fuzzing framework applying these solutions. We hope this tool is useful for improving the stability of Windows drivers and kernel environments.

In addition, the driver has different constraints for access to each of the IOCTL routines. Therefore, in order to apply the driver to the fuzzer, we have to find the contraints manually. Furthermore, since most of the drivers are distributed in the form of closed sources (.sys), Furthermore, since most of the drivers are distributed in the form of closed source (.sys), Reverse Engineering is required to obtain driver interface information. It is very inefficient to do this manually every time before you start fuzzing. It is very inefficient to do this manually every time before you start fuzzing. Even if this is possible, there is no guarantee that mistakes and false positives will not exist. Humans are not machines.

The team driverThru wanted to develop a tool that can easily recovery the structure of numerous drivers to increase the efficiency of kernel fuzzing.

That is how IREC (Interface RECovery) was born. IREC tool automatically extracts Driver interface information and constraints such as IOCTL CODE, InputBufferLength, OutBufferLength of driver in the form of .json file using angr framework, Symbolic Execution and radare2. 

The generated `.json` file is used as the kAFL agent code in the execution routine of IRPT (I/O Request & Intel-PT based Fuzzer?) later. Using IREC, we can extract the interface information and constraints of the wdm driver very easily and quickly without any further inefficient manual work.

#
#
#
#
#
## Fuzzer

---

*kAFL: Hardware-Assisted Feedback Fuzzing for OS Kernels* noted that non-determinism due to kernel-space interrupts, kernel threads, statefulness, and similar mechanisms makes kernel fuzzing more difficult. The kernel region has a memory structure different from that of the user land, and the execution flow can be changed by various unexpected requests such as interrupts. So it is not easy to perform a fuzzing test focusing only on a specific target region.

In addition, instrumentation is required to receive feedback on coverage increase or decrease by executing the fuzzing routine. In the case of open source user land applications, it is possible to easily measure coverage by using a code compilation technique such as AFL instrumentation, but since the Windows kernel is closed source, it is impossible to use the instrumentation technique to modify the inside of the code.

Accordingly, KRONOL borrowed the idea of using `Intel-PT` technology in the fuzzer from KAFL to measure the increase or decrease of coverage in the kernel. In addition, we modified the KVM-PT, QEMU-PT and hypercall communication technology developed by kAFL to implement communication between the VM loaded with the target driver and the fuzzer performing the mutation.

##### ![diy](/images/kaflfig.png)
kAFL is a very nice tool in that it enables hardware-assisted kernel fuzzing that is not dependent on the OS, but it is far from the ideal fuzzer that the driverThru team pursues. The reason is that kAFL targets only a single IOCTL CODE. This means that the ordering dependency that exists between IOCTL routines cannot be considered.

Therefore, the driverThru team tried to develop a fuzzer that solves the problems that kAFL cannot solve. Based on driver interface information that can be easily obtained using IREC.

### Brute-Force OneCode Fuzzer

So the first fuzzer developed by the DriverThru team is the **Brute-Force OneCode Fuzzer**. Brute-Force OneCode Fuzzer sends one IOCTL CODE per fuzzing routine to target driver considering only constraints such as inputBuffer and inputBufferLength obtained from IREC.

However, since only one IOCTL CODE is sended in one fuzzing routine, it is difficult to expect the  dependency between driver routines to be satisfied only with the payload. Furthermore, kAFL reflects only the feedback result from the most recent fuzzing routine, even though the existing routines have contributed largely to coverage extension. Although the previous fuzzing routine satisfies the ordering dependency and thus the coverage of the last executed fuzzing routine could be increased, all contributions to the previous routine are ignored when coverage feedback is reflected.

As such, Brute-Force OneCode Fuzzer completely relies on luck to satisfy the ordering dependency between IOCTL routines during fuzzing. Even if the fuzzer finds a crash fortunately, there is a fatal drawback that all payloads sent to target driver during fuzzing must be delivered to the driver in order to reproduce.

### Brute-Force MultiCode Fuzzer

The second fuzzer of team driverThru developed to solve the fatal problem of Brute-Force OneCode Fuzzer is Brute-Force MultiCode Fuzzer. **Brute-Force MultiCode Fuzzer** decodes the payload generated by the mutation, devides it into several IOCTL codes, and sends them to target driver. As a result, it is possible to satisfy the ordering dependency between IOCTL routines by delivering only one payload to the driver.
##### ![diy](/images/decodelogic.png)
그러나 Brute-Force MultiCode Fuzzer에도 단점이 존재했다. Brute-Force MultiCode Fuzzer는 드라이버에 보내기 직전의 페이로드를 IOCTL CODE와 inputBeffer로 디코드하는 방식을 이용했다. 퍼저가 뮤테이션 단계에서 페이로드의 구조를 모르는 것이 Brute-Force MultiCode Fuzzer의 치명적인 단점이다. 이를 바꾸어 이야기 하면, IOCTL CODE와 inputBuffer를 퍼저가 능동적으로 구분하여 뮤테이션을 진행하지 못한다는 것이다. Brute-Force라는 단어가 퍼저의 이름에 들어간 이유는 바로 이러한 이유 때문이다. 퍼저는 페이로드를 생성할때, Driver interface를 전혀 고려하지 않고 뮤테이션을 진행한다는 점에서 분명한 운적 요소(Lucky!, 우효!)가 존재하기 때문이다. driverThru팀은 효율적인 드라이버 퍼징 프레임워크 구축을 위해 Brute-Force MultiCode Fuzzer도  Driver의 안정성 테스트를 위한 이상적인 퍼저에 적합하지 않다고 판단했다.

### IRPT

퍼저가 무작위로 만든 하나의 페이로드를 여러개의 IOCTL CODE로 보내는 것을 넘어, 각 IOCTL CODE, inputBuffer, IOCTL CODE의 전송 순서 등의 dependency를 퍼저가 능동적으로 판단하여 각각 뮤테이션을 진행하는 기술을 구현할 수 있으면 좋겠다고 생각했고, 이를 위해 새롭게 개발한 퍼저가 바로 IRPT이다.
##### ![diy](/images/irptfig.png)
  IRPT는 IRP Program 이라는 단위로 IRP 패킷들을 묶어 뮤테이션을 진행하고, 이 IRP Program을 하나의 페이로드로 드라이버에게 전송하는 퍼저이다. Program 내부에 있는 각 IRP에 대한 IOCTL CODE와 inputBuffer 값들을 뮤테이션 하는 것은 물론, IRP의 순서에 대한 뮤테이션도 진행한다. 앞서 언급했던 두개의 Brute-force Fuzzer와 차별화 되는 IRPT만의 특징이자 가장 큰 장점은 바로 IRP의 순서에 대한 뮤테이션이 가능하다는 점이다. 선행되는 IOCTL 루틴으로 dependency가 충족되어 이후 IOCTL 루틴의 커버리지가 증가 한 경우, 커버리지의 증가를 야기한 루틴의 선후 관계를 퍼저가 이해하고 다음 뮤테이션에 이를 반영할 수 있다. 이로써 기존의 퍼저들에서 해결하지 못한 문제들을 성공적으로 해결하고, 효율적인 드라이버 퍼징을 실현할 수 있었다. 


> ##### asdfasdf



{{< button "./compose/" "DRIFT Docs" >}}

{{< button "./clarity/" "Clarity Theme Docs" >}}