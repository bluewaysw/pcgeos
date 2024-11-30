#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L vcimpex

# Tell the compiler we're doing a library (observe SS!=DS)
#XCCOMFLAGS = -WDE

# Set Copyright notice
XLINKFLAGS = -N Copyright\20Marcus\20Groeber

# compile user interface metafile into UI file
#vcimpex.ui: vcimpex\vcimpex.pvg
#	pmvg -u -c $(.ALLSRC) $(.TARGET)

