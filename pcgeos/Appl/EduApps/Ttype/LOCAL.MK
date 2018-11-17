#include <$(SYSMAKEFILE)>

COMPILE_OPTIONS ?=

XGOCFLAGS += $(COMPILE_OPTIONS)
GOCFLAGS += $(COMPILE_OPTIONS)

# -d:  Merge duplicate strings
# -Z:  suppress register reloads
# -Os: favor size of execution speed
# -1- -2- -3-: ensure that pure 8086 code is generated
#XCCOMFLAGS = -dc -Z -Os -O -WDE $(COMPILE_OPTIONS)

# -N:  Add stack probes to every routine (only for EC builds)
#ifndef NO_EC
#  XCCOMFLAGS += -N
#endif

# Set Copyright notice
XLINKFLAGS = -N (C)98\20Breadbox\20Computer\20Company $(COMPILE_OPTIONS)

