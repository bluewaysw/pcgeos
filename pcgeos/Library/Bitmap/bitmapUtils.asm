COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Doodle
FILE:		bitmapUtils.asm

ROUTINES:

	Name				Description
	----				-----------
	CreateNewGString		Creates a new GString in the temporary
					memory block.

	CreateNewBitmap			Allocates space on the heap for a
					bitmap, and initialize that bitmap's
					resolution, color mapping, etc.
					
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	2/91		Initial Version

DESCRIPTION:
	This file contains the memory allocation/utility routines used by
	VisBitmapClass.

RCS STAMP:
$Id: bitmapUtils.asm,v 1.1 97/04/04 17:43:00 newdeal Exp $
------------------------------------------------------------------------------@

BitmapEditCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				CreateNewBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the bitmap and does some necessary initialization.

CALLED BY:	

PASS:		*ds:si - VisBitmap
		al	- BMType record 
		cx	- width of bitmap to allocate (in points)
		dx	- height of bitmap to allocate (in points)
		di 	- x resolution
		bx 	- y resolution

		bp	- vm file handle to use (0 for default)

RETURN:		bx.ax	- VM file.block handle of bitmap (HugeArray)
		di	- gstate handle		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNewBitmap		proc	far
	class	VisBitmapClass
	uses	si,bp,cx,dx
	.enter

	;
	;  The passed dimensions are 72 dpi, while GrCreateBitmap takes
	;  pixels, so convert here
	;

	push	di			    ;save x resolution
	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	test	ds:[di].VBI_undoFlags, mask VBUF_MOUSE_EVENTS_IN_BITMAP_COORDS
	pop	di
	jnz	afterConvert

	call	ConvertVisPointToBitmapPoint

afterConvert:

	push	di			    ;save x resolution
	push	bx			    ;save y resolution
	push	ax			    ; save BMType

	mov_tr	ax, bp			    ; ax <- vm file handle to use
	tst	ax
	jnz	haveVMFile

	mov	ax, MSG_VIS_BITMAP_GET_VM_FILE
	call	ObjCallInstanceNoLock

haveVMFile:
	mov_tr	bx, ax			;bx <- file handle
	pop	ax			;al <- BMType
	clrdw	disi			;exposure OD
	call	GrCreateBitmap
	
	;
	;	Set the bitmap's resolution
	;
	pop	si				;si <- x resolution
	pop	bp				;si <- y resolution
	push	bx, ax				;save file, block handle
	mov	bx, bp				;bx <- y resolution
	mov_tr	ax, si				;ax <- x resolution
	call	GrSetBitmapRes

	;
	;	Set the color map mode to pattern, writing to a black
	;	background.
	;
	mov	al, CMT_DITHER
	call	GrSetAreaColorMap
	call	GrSetLineColorMap
	call	GrSetTextColorMap
	pop	bx, ax				;ax <- vm block handle
						;bx <- file handle

	.leave
	ret
CreateNewBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HackAroundWinScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Removes the window scale factor that may have been
		inserted by either GrSetBitmapRes or GrEditBitmap

Pass:		di - GState

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 11, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HackAroundWinScale	proc	far

	uses	ax
	.enter

	call	GrGetWinHandle
	xchg	di, ax				;di <- Window handle
	mov	cx, WIF_DONT_INVALIDATE
	call	WinSetNullTransform
	mov_tr	di, ax				;di <- GState handle

	.leave
	ret
HackAroundWinScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapConvertVisPointToBitmapPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisBitmap

		cx, dx - Vis Point

Return:		cx, dx - Bitmap Point

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 10, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapConvertVisPointToBitmapPoint	proc	far
	class	VisBitmapClass
	uses	bx, di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisBitmap_offset
	mov	bx, ds:[di].VBI_yResolution
	mov	di, ds:[di].VBI_xResolution
	call	ConvertVisPointToBitmapPoint
	
	.leave
	ret
VisBitmapConvertVisPointToBitmapPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertVisPointToBitmapPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Converts a location in the bitmap to a pixel coordinate

Pass:		cx, dx - point
		di - x resolution
		bx - y resolution

Return:		cx, dx - scaled by res/72

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 10, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertVisPointToBitmapPoint	proc	far
	uses	ax, bp
	.enter

	mov	bp, 72

	cmp	di, bp
	je	calcYPixels

	push	ax, dx
	mov_tr	ax, cx			;ax <- x point size
	imul	di			;dx:ax <- x pixel size
	cmp	dx, bp
	jge	overflowX
	idiv	bp
	tst	dx			;round up
	jz	haveXPixels
	inc	ax
haveXPixels:
	mov_tr	cx, ax
overflowX:
	pop	ax, dx

calcYPixels:

	cmp	bx, bp
	je	done

	mov_tr	ax, dx			;ax <- y point size
	imul	bx			;dx:ax <- y pixel size
	cmp	dx, bp
	jge	done
	idiv	bp
	tst	dx			;round up
	jz	haveYPixels
	inc	ax
haveYPixels:
	mov_tr	dx, ax

done:
	.leave
	ret
ConvertVisPointToBitmapPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				FreeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees the memory block containing the bitmap

CALLED BY:	

PASS:		*ds:si = VisBitmap object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
FreeBitmap		proc	near
	class	VisBitmapClass

	uses	ax, bx, bp, di
	.enter
	;
	;	Set up and make a call to GrDestroyBitmap
	;
	mov	bp, ds:[si]
	add	bp, ds:[bp].VisBitmap_offset

	clr	di
	xchg	di, ds:[bp].VBI_mainKit.VBK_gstate
	tst	di
	jz	freeVM
	mov	al, BMD_KILL_DATA
	call	GrDestroyBitmap

done:
	.leave
	ret

freeVM:
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjCallInstanceNoLock
	mov	bx, cx
	mov_tr	ax, dx
	clr	bp
	call	VMFreeVMChain
	jmp	done
FreeBitmap	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapMarkBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Mark the process that owns the block the body is in as
		busy. 

CALLED BY:	
		INTERNAL
PASS:		
		*(ds:si) - graphic body
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapMarkBusy		proc	far
	uses	ax,cx,dx,bp
	.enter

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication

	.leave
	ret
VisBitmapMarkBusy		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapMarkNotBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Mark the process that owns the block the body is in as
		not busy. 

CALLED BY:	
		INTERNAL
PASS:		
		*(ds:si) - graphic body
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapMarkNotBusy		proc	far
	uses	ax,cx,dx,bp
	.enter

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication

	.leave
	ret
VisBitmapMarkNotBusy		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisConstrainPointToVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - Vis object

		cx,dx - point

Return:		cx,dx - point inside object's vis bounds

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisConstrainPointToVisBounds	proc	far
	class	VisClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	cmp	cx, ds:[di].VI_bounds.R_left
	jge	checkRight
	mov	cx, ds:[di].VI_bounds.R_left
	jmp	checkY
checkRight:
	cmp	cx, ds:[di].VI_bounds.R_right
	jle	checkY
	mov	cx, ds:[di].VI_bounds.R_right
checkY:
	cmp	dx, ds:[di].VI_bounds.R_top
	jge	checkBottom
	mov	dx, ds:[di].VI_bounds.R_top
	jmp	done
checkBottom:
	cmp	dx, ds:[di].VI_bounds.R_bottom
	jle	done
	mov	dx, ds:[di].VI_bounds.R_bottom
done:
	.leave
	ret
VisConstrainPointToVisBounds	endp

BitmapEditCode	ends
