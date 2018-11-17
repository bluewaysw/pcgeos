COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) MyTurn.com 2000 -- All Rights Reserved

PROJECT:	Wav Library
FILE:		adpcm.asm

AUTHOR:		David Hunter, March 29, 2000

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	deh	6/12/2000	Added MS ADPCM decoder
	deh	3/29/2000	Initial revision

DESCRIPTION:
	This contains the code to perform Microsoft IMA ADPCM and
	Microsoft ADPCM decompression

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;============================================================================
;
;                     MICROSOFT IMA ADPCM DECOMPRESSOR
;
; Tables and C code (now comments) borrowed from Microsoft's sample IMA
; ADPCM CODEC available (for now) in the Microsoft Windows NT DDK.
;
;============================================================================

IMAADPCM_HEADER_LENGTH	equ	4

ImaAdpcmCode	segment resource

next_step	byte -1, -1, -1, -1, 2, 4, 6, 8
		byte -1, -1, -1, -1, 2, 4, 6, 8

step	word        7,     8,     9,    10,   11,    12,    13,    14
	word       16,    17,    19,    21,   23,    25,    28,    31
	word       34,    37,    41,    45,   50,    55,    60,    66
	word       73,    80,    88,    97,   107,   118,   130,   143
	word      157,   173,   190,   209,   230,   253,   279,   307
	word      337,   371,   408,   449,   494,   544,   598,   658
	word      724,   796,   876,   963,  1060,  1166,  1282,  1411
	word     1552,  1707,  1878,  2066,  2272,  2499,  2749,  3024
	word     3327,  3660,  4026,  4428,  4871,  5358,  5894,  6484
	word     7132,  7845,  8630,  9493, 10442, 11487, 12635, 13899
	word    15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794
	word    32767

; al <- nEncSample
; dx <- nPredSample
; bl <- nStepIndex
; Returned: dx -> nPredSample
; Destroyed: si

imaadpcmSampleDecode	macro
		local	signClear, bit2Clear, bit1Clear, bit0Clear
		local	clamp, done, samplePos

;    nStepSize   = step[nStepIndex];

		push	ax, bx
		xchg	bl, al		; al <- nStepIndex, bl <- nEncSample
		shl	al, 1
		mov	si, ax		; si <- offset into step table
		mov	si, cs:[step][si]	; si <- step[nStepIndex]
		push	dx		; save nPredSample
		clrdw	axdx		; axdx = lDifference
		
		;  calculate difference:
		;
		;       lDifference = (nEncodedSample + 1/2) * nStepSize / 4

		test	bl, 04h		; if (nEncodedSample & 4)
		jz	bit2Clear
		add	dx, si		;     lDifference += nStepSize
		adc	ax, 0
bit2Clear:
		shr	si, 1		; si <- nStepSize / 2
		test	bl, 02h		; if (nEncodedSample & 2)
		jz	bit1Clear
		add	dx, si		;     lDifference += nStepSize>>1
		adc	ax, 0
bit1Clear:
		shr	si, 1		; si <- nStepSize / 4
		test	bl, 01h		; if (nEncodedSample & 1)
		jz	bit0Clear
		add	dx, si		;     lDifference += nStepSize>>2
		adc	ax, 0
bit0Clear:
		shr	si, 1		; si <- nStepSize / 8
		add	dx, si		;     lDifference += nStepSize>>4
		adc	ax, 0
		
		test	bl, 08h		; if (nEncodedSample & 8)
		jz	signClear
		negdw	axdx		;     lDifference = -lDifference
signClear:
		mov	si, dx		; axsi = lDifference
		pop	dx		; dx = nPredSample
		clr	bx
		tst	dx		; is dx negative?
		jns	samplePos
		dec	bx		; sign extend into bx
samplePos:				; bxdx = nPredSample
		add	dx, si
		adc	bx, ax		; bxdx <= nPredSample + lDifference
		clr	ax
		mov	si, 07fffh	; axsi = most positive signed word
		jgdw	bxdx, axsi, clamp	; branch if bxdx is too big
		notdw	axsi		; axsi = most negative signed word
		jldw	bxdx, axsi, clamp	; branch if bxdx is too small
		jmp	done
clamp:
		mov	dx, si		; clamp to largest signed word
done:
		pop	ax, bx
endm

