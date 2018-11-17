COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainUIDocOperations.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLDocumentControl	Open look document control class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:

	$Id: cmainUIDocOperations.asm,v 1.1 97/04/07 10:51:54 newdeal Exp $

-------------------------------------------------------------------------------@


DocDialog segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlInitiateNewDoc --
		MSG_GEN_DOCUMENT_CONTROL_INITIATE_NEW_DOC for
					OLDocumentControlClass

DESCRIPTION:	Initiate "new" dialog box (if any exists)

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_GEN_DOCUMENT_CONTROL_INITIATE_NEW_DOC

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
OLDocumentControlInitiateNewDoc	method OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_INITIATE_NEW_DOC


	call	OLDCRemoveSummons


	; get a parameter frame on the stack

	sub	sp, size DocumentCommonParams
	mov	bp, sp

	mov	ss:[bp].DCP_flags, 0
	mov	ss:[bp].DCP_diskHandle, 0
	mov	ss:[bp].DCP_docAttrs, mask GDA_UNTITLED
	mov	ss:[bp].DCP_connection, 0

	mov	ax, MSG_GEN_DOCUMENT_GROUP_NEW_DOC
	mov	dx, size DocumentCommonParams
	call	SendToAppDCFrame

	add	sp, size DocumentCommonParams
done::
	Destroy	ax, cx, dx, bp
	ret

OLDocumentControlInitiateNewDoc	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDCRemoveSummons

DESCRIPTION:	Nuke the current summons

CALLED BY:	INTERNAL

PASS:
	*ds:si - ui document control

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
	Tony	5/ 1/92		Initial version

------------------------------------------------------------------------------@
OLDCRemoveSummons	proc	far		uses ax, bx, cx, dx, di, bp
	class	OLDocumentControlClass
	.enter

	; first bring in down

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	bx
	mov	ds:[di].OLDCI_currentFileType, bx
	xchg	bx, ds:[di].OLDCI_currentSummons
	tst	bx
	LONG jz	done

	mov	bp, si
	mov	si, offset FileNewSummons
if _DUI
	;
	; For Jedi, the dialog displayed on screen can be a primary window.
	; If that is the case, then we don't dismiss it; we just make it not
	; usable.
	;
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	cx, segment GenPrimaryClass
	mov	dx, offset GenPrimaryClass
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;ax,cx,dx,bp trashed
	jnc	notPrimary
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	dialogDown
notPrimary:
endif
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
if _DUI
dialogDown::
endif
	xchg	si, bp			;*ds:si = doc control, bx:bp = summons

	; must make user's group not usable

	push	bx
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDCI_attrs
	push	ax
	and	ax, not mask GDCA_CURRENT_TASK
	mov	ds:[di].GDCI_attrs, ax
	pop	ax
	and	ax, mask GDCA_CURRENT_TASK

	mov	bx, offset GDCI_openGroup
	cmp	ax, GDCT_OPEN shl offset GDCA_CURRENT_TASK
	jz	doRemove
	mov	bx, offset GDCI_useTemplateGroup
	cmp	ax, GDCT_USE_TEMPLATE shl offset GDCA_CURRENT_TASK
	jz	doRemove
	mov	bx, offset GDCI_saveAsGroup
	cmp	ax, GDCT_SAVE_AS shl offset GDCA_CURRENT_TASK
	jne	removeNoTask
doRemove:
	call	removeGroupAtGroupAtDIBX
removeNoTask:
	mov	bx, offset GDCI_dialogGroup
	call	removeGroupAtGroupAtDIBX
if _DUI
	;
	; unhook Edit menu UI
	;
	mov	bx, offset GDCI_openGroup
	call	removeGroupAtGroupAtDIBX
endif
	pop	bx

	; remove the block

	xchg	si, bp				;bx:si = summons
	push	ds:[LMBH_handle]		;save for fixing up DS
	call	UserDestroyDialog		;Use optimized, common routine
	pop	bx
	call	MemDerefDS
	xchg	si, bp				;bx:si = doc control
done:
	.leave
	ret

removeGroupAtGroupAtDIBX:
	push	ax, bx, cx, dx, si, bp
	mov	si, ds:[di][bx].chunk
	mov	bx, ds:[di][bx].handle
	tst	bx
	jz	removeDone
	mov	ax, MSG_GEN_REMOVE
	mov	dl, VUM_NOW
	clr	bp
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
removeDone:
	pop	ax, bx, cx, dx, si, bp
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	retn

OLDCRemoveSummons	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetAppLevel

DESCRIPTION:	Get the application level

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	ax - level (UIInterfaceLevel)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 6/92	Initial version

------------------------------------------------------------------------------@
GetAppLevel	proc	far	uses cx, dx, bp
	.enter

	mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
	call	GenCallApplication
	mov_tr	ax, dx

	.leave
	ret

GetAppLevel	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetFSLevel

DESCRIPTION:	Get the level for file selectors

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	ax - level (UIInterfaceLevel)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 6/92	Initial version

------------------------------------------------------------------------------@
GetFSLevel	proc	far	uses ds
	.enter

	mov	ax, segment docControlFSLevel
	mov	ds, ax
	mov	ax, ds:[docControlFSLevel]

	.leave
	ret

GetFSLevel	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetDocOptions

DESCRIPTION:	Get the level for file selectors

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	ax - DocControlOptions

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 6/92	Initial version

------------------------------------------------------------------------------@
GetDocOptions	proc	far	uses ds
	.enter

	mov	ax, segment docControlOptions
	mov	ds, ax
	mov	ax, ds:[docControlOptions]

	.leave
	ret

GetDocOptions	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlInitiateOpenDoc --
		MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC for
						OLDocumentControlClass

DESCRIPTION:	Initiate "open" dialog box (if any exists)

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC

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

if not _DUI

OLDocumentControlInitiateOpenDoc	method dynamic OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC

	mov	ax, GDCT_OPEN shl offset GDCA_CURRENT_TASK
	mov	bx, handle DocumentOpenUI
	mov	cx, offset GDCI_openGroup
	mov	dx, 3
	mov	di, vseg SetupForOpen
	mov	bp, offset SetupForOpen
	call	OLDCBringUpSummons
	Destroy	ax, cx, dx, bp
	ret

OLDocumentControlInitiateOpenDoc	endm

endif		; if (not _NIKE) and (not _JEDIMOTIF) and (not _DUI_) --------


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetupForOpen

DESCRIPTION:	Setup for the open dialog box

CALLED BY:	INTERNAL

PASS:
	cx - block of duplicated UI
	*ds:si - GenDocumentControl

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
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
SetupForOpen	proc	far
	class	OLDocumentControlClass

	mov	bx, cx

	call	GetAppLevel		;Can't open document as read only,
	cmp	ax, UIIL_ADVANCED	; unless in advanced mode
	jnz	biffInfoGroup

	call	GetDocOptions		;
	test	ax, mask DCO_NO_OPEN_READ_ONLY_OPTIONS
	mov	ax, UIIL_ADVANCED	;
	jz	noBiffInfoGroup

biffInfoGroup:
	push	ax, si
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	si, offset OpenInfoGroup
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, si

noBiffInfoGroup:

	; if using native files then no user notes

	cmp	ax, UIIL_INTERMEDIATE
	jb	biffUserNotes
	call	GetDocOptions
	test	ax, mask DCO_NO_NOTES_IN_OPEN_BOX
	jnz	biffUserNotes
	call	OLDocumentControlGetAttrs
	test	ax, mask GDCA_NATIVE
	jz	afterUserNotes
biffUserNotes:
	push	si
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	si, offset OpenUserNotesTextDisplay
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
afterUserNotes:

if not NO_USER_LEVELS
	push	si
	mov	dl, VUM_NOW
	mov	si, offset OpenSimpleTrigger
	call	GetDocOptions
	test	ax, mask DCO_FS_CANNOT_CHANGE
	jnz	nukeBoth
	call	GetFSLevel
	cmp	ax, UIIL_INTERMEDIATE
	jb	gotTrigger
	jmp	dontNukeBoth
nukeBoth:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
dontNukeBoth:
	mov	si, offset OpenAdvancedTrigger
gotTrigger:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
endif


if _DUI
	; set IMPORT not usable if it is not available

	call	GetAppLevel				;ax = app level
	cmp	ax, UIIL_INTRODUCTORY
	jz	forceNoImport
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GDCI_importGroup.handle
	jnz	afterImport
forceNoImport:
	push	si
	mov	si, offset OpenImportTrigger
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
afterImport:

	; if we have a document open, then switch moniker to 'cancel'

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDCI_attrs, mask GDCA_DOCUMENT_EXISTS
	jz	noChange

	push	si
	mov	si, offset CancelOpenTrigger
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	clr	cx
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; change the button's action

	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_OLDC_REMOVE_OLD_AND_TEST_FOR_DISPLAY_MAIN_DIALOG
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	clr	cx
	mov	dx, TO_OBJ_BLOCK_OUTPUT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; nuke the ATTR_GEN_DESTINATION_CLASS

	push	ds
	call	ObjLockObjBlock
	mov	ds, ax
	mov	ax, ATTR_GEN_DESTINATION_CLASS
	call	ObjVarDeleteData
	call	MemUnlock
	pop	ds
	pop	si
noChange:

else	; (not _NIKE) && (not _JEDIMOTIF) && (not _DUI)

	; if this is a viewer mode app then tweak the cancel trigger

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDCI_attrs
	and	ax, mask GDCA_MODE
	cmp	ax, GDCM_VIEWER shl offset GDCA_MODE
	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	cx, ATTR_GEN_DESTINATION_CLASS
	mov	si, offset CancelOpenTrigger
	jnz	viewerCommon

if _MOTIF or _ISUI
	; Viewer: If no documents are open, make it an Exit <app> trigger.
	clr	cx	; use "cancel" if doc exists
	push	di
	test	ds:[di].GDCI_attrs, mask GDCA_DOCUMENT_EXISTS
	jnz	setMoniker
	mov	cx, offset CancelOpenExitMoniker
setMoniker:
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	test	ds:[di].GDCI_attrs, mask GDCA_DOCUMENT_EXISTS
	jnz	cancelDone
	call	MakeExitAppMoniker
endif
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	clr	cx
	mov	dx, TO_GEN_PARENT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_META_QUIT
viewerCommon:
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
cancelDone::
	pop	si
endif

	; set the file selector correctly

if _DUI
;although we don't use the template dir for the document count title, we
;still set the template dir as the moniker to flag that we should enable
;the document count -- brianc 3/1/97
	;
	; replace default "Documents" in document count
	;	*ds:si = document control
	;	bx = duplicated UI block
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GDCI_templateDir
	tst	di
	jz	noName
	push	si
	mov	si, offset OpenFileSelector	; ^lbx:si = FS
	mov	dx, ds:[di]			; cx:dx = name
	mov	cx, ds
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
noName:
endif

	;
	; always set SP_DOCUMENT if in simple mode - brianc 7/20/93
	;
	call	GetDocOptions
	test	ax, mask DCO_FS_CANNOT_CHANGE
	jnz	allowUIDCDir			; can't change levels
	call	GetFSLevel
	cmp	ax, UIIL_INTERMEDIATE
	jae	allowUIDCDir			; UIIL_INTERMEDIATE or above
	push	si				; save UIDC
	mov	si, offset OpenFileSelector	; ^lbx:si = FS

NOFXIP<	mov	cx, cs							>
NOFXIP<	mov	dx, offset sfoNullPath		; cx:dx = pathname	>

FXIP <	push	ds							>
FXIP <	segmov	ds, cs, dx						>
FXIP <	mov	dx, offset sfoNullPath					>
FXIP <	clr	cx							>
FXIP <	call	SysCopyToStackDSDX					>
FXIP <	mov	cx, ds				; cx:dx = string	>
FXIP <	pop	ds							>

	mov	bp, SP_DOCUMENT
	mov	ax, MSG_GEN_PATH_SET
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	
FXIP <	call	SysRemoveFromStack					>
	
	mov	di, si				; ^lbx:di = FS
	pop	si				; *ds:si = UIDC
	jmp	setupFSCommon			; pass ^lbx:di = FS
						;	*ds:si = UIDC
allowUIDCDir:

	mov	di, offset OpenFileSelector
	call	OLDCCopyPathToFS
setupFSCommon:
	clr	ax
	call	SetupFileSelector
	ret

SetupForOpen	endp

LocalDefNLString sfoNullPath <0>

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlInitiateUseTemplateDoc --
		MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC for
						OLDocumentControlClass

DESCRIPTION:	Initiate "use template" dialog box (if any exists)

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC

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

if	_USE_DESIGN_ASSISTANT_FOR_TEMPLATES
designAssistantToken	GeodeToken <<'DSAS'>, 0>
endif

OLDocumentControlInitiateUseTemplateDoc	method dynamic \
					OLDocumentControlClass,
			MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC

if	_USE_DESIGN_ASSISTANT_FOR_TEMPLATES
	; Create an AppLaunchBlock
	;
	mov	ax, size AppLaunchBlock
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	jc	displayError
	push	ds
	mov	ds, ax
	mov	ds:[ALB_launchFlags], mask ALF_OVERRIDE_MULTIPLE_INSTANCE
	call	MemUnlock
	pop	ds

	; Now use IACP to launch the application
	;
	mov	ax, mask IACPCF_FIRST_ONLY or \
		    (IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	segmov	es, cs, di
	mov	di, offset designAssistantToken
	call	IACPConnect			; (frees AppLaunchBlock)
	jc	displayError
	clr	cx				; client shutting down
	call	IACPShutdown

	;
	; remove current dialog
	;
	call	OLDCRemoveSummons
done:
else
	mov	ax, GDCT_USE_TEMPLATE shl offset GDCA_CURRENT_TASK
	mov	bx, handle DocumentUseTemplateUI
	mov	cx, offset GDCI_useTemplateGroup
	mov	dx, 3
	mov	di, vseg SetupForUseTemplate
	mov	bp, offset SetupForUseTemplate
	call	OLDCBringUpSummons
endif
	Destroy	ax, cx, dx, bp
	ret

if	_USE_DESIGN_ASSISTANT_FOR_TEMPLATES
	; Couldn't load the Design Assistant, so notify the user
	;
displayError:
	jmp	done		
endif
OLDocumentControlInitiateUseTemplateDoc	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	SetupForUseTemplate

DESCRIPTION:	Setup for the use template dialog box

CALLED BY:	INTERNAL

PASS:
	cx - block of duplicated UI
	*ds:si - GenDocumentControl

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
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

SetupForUseTemplate	proc	far
	class	OLDocumentControlClass
	mov	bx, cx
;;ife _JEDIMOTIF
	call	GetAppLevel
	cmp	ax, UIIL_ADVANCED
	jz	advanced

	push	si
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	si, offset UseTemplateForEditingList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
advanced:
	; if using native files then no user notes
	; (New code for open template 4/29/94 cbh)
	; (

	call	GetAppLevel
	cmp	ax, UIIL_INTERMEDIATE
	jb	biffUserNotes
	call	GetDocOptions
	test	ax, mask DCO_NO_NOTES_IN_OPEN_BOX
	jnz	biffUserNotes
	call	OLDocumentControlGetAttrs
	test	ax, mask GDCA_NATIVE
	jz	afterUserNotes
biffUserNotes:
	push	si
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	si, offset UseTemplateUserNotesTextDisplay
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
afterUserNotes:
	;)
;;endif
		

	; set the file selector correctly

	mov	di, offset UseTemplateFileSelector
	mov	ax, mask OLDCFSF_TEMPLATE
	call	SetupFileSelector
	ret
SetupForUseTemplate	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetupFileSelector

DESCRIPTION:	Setup a file selector

CALLED BY:	INTERNAL

PASS:
	ax - OLDCFileSelectorFlags
	*ds:si - GenDocumentControl
	^lbx:di - GenFileSelector to set up

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
SetupFileSelector	proc	far
	class	OLDocumentControlClass
	.warn	-private

EC <	call	AssertIsUIDocControl					>

	push	di			; save FS chunk for subclass
	push	ax			; save flags

	; if the DC is managing VM files, then set the token to match. the
	; object must have a document token, since the VM file needs it.

	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	bp, ds:[si].GDCI_attrs
	test	bp, mask GDCA_VM_FILE
	jz	tokenSet
	push	bp

	; set the token via a message, as it's too much trouble for us to
	; add the vardata, etc. it's gross, too :)

	mov	cx, {word} ds:[si].GDCI_documentToken.GT_chars[0]
	mov	dx, {word} ds:[si].GDCI_documentToken.GT_chars[2]
	mov	bp, ds:[si].GDCI_documentToken.GT_manufID
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_TOKEN
	mov	si, di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	di, si					; ^lbx:di <- fs again
	pop	bp
tokenSet:
	pop	si

	; if this is a template file selector then change to the template
	; directory

	pop	ax
	push	ax
	test	ax, mask OLDCFSF_TEMPLATE
	LONG jz	notTemplate

if	not _USE_DESIGN_ASSISTANT_FOR_TEMPLATES
	call	EnsureTemplateDir
endif

	push	si, di, bp
	call	FilePushDir

	push	bx, di
	clrdw	cxdx				;assume no template path
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GDCI_templateDir
	mov	dx, ds:[di]
	mov	bx, SP_TEMPLATE			;bx <- disk handle
	call	FileSetCurrentPath

	; check for introductory templates

	call	GetAppLevel
	cmp	ax, UIIL_INTRODUCTORY
	jnz	gotTemplateDir
	push	ds
	mov	bx, handle IntroductoryTemplateDir 
	call	MemLock
	mov	ds, ax
	mov	dx, ds:[IntroductoryTemplateDir]	;ds:dx = path
	clr	bx
	call	FileSetCurrentPath
	mov	bx, handle IntroductoryTemplateDir 
	call	MemUnlock
	pop	ds
gotTemplateDir:
	pop	bx, di				;bxdi = file selector

	sub	sp, size PathName
	mov	si, sp
	push	bx, di, ds
	segmov	ds, ss
	mov	cx, size PathName
	call	FileGetCurrentPath
	mov	bp, bx				;bp = disk handle
	pop	bx, si, ds

	mov	cx, ss
	mov	dx, sp				;cx:dx = path
	mov	ax, MSG_GEN_PATH_SET
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; set virtual root

	push	bx, ds
	call	ObjLockObjBlock
	mov	ds, ax				;*ds:si - file sel

	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	VarDataSizePtr	ds, bx, cx		;cx = size
	mov	ax, ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
	call	ObjVarAddData
	mov	di, bx				;ds:di = dest
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	mov	si, bx				;ds:si = source
	segmov	es, ds
	rep	movsb
	pop	bx, ds
	call	MemUnlock

	add	sp, size PathName
	call	FilePopDir
	pop	si, di, bp
	jmp	fsCommon

notTemplate:

if CUSTOM_DOCUMENT_PATH
	;
	; Copy the ATTR_GEN_PATH_DATA of the DocControl object to the
	; FileSelector.
	; 
	call	CustomDocPathSetupFileSelectorPath
endif ; CUSTOM_DOCUMENT_PATH

	; remove the VIRTUAL root if so requested

	call	GetDocOptions
	test	ax, mask DCO_NAVIGATE_ABOVE_DOC
	jz	fsCommon

	push	si, ds
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, di
	mov	ax, ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
	call	ObjVarDeleteData
	call	MemUnlock
	pop	si, ds

fsCommon:
	call	ObjLockObjBlock
	mov	es, ax
	mov	di, es:[di]
	add	di, es:[di].Gen_offset			;es:di = file selector
	mov	ax, mask FSFC_DIRS or mask FSFC_GEOS_NON_EXECUTABLES
	test	bp, mask GDCA_VM_FILE
	jnz	gotFileType
	mov	ax, mask FSFC_DIRS or mask FSFC_NON_GEOS_FILES or \
			mask FSFC_MASK_CASE_INSENSITIVE
gotFileType:

	; restrict to only directories if flag passed

	pop	cx

	push	cx

if not SAVE_AS_SHOWS_EXISTING_FILES_AS_ENABLED
	;
	; Redwood, we'll allow non-dirs and just to nothing when they're
	; pressed.
	;
	test	cx, mask OLDCFSF_SAVE
	jz	notSave
	andnf	ax, not (mask FSFC_NON_GEOS_FILES or \
				mask FSFC_GEOS_EXECUTABLES or \
				mask FSFC_GEOS_NON_EXECUTABLES)
endif


notSave:
	mov	es:[di].GFSI_fileCriteria, ax

	; if simpleFS mode then don't allow directory and volume switching

	call	GetFSLevel			;ax = level

	; if introductory then cannot change directories

	cmp	ax, UIIL_BEGINNING
	jae	notIntro
	and	es:[di].GFSI_attrs, not (mask FSA_ALLOW_CHANGE_DIRS or \
					 mask FSA_HAS_CLOSE_DIR_BUTTON or \
					 mask FSA_HAS_OPEN_DIR_BUTTON)
	and	es:[di].GFSI_fileCriteria, not mask FSFC_DIRS

	; intro save gets no file list (since no directories)

	pop	cx
	push	cx
	test	cx, mask OLDCFSF_SAVE
	jz	notIntro
	and	es:[di].GFSI_attrs, not mask FSA_HAS_FILE_LIST
notIntro:

	; if introductory or beginner then cannot change drives

	pop	cx				;cx = flags
	test	cx, mask OLDCFSF_TEMPLATE
	jnz	forceIntroBeg
	cmp	ax, UIIL_INTERMEDIATE
	jae	notIntroBeg
forceIntroBeg:
	and	es:[di].GFSI_attrs, not (mask FSA_HAS_CHANGE_DRIVE_LIST or \
					 mask FSA_HAS_DOCUMENT_BUTTON or \
					 mask FSA_HAS_CHANGE_DIRECTORY_LIST)
notIntroBeg:

if	SINGLE_DRIVE_DOCUMENT_DIR
	;
	; Always allow document (i.e. New disk) button.   6/29/94 cbh
	;
	or	es:[di].GFSI_attrs, mask FSA_HAS_DOCUMENT_BUTTON

	;
	; Don't allow switching of disks in save-as if demand paging is being 
	; used, because of the nightmare disk swaps.   We'll allow it when the
	; current doc is on the ramdisk, though.
	;
	test	cx, mask OLDCFSF_SAVE
	jz	allowDiskSwitching
	push	ax
	call	OLDocumentControlGetAttrs
	test	ax, mask GDCA_FORCE_DEMAND_PAGING
	pop	ax
	jz	allowDiskSwitching
	call	DocCheckIfOnRamdisk		
	jz	allowDiskSwitching
	and	es:[di].GFSI_attrs, not (mask FSA_HAS_DOCUMENT_BUTTON)
allowDiskSwitching:

endif

	call	MemUnlock

if _DUI
	;
	; in _DUI, we only have a single file open at a time, so we can
	; use GDCI_targetDocName (the previously opened document) to set
	; the file selector selection to the just closed document
	;	*ds:si = GenDocumentControl
	;	^lbx:(stack) = file selector
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	dx, ds:[di].GDCI_targetDocName
	mov	cx, ds				; cx:dx = filename
	mov	ax, si				; *ds:ax = GenDocumentControl
	pop	si
	push	si				; ^lbx:si = file selector
	push	ax				; save GenDocumentControl
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si				; *ds:si = GenDocumentControl
endif

	; send a message to ourself to allow subclasses to muck with the
	; file selector

	mov	cx, bx
	pop	dx			;cx:dx = file selector
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR
	call	ObjCallInstanceNoLock

	.warn	@private
	ret

SetupFileSelector	endp


if CUSTOM_DOCUMENT_PATH

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustomDocPathSetupFileSelectorPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the ATTR_GEN_PATH_DATA from the DocControl to
		the FileSelector.  Then, set that as the Virtual Root.

CALLED BY:	(INTERNAL) SetupFileSelector

PASS:		*ds:si	- GenDocumentControlClass object
		^lbx:di	- GenFileSelector object

RETURN:		ds	- Fixed up.

DESTROYED:	none
SIDE EFFECTS:	

	ATTR_GEN_PATH_DATA & ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
	may be added to the FileSelector.  

	WARNING:  This routine MAY resize the LMem blocks, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

if DocControl->ObjVarFindData( ATTR_GEN_PATH_DATA )
	FileSelector->ObjVarAddData(ATTR_GEN_PATH_DATA)
	FileSelector->ObjVarAddData(ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT)
endif

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ptrinh	12/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CustomDocPathSetupFileSelectorPath	proc	near

	DCLptr	local	lptr	push	si
	FSHptr	local	hptr	push	bx
	FSLptr	local	lptr	push	di

	uses	ax,bx,cx,si,di,es
	.enter

	;
	; Check if GenDocumentControl object has vardata.
	;
		mov	ax, ATTR_GEN_PATH_DATA
		call	ObjVarFindData		; ds:bx - DC var data ptr
		jnc	done

		VarDataSizePtr	ds, bx, cx	; cx = size

	;
	; Copy ATTR_GEN_PATH_DATA var data from DocControl (DC) to
	; FileSelector (FS).
	;
		mov	bx, ss:[FSHptr]
		call	ObjLockObjBlock		; ax <- FS segment
		movdw	essi, axdi		; *es:si <- FS
		segxchg	ds, es, ax		; ds <- FS, es <- DC

		mov	ax, ATTR_GEN_PATH_DATA
		call	ObjVarAddData		; bx <- FS vardata offset
		segxchg	ds, es, di		; ds <- DC, es <- FS
		mov	di, bx			; es:di - (dest)
	;
	; The LMem heap may have shifted, so we update our ptr.
	;
		mov	si, ss:[DCLptr]		; *ds:si - DC

		mov	ax, ATTR_GEN_PATH_DATA
		call	ObjVarFindData		; bx <- DC vardata offset
		mov_tr	si, bx			; ds:si - (src)

		mov	ax, cx			; save size of vardata
		rep	movsb			; COPY!
	;
	; Add ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT.
	;
		mov_tr	cx, ax			; size of vardata

		segxchg	ds, es, ax		; ds <- FS, es <- DC
		mov	si, ss:[FSLptr]		; ds:si - FS
		mov	ax, ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
		call	ObjVarAddData		; bx <- FS vardata offset
		segxchg	ds, es, ax		; ds <- DC, es <- FS
		mov	di, bx			; es:di - (dest)
	;
	; The LMem heap may have shifted, so we update our ptr.
	;
		mov	si, ss:[DCLptr]		; *ds:si - DC

		mov	ax, ATTR_GEN_PATH_DATA
		call	ObjVarFindData		; bx <- FS vardata offset

		mov_tr	si, bx			; ds:si - (src)
		rep	movsb
	;
	; Unlock locked memory.
	;
		mov	bx, ss:[FSHptr]
		call	MemUnlock
done:
	.leave
	ret
CustomDocPathSetupFileSelectorPath	endp

endif ; CUSTOM_DOCUMENT_PATH




COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlFileSelected -- MSG_OLDC_OPEN_FILE_SELECTED
				and MSG_OLDC_DIR_SELECTED
				for OLDocumentControlClass

DESCRIPTION:	Sent by GenFileSelector when a file is selected -> get file
		name and attributes from dialog box and open a document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_OLDC_OPEN_FILE_SELECTED, MSG_OLDC_DIR_SELECTED

	bp - GenFileSelectorEntryFlags

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

OpenFlagsFrame	struct
    OFF_docParams		DocumentCommonParams
    OFF_flags			GenFileSelectorEntryFlags
    OFF_enableForEditing	BooleanByte
    OFF_selectForEditing	BooleanByte
    OFF_enableTextObj		BooleanByte
    OFF_userNotes		FileUserNotes
    OFF_message			word
    even
OpenFlagsFrame	ends

OLDocumentControlFileSelected	method dynamic OLDocumentControlClass,
					MSG_OLDC_OPEN_FILE_SELECTED,
					MSG_OLDC_USE_TEMPLATE_FILE_SELECTED,
					MSG_OLDC_SAVE_AS_DIR_SELECTED,
					MSG_OLDC_COPY_TO_DIR_SELECTED,
					MSG_OLDC_MOVE_TO_DIR_SELECTED

	mov	bx, ds:[di].OLDCI_currentSummons
	tst	bx
	jz	error


	; if error, report it

	test	bp, mask GFSEF_ERROR or mask GFSEF_NO_ENTRIES
	jz	noError
if _DUI
	;
	; Errors or no items, turn off appropriate UIs.
	;
	call	disableActivationUI
endif
error:
	Destroy	ax, cx, dx, bp
	ret

noError:
	mov	cx, offset SaveAsFileSelector
	mov	dx, offset SaveAsDirText
	cmp	ax, MSG_OLDC_SAVE_AS_DIR_SELECTED	; nothing else to do for
	je	saveAsCopyTo				;	Save As case

	mov	cx, offset CopyToFileSelector
	mov	dx, offset CopyToDirText
	cmp	ax, MSG_OLDC_COPY_TO_DIR_SELECTED	; nothing else to do for
	je	saveAsCopyTo				;	Save As case

if not _DUI
	mov	cx, offset MoveToFileSelector
	mov	dx, offset MoveToDirText
	cmp	ax, MSG_OLDC_MOVE_TO_DIR_SELECTED	; nothing else to do for
	je	saveAsCopyTo				;	Save As case
endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for NIKE project

	; if not opening a file update based on what the file is

	test	bp, mask GFSEF_OPEN
	jz	notOpen
		CheckHack <GFSET_FILE eq 0>
	test	bp, mask GFSEF_TYPE
	jnz	exitHere

	cmp	ax, MSG_OLDC_USE_TEMPLATE_FILE_SELECTED
	mov	ax, MSG_OLDC_USE_TEMPLATE_SELECTED
	jz	gotMessage
	mov	ax, MSG_OLDC_OPEN_SELECTED
gotMessage:
	call	ObjCallInstanceNoLock
exitHere:
	Destroy	ax, cx, dx, bp
	ret

	; for save-as or copy-to we want to display the directory to be saved
	; to
	; bxcx = file selector, bxdx = text

saveAsCopyTo:

	call	SetDirText

	jmp	exitHere

notOpen:

	; something selected -- update stuff

	push	ax, si, bp
if _DUI
	mov	si, offset FDOpenTrigger
else
	mov	si, offset OpenFileTrigger
endif
	cmp	ax, MSG_OLDC_OPEN_FILE_SELECTED
	jz	gotTriggerChunk
	mov	si, offset UseTemplateFileTrigger
gotTriggerChunk:
	andnf	bp, mask GFSEF_TYPE
	mov	ax, MSG_GEN_SET_ENABLED
	cmp	bp, GFSET_FILE shl offset GFSEF_TYPE
	jz	gotTriggerMessage
	mov	ax, MSG_GEN_SET_NOT_ENABLED
gotTriggerMessage:
if _DUI
	;
	; if main screen, set state of Edit menu items as well
	;
	call	vumNowFixup
	cmp	si, offset FDOpenTrigger
	jne	notListScreen
	call	setEditMenuItems
notListScreen:
else
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
endif
	pop	ax, si, bp

	mov	cx, bp
	sub	sp, size OpenFlagsFrame
	mov	bp, sp
	mov	ss:[bp].OFF_message, ax
	clr	ax
	mov	{word} ss:[bp].OFF_enableForEditing, ax	;assume not enabled
	mov	ss:[bp].OFF_enableTextObj, al
	mov	ss:[bp].OFF_flags, cx
SBCS <	mov	ss:[bp].OFF_userNotes[0], al				>
DBCS <	mov	{wchar}ss:[bp].OFF_userNotes[0], ax			>

	; if a volume is slected then we are set (the default values set above
	; will work fine)

	mov	ax, offset FileVolumeText
	andnf	cx, mask GFSEF_TYPE
	cmp	cx, GFSET_VOLUME shl offset GFSEF_TYPE
	LONG jz	gotText

	; get filename from file selector

	push	cx
	push	si
	mov	si, offset UseTemplateFileSelector
	cmp	ss:[bp].OFF_message, MSG_OLDC_USE_TEMPLATE_FILE_SELECTED
	jz	10$
	mov	si, offset OpenFileSelector
10$:
	clr	dx
	call	GetPathFromFileSelector		;ax = GenFileSelectorEntryFlags
	pop	si
	mov_tr	cx, ax				;cx = flags
	mov	ax, offset FileErrorText
	jnz	15$
	pop	cx
	jmp	gotText
15$:

	;
	; Push to that path so we can actually open the beast.
	; 
	call	PushAndSetPath

	; Only look up the file's user notes if we're using the feature.
	; 5/ 2/94 cbh

	call	GetAppLevel
	cmp	ax, UIIL_INTERMEDIATE
	jb	skipUserNotesLookup
	call	GetDocOptions
	test	ax, mask DCO_NO_NOTES_IN_OPEN_BOX
	jnz	skipUserNotesLookup
	test	ax, mask GDCA_NATIVE
	jnz	skipUserNotesLookup

	; get file flags (if a GEOS file)

	push	ds, es
	segmov	ds, ss, ax
	mov	es, ax
	lea	dx, ss:[bp].OFF_docParams.DCP_name
	lea	di, ss:[bp].OFF_userNotes
	mov	ax, FEA_USER_NOTES
	mov	cx, size OFF_userNotes
	call	FileGetPathExtAttributes
	jc	popDir
	mov	ss:[bp].OFF_enableTextObj, BB_TRUE
popDir:
	pop	ds, es

skipUserNotesLookup:
	call	FilePopDir
	pop	cx

	mov	ax, offset FileSubDirText
	andnf	cx, mask GFSEF_TYPE
	cmp	cx, GFSET_SUBDIR shl offset GFSEF_TYPE
	jz	gotText

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ss:[bp].OFF_flags
	mov	ds:[di].OLDCI_fileFlags, ax
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GDCI_attrs
	and	cx, mask GDCA_MODE
	mov_tr	di, ax

	test	di, mask GFSEF_TEMPLATE
	jz	notTemplate
	mov	ax, offset FileReadOnlyTemplateText
	test	di, mask GFSEF_READ_ONLY	;if read-only
	jnz	gotText				;then for-editing disabled

if 0	;screws up open-template -- could possibly check the message used...
	mov	ss:[bp].OFF_selectForEditing, BB_TRUE
endif

	mov	ax, offset FileTemplateText	;file is a template
	jmp	enableForEditing

notTemplate:
	mov	ax, offset FileReadOnlyText	;if read-only then disabled
	test	di, mask GFSEF_READ_ONLY
	jnz	gotText

	mov	ax, offset FileSharedSingleText
	test	di, mask GFSEF_SHARED_SINGLE
	jnz	enableForEditing

	mov	ss:[bp].OFF_selectForEditing, BB_TRUE
	mov	ax, offset FileSharedMultipleText
	test	di, mask GFSEF_SHARED_MULTIPLE
	jnz	checkMode
	mov	ax, offset FileNormalText
enableForEditing:
	mov	ss:[bp].OFF_enableForEditing, BB_TRUE

checkMode:
	cmp	cx, GDCM_VIEWER shl offset GDCA_MODE
	jnz	gotText
	mov	{word} ss:[bp].OFF_enableForEditing, 0

gotText:

	; OFF_enableForEditing, OFF_selectForEditing - set
	; ax - chunk handle of text for glyph

	; check for the same type (to avoid useless work)

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ax, ds:[di].OLDCI_currentFileType
	jz	afterMoniker
	mov	ds:[di].OLDCI_currentFileType, ax

	cmp	ss:[bp].OFF_message, MSG_OLDC_USE_TEMPLATE_FILE_SELECTED
	jz	afterMoniker
	mov	si, offset OpenFileTypeGlyph
	mov_tr	dx, ax
	mov	cx, handle ControlStrings
	push	bp
	mov	bp, VUM_NOW
 	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
afterMoniker:

	; update "for editing" list

	mov	dx, offset UseTemplateUserNotesTextDisplay
	mov	si, offset UseTemplateForEditingList
	cmp	ss:[bp].OFF_message, MSG_OLDC_USE_TEMPLATE_FILE_SELECTED
	jz	gotFEStuff
	mov	dx, offset OpenUserNotesTextDisplay
	mov	si, offset OpenForEditingList
gotFEStuff:
	push	dx				;save text display
	clr	cx				;assume set "false"
	clr	dx
	tst	ss:[bp].OFF_selectForEditing
	jz	setNotSelected
	mov	cx, mask GDA_READ_WRITE		;set "true"
setNotSelected:
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_SET_ENABLED
	tst	ss:[bp].OFF_enableForEditing
	jnz	setForEditingEnabled
	mov	ax, MSG_GEN_SET_NOT_ENABLED
setForEditingEnabled:
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si				;si = text display

	tst	ss:[bp].OFF_enableTextObj
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	setEnabled
	mov	ax, MSG_GEN_SET_NOT_ENABLED
setEnabled:
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	dx, ss
	add	bp, offset OFF_userNotes
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	add	sp, size OpenFlagsFrame

	Destroy	ax, cx, dx, bp
	ret

if _DUI
setEditMenuItems	label	near
	mov	si, offset OpenDeleteTrigger
	call	vumNowFixup
	mov	si, offset OpenRenameTrigger
	call	vumNowFixup
	mov	si, offset OpenDuplicateTrigger
	call	vumNowFixup
	retn

vumNowFixup	label	near
	push	ax				; save message
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax				; ax = message
	retn

disableActivationUI	label	near
	cmp	ax, MSG_OLDC_USE_TEMPLATE_FILE_SELECTED
	je	templateUI
	cmp	ax, MSG_OLDC_OPEN_FILE_SELECTED
	jne	DAUI_done

	;	
	; MSG_OLDC_OPEN_FILE_SELECTED: turn off open trigger and edit
	; menu items.
	;
	mov	si, offset FDOpenTrigger
	call	vumNowFixup
	call	setEditMenuItems
	jmp	DAUI_done

templateUI:
	;
	; turn off Use Template trigger.
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	si, offset UseTemplateFileTrigger
	call	vumNowFixup
DAUI_done:
	retn

endif ; _DUI

OLDocumentControlFileSelected	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlOpenSelected -- MSG_OLDC_OPEN_SELECTED
				for OLDocumentControlClass

DESCRIPTION:	Sent when the "open" trigger is selected -> get file name and
		attributes from dialog box and open a document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_OLDC_OPEN_SELECTED

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

OpenSelFrame	struct
    OSF_docParams	DocumentCommonParams
    OSF_message		word
OpenSelFrame	ends

OLDocumentControlOpenSelected	method dynamic OLDocumentControlClass,
					MSG_OLDC_OPEN_SELECTED,
					MSG_OLDC_USE_TEMPLATE_SELECTED

	mov	bx, ds:[di].OLDCI_currentSummons

	; If the current summons is zero then bail.  This happens on rare
	; occurances for reasons not fully understood. -- tony -- 3/23/93

	tst	bx
	jnz	5$
	ret
5$:

	; get a parameter frame on the stack

	sub	sp, size OpenSelFrame
	mov	bp, sp
	mov	ss:[bp].OSF_message, ax

	; get name from FileSelector -- if none then ignore

	push	si
	mov	si, offset OpenFileSelector
	cmp	ax, MSG_OLDC_OPEN_SELECTED
	jz	10$
	mov	si, offset UseTemplateFileSelector
10$:
	clr	dx				;no text object
	call	GetPathFromFileSelector		;ax = GenFileSelectorEntryFlags
	pop	si				;di = entry # of selection
	jz	done

		CheckHack <GFSET_FILE eq 0>
	test	ax, mask GFSEF_TYPE
	jz	isFile

	; on a subdirectory or volume

	push	si
	movdw	bxsi, cxdx			;bx:si = file selector
	mov	cx, di				; cx = entry #
	mov	ax, MSG_GEN_FILE_SELECTOR_OPEN_ENTRY
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;carry set if error
	pop	si
	jmp	done

	; query list for read-only

isFile:

	push	si, bp
	mov	ax, offset UseTemplateForEditingList
	mov	ss:[bp].DCP_flags, mask DOF_FORCE_TEMPLATE_BEHAVIOR
	cmp	ss:[bp].OSF_message, MSG_OLDC_OPEN_SELECTED
	jnz	gotFEList

	; copy the path back from the FS to our own data now we know we're
	; opening a real file

	call	OLDCCopyPathFromFS

	mov	ss:[bp].DCP_flags, 0

	;ask the GenBoolean object if it is SELECTED

	mov	ax, offset OpenForEditingList
gotFEList:
	mov_tr	si, ax
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;ax = selections
	pop	si, bp
	tst	ax
	mov	ax, mask GDA_READ_ONLY
	jz	mustBeReadOnly
	mov	ax, mask GDA_READ_WRITE
	mov	ss:[bp].DCP_flags, 0
mustBeReadOnly:

	mov	ss:[bp].DCP_docAttrs, ax
	mov	ss:[bp].DCP_connection, 0	; user-initiated

	mov	ax, MSG_GEN_DOCUMENT_GROUP_OPEN_DOC
	mov	dx, size DocumentCommonParams
	call	SendToAppDCFrame

	; finish the interaction

	call	OLDCRemoveSummons

done:
	add	sp, size OpenSelFrame
	Destroy	ax, cx, dx, bp
	ret

OLDocumentControlOpenSelected	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetPathFromFileSelector

DESCRIPTION:	Get a name from a file selector

CALLED BY:	INTERNAL

PASS:
	ss:bp - DocumentCommonParams
	*ds:si - doc control
	^lbx:di - file selector
	^lbx:dx - text object
		if 0 then no text object -- get file name from file selector
		if non-zero then use MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH

RETURN:
	Z flag - set if file selector empty
	ax - GenFileSelectorEntryFlags returned
	di - entry # of current selection
	cx:dx - file selector
	ss:bp - filled

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

GetPathFromFileSelector	proc	far
docOffset	local	nptr.DocumentCommonParams	\
	push bp
textObject	local	word \
	push dx
	.enter

	; get name from FileSelector -- if none then ignore

	mov	ax, MSG_GEN_PATH_GET
	tst	dx
	jz	gotMessage
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
gotMessage:
	push	bp
	mov	dx, ss				;dx:bp = path buffer
	mov	bp, ss:[docOffset]
	add	bp, offset DCP_path
	mov	cx, size DCP_path

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ss:[bp-offset DCP_path].DCP_diskHandle, cx ;store disk handle
	mov	cx, dx
	lea	dx, [bp-offset DCP_path]	;cx:dx = DocumentCommonParams
	pop	bp

	mov	di, ss:[textObject]		;cs:di = text object table
	tst	di
	jz	noTextObject

	; a text object exists -- get the file name from it (into cx:dx)

	push	bx, si				;save file selector
	mov	si, ss:[textObject]
		CheckHack <offset DCP_name eq 0>
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	push	cx, dx, bp			;save buffer & frame
	mov	bp, dx				;pass buffer in dx:bp
	mov	dx, cx
	call	ObjMessage
	pop	cx, dx, bp			;recover buffer address
	pop	bx, si
	mov	ax, (GFSET_FILE shl offset GFSEF_TYPE)
	clr	di				;(entry # doesn't matter)
	jmp	common

	; no text object -- get the file name from the file selector

noTextObject:
	push	bp
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov_tr	di, ax			;di = entry # of selection
	mov_tr	ax, bp			;return flags
	pop	bp

common:
	xchg	si, dx				;ss:si = DCP,
	mov	cx, bx				;^lcx:dx = file selector
	cmp	ss:[si].DCP_name, 0		;set Z flag for return
	.leave
	ret

GetPathFromFileSelector	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDCBringUpSummons

DESCRIPTION:	Bring up a summons

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenDocumentControl
	ax - type (GDCTasks)
	bx - block of UI to duplicate
	cx - offset in instance data to get extra UI from (or 0 for none)
	dx - child number to add extra UI at
	di:bp - setup routine

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
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDCBringUpSummons	proc	far	uses si
	class	OLDocumentControlClass
	.enter

if 0
	CheckHack <offset FileNewSummons eq offset FileOpenSummons>
	CheckHack <offset FileNewSummons eq offset FileUseTemplateSummons>
	CheckHack <offset FileNewSummons eq offset FileSaveAsSummons>
	CheckHack <offset FileNewSummons eq offset FileDialogSummons>
endif

EC <		call	AssertIsUIDocControl				>


	; bx = handle of block to duplicate
	; cx = offset in instance data of group to add in
	; dx = parameter to pass to ADD_GEN_CHILD in bp
	; di = setup routine

	push	dx				;save ADD_CHILD param
	push	cx				;save offset in instance data
	mov	cx, di				;cxbp = callback

	; biff any existing summons (normally there should not be one...)


	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	pushdw	cxbp				;save callback

	call	OLDCRemoveSummons

	; set current operation

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].GDCI_attrs, not mask GDCA_CURRENT_TASK
	or	ds:[di].GDCI_attrs, ax

	mov_tr	ax, bx				;ax = block to duplicate
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	xchg	ax, bx				;ax = owner, bx = block to dup
	clr	cx				;run by current thread
	call	ObjDuplicateResource		;bx = new resource
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLDCI_currentSummons, bx

	popdw	diax
	push	bx
	mov	cx, bx				;cx = block
	mov	bx, di				;bxax = callback
	call	ProcCallFixedOrMovable
	pop	bx

	; set the obj block output for the summons to by the Doc Control

	push	bx, ds
	call	ObjLockObjBlock
	mov	bx, ds:[LMBH_handle]
	mov	ds, ax
	call	ObjBlockSetOutput
	pop	bx, ds
	call	MemUnlock

	; XXX: add new object as an upward only link to the application
	;
	; add new object as an upward only link to the controller.  This will
	; allow help for all document control dialogs to come from the SPUI's
	; help file. - Joon (6/28/94)

	mov	cx, bx
	mov	dx, offset FileNewSummons

; XXX	push	si, ds
; XXX	clr	bx
; XXX	call	GeodeGetAppObject		;bxsi = app object
; XXX	call	ObjLockObjBlock
; XXX	mov	ds, ax
	call	GenAddChildUpwardLinkOnly
; XXX	call	MemUnlock
; XXX	pop	si, ds

	pop	di
	call	ThreadReturnStackSpace

	; add the user's group into the box

	pop	ax				;ax = offset of group to add
	pop	bp				;bp = parameters to gen add

EC <	call	GenCheckGenAssumption					>
if _DUI
	;
	; if main dialog/primary, add GDCI_openGroup UI
	; to end of list screen "Edit" menu
	; and disable "Template" button in "Edit" menu
	; if !GDCF_SUPPORTS_TEMPLATES
	;	*ds:si = GenDocumentControl
	;	^lcx:dx = dialog box
	;	ax = offset of dialog UI (GDCI_dialogGroup if main dialog)
	;
	cmp	ax, offset GDCI_dialogGroup
	jne	notMainDialog
	push	ax, cx, dx, si, bp
	mov	bx, cx				; bx = dialog box handle
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDCI_features, mask GDCF_SUPPORTS_TEMPLATES
	pushf					; save for later
	push	bx				; save dialog box handle
	movdw	cxdx, ds:[di].GDCI_openGroup	; ^lcx:dx = "Edit" menu UI
	jcxz	noEditUI
	mov	si, offset FDMemo		; ^lbx:si = "Edit" menu
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	movdw	bxsi, cxdx			; ^lbx:si = "Edit" menu UI
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; set "Edit" menu UI usable
noEditUI:
	pop	bx				; bx = dialog box handle
	popf					; supports templates?
	jnz	leaveTemplates			; yes, leave it
	mov	si, offset OpenTemplateTrigger	; else, remove it
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
leaveTemplates:
	pop	ax, cx, dx, si, bp
notMainDialog:
endif
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	add	di, ax
if _DUI
	push	si
endif
	movdw	bxsi, cxdx			;bx:si = dialog box
if _DUI
	;
	; if this is the main dialog/primary, add dialogGroup to special
	; place
	;
	push	si				;save dialog box chunk
	cmp	ax, offset GDCI_dialogGroup
	jne	notDialog
	mov	si, offset UserFileListGroup	;add dialogGroup here
notDialog:
endif
	tst	ax
	jz	noAdd

	movdw	cxdx, ds:[di]			;cx:dx = group to add
	tst	cx
	jz	noAdd
	mov	ax, MSG_GEN_ADD_CHILD
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pushdw	bxsi
	movdw	bxsi, cxdx			;bx:si = group to add
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	popdw	bxsi
noAdd:
if _DUI
	pop	si				;^lbx:si = dialog
endif
if _DUI
	pop	cx				;cx = Doc Ctrl chunk handle
endif
	mov	di, 1500
	call	ThreadBorrowStackSpace
	push	di

	; start the sucker up...

	; NOTE:  These messages can not be force-queued, as they can still
	; be in the queue at the time RemoveSummons is called, which
	; synchronously starts the destroy process on the dialog (by calling
	; UserDestroyDialog).  The result is that the dialog tries to
	; come up when the block it is in is being destroyed, yielding the
	; error OBJ_BLOCK_IN_PROCESS_OF_BEING_DESTROYED_IS_BECOMING_IN_USE.
	; Instead, we'll borrow some stack space, hoping that this was why
	; things were force queued the first time around... -- Doug 3/3/93
	;
if _DUI
	;
	; We need to make sure whether we are going to bring up a primary
	; or a interaction window. If it is a primary window, then we use
	; MSG_GEN_SET_USABLE.
	;
	push	cx
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	cx, segment GenPrimaryClass
	mov	dx, offset GenPrimaryClass
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;ax,cx,dx,bp trashed
	pop	cx
	jnc	bringUpDialog
	;
	; Bring up the primary window used by the document control.
	; 
	push	cx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	;
	; muck around the file selector
	;
	pop	si				;*ds:si = doc ctrl object
;;	CheckHack <offset OpenFileSelector eq offset UseTemplateFileSelector>
	mov	cx, bx
	mov	dx, offset OpenFileSelector	;^lcx:dx = file selector
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_CONFIGURE_FILE_SELECTOR
	call	ObjCallInstanceNoLock
	mov	si, offset FileDialogSummons
	jmp	bringUpMsg

bringUpDialog::
endif
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
if _DUI
bringUpMsg::
endif
	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

OLDCBringUpSummons	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDCCopyPathToFS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the path from a GenDocumentControl object to the
		file selector in its current summons.

CALLED BY:	OLDCBringUpSummons, OLDocumentControlSetPath
PASS:		*ds:si	= UI document control
		^lbx:di = file selector
RETURN:		none
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDCCopyPathToFS proc	far	uses	bx, si
	.enter

	movdw	cxdx, bxdi			;cxdx = file selector
	mov	bx, ds:[LMBH_handle]		;bxsi = document control
	call	OLDCCopyPathCommon
	.leave
	ret
OLDCCopyPathToFS endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDCCopyPathFromFS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the path from the GenFileSelector object in the passed
		GenDocumentControl's current summons to the GDC

CALLED BY:	OLDocumentControlSaveAsFileEntered,
       		OLDocumentControlOpenSelected
PASS:		*ds:si	= UI document control
RETURN:		^lcx:dx = file selector
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDCCopyPathFromFS proc	far
		class	OLDocumentControlClass
		uses	bx, bp
		.enter
	;
	; Call common routine to copy the path from the FS to the UIDC
	; 
		mov	bx, cx
		xchg	si, dx
		mov	cx, ds:[LMBH_handle]
		call	OLDCCopyPathCommon
	;
	; Restore order.
	; 
		mov	cx, bx
		xchg	dx, si
		.leave
		ret
OLDCCopyPathFromFS endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDCCopyPathCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a path from one object to another using the standard
		GEN_PATH_GET and GEN_PATH_SET messages

CALLED BY:	OLDCCopyPathToFS, OLDCCopyPathFromFS
PASS:		^lbx:si	= source of the path
		^lcx:dx	= destination for the path
RETURN:		nothing
DESTROYED:	bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDCCopyPathCommon proc near
		class	OLDocumentControlClass
		uses	bx, si, di, ax
		.enter
EC <		tst	bx						>
EC <		ERROR_Z	NULL_HANDLE_PASSED_TO_COPY_PATH_COMMON		>
	;
	; Fetch the path & disk handle from source's vardata.
	; 
		push	cx, dx		; save target object
		clr	dx
		mov	ax, MSG_GEN_PATH_GET
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

	;
	; It's possible that this MSG_GEN_PATH_GET failed, for
	; example, if the disk is no longer available.  If so, just
	; set the path to DOCUMENT and be done with it.
	;
		jc	error
		tst	bx
		jz	error
	;
	; Lock down the path.
	; 
		mov	bx, dx		; bx <- path handle
		call	MemLock
		mov	bp, cx		; bp <- disk handle
		mov_tr	cx, ax
		clr	dx		; cx:dx <- path
		mov_tr	ax, bx		; ax <- path block...

gotPath:
		pop	bx, si		; ^lbx:si <- destination
		push	ax		; save path handle

	;
	; If the destination object is an OLFileSelector, then use the
	; internal message, which will do the right thing with respect
	; to removable disks.
	;

		push	cx, dx, bp
		mov	cx, segment OLFileSelectorClass
		mov	dx, offset OLFileSelectorClass
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx, dx, bp
		
		mov	ax, MSG_GEN_PATH_SET
		jnc	sendIt
		mov	ax, MSG_OL_FILE_SELECTOR_PATH_SET
sendIt:
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Restore destination to ^lcx:dx
	; 
		mov	cx, bx
		mov	dx, si
	;
	; Free used-up path block.
	; 
		pop	bx
		tst	bx
		jz	done
		call	MemFree
done:
		.leave
		ret
error:
	;
	; Error getting our path -- just reset to DOCUMENT
	;
		mov	bp, SP_DOCUMENT
		clr	ax

NOFXIP <	mov	cx, cs					>
NOFXIP <	mov	dx, offset nullPath			>
		
FXIP <	; hack to get cx:dx to point to "0" value on the stack without >
FXIP <	; modifying stack (depends on code after gotPath)	>
FXIP <		mov	cx, ss					>
FXIP <		mov	dx, sp					>
FXIP <		add	dx, size word	; cx:dx will be the value of AX after >
FXIP <					; it has been pushed on the stack   >	
		
		jmp	gotPath
		
OLDCCopyPathCommon endp

nullPath	char	0


DocDialog ends

;---

DocSaveAsClose segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetDirText

DESCRIPTION:	Set the text for a dialog box "Save to Directory FOO"

CALLED BY:	INTERNAL

PASS:
	bxcx - file selector
	bxdx - text object

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/13/92		Initial version

------------------------------------------------------------------------------@
SetDirText	proc	far
textObj		local	lptr	push	dx
fsPath		local	PathName
fullPath	local	PathName
	.enter

	push	cx

	mov	si, dx				;bxsi = text object
	mov	ax, MSG_META_SUSPEND
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si				;bxsi = file selector

	; get the path from the file selector

	push	bp
	segmov	dx, ss
	lea	bp, fsPath
	mov	cx, size fsPath			;cx = buffer size
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cx = disk handle/standard path	
	pop	bp


	; get the full path

	push	bx
	mov	bx, cx				;bx = disk handle
	segmov	ds, ss
	lea	si, fsPath
	segmov	es, ss
	lea	di, fullPath
	mov	cx, size fullPath
	mov	dx, 1				;add drive name
	call	FileConstructFullPath
	pop	bx

	; find the last component

	lea	dx, fullPath			;dx = start of path
	mov	cx, di
	sub	cx, dx				;cx = length
DBCS <	shr	cx, 1							>
	jcxz	done

	mov	si, di				;cx is end of string
	std					;search backwards for a path
	LocalLoadChar ax, C_BACKSLASH		;separator
	LocalFindChar 				;scasb/scasw
	cld
	jcxz	20$
	inc	di				;point at backslash
	inc	di				;point past backslash
DBCS <	inc	di							>
DBCS <	inc	di							>
	cmp	di, si				;if backslash is the end then
	jz	20$				;use the whole thing
	mov	dx, di
20$:
	push	bp
	mov	si, textObj
	push	dx
	mov	dx, handle SavingToDirString
	mov	bp, offset SavingToDirString
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	bp

	mov	dx, ss

if SINGLE_DRIVE_DOCUMENT_DIR			;Avoid showing drive letter
	cmp	{char} ss:[bp+1], ':'
	jne	noDriveLetter
	cmp	{char} ss:[bp+2], '\\'
	jne	noDriveLetter
	add	bp, 3
noDriveLetter:
endif

	clr	cx				;null-terminated
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

done:
	mov	si, textObj
	mov	ax, MSG_META_UNSUSPEND
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

SetDirText	endp
 
COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlInitiateSaveAsDoc --
		MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC for
				OLDocumentControlClass

DESCRIPTION:	Initiate "save as" dialog box (if any exists)

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC

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
OLDocumentControlInitiateSaveAsDoc	method dynamic OLDocumentControlClass,
			MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC

	mov	ax, TEMP_OLDC_DOING_SAVE_AS_TEMPLATE
	call	ObjVarDeleteData

	FALL_THRU	BringUpSaveAs

OLDocumentControlInitiateSaveAsDoc	endm

;---

BringUpSaveAs	proc	far

EC <	call	AssertIsUIDocControl					>

	mov	ax, GDCT_SAVE_AS shl offset GDCA_CURRENT_TASK
	mov	bx, handle DocumentSaveAsUI
	mov	cx, offset GDCI_saveAsGroup
	mov	dx, 3
	mov	di, vseg SetupForSaveAs
	mov	bp, offset SetupForSaveAs
	call	OLDCBringUpSummons
	Destroy	ax, cx, dx, bp
	ret

BringUpSaveAs	endp

;---

OLDocumentControlInitiateSaveAsTemplateDoc	method dynamic \
						OLDocumentControlClass,
			MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_TEMPLATE_DOC

	mov	ax, TEMP_OLDC_DOING_SAVE_AS_TEMPLATE
	clr	cx
	call	ObjVarAddData

	GOTO	BringUpSaveAs

OLDocumentControlInitiateSaveAsTemplateDoc	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetupForSaveAs

DESCRIPTION:	Setup for the save as dialog box before the beast gets copied

CALLED BY:	INTERNAL

PASS:
	cx - block of duplicated UI
	*ds:si - GenDocumentControl

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
SetupForSaveAs	proc	far
	class	GenDocumentControlClass
EC <	call	AssertIsUIDocControl					>

	mov	bx, cx



	; set the text object correctly

	mov	cx, offset SaveAsTextEdit	;bx:cx = text object
	call	SetTextObjectWithFileName


if not NO_USER_LEVELS
	push	si
	mov	dl, VUM_NOW
	mov	si, offset SaveAsSimpleTrigger
	call	GetDocOptions
	test	ax, mask DCO_FS_CANNOT_CHANGE
	jnz	nukeBoth
	call	GetFSLevel
	cmp	ax, UIIL_INTERMEDIATE
	jb	gotTrigger
	jmp	dontNukeBoth
nukeBoth:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
dontNukeBoth:
	mov	si, offset SaveAsAdvancedTrigger
gotTrigger:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

endif
	mov	di, offset SaveAsFileSelector
	call	OLDCCopyPathToFS
	push	bx
	mov	ax, TEMP_OLDC_DOING_SAVE_AS_TEMPLATE
	call	ObjVarFindData
	pop	bx
	mov	ax, mask OLDCFSF_SAVE
	jnc	gotFlags

	; we need to use an alternate glyph here

	push	si
	mov	si, offset SaveAsTemplateFileGlyph
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, offset SaveAsFileGlyph
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	
			;setup the AddVarDataParams structure on stack
			;in prep of AddVarData to switch help Context
	mov	dx,size AddVarDataParams
	sub	sp,dx
	mov	bp,sp
	mov	ss:[bp].AVDP_dataType,ATTR_GEN_HELP_CONTEXT	;type
	mov	ss:[bp].AVDP_dataSize,length saveAsTemplateHelpname
	mov	ss:[bp].AVDP_data.high,cs		;fptr to string
	mov	ss:[bp].AVDP_data.low,offset saveAsTemplateHelpname;cont of fptr

	mov	si,offset FileSaveAsSummons
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di,mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	
	add	sp,size AddVarDataParams;getting rid of AddVarDataParams 
					;struct faster than a speeding
					;pop!
	pop	si

	mov	ax, mask OLDCFSF_SAVE or mask OLDCFSF_TEMPLATE
	mov	di, offset SaveAsFileSelector
gotFlags:

	call	SetupFileSelector
	ret

SetupForSaveAs	endp

saveAsTemplateHelpname	char	"dbDCSaveAT",0

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlSaveAsFileEntered --
		    MSG_OLDC_SAVE_AS_FILE_ENTERED for
						OLDocumentControlClass

DESCRIPTION:	Get file name and attributes from dialog box and save a
		document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_OLDC_SAVE_AS_FILE_ENTERED

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
OLDocumentControlSaveAsFileEntered	method dynamic \
					OLDocumentControlClass,
					MSG_OLDC_SAVE_AS_FILE_ENTERED,
					MSG_OLDC_COPY_TO_FILE_ENTERED,
					MSG_OLDC_MOVE_TO_FILE_ENTERED

	mov	bx, ds:[di].OLDCI_currentSummons

	; get a parameter frame on the stack

	sub	sp, size DocumentCommonParams
	mov	bp, sp
	push	ax				;save message
	clr	cx
	mov	ss:[bp].DCP_docAttrs, cx
	mov	ss:[bp].DCP_flags, cx

	; test for showing volume list, in which case we want to open the
	; selected volume

	push	si
	push	bp
	mov	si, offset SaveAsFileSelector
	cmp	ax, MSG_OLDC_SAVE_AS_FILE_ENTERED
	jz	10$
	mov	si, offset CopyToFileSelector
	cmp	ax, MSG_OLDC_COPY_TO_FILE_ENTERED
	jz	10$
if not _DUI
	mov	si, offset MoveToFileSelector
endif ;(not _NIKE) and (not _JEDIMOTIF) and (_DUI) ;- Not needed for NIKE project

10$:
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	cx, ss				;cx:dx = buffer
	mov	dx, bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	di, ax				;di = entry # of selection
	mov	ax, bp				;ax = flags
	pop	bp
	andnf	ax, mask GFSEF_TYPE
	cmp	ax, GFSET_VOLUME shl offset GFSEF_TYPE
	jnz	notVolumeList

	; on volume list

	mov	cx, di				;cx = entry # of selection
	mov	ax, MSG_GEN_FILE_SELECTOR_OPEN_ENTRY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	pop	ax				;discard message
	jmp	done

notVolumeList:
	pop	dx
	pop	ax
	push	ax				;ax = message
	push	dx
	mov	dx, offset SaveAsTextEdit
	cmp	ax, MSG_OLDC_SAVE_AS_FILE_ENTERED
	jz	20$

	mov	dx, offset CopyToTextEdit
	cmp	ax, MSG_OLDC_COPY_TO_FILE_ENTERED
	jz	20$
if not _DUI
	mov	dx, offset MoveToTextEdit
endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for NIKE project

20$:
	; check the filename string before attempt to save/copy/move to
	; ^lbx:dx = text object

	call	CheckForBlankTextObj
	jc	fileNameInvalid

	call	GetPathFromFileSelector		;return Z flag set if empty
						;ax = GFSEF_*, di = entry #
	pop	si
	pop	ax				;ax = message
	jz	done

	; save the document

	push	ax, bx
	mov	ax, TEMP_OLDC_DOING_SAVE_AS_TEMPLATE
	call	ObjVarFindData
	pop	ax, bx

	mov	di, MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE
	jc	gotMessage

	mov	di, MSG_GEN_DOCUMENT_COPY_TO
	cmp	ax, MSG_OLDC_COPY_TO_FILE_ENTERED
	jz	gotMessage

	mov	di, MSG_GEN_DOCUMENT_MOVE_TO
	cmp	ax, MSG_OLDC_MOVE_TO_FILE_ENTERED
	jz	gotMessage

	; copy the path back from the FS now we know we're going to perform
	; the operation (do this only for save as)

	call	OLDCCopyPathFromFS
	mov	di, MSG_GEN_DOCUMENT_SAVE_AS

gotMessage:
	mov_tr	ax, di
	mov	dx, size DocumentCommonParams

	push	si			;save instance chunk handle
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage		;di = message
	pop	si			;restore instance chunk handle

	; finish the interaction

	call	OLDCRemoveSummons	;destroys nothing

	; restore the stack

	add	sp, size DocumentCommonParams
	; deliver the message

	mov	cx, di
	mov	dx, TO_MODEL
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	ObjCallInstanceNoLock

	; quit without restoring even more stack...

	jmp	quit

done:
	add	sp, size DocumentCommonParams

quit:
	Destroy	ax, cx, dx, bp
	ret

fileNameInvalid:
	push	bp

	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, \
		(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or\
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	ss:[bp].SDOP_customString.handle, handle BlankFileNameErrStr
	mov	ss:[bp].SDOP_customString.chunk, offset BlankFileNameErrStr
	mov	ss:[bp].SDOP_stringArg1.handle, NULL
	mov	ss:[bp].SDOP_stringArg2.handle, NULL
	mov	ss:[bp].SDOP_customTriggers.segment, NULL
	mov	ss:[bp].SDOP_helpContext.segment, NULL
	call	UserStandardDialogOptr
	pop	bp

	pop	ax, dx
	jmp	done

OLDocumentControlSaveAsFileEntered	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlSaveAsDontSave --
		    MSG_OLDC_SAVE_AS_DONT_SAVE for
						OLDocumentControlClass

DESCRIPTION:	Destroy document.

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_OLDC_SAVE_AS_DONT_SAVE

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
	brianc	4/17/95		Initial version

------------------------------------------------------------------------------@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForBlankTextObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a string contains any non-blank
		characters before its null-terminator.

CALLED BY:	OLDocumentControlSaveAsFileEntered,
		OLDocumentRename
PASS:		^lbx:dx = text object
RETURN:		carry	set if string is blank (or null string)
		   	clear if a name has visible characters
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	11/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForBlankTextObj	proc	far

	uses	ax, bx, dx, si, bp, di
	.enter
	mov	si, dx				; ^lbx:si = text obj
	
	mov	dx, ss
	sub	sp, size FileLongName
	mov	bp, sp				; dx:bp = pointer to
						; text string
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cx = string length
						; w/o null
	push	ds			; preserve the segment
	movdw	dssi, dxbp

blankCheck:
	LocalGetChar ax, dssi			;ax <- character
	LocalIsNull ax				;NULL?
	jz	noVisCharFound			;branch if reached NULL
SBCS <	clr	ah							>
	call	LocalIsSpace			;space?
	jnz	blankCheck			;branch if still spaces

	pop	ds
	clc
	add	sp, size FileLongName
	jmp	exit

noVisCharFound:
	pop	ds
	add	sp, size FileLongName
	stc
exit:
	.leave
	ret
CheckForBlankTextObj	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlSaveAsCancelled --
		    MSG_GEN_DOCUMENT_CONTROL_SAVE_AS_CANCELLED for
						OLDocumentControlClass

DESCRIPTION:	Notification of "save as" cancelled -- if quitting then notify
		app dc

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_GEN_DOCUMENT_CONTROL_SAVE_AS_CANCELLED

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
OLDocumentControlSaveAsCancelled	method dynamic OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_SAVE_AS_CANCELLED

	call	OLDCRemoveSummons

	mov	ax, MSG_GEN_DOCUMENT_GROUP_SAVE_AS_CANCELLED
	call	SendToAppDCRegs

	Destroy	ax, cx, dx, bp
	ret

OLDocumentControlSaveAsCancelled	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetTextObjectWithFileName

DESCRIPTION:	Setup a text object and stuff its file name

CALLED BY:	INTERNAL

PASS:
	*ds:si - document control object
	^lbx:cx - text object

RETURN:
	none

DESTROYED:
	ax, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/12/92		Initial version

------------------------------------------------------------------------------@
SetTextObjectWithFileName	proc	far

	call	OLDocumentControlGetAttrs		;ax = attrs

	push	si
	mov	si, cx					;bx:si = text object
	call	SetTextObjectForFileType
	pop	si

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDCI_docAttrs, mask GDA_UNTITLED
	jnz	done

	; set the file name correctly in the text object

	;
	; Deal with funky ?xx sequences in names of DOS files, as produced
	; by the filesystem when PC Graphics characters are placed by weird
	; people into file names. We just drop them on the floor.
	;
	push	si
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	si, ds:[di].GDCI_targetDocName		;ds:si = text
	sub	sp, size GDCI_targetDocName
	mov	di, sp
	segmov	es, ss					;es:di = dest
filterWeirdDosCharsLoop:
	LocalGetChar ax, dssi
	LocalCmpChar ax, '?'
	jne	storeIt
	LocalGetChar ax, dssi
	LocalIsNull ax
	jz	storeIt		; => invalid name returned from FS, but that's
				;  no reason for us to die...
	LocalGetChar ax, dssi
	LocalIsNull ax
	jnz	filterWeirdDosCharsLoop
				; what he said...
storeIt:
	LocalPutChar esdi, ax
	LocalIsNull ax
	jnz	filterWeirdDosCharsLoop

	mov	dx, ss
	mov	bp, sp
	mov	si, cx					;bxsi = object
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GDCI_targetDocName

	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
done:
	ret

SetTextObjectWithFileName	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetTextObjectForFileType

DESCRIPTION:	Set a text object for either native or non-native namespace

CALLED BY:	INTERNAL

PASS:
	ax - GenDocumentControlAttrs
	bx:si - text object

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
	Tony	8/10/92		Initial version

------------------------------------------------------------------------------@
SetTextObjectForFileType	proc	far	uses ax, cx, dx, di, bp
	.enter

	mov	cx, FILE_LONGNAME_LENGTH	;assume VM file
	mov	dx, ATTR_GEN_TEXT_LEGAL_FILENAMES
ifdef DISABLE_LONGNAME_DOS_SUPPORT
	test	ax, mask GDCA_NATIVE
	jz	10$
	mov	cx, DOS_FILE_NAME_CORE_LENGTH + DOS_FILE_NAME_EXT_LENGTH + 1
	mov	dx, ATTR_GEN_TEXT_LEGAL_DOS_FILENAMES
10$:
endif

	; cx = max length, dx = appropriate hint

	sub	sp, size AddVarDataParams
	mov	bp, sp
	mov	ss:[bp].AVDP_dataSize, 0
	mov	ss:[bp].AVDP_dataType, dx
	mov	dx, size AddVarDataParams
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size AddVarDataParams

	mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

SetTextObjectForFileType	endp

DocSaveAsClose ends

;-----

DocInit segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlDisplayDialog --
		MSG_GEN_DCOUMENT_CONTROL_DISPLAY_DIALOG
					for OLDocumentControlClass

DESCRIPTION:	Display the main dialog box

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	8/ 4/92		Initial version

------------------------------------------------------------------------------@
OLDocumentControlDisplayDialog	method dynamic	OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG

if _DUI
	;
	; if no list screen, don't open it
	;
	push	ax, bx
	mov	ax, HINT_DOCUMENT_CONTROL_NO_FILE_LIST
	call	ObjVarFindData
	pop	ax, bx
	jc	exit
endif

	; if there is already a dialog box up then do nothing
	; added 9/23/93 by tony as an attempt to fix an obscure timing
	; bug caused by quickly trying to open a file after closing another
	; file and before the new/open dialog box appeared

	tst	ds:[di].OLDCI_currentSummons
	jnz	exit

	;
	; if no New or Open/Close support, just quit
	;
	mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES
	call	ObjCallInstanceNoLock		 ; ax = current features
	test	ax, mask GDCF_NEW or mask GDCF_OPEN_CLOSE
	jnz	allowNewOpen
	mov	ax, MSG_META_QUIT
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	exit

allowNewOpen:

	; if we are in viewer mode then put up the open dialog box instead

	call	OLDocumentControlGetAttrs
	and	ax, mask GDCA_MODE
	cmp	ax, GDCM_VIEWER shl offset GDCA_MODE
	jz	viewer

	mov	ax, GDCT_DIALOG shl offset GDCA_CURRENT_TASK
	mov	bx, handle DocumentDialogUI
	mov	cx, offset GDCI_dialogGroup
	mov	dx, 1
	mov	di, vseg SetupMainDialog
	mov	bp, offset SetupMainDialog
	call	OLDCBringUpSummons
exit:
	ret

viewer:
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC
	GOTO	ObjCallInstanceNoLock

OLDocumentControlDisplayDialog	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetupMainDialog

DESCRIPTION:	Setup for the main dialog

CALLED BY:	INTERNAL

PASS:
	cx - block of duplicated UI
	*ds:si - GenDocumentControl

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

if not _DUI

SetupMainDialog	proc	far
	class	OLDocumentControlClass

	mov	bx, cx

	push	es
	mov	ax, seg dgroup
	mov	es, ax

;	Nuke the OpenDefault trigger if this option is desired

	test	es:[docControlOptions], mask DCO_NO_OPEN_DEFAULT
	jz	10$
	push	si
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	si, offset FDOpenDefaultGroup
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
10$:

;	Nuke the "Exit" trigger if we are in transparent mode, are not
;	confirming saves, and are not a desk accessory

	mov	ax, es:[docControlOptions]
	test	ax, mask DCO_TRANSPARENT_DOC
	jz	keepExitTrigger

	test	ax, mask DCO_USER_CONFIRM_SAVE
	jnz	keepExitTrigger

	mov	ax, MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS
	call	UserCallApplication
	test	al, mask ALF_DESK_ACCESSORY
	jnz	keepExitTrigger

;
;	If we are in transparent mode, but we are allow the user to
;	close the apps, then keep the exit trigger (9/9/93 -atw)
;
	call	UserGetLaunchOptions
	test	ax, mask UILO_CLOSABLE_APPS
	jnz	keepExitTrigger

;
;	If a document exists (we are switching documents) then allow the
;	cancel trigger.
;
	call	OLDocumentControlGetAttrs
	test	ax, mask GDCA_DOCUMENT_EXISTS
	jnz	keepExitTrigger

	push	si
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	si, offset FDCancelTrigger
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

keepExitTrigger:

	; use the application help file for the "New/Open" dialog box

	sub	sp, size FileLongName
	movdw	cxdx, sssp

	mov	ax, MSG_META_GET_HELP_FILE
	call	UserCallApplication
	jnc	fixupStack

	push	si
	mov	si, offset FileDialogSummons
	mov	ax, MSG_META_SET_HELP_FILE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
fixupStack:
	add	sp, size FileLongName

	; if the user has override strings then use them

	mov	cx, offset GDCI_dialogNewText
	mov	dx, offset FDNewEmptyText
	call	replaceTextIfNeeded

	mov	cx, offset GDCI_dialogTemplateText
	mov	dx, offset FDNewTemplateText
	call	replaceTextIfNeeded

	mov	cx, offset GDCI_dialogOpenDefaultText
	mov	dx, offset FDOpenDefaultText
	call	replaceTextIfNeeded

	mov	cx, offset GDCI_dialogImportText
	mov	dx, offset FDImportText
	call	replaceTextIfNeeded

	mov	cx, offset GDCI_dialogOpenText
	mov	dx, offset FDOpenText
	call	replaceTextIfNeeded

if not NO_USER_LEVELS
	mov	cx, offset GDCI_dialogUserLevelText
	mov	dx, offset FDUserLevelText
	call	replaceTextIfNeeded
endif

	; if the user has override strings then use them

	mov	cx, offset GDCI_dialogNewMoniker
	mov	dx, offset FDNewEmptyTrigger
	call	replaceMonikerIfNeeded

	mov	cx, offset GDCI_dialogTemplateMoniker
	mov	dx, offset FDNewTemplateTrigger
	call	replaceMonikerIfNeeded

	mov	cx, offset GDCI_dialogOpenDefaultMoniker
	mov	dx, offset FDOpenDefaultTrigger
	call	replaceMonikerIfNeeded

	mov	cx, offset GDCI_dialogImportMoniker
	mov	dx, offset FDImportTrigger
	call	replaceMonikerIfNeeded

	mov	cx, offset GDCI_dialogOpenMoniker
	mov	dx, offset FDOpenTrigger
	call	replaceMonikerIfNeeded

	; if not starting up then change from Close to Cancel

	test	es:[docControlOptions], mask DCO_BYPASS_BIG_DIALOG
	jnz	forceCancel

	call	OLDocumentControlGetAttrs
	test	ax, mask GDCA_DOCUMENT_EXISTS
	jz	notCancel

	; setup for using the Cancel button

forceCancel:
	push	si, ds
	mov	si, offset FDCancelTrigger

	; set the moniker

	mov	ax, MSG_GEN_USE_VIS_MONIKER
	clr	cx
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; change the button's action

	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_OLDC_REMOVE_OLD_AND_TEST_FOR_DISPLAY_MAIN_DIALOG
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	clr	cx
	mov	dx, TO_OBJ_BLOCK_OUTPUT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; nuke the ATTR_GEN_DESTINATION_CLASS

	call	ObjLockObjBlock
	mov	ds, ax
	mov	ax, ATTR_GEN_DESTINATION_CLASS
	call	ObjVarDeleteData
	call	MemUnlock

	pop	si, ds
if _MOTIF or _ISUI
	jmp	cancelDone

notCancel:
	;
	; make cancel moniker "Exit <appname>"
	;
	push	si
	mov	si, offset FDCancelTrigger
	call	MakeExitAppMoniker
	pop	si
cancelDone:
else

notCancel:

endif
	; set IMPORT not usable if it is not available

	call	GetAppLevel				;ax = app level
	cmp	ax, UIIL_INTRODUCTORY
	jz	forceNoImport
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GDCI_importGroup.handle
	jnz	afterImport
forceNoImport:
	mov	ax, offset FDImportGroup
	call	setNotUsable
afterImport:

	; set EMPTY not usable if it is not available

	push	bx
	mov	ax, ATTR_GEN_DOCUMENT_CONTROL_NO_EMPTY_DOC_IF_NOT_ABOVE
	call	ObjVarFindData
	mov	cx, ds:[bx]
	pop	bx
	jnc	afterEmpty
	call	GetAppLevel				;ax = app level
	cmp	ax, cx
	ja	afterEmpty
	mov	ax, offset FDNewEmptyGroup
	call	setNotUsable
afterEmpty:

if not NO_USER_LEVELS
	; set USER LEVEL stuff up

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	cxdx, ds:[di].GDCI_userLevelGroup
	jcxz	noUserLevel
	push	si
	mov	si, offset FDUserLevelTrigger
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	jmp	afterUserLevel

noUserLevel:
	mov	ax, offset FDUserLevelGroup
	call	setNotUsable
afterUserLevel:
endif

	; set TEMPLATE not usable if it is not available

	call	OLDocumentControlGetFeatures		;ax = features
	test	ax, mask GDCF_SUPPORTS_TEMPLATES
	jnz	afterTemplates
	mov	ax, offset FDNewTemplateGroup
	call	setNotUsable
afterTemplates:

	; set OPEN DEFAULT not usable if it is not available

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GDCI_defaultFile
	jnz	afterOpenDefault
	mov	ax, offset FDOpenDefaultGroup
	call	setNotUsable
afterOpenDefault:

	pop	es
	ret

;---

setNotUsable:
	push	si
	mov_tr	si, ax
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	retn

;---

replaceTextIfNeeded:
	push	si
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	si, dx
	add	di, cx
	mov	bp, ds:[di]			;bp = chunk
	tst	bp
	jz	replaceDone
	mov	dx, ds:[LMBH_handle]		;bx = block
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
replaceDone:
	pop	si
	retn

;---

replaceMonikerIfNeeded:
	push	si
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	si, dx				;dssi = object
	add	di, cx
	mov	dx, ds:[di]			;dx = chunk
	tst	dx
	jz	replaceMonikerDone
	mov	cx, ds:[LMBH_handle]
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	bp, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
replaceMonikerDone:
	pop	si
	retn

SetupMainDialog	endp

else		; _NIKE or _JEDIMOTIF or _DUI --------------------------------

SetupMainDialog	proc	far
	class	OLDocumentControlClass

	push	cx
	call	SetupForOpen
	pop	cx
		
	ret
SetupMainDialog	endp

endif		; if (not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ---------


DocInit ends

;---

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlRemoveAndTestForDisplayMainDialog --
		MSG_OLDC_REMOVE_OLD_AND_TEST_FOR_DISPLAY_MAIN_DIALOG
						for OLDocumentControlClass

DESCRIPTION:	Remove and old dialog and test for displaying the main dialog

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	9/23/93		Initial version

------------------------------------------------------------------------------@
OLDocumentControlRemoveAndTestForDisplayMainDialog	method dynamic	\
			OLDocumentControlClass,
			MSG_OLDC_REMOVE_OLD_AND_TEST_FOR_DISPLAY_MAIN_DIALOG,
				MSG_GEN_DOCUMENT_CONTROL_IMPORT_CANCELLED

	call	OLDCRemoveSummons
	mov	ax, MSG_OLDC_TEST_FOR_DISPLAY_MAIN_DIALOG
	GOTO	ObjCallInstanceNoLock

OLDocumentControlRemoveAndTestForDisplayMainDialog	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlTestForDisplayMainDialog --
		MSG_OLDC_TEST_FOR_DISPLAY_MAIN_DIALOG for OLDocumentControlClass

DESCRIPTION:	If no document exists then display the main dialog

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	8/ 4/92		Initial version

------------------------------------------------------------------------------@
OLDocumentControlTestForDisplayMainDialog method dynamic OLDocumentControlClass,
				MSG_OLDC_TEST_FOR_DISPLAY_MAIN_DIALOG
	;
	; Ignore input.
	;

if _DUI
	;
	; if no list screen, don't open it
	;
	push	ax, bx
	mov	ax, HINT_DOCUMENT_CONTROL_NO_FILE_LIST
	call	ObjVarFindData
	pop	ax, bx
	jc	done
endif

	;
	; In Redwood, we don't want to check this flag.  Canon always wants
	; to put up the big dialog if there's no other document currently
	; around, which we assume is the case here.  8/ 3/93 cbh
	;
	push	es, ax
	segmov	es, dgroup, ax				;es = dgroup
	test	es:[docControlOptions], mask DCO_BYPASS_BIG_DIALOG
	pop	es, ax
	jnz	done
	
	; 12/1/93: if we're detaching, don't put up the dialog now. We'll do
	; it when we restore from state... I hope -- ardeb
	
	mov	ax, DETACH_DATA
	call	ObjVarFindData
	jc	done

	mov	ax, MSG_OLDC_TEST_FOR_DISPLAY_MAIN_DIALOG2
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_RECORD
	call	ObjMessage				;di = message

	; send to the app document control to send back to us

	mov	cx, di
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	dx, mask MF_FORCE_QUEUE
	mov	di, mask MF_RECORD
	call	ObjMessage				;di = message

	; send to the app document control to send back to us

	mov	cx, di
	mov	ax, MSG_META_DISPATCH_EVENT
	clr	dx
	call	SendToAppDCRegs

done:
	;
	; Accept input again.
	;
	ret

OLDocumentControlTestForDisplayMainDialog	endm

;---

OLDocumentControlTestForDisplayMainDialog2 method dynamic OLDocumentControlClass,
					MSG_OLDC_TEST_FOR_DISPLAY_MAIN_DIALOG2
	;
	; Ignore input.
	;
		
	call	OLDocumentControlGetAttrs
	test	ax, mask GDCA_DOCUMENT_EXISTS
	jnz	done
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLDCI_quitOD.handle
	jnz	done

;
; Problem -- just because the user quits all docs doesn't necessarily mean
; we're closing -- the quit can be aborted at a later point, possibly even
; by an new IACP connection coming in before the detach.  We'll try changing
; this to see if a quit is pending, instead.	-- Doug 3/1/93
;
; We used to check our DETACH_DATA vardata, but because of the double-delay
; on the DISPATCH_EVENT (why is that there????), we can actually get here
; after our detach is complete, so our DETACH_DATA vardata is gone. Instead, we
; rely on the app object's AS_DETACHING flag to tell us whether to abort
; 				-- ardeb 12/1/93
;
;	test	ds:[di].OLDCI_flags, mask OLDCF_QUIT_COMPLETED
; {
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	GenCallApplication
	test	ax, mask AS_QUITTING or mask AS_DETACHING or \
		    	mask AS_TRANSPARENT_DETACHING
; }
	jnz	done

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
	call	ObjCallInstanceNoLock
done:
	;
	; Accept input.
	;
	ret

OLDocumentControlTestForDisplayMainDialog2	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDCInitiateSaveDocForAutoSaveError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark as auto save error and continue on.  This is
		eventually used to remove the Cancel option from the
		Save As dialgo

CALLED BY:	MSG_OLDC_INITIATE_SAVE_DOC_FOR_AUTO_SAVE_ERROR
PASS:		*ds:si	= OLDocumentControlClass object
		ds:di	= OLDocumentControlClass instance data
		ds:bx	= OLDocumentControlClass object (same as *ds:si)
		es 	= segment of OLDocumentControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlInitiateSaveDoc --
		MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_DOC for
				OLDocumentControlClass

DESCRIPTION:	Initiate "save" dialog box (if needed)

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_DOC

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
OLDocumentControlInitiateSaveDoc	method dynamic OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_DOC

	; do we need a dialog box ?

EC <	call	GenCheckGenAssumption					>

if UNTITLED_DOCS_ON_SP_TOP
	call	DocCheckIfOnRamdisk	;for Redwood, put up dialog box if
	jz	doSaveAs		;  document is on RAM drive 7/30/93 cbh
endif

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDCI_docAttrs, mask GDA_UNTITLED or mask GDA_READ_ONLY
	jz	noDialogBox
doSaveAs:

	; need a dialog box -- use save as

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDCI_docAttrs, mask GDA_READ_ONLY
	jz	notReadOnly
	mov	ax, SDBT_NOTIFY_SAVING_READ_ONLY
	cmp	ds:[di].GDCI_docType, GDT_PUBLIC
	jnz	gotDialogType
	mov	ax, SDBT_NOTIFY_SAVING_PUBLIC
gotDialogType:
	call	CallUserStandardDialog

notReadOnly:


	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC
	GOTO	ObjCallInstanceNoLock

	; no dialog box needed, just save

noDialogBox:
	clr	cx
	clr	dx
	mov	ax, MSG_GEN_DOCUMENT_SAVE
	call	SendToTargetDocRegs

	Destroy	ax, cx, dx, bp
	ret

OLDocumentControlInitiateSaveDoc	endm

if _MOTIF or _ISUI

MakeExitAppMoniker	proc	far
	trigger	local	lptr	push si
	.enter
	push	bp
	stc				; get appname from app
	mov	bp, (VMS_TEXT shl offset VMSF_STYLE) or mask VMSF_COPY_CHUNK
	mov	cx, bx			; copy into our UI block
	call	GenFindMoniker		; ^lcx:dx = moniker
	pop	bp
;	jcxz	cancelDone		; not found leave plain "Exit" moniker
	tst	cx
	LONG jz	cancelDone
	push	ds, si, es
	mov	bx, cx
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, ss:[trigger]
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	si, ds:[di].GI_visMoniker	; *ds:si = current "Exit" moniker
	tst	si
	LONG jz	monikerDone
	mov	di, dx
	mov	di, ds:[di]		; ds:di = app name moniker
	test	ds:[di].VM_type, mask VMT_GSTRING
	jnz	monikerDone
	mov	di, dx
	ChunkSizeHandle	ds, di, ax	; ax = app name size (gives us some slop
					;  over the length of the actual text)
	ChunkSizeHandle ds, si, cx	; cx = "Exit" size
	add	cx, ax			; cx = new size
	add	cx, size TCHAR		; room for space separator
	mov	ax, si
	call	LMemReAlloc		; resize "Exit"
	mov	di, ds:[si]		; ds:di = "Exit" moniker
	mov	ds:[di].VM_width, 0	; recalc width
	add	di, offset VM_data.VMT_text
	segmov	es, ds, cx
	LocalStrLength			; point past null
	mov	{TCHAR}es:[di-(size TCHAR)], C_SPACE
	mov	si, dx
	mov	si, ds:[si]
	add	si, offset VM_data.VMT_text	; ds:si = app name
	LocalCopyString			; append app name to "Exit"
monikerDone:
	mov	ax, dx			; free app name chunk
	call	LMemFree
	call	MemUnlock
	pop	ds, si, es
cancelDone:
	.leave
	ret
MakeExitAppMoniker	endp

endif

DocCommon ends

;---

DocMisc segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlInitiateImportDoc --
		MSG_GEN_DOCUMENT_CONTROL_INITIATE_IMPORT_DOC
						for OLDocumentControlClass

DESCRIPTION:	Start importing a document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	8/ 4/92		Initial version

------------------------------------------------------------------------------@
OLDocumentControlInitiateImportDoc	method dynamic	OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_INITIATE_IMPORT_DOC

if 1

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	bxsi, ds:[di].GDCI_importGroup
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

else
	;	
	; Make sure any new, unsaved documents are dealt with.   If the user
	; cancels, we'll do nothing.  -chris 1/19/94
	;
	; Can't use this for Redwood currently.  The problem is, the user
	; will be prompted to save or delete any currently dirty files, and
	; if the user chooses delete, the New/Open dialog will appear on top
	; of the import dialog box, because no documents are currently open.
	; There is no easy way to delay putting up the new/open dialog box
	; if the import dialog is onscreen, as the app doesn't really know
	; how to access the import dialog box.  -cbh 1/20/94
	;
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	bxsi, ds:[di].GDCI_importGroup
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	cx, di
	mov	ax, MSG_META_QUERY_SAVE_DOCUMENTS
	GOTO	ObjCallInstanceNoLock
	
endif

OLDocumentControlInitiateImportDoc	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlInitiateExportDoc --
		MSG_GEN_DOCUMENT_CONTROL_INITIATE_EXPORT_DOC
						for OLDocumentControlClass

DESCRIPTION:	Start importing a document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	8/ 4/92		Initial version

------------------------------------------------------------------------------@
OLDocumentControlInitiateExportDoc	method dynamic	OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_INITIATE_EXPORT_DOC

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	bxsi, ds:[di].GDCI_exportGroup
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

OLDocumentControlInitiateExportDoc	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlOpenSimple -- MSG_OLDC_OPEN_SIMPLE
						for OLDocumentControlClass

DESCRIPTION:	Change the file selector to simple mode

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	10/ 7/92		Initial version

------------------------------------------------------------------------------@

if not NO_USER_LEVELS

OLDocumentControlOpenSimple	method dynamic	OLDocumentControlClass,
							MSG_OLDC_OPEN_SIMPLE
	mov	si, offset OpenFileSelector

	mov	bx, offset OpenSimpleTrigger
	mov	bp, offset OpenAdvancedTrigger
	FALL_THRU	SimpleCommon

OLDocumentControlOpenSimple	endm

;---

SimpleCommon	proc	far
if _DUI
	mov	cx, mask FSA_HAS_FILE_LIST
	mov	dx, 0
else
	mov	cx, mask FSA_ALLOW_CHANGE_DIRS or \
		    mask FSA_HAS_CLOSE_DIR_BUTTON or \
		    mask FSA_HAS_OPEN_DIR_BUTTON or \
		    mask FSA_HAS_FILE_LIST
	mov	dx, mask FSA_HAS_DOCUMENT_BUTTON or \
		    mask FSA_HAS_CHANGE_DIRECTORY_LIST or \
		    mask FSA_HAS_CHANGE_DRIVE_LIST
endif
	FALL_THRU	ChangeFSCommon

SimpleCommon	endp

;---

	; cx = bits to set, dx = bits to reset, si = file selector
	; bp = trigger to make usable, bx = trigger to make not usable

ChangeFSCommon	proc	far
	class	OLDocumentControlClass

	push	bx				;save trigger to make not usable
	push	bp				;save trigger to make usable
	push	cx				;save bits to set
	push	dx				;save bits to clear
	mov	bx, ds:[di].OLDCI_currentSummons	;bxsi = file selector
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_FILE_SELECTOR_GET_ATTRS
	mov	di, mask MF_CALL
	call	ObjMessage			;cx = attrs
	pop	ax				;ax = bits to clear
	not	ax
	and	cx, ax
	pop	ax				;cx = bits to set
	or	cx, ax
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_ATTRS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FILE_CRITERIA
	mov	di, mask MF_CALL
	call	ObjMessage			;cx = criteria
	ornf	cx, mask FSFC_DIRS
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	ret

ChangeFSCommon	endp



;---

OLDocumentControlOpenAdvanced	method dynamic	OLDocumentControlClass,
							MSG_OLDC_OPEN_ADVANCED
	mov	si, offset OpenFileSelector

if not NO_USER_LEVELS
	mov	bx, offset OpenAdvancedTrigger
	mov	bp, offset OpenSimpleTrigger
endif

	FALL_THRU	AdvancedCommon

OLDocumentControlOpenAdvanced	endm

;---

AdvancedCommon	proc	far
if _DUI
	mov	cx, mask FSA_HAS_FILE_LIST
else
	mov	cx, mask FSA_ALLOW_CHANGE_DIRS or \
		    mask FSA_HAS_CLOSE_DIR_BUTTON or \
		    mask FSA_HAS_OPEN_DIR_BUTTON or \
		    mask FSA_HAS_DOCUMENT_BUTTON or \
		    mask FSA_HAS_CHANGE_DIRECTORY_LIST or \
		    mask FSA_HAS_CHANGE_DRIVE_LIST or \
		    mask FSA_HAS_FILE_LIST
endif
	clr	dx
	GOTO	ChangeFSCommon

AdvancedCommon	endp

;---

OLDocumentControlSaveAsSimple	method dynamic	OLDocumentControlClass,
						MSG_OLDC_SAVE_AS_SIMPLE
	mov	si, offset SaveAsFileSelector
	mov	bx, offset SaveAsSimpleTrigger
	mov	bp, offset SaveAsAdvancedTrigger
	GOTO	SimpleCommon

OLDocumentControlSaveAsSimple	endm

;---

OLDocumentControlSaveAsAdvanced	method dynamic	OLDocumentControlClass,
						MSG_OLDC_SAVE_AS_ADVANCED
	mov	si, offset SaveAsFileSelector
	mov	bx, offset SaveAsAdvancedTrigger
	mov	bp, offset SaveAsSimpleTrigger
	GOTO	AdvancedCommon

OLDocumentControlSaveAsAdvanced	endm

endif

;---

if not NO_USER_LEVELS  ;----------------------- Not needed for Redwood project
OLDocumentControlCopyToSimple	method dynamic	OLDocumentControlClass,
						MSG_OLDC_COPY_TO_SIMPLE
	mov	si, offset CopyToFileSelector
	mov	bx, offset CopyToSimpleTrigger
	mov	bp, offset CopyToAdvancedTrigger
	GOTO	SimpleCommon

OLDocumentControlCopyToSimple	endm
endif ;not NO_USER_LEVELS ;------------------- Not needed for Redwood project

;---

if not NO_USER_LEVELS ;----------------------- Not needed for Redwood project
OLDocumentControlCopyToAdvanced	method dynamic	OLDocumentControlClass,
						MSG_OLDC_COPY_TO_ADVANCED
	mov	si, offset CopyToFileSelector
	mov	bx, offset CopyToAdvancedTrigger
	mov	bp, offset CopyToSimpleTrigger
	GOTO	AdvancedCommon

OLDocumentControlCopyToAdvanced	endm
endif ;not NO_USER_LEVELS ;------------------- Not needed for Redwood project

;---

if not NO_USER_LEVELS ;----------------------- Not needed for Redwood project
OLDocumentControlMoveToSimple	method dynamic	OLDocumentControlClass,
						MSG_OLDC_MOVE_TO_SIMPLE
	mov	si, offset MoveToFileSelector
	mov	bx, offset MoveToSimpleTrigger
	mov	bp, offset MoveToAdvancedTrigger
	GOTO	SimpleCommon

OLDocumentControlMoveToSimple	endm
endif ;not NO_USER_LEVELS ;------------------- Not needed for Redwood project

;---

if not NO_USER_LEVELS ;----------------------- Not needed for Redwood project
OLDocumentControlMoveToAdvanced	method dynamic	OLDocumentControlClass,
						MSG_OLDC_MOVE_TO_ADVANCED
	mov	si, offset MoveToFileSelector
	mov	bx, offset MoveToAdvancedTrigger
	mov	bp, offset MoveToSimpleTrigger
	GOTO	AdvancedCommon

OLDocumentControlMoveToAdvanced	endm
endif ;not NO_USER_LEVELS ;------------------- Not needed for Redwood project


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlOpenImportSelected --
		MSG_GEN_DOCUMENT_CONTROL_OPEN_IMPORT_SELECTED
						for OLDocumentControlClass

DESCRIPTION:	Handle the user selecting to import a document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - The message

	ss:bp - ImpexTranslationParams

RETURN:
	none

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
OLDocumentControlOpenImportSelected	method dynamic	OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_OPEN_IMPORT_SELECTED

	mov	ax, MSG_GEN_DOCUMENT_GROUP_IMPORT_NEW_DOC
	call	SendToAppDCFrame

	; finish the interaction

	call	OLDCRemoveSummons

	ret

OLDocumentControlOpenImportSelected	endm

DocMisc ends

;---

DocObscure segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlInitiateSetTypeDoc --
		MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_TYPE_DOC
						for OLDocumentControlClass

DESCRIPTION:	Start changing the type of a document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	8/ 4/92		Initial version

------------------------------------------------------------------------------@
if not _DUI
OLDocumentControlInitiateSetTypeDoc	method dynamic	OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_TYPE_DOC

	mov	ax, GDCT_TYPE shl offset GDCA_CURRENT_TASK
	mov	bx, handle DocumentTypeUI
	clr	cx				;no user UI group
	mov	di, vseg SetupForType
	mov	bp, offset SetupForType
	call	OLDCBringUpSummons
	ret

OLDocumentControlInitiateSetTypeDoc	endm
endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for NIKE project

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetupForType

DESCRIPTION:	Setup for the set type dialog box

CALLED BY:	INTERNAL

PASS:
	cx - block of duplicated UI
	*ds:si - GenDocumentControl

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
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
if not _DUI
SetupForType	proc	far	uses si
	class	GenDocumentControlClass
	.enter

	mov	bx, cx
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	push	ds:[di].GDCI_features
	push	ds:[di].GDCI_attrs
	mov	cx, ds:[di].GDCI_docType

	push	cx
	mov	ax, MSG_OLDC_TYPE_USER_CHANGE
	call	ObjCallInstanceNoLock
	pop	cx

	mov	si, offset TypeList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; set appropriate things not usable

	clr	cx				;cl = PUBLIC usable flag
						;ch = MULTI_USER usable flag
	clr	dx				;dl = TEMPLATE usable flag
						;assume none
	pop	ax				;ax = attrs
	and	ax, mask GDCA_MODE
	jz	10$				;if viewer mode then none
	mov	cx, 1				;if public then..
	inc	dx
	cmp	ax, GDCM_SHARED_SINGLE shl offset GDCA_MODE
	jz	10$
	mov	cx, 0x0100
10$:

	pop	ax			;ax = features
	test	ax, mask GDCF_SUPPORTS_USER_MAKING_SHARED_DOCUMENTS
	jnz	20$
	clr	cx
20$:
	test	ax, mask GDCF_SUPPORTS_TEMPLATES
	jnz	30$
	clr	dx
30$:

	push	dx
	mov	si, offset PublicItem
	call	testSetNotUsable
	mov	cl, ch
	mov	si, offset MultiUserItem
	call	testSetNotUsable

	pop	cx
	mov	si, offset TemplateItem
	call	testSetNotUsable
	mov	si, offset ReadOnlyTemplateItem
	call	testSetNotUsable

	.leave
	ret

	; set bxsi not usable if cl==0

testSetNotUsable:
	tst	cl
	jnz	usableDone
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
usableDone:
	retn

SetupForType	endp
endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for NIKE project

;---

OLDocumentControlInitiateSetPasswordDoc	method dynamic	OLDocumentControlClass,
			MSG_GEN_DOCUMENT_CONTROL_INITIATE_SET_PASSWORD_DOC

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	mov	ax, GDCT_PASSWORD shl offset GDCA_CURRENT_TASK
	mov	bx, handle DocumentPasswordUI
	clr	cx				;no user UI group
	mov	di, vseg SetupForPassword
	mov	bp, offset SetupForPassword
	call	OLDCBringUpSummons

	ret

OLDocumentControlInitiateSetPasswordDoc	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetupForPassword

DESCRIPTION:	Setup for the set password dialog box

CALLED BY:	INTERNAL

PASS:
	cx - block of duplicated UI
	*ds:si - GenDocumentControl

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
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
SetupForPassword	proc	far
	ret

SetupForPassword	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlTypeUserChange -- MSG_OLDC_TYPE_USER_CHANGE
						for OLDocumentControlClass

DESCRIPTION:	User changed document type

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - The message

	cx - new type

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 6/92		Initial version

------------------------------------------------------------------------------@
if not _DUI
OLDocumentControlTypeUserChange	method dynamic	OLDocumentControlClass,
						MSG_OLDC_TYPE_USER_CHANGE

	; set the text object to reflect the type the user has selected

	mov	bx, ds:[di].OLDCI_currentSummons
	mov	di, cx
	shl	di
	mov	bp, cs:typeTextTable[di]
	mov	dx, bx
	clr	cx
	mov	si, offset TypeDescription
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	ret

typeTextTable	word	\
	offset TypeNormalText, offset TypeReadOnlyText, offset TextTemplateText,
	offset TextReadOnlyTemplateText, offset TypePublicText,
	offset TypeMultiUserText

OLDocumentControlTypeUserChange	endm
endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for NIKE project


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlTypeChanged -- MSG_OLDC_TYPE_CHANGED
						for OLDocumentControlClass

DESCRIPTION:	Handle changing file type

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	8/ 5/92		Initial version

------------------------------------------------------------------------------@
if not _DUI
OLDocumentControlTypeChanged	method dynamic	OLDocumentControlClass,
						MSG_OLDC_TYPE_CHANGED

	; Get the data and send it to the document

	push	si
	mov	bx, ds:[di].OLDCI_currentSummons
	mov	si, offset TypeList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov_tr	cx, ax					;cx = type
	mov	ax, MSG_GEN_DOCUMENT_CHANGE_TYPE
	call	SendToTargetDocRegs

	call	OLDCRemoveSummons

	ret

OLDocumentControlTypeChanged	endm
endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for NIKE project


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlPasswordChanged -- MSG_OLDC_PASSWORD_CHANGED
						for OLDocumentControlClass

DESCRIPTION:	Handle changing file type

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	8/ 5/92		Initial version

------------------------------------------------------------------------------@
OLDocumentControlPasswordChanged	method dynamic	OLDocumentControlClass,
						MSG_OLDC_PASSWORD_CHANGED

	; Get the data and send it to the document

	sub	sp, size GenDocumentChangePasswordParams
	mov	bp, sp

	; get the password

	push	si, bp
	mov	bx, ds:[di].OLDCI_currentSummons
	mov	si, offset PasswordText
	lea	bp, ss:[bp].GDCPP_password
	mov	dx, ss
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, bp

	mov	ax, MSG_GEN_DOCUMENT_CHANGE_PASSWORD
	mov	dx, size GenDocumentChangePasswordParams
	call	SendToTargetDocFrame

	add	sp, size GenDocumentChangePasswordParams

	call	OLDCRemoveSummons

	ret

OLDocumentControlPasswordChanged	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlPasswordCancelled --
			MSG_OLDC_PASSWORD_CANCELLED for OLDocumentControlClass

DESCRIPTION:	Handle cancelling document password entry

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	brianc	8/26/94		Initial version

------------------------------------------------------------------------------@
OLDocumentControlPasswordCancelled	method dynamic	OLDocumentControlClass,
						MSG_OLDC_PASSWORD_CANCELLED

	call	OLDCRemoveSummons
	ret

OLDocumentControlPasswordCancelled	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlInitiateCopyToDoc --
		MSG_GEN_DOCUMENT_CONTROL_INITIATE_COPY_TO_DOC for
				OLDocumentControlClass

DESCRIPTION:	Initiate "copy to"

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_GEN_DOCUMENT_CONTROL_INITIATE_COPY_TO_DOC

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

OLDocumentControlInitiateCopyToDoc	method dynamic OLDocumentControlClass,
			MSG_GEN_DOCUMENT_CONTROL_INITIATE_COPY_TO_DOC

	mov	ax, TEMP_OLDC_DOING_SAVE_AS_TEMPLATE
	call	ObjVarDeleteData

	mov	ax, GDCT_COPY_TO shl offset GDCA_CURRENT_TASK
	mov	bx, handle DocumentCopyToUI
	clr	cx
	mov	di, vseg SetupForCopyTo
	mov	bp, offset SetupForCopyTo
	call	OLDCBringUpSummons

	Destroy	ax, cx, dx, bp
	ret

OLDocumentControlInitiateCopyToDoc	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	SetupForCopyTo

DESCRIPTION:	Setup for the copy to dialog box before the beast gets copied

CALLED BY:	INTERNAL

PASS:
	cx - block of duplicated UI
	*ds:si - GenDocumentControl

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

SetupForCopyTo	proc	far
	class	GenDocumentControlClass
EC <	call	AssertIsUIDocControl					>

	mov	bx, cx

	; set the text object correctly

	mov	cx, offset CopyToTextEdit	;bx:cx = text object
	call	SetTextObjectWithFileName

	push	si
	mov	dl, VUM_NOW
	mov	si, offset CopyToSimpleTrigger
	call	GetDocOptions
	test	ax, mask DCO_FS_CANNOT_CHANGE
	jnz	nukeBoth
	call	GetFSLevel
	cmp	ax, UIIL_INTERMEDIATE
	jb	gotTrigger
	jmp	dontNukeBoth
nukeBoth:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
dontNukeBoth:
	mov	si, offset CopyToAdvancedTrigger
gotTrigger:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	di, offset CopyToFileSelector
	call	OLDCCopyPathToFS
	mov	ax, mask OLDCFSF_SAVE
	call	SetupFileSelector
	ret

SetupForCopyTo	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentControlInitiateMoveToDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate "move to"

CALLED BY:	MSG_GEN_DOCUMENT_CONTROL_INITIATE_MOVE_TO_DOC
PASS:		*ds:si	= OLDocumentControlClass object
		ds:di	= OLDocumentControlClass instance data
		ds:bx	= OLDocumentControlClass object (same as *ds:si)
		es 	= segment of OLDocumentControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Joon	4/19/94   	Move version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _DUI
OLDocumentControlInitiateMoveToDoc	method dynamic OLDocumentControlClass, 
				MSG_GEN_DOCUMENT_CONTROL_INITIATE_MOVE_TO_DOC
	mov	ax, TEMP_OLDC_DOING_SAVE_AS_TEMPLATE
	call	ObjVarDeleteData

	mov	ax, GDCT_MOVE_TO shl offset GDCA_CURRENT_TASK
	mov	bx, handle DocumentMoveToUI
	clr	cx
	mov	di, vseg SetupForMoveTo
	mov	bp, offset SetupForMoveTo
	call	OLDCBringUpSummons

	ret
OLDocumentControlInitiateMoveToDoc	endm
endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for NIKE project


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetupForMoveTo

DESCRIPTION:	Setup for the move to dialog box before the beast gets moved

CALLED BY:	INTERNAL

PASS:
	cx - block of duplicated UI
	*ds:si - GenDocumentControl

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
	Joon	4/94		Move version

------------------------------------------------------------------------------@
if not _DUI
SetupForMoveTo	proc	far
	class	GenDocumentControlClass
EC <	call	AssertIsUIDocControl					>

	mov	bx, cx

	; set the text object correctly

	mov	cx, offset MoveToTextEdit	;bx:cx = text object
	call	SetTextObjectWithFileName

	push	si
	mov	dl, VUM_NOW
	mov	si, offset MoveToSimpleTrigger
	call	GetDocOptions
	test	ax, mask DCO_FS_CANNOT_CHANGE
	jnz	nukeBoth
	call	GetFSLevel
	cmp	ax, UIIL_INTERMEDIATE
	jb	gotTrigger
	jmp	dontNukeBoth
nukeBoth:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
dontNukeBoth:
	mov	si, offset MoveToAdvancedTrigger
gotTrigger:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	di, offset MoveToFileSelector
	call	OLDCCopyPathToFS
	mov	ax, mask OLDCFSF_SAVE
	call	SetupFileSelector
	ret

SetupForMoveTo	endp
endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for NIKE project


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlFileExported --
		MSG_GEN_DOCUMENT_CONTROL_FILE_EXPORTED
						for OLDocumentControlClass

DESCRIPTION:	Notification that a file has been successfully exported

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - The message

RETURN:
	none

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
OLDocumentControlFileExported	method dynamic	OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_FILE_EXPORTED

	; finish the interaction

	call	OLDCRemoveSummons

	ret

OLDocumentControlFileExported	endm


if _DUI
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentControlRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename the selected file in the Document Control level

CALLED BY:	MSG_OLDC_RENAME
PASS:		*ds:si	= OLDocumentControlClass object
		ds:di	= OLDocumentControlClass instance data
		es 	= segment of OLDocumentControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentControlRename	method dynamic OLDocumentControlClass, 
					MSG_OLDC_RENAME
		.enter
	;
	; Let the file selector do it for us
	;
		mov	ax, MSG_OL_FILE_SELECTOR_RENAME
		mov	bx, ds:[di].OLDCI_currentSummons
		mov	si, offset OpenFileSelector
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
OLDocumentControlRename		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentControlCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate the existing file.

CALLED BY:	MSG_OLDC_COPY
PASS:		*ds:si	= OLDocumentControlClass object
		ds:di	= OLDocumentControlClass instance data
		es 	= segment of OLDocumentControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentControlCopy	method dynamic OLDocumentControlClass, 
					MSG_OLDC_COPY
		.enter
	;
	; Let the file selector do it for us
	;
		mov	ax, MSG_OL_FILE_SELECTOR_COPY
		mov	bx, ds:[di].OLDCI_currentSummons
		mov	si, offset OpenFileSelector
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
OLDocumentControlCopy		endm

endif ; _JEDIMOTIF or _DUI

if _DUI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentControlCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the existing file.

CALLED BY:	MSG_OLDC_DELETE
PASS:		*ds:si	= OLDocumentControlClass object
		ds:di	= OLDocumentControlClass instance data
		es 	= segment of OLDocumentControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/25/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentControlDelete	method dynamic OLDocumentControlClass, 
					MSG_OLDC_DELETE
		.enter
	;
	; Let the file selector do it for us
	;
		mov	ax, MSG_GEN_FILE_SELECTOR_DELETE_SELECTION
		mov	bx, ds:[di].OLDCI_currentSummons
		mov	si, offset OpenFileSelector
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
OLDocumentControlDelete		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentControlTemplate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up template list.

CALLED BY:	MSG_OLDC_TEMPLATE
PASS:		*ds:si	= OLDocumentControlClass object
		ds:di	= OLDocumentControlClass instance data
		es 	= segment of OLDocumentControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/25/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
OLDocumentControlTemplate	method dynamic OLDocumentControlClass, 
					MSG_OLDC_TEMPLATE
		.enter
	;
	; Let the file selector do it for us
	;
		mov	ax, MSG_OL_FILE_SELECTOR_COPY
		mov	bx, ds:[di].OLDCI_currentSummons
		mov	si, offset OpenFileSelector
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
OLDocumentControlTemplate		endm
endif

endif	; _DUI


DocObscure ends
