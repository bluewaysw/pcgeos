COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainDocDialog.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:
	Dialog box routines for OLDocumentClass

	$Id: cmainDocDialog.asm,v 1.1 97/04/07 10:52:36 newdeal Exp $

------------------------------------------------------------------------------@

DocError segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	CallStandardDialogSS_BP

DESCRIPTION:	Call UserStandardDialog after doing prep work

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenDocument object
	ss:bp - DocumentNewOpenParameters
	bx:di - second argument (if any)

RETURN:
	none

DESTROYED:
	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/22/91		Initial version

------------------------------------------------------------------------------@

.assert (@CurSeg eq DocError)		;used as callback routine

FarCallStandardDialogSS_BP	proc	far
	call	CallStandardDialogSS_BP
	ret
FarCallStandardDialogSS_BP	endp

	; this routine *must* be a near routine

CallStandardDialogSS_BP	proc	near	uses cx, dx, si
	.enter

EC <	call	AssertIsGenDocument					>

	call	SetSysModalIfDiskFullError

if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
	call	DisableBusy
	push	cx, si
endif

	push	ax
	call	GetParentAttrs
	pop	ax

	mov	cx, ss				;pass file name in cx:dx
	lea	dx, ss:[bp].DCP_name
	mov	si, di
	call	CallUserStandardDialog

if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
	pop	cx, si
	call	RestoreBusy
endif

	.leave
	ret

CallStandardDialogSS_BP	endp

;
; pass:
;	*ds:si = GenDocument
;	al = StandardDialogBoxType
; return:
;	al = StandardDialogBoxType with high bit set if doing disk full error
; destroyed:
;	none
;
SetSysModalIfDiskFullError	proc	far
	push	ax, bx
	mov	ax, TEMP_OL_DOCUMENT_NO_DISK_SPACE_MESSAGE
	call	ObjVarFindData
	pop	ax, bx
	jnc	done			; not found, not handling disk full
	ornf	al, 0x80		; else, set high bit
done:
	ret
SetSysModalIfDiskFullError	endp

;-----

	; bx:di = second argument

.assert (@CurSeg eq DocError)		;used as callback routine

FarCallStandardDialogDS_SI	proc	far
	call	CallStandardDialogDS_SI
	ret
FarCallStandardDialogDS_SI	endp

	; this routine *must* be a near routine

CallStandardDialogDS_SI	proc	near	uses cx, dx, si
	class	OLDocumentClass
	.enter

EC <	call	AssertIsGenDocument					>

	call	SetSysModalIfDiskFullError

if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
	call	DisableBusy
	push	cx, si
endif

	push	ax
	call	GetParentAttrs
	pop	ax

	push	di
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds				;pass file name in cx:dx
	lea	dx, ds:[di].GDI_fileName
	pop	si
	call	CallUserStandardDialog

if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
	pop	cx, si
	call	RestoreBusy
endif

	.leave
	ret

CallStandardDialogDS_SI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	turn off busy state

CALLED BY:	CallStandardDialogSS_BP, CallStandardDialogDS_SI
PASS:		*ds:si = OLDocument
RETURN:		cx - busy count disabled
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
DisableBusy	proc	near
	uses	di
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLDI_busyCount
	jcxz	done
	push	cx
markNotBusy:
	call	OLDocMarkNotBusy
	loop	markNotBusy
	pop	cx
done:
	.leave
	ret
DisableBusy	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restore busy state

CALLED BY:	CallStandardDialogSS_BP, CallStandardDialogDS_SI
PASS:		*ds:si = OLDocument
		cx = busy count to restore
RETURN:		nothing
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if TURN_OFF_BUSY_ON_DOC_CTRL_DIALOG
RestoreBusy	proc	near
	jcxz	done
markBusy:
	call	OLDocMarkBusy
	loop	markBusy
done:
	ret
RestoreBusy	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	CallUserStandardDialog

DESCRIPTION:	Call UserStandardDialog with standard parameters

CALLED BY:	INTERNAL

PASS:
	al - StandardDialogBoxType
			high bit set to use system modal dialog
	cx:dx - first string argument (usually file name)
	bx:si - second string argument (rarely used)

RETURN:
	same as UserStandardDialog

DESTROYED:
	same as UserStandardDialog

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/90		Initial version

------------------------------------------------------------------------------@

;
; we use high bit for our devious purposes - brianc 7/14/93
;
.assert (StandardDialogBoxType le 128)

