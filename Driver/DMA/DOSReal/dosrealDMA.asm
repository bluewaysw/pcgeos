COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS	
MODULE:		DMA Driver for DOS-Real Mode systems
FILE:		dosrealDMA.asm

AUTHOR:		Todd Stumpf, Oct 13, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/13/92		Initial revision


DESCRIPTION:
	The actual DMA code for the driver.
		

	$Id: dosrealDMA.asm,v 1.1 97/04/18 11:44:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
udata		segment
	;
	;  On PC, only channels 1, 2, and 3 are available as channel 0
	;  is used as the memory re-fresh.
	;
	;  On the AT, channel 0 is available, as is channl 5, 6 and 7
	; 
	;  Channel four is never available, as it is either non-existant
	;  on the PC, or used to cascade the second chip on the AT.
	;
	channelUsage		byte	; mask of channels given to clients

	runningOnAt		byte	; are we on an AT?
udata		ends

ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMADoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dummy Routines for unsuported functions

CALLED BY:	Strategy Routine
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMADoNothing	proc	near
	ret
DOSRDMADoNothing	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMARequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acquire the single user resource channel

CALLED BY:	Strategy Routine
PASS:		dl	-> mask of channels requested

RETURN:		dl	<- mask of channels not granted

DESTROYED:	nothing
SIDE EFFECTS:	
		could change channel mask

PSEUDO CODE/STRATEGY:
		and together old mask and requested channels.
		if zero, that means we can grant the request,
			if non-zero that means a requested channel
			has already been grabbed.
		if zero, or together old and new mask to reflect change
			and save mask.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMARequest	proc	near
	uses	ax,ds
	.enter
	mov	ax, segment dgroup		; ax <- dgroup of driver
	mov	ds, ax				; ds <- dgroup of driver

	;
	;  To grant someone the channel, all we need
	;	to do is make sure no one else
	;	has taken it, and then take it
	;	ourselves.
	test	ds:[channelUsage], dl		; is anyone using one?
	jnz	error				; was there an overlap?

	;
	;  There wasn't an overlap.  Now set all the
	;	bits that were requested
	or	ds:[channelUsage], dl		; set the channels used
	clr	dl				; clear the mask
done:
	.leave
	ret
error:
	;
	;  There was an overlap.  Determine which channels
	;	could not be granted and return
	and	dl, ds:[channelUsage]
EC<	ERROR_Z -1				; better be something...>
	jmp	short done
DOSRDMARequest	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMARelease
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the channel resource

CALLED BY:	Strategy Routine
PASS:
		dl	-> mask of channels released

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		V's all the semaphores in the mask

PSEUDO CODE/STRATEGY:
		V each semaphore specified in the mask		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMARelease	proc	near
	uses	ax, ds
	.enter
	mov	ax, segment dgroup		; ax <- segment of driver 
	mov	ds, ax				; es <- segment of driver

EC<	mov	al, ds:[channelUsage]		; al <- channels granted>
EC<	and	al, dl				; al <- granted & released>
EC<	cmp	al, dl				; any released but not granted>
EC<	ERROR_NE BAD_DMA_RELEASE_MASK				>

	xor	ds:[channelUsage], dl		; change channel masks to zero

EC<	mov	al, dl				; al <- channels released >
EC<	and	al, ds:[channelUsage]		; al <- channels enabled  >
EC<	ERROR_NZ BAD_DMA_RELEASE_MASK				>
	.leave
	ret
DOSRDMARelease	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMADisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable DREQ from reaching chip for given channels

CALLED BY:	Strategy Routine

PASS:		dl	-> mask of channels to stop

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		sets mask bit of chip for each specified channel

PSEUDO CODE/STRATEGY:
				

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMADisable	proc	near
	uses	ax, dx, ds
	.enter

	mov	ax, segment dgroup		; ax <- dgroup of driver
	mov	ds, ax				; es <- dgroup of driver

EC<	mov	al, dl				; al <- channels to stop >
EC<	and	al, ds:[channelUsage]		; al <- channels used    >
EC<	cmp	al, dl				; stop un-used channels? >
EC<	ERROR_NE BAD_DMA_DISABLE_MASK		; I hope not....	 >

	mov	ah, mask MRM_disable		; ah <- setting for channels

	call	DOSRDMAWriteMaskRegisters
	.leave
	ret	
DOSRDMADisable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMAEnable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable DREQ to reach chip for given channels

CALLED BY:	Strategy Routine

PASS:		dl	-> mask of channels to re-start

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		clears mask bit of chip for each specified channel

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMAEnable	proc	near
	uses	ax, dx, ds
	.enter

	mov	ax, segment dgroup		; ax <- dgroup of driver
	mov	ds, ax				; es <- dgroup of driver

EC<	mov	al, dl				; al <- channels to enable  >
EC<	and	al, ds:[channelUsage]		; al <- channels granted    >
EC<	cmp	al, dl				; start un-granted channel? >
EC<	ERROR_NE BAD_DMA_ENABLE_MASK		; I hope not....	    >

	clr	ah				; ah <- setting for channels

	call	DOSRDMAWriteMaskRegisters
	.leave
	ret
DOSRDMAEnable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMAWriteMaskRegisters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the All Mask Register to update state

CALLED BY:	DOSRDMAEnable/Disable, DOSRDMARead/Write

PASS:		dl	-> mask of channels to set
		ah	-> setting for each channel
		ds	-> dgroup

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
		changes (probably) the channel request mask on
		the one or two DMA chips in the system.

		updates the settings in the dgroup
		
PSEUDO CODE/STRATEGY:
		Make the disk-drive walk across the table by
		seeking to one end of the disk, then seeking to the other.
		Well, that's what I'd like to do..... :)

		Actually, what we do is compare the mask bit of
		each channel with the original mask bit.  If there
		is a change, then write the new setting, otherwise,
		leave it alone.

		We don't use write all mask register because this
		could enable/disable a channel that was enabled/
		disabled by dos or some other TSR.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/14/92		Initial version
	DL  03/24/00		16 bit DMA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMAWriteMaskRegisters	proc	near
	uses	ax, cx, dx
	.enter
	;
	;  What we must now do is determine if
	;	there was a change in the status
	;	of each channel and if so, update
	;	the channels one at a time.
	mov	dh,dl			; save DMA mask
	
	mov	cx, 8
	clr	al				; al <- start at channel 0
topOfLoop:
	;
	;  See if this channel changed
	shr	dl, 1				; examine lsb of changes

	jc	changeChannel

nextChannel:
	inc	al				; al <- next channel #
	loop	topOfLoop	

	.leave
	ret

changeChannel:
	;
	;  We have just shifted off a changed channel.
	;  Examine the lsb of the settings and see
	;	if we should set or reset the bit.
	and	al, mask MRM_channel		; al <- mask register channel #
	or	al, ah				; al <- mask register setting
;---------------------------------------
; 	switch for 8 or 16 bit DMA channel
; 	the DH register show which type is requested
;---------------------------------------
	cmp	dh,01fh				; DMA 5..7 ?
        jb	bit_8				; nein
;
; 16 Bit
;
	out	AT_SINGLE_REQUEST_MASK, al	; write new mask for channel
	jmp	short nextChannel

;
; 8 Bit DMA
;
bit_8:

	out	PC_SINGLE_REQUEST_MASK, al	; write new mask for channel
	jmp	short nextChannel

DOSRDMAWriteMaskRegisters	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMATransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the DMA chip to do a transfer

CALLED BY:	Strategy Routine

PASS:		bx:si	-> start of buffer
		(must be word-aligned for 16 bit DMA)
		cx	-> length of buffer (in bytes/words)
		dl	-> channel for DMA
		dh	-> ModeRegisterMask

RETURN:		cx	<- length of buffer DMA'd
DESTROYED:	nothing
SIDE EFFECTS:	
		sets DMA channel for use

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMATransfer	proc	near
	uses	ax, bx, dx, si
	.enter
EC<	cmp	dl,4					>
EC<	ERROR_Z BAD_DMA_CHANNEL		>
EC<	cmp	dl,7					>
EC<	jbe	start_sub				>
EC<	ERROR	BAD_DMA_CHANNEL		>
EC<	start_sub:					>

	;
	;  Get the page # and address of the beginning of the
	;  buffer to program the DMA chip.
	;	ax <- page #, bx <- offset for SEGMENT
	;	This code is only valid for real mode operation, or
	;	if the memory manager intercepts DMA programming and
	;	does the proper translations (EMM386 usually does)
	mov_tr	ax, bx			; ax <- PPPPAAAA AAAAAAAAb

	rol	ax, 1			; ax <- PPPAAAAA AAAAAAAPb
	rol	ax, 1			; ax <- PPAAAAAA AAAAAAPPb
	rol	ax, 1			; ax <- PAAAAAAA AAAAAPPPb
	rol	ax, 1			; ax <- AAAAAAAA AAAAPPPPb

	mov	bx, 0fff0h		; bx <- 11111111 11110000b
	and	bx, ax			; bx <- AAAAAAAA AAAA0000b
	xor	ax, bx			; ax <- 00000000 0000PPPPb

	;
	;  Calculate true page and address with offset
	;	ax <- page # for buffer, bx <- offset for buffer
	add	bx, si			; bx <- true address of buffer
	adc	ax, 0			; ax <- true page of buffer

	cmp	dl, 4			; is it an AT channel?
	jae	adjustATPageOffset

