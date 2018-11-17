COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta	
MODULE:		Fax
FILE:		group3UI.asm

AUTHOR:		Andy Chiu, Oct 10, 1993

ROUTINES:
	Name			Description
	----			-----------

Methods:
  	FaxInfoVisOpen		Sets up the fax printer driver UI.

	FaxInfoVisClose		Makes sure file that contains info for the
				UI is closed.

	FaxInfoGetFileHandle	Returns the file handle of the fax information
				file.

	FaxInfoGetFileHandle	Returns the file handle of the fax information
				file.

	FaxInfoGetQuickListHandles
				Returns the mem and chunk handle to the
				quick numbers list.

	FaxInfoGetAddressBookUsed
				Gets the information about which address
				book is used

	FaxInfoSetAddressBookUsed
				Set the address book info that is being used.

	FaxInfoSaveSenderInfo	Save all the sender information fields.
	
	FaxInfoResetSenderInfo	Reset all the sender information fields.

	FaxInfoUseCoverPage	Automatically select "Use Cover Page" option.

Functions:
	OpenFaxInfomationFile
				Opens the file that contains the quick dial
				entries plust the coversheet information.

	GetFaxInformationFile
				Gets all the info from the fax information file.

	Group3GetSenderInfo 	Update UI objects with sender information.


	SetupInitialData	Calls the setup routines for the quick number
				lists, address book info, and dial assist info.

	FileInit		Makes sure the the right extended attributes
				is set to the fax information file.

	Group3GetDialAssistInfo
				Gets the dial assist info from the ini file
				and puts them in the appropiate UI file.

	Group3GetAddrBookInfo	Get the address book information from the
				fax info file.

	InitializeQuickNumbersList
				Makes sure that the quick numbers list knows
				how many elements it has and put the first 
				number of the quick numbers list in the 
				number text.

	Group3OptionsTriggerToggleEnabled
				Toggles the enabled status of the trigger
				when it receives this message.

        FaxCallSpoolPrintControl
			       	Send a method to the SpoolPrintControl
				object above me in the generic tree


;
; Procedures when we're shutting down the print driver
;

	UpdateQuickNumbers	Makes sure the quick list is updated if any
				items should be added.

	CheckIfNameOrNumberInQuickList
				Checks if the name or number in the number
				or name  text object is in the quick number
				list.

	AddNameOrNumberToQuickList
				Adds the number or name/number to the quick
				list depending on what the caller wants.

	AddElementToQuickList	Makes a new element in the quick list so we can
				add new information to the quick list.
				Will also delete old elements.

	MakeChunkFromText	This procedure gets the text from a text
				object and and copies it to a chunk that
				this procedure creates.


	Group3WriteDialAssistInfo
				Takes the dial assist info and writes it
				to the ini file.

	SwitchItemsInQuickList	Switch the first element and the element 
				the user chose in the QuickNumberList in 
				the Chunk Array of phone numbers

	DeleteElementInChunkArray
				For a chosen element, it deletes the
				entry and the chunks that the element points to.

	UpdateAddrBookInfo	Updates the fax information file so it know's
				the address book that the user wants to use

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/10/93   	Initial revision


DESCRIPTION:
	Code for the ui objects that first appear in the Print Dialog box
		

	$Id: group3UI.asm,v 1.1 97/04/18 11:53:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Before the fax dialog is sent, we set up some information
		in the UI so the user can obtain Quick number information
		and cover page information.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= FaxInfoClass object
		ds:di	= FaxInfoClass instance data
		ds:bx	= FaxInfoClass object (same as *ds:si)
		es 	= segment of FaxInfoClass
		ax	= message #
		bp	- 0 if top window, else window for object to open on
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxInfoVisOpen	method dynamic FaxInfoClass, 
					MSG_VIS_OPEN
	;
	; Call the super class
	;
		mov	di, offset FaxInfoClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].FaxInfo_offset	; ds:di <- instance data

	;
 	; Make sure the VM file is open so we can get the data we need.
openFile:		
		call	OpenFaxInformationFile	; bx <- file handle
		jc	handleOpenFileError

		call	VMGrabExclusive
		mov	ds:[di].FII_fileHandle, bx
	;
	; Go to the file and get all the info from the fax file
	;
		call	GetFaxInformationFile
		jc	deleteFileAndReleaseExclusive
	;
	; dx:bp <- handle to quick list (block and chunk)
	; cx <- # of items in list
	; dx:bp handles for chunk array
	;
		mov	di, ds:[si]
		add	di, ds:[di].FaxInfo_offset	; ds:di <- inst data
		mov	ds:[di].FII_qHeapHandle, dx
		mov	ds:[di].FII_qListHandle, bp
	;
	; Setup the quick list numbers, dial assist info, and address book info
	; parameters are:
	; cx = number of items in the quick list
	; bx = file handle of fax information file
	; *ds:si = FaxInfo class
	; ds = segment of UI
	;
		call	SetupInitialData
	;
	; Release the semaphore on the file
	;
		call	VMReleaseExclusive

exit:
	;
	; Because of something weird with GeoCalc, we have to renable these
	; buttons because they were disabled in FaxEvalMainUI.
	;
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

		ret

	;
	;	----------------------------
	;	E R R O R    H A N D L E R S
	;	----------------------------
	;

	;
	; This examines the error code in al from OpenFaxInformationFile
handleOpenFileError:
		cmp	al, FIFEC_FILE_CANNOT_BE_CREATED
		jz	cannotOpenFile

	; sanity checking.  Only other error is FIFEC_FILE_MUST_BE_DELETED
EC <		cmp	al, FIFEC_FILE_MUST_BE_DELETED			>
EC <		ERROR_NZ FAX_INFO_FILE_ERROR_CODE_INVALID		>
		jmp	deleteFile
		

	;
	; Else these are the handlers to delete the file and try to open
	; the file again.
deleteFileAndReleaseExclusive:
		call	VMReleaseExclusive
deleteFile:
	;
	; Destroy the file and tell whoever is calling that the file needs
	; to be recreated.
	;
		push	ds			; save segment of UI

		call	FilePushDir
		call	PutThreadInFaxDir
		segmov	ds, cs			; ds:dx <- file name
		mov	dx, offset faxInformationFileName
		call	FileDelete		; carry set if error

		pop	ds
		pushf
		call	FilePopDir
		popf
		jc	cannotOpenFile

		jmp	openFile
	;
	; If we couldn't delete the file we will then just have to deal
	; with it like the file couildn't be created.
cannotOpenFile:
		
		mov	di, ds:[si]
		add	di, ds:[di].FaxInfo_offset	; ds:di <- inst data
		clr	bx, 				; make null file handle

		mov	ds:[di].FII_qHeapHandle, bx	; clear out the qlist 
		mov	ds:[di].FII_qListHandle, bx	; handles

		mov	cx, GROUP3_MIN_QUICK_DIAL_NUMBERS
		call	SetupInitialData
		
		jmp	exit

FaxInfoVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenFaxInformationFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens the information needed by the user to fill out the
		cover page and quick dial numbers.

CALLED BY:	FaxInfoVisOpen
PASS:		es	= dgroup
RETURN:		bx	= VM file handle
		carry set if file is invalid
		al	= error code returned.

DESTROYED:	ah
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenFaxInformationFile	proc	near
		uses	cx,dx,bp,si,di,ds,es
		.enter

EC <		call	ECCheckDGroupES					>
	;
	; Set the current directory to the fax directroy which is at
	; SP_PRIVATE_DATA/FaxDir
	;
		call	PutThreadInFaxDir
		LONG	jc	pathError
	;
	; Open the file.
	; 
		mov	ax, (VMO_CREATE shl 8 ) or \
			mask VMAF_FORCE_READ_WRITE or \
			mask VMAF_FORCE_SHARED_MULTIPLE
		clr	cx			; default compression
		mov	dx, offset faxInformationFileName
		segmov	ds, cs			; ds:dx <- file name
		call	VMOpen			; bx <- filehandle
		LONG	jc	openError
		
	;
	; Check to see if the file existed.  If it did, then we have no
	; problem.  If it didn't then we must create the format.
	;
		cmp	ax, VM_CREATE_OK
		LONG 	jnz	checkAttributes
	;
	; Make sure extended attributes are set correctly
	;
		call	VMGrabExclusive
		mov	cx, cs
		mov	dx, offset faxDefaultsToken
		call	FileInit
	;
	; Create the block that will become the map block and contain all
	; the initialized data that we will need.
	;
		mov	cx, size FaxInformationFileInfo	; size of block
		call	VMAlloc				; ax <- VM block handle
EC <		call	ECVMCheckVMBlockHandle				>
		call	VMSetMapBlock
		mov_tr	dx, ax				; dx <- VM block handle
		mov	di, bx				; save file handle 
	;
	; Create an Lmem heap for the chunk array
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx			; default block header size
		call	VMAllocLMem		; ax <- block handle
		push	ax			; save heap handle
	;
	; Make the chunk array for the phone numbers.
	;
		call	VMLock			; ax <- segment
						; bp <- mem handle
		mov	bx, size QuickNumberChunkHandles
		mov	ds, ax			; block for the new array
		clr	cx			; default header size
		clr	al
		clr	si
		call	ChunkArrayCreate	; *ds:si <- array

		call	VMDirty
		call	VMUnlock
	;
	; Save that block handle into the map block so we can find the
	; heap later.  Also clear out all the other fields.
	;
		mov	ax, dx			; ax <- map block
		mov	bx, di			; bx <- file handle
EC <		call	ECVMCheckVMBlockHandle				>
		call	VMLock			; ax <- segment of vm block
						; bp <- mem handle
		mov	ds, ax
		pop	ds:[FIFI_heapBlock]	; <- heap handle
		mov	ds:[FIFI_chunkArrayHandle], si
		clr	al
		mov	{byte} ds:[FIFI_fromName], al
		mov	{byte} ds:[FIFI_fromCompany], al
		mov	{byte} ds:[FIFI_fromVoicePhone], al
		mov	{byte} ds:[FIFI_fromFaxPhone], al
		mov	{byte} ds:[FIFI_fromFaxID], al
	;
	; Write the default address book that should be used.
	;
		segmov	es, ds

if _USE_PALM_ADDR_BOOK
		mov	di, FIFI_addrBookFileInfo
		call	CopyDefaultAddressBookFileInfo
endif
		
if 0
		
		mov	cx, FIFI_addrBookFileInfo	
		mov	di, cx
		add	di, ABFI_name			; es:di <- dest
		segmov	ds, cs
		mov	si, offset addressBookFileName
		LocalCopyString

		mov	di, cx
		add	di, ABFI_path
		mov	si, offset addressBookPath
		LocalCopyString

		mov	di, cx
		mov	cl, ADDRESS_BOOK_DISK_HANDLES
		mov	{byte} es:[di].ABFI_diskHandle, cl
endif
		
	;
	; Unlock the this map block
	;
		call	VMDirty
		call	VMUnlock
		call	VMReleaseExclusive
exitClear::
		clc
done:
		.leave
		ret

checkAttributes:
		mov	cx, size ProtocolNumber
		sub	sp, cx
		mov	di, sp
		segmov	es, ss
		mov	ax, FEA_PROTOCOL
		call	FileGetHandleExtAttributes	; es:di <- filled

		cmp	es:[di].PN_major, FILE_MAJOR_PROTOCOL
		jne	short	protocolError
		cmp	es:[di].PN_minor, FILE_MINOR_PROTOCOL
		jne	short	protocolError

	;
	;	----------------------------
	;	E R R O R    H A N D L E R S
	;	----------------------------
	;

	;
	; This is a clean exit when the file is already made and the protocol
	; checks out OK
noError::
		add	sp, cx			; restore stack
		clc
		jmp	done

	;
	; This error occurs when the protocols don't check out.
	; Close the file and let the calling routine handle it.
protocolError:
		add	sp, cx			; restore stack
		mov	al, FILE_NO_ERRORS
		call	VMClose
		mov	al, FIFEC_FILE_MUST_BE_DELETED
		stc
		jmp	done

	;
	; This error occurs when the thread can't go to nor make the fax
	; directory
pathError:
		mov	si, offset CannotGoToFaxDir
		mov	ax, \
			CustomDialogBoxFlags <1,CDT_ERROR,GIT_NOTIFICATION,0>
		call	DoDialog

		mov	al, FIFEC_FILE_CANNOT_BE_CREATED
		stc		
		jmp	done

	;
	; This error occurs when the fax information file was not able
	; to be found nor made.
openError:
		mov	si, offset CannotOpenFaxInfoFile
		mov	ax, \
			CustomDialogBoxFlags <1,CDT_ERROR,GIT_NOTIFICATION,0>
		call	DoDialog

		mov	al, FIFEC_FILE_CANNOT_BE_CREATED
		stc
		jmp	done
		
OpenFaxInformationFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure extended attributes are set correctly to 
		the fax file.

CALLED BY:	OpenFaxInformationFile
PASS:		bx - file handle
		cx:dx = GeodeToken
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 8/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
fProtocol       ProtocolNumber < FILE_MAJOR_PROTOCOL, 
                                 FILE_MINOR_PROTOCOL >

fFlags          GeosFileHeaderFlags mask GFHF_SHARED_MULTIPLE

