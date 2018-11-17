COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Convert
FILE:		convertGeoDex.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	11/92		Initial version

DESCRIPTION:
	This file contains utility stuff for converting from 1.X to 2.0

	$Id: convertGeoDex.asm,v 1.1 97/04/04 17:52:49 newdeal Exp $

------------------------------------------------------------------------------@

ConvertGeoDex segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertOldGeoDexDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert 1.X GeoDex document.

CALLED BY:	(INTERNAL)

PASS:		bp - VM file handle

RETURN:		none

DESTROYED:	none

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	11/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertOldGeoDexDocument	proc	far
	uses ax, bx, cx, dx, si, di, ds, es, bp

	groupID		local	word
	mapBlk		local	word
	oldPhoneBlk	local	word
	newPhoneBlk	local	word
	curSize		local	word
	counter		local	word
	offsetToStr	local	word

	mov	bx, bp				; bx = file handle

	.enter

	call	DBGetMap			; ax = group di = item
	mov	groupID, ax			; save group ID
	mov	mapBlk, di			; save map item

	; resize the map block

	mov	cx, size MapData		; cx = size of new map block
	call	DBReAlloc			; make map block bigger  
	call	DBLock				; lock the map block
	mov	di, es:[di]

	; default sort option is ignore spaces and punctuations

	mov	es:[di].sortOption, mask SF_IGNORE_SPACE

	; now recover prefix and area code from old map block

	push	di
	mov	cx, DIAL_OPTION_TEXT_SIZE+1	; cx - # of words to move

	; move prefix and current area code stings down by one word

	mov	ax, es:[di].curLanguage
nextChar:
	mov	dx, word ptr es:[di].prefix
	mov	word ptr es:[di].prefix, ax
	mov	ax, dx
	add	di, 2
	loop	nextChar
	pop	di

	; there is no assumed area code

	mov	es:[di].assumedAreaCode, 0

	; get current language value 

	call	LocalGetLanguage		; ax - StandardLanguage
	mov	es:[di].curLanguage, ax		; save it!

	; get old phone block handle & total number of phone type names 

	mov	ax, es:[di].phoneTypeBlk
	mov	oldPhoneBlk, ax
	mov	ax, es:[di].totalPhoneNames	
	mov	counter, ax

	; we have to subtract one here because the actual number of
	; phone type names in data block is one less than this number

	dec	counter
	call	DBUnlock			; unlock the map block

	; allocate new phone type block and lock it

	mov	ax, groupID			; ax - group ID
	mov	cx, (MAX_NEW_PHONE_TYPE_NAME+7)*2 ; cx - size of new phone blk 
	mov	curSize, cx			; save the size
	call	DBAlloc
	mov	newPhoneBlk, di			; save the chunk handle
	call	DBLock
	mov	di, es:[di]			

	; first word holds the size of the entire block

	mov	es:[di], cx		

	; next word holds the offset to blank default phone type name

	mov	es:[di+2], (MAX_NEW_PHONE_TYPE_NAME+6)*2
	add	di, (MAX_NEW_PHONE_TYPE_NAME+6)*2
	mov	word ptr es:[di], 0		; blank phone type name
	call	DBUnlock			; unlock new phone block

	; now copy the phone type names from the old block to the new blk

	; first, lock the old phone type block

	mov	dx, 1				; phone type name counter
	mov	di, oldPhoneBlk
	call	DBLock
next:
	push	di				; save chunk handle
	mov	di, es:[di]

	; locate the phone type name string to copy

	mov	ax, dx
	shl	ax, 1
	add	ax, 2				; ax - offset to offset
	mov	si, di
	add	si, ax				
	mov	ax, es:[si]			; ax - offset to string
	add	di, ax				; es:di - string to copy
	mov	offsetToStr, ax

	; es:di - pointer to the string to copy

	call	LocalStringSize			; cx - size of phone string
	inc	cx				; add one for null char
	segmov	ds, es				; save ES in DS

	; now resize the new phone type block
	; so we can add this new phone type string

	push	cx
	add	cx, curSize			; cx - size of new phone blk
	mov	curSize, cx			; update the stack frame
	mov	di, newPhoneBlk			; di - DB item
	mov	ax, groupID			; ax - group ID
	call	DBReAlloc			; make it bigger!
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di]			; ax - offset to copy string to
	mov	es:[di], cx			; save new block size

	; new update the phone type name block 
	; with the new offset to strings 

	push	di
	mov	cx, dx				; cx - counter
	shl	cx, 1
	add	cx, 2
	add	di, cx				; es:di - place to write to
	mov	es:[di], ax			; write out the new offset
	pop	di

	add	di, ax				; es:di - destination
	pop	cx				; cx - number of bytes to copy
	pop	si				; restore chunk handle

	; copy the string

	push	si
	mov	si, ds:[si]
	add	si, offsetToStr			; ds:si - source string
	rep	movsb				; copy the string
	call	DBUnlock			; unlock new phone block
	pop	di				; chunk handle of old phone blk

	segmov	es, ds				; es - seg addr of old phone
	inc	dx
	cmp	dx, counter			; are we done?
	jne	next				; if not, continue
	call	DBUnlock			; unlock old phone block

	; now free the old phone type block 

	mov	ax, groupID			; ax - group ID
	mov	di, oldPhoneBlk			; di - DB item
	call	DBFree				; free this block

	; update the map block with new phone block ID
	
	mov	di, mapBlk
	call	DBLock	
	mov	di, es:[di]
	mov	ax, newPhoneBlk
	mov	es:[di].phoneTypeBlk, ax
	call	DBUnlock

	.leave
	ret
ConvertOldGeoDexDocument	endp

ConvertGeoDex ends
