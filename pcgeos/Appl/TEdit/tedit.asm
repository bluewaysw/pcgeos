COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		TEdit (Sample PC GEOS application)
FILE:		tedit.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	7/91		Initial version

TESCRIPTION:
	This file source code for the TEdit application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for handling documents.  Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: tedit.asm,v 1.2 98/02/15 19:57:52 gene Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include	assert.def
include vm.def

include object.def
include graphics.def
include gstring.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def
UseLib spool.def
UseLib Objects/vTextC.def
UseLib Objects/vLTextC.def
UseLib Objects/Text/tCtrlC.def
UseLib spell.def

include Internal/prodFeatures.def
;
; Add mailbox support for all but PIZZA systems and PENELOPE.
;

if FAX_SUPPORT
UseLib	Internal/spoolInt.def
UseLib  mailbox.def
include Mailbox/vmtree.def
include Mailbox/spooltd.def
include Mailbox/faxsendtd.def
include	initfile.def
endif


;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

TEProcessClass	class	GenProcessClass
TEProcessClass	endc

idata	segment
	TEProcessClass	mask CLASSF_NEVER_SAVED
idata	ends

;----------------------

; TEDocument class is our subclass of GenDocument that we use to add
; behavior to the GenDocument

TEDocumentClass	class	GenDocumentClass
TEDocumentClass endc

idata	segment
	TEDocumentClass
idata	ends

;----------------------

; TELargeTextClass adds some functionality for pasting non-dos characters
; into the SBCS version of TEdit.

TELargeTextClass	class	VisLargeTextClass
TELargeTextClass	endc

idata	segment
	TELargeTextClass
idata	ends

ifdef EXCELSIOR
include	eqeditDialog.def
endif

;----------------------

if FAX_SUPPORT

; TEPrintControlClass adds some functionality for detecting if the print
; destination is to a fax printer, so the font can be made more legible.

TEMailboxPrintControlClass	class	PrintControlClass

	MSG_TEMPC_CHECK_FOR_FAX	message
	;
	; Checks the destination of a print job to see if the destination print
	; driver is a fax print driver.
	;
	; Pass:		nothing
	;
	; Return: 	ax	- TRUE if the destination is a fax print driver
	;			- FALSE if the destination is not a fax print
	;			  driver, or if there is no way to tell.
	;

TEMailboxPrintControlClass	endc

idata	segment
	TEMailboxPrintControlClass
idata	ends

endif	; FAX_SUPPORT

;------------------------------------------------------------------------------
;			Constants and structures
;------------------------------------------------------------------------------

READ_WRITE_BLOCK_SIZE	equ	4000

BAD_OFFSET_IN_TRANSFER_TEXT_HUGE_ARRAY		enum	FatalErrors
EXPECTED_ELEMENT_SIZE_OF_ONE_IN_TEXT_HUGE_ARRAY	enum	FatalErrors

if DBCS_PCGEOS
UNEXPECTED_BYTE_OFFSET_FROM_LOCAL_DOS_TO_GEOS			enum FatalErrors
; LocalDosToGeos() returned a byte offset other than 1 when using the
; SJIS code page.  Since SJIS is only 1 and 2 byte codes, the byte
; offset should only ever be 1.
endif


;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

udata	segment

defaultPointSize	word		; default point size for next document

udata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		tedit.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for TEDocumentClass
;------------------------------------------------------------------------------

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the TextEdit application

CALLED BY:	UI (MSG_GEN_PROCESS_OPEN_APPLICATION)

PASS:		AX	= Method
		CX	= AppAttachFlags
		DX	= Handle to AppLaunchBlock
		BP	= Block handle
		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TEOpenApplication method TEProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION
	.enter

	; Call our superclass
	;
	push	cx
	mov	di, offset TEProcessClass	; class of SuperClass we call
	call	ObjCallSuperNoLock
		
	; Add process to point-size notification
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE
	call	TESendToAppGCNList

	; Set the default point size, unless we are restoring from state
	;
	pop	cx
	;
	; even if restoring from state, set point size if none set yet.
	; GWNT_TEXT_CHAR_ATTR_CHANGE will come in and overwrite our value,
	; if it wants - brianc 5/3/94
	; 
	tst	ds:[defaultPointSize]
	jz	setPointSize
	test	cx, mask AAF_RESTORING_FROM_STATE
	jnz	exit
setPointSize:
	call	UserGetDefaultMonikerFont	; default point size => DX
	mov	ax, 9
	cmp	dx, 10
	jle	storePointSize
	mov	ax, 12
	cmp	dx, 13
	jle	storePointSize
SBCS <	mov	ax, 14							>
DBCS <	mov	ax, 16							>
storePointSize:
	mov	ds:[defaultPointSize], ax
exit:
	.leave
	ret
TEOpenApplication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TECloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the TextEdit application

CALLED BY:	UI (MSG_GEN_PROCESS_CLOSE_APPLICATION)

PASS:		Nothing

RETURN:		CX	= Handle of extra block to save to state

DESTROYED:	AX, BX, DX, SI, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TECloseApplication method TEProcessClass, MSG_GEN_PROCESS_CLOSE_APPLICATION
	.enter
		
	; Remove process from point-size notification
	;
	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE
	call	TESendToAppGCNList
	clr	cx				; no extra state block

	.leave
	ret
TECloseApplication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TESendToAppGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends an add or remove message to the application object's
		GCN list

CALLED BY:	INTERNAL

PASS:		AX	= Message to send
		CX	= GCN list to work with

RETURN:		BX:SI	= Application object's OD

DESTROYED:	AX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TESendToAppGCNList	proc	near
	.enter
	
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp				; GCNListParams => SS:BP
	call    GeodeGetProcessHandle		; process handle => BX
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, cx
	mov	ss:[bp].GCNLP_optr.handle, bx
	clr	ss:[bp].GCNLP_optr.chunk
	clr	bx				; get this geode's application
	call	GeodeGetAppObject		; ... object OD => BX:SI
	mov	di, mask MF_STACK
	call	ObjMessage			; send it!!
	add	sp, dx				; clean up the stack

	.leave
	ret
TESendToAppGCNList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TENotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the process that some change has	occurred on a GCN list.

CALLED BY:	GLOBAL (MSG_META_NOTIFY_WITH_DATA_BLOCK)

PASS:		DS, ES	= DGroup
		CX:DX	= NotificationType
		BP	= Data block handle

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TENotifyWithDataBlock	method dynamic	TEProcessClass,
					MSG_META_NOTIFY_WITH_DATA_BLOCK

	; See if this is one we are interested in
	;
	tst	bp
	jz	callSuper			; no data, so we're done
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_TEXT_CHAR_ATTR_CHANGE
	jne	callSuper

	; Access the new point size, and store it away
	;
	push	ax, es
	mov	bx, bp
	call	MemLock
	mov	es, ax				;VisTextNotifyCharAttrChange->ES
	mov	ax, es:[VTNCAC_charAttr.VTCA_pointSize.WBF_int]
	mov	ds:[defaultPointSize], ax
	call	MemUnlock
	pop	ax, es

	; Now call our superclass
