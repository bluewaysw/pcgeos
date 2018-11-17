COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		graphicsFontDriver.asm
FILE:		graphicsFontDriver.asm

AUTHOR:		Gene Anderson, Mar  3, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB GrCallFontDriver	Find the correct font driver and call it.

    GLB FontDrDeleteLRUChar	Delete the least recently used character(s)
				to find free space

    INT FindLRUChar		Find the least recently used character

    INT AdjustPointers		Adjust pointers to chars after deleted char

    INT ShiftData		Shift data over deleted character, update
				table entry

    GLB FontDrFindFontInfo	Find FontInfo structure for a font

    GLB FontDrFindOutlineData	Find OutlineDataEntry for a font, and
				calculate styles that need to be
				implemented algorithmically.

    GLB FontDrAddFont		Add a font to the system

    GLB FontDrDeleteFont	Delete a font from the system

    GLB FontDrAddFonts		

    INT FontLoadFont

    GLB	FontFindFontFileName

    GLB FontDrGetFontIDFromFile
 
    GLB FontDrFindFileName

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/ 3/92		Initial revision

DESCRIPTION:
	This contains common routines for use by the Font Drivers

	$Id: graphicsFontDriver.asm,v 1.1 97/04/05 01:13:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontDriverCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCallFontDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the correct font driver and call it.

CALLED BY:	GLOBAL

PASS: 		di - handle of GState
		ax - function to call
		rest - depends on function called
		       (can be bx, cx, dx, bp)

RETURN:		carry - set if error
DESTROYED:	ax (if not returned)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrCallFontDriver	proc	far
	uses	di
	.enter

	push	bx, ds
	call	LockFontGStateDS		;ds <- seg addr of font
	mov	di, ax				;di <- function to call
	mov	ax, ds:FB_maker			;ax <- driver ID (FontMaker)
	call	FontDrUnlockFont		;done with font
	pop	bx, ds

	call	GrCallFontDriverID

	.leave
	ret
GrCallFontDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrDeleteLRUChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the least recently used character(s) to find free space
CALLED BY:	Font Drivers (GLOBAL)

PASS:		ds - seg addr of font buffer
		ax - size of data to free
RETURN: 	none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	while ((cursize + size(char) > MAX_FONT_SIZE) && (chars > 0)) {
	    for (i = first ; i < last ; i++) {
		LRU = MIN(LRU, char[i].usage);
	    }
	    for (i = first ; i < last ; i++) {
		if (char[i].ptr > char[LRU].ptr) {
		    char[i].ptr -= char[LRU].size;
		}
	    }
	    delete(char[LRU]);
	}
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Does not resize block smaller -- leaves the newly found space free
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontDrDeleteLRUChar	proc	far
	uses	bx, cx, dx, di, si, es
	.enter

	segmov	es, ds, cx			;ds <- seg addr of font
if DBCS_PCGEOS
	mov	cx, ds:FB_lastChar
	sub	cx, ds:FB_firstChar
	inc	cx				;cx <- # of characters
else
	mov	cl, ds:FB_lastChar
	sub	cl, ds:FB_firstChar
	inc	cl
	clr	ch				;cx <- # of characters
endif
deleteChar:
	call	FindLRUChar			;find least recently used
	cmp	si, -1				;see if no characters left
	je	noChars				;branch if no chars left
	call	AdjustPointers			;adjust pointers after char
	call	ShiftData			;shift data downward
	mov	bx, ds:FB_dataSize		;bx <- current size
	add	bx, ax				;bx <- size + new char
	sub	bx, MAX_FONT_SIZE		;see if small enough
	ja	deleteChar			;if so, keep deleting

noChars:
EC <	push	ax							>
EC <	mov	ax, ds				;ax <- seg addr of font	>
EC <	call	ECCheckFontBufAX					>
EC <	pop	ax							>

	.leave
	ret
FontDrDeleteLRUChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLRUChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the least recently used character.
CALLED BY:	FontDrDeleteLRUChar

PASS:		ds - seg addr of font
		cx - # of characters in font
RETURN:		si - offset of LRU character entry
		     (si == -1 if no characters left)
		bx - size of character data (including header)
		di - offset of char data (CharData)
DESTROYED:	bx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindLRUChar	proc	near
	uses	ax, cx, bp
	.enter

	mov	bx, ds:FB_heapCount		;bx <- current usage counter
	clr	dx				;dx <- current score
	mov	si, -1				;si <- ptr to LRU
	mov	bp, 0xffff
	clr	di
charLoop:
	cmp	ds:FB_charTable[di].CTE_dataOffset, CHAR_MISSING
	jbe	nextChar			;if no data, don't count
	mov	ax, bx				;ax <- heap count
if DBCS_PCGEOS
	;
	; DBCS fonts have the LRU count stored only for regions
	;
	test	ds:FB_flags, mask FBF_IS_REGION
	jz	noLRU
	push	si
	mov	si, ds:FB_charTable[di].CTE_dataOffset
	sub	ax, ds:[si].RCD_usage		;ax <- char's score
	pop	si
noLRU:
else
	sub	ax, ds:FB_charTable[di].CTE_usage ;ax <- char's score
endif
	cmp	ax, dx				;see if new oldest
	jb	nextChar			;branch if not
	ja	newLRU				;branch if new LRU
	cmp	ds:FB_charTable[di].CTE_dataOffset, bp
	ja	nextChar			;branch if after current LRU
newLRU:
	mov	si, di				;si <- ptr to LRU char
	mov	dx, ax				;dx <- new low score
	mov	bp, ds:FB_charTable[di].CTE_dataOffset
