COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	NIKE
MODULE:		
FILE:		mainAbbrev.asm

AUTHOR:		Lulu Lin, Aug 23, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT WPReadAbbrevPhrase      To read in the abbreviated phrase from
				disk.

    INT WriteAbbrevToMemCallBack 
				See message declaration

    INT WALBringUpDialogBox     To bring up a user dialog box with the
				string handle and offset passed in.

    INT CreateGStringVisMoniker Create a complex VisMoniker, using the
				Graphics System GString creation
				capability.

    INT CheckEmptyAbbrevPhrase  To check whether the user has typed both
				the abbreviation and the phrase in the
				dialog box.

    INT AbbrevGetTargetTextOD   To get the current text object having the
				target.

    INT ExpandAbbrevCallBack    Call back routine to expand an abbreviation
				into the phrase in the database.

    INT ChunkArrayCheckDuplicateAbbrev 
				check if the phrase enters already exists
				in the abbreviation database.

    INT CheckDuplicateAbbrevCallBack 
				To check each chunk array element against
				with the abbreviation passed in to see if
				the same abbreviation has existed in the
				data base.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/23/94   	Initial revision


DESCRIPTION:

	Implement the abbreviated phrase for GeoWrite where the user
could input up to MAX_ABBREV_PHRASE_PHRASE sets of abbreviated phrase.
Then expand will expand the current text to the corresponding phrase
if the text exists in the abbreviated database.

	$Id: mainAbbrev.asm,v 1.1 97/04/04 15:57:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _ABBREVIATED_PHRASE

include assert.def
include gstring.def

idata	segment
	WriteAbbrevListClass
idata	ends

DocAbbrevFeatures segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try to load abbreviated phrases.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALVisOpen	method dynamic WriteAbbrevListClass, 
					MSG_VIS_OPEN
	mov	di, offset WriteAbbrevListClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].WriteAbbrevList_offset
	tst	ds:[di].WALI_carray.chunk
	jnz	done

	; Try to load abbreviated phrases

	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	UserCallApplication

	push	ds:[LMBH_handle]
	mov	bp, 1		; don't want warning for file format
	call	WPReadAbbrevPhrase
	pop	bx
	call	MemDerefDS

	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	GOTO	UserCallApplication
done:
	ret
WALVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WPReadAbbrevPhrase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To read in the abbreviated phrase from disk.

CALLED BY:	WPGenProcessOpenApplication
PASS:		bp 	= set if no warning wanted
			  clear if warning wanted
RETURN:		nothing
DESTROYED:	ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WPReadAbbrevPhrase	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		call	FilePushDir
		
		mov	ax, SP_DOCUMENT
		call	FileSetStandardPath
		jc	done	
if 0
		; only register in real demo
		mov	al, SP_DOCUMENT	
		call	DiskRegisterDiskSilently
endif
		mov	ax, mask FOARF_ADD_CRLF or FILE_ACCESS_RW or \
			    FILE_DENY_NONE
		segmov	ds, cs
		mov	dx, offset AbbrevFileName
		call	FileOpenAndRead
		jc	done

		push	bx
	; ax = mem handle, bx = file handle, cx = buffer size
		mov_tr	dx, ax
		mov	ax, MSG_WAL_STORE_ABBREV_PHRASE_TO_CHUNK_ARRAY
		GetResourceHandleNS	AbbrevPhraseObj, bx
EC <		Assert	handle, bx					>
		mov	si, offset AbbrevPhraseObj
		mov	di, mask MF_CALL
EC <		call	ECCheckResourceHandle				>
		call	ObjMessage

		clr	al
		pop	bx
		call	FileClose

done:
		call	FilePopDir

		.leave
		ret
WPReadAbbrevPhrase	endp

AbbrevFileName	char	"ABBREV", C_NULL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALClearAbbrevPhrase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message declaration


CALLED BY:	MSG_WAL_CLEAR_ABBREV_PHRASE
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALClearAbbrevPhrase	method dynamic WriteAbbrevListClass, 
					MSG_WAL_CLEAR_ABBREV_PHRASE
	.enter
	mov	si,ds:[di].WALI_carray.chunk
	cmp	si, NULL
	je	done
	call	ChunkArrayZero
	movdw	ds:[di].WALI_carray, NULL
done:
	.leave
	ret
WALClearAbbrevPhrase	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALStoreAbbrevPhraseToChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message declaration

CALLED BY:	MSG_WAL_STORE_ABBREV_PHRASE_TO_CHUNK_ARRAY
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
		cx	= buffer size
		dx 	= mem handle
		bp	= set if no warning wanted
			  clear if warning about file format wanted
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALStoreAbbrevPhraseToChunkArray	method dynamic WriteAbbrevListClass, 
					MSG_WAL_STORE_ABBREV_PHRASE_TO_CHUNK_ARRAY
warning		local	word	push bp
bufferSize	local	word	push cx
objChunk	local	word	push si
chunkArrayChunk	local	word
stringLength	local	word

		uses	ax, cx, dx, bp
		.enter
		cmp	ds:[di].WALI_carray.handle, NULL
		je	readPhraseToChunkArray
dataBaseExists::
		GetResourceHandleNS	ExistInMemoryStr, bx
		mov	ax, offset ExistInMemoryStr
		mov	cl, 1
		clr	ch
		call	WALBringUpDialogBox
		cmp	ax, IC_NO
		LONG	je	done

		push	si
		mov	si, ds:[di].WALI_carray.chunk
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayZero
		pop	si

readPhraseToChunkArray:
		push	si
		tst	ss:[bufferSize]
		LONG	jz	freeMemBlock

	; create chunk array and assign it to the object's instance data
		clr	bx
		mov	cx, size ChunkArrayHeader
		clr	si
		mov	al, mask OCF_IGNORE_DIRTY
		call	ChunkArrayCreate
		mov	ss:[chunkArrayChunk], si
		mov	bx, ds:[OLMBH_header].LMBH_handle
		
		pop	di
		mov	di, ds:[di]
		add	di, ds:[di].WriteAbbrevList_offset
		mov	ds:[di].WALI_carray.handle, bx
		mov	ds:[di].WALI_carray.chunk, si

	; lock down the memory block and read abbrev and phrase
	; 
		mov	bx, dx		; handle of block
		call	MemLock
		mov	es, ax		
		clr	di		; es:[di] = string

scanOneLineIntoChunkArray:
		mov	cx, MAX_ABBREV_LENGTH + 1
		push	di
SBCS <		mov	al, VC_BLANK					>
SBCS <		repne	scasb						>
DBCS <		mov	ax, VC_BLANK					>
DBCS <		repne	scasw						>
		LONG	jne	invalidFileFormat
		sub	cx, MAX_ABBREV_LENGTH + 1
		not	cx
		inc	cx		; cx = length w/ null
		mov	ss:[stringLength], cx

	; replace blank space with null
		LocalPrevChar	esdi
