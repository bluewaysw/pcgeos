COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit/Document
FILE:		documentParse.asm

AUTHOR:		Cassie Hartzog, Nov  3, 1992

ROUTINES:
	Name			Description
	----			-----------
	PutStringInItem		Allocates an item and copies the text string 
				from the geode into it. 
	PutDataInItem		Allocates and item and copies the data into it. 
	StoreMoniker		Chunk may contain either a text or gstring 
				moniker. Put it into an item and update the 
				ResourceArrayElement. 
	StoreBitmap		chunk contains a bitmap, put it into an item in 
				the Resource's group. 
	StoreGString		chunk is a gstring structure, put it into an 
				item and update the RAD_origItem field. 
	StoreText		Chunk contains plain ol' text. Copy it into a 
				DBItem and store the info in the 
				ResourceArrayElement. 
	CheckIfBitmap		Determines if passed chunk points to a bitmap. 
	CalculateBitmapChunkSize	To check if this chunk could really 
				contain a bitmap, we need to see how big the 
				chunk would have to be to contain a bitmap of 
				the given height and width, in the given 
				format. 
	DocumentCalcPackbitsBytes	Calc number of bytes in a 
				packbits-compacted scan line 
	DocumentCalcLineSize	Calculate the line width (bytes) for a scan 
				line of a bitmap 
	CheckIfText		validate that ds:si points to a text string 
	CheckIfGString		Validate that chunk contains a gstring. 
	CheckForGStringOptrs	Look for gstring elements which draw from 
				optrs. 
	CheckForGStringOptrsCallback	 
	DBCSCheckFirstTwoWords	Are the first two characters valid DBCS ASCII? 
	CheckIfMoniker		Determine if the passed chunk contains a 
				moniker. 
	CheckIfUIObject		Determines whether the passed lmem chunk 
				contains an object subclassed off the passed 
				class, library. 
	CheckLibraryEntry	See if cx is an entry point for the passed 
				library. 
	CheckExportedEntry	Checks to see if cx is the correct exported 
				class 
	CheckIfSubclass		Given two entry points into the UI library, 
				determine if one is a subclass of the other. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	11/ 3/92	Initial revision


DESCRIPTION:
	Contains code which parses chunks and stores their data
	in DB items.

	$Id: documentParse.asm,v 1.1 97/04/04 17:14:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DocumentParseCode	segment resource
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutStringInItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates an item and copies the text string from the 
		geode into it.

CALLED BY:	StoreText
PASS:		ss:bp	- parse frame
		ds:si	- ptr to text
		dx	- TextStringArgs

RETURN:		di	= item number
DESTROYED:	es

PSEUDO CODE/STRATEGY:
	If the text string has UserDoDialog string arguments, output
	the 'at' character in front of it in the string copied to the item.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutStringInItem		proc	near
	uses	ax,bx,cx,dx
	.enter

	; if no string args, copy the whole chunk into item
	;
	tst	dx
	jnz	stringArgs
	call	PutDataInItem

done:	
	.leave
	ret

stringArgs:
	; get the size of the string, plus an extra char for each string arg
	;
	mov	cx, ss:[bp].PF_size
	mov	al, dh
	clr	ah, dh
	add	cx, ax				; ax <- # of '\1'string args
DBCS <	add	cx, ax							>
	add	cx, dx				; dx <- # of '\1'string args
DBCS <	add	cx, dx							>

haveSize::
	mov	bx, ss:[bp].PF_transFile
	mov	ax, ss:[bp].PF_group
	call	DBAlloc				; allocate item for text

	; lock the item and copy the text string into it
	;
	push	di				; save item #
	call	DBLock				; *es:di <- dbitem
	call	DBDirty
	mov	di, es:[di]			; es:di <- destination
	mov	cx, ss:[bp].PF_size		; cx <- # bytes in string
DBCS <	shr	cx, 1				; cx <- # chars in string	>
	mov	al, 1				; initialize to non-zero

charLoop:
EC <	LocalIsNull	ax			>
EC <	ERROR_Z	STRING_LENGTH_INCORRECT		>
	LocalGetChar	ax, dssi		; a[lx] <- next char
	LocalIsNull	ax			; is this the NULL?
	jz	storeChar
	LocalCmpChar	ax, 2			; is it a string arg 1 or 2?
	ja	storeChar
SBCS <	mov	{byte}es:[di], '@'					>
DBCS <	mov	{word}es:[di], C_COMMERCIAL_AT				>
	LocalNextChar	esdi
SBCS <	add	al, '0'				; get printable digit	>
DBCS <	add	ax, '0'				; get printable digit	>
storeChar:
	LocalPutChar	esdi, ax
	loop	charLoop

	call	DBUnlock			; unlock the item
	pop	di				; return the item
	jmp	done

PutStringInItem		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutDataInItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates and item and copies the data into it.

CALLED BY:	StoreBitmap, StoreGString
PASS:		ss:bp	- parse frame
		ds:si	- ptr to data

RETURN:		di	= item number
DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutDataInItem		proc	near
	uses	ax,bx,cx,si
	.enter

	mov	bx, ss:[bp].PF_transFile
	mov	ax, ss:[bp].PF_group

	; get the number of bytes to allocate
	;
	mov	cx, ss:[bp].PF_size
	call	DBAlloc				

	; lock the item and copy the data into it
	;
	push	di				; save item #
	call	DBLock				; *es:di <- dbitem
	call	DBDirty
	mov	di, es:[di]			; es:di <- destination
	rep	movsb

	call	DBUnlock			; unlock the item
	pop	di				; return the item

	.leave
	ret
PutDataInItem		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Chunk may contain either a text or gstring moniker.
		Put it into an item and update the ResourceArrayElement.

CALLED BY:	ParseUnknownChunks, ParseChunk

PASS:		ss:bp	- ParseFrame

RETURN:		carry set if moniker sucessfully stored, or if it
		is recognized as a moniker list entry.

DESTROYED:	ax,bx,cx

PSEUDO CODE/STRATEGY:
	The chunk may or may not contain a moniker. 
	First check if it has the correct moniker structure, and check
	if it really contains text or gstring, according to moniker type.
	Then save the moniker.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreMoniker		proc	far
	uses	si,di,dx,ds
	.enter
	
	; Dereference the chunk being examined
	;
	movdw	bxsi, ss:[bp].PF_object
	call	MemDerefDS
	mov	si, ds:[si]				

	; check if it is a moniker, check if gstring or text, and
	; get the mnemonic if there is one
	; 
	call	CheckIfMoniker				;dx <- ChunkType
	jnc	done

	; if not either text or gstring, it's not a moniker
	;
	clc
	test	dl, (mask CT_TEXT or mask CT_GSTRING)
	jz	done

	; get a pointer to the moniker data
	;
	movdw	bxsi, ss:[bp].PF_object
	call	MemDerefDS
	mov	si, ds:[si]				;ds:si <- VisMoniker

	call	PutDataInItem				;di <- item number
	push	di

	movdw	bxsi, ss:[bp].PF_resArray
	call	MemDerefDS
	mov	ax, ss:[bp].PF_element
	call	ChunkArrayElementToPtr
