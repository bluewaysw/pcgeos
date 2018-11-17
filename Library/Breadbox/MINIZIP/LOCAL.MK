#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L minizip

# -d     reduces the size of the dgroup by merging duplicate strings.
# -WDE   compile for SS != DS
# -w-stu turn off "undefined structure" warning
#XCCOMFLAGS = -d -Z -O -1- -2- -3- -WDE -w-stu -DZ_BUFSIZE=4096 -DUNZ_BUFSIZE=4096
XCCOMFLAGS = -d -WDE -w-stu -DZ_BUFSIZE=4096 -DUNZ_BUFSIZE=4096

# Create a Copyrigth-notice
#LINKFLAGS += -N (c)\20by\20RABE-Soft\2010/99



