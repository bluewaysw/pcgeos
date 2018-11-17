#
#	Local makefile for: mbounce
#
#	$Id: local.mk,v 1.1 97/04/04 16:36:35 newdeal Exp $
#
# Pass flag for (somewhat) unsafe resource fixups for multi-launchability
#
LINKFLAGS	+= -r

#include <$(SYSMAKEFILE)>
