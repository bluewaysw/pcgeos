COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	Config
MODULE:		
FILE:		configTitledGlyph.asm

AUTHOR:		Andrew Wilson, Dec  3, 1990

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/90		Initial revision

DESCRIPTION:
	This file contains code to implement TitledGlyph class
	to create nifty titled summons.

	$Id: prefTitledGlyph.asm,v 1.1 97/04/04 17:50:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitledMonikerStruct	struct
	TMS_setfont		OpSetFont
	TMS_textOp		OpDrawText
SBCS <	TMS_text	label	char					>
DBCS <	TMS_text	label	wchar					>
TitledMonikerStruct	ends

;
;	CONSTANTS FOR WIDTHS AND POSITIONS IN TITLED MONIKER
;

TITLE_MAX_LEN			equ	32

if PZ_PCGEOS
TITLED_MONIKER_TITLE_FONT	equ	FID_PIZZA_KANJI	;Title font is Kanji
TITLED_MONIKER_TITLE_SIZE	equ	16		; 16 point
endif

if PZ_PCGEOS
TITLED_MONIKER_WIDTH		equ	75
TITLED_MONIKER_HEIGHT		equ	55
TITLED_BITMAP_WIDTH		equ	64
TITLED_BITMAP_HEIGHT		equ	40
TITLED_MONIKER_MAX_FONT_SIZE	equ	16
else
TITLED_MONIKER_WIDTH		equ	120		; previously 75
TITLED_MONIKER_HEIGHT		equ	58		; previously 52
TITLED_BITMAP_WIDTH		equ	64
TITLED_BITMAP_HEIGHT		equ	40
TITLED_MONIKER_MAX_FONT_SIZE	equ	14
endif

TITLED_MONIKER_BITMAP_X_OFFSET	equ	(TITLED_MONIKER_WIDTH - \
					 TITLED_BITMAP_WIDTH) / 2
TITLED_MONIKER_BITMAP_Y_OFFSET	equ	2

CGA_TITLED_MONIKER_WIDTH	equ	TITLED_MONIKER_WIDTH
CGA_TITLED_MONIKER_HEIGHT	equ	30
CGA_TITLED_BITMAP_WIDTH		equ	TITLED_BITMAP_WIDTH
CGA_TITLED_BITMAP_HEIGHT	equ	18



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CombineTextAndGraphicsMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	combine text & gstring monikers into a single moniker

CALLED BY:	ConfigBuildTitledMoniker, ConfigBuildTitledMonikerUsingToken

PASS:		*ds:si - gstring moniker
		*es:di - text moniker
		al - DisplayType

RETURN:		*ds:si - (modified) gstring moniker returned

DESTROYED:	nothing.  ES will NOT be fixed up if moved!

PSEUDO CODE/STRATEGY:	
	The moniker is created in the block pointed to by DS

	A GrRelMoveTo is inserted before the bitmap to move it
		down and center it horizontally

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CombineTextAndGraphicsMonikers	proc near
	uses	ax,bx,cx,dx,di,si,es

visMoniker	local	lptr	push	si
textLength	local	word
textWidth	local	word
textYPos	local	word
displayType	local	DisplayType
SBCS <titleStr	local	TITLE_MAX_LEN+4 dup (char)			>
DBCS <titleStr	local	TITLE_MAX_LEN+4 dup (wchar)			>
						;Title max size + null +
						; room for ellipsis
	.enter

	mov	displayType, al

	;
	; Copy text onto the stack, so we can truncate it if
	; necessary.  Do this first, so that we can forget about
	; ES.
	;
	push	ds, si
	segmov	ds, es
	segmov	es, ss	
	mov	si, ds:[di]			;DS:SI <- text moniker
	add	si, offset VM_data + offset VMT_text
	segmov	es, ss
	lea	di, ss:[titleStr]		;ES:DI <- where to put title
	mov	cx, TITLE_MAX_LEN
	LocalCopyNString			;Copy data over from title 
	pop	ds, si

	;
	; Insert a GrRelMoveTo command at the beginning of the gstring.
	;
	mov	cx, size OpRelMoveTo
	mov	ax, si				; chunk handle
	mov	bx, offset VM_data+VMGS_gstring
	call	LMemInsertAt

	;
	; Now, insert the GrRelMoveTo command -- move over 5 and down
	; 2.  These should be constants, I suppose...  I'm relying on
	; the fact that LMemInsertAt zero-initializes the fractional
	; data. 
	;
	mov	bx, ds:[si]
	mov	ds:[bx].VM_data+VMGS_gstring+ORMT_opcode, GR_REL_MOVE_TO
	mov	ds:[bx].VM_data+VMGS_gstring+ORMT_x1.WWF_int, \
			TITLED_MONIKER_BITMAP_X_OFFSET
	mov	ds:[bx].VM_data+VMGS_gstring+ORMT_y1.WWF_int, \
			TITLED_MONIKER_BITMAP_Y_OFFSET
	mov	ds:[bx].VM_width, TITLED_MONIKER_WIDTH

	;
	; GET INFORMATION ABOUT TITLE AND CLIP IF NECESSARY
	;
	lea	si, ss:[titleStr]		;ES:SI <- ptr to text
	mov	bx, TITLED_MONIKER_WIDTH		;
