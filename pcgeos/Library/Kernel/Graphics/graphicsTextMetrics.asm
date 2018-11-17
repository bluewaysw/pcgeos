COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		graphicsTextMetrics.asm

AUTHOR:		John Wedgwood & Gene Anderson

ROUTINES:
	Name			Description
	----			-----------
	GrFontMetrics		Get metrics information about a font.

	GrCharWidth		Get width of single character.
	GrTextWidth		Get width of text string (integer)
	GrTextWidthWBFixed	Get width of text string (WBFixed)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	2/ 7/89		Initial revision
	Gene	4/25/89		new version for outline fonts

DESCRIPTION:
	Contains the text metrics routines. Routines for getting information
	about either the current font, a given character, or an entire string.
	All the routines require a GState to operate with.

NOTES:
	All information for fonts is stored in 256th's of 72nd's of an inch.
	The structure that most routines return is WBFixed, which is
	a word of integer, and a byte of fraction.
		eg. 0x0012.0x80 =	 18.50 points
		eg. 0xffee.0x80 =	-18.50 points
		eg. 0x0318.0x40 =	792.25 points

	$Id: graphicsTextMetrics.asm,v 1.1 97/04/05 01:13:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RED <	GraphicsText	segment resource		>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFontMetrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get metrics information about a font.
CALLED BY:	GLOBAL

PASS:		di - GState handle.
		si - information to return (GFM_info)
RETURN:		if GFM_ROUNDED set:
			dx - requested information (rounded)
		else:
			dx.ah - requested information (WBFixed)
		
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Uses the passed enum type (GFM_info) to index into a table of
	offsets. Since the table is made of words, bit 0 is always 0.
	GFM_ROUNDED is 1, so bit 0 is used to indicate whether the
	returned info should be rounded or not.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/28/89		Initial version
	eca	4/25/89		changed calls to GrLockFont
	eca	12/17/89	changes for new font format

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GFMI_WORD	equ	0x8000			;word-sized attribute
GFMI_BYTE	equ	0x4000			;byte-sized attribute

GFM_table	word \
	offset FB_height,			;GFMI_HEIGHT
	offset FB_mean,				;GFMI_MEAN
	offset FB_descent,			;GFMI_DESCENT
	offset FB_baselinePos,			;GFMI_BASELINE
	offset FB_extLeading,			;GFMI_LEADING
	offset FB_avgwidth,			;GFMI_AVERAGE_WIDTH
	offset FB_baselinePos,			;GFMI_ASCENT = baseline - accent
	offset FB_maxwidth,			;GFMI_MAX_WIDTH
	offset FB_height,			;GFMI_MAX_ADJUSTED_HEIGHT
	offset FB_underPos,			;GFMI_UNDER_POS
	offset FB_underThickness,		;GFMI_UNDER_THICKNESS
	offset FB_aboveBox,			;GFMI_ABOVE_BOX
	offset FB_accent,			;GFMI_ACCENT
	offset FB_maker or GFMI_WORD,		;GFMI_DRIVER
	offset FB_kernCount or GFMI_WORD,	;GFMI_KERN_COUNT
					;these two handled specially for DBCS
	offset FB_firstChar or GFMI_BYTE,	;GFMI_FIRST_CHAR
	offset FB_lastChar or GFMI_BYTE,	;GFMI_LAST_CHAR
	offset FB_defaultChar or GFMI_BYTE,	;GFMI_DEFAULT_CHAR
	offset FB_strikePos,			;GFMI_STRIKE_POS
	offset FB_belowBox			;GFMI_BELOW_BOX

CheckHack <size GFM_table eq GFM_info>

GrFontMetrics	proc	far
SBCS <	uses	bx, di, si, ds						>
DBCS <	uses	bx, cx, di, si, ds					>
	.enter

if DBCS_PCGEOS
	;
	; handle GFMI_FIRST_CHAR and GFMI_LAST_CHAR specially
	;
	mov	bx, si
	and	bx, not GFMI_ROUNDED
	cmp	bx, GFMI_FIRST_CHAR
	je	firstChar
	cmp	bx, GFMI_LAST_CHAR
	je	lastChar