callSuper:
	mov	di, offset TEProcessClass
	GOTO	ObjCallSuperNoLock
TENotifyWithDataBlock	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TEDocumentAttach -- MSG_META_ATTACH for TEDocumentClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of TEDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/27/93		Initial version

------------------------------------------------------------------------------@
TEDocumentAttach	method dynamic	TEDocumentClass, MSG_META_ATTACH

	; Set up the VM file (so that we always have it)

	push	si
	mov	bx, ds:[di].GDI_display
	mov	si, offset TETextEdit		;bxsi = text object

	push	bx
	call	ClipboardGetClipboardFile
	mov	cx, bx
	pop	bx

	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	ax, MSG_META_ATTACH
	mov	di, offset TEDocumentClass
	GOTO	ObjCallSuperNoLock

TEDocumentAttach	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TEDocumentPhysicalSave -- MSG_GEN_DOCUMENT_PHYSICAL_SAVE
							for TEDocumentClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of TEDocumentClass

	ax - The message

RETURN:
	carry - set if error
	ax - error code (if any)

TESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO COTE/STRATEGY:

KNOWN BUGS/SITE EFFECTS/CAVEATS/ITEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/30/92		Initial version

------------------------------------------------------------------------------@
TEDocumentPhysicalSave	method dynamic	TEDocumentClass,
						MSG_GEN_DOCUMENT_PHYSICAL_SAVE

	; Save the data in the file

	mov	bx, ds:[di].GDI_fileHandle		;save file handle
	call	WriteDataToFile

	ret

TEDocumentPhysicalSave	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TEDocumentPhysicalSaveAsFileHandle --
		MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE
						for TEDocumentClass

TESCRIPTION:	Write the document data to a new file handle

PASS:
	*ds:si - instance data (GDI_fileHandle is *old* file handle)
	es - segment of TEDocumentClass

	ax - The message

	cx - new file handle

RETURN:
	carry - set if error
	ax - error code

TESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO COTE/STRATEGY:

KNOWN BUGS/SITE EFFECTS/CAVEATS/ITEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/25/92		Initial version

------------------------------------------------------------------------------@
TEDocumentPhysicalSaveAsFileHandle	method dynamic	TEDocumentClass,
				MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE

	mov	bx, cx
	call	WriteDataToFile
	ret

TEDocumentPhysicalSaveAsFileHandle	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	WriteDataToFile

TESCRIPTION:	Write the data to the document file

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	bx - file handle

RETURN:
	carry - set if error
	ax - error code

DESTROYED:
	cx, dx, di

REGISTER/STACK USAGE:

PSEUDO COTE/STRATEGY:

KNOWN BUGS/SITE EFFECTS/CAVEATS/ITEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/25/92		Initial version
	dloft	4/25/93		added bufferHandle checks
------------------------------------------------------------------------------@
WriteDataToFile	proc	near	uses si
file		local	hptr	push	bx
bufferHandle	local	hptr
textHandle	local	hptr
blockSize	local	word
range		local	VisTextRange
params		local	VisTextGetTextRangeParameters
	class	TEDocumentClass
	.enter

	; clear bufferHandle so we can tell later if we've allocated one

	clr	ss:[bufferHandle]

	; get the file and position at the beginning of it

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDI_display
	mov	textHandle, ax
	tst	ax
	LONG jz	exit

	clrdw	cxdx
	clr	ax
	call	FileTruncate
	LONG jc	doneError

	; get text size (into range.VTR_end)

	push	bp
	clrdw	range.VTR_start
	movdw	range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ax, MSG_VIS_TEXT_GET_RANGE
	clr	cx				;no context
	mov	dx, ss

	mov	bx, textHandle
	mov	si, offset TETextEdit
	clr	di
	lea	bp, range
	call	ObjMessage
	pop	bp

	mov	ax, READ_WRITE_BLOCK_SIZE
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc			;allocate a buffer to read into
	mov	bufferHandle, bx
	mov	ds, ax				;ds = buffer

writeLoop:

	; get a chunk of text

	movdw	dxax, range.VTR_end
	movdw	cxbx, range.VTR_start
	cmpdw	dxax, cxbx
	LONG jz	doneNoError

	movdw	params.VTGTRP_range.VTR_start, cxbx
	subdw	dxax, cxbx
SBCS <	cmpdw	dxax, READ_WRITE_BLOCK_SIZE/2				>
DBCS <	cmpdw	dxax, (READ_WRITE_BLOCK_SIZE/4)-1			>
					; allow for CR-LF expansion
	jbe	gotSize
SBCS <	movdw	dxax, READ_WRITE_BLOCK_SIZE/2				>
DBCS <	movdw	dxax, (READ_WRITE_BLOCK_SIZE/4)-1			>
gotSize:
	mov	blockSize, ax
	adddw	dxax, cxbx
	movdw	params.VTGTRP_range.VTR_end, dxax
	movdw	range.VTR_start, dxax

	clr	ax
	movdw	params.VTGTRP_textReference.TR_type, TRT_POINTER
	movdw	params.VTGTRP_textReference.TR_ref.TRU_pointer.TRP_pointer, dsax
	mov	params.VTGTRP_flags, al

	push	bp
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE

	mov	bx, textHandle
	mov	si, offset TETextEdit
	clr	di
	lea	bp, params
	call	ObjMessage
	pop	bp

	mov	cx, blockSize
	cmpdw	range.VTR_start, range.VTR_end, ax
	clc
	jnz	gotFlag
	stc
gotFlag:
	call	ConvertBufferToDos

	clr	dx
	clr	ax				;allow errors
	mov	bx, file
	call	FileWrite
	jc	doneError
	jmp	writeLoop

doneError:
	mov	ax, offset FileWriteErrorString
	call	DisplayErrorDialog
	stc
	jmp	done

doneNoError:
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	mov	bx, textHandle
	mov	si, offset TETextEdit
	clr	di
	call	ObjMessage
	clc

done:
	pushf
	mov	bx, bufferHandle
	tst	bx				; if we've not allocated a
	jz	noFree				; buffer, don't free it!
	call	MemFree
noFree:
	popf

	jc	exit
	clr	al
	mov	bx, file
	call	FileCommit

exit:
	.leave
	ret

WriteDataToFile	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertBufferToDos

DESCRIPTION:	Convert a buffer from GEOS to DOS

CALLED BY:	INTERNAL

PASS:
	ds:0 - buffer
	SBCS:
		cx - size
	DBCS:
		cx - # of chars
	carry - set if this is the last block

RETURN:
	cx - new size

DESTROYED:
	ax, bx, dx, si, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	NOTE: The DBCS version has been changed to do all its character
	manipulation before converting to the DOS character set, since
	the size of a DOS character is unknown.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 8/92		Initial version