if PZ_PCGEOS
	mov	cx, TITLED_MONIKER_TITLE_FONT	;
	mov	dx, TITLED_MONIKER_TITLE_SIZE	;
else
	call	UserGetDefaultMonikerFont
endif
	push	cx, dx
	call	GetTitleInfo			;Returns strlen in CX and width
						; in BX (Clips title and adds
						; ellipsis if necessary)
	mov	ss:[textLength], cx
	mov	ss:[textWidth], bx

	;
	; REALLOCATE MONIKER CHUNK.  Add the text at the end
	;
	mov	si, ss:[visMoniker]
	mov	di, ds:[si]
	ChunkSizePtr	ds, di, dx
DBCS <	shl	cx, 1				; # chars -> # bytes	>
	add	cx, dx
	add	cx, size TitledMonikerStruct
	mov	ax, si				; chunk handle
	call	LMemReAlloc

	;
	; Mark this chunk not dirty again, as it's a VisMoniker, and
	; we don't like to save these things to state.
	;
	push	bx
	mov	bx, mask OCF_DIRTY shl 8
	call	ObjSetFlags
	pop	bx

	;
 	; DEREF CHUNK -- get old and store new height
	;
	mov	di, ds:[si]
	mov	ax, ({VisMonikerGString} ds:[di].VM_data).VMGS_height
	mov	textYPos, ax

	;
	; We choose the TITLED_MONIKER_HEIGHT for every case but
	; DS_TINY && DAR_VERY_SQUISHED. This allows things like the Zoomer
	; to use larger artwork, even though the screen is small
	;
	push	bx
	mov	bl, displayType
	mov	bh, bl
	andnf	bl, mask DT_DISP_SIZE
	cmp	bl, (DS_TINY shl offset DT_DISP_SIZE)
	mov	ax, TITLED_MONIKER_HEIGHT
	jne	gotHeight
	andnf	bh, mask DT_DISP_ASPECT_RATIO
	cmp	bh, (DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO)
	jne	gotHeight
	mov	ax, CGA_TITLED_MONIKER_HEIGHT
gotHeight:
	pop	bx
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, ax
	
	add	di, dx				; move to the end of gstring
	dec	di
EC <	cmp	{byte} ds:[di], GR_END_GSTRING	>
EC <	ERROR_NE CONFIG_INVALID_GSTRING		>

	;
	; Fill in textual data
	;
	mov	ds:[di].TMS_setfont.OSF_opcode, GR_SET_FONT
	clr	ds:[di].TMS_setfont.OSF_size.WBF_frac
	pop	ax				; restore font size => AX
	mov	ds:[di].TMS_setfont.OSF_size.WBF_int, ax
	sub	ax, TITLED_MONIKER_MAX_FONT_SIZE ; "bottom justify (really
	sub	textYPos, ax			 ; ...center) the text
	pop	ax				; restore font => AX
	mov	ds:[di].TMS_setfont.OSF_id, ax
	mov	ax, TITLED_MONIKER_WIDTH
	sub	ax, bx				; string width
	shr	ax, 1				;AX <- offset to draw text at.
	mov	ds:[di].TMS_textOp.ODT_x1, ax

	mov	ax, textYPos
	mov	ds:[di].TMS_textOp.ODT_y1, ax

	mov	ds:[di].TMS_textOp.ODT_opcode, GR_DRAW_TEXT

	mov	ax, textLength
	mov	ds:[di].TMS_textOp.ODT_len, ax

	add	di, offset TMS_text
	segmov	es, ds				;Save object block
	segmov	ds, ss
	lea	si, ss:[titleStr]
	mov	cx, textLength
	LocalCopyNString			;Copy over string

	mov	al, GR_END_GSTRING
	stosb

	segmov	ds, es				;Restore object block

	.leave
	ret
CombineTextAndGraphicsMonikers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigBuildTitledMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Global routine to build a titled moniker based on the
		passed moniker list

