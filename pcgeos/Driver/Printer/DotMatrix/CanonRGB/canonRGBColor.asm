COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Canon RGB Printer Driver
FILE:		canonRGBColor.asm

AUTHOR:		Joon Song, Feb 09, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	2/09/99   	Initial revision


DESCRIPTION:
		
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKColorLibInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize RGB to CMYK Conversion Library

CALLED BY:	VidInit
PASS:		es	= PState segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	2/08/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMYKColorLibInitialize	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter

		mov	bl, es:[PS_printerType]
		andnf	bl, mask PT_COLOR
		cmp	bl, BMF_MONO
		LONG je	done

		mov	ax, size CLInfo
		mov	cx, ALLOC_FIXED or (mask HAF_NO_ERR shl 8)
		call	MemAlloc
		
		mov	es:[PS_jobParams][JP_printerData][CPUID_clInfo], bx
		call	MemDerefDS

	; Initialize rgbToCmykInfo structure

		cmp	es:[PS_device], PD_CANON_BJC2000
		je	bjc2000
		cmp	es:[PS_device], PD_CANON_BJC2100
		je	bjc2000
		cmp	es:[PS_device], PD_GLOBALPC_BJC2120
		je	bjc2000
		cmp	es:[PS_device], PD_GLOBALPC_BJC2120_MONO
		je	bjc2000
		cmp	es:[PS_device], PD_GLOBALPC_BJC2112
		je	bjc2000
		cmp	es:[PS_device], PD_GLOBALPC_BJC2112_MONO
		je	bjc2000
EC <		cmp	es:[PS_device], PD_CANON_BJC1000_COLOR		>
EC <		ERROR_NE CANON_RGB_UNEXPECTED_DEVICE			>

		push	BJD_PM_BJC1000
		call	CLGetPrinterModel
		add	sp, 2
		mov	ds:[fPrintType], ax

		push	BJD_IT_BC05
		call	CLGetInkType
		add	sp, 2
		mov	ds:[fInkSystemType], ax
		jmp	setPaper
bjc2000:
		push	BJD_PM_BJC2000
		call	CLGetPrinterModel
		add	sp, 2
		mov	ds:[fPrintType], ax

		push	BJD_IT_BC21
		call	CLGetInkType
		add	sp, 2
		mov	ds:[fInkSystemType], ax
setPaper:
		push	BJD_MT_PLAINPAPER
		call	CLGetMediaType
		add	sp, 2
		mov	ds:[fMediaType], ax

		mov	ds:[fUseDither], USE_DITHER
		mov	ds:[fBitsPerPixel], 24

		mov	ax, LOW_RES_X_RES
		cmp	es:[PS_mode], PM_GRAPHICS_LOW_RES
		je	gotRes
		mov	ax, MED_RES_X_RES
		cmp	es:[PS_mode], PM_GRAPHICS_MED_RES
		je	gotRes
		mov	ax, HI_RES_X_RES
;		mov	ds:[fBitsPerPixel], 8	; use 8-bit color for hi-res
gotRes:
		mov	ds:[fRGBResolution], ax
		mul	es:[PS_customWidth]	; dx:ax = paperWidth * res
		mov	cx, 72
		div	cx			; ax = paperWidth * res / 72
		mov	ds:[fRGBLineWidth], ax
		mov	ds:[fRGBWidthPixel], ax

		push	es
		push	ds
		push	0
		call	CLInitialize
		add	sp, 4
EC <		cmp	ax, CL_ERROR					>
EC <		ERROR_E	CANON_RGB_CANON_LIBRARY_INTERNAL_ERROR		>
		pop	es

	; Allocate memory for RGB to CMYK conversion library

		mov	ax, ds:[fRGBBufferSize]
		add	ax, ds:[fCMMBufferSize].low
EC <		ERROR_C	CANON_RGB_COLOR_BUFFER_OVERFLOW			>
		add	ax, ds:[fCMYKBufferSize][0]
EC <		ERROR_C	CANON_RGB_COLOR_BUFFER_OVERFLOW			>
		add	ax, ds:[fCMYKBufferSize][2]
EC <		ERROR_C	CANON_RGB_COLOR_BUFFER_OVERFLOW			>
		add	ax, ds:[fCMYKBufferSize][4]
EC <		ERROR_C	CANON_RGB_COLOR_BUFFER_OVERFLOW			>
		add	ax, ds:[fCMYKBufferSize][6]
EC <		ERROR_C	CANON_RGB_COLOR_BUFFER_OVERFLOW			>

	; According to Joon, the original author of this code,
	; these buffers should not be needed by the final version
	; of the rgb2cmyk library, but after stepping through the
	; initialization routines in that library it is clear that
	; these buffers are accessed. -Don 10/1/99
;;;if (not USE_DITHER)
		add	ax, ds:[fEDBufferSize][0]
EC <		ERROR_C	CANON_RGB_COLOR_BUFFER_OVERFLOW			>
		add	ax, ds:[fEDBufferSize][2]
EC <		ERROR_C	CANON_RGB_COLOR_BUFFER_OVERFLOW			>
		add	ax, ds:[fEDBufferSize][4]
