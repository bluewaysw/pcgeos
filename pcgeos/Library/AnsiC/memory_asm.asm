COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Standard C Library
FILE:		memory_asm.asm

AUTHOR:		Andrew Wilson, Aug 23, 1991

ROUTINES:
	Name			Description
	----			-----------

Standard C routines:

	memchr			Return pointer to first occurrence of
				passed character in the given buffer.

	memcmp			Compare the first N bytes of the two
				given buffers.

	memcpy			Copies data from one passed buffer to the
				other given buffer as fast as possible.

	memmove			Same as memcpy but handle buffer overlap.

	memset			Sets each element of the given buffer to
				the given value.
	
Extensions:

	memccpy			Copies data from one passed buffer to the
				other. Will copy until passed char is
				copied, or until N bytes are copied.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/23/91		Initial revision.
	JDM	93.03.23	Updated to match the C language standard.

DESCRIPTION:
	C callable assembly language versions of the Standard C memory
	routines.

	$Id: memory_asm.asm,v 1.1 97/04/04 17:42:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	ansicGeode.def
include	geos.def
include	ec.def
include product.def

if SUPPORT_32BIT_DATA_REGS
.386		; For memcpy
endif

STRINGCODE	segment	word	public	'CODE'
.model	medium, pascal


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memchr_old
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported in the position of the old, buggy memchr.

CALLED BY:	External (old)
PASS:		see memchr
RETURN:		see memchr
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	memchr_old:far
memchr_old	proc	far
	REAL_FALL_THRU	MEMCHR
memchr_old	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memchr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the given array of unsigned characters of the given
		size for the first occurrence matching the given character.

CALLED BY:	External.

PASS:		const	void	*source	= Array to search.
		(For XIP system, *source can be pointing into the XIP
			movable code resource.)
		int		value	= Search for (unsigned char) val.
		size_t		count	= Length of array in characters.

RETURN:		void *	= NULL iff character not found.
			  Otherwise, pointer to the matching element.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Check for silly case of zero length.
	Search the given array for the given value.
	If not found then
		Set return pointer to NULL.
	Otherwise,
		Set return pointer to start of match.

KNOWN DEFECTS/CAVEATS/IDEAS:
	Note that this routine 'fails' if given a array length of zero (0).
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version.
	JDM	93.03.23	Big update.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	MEMCHR:far
memchr	equ	MEMCHR
MEMCHR	proc	far	source:fptr, value:word, count:word
	uses	di,es
	.enter
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, source					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	cx, count		; CX = Number of chars to search.
	jcxz	notFound		; Anything to search?  No, quit.

	les	di, source		; ES:DI = String to search.
	mov	ax, value		; AX = Character to search for.
	repne	scasb			; Search for it.
	jne	notFound		; Find it or bail.
	dec	di			; Found it.  Fix up pointer.
	mov	dx, es			; DX:AX = Pointer to match.
	mov	ax, di
exit:
	.leave
	ret

notFound:
	clr	ax, dx			; DX:AX = NULL.
	jmp	exit

MEMCHR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memcmp_old
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported in the position of the old, buggy memcmp.

CALLED BY:	External (old)
PASS:		see memcmp
RETURN:		see memcmp
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	memcmp_old:far
memcmp_old	proc	far
	REAL_FALL_THRU	MEMCMP
memcmp_old	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memcmp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the two given arrays of unsigned characters.

CALLED BY:	External.

PASS:		const void	*strOne	= First character array.
		const void	*strTwo	= Second character array.
		(For XIP system, the string ptrs can be pointing into the XIP
			movable code resource.)
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
	Check for a passed array length of zero (0).
	Compare the two given arrays until they don't match or length
	characters have been looked at.
	Subtract the last character looked at from strTwo from the last
	character looked at in strOne to produce the return value.

KNOWN DEFECTS/CAVEATS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version.
	JDM	93.03.23	Big update.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	MEMCMP:far
memcmp	equ	MEMCMP
MEMCMP	proc	far	strOne:fptr, strTwo:fptr, count:word
	uses	di,si,ds,es
	.enter
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid. Anyway, it shouldn't crash
	; for any circumstances because we are now in fixed code resource.
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, strOne					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, strTwo					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	; First, check for silly length.
	clr	ax			; Assume silly length.
	mov	cx, count		; CX = Number of chars to compare.
	jcxz	exit			; Exit iff CX == 0.

	; Compare the strings.
	les	di, strOne		; ES:DI = strOne.
	lds	si, strTwo		; DS:SI = strTwo.
	repe	cmpsb

	; Return difference of last two characters seen.
	mov	al, es:[di][-1]
	sub	al, ds:[si][-1]
	cbw
