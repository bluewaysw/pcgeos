COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ResEdit
FILE:		mainBatch.asm

AUTHOR:		Paul Canavese, Jun 15, 1995

ROUTINES:
	Name			Description
	----			-----------
	REARunBatchJob		Run a batch job. 
	InitiateBatchStatusDialog	Initiate the dialog that will report 
				the status of the batch job as it occurs. 
	REAProcessBatchFile	Process the batch command for the file 
				indicated in the passed frame. 
	BatchReport		Append a string to the batch report dialog. 
	BatchReportNumber	Write the passed number to the batch status 
				dialog. 
	BatchReportReturn	Write a return to the batch status dialog. 
	BatchReportTab		Write a tab to the batch status dialog. 
	BatchReportSetValue	Set one of the value indicators in the status 
				dialog. 
	BatchReportIncrementValue	Increment one of the value indicators 
				in the status dialog. 
	BatchReportError	Report an error in the status dialog. 
	BatchReportDocumentOpen	Report in the status box that the document has 
				been opened. 
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	6/15/95   	Initial revision


DESCRIPTION:
	
	Routines for batch processing.		

	$Id: mainBatch.asm,v 1.1 97/04/04 17:13:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include fileEnum.def
include system.def


MainProcessCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REARunBatchJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run a batch job.

CALLED BY:	MSG_RESEDIT_RUN_BATCH_JOB
PASS:		*ds:si	= ResEditApplicationClass object
		ds:di	= ResEditApplicationClass instance data
		ds:bx	= ResEditApplicationClass object (same as *ds:si)
		es 	= segment of ResEditApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	6/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
translationFileToken GeodeToken < "TRNS", MANUFACTURER_ID_GEOWORKS >

REARunBatchJob	method dynamic ResEditProcessClass, 
					MSG_RESEDIT_RUN_BATCH_JOB
		uses	cx, dx, ds
