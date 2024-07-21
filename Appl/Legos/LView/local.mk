#
# local.mk for LView application
# $Id: local.mk,v 1.3 98/10/16 00:12:40 martin Exp $
#

#include <$(SYSMAKEFILE)>

ASMFLAGS += -DREAD_CHECK -DWRITE_CHECK -wjmp
#ASMFLAGS += -D__HIGHC__  
#ASMFLAGS += -D__BORLANDC__
ASMFLAGS += -D__WATCOMC__
GOCFLAGS += -Ha
