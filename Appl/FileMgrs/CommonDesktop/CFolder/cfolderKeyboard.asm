COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cfolderKeyboard.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/15/93   	Initial version.

DESCRIPTION:
	

	$Id: cfolderKeyboard.asm,v 1.2 98/06/03 13:34:02 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


FolderObscure	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle keypresses in Folder Window

CALLED BY:	MSG_META_KBD_CHAR

PASS:		*ds:si	= FolderClass object
		ch 	= CharacterSet
		cl 	= character value
		dl 	= CharFlags
		dh 	= ShiftState
		bp(low)	= ToggleState
		bp(high)= scan code

RETURN:

DESTROYED:	ax,cx,dx,bp	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/15/90	Initial version
	brianc	1/29/92		updated for 2.0 keyboard nav.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderKbdChar	method	dynamic FolderClass, MSG_META_KBD_CHAR

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	fup

	push	ds, si
	segmov	ds, cs
	mov	si, offset folderSelectKeysTable
	mov	ax, FOLDER_SELECT_KEYS_TABLE_SIZE
	call	FlowCheckKbdShortcut		; carry set if match (uses bp)
	mov	di, si				; di = table offset if match
	pop	ds, si
	jnc	notSelectKey

	push	bx
	call	cs:[di].folderSelectKeysRoutineTable
	pop	bx
	LONG	jc scroll
	jmp	done

notSelectKey:
	push	ds, si
	segmov	ds, cs
	mov	si, offset folderKeysTable
	mov	ax, FOLDER_KEYS_TABLE_SIZE
	call	FlowCheckKbdShortcut		; carry set if match (uses bp)
	mov	di, si				; di = table offset if match
	pop	ds, si
GM <	jnc	notShortcut					>
ifdef GPC_ONLY
ND <	jnc	fup						>
else
ND <	jnc	notShortcut					>
endif

	; This is an ugly hack to prevent REPEAT_PRESS from opening icons.
	; Somebody should go through this & do it the right way. Joon (5/12/93)

	cmp	cs:[di].folderKeysRoutineTable, offset FolderKeyEnter
	jne	goodKey

	test	dl, mask CF_REPEAT_PRESS
	jz	goodKey

fup:
	;
	; we don't want this, send it back up to the GenView
	;
	clr	di
	mov	ax, MSG_META_FUP_KBD_CHAR
	call	FolderCallView
doneJMP:
	jmp	done

if _GMGR or _NEWDESK
ifndef GPC_ONLY
notShortcut:
	;
	; It's not a shortcut key -- if it's a normal (alphanumeric)
	; key, then look for a file whose name starts with this character
	;
	test	dh, mask SS_LALT or mask SS_RALT or mask SS_LCTRL \
		or mask SS_RCTRL
	jnz	fup

DBCS <	cmp	ch, CS_CONTROL_HB			;control char?	>
DBCS <	je	fup					;branch if so	>
SBCS <	tst	ch							>
SBCS <	jnz	fup							>
	;
	; Since shift-A, etc. is used to activate drives, but the
	; SHIFT flag isn't set for such things, make sure the thing
	; isn't uppercase 
	;
SBCS <	mov	al, cl							>
SBCS <	clr	ah							>
DBCS <	mov	ax, cx							>
	call	LocalIsUpper
	jnz	fup
		
	cmp	ds:[bx].FOI_displayList, NIL
	je	fup
	call	FolderLockBuffer
	jz	fup

	; Start with the first file AFTER the cursor,
	; in case there are several files that start with the same letter.
	;
	mov	bp, ds:[bx].FOI_cursor
	mov	di, bp
	cmp	di, NIL
	jne	cmpNext

useDisplayList:
	mov	bp, ds:[bx].FOI_displayList
	mov	di, bp
SBCS <	clr	ah							>
cmpLoop:
		CheckHack <offset FR_name eq 0>
	LocalGetChar	ax, esdi, noAdvance
	call	LocalCmpCharsNoCase
	jz	selectCommon

cmpNext:
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	jne	cmpLoop

	cmp	bp, ds:[bx].FOI_displayList
	jne	useDisplayList	
	jmp	unlockBuffer

endif ; not GPC_ONLY
endif ; GMGR	
	
goodKey:
	;
	; process keyboard shortcut
	;	*ds:si = Folder object
	;	ds:bx = Folder instance data
	;	di = matching entry in key table
	;
	mov	bp, di
	mov	ds:[bx].FOI_anchorIcon, NIL	; reset anchor

	tst	ds:[bx].DVI_gState
	jz	doneJMP				; no gstate, window, do nothing
	cmp	ds:[bx].FOI_displayList, NIL
	je	doneJMP				; no icons, no nothing
	call	FolderLockBuffer
	jz	doneJMP				; no buffer, do nothing

	; If there's a cursor, use it as the starting point.

	mov	di, ds:[bx].FOI_cursor
	cmp	di, NIL
	jne	callHandler

	mov	di, ds:[bx].FOI_selectList
	cmp	di, NIL
	jne	callHandler

	mov	dx, ds:[bx].FOI_displayList
	jmp	selectThisOne

callHandler:
	push	si, di
	mov	si, ds:[si]
	call	cs:[bp].folderKeysRoutineTable
	pop	si, di
	jc	selectThisOne

	push	si
	mov	si, ds:[si]
	call	cs:[bp].folderKeysWrapTable
	pop	si		
	jnc	unlockBuffer

selectThisOne:
	mov	di, dx				; es:di = new selection
	cmp	di, NIL				; if no selection then bail
	je	unlockBuffer
selectCommon::

	; If in multi-select mode then don't change select list

	DerefFolderObject	ds, si, bx
	test	ds:[bx].FOI_folderState, mask FOS_MULTI_SELECT_MODE
	jz	notMultiSelect

	call	SetCursor
	jmp	scroll

notMultiSelect:
	call	DeselectAll
	call	SelectESDIEntry			; select new one

scroll:
	; Tell the view to make this thing visible, but barely so.

	CheckHack <MRVM_0_PERCENT eq 0>

	clr	ax
	push	ax			; MRVP_yFlags	MakeRectVisibleFlags
	push	ax			; MRVP_yMargin	MakeRectVisibleMargin
	push	ax			; MRVP_xFlags	MakeRectVisibleFlags
	push	ax			; MRVP_xMargin	MakeRectVisibleMargin
	mov	ax, es:[di].FR_boundBox.R_bottom
	cwd
	pushdw	dxax			; MRVP_bounds.RD_bottom
	mov	ax, es:[di].FR_boundBox.R_right
	cwd
	pushdw	dxax			; MRVP_bounds.RD_right
	mov	ax, es:[di].FR_boundBox.R_top
	cwd
	pushdw	dxax			; MRVP_bounds.RD_top
	mov	ax, es:[di].FR_boundBox.R_left
	cwd
	pushdw	dxax			; MRVP_bounds.RD_left

	mov	bp, sp			; ss:bp = MakeRectVisibleParams

	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	mov	dx, size MakeRectVisibleParams
	mov	di, mask MF_CALL or mask MF_STACK
	call	FolderCallView

	add	sp, size MakeRectVisibleParams

