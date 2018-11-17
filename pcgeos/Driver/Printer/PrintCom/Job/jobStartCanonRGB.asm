COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobStartCanonRGB.asm

AUTHOR:		Joon Song, 9 Jan 1999

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/99		Initial revision from jobStartDotMatrix.asm


DESCRIPTION:
		

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do pre-job initialization

CALLED BY:	GLOBAL

PASS:		bp	- segment of locked PState
		dx:si	- Job Parameters block
		
RETURN:		carry	- set if some communication problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/99		Initial version from jobStartDotMatrix.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintStartJob	proc	far
	uses	ax,bx,cx,dx,si,di,es
	.enter

	mov	es, bp			;point at PState.

	mov	bx, es:PS_deviceInfo	;get the device specific info.
	call	MemLock
	mov	ds, ax			;segment into ds.
	mov	al, ds:PI_type		;get the printer smarts field.
	mov	ah, ds:PI_smarts		;get the printer smarts field.
	mov	{word}es:PS_printerType,ax	;set both in PState.
	mov	ax, ds:PI_customEntry	;get address of any custom routine.
	call	MemUnlock

	tst	ax			;see if a custom routine exists.
	jz	useStandard		;if not, skip to use standard init.
	jmp	ax			;else jmp to the custom routine.
					;(It had better jump back here to
					;somwhere in this routine or else
					;things will get ugly on return).
useStandard:
        call    PrintResetPrinterAndWait	;init the printer hardware
LONG	jc	done

	;load the paper path variables from the Job Parameters block

	mov	al, es:[PS_jobParams].[JP_printerData].[PUID_paperInput]
	clr	ah
	call	PrintSetPaperPath
LONG	jc	done

	; initialize some info in the PState

	clr	ax
	mov	es:[PS_cursorPos].P_x, ax	; set to 0,0 text
	mov	es:[PS_cursorPos].P_y, ax

	; set init codes (assuming graphic printing)

	mov	si, offset pr_codes_InitPrinter
	call	SendCodeOut
LONG	jc	done

	; set print resolution - usually 360x360 except mono-low-res
	; and mono-mid-res (180x180)

	mov	si, offset pr_codes_SetPrintResolution
	call	SendCodeOut
LONG	jc	done

	mov	ax, HI_RES_RASTER_X_RES
	mov	bx, HI_RES_RASTER_Y_RES
	clr	dx				; dx = clear = 360 DPI
	mov	cl, es:[PS_printerType]
	andnf	cl, mask PT_COLOR
	cmp	cl, BMF_MONO
	jne	setRes
	cmp	es:[PS_mode], PM_GRAPHICS_HI_RES
	je	setRes
	mov	ax, LOW_RES_MONO_X_RES
	mov	bx, LOW_RES_MONO_Y_RES
	inc	dx				; dx <- set = 180 DPI
setRes:
	mov	cl, bh
	call	PrintStreamWriteByte		; write vertRes.high
	mov	cl, bl
	call	PrintStreamWriteByte		; write vertRes.low
	mov	cl, ah
	call	PrintStreamWriteByte		; write horizRes.high
	mov	cl, al
	call	PrintStreamWriteByte		; write horizRes.low

	; set print method
	;
	; Print quality defaults to standard. If the media type is not
	; plain, envelope, or banner paper, print quality is set high.
	; (This rule is a must for proper print control using dither
	; [fast] halftoning).

	mov	si, offset pr_codes_SetPrintingMethod
	call	SendCodeOut	
LONG	jc	done

	mov	al, es:[PS_jobParams].[JP_printerData].[CPUID_mediaType]
;;	mov	cl, CANON_BJC_PRINT_QUALITY_DRAFT
;;	cmp	es:[PS_mode], PM_GRAPHICS_LOW_RES
;;	je	setQuality
	mov	cl, CANON_BJC_PRINT_QUALITY_STANDARD	; quality = standard
;; setQuality:
	cmp	al, CANON_BJC_MEDIA_TYPE_BANNER_PAPER
	ja	invalidMedia		; use zero as default if media invalid
	je	gotQuality		; banner paper uses standard quality
	cmp	al, CANON_BJC_MEDIA_TYPE_PLAIN_PAPER
	je	gotQuality		; so does plain paper
	cmp	al, CANON_BJC_MEDIA_TYPE_ENVELOPES
	je	gotQuality		; and envelope paper
	cmp	al, CANON_BJC_MEDIA_TYPE_OTHER
	je	gotQuality		; and other paper (why not?)
	mov	cl, CANON_BJC_PRINT_QUALITY_HIGH	; but, everyone else
gotQuality:						; uses high quality
	clr	ah
	mov	si, ax			; si <- offset into media table
	ornf	cl, cs:[printMediaTable][si]	; media goes in upper nibble
