COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CMain
FILE:		cmainDocumentMisc.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_ATTACH		Re-open a document that was open when the
				object was detached

    MTD MSG_META_GEN_PATH_RESTORE_DISK_PROMPT
				Ask the user to insert the disk holding
				this document, rather than using the name
				of the disk, on the assumption that it's
				more meaningful to the user than the name
				of the disk.

    MTD MSG_META_DETACH		Ensure the document will actually fit by
				updating it, if it's dirty.

    INT OLDocDestroyDocument	There's been some error with saving the
				document and either we or the user has
				decided to nuke it.

    MTD MSG_META_LOST_MODEL_EXCL
				Handle losing the model exclusive

    MTD MSG_GEN_DOCUMENT_CLOSE_IF_OPEN_FOR_IACP_ONLY
				Close doc if the only reason it is open is
				for an IACP connection

    MTD MSG_OL_DOCUMENT_CLOSE_FOR_NEW
				close this document before creating new one

    MTD MSG_GEN_DOCUMENT_CLOSE	Do what appears to the user to be "closing
				the document".  This involves asking for
				confirmation and possibly canceling or
				transforming to a save as.

 ?? none SendToDocumentControl	Do what appears to the user to be "closing
				the document".  This involves asking for
				confirmation and possibly canceling or
				transforming to a save as.

    MTD MSG_OL_DOCUMENT_CONTINUE_SAVE_AS_AFTER_DISK_FULL
				Continue a "save as" operation after a disk
				full

    MTD MSG_OL_DOCUMENT_RENAME_AFTER_SAVE_AS_DISK_FULL_REVERT
				rename reverted untitled document to
				desired name

    MTD MSG_OL_DOCUMENT_CONTINUE_CLOSE_AFTER_DISK_FULL
				Continue a "close" operation after a disk
				full

    INT OLDocumentSendCloseAck	If close requested by IACP, send message to
				client of connection. If close successful,
				remove connection from list of those
				interested.

    INT OLDocumentFindConnection_Close
				Callback function to locate an IACP
				connection in a document's iacpEngConnects
				array

    INT OLDocRemoveObj		Remove this object

    INT StopAutoSave		Fire up auto-save for this document

    GLB CheckIfDestinationIsCurrentFile
				Checks to see if the destination for the
				SAVE_AS is the same as the currently opened
				document - if so, we'll whine to the user

    MTD MSG_GEN_DOCUMENT_SAVE_AS
				SaveAs a file

 ?? INT FinishDocOperation	finish closing of document

 ?? INT SendToDocControlWithFlushQ
				Flush the process queue, and then dispatch
				the recorded message.

    MTD MSG_GEN_DOCUMENT_SAVE_AS_CANCELLED
				Notification that this is now the target
				document

    INT HandleSaveError		Handle errors after calling VMSave or
				VMSaveAs

    MTD MSG_GEN_DOCUMENT_IMPORT	Handle a document being imported

    MTD MSG_GEN_DOCUMENT_EXPORT	Notification that an export has been
				completed

    INT SendImpexNotificationToOutput
				Send import/export notification to the
				output

    MTD MSG_GEN_DOCUMENT_SEARCH_FOR_DOC
				Search for the given document and bring it
				to the front if it exists

    INT DisplayProtoProgress	Display a progress dialog for upgrading a
				document

 ?? INT DisplayConfirmSave	Display a dialog to confirm saving the
				current document

    INT BringDownProtoProgress	Bring down the protocol progress dialog

    MTD MSG_GEN_DOCUMENT_REVERT	Ask the user for confirmation before
				reverting a file.  If the user answers yes,
				revert the file

    MTD MSG_GEN_DOCUMENT_REVERT_NO_PROMPT
				Revert the file

    MTD MSG_OL_DOCUMENT_CONTINUE_REVERT
				Continue reverting after a trip through the
				queue

    MTD MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE
				Revert the file

    MTD MSG_OL_DOCUMENT_CONTINUE_REVERT_TO_AUTO_SAVE
				Continue reverting after a trip through the
				queue

    MTD MSG_GEN_DOCUMENT_CLOSE_FILE
				Temporarily close the file associated with
				the object

    MTD MSG_GEN_DOCUMENT_REOPEN_FILE
				Re-open the temporarily closed document
				file

    MTD MSG_GEN_DOCUMENT_GET_OPERATION
				Get the code for the operation that the
				document is undergoing

    MTD MSG_GEN_DOCUMENT_GET_DISPLAY
				The the associated display

    MTD MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE
				Enable auto-save (after it has been
				temporarily disabled)

    MTD MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE
				Temporarily disable auto-save

    MTD MSG_GEN_BRING_TO_TOP	Make this the top document

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cmainDocument.asm

DESCRIPTION:

	$Id: cmainDocumentMisc.asm,v 1.2 98/03/11 05:55:28 joon Exp $

------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

OLDocumentClass:

Synopsis
--------

OLDocument is the OPEN LOOK version of the document object.


	NOTE: The section between "Declaration" and "Methods declared" is
	      copied into uilib.def by "pmake def"

Declaration
-----------

OLDocumentClass	class OLContentClass
	uses GenDocumentClass

;-----------------------------------------------------------------------------
;		Methods
;-----------------------------------------------------------------------------

MSG_OL_DOCUMENT_CONTINUE_REVERT		message
;
;	Finish a revert

MSG_OL_DOCUMENT_CONTINUE_REVERT_QUICK	message
;
;	Finish a revert

MSG_OL_DOCUMENT_UPDATE_UI		message
;
;	Send update

MSG_OL_DOCUMENT_CONTINUE_CHANGE_TYPE	message
;
;	Continue changing the document type

MSG_OL_DOCUMENT_CONTINUE_RENAME	message
;
;	Continue changing the name
;
; Pass:
;	ss:bp - FileLongName

MSG_OL_DOCUMENT_DELETE_AFTER_SAVE_ERROR	message
MSG_OL_DOCUMENT_MOVE_AFTER_SAVE_ERROR	message
MSG_OL_DOCUMENT_DELETE_SELECTED_FILE	message
MSG_OL_DOCUMENT_SAVE_ERROR_RESOLVED	message
MSG_OL_DOCUMENT_MOVE_AFTER_ERROR_FEEDBACK	message
MSG_OL_DOCUMENT_DELETE_FILES_FS_NOTIFY	message
;
;	Pass:	cx = entry #
;		bp = GenFileSelectorEntryFlags (GFSEF_OPEN set if double-
;		     clicked)

MSG_OL_DOCUMENT_CONTINUE_CLOSE_AFTER_DISK_FULL	message
;
; Continue closing file after a disk full

MSG_OL_DOCUMENT_AUTO_SAVE_TIMER		message
;
; Internal message -- OLDocumentClass uses this message with the timer
; -- if we used MSG_GEN_DOCUMENT_AUTO_SAVE, then we would erroneously
; think our timer had fired if an app or other source sent us that
; message. 



if VOLATILE_SYSTEM_STATE

MSG_OL_DOCUMENT_WAIT_FOR_QUERY	message
;
; Sets OLDA_WAITING_FOR_SAVE_QUERY in the document.
;

MSG_OL_DOCUMENT_QUERY_IF_WAITING	message
;
; If we're waiting for a query, send a MSG_META_QUERY_SAVE_DOCUMENTS to 
; ourselves.
;
; Pass:		nothing
; Return:	carry set if fired off a query
;

endif

if FLOPPY_BASED_DOCUMENTS

MSG_OL_DOCUMENT_ADD_SIZE_TO_TOTAL	message
;
; Adds our document's size to the passed total.  Used by the document group
; to sum up the total size of the documents, useful for non-demand-paging
; systems with limited swap space, where you have to limited the number of
; open documents.   Also puts up an error box if this document exceeds the
; memory space available.
;
; Pass:		dx.cx -- running total
;		bp    -- set if a previous file was flagged as too large
; Return:	dx.cx -- adjusted to add size of GenDocument file
;		bp    -- set non-zero if this file is too large alone
;		ax, dx -- destroyed
;
endif

MSG_OL_DOCUMENT_CONTINUE_MOVE_TO	message
;
;	Continue moving the document
;
; Pass:
;	ss:bp - FileLongName


TEMP_OL_DOCUMENT_NO_DISK_SPACE_MESSAGE	vardata	word
;
; The message to send back to ourself after doing the no-disk-space
; procedure

