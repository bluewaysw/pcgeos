#include <$(SYSMAKEFILE)>

# The code was ported from C++ and freely mixes declarations and
# statements. Compile in C99 mode so Watcom accepts that.
XCCOMFLAGS += -za99
