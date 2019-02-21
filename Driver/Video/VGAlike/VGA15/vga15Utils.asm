COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		vga8Utils.asm

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
		

	$Id: vga8Utils.asm,v 1.2 96/08/05 03:51:40 canavese Exp $

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
		jim	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetVESAWin	proc	far
		uses	bx, cx
		.enter

                mov	cs:[pixelOffset], dx		; save offset
		mov	cx, dx				; save offset into scan
		mov	bx, cs:[modeInfo].VMI_scanSize	; get bytes/scan
		mul	bx				; dxax = 32-bit offset

                or      cx, cx
                jns     notneg
                neg     cx
                sub     ax,cx
                sbb     dx,00000h
                jmp     wasneg
notneg:
		add	ax, cx				; add offset into line
		adc	dx, 0
wasneg:
                mov     bx, cs:[modeInfo].VMI_winGran   ; bx = granularity
		cmp	bx, 0x40			; if 64K, done
		jne	computePage

		; at this point, dx = page number, ax = offset into page
havePage:
		push	ax				; save offset
		mov	cs:[curWinPage], dx		; save page number
                or      dx, dx
                js      pageSet
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

                pop     ax
                push    ax

		sub	ax, cs:[curWinEnd]		; check for partialscan
		neg	ax
		cmp	ax, cs:[modeInfo].VMI_scanSize
                jae     normalScan

		inc	ax
                shr     ax, 1
		mov	cs:[pixelsLeft], ax

normalScan:
		pop	ax				; restore offset
		mov	dx, cs:[writeSegment]		; load up segment

		.leave
		ret

		; if the granularity is not 64K, we have more computation to do
computePage:
                mov     bx, cs:[modeInfo].VMI_winSize   ; bx = granularity
                cmp     bx, 64
                jz      k64

		xchg	bl, bh				; *256
		shl	bx, 1				; *512
		shl	bx, 1				; *1024
                div     bx                              ; ax = page, dx = off
		xchg	ax, dx

k64:            push    ax

                mov     bx, cs:[nextWinInc]
                mov     ax, dx
                mul     bx
                mov     dx, ax

                pop     ax
                jmp     havePage
                
		; there is no window function, so use the software interrupt
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		int	VIDEO_BIOS
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
                or      dx, dx
                js      done

		cmp	cs:[modeInfo].VMI_scanSize, 1024
		jne	oddScanSize

		mov	ax, cs:[curWinEnd]
		andnf	ax, 0xfc00
done:
		ret

		; scan size is not 1024
oddScanSize:
                cmp     cs:[modeInfo].VMI_winGran, 64
                je      k64
		mov	ax, dx				; ax = win number
		mov	dx, cs:[modeInfo].VMI_winGran
		xchg	dh, dl				; *256
		shl	dx, 1				; *512
		shl	dx, 1				; *1024
		mul	dx				; dx:ax = window addr
                jmp     both
k64:
                clr     ax
both:
                push    ax                              ; save window addr.low
		add	ax, cs:[curWinEnd]
		adc	dx, 0
;                incdw   dxax                            ; +winSize
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

                mov     cs:[pixelOffsetSrc], dx         ; save offset
		mov	cx, dx				; save offset into scan
		mov	bx, cs:[modeInfo].VMI_scanSize	; get bytes/scan
		mul	bx				; dxax = 32-bit offset
		add	ax, cx				; add offset into line
		adc	dx, 0
                mov     bx, cs:[modeInfo].VMI_winGran   ; bx = granularity
		cmp	bx, 0x40			; if 64K, done
		jne	computePage

		; at this point, dx = page number, ax = offset into page
havePage:
		push	ax				; save offset
		mov	cs:[curWinPageSrc], dx
                or      dx, dx
                js      pageSet

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

                pop     ax
                push    ax

		sub	ax, cs:[curWinEnd]		; check for partialscan
		neg	ax
		cmp	ax, cs:[modeInfo].VMI_scanSize
                jae     normalScan

		inc	ax
                shr     ax, 1        
                mov     cs:[pixelsLeftSrc], ax