nextChar:
	add	di, size CharTableEntry		;advance to next char
	loop	charLoop			;loop while more characters

	cmp	si, -1				;see if no chars left
	je	afterSize			;branch if no chars left
	mov	di, bp				;di <- ptr to LRU char data
	test	ds:FB_flags, mask FBF_IS_REGION
	jz	bitmapChars			;branch if not region chars
	mov	bx, ds:[di].RCD_size		;bx <- size of character
afterSize:

	.leave
	ret

bitmapChars:
	;
	; The font is a bitmap font. We don't normally expect to
	; need to do the LRU thing on bitmap fonts, but it may
	; happen as: pointsize -> 128 && # chars -> 255
	;
	mov	al, ds:[di].CD_pictureWidth	;al <- width in bits
	add	al, 7				;round to next byte
	shr	al, 1
	shr	al, 1
	shr	al, 1				;al <- width in bytes
	mov	bl, ds:[di].CD_numRows		;bl <- height of char
	mul	bl				;ax <- size of char data
	add	ax, SIZE_CHAR_HEADER		;add size of header
	mov	bx, ax				;bx <- size of char
	jmp	afterSize
FindLRUChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustPointers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust pointers to chars after deleted char.
CALLED BY:	FontDrDeleteLRUChar

PASS:		es - seg addr of font
		cx - # of characters in font
		di - offset of char data being deleted (CharData)
		bx - size of character being deleted
RETURN:		none
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AdjustPointers	proc	near
	uses	cx, di
	.enter

	mov	dx, di				;dx <- offset of deleted data
	clr	di
charLoop:
	cmp	ds:FB_charTable[di].CTE_dataOffset, dx	;see if after char
	jbe	nextChar				;branch if before
	sub	ds:FB_charTable[di].CTE_dataOffset, bx	;adjust pointer
nextChar:
	add	di, size CharTableEntry		;advance to next char
	loop	charLoop			;loop while more chars

	.leave
	ret
AdjustPointers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShiftData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift data over deleted character, update table entry
CALLED BY:	FontDrDeleteLRUChar

PASS:		si - offset of char to delete (CharTableEntry)
		di - offset of char data (CharData)
		ds, es - seg addr of font
		bx - size of char to delete
RETURN:		ds:FB_dataSize - updated to new size
DESTROYED:	si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShiftData	proc	near
	uses	cx
	.enter

	mov	ds:FB_charTable[si].CTE_dataOffset, CHAR_NOT_BUILT
	mov	si, di				;es:di <- dest (this char)
	add	si, bx				;ds:si <- source (next char)
	mov	cx, ds:FB_dataSize		;cx <- ptr to end of font
	sub	cx, si				;cx <- # of bytes to shift
	rep	movsb				;shift me jesus
	sub	ds:FB_dataSize, bx		;update size of font

	.leave
	ret
ShiftData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrFindFontInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find FontInfo structure for a font
CALLED BY:	Font Drivers (GLOBAL)

PASS:		ds - seg addr of font info
		cx -- font ID (FontID)
RETURN:		ds:di - ptr to FontInfo for font
		carry - set if found
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontDrFindFontInfo	proc	far
	uses	bx
	.enter

	call	FarIsFontAvail
	mov	di, bx				;ds:di <- ptr to FontInfo

	.leave
	ret
FontDrFindFontInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrFindOutlineData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find OutlineDataEntry for a font, and calculate
		styles that need to be implemented algorithmically.
CALLED BY:	Font Drivers (GLOBAL)

PASS:		ds:di - ptr to FontInfo for font
		SBCS<bx - index of data to load (OutlineDataFlag)	>
		al - style (TextStyle)
RETURN:		SBCS <ds:di - ptr to OutlineEntry			>
		DBCS <ds:di - ptr to OutlineDataEntry.ODE_extraData	>
		al - styles to implement (TextStyle)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	smallest = (all styles);
	while (! end of list) {
		if (issubset(font style, requested style)) {
			smallest = min(weighted difference, smallest);
		}
	}
	return (smallest);
	
	- to determine if a set of styles is a subset of the requested
	  styles:
		issubset = (((requested AND font) XOR font) == 0)
	- to get the weighted difference of styles (assuming is a subset):
		difference = (requested AND font)
	  with the styles organized such that the most difficult to
	  emulate with software has the highest value:
		outline		- done in font driver
		bold		- done in font driver
		italic		- done in font driver
		superscript	- done in font driver
		subscript	- done in font driver
		strike through	- done in kernel
		underline	- done in kernel
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Currently defaults to first set of data if none are
	subsets of the requested styles.
	Should *not* be called if there is no outline data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontDrFindOutlineData	proc	far
	uses	bx, dx, si, bp
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx, si					>
EC <	movdw	bxsi, dsdi				>
EC <	call	ECAssertValidFarPointerXIP		>
EC <	pop	bx, si					>
endif	
	
SBCS <	push	bx							>
	clr	dh				;dh <- initial difference
	mov	bp, di
	add	bp, ds:[di].FI_outlineEnd	;bp <- ptr to end of table
	add	di, ds:[di].FI_outlineTab	;di <- ptr to start of table
EC <	cmp	bp, di				;>
EC <	ERROR_E	FONTMAN_FIND_OUTLINE_DATA_CALLED_WITH_BITMAP_FONT ;>
	mov	si, di				;si <- ptr to entry to use
	;
	; In the loop:
	;	al - TextStyle requested
	;
	;	ds:di - ptr to current entry
	;	dl - TextStyle of current entry
	;	bl - current difference from TextStyle requested
	;
	;	ds:si - ptr to entry to use
	;	dh - difference of TextStyle for entry to use (ie. smallest)
	;