; al <- nEncodedSample
; bl <- nStepIndex
; Returned: bl -> nStepIndex
; Destroyed: al, si

imaadpcmNextStepIndex	macro
		local	testOver, done

;    nStepIndex += next_step[nEncodedSample];

		xchg	bx, ax		; ax <- ?:nStepIndex, bx <- 0:nEncodedSample
		mov	bl, cs:[next_step][bx]	; bl <- next_step[nEncodedSample]
		xchg	bh, ah		; ah <- 0, bh restored
		add	bl, al		; bl <- nStepIndex + next_step[]
		jns	testOver	; branch if bl >= 0
		clr	bl
		jmp	done
testOver:
		cmp	bl, 88
		jle	done		; branch if bl <= 88
		mov	bl, 88
done:
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		imaadpcmDecode4Bit_M08
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Theis function decodes a buffer of data from ADPCM to PCM in
		the specified format.

CALLED BY:	PlaySoundIMAADPCM

PASS:		ds:si - pointer to the source buffer (ADPCM data)
		es:di - pointer to the destination buffer (PCM data).
		        Note that it is assumed to be large enough to hold
			all of the encoded data.
		bx    - the block alignment of the ADPCM data (in bytes)
		cx    -	the length of the source buffer

RETURN:		si    - offset in source buffer of first unused byte
		di    - offset in dest buffer one past last decoded sample

DESTROYED:	nothing
		

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	3/29/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
imaadpcmDecode4Bit_M08	proc	near
		uses	ax, bx, cx, dx
blkAlgn		local	word	push bx
srcLength	local	word	push cx
		.enter

;    while (cbSrcLength >= cbHeader)

mainLoop:
		cmp	srcLength, (IMAADPCM_HEADER_LENGTH * 1)
	LONG	jb	done

;        cbBlockLength  = (UINT)min(cbSrcLength, nBlockAlignment);

		mov	cx, blkAlgn	; cx <- nBlockAlignment
		cmp	srcLength, cx	; is cbSrcLength >= nBlockAlignment?
		jae	smallSrc	; branch if so
		mov	cx, srcLength	; cx <- cbSrcLength
smallSrc:

;        cbSrcLength   -= cbBlockLength;
;        cbBlockLength -= cbHeader;

		sub	srcLength, cx
		sub	cx, (IMAADPCM_HEADER_LENGTH * 1)

		;
		;  block header
		;

;        nPredSample = (int)*(short HUGE_T *)pbSrc;
;        pbSrc      += sizeof(short);
;        nStepIndex  = (int)(BYTE)*pbSrc;
;        pbSrc      += sizeof(short);        // Skip over padding byte.

		lodsw			; ax <- nPredSample
		mov	dx, ax		; dx <- nPredSample
		mov	bl, ds:[si]	; bl <- nStepIndex
		add	si, 2

		;
		;  write out first sample
		;

;        *pbDst++ = (BYTE)((nPredSample >> 8) + 128);

		mov	al, ah
		add	al, 080h
		stosb

;        while (cbBlockLength--)

blockLoop:
		jcxz	mainLoop
		dec	cx

;            bSample = *pbSrc++;

		lodsb			; al <- bSample
		mov	bh, al		; bh <- bSample
		push	si

		;
		;  sample 1
		;

;            nEncSample  = (bSample & (BYTE)0x0F);

		and	al, 0fh		; al <- nEncSample
		clr	ah

;            nPredSample = imaadpcmSampleDecode(nEncSample, nPredSample, nStepSize);

		imaadpcmSampleDecode	; dx <- nPredSample

;            nStepIndex  = imaadpcmNextStepIndex(nEncSample, nStepIndex);

		imaadpcmNextStepIndex	; bl <- nStepIndex

		;
		;  write out sample
		;

;            *pbDst++ = (BYTE)((nPredSample >> 8) + 128);

		mov	al, dh
		add	al, 080h
		stosb

		;
		;  sample 2
		;

;            nEncSample  = (bSample >> 4);

		mov	al, bh
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1

;            nPredSample = imaadpcmSampleDecode(nEncSample, nPredSample, nStepSize);

		imaadpcmSampleDecode	; dx <- nPredSample

;            nStepIndex  = imaadpcmNextStepIndex(nEncSample, nStepIndex);

		imaadpcmNextStepIndex	; bl <- nStepIndex

		;
		;  write out sample
		;