TEMP_OL_DOCUMENT_FREE_SPACE_DRIVE	vardata word
;
; Disk handle of drive we are showing free space for (in disk-full "delete
; other files" dialog.

TEMP_OL_DOCUMENT_DISK_FULL_RESOLVED	vardata
;
; Flag set as soon as disk full is resolved (when queueing 
; MSG_OL_DOCUMENT_SAVE_ERROR_RESOLVED).  Needed to synchronously stop
; file change notification handling.

TEMP_OL_DOCUMENT_DETACH_NO_SPACE_ERROR	vardata
;
; Set if got out-of-disk-space error while detaching

;-----------------------------------------------------------------------------
;		Constants & Structures
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;		Instance Data
;-----------------------------------------------------------------------------

    OLDI_autoSaveTimer		word
    OLDI_autoSaveTimerID	word

    OLDI_changeTimer		word
    OLDI_changeTimerID		word

    OLDI_iacpEngConnects	lptr.ChunkArrayHeader



OLDocumentAttrs	record
    OLDA_USER_OPENED:1		; non-zero if user has opened the document
    OLDA_REVERT_BEFORE_CLOSE:1	; non-zero if need to revert the document
				;  before it is finally closed (user chose
				;  to discard changes)
    ; These flags are used in conjunction with DCO_USER_CONFIRM_SAVE
    ; to avoid putting up the confirmation dialog box multiple times
    ; when a disk full error occurs during save or update.

    OLDA_SAVE_BEFORE_CLOSE:1	; set if user wants to save the document
    OLDA_UPDATE_BEFORE_CLOSE:1	; Set if document should be updated,
				; but not saved, when closed.
    OLDA_WAITING_FOR_SAVE_QUERY:1
				; this is set in all documents at the start
				; of an application switch, then used to query
				; on document at a time to save their document.
    :3
OLDocumentAttrs	end


    OLDI_attrs			OLDocumentAttrs

    OLDI_disk			word	; disk & id of the open
    OLDI_id			FileID	;  file, for search purposes
    OLDI_saveErrorRes		hptr	; Handle of duplicated resource holding
					;  dialog for making room to save
					;  a document on detach.
OLDocumentClass	endc


Methods declared
----------------

Additional documentation
------------------------

------------------------------------------------------------------------------@

CommonUIClassStructures segment resource

	OLDocumentClass	mask CLASSF_NEVER_SAVED or \
				mask CLASSF_DISCARD_ON_SAVE
CommonUIClassStructures ends


;---------------------------------------------------

DocInit segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentAttach -- MSG_META_ATTACH for OLDocumentClass

DESCRIPTION:	Re-open a document that was open when the object was detached

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_META_ATTACH

RETURN:

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	READ_CACHED_DATA_FROM_FILE
	ATTACH_UI_TO_DOCUMENT

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@
OLDocumentAttach	method dynamic OLDocumentClass, MSG_META_ATTACH

	;
	; 3/22/93: cope with Lazarus, where we get an ATTACH without having
	; received an APP_SHUTDOWN. We know this has happened if GDI_fileHandle
	; is non-zero (it is unrelocated to 0 before being saved to state, so
	; the only way it can be non-zero is if we're getting an ATTACH after
	; not having been loaded from the resource or state, i.e. on Lazarus)
	; 
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	tst	ds:[di].GDI_fileHandle
	LONG jnz	done

	;
	; Let's do a little hack here:  if PDA, then ignore
	; DRE_DRIVE_NO_LONGER_EXISTS on the assumption that it is
	; a dynamically loaded FS driver for a PCMCIA slot - brianc 7/6/93
	;
	push	ds
	mov	ax, segment olPDA
	mov	ds, ax
	tst	ds:[olPDA]
	pop	ds
	jz	notPDA			; not PDA, skip hack

	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarDerefData
	cmp	ds:[bx].GFP_disk, -1	; unrelocated?
	jne	notPDA			; have valid disk handle
	mov	ax, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	ObjVarFindData
EC <	ERROR_NC	OL_ERROR					>
	push	si
	mov	si, bx			; ds:si = DiskSave buffer
	mov	cx, 0			; no callback
	call	DiskRestore
	pop	si
	jnc	notPDA			; restored, just fall through to
					;	do it all again
	cmp	ax, DRE_DRIVE_NO_LONGER_EXISTS
	jne	notPDA			; not DRE_DRIVE_NO_LONGER_EXISTS,
					;	fall through
	jmp	removeDoc		; else, silently fail to New/Open
notPDA:

	;
	; Fetch the disk handle from our path. This will cause the thing
	; to be restored. If there's an error, the Gen utilities will have
	; already put up a box telling the user what went wrong, or the user
	; was the one that canceled the restore, so s/he doesn't need to be
	; told anything more.
	; 
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath
	tst	ax
	jz	removeDoc

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	dx, ds:[di].GDI_attrs
	andnf	dx, not (mask GDA_CLOSING or mask GDA_AUTO_SAVE_STOPPED)
	mov	ds:[di].GDI_attrs, dx

	sub	sp, size DocumentCommonParams
	mov	bp, sp
	mov	ss:[bp].DCP_diskHandle, 0	; use object's path
	mov	ss:[bp].DCP_flags, 0
	mov	ss:[bp].DCP_docAttrs, dx
	mov	ss:[bp].DCP_connection, 0	;user-initiated, since that's
						; the only kind that gets
						; saved to state

	push	si
	lea	si, ds:[di].GDI_fileName	;ds:si = name (source)
	segmov	es, ss
	lea	di, ss:[bp].DCP_name		;es:di = name (dest)
	mov	cx, size FileLongName
	rep	movsb
	pop	si

	mov	ax, MSG_META_ATTACH
	call	OLDocumentOpen
	lea	sp, ss:[bp+(size DocumentCommonParams)]
	jc	removeDoc

done:
	Destroy	ax, cx, dx, bp
	ret

removeDoc:
	mov	ax, mask GDA_CLOSING
	clr	bx
	call	OLDocSetAttrs

	mov	ax, MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_DOCUMENT_ATTACH_FAILED
	call	ObjCallInstanceNoLock
	call	OLDocRemoveObj
	stc					;return error.
	jmp	done

OLDocumentAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentRestoreDiskPrompt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the user to insert the disk holding this document,
		rather than using the name of the disk, on the assumption
		that it's more meaningful to the user than the name of the
		disk.

CALLED BY:	MSG_META_GEN_PATH_RESTORE_DISK_PROMPT
PASS:		*ds:si	= generic object
		ss:bp	= GenPathDiskRestoreArgs
		dx	= size GenPathDiskRestoreArgs
		cx	= DiskRestoreError that will be returned to DiskRestore
RETURN:		carry set if message handled:
			ax	= DiskRestoreError (may be DRE_DISK_IN_DRIVE)
		bp	= unchanged
		ds	= possibly destroyed (fixed up by object system)
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Use UserStandardDialog to prompt for the disk.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentRestoreDiskPrompt method dynamic OLDocumentClass,
				MSG_META_GEN_PATH_RESTORE_DISK_PROMPT
	uses	bp
	.enter
	;
	; Make room for the document's name and the drive name on the stack,
	; as we might be in the same block as the app object, which means the
	; strings might move during the standard dialog.
	; 
	sub	sp, size FileLongName + DRIVE_NAME_MAX_LENGTH
	segmov	es, ss
	mov	di, sp
	
	;
	; Copy the two strings onto the stack.
	; 
	mov	si, ds:[si]
	add	si, ds:[si].GenDocument_offset
	add	si, offset GDI_fileName
	mov	cx, size FileLongName
	rep	movsb
	lds	si, ss:[bp].GPDRA_driveName
	mov	cx, DRIVE_NAME_MAX_LENGTH

FXIP <	push	bx							>
FXIP <	mov	bx, ds							>
FXIP <	call	ECAssertValidFarPointerXIP				>
FXIP <	pop	bx							>	
	
	rep	movsb
	
	;
	; Now set up the parameters for UserStandardDialog
	;

	mov	ax, SDBT_DISK_RESTORE
	movdw	cxdx, sssp			;cxdx = arg #1 (document name)
	movdw	bxsi, sssp
	add	si, size FileLongName		;bxsi = arg #2 (drive name)
	;
	; Do it baby
	; 
	call	CallUserStandardDialog

	;
	; Clear the names off the stack.
	; 
	add	sp, size FileLongName + DRIVE_NAME_MAX_LENGTH
	;
	; If user said yes (Disk Is In The Drive), return that. Else say
	; s/he cancelled things.
	; 
	cmp	ax, IC_YES
	mov	ax, DRE_DISK_IN_DRIVE
	je	done		; (carry clear)
	mov	ax, DRE_USER_CANCELED_RESTORE
done:
	stc					; signal message handled.
	.leave
	ret
OLDocumentRestoreDiskPrompt endm

DocInit ends

;---

DocExit segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure the document will actually fit by updating it, if
		it's dirty.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= instance data
		es	= segment of OLDocumentClass
		^ldx:bp	= ack OD
		cx	= ack ID
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentDetach method dynamic OLDocumentClass, MSG_META_DETACH
		uses	ax, cx, dx, bp
		.enter
		call	ObjInitDetach
	;
	; deal with failed MSG_GEN_DOCUMENT_OPEN where blocking
	; error dialog will cause MSG_OLDG_REMOVE_DOC to come in
	; after MSG_META_DETACH - brianc 8/9/93
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		tst	ds:[di].GDI_fileHandle
		jz	done

		call	ObjIncDetach

	;
	; If we already have a disk full dialog on screen as the app
	; is exiting, then by all means, don't put up another one!
	; Just call our superclass and leave.  We'll get an ack back
	; when this whole mess is done.
	;
		
		mov	ax, TEMP_OL_DOCUMENT_NO_DISK_SPACE_MESSAGE
		call	ObjVarFindData
		jnc	saveOrUpdate

		mov	{word} ds:[bx], MSG_META_ACK

	;
	; Clear the GDA_CLOSING flag, as we'll want our AppShutdown
	; handler to close the file when this is all over
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		andnf	ds:[di].GDI_attrs, not mask GDA_CLOSING
		jmp	done
		
saveOrUpdate:

		mov	ax, TEMP_OL_DOCUMENT_DETACH_NO_SPACE_ERROR
		call	ObjVarDeleteData

		call	OLDocumentSaveOrUpdate

notFull:
		mov	ax, MSG_META_ACK
		jc	error
		call	ObjCallInstanceNoLock
done:
		.leave
		mov	di, offset OLDocumentClass
		call	ObjCallSuperNoLock
		call	ObjEnableDetach
		ret

error:
		push	ax
		mov	ax, TEMP_OL_DOCUMENT_DETACH_NO_SPACE_ERROR
		call	ObjVarFindData
		pop	ax
		jnc	notFull
		call	OLDocumentShowLowDiskError
		jmp	done
OLDocumentDetach endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentAppShutdown -- MSG_META_APP_SHUTDOWN for OLDocumentClass

DESCRIPTION:	Close a document because the application is exiting

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_META_APP_SHUTDOWN

RETURN:

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@
OLDocumentAppShutdown	method dynamic OLDocumentClass, MSG_META_APP_SHUTDOWN

	push	ax, cx, dx, bp
	call	ObjInitDetach

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDI_operation, GDO_DETACH
	mov	ax, ds:[di].GDI_attrs
	ornf	ds:[di].GDI_attrs, mask GDA_CLOSING

	; if the file is already closing then do nothing (except ack)

	test	ax, mask GDA_CLOSING
	jnz	ackAndExit

	; Stop auto-save.  Note that this does not remove events in the queue

	call	StopAutoSave

	; if the file has failed a "save" then try to copy it to an untitled
	; file

	test	ax, mask GDA_SAVE_FAILED
	jz	notSaveFailed

	clr	ax
	mov	bx, mask GDA_SAVE_FAILED
	call	OLDocSetAttrs
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_COPY_TEMPLATE
	call	ObjCallInstanceNoLock
	jnc	common

	mov	cx, TRUE		; nuke document, please
	call	OLDocDestroyDocument
	jmp	ackAndExit

notSaveFailed:

	; if the file is read-only, copy to an untitled file

	test	ax, mask GDA_DIRTY
	jz	common

	test	ax, mask GDA_READ_ONLY
	jz	notReadOnly
copyTemplateThenRevert:
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_COPY_TEMPLATE
	call	ObjCallInstanceNoLock
	jnc	common
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_REVERT
	call	ObjCallInstanceNoLock
	jmp	common

	; if dirty then save changes to ensure that enough disk space exists

notReadOnly:
	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	SendUndoMessage

	mov	ax, MSG_GEN_DOCUMENT_UPDATE
	call	ObjCallInstanceNoLock
	jc	copyTemplateThenRevert

common:
	mov	ax, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	call	ObjCallInstanceNoLock
	call	SendPhysicalCloseOnQueue


ackAndExit:
	pop	ax, cx, dx, bp
	mov	di, offset OLDocumentClass
	call	ObjCallSuperNoLock

	;
	; Since we likely queued a PHYSICAL_CLOSE to ourselves, we need to
	; delay responding to the shutdown until that has been handled.
	; Easiest way is to ObjIncDetach here and queue ourselves an ACK
	; 
	call	ObjIncDetach
	mov	ax, MSG_META_SHUTDOWN_ACK
;	call	SendToSelfOnQueue
;do more than this, actually flush queues so that subclasses can send
;send MSG_META_OBJ_FREEs in their handler for the
;MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT sent above - brianc 7/30/93
	push	cx, dx, bp
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = MSG_META_SHUTDOWN_ACK event
	mov	cx, di			; cx = MSG_META_SHUTDOWN_ACK event
	mov	dx, bx			; handle of flush block
	clr	bp			; initial flush stop
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp

	call	ObjEnableDetach
	ret

OLDocumentAppShutdown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocDestroyDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There's been some error with saving the document and either we
		or the user has decided to nuke it.

CALLED BY:	(INTERNAL) OLDocumentAppShutdown, OLDocumentDeleteAfterSaveError
PASS:		*ds:si	= document object
		cx	= non-zero to delete document, too
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocDestroyDocument proc	far
	class	GenDocumentClass
	.enter
if HANDLE_DISK_FULL_ON_SAVE_AS
	mov	di, ds:[si]
	add	di, ds:[di].OLDocument_offset
	mov	al, ds:[di].OLDI_attrs
	push	ax
endif
	push	cx
	mov	ax, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	call	ObjCallInstanceNoLock
	;
	; Revert the doc if we're supposed to do it before closing.
	;
	mov	di, ds:[si]
	add	di, ds:[di].OLDocument_offset
	test	ds:[di].OLDI_attrs, mask OLDA_REVERT_BEFORE_CLOSE
	jz	close
	andnf	ds:[di].OLDI_attrs, not mask OLDA_REVERT_BEFORE_CLOSE
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_REVERT
	call	ObjCallInstanceNoLock
close:
	call	SendPhysicalCloseOnQueue
	pop	cx
	jcxz	removeDoc
	call	SendPhysicalDeleteOnQueue
removeDoc:
if HANDLE_DISK_FULL_ON_SAVE_AS
	pop	ax
	test	al, mask OLDA_REVERT_BEFORE_CLOSE
	jz	noRevert
	mov	ax, MSG_OL_DOCUMENT_RENAME_AFTER_SAVE_AS_DISK_FULL_REVERT
	call	SendToSelfOnQueue
noRevert:
endif
	call	OLDocRemoveObj
	.leave
	ret
OLDocDestroyDocument endp

DocExit	ends

;------


;---


;---

DocSaveAsClose segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	RemoveConnection

DESCRIPTION:	Remove connection (after trivial reject is done)

CALLED BY:	OLDocumentRemoveConnection

PASS:
	*ds:si - document object
	ds:di - Vis data
	bp - IACP connection

RETURN:
	none

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/25/93		Initial version

------------------------------------------------------------------------------@
RemoveConnection	proc	far
	uses	ax, bx, cx, dx
	.enter

	tst	bp
	jz	noMoreUser
	
	mov	ax, ds:[di].OLDI_iacpEngConnects
	tst	ax			; could this possibly mean us?
	jz	done			; no

	push	si
	mov_tr	si, ax
	;
	; Locate the connection in the array of open connections.
	; 
	clr	ax
	mov	bx, cs
	mov	di, offset @CurSeg:OLDocumentFindConnection_Close
	call	ChunkArrayEnum		; ax <- element #
	mov	cx, si			; ensure non-zero, in case...
	jnc	notFound		; => ... not connected to us
   	
	call	ChunkArrayElementToPtr	; ds:di <- element
	call	ChunkArrayDelete	; nuke it
	call	ChunkArrayGetCount	; cx <- elements left
	mov_tr	ax, si			; ax <- array, for possible free
notFound:
	pop	si
	jcxz	noMoreEng

done:
	.leave
	ret

noMoreEng:
	;
	; No more engine-mode iacp connections, so biff the array that held
	; them.
	; 
	call	LMemFree
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLDI_iacpEngConnects, 0
	;
	; If user also isn't interested, nuke the document.
	; 
	test	ds:[di].OLDI_attrs, mask OLDA_USER_OPENED
	jz	nukeDocument
	jmp	done

noMoreUser:
	andnf	ds:[di].OLDI_attrs, not mask OLDA_USER_OPENED

	;
	; Changed from user-opened to not-user-opened, so set display, if any
	; not-usable, so it won't appear in the Windows menu while being
	; operated in engine mode.
	; 
					; Optimization -- if the thing won't
					; be operated in engine mode, i.e.
					; we're done with it, it will be 
					; destroyed anyway, shortly, &
					; efficiently, in the DESTROY_UI
					; handler. -- Skip setting the thing
					; NOT_USABLE here, as that would
					; defeat the optimize nuke coming up.
					;	-- Doug 1/93
	tst	ds:[di].OLDI_iacpEngConnects
	jz	derefVisDIBeforeCheckDocNukage

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_display
	tst	bx
	jz	derefVisDIBeforeCheckDocNukage
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY
	call	GenCallParent			; ^lcx:dx <- display template
	
	push	si
	mov	si, dx				; ^lbx:si <- dupl. display
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

derefVisDIBeforeCheckDocNukage:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;
	; See if there are any IACP references to the beast.
	; 
	tst	ds:[di].OLDI_iacpEngConnects
	jz	nukeDocument		; => no -- biff it
	
	;
	; If document still hanging around, we have to take care of
	; user-requested revert now, being sure to attach the UI after the
	; revert is complete.
	; 
	test	ds:[di].OLDI_attrs, mask OLDA_REVERT_BEFORE_CLOSE
	jz	done
	
	andnf	ds:[di].OLDI_attrs, not mask OLDA_REVERT_BEFORE_CLOSE

	mov	ax, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	call	ObjCallInstanceNoLock
	
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_REVERT
	call	SendToSelfOnQueue
	
	mov	ax, MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	call	SendToSelfOnQueue
	jmp	done

nukeDocument:
	
	;
	; None. Do as we do on APP_SHUTDOWN, with the exception that we
	; only close if not already closed, and we destroy the UI, rather
	; than leaving it around to be restored from state.
	; 
	call	OLDocumentGetAttrs
	test	ax, mask GDA_DIRTY
	jz	common

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDI_attrs, mask OLDA_REVERT_BEFORE_CLOSE
	jz	notDirtyRevert

	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	SendUndoMessage
	jmp	common

notDirtyRevert:
	test	ax, mask GDA_READ_ONLY
	jz	notReadOnly
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_COPY_TEMPLATE
	call	ObjCallInstanceNoLock
	jnc	common
revert:
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_REVERT
	call	ObjCallInstanceNoLock
	jmp	common

	; if dirty then save changes to ensure that enough disk space exists

notReadOnly:
	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	SendUndoMessage

	mov	ax, MSG_GEN_DOCUMENT_UPDATE
	call	ObjCallInstanceNoLock
	jc	revert

common:
	;
	; Detach the UI from the document
	; 
	mov	ax, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	call	ObjCallInstanceNoLock
	;
	; If user requested revert, do it now.
	; 
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDI_attrs, mask OLDA_REVERT_BEFORE_CLOSE
	jz	nukeUI
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_REVERT
	call	SendToSelfOnQueue
nukeUI:
	;
	; Nuke the UI for the document, as we'll need it no longer.
	; 
	mov	ax, MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	call	ObjCallInstanceNoLock
	;
	; Close the document file in a queued fashion so any messages in the
	; queue for the UI can be processed without death.
	; 
	call	SendPhysicalCloseOnQueue
	;
	; If the document is untitled, also queue a message to delete the file.
	; 
if not UNTITLED_DOCS_ON_SP_TOP
	call	OLDocumentGetAttrs
	test	ax, mask GDA_UNTITLED
	jz	removeObj
else
	call	DocCheckIfOnRamdisk		;on ramdisk, delete it
	jnz	removeObj
endif
	call	SendPhysicalDeleteOnQueue

removeObj:
	;
	; Finally, remove the document object itself from the tree. This will
	; also destroy it, eventually.
	; 
	call	OLDocRemoveObj
	jmp	done

RemoveConnection	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentLostModelExcl -- 	MSG_META_LOST_MODEL_EXCL,
						MSG_META_LOST_SYS_MODEL_EXCL
							for OLDocumentClass

DESCRIPTION:	Handle losing the model exclusive

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

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
	Tony	1/25/93		Initial version

------------------------------------------------------------------------------@
OLDocumentLostModelExcl	method dynamic OLDocumentClass,
						MSG_META_LOST_MODEL_EXCL,
						MSG_META_LOST_SYS_MODEL_EXCL
	cmp	ax, MSG_META_LOST_SYS_MODEL_EXCL
	je	justAutoSave

	add	bx, ds:[bx].Gen_offset
	andnf	ds:[bx].GDI_attrs, not mask GDA_MODEL

	; update UI stuff

	clr	bx
	call	SendCompleteUpdateToDC

	mov	ax, MSG_GEN_PROCESS_UNDO_SET_CONTEXT
	movdw	cxdx, NULL_UNDO_CONTEXT
	call	SendUndoMessage

justAutoSave:

if (not FLOPPY_BASED_DOCUMENTS)
 	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_GEN_DOCUMENT_AUTO_SAVE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
endif
	ret

OLDocumentLostModelExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDocumentCloseIfOpenForIACPConnectionOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Close doc if the only reason it is open is for an IACP
		connection

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_DOCUMENT_CLOSE_IF_OPEN_FOR_IACP_ONLY

		nothing

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenDocumentCloseIfOpenForIACPConnectionOnly	method dynamic OLDocumentClass,
			MSG_GEN_DOCUMENT_CLOSE_IF_OPEN_FOR_IACP_ONLY

	mov	ax, ATTR_GEN_DOCUMENT_OPEN_FOR_IACP_ONLY
	call	ObjVarFindData
	jnc	exit

	mov	ax, MSG_GEN_DOCUMENT_CLOSE	; start Close
	clr	bp			; no IACP connection (we're faking a
					; user operation here)
	call	ObjCallInstanceNoLock
exit:
	ret
GenDocumentCloseIfOpenForIACPConnectionOnly	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentClose -- MSG_GEN_DOCUMENT_CLOSE for
						OLDocumentClass

DESCRIPTION:	Do what appears to the user to be "closing the document".  This
		involves asking for confirmation and possibly canceling or
		transforming to a save as.

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message
	bp - IACPConnection performing the close (0 = user)

RETURN:
	cx - DocQuitStatus (DQS_OK, DQS_DELAYED, DQS_CANCEL, DQS_SAVE_ERROR)

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

OLDocumentCheckCUIClose	method	dynamic	OLDocumentClass, MSG_OL_DOCUMENT_CHECK_CUI_CLOSE
	;
	; only in CUI
	;
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	normalClose
	;
	; check number of documents opened
	;
	push	cx, dx, bp
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	GenCallParent			; dx = number docs
	cmp	dx, 1
	pop	cx, dx, bp
	jne	normalClose
	;
	; just us, quit (which will do a regular close on us)
	;
	mov	ax, MSG_META_QUIT
	call	UserCallApplication
	ret

	;
	; multiple documents, just close us
	;
normalClose:
	mov	ax, MSG_GEN_DOCUMENT_CLOSE
	call	ObjCallInstanceNoLock
	ret
OLDocumentCheckCUIClose	endm

if not VOLATILE_SYSTEM_STATE	;Other version in cmainDocumentRedwood.asm

OLDocumentClose	method dynamic OLDocumentClass, MSG_GEN_DOCUMENT_CLOSE

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDI_attrs
	test	ax, mask GDA_CLOSING
	jz	notClosing
	mov	cx, DQS_CANCEL
	Destroy	ax, dx, bp
	ret
notClosing:
	mov	ax, GDO_CLOSE
	call	OLDocSetOperation

	mov	ax, mask GDA_CLOSING
	clr	bx
	call	OLDocSetAttrs
	
	tst	bp
	LONG jnz	iacpClose

	; if we opened for iacp only, then we'll close for iacp even if we
	; don't have an IACPConnection. - Joon (6/14/94)

	mov	ax, ATTR_GEN_DOCUMENT_OPEN_FOR_IACP_ONLY
	call	ObjVarFindData
	LONG jc		iacpClose

doClose:
	push	bp

	; check for dirty

	call	OLDocumentGetAttrs
	test	ax, mask GDA_DIRTY
	LONG jz	clean

	; --- the file is dirty (has been modified)

	; if transparent mode then always save changes
	push	es, cx
	segmov	es, dgroup, cx				;es = dgroup
	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	pop	es, cx
	jz	testIACP

	; if confirm save mode, bring up dialog	
	push	es, cx
	segmov	es, dgroup, cx		;es = dgroup
	test	es:[docControlOptions], mask DCO_USER_CONFIRM_SAVE
	pop	es, cx
	jz	toSaveChanges

	;
	; Don't bring up the dialog if we already know what we're
	; supposed to do.  This happens in the case where we tried to
	; save earlier, but the disk was full.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDI_attrs, mask OLDA_SAVE_BEFORE_CLOSE
	jnz	toSaveChanges


	;
	; If users specified revert, it will be taken care of in
	; RemoveConnection. 
	;
		
	test	ds:[di].OLDI_attrs, mask OLDA_REVERT_BEFORE_CLOSE
	LONG jnz closeCommon

	test	ds:[di].OLDI_attrs, mask OLDA_UPDATE_BEFORE_CLOSE
	jz	confirm

	mov	ax, MSG_GEN_DOCUMENT_UPDATE
	call	ObjCallInstanceNoLock
	LONG jc	checkError
	jmp	clean

toSaveChanges:
	jmp	saveChanges
confirm:

	call	DisplayConfirmSave
	LONG jc	saveChanges

	; close without saving changes

revertClose:
	;
	; Tell OLDocumentRemoveConnection to revert before it closes the
	; file.
	; 
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLDI_attrs, mask OLDA_REVERT_BEFORE_CLOSE

	; We are going to get really ugly here.  We don't want the revert
	; to read in any blocks, since the file will then be closed.  To get
	; this effect we will set an internal file system flag.
	;	tony -- 3/16/95

	call	GetParentAttrs			;ax = attribute, ZF = is VM
	jz	notVM
	call	OLDocumentGetFileHandle		;bx = file handle
	push	ds
	mov	ax, SGIT_HANDLE_TABLE_SEGMENT	;get kernel data segment
	call	SysGetInfo
	mov	ds, ax				;ds:bx = file handle
	mov	bx, ds:[bx].HF_otherInfo	;ds:bx = VM handle
	or	ds:[bx].HVM_flags, mask IVMF_DEMAND_PAGING
	pop	ds
notVM:
	jmp	closeCommon

testIACP:
	; if IACP close, same as transparent mode

	tst	bp
	jnz	saveChanges

	; if "save" has failed before then don't ask, just try to save changes

	test	ax, mask GDA_SAVE_FAILED
	jnz	saveChanges

askSave:

	push	ax
	call	GetUIParentAttrs
	test	ax, mask GDCA_DO_NOT_SAVE_FILES
	pop	ax
	jnz	revertClose

	mov_tr	cx, ax
	mov	ax, SDBT_FILE_CLOSE_ATTACH_DIRTY
	test	cx, mask GDA_ATTACH_TO_DIRTY_FILE
	jnz	normalDirty
	mov	ax, SDBT_FILE_CLOSE_SAVE_CHANGES_UNTITLED
	test	cx, mask GDA_UNTITLED
	jnz	normalDirty
	mov	ax, SDBT_FILE_CLOSE_SAVE_CHANGES_TITLED
normalDirty:

ISU <	push	ax, bp				;bring application to 	>
ISU <	mov	ax, MSG_GEN_BRING_TO_TOP	; top so dialog will	>
ISU <	call	UserCallApplication		; not come up hidden	>
ISU <	pop	ax, bp				; behind other windows	>

	call	FarCallStandardDialogDS_SI
	cmp	ax, IC_NULL			;null -> abort
	LONG jz	cancel
	cmp	ax, IC_DISMISS			;cancel -> abort
	LONG jz	cancel
	cmp	ax, IC_NO			;no -> revert
	LONG jz	revertClose
EC <	cmp	ax, IC_YES						>
EC <	ERROR_NE	OL_ERROR					>

	; check for temporary or read only file, if so then do a "save as"

	mov	ax, cx				;restore GenDocumentAttrs
	andnf 	ax, not mask GDA_SAVE_FAILED	; clear the save failed flag

saveChanges:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_UNTITLED or mask GDA_READ_ONLY
	LONG jnz readOnlyOrTemporary

reallySaveChanges:
	; save the changes...

	mov	cx, TRUE			; about to save, not update
	call	WriteCachedData
retrySave:
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_SAVE
	call	ObjCallInstanceNoLock		;returns error in carry
	jnc	markClean

checkError:
	cmp	ax, ERROR_DISK_UNAVAILABLE
	jz	afterErrorMessage

	call	ConvertErrorCode
	cmp	ax, ERROR_SHORT_READ_WRITE
	jz	diskFull
handleOtherError:
	mov	cx, offset CallStandardDialogDS_SI
	call	HandleSaveError
	jnc	retrySave
afterErrorMessage:
	mov	cx, DQS_SAVE_ERROR
	jmp	cancelWithCode

diskFull:
	pop	bp
	push	bp
	tst	bp
	jnz	handleOtherError

	;
	; mark save-failed, so that if user decides to move document to
	; another directory, the old (unsaved) one will be deleted
	; - brianc 7/14/93
	;
	mov	ax, mask GDA_SAVE_FAILED	;mark that save failed
	clr	bx
	call	OLDocSetAttrs

	pop	bp
	mov	ax, MSG_OL_DOCUMENT_CONTINUE_CLOSE_AFTER_DISK_FULL
	call	OLDocumentShowLowDiskError
	mov	ax, DQS_DELAYED
	jmp	exit

	; actually close the file

markClean:
	;
	; we saved the file successfuly, mark the document as clean so when
	; we do RemoveConnection (from OLDocumentSendCloseAck), we won't try
	; to save the document again.  If we do, we run into problems with
	; apps that mark their VM files dirty on a WRITE_CACHED_DATA (which
	; is used to save the document in RemoveConnection), namely that the
	; document will still be dirty when the file is re-opened
	; - brianc 5/10/94
	;
	clr	ax
	mov	bx, mask GDA_DIRTY
	call	OLDocSetAttrs

clean:
	mov	ax, MSG_OLDC_TEST_FOR_DISPLAY_MAIN_DIALOG
	call	SendToDocumentControl
closeCommon:
	mov	cx, DQS_OK
done:
	pop	bp
	call	OLDocumentSendCloseAck
	call	OLDocClearOperation
exit:
	Destroy	ax, dx, bp
	ret

	; user said CANCEL

cancel::
	mov	cx, DQS_CANCEL
cancelWithCode:
	clr	ax				;bits to set
	mov	bx, mask GDA_CLOSING		;bits to clear
	call	OLDocSetAttrs
	jmp	done

	; closing a read-only, public or temporary file -- do a save as
readOnlyOrTemporary:
	tst	bp
	jnz	temporaryIACP

	; if we failed trying to save this file earlier, ask the user
	; what to do now.  cassie 3/21/95

	test	ax, mask GDA_SAVE_FAILED
	LONG	jnz	askSave

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_DOC
	call	SendToDocumentControl
	mov	cx, DQS_DELAYED
	jmp	done


temporaryIACP:
	; read-only dirty file closed through IACP gets put in untitled...I
	; think (dirty untitled gets saved to itself)

	test	ds:[di].GDI_attrs, mask GDA_UNTITLED
	LONG jnz reallySaveChanges

	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_COPY_TEMPLATE
	call	ObjCallInstanceNoLock
	jmp	clean

iacpClose:
	push	bp			; push in case we go to closeCommon
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDI_attrs, mask OLDA_USER_OPENED
	jnz	closeCommon		; assume user will deal with any
					;  problems
	push	si
	mov	si, ds:[di].OLDI_iacpEngConnects
	call	ChunkArrayGetCount
	pop	si
	cmp	cx, 1
	jne	closeCommon		; won't actually be closed yet, so
					;  do nothing
	pop	bp			; pop since we're not go'to closeCommon
	jmp	doClose
OLDocumentClose	endm

;---

endif

SendToDocumentControl	proc	far
	push	si
	mov	bx, segment GenDocumentControlClass
	mov	si, offset GenDocumentControlClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si
	mov	cx, di
	mov	dx, TO_GEN_PARENT
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	GenCallParent
	ret
SendToDocumentControl	endp




if HANDLE_DISK_FULL_ON_SAVE_AS
COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentContinueSaveAfterDiskFull --
		MSG_OL_DOCUMENT_CONTINUE_SAVE_AS_AFTER_DISK_FULL
							for OLDocumentClass

DESCRIPTION:	Continue a "save as" operation after a disk full

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

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
	brianc	4/26/95		Initial version

------------------------------------------------------------------------------@
OLDocumentContinueSaveAsAfterDiskFull	method dynamic	OLDocumentClass,
			MSG_OL_DOCUMENT_CONTINUE_SAVE_AS_AFTER_DISK_FULL

	;
	; Since Save As will only happen when closing an untitled document,
	; make sure we are back at the list screen
	;
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
	call	SendToDocumentControl
	ret

OLDocumentContinueSaveAsAfterDiskFull	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentRenameAfterSaveAsDiskFullRevert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rename reverted untitled document to desired name

CALLED BY:	MSG_OL_DOCUMENT_RENAME_AFTER_SAVE_AS_DISK_FULL_REVERT
PASS:		*ds:si	= OLDocumentClass object
		ds:di	= OLDocumentClass instance data
		ds:bx	= OLDocumentClass object (same as *ds:si)
		es 	= segment of OLDocumentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bx, dx, di, si, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentRenameAfterSaveAsDiskFullRevert	method dynamic OLDocumentClass, 
			MSG_OL_DOCUMENT_RENAME_AFTER_SAVE_AS_DISK_FULL_REVERT
PrintMessage <can't do this since new and old may be in different directories>
	;
	; rename revert untitled document to desired name, if necessary
	;
	mov	ax, TEMP_OL_DOCUMENT_SAVE_AS_DISK_FULL
	call	ObjVarFindData
	jnc	noRename
	segmov	es, ds				; es:di = new name
	lea	di, ds:[bx].DCP_name
	call	FilePushDir
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	lea	dx, ds:[bx].GFP_path
	mov	bx, ds:[bx].GFP_disk
	call	FileSetCurrentPath
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	lea	dx, ds:[si].GDI_fileName	; ds:dx = untitled name
	call	FileRename			; ignore error
	call	FilePopDir
noRename:
	ret
OLDocumentRenameAfterSaveAsDiskFullRevert	endm

endif	;HANDLE_DISK_FULL_ON_SAVE_AS

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentContinueCloseAfterDiskFull --
		MSG_OL_DOCUMENT_CONTINUE_CLOSE_AFTER_DISK_FULL
							for OLDocumentClass

DESCRIPTION:	Continue a "close" operation after a disk full

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

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
	Tony	7/ 1/93		Initial version

------------------------------------------------------------------------------@
OLDocumentContinueCloseAfterDiskFull	method dynamic	OLDocumentClass,
				MSG_OL_DOCUMENT_CONTINUE_CLOSE_AFTER_DISK_FULL

	mov	ax, MSG_OLDC_TEST_FOR_DISPLAY_MAIN_DIALOG
	call	SendToDocumentControl
	ret

OLDocumentContinueCloseAfterDiskFull	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentSendCloseAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If close requested by IACP, send message to client of
		connection. If close successful, remove connection from
		list of those interested.

CALLED BY:	(INTERNAL) OLDocumentClose
PASS:		*ds:si	= document object
		cx	= DocQuitStatus
		bp	= IACPConnection (0 = user)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	see OLDocumentRemoveConnection

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentSendCloseAck proc	near
	class	OLDocumentClass
	uses	cx, dx, bx
	.enter

	tst	bp
	jz	checkQuitStatus

	push	si, cx

		CheckHack <offset IDCAP_status+size IDCAP_status eq \
				size IACPDocCloseAckParams>
	push	cx
	clr	bx
	call	GeodeGetAppObject
	mov	cx, bx
	xchg	dx, si
	call	IACPGetServerNumber
		CheckHack <offset IDCAP_serverNum+size IDCAP_serverNum eq \
				offset IDCAP_status>
	push	ax
		CheckHack <offset IDCAP_connection+size IDCAP_connection eq \
				offset IDCAP_serverNum>
	push	bp
		CheckHack <offset IDCAP_docObj+size IDCAP_docObj eq \
				offset IDCAP_connection>
	push	ds:[LMBH_handle]
	push	dx
		CheckHack <offset IDCAP_docObj eq 0>

	mov	bp, sp
	mov	dx, size IACPDocCloseAckParams
	mov	ax, MSG_META_IACP_DOC_CLOSE_ACK
	clr	bx, si				; any class
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage		; di <- event handle
	
	mov	bp, ss:[bp].IDCAP_connection
	add	sp, dx			; clear stack
	mov	bx, di
	clr	cx			; no completion message
	mov	dx, TO_SELF
	mov	ax, IACPS_SERVER
	call	IACPSendMessage
	
	pop	si, cx			; recover doc obj and quit status

checkQuitStatus:
	cmp	cx, DQS_OK		; => doc not closed, so don't lose
					;  connection
	jne	done
	
	call	OLDocumentRemoveConnection
done:
	.leave
	ret
OLDocumentSendCloseAck endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentFindConnection_Close
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate an IACP connection in a document's
		iacpEngConnects array

CALLED BY:	(INTERNAL) OLDocumentAddConnection & OLDocumentLostConnection
			   via ChunkArrayEnum
PASS:		*ds:si	= array
		ds:di	= &IACPConnection to check
		ax	= entry # of this connection
RETURN:		carry set if this is the one:
			ax	= preserved
		carry clear if it ain't:
			ax	= ax+1
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentFindConnection_Close proc	far
	.enter
	cmp	ds:[di], bp
	je	done
	inc	ax
	stc
done:
	cmc
	.leave
	ret
OLDocumentFindConnection_Close endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDocRemoveObj

DESCRIPTION:	Remove this object

CALLED BY:	INTERNAL

PASS:
	*ds:si - object

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
	Tony	4/90		Initial version

------------------------------------------------------------------------------@
OLDocRemoveObj	proc	far	uses si
	.enter

EC <	call	AssertIsGenDocument					>

	call	StopAutoSave

	; remove ourself (delayed please, we would like to exist when the
	; call returns)

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_OLDG_REMOVE_DOC
	call	GenFindParent
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret

OLDocRemoveObj	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StopAutoSave

DESCRIPTION:	Fire up auto-save for this document

CALLED BY:	INTERNAL

PASS:
	*ds:si - document

RETURN:
	none

DESTROYED:
	bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@

StopAutoSave	proc	far	uses ax
	class	OLDocumentClass
	.enter

EC <	call	AssertIsGenDocument					>

	mov	ax, mask GDA_AUTO_SAVE_STOPPED
	clr	bx
	call	OLDocSetAttrs

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	clr	bx
	xchg	bx, ds:[di].OLDI_autoSaveTimer
	tst	bx
	jz	afterAutoSaveStopped
	mov	ax, ds:[di].OLDI_autoSaveTimerID
	call	TimerStop
afterAutoSaveStopped:

	clr	bx
	xchg	bx, ds:[di].OLDI_changeTimer
	tst	bx
	jz	afterChangeStopped
	mov	ax, ds:[di].OLDI_changeTimerID
	call	TimerStop
afterChangeStopped:

	.leave
	ret

StopAutoSave	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfDestinationIsCurrentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the destination for the SAVE_AS is the same
		as the currently opened document - if so, we'll whine 
		to the user

CALLED BY:	GLOBAL
PASS:		ss:bp - DocumentCommonParams
		*ds:si - OLDocument object
RETURN:		carry set if dest is *not* the same as open file
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckIfDestinationIsCurrentFile	proc	near
	uses	ax, bx, cx, dx, di, es
	
	curFileID	local	dword
	curDiskHan	local	hptr

	xchg	di, bp
	.enter

;	If the document is open, get the FileID

	push	ds, si
	segmov	ds, ss
	lea	dx, ss:[di].DCP_path	;DS:DX <- directory in which file 
					; resides
	mov	bx, ss:[di].DCP_diskHandle	;Disk handle (or StandardPath)
	lea	si, ss:[di].DCP_name	;DS:SI <- file name
	call	IACPGetDocumentID
	pop	ds, si
	jc	exit

;
;	AX - disk handle that file is on
;	CX:DX - file ID
;

;	See if file ID matches

	push	ax, cx, dx
	mov	di, ds:[si]
	add	di, ds:[di].GenDocument_offset
	mov	bx, ds:[di].GDI_fileHandle
	mov	cx, size curFileID		;Size of buffer
	segmov	es, ss
	lea	di, curFileID			;ES:DI <- ptr to file ID
	mov	ax, FEA_FILE_ID
	call	FileGetHandleExtAttributes
	pop	ax, cx, dx
	jc	exit
	cmpdw	cxdx, curFileID
	stc
	jne	exit

;	See if disk handle matches

	mov_tr	dx, ax			;DX <- disk handle of open file
	mov	cx, size hptr
	lea	di, curDiskHan
	mov	ax, FEA_DISK
	call	FileGetHandleExtAttributes
	jc	exit
	cmp	dx, curDiskHan
	stc
	jne	exit
	clc		
exit:
	.leave
	xchg	di, bp
	ret
CheckIfDestinationIsCurrentFile	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentSaveAs -- MSG_GEN_DOCUMENT_SAVE_AS for
						OLDocumentClass

DESCRIPTION:	SaveAs a file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_SAVE_AS

	dx - size DocumentCommonParams
	ss:bp - DocumentCommonParams

RETURN:
	carry - set if error
	bp - unchanged
	ax - (new) file handle

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	If the subclass dirties the document when handling SAVE_AS,
	then a MSG_META_VM_FILE_DIRTY will be placed on our queue,
	which won't be handled until after OLDocumentSaveAs exits.
	This will confuse the document control, which expects to be
	able to handle any MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE
	messages that come in.  The fix is either to break up
	OLDocumentSaveAs so that the "physical" save as message is
	sent on the queue, rather than called directly, or to disallow
	dirtying the document in a MSG_GEN_DOCUMENT_SAVE_AS handler.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentSaveAs	method dynamic OLDocumentClass,
					MSG_GEN_DOCUMENT_SAVE_AS,
					MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE
				uses bp
	.enter

	push	ax

	mov	ax, GDO_SAVE_AS
	call	OLDocSetOperation

	mov	ax, TEMP_OL_DOCUMENT_USER_RETRY_SAVE_AS
	call	ObjVarDeleteData

	mov	cx, TRUE		; saving
	call	WriteCachedData

	call	PushAndSetPath
	LONG jc handleError

;	If the file we're trying to save to is the same file, just exit,
;	and don't muck with the file.

	call	CheckIfDestinationIsCurrentFile
	jc	doSaveAs

;	Put up a special error

	mov	cx, ss
	lea	dx, ss:[bp].DCP_name
	mov	ax, SDBT_FILE_OVERWRITING_ITSELF
	call	SetSysModalIfDiskFullError
	call	CallUserStandardDialog	

backToSaveAs::
	; Go back to save as dialog

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC
	call	SendToDocumentControl
	; indicate what we're doing
	push	bx
	mov	ax, TEMP_OL_DOCUMENT_USER_RETRY_SAVE_AS
	clr	cx
	call	ObjVarAddData
	pop	bx

	mov	cx, MSG_OLDG_USER_CLOSE_CANCELLED
	stc				; error
	jmp	done

doSaveAs:
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS
	call	ObjCallInstanceNoLock
	LONG jc	handleError

if not UNTITLED_DOCS_ON_SP_TOP

	; if the old file was untitled (or could not be saved, usually
	; due to disk full) then remove it

EC <	call	GenCheckGenAssumption					>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_UNTITLED or mask GDA_SAVE_FAILED
	jz	notTempRVM
	push	ax, bp
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_DELETE
	call	ObjCallInstanceNoLock
	pop	ax, bp
notTempRVM:

	call	StoreNewDocumentName
	call	UserStoreDocFileName ; Store in the most-recently-opened list.

else		;UNTITLED_DOCS_ON_SP_TOP

	push	ax, bp, ds, dx
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_UNTITLED or mask GDA_SAVE_FAILED
	jz	notTempRVM
setPath:
	; Untitleds can always be found in SP_TOP for Redwood (7/19/93 cbh).
	; We'll do a direct delete here in that directory.

	push	ds
	call	FilePushDir
	mov	bx, SP_TOP
	segmov	ds, cs
	mov	dx, offset noDir
	call	FileSetCurrentPath
	pop	ds
	jc	notTempRVM

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	dx, ds:[di].GDI_fileName	;ds:dx = file name
	call	FileDelete

	call	FilePopDir
notTempRVM:
	pop	ax, bp, ds, dx

	;
	; Moved back to the end of this ifdef, where it belongs.  It was at
	; the top when we were doing optimized save-as, but it broke the
	; non-optimized version by making us try to delete the new file name
	; on the ramdisk.  6/ 4/94 cbh
	;
	call	StoreNewDocumentName

endif		;if not UNTITLED_DOCS_ON_SP_TOP

saveAsDone::

	push	bp
	mov	ax, MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED
	call	ObjCallInstanceNoLock
	pop	bp

	; mark clean and update UI document control

	clr	ax						;bits to set
	mov	bx, mask GDA_DIRTY or mask GDA_UNTITLED or \
		    mask GDA_READ_ONLY or mask GDA_ATTACH_TO_DIRTY_FILE or \
		    mask GDA_SAVE_FAILED or mask GDA_SHARED_SINGLE or \
		    mask GDA_SHARED_MULTIPLE			;bits to clear
	call	OLDocSetAttrs
	mov	bx, 1					;not losing target
	call	SendCompleteUpdateToDC

if VOLATILE_SYSTEM_STATE
	push	bp
	mov	ax, MSG_OLDG_DOC_MARKED_CLEAN		;send msg to doc group
	call	GenCallParent
	pop	bp
skipCleaning:
endif

	; if we're actually closing then close ourself

	call	OLDocumentGetAttrs
	test	ax, mask GDA_CLOSING
	jz	notClosing

	; clear CLOSING bit first so that CLOSE does not bail immediately

closing::
	clr	ax
	mov	bx, mask GDA_CLOSING
	call	OLDocSetAttrs
	clr	bp			; must be user-initiated
	mov	ax, MSG_GEN_DOCUMENT_CLOSE
	call	ObjCallInstanceNoLock
notClosing:

	call	OLDocumentGetFileHandle
	mov	cx, MSG_OLDG_USER_CLOSE_OK
	clc

	; ax = return value, cx = method to send to parent, carry set if error

done:
	call	OLDocClearOperation
	pop	dx				;dx = message
	pushf

	; for CUI Done dialog, don't inform of cancelled close, as the only
	; way that can happen is a save-as error, which should not abort
	; quit-mode
	cmp	cx, MSG_OLDG_USER_CLOSE_CANCELLED
	jne	notCUIDone
	push	ax
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY		; CUI?
	pop	ax
	ja	notCUIDone
	push	ax
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	UserCallApplication
	test	ax, mask AS_QUITTING		; done dialog?
	pop	ax
	jnz	exitPopf			; CUI Done, keep quit-mode
notCUIDone:

	cmp	dx, MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE
	jz	saveAsTemplate
	push	ax, bp
	mov_trash	ax, cx
	call	GenCallParent
	pop	ax, bp
exitPopf:
	popf

exit:

	; if there was an error then clear the GDA_CLOSING bit

	jnc	reallyExit

if HANDLE_DISK_FULL_ON_SAVE_AS
	;
	; unless it is a disk full problem, in which case, we are still
	; in the process of handling it, so leave the GDA_CLOSING bit set
	;
	mov	ax, TEMP_OL_DOCUMENT_SAVE_AS_DISK_FULL
	call	ObjVarFindData
	jc	leaveClosing
endif
	; or if user is going to retry save as
	mov	ax, TEMP_OL_DOCUMENT_USER_RETRY_SAVE_AS
	call	ObjVarDeleteData
	jnc	leaveClosing			; found and deleted
	clr	ax
	mov	bx, mask GDA_CLOSING
	call	OLDocSetAttrs
leaveClosing::
	clr	ax
	call	OLDocSetOperation
	stc
reallyExit:
	call	FilePopDir

	Destroy	cx, dx
	.leave
	ret

	; if we are doing a save as template then we need to make the document
	; a template

saveAsTemplate:
	popf
	pushf
	jc	exitPopf

	;
	; (For the ramdisk optimization, this is left in case the saving-
	;  to-ramdisk failed.)
	;
	call	OLDocumentGetFileHandle
	mov	ax, mask GFHF_TEMPLATE
	push	ax				;allocate a word on the stack
	segmov	es, ss
	mov	di, sp
	mov	cx, size GeosFileHeaderFlags
	mov	ax, FEA_FLAGS
	call	FileSetHandleExtAttributes
	mov	ax, SDBT_NOTIFY_SAVE_AS_TEMPLATE
	call	CallUserStandardDialog
	pop	ax
	popf
	jmp	exit

;---

handleError:
	cmp	ax, ERROR_DISK_UNAVAILABLE
	mov	cx, MSG_OLDG_USER_CLOSE_CANCELLED
	jz	stillAnError

	call	ConvertErrorCode
if HANDLE_DISK_FULL_ON_SAVE_AS
	cmp	ax, ERROR_SHORT_READ_WRITE
	je	diskFull
afterDiskFull:
endif

showError::
	mov	cx, offset CallStandardDialogSS_BP
	call	HandleSaveError
	mov	cx, MSG_OLDG_USER_CLOSE_CANCELLED
	jc	stillAnError
	tst	ax			;if non-zero then allow truncate
	jz	toTryAgain

overWrite::
	ornf	ss:[bp].DCP_flags, mask DOF_SAVE_AS_OVERWRITE_EXISTING_FILE

toTryAgain:
	jmp	doSaveAs


stillAnError:

	;
	; Save-as failed, make sure the UI document control resets its
	; path to be the old path, rather than the attempted new one (it
	; blithely set the new one in SAVE_AS_FILE_SELECTED)   3/29/94 cbh
	;
	mov	bx, 1					;not losing target
	call	SendCompleteUpdateToDC			; destroys all regs
	mov	cx, MSG_OLDG_USER_CLOSE_CANCELLED
	stc						;indicate error
	jmp	done

if HANDLE_DISK_FULL_ON_SAVE_AS
diskFull:
	push	ax
	call	OLDocumentGetAttrs
	test	ax, mask GDA_CLOSING
	pop	ax
	jz	afterDiskFull			;not closing, no handling
	mov	ax, TEMP_OL_DOCUMENT_SAVE_AS_DISK_FULL
	call	ObjVarFindData
	jc	stillAnError			;we're already handling it
	ornf	ss:[bp].DCP_flags, mask DOF_SAVE_AS_OVERWRITE_EXISTING_FILE
	mov	cx, size DocumentCommonParams	;yes, quite big
	call	ObjVarAddData
	push	ds, es, si
	segmov	es, ds
	mov	di, bx
	segmov	ds, ss
	mov	si, bp
	mov	cx, size DocumentCommonParams
	rep	movsb
	pop	ds, es, si
	mov	ax, MSG_OL_DOCUMENT_CONTINUE_SAVE_AS_AFTER_DISK_FULL
	call	OLDocumentShowLowDiskError
	jmp	stillAnError			;error not resolved yet
endif

OLDocumentSaveAs	endm

if UNTITLED_DOCS_ON_SP_TOP
noDir	byte	0
endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentSaveAsCancelled -- MSG_GEN_DOCUMENT_SAVE_AS_CANCELLED
						for OLDocumentClass

DESCRIPTION:	Notification that this is now the target document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_SAVE_AS_CANCELLED

RETURN:

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@
OLDocumentSaveAsCancelled	method dynamic OLDocumentClass,
					MSG_GEN_DOCUMENT_SAVE_AS_CANCELLED

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].GDI_attrs, not mask GDA_CLOSING
	ret

