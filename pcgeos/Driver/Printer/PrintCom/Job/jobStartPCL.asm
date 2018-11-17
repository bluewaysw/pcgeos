
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobStartPCL.asm

AUTHOR:		Dave Durran, 8 March 1990

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision from laserdwnSetup.asm
	Dave	5/92		Parsed from pcl4Setup.asm


DESCRIPTION:
	This file contains various setup routines needed by most PCL4 print 
	drivers.
		

	$Id: jobStartPCL.asm,v 1.1 97/04/18 11:51:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do pre-job initialization

CALLED BY:	GLOBAL

PASS:		bp	- segment of locked PState
		
RETURN:		carry	- set if some communication problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version
	Dave	10/94		Added initialization for the FE_styles
				and FE_stylesSet fields.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintStartJob	proc	far
	uses	ax,bx,cx,dx,si,di,es
	.enter

	mov	es, bp

	mov	bx,es:PS_deviceInfo	;get the device specific info.
	call	MemLock
	mov	ds,ax			;segment into ds.
	mov	al,ds:PI_type		;get the printer type field.
	mov	ah,ds:PI_smarts		;get the printer smarts field.
	mov {word} es:PS_printerType,ax ;set both in PState.
	mov	ax,ds:PI_customEntry	;get address of any custom routine.
	call	MemUnlock

	test	ax,ax			;see if a custom routine exists.
	je	useStandard		;if not, skip to use standard init.
	jmp	ax			;else jmp to the custom routine.
					;(It had better jump back here to
					;somwhere in this routine or else
					;things will get ugly on return).

useStandard:
	clc				;start off with no problems


BeginInit	label	near
	jc	errorStage
		; initialize the printer

	mov	si,offset pr_codes_ResetPrinter
	call	SendCodeOut
	jc	errorStage

InitPState	label	near
		; initialize some info in the PState
ifdef	PCL4MODE
		;first, check for multiple copies, and non-collated.
	test	es:[PS_jobParams].JP_spoolOpts,mask SO_COLLATE
	jz	setMultCopies
	mov	ax,1
	jmp	setCopies
setMultCopies:
		;works for up to 99 copies only!
	mov	al,es:[PS_jobParams].JP_numCopies ;value to set in printer.
	clr	ah
	mov	es:[PS_jobParams].JP_numCopies,1 ;set the PState to one pass
setCopies:
	call	PrintSetCopies		;set the # copies in the printer.
	jc	errorStage
endif

	clr	ax
	mov	es:[PS_asciiSpacing], 12	; set to 1/6th inch
	mov	es:[PS_asciiStyle], ax		; set to plain text
	mov	es:[PS_cursorPos].P_x, ax	; set to 0,0 text
	mov	es:[PS_cursorPos].P_y, ax
	mov     es:[PS_curFont].FE_stylesSet, ax
	not	ax				;now $ffff
	mov	es:[PS_previousAttribute],ax
	mov     es:[PS_curFont].FE_styles, ax

		;Initialize the default symbol set for internal fonts.
	call	PrintSetSymbolSet		;set in PState
	call	PrintLoadSymbolSet		;set up translation table

                ; Initialize the paper path.

                ;load the paper path variables from the Job Parameters block

        mov     ah,es:[PS_jobParams].[JP_printerData].[PUID_paperOutput]
        mov     al,es:[PS_jobParams].[JP_printerData].[PUID_paperInput]
        call    PrintSetPaperPath


ifdef	PCL4MODE
		
;This code is for the version that uses characters across page boundaries.
		; initialize the font
;	cmp	es:PS_mode,PM_FIRST_TEXT_MODE
;	jb	afterInit
;	call	PrInitFont
;afterInit:
endif


		;init the line spacing, and page length.

	mov	si,offset pr_codes_InitPrinter
	call	SendCodeOut
errorStage:
	jc	exitErr

ifdef	PCL4MODE
	mov	al,es:[PS_jobParams].[JP_printerData].[PUID_initMemory]
	cmp	al,HPFC_DELETE_TEMP_SOFT_FONTS	;make sure that we dont screw
	ja	InitPageSize		 ;up by doing some unknown operation.
	mov	di,offset pr_codes_FontControl
	call	WriteNumByteCommand
	jc	exitErr
	add	al,6
	mov	di,offset pr_codes_MacroControl
	call	WriteNumByteCommand
	jc	exitErr
endif
InitPageSize	label	near

		;page length....
		
ifdef	PCL4MODE
		;for laserjets: do not set the paper size if there is an
		;envelope in the printer - let the user determine paper type
		;from the front panel.
	test	es:[PS_jobParams].JP_paperSizeInfo.PSR_layout, PT_ENVELOPE
	clc			;force no error
	jnz	exitErr
endif

	mov	si,offset pr_codes_SetPageLength
	call	SendCodeOut
	jc	exitErr

	;
	; Determine the page length by converting the current size
	; (in pixels) to the page-length units in PCL (1/8"). As of
	; 1/30/95, we round the page length up (instead of truncating),
	; as this allows us to print to the edge of the paper when
 	; using A4 paper (for DeskJet only) -DLR.
	;

	clr	dx		;init for conversion.
	mov	ax,es:PS_customHeight	;get the paper size in points.
	mov	cx,9			;convert to 1/8" units.
	div	cx		;no rounding, as we want to err <...
ifndef	PCL4MODE
	tst	dx
	jz	checkForMax
	inc	ax
checkForMax:
endif
	mov	dx,112		;max value for legal size.
	cmp	dx,ax		;range check.
	jg	defaultLength
	mov	ax,dx		;get in ax for Hex routine.

defaultLength:
	call	HexToAsciiStreamWrite
	jc	exitErr
	mov	es,bp
	mov	si,offset pr_codes_MidPageLength
	call	SendCodeOut
	jc	exitErr
	sub	ax,4	;2 line top margin, 2 line bottom margin.
	call	HexToAsciiStreamWrite
	jc	exitErr
	mov	si,offset pr_codes_FinishPageLength
	call	SendCodeOut

exitErr:
	.leave
	ret
PrintStartJob	endp
