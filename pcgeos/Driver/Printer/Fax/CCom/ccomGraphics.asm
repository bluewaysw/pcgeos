COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer/Fax/CCom
FILE:		ccomGraphics.asm

AUTHOR:		Don Reeves, April 26, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 1/91		Initial revision
	Don	4/26/91		Made into a printer driver

DESCRIPTION:
	Functions for converting a swath to CFAX format.

	$Id: ccomGraphics.asm,v 1.1 97/04/18 11:52:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; masks to mask out the least-significant/most-significant 'n' bits

PosnMask	byte	0xff, 0xfe, 0xfc, 0xf8, 0xf0, 0xe0, 0xc0, 0x80, 0x00
InvPosnMask	byte	0x00, 0x01, 0x03, 0x07, 0x0f, 0x1f, 0x3f, 0x7f, 0xff

; _BitLength array that gives the number of sequential ones in the first group
; of them looking from the MSB (left)
_BitLength	byte	1, 1, 1, 1, 1, 1, 1, 1, 	; 80 - 87
			1, 1, 1, 1, 1, 1, 1, 1, 	; 88 - 8F
			1, 1, 1, 1, 1, 1, 1, 1, 	; 90 - 97
			1, 1, 1, 1, 1, 1, 1, 1, 	; 98 - 9F
			1, 1, 1, 1, 1, 1, 1, 1, 	; A0 - A7
			1, 1, 1, 1, 1, 1, 1, 1, 	; A8 - AF
			1, 1, 1, 1, 1, 1, 1, 1, 	; B0 - B7
			1, 1, 1, 1, 1, 1, 1, 1, 	; B8 - BF
			2, 2, 2, 2, 2, 2, 2, 2,		; C0 - C7
			2, 2, 2, 2, 2, 2, 2, 2,		; C8 - CF
			2, 2, 2, 2, 2, 2, 2, 2,		; D0 - D7
			2, 2, 2, 2, 2, 2, 2, 2,		; D8 - DF
			3, 3, 3, 3, 3, 3, 3, 3,		; E0 - E7
			3, 3, 3, 3, 3, 3, 3, 3,		; E8 - EF
			4, 4, 4, 4, 4, 4, 4, 4,		; F0 - F7
			5, 5, 5, 5, 6, 6, 7, 8		; F8 - FF

;;; Only need the last 128...
;;;_BitLength	byte	0, 1, 1, 2, 1, 1, 2, 3,		; 00 - 07
;;;			1, 1, 1, 1, 2, 2, 3, 4,		; 08 - 0F
;;;			1, 1, 1, 1, 1, 1, 1, 1,		; 10 - 17
;;;			2, 2, 2, 2, 3, 3, 4, 5,		; 18 - 1F
;;;			1, 1, 1, 1, 1, 1, 1, 1,		; 20 - 27
;;;			1, 1, 1, 1, 1, 1, 1, 1,		; 28 - 2F
;;;			2, 2, 2, 2, 2, 2, 2, 2,		; 30 - 37
;;;			3, 3, 3, 3, 4, 4, 5, 6, 	; 38 - 3F
;;;			1, 1, 1, 1, 1, 1, 1, 1,		; 40 - 47
;;;			1, 1, 1, 1, 1, 1, 1, 1,		; 48 - 4F
;;;			1, 1, 1, 1, 1, 1, 1, 1, 	; 50 - 57
;;;			1, 1, 1, 1, 1, 1, 1, 1,		; 58 - 5F
;;;			2, 2, 2, 2, 2, 2, 2, 2, 	; 60 - 67
;;;			2, 2, 2, 2, 2, 2, 2, 2,		; 68 - 6F
;;;			3, 3, 3, 3, 3, 3, 3, 3,		; 70 - 77
;;;			4, 4, 4, 4, 5, 5, 6, 7,		; 78 - 7F
;;;			1, 1, 1, 1, 1, 1, 1, 1, 	; 80 - 87
;;;			1, 1, 1, 1, 1, 1, 1, 1, 	; 88 - 8F
;;;			1, 1, 1, 1, 1, 1, 1, 1, 	; 90 - 97
;;;			1, 1, 1, 1, 1, 1, 1, 1, 	; 98 - 9F
;;;			1, 1, 1, 1, 1, 1, 1, 1, 	; A0 - A7
;;;			1, 1, 1, 1, 1, 1, 1, 1, 	; A8 - AF
;;;			1, 1, 1, 1, 1, 1, 1, 1, 	; B0 - B7
;;;			1, 1, 1, 1, 1, 1, 1, 1, 	; B8 - BF
;;;			2, 2, 2, 2, 2, 2, 2, 2,		; C0 - C7
;;;			2, 2, 2, 2, 2, 2, 2, 2,		; C8 - CF
;;;			2, 2, 2, 2, 2, 2, 2, 2,		; D0 - D7
;;;			2, 2, 2, 2, 2, 2, 2, 2,		; D8 - DF
;;;			3, 3, 3, 3, 3, 3, 3, 3,		; E0 - E7
;;;			3, 3, 3, 3, 3, 3, 3, 3,		; E8 - EF
;;;			4, 4, 4, 4, 4, 4, 4, 4,		; F0 - F7
;;;			5, 5, 5, 5, 6, 6, 7, 8		; F8 - FF



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertTopMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in white space for the top margin

