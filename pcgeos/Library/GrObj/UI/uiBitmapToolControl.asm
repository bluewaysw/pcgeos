COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiBitmapToolControl.asm

AUTHOR:		Jon Witort

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjBitmapToolControlClass

	$Id: uiBitmapToolControl.asm,v 1.1 97/04/04 18:05:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBitmapToolControlSetTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBitmapToolControl method for MSG_VBTC_SET_TOOL

Called by:	

Pass:		*ds:si = VisBitmapToolControl object
		ds:di = VisBitmapToolControl instance

		cx = identifier

Return:		nothing

Destroyed:	bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBitmapToolControlSetTool	method	GrObjBitmapToolControlClass,
				MSG_VBTC_SET_TOOL
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_VBTC_GET_TOOL_CLASS
	call	ObjCallInstanceNoLock
	jnc	done

	;
	;  Allocate our block of "extra" data for the floater to read
	;
	push	cx					;save class seg
	mov	ax, size BitmapGuardianSpecificInitializationData
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8
	call	MemAlloc
	pop	cx					;cx <- class seg
	jc	done
	mov	es, ax
	mov	ax, 1
	call	MemInitRefCount
	movdw	es:[BGSID_toolClass], cxdx
	call	GrObjBitmapGetActiveStatusForBitmapToolClass
	mov	es:[BGSID_activeStatus], al
	call	MemUnlock
	mov	bp, bx					;bp <- block

	mov	cx, segment BitmapGuardianClass
	mov	dx, offset BitmapGuardianClass
	mov	ax, MSG_GH_SET_CURRENT_TOOL_WITH_DATA_BLOCK
	mov	bx, segment GrObjHeadClass
	mov	di, offset GrObjHeadClass
	call	GenControlOutputActionRegs
done:
	.leave
	ret
GrObjBitmapToolControlSetTool	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBitmapGetActiveStatusForBitmapToolClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use look up table to get appropriate flags for
		BitmapToolClass

CALLED BY:	INTERNAL
		GrObjBitmapToolControlSetTool

PASS:		
		^lcx:dx - BitmapToolClass

RETURN:		
		al - GrObjVisGuardianFlags
			only GOVGF_CAN_EDIT_EXISTING_OBJECTS and
			GOVGF_CREATE_MODE matter

DESTROYED:	
		ah

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBitmapGetActiveStatusForBitmapToolClass		proc	near
	uses	di,cx,es
	.enter

 	segmov	es,cs,ax			;class offset table segment
	mov	di,offset BitmapToolClassOffsetTable
	mov	ax,dx				;class offset to find
	mov	cx,length BitmapToolClassOffsetTable
	repne	scasw
	jnz	notHome
	sub	di,offset BitmapToolClassOffsetTable + 2
	shr	di,1				;other table is byte sized
	add	di,offset BitmapToolClassActiveStatusTable	
	mov	al,{byte}es:[di]

done:
	.leave
	ret

notHome:
	;    If we don't have this class listed then just assume it
	;    can only be used to edit existing objects
	;

	mov	al,mask GOVGF_CAN_EDIT_EXISTING_OBJECTS
	jmp	done

GrObjBitmapGetActiveStatusForBitmapToolClass		endp


BitmapToolClassOffsetTable	word	\
	0,
	offset SelectionToolClass,
	offset LineToolClass,
	offset RectToolClass,
	offset EllipseToolClass,
	offset PencilToolClass,
	offset FatbitsToolClass,
	offset EraserToolClass,
	offset FloodFillToolClass

BitmapToolClassActiveStatusTable	byte \
	GOVGCM_GUARDIAN_CREATE shl offset GOVGF_CREATE_MODE,;BitmapGuardianClass
	mask GOVGF_CAN_EDIT_EXISTING_OBJECTS,		;SelectionToolClass
	mask GOVGF_CAN_EDIT_EXISTING_OBJECTS or \
	GOVGCM_VIS_WARD_CREATE shl offset GOVGF_CREATE_MODE, ;LineToolClass
	mask GOVGF_CAN_EDIT_EXISTING_OBJECTS or \
	GOVGCM_VIS_WARD_CREATE shl offset GOVGF_CREATE_MODE, ;RectToolClass
	mask GOVGF_CAN_EDIT_EXISTING_OBJECTS or \
	GOVGCM_VIS_WARD_CREATE shl offset GOVGF_CREATE_MODE, ;EllipseToolClass
	mask GOVGF_CAN_EDIT_EXISTING_OBJECTS or \
	GOVGCM_VIS_WARD_CREATE shl offset GOVGF_CREATE_MODE, ;PencilToolClass
	mask GOVGF_CAN_EDIT_EXISTING_OBJECTS,		;FatbitsToolClass	
	mask GOVGF_CAN_EDIT_EXISTING_OBJECTS,		;EraserToolClass	
	mask GOVGF_CAN_EDIT_EXISTING_OBJECTS		;FloodFillToolClass	

.assert (length BitmapToolClassOffsetTable eq length BitmapToolClassActiveStatusTable)

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjBitmapToolControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjToolControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjToolControlClass
	ax - MSG_GEN_CONTROL_UPDATE_UI

	ss:bp - GenControlUpdateUIParams

RETURN: nothing

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 feb 1992	Initial version
------------------------------------------------------------------------------@
GrObjBitmapToolControlUpdateUI	method GrObjBitmapToolControlClass,
				MSG_GEN_CONTROL_UPDATE_UI
	uses	ax, cx, dx, bp
	.enter

	mov	di, offset GrObjBitmapToolControlClass
	call	ObjCallSuperNoLock

	mov	bx, ss:[bp].GCUUIP_dataBlock
	tst	bx
	jz	done
	call	MemLock
	mov	es, ax
	movdw	dxax, es:[VBNCT_toolClass]
	call	MemUnlock
	cmpdw	dxax, -1
	je	done

	;
	;	Send a null GrObj message just for kicks
	;
	mov	bx, size GrObjNotifyCurrentTool
	call	GrObjGlobalAllocNotifyBlock

	call	MemLock
	mov	es, ax
	movdw	es:[GONCT_toolClass], -1
	call	MemUnlock

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_CURRENT_TOOL_CHANGE
	mov	dx, GWNT_GROBJ_CURRENT_TOOL_CHANGE
	call	GrObjGlobalUpdateControllerLow

done:
	.leave
	ret
GrObjBitmapToolControlUpdateUI	endm
GrObjUIControllerCode	ends
