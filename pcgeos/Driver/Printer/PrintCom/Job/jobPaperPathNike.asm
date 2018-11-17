
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobPaperPathNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	10/94		Initial revision


DESCRIPTION:
		

	$Id: jobPaperPathNike.asm,v 1.1 97/04/18 11:51:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetPaperPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the printer's paper path.
		set margins in PState

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		al	- PaperInputOptions record
		ah	- PaperOutputOptions record (ignored)

RETURN:		carry set if some transmission error.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This routine takes the record for the Paper input and output options
	and loads the Pstate and sets the printer up accordingly. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
PrintSetPaperPath	proc	far
	uses	ax,bx,cx,dx,si,di,es,ds
	.enter
	mov	es, bp			;es --> PState
	call	PrWaitForMechanismLow	;just to be safe
	jc	exit

EC <	cmp	al, ASF_TRAY1 shl offset PIO_ASF			>
EC <	je	inputOK							>
EC <	cmp	al, MF_MANUAL1 shl offset PIO_MANUAL			>
EC <	ERROR_NE -1			;bad PaperInputOptions		>
EC <inputOK:								>

	mov	es:[PS_paperInput], al
	mov	es:[PS_paperOutput], PS_REVERSE shl offset POO_SORTED

	cmp	al, ASF_TRAY1 shl offset PIO_ASF
	mov	al, 0			;manual = 0
	jne	setPaperFeed
	inc	al			;automatic cut sheet = 1

setPaperFeed:
	mov	ah, PB_SET_PAPER_FEED
	call	PrinterBIOS

	; Set printer margins
	mov	si, offset PI_marginASF	;set ASF path.. source for margins
	mov	bx, es:[PS_deviceInfo]
	call	MemLock
	mov	ds, ax			;ds:si = source (Info resource).
	mov	di, offset PS_currentMargins	;set dest offset for margins
						;es:di = dest (PState).
	mov	cx, (size PrinterMargins) shr 1	;size of the structure to copy.
	rep	movsw
	call	MemUnlock
	mov	dx, es:[PS_customWidth]		;get width of papaer loaded
	sub	dx, (PR_MARGIN_LEFT + PR_MARGIN_RIGHT) ;- margins = live area
	clr	ax
	call	PrConvertToDriverXCoordinates
	mov	ax, MAX_PRINT_WIDTH		;get max print w in 50ths
	sub	ax, dx				;get the unused area.
	sar	ax, 1				;on just the left side.
	mov	es:[PS_dWP_Specific].DWPS_xOffset, ax	;store the offset.
	clc
exit:
	.leave
	ret
PrintSetPaperPath	endp
