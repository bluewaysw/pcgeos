COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		ninfntIDs.asm

AUTHOR:		Gene Anderson, Jun 14, 1991

ROUTINES:
	Name				Description
	----				-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/14/91		Initial revision

DESCRIPTION:
	

	$Id: ninfntIDs.asm,v 1.1 97/04/04 16:16:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssignFontID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assign a PC/GEOS FontIDs value to this font
CALLED BY:	ConvertNimbusFont()

PASS:		ds:si - ptr to FontConvertEntry
RETURN:		carry - set if error
			ax - NimbusError
DESTROYED:	ax (if no error)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AssignFontID	proc	near
	.enter

	tst	ds:[si].FCE_fontID		;ID already assigned?
	jnz	inUse				;branch if already in use
	;
	; When the font name database gets done, this is a prime place
	; to make the call, John :-)
	;

	;
	; The name can't be found in the font name database, so we
	; assign the font an ID in the 'unmappable' range.
	;
	call	AssignUnmappableID
	jc	done				;branch if error

	mov	ds:[si].FCE_fontID, ax		;store new FontIDs value
	clc					;carry <- no error
done:
	.leave
	ret

inUse:
	mov	ax, NE_FONT_ID_IN_USE		;ax <- NimbusError
	stc					;carry <- error
	jmp	done
AssignFontID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssignUnmappableID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assign a FontIDs value in the Nimbus 'unmappable' range.
CALLED BY:	AssignFontID()

PASS:		ds:si - ptr to FontConvertEntry
RETURN:		ax - FontIDs value assigned
		carry - set if error
			ax - NimbusError
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	To increase (admittedly only slightly) the chances of two separate
	uses getting the same FontIDs value assigned to the same font,
	we hash on the font name string.  This value, after being normalized
	to the correct range, is used as a FontIDs value.  The value is
	checked for prior existance.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack	<FONT_INVALID eq 0>

AssignUnmappableID	proc	near
	uses	bx, cx, dx, si
	.enter

	mov	si, ds:[si].FCE_name		;*ds:si <- name string
	call	HashOnChunkString		;ax <- hash value
	;
	; See if the name already exists in the system
	;
	mov	si, ds:[si]			;ds:si <- ptr to string
	mov	dl, mask FEF_STRING or mask FEF_OUTLINES or mask FEF_DOWNCASE
	call	GrIsFontAvail			;does font name exist?
	cmp	cx, FONT_INVALID		;font exists?
	jne	fontExists			;branch if font already exists
	;
	; Make a copy of the font name for the FileEnum() callback
	;
	DoPush	ax, di, es
	segmov	es, udata, ax
	mov	di, offset checkFontName	;es:di <- ptr to buffer
charLoop:
	lodsb					;al <- character of string
	stosb					;store character
	tst	al				;end of string?
	jnz	charLoop			;loop while more
	DoPopRV	ax, di, es

	;
	; Normalize the value to the MAKER_NIMBUSQ range, and within
	; that range, to the FG_NON_PORTABLE family.
	;
CheckHack <FONT_FAMILY_DIVISIONS eq 0x200 >
	andnf	ax, 0x1ff
	add	ax, (MAKER_NIMBUSQ + FG_NON_PORTABLE)
	mov	bx, ax				;bx <- inital FontIDs value
	clr	dl				;dl <- FontEnumFlags
idLoop:
	push	ax
	call	IsIDAssigned?			;font already been converted?
	jc	errorOccurred
	pop	ax
	jcxz	success				;branch if not in use
	;
	; Try the next ID.  Check to see if we've wrapped around to
	; the first ID we tried.  If so, no IDs are available.
	;
	inc	ax				;ax <- try next id
	cmp	ax, bx				;check against initial value
	je	noIDs				;branch if wrapped around
	;
	; See if we've reached the end of our allotted range.  If so,
	; wrap around to the start of our allotted range.
	;
	cmp	ax, (MAKER_NIMBUSQ + FG_NON_PORTABLE + FONT_FAMILY_DIVISIONS)
	jne	idLoop				;go try next next ID
	mov	ax, (MAKER_NIMBUSQ + FG_NON_PORTABLE)
	jmp	idLoop

success:
	clc					;carry <- no error
done:
	.leave
	ret

noIDs:
	mov	ax, NE_NO_FONT_ID		;ax <- NimbusError
	stc					;carry <- error
	jmp	done

fontExists:
	mov	ax, NE_FONT_EXISTS		;ax <- NimbusError
	stc					;carry <- error
	jmp	done

errorOccurred:
	pop	bx				;clear stack
	jmp	done
AssignUnmappableID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsIDAssigned?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if font ID 
CALLED BY:	AssignUnmappableID()

PASS:		cx - FontIDs value to check
RETURN:		cx - 0 if FontIDs value not in use
		carry - set if error
			ax - NimbusError
DESTROYED:	ax (if not returned)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

fontNameString	char "*.FNT",0

