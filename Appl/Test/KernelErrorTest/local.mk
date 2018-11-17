#
# Local Makefile for _______
#
#	$Id: local.mk,v 1.1 97/04/04 16:58:24 newdeal Exp $
#

GEODE           = kerr

NO_EC = 1
ASMFLAGS += -Wall
LINKFLAGS += -Wunref
#include <$(SYSMAKEFILE)>
