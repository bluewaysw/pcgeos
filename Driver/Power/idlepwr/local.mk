#
#	$Id: local.mk,v 1.1 97/04/18 11:48:17 newdeal Exp $
#
#GEODE 	= idlepwr
#
#ASMFLAGS	+= -Wall
#LINKFLAGS	+= -Wunref


.PATH.asm .PATH.def : ../Common $(INSTALL_DIR:H)/Common

#PROTOCONST	= POWER
_PROTO		= 3.0

#include <$(SYSMAKEFILE)>
