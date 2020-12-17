---
title: "User guide"
weight: 2
description: >
  This page tells you how to get started with the Compose theme, including installation and basic configuration.
---
---

## IREC 

<h3>What is IREC</h3>

A cross platform framework to recover driver's communication interface. It aims to recover communication interface for fuzzing a kernel driver.

<h3>IREC structure</h3>

```
IREC
├── test-drivers                           # Test drivers to verify that madcore is working.
├── projects                               # Driver analysis projects
│   ├── symbolic                          # Techniques using symbolic execution.
│   ├── static                            # Techniques using static analysis techniques
│   └──wdm.py                             # WDM driver analysis framework
└── irec.py                                # Main module

```

<h3>Install</h3>
We recommend python3.8 virtual environment to use IREC.

```shell
# install virtualenv
$ pip install virtualenv
$ pip install virtualenvwrapper

# make virtual environment
$ virtualenv [virtual env name]
$ source [virtual env name]/bin/activate

$ deactivate
```

It requires angr, radare2 to use symbolic-analysis and static-analysis.

```shell
# use symbolic-analysis
$ pip install angr boltons argparse ipdb

# use static-analysis
$ apt install radare2
$ pip install r2pipe

```



## IRPT

<h3>Getting started</h3>

This project is based on [kAFL: HW-assisted Feedback Fuzzing for x86 Kernels](https://github.com/intelLabs/kAFL/). So, there is overlapping parts on Installation.

Installation requires multiple components, some of which can depend on Internet connectivity and defaults of your distribution / version. It is recommended to install step by step.

```shell
$ git clone [irpt]
$ cd ~/kafl
$ ./install.sh deps     # check platform and install dependencies
$ ./install.sh perms    # allow current user to control KVM (/dev/kvm)
$ ./install.sh qemu     # git clone qemu-pt and build Qemu
$ ./install.sh linux    # git clone kvm-pt and build Linux
```

It is safe to re-execute any of these commands after failure, for example if not all dependencies could have been downloaded.

The final step does not automatically install the new Linux kernel but only gives some default instructions. Install according to your preference/distribution defaults, or simply follow the suggested steps:

```shell
$ ./install.sh note
```

After reboot, make sure the new kernel is booted and PT support is detected by KVM:

```shell
$ sudo reboot
$ dmesg|grep VMX
 [VMX-PT] Info:   CPU is supported!
 ```

You must set the correct path to the Qemu binary in `kAFL-Fuzzer/irpt.ini`.

Launch `irpt.py` to get a help message with the detailed list of parameters:

```shell
$ python3 ~/kafl/kAFL-Fuzzer/kafl_fuzz.py -h
```

<h3>Setting Qemu</h3>

Before you launch `irpt.py`, you should be take a snapshot of Qemu with `loader.exe`. `loader.exe` is a file to load a target driver and `agent.exe`. Compile `loader.c` file to `loader.exe`:

```shell
$ ~/irpt/targets/compile_loader.sh
```
If you prepare the binary in `targets/bin/loader.exe`, you can launch `vm.py` to take a snapshot of Qemu. 

Launch `vm.py` to get a help message with the detailed list of parameters:

```shell
$ python vm.py
```

> <h3>Caution!<h3>  <h3>Snapshot mode is not available to access internet. You can launch `vm.py` with boot mode and download the binary inside the Qemu first.</h3>


## IRCAP

You should compile a driver that can capture the IRP from target driver. It saves the captured IRP file. You can use the file to select the seed when IRPT is launched.


## Monitor

You can monitor the fuzzer while it is running. We tried to make afl style to make it easier to recognize. There may be some side effects because It's an experimental function.

<h3>Monitor mode on/off </h3>

You can use the monitor mode if you just add `-tui` option.

```bash
$ python irpt.py ... -mode fuzz -tui
```
##### ![diy](/images/monitor.gif)


<h3>Process timing</h3>

```
+----------------------------------------------------+
|        run time : 0 days, 1 hrs, 30 min, 43 sec    |
|   last new path : 0 days, 0 hrs, 5 min, 40 sec     |
| last uniq crash : none seen yet                    |
|  last uniq hang : 0 days, 1 hrs, 24 min, 32 sec    |
+----------------------------------------------------+
```
This section tells you how long the fuzzer has been running and how much time has elapsed since its most resent finds. This is broken down into "paths" (a shorthand for corpus that trigger new execution patterns), crashes, and hangs.

There’s one important thing to watch out for: if the tool is not finding new paths within several minutes of starting, you’re probably not invoking the target driver correctly and it never gets to parse the input files we’re throwing at it. The input file should be follow the IRP program format.

<h3> Overall results</h3>

```
+-----------------------+
|  cycles done : 40     |
|  total paths : 12     |
| uniq crashes : 0      |
|   uniq hangs : 1      |
+-----------------------+
```

The first field in this section gives you the count of program mutates done so far - that is, the number of times the program that is input corpus went over all mutation logic. After the program finish a cycle, it creates a new program through the optimizer or executes a next cycle in order of the program in which they are scored. 

The next field shows you the number of different paths each program passes each time it is sent to the target driver. You can recognize the program is being mutated to find new coverages.

The remaining fields is the number of unique faults. The test cases, crashes, and hangs can be explored in real-time by browsing the `out` directory, as discussed in Interpreting output.

<h3>Cycle progress</h3>

```
+-------------------------------------+
|  now processing : 14                |
|  total programs : 13 (4 unique)     |
+-------------------------------------+
```

The box tells you how far along the fuzzer is with the cycle. It shows the ID of the program it is currently working on. The total programs is all program that is made by the fuzzer and if the 

<h3>Map coverage</h3>

```
+--------------------------------------+
|   total edges : 77                   |
|   map density : 0.01% / 0.06%        |
+--------------------------------------+
```

The section provides some trivia about the coverage observed by the target binary. The first line in the box deals with the counts of branch tuples the fuzzer has hit in the binary.

The other line in the box tells you how many branch tuples the fuzzer has already hit, in proportion to how much the bitmap can hold. The number on the left describes the current program, the one on the right is the value for the entire corpus.

<h3>Stage progress</h3>

```
+-------------------------------------+
|   now trying : AFLdetermin          |
| stage yields : 4/48.7k (0.01%)      |
|  total execs : 76.2k                |
|   exec speed : 1104/sec             |
+-------------------------------------+
```

This part gives you an in-depth peek at what the fuzzer is actually doing right now. It tells you about the current stage.

- AFLdetermin: a mutation logic with a pre-made formula without random intervention. It was designed in the same arithmetic logic of afl.
- splice: a last-resort strategy that kicks in after the first full queue cycle with no new paths. It is equivalent to ‘havoc’, except that it first splices together two random inputs from the program at some arbitrarily selected midpoint.
- insertIRP: a stage that new IRP packets containing another IOCTL codes are placed in the program.
- swapIRP: a mutation stage of the IRPs sequence. Several IRP packets are placed in a single program. The order dependency can meet by the sequence of transferring IRPs.
- removeIRP: a stage that removes IRP in the program.
- havoc: a sort-of-fixed-length cycle with stacked random tweaks. The operations attempted during this stage include bit flips, overwrites with random integers, block deletion, block duplication, plus assorted dictionary-related operations.

There’s the exec count progress indicator for the current stage, a global exec counter, and a benchmark for the current program execution speed. It's based on the execution criteria of the fuzzer that it sends an IRP to target driver once.

<h3>Findings in depth</h3>

```
+--------------------------------------+
| favored paths : 0 (0.00%)            |
|  new edges on : 10                   |
| total crashes : 0 (0 unique)         |
|  total tmouts : 1 (1 unique)         |
+--------------------------------------+
```

This gives you several metrics that are of interest mostly to complete nerds. The section includes the number of paths that the fuzzer likes the most based on a minimization algorithm baked into the code (these will get considerably more air time), and the last test cases that actually resulted in better edge coverage. There are also additional, more detailed counters for crashes and hangs. 

The last two sections tell the total  / unique counters of crashes and hangs. In irpt, crasher algorithm checks if newer crash / hang is produced in same context with crash / hang made before. In last line, Tmout counter indicates exactly the same thing to hang in irpt.

<h3>Fuzzing strategy yields</h3>

```
+-----------------------------------------------------+
|   insertIRP : 0/5327                                |
|     swapIRP : 5/4003                                |
|   mutateArg : 8/7749                                |
| AFLdetermin : 9/23.0k                               |
|      splice : 10/11.8k                              |
|   removeIRP : 0/21.0k                               |
+-----------------------------------------------------+
```

This is just another nerd-targeted section keeping track of how many paths we have netted, in proportion to the number of execs attempted, for each of the fuzzing strategies discussed earlier on. This serves to convincingly validate assumptions about the usefulness of the various approaches taken by irpt.

<h3>Path geometry</h3>

```
+---------------------+
|    level  : 3       |
|   pending : 7       |
|  pend fav : 2       |
| uniq prog : 7       |
|    reload : 0       |
+---------------------+
```

The first field in this section tracks the path depth reached through the guided fuzzing process. In essence: the initial test cases supplied by the user are considered “level 1”. The test cases that can be derived from that through traditional fuzzing are considered “level 2”; the ones derived by using these as inputs to subsequent fuzzing rounds are “level 3”; and so forth. The maximum depth is therefore a rough proxy for how much value you’re getting out of the instrumentation-guided approach taken by irpt.

The next field shows you the number of inputs that have not gone through any fuzzing yet. The same stat is also given for “favored” entries that the fuzzer really wants to get to in this database cycle (the non-favored entries may have to wait probabilistically to get their chance).

Last, we have the number of unique programs found during this fuzzing section and number of VMs reloaded by crash / hangs. In irpt, if fault events is occurred, VM(Qemu instance) is to be  shut downed then restarted.