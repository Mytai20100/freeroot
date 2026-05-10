# PROOT Installer

## Overview
Hmm this shell script is designed to automate the installation of Mytai20100, a lightweight any operating system environment using Proot.

## Prerequisites

- Bash shell environment
- Internet connectivity
- Wget installed
- Supported CPU architecture: x86_64 (amd64) , aarch64 (arm64) or aarch32 (armhf and armel)

## Installation

step 1. Clone the repository:

    
    git clone https://github.com/Mytai20100/freeroot.git
    cd freeroot
    
    
step 2. Run the installer script:

  ```sh
    ./noninteractive.sh
  ```
or
    
  ```sh
    bash noninteractive.sh
  ```

## Supported Architectures

- x86_64 (amd64)
- aarch64 (arm64)
- aarch32 (armhf and armel)

## License

This Proot Installer script is released under the [MIT License](LICENSE).
## Credit 
thx your script:[foxytouxxx](https://github.com/foxytouxxx/freeroot)
## Launch your vps with proot
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/Mytai20100/freeroot.git/HEAD)
# Change Log

* **Nov 9, 2024**
  Added `proot-aarch64`, `proot-x86_64`, `root.sh` from foxytouxxx.
  Added `Debian.sh`, `Ubuntu.sh` by me.

* **Nov 10, 2024**
  Fixed some issues in `Ubuntu.sh`.

* **Nov 23, 2024**
  Updated some components in `root.sh` and `Ubuntu.sh`.

* **Nov 24, 2024**
  Minor update to `root.sh`.

* **Oct 5, 2025**
  Added `noninteractive.sh`, updated to Ubuntu 24.04, but encountered errors → reverted back to 22.04.

* **Oct 6, 2025**
  General fixes and improvements.

* **Dec 28, 2025**
  Fixed Java reset issue.

* **Feb 10, 2026**
  Updated hostname to `"node"`, fixed disk detection.

* **Mar 10, 2026**
  Added BusyBox support for `wget` and `tar`.

* **May 10, 2026**
  Switched to custom proot from [https://github.com/Mytai20100/freeproot/](https://github.com/Mytai20100/freeproot/)
  Improved compatibility (non-flag execution + better isolation than old proot).