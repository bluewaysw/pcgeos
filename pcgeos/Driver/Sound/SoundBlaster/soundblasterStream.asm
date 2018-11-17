COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS Sound System
MODULE:		Sound Blaster Driver
FILE:		soundblasterStream.asm

AUTHOR:		Todd Stumpf, Nov 11, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/11/92   	Initial revision


DESCRIPTION:
	The sound library assumes all DACs will want to read data out
	of a stream.  For many of the DACs this is infact true.  For
	the SoundBlaster, its "kinda" true.

	These are the routines that manage DMAing from a stream.

	$Id: soundblasterStream.asm,v 1.1 97/04/18 11:57:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
udata		segment
	streamSegment		word
	dataOnStream		word
udata		ends

ResidentCode	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACReadNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification reciepiant routine

CALLED BY:	Stream Driver
PASS:		cx	-> # of bytes to read
		dx	-> stream token (virtual segment)
		bx	-> stream segment

RETURN:		nothing

DESTROYED:	ax, cx (allowed ax, bx, si, di)

SIDE EFFECTS:
		Sets up parameters for next interrupt transfer

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/11/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACReadNotification	proc	far
	pushf
	uses	cx, dx, ds, es
	.enter
	mov	ax, segment dgroup		; ax <- dgroup of driver
	mov	ds, ax				; ds <- dgroup of driver

	;
	;  See if we are being notified that someone wrote something
	;  or just that the threshold has changed?
	tst	cx
	jz	sendAck

	;
	;  determine the largest legal transfer size
	;  for the next interrupt transfer
	mov	ds:[dataOnStream], cx		; save amount available
	mov	ax, ds:[maxTransferSize]	; ax <- upper limit on size
	cmp	ax, cx				; is available more than limit?
	jb	setSize

	mov_tr	ax, cx				; guess so.  Set to max size.
setSize:
	mov	ds:[interruptTransferLength], ax; set next transfer length

	tst	ds:[lastInterruptTransferLength]
	jz	restartTransfer

sendAck:
	mov	ds, bx				; ds <- stream

	;
	;  We want to be notified of every write done by the writer.
	;  But each time this routine gets called, the driver sets
	;  flags that prevent a notification from being sent until
	;  we act on the previous notification.  That is, until we
	;  read something.  To deal with this little problem
	;  we send our own "acknowledgment" by fiddling with the
	;  stream settings.
	; 
	;  Send and "ack"
	;  Reset the reader state.
EC<	tst	ds:[SD_writer.SSD_data].SN_data			>
EC<	jz	setFlags					>
EC<	push	es						>
EC<	mov	es, ds:[SD_writer.SSD_data].SN_data		>
EC<	mov	cx, ds						>
EC<	cmp	es:[SC_position.SSS_stream].SSS_streamSegment,cx >
EC<	ERROR_NE -1						>
EC<	pop	es						>
EC<setFlags:							>

	clr	ds:[SD_reader.SSD_data].SN_ack
	and	ds:[SD_state], not mask SS_RDATA

done::
	.leave
	call	SafePopf			; restore flags
	ret

restartTransfer:
	;
	;  We are re-starting the transfer.  All this requires
	;	is that we send the transfer command and length
	;	and re-enable DMA transfers
	mov	cx, ax				; cx <- interruptTransferLength
	mov	ds:[lastInterruptTransferLength], cx
	mov	ah, ds:[interruptTransferMode]
	call	SBDDACDMANextBlock
	and	ds:[interruptTransferMode], 0feh; nuke reference byte
	jmp	short sendAck
	
SBDDACReadNotification	endp
ResidentCode		ends


