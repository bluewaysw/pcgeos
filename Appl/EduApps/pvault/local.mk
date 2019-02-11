#include <$(SYSMAKEFILE)>

#Pick a build version
#COMPILE_OPTIONS ?= -DNSAFE_BUILD
#COMPILE_OPTIONS += -DCOMPILE_OPTION_EXPIRE_ON
COMPILE_OPTIONS += -DDESKTOP_BUILD

XGOCFLAGS += $(COMPILE_OPTIONS)
GOCFLAGS += $(COMPILE_OPTIONS)

# -d:  Merge duplicate strings
# -Z:  suppress register reloads
# -Os: favor size of execution speed
# -1- -2- -3-: ensure that pure 8086 code is generated
#XCCOMFLAGS = -d -dc -Z -Os -O -WDE $(COMPILE_OPTIONS)
#XCCOMFLAGS = -d -Z -Os -O -WDE $(COMPILE_OPTIONS)

# -N:  Add stack probes to every routine (only for EC builds)
#ifndef NO_EC
#  XCCOMFLAGS += -N
#endif

# Set Copyright notice
XLINKFLAGS = -N "(C)2019 blueway.Softworks" $(COMPILE_OPTIONS)

