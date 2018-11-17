COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS Sound System	
MODULE:		DAC driver for Sound Blaster cards
FILE:		soundblasterDAC.asm

AUTHOR:		Todd Stumpf, Oct  9, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/ 9/92		Initial revision


DESCRIPTION:
	These are the routines which manage the DAC on the sound system.

	The driver interface for PC/GEOS presents all DACs as having
	a FIFO queue for the data.  As the SoundBlaster does not actually
	have a FIFO, we need to make one in software.

	The plan is this: We set up a buffer (probably 1k).  Then,
	use the Sound Blasters ability to DMA to transfer the data from
	idata to the device in, say, 64 byte chunks.
		

	$Id: soundblasterDAC.asm,v 1.1 97/04/18 11:57:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata		segment
	DSPFormatCommand		byte

	maxTransferSize			word
udata		ends


ResidentCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACSetSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a transfer rate and format for the DAC

CALLED BY:	Strategy Routine
PASS:		cx	-> DAC to set
		ax	-> ManufacturerID
		bx	-> DACSampleFormat
		dx	-> sampling rate requested (in Hz)

RETURN:		dx	<- sampling rate set (in Hz)
		cx	<- request Stream size
		carry set if un-supported format or DAC #

DESTROYED:	nothing

SIDE EFFECTS:	Attempts to alter the DSP on the Sound Blaster to
		process Data at the new rate and format

PSEUDO CODE/STRATEGY:
		Calculate the divisor for the given rate then set
		the DSP for it.

		The transfer rate of DAC data for the Sound Blaster
		is figured in the following manner:

		RATE = 65,535 - (256,000,000 / divisor)

		So:

		divisor = 65,356 - (256,000,000 / RATE)


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACSetSample	proc	near
	uses	ax
	.enter
	;
	;  See if this is a DAC we should respond to.
	;  As we have only one DAC, we only respond to DAC 0.
	cmp	cx, ds:[numOfDACs]		; addressed to non-zero DAC?
	jae	error

	;
	;  See what the range of sampling rates is for the
	;  given format.  If the closest rate is
	;  zero, that means this sample format is not
	;  supported.
	call	SBDDACCheckSample  ; dx <- closest rate
	tst	dx			; check closest rate
	jz	error

	push	bx			; save sample format
	push	dx			; save sample rate

calculateDivisor::
	;
	mov	cx, dx			; cx <- sampling rate
	movdw	dxax, 256000000		; dxax <- 256000000
	div	cx			; ax <- 65536 - divisor

	neg	ax			; ax <- divisor

	mov	bx, ax			; bx <- divisor for rate

	;
	;  Set up the DAC to operate at the given rate
	SBDDACWriteDSP	DSP_SET_RATE_DIVISOR, 25

	SBDDACWriteDSP	bh, 25

	;
	;  Determine optimal transfer size given rate
	pop	bx			; restore Hz sample rate
	mov	ax, bx			; ax <- sampling rate

	clr	dx			; dxax <- sample rate
	mov	cx, 60			; cx <- 1 tick = 60/sec
	div	cx			; ax <- # of bytes in 1/2 tick

	mov	ds:[maxTransferSize], ax; save maximum allowed transfer

	mov	dx, bx			; dx <- sampling rate
	pop	bx			; restore format

	mov	cx, 1
	call	SBDDACGetFormatSetting	; dl <- mode to set on DSP

	mov	ds:[DSPFormatCommand], dl	; save format for later

	clr	cx			; cx <- no reference byte
	call	SBDDACGetFormatSetting	; dl <- mode to set on DSP
	mov	ds:[interruptTransferMode], dl	; save int. format

	mov	cx, STANDARD_DAC_STREAM_SIZE
	clc				; everything ok
done:
	.leave
	ret
error:
	;
	;  We were told to process a format we don't support.
	;  set the carry flag and return.
	stc
	jmp	short done
SBDDACSetSample	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACCheckSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if a sample rate and format is supported

CALLED BY:	Strategy Routine
PASS:		cx	-> DAC to check
		ax	-> ManufacturerID
		bx	-> DACSampleFormat
		dx	-> sample rate (in Hz)

RETURN:		dx	<- closest available sample rate (in Hz)
		cx	<- request stream size
DESTROYED:	nothing
SIDE EFFECTS:	
		none
