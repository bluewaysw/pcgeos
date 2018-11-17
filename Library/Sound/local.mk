#
#	Local makefile for: text library
#
#	$Id: local.mk,v 1.1 97/04/07 10:46:21 newdeal Exp $
#
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#include <$(SYSMAKEFILE)>


#
# If the target is "XIP" then specify the conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g) -DGPC_VERSION
UICFLAGS	+= -DGPC_VERSION
LINKFLAGS	+= -DGPC_VERSION

#full		:: XIP
