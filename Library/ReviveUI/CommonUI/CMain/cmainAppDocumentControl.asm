COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainAppDocumentControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLDocumentGroup	Open look document control class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:

	$Id: cmainAppDocumentControl.asm,v 1.97 97/01/03 15:12:58 ptrinh Exp $

------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLDocumentGroupClass	mask CLASSF_NEVER_SAVED or \
				mask CLASSF_DISCARD_ON_SAVE
CommonUIClassStructures ends

;---------------------------------------------------

DocInit segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentGroupAppStartup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do what we must when application first starts up.

CALLED BY:	MSG_META_APP_STARTUP
PASS:		*ds:si	= GenDocumentGroup object
		^hdx	= AppLaunchBlock
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentGroupAppStartup method dynamic OLDocumentGroupClass, 
			  		MSG_META_APP_STARTUP
	.enter

	; give ourselves a one way upward link to the UI document control
	; so that GUP stuff will work

	push	dx
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	cxdx, ds:[di].GDGI_documentControl
	call	GenSetUpwardLink
	pop	dx
	
	; let any children that have come back from the dead know about this.
	
	mov	ax, MSG_META_APP_STARTUP
	call	GenSendToChildren

	Destroy	ax, cx, dx, bp
	.leave
	ret
OLDocumentGroupAppStartup endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentGroupAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Make sure that any UserDoDialog won't block the UI from
		finishing MSG_META_ATTACH  -- force queue in front the
		attach if in a single-threaded app.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_ATTACH
		cx, dx, bp	- ?

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentGroupAttach	method dynamic OLDocumentGroupClass,
						MSG_META_ATTACH
	clr	bx
	push	si
	call	GeodeGetAppObject
	pop	si
	call	ObjTestIfObjBlockRunByCurThread
	jne	twoThreaded

	; If single-threaded, do the ATTACH after the current method is
	; finished being handled, so that the UI thread finished its
	; MSG_META_ATTACH.	-- Doug 4/30/93
	;
	mov	ax, MSG_OLDG_ATTACH
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

twoThreaded:

	; Allow two-threaded apps to just go ahead & finish the attached,
	; since the UI is free to finish the ATTACH over on its side.
	;
	FALL_THRU OLDocumentGroupOLDGAttach
OLDocumentGroupAttach	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupOLDGAttach -- MSG_OLDG_ATTACH for
						OLDocumentGroupClass

DESCRIPTION:	Send attach to children

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_OLDG_ATTACH
	cx, dx, bp	- Same as that passed in MSG_META_ATTACH

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
	Doug	4/30/93		Changed to happen *after* MSG_META_ATTACH done

------------------------------------------------------------------------------@
OLDocumentGroupOLDGAttach	method OLDocumentGroupClass, MSG_OLDG_ATTACH

	mov	ax, MSG_META_ATTACH
	call	GenSendToChildren

	Destroy	ax, cx, dx, bp
	ret

OLDocumentGroupOLDGAttach	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupOpenDefaultDoc --
		MSG_GEN_DOCUMENT_GROUP_OPEN_DEFAULT_DOC for
						OLDocumentGroupClass

DESCRIPTION:	Open the default document (if one exists)

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_OPEN_DEFAULT_DOC
	dx - size DocumentCommonParams
	ss:bp - DocumentCommonParams

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
OLDocumentGroupOpenDefaultDoc	method dynamic \
					OLDocumentGroupClass,
				MSG_GEN_DOCUMENT_GROUP_OPEN_DEFAULT_DOC

