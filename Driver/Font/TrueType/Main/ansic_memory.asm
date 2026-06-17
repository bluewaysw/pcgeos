STRINGCODE	segment	word	public	'CODE'
.model	medium, pascal

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MEMCMP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Compare the two given arrays of unsigned characters.

CALLED BY:	External.

PASS:		const void	*strOne	= First character array.
		const void	*strTwo	= Second character array.
		(For XIP system, the string ptrs can be pointing into the
			XIP movable code resource.)
		size_t		count	= Length of arrays in characters.

RETURN:		int	= 0 iff all elements equal.
			  > 0 iff the differing element from strOne is
				greater than the element from strTwo.
			  < 0 iff the differing element from strOne is
				less than the element from strTwo.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????
	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Bail out early on zero count.
	Compare word-wise via repe cmpsw for speed.
	If a differing word is found, back up one word and re-compare
	byte-wise to find the exact differing byte.
	If all words matched, compare the trailing odd byte if present.
	Subtract the strTwo byte from the strOne byte to produce the
	signed return value (cbw to extend to int).

KNOWN DEFECTS/CAVEATS/IDEAS:
	Assumes both strings begin on word-sized boundaries for maximum
	efficiency. Byte-granular fallback handles odd trailing byte.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version.
	JDM	93.03.23	Big update.
	JK	23.05.2026	AI supported optimization:
				- word-wise compare via repe cmpsw
				- carry trick for odd trailing byte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	MEMCMP:far
memcmp	equ	MEMCMP
MEMCMP	proc	far	strOne:fptr, strTwo:fptr, count:word
	uses	di, si, ds, es
	.enter

if FULL_EXECUTE_IN_PLACE
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, strOne					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, strTwo					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

;	Bail out early on zero count -- return 0 (arrays "equal").
	clr	ax			; Assume equal / zero count.
	mov	cx, count
	jcxz	exit

	les	di, strOne		; ES:DI = strOne
	lds	si, strTwo		; DS:SI = strTwo

;	Word-wise compare: 2 bytes per iteration instead of 1.
;	CF from shr tells us if count was odd (trailing byte pending).
	shr	cx, 1			; CX = count/2; CF = count & 1
	repe	cmpsw			; Compare word-wise
	jnz	wordsDiffer		; Branch if a differing word was found

;	All full words matched. Check for trailing odd byte (CF from shr).
	jnc	exit			; CF=0: even count, all bytes equal
	cmpsb				; CF=1: compare the one remaining byte
	jz	exit			; Bytes equal: return 0 in AX
	jmp	calcDiff		; Bytes differ: compute return value

wordsDiffer:
;	A differing word was found. Back up one word and re-compare
;	byte-wise to identify which byte differs and compute the
;	signed difference correctly.
	dec	di			; \  Back up both pointers by one
	dec	di			;  > word (2 bytes) to re-examine
	dec	si			; |  the differing word byte-by-byte.
	dec	si			; /
	cmpsb				; Compare first byte of differing word
	jnz	calcDiff		; First byte differs: compute diff
	cmpsb				; First byte equal: second byte differs

calcDiff:
;	ES:DI-1 and DS:SI-1 point to the two differing bytes.
;	Compute signed difference for int return value.
	mov	al, es:[di-1]		; AL = strOne differing byte
	sub	al, ds:[si-1]		; AL = strOne[i] - strTwo[i]
	cbw				; Sign-extend to int (AX)

exit:
	.leave
	ret
MEMCMP	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MEMCPY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Copy the first count characters from source into dest
		as fast as possible.

CALLED BY:	External.

PASS:		void		*dest	= Buffer to copy to.
		const void	*source	= Buffer to copy from.
		(For XIP system, *source can be pointing into the XIP
			movable code resource.)
		size_t		count	= Number of characters to copy.

RETURN:		void *	= 'dest' pointer.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????
	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Bail out early on zero count.
	Save low bits of count before shifting to avoid lahf/sahf:
		Bit 0 = trailing odd byte pending.
		Bit 1 = trailing odd word pending (32-bit path only).
	For 386+:
		Copy dword-wise, then handle word/byte remainders via
		direct bit tests on saved count.
	For 8086/286:
		Copy word-wise via rep movsw.
		Use carry directly from shr for trailing odd byte.
	Return original dest pointer in DX:AX.

KNOWN DEFECTS/CAVEATS/IDEAS:
	Does *not* handle overlapping buffers -- use memmove for that.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version.
	JDM	93.03.23	Big rewrite.
	JK	23.05.2026	AI supported optimization:
				- replaced lahf/sahf with bit-test on saved
				- count: same fix as memset.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	MEMCPY:far