FO_loop:
	cmp	di, bp				;at end of list?
	jae	endList				;yes, exit
	mov	dl, ds:[di].ODE_style		;dl <- style of outline
	cmp	dl, al				;an exact match?
	je	exactMatch			;branch if exact match
	mov	bh, al
	and	bh, dl
	mov	bl, bh				;bl <- weighted difference
	xor	bh, dl				;bh <- zero iff subset
	jne	notSubset			;branch if not a subset
	cmp	bl, dh				;cmp with minimum so far
	jb	notSubset			;branch if larger difference
	mov	si, di				;si <- new ptr to entry
	mov	dh, bl				;dh <- new minimum difference
notSubset:
	add	di, size OutlineDataEntry	;advance to next entry
	jmp	FO_loop				;and loop

exactMatch:
	mov	si, di				;ds:si <- ptr to current entry
	clr	al				;al <- no styles to implement
	jmp	gotStyles

endList:
	xor	al, dh				;al <- styles to implement
gotStyles:
	mov	di, si				;di <- off of OutlineDataEntry
SBCS <	pop	si				;si <- index of data to load>
SBCS <	add	di, si				;ds:di <- ptr to OutlineEntry>
	add	di, (size ODE_style + size ODE_weight)

	.leave
	ret
FontDrFindOutlineData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrAddFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a font to the system
CALLED BY:	Font Drivers (GLOBAL)

PASS:		ds:si - ptr to FontInfo & corresponding entries:
			PointSizeEntry - for bitmap sizes, if any
			OutlineDataEntry - for outlines, if any
		ax - size of FontInfo & corresponding entries
		cx - FontID for font
RETURN:		carry - set if error
		    ax - error code (FontAddDeleteError)
DESTROYED:	none (ax if not returned)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontDrAddFont	proc	far
	uses	ds, si, es, di, cx, bx
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx				>
EC <	mov	bx, ds				>
EC <	call	ECAssertValidFarPointerXIP	>
EC <	pop	bx				>
endif

EC <	call	ECCheckFontInfo			;>

	push	cx
	push	ds, si
	call	FarLockInfoBlock		;ds <- seg addr of font info
	;
	; See if the font is already in the system
	;
	call	FarIsFontAvail			;font already in system?
	jc	fontExistsError			;branch if already loaded
	;
	; See if we have too many fonts.  If so, don't add this one.
	; If not, up the number of fonts we've got loaded.
	;
	push	ds,ax,dx,cx
	mov	dx, FONTS_AVAIL_HANDLE		;dx <- handle of chunk
	ChunkSizeHandle	ds, dx, ax		;ax <- size of chunk
	mov	cx,size FontsAvailEntry
	clr	dx
	div	cx				;ax <- number of
						;entries
	cmp	ax,MAX_FONTS
	pop	ds,ax,dx,cx
	jl	cont
	stc	
	jmp	tooManyFonts
cont:
	;
	; Add a chunk for the FontInfo, et al.
	;
	mov	cx, ax				;cx <- size of chunk
	call	LMemAlloc
	mov	di, ax				;di <- chunk handle
	mov	di, ds:[di]			;ds:di <- ptr to chunk
	segmov	es, ds				;es:di <- ptr to chunk
	pop	ds, si				;ds:si <- ptr to new FontInfo
	rep	movsb				;copy me jesus
	segmov	ds, es				;ds <- seg addr of font info
	push	ax				;save chunk handle
	;
	; Add a FontsAvailEntry for the font
	;
	mov	ax, FONTS_AVAIL_HANDLE		;ax <- handle of chunk
	ChunkSizeHandle	ds, ax, cx		;cx <- size of chunk
	push	cx				;save old size
	add	cx, (size FontsAvailEntry)	;cx <- new size of chunk
	call	LMemReAlloc
	;
	; Point the FontsAvailEntry at the FontInfo chunk
	;
	mov	si, ax
	mov	si, ds:[si]			;ds:si <- ptr to chunk
	pop	ax				;ax <- old chunk size
	add	si, ax				;ds:si <- ptr to new space
	pop	ds:[si].FAE_infoHandle		;store chunk of FontInfo
	pop	ds:[si].FAE_fontID		;store FontID value
	mov	{char}ds:[si].FAE_fileName, C_NULL
						;carry <- clear from add
done:
	call	FarUnlockInfoBlock

	.leave
	ret

fontExistsError:
	mov	ax, FADE_FONT_ALREADY_EXISTS	;ax <- FontAddDeleteError
errorCommon:
	add	sp, (size word)*3		;clean up stack
	stc					;carry <- set for error
	jmp	done
tooManyFonts:
	mov	ax, FADE_TOO_MANY_FONTS
	jmp 	errorCommon

FontDrAddFont	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrAddFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds fonts given from list of font file names to the
	system.  If a font is already in the system, it will not be replaced.
	All of the fonts that were successfully added, will have a TRUE value
	in the last byte of there FileLongName field.

CALLED BY:	GLOBAL
PASS:		bx - handle of font file list
		cx - number of font files to add
RETURN:		carry = set if error (memory allocation failed)
DESTROYED:	nothing
SIDE EFFECTS:	Sends message GWNT_FONTS_ADDED to GCNSLT_FONT_CHANGES
	All the fonts successfully added, will the last byte in there
	FontLongName field marked as true.

PSEUDO CODE/STRATEGY:

save current directory
change to the font standard path
lock memory for list of font file names passed in
alloc memory for list of FontIDs successfully added
loop:
	load in the font info from the font file
		move on to next font if this fails
	call FontDrAddFont to add the font
		if this fails move on to next font
	save the FontID of the font just added 
	look the font up in the avail list.  
		if the font is not there an error occurred, move on to
		the next font
	put the font file name in the fonts avail entry
	mark the font file name entry as successfully added
	if there are fonts still to add, move on to the next one
