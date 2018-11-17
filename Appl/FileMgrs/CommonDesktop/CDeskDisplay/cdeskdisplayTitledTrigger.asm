COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	Config
MODULE:		
FILE:		deskdisplayTitledTrigger.asm

AUTHOR:		Andrew Wilson, Dec  3, 1990

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/90	Initial revision

DESCRIPTION:
	This file contains code to implement the TitledGenTriggerClass and
	to create nifty titled summons.

	$Id: cdeskdisplayTitledTrigger.asm,v 1.1 97/04/04 15:02:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BuildCode	segment resource

TitledMonikerPrologue	struct
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

;
;	CONSTANTS FOR WIDTHS AND POSITIONS IN TITLED MONIKER
;

if PZ_PCGEOS

TITLED_MONIKER_TITLE_FONT	equ	FID_PIZZA_KANJI
TITLED_MONIKER_TITLE_SIZE	equ	16

else

TITLED_MONIKER_TITLE_FONT	equ	FID_BERKELEY	;Title font is Berkeley
TITLED_MONIKER_TITLE_SIZE	equ	9		; 10 point

endif

FIRST_WIDE_ICON			equ	8

WIDE_TITLED_MONIKER_WIDTH	equ	65
TITLED_MONIKER_WIDTH		equ	60
TITLED_MONIKER_HEIGHT		equ	42
TITLED_BITMAP_WIDTH		equ	48
TITLED_BITMAP_HEIGHT		equ	30

CGA_TITLED_MONIKER_WIDTH	equ	TITLED_MONIKER_WIDTH
CGA_TITLED_MONIKER_HEIGHT	equ	26
CGA_TITLED_BITMAP_WIDTH		equ	TITLED_BITMAP_WIDTH
CGA_TITLED_BITMAP_HEIGHT	equ	14

TITLED_MONIKER_TOP_OFFSET	equ	32
TITLED_MONIKER_BITMAP_OFFSET	equ	2
CGA_TITLED_MONIKER_TOP_OFFSET	equ	16

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitledGenTriggerVisBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We intercept VisBuild and create a moniker for the glyph
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
TitledGenTriggerVisBuild	method dynamic TitledGenTriggerClass,
							MSG_SPEC_BUILD
	mov	bx, ds:[di].TGTI_title		;*DS:BX <- title text	
	clr	ax
	mov	al,ds:[di].TGTI_pictureNumber	;AX <- title text
	mov	di, offset TitledGenTriggerClass
	GOTO	DoVisBuildCommon
TitledGenTriggerVisBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoVisBuildCommon
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
DoVisBuildCommon	proc	far
	push	es,cx,dx,bp,di		; preserve VisBuildFlags
	push	bx
EC <	cmp	ax, NUM_CGA_TITLED_MONIKERS				>
EC <	ERROR_AE BAD_PICTURE_NUMBER					>
	push	ax
	push	si			;Save ptr to titled object
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	mov	bx, handle Desktop
	mov	si, offset Desktop
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
	mov	ax, bp			;Pass picture number in AX
	shl	bp,1			;Multiply picture # by 4 (size of table
	shl	bp,1			; entry -- optr)

;	SET UP MONIKER

	mov	cx, ({optr} cs:[di][bp]).handle	;^lCX:DX <- bitmap to put in 
	mov	dx, ({optr} cs:[di][bp]).chunk	; moniker
	pop	bx				;Restore title chunk
	call	TitledObjectSetMoniker

	pop	es,cx,dx,bp,di		; restore VisBuildFlags
				; Continue by calling superclass with same
				;	method
	mov	ax, MSG_SPEC_BUILD
	GOTO	ObjCallSuperNoLock
DoVisBuildCommon	endp



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
	monikerWidth	local	word
	.enter

;	SET UP LOCALS

	mov	object, si
	mov	bitmap.handle, cx
	mov	bitmap.chunk, dx
	mov	monikerWidth, TITLED_MONIKER_WIDTH
	cmp	ax, FIRST_WIDE_ICON
	jb	haveWidth
	mov	monikerWidth, WIDE_TITLED_MONIKER_WIDTH
haveWidth:

;	COPY TITLE DATA OUT OF CHUNK AND ONTO STACK FOR MANIPULATION

	mov	si, ds:[bx]			;DS:SI <- ptr to title data
	segmov	es, ss
	lea	di, titleStr			;ES:DI <- where to put title
						; data
	ChunkSizePtr	ds, si, cx
	inc	cx
DBCS <	inc	cx							>
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
	mov	bx, monikerWidth		;
	mov	cx, TITLED_MONIKER_TITLE_FONT	;
	mov	dx, TITLED_MONIKER_TITLE_SIZE	;
	call	GetTitleInfo			;Returns strlen in CX and width
						; in BP (Clips title and adds
						; ellipsis if necessary)