FileInit        proc    near
	        uses    ax, cx, di, es
	        .enter

	        sub     sp, 3 * size FileExtAttrDesc
        	mov     di, sp
        	segmov  es, ss
        	mov     es:[di][0*FileExtAttrDesc].FEAD_attr, FEA_TOKEN
     	   	mov     es:[di][0*FileExtAttrDesc].FEAD_value.segment, cx
        	mov     es:[di][0*FileExtAttrDesc].FEAD_value.offset, dx
        	mov     es:[di][0*FileExtAttrDesc].FEAD_size, size GeodeToken

		mov     es:[di][1*FileExtAttrDesc].FEAD_attr, FEA_PROTOCOL
        	mov     es:[di][1*FileExtAttrDesc].FEAD_value.segment, cs
        	mov     es:[di][1*FileExtAttrDesc].FEAD_value.offset, offset fProtocol
        	mov     es:[di][1*FileExtAttrDesc].FEAD_size, size fProtocol

        	mov     es:[di][2*FileExtAttrDesc].FEAD_attr, FEA_FLAGS
        	mov     es:[di][2*FileExtAttrDesc].FEAD_value.segment, cs
        	mov     es:[di][2*FileExtAttrDesc].FEAD_value.offset, offset fFlags
        	mov     es:[di][2*FileExtAttrDesc].FEAD_size, size fFlags

        	mov     ax, FEA_MULTIPLE
        	mov     cx, 3
        	call    FileSetHandleExtAttributes
        	add     sp, 3 * size FileExtAttrDesc


		call	VMUpdate

	; Since there's no reason for the user to know if the update didn't go
	; through, we are not going to handle any error that comes up.

		
       .leave
        ret
FileInit        endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFaxInformationFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets all the info from the fax information file.

CALLED BY:	FaxInfoVisOpen
PASS:		bx	= file handle
		ds	= segment for UI
RETURN:		dx:bp	= handle to chunk array
		cx	= number of items in the chunk array
		carry set if error

DESTROYED:	nothing

SIDE EFFECTS:
	Will release semaphore on file if the file has been corrupted.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFaxInformationFile	proc	near
	uses	ax,bx,si,di,es
	.enter
	;
	; Get the map block so we can initialize our data
	;
		call	VMGetMapBlock			; ax <- map block handle
	;
	; Check to see if the file has been corrupted and there is no 
	; longer a map block.  We will return an error to the calling routine.
	;
		tst	ax
		LONG	jz	error
	;
	; Lock the block and fill information into the text objects that are
	; needed.
	;
		call	VMLock				; ax <- segment
							; bp <- mem handle
	;
	; Fill in the text objects with the sender information.
	;
		mov	es, ax				; es = map block segment
		call	Group3GetSenderInfo
	;
	; Remember the local memory heap and and chunk array handles
	;
		mov	ax, es:[FIFI_heapBlock]
		mov	si, es:[FIFI_chunkArrayHandle]

		call	VMUnlock

	;
	; We're going to copy the info into memory because more than one
	; dialog might need to make a change to it.
	;
	; Get *ds:si to be pointing to the chunk array so we can use the
	; chunk array routines.
	;
EC <		call	ECVMCheckVMBlockHandle				>
		call	VMLock			; ax <- segment
						; bp <- mem handle
		push	ds			; save seg of ui
		mov	ds, ax			; *ds:si <- chunk array
	;
	; Find out the size of the LMemBlock.  Allocate a new block
	; and copy it to the new block.  No error will be handled here
	; because if it the system can't handle this allocation, they are
	; screwed anyway.
	;
		push	si

		mov	dx, ds:[LMBH_blockSize]	; size of copied block
		mov	ax, dx
		mov	cl, mask HF_SHARABLE or mask HF_SWAPABLE
		mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
		call	MemAlloc		; bx - handle of block allocate
						; ax - address of block
		mov	es, ax
		clr	di
		clr	si
		mov	cx, dx			; cx <- size of block
		rep	movsb

		pop	si

		call	MemUnlock		; unlock the allocated block
		; bx is still the mem handle of the block
	;
	; Tell the quick numbers list how many items there should be
	;
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayGetCount	; cx <- number of elements
		tst	cx
		jnz	unlockBlock
		inc	cx				; make sure at least
							; 1 item is in the list
unlockBlock:
	;
	; Unlock the block that has the chunk array
	;
		call	VMDirty
		call	VMUnlock
	;
	; dx:bp should be returned as handles for the chunk array.
	;
		pop	ds			; ds <- segment of UI
		mov	dx, bx
		mov	bp, si

		clc

exit:
	.leave
	ret

		
	;
	;	----------------------------
	;	E R R O R    H A N D L E R S
	;	----------------------------
	;

	;
	; The information was not extractable from the file.
error:
		
		stc
		jmp	exit

GetFaxInformationFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3GetSenderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the sender information from the VM file and place
		them into the text objects.  Updates FromGlyph.

CALLED BY:	FaxInfoResetSenderInfo
		GetFaxInformationFile

PASS:		es	= segment of locked map block
		bp	= memory handle
		bx	= file handle of VM file

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOTE:	Caller is responsible for locking block before
			calling this routine and unlocking block after 
			this routine returns.
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/ 8/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3GetSenderInfo	proc	near
		uses	ax,bx,cx,dx,si,bp
		.enter
	;
	; Filling in the text of the text objects.  For some reason
	; dx and bp get trashed, so es needs to be preserved.
	;
		mov	bx, 2 * (length FileInformationOffsets - 1)
						; bx = offset into data
	;
	; Now write the information from the VM file to the text objects.
	;
fillInTextObjectsLoop:
		mov	dx, es			; dx = seg of map block
		mov	bp, cs:FileInformationOffsets[bx]	
		mov	si, cs:UIInformationObjChunks[bx]	
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock

		dec	bx
		dec	bx
		jns	fillInTextObjectsLoop
	;
	; Make sure the sender moniker is updated.  Go back into the info file
	; and use the info of what the sender's name is.
	;
		mov	dx, es
		mov	bp, FIFI_fromName
		clr	cx
		mov	si, offset CoverPageFromSummaryText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	si, offset CoverPageFromSummaryText
		call	ObjCallInstanceNoLock

		mov	ax, MSG_VIS_TEXT_SELECT_START
		call	ObjCallInstanceNoLock

		.leave
		ret
Group3GetSenderInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupInitialData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the setup routines for the quick number lists,
		address book info, and dial assist info.

