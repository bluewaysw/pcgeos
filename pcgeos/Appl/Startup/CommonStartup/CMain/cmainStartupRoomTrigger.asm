COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		welcome
FILE:		cmainStartupRoomTrigger.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

DESCRIPTION:
	This file contains the StartupRoomTriggerClass

	$Id: cmainStartupRoomTrigger.asm,v 1.1 97/04/04 16:52:18 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;	Constants & Structures
;------------------------------------------------------------------------------

BMonikerPrologue	struct
	BMP_height		word	(?)
	BMP_drawbitmapOp	byte	(?)
	BMP_drawbitmapX	word	(?)
	BMP_drawbitmapY	word	(?)
	BMP_drawbitmapOptr	optr	(?)
	BMP_setfontOp		byte	(?)
	BMP_setfontPtFrac	byte	(?)
	BMP_setfontPtInt	word	(?)
	BMP_setfontID		word	(?)
	BMP_drawtextOp	byte	(?)
	BMP_drawtextX		word	(?)
	BMP_drawtextY		word	(?)
	BMP_drawtextLen	word	(?)
BMonikerPrologue	ends
			
.assert	(BMP_drawbitmapOp eq VMGS_gstring)

;
;	CONSTANTS FOR WIDTHS AND POSITIONS IN OVERVIEW MONIKER
;

		;Title font is Berkeley	10 point

OVERVIEW_MONIKER_TITLE_FONT	equ	FID_BERKELEY
OVERVIEW_MONIKER_TITLE_SIZE	equ	12
CGA_OVERVIEW_MONIKER_TITLE_SIZE	equ	10

OVERVIEW_MONIKER_WIDTH		equ	143
OVERVIEW_MONIKER_HEIGHT		equ	132
;OVERVIEW_MONIKER_HEIGHT		equ	129
OVERVIEW_BITMAP_WIDTH		equ	143
OVERVIEW_BITMAP_HEIGHT		equ	113

OVERVIEW_MONIKER_TOP_OFFSET	equ	116
OVERVIEW_MONIKER_BITMAP_OFFSET	equ	2
	
CGA_OVERVIEW_MONIKER_HEIGHT	equ	74
CGA_OVERVIEW_BITMAP_HEIGHT	equ	62
CGA_OVERVIEW_MONIKER_TOP_OFFSET	equ	62


idata	segment

	StartupRoomTriggerClass

idata	ends

CommonCode	segment	resource

ifdef WELCOME

VGAOverviewMonikers	label	optr
EGAOverviewMonikers	optr	ProRoomColorMoniker,
				ProRoomColorMoniker,
				ProRoomColorMoniker

NUM_EGA_OVERVIEW_MONIKERS	equ	($-EGAOverviewMonikers)/4
.assert NUM_EGA_OVERVIEW_MONIKERS eq	PictureNumber

HGCOverviewMonikers	optr	ProRoomBWMoniker,
				ProRoomBWMoniker,
				ProRoomBWMoniker

NUM_HGC_OVERVIEW_MONIKERS	equ	($-HGCOverviewMonikers)/4
.assert	NUM_HGC_OVERVIEW_MONIKERS eq PictureNumber

CGAOverviewMonikers	optr	ProRoomCGAMoniker,
				ProRoomCGAMoniker,
				ProRoomCGAMoniker

NUM_CGA_OVERVIEW_MONIKERS	equ	($-CGAOverviewMonikers)/4
.assert	NUM_CGA_OVERVIEW_MONIKERS eq PictureNumber

endif

ifdef ISTARTUP

VGAOverviewMonikers	label	optr
EGAOverviewMonikers	optr	CPrimaryMoniker,
				CAssistedMoniker,
				CSelfGuidedMoniker

NUM_EGA_OVERVIEW_MONIKERS	equ	($-EGAOverviewMonikers)/4
.assert NUM_EGA_OVERVIEW_MONIKERS eq PictureNumber


HGCOverviewMonikers	optr	BWPrimaryMoniker,
				BWAssistedMoniker,
				BWSelfGuidedMoniker
				