setChannelSettings:
	;
	;  Set up si to index the port #'s in the table below
	push	dx			; save channel # and mode register

	clr	dh			; dx <- dl
	mov	si, dx			; si <- channel # byte offset

	;
	;  As we are going to program the DMA chip, we must have
	;	the internal flip-flop cleared so we program
	;	the correct byte of each word value
	push	ax

	mov	dl, cs:flipFlopPortAddress[si]
	clr	al
	out	dx, al
	jmp	$+2

	pop	ax

	;
	;  Set up the DMA chip to work on the correct page
	mov	dl, cs:pagePortAddress[si]	; dx <- port # for channel
	out	dx, al				; write page # to port
	jmp	$+2

	;
	;  Set up the DMA chip to work on the correct offset
	mov	dl, cs:addressPortAddress[si]	; dx <- port # for channel
	mov	al, bl				; al <- lsb of block offset
	out	dx, al				; write low byte
	jmp	$+2				; wait for fast AT's

	mov	al, bh				; al <- msb of block offset
	out	dx, al				; write high byte
	jmp	$+2				; wait for fast AT's

	;
	;  Set up the DMA chip to work for the correct length
	add	bx, cx				; bx <- ending address
	jc	crossPageBoundry

writeLength:
	mov	dl, cs:lengthPortAddress[si]	; dx <- port # for channel

	mov	al, cl				; al <- lsb of count
	out	dx, al				; write low byte
	jmp	$+2				; wait for fast PC's

	mov	al, ch				; ah <- msb of count
	out	dx, al				; write high byte

	;
	;  Write transfer mode to DMA chip
	pop	dx				; restore channel & command

	mov	al, 003h			; al <- 0000 0011b
	and	al, dl				; al <- mask of chip channel
	or	al, dh				; al <- Mode Register setting

	clr	dh
	mov	dl, cs:modePortAddress[si]	; dl <- Mode register setting

	out	dx, al				; write mode
done::
	.leave
	ret

crossPageBoundry:
	;
	;  When we get here, bx contains the ending of the
	;  buffer in the next page, and cx contains the
	;  total length.  So, we just subtract bx from
	;  cx getting and set it for that length
	sub	cx, bx				; cx <- remaining lenght
	jmp	short	writeLength

;----------------------------------------
; Calculation of Page/Offset for 16-Bit-DMA
;
; Only the offset needs to be recalculated
; (DL: 02.04.2000)
; ax = Page	bx = Offset
;----------------------------------------

adjustATPageOffset:
	;
	;	All the AT channels deal with words, as
	;	they are originally handled by a second
	;	DMA chip just wired with shifted address
	;	lines, so the address range is 128K with
	;	word increments.
	;	the page register, however, is wired like
	;	the 8 bit version, except that the LSB is
	;	ignored totally
	;	So, we must adjust the offset to be a word
	;	word offset. and deal with an odd page.
	shr	bx				; bx <- word offset/2 (16 bit transfers/increments)
	push	ax			; save ax
	shr	ax				; is the page equal? (ignore the MSB shifted in)
	pop	ax				; restore ax ( unused LSB still needed for page 
						; boundary crossing)
    jnc	setChannelSettings

	;  We shifted out a page.  Add it in to the offset
	add	bx, 08000h			; bx <- extra 64k of offset
	jmp	short setChannelSettings

DOSRDMATransfer	endp

pagePortAddress		byte	CHANNEL_ZERO_PAGE,
				CHANNEL_ONE_PAGE,
				CHANNEL_TWO_PAGE,
				CHANNEL_THREE_PAGE,
				CHANNEL_FOUR_PAGE,	; Better never be used!
				CHANNEL_FIVE_PAGE,
				CHANNEL_SIX_PAGE,
				CHANNEL_SEVEN_PAGE