unlockBuffer:
	call	FolderUnlockBuffer
done:
	ret
FolderKbdChar	endm

;
; keyboard shortcut handling routines


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderKey{BlankEnter, Left,Right,Up,Down,Home,End}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle one of the keypresses

CALLED BY:	FolderKbdChar

PASS:		ds:si = Folder instance data
		es:di = current FolderRecord 

RETURN:		carry set to set new selection
			es:dx = new selection
		carry clear otherwise
		si - folder chunk handle
DESTROYED:	ax, bx, bp, di, si


PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/20/92   	added header
	martin	7/28/92		completly revised to handle flexible placement

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderKeyEnter	proc	near
GM<	class	FolderClass	>
ND<	class	NDFolderClass 	>
ND<	mov	ds:[si].NDFOI_popUpType, WPUT_SELECTION	>

	mov	ax, MSG_OPEN_SELECT_LIST
	mov	si, ds:[si].FOI_chunkHandle
	call	ObjCallInstanceNoLock		; open it
	clc					; don't change selection
	ret
FolderKeyEnter	endp
;----------------------------------------------------------------------
FolderKeyEnterClose	proc	near
	class	FolderClass
	push	ax, cx, dx, bp, si
	mov	si, ds:[si].FOI_chunkHandle
	mov	ax, MSG_CLOSE_FOLDER_WIN
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp, si
	GOTO	FolderKeyEnter
FolderKeyEnterClose	endp

;----------------------------------------------------------------------

if GPC_SIMPLE_KBD_NAVIGATION

FolderKeyNavigationFlags	record
	FKNF_VERTICAL:1
	FKNF_BACKWARD:1
FolderKeyNavigationFlags	end

FolderKeyNoWrap	proc	near
	clc			; don't change selection
	ret
FolderKeyNoWrap endp

FolderKeyHome	proc	near
	mov	dx, -1
	push	dx		; X target
	push	dx		; Y target
	mov	dx, 0
	push	dx		; flags
	call	FolderGetNextOne
	ret
FolderKeyHome	endp

FolderKeyEnd	proc	near
	mov	dx, 32767
	push	dx		; X target
	push	dx		; Y target
	mov	dx, mask FKNF_BACKWARD
	push	dx		; flags
	call	FolderGetNextOne
	ret
FolderKeyEnd	endp

FolderKeyLeft	proc	near
	push	es:[di].FR_iconBounds.R_left	; X target
	push	es:[di].FR_iconBounds.R_top	; Y target
	mov	dx, mask FKNF_BACKWARD
	push	dx				; flags
	call	FolderGetNextOne
	ret
FolderKeyLeft	endp

FolderKeyRight	proc	near
	push	es:[di].FR_iconBounds.R_left	; X target
	push	es:[di].FR_iconBounds.R_top	; Y target
	clr	dx
	push	dx				; flags
	call	FolderGetNextOne
	ret
FolderKeyRight	endp

FolderKeyUp	proc	near
	push	es:[di].FR_iconBounds.R_left	; X target
	push	es:[di].FR_iconBounds.R_top	; Y target
	mov	dx, mask FKNF_VERTICAL or mask FKNF_BACKWARD
	push	dx				; flags
	call	FolderGetNextOne
	ret
FolderKeyUp	endp

FolderKeyDown	proc	near
	push	es:[di].FR_iconBounds.R_left	; X target
	push	es:[di].FR_iconBounds.R_top	; Y target
	mov	dx, mask FKNF_VERTICAL
	push	dx				; flags
	call	FolderGetNextOne
	ret
FolderKeyDown	endp

FolderGetNextOne	proc	near	flags:word,
					yTarget:word,
					xTarget:word
currentOne	local	word	push	di
bestDiff	local	dword
bestSoFar	local	word
	uses	cx
	class	FolderClass
	.enter
	mov	bestSoFar, di
	movdw	bestDiff, -1
	mov	di, ds:[si].FOI_displayList
checkLoop:
	mov	ax, es:[di].FR_iconBounds.R_left
	mov	bx, es:[di].FR_iconBounds.R_top
	mov	cx, xTarget
	mov	dx, yTarget
	call	normalizePos
	test	flags, mask FKNF_VERTICAL
	jnz	vertical
horizontal::
	test	flags, mask FKNF_BACKWARD
	jnz	hBackward
hForward::
	cmpdw	bxax, dxcx
	jle	checkNext
	subdw	bxax, dxcx
	cmpdw	bxax, bestDiff
	jae	checkNext
	movdw	bestDiff, bxax
	jmp	newBest

hBackward:
	cmpdw	bxax, dxcx
	jge	checkNext
	subdw	dxcx, bxax
	cmpdw	dxcx, bestDiff
	jae	checkNext
	movdw	bestDiff, dxcx
	jmp	newBest
	
vertical:
	test	flags, mask FKNF_BACKWARD
	jnz	vBackward
vForward::
	cmpdw	axbx, cxdx
	jle	checkNext
	subdw	axbx, cxdx
	cmpdw	axbx, bestDiff
	jae	checkNext
	movdw	bestDiff, axbx
	jmp	newBest

vBackward:
	cmpdw	axbx, cxdx
	jge	checkNext
	subdw	cxdx, axbx
	cmpdw	cxdx, bestDiff
	jae	checkNext
	movdw	bestDiff, cxdx
newBest:
	mov	bestSoFar, di
checkNext:
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	LONG jne	checkLoop
	mov	dx, bestSoFar
	cmp	dx, currentOne
	je	done				; no change, C clear
	stc					; else, got one
done:
	.leave
	ret	@ArgSize

normalizePos	label	near
	call	normalizeX
	xchg	ax, cx
	call	normalizeX
	xchg	ax, cx
	call	normalizeY
	xchg	bx, dx
	call	normalizeY
	xchg	bx, dx
	retn

