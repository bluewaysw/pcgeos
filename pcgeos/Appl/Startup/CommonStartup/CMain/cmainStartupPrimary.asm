COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Startup
FILE:		cmainStartupApplication.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/89		Initial version

DESCRIPTION:
	This file contains a Startup application

	$Id: cmainStartupApplication.asm,v 1.1 97/04/04 16:52:16 newdeal Exp $

------------------------------------------------------------------------------@

;##############################################################################
;	Initialized data
;##############################################################################

; Turn off all artwork on the primary, since it no longer is displayed
;
_PRIMARY_ARTWORK = 0

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

	StartupPrimaryClass

idata	ends

;##############################################################################
;	Code
;##############################################################################


if	_PRIMARY_ARTWORK
if	_NEW_DEAL
include	cmainNewDealBitmap.asm
else
include	cmainGlobalPCBitmap.asm
endif
endif


CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupPrimaryVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the primary into a transparent window

CALLED BY:	MSG_VIS_OPEN

PASS:		*ds:si	= StartupPrimaryClass object
		ds:di	= StartupPrimaryClass instance data
		ds:bx	= StartupPrimaryClass object (same as *ds:si)
		es 	= segment of StartupPrimaryClass
		ax	= message #
RETURN:		bp	= 0 if top window, else window for object to open on
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/01/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupPrimaryVisOpen	method dynamic StartupPrimaryClass, 
					MSG_VIS_OPEN
	mov	di, offset StartupPrimaryClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_QUERY_WINDOW
	call	ObjCallInstanceNoLock
	jcxz	done

	mov	si, WIT_COLOR
	clr	ax, bx
	mov	ah, mask WCF_TRANSPARENT
	mov	di, cx
	call	WinSetInfo
done:
	ret
StartupPrimaryVisOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupPrimaryVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw background bitmap

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= StartupPrimaryClass object
		bp	= gstate
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	9/29/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PRIMARY_ARTWORK
StartupPrimaryVisDraw	method	dynamic	StartupPrimaryClass,
					MSG_VIS_DRAW
	uses	ax, cx, dx, si, bp, ds, es
	.enter

	call	StartupPrimaryDrawBackgroundBitmap
	call	StartupPrimaryDrawEverythingElse

	.leave

	mov	di, offset StartupPrimaryClass
	GOTO	ObjCallSuperNoLock
	
StartupPrimaryVisDraw	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupPrimaryDrawEverythingElse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw everything else

CALLED BY:	StartupPrimaryVisDraw
PASS:		bp	= gstate
RETURN:		bp	= gstate
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	9/29/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PRIMARY_ARTWORK

DELTA = -6
	
StartupPrimaryDrawEverythingElse	proc	near

	mov	cl, GST_PTR
	mov	bx, cs
	mov	si, offset chooseUIGString
	call	GrLoadGString		; si = GString

	mov	di, bp			; di = GState
	clr	ax, bx
	mov	dx, GSRT_COMPLETE
	call	GrDrawGString

	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString

	ret
StartupPrimaryDrawEverythingElse	endp

chooseUIGString	label	char
	; Sans 24 point Bold Black

	GSSetFont	FID_DTC_URW_SANS, 24, 0
	GSSetTextStyle	<mask TS_BOLD>, <0>
	GSSetTextColorIndex	C_BLACK

	GSDrawTextOptr	 99, 109+DELTA, WhichDesktopString
	GSDrawTextOptr	270, 210+DELTA, GlobalPCDesktopString
	GSDrawTextOptr	270, 305+DELTA, StandardDesktopString

	; Sans 24 point Bold Yellow

	GSSetTextColor	250, 214, 62	

	GSDrawTextOptr	 97, 107+DELTA, WhichDesktopString
	GSDrawTextOptr	268, 208+DELTA, GlobalPCDesktopString
	GSDrawTextOptr	268, 303+DELTA, StandardDesktopString

	; Sans 18 point Normal Yellow

	GSSetFont	FID_DTC_URW_SANS, 18, 0
	GSSetTextStyle	<0>, <mask TS_BOLD>

	GSDrawTextOptr	 29, 418+DELTA, HelpString
	GSDrawTextOptr	552, 418+DELTA, ShutDownString

	; Sans 10 point Normal Yellow

if	not _NEW_DEAL
	GSSetFont	FID_DTC_URW_SANS, 10, 0
	GSDrawTextOptr	420, 50, TrademarkString
endif
	
	; Sans 18 point Normal Light Gray

	GSSetTextColorIndex	C_LIGHT_GRAY
	GSSetFont	FID_DTC_URW_SANS, 18, 0

	GSDrawTextOptr	 98, 135+DELTA, YourDesktopString
	GSDrawTextOptr	 93, 153+DELTA, ItHelpsYouString	
	GSDrawTextOptr	268, 234+DELTA, ForEasyAccessString
	GSDrawTextOptr	268, 252+DELTA, DocumentsAndProgramsString
	GSDrawTextOptr	268, 329+DELTA, ForAdvancedAccessString
	GSDrawTextOptr	268, 347+DELTA, DocumentsAndProgramsString
endif	; if _PRIMARY_ARTWORK
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupPrimaryDrawBackgrounBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw background bitmap

