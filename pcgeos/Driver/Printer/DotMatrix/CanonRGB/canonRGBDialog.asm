COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon RGB Print Driver
FILE:		canonRGBDialog.asm

AUTHOR:		David Hunter

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	6/19/2000	Initial revision


DESCRIPTION:
	This file contains code to evaluate UI for the CanonRGB
	print driver

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	UI/uiGetNoMain.asm		;pass no tree for Main box
include	UI/uiGetOptions.asm		;pass tree for Options box
include	UI/uiEval.asm			;call the routine specified in device
					;info resource.


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintEvalOptionsUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to evaluate the data passed in the object tree.

CALLED BY:	PrintCallEvalRoutine

PASS:		bp	= PState segment
		cx	= Handle of the duplicated generic tree
			  displayed in the main print dialog box.
		dx	= Handle of the duplicated generic tree
			  displayed in the options dialog box
		es:si	= Segment holding JobParameters structure
		ax	= Handle of JobParameters block

RETURN:		nothing

DESTROYED:	ax, bx, cx, si, di, es, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
	dhunter	6/19/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintEvalCanonRGBOptionsUI	proc	near
	tst	dx			;see if we really do anything here.
	jz	exit			;if not, just exit.

	mov	ds, bp			;ds <- PState segment

	cmp	bx, PRINT_UI_EVAL_ROUTINE	;see if eval or stuff...
	jne	stuffUI				;if stuff routine, skip.

	; Evaluate paper type

	push	si
	mov	bx, dx			;handle of the options list tree
	mov	si, offset OptionsASF1BinResource:ASF1BinMediaList
	call	GetItemGroupSelection
	pop	si
	mov	es:[si].[JP_printerData].[CPUID_mediaType], al

	; Set constant data (borrowed from PrintEvalDummyASF)
        mov     es:[si].[JP_printerData].[PUID_paperInput], ASF_TRAY1 shl \
(offset PIO_ASF)
        mov     es:[si].[JP_printerData].[PUID_paperOutput],NULL
        mov     es:[si].[JP_printerData].[PUID_countryCode],PCC_USA
        mov     es:[si].[JP_printerData].[PUID_symbolSet],PSS_IBM437

	jmp	exit

stuffUI:
	; Reset paper type

	clr	cx
	mov	cl, es:[si].[JP_printerData].[CPUID_mediaType]
;	push	si
	mov	bx, dx			;handle of the options list tree
	mov	si, offset OptionsASF1BinResource:ASF1BinMediaList
	call	SetItemGroupSelection
;	pop	si
exit:
	ret

GetItemGroupSelection label near
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	retn

SetItemGroupSelection label near
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	di, mask MF_CALL
	call	ObjMessage
	retn

PrintEvalCanonRGBOptionsUI	endp