end loop
	unlock the list of font file names
	send out notification that fonts have been added
		- this notification includes the list of font files
		succesffully added
restory original directory

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	2/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontDrAddFonts	proc	far	
fontFileList	local	hptr	push bx
fontCount	local	word	push cx
fontsAddedCount local	word
fontInfoHandle	local	hptr
fontsAddedList	local	word
fontsAddedHandle local	hptr
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; if there are no files to add leave
	;	
	tst	cx
LONG	jz	exit
	clr	ss:[fontsAddedCount]		;

	call	FilePushDir				

	mov	ax, SP_FONT
	call	FileSetStandardPath		
	
	call	MemLock			; lock the list of fonts
LONG	jc	almostExit
	mov	es,ax			
	clr	dx				;es:dx <- ptr to font
						;file name
	;
	; allocate block for list of successfully added font ID, which
	; will be sent out with the notification
	;
	mov_tr	ax,cx				
	shl	ax,1
	mov	cx,ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
LONG	jc	allocError
	mov	ss:[fontsAddedList],ax
	mov	ss:[fontsAddedHandle],bx

addFontLoop:
	call FontLoadFont	; bx <- handle to block with font info
				; ax <- size font info block &
				; corresponding entries
	;
	; if there is an error loading the font, move on to the next
	; font. 
	;
	jc	nextFontLoadError
	push	ax		;save the size of the font info block &
				;entries
	;
	; add the font
	;
	mov	ss:[fontInfoHandle],bx
	call	MemLock
	mov	ds,ax
	pop	ax
	clr	si
	mov	cx,ds:[FI_fontID]
	call	FontDrAddFont
	;
	; free the memory allocated for the font info
	; read in from the font file
	;
	pushf
	mov	bx,ss:[fontInfoHandle]
	call	MemFree	
	popf
	;
	;if the font already exists or there was any other problem
	;adding it move on to the next font
	;
	jc	nextFont	
	;
	; add the FontID to list of FontIDs added
	;
	push	es
	mov	es,ss:[fontsAddedList]		;store fontID in 
	mov	di,ss:[fontsAddedCount]		;buffer
	shl	di,1
EC<	EC_BOUNDS	es di>
	mov	es:[di],cx
	inc	ss:[fontsAddedCount]
	pop	es
	;
	; FontDrAddFont adds the fonts, but it set the file name in 
	; the FontsAvailEntry to Null, so it is set here to the file name
	;
	push	es
	call	FarLockInfoBlock
	call	FarIsFontAvail		
	;
	; if the font is not found there adding the fonts has failed
	;
NEC<	jnc	cont						>
EC<	ERROR_NC	FONT_ADD_FAILED				>
	segxchg	ds,es
	lea	di,es:[di].FAE_fileName		
	mov	si,dx				; si <- offset to file name
	mov	cx,FONT_FILE_LENGTH
EC<	EC_BOUNDS	es di>
	LocalCopyNString
	dec	si
EC<	EC_BOUNDS	ds si>
	mov	{byte}ds:[si],TRUE
cont::
	call	FarUnlockInfoBlock
	pop	es
nextFont:
nextFontLoadError:
	dec 	ss:[fontCount]
	tst	ss:[fontCount]
	jz	done
	add	dx, size FileLongName
	jmp	addFontLoop
done:	
	;
	; unlock memory list passed in
	;
	mov	bx, ss:[fontFileList]
	call 	MemUnlock
	;
	; send out notification that fonts have been added
	;
	mov	cx,TRUE
	mov	ax,ss:[fontsAddedCount]
	mov	ds,ss:[fontsAddedList]
	call	FontSendAddDeleteNotification	; tell the world fonts
						; have been added
	;
	; free the memory allocated for the list of FontID's added
	;
	mov	bx, ss:[fontsAddedHandle]
	call	MemFree

almostExit:
	call	FilePopDir
exit:
	.leave
	ret

allocError:
	;
	; unlock memory list passed in
	;
	mov	bx, ss:[fontFileList]
	call 	MemUnlock
	jmp	almostExit

FontDrAddFonts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrFindFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the file name for a font from the fonts avail entry.

CALLED BY:	Global
PASS:		cx - FontID
		ds - locked font info segment
RETURN:		ds:si - ptr to font file name
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontDrFindFileName	proc	far
	uses	bx,di
	.enter

	call	FarIsFontAvail
	lea	si,ds:[di].FAE_fileName

	.leave
	ret
FontDrFindFileName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrGetFontIDFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the font ID from the file

CALLED BY:	Global
PASS:		ds:dx - ptr to filename
		assumes that already in the directory with the font
RETURN:		cx - FontID
		if error 
			cx - FID_INVALID
			carry set if there is an error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontDrGetFontIDFromFile	proc	far
fontID	local	FontID
	uses	ax,bx,dx,si,di,bp,ds
	.enter


	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY >
	call	FileOpen
	jc	openError
	
	mov_trash bx,ax				;bx <- file handle

	;
	; move to location of font id
	;
	clr	cx
	mov	dx,size FontFileInfo
	mov	al, FILE_POS_START
	call	FilePosFar			;read in the bytes
	
	;
	; read font ID into local fontID
	;
	clr	ax
	mov	cx, size FontID
	lea	dx, ss:[fontID]			
	segmov	ds,ss
	call	FileReadFar
	jc	readError

	mov	cx,ss:[fontID]

