
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobPaperPathRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	2/93		Initial revision


DESCRIPTION:
		

	$Id: jobPaperPathRedwood.asm,v 1.1 97/04/18 11:51:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetPaperPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the printer's paper path.
		set margins in PState

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.
		normally these matter - in redwood the paper path is read
		from the gate array.
		al	- PaperInputOptions record (dont care)
		ah	- PaperOutputOptions record (dont care)

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
	mov	es,bp			;es --> PState

	clr	es:[PS_redwoodSpecific].RS_savedErrorStatus
						;init the saved ASF status

	mov	si,offset pr_codes_ASFQuery	;see if an ASF is hooked up.
	call	SendCodeOut			;send the query....
	jc	exit				;(errors out)	
	call	StatusPacketIn			;...and get response from Gate
	jc	exit				;errors out
		;now check the buffer for the ASF bits.
	cmp {word} es:[PS_redwoodSpecific].RS_status.RSB_length,ASF_TEST_ID
	jne	assumeASF
	cmp {word} es:[PS_redwoodSpecific].RS_status.RSB_parameters,ASF_TEST_MANUAL
	jne     assumeASF
		;we have a manual feed arraingement.
	mov	es:[PS_paperInput],MF_MANUAL1 shl offset PIO_MANUAL
	jmp	havePathLoaded
assumeASF:
	mov	es:[PS_paperInput],ASF_TRAY1 shl offset PIO_ASF
	mov	es:[PS_redwoodSpecific].RS_savedErrorStatus,mask PER_ASF
havePathLoaded:
	mov	es:[PS_paperOutput],PS_REVERSE shl offset POO_SORTED
	mov	si, offset PI_marginASF	;set ASF path.. source for margins
	mov	bx,es:[PS_deviceInfo]
	call	MemLock
	mov	ds,ax			;ds:si = source (Info resource).
	mov	di,offset PS_currentMargins	;set dest offset for margins
						;es:di = dest (PState).
	mov	cx,(size PrinterMargins) shr 1	;size of the structure to copy.
	rep movsw
	call	MemUnlock
	mov	cx,es:[PS_customWidth]		;get width of papaer loaded
	sub	cx,(PR_MARGIN_LEFT + PR_MARGIN_RIGHT) ;- margins = live area
	mov	ax,cx				;save away x1
	shl	cx,1				;x2
	shl	cx,1				;x4
	add	cx,ax				;x5 , now in 360ths
	mov	ax,MAX_PRINT_WIDTH		;get max print w in 360ths
	sub	ax,cx				;get the unused area.
	sar	ax,1				;on just the left side.
	mov	es:[PS_redwoodSpecific].RS_xOffset,ax ;store the offset.
	clc
exit:
	.leave
	ret
PrintSetPaperPath	endp
