COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		textReplace.asm

AUTHOR:		John Wedgwood, Oct  6, 1989

ROUTINES:
	Name			Description
	----			-----------
	TextReplace		Do a replacement operation.
	TextShiftChars		Make space for the text to insert.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 6/89	Initial revision

DESCRIPTION:
	Routines for handling text changes.

	$Id: textReplace.asm,v 1.1 97/04/07 11:18:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextSetReplace segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextReplace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace an area in the text stream.
		This can accomplish insertion, deletion, and replacement:
			Insertion:	Replace range of length 0 with new text
			Deletion:	Replace range of text with no new text.
			Replacement:	Replace range with new text.

CALLED BY:	VisTextReplace *only*
PASS:		*ds:si	= pointer to VisTextInstance.
		ss:bp	= VisTextReplaceParameters
		zero flag set if a paragraph attribute was nuked
RETURN:		LICL_vars updated
		dx - end of line (place to put cursor) or -1 if can't
		     optimize redraw
DESTROYED:	nothing.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/22/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextReplace	proc	far	uses	ax, bx, cx, di
	class	VisTextClass
	.enter

	pushf					; Save "para change" flag
	call	Text_DerefVis_DI
	test	ds:[di].VTI_features, mask VTF_ALLOW_UNDO
	jz	noUndo
	call	GenProcessUndoCheckIfIgnoring	;Don't create any actions if
	tst	ax				; ignoring undo
	jnz	noUndo
	call	TU_DoReplaceUndo
noUndo:
	
	call	TS_ReplaceRange			; Replace the bytes of text
	popf					; Restore "para change" flag
	lahf					; ah <- flags

	;
	; At this point we need to ensure that we have enough stack space
	; this involves saving the VisTextRange so that we can copy it to
	; the new stack
	;
	; ah	= Flags, Zero set if paragraph attribute was nuked
	;
	push	bp
	call	SwitchStackWithDataAllowingForInsertedString
						;trashes cx, dx, di, es
						;on-stack, stack-space token

	;
	; Allocate stack frame for calculation.
	;
	sub	sp, size LICL_vars
	mov	cx, sp				; ss:cx <- LICL_vars

	;
	; Check to see if line structures actually exist.
	;
	call	Text_DerefVis_DI		; ds:di <- instance
	test	ds:[di].VTI_intFlags, mask VTIF_HAS_LINES
	jz	afterLineAdjust			; Branch if it doesn't
	
	;
	; The call to TL_LineAdjustForReplacement must be made before the
	; call to TR_RegionAdjustForReplacement. If it isn't, then we
	; attempt to figure the first changed line based on the new
	; region starts rather than the old ones (as we should).
	;
	call	TL_LineAdjustForReplacement	; Update line-start info

afterLineAdjust:
	call	TR_RegionAdjustForReplacement	; Update the regions
	
	call	TextCheckCanCalcWithRange	; Check for recalc possible
	jc	done				; Skip this next part if not
	
	xchg	cx, bx				; cx.di <- First line
						; ss:bx <- LICL_vars
	;
	; Set the range to the set of inserted characters
	;
	; cx.di	= First line to calculate
	; ss:bx	= LICL_vars
	; ss:bp	= VisTextReplaceParameters
	; ah	= Flags, zero set if paragraph attribute was nuked.
	;
	sahf
	pushf					; Save "para-attr nuked" flag
	movdw	dxax, ss:[bp].VTRP_range.VTR_start
	movdw	ss:[bx].LICL_range.VTR_start, dxax

	adddw	dxax, ss:[bp].VTRP_insCount
	movdw	ss:[bx].LICL_range.VTR_end, dxax
	popf					; Zero set if para-attr nuked
	
	jnz	doRecalc
	
	;
	; A paragraph attribute was nuked, we need to compute through to
	; the end of the next paragraph. This is easy... Just start at
	; the start and find the paragraph end.
	;
	movdw	dxax, ss:[bx].LICL_range.VTR_end
	call	TSL_FindParagraphEnd		; dx.ax <- end of paragraph
	movdw	ss:[bx].LICL_range.VTR_end, dxax

doRecalc:
	;
	; TL_LineAdjustForReplacement() returns bx.di = the line on which the
	; change occurred which is (coincidentally) the line to pass
	; to TextRecalcInternal().
	;
	call	TextRecalcInternal		; Recalculate line info.
