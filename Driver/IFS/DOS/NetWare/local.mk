##############################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Netware IFS Driver
# FILE:		local.mk
#
# REVISION HISTORY:
#	SH	4/94		Initial version
#
# DESCRIPTION:	
#
# RCS STAMP:
#	$Id: local.mk,v 1.1 97/04/10 11:55:17 newdeal Exp $
#
##############################################################################
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#include    <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify the conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP



