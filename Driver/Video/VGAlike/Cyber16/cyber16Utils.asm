COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		cyber16Utils.asm

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
	Utility routines for 64K-color IGS CyberPro
		

	$Id: cyber16Utils.asm,v 1.2$

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
		uses	cx
		.enter

		mov	cs:[pixelOffset], dx		; save offset
		mov	cx, dx				; save offset into scan
		mul	cs:[modeInfo].VMI_scanSize	; dxax = 32-bit offset

		tst	cx
		jns	notneg
		add	ax, cx
		adc	dx, -1
		jmp	wasneg
notneg:
		add	ax, cx				; add offset into line
		adc	dx, 0
wasneg:

		; at this point, dx = page number, ax = offset into page

		mov	cs:[curWinPage], dx		; save page number

		; pre-compute some optimization variables, since we assume
		; that we will be accessing other scan lines around this one.

		push	ax
		neg	ax				; ax = bytes left
		shr	ax, 1				; partial scan
		mov	cs:[pixelsLeft], ax

		call	CalcLastScanPtr
		mov	cs:[lastWinPtr], ax

		; set page

		call	SetCyberProWinPage
		pop	ax				; restore offset

		mov	dx, cs:[writeSegment]		; load up segment

		.leave
		ret
SetVESAWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLastScanPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a pointer to the last scan line in the window

CALLED BY:	INTERNAL
PASS:		dx	- current window number
RETURN:		ax	- offset to beginning of last scanline in window
DESTROYED:	dx

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
		mov	ax, 0xffff
		div	cs:[modeInfo].VMI_scanSize
		mul	cs:[modeInfo].VMI_scanSize
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
	jim	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetVESAWinSrc	proc	far
		uses	cx
		.enter

		mov	cs:[pixelOffsetSrc], dx		; save offset
		mov	cx, dx				; save offset into scan
		mul	cs:[modeInfo].VMI_scanSize	; dxax = 32-bit offset
		add	ax, cx				; add offset into line
		adc	dx, 0

		; at this point, dx = page number, ax = offset into page

		mov	cs:[curWinPageSrc], dx

		; pre-compute some optimization variables, since we assume
		; that we will be accessing other scan lines around this one.

		push	ax				; save offset
		neg	ax
		shr	ax, 1	
		mov	cs:[pixelsLeftSrc], ax

		call	CalcLastScanPtr
		mov	cs:[lastWinPtrSrc], ax

		; set page for source only

		call	SetCyberProWinPageSrc
		pop	ax				; restore offset

		mov	dx, cs:[readSegment]		; load up segment

		.leave
		ret
SetVESAWinSrc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNextWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the next window, position the offset at the last scan

CALLED BY:	INTERNAL
		NextScan macro
PASS:		di	- old offset into window + scanSize
		carry	- set if change of window is definite
RETURN:		carry	- set if this scan line is not wholly in window
		di	- offset into next window
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNextWin	proc	far
		jc	nextPage

		push	ax
		mov	ax, di
		neg	ax				; ax = # bytes left 
		shr	ax, 1				; ax = # pixels left
		mov	cs:[pixelsLeft], ax
		pop	ax
		stc					; scan is not complete
		ret

		; definitely past the end of the window.  Onto the next one.
nextPage:
		push	ax, dx
		inc	cs:[curWinPage]			; bump to next page
		call	SetCyberProWinPage
		mov	dx, cs:[curWinPage]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtr], ax
		pop	ax, dx
		clc					; scan is complete
		ret
SetNextWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNextWinSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the next window, position the offset at the last scan

CALLED BY:	INTERNAL
		NextScan macro
PASS:		di	- offset into window
RETURN:		carry	- set if this scan line is not wholly in window
		di	- offset into next window
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNextWinSrc	proc	far
		jc	nextPage

		push	ax
		mov	ax, di
		neg	ax				; ax = # bytes left
		shr	ax, 1				; ax = # pixels left
		mov	cs:[pixelsLeftSrc], ax
		pop	ax
		stc					; scan is not complete
		ret

		; definitely past the end of the window.  Onto the next one.
nextPage:
		push	ax, dx
		inc	cs:[curWinPageSrc]		; bump to next page
		call	SetCyberProWinPageSrc
		mov	dx, cs:[curWinPageSrc]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtrSrc], ax
		pop	ax, dx
		clc					; scan is complete
		ret
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
		uses	ax, dx
		.enter

		inc	cs:[curWinPage]			; bump to next page
		call	SetCyberProWinPage
		mov	dx, cs:[curWinPage]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtr], ax
		clr	di				; restore offset in win

		.leave
		ret
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
		uses	ax, dx
		.enter

		inc	cs:[curWinPageSrc]		; bump to next page
		call	SetCyberProWinPageSrc
		mov	dx, cs:[curWinPageSrc]		; restore page number
		call	CalcLastScanPtr
		mov	cs:[lastWinPtrSrc], ax
		clr	di				; restore offset in win

		.leave
		ret
