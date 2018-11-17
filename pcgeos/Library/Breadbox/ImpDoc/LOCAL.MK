#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L impdoc

# Force Borland C to create code that loads DS in function entry
XCCOMFLAGS = -WDE

#
# Tell what *_PROTO_{MAJOR,MINOR} constants to use for the driver protocol
#
# PROTOCONST      = MIME_DRV
_PROTO = 4.1

