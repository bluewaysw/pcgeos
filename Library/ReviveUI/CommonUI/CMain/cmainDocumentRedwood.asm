COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainDocumentRM.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLDocument		Open look document class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	9/ 9/93		Made Redwood specific

DESCRIPTION:

	$Id: cmainDocumentRedwood.asm,v 1.8 94/06/29 19:19:45 chris Exp $

------------------------------------------------------------------------------@

DocSaveAsClose segment resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	DocCheckIfOnRamdisk

SYNOPSIS:	Checks to see if document is currently being saved to the
		RAMDisk.

CALLED BY:	FAR

PASS:		*ds:si -- document

RETURN:		zero flag set if current doc path is SP_TOP (i.e. the ramdisk)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/29/93       	Initial version

------------------------------------------------------------------------------@

if UNTITLED_DOCS_ON_SP_TOP

DocCheckIfOnRamdisk	proc	far	uses	ax, bx, cx, dx, di, si, es
	.enter
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData				;ds:bx = GenFilePath

	mov	cx, ds:[bx].GFP_disk
	lea	si, ds:[bx].GFP_path			;ds:si = path string

	mov	dx, SP_TOP				;see if on RAM disk
	mov	di, offset noPath	
	segmov	es, cs

	call	FileComparePaths
						CheckHack <(PCT_EQUAL eq 0)>
	tst	al
	.leave
	ret
DocCheckIfOnRamdisk	endp

noPath		byte	0

endif







COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentQuerySaveDocuments -- 
		MSG_META_QUERY_SAVE_DOCUMENTS for OLDocumentClass

DESCRIPTION:	Queries to save documents for an app switch.  

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_QUERY_SAVE_DOCUMENTS

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/26/93         	Initial Version

------------------------------------------------------------------------------@

if VOLATILE_SYSTEM_STATE

OLDocumentQuerySaveDocuments	method dynamic	OLDocumentClass, \
				MSG_META_QUERY_SAVE_DOCUMENTS

	;
	; Grab the model exclusive.   Doing this means we have to clean things
	; up when we return to the application, so the document with the
	; target gets the model again.   See OLApplicationGainedFullScreenExcl.
	; cbh 8/30/93
	;
;	mov	di, ds:[si]			;no view yet, skip (10/3/93)
;	add	di, ds:[di].Gen_offset		; (doesn't seem to be needed 
;	cmp	{word} ds:[di].GCI_genView, 0	;  now.  10/11/93 cbh)
;	jz	doNothing
	call	MetaGrabModelExclLow		
	clr	bp				;not IACP, at least pretend
						;  not...
	clr	ax				;al non-zero: query-save
	inc	ax				;ah zero: not autosave
	call	SaveAndMaybeClose
	ret

doNothing:
	mov	ax, MSG_OLDG_DOC_MARKED_CLEAN
	call	GenCallParent
	ret

OLDocumentQuerySaveDocuments	endm

endif



COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentWaitForQuery -- 
		MSG_OL_DOCUMENT_WAIT_FOR_QUERY for OLDocumentClass

DESCRIPTION:	Sets OLDA_WAITING_FOR_SAVE_QUERY

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_DOCUMENT_WAIT_FOR_QUERY

RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/27/93         	Initial Version

------------------------------------------------------------------------------@

if VOLATILE_SYSTEM_STATE

OLDocumentWaitForQuery	method dynamic	OLDocumentClass, \
				MSG_OL_DOCUMENT_WAIT_FOR_QUERY

	ornf	ds:[di].OLDI_attrs, mask OLDA_WAITING_FOR_SAVE_QUERY
	ret
OLDocumentWaitForQuery	endm

endif




COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentQueryIfWaiting -- 
		MSG_OL_DOCUMENT_QUERY_IF_WAITING for OLDocumentClass

DESCRIPTION:	If we're waiting for a query, we'll query ourselves, and
		return the carry set.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_DOCUMENT_QUERY_IF_WAITING

RETURN:		carry set if we did a query
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/27/93         	Initial Version

------------------------------------------------------------------------------@

if VOLATILE_SYSTEM_STATE

