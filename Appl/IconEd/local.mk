##############################################################################
#
# PROJECT:	Icon Editor (GOC version)
#
# FILE:         local.mk
#               Ported to GOC by RABE-Soft 07/2025
#
# AUTHOR:       Rainer Bettsteller
#
##############################################################################


# XGOCFLAGS are passed to the GOC-Pre-Prozessor


# Do not Create an EC version
# NO_EC = 1

# XCCOMFLAGS are passed to the C-Compiler


# LINKFLAGS are passed to GLUE-Linker

# Create a Copyrigth-notice
LINKFLAGS += -N "Made by RABE-Soft for freeGEOS"

#include <$(SYSMAKEFILE)>