exit:
	.leave
	ret
MEMCMP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memcpy_old
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported in the position of the old, buggy memcpy.

CALLED BY:	External (old)
PASS:		see memcpy
RETURN:		see memcpy
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	memcpy_old:far
memcpy_old	proc	far
	REAL_FALL_THRU	MEMCPY
memcpy_old	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memcpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the first length characters from the second given
		buffer into the first buffer as fast as possible.

CALLED BY:	External.

PASS:		void		*dest	= Buffer to copy to.
		const void	*source	= Buffer to copy from.
		(For XIP system, *source can be pointing into the XIP movable
			code resource.)
		size_t		count	= Number of characters to copy.

RETURN:		void *	= 'dest' string.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:	????
	Copy the given number of characters from the source character array
	to the destination character array in the fastest possible manner.

KNOWN DEFECTS/CAVEATS/IDEAS:
	Note that as per the C language standard, this routine does *not*
	handle overlap since that is slower than the version that does.  If
	you want to not have to worry about buffer overlap then use the
	memmove function.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version.
	JDM	93.03.23	Big rewrite.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	MEMCPY:far
memcpy	equ	MEMCPY
MEMCPY	proc	far	dest:fptr, source:fptr, count:word
	uses	ds, si, es, di
	.enter

	; Check for any initial problems...
	les	di, dest		; ES:DI = destination string.
	lds	si, source		; DS:SI = source string.
	mov	cx, count		; CX = count.
	jcxz	exit			; Exit iff *no* number of chars...
	shr	cx			; Word-sized moves please.
if SUPPORT_32BIT_DATA_REGS
	lahf				; Save carry flag for odd byte move
	shr	cx			; DWord-sized moves please.
	rep	movsd			; Move it!
	jnc	noWords			; Carry flag set from second shr.
	movsw				; Copy the odd word
noWords:
	sahf				; Restore carry flag from first shr.
else
	rep	movsw			; Move it!
endif
	jnc	exit			; Carry flag set from shr above.
	movsb				; Move odd byte if necessary.
exit:
	mov	dx, es			; Return ptr to dest in DX:AX.
	mov	ax, dest.offset
	.leave
	ret
MEMCPY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memmove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the given 'count' char's from the 'source' string to
		the given 'destination' string.

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
	Copy the given number of characters from the source character array
	to the destination character array allowing for the overlap.

	If no overlap then copy the arrays in the 'forward' direction.
	Otherwise, copy the arrays in the 'backwards' direction to ensure
	that the value is read from the source array before it has been
	overwritten in the destination array.

KNOWN DEFECTS/CAVEATS/IDEAS:
	Note that this assumes that the source and destination character
	arrays overlap *only* if the segment registers are the same!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.03.22	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	MEMMOVE:far
memmove	equ	MEMMOVE
MEMMOVE	proc	far	destin:fptr, source:fptr, count:word
	uses	ds, si, es, di
	.enter

	; Check for any initial problems...
	les	di, destin		; ES:DI = destination string.
	mov	dx, es			; Return ptr to dest in DX:AX.
	mov	ax, di
	lds	si, source		; DS:SI = source string.
	mov	cx, count		; CX = count.
	jcxz	exit			; Exit iff *no* number of chars...

	; Check for array overlap...  (See note in header.)
	mov	bx, ds
	cmp	dx, bx			; Segments different?
	jne	forward			; Yep.  Move it!

	; Assert:
	;	Source & destination segments are equal.
	;
	; If the destination offset comes before the source offset then no
	; need to worry about overlap since things will work already.
	cmp	di, si			; Destination < Source?
	jb	forward			; Yep.  Move it!

	; Assert:
	;	Source & destination segments are equal.
	;	Source offset <= Destination offset.
	;
	; If the end of the source array comes *after* the start of the
	; destination array then the arrays overlap and so we'll have to
	; copy the arrays from the ends to the beginning.
	mov	bx, si			; BX = Source offset.
	add	bx, cx			; BX += Character count.
	cmp	bx, di			; Overlap?
	jbe	forward			; Nope.  Move it!

	; Assert:	Arrays overlap.
	;
	; Fix-up each array pointer to point to the end of the array.
	mov	si, bx			; BX from above.
	dec	si			; DS:SI = End of source array.
	add	di, cx			; DI += Character count.
	dec	di			; ES:DI = End of destinatation.

	std				; Move backwards through strings.
	shr	cx			; Move words.
	jnc	backward		; => no extra byte to move.
	movsb				; Move final byte, since buffers...
					; ...tend to be word-aligned.
