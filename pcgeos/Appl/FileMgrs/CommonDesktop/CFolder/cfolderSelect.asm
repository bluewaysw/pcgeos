COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Folder
FILE:		folderSelect.asm
AUTHOR:		Brian Chin

ROUTINES:
	INT	DeselectAll - deselect all selected files
	INT	AddToSelectList - add file to selection list
	INT	RemoveFromSeletList - remove file from selection list
	INT	AnchoredSelect - select group
	INT	HideSelection - hide selected files
	INT	UnhideSelection - unhide selected files

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version

DESCRIPTION:
	This file contains routines to support file selection list.

	$Id: cfolderSelect.asm,v 1.2 98/05/05 00:57:35 joon Exp $

------------------------------------------------------------------------------@

FolderAction segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeselectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deselects all selected files

CALLED BY:	INTERNAL
			FolderDeselectAll

PASS:		*ds:si - FolderClass object
		es - segment of locked folder buffer

RETURN:		preserves ds, si, es, di

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeselectAll	proc	far

	uses	di, si, bx

	class	FolderClass

	.enter

	mov	di, NIL
	call	SetCursor

	DerefFolderObject	ds, si, bx

	mov	di, ds:[bx].FOI_selectList	; start of select list

startLoop:
	cmp	di, NIL				; check if end-of-list mark
	je	done				; if so, done!
	and	es:[di].FR_state, not (mask FRSF_SELECTED)	; unselect
	test	ds:[bx].FOI_folderState, mask FOS_UPDATE_PENDING
	jz	invert
	ornf	es:[di].FR_state, mask FRSF_DELAYED
	jmp	after

invert:
	call	InvertIfTarget
after:
	mov	di, es:[di].FR_selectNext
	jmp	startLoop
done:
	mov	ds:[bx].FOI_selectList, NIL	; clear list

	.leave
	ret
DeselectAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddToSelectList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add this file to the selection list

CALLED BY:	FolderObjectPress

PASS:		es:di - pointer to folder buffer entry of file to add
		*ds:si - FolderClass object

RETURN:		file added to selection list (ds:[si].FOI_selectList)
		ds, si, es, di preserved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		find end of selection list
		tack file onto end of list

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddToSelectList	proc	far
	class	FolderClass

	uses	ax, bx, si, bp
	.enter

	DerefFolderObject	ds, si, bx
	mov	bp, ds:[bx].FOI_selectList	; get head of selection list
	cmp	bp, NIL				; check if empty list
	je	empty				; if so, handle specially
startLoop:
	mov	bx, bp				; get this item's addr.
	mov	bp, es:[bx].FR_selectNext	; get next item in list
	cmp	bp, NIL				; check if end-of-list
	jne	startLoop			; if not, go back for more
	mov	es:[bx].FR_selectNext, di	; attach new to end-of-list
	jmp	short endIt		; then make sure it's the end

empty:
	mov	ds:[bx].FOI_selectList, di	; make new the whole list

endIt:
	mov	es:[di].FR_selectNext, NIL	; make new one the end-of-list

	ornf	es:[di].FR_state, mask FRSF_SELECTED

	DerefFolderObject	ds, si, bx
	test	ds:[bx].FOI_folderState, mask FOS_UPDATE_PENDING
	jz	invert

	ornf	es:[di].FR_state, mask FRSF_DELAYED
	jmp	done

invert:
	call	InvertIfTarget
done:
	.leave
	ret
AddToSelectList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveFromSelectList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	remove this file from the selection list

CALLED BY:	calledby

PASS:		es:di - pointer to folder buffer entry of file to remove
		*ds:si - FolderClass object

RETURN:		file removed from selection list (ds:[si].FOI_selectList)
		ds, si, es, di preserved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/15/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveFromSelectList	proc	far
	class	FolderClass
	uses	ax, bx, si, bp
	.enter

	DerefFolderObject	ds, si, bx
	cmp	ds:[bx].FOI_selectList, NIL	; empty list?
	je	done				; yes

	cmp	di, ds:[bx].FOI_selectList	; are we head of list?
	jne	notHead				; if not, continue
	mov	bp, es:[di].FR_selectNext	; get the one after us
	mov	ds:[bx].FOI_selectList, bp	; attach as new head of list
	jmp	markNotSelected			; done!

notHead:
	mov	bp, ds:[bx].FOI_selectList	; start at beginning of list
	mov	bx, es:[bp].FR_selectNext	; we aren't the first, get next

startLoop:
	cmp	bx, NIL				; is this end of list?
	je	done			; if so, done
	cmp	bx, di				; is this us?
	je	foundUs			; if so, unlink us
	mov	bp, bx				; save previous one
	mov	bx, es:[bx].FR_selectNext	; else, get next in list
	jmp	startLoop			; 	and check it

foundUs:
	mov	bx, es:[di].FR_selectNext	; get the one after us
	mov	es:[bp].FR_selectNext, bx	; attach to the one before us

markNotSelected:
EC <	test	es:[di].FR_state, mask FRSF_SELECTED			>
EC <	ERROR_Z	-1							>

	andnf	es:[di].FR_state, not (mask FRSF_SELECTED)

	DerefFolderObject	ds, si, bx
	test	ds:[bx].FOI_folderState, mask FOS_UPDATE_PENDING
	jz	invert

	ornf	es:[di].FR_state, mask FRSF_DELAYED
	jmp	done

invert:
	call	InvertIfTarget
done:
	.leave
	ret
RemoveFromSelectList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnselectESDIEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unselect a file

CALLED BY:

PASS:		*ds:si - FolderClass object
		es:di - FolderRecord to select

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/17/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnselectESDIEntry	proc	far
	class	FolderClass

	uses	bx
	.enter

	call	RemoveFromSelectList
	call	PrintFolderInfoString
GM<	mov	bx, ds:[si]						>
GM<	mov	bx, ds:[bx].FOI_selectList				>
GM<	call	UpdateFileMenuCommon					>

	.leave
	ret
UnselectESDIEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectESDIEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		*ds:si - FolderClass object
		es:di - FolderRecord 		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/17/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectESDIEntry	proc	far
	class	FolderClass
	uses	bx
	.enter

	DerefFolderObject	ds, si, bx
	mov	ds:[bx].FOI_anchorIcon, NIL	; reset extend select anchor

	call	SetCursor
	call	AddToSelectList			; add DI to selection list
	call	PrintFolderInfoString		; update selection status

	.leave
	ret
SelectESDIEntry	endp

FolderAction ends
