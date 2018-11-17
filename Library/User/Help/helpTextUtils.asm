COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpTextUtils.asm

AUTHOR:		Gene Anderson, Oct 23, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/23/92		Initial revision


DESCRIPTION:
	Routines for dealing with the text object in the help controller

	$Id: helpTextUtils.asm,v 1.1 97/04/07 11:47:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTConnectTextAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect various text attribute structures to our text object

CALLED BY:	HLDisplayText()
PASS:		*ds:si - controller
		ss:bp - inherited locals
			childBlock - child block
RETURN:		ax - VM handle of name array
		ds - fixed up
DESTROYED:	bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: also sets the file handle for the text object to the help file
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTConnectTextAttributes		proc	near
	uses	dx, di, si
HELP_LOCALS
	.enter	inherit

	;
	; Create new text storage
	;
	call	HTCreateTextStorage
	;
	; Get the map block of the help file
	;
	call	HFGetFile			;bx <- handle of help file
	call	DBLockMap			;*es:di <- map block
EC <	tst	di				;>
EC <	ERROR_Z HELP_FILE_HAS_NO_MAP_BLOCK	;>
	mov	di, es:[di]			;es:di <- ptr HelpFileMapBlock
	;
	; Connect the object to the help file
	;
	mov	cx, bx				;cx <- handle of help file
	mov	bx, ss:childBlock
	mov	si, offset HelpTextDisplay	;^lbx:si <- chunk of text object
	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	call	HUObjMessageSend
	;
	; Convert the fonts we use if we're connected to a TV or
	; if the user has selected the largest system font (and
	; hence we need to make the help text more readable)
	;
	mov	ax, es:[di].HFMB_charAttrs	;ax <- VM handle of char attrs
	call	HTConvertFontsForTVOrLarge
	;
	; Connect the various attribute arrays
	; NOTE: the order is important -- the names must be done first
	; NOTE: see vTextC.def for details
	;
	mov	ch, TRUE			;ch <- handles are VM
	push	bp
	clr	bp				;bp <- use 1st element
	mov	ax, MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY

	mov	dx, es:[di].HFMB_names		;dx <- VM handle of names
	push	dx
	mov	cl, VTSF_NAMES
	call	HUObjMessageSend
	mov	dx, es:[di].HFMB_charAttrs	;dx <- VM handle of char attrs
	mov	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	call	HUObjMessageSend
	mov	dx, es:[di].HFMB_paraAttrs	;dx <- VM handle of para attrs
	mov	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	call	HUObjMessageSend
	mov	dx, es:[di].HFMB_graphics	;dx <- VM handle of graphics
	mov	cl, mask VTSF_GRAPHICS
	call	HUObjMessageSend
	mov	dx, es:[di].HFMB_types		;dx <- VM handle of types
	mov	cl, mask VTSF_TYPES
	call	HUObjMessageSend
	pop	ax				;ax <- VM handle of names
	pop	bp
	;
	; Finished with the map block of the help file
	;
	call	DBUnlock

	.leave
	ret
HTConnectTextAttributes		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTConvertFontsForTVOrLarge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert fonts & pointsizes for viewing on the TV

CALLED BY:	HLDisplayText()
PASS:		cx	- handle of VM file holding character attr array
		ax	- handle of VM block holding character attr array
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		For each character array element {
			if font/pointsize/etc. match element {
				substitute new font/pointsize/etc.
			}
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTConvertFontsForTVOrLarge	proc	near
		uses	ax, bx, cx, dx, di, si, bp, ds, es
		.enter
	;
	; Determine if we need to do anything at all:
	;    a) connected to a TV
	;    b) system font is set to large
	;
		mov	di, offset HTConvertForTVCharAttrCB
		call	HTCheckIfTV
		jc	doConversion
		mov	di, offset HTConvertForLargeCharAttrCB
		push	cx, dx
		call	UserGetDefaultMonikerFont
		cmp	dx, 14
		pop	cx, dx
		jb	done
	;
	; Lock down the VM block holding the character attr array
	; Offset of callback routine is already in DI
	;
