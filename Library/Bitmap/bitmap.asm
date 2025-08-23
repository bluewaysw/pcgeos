COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991, 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap
FILE:		bitmap.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the VisBitmapClass

RCS STAMP:

	$Id: bitmap.asm,v 1.1 97/04/04 17:43:46 newdeal Exp $
------------------------------------------------------------------------------@
BitmapClassStructures	segment resource

	VisBitmapClass

BitmapClassStructures	ends


BITMAP_USES_VM_BASED_GSTRINGS	= 1

BitmapBasicCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapRecreateCachedGStates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy and recreate any cached gstates

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of VisBitmapClass

RETURN:		nothing
	
DESTROYED:	ax

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapRecreateCachedGStates	method dynamic VisBitmapClass, 
				MSG_VIS_RECREATE_CACHED_GSTATES
	.enter

	mov	ax, MSG_VIS_BITMAP_DESTROY_SCREEN_GSTATE
	call	ObjCallInstanceNoLock

	.leave
	ret
VisBitmapRecreateCachedGStates		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_DRAW handler for VisBitmapClass

		Sets proper clip region, area color, then draws the bitmap,
		its text object, etc.

CALLED BY:	

PASS:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance
		bp = gstate to draw through
		cl - DrawFlags

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	1/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapDraw	method dynamic	VisBitmapClass, MSG_VIS_DRAW

	uses	cx, dx, bp
	.enter

	push	cx					;save draw flags

	test	ds:[di].VBI_undoFlags, mask VBUF_ANTS_DRAWN
	jz	afterAnts

	;
	;  We only want the ants erased from the bitmap, not from
	;  the screen, so temporarily clear out the screen gstate
	;
	clr	cx
	xchg	cx, ds:[di].VBI_screenGState
	push	cx

	;
	;	Draw the ants again to erase them
	;
	mov	ax, MSG_VIS_BITMAP_DRAW_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	pop	ds:[di].VBI_screenGState

afterAnts:

	;
	;	Save the gstate so we can dinkle with impunity
	;

	mov	di, bp
	call	GrSaveState

	;
	;	Here we clip the gstate's window so that only the bitmap
	;	will be drawn (if we didn't do this, then stuff in any gtring
	;	that went outside the bitmap's vis bounds would be drawn,
	;	which would be bad).
	;
	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset
	mov	ax, ds:[bp].VI_bounds.R_left
	mov	bx, ds:[bp].VI_bounds.R_top

	mov	cx, ds:[bp].VI_bounds.R_right
	mov	dx, ds:[bp].VI_bounds.R_bottom

	push	si					;save VisBitmap chunk
	mov	si, PCT_INTERSECTION
	call	GrSetClipRect

	mov_tr	cx, ax					;cx <- left
	sub	cx, ds:[bp].VBI_bitmapToVisHOffset
	mov	dx, bx					;dx <- top
	sub	dx, ds:[bp].VBI_bitmapToVisVOffset

	;
	;	Now we draw the actual bitmap to the gstate
	;
	mov	bp, di					;bp <- gstate
	pop	si					;*ds:si <- VisBitmap
	mov	ax, MSG_VIS_BITMAP_DRAW_BITMAP_TO_GSTATE
	call	ObjCallInstanceNoLock

	pop	cx					;cl <- DrawFlags
	test	cl, mask DF_EXPOSED
	jz	restorePassed

	;
	;    Make sure any drag tools clean up any feedback
	;

	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset
	mov	bx, ds:[bp].VBI_tool.handle
	tst	bx
	jz	checkAnts

	BitSet	ds:[bp].VBI_undoFlags, VBUF_EXPOSED_HAPPENING

	xchg	di, ds:[bp].VBI_screenGState
	push	di

	push	si
	mov	si, ds:[bp].VBI_tool.chunk
	mov	ax, MSG_TOOL_CLEANUP_AFTER_EXPOSE
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si

	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset
	pop	di
	xchg	di, ds:[bp].VBI_screenGState
	BitClr	ds:[bp].VBI_undoFlags, VBUF_EXPOSED_HAPPENING

checkAnts:
	test	ds:[bp].VBI_undoFlags, mask VBUF_ANTS_DRAWN
	jz	restorePassed

	;
	;  Get our screen gstate and make it the update gstate
	;

	mov	ax, MSG_VIS_BITMAP_GET_SCREEN_GSTATE
	call	ObjCallInstanceNoLock
	tst	bp
	jz	restorePassed

	push	di					;save passed gstate

	mov	di, bp					;di <- screen gstate
	call	GrSetUpdateGState			;screen gstate = update

	mov	ax, MSG_VIS_BITMAP_DRAW_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	tst	di
	jz	afterUpdate
	call	GrSetUpdateGState			;passed gstate = update
afterUpdate:
	pop	di					;di <- passed GState


restorePassed:
	call	GrRestoreState

	.leave
	ret
VisBitmapDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapDrawBitmapToGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_DRAW handler for VisBitmapClass

		Simply draws the bitmap to the passed gstate.

CALLED BY:	

PASS:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance
		bp = gstate to draw through
;		cx,dx - coordinates to draw the bitmap at

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	1/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapDrawBitmapToGState	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_DRAW_BITMAP_TO_GSTATE
	.enter

	push	cx, dx

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock

	mov	bx, cx
	mov_tr	ax, dx
	pop	cx, dx
	tst	ax
	jz	done
	mov	di, bp
	call	DrawBitmapToGState
done:
	.leave
	ret
VisBitmapDrawBitmapToGState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapDrawBackupBitmapToGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_DRAW handler for VisBitmapClass

		Simply draws the bitmap to the passed gstate.

CALLED BY:	

PASS:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance
		bp = gstate to draw through
;		cx,dx - coordinates to draw the bitmap at

RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	1/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapDrawBackupBitmapToGState	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_DRAW_BACKUP_BITMAP_TO_GSTATE
	.enter

if 1
	push	cx, dx

	mov	ax, MSG_VIS_BITMAP_GET_BACKUP_BITMAP
	call	ObjCallInstanceNoLock

	mov	bx, cx
	mov_tr	ax, dx
	pop	cx, dx
	mov	di, bp
	tst	ax
	jz	done
	call	DrawBitmapToGState
else
	push	cx, dx

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock

	mov	bx, cx
	mov_tr	ax, dx
	pop	cx, dx
	mov	di, bp
	tst	ax
	jz	done

	xchg	ax, cx
	xchg	bx, dx
	call	GrFillHugeBitmap
	xchg	ax, cx
	xchg	bx, dx
endif
done:
	.leave
	ret
VisBitmapDrawBackupBitmapToGState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DrawBitmapToGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a bitmap into the passed gstate

CALLED BY:	VisBitmapDraw

PASS:		di = gstate to draw to
		bx = vm file handle of bitmap
		ax = vm block handle of bitmap
		cx,dx - coordinates to draw the bitmap at

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawBitmapToGState	proc	far
	.enter

	xchg	ax, cx
	xchg	bx, dx
	call	GrDrawHugeBitmap
	xchg	ax, cx
	xchg	bx, dx

	.leave
	ret
DrawBitmapToGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetMainBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_GET_BITMAP handler for VisBitmapClass
		Returns the vm file and block handles to the main bitmap

CALLED BY:	

PASS:		ds:di = VisBitmap instance

RETURN:		cx = vm file handle
		dx = vm block handle

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	1/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetMainBitmap	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_GET_MAIN_BITMAP
	.enter

	mov	dx, ds:[di].VBI_mainKit.VBK_bitmap
	mov	ax, MSG_VIS_BITMAP_GET_VM_FILE
	call	ObjCallInstanceNoLock
	mov_tr	cx, ax

	.leave
	ret
VisBitmapGetMainBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetTransferBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_GET_TRANSFER_BITMAP handler for VisBitmapClass
		Returns the vm file and block handles to the transfer bitmap

CALLED BY:	

PASS:		ds:di = VisBitmap instance

RETURN:		cx = vm file handle
		dx = vm block handle

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	1/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetTransferBitmap	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_GET_TRANSFER_BITMAP
	.enter

	mov	bp, ds:[di].VBI_transferBitmap
	mov	cx, ds:[di].VBI_transferBitmapPos.P_x
	mov	dx, ds:[di].VBI_transferBitmapPos.P_y

	.leave
	ret
VisBitmapGetTransferBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetBackupBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_GET_BITMAP handler for VisBitmapClass
		Returns the vm file and block handles to the backup bitmap

CALLED BY:	

PASS:		ds:di = VisBitmap instance

RETURN:		cx = vm file handle
		dx = vm block handle

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	1/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetBackupBitmap	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_GET_BACKUP_BITMAP
	.enter

	mov	dx, ds:[di].VBI_backupKit.VBK_bitmap
	call	ClipboardGetClipboardFile		;bx <- VM file
	mov	cx, bx

	.leave
	ret
VisBitmapGetBackupBitmap	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_GET_VM_FILE

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		ax - VM file handle

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 31, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetVMFile	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_GET_VM_FILE
	uses	di
	.enter

	;
	;	If the VisBitmap's block is in a VM file, then we use it.
	;
	test	ds:[LMBH_flags], mask LMF_IS_VM
	jz	checkDefault

	mov	bx, ds:[LMBH_handle]
	mov	ax,MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo

done:
	.leave
	ret

	;
	;	The VisBitmap isn't in a VM file, so the vm file default
	;	had better be set
	;
checkDefault:
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ax, ds:[di].VBI_vmFile
EC<	tst	ax							>
EC<	ERROR_Z	NO_PASSED_VM_FILE_AND_VIS_BITMAP_NOT_IN_VM_BLOCK	>
	jmp	done
VisBitmapGetVMFile	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_OPEN handler for VisBitmapClass

		Checks to make sure that a bitmap has been allocated, and
		if not, sends a MSG_VIS_BITMAP_CREATE_BITMAP

PASS:		ds:si 	= VisBitmap object
		ax	= MSG_VIS_OPEN

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	1/91		initial version
	jon	8/14/91		revised to provide more flexible API
	jon	8 jan 92	revised API
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapVisOpen	method dynamic	VisBitmapClass, MSG_VIS_OPEN

	.enter

	mov	di, offset VisBitmapClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	cx, ds:[di].VBI_mainKit.VBK_bitmap
	jcxz	createBitmap

done:
	.leave
	ret

createBitmap:
	;
	;	Create the bitmap by telling it that its geometry is valid.
	;	
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	ObjCallInstanceNoLock
	jmp	done
VisBitmapVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_CLOSE handler for VisBitmapClass

CALLED BY:	

PASS:		*ds:si - instance data
		ds:di = instance data
		es - segment of VisClass
		
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapVisClose	method dynamic	VisBitmapClass, MSG_VIS_CLOSE

	.enter

if BITMAP_TEXT
	;
	;	First send a MSG_VIS_CLOSE to the text object
	;
	mov	bx, ds:[di].VBI_visText.handle
	tst	bx
	jz	callSuper
	push	si
	mov	si, ds:[di].VBI_visText.chunk
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

callSuper:
endif

	;
	;  Get rid of our gstate first
	;

	mov	ax, MSG_VIS_BITMAP_DESTROY_SCREEN_GSTATE
	call	ObjCallInstanceNoLock

	;
	;	Call our superclass
	;
	mov	di, offset VisBitmapClass
	mov	ax, MSG_VIS_CLOSE
	call	ObjCallSuperNoLock

	.leave
	ret
VisBitmapVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapRelocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with relocation and unrelocation of VisBitmaps

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)

		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper

RETURN:		carry - set if error
		bp - unchanged

DESTROYED:	
		ax,cx,dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	17 jun 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapRelocation	method dynamic VisBitmapClass, reloc

	.enter

	cmp	dx,VMRT_RELOCATE_AFTER_READ
	jne	done

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	BitClr	ds:[di].VI_geoAttrs, VA_REALIZED

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	push	ax
	clr	ax
	mov	ds:[di].VBI_screenGState, ax
	mov	ds:[di].VBI_mainKit.VBK_gstate, ax
	mov	ds:[di].VBI_lastEdit, ax
	mov	ds:[di].VBI_backupKit.VBK_gstate, ax
	mov	ds:[di].VBI_backupKit.VBK_bitmap, ax
	mov	ds:[di].VBI_transferGString, ax
	mov	ds:[di].VBI_transferBitmap, ax
	mov	ds:[di].VBI_vmFile, ax
	mov	ds:[di].VBI_backupThread, ax
	mov	ds:[di].VBI_editingKit.VBEK_screen,ax
	mov	ds:[di].VBI_editingKit.VBEK_bitmap,ax
	mov	ds:[di].VBI_editingKit.VBEK_gstring,ax
	mov	ds:[di].VBI_editingKit.VBEK_memBlock,ax
	clrdw	ds:[di].VBI_fatbits,ax
	clrdw	ds:[di].VBI_fatbitsWindow,ax
	clrdw	ds:[di].VBI_finishEditingOD, ax
	mov	ds:[di].VBI_finishEditingMsg, ax
	clrdw	ds:[di].VBI_mouseGrab, ax
	mov	ds:[di].VBI_antTimer, ax

	;
	;  Clear out any vardata
	;

	mov	ax, ATTR_BITMAP_INTERACTIVE_DISPLAY_KIT
	call	ObjVarDeleteData

	pop	ax
done:
	clc
	mov	di, offset VisBitmapClass
	call	ObjRelocOrUnRelocSuper

	.leave
	ret
VisBitmapRelocation	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_GAINED_TARGET_EXCL handler for VisBitmapClass.

		This method is subclassed in order see whether we need
		to restart our ant timer.

PASS:		nothing
		
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	17 jun 1992	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGainedTargetExcl	method dynamic	VisBitmapClass,
				MSG_META_GAINED_TARGET_EXCL

	.enter

	mov	di, offset VisBitmapClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_FORMAT_CHANGE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_BITMAP_NOTIFY_SELECT_STATE_CHANGE
	call	ObjCallInstanceNoLock

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_FATBITS_SET_VIS_BITMAP
	call	VisBitmapSendToVisFatbits

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset	
	cmp	ds:[di].VBI_antTimer, VIS_BITMAP_ANT_TIMER_PAUSED
	jne	done

	clr	ds:[di].VBI_antTimer
	mov	ax, MSG_VIS_BITMAP_SPAWN_SELECTION_ANTS
	call	ObjCallInstanceNoLock

done:

	mov	cx, 1
	mov	dx, 1
	call	GeodeGetProcessHandle
	mov	ax, MSG_GEN_PROCESS_UNDO_SET_CONTEXT
	clr	di
	call	ObjMessage

	.leave
	ret
VisBitmapGainedTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_LOST_TARGET_EXCL handler for VisBitmapClass.

		This method is subclassed in order see whether we need
		to kill our ant timer.

PASS:		nothing
		
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	17 jun 1992	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapLostTargetExcl		method dynamic	VisBitmapClass,
				MSG_META_LOST_TARGET_EXCL

	.enter

	cmp	ds:[di].VBI_antTimer, VIS_BITMAP_ANT_TIMER_PAUSED
	jbe	callSuper

	mov	ax, MSG_VIS_BITMAP_KILL_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_antTimer, VIS_BITMAP_ANT_TIMER_PAUSED	

callSuper:

	call	VisBitmapDetachBackupThread

	mov	di, segment VisBitmapClass
	mov	es, di
	mov	di, offset VisBitmapClass
	mov	ax, MSG_META_LOST_TARGET_EXCL
	call	ObjCallSuperNoLock

	.leave
	ret
VisBitmapLostTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapCreateTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_CREATE_TRANSFER_FORMAT

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		cx = VM file handle

Return:		ax = vm block handle

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 14, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCreateTransferFormat	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_CREATE_TRANSFER_FORMAT
	uses	cx,dx,bp
	.enter

	push	cx				;save dest. vm file

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock

	mov	bx, cx				;bx <- source vm file
	mov_tr	ax, dx				;ax <- source block handle
	clr	bp				;ax:bp <- id
	pop	dx				;dx <- dest. VM file
	call	VMCopyVMChain			;ax:bp <- new id

	.leave
	ret
VisBitmapCreateTransferFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapReplaceWithTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_REPLACE_WITH_TRANSFER_FORMAT

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		cx - vm file handle of transfer file
		dx - vm block handle (same as that returned by 
 			MSG_VIS_BITMAP_CREATE_TRANSFER_FORMAT)

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 14, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapReplaceWithTransferFormat	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_REPLACE_WITH_TRANSFER_FORMAT
	uses	cx,dx,bp
	.enter

	call	ObjMarkDirty

	push	cx, dx				;save passed file, block

	;
	;  Make sure nobody's using our gstates
	;
	mov	ax, MSG_VIS_BITMAP_FORCE_CURRENT_EDIT_TO_FINISH
	call	ObjCallInstanceNoLock

	;
	;  Free the main gstate, 'cause it'll no longer be valid
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	cx
	xchg	cx, ds:[di].VBI_mainKit.VBK_gstate
	jcxz	getMainBitmap

	mov	di, cx
	mov	al, BMD_KILL_DATA
	call	GrDestroyBitmap
	jmp	getNew