------------------------------------------------------------------------------@
ConvertBufferToDos	proc	near
	pushf

if DBCS_PCGEOS
	;
	; move data to end of block
	;
	segmov	es, ds
	push	cx
	mov	di, READ_WRITE_BLOCK_SIZE/2
	clr	si
	rep	movsw
	pop	cx
	;
	; Replace all CRs with CR/LF.
	;
	mov	si, READ_WRITE_BLOCK_SIZE/2	;ds:si <- source
	clr	di				;es:di <- dest
fooLoop:
	LocalGetChar ax, dssi			;get char
	LocalCmpChar ax, C_CR			;see if <CR>
	jnz	store				;branch if not
	LocalPutChar esdi, ax
	LocalLoadChar ax, C_LF
store:
	LocalPutChar esdi, ax
	loop	fooLoop				;loop while more bytes
	;
	; if this is the last block make sure that it ends in a CR-LF
	;
	popf
	jnc	notLast				;branch if not last block
	cmp	{wchar} es:[di-2], C_LF
	je	notLast
	LocalLoadChar ax, C_CR
	LocalPutChar esdi, ax
	LocalLoadChar ax, C_LF
	LocalPutChar esdi, ax
notLast:
	shr	di, 1
	mov	cx, di				;cx <- new length
	;
	; move data to end of block (move backwards to deal with overlap)
	;
	push	cx
	mov	di, READ_WRITE_BLOCK_SIZE
	dec	di
	dec	di				;es:di = last char of dest
	mov	si, cx				;ds:si = last char of source
	dec	si
	shl	si, 1
	std					;move backwards
	rep	movsw
	cld					;forwards again
	pop	cx
	mov	si, READ_WRITE_BLOCK_SIZE
	sub	si, cx
	sub	si, cx				;ds:si <- source for convert
endif
	;
	; convert to the DOS character set, replacing all unknown characters
	; with '_' (this should never happen)

SBCS <	clr	si							>
DBCS <	clr	di				;es:di <- dest		>
	mov	ax, '_'				;replacement character
DBCS <	clr	bx, dx				;bx <- cur code page, disk>
	call	LocalGeosToDos

if not DBCS_PCGEOS
	; move the data to the end of the block

	segmov	es, ds				;es:di <- dest ptr
	push	cx
	mov	di, READ_WRITE_BLOCK_SIZE/2
	rep	movsb
	pop	cx

	mov	si, READ_WRITE_BLOCK_SIZE/2	;source
	clr	di				;dest

fooLoop:
	lodsb					;get byte
	cmp	al, C_CR			;see if <LF>
	jnz	store				;add linefeeds
	stosb
	mov	al, C_LF
store:
	stosb					;else store byte
	loop	fooLoop				;loop while more bytes

	; if this is the last block make sure that it ends in a CR-LF

	popf
	jnc	done
	cmp	{char} es:[di-1], C_LF
	jz	done
	mov	al, C_CR
	stosb
	mov	al, C_LF
	stosb

done:
	mov	cx, di				;return new size
endif
	ret

ConvertBufferToDos	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ReadDataFromFile

DESCRIPTION:	Read the data from the document file

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 8/92		Initial version

------------------------------------------------------------------------------@
ReadDataFromFile	proc	near	uses si
documentObj	local	optr	push ds:[LMBH_handle], si
file		local	hptr
bufferHandle	local	hptr
textHandle	local	hptr
textSize	local	dword
modifiedFlag	local	word
	class	TEDocumentClass
	.enter

	mov	modifiedFlag, 0
	movdw	textSize, 0

	; get the file and position at the beginning of it

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDI_display
	mov	textHandle, ax

	mov	bx, ds:[di].GDI_fileHandle
	mov	file, bx

	clrdw	cxdx
	mov	al, FILE_POS_START
	call	FilePos

	mov	cx, 1					;flush actions
	mov	ax, MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS
	call	sendToProcess

	mov	ax, MSG_META_SUSPEND
	call	sendToTextObject
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	sendToTextObject

	mov	ax, READ_WRITE_BLOCK_SIZE
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc			;allocate a buffer to read into
	mov	bufferHandle, bx
	mov	ds, ax				;ds = buffer

	mov	al, FILE_POS_START
	mov	bx, file
	clrdw	cxdx
	call	FilePos

readLoop:

	; Read in the data from the document

	mov	bx, file
SBCS <	clr	dx							>
DBCS <	mov	dx, READ_WRITE_BLOCK_SIZE/2				>
SBCS <	mov	cx, READ_WRITE_BLOCK_SIZE				>
DBCS <	mov	cx, READ_WRITE_BLOCK_SIZE/2				>
	clr	ax				;allow errors
	call	FileRead
	jnc	readOK
	cmp	ax, ERROR_SHORT_READ_WRITE
	jnz	errorDone
readOK:
	jcxz	done

	call	ConvertBufferToGeos		;cx <- string length
	or	modifiedFlag, dx
	jcxz	readLoop

	add	textSize.low, cx		;add buffer size to 
	adc	textSize.high, 0		; cumulative textSize 

	; append the data to the text object

	mov	ax, MSG_VIS_TEXT_APPEND_BLOCK
	mov	dx, bufferHandle
	call	sendToTextObject

	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	di, mask MF_CALL 
	mov	bx, textHandle
	call	sendToTextObjectLow		;dx.ax <- text size
	cmpdw	dxax, textSize
	je	readLoop
	mov	ax, offset FileTooBigString
	jmp	displayError

errorDone:
	mov	ax, offset FileReadErrorString
	jmp	displayError

done:
	tst	modifiedFlag
	jz	afterModified
	mov	ax, offset CharactersFilteredString
displayError:
	movdw	bxsi, documentObj
	call	MemDerefDS
	call	DisplayErrorDialog
afterModified:

	mov	bx, bufferHandle
	call	MemFree

	mov	ax, MSG_VIS_TEXT_SELECT_START
	call	sendToTextObject

	; Change to the default point size

	mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
	call	sendToTextObject

	mov	cx, es:[defaultPointSize]
	push	bp
	mov	bx, textHandle
	mov	dx, size VisTextSetPointSizeParams
	sub	sp, dx
	mov	bp, sp
	clr	ax
	clrwwf	ss:[bp].VTSPSP_range.VTR_start, ax
	movwwf	ss:[bp].VTSPSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	movwwf	ss:[bp].VTSPSP_pointSize, cxax
	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	mov	di, mask MF_CALL or mask MF_STACK
	call	sendToTextObjectLow
	add	sp, size VisTextSetPointSizeParams
	pop	bp

	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	call	sendToTextObject		; clear modified bit, so
						; actual changes later
						; will enable SAVE trigger

	mov	ax, MSG_META_UNSUSPEND
	call	sendToTextObject

	mov	ax, MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS
	call	sendToProcess

	.leave
	ret

;---

sendToTextObject:
	mov	bx, textHandle
	clr	di