CALLED BY:	PrintStartPage
	
PASS:		SS:BP	= Local variables

RETURN:		Carry	= Set (if error)
			= Clear (if OK)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertTopMargin	proc	near
cff		local	CFFrame
		uses	ax, bx, cx, di, es
		.enter	inherit
	;
	; Write a bunch of blank lines
	;
		mov	es, ss:[cff.CFF_outBufSeg]
		clr	di			; es:di <- output buffer
		mov	bx, ss:[cff.CFF_curPageFile]
		mov	cx, TOP_MARGIN_OFFSET_MED
		tst	ss:[cff.CFF_faxFileHeader.FFH_resolution]
		jz	store
		mov	cx, TOP_MARGIN_OFFSET_HIGH
store:
		mov	al, BLANK_TOKEN
		ECRepStosb
		call	ConvertFlushBuffer

		.leave
		ret
ConvertTopMargin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a bitmap swath to fax format and write it to the
		file.

CALLED BY:	Spooler

PASS:		BP	= Segment address of PState
		dx.cx   - VM file and block handle for huge bitmap

RETURN:		carry set if file error
			ax	= error code.
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/91		Initial version
	don	5/02/91		Made into a printer driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSwath	proc	far
		mov	bx, bp
cff		local	CFFrame
		uses	cx, dx, di, si, ds, es
		.enter
	
	;
	; Some set-up work
	;
		mov	ds, bx
		call	ConvertCFFrameToStack	; load the stack with frame

	;
	; ds trashed in one of these routines
	;
		segmov	es, ds			; es = segment of PState
		call	LoadSwathHeader

		call	PrLoadPstateVars
		clr	es:[PS_curColorNumber]	; what the hooey?

		call	DerefFirstScanline

		mov	cx, es:[PS_swath].B_width
		mov	dx, es:[PS_swath].B_height

	;
	; Determine the width of the bitmap (in bytes)
	;
		push	cx			; save bitmap width
		mov_tr	ax, cx
		mov	cl, 3
		shr	ax, cl			; divide by eight
		mov	bx, ax			; width (bytes) => BX
		shl	bx, cl			; multiply by eight
		pop	cx			; actual pixel width => CX
		sub	cx, bx			; difference => CX
		jcxz	extraBits
		inc	ax			; we have partially filled byte
extraBits:

		sub	ax, FAX_BAND_WIDTH / 8
		neg	ax			; missing bytes => AX
		mov_tr	cx, ax			; store missing bytes => CX
		mov	bx, ss:[cff.CFF_curPageFile]
		clr	di

scanLoop:
	;
	; Make sure there's enough room in the buffer for a worst-case line
	; (50% grey, as usual). Such a beast requires 15% more room. We
	; take a conservative view and insist on room for 20% more bytes
	; than are in the scan line.
	; 
		mov	ax, CONVERT_BUFFER_SIZE
		sub	ax, di
		cmp	ax, FAX_BAND_WIDTH + (FAX_BAND_WIDTH + 4) / 5
		jae	bufferOK

		push	es
		mov	es, ss:[cff.CFF_outBufSeg] ; es:di <- output buffer
		call	ConvertFlushBuffer	; else flush the buffer
		pop	es

		jc	done			; die if FileWrite failed