normalizeX	label	near
	test	ds:[si].FOI_displayMode, mask FIDM_LICON
	jnz	needNormalizeX
	cmp	ds:[si].FOI_displayMode, mask FIDM_SICON
	jz	doneNormalizeX
needNormalizeX:
	push	bx, cx, dx
	mov	dx, ax
	clr	cx, ax
	mov	bx, es:[di].FR_iconBounds.R_right
	sub	bx, es:[di].FR_iconBounds.R_left
	call	GrSDivWWFixed
	jnc	gotX
	mov	dx, 32767
gotX:
	mov	ax, dx
	pop	bx, cx, dx
doneNormalizeX:
	retn

normalizeY	label	near
	test	ds:[si].FOI_displayMode, mask FIDM_LICON
	jnz	needNormalizeY
	cmp	ds:[si].FOI_displayMode, mask FIDM_SICON
	jz	doneNormalizeY
needNormalizeY:
	push	ax, cx, dx
	mov	dx, bx
	clr	cx, ax
	mov	bx, es:[di].FR_iconBounds.R_right
	sub	bx, es:[di].FR_iconBounds.R_left
	call	GrSDivWWFixed
	jnc	gotY
	mov	dx, 32767
gotY:
	mov	bx, dx
	pop	ax, cx, dx
doneNormalizeY:
	retn
FolderGetNextOne	endp

FolderKeyWrapLeft equ FolderKeyLeft
FolderKeyWrapRight equ FolderKeyRight
FolderKeyWrapUp equ FolderKeyUp
FolderKeyWrapDown equ FolderKeyDown

else	; GPC_SIMPLE_KBD_NAVIGATION

FolderKeyHome	proc	near
	class	FolderClass 
	mov	dx, ds:[si].FOI_displayList	; NIL is okay
	stc					; change selection
	ret
FolderKeyHome	endp

;----------------------------------------------------------------------
FolderKeyEnd	proc	near
	class	FolderClass
	cmp	es:[di].FR_displayNext, NIL	; is this the last one
	je	done				; this is last one (clc)
endLoop:
	mov	dx, di				; this is potential last one
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	jne	endLoop				; this is not last one
	stc					; change selection
done:
	ret
FolderKeyEnd	endp

;----------------------------------------------------------------------
FolderKeyDown	proc	near
	class	FolderClass

bestSoFar	local	nptr.FolderRecord	push	di
current		local	nptr.FolderRecord	push	di
bestScore	local	dword
currentScore	local	dword

	.enter
ForceRef	currentScore

	movdw	bestScore, -1

	mov	bx, es:[di].FR_iconBounds.R_left
	mov	ax, es:[di].FR_iconBounds.R_right
	sub	ax, bx
	shr	ax
	add	ax, bx				; ax = center of icon
						; (X direction) 
	mov	bx, es:[di].FR_iconBounds.R_top
	mov	di, ds:[si].FOI_displayList

findIconLoop:
	mov	dx, es:[di].FR_iconBounds.R_top
	cmp	dx, bx
	jle	checkNext			; ignore if above
	mov	cx, es:[di].FR_iconBounds.R_left
	cmp	ax, cx
	jl	useLeft
	mov	cx, ax
	sub	cx, es:[di].FR_iconBounds.R_right
	jmp	checkThisIcon

useLeft:
	sub	cx, ax				; cx = positive delta x (^x)

checkThisIcon:
	sub	dx, bx				; dx = positive delta y (^y)
	call	FolderCalcIconScore

checkNext:
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	jne 	findIconLoop

	mov	dx, bestSoFar
	cmp	dx, current
	je	done
	stc					; change selection

done:
	.leave
	ret
FolderKeyDown	endp


FolderKeyUp	proc	near

	class	FolderClass

bestSoFar	local	nptr.FolderRecord	push	di
current		local	nptr.FolderRecord	push	di
bestScore	local	dword
currentScore	local	dword

	.enter

ForceRef	currentScore

	movdw	bestScore, -1
	mov	bx, es:[di].FR_iconBounds.R_left
	mov	ax, es:[di].FR_iconBounds.R_right
	sub	ax, bx
	shr	ax
	add	ax, bx				; ax = center of icon
						; (X direction) 
	mov	bx, es:[di].FR_iconBounds.R_top
	mov	di, ds:[si].FOI_displayList
findIconLoop:
	mov	dx, es:[di].FR_iconBounds.R_top
	cmp	dx, bx
	jge	checkNext			; ignore if below
	mov	cx, es:[di].FR_iconBounds.R_left
	cmp	ax, cx
	jl	useLeft
	mov	cx, ax
	sub	cx, es:[di].FR_iconBounds.R_right
	jmp	checkThisIcon
useLeft:
	sub 	cx, ax				; cx = positive delta x (^x)
checkThisIcon:
	neg	dx
	add	dx, bx				; dx = positive delta y (^y)
	call	FolderCalcIconScore
checkNext:
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	jne 	findIconLoop

	mov	dx, bestSoFar
	cmp	dx, current
	je	done
	stc					; change selection
done:
	.leave
	ret
FolderKeyUp	endp



FolderKeyLeft	proc	near
	class	FolderClass
bestSoFar	local	nptr.FolderRecord	push	di
current		local	nptr.FolderRecord	push	di
bestScore	local	dword
currentScore	local	dword

	.enter
	ForceRef	currentScore
	movdw	bestScore, -1
	mov	bx, es:[di].FR_iconBounds.R_top
	mov	ax, es:[di].FR_iconBounds.R_bottom
	sub	ax, bx
	shr	ax
	add	ax, bx				; ax = center of icon
						; (Y direction) 
	mov	bx, es:[di].FR_iconBounds.R_left
	mov	di, ds:[si].FOI_displayList
findIconLoop:
	mov	dx, es:[di].FR_iconBounds.R_left
	cmp	dx, bx
	jge	checkNext			; ignore if to the right
	mov	cx, es:[di].FR_iconBounds.R_top
	cmp	ax, cx
	jl	useTop
	mov	cx, ax
	sub	cx, es:[di].FR_iconBounds.R_bottom
	jmp	checkThisIcon
useTop:
	sub 	cx, ax				; cx = positive delta y (^y)
checkThisIcon:
	neg	dx
	add	dx, bx				; dx = positive delta x (^x)
	call	FolderCalcIconScore
checkNext:
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	jne 	findIconLoop

	mov	dx, bestSoFar
	cmp	dx, current
	je	done
	stc					; change selection
done:
	.leave
	ret
FolderKeyLeft	endp

FolderKeyRight	proc	near
	class	FolderClass
