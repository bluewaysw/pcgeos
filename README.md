# PC/GEOS
This repository is the offical place to hold all the source codes around the PC/GEOS graphical user
interface and its sophisticated applications. It is the source to build SDK and release version of PC/GEOS.
It is the place to collaborate on further developments.

![Screenshot showing a typical GEOS desktop](Techdocs/Markdown/Art/title-screenshot.png)

The base of this repository is the source code used to build Breadbox Ensemble 4.13 reduced by some modules identified as critical in regard to the license choosen for the repository.

While now the WATCOM is used to compile the C parts, the full SDK is available for Windows and Linux.

# How to build?

## Prerequisites
The SDK requires "sed" (https://en.wikipedia.org/wiki/Sed) and "perl" (https://en.wikipedia.org/wiki/Perl) to be installed. Both are pre-installed in most Linux-distributions. Windows-users should install "sed" by adding the usr/bin of the official git distribution (https://git-scm.com) to the path (or Cygwin), and should use the perl-variant "Strawberry Perl" (http://strawberryperl.com/).

On Linux if you want to use swat for debugging with good system integration is is required to install xdotools package. It ensures swat receives the keyboard focus once needed. 

## Install WATCOM and set environment
- Unzip WATCOM tools from a suitable [release-tar-gz](https://github.com/open-watcom/open-watcom-v2/releases/download/2020-12-01-Build/ow-snapshot.tar.gz) snapshot (currently tested: 2020-12-01) for instance to `C:\WATCOM-V2`
- add WATCOM env variable: `WATCOM=c:\WATCOM-V2`
- set `BASEBOX=basebox` to use the advanced emulator backend from [pcgeos-basebox](https://github.com/bluewaysw/pcgeos-basebox/tags) if it is on the executable path, alternatively you may provide the full path to the executable as well
- set `ROOT_DIR` to the root of the checkout
- set `LOCAL_ROOT` to a local working directory (can be empty at first, but should be under `pcgeos`, so you can use it for development of your own apps as well)
- add `C:\WATCOM-V2\binnt` to your system path variable
- add `bin` of the checkout of this repo to path variable
- add sed and perl to path variable - note the order to avoid loading the wrong Perl version. Example:

        set WATCOM=c:\WATCOM-V2
        set ROOT_DIR=C:\Geos\pcgeos
        set LOCAL_ROOT=c:\Geos\pcgeos\Local
        set BASEBOX=basebox
        PATH %WATCOM%\binnt;%ROOT_DIR%\bin;C:\Geos\pcgeos-basebox\binnt;%PATH%;c:\Program Files\Git\usr\bin

Document is work in progress.... stay tuned!


## Building PC/GEOS SDK
Build pmake tool:

    cd %ROOT_DIR%/Tools/pmake/pmake
    wmake install

Build all the other SDK Tools:

    cd %ROOT_DIR%/Installed/Tools
    pmake install

Build all PC/GEOS (target) components:

    cd %ROOT_DIR%/Installed`
    pmake`

Build the target environment:

    perl %ROOT_DIR%/Tools/build/product/bbxensem/Scripts/buildbbx.pl

  - the answers to the questions from the above perl-script are:
    - nt (for the platform)
    - y (for the EC version)
      - Alternatively, reply "n" for the NC ("release") version that is faster and corresponds to the actual release
      - The EC ("debug") version has stricter error checking and is better suited for debugging
    - n (as the build for Double-Byte Character Sets is not yet fully functional)
    - y (for the geodes)
    - n (for the VM files)
    - and then you'll have to enter the path to a "gbuild"-folder in your LOCAL_ROOT-folder.
  - BTW: It's expected that the current version of the perl-script creates several "Could not find file _name_ in any of the source trees."-messages.
  - Advanced use: You can use the EC target and the NC target simultaneously.
    - Build the EC target (answers nt/y/n/y/n/path). The path should end with `gbuild.ec`.
    - Build the NC target (answers nt/y/n/y/n/path). The path should end with `gbuild` or `gbuild.nc`.
    - The `target` command (see below) starts the EC target by default. To start the NC target, enter `target -n`.

Launch the target environment in dosbox:
- make sure dosbox is added to your path variable, or [pcgeos-basebox](https://github.com/bluewaysw/pcgeos-basebox/tags) is installed and configured using BASEBOX environmental variable
- `%ROOT_DIR%/bin/target` to launch the EC ("debug") version
  - the "swat" debugger stops immediately after the first stage of the boot process
  - enter `quit` at the "=>" prompt to detach the debugger and launch PC/GEOS stand-alone
    - or: enter `c` to launch with the debugger running in the background (slower)

## Customize target environment
If you want to customize the target environment settings only for yourself, you should not change the file `%ROOT_DIR%/bin/basebox.conf`.
- Create a file called basebox_user.conf in %LOCAL_ROOT% folder.
- Enter the new settings here. These settings overwrite those from basebox.conf. Example:
  - [cpu]
  - cycles=55000


# How to develop?

PC/GEOS comes with extensive technical documentation that describes tools, programming languages and API calls from the perspective of an SDK user. This documentation can be found in the `TechDocs` folder and is available in Markdown format.

You can find a browseable, searchable version of the documentation here: https://bluewaysw.github.io/pcgeos/

##
We are on https://discord.com/ for more efficient collaboration. Please register at https://discord.gg/qtMqgZXhf9 for blueway.Softworks or use an existing discord-account to get access to our developer community. Welcome!
