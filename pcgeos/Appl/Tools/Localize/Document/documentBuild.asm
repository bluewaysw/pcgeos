COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit	
FILE:		documentBuild.asm

AUTHOR:		Cassie Hartzog, Dec  1, 1992

ROUTINES:
	Name			Description
	----			-----------
	REDCreatePatchFile	Create a new executable, and then generate a 
				patch file by comparing it to the original 
				file. 
	REDCreateExecutable	Creates a new geode from the document's 
				translation file and the original source geode. 
	REDCreateNullExecutable	Build a null geode and a language patch file 
				with respect to it. 
	REDValidate		Check the document to make sure string 
				arguments match and no strings are outside size 
				limits. 
	CheckChunks		Enumerate the elements in this ResourceArray, 
				checking for min/max or string argument 
				violations. 
	CheckChunksCallback	Check that each text chunk which has 1 or 2 
				string args in the original has the same number 
				in the translation. Check also that the min/max 
				length constraints are not violated. 
	CheckItemForLength	Check that the translation item does not 
				violate the min/max length contsraints. 
	CheckItemForStringArgs	Make sure translation item has proper number of 
				string args. 
	WriteResource		The resource has been updated, now write it to 
				file. 
	WriteRelocationTable	The updated resource has been written to the 
				file, now write the relocation table out. Free 
				it when done. 
	UpdateResourceTable	The resource has been updated, now set its new 
				size and position in the resource table. Also 
				read its relocation table into memory. 
	UpdateResource		Update any chunks that have changed, compact 
				the heap, fix the LMemBlockHeader. 
	UpdateChunk		Change the data in the chunk for this element 
				to the data stored in the TransItem. 
	NullStringsInChunk	If this chunk holds textual data, replace it 
				with a null string. 
	LocInitEndOfChunk	Initialize the end of a used chunk to 0xcc. 
	UpdateObjectChunk	This object has a keyboard shortcut which may 
				need updating. 
	UpdateChunkFixMonikerWidth	Data has been copied out to chunk. 
				Fix-up moniker's cached width, if necessary. 
	UpdateChunkCopyData	Copy the translated item to the resized chunk. 
	VerifyChunkEquality	Make sure that chunk in geode is same as 
				original chunk stored in the translation file, 
				to ensure that the translation file is not out 
				of sync with the geode. 
	CopyResourceTable	Make a copy of the resource table that will not 
				be modified in the process of building the new 
				executable. 
	CopyHeaders		Copy the headers from the source to destination 
				geode. 
	OpenBuildFiles		Open the source geode and a new file in the 
				destination path for the new geode. 
	ChangeNameAndUserNotes	Change the longname and user notes in the newly 
				created file. 
	DeleteNewGeode		The build failed. Delete the new geode file, if 
				one was created. 
	CloseBuildFiles		The CreateExecutable function is done, so close 
				the files now. 

REVISION HISTORY:
	Name	 Date		Description
	----	 ----		-----------
        cassie	 12/ 1/92	Initial revision
	canavese 10/9/95	Major revision: support for batching,
				creating patch files, null geodes, etc.


DESCRIPTION:
	Code for building new geodes from information stored in the
	translation DataBase file.

	$Id: documentBuild.asm,v 1.1 97/04/04 17:14:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include	assert.def


DocumentBuildCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDCreatePatchFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new executable, and then generate a patch
		file by comparing it to the original file.

CALLED BY:	MSG_RESEDIT_DOCUMENT_CREATE_PATCH_FILE
PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PJC	4/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDCreatePatchFile	method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_CREATE_PATCH_FILE
		uses	ax, cx, dx, bp
		.enter

		call	FilePushDir

	; Call CreateExecutable with all the correct flags.

		mov	ax, MSG_RESEDIT_DOCUMENT_CREATE_EXECUTABLE
		mov	cl, CET_TRANSLATED_GEODE
		mov	ch, CEU_UPDATE_IF_NECESSARY
		mov	dl, CEN_ORIGINAL_NAME
		mov	dh, CED_SP_WASTE_BASKET
		call	ObjCallInstanceNoLock
		LONG jc	errorInTempGeodeCreate

	; Indicate success in creating temporary geode.

		call	IsBatchMode
		jnc	afterBatchReport
		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		GetResourceHandleNS	FileMenuUI, dx
		mov	bp, offset ResEditBatchTempGeodeCreated
		call	BatchReportTab
		call	BatchReport
		call	BatchReportReturn

afterBatchReport:

	; Put up hourglass.

		call	MarkBusyAndHoldUpInput

	; Open the original geode.

		call	GetFileHandle		; Get document file handle.
		call	DBLockMap		
		mov	di, es:[di]		; es:di = TransMapHeader
		call	OpenSourceFile
		push	bx			; Original geode.

	; Set top-level directory of translated geode.

		mov	ax, SP_WASTE_BASKET
		call	FileSetStandardPath
		jc	error
	
	; Open translated geode.

		push	ds
		mov	al, FILE_DENY_W or FILE_ACCESS_R
		segmov	ds, es, dx
		lea	dx, es:[di].TMH_dosName
		call	FileOpen
		pop	ds
		mov	bx, ax

	; Go to directory where we want the patch file to be created.

		mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_DESTINATION_PATH
		call	ObjCallInstanceNoLock

	; Create the patch file.

		pop	ax
		call	GeneratePatchFile

	; Delete translated geode.

		push	ax
		clr	al
		call	FileClose
		call	FileDelete
		pop	bx

	; Close files.

		call	DBUnlock
		clr	al
		call	FileClose

	; Take down hourglass.

		call	MarkNotBusyAndResumeInput

error:
		call	FilePopDir
		.leave
		ret

errorInTempGeodeCreate:

	; Indicate failure in creating temporary geode.

		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		GetResourceHandleNS	FileMenuUI, dx
		mov	bp, offset ResEditBatchTempGeodeError
		call	BatchReportTab
		call	BatchReport
		call	BatchReportReturn
		stc
		jmp	error

REDCreatePatchFile	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDCreateExecutable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new geode from the document's translation file and
		the original source geode.

CALLED BY:	UI - MSG_RESEDIT_DOCUMENT_CREATE_EXECUTABLE

PASS:		*ds:si 	- instance data
		ds:di 	- *ds:si
		es 	- seg addr of ResEditDocumentClass
		ax 	- the message
		cl	- CreateExecutableTypeEnum
		cl	- CreateExecutableUpdateEnum
		dl	- CreateExecutableNameEnum
		dh	- CreateExecutableDestinationEnum

RETURN:		carry set on error

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDCreateExecutable	method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_CREATE_EXECUTABLE
cef	local	CreateExecutableFrame
		.enter

EC <		call	AssertIsResEditDocument				>
EC <		Assert 	etype	cl, CreateExecutableTypeEnum		>
EC <		Assert 	etype	ch, CreateExecutableUpdateEnum		>
EC <		Assert 	etype	dl, CreateExecutableNameEnum		>
EC <		Assert 	etype	dh, CreateExecutableDestinationEnum	>

	; Put up hourglass.

		call	MarkBusyAndHoldUpInput

	; Get the resource count.

		mov	bx, ds:[di].REDI_totalResources

	; Initialize the CEF with 0's

		push	cx			; CreateExecutable enum.
		segmov	es, ss, ax
		lea	di, ss:[cef]
		mov	cx, size CreateExecutableFrame/2  ; Word aligned
		clr	ax
		rep	stosw
		pop	cx			; CreateExecutable enum.

	; Initialize other CEF values.

EC<		mov	ss:[cef].CEF_TFF.TFF_signature, TRANSLATION_FILE_FRAME_SIG >
		mov	ss:[cef].CEF_TFF.TFF_numResources, bx
		mov	ss:[cef].CEF_TFF.TFF_geodeType, cl
		mov	ss:[cef].CEF_TFF.TFF_updateType, ch
		mov	ss:[cef].CEF_TFF.TFF_nameType, dl
		mov	ss:[cef].CEF_TFF.TFF_destType, dh
		mov	bx, ds:[LMBH_handle]
		movdw	ss:[cef].CEF_document, bxsi

	; Allocate a fixed block to hold resource handles.

		DerefDoc				; ds:di = document
		call	AllocResourceHandleTable	; es <- DHS
		mov	ss:[cef].CEF_TFF.TFF_handles, es

	; Save translation file.

		push	bp
		mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_SAVE
		call	ObjCallInstanceNoLock
		pop	bp

	; Validate translation file.

		mov	ax, MSG_RESEDIT_DOCUMENT_VALIDATE
		call	ObjCallInstanceNoLock
		LONG	jc	error

	; Store the translation file handle in the CEF.

		call	GetFileHandle		; ^hbx <- translation file
		mov	ss:[cef].CEF_TFF.TFF_transFile, bx

	; Open the source geode and create the destination geode file.
	; Store their handles in the document instance data.

		call	OpenBuildFiles
		LONG	jc	error

	; Copy the file headers from the source to the destination.
	; Load the import, export and resource tables into DHS. Write the 
	; import and export tables out to new geode, which do not change.
	; Initialize CEF_curPos, get position and size of resource table

		call	CopyHeaders	
		LONG	jc	error

	; Make a copy of the ResourceTable which will be used to look up
	; stuff in the old geode (eg. in LoadResource).  Allocate a block
	; to hold the RelocationTable for the resources.
	
		call	CopyResourceTable
		LONG	jc	error

	; Indicate current and total resources in status dialog.

		mov	dx, ss:[cef].CEF_TFF.TFF_numResources	
		call	IsBatchMode
		jnc	initLoop
		push	si
		clr	dx
		mov	si, offset ResEditBatchCurrentResourceNumber
		call	BatchReportSetValue
		mov	dx, ss:[cef].CEF_TFF.TFF_numResources	
		mov	si, offset ResEditBatchTotalResourceNumber
		call	BatchReportSetValue
		pop	si

initLoop:

	; Initialize variables for the big loop.
	
		mov	cx, dx			; cx <- # res left to update
		clr	ax			; start with resource # 0

getResource:

	; Indicate the resource number we're on in the status dialog.

		mov	bx, ss:[cef].CEF_document.handle
		call	MemDerefDS
		call	IsBatchMode
		jnc	incResourceNum
		push	si
		mov	dx, ax				; Resource number.
		inc	dx
		mov	si, offset ResEditBatchCurrentResourceNumber
		call	BatchReportSetValue
		pop	si

incResourceNum:

	; Increment the resource number.

		mov	ss:[cef].CEF_count, cx	; Save number remaining.
		mov	dx, ss:[cef].CEF_TFF.TFF_numResources
		mov	ss:[cef].CEF_resNumber, ax

	; Load this resource into a memory block.  Note that this
	; routine "relocates" LMem blocks by substituting resource
	; ID in LMBH_handle with the block handle.  The resource ID
	; MUST BE RESTORED before the resource is written out.
	
		push	bp
		lea	bp, ss:[cef].CEF_TFF
		call	LoadResourceNoSaveDS	;^hbx <- resource block
		jnc	updateResource		
		pop	bp

		cmp	ax, LRE_ZERO_SIZE	;if 0 size, nothing to write
		je	nextResource
		mov	ax, EV_LOAD_RESOURCE	;else it's an error
		LONG	jmp	error 	

updateResource:

	; Make the changes as dictated by the translation file.
	;  ^hbx is always the (locked) resource block.

		call	MyMemLock		; ^hbx <- locked resource block
		pop	bp			; restore stack frame pointer
		call	UpdateResource		; cx <- real size of resource
		LONG	jc	errorFreeBX	; ax <- ErrorValue

	; Write the resource out to new file.
	
		call	WriteResource		; dx <- # bytes written
		LONG	jc	errorFreeBX	; ax <- ErrorValue

	; Update resource table information (size, position) and load
	; the relocation table for this resource
	; Pass: 	cx - actual resource size
	;		dx - number of bytes written
	
		call	UpdateResourceTable	; cx <-size of relocation table
		LONG 	jc	errorFreeBX	; ax <- ErrorValue

		call	WriteRelocationTable	; Write the relocation table
		LONG	jc	errorFreeBX

		push	bp
		lea	bp, ss:[cef].CEF_TFF
		call	MyMemFree			; Free the resource block
		pop	bp

nextResource:
		mov	ax, ss:[cef].CEF_resNumber
		inc	ax
		mov	cx, ss:[cef].CEF_count
		loop	getResource

	; Position the destination geode at the Resource Table.
	
		movdw	cxdx, ss:[cef].CEF_resTablePos
		mov	bx, ss:[cef].CEF_newGeode
		mov	al, FILE_POS_START
		call	FilePos

	; Lock the updated Resource Table.

		mov	bx, ss:[cef].CEF_resourceTable
		call	MemLock

	; Write the new Resource Table to the destination geode. 

		push	ds
		mov	ds, ax
		clr	dx
		mov	cx, ss:[cef].CEF_resTableSize
		mov	bx, ss:[cef].CEF_newGeode
		clr	al
		call	FileWrite
		pop	ds
		mov	ax, EV_NO_ERROR
		jnc	closeFiles
		mov	ax, EV_FILE_WRITE_RESOURCE

error:	

	; Delete the new geode.

		movdw	bxsi, ss:[cef].CEF_document
		call	MemDerefDS
		call	DeleteNewGeode

	; If error has already been reported, don't report it a second time.

		cmp	ax, EV_NO_ERROR
		stc
		je	closeFiles		; CF is clear.

	; If the resources or chunks don't match, try updating the
	; translation file.

		cmp	ax, EV_NUM_RESOURCES
		je	updateTranslationFile
		cmp	ax, EV_CHUNK_MISMATCH
		je	updateTranslationFile

	; Put up a dialog to report error.

		mov	cx, ax
		mov	ax, MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE
		call	ObjCallInstanceNoLock
		stc

closeFiles:
		pushf				; Preserve carry flag.
		movdw	bxsi, ss:[cef].CEF_document
		call	MemDerefDS
		call	CloseBuildFiles
		popf
		jnc	done
		cmp	ax, EV_NO_ERROR
		stc
		je	done
		mov	cx, ax
		mov	ax, MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE
		call	ObjCallInstanceNoLock
		stc

done:

	; Indicate success/failure in status dialog.

		pushf
		jnc	doneNoReport
		call	IsBatchMode
		jnc	doneNoReport
		push	bp
		mov	bp, offset ResEditBatchGeodeCreateError

		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		GetResourceHandleNS	FileMenuUI, dx
		call	BatchReportTab
		call	BatchReport
		call	BatchReportReturn
		pop	bp

doneNoReport:

	; Take down hourglass.

		call	MarkNotBusyAndResumeInput
		popf

		.leave
		ret

errorFreeBX:
		push	bp
		lea	bp, ss:[cef].CEF_TFF
		call	MyMemFree
		pop	bp
		jmp	error

updateTranslationFile:

	; Are we supposed to update?

		mov	ax, EV_UPDATE_UNSUCCESSFUL
		cmp	ss:[cef].CEF_TFF.TFF_updateType, \
				CEU_DO_NOT_ATTEMPT_UPDATE
		LONG je	error

	; Close the files we were using.

		call	CloseBuildFiles

	; Report any errors from the close.

		cmp	ax, EV_NO_ERROR
		jnc	doUpdate
		mov	ax, MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE
		call	ObjCallInstanceNoLock
		
doUpdate:

	; Do the update.

		push	bp
		mov	ax, MSG_RESEDIT_DOCUMENT_UPDATE_TRANSLATION
		mov	di, mask MF_FORCE_QUEUE
		movdw	bxsi, ss:[cef].CEF_document
		call	ObjMessage
		pop	bp

	; Try to create the executable again.

		mov	ax, MSG_RESEDIT_DOCUMENT_CREATE_EXECUTABLE
		mov	cl, ss:[cef].CEF_TFF.TFF_geodeType
		mov	ch, CEU_DO_NOT_ATTEMPT_UPDATE
		mov	dl, ss:[cef].CEF_TFF.TFF_nameType
		mov	dh, ss:[cef].CEF_TFF.TFF_destType
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		clc
		pushf
		jmp	doneNoReport

REDCreateExecutable	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDCreateNullPatchFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a null geode and a language patch file with respect to
		it.

CALLED BY:	MSG_RES_EDIT_DOCUMENT_CREATE_NULL_PATCH_FILE
PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
RETURN:		carry set on error
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	6/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDCreateNullPatchFile	method dynamic ResEditDocumentClass, 
				MSG_RESEDIT_DOCUMENT_CREATE_NULL_PATCH_FILE
		uses	ax,cx,dx,bp
		.enter

	; Save original path.

		call	FilePushDir

	; Create a null-geode.

		mov	ax, MSG_RESEDIT_DOCUMENT_CREATE_EXECUTABLE
		mov	cl, CET_NULL_GEODE
		mov	ch, CEU_UPDATE_IF_NECESSARY
		mov	dl, CEN_ORIGINAL_NAME
		mov	dh, CED_DESTINATION_DIR
		call	ObjCallInstanceNoLock
		LONG jc	error

	; Create a translated geode.

		mov	ax, MSG_RESEDIT_DOCUMENT_CREATE_EXECUTABLE
		mov	cl, CET_TRANSLATED_GEODE
		mov	ch, CEU_DO_NOT_ATTEMPT_UPDATE
		mov	dl, CEN_ORIGINAL_NAME
		mov	dh, CED_SP_WASTE_BASKET
		call	ObjCallInstanceNoLock
		jc	error

	; Put up hourglass.

		call	MarkBusyAndHoldUpInput

	; Set top-level directory of translated geode.

		mov	ax, SP_WASTE_BASKET
		call	FileSetStandardPath

	; Get the document's TransMapHeader.

		call	GetFileHandle		; Get document file handle.
		call	DBLockMap		
		mov	di, es:[di]		; es:di = TransMapHeader

	; Open translated geode.

		push	ds
		mov	al, FILE_DENY_W or FILE_ACCESS_R
		segmov	ds, es, dx
		lea	dx, es:[di].TMH_dosName
		call	FileOpen
		pop	ds
		jc	errorUnlockDB
		push	ax

	; Set top-level directory for null-geode.

		mov	dx, offset DocumentInitfile:destinationKey
		call	SetDirectoryFromInitFile
		jc	errorUnlockDB

	; Open null geode.

		push	ds
		mov	al, FILE_DENY_W or FILE_ACCESS_R
		segmov	ds, es, dx
		lea	dx, es:[di].TMH_dosName
		call	FileOpen
		pop	ds			
		jc	errorUnlockDB

	; Change to the correct patch destination directory.

;		call	GeodeSetGeneralPatchPath

	; Create the patch file.

		pop	bx
		call	GeneratePatchFile

	; Close the geode files.

		push	ax
		clr	ax
		call	FileClose
		jc	errorUnlockDB
		pop	bx
		call	FileClose

	; Delete the translated geode.

		mov	ax, SP_WASTE_BASKET
		call	FileSetStandardPath
		segmov	ds, es, dx
		lea	dx, es:[di].TMH_dosName
		call	FileDelete

errorUnlockDB:

	; Unlock the document's TransMapHeader

		call	DBUnlock

error:

	; Restore original path.
		
		call	FilePopDir

	; Take down hourglass.

		pushf
		call	MarkNotBusyAndResumeInput
		popf

		.leave
		ret
REDCreateNullPatchFile	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDValidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the document to make sure string arguments match and
		no strings are outside size limits.

CALLED BY:	MSG_RESEDIT_DOCUMENT_VALIDATE

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #

RETURN:		if error,
			carry set
			ax = ErrorValue
		else
			carry clear

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDValidate	method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_VALIDATE
		uses	cx, dx
		.enter

EC <		call	AssertIsResEditDocument				>

	; Get the document file handle.

		call	GetFileHandle
		push	bx

	; Lock the TransMapHeader.

		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		pop	dx			; Document file handle.
		push	ds,si
		movdw	dssi, cxax

	; Check each chunk for errors.

		mov	bx, cs
		mov	di, offset CheckChunks
		call	ChunkArrayEnum	

	; Unlock TransMapHeader

		call	DBUnlock_DS
		pop	ds,si

		.leave
		ret
REDValidate	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the elements in this ResourceArray, checking
		for min/max or string argument violations.

CALLED BY:	PrepareToCreate

PASS:		*ds:si	- ResourceMap
		ds:di	- ResourceMapElement
		dx	- file handle
		
RETURN:		carry set to abort
			ax - ErrorValue
DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckChunks		proc	far
	.enter inherit REDCreateExecutable

	push	ds:[LMBH_handle]

	call	ChunkArrayPtrToElement
	mov	ss:[cef].CEF_resNumber, ax

	mov	bx, dx
	mov	ax, ds:[di].RME_data.RMD_group
	mov	di, ds:[di].RME_data.RMD_item
	call	DBLock_DS

	mov	cx, ax			;pass cx <- group, dx <- file handle
	mov	bx, cs			;  to the callback
	mov	di, offset CheckChunksCallback
	call	ChunkArrayEnum
	call	DBUnlock_DS

	pop	bx
	call	MemDerefDS
	.leave
	ret
CheckChunks		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckChunksCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that each text chunk which has 1 or 2 string args
		in the original has the same number in the translation.
		Check also that the min/max length constraints are not
		violated.

CALLED BY:	CheckChunks (via ChunkArrayEnum)
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		dx	- file handle
		cx	- group

RETURN:		carry set to abort
			ax - ErrorValue
DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckChunksCallback	proc	far
	uses	cx,dx
	.enter inherit REDCreateExecutable

	; if no translation item, nothing to check
	;
	tst	ds:[di].RAE_data.RAD_transItem
	jz	continue

	; if not a plain text chunk, don't need to check
	;
	test	ds:[di].RAE_data.RAD_chunkType, mask CT_TEXT
	jz	continue

	; check that all string arguments are present
	;
	call	CheckItemForStringArgs
	mov	ax, EV_MISSING_STRING_ARG
	jc	showOffender

	; check that min/max length not violated
	;
	call	CheckItemForLength
	jnc	done

showOffender:
	push	ax, ds, si
	call	ChunkArrayPtrToElement
	mov	dx, ax
	movdw	bxsi, ss:[cef].CEF_document
	call	MemDerefDS				; *ds:si <- document
	mov	al, ST_TRANSLATION
	mov	cx, ss:[cef].CEF_resNumber

	; pass 	al - target	
	; 	cx - resource number
	;	dx - chunk number
	;
	call	DocumentGoToResourceChunkTarget
	pop	ax, ds, si
	stc
done:
	.leave
	ret

continue:
	clc
	jmp	done
CheckChunksCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckItemForLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the translation item does not violate
		the min/max length contsraints.

CALLED BY:	CheckChunksCallback
PASS:		ds:di	- ResourceArrayElement
		dx	- file handle
		cx	- group number
		
RETURN:		carry set if length violates min or max
			ax - ErrorValue
DESTROYED:	bx,cx,dx,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckItemForLength		proc	near
	uses	si,di
	.enter

EC <	test	ds:[di].RAE_data.RAD_chunkType, mask CT_TEXT		>
EC <	ERROR_Z	BAD_CHUNK_TYPE						>

	; if min and max are both 0, size is not constrained
	;
	tst	ds:[di].RAE_data.RAD_minSize
	jnz	check
	tst	ds:[di].RAE_data.RAD_maxSize
	clc
	jz	done

check:
	mov	si, di				;ds:si <- ResourceArrayElement
	mov	bx, dx
	mov	ax, cx
	mov	di, ds:[si].RAE_data.RAD_transItem
	call	DBLock
	mov	di, es:[di]			;es:di <- chunk data
	ChunkSizePtr	es, di, cx		;cx <- size of chunk
	call	DBUnlock

	test	ds:[si].RAE_data.RAD_chunkType, mask CT_MONIKER
	jz	notMoniker
	sub	cx, MONIKER_TEXT_OFFSET		;cx <- length of text

notMoniker:
DBCS <	shr	cx, 1				;cx <- length of text	>
	dec	cx				;subtract the null
	mov	ax, EV_TEXT_TOO_SHORT
	cmp 	cx, ds:[si].RAE_data.RAD_minSize
	jb	fail
	mov	ax, EV_TEXT_TOO_LONG
	cmp 	cx, ds:[si].RAE_data.RAD_maxSize
	ja	fail
	clc
done:
	.leave
	ret

fail:
	stc
	jmp	done
CheckItemForLength		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckItemForStringArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure translation item has proper number of 
		string args.

CALLED BY:	CheckChunksCallback
PASS:		ds:di	- ResourceArrayElement
		dx	- file handle
		cx	- group number
		
RETURN:		carry set if a string arg is missing
DESTROYED:	ax,bx,cx,dx,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckItemForStringArgs		proc	near 	
	uses	cx,dx,si,di
	.enter	

	; if not text, can't have string arguments
	;
	cmp	ds:[di].RAE_data.RAD_chunkType, mask CT_TEXT
	clc
	jne	done
;XXX fix this to check text monikers, too

	; if there are no string args in the original, don't need to
	; check for them in the translation.  (In this case, a '@1' or
	; '@2' in the translation are not interpreted as string args)
	;
	tst	ds:[di].RAE_data.RAD_stringArgs
	clc
	jz	done

	push	ds:[di].RAE_data.RAD_stringArgs
	mov	bx, dx
	mov	ax, cx
	mov	di, ds:[di].RAE_data.RAD_transItem
	call	DBLock
	mov	di, es:[di]
	pop	bx

	clr	dh
	mov	dl, bh				;dx <- # of string arg 1
	clr	bh				;bx <- # of string arg 2
	ChunkSizePtr	es, di, cx		;cx <- size of string

if DBCS_PCGEOS
EC <	test	cx, 1							>
EC <	ERROR_NZ RESEDIT_IS_ODD						>
	shr	cx, 1				;cx <- length of string
endif
	; find all occurrences of '@' in the translated string
	;
SBCS <	mov	al, '@'							>
DBCS <	mov	ax, C_COMMERCIAL_AT					>

checkLoop:
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	jnz	checkDone			; '@' wasn't found...
SBCS <	cmp	{byte}es:[di], '1'		; is this string arg 1?	>
DBCS <	cmp	{word}es:[di], C_DIGIT_ONE				>
	jne	checkSecond		
	dec	dx				; yes, dec its counter 
	jmp	checkLoop

checkSecond:
SBCS <	cmp	{byte}es:[di], '2'		; is this string arg 2?	>
DBCS <	cmp	{word}es:[di], C_DIGIT_TWO				>
	jne	checkLoop
	dec	bx				; yes, dec its counter
	jmp	checkLoop

checkDone:
	tst	dx				;were all string args 1 found?
	jnz	failure
	tst	bx				;were all string args 2 found?
	jnz	failure
	clc	

unlock:
	call	DBUnlock
done:
	.leave
	ret

failure:
	stc
	jmp	unlock

CheckItemForStringArgs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The resource has been updated, now write it to file.

CALLED BY:	CreateExecutable

PASS:		^hbx	- locked resource block
		on stack - CEF

RETURN:		dx	- number of bytes written            
		carry set if error:
			ax - ErrorValue

DESTROYED:	ax,ds

PSEUDO CODE/STRATEGY:
	Write the resource block to file, which is already paragraph
	aligned. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteResource		proc	near
	uses	bx,cx,si
	.enter inherit REDCreateExecutable

	mov	ax, MGIT_SIZE
	call	MemGetInfo
	mov	cx, ax				;ax <- size, paragraph aligned
	
	; write the updated resource to the new geode file
	;
	call	MemDerefDS
	mov	bx, ss:[cef].CEF_newGeode	;^hbx <- file handle
	clr	dx				;ds:dx <- resource
	clr	al
	call	FileWrite			;cx <- # bytes written
	mov	dx, cx
	mov	ax, EV_FILE_WRITE_RESOURCE	;carry set if write error

	.leave
	ret

WriteResource		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteRelocationTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The updated resource has been written to the file,
		now write the relocation table out.  Free it when done.

CALLED BY: 	CreateExecutable

PASS:		^hbx	- handle of updated resource
		cx	- relocation table size
		on stack - CEF

RETURN:		carry set if error
			ax - ErrorValue

DESTROYED:	cx,dx,si

PSEUDO CODE/STRATEGY:
	The relocation table does not need to be updated for object blocks.
	It contains one null entry.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteRelocationTable		proc	near
	uses	bx
	.enter inherit REDCreateExecutable

	tst	cx
	clc
	jz	done				;no relocation table, skip it

	lea	si, ss:[cef]			;ss:si <- cef
	call	UpdateRelocationTable
	cmp	ax, EV_NO_ERROR
	stc
	jne	done

	mov	bx, ss:[cef].CEF_relocTable
	call	MemLock				;lock the reloc table
	mov	ds, ax

	mov	bx, ss:[cef].CEF_newGeode
	clr	dx				;ds:dx <- relocation table
	clr	al
	call	FileWrite			;write it to file
	mov	ax, EV_FILE_WRITE_RELOC_TABLE
	jc	unlock

	; update curPos for the next resource
	;
	clr	ax
	adddw	ss:[cef].CEF_curPos, axcx
	clc

unlock:
	mov	bx, ss:[cef].CEF_relocTable
	call	MemUnlock

done:
	.leave
	ret
WriteRelocationTable		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateResourceTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The resource has been updated, now set its new size
		and position in the resource table.  Also read its
		relocation table into memory.

CALLED BY:	(INTERNAL) CreateExecutable

PASS:		on stack: CreateExecutableFrame
		es	- DocumentHandleStruct segment
		cx	- actual resource size, or 0 it if is unchanged
		dx	- number of bytes written 

RETURN:		cx	- relocation table size
		carry set if error
			ax - CreateExecutionError
			dx - 0

DESTROYED:	ax,ds

PSEUDO CODE/STRATEGY:
	The resource table is laid out like this:

		+---------------------------------------+
		|					|
		|     Resource size table (words)	|
		|					|
		+---------------------------------------+
		|					|
		|   Resource position table (dwords)	|
		|					|
		+---------------------------------------+
		|					|
		|  Relocation table size table (words)	|
		|					|
		+---------------------------------------+
		|					|
		|    Allocation flags table (words)	|
		|					|
		+---------------------------------------+

	First, save the new size for this resource.
	Then save its file position, passed in ss:bp.
	Update the current file position after this resource is written.
	Get its relocation table size, and if non-zero,
	allocate a block and read it in.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateResourceTable		proc	near
	uses	bx,si,di,es
	.enter inherit REDCreateExecutable

	segmov	ds, es, ax

	mov	bx, ss:[cef].CEF_resourceTable
	call	MemLock
	mov	es, ax				;es <- segment of resource table

	; save the new resource size, if it has changed
	;
	mov	ax, ss:[cef].CEF_resNumber	; ax <- resource number	
	shl	ax, 1				; ax <- res # * 2 = offset
	mov	si, ax				;es:si <- this resource's size
	tst	cx
	jz	noChange
	mov	es:[si], cx

noChange:
	; save the new file position for this resource
	;
	push	si, dx				;resource*2
	shl	ax, 1				;resource*4	
	mov	si, ax
	mov	ax, ss:[cef].CEF_TFF.TFF_numResources
	shl	ax, 1				;#res*2 (skip res size table)
	add	si, ax				;#res*2 + res*4 (resource pos)
	movdw	es:[si], ss:[cef].CEF_curPos, dx
	pop	si, dx				;res*2

	; get the size of its relocation table
	add	si, ax		
	add	si, ax
	add	si, ax				;#res*6 + res*2
	mov	cx, es:[si]			;cx <- size of reloc table

	push	bx
	mov	bx, ss:[cef].CEF_resourceTable
	call	MemUnlock			;unlock resource table
	pop	bx

	; update file position to point to end of this (padded) resource
	;
	clr	ax
	adddw	ss:[cef].CEF_curPos, axdx			
;	tst	cx				;did resource change?
;	clc	
;	jz	done				;Nope, we're done.

	; resize the block for the relocation table
	;
	push	cx
	mov	ax, cx				;ax <- size of reloc table
	mov	cx, ALLOC_DYNAMIC_LOCK
	mov	bx, ss:[cef].CEF_relocTable
	call	MemReAlloc			;^hbx <- block, ax <- segment
	jc	noMem
	pop	cx				;relocation table size

	push	bx				;save relocation table handle
	mov	ds, ax
	clr	dx  				;ds:dx <- buffer to read into
	segmov	es, ss:[cef].CEF_TFF.TFF_handles
	mov	bx, es:[DHS_geode]
	clr	al
	call	FileRead			;cx <- # bytes read
	pop	bx				;^hbx <- relocation table
	jc	fileError
	call	MemUnlock			;unlock relocation table

	clc
