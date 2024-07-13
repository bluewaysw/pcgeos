#
# local.mk for Gadget library
# $Id: local.mk,v 1.1 98/03/11 04:34:12 martin Exp $
#

#include <$(SYSMAKEFILE)>

#GOCFLAGS += -Ha
#if DBCS
#else
ASMFLAGS += -DREAD_CHECK -DWRITE_CHECK -wjmp
#endif
#ASMFLAGS += -D__HIGHC__  
ASMFLAGS += -D__WATCOMC__  