OLDocumentSaveAsCancelled	endm

DocSaveAsClose ends

;---

DocError segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	HandleSaveError

DESCRIPTION:	Handle errors after calling VMSave or VMSaveAs

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax - error code
	cx - routine to call to put up the error box. One of
		CallStandardDialogSS_BP	(ss:bp = DocumentCommonParams)
		CallStandardDialogDS_SI (*ds:si = GenDocument object)

RETURN:
	carry - set if still an error, clear to retry
	ax - if retry: non-zero to allow truncation

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@

ERROR_STRING_BUFFER	=	10

HandleSaveError	proc	far

EC <	call	AssertIsGenDocument					>

	cmp	ax, ERROR_SHORT_READ_WRITE
	jne	notFull
	push	ax, bx, cx
	mov	ax, TEMP_OL_DOCUMENT_DETACH_NO_SPACE_ERROR
	clr	cx
	call	ObjVarAddData
	pop	ax, bx, cx
notFull:

	;
	; If not opened by the user, there's no retry.
	; 
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDI_attrs, mask OLDA_USER_OPENED
	jz	doneError

	cmp	ax, ERROR_WRITE_PROTECTED
	jz	writeProtected

	cmp	ax, ERROR_FILE_EXISTS
	jz	fileExists

	push	bx, dx, di
	mov	dx, SDBT_FILE_SAVE_AS_FILE_FORMAT_MISMATCH
	cmp	ax, ERROR_FILE_FORMAT_MISMATCH
	jz	gotErrorCode
	mov	dx, SDBT_FILE_SAVE_AS_SHARING_DENIED
	cmp	ax, ERROR_ACCESS_DENIED
	jz	gotErrorCode
	cmp	ax, ERROR_SHARING_VIOLATION
	je	gotErrorCode
	mov	dx, SDBT_FILE_SAVE_INSUFFICIENT_DISK_SPACE
	cmp	ax, ERROR_SHORT_READ_WRITE
	jz	gotErrorCode
	mov	dx, SDBT_FILE_ILLEGAL_NAME
	cmp	ax, ERROR_INVALID_NAME
	jz	gotErrorCode
	mov	dx, SDBT_FILE_SAVE_ERROR
