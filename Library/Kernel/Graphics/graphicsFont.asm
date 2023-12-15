COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		graphicsFont.asm

AUTHOR:		Gene Anderson, Feb 11, 1990

ROUTINES:
	Name			Description
	----			-----------
GLBL	GrSetFontWeight		Set weight for font
GLBL	GrSetFontWidth		Set width for font
GLBL	GrSetSuperscriptAttr	Set superscript attributes
GLBL	GrSetSubscriptAttr	Set subscript attributes

GLBL	GrGetFontWeight		Get weight for font
GLBL	GrGetFontWidth		Get width for font
GLBL	GrGetSuperscriptAttr	Get superscript attributes
GLBL	GrGetSubscriptAttr	Get subscript attributes

GLBL	GrGetFontName		Get the name of a font
GLBL	GrCharWidth		Get width of a single character
GLBL	GrCharMetrics		Get metrics for a char
GLBL	GrEnumFonts		Return available font names and IDs
GLBL	GrCheckFontAvail		See if named font is available
GLBL	GrFindNearestPointsize	Find nearest available pointsize
GLBL	GrGetCharInfo		Get info about single character

EXT	LibFindBestFace		Find closest match to size & style
INT	CheckFontType		See if a font is of the correct type
INT	AddFont			Add font to buffer
INT	IsFontAvailable		See if font ID is available in system
INT	FindNearestBitmap	Find nearest bitmap face to pointsize & style
INT	FindNearestOutline	Find nearest outlines to style
INT	ScalePointsize		Scale pointsize by graphics system transform
INT	CheckCloserSize		See if pointsize is closer to current size
INT	CheckCloserStyles	See if styles are closer subset of current
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/11/90		Initial revision

DESCRIPTION:
	
		
	$Id: graphicsFont.asm,v 1.1 97/04/05 01:12:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphcisFontsEnum segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrEnumFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a list of names of available fonts.
CALLED BY:	GrEnumFonts

PASS:		cx - # of FontEnumStruct's that buffer can hold
		if cx=0:
		    just return number of matching fonts
		else:
		    es:di - ptr to buffer
		dl - type of fonts to find (FontEnumFlags)
		if FEF_FAMILY set:
		    dh - family of fonts to find (FontFamily)
RETURN:		cx - # of fonts found
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/11/90		Initial version
	jim	1/91		moved over from klib to kernel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrEnumFonts	proc	far
	uses	si, ds,ax,bx
sortParams	local	QuickSortParameters
	.enter

if 	FULL_EXECUTE_IN_PLACE
EC <	jcxz	xipOK						>
EC <	push	bx, si						>
EC <	movdw	bxsi, esdi					>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	pop	bx, si						>
xipOK::
endif	
	push	di
	call	FarLockInfoBlock		;lock font info block
	mov	bx, cx				;bx <- # of fonts to find
	mov	si, ds:[FONTS_AVAIL_HANDLE]	;si <- ptr to chunk
	ChunkSizePtr	ds, si, ax		;ax <- chunk size
	add	ax, si				;ax -> end of chunk
fontLoop:
	tst	bx				;buffer passed?
	jz	noBufferEnd			;branch if no buffer passed
	jcxz	endList				;branch if no more space
noBufferEnd:
	cmp	si, ax				;through list?
	jae	endList				;yes, exit
	push	si
	call	CheckFontType			;see font of right type
	jnc	nextFont			;branch if not
	tst	bx				;buffer passed?
	jz	noBufferAdd			;branch if no buffer passed
	call	AddFont				;add font to list
	add	di, size FontEnumStruct		;move to next dest ptr
noBufferAdd:
	dec	cx				;one less font to find
nextFont:
	pop	si
	add	si, size FontsAvailEntry	;move to next src entry
	jmp	fontLoop			;loop while more

	;
	; We're done with the font info block, and almost home...
	;