if UNTITLED_DOCS_ON_SP_TOP
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData	
	jc	skipRedwoodDirectoryStuff

	;
	; In for floppy-based-systems with untitled docs on the local disk, 
	; try the document floppy first, without creating a new document.   
	; Then try the local disk.
	; 
	;
	mov	ss:[bp].DCP_diskHandle, SP_DOCUMENT
	mov	{TCHAR}ss:[bp].DCP_path[0], 0

	mov	ss:[bp].DCP_flags, mask DOF_NO_ERROR_DIALOG
						;don't create!
						;(and don't complain on errors)
openDoc::
	push	bp
	mov	ax, MSG_GEN_DOCUMENT_GROUP_OPEN_DOC
	call	ObjCallInstanceNoLock
	pop	bp
	jnc	done				;doc found, done

if _NIKE
	; Warn user that default document was not found.

	mov	ax, SDBT_FILE_OPEN_DEFAULT_DOCUMENT_NOT_FOUND
	call	CallUserStandardDialog
	cmp	ax, IC_YES			;if IC_YES, try again
	je	openDoc
	cmp	ax, IC_NO			;if IC_NO, create new
	jne	done				; else cancel open default doc

	; Warning user about creating new default document.

	mov	ax, SDBT_FILE_OPEN_DEFAULT_DOCUMENT_NEW_DEFAULT
	call	CallUserStandardDialog
	cmp	ax, IC_YES			;if IC_YES, create new
	jne	done				; else cancel open default doc

endif	; if _NIKE

	ornf	ss:[bp].DCP_docAttrs, mask GDA_UNTITLED
	mov	ss:[bp].DCP_diskHandle, SP_TOP
skipRedwoodDirectoryStuff:
endif	; if UNTITLED_DOCS_ON_SP_TOP

	mov	ss:[bp].DCP_flags, mask DOF_CREATE_FILE_IF_FILE_DOES_NOT_EXIST
	mov	ax, MSG_GEN_DOCUMENT_GROUP_OPEN_DOC
	call	ObjCallInstanceNoLock
	jnc	done

	; *** handle error opening default file
if _RUDY
	;
	; On Rudy, we'll assume that if an app is using a DocControl
	; to open a default document, then that is the only document
	; it will ever want to open.  If it can't open it, then
	; it can't do anything, so it might as well quit.
	;
	mov	ax, MSG_META_QUIT
	call	UserCallApplication
endif ; _RUDY

done:
	Destroy	ax, cx, dx
	ret

OLDocumentGroupOpenDefaultDoc	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentGroupUpdateModelExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Provide default model node behavior

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- model messages

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLDocumentGroupUpdateModelExcl	method	OLDocumentGroupClass,
					MSG_META_GAINED_MODEL_EXCL,
					MSG_META_LOST_MODEL_EXCL,
					MSG_META_GAINED_SYS_MODEL_EXCL,
					MSG_META_LOST_SYS_MODEL_EXCL

	mov	bp, MSG_META_GAINED_MODEL_EXCL	; pass base message in bp
	mov	bx, offset Vis_offset
	mov	di, offset OLDGI_modelExcl
	GOTO	FlowUpdateHierarchicalGrab
OLDocumentGroupUpdateModelExcl	endm

DocInit ends

;---

DocExit segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupDetach -- MSG_META_DETACH for
						OLDocumentGroupClass

DESCRIPTION:	Send attach to children

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_META_DETACH or MSG_META_APP_SHUTDOWN

	cx - caller's ID
	dx:bp - OD for MSG_META_ACK

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
OLDocumentGroupDetach	method dynamic OLDocumentGroupClass,
						MSG_META_DETACH,
						MSG_META_APP_SHUTDOWN

	push	ax, cx, dx, bp
	call	ObjInitDetach

	; increment detach count for each child

	push	ax
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjCallInstanceNoLock		;dx = # of children
	pop	ax
	mov	cx, dx
	jcxz	done
10$:
	call	ObjIncDetach
	loop	10$

	; send to children

	mov	dx, ds:[LMBH_handle]
	mov	bp, si				;dx:bp = OD for ACK
	call	GenSendToChildren

done:

	pop	ax, cx, dx, bp
	mov	di, offset OLDocumentGroupClass
	call	ObjCallSuperNoLock

	call	ObjEnableDetach

	Destroy	ax, cx, dx, bp
	ret

OLDocumentGroupDetach	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupShutdownComplete

DESCRIPTION:	Nukes generic one-way upward link, once children have 
		shut down.

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_META_SHUTDOWN_COMPLETE

	cx - caller's ID
	dx:bp - OD for MSG_META_ACK

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
	Doug	5/92		Initial version
	ardeb	10/19/92	Changed to SHUTDOWN_COMPLETE

------------------------------------------------------------------------------@
OLDocumentGroupShutdownComplete	method dynamic OLDocumentGroupClass,
						MSG_META_SHUTDOWN_COMPLETE
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GI_link.LP_next.handle, 0	; nuke upward one-way
	mov	ds:[di].GI_link.LP_next.chunk, 0	;	link

	mov	di, offset OLDocumentGroupClass
	GOTO	ObjCallSuperNoLock

OLDocumentGroupShutdownComplete	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupQuit -- MSG_META_QUIT for
						OLDocumentGroupClass

DESCRIPTION:	Handle a user request to quit.

PASS:
	*ds:si - instance data
	es - segment of OLApAppocumentControlClass

	ax - MSG_META_QUIT

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	ptr = first child;   status = CONTINUE;
	while ((ptr != NULL) && (STATUS == CONTINUE)) {
	    status = MSG_GEN_DOCUMENT_USER_CLOSE(ptr);
	    ptr = NextSibling(ptr);
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentGroupQuit	method dynamic OLDocumentGroupClass, MSG_META_QUIT

	; Save the optr with the current model grab

	mov	ax, MSG_META_GET_MODEL_EXCL
	call	ObjCallInstanceNoLock			;cx:dx = cur model
	pushdw	cxdx	

	mov	cx, ds:[di].OLDGI_quitObj.handle
	mov	dx, ds:[di].OLDGI_quitObj.chunk
	tst	cx
	jnz	while
	
	; begin at first child

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GI_comp.CP_firstChild.handle
	mov	dx, ds:[di].GI_comp.CP_firstChild.chunk
	tst	cx					;check for no children
	jz	finished

	; cx:dx = child
	; ds:di = spec offset

while:
	test	dx, LP_IS_PARENT
	jnz	finished

	push	si

	; find next sibling (in case this object is removed in the call)

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	bx, cx
	mov	si, dx					;bx:si = child to call
	call	ObjLockObjBlock
	mov	es, ax
	mov	bp, es:[si]
	add	bp, es:[bp].Gen_offset
	mov	ax, es:[bp].GI_link.LP_next.handle
	mov	ds:[di].OLDGI_quitObj.handle, ax
	mov	ax, es:[bp].GI_link.LP_next.chunk
	mov	ds:[di].OLDGI_quitObj.chunk, ax
	call	MemUnlock

EC <	push	ax >					; ec shouldn't trash
EC <	mov	ax, NULL_SEGMENT > 			; to avoid ec crash
EC <	mov_tr	es, ax >
EC <	pop	ax >					; ec shouldn't trash

	movdw	bxsi, cxdx
	mov	ax, MSG_META_GRAB_MODEL_EXCL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_DOCUMENT_CLOSE
	clr	bp					; user-initiated
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage				;cx = DocQuitStatus

	pop	si
	cmp	cx, DQS_SAVE_ERROR
	jz	cancel
	cmp	cx, DQS_CANCEL
	jz	cancel
	cmp	cx, DQS_DELAYED
	jz	delayed

	; continue, but clear the queue first

	popdw	bxdx
	call	restoreModel

	mov	ax, MSG_META_QUIT
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

	; all done !

finished:
	popdw	cxdx
	clr	cx
	jmp	common

	; delayed (in the middle of a "save as")

delayed:
	popdw	bxdx
	ret

	; cancel quitting

cancel:
	popdw	bxdx
	call restoreModel
	mov	cx, -1				;cx = non-zero (abort)
common:
	clr	ax
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLDGI_quitObj.handle, ax
	mov	ds:[di].OLDGI_quitObj.chunk, ax
	mov	ax, MSG_META_QUIT_ACK
	call	SendToUIDocControl
	Destroy	ax, cx, dx, bp
	ret

restoreModel:
	; restore the model grab to the doc which had it initially

	xchg	dx, si
	mov	ax, MSG_META_GRAB_MODEL_EXCL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			;restore the cur model
	xchg	dx, si
	retn
OLDocumentGroupQuit	endm

SendToUIDocControl	proc	far
	class	OLDocumentGroupClass

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDGI_documentControl.handle
	mov	si, ds:[di].GDGI_documentControl.chunk
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

SendToUIDocControl	endp

DocExit	ends

;---

DocCommon segment resource




COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupGetTotalSize -- 
		MSG_OLDG_GET_TOTAL_SIZE for OLDocumentGroupClass

DESCRIPTION:	Returns total size of all child documents.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OLDG_GET_TOTAL_SIZE

RETURN:		dx.cx -- total size
		bp - non-zero if an individual file was too large	
		ax - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	1/16/94         Initial Version

------------------------------------------------------------------------------@

if FLOPPY_BASED_DOCUMENTS

OLDocumentGroupGetTotalSize	method dynamic	OLDocumentGroupClass, \
				MSG_OLDG_GET_TOTAL_SIZE

	clrdw	dxcx			; initialize size
	clr	bp			; no individual files too large yet
	mov	ax, MSG_OL_DOCUMENT_ADD_SIZE_TO_TOTAL

	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset GI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	mov	bx,OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	push	bx
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
	ret
OLDocumentGroupGetTotalSize	endm

endif

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupMarkDirty --
			MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY for
			OLDocumentGroupClass

DESCRIPTION:	Mark a document as dirty

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY

	cx:dx - document to mark dirty.  If 0 then the target document is
		marked as dirty

RETURN:

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
OLDocumentGroupMarkDirty	method dynamic OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY

	mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
	FALL_THRU	SendToCXDXOrTargetDocument

OLDocumentGroupMarkDirty	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToCXDXOrTargetDocument

DESCRIPTION:	Send a method to the document in cx:dx or to the target
		document if cx:dx is 0

CALLED BY:	GLOBAL

PASS:
	*ds:si - GenDocumentGroup
	ax - method to send
	cx:dx - document or 0 to send to target

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
SendToCXDXOrTargetDocument	proc	far
	tst	cx
	jnz	common


	pushdw	bxsi
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	popdw	bxsi
	mov	cx, di
	mov	dx, TO_MODEL
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	GOTO	ObjCallInstanceNoLock

common:
	movdw	bxsi, cxdx
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

SendToCXDXOrTargetDocument	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupSendClassedEvent

DESCRIPTION:	Sends "TO_MODEL" messages on to current Model exclusive

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_META_SEND_CLASSED_EVENT

	cx	- handle of classed event
	dx	- TargetObject

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@
OLDocumentGroupSendClassedEvent	method	OLDocumentGroupClass, \
						MSG_META_SEND_CLASSED_EVENT
	cmp	dx, TO_MODEL
	je	toModelDoc

	mov	di, offset OLDocumentGroupClass
	GOTO	ObjCallSuperNoLock

toModelDoc:
	movdw	bxbp, ds:[di].OLDGI_modelExcl.HG_OD
	clr	di
	call	FlowDispatchSendOnOrDestroyClassedEvent
	ret

OLDocumentGroupSendClassedEvent	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupGetDocByFile --
			MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE for
			OLDocumentGroupClass

DESCRIPTION:	Set the output

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE

	cx - file handle open to the document

RETURN:
	cx:dx - OD (0 if none)
	cx - unchanged

ALLOWED TO DESTROY:
	ax
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentGroupGetDocByFile	method OLDocumentGroupClass,
				MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE
doc	local	optr
	.enter
	;
	; Use ObjCompProcessChildren to send MSG_GEN_DOCUMENT_TEST_FOR_FILE
	; to each of our GenDocument children. If the file handle passed in CX
	; doesn't belong to the child, it will return carry clear with CX
	; unmodified, so we can tell OCPC to not save the parameters. If the
	; file does belong to the child, it will mark itself dirty and return
	; carry set, causing the processing of the children to abort.
	; 

	clr	ax
	mov	doc.handle, ax
	mov	doc.chunk, ax
	push	bp
	mov	dx, ss
	lea	bp, doc

	push	ax		; Start with the first child
	push	ax
	mov	di, offset GI_link
	push	di
	push	ax		; Use canned callback
	mov	ax, OCCT_DONT_SAVE_PARAMS_TEST_ABORT
	push	ax
		
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	mov	ax, MSG_GEN_DOCUMENT_TEST_FOR_FILE
	call	ObjCompProcessChildren
	pop	bp

	mov	cx, doc.handle
	mov	dx, doc.chunk

	.leave
	ret

OLDocumentGroupGetDocByFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentGroupMarkDirtyByFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the document that has the given file open and
		mark it dirty

CALLED BY:	MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE
PASS:		*ds:si	= instance data
		es	= segment of OLDocumentGroupClass
		ax	= MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE
		cx	= file handle
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentGroupMarkDirtyByFile method OLDocumentGroupClass,
		    		MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE

	call	OLDocumentGroupGetDocByFile	;cx:dx = OD
EC <	tst	cx							>
EC <	ERROR_Z	PASSED_FILE_NOT_OPENED_BY_DOCUMENT_CONTROL		>

	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

OLDocumentGroupMarkDirtyByFile		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentGroupAutoSaveByFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the document that has the given file open and
		trigger an autosave

CALLED BY:	MSG_GEN_DOCUMENT_GROUP_AUTO_SAVE_BY_FILE
PASS:		*ds:si	= instance data
		es	= segment of OLDocumentGroupClass
		ax	= MSG_GEN_DOCUMENT_GROUP_AUTO_SAVE_BY_FILE
		cx	= file handle
RETURN:		nothing
DESTROYED:	cx, dx, bx, si, ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rg	4/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentGroupAutoSaveByFile method OLDocumentGroupClass,
		    		MSG_GEN_DOCUMENT_GROUP_AUTO_SAVE_BY_FILE

	call	OLDocumentGroupGetDocByFile	;cx:dx = OD
	jcxz	notMyDoc

	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_DOCUMENT_AUTO_SAVE
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

notMyDoc:
	ret
OLDocumentGroupAutoSaveByFile		endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupFileChanged -- MSG_OLDG_FILE_CHANGED for
			OLDocumentGroupClass

DESCRIPTION:	Update the UI for the document control (pass this on to
		the UI document control)

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_OLDG_FILE_CHANGED

	dx - size DocumentFileChangedParams
	ss:bp - DocumentFileChangedParams

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
OLDocumentGroupFileChanged	method dynamic OLDocumentGroupClass,
					MSG_OLDG_FILE_CHANGED

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDGI_documentControl.handle
	mov	si, ds:[di].GDGI_documentControl.chunk
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_FILE_CHANGED
	mov	dx, size DocumentFileChangedParams
	mov	di, mask MF_STACK
	GOTO	ObjMessage

OLDocumentGroupFileChanged	endm

;------

OLDocumentGroupGetUIAttrs	method dynamic OLDocumentGroupClass,
				MSG_GEN_DOCUMENT_GROUP_GET_UI_ATTRS

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS
	GOTO	CallUIDocControl

OLDocumentGroupGetUIAttrs	endm

;------

OLDocumentGroupGetTemplateDir	method dynamic OLDocumentGroupClass,
				MSG_GEN_DOCUMENT_GROUP_GET_TEMPLATE_DIR

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_GET_TEMPLATE_DIR
	GOTO	CallUIDocControl

OLDocumentGroupGetTemplateDir	endm

;------

OLDocumentGroupGetUIFeatures	method dynamic \
						OLDocumentGroupClass,
				MSG_GEN_DOCUMENT_GROUP_GET_UI_FEATURES

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_GET_FEATURES
	FALL_THRU	CallUIDocControl

OLDocumentGroupGetUIFeatures	endm

;------

CallUIDocControl	proc	far
	class	OLDocumentGroupClass

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDGI_documentControl.handle
	mov	si, ds:[di].GDGI_documentControl.chunk
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

CallUIDocControl	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupGetOutput --
			MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT for
			OLDocumentGroupClass

DESCRIPTION:	Get the output

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT

	cx:dx - output

RETURN:
	bp - unchanged

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
OLDocumentGroupGetOutput	method dynamic OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT

	add	bx, ds:[bx].Gen_offset
	movdw	cxdx, ds:[bx].GDGI_output
	ret

OLDocumentGroupGetOutput	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupGetAttrs --
		MSG_GEN_DOCUMENT_GROUP_GET_ATTRS for OLDocumentGroupClass

DESCRIPTION:	Get the DocumentControlAttrs

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_GET_ATTRS

RETURN:
	ax - GenDocumentGroupAttrs
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
OLDocumentGroupGetAttrs	method dynamic OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_GET_ATTRS

	add	bx, ds:[bx].Gen_offset
	mov	ax, ds:[bx].GDGI_attrs
	ret

OLDocumentGroupGetAttrs	endm

DocCommon ends

;---

DocNewOpen segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentGroupAlterFTVMCExcl --
		MSG_META_MUP_ALTER_FTVMC_EXCL for OLDocumentGroupClass

DESCRIPTION:	Alter an exclusive

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - The message

	cx:dx - object
	bp - flags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 4/92		Initial version

------------------------------------------------------------------------------@
OLDocumentGroupAlterFTVMCExcl method dynamic OLDocumentGroupClass,
					MSG_META_MUP_ALTER_FTVMC_EXCL

	; Since we're a model node, check to see if this request
	; includes a change to the focus hierarchy.

	test	bp, mask MAEF_MODEL
	jz	callSuper		; if not, skip & send to superclass

	; Call Flow utility routine to handle modifying the node

	push	ax			; save message
	mov	ax, MSG_META_GAINED_MODEL_EXCL	;pass gained message
	push	bp			; save original flags
					; Pass only the "GRAB" flag &
					; which hierarchy this node is.
	and	bp, mask MAEF_GRAB or mask MAEF_MODEL
	mov	bx, offset Vis_offset
	mov	di, offset OLDGI_modelExcl
	call	FlowAlterHierarchicalGrab
	pop	bp			; restore original flags
	pop	ax			; restore message

	; Now that we've updated the focus node, clear that portion
	; of the request from the flags

	and	bp, not mask MAEF_MODEL

	; If request was also to grab/release on other nodes, pass on request

	test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
	jz	done			; otherwise done.

callSuper:

	; Pass message on to superclass for handling outside of this class.

	mov	di, offset OLDocumentGroupClass
	call	ObjCallSuperNoLock
done:
	ret

OLDocumentGroupAlterFTVMCExcl	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateDocObject

DESCRIPTION:	Create a new document object and add it as a child of this
		object.  Send it a new or open method and send the correct
		notification

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenDocumentGroup object
	ax - method to send to document
	dx - size DocumentCommonParams
	ss:bp - DocumentCommonParams

RETURN:
	cx:dx - new Document object created (0 if error)

DESTROYED:
	ax, bx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Steve	2/92		Added duplicate resource option

------------------------------------------------------------------------------@
CreateDocObject	proc	far
	class	OLDocumentGroupClass

if CUSTOM_DOCUMENT_PATH
	call	CustomDocPathInitDocCommonParams
endif ; CUSTOM_DOCUMENT_PATH

	push	ax				;message 

	push	bp				;stack frame offset

	; create a new object

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GDGI_genDocument.handle
	LONG jnz duplicateDocumentResource
	les	di, ds:[di].GDGI_documentClass

	push	si				;doc control chunk
	mov	bx, ds:[LMBH_handle]		;put it in this block
	call	ObjInstantiate			;create new object (bx:si)

	mov	dx, si				;new document chunk
	pop	si				;doc control chunk

addDocument:
	pop	bp				;stack frame offset
	push	bp				;stack frame offset

	; If opening for an IACP connection, set
	; ATTR_GEN_DOCUMENT_OPEN_FOR_IACP_ONLY on the new object
	;
	; {
	test	ss:[bp].DCP_flags, mask DOF_OPEN_FOR_IACP_ONLY
	jz	afterPrintCheck
	push	dx, si				;new chunk, control chunk
	mov	si, dx				;new chunk
	mov	dx, size AddVarDataParams
	sub	sp, dx
	mov	bp, sp
	clr	ax
	mov	ss:[bp].AVDP_data.segment, ax
	mov	ss:[bp].AVDP_data.offset, ax
	mov	ss:[bp].AVDP_dataSize, ax
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_DOCUMENT_OPEN_FOR_IACP_ONLY
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size AddVarDataParams
	pop	dx, si				;new chunk, control chunk
afterPrintCheck:
	; }

	; add new document object as child of document control

	mov	cx, bx				;new document handle
	mov	bp, CCO_FIRST or mask CCF_MARK_DIRTY
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock

	; Update the number of documents

NKE <	call	OLDocumentGroupUpdateDocumentCount			>

	; mark the new document object as usable

	push	dx, si				;new chunk, control chunk
	mov	si, dx				;new chunk
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx, si				;new chunk, control chunk

	; send new document object the file name

	pop	bp				;stack frame offset

	pop	ax				;ax = method to send to doc

	push	si				;document control chunk
	mov	si, dx				;^lbx:si = new document

	mov	dx, size DocumentCommonParams
	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	call	ObjMessage			;carry - set if error
						;bp = file handle
	mov	cx, bx				;cx:dx = document
	mov	dx, si
	pop	si				;*ds:si = control
	jnc	done

	; error -- remove new document from document control

	push	si				;save doc control
	mov	ax, MSG_OLDG_REMOVE_DOC
	call	ObjCallInstanceNoLock
	mov	ax, MSG_OLDC_TEST_FOR_DISPLAY_MAIN_DIALOG
	call	SendToUIDocControl
	clr	cx
	clr	dx
	pop	si				;*ds:si = doc control
	stc
done:
	ret

duplicateDocumentResource:
	mov	bx,ds:[di].GDGI_genDocument.handle	;resource handle
	clr	ax				; have current geode own block
	clr	cx				; have current thread run block
	call	ObjDuplicateResource
	mov	dx,ds:[di].GDGI_genDocument.chunk
	jmp	addDocument


CreateDocObject	endp

if CUSTOM_DOCUMENT_PATH

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustomDocPathInitDocCommonParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the passed DocumentCommonParams with the
		values in ATTR_GEN_PATH_DATA if present.

CALLED BY:	(INTERNAL) CreateDocObject, OLDocumentGroupGetDefaultName

PASS:		*ds:si	- Object containing ATTR_GEN_PATH_DATA
		ss:bp	- DocumentCommonParams

RETURN:		DocumentCommonParams structure modified if
		ATTR_GEN_PATH_DATA present.

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ptrinh	12/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CustomDocPathInitDocCommonParams	proc	near
	uses	ax,bx,si,di,es
	.enter

	;
	; Only copy if there wasn't passed a diskhandle or path...
	;
	tst	ss:[bp].DCP_diskHandle
	jnz	done
	tst	{TCHAR}ss:[bp].DCP_path[0]
	jnz	done

	;
	; and if exists ATTR_GEN_PATH_DATA...
	;
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData			; ds:bx - GenFilePath
	jnc	done

	;
	; Copy disk handle and path name -- optimized based on
	; assumptions.  (See CheckHack.)
	;
	segmov	es, ss, di
	lea	di, ss:[bp].DCP_diskHandle	; es:di - dst
	lea	si, ds:[bx].GFP_disk		; ds:si - src

	movsw					; DiskHandle
		CheckHack < size GFP_disk eq size word >

	LocalCopyString				; Path
		CheckHack < offset DCP_diskHandle + 2 eq offset DCP_path >
		CheckHack < offset GFP_disk + 2 eq offset GFP_path >

done:
	.leave
	ret
CustomDocPathInitDocCommonParams	endp
endif ; CUSTOM_DOCUMENT_PATH


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentGroupUpdateDocumentCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the number of documents

CALLED BY:	CreateDocObject
		OLDocumentGroupRemoveDoc
PASS:		*ds:si	= GenDocumentGroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NIKE	;--------------------------------------------------------------

OLDocumentGroupUpdateDocumentCount	proc	far
	class	OLDocumentGroupClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjCallInstanceNoLock

	push	dx				;extra data
	mov	dx, sp
	mov	ax, TEMP_OLDC_NUMBER_OF_DOCUMENTS or mask VDF_SAVE_TO_STATE
	push	ax				;AVDP_dataType
	mov	ax, size word
	push	ax				;AVDP_dataSize
	pushdw	ssdx				;AVDP_data
	mov	bp, sp

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	bxsi, ds:[di].GDGI_documentControl
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size AddVarDataParams + size word

	; HACK: remove and then re-add the documentControl from the
	; GAGCNLT_APP_TARGET_NOTIFY_DOCUMENT_CHANGE GCNList.  This will
	; cause the documentControl to update itself.  (Can't use
	; MSG_OL_DOCUMENT_UPDATE_UI, because the notification to update
	; will be ignored because nothing has changed.)

	pushdw	bxsi				; GCNLP_optr
	mov	ax, GAGCNLT_APP_TARGET_NOTIFY_DOCUMENT_CHANGE
	push	ax				; GCNLP_ID.GCNLT_type
	mov	ax, MANUFACTURER_ID_GEOWORKS
	push	ax				; GCNLP_ID.GCNLT_manuf
	mov	bp, sp

	push	bp
	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	dx, size GCNListParams
	call	callApp
	pop	bp
	jnc	fixupStack

	mov	ax, MSG_META_GCN_LIST_ADD
	mov	dx, size GCNListParams
	call	callApp

fixupStack:
	add	sp, size GCNListParams

	.leave
	ret

callApp:
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	retn

OLDocumentGroupUpdateDocumentCount	endp

endif		; if _NIKE ----------------------------------------------------


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupOpenDoc --
		MSG_GEN_DOCUMENT_GROUP_OPEN_DOC	for OLDocumentGroupClass

DESCRIPTION:	Open a file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_OPEN_DOC
	dx - size DocumentCommonParams
	ss:bp - DocumentCommonParams

RETURN:
	cx:dx - new Document object created (0 if error)

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
OLDocumentGroupOpenDoc	method dynamic OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_OPEN_DOC

	ornf	ss:[bp].DCP_flags, mask DOF_RAISE_APP_AND_DOC
	
	; If we are being asked to FORCE template behavior, then ALWAYS
	; "open" the document (since it really opens the document and copies
	; it into a new document).  --JimG 9/2/94
	
	test	ss:[bp].DCP_flags, mask DOF_FORCE_TEMPLATE_BEHAVIOR
	jnz	openIt
	
	call	OLDocumentGroupSearchForDoc
	jc	done

openIt:
	mov	ax, MSG_GEN_DOCUMENT_OPEN
	call	CreateDocObject
done:
	ret

OLDocumentGroupOpenDoc	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentGroupSearchForDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search our generic children for one that has a document open

CALLED BY:	MSG_GEN_DOCUMENT_GROUP_SEARCH_FOR_DOC
PASS:		*ds:si	= GenDocumentGroup object
		ss:bp	= DocumentCommonParams describing the document
RETURN:		carry set if document found
DESTROYED:	ax, bx, di
SIDE EFFECTS:	the document and app may be raised, if DOF_RAISE_APP_AND_DOC
     			is set in the DCP and the document is found.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentGroupSearchForDoc method OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_SEARCH_FOR_DOC
	.enter
	test	ss:[bp].DCP_flags, mask DOF_NAME_HOLDS_FILE_ID
	jnz	haveID
	
	;
	; Fetch the real ID for the document.
	; 
	push	ds, si
	segmov	ds, ss
	lea	dx, ss:[bp].DCP_path
	lea	si, ss:[bp].DCP_name
	mov	bx, ss:[bp].DCP_diskHandle
	call	IACPGetDocumentID
	pop	ds, si
	
	;
	; Save the first four bytes of DCP_name and the original disk handle.
	; 
	pushdw	({FileID}ss:[bp].DCP_name)
	push	ss:[bp].DCP_diskHandle
	;
	; Replace them with the 48-bit file ID.
	; 
	movdw	({FileID}ss:[bp].DCP_name), cxdx
	mov	ss:[bp].DCP_diskHandle, ax
haveID:
	push	ss:[bp].DCP_flags	; save so we know what to pop
	ornf	ss:[bp].DCP_flags, mask DOF_NAME_HOLDS_FILE_ID
	
	clr	ax
	push	ax, ax				;first child
	mov	ax, offset GI_link
	push	ax
	clr	ax
	push	ax				;callback.segment
	mov	ax, OCCT_SAVE_PARAMS_TEST_ABORT
	push	ax				;callback.offset
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp

	mov	ax, MSG_GEN_DOCUMENT_SEARCH_FOR_DOC
	call	ObjCompProcessChildren

	;
	; Restore disk handle and first four bytes of the name if necessary.
	; 
	lahf
	pop	bx
	test	bx, mask DOF_NAME_HOLDS_FILE_ID
	jnz	done
	pop	ss:[bp].DCP_diskHandle
	popdw	({FileID}ss:[bp].DCP_name)
done:
	sahf
	.leave
	ret
OLDocumentGroupSearchForDoc endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupGetDefaultName --
			MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME for
			OLDocumentGroupClass

DESCRIPTION:	Get the DocumentControlAttrs

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME
	cx:dx - DocumentCommonParams buffer

RETURN:
	ax - DocumentControlAttrs
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
OLDocumentGroupGetDefaultName	method dynamic \
					OLDocumentGroupClass,
				MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME
					uses cx, dx
	.enter

	mov	es, cx
	mov	di, dx

	; default documents retrieved from us are always in the DOCUMENT
	; directory   7/29/93 cbh

if UNTITLED_DOCS_ON_SP_TOP
	mov	es:[di].DCP_diskHandle, SP_TOP
elseif CUSTOM_DOCUMENT_PATH
	mov	es:[di].DCP_diskHandle, 0
else
	mov	es:[di].DCP_diskHandle, SP_DOCUMENT
endif
	mov	{TCHAR}es:[di].DCP_path[0], 0

if CUSTOM_DOCUMENT_PATH
	call	CustomDocPathInitDocCommonParams	
endif ; CUSTOM_DOCUMENT_PATH

	; copy default name from our instance data.

	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	ax, ds:[si].GDGI_attrs		; return attrs in ax
	mov	si, ds:[si].GDGI_untitledName
	mov	si, ds:[si]			;ds:si = source (default name)

	CheckHack	<offset DCP_name eq 0>
	ChunkSizePtr	ds, si, cx
SBCS <EC <	cmp	cx, FILE_LONGNAME_LENGTH-3+1			>>
DBCS <EC <	cmp	cx, (FILE_LONGNAME_LENGTH-3+1)*(size wchar)	>>
EC <	ERROR_A OLAPPDC_DEFAULT_NAME_TOO_LONG				>
	rep	movsb

	.leave
	ret

OLDocumentGroupGetDefaultName	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupGetToken --
		MSG_GEN_DOCUMENT_GROUP_GET_TOKEN for OLDocumentGroupClass

DESCRIPTION:	Get the token from the UI doc control

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - The message

	cx:dx - address to store token

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
OLDocumentGroupGetToken	method dynamic OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_GET_TOKEN

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN
	call	CallUIDocControl
	ret

OLDocumentGroupGetToken	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupGetProtocol --
	    MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL for OLDocumentGroupClass

DESCRIPTION:	Get the protocol

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL

RETURN:
	cx - major protocol
	dx - minor protocol
	bp - unchanged

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
OLDocumentGroupGetProtocol	method dynamic OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL

	add	bx, ds:[bx].Gen_offset
	mov	cx, ds:[bx].GDGI_protocolMajor
	mov	dx, ds:[bx].GDGI_protocolMinor
	ret

OLDocumentGroupGetProtocol	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentGroupGetView --
		MSG_APP_GEN_DOCUMENT_CONTROL_GET_VIEW
					for OLDocumentGroupClass

DESCRIPTION:	Return to associated GenView

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - The message

RETURN:
	cx:dx - GenView
	ax, bp - unchanged

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
OLDocumentGroupGetView	method dynamic	OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_GET_VIEW
	add	bx, ds:[bx].Gen_offset
	movdw	cxdx, ds:[bx].GDGI_genView
	ret

OLDocumentGroupGetView	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentGroupGetDisplay --
		MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY
					for OLDocumentGroupClass

DESCRIPTION:	Return to associated GenDisplay

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - The message

RETURN:
	cx:dx - GenDisplay
	ax, bp - unchanged

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
OLDocumentGroupGetDisplay	method dynamic	OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY
	add	bx, ds:[bx].Gen_offset
	movdw	cxdx, ds:[bx].GDGI_genDisplay
	ret

OLDocumentGroupGetDisplay	endm
COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentGroupGetDisplayGroup --
		MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY_GROUP
					for OLDocumentGroupClass

DESCRIPTION:	Return to associated GenDisplayGroup

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - The message

RETURN:
	cx:dx - GenDisplayGroup
	ax, bp - unchanged

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
OLDocumentGroupGetDisplayGroup	method dynamic \
					OLDocumentGroupClass,
				MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY_GROUP

	add	bx, ds:[bx].Gen_offset
	movdw	cxdx, ds:[bx].GDGI_genDisplayGroup
	ret

OLDocumentGroupGetDisplayGroup	endm

DocNewOpen ends

;---

DocNew segment resource

OLDocumentGroupGetCreator	method dynamic OLDocumentGroupClass,
				MSG_GEN_DOCUMENT_GROUP_GET_CREATOR

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_GET_CREATOR
	call	CallUIDocControl
	ret

OLDocumentGroupGetCreator	endm

DocNew ends

;---

DocMisc segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentGroupImportNewDoc --
		MSG_GEN_DOCUMENT_GROUP_IMPORT_NEW_DOC for OLDocumentGroupClass

DESCRIPTION:	Create a new document and import into it

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - The message

	ss:bp - ImpexTranslationParams
	dx -- size ImpexTranslationParams

RETURN:
	cx:dx - new Document object created
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

OLDocumentGroupImportNewDoc	method dynamic	OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_IMPORT_NEW_DOC

	push	bp
	sub	sp, size DocumentCommonParams
	mov	bp, sp
	clr	ax
	mov	ss:[bp].DCP_flags, mask DOF_FORCE_REAL_EMPTY_DOCUMENT
	mov	ss:[bp].DCP_diskHandle, ax
	mov	ss:[bp].DCP_connection, ax
	mov	ss:[bp].DCP_docAttrs, mask GDA_UNTITLED
	mov	ax, MSG_GEN_DOCUMENT_NEW
	call	CreateDocObject
	lahf
	add	sp, size DocumentCommonParams
	sahf
	pop	bp

	jc	done
	push	bp
	movdw	bxsi, cxdx
	mov	dx, size ImpexTranslationParams
	mov	ax, MSG_GEN_DOCUMENT_IMPORT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	movdw	cxdx, bxsi
	pop	bp

done:
	pushf
	mov	ax, ss:[bp].ITP_returnMsg
	movdw	bxsi, ss:[bp].ITP_impexOD
	mov	dx, size ImpexTranslationParams
	mov	di, mask MF_STACK
	call	ObjMessage
	popf
	ret

OLDocumentGroupImportNewDoc	endm


DocMisc ends

;---

DocObscure segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupGetDocName--
		    MSG_PRINT_GET_DOC_NAME for OLDocumentGroupClass

DESCRIPTION:	Get the document name from the target document

PASS:		DS:DI	= OLDocumentGroupClass specific instance data
		DS:BX	= Deref'd OLDocumentGroupClass
		ES	= Segment of OLApAppocumentControlClass
		CX:DX	= OD to send method name to (PrintControlClass)
		BP	= Method to send to OD (MSG_PRINT_CONTROL_SET_DOC_NAME)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		I allocate more than the necessary number of bytes
		on the stack, as that is what the DocumentClass
		expects. Actually, though, the name cannot exceed
		FILE_LONGNAME_LENGTH+1, include the null terminator.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/90		Initial version

------------------------------------------------------------------------------@
OLDocumentGroupGetDocName	method dynamic	OLDocumentGroupClass, \
					    	MSG_PRINT_GET_DOC_NAME
	.enter

	; Allocate memory for the block
	;
	mov	bx, di				; OLAppDocInstance => DS:BX

	sub	sp, FILE_LONGNAME_BUFFER_SIZE	; bytes to allocate
	mov	di, sp				; store buffer => AX
	push	cx, dx				; store the SPC OD
	mov	{byte} ss:[di], 0		; null terminate the string
	mov	cx, ss
	mov	dx, di				; buffer => CX:DX
	
	; Ask the target document to fill the block
	;
	mov	si, ds:[bx].OLDGI_modelExcl.HG_OD.chunk
	mov	bx, ds:[bx].OLDGI_modelExcl.HG_OD.handle
	tst	bx				; any target document ??
	jz	done				; nope, so return empty string
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; fill that block!

	; Now send the document name off to the SpoolPrintControl
	;
done:
	pop	bx, si				; PrintControl OD => BX:SI
	mov	ax, bp				; method => AX
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; send the document name
	add	sp, FILE_LONGNAME_BUFFER_SIZE

	.leave
	ret
OLDocumentGroupGetDocName	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupSetOutput --
			MSG_GEN_DOCUMENT_GROUP_SET_OUTPUT for
			OLDocumentGroupClass

DESCRIPTION:	Set the output

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_SET_OUTPUT

	cx:dx - output

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
OLDocumentGroupSetOutput	method dynamic OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_SET_OUTPUT

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDGI_output.handle, cx
	mov	ds:[di].GDGI_output.chunk, dx

	ret

OLDocumentGroupSetOutput	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentGroupGetModelExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the model exclusive for this app.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		cx:dx - model object
		carry set
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentGroupGetModelExcl	method	dynamic OLDocumentGroupClass, 
				MSG_META_GET_MODEL_EXCL
	.enter
	movdw	cxdx, ds:[di].OLDGI_modelExcl.HG_OD
	stc
	.leave
	ret
OLDocumentGroupGetModelExcl	endp


if _JEDIMOTIF
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDGUpdateTableField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the date field for the file selector of the table
		object.

CALLED BY:	MSG_OLDG_UPDATE_TABLE_DATE_FIELD
PASS:		*ds:si	= OLDocumentGroupClass object
		ds:di	= OLDocumentGroupClass instance data
		es 	= segment of OLDocumentGroupClass
		^lcx:dx	= OLFSTableClass object
		bp	= row # to update
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDGUpdateTableDateField	method dynamic OLDocumentGroupClass, 
					MSG_OLDG_UPDATE_TABLE_DATE_FIELD
		.enter
		mov	bx, cx
		mov	si, dx			;^lbx:si = table object
		mov	cx, bp			;cx = row #
		mov	dx, FILE_TABLE_DATE_COL	;dx = col #
		mov	ax, MSG_TABLE_REDRAW_CELL
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		.leave
		ret
OLDGUpdateTableDateField		endm
endif

DocObscure ends

;---

DocSaveAsClose segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupRemoveDoc -- MSG_OLDG_REMOVE_DOC for
						OLDocumentGroupClass

DESCRIPTION:	Remove an already closed document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_OLDG_REMOVE_DOC

	cx:dx - document to remove

RETURN:

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
OLDocumentGroupRemoveDoc	method dynamic OLDocumentGroupClass,
					MSG_OLDG_REMOVE_DOC

	; release all exclusives for the document

	push	cx, dx, si
	mov	ax, MSG_META_RELEASE_MODEL_EXCL
	movdw	bxsi, cxdx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; make the document not usable

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, si

	; remove the document

	clr	bp				;don't bother marking dirty
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	ObjCallInstanceNoLock

	; Update the number of documents

NKE <	call	OLDocumentGroupUpdateDocumentCount			>

	; if this document was the target document then zero the target
	; OR if this document was the last document

	push	cx,dx				;document OD

	; free the document. If the genDocument.handle field is
	; non-zero, it means that a resource was duplicated to
	; create the document and we must free the block
	; that resulted from duplicating the resource. Otherwise
	; the document was created with ObjInstantiate in the
	; same block as the Control and we should just free the object

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GDGI_genDocument.handle
	jnz	freeBlock

	mov	ax,MSG_META_OBJ_FREE			; free object only
	jmp	freeIt

freeBlock:
	mov	ax,MSG_META_BLOCK_FREE			; free whole block
freeIt:
	pop	bx,si					; document OD
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	ret
OLDocumentGroupRemoveDoc	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupSaveAsCancelled --
		    MSG_GEN_DOCUMENT_GROUP_SAVE_AS_CANCELLED for
				OLDocumentGroupClass

DESCRIPTION:	Cancel quitting

PASS:
	*ds:si - instance data
	es - segment of OLApAppocumentControlClass

	ax - MSG_GEN_DOCUMENT_GROUP_SAVE_AS_CANCELLED

RETURN:

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
OLDocumentGroupSaveAsCancelled	method dynamic \
					OLDocumentGroupClass,
				    MSG_GEN_DOCUMENT_GROUP_SAVE_AS_CANCELLED

	mov	ax, MSG_OLDG_USER_CLOSE_CANCELLED
	call	ObjCallInstanceNoLock

	; inform target document

	mov	ax, MSG_GEN_DOCUMENT_SAVE_AS_CANCELLED
	clr	cx
	call	SendToCXDXOrTargetDocument

	;
	; Clear out any pending query-save-documents reply.  3/30/94 cbh
	;
	clr	cx
	mov	ax, MSG_META_QUERY_SAVE_DOCUMENTS
	GOTO	ObjCallInstanceNoLock

OLDocumentGroupSaveAsCancelled	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupUserCloseCancelled --
		    MSG_OLDG_USER_CLOSE_CANCELLED for
				OLDocumentGroupClass

DESCRIPTION:	User close cancelled

PASS:
	*ds:si - instance data
	es - segment of OLApAppocumentControlClass

	ax - MSG_OLDG_USER_CLOSE_CANCELLED

RETURN:

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
OLDocumentGroupUserCloseCancelled	method dynamic \
					OLDocumentGroupClass,
				    MSG_OLDG_USER_CLOSE_CANCELLED

	clr	ax
	mov	ds:[di].OLDGI_quitObj.chunk, ax
	xchg	ax, ds:[di].OLDGI_quitObj.handle
	tst	ax
	jz	notQuitting
	mov	cx, -1				;cx = non-zero (abort)
	mov	ax, MSG_META_QUIT_ACK
	push	si				;save app doc control ptr
	call	SendToUIDocControl
	pop	si				;restore ptr
notQuitting:

	ret

OLDocumentGroupUserCloseCancelled	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupUserCloseOK --
		    MSG_OLDG_USER_CLOSE_OK for
				OLDocumentGroupClass

DESCRIPTION:	User close OK

PASS:
	*ds:si - instance data
	es - segment of OLApAppocumentControlClass

	ax - MSG_OLDG_USER_CLOSE_OK

RETURN:

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
OLDocumentGroupUserCloseOK	method dynamic \
					OLDocumentGroupClass,
				    MSG_OLDG_USER_CLOSE_OK

	tst	ds:[di].OLDGI_quitObj.handle
	jz	notQuitting
	mov	ax, MSG_META_QUIT			;continue
	call	ObjCallInstanceNoLock
notQuitting:
	ret

OLDocumentGroupUserCloseOK	endm






COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupQuerySaveDocuments -- 
		MSG_META_QUERY_SAVE_DOCUMENTS for OLDocumentGroupClass

DESCRIPTION:	Queries user to save any opened documents, prior to switching
		applications.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_QUERY_SAVE_DOCUMENTS
		cx	- event to use after we`ve done our duty

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
	chris	6/23/93         	Initial Version

------------------------------------------------------------------------------@

if VOLATILE_SYSTEM_STATE

OLDocumentGroupQuerySaveDocuments	method dynamic	OLDocumentGroupClass, \
				MSG_META_QUERY_SAVE_DOCUMENTS

	;
	; Save the passed event to use when we're done.
	; If there's already an event hanging around, let's nuke it.
	;
	mov	bx, ds:[di].OLDGI_appSwitchMsg		;get current message
	mov	ds:[di].OLDGI_appSwitchMsg, cx		;store new message
	tst	bx					;no old message, branch
	jz	10$
	call	ObjFreeMessage

10$:
	;
	; If no message was passed in cx, the system is trying to flush
	; out the query message because of a user cancel, so we'll do
	; nothing further.   3/30/94 cbh
	;
	tst	cx
	jz	exit

	mov	ax, MSG_OL_DOCUMENT_WAIT_FOR_QUERY
	call	GenSendToChildren		;have documents wait for query

					;if anyone is clean, mark them now
	mov	ax, MSG_OLDG_DOC_MARKED_CLEAN
	call	ObjCallInstanceNoLock
exit:
	ret
OLDocumentGroupQuerySaveDocuments	endm

endif




COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupDocMarkedClean -- 
		MSG_OLDG_DOC_MARKED_CLEAN for OLDocumentGroupClass

DESCRIPTION:	Sent when a document marks itself clean.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OLDG_DOC_MARKED_CLEAN

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
	chris	7/26/93         Initial Version

------------------------------------------------------------------------------@

if VOLATILE_SYSTEM_STATE

OLDocumentGroupDocMarkedClean	method dynamic	OLDocumentGroupClass, \
				MSG_OLDG_DOC_MARKED_CLEAN

	;
	; Not in app switching mode, exit
	;
	mov	cx, ds:[di].OLDGI_appSwitchMsg
	tst	cx
	jz	exit

	;
	; Collect the number of currently dirty documents.
	;
	push	cx
	call	CheckDirtyDocuments		;counts number of dirties
	pop	bx				;restore app switch message
	jc	stillDirty			;still a dirty document, branch
	;
	; Fire off the stored app switching message.
	;
	mov	di, mask MF_FORCE_QUEUE		
	call	MessageDispatch	

	;
	; Event fired off, nuke references to it.
	;
EC <	call	VisCheckVisAssumption					>
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	clr	ds:[di].OLDGI_appSwitchMsg
	jmp	short exit

stillDirty:		
	;
	; Still at least one dirty document open, go fire off another
	; MSG_META_QUERY_SAVE_DOCUMENTS to a document that is waiting for it.
	;
	call	QueryFirstDocumentWaiting
	
exit:
	ret
OLDocumentGroupDocMarkedClean	endm

endif





COMMENT @----------------------------------------------------------------------

ROUTINE:	QueryFirstDocumentWaiting

SYNOPSIS:	Sends message to the first document still waiting for a query.

CALLED BY:	OLDocumentGroupDocMarkedClean

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/27/93       	Initial version

------------------------------------------------------------------------------@

if VOLATILE_SYSTEM_STATE

QueryFirstDocumentWaiting	proc	near
	mov	ax, MSG_OL_DOCUMENT_QUERY_IF_WAITING
	clr	bx				; initial child (first
	push	bx				; child of
	push	bx				; composite)
	mov	bx,offset GI_link		;pass offset to LinkPart
	push	bx
	clr	bx
	push	bx				;send message
;	ornf	bx, OCCT_SAVE_PARAMS_TEST_ABORT
	push	bx
	mov	bx,offset Gen_offset		;pass offset to master part
	mov	di,offset GI_comp		;pass offset to composite
	call	ObjCompProcessChildren
	ret
QueryFirstDocumentWaiting	endp

endif




DocSaveAsClose ends

Resident	segment resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckDirtyDocuments, CheckDocumentDirty

SYNOPSIS:	Checks if any document dirty, or on the ramdisk.

CALLED BY:	OLDocumentGroupDocMarkedClean

PASS:		*ds:si -- doc group/ document

RETURN:		carry set if any dirty documents

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/26/93       	Initial version

------------------------------------------------------------------------------@

if VOLATILE_SYSTEM_STATE

CheckDirtyDocuments	proc	far
	mov	bx, offset CheckDocumentDirty
	clr	di			;do all children
	call	OLResidentProcessGenChildrenFromDI
	ret
CheckDirtyDocuments	endp

CheckDocumentDirty	proc	far
	;
	;
	;
	class	GenDocumentClass

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_AUTO_SAVE_STOPPED
						;no autosave, hopefully means
	clc					; shutting down, ignore whether
						; on ramdisk and exit c=0
	jnz	exit

	call	DocCheckIfOnRamdisk		;document still on the ramdisk,
	jz	dirty				;  we need to return "dirty".

	test	ds:[di].GDI_attrs, mask GDA_DIRTY
	jz	exit
dirty:
	stc					;return carry set and quit
exit:
	ret
CheckDocumentDirty	endp

endif

Resident	ends
