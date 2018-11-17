COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS - Bitmap edit object
MODULE:		VisBitmap edit object
FILE:		bitmapUndo.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	December 1992	Initial revision

DESCRIPTION:	Handle the "undo" stuff for the VisBitmapObject

	$Id: bitmapUndo.asm,v 1.1 97/04/04 17:43:48 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapObscureEditCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmap method for MSG_VIS_BITMAP_UNDO
		Undo the last edit made to the bitmap

Called by:	GLOBAL

Pass:		*ds:si = VisBitmap object
		ds:di = VisBitmap instance

		ss:[bp] - UndoActionStruct

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapUndo	method dynamic	VisBitmapClass, MSG_META_UNDO

	uses	cx, dx, bp
	.enter
	
	;
	;	If VisBitmap isn't VBUF_UNDOABLE, then ignore
	;
	test	ds:[di].VBI_undoFlags, mask VBUF_UNDOABLE
	jz	done

	;
	;	If we've logged multiple actions, then skip all but one
	;
	tst	ss:[bp].UAS_data.UADU_flags.UADF_flags.high
	jz	doItNow

done:
	.leave
	ret

undoTheUndo:
	mov	ax, ds:[di].VBI_lastEdit
	tst	ax
	jz	done

	push	ax					;save gstring
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock
	pop	ax					;ax <- last edit

	mov	di, bp			;di <- main bitmap handle
	push	si			;save object ptr
	mov_tr	si, ax		;si <- gstring handle

	;
	;	*DON'T* send MSG_BACKUP_GSTRING_TO_BITMAP in place of the
	;	following code, as your gstring will be GrDestroyGString'ed
	;	and will make further dual undo impossible.
	;

	call	BitmapWriteGStringToBitmapCommon
	pop	si				;*ds:si <- VisBitmap

	call	BitmapAddUndoAction
	jmp	startAnts

doItNow:
	mov	cx, handle BitmapUndoStrings
	mov	dx, offset undoPaintingString
	call	BitmapStartUndoChain

if 0
	;
	;  We only want to replace the path here if there was one to begin
	;  with, otherwise you get wierd paths coming back from long ago.
	;  We need to record whether a path exists before sending
	;  MSG_VIS_BITMAP_REPLACE_WITH_TRANSFER_FORMAT, which will nuke
	;  the path.
	;

	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock

	tst	bp				;no gstate, no path
	stc					;assume no path
	pushf
	jz	writeTransfer
	popf

	mov	di, bp				;bx <- main gstate
	mov	ax, GPT_CURRENT
	call	GrTestPath
	pushf					;carry set if no path
else
	;
	;  ACTUALLY, I think we're going to test for the existence of
	;  the transfer gstring instead. -jon
	;

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset

	mov	ax, ss:[bp].UAS_data.UADU_flags.UADF_flags.low
	and	ax, mask VBUF_HAD_SELECTION_BEFORE_LAST_ACTION
	or	ax, ds:[di].VBI_transferGString
	or	ax, ds:[di].VBI_antTimer
	pushf
endif

if	0
writeTransfer:
endif

if 1
	call	WriteTransferGStringIfAny
endif

	mov	ax, MSG_VIS_BITMAP_FORCE_CURRENT_EDIT_TO_FINISH
	call	ObjCallInstanceNoLock

	;
	;	Force the backup thread to finish everything it's doing
	;

	call	VisBitmapDetachBackupThread

	;
	;	toggle the VBUF_LAST_EDIT_UNDONE bit to undo the last edit
	;	(accounts for undo the undo)
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	xornf	ds:[di].VBI_undoFlags, mask VBUF_LAST_EDIT_UNDONE

	;
	;	If we don't have a backup bitmap, then just invalidate
	;	ourself to show the new state of affairs
	;
	mov	ax, MSG_VIS_BITMAP_GET_BACKUP_BITMAP
	call	ObjCallInstanceNoLock
	pop	ax					;ax <- path? flag
	tst	dx
	jz	inval

	;
	;	We do have a backup bitmap: now there are 2 courses of action:
	;
	;	1 -	If the edit is being undone, then copy the backup
	;		bitmap to the main bitmap
	;
	;	2 -	If the edit is being reinstated (undo the undo), then
	;		we need to draw the gstring to the bitmap
	;

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	test	ds:[di].VBI_undoFlags, mask VBUF_LAST_EDIT_UNDONE
	jz	undoTheUndo

	push	ax					;save path flag

	mov	ax, MSG_VIS_BITMAP_REPLACE_WITH_TRANSFER_FORMAT
	call	ObjCallInstanceNoLock

	call	BitmapAddUndoAction

if 0
	popf					;carry set if no path
	jc	inval
else
	popf					;Z set if no transfer gstring
	jz	inval
endif

	;
	;  Will probably need to fix up path hooey in the main bitmap
	;  here since it got nuked in the replace deal.
	;  Also think about transfer gstring
	;

	mov	ax, MSG_VIS_BITMAP_GET_BACKUP_GSTATE
	call	ObjCallInstanceNoLock
	tst	bp				;no gstate, no path
	jz	inval

	;
	;  Let's see if the backup gstate has a path to copy
	;
	mov	di, bp				;bx <- backup gstate
	mov	ax, GPT_CURRENT
if 1
	call	GrTestPath
else
	call	GrGetPathBounds
