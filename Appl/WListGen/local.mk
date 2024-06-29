##############################################################################
#
# PROJECT:      Build a new (!) word list for Word Matcher
#               Local Makefile
# FILE:         LOCAL.MK
#               by RABE-Soft 06/2024
#
# AUTHOR:       Rainer Bettsteller
#
##############################################################################


# XGOCFLAGS werden an dan GOC-Pre-Prozessor Åbergeben


# Keine EC-Version anlegen - Do not Create any EC version
# NO_EC = 1


# XCCOMFLAGS werden an den C-Compiler Åbergeben


# LINKFLAGS werden an den GLUE-Linker Åbergeben

# Create a Copyrigth-notice
LINKFLAGS += -N "Tool by RABE-Soft 06/2024"

#include <$(SYSMAKEFILE)>