sendToTextObjectLow:
	mov	si, offset TETextEdit
	call	ObjMessage
	retn

;---

sendToProcess:
	clr	bx
	call	GeodeGetProcessHandle
	clr	di
	call	ObjMessage
	retn

ReadDataFromFile	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertBufferToGeos

DESCRIPTION:	Convert a buffer from DOS to GEOS

CALLED BY:	INTERNAL

PASS:
	DBCS:
		ds:READ_WRITE_BLOCK_SIZE/2 - buffer
		bx - file handle
	SBCS:
		ds:0 - buffer
	cx - size

RETURN:
	DBCS:
		cx - new length
	SBCS:
		cx - new size
	dx - non-zero if buffer was changed (control characters removed)

DESTROYED:
	ax, bx, dx, si, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 8/92		Initial version

------------------------------------------------------------------------------@
ConvertBufferToGeos	proc	near
	uses	es
	.enter

	; convert to the GEOS character set, replacing all unknown characters
	; with C_CTRL_A

DBCS <	push	bx				;save file handle	>
SBCS <	clr	si							>
DBCS <	segmov	es, ds							>
DBCS <	clr	di				;es:di <- dest ptr	>
DBCS <	mov	si, READ_WRITE_BLOCK_SIZE/2	;ds:si <- source buffer	>
	mov	ax, C_CTRL_A			;replacement character
DBCS <	clr	bx, dx				;bx <- cur code page, disk>
	call	LocalDosToGeos
DBCS <	pop	bx				;bx <- file handle	>
if DBCS_PCGEOS
	;
	; In multi-byte versions of DOS, it is possible we split the
	; last character.  If so, adjust the file pointer back 
	; so we re-read the correct # of bytes.  Not particularly 
	; efficient but easier than adjusting ptrs, buffer sizes, etc.
	;
	cmp	al, DTGSS_CHARACTER_INCOMPLETE	;split character?
	jne	noAdjust			;branch if not
EC <	cmp	ah, 1				;has to be 1		>
EC <	ERROR_NE	UNEXPECTED_BYTE_OFFSET_FROM_LOCAL_DOS_TO_GEOS	>
	push	cx				;save # of chars

	clrdw	cxdx				
	mov	dl, ah				;# of bytes to backup
	negdw	cxdx

	mov	al, FILE_POS_RELATIVE		;al <- FilePosMode
	call	FilePos
	pop	cx				;cx <- # of chars
noAdjust:
endif

SBCS <	clr	di							>
DBCS <	clr	si							>
	clr	dx				;modified flag
SBCS <	segmov	es, ds				;es:di <- dest ptr	>
	jcxz	doneChars
fooLoop:
	LocalGetChar ax, dssi			;get char

	LocalCmpChar ax, C_CTRL_Z		;skip Ctrl-Z, but don't warn
	jnz	notCtrlZ			;the user if at the end of the
	cmp	cx, 1				;file since DOS programs
	jz	skip				;often do this
	jmp	skipAndMark

notCtrlZ:
	LocalCmpChar ax, C_PAGE_BREAK		;allow page-breaks
	je	store
	LocalCmpChar ax, C_LF			;see if <LF>
	je	skip				;ignore linefeeds
	LocalCmpChar ax, C_TAB
	jz	store
	LocalCmpChar ax, C_CR
	jz	store
	LocalCmpChar ax, ' '
	jb	skipAndMark
store:
	LocalPutChar esdi, ax			;else store character
	jmp	skip

skipAndMark:
	inc	dx
skip:
	loop	fooLoop				;loop while more bytes

doneChars:
	mov	cx, di				;return new size
DBCS <	shr	cx, 1				;cx <- new length	>

	.leave
	ret
ConvertBufferToGeos	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DisplayErrorDialog

DESCRIPTION:	Display an error dialog

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax - offset of string (in StringsUI)

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/10/92		Initial version

------------------------------------------------------------------------------@
DisplayErrorDialog	proc	near	uses ax, bx, cx, di, bp, es
	class	TEDocumentClass
	.enter

	clr	di
	pushdw	didi				;SDP_helpContext

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	cx, ds:[di].GDI_fileName		;dscx = name

	mov_tr	bp, ax					;bp = string
	GetResourceHandleNS	StringsUI, bx
	call	MemLock
	mov	di, ax
	mov	es, ax
	mov	bp, es:[bp]				;di:bp = string

.assert (offset SDP_customTriggers eq offset SDP_stringArg2+4)
	pushdw	axax		; don't care about SDP_customTriggers

.assert (offset SDP_stringArg2 eq offset SDP_stringArg1+4)
	pushdw	axax		; don't care about SDP_stringArg2

.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	pushdw	dscx		; save SDP_stringArg1 (document name)

.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	pushdw	dibp		; save SDP_customString (di:bp)

.assert (offset SDP_customString eq offset SDP_customFlags+2)
.assert (offset SDP_customFlags eq 0)
	mov	ax, CustomDialogBoxFlags \
			<FALSE, CDT_NOTIFICATION, GIT_NOTIFICATION,0>
	push	ax

	call	UserStandardDialog

	call	MemUnlock

	.leave
	ret

DisplayErrorDialog	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	TEDocumentCreateUIForDocument --
		MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT for TEDocumentClass

DESCRIPTION:	Create the UI used to display the document (the text object)

PASS:
	*ds:si - instance data
	es - segment of TEDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 8/92		Initial version

------------------------------------------------------------------------------@
TEDocumentCreateUIForDocument	method dynamic	TEDocumentClass,
					MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT

	mov	di, offset TEDocumentClass
	call	ObjCallSuperNoLock

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_display
	mov	si, offset TETextEdit		;bxsi = text object

	; We need a VM file -- use the clipboard

	push	bx
	call	ClipboardGetClipboardFile
	mov	cx, bx
	pop	bx

	; Make the text object large

	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_VIS_LARGE_TEXT_CREATE_DATA_STRUCTURES
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	call	ReadDataFromFile

	ret

TEDocumentCreateUIForDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TEDocumentAttachUIToDocument --
		MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT for TEDocumentClass

DESCRIPTION:	Attach the UI used to display the document (the text object)
		into the visual tree

PASS:
	*ds:si - instance data
	es - segment of TEDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 8/92		Initial version

------------------------------------------------------------------------------@
TEDocumentAttachUIToDocument	method dynamic	TEDocumentClass,
					MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

	mov	di, offset TEDocumentClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GDI_display
	mov	dx, offset TETextEdit		;cxdx = text object

	; add the object as a child

	pushdw	cxdx				;save text object
	mov	ax, MSG_VIS_ADD_CHILD
	clr	bp
	call	ObjCallInstanceNoLock
	popdw	bxsi				;bxsi = text object

	; We need a VM file -- use the clipboard

	push	bx
	call	ClipboardGetClipboardFile
	mov	cx, bx
	pop	bx

	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	ret

TEDocumentAttachUIToDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TEDocumentDetachUIFromDocument --
		MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT for TEDocumentClass

DESCRIPTION:	Detach the UI for the document from the visual world

PASS:
	*ds:si - instance data
	es - segment of TEDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 3/92		Initial version

------------------------------------------------------------------------------@
TEDocumentDetachUIFromDocument	method dynamic	TEDocumentClass,
					MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT

	; remove the object as a child

	push	si
	mov	bx, ds:[di].GDI_display
	mov	si, offset TETextEdit		;bxsi = text object

	mov	ax, MSG_VIS_REMOVE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	ax, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	mov	di, offset TEDocumentClass
	GOTO	ObjCallSuperNoLock

TEDocumentDetachUIFromDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TEDocumentDestroyUIForDocument --
		MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT for TEDocumentClass

DESCRIPTION:	Destroy the UI for the document

PASS:
	*ds:si - instance data
	es - segment of TEDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 3/92		Initial version

------------------------------------------------------------------------------@
TEDocumentDestroyUIForDocument	method dynamic	TEDocumentClass,
					MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT

	push	si
	mov	bx, ds:[di].GDI_display
	mov	si, offset TETextEdit		;bxsi = text object
	mov	ax, MSG_VIS_TEXT_FREE_ALL_STORAGE
	mov	cx, TRUE			;cx <- destroy elements, too
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	si

	mov	ax, MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	mov	di, offset TEDocumentClass
	GOTO	ObjCallSuperNoLock

TEDocumentDestroyUIForDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TEDocumentFileChangedReinitializeCreatedUI --
		MSG_GEN_DOCUMENT_FILE_CHANGED_REINITIALIZE_CREATED_UI
						for TEDocumentClass

DESCRIPTION:	Revert

PASS:
	*ds:si - instance data
	es - segment of TEDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 9/92		Initial version

------------------------------------------------------------------------------@
TEDocumentFileChangedReinitializeCreatedUI	method dynamic	TEDocumentClass,
			MSG_GEN_DOCUMENT_FILE_CHANGED_REINITIALIZE_CREATED_UI
	call	ReadDataFromFile
	ret

TEDocumentFileChangedReinitializeCreatedUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TEDocumentStartPrinting --
		MSG_PRINT_START_PRINTING for TEDocumentClass

DESCRIPTION:	Start printing

PASS:
	*ds:si - instance data
	es - segment of TEDocumentClass

	ax - The message

	cx:dx - spool print control
	bp - gstate

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/10/92		Initial version
	JDM	93.02.15	push-/pob-wbf modifications.

------------------------------------------------------------------------------@
TEDocumentStartPrinting	method dynamic	TEDocumentClass,
						MSG_PRINT_START_PRINTING
gstate		local	hptr	push	bp
displayHandle	local	hptr	push	ds:[di].GDI_display
leftMargin	local	word
topMargin	local	word
horizMargins	local	word
vertMargins	local	word
oldSize		local	XYSize
newSize		local	XYSize
counter		local	word
regionNum	local	word
;;;tmatrix	local	TransMatrix
getParams	local	VisTextGetAttrParams
charAttr	local	VisTextCharAttr
diffs		local	VisTextCharAttrDiffs
setParams	local	VisTextSetCharAttrParams
userModified	local	word
NPZ <ifFax	local	word						>
	.enter

	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	UserCallApplication
	pop	ax, cx, dx, bp

if FAX_SUPPORT
	;
	; If this is a fax, change the font to something readable.  URW_MONO is
	; too thin to make out.
	;
	mov	ax, MSG_TEMPC_CHECK_FOR_FAX
	call	callSpoolPrintControl		; ax <- TRUE if this is a fax
	mov	ss:[ifFax], ax
endif ;FAX_SUPPORT
		
	; Get the margins the printer is using

	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_PRINTER_MARGINS
	mov	dx, TRUE			; set the margins too
	call	callSpoolPrintControl		; margins => AX, CX, DX, BP
	mov	di, bp
	pop	bp
	mov	leftMargin, ax
	mov	topMargin, cx
	add	dx, ax
	add	di, cx
	mov	horizMargins, dx
	mov	vertMargins, di

	; Get and set the paper size the user has selected

	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_PAPER_SIZE
	call	callSpoolPrintControl		; paper dimmensions => CX, DX
	push	cx, dx
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_SIZE
	call	callSpoolPrintControl
	pop	cx, dx
	pop	bp
	sub	cx, horizMargins
	sub	dx, vertMargins
	mov	newSize.XYS_width, cx
	mov	newSize.XYS_height, dx

	; get the user modified state of text object, then mark it as user
	; modified so that we don't bogusly mark the document as dirty

	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	call	callTextObject			;cx = user modified state
	mov	userModified, cx
	mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
	call	callTextObject

	; change the font and point size to MONO 12

	mov	ax, MSG_META_SUSPEND
	call	callTextObject

	lea	ax, charAttr
	movdw	getParams.VTGAP_attr, ssax
	lea	ax, diffs
	movdw	getParams.VTGAP_return, ssax
	clr	getParams.VTGAP_flags
	mov	ax, MSG_VIS_TEXT_GET_CHAR_ATTR
	lea	bx, getParams
	mov	dx, size getParams
	call	callTextObject

	push	charAttr.VTCA_fontID
	mov	al, charAttr.VTCA_textStyles
	push	ax				; save text styles
	pushwbf	charAttr.VTCA_pointSize, ax
NPZ <	mov	charAttr.VTCA_fontID, FID_DTC_URW_MONO			>
PZ <	mov	charAttr.VTCA_fontID, FID_BITSTREAM_KANJI_HON_MINCHO	>
	mov	charAttr.VTCA_pointSize.WBF_int, 12
	mov	charAttr.VTCA_pointSize.WBF_frac, 0

if FAX_SUPPORT
	CheckHack <FALSE eq 0>
	tst	ss:[ifFax]
	jz	setAttrs

	; It's a fax.  Make the characters legible.

	ornf	charAttr.VTCA_textStyles, mask TS_BOLD
setAttrs:
endif

	lea	ax, charAttr
	movdw	setParams.VTSCAP_charAttr, ssax
	mov	ax, MSG_VIS_TEXT_SET_CHAR_ATTR
	lea	bx, setParams
	mov	dx, size setParams
	call	callTextObject

	popwbf	charAttr.VTCA_pointSize, ax
	pop	ax				; al <- styles
	mov	charAttr.VTCA_textStyles, al
	pop	charAttr.VTCA_fontID

	; change the page size of the text object

	mov	ax, MSG_VIS_LARGE_TEXT_GET_DRAFT_REGION_SIZE
	call	callTextObject
	mov	oldSize.XYS_width, cx
	mov	oldSize.XYS_height, dx

	mov	cx, newSize.XYS_width
	mov	dx, newSize.XYS_height
	mov	ax, MSG_VIS_LARGE_TEXT_SET_DRAFT_REGION_SIZE
	call	callTextObject

	mov	ax, MSG_META_UNSUSPEND
	call	callTextObject

	; now loop through printing the regions

	mov	ax, MSG_VIS_LARGE_TEXT_GET_REGION_COUNT
	call	callTextObject			;cx = count
	mov	counter, cx
	clr	regionNum

	; tell the PrintControl how many pages we have to print

	push	bp
	mov	dx, cx
	mov	cx, 1
	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	call	callSpoolPrintControl
	pop	bp

	; We use the default translation matrix as the text object
	; applies additional transformations to it. Each loop:
	;	1) Assume the default transform is correct
	;	2) Return to the top of the page
	;	3) Re-position for the next page
	;	4) Re-initialize the default transformation
	;	5) Account for margins
	
