COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		deskdisplayDirTool.asm

AUTHOR:		Adam de Boor, Jan 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/30/92		Initial revision


DESCRIPTION:
	Implementation of DirToolClass
		

	$Id: cdeskdisplayDirTool.asm,v 1.1 97/04/04 15:02:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PseudoResident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DirToolPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	provide feedback during direct-manipulation

CALLED BY:	MSG_META_PTR

PASS:		usual object stuff
			ds:di = DirTool instance data
		es - segment of DirToolClass
		bp - UIFA flags
			UIFA_IN - set mouse pointer if in bounds of this object

RETURN:		ax = MouseReturnFlags

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/11/91		Initial version for 2.0 quick-transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DirToolPtr	method	DirToolClass, MSG_META_PTR
	add	di, offset DrT_flags		; ds:di = flags
	mov	bx, offset Callback_DirToolPtr	; bx = callback routine
	mov	ax, offset DirToolClass
	call	ToolPtrCommon
	ret
DirToolPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Callback_DirToolPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback for DirToolPtr that determines the quick
		transfer default for move/copy.

CALLED BY:	ToolPtrCommon

PASS:		*ds:si - DirTool object

RETURN:		ax = CQTF_MOVE, CQTF_COPY or CQTF_CLEAR

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/17/93	Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Callback_DirToolPtr	proc	near
	class	DirToolClass
	uses	bx, cx, dx, bp, si, di
	.enter

	call	CheckQuickTransferType		; check if CIF_FILES supported
	jnc	supported

	mov	ax, CQTF_CLEAR			; nope, just clear cursor
	jmp	done

supported:
	tst	bx				; copy if source is remote
	jnz	itsCopy

	mov	si, ds:[si]			; dereference object
	add	si, ds:[si].Gen_offset

	cmp	ds:[si].DrT_toolType, DIRTOOL_WASTEDIR
	je	itsMove				; equal flags are set for below

	mov	bx, ds:[si].DrT_diskHandle	; bx <- our disk handle
	test	bx, DISK_IS_STD_PATH_MASK	; is this a standard path?
	jz	compareThem			; compare if not a SP

	push	es
NOFXIP<	segmov	es, <segment idata>, bx		; es = dgroup		>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	bx, es:[geosDiskHandle]		; SP's are on the system disk
	pop	es

compareThem:	; bx is the dest diskhandle, ax is source diskhandle
	cmp	ax, bx
itsMove:
	mov	ax, CQTF_MOVE
	je	done				; "Move" if equal flags are set
itsCopy:
	mov	ax, CQTF_COPY			; else, do "Copy"
done:
	.leave
	ret
Callback_DirToolPtr	endp

DirToolLostGadgetExcl	method	DirToolClass, MSG_VIS_LOST_GADGET_EXCL
	add	di, offset DrT_flags
	call	ToolLostGadgetExclCommon
	ret
DirToolLostGadgetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DirToolEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle direct-manipulation

CALLED BY:	MSG_META_END_MOVE_COPY

PASS:		usual object stuff
		es - segment of DirToolClass
		bp - UIFA flags

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DirToolEndMoveCopy	method	DirToolClass, MSG_META_END_MOVE_COPY
	uses	ax, cx, dx, bp, si
	.enter
	call	DirToolLostGadgetExcl		; release mouse, if needed
	mov	di, MSG_DIRTOOL_QT_INTERNAL
	call	ToolQuickTransfer
	.leave
	mov	di, offset DirToolClass
	call	ObjCallSuperNoLock
	ret
DirToolEndMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DirToolEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle direct-manipulation for ZMGR

CALLED BY:	MSG_META_END_SELECT

PASS:		usual object stuff
		es - segment of DirToolClass
		bp - UIFA flags

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PEN_BASED
DirToolEndSelect	method	DirToolClass, MSG_META_END_SELECT
	uses	ax, cx, dx, bp, si
	.enter
	push	es
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_MOVECOPY
	pop	es
	jz	done
	call	DirToolLostGadgetExcl		; release mouse, if needed
	mov	di, MSG_DIRTOOL_QT_INTERNAL
	call	ToolQuickTransfer
done:
	.leave
	mov	di, offset DirToolClass
	call	ObjCallSuperNoLock
	ret
DirToolEndSelect	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DirToolGetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get tool type for this tool

CALLED BY:	MSG_DIR_TOOL_GET_TYPE

PASS:		usual object stuff

RETURN:		dl - tool type

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DirToolGetType	method	dynamic DirToolClass, MSG_DIR_TOOL_GET_TYPE
	mov	dl, ds:[di].DrT_toolType	; get drive number
	ret
DirToolGetType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DirToolSetDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set disk handle for this dir tool

CALLED BY:	MSG_DIR_TOOL_SET_DISK_HANDLE

PASS:		usual object stuff
		bp - disk handle

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DirToolSetDiskHandle	method	dynamic DirToolClass,
				MSG_DIR_TOOL_SET_DISK_HANDLE
	mov	ds:[di].DrT_diskHandle, bp	; save disk handle
	ret
DirToolSetDiskHandle	endm

PseudoResident	ends