NUM_HGC_OVERVIEW_MONIKERS	equ	($-HGCOverviewMonikers)/4
.assert	NUM_HGC_OVERVIEW_MONIKERS eq PictureNumber

CGAOverviewMonikers	optr	CGAPrimaryMoniker,
				CGAAssistedMoniker,
				CGASelfGuidedMoniker

NUM_CGA_OVERVIEW_MONIKERS	equ	($-CGAOverviewMonikers)/4
.assert	NUM_CGA_OVERVIEW_MONIKERS eq PictureNumber

endif
 


;##############################################################################
;	CODE
;##############################################################################


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupRoomTriggerSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the object is vis built, copy in the correct moniker 

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupRoomTriggerSpecBuild	method	StartupRoomTriggerClass, MSG_SPEC_BUILD
	push	es,cx,dx,bp		; preserve SpecBuildFlags
	mov	al,ds:[di].SRTI_pictureNumber
	clr	ah
EC <	cmp	ax, NUM_CGA_OVERVIEW_MONIKERS				>
EC <	ERROR_AE BAD_PICTURE_NUMBER					>
	push	ax
	push	si			;Save ptr to Overview trigger
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	mov	bx, handle StartupApp
	mov	si, offset StartupApp
	mov	di,mask MF_CALL
	call	ObjMessage			;Get app display scheme in AH
	pop	si				;Restore ptr to Overview trigger
	mov	al, ah				;copy display type to AL
	andnf	ah, mask DT_DISP_ASPECT_RATIO
	mov	di, offset CGAOverviewMonikers	;
	cmp	ah, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
	je	10$				;CGA
	mov	di, offset VGAOverviewMonikers	;
	cmp	ah, DAR_NORMAL
	je	8$				;VGA or MCGA
	mov	di, offset EGAOverviewMonikers	;else EGA or HGC
8$:
	and	al, mask DT_DISP_CLASS		;Get display class
	cmp	al, DC_GRAY_1			;Are we on a monochrome display
	jne	10$				;EGA
	mov	di, offset HGCOverviewMonikers	;
10$:
	pop	bp			;Restore picture number
	shl	bp,1			;Multiply picture # by 4 (size of table
	shl	bp,1			; entry -- optr)

;	SET UP MONIKER

	mov	cx, ({optr} cs:[di][bp]).handle	;^lCX:DX <- bitmap to put in 
	mov	dx, ({optr} cs:[di][bp]).chunk	; moniker
	mov	ax, MSG_SRT_SET_MONIKER
	call	ObjCallInstanceNoLock

	pop	es,cx,dx,bp		; restore SpecBuildFlags
				; Continue by calling superclass with same
				;	method
	mov	ax, MSG_SPEC_BUILD
	mov	di, offset StartupRoomTriggerClass
	GOTO	ObjCallSuperNoLock
StartupRoomTriggerSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupRoomTriggerSetMoniker	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method combines the passed moniker and passed title
		string to be one beautiful moniker. It overwrites the passed
		chunk in DX, so any DIRTY or IGNORE_DIRTY flags can be set on
		it. 
CALLED BY:	GLOBAL
PASS:		CX:DX - optr of bitmap to be part of moniker
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupRoomTriggerSetMoniker	method	dynamic StartupRoomTriggerClass,
						MSG_SRT_SET_MONIKER
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

	mov	si, ds:[di].SRTI_title
	mov	si, ds:[si]			;DS:SI <- ptr to title data
	segmov	es, ss, di			;
	lea	di, titleStr			;ES:DI <- where to put title
						; data
	ChunkSizePtr	ds, si, cx
	inc	cx
	shr	cx, 1				;CX <- # words
	rep	movsw				;Copy data over from title 

;	NUKE OLD VIS MONIKER

	push	bp				;Save ptr to locals
	mov	si, object
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	call	ObjCallInstanceNoLock
	push	ax				;Save vis moniker chunk
	clr	cx				;Nuke old vis moniker
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	pop	ax				;Get vis moniker chunk
	tst	ax				;If no chunk, exit
	jz	10$				;
	call	LMemFree			;Else, free old vis moniker
