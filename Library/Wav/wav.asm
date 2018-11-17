COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Wav Library
FILE:		wav.asm

AUTHOR:		Andrew Wilson, Jul 21, 1993

ROUTINES:
	Name			Description
	----			-----------
	WavPlayFile		Plays a .wav file sound

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/21/93		Initial revision
	srs	8/10/93		Scarfed from Andrew

DESCRIPTION:
	This contains the code to play a digitized .wav file sound

	$Id: wav.asm,v 1.1 97/04/07 11:51:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef	GPC_ONLY
ifndef PRODUCT_NDO2000
PRODUCT_NDO2000			equ	1	; needed for Nokia SDK compatibility, as the 
								; author of BestSound is not using the ND/MyTurn
								; SDK configuration
endif

WAV_CALL_BSNWAV			enum	Warnings
WAV_AFTER_BSNWAV		enum	Warnings

endif

PROGRESS_WARNINGS	equ	FALSE

if PROGRESS_WARNINGS
CALLING_FILE_READ			enum	Warnings
CALLING_SPTSS				enum	Warnings
FINISHED_CALLING_FILE_READ		enum	Warnings
FINISHED_CALLING_SPTSS			enum	Warnings
endif

idata	segment
wavSem		Semaphore	< 1, 0 >
idata	ends

Fixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WavPlaySoundAndDestroyThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is intended to be called from ThreadCreate.

CALLED BY:	ThreadCreate

PASS:
		cx - handle of block containing WavFilePathBlock

RETURN:
		never - it jumps to ThreadDestroy

DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WavPlaySoundAndDestroyThread		proc	far

;	call	WavLockExclusive

	call	WavPlayFromWavFilePathBlock

	; We won't give up the ghost here because we are A-number-1
	; priority.  We should get the ThreadDestroy before being
	; task switched.
	;
;	call	WavUnlockExclusive

	;    Set hair on fire and run
	;

	clr	cx,dx,bp			;exit code, no ack object
	jmp	ThreadDestroy

WavPlaySoundAndDestroyThread		endp
Fixed	ends

WavCode	segment resource

		SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WAVPLAYFILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	WavPlayFile	

C DECLARATION:

extern void
    _pascal WavPlayFile(DiskHandle disk, const char *path, const char *fname);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WAVPLAYFILE	proc	far	disk:hptr, path:fptr.char, fname:fptr.char
	uses	ds, es, di
	.enter
	mov	bx, disk
	lds	dx, path
	les	di, fname
	call	WavPlayFile
	.leave
	ret
WAVPLAYFILE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLAYSOUNDFROMFILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	PlaySoundFromFile

C DECLARATION:

extern void
    _pascal PlaySoundFromFile(FileHandle file);

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLAYSOUNDFROMFILE	proc	far
	.enter
	C_GetOneWordArg	bx,	cx,dx
	call	PlaySoundFromFile
	.leave
	ret
PLAYSOUNDFROMFILE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WAVPLAYINITSOUND
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	WavPlayInitSound

C DECLARATION:

extern void
    _pascal WavPlayInitSound(GeodeToken *geodeToken, word enum);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	3/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WAVPLAYINITSOUND	proc	far
	C_GetThreeWordArgs	cx, dx, bx, ax	; cx:dx <- GeodeToken *
						; bx <- enum type
	call	WavPlayInitSound
	ret
WAVPLAYINITSOUND	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WavPlayFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create WavFilePathBlock and create another thread, passing
		the WavFilePathBlock, to play the sound.

CALLED BY:	EXTERNAL

PASS:		
	bx - disk handle OR StandardPath
		If BX is 0, then the passed path is either relative to
		the thread's current path, or is absolute (with a
		drive specifier).

	ds:dx - Path specification.  The path MAY contain a drive
		spec, in which case, BX should be passed in as zero.

	es:di - file name with extension and null terminated

RETURN:		
		nothing
DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UICategory char "ui", 0
UIKey char "sound", 0

WavPlayFile		proc	far
	uses	ax,bx,cx,dx,bp,di,si,es,ds
	.enter

	;    Allocate WavFilePathBlock

	mov	si,bx				;disk handle or StandardPath
	mov	ax, size WavFilePathBlock
	mov	cx, mask HF_SHARABLE or mask HF_SWAPABLE or (mask HAF_LOCK shl 8)
	mov	bx, handle 0			;wav library is owner
	call	MemAllocSetOwner
	jc	done

	push	es,di				;filename fptr

	;    Copy path to WavFilePathBlock
	;

	mov	es,ax				;WavFilePathBlock segment
	mov	es:[WFPB_disk],si		;disk handle or StandardPath
	mov	di,offset WFPB_path
	mov	si,dx				;source path offset
	mov	cx,(size WFPB_path)/2		;source path length
	rep movsw

	;    Copy filename to WavFilePathBlock
	;

	pop	ds,si				;filename fptr
	mov	di,offset WFPB_file
	mov	cx,(size WFPB_file)/2
	rep movsw	

	;     Unlock WavFilePathBlock
	;

	call	MemUnlock

	push	bx				;WavFilePathBlock handle
	mov	al,PRIORITY_UI
	mov	cx, segment Fixed
	mov	dx,offset WavPlaySoundAndDestroyThread
	mov	bp,handle 0			;wav library is owner
	mov	di, WAV_OTHER_THREAD_STACK_SIZE
	call	ThreadCreate
	pop	bx				;WavFilePathBlock handle
	jc	threadCreateError

