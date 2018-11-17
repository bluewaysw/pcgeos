COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	GEOS 2.1
MODULE:		
FILE:		pgfsManager.asm

AUTHOR:		Adam de Boor, Sep 29, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/29/93		Initial revision


DESCRIPTION:
	The file what gets assembled
		

	$Id: pgfsManager.asm,v 1.1 97/04/18 11:46:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_PCMCIA equ TRUE

include	gfsGeode.def


DefDriver Internal/pcmciaDr.def
UseDriver Internal/fontDr.def
UseLib	pcmcia.def

UseDriver Internal/powerDr.def

include gfsConstant.def
include gfsVariable.def
include	pgfsConstant.def
include	pgfsVariable.def

; PCMCIA driver code
include	pgfsCardServices.asm
include	pgfsEntry.asm
include	pgfsInsert.asm
include	pgfsRemove.asm
include	pgfsUtils.asm
include pgfsWindow.asm

; GFS driver code

include	gfsDisk.asm
include	gfsEntry.asm
include gfsEnum.asm
include gfsExtAttrs.asm
include gfsInitExit.asm
include gfsIO.asm
include gfsMapPath.asm
include gfsPath.asm
include gfsUtils.asm

include pgfsDevSpec.asm