EC < 	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND			>

	pop	ds:[di].RAE_data.RAD_origItem
	mov	bl, ss:[bp].PF_mnemonic
	mov	ds:[di].RAE_data.RAD_mnemonicType, bl
SBCS <	mov	bl, ss:[bp].PF_mnemonicChar				>
DBCS <	mov	bx, ss:[bp].PF_mnemonicChar				>
SBCS <	mov	ds:[di].RAE_data.RAD_mnemonicChar, bl			>
DBCS <	mov	ds:[di].RAE_data.RAD_mnemonicChar, bx			>
	ornf	ds:[di].RAE_data.RAD_chunkType, dl
	ornf	ds:[di].RAE_data.RAD_chunkType, mask CT_MONIKER
	stc

done:
	.leave
	ret

StoreMoniker		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	chunk contains a bitmap, put it into an item in the 
		Resource's group.

CALLED BY:	ParseUnknownChunks, ParseChunk

PASS:		ss:bp	- parse frame

RETURN:		carry set if a bitmap was stored

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreBitmap		proc	far
	uses	si,di,ds
	.enter

	;
	; Dereference the chunk being examined
	;
	movdw	bxsi, ss:[bp].PF_object
	call	MemDerefDS
	mov	si, ds:[si]

	call	CheckIfBitmap
	jnc	done

	call	PutDataInItem			;di <- DBItem for data

	movdw	bxsi, ss:[bp].PF_resArray
	call	MemDerefDS
	mov	bx, di				;bx <- new DBItem
	mov	ax, ss:[bp].PF_element
	call	ChunkArrayElementToPtr		;ds:di <- ResourceArrayElement
EC < 	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND			>

	mov	ds:[di].RAE_data.RAD_origItem, bx
	ornf	ds:[di].RAE_data.RAD_chunkType, mask CT_BITMAP
	inc	ss:[bp].PF_number
	stc
done:
	.leave
	ret
StoreBitmap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	chunk is a gstring structure, put it into an item and 
		update the RAD_origItem field.

CALLED BY:	ParseUnknownChunks, ParseChunk

PASS:		ss:bp	- parse frame
		carry	- set to check gstring, clear to skip check

RETURN:		carry set if it is a valid gstring and was added

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreGString		proc	far
	uses	si,di,ds
	.enter

	; Dereference the chunk being examined
	;
	movdw	bxsi, ss:[bp].PF_object
	call	MemDerefDS
	mov	si, ds:[si]				

	jnc	noCheck
	call	CheckIfGString			;validate that it is gstring
	jnc	done				;not valid, don't store it

noCheck:	
	call	PutDataInItem			;di <- DBItem for data

	movdw	bxsi, ss:[bp].PF_resArray
	call	MemDerefDS
	mov	bx, di				;bx <- new DBItem
	mov	ax, ss:[bp].PF_element
	call	ChunkArrayElementToPtr		;ds:di <- ResourceArrayElement
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND			>

	mov	ds:[di].RAE_data.RAD_origItem, bx
;	clr	ds:[di].RAE_data.RAD_transItem
	ornf	ds:[di].RAE_data.RAD_chunkType, mask CT_GSTRING
	inc	ss:[bp].PF_number
	clr	ss:[bp].PF_mnemonic
	stc
done:
	.leave
	ret
StoreGString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Chunk contains plain ol' text.  Copy it into a DBItem
		and store the info in the ResourceArrayElement.

CALLED BY:	ParseUnknownChunks, ParseChunk

PASS:		ss:bp	- parse frame
		ds:si	- ptr to string
		carry	- set to check text, clear to skip check

RETURN:		carry set if it was text and was added

DESTROYED:	ax, bx, si, di, ds

PSEUDO CODE/STRATEGY:
	StoreMoniker calls CheckIfMoniker, which calls CheckIfText
	so no need to check it again here.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreText		proc	far
	uses	si,di,ds
	.enter

	; Dereference the chunk being examined
	;
	movdw	bxsi, ss:[bp].PF_object
	call	MemDerefDS
	mov	si, ds:[si]				

	jnc	noCheck
	call	CheckIfText			;dx <- TextStringArgs
	jnc	done				;not valid, don't store it

noCheck:	
	call	PutStringInItem			;di <- string's DBItem
	movdw	bxsi, ss:[bp].PF_resArray
	call	MemDerefDS			;ds:di <- ResourceArrayElement
	mov	bx, di				;bx <- new DBItem
	mov	ax, ss:[bp].PF_element
	call	ChunkArrayElementToPtr
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_NOT_FOUND			>

	mov	ds:[di].RAE_data.RAD_origItem, bx
	ornf	ds:[di].RAE_data.RAD_chunkType, mask CT_TEXT
	mov	ds:[di].RAE_data.RAD_stringArgs, dx
	inc	ss:[bp].PF_number
	stc
done:
	.leave
	ret

StoreText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if passed chunk points to a bitmap.

CALLED BY:	ParseChunk
PASS:		ss:bp	- ParseFrame

RETURN:		carry set if this is a valid bitmap
DESTROYED:	ax,bx,cx,dx,si,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAX_BITMAP_WIDTH	equ	640
MAX_BITMAP_HEIGHT	equ	400

CheckIfBitmap		proc	far
	
	;
	; chunk must be at least big enough to hold a bitmap struct
	;
	mov	dx, ss:[bp].PF_size
	cmp	dx, size Bitmap
	jbe	failed

	;
	; if this is a complex bitmap, make sure chunk is big enough 
	; to hold a CBitmap struct
	;
	mov	al, ds:[si].B_type
	test	al, mask BMT_COMPLEX 
	jz	simple
	cmp	dx, size CBitmap
	jbe	failed

	;
	; If x and y resolutions are different, there's a good chance this 
	; is not a bitmap. (Jon) 
	; (Geos does not allow creation of bitmaps with different
	; resolutions, though we may support importing them in the future.)
	;
	mov	bx, ds:[si].CB_xres
	cmp	bx, ds:[si].CB_yres
	jne	failed

	;
	; Bitmap data should follow CBitmap structure + palette
	;	
	cmp	ds:[si].CB_data, dx
	jae	failed	

	;
	; If we don't have a palette, then logically
	; CB_data needs to be size CBitmap.
	;
	cmp	ds:[si].CB_palette, 0
	jnz	cont

	cmp	ds:[si].CB_data, size CBitmap
	jnz	failed