fileEnumMatchAttrsEnd	local   FileExtAttrDesc
fileEnumMatchAttrs	local   FileExtAttrDesc
fileEnumParams		local   FileEnumParams
		.enter

	; Turn on batch processing mode.

		mov	al, BM_ON		
		call	SetBatchMode

	; check for autorun batch mode?


	; Initiate the status dialog.

		call	InitiateBatchStatusDialog
	
	; Allocate BatchProcessStruct.

		mov	ax, size BatchProcessStruct
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		mov	es, ax
		mov	es:[BPS_handle], bx

	; Set DocumentCommonParam fields.

		mov	{word} es:[BPS_docParams].DCP_docAttrs, 0
		mov	{word} es:[BPS_docParams].DCP_flags, 0
		mov	{word} es:[BPS_docParams].DCP_connection, 0

	; Determine message to send to document.

		push	bp
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchOptionList 
		mov	di, mask MF_CALL
		call	ObjMessage
			; ax = batch message
		mov	es:[BPS_batchMessage], ax

	; Get the path of the directory holding translation files to batch.


		; try autorun batch dir configuration first
		GetResourceHandleNS	StringsUI, bx
		call	MemLock
		mov	ds, ax
		mov	si, offset AutorunBatchKey	
		mov	dx, ds:[si]			; ds:si <- key string
		mov	cx, ds				; cx:dx <- key string
		mov	si, offset CategoryString	
		mov	si, ds:[si]			; ds:si <- category string

		mov	bp, size [BPS_docParams].DCP_path	
		lea	di, es:[BPS_docParams].DCP_path ; es:di - buffer to fill
		call	InitFileReadString		; ^hbx <- contains dest path
		
		pushf
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
		mov	cx, es
		lea	dx, es:[BPS_docParams].DCP_path
		mov	al, 'M' - 'A'			; Disk handle.
		call	DiskRegisterDiskSilently
		popf
		jnc	autorun

		mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
		lea	dx, es:[BPS_docParams].DCP_path
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchDirSelector 
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	bx, ax			; Disk handle.
autorun:
		pop	bp

	; Change to selected directory.

		push	ds
		call	FilePushDir
		mov	ds, cx
		call	FileSetCurrentPath
		mov	es:[BPS_docParams].DCP_diskHandle, bx
		pop	ds

	; Get all the translation files we want to batch through.

		clr	ax
		mov	ss:[fileEnumParams].FEP_searchFlags, \
				mask FESF_GEOS_NON_EXECS
		mov	ss:[fileEnumParams].FEP_returnAttrs.segment, ax
		mov	ss:[fileEnumParams].FEP_returnAttrs.offset, \
				FESRT_NAME
		mov	ss:[fileEnumParams].FEP_returnSize, \
				size FileLongName
		mov	ss:[fileEnumParams].FEP_matchAttrs.segment, ss
		lea	bx, ss:[fileEnumMatchAttrs]
		mov	ss:[fileEnumParams].FEP_matchAttrs.offset, bx
		mov	ss:[fileEnumParams].FEP_bufSize, \
				FE_BUFSIZE_UNLIMITED
		mov	ss:[fileEnumParams].FEP_skipCount, ax

		mov	ss:[fileEnumMatchAttrs].FEAD_attr, FEA_TOKEN
		mov     ss:[fileEnumMatchAttrs].FEAD_value.offset, \
				offset translationFileToken
		mov     ss:[fileEnumMatchAttrs].FEAD_value.segment, cs
		mov     ss:[fileEnumMatchAttrs].FEAD_size, size GeodeToken
		mov     ss:[fileEnumMatchAttrsEnd].FEAD_attr, FEA_END_OF_LIST

		push	ds, si
	        segmov  ds, ss, ax
	        lea     si, ss:[fileEnumParams]
		call	FileEnumPtr
		pop	ds, si
			; bx = list of matching files.
		jcxz	noFiles
		mov	es:[BPS_fileNameListHandle], bx
		mov	es:[BPS_countToProcess], cx

	; Indicate current and total files in the status dialog.

		push	si
		clr	dx
		mov	si, offset ResEditBatchCurrentFileNumber
		call	BatchReportSetValue
		mov	dx, cx
		mov	si, offset ResEditBatchTotalFileNumber
		call	BatchReportSetValue
		pop	si

	; Lock the list of files.

		call	MemLock
		mov	es:[BPS_nextFileName].segment, ax
		clr	es:[BPS_nextFileName].offset

	; Process the files.  The handler for MSG_RESEDIT_PROCESS_BATCH_FILE
	; send a message for the next file.  After the last file, the
	; handler will clean up.

		mov	cx, es
		mov	ax, MSG_RESEDIT_PROCESS_BATCH_FILE
		call	GeodeGetProcessHandle		; bx = process handle
		mov	di, mask MF_CALL
		call	ObjMessage

done:
		.leave
		ret

noFiles:

	; Free the BatchProcessStruct

		mov	bx, es:[BPS_handle]
		call	MemFree

	; Notify user that no translation files are in directory.

		mov	cx, EV_ERROR_NO_FILES_TO_BATCH
		call	DocumentDisplayMessage

	; Pull down the batch status dialog.

		push	bp
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	cx, IC_DISMISS
                GetResourceHandleNS     FileMenuUI, bx
                mov     si, offset ResEditBatchStatus
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp

	; Close the batch dialog.
		
		mov	ax, MSG_RESEDIT_APPLICATION_CANCEL_BATCH
                GetResourceHandleNS     AppResource, bx
                mov     si, offset ResEditApp
                mov     di, mask MF_FORCE_QUEUE
                call    ObjMessage

	; Turn off batch processing mode.

		mov	al, BM_OFF	
		call	SetBatchMode
		jmp	done

REARunBatchJob	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitiateBatchStatusDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate the dialog that will report the status of the batch
		job as it occurs.

