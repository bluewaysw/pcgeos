# $Id: local.mk,v 1.1 97/04/05 01:29:24 newdeal Exp $

PROTOCONST	= PREF_MODULE

#
# Different App icon
#
ASMFLAGS	+= -DGPC_VERSION
UICFLAGS	+= -DGPC_VERSION
LINKFLAGS	+= -DGPC_VERSION

#include <$(SYSMAKEFILE)>