bestSoFar	local	nptr.FolderRecord	push	di
current		local	nptr.FolderRecord	push	di
bestScore	local	dword
currentScore	local	dword

	.enter
	ForceRef	currentScore
	;
	; If this is the last icon in the display list then we can't
	; move to the right.
	;
	cmp	es:[di].FR_displayNext, NIL
	je	done

	movdw	bestScore, -1
	mov	bx, es:[di].FR_iconBounds.R_top
	mov	ax, es:[di].FR_iconBounds.R_bottom
	sub	ax, bx
	shr	ax
	add	ax, bx				; ax = center of icon
						; (Y direction) 
	;
	; For the loop:
	; 	ax	= center of current selection
	; 	bx	= left edge of current selection
	; 	di	= record to check next
	; 
	mov	bx, es:[di].FR_iconBounds.R_left
	mov	di, ds:[si].FOI_displayList
findIconLoop:
	mov	dx, es:[di].FR_iconBounds.R_left
	cmp	dx, bx
	jle	checkNext			; ignore if to the left
	mov	cx, es:[di].FR_iconBounds.R_top
	cmp	ax, cx				; is this one above or below
						;  selection?
	jl	useTop				; below, so figure distance from
						;  center to top of this one
	mov	cx, ax
	sub	cx, es:[di].FR_iconBounds.R_bottom
	jmp	checkThisIcon
useTop:
	sub 	cx, ax				; cx = positive delta y (^y)
checkThisIcon:
	sub	dx, bx				; dx = positive delta x (^x)
	call	FolderCalcIconScore
checkNext:
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	jne 	findIconLoop

	mov	dx, bestSoFar
	cmp	dx, current
	je	done
	stc					; change selection
done:
	.leave
	ret
FolderKeyRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderKeyNoWrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wrapping function for directions that aren't supposed to
		wrap

CALLED BY:	(INTERNAL) FolderKbdChar
PASS:		es:di	= current selection
		ds:si	= FolderInstance
RETURN:		carry set to change selection:
			dx	= new selection
		carry clear to not change
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderKeyNoWrap	proc	near
	clc			; don't change selection
	ret
FolderKeyNoWrap endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderKeyWrapRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the left-most item on the next line.

CALLED BY:	FolderKbdChar
PASS:		es:di	= current selection
		ds:si	= FolderInstance
RETURN:		carry set to change selection:
			dx	= new selection
		carry clear to not change
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Run through things looking for an icon that is
		(1) below the current one,
		(2) moving all the way right from it doesn't end us up with
		    the current selection, and
		(3) is the closest left-most one of this set.
		
		Strategy: 
			- work through the display list looking for icons
			  that are below the center of the current one.
			- if an icon is closer than any previous, but still
			  farther away than the minimum, record it.
			- if an icon is same distance as previous best, but is
			  farther left, record it.
			- when hit the end of the list, repeatedly call
			  FolderKeyRight until it stops changing. If final
			  thing is same as current selection, set minimum to
			  what we thought was the best and try again.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderKeyWrapRight	proc	near
	class	FolderClass
bestSoFar	local	nptr.FolderRecord	push	di	
current		local	nptr.FolderRecord 	push 	di
bestScore	local	sword
bestLeft	local	sword
minScore	local	sword

	.enter
	mov	minScore, 0			; boundary. score must be
						;  greater than this
again:
	mov	bestScore, 32767
	mov	bestLeft, 32767
	mov	bx, es:[di].FR_iconBounds.R_top
	mov	ax, es:[di].FR_iconBounds.R_bottom
	sub	ax, bx
	shr	ax
	add	ax, bx				; ax = center of icon
						; (Y direction) 
	mov	di, ds:[si].FOI_displayList
findIconLoop:
	mov	dx, es:[di].FR_iconBounds.R_top
	sub	dx, ax
	jle	checkNext			; ignore if above

	mov	cx, es:[di].FR_iconBounds.R_left
	cmp	dx, ss:[bestScore]
	jg	checkNext			; farther away
	jl	checkMin			; closer

	; equal. see which is left-most
	cmp	cx, ss:[bestLeft]
	jge	checkNext			; already have left-most
checkMin:
	cmp	dx, ss:[minScore]		; too close?
	jle	checkNext

	mov	ss:[bestLeft], cx
	mov	ss:[bestScore], dx
	mov	ss:[bestSoFar], di

checkNext:
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	jne 	findIconLoop

	;
	; Now work our way right from the beast and see if we end up where
	; we started, implying what we have is actually on the same "level"
	; as what we had.
	; 
	mov	di, ss:[bestSoFar]
moveRight:
	cmp	es:[di].FR_displayNext, NIL
	je	moveRightDone		; assume end of display list is
					;  right-most object and any change
					;  made by FolderKeyRight would be
					;  a move upward, which ain't what
					;  we want

	call	FolderKeyRight
	mov	di, dx			; for passing in again, if change
	jc	moveRight		; => selection changed

moveRightDone:
	cmp	di, ss:[current]	; same as we started with?
	stc
	jne	haveIt			; no => on different level, so we're
					;  done

	mov	ax, ss:[bestScore]	; yes. set this one's score as the
	mov	ss:[minScore], ax	;  boundary for our next search.

	mov	ax, di			; loop if we actually found anything
	xchg	ax, ss:[bestSoFar]	;  but ourselves on the previous loop
	cmp	ax, di
	jne	again
	; (carry clear on == comparison)

haveIt:
	mov	dx, bestSoFar
	.leave
	ret
FolderKeyWrapRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderKeyWrapLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the left-most item on the next line.

CALLED BY:	FolderKbdChar
PASS:		es:di	= current selection
		ds:si	= FolderInstance
RETURN:		carry set to change selection:
			dx	= new selection
		carry clear to not change
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Run through things looking for an icon that is
		(1) below the current one,
		(2) moving all the way right from it doesn't end us up with
		    the current selection, and
		(3) is the closest left-most one of this set.
		
		Strategy: 
			- work through the display list looking for icons
			  that are below the center of the current one.
			- if an icon is closer than any previous, but still
			  farther away than the minimum, record it.
			- if an icon is same distance as previous best, but is
			  farther left, record it.
			- when hit the end of the list, repeatedly call
			  FolderKeyRight until it stops changing. If final
			  thing is same as current selection, set minimum to
			  what we thought was the best and try again.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderKeyWrapLeft	proc	near
	class	FolderClass

bestSoFar	local	nptr.FolderRecord	push	di	
current		local	nptr.FolderRecord 	push 	di
bestScore	local	sword
bestRight	local	sword
maxScore	local	sword
failedToAdvance	local	word

	.enter
	mov	failedToAdvance, 0
	mov	maxScore, 0			; boundary. score must be
						;  less than this
