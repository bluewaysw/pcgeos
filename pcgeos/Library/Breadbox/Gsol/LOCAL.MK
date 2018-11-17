#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L gsol

# Force Borland C to create code that loads DS in function entry
XCCOMFLAGS = -WDE

# Set Copyright notice
XLINKFLAGS = -N Copyright\20Marcus\20Groeber

