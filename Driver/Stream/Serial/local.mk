#
#	Local makefile for: serial library
#
#	$Id: local.mk,v 1.1 97/04/18 11:46:01 newdeal Exp $
#
ASMFLAGS	+= -Wall -DGPC
LINKFLAGS	+= -Wunref

# for special WIN32DBCS version
ASMFLAGS        += $(.TARGET:MWIN32*:S/$(.TARGET)/-DWIN32 -DHARDWARE_TYPE=PC/)

#
# There are no strings to localize.
#
NO_LOC		=

#include <$(SYSMAKEFILE)>
