#####################################################################
# MODULE:       Local makefile
# FILE:         local.mk
#####################################################################

# Flags to make the C-Compiler put the dgroup in
# ds before calling functions so we can use global variables there.
XCCOMFLAGS += -zu

# Turn off error-checking version (if adequate).
# NO_EC = 1

# Something for the installable FM Tools (see also fmtools.goh)
# _PROTO = 1.0
# commented out because protocol number is defined in the .rev file

# no .ldf file required here.
#undef LIBOBJ

# Include the system makefile.
#include <$(SYSMAKEFILE)>