CALLED BY:	FaxInfoVisOpen
PASS:		bx	= file handle of fax information file
		(bx = 0) if no file opened.
		cx 	= number of items in the quick list.
		ds	= segment of UI
		*ds:si	= FaxInfoClass
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupInitialData	proc	near
		uses	di
		.enter	

	;
	; Initialize the quick list
	;
		call	InitializeQuickNumbersList
	;
	; Get the billing card information from the ini file.
	;
		call	Group3GetDialAssistInfo
	;
	; Get the address book information.
	;
		mov	di, ds:[si]
		add	di, ds:[di].FaxInfo_offset
		call	Group3GetAddrBookInfo

		.leave
		ret
SetupInitialData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3GetDialAssistInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the dial assist info from the ini file and puts them
		in the appropiate UI file.

CALLED BY:	FaxInfoVisOpen
		DialAssistResetFields

PASS:		ds	= segment of UI
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Group3GetDialAssistInfo	proc	near

tempBuf		local	FAX_MAX_FIELD_LENGTH	dup (char)

	uses	ax,bx,cx,dx,si,di,es
	.enter

		push	bp
	;
	; Setup registers for the loop below.  These are the registers
	; that shouldn't change or need to be initialized.
	;
		segmov	es, ss
		lea	di, ss:tempBuf			; es:di <- buf to fill

		mov	bx, 2 * (length FileInitKeyOffsets - 1)
grabAndEnterTextLoop:
		push	bx				; save counter
		push	ds				; save segment of UI

		mov	{byte} es:[di], 0		; make it a null string
	;
	; Fill the buffer.
	;
		mov	cx, cs
		mov	dx, cs:FileInitKeyOffsets[bx]	; cx:dx <- keys

		mov	ds, cx
		mov	si, offset fileInitFaxCategory	; ds:si <- category
		mov	bp, FAX_MAX_FIELD_LENGTH
		call	InitFileReadString		; cx <- # of bytes
							; es:di <- filled
		jnc	putTextInTextObject
		mov	{byte} es:[di], 0			; clr buffer
	;
	; Put it in the text object.
	;
putTextInTextObject:
		pop	ds				; ds <- seg of UI
		pop	bx				; bx <- counter
		mov	dx, es
		mov	bp, di				; dx:bp <- buffer
		mov	si, cs:DialAssistTextOffsets[bx]
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock
	;
	; See if we're done with the loop
	;
		dec	bx
		dec	bx
		jns	grabAndEnterTextLoop

		pop	bp

	.leave
	ret
Group3GetDialAssistInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3GetAddrBookInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the address book information from the fax info file.

CALLED BY:	FaxInfoVisOpen
PASS:		ds:di	= Instance data
		bx	= file handle to fax info
		if bx is 0 then it means a file could not be opened.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/29/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3GetAddrBookInfo	proc	near
		class 	FaxInfoClass
		uses	ax,cx,si,di,bp,ds,es
		.enter

	;
	; See if we were able to open the fax information file.
	; if we weren't then, we will just use the defaults to make the
	; as a temporary value for the address book.
	;
		tst	bx
		jnz	getFileInfo
	;
	; es:di will point to the Instance Data of the fax info class
	; write the address book info
	;
		lea	di, ds:[di].FII_addrInfo
		segmov	es, ds
if _USE_PALM_ADDR_BOOK
		call	CopyDefaultAddressBookFileInfo
endif
		
		jmp	exit
		
	;
	; Get the map block so we can get information pertaining to
	; the addr book
	;
getFileInfo:
		call	VMGetMapBlock		; ax <- map block
		call	VMLock			; bp <- mem handle
						; ax <- segment
		lea	di, ds:[di].FII_addrInfo
		segmov	es, ds			; es:di <- dest
		mov	ds, ax
		mov	si, FIFI_addrBookFileInfo	; ds:si <- src

if _USE_PALM_ADDR_BOOK
		call	CopyAddressBookFileInfo
endif
		
		call	VMUnlock		
exit:
		.leave
		ret
Group3GetAddrBookInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeQuickNumbersList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure that the quick numbers list knows how many 
		elements it has and put the first number of the quick
		numbers list in the number text.

CALLED BY:	Group3GetFaxInformationFile
PASS:		ds	= segment of UI
		cx	= number of items in the chunk array
RETURN:		nothing	
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeQuickNumbersList	proc	near

		uses	ax, cx, dx, si, bp
		.enter
	;
	; Tell the list how many items it should have
	;
		mov	si, offset Group3UI:Group3QuickNumbersList
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallInstanceNoLock
	;
	; Make the first element of the quick numbers list selected and
	;
		clr	dx
		clr	cx			; select first number
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
	;
	; Have the text written in the number text box
	;
		mov	ax, MSG_QUICK_NUMBERS_LIST_SET_CURRENT_SELECTION
		clr	cx
		call	ObjCallInstanceNoLock

		.leave
		ret
InitializeQuickNumbersList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoSetNumPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of the number of pages in the fax

CALLED BY:	FaxInfoInitializeData

PASS:		*ds:si - FaxInfoClass object
		ds:di  - instance data

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/02/91		Initial version
	don	5/02/91		Change to request page information
	ac	1/15/94		Added to Fax Project

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoSetNumPages	proc	near
	class	FaxInfoClass
npagesString	local	11 dup(char)

	uses	ax, cx, dx, es
	.enter

	; Get the number of pages
	;
	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_SELECTED_PAGE_RANGE
	call	FaxCallSpoolPrintControl
	pop	bp
		
	sub	dx, cx
	inc	dx				; number of pages => DX

	mov	ds:[di].FII_numPages, dx

	
	; Now convert it to ascii for placing in the CovertSheetPages display
	;
	mov_tr	ax, dx
	inc	ax				; Plus one for the cover sheet
	clr	dx
	mov	cx, mask UHTAF_NULL_TERMINATE
	segmov	es, ss
	lea	di, ss:[npagesString]
	call	UtilHex32ToAscii

	; Put it in the object....
	;
	push	bp				; save for locals

	push	si				; save FaxInfo handle

	mov	dx, ss
	mov	bp, di
	clr	cx				; null-terminated
	mov	si, offset CoverPageNumPages
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock

	pop	si				; restore FaxInfoHandle
		
	pop	bp				; restore for locals

	;
	; Instance data may have moved, so I will make sure it's been
	; fixed up.
	;
		mov	di, ds:[si]
		add	di, ds:[di].FaxInfo_offset
		
	.leave
	ret
FaxInfoSetNumPages	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gives us a chance to close the file.

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= FaxInfoClass object
		ds:di	= FaxInfoClass instance data
		ds:bx	= FaxInfoClass object (same as *ds:si)
		es 	= segment of FaxInfoClass
		ax	= message #
		bp	- 0 if top window, else window for object to open on
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoVisClose	method dynamic FaxInfoClass, 
					MSG_VIS_CLOSE

	;
	; Make sure the superclass is called
	;
		mov	di, offset FaxInfoClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].FaxInfo_offset	; ds:di <- instance data
	;
	; Find out how many pages are in the fax not including
	; the cover page.
	;
		call	FaxInfoSetNumPages

	;
	; Free the local copy of the quick number list that we have.
	; The handle is Zero, it means that we never had a copy of the
	; heap handle.
	;
		clr	bx
		xchg	bx, ds:[di].FII_qHeapHandle
		tst	bx
		jz	closeFile
		
		call	MemFree
	;
	; Save information back into the VM file. First get the map 
	; block and lock it down.
	;