normalScan:
		pop	ax				; restore offset
		mov	dx, cs:[readSegment]		; load up segment

		.leave
		ret

		; if the granularity is not 64K, we have more computation to do
computePage:
                mov     bx, cs:[modeInfo].VMI_winSize   ; bx = granularity
                cmp     bx, 64
                jz      k64

		xchg	bl, bh				; *256
		shl	bx, 1				; *512
		shl	bx, 1				; *1024
                div     bx                              ; ax = page, dx = off
		xchg	ax, dx

k64:            push    ax

                mov     bx, cs:[nextWinInc]
                mov     ax, dx
                mul     bx
                mov     dx, ax

                pop     ax
                jmp     havePage

		; there is no window function, so use the software interrupt
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		int	VIDEO_BIOS
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
SetNextWin      proc    far
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
                or      dx, dx
                js      pageSet

		clr	bh  				; set window A
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
                shr     ax, 1
		mov	cs:[pixelsLeft], ax
		stc
		jmp	done

		; no window function supplied, use BIOS
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		int	VIDEO_BIOS
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

		; definitely past the end of the window.  Onto the next one.
nextPage:
		sub	di, cs:[curWinEnd]
		dec	di				; di = offset into next
		mov	dx, cs:[curWinPageSrc]		; get current page #
		add	dx, cs:[nextWinInc]		; bump to next page
		mov	cs:[curWinPageSrc], dx		; get new page
                or      dx,dx
                js      pageSet

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
                shr     ax, 1
		mov	cs:[pixelsLeftSrc], ax
		stc
		jmp	done

		; no window function supplied, use BIOS
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		int	VIDEO_BIOS
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
                or      dx, dx
                js      pageSet
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
		int	VIDEO_BIOS
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
                or      dx, dx
                js      pageSet

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
		int	VIDEO_BIOS
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

                mov     dx, cs:[modeInfo].VMI_winSize
		xchg	dl, dh				; *256
		shl	dx, 1				; *512
		shl	dx, 1				; *1024
		add	di, dx				; add winGran size
		mov	dx, cs:[curWinPage]		; get new page
                sub     dx, cs:[nextWinInc]
                mov     cs:[curWinPage], dx
                or      dx, dx
                js      pageSet

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
                shr     ax, 1
		mov	cs:[pixelsLeftSrc], ax
		stc
		jmp	done

		; no window function supplied, use BIOS
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		int	VIDEO_BIOS
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
	jim	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPrevWinSrc	proc	far
		uses	ax, bx, dx
		.enter

		; definitely past the end of the window.  Onto the prev one.

                mov     dx, cs:[modeInfo].VMI_winSize
		xchg	dl, dh				; *256
		shl	dx, 1				; *512
		shl	dx, 1				; *1024
		add	di, dx				; add winGran size
		mov	dx, cs:[curWinPageSrc]		; get new page
                sub     dx, cs:[nextWinInc]
                mov     cs:[curWinPageSrc], dx
                or      dx, dx
                js      pageSet
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
                shr     ax, 1
                mov     cs:[pixelsLeftSrc], ax
		stc
		jmp	done

		; no window function supplied, use BIOS
useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		int	VIDEO_BIOS
		jmp	pageSet
SetPrevWinSrc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the ditherMatrix

CALLED BY:	CheckSetDither macro
PASS:		ds:[si]	- CommonAttr structure
		es	- Window structure
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We have quite a few more colors to dither with.  I'm using
		a method suggested in Graphics Gems 2, page 72.  Basically,
		we take the 8-bit component values (RGB), map them into 6
		different base values (0,33,66,99,cc,ff) and achieve shades
		in between those six by dithering.  Thus the remainder of the
		desired color minus the base chosen is used to index into a
		set of dither matrices for each component.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetDither       proc    far
		uses	ax,bx,cx,dx,si,ds,es,di

		.enter
 
		; load up the RGB values...

		mov	dl, ds:[si].CA_colorRGB.RGB_red
		mov	dh, ds:[si].CA_colorRGB.RGB_green
		mov	bl, ds:[si].CA_colorRGB.RGB_blue
		mov	ax, es:[W_pattPos]		; get patt ref point
		and	ax, 0x0303			; need low 2, not three

		; check to see if we really need to re-create it.  If the color
		; is the same, and the shift amount is the same, then we're OK.

		cmp	dl, cs:[ditherColor].RGB_red
		jne	setNewDither
		cmp	dh, cs:[ditherColor].RGB_green
		jne	setNewDither
		cmp	bl, cs:[ditherColor].RGB_blue
		jne	setNewDither
		
		; besides the color, we should check the rotation.

		cmp	ax, {word} cs:[ditherRotX]	; same ?
		LONG je	done

