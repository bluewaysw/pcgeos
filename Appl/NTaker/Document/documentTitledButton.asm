COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	NTaker
MODULE:		Document
FILE:		documentTitledButton.asm

AUTHOR:		Andrew Wilson, Dec  3, 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/90		Initial revision

DESCRIPTION:
	This file contains code to implement the TitledGenTriggerClass and
	to create nifty titled summons.

	$Id: documentTitledButton.asm,v 1.1 97/04/04 16:17:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitledMonikerPrologue	struc
	TMP_height		word	(?)
	TMP_drawbitmapOp	byte	(?)
	TMP_drawbitmapX	word	(?)
	TMP_drawbitmapY	word	(?)
	TMP_drawbitmapOptr	optr	(?)
	TMP_setfontOp		byte	(?)
	TMP_setfontPtFrac	byte	(?)
	TMP_setfontPtInt	word	(?)
	TMP_setfontID		word	(?)
	TMP_drawtextOp	byte	(?)
	TMP_drawtextX		word	(?)
	TMP_drawtextY		word	(?)
	TMP_drawtextLen	word	(?)
TitledMonikerPrologue	ends

.assert	(TMP_drawbitmapOp eq VMGS_gstring)
	
;
;	CONSTANTS FOR WIDTHS AND POSITIONS IN TITLED MONIKER
;

TITLE_MAX_LEN			equ	32
TITLED_MONIKER_TITLE_FONT	equ	FID_BERKELEY
;Title font is Berkeley

TITLED_MONIKER_TITLE_SIZE	equ	9

TITLED_MONIKER_WIDTH		equ	64
TITLED_MONIKER_HEIGHT		equ	34
TITLED_BITMAP_WIDTH		equ	48

CGA_TITLED_MONIKER_WIDTH	equ	TITLED_MONIKER_WIDTH
CGA_TITLED_MONIKER_HEIGHT	equ	24
CGA_TITLED_BITMAP_WIDTH		equ	TITLED_BITMAP_WIDTH

TITLED_MONIKER_TEXT_OFFSET	equ	23
CGA_TITLED_MONIKER_TEXT_OFFSET	equ	14
TITLED_MONIKER_BITMAP_OFFSET	equ	2

TitleCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitledGenTriggerSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We intercept SpecBuild and create a moniker for the glyph
		(a nifty one, with a title and *everything*).

CALLED BY:	GLOBAL
PASS:		normal object params
		bp = SpecBuildFlags
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TitledGenTriggerSpecBuild	method dynamic TitledGenTriggerClass,
							 MSG_SPEC_BUILD
	mov	bx, ds:[di].TGTI_title		;*DS:BX <- title text	
	clr	ax
	mov	al, ds:[di].TGTI_pictureNumber	;AX <- title text
	mov	di, offset TitledGenTriggerClass
	FALL_THRU	DoSpecBuildCommon
TitledGenTriggerSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoSpecBuildCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine handles creating a titled vis moniker for the 
		passed object and for passing MSG_SPEC_BUILD off to the 
		superclass.

CALLED BY:	GLOBAL
PASS:		*DS:BX - ptr to title text
		AX - picture number
		CX, DX, BP - MSG_SPEC_BUILD parameters
			bp - SpecBuildFlags
		ES:DI - ptr to class of object
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoSpecBuildCommon	proc	far
	test	bp, mask SBF_WIN_GROUP		; if doing win group, moniker
	jnz	done				; for button has already been
						; set, don't bother again
	push	es,cx,dx,bp,di		; preserve SpecBuildFlags

	push	bx			; title text

EC <	cmp	ax, NUM_CGA_TITLED_MONIKERS				>
EC <	ERROR_AE BAD_PICTURE_NUMBER					>

	push	ax
	push	si			;Save ptr to titled object
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	clr	bx
	call	GeodeGetAppObject
	mov	di,mask MF_CALL
	call	ObjMessage			;Get app display scheme in AH
	pop	si				;Restore ptr to titled object
	mov	al, ah				;copy display type to AL
	andnf	ah, mask DT_DISP_ASPECT_RATIO
	mov	di, offset CGATitledMonikers
	cmp	ah, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
	je	10$				;CGA
	mov	di, offset VGATitledMonikers
	cmp	ah, DAR_NORMAL
	je	8$				;VGA or MCGA
	mov	di, offset EGATitledMonikers	;else, EGA or HGC