endif
	call	LockFontGStateDS		;ds <- seg addr of font
	push	bx				;save font handle
	mov	bx, si				;bl[0] <- rounding bit
	mov	di, si
	and	di, not GFMI_ROUNDED
	;
	; Get the offset from the table, and figure out if its a special value
	;
	mov	si, cs:GFM_table[di]		;ds:si <- offset of info
	test	si, GFMI_WORD or GFMI_BYTE
	jnz	nonWBFixed			;branch if not WBFixed
	mov	dx, ds:[si].WBF_int
	mov	bh, ds:[si].WBF_frac		;dx:bh <- info requested
	;
	; if GFM_ASCENT then calculate: ascent = baseline - accent
	;
	cmp	di, GFMI_ASCENT			;ascent?
	jne	notAscent			;branch if not ascent
	sub	bh, ds:[FB_accent].WBF_frac
	sbb	dx, ds:[FB_accent].WBF_int
notAscent:
	;
	; if GFMI_MAX_ADJUSTED_HEIGHT then calculate
	;	Adjusted height = height + adjustment + above + below.
	;
	cmp	di, GFMI_MAX_ADJUSTED_HEIGHT
	jne	notAdjustedHeight
	add	bh, ds:FB_heightAdjust.WBF_frac
	adc	dx, ds:FB_heightAdjust.WBF_int

	add	bh, ds:FB_aboveBox.WBF_frac
	adc	dx, ds:FB_aboveBox.WBF_int

	add	bh, ds:FB_belowBox.WBF_frac
	adc	dx, ds:FB_belowBox.WBF_int
notAdjustedHeight:
	;
	; Round appropriately
	;
	test	bl, GFMI_ROUNDED		;rounding?
	je	noRound				;branch if not rounding
	rcl	bh, 1				;carry <- high bit
	adc	dx, 0				;dx <- info requested (rounded)
	jmp	afterRound
noRound:
	mov	ah, bh				;dx:ah <- info requested
afterRound:
	pop	bx				;bx <- handle of font

NORED <	call	NearUnlockFont			; unlock the font	>
REDWOOD<call	FontDrUnlockFont					>

DBCS <done:								>
	.leave
	ret

	;
	; The attribute is a word (or a byte, but these will be
	; returned as a word anyway, for DBCS in the future)
	;
nonWBFixed:
	test	si, GFMI_BYTE			;byte attribute?
	jnz	isByte				;branch if is byte
	andnf	si, not (GFMI_WORD)		;si <- offset of attribute
	mov	dx, ds:[si]			;dx <- attribute
	jmp	afterRound
isByte:
	andnf	si, not (GFMI_BYTE)		;si <- offset of attribute
	clr	dh
	mov	dl, ds:[si]			;dx <- attribute
	jmp	afterRound

if DBCS_PCGEOS
firstChar:
	mov	cx, offset FI_firstChar
	jmp	firstLastCommon
lastChar:
	mov	cx, offset FI_lastChar
firstLastCommon:
	xchg	cx, si				;cx = GFMI, si = offset
	push	ax, cx
	call	GrGetFont			;cx = font ID
	call	LockInfoBlock			;ds = seg addr of font info
	call	IsFontAvail			;ds:bx = FontInfo chunk
	jc	haveFont
	call	GrGetDefFontID			;cx = default font ID
	call	IsFontAvail			;ds:bx = FontInfo chunk
haveFont:
	mov	dx, ds:[bx][si]			;dx = desired info
	call	UnlockInfoBlock
	pop	ax, cx
	test	cx, GFMI_ROUNDED
	jnz	done				;return rounded, preserve AX
	clr	ah				;else no rounding, frac=0
	jmp	done
endif
GrFontMetrics	endp

RED <	GraphicsText	ends				>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTextWidth	GrTextWidthWBFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of a string (including kerning).