done:
	.leave
	ret

threadCreateError:
	call	MemFree
	jmp	done

WavPlayFile		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WavPlayFromWavFilePathBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play the .wav file specified in the passed WavFilePathBlock

CALLED BY:	INTERNAL
		WavPlaySoundAndDestroyThread

PASS:		cx - WavFilePathBlock handle

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WavPlayFromWavFilePathBlock		proc	far
	uses	ax,bx,dx,ds
	.enter

	;    Lock WavFilePathBlock
	;

	mov	bx,cx
	call	MemLock
	jc	done
	push	bx				;WavFilePathBlock handle
	mov	ds,ax

	;    Switch to specifed directory
	;

	call	FilePushDir
	mov	bx,ds:[WFPB_disk]
	mov	dx,offset WFPB_path
	call	FileSetCurrentPath
	jc	popDir

	;    Open the .wav file
	;

	mov	dx,offset WFPB_file
	mov	al, FE_DENY_WRITE shl offset FAF_EXCLUDE or \
		    FA_READ_ONLY shl offset FAF_MODE
	call	FileOpen
	jc	popDir

	;    Play that sound
	;

	mov	bx,ax				;.wav file handle
	call	PlaySoundFromFile

	;    Close that file
	;

	clr	al
	call	FileClose

popDir:
	;    Restore original directory
	;

	call	FilePopDir

	;    Unlock and free the WavFilePathBlock
	;

	pop	bx				;WavFilePathBlock handle
	call	MemUnlock
	call	MemFree

done:
	.leave
	ret
WavPlayFromWavFilePathBlock		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to make sure that the file is a sample sound file.

CALLED BY:	PlaySoundFromFile

PASS:		bx - handle of file

RETURN: 	carry clear if file is good
			ax - SoundFileFormat
		carry set if file is no good

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 8/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileFormat	proc	near
	uses	bx,cx,dx,ds
headerBuffer	local	HeaderDescriptor
	.enter

	segmov	ds, ss, ax			; ds <- ss, trashes ax
	
	;
	; Read the header of the file into the buffer on the stack.
	;
	mov	dx, bp
	add	dx, offset headerBuffer		; ds:dx = buffer to read to
	clr	ax				; flags
	mov	cx, size HeaderDescriptor	; # of bytes to read

	call	FileRead
	
	; 
	; Is the file a RIFF file?
	;
	mov	ax, {word} ds:[headerBuffer].HD_fileID
	mov	cx, "RI"
	mov	bx, {word} ds:[headerBuffer].HD_fileID+2
	mov	dx, "FF"

	cmpdw	axbx, cxdx
	jne	checkAIFF
	
	;
	; So far so good.  Is it a WAVE format?  
	;
	mov	ax, {word} ds:[headerBuffer].HD_fileFormat
	mov	cx, "WA"
	mov	bx, {word} ds:[headerBuffer].HD_fileFormat+2
	mov	dx, "VE"

	cmpdw	axbx, cxdx
	mov	ax, SFF_RIFF
	je	goodExit
noGood:
	stc
	jmp	exit

checkAIFF:	
	mov	cx, "FO"
	mov	dx, "RM"
	cmpdw	axbx, cxdx
	jne	noGood

	;
	; Looks like an AIFF file so far.  Check the format.
	;
	mov	ax, {word} ds:[headerBuffer].HD_fileFormat
	mov	cx, "AI"
	mov	bx, {word} ds:[headerBuffer].HD_fileFormat+2
	mov	dx, "FF"

	cmpdw	axbx, cxdx
	mov	ax, SFF_AIFF
	jne	noGood
	
goodExit:
	clc

exit:
	.leave
	ret
GetFileFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlaySoundFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays a sound from the passed file handle

CALLED BY:	GLOBAL
PASS:		bx - file handle
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlaySoundFromFile	proc	far	uses	ax, di, ds, si, cx, dx, bp

	.enter

	;
	;  If Sound Preference turns off the sound, don't play the music
	;
	segmov	ds, cs
	mov	si, offset UICategory	; ds:si - category
	mov	cx, cs
	mov	dx, offset UIKey		; cx:dx - key
	mov	bp, InitFileReadFlags <IFCC_INTACT, 1, 0, 0>
	call	InitFileReadBoolean
	jc	exit
	tst	ax
	jz	exit

;----------------------------------
; Playing WAV-File with BSNWAV-Lib
;----------------------------------

ifndef	GPC_ONLY

EC<	WARNING	WAV_CALL_BSNWAV>

	push	bx			; FileHandle for later
	push	bx			; FileHandle
	clr	bx			; Clear BX for pushing zeros to stack
	push	bx			; PlayFlags (0x0000)
	push	bx			; Optr to parent (0x0000)
	push	bx			; 2nd half of optr

	call	BSNWAVEPLAYFILE		; call BSNWAV-Lib for playing WAV
					; with 16 Bit / Stereo / 44 kHz
					; BestSound-driver will be needed

	pop	bx			; Get FileHandle back from Stack

EC<	WARNING	WAV_AFTER_BSNWAV>

	tst	ax
	jz	exit			; respond = 0 --> finish
endif

