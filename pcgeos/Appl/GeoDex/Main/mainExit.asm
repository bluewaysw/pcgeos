COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Main		
FILE:		mainExit.asm

AUTHOR:		Ted H. Kim, March 4, 1992

ROUTINES:
	Name			Description
	----			-----------
	RolodexSaveState	Save some variables inside a state file
	RemoveFromTextSelectList	
				Remove GeoDex from GCNList
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	Contains various routines called when GeoDex is exiting. 

	$Id: mainExit.asm,v 1.1 97/04/04 15:50:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Exit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RolodexSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves variables from udata into a data block that will
		be saved inside the state file.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION 

PASS:		ds - segment address of core block

RETURN:		cx - handle of data block

DESTROYED:	ax, bx, cx, es, si, di

PSEUDO CODE/STRATEGY:
	Allocate a block
	Copy all udata from differnt modules
	Return with handle of data block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	12/10/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RolodexSaveState	method	GeoDexClass, MSG_GEN_PROCESS_CLOSE_APPLICATION
	mov	bx, NUM_TEXT_EDIT_FIELDS+1  ; cx - number of fields to compare
					; add one for the note field
	clr	bp			; bp - offset into FieldTable
	call	CompareRecord
	je	notDirty		; if the record not modified, skip
NPZ <	test	ds:[dirtyFields], mask DFF_INDEX  ; is index field dirty?>
PZ <	test	ds:[dirtyFields], mask DFF_INDEX or mask DFF_PHONETIC	>
PZ <					; is index/phonetic field dirty?>
	je	addrDirty		; if not, skip
	ornf	ds:[recStatus], mask RSF_INDEX_DIRTY	; set the flag
	jmp	notDirty
addrDirty:
	ornf	ds:[recStatus], mask RSF_ADDR_DIRTY	; assume addr dirty
notDirty:
	call	CloseComPort		; close the com port

	mov	ax, endStateData - begStateData ; ax - # of bytes to allocate
	mov	cl, mask HF_SWAPABLE	; HeapFlags
	mov	ch, HAF_STANDARD_NO_ERR_LOCK	; HeapAllocFlags
	call	MemAlloc		; allocate a block
	clr	di	
	mov	es, ax			; es:di - destination

	mov	cx, endStateData - begStateData ; cx - number of bytes move
	mov	si, offset begStateData	; ds:si - source (udata)
	rep	movsb			; read map block into udata

	mov	cx, bx
	call	MemUnlock		; close up map block

	push	cx			; save the handle of memory block
	call	GeodeGetProcessHandle	; get process handle
	mov	cx, bx			; cx - process handle
	clr	dx			; dx - has to be the same as AddXfer
					; removed my OD from the list
	call	ClipboardRemoveFromNotificationList
	call	RemoveFromTextSelectList
	pop	cx			; restore the handle of memory block
	ret
RolodexSaveState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveFromTextSelectList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove GeoDex from text select state change GCNList.

CALLED BY:	(INTERNAL) RolodexSaveState

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, dx, bp, di, si

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveFromTextSelectList	proc	near

	; Setup GCNListParams

	mov	bx, ds:[processID]		; bx - process handle
	mov	dx, size GCNListParams		; dx - size of stack frame
	sub	sp, dx
	mov	bp, sp				; GCNListParams => SS:BP
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, \
			GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	mov	ss:[bp].GCNLP_optr.handle, bx	; bx:si - send it to process
	mov	ss:[bp].GCNLP_optr.chunk, 0	

	; get AppObject of current process 

	clr	bx
	call	GeodeGetAppObject		; returns OD in bx:si
	mov	ax, MSG_META_GCN_LIST_REMOVE	; remove GeoDex from GCNList
	mov	di, mask MF_STACK
	call	ObjMessage			; send it!!
	add	sp, dx				; clean up the stack
	ret
RemoveFromTextSelectList	endp

Exit	ends