again:
	mov	bestScore, -32767
	mov	bestRight, 0
	mov	bx, es:[di].FR_iconBounds.R_top
	mov	ax, es:[di].FR_iconBounds.R_bottom
	sub	ax, bx
	shr	ax
	add	ax, bx				; ax = center of icon
						; (Y direction) 
	mov	di, ds:[si].FOI_displayList
findIconLoop:
	mov	dx, es:[di].FR_iconBounds.R_top
	sub	dx, ax				; dx <- negative distance
	jge	checkNext			; ignore if below

	mov	cx, es:[di].FR_iconBounds.R_right
	cmp	dx, ss:[bestScore]
	jl	checkNext			; farther away
	jg	checkMax			; closer

	; equal. see which is left-most
	cmp	cx, ss:[bestRight]
	jle	checkNext			; already have right-most
checkMax:
	cmp	dx, ss:[maxScore]		; too close?
	jge	checkNext

	mov	ss:[bestRight], cx
	mov	ss:[bestScore], dx
	mov	ss:[bestSoFar], di

checkNext:
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	jne 	findIconLoop

	;
	; Now work our way left from the beast and see if we end up where
	; we started, implying what we have is actually on the same "level"
	; as what we had.
	; 
	mov	di, ss:[bestSoFar]
moveLeft:
	cmp	di, ds:[si].FOI_displayList
	je	moveLeftDone		; assume start of display list is
					;  left-most object and any change
					;  made by FolderKeyRight would be
					;  a move downward, which ain't what
					;  we want

	call	FolderKeyLeft
	mov	di, dx			; for passing in again, if change
	jc	moveLeft		; => selection changed

moveLeftDone:
	cmp	di, ss:[current]	; same as we started with?
	stc
	jne	haveIt			; no => on different level, so we're
					;  done

	mov	ax, ss:[bestScore]	; yes. set this one's score as the
	mov	ss:[maxScore], ax	;  boundary for our next search.

	mov	ax, di			; loop if we actually found anything
	xchg	ax, ss:[bestSoFar]	;  but ourselves on the previous loop
	cmp	ax, di
	jne	again
	;
	; if we didn't find anything but ourselves on the previous loop,
	; we need to try once more as this will happen if there is only a
	; single item in the row - brianc 6/14/93
	;
	tst	ss:[failedToAdvance]
	clc				; assume nothing found
	jnz	haveIt			; yep, already tried, nothing found
	mov	ss:[failedToAdvance], -1	; else, indicate 2nd attempt
	jmp	short again

haveIt:
	mov	dx, bestSoFar
	.leave
	ret
FolderKeyWrapLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderKeyWrapDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the top-most item on the next line.

CALLED BY:	FolderKbdChar
PASS:		es:di	= current selection
		ds:si	= FolderInstance
RETURN:		carry set to change selection:
			dx	= new selection
		carry clear to not change
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderKeyWrapDown	proc	near
	class	FolderClass
bestSoFar	local	nptr.FolderRecord	push	di	
current		local	nptr.FolderRecord 	push 	di
bestScore	local	sword
bestTop		local	sword
minScore	local	sword

	.enter
	mov	minScore, 0			; boundary. score must be
						;  greater than this
again:
	mov	bestScore, 32767
	mov	bestTop, 32767
	mov	bx, es:[di].FR_iconBounds.R_left
	mov	ax, es:[di].FR_iconBounds.R_right
	sub	ax, bx
	shr	ax
	add	ax, bx				; ax = center of icon
						; (X direction) 
	mov	di, ds:[si].FOI_displayList
findIconLoop:
	mov	dx, es:[di].FR_iconBounds.R_left
	sub	dx, ax
	jle	checkNext			; ignore if to left

	mov	cx, es:[di].FR_iconBounds.R_top
	cmp	dx, ss:[bestScore]
	jg	checkNext			; farther away
	jl	checkMin			; closer

	; equal. see which is top-most
	cmp	cx, ss:[bestTop]
	jge	checkNext			; already have top-most
checkMin:
	cmp	dx, ss:[minScore]		; too close?
	jle	checkNext

	mov	ss:[bestTop], cx
	mov	ss:[bestScore], dx
	mov	ss:[bestSoFar], di

checkNext:
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	jne 	findIconLoop

	;
	; Now work our way down from the beast and see if we end up where
	; we started, implying what we have is actually on the same "level"
	; as what we had.
	; 
	mov	di, ss:[bestSoFar]
moveRight:
	cmp	es:[di].FR_displayNext, NIL
	je	moveDownDone		; assume end of display list is
					;  bottom-most object and any change
					;  made by FolderKeyDown would be
					;  a move upward, which ain't what
					;  we want

	call	FolderKeyDown
	mov	di, dx			; for passing in again, if change
	jc	moveRight		; => selection changed

moveDownDone:
	cmp	di, ss:[current]	; same as we started with?
	stc
	jne	haveIt			; no => on different level, so we're
					;  done

	mov	ax, ss:[bestScore]	; yes. set this one's score as the
	mov	ss:[minScore], ax	;  boundary for our next search.

	mov	ax, di			; loop if we actually found anything
	xchg	ax, ss:[bestSoFar]	;  but ourselves on the previous loop
	cmp	ax, di
	jne	again
	; (carry clear on == comparison)

haveIt:
	mov	dx, bestSoFar
	.leave
	ret
FolderKeyWrapDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderKeyWrapUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the bottom-most item on the previous line.

CALLED BY:	FolderKbdChar
PASS:		es:di	= current selection
		ds:si	= FolderInstance
RETURN:		carry set to change selection:
			dx	= new selection
		carry clear to not change
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderKeyWrapUp	proc	near
	class	FolderClass

bestSoFar	local	nptr.FolderRecord	push	di	
current		local	nptr.FolderRecord 	push 	di
bestScore	local	sword
bestBottom	local	sword
maxScore	local	sword
failedToAdvance	local	word

	.enter
	mov	failedToAdvance, 0
	mov	maxScore, 0			; boundary. score must be
						;  less than this
again:
	mov	bestScore, -32767
	mov	bestBottom, 0
	mov	bx, es:[di].FR_iconBounds.R_left
	mov	ax, es:[di].FR_iconBounds.R_right
	sub	ax, bx
	shr	ax
	add	ax, bx				; ax = center of icon
						; (X direction) 
	mov	di, ds:[si].FOI_displayList
