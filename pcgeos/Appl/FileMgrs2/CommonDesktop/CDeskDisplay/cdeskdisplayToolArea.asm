COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Main
FILE:		deskdisplayToolArea.asm

ROUTINES:
	ToolAreaMoveDriveTools	- moves the drive buttons to another object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/10/92		Initial version

DESCRIPTION:
	This file contains message handlers for the ToolArea class

	$Id: cdeskdisplayToolArea.asm,v 1.1 97/04/04 15:02:59 newdeal Exp $

------------------------------------------------------------------------------@

ToolCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolAreaMoveDriveTools
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	moves the drive buttons to another object.

CALLED BY:	MSG_TA_MOVE_DRIVE_TOOLS

PASS:		ds:si - standard object stuff
		cx:dx - destination object for drive tools

RETURN:		nothing

DESTROYED:	???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolAreaMoveDriveTools	method	ToolAreaClass, MSG_TA_MOVE_DRIVE_TOOLS
	.enter
	;
	; cx:dx already set to destination object
	;
	clr	bx
	push	bx			; start at Nth child
	push	bx			; n = 0 means first child
	mov	bx, offset GI_link	; Pass the offset to LinkPart
	push	bx
	mov	bx, SEGMENT_CS		; bx <- vseg if XIP'ed
	push	bx			; push segment
	mov	bx, offset ToolAreaMoveDriveToolsCallBack
	push	bx
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren

	.leave
	ret
ToolAreaMoveDriveTools	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolAreaMoveDriveToolsCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	determines if passed object is a drive tool and copies if so

CALLED BY:	ToolAreaMoveDriveTools

PASS:		*ds:si	- child
		*es:di	- composite
		cx:dx	- destination object

RETURN:		cx:dx	- destination object

DESTROYED:	bx, si, di, ds, es, ax, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolAreaMoveDriveToolsCallBack	proc	far
	uses	cx, dx
	.enter

	mov	bx, es:[LMBH_handle]
	mov	bp, di					; src object in bx:bp

	mov	ax, segment DriveToolClass
	mov	es, ax
	mov	di, offset DriveToolClass
	call	ObjIsObjectInClass			; is this a DriveTool
	jnc	exit

	push	cx, dx					; save dest object
	push	bp					; save src handle

	mov	ax, MSG_GEN_SET_NOT_USABLE		; set child unusable
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_REMOVE_CHILD
	mov	cx, ds:[LMBH_handle]
	mov	dx, si					; cx:dx is child
	pop	si					; bx:si is parent (src)
	clr	bp
	call	ObjMessageCall

	pop	bx, si					; restore dest object
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST
	call	ObjMessageCall
	
	mov	ax, MSG_GEN_SET_USABLE
	mov	bx, cx					; set child usable
	mov	si, dx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessageCall
exit:
	.leave
	ret
ToolAreaMoveDriveToolsCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolAreaSetDriveLocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the instance data according to what is passed in

CALLED BY:	MSG_TA_SET_DRIVE_LOCATION

PASS:		cl - DriveButtonLocations
		standard object stuff

RETURN:		nothing

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolAreaSetDriveLocation	method ToolAreaClass, MSG_TA_SET_DRIVE_LOCATION
	.enter

	mov	ds:[di].TA_driveButtonLocation, cl

	.leave
	ret
ToolAreaSetDriveLocation	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolAreaGetDriveLocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the location of the drive buttons in cl

CALLED BY:	MSG_TA_GET_DRIVE_LOCATION

PASS:		standard object stuff

RETURN:		cl - DriveButtonLocations

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolAreaGetDriveLocation	method ToolAreaClass, MSG_TA_GET_DRIVE_LOCATION
	.enter

	mov	cl, ds:[di].TA_driveButtonLocation

	.leave
	ret
ToolAreaGetDriveLocation	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolAreaFindDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find drive given drive number and starting location

CALLED BY:	MSG_TA_FIND_DRIVE

PASS:		*ds:si	= ToolAreaClass object
		ds:di	= ToolAreaClass instance data
		es 	= segment of ToolAreaClass
		ax	= MSG_TA_FIND_DRIVE

		dx	= drive number
		cx	= starting location

RETURN:		^lcx:dx	= drive (or NULL if not found)

ALLOWED TO DESTROY:	
		ax, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/18/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolAreaFindDrive	method	dynamic	ToolAreaClass, MSG_TA_FIND_DRIVE
driveNumber	local	word	push	dx
toolArea	local	word	push	si
location	local	word	push	cx
	.enter
checkDrive:
	mov	cx, location
	mov	si, toolArea
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	push	bp
	call	ObjCallInstanceNoLock		; ^lcx:dx = child
	pop	bp
	jc	done				; not found, cx = 0
	movdw	bxsi, cxdx			; ^lbx:si = child
	mov	cx, segment DriveToolClass
	mov	dx, offset DriveToolClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	push	bp
	call	ObjMessageCallFixup
	pop	bp
	jnc	nextDrive
	mov	ax, MSG_DRIVE_TOOL_GET_DRIVE
	push	bp
	call	ObjMessageCallFixup		; bp = drive #
	mov	ax, bp				; ax = drive #
	pop	bp
	cmp	ax, driveNumber			; is this the one?
	movdw	cxdx, bxsi			; assume so
	je	done				; yes, done
nextDrive:
	inc	location
	jmp	short checkDrive

done:
	.leave
	ret
ToolAreaFindDrive	endm


ToolCode	ends