CALLED BY:	TitledGlyphSpecBuild

PASS:		*ds:si - visMoniker list

RETURN:		nothing -- vis moniker list replaced with vis moniker.

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Stick the text as a gstring op code after the bitmap (could go
	before, too, I guess...)

	Update the vis moniker's width to be the max of the bitmap and
	the text width.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/90	Initial version
	CDB	4/ 6/92   	Revised to use standard monikers.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConfigBuildTitledMoniker	proc far
	uses	ax,bx,cx,dx,di,si,bp,es

visMoniker	local	lptr
displayType	local	DisplayType

	.enter

	; If moniker is not a list, then exit

	push	si
	mov	si, ds:[si]
	test	ds:[si].VM_type, mask VMT_MONIKER_LIST
	pop	si
	jz	done

	;	
	; get the text moniker	
	;

	mov	ss:[visMoniker], si

	mov	di, si
	mov	cx, ds:[LMBH_handle]

	call	UserGetDisplayType
	mov	displayType, ah
	mov	bh, ah
	push	bp
	mov	bp, VMS_TEXT shl offset VMSF_STYLE
	call	VisFindMoniker			; ^lcx:dx - text moniker
	pop	bp

	
	push	cx, dx				; text moniker

	; get picture moniker -- replace original moniker.

	mov	di, visMoniker
	mov	bh, displayType
	push	bp
	mov	bp, mask VMSF_REPLACE_LIST or mask VMSF_GSTRING or \
				(VMS_ICON shl offset VMSF_STYLE) 
	call	VisFindMoniker		; *ds:dx - picture moniker
	pop	bp

	pop	bx, di				; ^lbx:di - text moniker
	call	ObjLockObjBlock
	mov	es, ax				; *es:di - text moniker
	
	mov	si, dx
	mov	al, displayType
	call	CombineTextAndGraphicsMonikers

	call	MemUnlock			; unlock text block
done:
	.leave
	ret
ConfigBuildTitledMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CONFIGBUILDTITLEDMONIKER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a moniker for a titled glyph from a moniker list,
		combining one of the graphical elements with the text
		element.

CALLED BY:	GLOBAL
PARAMETERS:	void (optr monikerList)
SIDE EFFECTS:	monikerList chunk is replaced by a moniker.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CONFIGBUILDTITLEDMONIKER proc	far
	C_GetOneDWordArg	bx, ax,  cx, dx
	push	ds, si
	mov_tr	si, ax
	call	ObjLockObjBlock
	mov	ds, ax		; *ds:si <- list
	call	ConfigBuildTitledMoniker
	call	MemUnlock
	pop	ds, si
	ret
CONFIGBUILDTITLEDMONIKER endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigBuildTitledMonikerUsingToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Combine 2 vis monikers -- placing the text moniker
		centered below the picture moniker

CALLED BY:	GLOBAL

PASS:		ds - lmem block in which to create moniker
		ax:bx:si - token characters

RETURN:		if token found:
			carry clear
			*ds:dx - new moniker
		else:
			carry set -- moniker not found in token DB

DESTROYED:	ax,bx,cx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/27/92   	Initial version.
	jenny	5/22/93		Rewrote for token database API change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigBuildTitledMonikerUsingToken	proc far

	uses	es, si

blockHandle	local	hptr	push	ds:[LMBH_handle]
displayType	local	DisplayType

	.enter

	;
	; Get the display type.
	;

	push	ax
	call	UserGetDisplayType
	mov	displayType, ah
	mov	dh, ah
	pop	ax

	;
	; Get picture moniker -- copying it into this block
	;

	mov	cx, ss:[blockHandle]
	mov	di, (VMS_ICON shl offset VMSF_STYLE) or mask \
			VMSF_COPY_CHUNK or mask VMSF_GSTRING
	push	di
	clr	di
	push	di			; garbage push
	call	TokenLoadMoniker	; di <- gstring moniker
					;  chunk handle
	jc	done

	;
	; Get (and lock) the text moniker
	;

	push	bp
	mov	bp, (VMS_TEXT shl offset VMSF_STYLE)
	call	TokenLookupMoniker	; ax <- shared/local token db flag
	pop	bp

	jc	done

	push	ax			; save shared/local flag
	call	TokenLockTokenMoniker	; *ds:bx - text moniker

	;
	; Combine the two.
	;

	segmov	es, ds
	mov	si, di				; si <- gstring
						;  moniker chunk handle
	mov	di, bx				; *es:di - text moniker
	mov	bx, ss:[blockHandle]
	call	MemDerefDS			; *ds:si - gstring moniker
	mov	al, displayType
	call	CombineTextAndGraphicsMonikers	; *ds:si - new moniker

	;
	; Unlock the text moniker.
	;

	pop	ax			; ax <- shared/local token db flag
	push	ds
	segmov	ds, es
	call	TokenUnlockTokenMoniker
	mov	dx, si
	pop	ds			; *ds:dx - new moniker
	clc
