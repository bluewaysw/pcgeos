COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainDocumentCommon.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLDocument		Open look document class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cmainDocument.asm

DESCRIPTION:

	$Id: cmainDocumentCommon.asm,v 1.17 95/10/11 10:53:44 adam Exp $

------------------------------------------------------------------------------@
DocCommon segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGetFileName -- MSG_GEN_DOCUMENT_GET_FILE_NAME for
					OLDocumentClass

DESCRIPTION:	Get the document's file name, without its leading path

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_GET_FILE_NAME
	cx:dx - buffer for name (FileLongName)

RETURN:
	cx, dx, bp - unchanged

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
OLDocumentGetFileName	method dynamic OLDocumentClass,
					MSG_GEN_DOCUMENT_GET_FILE_NAME
						uses cx
	.enter

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	si, ds:[di].GDI_fileName

	mov	es, cx
	mov	di, dx				;es:di = dest

	mov	cx, size FileLongName / 2
	rep	movsw

	.leave
	ret

OLDocumentGetFileName	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDocSetOperation

DESCRIPTION:	Set the operation being performed

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax - GenDocumentOperation

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
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
OLDocSetOperation	proc	far	uses di
	class	OLDocumentClass
	.enter

EC <	call	AssertIsGenDocument					>

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	mov	ds:[di].GDI_operation, ax

	.leave
	ret

OLDocSetOperation	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDocClearOperation

DESCRIPTION:	Clear the operation being performed

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	none