PSEUDO CODE/STRATEGY:
		call SBDDACGetFormat range, check bounds and return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACCheckSample	proc	near
	uses	si,di
	.enter
	;
	;  See if the requested DAC # even exits
	cmp	cx, ds:[numOfDACs]
	jae	notSupported

	;
	;  Get the range of sample rates supported for
	;	the specified manufacturer and format.
	;  The maximum and minimum will be zero if
	;	the format is not supported
	call	SBDDACGetFormatRange	; di <- max rate, si <- min rate

	tst	di			; is format supported at all
	jz	notSupported

	;
	;  Is the requested format rate to low?
	cmp	dx, si
	jb	setToMin

	;
	;  Is the requested format rate to fast?
	cmp	dx, di
	ja	setToMax
done:
	mov	cx, STANDARD_DAC_STREAM_SIZE
	.leave
	ret
notSupported:
	clr	dx			; unsupported format. set rate to zero
	jmp	short done

setToMin:
	mov	dx, si			; rate is to low, set to min.
	jmp	short done

setToMax:
	mov	dx, di			; rate is to fast, set to max.
	jmp	short done
SBDDACCheckSample	endp
ResidentCode		ends

LoadableCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACAttachToStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach to the given stream

CALLED BY:	Strategy Routine
PASS:		cx	-> DAC to attach
		ax	-> stream token (virtual segment)
		bx	-> stream segment
		dx	-> stream size
		INT_ON

RETURN:		carry set on error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/19/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACAttachToStream	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	;  Look for legal DAC to attach
	cmp	cx, ds:[numOfDACs]
	jae	error

	;
	;  Set the notification threshold for the reader
	;	half of the stream.  The threshold
	;	is zero, meaning that anytime the writer
	;	writes data, we want to know about it.
	mov	ax, STREAM_READ
	clr	cx
	mov	di, DR_STREAM_SET_THRESHOLD
	call	StreamStrategy

	push	dx				; save stream size

	;
	;  Set notification routine for the reader half
	;  	of the stream.
	mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE,>
	mov	cx, segment ResidentCode
	mov	dx, offset SBDDACReadNotification
	mov	di, DR_STREAM_SET_NOTIFY
	call	StreamStrategy

	;
	;  Try to request the DMA channel
	mov	cx, ds:[baseDMAChannel]
	mov	dl, 1
	shl	dl, cl				; dl <- mask of request channel
	mov	dh, dl				; dh <- mask of request channel
	mov	di, DR_REQUEST_CHANNEL

	INT_OFF
	call	ds:[DMADriver]			; call DMA driver
	INT_ON

	tst	dl				; did we get it?
	jnz	error	

	mov	dl, dh				; dl <- channel of transfer
	mov	di, DR_DISABLE_DMA_REQUESTS
	INT_OFF
	call	ds:[DMADriver]			; turn off requests to chip
	INT_ON

	;
	;  Try to set up an auto-init transfer of the
	;	entire buffer.  If it fails, we
	;	just return carry set.
	pop	ax				; restore size of stream

	mov	si, offset SD_data		; bx:si <- buffer to DMA
	dec	ax				; transfer size -1
	mov	cx, ax				; cx <- size of buffer
	mov	dx, ds:[baseDMAChannel]		; dl <- channel #
	mov	dh, ModeRegisterMask <DMATM_SINGLE_TRANSFER,0,1,DMATD_READ>
	mov	di, DR_START_DMA_TRANSFER
	INT_OFF
	call	ds:[DMADriver]			; set up transfer
	INT_ON

	cmp	cx, ax				; can we transfer buffer?
	jne	error

	mov	ds:[streamSegment], bx

	mov	cx, ds:[baseDMAChannel]
	mov	dl, 1
	shl	dl, cl
	mov	di, DR_ENABLE_DMA_REQUESTS
	INT_OFF
	call	ds:[DMADriver]
	INT_ON					; turn off request to chip

	clc					; clear carry flag
done:
	.leave
	ret
error:
	pop	dx				; clean up stack
	clr	ds:[streamSegment]
	stc
	jmp	short done
SBDDACAttachToStream	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACDettachFromStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up stream and stop transfer

CALLED BY:	Strategy Routine
PASS:		cx	-> DAC to stop
		bx	-> segment for stream

		ds	-> dgroup of driver
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		Stops the DAC in progress.  Stops the DMA transfer