bufferOK:
	;
	; Convert the current scan line.
	;
		mov_tr	ax, cx			; missing bytes => AX
		mov	cx, FAX_BAND_WIDTH / 8	; total bytes/line => CX
		push	es			; PState
		mov	es, ss:[cff.CFF_outBufSeg] ; es:di <- output buffer

		call	ConvertScanLine

		xchg	ax, cx			; return missing bytes => CX

	;
	; If line was completely blank, then don't need an EOL.
	;

		cmp	{byte}es:[di-1], BLANK_TOKEN
		je	afterStoreEOL
		mov	al, EOL_TOKEN
		ECStosb
afterStoreEOL:

		pop	es			; PState

		dec	dx
		jz	flush
		inc	es:[PS_newScanNumber]
		call	DerefAScanline
		jmp	scanLoop

flush:
	;
	; Swath is done. Flush anything left in the buffer.
	; HugeArrayUnlock expects sptr to element block 
	; (returned by HugeArrayLock) in ds.
	;
		call	HugeArrayUnlock

		push	es
		mov	es, ss:[cff.CFF_outBufSeg]
		call	ConvertFlushBuffer
		pop	es

done:
	;
	; Segment of PState expected in ds.
	;
		segmov	ds, es
		call	ConvertStackToCFFrame	; write stack back into memory

		.leave
		ret
PrintSwath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertFlushBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush the internal output buffer to the fax file

CALLED BY:	ConvertTopMargin, ConvertSwath
	
PASS:		ES:DI	= Next free byte in buffer (assumes ES:0 starts buffer)
		BX	= File handle

RETURN:		Carry	= Clear (if success)
			= Set (if failure)

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertFlushBuffer	proc	near
		uses	cx, dx, ds
		.enter
	;
	; Now write the buffer out.
	;
		segmov	ds, es
		clr	dx
		mov	cx, di
		jcxz	flushComplete
		mov	di, dx	; start from beginning of buffer when write
				;  is complete.
		clr	al
		call	FileWrite
EC <		WARNING_C ERROR_WRITING_TO_DATA_FILE		>
flushComplete:
		.leave
		ret
ConvertFlushBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertScanLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function converts a single scan-line of bitmap data

CALLED BY:	PrintSwath

PASS:		ds:si	= start of scanline
		es:di	= buffer for output
		cx	= width of scanline to build (in bytes)
		ax	= number of bytes bitmap lacks to complete scanline
		