;	ALLOCATE MONIKER CHUNK

						;CX <- total size of moniker
	add	cx, size TitledMonikerPrologue + size VisMoniker + size VisMonikerGString + size OpEndGString

	mov	al, mask OCF_DIRTY		;Save this to the state file.
	call	LMemAlloc			;Allocate the moniker

;	FILL IN MONIKER CHUNK 

	push	cx,dx, ax, bp
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	mov	bx, handle Desktop
	mov	si, offset Desktop
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;Get app display scheme in AH
	segmov	es,ds,di			;ES <- moniker segment
	pop	cx, dx, di, bp
	push	di
	mov	di,ds:[di]			;Deref moniker chunk
	push	monikerWidth			;Set cached size
	pop	ds:[di].VM_width
	mov	{word} ds:[di].VM_data + VMGS_height, TITLED_MONIKER_HEIGHT
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_drawtextY, TITLED_MONIKER_TOP_OFFSET
	cmp	ah, CGA_DISPLAY_TYPE
	jne	notCGA				;Adjust height for CGA
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_drawtextY, CGA_TITLED_MONIKER_TOP_OFFSET
	mov	{word} ds:[di].VM_data + VMGS_height, CGA_TITLED_MONIKER_HEIGHT
notCGA:
	mov	ds:[di].VM_type,( mask VMLET_GSTRING or (DAR_NORMAL shl offset VMLET_GS_ASPECT_RATIO) or (DC_GRAY_1 shl offset VMLET_GS_COLOR) )
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_drawbitmapOp, GR_DRAW_BITMAP_OPTR
	mov	ax, monikerWidth		; (TITLED_MONIKER_WIDTH
	sub	ax, TITLED_BITMAP_WIDTH		;	- TITLED_BITMAP_WIDTH)
	shr	ax, 1				;	/2
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_drawbitmapX, ax
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_drawbitmapY, TITLED_MONIKER_BITMAP_OFFSET
	mov	ax, bitmap.handle	
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_drawbitmapOptr.handle, ax
	mov	ax, bitmap.chunk
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_drawbitmapOptr.chunk, ax
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_setfontOp, GR_SET_FONT
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_setfontPtFrac, 0
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_setfontPtInt, TITLED_MONIKER_TITLE_SIZE
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_setfontID, TITLED_MONIKER_TITLE_FONT
	mov	ax, monikerWidth
	sub	ax,dx
	shr	ax,1				;AX <- offset to draw text at.
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_drawtextX, ax
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_drawtextOp, GR_DRAW_TEXT
	sub	cx, size TitledMonikerPrologue + size VisMoniker + size VisMonikerGString + size OpEndGString
						;CX <- byte length of title
	mov	({TitledMonikerPrologue} ds:[di].VM_data + VMGS_gstring).TMP_drawtextLen, cx
						;Store string byte length
						;ES:DI <- ptr to store title
	add	di,size TitledMonikerPrologue + size VisMoniker	+ size VisMonikerGString

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
if DBCS_PCGEOS
	call	LocalStringLength
else
	mov	cx, -1				;
	clr	al				;
	repne	scasb				;
	not	cx				;CX <- length of string
endif
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
	LocalLoadChar ax, '.'			;Get width of a '.'
	call	GrCharWidth			;	
	mov	bp, dx				;BP <- width of '.' * 3...
	shl	dx, 1				;
	add	bp, dx				;
	clr	cx
cliploop:
	inc	cx
	LocalGetChar ax, dssi			;Get next character from string
	call	GrCharWidth
	add	bp,dx				;BP += width of next char
	cmp	bp, bx				;
	jl	cliploop			;
	sub	bp, dx				;BP <- real width
	LocalLoadChar ax, '.'				;Add '...'
	push	di				;Save GState
SBCS <	lea	di, ds:[si][-1]						>
DBCS <	lea	di, ds:[si][-2]						>
	LocalPutChar esdi, ax
	LocalPutChar esdi, ax
	LocalPutChar esdi, ax
	LocalClrChar
	LocalPutChar esdi, ax
	add	cx, 3				;CX <- clipped string length
	pop	di				;Restore GState
noclip:
	call	GrDestroyState
	mov	dx, bp
	.leave
	ret
GetTitleInfo	endp

AppIconAreaSCMonikerResource segment lmem
global	MessyWasteCanSCBitmap:chunk
global	DocDirButtonSCBitmap:chunk
global	OpenFileSCBitmap:chunk
global	GetInfoSCBitmap:chunk
global	MoveFileSCBitmap:chunk
global	CopyFileSCBitmap:chunk
global	DupFileSCBitmap:chunk
global	RenameFileSCBitmap:chunk
global	FormatSCBitmap:chunk
global	CloseDirSCBitmap:chunk
global	OpenDirSCBitmap:chunk
global	CreateDirSCBitmap:chunk
global	ExitSCBitmap:chunk
global	HelpSCBitmap:chunk
AppIconAreaSCMonikerResource ends