PSEUDO CODE/STRATEGY:
		determine transfer type and call appropriate routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACDettachFromStream	proc	far
	uses	ax, cx, dx, di
	.enter
	pushf
	;
	;  See if we are dealing with a legal DAC
	;
	cmp	cx, ds:[numOfDACs]		; check for legal DAC #
	jae	done


	INT_OFF

	;
	;  See if we are even attached yet
	;
	clr	cx
	xchg	cx, ds:[streamSegment]
	tst	cx
	jz	done

	;
	;  First, we signal the DSP itself to quit
	;	requesting transfers.
	SBDDACWriteDSP DSP_DMA_HALT, 25		; loop 25 times

	;
	;  Then we try to stop the transfer
	;	by instructing the DMA chip to
	;	not respond to the DMA requests.
	mov	cx, ds:[baseDMAChannel]		; cx <- channel for transfer
	mov	dl, 1
	shl	dl, cl				; dl <- mask for channel

	mov	di, DR_DISABLE_DMA_REQUESTS
	call	ds:[DMADriver]			; mask out the channel

	;
	;  Also, we tell the DMA chip to
	;	stop the transfer and finally
	;	we release the channel
	mov	dx, ds:[baseDMAChannel]		; dl <- channel
	mov	di, DR_STOP_DMA_TRANSFER
	call	ds:[DMADriver]			; stop the DMA transfer

	mov	cx, ds:[baseDMAChannel]
	mov	dl, 1
	shl	dl, cl
	mov	di, DR_RELEASE_CHANNEL
	call	ds:[DMADriver]

	;
	;  Clear the "last transfer" amount, so that
	;  we know we are supposed to restart the
	;  DMA process when we reconnect
	clr	ds:[lastInterruptTransferLength]

done:
	call	SafePopf
	.leave
	ret
SBDDACDettachFromStream	endp
LoadableCode			ends

ResidentCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACResetADPCM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the reference bit for the ADPCM transfer

CALLED BY:	Strategy Routine
PASS:		cx	-> DAC to change
		ds	-> dgroup of driver
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		alters the dmaTransferMode if applicable

PSEUDO CODE/STRATEGY:
		check for legal DAC
		check for appropriate transfer mode
		set bit
		return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	12/ 3/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACResetADPCM	proc	near
	.enter
	;
	;  Check for a legal DAC
	cmp	cx, ds:[numOfDACs]
	jae	done

	;
	;  Check for an empty stream
	tst	ds:[dataOnStream]
	jnz	done

	;
	;  It is fairly easy for us to alter the transfer mode.
	;  All we do is copy the dmaTransferMode to the
	;	interrupt transfer mode.
	;  Pretty simple, really.
	mov	cl, ds:[DSPFormatCommand]
	mov	ds:[interruptTransferMode], cl

	;
	;  As there is only one DAC on the Sound blaster, we
	;	know that cx was zero when we reached here.
	;  To preserve cx, all we do is clear cl.
	clr	cl
done:
	.leave
	ret
SBDDACResetADPCM	endp

ResidentCode		ends

LoadableCode			segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACFlushDAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean out the stream and stop the DAC

CALLED BY:	Strategy Routine
PASS:		cx	-> DAC to clean out
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/25/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACFlushDAC	proc	far
	uses	ax, cx, dx, di
	.enter
	cmp	cx, ds:[numOfDACs]
	jae	done

	tst	ds:[streamSegment]
	jz	done

	;
	;  To "Flush" the DAC, all we do is disable the DMA
	;	chip, and then do a DMA_HALT.
	mov	cx, ds:[baseDMAChannel]
	mov	dl, 1
	shl	cl
	mov	di, DR_DISABLE_DMA_REQUESTS
	call	ds:[DMADriver]


	SBDDACWriteDSP	DSP_DMA_HALT, 25
done:
	.leave
	ret
SBDDACFlushDAC	endp

LoadableCode		ends

ResidentCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACGetFormatRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the maximum and minimum rate for the given format

CALLED BY:	SBDCheck(Set)Sample

PASS:		ax	-> ManufacturerID
		bx	-> DACSampleFormat
		dx	-> sample rate (in Hz)

		ds	-> dgroup of driver
RETURN:		si	<- minimum rate for format (zero if unsupported)
		di	<- maximum rate for format (zero if unsupported)

DESTROYED:	nothing
SIDE EFFECTS:	
		none

PSEUDO CODE/STRATEGY:
		Look for legal 
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACGetFormatRange	proc	near
	uses	bx, cx, ds
	.enter
	mov	cx, bx					; cx <- format

	clr	bx,si,di
