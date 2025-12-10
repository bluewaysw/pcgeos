
#include <$(SYSMAKEFILE)>

# NO_EC = 1


# The manual says I should do this... ;-)
XGOCFLAGS = -L rsftool

# -zc	place const data into code segment (is set by default)
# -zu	SS != DGROUP (i.e., do not assume stack is in data segment, set by default)
# XCCOMFLAGS = -zc -zu

# Create a Copyrigth-notice
LINKFLAGS += -N "Made by RABE-Soft 04/2020-07/25"