DESTROYED:
	none (flags preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
OLDocClearOperation	proc	far	uses ax
	class	OLDocumentClass
	.enter
	pushf

	clr	ax
	call	OLDocSetOperation

	popf
	.leave
	ret

OLDocClearOperation	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendPhysicalCloseOnQueue

DESCRIPTION:	Send a MSG_GEN_DOCUMENT_PHYSICAL_CLOSE to ourself via the
		queue

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenDocument object

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/30/91		Initial version

------------------------------------------------------------------------------@
SendPhysicalCloseOnQueue	proc	far
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_CLOSE
	FALL_THRU	SendToSelfOnQueue
SendPhysicalCloseOnQueue	endp

SendToSelfOnQueue	proc	far
EC <	call	AssertIsGenDocument					>

	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage
SendToSelfOnQueue	endp

SendPhysicalDeleteOnQueue	proc	far
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_DELETE
	GOTO	SendToSelfOnQueue
SendPhysicalDeleteOnQueue	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentSave -- MSG_GEN_DOCUMENT_SAVE for OLDocumentClass

DESCRIPTION:	Save a file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_SAVE

RETURN:
	carry - set if error

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
OLDocumentSave	method dynamic OLDocumentClass, MSG_GEN_DOCUMENT_SAVE

	call	OLDocMarkBusy

	mov	ax, GDO_SAVE
	call	OLDocSetOperation

	mov	cx, TRUE
	call	WriteCachedData
retrySave:
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_SAVE
	call	ObjCallInstanceNoLock
	jnc	noError

	; if the error is that the disk is not available then don't mark
	; the save as failed, since we know that the file is still in
	; a consistent state.  This allows the user to discard changes
	; on CLOSE.

	cmp	ax, ERROR_DISK_UNAVAILABLE
	jz	dontMarkSaveFailed

	call	ConvertErrorCode
	mov	cx, offset CallStandardDialogDS_SI
	call	HandleSaveError
	jnc	retrySave

	mov	ax, mask GDA_SAVE_FAILED	;mark that save failed
	clr	bx
	call	OLDocSetAttrs
dontMarkSaveFailed:
	stc
done:
	call	OLDocClearOperation
	Destroy	ax, cx, dx, bp

	call	OLDocMarkNotBusy
	ret

noError:
	call	SetCleanAndUpdate
	clc
	jmp	done

OLDocumentSave	endm

;---

SetCleanAndUpdate	proc	far
EC <	call	AssertIsGenDocument					>
	pushf
	clr	ax						;bits to set
	mov	bx, mask GDA_DIRTY or mask GDA_ATTACH_TO_DIRTY_FILE or \
			mask GDA_SAVE_FAILED			;bits to clear
	call	OLDocSetAttrs
	mov	bx, 1				;not losing target
	call	SendNotificationToDC
	popf
	ret
SetCleanAndUpdate	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDocMarkBusy

DESCRIPTION:	Mark the app as busy

CALLED BY:	INTERNAL

PASS:	*ds:si - instance data of doc obj
	none

RETURN:
	none

DESTROYED:
	none, preserves flags

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/10/92		Initial version

------------------------------------------------------------------------------@
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
OLDocMarkBusy	proc	far
	uses	di
	.enter
	pushf
EC <	call	AssertIsGenDocument					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	inc	ds:[di].OLDI_busyCount
	call	OLDocMarkBusyOnly
	popf
	.leave
	ret
OLDocMarkBusy	endp

OLDocMarkBusyOnly	proc	far	uses ax, cx, dx, bp
else
OLDocMarkBusy	proc	far	uses ax, cx, dx, bp
endif
	.enter
	pushf
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication
	popf
	.leave
	ret
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
OLDocMarkBusyOnly	endp
else
OLDocMarkBusy	endp
endif

if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
OLDocMarkNotBusy	proc	far
	uses	di
	.enter
	pushf
EC <	call	AssertIsGenDocument					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	dec	ds:[di].OLDI_busyCount
	call	OLDocMarkNotBusyOnly
	popf
	.leave
	ret
OLDocMarkNotBusy	endp

OLDocMarkNotBusyOnly	proc	far	uses ax, bx, cx, dx, bp, di
else
OLDocMarkNotBusy	proc	far	uses ax, bx, cx, dx, bp, di
endif
	.enter
	pushf
	push	si
	clr	bx
	call	GeodeGetAppObject

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di

	mov	dx, bx			; pass a block owned by process
	mov	bp, OFIQNS_INPUT_OBJ_OF_OWNING_GEODE	; app obj is next stop
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE

;	mov	di, mask MF_RECORD	; Flush through a second time
;	call	ObjMessage		; wrap up into event
;	mov	cx, di			; event in cx

					; dx is already block owned by process
					; bp is next stop
					; ax is message
	pop	si
	call	ObjCallInstanceNoLock	; Finally, send this after a flush

	popf
	.leave
	ret
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
OLDocMarkNotBusyOnly	endp
else
OLDocMarkNotBusy	endp
endif

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentMarkDirty -- MSG_GEN_DOCUMENT_MARK_DIRTY for
					OLDocumentClass

DESCRIPTION:	Mark the document as dirty

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_MARK_DIRTY

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
OLDocumentMarkDirty	method dynamic OLDocumentClass,
					MSG_GEN_DOCUMENT_MARK_DIRTY
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDI_attrs
	test	ax, mask GDA_DIRTY
	jnz	done

	; shared multiple files never really get dirty

	test	ax, mask GDA_SHARED_MULTIPLE
	jnz	done

	ornf	ds:[di].GDI_attrs, mask GDA_DIRTY

	; update UI stuff

	mov	bx, 1				;not losing target
	call	SendNotificationToDC

done:
	Destroy	ax, cx, dx, bp
	ret

OLDocumentMarkDirty	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentAutoSaveTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle notification that our auto save timer has
		fired.  Send MSG_GEN_DOCUMENT_AUTO_SAVE to self,
		unless we can't.

PASS:		*ds:si	- OLDocumentClass object
		ds:di	- OLDocumentClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLDocumentAutoSaveTimer	method	dynamic	OLDocumentClass, 
					MSG_OL_DOCUMENT_AUTO_SAVE_TIMER

		clr	ds:[di].OLDI_autoSaveTimer

		mov	ax, MSG_GEN_DOCUMENT_AUTO_SAVE
		GOTO	ObjCallInstanceNoLock 

OLDocumentAutoSaveTimer	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentAutoSave -- MSG_GEN_DOCUMENT_AUTO_SAVE for
					OLDocumentClass

DESCRIPTION:	Auto save the file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_AUTO_SAVE

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@


OLDocumentAutoSave	method dynamic OLDocumentClass,
					MSG_GEN_DOCUMENT_AUTO_SAVE


if FLOPPY_BASED_DOCUMENTS or LIMITED_UNTITLED_DOC_DISK_SPACE

	; First check is to avoid the UI document control doing as save as.
	
	call	CheckIfDocCtrlDoingSaveAs
	jnc	continueOn			;nope, continue
	clr	cx
	jmp	restartTimer			;restart timer (c=0)
continueOn:
endif

	; See if we should really auto-save

	call	OLDocumentGetAttrs
	test	ax, mask GDA_CLOSING or mask GDA_AUTO_SAVE_STOPPED or \
		    mask GDA_READ_ONLY
	LONG	jnz	exit			;if closing do nothing (CF = 0)

	; if we're in the middle of some operation then exit

	clr	cx				;if doing something, skip 
						;auto-save this time 'round
	cmp	ds:[di].GDI_operation, GDO_NORMAL
	clc
	LONG	jnz	restartTimer		;c=0
	mov	cx, 60				;if busy try again in a second
	test	ds:[di].GDI_attrs, mask GDA_PREVENT_AUTO_SAVE
	LONG	jnz	restartTimer		;if aborting, try again(CF = 0)
	
if	_NIKE
	; If we are printing, try again in 5 seconds (seems like a reasonable
	; timeframe to me). We do this so that the user is constantly not
	; pestered that s/he has a large untitled document or a document
	; that exceeds the system's size limits. -Don 6/3/95
	;
	mov	cx, 60 * 5			;5 seconds
	call	CheckIfSystemPrinting
	LONG	jc	restartTimer
endif


if LIMITED_UNTITLED_DOC_DISK_SPACE
	;
	; If document is not on the ramdisk (i.e. has been saved before),
	; don't do this stuff!  2/21/94 cbh  Except for things that have
	; demand paging forced, we'll do this dirty block check only.
	; 3/12/94 cbh
	;
	call	GetUIParentAttrs
	test	ax, mask GDCA_FORCE_DEMAND_PAGING
	jnz	checkDirtyForAnyDoc

if UNTITLED_DOCS_ON_SP_TOP
	call	DocCheckIfOnRamdisk		;not on ramdisk, branch
	jne	tryAgainCarryClear
else
	call	OLDocumentGetAttrs
	test	ax, mask GDA_UNTITLED
	je	tryAgainCarryClear
endif

checkDirtyForAnyDoc:

	call	CheckForDirtyDoc		;dirty size in dx.cx

	; If not many blocks are dirty, don't save!  

	tst	dx
	jne	pastAutosaveThreshold
	cmp	cx, UNTITLED_MAX_SIZE
	jb	tryAgainCarryClear		;not much dirty, try again

pastAutosaveThreshold:

	; We're going to do the auto-save, type thing.  Set the operation type.
	
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDI_operation, GDO_AUTO_SAVE

	mov	ax, SDBT_QUERY_AUTOSAVE_TITLED
	call	DocCheckIfOnRamdisk		;not on ramdisk, branch
	jne	putupErrorBox
	mov	ax, SDBT_QUERY_AUTOSAVE_UNTITLED
if _NIKE
	;
	; We are here because an untitled doc exceeded the autosave
	; threshhold. We want the user to save the doc to floppy, so
	; that the document can be reverted to its last autosaved version
	; if something goes awry (as in GeoWrite when too many pages are
	; created).  cassie 4/25/95
	;
	mov	ds:[di].GDI_operation, GDO_SAVE_AS
endif
putupErrorBox:
	call	FarCallStandardDialogDS_SI

tryAgainCarryClear:
	clr	cx				;start with standard time
						;possibly fall through to
						;  check total file size, too
						;(c=0, no error)

afterDirtyBlocks:

endif

if FLOPPY_BASED_DOCUMENTS 
	;
	; Don't do this check for demand-paging documents.  3/12/94 cbh
	;
	call	GetUIParentAttrs
	test	ax, mask GDCA_FORCE_DEMAND_PAGING
	jnz	resetNormal

	mov	ax, MSG_OLDG_GET_TOTAL_SIZE	;get total size of current docs 
	call	GenCallParent			; in dx.cx
	cmpdw	dxcx, MAX_TOTAL_FILE_SIZE	;have things gotten out of hand?
	mov	cx, 0				;assume not , use auto
						;     save stuff again
	jb	resetNormal			;
	tst	bp				;if a dialog is gone off already
	jnz	resetNormal			;  then don't do another one

	; We're going to do the auto-save.  Set the operation type.
	
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDI_operation, GDO_AUTO_SAVE

	mov	ax, SDBT_AUTOSAVE_TOTAL_FILES_TOO_LARGE
	call	FarCallStandardDialogDS_SI

resetNormal:
	clr	cx				;restart with standard time
						; (c=0)
endif

;;;		
;;; This conditional is being removed because adam and tony's recent changes
;;; have made saving to floppy much faster, and we want autosave to work on
;;; Nike. (cassie 3/21/95)
;;;
;;;if (not LIMITED_UNTITLED_DOC_DISK_SPACE) and \
;;;   (not FLOPPY_BASED_DOCUMENTS)

if _NIKE
	;
	; save the current operation - it may be "save as"
	;
	push	ds:[di].GDI_operation
endif
	; We're going to do the auto-save.  Set the operation type.
		
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDI_operation, GDO_AUTO_SAVE

	; Do the actual update work

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication

if (not _JEDIMOTIF)	; always update for JEDI
	; if transparent mode then do a save (since there is no point in
	; auto-save)
	push	es	
	segmov	es, dgroup, ax			;es = dgroup
	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	pop	es
	jz	notTransparent
	push	es
	segmov	es, dgroup, ax
	test	es:[docControlOptions], mask DCO_USER_CONFIRM_SAVE
	pop	es
	mov	ax, MSG_GEN_DOCUMENT_SAVE
	jz	gotMessage
notTransparent:
endif
	mov	ax, MSG_GEN_DOCUMENT_UPDATE
gotMessage:
	call	ObjCallInstanceNoLock

if _JEDIMOTIF
	;
	; If disk full error, queue up a close and flag
	; as auto-save error so a Save As dialog for an untitled
	; document will not have the "Cancel" trigger.  The flag
	; is cleared in SAVE_AS_CANCELLED (which won't happen since
	; there'll be no "Cancel" trigger), if the document is destroyed
	; (for "Don't Save" option), or in the SAVE_AS handler.
	;
	jnc	notDiskFull
	cmp	ax, ERROR_SHORT_READ_WRITE
	jne	notDiskFullError
	mov	ax, TEMP_OL_DOCUMENT_NO_DISK_SPACE_MESSAGE
	call	ObjVarFindData
	jc	notDiskFullError		;already doing disk-full
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLDI_attrs, mask OLDA_AUTO_SAVE_ERROR
	mov	ax, MSG_GEN_DOCUMENT_CLOSE	;ax can be trashed now
	mov	bp, 0				;user close
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
notDiskFullError:
	stc					;indicate error
notDiskFull:
endif

	pushf					;preserve the flags
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication
	clr	cx				;start with standard time
	popf					;restore the flags
;;;endif

if _NIKE
	;
	; If the untitled doc exceed max untitled size, put up
	; save as dialog before returning
	;
	pop	ax
	cmp	ax, GDO_SAVE_AS
	je	saveAs

resetOperation:

endif		
	; Reset the operation type to GDO_NORMAL.
	
	lahf					; Preserve the carry
						; in ah.

	mov	di, ds:[si]			; Deref the thing, as
	add	di, ds:[di].Gen_offset		; it might've moved.
	mov	ds:[di].GDI_operation, GDO_NORMAL ; Reset the old type.

	sahf					; Recover the carry
						; from ah.
		
restartTimer:
	pushf					;again preserve flags

	; 10/3/95: check to see autosave is supported. If it's not didn't,
	; we don't want one now. Need this check because various things
	; call GEN_DOCUMENT_AUTO_SAVE (the temp-async VM stuff, when we
	; lose the model exclusive, to name two), not just AUTO_SAVE_TIMER.
	; We do the restart here, rather than AUTO_SAVE_TIMER, to cope with
	; the Nike-specific code above that sleeps while printing -- ardeb

	call	GetParentAttrs
	test	ax, mask GDGA_SUPPORTS_AUTO_SAVE
	jz	timerDone

	mov	dx, offset OLDI_autoSaveTimer
	call	StartATimer			;time in CX
timerDone:
	popf					;and restore the flags
exit:
	Destroy	ax, cx, dx, bp
	ret

if _NIKE

saveAs:

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC
	call	SendToDocumentControl
	stc
	jmp	resetOperation

endif
OLDocumentAutoSave	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForDirtyDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check whether doc is dirty, and if a VM file, get
		the size of the dirty blocks.

CALLED BY:	OLDocumentAutoSave
PASS:		ds:di - document instance data
RETURN:		dx.cx = dirty size
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/12/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if LIMITED_UNTITLED_DOC_DISK_SPACE

CheckForDirtyDoc		proc	near
	.enter

	call	GetUIParentAttrs
	test	ax, mask GDCA_VM_FILE
	jz	notVMFile

	mov	bx, ds:[di].GDI_fileHandle
	call	VMGetDirtySize			;dirty size in dx.cx
done:
	.leave
	ret

notVMFile:
	;
	; If not a VM file, returning dx non-zero if it is dirty will
	; make the caller believe that we are past the autosave threshhold.
	;
	mov	dx, 1				;assume its dirty
	test	ds:[di].GDI_attrs, mask GDA_DIRTY
	jnz	done
	dec	dx				;return dx.cx = 0 if clean
	mov	cx, dx
	jmp	done
		
CheckForDirtyDoc		endp

endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfDocCtrlDoingSaveAs

SYNOPSIS:	Checks to see if the (grandparent) document control is
		currently doing a save-as.

CALLED BY:	OLDocumentAutoSave

PASS:		*ds:si -- OLDocument

RETURN:		carry set if parent is doing a save as

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/26/94       	Initial version

------------------------------------------------------------------------------@

if FLOPPY_BASED_DOCUMENTS or LIMITED_UNTITLED_DOC_DISK_SPACE

CheckIfDocCtrlDoingSaveAs	proc	near

	push	si
	mov	si, offset GenDocumentControlClass
	mov	bx, segment GenDocumentControlClass
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	pop	si

	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent

	;
	; DocumentControlAttrs in ax, check task.
	;
	and 	ax, mask GDCA_CURRENT_TASK
	cmp	ax, GDCT_SAVE_AS shl offset GDCA_CURRENT_TASK
	clc	
	jne	exit				;no match, exit
	stc					;else return carry set
exit:
	ret
CheckIfDocCtrlDoingSaveAs	endp

endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfSystemPrinting

SYNOPSIS:	Checks to see if the system is printing

CALLED BY:	OLDocumentAutoSave

PASS:		nothing

RETURN:		carry set if system is printing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/3/95       	Initial version

------------------------------------------------------------------------------@

if _NIKE

spoolGeodeName		char	"spool   "
faxSpoolGeodeName	char	"faxspool"

CheckIfSystemPrinting	proc	near
	uses	ax, cx, dx, di, es
	.enter

	;
	; First, check to see if we are in the middle of faxing. On
	; NIKE, the faxspool library is only loaded if we are faxing,
	; so we can just check for its existence and return carry set
	; if we find it (which conveniently is what GeodeFind returns).
	;
	segmov	es, cs
	mov	di, offset faxSpoolGeodeName
	mov	ax, length faxSpoolGeodeName
	clr	cx, dx
	call	GeodeFind
	jc	done				; geode found, so we're done

	;
	; First find the spool geode. We do this, instead of always
	; loading the library, as we don't want the specUI dependent
	; upon the spooler.
	;
	mov	di, offset spoolGeodeName
	mov	ax, length spoolGeodeName
	call	GeodeFind
	jnc	done

	;
	; Now see if anything is printing
	;
	mov	ax, 24				; offset SpoolInfo
	call	ProcGetLibraryEntry
	mov	cx, SIT_QUEUE_INFO
	mov	dx, -1				; jsut see if we are printing
	call	ProcCallFixedOrMovable
	cmp	ax, SPOOL_QUEUE_NOT_EMPTY
	clc
	jne	done
	stc					; yes, we're printing	
done:
	.leave
	ret
CheckIfSystemPrinting	endp

endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentAddSizeToTotal -- 
		MSG_OL_DOCUMENT_ADD_SIZE_TO_TOTAL for OLDocumentClass

DESCRIPTION:	Adds size to the total.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_DOCUMENT_ADD_SIZE_TO_TOTAL
		dx.cx	- running total
		bp	- non-zero if we've put up a "file too large" message

RETURN:		dx.cx 	- updated, adding file size
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	1/16/94         	Initial Version

------------------------------------------------------------------------------@

if FLOPPY_BASED_DOCUMENTS

OLDocumentAddSizeToTotal	method dynamic	OLDocumentClass, \
				MSG_OL_DOCUMENT_ADD_SIZE_TO_TOTAL
	pushdw	dxcx
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_fileHandle
	clr	ax				;in case bx=0, bx.ax=size=0
	tst	bx				;no handle yet, get out!
	jz	exit	

	;	
	; The last line of GetParentAttrs is - 
	; test	ax, mask GDGA_VM_FILE, so we are going to take advantage of
	; that test here to see if we are finding the size of a VMfile
	; or a non-vm file.
	;
	call	GetParentAttrs			
	jnz	getVMFileSize
	
	call	FileSize	
	jmp	gotSize
getVMFileSize:
	call	VMGetUsedSize			;size in dx.cx
	mov	ax, cx				;now in dx.ax
gotSize:

	;
	; While we're here, if this document's file size is too large, we'll
	; put up an individual error box for that file only.
	;
	cmpdw	dxax, MAX_TOTAL_FILE_SIZE
	jb	10$

	push	ax
	mov	ax, SDBT_AUTOSAVE_FILE_TOO_LARGE
	call	FarCallStandardDialogDS_SI
	pop	ax
	dec	bp				;set file-too-large flag
10$:

	mov	bx, dx				;now bx.ax
exit:
	popdw	dxcx
	adddw	dxcx, bxax
	ret
OLDocumentAddSizeToTotal	endm

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	StartATimer

DESCRIPTION:	Start a timer (either auto-save or change notification)

CALLED BY:	StartAutoSave

PASS:
	*ds:si - GenDocument object
	cx - time (or 0 to fetch it)
	dx - offset of field: OLDI_autoSaveTimer or OLDI_changeTimer

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 7/91		Initial version

------------------------------------------------------------------------------@
StartATimer	proc	far
	class	OLDocumentClass

EC <	call	AssertIsGenDocument					>

	call	OLDocumentGetAttrs
	test	ax, mask GDA_AUTO_SAVE_STOPPED
	jnz	exit
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	di, dx

	; if timer already started, don't start another

	tst	<{word} ds:[di]>
	jnz	exit

	; get timer interval

	tst	cx
	jnz	gotTime
	call	GetTimerInterval
	jcxz	exit

gotTime:
	cmp	dx, offset OLDI_autoSaveTimer
	mov	dx, MSG_OL_DOCUMENT_AUTO_SAVE_TIMER
	je	gotMessage
	mov	dx, MSG_GEN_DOCUMENT_CHECK_FOR_MODIFICATIONS
gotMessage:
	mov	ax, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[LMBH_handle]
	call	TimerStart
	mov	ds:[di], bx
	mov	ds:[di+2], ax
exit:
	ret

StartATimer	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetTimerInterval

DESCRIPTION:	Get the auto-save or change time from the .ini file

CALLED BY:	StartAutoSaveLow

PASS:
	*ds:si - object
	dx - offset of field: OLDI_autoSaveTimer or OLDI_changeTimer

RETURN:
	cx - auto-save time

DESTROYED:
	ax, bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
GetTimerInterval	proc	near	uses dx, si, ds
	.enter

EC <	call	AssertIsGenDocument					>

	segmov	ds, cs
	mov	si, offset uiCategory		;ds:si = category
	mov	cx, cs

	cmp	dx, offset OLDI_changeTimer
	mov	dx, offset changeTimeKey	;cx:dx = key
	jz	getValue

	mov	dx, offset autoSaveKey		;cx:dx = key
	call	InitFileReadBoolean		;ax = value
	jc	useDefaultValue
	tst	ax
	jz	noAutoSave

	mov	dx, offset autoSaveTimeKey
getValue:
	call	InitFileReadInteger		;ax = value
	jnc	existsInIniFile

useDefaultValue:
	mov	cx, 3600
done:
	.leave
	ret

noAutoSave:
	clr	cx
	jmp	done

existsInIniFile:
	tst	ax
	jz	useAX
	cmp	ax, 65535/60			;maximum
	jl	afterMax
	mov	ax, 65535/60
afterMax:
	mov	cx, 60
	mul	cx
useAX:
	mov_trash	cx, ax
	jmp	done

GetTimerInterval	endp

uiCategory	char	"ui", 0
autoSaveKey	char	"autosave", 0
autoSaveTimeKey	char	"autosaveTime", 0
changeTimeKey	char	"changePollTime", 0

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentUpdate -- MSG_GEN_DOCUMENT_UPDATE for OLDocumentClass

DESCRIPTION:	Flush changes to the document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	carry - set if error
	ax - error code

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/11/92		Initial version

------------------------------------------------------------------------------@
OLDocumentUpdate	method dynamic	OLDocumentClass, MSG_GEN_DOCUMENT_UPDATE

	clr	cx		; not saving
	call	WriteCachedData
	jnc	done
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_UPDATE
	call	ObjCallInstanceNoLock
	jnc	clearSaveFailed

	; if the error is that the disk is not available then don't mark
	; the save as failed, since we know that the file is still in
	; a consistent state.  This allows the user to discard changes
	; on CLOSE.

	cmp	ax, ERROR_DISK_UNAVAILABLE
	jz	dontMarkSaveFailed

	; Let user know all is not good in this here state o' Denmark...

	mov	cx, offset CallStandardDialogDS_SI
	call	ConvertErrorCode
	push	ax				;save converted error code
	call	HandleSaveError
	mov	ax, mask GDA_SAVE_FAILED	;mark that save failed
	clr	bx
	call	OLDocSetAttrs
	pop	ax				;restore error code
dontMarkSaveFailed:
	stc
done:
	ret

clearSaveFailed:
	clr	ax
	mov	bx, mask GDA_SAVE_FAILED
	call	OLDocSetAttrs
	clc
	jmp	done
OLDocumentUpdate	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	IsFileDirty

DESCRIPTION:	Determine if the file is dirty

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	carry - set if dirty

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/21/92		Initial version

------------------------------------------------------------------------------@
IsFileDirty	proc	far	uses ax, bx
	.enter

	call	GetParentAttrs
	jnz	vmFile

	; file is not a VM file -- look at the dirty bit

	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GDI_attrs, mask GDA_DIRTY
	jmp	afterTest

vmFile:
	call	OLDocumentGetFileHandle		;bx = file handle
	call	VMGetDirtyState			;ah = dirty since last auto-save
	tst	ah				;clears carry
afterTest:
	jz	done
	stc
done:
	.leave
	ret

IsFileDirty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteCachedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the cached data for the file are written out.
		We assume that we only need to write the data if (1) the
		file itself is dirty (VM files only), or (2) the document
		has been marked dirty.

CALLED BY:	(INTERNAL)
PASS:		cx	= non-zero if saving, 0 if auto-saving
		*ds:si	= GenDocument object
RETURN:		carry set if document was dirty
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteCachedData	proc	far
	uses	bp, ax, bx, dx
	.enter

	;
	; First see if the file itself is dirty.
	; 
	call	IsFileDirty
	jc	writeIt
	;
	; File's not dirty. How about the document object?
	; 
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GDI_attrs, mask GDA_DIRTY
	jz	done			; doc object not dirty either (carry
					;  cleared by test)
writeIt:
	;
	; Doc or file is dirty. If the file is a VM file, we need to clear
	; the VMA_NOTIFY_DIRTY attribute so whatever dirtying the app does
	; doesn't generate a dirty-notification with the former file handle,
	; when doing a SaveAs, that arrives after the operation is complete
	; and messes things up.
	; 
	clr	bx			; assume not VM file
	call	GetParentAttrs
	jz	writeData		; => not VM, so don't worry
	
	call	OLDocumentGetFileHandle	; bx <- file handle
	call	VMGetAttributes		; ax <- current attrs, for restore
	push	ax
	mov	ax, mask VMA_NOTIFY_DIRTY shl 8	; clear VMA_NOTIFY_DIRTY
	call	VMSetAttributes

writeData:
	mov	ax, MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE
	call	ObjCallInstanceNoLock

	tst	bx			; VM file needing attr restoration?
	jz	wasDirty		; => no
	
	pop	ax			; ax <- old attrs
	test	al, mask VMA_NOTIFY_DIRTY
	jz	wasDirty
	mov	ax, mask VMA_NOTIFY_DIRTY
	call	VMSetAttributes
wasDirty:
	stc				; indicate dirty file
done:
	.leave
	ret
WriteCachedData	endp
COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentCheckForModifications --
		MSG_GEN_DOCUMENT_CHECK_FOR_MODIFICATIONS for OLDocumentClass

DESCRIPTION:	Check for modifications in the file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 7/91		Initial version

------------------------------------------------------------------------------@
OLDocumentCheckForModifications	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_CHECK_FOR_MODIFICATIONS

	; Ensure that a timer is not running

EC <	mov	bx, ds:[di].OLDI_changeTimer				>
EC <	tst	bx							>
EC <	jz	10$							>
EC <	mov	ax, ds:[di].OLDI_changeTimerID				>
EC <	call	TimerStop						>
EC <	ERROR_NC	OL_DOCUMENT_CHANGE_TIMER_SHOULD_NOT_EXIST	>
EC <10$:								>

	mov	ds:[di].OLDI_changeTimer, 0

	; See if we should really check for changes

	call	OLDocumentGetAttrs
	test	ax, mask GDA_CLOSING
	jnz	exit				;if closing do nothing (CF = 0)

	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_CHECK_FOR_MODIFICATIONS
	call	ObjCallInstanceNoLock
	jnc	noModifications
	mov	ax, MSG_GEN_DOCUMENT_DOCUMENT_HAS_CHANGED
	call	ObjCallInstanceNoLock
noModifications:

	clr	cx				;standard time
	mov	dx, offset OLDI_changeTimer
	call	StartATimer
exit:
	Destroy	ax, cx, dx, bp
	ret

OLDocumentCheckForModifications	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentTestForFile -- MSG_GEN_DOCUMENT_TEST_FOR_FILE for
					OLDocumentClass

DESCRIPTION:	Test to see if this document has the given file open

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_TEST_FOR_FILE
	cx - file handle
	dx:bp - buffer to store optr if match

RETURN:
	carry - set if match
	cx - unmodified

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
OLDocumentTestForFile	method dynamic OLDocumentClass,
					MSG_GEN_DOCUMENT_TEST_FOR_FILE
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GDI_fileHandle, cx
	clc
	jnz	done

	mov	es, dx
	mov	di, bp
	mov_trash	ax, si
	stosw
	mov	ax, ds:[LMBH_handle]
	stosw
	stc
done:
	ret

OLDocumentTestForFile	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGetFileHandle -- MSG_GEN_DOCUMENT_GET_FILE_HANDLE for
					OLDocumentClass

DESCRIPTION:	Get the document's file handle

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_GET_FILE_HANDLE

RETURN:
	ax - file handle (bx also file handle if called directly)
	cx, dx, bp - unchanged

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
OLDocumentGetFileHandle	method OLDocumentClass,
					MSG_GEN_DOCUMENT_GET_FILE_HANDLE
	push	di
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDI_fileHandle
	mov	bx, ax
	pop	di
	ret

OLDocumentGetFileHandle	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDocSetAttrs

DESCRIPTION:	Set the document as not dirty and update the DC

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenDocument
	ax - bits to set
	bx - bits to clear

RETURN:
	ax - new attributes

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocSetAttrs	proc	far	uses di
	class	OLDocumentClass
	.enter

EC <	call	AssertIsGenDocument					>

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	not	bx
	and	bx, ds:[di].GDI_attrs
	or	ax, bx
	mov	ds:[di].GDI_attrs, ax

	.leave
	ret

OLDocSetAttrs	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGetAttrs -- MSG_GEN_DOCUMENT_GET_ATTRS for
					OLDocumentClass

DESCRIPTION:	Get the document attributes

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_GET_ATTRS

RETURN:
	ds:di - GenClass master-level instance data
	ax - GenDocumentAttrs
	cx, dx, bp - unchanged

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
OLDocumentGetAttrs	method OLDocumentClass, MSG_GEN_DOCUMENT_GET_ATTRS
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDI_attrs
	ret

OLDocumentGetAttrs	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentUpdateUI -- MSG_OL_DOCUMENT_UPDATE_UI
					for OLDocumentClass

DESCRIPTION:	...

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
OLDocumentUpdateUI	method	OLDocumentClass, MSG_OL_DOCUMENT_UPDATE_UI

	mov	bx, 1				;not losing target
	call	SendNotificationToDC
	ret

OLDocumentUpdateUI	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendNotificationToDC

DESCRIPTION:	Send GCN notification

CALLED BY:	INTERNAL

PASS:
	bx - 0 if losing target
	*ds:si - GenDocument

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
SendNotificationToDC	proc	far	uses si
	.enter

EC <	call	AssertIsGenDocument					>

	tst	bx
	jz	haveNotificationBlock

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	dx, ds:[di].GDI_attrs
	test	dx, mask GDA_MODEL
	LONG jz	done

	; generate the notification block

	push	ds:[di].GDI_type
	push	ds:[di].GDI_fileHandle

	clr	ax
ife	_JEDIMOTIF			; no empty or default docs in jmotif
	call	DoesEmptyDocumentExist
	jc	noEmpty
	dec	al
noEmpty:
	call	DoesDefaultDocumentExist
	jc	noDefault
	dec	ah
noDefault:
endif
		
	push	ax

	mov	ax, size NotifyDocumentChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or (mask HAF_ZERO_INIT shl 8) \
				or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	mov	es:NDC_attrs, dx
	pop	{word} es:NDC_emptyExists
	pop	es:NDC_fileHandle
	pop	es:NDC_type
	call	MemUnlock

	mov	ax, 1
	call	MemInitRefCount

haveNotificationBlock:
	mov	bp, bx

	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_DOCUMENT_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event

	mov	ax, mask GCNLSF_SET_STATUS
	tst	bp
	jnz	afterTransitionCheck
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
afterTransitionCheck:

	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type,
				GAGCNLT_APP_TARGET_NOTIFY_DOCUMENT_CHANGE
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, ax

	mov	ax, MSG_META_GCN_LIST_SEND
	mov	dx, size GCNListMessageParams

	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GCNListMessageParams

done:
	.leave
	ret

SendNotificationToDC	endp


ife	_JEDIMOTIF
COMMENT @----------------------------------------------------------------------

FUNCTION:	DoesEmptyDocumentExist

DESCRIPTION:	Determine if a default empty document exists

CALLED BY:	INTERNAL

PASS:
	*ds:si - document

RETURN:
	carry - set if does not exists

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 7/92		Initial version

------------------------------------------------------------------------------@
DoesEmptyDocumentExist	proc	near	uses ax, bx, dx, di, ds
	.enter
EC <	call	AssertIsGenDocument					>
	class	OLDocumentControlClass

	call	FilePushDir

	call	SetTemplateDir

	mov	bx, handle defaultDocumentName
	call	MemLock
	mov	ds, ax
	mov	dx, ds:[defaultDocumentName]		;ds:dx = default name
	call	FileGetAttributes			;test for existence
	mov	bx, handle defaultDocumentName
	call	MemUnlock

	call	FilePopDir

	.leave
	ret

DoesEmptyDocumentExist	endp
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetTemplateDir

DESCRIPTION:	Set the template directory to be the current directory

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

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
	Tony	8/11/92		Initial version

------------------------------------------------------------------------------@
SetTemplateDir	proc	far	uses ax, bx, cx, dx, bp
	.enter

	sub	sp, size PathName
	movdw	cxdx, sssp
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_TEMPLATE_DIR
	call	GenCallParent
	mov	dx, sp
	push	ds
	segmov	ds, ss
	mov	bx, SP_TEMPLATE
	call	FileSetCurrentPath
	pop	ds
	add	sp, size PathName

	.leave
	ret

SetTemplateDir	endp


ife	_JEDIMOTIF
COMMENT @----------------------------------------------------------------------

FUNCTION:	DoesDefaultDocumentExist

DESCRIPTION:	Determine whether a default document exists

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	carry - set if does not exist

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 7/92		Initial version

------------------------------------------------------------------------------@
DoesDefaultDocumentExist	proc	near	uses ax, bx, cx, dx, si, ds
category	local	INI_CATEGORY_BUFFER_SIZE dup (char)
	.enter

	; get category from app object

	mov	cx, ss
	lea	dx, category

	push	bp
	mov	ax, MSG_META_GET_INI_CATEGORY
	call	GenCallApplication
	pop	bp

	push	bp
	segmov	ds, ss
	lea	si, category			;ds:si = category
	mov	cx, cs
	mov	dx, offset defaultKey2		;cx:dx = key
	mov	bp, IFCC_INTACT shl offset IFRF_CHAR_CONVERT	;create buffer
	call	InitFileReadString
	jc	done
	call	MemFree
	clc
done:
	pop	bp

	.leave
	ret

DoesDefaultDocumentExist	endp

defaultKey2	char	"defaultDocument", 0

endif			; endif _JEDIMOTIF

;-----

SendUndoMessage	proc	far
EC <	call	AssertIsGenDocument					>
	push	ax
	call	GetParentAttrs
	test	ax, mask GDGA_AUTOMATIC_UNDO_INTERACTION
	pop	ax
	jz	exit
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	ret
SendUndoMessage	endp

; 
; OLDocumentAddSizeToTotal depends on:
; test	ax, mask GDGA_VM_FILE in case anyone thinks of removing it
;
GetParentAttrs	proc	far
EC <	call	AssertIsGenDocument					>
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_ATTRS
	call	Document_GenCallParent
	test	ax, mask GDGA_VM_FILE
	ret
GetParentAttrs	endp

GetUIParentAttrs	proc	far
EC <	call	AssertIsGenDocument					>
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_UI_ATTRS
	call	Document_GenCallParent
	ret
GetUIParentAttrs	endp

Document_GenCallParent	proc	near
	call	GenCallParent
	ret
Document_GenCallParent	endp


;=========================================

if	ERROR_CHECK

AssertIsGenDocument	proc	far	uses di, es
	.enter
	pushf

	call	GenCheckGenAssumption
	mov	di, segment GenDocumentClass
	mov	es, di
	mov	di, offset GenDocumentClass
	call	ObjIsObjectInClass
	ERROR_NC	OBJECT_NOT_A_GEN_DOCUMENT

	popf
	.leave
	ret
AssertIsGenDocument	endp

endif

DocCommon ends