8$:
	and	al, mask DT_DISP_CLASS		;Get display class
	cmp	al, DC_GRAY_1			;Are we on a monochrome display
	jne	10$				;EGA
	mov	di, offset HGCTitledMonikers
10$:
	pop	bp			;Restore picture number
	shl	bp,1			;Multiply picture # by 4 (size of table
	shl	bp,1			; entry -- optr)

;	SET UP MONIKER

	mov	cx, ({optr} cs:[di][bp]).handle	;^lCX:DX <- bitmap to put in 
	mov	dx, ({optr} cs:[di][bp]).chunk	; moniker
	pop	bx				;Restore title chunk
	call	TitledObjectSetMoniker

	pop	es,cx,dx,bp,di		; restore SpecBuildFlags
done:
				; Continue by calling superclass with same
				;	method
	mov	ax, MSG_SPEC_BUILD
	GOTO	ObjCallSuperNoLock
DoSpecBuildCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitledObjectSetMoniker	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method combines the passed moniker and passed title
		chunk to be one beautiful moniker. 
CALLED BY:	GLOBAL
PASS:		CX:DX - optr of bitmap to be part of GCM moniker
		BX - title chunk
		*DS:SI - object to set moniker for

RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TitledObjectSetMoniker	proc	near
	bitmap		local	optr
	object		local	lptr
	titleStr	local	TITLE_MAX_LEN+4 dup (char)
						;Title max size + null +
						; room for ellipsis
	
	.enter

;	SET UP LOCALS

	mov	object, si
	mov	bitmap.handle, cx
	mov	bitmap.chunk, dx

;	COPY TITLE DATA OUT OF CHUNK AND ONTO STACK FOR MANIPULATION

	mov	si, ds:[bx]			;DS:SI <- ptr to title data
	segmov	es, ss
	lea	di, titleStr			;ES:DI <- where to put title
						; data
	ChunkSizePtr	ds, si, cx
EC <	cmp	cx, TITLE_MAX_LEN		>
EC <	ERROR_AE TITLED_OBJECT_BAD_TITLE	>

	inc	cx
	shr	cx, 1				;CX <- # words
	rep	movsw				;Copy data over from title 

;	GET INFORMATION ABOUT TITLE AND CLIP IF NECESSARY

	lea	si, titleStr			;ES:SI <- ptr to title
	mov	bx, TITLED_MONIKER_WIDTH		;
	mov	cx, TITLED_MONIKER_TITLE_FONT	;
	mov	dx, TITLED_MONIKER_TITLE_SIZE	;
	call	GetTitleInfo			;Returns strlen in CX and width
						; in BP (Clips title and adds
						; ellipsis if necessary)

;	ALLOCATE MONIKER CHUNK

						;CX <- total size of moniker
	add	cx, size TitledMonikerPrologue + size VisMoniker + size OpEndGString

	mov	al, mask OCF_DIRTY		;Save this to the state file.
	call	LMemAlloc			;Allocate the moniker

;	FILL IN MONIKER CHUNK 

	push	cx,dx, ax, bp
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	clr	bx
	call	GeodeGetAppObject
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;Get app display scheme in AH
	segmov	es,ds,di			;ES <- moniker segment
	pop	cx, dx, di, bp
	push	di
	mov	di,ds:[di]			;Deref moniker chunk
	mov	ds:[di].VM_width, TITLED_MONIKER_WIDTH ;Set cached size
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, \
				TITLED_MONIKER_HEIGHT
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextY, TITLED_MONIKER_TEXT_OFFSET

	cmp	ah, CGA_DISPLAY_TYPE
	jne	notCGA				;Adjust height for CGA
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextY, CGA_TITLED_MONIKER_TEXT_OFFSET
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, \
				CGA_TITLED_MONIKER_HEIGHT
notCGA:

	; See if b/w (GRAY_1) or not

	and	ah, mask DT_DISP_CLASS
	cmp	ah, DC_GRAY_1 shl offset DT_DISP_CLASS
	jne	drawOp
	mov	({TitledMonikerPrologue}ds:[di].VM_data).TMP_drawbitmapOp, \
						GR_FILL_BITMAP_OPTR
	jmp	gotOp