OLDocumentQueryIfWaiting	method dynamic	OLDocumentClass, \
				MSG_OL_DOCUMENT_QUERY_IF_WAITING

	test	ds:[di].OLDI_attrs, mask OLDA_WAITING_FOR_SAVE_QUERY
	jz	exit				;not waiting, exit (c=0)

	and	ds:[di].OLDI_attrs, not mask OLDA_WAITING_FOR_SAVE_QUERY

	mov	ax, MSG_META_QUERY_SAVE_DOCUMENTS
	call	ObjCallInstanceNoLock
	stc
exit:
	ret
OLDocumentQueryIfWaiting	endm

endif


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

if VOLATILE_SYSTEM_STATE

OLDocumentClose	method dynamic OLDocumentClass, MSG_GEN_DOCUMENT_CLOSE

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDI_attrs
	test	ax, mask GDA_CLOSING
	jz	notClosing
exit:
	mov	cx, DQS_CANCEL
	Destroy	ax, dx, bp
	ret

notClosing:
	clr	ax				;do normal close
	call	SaveAndMaybeClose
	ret

OLDocumentClose	endm

endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	SaveAndMaybeClose

SYNOPSIS:	Saves the document, then closes if desired.

CALLED BY:	OLDocumentClose, OLDocumentQuerySave

PASS:		*ds:si -- OLDocumentClass
		al -- zero if we're supposed to always close (original
		      function of this code).   Non-zero if we're just saving
		      or deleting, as we switch apps in Redwood
		ah -- non-zero if doing autosave
		bp -- IACP connection (0 if user)

RETURN:		cx - DocQuitStatus 
		     (DQS_OK, DQS_DELAYED, DQS_CANCEL, DQS_SAVE_ERROR)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if always closing (al = 0, ah = 0)
		put up message whether user should save the file;
		if yes
			save the file
		close the file

	elseif switching apps in redwood (al = 1, ah = 0)
		if previously saved file (not on ramdisk)
			resave
		else
			put up message whether user should save or delete file
			if yes
				save the file
			else
				delete the file

	elseif autosaving in Redwood (al = 1, ah = 1)
		put up message whether user should save or close file
		if yes
			save the file
		else
			close the file

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/23/93       	Initial version

------------------------------------------------------------------------------@

if VOLATILE_SYSTEM_STATE

SaveAndMaybeClose	proc	far
	tst	bp
	LONG jnz	iacpClose

doClose:
	push	bp
	push	ax

	mov	bx, ax			;we'll keep the flag in bx for awhile

	mov	ax, GDO_CLOSE
	call	OLDocSetOperation


	; check for dirty

	call	OLDocumentGetAttrs
	tst	bx			;don't set close bit if not closing
					;   7/26/93 cbh
	jnz	doneWithCloseBit

	ornf	ax, mask GDA_CLOSING
doneWithCloseBit:

	mov	ds:[di].GDI_attrs, ax
	test	ax, mask GDA_DIRTY
	LONG jz	cleanOnEntry

	; --- the file is dirty (has been modified)

	; if transparent mode then always save changes
	push	es, ax
	segmov	es, dgroup, ax			;es = dgroup
	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	pop	es, ax
	jz	testIACP

	; if confirm save mode, bring up dialog	

	push	es, ax
	segmov	es, dgroup, ax
	test	es:[docControlOptions], mask DCO_USER_CONFIRM_SAVE
	pop	es, ax
	jz	saveChanges
	jmp	clean

testIACP:
	; if IACP close, same as transparent mode

	tst	bp
	jnz	saveChanges

	; if "save" has failed before then don't ask, just try to save changes

	test	ax, mask GDA_SAVE_FAILED
	jnz	saveChanges

	push	ax
	call	GetUIParentAttrs
	test	ax, mask GDCA_DO_NOT_SAVE_FILES
	pop	ax
	LONG jnz revertClose

	mov_tr	cx, ax

	mov	ax, SDBT_FILE_CLOSE_ATTACH_DIRTY
	test	cx, mask GDA_ATTACH_TO_DIRTY_FILE
	jnz	normalDirty

	mov	ax, SDBT_FILE_CLOSE_SAVE_CHANGES_UNTITLED
	test	cx, mask GDA_UNTITLED
	jnz	checkRedwoodFlags
	mov	ax, SDBT_FILE_CLOSE_SAVE_CHANGES_TITLED