done:
	.leave
	ret

noMem:
	add	sp, 2				;fixup the stack
	mov 	ax, EV_MEMALLOC
	jmp	error
fileError:
	mov	ax, EV_FILE_READ_HEADERS
	mov	bx, ds:[LMBH_handle]
	call	MemFree				;free the relocation table
error:
	clr	bx				;no handle to return
	clc
	jmp	done

UpdateResourceTable		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update any chunks that have changed, compact the
		heap, fix the LMemBlockHeader.

CALLED BY:	(INTERNAL) - CreateExecutable

PASS:		on stack: CreateExecutableFrame
		es	- DocumentHandlesStruct segment
		^hbx	- locked resource block
		ax	- segment of resource block

RETURN:		cx	- resource size, or 0 if it is unchanged
		carry set if error:
			ax - ErrorValue

DESTROYED:	ax, ds

PSEUDO CODE/STRATEGY:
	This routine is called for every resource, including those
	that are not LMem, and those that have no handles.
	If the resource has no handles, it does not need to be
	updated, but its resource ID must be restored to LMBH_handle.

	Find and lock the ResourceArray for this resource.
	Use ChunkArrayEnum to go through each element and update
	the resource with the data in the ResourceArrayElement.
	Compact the heap (if LMem) and update LMBH fields.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateResource		proc	near
	uses	bx,dx,si,di,es
	.enter	inherit REDCreateExecutable


		mov	es, ax				; es <- resource segment
	
	; Find the ResourceMapElement for this resource.  If there is not
	; one, this resource has no editable chunks.  Just return its size.
	 
		mov	ss:[cef].CEF_TFF.TFF_sourceGroup, bx
		;save resource handle
		mov	bx, ss:[cef].CEF_TFF.TFF_transFile
		call	DBLockMap_DS			; *ds:si <- ResourceMap
		mov	ax, ss:[cef].CEF_resNumber
		call	FindResourceNumber
		LONG	jc	notFound		; Resource not found
		mov	si, di				; ds:di <- ResMapElement

	; Lock the resource array, which contains possibly edited chunks
	 
		mov	dx, bx				; Save trans file
		mov	ax, ds:[si].RME_data.RMD_group	; ResArray group & item
		mov	di, ds:[si].RME_data.RMD_item
		call	DBUnlock_DS			; unlock ResourceMap
		call	DBLock_DS			; *ds:si <- ResArray

	; Set the callback to either translate the chunks or null out all
	; strings.

		mov	di, offset UpdateChunk		;bx:di <- callback
		cmp	ss:[cef].CEF_TFF.TFF_geodeType, CET_NULL_GEODE
		jne	doEnum
		mov	di, offset NullStringsInChunk	;bx:di <- callback
doEnum:

	; Process each chunk.

	; pass es <- resource segment, bp <- group number, 
	; ^hdx <- translation file to the callback
	
		push	bp
		mov	bp, ax				;bp <- group number
		mov	bx, cs
		call	ChunkArrayEnum	
		pop	bp
		call	DBUnlock_DS			;unlock ResourceArray
		jc	updateError			;cx <- chunk number

	; Now that all chunks have been updated, contract the block.
	
		segmov	ds, es, ax
		call	LMemContract		

	; If it is an object block, the resourceSize in ObjLMemBlockHeader
	; must be updated so that the resource can be reloaded correctly
	; (size of resource block in paragraphs)
	;
	mov	bx, ss:[cef].CEF_TFF.TFF_sourceGroup	;get resource handle
	test	ds:[LMBH_lmemType], LMEM_TYPE_OBJ_BLOCK
	jz	notObject
	mov	ax, MGIT_SIZE
	call	MemGetInfo			;ax <- resource size
	mov	cl, 4
	shr	ax, cl				;ax <- number of paragraphs
	mov	ds:[OLMBH_resourceSize], ax

notObject:
	; Restore the resource ID to the LMemBlockHeader.
	;
	mov	ax, ss:[cef].CEF_resNumber
	mov	ds:[LMBH_handle], ax

	; Turn off LMem management of block.
	;
	mov	ax, (mask HF_LMEM shl 8)
	call	MemModifyFlags
	mov	cx, ds:[LMBH_blockSize]		;return cx = block size
	clc

done:	
	.leave
	ret

notFound:
	; There was no entry for this resource in the ResourceMap.
	; Either it is not LMem, or it has no editable chunks.
	; In the latter case, we need to restore the resource ID
	; to LMBH_handle.
	;
	clr	cx				;resource size unchanged
	call	DBUnlock_DS			;unlock the map block
	mov	bx, ss:[cef].CEF_TFF.TFF_sourceGroup	;get resource handle
	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
	call	MemGetInfo			; al <- HeapFlags
        test    al, mask HF_LMEM
	clc
        jz      done				; not LMem, good-bye
	segmov	ds, es, ax			; ds <- resource segment
	jmp	notObject

updateError:
	; DocumentGoToResourceChunkTarget wants:
	; pass 	al - target	
	; 	cx - element # of resource
	;	dx - element # of chunk
	;	ds:si - document
	push	ax
	mov	dx, cx			; dx <- element # of chunk

	; Convert from resource # to element # of resource
	mov	bx, ss:[cef].CEF_TFF.TFF_transFile
	call	DBLockMap_DS				;*ds:si <- ResourceMap
	mov	ax, ss:[cef].CEF_resNumber
	call	FindResourceNumber
EC <	ERROR_C CHUNK_ARRAY_ELEMENT_NOT_FOUND				>
	call	ChunkArrayPtrToElement
	call	DBUnlock_DS				;unlock ResourceMap
	mov_tr	cx, ax			; cx <- element # of resource

	movdw	bxsi, ss:[cef].CEF_document
	call	MemDerefDS
	mov	al, ST_ORIGINAL
	call	DocumentGoToResourceChunkTarget
	pop	ax
	stc
	jmp	done

UpdateResource		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the data in the chunk for this element to 
		the data stored in the TransItem.

CALLED BY:	UpdateResource (via ChunkArrayEnum)

PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		bp	- resource group
		es	- segment of resource from source geode
		^hdx	- translation file handle

RETURN:		carry set if error:
			ax - ErrorValue
			cx - ResourceArrayElement's number
DESTROYED:	ax,bx,cx

    WARNING: This routine MAY resize LMem and/or object blocks
	...invalidating stored segment pointers and current register
	or stored offsets to them.

PSEUDO CODE/STRATEGY:
	Verify that the original item in the resource array is the
	same as the chunk that will be changed.

	If there is no translation item, don't change anything.

	Calculate # of bytes to be inserted or deleted and call
	LMemInsert or LMemDelete to do it.

	Copy the translation into the chunk.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateChunk		proc	far
	uses	dx,bp
	.enter

EC <		Assert	lmem, es:[LMBH_handle]				>
EC <		Assert	lmem, ds:[LMBH_handle]				>
		push	es:[LMBH_handle]
		push	ds:[LMBH_handle]

	; If this is an object, no need to do any of what follows...

		test	ds:[di].RAE_data.RAD_chunkType, mask CT_OBJECT
		LONG	jnz	updateObject

	; If the original chunk stored in the translation file does not
	; match *exactly* the chunk from the resource block, it's an error.

		call	VerifyChunkEquality		;cx <- size of original
		LONG	jc	verifyError

	; If there is no translation item, nothing to change

		mov	ax, bp				;ax <- group number
		mov	bp, ds:[di].RAE_data.RAD_transItem
		tst	bp
		clc
		LONG	jz	done

	; Lock down the translated item, get its size

		push	cx				;save original size
		push	ds:[di].RAE_data.RAD_handle	;save chunk handle
		mov	cx, ds:[di].RAE_data.RAD_stringArgs		
		mov	bx, dx				;^hbx <- file handle
		mov	dl, ds:[di].RAE_data.RAD_chunkType
		mov	di, bp
		call	DBLock_DS
		mov	di, ds:[si]
		mov	al, dl				;al <- ChunkType
		ChunkSizePtr	ds, di, dx		;dx <- size of trans

	; If not text, or no string args, size is okay
	
		cmp	al, mask CT_TEXT
		jne	haveSize
		tst	cx			
		jz	haveSize

	; Subtract the number of string arguments from the size
	; (to account for the extra 'at' character)
	; DBCS: each extra 'at' character is two bytes.

		push	cx, cx
		clr	ch
		sub	dx, cx				; cx <- string arg 1
DBCS <		sub	dx, cx						>
		pop	cx
		mov	cl, ch
		clr	ch
		sub	dx, cx				; cx <- string arg 2
DBCS <		sub	dx, cx						>
		pop	cx

haveSize:
	; Need the chunk to be resized in ds for the LMem call

		segxchg	es, ds				;es:di <- ResArrayElem
		pop	si				;*ds:si<-resize chunk
		mov	bx, cx				; bx <- TextStringArgs
		pop	cx				; cx <- original size

	; We'll insert or delete at beginning of chunk, since the
	; entire translated chunk is copied to the resource

		push	ax, bx				;save CT, StringArgs
		mov	ax, si				;chunk to resize
		clr	bx				;insert/del at byte 0
		mov	bp, dx				;save new chunk size

		cmp	dx, cx
		jg	insertBytes
		cmp	dx, cx				;XXX: unnecessary?
		jl	deleteBytes

copyChunk:
	; Restore ChunkType, TextStringArgs
		pop	ax, bx

	; Now set ds:si <- source (ResourceArrayElement transItem)
	; and set es:di <- destination (resource block)

		push	ds:[si]				;save transItem offset
		segxchg	ds, es
		mov	si, di
		pop	di
		mov	cx, bp				;size of new item

		push	ax
		call	UpdateChunkCopyData
		call	LocInitEndOfChunk
		call	DBUnlock_DS			;unlock trans item
		pop	cx
		jc	error

	; Check that the new chunk is the size it is expected to be
	
EC <		ChunkSizePtr	es, di, bx			>
EC <		cmp	bx, bp					>
EC <		ERROR_NE	CHUNK_SIZE_MISMATCH		>

	; If this is a text moniker, fix-up the cached width.
	; Pass cl - ChunkType
	
		call	UpdateChunkFixMonikerWidth
		clc

error:
done:
		pop	bx
		call	MemDerefDS			;deref ResourceArray
		pop	bx
		call	MemDerefES			;deref resource block
		.leave
		ret

updateObject:
		call	UpdateObjectChunk
		clc
		jmp	done

insertBytes:
		sub	dx, cx
		mov	cx, dx				;cx <- # bytes to add
		call	LMemInsertAt
		mov	ax, EV_UPDATE_CHUNK_RESIZE
		jc	errorUnlockPopTwo
		jmp	copyChunk

deleteBytes:
		sub	cx, dx				;cx <- #bytes to delete
		call	LMemDeleteAt
		mov	ax, EV_UPDATE_CHUNK_RESIZE
		jnc	copyChunk
	