closeFile:
	pushf					; save carry if there
						; is an error
	clr	ax
	call 	FileCloseFar			; close the file	
	popf	
exit:
	.leave
	ret

openError:
	mov	cx,FID_INVALID
	jmp	exit
readError: 
	mov	cx,FID_INVALID
	jmp	closeFile

FontDrGetFontIDFromFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontSendAddDeleteNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a notification of that fonts have been
	added/deleted to/from the system along with a list of the FontIDs
	added/deleted 

CALLED BY:	FontDrAddFonts
PASS:		ax - number of fonts added or deleted 
		ds - pointer to list of FontID's added or deleted
		cx - Flag to tell whether to send out and added or
		deleted notifitcation if it is FALSE then send out 
		a deleted notification, else send out an added
		notification 
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	Sends GWNT_FONTS_ADDED notification that fonts have
been added to GCNSLT_FONT_CHANGES 

PSEUDO CODE/STRATEGY:
	copy the passed in list of FontID's to a new list.
	put at the beggining of this new list, the number of fonts
		added or removed.		
	record the message to send
	send the message
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontSendAddDeleteNotification	proc	near
fontsAddDelCount	local	word	push	ax
fontsAddDelFlag		local	word	push	cx
	uses	ax,bx,cx,dx,si,di,bp
	.enter 

	;
	; copy the old list of font ID's to a new one, which is the
	; exact size of the list
	;
	inc	ax			; add a word on for the count
	shl	ax,1
	mov	cx,ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAllocFar
	mov	es,ax
	mov	ax,ss:[fontsAddDelCount]
	clr	di
EC<	EC_BOUNDS	es di	>	
	stosw				; move count into first word
	clr	si
	mov_tr	cx,ax
EC<	EC_BOUNDS	es di	>	
	rep	movsw			; copy list
EC<	dec	di	>
EC<	EC_BOUNDS	es di>
EC<	inc	di	>	
	call	MemUnlock
	;
	; Initialize the reference count for the data block to 1, to
	; account for what GCNListSend does.
	; 
	mov	ax, 1
	call	MemInitRefCount
	;
	; Record the MSG_NOTIFY_FILE_CHANGE going to no class in particular.
	; 
	mov	dx, GWNT_FONTS_DELETED
	tst	ss:[fontsAddDelFlag]
	jz 	cont
	mov	dx, GWNT_FONTS_ADDED
cont:	
	push	bp
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	bp, bx
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage
	;
	; send the message
	;
	mov	cx, di				; cx <- event handle
	mov	bx, MANUFACTURER_ID_GEOWORKS	; bxax <- list ID
	mov	ax, GCNSLT_FONT_CHANGES
	mov	dx, bp				; dx <- data block
	mov	bp, mask GCNLSF_FORCE_QUEUE	
	call	GCNListSend
	pop	bp

	.leave
	ret
FontSendAddDeleteNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontLoadFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads a font into a font info structure

CALLED BY:	FontLoadFont (Internal)
PASS:		es:dx	name of file to load
RETURN:		bx - Handle of block with FontInfo structure
		ax - size of FontInfo & corresponding entries
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	open the font file
		if open failed then return with an open error
	Read the FontFileInfo structure in 
	check to make sure that it is a font file that we approve of 
	Allocate room for the FontInfo structur plus the associated
		entries
	Read the info from the file into this structure
	Clear the File Handle in the FontInfoStructure
	Close the file
	return the FontInfo structure	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	2/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontLoadFont	proc	near
fontFileInfo	local	FontFileInfo
fontFileHandle	local	hptr
fontInfoHandle	local	hptr
	uses	cx,dx,di,bp,si,ds
	.enter
	;
	; Open the font file using the name passed in
	;
	segmov	ds,es
	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY >
	call	FileOpen

LONG 	jc	done
	;
	; Read the signature and version # from the start of the file.
	; 
	mov_trash	bx, ax			;put file handle in bx
	mov	ss:[fontFileHandle], bx
	mov	cx, size fontFileInfo		;read in first few bytes

	lea	dx, ss:[fontFileInfo]
	segmov	ds, ss				;ds:dx <- dest buffer 

	clr	al				;return errors, please
EC<	EC_BOUNDS	ds dx	>	
	call	FileReadFar			;read in the bytes

EC <	jnc	noReadError			>;no problems, branch
EC <	cmp	ax, ERROR_SHORT_READ_WRITE	>;see if small file
EC < 	ERROR_NE GRAPHICS_BAD_FONT_FILE					>
EC <noReadError:							>
	LONG jc	closeFont

	;
	; Make sure the file's actually a font file that we can handle.
	; 
	cmp	ss:[fontFileInfo].FFI_signature, FID_SIG_LO
	LONG jne closeFont				;nope, branch
	cmp	ss:[fontFileInfo].FFI_signature[2], FID_SIG_HI
	LONG jne closeFont				;nope, branch
	cmp	ss:[fontFileInfo].FFI_majorVer, MAX_MAJOR_VER;can we deal with it?
	ja	closeFont				;nope, branch

	;
	; At this point, the file is a font file.  We will read the file into
	; a new chunk and save the font ID and chunk handle in the
	; fontsAvail list.
	;
	mov	ax, ss:[fontFileInfo].FFI_headerSize;make a chunk for the rest
	
	add	ax, FI_RESIDENT			;add room to store
						;file handle
	push	ax				;save the size of font
						;info + corresponding
	;					;data
	; allocate room for the font info structure & corresponding
	; entries
	;
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	jc	noMemError
	mov	ss:[fontInfoHandle],bx
	mov	ds,ax

	pop	cx				;cx <- size font info
	push	cx
	mov	dx, offset FI_fontID
	sub	cx, FI_RESIDENT			;not reading file handle
	clr	al
	mov	bx,ss:[fontFileHandle]	