checkRedwoodFlags:
	tst	bl				;see if doing app switch here
						; (no close)  6/23/93 cbh
	jz	normalDirty			;not doing app switch...

	add	ax, SDBT_QUERY_SAVE_ON_APP_SWITCH_UNTITLED - \
	 	    SDBT_FILE_CLOSE_SAVE_CHANGES_UNTITLED

;if AUTOSAVE_BASED_ON_DIRTY_BLOCKS
if	0		;not needed anymore
	tst	bh
	jz	normalDirty

	add	ax, SDBT_QUERY_AUTOSAVE_UNTITLED - \
		    SDBT_QUERY_SAVE_ON_APP_SWITCH_UNTITLED
endif

normalDirty:

PMAN <	push	ax, bp				;bring application to 	>
PMAN <	mov	ax, MSG_GEN_BRING_TO_TOP	; top so dialog will	>
PMAN <	call	UserCallApplication		; not come up hidden	>
PMAN <	pop	ax, bp				; behind other windows	>

	call	FarCallStandardDialogDS_SI

	cmp	ax, IC_NULL			;null -> abort
	LONG jz	cancel
	cmp	ax, IC_DISMISS			;cancel -> abort
	LONG jz	cancel
	cmp	ax, IC_NO			;no -> revert
	LONG	jz	revertClose
EC <	cmp	ax, IC_YES						>
EC <	ERROR_NE	OL_ERROR					>

	; check for temporary file, if so then do a "save as"

saveChanges:

	;
	; We're changing the check here to do a save-as if the document is
	; currently on the RAM drive.   This catches geodex style documents
	; being initially opened on the RAM drive, but aren't technically
	; untitled.  For Redwood 7/30/93.
	;
if UNTITLED_DOCS_ON_SP_TOP
	call	DocCheckIfOnRamdisk
	LONG	jz	temporary
else
	test	ds:[di].GDI_attrs, mask GDA_UNTITLED
	LONG jnz temporary
endif

	test	ds:[di].GDI_attrs, mask GDA_READ_ONLY
	LONG jnz readOnly

reallySaveChanges:
	; save the changes...

	call	IsFileDirty
	jnc	retrySave
	mov	cx, TRUE			; about to save, not update
	mov	ax, MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE
	call	ObjCallInstanceNoLock
retrySave:
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_SAVE
	call	ObjCallInstanceNoLock		;returns error in carry
	jnc	clean
	call	ConvertErrorCode
	cmp	ax, ERROR_SHORT_READ_WRITE
	jz	diskFull
handleOtherError:
	mov	cx, offset CallStandardDialogDS_SI
	call	HandleSaveError
	jnc	retrySave
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

	pop	ax
	pop	bp
	mov	ax, MSG_OL_DOCUMENT_CONTINUE_CLOSE_AFTER_DISK_FULL
	call	OLDocumentShowLowDiskError
	mov	ax, DQS_DELAYED
	jmp	exit

	; actually close the file

cleanOnEntry:

if UNTITLED_DOCS_ON_SP_TOP
	;
	; Our document was clean on entry.   If we're on a Ramdisk, we're
	; probably a new, undirtied document (i.e. nothing is in it), or
	; I'm a hoser.   Let's delete the thing.
	;
	call	DocCheckIfOnRamdisk		;not on ramdisk, branch
	jnz	clean
	pop	ax
	clr	al				;else ensure it's closed
	push	ax
endif