findIconLoop:
	mov	dx, es:[di].FR_iconBounds.R_left
	sub	dx, ax				; dx <- negative distance
	jge	checkNext			; ignore if below

	mov	cx, es:[di].FR_iconBounds.R_bottom
	cmp	dx, ss:[bestScore]
	jl	checkNext			; farther away
	jg	checkMax			; closer

	; equal. see which is bottom-most
	cmp	cx, ss:[bestBottom]
	jle	checkNext			; already have bottom-most
checkMax:
	cmp	dx, ss:[maxScore]		; too close?
	jge	checkNext

	mov	ss:[bestBottom], cx
	mov	ss:[bestScore], dx
	mov	ss:[bestSoFar], di

checkNext:
	mov	di, es:[di].FR_displayNext
	cmp	di, NIL
	jne 	findIconLoop

	;
	; Now work our way up from the beast and see if we end up where
	; we started, implying what we have is actually on the same "level"
	; as what we had.
	; 
	mov	di, ss:[bestSoFar]
moveUp:
	cmp	di, ds:[si].FOI_displayList
	je	moveUpDone		; assume start of display list is
					;  left-most object and any change
					;  made by FolderKeyUp would be
					;  a move downward, which ain't what
					;  we want

	call	FolderKeyUp
	mov	di, dx			; for passing in again, if change
	jc	moveUp			; => selection changed

moveUpDone:
	cmp	di, ss:[current]	; same as we started with?
	stc
	jne	haveIt			; no => on different level, so we're
					;  done

	mov	ax, ss:[bestScore]	; yes. set this one's score as the
	mov	ss:[maxScore], ax	;  boundary for our next search.

	mov	ax, di			; loop if we actually found anything
	xchg	ax, ss:[bestSoFar]	;  but ourselves on the previous loop
	cmp	ax, di
	jne	again
	;
	; if we didn't find anything but ourselves on the previous loop,
	; we need to try once more as this will happen if there is only a
	; single item in the row - brianc 6/14/93
	;
	tst	ss:[failedToAdvance]
	clc				; assume nothing found
	jnz	haveIt			; yep, already tried, nothing found
	mov	ss:[failedToAdvance], -1	; else, indicate 2nd attempt
	jmp	short again

haveIt:
	mov	dx, bestSoFar
	.leave
	ret
FolderKeyWrapUp	endp



COMMENT @-------------------------------------------------------------------
			FolderCalcIconScore
----------------------------------------------------------------------------

DESCRIPTION:

CALLED BY:	INTERNAL - FolderKey{Up,Down,Right,Left}

PASS:		dx	= distance from cursor to icon 
			  (in direction of keypress)
		cx	= distance from cursor to icon		
			  (perpendicular to keypress)

RETURN:		Inherited local variables:
			bestScore, bestSoFar

DESTROYED:	cx, dx 
		currentScore (inherited local variable)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/29/92		Initial version

---------------------------------------------------------------------------@
FolderCalcIconScore	proc	near

	uses	ax, bx

	.enter 	inherit FolderKeyUp

	mov	bx, dx				; bx = ^y

	cmp	bx, cx				; inside 45 degree wedge?
	jl	done				; ignore if not

	sub	bx, cx				; bx = ^y - ^x
	jns	continue
	neg	bx
continue:					; bx = |^y - ^x|
	shl	bx
	shl	bx
	shl	bx				; bx = Constant|^y - ^x|
	inc	bx				; bx = Constant|^y - ^x|+1
	jz	done

	mov	ax, dx
	imul	ax				; dx:ax = ^y squared
	movdw	currentScore, dxax

	mov	ax, cx
	imul	ax
	adddw	dxax, currentScore		; currentScore =
						; distance squared

	mov	cx, ax			; dx:cx = Constant*sqr(distance)

	clr	ax
	call	GrUDivWWFixed		     	; divide, fraction in dx.cx 
	mov	ax, cx
	cmpdw	bestScore, dxax
	jb	done
	movdw	bestScore, dxax
	mov	bestSoFar, di

done:
	.leave
	ret
FolderCalcIconScore	endp

endif  ; GPC_SIMPLE_KBD_NAVIGATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	FolderSelectKeysExtendLeft,	FolderSelectKeysExtendRight,
	FolderSelectKeysExtendUp,	FolderSelectKeysExtendDown,
	FolderSelectKeysToggleIcon	FolderSelectKeysToggleMultiSelect
	FolderSelectKeysSelectAll	FolderSelectKeysDeselectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extend selection left
		Extend selection right
		Extend selection up
		Extend selection down
		Toggle currently selected icon
		Toggle multi-select mode
		Select all icons
		Deselect all icons

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = Folder object
		ds:bx = folder instance data
RETURN:		if carry set
			we need to scroll,
			folder buffer is locked
			es:di = FolderRecord to make visibile
		else
			we don't need to scroll
			folder buffer is not locked

DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSelectKeysExtendLeft	proc	near
	mov	ax, offset FolderKeyLeft
	GOTO	FolderSelectKeysExtend
FolderSelectKeysExtendLeft	endp

FolderSelectKeysExtendRight	proc	near
	mov	ax, offset FolderKeyRight
	GOTO	FolderSelectKeysExtend
FolderSelectKeysExtendRight	endp

FolderSelectKeysExtendUp	proc	near
	mov	ax, offset FolderKeyUp
	GOTO	FolderSelectKeysExtend
FolderSelectKeysExtendUp	endp

FolderSelectKeysExtendDown	proc	near
	mov	ax, offset FolderKeyDown
	FALL_THRU FolderSelectKeysExtend
FolderSelectKeysExtendDown	endp

FolderSelectKeysExtend		proc	near
oldRegion	local	Rectangle
newRegion	local	Rectangle
	class	FolderClass
	.enter

	mov	di, ds:[bx].FOI_cursor
	cmp	di, NIL
	je	done			; done if no icon has cursor

	call	FolderLockBuffer

	cmp	ds:[bx].FOI_anchorIcon, NIL
	jne	moveCursor
	mov	ds:[bx].FOI_anchorIcon, di

moveCursor:
	push	si, di
	mov	si, bx			; ds:si = folder instance data
	mov_tr	bx, ax
	call	bx
	pop	si, di
	jc	extendSelection

	call	FolderUnlockBuffer
	jmp	done

extendSelection:
	push	si
	mov	bx, ds:[si]
	mov	si, ds:[bx].FOI_anchorIcon
	lea	bx, ss:[oldRegion]
	call	calcSelectRegion
	mov	di, dx
	lea	bx, ss:[newRegion]
	call	calcSelectRegion
	pop	si

	call	SetCursor

	push	di
	mov	bx, ds:[si]
	mov	di, ds:[bx].FOI_displayList
