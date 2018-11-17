COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Folder
FILE:		folderUtils.asm
AUTHOR:		Brian Chin

ROUTINES:
	INT	ExposeFolderObjectIcon - create gState and draw one object
	INT	GetFolderObjectIcon - get correct icon for folder object
	INT	GetFolderObjectName - get name for folder object
	INT	GetFolderObjectBoundBox - get bounding box of folder object's
						icon/name pair
	INT	CheckGEOSFile - check if a GEOS file
	INT	PrepESDIForError - get 8.3 and 32 filename ready for error
					reporting
	INT	GetNextMappingEntry - get next entry in mappings list
	INT	GetTokenFromMapField - get token from map field
	INT	PrintTimeField - print hours, minutes, or seconds
	INT	PrintWordAX - print ASCII version of hex word
	INT	PrintWordAXDX - print ASCII version of hex dword

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/89		Initial version

DESCRIPTION:
	This file contains utility routines for the Folder object.

	$Id: cfolderUtils.asm,v 1.1 97/04/04 14:59:26 newdeal Exp $

------------------------------------------------------------------------------@

FolderCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExposeFolderObjectIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create gState and draw icon for this folder object

CALLED BY:	INTERNAL
			FolderObjectPress
			DeselectAll

PASS:		*ds:si - FolderClass object 
		es:di - pointer to folder buffer entry for object
		ax =	mask DFI_CLEAR to clear
			mask DFI_DRAW to draw
			mask DFI_CLEAR to clear
			mask DFI_GREY to clear

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExposeFolderObjectIcon	proc	far
	class	FolderClass
	uses	bp
	.enter

EC <	call	ECCheckFolderRecordESDI		>

	DerefFolderObject	ds, si, bx
	mov	bp, ds:[bx].DVI_gState		; get gState