;            *pbDst++ = (BYTE)((nPredSample >> 8) + 128);

		mov	al, dh
		add	al, 080h
		stosb

;        }
		pop	si
		jmp	blockLoop
;    }
done:
		.leave
		ret
imaadpcmDecode4Bit_M08	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlaySoundIMAADPCM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays a Microsoft IMA ADPCM encoded sound.

CALLED BY:	PlaySound
PASS:		bx - file handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Fill our data buffer
		Convert whole blocks to PCM data
		Play the blocks
		Move unconverted data to the start of the data buffer
		Repeat until all blocks are played or error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	6/12/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlaySoundIMAADPCM	proc	far

	.enter	inherit ProcessRIFFFile

	;
	; Lock the blocks for the data.
	;
	mov	ax, ADPCM_IN_BUFFER_SIZE
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc			; bx <- handle of block 
LONG	jc	error
	mov	dataHandle, bx

	mov	ax, DATA_BUFFER_SIZE
	mov	cx, ALLOC_STATIC_LOCK
	call	MemAlloc			; bx <- handle of block 
LONG	jc	errorFreeData
	mov	es, ax
	mov	pcmDataHandle, bx

	clr	cx				; cx <- bytes in src buffer

readBuffer:
	;
	; Read data from the file into the dataBuffer. Number of bytes read
	; will be returned in cx.
	;
	mov	bx, dataHandle
	call	MemLock				; ax <- dataHandle segment
	mov	ds, ax
	mov	si, cx				; ds:si <- dataBuffer +unused
	mov	cx, ADPCM_IN_BUFFER_SIZE
	sub	cx, si				; cx <- bytes to fill buffer
	call	ReadDataFromFile
	jc	done
	add	cx, si				; cx <- total bytes avail.

	;
	; Always convert whole blocks while possible.  When we reach the end
	; of the file, we'll have no choice but to convert a partial block.
	; This is done because the converter must always start at the top
	; of a block.
	;
	mov	bx, fileInfo.FFD_blockAlign	; bx <- block alignment
	clr	dx
	mov	ax, cx				; dx:ax <- total bytes avail.
	cmp	ax, bx				; at least one block?
	jle	partial				; nope, use what we have
	tstdw	fileInfo.FFD_bytesLeft		; file done?
	jz	partial				; yep, convert everything!
	div	bx				; ax <- # whole blocks
	mul	bx				; dx:ax <- # bytes in blocks
partial:
	xchg	cx, ax				; cx <- # bytes to convert,
						; ax <- # bytes in buffer
	;
	; Convert the IMA ADPCM data to PCM data.
	;
	clr	si				; ds:si <- source buffer
	mov	di, si				; es:di <- dest buffer
	call	imaadpcmDecode4Bit_M08
	tst	di				; did it convert anything
	jz	done				; nope, bail

	;
	; Move any unused data at the end of the source buffer to the start.
	;
	sub	ax, cx				; ax <- # bytes remaining
	mov	cx, ax				; cx <- # bytes remaining
	jcxz	noCopy
	push	cx, di, es
	segmov	es, ds, ax
	clr	di
	shr	cx, 1
	pushf
	rep	movsw
	popf
	jnc	evenCX
	movsb
evenCX:
	pop	cx, di, es
noCopy:

	;
	; Play the sound that is in the buffer. di is # of bytes in buffer
	;
	mov	bx, dataHandle
	call	MemUnlock
	segmov	ds, es, ax
	push	cx
	mov	cx, di				; cx <- bytes in dest buffer
	call	PlaySoundFromBuffer
	pop	cx
	
 	;
	; Are we done with a file?
	;
	tstdw	fileInfo.FFD_bytesLeft
	jnz	readBuffer

done:	
	;
	; unlock the block containing the buffer for the data
	;
	mov	bx, pcmDataHandle
	call	MemFree
errorFreeData:
	mov	bx, dataHandle
	call	MemFree
error:
	.leave
	ret
PlaySoundIMAADPCM	endp

ImaAdpcmCode	ends


;============================================================================
;
;                       MICROSOFT ADPCM DECOMPRESSOR
;
; (Microsoft in its infinite wisdom has seen fit to abandon support of their
; own ADPCM format; surprise, surprise.  So, I had to turn elsewhere...)
;
; Tables and algorithm borrowed from SoX (Sound eXchange) sound conversion
; and effects utility.  Thanks to Chris Bagwell for continuing to support
; and distribute this utility.  The home page for the program is currently
; http://home.sprynet.com/~cbagwell/sox.html
;
;============================================================================

