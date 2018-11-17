# $Id: local.mk,v 1.1 92/07/26 16:53:50 adam Exp $
.PATH.h		:
.PATH.h		: ../../utils $(INSTALL_DIR:H:H)/utils
.PATH.a		: ../../utils $(INSTALL_DIR:H:H)/utils
LIBS		= $(.TARGET:H)/libutils.a

#include <$(SYSMAKEFILE)>
