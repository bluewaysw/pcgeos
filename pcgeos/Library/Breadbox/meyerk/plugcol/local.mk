#####################################################################
# MODULE:       Local makefile
# FILE:         local.mk
#####################################################################
#
#
# Flags to make the C-Compiler put the dgroup in 
# ds before calling functions so we can use global variables there.
XCCOMFLAGS += -WDE -d
#
# Put our copyright message in geode (32 char. max.).
LINKFLAGS += -N Copyright\20(C)\20by\20MeyerK
#
#
# Turn off error-checking.
##NO_EC = 1
#
# Something for the installable FM Tools
#
_PROTO = 1.0
#
# Include the system makefile.
#include <$(SYSMAKEFILE)>
#