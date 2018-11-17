#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L zlib

# -d     reduces the size of the dgroup by merging duplicate strings.
# -WDE   compile for SS != DS
# -w-stu turn off "undefined structure" warning
#
# MAX_MEM_LEVEL=7 and MAX_WBITS = 14 prevents form allocating too large blocks
# of memory             MAX_MEM_LEVEL = 8  and/or MAX_WBITS = 15 will crash
# see ZCONF.H and deflateInit2_() for more details
#XCCOMFLAGS = -d -Z -O -1- -2- -3- -DMAX_MEM_LEVEL=7 -DMAX_WBITS=14  -WDE -w-stu
XCCOMFLAGS = -d -DMAX_MEM_LEVEL=7 -DMAX_WBITS=14  -WDE -w-stu

# Create a Copyrigth-notice
#LINKFLAGS += -N (c)\20G.-L.G.\20M.A.\20M.G.\20R.B.