cont:

	sub	dx, ds:[si].CB_data		;dx <- size of bitmap data
	jmp	checkFormat

simple:
	sub	dx, size Bitmap			;dx <- size of bitmap data

checkFormat:
	andnf	al, mask BMT_FORMAT
	cmp	al, BMFormat
	ja	failed

	cmp	ds:[si].B_compact, 0
	jb	failed		
	cmp	ds:[si].B_compact, BMC_PACKBITS
	ja	failed				;BMC_USER_DEFINED fails?

	; if the bitmap is bigger than I will draw, don't edit it
	;
	call	GrGetBitmapSize
	cmp	ax, MAX_BITMAP_WIDTH
	ja	failed
	cmp	bx, MAX_BITMAP_HEIGHT
	ja	failed

	; check if a bitmap of this type could fit into a chunk of this size
	;
	call	CalculateBitmapChunkSize
	ret

failed:
	clc
	ret

CheckIfBitmap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateBitmapChunkSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To check if this chunk could really contain a bitmap,
		we need to see how big the chunk would have to be to
		contain a bitmap of the given height and width, in the
		given format.

CALLED BY:	CheckIfBitmap
PASS:		ds:si	- supposed bitmap
		ss:bp	- ParseFrame
		dx	- data size

RETURN:		carry set if chunk is right size to hold this bitmap

DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateBitmapChunkSize		proc	near

	push	si
	mov	bx, dx

	; calculate the number of bytes per scan line
	;
	mov	al, ds:[si].B_type
	mov	cx, ds:[si].B_width
	call	DocumentCalcLineSize		;ax <- #bytes per scan line
	tst	ax
	jz	failed				;if 0, not a bitmap
	cmp	ax, 8000h
	ja	failed				;if too big, not a bitmap

	cmp	ds:[si].B_compact, BMC_UNCOMPACTED
	jne	compacted

	mov	dx, ds:[si].B_height
	mul	dx				;ax <- #bytes for bitmap
	tst	dx
	clc
	jnz	done

checkSize:
	; if chunk size is not same as calculated size, it's not a bitmap
	;
	cmp	bx, ax
	stc					;assume sizes match
	je	done				;yes!
failed:
	clc					;failure
done:	
	pop	si
	ret

compacted:	; ax == num bytes per scanline

	mov	cx, ds:[si].B_height
	jcxz	failed
	mul	cx		; ax == num bytes in bitmap
	push	bx
	mov	bx, ax		; bx == num bytes in bitmap
	clr	ax

	mov	dl, ds:[si].B_type
	test	dl, mask BMT_COMPLEX
	jz	advanceSimple
	add	si, ds:[si].CB_data
	jmp	calc

advanceSimple:
	add	si, size Bitmap	

calc:
	push	cx
	call	DocumentCalcPackbitsBytes	;cx <- #bytes in scan line
	add	ax, cx
	pop	cx
	pop	bx
	jmp	checkSize

CalculateBitmapChunkSize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentCalcPackbitsBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc number of bytes in a packbits-compacted scan line

CALLED BY:	INTERNAL

PASS:		ds:si	- far pointer to start of next scan of data
		bx	- #bytes when uncompacted (line length)

RETURN:		cx	- #bytes in scan

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		act as if decompacting, but don't write anything

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentCalcPackbitsBytes proc	near
		push	ax,bx,si	; save trashed regs
		clr	ah		; for 16 bit subtractions later
		clr	cx		; use cx as total compacted count

		; starting a packet, get flag/counts byte
CPB_5:
		lodsb			; get flag/count byte
		inc	cx		; count one for the flag/count byte
		tst	al
		jns	CPB_100		; jmp for discrete bytes

		; repeat count with data byte, just inc nbytes and pointer,
		; dec #uncompacted bytes appropriately

		inc	cx		; one more byte in 
		inc	si		; bump to next flag/count byte
		neg	al		;convert to number of bytes packed
		inc	al		;i.e. number of copies plus the orig
CPB_20:
		sub	bx, ax		; subtract from total uncompacted bytes
		jne	CPB_5		; jmp if more bytes
		pop	ax,bx,si
		ret

;-----------------------------------------------------------------------------
		; discrete bytes, see how many
CPB_100:
		inc	al		; convert to number of discrete bytes
		add	cx, ax		; bump count of compacted bytes 
		add	si, ax		; bump pointer too
		jmp	short	CPB_20
DocumentCalcPackbitsBytes endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentCalcLineSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the line width (bytes) for a scan line of a bitmap

CALLED BY:	INTERNAL

PASS:		al	- B_type byte
		cx	- width of bitmap (pixels)

RETURN:		ax	- #bytes needed

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		case BMT_FORMAT:
		    BMF_MONO:	#bytes = (width+7)>>3
		    BMF_4BIT:	#bytes = (width+1)>>1
		    BMF_8BIT:	#bytes = width
		    BMF_24BIT:	#bytes = width * 3
		    BMF_4CMYK:	#bytes = 4*((width+7)>>3)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	06/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentCalcLineSize	proc	near
		uses	dx
		.enter
		mov	ah, al			; make a copy
		and	ah, mask BMT_FORMAT	; isolate format
		xchg	ax, cx			; ax = line width, cx = flags
		
		mov	dx, ax			; save line width
		add	dx, 7			; calc mask size
		shr	dx, 1
		shr	dx, 1
		shr	dx, 1

		cmp	ch, BMF_MONO 		; are we monochrome ?
		ja	colorCalc		;  no, do color calculation
		
		mov	ax, dx			; ax = BMF_MONO size

		; done with scan line calc.  If there is a mask, add that in
checkMask:
		test	cl, mask BMT_MASK	; mask stored too ?
		jz	done
		add	ax, dx
done:
		.leave
		ret

		; more than one bit/pixel, calc size
colorCalc:
		cmp	ch, BMF_8BIT		; this is really like mono
		je	checkMask
		jb	calcVGA			; if less, must be 4BIT
		cmp	ch, BMF_24BIT		; this is really like mono
		je	calcRGB

		; it's CMYK or CMY, this should be easy
		
		mov	ax, dx			; it's 4 times the mask size
		shl	ax, 1
		shl	ax, 1
		jmp	checkMask

		; it's 4BIT
calcVGA:
		inc	ax			; yes, round up
		shr	ax, 1			; and calc #bytes
		jmp	checkMask

		; it's RGB.