doConversion::
		mov	bx, cx			; VM file => BX
		call	VMLock			; block segment => AX
						; memory handle => BP
		mov	ds, ax
		mov	si, 10h			; HACK!!!
		mov	bx, cs
		call	ChunkArrayEnum
		call	VMDirty
		call	VMUnlock		
done:		
		.leave
		ret
HTConvertFontsForTVOrLarge	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTCheckIfTV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert fonts & pointsizes for viewing on the TV

CALLED BY:	Utility
PASS:		nothing
RETURN:		carry	- set if on TV, clear otherwise
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/21/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTCheckIfTV	proc	far
		uses	ax
		.enter
		
		call	UserGetDisplayType
		and	ah, mask DT_DISP_ASPECT_RATIO
		cmp	ah, DAR_TV shl offset DT_DISP_ASPECT_RATIO
		je	done
		stc
done:
		cmc
		
		.leave
		ret
HTCheckIfTV	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTConvertForTVCharAttrCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify the passed VisTextCharAttr structure so
		that the help text is readable on a TV

CALLED BY:	HLConvertFontsForTVOrLarge via ChunkArrayEnum
PASS:		DS:DI	= VisTextCharAttr
RETURN:		carry	= clear (to continue enumeration)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		if pointsize = 10 or 12 then
			if styles = none or underline
				fontID = BERKELEY
				pointsize = 14
			else
				fontID = "Cranbrook"
				pointsize = 18				
				text color = blue
		if pointsize = 16 then
			pointsize = 18
			if  styles = bold+italic then
				styles = none
				text color = blue

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTConvertForTVCharAttrCB	proc	far
		uses	ax, cx
		.enter
	;
	; For now, just check for some point sizes and do the conversion
	;
		mov	ax, ds:[di].VTCA_pointSize.WBF_int
		mov	cx, 14			; convert to 14
		cmp	ax, 10
		je	doConversion
		cmp	ax, 12
		je	doConversion
		mov	cx, 18			; convert to 18
		cmp	ax, 16
		jne	done
	;
	; For 16 point text, if it is bold + italic, convert to
	; just bold, since italic looks crappy on a TV.
	;
		cmp	ds:[di].VTCA_textStyles, mask TS_BOLD or mask TS_ITALIC
		jne	doConversion
		clr	ds:[di].VTCA_textStyles
		call	changeToBlue
	;
	; Store the new pointsize, and if we are converting to 14
	; point text, then change the font to Berkeley (unless
	; some style was present, in which case we change to
	; Sather Gothic).
	;
doConversion:
		mov	ds:[di].VTCA_pointSize.WBF_int, cx
		clr	ds:[di].VTCA_pointSize.WBF_frac
		cmp	cx, 14
		jne	done
		mov	cx, FID_BERKELEY
		test	ds:[di].VTCA_textStyles, mask TS_UNDERLINE
		jnz	changeFont
		tst	ds:[di].VTCA_textStyles
		jz	changeFont
		clr	ds:[di].VTCA_textStyles
		mov	ds:[di].VTCA_pointSize.WBF_int, 18
		call	changeToBlue
		mov	cx, FID_DTC_CENTURY_SCHOOLBOOK
changeFont:
		mov	ds:[di].VTCA_fontID, cx
done:
		clc

		.leave
		ret
	;
	; Change the color to blue, if (and only if) the current
	; color of the text is black. Otherwise, do nothing so
	; we don't muck up the help text designer's intent. -Don 3/18/00
	;
changeToBlue:
		tst	ds:[di].VTCA_color.CQ_info
		jnz	doneColorChange		; if not an INDEX, do nothing
		cmp	ds:[di].VTCA_color.CQ_redOrIndex, C_BLACK
		jne	doneColorChange
		mov	ds:[di].VTCA_color.CQ_redOrIndex, C_BLUE
