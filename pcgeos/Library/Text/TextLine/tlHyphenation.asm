COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlHyphenation.asm

AUTHOR:		John Wedgwood, Sep 24, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 9/24/92	Initial revision

DESCRIPTION:
	Code to do auto-hyphenation of words.

	$Id: tlHyphenation.asm,v 1.1 97/04/07 11:21:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextObscure	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyphenateWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hyphenate a word.

CALLED BY:	CalculateHyphenCallback
PASS:		*ds:si	= Instance
		dx.ax	= Word start
		cx.di	= Position where the word overflows the line.
			  We need to break *before* this offset
		bx 	= VTPA_hyphenationInfo		
	
RETURN:		carry set if hyphenation is not possible
		carry clear otherwise
			ax	= Offset into the word where we want to break
			di.cl	= Position in word where the hyphen character
				  starts (WBFixed). This is an offset from
				  the left edge of the word.
			dx.ch	= Width of the hyphen character in whatever
				  style the text is immediately before the
				  hyphen.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAX_CHARS_FOR_HYPHENATION	equ	32
BUFFER_SIZE_FOR_HYPHENATION	equ	33

HyphenateWord	proc	far
	uses	bp
wordBreak	local	dword		push	cx, di
	;
	; The offset into the text before which the word must be broken.
	;

SBCS <wordData	local	BUFFER_SIZE_FOR_HYPHENATION dup (char)		>
DBCS <wordData	local	BUFFER_SIZE_FOR_HYPHENATION dup (wchar)		>
	;
	; Contains the text of the word, null terminated
	;

textRange	local	VisTextRange
	;
	; Used by CopyWordIntoStackBuffer to hold the range of text which
	; the word occupies.
	;

textRef		local	TextReference
	;
	; A TextReference which is required by the code which extracts
	; the word from the text-stream.
	;

	.enter

ForceRef	textRef

;-----------------------------------------------------------------------------
	;
	; We copy the word (up to the some reasonable number of characters)
	; into a buffer on the stack.
	;
	call	CopyWordIntoStackBuffer		; wordData <- text (w/ NULL)
						; ax <- size (w/o NULL)

;-----------------------------------------------------------------------------
	;
	; We need to compute the position of the break offset as an offset
	; into the word. If this offset is larger than the number of bytes
	; we copied into our buffer, then we want to knock it down so that
	; it falls at some position in the buffer.
	;
	movdw	dxcx, wordBreak			; dx.cx <- break offset
	subdw	dxcx, textRange.VTR_start	; dx.cx <- offset into word
	
	;
	; The offset into the word should never be more than 64K...
	;
EC <	tst	dx							>
EC <	ERROR_NZ OFFSET_INTO_WORD_IS_GREATER_THAN_64K			>

	cmp	cx, ax				; Check for beyond buffer end
	jbe	breakOffsetOK
	mov	cx, ax				; cx <- legal offset
breakOffsetOK:

;-----------------------------------------------------------------------------
	;
	; Now that the word is in the buffer, we call the hyphenation code
	; passing it a pointer to the word, the minimum prefix size, the
	; minimum suffix size, the minimum word size, and the place we want
	; to break before. It returns us the offset at which to break the word.
	;

	lea	ax, wordData			; ss:ax <- ptr to buffer
	pushdw	ssax				; Pass ptr to buffer

	; bx = VTPA_hyphenationInfo. From this word of data, extract the 
	; min prefix, min suffix, and min word sizes (size 4 bits each)
	; and increment them since the actual range is 1-16 not 0-15.

	push	cx
	clr	ax
	mov	al, bl				; ax = 0,0,prefix,suffix
	mov	cl, 4				; cx = amount to shift ax
	shr	ax, cl				; ax = prefix - 1
	inc	ax				; ax = prefix
	pop	cx
	push	ax				; push min prefix size

	push	cx
	clr	ax
	mov	al, bl				; ax = 0,0,prefix,suffix
	mov	cx, 000Fh			; cx = bitmask
	and	ax, cx				; ax = suffix -1
	inc 	ax				; ax = suffix
	pop	cx
	push	ax				; push min suffix size

	push	cx
	clr	ax
	mov	al, bh				; ax = 0,0,maxlines,minword
	mov	cx, 000Fh			; cx = bitmask
	and	ax, cx				; ax = minword -1
	inc	ax				; ax = minword size
	pop	cx
	push	ax				; push min word size

	push	cx				; Pass max break position

	call	ChooseHyphenationPosition	; ax <- break pos

	tst	ax				; Check for no break possible
	jz	noHyphenation			; Branch if none possible

;-----------------------------------------------------------------------------
	;
	; ax	= The offset into the word where we want to do the hyphenation.
	;
	; We need to compute the width of the word at that position and
	; the width of the hyphen given that style. To do this, I compute
	; the range between where the word starts and where the break
	; occurs.
	;

	;
	; What follows is a strange way of adding the dword textRange.VTR_start
	; to a word (ax).
	;
	; The idea is that there is this "assumed" high-word of zero associated
	; with ax and since I want the result in dx.ax, the operations are:
	;	add	ax, VTR_start.low
	;	adc	<mystery>, VTR_start.high
	;	mov	dx, <mystery>
	;
	; This can reordered as I do below so no scratch register is needed
	;