CheckHack <	VC_NULL eq 0						>
		clr	ax		; VC_NULL
		LocalPutChar	esdi, ax

	; scan the phrase string and carriage return, line feed
		mov	cx, MAX_PHRASE_LENGTH + 2
SBCS <		mov	al, VC_ENTER					>
SBCS <		repne	scasb						>
DBCS <		mov	ax, VC_ENTER					>
DBCS <		repne	scasw						>

	; replace blank space with null
		LocalPrevChar	esdi
CheckHack <	VC_NULL eq 0						>
		clr	ax		; VC_NULL
		LocalPutChar	esdi, ax

SBCS <		mov	al, VC_LF					>
SBCS <			scasb						>
DBCS <		mov	ax, VC_LF					>
DBCS <			scasw						>
		LONG	jne	invalidFileFormat

	; compute the exact string for the size of the chunk array elt
	; decrement the buffer size according to the string length
		sub	cx, MAX_PHRASE_LENGTH + 2
		not	cx
		inc	cx
		add	ss:[stringLength], cx
		mov	cx, ss:[stringLength]
		sub	ss:[bufferSize], cx
		dec	ss:[bufferSize]					
DBCS <		dec	ss:[bufferSize]					>
		mov	ax, cx
DBCS <		shl	cx						>

		mov	si, ss:[chunkArrayChunk]
		call	ChunkArrayAppend	; ds:di = new element
		segxchg	ds, es			; es:di = string dest
		pop	si			; ds:si = string src
		LocalCopyNString	SAVE_REGS
		segxchg	ds, es			
		mov	di, si
		add	di, cx			
	; increment di to skip the line feed
		inc	di			; es:di = next string
		
	cmp	ss:[bufferSize], 0
		jg	scanOneLineIntoChunkArray

endOfFileReach::

		push	bp			; preserve frame pointer
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	si, ss:[chunkArrayChunk]
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayGetCount
		mov	si, ss:[objChunk]

EC <		Assert	objectPtr, dssi, WriteAbbrevListClass		>

		call	ObjCallInstanceNoLock
freeMemBlock:
EC <		call	ECCheckMemHandle				>
		call	MemFree

	;
	; check if the maximum pair of abbreviation has reached.
	; if reach disable the add trigger
	;
		mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS

EC <		Assert	objectPtr, dssi, WriteAbbrevListClass		>

		call	ObjCallInstanceNoLock	; cx = # of item
		pop	bp			; frame pointer
		cmp	cx, MAX_ABBREV_PHRASE_PAIR
		jl	done

		push	bp		; frame pointer
		GetResourceHandleNS	AddAbbrevTrigger, bx
		mov	si, offset AddAbbrevTrigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp		; frame pointer
done:

	.leave
	ret

invalidFileFormat:
		tst	ss:[warning]
		jnz	done
	; bring up an error notification dialog box
		GetResourceHandleNS	InvalidFileFormatStr, bx
		mov	ax, offset InvalidFileFormatStr
		mov	ch, 1
		clr	cl
		call	WALBringUpDialogBox
		jmp	done

WALStoreAbbrevPhraseToChunkArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALLoadAbbrevPhrase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message declaration

CALLED BY:	MSG_WAL_LOAD_ABBREV_PHRASE
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALLoadAbbrevPhrase	method dynamic WriteAbbrevListClass, 
					MSG_WAL_LOAD_ABBREV_PHRASE
		uses	ax, cx, dx, bp
		.enter

		clr	bp		; warning wanted
		call	WPReadAbbrevPhrase

		.leave
		ret
WALLoadAbbrevPhrase	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALSaveAbbrevPhrase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message declaration

CALLED BY:	MSG_WAL_SAVE_ABBREV_PHRASE
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALSaveAbbrevPhrase	method dynamic WriteAbbrevListClass, 
					MSG_WAL_SAVE_ABBREV_PHRASE
selfSptr	Local	word	push	ds
selfLptr	Local	word	push	si
memSegment	Local	word
memHandle	Local	word

		uses	ax, cx, dx, bp
		.enter
		call	FilePushDir

		mov	ax, SP_DOCUMENT
		call	FileSetStandardPath
		LONG jc	done
	; 
	; check whether there is abbrev database on disk already
if 0
		; only register in real demo
		mov	al, SP_DOCUMENT
		call	DiskRegisterDiskSilently
endif
		mov	ax, mask FOARF_ADD_CRLF or FILE_ACCESS_RW or \
			    FILE_DENY_NONE
		segmov	ds, cs
		mov	dx, offset AbbrevFileName
		call	FileOpen
		jc	writeDataToDisk
		mov	bx, ax
		call	FileClose
diskAbbrevExists::
		GetResourceHandleNS	ExistInDiskStr, bx
		mov	ax, offset ExistInDiskStr
		mov	cl, 1
		clr	ch
		call	WALBringUpDialogBox
		cmp	ax, IC_NO
		LONG	je	done
		mov	ax, mask FOARF_ADD_CRLF or FILE_ACCESS_RW or \
			    FILE_DENY_NONE
	;
	; if the chunk array is null, just destroy the abbreviation file
	;
		cmp	ds:[di].WALI_carray.chunk, NULL
		LONG	je	destroyAbbrevFile

writeDataToDisk:
	;	
	; allocate and lock a memory block and write out the data
	; (one byte memory allocated)
		mov	ax, 1
		mov	cl, mask HF_SWAPABLE
		mov	ch, mask HAF_LOCK or mask HAF_ZERO_INIT
		call	MemAlloc		; bx = handle, ax = address
		LONG	jc	notEnoughMemory
		mov	ss:[memSegment], ax
		mov	ss:[memHandle], bx
	;
	; use chunk array enum to write out the abbreviation and
	; phrase in memory to a memory block
	;
		mov	dx, bx
		mov	ds, ss:[selfSptr]
		mov	si, ss:[selfLptr]
		mov	di, ds:[si]
		add	di, ds:[di].WriteAbbrevList_offset
		mov	si, ds:[di].WALI_carray.chunk 	; *ds:si = carray
		mov	bx, cs
		mov	di, offset WriteAbbrevToMemCallBack ; bx:di = callback

		cmp	si, NULL
		LONG	je	destroyAbbrevFile

EC <		call	ECCheckChunkArray				>
		call	ChunkArrayGetCount	; cx = # of elemnt
		tst	cx
		LONG	jz	destroyAbbrevFile
		clr	cx		; position in memory

		call	ChunkArrayEnum
		push	cx			; size of mem to write
						; to file
		mov	bx, ss:[memHandle]
EC <		call	ECCheckMemHandle				>
		call	MemUnlock
	;
	; open file, file write and close file
	;
fileCreate::
		segmov	ds, cs
		mov	dx, offset AbbrevFileName
		mov	ah, 1 shl offset FCF_NATIVE or \
			    FILE_CREATE_TRUNCATE shl offset FCF_MODE \
			    or FILE_DENY_NONE
		mov	al, FE_NONE shl offset FAF_EXCLUDE or FA_WRITE_ONLY
