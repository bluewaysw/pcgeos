COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ResEdit/Text	
FILE:		textDraw.asm

AUTHOR:		Cassie Hartzog, Oct 14, 1992

ROUTINES:
	Name			Description
	----			-----------
EXT	ResEditTextFilter	MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS

EXT	ResEditGlyphRecalcHeight
				MSG_RESEDIT_GLYPH_RECALC_HEIGHT
				Recalculates height of the glyph object after
				replacing its moniker with passed graphic.

EXT	ResEditTextRecalcHeight	MSG_RESEDIT_TEXT_RECALC_HEIGHT
				Recalculates the height of the text object
				after replacing its text with that passed in.

EXT	ResEditTextHeightNotify	Handler for MSG_META_TEXT_HEIGHT_NOTIFY

EXT	ResEditTextDraw		Handler for MSG_RESEDIT_TEXT_DRAW.
				Draws a chunk that is of type CT_TEXT

INT	ResEditTextSetMnemonicUnderline MSG_RESEDIT_TEXT_SET_MNEMONIC_UNDERLINE
				Gets the mnemonic position and sets the 
				text style to underline the mnemonic.

EXT	ResEditTextSetUnderline	MSG_RESEDIT_TEXT_SET_UNDERLINE
				Underlines a character at the passed position.

EXT	ResEditTextClearUnderline MSG_RESEDIT_TEXT_CLEAR_UNDERLINE
				Clears the underline from all characters.

EXT	ResEditTextSetAttrs	MSG_RESEDIT_TEXT_SET_STATE
				Changes the text VI_attrs field.

EXT	ResEditTextMouseMove	A pointer event has occurred.  Let the
				superclass handle it, set selection state in
				the document.

EXT	ResEditTextGetCharacter	MSG_RESEDIT_TEXT_GET_CHARACTER
				Returns the character at the passed offset.

EXT	ResEditTextGetSize	MSG_RESEDIT_TEXT_GET_SIZE
				Returns the number of characters in the text.

EXT	ResEditTextSetText	Change the text, size, position of a 
				text object.

EXT	ResEditTextSaveText	Save the text from the object to a DB Item.

EXT	ResEditTextSetState	Sets and clears the VisTextState bits.

INT	CopyVisMoniker		Copies VisMoniker structures to the new 
				or resized translation item.

INT	SaveNewMnemonic		Copies the new mnemonic to the translation 
				item.

INT	SaveNewText		Copies the new text to the translation item.

INT	AllocNewTransItem	Allocates/reallocates a translation item.

INT	ResEditTextSaveTextNotMoniker 
				Saves an edited text item which is NOT a 
				moniker to a translation item.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cassie	10/14/92	Initial revision

DESCRIPTION:
	This file contains the code for drawing the text objects.

	$Id: textDraw.asm,v 1.1 97/04/04 17:13:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextDrawCode	segment	resource

TextDraw_ObjMessage_call	proc	near
	ForceRef TextDraw_ObjMessage_call
	push	di
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di
	ret
TextDraw_ObjMessage_call	endp

TextDraw_ObjCallInstanceNoLock_saveBP	proc	near
	push	bp
	call	ObjCallInstanceNoLock
	pop	bp
	ret
TextDraw_ObjCallInstanceNoLock_saveBP	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditGlyphRecalcHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the height of the passed bitmap/gstring
		for PosArray.

CALLED BY:	(EXTERNAL) RecalcChunkHeight

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditGlyphClass
		ax - the message
		ss:bp - SetDataParams

RETURN:		dx - height

DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, bp

PSEUDO CODE/STRATEGY:
	If the item contains a bitmap, call GrGetBitmapSize. 
	Else replace HeightGlyph object's VisMoniker with the data 
	that is in the passed chunk.  Then call VisGetMonikerSize.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditGlyphRecalcHeight		method dynamic ResEditGlyphClass,
					MSG_RESEDIT_GLYPH_RECALC_HEIGHT

	mov	di, bp					;ss:di <- SetDataParams
	sub	sp, size ReplaceVisMonikerFrame
	mov	bp, sp

	mov	dl, ss:[di].SDP_chunkType
	mov	bx, ss:[di].SDP_file
	mov	ax, ss:[di].SDP_group			;ax <- group number
	mov	di, ss:[di].SDP_item			;di <- item number
	call	DBLock					;*es:di <-ResArray

	push	ds:[LMBH_handle], si			;save glyph OD
	segmov	ds, es
	mov	si, ds:[di]				;ds:si <- chunk data
	ChunkSizePtr	ds, si, cx

	test	dl, mask CT_BITMAP
	jz	notBitmap
	call	GrGetBitmapSize	
	mov	dx, bx
	call	DBUnlock_DS				;unlock DBItem
	add	sp, 4					;clear the stack
	jmp	done

notBitmap:
	mov	di, si					;ds:di <- chunk data
	pop	bx, si
	test	dl, mask CT_TEXT
	jz	itsGString
	add	di, MONIKER_TEXT_OFFSET
	jmp	itsText
itsGString:
	add	di, offset VM_data
	mov	dx, ds:[di].VMGS_height
	tst	dx
	jnz	haveHeight
	sub	di, offset VM_data
	add	di, MONIKER_GSTRING_OFFSET