;this can happen if you resize GeoManager window to smallest possible (such
;that the GenView in the Folder Windows aren't visible, then open a new
;Folder Window - brianc 11/8/90

	tst	bp
	jz	done

EC <	push	ax, di							>
EC <	mov	ax, GIT_WINDOW						>
EC <	mov	di, bp							>
EC <	call	GrGetInfo						>
EC <	tst	ax							>
EC <	ERROR_Z NO_GSTATE						>
EC <	pop	ax, di							>

	call	DrawFolderObjectIcon		; pass bp=gState, es:di=entry
done:
	.leave
	ret
ExposeFolderObjectIcon	endp

InvertIfTarget	proc	far
	class	FolderClass
	uses	bx
	.enter

	DerefFolderObject	ds, si, bx

GM <	test	ds:[bx].FOI_folderState, mask FOS_TARGET	>
GM <	jz	done						>
	mov	ax, mask DFI_INVERT
	call	ExposeFolderObjectIcon
GM< done:							>
	.leave
	ret
InvertIfTarget	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFolderObjectName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get name for this folder object

CALLED BY:	INTERNAL
			DrawFolderObjectIcon (for displaying name)
			DrawFullFileDetail (for displaying name)
			BuildBounds (to compute name length)

PASS:		es:bp - pointer to folder buffer entry for this object

RETURN:		ds:si - pointer to name for this object

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/31/89		Initial version
	brianc	12/7/89		change for long filename support
	ardeb	1/29/92		changes for IFS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFolderObjectName	proc	near
	segmov	ds, es				; ds = name segment
	lea	si, es:[bp].FR_name
	stc					; always a long name
	ret
GetFolderObjectName	endp

FolderCode	ends

;-----------------------------------------------------------------------------

FolderOpenCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrepESDIForError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	prepare 8.3 and 32-character filenames ready for error
		reporting mechanism

CALLED BY:	INTERNAL
			FileOpenESDI
			LaunchGeosFile

PASS:		es:di - folderRecord

RETURN:		fileOperationInfoEntryBuffer - contains 8.3 and 32-character
				filenames of file, ready for error reporter

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrepESDIForError	proc	far
		uses	ds, si, es, di, cx
		.enter
		segmov	ds, es, si
		mov	si, di
NOFXIP <	segmov	es, dgroup, di					>
FXIP	<	mov	di, bx						>
FXIP	<	GetResourceSegmentNS dgroup, es, TRASH_BX		>
FXIP	<	mov	bx, di						>
		mov	di, offset dgroup:fileOperationInfoEntryBuffer

		CheckHack <size FR_name eq size FOIE_name and \
		offset FOIE_name eq 0>

		CheckHack <(offset FR_name) eq 0>
		mov	cx, size FOIE_name
		rep movsb
		.leave
		ret
PrepESDIForError	endp

FolderOpenCode	ends

;-----------------------------------------------------------------------------

FolderCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextMappingEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get next entry in mappings list

CALLED BY:	INTERNAL
			CheckNonGEOSTokenMapping
			GetDatafileCreator

PASS:		ds:si - mappings list

RETURN:		ds:si - updated to point past next mapping entry
		carry clear if next mapping entry available
			mappingField1 - first field of mapping
			mappingField2 - second field of mapping
		carry set if no more mapping entries

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextMappingEntry	proc	far
DBCS <	push	dx							>
	push	ax, es, di
NOFXIP<	segmov	es, dgroup, ax						>
FXIP  <	mov	ax, bx							>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP  <	mov	bx, ax							>
	mov	di, offset dgroup:mappingField1
SBCS <	clr	ah				; not doing token field	>
DBCS <	clr	dl				; not doing token field	>
nextChar1:
	LocalGetChar	ax, dssi		; get char
	call	HandleTokenField		; check if in token field
	jnz	notField1End			; yes, don't skip anything

	LocalCmpChar	ax, ' '			; check if white space
	je	nextChar1
SBCS <	cmp	al, VC_TAB						>
DBCS <	LocalCmpChar	ax, C_TAB					>
	je	nextChar1
SBCS <	cmp	al, VC_LF						>
DBCS <	LocalCmpChar	ax, C_LINEFEED					>
	je	nextChar1
SBCS <	cmp	al, VC_ENTER						>
DBCS <	LocalCmpChar	ax, C_ENTER					>
	je	nextChar1			; if so, skip this char

	LocalIsNull	ax			; end of mapping list ?
	stc					; in case end
	jz	endOfMappings			; if so, done
	LocalCmpChar	ax, '='			; end of field1 ?
	jne	notField1End			; no
	;
	; end of field1, null-terminate buffer for field1
	;
SBCS <	clr	al				; null-terminator for field1 >
DBCS <	clr	ax				; null-terminator for field1 >
notField1End:
	LocalPutChar esdi, ax			; else, store field1 character
	LocalIsNull	ax
	jnz	nextChar1			; if not end of field1, loop
	;
	; begin copying field2
	;
	mov	di, offset dgroup:mappingField2
nextChar2:
	LocalGetChar ax, dssi			; get char of field2
	call	HandleTokenField		; check if in token field
	jnz	notField2End			; yes, don't skip anything

	cmp	ax, ' '				; check if white space
	je	nextChar2
SBCS <	cmp	al, VC_TAB						>
DBCS <	cmp	ax, C_TAB						>
	je	nextChar2			; yes, skip this char.

	LocalIsNull ax				; end of field2 ?
;;	jz	field2End			; yes
;;must leave a null for next time around - 7/17/90
	jnz	notEnd				; nope
	LocalPrevChar dssi			; point back at null
	jmp	short field2End
notEnd:
;;
SBCS <	cmp	al, VC_ENTER			; end of field2 ?	>
DBCS <	cmp	ax, C_ENTER			; end of field2 ?	>
	jne	notField2End			; no
field2End:
SBCS <	clr	al				; null-terminator for field2 >
DBCS <	clr	ax				; null-terminator for field2 >
notField2End:
	LocalPutChar esdi, ax			; store field2 character
	LocalIsNull	ax			; if not end of field2, loop
	jnz	nextChar2
	clc					; success
endOfMappings:
	pop	ax, es, di
DBCS <	pop	dx							>
	ret
GetNextMappingEntry	endp

HandleTokenField	proc	near
	LocalCmpChar	ax, '"'			; entering token field?
	jne	notTokenField
SBCS <	not	ah				; mark doing token field >
DBCS <	not	dl				; mark doing token field >
notTokenField:
SBCS <	tst	ah				; doing token field?	>
DBCS <	tst	dl				; doing token field?	>
	ret
HandleTokenField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTokenFromMapField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	load up token registers from map field

CALLED BY:	INTERNAL
			CheckNonGEOSTokenMapping
			GetDatafileCreator

PASS:		ds:si = mapping field

RETURN:		ax:bx:si = token
		cx = 1 past terminator of ID

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTokenFromMapField	proc	far
	;
	; NOTE: the token chars are in a DBCS string (read from GEOS.INI),
	; but are SBCS chars so the high byte of each DBCS char is ignored.
	;
	LocalNextChar dssi			; skip '"'
	LocalGetChar ax, dssi
	mov	cl, al				; save first token char
	LocalGetChar ax, dssi
SBCS <	mov	ah, al							>
DBCS <	mov	ch, al							>
	LocalGetChar ax, dssi
	mov	bl, al
	LocalGetChar ax, dssi
	mov	bh, al
SBCS <	mov	al, cl				; ax:bx = token		>
DBCS <	mov	ax, cx				; ax:bx = token		>
	LocalNextChar dssi			; skip '"'
	LocalNextChar dssi			; skip ','
	push	ax, bx				; save it
	call	GetTokenManufID			; si <- ds:si
	pop	ax, bx				; retrieve token chars.
	ret
GetTokenFromMapField	endp

GetTokenManufID	proc	near
	mov	bx, 10				; base 10
	clr	cx				; cx = value
digitLoop:
	LocalGetChar ax, dssi
	LocalCmpChar ax, '0'			; if not numeric, done
	jb	done
	LocalCmpChar ax, '9'
	ja	done
SBCS <	clr	ah							>
	sub	ax, '0'				; convert to value
	xchg	ax, cx
	mul	bx				; dx:ax <- digit * 10
	add	ax, cx
	mov	cx, ax				; cx = new value
	jmp	short digitLoop
done:
	xchg	si, cx				; return token's manuf. ID
	ret
GetTokenManufID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintFileSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	print ASCII version of filesize

CALLED BY:	INTERNAL
			DrawFullFileDetail

PASS:		ax:dx - filesize
		di - graphics state
		bx - Y position for filesize

RETURN:		

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/14/89		Initial version
	brianc	11/189		right justify

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintFileSize	proc	near
	uses	ds, si, es, di, cx, bp
	.enter
	sub	sp, 20				; plenty of room to be safe
	mov	bp, di				; save GState
	mov	di, ss
	mov	es, di
	mov	ds, di
	mov	di, sp				; es:di = file size buffer
	mov	si, sp				; ds:si = file size string
	call	ASCIIizeDWordAXDX
	mov	di, bp				; retrieve GState
	mov	cx, -1				; null-term'ed
	call	GrTextWidth			; dx = length of filesize
if _ZMGR and SEPARATE_NAMES_AND_DETAILS
;	mov	ax, ss:[separateFileSizeEndPos]
;just put it near the right edge of the screen - brianc 5/10/93
	mov	ax, ZMGR_FULL_DATES_RIGHT_BOUND
else
	mov	ax, ss:[fullFileDatePos]
endif
	sub	ax, LONG_TEXT_HORIZ_SPACING
	sub	ax, dx				; ax = X position for filesize
						; bx = Y position for filesize
	clr	cx				; file size is null-term'ed
	call	GrDrawText
	add	sp, 20
	.leave
	ret
PrintFileSize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSetCurPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the current path from this folder's vardata. If
		that can't be done, set the FOS_BOGUS flag for all to
		see and enjoy

PASS:		*ds:si	- FolderClass object
		ds:di	- FolderClass instance data
		es	- segment of FolderClass

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear
			ax - destroyed

DESTROYED:	nothing 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderSetCurPath	method	dynamic	FolderClass, 
					MSG_FOLDER_SET_CUR_PATH
		uses	dx
		.enter
		
		mov	ax, ATTR_FOLDER_PATH_DATA
		mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
		jnc	done

		call	FolderSendCloseViaQueue ; sets the BOGUS flag
		stc
done:
		.leave
		ret
FolderSetCurPath	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetNonGEOSTokenOfCreator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Global utility routine to determine if a given
		file name is associated with a non-GEOS token specified
		in the ini file.  If so, return the token of the
		file's CREATOR, not the file itself.

CALLED BY:	GLOBAL

PASS:		ds:si	= filename (NULL-Terminated) (can be whole path)

RETURN:		carry clear if token found
			ax:bx:si - token
		carry set if no token

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Create a FolderRecord and call CheckNonGEOSTokenMapping.
		This function exists because FolderRecord is an internal
		structure not used by other modules.  We then return the
		token stored in the FR_creator field.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	10/11/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetNonGEOSTokenOfCreator	proc	far
	uses	cx, dx, ds, es, di
	.enter

	; Need to get just tail of filename if a full path is provided.
	; Move to end of string
	segmov	es, ds, di
	clr	di				; es:di = filename
	clr	al				; looking for null
	mov	cx, 1000h			; cx = large number for rep
	repne scasb
	; (Better be a match!)
EC <	ERROR_NE ILLEGAL_PATH						>
	dec	di				; es:di points to NULL
	mov	cx, di				; cx = len string (di-0)
	push	cx				; save strlen
	dec	di				; es:di points to last char
	std					; go backwards
	mov	al, '\\'			; look for blackslash
	repne scasb
	pop	cx				; original strlen
	jne	dssiEqFilename			; no path elts, done
	inc	di
	inc	di				; es:di points to tail
	sub	cx, di				; adjust strlen
	mov	si, di				; ds:si now points to tail

dssiEqFilename:
	cld					; restore direction flag
	push	cx				; strlen
	mov	ax, size FolderRecord
	mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	pop	cx				; strlen
	jc	done				; carry set - no token
	push	bx				; save handle
	mov	es, ax
	clr	di				; es:di = FolderRecord

    CheckHack <(offset FR_name) eq 0>		; es:di <- ptr to name
	
	rep movsb				; copy filename

	clr	di				; reset di
	call	CheckNonGEOSTokenMapping
	jc	noToken				; no match at all
	mov	di, offset FR_creator		; else get creator token
	mov	ax, {word} es:[di].GT_chars	; from FolderRecord (still
	mov	dx, {word} es:[di].GT_chars+2	; locked at this point.)
	mov	si, es:[di].GT_manufID
	tst	ax				; make sure creator token
	jnz	haveToken			; has been filled in
	tst	dx
	stc
	jz	noToken				; dang, no token
haveToken:
	clc					; oh, token.. we're cool

noToken:
	pop	bx				; FolderRecord Handle
	pushf					; preserve carry flag
	call	MemFree				; free the FolderRecord
	popf
	mov	bx, dx				; restore part of token, if any

done:
	.leave
	ret
FolderGetNonGEOSTokenOfCreator	endp


FolderCode ends
