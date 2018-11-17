#
# Local Makefile for AnsiC
#
#	$Id: local.mk,v 1.1 97/04/04 17:42:26 newdeal Exp $
#

ASMFLAGS += -Wall
LINKFLAGS += -Wunref

#CCOM_MODEL	= -Mb
CCOM_MODEL	= -ml

ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#include <$(SYSMAKEFILE)>

#
# For DBCS version, make sure we have DBCS-specific LDF
#
LINKFLAGS	+= $(.TARGET:X\\[DBCS\\]/*:S|DBCS|-l|g)