CheckHack <	FILE_ATTR_NORMAL eq	0				>
		clr	cx		; no FileAttrs
		call	FileCreate	; ax = file handle
		jc	fileError
		push	ax		; file handle

		mov	bx, ss:[memHandle]
EC <		call	ECCheckMemHandle				>
		call	MemLock		; bx = handle, ax = segment
		mov	ss:[memSegment], ax

		pop	bx		; file handle
		pop	cx		; size of mem
		mov	ds, ax
		clr	al
		clr	dx
		call	FileWrite

		push	bx		; file handle
		mov	bx, ss:[memHandle]
EC <		call	ECCheckMemHandle				>
		call	MemUnlock

		pop	bx		; file handle
		clr	ax
		call	FileClose
		jc	fileError
done:
		call	FilePopDir
		.leave
		ret

notEnoughMemory:
		GetResourceHandleNS	NotEnoughMemoryStr, bx
		mov	ax, offset NotEnoughMemoryStr
		mov	cl, 1
		mov	ch, 1	
		call	WALBringUpDialogBox
		jmp	done
fileError:
		GetResourceHandleNS	FileErrorStr, bx
		mov	ax, offset FileErrorStr
		mov	cl, 1
		mov	ch, 1	
		call	WALBringUpDialogBox
		jmp	done

destroyAbbrevFile:
		segmov	ds, cs
		mov	dx, offset AbbrevFileName
		call	FileDelete
		jmp	done

WALSaveAbbrevPhrase	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteAbbrevToMemCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message declaration

CALLED BY:	
PASS:		*ds:si = array
		ds:di = array element being enumerated
		ax = mem address
		cx = current position in memory to write the abbrev.
		dx = mem handle
RETURN:		ax = mem address
		cx = new position of memory the next string should be
		dx = mem handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteAbbrevToMemCallBack	proc	far
memoryPos	Local	word	push	cx

		uses	ax, bx, dx, si,di
		.enter

		mov	bx, dx
EC <		call	ECCheckMemHandle				>

;		segmov	es, ds		; es:di = source	
	;
	; reallocate the memory block to fit the both the abbreviation
	; and the phrase of this chunk array element
	;
		mov	si, di		; ds:si = element
		mov	di, ss:[memoryPos]	; es:di = mem
scanLength::
		mov	cx, -1
	; scan until reaching Null terminator, then write to memory block
		mov	ax, es		; exchange the segment register
		segmov	es, ds
		mov	ds, ax
		xchg	si, di		; es:di = array element
SBCS <	mov	al, VC_NULL						>
SBCS <	repne	scasb							>
SBCS <	mov	al, VC_NULL						>
SBCS <	repne	scasb							>

DBCS <	mov	ax, VC_NULL						>
DBCS <	repne	scasw							>
DBCS <	mov	ax, VC_NULL						>
DBCS <	repne	scasw							>
		mov	ax, es		; exchange the segment register
		segmov	es, ds
		mov	ds, ax
		xchg	si, di		; es:di = mem

		not	cx		; length of the abbrev + phrase
		mov	ax, cx		; size of memory
		sub	si, cx		; ds:si = point to abbreviation
EC <		call	ECCheckMemHandle				>

		mov	ax, MGIT_SIZE
		call	MemGetInfo
		add	ax, cx

		mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
		call	MemReAlloc	; ax = mem segment, bx = mem handle
		jc	notEnoughMemory

		mov	es, ax				
	; copy the abbrevation and change the null terminated to space
		LocalCopyString		
		LocalPrevChar	esdi
		mov	ax, VC_BLANK
		LocalPutChar	esdi, ax

	; copy the phrase
		LocalCopyString
	;
	; add the carrige return and the line feed after each line
	;
		LocalPrevChar	esdi
SBCS <		mov	al, VC_ENTER					>
SBCS <		stosb							>
SBCS <		mov	al, VC_LF					>
SBCS <		stosb							>

DBCS <		mov	ax, VC_ENTER					>
DBCS <		stosw							>
DBCS <		mov	ax, VC_LF					>
DBCS <		stosw							>

EC <		call	ECCheckMemHandle				>
		call	MemUnlock
		mov	cx, di		; preserve the position in memory
done:
		.leave
		ret

notEnoughMemory:
		GetResourceHandleNS	NotEnoughMemoryStr, bx
		mov	ax, offset NotEnoughMemoryStr
		clr	cl
		mov	ch, 1
		call	WALBringUpDialogBox
		jmp	done

WriteAbbrevToMemCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALEditAbbrevPhrase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	see message declaration

CALLED BY:	MSG_WAL_EDIT_ABBREV_PHRASE
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALEditAbbrevPhrase	method dynamic WriteAbbrevListClass, 
					MSG_WAL_EDIT_ABBREV_PHRASE
SBCS <	abbrevPair local MAX_ABBREV_LENGTH + MAX_PHRASE_LENGTH + 2 dup (char)>
DBCS <	abbrevPair local MAX_ABBREV_LENGTH + MAX_PHRASE_LENGTH + 2 dup (wchar)>

		uses	ax, cx, dx, bp
		.enter
	;
	; set the instance data flag to edit mode
	;
		mov	ds:[di].WALI_mode, WAMF_EDIT

	;
	; replace abbreviation field and phrase field in modification
	; dialog box to the abbreviation pair selected from the
	; dynamic list
	;
		push	bp		; preserve frame pointer
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock	; ax = current selection
		pop	bp		; frame pointer
		cmp	ax, GIGS_NONE
		LONG	je	noSelectionFound

	; NOTE: chunk array is in the same data block as the
	; object

		mov	si, ds:[di].WALI_carray.chunk
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayElementToPtr	; cx = elmt size
						; ds:di = element
		mov	bx, cx			; length of pair
		mov	cx, -1
		segmov	es, ds			; es:di = element