gotErrorCode:

	; put error code in buffer

	sub	sp, ERROR_STRING_BUFFER
	mov	di, sp
	push	dx, cx, es
	mov	bx, ss
	mov	es, bx				;es:di = bx:di = buffer
	mov	cx, mask UHTAF_NULL_TERMINATE
	clr	dx
	call	UtilHex32ToAscii
	pop	ax, cx, es

	call	cx

	add	sp, ERROR_STRING_BUFFER
	pop	bx, dx, di

doneError:
	stc
	ret

writeProtected:
	mov	ax, SDBT_FILE_SAVE_WRITE_PROTECTED
	call	cx
	cmp	ax, IC_YES
	jnz	doneError
	clr	ax			;carry clear, ax = 0 (no truncate)
	ret

fileExists:
	mov	ax, SDBT_FILE_SAVE_AS_FILE_EXISTS
	call	cx

	;
	;  For Leia we don't allow overwriting the other document under
	;  any circumstance.
	;
	cmp	ax, IC_YES
	jz	allowTruncation

	; user has said "no" to overwriting -- bring up "save as" dialog again

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC
	call	SendToDocumentControl
	; indicate what we're doing
	push	bx, cx
	mov	ax, TEMP_OL_DOCUMENT_USER_RETRY_SAVE_AS
	clr	cx
	call	ObjVarAddData
	pop	bx, cx
	jmp	doneError