errorUnlockPopTwo:
		add	sp, 4			;clear CT, StringArgs from the stack
		call	DBUnlock			;unlock ResArrayElement
		jmp	done

verifyError:
	; The original chunk in the translation file doesn't match
	; the real chunk it is supposed to correspond to in the geode.
	; Get the element number so the caller knows who is causing problems.
	
		call	ChunkArrayPtrToElement		; ax <- element number
		mov	cx, ax
		mov	ax, EV_CHUNK_MISMATCH
		stc
		jmp	done

UpdateChunk		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NullStringsInChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this chunk holds textual data, replace it with a null
		string.

CALLED BY:	UpdateResource (via ChunkArrayEnum)

PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		bp	- resource group
		es	- segment of resource from source geode
		^hdx	- translation file handle

RETURN:		carry set if error:
			ax - ErrorValue
			cx - ResourceArrayElement's number
DESTROYED:	ax,bx,cx

    WARNING: This routine MAY resize LMem and/or object blocks
	...invalidating stored segment pointers and current register
	or stored offsets to them.

PSEUDO CODE/STRATEGY:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	6/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NullStringsInChunk	proc	far
		uses	dx,si,di,bp
		.enter

EC <		Assert	lmem, es:[LMBH_handle]				>
EC <		Assert	lmem, ds:[LMBH_handle]				>

		push	es:[LMBH_handle]
		push	ds:[LMBH_handle]

	; If this is an object, or not text, do nothing.

		test	ds:[di].RAE_data.RAD_chunkType, mask CT_OBJECT
		jnz	done
		test	ds:[di].RAE_data.RAD_chunkType, mask CT_TEXT
		jz	done

	; If the original chunk stored in the translation file does not
	; match *exactly* the chunk from the resource block, it's an error.
	
		call	VerifyChunkEquality	; cx <- size of original
		LONG	jc	verifyError

	; Need the chunk to be resized in ds for the LMem call
	
		mov	si, ds:[di].RAE_data.RAD_handle
		segxchg	es, ds			; es:di <- ResArrayElem
		mov	ax, si			; chunk to resize
		clr	bx			; insert/del at byte 0

	; Delete all but one character (for null).

nullString::
		dec	cx			;cx <- #bytes to delete
		call	LMemDeleteAt
		mov	ax, EV_UPDATE_CHUNK_RESIZE
		jc	done			; error

	; Write in null character.

		mov	di, ds:[si]
		segxchg	ds, es
		mov	{byte} es:[di], 0	; Write in null.

	; Set the end of the chunk to a 0xcc.

		call	LocInitEndOfChunk
	
	; Check that the new chunk is the size it is expected to be
	
EC <		ChunkSizePtr	es, di, bx			>
EC <		cmp	bx, 1					>
EC <		ERROR_NE	CHUNK_SIZE_MISMATCH		>
		clc

done:
		pop	bx
		call	MemDerefDS		;deref ResourceArray
		pop	bx
		call	MemDerefES		;deref resource block

		.leave
		ret

verifyError:

	; The original chunk in the translation file doesn't match
	; the real chunk it is supposed to correspond to in the geode.
	; Get the element number so the caller knows who is causing problems.
	
		call	ChunkArrayPtrToElement	; ax <- element number
		mov	cx, ax
		mov	ax, EV_CHUNK_MISMATCH
		stc
		jmp	done

NullStringsInChunk	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocInitEndOfChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the end of a used chunk to 0xcc.

CALLED BY:	INTERNAL UpdateChunk
PASS:		es:di	= chunk.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/ 1/90		Initial version
	dubois	11/15/94  	Stolen from kernel and tweaked

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocInitEndOfChunk	proc	near
	uses	di, cx, ax			;
	.enter					;

if ERROR_CHECK
	push	ax, bx
	mov	bx, es:[LMBH_handle]
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	cmp	di, ax
	ERROR_AE	-1
	pop	ax, bx
endif

	; es:di <- ptr to chunk
	mov	cx, es:[di].LMC_size		;
	add	di, cx				;
	dec	di				; di <- ptr to chunk end.
	dec	di
	mov	ax, cx				;
	RoundUpDW	cx			;
	sub	cx, ax				; cx <- # of free bytes.
	mov	al, 0xcc			;
	rep	stosb				;
	.leave					;
	ret					;
LocInitEndOfChunk	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateObjectChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This object has a keyboard shortcut which may need updating.

CALLED BY:	INTERNAL (UpdateChunk)
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		bp	- resource group
		es	- segment of resource from source geode
		^hdx	- translation file handle

RETURN: 	nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Store the kbdAccelerator, regardless of whether or not it
	has changed, since that is easiest.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateObjectChunk	proc	near

	push	bp
	mov	bp, ds:[di].RAE_data.RAD_handle		;*es:bp <- object
	mov	bp, es:[bp]
	add	bp, es:[bp].Gen_offset
	mov	ax, ds:[di].RAE_data.RAD_kbdShortcut
	mov	es:[bp].GI_kbdAccelerator, ax
	pop	bp
	ret

UpdateObjectChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateChunkFixMonikerWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Data has been copied out to chunk.
		Fix-up moniker's cached width, if necessary.

CALLED BY:	UpdateChunk
PASS:		es:di	- new chunk
		cl	- ChunkType

RETURN:		nothing
DESTROYED:	ax,bx,cx,si,di,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Should I provide a cached width for ALL monikers, or only 
	those that previously had a cached width?
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateChunkFixMonikerWidth		proc	near
	uses	bp,dx
	.enter

	test	cl, mask CT_MONIKER
	jz	done
	test	cl, mask CT_TEXT
	jz	done

	segmov	ds, es
	mov	si, di	
	mov	bp, di				; es:bp <- VisMoniker
	add	si, MONIKER_TEXT_OFFSET		; ds:si <- moniker's text

	clr	di
	call	GrCreateState

	;
	; set font, point size to use when calculating width
	;

if PZ_PCGEOS
	mov	cx, FID_PIZZA_KANJI
	mov	dx, 12
else
	mov	cx, FID_BERKELEY
	mov	dx, 9				; point size = 9
endif

	clr	ah				; (no fraction part)
	call	GrSetFont
	call	GrTextWidth			; dx <- moniker width (points)
	mov	bx, dx

if PZ_PCGEOS
CheckHack <width VMCW_PIZZA_KANJI_12 eq 7>
	test	bx, 0xff80			; are high bits set?
	WARNING_NZ	PIZZA_KANJI_12_TOO_LARGE
	jnz	noCachedWidth
	andnf	bx, 0x7f			; 7 bits for pizza 12
	mov	cl, offset VMCW_PIZZA_KANJI_12
	shl	bx, cl
else
	; check whether width will fit in 7 bits
	;
	test	bx, 0xff80			; are high bits set?
	jnz	noCachedWidth
	andnf	bx, 0x7f			; 7 bits for berkeley 9
	mov	cl, offset VMCW_BERKELEY_9
	shl	bx, cl
endif	
	;
	; set font, point size to use when calculating width
	;
if PZ_PCGEOS
CheckHack <width VMCW_PIZZA_KANJI_16 eq 8>
CheckHack <offset VMCW_PIZZA_KANJI_16 eq 0>
	mov	cx, FID_PIZZA_KANJI
	mov	dx, 16
	clr	ah
	call	GrTextWidth
	andnf	dx, 0xff			; 8 bits for pizza 16
	WARNING_NZ	PIZZA_KANJI_16_TOO_LARGE
	jnz	noCachedWidth
	ornf	bx, dx
	ornf	bx, mask VMCW_HINTED
else
	mov	cx, FID_BERKELEY
	mov	dx, 10				; point size = 10
	clr	ah				; (no fraction part)
	call	GrTextWidth			; dx <- moniker width
	andnf	dx, 0xff			; 8 bits for berkeley 10
CheckHack <offset VMCW_BERKELEY_10 eq 0>
	mov	bl, dl
	or	bx, mask VMCW_HINTED
endif

storeWidth:
	mov	es:[bp].VM_width, bx
	call	GrDestroyState
done:
	.leave
	ret

noCachedWidth:
	clr	bx
	jmp	storeWidth

UpdateChunkFixMonikerWidth		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateChunkCopyData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the translated item to the resized chunk.

CALLED BY:	UpdateChunk
PASS:		ds:si	- pointer to translation item data
		es:di	- pointer to destination chunk
		cx	- size of chunk pointed to by es:di
		al	- ChunkType
		bx	- TextStringArgs

RETURN:		carry set if not all string args found
			ax - CEE
DESTROYED:	si, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:	pushes/pops di twice?
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateChunkCopyData		proc	near	
	uses	bx,dx,di
	.enter

	mov	dl, al
	push	di	
	test	dl, mask CT_TEXT	; is it text of some sort?
	jz	copyLoop		; if not text, it has no string args
	tst	bx			; if text, it has optional string args
	jz	copyLoop		; if no string args, do straight copy

DBCS <	shr	cx, 1			; cx <- length of string	>
argLoop:
	; if no more string args to find, do a straight copy
	;
	tst	bx					
SBCS <	jz	copyLoop						>
DBCS <	jz	copyLoopShlCX						>

	; if this char is not start of string arg expression, continue
	;
	LocalGetChar	ax, dssi		; lods[bw]
	LocalCmpChar	ax, '@'			; cmp a[lx]
	jne	continue

	; is it the first string arg?
	;
	LocalCmpChar	ds:[si], '1'
	jne	checkSecondArg

	; we found string arg 1 - '@1'.  Want to write '\1', not '@1'.
	; so put 1 in al, skip the @.
	;
	dec	bh				; dec the string arg 1 count
	LocalLoadChar	ax, 1			; store a '\1', not a '@'
	LocalNextChar	dssi			; skip the next char ('1')
	jmp	continue

checkSecondArg:
	; is it the second string arg?
	;
	LocalCmpChar	ds:[si], '2'
	jne	continue

	; we found string arg 2 - '@2'.  write '\2', not '@2'
	;
	dec	bl				; dec the string arg 2 count
	LocalLoadChar	ax, 2			; store a '\2', not a '@'
	LocalNextChar	dssi			; skip the next char ('2')

continue:
	LocalPutChar	esdi, ax
	loop	argLoop

	pop	di
	tst	bx
	clc
	jz	done
	mov	ax, EV_MISSING_STRING_ARG
	stc
done:
	.leave
	ret

DBCS <copyLoopShlCX:							>
DBCS <	shl	cx, 1				;cx <- size of string	>
copyLoop:
	rep	movsb
	pop	di
	clc
	jmp	done

UpdateChunkCopyData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyChunkEquality
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that chunk in geode is same as original chunk
		stored in the translation file, to ensure that the
		translation file is not out of sync with the geode.

CALLED BY:	UpdateResourceCallback

PASS:		*ds:si  - ResourceArray
		ds:di	- ResourceArrayElement
		bp	- resource group
		^hdx	- translation file
		es	- segment containing resource from geode 

