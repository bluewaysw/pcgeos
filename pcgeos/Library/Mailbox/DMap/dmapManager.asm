COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Driver map
FILE:		dmapManager.asm

AUTHOR:		Adam de Boor, Mar 30, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/30/94		Initial revision


DESCRIPTION:
	Driver map maintenance.
		

	$Id: dmapManager.asm,v 1.1 97/04/05 01:19:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def

include	Internal/geodeStr.def
include	Internal/fileStr.def	;For GeosFileHeader
include fileEnum.def

include	dmapConstant.def

include	dmapCode.asm