EC<	EC_BOUNDS	ds dx>
	call	FileReadFar
EC <	ERROR_C	GRAPHICS_BAD_FONT_FILE					>

	mov	ds:[FI_fileHandle], 0	;clear file handle
	mov	bx, ss:[fontInfoHandle]
	call	MemUnlock
	pop	ax				;return size of Font
						;info & corresponding entries

closeFont:
	;
	; need to push and pop ax to save the size of the Font info &
	; corresponding entries, if they exist.
	;
	pushf
	push	ax		
	mov	ax, FILE_NO_ERRORS		
	mov	bx,ss:[fontFileHandle]
	call 	FileCloseFar			; close the file
	pop	ax
	popf

done::
	mov	bx,ss:[fontInfoHandle]
	.leave
	ret

noMemError:
	stc
	jmp	closeFont

FontLoadFont	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrDeleteFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the fonts from the system, associated with the
		list of file names passed in. If ax is TRUE the font
		will be deleted if it is in use. Will not delete the
		font if it is the default font.

CALLED BY:	
PASS:		bx - handle of font file list
		cx - number of font files found	
		ax - force delete flag
RETURN:		modify list of fonts passed in, see SIDE EFFECTS:
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	For every font file that was successfully deleted the
last byte of the font filename structure passed in for that font, will
be set to TRUE.  

PSEUDO CODE/STRATEGY:
	Lock the list of font file names
	allocate memory for list of successfully deleted FontID's
deleteLoop
	Find the FontID corresponding to the file name 
	Delete the font using the force delete flag.  (delete the font
		whether or not the font is in use)
	put true in the last byte of the FontFileName record passed
		in, indicating that the font has been deleted
	record the FontID of the successfully deleted font
	move on to the next font
end loop
	unlock the list of font file names
	send out notification that font files have been deleted.  Send
		the list of FontID's deleted with the notification
	free the memory allocated for the list of FontID's
	return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontDrDeleteFonts	proc	far
forceDeleteFlag	local	word	push 	ax
fontsDeletedList	local	word
fontsDeletedHandle	local	hptr
fontsDeletedCount	local	word
	uses	ax,bx,cx,dx,si,di,es,ds

	.enter

	tst	cx			;no fonts to delete
LONG	jz	exit

	clr	ss:[fontsDeletedCount]

	push	bx
	call	MemLock
	mov	si,ax			;si:dx <-ptr to font file names	
	clr	dx

	;
	; allocate room to store the list of FontID's deleted
	;
	push	cx
	mov	ax,cx			;ax <- # of Fonts to delete
	shl	ax,1
	mov	cx,ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	pop	cx			; font count
LONG	jc	allocError
	mov	ss:[fontsDeletedList],ax
	mov	ss:[fontsDeletedHandle],bx


deleteLoop:
	call 	FarLockInfoBlock
	call	FontDrFindFontIdByName
	call	FarUnlockInfoBlock	; preserves flags
	;
	; if the font was not found, move on to the next font
	;
	jnc	nextFont		; based on the carry flag from
					; FontDrFindFontIdByName
	push	bx
	push	cx
	mov	cx,bx
	mov	ax,forceDeleteFlag
	call	FontDrDeleteFontOpt
EC	<WARNING_C	FONT_DELETE_FAILED	>
	pop	cx
	pop 	bx
	jc	nextFont		; font was not deleted
	mov	es,si
	mov	di,dx			; mark font as deleted
	;
	; mark the font deleted it the FontDrDeleteFont returned
	; without an error
	;
	jc	nextFont
EC<	EC_BOUNDS	es di>
	mov	{byte}es:[di] + size FileLongName - 1, TRUE

	;
	; add the Font ID
	;
	push	es
	mov	es,ss:[fontsDeletedList]		;store fontID in 
	mov	di,ss:[fontsDeletedCount]		;buffer
	shl	di,1
EC<	EC_BOUNDS	es di>
	mov	es:[di],bx				;es:di <- FontID
	inc	ss:[fontsDeletedCount]
	pop 	es

nextFont:
	add	dx,size	FileLongName
	loop	deleteLoop

endLoop::
	pop	bx
	call	MemUnlock
	;
	; send out notification that fonts have been deleted
	;
	mov	ax,ss:[fontsDeletedCount]
	tst	ax
	jz	noNotification
	mov	cx,FALSE
	mov	ds,ss:[fontsDeletedList]
	call	FontSendAddDeleteNotification	; tell the world fonts
						; have been deleted
noNotification:
	;
	; free the memory allocated to store the list of FontID's
	; added because the notification has already been sent out
	;
	mov	bx,ss:[fontsDeletedHandle]
	call	MemFree	
	clc
exit:
	.leave
	ret

allocError:
	pop	bx
	call	MemUnlock
	jmp	exit

FontDrDeleteFonts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrFindFontIdByName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give the file name of a font, returns the font ID of
		that font

CALLED BY:	FontDrDeleteFonts
PASS:		si:dx	- ptr to font file name
		ds 	- seg address of font block
RETURN:		bx	- FontID
			Set carry if font found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Scan through the list of avail fonts, if the font file name of
		the FontsAvailEntry matches the file name passed,
		return the FontID and set carry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontDrFindFontIdByName	proc	near
	uses	ax,cx,dx,si,di,bp,es
	.enter
	;
	; carry is clear until the correct font is found
	;
	mov	cx,si
	clc						
	mov	di, ds:[FONTS_AVAIL_HANDLE]	;di <- ptr to chunk
	ChunkSizePtr	ds, di, ax		;ax <- chunk size
	add	ax, di				;ax -> end of chunk
