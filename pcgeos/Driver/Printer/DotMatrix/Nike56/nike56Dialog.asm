COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nike printer driver
FILE:		nike56Dialog.asm

AUTHOR:		Joon Song, Mar 23, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/23/95   	Initial revision


DESCRIPTION:
	This file contains code to evaluate UI for Nike56 printer driver.
		

	$Id: nike56Dialog.asm,v 1.1 97/04/18 11:55:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	UI/uiGetNoMain.asm		;pass no tree for Main box
include	UI/uiGetOptions.asm		;pass tree for Options box
include	UI/uiEval.asm			;call the routine specified in device
					;info resource.


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEvalNikeOptionsUI
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
	Joon	3/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintEvalNikeOptionsUI	proc	near
	tst	dx			;see if we really do anything here.
	jz	exit			;if not, just exit.

	mov	ds, bp			;ds <- PState segment

	cmp	bx, PRINT_UI_EVAL_ROUTINE	;see if eval or stuff...
	jne	stuffUI				;if stuff routine, skip.

	; Evaluate paper path

	push	si
	mov	bx, dx			;handle of the options list tree.
	mov	si, offset NikeOptionsResource:NikeInputList
	call	GetItemGroupSelection
	pop	si
	mov	es:[si].[JP_printerData].[PUID_paperInput], al

	; Evaluate ink saver

	push	si
	mov	si, offset NikeOptionsResource:NikeInkSaverList
	call	GetItemGroupSelection
	pop	si
	andnf	al, mask PPO_INK_SAVER
	andnf	es:[si].[JP_printerData].[NPUID_printOptions], \
					not mask PPO_INK_SAVER
	ornf	es:[si].[JP_printerData].[NPUID_printOptions], al

	; Turn ink saver off for color (high and medium)

	mov	ax, MSG_GEN_SET_USABLE
	cmp	ds:[PS_device], PD_NIKE_IV_PLAIN
	je	setState
	cmp	ds:[PS_device], PD_NIKE_IV_TRANSP
	je	setState
	cmp	ds:[PS_mode], PM_GRAPHICS_LOW_RES
	je	setState
	mov	ax, MSG_GEN_SET_NOT_USABLE
setState:
	mov	si, offset NikeOptionsResource:NikeInkSaverList
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	di
	call	ObjMessage
	jmp	exit

stuffUI:
	; Reset paper path

	clr	cx
	mov	cl, es:[si].[JP_printerData].[PUID_paperInput]

	push	si
	mov	bx, dx			;handle of the options list tree.
	mov	si, offset NikeOptionsResource:NikeInputList
	call	SetItemGroupSelection
	pop	si

	; Reset ink saver

	clr	cx
	mov	cl, es:[si].[JP_printerData].[NPUID_printOptions]
	andnf	cl, mask PPO_INK_SAVER

	mov	si, offset NikeOptionsResource:NikeInkSaverList
	call	SetItemGroupSelection
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

PrintEvalNikeOptionsUI	endp


;==============================================================================
;			NikePaperInputGroupClass
;==============================================================================

idata segment
NikePaperInputGroupClass
idata ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NPIGSetSingleSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set paper feed in BIOS

CALLED BY:	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
PASS:		*ds:si	= NikePaperInputGroupClass object
		ds:di	= NikePaperInputGroupClass instance data
		ds:bx	= NikePaperInputGroupClass object (same as *ds:si)
		es 	= segment of NikePaperInputGroupClass
		ax	= message #
		cx	= current selection
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NPIGSetSingleSelection	method dynamic NikePaperInputGroupClass, 
				MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	push	cx
	mov	di, offset NikePaperInputGroupClass
	call	ObjCallSuperNoLock
	pop	cx

	call	PrWaitForMechanismLow

	mov	ax, PB_SET_PAPER_FEED shl 8	;al = 0 = manual paper feed
	cmp	cx, ASF_TRAY1 shl offset PIO_ASF
	jne	10$
	inc	ax				;al = 1 = automatic paper feed
10$:	call	PrinterBIOS

	ret
NPIGSetSingleSelection	endm