RETURN:		cx	- size of original chunk
		carry set if chunks are not equal

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyChunkEquality		proc	near
	uses	dx,si,di,ds
	.enter

		mov	cx, ds:[di].RAE_data.RAD_stringArgs

	; Make sure it is a valid handle
	
		mov	ax, es:[LMBH_nHandles]		;number of handles
		shl	ax, 1				;size of handle table
		add	ax, es:[LMBH_offset]		;max handle
		mov	bx, ds:[di].RAE_data.RAD_handle
		mov	di, ds:[di].RAE_data.RAD_origItem
		cmp	bx, ax				;is it a valid handle
		stc
		LONG	jge	done

		push	bx
		mov	ax, bp
		mov	bx, dx
		call	DBLock_DS
		mov	si, ds:[si]			;ds:si <- origItem
		pop	di

	; Check if the chunk handle is in bounds.

		mov	dx, es:[LMBH_offset]
		cmp	di, dx
		LONG jb	handleOutOfBounds	; It is before handle table.
		mov	ax, es:[LMBH_nHandles]
		shl	ax, 1
		add	dx, ax
		cmp	di, dx
		LONG jae handleOutOfBounds	; It is after handle table.

	; Check that handle is not free, not 0 sized
	
		clr	ax				;chunk size for now
		mov	di, es:[di]			;es:di <- chunk
		inc	di
		jz	cmpSizes			;will fail, since ax=0
		dec	di
		jz	cmpSizes			;will fail, since ax=0

		ChunkSizePtr	es, di, ax	; ax <- resource's chunk size

cmpSizes:
		ChunkSizePtr	ds, si, dx	; dx <- TransFile's chunk size
	;
	; subtract the extra byte (word) for the at sign in front of each string
	; arg representation stored in the TransFile's chunk.
	;
	clr 	bh
	mov	bl, ch				; bx <- number of stringArg1
	sub	dx, bx
DBCS <	sub	dx, bx							>
	mov	bl, cl				; bx <- number of stringArg2
	sub	dx, bx				; dx <- size less string args
DBCS <	sub	dx, bx							>

	mov	bx, dx				; save the size in bx
	cmp	ax, dx				; do their sizes match?
	stc
	jne	noMatch
	mov	dx, ax				; dx <- orig string length
	xchg	cx, dx				; dx <- string arguments

	;
	; Now es:di <- chunk from geode, ds:si <- original chunk stored
	; in the translation file, cx = length of the two chunks (with
	; OrigItem chunk size adjusted for string argument at signs)
	;
	tst	dx				; are there string args?
	jnz	stringArgs			; yes... do complex checking
noStringArgs::
	repe	cmpsb
	je	match
	jmp	noMatch

stringArgs:
if DBCS_PCGEOS
EC <	test	cx, 1				; should be safe to use lodsw	>
EC <	ERROR_NZ NON_STRING_HAS_STRING_ARGS	; if no, something's wrong	>
	shr	cx, 1
endif
cmpNext:
	LocalGetChar	ax, dssi	; a[lx] <- next byte/word from OrigItem
	LocalCmpChar	ax, '@'			; is it the at sign?
	jne	compare				; no, proceed as normal
	tst	dx				; are there string args?
	jz	compare				; no, proceed as normal
	LocalCmpChar	es:[di], 2		; is this a valid string arg?
	ja	compare				; no, it is greater than 2
	LocalCmpChar	es:[di], 0		;
	je	compare				; no, it is less than 1
	;
	; The current char in the translation file chunk is the at sign.
	; The current char in the geode's chunk is either 1 or 2, a valid
	; string argument.  Check whether the next byte in the translation
	; file chunk matches it.  If not, this is a mismatch.
	;
	LocalGetChar	ax, dssi		; a[lx] <- should be '1' or '2'
SBCS <	sub	al, '0'				; al <- numeric representation	>
DBCS <	sub	ax, C_DIGIT_ZERO		; ax <- numeric representation	>
compare:
	LocalCmpChar	ax, es:[di]
	jne	noMatch
	LocalNextChar	esdi
	loop	cmpNext
	
match::
	clc
	mov	cx, bx
unlock:
	call	DBUnlock_DS
done:
	.leave
	ret

noMatch:
	stc
	jmp	unlock

handleOutOfBounds:
	stc
	jmp	done

VerifyChunkEquality		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyResourceTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a copy of the resource table that will not
		be modified in the process of building the new executable.

CALLED BY:	DocumentBuildNewGeode

PASS:		es - DocumentHandlesStruct
		on stack - CreateExecutableFrame

RETURN:		carry set if unsuccessful
			ax - ErrorValue

DESTROYED:	bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	sets CEF_curPos to point past headers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyResourceTable	proc	near
	.enter inherit REDCreateExecutable

	movdw	bxsi, ss:[cef].CEF_document
	push	bx
	call	MemDerefDS
EC <	call	AssertIsResEditDocument				>

EC<	cmp	es:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG	>
EC<	ERROR_NE  BAD_DOCUMENT_HANDLES_STRUCT			>

	mov	bx, es:[DHS_resourceTable]
	mov	ax, MGIT_SIZE
	call	MemGetInfo			;ax <- size

	push	ax
	mov	dx, bx				;^hdx <- original block
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			;^hbx <- block, ax <- segment
	pop	cx
	jc	done
	mov	es, ax				;es:0 <- destination

	push	bx				;save new block handle
	mov	bx, dx				;^hbx <- original
	call	MemLock				;lock the source block
	mov	ds, ax				;ds:0 <- source

	; do the copy (cx = number of bytes)
	shr	cx				; cx <- # words
	clr	si, di
	rep	movsw

	call	MemUnlock			;unlock source block
	pop	bx
	call	MemUnlock			;unlock copy block
	mov	ss:[cef].CEF_resourceTable, bx

	; allocate the Relocation table block, with enough room for
	; one dword entry
	;
	mov	ax, 4				;room for 1 relocation entry
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc			;^hbx <- block
	mov	ss:[cef].CEF_relocTable, bx
	
done:
	mov	ax, EV_MEMALLOC
	segmov	es, ss:[cef].CEF_TFF.TFF_handles, cx

	pop	bx
	call	MemDerefDS

	.leave
	ret
CopyResourceTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyHeaders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the headers from the source to destination geode.

CALLED BY:	CreateExecutable

PASS:		on stack- CreateExecutableFrame
		es	- segment of DocumentHandlesStruct

RETURN:		carry set if unsuccessful:
			ax	- ErrorValue

DESTROYED:	ax,bx,cx,dx,ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	sets ss:[curPos] to point past headers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyHeaders		proc	near
	.enter inherit REDCreateExecutable
	
	push	ds:[LMBH_handle]

	; position the file at the start of the GeodeFileHeader
	;
	segmov	es, ss:[cef].CEF_TFF.TFF_handles, ax
EC<	cmp	es:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG		>
EC<	ERROR_NE  BAD_DOCUMENT_HANDLES_STRUCT				>
	mov	bx, es:[DHS_geode]
	mov	dx, offset GFH_execHeader
	clr	cx				;cx:dx <- file position
	mov	al, FILE_POS_START
	call	FilePos

	; allocate room for the GeodeHeader, less the space used only
	; when the geode is loaded 
	;
	mov	cx, (size ExecutableFileHeader + offset GH_geoHandle)
	sub	sp, cx
	mov	dx, sp
	segmov	ds, ss, ax			;ds:dx <- buffer to read into
	clr	al
	call	FileRead
	mov	ax, EV_FILE_READ_HEADERS
	LONG	jc	errorGFH

	; don't change the GeodeFileHeader, just copy it
	;
	mov	bx, ss:[cef].CEF_newGeode
	clr	al
	call	FileWrite
	mov	ax, EV_FILE_WRITE
	LONG	jc	errorGFH
	clr	ax
	movdw	ss:[cef].CEF_curPos, axcx	; cx = # bytes written

	mov	si, dx
	mov	ax, ds:[si].GFH_execHeader.EFH_resourceCount
	mov	bx, ds:[si].GFH_execHeader.EFH_importLibraryCount
	mov	cx, ds:[si].GFH_execHeader.EFH_exportEntryCount

	cmp	ax, ss:[cef].CEF_TFF.TFF_numResources
	mov	ax, EV_NUM_RESOURCES
	LONG	jne	errorGFH

	add	sp, (size ExecutableFileHeader + offset GH_geoHandle)

	; Load the import, export and resource tables.  Store block
	; handles in document instance data.
	;
	mov	ax, ss:[cef].CEF_TFF.TFF_numResources
	push	bp
	lea	bp, ss:[cef].CEF_TFF
	call	LoadTables
	pop	bp
	LONG	jc	error

	mov	ax, bx				;ax <- # import entries
	tst	ax
	jnz	haveImports
	mov	ax, cx				;ax <- # export entries
	jmp	noImports

haveImports:
	; calculate the size of the Imported Library table
	;
	push	cx				;save # export entries
	mov	bx, size ImportedLibraryEntry
	clr	dx
	mul	bx				;ax <- # bytes to write
EC <	tst	dx						>
EC <	ERROR_NZ BLOCK_SIZE_TOO_LARGE				>
	mov	cx, ax	

	; lock the import table and write it to the file, unchanged
	;
	mov	bx, es:[DHS_importTable]
	call	MemLock
	mov	ds, ax
	clr	dx				;ds:dx <- buffer to write from
	mov	bx, ss:[cef].CEF_newGeode
	clr	al
	call	FileWrite			;cx <- # bytes written
	mov	bx, es:[DHS_importTable]
	call	MemUnlock
	pop	ax				;ax <- # export entries
	LONG	jc	fileError
	adddw	ss:[cef].CEF_curPos, dxcx	;cx=# bytes written (dx=0)

noImports:
	; calculate the size of the Export table, if there is one
	;
	tst	ax				;any export entries?
	jz	noExports		
	mov	cx, size dword			;size of an export entry
	clr	dx
	mul	cx				;ax <- size of export table
EC <	tst	dx						>
EC <	ERROR_NZ BLOCK_SIZE_TOO_LARGE				>

	; lock the export table and write it to the file, unchanged
	;
	mov	cx, ax				;# bytes to write
	mov	bx, es:[DHS_exportTable]
	call	MemLock
	mov	ds, ax
	clr	dx				;ds:dx <- buffer to write from
	mov	bx, ss:[cef].CEF_newGeode
	clr	al
	call	FileWrite
	mov	bx, es:[DHS_exportTable]
	call	MemUnlock
	LONG	jc	fileError
	adddw	ss:[cef].CEF_curPos, dxcx	;cx= # bytes written (dx=0)

noExports:
	pushdw	ss:[cef].CEF_curPos		;save FilePos of resource table

	; calculate the size of the resource table
	;
	mov	ax, ss:[cef].CEF_TFF.TFF_numResources
	mov	cx, 10				;size of resource table info
	clr	dx
	mul	cx
