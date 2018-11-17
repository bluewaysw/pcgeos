# $Id: local.mk,v 1.1 97/04/18 11:57:59 newdeal Exp $

.PATH.asm .PATH.def : .. $(INSTALL_DIR:H)

PROTOCONST	= SWAP

#include    <$(SYSMAKEFILE)>