;--------------------------------------
; Playing WAV-File with the 'old' code
; if the BSNWAV-Lib has reported an
; error or the WAV-Lib is not compiled
; for NDO2000
;--------------------------------------

	call	GetFileFormat		;AX = SoundFileFormat
	jc	exit			;If unrecognized, branch
	mov_tr	di, ax
	cmp	di, size soundPlayRoutines-2
	ja	exit
	call	cs:[soundPlayRoutines][di]

exit:
	.leave
	ret
PlaySoundFromFile	endp
soundPlayRoutines	nptr	ProcessRIFFFile



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessRIFFFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract all necessary information from the RIFF file.

CALLED BY:	PlaySoundFromFile

PASS:		nothing

RETURN:		carry clear if all is well
			fileInfo fields filled in
		carry set if all is not well
			fileInfo fields undefined

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessRIFFFile	proc	near	uses	bx, cx, dx, si, ds, es
.warn -unref_local
	fileHandle	local	hptr	\
			push	bx

	fileInfo	local	FileFormatDescriptor
;
;	Used by ProcessRIFFFormatChunk/DataChunk
;
	chunkSize	local	dword
	chunkRead	local	word
	extraSize	local	word
	extraHan	local	hptr
	extraSeg	local	sptr
	fmtChunkInfo	local	FormatChunkDescriptor
;
;	Used by PlaySoundFromBuffer
;
	bytesLeft	local 	word
	dacThingie	local	SampleFormatDescription
	dataHandle	local	hptr
	pcmDataHandle	local	hptr
.warn @unref_local
	dacHandle	local	hptr

	.enter

	;
	; Find the format chunk.
	;
	mov	cx, "fm"
	mov	dx, "t "
	call	FindRIFFChunk
	jc	done

	;
	; Extract the important format information from the chunk.
	;
	clr	ss:[extraHan]
	call	ProcessRIFFFormatChunk
	jc	freeExtra

	;
	; Things still look dandy.  Find the data chunk.
	;
	mov	cx, "da"
	mov	dx, "ta"
	call	FindRIFFChunk
	jc	freeExtra

	;
	; Extract size and position of data from the chunk.
	;
	call	ProcessRIFFDataChunk
	jc	freeExtra

	;
	; Allocate a new DAC.
	;
	call	SoundAllocSampleStream
	jc	freeExtra

	mov	dacHandle, bx
	call	PrepareSoundStream	; attach the DAC
	jnc	playSound

freeDAC:
	call	SoundFreeSampleStream

freeExtra:
	;
	; Free extra block if alloc'd and leave.
	;
	pushf
	mov	bx, ss:[extraHan]
	tst	bx
	jz	noExtra
	call	MemFree
noExtra:
	popf
done:
	.leave
	ret

	;
	; Grab the exclusive lock now, so that other WAV threads trying to play
	; will fail above, and other external clients can block until we're done.
	;
playSound:
	call	WavLockExclusive

	call	PlaySound

if 0
PrintMessage <Nuke this code when there is a way to wait for a sound to end>

	;    Guessimate time to sleep based on data size and
	;    stream buffer size. Use smaller of the two values
	;

	clr	dx
	mov	ax,ASSUMED_STREAM_BUFFER_SIZE
	cmpdw	fileInfo.FFD_dataSize,dxax
	jae	calcSleep
	movdw	dxax,fileInfo.FFD_dataSize

calcSleep:

	mov	bx,60		;Ticks per second
	mul	bx
	mov	bx, fileInfo.FFD_sampleRate
	div	bx

	;    Wait for the sound to stop playing before returning
	;
	call	TimerSleep


;
;	WORKAROUND FOR BUG IN ZOOMER SOUND DRIVER THAT WOULD DIE IF YOU CALLED
;	SoundDisableSampleStream WHILE THERE WAS STILL DATA IN THE STREAM:
;

	;
	; Check if the sound stream is empty - if not, sleep for a second, 
	; and check again...
	;

waitForStreamToEmpty:

	push	ds
	mov	bx, dacHandle
	call	MemDerefDS
	mov	ds, ds:[SC_position].SSS_stream.SSS_streamSegment
	tst	ds:[SD_reader].SSD_sem.Sem_value
	pop	ds
	jz	streamEmpty

	mov	ax, 60
	call	TimerSleep
	jmp	waitForStreamToEmpty

streamEmpty:
	;
	; The sound stream is empty - wait another 1/2 second 
	;
	mov	ax, 30
	call	TimerSleep

endif
	;
	; Disable the stream now that we've finished with it.
	;
	mov	bx, dacHandle
	call	SoundDisableSampleStream

	;
	; Relinquish our exclusive lock, cleanup and leave.
	;
	call	WavUnlockExclusive
	jmp	freeDAC


ProcessRIFFFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadDataFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read data from the file into the buffer for the data.  

CALLED BY:	PlaySound... routines

PASS:		ds	= segment address of block for data to be written to
		si	= offset of block for data to be written to
		cx	= number of bytes to read (max)

RETURN:		cx	= number of bytes read

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 8/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadDataFromFile	proc	far
	uses	ax,bx,dx,ds,bp
	.enter	inherit	ProcessRIFFFile

	mov	dx, cx
	;
	; Figure out how much data to read from the file.
	;
	mov	cx, fileInfo.FFD_bytesLeft.low	; # of bytes to read
	tst	fileInfo.FFD_bytesLeft.high
	jnz	useMax
	cmp	cx, dx
	jbe	readNow
useMax:
	mov	cx, dx

