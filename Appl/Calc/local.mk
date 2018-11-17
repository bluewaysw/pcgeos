# $Id: local.mk,v 1.1 97/04/04 14:46:43 newdeal Exp $
.PATH.ui	: $(ROOT_DIR)/Appl/Art
UICFLAGS	+= -I$(ROOT_DIR)/Appl/Art

ASMFLAGS	+= -Wall

GCM		= oui

#include    <$(SYSMAKEFILE)>