calcRGB:
		mov	dx, ax			; *1
		shl	ax, 1			; *2
		add	ax, dx			; *3
		add	dx, 7			; recalc mask since we used dx
		shr	dx, 1
		shr	dx, 1
		shr	dx, 1
		jmp	checkMask
						; THIS FALLS THROUGH IF MASK
DocumentCalcLineSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	validate that ds:si points to a text string

CALLED BY:	StoreText, CheckIfMoniker

PASS:		ss:bp	- ParseFrame
		ds:si	- text to check

RETURN:		carry set if text chunk is valid
		dx 	- TextStringArgs
	
DESTROYED:	dx, ds, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Does not support DBCS.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfText		proc	near
	uses	cx, bx
	.enter

	; If it is text, it may or may not be null-terminated.
	;	
	mov	di, si
	clr	dx				; dx is TextStringArgs record
	mov	cx, ss:[bp].PF_size		
	dec	cx				; don't check last char
DBCS <	dec	cx							>
	add	di, cx				; ds:di points to last char
	LocalGetChar	bx, dsdi, NO_ADVANCE	; b[lx] <- last char
	sub	di, cx

DBCS <	shr	cx, 1				; cx <- number of chars	>
	LocalIsNull	bx			; is it a NULL?
	jz	startCheck			; yes
	inc	cx				; no, must check last char too

startCheck:
	LocalGetChar	bx, dsdi, NO_ADVANCE
	LocalCmpChar	bx, C_CR		; is it a carriage return?
	je      next
	LocalCmpChar	bx, C_TAB		; is it a tab?
	je      next
	LocalCmpChar	bx, C_LF		; is it a newline?
	je      next
	LocalCmpChar	bx, '\1'		; UserStandardDialog arg 1
	je	checkFirstReplacement
	LocalCmpChar	bx, '\2'		; UserStandardDialog arg 2
	je	checkSecondReplacement
	LocalCmpChar	bx, C_SPACE		; is it below a space?
	jb	failedCheck                     ;  it's a control char	

	; SBCS - everthing from C_SPACE - 0xef is valid, except the delete char
	; DBCS - 0xee## are also invalid characters
	; DBCS - now, everything with a non-zero HB is invalid to help
	; parsing.  The only exceptions are puncts, which are of the form
	; 0x2000 - 0x27ff.  This range fits nicely under the mask 0x27ff
DBCS <PrintMessage<Remove Ascii-only restriction when parsing fixed >>
	LocalCmpChar	bx, C_DELETE		; is it delete char?
        je      failedCheck
DBCS <	test	bh, not 0x27			; let mask 0x27 through	>
DBCS <	jnz	failedCheck						>
;;DBCS <	cmp	bh, CS_CONTROL_HB		; is it a DBCS control char?	>
;;DBCS <	je	failedCheck						>
	
next:
	LocalNextChar	dsdi
        loop    startCheck                      ; continue checking.
	stc
	jmp	done

checkFirstReplacement:
	inc	dh
EC<	cmp	dh, 0						>
EC<	ERROR_Z	RESEDIT_INTERNAL_LOGIC_ERROR			>
	cmp	dh, 1
	ja	clrDXThenFail		; we're only allowed one of these in a string
	jmp	next

checkSecondReplacement:
	inc	dl
EC<	cmp	dl, 0						>
EC<	ERROR_Z	RESEDIT_INTERNAL_LOGIC_ERROR			>
	cmp	dl, 1			; we're only allowed one of these in a string
	ja	clrDXThenFail
	jmp	next

clrDXThenFail:
	clr	dx
failedCheck:
	clc
done:
	.leave
	ret

CheckIfText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate that chunk contains a gstring.

CALLED BY:	StoreGString, CheckIfMoniker

PASS:		ss:bp	- parse frame
		ds:si	- gstring to check

RETURN:		carry set if a gstring

DESTROYED:	ax,bx,cx,di,ds,es

