##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	Jeid
# MODULE:	JPerf
# FILE: 	local.mk
# AUTHOR: 	Chris Lee
#
#	$Id: local.mk,v 1.1 97/04/04 16:53:15 newdeal Exp $
#
###############################################################################

#
# Turn on warnings which are normally off.
#
LINKFLAGS	+= -Wunref
ASMFLAGS	+= -Wall


#
# XIP
# 
ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)
ASMFLAGS += -DREAD_CHECK -DWRITE_CHECK


#
# Include the system makefile
#
#include	<$(SYSMAKEFILE)>

