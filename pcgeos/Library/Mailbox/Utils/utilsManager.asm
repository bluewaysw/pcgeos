COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Utility Routines
FILE:		utilsManager.asm

AUTHOR:		Adam de Boor, May  9, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 9/94		Initial revision


DESCRIPTION:
	General utility routines
		

	$Id: utilsManager.asm,v 1.1 97/04/05 01:19:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	mailboxGeode.def

UseLib	Objects/vTextC.def
include	timedate.def
include	Internal/harrint.def

UseDriver Internal/mbDataDr.def

include utilsGlobal.asm
include	utilsResident.asm
include utilsCode.asm
include utilsEC.asm
include utilsC.asm