CALLED BY:	REARunBatchJob
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	9/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitiateBatchStatusDialog	proc	near
		uses	ax,bx,cx,dx,bp,si,di
		.enter

	; Clear any status text from previous job.
		
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchStatusText
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

	; Disable "OK" trigger.  We will enable it once the job is
	; completed.

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchOKTrigger
		mov	di, mask MF_CALL
		call	ObjMessage

	; Enable "Cancel" trigger.

		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchCancelTrigger
		call	ObjMessage

	; Put up our status box.

		mov	ax, MSG_GEN_INTERACTION_INITIATE
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchStatus
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

	; Bring it to the top, even though it's still going to be behind the
	; New/Open dialog until it goes away.

		mov	ax, MSG_GEN_BRING_TO_TOP
		call	ObjMessage

	; Indicate the start of the batch job.

		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		mov	dx, bx
		mov	bp, offset ResEditBatchStartText
		call	ObjMessage
		call	BatchReport
		call	BatchReportReturn

		.leave
		ret
InitiateBatchStatusDialog	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REAProcessBatchFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the batch command for the file indicated in the
		passed frame.

CALLED BY:	MSG_RESEDIT_PROCESS_BATCH_FILE

PASS:		*ds	= dgroup of process
		ds:di	= ResEditProcessClass instance data
		ds:bx	= ResEditProcessClass object (same as *ds:si)
		es 	= segment of ResEditProcessClass
		ax	= message #
		cx	= BatchProcessStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REAProcessBatchFile	method dynamic ResEditProcessClass, 
					MSG_RESEDIT_PROCESS_BATCH_FILE
docParams	local	DocumentCommonParams
token		local	GeodeToken
		uses	ax, cx, dx, bp
		.enter

	; Copy longname into DocumentCommonParams.

		push	ds
		mov	es, cx
		lea	di, es:[BPS_docParams].DCP_name
		movdw	dssi, es:[BPS_nextFileName]
		mov	cx, size FileLongName
		rep	movsb
		pop	ds

	; Indicate the file number we're on in the status dialog.

		push	bp, si, di
		mov	si, offset ResEditBatchCurrentFileNumber
		call	BatchReportIncrementValue

	; Indicate the current file name in status dialog.

		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		GetResourceHandleNS	FileMenuUI, bx
		clr	cx
		movdw	dxbp, es:[BPS_nextFileName]	; Document name
		mov	si, offset ResEditBatchCurrentFileName
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp, si, di

	; Indicate document open in status dialog.

		movdw	cxdx, es:[BPS_nextFileName]
		call	BatchReportDocumentOpen

	; Aargh.  Copy the docParams to the stack.  This is zaniness so we
	; can force queue each file.

		push	ds
		segmov	ds, ss, di
		segxchg	ds, es
		lea	di, ss:[docParams]
		lea	si, ds:[BPS_docParams]
		mov	cx, size DocumentCommonParams
		rep	movsb
		segxchg	ds, es

	; Get the token characters.

		push	es
		lea	dx, ss:[docParams].DCP_name
		segmov	es, ss, di
		lea	di, ss:[token]
		mov	ax, FEA_TOKEN
		mov	cx, size GeodeToken
		call	FileGetPathExtAttributes
		pop	es
		pop	ds
		LONG jc	errorOpen

	; Check if the this is a ResEdit document.

		cmp	{word} ss:[token].GT_chars, "TR"
		LONG jne notTranslationFile
		cmp	{word} ss:[token].GT_chars+2, "NS"
		LONG jne notTranslationFile
		cmp	{word} ss:[token].GT_manufID, \
				MANUFACTURER_ID_GEOWORKS
		LONG jne notTranslationFile

	; Open the document.

		push	bp
		mov	ax, MSG_GEN_DOCUMENT_GROUP_OPEN_DOC
		mov	dx, size DocumentCommonParams
		GetResourceHandleNS	AppDocUI, bx
		mov	si, offset ResEditDocumentGroup 
		lea	bp, ss:[docParams]
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
			; cx:dx = new document object (0 if error)
		pop	bp
		LONG jc	errorOpen
		stc
		LONG jcxz errorOpen