backward:
	dec	si			; Point to initial word to move...
	dec	di			; ...not final byte.
	rep	movsw			; Move it!
	cld				; Clean up after ourselves.
	jmp	exit

forward:
	shr	cx			; Word-sized moves please.
	rep	movsw			; Move it!
	jnc	exit			; Carry flag set from shr above.
	movsb				; Move odd byte if necessary.
exit:
	.leave
	ret
MEMMOVE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memset_old
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported in the position of the old, buggy memset.

CALLED BY:	External (old)
PASS:		see memset
RETURN:		see memset
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	memset_old:far
memset_old	proc	far
	REAL_FALL_THRU	MEMSET
memset_old	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memset
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

	Asserts:	The first 'length' number of characters of the
			'target' string has been set to the given 'value'.

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Check for silly zero (0) array length.
	Write the value to the array by word-sized writes for efficiency
	(write the odd byte at the end iff needed).

KNOWN DEFECTS/CAVEATS/IDEAS:
	Assumes that the string begins on a word-sized boundary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version
	JDM	93.03.23	Big update.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	MEMSET:far
memset	equ	MEMSET
MEMSET	proc	far	target:fptr, value:word, count:word
	uses	di, es
	.enter

	les	di, target		; ES:DI = String to set.
	mov	dx, di			; ES:DX = String to set.
	mov	cx, count		; CX = Number of bytes to write.
	jcxz	exit			; Bail iff no bytes to write.
	mov	ax, value		; AL = (unsigned char) value;
	mov	ah, al			; Duplicate value for setting...
	shr	cx			; ...by word sized writes.
	rep	stosw			; Write it!
	jnc	exit			; Skip odd byte move if not needed.
	stosb				; Store odd byte.
exit:
	mov_trash	ax, dx		; ES:AX = String to set.
	mov	dx, es			; DX:AX = String to set.

	.leave
	ret
MEMSET	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Non-Standard C Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memccpy_old
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported in the position of the old, buggy memcpy.

CALLED BY:	External (old)
PASS:		see memccpy
RETURN:		see memccpy
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	memccpy_old:far
memccpy_old	proc	far
	REAL_FALL_THRU	MEMCCPY
memccpy_old	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		memccpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy characters from the first given string to the second
		until either the given character is seen or at most the
		given number of characters have been copied.

CALLED BY:	External.

PASS:		void		*destin	= String to copy to.
		const void	*source	= String to copy from.
		(For XIP system, *source can be pointing into the movable
			XIP code resource.)
		int		value	= Stop on (unsigned char) value.
		size_t		count	= Maximum number of chars to copy.

RETURN:		Void.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None

PSEUDO CODE/STRATEGY:
	Figure out the index of the character 'value' that can stop the
	copy.
	Number of characters to copy = Min (Length, index of 'value').
	Use memmove() to actually move the characters.

KNOWN DEFECTS/CAVEATS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 8/91		Initial version.
	JDM	93.03.23	Big update.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	MEMCCPY:far
memccpy	equ	MEMCCPY
MEMCCPY	proc	far	destin:fptr, source:fptr, value:word, count:word
	uses	di,es
	.enter

	; Figure out the index of the given character in the source buffer.
	mov	cx, count		; CX = Max. number of chars.
	jcxz	errorExit		; Nothing to do...
	les	di, source		; ES:DI = Source buffer.
	mov	ax, value		; AL = (unsigned char) value.
	repne	scasb			; CX == # of bytes *not* to copy.
	neg	cx			; CX = -CX.
	add	cx, count		; CX = # of bytes to copy.

	; Now pass on all of the real arguments to memmove().
	; Use pascal calling convention (left to right argument push'age).
	pushdw	destin
	pushdw	source
	push	cx			; Number of characters to copy.
	call	memmove			; DX:AX == Destination buffer.

exit:
	.leave
	ret

errorExit:
	movdw	dxax, destin		; DX:AX = Destination buffer.
	jmp	exit

MEMCCPY	endp


STRINGCODE	ends
