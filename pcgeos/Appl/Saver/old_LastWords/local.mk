#
# $Id: local.mk,v 1.1 97/04/04 16:48:34 newdeal Exp $
#
#if $(BRANCH) != "Release10X"
ASMFLAGS	+= -DSHOW_DATE_TIME=1
UICFLAGS	+= -DSHOW_DATE_TIME=1
#else
ASMFLAGS	+= -DSHOW_DATE_TIME=0
UICFLAGS	+= -DSHOW_DATE_TIME=0
#endif

#include	<$(SYSMAKEFILE)>
