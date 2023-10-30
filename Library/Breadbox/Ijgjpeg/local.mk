#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L ijgjpeg

# -d   reduces the size of the dgroup by merging duplicate strings.
# -w-  turn off some warnings
#XCCOMFLAGS = -d -Z -Os -O -w-stu -w-par -WDE
XCCOMFLAGS = -zu 
# -dc (Borland) is not set to push literals into code segment, not
# sure why, but trying -zc is not working properly

#XLINKFLAGS = -N \(C\)98\20Breadbox\20Computer\20Company
