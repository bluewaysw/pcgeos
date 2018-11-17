COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nimbusBitmaps.asm

AUTHOR:		Gene Anderson, May 27, 1990

ROUTINES:
	Name			Description
	----			-----------
	AllocBMap		Allocate a bitmap
	BMapBits		Flip bits in bitmap
	SetBit			Set a bit in bitmap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/27/90		Initial revision

DESCRIPTION:
	Assembly version of bitmap.c

	$Id: nimbusBitmap.asm,v 1.1 97/04/18 11:45:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocBMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a bitmap
CALLED BY:	MakeChar()

PASS:		ds - seg addr of NimbusVars
		(ax,bx),(cx,dx) - bounds of character
RETURN:		ds:guano - NimbusBitmap
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocBMap	proc	near
	uses	es, di
	.enter

	mov	ds:guano.NB_lox, ax		;q->lox = lox;
	mov	ds:guano.NB_hiy, dx		;q->hiy = hiy;
	sub	cx, ax
	inc	cx
	mov	ds:guano.NB_width, cx		;q->w = hix - lox + 1;
	sub	dx, bx
	inc	dx
	mov	ds:guano.NB_height, dx		;q->h = hiy - loy + 1;
	add	cx, 0x07
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1
	mov	ds:guano.NB_bytesperline, cx	;q->bpl = 1+((q->w - 1) >> 3);
	mov	ax, dx

	mov	bx, segment udata
	mov	es, bx				;es <- seg addr of udata
	call	ds:GenRouts.CGR_alloc_rout	;allocate bitmap or region

	.leave
	ret
AllocBMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and lock a block for use as a bitmap
CALLED BY:	AllocBMap()

PASS:		ds - seg addr of NimbusVars
		ax, dx - height of bitmap (in lines)
		cx - width of bitmap (in bytes)
		es - seg addr of udata
RETURN:		es:bitmapHandle - handle of bitmap
		ds:guano.NB_segment
DESTROYED:	ax, bx, cx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapAlloc	proc	near
	.enter

	mul	cx				;ax <- height * bytesperline
EC <	ERROR_C	FONT_CHAR_TOO_BIG		;>
	mov	cx, ax				;cx <- size (in bytes)
	mov	bx, es:bitmapHandle		;bx <- handle of our block
	cmp	ax, es:bitmapSize		;see if block big enough
	ja	reallocBlock			;branch if not big enough
	call	MemLock				;lock the block
	jnc	notDiscarded			;branch if still around
reallocBlock:
	mov	ax, cx				;ax <- size (in bytes)
	mov	es:bitmapSize, ax		;save new block size
	mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
	call	MemReAlloc			;reallocate as necessary
	mov	cx, es:bitmapSize		;cx <- size (in bytes)
notDiscarded:
	mov	es, ax				;es <- seg addr of data bytes
	mov	ds:guano.NB_segment, ax		;store seg addr

	clr	di
	clr	al
	rep	stosb				;initalize data bytes

	.leave
	ret
BitmapAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMapBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flip bits in a bitmap to right of given position
CALLED BY:	YPixelate()

PASS:		ds:guano - NimbusBitmap
		(cx,bp) - (x,y) point to invert from
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

first_bit	byte	0xFF, 0x7F, 0x3F, 0x1F, 0x0F, 0x07, 0x03, 0x01

BMapBits	proc	near
	uses	ds, si
	.enter

	;
	;/* convert coordinates to row/column indices */
	;
	;/* double check the indices */
	;
	mov	ax, ds:guano.NB_hiy
	sub	ax, bp				;ax <- bmap->hiy - y;
	jl	done				;if (r < 0)
	cmp	ax, ds:guano.NB_height
	jge	done				;if (r >= bmap->h)
	sub	cx, ds:guano.NB_lox		;cx <- x - bmap->lox;
	jns	colPositive			;if (c < 0) (set by sub)
	clr	cx				;c = 0;
colPositive:
	cmp	cx, ds:guano.NB_width		;if (c >= bmap->w)
	jb	colOK
	mov	cx, ds:guano.NB_width
	dec	cx				;c = bmap->w - 1;