setNewDither:
		mov	cs:[ditherColor].RGB_red, dl	; set new color
		mov	cs:[ditherColor].RGB_green, dh
		mov	cs:[ditherColor].RGB_blue, bl
		mov	{word} cs:[ditherRotX], ax	; set rotation value

		segmov	es, cs, di
		mov	di, offset ditherMatrix		; es:di -> ditherMatrix

		; init the matrix with the base values...

		segmov	es, cs, di
		mov	di, offset ditherMatrix		; es:di -> ditherMatrix

		; now fill in the 16 dither positions.

		segmov	ds, cs, si
		mov	si, offset ditherCutoff		; ds:si = cutoff values
		mov	cx, 16				; 16 values to calc

calcLoop:
                push    dx
                push    bx

                ; dither red part

                lodsb
                mov     bh, dl
                and     bh,7
                cmp     al, bh
                jnc     dithGreen
                add     dl, 8
                jnc     dithGreen
                mov     dl,255

dithGreen:
                ; dither green part

                mov     bh, dh
                and     bh, 3
                shl     bh, 1
                cmp     al, bh
                jnc     dithBlue
                add     dh, 4
                jnc     dithBlue
                mov     dh, 255

dithBlue:
                ; dither blue part

                mov     bh, bl
                and     bh, 7
                cmp     al, bl
                jnc     dithDone
                add     bl, 8
                jnc     dithDone
                mov     bl, 255

dithDone:
                ; calc the RGB color value and save it in the
                ; dither matrix
                push    ax
                push    bx

                mov     bh, dl
                mov     al, dh
                mov     ah, bl

                mov     bl, ah
                shr     bx, 1
                shr     bx, 1
                shr     bx, 1

                shl     al, 1
                rcl     bh, 1
                shl     al, 1
                rcl     bh, 1

                and     al, 0E0h
                and     bl, 01Fh
                or      bl, al
                mov     ax, bx
                stosw                           ; store value in dither 
                pop     bx
                pop     ax

                pop     bx
                pop     dx

                loop    calcLoop

                ; both direction x and y
                mov     cx, {word} cs:[ditherRotX]     

                jcxz    done

                call    RotateDither                
done:
                .leave
                ret
SetDither       endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dither is offset by the window position.  Rotate it.

CALLED BY:	INTERNAL
		SetDither
PASS:		ditherMatrix initialized
		cl	- x rotation
		ch	- y rotation
RETURN:		nothing
DESTROYED:	cx, bx, ax

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
comment %
RotateDither	proc	near
		
		; rotate in x first, then in Y

		tst	cl
		jz	handleY
		mov	si, offset cs:ditherMatrix
		call	RotateX
		add	si, 4
		call	RotateX
		add	si, 4
		call	RotateX
		add	si, 4
		call	RotateX
handleY:
		tst	ch
		jz	done
		mov	si, offset cs:ditherMatrix
		call	RotateY
		inc	si
		call	RotateY
		inc	si
		call	RotateY
		inc	si
		call	RotateY
done:
		ret
RotateDither	endp

RotateX		proc	near
		mov	ax, {word} ds:[si]
		mov	bx, {word} ds:[si+2]
		cmp	cl, 2
		ja	doThree
		jb	doOne
		xchg	ax, bx