memcpy	equ	MEMCPY
MEMCPY	proc	far	dest:fptr, source:fptr, count:word
	uses	ds, si, es, di
	.enter

	les	di, dest		; ES:DI = destination
	lds	si, source		; DS:SI = source
	mov	cx, count
	jcxz	exit			; Nothing to copy

	shr	cx, 1			; CX = count/2; CF = count & 1

if SUPPORT_32BIT_DATA_REGS
;	Save low 2 bits of count before the second shr destroys them.
;	Bit 0 = trailing odd byte, bit 1 = trailing odd word.
;	This avoids lahf/sahf entirely (8 cycles saved).
	mov	bx, cx			; BX = count/2 (remainder bits)
	shr	cx, 1			; CX = count/4; CF = (count/2) & 1
	rep	movsd			; Copy dword-wise

	test	bx, 1			; Odd word remaining?
	jz	noByte			;  (bit 0 of count/2 = bit 1 of count)
	movsw				; Copy trailing word
noByte:
	test	count, 1		; Odd byte remaining?
	jz	exit			;  (original bit 0 of count)
	movsb				; Copy trailing byte

else
;	16-bit path (8086/286): copy word-wise.
;	Carry from shr above is still live -- use it directly.
	rep	movsw			; Copy word-wise
	jnc	exit			; CF=0: even count, done
	movsb				; CF=1: copy trailing odd byte

endif

exit:
	mov	dx, es			; DX:AX = original dest pointer
	mov	ax, dest.offset
	.leave
	ret
MEMCPY	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MEMMOVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Copy the given 'count' chars from 'source' to 'destin',
		correctly handling overlap between the two buffers.

CALLED BY:	External.

PASS:		const void	*destin	= String to copy to.
		void		*source	= String to copy from.
		(For XIP system, *source can be pointing into the XIP
			movable code resource.)
		size_t		count	= Number of characters to copy.

RETURN:		void *	= 'destin' string.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????
	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Bail out early on zero count.
	Overlap is only detected when source and destination segments
	are equal (see KNOWN DEFECTS below).
	If dest < source, or source+count <= dest: copy forward.
	Otherwise (overlap): copy backward via std/rep movsw/cld.
	Forward path:
		Save low bits of count before shifting to avoid lahf/sahf.
		For 386+: copy dword-wise, handle word/byte remainders
		via bit tests on saved count.
		For 8086/286: copy word-wise, use carry from shr for
		trailing odd byte.
	Backward path:
		Advance pointers to end of buffers.
		Copy odd trailing byte first (buffers tend to be word-
		aligned, so the odd byte is at the high end).
		Copy word-wise backwards via rep movsw with DF set.
		Clear DF unconditionally before exit.

KNOWN DEFECTS/CAVEATS/IDEAS:
	Overlap is only detected when source and destination segment
	registers are equal.  Cross-segment overlap is not handled.
	DF is always restored to 0 (forward) before exit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.03.22	Initial version.
	JK	23.05.2026	AI supported optimization:
				- replaced lahf/sahf with bit-test on saved
				- count (forward path)
				- backward path: word-wise copy retained as-is
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	MEMMOVE:far
memmove	equ	MEMMOVE
MEMMOVE	proc	far	destin:fptr, source:fptr, count:word
	uses	ds, si, es, di
	.enter

	les	di, destin		; ES:DI = destination string
	mov	dx, es			; Save dest segment for return value
	mov	ax, di			; Save dest offset for return value
	lds	si, source		; DS:SI = source string
	mov	cx, count
	jcxz	exit			; Nothing to copy

;	Check for overlap (only meaningful when segments are equal).
	mov	bx, ds
	cmp	dx, bx			; Same segment?
	jne	forward			; Different segments: copy forward

	cmp	di, si			; dest < source?
	jb	forward			; No overlap possible: copy forward

;	Assert: same segment, dest >= source.
;	Overlap exists iff source + count > dest.
	mov	bx, si
	add	bx, cx			; BX = source + count
	cmp	bx, di			; source+count <= dest?
	jbe	forward			; No overlap: copy forward

;	Assert: buffers overlap; copy backward to avoid clobbering source.
;
;	Advance SI to last byte of source, DI to last byte of dest.
;	BX already holds source+count (= one past end of source).
	mov	si, bx
	dec	si			; DS:SI = last byte of source
	add	di, cx
	dec	di			; ES:DI = last byte of dest

	std				; Copy backwards

;	Copy odd trailing byte first (high end) so that the bulk of the
;	copy proceeds on word-aligned addresses.
	shr	cx, 1			; CX = count/2; CF = count & 1
	jnc	backward		; Even count: no trailing byte
	movsb				; Copy odd high byte