RETURN:		es:di	= first free byte in output buffer
		ds:si	= one past end of scan line

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

	char *
	BMap2CFax(char *out, char *bitmap, int bytes)
	{
	    register int rlen;
	    register char byte, fval, tval;
	    int res, obits, t, mkup;
	    
	    tval = 0;
	    fval = ~tval;
	    res = 0;
	    p = bitmap;
	    byte = *p++;
	    obits = 0;
	    pending = 0;
	    
	    while(bytes)
	    {
		/*
		 * Look for run of identical bytes of the current run type
		 * before dealing with bits
		 */
		for (rlen = 0; bytes && byte == tval; byte = *p++, bytes--)
		    rlen += 8;
		
		/*
		 * Compensate for the extra bits added in to byte of this color
		 * on the last pass (i.e. the run started res bits into byte,
		 * not from the msb of byte, so reduce the run length by that
		 * amount).
		 */
		rlen -= res;

		/*
		 * Figure how many more bits of the final, non-matching
		 * byte are of the right type. t ends up with bits being 1 if
		 * they're the current run color, and 0 if they're not. The
		 * run can only continue if the left-most bit is of the right
		 * color
		 */
		if (bytes && ((t=((~(byte^tval))&0xff)) & 0x80))
		{
		    res = _BitLength[t-0x80];
		    pmask = PosnMask[8-res];

		    /*
		     * Add the remainder of the run in byte to the total length
		     */
		    rlen += res;
		    
		    /*
		     * Set the high bits that aren't part of the run to match
		     * the off color for our next pass.
		     */
		    byte = (byte & ~pmask) | (fval & pmask);
		}
		else
		{
		    /* run stopped at the previous byte */
		    res = 0;
		}
		
		/*
		 * If we're still building an image token, fill it out as much
		 * as possible with the current color.
		 */
		if (obits)
		{
		    /*
		     * Set all unfilled bits of image token with the current
		     * color. Any overshoot (if rlen < obits) will be taken care
		     * of on the next pass when they will be set to the other
		     * color
		     */
		    pmask = PosnMask[obits];
	
		    /*
		     * (use fval, not tval, because polarity is reversed in an
		     * image token [0 is black, 1 is white])
		     */
		    *out = (*out & pmask) | (fval & ~pmask);

		    /* reduce run length by the bits added to the image token */
		    rlen -= obits;

		    if (rlen < 0)
		    {
		    	/*
			 * overshoot. # unfilled bits is just negative of the
			 * amount of the overshoot
			 */
		        obits = -rlen;
		    }
		    else
		    {
			/*
			 * image token is now filled, so advance output pointer
			 * and reset output-bits-left counter
			 */
		        out++;
			obits = 0;
		    }
		}

		if (rlen > 0)
		{
		    /*
		     * Start an image token if storing a run length would
		     * be wasteful (< 7 bits) and there are enough bits left
		     * to ensure the image token will get filled.
		     */
		    if (rlen < 7 && bytes>1)
		    {
			/* same reason for using fval here as before */
		        *out = (char) (0x80 | fval);
			obits = 7 - rlen;
		    }
		    else
		    {
			/*
			 * Stick in an empty run if it's pending from the
			 * previous pass
			 */
		        if (pending)
			    *out++ = 1;
			/*
			 * If run length is > 64, stick in a token for the
			 * nearest multiple of 64 first.
			 */
			if ((mkup=(rlen>>6)) > 0)
			    *out++ = (char) (mkup+64);
			*out++ = (char) ((rlen&0x3f)+1);
		    }
		    pending = 0;
		}
		else if (!rlen)
		{
		    /* Cancel any empty run that was pending for us, or make
		     * sure the next pass adds an empty run for our color so
		     * things stay in sync. */
		    pending = !0;
		}

		/* Switch to the other color during the next pass */
		tval = fval;
		fval = ~tval;
	    }

	    /* If any unfinished image token, return one past it, else out
	     * is already the first free byte in the output buffer. */
	    return (obits ? out+1 : out);
	}
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WHITE_BYTE = 0
BLACK_BYTE = 0xff

ConvertScanLine	proc	near
missing		local	word	; missing number of bytes from this scanline \
		push	ax
leftMargin	local	word	; bytes in the margin that should be empty \
		push	cx
bytes		local	word	; number of bytes left in this scanline \
		push	cx
rlen		local	word
res		local	word	; remainder
obits		local	word	; # bits left in current image token
emptyPending	local	byte	; non-zero if empty run pending to keep
				;  color syncronized.
		uses	ax, bx, cx, dx, ds
		.enter

if ERROR_CHECK
		push	ds, si
		call	ECCheckBounds
		segmov	ds, es
		mov	si, di
		call	ECCheckBounds
		pop	ds, si
endif

	;
	; dl - white byte, dh = black
	;

		mov	dx, WHITE_BYTE or (BLACK_BYTE shl 8)
		
	;
	; Initialize the other stack-based state variables.
	;
		sub	ss:[leftMargin], (LEFT_MARGIN_OFFSET / 8)
		sub	ss:[missing], (LEFT_MARGIN_OFFSET / 8)
		clr	ax
		mov	ss:[res], ax		; res = 0
		mov	ss:[obits], ax		; obits = 0
		mov	ss:[emptyPending], al	; emptyPending = 0
		mov	al, WHITE_BYTE		; always have margin (white)
		jmp	mainLoop
done:
		tst	ss:[obits]
 ; from what I understand, this shouldn't happen