CALLED BY:	External.
PASS:		ds:si = ptr to the text.
		di = GState.
		cx = max number of characters to check.
RETURN:		dx.ah = width of the string (in points) (GrTextWidthWBFixed)
		dx    = width of the string (in points) (GrTextWidth)
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/28/89		Initial version
	eca	8/27/89		Added check for simple case
	jcw	16-Nov-89	Added support for soft hyphen.
	eca	12/17/89	changes for new font format
	jim	05/09/90	added GrTextWidthFixed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrTextWidth	proc	far
		uses	ax
		.enter
		call	GrTextWidthWBFixed	; do the width thing
		rcl	ah, 1			; round up the result
		adc	dx, 0
		.leave
		ret
GrTextWidth	endp

FastLock2FG	es, di, ax, GTW_gsLock1, GTW_gsLock2

GrTextWidthWBFixed	proc	far
	uses	bx, cx, si, bp, ds, es
DBCS <gstateSeg	local	sptr.GState					>
DBCS <prevFlags	local	CharTableFlags					>
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <	call	ECCheckBounds						>
endif
	push	ax				;save this separately
SBCS <	mov	bp, ds				;bp <- seg addr of string >
DBCS <	mov	dx, ds				;dx <- seg addr of string >
	LoadVarSeg	ds			;ds <- seg addr of idata
	push	ds, di				;save idata, GState handle
	FastLock1	ds, di, ax, GTW_gsLock1, GTW_gsLock2, file-global
	mov	ds, ax				;ds <- seg addr of GState
	;
	; Now lock the font, we need this no matter what...
	;
	call	NearLockFont
SBCS <	push	bx				;save font handle	>
	mov	es, ax				;es <- seg addr of font
	;
	; Load up the textMode...
	;
	mov	bl, ds:GS_textMode		;bl <- TextMode
SBCS <	mov	ax, bp				;ax <- seg addr of string >
SBCS <	mov	bp, ds				;bp <- seg addr of GState >
SBCS <	mov	ds, ax				;ds <- seg addr of string >
DBCS <	mov	ss:gstateSeg, ds		;save seg addr of GState >
DBCS <	mov	ds, dx				;ds <- seg addr of string >
	;
	; es = font segment address.
	; SBCS: bp = GState segment address.
	; bl = TextMode
	;

	mov	di, cx				; Use 'di' for counter.
						;
	clr	dx				; dx.cl = running width
	clr	cx				; cx <- kerning character
SBCS <	clr	bh				; bh <- kern char flags	>
SBCS <	clr	ah				; want ah == 0 always.	>
DBCS <	clr	bh				; dx.bh = running width >
DBCS <	clr	prevFlags						>
charLoop:					;
	LocalGetChar ax, dssi			;
	LocalIsNull ax				;
	jz	endLoop				; Quit on NULL.
						;
	LocalCmpChar	ax, C_SPACE		; Check for a padded space.
	je	spaceChar			; Handle spaces specially.
afterSpaceChar:					;
SBCS <	cmp	al, C_OPTHYPHEN			; Check for optional hyphen. >
DBCS <	LocalCmpChar 	ax, C_SOFT_HYPHEN	; Check for optional hyphen. >
	jne	afterOptHyphen			;
	jmp	optHyphen			;
afterOptHyphen:					;
	;
	; Now add in the character width, checking for a character
	; that is before the first, after the last, or missing.
	;
	push	di, ds				;save count, string seg
	push	ax				;save current char
	segmov	ds, es				;ds <- seg addr
if DBCS_PCGEOS
afterDefault:
	cmp	ax, ds:FB_lastChar		;
	ja	afterLastChar			; Branch if beyond last char
	sub	ax, ds:FB_firstChar		; Adjust and check char
	jb	beforeFirstChar
else
	cmp	al, ds:FB_lastChar		;
	ja	useDefaultChar			; Branch if beyond last char
afterDefault:					;
	sub	al, ds:FB_firstChar		; Adjust and check char
	jb	useDefaultChar