MSAdpcmCode	segment	resource

MSADPCM_HEADER_LENGTH	equ	7
MSADPCM_MIN_DELTA	equ	16

AdaptionTable	word	230, 230, 230, 230, 307, 409, 512, 614
		word	768, 614, 512, 409, 307, 230, 230, 230

; al <- iErrorDelta
; dx <- curSample
; bl <- nPred
; ds:0 <- MSADPCMWaveFormat
; Returned: dx -> new nCurSample
; Destroyed: si
;
; Vars:	curSample, oldSample are 16-bit signed integers
;	iDelta is 16-bit unsigned integer
;	coef1, coef2 are signed BBFixed values
;	lPredSamp, lNewSamp are 32-bit signed integers
;	iErrorDelta is 4-bit signed integer
;
; 1. Predict the next sample from the previous two samples.
;    lPredSamp = ((curSample * coef1[nPred]) + (oldSample * coef2[nPred]))
;
; 2. Add the prediction error to the next sample and fixup for
;    overflow/underflow.
;    lNewSamp = lPredSamp + (iDelta * iErrorDelta)
;
; 3. Shift the new sample into the previous sample buffer.
;    oldSample = curSample, curSample = lNewSamp

msadpcmSampleDecode	macro
		local	notNeg, notNeg2, clamp, done
		
		push	bx, cx
		clr	bh
		mov	si, bx		; si <- nPred
		.assert (size MSADPCMCOEFSET eq 4)
		shl	si, 1
		shl	si, 1		; si <- offset into MSAWF_coeff
		push	ax		; save iErrorDelta
		push	dx		; save curSample
		mov_tr	ax, dx		; ax <- curSample
		imul	ds:MSAWF_coeff[si].MSACS_coef1
		movdw	cxbx, dxax	; cxbx <- temp sum
		pop	ax		; ax <- curSample
		xchg	ax, oldSample	; ax <- oldSample,
					;  oldSample <- curSample
		imul	ds:MSAWF_coeff[si].MSACS_coef2
		adddw	cxbx, dxax	; cxbx <- lPredSamp (WB.B)
		pop	ax		; ax <- iErrorDelta
		mov	si, ax		; si <- iErrorDelta
		test	ax, 08h		; Is negative?
		jz	notNeg		; nope, branch
		or	al, 0f0h	; sign-extend into ax
		not	ah
notNeg:
		imul	iDelta		; dxax <- iDelta * iErrorDelta
		add	al, bh		; add lPredSamp
		adc	ah, cl
		adc	dl, ch
		clr	dh
		test	dl, 080h	; Is negative?
		jz	notNeg2		; nope, branch
		dec	dh
notNeg2:				; dxax <- lNewSamp
		xchg	dx, ax		; axdx <- lNewSamp
		clr	bx
		xchg	bx, ax		; bxdx <- lNewSamp, ax = 0
		mov	cx, 07fffh	; axcx = most positive signed word
		jgdw	bxdx, axcx, clamp	; branch if bxdx is too big
		notdw	axcx		; axcx = most negative signed word
		jldw	bxdx, axcx, clamp	; branch if bxdx is too small
		jmp	done
clamp:
		mov	dx, cx		; clamp to largest signed word
done:					; curSample <- lNewSamp
		mov	ax, si		; restore ax
		pop	bx, cx
endm

; al <- iErrorDelta
; ds:0 <- MSADPCMWaveFormat
; Returned: bl -> iDelta
; Destroyed: ax, si
;
; iDelta = iDelta * AdaptionTable[iErrorDelta]
;
; iErrorDelta is 4-bit index
; iDelta is 16-bit unsigned integer
; AdaptionTable is array of signed BBFixed values

msadpcmNextStepIndex	macro
		local	store
		
		push	dx
		mov	si, ax		; si <- iErrorDelta
		shl	si, 1		; si <- offset into AdaptionTable
		mov	ax, iDelta	; ax <- iDelta
		imul	cs:AdaptionTable[si]	; dl:ah <- iDelta
		xchg	al, ah
		mov	ah, dl		; ax <- iDelta
		cmp	ax, MSADPCM_MIN_DELTA
		jae	store
		mov	ax, MSADPCM_MIN_DELTA
