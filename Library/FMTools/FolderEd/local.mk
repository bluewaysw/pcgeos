#####################################################################
# MODULE:       Local makefile
# FILE:         local.mk
#####################################################################
#
#
# Flags to make the C-Compiler put the dgroup in
# ds before calling functions so we can use global variables there.
# XCCOMFLAGS += -WDE -d
#
# Put our copyright message in geode (32 char. max.).
LINKFLAGS += -N "Programmed by Rabe-Soft 2024"

# Turn off error-checking.
# NO_EC = 1

# Something for the installable FM Tools
# Protocol number ist defined in the .rev file
# _PROTO = 1.0
# PROTOCONST	= FMTOOL

# Include the system makefile.
#include <$(SYSMAKEFILE)>