doneColorChange:
		retn
HTConvertForTVCharAttrCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTConvertForLargeCharAttrCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify the passed VisTextCharAttr structure so
		that the help text is more readable on the screen
		(done because the user has chosen the largest font)

CALLED BY:	HLConvertFontsForTVOrLarge via ChunkArrayEnum
PASS:		DS:DI	= VisTextCharAttr
RETURN:		carry	= clear (to continue enumeration)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		if pointsize = 10 or 12 then
			pointsize = 14
		if pointsize = 16 then
			pointsize = 18

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTConvertForLargeCharAttrCB	proc	far
		uses	ax, cx
		.enter
	;
	; For now, just check for some point sizes and do the conversion
	;
		mov	ax, ds:[di].VTCA_pointSize.WBF_int
		mov	cx, 14			; convert to 14
		cmp	ax, 10
		je	doConversion
		cmp	ax, 12
		je	doConversion
		mov	cx, 18			; convert to 18
		cmp	ax, 16
		jne	done
doConversion:
		mov	ds:[di].VTCA_pointSize.WBF_int, cx
		clr	ds:[di].VTCA_pointSize.WBF_frac
done:
		clc

		.leave
		ret
HTConvertForLargeCharAttrCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTGetTextForContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text for a context and stuff it in the text display

CALLED BY:	HLDisplayText()
PASS:		*ds:si - controller
		ss:bp - inherited locals
			childBlock - handle of child block
			context - name of context to get