topOfLoop:
	;
	;  Check for a legal manufacturer ID
	cmp	cs:slowFormatList[bx].DACFR_manufacturerID, ax
	je	checkFormat

incBXAndLoop:
	add	bx, size DACFormatRange			; get next listing
	cmp	cs:slowFormatList[bx].DACFR_manufacturerID, END_OF_DAC_FORMAT_LIST
	jne	topOfLoop

done:
	.leave
	ret

checkFormat:
	;
	;  Check for a matching format #
	cmp	cs:slowFormatList[bx].DACFR_manufacturerID, cx
	jne	incBXAndLoop
	mov	si, cs:slowFormatList[bx].DACFR_min	; si <- min
	mov	di, cs:slowFormatList[bx].DACFR_max	; di <- max
	jmp	short done
SBDDACGetFormatRange	endp

	;
	;  List must be ordered by Manufacturer if GetFormatRange
	;	is to work.
slowFormatList	DACFormatRange	\
	<MANUFACTURER_ID_GEOWORKS     , DACSF_8_BIT_PCM   , 4000, 23000>,
	<MANUFACTURER_ID_CREATIVE_LABS, DACSF_8_BIT_PCM   , 4000, 23000>,
	<MANUFACTURER_ID_CREATIVE_LABS, DACSF_2_TO_1_ADPCM, 4000, 12000>,
	<MANUFACTURER_ID_CREATIVE_LABS, DACSF_3_TO_1_ADPCM, 4000, 13000>,
	<MANUFACTURER_ID_CREATIVE_LABS, DACSF_4_TO_1_ADPCM, 4000, 11000>
	word	END_OF_DAC_FORMAT_LIST


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACGetFormatSetting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the command and value to send to the DSP

CALLED BY:	SBDSetSample
PASS:		dx	-> Hz setting for sample
		bx	-> DACSampleFormat
		cx	-> DACReferenceByte

RETURN:		dl	<- command to send to DSP

DESTROYED:	nothing
SIDE EFFECTS:	
		none

PSEUDO CODE/STRATEGY:
		look up rate and see if it is "high speed".

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACGetFormatSetting	proc	near
	uses	ax,bx
	.enter
	;
	;  Look at format and determine propper command
	;	to send to DSP.
	mov	al, bl				; al <- DACSampleFormat
	shl	al, 1				; make room for reference
	add	al, cl				; al <- format + reference
	mov	bx, offset formatCommandTable	; cs:bx <- formatCommandTable

EC<	cmp	al, size formatCommandTable			>
EC<	ERROR_AE UNSUPORTED_DAC_FORMAT				>

	xlat	cs:[bx]				; al <- DSP command for format

	mov	dl, al				; dl <- command for DSP
done:
	.leave
	ret
SBDDACGetFormatSetting	endp

	;
	;  Depending up the DAC data format, a different command
	;  needs to be given to the DAC.  Since all the formats
	;  supported by the SoundBlaster are currently lower than
	;  128, we just use a xlat command to get the value to
	;  load given the format.
formatCommandTable	byte	14h,		; 8 bit PCM
				14h,		; 8 bit PCM with reference?
				74h,		; 2:1 ADPCM
				75h,		; 2:1 ADPCM with reference
				76h,		; 3:1 ADPCM
				77h,		; 3:1 ADPCM with reference
				16h,		; 4:1 ADPCM
				17h		; 4:1 ADPCM with reference


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACDMANextBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Instruct DSP about size of up-coming transfer

CALLED BY:	SBDDACSetMode
PASS:		cx	-> # of bytes to transfer
		ah	-> DSP command for format

		ds	-> dgroup of driver
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		changes settings of DSP

PSEUDO CODE/STRATEGY:
		The DSP (and the DMA chip) expect to get programmed
			with the # of bytes to transfer-1.  Thus,
		a value of 0 indicates one byte.  This allows an
		entire 64k of data to be passed by setting the
		length to 65536-1=65535, which will fit in a word.

		look for transfer
			send transfer command
			send lsb of count
			send msb of count
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACDMANextBlock	proc	near
	uses	ax,bx,dx
	.enter
	;
	;  For a low-speed command, we send the
	;  transfer command, then the length.
	mov	bl, ah

	SBDDACWriteDSP	bl, 25

	dec	cx				; set # of bytes-1

	SBDDACWriteDSP	cl, 25

	SBDDACWriteDSP	ch, 25

	inc	cx				; restore cx
	.leave
	ret
SBDDACDMANextBlock	endp

ResidentCode		ends
