# PC/GEOS
This repository is the offical place to hold all the source codes around the PC/GEOS graphical user
interface and its sophisticated applications. It is the source to build SDK and release version of PC/GEOS.
It is the place to collaborate on further developments.

The basement of this repository is the source code used to build Breadbox Ensemble 4.13 reduced by some modules identified as critical in regard to the license choosen for the repository.

# How to build?

## Compiling under Debian 10

- Clone the repository
- Run `bash compile-under-Linux.sh`

## Install WATCOM
- Unzip WATCOM tools from the latest [release-tar-gz](https://github.com/open-watcom/open-watcom-v2/releases/download/Current-build/ow-snapshot.tar.gz) for instance to C:\WATCOM-V2
- add C:\WATCOM-V2\binnt to your system path variable
- add pcgeos\bin of the checkout of this repo to path variable
- add perl to path variable
- add WATCOM env variable: WATCOM=c:\WATCOM-V2
- set ROOT_DIR=
- set LOCAL_ROOT if needed

Document is work in progress.... stay tuned!

## Building PC/GEOS SDK
Build pmake tool:
- cd pcgeos/Tools/pmake/pmake
- wmake install

Build all the other SDK Tools:
- cd pcgeos/Installed/Tools
- pmake

Build all PC/GEOS (target) components:
- cd pcgeos/Installed
- pmake

## Running PC/GEOS in DOSBox

For running you need fonts in "Nimbus Q" format placed under *ensemble/userdata/font*.
You can get the font files (*.fnt) from a previous release of PC/GEOS, Geoworks or Breadbox or by downloading (after registration) from http://blog.bluewaysw.de/packages-for-download .

After getting the font files in place, you can start PC/GEOS in DOSBox under Linux with:

	bash start-in-dosbox.sh

We are on https://bluewaysw.slack.com/ for more efficient collaboration. If you are a collaborator by issuing a pull request and you are registered at blog.bluewaysw.de for MyGEOS you will be invited to join us. Welcome!
