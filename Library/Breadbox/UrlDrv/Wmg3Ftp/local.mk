#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L wmg3ftp

# Force Borland C to create code that loads DS in function entry
#XCCOMFLAGS = -WDE

# XCCOMFLAGS += -DLOGFILE

# Set Copyright notice
XLINKFLAGS = -N by\20Breadbox\20Computer

#
# Tell what *_PROTO_{MAJOR,MINOR} constants to use for the driver protocol
#
# PROTOCONST      = URL_DRV
_PROTO = 7.0

