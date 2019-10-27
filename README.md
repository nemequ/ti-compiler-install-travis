# Intall TI Compilers on Travis

This is just a quick script to install various [TI
compilers](https://www.ti.com/tool/TI-CGT) on Travis CI.

To use this script, just pass it the compiler name(s) you want to
install and it will download the latest version.  Valid namse are:

 * `armcl` — ARM
 * `cl430` — MSP430
 * `cl2000` — C2000
 * `cl6x` — C6000
 * `cl7x` — C7000
 * `clpru` — PRU
 * `all` — all of the above

Alternatively, you can call the script without any arguments and it
will use the CC/CXX environment variables.

Note that the gcc-multilib package is required since the installers
are 32-bit executables.

I strongly suggest you don't copy this script to your repository.
Instead, use curl to download the current version and run it.  This
allows us to update the script as necessary when TI changes things.
Here is an example of proper usage:

```yml
addons:
  apt:
    packages:
    - gcc-multilib

matrix:
  include:
    - env: C_COMPILER=cl7x CXX_COMPILER=cl7x INSTALL_TI_COMPILERS=y

before_install:
###
## If we use the matrix to set CC/CXX Travis overwrites the values,
## so instead we use C/CXX_COMPILER then copy the values to CC/CXX
## here (after Travis has set CC/CXX).
###
- if [ -n "${C_COMPILER}" ]; then export CC="${C_COMPILER}"; fi
- if [ -n "${CXX_COMPILER}" ]; then export CXX="${CXX_COMPILER}"; fi
- if [ "x${INSTALL_TI_COMPILERS}" = "xy" ]; then curl -s 'https://raw.githubusercontent.com/nemequ/ti-compiler-install-travis/master/ti-cgt-install.sh' | /bin/sh; fi
```