getMainBitmap:
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock

	tst	dx
	jz	getNew

	mov	bx, cx
	mov_tr	ax, dx
	clr	bp
	call	VMFreeVMChain

getNew:
	mov	ax, MSG_VIS_BITMAP_GET_VM_FILE
	call	ObjCallInstanceNoLock
	mov_tr	dx, ax				;dx <- dest vm file
	pop	bx, ax				;bx <- source vm file handle
						;ax <- source vm block handle
	;
	; Now we either want to copy the bitmap, or compact it. Since 
	; GrCompactBitmap takes the destination VM file handle, it essentially
	; does the copying at the same time. If the bitmap is not currently
	; compacted, then we will compact it
	;
	push	bx, ax
	mov	ax, ATTR_BITMAP_DO_NOT_COMPACT_BITMAP
	call	ObjVarFindData
	pop	bx, ax
	jc	noCompact

	call	CheckHugeArrayBitmapCompaction
	jne	noCompact			;compacted, just copy
	jc	compactBitmap			;uncompacted, so compact it now
	; just copy anyhow

noCompact:
	clr	bp
	call	beforeBitmapCopy
	call	VMCopyVMChain			;...otherise copy the bitmap
	call	afterBitmapCopy
	
afterCopy:
	;
	; We completed the copy (new bitmap is in DX:AX)
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_mainKit.VBK_bitmap, ax

	mov	bx, dx
	call	VMLock
	mov	es, ax
	mov	al, es:[(size HugeArrayDirectory)].CB_simple.B_type
	andnf	al, mask BMT_FORMAT
	mov	ds:[di].VBI_bmFormat, al
	mov	bx, es:[(size HugeArrayDirectory)].CB_xres
	mov	ds:[di].VBI_xResolution, bx
	mov	bx, es:[(size HugeArrayDirectory)].CB_yres
	mov	ds:[di].VBI_yResolution, bx
	call	VMUnlock

	mov	ax, MSG_VIS_BITMAP_VIS_BOUNDS_MATCH_BITMAP_BOUNDS
	call	ObjCallInstanceNoLock

	.leave
	ret

compactBitmap:
	;
	; The bitmap needs to be compacted
	;
	call	beforeBitmapCopy
	call	GrCompactBitmap			;dx:cx <- compacted bitmap
	call	afterBitmapCopy
	mov_tr	ax, cx
	jmp	afterCopy

	;
	; Before we copy the bitmap, let's do our best to make sure
	; that handle allocation & memory use is minized. So, let's do
	; a VMUpdate on the destination file. I also tried in the past
	; doing a VMUpdate on the source, but that just slowed things
	; down because (I believe) the bitmap data was already in swap'ed
	; memory, so it is faster to access then from the disk. To minimize
	; handle usage we could also turn off VMA_SYNC_UPDATE on the source
	; file, and while that does save handles is results in the copy
	; process taking about twice as long.
	;
beforeBitmapCopy:
	push	ax, bx
	mov	bx, dx
	call	VMUpdate			; update destination
	pop	ax, bx
	retn

	;
	; After we we copy the bitmap, perfom a VMUpdate on the destination,
	; and restore the SYNC_UPDATE status. D must be passed holding the
	; value returned from beforeBitmapCopy sub-routine. To  ensure the
	; "Import Status" DB comes down, we queue a message first through
	; our process to send a message back to initiate the auto-save.
	;
afterBitmapCopy:
	push	ax, bx, cx, dx, di, si
	mov	ax, MSG_META_VM_FILE_AUTO_SAVE
	call	GeodeGetProcessHandle
	mov	cx, dx				; VM file -> cx
	mov	di, mask MF_RECORD
	call	ObjMessage			; event handle -> di
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	cx, di
	mov	dx, mask MF_FORCE_QUEUE
	mov	di, dx
	call	ObjMessage
	pop	ax, bx, cx, dx, di, si
	retn
VisBitmapReplaceWithTransferFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHugeArrayBitmapCompaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the bitmap is compacted

CALLED BY:	GLOBAL

PASS:		BX:AX	= Bitmap VM file:block handles

RETURN:		ZF	= Set if uncompacted
                CF	= Set if should be compacted

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/20/94		Initial version
	Don	10/21/00	Don't both ever compressing a 24-bit bitmap,
				  or the CMY or CMYK bitmaps

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHugeArrayBitmapCompaction	proc	far
	uses	ax, bp, es
	.enter
	
	call	VMLock
	mov	es, ax
	cmp	es:[(size HugeArrayDirectory)].CB_simple.B_compact, \
								BMC_UNCOMPACTED
	pushf

	; OK, we're not compacted. If we're mono, 4-bit, or 8-bit, then
	; we are excellent compaction candidates. Anything else, we're not

	mov	al, es:[(size HugeArrayDirectory)].CB_simple.B_type
	and	al, mask BMT_FORMAT
	cmp	al, BMF_MONO
	je	doneCompact				; mono - ZF set
	cmp	al, BMF_4BIT
	je	doneCompact				; 4-bit - ZF set
	cmp	al, BMF_8BIT			; if 8-bit, ZF set, else not
	je	doneCompact
	popf
	clc	; recomment not to compact
	jmp	done
doneCompact:
	popf
	stc
done:
	call	VMUnlock

	.leave
	ret
CheckHugeArrayBitmapCompaction	endp

BitmapBasicCode	ends

BitmapEditCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up our non-zero defaults

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)

		ax - method
		dx - VMRelocType
RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	17 jun 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapInitialize	method dynamic VisBitmapClass,
			MSG_META_INITIALIZE
	.enter

	mov	di, offset VisBitmapClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	ornf	ds:[di].VBI_undoFlags, mask VBUF_TRANSPARENT
	mov	ds:[di].VBI_bmFormat, BMF_4BIT
	mov	ds:[di].VBI_xResolution, 72
	mov	ds:[di].VBI_yResolution, 72

	.leave
	ret
VisBitmapInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up our non-zero defaults

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	17 jun 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0	;grobj intercepts and doesn't call super class anyways...
VisBitmapInvalidate	method dynamic VisBitmapClass,
			MSG_VIS_INVALIDATE
	.enter

	mov	di, offset VisBitmapClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_INVALIDATE
	call	VisBitmapSendToVisFatbits

	.leave
	ret
VisBitmapInvalidate	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapInvalidateIfTransparent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up our non-zero defaults

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	17 jun 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapInvalidateIfTransparent	method dynamic VisBitmapClass,
					MSG_VIS_BITMAP_INVALIDATE_IF_TRANSPARENT
	.enter

if 0
	test	ds:[di].VBI_undoFlags, mask VBUF_TRANSPARENT
	jz	done

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

done:
endif
	.leave
	ret
VisBitmapInvalidateIfTransparent	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapSetVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_SET_VM_FILE

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		cx - VM file handle

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 31, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetVMFile	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_SET_VM_FILE
	.enter

	mov	ds:[di].VBI_vmFile, cx	

	.leave
	ret
VisBitmapSetVMFile	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapSetVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_SET_VIS_BOUNDS

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		ss:bp - Rectangle

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 31, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetVisBounds	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_SET_VIS_BOUNDS
	.enter

	mov	ax, ss:[bp].R_left
	mov	ds:[di].VI_bounds.R_left, ax
	mov	ax, ss:[bp].R_top
	mov	ds:[di].VI_bounds.R_top, ax
	mov	ax, ss:[bp].R_right
	mov	ds:[di].VI_bounds.R_right, ax
	mov	ax, ss:[bp].R_bottom
	mov	ds:[di].VI_bounds.R_bottom, ax

	.leave
	ret
VisBitmapSetVisBounds	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetBitmapSizeInPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_POINTS

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		cx,dx = bitmap point width, height

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 31, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetBitmapSizeInPoints	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_POINTS
	uses	bp

	.enter

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock			;cx <- vm file handle
							;dx <- vm block handle
	mov	bx, cx					;bx <- vm file handle

	tst	dx					;no bitmap, no size
	mov	cx, dx
	jz	done

	mov	di, dx					;di <- vm block handle
	call	GrGetHugeBitmapSize
	mov_tr	cx, ax					;cx <- width
	mov	dx, bx					;dx <- height

done:
	.leave
	ret
VisBitmapGetBitmapSizeInPoints	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetBitmapSizeInPixels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_PIXELS

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		cx,dx = bitmap pixel width,height

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 31, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetBitmapSizeInPixels	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_PIXELS
	uses	bp
	.enter

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock
	mov_tr	bx, cx

	tst	dx					;no bitmap, no size
	mov	cx, dx
	jz	done

	mov_tr	ax, dx
	call	VMLock
	mov	ds, ax
	mov	cx, ds:[size HugeArrayDirectory].CB_simple.B_width
	mov	dx, ds:[size HugeArrayDirectory].CB_simple.B_height
	call	VMUnlock

done:
	.leave
	ret
VisBitmapGetBitmapSizeInPixels	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapCreateBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_CREATE_BITMAP

		Allocates a bitmap and initizes it. Also allocates a
		backup bitmap if VBUF_USES_BACKUP_BITMAP is set.

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		cx,dx = width,height of bitmap to be allocated
			(or either 0 to use bounds of passed gstring)
		bp = handle to gstring to draw to created bitmap (0 for none)

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	June, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCreateBitmap	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_CREATE_BITMAP

	uses	cx, dx, bp

	.enter

	call	ObjMarkDirty

	call	VisBitmapMarkBusy

	jcxz	calcDimensions
	tst	dx
	jnz	haveDimensions

calcDimensions:
	tst	bp

if 0	;ERROR_CHECK
	ERROR_Z	BAD_CREATE_BITMAP_PARAMS
else
	jz	markNotBusyShort
endif

	push	si, di				;save obj, instance
	clr	dx, di
	mov	si, bp

	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos

	call	GrGetGStringBounds
	pop	si, di				;*ds:si - VisBitmap
						;ds:di - instance
	jnc	setBounds
markNotBusyShort:
	jmp	markNotBusy

setBounds:
	;
	; if the bitmap is too large, then forget it.
	;
	push	cx, dx
	sub	cx, ax
	sub	dx, bx
	call	VisBitmapCheckBitmapSize
	pop	cx, dx
	jc	bitmapTooLarge

	;
	;  Set our bounds to the bounds of the gstring
	;
	push	ax, bx,bp			;save left,top,gstring
	push	dx
	push	cx
	push	bx
	push	ax
	mov	bp, sp
	mov	ax, MSG_VIS_BITMAP_SET_VIS_BOUNDS
	call	ObjCallInstanceNoLock
	add	sp, size Rectangle

	pop	ax, bx, bp			;ax <- left, bx <- top,
						;bp <- gstring
	sub	cx, ax				;cx <- gstring width
	sub	dx, bx				;dx <- gstring height
	jmp	sizeOK

haveDimensions:
	;
	; if the bitmap is too large, then forget it.
	;
	call	VisBitmapCheckBitmapSize
	jnc	sizeOK

bitmapTooLarge:
	; bitmap is too large.  notify user.

	clr	ax
	pushdw	axax			; SDOP_helpContext
	pushdw	axax			; SDOP_customTriggers
	pushdw	axax			; SDOP_stringArg2
	pushdw	axax			; SDOP_stringArg1
	mov	ax, handle BitmapTooLargeString
	push	ax
	mov	ax, offset BitmapTooLargeString
	push	ax			; SDOP_customString
	mov	ax, CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE or \
		    GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE
	push	ax			; SDOP_customFlags
	call	UserStandardDialogOptr

	; and redraw.

	push	si
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	mov	ax, MSG_GEN_VIEW_REDRAW_CONTENT
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	ax, MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS
	mov	cx, di
	call	ObjCallInstanceNoLock
	jmp	markNotBusy	

sizeOK:
	push	cx, dx				;save width, height

	;
	;	Create the damn bitmap
	;
	push	bp				;save gstring
	clr	bx				;use default file
	call	CreateBitmapCommon
	pop	cx				;cx <- gstring handle

	;
	;	No errors, so save the returned handles
	;

	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset
	mov	ds:[bp].VBI_mainKit.VBK_bitmap, ax
	mov	ds:[bp].VBI_mainKit.VBK_gstate, di

	;
	;	See if there's a gstring to be drawn
	;
	jcxz	checkBackup

	;
	;	Draw the damn gstring, centered on the bitmap
	;

	mov	bp, di				;bp <- gstate
	push	si				;save bitmap chunk handle
	mov	si, cx
	clr	di,dx

	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos

	call	GrGetGStringBounds
	mov	di, si				;di <- gstring
	pop	si				;si <- chunk handle

;
; Previously, the gstring was being centered within the past bounds, but
; that isn't working for GrObj text objects, which are upper-left aligned
; in their territory, so I'll use that as my guiding principle for now.
;
if 0
	sub	cx, ax
	sub	dx, bx
	pop	ax,bx				;ax,bx <- width, height
	sub	ax, cx
	sub	bx, dx
	mov_tr	dx, ax
	clr	ax, cx

	;
	;  incomprehensible fudge factor
	;
	dec	dx
	dec	bx

	sarwwf	dxcx
	sarwwf	bxax
else

	;
	;  We want to apply a translation so that the upper left
	;  of the gstring comes out at 0,0
	;
	mov_tr	dx, ax				;dx <- left
	neg	dx
	neg	bx
	clr	ax, cx
	add	sp, 4				;clear height, width
endif
	
	xchg	di, bp				;bp <- gstring
						;di <- bitmap gstate
	call	GrSaveState
	call	GrApplyTranslation
	mov	cx, bp				;cx <- gstring
	mov	bp, di				;bp <- bitmap gstate
	clr	dx				;don't free block
	mov	ax, MSG_VIS_BITMAP_BACKUP_GSTRING_TO_BITMAP
	call	ObjCallInstanceNoLock
	call	GrRestoreState

	call	HackAroundWinScale

	sub	sp, 4				;pretend we didn't pop width/h

	;
	;	Creating a backup bitmap gives us a responsive undo
	;	mechanism; without it, and if the bitmap is UNDOABLE,
	;	performance will be slow.
	;
checkBackup:
	add	sp, 4				;clear width/height from stack
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	test	ds:[di].VBI_undoFlags, mask VBUF_USES_BACKUP_BITMAP
	jz	afterBackupCreate

	mov	ax, MSG_VIS_BITMAP_CREATE_BACKUP_BITMAP
	call	ObjCallInstanceNoLock

afterBackupCreate:
	;
	;	Set the initial gstate info
	;
	sub	sp, size VisBitmapGraphicsStateStuff
	mov	bp, sp

	;
	;	C_BLACK area color
	;
	mov	ss:[bp].VBGSS_areaColor.high, CF_RGB shl 8
	mov	ss:[bp].VBGSS_areaColor.low, 0x0000

	;
	;	C_BLACK line color
	;
	mov	ss:[bp].VBGSS_lineColor.high, CF_RGB shl 8
	mov	ss:[bp].VBGSS_lineColor.low, 0x0000

	;
	;	C_WHITE background color
	;
	mov	ss:[bp].VBGSS_backColor.high, CF_RGB shl 8 or 0xff
	mov	ss:[bp].VBGSS_backColor.low, 0xffff

	;
	;	Line width = 1
	;
	mov	ss:[bp].VBGSS_lineWidth, 1

	mov	ax, MSG_VIS_BITMAP_SET_GSTATE_STUFF
	call	ObjCallInstanceNoLock

	add	sp, size VisBitmapGraphicsStateStuff

	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_FORMAT_CHANGE
	call	ObjCallInstanceNoLock


markNotBusy:
	call	VisBitmapMarkNotBusy
	.leave
	ret
VisBitmapCreateBitmap	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapCheckBitmapSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check bitmap size against max size

CALLED BY:	VisBitmapCreateBitmap
PASS:		*ds:si	= VisBitmap object
		cx,dx	= width,height of bitmap
RETURN:		carry set if bitmap is too large
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	7/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

bitmapCategory	char	"bitmap",0
bitmapSizeKey	char	"bitmapSizeLimit",0