StandardArg2		etype	byte
SA2_NONE		enum	StandardArg2
SA2_CREATING_NEW	enum	StandardArg2
SA2_OPENING		enum	StandardArg2
SA2_SAVING		enum	StandardArg2
SA2_REVERTING		enum	StandardArg2
SA2_MOVING		enum	StandardArg2

;
; accessed via (StandardArg2-1)*2
;
StdDialogArg2Table	label	word
	word	offset SDA_createNew
	word	offset SDA_opening
	word	offset SDA_saving
	word	offset SDA_reverting
	word	offset SDA_moving

StdDialogEntry	struct
    SDE_flags		CustomDialogBoxFlags
    SDE_arg2		StandardArg2
    SDE_string		word		; string must be in
					;	DialogStringUI resource
					; table of custom response triggers
    SDE_customTriggers	nptr.StandardDialogResponseTriggerTable
StdDialogEntry	ends

StdDialogTable	label	StdDialogEntry
    StdDialogEntry	<		;SDBT_FILE_NEW_CANNOT_CREATE_TEMP_NAME
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_CREATING_NEW,			;SDE_arg2
	offset SDS_fileCannotCreateTemp,	;SDE_string
	0					;SDE_customTriggers
    >
if LIMITED_UNTITLED_DOC_DISK_SPACE
    StdDialogEntry	<		;SDBT_FILE_NEW_INSUFFICIENT_DISK_SPACE
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_CREATING_NEW,			;SDE_arg2
	offset SDS_fileNewInsufficientDiskSpace, ;SDE_string
	0					;SDE_customTriggers
    >
else
    StdDialogEntry	<		;SDBT_FILE_NEW_INSUFFICIENT_DISK_SPACE
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_CREATING_NEW,			;SDE_arg2
	offset SDS_fileInsufficientDiskSpace,	;SDE_string
	0					;SDE_customTriggers
    >