readNow:
	;
	; Read the data from the file.
	;

if 0
PrintMessage <Nuke ECCode>
;***
	mov	bx, dataHandle
	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
	call	MemGetInfo
	tst	ah
	ERROR_Z	-1
	
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	cmp	ax, cx
	ERROR_B	-1
	
	mov	dx, ds
	mov	ax, MGIT_ADDRESS
	call	MemGetInfo
	cmp	ax, dx
	ERROR_NZ	-1
;***
endif

	mov	dx, si				; ds:dx = buffer to read to

	test	fileInfo.FFD_format, DACRB_WITH_REFERENCE_BYTE
	jnz	ref
read:
	mov	bx, fileHandle			; bx <- handle of file to read
	clr	ax				; flags
if PROGRESS_WARNINGS
EC <	WARNING	CALLING_FILE_READ					>
endif
	call	FileRead			; cx <- amount read (bytes)
if PROGRESS_WARNINGS
EC <	WARNING	FINISHED_CALLING_FILE_READ				>
endif
	jc	fileEnded

if 0
PrintMessage <nuke this>

	push	si
	mov	si, dx							
	add	si, cx							
	cmp	si, DATA_BUFFER_SIZE+1
	ERROR_A	-1
	cmp	{byte} ds:[DATA_BUFFER_SIZE], 0
	ERROR_NE	-1
	pop	si
endif

	;
	; decrement bytesLeft by amount read
	;
	clr	dx
	subdw	fileInfo.FFD_bytesLeft, dxcx
EC <	ERROR_C		-1						>
	jmp	short done

fileEnded:
	cmp	ax, ERROR_SHORT_READ_WRITE
	stc
	jnz	done
	;
	; unexpected end of file.  possibly because size was wrong.
	; we'll just note that there's no bytes left and play what we have.
	;
	clrdw	fileInfo.FFD_bytesLeft
if	0
	cmp	{byte} ds:[DATA_BUFFER_SIZE], 0
	ERROR_NE	-1
endif
	clc
done:	
	.leave
	ret

ref:
	dec	cx
	mov	{byte}ds:[0], 000h
	inc	dx
	jmp	read

ReadDataFromFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlaySoundFromBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play the sound that is in the buffer. 

CALLED BY:	PlaySound... routines

PASS:		ds	= segment address of block for data buffer
		cx	= number of bytes in buffer


RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 8/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlaySoundFromBuffer	proc	far
	uses	ax,bx,cx,dx,bp,si,di
	.enter	inherit	ProcessRIFFFile
	mov	bytesLeft, cx

	;
	; fill in dacThingie fields
	;
	mov	cx, fileInfo.FFD_formatMID
	mov	ss:[dacThingie].SFD_manufact, cx
	mov	cx, fileInfo.FFD_format
	mov	ss:[dacThingie].SFD_format, cx
	and	fileInfo.FFD_format, not DACRB_WITH_REFERENCE_BYTE
	mov	cx, fileInfo.FFD_sampleRate
	mov	ss:[dacThingie].SFD_rate, cx
	mov	ss:[dacThingie].SFD_playFlags, mask DACPF_CATENATE
	
	mov	bx, dacHandle
	mov	dx, ds
	clr	si				; dx:si = buffer of DAC data
	mov	cx, ss:[bytesLeft]	

playLoop:	
if 0	; Why limit the byte count?
	;
	; Play a certain number of bytes (<= cx) to DAC.
	;
	cmp	cx, DAC_STREAM_SIZE			
	jbe	playToDAC			; not much left, play it all!
	mov	cx, DAC_STREAM_SIZE		; too much!  play part of it.
	
playToDAC:
endif
	push	bp
	lea	bp, dacThingie
;noErr:
	mov	ax, ss				; ax:bp=SampleFormatDescription
if PROGRESS_WARNINGS
EC <	WARNING	CALLING_SPTSS						>
endif
	call	SoundPlayToSampleStream
if PROGRESS_WARNINGS
EC <	WARNING	FINISHED_CALLING_SPTSS					>
endif
;	jnc	noErr
	pop	bp

	;
	; Decrement bytesLeft by number of bytes played and see if we are
	; done playing the whole buffer.
	;
	mov_tr	ax, cx			; ax = number of bytes played
	mov	cx, ss:[bytesLeft]	; cx = # of bytes left before playing
	sub	cx, ax			; cx = number of bytes left after playing
	jcxz 	donePlaying

	;
	; Still some more to go.  Advance position of buffer to start playing
	; from and keep track of the number of bytes to go.
	;
	and	ss:[dacThingie].SFD_format, not DACRB_WITH_REFERENCE_BYTE
	add	si, ax			; si <- beginning of next part of buffer 
	mov	ss:[bytesLeft], cx	; save # of bytes left in buffer to play
	jmp	short playLoop

donePlaying:	
	.leave
	ret
PlaySoundFromBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays a sound from the file we've opened/processed

CALLED BY:	GLOBAL
PASS:		bx - file handle
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlaySound	proc	near
	uses	ds, es
	.enter	inherit ProcessRIFFFile

	;
	; Raise our thread priority to reeeelly important, cause that's what we are.
	;
	push	bx
	clr	bx
	mov	ax, PRIORITY_TIME_CRITICAL or \
		    (mask TMF_BASE_PRIO or mask TMF_ZERO_USAGE) shl 8
	call	ThreadModify
	pop	bx

	;
	; Do different things depending on the sound format.
	;

	cmp	fmtChunkInfo.FCD_formatTag, WAVE_FORMAT_PCM
	jne	notPCM
	call	PlaySoundPCM
	jmp	done

