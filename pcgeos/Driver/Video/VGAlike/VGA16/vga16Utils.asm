COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		vga16Utils.asm

AUTHOR:		Jim DeFrisco, Feb  5, 1992

ROUTINES:
	Name			Description
	----			-----------
	SetMemWin		Called by the CalcScanLine macro

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/ 5/92		Initial revision


DESCRIPTION:
	Utility routines for 256-color vga
		

	$Id: vga16Utils.asm,v 1.2$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetVESAWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the correct memory window for the display. 

CALLED BY:	INTERNAL
		CalcScanLine macro
PASS:		ax	- scan line
		dx	- offset into line
RETURN:		ax	- offset into window
		dx	- window segment
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetVESAWin	proc	far
		uses	bx, cx
		.enter

		mov	cs:[pixelOffset], dx		; save offset
		mov	cx, dx				; save offset into scan
		mov	bx, cs:[modeInfo].VMI_scanSize	; get bytes/scan
		mul	bx				; dxax = 32-bit offset

		tst	cx
		jns	notneg
		neg	cx
		sub	ax, cx
		sbb	dx, 0
		jmp	wasneg
notneg:
		add	ax, cx				; add offset into line
		adc	dx, 0
wasneg:
		mov	bx, cs:[modeInfo].VMI_winGran	; bx = granularity
		cmp	bx, 0x40			; if 64K, done
		jne	computePage

		; at this point, dx = page number, ax = offset into page
havePage:
		push	ax				; save offset
		mov	cs:[curWinPage], dx		; save page number
		tst	dx
		js	pageSet
		clr	bh				; set window A
		mov	bl, cs:[writeWindow]
		tst	cs:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	cs:[modeInfo].VMI_winFunc	; set page

		; now that the page is set, pre-compute some optimization
		; variables, since we assume that we will be accessing other
		; scan lines around this one.
pageSet:
		mov	dx, cs:[curWinPage]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtr], ax

		pop	ax
		push	ax

		sub	ax, cs:[curWinEnd]		; check for partialscan
		neg	ax
		cmp	ax, cs:[modeInfo].VMI_scanSize
		jae	normalScan

		inc	ax
		shr	ax, 1
		mov	cs:[pixelsLeft], ax

normalScan:
		pop	ax				; restore offset
		mov	dx, cs:[writeSegment]		; load up segment

		.leave
		ret

		; if the granularity is not 64K, we have more computation to do
computePage:
		mov	bx, cs:[modeInfo].VMI_winSize	; bx = granularity
		cmp	bx, 64
		jz	k64

		xchg	bl, bh				; *256
		shl	bx, 1				; *512
		shl	bx, 1				; *1024
		div	bx				; ax = page, dx = off
		xchg	ax, dx

k64:		push	ax

		mov	bx, cs:[nextWinInc]
		mov	ax, dx
		mul	bx
		mov	dx, ax

		pop	ax
		jmp	havePage
		
		; there is no window function, so use the software interrupt
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		CALL_VIDEO
		jmp	pageSet

SetVESAWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLastScanPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a pointer to the last scan line in the window

CALLED BY:	INTERNAL
PASS:		dx	- current window number
RETURN:		ax	- offset to beginning of last scanline in window
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
		Basic equation is:

			unknown

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcLastScanPtr	proc	near
		tst	dx
		js	done

		cmp	cs:[modeInfo].VMI_scanSize, 1024
		jne	oddScanSize

		mov	ax, cs:[curWinEnd]
		andnf	ax, 0xfc00
done:
		ret

		; scan size is not 1024
oddScanSize:
		cmp	cs:[modeInfo].VMI_winGran, 64
		je	k64
		mov	ax, dx				; ax = win number
		mov	dx, cs:[modeInfo].VMI_winGran
		xchg	dh, dl				; *256
		shl	dx, 1				; *512
		shl	dx, 1				; *1024
		mul	dx				; dx:ax = window addr
		jmp	both
k64:
		clr	ax
both:
		push	ax				; save window addr.low
		add	ax, cs:[curWinEnd]
		adc	dx, 0
		mov	bx, cs:[modeInfo].VMI_scanSize
		div	bx
		mul	bx
		pop	bx
		sub	ax, bx
		ret

CalcLastScanPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetVESAWinSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used by Blt to set source window for reading

CALLED BY:	INTERNAL
		BltQuick
PASS:		ax	- scan line
		dx	- offset into line
RETURN:		ax	- offset into window
		dx	- window segment
DESTROYED:	

PSEUDO CODE/STRATEGY:
		If the VESA board supports two windows, this function will set
		up the "read" window and save away the segment address.
		
		If only one window is supported, 
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetVESAWinSrc	proc	far
		uses	bx, cx
		.enter

		mov	cs:[pixelOffsetSrc], dx	 ; save offset
		mov	cx, dx				; save offset into scan
		mov	bx, cs:[modeInfo].VMI_scanSize	; get bytes/scan
		mul	bx				; dxax = 32-bit offset
		add	ax, cx				; add offset into line
		adc	dx, 0
		mov	bx, cs:[modeInfo].VMI_winGran	; bx = granularity
		cmp	bx, 0x40			; if 64K, done
		jne	computePage

		; at this point, dx = page number, ax = offset into page
havePage:
		push	ax				; save offset
		mov	cs:[curWinPageSrc], dx
		tst	dx
		js	pageSet

		clr	bh				; set mode
		mov	bl, cs:[readWindow]		; set window A
		tst	cs:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	cs:[modeInfo].VMI_winFunc	; set page

		; now that the page is set, pre-compute some optimization
		; variables, since we assume that we will be accessing other
		; scan lines around this one.
pageSet:
		mov	dx, cs:[curWinPageSrc]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtrSrc], ax

		pop	ax
		push	ax

		sub	ax, cs:[curWinEnd]		; check for partialscan
		neg	ax
		cmp	ax, cs:[modeInfo].VMI_scanSize
		jae	normalScan

		inc	ax
		shr	ax, 1	
		mov	cs:[pixelsLeftSrc], ax

normalScan:
		pop	ax				; restore offset
		mov	dx, cs:[readSegment]		; load up segment

		.leave
		ret

		; if the granularity is not 64K, we have more computation to do
computePage:
		mov	bx, cs:[modeInfo].VMI_winSize	; bx = granularity
		cmp	bx, 64
		jz	k64

		xchg	bl, bh				; *256
		shl	bx, 1				; *512
		shl	bx, 1				; *1024
		div	bx				; ax = page, dx = off
		xchg	ax, dx

k64:		push	ax

		mov	bx, cs:[nextWinInc]
		mov	ax, dx
		mul	bx
		mov	dx, ax

		pop	ax
		jmp	havePage

		; there is no window function, so use the software interrupt
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		CALL_VIDEO
		jmp	pageSet

SetVESAWinSrc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNextWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the next window, position the offset at the last scan

CALLED BY:	INTERNAL
		NextScan macro
PASS:		di	- old offset into window + scanSize
		carry	- set if change of window is definite
RETURN:		carry	- set if this scan line is now wholly in window
		di	- offset into next window
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNextWin	proc	far
		uses	ax, bx, dx
		.enter

		jc	nextPage
		cmp	di, cs:[curWinEnd]
		jbe	doPartial

		; definitely past the end of the window.  Onto the next one.
nextPage:
		sub	di, cs:[curWinEnd]
		dec	di				; di = offset into next
		mov	dx, cs:[curWinPage]		; get current page #
		add	dx, cs:[nextWinInc]		; bump to next page
		mov	cs:[curWinPage], dx		; get new page
		tst	dx
		js	pageSet

		clr	bh					; set window A
		mov	bl, cs:[writeWindow]
		tst	cs:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	cs:[modeInfo].VMI_winFunc	; set page

		; done setting new page.
pageSet:
		mov	dx, cs:[curWinPage]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtr], ax
		mov	ax, di
		sub	ax, cs:[curWinEnd]		; check for partialscan
		neg	ax
		cmp	ax, cs:[modeInfo].VMI_scanSize
		jb	partialScan
		clc
done:
		.leave
		ret