endif
    StdDialogEntry	<		;SDBT_FILE_NEW_TOO_MANY_OPEN_FILES
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_CREATING_NEW,			;SDE_arg2
	offset SDS_fileTooManyOpenFiles,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_NEW_ERROR
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_CREATING_NEW,			;SDE_arg2
	offset SDS_fileError,			;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_NEW_WRITE_PROTECTED
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>,	;SDE_flags
	SA2_CREATING_NEW,			;SDE_arg2
	offset SDS_fileWriteProtected,		;SDE_string
	offset SDRT_okCancel			;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_FILE_OPEN_SHARING_DENIED
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_OPENING,				;SDE_arg2
	offset SDS_fileSharingDenied,		;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_OPEN_FILE_NOT_FOUND
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_OPENING,				;SDE_arg2
	offset SDS_fileFileNotFound,		;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_OPEN_INVALID_VM_FILE
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_OPENING,				;SDE_arg2
	offset SDS_fileInvalidVMFile,		;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_OPEN_INSUFFICIENT_DISK_SPACE
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_OPENING,				;SDE_arg2
	offset SDS_fileInsufficientDiskSpace,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_OPEN_ERROR
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_OPENING,				;SDE_arg2
	offset SDS_fileError,			;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_OPEN_READ_ONLY_PUBLIC_IN_TRANSPARENT_MODE
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileOpenReadOnlyPublicInTransparentMode, ;SDE_string
	offset SDRT_okCancel			;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_OPEN_VM_DIRTY
	<FALSE, CDT_NOTIFICATION, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileOpenVMDirty,		;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_OPEN_APP_MORE_RECENT_THAN_DOC
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileOpenAppMoreRecent,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_OPEN_DOC_MORE_RECENT_THAN_APP
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileOpenDocMoreRecent,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_OPEN_FILE_TYPE_MISMATCH
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileOpenFileTypeMismatch,	;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_FILE_SAVE_INSUFFICIENT_DISK_SPACE
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_SAVING,				;SDE_arg2
	offset SDS_fileInsufficientDiskSpace,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_SAVE_ERROR
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileSaveError,		;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_SAVE_WRITE_PROTECTED
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>,	;SDE_flags
	SA2_SAVING,				;SDE_arg2
	offset SDS_fileWriteProtected,		;SDE_string
	offset SDRT_okCancel			;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_FILE_SAVE_AS_FILE_EXISTS
	<FALSE, CDT_QUESTION, GIT_AFFIRMATION>,	;SDE_flags
	SA2_SAVING,				;SDE_arg2
	offset SDS_fileSaveFileExists,		;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_SAVE_AS_SHARING_DENIED
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_SAVING,				;SDE_arg2
	offset SDS_fileSharingDenied,		;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_SAVE_AS_FILE_FORMAT_MISMATCH
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileSaveAsFileFormatMismatch, ;SDE_string
	0					;SDE_customTriggers
    >


    StdDialogEntry	<		;SDBT_FILE_CLOSE_SAVE_CHANGES_UNTITLED
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileCloseSaveChangesUntitled,	;SDE_string
	offset SDRT_fileCloseSaveChangesUntitled	;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_CLOSE_SAVE_CHANGES_TITLED
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileCloseSaveChangesTitled,	;SDE_string
	offset SDRT_fileCloseSaveChangesTitled	;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_CLOSE_ATTACH_DIRTY
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileCloseAttachDirty,	;SDE_string
	offset SDRT_fileCloseAttachDirty	;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_FILE_REVERT_CONFIRM
	<FALSE, CDT_WARNING, GIT_AFFIRMATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileRevertConfirm,		;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_FILE_REVERT_ERROR
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_REVERTING,				;SDE_arg2
	offset SDS_fileError,			;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_FILE_ATTACH_DISK_NOT_FOUND
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_attachDiskNotFound,		;SDE_string
	offset SDRT_attachDiskNotFound		;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_CANNOT_CHANGE_TYPE
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_cannotChangeType,		;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_CANNOT_CHANGE_PASSWORD
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_cannotChangePassword,	;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_PROMPT_MOVE_TEMPLATE
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_promptMoveTempalte,		;SDE_string
	offset SDRT_promptMoveTemplate		;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_BAD_PASSWORD
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_badPassword,			;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_RENAME_FILE_EXISTS
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_renameFileExists,		;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_RENAME_ERROR
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_renameError,			;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_BACKUP_ERROR
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_backupError,			;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_REVERT_QUICK_CONFIRM
	<FALSE, CDT_WARNING, GIT_AFFIRMATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_revertQuickConfirm,		;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_REVERT_QUICK_ERROR
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_revertQuickError,		;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_QUERY_SET_EMPTY_NONE_EXISTS
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_querySetEmptyNoneExists,	;SDE_string
	offset SDRT_querySetEmptyNoneExists	;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_QUERY_SET_EMPTY_ONE_EXISTS
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_querySetEmptyOneExists,	;SDE_string
	offset SDRT_querySetEmptyOneExists	;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_QUERY_CLEAR_EMPTY
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_queryClearEmpty,		;SDE_string
	offset SDRT_queryClearEmpty		;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_QUERY_SET_DEFAULT_NONE_EXISTS
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_querySetDefaultNoneExists,	;SDE_string
	offset SDRT_querySetDefaultNoneExists	;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_QUERY_SET_DEFAULT_ONE_EXISTS
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_querySetDefaultOneExists,	;SDE_string
	offset SDRT_querySetDefaultOneExists	;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_QUERY_CLEAR_DEFAULT
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_queryClearDefault,		;SDE_string
	offset SDRT_queryClearDefault		;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_SET_EMPTY_ERROR
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_setEmptyError,		;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_TRANSPARENT_NEW_FILE_EXISTS
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_transparentNewFileExists,	;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_CONFIRM_PASSWORD_CHANGE
	<FALSE, CDT_WARNING, GIT_AFFIRMATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_confirmPasswordChange,	;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_NOTIFY_SAVE_AS_TEMPLATE
	<FALSE, CDT_NOTIFICATION, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_notifySaveAsTemplate,	;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_NOTIFY_SAVING_READ_ONLY
	<FALSE, CDT_NOTIFICATION, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_notifySavingReadOnly,	;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_NOTIFY_SAVING_PUBLIC
	<FALSE, CDT_NOTIFICATION, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_notifySavingPublic,		;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_DISK_RESTORE
	<FALSE, CDT_ERROR, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_diskRestore,			;SDE_string
	offset SDRT_diskRestore			;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_FILE_ILLEGAL_NAME
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileSaveIllegalName,		;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_FILE_OVERWRITING_ITSELF
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileOverwritingItself,	;SDE_string
	0					;SDE_customTriggers
    >

if	VOLATILE_SYSTEM_STATE
    StdDialogEntry	<		;SDBT_QUERY_SAVE_ON_APP_SWITCH_UNTITLED
	<TRUE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_querySaveOnAppSwitchUntitled,	;SDE_string
	offset SDRT_querySaveOnAppSwitchUntitled	;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_QUERY_SAVE_ON_APP_SWITCH_TITLED
	<TRUE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_querySaveOnAppSwitchTitled,	;SDE_string
	offset SDRT_querySaveOnAppSwitchTitled	;SDE_customTriggers
    >
