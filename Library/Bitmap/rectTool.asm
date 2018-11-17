COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		rectTool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	5/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the RectToolClass.

RCS STAMP:
$Id: rectTool.asm,v 1.1 97/04/04 17:43:18 newdeal Exp $

------------------------------------------------------------------------------@
BitmapClassStructures	segment resource
	RectToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource

if 0
RectInitialize	method	RectToolClass, MSG_META_INITIALIZE
	mov	di, offset RectToolClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	mov	ds:[di].TI_constrainStrategy, CS_DIAGONAL_CONSTRAINT
	ret
RectInitialize	endm
endif
	
BitmapToolCodeResource	ends			;end of tool code resource