closeFile:
		clr	bx
		xchg	bx, ds:[di].FII_fileHandle	; save file handle
	;
	; If the file handle is Zero, it means that we are unable to open
	; the file and that we proceeded as if nothing happened.
	; So skip the part where it's updating the fax information file.
	;
		tst	bx
		jz	closeAddressBook
		
		call	VMGrabExclusive
		
EC <		call	ECCheckFileHandle				>
		call	VMGetMapBlock		; ax <- map block handle
		call	VMLock			; ax <- segment
						; bp <- memory handle
	;
	; Remember all the new file info for the address book
	;
		call	UpdateAddrBookInfo

		mov	es, ax
		mov	cx, es:[FIFI_chunkArrayHandle]
		mov	dx, es:[FIFI_heapBlock]
	;
	; Unlock the map block.
	;
		call	VMDirty
		call	VMUnlock
	;
	; Update the quick number list and close the file.
	;
EC <		call	ECCheckFileHandle				>
		call	UpdateQuickNumbers

		mov	al, FILE_NO_ERRORS
		call	VMReleaseExclusive
		call	VMClose
	;
	; Make sure the address book is closed if we used it.
	;
closeAddressBook:
if _USE_PALM_ADDR_BOOK
		mov	si, offset AddrBookList
		mov	ax, MSG_ADDRESS_BOOK_LIST_CLOSE_BOOK
		call	ObjCallInstanceNoLock
endif
		ret
FaxInfoVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3WriteDialAssistInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes the dial assist info and writes it to the ini file.

CALLED BY:	DialAssistSaveFields
PASS:		ds	= segment of UI
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3WriteDialAssistInfo	proc	near

tempBuf		local	FAX_MAX_FIELD_LENGTH	dup (char)

	uses	ax,bx,cx,dx,si,di
	.enter
		push	bp

		lea	di, ss:tempBuf		

		mov	bx, 2 * (length FileInitKeyOffsets - 1)
		segmov	es, ss
writeINILoop:
		push	ds				; save segment of UI
		mov	dx, ss
		mov	bp, di	
		mov	si, cs:DialAssistTextOffsets[bx]
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock

		mov	di, bp				; es:di <- string

		mov	cx, cs
		mov	dx, cs:FileInitKeyOffsets[bx]	; cx:dx <- key
		
		mov	ds, cx
		mov	si, offset fileInitFaxCategory	; ds:si <- category

		call	InitFileWriteString

		pop	ds				; ds <- segment of UI
		dec	bx
		dec	bx
		jns	writeINILoop


		pop	bp

		call	InitFileSave
	.leave
	ret
Group3WriteDialAssistInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateQuickNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the quick list is updated if any
		items should be added.

CALLED BY:	FaxInfoVisClose
PASS:		ds	= segment of UI
		bx	= file handle
		cx	= chunk array handle
		dx	= heap handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/30/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateQuickNumbers	proc	near
	uses	ax, bx, cx, dx, bp, si
	.enter

		push	cx, dx			; optr to chunk array

if _USE_PALM_ADDR_BOOK
	;
	; Check to see if an address book entry was used.
	;
		mov	si, offset AddrBookList
		mov	ax, MSG_ADDRESS_BOOK_LIST_IS_ADDRESS_BOOK_USED
		call	ObjCallInstanceNoLock
		jc	short	checkIfAddressInQuickSelection
endif
	;
	; Check to see if the text in the number field matches any of the
	; numbers in the quick numbers list
	;
checkIfInList:
		clr	ax				; just check number
		call	CheckIfNameOrNumberInQuickList	; ax <- element number
		jnc	addNumber
switchItems::
	;
	; If the excution comes through here, then that means that 
	; the number chosen was not the first one, so we have to switch
	; the order of the quick number lists
	;
		mov_tr	cx, ax			; cx <- element to choose
		pop	si, ax
EC <		call	ECVMCheckVMBlockHandle				>
		call	SwitchItemsInQuickList

exit:
		.leave
		ret

checkIfAddressInQuickSelection:		
	;
	; Check to see if it's name has changed and it's an address book entry
	; if so, then we add the number.
	;
		push	cx, dx
		mov	si, offset Group3NameText
		mov	ax, MSG_GEN_TEXT_IS_MODIFIED
		call	ObjCallInstanceNoLock
		pop	cx, dx
		jc	checkIfInList

		push	cx, dx
		mov	si, offset Group3NumberText
		mov	ax, MSG_GEN_TEXT_IS_MODIFIED
		call	ObjCallInstanceNoLock
		pop	cx, dx
		jc	checkIfInList

		mov	ax, si				; make si non zero
		call	CheckIfNameOrNumberInQuickList	; ax <- item found
		jc	switchItems

addNameAndNumber::
	;
	; Add the new number as a name and number in the list
	; Because we have determined it's an address book entry that should
	; be in the list.
	;
		pop	si, ax
		mov	cx, ax			; make cx non-zero
		call	AddNameOrNumberToQuickList
		jmp	exit

addNumber:
	;
	; Add the number to the list.
	;
		pop	si, ax			; optr to chunk array
		clr	cx			; add number only
		call	AddNameOrNumberToQuickList
		jmp	exit

		
UpdateQuickNumbers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfNameOrNumberInQuickList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the name or number in the number or name  text object
		is in the quick number list.

CALLED BY:	UpdateQuickNumbers
PASS:		ds	= segment of UI
		bx 	= file handle
		cx	= chunk array handle
		dx	= VM block heap handle
		ax	= 0 if just number to check
			= non-zero if name and number to check
RETURN:		carry set if in the quick list
		ax	= element number if is in the list
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfNameOrNumberInQuickList	proc	near
	; handle of heap that quick list is in
blockHan			local	hptr	push	dx
	; chunk handle of the chunk array
chunkHan		local	nptr	push	cx
	; flag to tell how the user wants to use this function
userFlag		local	word	push	ax
	; temp buffer to hold the number string
tempNameBuf		local	FAX_MAX_FIELD_LENGTH	dup (char)
tempNumberBuf		local	FAX_MAX_FIELD_LENGTH	dup (char)
		
		uses	bx,cx,dx,si,di,bp,es,ds
		.enter
	;
	; Check to see if we should know what is in the name field.
	;
		mov	di, bp				; di <- bp for locals
		tst	ax
		jz	getNumberText

		mov	dx, ss
		lea	bp, ss:[tempNameBuf]
		mov	si, offset Group3NameText
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock	; cx <- length of string
		mov	bp, di
	;
	; Get the number from the text object
	;