AppIconAreaSMMonikerResource segment lmem
global	MessyWasteCanSMBitmap:chunk
global	DocDirButtonSMBitmap:chunk
global	OpenFileSMBitmap:chunk
global	GetInfoSMBitmap:chunk
global	MoveFileSMBitmap:chunk
global	CopyFileSMBitmap:chunk
global	DupFileSMBitmap:chunk
global	RenameFileSMBitmap:chunk
global	FormatSMBitmap:chunk
global	CloseDirSMBitmap:chunk
global	OpenDirSMBitmap:chunk
global	CreateDirSMBitmap:chunk
global	ExitSMBitmap:chunk
global	HelpSMBitmap:chunk
AppIconAreaSMMonikerResource ends

AppIconAreaSCGAMonikerResource segment lmem
global	MessyWasteCanSCGABitmap:chunk
global	DocDirButtonSCGABitmap:chunk
global	OpenFileSCGABitmap:chunk
global	GetInfoSCGABitmap:chunk
global	MoveFileSCGABitmap:chunk
global	CopyFileSCGABitmap:chunk
global	DupFileSCGABitmap:chunk
global	RenameFileSCGABitmap:chunk
global	FormatSCGABitmap:chunk
global	CloseDirSCGABitmap:chunk
global	OpenDirSCGABitmap:chunk
global	CreateDirSCGABitmap:chunk
global	ExitSCGABitmap:chunk
global	HelpSCGABitmap:chunk
AppIconAreaSCGAMonikerResource ends


VGATitledMonikers	label	optr
							; 60-pixel wide icons:
EGATitledMonikers	optr	ExitSCBitmap		; exit to DOS
			optr	OpenFileSCBitmap	; Open
			optr	GetInfoSCBitmap		; Get Info
			optr	MoveFileSCBitmap	; Move
			optr	CopyFileSCBitmap	; Copy
			optr	DupFileSCBitmap		; Duplicate
			optr	RenameFileSCBitmap	; Rename
			optr	FormatSCBitmap		; Format
							; 65-pixel wide icons:
			optr	MessyWasteCanSCBitmap	; Delete (Waste Basket)
			optr	OpenDirSCBitmap		; Open Dir
			optr	CloseDirSCBitmap	; Close Dir
			optr	CreateDirSCBitmap	; Create Dir
			optr	DocDirButtonSCBitmap	; Documents
			optr	HelpSCBitmap		; Help

NUM_EGA_TITLED_MONIKERS	equ	($-EGATitledMonikers)/4

HGCTitledMonikers	optr	ExitSMBitmap		; exit to DOS
			optr	OpenFileSMBitmap	; Open
			optr	GetInfoSMBitmap		; Get Info
			optr	MoveFileSMBitmap	; Move
			optr	CopyFileSMBitmap	; Copy
			optr	DupFileSMBitmap		; Duplicate
			optr	RenameFileSMBitmap	; Rename
			optr	FormatSMBitmap		; Format
			optr	MessyWasteCanSMBitmap	; Delete (Waste Basket)
			optr	OpenDirSMBitmap		; Open Dir
			optr	CloseDirSMBitmap	; Close Dir
			optr	CreateDirSMBitmap	; Create Dir
			optr	DocDirButtonSMBitmap	; Documents
			optr	HelpSMBitmap		; Help
NUM_HGC_TITLED_MONIKERS	equ	($-HGCTitledMonikers)/4
.assert	NUM_HGC_TITLED_MONIKERS eq NUM_EGA_TITLED_MONIKERS


CGATitledMonikers	optr	ExitSCGABitmap		; exit to DOS
			optr	OpenFileSCGABitmap	; Open
			optr	GetInfoSCGABitmap	; Get Info
			optr	MoveFileSCGABitmap	; Move
			optr	CopyFileSCGABitmap	; Copy
			optr	DupFileSCGABitmap	; Duplicate
			optr	RenameFileSCGABitmap	; Rename
			optr	FormatSCGABitmap	; Format
			optr	MessyWasteCanSCGABitmap	; Delete (Waste Basket)
			optr	OpenDirSCGABitmap	; Open Dir
			optr	CloseDirSCGABitmap	; Close Dir
			optr	CreateDirSCGABitmap	; Create Dir
			optr	DocDirButtonSCGABitmap	; Documents
			optr	HelpSCGABitmap		; Help
NUM_CGA_TITLED_MONIKERS	equ	($-CGATitledMonikers)/4
.assert	NUM_CGA_TITLED_MONIKERS eq NUM_EGA_TITLED_MONIKERS

BuildCode ends

