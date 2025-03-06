#include <$(SYSMAKEFILE)>

COMPILE_OPTIONS ?=
#COMPILE_OPTIONS += -DCOMPILE_OPTION_BOOKMARKS
COMPILE_OPTIONS += -DCOMPILE_OPTION_FAVORITES
COMPILE_OPTIONS += -DGLOBAL_INTERNET_BUILD
#COMPILE_OPTIONS += -DCOMPILE_OPTION_PROFILING_ON

COMPILE_OPTIONS += $(.TARGET:X\\[AB\\]/*:S|AB| -DCOMPILE_OPTION_AUTO_BROWSE |g)
COMPILE_OPTIONS += $(.TARGET:X\\[ABDBCS\\]/*:S|ABDBCS| -DCOMPILE_OPTION_AUTO_BROWSE |g)

XGOCFLAGS += $(COMPILE_OPTIONS)
GOCFLAGS += $(COMPILE_OPTIONS)

# -d:  Merge duplicate strings
# -dc: Move strings to code segment
# -Z:  suppress register reloads
# -Os: favor size of execution speed
# JavaScript code uses #if rather than #ifdef
#XCCOMFLAGS = -d -dc -Z -Os -O $(COMPILE_OPTIONS:S|JAVASCRIPT_SUPPORT|JAVASCRIPT_SUPPORT=1|g)
XCCOMFLAGS = -zu $(COMPILE_OPTIONS:S|JAVASCRIPT_SUPPORT|JAVASCRIPT_SUPPORT=1|g)
# removed -zc because it is not compatible with code_seg() pragma

# -N:  Add stack probes to every routine (only for EC builds)
#ifndef NO_EC
#  XCCOMFLAGS += -N
#endif

# Set Copyright notice
#XLINKFLAGS = -N (C)98\20Breadbox\20Computer\20Company $(COMPILE_OPTIONS)
XLINKFLAGS = $(COMPILE_OPTIONS)

full	:: AB