EC  <		ERROR_NZ PARTIAL_IMAGE_TOKEN_NOT_ALLOWED 		>
NEC <		jz	exit						>
NEC <		inc	di						>
NEC <exit:								>
		.leave
		ret

mainLoop:
	;
	; Check if out of bytes:
	;	while (bytes)
	;	{
	;
	; AL = byte, DL = tval, DH = fval
	;
		mov	cx, ss:[bytes]
		jcxz	done
		
	;
	; Look for bytes that have all bits set to the current color (tval).
	; BX is rlen, counting the number of bits in the run.
	;
		clr	bx		; rlen is 0, for starters
runScanLoop:
		cmp	al, dl		; all the current color?
		jne	figureRunLength	; nope. figure the total length of the
					;  run
		add	bx, 8		; yup. another 8 pixels in the run.
		mov	al, WHITE_BYTE	; al <- white, in case we run over
					;  the right margin
		cmp	cx, ss:[leftMargin]	; still in left margin?
		ja	scanLoop	; yes -- left margin is all white
		cmp	cx, ss:[missing]
		jbe	scanLoop	; right margin/missing bytes are white
		lodsb			; fetch next byte
scanLoop:
		loop	runScanLoop	; and keep looking while there are
					;  bytes to check.
;;;		dec	si		; shouldn't have incremented that
					;  last time, as byte fetched was bogus
figureRunLength:
	;
	; Hit a byte that's not monochromatic (or is, but it's not the current
	; color). Figure the length of the run of the current color. We have
	; to reduce the run length by the number of bits from the initial byte
	; that were forced to the current color on the previous pass (res).
	; 
		sub	bx, ss:[res]	; rlen -= res
		mov	ss:[rlen], bx
		mov	ss:[res], 0	; assume no run continuation
		jcxz	checkImageRemainder; if no bytes left, byte must have
					   ;  been monochromatic...
	;
	; Figure the number of bits in sequence from the MSB that are of
	; the current color. This is done by getting all the bits of the
	; current color to be 1, and those of the off color to be 0. We can
	; then use the high bit and our _BitLength table to see how many, if
	; any, are in sequence.
	; AL = byte, DL = tval, DH = fval = ~tval
	;
	; Note: the operations here aren't a transcription of the C code
	; in the header, because (byte ^ ~tval) gives us the SF with the
	; high bit (NOT doesn't alter the flags), so we can just branch
	; right away.
	;
		mov	ah, al		; preserve byte
		xor	al, dh		; figure (byte ^ ~tval)
		jns	checkImageRemainder	; msb isn't the right color,
						;  so run doesn't include this
						;  byte
		
		lea	bx, cs:[_BitLength-0x80]
		cs:xlatb
		mov	{byte}ss:[res], al; res = _BitLength[t-0x80]

		mov	bh, ah		; preserve byte
		cbw
		add	ss:[rlen], ax	; rlen += res
		mov	ah, bh		; recover byte
		
		sub	al, 8
		neg	al
		lea	bx, cs:[InvPosnMask]
		cs:xlatb		;pmask = PosnMask[8-res]
		and	ah, al		; (byte & ~pmask)
		not	al
		and	al, dh		; (fval & pmask)
		or	ah, al		; byte = (byte & ~pmask)|(fval & pmask)

checkImageRemainder:
		; AH = byte, CX = bytes
		
		mov	ss:[bytes], cx
		mov	cx, ss:[obits]
		jcxz	handleRun
	;
	; We're building up an image token, so set the unclaimed bits (obits
	; least-significant bits) to match the current color. Turns out
	; the polarity of our image matches that of the image token, which
	; is why we use "tval" here, instead of "fval".
	; 
		xchg	ax, cx		; CH = byte, AL = obits
		
		lea	bx, cs:[PosnMask]
		cs:xlatb
		mov	ah, es:[di]	; Fetch the image token
		and	ah, al		; Clear out unfilled bits
		not	al
if WHITE_BYTE eq 0
		and	al, dh		; Fill same bits of AL with tval
					;  (image tokens use inverse polarity
					;  from us, so use fval instead)
else
		and	al, dl		; Fill same bits of AL with tval