VisBitmapCheckBitmapSize	proc	near
	class	VisBitmapClass
	uses	ax,bx,cx,dx,si,ds
	.enter

	mov	ax, cx
	mul	dx			; dx:ax = number of pixels in bitmap

	mov	bx, ds:[si]
	add	bx, ds:[bx].VisBitmap_offset
	mov	cl, ds:[bx].VBI_bmFormat

	cmp	cl, BMF_8BIT		; 8bit = 1 byte/pixel
	je	gotSize

	shrdw	dxax
	cmp	cl, BMF_4BIT		; 4bit = 1/2 byte/pixel
	je	gotSize
	cmp	cl, BMF_4CMYK		; 4cmyk = 1/2 byte/pixel
	je	gotSize
	cmp	cl, BMF_3CMY		; 3cmy = 1/2 byte/pixel
	je	gotSize

	shrdw	dxax
	shrdw	dxax
	cmp	cl, BMF_MONO		; mono = 1/8 byte/pixel
	jne	tooLarge		; other formats are considered too big
gotSize:
	shldw	dxax
	shldw	dxax
	shldw	dxax
	shldw	dxax
	shldw	dxax
	shldw	dxax			; dx = number of kbytes in bitmap
	mov_tr	bx, dx			; bx = number of kbytes in bitmap

	mov	ax, 65535		; default limit = 65535K
	mov	cx, cs
	mov	dx, offset bitmapSizeKey
	mov	ds, cx
	mov	si, offset bitmapCategory
	call	InitFileReadInteger
	cmp	ax, bx
	jae	done
tooLarge:
	stc
done:
	.leave
	ret
VisBitmapCheckBitmapSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapCreateBackupBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_CREATE_BACKUP_BITMAP
		Creates a backup bitmap and stores the relevant handles
		in the VisBitmap's instance data.

Called by:	VisBitmapCreateBitmap, GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		carry set if successful

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCreateBackupBitmap	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_CREATE_BACKUP_BITMAP

	uses	cx, dx, bp
	.enter

	;
	;  Free the backup bitmap
	;

	call	DestroyBackupBitmap

	;
	;  Make a copy of the main bitmap and save it as our backup
	;

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock
	tst	dx
	jz	done

	;
	;  Use the clipboard file for the backup bitmap
	;
	mov_tr	ax, dx					;ax <- source block
	call	ClipboardGetClipboardFile		;bx <- dest VM file
	mov	dx, bx					;dx <- dest VM file

	mov	bx, cx					;bx <- source file
	clr	bp
	call	VMCopyVMChain

	call	ObjMarkDirty
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_backupKit.VBK_bitmap, ax
	stc
done:
	.leave
	ret
VisBitmapCreateBackupBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CreateBitmapCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates 

Pass:		*ds:si - VisBitmap object
		cx, dx = dimensions of bitmap to be allocated
		bx - vm file handle to use (0 for default)

Return:		bx = VM file handle of bitmap
		ax = VM block handle of bitmap
		di = gstate handle

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateBitmapCommon	proc	far
	class	VisBitmapClass

	uses	si,dx,bp
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	al, ds:[di].VBI_bmFormat

	rept offset BMT_FORMAT
	shl	al
	endm
	or	al, mask BMT_COMPLEX

	test	ds:[di].VBI_undoFlags, mask VBUF_TRANSPARENT
	jz	gotFormat

	or	al, mask BMT_MASK

gotFormat:
	mov	bp, bx				;bp <- vm file handle
	mov	bx, ds:[di].VBI_yResolution
	mov	di, ds:[di].VBI_xResolution
	call	CreateNewBitmap

	;
	;	Clear the mask if we're transparent
	;
	push	ax
	mov	ax, mask BM_EDIT_MASK
	clr	dx
	call	GrSetBitmapMode
	test	ax, mask BM_EDIT_MASK
	jz	afterMask

	call	GrClearBitmap
	clr	ax
	call	GrSetBitmapMode
afterMask:
	pop	ax

	.leave
	ret
CreateBitmapCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapResizeRealEstate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_RESIZE_REAL_ESTATE

		Resizes the bitmap's dimensions


Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance
		ss:[bp] = RectAndGState:

			RAG_gstate = gstate to transform original bitmap
					through before drawing to newly resized
					bitmap

			RAG_rect = new bitmap coordinates (in old
					bitmap coordinates)

			E.g., if you want to increase the size of the
			bitmap by 5 pixels on all sides, you would pass:

			ss:bp.R_left   = -5
			ss:bp.R_top    = -5
			ss:bp.R_right  = (current right) + 5
			ss:bp.R_bottom = (current bottom) + 5

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 13, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapResizeRealEstate	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_RESIZE_REAL_ESTATE
	uses	cx, dx, bp
	.enter

	call	VisBitmapMarkBusy

	;
	;	See if the desired real estate is different from the
	;	current real estate
	;
	tst	ss:[bp].RAG_rect.R_left		;change in left bound?
	jnz	doResize

	tst	ss:[bp].RAG_rect.R_top		;change in top bound?
	jnz	doResize

	;
	;	We need to extract the bitmap's dimensions to determine
	;	whether a resize is needed
	;
	mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_POINTS
	call	ObjCallInstanceNoLock

	;
	;	Check for non-zero size
	;
EC<	tst	cx				>
EC<	ERROR_Z	OPERATION_REQUIRES_BITMAP	>

NEC<	jcxz	done				>

	cmp	cx, ss:[bp].RAG_rect.R_right	;change in right bound?
	jne	doResize

	cmp	dx, ss:[bp].RAG_rect.R_bottom	;change in bottom bound?
	jne	doResize

done:
	call	VisBitmapMarkNotBusy

	.leave
	ret

doResize:	

	call	VisBitmapDoThatCrazyRemappingThing
	jmp	done
VisBitmapResizeRealEstate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapSetFormatAndResolution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_SET_FORMAT_AND_RESOLUTION

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		cl - BMFormat
		dx - x resolution
		bp - y resolution

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 22, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetFormatAndResolution	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_SET_FORMAT_AND_RESOLUTION

	uses	cx, dx, bp

	.enter

	;    If we haven't created a bitmap yet then just store the
	;    data
	;

	tst	ds:[di].VBI_mainKit.VBK_bitmap
	jnz	checkForChanges
	mov	ds:[di].VBI_bmFormat,cl
	mov	ds:[di].VBI_xResolution,dx
	mov	ds:[di].VBI_yResolution,bp

done:
	.leave
	ret

checkForChanges:
	cmp	ds:[di].VBI_bmFormat, cl
	jne	makeTheChange
	cmp	ds:[di].VBI_xResolution, dx
	jne	makeTheChange
	cmp	ds:[di].VBI_yResolution, bp
	je	done

makeTheChange:

	call	VisBitmapMarkBusy

	mov	bl, cl					;save format
	push	dx					;save x res
	push	bp					;save y res
	
	mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_POINTS
	call	ObjCallInstanceNoLock


	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_bmFormat, bl
	pop	ds:[di].VBI_yResolution
	pop	ds:[di].VBI_xResolution

	sub	sp, size RectAndGState
	mov	bp, sp
	clr	ax
	mov	ss:[bp].RAG_rect.R_left, ax
	mov	ss:[bp].RAG_rect.R_right, cx
	mov	ss:[bp].RAG_rect.R_top, ax
	mov	ss:[bp].RAG_rect.R_bottom, dx
	mov	ss:[bp].RAG_gstate, ax

	call	VisBitmapDoThatCrazyRemappingThing
	add	sp, size RectAndGState

	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_FORMAT_CHANGE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	call	VisBitmapMarkNotBusy

	jmp	done
VisBitmapSetFormatAndResolution	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BitmapCopyTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		di - destination gstate
		cx - source gstate

		dx,ax - ammount to translate before copying transform

Return:		nothing

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapCopyTransform	proc	far

	uses	ax, bx, cx, ds, si

matrix	local	TransMatrix

	.enter

	push	cx				;save source gstate
	mov_tr	bx, ax
	clr	ax, cx
	call	GrApplyTranslation

	mov_tr	ax, di				;ax <- dest gstate
	pop	di				;di <- source gstate
	segmov	ds, ss
	lea	si, ss:matrix
	call	GrGetTransform			;ds:si <- source transform
	mov_tr	di, ax				;di <- dest gstate
	call	GrApplyTransform		;dest gstate <- source matrix

	.leave

	ret
BitmapCopyTransform	endp	

if BITMAP_TEXT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapCreateVTFB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_CREATE_VTFB handler for VisTextForBitmaps
		This method instantiates a VisTextForBitmaps object, sets
		up its initial values, and creates a one-way upward visual
		linkage from the text object to the VisBitmap.

CALLED BY:	

PASS:		*ds:si = VisBitmap object
		
RETURN:		^lcx:dx = newly created VisTextForBitmaps object

DESTROYED:	ax, bx, bp, di, si

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCreateVTFB method dynamic VisBitmapClass, MSG_VIS_BITMAP_CREATE_VTFB
	;
	;	Create a VisTextForBitmaps object
	;
	mov	di, segment VisTextForBitmapsClass
	mov	es, di
	mov	di, offset VisTextForBitmapsClass
	mov	ax, MSG_VTFB_AFTER_CREATE
	mov	bp, VBI_visText
	call	InstantiateCommon
	ret
VisBitmapCreateVTFB	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapCreateTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_CREATE_TOOL handler for VisBitmapClass.
		Creates a tool of the passed class for editing the bitmap.
		Destroys any previous tool. 

CALLED BY:	global

PASS:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance
		cx:dx = segment:offset of class of desired tool

RETURN:		^lcx:dx = OD of new tool

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		just do it

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCreateTool  method dynamic  VisBitmapClass, MSG_VIS_BITMAP_CREATE_TOOL
	uses	bp
	.enter
	mov	bp, si					;bp <- object chunk

	;
	;	See whether we have an old tool or not
	;
	mov	bx, ds:[di].VBI_tool.handle
	tst	bx					;is there an old tool?
	jz	createNew

	;
	;	If the old tool is the same class as our new tool, then
	;	just re-use the old one.
	;

	push	cx,dx					;desired class
	mov	si, ds:[di].VBI_tool.chunk		;si <- tool offset
	mov	ax,MSG_META_GET_CLASS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	di,dx					;current class offset
	mov	ax,cx					;current class segment
	pop	cx,dx					;desired class
	cmp	di, dx					;class offsets
	jne	notSame
	cmp	ax, cx					;class segments
	je	useCurrentTool

notSame:
	;
	;	Tell the tool to end its last edit, if any
	;
	mov	si, bp					;si <- VB offset
	mov	ax, MSG_VIS_BITMAP_FORCE_CURRENT_EDIT_TO_FINISH
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset

	;
	;  The tool should have released the mouse by now
	;

EC<	cmpdw	ds:[di].VBI_tool, ds:[di].VBI_mouseGrab, ax	>
EC<	ERROR_Z	VIS_BITMAP_FREEING_TOOL_WITH_MOUSE_GRAB		>

	;
	;  Just to be sure...
	;
NEC<	clr	ax				>
NEC<	clrdw	ds:[di].VBI_mouseGrab, ax	>

	;
	;	Free the old tool
	;
	mov	si, ds:[di].VBI_tool.chunk		
	mov	ax, MSG_META_OBJ_FREE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, bp				;si <- object chunk

createNew:
	;
	;	es:di <- pointer to tool class, then instantiate
	;	one of those.
	;
	mov	es, cx				;es:di <- pointer to tool class
	mov	di, dx
	mov	ax, MSG_TOOL_AFTER_CREATE
	mov	bp, VBI_tool
	call	InstantiateCommon

	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_TOOL_CHANGE
	call	ObjCallInstanceNoLock
done:
	.leave
	ret

useCurrentTool:
	mov	bp, ds:[bp]
	add	bp, ds:[bp].VisBitmap_offset
	mov	dx, ds:[bp].VBI_tool.offset
	mov	cx, bx				;current tool handle
	jmp	done
VisBitmapCreateTool	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			InstantiateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si = VisBitmap instance
		es:di = segment:offset of class to be instantiated
		ax = message # to send to instantiated object
		bp = offset into VisBitmap's instance to store optr

Return:		^lcx:dx = newly instantiated object

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	June 1991	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InstantiateCommon	proc	near

	uses	bx, di, si

	.enter
	push	ax					;save after-create
							;method #

	push	bp					;save instance data
							;offset

	push	si					;save object offset

	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate

	;
	;	We're going to create a one-way upward visual link
	;	between the VisBitmap and its VisTextForBitmaps. We do this
	;	because:
	;
	;		1 - The VisText object requires a visual parent
	;		    to make VUP calls, etc.
	;
	;		2 - We don't want to make the VisBitmap a subclass
	;		    of VisComp, since all we really would get out
	;		    of that would be the child linkage
	;
	;	To this end, we must construct the parent OD, which is
	;	done by taking the actual OD and OR'ing LP_IS_PARENT into
	;	the chunk handle.
	;
	mov_tr	ax, si				;ax <- new obj's chunk
	pop	si					;si <- VisBitmap chunk
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
;	ornf	dx, LP_IS_PARENT

	;
	;	At this point, cx:dx is a "parent OD", and will be stored
	;	into the VisTextForBitmap's VI_link with the
	;	MSG_VTFB_AFTER_CREATE
	;

	;
	;	Save the OD of the VisTextForBitmaps in the VisBitmap's
	;	instance data.
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	pop	bp					;bp <- instance offset
	mov	ds:[di][bp].handle, bx
	mov	ds:[di][bp].chunk, ax

	mov_tr	si, ax				;^lbx:si = text object

	;
	;	This call to MSG_META_DUMMY fleshes out the object's
	;	instance data so that we can do stuff to it.  I don't
	;	know why the call to MSG_VTFB_AFTER_CREATE doesn't do
	;	the same thing, but if you remove the call to MSG_META_DUMMY,
	;	the MSG_VTFB_AFTER_CREATE will attempt to set the object's
	;	VI_link, and nothing will happen.
	;
	mov	ax, MSG_META_DUMMY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;	Set up the initial state to the VisTextForBitmap (e.g., initial
	;	font, parent OD, etc.)
	;
	pop	ax
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;	^lcx:dx <- OD of new tool
	;
	mov	cx, bx
	mov	dx, si
	.leave
	ret
InstantiateCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetGStateHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_GET_GSTATE_HANDLE handler for VisBitmapClass
		Returns the handle to the bitmap's gstate

CALLED BY:	

PASS:		ds:di = VisBitmap instance

RETURN:		bp = gstate

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	1/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetMainGState	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_GET_MAIN_GSTATE

	uses	ax, bx, cx, dx, di

	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	bp, ds:[di].VBI_mainKit.VBK_gstate
	tst	bp
	jz	createNew

	;
	;  Stuff the VM file into the gstate in case the damn thing's
	;  changed since we loaded it
	;

	mov	ax, MSG_VIS_BITMAP_GET_VM_FILE
	call	ObjCallInstanceNoLock

	mov	di, bp
	call	GrSetVMFile
	jmp	done

createNew:

	;
	;	Create the damn bitmap
	;
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock
	mov	bp, dx
	tst	dx
	jz	done

	;
	;  Make sure the bitmap is uncompacted
	;
	mov	ax, ATTR_BITMAP_DO_NOT_COMPACT_BITMAP
	call	ObjVarFindData			; carry set if found
	jc	editBitmap

	movdw	bxax, cxdx
	call	CheckHugeArrayBitmapCompaction
	je	editBitmap			;uncompacted, ready for edit

	mov_tr	ax, dx
	mov	dx, cx				;dx <- vm file
	call	GrUncompactBitmap		;dx:cx <- uncompacted bitmap

	push	bp
	clr	bp
	call	VMFreeVMChain			;free the compacted bitmap
	pop	bp

	call	ObjMarkDirty			;be certain to dirty the sucker
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_mainKit.VBK_bitmap, cx

	xchg	cx, dx				;cx <- vm file, dx <- vm handle

editBitmap:
	mov     ax,TGIT_THREAD_HANDLE       ;get thread handle
	clr     bx                          ;...for the current thread
	call    ThreadGetInfo               ;ax = thread handle
	mov_tr  di,ax                       ;di = thread handle

	movdw	bxax, cxdx
	call	GrEditBitmap			;di <- gstate handle

	call	HackAroundWinScale

	push	ax				;save block handle
	mov	al, CMT_DITHER
	call	GrSetAreaColorMap
	call	GrSetLineColorMap
	call	GrSetTextColorMap
	pop	ax				;ax <- vm block handle

	;
	;	No errors, so save the returned handles
	;
	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset
	mov	ds:[bp].VBI_mainKit.VBK_gstate, di
	mov	bp, di				;bp <- main gstate

done:
	.leave
	ret
VisBitmapGetMainGState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetBackupGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_GET_BACKUP_GSTATE handler for VisBitmapClass
		Returns the handle to the bitmap's gstate

