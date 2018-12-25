#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L extgraph

# Force Borland C to create code that loads DS in function entry
#XCCOMFLAGS = -WDE

# Set Copyright notice
XLINKFLAGS = -N \(C\)98\20Breadbox\20Computer\20Company