SBCS <		mov	al, VC_NULL					>
SBCS <		repne	scasb						>
		not	cx			; length of abbrev
		sub	di, cx			; ds:di = abbreviation
		mov	si, di			; ds:si = abbreviation
	;
	; copy the abbreviation into the local variable
	;
		push	bp			; frame pointer
		segmov	es, ss
		lea	di, abbrevPair		; es:di = abbrev(dest)
		LocalCopyString			; es:di = phrase
		LocalCopyString 		; copy the phrase

	;
	; put the selected abbreviation to the Abbreviation field in the
	; dialog box
	;
		push	cx		; length of the pair
		sub	di, bx		; es:di = point to abbreviation
		movdw	dxbp, esdi	; dx:bp = point to abbreviation
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		GetResourceHandleNS	AbbreviationName, bx
		mov	si, offset AbbreviationName
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage	
	;
	; put the selected phrase to the Phrase field in the dialog box
	;
		pop	cx		; length of the pair
		pop	bp
		push	bp		; frame pointer
		segmov	es, ss
		mov	dx, es
		lea	bp, abbrevPair
		add	bp, cx		; dx:bp = point to phrase
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		GetResourceHandleNS	AbbreviationPhrase, bx
		mov	si, offset AbbreviationPhrase
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage

		pop	bp			; frame pointer

	;
	; initiate the dialog box to modify the abbreviation and phrase
	; (change the moniker of the dialog box to "edit"
	;
		push	bp			; frame pointer
		GetResourceHandleNS AbbrevPhraseModificationDialog, bx
		mov	si, offset AbbrevPhraseModificationDialog
		mov	cx, offset EditAbbrevMoniker	; chunk of visMoniker
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		GetResourceHandleNS	AbbrevPhraseModificationDialog, bx
		mov	si, offset AbbrevPhraseModificationDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
	;
	; enable the save trigger since the database has been changed
	;
		GetResourceHandleNS	SavePhraseTrigger, bx
		mov	si, offset SavePhraseTrigger
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp		; frame pointer

done:
		.leave
		ret

noSelectionFound:
		GetResourceHandleNS	NoItemSelectedStr, bx
		mov	ax, offset NoItemSelectedStr
		mov	ch, 1
		clr	cl
		call	WALBringUpDialogBox
		jmp	done

WALEditAbbrevPhrase	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALDeleteAbbrevPhrase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message declaration

CALLED BY:	MSG_WAL_DELETE_ABBREV_PHRASE
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALDeleteAbbrevPhrase	method dynamic WriteAbbrevListClass, 
					MSG_WAL_DELETE_ABBREV_PHRASE
		uses	ax, cx, dx, bp
		.enter

		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock	; ax = pos of elmt
		cmp	ax, -1
		je	noItemSelected

		push	si			; obj chunk handle
		mov	si, ds:[di].WALI_carray.chunk
		mov	cx, 1
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayDeleteRange

		pop	si			; obj chunk handle
		push	bp
		mov	cx, ax
		mov	dx, 1
		mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
		call	ObjCallInstanceNoLock
		pop	bp

enableAddItem::
		GetResourceHandleNS	AddAbbrevTrigger, bx
		mov	si, offset AddAbbrevTrigger
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		GetResourceHandleNS	SavePhraseTrigger, bx
		mov	si, offset SavePhraseTrigger
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
	.leave
	ret

noItemSelected:
		GetResourceHandleNS	NoItemSelectedStr, bx
		mov	ax, offset NoItemSelectedStr
		mov	ch, 1
		clr	cl
		call	WALBringUpDialogBox
		jmp	done
		
WALDeleteAbbrevPhrase	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALDeleteAllAbbrevPhrase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message declaration

CALLED BY:	MSG_WAL_DELETE_ALL_ABBREV_PHRASE
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALDeleteAllAbbrevPhrase	method dynamic WriteAbbrevListClass, 
					MSG_WAL_DELETE_ALL_ABBREV_PHRASE
		uses	ax, cx, dx, bp
		.enter

		GetResourceHandleNS	DeleteAllWarningStr, bx
		mov	ax, offset DeleteAllWarningStr
		mov	cl, 1
		clr	ch
		call	WALBringUpDialogBox
		cmp	ax, IC_NO
		je	done

		cmp	ds:[di].WALI_carray.chunk, NULL
		je	done

		mov	ax, MSG_WAL_CLEAR_ABBREV_PHRASE
		call	ObjCallInstanceNoLock

		clr	cx		; zero item in abbrev list
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallInstanceNoLock
	
	; enable the Add trigger and the Save trigger
		push	bp		; frame pointer
		GetResourceHandleNS	AddAbbrevTrigger, bx
		mov	si, offset AddAbbrevTrigger
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		GetResourceHandleNS	SavePhraseTrigger, bx
		mov	si, offset SavePhraseTrigger
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp		; frame pointer
done:
		.leave
		ret
WALDeleteAllAbbrevPhrase	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALBringUpDialogBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To bring up a user dialog box with the string handle
		and offset passed in.

CALLED BY:	
PASS:		ax = offset of the messge
		bx = handle of the message
		cl = set if an affirmative dialog box
			clear if notification dialog box
		ch = set if an error dialog type wanted
		     clear if a question dialog type wanted
RETURN:		ax = user's respond
DESTROYED:	bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALBringUpDialogBox	proc	near
	uses	bx,cx,dx,si,di,bp
	.enter
	; 
	; Bring up a dialog box notifying the user that the password
	; not verified
	;
		sub	sp, size StandardDialogOptrParams
		mov	bp, sp
		tst	cl
		jz	notificationBoxWanted
		tst	ch
		jnz	errorDialogFlags
		mov	ss:[bp].SDOP_customFlags, \
			(CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or\
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
		jmp	customString

notificationBoxWanted:
		tst	ch
		jnz	errorDialogFlags
		mov	ss:[bp].SDOP_customFlags, \
			(CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		jmp	customString

errorDialogFlags:
		mov	ss:[bp].SDOP_customFlags, \
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)

customString:
		mov	ss:[bp].SDOP_customString.handle, bx
		mov	ss:[bp].SDOP_customString.chunk, ax
		mov	ss:[bp].SDOP_stringArg1.handle, NULL
		mov	ss:[bp].SDOP_stringArg2.handle, NULL
		mov	ss:[bp].SDOP_customTriggers.segment, NULL
		mov	ss:[bp].SDOP_helpContext.segment, NULL
		call	UserStandardDialogOptr


	.leave
	ret
WALBringUpDialogBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALGenDynamicListQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the dynamic list of the abbreviated phrase query
		for moniker, we make up our own graphic string for
		each moniker.

CALLED BY:	MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
		^lcx:dx = the dynamic list requesting the moniker
		bp	= the position of the item requeseted
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALGenDynamicListQueryItemMoniker	method dynamic WriteAbbrevListClass, 
					MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
	itemPosition	local	word	push	bp
	selfSptr	local	word	push 	ds
	selfLptr	local	word	push	si
	chunkArrayHptr	local	hptr.LMemBlockHeader
	gstringChunk	local	lptr

SBCS <	abbrevPair local MAX_ABBREV_LENGTH + MAX_PHRASE_LENGTH + 2 dup (char)>
DBCS <	abbrevPair local MAX_ABBREV_LENGTH + MAX_PHRASE_LENGTH + 2 dup (wchar)>

		ForceRef	selfSptr
		ForceRef	gstringChunk

		.enter
		movdw	bxsi, ds:[di].WALI_carray	; ^lbx:si = carray
		tst	bx
		jz	done

		mov	ss:[chunkArrayHptr], bx
		mov	ax, ss:[itemPosition]
		call	ChunkArrayElementToPtr		; ds:di = element
						; cx = elt. size
		mov	si, di				; ds:si = element

	; copy the element (abbrev + phrase) into the local var
		segmov	es, ss
		lea	di, abbrevPair
		LocalCopyString
		LocalCopyString

	; di ?= Gstate?
		call	CreateGStringVisMoniker	; ax = vismoniker lptr
					; ds = sptr of carray block 
		movdw	cxdx, bxax		; ^lcxdx = vismoniker src
		mov	bx, ds			; bx = carray sptr
		mov	si, ss:[selfLptr]	; *ds:si = self
		mov_tr	di, dx			; save VisMoniker Lptr 
EC <		Assert	objectPtr, dssi, WriteAbbrevListClass		>
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
		push	bp
		mov	bp, ss:[itemPosition]
		call	ObjCallInstanceNoLock		
		pop	bp

	; free VisMoniker
		mov_tr	ax, di		; *ds:ax = visMoniker
		call	LMemFree

	; unlock carray block
		mov	bx, ss:[chunkArrayHptr]	
		call	MemUnlock
done:

		.leave
		ret

WALGenDynamicListQueryItemMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateGStringVisMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a complex VisMoniker, using the Graphics System
		GString creation capability.

CALLED BY:	WALGenDyanmicListQueryItemMoniker
PASS:		bx	= handle of memory block in which to allocate gstring
			  chunk
		ss:bp	= inherited stack frame
		cx 	= chunk array element size
RETURN:		ds	= pointing to locked memory block
		ax	= chunk handle of VisMoniker
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- create the gstring (this routine now allocates the chunk)
	- perform drawing operations to the gstate
	- end the gstring and destroy the gstate, leaving the data
	- insert a VisMoniker structure at the front of the chunk
	- stuff the VisMoniker header to make it a valid VisMoniker

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateGStringVisMoniker	proc	near
	selfSptr	local	word
	selfLptr	local	word
	chunkArrayHptr	local	hptr.LMemBlockHeader
	gstringChunk	local	lptr
SBCS <	abbrevPair local MAX_ABBREV_LENGTH + MAX_PHRASE_LENGTH + 2 dup (char)>
DBCS <	abbrevPair local MAX_ABBREV_LENGTH + MAX_PHRASE_LENGTH + 2 dup (wchar)>

		uses	bx, si, di
		.enter	inherit

		mov	ss:[chunkArrayHptr], bx
	;
	; Create a GString
	;
		mov	cl, GST_CHUNK	; place gstring in local memory chunk
		call	GrCreateGString	; di = gstate, si = chunk
		mov	ss:[gstringChunk], si	; save gstring chunk

	;
	; Draw abbreviation
	;
		segmov	ds, ss
		lea	si, abbrevPair
		clr	ax, bx	; ds:si = string to draw
		call	GrDrawText
	;
	; Draw space and column
	;
		mov	ax, PHRASE_POS - SPACE_BET_STRINGS
		mov	dl, ':'
		xchg	dl, ds:[si]
		mov	cx, 1
		call	GrDrawText
		xchg	dl, ds:[si]		; ds:si = abbrevation
	
	;
	; Advance *ds:si to point to the phrases
	;
		push	di			; gstate
		mov	cx, MAX_PHRASE_LENGTH
		segmov	es, ds, ax
		mov	di, si
SBCS <		mov	al, VC_NULL					>
SBCS <		repne	scasb						>
DBCS <		mov	ax, VC_NULL					>
DBCS <		repne	scasw						>
		mov	si, di			; ds:si = phrase
		pop	di			; gstate
	;
	; Draw phrase
	;
		mov	ax, PHRASE_POS
		mov	cx, MAX_PHRASE_LENGTH		; null terminate string
		call	GrDrawText
		call	GrEndGString
	;
	; put width and height of moniker to stack, so we have the
	; info when stuffing the GString header
		mov	si, GFMI_HEIGHT or GFMI_ROUNDED
		call	GrFontMetrics
		mov	cx, 1
		push	cx, dx

	; Then nuke the GState, as we don't need it anymore.
	; (di must still be the GString handle)
		mov	dl, GSKT_LEAVE_DATA	; leave precious data intact
		mov	si, di
		clr	di
		call	GrDestroyGString	; but get rid of the GState

	; Pre-pend GString with header needed for VisualMoniker
		mov	bx, ss:[chunkArrayHptr]	; restore lmem block hptr
EC < 		call	ECCheckMemHandle				>
		call	MemLock			; lock block for lmem insert
		mov	ds, ax

		mov	ax, ss:[gstringChunk]	; ax <- gstring chunk
		clr	bx			; offset at which to insert
		mov	cx, size VisMoniker + size VisMonikerGString
		call	LMemInsertAt

	; Stuff the VisMoniker header structure, to make this a valid
	; GString Moniker
		mov	si, ax
		mov	di, ds:[si]	; deref to get ptr to chunk in ds:di
		mov	ds:[di].VM_type, mask VMT_GSTRING
.warn -field
		pop	ds:[di].VM_width, ds:[di].VM_data.VMGS_height
.warn @field
					; get width & height
		.leave
		ret
CreateGStringVisMoniker	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALAddAbbrevPhrase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message declaration

CALLED BY:	MSG_WAL_ADD_ABBREV_PHRASE
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALAddAbbrevPhrase	method dynamic WriteAbbrevListClass, 
					MSG_WAL_ADD_ABBREV_PHRASE
		uses	ax, cx, dx, bp
		.enter

		mov	ds:[di].WALI_mode, WAMF_ADD
	;
	; if the chunk array is not created due to no file exists,
	; create the chunk array here

		cmp	ds:[di].WALI_carray.handle, NULL
		jne	addDialogBox

		push	si		; preserve obj chunk handle
		clr	bx
		mov	cx, size ChunkArrayHeader
		clr	si
		mov	al, mask OCF_IGNORE_DIRTY
		call	ChunkArrayCreate
		mov	ax, si		; chunk array chunk handle
		pop	di		; obj chunk handle
		mov	di, ds:[di]
		add	di, ds:[di].WriteAbbrevList_offset
		mov	bx, ds:[OLMBH_header].LMBH_handle
		movdw	ds:[di].WALI_carray, bxax

addDialogBox:
	;
	; change the moniker of the dialog box to "add abbreviation"
	;
		GetResourceHandleNS	AbbrevPhraseModificationDialog, bx
		mov	si, offset AbbrevPhraseModificationDialog
		mov	cx, offset AddAbbrevMoniker	; chunk of vismoniker
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; delete all the current text in the abbreviation & phrase field
	;
		GetResourceHandleNS	AbbreviationName, bx
		mov	si, offset AbbreviationName
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		GetResourceHandleNS	AbbreviationPhrase, bx
		mov	si, offset AbbreviationPhrase
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; initiate the dialog box 
	;
		GetResourceHandleNS	AbbrevPhraseModificationDialog, bx
		mov	si, offset AbbrevPhraseModificationDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		
	; enable save trigger since the dynamic list has been modified
		GetResourceHandleNS	SavePhraseTrigger, bx
		mov	si, offset SavePhraseTrigger
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
WALAddAbbrevPhrase	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALGenApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When any pair of abbreviated phrase is selected
		MSG_GEN_APPLY is sent out, thus we need to enable the
		triggers "Edit" and "Delete" for the user.

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALGenApply	method dynamic WriteAbbrevListClass, 
					MSG_GEN_APPLY
		uses	ax, cx, dx, bp
		.enter
		mov	di, offset WriteAbbrevListClass
		call	ObjCallSuperNoLock

		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock		; ax = selection

enableEditDelete::
		push	bp		; preserve frame pointer
		GetResourceHandleNS	EditAbbrevTrigger, bx
		mov	si, offset EditAbbrevTrigger
		mov	di, mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage

		GetResourceHandleNS	DeleteAbbrevTrigger, bx
		mov	si, offset DeleteAbbrevTrigger
		call	ObjMessage
		pop	bp		; frame pointer

		.leave
		ret
WALGenApply	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALAbbrevModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message declaration.

CALLED BY:	MSG_WAL_ABBREV_MODIFIED
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALAbbrevModified	method dynamic WriteAbbrevListClass, 
					MSG_WAL_ABBREV_MODIFIED
SBCS <	abbrevPair local MAX_ABBREV_LENGTH + MAX_PHRASE_LENGTH + 2 dup (char)>
DBCS <	abbrevPair local MAX_ABBREV_LENGTH + MAX_PHRASE_LENGTH + 2 dup (wchar)>
selfChunk	   local	word
pairLength	   local	word
addOrEdit	   local	byte		; clear = edit
						; set = add
		uses	ax, cx, dx, bp
		.enter
		cmp	ds:[di].WALI_mode, WAMF_ADD
		jne	checkEmptyAbbrev
	;
	; check if the total number of pair has exceeded the maximum
	; number of pair allow
		push	bp		; frame pointer
		mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
		call	ObjCallInstanceNoLock	; cx = # of item
		pop	bp		; frame pointer

		cmp	cx, MAX_ABBREV_PHRASE_PAIR
		LONG	jge	exceedPairLimit

checkEmptyAbbrev:
	; check the abbreviation and the phrase are complete
		clc	
		call	CheckEmptyAbbrevPhrase
		LONG	jc	done

		mov	al, ds:[di].WALI_mode
		mov	ss:[addOrEdit], al
		
	;
	; grab the abbreviation and phrase
		mov	ss:[selfChunk], si
		push	bp		
		mov	dx, ss
		lea	bp, abbrevPair
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		GetResourceHandleNS	AbbreviationName, bx		
		mov	si, offset AbbreviationName
		call	ObjMessage		; cx = length w/o null
		mov	es, dx
		mov	dx, bp			; es:dx = abbreviation
DBCS <		shl	cx, 1			; #chars -> #bytes 	>
		pop	bp		
		inc	cx
DBCS <		inc	cx						>
		mov	ss:[pairLength], cx

		GetResourceHandleNS	AbbreviationPhrase, bx
		push	bp		
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	si, cx
		mov	dx, ss
		lea	bp, abbrevPair[si]
		mov	si, offset AbbreviationPhrase
		call	ObjMessage		; cx = length w/o null
DBCS <		shl	cx, 1			; #chars -> #bytes	>
		pop	bp		
		inc	cx
DBCS <		inc	cx						>
		add	ss:[pairLength], cx
	;
	; chech if the chunk array already exists, if not, create one
	;
		mov	si, ss:[selfChunk]
		mov	si, ds:[si]
		add	si, ds:[si].WriteAbbrevList_offset
		movdw	bxsi, ds:[si].WALI_carray	; ^lbx:si = chunkarray
		tst	bx
		jne	checkAddOrEdit
	;
	; create a chunk array if it is not created already
	;
		clr	bx
		mov	cx, size ChunkArrayHeader
		clr	si
		mov	al, mask OCF_IGNORE_DIRTY
		call	ChunkArrayCreate
		mov	bx, ds:[OLMBH_header].LMBH_handle
	;
	; assign the chunk array into the instance data of the object
	;	
		mov	si, ss:[selfChunk]
		mov	di, ds:[si]
		add	di, ds:[di].WriteAbbrevList_offset
		mov	ds:[di].WALI_carray.handle, bx
		mov	ds:[di].WALI_carray.chunk, si

checkAddOrEdit:

	; check whether the user was adding a new phrase or
	; editing		*ds:si = chunkarray at this point
	
		cmp	ss:[addOrEdit], WAMF_ADD
		je	addNewItem
	;
	; get the position of the element we are replacing
	;
		push	si		; chunk array handle
		push	bp		; frame pointer
		mov	si, ss:[selfChunk]
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock		; ax = selection
		pop	bp		; frame pointer
	;
	; get the chunk array element into es:di for checking
	; duplicate
		pop	si
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayElementToPtr		; cx = element size
							; ds:di = elmt	
	; compare if the edited abbreviation is the same as the
	; original one, if matches, we don't need to check for
	; duplicate abbreviation.  If not, we have to check for
	; duplicate abbreviation.

DBCS <		shr	cx				; cx = #char	>
		segmov	es, ds				; es:di = dest
		push	ds, si			; preserve the chunk
						; array handle
checkDuplicate::
		segmov	ds, ss
		lea	si, ss:[abbrevPair]		; ds:si = source
		call	LocalCmpStrings
		movdw	esdx, dssi		; current text to compare
		pop	ds, si

		jz	queryVisMoniker

EC <		call	ECCheckChunkArray				>
		call	ChunkArrayCheckDuplicateAbbrev
		LONG	jc	done

queryVisMoniker:
	; assign the newly edit phrase to the chunkarray
	; resize the chunk array element, then change the content
	;
		mov	cx, ss:[pairLength]
		call	ChunkArrayElementResize

		call	ChunkArrayElementToPtr		; cx = element size
							; ds:di = elmt
		segmov	es, ds				; es:di = elmt(dest)
		segmov	ds, ss
		lea	si, ss:[abbrevPair]		; ds:si = source
		LocalCopyNString		; copy abbrev+phrase

	; invalidate the old pair of abbreviation and draw the new
	; pairs
		push	bp			; frame pointer
		GetResourceHandleNS	AbbrevPhraseObj, cx
		mov	dx, offset AbbrevPhraseObj
		segmov	ds, es
		mov	si, ss:[selfChunk]	; *ds:si ??
		mov	bp, ax			; ^lcx:dx = visMoniker
		mov	ax, MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
		call	ObjCallInstanceNoLock
		pop	bp			; frame pointer

		jmp	done
addNewItem:
	; check whether the abbreviation has existed in memory
		segmov	es, ss
		lea	dx, ss:[abbrevPair]
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayCheckDuplicateAbbrev
		LONG	jc	done


		mov	ax, ss:[pairLength]		; size of the element
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayAppend		; ds:di = new elmt
		
		segmov	es, ds				; es:di = dest
		push	ds
		segmov	ds, ss
		lea	si, ss:[abbrevPair]		; ds:si = source
		mov	cx, ax
		LocalCopyNString

		pop	ds		; since the block won't move

		push	bp		; frame pointer
		mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
		mov	cx, GDLP_LAST		; add at end
		mov	dx, 1
		mov	si, ss:[selfChunk]
		call	ObjCallInstanceNoLock

	;
	; make the item visible to the user
	;
		mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
EC <		Assert	objectPtr, dssi, WriteAbbrevListClass		>
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
		call	ObjCallInstanceNoLock	; cx = # of item
		pop	bp			; frame pointer
		cmp	cx, MAX_ABBREV_PHRASE_PAIR
		jl	done

	; disable the  Add Item trigger if the number of abbreviation
	; pairs has reach the maximum number

		push	bp		; frame pointer
		GetResourceHandleNS	AddAbbrevTrigger, bx
		mov	si, offset AddAbbrevTrigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp		; frame pointer
done:
		.leave
		ret

exceedPairLimit:
	;
	; bring up an error notification dialog box to indicate there
	; can be no more pair of abbreviation & phrase added
	;
		GetResourceHandleNS	PairLimitExceedStr, bx
		mov	ax, offset PairLimitExceedStr
		mov	ch, 1
		clr	cl
		call	WALBringUpDialogBox
		jmp	done

WALAbbrevModified	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEmptyAbbrevPhrase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To check whether the user has typed both the
		abbreviation and the phrase in the dialog box.

CALLED BY:	WALAbbrevModified
PASS:		nothing
RETURN:		carry set if either field are empty
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	9/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEmptyAbbrevPhrase	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; since the maximum length of the phrase is not more than ax
	; can contain, I just test ax instead of dx:ax

		GetResourceHandleNS	AbbreviationName, bx
		mov	si, offset AbbreviationName
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage		; dx:ax = length w/o null
		cmp	ax, 0
		jz	emptyAbbrevPhrase

		GetResourceHandleNS	AbbreviationPhrase, bx
		mov	si, offset AbbreviationPhrase
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage		; dx:ax = length w/o null
		cmp	ax, 0
		jz	emptyAbbrevPhrase

done:
		.leave
		ret

emptyAbbrevPhrase:

	; bring up an error notification dialog box
		GetResourceHandleNS	IncompleteEntryStr, bx
		mov	ax, offset IncompleteEntryStr
		mov	ch, 1
		clr	cl
		call	WALBringUpDialogBox
		stc
		jmp	done

CheckEmptyAbbrevPhrase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WPWriteProcessExpandCurrentAbbrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See meesage declaration

CALLED BY:	MSG_WRITE_PROCESS_EXPAND_CURRENT_ABBREV
PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		dx:bp	= current text to be expand
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	9/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WPWriteProcessExpandCurrentAbbrev	method dynamic WriteProcessClass, 
					MSG_WRITE_PROCESS_EXPAND_CURRENT_ABBREV
SBCS <	abbrevOrPhrase local MAX_PHRASE_LENGTH + 1 dup (char)		>
DBCS <	abbrevOrPhrase local MAX_PHRASE_LENGTH + 1 dup (wchar)		>

textHandle	Local	word	
textChunk	Local	word
selfChunk	Local	word

	uses	ax, cx, dx, bp
	.enter
		mov	ss:[selfChunk], si
		push	bp			; preserve frame pointer
	;
	; how to get the word under the cursor to es:dx??????
	;
		call	AbbrevGetTargetTextOD	; ^lbx:si = text obj
		mov	ss:[textHandle], bx
		mov	ss:[textChunk], si
		LONG	jnc	notTextTargetDialog

		push	bx, si

	;
	; get the selection, but make sure it's not too big
	;
		push	bp			; frame pointer
		sub	sp, size VisTextRange
		mov	bp, sp
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS 
		call	ObjMessage		; cx = length w/o null
		
		movdw	dxax, ss:[bp].VTR_end
		subdw	dxax, ss:[bp].VTR_start
		add	sp, size VisTextRange
		
		pop	bp			; frame pointer
		
		cmpdw	dxax, 0
		je	getEntireTextFromCursor

	; since there is some text selected just try to expand that selection
		mov	dx, ss
		lea	bp, abbrevOrPhrase		; dx:bp = dest
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		jmp	replaceString

getEntireTextFromCursor:
	; !!! have to get the correct bx si to send the message!!!
	;
		mov	cx, ss:[textHandle]
		mov	dx, ss:[textChunk]
		sub	sp, size GetContextParams
		mov	bp, sp

		call	GeodeGetProcessHandle
		clr	si
		movdw	ss:[bp].GCP_replyObj, bxsi
		mov	ss:[bp].GCP_numCharsToGet, MAX_ABBREV_LENGTH
		mov	ss:[bp].GCP_location, CL_SELECTED_WORD
		mov	ax, MSG_META_GET_CONTEXT
		mov	di, mask MF_STACK or mask MF_CALL
		mov	bx, cx
		mov	si, dx
		mov	dx, size GetContextParams
		call	ObjMessage

		add	sp, size GetContextParams
		pop	bx, si

		jmp	done
	; 
	; if the current text is selected, find the phrase correspond
	; to that abbreviation and replace the selection.
	; 
replaceString:

		mov	ax, MSG_WAL_GET_PHRASE_FROM_ABBREV
		GetResourceHandleNS	AbbrevPhraseObj, bx
		mov	si, offset AbbrevPhraseObj
		mov	di, mask MF_CALL
		call	ObjMessage		; dx:bp = string to replace
dummy::
		pop	bx, si
		jnc	abbrevNotFoundDialog
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage

done:
		pop	bp		; frame pointer
		.leave
		ret

notTextTargetDialog:
	; bring up a dialog box to tell the user that there is no select
	; text to expand upon.

		GetResourceHandleNS	NoTextTargetToExpandStr, bx
		mov	ax, offset NoTextTargetToExpandStr
		mov	ch, 1
		clr	cl
		call	WALBringUpDialogBox
		stc
		jmp	done

abbrevNotFoundDialog:
	; bring up a dialog box to tell the user that the abbreviation
	; is not found
		GetResourceHandleNS	AbbrevNotFoundStr, bx
		mov	ax, offset AbbrevNotFoundStr
		mov	ch, 1
		clr	cl
		call	WALBringUpDialogBox
		stc
		jmp	done


WPWriteProcessExpandCurrentAbbrev	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WALGetPhraseFromAbbrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message declaration

CALLED BY:	MSG_WAL_GET_PHRASE_FROM_ABBREV
PASS:		*ds:si	= WriteAbbrevListClass object
		ds:di	= WriteAbbrevListClass instance data
		ds:bx	= WriteAbbrevListClass object (same as *ds:si)
		es 	= segment of WriteAbbrevListClass
		ax	= message #
		dx:bp	= current text content
RETURN:		carry set if there is a phrase to replace the abbrev.
			dx:bp 	= phrase to replace the abbrev
		carry clear otherwise.		
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	9/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WALGetPhraseFromAbbrev	method dynamic WriteAbbrevListClass, 
					MSG_WAL_GET_PHRASE_FROM_ABBREV
		uses	ax, cx, dx, bp
		.enter

		mov	di, ds:[di].WALI_carray.chunk
		tst	di
		je	noChunkArrayToEnum
enumArray:
		mov	si, di		; *ds:si <- chunkarray
		mov	bx, cs
		mov	di, offset ExpandAbbrevCallBack	; bx:di = call back
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayEnum
done:
		.leave
		ret

noChunkArrayToEnum:
		mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
		call	UserCallApplication

		push	ds:[LMBH_handle]
		mov	bp, 1		; don't want warning for file format
		call	WPReadAbbrevPhrase
		pop	bx
		call	MemDerefDS

		mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
		call	UserCallApplication

		mov	di, ds:[si]
		add	di, ds:[di].WriteAbbrevList_offset
		mov	di, ds:[di].WALI_carray.chunk
		tst	di
		jnz	enumArray
		jmp	done		; done with carry clear

WALGetPhraseFromAbbrev	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AbbrevGetTargetTextOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To get the current text object having the target.

CALLED BY:	WPWriteProcessExpandCurrentAbbrev
PASS:		nothing
RETURN:		carry SET if found 
			^lbx:si - OD of system target text object
		carry clear otherwise
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AbbrevGetTargetTextOD	proc	near
	uses	ax, cx,dx, di,bp
	.enter
		
	; Since the abbreviation only run under GeoWrite right now,
	; we know which application we are currently runnin

		GetResourceHandleNS	WriteApp, bx
		mov	si, offset WriteApp
	;
	; Now, ask that app which object has the target.
	;
		mov	ax, MSG_META_GET_TARGET_AT_TARGET_LEVEL
		mov	cx, TL_TARGET
		mov	di, mask MF_CALL
		call	ObjMessage 
		clc
		jcxz	done
		movdw	bxsi, cxdx
		
	;
	; Make sure we're looking at a text object.  
	;
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	cx, segment VisLargeTextClass
		mov	dx, offset VisLargeTextClass
		mov	di, mask MF_CALL
		call	ObjMessage
done:
	.leave
	ret
AbbrevGetTargetTextOD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandAbbrevCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call back routine to expand an abbreviation into the
		phrase in the database.

CALLED BY:	WALGetPhraseFromAbbrev
PASS:		*ds:si 	= chunk array
		ds:di 	= element
		dx:bp 	= abbreviation to expand on
RETURN:		carray set if the abbreviation can be replace
			dx:bp = phrase to expand the abbrev
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	9/ 1/94    	Initial version


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandAbbrevCallBack	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		mov	si, di			; ds:si = elmt = string
		mov	es, dx
		mov	di, bp			; es:di = abbreviation to check
		call	LocalCmpStrings
		clc
		jnz	done

	; grab the phrase correspond to the current abbreviation
		segxchg	es, ds			; es:di = element(abbrev)
		xchg	si, di			
		mov	cx, -1
SBCS <		mov	al, VC_NULL					>
SBCS <		repne	scasb						>
DBCS <		mov	ax, VC_NULL					>
DBCS <		repne	scasw						>
						; es:di = element(phrase)
		xchg	si, di			; es:si = phrase (source)

	;
	; pass out the current string
	; ds:si = source, es:di = dest
		segxchg es, ds			; ds:si = phrase (source)
		LocalCopyString
		stc
done:
	.leave
	ret
ExpandAbbrevCallBack	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChunkArrayCheckDuplicateAbbrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if the phrase enters already exists in the
		abbreviation database.

CALLED BY:	*ds:si = chunk array to enum
PASS:		es:dx = new abbreviation to compare
		cx = length of the abbreviation to compare
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	9/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChunkArrayCheckDuplicateAbbrev	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

		mov	cx, MAX_ABBREV_LENGTH
		mov	bx, cs
		mov	di, offset CheckDuplicateAbbrevCallBack	
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayEnum

		jc	duplicateAbbrev
done:
	.leave
	ret

duplicateAbbrev:
	; bring up an error notification dialog box
		GetResourceHandleNS	DuplicateAbbrevStr, bx
		mov	ax, offset DuplicateAbbrevStr
		mov	ch, 1
		clr	cl
		call	WALBringUpDialogBox
		stc
		jmp	done

ChunkArrayCheckDuplicateAbbrev	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDuplicateAbbrevCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To check each chunk array element against with the
		abbreviation passed in to see if the same abbreviation
		has existed in the data base.

CALLED BY:	ChunkArrayCheckDuplicateAbbrev
PASS:		ds:si = chunk array
		ds:di = element
		es:dx = string of the new abbreviation to compare
		cx = length of string to compare
RETURN:		zero flag set if same abbreviation found
		
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	9/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDuplicateAbbrevCallBack	proc	far
	uses	dx,si,di,bp
	.enter

	mov	si, di			; ds:si = elmt = string
	mov	di, dx			; es:di = abbreviation to check
	call	LocalCmpStrings
	clc
	jnz	done
	stc
done:
	.leave
	ret
CheckDuplicateAbbrevCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WPMetaContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message would return with the current word of the
		current text object.  The current word should be the
		abbreviation the user wants to expand on.

CALLED BY:	MSG_META_CONTEXT
PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	9/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WPMetaContext	method dynamic WriteProcessClass, 
					MSG_META_CONTEXT
textBlock	local	word	push	bp
SBCS <	currentText	local MAX_PHRASE_LENGTH + 1 dup (char)		>
DBCS <	currentText 	Local MAX_PHRASE_LENGTH + 1 dup (wchar)		>

	uses	ax, cx, dx, bp
	.enter
		push	bp		; frame pointer
	; lock the text block
		mov	bx, ss:[textBlock]
		call	MemLock
		mov	es, ax
		mov	di, offset CD_contextData

	; check for no characters at all
		tstdw	es:CD_numChars
		jz	noTextToReplace		; es:di = text

	; copy the text into the local var
		segmov	ds, es		
		mov	si, di		; ds:si = source
		segmov	es, ss
		lea	di, ss:[currentText]	; es:di = dest (local var)

		LocalCopyString	SAVE_REGS

	; find the matching phrase for this abbreviation
		movdw	dxbp, esdi
		mov	ax, MSG_WAL_GET_PHRASE_FROM_ABBREV
		GetResourceHandleNS	AbbrevPhraseObj, bx
		mov	si, offset AbbrevPhraseObj
		mov	di, mask MF_CALL
		call	ObjMessage	; dx:bp = string to replace
		jnc	noTextToReplace

		call	AbbrevGetTargetTextOD	;^lbx:si = text obj
	
	; replace the matching phrase 
		push	dx, bp		; dx:bp = phrase to replace
		mov	cx, VTKF_SELECT_WORD
		mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
		mov	di, mask MF_CALL
		call	ObjMessage

		pop	dx, bp		; dx:bp = phrase to replace
		mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION_PTR
		clr	cx
		mov	di, mask MF_CALL
		call	ObjMessage
done:		
		pop	bp	; frame pointer
		.leave
		ret

noTextToReplace:
		GetResourceHandleNS	AbbrevNotFoundStr, bx
		mov	ax, offset AbbrevNotFoundStr
		mov	ch, 1
		clr	cl
		call	WALBringUpDialogBox
		stc
		jmp	done

WPMetaContext	endm

DocAbbrevFeatures ends

endif