itsText:
	movdw	ss:[bp].RVMF_source, dsdi
	mov	ss:[bp].RVMF_sourceType, VMST_FPTR
	clr	ss:[bp].RVMF_width			;if gstring, compute
	clr	ss:[bp].RVMF_height			; width and height
	mov	ss:[bp].RVMF_length, cx			;# of bytes in gstring
	mov	ss:[bp].RVMF_updateMode, VUM_NOW
	mov	ss:[bp].RVMF_dataType, VMDT_GSTRING	;it's a gstring

	segmov	es, ds					;save DBItem segment
	call	MemDerefDS				;*ds:si <- Glyph object
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	call	ObjCallInstanceNoLock
	call	DBUnlock			;unlock DBItem in es

	clr	di				;no window for gstate
	call	GrCreateState	
	mov	bp, di				;^hbp <- gstate

	clr	ax				;get font size from gstate
	mov	di, ds:[si]			;*ds:si <- glyph object
	add	di, ds:[di].Gen_offset
	segmov	es, ds
	mov	di, es:[di].GI_visMoniker	;*es:di <- moniker
	call	VisGetMonikerSize		; dx <- new height	

	mov	di, bp
	call	GrDestroyState

checkDX:
EC <	test	dx, 0xff00			>
EC <	jz	done				>
EC <	mov	dx, 5				>

done:
	add	sp, size ReplaceVisMonikerFrame
	ret

haveHeight:
	call	DBUnlock_DS
	jmp	checkDX

ResEditGlyphRecalcHeight		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextRecalcHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The text object needs to recalculate its height,
		with the text in the passed db item.

CALLED BY:	RecalcChunkHeight

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ss:bp	- SetDataParams

RETURN:		dx	- height

DESTROYED:	ax, bx, si, di, ds, es (method handler)
		cx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextRecalcHeight		method dynamic ResEditTextClass,
						MSG_RESEDIT_TEXT_RECALC_HEIGHT

	call	ReplaceText

	; calculate the height of the text object with the new text
	;
	mov	cx, ss:[bp].SDP_width
	clr	dx				; don't cache height
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
	call	ObjCallInstanceNoLock		; dx <- new height	

	ret
ResEditTextRecalcHeight		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The height of a text object has changed.  

CALLED BY:	UI - MSG_VIS_TEXT_HEIGHT_NOTIFY
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message
		dx - new height

RETURN:		nothing
DESTROYED:	ax, bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	If it is the EditText object whose size has changed, let the
	document handle the resizing and redrawing.  Don't care if
	other text object size has changed, since they aren't drawable.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextHeightNotify		method dynamic ResEditTextClass,
						MSG_VIS_TEXT_HEIGHT_NOTIFY
	cmp	ds:[di].RETI_type, RETT_EDIT
	jne	done
	mov	ax, MSG_RESEDIT_DOCUMENT_HEIGHT_NOTIFY
	call	VisCallParent
done:
	ret
ResEditTextHeightNotify		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Text is about to be entered into EditText.  
		First remove all underline, then restore the mnemonic 
		underline.

CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message
		ss:bp - VisTextReplaceParameters
RETURN:		carry set to reject replacement.
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/31/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextFilter		method dynamic ResEditTextClass,
				MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS

	push	bp
	movdw	dxax, ss:[bp].VTRP_insCount
	mov	ch, ds:[di].RETI_style		; ch <- TextStyle
	mov	cl, ds:[di].RETI_mnemonic	; cl <- old mnemonic
	lea	bp, ss:[bp].VTRP_range
	call	CalculateNewMnemonicOffset	; cl <- new mnemonic offset
	mov	ds:[di].RETI_mnemonic, cl	; cl <- old mnemonic
	pop	bp

	mov	ax, MSG_RESEDIT_TEXT_FILTER_VIA_REPLACE_PARAMS
	mov	dx, size VisTextReplaceParameters
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE \
			or mask MF_REPLACE
	mov	bx, ds:[LMBH_handle]		; ^lbx:si <- this text object
	call	ObjMessage
	clc					; carry clear to do replacement

	ret
ResEditTextFilter		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateNewMnemonicOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Text is being modified.  Calculate what the new mnemonic
		offset is, based on the text being replaced, what it is
		being replaced with, and the offset of the old mnemonic.

CALLED BY:	HandleReplaceMatch, ResEditTextFilterViaReplaceParams
PASS:		ss:bp	- VisTextRange of text to replace
		dx:ax	- count of chars in replace text
		cl	- (character) offset of mnemonic character 
		ch	- current TextStyle