printLoop:

	mov	di, gstate
	call	GrSaveState
;;;	call	GrSetDefaultTransform
;;;	segmov	ds, ss
;;;	lea	si, tmatrix
;;;	call	GrGetTransform
;;;	movdw	dxcx, ds:[si].TM_e31.DWF_int
;;;	movdw	bxax, ds:[si].TM_e32.DWF_int
;;;	negdw	dxcx				;dxcx = x translation
;;;	negdw	bxax				;bxax = y translation
;;;	call	GrApplyTranslationDWord

	; Get this page's position

	mov	ax, MSG_VIS_LARGE_TEXT_GET_REGION_POS
	mov	cx, regionNum
	call	callTextObject			;dxax = pos, cx = height
	pushdw	dxax				;save y pos

	; Set a clip rectangle so that all of the text in the
	; document will not be drawn into the spool file (for this page)

	mov	dx, cx				;dx = height
	mov	ax, leftMargin
	mov	bx, topMargin
	mov	cx, newSize.XYS_width
	add	cx, ax
	add	dx, bx
	;
	; adjust bottom of clip rect to fix problem where top pixel of next
	; line (on next page) appears on this page
	;
PZ <	dec	dx							>
	mov	si, PCT_REPLACE
	call	GrSetClipRect

	; Translate to the location of the page (including the margins)

	popdw	bxax				;bxax = y pos
	negdw	bxax
	add	ax, topMargin
	adc	bx, 0
	clr	dx
	mov	cx, leftMargin			;dxcx = x pos
	call	GrApplyTranslationDWord
	call	GrInitDefaultTransform

	; Now actually print

	mov	ax, MSG_VIS_DRAW
	mov	cl, mask DF_EXPOSED or mask DF_PRINT
	mov	bx, di				;bx = GState (passed in BP)
	call	callTextObject

	; Must be present at the end of each page

	mov	di, gstate
	call	GrRestoreState
	mov	al, PEC_FORM_FEED
	call	GrNewPage

	inc	regionNum
	dec	counter
	LONG jnz printLoop

	; Tell the PrintControl object that we're done

	push	bp
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
	call	callSpoolPrintControl
	pop	bp

	mov	ax, MSG_META_SUSPEND
	call	callTextObject

	lea	ax, charAttr
	movdw	setParams.VTSCAP_charAttr, ssax
	mov	ax, MSG_VIS_TEXT_SET_CHAR_ATTR
	lea	bx, setParams
	mov	dx, size setParams
	call	callTextObject

	mov	cx, oldSize.XYS_width
	mov	dx, oldSize.XYS_height
	mov	ax, MSG_VIS_LARGE_TEXT_SET_DRAFT_REGION_SIZE
	call	callTextObject

	mov	ax, MSG_META_UNSUSPEND
	call	callTextObject

	tst	userModified
	jnz	afterUserModified
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	call	callTextObject
afterUserModified:

	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_FORCE_QUEUE
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	ObjMessage

	.leave
	ret

;---

callSpoolPrintControl:
	push	bx, si, di
	GetResourceHandleNS	TEPrintControl, bx
	mov	si, offset TEPrintControl
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bx, si, di
	retn

;---

	; bx - value to pass in bp

callTextObject:
	push	bx, si, di, bp
	push	bx
	mov	bx, displayHandle
	mov	si, offset TETextEdit
	mov	di, mask MF_CALL
	pop	bp
	call	ObjMessage
	pop	bx, si, di, bp
	retn

TEDocumentStartPrinting	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	TEDocumentSetPointSize -- MSG_VIS_TEXT_SET_POINT_SIZE for
							TEDocumentClass

DESCRIPTION:	Set the point size

PASS:
	*ds:si - instance data
	es - segment of TEDocumentClass

	ax - The message

	ss:bp - VisTextSetPointSizeParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/18/92		Initial version

------------------------------------------------------------------------------@
TEDocumentSetPointSize	method dynamic	TEDocumentClass,
						MSG_VIS_TEXT_SET_POINT_SIZE

	; get the user modified state of text object, then mark it as user
	; modified so that we don't bogusly mark the document as dirty

	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	call	callTextObject			;cx = user modified state
	push	cx
	mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
	call	callTextObject

	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	mov	dx, size VisTextSetPointSizeParams
	call	callTextObject

	pop	cx
	tst	cx
	jnz	afterUserModified
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	call	callTextObject
afterUserModified:

	ret

;---

	; bx - value to pass in bp

callTextObject:
	push	si, bp
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_display
	mov	si, offset TETextEdit
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, bp
	retn

TEDocumentSetPointSize	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TEProcessTextUserModified -- MSG_META_TEXT_USER_MODIFIED
							for TEProcessClass

DESCRIPTION:	Notification that the user has modified the text

PASS:
	*ds:si - instance data
	es - segment of TEProcessClass

	ax - The message
	cx:dx = text object

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/10/92		Initial version

------------------------------------------------------------------------------@
TEProcessTextUserModified	method dynamic	TEProcessClass,
					MSG_META_TEXT_USER_MODIFIED

	; sending a MSG_GEN_DOCUMENT_MARK_DIRTY to the MODEL does not
	; always work since the MODEL might not be updated yet.  Instead,
	; we want to send to the document associated with this text
	; object

	pushdw	cxdx

	mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage			;di = message
	mov	cx, di

	popdw	bxsi

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	cx, di
	mov	dx, TO_OBJ_BLOCK_OUTPUT
	clr	di
	call	ObjMessage			;cxdx = document

	ret

TEProcessTextUserModified	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TELargeTextReplaceWithTextTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message sent when the text object is pasted to.  This will
		essentially clean up the incoming text, making sure that all
		characters are legal dos characters.

CALLED BY:	MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
PASS:		*ds:si	= TELargeTextClass object
		ds:di	= TELargeTextClass instance data
		ds:bx	= TELargeTextClass object (same as *ds:si)
		es 	= segment of TELargeTextClass
		ax	= message #
		
		dx	= size CommonTransferParams (if called remotely)
		ss:bp	= CommonTransferParams structure

RETURN:		none

