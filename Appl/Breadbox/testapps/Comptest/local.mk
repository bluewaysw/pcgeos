##############################################################################
#
# PROJECT:      
#               Local Makefile
# FILE:         LOCAL.MK
#               Copyright (c) by RABE-Soft 06/2024
#
# AUTHOR:       Rainer Bettsteller
#
##############################################################################


# XGOCFLAGS werden an dan GOC-Pre-Prozessor übergeben


# Keine EC-Version anlegen - Do not Create any EC version
# NO_EC = 1


# XCCOMFLAGS werden an den C-Compiler übergeben


# LINKFLAGS werden an den GLUE-Linker übergeben

# Create a Copyrigth-notice
LINKFLAGS += -N "(c) by RABE-Soft 06/2024"

#include <$(SYSMAKEFILE)>