RETURN:		cl	- new offset of mnemonic character, or
		  	- VMO_NO_MNEMONIC if no longer a mnemonic
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	There are three cases we must worry about here:
	    (1) mnemonic lies before text being replaced
	    (2) mnemonic lies after text being replaced
	    (3) mnemonic lies within text being replaced

	In case (1), the mnemonic will not change.
	In case (2), the mnemonic will move by an amount equal to its
	   old position - size of text being replaced + size of new text.
	In case (3), the mnemonic char is being replaced, so remove the
	   mnemonic.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateNewMnemonicOffset		proc	far
	.enter

	test	ch, mask TS_UNDERLINE
	jz	noMnemonic

	;
	; (1) Check if the mnemonic lies before the replace range.
	;
	clr	ch				; cx <- offset of old char
	tst	ss:[bp].VTR_start.high	
	jnz	done				; high word != 0, cx < start
	cmp	cx, ss:[bp].VTR_start.low	
	jb	done				; cx < start, no change
	;
	; (3) Check if the mnemonic lies within the replace range.
	;
	; The mnemonic char comes after the start of the replace range.
	; See if the mnemonic char comes before the end of the range.
	; Note that the mnemonic char itself extends across a range of 1,
	; from cx to cx+1.  Therefore, if it is to lie within the range,
	; the start of the mnemonic char's range must be strictly less 
	; than VTR_end.
	;
	tst	ss:[bp].VTR_end.high	
	jnz	noMnemonic			; high word set, cx < end
	cmp	cx, ss:[bp].VTR_end.low
	jb	noMnemonic			; cx < end, mnemonic in range
	;
	; (2) Only remaining possibility is that the replace range 
	;     comes after the mnemonic character.
	;
	; Subtract size of range from the mnemonic char's old position.
	;
	sub	cx, ss:[bp].VTR_end.low	
	add	cx, ss:[bp].VTR_start.low	;cx = cx - (end-start)
	;
	;
	; Add the number of characters being inserted to get the new
	; position of the mnemonic.  Make sure the new offset is valid
	; by testing whether it is so large that it could be interpreted
	; as one of the VMO constants.
	; 
.assert ( VMO_CANCEL lt VMO_MNEMONIC_NOT_IN_MKR_TEXT )
.assert ( VMO_CANCEL lt VMO_NO_MNEMONIC )
	tst	dx				; if too many chars being
	jnz	noMnemonic			;   added, can't be mnemonic
	add	cx, ax
	cmp	cx, VMO_CANCEL
	jae	noMnemonic

done:
	.leave
	ret

noMnemonic:
	mov	cl, VMO_NO_MNEMONIC
	jmp	done

CalculateNewMnemonicOffset		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextFilterViaReplaceParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Text has been entered into EditText.  Update the
		mnemonic underline.

CALLED BY:	MSG_RESEDIT_TEXT_FILTER_VIA_REPLACE_PARAMS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message
		cl - offset of new mnemonic char
		   -or- VMO_NO_MNEMONIC if none

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/31/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextFilterViaReplaceParams	method dynamic ResEditTextClass,
				MSG_RESEDIT_TEXT_FILTER_VIA_REPLACE_PARAMS

	;
	; Suspend text recalculation
	;
	push	cx, bp
	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock
	pop	cx, bp

	;
	; To simplify matters, call TextClearUnderline with TS_UNDERLINE
	; set to remove all underlining from old AND inserted text. 
	; 
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].RETI_style, mask TS_UNDERLINE
	call	ResEditTextClearUnderline	; clear any residual underline

	;
	; If there is no mnemonic now, don't set any underline
	;
SBCS <	clr	dl 				; assume no mnemonic char	>
DBCS <	clr	dx							>
	cmp	cl, VMO_NO_MNEMONIC
	je	done

	;
	; Else there is a mnemonic, draw the underline now.
	;
	call	ResEditTextSetUnderline		; cl <- offset of mnemonic

	; 
	; Get the actual mnemonic character to pass to the document.
	;
	push	cx
	clr	ch				; cx <- offset of char to get
	call	ResEditTextGetCharacter
SBCS <	mov	dl, cl				; dl <- mnemonic char	>
DBCS <	mov	dx, cx							>
	pop	cx

done:
	;
	; Notify the document that the text/mnemonic have changed.
	;     pass: 	cl - offset of mnemonic char
	;		dl (dx) - mnemonic char
EC<	call	AssertIsResEditText			>
EC<	cmp	si, offset EditText			>
EC<	ERROR_NE RESEDIT_INTERNAL_LOGIC_ERROR		>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ch, ds:[di].RETI_style		; ch <- TextStyle
	mov	ax, MSG_RESEDIT_DOCUMENT_USER_MODIFIED_TEXT
	call	VisCallParent

	;
	; Resume text recalculation.
	;
	mov	ax, MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	ret
ResEditTextFilterViaReplaceParams		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The text object needs to update itself and then draw.

CALLED BY:	VisDrawCallback
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message
		ss:bp	= VisDrawParams

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,ds,es 

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextDraw		method dynamic ResEditTextClass,
						MSG_RESEDIT_TEXT_DRAW

	;
	; make the object not drawable while it is updated to 
	; draw this new chunk
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].VI_attrs, not (mask VA_DRAWABLE)

	;
	; replace the text, change the object's size and position
	;
	push	bp
	lea	bp, ss:[bp].VDP_data
	call	ResEditTextSetText

	;
	; set the style to underline the mnemonic character
	;
	call	ResEditTextSetMnemonicUnderline

	;
	; make the object drawable again
	;
EC<	call	AssertIsResEditText			>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].VI_attrs, mask VA_DRAWABLE

	; draw the object
	;
	pop	bx
	mov	bp, ss:[bx].VDP_gstate
	mov	cl, ss:[bx].VDP_drawFlags
	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLock
	mov	bp, bx				;ss:bp <- VisDrawParams

	ret
ResEditTextDraw		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextSetMnemonicUnderline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When drawing a text object, set the underline for the
		mnemonic character.