notPCM:
	cmp	fmtChunkInfo.FCD_formatTag, WAVE_FORMAT_IMA_ADPCM
	jne	notIMAADPCM
	call	PlaySoundIMAADPCM
	jmp	done

notIMAADPCM:
	cmp	fmtChunkInfo.FCD_formatTag, WAVE_FORMAT_ADPCM
	jne	done
	call	PlaySoundMSADPCM

done:
	.leave
	ret

PlaySound	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlaySoundPCM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays a PCM encoded sound.  In other words, no encoding;
		the sound library plays this kind of data.

CALLED BY:	PlaySound
PASS:		bx - file handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Read a block of data
		Play the block
		Repeat until all blocks are played or error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	6/12/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlaySoundPCM	proc	near
	.enter	inherit ProcessRIFFFile

	;
	; Lock the block for the data.
	;
	mov	ax, DATA_BUFFER_SIZE
	mov	cx, ALLOC_STATIC_LOCK
	call	MemAlloc			; bx <- handle of block 
	jc	error
	mov	ds, ax
	mov	es, ax
	mov	dataHandle, bx

readBuffer:
	;
	; Read data from the file into the dataBuffer. Number of bytes read
	; will be returned in cx.
	;
	mov	cx, DATA_BUFFER_SIZE
	clr	si				; ds:si <- dataBuffer
	call	ReadDataFromFile
	jc	done

	;
	; Downconvert the PCM data in place if necessary.
	;
	test	fileInfo.FFD_flags, mask FFF_16_TO_8_BITS
	jz	not16Bit

	; 16 to 8 bit conversion: Skip the low (earliest) bytes.
	; Also, 16-bit samples are signed and use 0000h as center,
	; as opposed to 8-bit samples which are unsigned and use 80h.
	;
	shr	cx, 1
	push	cx
	clr	si
	mov	di, si
pcm16to8:
	lodsw
	xchg	al, ah
	add	al, 80h
	stosb
	loop	pcm16to8
	pop	cx

not16Bit:
	test	fileInfo.FFD_flags, mask FFF_UNDERSAMPLE
	jz	play

	shr	cx, 1
	push	cx
	clr	si
	mov	di, si

	test	fileInfo.FFD_format, (DACSF_STEREO shl offset SMID_format)
	jz	undermono

	; Stereo 8-bit undersampling: Skip every other word.
understereo:
	lodsw
	stosw
	add	si, 2
	loop	understereo
	jmp	underdone

	; Mono 8-bit undersampling: Skip every other byte.
undermono:
	lodsw
	stosb
	loop	undermono

underdone:				; Ha.
	pop	cx

play:
	;
	; Play the sound that is in the buffer. cx is # of bytes in buffer
	;
	call	PlaySoundFromBuffer
	
 	;
	; Are we done with a file?
	;
	tstdw	fileInfo.FFD_bytesLeft
	jnz	readBuffer

done:	
	;
	; unlock the block containing the buffer for the data
	;
	mov	bx, dataHandle
	call	MemFree
error:
	.leave
	ret
PlaySoundPCM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrepareSoundStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach the DAC.  If unsuccessful, will try again with
		maximum priority.  

CALLED BY:	SampleSoundsFileSelected

PASS:		bx - DAC handle

RETURN:		carry set if unsuccessful, else carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 9/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrepareSoundStream	proc	near
	uses	ax,bx,cx,dx,si
	.enter	inherit	ProcessRIFFFile

	;
	; Attach the DAC.
	;
	mov	ax, SP_STANDARD
	mov	cx, fileInfo.FFD_sampleRate
	mov	dx, fileInfo.FFD_formatMID
	mov	si, fileInfo.FFD_format
	call	SoundEnableSampleStream
;	jnc	done					; attached! 

if 0
	;
	; driver unavailable, try again with highest priority.
	; if still won't attach, must be a hardware error 
	; (i.e. does user even have a sound driver?)
	;
	clr	ax					; 0 = highest priority
	call	SoundEnableSampleStream
endif

done::
	.leave
	ret
PrepareSoundStream	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindRIFFChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the specified type of chunk in the file. Only looks 
		at the part of the file that is after the current position.

CALLED BY:	ProcessRIFFFile

PASS:		bx - handle of sound file
		cxdx	= chunk ID of the type of chunk to find 
		es	= dgroup

RETURN:		carry set if chunk not found
		carry clear if found
			file position will be set at end of chunk ID

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/11/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindRIFFChunk	proc	near
	uses	ax,bx,cx,dx,ds,di

.assert	ID_STRING_LENGTH	eq	size dword
	chunkBuffer	local	dword

	chunkSize	local	dword	
	
	.enter

	push	cx, dx				; save chunkID

	
	segmov	ds, ss, ax			; ds <- ss, trashes ax

