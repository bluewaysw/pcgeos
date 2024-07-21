# local.mk 
# $Id: local.mk,v 1.3 98/10/15 13:36:15 martin Exp $
#

#include <$(SYSMAKEFILE)>

GOCFLAGS += -Ha -D__WATCOMC__
XCCOMFLAGS += -zc -D__WATCOMC__
ASMFLAGS += -D__WATCOMC__