CALLED BY:	MSG_RESEDIT_TEXT_SET_MNEMONIC_UNDERLINE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message
		ss:bp	- SetDataParams

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextSetMnemonicUnderline		method ResEditTextClass,
;;; fix: the check is silly
				MSG_RESEDIT_TEXT_SET_MNEMONIC_UNDERLINE

	; If this is not a moniker, don't underline anything
	;
	test	ss:[bp].SDP_chunkType, mask CT_MONIKER
	jz	done

	;
	; Now figure out what to underline.  If the mnemonic character
	; is after the text, don't need to underline anything.
	;
	cmp	ss:[bp].SDP_mnemonicType, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	je	done

	;
	; Given the mnemonic type and mnemonic count, get the
	; position of this moniker's mnemonic in the Mnemonic List
	; 
	mov	al, ss:[bp].SDP_mnemonicType
	mov	cl, ss:[bp].SDP_mnemonicCount
	call	GetMnemonicPosition		;al <- position in list
;;FIXME	;; this just subtracts two unless it's a VMO_ (checked for above)

	;
	; If the mnemonic is position 0 (NIL) or 1 (ESC), don't
	; need to underline anything.
	;
	cmp	al, 2
	jb	done
	sub	al, 2
	clr	ah
	mov	cx, ax				;offset where underline starts

	call	ResEditTextSetUnderline

	; set the underline flag
	;
EC<	call	AssertIsResEditText			>
	mov	di, ds:[si]
	add	di, ds:[di].ResEditText_offset
	ornf	ds:[di].RETI_style, mask TS_UNDERLINE
	mov	ds:[di].RETI_mnemonic, cl

done:
	ret

ResEditTextSetMnemonicUnderline		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextSetUnderline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the underline for the mnemonic character.

CALLED BY:	(EXTERNAL) - DocumentChangeMnemonic

PASS:		*ds:si - instance data
		es - seg addr of ResEditTextClass
		ax - the message
		cl - (character) offset in text to underline

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
		ax,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextSetUnderline			method ResEditTextClass,
					MSG_RESEDIT_TEXT_SET_UNDERLINE
	uses	cx, bp
	.enter

EC<	call	AssertIsResEditText			>

	mov	di, ds:[si]
	add	di, ds:[di].ResEditText_offset
	ornf	ds:[di].RETI_style, mask TS_UNDERLINE
	mov	ds:[di].RETI_mnemonic, cl

	sub	sp, size VisTextSetTextStyleParams
	mov	bp, sp
	clr	ss:[bp].VTSTSP_extendedBitsToSet
	clr	ss:[bp].VTSTSP_extendedBitsToClear

	mov	ss:[bp].VTSTSP_styleBitsToSet, mask TS_UNDERLINE
	clr	ss:[bp].VTSTSP_styleBitsToClear
	
	;
	; set dx to point to the end of the 1-character range to underline
	;
	clr	ch
	mov	dx, cx
	inc	dx

EC <	mov	ax, MSG_RESEDIT_TEXT_GET_SIZE				>
EC <	call	ObjCallInstanceNoLock		;cx = # of characters 	>
EC <	cmp	dx, cx							>
EC <	ERROR_A POSITION_OUT_OF_RANGE					>

	clr	ax
	movdw	ss:[bp].VTSTSP_range.VTR_end, axdx
	dec	dx
	movdw	ss:[bp].VTSTSP_range.VTR_start, axdx

	mov	dx, size VisTextSetTextStyleParams
	mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
	call	ObjCallInstanceNoLock

	add	sp, size VisTextSetTextStyleParams

	.leave
	ret
ResEditTextSetUnderline	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextClearUnderline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the mnemonic is changing, need to clear the old
		underline from the text.  

CALLED BY:	MSG_RESEDIT_TEXT_CLEAR_UNDERLINE
PASS:		*ds:si - instance data
		es - seg addr of ResEditTextClass
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextClearUnderline		method ResEditTextClass,
					MSG_RESEDIT_TEXT_CLEAR_UNDERLINE
	uses	cx,dx,bp
	.enter

EC<	call	AssertIsResEditText			>

	; if the underline flag is not set, nothing is underlined, so
	; there is no need to clear it
	;
	mov	di, ds:[si]
	add	di, ds:[di].ResEditText_offset
	test	ds:[di].RETI_style, mask TS_UNDERLINE
	jz	noUnderline

	; 
	; allocate the VTSTSP structure on the stack and fill it in
	;
	sub	sp, size VisTextSetTextStyleParams
	mov	bp, sp

	clr	ss:[bp].VTSTSP_extendedBitsToSet
	clr	ss:[bp].VTSTSP_extendedBitsToClear
	clr	ss:[bp].VTSTSP_styleBitsToSet
	mov	ss:[bp].VTSTSP_styleBitsToClear, mask TS_UNDERLINE

	mov	ax, MSG_RESEDIT_TEXT_GET_SIZE				
	call	ObjCallInstanceNoLock			;cx = # of characters

	clr	ax
	movdw	ss:[bp].VTSTSP_range.VTR_end, axcx
	clr	cx
	movdw	ss:[bp].VTSTSP_range.VTR_start, axcx

	mov	dx, size VisTextSetTextStyleParams
	mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
	call	ObjCallInstanceNoLock

	add	sp, size VisTextSetTextStyleParams

	;
	; clear the underline flag and mnemonic char's offset
	;