IFA_loop:
	cmp	di, ax				;are we thru the list?
	jae	noMatch				;yes, exit carry clear
	lea	si,ds:[di].FAE_fileName
	push	di
	movdw	esdi,cxdx			;es:di < ptr to file name
	call	LocalCmpStrings
	pop	di
	je	match				;we have a match, branch
	add	di, size FontsAvailEntry	;else move to next entry
	jmp	IFA_loop			;and loop

match:
	mov	bx, ds:[di].FAE_fontID		;bx <- chunk handle
	stc					;indicate is available
noMatch:

	.leave
	ret
FontDrFindFontIdByName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrDeleteFontOpt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a font from the system. If ax is true the font
		is deleted even if it is in use.  Will not delete the
		font if it is the default font.

CALLED BY:	FontDrDeleteFonts
PASS:		cx - FontID value for the font
		ax - flag to force deletion of font
RETURN:		carry - set if error
		ax - error code (FontAddDeleteError)
DESTROYED:	nothing (ax if not returned)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontDrDeleteFontOpt	proc	near
	uses	bx,cx,dx
	.enter
	;
	; check to make sure not trying to delete the default font
	;
	push	ax
	push	cx
	call 	GrGetDefFontID
	pop	bx			;bx <- FontID passed in
	pop	ax
	cmp	cx,bx
	jz	defaultFontError

	mov	cx,bx			;cx <- FontID passed in	
	call	FontDrDeleteFontCommon
exit:
	.leave
	ret
defaultFontError:
	stc
	mov	ax, FADE_DEFAULT_FONT
	jmp	exit
FontDrDeleteFontOpt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrDeleteFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a font from the system
CALLED BY:	GLOBAL

PASS:		cx - FontID value for font
		references to its in use entry
RETURN:		carry - set if error
		    ax - error code (FontAddDeleteError)
DESTROYED:	none (ax if not returned)

PSEUDO CODE
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 3/92		Initial version
	IP	03/30/94 	seperated common code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontDrDeleteFont	proc	far
	.enter
	clr	ax
	call	FontDrDeleteFontCommon
	.leave
	ret
FontDrDeleteFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontDrDeleteFontCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a font from the system
CALLED BY:	GLOBAL

PASS:		cx - FontID value for font
		ax - flag if true deletes the font if there are still
		references to its in use entry
RETURN:		carry - set if error
		    ax - error code (FontAddDeleteError)
DESTROYED:	none (ax if not returned)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontDrDeleteFontCommon	proc	near
	uses	bx, cx, dx, ds, si, di
forceDeleteFlag	local	word	push	ax
	.enter

	call	FarLockInfoBlock		;ds <- seg addr of font info
	;
	; See if the font is even in the system
	;
	call	FarIsFontAvail			;is font in system?
LONG	jnc	noSuchFontError			;branch if no such font
	mov	dx, di				;ds:dx <- ptr to FontsAvailEntry
	sub	dx, ds:[FONTS_AVAIL_HANDLE]	;dx <- offset of FontsAvailEntry
	;
	; See if it is in use any where
	;
	mov	si, ds:[FONTS_IN_USE_HANDLE]	;ds:si <- ptr to in use chunk
	ChunkSizePtr	ds, si, ax		;ax <- size of chunk
	add	ax, si				;ds:ax <- end of chunk
inUseLoop:
	cmp	si, ax				;end of list?
	jae	endList				;all done
	mov	bx, ds:[si].FIUE_dataHandle	;bx <- handle of data
	tst	bx				;entry in use?
	jz	nextFont			;branch if not in use
	cmp	cx, ds:[si].FIUE_attrs.FCA_fontID ;our font?
	jne	nextFont			;branch if not same
						;font
	;
	; if the force delete flag is set, then we want to delete the
	; font whether or not there are references to it
	;
	tst	ss:[forceDeleteFlag]
	jnz	killIt
	tst	ds:[si].FIUE_refCount		;font in use?
	jnz	inUseError			;branch if font in use
	jmp	cont
killIt:
	;
	; mark the in use entry as invalid
	;
	or	ds:[si].FIUE_flags, mask FBF_IS_INVALID
	;
	; if the there are still references to the font do not free it
	;
	tst	ds:[si].FIUE_refCount		;font in use?
	jnz	nextFont
cont:
	;
	; if the ref count is zero then free the font data
	;
	call	MemFree
	clr	ds:[si].FIUE_dataHandle
nextFont:
	add	si, (size FontsInUseEntry)	;ds:si <- next entry
	jmp	inUseLoop

	;
	; We've checked (and possibly freed) all references to the
	; font.  Now nuke its FontsAvailEntry and FontInfo chunk.
	;
	; ds:di - ptr to FontsAvailEntry from FarIsFontAvail()
	;
endList:
	mov	ax, ds:[di].FAE_infoHandle	;ax <- chunk handle of FontInfo
	mov	si, ax
	mov	si, ds:[si]			;ds:si <- ptr to FontInfo
	call	RemoveFontFileFromCache
	call	DeleteOutlineEntriesData
	call	LMemFree
	mov	ax, FONTS_AVAIL_HANDLE		;ax <- chunk handle
	mov	bx, dx				;bx <- ofset of deletion
	mov	cx, (size FontsAvailEntry)	;cx <- # of bytes to delete
	call	LMemDeleteAt
	clc					;carry <- no error
done:
	call	FarUnlockInfoBlock		;done with font info

	.leave
	ret

noSuchFontError:
	mov	ax, FADE_NO_SUCH_FONT		;ax <- FontAddDeleteError
