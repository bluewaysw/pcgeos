COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		amateurJoke.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/14/92   	Initial version.

DESCRIPTION:
	

	$Id: amateurJoke.asm,v 1.1 97/04/04 15:12:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AMATEUR_MAX_JOKE_FILE_SIZE	=	32000


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentReadJokeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the text file and read it into a buffer

CALLED BY:	ContentInitialize

PASS:		*ds:si - content

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentReadJokeFile	proc near
	uses	ax,bx,cx,dx,di,bp,es

	class	AmateurContentClass 

	.enter

EC <	call	ECCheckContentDSSI		>  

	push	ds, si


	;
	; Open the file
	;

	segmov	ds, es			; dgroup
	mov	dx, offset dataDirName
	mov	bx, SP_USER_DATA
	call	FileSetCurrentPath
	jc	errorPopDSSI


	mov	dx, offset jokeFileName
	mov	al, FILE_ACCESS_R or FILE_DENY_NONE
	call	FileOpen
	jc	errorPopDSSI

	; The file is open.  Get its size and allocate a VM block

	mov	bx, ax
	call	FileSize
	tst	dx
	jnz	errorPopDSSI		; 

	cmp	ax, AMATEUR_MAX_JOKE_FILE_SIZE
	ja	errorPopDSSI	

	inc	ax			; increase file size by 1
	push	ax, bx			; file size, handle
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc		
	mov	bp, bx			; mem handle
	pop	cx, bx			; file size, handle
	jc	errorPopDSSI		; unable to allocate
	mov	ds, ax

	push	bx			; file handle
	mov	bx, cx			; file size
	mov	{byte} ds:[bx], 0	; make sure the buffer is
					; null-terminated 
	pop	bx			; file handle

	clr	al
	clr	dx
	dec	cx
	call	FileRead		; read the whole file into a buffer
	jc	errorPopDSSI

	call	FileClose

	segmov	es, ds			; file buffer
	pop	ds, si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].ACI_jokeHandle, bp
	mov	ds:[di].ACI_bufferSize, cx

	; now, count how many jokes

	call	ContentCountJokes

	mov	bx, bp
	call	MemUnlock
	
done:
	.leave
	ret

errorPopDSSI:
	pop	ds, si
	jmp	done


ContentReadJokeFile	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentCountJokes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Separate each joke by a null character, stick
		the number of jokes in the content's instance data

CALLED BY:

PASS:		ds:di - content
		es - joke buffer
		cx - buffer size

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentCountJokes	proc near
	uses	ax,bx,cx,dx,di,si,bp
	class	AmateurContentClass 
	.enter

	push	di
	clr	di, dx		; current pointer, number of jokes

	call	GotoNextNonBlankLine
	jc	done

startLoop:
	inc	dx		; one more joke
	call	GotoNextBlankLine
	jc	done

	; Null-terminate the previous joke by storing a 0 at es:[di-2]

	mov	{byte} es:[di-2], 0

	; Now, continue until the next non-blank line

	call	GotoNextNonBlankLine
	jnc	startLoop

done:
	pop	di
	mov	ds:[di].ACI_jokeCount, dx

	.leave
	ret
ContentCountJokes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoNextNonBlankLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the next non-blank line

CALLED BY:

PASS:		es:di - current position
		cx - size to end of buffer

RETURN:		es:di, cx updated

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

	Will return pointer to the current line, if the current line
	is non-blank


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GotoNextNonBlankLine	proc near
	.enter

startLoop:
	call	IsLineBlank?
	jnc	done

	call	GotoNextLine
	jc	done
	jmp	startLoop

done:

	.leave
	ret
GotoNextNonBlankLine	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoNextBlankLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the next blank line

CALLED BY:	

PASS:		es:di - current position
		cx - number of characters to end of buffer

RETURN:		es:di, cx updated
		carry set if arrived at end of file

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GotoNextBlankLine	proc near
	.enter

startLoop:
	call	IsLineBlank?
	jc	found

	call	GotoNextLine
	jc	done		; return carry set
	jmp	startLoop

found:
	clc
done:
	.leave
	ret