done:
	.leave
	ret
ConfigBuildTitledMonikerUsingToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CONFIGBUILDTITLEDMONIKERUSINGTOKEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Similar to ConfigBuildTitledMoniker, but uses the moniker 
		list for a token in the token database.

CALLED BY:	GLOBAL
PARAMETERS:	ChunkHandle (GeodeToken *, MemHandle)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CONFIGBUILDTITLEDMONIKERUSINGTOKEN proc	far
	C_GetThreeWordArgs	cx, dx, bx, ax	; cx:dx <- GeodeToken *
						; bx <- destBlock
	push	ds, si, bx, di		; di nuked by real routine
	movdw	dssi, cxdx
	mov	ax, {word}ds:[si].GT_chars[0]
	mov	cx, {word}ds:[si].GT_chars[2]
	mov	si, ds:[si].GT_manufID
	call	ObjLockObjBlock
	mov	ds, ax			; ds <- dest block
	mov	bx, cx			; ax:bx:si <- token
	call	ConfigBuildTitledMonikerUsingToken
	pop	ds, si, bx, di
	call	MemUnlock
	mov	ax, 0		; assume token not found
	jc	done
	mov_tr	ax, dx		; wrong. return chunk handle
done:
	ret
CONFIGBUILDTITLEDMONIKERUSINGTOKEN endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTitleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the width/length of the passed string and 
		clips it if necessary.

CALLED BY:	CombineTextAndGraphicsMonikers

PASS:		ES:SI - null-terminated string
		BX - width to clip to
		CX - font ID
		DX - point size of font

RETURN:		CX - string length, including NULL
		BX - pixel width

DESTROYED:	di, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTitleInfo	proc	near
	uses	ax,ds,bp
	.enter
	segmov	ds,es,di			;DS:SI <- ptr to string
	push	cx, dx
	mov	di, si				;ES:DI <- ptr to string
	call	LocalStringLength		;cx = length w/o null
	inc	cx				;cx = length w/ null
	push	cx				;Save length	
	clr	di
	call	GrCreateState			;Get a GState to manipulate
	pop	ax				;Restore string len
	pop	cx, dx				;Restore Font/Pt Size
	push	ax				;Save string len
	clr	ah				;
	call	GrSetFont			;
	clr	cx				;
	call	GrTextWidth			;Do trivial reject -- entire 
						; string fits
	pop	cx				;CX <- string length
	mov	bp,dx				;BP <- pixel width
	cmp	bp, bx				;If width < moniker width, then
	jle	noclip				; no clipping, dude!
	LocalLoadChar	ax, '.'			;Get width of a '.'
SBCS <	clr	ah							>
	call	GrCharWidth			;	
	mov	bp, dx				;BP <- width of '.' * 3...
	shl	dx, 1				;
	add	bp, dx				;
	clr	cx
cliploop:
	inc	cx
	LocalGetChar	ax, dssi		;Get next character from string
	call	GrCharWidth
	add	bp,dx				;BP += width of next char
	cmp	bp, bx				;
	jl	cliploop			;
	sub	bp, dx				;BP <- real width
	LocalLoadChar	ax, '.'			;Add '...'
	push	di				;Save GState
	lea	di, ds:[si]
	LocalPrevChar	esdi
	LocalPutChar	esdi, ax
	LocalPutChar	esdi, ax
	LocalPutChar	esdi, ax
	clr	ax				;Add null terminator
	LocalPutChar	esdi, ax
	add	cx, 3				;CX <- clipped string length
	pop	di				;Restore GState
noclip:
	call	GrDestroyState
	mov	bx, bp				; return width
	.leave
	ret
GetTitleInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitledGlyphSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We intercept SpecBuild and create a moniker for the glyph
		(a nifty one, with a title and *everything*).

CALLED BY:	GLOBAL

PASS:		*ds:si - TitledGlyph object

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TitledGlyphSpecBuild	method dynamic TitledGlyphClass, 
							MSG_SPEC_BUILD
	push	si
	mov	si, ds:[di].GI_visMoniker
	call	ConfigBuildTitledMoniker
	pop	si

	; Now, call superclass

	mov	di, offset TitledGlyphClass
	GOTO	ObjCallSuperNoLock
TitledGlyphSpecBuild	endm