MidScanNextWinSrc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPrevWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the previous window, position the offset at the last scan

CALLED BY:	INTERNAL
		PrevScan macro
PASS:		di	- offset into window
RETURN:		carry	- set if this scan line is not wholly in window
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPrevWin	proc	far
		uses	ax, dx
		.enter

		tst	cs:[curWinPage]
		jz	calcLast

		dec	cs:[curWinPage]
		call	SetCyberProWinPage

		; calc last scan ptr
calcLast:
		mov	dx, cs:[curWinPage]
		call	CalcLastScanPtr
		mov	cs:[lastWinPtr], ax

		cmp	cs:[lastWinPtr], di
		ja	done				; scan is complete

		neg	ax				; ax = # bytes left
		shr	ax, 1				; ax = # pixels left
		mov	cs:[pixelsLeft], ax
		stc					; scan is not complete
done:
		.leave
		ret
SetPrevWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPrevWinSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the previous window, position the offset at the last scan

CALLED BY:	INTERNAL
		PrevScan macro
PASS:		di	- offset into window
RETURN:		carry	- set if this scan line is not wholly in window
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

		tst	cs:[curWinPageSrc]
		jz	calcLast

		dec	cs:[curWinPageSrc]
		call	SetCyberProWinPageSrc

		; calc last scan ptr
calcLast:
		mov	dx, cs:[curWinPageSrc]
		call	CalcLastScanPtr
		mov	cs:[lastWinPtrSrc], ax

		cmp	cs:[lastWinPtrSrc], di
		ja	done				; scan is complete

		neg	ax				; ax = # bytes left
		shr	ax, 1				; ax = # pixels left
		mov	cs:[pixelsLeftSrc], ax
		stc					; scan is not complete
done:
		.leave
		ret
SetPrevWinSrc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetWinPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just set the current memory window

CALLED BY:	INTERNAL
PASS:		bl	- window to set
		dx	- which window to set
RETURN:		nothing
DESTROYED:	ax,bx,dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetWinPage	proc	far

		mov	bh, dl
		outb	EXTINDEX, bl
		outb	EXTDATA, bh

		ret
SetWinPage	endp

if	SAVE_UNDER_COUNT gt 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetWinNoOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the dest window.

CALLED BY:	INTERNAL
		FirstWinNoOffset macro
PASS:		ax	= page to write
RETURN:		es	= segment to write
DESTROYS:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	4/21/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetWinNoOffset	proc	near

	mov	cs:[curWinPage], ax
	call	SetCyberProWinPage
	mov	es, cs:[writeSegment]

	ret
SetWinNoOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetWinNoOffsetSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the src window.

CALLED BY:	INTERNAL
		FirstWinNoOffsetSrc macro
PASS:		ax	= page to read
RETURN:		ds	= segment to read
DESTROYS:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	4/21/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetWinNoOffsetSrc	proc	near

	mov	cs:[curWinPageSrc], ax
	call	SetCyberProWinPageSrc
	mov	ds, cs:[readSegment]

	ret
SetWinNoOffsetSrc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNextWinNoOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance dest window to the next one.

CALLED BY:	INTERNAL
		NextWinNoOffset macro
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	4/21/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNextWinNoOffset	proc	near

	inc	cs:[curWinPage]
	GOTO	SetCyberProWinPage

SetNextWinNoOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNextWinNoOffsetSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance src window to the next one.

CALLED BY:	INTERNAL
		NextWinNoOffsetSrc macro
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	4/21/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNextWinNoOffsetSrc	proc	near

	inc	cs:[curWinPageSrc]
	GOTO	SetCyberProWinPageSrc

SetNextWinNoOffsetSrc	endp

endif	; SAVE_UNDER_COUNT gt 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCyberProWinPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set CyberPro win page

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/20/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCyberProWinPage	proc	near

		outb	EXTINDEX, CYBER_WRITE_BANK
		outb	EXTDATA, {byte}cs:[curWinPage]

		ret
SetCyberProWinPage	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCyberProWinPageSrc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set CyberPro win page src

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/20/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCyberProWinPageSrc	proc	near

		outb	EXTINDEX, CYBER_READ_BANK
		outb	EXTDATA, {byte}cs:[curWinPageSrc]

		ret
SetCyberProWinPageSrc	endp
	

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
		uses	ax,bx,cx,dx,si,di,bp,ds,es
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