endif
						;
	mov	di, ax				;di <- offset of character
	FDIndexCharTable di, ax			;di <- ptr into width table
	tst	ds:FB_charTable[di].CTE_dataOffset ;see if character missing
	jz	useDefaultChar			;branch if missing
	pop	ax				;ax <- current char
	test	bl, TM_KERNING			;see if any kerning info
	jne	kerned				;branch if any kerning info
SBCS <	add	cl, ds:FB_charTable[di].CTE_width.WBF_frac		>
DBCS <	add	bh, ds:FB_charTable[di].CTE_width.WBF_frac		>
	adc	dx, ds:FB_charTable[di].CTE_width.WBF_int
afterKernedChar:
	pop	di, ds				;di <- count, ds <- string seg
						;
skipChar:					;
SBCS <	mov	ch, al				; ch <- previous character.>
DBCS <	mov	cx, ax				; cx <- previous character.>
						;
	dec	di				; One less character...
	jnz	charLoop			; Loop while not done.
endLoop:

DBCS <	mov	cl, bh				; cl <- fraction	>
SBCS <	pop	bx				; bx <- handle of font	>
SBCS <	call	NearUnlockFont			; unlock the font >
DBCS <	mov	ds, ss:gstateSeg		; ds <- seg addr of GState >
DBCS <	call	UnlockFontFromGState		; unlock the font >
						;
	pop	ds, di				; di <- handle of GState
	FastUnLock	ds, di, ax		; Unlock the GState.
	pop	ax
	mov	ah, cl				; return fraction here
	.leave					;
	ret					;

if DBCS_PCGEOS
	;
	; The character in question is not in the current section
	; of the font.  Lock down the correct section and try again.
	;
beforeFirstChar:
	add	ax, ds:FB_firstChar		;re-adjust character
afterLastChar:
	push	ax
	mov	ds, ss:gstateSeg		;ds <- seg addr of GState
	call	LockCharSet
	mov	ds, ax				;ds <- (new) font seg
	mov	es, ax				;es <- (new) font seg
	pop	ax
	jnc	afterDefault			;branch if char exists
useDefaultChar:
	mov	ax, ds:FB_defaultChar
	jmp	afterDefault

else

useDefaultChar:
	mov	al, ds:FB_defaultChar
	jmp	afterDefault
endif

;******************************************************************************
;
; Add in space padding
;   SBCS:
;	dx.cl = width so far.
;	ax    = current character.
;	ch    = previous character.
;	bp    = segment address of gstate.
;	bl    = TextMode
;   DBCS:
;	dx.bh = width so far
;	cx    = previous character
;	gstateSeg = seg addr of GState
;
spaceChar:
	test	bl, mask TM_PAD_SPACES		; see if non-zero padding
	je	afterSpaceChar			; branch if no padding
	push	ds				; Save string segment.
SBCS <	mov	ds, bp				;			>
DBCS <	mov	ds, ss:gstateSeg		;			>
SBCS <	add	cl, ds:GS_textSpacePad.WBF_frac				>
DBCS <	add	bh, ds:GS_textSpacePad.WBF_frac				>
	adc	dx, ds:GS_textSpacePad.WBF_int
	pop	ds				; Restore string segment.
	jmp	afterSpaceChar			;
;
; Handle soft hyphen character.
;
; Check for on last character of string.
; PASS:
;	ds:si = pointer to next character in string.
;	di    = # of characters left to check.
;	bl    = TextMode
; RETURN:
;	ax    = C_HYPHEN if using hyphen character
;
optHyphen:					;
	test	bl, mask TM_DRAW_OPTIONAL_HYPHENS
	jz	skipChar			; Skip if not desired.
	cmp	di, 1				; If this is the last char
	je	useHyphen			;   use hyphen.
SBCS <	cmp	{byte} ds:[si], 0		; Null signals last char too.>
DBCS <	cmp	{wchar} ds:[si], 0		; Null signals last char too.>
	jne	skipChar			;