EC<	call	AssertIsResEditText			>
	mov	di, ds:[si]
	add	di, ds:[di].ResEditText_offset
	andnf	ds:[di].RETI_style, not (mask TS_UNDERLINE)
	clr	ds:[di].RETI_mnemonic

noUnderline:
	.leave
	ret

ResEditTextClearUnderline		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextSetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set and clear the VisAttrs flags.

CALLED BY:	MSG_RESEDIT_TEXT_SET_ATTRS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message
		cl - bits to set
		ch - bits to clear
RETURN:		
DESTROYED:	cx, bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextSetAttrs		method dynamic ResEditTextClass,
						MSG_RESEDIT_TEXT_SET_ATTRS

	not	ch
	and	ds:[di].VI_attrs, ch
	or	ds:[di].VI_attrs, cl

	ret
ResEditTextSetAttrs		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextGetCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the character at the requested offset into the text.

CALLED BY:	MSG_RESEDIT_TEXT_GET_CHARACTER

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message
		cx - (character) offset

RETURN:		cl - character, (cx in dbcs) or 
		     -1 if the offset is out of range

DESTROYED:	si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextGetCharacter		method ResEditTextClass,
					MSG_RESEDIT_TEXT_GET_CHARACTER
	uses	bx,si
	.enter

EC<	call	AssertIsResEditText			>
DBCS <	shl	cx, 1				;convert to byte offset	>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].VTI_text
	mov	si, ds:[si]			;ds:si <- text
	ChunkSizePtr	ds, si, bx
	dec	bx				;subtract the null character
DBCS <	dec	bx				; one more for dbcs	>

	cmp	cx, bx				;is offset out of bounds?
	ja	outOfBounds
	add	si, cx
SBCS <	mov	cl, {byte}ds:[si]					>
DBCS <	mov	cx, {word}ds:[si]					>

done:
	.leave
	ret

outOfBounds:
SBCS <	mov	cl, -1							>
DBCS <	mov	cx, -1							>
	jmp	done

ResEditTextGetCharacter		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextFindCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first occurrence of the passed character.

CALLED BY:	MSG_RESEDIT_TEXT_FIND_CHARACTER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClassClass
		ax - the message
		cl - character to find (cx in DBCS)
RETURN:		cx - offset of character (in characters), 
			-1 if not found
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextFindCharacter		method dynamic ResEditTextClass,
					MSG_RESEDIT_TEXT_FIND_CHARACTER
	uses	dx, bp
	.enter

	segmov	es, ds, ax
	mov	di, es:[di].VTI_text
	mov	di, es:[di]		; es:di <- string to search
	mov	bp, di			; es:bp <- start at first char

	ChunkSizePtr	es, di, bx	; bx <- length of string w/null
	dec	bx
DBCS <	dec	bx							>
	mov	dx, bx			; dx <- length of string w/o null
DBCS <	shr	dx, 1			; dx <- # of chars w/o null	>
	dec	bx			; offset of last byte
DBCS <	dec	bx			; offset of last char		>
	add	bx, di			; es:bx <- last char to search

	;
	; put the search string on the stack; point ds:si at it.
	;
SBCS <	clr	ch							>
	push	cx
	mov	si, sp
	segmov	ds, ss, ax		; ds:si <- char to find
	mov	cx, 1			; cs <- # chars in search string

	mov	al, mask SO_NO_WILDCARDS or mask SO_PARTIAL_WORD
	call	TextSearchInString	; es:di <- string found
	mov	cx, -1			; assume no match
	jc	done

	mov	cx, di			; cx <- ptr to matching char
	sub	cx, bp			; cx <- byte offset to matching char
DBCS <	shr	cx, 1			; cx <- offset in characters	>

done:	
	add	sp, 2			; take the search string off
	.leave
	ret
ResEditTextFindCharacter		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextGetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of characters in the text string, not
		including the NULL.  Should be thought of as
		ResEditTextGetLength.

CALLED BY:	MSG_RESEDIT_TEXT_GET_SIZE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message

RETURN:		cx - number of characters
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextGetSize		method dynamic ResEditTextClass,
						MSG_RESEDIT_TEXT_GET_SIZE
	push	si
	mov	si, ds:[di].VTI_text
	mov	di, ds:[si]			;ds:si <- text
	segmov	es, ds

	call	LocalStringLength		;cx <- # of characters
						; not counting the NULL
	pop	si
	ret
ResEditTextGetSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reposition the text object to the chunk's location, 
		add its text as	my text.

CALLED BY:	MSG_RESEDIT_TEXT_SET_TEXT, ResEditTextDraw

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditTextClass
		ax - the message
		ss:bp	- SetDataParams

RETURN:		nothing

DESTROYED:	ax,bx,si,di,ds,es (by method handler)

PSEUDO CODE/STRATEGY:
	If it is a text moniker that has a mnemonic which comes after
	the moniker text, subtract another byte from the string length
	before using it to replace the VisMoniker.

	Set the max length of the text to the passed value, if it is
	non-zero.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextSetText	method  ResEditTextClass, MSG_RESEDIT_TEXT_SET_TEXT
	uses	cx,dx,bp
	.enter

	; clear any residual underlines
	;
	call	ResEditTextClearUnderline

