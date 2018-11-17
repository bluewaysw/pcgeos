COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscTitle.asm

AUTHOR:		Andrew Wilson, Dec  3, 1990

ROUTINES:
	Name			Description
	----			-----------
	TitledGlyphSpecBuild	Intercept SpecBuild and create a moniker
	DoSpecBuildCommon	Create a titled vis moniker
	TitledObjectSetMoniker	Combine the passed moniker and passed title
	GetTitleInfo		Get the width/length of the passed string
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/3/90		Initial revision

DESCRIPTION:
	This file contains code to implement the TitledNotifySummonsClass and
	to create nifty titled summons.

	$Id: miscTitle.asm,v 1.1 97/04/04 15:50:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GPC

TitledMonikerPrologue	struct
	TMP_height		word	(?)
	TMP_drawbitmapOp	byte	(?)
	TMP_drawbitmapX		word	(?)
	TMP_drawbitmapY		word	(?)
	TMP_drawbitmapOptr	optr	(?)
	TMP_setfontOp		byte	(?)
	TMP_setfontPtFrac	byte	(?)
	TMP_setfontPtInt	word	(?)
	TMP_setfontID		word	(?)
	TMP_drawtextOp		byte	(?)
	TMP_drawtextX		word	(?)
	TMP_drawtextY		word	(?)
	TMP_drawtextLen		word	(?)
TitledMonikerPrologue	ends

.assert	(TMP_drawbitmapOp eq size VisMonikerGString)
	
TitledIcon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitledGlyphSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We intercept SpecBuild and create a moniker for the glyph
		(a nifty one, with a title and *everything*).

CALLED BY:	GLOBAL
PASS:		normal object params
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
TitledGlyphSpecBuild	method dynamic TitledGenTriggerClass, MSG_SPEC_BUILD
	mov	bx, ds:[di].TGTI_title		;*DS:BX <- title text	
	clr	ax
	mov	al,ds:[di].TGTI_pictureNumber	;AX <- title text
	mov	di, offset TitledGenTriggerClass
	GOTO	DoSpecBuildCommon
TitledGlyphSpecBuild	endm


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
	push	es,cx,dx,bp,di		; preserve SpecBuildFlags
	push	bx
EC <	cmp	ax, NUM_CGA_TITLED_MONIKERS				>
EC <	ERROR_AE BAD_PICTURE_NUMBER					>
	push	ax
	push	si			;Save ptr to titled object
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	GetResourceHandleNS	RolodexApp, bx
	mov	si, offset RolodexApp
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
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
	mov	ax, bp			; ax - picture number
	shl	bp,1			;Multiply picture # by 4 (size of table
	shl	bp,1			; entry -- optr)

;	SET UP MONIKER

	mov	cx, ({optr} cs:[di][bp]).handle	;^lCX:DX <- bitmap to put in 
	mov	dx, ({optr} cs:[di][bp]).chunk	; moniker
	pop	bx				;Restore title chunk
	call	TitledObjectSetMoniker

	pop	es,cx,dx,bp,di		; restore SpecBuildFlags
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
		AX - picture number
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TitledObjectSetMoniker	proc	near
	bitmap		local	optr
	object		local	lptr
SBCS <	titleStr	local	TITLE_MAX_LEN+4 dup (char)		>
DBCS <	titleStr	local	TITLE_MAX_LEN+4 dup (wchar)		>
						;Title max size + null +
						; room for ellipsis
	height		local	word		; height of the button
	bitmapWidth	local	word		; width of the bitmap
	titleOffset	local	word		; text offset
	cgaHeight	local	word		; height of CGA button
	cgaOffset	local	word		; text offset in CGA button
	pictureNumber	local	word		; picture number

	.enter

;	SET UP LOCALS

	mov	object, si
	mov	bitmap.handle, cx
	mov	bitmap.chunk, dx

	mov	pictureNumber, ax		; save the picture number
	shl	ax, 1				; (picture number) * 2 
	mov	di, ax				; di - offset to table
	mov	ax, cs:MonikerHeightTable[di]	; ax - height of the button
	mov	height, ax
	mov	ax, cs:MonikerOffsetTable[di]	; ax - text y offset
	mov	titleOffset, ax
	mov	ax, cs:BitmapWidthTable[di]	; ax - bitmap width
	mov	bitmapWidth, ax
	mov	ax, cs:CGAMonikerHeightTable[di]	; cga height
	mov	cgaHeight, ax
	mov	ax, cs:CGAMonikerOffsetTable[di]	; cga text offset
	mov	cgaOffset, ax

;	COPY TITLE DATA OUT OF CHUNK AND ONTO STACK FOR MANIPULATION

	mov	si, ds:[bx]			;DS:SI <- ptr to title data
	segmov	es, ss
	lea	di, titleStr			;ES:DI <- where to put title
						; data
	ChunkSizePtr	ds, si, cx
	inc	cx
	shr	cx, 1				;CX <- # words
	rep	movsw				;Copy data over from title 

