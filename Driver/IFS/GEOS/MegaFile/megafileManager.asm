COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		fileManager.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision


DESCRIPTION:
	Guess what?
		

	$Id: megafileManager.asm,v 1.1 97/04/18 11:46:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_FILE	equ	TRUE

include	gfsGeode.def
include	gfsConstant.def
include Internal/mfsDr.def
include megafileConstant.def

include	gfsVariable.def
include megafileVariable.def

include	gfsDisk.asm
include	gfsEntry.asm
include gfsEnum.asm
include gfsExtAttrs.asm
include gfsInitExit.asm
include gfsIO.asm
include gfsMapPath.asm
include gfsPath.asm
include gfsUtils.asm

include megafileDevSpec.asm