allowTruncation:
	clc
	mov	ax, -1			;allow truncation
	ret
HandleSaveError	endp

DocError ends

;---


;---

DocMisc segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentImport -- MSG_GEN_DOCUMENT_IMPORT for OLDocumentClass

DESCRIPTION:	Handle a document being imported

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message
	ss:bp - ImpexTranslationParams

RETURN:
	carry - set if error

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 9/92		Initial version

------------------------------------------------------------------------------@
OLDocumentImport	method dynamic	OLDocumentClass, MSG_GEN_DOCUMENT_IMPORT

	mov	ax, MSG_META_DOC_OUTPUT_IMPORT_FILE
	call	SendImpexNotificationToOutput

	mov	ax, MSG_GEN_DOCUMENT_SAVE
	call	SendToSelfOnQueue

	mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
	call	SendToSelfOnQueue

	ret

OLDocumentImport	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentExport -- MSG_GEN_DOCUMENT_EXPORT
							for OLDocumentClass

DESCRIPTION:	Notification that an export has been completed 

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message
	ss:bp - ImpexTranslationParams

RETURN:
	carry - set if error

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 9/92		Initial version

------------------------------------------------------------------------------@
OLDocumentExport	method dynamic	OLDocumentClass, MSG_GEN_DOCUMENT_EXPORT

	mov	ax, MSG_META_DOC_OUTPUT_EXPORT_FILE
	call	SendImpexNotificationToOutput

	push	si
	mov	bx, segment GenDocumentControlClass
	mov	si, offset GenDocumentControlClass
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_FILE_EXPORTED
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent

	ret

