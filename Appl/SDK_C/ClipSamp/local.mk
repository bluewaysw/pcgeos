#
# Local Makefile for CClipSamp
#
#	$Id: local.mk,v 1.1 97/04/04 16:36:08 newdeal Exp $
#


#
# Turn relocations to unshared resources from shared ones into virtual-segment
# relocations, allowing us to use GeodeGetOptrNS...
#
LINKFLAGS       += -r

#include <$(SYSMAKEFILE)>
