# $Id: local.mk,v 1.1 97/04/04 15:46:51 newdeal Exp $
GEODE		=	soli
.PATH.ui	: $(ROOT_DIR)/Appl/Art
UICFLAGS	+= -I$(ROOT_DIR)/Appl/Art

ASMFLAGS	+= -Wall

#include    <$(SYSMAKEFILE)>
