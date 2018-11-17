# $Id: local.mk,v 1.1 97/04/04 16:28:04 newdeal Exp $

.PATH.uih .PATH.asm .PATH.def : ../Common $(INSTALL_DIR:H)/Common
UICFLAGS	+= -I../Common -I$(INSTALL_DIR:H)/Common
ASMFLAGS	+= -Wall

#include    <$(SYSMAKEFILE)>