endif

if LIMITED_UNTITLED_DOC_DISK_SPACE
    StdDialogEntry	<		;SDBT_QUERY_AUTOSAVE_UNTITLED
	<TRUE, CDT_WARNING, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_queryAutosaveUntitled,	;SDE_string
	0			;SDE_customTriggers
    >

    StdDialogEntry	<		;SDBT_QUERY_AUTOSAVE_TITLED
	<TRUE, CDT_WARNING, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_queryAutosaveTitled,	;SDE_string
	0			;SDE_customTriggers
    >
endif

if FLOPPY_BASED_DOCUMENTS
    StdDialogEntry	<		;SDBT_AUTOSAVE_TOTAL_FILES_TOO_LARGE
	<TRUE, CDT_WARNING, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_autosaveTotalFilesTooLarge,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_AUTOSAVE_FILE_TOO_LARGE
	<TRUE, CDT_WARNING, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_autosaveFileTooLarge,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_CANT_OPEN_TOTAL_FILES_TOO_LARGE
	<TRUE, CDT_ERROR, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_cantOpenTotalFilesTooLarge,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_CANT_CREATE_TOTAL_FILES_TOO_LARGE
	<TRUE, CDT_ERROR, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_cantCreateTotalFilesTooLarge,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_CANT_IMPORT_TOTAL_FILES_TOO_LARGE
	<TRUE, CDT_ERROR, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_cantImportTotalFilesTooLarge,	;SDE_string
	0					;SDE_customTriggers
    >
endif

if ENFORCE_DOCUMENT_HANDLES
    StdDialogEntry	<		;SDBT_CANT_OPEN_TOTAL_FILES_TOO_LARGE
	<TRUE, CDT_ERROR, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_cantOpenTotalFilesTooLarge,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_CANT_CREATE_TOTAL_FILES_TOO_LARGE
	<TRUE, CDT_ERROR, GIT_NOTIFICATION>, ;SDE_flags
	0,					;SDE_arg2
	offset SDS_cantCreateTotalFilesTooLarge,	;SDE_string
	0					;SDE_customTriggers
    >
endif

    StdDialogEntry	<		;SDBT_CANT_MOVE_READ_ONLY_DOCUMENT
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_cantMoveReadOnlyDocument,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_MOVE_WRITE_PROTECTED
	<FALSE, CDT_QUESTION, GIT_MULTIPLE_RESPONSE>,	;SDE_flags
	SA2_MOVING,				;SDE_arg2
	offset SDS_fileWriteProtected,		;SDE_string
	offset SDRT_okCancel			;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_UNABLE_TO_OVERWRITE_EXISTING_FILE
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_unableToOverwriteExistingFile,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_MOVE_INSUFFICIENT_DISK_SPACE
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	SA2_MOVING,				;SDE_arg2
	offset SDS_fileInsufficientDiskSpace,	;SDE_string
	0					;SDE_customTriggers
    >
    StdDialogEntry	<		;SDBT_FILE_MOVE_ERROR
	<FALSE, CDT_ERROR, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileMoveError,		;SDE_string
	0					;SDE_customTriggers
    >

    StdDialogEntry	<	;SDBT_FILE_COPY_FILE_IS_PUBLIC_OR_READ_ONLY
	<FALSE, CDT_NOTIFICATION, GIT_NOTIFICATION>,	;SDE_flags
	0,					;SDE_arg2
	offset SDS_fileCopyPublicOrReadOnly,	;SDE_string
	0					;SDE_customTriggers
    >
	

;
; lists of response trigger monikers and response values for
; GIT_MULTIPLE_RESPONSE dialog interaction types
;
SDRT_okCancel label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_ok,			; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>

SDRT_fileCloseSaveChangesUntitled label	StandardDialogResponseTriggerTable
	word	3				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_fileCloseSaveChangesUntitled_Yes,	; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_fileCloseSaveChangesUntitled_No,	; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_fileCloseSaveChangesTitled label	StandardDialogResponseTriggerTable
	word	3				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_fileCloseSaveChangesTitled_Yes,	; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_fileCloseSaveChangesTitled_No,	; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>


