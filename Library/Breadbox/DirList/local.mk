#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L dirlist

# -d     reduces the size of the dgroup by merging duplicate strings.
# -WDE   compile for SS != DS
# -w-stu turn off "undefined structure" warning
#XCCOMFLAGS = -d -Z -O -1- -2- -3- -WDE -w-stu
#XCCOMFLAGS = -d -WDE -w-stu

# Create a Copyrigth-notice
#LINKFLAGS += -N (c)\20by\20RABE-Soft\2010/99