iconLoop:
	cmp	di, NIL
	je	noMoreIcons

	call	checkIconInOnlyOneRegion
	jz	nextIcon

	test	es:[di].FR_state, mask FRSF_SELECTED
	jnz	deselect

	call	AddToSelectList
	jmp	nextIcon
deselect:
	call	RemoveFromSelectList
nextIcon:
	mov	di, es:[di].FR_displayNext
	jmp	iconLoop

noMoreIcons:
GM<	call	PrintFolderInfoString					>
	pop	di
	stc				; leave with folder buffer locked
done:
	.leave
	ret


calcSelectRegion:
	;
	; Calculate rectanglar region which encompass FolderRecords
	; es:di and es:si.  Store in Rectangle ss:[bx].
	; Destroys - ax, cx
	;
	mov	ax, es:[di].FR_boundBox.R_left
	mov	cx, es:[si].FR_boundBox.R_left
	cmp	ax, cx
	jl	10$
	mov	ax, cx
10$:
	inc	ax
	mov	ss:[bx].R_left, ax

	mov	ax, es:[di].FR_boundBox.R_top
	mov	cx, es:[si].FR_boundBox.R_top
	cmp	ax, cx
	jl	20$
	mov	ax, cx
20$:
	inc	ax
	mov	ss:[bx].R_top, ax

	mov	ax, es:[di].FR_boundBox.R_right
	mov	cx, es:[si].FR_boundBox.R_right
	cmp	ax, cx
	jg	30$
	mov	ax, cx
30$:
	dec	ax
	mov	ss:[bx].R_right, ax

	mov	ax, es:[di].FR_boundBox.R_bottom
	mov	cx, es:[si].FR_boundBox.R_bottom
	cmp	ax, cx
	jg	40$
	mov	ax, cx
40$:
	dec	ax
	mov	ss:[bx].R_bottom, ax
	retn


checkIconInOnlyOneRegion:
	;
	; Return zflag clear if icon (es:di) is in one region but not the other
	;
	clr	cx
	mov	ax, ss:[oldRegion].R_left
	cmp	ax, es:[di].FR_boundBox.R_right
	jg	notInOld
	mov	ax, ss:[oldRegion].R_right
	cmp	ax, es:[di].FR_boundBox.R_left
	jl	notInOld
	mov	ax, ss:[oldRegion].R_top
	cmp	ax, es:[di].FR_boundBox.R_bottom
	jg	notInOld	
	mov	ax, ss:[oldRegion].R_bottom
	cmp	ax, es:[di].FR_boundBox.R_top
	jl	notInOld
	inc	cx					; in old region
notInOld:
	mov	ax, ss:[newRegion].R_left
	cmp	ax, es:[di].FR_boundBox.R_right
	jg	notInNew
	mov	ax, ss:[newRegion].R_right
	cmp	ax, es:[di].FR_boundBox.R_left
	jl	notInNew
	mov	ax, ss:[newRegion].R_top
	cmp	ax, es:[di].FR_boundBox.R_bottom
	jg	notInNew	
	mov	ax, ss:[newRegion].R_bottom
	cmp	ax, es:[di].FR_boundBox.R_top
	jl	notInNew
	inc	cx					; in new region
notInNew:
	test	cl, 1					; return zero flag
	retn
FolderSelectKeysExtend		endp


FolderSelectKeysToggleIcon	proc	near
	class	FolderClass

	mov	ds:[bx].FOI_anchorIcon, NIL

	mov	di, ds:[bx].FOI_cursor			; get cursor
	cmp	di, NIL
	je	done					; exit if no cursor

	call	FolderLockBuffer			; lock folder buffer

	test	es:[di].FR_state, mask FRSF_SELECTED	; selected?
	jnz	unselect				; yep, then unselect

	call	SelectESDIEntry				; select it
	jmp	short unlock

unselect:
	call	UnselectESDIEntry			; unselect it
unlock:
	call	FolderUnlockBuffer
done:
	clc
	ret
FolderSelectKeysToggleIcon	endp


FolderSelectKeysToggleMultiSelect	proc	near
	class	FolderClass
	mov	ds:[bx].FOI_anchorIcon, NIL
	xor	ds:[bx].FOI_folderState, mask FOS_MULTI_SELECT_MODE
	clc
	ret
FolderSelectKeysToggleMultiSelect	endp


FolderSelectKeysSelectAll	proc	near
	class	FolderClass
	mov	ds:[bx].FOI_anchorIcon, NIL
	call	FolderSelectAll
	clc
	ret
FolderSelectKeysSelectAll	endp


FolderSelectKeysDeselectAll	proc	near
	class	FolderClass
	mov	ds:[bx].FOI_anchorIcon, NIL
	call	FolderDeselectAll
	clc
	ret
FolderSelectKeysDeselectAll	endp



	;P     C  S       C
	;h  A  t  h  S    h
	;y  l  r  f  e    a
	;s  t  l  t  t    r
if DBCS_PCGEOS

folderSelectKeysTable	KeyboardShortcut \
	<1, 0, 0, 0, C_SYS_NUMPAD_4 and mask KS_CHAR>,	;extend selection left
	<1, 0, 0, 0, C_SYS_NUMPAD_6 and mask KS_CHAR>,	;extend selection right
	<1, 0, 0, 0, C_SYS_NUMPAD_8 and mask KS_CHAR>,	;extend selection up
	<1, 0, 0, 0, C_SYS_NUMPAD_2 and mask KS_CHAR>,	;extend selection down
	<1, 0, 0, 0, C_SPACE>,			;toggle currently selected icon
	<0, 0, 0, 1, C_SYS_F8 and mask KS_CHAR>, ;toggle multi-select mode
	<1, 0, 1, 0, C_SLASH>,			;select all
	<1, 0, 1, 0, C_BACKSLASH>		;deselect all
else

folderSelectKeysTable	KeyboardShortcut \
	<1, 0, 0, 0, 0xf, VC_NUMPAD_4>,		;extend selection left
	<1, 0, 0, 0, 0xf, VC_NUMPAD_6>,		;extend selection right
	<1, 0, 0, 0, 0xf, VC_NUMPAD_8>,		;extend selection up
	<1, 0, 0, 0, 0xf, VC_NUMPAD_2>,		;extend selection down
	<1, 0, 0, 0, 0x0, C_SPACE>,		;toggle currently selected icon
	<0, 0, 0, 1, 0xf, VC_F8>,		;toggle multi-select mode
	<1, 0, 1, 0, 0x0, C_SLASH>,		;select all
	<1, 0, 1, 0, 0x0, C_BACKSLASH>		;deselect all