;	NUKE OLD VIS MONIKER

	push	bp				;Save ptr to locals
	mov	si, object			;
	mov	ax, MSG_GEN_GET_VIS_MONIKER	;
	call	ObjCallInstanceNoLock		;
	push	ax				;Save vis moniker chunk
	clr	cx				;Nuke old vis moniker
	mov	ax, MSG_GEN_USE_VIS_MONIKER	;
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE	;
	call	ObjCallInstanceNoLock		;
	pop	ax				;Get vis moniker chunk
	tst	ax				;If no chunk, exit
	jz	10$				;
	call	LMemFree			;Else, free old vis moniker
10$:
	pop	bp				;Restore ptr to locals

;	GET INFORMATION ABOUT TITLE AND CLIP IF NECESSARY

	lea	si, titleStr			;ES:SI <- ptr to title
	mov	bx, TITLED_MONIKER_WIDTH		;
	mov	cx, TITLED_MONIKER_TITLE_FONT	;
	mov	dx, TITLED_MONIKER_TITLE_SIZE	
	call	GetTitleInfo			;Returns strsize in CX and width
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
	GetResourceHandleNS	RolodexApp, bx
	mov	si, offset RolodexApp
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;Get app display scheme in AH
	segmov	es,ds,di			;ES <- moniker segment
	pop	cx, dx, di, bp
	push	di
	mov	di,ds:[di]			;Deref moniker chunk
	mov	ds:[di].VM_width, TITLED_MONIKER_WIDTH ;Set cached size
	push	ax
	mov	ax, height
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, ax
	mov	ax, titleOffset
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextY, ax
	pop	ax
	cmp	ah, CGA_DISPLAY_TYPE
	jne	notCGA				;Adjust height for CGA

	mov	ax, cgaOffset
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextY, ax
	mov	ax, cgaHeight
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, ax
notCGA:
	mov	ds:[di].VM_type,( mask VMLET_GSTRING or (DAR_NORMAL shl offset VMLET_GS_ASPECT_RATIO) or (DC_GRAY_1 shl offset VMLET_GS_COLOR) )
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapOp, GR_DRAW_BITMAP_OPTR
ifndef GPC  ; all color
	cmp	pictureNumber, 2	; Next or Previous button bitmap?
	jge	common			; if not, skip
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapOp, GR_FILL_BITMAP_OPTR

common:
endif
	mov	ax, TITLED_MONIKER_WIDTH
	sub	ax, bitmapWidth
	shr	ax, 1

	;mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapX, (TITLED_MONIKER_WIDTH - TITLED_BITMAP_WIDTH)/2
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapX, ax
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapY, TITLED_MONIKER_BITMAP_OFFSET
	mov	ax, bitmap.handle	
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapOptr.handle, ax
	mov	ax, bitmap.chunk
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawbitmapOptr.chunk, ax
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_setfontOp, GR_SET_FONT
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_setfontPtFrac, 0
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_setfontPtInt, TITLED_MONIKER_TITLE_SIZE				; use 12 point for non CGA
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_setfontID, TITLED_MONIKER_TITLE_FONT
	mov	ax, TITLED_MONIKER_WIDTH
	sub	ax,dx
	shr	ax,1				;AX <- offset to draw text at.
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextX, ax
	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextOp, GR_DRAW_TEXT
	sub	cx, size TitledMonikerPrologue + size VisMoniker + size OpEndGString
						;CX <- byte length of title
DBCS <	mov	si, cx				; si <- byte length of title>
DBCS <	shr	si				; si <- length of title string>
DBCS <	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextLen, si>
SBCS <	mov	({TitledMonikerPrologue} ds:[di].VM_data).TMP_drawtextLen, cx>
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

CALLED BY:	TitledObjectSetMoniker
PASS:		ES:SI - null-terminated string
		BX - width to clip to
		CX - font ID
		DX - point size of font
RETURN:		CX - string size (w/ C_NULL)
		DX - pixel width
DESTROYED:	di, si
 
PSEUDO CODE/STRATEGY:
		A similar version exists in Appl/GeoFile

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/14/90		Initial version
	witt	1/22/94 	DBCS-ized. string size -> cx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTitleInfo	proc	near
	uses	ax,ds,bp
	.enter
	segmov	ds,es,di			;DS:SI <- ptr to string
	push	cx, dx
	mov	di, si				;ES:DI <- ptr to string
	call	LocalStringSize			;CX <- size of string
	LocalNextChar	escx			;count the C_NULL!
	push	cx				;Save size	
	clr	di
	call	GrCreateState			;Get a GState to manipulate
	pop	ax				;Restore string size
	pop	cx, dx				;Restore Font/Pt Size
	push	ax				;Save string size
	clr	ah				;
	call	GrSetFont			;
	clr	cx				;Check all chars
	call	GrTextWidth			;Do trivial reject -- entire 
						; string fits
	pop	cx				;CX <- string size
	mov	bp,dx				;BP <- pixel width
	cmp	bp, bx				;If width < moniker width, then
	jle	noclip				; no clipping, dude!
	LocalLoadChar	ax, '.'			;Get width of a '.'
	call	GrCharWidth			;	
	mov	bp, dx				;BP <- width of '.' * 3...
	shl	dx, 1				;
	add	bp, dx				;
	clr	cx