EC <	tst	dx						>
EC <	ERROR_NZ BLOCK_SIZE_TOO_LARGE				>
	mov	cx, ax				;# of bytes to write

	; Lock the resource table and write it to the file, unchanged,
	; just as a place holder.  Changed table will be written later.
	;
	mov	bx, es:[DHS_resourceTable]
	call	MemLock
	mov	ds, ax
	clr	dx				;ds:dx <- buffer to write from
	mov	bx, ss:[cef].CEF_newGeode
	clr	al
	call	FileWrite
	mov	bx, es:[DHS_resourceTable]
	call	MemUnlock
	jc	fileErrorPop2
	adddw	ss:[cef].CEF_curPos, dxcx	;cx= # bytes written (dx=0)

	popdw	ss:[cef].CEF_resTablePos
	mov	ss:[cef].CEF_resTableSize, cx
	clc

error:
	pop	bx
	call	MemDerefDS

	.leave
	ret

errorGFH:
	add	sp, (size ExecutableFileHeader + offset GH_geoHandle)
	stc
	jmp	error

fileErrorPop2:
	add	sp, 4				;clear file pos off stack
fileError:
	mov	ax, EV_FILE_WRITE
	stc
	jmp	error

CopyHeaders		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenBuildFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the source geode and a new file in the
		destination path for the new geode.

CALLED BY:	CreateExecutable

PASS:		ss:bp	- CreateExecutableFrame
		es	- DocumentHandleStruct segment
		^hbx	- translation file
		ds:si	- document

RETURN: 	carry set if error
		ax	- ErrorValue

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenBuildFiles		proc	near
		uses	es
		.enter inherit REDCreateExecutable

EC <		call	AssertIsResEditDocument				>
EC <		cmp	es:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG	>
EC <		ERROR_NE  BAD_DOCUMENT_HANDLES_STRUCT			>
EC <		push	ax						>
EC <		mov	ax, ds						>
EC <		call	ECCheckSegment					>
EC <		mov	ax, es						>
EC <		call	ECCheckSegment					>
EC <		pop	ax						>

	; Save document handle and current directory.

		push	ds:[LMBH_handle], si
		call	FilePushDir

	; Open the source geode file.

		push	bp
		lea	bp, ss:[cef].CEF_TFF 	
		mov	ax, MSG_RESEDIT_DOCUMENT_OPEN_SOURCE_GEODE
		call	ObjCallInstanceNoLock
		pop	bp
		jc	error

	; Should geode go to a temporary directory?

		cmp	ss:[cef].CEF_TFF.TFF_destType, CED_SP_WASTE_BASKET
		LONG je	changeToSPWastebasket

	; Change to the top-level destination path

		mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_DESTINATION_PATH
		call	ObjCallInstanceNoLock	

createFile:

	; Lock the TransMapHeader

		pushf
		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		popf
		push	ds:[LMBH_handle], si
		movdw	dsdi, cxdx
		jc	errorCreate	; Error in hanging to path

	; Create the new file in this path, with a DOS name

		lea	dx, ds:[di].TMH_dosName	;ds:dx <- DOS name
if DBCS_PCGEOS
EC <		tst	{word}ds:[di].TMH_dosName		>
else
EC <		tst	{byte}ds:[di].TMH_dosName		>
endif
EC <		ERROR_Z	NO_FILE_NAME				>
		mov	ah, (mask FCF_NATIVE_WITH_EXT_ATTRS or \
				FILE_CREATE_TRUNCATE shl offset FCF_MODE)
		mov	al, FILE_DENY_RW or FILE_ACCESS_W
		clr	cx
		call	FileCreate		; ^hax <- new file
		mov	bx, ax
		jc	errorCreate

	; Close the file for CopyExtAttrs.

		clr	al
		call	FileClose
		jc	errorCreate

	; Copy the extended attributes from the original to the new file.
	
		mov	bx, es:[DHS_geode]	; ^hbx <- original geode, 
		call	FileCopyExtAttributes	; ds:dx <- new file name
		jc	errorCreate

	; Reopen the destination file and store its handle in document.
	
		mov	al, FILE_DENY_RW or FILE_ACCESS_W
		call	FileOpen
		mov	dx, ax			; ^hdx <- new geode
		jc	errorCreate
		mov	ss:[cef].CEF_newGeode, dx

	; Unlock TransMapHeader.

		call	DBUnlock_DS
		pop	bx, si
		call	MemDerefDS		; (preserves flags)

	; Change the user notes in the new file.
	
		call	ChangeNameAndUserNotes

	; Change the copyright info in the new file.

		call	ChangeCopyrightInfo

		mov	ax, EV_NO_ERROR
		clc
error:	
		call	FilePopDir		; (preserves flags)
		pop	bx, si
		call	MemDerefDS		; (preserves flags)

		.leave
		ret

errorCreate:

	; Put up error message.

		push	bp
		mov	dx, ds
		lea	bp, ds:[di].TMH_sourceName
		mov	cx, EV_FILE_CREATE
		call	DocumentDisplayMessage
		pop	bp

	; Unlock the TransMapHeader.

		call	DBUnlock_DS

	; Restore the document.

		pop	bx, si
		call	MemDerefDS		; (preserves flags)
		mov	ax, EV_NO_ERROR
		stc
		jmp	error

changeToSPWastebasket:
		mov	ax, SP_WASTE_BASKET
		call	FileSetStandardPath
		jmp	createFile

OpenBuildFiles		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeNameAndUserNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the longname and user notes in the newly created
		file.

CALLED BY:	OpenBuildFiles

PASS:		ds:si	- document
		^hdx	- new geode

RETURN:		carry set if error
			ax - ErrorValue

DESTROYED:	ax,bx,cx,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeNameAndUserNotes		proc	near
		uses	si, dx
		.enter inherit REDCreateExecutable

EC <		call	AssertIsResEditDocument				>
EC <		xchg	bx, dx						>
EC <		call	ECCheckFileHandle				>
EC <		xchg	dx, bx						>

	; Get the TransMapHeader.

		push	si
		mov	bx, dx			; Geode handle.
		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		movdw	essi, cxdx

	; Set the user notes.

		lea	di, es:[si].TMH_userNotes	; es:di <- user notes
		mov	ax, FEA_USER_NOTES
		mov	cx, GFH_USER_NOTES_BUFFER_SIZE
		call	FileSetHandleExtAttributes
		mov	ax, EV_SET_USER_NOTES
		jc	done

	; Determine which filename we will use.

		lea	di, es:[si].TMH_destName	; es:di <- long name
		cmp	ss:[cef].CEF_TFF.TFF_nameType, CEN_TRANSLATED_NAME
		je	setName				; Use TMH_destName.
		lea	di, es:[si].TMH_sourceName	; es:di <- long name.
setName:

	; Set the file long-name.

		mov	ax, FEA_NAME
		mov	cx, FILE_LONGNAME_BUFFER_SIZE
		call	FileSetHandleExtAttributes
		mov	ax, EV_SET_LONGNAME

done:
		pop	si
		call	DBUnlock

		.leave
		Destroy	ax,bx,cx,di
		ret
ChangeNameAndUserNotes		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeCopyrightInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Change the Copyright/Screen saver module info for the new
		file.		

CALLED BY:	OpenBuildFiles

PASS:		ds:si	- document
		^hdx	- new geode

RETURN:		carry set if error
			ax - ErrorValue

DESTROYED:	ax,bx,cx,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	12/12/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeCopyrightInfo		proc	near
	uses	si, dx
	.enter inherit REDCreateExecutable
EC <	call	AssertIsResEditDocument				>
EC <	xchg	bx, dx						>
EC <	call	ECCheckFileHandle				>
EC <	xchg	dx, bx						>

	call	GetFileHandle			; bx <- DB file handle

	; Get the TransMapHeader.
	push	dx
	mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
	call	ObjCallInstanceNoLock
	movdw	essi, cxdx
	pop	dx				; dx <- geode handle

	; Dereference the copyright info.
	push	es	
	mov	ax, es:[si].TMH_copyrightGroup
	mov	di, es:[si].TMH_copyrightItem
	tst	di
	jz	unlockTransMap
	call	DBLock				; es:*di <- pointer to DB item
	mov	di, es:[di]			; es:di <- copyright info

	; Set the copyright info
	mov	bx, dx				; bx <- geode handle
	mov	ax, FEA_NOTICE
	mov	cx, GFH_NOTICE_SIZE
	call	FileSetHandleExtAttributes

	; Unlock Copyright DBItem
	call	DBUnlock

unlockTransMap:
	; Unlock TransMapHeader
	pop	es
	call	DBUnlock
	.leave
	ret
ChangeCopyrightInfo		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteNewGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The build failed.  Delete the new geode file, if one
		was created.

CALLED BY:	REDCreateExecutable
PASS:		on stack - CEF
		ds:si	- document
RETURN:		nothing
DESTROYED:	bx,dx,di,ds,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteNewGeode		proc	near
		uses	ax
		.enter 	inherit REDCreateExecutable

		call	FilePushDir

		clr	bx
 		xchg	bx, ss:[cef].CEF_newGeode
		tst	bx
		jz	done
		mov	al, FILE_NO_ERRORS
		call	FileClose

	; Go to destination path.

		mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_DESTINATION_PATH
		call	ObjCallInstanceNoLock
		jc	done

	; Lock the TransMapHeader.

		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		movdw	esdi, cxdx

	; Delete the file.

		lea	dx, es:[di].TMH_destName
		call	FileDelete

	; Unlock the TransMapHeader

		call	DBUnlock

done:
		call	FilePopDir

		.leave
		Destroy bx,dx,di
		ret

DeleteNewGeode		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseBuildFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The CreateExecutable function is done, so close the
		files now.

CALLED BY:	CreateExecutable

PASS:		on stack - CEF
		*ds:si	- document

RETURN:		ax - ErrorValue

DESTROYED:	ax, bx, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseBuildFiles		proc	near
	.enter inherit REDCreateExecutable

EC <	call	AssertIsResEditDocument				>

	mov	bx, ss:[cef].CEF_relocTable
	tst	bx
	jz	noRelocTable
	call	MemFree

noRelocTable:
	mov	bx, ss:[cef].CEF_resourceTable
	tst	bx
	jz	noResourceTable
	call	MemFree

noResourceTable:

	; Close the source file and free the geode tables.
	; If there is no source file, there will not be any tables
	; or destination file, since the build code aborts if there
	; is an error when the source file is opened.
	;
	push	bp
	lea	bp, ss:[cef].CEF_TFF
	call	CloseGeodeAndFreeTables
	pop	bp

 	mov	bx, ss:[cef].CEF_newGeode
	tst	bx
	jz	noFile
	mov	al, FILE_NO_ERRORS
	call	FileClose
noFile:	
	mov	ax, EV_NO_ERROR
	.leave
	ret
CloseBuildFiles		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                UpdateRelocationTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Fixup the relocations for this resource, which may have
                moved and/or changed in size.