EC<	call	AssertIsResEditText			>

	; set the top, left coordinates of the text object,
	; leaving a boundary for the select rectangle
	;
	mov	cx, ss:[bp].SDP_left
	mov	dx, ss:[bp].SDP_top
	add	dx, ss:[bp].SDP_border		;move top down
	mov	ax, MSG_VIS_SET_POSITION
	call	TextDraw_ObjCallInstanceNoLock_saveBP

	; set the object size according to chunk size
	;
	mov	cx, ss:[bp].SDP_width
	mov	dx, ss:[bp].SDP_height
	sub	dx, SELECT_LINE_WIDTH
	mov	ax, MSG_VIS_SET_SIZE
	call	TextDraw_ObjCallInstanceNoLock_saveBP

	; set the max length of the text, if a length was given in 
	; the localization instructions.
	;
	mov	cx, ss:[bp].SDP_maxLength
	tst	cx
	jnz	setMax
	mov	cx, -1					; no max
setMax:
	mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
	push	bp
	call	ObjCallInstanceNoLock
	pop	bp

	call	ReplaceText

	.leave
	ret

ResEditTextSetText		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace Text in text object with text from chunk.

CALLED BY:	INTERNAL - ResEditTextSetText, ResEditTextRecalcHeight
PASS:		*ds:si - text object
		ss:bp - SetDataParams
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,es
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceText		proc	near
	uses	bp
	.enter

	mov	dl, ss:[bp].SDP_chunkType

	; lock the db item that holds the text
	;
	mov	dh, ss:[bp].SDP_mnemonicType
	mov	bx, ss:[bp].SDP_file
	mov	ax, ss:[bp].SDP_group
	mov	di, ss:[bp].SDP_item
	call	DBLock
	mov	di, es:[di]				;es:di <- data
	mov	bp, di					

	test	dl, mask CT_OBJECT
	jz	notObject
	; 
	; OrigItems for objects store the KeyboardShortcut after the
	; textual representation, while transItems do not.
	; Get the string length by looking for NULL.
	;
	; FIXME: change Release20X to use LocalStringLength and nuke this...
	;
if DBCS_PCGEOS
	call	LocalStringLength
else
	mov	al, 0			; look for NULL
	mov	cx, -1			; keep looking until it is found
	repne	scasb		
	not	cx			; cx <- string length
	dec	cx			; don't count the NULL
endif
	jmp	replace

notObject:
	;
	; if it is a moniker, get size of text alone.  Don't count the size of
	; the mnemonic after the text, if it exists.
	;
	ChunkSizePtr	es, di, cx
	test	dl, mask CT_MONIKER
	jz	findNull
	add	bp, MONIKER_TEXT_OFFSET			;es:bp <- text
	sub	cx, MONIKER_TEXT_OFFSET			;cx <- text size
	cmp	es:[di].VM_data.VMT_mnemonicOffset, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	findNull
SBCS <	sub	cx, 1							>
DBCS <	sub	cx, 2							>
findNull:
	;
	; Check if string is NULL-terimnated, and if so, subtract
	; the NULL from the string length.
	;
	mov	di, bp
	add	di, cx				; es:di points off the end
DBCS <	shr	cx, 1				; cx <- text length	>
	LocalPrevChar	esdi
SBCS <	tst	{byte}es:[di]						>
DBCS <	tst	{word}es:[di]						>
	jnz	replace
	dec	cx				;subtract NULL from length

replace:
	;
	; replace the text with the chunk in the passed item
	;
	mov	dx, es					;dx:bp <- text
EC<	call	CheckForNull				>
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock
	call	DBUnlock

	.leave
	ret
ReplaceText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextSaveText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the text from the object to a DB Item.

CALLED BY:	MSG_RESEDIT_TEXT_SAVE_TEXT
PASS:		*ds:si - instance data
		ds:di 	- *ds:si
		es 	- seg addr of ResEditTextClass
		ax 	- the message
		ss:bp	- SetDataParams
		cx	- original item number

RETURN:		cx	- new item number, or
			  0 if not modified
		dh,dl	- mnemonicType, mnemonicChar (SBCS)
		ah,dx	- mnemonicType, mnemonicChar (DBCS)

DESTROYED:	ax, bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	Allocate or resize the dbitem, by calling AllocNewTransItem,
	passing the new size.  This size must include room for the
	text, VisMoniker structure if necessary, and an extra byte (word)
	for a mnemonic not in the moniker text, if there is one.

	The database item needs to be updated if either the text
	object has been user modified, or the mnemonic has been
	modified.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextSaveText		method dynamic ResEditTextClass,
						MSG_RESEDIT_TEXT_SAVE_TEXT
	.enter

	test	ss:[bp].SDP_chunkType, mask CT_MONIKER
	LONG	jz	notMoniker

	; make room for VisMoniker buffer first
	;
	sub	sp, MONIKER_TEXT_OFFSET
	mov	di, sp				;es:di <- buffer

	push	cx
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	ObjCallInstanceNoLock		;dx:ax <- # chars in text
EC <	tst	dx					>
EC <	ERROR_NZ TEXT_SIZE_IS_TOO_LARGE_FOR_DBITEM 	>
DBCS <	shl	ax, 1				;ax <- size of text	>
DBCS <	ERROR_C TEXT_SIZE_IS_TOO_LARGE_FOR_DBITEM	>
	pop	dx				;dx <- OrigItem number

	; add the null and room for the VisMoniker structures 
	;