store:
		mov	iDelta, ax	; store new value
		pop	dx
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		msadpcmDecode4Bit_M08
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Theis function decodes a buffer of data from ADPCM to PCM in
		the specified format.

CALLED BY:	PlaySoundMSADPCM

PASS:		ds:si - pointer to the source buffer (ADPCM data)
		es:di - pointer to the destination buffer (PCM data).
		        Note that it is assumed to be large enough to hold
			all of the encoded data.
		bx    - the block alignment of the ADPCM data (in bytes)
		cx    -	the length of the source buffer
		dx    - segment of the extra data block (MSADPCMWaveFormat)

RETURN:		si    - offset in source buffer of first unused byte
		di    - offset in dest buffer one past last decoded sample

DESTROYED:	nothing
		

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	3/29/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
msadpcmDecode4Bit_M08	proc	near
		uses	ax, bx, cx, dx
srcBuffer	local	sptr	push ds
extraSeg	local	sptr	push dx
blkAlgn		local	word	push bx
srcLength	local	word	push cx
blkLength	local	word
oldSample	local	sword
iDelta		local	sword
		.enter
	;
	; Loop until we don't have enough bytes for a header.
	;
mainLoop:
		cmp	srcLength, (MSADPCM_HEADER_LENGTH * 1)
	LONG	jb	done
	;
	; Load blkLength with the number of bytes to decode for this block.
	;
		mov	cx, blkAlgn	; cx <- nBlockAlignment
		cmp	srcLength, cx	; is srcLength >= nBlockAlignment?
		jae	smallSrc	; branch if so
		mov	cx, srcLength	; cx <- srcLength
smallSrc:
	;
	; Decrement srcLength by the block length.
	;
		sub	srcLength, cx
	;
	; Decrement blkLength by the header length.
	;
		sub	cx, (MSADPCM_HEADER_LENGTH * 1)
		mov	blkLength, cx	; blkLength <- cx
	;
	; Read the header.
	;
		segmov	ds, srcBuffer, ax
		lodsb			; al <- nPred
		mov	bl, al		; bl <- nPred
		lodsw			; ax <- iDelta
		mov	iDelta, ax	; store it
		lodsw			; ax <- curSample
		mov_tr	dx, ax		; dx <- curSample
		lodsw			; ax <- oldSample
		mov	oldSample, ax	; store it
	;
	; Write out the first two samples.
	;
		mov	al, oldSample.high	; First oldSample...
		add	al, 080h
		stosb
		mov	al, dh			; ...then curSample
		add	al, 080h
		stosb
	;
	; Load cx with the number of samples in this block. First calculate
	; how many samples the block can hold given its byte length, then
	; limit that by MSAWF_samplesPerBlock.
	;
		segmov	ds, extraSeg, ax
		shl	cx, 1		; cx <- calc'd samples in this block
		mov	ax, ds:[MSAWF_samplesPerBlock]
		sub	ax, 2		; ignore samples in header
		cmp	ax, cx		; samplesPerBlock <= calc'd samples?
		ja	shortBlk	; branch if not
		mov	cx, ax
shortBlk:				; cx <- samples in this block
		jmp	endBlkLoop
	;
	; Loop to decode all samples in this block:
	;
blockLoop:
	;
	; Read a byte.  Each nibble is an encoded sample.
	;
		mov	ds, srcBuffer	; ds <- srcBuffer
		lodsb			; al <- bSample
		mov	bh, al		; bh <- bSample
		push	si
		dec	blkLength	; consumed another byte
		mov	ds, extraSeg	; ds <- extraSeg
	;
	; Sample 1 - High nibble
	;
		and	ax, 00f0h	; ah = 0
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1		; al <- iErrorDelta
		msadpcmSampleDecode	; dx <- curSample
		msadpcmNextStepIndex	; bl <- nPred
		mov	al, dh
		add	al, 080h
		stosb			; write it
	LONG	jcxz	endBlkLoopPop	; branch if out of samples
		dec	cx
	;
	; Sample 2 - Low nibble
	;
		mov	al, bh
		and	ax, 000fh	; al <- iErrorDelta, ah = 0
		msadpcmSampleDecode	; dx <- curSample
		msadpcmNextStepIndex	; bl <- nPred
		mov	al, dh
		add	al, 080h
		stosb			; write it
	;
	; End of block loop
	;
