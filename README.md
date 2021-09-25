# PC/GEOS
This repository is the offical place to hold all the source codes around the PC/GEOS graphical user
interface and its sophisticated applications. It is the source to build SDK and release version of PC/GEOS.
It is the place to collaborate on further developments.

The base of this repository is the source code used to build Breadbox Ensemble 4.13 reduced by some modules identified as critical in regard to the license choosen for the repository.

While now the WATCOM is used to compile the C parts, the full SDK is available for Windows and Linux.

# How to build?

## Prerequisites
The SDK requires "sed" (https://en.wikipedia.org/wiki/Sed) and "perl" (https://en.wikipedia.org/wiki/Perl) to be installed. Both are pre-installed in most Linux-distributions. Windows-users should install "sed" by installing Cygwin (https://www.cygwin.com/) or by adding the usr/bin of the official git distribution (https://git-scm.com) to the path, and should use the perl-variant "Strawberry Perl" (http://strawberryperl.com/).

On Linux if you want to use swat for debugging with good system integration is is required to install xdotools package. It ensures swat receives the keyboard focus once needed. 

## Install WATCOM
- Unzip WATCOM tools from the latest [release-tar-gz](https://github.com/open-watcom/open-watcom-v2/releases/download/2020-12-01-Build/ow-snapshot.tar.gz) for instance to C:\WATCOM-V2
- add C:\WATCOM-V2\binnt to your system path variable
- add pcgeos\bin of the checkout of this repo to path variable
- add sed and perl to path variable
- add WATCOM env variable: WATCOM=c:\WATCOM-V2
- set ROOT_DIR= to the root of the checkout
- set LOCAL_ROOT if needed
- set BASEBOX=basebox to use the advanced emulator backend from [pcgeos-basebox](https://github.com/bluewaysw/pcgeos-basebox.git) if it is on the executable path, alternatively you may provide the full path to the executable as well

Document is work in progress.... stay tuned!


## Building PC/GEOS SDK
Build pmake tool:
- cd pcgeos/Tools/pmake/pmake
- wmake install

Build all the other SDK Tools:
- cd pcgeos/Installed/Tools
- pmake install

Build all PC/GEOS (target) components:
- cd pcgeos/Installed
- pmake

Build the target environment:
- cd pcgeos/Tools/build/product/bbxensem/Scripts
- perl -I. buildbbx.pl
  - the answers to the questions from the above perl-script are:
    - nt (for the platform)
    - y (for the EC version)
    - n (for the DBCS)
    - y (for the geodes)
    - n (for the VM files)
    - and then you'll have to enter the path to a "gbuild"-folder in your LOCAL_ROOT-folder.
  - BTW: It's expected that the current version of the perl-script creates several "Could not find file _name_ in any of the source trees."-messages.

Launch the target environment in dosbox:
- make sure dosbox is added to your path variable, or [pcgeos-basebox](https://github.com/bluewaysw/pcgeos-basebox.git) is installed and configured using BASEBOX environmental variable
- cd pcgeos
- bin/target
  - the "swat" debugger stops immediately after the first stage of the boot process
  - enter "quit" at the "=>" prompt to detach the debugger and launch PC/GEOS stand-alone
    - or: enter "c" to launch with the debugger running in the background (slower)

We are on https://bluewaysw.slack.com/ for more efficient collaboration. Please register at https://blog.bluewaysw.de for MyGEOS and use the Slack section and receive access to our developer community. Welcome!
