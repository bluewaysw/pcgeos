#####################################################################
# MODULE:       Local makefile
# FILE:         local.mk
#####################################################################
#
#
# Prepare for conditional linking
XESPFLAGS  += -DENG -DR4
XGOCFLAGS  += -DENG -DR4
XCCOMFLAGS += -DENG -DR4
XLINKFLAGS += -DENG -DR4
#
#
# Put our copyright message in geode (32 char. max.).
LINKFLAGS += -N Copyright\20(C)\20by\20MeyerK
#
#
_REL = 1.6.0.0
#
#
# Turn off error-checking.
#NO_EC = 1
#
#
# Include the system makefile.
#include <$(SYSMAKEFILE)>