doPartial:
		mov	ax, cs:[curWinEnd]		; compute #pixs left
		sub	ax, di
partialScan:
		inc	ax
		shr	ax, 1
		mov	cs:[pixelsLeft], ax
		stc
		jmp	done

		; no window function supplied, use BIOS
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		CALL_VIDEO
		jmp	pageSet

SetNextWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNextWinSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the next window, position the offset at the last scan

CALLED BY:	INTERNAL
		NextScan macro
PASS:		di	- offset into window
RETURN:		carry	- set if this scan line is now wholly in window
		di	- offset into next window
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNextWinSrc	proc	far
		uses	ax, bx, dx
		.enter

		jc	nextPage
		cmp	di, cs:[curWinEnd]
		jbe	doPartial

		; definitely past the end of the window.	Onto the next one.
nextPage:
		sub	di, cs:[curWinEnd]
		dec	di				; di = offset into next
		mov	dx, cs:[curWinPageSrc]		; get current page #
		add	dx, cs:[nextWinInc]		; bump to next page
		mov	cs:[curWinPageSrc], dx		; get new page
		tst	dx
		js	pageSet

		clr	bh
		mov	bl, cs:[readWindow]			; set window A
		tst	cs:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	cs:[modeInfo].VMI_winFunc	; set page

		; done setting new page.
pageSet:		
		mov	dx, cs:[curWinPageSrc]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtrSrc], ax
		mov	ax, di
		sub	ax, cs:[curWinEnd]		; check for partialscan
		neg	ax
		cmp	ax, cs:[modeInfo].VMI_scanSize
		jb	partialScan
		clc
done:
		.leave
		ret

doPartial:
		mov	ax, cs:[curWinEnd]		; compute #pixs left
		sub	ax, di
partialScan:
		inc	ax
		shr	ax, 1
		mov	cs:[pixelsLeftSrc], ax
		stc
		jmp	done

		; no window function supplied, use BIOS
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		CALL_VIDEO
		jmp	pageSet

SetNextWinSrc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MidScanNextWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In the middle of processing a scan line, move to next window

CALLED BY:	
PASS:		nothing
RETURN:		di	- cleared
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MidScanNextWin	proc	far
		uses	ax, dx, bx
		.enter

		mov	dx, cs:[curWinPage]		; get current page #
		add	dx, cs:[nextWinInc]		; bump to next page
		mov	cs:[curWinPage], dx		; get new page
		tst	dx
		js	pageSet
		clr	bh				; set window A
		mov	bl, cs:[writeWindow]
		tst	cs:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	cs:[modeInfo].VMI_winFunc	; set page

		; done setting new page.
pageSet:		
		mov	dx, cs:[curWinPage]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtr], ax
		clr	di				; restore offset in win

		.leave
		ret

		; no window function supplied, use BIOS
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		CALL_VIDEO
		jmp	pageSet

MidScanNextWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MidScanNextWinSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In the middle of processing a scan line, move to next window

CALLED BY:	
PASS:		nothing
RETURN:		di	- cleared
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MidScanNextWinSrc	proc	far
		uses	ax, dx, bx
		.enter

		mov	dx, cs:[curWinPageSrc]		; get current page #
		add	dx, cs:[nextWinInc]		; bump to next page
		mov	cs:[curWinPageSrc], dx		; get new page
		tst	dx
		js	pageSet

		clr	bh				; set window A
		mov	bl, cs:[readWindow]
		tst	cs:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	cs:[modeInfo].VMI_winFunc	; set page

		; done setting new page.
pageSet:		
		mov	dx, cs:[curWinPageSrc]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtrSrc], ax
		clr	di				; restore offset in win

		.leave
		ret

		; no window function supplied, use BIOS
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		CALL_VIDEO
		jmp	pageSet

MidScanNextWinSrc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPrevWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the previous window, position the offset at the last scan

CALLED BY:	INTERNAL
		PrevScan macro