clean:
	; If we got here, lets assume somehow we've marked the document
	; clean.   This should catch the non-standard save cases that I've
	; missed.  7/26/93 cbh  (Doesn't actually seem to mark the document
	; clean, apparently because it was closing anyway in the old version.
	; I'll do so here.  7/27/93 cbh)

	call	markCleanTellDocGroupReallyQueued

	mov	ax, MSG_OLDC_TEST_FOR_DISPLAY_MAIN_DIALOG
	call	SendToDocumentControl
closeCommon:
	mov	cx, DQS_OK
done:
	pop	ax	
	pop	bp
	tst	ax				;not supposed to close, branch
	jnz	afterClose
	call	OLDocumentSendCloseAck

afterClose:
	call	OLDocClearOperation
exit:
	Destroy	ax, dx, bp
	ret

	; close without saving changes

revertClose:

	;
	; For switch-apps mode only (al != 0):
	; If an untitled document, we'll delete it and close.   If a titled
	; document, we`ll revert it and not close.   Set ax appropriately for
	; this.   (cbh 12/16/93)
	;
if UNTITLED_DOCS_ON_SP_TOP
	call	DocCheckIfOnRamdisk		;not on ramdisk, branch
	jnz	doRevert
else
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_UNTITLED
	jz	doRevert
endif

	pop	ax
	clr	al				;else ensure it's closed
	push	ax

doRevert:
	;
	; Tell OLDocumentRemoveConnection to revert before it closes the
	; file.   
	; 
	pop	ax	

	tst	ax				;not closing file?  revert only
	jnz	revertNoClose
	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLDI_attrs, mask OLDA_REVERT_BEFORE_CLOSE

	mov	cx, DQS_OK
	pop	bp

	call	OLDocumentSendCloseAck

	call	markCleanTellDocGroupQueued	;moved here 5/ 8/94
	jmp	afterClose

revertNoClose:
	pop	bp
	;
	; Experiment with marking busy
	;
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	UserCallApplication

	mov	ax, MSG_GEN_DOCUMENT_REVERT_NO_PROMPT
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	UserSendToApplicationViaProcess
	
	;
	; For Redwood, we could mark clean and notify the doc group here,
	; but it will be better to do it at the end of the true revert.
	; 5/ 8/94 cbh
	;
	jmp	afterClose

	; user said CANCEL

cancel:
	mov	cx, DQS_CANCEL
cancelWithCode:
	;
	; Cancelling, make sure any query-result message is cleaned out of
	; the system, so that the result message isn't called later on
	; for some other reason.  3/30/94 cbh
	;
	push	cx, dx, bp
	clr	cx
	mov	ax, MSG_META_QUERY_SAVE_DOCUMENTS
	call	GenCallParent			;sending to app control is
						;  sufficient to clear out
						;  return message
	pop	cx, dx, bp

	clr	ax				;bits to set
	mov	bx, mask GDA_CLOSING		;bits to clear
	call	OLDocSetAttrs
	jmp	done

	; closing a read-only or public file -- if transparent mode then
	; discard changes

readOnly:
	call	GetDocOptions
	test	ax, mask DCO_TRANSPARENT_DOC
	jnz	revertClose

	; closing a temporary file -- do a save as

temporary:
	tst	bp
	jnz	temporaryIACP

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
	LONG jne	closeCommon	; won't actually be closed yet, so
					;  do nothing
	jmp	doClose

;------------------------------------------------------------

markCleanTellDocGroupQueued:
	clr	ax					;set clean
	mov	bx, mask GDA_DIRTY
	call	OLDocSetAttrs

	push	si
	mov	ax, MSG_OLDG_DOC_MARKED_CLEAN
	call	GenFindParent
	mov	di, mask MF_FORCE_QUEUE		;queue it, get doc deleted 1st
	call	ObjMessage			;  (cbh 11/12/93)
	pop	si
	retn

;------------------------------------------------------------

markCleanTellDocGroupReallyQueued:
	clr	ax					;set clean
	mov	bx, mask GDA_DIRTY
	call	OLDocSetAttrs

	push	si
	mov	ax, MSG_OLDG_DOC_MARKED_CLEAN
	call	GenFindParent

	mov	di, mask MF_RECORD
	call	ObjMessage
	push	cx, dx, bp
	mov	cx, di			; message to send after flush
	;
	; Attempt to really slow down this process, after all current
	; messages are flushed.
	;
	mov	dx, bx			; pass a block owned by process
	mov	bp, OFIQNS_INPUT_OBJ_OF_OWNING_GEODE	; app obj is next stop
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	mov	di, mask MF_RECORD	; Flush through a second time
	call	ObjMessage		; wrap up into event
	mov	cx, di			; event in cx

					; dx is already block owned by process
					; bp is next stop
					; ax is message
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; Finally, send this after a flush
	pop	cx, dx, bp
	pop	si
	retn

SaveAndMaybeClose	endp

endif


DocSaveAsClose ends