;==============================================================================
;		IGS CyberPro 2010 Utility Functions (SETMODE.CPP)
;==============================================================================

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  SetIGSMode: To set graphics and TV mode
  In:	Data Structure sModeParam is set.
  Out:	Requested mode is set.
	Video memory is cleared.
	TV Out registers are also programmed.

  Note:
    1. The source code has already included following resolutions:
      -------------------------------------------
      | Resolution|  NTSC (60Hz) |  PAL (50Hz)	|
      |-----------|--------------|--------------|
      |  640x440  | CRT/TV (O/U) |     N/A	|
      |  640x480  | CRT/TV(O/U/I)|    CRT/TV	|
      |  720x540  |    N/A	 |    CRT/TV	|
      |  800x600  |    CRT	 |    CRT/TV	|
      | 1024x768  |    CRT	 |     N/A	|
      -------------------------------------------
	    1) . CRT/TV: Support both Monitor and TV.
	       . N/A:	 Not support or not applicable.
	       . CRT:	 Support Monitor only, no TV.
	       . O/U:	 Support Overscan/Underscan mode.
	       . O/U/I:  Support Overscan/Underscan/Interpolation mode.
	    2) . Please refer to tables in set2010.txt for
		   more resolution, such as 1280x1024 or 1600x1200.
		   more refresh rates, such as 56Hz, 60Hz, 72Hz or 75Hz.
	       The extra tables in set2010.txt can be easily combined into
	       IGS_TBLS.H to support desired modes.
	    3) Underscan:
	       640x480: Underscan applies to both horizontal and vertical.
	       640x440: Underscan applies to horizontal only. Vertical lines
			fit into screen by nature, so don't need underscan.
	    4) Interpolation: applies to vertical lines only.

    2. The refresh rate and color depth are hard-coded, but it is easy to
       modify the code to handle it. Since many OSs need small footprint of
       the final binary, the complete resolution tables are not included in
       igs_tbls.h file. To add more resolution/color depth/refresh rate
       support, please refer to set2010.txt for detail.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
screenCategory	char	"screen 0", 0
horizPosKey	char	"horizPos", 0
vertPosKey	char	"vertPos", 0
tvOptionsKey	char	"tvOptions", 0

SetIGSMode	proc	far

	call	DetectCRT

	tst	cs:[tvMode]
	jnz	doTV

doCRT::
	; Call video BIOS to set mode.
	mov	ax, (VESA_BIOS_EXT shl 8) or VESA_SET_MODE
	mov	bx, cs:[cyberProMode]
	mov	bx, cs:[vesaModeTable][bx]
	int	VIDEO_BIOS
	jmp	done

doTV:	
	; Call video BIOS to set mode.
	mov	ax, (VESA_BIOS_EXT shl 8) or VESA_SET_MODE
	mov	bx, CM_640x440_16_TV
	int	VIDEO_BIOS

	; save ext_reg_33 and ext_reg_3C
	outb	EXTINDEX, 0x33	
	inb	cs:[bReg33], EXTDATA	; bReg33 = inportb(EXTDATA);
	outb	EXTINDEX, 0x3C	
	inb	cs:[bReg3C], EXTDATA	; bReg3C = inportb(EXTDATA);

ifidn	PRODUCT, <>			; default version is NTSC
	; FSCLOW needs a little adjustment because the VBIOS doesn't set the
	; value that matches NTSC spec.
	clr	ax			; use default freq
	call	Cyber16SetTVSubcarrierFreq
endif	; PRODUCT, <>

	; Read init file to get any custom centering settings by the user.
	mov	cx, cs
	mov	dx, offset horizPosKey
	mov	ds, cx
	mov	si, offset screenCategory
	call	InitFileReadInteger		; CF clear if found, ax = val
	jc	afterCustomHoriz
	call	Cyber16SetHorizPos
afterCustomHoriz:
	mov	dx, offset vertPosKey
	call	InitFileReadInteger		; CF clear if found, ax = val
	jc	afterCustomVert
	call	Cyber16SetVertPos
afterCustomVert:

	; Replace default palette values with those for TV.
	mov	si, offset tvPaletteOverride	; ds:si = tvPaletteOverride
	mov	es, cx				; es = dgroup
	mov	di, offset currentPalette	; es:di = currentPalette
		CheckHack <(size tvPaletteOverride and 1) eq 0>
	mov	cx, size tvPaletteOverride / 2
	rep	movsw

	; Read init file to get other custom options.
	mov	si, offset screenCategory
	mov	cx, cs
	mov	dx, offset tvOptionsKey
	call	InitFileReadInteger		; CF clear if found, ax = val
	jc	afterTvOptions
ifidn	PRODUCT, <>			; default version is NTSC
	test	ax, mask VPOF_SET_TV_SUBCARRIER_FREQ
	jz	afterFreq
	call	Cyber16SetTVSubcarrierFreq	; passing ax non-zero
endif	; PRODUCT, <>
afterFreq:
	test	ax, mask VPOF_SET_BLACK_WHITE
	jz	afterBW
	call	Cyber16SetBlackWhite		; passing ax non-zero
afterBW:
afterTvOptions:

