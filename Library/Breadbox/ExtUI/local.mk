#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L extui

# Force Borland C to create code that loads DS in function entry
#XCCOMFLAGS = -WDE

# Set Copyright notice
XLINKFLAGS = -N \(C\)97\20Breadbox\20Computer\20Company

