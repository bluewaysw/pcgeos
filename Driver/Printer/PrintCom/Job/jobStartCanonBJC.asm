COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobStartCanonBJ.asm

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
	jc	done

	;load the paper path variables from the Job Parameters block

	mov	al, es:[PS_jobParams].[JP_printerData].[PUID_paperInput]
	clr	ah
	call	PrintSetPaperPath
	jc	done

	; initialize some info in the PState

	clr	ax
	mov	es:[PS_cursorPos].P_x, ax	; set to 0,0 text
	mov	es:[PS_cursorPos].P_y, ax

	; set init codes (assuming graphic printing)

	mov	si, offset pr_codes_InitPrinter
	call	SendCodeOut
	jc	done

	; set print resolution

	mov	si, offset pr_codes_SetPrintResolution
	call	SendCodeOut
	jc	done

	mov	ax, LOW_RES_X_RES
	mov	bx, LOW_RES_Y_RES
	cmp	es:[PS_mode], PM_GRAPHICS_LOW_RES
	je	setRes
	mov	ax, HI_RES_X_RES
	mov	bx, HI_RES_Y_RES
setRes:
	mov	cl, bh
	call	PrintStreamWriteByte		; write vertRes.high
	mov	cl, bl
	call	PrintStreamWriteByte		; write vertRes.low
	mov	cl, ah
	call	PrintStreamWriteByte		; write horizRes.high
	mov	cl, al
	call	PrintStreamWriteByte		; write horizRes.low

	; set print method (sets print "quality" based on PrintMode)

	mov	si, offset pr_codes_SetPrintingMethod
	call	SendCodeOut	
	jc	done

	mov	cl, CANON_BJC_PRINT_QUALITY_DRAFT
	cmp	es:[PS_mode], PM_GRAPHICS_LOW_RES
	je	setQuality
	mov	cl, CANON_BJC_PRINT_QUALITY_STANDARD
setQuality:
	call	PrintStreamWriteByte
done:
	.leave
	ret
PrintStartJob	endp
