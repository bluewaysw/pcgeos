# the following must be included and be before the include of the SYSMAKEFILE
#DIS386 ?= 1

#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L htmlpars

# -WDE: Make sure that SS!=DS situation in library is observed
# -d:   Merge duplicate strings
XCCOMFLAGS = -d -Z -Os -O -WDE -3

# Set Copyright notice
XLINKFLAGS = -N by\20Marcus\20Groeber