documentOpen::					; Leave for swat verbose

	; If option is selected, automatically update the translation file.

		push	bp, cx, dx		; locals, Document optr
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchSaveBooleanGroup 
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp, bx, si		; locals, Document optr
		test	ax, mask BF_FORCE_UPDATE
		mov	ch, CEU_UPDATE_IF_NECESSARY
		jz	afterForcedUpdate

	; Do the update.

		push	bp, bx, si
		mov	ax, MSG_RESEDIT_DOCUMENT_UPDATE_TRANSLATION
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp, bx, si
		mov	ch, CEU_DO_NOT_ATTEMPT_UPDATE	; Don't update again.

afterForcedUpdate:

	; Set options for creating a plain executable (in case this is the
	; option).

		mov	cl, CET_TRANSLATED_GEODE
		mov	dl, CEN_TRANSLATED_NAME
		mov	dh, CED_DESTINATION_DIR

	; Send batch command to document.

		mov	ax, es:[BPS_batchMessage]
		mov	di, mask MF_CALL
		push	bx, si, bp		; Document optr, locals.
		call	ObjMessage

	; Update the document so the changes get written out to disk.

		push	bp
		mov	ax, MSG_GEN_DOCUMENT_UPDATE
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp

	; Check if we want to commit the changes, or just write them out as
	; uncommitted.

		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchSaveBooleanGroup 
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bx, si, bp		; Document optr, locals.
		test	ax, mask BF_SAVE_TRANSLATION_FILES
		jz	justUpdate

saveDocument::					; Leave for swat verbose.

	; Save the document.

		push	bp
		mov	ax, MSG_GEN_DOCUMENT_SAVE
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp

justUpdate:

	; Mark the document clean, so we don't get a dialog asking if we
	; want to save/discard changes, and so the changes aren't committed.

		mov	ax, MSG_RESEDIT_DOCUMENT_MARK_CLEAN
		mov	di, mask MF_CALL
		call	ObjMessage

	; Close the document.

		push	bp
		mov	ax, MSG_GEN_DOCUMENT_CLOSE
		clr	bp
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	bp

	; Are we the last file to process?

		dec	es:[BPS_countToProcess]
		jz	fileFreeList		; We were the last file.

nextFile:

	; Has the user cancelled the batch job?

		call	IsBatchModeCancelled
		jc	fileFreeList

	; Process next file.

		add	es:[BPS_nextFileName].offset, size FileLongName
		mov	cx, es
		mov	ax, MSG_RESEDIT_PROCESS_BATCH_FILE
		call	GeodeGetProcessHandle
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

done:
		.leave
		ret

errorOpen:

	; Report error in status dialog.

		mov	ax, offset ResEditBatchOpenTranslationError
		call	BatchReportError
		jmp	error		

notTranslationFile:

	; Report error in status dialog.

		mov	ax, offset ResEditBatchNotTranslationFileError
		call	BatchReportError

error:

	; Are we the last file to process?

		dec	es:[BPS_countToProcess]
		jnz	nextFile

fileFreeList:

	; Free the file name list.

		mov	bx, es:[BPS_fileNameListHandle]
		call	MemFree

	; Free the BatchProcessStruct

		mov	bx, es:[BPS_handle]
		call	MemFree

	; If batch mode has been cancelled by the user, turn off batch mode
	; and put up the New/Open dialog again.

		call	IsBatchModeCancelled
		jc	done

	; Enable "OK" trigger.

		push	bp
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchOKTrigger
		mov	di, mask MF_CALL
		call	ObjMessage

	; Disable "Cancel" trigger.

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchCancelTrigger
		call	ObjMessage

	; Indicate the end of the batch job.

		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		mov	dx, bx
		mov	bp, offset ResEditBatchEndText
		call	ObjMessage
		call	BatchReport
		call	BatchReportReturn
		pop	bp

	; force shutdown ensemble if in autorun batch
		mov	ax, SST_PANIC
		call	SysShutdown
		jmp	done

REAProcessBatchFile	endm




; #########################################################################
; #                       BATCH REPORT ROUTINES
; #########################################################################



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BatchReport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append a string to the batch report dialog.