useHyphen:					;
SBCS <	mov	al, C_HYPHEN			; Replace with real hyphen. >
DBCS <	LocalLoadChar	ax, C_HYPHEN_MINUS	; Replace with real hyphen. >
	jmp	afterOptHyphen			;

;
; Handle kerned characters.
; PASS:
;   SBCS:
;	dx.cl = width so far (w/o current char)
;	ax    = current character
;	bh    = previous CharTableFlags
;	ch    = previous character
;	bp    = seg addr of gstate
;	ds,es:di = index of CharTableEntry for current char
;   DBCS:
;	dx.bh = width so far (w/o current char)
;	cx    = previous character
;	gstateSeg = seg addr of GState
;	prevFlags = previos CharTableFlags
;
; RETURN:
;   SBCS:
;	dx.cl = updated width (w/ current char, kerning)
;   DBCS:
;	dx.bh = updated width (w/ current char, kerning)
;
kerned:
	push	ax, bx
	push	cx, dx, di

SBCS <	mov	ah, ch				;ah <- prev, al <- current >
SBCS <	test	bh, mask CTF_IS_FIRST_KERN				>
DBCS <	test	ss:prevFlags, mask CTF_IS_FIRST_KERN			>
	pushf					;save flag from test
	clr	bx				;bx <- char width (BBFixed)
	;
	; Adjust the width based on any track kerning.
	;
	push	ds
SBCS <	mov	ds, bp				;ds <- seg addr of gstate >
DBCS <	mov	ds, ss:gstateSeg		;ds <- seg addr of gstate >
	add	bx, {word}ds:GS_trackKernValue	;add track kern value
	pop	ds
	;
	; See if the character is even kernable.
	; If it is kernable, scan the table of kern pairs.
	;
	; No check is done (in the EC version) for no kerning pairs.
	; If the CTF_IS_SECOND_KERN is set and there are no kern
	; pairs, then the font is a bit dorked. So (in the non-EC
	; version) the Z flag is set in case cx == 0, meaning the
	; font is a little dorked...
	; There probably should be an ERROR BAD_FONT_FILE if cx is
	; zero and a character is marked as kernable, but I don't
	; have the bytes for it...
	;
	popf					;from 'test CTF_IS_FIRST_KERN'
	jz	noPairKerning			;branch if not after kernable
if DBCS_PCGEOS
PrintMessage <fix kern code for DBCS in GrTextWidthWBFixed>
	ERROR	-1
endif
	test	ds:FB_charTable[di].CTE_flags, mask CTF_IS_SECOND_KERN
	jz	noPairKerning			;branch if not kernable
	mov	cx, ds:FB_kernCount		;cx <- number of kerning pairs
NEC <	tst	ah				;set Z flag in case cx == 0 >
	mov	di, ds:FB_kernPairPtr		;es:di = kerning table
	repne scasw				;find kerning pair.
	jne	noPairKerning			;quit if not found.
	;
	; Kerning pair was found, adjust the width.
	;
	sub	di, ds:FB_kernPairPtr		;di <- offset to pair (+1)
	add	di, ds:FB_kernValuePtr		;di <- offset to value (+1)
	add	bx, {word}ds:[di-2]		;add pair kern value
noPairKerning:
	pop	cx, dx, di			;dx.cl <- string width so far
	;
	; Don't back up. If pairwise kerning plus track kerning results
	; in a character width of less than zero, set the width to zero.
	;
	mov	al, bh
	cbw					;ax.bl <- kerning
	add	bl, ds:FB_charTable[di].CTE_width.WBF_frac
	adc	ax, ds:FB_charTable[di].CTE_width.WBF_int
	tst	ah				;see if backing up
	js	dontBackUp			;branch if negative width
	add	cl, bl
	adc	dx, ax				;dx.cl <- new string width
dontBackUp:
	pop	ax, bx
	mov	bh, ds:FB_charTable[di].CTE_flags ;save CharTableFlags
DBCS <	mov	ss:prevFlags, bh					>
DBCS <	clr	bh				;fraction		>
	jmp	afterKernedChar

GrTextWidthWBFixed	endp

