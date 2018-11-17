# $Id: local.mk,v 1.1 97/04/18 11:46:39 newdeal Exp $

.PATH.asm .PATH.def : ../Common $(INSTALL_DIR:H)/Common \
                      ../../../PCMCIA/Common \
                      $(INSTALL_DIR:H)/../../PCMCIA/Common

PROTOCONST	= PCMCIA

#include    <$(SYSMAKEFILE)>