done:

	;
	; Must have the selection set correctly (as we do now) before calling.
	; TextUpdateOptimizations().
	;
	call	TextCheckCanDraw		; No update needed if we can't
	jc	setLineEnd			;   draw anyway
	call	TextUpdateOptimizations		; Attempt optimizations.
	jc	markDirty			; Quit if optimizations worked.
	add	sp, size LICL_vars		; Restore stack
						; 11/1/94: do this before update
						;  to prevent stack overflow
						;  when another of these
						;  monsters is allocated for the
						;  drawing -- ardeb
	call	TextSendUpdate			; Update the screen.
	sub	sp, size LICL_vars
setLineEnd:
	mov	dx, -1				; Not an optimized redraw.
markDirty:
	add	sp, size LICL_vars		; Restore stack

	pop	di
	add	sp, size VisTextReplaceParameters
	call	ThreadReturnStackSpace
	pop	bp

	.leave
	ret
TextReplace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwitchStackWithDataAllowingForInsertedString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab stack space, moving the VisTextReplaceParameters over
		to the new stack and updating any references if necessary.

CALLED BY:	TextReplace
PASS:		ss:bp	= Pointer to VisTextReplaceParameters to copy
RETURN:		on-stack:	stack-space token
DESTROYED:	cx, dx, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwitchStackWithDataAllowingForInsertedString	proc	near
	;
	; When we switch stacks, we will lose our own return address
	; so we need to get it now.
	;
	pop	cx				; cx <- return address

	;
	; Switch stacks, copying the parameters
	;
	mov	dx, sp				; dx <- old stack pointer
	mov	di, size VisTextReplaceParameters ; di <- size of struct
	push	di				; di <- amount to copy
	;
	; We need to adjust dx so that it contains the value that sp will
	; have at the moment that ThreadBorrowStackSpace is called.
	;
	; Since SwitchStackWithData() will pop both the amount to copy
	; and our return address, the value in dx now is correct.
	;
	call	SwitchStackWithData		; Allocate space
	pop	di				; di <- stack space token
	push	di				; Save token for caller
	push	cx				; Save return address
	
	;
	; di	= Stack-space token.
	; dx	= Old stack pointer
	;
	tst	di				; Check for switched stacks
	jz	done				; Branch if we didn't
	
	tst	<{word} ss:[bp].VTRP_insCount>	; Check for nothing inserted
	jz	done				; Branch if nothing
	
	;
	; We did switch stacks. If the replace-parameters hold a pointer
	; reference, and if that pointer reference is into the (old) stack
	; then we need to change the reference.
	;
	
	;
	; Check for a pointer into the stack
	;
	cmp	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	jne	done				; Branch if not a pointer

	;
	; Compare the pointer segment to the old stack.
	;
	mov	cx, ss
	cmp	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.segment, cx
	jne	done				; Branch if not ptr to stack
	
	;
	; Compare the pointer offset to the current old stack pointer. If it's
	; less than the old stack pointer, then it was probably in dgroup
	; somewhere (below the stack).
	;
	cmp	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.offset, dx
	jb	done

;-----------------------------------------------------------------------------
	;
	; The reference is a pointer and it is a pointer into the stack.
	;
	; Change the pointer to point at the allocated block.
	;
	; One interesting point. The offset of the string in the new block
	; is not the same as the offset it used to have in our stack.
	;
	; However the offset of the string from the stack pointer is the same
	; as the offset of the string from the base of the new block, so we
	; can take advantage of that fact.
	;
	; dx	= Old stack pointer.
	;
adjustReference::
	pop	cx				; ax <- return address
	pop	di				; di <- token

	push	di				; Save token
	push	cx				; Save return address
	
	;
	; Now... The return stack is all set up...
	;
	push	ax, bx

	mov	bx, di				; bx <- block handle
	call	MemLock				; ax <- segment of block
	mov	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.segment, ax

	sub	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.offset, dx
	
	;
	; Since the data was copied at a paragraph boundary, we need to adjust
	; the offset to compensate for data shifting around...
	;
	; Here's what's on the stack now:
	;	bx		<<-- top
	;	ax		<<-- return address
	;	di		<<-- stack space token
	;	StackFooter	<<-- from ThreadBorrowStackSpace call
	;
	mov	bx, sp
	mov	ax, ss:[bx+6].SL_savedStackPointer
	add	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.offset, ax

	pop	ax, bx
;-----------------------------------------------------------------------------

done:
	;
	; On stack:
	;	return address		<<== top
	;	stack space token
	;
	ret					; Return to address on stack
SwitchStackWithDataAllowingForInsertedString	endp


TextSetReplace ends
