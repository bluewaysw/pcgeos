COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiControl.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92	Initial version.

DESCRIPTION:
	Common procedures for UI controllers

	$Id: uiControl.asm,v 1.1 97/04/04 18:04:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDupInfoCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the controller's DupInfo table

CALLED BY:

PASS:		cx:dx - location to copy table to
		ds:si - source of table

RETURN:		nothing 

DESTROYED:	cx,ds,si,es,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyDupInfoCommon	proc far
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep	movsb
	ret
CopyDupInfoCommon	endp