getNumberText:
		mov	dx, ss
		lea	bp, ss:[tempNumberBuf]
		mov	si, offset Group3NumberText
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock	; cx <- string length
	;
	; Lock down the chunk array from the file.
	;
		mov	bp, di
		mov	si, ss:[chunkHan]
		mov	ax, ss:[blockHan]
EC <		call	ECVMCheckVMBlockHandle				>
		call	VMLock		; bp <- mem handle
		push	bp		; save mem handle
		mov	ds, ax		; ds:si <- chunk array
	;
	; Check each number in the list.  Read the chunk array from the
	; file and check each entry.  
	;
		mov	bp, di
		segmov	es, ss
		clr	ax, cx		; ax <- counter
					; cx indicates null term.
		mov	bx, si		; save c-array handle in bx

		tst	ss:[userFlag]
		jz	checkNumberString
		
checkNameAndNumberStringLoop:
		call	ChunkArrayElementToPtr	; ds:di <- new element
		jc	stringNotFound
		tst	ds:[di].QNCH_nameChunk
		jz	short continueNameAndNumberLoop
		mov	si, ds:[di].QNCH_nameChunk
		mov	si, ds:[si]		; ds:si <- new string
		mov	dx, di
		lea	di, ss:[tempNameBuf]	; es:di <- name text
		call	LocalCmpStrings
		jnz	short continueNameAndNumberLoop

	; Name check was successful, check the number
		mov	di, dx
		mov	si, ds:[di].QNCH_numberChunk
		mov	si, ds:[si]
		lea	di, ss:[tempNumberBuf]	; es:di <- number text
		call	LocalCmpStrings
		jz	stringFound
		
continueNameAndNumberLoop:
		mov	si, bx
		inc	ax
		jmp	checkNameAndNumberStringLoop

checkNumberString:
		lea	dx, ss:[tempNumberBuf]
		
checkNumberStringLoop:
		call	ChunkArrayElementToPtr	; ds:di <- new element
		jc	stringNotFound
		tst	ds:[di].QNCH_nameChunk
		jnz	short continueNumberLoop
		mov	si, ds:[di].QNCH_numberChunk
		mov	si, ds:[si]		; ds:si <- new string
		mov	di, dx			; es:di <- number text
		call	LocalCmpStrings
		jz	stringFound
continueNumberLoop:		
		mov	si, bx
		inc	ax
		jmp	checkNumberStringLoop

exit:		
		.leave
		ret
stringFound:
		pop	bx			
		xchg	bp, bx			; bp <- mem handle
		call	VMUnlock
		xchg	bp, bx			; bp <- for local vars
		stc
		jmp	exit
stringNotFound:
		pop	bx		
		xchg	bp, bx			; bp <- mem handle
		call	VMUnlock
		xchg	bp, bx			; bp <- for local vars
		clc
		jmp	exit
		
CheckIfNameOrNumberInQuickList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNameOrNumberToQuickList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds in a number or name/number to the quick list depending
		on what the caller wants.
CALLED BY:	INTERNAL
PASS:		ds	= segment of UI
		ax	= heap handle of chunk array
		si	= handle to chunk array
		cx	= zero if just number wanted.
			  non-zero if name and number wanted.
RETURN:		Element is added
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddNameOrNumberToQuickList	proc	near
	uses	ax,bx,si,di,bp,es
	.enter

	;
	; Lock the block for the chunk array.
	;
		call	VMLock
		mov	es, ax			; *ds:si <- chunk array
		mov	di, si
	;
	; Check if we need to add the name
	;
		jcxz	getNumber
	;
	; Get the name and add it into the list
	;
		mov	si, offset Group3NameText	
		call	MakeChunkFromText	; si <- new chunk
		mov	cx, si			; cx <- new chunk
getNumber:
	;
	; Get the number and add it to the list
	;
		mov	si, offset Group3NumberText
		call	MakeChunkFromText	; si <- new chunk
	;
	; Make sure space in the chunk array is made for the element
	;
		push	ds
		segmov	ds, es
		mov	bx, si			; bx <- new number chunk
		mov	si, di			; *ds:si <- chunk array
		call	AddElementToQuickList	; ds:di <- new element
		mov	ds:[di].QNCH_nameChunk, cx
		mov	ds:[di].QNCH_numberChunk, bx
		pop	ds
	;
	; Unlock the block for the chunk array
	;
		call	VMDirty
		call	VMUnlock
		
	.leave
	ret
AddNameOrNumberToQuickList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddElementToQuickList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a new element in the quick list so we can
		add new information to the quick list.  Will also delete
		old elements.

CALLED BY:	INTERNAL
PASS:		ds	= segment of Heap
		bx	= VM file handle
		si	= chunk handle to chunk array
RETURN:		ds:di 	= new element
DESTROYED:	nothing
SIDE EFFECTS:	Will also delete an old number if there are ten numbers
		in the list.  ds may have changed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddElementToQuickList	proc	near
	uses	ax,cx
	.enter

	;
	; Get the count of elements in the chunk array.  If it's Zero, we need
	; to do an append.  If it's greater than our max, then we need
	; to also discard the last element.
	;
EC <		call	ECCheckChunkArray				>
		call	ChunkArrayGetCount		; cx <- number of elements
		jcxz	appendElement
	;
	; Test to see if we have to many elements.  If so, we'll delete the
	; last one.
	;
		mov	ax, GROUP3_MAX_QUICK_DIAL_NUMBERS
		cmp	cx, ax
		jl	short	getBeginingElement
	;
	; Delete 10th element.
	;	
		dec	ax
		call	ChunkArrayElementToPtr		; ds:di <- new element
		call	DeleteElementInChunkArray

getBeginingElement:
	;
	; Otherwise add it to the chunk array.
	;
		clr	ax				; get first element
		call	ChunkArrayElementToPtr		; ds:di <- first element
		call	ChunkArrayInsertAt		; ds:di <- new element

exit:
		.leave
		ret					; ds:di <- new element

appendElement:
	;	
	; This is the first element in the list, so we have to append it.
	;
		call	ChunkArrayAppend		; ds:di <- new element
		jmp	exit

AddElementToQuickList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeChunkFromText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure gets the text from a text object and
		and copies it to a chunk that this procedure creates.

CALLED BY:	INTERNAL
PASS:		ds	= segment of UI
		es	= Lmem heap to create chunk in
		si	= offset to Text object wanted