DESTROYED:	ax, cx, dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The text from the clipboard come in as a huge array.  Thus, for each
	block, we lock it down, copy it into a temporary memory block,
	clean up that block, and have the text object insert that block into
	itself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/14/94   	Initial version
	PT	5/26/95		Functions with QuickMove now

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not DBCS_PCGEOS

TELargeTextReplaceWithTextTransferFormat     method dynamic TELargeTextClass, 
			MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
transferParamsPtr	local	word		push	bp
objectChunk		local	lptr		push	si
replace 		local	VisTextReplaceParameters
elementsRemaining	local	dword
arrayIndex		local	dword
vmFile			local	word
arrayDirectoryBlock	local	word
allDosChars		local	byte
	.enter
	
	; Assume all dos chars
	mov	ss:[allDosChars], TRUE
	
	; Suspend the text object so that the possibly multiple updates
	; will be seen as one update.
	push	bp				; locals stack frame
	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock		; Destroys: ax, cx, dx, bp
	pop	bp				; locals stack frame

	; Before doing anything, we should see if this is a QuickMove.
	; If it is, then TEQuickMove special will remove the "old
	; range" before we start pasting.
	push	bp				; locals stack frame
	mov	bp, ss:[transferParamsPtr]
	call	TEQuickMoveSpecial
	pop	bp				; locals stack frame
	LONG jc	done				; quick move failed
	
	mov	bx, ss:[transferParamsPtr]

	; Initialize the replacement parameters.  The first time we do this,
	; we replace the range given in the transfer params.  After that, we
	; set the start to the end.
	
	movdw	ss:[replace].VTRP_range.VTR_start, \
		  ss:[bx].CTP_range.VTR_start, ax
	movdw	ss:[replace].VTRP_range.VTR_end, \
		  ss:[bx].CTP_range.VTR_end, ax
        clr	ss:[replace].VTRP_insCount.high	; always < 64K
	mov	ss:[replace].VTRP_flags, mask VTRF_USER_MODIFICATION
	mov	ss:[replace].VTRP_textReference.TR_type, TRT_POINTER
	; pointer offset is always 0
	clr	ss:[replace].VTRP_textReference.TR_ref.TRU_pointer.TRP_pointer.offset
	
	; Lock down the block containing the TextTransferBlockHeader struct
	mov	ax, ss:[bx].CTP_vmBlock
	mov	bx, ss:[bx].CTP_vmFile
	push	bp
	call	VMLock				; ax = segment, bp = handle
	mov	es, ax
	
	; Get VMblock of Huge Array directory block for text data.
	mov	di, es:[TTBH_text].high	
	
	; Unlock this block.. don't need it anymore.  We don't care about
	; the attribute runs for this application.
	call	VMUnlock
	pop	bp				; bp = locals ptr
	
	mov	ss:[vmFile], bx
	mov	ss:[arrayDirectoryBlock], di
	
	; bx = VMfile handle, di = VMblock handle of directory block
	call	HugeArrayGetCount		; dxax = number of elements
	
	tst	dx				; if there are 0 or 1 elements
	jnz	beginLoop			; then just skip the loop.
	cmp	ax, 1				; the 1 element would just be
   LONG	jbe	endLoop				; a zero byte anyway.
	
beginLoop:
	decdw	dxax				; don't count NULL
	movdw	ss:[elementsRemaining], dxax
	
	clrdw	ss:[arrayIndex]			; start at 0

blockLoop:
	push	ds				; save object block addr
	movdw	dxax, ss:[arrayIndex]
	mov	bx, ss:[vmFile]
	mov	di, ss:[arrayDirectoryBlock]
	call	HugeArrayLock			; ds:si = ptr to element
						; ax <- count after (incl 1st)
						; cx <- count before
						; dx <- element size
EC <	tst	ax							>
EC <	ERROR_Z	BAD_OFFSET_IN_TRANSFER_TEXT_HUGE_ARRAY			>
EC <	cmp	dx, 1							>
EC <	ERROR_NE EXPECTED_ELEMENT_SIZE_OF_ONE_IN_TEXT_HUGE_ARRAY	>
	
	; Take minimum of the count after in this array block and of the
	; elements remaining as the number of bytes to copy.  This basically
	; ensures that we don't copy the zero byte at the end of the string
	; since elementsRemaining has been decremented to take care of the
	; zero byte.
	clr	dx
	cmpdw	dxax, ss:[elementsRemaining]
	jbe	gotCount
	mov	ax, ss:[elementsRemaining].low	;high must be zero!
	
gotCount:
	; Allocate and LOCK temporary buffer
	mov	cx, (mask HAF_LOCK or mask HAF_NO_ERR) shl 8 or mask HF_SWAPABLE	; HeapFlags/HeapAllocFlags
	mov	dx, ax				; save size of block
	call	MemAlloc			; bx = handle, ax = segment
	mov	es, ax
	
	; Copy data from the VMblock into our new buffer.
	mov	cx, dx				; size of block
	clr	di
	shr	cx, 1
	rep	movsw				; copy words
	jnc	doneWithCopy
	movsb					; copy extra byte

doneWithCopy:
	call	HugeArrayUnlock
	
	call	TECleanUpNonDosChars
	andnf	ss:[allDosChars], ch		; keep track if any non-dos
						; chars were substituted
						; with the underscore.
						
	pop	ds				; restore object block addr
	
	; Load up the replace parameters and do the replace!
	mov	ss:[replace].VTRP_textReference.TR_ref.TRU_pointer.TRP_pointer.segment, es
	mov	ss:[replace].VTRP_insCount.low, dx
	mov	si, ss:[objectChunk]
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT	; carry set if error
	push	bp
	lea	bp, ss:[replace]
	call	ObjCallInstanceNoLock
	pop	bp
	   
	; bx = local buffer memory handle, still!
	pushf	
	call	MemFree
	popf	
	jc	endLoop
		
	; Retrieve size of this last replacement.
	mov	ax, ss:[replace].VTRP_insCount.low
	clr	bx
	subdw	ss:[elementsRemaining], bxax
	adddw	ss:[arrayIndex], bxax
	
	; make start and end the same for next replacements
	; since they both come back pointing to the start of the last
	; replacement, add in the length of the replacement to get the
	; position for the next call.
	adddw	bxax, ss:[replace].VTRP_range.VTR_start
	movdw	ss:[replace].VTRP_range.VTR_start, bxax
	movdw	ss:[replace].VTRP_range.VTR_end, bxax
	
    	tstdw	ss:[elementsRemaining]		; done?
   LONG	jnz	blockLoop

