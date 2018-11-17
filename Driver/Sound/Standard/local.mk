#############################################################################
#	
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#	
#	PROJECT:	PC/GEOS
#	MODULE:		Sound System
#	FILE:		standardConstant.def
#
#	AUTHOR:		Todd Stumpf, Jul 15, 1994
#
#	REVISION HISTORY:
#		Name	Date		Description
#		----	----		-----------
#		TS	7/15/94   	Initial revision
#
#
#	DESCRIPTION:
#		Standard Sound Driver special Makefile definitions	
#		
#	$Id: local.mk,v 1.1 97/04/18 11:57:38 newdeal Exp $
#	
#############################################################################

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

GEODE		= standard

#include	"$(SYSMAKEFILE)"