RETURN:		si	= chunk handle of the copied text
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeChunkFromText	proc	near
	uses	ax,bx,cx,dx,bp
		.enter

	;
	; Find out how large the text is, so we know how big of
	; a chunk to allocate
	;
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock		; dx:ax <- text length
	;
	; Create the chunk that we need.
	;
		mov	bx, ds			; save segment of UI

		segmov	ds, es
		inc	ax			; include null
		mov_tr	cx, ax
		clr	al			; no object flags
		call	LMemAlloc		; ax <- Handle of chunk
						; ds may of changed
		push	ax
	;
	; Copy the text from the text object into the the chunk
	;
		mov_tr	bp, ax
		mov	bp, ds:[bp]
		mov	dx, ds			; dx:bp <- location to copy to
		mov	ds, bx			; *ds:si <- text object
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock
	;
	; return the chunk handle for this proocedure
	;
		pop	si
		mov	es, dx
		
	.leave
	ret
MakeChunkFromText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwitchItemsInQuickList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch the first element and the element the user chose
		in the QuickNumberList in the Chunk Array of phone numbers

CALLED BY:	FaxInfoVisOpen
PASS:		cx	= element chose
		si	= handle to the chunk array
		ax	= handle to block of chunk array
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/12/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwitchItemsInQuickList	proc	near
		uses	ax,bx,cx,di,ds
		.enter

		jcxz	exit			; do nothing if first element
	;
	; Lock down block of the chunk array
	;
		call	VMLock			; ax <- segment
						; bp <- mem handle
		mov	ds, ax			; *ds:si <- chunk array

	;
	; Get the chosen element in the chunk array
	;
		mov_tr	ax, cx			; ax <- chosen element
		call	ChunkArrayElementToPtr	; ds:di <- chosen element
EC <		ERROR_C	-1						>
		pushdw	ds:[di]			; save the value
	;
	; Delete that element in the chunk array
	;
		call	ChunkArrayDelete
	;
	; Get the first element in the chunk array and insert 
	; at that point
	;
		clr	ax
		call	ChunkArrayElementToPtr	; ds:di <- first element
		call	ChunkArrayInsertAt	; ds:di <- new element
		
	;
	; Read in the new value for the first element
	;
		popdw	ds:[di]
	;
	; Unlock the block
	;
		call	VMDirty
		call	VMUnlock

exit:
		.leave
		ret
SwitchItemsInQuickList	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteElementInChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For a chosen element, it deletes the entry and the
		chunks that the element points to.

CALLED BY:	INTERNAL
PASS:		*ds:si	= chunk array
		ds:di	= element
RETURN:		ds:di 	= points to the same element (if it still exists)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteElementInChunkArray	proc	near
	uses	ax
	.enter
		

	;
	; Find out what chunks the element is pointing to and free up
	; those chunks
	;
		mov	ax, ds:[di].QNCH_nameChunk
		tst	ax
		jz	freeNumber

		call	LMemFree

freeNumber:
		mov	ax, ds:[di].QNCH_numberChunk
EC <		tst	ax						>
EC <		ERROR_Z	-1						>

		call	LMemFree
		
	;
	; Delete the element in the chunk array
	;
		call	ChunkArrayDelete

		
	.leave
	ret
DeleteElementInChunkArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateAddrBookInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the fax information file so it know's the
		address book that the user wants to use

CALLED BY:	FaxInfoClose
PASS:		bx	= file handle of fax information file
		ds:di 	= instance data of FaxInfo
		ax	= segment of where to write data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/27/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateAddrBookInfo	proc	near
		class FaxInfoClass
		uses	si,di,es
		.enter

	;
	; Get the place to write the fax information
	;

		lea	si, ds:[di].FII_addrInfo	; ds:si <- src
		mov	es, ax
		mov	di, FIFI_addrBookFileInfo	; es:di <- dest.
if _USE_PALM_ADDR_BOOK
		call	CopyAddressBookFileInfo
endif
		.leave
		ret
		
UpdateAddrBookInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoGetFileHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the file handle of the fax information file.

CALLED BY:	MSG_FAX_INFO_GET_FILE_HANDLE
PASS:		*ds:si	= FaxInfoClass object
		ds:di	= FaxInfoClass instance data
		ds:bx	= FaxInfoClass object (same as *ds:si)
		es 	= segment of FaxInfoClass
		ax	= message #
RETURN:		ax	= file handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoGetFileHandle	method dynamic FaxInfoClass, 
					MSG_FAX_INFO_GET_FILE_HANDLE

		mov	ax, ds:[di].FII_fileHandle

		ret
FaxInfoGetFileHandle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoGetQuickListHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the mem and chunk handle to the quick numbers list.

CALLED BY:	MSG_FAX_INFO_GET_QUICK_LIST_HANDLES
PASS:		*ds:si	= FaxInfoClass object
		ds:di	= FaxInfoClass instance data
		ds:bx	= FaxInfoClass object (same as *ds:si)
		es 	= segment of FaxInfoClass
		ax	= message #
RETURN:		ax	= block handle
		cx	= chunk handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoGetQuickListHandles	method dynamic FaxInfoClass, 
					MSG_FAX_INFO_GET_QUICK_LIST_HANDLES
		mov	ax, ds:[di].FII_qHeapHandle
		mov	cx, ds:[di].FII_qListHandle

		ret
FaxInfoGetQuickListHandles	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoGetAddressBookUsed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the information about which address book is used

CALLED BY:	MSG_FAX_INFO_GET_ADDRESS_BOOK_USED
PASS:		*ds:si	= FaxInfoClass object
		ds:di	= FaxInfoClass instance data
		ds:bx	= FaxInfoClass object (same as *ds:si)
		es 	= segment of FaxInfoClass
		ax	= message #
		cx:dx	= fptr to AddressBookFileInfo struc
RETURN:		cx:dx	= filled
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoGetAddressBookUsed	method dynamic FaxInfoClass, 
					MSG_FAX_INFO_GET_ADDRESS_BOOK_USED
		uses	ax, cx, dx, bp
		.enter
	;
	; Return the information into the stucture.
	;
		lea	si, ds:[di].FII_addrInfo	; ds:si <- data to copy
		mov	es, cx
		mov	di, dx		; ds:di <- structure to fill
if _USE_PALM_ADDR_BOOK
		call	CopyAddressBookFileInfo
endif
		.leave
		ret
FaxInfoGetAddressBookUsed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoSetAddressBookUsed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the address book info that is being used.