drawOp:
	mov	({TitledMonikerPrologue}ds:[di].VM_data).TMP_drawbitmapOp, \
						GR_DRAW_BITMAP_OPTR
gotOp:

	mov	ds:[di].VM_type,( mask VMT_GSTRING or (DAR_NORMAL shl offset VMT_GS_ASPECT_RATIO) or (DC_GRAY_1 shl offset VMT_GS_COLOR) )
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapX, (TITLED_MONIKER_WIDTH - TITLED_BITMAP_WIDTH)/2
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapY, TITLED_MONIKER_BITMAP_OFFSET
	mov	ax, bitmap.handle	
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapOptr.handle, ax
	mov	ax, bitmap.chunk
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapOptr.chunk, ax
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_setfontOp, GR_SET_FONT
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_setfontPtFrac, 0
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_setfontPtInt, TITLED_MONIKER_TITLE_SIZE
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_setfontID, TITLED_MONIKER_TITLE_FONT
	mov	ax, TITLED_MONIKER_WIDTH
	sub	ax,dx
	shr	ax,1				;AX <- offset to draw text at.
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextX, ax
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextOp, GR_DRAW_TEXT
	sub	cx, size TitledMonikerPrologue + size VisMoniker + size OpEndGString
						;CX <- byte length of title
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextLen, cx
						;Store string byte length
						;ES:DI <- ptr to store title
	add	di,size TitledMonikerPrologue + size VisMoniker	

	push	ds				;Save object block
	segmov	ds, ss, si			;
	lea	si, titleStr			;DS:SI <- title string
	rep	movsb				;Copy over string
	mov	es:[di].OEGS_opcode, GR_END_GSTRING	;End the string
	pop	ds				;Restore object block
	pop	cx				;Restore moniker chunk handle
	push	bp
	mov	si, object
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	;Update the moniker
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	call	ObjCallInstanceNoLock
	pop	bp
	.leave
	ret
TitledObjectSetMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTitleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the width/length of the passed string and 
		clips it if necessary.

CALLED BY:	GLOBAL
PASS:		ES:SI - null-terminated string
		BX - width to clip to
		CX - font ID
		DX - point size of font
RETURN:		CX - string length
		DX - pixel width
DESTROYED:	di, si
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

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
	mov	cx, -1				;
	clr	al				;
	repne	scasb				;
	not	cx				;CX <- length of string
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
	mov	al, '.'				;Get width of a '.'
	call	GrCharWidth			;	
	mov	bp, dx				;BP <- width of '.' * 3...
	shl	dx, 1				;
	add	bp, dx				;
	clr	cx
cliploop:
	inc	cx
	lodsb					;Get next character from string
	call	GrCharWidth
	add	bp,dx				;BP += width of next char
	cmp	bp, bx				;
	jl	cliploop			;
	sub	bp, dx				;BP <- real width
	mov	al, '.'				;Add '...'
	push	di				;Save GState
	lea	di, ds:[si][-1]
	stosb
	stosb
	stosb
	clr	al				;Add null terminator
	stosb
	add	cx, 3				;CX <- clipped string length
	pop	di				;Restore GState
noclip:
	call	GrDestroyState
	mov	dx, bp
	.leave
	ret
GetTitleInfo	endp

VGATitledMonikers	label	optr
EGATitledMonikers	optr	UpArrowSCMoniker
			optr	DownArrowSCMoniker
			optr	NewCardSCMoniker

.assert ($-EGATitledMonikers)/4 eq PictureNumber

HGCTitledMonikers	optr	UpArrowSMMoniker
			optr	DownArrowSMMoniker
			optr	NewCardSMMoniker

NUM_HGC_TITLED_MONIKERS	equ	($-HGCTitledMonikers)/4

.assert	NUM_HGC_TITLED_MONIKERS eq PictureNumber

CGATitledMonikers	optr	UpArrowSCGAMoniker
			optr	DownArrowSCGAMoniker
			optr	NewCardSCGAMoniker

NUM_CGA_TITLED_MONIKERS	equ	($-CGATitledMonikers)/4

.assert	NUM_CGA_TITLED_MONIKERS eq PictureNumber

TitleCode	ends