CALLED BY:	StartupPrimaryVisDraw
PASS:		bp	= gstate
RETURN:		bp	= gstate
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	9/29/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PRIMARY_ARTWORK
StartupPrimaryDrawBackgroundBitmap	proc	near	

	; calculate size of CBitmap block we need to draw

	mov	bx, handle ChooseUIBitmapHeaderResource
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	mov	cx, ax			; cx = size of bitmap header block

	call	MemLock
	mov	ds, ax
	mov	dx, ds:[CB_simple].B_width
	call	MemUnlock

	mov	ax, SCANLINES_PER_RESOURCE
	mul	dx			; ax = size of bitmap data in a block

	; allocate a block to hold the CBitmap we are going to draw

	push	cx	
	add	ax, cx
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	mov	es, ax
	pop	cx			; cx = size of bitmap header block
	jc	done

	push	bx
	mov	bx, handle ChooseUIBitmapHeaderResource
	call	MemLock
	mov	ds, ax
	clr	si, di

	; copy the bitmap header into our CBitmap block
	
	push	cx
	shr	cx, 1
	rep	movsw
	adc	cx, cx
	rep	movsb
	pop	cx

	mov	es:[CB_startScan], 0	; first scan is 0
	mov	es:[CB_numScans], 0	; number of scans initially is 0

	segmov	ds, es
	clr	si			; ds:si = CBitmap
	clr	ax, bx			; draw at (0,0)
	mov	dx, cs
	mov	cx, offset StartupPrimaryDrawBackgroundBitmapCB
	mov	di, bp			; di = gstate
	call	GrDrawBitmap
	pop	bx

	call	MemFree
	mov	bx, handle ChooseUIBitmapHeaderResource
	call	MemUnlock
done:
	ret
StartupPrimaryDrawBackgroundBitmap	endp
endif
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupPrimaryDrawBackgroundBitmapCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw background bitmap

CALLED BY:	MSG_VIS_DRAW
PASS:		ds:si	= CBitmap
RETURN:		ds:si	= CBitmap
		carry set if nothing more to draw
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	9/29/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PRIMARY_ARTWORK
StartupPrimaryDrawBackgroundBitmapCB	proc	far
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	.enter

	clr	dx
	mov	ax, ds:[si].CB_startScan
	add	ax, ds:[si].CB_numScans
	mov	ds:[si].CB_startScan, ax
	mov	bx, SCANLINES_PER_RESOURCE
	mov	ds:[si].CB_numScans, bx
	div	bx
	cmp	ax, length chooseUIBitmapResourceTable
	jae	stopDrawing

	mov	bx, ax
	add	bx, bx
	mov	bx, cs:[chooseUIBitmapResourceTable][bx]

	mov	ax, SCANLINES_PER_RESOURCE
	mul	ds:[si].CB_simple.B_width
	mov	cx, ax
	
	call	MemLock
	segmov	es, ds
	mov	di, ds:[si].CB_data
	mov	ds, ax
	clr	si
	shr	cx, 1
	rep	movsw
	adc	cx, cx
	rep	movsb	
	call	MemUnlock
	clc
done:
	.leave
	ret
	
stopDrawing:
	stc
	jmp	done

StartupPrimaryDrawBackgroundBitmapCB	endp
endif

if _PRIMARY_ARTWORK
chooseUIBitmapResourceTable	hptr	\
	ChooseUIBitmap00Resource,
	ChooseUIBitmap01Resource,
	ChooseUIBitmap02Resource,
	ChooseUIBitmap03Resource,
	ChooseUIBitmap04Resource,
	ChooseUIBitmap05Resource,
	ChooseUIBitmap06Resource,
	ChooseUIBitmap07Resource,
	ChooseUIBitmap08Resource,
	ChooseUIBitmap09Resource,
	ChooseUIBitmap0AResource,
	ChooseUIBitmap0BResource,
	ChooseUIBitmap0CResource,
	ChooseUIBitmap0DResource,
	ChooseUIBitmap0EResource,
	ChooseUIBitmap0FResource,
	ChooseUIBitmap10Resource,
	ChooseUIBitmap11Resource,
	ChooseUIBitmap12Resource,
	ChooseUIBitmap13Resource,
	ChooseUIBitmap14Resource,
	ChooseUIBitmap15Resource,
	ChooseUIBitmap16Resource,
	ChooseUIBitmap17Resource,
	ChooseUIBitmap18Resource,
	ChooseUIBitmap19Resource,
	ChooseUIBitmap1AResource,
	ChooseUIBitmap1BResource,
	ChooseUIBitmap1CResource,
	ChooseUIBitmap1DResource,
	ChooseUIBitmap1EResource,
	ChooseUIBitmap1FResource,
	ChooseUIBitmap20Resource,
	ChooseUIBitmap21Resource,
	ChooseUIBitmap22Resource,
	ChooseUIBitmap23Resource,
	ChooseUIBitmap24Resource,
	ChooseUIBitmap25Resource,
	ChooseUIBitmap26Resource,
	ChooseUIBitmap27Resource,
	ChooseUIBitmap28Resource,
	ChooseUIBitmap29Resource,
	ChooseUIBitmap2AResource,
	ChooseUIBitmap2BResource
endif

CommonCode	ends