GotoNextBlankLine	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoNextLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		es:di - current position
		cx - number of chars remaining in buffer

RETURN:		es:di - next line
		cx - number of chars remaining
		carry set if overran buffer

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

	Scan for a Line-Feed character.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GotoNextLine	proc near
	uses	ax
	.enter
	mov	al, VC_LF
	repne	scasb
	jcxz	endOfBuffer
	clc
done:
	.leave
	ret
endOfBuffer:
	stc
	jmp	done

GotoNextLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsLineBlank?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine whether the current line is blank

CALLED BY:

PASS:		es:di - joke buffer position
		cx - number of bytes left

RETURN:		carry set if line blank

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	If there are any non-blank characters before the next
line-feed or comment character, then return TRUE (carry set) else
return FALSE.


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsLineBlank?	proc near
	uses	cx, di
	.enter
	
startLoop:
	mov	al, es:[di]

	; check end-of-line conditions
	
	cmp	al, VC_CTRL_M
	je	yesBlank
	cmp	al, JOKE_COMMENT
	je	yesBlank

	; check for whitespaces

	cmp	al, ' '		; space
	je	continue
	cmp	al, '	'	; tab
	je	continue

	; not blank.

	jmp	notBlank

continue:
	inc	di
	loop	startLoop

yesBlank:
	stc	

done:
	.leave
	ret

notBlank:
	clc
	jmp	done



IsLineBlank?	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentChooseJoke
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pick a joke at random and set the joke VisText object
		with the joke.

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentChooseJoke	proc near
	uses	ax,bx,cx,dx,di,si,bp,es
	class	AmateurContentClass 
	.enter

EC <	call	ECCheckContentDSSI		>  

	; check the Jokes boolean group to see if jokes are on

	push	si
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	bx, handle JokesList
	mov	si, offset JokesList
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	si
	jc	done
	

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	test	ds:[di].ACI_gameAttrs, mask GCA_JOKES
	jz	noJoke

	mov	bx, ds:[di].ACI_jokeHandle
	tst	bx
	jz	noJoke

	; Are there any jokes in the buffer?

	mov	dx, ds:[di].ACI_jokeCount
	tst	dx
	jz	noJoke

	call	GameRandom		; number in DX

	push	bx
	call	MemLock
	mov	es, ax
	
	mov	cx, ds:[di].ACI_bufferSize
	clr	di

	
	inc	dx
startLoop:
	call	GotoNextNonBlankLine
	dec	dx
	jz	gotJoke

	; There can't be an error here, because we've already counted
	; the jokes

	call	GotoNextBlankLine
EC <	ERROR_C JOKE_FILE_ERROR		>
	jmp	startLoop

gotJoke:

	; now, es:di points to the joke text.  

	call	SetJokeText

	pop	bx
	call	MemUnlock


	mov	bx, handle JokeSummons
	mov	si, offset JokeSummons
	call	UserDoDialog
	stc
done:

	.leave
	ret

noJoke:
	clc
	jmp	done
ContentChooseJoke	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetJokeText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup the joke text and stick it in the text object

CALLED BY:	ContentChooseJoke

PASS:		es:di - joke text

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetJokeText	proc near
	uses	ax,bx,cx,dx,di,si,bp,ds,es

	.enter

	segmov	ds, es
	mov	si, di

	sub	sp, MAX_JOKE_TEXT_LENGTH
	mov	di, sp
	segmov	es, ss

	; ds:si - source joke text
	; es:di - destination

	mov	cx, MAX_JOKE_TEXT_LENGTH-1

	; Don't copy LF characters, and don't overrun limit

	push	di
startLoop:
	lodsb
	cmp	al, VC_LF
	je	nextChar
	stosb
nextChar:
	loop	startLoop

	pop	si

	; strip out non-geos characters.

	segmov	ds, es
	clr	cx
	mov	ax, ' '
	call	LocalDosToGeos

	mov	bp, si
	mov	dx, ds		; now, dx:bp is the text

	mov	bx, handle JokeTextDisplay
	mov	si, offset JokeTextDisplay
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage


	add	sp, MAX_JOKE_TEXT_LENGTH	

	

	.leave
	ret
SetJokeText	endp