EC <		ERROR_C	CANON_RGB_COLOR_BUFFER_OVERFLOW			>
		add	ax, ds:[fEDBufferSize][6]
EC <		ERROR_C	CANON_RGB_COLOR_BUFFER_OVERFLOW			>
;;;endif
		mov	cx, ALLOC_DYNAMIC_NO_ERR
		call	MemAlloc
		mov	es:[PS_jobParams][JP_printerData][CPUID_dataBuffer], bx

	; Start color conversion

		call	CMYKColorLibLockBuffers

		push	es
		push	ds
		push	0
		call	CLStart
		add	sp, 4
EC <		cmp	ax, CL_ERROR					>
EC <		ERROR_E	CANON_RGB_CANON_LIBRARY_INTERNAL_ERROR		>
		pop	es

		call	CMYKColorLibUnlockBuffers
done:		
		.leave
		ret
CMYKColorLibInitialize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKColorLibEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End

CALLED BY:	PrintEndJob
PASS:		es	= PState segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	2/09/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMYKColorLibEnd	proc	near
		uses	bx
		.enter

		mov	bl, es:[PS_printerType]
		andnf	bl, mask PT_COLOR
		cmp	bl, BMF_MONO
		je	done

		clr	bx
		xchg	bx, es:[PS_jobParams][JP_printerData][CPUID_clInfo]
		call	MemFree

		clr	bx
		xchg	bx, es:[PS_jobParams][JP_printerData][CPUID_dataBuffer]
		call	MemFree
done:
		.leave
		ret
CMYKColorLibEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKColorLibLockBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock all RGB->CMYK conversion buffers

CALLED BY:	INTERNAL
PASS:		es	= PState segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	2/08/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMYKColorLibLockBuffers	proc	near
		uses	ax,bx,dx,ds
		.enter

		mov	bl, es:[PS_printerType]
		andnf	bl, mask PT_COLOR
		cmp	bl, BMF_MONO
		LONG je	done

		mov	bx, es:[PS_jobParams][JP_printerData][CPUID_clInfo]
		call	MemDerefDS

	; Set data pointers to data buffer

		mov	bx, es:[PS_jobParams][JP_printerData][CPUID_dataBuffer]
		call	MemLock
		clr	dx
		movdw	ds:[fRGBBufferPtr], axdx
		add	dx, ds:[fRGBBufferSize]
		movdw	ds:[fCMMBufferPtr], axdx
		add	dx, ds:[fCMMBufferSize].low
		movdw	ds:[fCMYKBufferPtr][0], axdx
		add	dx, ds:[fCMYKBufferSize][0]
		movdw	ds:[fCMYKBufferPtr][4], axdx
		add	dx, ds:[fCMYKBufferSize][2]
		movdw	ds:[fCMYKBufferPtr][8], axdx
		add	dx, ds:[fCMYKBufferSize][4]
		movdw	ds:[fCMYKBufferPtr][12], axdx

	; According to Joon, the original author of this code,
	; these buffers should not be needed by the final version
	; of the rgb2cmyk library, but after stepping through the
	; initialization routines in that library it is clear that
	; these buffers are accessed. -Don 10/1/99
;;;if (not USE_DITHER)
		add	dx, ds:[fCMYKBufferSize][6]
		movdw	ds:[fEDBufferPtr][0], axdx
		add	dx, ds:[fEDBufferSize][0]
		movdw	ds:[fEDBufferPtr][4], axdx
		add	dx, ds:[fEDBufferSize][2]
		movdw	ds:[fEDBufferPtr][8], axdx
		add	dx, ds:[fEDBufferSize][4]
		movdw	ds:[fEDBufferPtr][12], axdx
;;;endif
done:
		.leave
		ret
CMYKColorLibLockBuffers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKColorLibUnlockBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock all RGB->CMYK conversion buffers

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	2/08/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMYKColorLibUnlockBuffers	proc	near
		uses	ax, bx, ds
		.enter

		mov	bl, es:[PS_printerType]
		andnf	bl, mask PT_COLOR
		cmp	bl, BMF_MONO
		LONG_EC je	done

EC <		mov	bx, es:[PS_jobParams][JP_printerData][CPUID_clInfo] >
EC <		call	MemDerefDS					    >

EC <		clrdw	ds:[fRGBBufferPtr]				    >
EC <		clrdw	ds:[fCMMBufferPtr]				    >
EC <		clrdw	ds:[fCMYKBufferPtr][0]				    >
EC <		clrdw	ds:[fCMYKBufferPtr][4]				    >
EC <		clrdw	ds:[fCMYKBufferPtr][8]				    >
EC <		clrdw	ds:[fCMYKBufferPtr][12]				    >
EC <		clrdw	ds:[fEDBufferPtr][0]				    >
EC <		clrdw	ds:[fEDBufferPtr][4]				    >
EC <		clrdw	ds:[fEDBufferPtr][8]				    >
EC <		clrdw	ds:[fEDBufferPtr][12]				    >

		mov	bx, es:[PS_jobParams][JP_printerData][CPUID_dataBuffer]
		call	MemUnlock
done:
		.leave
		ret
CMYKColorLibUnlockBuffers	endp