colOK:
	;
	;/* find starting byte address, and bit number */
	;
	mul	ds:guano.NB_bytesperline	;ax <- (r*bmap->bpl)
	mov	bx, cx
	and	bx, 0x07			;bx <- (c & 7)
	mov	si, ax
	mov	ax, cx				;si <- (r*bmap->bpl)
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1				;ax <- (c >> 3)
	add	si, ax				;si <- p = (r*bmap->bpl)+(c>>3);
	;
	;/* flip trailing portion of first byte */
	;
	mov	dl, cs:first_bit[bx]		;dl <- first[bit];
	mov	cx, ds:guano.NB_bytesperline	;cx <- bmap->bpl;
	mov	ds, ds:guano.NB_segment		;ds <- seg addr of bitmap
	xor	{byte} ds:[si], dl		;*p ^= first[bit];
	inc	si				;p++
	;
	;/* flip remaining bytes */
	;
	sub	cx, ax				;r = bmap->bpl - (c >> 3);
flipLoop:
	dec	cx				;--r;
	jcxz	done
EC <	push	ax, bx				>
EC <	call	SysGetECLevel			>
EC <	test	ax, mask ECF_GRAPHICS		>
EC <	jz	afterAnalEC			>
EC <	call	DoAnalEC			>
EC <afterAnalEC:				>
EC <	pop	ax, bx				>
	xor	{byte} ds:[si], 0xFF		;*p ^= 0xFF;
	inc	si				;p++;
	jmp	flipLoop

done:
	.leave
	ret
BMapBits	endp

;
; Do anan-retentive error checking on the offset
; into the bitmap to catch any memory trashing.
;
EC <DoAnalEC	proc	near			>
EC <	push	cx, ds				>
EC <	mov	ax, segment udata 		>
EC <	mov	ds, ax				>
EC <	mov	bx, ds:bitmapHandle		>
EC <	mov	ax, MGIT_SIZE			>
EC <	call	MemGetInfo			>
EC <	cmp	si, ax				;cmp (ptr, block size)>
EC <	ERROR_AE	OVERDOSE		>
EC <	mov	cx, ds:bitmapSize		>
EC <	cmp	si, cx				;cmp (ptr, expected size)>
EC <	ERROR_AE	OVERDOSE		>
EC <	cmp	cx, ax				;cmp (expected size, block size>
EC <	ERROR_A	OVERDOSE			>
EC <	pop	cx, ds				>
EC <	ret					>
EC <DoAnalEC	endp				>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a bit in a bitmap.
CALLED BY:	CheckHoles()

PASS:		ds:guano - NimbusBitmap
		(bx, bp) - point to set in bitmap (not TRUNC'd)
RETURN:		none
DESTROYED:	ax, bx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

mask_bits	byte	0x80, 0x40, 0x20, 0x10, 0x8, 0x4, 0x2, 0x1

SetBit	proc	near
	TRUNC	bx				;TRUNC(x);
	TRUNC	bp				;TRUNC(y);
	;
	;/* convert coordinates to row/column indices */
	;
	sub	bx, ds:guano.NB_lox		;c = x - bmap->lox;
	js	done				;if (c < 0)
	mov	ax, ds:guano.NB_hiy
	sub	ax, bp				;r = bmap->hiy;
	js	done				;if (r < 0)
	;
	;/* double check the indices */
	;
	cmp	bx, ds:guano.NB_width		;if (c >= bmap->w)
	jae	done
	cmp	ax, ds:guano.NB_height		;if (r >= bmap->h)
	jae	done
	;
	;/* find starting byte address, and bit number, and set it */
	;
	push	ds
	mov	di, bx
	and	di, 0x7				;bit = c & 7;
	mul	ds:guano.NB_bytesperline	;(r * bmap->bpl)
EC <	ERROR_C	FONT_CHAR_TOO_BIG		;>
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1				;(c >> 3);
	add	ax, bx				;byte = (r*bmap->bpl)+(c>>3);
	mov	bl, cs:mask_bits[di]		;bl <- mask[bit];
	mov	di, ax
	mov	ds, ds:guano.NB_segment		;ds <- seg addr of bitmap
	ornf	ds:[di], bl			;bmap->bits[byte] |= mask[bit];
	pop	ds
EC <	push	ax, bx, si			>
EC <	call	SysGetECLevel			>
EC <	test	ax, mask ECF_GRAPHICS		>
EC <	jz	afterAnalEC			>
EC <	mov	si, di				;check di as offset>
EC <	call	DoAnalEC			>
EC <afterAnalEC:				>
EC <	pop	ax, bx, si			>
done:
	ret
SetBit	endp