endList:
	pop	di
	call	FarUnlockInfoBlock		;unlock font info block
	;
	; If a buffer was passed:
	;	 bx  = # of entries in buffer
	;	-cx  = # of entries not used
	;	= # of matching fonts that fit
	;	  carry clear (no borrow)
	; else:
	;	 bx  = 0
	;	-cx  = -(# of matching fonts)
	;	= # of matching fonts
	;	  carry set (borrow)
	;
	sub	bx, cx
	mov	cx, bx				;cx <- # of fonts found
	jc	noSort				;branch if no buffer
	;
	; Sort the damn thing if the caller requested it
	;
	test	dl, mask FEF_ALPHABETIZE	;sorting?
	jz	noSort				;branch if not sorting
;;;
;;;ArrayQuickSort() currently trashes ax, cx, dx
;;;
	push	cx, dx
	mov	si, di
	segmov	ds, es				;ds:si <- ptr to array
	clr	ax
	mov	ss:sortParams.QSP_lockCallback.segment, ax
	mov	ss:sortParams.QSP_unlockCallback.segment, ax
CheckHack < DEFAULT_MEDIAN_LIMIT eq 0 >
	mov	ss:sortParams.QSP_medianLimit, ax
	mov	ss:sortParams.QSP_insertLimit, DEFAULT_INSERTION_SORT_LIMIT
	mov	ss:sortParams.QSP_compareCallback.segment, SEGMENT_CS
	mov	ss:sortParams.QSP_compareCallback.offset, offset GEFCompareFonts
	mov	ax, (size FontEnumStruct)	;ax <- size of entry
	call	ArrayQuickSort			;sort me jesus
	pop	cx, dx				;cx <- # of elements
noSort:

	.leave
	ret
GrEnumFonts	endp

GEFCompareFonts	proc	far
	add	si, offset FES_name		;ds:si <- string #1
	add	di, offset FES_name		;es:di <- string #2
	clr	cx				;cx <- NULL-terminated
	call	LocalCmpStrings
	ret
GEFCompareFonts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFontType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if font is of the correct type
CALLED BY:	LibEnumFonts, LibIsFontAvail

PASS:		ds:si - ptr to FontsAvailEntry
		es:di - ptr to free space in buffer
		dl - type of fonts to find (FontEnumFlags)
		if FEF_FAMILY:
			dh - family of fonts to find (FontFamily)
RETURN:		ds:si - ptr to FontInfo
		carry - set if match
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckFontType	proc	far
	uses	ax
	.enter

EC <	test	dl, mask FEF_OUTLINES or mask FEF_BITMAPS ;>
EC <	ERROR_Z	FONTMAN_NEED_FEF_OUTLINES_OR_FEF_BITMAPS ;>

	mov	si, ds:[si].FAE_infoHandle	;si <- chunk of info
	mov	si, ds:[si]			;si <- ptr to FontInfo

	tst	{word}ds:[si].FI_faceName	;blank name?
	jz	noMatch				;don't add if blank name
	test	dl, mask FEF_BITMAPS		;find bitmaps?
	jz	noBitmaps			;branch if not
	tst	ds:[si].FI_pointSizeTab		;see if any bitmaps
	jnz	checkBits			;if so, check other bits
noBitmaps:
	test	dl, mask FEF_OUTLINES		;find outlines?
	jz	noOutlines
	tst	ds:[si].FI_outlineTab		;see if any outlines
	jnz	checkBitsOutline		;if so, check other bits
noOutlines:
noMatch:
	clc					;<- indicate no match
done:
	.leave
	ret

checkBitsOutline:
if DBCS_PCGEOS
	;
	; There exist some bitmap-only fonts provided by a special font
	; driver.  Due to limitations in the implementation, these
	; otherwise appear to be outline fonts.  However, we don't
	; wish them enumerated as such, lest they show up in the font
	; menu, etc.
	;
	; However, to allow GrCheckFontAvail() to still match these
	; fonts when passing FEF_BITMAPS and FEF_OUTLINES, we double-
	; check here for FEF_BITMAPS first and do the regular
	; checking of FontEnumFlags if it is set.
	;
	test	dl, mask FEF_BITMAPS		;looking for bitmaps?
	jnz	checkBits			;branch if so
	cmp	ds:[si].FI_maker, FM_BITMAP	;bitmap-only from a font driver?
	je	noOutlines			;branch if so
endif
checkBits:
	mov	al, ds:[si].FI_family		;al <- FontFamily

	test	dl, mask FEF_USEFUL		;match "useful" fonts?
	jz	checkFixed			;no, check fixed bit
	test	al, mask FA_USEFUL		;useful?
	jz	noMatch				;branch if not
checkFixed:
	test	dl, mask FEF_FIXED_WIDTH	;match fixed width?
	jz	checkFamily			;no, check family
	test	al, mask FA_FIXED_WIDTH		;fixed width?
	jz	noMatch				;branch if not
checkFamily:
	test	dl, mask FEF_FAMILY		;match font family?
	jz	match				;no, font matches
	andnf	al, mask FA_FAMILY		;keep only family bits
	cmp	al, dh				;correct family?
	jne	noMatch				;branch if not
match:
	stc					;<- indicate match
	jmp	done
CheckFontType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add font to enumerated list of fonts, downcasing if requested.
CALLED BY:	LibEnumFonts

PASS: 		ds:si - ptr to FontInfo for font
		dl - type of fonts to find (FontEnumFlags)
		es:di - ptr to available FontEnumStruct
RETURN: 	none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <(offset FES_ID) eq 0>
CheckHack <(offset FES_name) eq (offset FES_ID + size word)>

AddFont	proc	far
	uses	ax, cx, si, di
	.enter

	mov	ax, ds:[si].FI_fontID		;ax <- font ID
	push	di
	stosw					;store ID, update ptr (di)
	add	si, offset FI_faceName		;ds:si <- ptr to name
SBCS <	mov	cx, FONT_NAME_LEN/2		;cx <- # of words to copy >
DBCS <	mov	cx, FONT_NAME_LEN		;cx <- # of words to copy >
	rep	movsw				;copy the name, update ptr (di)
	pop	si				;si <- offset of dest
	;
	; Downcase the string if requested
	;
	test	dl, mask FEF_DOWNCASE		;downcase strings?
	jz	noDowncase			;branch if not downcasing
	push	ds
	segmov	ds, es				;ds:si <- ptr to buffer
	call	LocalDowncaseString
	pop	ds
noDowncase:

	.leave
	ret
AddFont	endp

GraphcisFontsEnum ends

;---

GraphicsFonts	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetFontWeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set weight for font for drawing
CALLED BY:	GLOBAL

PASS:		di - handle of GState
		al - FontWeight enum (% of normal)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetFontWeight	proc	far
EC <	cmp	al, FWE_BLACK			;>
EC <	ERROR_BE FONT_BAD_WEIGHT		;>
	push	bx
	mov	bx, offset FCA_weight or (GR_SET_FONT_WEIGHT shl 8)
	GOTO	SetFontAttrCommonByte, bx
GrSetFontWeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetFontWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set width for font font drawing
CALLED BY:	GLOBAL

PASS:		di - handle of GState
		al - FontWidth enum (% of normal)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetFontWidth	proc	far
	push	bx
	mov	bx, offset FCA_width or (GR_SET_FONT_WIDTH shl 8)
	GOTO	SetFontAttrCommonByte, bx
GrSetFontWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetSuperscriptAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set superscript attributes
CALLED BY:	GLOBAL

PASS:		di - handle of GState
		al - SuperscriptPosition (% of font size up)
		ah - SuperscriptSize (% of font size)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetSuperscriptAttr	proc	far
	push	bx
	mov	bx, offset FCA_superPos or (GR_SET_SUPERSCRIPT_ATTR shl 8)
	GOTO	SetFontAttrCommonWord, bx
GrSetSuperscriptAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetSubscriptAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set subscript attributes
CALLED BY:	GLOBAL

PASS:		di - handle of GState
		al - SubscriptPosition (% of font size down)
		ah - SubscriptSize (% of font size)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetSubscriptAttr	proc	far
	push	bx
	mov	bx, offset FCA_subPos or (GR_SET_SUBSCRIPT_ATTR shl 8)
	FALL_THRU	SetFontAttrCommonWord, bx
GrSetSubscriptAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFontAttrCommon{Byte,Word}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for setting font attribute
CALLED BY:	UTILITY

PASS:		di - handle of GState
		ax - value to set
		bl - offset of attribute in GState
		bh - opcode for GString
		on stack - saved bx, far return address
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetFontAttrCommonWord	proc	far
	uses	ds, ax
	.enter

	;
	; Do common setup
	;
	call	LockDI_DS_checkFar		;lock the GState, check GString
	pushf
	push	bx				;save opcode
	clr	bh				;bx <- offset of attribute
	;
	; Set the attribute in the GState and invalidate the font
	;
	mov	{word}ds:GS_fontAttr[bx], ax	;set the attribute
	call	FarInvalidateFont		;invalidate the font
	;
	; If in a GString, write out the attribute, too.
	;
	mov	bx, ax				;bx <- attribute
	pop	ax				;ah <- opcode
	popf
	jnc	notGString			;branch if not GString
	push	cx
	mov	al, ah				;al <- opcode
	mov	cl, 2				;cl <- # of bytes to write
	mov	ch, GSSC_FLUSH
	call	GSStoreBytes			;write me jesus
	pop	cx
notGString:
	;
	; Unlock the GState
	;
	mov	bx, ds:[LMBH_handle]		;bx <- handle of GState
	call	MemUnlock
	mov	di, bx				;di <- handle of GState

	.leave
	FALL_THRU_POP	bx			;bx <- saved bx
	ret
SetFontAttrCommonWord	endp

SetFontAttrCommonByte	proc	far
	uses	ds, ax
	.enter

	;
	; Do common setup
	;
	call	LockDI_DS_checkFar		;lock the GState, check GString
	pushf
	push	bx				;save opcode
	clr	bh				;bx <- offset of attribute
	;
	; Set the attribute in the GState and invalidate the font
	;
	mov	{byte}ds:GS_fontAttr[bx], al	;set the attribute
	call	FarInvalidateFont		;invalidate the font
	;
	; If in a GString, write out the attribute, too.
	;
	pop	bx				;bh <- opcode
	popf
	jnc	notGString			;branch if not GString
	push	cx
	mov	ah, al				;ah <- attribute
	mov	al, bh				;al <- opcode
	mov	cl, 1				;cl <- # of bytes to write
	mov	ch, GSSC_FLUSH
	call	GSStoreBytes			;write me jesus
	pop	cx
notGString:
	;
	; Unlock the GState
	;
	mov	bx, ds:[LMBH_handle]		;bx <- handle of GState
	call	MemUnlock
	mov	di, bx				;di <- handle of GState

	.leave
	FALL_THRU_POP	bx			;bx <- saved bx
	ret
SetFontAttrCommonByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetFontWeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get weight of font used for drawing
CALLED BY:	GLOBAL

PASS:		di - handle of GState
RETURN:		al - FontWeight enum (% of normal)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetFontWeight	proc	far
	mov	al, offset FCA_weight
	GOTO	GetFontAttrCommonByte
GrGetFontWeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetFontWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get width of font used for drawing
CALLED BY:	GLOBAL

PASS:		di - handle of GState
RETURN:		al - FontWidth enum (% of normal)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetFontWidth	proc	far
	mov	al, offset FCA_width
	GOTO	GetFontAttrCommonByte
GrGetFontWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetSuperscriptAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get superscript attributes used for drawing
CALLED BY:	GLOBAL

PASS:		di - handle of GState
RETURN:		al - SuperscriptPosition (% of font size up)
		ah - SuperscriptSize (% of font size)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetSuperscriptAttr	proc	far
	mov	al, offset FCA_superPos
	GOTO	GetFontAttrCommonWord
GrGetSuperscriptAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetSubscriptAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get subscript attributes used for drawing
CALLED BY:	GLOBAL

PASS:		di - handle of GState
RETURN:		al - SubscriptPosition (% of font size down)
		ah - SubscriptSize (% of font size)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetSubscriptAttr	proc	far
	mov	al, offset FCA_subPos
	FALL_THRU	GetFontAttrCommonWord
GrGetSubscriptAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFontAttrCommon{Byte,Word}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to get a font attribute
CALLED BY:	UTILITY

PASS:		di - handle of GState
		al - offset of attribute in FontCommonAttrs
RETURN:		ax - attribute
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetFontAttrCommonWord	proc	far
	push	ds
	call	LockDI_DS_checkFar
	uses	bx
	.enter

	mov	bl, al
	clr	bh				;bx <- offset of attribute
	mov	ax, {word}ds:GS_fontAttr[bx]	;ax <- attribute

	.leave
	GOTO	UnlockDI_popDS, ds
GetFontAttrCommonWord	endp

GetFontAttrCommonByte	proc	far
	push	ds
	call	LockDI_DS_checkFar
	uses	bx
	.enter

	mov	bl, al
	clr	bh				;bx <- offset of attribute
	mov	al, {byte}ds:GS_fontAttr[bx]	;al <- attribute

	.leave
	GOTO	UnlockDI_popDS, ds
GetFontAttrCommonByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetFontName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name of a font
CALLED BY:	GLOBAL

PASS:		cx - ID of font (FontID)
		ds:si - ptr to buffer (FID_NAME_LEN in size)
RETURN:		if match:
		    ds:si - filled buffer
		    cx - length of name in chars (not including NULL)
		    carry - set
		else:
		    cx - 0
		    carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	CHANGE for DBCS
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetFontName	proc	far
	uses	ds, si, es, di, bx
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx					>
EC <	mov	bx, ds					>
EC <	call	ECAssertValidFarPointerXIP		>
EC <	pop	bx					>
endif

	segmov	es, ds
	mov	di, si				;es:di <- ptr to buffer
	call	FarLockInfoBlock		;lock font info block
	mov	bx, cx				;lookup exact font id
	call	IsFontAvailable			;is font in system?
	jnc	notAvailable			;branch if not
	;
	; The font is available, so copy the name
	;
	mov	cx, -1
	add	si, offset FI_faceName
charLoop:
	LocalGetChar ax, dssi
	LocalPutChar esdi, ax
	inc	cx				;one more character
	LocalIsNull ax				;NULL?
	jnz	charLoop			;branch while not NULL
	stc					;carry  <- font found
done:
	call	FarUnlockInfoBlock		;unlock font info block

	.leave
	ret

notAvailable:
	clr	cx				;cx <- no string (carry clear)
	jmp	done
GrGetFontName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCharMetrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return metrics for a single character
CALLED BY:	GLOBAL

PASS:		di - handle of GState
		si - info to return (GCM_info)
		ax - character (Chars)
RETURN:		if font or driver is not available:
			carry - set
			dx:ax - 0
		if GCM_ROUNDED set:
			dx - information (rounded)
		else:
			dx.ah - information (WBFixed)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/ 4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrCharMetrics	proc	far
	uses	bx, cx, es
	.enter

if not DBCS_PCGEOS
EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif

	;
	; Lock the GState
	;
	push	di				;save handle of GState
	push	ax				;save character
	mov	bx, di				;bx <- handle of GState
	call	MemLock
	mov	es, ax				;es <- seg addr of GState
	;
	; See if the font is even available
	;
	mov	cx, es:GS_fontAttr.FCA_fontID	;cx <- current font
	mov	dl, mask FEF_OUTLINES		;dl <- FontEnumFlags
	call	GrCheckFontAvail			;font available?
	jcxz	notAvailable			;branch if not available
	;
	; Call the corresponding driver
	;
	pop	dx				;dx <- character (Chars)
	mov	cx, si				;cx <- GCM_info
	mov	ax, DR_FONT_CHAR_METRICS	;ax <- FontFunction
	call	GrCallFontDriver
done:
	;
	; Unlock the GState
	;
	pop	bx				;bx <- handle of GState
	call	MemUnlock			;unlock the GState

	.leave
	ret

notAvailable:
	pop	ax
	clr	ax, dx				;dx:ax <- font not available
	stc					;carry <- error
	jmp	done
GrCharMetrics	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCharWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return width of a single character
CALLED BY:	EXTERNAL: GrCharWidth

PASS:		di - handle of GState
		ax - character
RETURN:		dx.ah <- width of character (WBFixed)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: this routine gives the pen width of a single character, and
	does not take into account track kerning, pairwise kerning, space
	padding, or any other attributes -- it is simply the character width.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrCharWidth	proc	far
SBCS <	uses	di, ds, bp, bx, cx					>
DBCS <	uses	si, di, ds, bp, bx, cx					>
	.enter

if not DBCS_PCGEOS
EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif

DBCS <	mov	si, di				;save GState		>
	push	ax				;save al
	call	LockFontGStateDS		;ds <- seg addr of font
	;
	; Force character to default character if it is missing from the
	; character set.
	;
SBCS <	cmp	al, byte ptr ds:FB_lastChar				>
SBCS <	ja	useDefaultChar			;branch if after last char >
DBCS <	cmp	ax, ds:FB_lastChar					>
DBCS <	ja	afterLastChar			;branch if after last char >
afterDefault:
SBCS <	sub	al, byte ptr ds:FB_firstChar				>
SBCS <	jb	useDefaultChar						>
DBCS <	sub	ax, ds:FB_firstChar					>
DBCS <	jb	beforeFirstChar						>
SBCS <	clr	ah							>
	mov	di, ax				;di <- index of char
	FDIndexCharTable di, ax			;di <- offset into char table
	tst	ds:FB_charTable.CTE_dataOffset[di]
	jz	useDefaultChar			;use default if missing char.
	mov	dx, ds:FB_charTable[di].CTE_width.WBF_int
	mov	ch, ds:FB_charTable[di].CTE_width.WBF_frac

	call	FontDrUnlockFont
	pop	ax				;al <- character
	mov	ah, ch				;dx.ah <- width

	.leave
	ret

if DBCS_PCGEOS
	;
	; The character in question is not in the current section
	; of the font.  Lock down the correct section and try again.
	; Unlike many graphics routines, we don't have the GState
	; locked so we need to lock it first.
	;
beforeFirstChar:
	add	ax, ds:FB_firstChar		;re-adjust character
afterLastChar:
	push	ax
	call	LockDI_DS_checkFar		;ds <- seg addr of GState
	call	LockCharSetFar
	mov	bx, ds:GS_fontHandle		;bx <- (new) font handle
	mov	ds, ax				;ds <- (new) font seg
	xchg	bx, si				;bx <- handle of GState
	call	MemUnlock			;unlock GState
	xchg	bx, si				;bx <- (new) font handle
	pop	ax
	jnc	afterDefault			;branch if char exists
useDefaultChar:
	mov	ax, ds:FB_defaultChar		;ax <- default char
	mov	di, si				;di <- GState
	jmp	afterDefault

else
useDefaultChar:
	mov	al, byte ptr ds:FB_defaultChar	;use default char
	jmp	afterDefault
endif
GrCharWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetCharInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return info for a single character
CALLED BY:	EXTERNAL: GrGetCharInfo

PASS:		di - handle of GState
		ax - character
RETURN:		cl - CharTableFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetCharInfo	proc	far
	uses	di, ds, bp, ax, bx, dx
	.enter

if not DBCS_PCGEOS
EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif

	call	LockFontGStateDS		;ds <- seg addr of font
	;
	; Return CTF_NO_DATA if it is missing from the character set.
	;
SBCS <	cmp	al, byte ptr ds:FB_lastChar				>
SBCS <	ja	noData				;branch if after last char >
DBCS <	cmp	ax, ds:FB_lastChar					>
DBCS <	ja	afterLastChar			;branch if after last char >
DBCS <afterDefault:							>
SBCS <	sub	al, byte ptr ds:FB_firstChar				>
SBCS <	jb	noData							>
DBCS <	sub	ax, ds:FB_firstChar					>
DBCS <	jb	beforeFirstChar						>
SBCS <	clr	ah							>
	mov	di, ax				;di <- index of char
	FDIndexCharTable di, ax			;di <- offset into char table
	mov	cl, ds:FB_charTable.CTE_flags[di]
done:
	call	FontDrUnlockFont

	.leave
	ret

if DBCS_PCGEOS
	;
	; The character in question is not in the current section
	; of the font.  Lock down the correct section and try again.
	; Unlike many graphics routines, we don't have the GState
	; locked so we need to lock it first.
	;
beforeFirstChar:
	add	ax, ds:FB_firstChar		;re-adjust character
afterLastChar:
	push	ax
	call	LockDI_DS_checkFar		;ds <- seg addr of GState
	call	LockCharSetFar
	mov	bx, ds:GS_fontHandle		;bx <- (new) font handle
	mov	ds, ax				;ds <- (new) font seg
	xchg	bx, si				;bx <- handle of GState
	call	MemUnlock			;unlock GState
	xchg	bx, si				;bx <- (new) font handle
	pop	ax
	jnc	afterDefault			;branch if char exists
endif
SBCS <noData:								>
	mov	cl, mask CTF_NO_DATA		;return NO_DATA
	jmp	done

GrGetCharInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCheckFontAvail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if named font exists.
CALLED BY:	GrCheckFontAvail

PASS:		dl - font types to match (FontEnumFlags)
		if FEF_FAMILY set:
		    dh - font family to match (FontFamily)
		if FEF_STRING set:
		    ds:si - ptr to string to match (null-terminated)
		  else:
		    cx - ID of font to match (FontID)
RETURN:		if match:
	            cx - ID of font
		  else:
		    cx - FID_INVALID
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Will die horribly if the string is NULL
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/12/90		Initial version
	jim	1/91		moved from klib to kernel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrCheckFontAvail	proc	far
	test	dl, mask FEF_STRING
	jz	noString
	
	mov	ss:[TPD_dataBX], handle GrCheckFontAvailReal
	mov	ss:[TPD_dataAX], offset GrCheckFontAvailReal
	GOTO	SysCallMovableXIPWithDSSI

noString:
	call	GrCheckFontAvailReal
	ret
GrCheckFontAvail	endp
CopyStackCodeXIP	ends

else

GrCheckFontAvail	proc	far
	FALL_THRU	GrCheckFontAvailReal
GrCheckFontAvail	endp

endif


GrCheckFontAvailReal	proc	far
	uses	ax, si, di, bp, ds, es
	.enter

EC <	test	dl, mask FEF_ALPHABETIZE	;>
EC <	ERROR_NZ FONTMAN_BAD_ENUM_FLAG_PASSED_TO_IS_FONT_AVAIL >

	segmov	es, ds
	mov	di, si				;es:di <- ptr to match string
	call	FarLockInfoBlock		;lock font info block

	sub	sp, size FontEnumStruct		;allocate buffer on stack
	mov	bp, sp				;bp <- ptr to bottom of buffer

	mov	si, ds:[FONTS_AVAIL_HANDLE]	;si <- ptr to chunk
	ChunkSizePtr	ds, si, ax		;ax <- chunk size
	add	ax, si				;ax -> end of chunk

fontLoop:
	cmp	si, ax				;through list?
	push	si
	jae	noMatch				;yes, exit
	call	CheckFontType			;see font of right type
	jc	rightType			;branch if right type
nextFont:
	pop	si				;recover avail entry ptr
	add	si, size FontsAvailEntry	;move to next src entry
	jmp	fontLoop			;loop while more fonts

noMatch:
	mov	cx, FID_INVALID			;cx <- no font matched
endList:
	pop	si				;clean up stack
	add	sp, size FontEnumStruct		;dealloc buffer
	call	FarUnlockInfoBlock		;unlock font info block

	.leave
	ret

rightType:
	test	dl, mask FEF_STRING		;see if ID or string
	jnz	isString			;branch if string
	cmp	ds:[si].FI_fontID, cx		;see if ID matches
	jne	nextFont			;nope, try again
	jmp	endList				;branch always

isString:
	push	ax, si, di, ds, es
	push	es, di
	segmov	es, ss
	mov	di, bp				;es:di <- ptr to buffer
	call	AddFont				;copy and downcase, if necessary
	add	di, offset FES_name		;es:di <- ptr to font name
	pop	ds, si				;ds:si <- ptr to match string
	clr	cx				;cx <- strings NULL_terminated
	test	dl, mask FEF_DOWNCASE
	jnz	downCase			;branch if case-insensitive
	call	LocalCmpStrings
afterCompare:
	pop	ax, si, di, ds, es
	jne	nextFont			;branch if not equal
	mov	cx, ds:[si].FI_fontID		;cx <- font ID
	jmp	endList				;and exit

downCase:
	call	LocalCmpStringsNoCase
	jmp	afterCompare
	
GrCheckFontAvailReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFindNearestPointsize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the nearest available pointsize for a font.
CALLED BY:	GrFindNearestPointsize

PASS:		cx - font ID (FontID)
		dx.ah - pointsize (WBFixed)
		al - style (TextStyle)
RETURN:		if font exists:
		    dx.ah - nearest available pointsize (if font exists)
		    al - styles of closest face (TextStyle)
		    cx - unchanged
		else:
		    cx - FID_INVALID
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/12/90		Initial version
	jim	1/91		moved from klib to kernel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrFindNearestPointsize	proc	far
	uses	ds, si, bx, di
	.enter

	call	FarLockInfoBlock		;lock font info block
	mov	bx, cx				;lookup for exact font id
	call	IsFontAvailable			;see if font available
	jnc	fontNotFound			;branch if font not in system
	push	cx
SBCS <	mov	cl, TRUE			;cl <- find closest absolute >
DBCS <	mov	cl, FCS_ASCII			;cl <- FontCharSet	>
	call	FindNearestBitmap		;see if a bitmap available
	pop	cx
	jc	done				;if so, done
	call	FindNearestOutline		;see if an outline available
	jc	done				;if so, done
fontNotFound:
EC <	mov	dx, -1				;>
	mov	cx, FID_INVALID		;cx <- invalid font
done:
	call	FarUnlockInfoBlock		;unlock font info block

	.leave
	ret

GrFindNearestPointsize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibFindBestFace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find closest match for pointsize & style.
CALLED BY:	EXTERNAL: FindFont

PASS:		ds - seg addr of font info block
		es - seg addr of GState
		bp:si - ptr to transformation matrix (TMatrix)
RETURN:		cx - font to use (FontID)
		dx.ah - pointsize to use (WBFixed)
		al - style to use (TextStyle)
		carry - set if outline font substituted
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FID_MAKER_MASK		equ	0xF0

LibFindBestFace	proc	far
	uses	bx, si, di
	.enter

	mov	cx, es:GS_fontAttr.FCA_fontID	;cx <- font to find
	movwbf	dxah, es:GS_fontAttr.FCA_pointsize
	mov	bl, es:GS_fontAttr.FCA_textStyle
	mov	al, bl
	andnf	al, not KERNEL_STYLES		;al <- no kernel styles
	and	bl, KERNEL_STYLES
	push	bx
	
	; pass FID without maker id, to enable fuzzy matching
	mov	bx, cx
	and	bh, not FID_MAKER_MASK

	;
	; See if the font is even available.
	;
	call	IsFontAvailable
	jnc	useDefaultFont			;branch if font not available
	;
	; Find the closest size and style available.
	;
	push	cx
SBCS <	mov	cl, TRUE			;cl <- find closest	>
DBCS <	mov	cl, es:GS_fontAttr.FCA_charSet	;cl <- FontCharSet	>
	call	FindNearestBitmap
	pop	cx
	jc	bitmapFontFound			;branch if bitmap found
	call	FindNearestOutline		;see if an outline available
	jc	foundFont			;if so, done

useDefaultFont:
	call	GrGetDefFontID			;get system defaults
	clr	al				;al <- no styles
	;mov	es:GS_fontAttr.FCA_fontID, cx
DBCS <	mov	bh, FCS_ASCII			;bh <- FontCharSet of default>
bitmapFontFound:
	clc					;carry <- no outline subst.
foundFont:
	mov	es:GS_fontAttr.FCA_fontID, cx
DBCS <	mov	es:GS_fontAttr.FCA_charSet, bh				>
	pop	bx
	pushf
	ornf	al, bl
	mov	es:GS_fontAttr.FCA_textStyle, al
	movwbf	es:GS_fontAttr.FCA_pointsize, dxah
	mov	es:GS_fontAttr.FCA_weight, FW_NORMAL
	mov	es:GS_fontAttr.FCA_width, FWI_MEDIUM
	mov	es:GS_fontAttr.FCA_superPos, SPP_DEFAULT
	mov	es:GS_fontAttr.FCA_superSize, SPS_DEFAULT
	mov	es:GS_fontAttr.FCA_subPos, SBP_DEFAULT
	mov	es:GS_fontAttr.FCA_subSize, SBS_DEFAULT
	ornf	es:GS_fontFlags, mask FBF_MAPPED_FONT
	popf
	.leave
	ret
LibFindBestFace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsFontAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if font is available on the system.
CALLED BY:	LibFindNearestPointsize, LibFindBestFace

PASS:		ds - seg addr of font info block
		cx - font ID to check for
		bx - font ID to check for, without manufacturer if
		     manufacturer mapping is requested
RETURN:		carry set:
		    ds:si - ptr to FontInfo for font
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FID_MAKER_BITS	equ	0xf0	; hi bytes of fontID

IsFontAvailable	proc	near
	uses	ax, dx
	.enter

	mov	si, ds:[FONTS_AVAIL_HANDLE]	;si <- ptr to chunk
	ChunkSizePtr	ds, si, ax		;ax <- chunk size
	add	ax, si				;ax -> end of chunk
fontLoop:
	cmp	si, ax				;end of list?
	jae	fontNotFound			;branch if end (carry clear)
	cmp	ds:[si].FAE_fontID, cx		;see if correct font
	je	fontAvailable			;branch if correct font
	test	ds:[si].FAE_fontID.high, FID_MAKER_MASK
	jz	nextFont			;skip bitmap font
	mov	dx, ds:[si].FAE_fontID
	and	dh, not FID_MAKER_MASK
	cmp	dx, bx
	je	fontAvailable			;branch if usable font
nextFont:
	add	si, FontsAvailEntry		;move to next entry
	jmp	fontLoop

fontAvailable:
	mov	cx, ds:[si].FAE_fontID
	mov	si, ds:[si].FAE_infoHandle	;ds:si <- handle of FontInfo
	mov	si, ds:[si]			;ds:si <- ptr to FontInfo
	stc					;indicate font available
fontNotFound:
	.leave
	ret
IsFontAvailable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNearestOutline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find closest font outline available, if any.
CALLED BY:	LibFindNearestPointsize

PASS:		ds:si - ptr to FontInfo for font
		al - set of styles to match (TextStyle)
RETURN:		if carry set:
		    al - (subset of) styles found (TextStyle)
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindNearestOutline	proc	near
	uses	si, cx
	.enter
	;
	; Check for correct outline. We can generate any pointsize
	; from it, meaning the nearest pointsize is as requested.
	; Also, most styles can be implemented in the font
	; driver or in the kernel.
	;
	mov	di, ds:[si].FI_outlineTab	;di <- offset of outlines
	add	di, si				;di <- ptr to outlines
	add	si, ds:[si].FI_outlineEnd	;si <- ptr to end
	clr	bl				;bl <- closest
	clr	ch				;ch <- flag: subset found?
outlineLoop:
	cmp	di, si				;see if end of list
	jae	endList
	mov	bh, ds:[di].ODE_style		;bh <- styles of outline
	call	CheckCloserStyles
	jnc	nextOutline			;branch if not subset
	mov	ch, TRUE			;ch <- indicate subset found
nextOutline:
	add	di, size OutlineDataEntry	;move to next entry
	jmp	outlineLoop

endList:
	tst	ch				;see if any subset (clear carry)
	jz	noSubset
	mov	al, bl				;al <- styles found
	stc					;indicate subset found
noSubset:

	.leave
	ret
FindNearestOutline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNearestBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find closest font bitmap, if any
CALLED BY:	LibFindNearestPointsize, LibFindBestFace

PASS:		ds:si - ptr to FontInfo for font
		dx.ah - pointsize to find (WBFixed)
		al - styles to match (TextStyle)
	SBCS:
		cl - TRUE if absolute closest
		     FALSE if closest smaller size
	DBCS:
		cl - FontCharSet to match

RETURN:		carry set:
		    dx.ah - closest pointsize found
		    al - styles of closest face (TextStyle)
	DBCS:
		    bh - FontCharSet of closest face
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
	foreach (bitmap) {
	    if (closer size) {
		size = cur_size;
		style = cur_style;
	    } else if (same size) {
		if (closer style) {
	    	    style = cur_style;
		}
	    }
	}
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Selection is done in the order:
		(1) closest pointsize
		(2) closest style
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindNearestBitmap	proc	near
	uses	cx, si, bp
	.enter

	mov	di, ds:[si].FI_pointSizeTab	;di <- offset of bitmaps
	add	di, si				;di <- ptr to start
	add	si, ds:[si].FI_pointSizeEnd	;si <- ptr of end
	clr	bl				;bl <- closest style
if DBCS_PCGEOS
	cmp	dx, MAX_BITMAP_POINTSIZE	;too large for a bitmap?
	ja	fontNotFound			;branch if too large
	mov	dh, 0xff
else
	clr	ch
	mov	bp, 0x8000			;bp.ch <- closest size
endif
	
bitmapLoop:
	cmp	di, si				;see if end of list
	jae	takeGuess			;if so, we're almost done

	;
	; We ignore the FontCharSet.  The reason for this perverse logic
	; is that in the event we've gotten here, either the pointsize,
	; style or FontCharSet didn't match.
	;
	; This was supposed to fix bug #30503.  We need to undo Gene's
	; fix in order to fix another problem with finding DBCS Kanji
	; characters.
	; BrianC  approves.  7/30/96 - ptrinh
	;
;if 0
DBCS <	cmp	cl, ds:[di].PSE_charSet		;right char set?	>
DBCS <	jne	nextBitmap			;branch if not		>
;endif

	call	CheckCloserSize			;see if closer size
	jnc	nextBitmap			;branch if not closer size
	jne	closerSize			;branch if not same size
	mov	bh, ds:[di].PSE_style		;bh <- styles of bitmap
	call	CheckCloserStyles		;see if subset of styles
	jmp	nextBitmap
closerSize:
	mov	bl, ds:[di].PSE_style		;bl <- closest style
DBCS <	mov	bh, ds:[di].PSE_charSet		;bh <- FontCharSet
nextBitmap:
	add	di, size PointSizeEntry		;move to next entry
	jmp	bitmapLoop


takeGuess:
if DBCS_PCGEOS
	cmp	dh, 0xff			;see if any found
	je	fontNotFound2			;nope, bummer
	mov	al, bl				;al <- nearest style
	mov	dl, dh
	clr	ah, dh				;dx.ah <- nearest pointsize
foundFont2:
else
	cmp	bp, 0x8000			;see if any found
	je	fontNotFound			;nope, bummer
	mov	al, bl				;al <- nearest style
	mov	ah, ch
	mov	dx, bp				;dx.ah <- nearest pointsize
endif
	stc					;indicate something close found
done:
	.leave
	ret

	;
	; FontCharSet or style mismatched.  To make sure we get a match,
	; we return the original pointsize, no styles, and grab the
	; first available FontCharSet.  At this point, ds:si points
	; past the last PointSizeEntry, so we use it as that is more
	; convienient than grabbing anything else.
	;
DBCS <fontNotFound2:							>
DBCS <	clr	dh				;dx <- original pointsize >
DBCS <	clr	al				;al <- no styles	>
DBCS <	mov	bh, ds:[si][-(size PointSizeEntry)].PSE_charSet		>
DBCS <	jmp	foundFont2			;branch to return carry set >

fontNotFound:
	clc					;indicate face not found
	jmp	done
FindNearestBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCloserSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if pointsize is closest to requested size.
CALLED BY:	FindNearestBitmap

PASS:	SBCS:
		dx.ah - pointsize to find (WBFixed)
		bp.ch - closest size so far (WBFixed)
		cl - TRUE if absolute closest
		     FALSE if closest smaller size
	DBCS:
		dl - pointsize to find
		dh - closest so far

		ds:di - ptr to PointSizeEntry to check

RETURN:		if carry set:
		    if z flag set:
			SBCS:
			    bp.ch - same size (WBFixed)
			DBCS:
			    dh - same size
		    else:
			SBCS:
			    bp.ch - new closest size (WBFixed)
			DBCS:
			    dh - new closest size
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckCloserSize	proc	near

if DBCS_PCGEOS
	uses	ax
	.enter

	mov	al, dl				;al <- size to find
	sub	al, ds:[di].PSE_pointSize	;al <- distance to size
	mov	ah, dl
	sub	ah, dh				;ah <- distance to closest
	;
	; Make sure the distances are positive
	;
	tst	al
	jns	chkDistPos			;branch if distance positive
	neg	al
chkDistPos:
	tst	ah
	jns	curDistPos			;branch if distance positive
	neg	ah
curDistPos:
	;
	; Compare the distances
	;
	cmp	al, ah				;see if (check < current)
	ja	notCloser
	;
	; This size is closer -- use it
	;
	mov	dh, ds:[di].PSE_pointSize	;dh <- new closer size
	tst	dh				;clear z flag
	stc					;<- indicate new closer size
done:
	.leave
	ret

notCloser:
	clc					;<- indicate not closer size
	jmp	done

else

	uses	ax, bx, dx
	.enter

	mov	al, ah
	mov	bx, dx				;bx.al <- size to find
	sub	al, ds:[di].PSE_pointSize.WBF_frac
	sbb	bx, ds:[di].PSE_pointSize.WBF_int  ;bx.al <- distance to size
	sub	ah, ch
	sbb	dx, bp				;dx.ah <- distance to closest

	tst	cl				;see if absolute closest
	jz	compareSizes			;branch if closest smaller

	tst	bx
	jns	chkDistPos			;branch if distance positive
	NegateFixed bx, al			;bx.al <- absolute distance
chkDistPos:
	tst	dx
	jns	curDistPos			;branch if distance positive
	NegateFixed dx, ah			;dx.ah <- absolute distance
curDistPos:
	;
	; Compare the distances. The distance to the closest
	; so far is always positive. If we're finding the
	; absolute closest, then the distance to the size is
	; positive. If we're finding the closest smaller, and
	; the distance is negative, then the size is smaller
	; and we can ignore it. Finally, we can compare the two
	; distances, which are then both non-negative.
	;
compareSizes:
	tst	bx				;see if size larger
	js	notCloser			;don't want it
	cmp	bx, dx				;see if (check < current)
	jb	closer
	ja	notCloser
	cmp	al, ah				;check fractions if ints equal
	ja	notCloser
	je	isCloser			;branch (z flag set)
closer:
	mov	ch, ds:[di].PSE_pointSize.WBF_frac
	mov	bp, ds:[di].PSE_pointSize.WBF_int ;bp.ch <- new closer size
	tst	bp				;clear z flag
isCloser:
	stc					;<- indicate new closer size
done:
	.leave
	ret

notCloser:
	clc					;<- indicate not closer size
	jmp	done
endif
CheckCloserSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCloserStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if set of styles is closest to requested to set.
CALLED BY:	FindNearestBitmap, FindNearOutline

PASS:		al - styles to match (TextStyle)
		bl - closest styles so far (TextStyle)
		bh - styles to check (TextStyle)
RETURN:		if carry set:
		    if closer subset:
		        bl - closest styles (TextStyle)
		else:
		    wasn't a subset
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	- to determine if a set of styles is a subset of the requested
	  styles:
		issubset = (((requested AND font) XOR font) == 0)
	- to get the weighted difference of styles (assuming is a subset):
		difference = (requested AND font)
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckCloserStyles	proc	near
	uses	cx
	.enter

	mov	cl, bh				;cl <- styles to check
	andnf	cl, al				;cl <- styles in common
	mov	ch, cl				;ch <- weighted difference
	xor	cl, bh				;cl <- zero iff subset (c <- 0)
	jne	notSubset			;branch if not a subset

	mov	cl, bl				;cl <- styles found
	andnf	cl, al				;cl <- styles in common
	cmp	ch, cl				;see if new > current
	jb	notCloser			;not closer subset
	mov	bl, bh				;bl <- new closest styles
notCloser:
	stc					;indicate subset
notSubset:

	.leave
	ret
CheckCloserStyles	endp

GraphicsFonts	ends