10$:
	pop	bp				;Restore ptr to locals

;	GET INFORMATION ABOUT TITLE AND CLIP IF NECESSARY

	push	cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	mov	bx, handle StartupApp
	mov	si, offset StartupApp
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;Get app display scheme in AH
	pop	cx, dx, bp

	push	ax
	lea	si, titleStr			;ES:SI <- ptr to title
	mov	bx, OVERVIEW_MONIKER_WIDTH
	mov	cx, OVERVIEW_MONIKER_TITLE_FONT	;
	mov	dx, OVERVIEW_MONIKER_TITLE_SIZE	;
	cmp	ah, CGA_DISPLAY_TYPE
	jne	40$				;Adjust size for CGA
	mov	dx, CGA_OVERVIEW_MONIKER_TITLE_SIZE	;
40$:	
	call	GetBTitleInfo			;Returns strlen in CX and width
						; in BP (Clips title and adds
						; ellipsis if necessary)

;	ALLOCATE MONIKER CHUNK

						;CX <- total size of moniker
	add	cx, size BMonikerPrologue + size VisMoniker + size OpEndGString

	mov	al, mask OCF_DIRTY		;Save this to the state file.
	call	LMemAlloc			;Allocate the moniker

;	FILL IN MONIKER CHUNK 
		
	segmov	es,ds,di			;ES <- moniker segment
	xchg	di, ax				;DI <- moniker chunk handle
	pop	ax
	push	di				;Save moniker chunk handle
	mov	di,ds:[di]			;Deref moniker chunk

						;Set cached size
	mov	ds:[di].VM_width, OVERVIEW_MONIKER_WIDTH
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, \
				OVERVIEW_MONIKER_HEIGHT
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_drawtextY, \
						OVERVIEW_MONIKER_TOP_OFFSET
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_setfontPtInt, \
						OVERVIEW_MONIKER_TITLE_SIZE
	cmp	ah, CGA_DISPLAY_TYPE
	jne	notCGA				;Adjust height for CGA
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_setfontPtInt, \
						CGA_OVERVIEW_MONIKER_TITLE_SIZE
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, \
				CGA_OVERVIEW_MONIKER_HEIGHT
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_drawtextY, \
						CGA_OVERVIEW_MONIKER_TOP_OFFSET
notCGA:
	mov	ds:[di].VM_type,( mask VMLET_GSTRING or \
			(DAR_NORMAL shl offset VMLET_GS_ASPECT_RATIO) or \
			(DC_GRAY_1 shl offset VMLET_GS_COLOR) )
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_drawbitmapOp, \
							GR_DRAW_BITMAP_OPTR
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_drawbitmapX, \
			(OVERVIEW_MONIKER_WIDTH - OVERVIEW_BITMAP_WIDTH)/2
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_drawbitmapY, \
						OVERVIEW_MONIKER_BITMAP_OFFSET
	mov	ax, bitmap.handle	
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_drawbitmapOptr.handle,\
								ax
	mov	ax, bitmap.chunk
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_drawbitmapOptr.chunk,\
								ax
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_setfontOp, GR_SET_FONT
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_setfontPtFrac, 0
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_setfontID, \
						OVERVIEW_MONIKER_TITLE_FONT
	mov	ax, OVERVIEW_MONIKER_WIDTH
	sub	ax,dx
	shr	ax,1				;AX <- offset to draw text at.
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_drawtextOp, \
								GR_DRAW_TEXT
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_drawtextX, ax

	sub	cx, size BMonikerPrologue + size VisMoniker + size OpEndGString
						;CX <- byte length of title
	mov	({BMonikerPrologue} ds:[di].VM_data).BMP_drawtextLen, cx
						;Store string byte length
						;ES:DI <- ptr to store title
	add	di,size BMonikerPrologue + size VisMoniker	

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
StartupRoomTriggerSetMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBTitleInfo
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
GetBTitleInfo	proc	near
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
GetBTitleInfo	endp

CommonCode	ends