CALLED BY:	

PASS:		ds:di = VisBitmap instance

RETURN:		bp = gstate (0 if unsuccessful)

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	1/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetBackupGState	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_GET_BACKUP_GSTATE
	uses	cx, dx
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	bp, ds:[di].VBI_backupKit.VBK_gstate
	tst	bp
	jnz	done

getBitmap:

	;
	;	Create the damn bitmap
	;
	mov	ax, MSG_VIS_BITMAP_GET_BACKUP_BITMAP
	call	ObjCallInstanceNoLock
	mov	bp, dx
	tst	dx
	jz	checkCreate

	;
	;  Make sure the bitmap is uncompacted
	;
	mov	ax, ATTR_BITMAP_DO_NOT_COMPACT_BITMAP
	call	ObjVarFindData			; carry set if found
	jc	editBitmap

	movdw	bxax, cxdx
	call	CheckHugeArrayBitmapCompaction
	je	editBitmap			;uncompacted, ready for edit

	mov_tr	ax, dx
	mov	dx, cx				;dx <- vm file
	call	GrUncompactBitmap		;dx:cx <- uncompacted bitmap
	clr	bp
	call	VMFreeVMChain			;free the compacted bitmap

	call	ObjMarkDirty
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_backupKit.VBK_bitmap, cx

	xchg	cx, dx				;cx <- vm file, dx <- vm handle

editBitmap:
	mov     ax,TGIT_THREAD_HANDLE       ;get thread handle
	clr     bx                          ;...for the current thread
	call    ThreadGetInfo               ;ax = thread handle
	mov_tr  di,ax                       ;di = thread handle

	mov	bx, cx
	mov_tr	ax, dx
	call	GrEditBitmap			;di <- gstate handle

	call	HackAroundWinScale

	push	ax				;save block handle
	mov	al, CMT_DITHER
	call	GrSetAreaColorMap
	call	GrSetLineColorMap
	call	GrSetTextColorMap
	pop	ax				;ax <- vm block handle

	;
	;	No errors, so save the returned handles
	;
	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset
	mov	ds:[bp].VBI_backupKit.VBK_gstate, di
	mov	bp, di				;bp <- backup gstate
done:
	.leave
	ret

checkCreate:
	test	ds:[di].VBI_undoFlags, mask VBUF_USES_BACKUP_BITMAP
	jz	done

	mov	ax, MSG_VIS_BITMAP_CREATE_BACKUP_BITMAP
	call	ObjCallInstanceNoLock
	LONG	jc	getBitmap
	clr	bp
	jmp	done
VisBitmapGetBackupGState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_START_SELECT handler for VisBitmapClass

CALLED BY:	UI

PASS:		ds:di = VisBitmap instance
		cx, dx = mouse coordinates
		bp low = ButtonInfo
		bp high = UIFunctionsActive

RETURN:		ax = MRF_PROCESSED (MouseReturnFlags)

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapStartSelect	method dynamic	VisBitmapClass, MSG_META_START_SELECT

	.enter

	call	MetaGrabTargetExclLow

	;
	;	Pass the method on if it has been requested
	;
	mov	bx, ds:[di].VBI_tool.handle
	tst	bx					;do we have a tool?
	jz	done					;if not, exit
	push	ds:[di].VBI_tool.chunk

	;
	;	Convert coords into bitmap coords
	;
	call	ConvertVisToBitmapCoords
	pop	si
	clr	di
	call	ObjMessage
done:
	mov	ax, mask MRF_PROCESSED
	.leave
	ret
VisBitmapStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Basically handles mouse events other than MSG_META_PTR

CALLED BY:	UI

PASS:		ds:di = VisBitmap instance
		cx, dx = mouse coordinates
		bp low = ButtonInfo
		bp high = UIFunctionsActive

RETURN:		ax = MRF_PROCESSED (MouseReturnFlags)

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapPtr	method dynamic	VisBitmapClass, MSG_META_PTR

	.enter

	test	bp, mask UIFA_MOVE_COPY shl 8
	jnz	checkStatus

	;
	;	Pass the method on if it has been requested
	;

checkMouse:
if 0
	call	VisConstrainPointToVisBounds
endif

	mov	bx, ds:[di].VBI_mouseGrab.handle
	tst	bx				;do we have a tool?
	jz	getToolPtrImage					;if not, exit
	push	ds:[di].VBI_mouseGrab.chunk

	;
	;	Convert coords into bitmap coords
	;
	call	ConvertVisToBitmapCoords
	pop	si
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	.leave
	ret

getToolPtrImage:
	mov	ax, mask MRF_PROCESSED
	mov	bx, ds:[di].VBI_tool.handle
	tst	bx
	jz	done
	mov_tr	cx, ax
	mov	si, ds:[di].VBI_tool.offset
	mov	ax, MSG_TOOL_GET_POINTER_IMAGE
	mov	di, mask MF_CALL
	call	ObjMessage
	jmp	done

checkStatus:
	test	bp, mask UIFA_IN shl 8
	jz	releaseMouse

	call	ClipboardGetQuickTransferStatus
	jz	checkMouse

	push	bp					;save UIFA
	mov	bp, mask CIF_QUICK
	call	ClipboardQueryItem
	push	cx, dx					;save owner
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardTestItemFormat
	pushf
	call	ClipboardDoneWithItem
	popf
	pop	cx, dx					;^lcx:dx <- owner
	pop	bp					;bp high <- UIFA
	mov	ax, CQTF_CLEAR
	jc	setCursor

	;
	;  By default we want to move the item within a single VisBitmap,
	;  but want to copy between bitmaps
	;
	mov	ax, CQTF_MOVE
	cmp	dx, si
	jne	notSource
	cmp	cx, ds:[LMBH_handle]
	je	setCursor
notSource:
	mov	ax, CQTF_COPY
setCursor:
	call	ClipboardSetQuickTransferFeedback
	mov	ax, mask MRF_PROCESSED
	jmp	done

releaseMouse:
	;
	;
	; We are getting pointer events even though the mouse is outside
	; the bounds of our object. Allow someone else to grab the events
	; and signal that we aren't paying attention to them any more.
	;
	call	VisReleaseMouse
	mov	ax, CQTF_CLEAR
	jmp	setCursor
VisBitmapPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Basically handles mouse events other than MSG_META_START_*

CALLED BY:	UI

PASS:		ds:di = VisBitmap instance
		cx, dx = mouse coordinates
		bp low = ButtonInfo
		bp high = UIFunctionsActive

RETURN:		ax = MRF_PROCESSED (MouseReturnFlags)

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapEndSelect	method dynamic	VisBitmapClass, MSG_META_DRAG_SELECT,
							MSG_META_END_SELECT
	.enter

	;
	;	Pass the method on if it has been requested
	;
	mov	bx, ds:[di].VBI_mouseGrab.handle
	tst	bx					;do we have a tool?
	jz	done					;if not, exit
	push	ds:[di].VBI_mouseGrab.chunk

	;
	;	Convert coords into bitmap coords
	;
	call	ConvertVisToBitmapCoords
	pop	si
	clr	di
	call	ObjMessage
done:
	mov	ax, mask MRF_PROCESSED
	.leave
	ret
VisBitmapEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVisToBitmapCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisBitmap
		cx, dx - vis location

Return:		cx,dx in bitmap coords

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  1, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertVisToBitmapCoords	proc	far
	class	VisBitmapClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset

	sub	cx, ds:[di].VI_bounds.R_left
	add	cx, ds:[di].VBI_bitmapToVisHOffset
	sub	dx, ds:[di].VI_bounds.R_top
	add	dx, ds:[di].VBI_bitmapToVisVOffset

	test	ds:[di].VBI_undoFlags, mask VBUF_MOUSE_EVENTS_IN_BITMAP_COORDS
	jnz	done

	call	VisBitmapConvertVisPointToBitmapPoint

done:
	.leave
	ret
ConvertVisToBitmapCoords	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapSetFatbitsMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_SET_FATBITS_MODE

Called by:	MSG_VIS_BITMAP_SET_FATBITS_MODE

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		cx - nonzero for fatbits mode

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSetFatbitsMode	method dynamic	VisBitmapClass,
					MSG_VIS_BITMAP_SET_FATBITS_MODE
	.enter

	BitClr	ds:[di].VBI_undoFlags, VBUF_MOUSE_EVENTS_IN_BITMAP_COORDS
	jcxz	sendToTool

	BitSet	ds:[di].VBI_undoFlags, VBUF_MOUSE_EVENTS_IN_BITMAP_COORDS

sendToTool:
	;
	;  All we really need to do is pass this on to the current tool
	;
	mov	bx, ds:[di].VBI_tool.handle
	tst	bx					;do we have a tool?
	jz	done					;if not, exit
	mov	si, ds:[di].VBI_tool.chunk
	mov	ax, MSG_TOOL_SET_FATBITS_MODE
	clr	di
	call	ObjMessage

done:	
	.leave
	ret
VisBitmapSetFatbitsMode	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapWriteChanges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the last user edit from the temporary store space
		out into the main bitmap.

CALLED BY:	VisBitmapWriteChanges, VisBitmapStartSelect, etc.

PASS:		ds:di = VisBitmap instance
		*ds:si = VisBitmap object
		
RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapWriteChanges	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_WRITE_CHANGES
	uses	cx, dx, bp
	.enter

	;
	;	Make sure we have a gstring that needs to be written.
	;

	call	VisBitmapGetLastEdit
	jcxz	done

	;
	;	Test to see if the change has been undone, 
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	test	ds:[di].VBI_undoFlags, mask VBUF_LAST_EDIT_UNDONE
	jnz	done

	;
	;	Set up the backup gstate with our gstate defaults. If no
	;	backup exists, use the main bitmap
	;
	mov	ax, MSG_VIS_BITMAP_GET_BACKUP_GSTATE
	call	ObjCallInstanceNoLock
	tst	bp
	pushf						;save Z flag
							;(set if we're using
							; the main bitmap)
	jnz	apply

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock
apply:
	mov	ax, MSG_VIS_BITMAP_APPLY_GSTATE_STUFF
	call	ObjCallInstanceNoLock
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	dx	
	xchg	dx, ds:[di].VBI_editingKit.VBEK_memBlock
	popf						;restore Z
	jz	doItOnThisThread

	mov	bx, ds:[di].VBI_backupThread
	tst	bx
	jz	createThread

haveThread:
	mov	ax, MSG_BACKUP_GSTRING_TO_BITMAP
	clr	di
	call	ObjMessage

done:
	.leave
	ret

createThread:
	push	di, bp, cx, dx				;save instance ptr,
							;backup gstate handle,
							;changes gstate handle
							;changes mem block
	call	GeodeGetProcessHandle
	mov	cx, segment BitmapBackupProcessClass
	mov	dx, offset BitmapBackupProcessClass
	mov	bp, 400h				;1K stack for now
	mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	di, bp, cx, dx				;di <- instance ptr
							;bp <- backup gstate
							;cx <- changes gstate
							;dx <- changes block
	jc	doItOnThisThread

	mov	ds:[di].VBI_backupThread, ax
	mov_tr	bx, ax				;bx <- thread handle
	jmp	haveThread

doItOnThisThread:
	mov	ax, MSG_VIS_BITMAP_BACKUP_GSTRING_TO_BITMAP
	call	ObjCallInstanceNoLock
	jmp	done
VisBitmapWriteChanges	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapGetLastEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Retrieves VBI_lastEdit clearing the field in instance
		data on the assumption that it is being written out

Pass:		*ds:si - VisBitmap

Return:		cx - VBI_lastEdit

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 19, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetLastEdit	proc	far
	class	VisBitmapClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	cx
	xchg	cx, ds:[di].VBI_lastEdit

	.leave
	ret
VisBitmapGetLastEdit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteTransferGStringKillPathCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		di - destination gstate
		bx - source gstate

		cx, dx - offset at which to draw the gstring

Return:		nothing

Destroyed:	This is a VisBitmapEditBitmap callback routine, which
		can trash anything it damn well pleases.

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0	;;;unused

WriteTransferGStringKillPathCB	proc	far
	.enter

	tst	bx
	jz	nukePath

	call	GrSaveState
	mov	si, bx			;si <- source gstring

	mov	bx, dx
	clr	dx

	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos

	mov_tr	ax, cx

	call	GrDrawGString
	call	GrRestoreState

nukePath:
	;
	;  Nuke the path
	;
	mov	cx, PCT_NULL
	call	GrBeginPath

	.leave
	ret
WriteTransferGStringKillPathCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteTransferGStringToMaskCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		di - destination gstate
		bx - source gstate

		cx, dx - offset at which to draw the gstring

Return:		nothing

Destroyed:	This is a VisBitmapEditBitmap callback routine, which
		can trash anything it damn well pleases.

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteTransferGStringToMaskCB	proc	far
	.enter

	tst	bx
	jz	done

	call	GrSaveState
	mov	si, bx			;si <- source gstring

	mov	ax, C_BLACK
	call	GrSetAreaColor
	call	GrSetLineColor


	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos

	mov_tr	ax, cx
	mov	bx, dx
	clr	dx

	call	BitmapDrawGStringToMask
	call	GrRestoreState

done:
	.leave
	ret
WriteTransferGStringToMaskCB	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapDrawGStringToMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

PASS:		di	- GState handle
		si	- handle of GString to draw
			  (as returned by GrLoadString)
		ax,bx	- x,y coordinate at which to draw 

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 18, 1993 	Initial version.
	sh	Apr 25, 1994	XIP'ed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapDrawGStringToMask	proc	far
	uses	ax, bx, cx, dx
	.enter

	mov_tr	dx, ax					;dx <- x pos
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos

if 0
	call	GrSaveState

	mov	al, MM_SET
	call	GrSetMixMode

	;
	;  Some gstrings may contain GR_SET_MIX_MODE's, so set
	;  area/line/text color to black just in case. If the GString
	;  does have a GR_SET_MIX_MODE and a GrDrawBitmap following it,
	;  we're screwed.
	;	

	mov	ax, C_BLACK
	call	GrSetAreaColor
	call	GrSetLineColor
	call	GrSetTextColor

	mov_tr	ax, dx					;ax <- pos

	clr	dx
	call	GrDrawGString

	call	GrRestoreState

else
	call	GrGetMixMode
	push	ax

	mov	bx, SEGMENT_CS			; bx <- vseg if XIP'ed
	mov	cx, offset SetMixMode
	mov	dx, mask GSC_OUTPUT
	call	GrParseGString

	pop	ax
	call	GrSetMixMode
endif
	.leave
	ret
BitmapDrawGStringToMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMixMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 10, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMixMode	proc	far
	.enter

	;
	;  If the mix mode is something that depends on the source, we
	;  want to nuke that in favor of MM_SET so that no dithering occurs
	;

	call	GrGetMixMode

	cmp	al, MM_SET
	je	keepGoing

	cmp	al, MM_CLEAR
	je	keepGoing

	cmp	al, MM_INVERT
	je	keepGoing

	;
	;  The bitmap is reserving MM_NOP to mean MM_CLEAR in the mask so
	;  as a hack to make the eraser tool work properly.
	;

	cmp	al, MM_NOP
	je	setClear


	mov	al, MM_SET
setMode:
	call	GrSetMixMode

keepGoing:
	clr	ax

	.leave
	ret

setClear:
	mov	al, MM_CLEAR
	jmp	setMode
SetMixMode	endp


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapDrawGStringToMaskCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

PASS:	ds:si	- pointer to element.
	bx	- BP passed to GrParseGString
	di 	- GState handle passed to GrParseGString

RETURN:	ax	- TRUE if finished, else
		  FALSE to continue parsing.
	ds	- as passed or segment of another
		  huge array block in vm based gstrings.
	
MAY DESTROY: ax,bx,cx,dx,di,si,bp,es

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 18, 1993 	Initial version.
	sh	Apr 26, 1994	XIP'ed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapDrawGStringToMaskCB	proc	far
	.enter

	mov	ax, C_BLACK
	call	GrSetAreaColor
	call	GrSetLineColor

	mov	ax, SDM_100
	cmp	{byte} ds:[si], GR_DRAW_BITMAP
	je	isDrawBitmap

	cmp	{byte} ds:[si], GR_DRAW_BITMAP_CP
	je	isDrawBitmapCP

done:
	.leave
	call	GrSetAreaMask
	mov	ax, FALSE
	ret

isDrawBitmap:

	mov	dx, SEGMENT_CS			; dx <- vseg if XIP'ed
	mov	cx, offset BitmapDrawBitmapFromGStringCB
	mov	ax, ds:[si].ODB_x
	mov	bx, ds:[si].ODB_y
	add	si, size OpDrawBitmap
	call	GrFillBitmap
	mov	ax, SDM_0			;skip the GrDrawBitmap
	jmp	done