findChunk:
	;
	; Read the chunk ID (4 character code).
	;
	mov	dx, bp
	add	dx, offset chunkBuffer		; ds:dx = buffer to read to
	clr 	ax				; flags
	mov	cx, ID_STRING_LENGTH		; # of bytes to read

	call	FileRead		
	jc	popDone

	;
	; Compare it with the chunk ID of the kind of chunk we want.
	;
	pop	cx, dx				; restore chunkID

	cmpdw	dxcx, chunkBuffer
	je	done				; found it!

	;
	; Keep looking.  
	;
	push	cx, dx				; save chunkID
	
	;
	; Read the size of the current chunk.
	;
	mov	dx, bp
	add	dx, offset chunkSize		; ds:dx = buffer to read to
	clr	ax				; flags
	mov	cx, size dword			; cx <- # of bytes to read

	call	FileRead
	jc	popDone

	;
	; Position file at beginning of next chunk.
	;
	movdw	cxdx, ss:[chunkSize]		; cxdx <- size of chunk
	mov	al, FILE_POS_RELATIVE
	call	FilePos
	jmp	short findChunk
popDone:
	pop	cx, dx
done:
	.leave
	ret
FindRIFFChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessRIFFFormatChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract format and sample rate info from the format chunk	
		and compute the DACSampleFormat from it.

CALLED BY:	ProcessRIFFFile

PASS:		bx - file handle

RETURN:		carry clear if format is acceptable
		carry set if format is not acceptable

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/11/93			Initial version
	dhunter 1/17/2000   Added stereo support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessRIFFFormatChunk	proc	near
	uses	ax,bx,cx,dx,ds
	.enter	inherit	ProcessRIFFFile

	;
	; Read size of format chunk.
	;
	segmov	ds, ss, dx			; ds <- ss, trashes dx

	mov	dx, bp
	add	dx, offset chunkSize		; ds:dx = buffer to read size to
	clr	al				; flags
	mov	cx, size dword			; cx <- # of bytes to read

	call	FileRead
	jc	badFormatNear

	;
	; Read the data of the format chunk into the fmtChunkInfo structure.
	;
	mov	cx, size FormatChunkDescriptor	
	mov	dx, bp
	add	dx, offset fmtChunkInfo		; ds:dx = buffer to read to
	clr	al				; flags

	call	FileRead
	jc	badFormatNear
	mov	ss:[chunkRead], cx

	;
	; Check mono or stereo.
	;
	mov ax, fmtChunkInfo.FCD_numChannels
	cmp	ax, MONO
	je  channelOK
	cmp ax, STEREO
	jne badFormatNear   			    ; can handle mono or stereo
channelOK:

	;
	; Get the sample rate.
	;
	mov	cx, fmtChunkInfo.FCD_samplesPerSec.low

	; Hack to support 44.1 KHz playback on sound driver that doesn't
	; support it.
	cmp	cx, 22050			; rate > 22050?
	jbe	setRate				; nope, it's fine
	cmp	fmtChunkInfo.FCD_formatTag, WAVE_FORMAT_PCM
	jne	setRate				; only undersample PCM data
	shr	cx, 1				; halve the sample rate
	ornf	fileInfo.FFD_flags, mask FFF_UNDERSAMPLE
setRate:
	mov	fileInfo.FFD_sampleRate, cx

	;
	; Copy the blockAlign field.
	;
	mov	cx, fmtChunkInfo.FCD_blockAlign
	mov	fileInfo.FFD_blockAlign, cx
	
	;
	; Get the format tag.
	;
	cmp	fmtChunkInfo.FCD_formatTag, WAVE_FORMAT_PCM
	jne	notPCM

	;
	; Microsoft PCM format:

	;
	; Get the number of bits per sample.
	cmp	fmtChunkInfo.FCD_bitsPerSample, 8	; 8 bits?
	je	PCM8

	cmp	fmtChunkInfo.FCD_bitsPerSample, 16	; 16 bits?
	jne	badFormatNear		; can only handle 8 or 16 bits

	ornf	fileInfo.FFD_flags, mask FFF_16_TO_8_BITS
PCM8:
	mov	fileInfo.FFD_format, (DACSF_8_BIT_PCM shl offset SMID_format)
	mov	fileInfo.FFD_formatMID, MANUFACTURER_ID_GEOWORKS
	cmp ax, STEREO
	jne mono
	or  fileInfo.FFD_format, (DACSF_STEREO shl offset SMID_format)
mono:
	jmp	goodFormat

	; Located here for Near branch convenience
badFormatNear:
	jmp	badFormat

notPCM:
	cmp	fmtChunkInfo.FCD_formatTag, WAVE_FORMAT_IMA_ADPCM
	jne	notIMAADPCM

	;
	; IMA ADPCM format:

	cmp	fmtChunkInfo.FCD_bitsPerSample, 4	; only 4 bits allowed
	jne	badFormat
	mov	fileInfo.FFD_format, (DACSF_8_BIT_PCM shl offset SMID_format)
	mov	fileInfo.FFD_formatMID, MANUFACTURER_ID_GEOWORKS
	cmp	ax, MONO
	jne	badFormat				; only mono for now

	jmp	goodFormat