done:
	ret
SetIGSMode	endp

if	ALLOW_BIG_MOUSE_POINTER

vesaModeTable	label	VESAMode
	VESAMode	VM_640x480_16	; VD_IGS_CYBER_PRO_640x480_16_SP
	VESAMode	VM_640x480_16	; VD_IGS_CYBER_PRO_640x480_16_BP
	VESAMode	VM_800x600_16	; VD_IGS_CYBER_PRO_800x600_16_SP
	VESAMode	VM_800x600_16	; VD_IGS_CYBER_PRO_800x600_16_BP
if	ALLOW_1Kx768_16
	VESAMode	VM_1Kx768_16	; VD_IGS_CYBER_PRO_1Kx768_16_SP
	VESAMode	VM_1Kx768_16	; VD_IGS_CYBER_PRO_1Kx768_16_BP
endif	; ALLOW_1Kx768_16

else

vesaModeTable	label	VESAMode
	VESAMode	VM_640x480_16		; VD_IGS_CYBER_PRO_640x480_16
	VESAMode	VM_800x600_16		; VD_IGS_CYBER_PRO_800x600_16
if	ALLOW_1Kx768_16
	VESAMode	VM_1Kx768_16		; VD_IGS_CYBER_PRO_1Kx768_16
endif	; ALLOW_1Kx768_16

endif	; ALLOW_BIG_MOUSE_POINTER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  GetVMem: Retrieve the amount of memory on the card
  In:  Nothing
  Out: CL <- 0 = 1 Meg, 1 <- 2 Meg, 2 <- 4 Meg
       AX trashed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0	; Doesn't work, since the hardware reports 2megs on 1meg machine.
GetVMemSize	proc	far
	outb	EXTINDEX, 0x072
	inb	al, EXTDATA
	mov_tr	cl, al
	andnf	cl, 0x3
	ret
GetVMemSize	endp
endif

if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  ReadTVReg: Read a 16-bit value from a TV register.
  In:	dx	= TV register index.
  Out:	ax	= Return a 16-bit value of the TV register.
  Note: TV register read must be two 8-bit read, not a 16-bit read.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadTVReg	proc	near
	uses	ds, si
	.enter

	segmov  ds, 0xb000, si
	mov	si, dx

	call	UnlockTVReg		;

	mov	al, ds:[si]		; valueL =  *(bTVRegBase + index);
	mov	ah, ds:[si+1]		; valueH =  *(bTVRegBase + index +1);

	push	ax
	call	LockTVReg		;
	pop	ax

	.leave
	ret
ReadTVReg	endp
endif	; ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  WriteTVReg: Write a 16-bit value into a TV register.
  In:	dx	= TV register index.
	ax	= 16-bit value to write.
  Out:	None
  Note: TV register write must be a 16-bit write, not two 8-bit write.
	Make sure your compilers handle it correctly.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteTVReg	proc	near
	uses	ds, si, cx
	.enter
	
	segmov	ds, 0xb000, si
	mov	si, dx
	mov_tr	cx, ax

	call	UnlockTVReg		;
	mov	ds:[si], cx
	call	LockTVReg		;

	.leave
	ret
WriteTVReg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  UnlockTVReg: Allow the access to TV registers.
  In: None
  Out: TV register can be accessed.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockTVReg	proc	near

	outb	EXTINDEX, 0x33		;
	mov		al, cs:[bReg33]
	ornf		al, 0x08
	outb	EXTDATA, al		; bReg33|0x08

	outb	EXTINDEX, 0x3C		;
	mov		al, cs:[bReg3C]
	ornf		al, 0x80			
	outb	EXTDATA, al		; bReg3C|0x80

	ret
UnlockTVReg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  LockTVReg: Deny the access to TV registers.
  In: None
  Out: TV register can not be accessed.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockTVReg	proc	near

	outb	EXTINDEX, 0x3C		;
	outb	EXTDATA, cs:[bReg3C]	;

	outb	EXTINDEX, 0x33		;
	outb	EXTDATA, cs:[bReg33]	;

	ret
LockTVReg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   DetectCRT: Determine whether CRT (monitor) is hooked up or not.
   In:	None
   Out: set tvMode = TRUE/FALSE

   Note: 1) This detection needs to be done once only right after InitChip();
	 2) Monitor must be physically connected.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DetectCRT	proc	near

	mov	cs:[tvMode], TRUE
	
	outb	EXTINDEX, 0xBF
	outb	EXTDATA, 0x01		; Banking control

	outb	EXTINDEX, 0xB1
	inb	al, EXTDATA
	andnf	al, 0x40		; if <6>=0, CRT is connected
	jnz	10$

	mov	cs:[tvMode], FALSE
10$:
	outb	EXTINDEX, 0xBF
	outb	EXTDATA, 0x00

	ret
DetectCRT	endp