cliploop:
	LocalNextChar	dscx
	LocalGetChar	ax, dssi		;Get next character from string

	call	GrCharWidth
	add	bp,dx				;BP += width of next char
	cmp	bp, bx				;
	jl	cliploop			;
	sub	bp, dx				;BP <- real width
	LocalLoadChar	ax, '.'			;Add '...'

	push	di				;Save GState
SBCS <	lea	di, ds:[si][-1]			;Backup one char	>
DBCS <	lea	di, ds:[si][-2]						>

	LocalPutChar	esdi, ax
	LocalPutChar	esdi, ax
	LocalPutChar	esdi, ax

	LocalClrChar	ax			;Add null terminator
	LocalPutChar	esdi, ax

SBCS <	add	cx, 3*(size char)		;CX <- clipped string size>
DBCS <	add	cx, 3*(size wchar)		;CX <- clipped string size>
	pop	di				;Restore GState
noclip:
	call	GrDestroyState
	mov	dx, bp
	.leave
	ret
GetTitleInfo	endp

VGATitledMonikers	label	optr
ifdef GPC
EGATitledMonikers	optr	GPCUpSCMoniker
			optr	GPCDownSCMoniker
			optr	GPCNewSCMoniker
			optr	GPCNoteSCMoniker
else
EGATitledMonikers	optr	bwUpMoniker
			optr	bwDownMoniker
			optr	NewSCMoniker
			optr	NoteSCMoniker
endif
			optr	CalendarSCMoniker
			optr	DialSCMoniker
NUM_EGA_TITLED_MONIKERS	equ	($-EGATitledMonikers)/4

ifdef GPC ; same as VGA/EGA
HGCTitledMonikers	optr	GPCUpSCMoniker
			optr	GPCDownSCMoniker
			optr	GPCNewSCMoniker
			optr	GPCNoteSCMoniker
else
HGCTitledMonikers	optr	bwUpMoniker
			optr	bwDownMoniker
			optr	NewSMMoniker
			optr	NoteSMMoniker
endif
			optr	CalendarSMMoniker
			optr	DialSMMoniker

NUM_HGC_TITLED_MONIKERS	equ	($-HGCTitledMonikers)/4
.assert	NUM_HGC_TITLED_MONIKERS eq NUM_EGA_TITLED_MONIKERS

ifdef GPC ; same as VGA/EGA
CGATitledMonikers	optr	GPCUpSCMoniker
			optr	GPCDownSCMoniker
			optr	GPCNewSCMoniker
			optr	GPCNoteSCMoniker
else
CGATitledMonikers	optr	bwUpMoniker
			optr	bwDownMoniker
			optr	NewSCGAMoniker
			optr	NoteSCGAMoniker
endif
			optr	CalendarSCGAMoniker
			optr	DialSCMoniker
NUM_CGA_TITLED_MONIKERS	equ	($-CGATitledMonikers)/4
.assert	NUM_CGA_TITLED_MONIKERS eq NUM_EGA_TITLED_MONIKERS

	; tables used to draw monikers inside GeoDex icons

ifdef GPC
TEXT_ADJUST = 2
HEIGHT_ADJUST = TEXT_ADJUST+TITLED_MONIKER_TITLE_SIZE
endif

	MonikerHeightTable	label	word
ifdef GPC
		word	19+HEIGHT_ADJUST
		word	19+HEIGHT_ADJUST
		word	21+HEIGHT_ADJUST
		word	26+HEIGHT_ADJUST
else
		word	24
		word	24
		word	30
		word	33
endif
		word	39
		word	36

	BitmapWidthTable	label	word
ifdef GPC
		word	19
		word	19
		word	28
		word	37
else
		word	23
		word	23
		word	48
		word	48
endif
		word	48
		word	48

	MonikerOffsetTable	label	word
if PZ_PCGEOS
	; How to calculate these parameters?  from experience?
		word	11
		word	11
		word	18
		word	20
		word	25
else
ifdef GPC
		word	19+TEXT_ADJUST
		word	19+TEXT_ADJUST
		word	21+TEXT_ADJUST
		word	26+TEXT_ADJUST
else
		word	13
		word	13
		word	21
		word	24
endif
		word	30
		word	27
endif

	CGAMonikerHeightTable	label	word
ifdef GPC ;same as EGA/VGA
		word	19+HEIGHT_ADJUST
		word	19+HEIGHT_ADJUST
		word	21+HEIGHT_ADJUST
		word	26+HEIGHT_ADJUST
else
		word	24
		word	24
		word	24
		word	24
endif
		word	23
		word	23

	CGAMonikerOffsetTable	label	word
ifdef GPC
		word	19+TEXT_ADJUST
		word	19+TEXT_ADJUST
		word	21+TEXT_ADJUST
		word	26+TEXT_ADJUST
else
		word	13
		word	13
		word	14
		word	14
endif
		word	14
		word	14

TitledIcon	ends

endif  ; not GPC
