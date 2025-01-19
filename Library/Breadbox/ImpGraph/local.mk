#
# There are no strings to localize.
#
NO_LOC		=

#include <$(SYSMAKEFILE)>

# The manual says I should do this... ;-)
XGOCFLAGS = -L impgraph

# Force Borland C to create code that loads DS in function entry
#XCCOMFLAGS = -WDE

# Set Copyright notice
#XLINKFLAGS = -N \(C\)97\20Breadbox\20Computer\20Company

CCOMFLAGS += -I../ijgjpeg/include

#
# Tell what *_PROTO_{MAJOR,MINOR} constants to use for the driver protocol
#
# PROTOCONST      = MIME_DRV
_PROTO = 4.1

# for special FJPEGDBCS version
ASMFLAGS        += $(.TARGET:MFJPEGDBCS*:S/$(.TARGET)/-DPRODUCT_FJPEG -DHARDWARE_TYPE=PC/)
GOCFLAGS        += $(.TARGET:MFJPEGDBCS*:S/$(.TARGET)/-DPRODUCT_FJPEG -DHARDWARE_TYPE=PC/)
LINKFLAGS        += $(.TARGET:MFJPEGDBCS*:S/$(.TARGET)/-DPRODUCT_FJPEG -DHARDWARE_TYPE=PC/)

# NOTE NOTE NOTE:
# when calling mkmf / pmake depend and compiling afterwards,
# you might see an error like:
# "pmake: Can't figure out how to make impfjpeg.cpp. Stop"
#
# You have to manually edit dependencies.mk and remove:
#
# impfjpeg.obj \
# impfjpeg.eobj: impfjpeg.cpp
#
# ... this is a bug. (meyerk 01/2025)
