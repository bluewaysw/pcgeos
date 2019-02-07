#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L html4par

COMPILE_OPTIONS ?=
COMPILE_OPTIONS += $(.TARGET:X\\[JS\\]/*:S|JS| -DJAVASCRIPT_SUPPORT |g)
COMPILE_OPTIONS += $(.TARGET:X\\[JSDBCS\\]/*:S|JSDBCS| -DJAVASCRIPT_SUPPORT |g)

XGOCFLAGS += $(COMPILE_OPTIONS)
GOCFLAGS += $(COMPILE_OPTIONS)

# -WDE: Make sure that SS!=DS situation in library is observed
# -d:   Merge duplicate strings
# -O:   Some other optimizations...
# -Z:   Suppress register reloads
# JavaScript code uses #if rather than #ifdef
#XCCOMFLAGS = -d -O -Z -WDE $(COMPILE_OPTIONS:S|JAVASCRIPT_SUPPORT|JAVASCRIPT_SUPPORT=1|g)
XCCOMFLAGS = $(COMPILE_OPTIONS:S|JAVASCRIPT_SUPPORT|JAVASCRIPT_SUPPORT=1|g)
#if $(PRODUCT) != "NDO2000"
# -dc: Breaks mkmf...  Removed from NDO2000 build.
##XCCOMFLAGS += -dc 
#endif

# -N:  Add stack probes to every routine (only for EC builds)
#ifndef NO_EC
#  XCCOMFLAGS += -N
#endif

# Set Copyright notice
//XLINKFLAGS = -N \(C\)98\20Breadbox\20Computer\20Company $(COMPILE_OPTIONS)
XLINKFLAGS = $(COMPILE_OPTIONS)
