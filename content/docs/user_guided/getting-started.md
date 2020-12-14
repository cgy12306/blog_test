---
title: "User guided"
weight: 2
description: >
  This page tells you how to get started with the Compose theme, including installation and basic configuration.
---
---

## IREC 

<h4>What is IREC</h4>

A cross platform framework to recover driver's communication interface. It aims to recover communication interface for fuzzing a kernel driver.

- IREC structure

```
MadCore
├── test-drivers                           # Test drivers to verify that madcore is working.
├── projects                               # Driver analysis projects
│   ├── symbolic                          # Techniques using symbolic execution.
│   ├── static                            # Techniques using static analysis techniques
│   └──wdm.py                             # WDM driver analysis framework
└── madcore.py                             # Main module
```
  - install

```shell
# install dependencies
$ pip install angr boltons argparse ipdb
```



## IRPT

- install

Installation requires multiple components, some of which can depend on Internet connectivity and defaults of your distribution / version. It is recommended to install step by step and manually investigate any reported errors:

```shell
git clone this_repo ~/kafl

cd ~/kafl
./install.sh deps     # check platform and install dependencies
./install.sh perms    # allow current user to control KVM (/dev/kvm)
./install.sh qemu     # download, patch and build Qemu
./install.sh linux    # download, patch and build Linux
```

It is safe to re-execute any of these commands after failure, for example if not all dependencies could have been downloaded.

The final step does not automatically install the new Linux kernel but only gives some default instructions. Install according to your preference/distribution defaults, or simply follow the suggested steps:

```shell
./install.sh note
```

After reboot, make sure the new kernel is booted and PT support is detected by KVM:

```shell
$ sudo reboot
$ dmesg|grep VMX
 [VMX-PT] Info:   CPU is supported!
 ```
Lauch kAFL-Fuzzer/kafl_fuzz.py to verify all python dependencies are met. You should be able to get a help message with the detailed list of parameters:

```shell
python3 ~/kafl/kAFL-Fuzzer/kafl_fuzz.py -h
```
You may have to hunt down some python dependencies that did not install correctly (try the corresponding package provided by your distribution!), or set the correct path to the Qemu binary in kAFL-Fuzzer/kafl.ini.


## IRCAP
You need a [recent **extended** version](https://github.com/gohugoio/hugo/releases) (we recommend version 0.61 or later) of [Hugo](https://gohugo.io/) to do local builds and previews of sites (like this one) that uses this theme.

If you install from the release page, make sure to get the `extended` Hugo version, which supports [sass](https://sass-lang.com/documentation/file.SCSS_FOR_SASS_USERS.html); you may need to scroll down the list of releases to see it. 

For comprehensive Hugo documentation, see [gohugo.io](https://gohugo.io/).


## Monitor
You need a [recent **extended** version](https://github.com/gohugoio/hugo/releases) (we recommend version 0.61 or later) of [Hugo](https://gohugo.io/) to do local builds and previews of sites (like this one) that uses this theme.

If you install from the release page, make sure to get the `extended` Hugo version, which supports [sass](https://sass-lang.com/documentation/file.SCSS_FOR_SASS_USERS.html); you may need to scroll down the list of releases to see it. 

For comprehensive Hugo documentation, see [gohugo.io](https://gohugo.io/).You need a [recent **extended** version](https://github.com/gohugoio/hugo/releases) (we recommend version 0.61 or later) of [Hugo](https://gohugo.io/) to do local builds and previews of sites (like this one) that uses this theme.

If you install from the release page, make sure to get the `extended` Hugo version, which supports [sass](https://sass-lang.com/documentation/file.SCSS_FOR_SASS_USERS.html); you may need to scroll down the list of releases to see it. 

For comprehensive Hugo documentation, see [gohugo.io](https://gohugo.io/).You need a [recent **extended** version](https://github.com/gohugoio/hugo/releases) (we recommend version 0.61 or later) of [Hugo](https://gohugo.io/) to do local builds and previews of sites (like this one) that uses this theme.

If you install from the release page, make sure to get the `extended` Hugo version, which supports [sass](https://sass-lang.com/documentation/file.SCSS_FOR_SASS_USERS.html); you may need to scroll down the list of releases to see it. 

For comprehensive Hugo documentation, see [gohugo.io](https://gohugo.io/).