PASS:		di	- offset into window
RETURN:		carry	- set if this scan line is now wholly in window
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPrevWin	proc	far
		uses	ax, bx, dx
		.enter

		; definitely past the end of the window.  Onto the prev one.

		mov	dx, cs:[modeInfo].VMI_winSize
		xchg	dl, dh				; *256
		shl	dx, 1				; *512
		shl	dx, 1				; *1024
		add	di, dx				; add winGran size
		mov	dx, cs:[curWinPage]		; get new page
		sub	dx, cs:[nextWinInc]
		mov	cs:[curWinPage], dx
		tst	dx
		js	pageSet

		clr	bh
		mov	bl, cs:[writeWindow]		; set window A
		tst	cs:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	cs:[modeInfo].VMI_winFunc	; set page

		; done setting new page.
pageSet:
		mov	dx, cs:[curWinPage]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtr], ax
		mov	ax, di
		sub	ax, cs:[curWinEnd]		; check for partialscan
		neg	ax
		cmp	ax, cs:[modeInfo].VMI_scanSize
		jb	partialScan
		clc
done:
		.leave
		ret

partialScan:
		shr	ax, 1
		mov	cs:[pixelsLeft], ax
		stc
		jmp	done

		; no window function supplied, use BIOS
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		CALL_VIDEO
		jmp	pageSet
SetPrevWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPrevWinSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the previous window, position the offset at the last scan

CALLED BY:	INTERNAL
		PrevScan macro
PASS:		di	- offset into window
RETURN:		carry	- set if this scan line is now wholly in window
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPrevWinSrc	proc	far
		uses	ax, bx, dx
		.enter

		; definitely past the end of the window.  Onto the prev one.

		mov	dx, cs:[modeInfo].VMI_winSize
		xchg	dl, dh				; *256
		shl	dx, 1				; *512
		shl	dx, 1				; *1024
		add	di, dx				; add winGran size
		mov	dx, cs:[curWinPageSrc]		; get new page
		sub	dx, cs:[nextWinInc]
		mov	cs:[curWinPageSrc], dx
		tst	dx
		js	pageSet
		clr	bh				; set window A
		mov	bl, cs:[readWindow]
		tst	cs:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	cs:[modeInfo].VMI_winFunc	; set page

		; done setting new page.
pageSet:		
		mov	dx, cs:[curWinPageSrc]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtrSrc], ax
		mov	ax, di
		sub	ax, cs:[curWinEnd]		; check for partialscan
		neg	ax
		cmp	ax, cs:[modeInfo].VMI_scanSize
		jb	partialScan
		clc
done:
		.leave
		ret

partialScan:
		shr	ax, 1
		mov	cs:[pixelsLeftSrc], ax
		stc
		jmp	done

		; no window function supplied, use BIOS
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		CALL_VIDEO
		jmp	pageSet
SetPrevWinSrc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetWinPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just set the current memory window

CALLED BY:	INTERNAL
PASS:		bl	- window to set
		dx	- which window to set
RETURN:		nothing
DESTROYED:	bx,dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetWinPage	proc	far
		or	dx, dx
		js	done
		clr	bh
		tst	ss:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	ss:[modeInfo].VMI_winFunc	; set page
done:		
		ret

useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		CALL_VIDEO
		jmp	done		
SetWinPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert 8-bit palette to 16-bit RGB

CALLED BY:	INTERNAL
PASS:		bmPalette	= palette
RETURN:		transPalette	= 16-bit RGB palette
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/20/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcPalette	proc	far
		uses	ax,bx,cx,si,di,ds,es
		.enter

		lds	si, ss:[bmPalette]
		segmov	es, ss, di
		mov	di, offset transPalette
		andnf	bl, mask BMT_FORMAT
		mov	cx, 2
		cmp	bl, BMF_MONO
		je	calcLoop
		mov	cx, 16
		cmp	bl, BMF_4BIT
		je	calcLoop
		mov	cx, 256
		cmp	bl, BMF_8BIT
		jne	done
calcLoop:
		mov	bl, ds:[si]
		mov	ax, ds:[si+1]
		xchg	al, ah
		shr	ah, 2
		shr	ax, 3
		andnf	bl, 0xf8
		ornf	ah, bl
		stosw
		add	si, 3
		loop	calcLoop
done:
		.leave
		ret
CalcPalette	endp
