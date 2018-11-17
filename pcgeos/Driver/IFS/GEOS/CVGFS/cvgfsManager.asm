COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File System Drivers
FILE:		vgfsManager.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision
	cassie	6/29/93		adapted for bullet
	todd	9/12/94		Made generic for all VG-230 platforms
	Joon	1/19/96		Adapted for compressed GFS

DESCRIPTION:
	Guess what?
		

	$Id: cvgfsManager.asm,v 1.1 97/04/18 11:46:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_VGFS	equ	TRUE

include	gfsGeode.def
include	gfsConstant.def
include cvgfsConstant.def

include	gfsVariable.def
include cvgfsVariable.def
include cvgfsMacro.def

include	gfsDisk.asm
include	gfsEntry.asm
include gfsEnum.asm
include gfsExtAttrs.asm
include gfsInitExit.asm
include gfsIO.asm
include gfsMapPath.asm
include gfsPath.asm
include gfsUtils.asm

include cvgfsDevSpec.asm