CALLED BY:	MSG_FAX_INFO_SET_ADDRESS_BOOK_USED
PASS:		*ds:si	= FaxInfoClass object
		ds:di	= FaxInfoClass instance data
		ds:bx	= FaxInfoClass object (same as *ds:si)
		es 	= segment of FaxInfoClass
		ax	= message #
		cx:dx	= AddressBookFileInfo struc
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoSetAddressBookUsed	method dynamic FaxInfoClass, 
					MSG_FAX_INFO_SET_ADDRESS_BOOK_USED
		uses	ax, cx
		.enter
	;
	; Copy the info in cx:dx into our instance data
	;
		add	di, FII_addrInfo
		segmov	es, ds			; es:di <- where to write data

		mov	ds, cx
		mov	si, dx			; ds:si <- new file info
		mov 	cx, size AddressBookFileInfo
		rep	movsb
		
		.leave
		ret
FaxInfoSetAddressBookUsed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoResetSenderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset all the sender information fields.

CALLED BY:	MSG_FAX_INFO_RESET_SENDER_INFO

PASS:		*ds:si	= FaxInfoClass object
		ds:di	= FaxInfoClass instance data
		es 	= segment of FaxInfoClass

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Use the information copied out of the Fax Information File
		to restore the fields of the text objects in the sender
		information dialog.  (This does not include the receiver
		name.)  Basically copied from GetFaxInformationFile.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoResetSenderInfo	method dynamic FaxInfoClass, 
					MSG_FAX_INFO_RESET_SENDER_INFO
	;
	; Get the coversheet information out of the VM file.
	; 
		mov	bx, ds:[di].FII_fileHandle
		tst	bx
		jz	exit
		
		call	VMGrabExclusive

EC <		call	ECCheckFileHandle				>

		call	VMGetMapBlock		; ax = map block handle
		tst	ax
		jz	done			; error, bail...

		call	VMLock			; ax = segment
						; bp = memory handle
	;
	; Get the cover page information and place them in the text objects.
	;
		mov	es, ax			; es = segment of map block
		call	Group3GetSenderInfo
		call	VMUnlock
done:
EC <		call	ECCheckFileHandle			>

		call	VMReleaseExclusive
exit:
		ret
FaxInfoResetSenderInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoSaveSenderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the new sender information to the VM file.

CALLED BY:	MSG_FAX_INFO_SAVE_SENDER_INFO
PASS:		*ds:si	= FaxInfoClass object
		ds:di	= FaxInfoClass instance data
		es 	= segment of FaxInfoClass

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoSaveSenderInfo	method dynamic FaxInfoClass, 
					MSG_FAX_INFO_SAVE_SENDER_INFO
	;
	; Save all the sender information back into the VM file, if there
	; one exists.
	;
 		mov	bx, ds:[di].FII_fileHandle	
		tst	bx
		jz	exit				; bail if no file

		call	VMGrabExclusive

EC <		call	ECCheckFileHandle			>
			
		call	VMGetMapBlock			; ax = map block handle
		tst	ax
		jz	releaseExclusive
		
		call	VMLock				; ax = segment
							; bp = memory handle
		push	bx				; save file handle
		push	bp				; save mem handle
	;
	; Now write the information from the text objects to the VM map
	; block.
	;
		mov_tr	dx, ax				; dx = map block segment
		mov	bx, 2 * (length FileInformationOffsets - 1)
							; bx = offset into data
extractTextObjectsLoop:
		mov	bp, cs:FileInformationOffsets[bx]
		mov	si, cs:UIInformationObjChunks[bx]
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock

		dec	bx
		dec	bx
		jns	extractTextObjectsLoop

		pop	bp				; bp = mem handle
		call	VMDirty
		call	VMUnlock
		
		pop	bx
releaseExclusive:
EC <		call	ECCheckFileHandle				>

		call	VMReleaseExclusive			
exit:
		ret
FaxInfoSaveSenderInfo	endm


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxInfoUseCoverPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Automatically select to use cover page.

CALLED BY:	MSG_FAX_INFO_USE_COVER_PAGE

PASS:		*ds:si	= FaxInfoClass object
		ds:di	= FaxInfoClass instance data
		es 	= segment of FaxInfoClass

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxInfoUseCoverPage	method dynamic FaxInfoClass, 
					MSG_FAX_INFO_USE_COVER_PAGE
		
		mov	si, offset Group3CoverPageItemGroup
		mov	cx, PO_COVER_PAGE
		clr	dx			; not indeterminate
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		GOTO	ObjCallInstanceNoLock

FaxInfoUseCoverPage	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                FaxCallSpoolPrintControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Send a method to the SpoolPrintControl object above me in
                the generic tree

CALLED BY:      INTERNAL
        
PASS:           DS:*SI  = FaxInfoClass object
                AX      = Method to send
                CX      }
                DX      = Data to send with method
                BP      }

RETURN:         AX, CX, DX, BP

DESTROYED:      Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Don     4/27/91         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxCallSpoolPrintControl        proc    near
        uses    bx, si, di
        .enter

        ; Find the SpoolPrintControlClass object
        ;
        push    ax, cx, dx, bp
        mov     ax, MSG_GEN_GUP_FIND_OBJECT_OF_CLASS
        mov     cx, segment PrintControlClass
        mov     dx, offset PrintControlClass
        call    ObjCallInstanceNoLock           ; ^lcx:dx = SPC
EC <    ERROR_NC        -1			             >

        ; Now pass the method on to the SpoolPrintControl object
        ;
        mov     bx, cx
        mov     si, dx
        pop     ax, cx, dx, bp
        mov     di, mask MF_CALL or mask MF_FIXUP_DS
        call    ObjMessage

        .leave
        ret
FaxCallSpoolPrintControl        endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3OptionsTriggerToggleEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggles the enabled status of the trigger when it receives
		this message

CALLED BY:	MSG_GROUP3_OPTIONS_TRIGGER_TOGGLE_ENABLED
PASS:		*ds:si	= Group3OptionsTriggerClass object
		ds:di	= Group3OptionsTriggerClass instance data
		ds:bx	= Group3OptionsTriggerClass object (same as *ds:si)
		es 	= segment of Group3OptionsTriggerClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GroupOptionsTriggerToggleEnabled	method dynamic Group3OptionsTriggerClass, 
					MSG_GROUP3_OPTIONS_TRIGGER_TOGGLE_ENABLED
		uses	ax, cx, dx, bp
		.enter
	;
	; Look in the instance data to see if it is enabled
	;
		test	ds:[di].GI_states, mask GS_ENABLED
		jnz	disableTrigger
	;
	; Enable the trigger
	;
		mov	ax, MSG_GEN_SET_ENABLED
	jmp	short	sendMessage
disableTrigger:
	;
	; Disable the trigger
	;
		mov	ax,  MSG_GEN_SET_NOT_ENABLED

sendMessage:
	;
	; Send the appropiate message to the trigger
	;
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

		.leave
		ret
GroupOptionsTriggerToggleEnabled	endm