endif
	jc	inval

	mov	bx, di				;bx <- gstate
	clr	cx, dx				;copy path at offset 0,0

	;
	;  Set the path in the main bitmap's gstate
	;
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjCallInstanceNoLock
	tst	bp
	jz	tryScreen

	mov	di, bp				;di <- main gstate
	call	CopyPath

tryScreen:
	;
	;  Set the path in the screen gstate
	;
	mov	ax, MSG_VIS_BITMAP_GET_SCREEN_GSTATE
	call	ObjCallInstanceNoLock
	tst	bp
	jz	startAnts

	mov	di, bp				;di <- screen gstate
	call	CopyPath

startAnts:
	mov	ax, MSG_VIS_BITMAP_SPAWN_SELECTION_ANTS
	call	ObjCallInstanceNoLock

inval:

	call	BitmapEndUndoChain

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_INVALIDATE
	call	VisBitmapSendToVisFatbits

	mov	ax, MSG_VIS_BITMAP_NOTIFY_SELECT_STATE_CHANGE
	call	ObjCallInstanceNoLock
	jmp	done
VisBitmapUndo	endm

BitmapObscureEditCode	ends

BitmapBasicCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapAddUndoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an action to an existing undo chain

CALLED BY:	UTILITY (BitmapInitUndo)

PASS:		ax - UndoType
		*ds:si - VisBitmap

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapAddUndoAction	proc far
	uses	ax,bx,dx,di,bp
	class	VisBitmapClass 
	.enter

	call	CheckIfIgnoring
	jc	done

	;
	;  Inc the undo depth
	;

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	tst	ds:[di].VBI_undoDepth
	jz	done
	mov	cx, ds:[di].VBI_nUndoActions
	inc	ds:[di].VBI_nUndoActions
	mov	al, ds:[di].VBI_undoFlags
	sub	sp,size AddUndoActionStruct
	mov	bp, sp

	mov	ss:[bp].AUAS_data.UAS_dataType, UADT_FLAGS
	mov	ss:[bp].AUAS_data.UAS_data.UADU_flags.UADF_flags.low, ax
	mov	ss:[bp].AUAS_data.UAS_data.UADU_flags.UADF_flags.high, cx
	mov	ss:[bp].AUAS_flags, 0	;mask AUAF_NOTIFY_BEFORE_FREEING
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[bp].AUAS_output, axsi

	mov	dx, size AddUndoActionStruct
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	GeodeGetProcessHandle
	mov	ax, MSG_GEN_PROCESS_UNDO_ADD_ACTION
	call	ObjMessage

	add	sp, size AddUndoActionStruct	
done:
	.leave
	ret
BitmapAddUndoAction	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfIgnoring
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the process is ignoring UNDO

CALLED BY:	BitmapStartUndoChain, BitmapAddUndoAction,
		BitmapEndUndoChain

PASS:		nothing 

RETURN:		carry SET if ignoring

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfIgnoring	proc near
	uses	ax
	.enter

	call	GenProcessUndoCheckIfIgnoring
	tst_clc	ax
	jz	done
	stc
done:
	.leave
	ret
CheckIfIgnoring	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapStartUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin an undo chain

CALLED BY:	UTILITY

PASS:		cx:dx - optr to undo title
		*ds:si - VisBitmap

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapStartUndoChain	proc far
	uses	ax,bx,dx,bp,di
	class	VisBitmapClass 
	.enter

	call	CheckIfIgnoring
	jc	done

	sub	sp,size StartUndoChainStruct
	mov	bp, sp

	movdw	ss:[bp].SUCS_title, cxdx
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[bp].SUCS_owner, axsi

	;
	;  Inc the undo depth
	;

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	inc	ds:[di].VBI_undoDepth

if 0
	BitClr	ds:[di].VBI_undoFlags, VBUF_HAD_SELECTION_BEFORE_LAST_ACTION
	tst	ds:[di].VBI_antTimer
	jz	startChain
	BitSet	ds:[di].VBI_undoFlags, VBUF_HAD_SELECTION_BEFORE_LAST_ACTION
startChain:
endif

	call	GeodeGetProcessHandle
	mov	dx, size StartUndoChainStruct
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	mov	ax, MSG_GEN_PROCESS_UNDO_START_CHAIN
	call	ObjMessage
	add	sp, size StartUndoChainStruct
done:
	.leave
	ret
BitmapStartUndoChain	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapEndUndoChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	finish sending undo data to the process

CALLED BY:	UTILITY

PASS:		es:bp - vis bitmap instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapEndUndoChain	proc far
	class	VisBitmapClass
	uses	ax,bx,cx,di
	.enter

	call	CheckIfIgnoring
	jc	done

	;
	;  Dec the undo depth
	;

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	cx, ds:[di].VBI_undoDepth
	jcxz	done
	dec	cx
	jnz	endChain

	;
	;  We're back to 0, so clear out the number of actions
	;
	mov	ds:[di].VBI_nUndoActions, cx

if 0
	BitClr	ds:[di].VBI_undoFlags, VBUF_HAD_SELECTION_BEFORE_LAST_ACTION
	tst	ds:[di].VBI_antTimer
	jz	endChain
	BitSet	ds:[di].VBI_undoFlags, VBUF_HAD_SELECTION_BEFORE_LAST_ACTION
endif

endChain:
	mov	ds:[di].VBI_undoDepth, cx
	mov	cx, sp					;non zero
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GEN_PROCESS_UNDO_END_CHAIN
	call	ObjMessage

done:
	.leave
	ret
BitmapEndUndoChain	endp

BitmapBasicCode	ends