invalidMedia:
	call	PrintStreamWriteByte

	; set page margins (all values specified in multiples of 1/60")

	mov	si, offset pr_codes_SetPageMargins
	call	SendCodeOut
	jc	done

	BranchIfBannerMode	bannerMode
	mov	ax, es:[PS_customHeight]	; write page length
	sub	ax, PR_MARGIN_TOP + PR_MARGIN_BOTTOM
	call	PSJConvertAndOutputLength
	jmp	leftMargin

	; In banner mode, we must ensure that the page length set here
	; results in a total raster count that is a multiple of 8.  So,
	; we pick a constant length that just happens to have this property.
	; We also store the raster count per page at this point.
bannerMode:
	mov	ax, BANNER_MODE_HI_RES_PAGE_LENGTH	; assume 360 DPI
	mov	bx, BANNER_MODE_HI_RES_RASTER_COUNT
	tst	dx				; printing 360 DPI?
	jz	setBannerMargin			; branch if so
	mov	ax, BANNER_MODE_LOW_RES_PAGE_LENGTH	; nope, use 180 DPI
	mov	bx, BANNER_MODE_LOW_RES_RASTER_COUNT
setBannerMargin:
	mov	es:[PS_jobParams].[JP_printerData].[CPUID_rasterCount], bx
	mov	cl, ah
	call	PrintStreamWriteByte		; - high byte
	mov	cl, al
	call	PrintStreamWriteByte		; - low byt
leftMargin:
	clr	ax				; write zero left margin
	mov	cl, ah
	call	PrintStreamWriteByte		; - high byte
	mov	cl, al
	call	PrintStreamWriteByte		; - low byte
	mov	ax, es:[PS_customWidth]		; write right margin
	sub	ax, PR_MARGIN_LEFT + PR_MARGIN_RIGHT
	call	PSJConvertAndOutputLength
	mov	ax, PR_LEFT_MARGIN_OFFSET	; write offset
	mov	cl, ah
	call	PrintStreamWriteByte		; - high byte
	mov	cl, al
	call	PrintStreamWriteByte		; - low byte

	; Set print media loading.  This command may set banner mode,
	; so it must be the last control command sent before raster data,
	; as the printer will ignore any further controls until the
	; reset command (ESC @) is sent.

	mov	si, offset pr_codes_SetPrintMediaLoading
	call	SendCodeOut
	jc	done

	mov	cl, (CANON_BJC_PRINTER_MODEL_ID shl 4) \
		or CANON_BJC_MEDIA_SOURCE_ASF1
	call	PrintStreamWriteByte		; write Model_ID
	mov	al, es:[PS_jobParams].[JP_printerData].[CPUID_mediaType]
	mov	cl, 4
	shl	al, cl				; media goes in upper nibble
	mov	cl, al
	call	PrintStreamWriteByte		; write media type

	; initialize color library

	call	CMYKColorLibInitialize
	clc	
done:
	.leave
	ret

; Each Media Type passed in the SetPrintMediaLoading command has a matching
; Print Media constant passed in the SetPrintingMethod command.  The Media
; Type is set in the job printer data, while the Print Media is looked up
; in this table.  All values are shifted into the upper nibble as per the
; command format.

printMediaTable	byte	CANON_BJC_PRINT_MEDIA_PLAIN_PAPER shl 4, \
			0, \
			CANON_BJC_PRINT_MEDIA_TRANSPARENCIES shl 4, \
			CANON_BJC_PRINT_MEDIA_BACK_PRINT_FILM shl 4, \
			0, \
			0, \
			CANON_BJC_PRINT_MEDIA_GLOSSY_PAPER shl 4, \
			CANON_BJC_PRINT_MEDIA_HIGH_GLOSS_FILM shl 4, \
			CANON_BJC_PRINT_MEDIA_ENVELOPES shl 4, \
			CANON_BJC_PRINT_MEDIA_OTHER shl 4, \
			0, \
			CANON_BJC_PRINT_MEDIA_HIGH_RES_PAPER shl 4, \
			CANON_BJC_PRINT_MEDIA_GLOSSY_CARDS shl 4, \
			CANON_BJC_PRINT_MEDIA_BANNER_PAPER shl 4

PrintStartJob	endp

;
; Utility routine to convert a length in ax in points (1/72") to 
; a multiple of 1/60" and write it to the device.
;
PSJConvertAndOutputLength	proc	near
	clr	dx
	mov	cx, 5				; pts (1/72") -> 1/60"
	mul	cx
	mov	cx, 6
	div	cx
	mov	cl, ah
	call	PrintStreamWriteByte		; write high byte
	mov	cl, al
	call	PrintStreamWriteByte		; write low byte
	ret
PSJConvertAndOutputLength	endp