SDRT_fileCloseAttachDirty	label	StandardDialogResponseTriggerTable
	word	3				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry	<
		SDRT_fileCloseAttachDirty_Yes,	; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry	<
		SDRT_fileCloseAttachDirty_No,	; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry	<
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_attachDiskNotFound	label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry	<
		SDRT_ok,			; SDRTE_moniker
		IC_OK				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry	<
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_promptMoveTemplate	label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry	<
		SDRT_promptMoveTemplate_Yes,	; SDRTE_moniker
		IC_OK				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry	<
		SDRT_promptMoveTemplate_No,	; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_querySetEmptyNoneExists	label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_querySetEmpty_Yes,		; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_querySetEmptyOneExists	label	StandardDialogResponseTriggerTable
	word	3				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_querySetEmpty_Yes,		; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_querySetEmptyOneExists_No,	; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_queryClearEmpty		label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_querySetEmptyOneExists_No,	; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_querySetDefaultNoneExists	label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_querySetDefault_Yes,	; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_querySetDefaultOneExists	label	StandardDialogResponseTriggerTable
	word	3				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_querySetDefault_Yes,	; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_querySetDefaultOneExists_No,	; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_queryClearDefault		label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_querySetDefaultOneExists_No,	; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_diskRestore		label	StandardDialogResponseTriggerEntry
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_diskRestore_Yes,		; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_diskRestore_No,		; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>

if VOLATILE_SYSTEM_STATE

SDRT_querySaveOnAppSwitchUntitled label	StandardDialogResponseTriggerTable
	word	3				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDS_querySave_Save,		; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDS_querySave_Delete,		; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_querySaveOnAppSwitchTitled label	StandardDialogResponseTriggerTable
	word	3				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDS_querySave_Save,		; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDS_querySave_Revert,		; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

if FLOPPY_BASED_DOCUMENTS
SDRT_queryAutosaveUntitled	label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDS_querySave_Save,		; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>

SDRT_queryAutosaveTitled	label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDS_querySave_Save,		; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>
endif

endif




;---

CallUserStandardDialog	proc	far	uses bx, cx, dx, si, bp, ds
	.enter

	sub	sp, size StandardDialogParams
	mov	bp, sp
	movdw	ss:[bp].SDP_stringArg1, cxdx
	movdw	ss:[bp].SDP_stringArg2, bxsi

	; handle standard types

	test	al, 0x80			; check sys modal flag
	pushf
	andnf	al, 0x7f

	clr	bx
	mov	bl, al
	mov	ax, size StdDialogEntry
	mul	bx
	mov_tr	bx, ax

	mov	ax, cs:StdDialogTable[bx].SDE_customTriggers
	movdw	ss:[bp].SDP_customTriggers, csax
	popf					; recover sys modal flag
	push	{word} cs:StdDialogTable[bx].SDE_arg2
	mov	ax, cs:StdDialogTable[bx].SDE_flags	;ax = flags
	jz	haveSysModalFlag
	ornf	ax, mask CDBF_SYSTEM_MODAL
haveSysModalFlag:
	mov	ss:[bp].SDP_customFlags, ax
	mov	si, cs:StdDialogTable[bx].SDE_string

	;
	; hack for file-not-found error on PDAs - brianc 6/7/93
	;
	cmp	si, offset SDS_fileFileNotFound
	jne	notNotFound
	call	OpenCheckIfPDA
	jnc	notNotFound
	mov	si, offset SDS_fileFileNotFoundPDA
notNotFound:
	;
	; hack for file-save error on PDAs - brianc 7/12/93
	;
	cmp	si, offset SDS_fileSaveError
	jne	notFileSave
	call	OpenCheckIfPDA
	jnc	notFileSave		;fixed from notNotFound 8/4/93 cbh
	mov	si, offset SDS_fileSaveErrorPDA
notFileSave:

	mov	bx, handle DocumentStringsUI
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	movdw	ss:[bp].SDP_customString, dssi

	; if SDE_arg2 is non zero, then it is an index into StdDialogArg2Table
	; of strings for arg2

	pop	bx				;bl = arg2
	clr	bh
	tst	bx
	jz	noArg2
	dec	bx
	shl	bx
	mov	bx, cs:StdDialogArg2Table[bx]
	mov	bx, ds:[bx]
	movdw	ss:[bp].SDP_stringArg2, dsbx
noArg2:

	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialog		;pass params on stack

	mov	bx, handle DocumentStringsUI
	call	MemUnlock

	.leave
	ret

CallUserStandardDialog	endp

DocError ends