isDrawBitmapCP:
	mov	dx, SEGMENT_CS			; dx <- vseg if XIP'ed
	mov	cx, offset BitmapDrawBitmapFromGStringCB
	add	si, size OpDrawBitmapAtCP
	call	GrFillBitmapAtCP
	mov	ax, SDM_0			;skip the GrDrawBitmapAtCP
	jmp	done
BitmapDrawGStringToMaskCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapDrawBitmapFromGStringCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HugeArrayNext bitmap to next slice

CALLED BY:	INTERNAL
		BitmapCreateGrObjFromGrDrawBitmap 

PASS:		ds:si - pointing at CBitmap structure in
		a GR_DRAW_BITMAP or GSE_BITMAP_SLICE gstring element

RETURN:		
		if next gstring element is a GSE_BITMAP_SLICE
			ds:si - pointing at CBitmap structure in next
			gstring element		
			carry clear

		if next gstring element is not a GSE_BITMAP_SLICE
			ds:si - pointing a op code of next gstring element
			carry set
		
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE FAR - it is used as a call back routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapDrawBitmapFromGStringCB		proc	far
	uses	ax,dx
	.enter

	;    Need to point si back to begin of gstring element so
	;    that HugeArrayNext will work.
	;    If CB_numScans is zero then this is the GR_DRAW_BITMAP
	;    element, otherwise it is a GSE_BITMAP_SLICE
	;

	mov	ax,size OpDrawBitmap
	tst	ds:[si].CB_numScans
	jz	10$
	mov	ax,size OpBitmapSlice
10$:
	sub	si,ax

	call	HugeArrayNext

	;   Move si past the OpBitmapSlice data to point at the CBitmap
	;   structure, unless the element we are pointing at is
	;   not a GSE_BITMAP_SLICE
	;

	cmp	ds:[si].OBS_opcode,GSE_BITMAP_SLICE
	jne	notExpected
	add	si,size OpBitmapSlice

	clc
done:
	.leave
	ret

notExpected:
	;    We did not expect to be called back with the pointer pointing
	;    into the last slice of the bitmap. We have now passed onto
	;    the gstring element that lies beyond the bitmap. However the
	;    code after the call to GrDrawBitmap expects ds:si pointing
	;    into the last slice of the bitmap at the CBitmap structure.
	;    So make things happy and stop processing.
	;

	call	HugeArrayPrev
	add	si,size OpBitmapSlice
	stc
	jmp	done	

BitmapDrawBitmapFromGStringCB		endp

endif

if BITMAP_TEXT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapUpdateWindowsAndImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_UPDATE_WINDOWS_AND_IMAGE handler for VisBitmapClass.
		This method is subclassed in order to propogate the call
		down to the text object.

CALLED BY:	

PASS:		cl 	- already-invalidated flag --
		   if set (VUI_ALREADY_INVALIDATED), means we no
		   longer need to invalidate things, unless we hit
		   a window at some point.  Cleared if we are to
		   invalidate things as we find them.
		
RETURN:		nothing

DESTROYED:	ax

KNOWN BUGS/IDEAS:
		I didn't really look into what the flag passed in cl
		means; I just pass it along. If somebody thinks this
		is incorrect, then by all means: fix it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapUpdateWindowsAndImage	method dynamic	VisBitmapClass,
				MSG_VIS_UPDATE_WINDOWS_AND_IMAGE

	uses	cx, dx, bp
	.enter

	;
	;	Save text object OD to stack	
	;
	push	ds:[di].VBI_visText.handle, ds:[di].VBI_visText.chunk

	;
	;	Call the superclass
	;
	mov	di, offset VisBitmapClass
	call	ObjCallSuperNoLock

	;
	;	Pass the call along to the text object
	;
	pop	bx, si					;^lbx:si <- text obj.
	mov	ax, MSG_VIS_UPDATE_WINDOWS_AND_IMAGE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
VisBitmapUpdateWindowsAndImage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapCheckHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_BITMAP_CHECK_TEXT_HEIGHT handler for VisBitmapClass.
		Verifies that the height to which the text object wants to
		resize is valid (i.e., the text object will be fully inside
		the bitmap object).

CALLED BY:	VisTextForBitmapsResize

PASS:		*ds:si = VisBitmap object
		dx = height to which text object woiuld like to resize
		cx = top coordinate of text object IN DOCUMENT COORDINATES
		
RETURN:		dx = height to which the text object may resize

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		return the minimum of:
			1- Passed height
			2- Space between text object top and bitmap bottom
KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCheckTextHeight	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_CHECK_TEXT_HEIGHT
	uses	cx
	.enter

	;
	;	cx <- height between top of text object & bottom of screen
	;	      (The maximum height we should allow)
	;	
	sub	cx, ds:[di].VI_bounds.R_bottom
	add	cx, ds:[di].VI_bounds.R_top
	neg	cx
	inc	cx

	;
	;	If the proposed height is <= the max, then proposed is ok.
	;
	cmp	dx, cx
	jle	done

	;
	;	The proposed height is too much; return the maximum
	;	allowable height in dx.
	;
	mov	dx, cx	
done:
	.leave
	ret
VisBitmapCheckTextHeight endm

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapVupCreateGstate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_VUP_CREATE_GSTATE
		Creates a gstate, and sets the clip region to the bitmap's
		vis bounds.

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		bp = gstate
		carry set

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapVUPCreateGState	method dynamic	VisBitmapClass,
				MSG_VIS_VUP_CREATE_GSTATE
	.enter

	;
	;	Get the gstate from our superclass
	;
	mov	di, offset VisBitmapClass
	call	ObjCallSuperNoLock
	jnc	done

	mov	ax,MSG_VIS_BITMAP_CLIP_GSTATE_TO_VIS_BOUNDS
	call	ObjCallInstanceNoLock

	stc

done:
	.leave
	ret
VisBitmapVUPCreateGState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapClipGStateToVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_VUP_CREATE_GSTATE
		Creates a gstate, and sets the clip region to the bitmap's
		vis bounds.

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		bp = gstate

Return:		bp = gstate with clip rect set

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	srs	Jan  15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapClipGStateToVisBounds  method dynamic VisBitmapClass,
				MSG_VIS_BITMAP_CLIP_GSTATE_TO_VIS_BOUNDS
	uses	cx,dx,bp
	.enter

	;
	;  If the VisBitmap isn't realized (as may occur during a
	;  dynamic creation), then don't clip.
	;
	;  hooey. The realized bit is already set. I'll use the less
	;  intuitive check for the bitmap
	;
if 0
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	done
else
	tst	ds:[di].VBI_mainKit.VBK_bitmap
	jz	done
endif

	mov	di, bp					;di <- gstate
EC <	call	ECCheckGStateHandle			>

	;
	;	Get our vis bounds so we can clip to them
	;
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock

	push	si					;save obj. chunk

	push	ax					;save left
	push	cx					;save right
	push	bp					;save top
	push	dx					;save bottom

	mov_tr	dx, ax					;dx <- left
	mov	bx, bp					;bx <- top

	;
	;	Factor in the bitmap <-> vis offset
	;
	mov	si, ds:[si]
	add	si, ds:[si].VisBitmap_offset
	sub	dx, ds:[si].VBI_bitmapToVisHOffset
	sub	bx, ds:[si].VBI_bitmapToVisVOffset

	;
	;	Translate to the bitmap's origin
	;
	clr	ax, cx					;ax, cx <- 0 frac.
	call	GrApplyTranslation

	mov	ax, ds:[si].VBI_bitmapToVisHOffset
	mov	bx, ds:[si].VBI_bitmapToVisVOffset

	pop	dx					;dx <- vis bottom
	pop	si					;bx <- vis top
	sub	dx, si					;dx <- height
	add	dx, bx					;dx <- bitmap bottom
	pop	cx					;cx <- vis right
	pop	si					;bx <- vis left
	sub	cx, si					;cx <- width
	add	cx, ax					;cx <- bitmap right

	;
	;	Clip the region
	;
	mov	si, PCT_REPLACE
	call	GrSetClipRect
	pop	si					;*ds:si <- VisBitmap

	;
	;  Scale the gstate so that bitmap edits come out in vis coordinates
	;

	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset

	mov	bx, ds:[bp].VBI_yResolution
	mov	dx, 72
	clr	ax, cx
	call	GrUDivWWFixed

	pushwwf	dxcx

	mov	bx, ds:[bp].VBI_xResolution
	mov	dx, 72
	clr	ax, cx
	call	GrUDivWWFixed

	popwwf	bxax
	call	GrApplyScale

done:
	.leave
	ret
VisBitmapClipGStateToVisBounds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetScreenGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_GET_SCREEN_GSTATE
		Checks to see if we have a cached gstate, and if so, returns
		it. Otherwise it creates the gstate and caches it.

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		bp = gstate

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetScreenGState	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_GET_SCREEN_GSTATE

	uses	cx, dx
	.enter

	;
	;	See if we already allocated a screen gstate
	;
	mov	bp, ds:[di].VBI_screenGState
	tst	bp
	jnz	applyGStateStuff

	;
	;	Create a new gstate, cache it in our instance data
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset	
	mov	ds:[di].VBI_screenGState, bp

applyGStateStuff:
	mov	ax, MSG_VIS_BITMAP_APPLY_GSTATE_STUFF
	call	ObjCallInstanceNoLock

	.leave
	ret
VisBitmapGetScreenGState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetEditingGStates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DESCRIPTION:	MSG_VIS_BITMAP_GET_EDITING_GSTATES handler for VisBitmapClass

		Returns a number of gstates necessary to make edits to the
		bitmap. Edits should be made to all of the returned gstates
		that are non-zero. The screen gstate returned in bp is
		guaranteed to be nonzero. 

PASS:		*ds:si 	= VisBitmapClass object

		ss:[bp] - VisBitmapGetEditingGStatesParams

RETURN:		bp	= screen gstate handle
		cx	= edit token

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

		* Always return bp = screen gstate handle

		* Return a gstring gstate handle iff bitmap is undoable

		* Return main bitmap handle if not undoable, or if backup
		  bitmap exists.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/2/91 		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetEditingGStates	method dynamic VisBitmapClass,
				MSG_VIS_BITMAP_GET_EDITING_GSTATES
	uses	dx
	.enter

	call	WriteTransferGStringIfAny

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	movdw	cxdx, ss:[bp].VBGEGSP_requestor
	movdw	ds:[di].VBI_finishEditingOD, cxdx
	mov	ax, ss:[bp].VBGEGSP_finishMsg
	mov	ds:[di].VBI_finishEditingMsg, ax

	mov	ax, MSG_VIS_BITMAP_WRITE_CHANGES
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	test	ds:[di].VBI_undoFlags, mask VBUF_UNDOABLE
	jz	afterStartChain

	movdw	cxdx, ss:[bp].VBGEGSP_undoTitle
	jcxz	afterStartChain

	call	BitmapStartUndoChain

afterStartChain:
	;
	;	bp <- screen gstate
	;
	mov	ax, MSG_VIS_BITMAP_GET_SCREEN_GSTATE
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_editingKit.VBEK_screen, bp

	push	bp					;save screen

	mov	cx, ds:[di].VBI_editingKit.VBEK_gstring
	jcxz	tryBitmap

	mov	bp, cx
	mov	ax, MSG_VIS_BITMAP_APPLY_GSTATE_STUFF
	call	ObjCallInstanceNoLock

tryBitmap:

	mov	bp, ds:[di].VBI_editingKit.VBEK_bitmap
	or	cx, bp
	jcxz	needNew

	tst	bp
	jz	done

	mov	ax, MSG_VIS_BITMAP_APPLY_GSTATE_STUFF
	call	ObjCallInstanceNoLock

done:
	pop	bp					;bp <- screen gstate
	.leave
	ret

needNew:
	;
	;	If there is no bitmap, then I assume we're creating
	;	one dynamically, wherein we fill up a gstring, then
	;	use it to create ourselves. If this is the case, then
	;	create the scratch gstring thing
	;
	tst	ds:[di].VBI_mainKit.VBK_bitmap
	jz	createScratch

	;
	;	Assume not undoable
	;
	clr	cx
	mov	ds:[di].VBI_editingKit.VBEK_gstring, cx
	test	ds:[di].VBI_undoFlags, mask VBUF_UNDOABLE
	jz	getMainHandle

createScratch:
	;
	;	Create a gstring to write the user's actions to in
	;	our scratch block
	;
	mov	ax, MSG_VIS_BITMAP_CREATE_SCRATCH_GSTRING
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_BITMAP_APPLY_GSTATE_STUFF
	call	ObjCallInstanceNoLock

	mov	cx, bp					;cx <- scratch gstate

	;
	;	Store away the handle to our temporary gstring, and
	;	reset the undo flag.
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_editingKit.VBEK_gstring, cx
	mov	ds:[di].VBI_editingKit.VBEK_memBlock, dx

	;
	;	If there is a backup bitmap, then we can go ahead and
	;	return the main bitmap handle. Otherwise, we just return
	;	null in that space
	;
	mov	ax, MSG_VIS_BITMAP_GET_BACKUP_GSTATE
	call	ObjCallInstanceNoLock
	mov	dx, bp
	tst	dx
	jz	afterMain
getMainHandle:
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_BITMAP_APPLY_GSTATE_STUFF
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	dx, bp					;bp,dx <- screen,main
afterMain:
	mov	ds:[di].VBI_editingKit.VBEK_bitmap, dx
	BitClr	ds:[di].VBI_undoFlags, VBUF_LAST_EDIT_UNDONE

	mov	cx, 1					;cx <- token
	jmp	done
VisBitmapGetEditingGStates	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapNotifyCurrentEditFinished
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for
		MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED

		Inform the VisBitmap that the tool is done editing.

Called by:	tools

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapNotifyCurrentEditFinished	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	uses	cx, dx, bp
	.enter

	test	ds:[di].VBI_undoFlags, mask VBUF_UNDOABLE
	jz	closeEdit

	call	BitmapAddUndoAction
	call	BitmapEndUndoChain

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	tst	ds:[di].VBI_undoDepth
	jnz	done

closeEdit:

	call	BitmapCloseEditCommon

done:
	.leave
	ret
VisBitmapNotifyCurrentEditFinished	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapCloseEditCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Closes the current string of edits, which means the
		end of an undoable action chain, as far as the bitmap
		is concerned

Pass:		*ds:si - VisBitmap

Return:		nothing

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 14, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapCloseEditCommon	proc	near
	class	VisBitmapClass
	uses	ax, cx, dx, bp, di, si
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	cx

	;
	;  this stuff used to be below the jcxz, but things were tweaking
	;
	mov	ds:[di].VBI_finishEditingOD.handle, cx
	mov	ds:[di].VBI_editingKit.VBEK_screen, cx
	mov	ds:[di].VBI_editingKit.VBEK_bitmap, cx

	xchg	cx, ds:[di].VBI_editingKit.VBEK_gstring
	jcxz	done
	mov	ds:[di].VBI_lastEdit, cx

	mov	di, cx					;di <- gstring
	call	GrEndGString
	mov	bp, di					;bp <- gstring

	;
	;	If there's no bitmap, then we must have been creating
	;	it from this here gstring
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	tst	ds:[di].VBI_mainKit.VBK_bitmap
	jnz	checkAnts

	clr	cx					;use gstring bounds
	xchg	ds:[di].VBI_lastEdit, cx		;don't want it drawn 2x
	push	cx
	clr	cx
	mov	ax, MSG_VIS_BITMAP_CREATE_BITMAP
	call	ObjCallInstanceNoLock

	;
	;  Destroy the GString
	;
	pop	si
	tst	si
	jz	done

	clr	di
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString
	jmp	done

checkAnts:
	cmp	ds:[di].VBI_antTimer, VIS_BITMAP_ANT_TIMER_PAUSED
	jne	done

	clr	ds:[di].VBI_antTimer
	mov	ax, MSG_VIS_BITMAP_SPAWN_SELECTION_ANTS
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
BitmapCloseEditCommon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapForceCurrentEditToFinish
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for
		MSG_VIS_BITMAP_FORCE_CURRENT_EDIT_TO_FINISH

		Force the tool to finish the current edit (if any).

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapForceCurrentEditToFinish	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_FORCE_CURRENT_EDIT_TO_FINISH
	uses	cx, dx
	.enter

	mov	bx, ds:[di].VBI_finishEditingOD.handle
	tst	bx
	jz	done

	mov	si, ds:[di].VBI_finishEditingOD.chunk
	mov	ax, ds:[di].VBI_finishEditingMsg
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
if 0

