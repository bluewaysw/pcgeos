#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L cookies

# Force Borland C to create code that loads DS in function entry
#XCCOMFLAGS = -WDE -d
XCCOMFLAGS = -zu -zc 

CCOMFLAGS += -DSSL_ENABLE
GOCFLAGS += -DSSL_ENABLE
LINKFLAGS += -DSSL_ENABLE

CCOMFLAGS += -DCOOKIE_ENABLE
GOCFLAGS += -DCOOKIE_ENABLE
LINKFLAGS += -DCOOKIE_ENABLE


