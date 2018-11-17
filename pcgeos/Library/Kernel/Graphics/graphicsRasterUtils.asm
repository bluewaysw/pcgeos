
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		Graphics/graphicsRasterUtils.asm

AUTHOR:		Jim DeFrisco, 5/23/90

ROUTINES:
	Name			Description
	----			-----------
    GBL	GrSetBitmapRes		set resolution of bitmap
    GBL	GrGetBitmapRes		get resolution of bitmap
    GBL	GrClearBitmap		init data portion of a bitmap
    GBL	GrGetBitmapSize		get real size of a bitmap (in points)

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/23/90		Initial revision


DESCRIPTION:
	A few small routines used by different raster modules
		

	$Id: graphicsRasterUtils.asm,v 1.1 97/04/05 01:13:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsAllocBitmap	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetBitmapRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set resolution for a bitmap

CALLED BY:	GLOBAL

PASS:		di	- GState handle to bitmap (returned by GrCreateBitmap)
		ax	- x resolution (dpi)
		bx	- y resolution (dpi)

RETURN:		carry set if GState not associated with a bitmap

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Bitmap must be a complex bitmap, since simple bitmaps are all
		assumed to be 72dpi.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetBitmapRes	proc	far
		uses	ax, bx, cx, dx, si, di, ds
		.enter

		; get the current resolution, so we can properly set the window
		; scale factor

		push	ax, bx			; save new res so we can set
						;  it below
		push	di			; save GState handle
		push	ax			; save new x res
		mov	dx, bx			; do y first
		call	GrGetBitmapRes		; ax = xres, bx = yres
		jc	clearStackDone
		push	ax			; save old x res
		clr	cx, ax			; no fractions
		call	GrSDivWWFixed		; dxcx = y scale to apply
		mov	ax, dx			; axcx = y scale factor
		pop	bx			; restore old x res
		pop	dx			; restore new x res
		pushwwf	axcx			; save y scale factor
		clr	cx, ax			; no fractions
		call	GrSDivWWFixed		; dxcx = x scale factor
		call	GrGetWinHandle		; ax = window handle
		mov	di, ax			; di = window handle
		popwwf	bxax			; bxax = y scale factor
		mov	si, WIF_DONT_INVALIDATE
		call	WinApplyScale
		pop	di			; restore GState handle
		pop	ax, bx			; restore new resolution

		; lock down the header.

		push	ax, bx			; save x and y resolution
		call	LockHugeBitmap
		pop	ax, bx
		jc	done
		mov	ds:[EB_bm].CB_xres, ax
		mov	ds:[EB_bm].CB_yres, bx
		call	HugeArrayDirty
		call	HugeArrayUnlockDir
		clc
done:
		.leave
		ret

clearStackDone:
		add	sp, 8
		stc
		jmp	done
GrSetBitmapRes	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetBitmapRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get resolution for a bitmap

CALLED BY:	GLOBAL

PASS:		di	- GState handle to bitmap (returned by GrCreateBitmap)

RETURN:		carry set if GState not associated with a bitmap, else
		ax	- x resolution (dpi)
		bx	- y resolution (dpi)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Bitmap must be a complex bitmap, since simple bitmaps are all
		assumed to be 72dpi.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetBitmapRes	proc	far
		uses	di, ds
		.enter

		; lock down the header.

		call	LockHugeBitmap
		jc	done

		mov	ax, ds:[EB_bm].CB_xres
		mov	bx, ds:[EB_bm].CB_yres
		call	HugeArrayUnlockDir
		clc

done:
		.leave
		ret
GrGetBitmapRes	endp

GraphicsAllocBitmap	ends


GraphicsDrawBitmap	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetHugeBitmapSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the size in points of the bitmap

CALLED BY:	GLOBAL

PASS:		bx:di - HugeArray vm file/vm block handle

RETURN:		
		ax - x size in points
		bx - y size in points

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetHugeBitmapSize		proc	far
	uses	ds,si
	.enter

	call	HugeArrayLockDir
	mov	ds,ax
	mov	si,offset EB_bm
	call	GrGetBitmapSize
	call	HugeArrayUnlockDir

	.leave
	ret
GrGetHugeBitmapSize		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetBitmapSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the size of a bitmap

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to bitmap

RETURN:		ax	- x size (points)
		bx	- y size (points)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If the bitmap resolution is not the default, then
		calculate the appropriate size

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetBitmapSize	proc	far
		uses	cx, dx
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx					>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx					>
endif		
		; first check for a simple bitmap.  If this is the case,
		; just return the stored height and width.  We'll assume
		; that is the case.  We can also do this if the bitmap is
		; complex, but the resolution is 72 dpi

		mov	ax, ds:[si].B_width		; get width as is
		mov	bx, ds:[si].B_height		; same for height
		test	ds:[si].B_type, mask BMT_COMPLEX ; complex type ?
		jz	done				;   no, all done
		cmp	ds:[si].CB_xres, 72		; check for 72 dpi
		jne	calculateWidth			;  no, do full calc
		cmp	ds:[si].CB_yres, 72		; check for 72 dpi
		je	done				;  yes, all done

		; OK, the resolution is screwy -- do the width calc first
calculateWidth:
		mov	dx, DEF_BITMAP_RES 	; set up dividend
		clr	cx
		mov	bx, ds:[si].CB_xres	; get x resolution
		clr	ax
		call	GrUDivWWFixed		; calculate the factor
		mov	bx, ds:[si].B_width	; calculate new width
		clr	ax
		call	GrMulWWFixed		; calc new width
		add	cx, 8000h		; do the rounding
		adc	dx, 0
		push	dx			; save new width

		; now do height

		mov	dx, DEF_BITMAP_RES 	; set up dividend
		clr	cx
		mov	bx, ds:[si].CB_yres	; get y resolution
		clr	ax
		call	GrUDivWWFixed		; calculate the factor
		mov	bx, ds:[si].B_height	; calculate new width
		clr	ax
		call	GrMulWWFixed		; calc new width
		add	cx, 8000h		; do the rounding
		adc	dx, 0
		mov	bx, dx 			; set new height
		pop	ax			; restore new width
done:
		.leave
		ret
GrGetBitmapSize	endp

GraphicsDrawBitmap	ends