errorCommon:
	stc					;carry <- error
	jmp	done

inUseError:
	mov	ax, FADE_FONT_IN_USE		;ax <- FontAddDeleteError
	jmp	errorCommon
FontDrDeleteFontCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteOutlineEntriesData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	frees any memory referenced by handles in the
		OutlineEntries found in FontInfo

CALLED BY:	FontDrDeleteFontCommon
PASS:		ds:si
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Don't need to clear the handle entries because the structure
	they are in will be freed as soon as this routine returns

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteOutlineEntriesData	proc	near
if DBCS_PCGEOS
PrintMessage <fix DeleteOutlineEntriesData for DBCS>
else
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; calculate how many outline data entries there are
	;
	mov	bp,ds:[si].FI_outlineTab
	mov	ax,ds:[si].FI_outlineEnd

deleteLoop:	
	cmp	bp,ax
	jz	endLoop
	
	mov	bx,ds:[si][bp].ODE_header.OE_handle
	tst	bx
	jz	cont1
	;
	; free the memory
	;
	call	MemFree
cont1:
	mov	bx,ds:[si][bp].ODE_first.OE_handle
	tst	bx
	jz	cont2
	;
	; free the memory
	;
	call	MemFree
cont2:
	mov	bx,ds:[si][bp].ODE_second.OE_handle
	tst	bx
	jz	cont3
	;
	; free the memory
	;
	call	MemFree
cont3:
	add	bp,size OutlineDataEntry
	jmp	deleteLoop
endLoop:
	.leave
endif
	ret
DeleteOutlineEntriesData	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveFontFileFromCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a font file from the cache and close it

CALLED BY:	FontDrDeleteFont()
PASS:		ds - P'locked
		ds:si - ptr to FontInfo
		ds:di - ptr to FontsAvailEntry
RETURN:		none
DESTROYED:	bx, cx

PSEUDO CODE/STRATEGY:
	NOTE: we don't bother clearing the FI_fileHandle field because
	the chunk will be deleted after this call, and we have exclusive
	access to the block so no one will see it in the mean time.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveFontFileFromCache		proc	near
	uses	ax, es, di

	mov	bx, ds:[si].FI_fileHandle	;bx <- file handle if open
	tst	bx				;file open?
	jz	quit				;branch if not open

	.enter

	;
	; Close the file
	;
	clr	al				;al <- flags
	call	FileCloseFar
	;
	; Find the font in the cache and remove it.  We simply
	; zero the entry and let RecordNewFontFile() fill it in
	; when it needs it.
	;
	mov	ax, ds:[di].FAE_fontID		;ax <- FontID
	mov	di, ds:[FONT_FILE_CACHE_HANDLE]
	ChunkSizePtr ds, di, cx
	shr	cx, 1				;cx <- # of entries
	segmov	es, ds				;es:di <- ptr to file cache
	repne	scasw				;find font ID
EC <	ERROR_NE FONTMAN_FILE_CACHE_CORRUPTED	;>
	mov	{FontID}ds:[di][-(size FontID)], FID_INVALID

	.leave
quit:
	ret
RemoveFontFileFromCache		endp

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckFontInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify a FontInfo structure
CALLED BY:	FontDrAddFont()

PASS:		ds:si - ptr to FontInfo
		cx - FontID of font
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckFontInfo	proc	near
	uses	ax, dx
	.enter

	pushf
	;
	; FontID match?
	;
	cmp	cx, ds:[si].FI_fontID
	ERROR_NE FONTMAN_BAD_FONT_INFO_FOR_ADD_FONT
	;
	; Pointsize pointers ordered and large enough?
	;
	mov	ax, ds:[si].FI_pointSizeEnd
	tst	ax				;any PointSizeEntry?
	jz	noPointsizes1
	cmp	ax, (size FontInfo)		;large enough?
	ERROR_B	FONTMAN_BAD_FONT_INFO_FOR_ADD_FONT
	cmp	ax, ds:[si].FI_pointSizeTab	;ordered correctly?
	ERROR_BE FONTMAN_BAD_FONT_INFO_FOR_ADD_FONT
noPointsizes1:
	;
	; Are there an integral number of PointSizeEntry's?
	;
	sub	ax, ds:[si].FI_pointSizeTab	;ax <- size
	jz	noPointsizes2
	mov	dl, (size PointSizeEntry)	;dl <- size of PointSizeEntry
	div	dl
	tst	ah				;any remainder?
	ERROR_NZ FONTMAN_BAD_FONT_INFO_FOR_ADD_FONT
noPointsizes2:
	;
	; Outline pointers ordered and large enough?
	;
	mov	ax, ds:[si].FI_outlineEnd
	tst	ax				;any OutlineDataEntry's?
	jz	noOutlines1
	cmp	ax, (size FontInfo)		;large enough?
	ERROR_B	FONTMAN_BAD_FONT_INFO_FOR_ADD_FONT
	cmp	ax, ds:[si].FI_outlineTab	;ordered correctly?
	ERROR_BE FONTMAN_BAD_FONT_INFO_FOR_ADD_FONT
noOutlines1:
	;
	; Are there an integral number of OutlineDataEntry's?
	;
	sub	ax, ds:[si].FI_outlineTab	;ax <- size
	jz	noOutlines2
	mov	dl, (size OutlineDataEntry)	;dl <- size of OutlineDataEntry
	div	dl
	tst	ah				;any remainder?
	ERROR_NZ FONTMAN_BAD_FONT_INFO_FOR_ADD_FONT
noOutlines2:

	popf

	.leave
	ret
ECCheckFontInfo	endp

endif

FontDriverCode	ends