endif

FOLDER_SELECT_KEYS_TABLE_SIZE=($-folderSelectKeysTable)/(size KeyboardShortcut)

folderSelectKeysRoutineTable	nptr.near \
	FolderSelectKeysExtendLeft,		; Shift-Left
	FolderSelectKeysExtendRight,		; Shift-Right
	FolderSelectKeysExtendUp,		; Shift-Up
	FolderSelectKeysExtendDown,		; Shift-Down
	FolderSelectKeysToggleIcon,		; Space
	FolderSelectKeysToggleMultiSelect,	; Shift-F8
	FolderSelectKeysSelectAll,		; Ctrl-/
	FolderSelectKeysDeselectAll		; Ctrl-\

FOLDER_SELECT_KEYS_ROUTINE_TABLE_SIZE = length folderSelectKeysRoutineTable


	 ;P     C  S     C
	 ;h  A  t  h  S  h
	 ;y  l  r  f  e  a
	 ;s  t  l  t  t  r

if DBCS_PCGEOS

folderKeysTable	KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,		;previous file
	<0, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,		;next file
	<1, 0, 0, 0, C_SYS_JOYSTICK_180 and mask KS_CHAR>,	;previous file
	<1, 0, 0, 0, C_SYS_JOYSTICK_0 and mask KS_CHAR>,	;next file
	<1, 0, 0, 0, C_SYS_JOYSTICK_90 and mask KS_CHAR>,	;up file
	<1, 0, 0, 0, C_SYS_JOYSTICK_270 and mask KS_CHAR>,	;down file
	<0, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,		;up file window
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,		;down file
	<0, 0, 0, 0, C_SYS_ENTER and mask KS_CHAR>,		;open file
	<0, 0, 1, 0, C_SYS_ENTER and mask KS_CHAR>,		;open file, cls
	<1, 0, 0, 0, C_SYS_FIRE_BUTTON_1 and mask KS_CHAR>,	;open file
	<1, 0, 0, 0, C_SYS_FIRE_BUTTON_2 and mask KS_CHAR>,	;open file
	<0, 0, 0, 0, C_SYS_HOME and mask KS_CHAR>,		;home
	<0, 0, 0, 0, C_SYS_END and mask KS_CHAR>,		;end
	<0, 0, 0, 0, C_SYS_TAB and mask KS_CHAR>,		;next file
	<0, 0, 0, 1, C_SYS_TAB and mask KS_CHAR>		;previous file

else

folderKeysTable	KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_LEFT>,		;previous file
	<0, 0, 0, 0, 0xf, VC_RIGHT>,		;next file
	<1, 0, 0, 0, 0xf, VC_JOYSTICK_180>,	;previous file
	<1, 0, 0, 0, 0xf, VC_JOYSTICK_0>,	;next file
	<1, 0, 0, 0, 0xf, VC_JOYSTICK_90>,	;up file
	<1, 0, 0, 0, 0xf, VC_JOYSTICK_270>,	;down file
	<0, 0, 0, 0, 0xf, VC_UP>,		;up file window
	<0, 0, 0, 0, 0xf, VC_DOWN>,		;down file
	<0, 0, 0, 0, 0xf, VC_ENTER>,		;open file
	<0, 0, 1, 0, 0xf, VC_ENTER>,		;open file, close folder
	<1, 0, 0, 0, 0xf, VC_FIRE_BUTTON_1>,	;open file
	<1, 0, 0, 0, 0xf, VC_FIRE_BUTTON_2>,	;open file
	<0, 0, 0, 0, 0xf, VC_HOME>,		;home
	<0, 0, 0, 0, 0xf, VC_END>,		;end
	<0, 0, 0, 0, 0xf, VC_TAB>,		;next file
	<0, 0, 0, 1, 0xf, VC_TAB>		;previous file

endif

FOLDER_KEYS_TABLE_SIZE = ($-folderKeysTable)/(size KeyboardShortcut)

folderKeysRoutineTable	nptr.near \
	FolderKeyLeft,	   		; VC_LEFT
	FolderKeyRight,			; VC_RIGHT
	FolderKeyLeft,	   		; VC_JOYSTICK_180
	FolderKeyRight,			; VC_JOYSTICK_0
	FolderKeyUp,	   		; VC_JOYSTICK_90
	FolderKeyDown,			; VC_JOYSTICK_270
	FolderKeyUp,			; VC_UP
	FolderKeyDown,			; VC_DOWN
	FolderKeyEnter,			; VC_ENTER
	FolderKeyEnterClose,		; CTRL ENTER
	FolderKeyEnter,			; VC_FIRE_BUTTON_1
	FolderKeyEnter,			; VC_FIRE_BUTTON_2
	FolderKeyHome,			; VC_HOME
	FolderKeyEnd,			; VC_END
	FolderKeyRight,			; VC_TAB
	FolderKeyLeft			; Shift+VC_TAB
FOLDER_KEYS_ROUTINE_TABLE_SIZE = length folderKeysRoutineTable

folderKeysWrapTable	nptr.near \
	FolderKeyWrapLeft,		; VC_LEFT     
	FolderKeyWrapRight,		; VC_RIGHT    
	FolderKeyWrapLeft,   		; VC_JOYSTICK_180
	FolderKeyWrapRight,		; VC_JOYSTICK_0
	FolderKeyWrapUp,   		; VC_JOYSTICK_90
	FolderKeyWrapDown,		; VC_JOYSTICK_270
	FolderKeyWrapUp,		; VC_UP	      
	FolderKeyWrapDown,		; VC_DOWN     
	FolderKeyNoWrap,		; VC_ENTER    
	FolderKeyNoWrap,		; CTRL ENTER
	FolderKeyNoWrap,		; VC_FIRE_BUTTON_1    
	FolderKeyNoWrap,		; VC_FIRE_BUTTON_2    
	FolderKeyNoWrap,		; VC_HOME     
	FolderKeyNoWrap,		; VC_END      
	FolderKeyWrapRight,		; VC_TAB      
	FolderKeyWrapLeft		; Shift+VC_TAB
.assert length folderKeysWrapTable eq length folderKeysRoutineTable
.assert (size KeyboardShortcut eq size word)
.assert (FOLDER_KEYS_ROUTINE_TABLE_SIZE eq FOLDER_KEYS_TABLE_SIZE)

FolderObscure	ends