lengthPortAddress	byte	CHANNEL_ZERO_COUNT,
				CHANNEL_ONE_COUNT,
				CHANNEL_TWO_COUNT,
				CHANNEL_THREE_COUNT,
				CHANNEL_FOUR_COUNT,	; Better never be used!
				CHANNEL_FIVE_COUNT,
				CHANNEL_SIX_COUNT,
				CHANNEL_SEVEN_COUNT

addressPortAddress	byte	CHANNEL_ZERO_OFFSET,
				CHANNEL_ONE_OFFSET,
				CHANNEL_TWO_OFFSET,
				CHANNEL_THREE_OFFSET,
				CHANNEL_FOUR_OFFSET,	; Better never be used!
				CHANNEL_FIVE_OFFSET,
				CHANNEL_SIX_OFFSET,
				CHANNEL_SEVEN_OFFSET

modePortAddress		byte	PC_CHANNEL_MODE,
				PC_CHANNEL_MODE,
				PC_CHANNEL_MODE,
				PC_CHANNEL_MODE,
				AT_CHANNEL_MODE,
				AT_CHANNEL_MODE,
				AT_CHANNEL_MODE,
				AT_CHANNEL_MODE

flipFlopPortAddress	byte	PC_CLEAR_FLIP_FLOP,
				PC_CLEAR_FLIP_FLOP,
				PC_CLEAR_FLIP_FLOP,
				PC_CLEAR_FLIP_FLOP,
				AT_CLEAR_FLIP_FLOP,
				AT_CLEAR_FLIP_FLOP,
				AT_CLEAR_FLIP_FLOP,
				AT_CLEAR_FLIP_FLOP

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMACheckTC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a job has been completed

CALLED BY:	Strategy Routine
PASS:		dl	-> channel to look at
RETURN:		carry set if job still going
		carry clear if job pending

DESTROYED:	nothing
SIDE EFFECTS:	
		none

PSEUDO CODE/STRATEGY:
		check the JobPending		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMACheckTC	proc	near
	uses	bx, ds
	.enter
	mov	bx, segment dgroup
	mov	ds, bx

	clr	bx
	mov	bl, dl
	shl	bx, 1

	call	DOSRDMAUpdatePendingJobs

EC<	stc						>
EC<	ERROR_C -1					>
	.leave
	ret
DOSRDMACheckTC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMAUpdatePendingJobs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the TC complete register and zero completed jobs

CALLED BY:	DOSRDMACheckTC
PASS:		ds	-> dgroup of driver
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		changes pending job status

PSEUDO CODE/STRATEGY:
		read PC chip
		zero those jobs which have completed
		read AT chip
		zero those jobs which have completed
		return	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMAUpdatePendingJobs	proc	near
	uses	ax, cx, di
	.enter

EC<	stc						>
EC<	ERROR_C	-1					>

	.leave
	ret

DOSRDMAUpdatePendingJobs	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSRDMAStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop a DMA transfer

CALLED BY:	Strategy Routine

PASS:		dl	-> channel to stop

RETURN:		cx	<- # of bytes left to process

DESTROYED:	nothing
SIDE EFFECTS:	
		updates the pendingJob info

PSEUDO CODE/STRATEGY:
		update the pendingJob info
		check the current job
		mark request high if jobs match
		return current word value

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSRDMAStop	proc	near
	uses	ax, bx, dx, ds
	.enter
	mov	bx, segment dgroup		; bx <- dgroup of driver
	mov	ds, bx				; es <- dgroup of driver

	clr	bx				; bx <- channel #
	mov	bl, dl

	mov	cl, dl				; cl <- channel #
	mov	dl, 01h				; dl <- 00000001b
	shl	dl, cl				; dl <- channel mask

	mov	ah, mask MRM_disable		; ah <- new mask settings
	call	DOSRDMAWriteMaskRegisters	; mask off channel
	
	mov	dl, cs:lengthPortAddress[bx]	; dx <- port to read from
	clr	dh

	in	al, dx				; al <- low byte of count
	jmp	$+2
	jmp	$+2

	mov	ah, al
	in	al, dx				; al <- high byte of count
	xchg	al,ah

	cmp	bx, 3				; is PC chip or AT chip?
	jb	done

	shl	ax, 1				; if AT, transform byte to word

done:
	mov_tr	cx, ax				; cx <- # of bytes left

	.leave
	ret
DOSRDMAStop	endp

ResidentCode		ends