endLoop:
	; Let the text object update itself!
	mov	si, ss:[objectChunk]
	mov	ax, MSG_META_UNSUSPEND
	push	bp
	call	ObjCallInstanceNoLock		; Destroys: ax, cx, dx, bp
	pop	bp
	
	tst	ss:[allDosChars]
   LONG	jnz	done
	
	; Okay, give the user a notification that they pasted non dos
	; characters into the TFE:
	
	push	bp
	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags,
	    	    	(CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	ss:[bp].SDOP_customString.handle, handle nonDosCharsString
	mov	ss:[bp].SDOP_customString.offset, offset nonDosCharsString
	clr	ax
	mov	ss:[bp].SDOP_stringArg1.handle, ax
	mov	ss:[bp].SDOP_stringArg2.handle, ax
	mov	ss:[bp].SDOP_customTriggers.handle, ax
	mov	ss:[bp].SDOP_helpContext.segment, ax
	
	; Pops this thing off the stack
	call	UserStandardDialogOptr
	
	pop	bp				; Restore local ptr
	
done:
	.leave
	ret
TELargeTextReplaceWithTextTransferFormat	endm

endif ;not DBCS_PCGEOS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEQuickMoveSpecial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called right before a inserting a graphic or pasting in a
		transfer item.

		NOTE: Taken out of ttQuick.asm, QuickMoveSpecial.

CALLED BY:	TELargeTextReplaceWithTextTransferFormat

PASS:		*ds:si	= text object we are going to paste into.
		ss:bp	= CommonTransferParams structure
			  Assumes the pasteFrame and quickFrame are on
			  the stack.

RETURN:		*ds:si	= object we ought to paste into.
		VTRP_range.VTR_start set correctly for the paste.

		CF SET if the operation can't succeed

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/26/95    	Initial version
	gene	3/22/00		Removed hack, use ...PREP_FOR_QUICK_TRANSFER

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not DBCS_PCGEOS

TEQuickMoveSpecial	proc	near
	uses	ax,bx,cx,dx,di,bp

	.enter

	mov	ax, MSG_VIS_TEXT_PREP_FOR_QUICK_TRANSFER
	call	ObjCallInstanceNoLock

	.leave
	ret
TEQuickMoveSpecial	endp

endif ;not DBCS_PCGEOS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TECleanUpNonDosChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes all characters in buffer DOS compatible characters.
		Converts some GEOS characters (e.g., smart quotes) to DOS
		characters, but if other GEOS characters are encountered,
		they are replaced by an underscore.

CALLED BY:	TELargeTextReplaceWithTextTransferFromat
PASS:		es:0	= points to block to be cleaned up
		dx	= number of chars (bytes) to be cleaned up
		
RETURN:		es:0	= points to cleaned up block
		ch	= Non-zero value if all chars were DOS chars or
			    replaced by acceptable DOS character.
			  Zero if at least one char was a non-DOS char that
			    was replaced by an underscore.

DESTROYED:	ds, si, ax, cl

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not DBCS_PCGEOS

TECleanUpNonDosChars	proc	near
	uses	dx
	.enter
	
	segmov	ds, es, si
	clr	si
	clr	ax
	mov	cx, dx
	mov	dh, TRUE			; assume all DOS-ok chars
	
cleanUpLoop:
	lodsb					; get char into al
	call	LocalIsDosChar
	jz	notADosChar
	;
	; check for some nasty control chars
	;
	cmp	al, C_SPACE
	jae	continueLoop
	cmp	al, C_GRAPHIC
	je	doReplacement
	cmp	al, C_SECTION_BREAK
	je	doReplacement
	cmp	al, C_PAGE_BREAK
	je	doReplacement
continueLoop:
	loop	cleanUpLoop

	mov	ch, dh
	.leave
	ret

notADosChar:
	; Check for smart double quotes
	mov	dl, C_QUOTE
	cmp	al, C_QUOTEDBLLEFT
	je	gotTheReplacementChar
	cmp	al, C_QUOTEDBLRIGHT
	je	gotTheReplacementChar
	
	; Check for smart single quotes
	mov	dl, C_SNG_QUOTE
	cmp	al, C_QUOTESNGLEFT
	je	gotTheReplacementChar
	cmp	al, C_QUOTESNGRIGHT
	je	gotTheReplacementChar
	
	; Oh well.. just give 'em an underscore.
	clr	dh				; oops, had to replace with '_'
doReplacement:
	mov	dl, C_UNDERSCORE

gotTheReplacementChar:
	; replace the character (no longer pointer to by si since si was
	; automatically incremented by the lodsb).
	mov	ds:[si-1], dl
	jmp	continueLoop
	
TECleanUpNonDosChars	endp

endif ;not DBCS_PCGEOS


;===========================================================================
;			Mailbox system-specific code
;===========================================================================

if FAX_SUPPORT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                TEMPCCheckForFax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine checks to see if the destination of a print job is
		a fax print driver or not.  It is recommended that this be
		called from the MSG_PRINT_START_PRINTING handler.

CALLED BY:      MSG_TEMPC_CHECK_FOR_FAX

PASS:		*ds:si	- instance data of TEMailboxPrintControlClass
		ds:di	- *ds:si
		es	- seg addr of TEMailboxPrintControlClass
		ax	- MSG_TEMPC_CHECK_FOR_FAX

RETURN:		ax	- TRUE if the destination is a fax print driver
			- FALSE if the destination is not a fax print driver,
			  or if there is no way to tell.

DESTROYED:	bx, si, di, ds, es (method handler)

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jdashe  3/23/95  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PRINTER_TYPE_KEY	equ	"type"
LocalDefNLString faxPrinterKey	<PRINTER_TYPE_KEY, 0>

TEMPCCheckForFax	method dynamic TEMailboxPrintControlClass,
							 MSG_TEMPC_CHECK_FOR_FAX
		uses	cx, dx
		.enter
	;
	; Hack: check to see if there is a temp varadata block.  If so, it
	; contains the file name of the print driver being used.
	;
		mov	ax, TEMP_PRINT_CONTROL_INSTANCE
		call	ObjVarFindData		; ds:bx <- vardata
		jnc	notAFaxNoBlock		; jump if no vardata
	;
	; Found the vardata.  Get the JobParameters block.
	;
		mov	bx, ds:[bx].TPCI_jobParHandle
		tst	bx
		jz	notAFax			; jump if no JobParams
		call	MemLock			; ax <- seg of JP
		jc	notAFax
	;
	; Got the JobParams.  Read the type from the ini file.
	;
		mov	ds, ax			; ds:0 <- JobParams
		mov	si, offset JP_printerName ; ds:si <- printer name
		mov	cx, cs			; cx:dx <- type key
		mov	dx, offset faxPrinterKey
		call	InitFileReadInteger	; ax <- printer type

		jc	notAFax

		cmp	ax, PDT_FACSIMILE
		jne	notAFax			; jump if no match

		mov	ax, TRUE		; it's a fax.
done:
		tst	bx
		jz	exit
		call	MemUnlock		; unlock JobParams
exit:
		.leave
		ret

notAFaxNoBlock:
	;
	; There's no fax, and we don't have a JobParams block to unlock.
	;
		clr	bx
notAFax:
		mov	ax, FALSE
		jmp	done
TEMPCCheckForFax	endm

endif ;FAX_SUPPORT

CommonCode	ends		;end of CommonCode resource
