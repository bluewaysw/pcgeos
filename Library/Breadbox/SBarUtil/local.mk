#include <$(SYSMAKEFILE)>

XGOCFLAGS = -L sbarutil

# Force Borland C to create code that loads DS in function entry
XCCOMFLAGS = -WDE