SBCS <	add	ax, (MONIKER_TEXT_OFFSET+1)				>
DBCS <	add	ax, (MONIKER_TEXT_OFFSET+2)				>
	mov	cx, ax

	; add the room for mnemonic char if it comes after text
	;
	cmp	ss:[bp].SDP_mnemonicType, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	noExtra
	inc	cx				;add room for extra byte
DBCS <	inc	cx				;add room for extra word>

noExtra:
	;
	; copy the item's VisMoniker structures into buffer
	;
	segmov	es, ss				;es:di <- buffer
	call	CopyVisMoniker

	;
	; AllocNewTransItem returns cx = 0 if the new transItem is
	; the same size as the old.
	;
	push	ax, di				;save mnemonic, buffer ptr
	mov	bx, ss:[bp].SDP_file
	mov	ax, ss:[bp].SDP_group		;ax <- resource group
	mov	di, ss:[bp].SDP_item		;di <- trans item, if one
	call	AllocNewTransItem		;cx <- new item
	pop	ax, di

	;
	; Save the new text
	;
	call	SaveNewText

	;
	; Save the new mnemonic.
	; DBCS: return mnemonicType in ah since mnemonicChar takes up all of dx
	;
SBCS <	mov	al, ss:[bp].SDP_mnemonicChar				>
DBCS <	mov	dx, ss:[bp].SDP_mnemonicChar				>
DBCS <	clr	al				;for safety		>
	mov	ah, ss:[bp].SDP_mnemonicType
	call	SaveNewMnemonic
SBCS <	mov	dx, ax				;return mnemonic in dx	>

	add	sp, MONIKER_TEXT_OFFSET

done:
	.leave
	ret

notMoniker:
	call	ResEditTextSaveTextNotMoniker
	jmp	done

ResEditTextSaveText		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyVisMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to save the VisMoniker structure from the source
		item before it is possibly resized, so that it can be
		copied to the destination item correctly.

CALLED BY:	TextSaveText
PASS:		es:di 	- buffer
		ss:bp	- SetDataParams
		dx	- OrigItem

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyVisMoniker		proc	near
	uses	ax,bx,cx,si,di,ds
	.enter

	push	di
	mov	di, ss:[bp].SDP_item
	mov	ax, ss:[bp].SDP_group
	mov	bx, ss:[bp].SDP_file
	tst	di
	jnz	haveItem
	mov	di, dx
haveItem:
	call	DBLock_DS
	mov	si, ds:[si]				;ds:si <- source
	pop	di					;es:di <- destination

	mov	cx, MONIKER_TEXT_OFFSET
	rep	movsb

	call	DBUnlock_DS
	.leave
	ret
CopyVisMoniker		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The mnemonic has been changed.  
		Save the new mnemonic to the translation item.

CALLED BY:	TextSaveText

PASS:		*ds:si	- ResEditText instance data
		ds:di	- ResEditText instance data
		ss:bp	- SetDataParams
		cx	- translation item to save text into
		ah	- offset of mnemonic, or
				  VMO_CANCEL, or
				  VMO_NO_MNEMONIC, or
				  VMO_MNEMONIC_NOT_IN_MKR_TEXT
		al = mnemonic char (SBCS)
		dx = mnemonic char (DBCS)

RETURN:		nothing

DESTROYED:	bx,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewMnemonic		proc	near
	uses	si,di
	.enter

	push	ax
DBCS <	push	dx			; save the mnemonic char	>
	mov	di, cx
	mov	ax, ss:[bp].SDP_group
	mov	bx, ss:[bp].SDP_file
	call	DBLock
	call	DBDirty
	mov	di, es:[di]
	mov	si, di
	ChunkSizePtr	es, di, bx
DBCS <	pop	dx			; restore the mnemonic char	>
	pop	ax

	; save the new mnemonicOffset
	;
	add	di, offset VM_data + offset VMT_mnemonicOffset
	mov	{byte}es:[di], ah

	; if mnemonic comes after text, save that byte (word), too
	;
	cmp	ah, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	done
	add	si, bx				
	LocalPrevChar	essi			;es:si <- last char in moniker
SBCS <	mov	{byte}es:[si], al					>
DBCS <	mov	{word}es:[si], dx					>

done:
	call	DBUnlock

	.leave
	ret
SaveNewMnemonic		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EditText has been modified.

CALLED BY:	TextSaveText, TextSaveTextNotMoniker

PASS:		*ds:si	- ResEditText instance data
		es:di	- buffer holding VisMoniker structures
		ss:bp	- SetDataParams
		cx	- translation item to save text into

RETURN:		nothing

DESTROYED:	bx,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewText		proc	near
	uses	ax,cx,si,ds
	.enter

	push	si, ds
	segmov	ds, es
	mov	si, di					;ds:si <- VisMoniker

	; lock the item into which text will be saved
	;
	mov	di, cx
	mov	ax, ss:[bp].SDP_group
	mov	bx, ss:[bp].SDP_file
	call	DBLock
	call	DBDirty
	mov	di, es:[di]