OLDocumentExport	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendImpexNotificationToOutput

DESCRIPTION:	Send import/export notification to the output

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax - message
	ss:bp - ImpexTranslationParams

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
	Tony	6/22/92		Initial version

------------------------------------------------------------------------------@
SendImpexNotificationToOutput	proc	near	uses si
	.enter

	push	ax, bp
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT
	call	GenCallParent			;cx:dx = output
	pop	ax, bp
	movdw	bxsi, cxdx

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

SendImpexNotificationToOutput	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentSearchForDoc -- MSG_GEN_DOCUMENT_SEARCH_FOR_DOC
							for OLDocumentClass

DESCRIPTION:	Search for the given document and bring it to the front
		if it exists

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

	ss:bp - DocumentCommonParams

RETURN:
	carry - set if a match

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/10/92		Initial version

------------------------------------------------------------------------------@
OLDocumentSearchForDoc	method dynamic	OLDocumentClass,
						MSG_GEN_DOCUMENT_SEARCH_FOR_DOC

	test	ss:[bp].DCP_flags, mask DOF_NAME_HOLDS_FILE_ID
	jz	useNames
	
	mov	ax, ss:[bp].DCP_diskHandle
	cmp	ds:[di].OLDI_disk, ax
	LONG jne	noMatch
	
	mov	ax, ({FileID}ss:[bp].DCP_name).low
	cmp	ds:[di].OLDI_id.low, ax
	LONG jne	noMatch

	mov	ax, ({FileID}ss:[bp].DCP_name).high
	cmp	ds:[di].OLDI_id.high, ax
	jne	noMatch
	jmp	match