endif
		or	al, ah		; Merge them together
		mov	es:[di], al	; and store the image token back again
		
	;
	; Reduce the run length by the number of bits given to the image
	; token, and set the number of unfilled bits appropriately.
	;
		mov	bx, ss:[rlen]
		sub	bx, ss:[obits]
		mov	ss:[rlen], bx
		js	setobits	; => overshoot, -BX is new obits
		inc	di		; image token complete, out++
		clr	bx		; obits = 0
setobits:
		neg	bx
		mov	ss:[obits], bx
		xchg	ax, cx		; AH = byte

	;----------------------------------------------------------------------
handleRun:
	;
	; Now deal with the run itself. If the run length is < 7, we want
	; to either start an image token (if rlen > 0), or mark an empty run
	; pending (if rlen is 0), or just finish this pass (if rlen < 0).
	;
	; AH = byte
		mov	bx, ss:[rlen]
		xchg	cx, ax		; (1-byte inst)
		cmp	bx, 7
		jl	startImageToken
		
		cmp	bx, FAX_BAND_WIDTH
		je	checkBlankLine
storeRun:
	;
	; We actually have a run to store. First see if there's any pending
	; empty run.
	;
		tst	ss:[emptyPending]
		jz	pendingHandled
	;
	; Yes. Store a zero-length run so the right color comes in here.
	;
		mov	al, 1
		ECStosb
pendingHandled:
		mov	ax, bx
		andnf	ax, 0x3f	; ax <- rlen % 64
		xor	bx, ax		; bx <- rlen - (rlen % 64)
		jz	over64Handled

		xchg	bh, bl		; this is rlen >> 6. trust me :)
		rol	bx		;  a.k.a. int(rlen / 64)
		rol	bx		;   ...
		add	bx, 64		; make it a token...
		xchg	ax, bx
		ECStosb
		xchg	ax, bx
over64Handled:
	;
	; length < 64, now. adjust to proper token range by adding one, then
	; store that sucker away.
	; 
		inc	ax			; (1-byte instruction)
		ECStosb
endLoopClearPending:
		mov	ss:[emptyPending], 0
endLoop:
	;
	; Switch to the off color and keep looping until we run out of bytes.
	; CH = byte
	; 
		mov	al, ch			; AL <- byte
		xchg	dl, dh
		jmp	mainLoop

startImageToken:
	;
	; Run too short to be worth creating a run token for it. If this is
	; because we used up all the bits filling an image token (rlen <= 0),
	; we can just loop, unless rlen is 0, in which case we must mark a zero
	; run as pending because it expects the run following an image token
	; to be for the color that's in the last pixel of the image token.
	;
		tst	bx
		js	endLoop
		jz	markPendingZero
	;
	; There are actually bits left over. Make them into an image token
	; as long as there's more than one byte left in the scanline, so we can
	; be sure we won't be left with a half-filled image token. If there's
	; only one left (or we've used them all up), just create a short run.
	;
		cmp	ss:[bytes], 1
		jle	storeRun

		mov	al, 0x80		; image token flag
if WHITE_BYTE eq 0
		or	al, dh			; image tokens use 1 == white,
						;  so use the inverse of the
						;  current color.
else
		or	al, dl			; use current color
endif
						;
		mov 	es:[di], al
		
	;
	; Figure the number of bits remaining in the image token and
	; loop.
	;
		sub	bx, 7
		neg	bx
		mov	ss:[obits], bx
	;
	; When we start an image token, we need to clear the pending flag, since
	; the color of the next run token depends on how the new token is
	; finished out, not on how the previous image token ended.
	;
		jmp	endLoopClearPending

markPendingZero:
	;
	; If there was an empty run pending before us, the two empty runs
	; cancel each other out. Else we need to stick in an empty run
	; before the next run of the other color to make sure the color
	; is correct for the next run.
	; 
		not	ss:[emptyPending]
		jmp	endLoop

checkBlankLine:
	;
	; Entire line is of the current color. If that color is white, we can
	; save a byte for the line by using the special BLANK_TOKEN value.
	;
		cmp	dl, WHITE_BYTE
		jne	storeRun

		mov	al, BLANK_TOKEN-1	; -1 for INC at over64Handled
		jmp	over64Handled
ConvertScanLine	endp

