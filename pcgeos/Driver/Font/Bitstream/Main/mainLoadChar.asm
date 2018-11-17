COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	GEOS Bitstream Font Driver
MODULE:		Main
FILE:		mainLoadChar.asm

AUTHOR:		Brian Chin

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
EXT	sp_load_char_data	load character data
EXT	tt_get_font_fragment	load character data
EXT	tt_release_font_fragment

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/8/93		Initial version.
	brianc	10/29/92	convert to assembly
	brianc	3/8/94		add truetype stuff

DESCRIPTION:
	This file contains GEOS Bitstream Font Driver routines.

	$Id: mainLoadChar.asm,v 1.1 97/04/18 11:45:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


	SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sp_load_char_data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	load character data

CALLED BY:	Bitstream C code

PASS:		sp_load_char_data(fix31 file_offset,
				fix15 num_bytes, fix15 buf_offset)

RETURN:		pointer to buff_t

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/29/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
sp_load_char_data	proc	far	file_offset:dword,
					num_bytes:word, buf_offset:word

	uses	ds, es, di

	.enter

	segmov	es, dgroup, ax

	clrdw	es:[charData].BT_no_bytes		; no bytes read yet
	mov	bx, es:[charGenBufferHandle]
	tst	es:[installFlag]
	jz	haveBuf
	mov	bx, es:[installCharGenBufferHandle]
haveBuf:
	call	MemDerefDS			; ds = char gen buf segment
	mov	bx, es:[fontFileHandle]
	tst	es:[installFlag]
	jz	haveFile
	mov	bx, es:[installFontFileHandle]
haveFile:
	segmov	es:[charData].BT_origin.segment, ds, ax
	mov	dx, buf_offset
	mov	es:[charData].BT_origin.offset, dx
	push	dx				; save buffer offset
	;
	; get font file offset from table if concatenated kanji font,
	; else used passed file offset
	;
	movdw	cxdx, file_offset		; assume not cancat kanji font
if DBCS_PCGEOS
	tst	es:[installFlag]
	jnz	notConcat			; not when installing
	test	es:[outputInfo].OI_kanjiFont, mask BKFF_KANJI
	jz	notConcat			; not Kanji font
	test	es:[outputInfo].OI_kanjiFont, mask BKFF_MULTI_FILE
	jnz	notConcat			; not concat Kanji font
	clr	ah
	mov	al, es:[outputInfo].OI_fontInstance.BFIID_SJISEntry
	mov	di, ax
	tst	di
	jz	haveOffset
	sub	di, 0x80
	cmp	di, 0x1f
	jbe	haveOffset
	sub	di, (0xe0-0x080-0x20)
haveOffset:
	shl	di, 1
	shl	di, 1			; * (size dword)
	mov	cx, es:[kanjiFontFilePosTable][di].high	; cxdx = start of file
	mov	dx, es:[kanjiFontFilePosTable][di].low
	adddw	cxdx, file_offset		; cxdx = desired offset
notConcat:
endif
	mov	di, dx				; cxdi = desired offset
	mov	al, FILE_POS_START
	call	FilePos
	cmpdw	dxax, cxdi
	pop	dx				; ds:dx = read into here
	jne	done
	mov	cx, num_bytes
	mov	al, 0
	call	FileRead
	jc	done				; error, no bytes read
	mov	es:[charData].BT_no_bytes.low, cx
done:
	mov	dx, es
	mov	ax, offset charData
	.leave
	ret
sp_load_char_data	endp


if PROC_TRUETYPE

;TRUETYPECODE	segment	word public 'CODE'
Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		tt_get_font_fragment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	load font data

CALLED BY:	Bitstream C code

PASS:		tt_get_font_fragment(ufix32 fid,
				ufix32 buf_offset, ufix32 buf_length)

RETURN:		*void

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
tt_get_font_fragment	proc	far	fid:dword,
					buf_offset:dword, buf_length:dword

	uses	ds, di
	.enter

	mov	bx, fid.low			; get file handle
	mov	cx, buf_offset.high
	mov	dx, buf_offset.low
	mov	di, dx
	mov	al, FILE_POS_START
	call	FilePos
	cmpdw	dxax, cxdi
	jne	error

EC <	tst	buf_length.high						>
EC <	ERROR_NZ	BITSTREAM_INTERNAL_ERROR			>
NEC <	jnz	error							>
	mov	ax, buf_length.low
	add	ax, size word			; room for handle
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jc	error

	mov	ds, ax
	mov	dx, size word
	mov	ds:[0], bx			; store buffer handle
	mov	bx, fid.low			; get file handle
	mov	cx, buf_length.low
	mov	al, 0
	call	FileRead
	jc	error				; error, no bytes read
	mov	dx, ds				; ds:ax = buffer
	mov	ax, size word
done:

	.leave
	ret

error:
	clr	dx, ax
	jmp	short done

tt_get_font_fragment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		tt_release_font_fragment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	load character data

CALLED BY:	Bitstream C code

PASS:		tt_release_font_fragment(void *ptr)

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
tt_release_font_fragment	proc	far	fontptr:fptr

	uses	ds
	.enter

	mov	bx, fontptr.segment
	tst	bx
	jz	done
	mov	ds, bx
	mov	bx, ds:[0]
	call	MemFree
done:

	.leave
	ret
tt_release_font_fragment	endp

;TRUETYPECODE	ends
Resident	ends

endif	;if PROC_TRUETYPE


if PROC_TYPE1

;TYPE1CODE	segment	word public 'CODE'
Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		get_byte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	load font data

CALLED BY:	Bitstream C code

PASS:		get_byte(char *next_char)

RETURN:		boolean

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
get_byte	proc	far	next_char:fptr

	uses	ds, es

	.enter

	segmov	es, dgroup, ax

	mov	bx, es:[fontFileHandle]
	tst	es:[installFlag]
	jz	haveFile
	mov	bx, es:[installFontFileHandle]
haveFile:
	mov	ds, next_char.segment
	mov	dx, next_char.offset
	mov	cx, 1
	mov	al, 0
	call	FileRead
	mov	ax, FALSE			; assume error
	jc	done				; error, no bytes read
	mov	ax, TRUE			; else, success
done:
	.leave
	ret
get_byte	endp

;TYPE1CODE	ends
Resident	ends

endif	;if PROC_TYPE1

	SetDefaultConvention