done:
		mov	{word} ds:[si], ax
		mov	{word} ds:[si+2], bx
		ret
doThree:
		xchg	al, ah
		xchg	ah, bl
		xchg	bl, bh
		jmp	done
doOne:
		xchg	al, bh
		xchg	bh, bl
		xchg	bl, ah
		jmp	done
RotateX		endp

RotateY		proc	near
		mov	al, {byte} ds:[si]
		mov	ah, {byte} ds:[si+4]
		mov	bl, {byte} ds:[si+8]
		mov	bh, {byte} ds:[si+12]
		cmp	ch, 2
		ja	doThree
		jb	doOne
		xchg	ax, bx
done:
		mov	{byte} ds:[si], al
		mov	{byte} ds:[si+4], ah
		mov	{byte} ds:[si+8], bl
		mov	{byte} ds:[si+12], bh
		ret
doThree:
		xchg	al, ah
		xchg	ah, bl
		xchg	bl, bh
		jmp	done
doOne:
		xchg	al, bh
		xchg	bh, bl
		xchg	bl, ah
		jmp	done
RotateY		endp
%

RotateDither    proc    near

		; rotate in x first, then in Y

		tst	cl
		jz	handleY
		mov	si, offset cs:ditherMatrix
		call	RotateX
                add     si, 8
		call	RotateX
                add     si, 8
		call	RotateX
                add     si, 8
		call	RotateX
handleY:
		tst	ch
		jz	done
		mov	si, offset cs:ditherMatrix
		call	RotateY
		inc	si
                inc     si
		call	RotateY
		inc	si
                inc     si
		call	RotateY
		inc	si
                inc     si
		call	RotateY
done:
		ret
RotateDither	endp

RotateX         proc    near
                uses    bp, dx

                .enter

                mov     ax, [si]
                mov     bx, [si+2]         
                mov     bp, [si+4]
                mov     dx, [si+6]

                cmp     cl, 2                       
                ja      doThree     
                jc      doOne

                xchg    bp, ax       
                xchg    dx, bx
done:
                mov     [si], ax              
                mov     [si+2], bx            
                mov     [si+4], bp
                mov     [si+6h], dx

                .leave

                ret

doThree:
                xchg    bx,ax 
                xchg    bp,bx 
                xchg    dx,bp 
                jmp     done

doOne:
                xchg    dx,ax        
                xchg    bp,dx
                xchg    bx,bp
                jmp     done

RotateX         endp

RotateY         proc    near        
                uses    bp, dx

                .enter
                mov     ax, [si]    
                mov     bx, [si+8]
                mov     bp, [si+16]
                mov     dx, [si+24]

                cmp     ch, 2

                ja      doThree
                jc      doOne

                xchg    bp, ax
                xchg    dx, bx    
done:
                mov     [si], ax
                mov     [si+8], bx
                mov     [si+16], bp
                mov     [si+24], dx

                .leave
                ret

doThree:
                xchg    bx, ax 
                xchg    bp, bx
                xchg    dx, bp
                jmp     done

doOne:
                xchg    dx, ax
                xchg    bp, dx
                xchg    bx, bp
                jmp     done

RotateY         endp


CalcPalette     proc    far
                uses    ds, si, di, bx, cx

                .enter

                mov     ds, word ptr ss:[bmPalette+2]
                mov     si, word ptr ss:[bmPalette]

                mov     di ,0
                mov     cx, 16

                and     bl, 7
                dec     bl
                jz      calcLoop

                mov     cx, 256
                dec     bl
                jnz     done

calcLoop:
                mov     bh, [si]
                mov     ax, word ptr [si+1]
                add     si, 3
 
                mov     bl, ah
                shr     bx, 1
                shr     bx, 1
                shr     bx, 1

                shl     al, 1
                rcl     bh, 1
                shl     al, 1
                rcl     bh, 1

                and     al, 0E0h
                and     bl, 01Fh
                or      bl, al

                mov     ss:[transPalette][di], bx

                inc     di
                inc     di
                loop    calcLoop
done:
                .leave
                ret

CalcPalette     endp