useNames:
	; first compare the file names

	push	si
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	si, ds:[di].GDI_fileName		;ds:si = file name
	segmov	es, ss
	lea	di, ss:[bp].DCP_name			;es:di = name passed
	call	cmpstr
	jnz	popSI_noMatch

	; names match -- compare the disk handle and path

	pop	si
	push	si
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData				;ds:bx = GenFilePath
	mov	ax, ds:[bx].GFP_disk
	cmp	ax, ss:[bp].DCP_diskHandle
	jnz	popSI_noMatch

	lea	si, ds:[bx].GFP_path
	lea	di, ss:[bp].DCP_path
	call	cmpstr
	jnz	popSI_noMatch

	pop	si

match:
	; If doc being looked for (i.e. "opened") by user, then clear
	; ATTR_GEN_DOCUMENT_OPEN_FOR_IACP_ONLY flag so we don't
	; close it after IACP job is complete.
	;
	; {
	tst	ss:[bp].DCP_connection		; 0 if by user (or app-mode
						; IACP connection)
	jnz	afterPrintUpdate
	test	ss:[bp].DCP_flags, mask DOF_OPEN_FOR_IACP_ONLY
	jnz	afterPrintUpdate		; not set if user
	mov	ax, ATTR_GEN_DOCUMENT_OPEN_FOR_IACP_ONLY
	call	ObjVarDeleteData
afterPrintUpdate:
	; }

	test	ss:[bp].DCP_flags, mask DOF_RAISE_APP_AND_DOC
	jz	checkIACP

	;
	; Raise ourselves and our application, as instructed.
	; 
	push	bp
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	ObjCallInstanceNoLock
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	call	GenCallApplication
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	GenCallApplication
	pop	bp

checkIACP:
	mov	ax, ss:[bp].DCP_connection
	call	OLDocumentAddConnection
	stc
	ret

popSI_noMatch:
	pop	si
noMatch:
	clc
	ret

;---

	; return zero flag

cmpstr:
SBCS <	lodsb								>
DBCS <	lodsw								>
SBCS <	scasb								>
DBCS <	scasw								>
	jnz	cmpdone
SBCS <	tst	al							>
DBCS <	tst	ax							>
	jnz	cmpstr
cmpdone:
	retn

OLDocumentSearchForDoc	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	DisplayProtoProgress

DESCRIPTION:	Display a progress dialog for upgrading a document

CALLED BY:	INTERNAL

PASS:
	*ds:si	= GenDocumentClass object

RETURN:
	di - handle of dialog

DESTROYED:
	ax, bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/21/92	Initial version
	kho	 2/10/97	Preserve DS, and exclude if
				NO_DOCUMENT_UPGRADE_PROGRESS_DIALOG is true

------------------------------------------------------------------------------@
DisplayProtoProgress	proc	far	uses si
	.enter

if not NO_DOCUMENT_UPGRADE_PROGRESS_DIALOG
	Assert	objectPtr, dssi, GenDocumentClass

	push	ds:[LMBH_handle]			; save handle
	mov	bx, handle ProtoProgressDialog
	mov	si, offset ProtoProgressDialog
	call	UserCreateDialog			; ds destroyed
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage
	mov	di, bx

	;
	; Restore ds
	;
	pop	bx
	call	MemDerefDS
endif ; not NO_DOCUMENT_UPGRADE_PROGRESS_DIALOG

	.leave
	ret

DisplayProtoProgress	endp


COMMENT @-------------------------------------------------------------------
			DisplayConfirmSave
----------------------------------------------------------------------------

DESCRIPTION:	Display a dialog to confirm saving the current document

CALLED BY:	OLDocumentClose

PASS:		*ds:si	= GenDocumentClass object

RETURN:		CF	= set if user wants save
			  clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If IC_NULL comes in, then just save the thing, as this is
	probably better than reverting...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/19/93		Initial version

---------------------------------------------------------------------------@

if not VOLATILE_SYSTEM_STATE

DisplayConfirmSave	proc	far
	uses	ax, bx, cx, dx, di, si, bp
	.enter

	mov	cx, ds
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	dx, ds:[di].GDI_fileName	;cx:dx = file name

	push	ds:[LMBH_handle]		;object block handle
	mov	bx, handle ConfirmSaveDialog
	mov	si, offset ConfirmSaveDialog
	call	UserCreateDialog		;doesn't fixup DS
	call	MemDerefStackDS

	push	si
	mov	bp, VUM_NOW
	mov	si, offset ConfirmSaveFile
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si	

	push	ds:[LMBH_handle]		;object block handle
	call	UserDoDialog			;doesn't fixup DS
	call	UserDestroyDialog
	call	MemDerefStackDS
	;
	; Possible return values are IC_YES, IC_NO, or IC_NULL.  If
	; IC_YES or IC_NULL, then do a save.
	;
	cmp	ax, IC_NO
	je	exit

	stc
exit:

	.leave
	ret
DisplayConfirmSave	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	BringDownProtoProgress

DESCRIPTION:	Bring down the protocol progress dialog

CALLED BY:	INTERNAL

PASS:
	*ds:si	= GenDocumentClass object
	di - block handle (0 for none)

RETURN:
	none

