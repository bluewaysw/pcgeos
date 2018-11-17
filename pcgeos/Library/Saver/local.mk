#
#	Local makefile for: Saver library
#
#	$Id: local.mk,v 1.1 97/04/07 10:44:31 newdeal Exp $
#
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#
# GPC additions
#
ASMFLAGS	+= -DGPC
UICFLAGS	+= -DGPC


#include <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify the conditional
# compilation directives on the saverand line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP
