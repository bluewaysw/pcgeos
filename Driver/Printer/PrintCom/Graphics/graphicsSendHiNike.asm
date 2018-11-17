COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		NIKE 56-pin print drivers
FILE:		graphicsSendHiNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	12/94		Initial revision


DESCRIPTION:

	$Id: graphicsSendHiNike.asm,v 1.1 97/04/18 11:51:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendTheBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Used to print a 50 pin High resolution band. (non-interleaved)
	Usually used to print a 300dpi resolution band.

CALLED BY:
	PrPrintHiBand

PASS:
	ds:si	=	buffer structure.
	es	=	segment of PState

RETURN:

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	12/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrSendTheBand	proc	near
curBand local   BandVariables
	uses	ax,bx,cx,dx,di,si
	.enter inherit

		;Move the printhead down to the next band on the page.

	clr	dx
	xchg	dx, es:[PS_dWP_Specific].DWPS_yOffset
	call	PrLineFeed		;start in the right place.
	jc	exit

	call	PrWaitForMechanismLow	;wait for the linefeed to happen.
	jc	exit			;propogate errors out.

		;Now we get the particulars for this buffer from the structure
		;at the front of the buffer, and load the proper registers for
		;the two calls to send the data to the print head.

	push	es, bp
	mov	ah, PB_SET_PRINT_AREA
	mov	al, es:[printOptions]
	and	al, mask PPO_UNI_DIR
	mov	cl, offset PPO_UNI_DIR
	shr	al, cl
	mov	bx, ds:[si].GPB_startColumn
	mov	cx, ds:[si].GPB_endColumn
	mov	dx, ds			;segment for rotated and merged buffer
	add	si, offset GPB_bandBuffer	;offset of rotated buffer
	mov	bp, es:[PS_dWP_Specific].DWPS_shinglingPrint
	mov	di, PRINT_DMA_BUFFER_SEGMENT
	mov	es, di
	clr	di			;es:di = DMA buffer
	call	PrinterBIOS		;set the print area and start the DMA
	pop	es, bp
	jc	exit			;propogate errors out.

	call	PrWaitForMechanismLow	;wait for PB_SET_PRINT_AREA to finish
	jc	exit			;propogate errors out.

	mov	ah, PB_PRINT_SWATH
	mov	al, es:[printOptions]
	and	al, mask PPO_INK_SAVER
	mov	cl, offset PPO_INK_SAVER
	shr	al, cl
	call	PrinterBIOS		;carry set if error
exit:
	.leave
	ret
PrSendTheBand	endp