notIMAADPCM:
	cmp	fmtChunkInfo.FCD_formatTag, WAVE_FORMAT_ADPCM
	jne	notMSADPCM

	;
	; Microsoft ADPCM format:

	cmp	fmtChunkInfo.FCD_bitsPerSample, 4	; only 4 bits allowed
	jne	badFormat
	mov	fileInfo.FFD_format, (DACSF_8_BIT_PCM shl offset SMID_format)
	mov	fileInfo.FFD_formatMID, MANUFACTURER_ID_GEOWORKS
	cmp	ax, MONO
	jne	badFormat				; only mono for now
	call	ProcessRIFFFormatChunkEx
	jc	badFormat
	mov	cx, ss:[extraSize]
	sub	cx, size MSADPCMWaveFormat
	jb	badFormat			; missing the base fields
	segmov	ds, ss:[extraSeg], ax
	mov	ax, ds:[MSAWF_numCoeff]		; ax <- # coeff sets
	.assert	(size MSADPCMCOEFSET eq 4)
	shl	ax, 1
	shl	ax, 1				; ax <- byte count of coeff sets
	cmp	cx, ax
	jb	badFormat			; coeff set too small

	jmp	goodFormat			; It's good!

notMSADPCM:
	;
	; Add other formats here.
	jmp	badFormat

	;
	; Position the file position at the end of the format chunk.
	; If the size of the chunk is the same as the number of bytes we
	; read from the file, then the file position is already at the correct
	; location.
	;
goodFormat:
	movdw	dxcx, ss:[chunkSize]
	sub	cx, ss:[chunkRead]	; cx <- dist to move position
	jcxz	clearCarry

	mov	al, FILE_POS_RELATIVE
	xchg	cx, dx				; cx:dx = offset from current pos
	call	FilePos

clearCarry:	
	clc					; everything went okay!
	jmp 	short done
	
badFormat:
	stc

done:	
	.leave

	ret
ProcessRIFFFormatChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessRIFFFormatChunkEx
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract extra format info from the format chunk.

CALLED BY:	ProcessRIFFFormatChunk
PASS:		bx <- file handle
RETURN:		carry set if error occurred or no extra data
		carry clear otherwise
		ss:[extraSize] <- size of extra data
		ss:[extraSeg] <- segment of fixed block w/ extra data
DESTROYED:	nothing
SIDE EFFECTS:	chunkRead adjusted for new file position

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	6/08/2000    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessRIFFFormatChunkEx	proc	near
	.enter	inherit ProcessRIFFFile

	; Check if there is any remaining data in the chunk.
	;
	movdw	dxcx, ss:[chunkSize]
	sub	cx, ss:[chunkRead]	; cx <- bytes left in chunk
	jcxz	error

	; Read the count of bytes in the extra data.
	;
	mov	cx, size word
	mov	dx, bp
	add	dx, offset extraSize	; ds:dx = buffer to read to
	clr	al				; flags
	call	FileRead
	jc	done
	add	ss:[chunkRead], size word

	; Check if there is actually enough data in the chunk.
	;
	movdw	dxcx, ss:[chunkSize]
	sub	cx, ss:[chunkRead]
	cmp	cx, ss:[extraSize]
	jb	done			; not enough - carry set
	
	; Allocate a block to hold the extra data.
	;
	mov	ax, ss:[extraSize]
	mov	cx, ALLOC_STATIC_LOCK
	call	MemAlloc			; bx <- handle of block 
	jc	done
	mov	ds, ax
	mov	ss:[extraSeg], ax
	mov	extraHan, bx

	; Read the extra data into the block.
	mov	cx, ss:[extraSize]
	clr	dx			; ds:dx = buffer to read data
	clr	al			; flags
	mov	bx, fileHandle
	call	FileRead
	jc	done
	add	ss:[chunkRead], cx
done:
	.leave
	ret
error:
	stc
	jmp	done
ProcessRIFFFormatChunkEx	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessRIFFDataChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size and position of the data and fill in the fields
		of the FileFormatDescriptor.
		Current file position must be at end of chunkID for the
		data chunk.

CALLED BY:	ProcessRIFFFile

PASS:		bx - file handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/12/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessRIFFDataChunk	proc	near
	uses	ax,bx,cx,dx,ds
	.enter	inherit	ProcessRIFFFile

	;
	; Read the size of the data chunk and save it.
	;	
	segmov	ds, ss, ax			; ds <- ss, trashes dx

	mov	dx, bp
	add	dx, offset chunkSize		; ds:dx = buffer to read size to
	clr	ax				; flags
	mov	cx, size chunkSize		; cx <- # of bytes to read

	call	FileRead
	jc	exit

	movdw	dxax, chunkSize
	movdw	fileInfo.FFD_dataSize, dxax	; save size of data
	movdw	fileInfo.FFD_bytesLeft, dxax	; whole thing is left
	
	;
	; Find the current position.
	;
	call	GetCurrentFilePosition
	
	movdw	fileInfo.FFD_dataOffset, dxax	; save position
exit:	
	.leave
	ret
ProcessRIFFDataChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentFilePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current file position.

CALLED BY:	ProcessRIFFDataChunk,

PASS:		bx - file handle

RETURN:		dxax	= current position

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurrentFilePosition	proc	near
	uses	bx,cx
	.enter

	clrdw	cxdx
	mov	al, FILE_POS_RELATIVE
	call	FilePos

	.leave
	ret
GetCurrentFilePosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WavPlayInitSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays a sound specified in the ini file.

CALLED BY:	GLOBAL
PASS:		cx:dx = vfptr to GeodeToken
		bx - enumerated type