DESTROYED:
	bx, di (flags preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/21/92	Initial version
	kho	 2/10/97	Preserve DS, and exclude if
				NO_DOCUMENT_UPGRADE_PROGRESS_DIALOG is true

------------------------------------------------------------------------------@
BringDownProtoProgress	proc	far	uses si
	.enter

if not NO_DOCUMENT_UPGRADE_PROGRESS_DIALOG
	Assert	objectPtr, dssi, GenDocumentClass
	pushf
	mov	bx, di
	tst	bx
	jz	done

	push	ds:[LMBH_handle]
	mov	si, offset ProtoProgressDialog
	call	UserDestroyDialog			; ds might be destroyed
	;
	; Restore ds
	;
	pop	bx
	call	MemDerefDS
done:
	popf
endif ; not NO_DOCUMENT_UPGRADE_PROGRESS_DIALOG

	.leave
	ret

BringDownProtoProgress	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentRevert -- MSG_GEN_DOCUMENT_REVERT for
						OLDocumentClass

DESCRIPTION:	Ask the user for confirmation before reverting a file.  If the
		user answers yes, revert the file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_USER_REVERT

RETURN:
	carry - set if aborted

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentRevert	method dynamic OLDocumentClass, MSG_GEN_DOCUMENT_REVERT

	mov	ax, GDO_REVERT
	call	OLDocSetOperation

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_CLOSING
	jnz	error

	mov	ax, SDBT_FILE_REVERT_CONFIRM
	call	FarCallStandardDialogDS_SI
	cmp	ax, IC_YES
	jnz	error

	mov	ax, MSG_GEN_DOCUMENT_REVERT_NO_PROMPT
	call	ObjCallInstanceNoLock
	Destroy	ax, cx, dx, bp
	clc
	ret

error:
	call	OLDocClearOperation
	Destroy	ax, cx, dx, bp
	stc
	ret

OLDocumentRevert	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentRevertNoPrompt -- MSG_GEN_DOCUMENT_REVERT_NO_PROMPT
						 for OLDocumentClass

DESCRIPTION:	Revert the file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_REVERT_NO_PROMPT

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentRevertNoPrompt	method dynamic OLDocumentClass,
					MSG_GEN_DOCUMENT_REVERT_NO_PROMPT

	mov	ax, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	call	ObjCallInstanceNoLock

	; at this point we must queue a message to finish the revert, since
	; we need to be fully detached before physically doing the revert

	mov	ax, MSG_OL_DOCUMENT_CONTINUE_REVERT
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	Destroy	ax, cx, dx, bp
	ret

OLDocumentRevertNoPrompt	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentContinueRevert -- MSG_OL_DOCUMENT_CONTINUE_REVERT
						for OLDocumentClass

DESCRIPTION:	Continue reverting after a trip through the queue

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

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
	Tony	10/30/91		Initial version

------------------------------------------------------------------------------@
OLDocumentContinueRevert	method dynamic	OLDocumentClass,
				MSG_OL_DOCUMENT_CONTINUE_REVERT

	call	OLDocMarkBusy

	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_REVERT
	call	ObjCallInstanceNoLock
	jnc	afterError
	mov	ax, SDBT_FILE_REVERT_ERROR
	call	FarCallStandardDialogDS_SI
	stc
afterError:
	pushf
	mov	ax, MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_FILE_CHANGED_REINITIALIZE_CREATED_UI
	call	ObjCallInstanceNoLock
	popf
	jc	afterClean
	
	call	SetCleanAndUpdate

afterClean:
	call	OLDocClearOperation

	call	OLDocMarkNotBusy

if VOLATILE_SYSTEM_STATE
	clr	ax					;set clean
	mov	bx, mask GDA_DIRTY
	call	OLDocSetAttrs

	mov	ax, MSG_OLDG_DOC_MARKED_CLEAN
	call	GenCallParent
endif

	Destroy	ax, cx, dx, bp
	ret

OLDocumentContinueRevert	endm

DocMisc ends

;---

DocObscure segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentRevertNoPrompt --
		MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE for OLDocumentClass

DESCRIPTION:	Revert the file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentRevertToAutoSave	method dynamic OLDocumentClass,
					MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE

	mov	ax, GDO_REVERT_TO_AUTO_SAVE
	call	OLDocSetOperation

	mov	ax, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	call	ObjCallInstanceNoLock

	; at this point we must queue a message to finish the revert, since
	; we need to be fully detached before physically doing the revert

	mov	ax, MSG_OL_DOCUMENT_CONTINUE_REVERT_TO_AUTO_SAVE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	Destroy	ax, cx, dx, bp
	ret

OLDocumentRevertToAutoSave	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentContinueRevert --
		MSG_OL_DOCUMENT_CONTINUE_REVERT_TO_AUTO_SAVE
		for OLDocumentClass

DESCRIPTION:	Continue reverting after a trip through the queue

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

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
	Tony	10/30/91		Initial version

------------------------------------------------------------------------------@
OLDocumentContinueRevertToAutoSave	method dynamic	OLDocumentClass,
				MSG_OL_DOCUMENT_CONTINUE_REVERT_TO_AUTO_SAVE

	call	OLDocMarkBusy

	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_REVERT_TO_AUTO_SAVE
	call	ObjCallInstanceNoLock
	jnc	afterError
	mov	ax, SDBT_FILE_REVERT_ERROR
	call	FarCallStandardDialogDS_SI

afterError:
	mov	ax, MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_FILE_CHANGED_REINITIALIZE_CREATED_UI
	call	ObjCallInstanceNoLock

	call	OLDocClearOperation

	call	OLDocMarkNotBusy

	Destroy	ax, cx, dx, bp
	ret

OLDocumentContinueRevertToAutoSave	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentCloseFile -- MSG_GEN_DOCUMENT_CLOSE_FILE
						for OLDocumentClass

DESCRIPTION:	Temporarily close the file associated with the object

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

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
	Tony	8/10/92		Initial version

------------------------------------------------------------------------------@
OLDocumentCloseFile	method dynamic	OLDocumentClass,
						MSG_GEN_DOCUMENT_CLOSE_FILE

	call	StopAutoSave

	mov	ax, MSG_GEN_DOCUMENT_UPDATE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	call	ObjCallInstanceNoLock

	call	SendPhysicalCloseOnQueue

	;
	; Now queue up a message to be sent after the physical close
	; happens.
	;
	; First record an event going to the app object.
	;
		push	si			; #1
		clr	bx
		call	GeodeGetAppObject
		mov	di, mask MF_RECORD
		mov	ax, MSG_GEN_APPLICATION_CLOSE_FILE_ACK
		call	ObjMessage		; ^hdi <- event
		pop	si			; #1
	;
	; Force-queue message to self that will send the event.
	;
		mov	cx, di			; ^hcx <- event
		clr     dx		        ; no special flags for
						; MessageDispatch
		mov	ax, MSG_META_DISPATCH_EVENT
		call	SendToSelfOnQueue

		ret
OLDocumentCloseFile	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentReOpenFile -- MSG_GEN_DOCUMENT_REOPEN_FILE
						for OLDocumentClass

DESCRIPTION:	Re-open the temporarily closed document file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

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
	Tony	8/10/92		Initial version

------------------------------------------------------------------------------@
OLDocumentReOpenFile	method dynamic	OLDocumentClass,
						MSG_GEN_DOCUMENT_REOPEN_FILE

	; create structure to pass to ourselves to re-open the file

	sub	sp, size DocumentCommonParams
	mov	bp, sp
	mov	ss:[bp].DCP_docAttrs, 0
	mov	ss:[bp].DCP_flags, mask DOF_REOPEN

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	and	ds:[di].GDI_attrs, not mask GDA_AUTO_SAVE_STOPPED
	mov	ax, ds:[di].GDI_attrs
	and	ax, mask GDA_READ_ONLY or mask GDA_READ_WRITE
	mov	ss:[bp].DCP_docAttrs, ax

	; copy file name

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	si, ds:[di].GDI_fileName		;ds:si = source
	segmov	es, ss
	lea	di, ss:[bp].DCP_name
	mov	cx, size DCP_name
	rep 	movsb
	pop	si

	; copy path

	push	si
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	mov	ax, ds:[bx].GFP_disk
	mov	ss:[bp].DCP_diskHandle, ax
	lea	si, ds:[bx].GFP_path
	lea	di, ss:[bp].DCP_path
	mov	cx, size DCP_path
	rep	movsb
	pop	si

	mov	ss:[bp].DCP_connection, -1	; signal no-change

	mov	ax, MSG_GEN_DOCUMENT_OPEN
	call	ObjCallInstanceNoLock

	add	sp, size DocumentCommonParams

	mov	bx, 1				; not losing target
	call	SendNotificationToDC
	ret

OLDocumentReOpenFile	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentGetOperation -- MSG_GEN_DOCUMENT_GET_OPERATION for
						OLDocumentClass

DESCRIPTION:	Get the code for the operation that the document is
		undergoing

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	ax - GenDocumentOperation
	cx, dx, bp - unchanged

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
OLDocumentGetOperation	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_GET_OPERATION
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDI_operation
	ret

OLDocumentGetOperation	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentGetDisplay -- MSG_GEN_DOCUMENT_GET_DISPLAY
		for OLDocumentClass

DESCRIPTION:	The the associated display

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	cx:dx - display block

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/28/91		Initial version

------------------------------------------------------------------------------@
OLDocumentGetDisplay	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_GET_DISPLAY

	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY
	call	GenCallParent
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GDI_display
	ret

OLDocumentGetDisplay	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentEnableAutoSave -- MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE
						for OLDocumentClass

DESCRIPTION:	Enable auto-save (after it has been temporarily disabled)

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

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
	Tony	10/30/91		Initial version

------------------------------------------------------------------------------@
OLDocumentEnableAutoSave	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_ENABLE_AUTO_SAVE

	mov	ax, mask GDA_PREVENT_AUTO_SAVE
	clr	bx
	call	OLDocSetAttrs
	Destroy	ax, cx, dx, bp
	ret

OLDocumentEnableAutoSave	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentDisableAutoSave -- MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE
						for OLDocumentClass

DESCRIPTION:	Temporarily disable auto-save

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

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
	Tony	10/30/91		Initial version

------------------------------------------------------------------------------@
OLDocumentDisableAutoSave	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_DISABLE_AUTO_SAVE

	clr	ax
	mov	bx, mask GDA_PREVENT_AUTO_SAVE
	call	OLDocSetAttrs
	Destroy	ax, cx, dx, bp
	ret

OLDocumentDisableAutoSave	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentBringToTop -- MSG_GEN_BRING_TO_TOP
						for OLDocumentClass

DESCRIPTION:	Make this the top document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_BRING_TO_TOP

RETURN:

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

	; Since the app document control processes QUIT in child order, an
	; application can force QUIT to sequence the way it wants.

OLDocumentBringToTop	method dynamic OLDocumentClass, MSG_GEN_BRING_TO_TOP,
							MSG_GEN_LOWER_TO_BOTTOM

	push	ax
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY
	call	GenCallParent
	pop	ax
	jcxz	done

	; set the display not usable

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_display
	mov	si, dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	ret

OLDocumentBringToTop	endm

DocObscure ends
