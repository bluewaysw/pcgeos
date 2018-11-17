# $Id: local.mk,v 1.1 97/04/10 11:54:52 newdeal Exp $

.PATH.asm .PATH.def : ../Common $(INSTALL_DIR:H)/Common

PROTOCONST	= FS

#include <$(SYSMAKEFILE)>