backward:
;	Back up both pointers by one more so they point to the last full
;	word rather than the byte we just copied (or the last byte if
;	count was even).
	dec	si
	dec	di
	rep	movsw			; Copy word-wise backwards
	cld				; Restore direction flag
	jmp	exit

forward:
	shr	cx, 1			; CX = count/2; CF = count & 1

if SUPPORT_32BIT_DATA_REGS
;	Save low bits of count/2 before second shr destroys CF.
;	Bit 0 of BX = trailing odd word; bit 0 of count = trailing odd byte.
;	This avoids lahf/sahf entirely (8 cycles saved).
	mov	bx, cx			; BX = count/2 (remainder bits)
	shr	cx, 1			; CX = count/4; CF = (count/2) & 1
	rep	movsd			; Copy dword-wise

	test	bx, 1			; Odd word remaining?
	jz	noWord
	movsw				; Copy trailing word
noWord:
	test	count, 1		; Odd byte remaining?
	jz	exit
	movsb				; Copy trailing byte

else
;	8086/286: copy word-wise; carry from shr is still live.
	rep	movsw			; Copy word-wise
	jnc	exit			; CF=0: even count, done
	movsb				; CF=1: copy trailing odd byte

endif

exit:
	.leave
	ret
MEMMOVE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MEMSET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Store the given character in each of the elements of the
		given character array.

CALLED BY:	External.

PASS:		void	*target		= String to store into.
		int	value		= Set each element to
					  (unsigned char) val.
		size_t	count		= Number of replications.

RETURN:		void *	= 'target' string.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????
	Asserts:	The first 'count' number of characters of the
			'target' string has been set to the given 'value'.

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Bail out early on zero count.
	Build word (and dword if 386+) fill value by duplicating
	the byte value across all positions.
	For 386+:
		Save remainder bits from count before shifting.
		Fill dword-wise, then handle word and byte remainders
		via direct bit tests on saved count -- no flag
		save/restore needed.
	For 8086/286:
		Fill word-wise via rep stosw.
		Use carry directly from the shift to handle the
		trailing odd byte -- no lahf/sahf needed.
	Return original target pointer in DX:AX.

KNOWN DEFECTS/CAVEATS/IDEAS:
	Assumes that the string begins on a word-sized boundary.
	The 32-bit path requires a 386 or better (SUPPORT_32BIT_DATA_REGS).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version
	JDM	93.03.23	Big update.
	JK	23.05.26	AI supported optimization:
				- removed lahf/sahf overhead
				- fill-value construction bug (or ax,dx)
				- 8086-safe carry trick for 16-bit path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	MEMSET:far
memset	equ	MEMSET
MEMSET	proc	far	target:fptr, value:word, count:word
	uses	di, es
	.enter

	mov	cx, count		; CX = number of bytes to write
	jcxz	exit			; Bail iff no bytes to write

	les	di, target		; ES:DI = destination string
	mov	dx, di			; ES:DX = destination (for return value)

	mov	ax, value		; AL = (unsigned char) value
	mov	ah, al			; Duplicate byte to fill word: AH=AL=val

if SUPPORT_32BIT_DATA_REGS
;	Build dword fill value in EAX: all 4 bytes = val.
;	We save AX first because shl eax,16 destroys the word value.
;	Note: do NOT use "or ax, dx" here -- DX holds the target pointer,
;	not the fill value. That would corrupt every 4th byte.
	mov	bx, ax			; BX = val:val (save before shl)
	shl	eax, 16			; EAX = val:val:00:00
	mov	ax, bx			; EAX = val:val:val:val

;	Save the low 2 bits of count now, before shr destroys them.
;	This lets us test for word/byte remainders without lahf/sahf.
	mov	bx, cx			; BX = original count (remainder bits)
	shr	cx, 2			; CX = count / 4 (dword iterations)
	rep	stosd			; Fill dword-wise

	test	bx, 2			; Odd number of words remaining?
	jz	noWord
	stosw				; Write trailing word
noWord:
	test	bx, 1			; Odd byte remaining?
	jz	exit
	stosb				; Write trailing byte

else
;	16-bit path (8086/286): fill word-wise, handle odd byte via carry.
;	shr sets carry iff count was odd -- use it directly instead of
;	wasting 8 cycles on lahf/sahf.
	shr	cx, 1			; CX = count / 2; CF = count & 1
	rep	stosw			; Fill word-wise
	jnc	exit			; CF=0: even count, we are done
	stosb				; CF=1: write the trailing odd byte

endif

exit:
	mov	ax, dx			; DX:AX = original target pointer
	mov	dx, es
	.leave
	ret
MEMSET	endp

STRINGCODE	ends
