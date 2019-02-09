#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L wmg3http

# Force Borland C to create code that loads DS in function entry
#XCCOMFLAGS = -WDE -d

# -N:  Add stack probes to every routine (only for EC builds)
#ifndef NO_EC
#  XCCOMFLAGS += -N
#endif

# Set Copyright notice
XLINKFLAGS = -N by\20M.Groeber/Ken\20Yap

CCOMFLAGS += -DSSL_ENABLE
GOCFLAGS += -DSSL_ENABLE
LINKFLAGS += -DSSL_ENABLE

CCOMFLAGS += -DCOOKIE_ENABLE
GOCFLAGS += -DCOOKIE_ENABLE
LINKFLAGS += -DCOOKIE_ENABLE

#
# To show receive speed in status line
#
CCOMFLAGS += -DRECV_SPEED
GOCFLAGS += -DRECV_SPEED

#
# Tell what *_PROTO_{MAJOR,MINOR} constants to use for the driver protocol
#
# PROTOCONST      = URL_DRV
_PROTO = 7.0