RETURN:		carry - set if error (context name doesn't exist)
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTGetTextForContext		proc	near
	class	HelpControlClass
	uses	dx,  si, di, es, ds
HELP_LOCALS
	.enter	inherit

	;
	; Find the name for the context
	;
	call	HNFindNameForContext
	jc	quit				;branch if error

	;
	; Tell our text object to load the text
	;
	mov	dx, ss:nameData.HFND_text.VTND_helpText.DBGI_item
	tst	dx				;any item?
	stc					;carry <- in case of error
	jz	quit				;branch if no error
	mov	cx, ss:nameData.HFND_text.VTND_helpText.DBGI_group
	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset
	tst	ds:[di].HCI_compressLib
	jnz	uncompress

;	If no compression, just have the text be loaded up normally

	mov	bx, ss:childBlock
	mov	si, offset HelpTextDisplay	;^hbx:si <- OD of text object
	push	bp
	mov	ax, MSG_VIS_TEXT_LOAD_FROM_DB_ITEM
	clr	bp				;bp <- use VTI_vmFile
	call	HUObjMessageSend
	pop	bp
noError:

;	Set the selection to be the start of the text
	mov	bx, ss:childBlock
	mov	si, offset HelpTextDisplay
	mov	ax, MSG_VIS_TEXT_SELECT_START
	clr	di				;Don't call HUObjMessageSend,
	call	ObjMessage			; as DS is not valid here

if HIGHLIGHT_LINK_WHEN_OPENED
	mov	ax, MSG_HELP_TEXT_NAVIGATE_TO_NEXT_FIELD
	clr	di				;Don't call HUObjMessageSend,
	call	ObjMessage			; as DS is not valid here
endif ; HIGHLIGHT_LINK_WHEN_OPENED

	clc					;carry <- no error
quit:
	
	.leave
	ret
uncompress:
	mov	si, ds:[di].HCI_compressLib
	;
	; CX.DX <- group/item of compressed data
	;
	mov	bx, ds:[di].HCI_curFile
	movdw	axdi, cxdx
	call	DBLock
;
; The first word is the uncompacted size
;
	mov	di, es:[di]
	mov	ax, es:[di]			;AX <- size of uncompacted data
	ChunkSizePtr	es, di, dx		;DX <- size of compacted data
	sub	dx, size word
	add	di, size word

;	Allocate a block large enough to hold the uncompacted data

EC <	push	ax							>
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
EC <	pop	cx							>
	jc	uncompressError
	push	bx			;Save handle of data
	mov	ds, ax
EC <	push	cx			> ;Save # bytes in data
	mov	ax, CL_DECOMP_BUFFER_TO_BUFFER or mask CLF_MOSTLY_ASCII
	push	ax
	clr	ax							
	push	ax			;sourceFileHan (unused)
	pushdw	esdi			;sourceBuff
	push	dx			;sourceBuffSize
	push	ax			;destBuffHan
	pushdw	dsax			;destBuffer
	mov	bx, si
	mov	ax, enum CompressDecompress
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable	;AX <- # bytes written out (0 if err)
EC <	pop	dx							>
	tst	ax
	jz	uncompressFreeError
EC <	cmp	dx, ax							>
EC <	ERROR_NE BAD_NUM_BYTES_WRITTEN_OUT				>
	call	DBUnlock		;Unlock the DB item

;	Send the data off to the object

	mov	ax, MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_FORMAT
	mov	bx, ss:childBlock
	mov	si, offset HelpTextDisplay	;^hbx:si <- OD of text object
	mov	cx, ds				;CX.DX <- ptr to data to load
	clr	dx
	push	bp
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	pop	bx			;Restore handle of uncompressed data
	call	MemFree			;Free it
	jmp	noError

uncompressFreeError:
	pop	bx
	call	MemFree
uncompressError:
	call	DBUnlock
	stc
	jmp	quit
HTGetTextForContext		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTCreateTextStorage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create storage for the HelpTextDisplay

CALLED BY:	HelpControlInit()
PASS:		*ds:si - controller
RETURN:		ds - fixed up
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTCreateTextStorage		proc	near
	uses	si
	.enter

	call	HUGetChildBlockAndFeatures
	mov	si, offset HelpTextDisplay	;^lbx:si <- OD of text object
	;
	; Create storage for the text object
	;
	mov	cx, mask VTSF_MULTIPLE_CHAR_ATTRS or \
			mask VTSF_MULTIPLE_PARA_ATTRS or \
			mask VTSF_GRAPHICS or \
			mask VTSF_TYPES		;ch <- no regions
	mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
	call	HUObjMessageSend

	.leave
	ret
HTCreateTextStorage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTDestroyTextStorage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the storage for the text object

CALLED BY:	HelpControlExit()
PASS:		*ds:si - controller
RETURN:		ds - fixed up
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTDestroyTextStorage		proc	near
	uses	ax, bx, cx, dx, si
	.enter

	call	HUGetChildBlockAndFeatures
	mov	si, offset HelpTextDisplay	;^lbx:si <- OD of text object
	clr	cx				;cx <- don't destroy elements
	mov	ax, MSG_VIS_TEXT_FREE_STORAGE
	call	HUObjMessageSend

	.leave
	ret
HTDestroyTextStorage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTGetTextForHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text to record for history reference

CALLED BY:	HHRecordHistory()
PASS:		ss:bp - inherited locals
		ds - block to allocate text chunk in
RETURN:		bx - chunk of text
		ds - fixed up
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HTGetTextForHistory		proc	near
	uses	ax, cx, dx, bp, si
HELP_LOCALS
	.enter	inherit

	clr	dx				;dx <- current position

getTextLoop::
	push	ds:LMBH_handle			;save handle of block
	mov	bx, ss:childBlock
	mov	si, offset HelpTextDisplay	;^lbx:si <- OD of text object
	;
	; Get the range of the first line of text
	; (ie. the first paragraph minus the <CR>)
	;
	push	dx, bp
	sub	sp, (size VisTextGetTextRangeParameters)
	mov	bp, sp				;ss:bp <- params
	mov	ss:[bp].VTGTRP_range.VTR_start.low, dx
	clr	ss:[bp].VTGTRP_range.VTR_start.high
	mov	ss:[bp].VTGTRP_range.VTR_end.low, dx
	clr	ss:[bp].VTGTRP_range.VTR_end.high
CheckHack <(offset VTGTRP_range) eq 0>
	mov	dx, ss				;dx:bp <- ptr to range
	mov	cx, mask VTRC_PARAGRAPH_CHANGE
	mov	ax, MSG_VIS_TEXT_GET_RANGE
	push	bp
	call	callObjMessage
	pop	bp
	decdw	ss:[bp].VTGTRP_range.VTR_end	;-1 for CR
	;
	; Get the text for the range we've got
	;
	mov	ss:[bp].VTGTRP_textReference.TR_type, TRT_SEGMENT_CHUNK
	mov	ss:[bp].VTGTRP_textReference.TR_ref.TRU_segChunk.TRSC_segment, ds
	mov	ss:[bp].VTGTRP_textReference.TR_ref.TRU_segChunk.TRSC_chunk, 0
	mov	ss:[bp].VTGTRP_flags, mask VTGTRF_ALLOCATE_ALWAYS

	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE


	call	callObjMessage			;cx = allocated chunk.



	add	sp, (size VisTextGetTextRangeParameters)
	pop	dx, bp				;dx <- current position
	;
	; Dereference the block the text was copied into in case it moved.
	;
	pop	bx				;bx <- handle of block
	call	MemDerefDS
	mov	bx, cx				;bx <- chunk of text
	;
	; Make sure the text isn't too long.
	;
	ChunkSizeHandle ds, bx, ax		;ax <- size of text (w/NULL)
DBCS <	shr	ax, 1				;ax <- length (w/NULL)>

	cmp	ax, 1
	jbe	noText				;branch if no text

	cmp	ax, MAXIMUM_HISTORY_LENGTH
	ja	tooMuchText			;branch if text too long

done:
	.leave
	ret

	;
	; No text was on the line -- skip it.
	;


noText:
	inc	dx				;dx <- skip <CR>
	mov	ax, bx				;ax <- chunk with text
	call	LMemFree
	jmp	getTextLoop


	;
	; Too much text was on this line -- truncate it.
	;
tooMuchText:
	mov	ax, bx				;ax <- chunk of text
SBCS <	mov	cx, MAXIMUM_HISTORY_LENGTH+1	;cx <- new size>
DBCS <	mov	cx, (MAXIMUM_HISTORY_LENGTH+1)*2 ;>
	call	LMemReAlloc
	;
	; Slap an ellipsis on the end...
	; ...and NULL-terminate the beast.
	;
	mov	si, ds:[bx]			;ds:si <- ptr to chunk
SBCS <	mov	{char}ds:[si][MAXIMUM_HISTORY_LENGTH-1], C_ELLIPSIS	>
SBCS <	mov	{char}ds:[si][MAXIMUM_HISTORY_LENGTH], C_NULL		>
DBCS <	mov	{wchar}ds:[si][2*MAXIMUM_HISTORY_LENGTH-2], C_HORIZONTAL_ELLIPSIS>
DBCS <	mov	{wchar}ds:[si][2*MAXIMUM_HISTORY_LENGTH], C_NULL	>
	jmp	done

callObjMessage:
	push	di
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di
	retn
HTGetTextForHistory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HTGetTypeForHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get type to record for history reference

CALLED BY:	HHRecordHistory()
PASS:		ss:bp - inherited locals
		*ds:si - controller
RETURN:		dl - VisTextContextType
DESTROYED:	dh

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HTGetTypeForHistory		proc	near
	uses	ax, bx, cx, si
HELP_LOCALS
	.enter	inherit

	;
	; Get the context at the start of the page
	;
	push	si
	mov	bx, ss:childBlock
	mov	si, offset HelpTextDisplay
	clrdw	dxax				;dx:ax <- offset to check
	clrdw	cxdi
	call	HTGetLinkForPos			;ax <- context at offset
	pop	si
	;
	; Get the type of the context
	;
	call	HNGetTypeForContext

	.leave
	ret
HTGetTypeForHistory		endp

HelpControlCode ends