IsIDAssigned?	proc	near
	uses	bx, dx, bp, ds
	.enter

	;
	; See if the font (ID) is available in the system.
	;
	mov	cx, ax				;ax <- current ID
	call	GrIsFontAvail			;is font in system?
	tst	cx
	jnz	done				;branch if in use
	;
	; See if the font (ID) has already been assigned to a font
	; we converted during this session.
	;
	; Set up the stack for the FileEnumParams.
	;
	segmov	ds, udata, dx
	mov	ds:checkFontID, ax		;pass FontIDs value
	mov	ds:checkError, -1		;no error

	sub	sp, size FileEnumParams
	mov	bp, sp
	;
	; Search for everything that matches "*.FNT" in the FONT directory.
	;
	call	FilePushDir
	mov	ax, SP_FONT			;ax <- StandardPath
	call	FileSetStandardPath

	mov	ss:[bp].FEP_fileTypes,	mask FEFT_FILES or \
					mask FEFT_NON_GEOS
	mov	ss:[bp].FEP_searchFlags, mask FESF_CALLBACK or \
					 mask FESF_NAME
	clr	ax
	mov	ss:[bp].FEP_returnFlags, al
	mov	ss:[bp].FEP_skipCount, ax
	mov	ss:[bp].FEP_bufSize, ax
	mov	ss:[bp].FEP_callback.high, cs
	mov	ss:[bp].FEP_callback.low, offset CheckForID
	mov	ss:[bp].FEP_name.high, cs
	mov	ss:[bp].FEP_name.low, offset fontNameString
	call	FileEnum
	mov	cx, dx				;cx <- file count (0 if nomatch)
	call	FilePopDir
	jcxz	noError				;branch if no match (ie. OK)
	cmp	ds:checkError, -1		;is this really error?
	je	noError				;not error (ie. match found)
	mov	ax, ds:checkError		;ax <- NimbusError
	stc					;carry <- error
	jmp	done

noError:
	clc					;carry <- no error
done:
	.leave
	ret
IsIDAssigned?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check one font file to see if FontIDs value is in use.
CALLED BY:	IsIDAssigned?() via FileEnum()

PASS:		es:di - DosFileInfoStruct for current file
		ss:bp -  FileEnumParams struct

RETURN:		carry - if FontIDs value found
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckForID	proc	far
	uses	ax, bx, cx, dx, si, di, bp, ds, es
fontHeader	local	FontFileHeader
	.enter

	;
	; (try to) open the file
	;
	segmov	ds, es
	lea	dx, ds:[di].DFIS_name		;ds:dx <- DOS name
	mov	al, FileAccessFlags <FE_EXCLUSIVE, FA_READ_ONLY>
	call	FileOpen
	jc	noMatch				;branch if can't open
	mov	bx, ax				;bx <- file handle
	;
	; Seek to the start
	;
	mov	al, FILE_SEEK_START
	clr	cx
	mov	dx, cx				;cx:dx <- offset (0)
	call	FilePos
	;
	; Get the FontFileInfo from the file and verify it is a PC/GEOS
	; font file.
	;
	lea	dx, ss:fontHeader
	segmov	ds, ss				;ds:dx <- ptr to buffer
	mov	cx, (size FontFileHeader)	;cx <- # of bytes
	call	FileRead			;read me jesus
	call	FileClose			;no further need
	jc	noMatch				;branch if error
	cmp	{word}ss:fontHeader.FFH_fileInfo.FFI_signature, FONT_SIG_LOW
	jne	noMatch
	cmp	{word}ss:fontHeader.FFH_fileInfo.FFI_signature[2], FONT_SIG_HIGH
	jne	noMatch

	segmov	ds, udata, ax
	mov	ax, ds:checkFontID		;ax <- FontIDs to check
	cmp	ax, ss:fontHeader.FFH_fontID	;FontIDs match?
	je	match				;branch if matches
	segmov	es, ss
	lea	dx, ss:fontHeader.FFH_name	;es:dx <- ptr to file font name
	mov	si, offset checkFontName	;ds:si <- ptr to our font name
	clr	cx				;cx <- NULL-terminated
	mov	di, DR_LOCAL_CMP_STRINGS_NO_CASE
	call	SysLocalInfo
	je	stringsMatch			;branch if strings match
noMatch:
	stc					;carry <- ID not found
done:

	.leave
	ret

stringsMatch:
	mov	ds:checkError, NE_FONT_EXISTS
match:
	clc					;carry <- ID found
	jmp	done
CheckForID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashOnChunkString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assign a hash value based on a string in an lmem chunk
CALLED BY:	AssignUnmappableID()

PASS:		*ds:si - ptr to string (NULL-terminated)
RETURN:		ax - hashed value (0-65536)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HashOnChunkString	proc	near
	uses	si, cx
	.enter

	mov	si, ds:[si]			;ds:si <- ptr to string
	ChunkSizePtr	ds, si, cx		;cx <- length of string
	call	HashOnString

	.leave
	ret
HashOnChunkString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashOnString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assign a hash value based on a string
CALLED BY:	AssignUnmappableID()

PASS:		ds:si - ptr to string (NULL-terminated)
		cx - length of string (not including NULL)
RETURN:		ax - hashed value (0-65536)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	hash = length(string);
	for (i = 0; i < length(string) ; i++) {
		hash = (hash*7)%(2^16) + string[i];
	}
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HashOnString	proc	near
	uses	si, dx, bx, cx
	.enter

	mov	dx, cx				;dx <- hash value (length)
	clr	ax				;ah <- high byte of character
charLoop:
	mov	bx, dx				;bx <- hash value * 1
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1				;dx <- hash value * 8
	sub	dx, bx				;dx <- hash value * 7
	lodsb					;ax <- character
	add	dx, ax				;dx <- new hash value
	loop	charLoop

	mov	ax, dx				;ax <- hashed value
	.leave
	ret
HashOnString	endp

ConvertCode	ends