doRange::
	push	ax				; Save break position
	add	ax, textRange.VTR_start.low	; dx.ax <- end of range
	mov	dx, textRange.VTR_start.high
	adc	dx, 0
	
	movdw	textRange.VTR_end, dxax		; Save end of range.
	
	;
	; Compute the distance to the hyphen in the word
	;
	push	bp
	lea	bp, textRange			; ss:bp -> VisTextRange
	call	ComputeRangeWidthAndHyphenWidth	; di.cl <- position of hyphen
						; dx.ch <- width of hyphen
	pop	bp
	pop	ax				; Restore break position
	
	;
	; ax	= Break position
	; di.cl	= Position of hyphen
	; dx.ch	= Width of hyphen
	;
	clc					; Signal: hyphenation possible

quit:
	;
	; Carry set if hyphenation is not possible.
	;
	.leave
	ret

noHyphenation:
	stc					; Signal: no hyphenation possible
	jmp	quit
HyphenateWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyWordIntoStackBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the word (up to MAX_CHARS_FOR_HYPHENATION) into a buffer
		on the stack.

CALLED BY:	HyphenateWord
PASS:		ss:bp	= Inheritable stack frame
		dx.ax	= Offset to start of word
RETURN:		wordData= The bytes of the word, null terminated
		ax	= Number of characters copied (not counting NULL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
    Side Effects:
	textRange	- Set to range of word in text
	textRef		- Set to a TextReference to the wordData buffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyWordIntoStackBuffer	proc	near
	uses	bx, cx, dx, di
	.enter	inherit	HyphenateWord
	;
	; Initialize the stack frame
	;
	movdw	textRange.VTR_start, dxax

	;
	; We try to get MAX_CHARS_FOR_HYPHENATION into the buffer, but
	; if there aren't that many in the object, we need to limit ourselves.
	;
	movdw	cxbx, dxax			; cx.bx <- word start
	adddw	cxbx, MAX_CHARS_FOR_HYPHENATION	; cx.bx <- end pos for get
	
	call	TS_GetTextSize			; dx.ax <- size of text
	cmpdw	cxbx, dxax			; Can't go past the end
	jbe	gotEndOffset
	movdw	cxbx, dxax
gotEndOffset:
	movdw	textRange.VTR_end, cxbx		; Finally, set the end
	
	;
	; Now that we have the range, we need to set up the reference.
	;
	mov	textRef.TR_type, TRT_POINTER
	lea	ax, wordData			; ss:ax <- ptr to buffer
	movdw	textRef.TR_ref.TRU_pointer.TRP_pointer, ssax
	
	;
	; Copy the text into the buffer, no null terminator
	;
	push	bp
	lea	bx, textRange
	lea	bp, textRef
	call	TS_GetTextRange			; dx.ax <- number copied
	pop	bp	

	;
	; Null terminate the buffer
	;
	mov	di, ax				; di <- offset to end
DBCS <	shl	di, 1				; char offset -> byte offset>
SBCS <	mov	{byte} wordData[di], 0		; Poof, null terminated>
DBCS <	mov	{wchar} wordData[di], 0		; Poof, null terminated>
	.leave
	ret
CopyWordIntoStackBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeRangeWidthAndHyphenWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the width of a range of text and the width of a
		hyphen character which is in the style of the last
		character in that range.

CALLED BY:	HyphenateWord
PASS:		*ds:si	= Instance
		ss:bp	= VisTextRange
RETURN:		di.cl	= Position of hyphen as offset from start of word
		dx.ch	= Width of hyphen in style of last char in range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeRangeWidthAndHyphenWidth	proc	near
				class	VisTextClass
	uses	ax, bx
	.enter

	; see CheckSoftHyphen for clues
	; see also CommonFieldTextPosition

	; push parameters to CommonFieldTextPosition
         	
	movdw	cxdx, ss:[bp].VTR_start		; offset to the start of range
	pushdw	cxdx

	movdw	axbx, ss:[bp].VTR_end		; offset to end of the range
	subdw	axbx, cxdx			; end - start = number of chars
	pushdw	axbx				; this is the constraint that
						; will be used, so pixel offset
						; is what will be found.

	mov	ax, 0x7fff			; pixel offset = big number
	push	ax				;

	clrdw	axbx				; space padding (none)
	pushdw	axbx

	call	CommonFieldTextPosition		; ax = text offset
						; cx = pixel offset into field
						
	mov	di, cx
	clr	cl				; (0 fraction)

	; get hyphen width
	;
	; note that for now we're just using GrCharWidth, which doesn't 
	; account for kerning, or other attributes. 
	;

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VTI_gstate	; di = handle to gstate
	mov	ax, C_HYPHEN	
	call	GrCharWidth		; dx.ah = width of hyphen
	mov	ch, ah			; dx.ch = width of hyphen
	pop	di

	.leave
	ret
ComputeRangeWidthAndHyphenWidth	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseHyphenationPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose a place to hyphenate a word.

CALLED BY:	HyphenateWord
PASS:		On stack:
		    wordPtr	- Pointer to the text of the word.
				  Null terminated.
		    minPrefix	- Minimum number of chars before any hyphen
		    minSuffix	- Minimum number of chars after any hyphen
		    minLength	- shortest word to hyphenate
		    maxBreakPos	- The absolute last position at which a
		    		  break can occur.
RETURN:		ax	= Position to break at
			  0 if no break is possible
		Cleans up the stack before returning (due to the "pascal"
			nature of the geos-conventions, see below)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

In C, this would be defined as:
    word ChooseHyphenationPosition(char *word, int wordSize, int maxBreakPos);

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	;
	; This macro defines the parameter ordering associated with pc/geos
	; and whether or not routines which take arguments on the stack also
	; clean them up before returning.
	;
	SetGeosConvention

ChooseHyphenationPosition	proc	far	wordPtr:fptr.char,
						minPrefix:word,
						minSuffix:word,
						minLength:word,
						maxBreakPos:word
	uses	bp, bx, cx, dx, di, es, si
	.enter

	; don't bother hyphenating if params say it's impossible

	clr	cx
	cmp	minPrefix, cx
	LONG jl	noHyphen		; if neg prefix length, exit
	cmp	minSuffix, cx
	LONG jl	noHyphen 		; if neg suffix length, exit
	mov	cx, maxBreakPos
	cmp	minPrefix, cx	
	jg	noHyphen		; if prefix past maxbreakpos, exit

	; get a list of hyphenation points for the word

	mov	ax, segment udata
	mov	es, ax
	movdw	bxax, es:[hyphenateWordEntryPoint]
	tst	bx			;If no hyphenation library loaded, 
	jz	noHyphen		; exit
	pushdw	wordPtr
	push	minLength
	call	ProcCallFixedOrMovable	; ^hbx = byte array of hyphen points
					; cx = length of word without null
	tst	ax
	jz	noHyphen		; if error, return no hyphenation
	mov_tr	bx, ax			;BX 

	; lock the array block

	push	bx			; save handle to array block
	call	MemLock			; ax = array seg

	;
	; Get the last hyphenation point before the maxBreakPos. If no
	; such points exist, return 0 
	;
	
	mov	es, ax			; es:di -> array of hyp points
	mov	di, offset HP_array
	clr	dx			; dx = best hyp point found (or 0 if 
					; none)
	mov	bx, es:[HP_wordLen]	; bx = length of hyphenated word
	sub	bx, minSuffix		; bx = max break pos with suffix
	cmp	bx, 0
	jle	freeBlockNoHyphen	; if end word pos - suffix < 0, no hyp.
	cmp	bx, maxBreakPos
	jg	useMaxBreakPos		; use min (maxBreakPos,maxSuffixPos)
maxBreakSet:
	mov	cx, minPrefix
	clr	ax
getHypPosLoop:
	mov	al, es:[di]		; ax = next hyp point
	tst	ax			; if ax = 0, no more hyp points, use dx
	jz	getHypPosLoopEnd	
	cmp	ax, bx			; if next hyp point past maxBreakPos
	jg	getHypPosLoopEnd	; 	then use dx
	cmp	ax, cx			; if next hyp point not past minPrefix
	jl	dontUsePoint		; 	then don't use this point
	mov	dx, ax			; else dx = better hyp point
dontUsePoint:
	inc	di			; es:di -> next hyp point
	jmp 	getHypPosLoop
getHypPosLoopEnd:
	mov	ax, dx	

	;
	; free the array block
	;
	pop	bx
	call	MemFree

exit:
	.leave
	ret
useMaxBreakPos:
	mov	bx, maxBreakPos
	jmp	maxBreakSet
freeBlockNoHyphen:
	pop	bx
	call	MemFree
noHyphen:
	clr	ax
	jmp	exit
ChooseHyphenationPosition	endp


TextObscure	ends

TextControlInit segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTSETHYPHENATIONCALL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		bx.ax - args to pass to ProcCallFixedOrMovable to call to
			get hyphenation position
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTSETHYPHENATIONCALL:far
TEXTSETHYPHENATIONCALL	proc	far
	.enter
	C_GetOneDWordArg	bx, ax, 	cx, dx
	push	ds
	mov	cx, segment idata
	mov	ds, cx
	movdw	ds:[hyphenateWordEntryPoint], bxax
	pop	ds
	.leave
	ret
TEXTSETHYPHENATIONCALL	endp

	;
	; This macro restores the default parameter ordering style.
	;
	SetDefaultConvention


TextControlInit ends
