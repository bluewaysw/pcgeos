#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L wmg3ext

# Force Borland C to create code that loads DS in function entry
#XCCOMFLAGS = -WDE

# XCCOMFLAGS += -DLOGFILE

#
# Tell what *_PROTO_{MAJOR,MINOR} constants to use for the driver protocol
#
# PROTOCONST      = URL_DRV
_PROTO = 7.0


