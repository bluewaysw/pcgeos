#
#	Local makefile for: benoit
#
#	$Id: local.mk,v 1.1 97/04/04 16:39:41 newdeal Exp $
#
# Pass flag to allow resource fixups, since we're multi-launchable.
#
LINKFLAGS	+= -r

#include <$(SYSMAKEFILE)>