checkTransferGString:

	;
	;  Maybe move this thing up to the top?
	;

	call	WriteTransferGStringIfAny
	jmp	done

endif
VisBitmapForceCurrentEditToFinish	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteTransferGStringIfAny
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisBitmap

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec  4, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteTransferGStringIfAny	proc	far
	class	VisBitmapClass
	uses	ax, bx, cx, dx, bp, di
	.enter

	;
	;  See if we need to free a transfer bitmap
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	bx
	xchg	bx, ds:[di].VBI_transferBitmap
	tst	bx
	jz	afterBitmap

	;
	;  Free the transfer bitmap
	; 
	mov_tr	ax, bx					;ax <- vm block handle
	call	ClipboardGetClipboardFile		;bx <- VM file

	push	bp
	clr	bp
	call	VMFreeVMChain
	pop	bp

afterBitmap:

if 0
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	tst	ds:[di].VBI_antTimer
	jz	done
endif

	;
	;  Kill the ants in any case
	;
	mov	ax, MSG_VIS_BITMAP_KILL_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	;
	;  Clear out the gstring. Even if there's nothing there, I don't
	;  care, 'cause I still wanna nuke the path
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	cx
	xchg	cx, ds:[di].VBI_transferGString
	jcxz	done

	push	si
	mov	si, cx
	clr	di
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString
	pop	si

	mov	ax, INVALIDATE_ENTIRE_FATBITS_WINDOW
	mov	bp, offset undoTransferString
	mov	di, offset HomeyDestroyPathCB
NOFXIP<	pushdw	csdi				> 	; mask callback
FXIP<	mov	dx, vseg @CurSeg		>
FXIP<	pushdw	dxdi				>
	mov	di, offset HomeyDestroyPathCB
NOFXIP<	pushdw	csdi				> 	; normal callback
FXIP<	mov	dx, vseg @CurSeg		>
FXIP<	pushdw	dxdi				>
	mov	di, C_BLACK
	push	di

	;
	;  Assume inval rect is ax,bx,cx,dx
	;
	push	ax
	push	ax
	push	ax
	push	ax

	;
	;  Save params

	push	ax
	push	ax
	push	ax
	push	ax

	;
	;  Tell the VisBitmap that we're going to make an edit
	;

	mov	ax, handle BitmapUndoStrings
	pushdw	axbp
	mov	bp, MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	push	bp
	push	ds:[LMBH_handle], si

	mov	bp, sp

	mov	ax, MSG_VIS_BITMAP_GET_EDITING_GSTATES
	call	ObjCallInstanceNoLock

	add	sp, size VisBitmapGetEditingGStatesParams

	push	cx					;save edit ID

	mov	bp, sp
	
	mov	ax, MSG_VIS_BITMAP_EDIT_BITMAP
	call	ObjCallInstanceNoLock

	add	sp, size VisBitmapEditBitmapParams

	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	call	ObjCallInstanceNoLock

	call	BitmapCloseEditCommon

done:

	mov	ax, MSG_VIS_BITMAP_NOTIFY_SELECT_STATE_CHANGE
	call	ObjCallInstanceNoLock

	.leave
	ret
WriteTransferGStringIfAny	endp

HomeyDestroyPathCB	proc	far
	.enter

	;
	;  Nuke the path
	;
	mov	cx, PCT_NULL
	call	GrBeginPath

	.leave
	ret
HomeyDestroyPathCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapCreateScratchGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_CREATE_SCRATCH_GSTRING

		Creates a gstring for tools to write temporary changes to.

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		bp = scratch gstring
		dx = vmem block handle of gstring

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  8, 1992 	Initial version.
	jim	5/92		Changed to reflect changes to GrCreateGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if  BITMAP_USES_VM_BASED_GSTRINGS
VisBitmapCreateScratchGString	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_CREATE_SCRATCH_GSTRING
	uses	cx
	.enter

	call	ClipboardGetClipboardFile		;bx <- VM file

	mov	cl, GST_VMEM
	call	GrCreateGString			; si = chunk handle
	mov	bp, di				;bp <- gstring handle
	clr	dx

	.leave
	ret
VisBitmapCreateScratchGString	endm
else
VisBitmapCreateScratchGString	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_CREATE_SCRATCH_GSTRING
	uses	cx
	.enter
	jcxz	useDefaultSize
gotSize:
	mov	ax, LMEM_TYPE_GENERAL
	call	MemAllocLMem
	mov	cl, GST_CHUNK
	call	GrCreateGString			; si = chunk handle
	mov	bp, di				;bp <- gstring handle
	mov	dx, bx				;dx <- mem handle

	.leave
	ret

useDefaultSize:
	mov	cx, DEFAULT_BITMAP_GSTRING_SIZE
	jmp	gotSize
VisBitmapCreateScratchGString	endm
endif

if	BITMAP_TEXT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapGetVTFBOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_GET_VTFB_OD

		Return the OD of this object's VisTextForBitmaps.
		If there is none, one is instantiated.

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		^lcx:dx - text OD

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetVTFBOD	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_GET_VTFB_OD

	.enter
	mov	cx, ds:[di].VBI_visText.handle
	jcxz	makeVTFB
	mov	dx, ds:[di].VBI_visText.chunk
done:
	.leave
	ret
makeVTFB:
	mov	ax, MSG_VIS_BITMAP_CREATE_VTFB
	call	ObjCallInstanceNoLock

	mov	si, ds:[si]
	add	si, ds:[si].VisBitmap_offset
	mov	ds:[si].VBI_visText.handle, cx
	mov	ds:[si].VBI_visText.offset, dx
	jmp	done
VisBitmapGetVTFBOD	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapPrepareVTFB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_PREPARE_VTFB

		Initialize the VisTextForBitmaps so we can begin using it

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance
		cx,dx = desired location of VTFB

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapPrepareVTFB	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_PREPARE_VTFB

	uses	cx, dx, bp

	.enter

	push	cx, dx, si				;save location,
							;VisBitmap chunk

	mov	bx, ds:[di].VBI_visText.handle
	mov	si, ds:[di].VBI_visText.chunk

	;
	;	Make the object neither drawable nor detectable.
	;
	mov	cx, (mask VA_DRAWABLE or mask VA_DETECTABLE) shl 8
	mov	dl, VUM_NOW
	mov	ax, MSG_VIS_SET_ATTRS
	call	ObjCallInstanceNoLock

	;
	;	Set the selection to the entire text
	;
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;	Erase the selection
	;
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, si				;cx,dx <- location,
							;si <- VisBitmap ptr

	;
	;	Now we'll move the VisTextForBitmaps object to the
	;	appropriate spot and resize it.
	;
	tst	cx
	jge	gotLeft
	clr	cx
gotLeft:
	tst	dx
	jge	gotTop
	clr	dx
gotTop:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	ax, ds:[di].VI_bounds.R_right		;save right coord
	sub	ax, ds:[di].VI_bounds.R_left		;of the bitmap
	push	ax
	mov	si, ds:[di].VBI_visText.chunk

	;
	;	Move the text object to the upper-left-hand corner of
	;	the user defined area
	;
	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;	Get the height of one line of text
	;
	push	cx, bp
	clr	dx
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	cx, bp

	pop	ax		;ax <- bitmap right
	sub	ax, cx		;ax <- width from text left to bitmap right

	cmp	bp, VIS_TEXT_FOR_BITMAPS_MIN_WIDTH
	jl	defaultWidth

	cmp	bp, ax
	jle	draggedIsWidth

defaultWidth:
	mov_tr	cx, ax
	jmp	gotSize

draggedIsWidth:
	mov	cx, bp
gotSize:
	mov	ax, MSG_VIS_SET_SIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_VTFB_APPEAR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
VisBitmapPrepareVTFB	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapBackupGStringToBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the last user edit from the temporary store space
		out into a bitmap.

CALLED BY:	VisBitmapWriteChanges, VisBitmapStartSelect, etc.

PASS:		bp = gstate of bitmap to draw to
		cx = gstate of gstring to draw
		
RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapBackupGStringToBitmap	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_BACKUP_GSTRING_TO_BITMAP
	.enter

 	mov	di, bp				;di <- bitmap's gstate handle
	mov	si, cx				;si <- gstring's gstate handle
	call	BitmapWriteGStringToBitmapCommon

	.leave
	ret
VisBitmapBackupGStringToBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapWriteGStringToBitmapCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		^hsi - gstring
		^hdi - gstate to bitmap

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 14, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapWriteGStringToBitmapCommon	proc	far
	uses	ax, dx
	.enter

	;
	;	Rewind the gstring so that we can draw from the beginning,
	;	and draw it.
	;
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos

	;
	;	Draw the string at 0,0 since it should be using
	;	bitmap coordinates.
	;
	mov	ax, mask BM_EDIT_MASK
	clr	dx
	call	GrSetBitmapMode
	test	ax, mask BM_EDIT_MASK
	jz	afterMask

	;
	;  We don't want the gstring to trash anything vital (like the
	;  path, for one), so protect ourselves here
	;
	call	GrSaveState

	;
	;  Draw to the mask
	;
	clr	ax, bx, dx
	call	BitmapDrawGStringToMask

	;
	;  Return the gstate to it's normal state
	;
	call	GrRestoreState

	clr	ax, dx
	call	GrSetBitmapMode

	;
	;	Rewind the gstring so that we can draw from the beginning,
	;	and draw it.
	;
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos

afterMask:
	;
	;  Draw to the bitmap
	;
	clr	ax, bx, dx
	call	GrDrawGString

	.leave
	ret
BitmapWriteGStringToBitmapCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapToolMouseManager
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handles mouse related requests from the tools

PASS:		ds:si 	= VisBitmapClass object
		ds:di 	= VisBitmapClass instance
		ds:bx   = instance data of superclass
		es	= segment of VisBitmapClass class record
		ax	= method number

		bp = VisBitmapMouseManagerRequestTypes


RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7/2/91 		Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapMouseManager	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_MOUSE_MANAGER

	.enter
	cmp	bp, VBMMRT_GRAB_MOUSE
	jne	checkReleaseMouse

	movdw	ds:[di].VBI_mouseGrab, ds:[di].VBI_tool, ax
	call	VisGrabMouse
done:
	.leave
	ret

checkReleaseMouse:
	cmp	bp, VBMMRT_RELEASE_MOUSE
	jne	sendAllPtrEvents

	clr	ax
	clrdw	ds:[di].VBI_mouseGrab, ax
	call	VisReleaseMouse
	jmp	done

sendAllPtrEvents:
EC<	cmp	bp, VBMMRT_SEND_ALL_PTR_EVENTS		>
EC<	ERROR_NE	BAD_MOUSE_MANAGER_REQUEST_TYPE	>
	jmp	done
VisBitmapMouseManager	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapNotifyGeometryValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_NOTIFY_GEOMETRY_VALID

		Inform the bitmap that its geometry is now valid. This
		method will allocate a bitmap the size of the vis bounds
		if none has been previously allocated.

Called by:	GLOBAL

Pass:		nothing

Return:		nothing

Destroyed:	ax, cx, dx, bp

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 13, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapNotifyGeometryValid	method dynamic	VisBitmapClass,
				MSG_VIS_NOTIFY_GEOMETRY_VALID

	.enter

	BitClr	ds:[di].VI_optFlags, VOF_GEOMETRY_INVALID

	;
	;	Check for the existence of a bitmap. If none exists,
	;	create one.
	;

	tst	ds:[di].VBI_mainKit.VBK_bitmap
	jnz	moveInsideVisBounds

	;
	;	We need to create a new bitmap.
	;	
	mov	ax, MSG_VIS_GET_SIZE
	call	ObjCallInstanceNoLock

	clr	bp					;no gstring
	mov	ax, MSG_VIS_BITMAP_CREATE_BITMAP
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

	;
	;	Bitmap already exists, so make sure that the new
	;	vis bounds are a sub-region of the bitmap bounds
	;
moveInsideVisBounds:
	clr	cx, dx					;align top left of
							;bitmap with top left
							;of vis bounds
	mov	ax, MSG_VIS_BITMAP_MOVE_INSIDE_VIS_BOUNDS
	call	ObjCallInstanceNoLock
	jmp	done
