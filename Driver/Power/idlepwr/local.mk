#
#	$Id: local.mk,v 1.1 97/04/18 11:48:17 newdeal Exp $
#

.PATH.asm .PATH.def : ../Common $(INSTALL_DIR:H)/Common

#PROTOCONST	= POWER
#
# Dec 2025: mkmf has bugs when being used with drivers.
# PROTOCONST = POWER can't be set here, it must be added
# to the Makefile in Installed, along with LIBNAME = power
# and a "clean" afterwards.
# Don't call mkmf for this project - idlepwr will not compile
# after using mkmf.
#

#include <$(SYSMAKEFILE)>