RETURN:		nothing
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

 To call this function, you need to make sure the wav file is pointed by a key
 under [sound] category.  The key is composed of the GeodeToken of the calling
 app, and an enumerated word value defined by the app.  For example, the Tetris
 game plays a wav file for dropping pieces.  In tetris, the code calls this
 WavPlayInitSound with Tetris GeodeToken and a word value defined by Tetris.

	#define TETRIS_DROP_SOUND   0
	#define TETRIS_ROTATE_SOUND 1
	GeodeToken token;
	GeodeGetInfo(GeodeGetCodeProcessHandle(), GGIT_TOKEN_ID, &token);
	WavPlayInitSound(&token, TETRIS_DROP_SOUND);
	WavPlayInitSound(&token, TETRIS_ROTATE_SOUND);

 In the net.ini file, you specifed the wav file associate with the sound by:

	[sound]
	84_69_84_82_0_0 = drop.wav
	84_69_84_82_0_1 = rotate.wav

 where "84_69_84_82" is the ascii decimal value of "TETR", the 4 letter token
 chars of the app, the second last digit is the manufacutre ID of Tetris.
 (MANUFACTURE_ID_GEOWORKS is 0.)  The last digit is the enumerated word value
 defined by the app.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	3/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WavPlayInitSound	proc	far
keyBuffer	local	50 dup	(char)
	uses	ax, bx, cx, dx, es, di, ds, si
	.enter
	;
	;  Compose a key by using Geodetoken + enum word
	;
	segmov	es, ss
	lea	di, keyBuffer
	movdw	dssi, cxdx
	call	UtilAsciiToHexString
	;
	;  Now Copy the manufacture ID to the buffer
	;  ds:si should point to GT_manufID
	;
	mov	ax, ds:[si]
	clr	dx
SBCS <	mov	cx, mask UHTAF_NULL_TERMINATE				>
DBCS <	mov	cx, mask UHTAF_NULL_TERMINATE or mask UHTAF_SBCS_STRING	>
	call	UtilHex32ToAscii
	add	di, cx
	;
	;  Copy '_' to the buffer
	;
	mov	{byte}es:[di], '_'
	inc	di
	;
	;  Copy passed enum word
	;
	mov	ax, bx
	clr	dx
SBCS <	mov	cx, mask UHTAF_NULL_TERMINATE				>
DBCS <	mov	cx, mask UHTAF_NULL_TERMINATE or mask UHTAF_SBCS_STRING	>
	call	UtilHex32ToAscii
	;
	;  So now the keyBuffer = "4LetterToken_ManufactureId_EnumWord"
	;
	lea	di, keyBuffer
	call	WavReadInitKeyToPlay
		
	.leave
	ret
WavPlayInitSound	endp

;
; es:di - key
;
WavPlayCategory char "sound", 0
WavFilePath	TCHAR	"sounds", 0

WavReadInitKeyToPlay	proc	near
	uses	bp
	.enter

	mov	cx, es
	mov	dx, di		; cx:dx - key ASCII string

	segmov	ds, cs
	mov	si, offset WavPlayCategory	; ds:si - category

	mov	bp, InitFileReadFlags <IFCC_INTACT, 1, 0, 0>
	call	InitFileReadString
	mov	cx, bx
		
	jc	notFound
	call	MemLock
	mov	es, ax
	clr	di		; es:di - wave file name
	segmov	ds, cs
	mov	dx, offset WavFilePath	; ds:dx - wave file path
ifdef PRODUCT_NDO2000
	mov	bx, SP_USER_DATA	; bx <- StandardPath
else
	mov	bx, SP_PRIVATE_DATA	; disk handle OR StandardPath
endif

	call	WavPlayFile

	mov	bx, cx
	call	MemFree
notFound:
	
	.leave
	ret
WavReadInitKeyToPlay	endp

;
; PASS:	  ds:si - string of 4-letter token
;	  es:di - buffer to store the converted hex letters.
; Return: si, di - changed 
;
UtilAsciiToHexString	proc	near
	uses	ax, cx, dx
	.enter
	
	clr	dx, ax
	mov	cx, 4		; token are 4 letters

loopNext:
	push	cx
		
	mov	al, ds:[si]
SBCS <	mov	cx, mask UHTAF_NULL_TERMINATE				>
DBCS <	mov	cx, mask UHTAF_NULL_TERMINATE or mask UHTAF_SBCS_STRING	>
	call	UtilHex32ToAscii
	add	di, cx
	inc	si
	;
	;  Copy '_' to the buffer
	;
	mov	{byte}es:[di], '_'
	inc	di

	pop	cx
	dec	cx
	jcxz	done
	jmp	loopNext
done:
	;
	;  Copy NULL to the buffer
	;
	clr	{byte}es:[di]

	.leave
	ret
UtilAsciiToHexString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WavLockExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the global exclusive.  Only one thread can play
		a wav file at a time.
		
		May be called externally to wait for a sound to finish
		playing.  (Be sure to UnlockExclusive as well).

CALLED BY:	WavPlaySoundAndDestroyThread, GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		May block if someone is playing a sound.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	10/20/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WavLockExclusive	proc	far
	uses	ax,ds
	.enter

	mov	ax, segment dgroup
	mov	ds, ax
	PSem	ds, wavSem, TRASH_AX

	.leave
	ret
WavLockExclusive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WavUnlockExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release global exclusive.

CALLED BY:	WavPlaySoundAndDestroyThread, GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	10/20/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WavUnlockExclusive	proc	far
	uses	ax,ds
	.enter

	mov	ax, segment dgroup
	mov	ds, ax
	VSem	ds, wavSem, TRASH_AX

	.leave
	ret
WavUnlockExclusive	endp


WavCode	ends
