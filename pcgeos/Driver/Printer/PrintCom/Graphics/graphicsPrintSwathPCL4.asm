
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		graphicsPrintSwathPCL4.asm

AUTHOR:		Dave Durran January 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial laserjet revision
	Dave	1/21/92		2.0 PCL 4 driver revision


DESCRIPTION:

	$Id: graphicsPrintSwathPCL4.asm,v 1.1 97/04/18 11:51:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap using the appropriate algorythm for 
		the amount of free memory installed in the LaserJet.

CALLED BY:	PrintSwath

PASS:		bp	- PState segment
		dx.cx	- VM file and block handle for Huge bitmap

RETURN:		carry	-set if some communications error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSwath	proc	far
	uses	ax,bx,cx,dx,si,di,ds,es
	mov	es, bp			; es -> PState
	.enter


		; load the bitmap header into the PState
	call    LoadSwathHeader         ; bitmap header into PS_swath

		; load up the band width and height
	call    PrLoadPstateVars        ;set up the pstate band Vars.

	clr	ax			;set color number to zero (monochrome)
	mov	es:[PS_curColorNumber],ax

		;check the resolution we are printing in, and set it in printer.
	clr	ah
	mov	al, es:[PS_mode]	; get the mode
EC<	cmp	ax,PM_FIRST_TEXT_MODE				>
EC<	ERROR_AE	INVALID_MODE				>
	mov	si,ax			;use as index
	mov	ax,cs:[si]+offset pr_graphic_Res_Values
	mov	di,offset pr_codes_SetGraphicRes
	call	WriteNumCommand	
	jc	exit

		;routine to see how much memory is in the printer, and steer
		;to the proper graphics routine.
	clr	al			;init the memory variable.
	mov	ah,PM_GRAPHICS_HI_RES   ;init the mode.
	sub	ah,es:[PS_mode]
	shr	ah,1			;divide / 2 for 1 byte step.
	shr	ax,1			;get into BBFixed format.
	add	ax,es:[PS_jobParams].[JP_printerData].[PUID_amountMemory]
	add	ax,80h			;round fractional meg up to next.
	clr	al			;get into an integer,
	xchg	al,ah			;we dont care about .5 M increments.
	dec	ax			;zero is .5 and 1Meg.
	cmp	ax,4 			;we only care about the first 4Meg
	jb	memCorrected
	mov	ax,offset PrSendBitmap	;we have oodles of memory, just blow
					; the bitmap out.
	jmp	callTheSendRoutine

memCorrected:
	sal	ax,1			;word pointer.....
	mov	si,ax			;into index reg.
	mov	al,es:[PS_jobParams].[JP_printerData].[PUID_initMemory]
	inc	al			;get to 0,1,or 2 , 0 = do nothing
					;1 = trash all, 2 = trash temp only
	sal	ax,1			;get into hi 2 bits of index.
	sal	ax,1			;2 bits of memory info,
	sal	ax,1			;+ 1 bit for word pointer.
	or	si,ax			;add into index for call.
	mov	ax,cs:[si]+offset printMethods

callTheSendRoutine:
	call	ax		

exit:
        call    HugeArrayUnlock         ;get rid of last locked block in
                                        ;huge array.
	.leave
	ret
PrintSwath	endp

printMethods	nptr.near\
	PrSendBitmapCompressed,	;0.5M-1.0M, all fonts remain.\
	PrSendBitmapCompressed,	;1.5M-2.0M, all fonts remain.\
	PrSendBitmapCompressed,	;2.5M-3.0M, all fonts remain.\
	PrSendBitmap,		;3.5M-4.0M-UP, all fonts remain.\
	PrSendBitmapCompressed,	;0.5M-1.0M, all fonts deleted.\
	PrSendBitmap,		;1.5M-2.0M, all fonts deleted.\
	PrSendBitmap,		;2.5M-3.0M, all fonts deleted.\
	PrSendBitmap,		;3.5M-4.0M-UP, all fonts deleted.\
	PrSendBitmapCompressed,	;0.5M-1.0M, temporary fonts deleted.\
	PrSendBitmapCompressed,	;1.5M-2.0M, temporary fonts deleted.\
	PrSendBitmap,		;2.5M-3.0M, temporary fonts deleted.\
	PrSendBitmap		;3.5M-4.0M-UP, temporary fonts deleted.