CALLED BY:      WriteRelocationTable

PASS:           ^hbx    - new resource block
                cx      - size of relocation table
		es:0	- DocumentHandlesStruct
		ss:[si] - CreateExecutableFrame

RETURN:         ax - EV_NO_ERROR if Relocation Table was successfully
			updated.

DESTROYED:      ax,dx,si,di,ds

PSEUDO CODE/STRATEGY:
	If this is an LMem resource which has a non-trivial relocation table:
		Make a copy of the original resource
		Find the chunk which contains the relocation offset
		Update the GRE_offset with the new value

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        cassie  12/ 2/92        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateRelocationTable           proc    near

newRes          local   hptr    push    bx
origRes         local   hptr	
origReloc       local   hptr    

        uses    bx,cx,es,bp
        .enter 

	clr	ss:[origRes]
	clr	ss:[origReloc]
	segmov	ds, es, ax
EC<	cmp	ds:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG		>
EC<	ERROR_NE  BAD_DOCUMENT_HANDLES_STRUCT				>

        ; If it is not an LMem block, it couldn't have been edited, so
        ; nothing in the relocation table should have changed.
	; If it is read only, as for resources in motif which contain
	; VisMoniker lists, it may have relocation entries which need
	; to be updated.
	;
        mov     dx, ss:[si].CEF_TFF.TFF_numResources
	mov	ax, ss:[si].CEF_resNumber
	mov	bx, ds:[DHS_resourceTable]	;^hbx <- resource table
	call	GetResourceFlags		; ax <- HAF and HF flags
        test    al, mask HF_LMEM
	clc
        LONG	jz      noRelocation

	; It appears that the preference modules all have a strings 
	; resource with a moniker list that is not marked read-only.
	; This resource is not read-only, but it does have a relocation
	; table.  So we will relocate regardless of whether it is 
	; read-only or not.
	;
;        test    ah, mask HAF_READ_ONLY
;        LONG	jz    	noRelocation

	; if there is only one entry, it is a null entry and we are
	; done????
	;
	cmp	cx, size GeodeRelocationEntry
	LONG	je	noRelocation

        ; load a copy of the original resource
	;
        push    cx
        mov     ax, ss:[si].CEF_resNumber
	mov	bx, ds:[DHS_geode]
	mov	cx, ds:[DHS_resourceTable]
        call    ResEditLoadResourceLow                 ;^hbx <- resource block
        mov     ss:[origRes], bx
        pop     cx                              ; cx <- size of table
        jnc	checkNoHandles

loadResourceErr::
EC <    cmp     ax, LRE_NO_HANDLES                              >
EC <    ERROR_E UNEXPECTED_LOAD_RESOURCE_ERROR                  >
EC <    cmp     ax, LRE_NOT_LMEM                                >
EC <    ERROR_E UNEXPECTED_LOAD_RESOURCE_ERROR                  >
        mov     ax, EV_LOAD_RESOURCE
        jmp     freeTheResource

	; If the lmem heap has LMF_NO_HANDLES set, then none of the
	; relocations could have changed (these types of lmem blocks
	; cannot be localized by resedit).  Don't try to do fixups because
	; FindRelocationHandle doesn't deal with the lack of a handle
	; table.
	;		-- dubois 12/2/94
checkNoHandles:
	call	ObjLockObjBlock			; use instead of MemLock to
;;;	call	MemLock				; ...avoid EC warning  -Don
	mov	ds, ax				; ds <- original resource
	mov	ax, ds:[LMBH_flags]
	call	MemUnlock
	test	ax, mask LMF_NO_HANDLES
	jz	hasRelocations
	mov	ax, EV_NO_ERROR
	jmp	noError

	; There was an error loading resource.  Do the right thing.
	;
hasRelocations:
        ; lock the relocation table for the resource
	;
        mov     bx, ss:[si].CEF_relocTable
        call    MemLock
        mov     ds, ax
        clr     si                              ;ds:si <- Relocation table

	; Allocate a block to hold a copy of the relocation table.
	; (Pass HAF_NO_ERR, since this block will most likely be very 
	; small, less than 100k).
	;
	push	cx				;save actual table size
	mov	ax, cx
	mov	cx, ALLOC_STATIC_NO_ERR_LOCK
	call	MemAlloc
	mov	ss:[origReloc], bx
	mov	es, ax
	clr	di				;es:di <- buffer for copy
	pop	cx

        ; Copy the relocation table, so it can be used to
	; find the offsets in the original resource.
	;
	rep	movsb
	
        ; calculate the number of entries
	;
	mov	ax, di				;ax <- actual table size
	clr	dx
        mov     cx, size GeodeRelocationEntry
        div     cx                              ;ax <- # of entries
EC<	tst	dx					>
EC<	ERROR_NZ	RESEDIT_INTERNAL_LOGIC_ERROR	>

        mov     cx, ax				;cx <- counter
        mov     bx, ss:[origRes]		;^hbx <- original resource
        mov     dx, ss:[newRes]			;^hdx <- edited resource
	clr	si				;es:si <- first GRE
	push	bp

relocate:
	; Pass: es:si - GeodeRelocationEntry to find in original
	;	^hbx - copy of original resource
	;	
        call    FindRelocationHandle            ;^ldi <- chunk handle
                                                ;bp <- offset within chunk
	jc	error
	tst	bp				;if bp = 0, relocation
	jz	getNext				;  offset did not change

	; Pass: ds:si - GeodeRelocationEntry to be updated
	;	^hdx - updated resource
	;	^ldi - chunk containing the offset
	; 	bp - relative offset within that chunk
	;
        call    FixRelocationOffset      

getNext:
        add     si, size GeodeRelocationEntry
        loop    relocate
	clc

error:
	pop	bp
	mov	ax, EV_NO_ERROR
	jnc	noError
	mov	ax, EV_RELOCATION_NOT_FOUND

noError:
	; Now free the blocks allocated above.
	;
        mov     bx, ss:[origReloc]
        tst     bx
        jz      freeTheResource
        call    MemFree

freeTheResource:
        mov     bx, ss:[origRes]
        tst     bx
        jz      done
        call    MemFree

done:
        .leave
        ret

noRelocation:
	mov	ax, EV_NO_ERROR
	jmp	done

UpdateRelocationTable           endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                FindRelocationHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Find the chunk in the original, unedited resource
		which contains the offset in this GeodeRelocationEntry.

CALLED BY:      (INTERNAL) UpdateRelocationTable

PASS:           es:si   - GeodeRelocationEntry
                ^hbx    - original resource block
                ^hdx    - new resource block

RETURN:		carry set if chunk containing relocation was not found 
		carry clear if relocation was found
                ^ldi - chunk handle containing this relocation
	         bp = relative offset of the relocation within the chunk
		    = 0 if relocation did not change becuase its offset
		      is before the handle table, and therefore was not
		      affected by any changes to chunks in the resource.

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
	Lock the original resource.  
	Look through the handle table for the last entry whose value
		is greater than the relocation offset.

	The Translation libraries use DefTransLib macro to create a
	FormatStrings resource, which contains the following structure.

	Only the strings are actual chunks.  The optrs have relocation
	entries, but their offset is before the first chunk handle, so
	do not change as a result of editing changes to the chunks.

ImpexFormatGeodeInfo		struct
	IFGI_headerString	nptr.char	; name of format
	IFGI_fileSpecString	nptr.char	; file specification for format
	IFGI_importUI		optr		; OD of UI to display on import
	IFGI_exportUI		optr		; OD of UI to display on export
	IFGI_formatInfo		ImpexFormatInfo
ImpexFormatGeodeInfo		ends

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        cassie  12/ 2/92        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindRelocationHandle            proc    near
        uses    bx,dx,si,ds
        .enter

        ; lock the copy of the original resource 
        ;
	push	bx
	call	ObjLockObjBlock			; use instead of MemLock to
;;;	call	MemLock				; ...avoid EC warning  -Don
	mov	ds, ax

	; calculate the size of the handle table
	;
        mov     di, ds:[LMBH_offset]		;ds:di <- first entry
        mov     dx, ds:[LMBH_nHandles]		;dx <- number of handles

EC <	test	ds:[LMBH_flags], mask LMF_NO_HANDLES			>
EC <	ERROR_NZ RESEDIT_INTERNAL_LOGIC_ERROR				>

        shl     dx, 1                           ;dx <- size of handle table
        add     dx, di                          ;dx < ptr after last entry

        mov     bp, es:[si].GRE_offset		;bp <- relocation offset
	tst	bp
	jz	notFound

	cmp	bp, di				;is offset before 1st chunk?
	jb	notFound

tryHandle:
     	cmp     di, dx                          ;handle must be within table
	cmc				;want jae (ie jnc) done, but should
	jc	done			;return with carry set so we cmc

        ; check if the chunk is free (ptr = 0) or 0 size (ptr = -1)
        ;
        mov     bx, ds:[di]                     ;bx <- offset of chunk
        inc     bx				
        jz      tryNext				;is it a free chunk?
        dec     bx
        jz      tryNext				;is it an empty chunk?

        ; if relocation offset is in this chunk, bp >= bx...
	;
        cmp     bp, bx				;is offset before this chunk?
        jb      tryNext				;yes, try the next one

	; and bp < ax, where ax = byte after end of chunk
	;
        ChunkSizePtr    ds, bx, ax         	
        add     ax, bx                 		;ax <- offset of end of chunk
        cmp     bp, ax				;is it after this chunk? 
        jae     tryNext				;yes, try the next one

        ; it's in this chunk, find its relative offset within the chunk
	; (as opposed to within the resource)
	;
        sub     bp, bx                          ;bp <- relative offset in chunk
        jmp     gotIt

tryNext:
        add     di, size word                   ;go to next handle
        jmp     tryHandle

gotIt:
	clc
done:
	pop	bx
	call	MemUnlock

        .leave
        ret

notFound:
	clr	bp
	jmp	gotIt

FindRelocationHandle            endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                FixRelocationOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Fix the relocation offsets that have been invalidated
                by moving or resizing the LMem block when it was updated.

CALLED BY:      UpdateRelocationTable

PASS:           ds:si   - GeodeRelocationEntry
                ^hdx    - updated resource 
                ^ldi    - chunk containing this relocation
                bp      - relative offset of relocation within this chunk

RETURN:         new relocation offset stored in ds:[si].GRE_offset
DESTROYED:      ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        cassie  12/ 3/92        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixRelocationOffset             proc    near
	uses	bx,es
	.enter

        mov     bx, dx
        call    MemDerefES		; *es:di <- offset of chunk 
					;   containing the relocation
        add     bp, es:[di]             ; bp <- new relocation offset
	mov	ds:[si].GRE_offset, bp	; save the new offset

	.leave
        ret
FixRelocationOffset             endp

;---------------

;DocBuild_ObjMessage_call	proc near
;	push	di
;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
;	call	ObjMessage
;	pop	di
;	ret
;DocBuild_ObjMessage_call	endp

DocumentBuildCode	ends