PSEUDO CODE/STRATEGY:
	Draw the gstring an element at a time (skipping over them so 
	that they aren't actually drawn), checking for GSRT_FAULT.
	If no faults, the gstring contains valid opcodes, though
	their arguments may be invalid.

	Uses PF_mnemonicType to get a return value from the
	callback which checks if the gstring contains any optrs.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Does not handle gstrings stored in HugeArrays, which should not be
	a problem because they can't be created staticly, according to Jim.

	GStrings which draw bitmaps or text from optrs cannot be
	edited until some provision is made for relocating optrs.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfGString		proc	near
	uses	dx,si,bp
	.enter

	tst 	{byte}ds:[si]			;simple check to see if there
	clc					; is at least more than an
	LONG	jz	notGString		; GrEndGString command

.assert (TYPE GStringElement eq byte)

	mov	cx, ss:[bp].PF_size
	push	cx, si
	sub	cx, size OpEndGString		;point to what should be 
	add	si, cx				; the EndGString command
	cmp	{byte}ds:[si], GR_END_GSTRING	;yes, it could be a gstring
	pop	cx, si				
	LONG	jne	notGString		;nope, it's not a gstring

	push	bp				;save ParseFrame pointer

	mov	bp, si
	segmov	es, ds				;es:di <- gstring
	mov	dx, bp
	add	dx, cx				;es:dx <- end of gstring

	mov	cl, GST_PTR			;gstring stream from ptr
	mov	bx, ds				;bx:si <- gstring address
	call	GrLoadGString			;^hsi <- gstring

	; check the first opcode is within valid range
	;
	cmp	{byte}es:[bp], GSE_LAST_OPCODE
	ja	failure
	clr	di

	; when loop starts, I know the first opcode is okay
	; 	es:dx = end of gstring chunk
	;	es:bp = start of gstring chunk
	;	^hsi = gstring
	;	di = 0 (no gstate)
nextElement:
	; get the next element and its size
	;
	clr	ax
	clr	cx				;buffer is 0 sized - don't copy
	call	GrGetGStringElement		;al <- opcode, cx <- elem. size
	add	bp, cx				;es:bp <- next element
	cmp	ax, GSE_INVALID			;is the opcode invalid?
	je	failure
	cmp	ax, GSE_LAST_OPCODE		;is it within valid range?
	ja	failure
	cmp	al, GR_END_GSTRING		;is it the end of the gstring?
	je	success			

	mov	al, GSSPT_SKIP_1
	call	GrSetGStringPos			; now skip over the element

	cmp	bp, dx				;if not at end of chunk, 
	jb	nextElement			;  get the next element

failure:
	pop	bp				;ss:bp <- ParseFrame
	clc
	jmp	done

success:
	cmp	bp, dx
	jne	failure

	; Check if this gstring has optr commands, and if so, 
	; whether the optrs are valid.  Only gstrings with non-
	; optr commands are editable.
	;
	pop	bp				;ss:bp <- ParseFrame
	call	CheckForGStringOptrs
	tst	ss:[bp].PF_mnemonic		;0 if no optr command
	stc					;it's an editable gstring
	jz	done
	clc

done:
	pushf
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	popf

notGString:
	.leave
	ret

CheckIfGString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForGStringOptrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for gstring elements which draw from optrs.

CALLED BY:	CheckIfGString

PASS:		^hsi	- gstring
		ss:bp	- ParseFrame

RETURN:		dx 	- ChunkType

DESTROYED:	di, bx, cx

PSEUDO CODE/STRATEGY:
	If drawing from OPTR, make this gstring non-editable for now.
	Later, add code to read in resource, copy data to a new
	resource, and fixup the gstring optr.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForGStringOptrs		proc near
	uses	ds
	.enter

	CheckHack <offset ODBOP_optr eq 5>
	CheckHack <offset OFBOP_optr eq 5>
	CheckHack <offset ODTO_optr eq 5>

	; reset to beginning of gstring
	;
	clr	ss:[bp].PF_mnemonic		;is set to -1 if optr found
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos		

	clr	di				;no gstate
	mov	dx, mask GSC_OUTPUT
	mov	bx, cs
	mov	cx, offset CheckForGStringOptrsCallback
	call	GrParseGString	

	.leave
	ret

CheckForGStringOptrs		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForGStringOptrsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	CheckForGStringOptrs (via GrParseGString)
PASS:		ds:si	- ptr to element
		ss:bx	- ParseFrame

RETURN:		ax	- TRUE if optr found, FALSE to continue parsing
		sets ss:[bp].PF_mnemonic 
			= 0 gstring doesn't contain optr command
			= 1 gstring contains optr command, optr was found
			= -1 if gstring contains an optr command
				but the optr couldn't be found

DESTROYED: 	bx,cx,dx

PSEUDO CODE/STRATEGY:
	Uses PF_mnemonicType to indicate whether the gstring
	contains any optrs, and whether they were found.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForGStringOptrsCallback		proc	far

	mov	al, {byte}ds:[si]
	cmp	al, GR_END_GSTRING
	je	endOfGString

	mov	dl, mask CT_TEXT			;is it text?
	cmp	al, GR_DRAW_TEXT_OPTR			;ODTO_optr dword
	je	saveOptr

	mov	dl, mask CT_BITMAP			;is it a bitmap?
	cmp	al, GR_DRAW_BITMAP_OPTR			;ODBOP_optr optr
	je	saveOptr
	cmp	al, GR_FILL_BITMAP_OPTR			;OFBOP_optr optr
	je	saveOptr

	mov	ax, FALSE				;continue processing
	ret

saveOptr:
	; mark the optr as being bitmap or text
	; (do I want to note that it is in a gstring for chunk type text??)
	;
	mov	bp, bx				;ss:bp <- ParseFrame
	movdw	bxax, ds:[si+5]			;all optrs 5 bytes from start
	clr	cx				;set the ChunkType flags in dl
	call	SetOptrType			
	mov	ss:[bp].PF_mnemonic, 1		;assume optr was found
	jnc	endOfGString
	mov	ss:[bp].PF_mnemonic, -1		;couldn't find optr

endOfGString:
	mov	ax, TRUE			;stop processing
	ret

CheckForGStringOptrsCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCSCheckFirstTwoWords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Are the first two characters valid DBCS ASCII?

CALLED BY:	CheckIfMoniker
PASS:		ds:si	- data to check
RETURN:		carry set if we think ds:si isn't a moniker because the
		first two words look like text.

		carry clear if ds:si could be a moniker.

		fatal error if the first two words look like text, but
		could also be a valid moniker header.

DESTROYED:	nothing
SIDE EFFECTS:	none

EXPLANATION OF HACK:
	Plain DBCS text can sometimes look like a valid text moniker.
	We want to be able avoid this, so we check to see if the first
	two characters are of the form 0x00##, with some restrictions on ##
	(ie, not a bizarre control character).
	
	So, we are checking whether the byte pattern is: ## 00 ## 00

	If the data actually comprise a VisMoniker, the 2nd and 3rd bytes
	will be the VM_width field.  We make the assumption that the
	2nd byte (low byte of VM_width) will very seldom be 00, unless the
	3rd byte (high byte of VM_width) is 00 also.  
	
	If the 3rd byte is 00, then the second word will not be a valid
	DBCS ASCII character, since it will be 0x0000.

	A gray area is where the low byte of VM_width is 0x00 (looks like
	text) and the first byte is 0x01 (looks like a text moniker -- all
	the ones I've seen have VM_type = 0x01 or 0x00).  Here, I fatal
	error so I can see what data are causing this.

		DANGEROUS:	01 00 ## 00

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	3/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
DBCSCheckFirstTwoWords	proc	near
	uses	ax,cx,si,di
	.enter

	mov	di, si			; keep a copy around
	mov	cx, 2			; check 2 chars
checkChar:
	lodsw
	tst	ah
	jnz	invalidText
	cmp	ax, C_CR		; Check everything below 0x0020 first
	je	next
	cmp	ax, C_TAB
	je	next
	cmp	ax, C_LF
	je	next
	cmp	ax, '\1'
	je	next
	cmp	ax, '\2'
	je	next
	cmp	ax, C_SPACE
	jb	invalidText
	cmp	ax, C_DELETE		; only invalid char above 0x0020
	je	invalidText
next:
	loop	checkChar
				
validText::
	cmp	{byte}ds:[di], 1
	je	ambiguous
	stc
	jmp	done
invalidText:
	clc
done:
	.leave
	ret

ambiguous:
	sub	si, 2		;ds:si points after the \1 char
	clr	ax
	pushdw	axax		;SDP_helpContext
	pushdw	axax		;SDP_customTriggers
	pushdw	axax		;SDP_stringArg2
	pushdw	dssi		;SDP_stringArg1
	mov	ax, offset DialogString
	pushdw	csax		;SDP_customString
	mov	ax, (CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	push	ax
	call	UserStandardDialog
	cmp	ax, IC_YES
	stc
	je	done
	jmp	invalidText

	ERROR_B	RESEDIT_AMBIGUOUS_TEXT_OR_MONIKER
	stc
	jmp	done

DBCSCheckFirstTwoWords	endp
LocalDefNLString	DialogString, <'Is <@1',C_CTRL_A,'> a string (as opposed to a moniker) which begins with @1?\r\rIf the character after @1 is garbage, then it is probably a moniker and you should hit the "No" button.',0>
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the passed chunk contains a moniker.

CALLED BY:	StoreMoniker

PASS:		ss:bp	- parse frame
		ds:si	- data to check

RETURN:		carry set if chunk is a moniker, or a moniker list
		dl	- ChunkType: 
	 	  CT_TEXT or CT_GSTRING - if chunk contains a moniker
		  CT_MONIKER_LIST       - if chunk contains a moniker list
		  CT_NOT_EDITABLE       - if not moniker or moniker list

DESTROYED:	

PSEUDO CODE/STRATEGY:
	Check moniker width (and height, if it is a gstring)
	against the size of a VGA display (800x640).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfMoniker		proc	far
	uses 	ax,bx,si,di
	.enter

	push	ss:[bp].PF_size				;save actual size

	; at the minimum, a moniker is big enough for these two structs
	;
	cmp	ss:[bp].PF_size, (size VisMoniker + size VisMonikerText)
	LONG	jbe	failure

	; VisMoniker lists have already been marked, in ParseObjectChunks
	;
	mov	dl, mask CT_MONIKER_LIST
	test	ds:[si].VM_type, mask VMT_MONIKER_LIST
	clc
	LONG 	jnz	done

	; if it's marked as a gstring, see if it is a gstring, else it 
	; must be text.
	;
	test	ds:[si].VM_type, mask VMT_GSTRING
	jnz	tryGString

	; move ptr to text offset, and correct the chunk size
	; to be size of the text, then check if it is actually text
	; DBCS: crude hack to check if the first two bytes are DBCS ascii.
	;  if they are, likely that this is not a moniker
	;
	mov	di, si					
	add	si, MONIKER_TEXT_OFFSET
	sub	ss:[bp].PF_size, MONIKER_TEXT_OFFSET

	; if mnemonic is not in text, sub off the 1 byte/word for it
	; that follows the text from the size of the chunk
	;
	mov	bl, ds:[di].VM_data.VMT_mnemonicOffset
	cmp	bl, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	checkText
	dec	ss:[bp].PF_size				;sub off mnemonic
DBCS <	dec	ss:[bp].PF_size				;sub off mnemonic	>

checkText:
	call	CheckIfText				;dx <- TextStringArgs
	jnc	failure

	; if it is a text moniker, this flag shouldn't be set 
	; (why?)
	sub	si, MONIKER_TEXT_OFFSET			;ds:si <- moniker
	test	ds:[si].VM_type, mask VMT_GS_ASPECT_RATIO
	jnz	failure

	; if it is a text moniker, the first two words very likely won't
	; look like ascii DBCS.  Note that this is a heuristic hack, and
	; should be removed when some more stable check comes along.
	;
DBCS <	call	DBCSCheckFirstTwoWords					>
DBCS <	jc	failure	     						>
DBCS <	PrintMessage <DBCSCheckFirstTwoWords needs to be fixed>		>
	mov	bl, ds:[si].VM_data.VMT_mnemonicOffset
	mov	ss:[bp].PF_mnemonic, bl
	LocalClrChar	ax			; no mnemonicChar, yet
	cmp	bl, VMO_NO_MNEMONIC
	je	saveChar

	cmp	bl, VMO_CANCEL
	je	saveChar
	mov	ax, ss:[bp].PF_size		;offset to mnemonicChar
	cmp	bl, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	je	notInMoniker
	clr	bh				; moniker is in text
	mov	ax, bx				; ax <- offset to char
DBCS <	shl	bx, 1				; bx <- byte offset to char	>
	cmp	bx, ss:[bp].PF_size		; check that offset is valid
	jae	failure				; nope, it falls out of bounds

notInMoniker:
	; mnemonic lies after text string null terminator
	;
	mov	di, si
	add	di, MONIKER_TEXT_OFFSET 	; ds:di <- text
SBCS <	add	di, ax				; ds:di <- mnemonicChar	>
DBCS <	add	di, bx				; ds:di <- mnemonicChar	>
	LocalGetChar	ax, dsdi, NO_ADVANCE	; save the mnemonic

saveChar:
	; ss:bp.PF_size is still text size, as set above
	; Make sure that our assumption that VM_type (used for DBCS hack)
	; is correct.  It should always be 0x01 or (in rare cases) 0x00
	;
DBCS <	test	{byte}ds:[si].VM_type, 0xfe	;is it 0x00 or 0x01?	>
DBCS <	ERROR_NZ	VM_TYPE_ASSUMPTION_INCORRECT				>
SBCS <	mov	ss:[bp].PF_mnemonicChar, al				>
DBCS <	mov	ss:[bp].PF_mnemonicChar, ax				>
	mov	dl, mask CT_TEXT
	stc
	jmp	done

tryGString:
	; check the moniker width for clearly bogus numbers
	;
	cmp	ds:[si].VM_width, 640
	ja	failure

	; check the moniker height for impossible values
	;
	add	si, offset VM_data
	cmp	ds:[si].VMGS_height, 800h
	ja	failure
	add	si, offset VMGS_gstring		; ds:si <- gstring
		
	; move ptr to data offset, and correct the chunk size
	; then check if it is a valid gstring
	;
	sub	ss:[bp].PF_size, MONIKER_GSTRING_OFFSET
	call	CheckIfGString
	jnc	failure

	; now, because some text strings also pass the gstring
	; moniker test, see if this chunk passes as text.  
	; If so, it is more likely a plain text chunk.
	;
	sub	si, MONIKER_GSTRING_OFFSET
	add	ss:[bp].PF_size, MONIKER_GSTRING_OFFSET
	call	CheckIfText			;is it text?
	jc	failure				;yes, so don't mark it gstring
	tst	dx				;does it have string args?
	jnz	failure				;is yes, can't be a moniker
	mov	dl, mask CT_GSTRING		;no, it's a gstring allright
	stc			

done:
	pop	ss:[bp].PF_size			;restore chunk size
	.leave
	ret

failure:
	mov	dl, mask CT_NOT_EDITABLE
	clc
	jmp	done

CheckIfMoniker		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfUIObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines whether the passed lmem chunk contains
		an object subclassed off the passed class, library.

CALLED BY:	MarkObjects, MarkText
PASS:		ss:bp	- ParseFrame
		ax	- class entry point to check for (in UI library)

RETURN:		carry set if object of class, clear if not

DESTROYED:	ax,di,si,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UILibrary	char	'ui      ', 0
CheckIfUIObject		proc	far
	uses	bx,cx,dx,es
	.enter

	push	ax				;class to check for
	movdw	bxsi, ss:[bp].PF_object
	call	MemDerefDS
	mov	si, ds:[si]
	mov	cx, ds:[si].MB_class.offset	;library number
	push	ds:[si].MB_class.segment	;possible entry point
	mov	dx, cx
	
	;
	; If the geode being parsed is the UI library, there is no need
	; to follow the superclass up looking for a library relocation
	; to this library.  Just check if object is GenClass subclass.
	;
	test	ss:[bp].PF_flags, mask PF_UI_LIBRARY
	jnz	checkSubClass

	;
	; MB_class.offset holds the ObjRelocationID for the object's class
	; see if this object is relocated from a library
	;
	andnf	dx, mask RID_SOURCE
	cmp	dx, (ORS_LIBRARY shl offset RID_SOURCE)
	jne 	notLibrarySource
	andnf	cx, mask RID_INDEX		;imported library number

	;
	; This will only detect objects defined in the UI library
	;
	segmov	ds, cs
	lea	si, cs:[UILibrary]		;ds:si <- ui string
	call	CheckLibraryEntry		;is it a UI entry point?
	jnc	notObject

checkSubClass:
EC<	andnf	dx, mask RID_SOURCE					>
EC<	cmp	dx, (ORS_OWNING_GEODE_ENTRY_POINT shl offset RID_SOURCE)>
	pop	dx				;MB_class_segment entry point
	pop	cx				;the passed class to check for
	call	CheckIfSubclass			;carry set if a subclass
	jmp	done

notLibrarySource:
	; see if class is relocated from within the geode 
	;
	cmp	dx, (ORS_OWNING_GEODE_ENTRY_POINT shl offset RID_SOURCE)
	jne	notObject
	andnf	cx, mask RID_INDEX		;resource which exports it
 	pop	bx				;MB_class.segment = entry point
	pop	ax				;class to check for
	segmov	ds, cs
	lea	si, cs:[UILibrary]		;ds:si <- ui string
	call	CheckExportedEntry		;pass ax = class enum.
	jnc	done
	jmp	done
	
notObject:
	pop	ax, ax				;fixup the stack
	clc
done:
	.leave
	ret
CheckIfUIObject		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if cx is an entry point for the passed library.

CALLED BY:	CheckIfObject

PASS:		ss:bp	- ParseFrame
		cx	- entry point to check
		ds:si	- name of library class is defined in

RETURN:		carry set if object is of this class, clear if not
		(or if no imported library entries)

DESTROYED:	cx, si, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckLibraryEntry 		proc	near
	uses	ax,bx,di,es
	.enter

	; Lock the library table and get the offset of the
	; cx'th library entry.
	mov	bx, ss:[bp].PF_TFFoffset
	segmov	es, ss:[bx].TFF_handles
	mov	bx, es:[0].DHS_importTable
	tst	bx
	clc
	jz	noTable

	call	MemLock
	mov	es, ax
	mov	ax, cx
EC <	tst	ah					>
EC <	ERROR_NZ RESEDIT_INTERNAL_LOGIC_ERROR		>
	mov	cl, size ImportedLibraryEntry
	mul	cl
	mov	di, ax
	mov	cx, GEODE_NAME_SIZE
	
compare:
	; check if ILE_name in es:di is the same as passed name
	;
	lodsb					;get char in al, increment si
	cmp	al, es:[di]			;does it match char in ILE?
	jne	failed	
	inc	di
	loop	compare
	stc
	
done:
	call	MemUnlock
noTable:
	.leave
	ret
failed:
	clc
	jmp	done
CheckLibraryEntry 		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckExportedEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if cx is the correct exported class

CALLED BY:	CheckIfUIObject

PASS:		ax	- the superclass we're looking for
		bx	- the exported entry to check (MB_class.segment)
		cx	- resource which exports it (RID source)
		ss:bp	- ParseFrame
		ds:si	- library to check for

RETURN:		carry set if correct

DESTROYED:	si,di,ds,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckExportedEntryFrame	struc
    CEEF_exportPtr	dword		; export resource:offset pointer
    CEEF_reloc		hptr		; the resource's relocation table
    CEEF_relocCount 	word		; number of relocation entries
    CEEF_resPos		dword		; file position of resource.
    CEEF_entryPt	word		; exported entry point
    CEEF_class		word		; superclass' entry point
    CEEF_passedBP	word
    CEEF_library	fptr
CheckExportedEntryFrame	ends

CheckExportedEntry		proc	near
	uses	bp
	.enter

	mov	di, bp				;ss:di <- ParseFrame
	sub	sp, size CheckExportedEntryFrame
	mov	bp, sp				;ss:bp <- CEEFrame
	mov	ss:[bp].CEEF_class, ax
	mov	ss:[bp].CEEF_entryPt, bx
	mov	ss:[bp].CEEF_passedBP, di
	movdw	ss:[bp].CEEF_library, dssi
	clr	ss:[bp].CEEF_reloc		;no handle yet

	; Get the export entry for the passed entry point number
	;
	mov	bx, ss:[di].PF_TFFoffset
	segmov	es, ss:[bx].TFF_handles
	mov	bx, es:[0].DHS_exportTable
	call	MemLock
	mov	ds, ax
	
	mov	cx, ss:[bp].CEEF_entryPt
	shl	cx				;entry*2
	shl	cx				;entry*4
	mov	si, cx	
	movdw	cxdx, ds:[si]			;ds:si <- export entry
	movdw	ss:[bp].CEEF_exportPtr, cxdx
	call	MemUnlock

	; Now get information about this resource and its relocation table
	; It must stay locked through loops to load and findRelocation.
	;
	mov	si, di				;ss:si <-ParseFrame
	mov	bx, es:[0].DHS_resourceTable
	call	MemLock
	mov	ds, ax

loadRelocation:
	; find the size of the relocation table for the resource 
	;      ds:0 points to geode's resource Table
	;
	clr	di
	mov	ax, ss:[si].PF_numResources
EC <	tst	ah					>
EC <	ERROR_NZ RESEDIT_INTERNAL_LOGIC_ERROR		>
	mov	cl, 6				;move past first 3 words
	mul	cl				;#res*6 (bytes)
	add	ax, ss:[bp].CEEF_exportPtr.high
	add	ax, ss:[bp].CEEF_exportPtr.high	;#res*6 + resource*2
	mov	di, ax
	mov	ax, ds:[di]			;relocation table size
	push	ax
		
	; get the resource size (it is actually paragraph aligned)
	;
	mov	di, ss:[bp].CEEF_exportPtr.high 
	mov	ax, di				;ax <- resource number
	shl	di
	mov	cx, ds:[di]			;resource size
	RoundUp	cx				;round up to paragraph boundary
	push	cx

	; get the file position of the resource's relocation table
	;
	shl	ax, 1				;resource*2
	shl	ax, 1				;resource*4
	mov	di, ss:[si].PF_numResources
	shl	di
	add	di, ax				;#res*4 + res*2
	movdw	cxdx, ds:[di]			
	movdw	ss:[bp].CEEF_resPos, cxdx	;position of resource in file
	pop	ax				;resource size, rounded up
	add	dx, ax	
	adc	cx, 0				;cx:dx <-relocation table offset

	; read in the relocation table	
	;
	pop	ax				;relocation table size
	mov	bx, es:[0].DHS_geode
	call	FilePosAndRead
	LONG	jc	error	
	mov	ss:[bp].CEEF_reloc, bx		;^hbx <- relocation table

	; calculate the number of relocation entries from the table size
	;
	clr	dx
	mov	cx, size GeodeRelocationEntry
	div	cx				;should divide evenly, but...
EC <	tst	dx					>
EC <	ERROR_NZ	RESEDIT_INTERNAL_LOGIC_ERROR	>
	mov	ss:[bp].CEEF_relocCount, ax

	; now look for the relocation entry which matches the 
	; offset read from the exported entry table (exportPtr.low)
findRelocation:
	mov	bx, ss:[bp].CEEF_reloc
	call	MemLock
	mov	ds, ax
	mov	cx, ss:[bp].CEEF_relocCount 	;cx <- number of GRE's
	clr	di
	mov	ax, ss:[bp].CEEF_exportPtr.low	;offset of relocation
	mov	bx, ax			
	add	bx, size word			;segment of relocation
cmpOffset:
	cmp	ax, ds:[di].GRE_offset		;do the offsets match?
	je	found
	cmp	bx, ds:[di].GRE_offset		;why this check????????
	je	found
	add	di, size GeodeRelocationEntry
	loop	cmpOffset
	mov	bx, ss:[bp].CEEF_reloc
	call	MemUnlock
	jmp	error

found:
	; if this is a class relocated from a library, relocation
	; type must be GRT_FAR_PTR
	;
	mov	cl, ds:[di].GRE_info
	mov	dl, cl
	andnf 	cl, mask GRI_SOURCE
	andnf	dl, mask GRI_TYPE
	cmp	cl, GRS_LIBRARY shl offset GRI_SOURCE
	jne	tryResource	
	cmp	dl, GRT_OFFSET shl offset GRI_TYPE
	jne	error

	; check if this is a valid UI library entry
	;
	push	si
	mov	cl, ds:[di].GRE_extra		;cl <- library entry number
	clr	ch
	; move unlock where GRE stuff isn't used anymore (awu bug fix)
	mov	bx, ss:[bp].CEEF_reloc
	call	MemUnlock

	movdw	dssi, ss:[bp].CEEF_library	;library name
;	segmov	ds, cs
;	lea	si, cs:[UILibrary]		;ds:si <- ui string
	push	bp
	mov	bp, ss:[bp].CEEF_passedBP	;ss:bp <- ParseFrame
	call	CheckLibraryEntry
	pop	bp
	pop	si
	jnc	error

	; locate the offset of the relocation in the resource containing it
	;
	movdw	cxdx, ss:[bp].CEEF_resPos	;resource location in file
	add	dx, ss:[bp].CEEF_exportPtr.low	;offset of the relocation
	adc	cx, 0
	mov	al, FILE_POS_START
	mov	bx, es:[0].DHS_geode
	call	FilePos

	segmov	ds, ss
	lea	dx, ss:[bp].CEEF_exportPtr.low	;get entry-point number of
	mov	cx, size word			; superclass into exportO
	clr	al
	call	FileRead
	jc	error

	; Check if class being exported is a subclass of the one passed.
	;
	mov	cx, ss:[bp].CEEF_class	
	mov	dx, ss:[bp].CEEF_exportPtr.low
	call	CheckIfSubclass			;carry set if it's a subclass

done:
	lahf
	mov	bx, es:[0].DHS_resourceTable
	call	MemUnlock
	mov	bx, ss:[bp].CEEF_reloc
	tst	bx
	jz	noReloc
	call	MemFree
noReloc:
	add	sp, size CheckExportedEntryFrame
	sahf
		
	.leave
	ret
errorPop:
	pop	cx
error:
	clc
	jmp	done

tryResource:
	; If the relocation source is a resource within this Geode,
	; the segment portion of the relocation will hold the
	; resource number of the segment containing the superclass.
	;
	cmp	cl, GRS_RESOURCE shl offset GRI_SOURCE
	jne	error				;might have been MetaClass??
	cmp	dl, GRT_SEGMENT shl offset GRI_TYPE
	jne	error
	push	ss:[bp].CEEF_exportPtr.high	;save old resource number
	movdw	cxdx, ss:[bp].CEEF_resPos	;get resource file position
	add	dx, ss:[bp].CEEF_exportPtr.low	;add relocation offset
	adc	cx, 0

	mov	al, FILE_POS_START
	mov	bx, es:[0].DHS_geode
	call	FilePos
	
	; load the relocation: resource number, offset within resource
	;
	segmov	ds, ss
	lea	dx, ss:[bp].CEEF_exportPtr.low
	mov	cx, size dword
	clr	al
	call	FileRead
	jc	errorPop

	pop	ax				;the old resource number
	cmp	ax, ss:[bp].CEEF_exportPtr.high	;are they in same resource? 
	lahf
	mov	bx, es:[0].DHS_resourceTable
	call	MemDerefDS			;ds - segment of resource tbl
	sahf	
	LONG	je	findRelocation		;yes, find relocation again
	call	MemFree				;free old relocation table
	LONG	jmp	loadRelocation		;no, load the new reloc table

CheckExportedEntry		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfSubclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given two entry points into the UI library,
		determine if one is a subclass of the other.

CALLED BY:	CheckIfUIObject, CheckExportedEntry

PASS:		cx	- UI entry point (superclass?)
		dx	- UI entry point (subclass?)

RETURN:		carry set if dx is a subclass of cx

DESTROYED:	ax,bx,di,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfSubclass		proc	near
	uses	si,es
	.enter

	mov	bx, handle ui
	mov	ax, cx				;superclass entry point
	call	ProcGetLibraryEntry
	movdw	dssi, bxax			;ds:si <- fptr of class
	
	mov	bx, handle ui
	mov	ax, dx				;subclass entry point
	call	ProcGetLibraryEntry
	movdw	esdi, bxax			;es:di <- object's class

	call	ObjIsClassADescendant		;carry set if a subclass

	.leave
	ret
CheckIfSubclass		endp

DocumentParseCode	ends