CALLED BY:	BatchReportDocumentOpen
PASS:		ax	= append message
		dx:bp	= string to append
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BatchReport	proc	far
		uses	ax,bx,cx,si,di
		.enter

		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchStatusText
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		clr	cx
		call	ObjMessage

		.leave
		ret
BatchReport	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BatchReportNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the passed number to the batch status dialog.

CALLED BY:	BatchDisplayChunkStateCounts
PASS:		ax	= number
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BatchReportNumber	proc	far
numberBuffer	local	UHTA_NULL_TERM_BUFFER_SIZE dup (TCHAR)
		uses	ax,cx,dx,di,bp
		.enter

	; First, convert number to an ASCII string.

		mov	cx, mask UHTAF_NULL_TERMINATE
		clr	dx
		segmov	es, ss, di
		lea	di, numberBuffer
		call	UtilHex32ToAscii

	; Now, write it out to the dialog.

		push	bp
		mov	ax, MSG_VIS_TEXT_APPEND
		mov	dx, ss
		lea	bp, ss:[numberBuffer]
		call	BatchReport
		pop	bp

		.leave
		ret
BatchReportNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BatchReportReturn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a return to the batch status dialog.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
returnChar char C_ENTER,0

BatchReportReturn	proc	far
		uses	ax,bx,cx,dx,bp,si,di
		.enter

		mov	ax, MSG_VIS_TEXT_APPEND
		mov	dx, cs
		mov	bp, offset returnChar

		GetResourceHandleNS	FileMenuUI, bx
		clr	cx
		mov	si, offset ResEditBatchStatusText
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
BatchReportReturn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BatchReportTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a tab to the batch status dialog.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
tabChar char C_TAB,0

BatchReportTab	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		mov	ax, MSG_VIS_TEXT_APPEND
		mov	dx, cs
		mov	bp, offset tabChar

		GetResourceHandleNS	FileMenuUI, bx
		clr	cx
		mov	si, offset ResEditBatchStatusText
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
BatchReportTab	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BatchReportSetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set one of the value indicators in the status dialog.

CALLED BY:	EXTERNAL
PASS:		dx = value
		si = offset of GenValue in the FileMenuUI resource
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BatchReportSetValue	proc	far
		uses	ax,bx,cx,dx,di,bp
		.enter

		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		GetResourceHandleNS	FileMenuUI, bx
		mov	cx, dx
		clr	bp
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
BatchReportSetValue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BatchReportIncrementValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment one of the value indicators in the status dialog.

CALLED BY:	EXTERNAL
PASS:		si = offset of GenValue in the FileMenuUI resource
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BatchReportIncrementValue	proc	far
		uses	ax,bx,cx,dx,di,bp
		.enter

		mov	ax, MSG_GEN_VALUE_INCREMENT
		GetResourceHandleNS	FileMenuUI, bx
		clr	cx, bp
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
BatchReportIncrementValue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BatchReportError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report an error in the status dialog.

CALLED BY:	EXTERNAL
PASS:		ax	= offset of the error string in FileMenuUI
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BatchReportError	proc	far
		uses	dx,bp
		.enter

		mov	bp, ax
		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		GetResourceHandleNS	FileMenuUI, dx
		call	BatchReportTab
		call	BatchReport
		call	BatchReportReturn

		.leave
		ret
BatchReportError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BatchReportDocumentOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report in the status box that the document has been opened.

CALLED BY:	REAProcessBatchFile
PASS:		cx:dx	= document name
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BatchReportDocumentOpen	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	; Write "Opening document:".

		push	cx, dx
		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		GetResourceHandleNS	FileMenuUI, dx
		mov	bp, offset ResEditBatchOpenDocumentText
		call	BatchReport

	; Write document name.

		mov	ax, MSG_VIS_TEXT_APPEND
		pop	dx, bp
		call	BatchReport
		call	BatchReportReturn

		.leave
		ret
BatchReportDocumentOpen	endp


MainProcessCode 	ends