EC <	ChunkSizePtr	es, di, bx		>

	test	ss:[bp].SDP_chunkType, mask CT_MONIKER
	jz	notMoniker

	; copy the moniker stuff now
	;
	mov	cx, MONIKER_TEXT_OFFSET			
EC <	sub	bx, cx				>	
;EC <	dec	bx				>	;bx <- size of text
	rep	movsb

notMoniker:
	pop	si, ds					;*ds:si <- text object

	; read the text into the item
	;
	push	bp
	mov	dx, es					;dx:bp <- text buffer
	mov	bp, di
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjCallInstanceNoLock			;cx <- string length
	pop	bp

;
; does the allocated chunk size (bx) gibe with the string length?
;
EC <	cmp	ss:[bp].SDP_mnemonicType, VMO_MNEMONIC_NOT_IN_MKR_TEXT >
EC <	je	noCheck				>	;too complicated
EC <	inc	cx				>	;add null to length
if DBCS_PCGEOS
EC <	shl	cx, 1				>	;convert length to size
endif
EC <	cmp	bx, cx				>	
EC <	ERROR_NE TEXT_SIZE_DOES_NOT_MATCH_CHUNK_SIZE	>
EC < noCheck:					>

	call	DBUnlock

	.leave
	ret
SaveNewText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocNewTransItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The text object has been modified, need to allocate or
		reallocate the translation item.		

CALLED BY:	EXTERNAL (TextSaveText, TextSaveTextNotMoniker,)

PASS:		cx	- size of item
		dx	- original item number
		di	- translation item number
		ax	- resource group number
		^hbx	- file handle

RETURN:		cx	- item number
		carry set if size changed


DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocNewTransItem		proc	far
	uses	ax,bx,dx,di,es
	.enter

	; if there is no translation item yet, have to allocate one
	;
	tst	di
	jnz	haveItem
	mov	di, dx

	; allocate an item of the right size
	;
	call	DBAlloc				;di <- item
	mov	cx, di				;cx <- new TransItem
	stc					;size changed
done:
	.leave	
	ret

haveItem:
	; lock the translation chunk, get its size
	;
	push	di
	call	DBLock
	ChunkSizeHandle	es, di, dx
	call	DBUnlock
	pop	di

	; compare size of the chunk to size needed. If the same,
	; don't need to reallocate.
	;
	cmp	dx, cx
	jne	haveChunk
	mov	cx, di				;cx <- old transItem
	clc					;size didn't change
	jmp	done
	
haveChunk:
	call	DBReAlloc
	mov	cx, di				;cx <- realloc'd transItem
	stc					;size changed
	jmp	done

AllocNewTransItem		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditTextSaveTextNotMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save any changes to text object to database item.

CALLED BY:	TextSaveText
PASS:		*ds:si	- EditText
		ds:di	- EditText
		ss:bp	- SetDataParams
		cx	- original item number

RETURN:		cx	- new item number, or
			  0 if not modified
		dx	- 0 (new mnemonic) (SBCS)
		dx, ah	- 0 (new mnemonic) (DBCS)

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditTextSaveTextNotMoniker		proc	near
	uses	bx,di
	.enter

	push	cx
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	ObjCallInstanceNoLock		;dx:ax <- # chars in text
EC <	tst	dx					>
EC <	ERROR_NZ TEXT_SIZE_IS_TOO_LARGE_FOR_DBITEM 	>
	inc	ax				;add room for null
	mov	cx, ax				;cx <- length
DBCS <	shl	cx, 1				;cx <- size		>
	pop	dx				;dx <- OrigItem number

	; Allocate or reallocate a transItem and save the text to it.
	;
	mov	bx, ss:[bp].SDP_file
	mov	ax, ss:[bp].SDP_group		;ax <- resource group
	mov	di, ss:[bp].SDP_item		;di <- trans item, if one
	call	AllocNewTransItem		;cx <- new item
	call	SaveNewText
	mov	dx, 0				
DBCS <	mov	ah, 0							>

	.leave
	ret
ResEditTextSaveTextNotMoniker		endp


if	ERROR_CHECK

COMMENT @----------------------------------------------------------------------

FUNCTION:	AssertIsResEditDocument

DESCRIPTION:	Assert the *ds:si is a ResEditTextClass object

CALLED BY:	INTERNAL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/19/92	Initial version

------------------------------------------------------------------------------@

AssertIsResEditText		proc	near	uses di, es
	.enter
	pushf

	GetResourceSegmentNS	ResEditTextClass, es
	mov	di, offset ResEditTextClass
	call	ObjIsObjectInClass
	ERROR_NC	OBJECT_NOT_A_RESEDIT_DOCUMENT

	popf
	.leave
	ret
AssertIsResEditText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check for null in text string

CALLED BY:	ReplaceText
PASS:		dx:bp	- text string
		cx - text string length
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForNull		proc	near
	uses	ax,cx,es,di
	jcxz	exit
	.enter

	movdw	esdi, dxbp
SBCS <	clr	al							>
DBCS <	clr	ax							>
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	tst	cx
	ERROR_NZ	STRING_LENGTH_INCORRECT

	.leave
exit:
	ret
CheckForNull		endp

endif

TextDrawCode		ends