endBlkLoopPop:
		pop	si
endBlkLoop:
		jcxz	blockDone
		dec	cx
		jmp	blockLoop
blockDone:
	;
	; Skip any remaining block padding.
	;
		add	si, blkLength
		jmp	mainLoop
done:
		mov	ds, srcBuffer
		.leave
		ret
msadpcmDecode4Bit_M08	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlaySoundMSADPCM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Plays a Microsoft ADPCM encoded sound.

CALLED BY:	PlaySound
PASS:		bx - file handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Fill our data buffer
		Convert whole blocks to PCM data
		Play the blocks
		Move unconverted data to the start of the data buffer
		Repeat until all blocks are played or error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	6/12/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PlaySoundMSADPCM	proc	far

	.enter	inherit ProcessRIFFFile

	;
	; Lock the blocks for the data.
	;
	mov	ax, ADPCM_IN_BUFFER_SIZE
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc			; bx <- handle of block 
LONG	jc	error
	mov	dataHandle, bx

	mov	ax, DATA_BUFFER_SIZE
	mov	cx, ALLOC_STATIC_LOCK
	call	MemAlloc			; bx <- handle of block 
LONG	jc	errorFreeData
	mov	es, ax
	mov	pcmDataHandle, bx

	clr	cx				; cx <- bytes in src buffer

readBuffer:
	;
	; Read data from the file into the dataBuffer. Number of bytes read
	; will be returned in cx.
	;
	mov	bx, dataHandle
	call	MemLock				; ax <- dataHandle segment
	mov	ds, ax
	mov	si, cx				; ds:si <- dataBuffer +unused
	mov	cx, ADPCM_IN_BUFFER_SIZE
	sub	cx, si				; cx <- bytes to fill buffer
	call	ReadDataFromFile
	jc	done
	add	cx, si				; cx <- total bytes avail.

	;
	; Always convert whole blocks while possible.  When we reach the end
	; of the file, we'll have no choice but to convert a partial block.
	; This is done because the converter must always start at the top
	; of a block.
	;
	mov	bx, fileInfo.FFD_blockAlign	; bx <- block alignment
	clr	dx
	mov	ax, cx				; dx:ax <- total bytes avail.
	cmp	ax, bx				; at least one block?
	jle	partial				; nope, use what we have
	tstdw	fileInfo.FFD_bytesLeft		; file done?
	jz	partial				; yep, convert everything!
	div	bx				; ax <- # whole blocks
	mul	bx				; dx:ax <- # bytes in blocks
partial:
	xchg	cx, ax				; cx <- # bytes to convert,
						; ax <- # bytes in buffer
	;
	; Convert the MS ADPCM data to PCM data.
	;
	clr	si				; ds:si <- source buffer
	mov	di, si				; es:di <- dest buffer
	mov	dx, ss:[extraSeg]		; dx <- segment of extra data
	call	msadpcmDecode4Bit_M08
	tst	di				; did it convert anything
	jz	done				; nope, bail

	;
	; Move any unused data at the end of the source buffer to the start.
	;
	sub	ax, cx				; ax <- # bytes remaining
	mov	cx, ax				; cx <- # bytes remaining
	jcxz	noCopy
	push	cx, di, es
	segmov	es, ds, ax
	clr	di
	shr	cx, 1
	pushf
	rep	movsw
	popf
	jnc	evenCX
	movsb
evenCX:
	pop	cx, di, es
noCopy:

	;
	; Play the sound that is in the buffer. di is # of bytes in buffer
	;
	mov	bx, dataHandle
	call	MemUnlock
	segmov	ds, es, ax
	push	cx
	mov	cx, di				; cx <- bytes in dest buffer
	call	PlaySoundFromBuffer
	pop	cx
	
 	;
	; Are we done with a file?
	;
	tstdw	fileInfo.FFD_bytesLeft
	jnz	readBuffer

done:	
	;
	; unlock the block containing the buffer for the data
	;
	mov	bx, pcmDataHandle
	call	MemFree
errorFreeData:
	mov	bx, dataHandle
	call	MemFree
error:
	.leave
	ret
PlaySoundMSADPCM	endp

MSAdpcmCode	ends