VisBitmapNotifyGeometryValid	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapDisplayInteractiveFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_EDIT_BITMAP

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		ss:[bp] - VisBitmapEditBitmapParams
			  (callbacks must be vfptr for XIP'ed geodes)

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapDisplayInteractiveFeedback	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_DISPLAY_INTERACTIVE_FEEDBACK
	uses	cx,dx
	.enter

	call	VisBitmapCheckFatbitsActive
	pushf

	mov	al, ds:[di].VBI_undoFlags
	mov	di, ds:[di].VBI_screenGState
	tst	di
	jz	afterScreen

	call	LoadParamsAndCallEditRoutine

afterScreen:
	popf
	jnc	done

	test	al, mask VBUF_EXPOSED_HAPPENING
	jnz	done

	;
	;  Get the proper gstate to edit
	;

	mov	di, bp					;ss:di <- params
	mov	ax, MSG_VIS_BITMAP_GET_INTERACTIVE_DISPLAY_GSTATE
	call	ObjCallInstanceNoLock
	xchg	di, bp					;ss:bp <- params
							;di <- gstate
	call	LoadParamsAndCallEditRoutine

	call	VisBitmapInvalFatbits

done:
	.leave
	ret
VisBitmapDisplayInteractiveFeedback	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapCheckFatbitsActive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Determines whether a fatbits window is active on this bitmap

Pass:		*ds:si - VisBitmap

Return:		carry set if fatbits window active

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 27, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapCheckFatbitsActive	proc	far
	class	VisBitmapClass
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	bx, ds:[di].VBI_fatbits.handle
	tst_clc	bx
	jz	done

if 0
	;
	;  See if the fatbits object is realized
	;
	mov	si, ds:[di].VBI_fatbits.offset
	mov	ax, MSG_VIS_GET_ATTRS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	test	cl, mask VA_REALIZED			;clears carry
	jz	done
endif
	stc

done:
	.leave
	ret
VisBitmapCheckFatbitsActive	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapGetInteractiveDisplayGstate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_GET_INTERACTIVE_DISPLAY_GSTATE

Called by:	MSG_VIS_BITMAP_GET_INTERACTIVE_DISPLAY_GSTATE

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		^hbp - gstate

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 26, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetInteractiveDisplayGState	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_GET_INTERACTIVE_DISPLAY_GSTATE
	.enter

	;
	;  If we have vardata, return that
	;

	clr	bp					;assume none
	mov	ax, ATTR_BITMAP_INTERACTIVE_DISPLAY_KIT
	call	ObjVarFindData
	jnc	useMain

	;
	;  We have a copied bitmap, so return it
	;

	mov	bp, ds:[bx].VBDK_gstate
	jmp	done

useMain:
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
VisBitmapGetInteractiveDisplayGState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapGetInteractiveDisplayBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_GET_INTERACTIVE_DISPLAY_Bitmap

Called by:	MSG_VIS_BITMAP_GET_INTERACTIVE_DISPLAY_BITMAP

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		cx - vm file handle
		dx - vm block handle

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 26, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapGetInteractiveDisplayBitmap	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_GET_INTERACTIVE_DISPLAY_BITMAP
	.enter

	;
	;  If we have vardata, return that
	;

	mov	ax, ATTR_BITMAP_INTERACTIVE_DISPLAY_KIT
	call	ObjVarFindData
	jnc	useMain

	;
	;  We have a copied bitmap, so return it
	;
	mov	dx, ds:[bx].VBDK_bitmap
	call	ClipboardGetClipboardFile
	mov	cx, bx
	jmp	done

useMain:
	;
	;  Simply return the main Bitmap
	;

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
VisBitmapGetInteractiveDisplayBitmap	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapInvalFatbits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Invalidates the fatbits object after scaling the rectangle
		by the resolution

Pass:		*ds:si - VisBitmap
		ss:bp - VisBitmapEditBitmapParams

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 10, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapInvalFatbits	proc	far
	class	VisBitmapClass
	uses	ax
	.enter

	mov	ax, MSG_VIS_FATBITS_INVALIDATE_RECTANGLE
	call	VisBitmapSendToVisFatbits

	.leave
	ret
VisBitmapInvalFatbits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapSendToVisFatbits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Invalidates the fatbits object after scaling the rectangle
		by the resolution

Pass:		*ds:si - VisBitmap
		ss:bp - VisBitmapEditBitmapParams

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 10, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapSendToVisFatbits	proc	far
	class	VisBitmapClass
	uses	bx, si, di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	bx, ds:[di].VBI_fatbits.handle
	jz	done

	mov	si, ds:[di].VBI_fatbits.chunk
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
VisBitmapSendToVisFatbits	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapEditBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_EDIT_BITMAP

Called by:	

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		ss:[bp] - VisBitmapEditBitmapParams
			  (callbacks must be vfptr for XIP'ed geodes)
Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapEditBitmap	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_EDIT_BITMAP
	uses	cx,dx,bp
	.enter

	push	ds:[di].VBI_editingKit.VBEK_gstring
	push	ds:[di].VBI_editingKit.VBEK_bitmap
	mov	di, ds:[di].VBI_editingKit.VBEK_screen

	mov	ax, MSG_VIS_BITMAP_MAKE_SURE_NO_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	call	LoadParamsAndCallEditRoutine

	pop	di
	tst	di
	jz	tryGString

	call	GrGetCurPos
	call	EditMaskCommon
	call	GrMoveTo

	call	LoadParamsAndCallEditRoutine

tryGString:
	pop	di
	tst	di
	jz	checkFatbits

if 0	;bitmap mode stuff doesn't work with gstring
	call	GrGetCurPos
 	push	ax, bx
endif
	call	LoadParamsAndCallEditRoutine

if 0	;bitmap mode stuff doesn't work with gstring

	mov	bx, ds:[si]
	add	bx, ds:[bx].VisBitmap_offset
	test	ds:[bx].VBI_undoFlags, mask VBUF_TRANSPARENT
	pop	ax, bx
	jz	checkFatbits

	call	GrMoveTo
	call	EditMaskCommon
endif

checkFatbits:

	call	VisBitmapInvalFatbits

	.leave
	ret
VisBitmapEditBitmap	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadParamsAndCallEditRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Loads ax,bx,cx,dx with the values and calls the routine
		found in the passed VisBitmapEditBitmapParams.

Pass:		^hdi - gstate to call the edit routine with
		ss:bp - VisBitmapEditBitmapParams

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep 16, 1992 	Initial version.
	sh	Apr 26, 1994	XIP'ed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadParamsAndCallEditRoutine	proc	near
	uses	ax, bx, cx, dx, bp, di, si, ds
	.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si					>
EC<	movdw	bxsi, ss:[bp].VBEBP_routine		>
EC<	call	ECAssertValidFarPointerXIP		>
EC<	pop	bx, si					>
endif

	mov	ax, ss:[bp].VBEBP_ax
	mov	bx, ss:[bp].VBEBP_bx
	mov	cx, ss:[bp].VBEBP_cx
	mov	dx, ss:[bp].VBEBP_dx

FXIP<	pushdw	ss:[bp].VBEBP_routine			>
FXIP<	call	PROCCALLFIXEDORMOVABLE_PASCAL		>
NOFXIP<	call	{dword} ss:[bp].VBEBP_routine		>

	.leave
	ret
LoadParamsAndCallEditRoutine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EditMaskCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		^hdi - bitmap gstate
		ss:bp - VisBitmapEditBitmapParams

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 28, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditMaskCommon	proc	near
	class	VisBitmapClass

	uses	ax, bx, dx
	.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si					>
EC<	movdw	bxsi, ss:[bp].VBEBP_routine		>
EC<	call	ECAssertValidFarPointerXIP		>
EC<	pop	bx, si					>
endif

	mov	ax, mask BM_EDIT_MASK
	clr	dx
	call	GrSetBitmapMode
	test	ax, mask BM_EDIT_MASK
	jz	done

if 0
	call	GrGetAreaColor
	push	ax, bx

	call	GrGetLineColor
	push	ax, bx

	mov	ax, ss:[bp].VBEBP_maskColor
	call	GrSetAreaColor
	call	GrSetLineColor
else

	call	GrGetMixMode
	push	ax

	mov	al, MM_SET
	cmp	ss:[bp].VBEBP_maskColor, C_WHITE
	jne	setMode
	mov	al, MM_CLEAR

setMode:
	call	GrSetMixMode
endif

	push	cx, bp, di, si, ds
	
	mov	ax, ss:[bp].VBEBP_ax
	mov	bx, ss:[bp].VBEBP_bx
	mov	cx, ss:[bp].VBEBP_cx
	mov	dx, ss:[bp].VBEBP_dx

if 0

FXIP<	pushdw	ss:[bp].VBEBP_maskRoutine		>
FXIP<	call	PROCCALLFIXEDORMOVABLE_PASCAL		>
NOFXIP<	call	{dword} ss:[bp].VBEBP_maskRoutine	>

else

FXIP<	pushdw	ss:[bp].VBEBP_routine			>
FXIP<	call	PROCCALLFIXEDORMOVABLE_PASCAL		>
NOFXIP<	call	{dword} ss:[bp].VBEBP_routine		>

endif

	pop	cx, bp, di, si, ds

	clr	ax, dx
	call	GrSetBitmapMode	

if 0
	pop	ax, bx
	mov	ah, CF_RGB
	call	GrSetLineColor

	pop	ax, bx
	mov	ah, CF_RGB
	call	GrSetAreaColor
endif
	pop	ax
	call	GrSetMixMode

done:
	.leave
	ret
EditMaskCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapVisBoundsMatchBitmapBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method: MSG_VIS_BITMAP_VIS_BOUNDS_MATCH_BITMAP_BOUNDS
		Sets the visual bounds to equal the bitmap's bounds

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax

Comments:	
		Maybe use MSG_VIS_NOTIFY_GEOMETRY_VALID at the end?

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapVisBoundsMatchBitmapBounds	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_VIS_BOUNDS_MATCH_BITMAP_BOUNDS
	uses	cx, dx
	.enter

	;
	;	Align the top,left vis bounds with top,left bitmap bounds
	;
	mov	ax, MSG_VIS_GET_POSITION
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	sub	cx, ds:[di].VBI_bitmapToVisHOffset
	sub	dx, ds:[di].VBI_bitmapToVisVOffset

	mov	ax, MSG_VIS_SET_POSITION
	call	ObjCallInstanceNoLock

	;
	;	Zero the offsets, since we are now aligned
	;
	clr	ax
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_bitmapToVisHOffset, ax
	mov	ds:[di].VBI_bitmapToVisVOffset, ax
		
	;
	;	Set the vis size = bitmap size
	;
	mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_POINTS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_BITMAP_DESTROY_SCREEN_GSTATE
	call	ObjCallInstanceNoLock

	.leave
	ret
VisBitmapVisBoundsMatchBitmapBounds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapDestroyScreenGstate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_DESTROY_SCREEN_GSTATE

Called by:	MSG_VIS_BITMAP_DESTROY_SCREEN_GSTATE

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 11, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapDestroyScreenGstate	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_DESTROY_SCREEN_GSTATE
	uses	cx
	.enter

	;
	;  Clean up anything we may have been using the gstate for
	;
	mov	ax, MSG_VIS_BITMAP_FORCE_CURRENT_EDIT_TO_FINISH
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_BITMAP_KILL_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	;
	;  Nuke it!
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	cx
	xchg	cx, ds:[di].VBI_screenGState
	jcxz	done
	mov	di, cx
	call	GrDestroyState

done:
	.leave
	ret
VisBitmapDestroyScreenGstate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapBitmapBoundsMatchVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_BITMAP_BOUNDS_MATCH_VIS_BOUNDS

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapBitmapBoundsMatchVisBounds	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_BITMAP_BOUNDS_MATCH_VIS_BOUNDS

newBounds	local	RectAndGState

	uses	cx, dx
	.enter

	mov	ax, MSG_VIS_GET_SIZE
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ax, ds:[di].VBI_bitmapToVisHOffset
	mov	ss:newBounds.RAG_rect.R_left, ax	
	add	ax, cx
	mov	ss:newBounds.RAG_rect.R_right, ax

	mov	ax, ds:[di].VBI_bitmapToVisVOffset
	mov	ss:newBounds.RAG_rect.R_top, ax
	add	ax, dx
	mov	ss:newBounds.RAG_rect.R_bottom, ax

	clr	ss:newBounds.RAG_gstate

	push	bp
	lea	bp, ss:newBounds
	mov	ax, MSG_VIS_BITMAP_RESIZE_REAL_ESTATE
	call	ObjCallInstanceNoLock
	pop	bp

	;
	;	Zero the offsets, since we are now aligned
	;
	clr	ax
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_bitmapToVisHOffset, ax
	mov	ds:[di].VBI_bitmapToVisVOffset, ax
		
	;    Destroy gstate so that a new one will get 
	;    created with the proper clip rect

	mov	ax, MSG_VIS_BITMAP_DESTROY_SCREEN_GSTATE
	call	ObjCallInstanceNoLock

	.leave
	ret
VisBitmapBitmapBoundsMatchVisBounds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapBitmapBecomeDormant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_BITMAP_BOUNDS_MATCH_VIS_BOUNDS

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapBecomeDormant	method dynamic	VisBitmapClass,
			MSG_VIS_BITMAP_BECOME_DORMANT
	uses	cx, dx, bp
	.enter

	;
	;  A bunch of instance data gets zeroed below, so make sure
	;  we get marked dirty.
	;

	mov	ax, MSG_VIS_BITMAP_FORCE_CURRENT_EDIT_TO_FINISH
	call	ObjCallInstanceNoLock

	;
	;  Free the backup thread here
	;

	call	VisBitmapDetachBackupThread

	mov	ax, MSG_VIS_BITMAP_KILL_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	;
	;  Kill fatbits window
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisFatbits_offset
	mov	bx, ds:[di].VBI_fatbitsWindow.handle
	tst	bx
	jz	afterFatbits

	push	si					;save bitmap chunk

	pushdw	ds:[di].VBI_fatbits			;save fatbits OD
	mov	si, ds:[di].VBI_fatbitsWindow.chunk
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	;
	;  Remove the window from the application
	;

	movdw	cxdx, bxsi				;^lcx:dx <- window
	clr	bx
	call	GeodeGetAppObject

	pushdw	cxdx
	mov	ax, MSG_GEN_REMOVE_CHILD
	clr	bp					;don't mark dirty
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	popdw	bxsi

	;
	;  Nuke the objects
	;

	mov	ax, MSG_META_BLOCK_FREE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;  Nuke the fatbits, too
	;

	popdw	bxsi
	mov	ax, MSG_META_BLOCK_FREE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	ax
	clrdw	ds:[di].VBI_fatbitsWindow
	clrdw	ds:[di].VBI_fatbits

afterFatbits:
	call	VisBitmapGetLastEdit
	jcxz	freeBackupBitmap

	push	si
	mov	si, cx
	clr	di
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString
	pop	si

freeBackupBitmap:

	call	DestroyBackupBitmap

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	cx
	xchg	cx, ds:[di].VBI_mainKit.VBK_gstate
	jcxz	afterMainGState

	mov	di, cx
	call	GrDestroyState
	
afterMainGState:
	mov	ax, MSG_VIS_BITMAP_DESTROY_SCREEN_GSTATE
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	cx
	xchg	cx, ds:[di].VBI_transferGString
	jcxz	afterTransferGString

	xchg	cx, si
	clr	di
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString
	mov	si, cx

afterTransferGString:
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	cx
	xchg	cx, ds:[di].VBI_transferBitmap
	jcxz	afterTransferBitmap

	call	ClipboardGetClipboardFile		;bx <- VM file
	mov_tr	ax, cx
	push	bp
	clr	bp
	call	VMFreeVMChain
	pop	bp

afterTransferBitmap:

if 0	;causes death if you free an object in a document

	;
	;  Free the tool
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	bx
	xchg	bx, ds:[di].VBI_tool.handle
	tst	bx
	jz	afterTool
	push	si
	mov	si, ds:[di].VBI_tool.chunk
	mov	ax, MSG_META_OBJ_FREE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

afterTool:
endif
	;
	;  Compact the bitmap
	;
	mov	ax, ATTR_BITMAP_DO_NOT_COMPACT_BITMAP
	call	ObjVarFindData
	jc	done		

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock

	tst	dx
	jz	done
	
	movdw	bxax, cxdx

	call	CheckHugeArrayBitmapCompaction
	jne	done				;already compacted
	jnc	done				;dont compact

	mov	dx, cx				;dx <- destination VM file
	call	GrCompactBitmap			;dx:cx <- compacted bitmap

	clr	bp
	call	VMFreeVMChain			;free the uncompacted bitmap

	call	ObjMarkDirty			;be certain to dirty the sucker
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	ds:[di].VBI_mainKit.VBK_bitmap, cx

done:
	.leave
	ret
VisBitmapBecomeDormant	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapDetachBackupThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Send the VisBitmap's backup thread a MSG_META_DETACH

Pass:		*ds:si - VisBitmap

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapDetachBackupThread	proc	far
	class	VisBitmapClass
	uses	ax, bx, cx, dx, bp, di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	clr	bx
	xchg	bx, ds:[di].VBI_backupThread
	tst	bx
	jz	done
	mov	ax, MSG_META_DETACH
	clr	cx, dx, bp
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

done:
	.leave
	ret
VisBitmapDetachBackupThread	endp

BitmapEditCode		ends		;end of CommonCode resource

BitmapObscureEditCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapDoThatCrazyRemappingThing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisBitmap
		ss:[bp] - RectAndGState

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 22, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapDoThatCrazyRemappingThing	proc	far
	class	VisBitmapClass
	uses	ax, bx, cx, dx, di, bp
	.enter

	call	ObjMarkDirty

	;
	;  Tidy up things a bit
	;

	mov	ax, MSG_VIS_BITMAP_FORCE_CURRENT_EDIT_TO_FINISH
	call	ObjCallInstanceNoLock

	;
	;	Free the backup bitmap, if any
	;

	call	DestroyBackupBitmap

	;
	;  Nuke the cached screen gstate, as it'll no longer be any good
	;

	mov	ax, MSG_VIS_BITMAP_DESTROY_SCREEN_GSTATE
	call	ObjCallInstanceNoLock

	mov	cx, ss:[bp].RAG_rect.R_right
	sub	cx, ss:[bp].RAG_rect.R_left
	mov	dx, ss:[bp].RAG_rect.R_bottom
	sub	dx, ss:[bp].RAG_rect.R_top

	clr	bx					;use default file
	call	CreateBitmapCommon

	mov_tr	bx,ax					;bx <- vm block handle

	;
	;	Draw the original into the new one
	;
	push	bp					;save local ptr

	;    
	;    Coordinates in the new bitmap to draw the old one at
	;
	mov	cx, ss:[bp].RAG_rect.R_left
	neg	cx
	mov	dx, ss:[bp].RAG_rect.R_top
	neg	dx

	mov	ax, ss:[bp].RAG_gstate
	push	ax
	tst	ax
	jz	oldToNew

	;
	;	Copy transform of passed gstate to new gstate
	;
	xchg	ax,cx					;x trans, gstate
	call	GrSaveState				;save new transform
	call	BitmapCopyTransform
	clr	cx, dx					;coords = 0
oldToNew:
	mov	bp, di					;bp <- new gstate
	mov	ax, MSG_VIS_BITMAP_DRAW_BITMAP_TO_GSTATE
	call	ObjCallInstanceNoLock

	push	dx
	mov	ax, mask BM_EDIT_MASK
	clr	dx
	call	GrSetBitmapMode
	test	ax, mask BM_EDIT_MASK
	pop	dx
	jz	afterCopy

	mov	al, MM_SET
	call	GrSetMixMode

	mov	ax, MSG_VIS_BITMAP_DRAW_BITMAP_TO_GSTATE
	call	ObjCallInstanceNoLock

	mov	al, MM_COPY
	call	GrSetMixMode

	clr	ax, dx
	call	GrSetBitmapMode

afterCopy:

	;
	;  Clear the scale factor here
	;
	call	HackAroundWinScale

	pop	cx
	jcxz	afterRestoreState

	call	GrRestoreState

afterRestoreState:
	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset

	xchg	ds:[bp].VBI_mainKit.VBK_bitmap, bx
	xchg	di, ds:[bp].VBI_mainKit.VBK_gstate	;di <- old gstate

	tst	di
	jz	noGState

	mov	al, BMD_KILL_DATA
	call	GrDestroyBitmap
	jmp	checkBackup

noGState:
	tst	bx
	jz	checkBackup

	mov	ax, MSG_VIS_BITMAP_GET_VM_FILE
	call	ObjCallInstanceNoLock

	xchg	ax, bx					;bx <- vm file
							;ax <- vm block handle
	clr	bp
	call	VMFreeVMChain

checkBackup:

	pop	bp					;bp <- local ptr

if 0	; let the backup bitmap be allocated when necessary

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	test	ds:[di].VBI_undoFlags, mask VBUF_USES_BACKUP_BITMAP
	jz	done

	;
	;  Make a copy for the backup bitmap
	;

	mov	ax, MSG_VIS_BITMAP_CREATE_BACKUP_BITMAP
	call	ObjCallInstanceNoLock
done:
endif
	.leave
	ret
VisBitmapDoThatCrazyRemappingThing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyBackupBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Frees the back up bitmap, if any, and the associated
		gstate, if any

Pass:		*ds:si - VisBitmap

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar  9, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyBackupBitmap	proc	far
	class	VisBitmapClass
	uses	ax, bx, cx, dx, bp, di
	.enter

	;
	;  Nuke the backup thread
	;
	call	VisBitmapDetachBackupThread

	;
	;  Free the bitmap
	;
	mov	di,ds:[si]
	add	di,ds:[di].VisBitmap_offset
	clr	cx
	xchg	cx, ds:[di].VBI_backupKit.VBK_bitmap
	jcxz	done

	clr	dx
	xchg	dx, ds:[di].VBI_backupKit.VBK_gstate
	tst	dx
	jz	freeVM

	mov	di, dx
	mov	al, BMD_KILL_DATA
	call	GrDestroyBitmap

done:
	.leave
	ret

freeVM:
	call	ClipboardGetClipboardFile		;bx <- VM file
	mov_tr	ax, cx
	clr	bp
	call	VMFreeVMChain
	call	VMUpdate		; update on disk (hopefully truncate
					;	as small as possible)
					; ignore error
	jmp	done
DestroyBackupBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapMoveInsideVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_MOVE_INSIDE_VIS_BOUNDS

		Move the bitmap around inside its vis bounds. If any area in
		the bitmaps coordinates outside the bitmap is exposed, the
		bitmap is expanded.

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		cx = horizontal amount to move relative to vis bounds
		dx = vertical amount to move relative to vis bounds

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 12, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapMoveInsideVisBounds	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_MOVE_INSIDE_VIS_BOUNDS
	uses	cx, dx
newBitmapBounds		local	RectAndGState
	.enter

	clr	ax, newBitmapBounds.RAG_rect.R_left, newBitmapBounds.RAG_rect.R_top

	;
	;	Move the bitmap within the vis bounds
	;
	sub	ds:[di].VBI_bitmapToVisHOffset, cx
	sub	ds:[di].VBI_bitmapToVisVOffset, dx

	;
	;	If the geometry is invalid then just bail
	;
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	jnz	done

	;
	;	If left edge of the bitmap moved to the right of the vis left,
	;	then we have to allocate more bitmap to the left
	;    
	tst	ds:[di].VBI_bitmapToVisHOffset
	jns	checkVertical
	xchg	ax, ds:[di].VBI_bitmapToVisHOffset
	mov	ss:newBitmapBounds.RAG_rect.R_left, ax
	clr	ax

checkVertical:
	;
	;	If top edge of the bitmap moved above of the vis top,
	;	then we have to allocate more bitmap on the top
	;    
	tst	ds:[di].VBI_bitmapToVisVOffset
	jns	compareDimensions
	xchg	ax, ds:[di].VBI_bitmapToVisVOffset
	mov	ss:newBitmapBounds.RAG_rect.R_top, ax

compareDimensions:
	;
	;	Get the size of the bitmap
	;
	mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_POINTS
	call	ObjCallInstanceNoLock

	mov	newBitmapBounds.RAG_rect.R_right, cx
	mov	newBitmapBounds.RAG_rect.R_bottom, dx

	;
	;	Get the visual size
	;
	mov	ax, MSG_VIS_GET_SIZE
	call	ObjCallInstanceNoLock

	;
	;	We want to make sure that the vis bounds + the bitmap<->vis
	;	offset do not extend beyond the bitmap edges
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].VisBitmap_offset
	add	cx, ds:[bx].VBI_bitmapToVisHOffset	;cx <- right vis bound
							;      in bitmap coords
	add	dx, ds:[bx].VBI_bitmapToVisVOffset	;dx <- bottom vis bound
							;      in bitmap coords
	;
	;	Compare bitmap and vis bottoms
	;
	
	add	dx, newBitmapBounds.RAG_rect.R_top
	cmp	dx, newBitmapBounds.RAG_rect.R_bottom
	jle	checkRightEdge

	mov	newBitmapBounds.RAG_rect.R_bottom, dx
	;
	;	Compare bitmap and vis rights. If vis right > bitmap right,
	;	then we need to resize.
	;
checkRightEdge:
	add	cx, newBitmapBounds.RAG_rect.R_left
	cmp	cx, newBitmapBounds.RAG_rect.R_right
	jle	resize

	mov	newBitmapBounds.RAG_rect.R_right, cx

resize:
	clr	ss:newBitmapBounds.RAG_gstate
	push	bp					;save local ptr
	lea	bp, ss:newBitmapBounds
	mov	ax, MSG_VIS_BITMAP_RESIZE_REAL_ESTATE
	call	ObjCallInstanceNoLock
	pop	bp					;bp <- local ptr

	;    Destroy screen gstate so that a new one will get 
	;    created with the proper clip rect

	mov	ax, MSG_VIS_BITMAP_DESTROY_SCREEN_GSTATE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
VisBitmapMoveInsideVisBounds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapContort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_CONTORT

		(For lack of a better name) this method takes an arbitrary
		gstate and translates the bitmap through it. It resizes
		itself to accomodate any size changes that may occur as
		a result.

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance
		bp - GState to contort through

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 17, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapContort	method dynamic	VisBitmapClass, MSG_VIS_BITMAP_CONTORT

utilPoint			local	PointDWFixed
transformedPoints		local	FourPointDWFixeds
transformedRectDWF		local	RectDWFixed
transformedRAG			local	RectAndGState

	uses	cx, dx
	.enter

	mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_POINTS
	call	ObjCallInstanceNoLock
	mov_tr	ax,dx				;pixel height
	mov	di, ss:[bp]			;di <- passed gstate

	segmov	es, ss
	lea	dx, ss:utilPoint

	;
	;	Do top left point
	;
	call	ClearUtilPoint
	call	GrTransformDWFixed

	movdwf	transformedPoints.FPDF_TL.PDF_x, utilPoint.PDF_x, bx
	movdwf	transformedPoints.FPDF_TL.PDF_y, utilPoint.PDF_y, bx

	;
	;	Do top right point
	;
	call	ClearUtilPoint
	mov	utilPoint.PDF_x.DWF_int.low, cx
	call	GrTransformDWFixed

	movdwf	transformedPoints.FPDF_TR.PDF_x, utilPoint.PDF_x, bx
	movdwf	transformedPoints.FPDF_TR.PDF_y, utilPoint.PDF_y, bx

	;
	;	Do bottom right point
	;
	call	ClearUtilPoint
	mov	utilPoint.PDF_x.DWF_int.low, cx
	mov	utilPoint.PDF_y.DWF_int.low, ax
	call	GrTransformDWFixed

	movdwf	transformedPoints.FPDF_BR.PDF_x, utilPoint.PDF_x, bx
	movdwf	transformedPoints.FPDF_BR.PDF_y, utilPoint.PDF_y, bx

	;
	;	Do bottom left point
	;
	call	ClearUtilPoint
	mov	utilPoint.PDF_y.DWF_int.low, ax
	call	GrTransformDWFixed

	movdwf	transformedPoints.FPDF_BL.PDF_x, utilPoint.PDF_x, bx
	movdwf	transformedPoints.FPDF_BL.PDF_y, utilPoint.PDF_y, bx

	;
	;	Calculate the bounding rectangle of our weird transformed
	;	rectangle
	;
	push	ds, si
	segmov	ds, ss
	lea	si, transformedRectDWF
	lea	di, transformedPoints
	call	BitmapSetRectDWFixedFromFourPointDWFixeds
	pop	ds, si

	mov	ax, transformedRectDWF.RDWF_left.DWF_int.low
	tst	transformedRectDWF.RDWF_left.DWF_frac
	jns	$10
	inc	ax	
$10:
	mov	transformedRAG.RAG_rect.R_left, ax
	mov	ax, transformedRectDWF.RDWF_right.DWF_int.low
	tst	transformedRectDWF.RDWF_right.DWF_frac
	jns	$20
	inc	ax	
$20:
	mov	transformedRAG.RAG_rect.R_right, ax
	mov	ax, transformedRectDWF.RDWF_top.DWF_int.low
	tst	transformedRectDWF.RDWF_top.DWF_frac
	jns	$30
	inc	ax	
$30:
	mov	transformedRAG.RAG_rect.R_top, ax
	mov	ax, transformedRectDWF.RDWF_bottom.DWF_int.low
	tst	transformedRectDWF.RDWF_bottom.DWF_frac
	jns	$40
	inc	ax	
$40:
	mov	transformedRAG.RAG_rect.R_bottom, ax

	mov	ax, ss:[bp]				;ax <- passed gstate
	mov	transformedRAG.RAG_gstate, ax
	push	bp
	lea	bp, transformedRAG
	mov	ax, MSG_VIS_BITMAP_RESIZE_REAL_ESTATE
	call	ObjCallInstanceNoLock
	pop	bp

	.leave
	ret
VisBitmapContort	endm

ClearUtilPoint	proc	near
	.enter inherit VisBitmapContort

	clr	bx
	clrdwf	utilPoint.PDF_x, bx
	clrdwf	utilPoint.PDF_y, bx

	.leave
	ret
ClearUtilPoint	endp




	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapInitRectDWFixedWithPointDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the top,left and bottom, right of the
		RectDWFixed to the passed PointDWFixed

CALLED BY:	internal

PASS:		
		ds:si - RectDWFixed
		es:di - PointDWFixed

RETURN:		
		ds:si - RectDWFixed - initialized

DESTROYED:	
		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapInitRectDWFixedWithPointDWFixed		proc	far
	uses	cx,di,si,ds,es
	.enter

	push	ds				;Rect seg
	push	es				;Point seg
	pop	ds				;Source seg
	pop	es				;Dest seg
	xchg	di,si				;di <- dest offset
						;si <- source offset

	;    Copy point to left,top
	;

	mov	cx,size PointDWFixed/2
	rep	movsw

	;    Copy point to right, bottom

	sub	si,size PointDWFixed		;source offset
	mov	cx,size PointDWFixed/2
	rep	movsw

	.leave
	ret
BitmapInitRectDWFixedWithPointDWFixed		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapCombineRectDWFixedWithPointDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increase size of RectDWFixed to include the passed point

CALLED BY:	internal

PASS:		
		ds:si - Ordered RectDWFixed
		es:di - PointDWFixed

RETURN:		
		RectDWFixed potentially expanded

DESTROYED:	
		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapCombineRectDWFixedWithPointDWFixed		proc	far
	uses	ax,bx,cx
	.enter

	;    If x of point is less than left of rect, then jump to set
	;    new left
	;

	movdwf	cxbxax,es:[di].PDF_x
	jldwf	cxbxax, ds:[si].RDWF_left, newLeft


	;    If x of point is greater than right of rect, then jump to set
	;    new right
	;
	jgdwf	cxbxax, ds:[si].RDWF_right, newRight

checkTopBottom:
	;    If y of point is less than top of rect, then jump to set
	;    new top
	;

	movdwf	cxbxax,es:[di].PDF_y
	jldwf	cxbxax,ds:[si].RDWF_top, newTop

	;    If y of point is greater than bottom of rect, then jump to set
	;    new bottom
	;

	jgdwf	cxbxax,ds:[si].RDWF_bottom, newBottom

done:
	.leave
	ret

newLeft:
	movdwf	ds:[si].RDWF_left,cxbxax
	jmp	checkTopBottom

newRight:
	movdwf	ds:[si].RDWF_right,cxbxax
	jmp	checkTopBottom

newTop:
	movdwf	ds:[si].RDWF_top,cxbxax
	jmp	done

newBottom:
	movdwf	ds:[si].RDWF_bottom,cxbxax
	jmp	done


BitmapCombineRectDWFixedWithPointDWFixed		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapSetRectDWFixedFromFourPointDWFixeds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the RectDWFixed to surround the all the points
		in the FourPointDWFixeds structure

CALLED BY:	internal

PASS:		
		ds:si - RectDWFixed
		es:di - FourPointDWFixeds

RETURN:		
		ds:si - RectDWFixed

DESTROYED:	
		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapSetRectDWFixedFromFourPointDWFixeds		proc	far
	.enter

	call	BitmapInitRectDWFixedWithPointDWFixed

	add	di,size PointDWFixed
	call	BitmapCombineRectDWFixedWithPointDWFixed
	add	di,size PointDWFixed
	call	BitmapCombineRectDWFixedWithPointDWFixed
	add	di,size PointDWFixed
	call	BitmapCombineRectDWFixedWithPointDWFixed

	.leave
	ret
BitmapSetRectDWFixedFromFourPointDWFixeds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapInitiateFatbits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_INITIATE_FATBITS

Called by:	MSG_VIS_BITMAP_INITIATE_FATBITS

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		cx,dx - location to spawn fatbits about
		bp - ImageBitSize

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapInitiateFatbits	method dynamic	VisBitmapClass,
				MSG_VIS_BITMAP_INITIATE_FATBITS
	uses	cx,dx,bp
	.enter

	push	cx, dx, bp			;save location, ImageBitSize

	tst	ds:[di].VBI_fatbits.handle
	LONG	jnz	haveFatbits

	;
	;  If ants exist, they aren't being drawn to the bitmap yet,
	;  since there's no reason to do that if there aren't fatbits.
	;  Starting to draw the ants this late without halting them momentarily
	;  will screw 'em up, and you'll get greebles in your bitmap
	;

	;
	;  I'm doing a kill and then a spawn instead of a "make sure no"
	;  so that the duplicate bitmap will be created -jon 3/26/93
	;

	;
	;  Only want to restart ants if we had 'em to begin with
	;
	tst	ds:[di].VBI_antTimer
	pushf

	mov	ax, MSG_VIS_BITMAP_KILL_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	push	si				;save VisFatbits chunk

	;
	;  Get the app obj
	;
	clr	bx
	call	GeodeGetAppObject

	push	bx, si				;save app obj

	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo
	mov_tr	cx, ax				;cx <- exec thread
	mov	bx, handle FatbitsInteractionAndViewTemplate
	clr	ax
	call	ObjDuplicateResource

	mov	cx, bx
	mov	dx, offset FatbitsWindow
	mov	bp, CCO_LAST

	pop	bx, si				;^lbx:si <- app obj

	mov	ax, MSG_GEN_ADD_CHILD
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	push	cx				;save view handle

	mov	bx, handle FatbitsAndContentTemplate
	clr	ax, cx
	call	ObjDuplicateResource

	mov	cx, bx
	mov	dx, offset FatbitsContent

	pop	bx
	mov	si, offset FatbitsView
	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	si, offset FatbitsWindow
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si				;*ds:si <- VisFatbits
	mov	di, ds:[si]
	add	di, ds:[di].VisFatbits_offset
	mov	ds:[di].VBI_fatbits.handle, cx
	mov	ds:[di].VBI_fatbits.chunk, offset MrFatbits
	mov	ds:[di].VBI_fatbitsWindow.handle, bx
	mov	ds:[di].VBI_fatbitsWindow.chunk, offset FatbitsWindow

	popf
	jz	haveFatbits

	;
	;  Start the ants up again since we nuked 'em before
	;

	mov	ax, MSG_VIS_BITMAP_SPAWN_SELECTION_ANTS
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset

haveFatbits:
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	movdw	bxsi, ds:[di].VBI_fatbits
	mov	ax, MSG_VIS_FATBITS_SET_VIS_BITMAP
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov_tr	ax, dx				;ax <- VisBitmap chunk handle
	pop	cx, dx, bp			;restore location, ImageBitSize
	push	ax				;save VisBitmap chunk handle
	mov	ax, MSG_VIS_FATBITS_SET_IMPORTANT_LOCATION_AND_IMAGE_BIT_SIZE
 	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si				;*ds:si <- VisBitmap
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	movdw	bxsi, ds:[di].VBI_fatbitsWindow
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
VisBitmapInitiateFatbits	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_META_FINAL_OBJ_FREE

Called by:	MSG_META_FINAL_OBJ_FREE

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapFinalObjFree	method dynamic	VisBitmapClass, MSG_META_FINAL_OBJ_FREE

	.enter

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock

	tst	dx
	jz	callSuper

	mov	bx, cx
	mov_tr	ax, dx
	clr	bp
	call	VMFreeVMChain

callSuper:
	mov	di, offset VisBitmapClass
	mov	ax, MSG_META_FINAL_OBJ_FREE

	.leave
	GOTO	ObjGotoSuperTailRecurse
VisBitmapFinalObjFree	endm

BitmapObscureEditCode	ends
