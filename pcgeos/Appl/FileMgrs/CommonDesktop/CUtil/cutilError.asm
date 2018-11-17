COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cutilError.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	Initial version.

DESCRIPTION:
	

	$Id: cutilError.asm,v 1.2 98/06/03 13:51:01 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PseudoResident segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopYesNoWarning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	warning user about something, and ask if they wish to
		continue

CALLED BY:	INTERNAL

PASS:		ax - DesktopWarningFlags
		dgroup:[fileOperationInfoEntryBuffer] - FileOperationInfoEntry
			if mask DETF_SHOW_FILENAME used in DesktopWarningTable

		ds:dx - filename
			if mask DETF_USE_DS_DX_NAME used in DesktopWarningTable
		OR
		ds:dx - string
			if mask DETF_USE_DS_DX_STRING used in
			DesktopWarningTable

		dgroup:[recurErrorFlag] = 1 if recursive file operation warning

RETURN:		ax = YESNO_YES (yes, continue)
			or YESNO_NO (no, don't continue)
			or YESNO_CANCEL (user cancelled operation)
			or DESK_DB_DETACH (detaching application)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/22/90		pulled out common routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopYesNoWarning	proc	far
	uses	bx, cx, dx, ds, si, es, di

warningFlags	local	DesktopWarningFlags	push	ax
warningString	local	optr.char
secondTrigger	local	StandardDialogResponseTriggerEntry
firstTrigger	local	StandardDialogResponseTriggerEntry
triggerTable	local	word

	.enter

	cmp	ss:[willBeDetaching], TRUE	; detach received?
	LONG je	detachEntry			; yes, return detach
	cmp	ss:[detachActiveHandling], TRUE	; detach pending?
	jne	afterActive			; no, continue
	call	InformActiveBoxOfAttention	; else, change text in active
						;	box
afterActive:

	;
	; find correct string to use for given error code
	;

	andnf	ax, mask DWF_WARNING
	clr	si				; start of table
warningLoop:
	cmp	cs:[DesktopWarningTable][si].WTE_warning, NIL	; end of table?
EC <	ERROR_E ILLEGAL_WARNING	>
LONG	je	90$

	cmp	cs:[DesktopWarningTable][si].WTE_warning, ax
	je	foundWarningEntry		; yes, use it
	add	si, size WarningTableEntry	; move to next entry
	jmp	warningLoop

	;
	; found warning string for this error
	;
foundWarningEntry:
	movdw	ss:[warningString], cs:[DesktopWarningTable][si].WTE_string, ax

	;
	; set up UserStandardDialog parameters on stack
	;
	; note that since UserStandardDialog takes its parameters on the stack,
	; we cannot leave anything on the stack across the call to
	; UserStandardDialog and we do not free these parameters after the call
	;
	;	cs:si = WarningTableEntry
	;

	sub	sp, size StandardDialogParams
	mov	bx, sp


	;
	; See if there are custom triggers
	; 
	tst	cs:[DesktopWarningTable][si].WTE_customTriggers
	jz	afterTriggers

	;
	; See if the caller wants a "skip" trigger
	;

	test	ss:[warningFlags], mask DWF_NO_SKIP_TRIGGER
	jz	useNormalTriggers

	mov	di, cs:[DesktopWarningTable][si].WTE_customTriggers
				; cx:bx - custom triggers

	mov	ss:[triggerTable], 2	; 2 triggers

	;
	; Caller only wants the first and 3rd triggers -- so copy them
	; onto the stack
	;

	add	di, offset SDRTT_triggers	; cs:di - first trigger
	movdw	ss:[firstTrigger].SDRTE_moniker, cs:[di].SDRTE_moniker, ax
	mov	ax, cs:[di].SDRTE_responseValue
	mov	ss:[firstTrigger].SDRTE_responseValue, ax

	add	di, 2*size StandardDialogResponseTriggerEntry
	movdw	ss:[secondTrigger].SDRTE_moniker, cs:[di].SDRTE_moniker, ax
	mov	ax, cs:[di].SDRTE_responseValue
	mov	ss:[secondTrigger].SDRTE_responseValue, ax
			

	mov	ss:[bx].SDP_customTriggers.segment, ss
	lea	ax, ss:[triggerTable]
	mov	ss:[bx].SDP_customTriggers.offset, ax
	jmp	afterTriggers

useNormalTriggers:
	mov	ss:[bx].SDP_customTriggers.segment, cs
	mov	ax, cs:[DesktopWarningTable][si].WTE_customTriggers
	mov	ss:[bx].SDP_customTriggers.offset, ax

afterTriggers:

	;
	; set up filename for error box, if needed
	;	fileOperationInfoEntryBuffer - filename info
	;	pathBuffer - name if recurErrorFlag set
	;	ds:dx - name if DETF_USE_DS_DX_NAME set
	;	ss:bx = StandardDialogParams
	;

	mov	ax, cs:[DesktopWarningTable][si].WTE_flags
	test	ax, mask DETF_USE_DS_DX_NAME
	jnz	useDSDXName
	test	ax, mask DETF_USE_DS_DX_STRING
	jnz	useDSDXString

	mov	cx, ss
	mov	dx, offset fileOperationInfoEntryBuffer.FOIE_name
	jmp	10$

useDSDXName:
	call	GetTailComponent
useDSDXString:
	mov	cx, ds
10$:
	; cx:dx - filename

	cmp	ss:[recurErrorFlag], 1		; recursive file-op error?
	jne	haveName			; nope, use normal name

	mov	cx, ss
	mov	dx, offset dgroup:pathBuffer	; else, use this

	; don't reset flag as another recursive error (or warning) may
	; need to be reported after this warning (flag is reset by caller
	; of file operation that initially set the flag)

;	mov	ss:[recurErrorFlag], 0

haveName:
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, cxdx					>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	popdw	bxsi						>
endif
	;
	; set up warning string
	;	cx:dx = filename
	;	ax = flags
	;	ss:bx = StandardDialogParams
	;
	; no string arg 2

	push	ax, bx
	movdw	bxsi, ss:[warningString]
	call	MemLock
	mov	ds, ax
	pop	ax, bx
	mov	si, ds:[si]
	movdw	ss:[bx].SDP_stringArg1, cxdx
	movdw	ss:[bx].SDP_customString, dssi

	

	;
	; set up and call UserStandardDialog
	;	ax = DesktopErrorTableFlags (misnomer, no?)
	;	ss:bx = StandardDialogParams
	;
						; custom box - assume Y/N/C
	mov	cx, ((CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
		    (GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE))
	test	ax, mask DETF_NO_CANCEL
	jz	70$				; keep cancel
	mov	cx, ((CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE))
70$:
	test	ax, mask DETF_PROMPT		; prompt box?
	jz	75$				; nope, use whatever we got
	mov	cx, ((CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
		    (GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE))
75$:

if _NEWDESK
	; Don't do this in GeoManager, because it's a pain in the ass
	; for users...
	;
		
	;
	; If destructive, don't make the "YES" trigger the default.
	;

	test	ax, mask DETF_DESTRUCTIVE
	jz	storeFlags
	ornf	cx, mask CDBF_DESTRUCTIVE_ACTION
storeFlags:
endif
		
	mov	ss:[bx].SDP_customFlags, cx
	clr	ss:[bx].SDP_helpContext.segment
	mov	ss:[modalBoxUp], TRUE
	;
	; params are on stack
	;
	mov	si, ax				; flags
	call	UserStandardDialog		; put up box
	mov	ss:[modalBoxUp], FALSE
	;
	; clean up
	;	ax = response
	;
	mov	bx, ss:[warningString].handle
	call	MemUnlock
	;
	; process UserStandardDialog response
	;	ax = response
	;	si = flags
	;
detachEntry:
	mov	cx, DESK_DB_DETACH		; assume detach error code
	cmp	ss:[willBeDetaching], TRUE	; detach waiting?
	je	90$				; yes, return detach
	cmp	ss:[detachActiveHandling], TRUE	; detach waiting?
	je	90$				; yes, return detach
	cmp	ax, IC_NULL			; application detached?
	je	90$				; yes, return detach
	mov	cx, YESNO_NO			; assume no
	cmp	ax, IC_NO			; no?
	je	90$				; yes, return no
	mov	cx, YESNO_YES			; assume yes
	cmp	ax, IC_YES			; yes?
	je	90$				; yes, return yes
EC <	test	si, mask DETF_NO_CANCEL					>
EC <	ERROR_NZ	BOGUS_USER_STANDARD_DIALOG_RESPONSE		>
	mov	cx, YESNO_CANCEL		; assume cancel
	cmp	ax, IC_DISMISS			; cancel?
	je	90$				; yes, return cancel
EC <	ERROR BOGUS_USER_STANDARD_DIALOG_RESPONSE			>
90$:
	mov	ax, cx				; return response in AX
	.leave
	ret
DesktopYesNoWarning	endp

DesktopWarningTable	label	WarningTableEntry
    WarningTableEntry	<
	WARNING_DELETE_FILE,				;WTE_warning
	DeleteFileWarningStr,				;WTE_string
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset DeleteFileWarningTriggerTable		;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DELETE_DIR,				;WTE_warning
	DeleteDirWarningStr,				;WTE_string
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset DeleteDirWarningTriggerTable		;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DELETE_READONLY,		 	;WTE_warning
	DeleteReadOnlyWarningStr,		 	;WTE_string
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset DeleteReadOnlyWarningTriggerTable 	;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DELETE_LINK,			 	;WTE_warning
	DeleteLinkWarningStr,			 	;WTE_string
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset DeleteFileWarningTriggerTable	 	;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_THROW_AWAY_FILE,			;WTE_warning
	ThrowAwayFileWarningStr,			;WTE_string
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset ThrowAwayFileWarningTriggerTable		;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_THROW_AWAY_DIR,				;WTE_warning
	ThrowAwayDirWarningStr,				;WTE_string
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset ThrowAwayDirWarningTriggerTable		;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_THROW_AWAY_READONLY,		 	;WTE_warning
	ThrowAwayReadOnlyWarningStr,		 	;WTE_string
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset ThrowAwayReadOnlyWarningTriggerTable 	;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_THROW_AWAY_LINK,		 	;WTE_warning
	ThrowAwayLinkWarningStr,		 	;WTE_string
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset ThrowAwayFileWarningTriggerTable 	;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_REPLACE_32_FILE,			;WTE_warning
	ReplaceFileWarningStr,				;WTE_string
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset ReplaceFileWarningTriggerTable		;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_REPLACE_WASTEBASKET_FILE,		;WTE_warning
	ReplaceWastebasketFileWarningStr,		;WTE_string
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset ReplaceFileWarningTriggerTable		;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DELETE_ITEMS,				;WTE_warning
	DeleteItemsWarningStr,				;WTE_string
	mask DETF_DESTRUCTIVE,
	offset DeleteItemsWarningTriggerTable		;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_THROW_AWAY_ITEMS,			;WTE_warning
	ThrowAwayItemsWarningStr,			;WTE_string
	mask DETF_DESTRUCTIVE,
	offset ThrowAwayItemsWarningTriggerTable 	;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_RECURSIVE_ACCESS_DENIED,	 	;WTE_warning
	RecursiveAccessDeniedStr,		 	;WTE_string
	mask DETF_SHOW_FILENAME,		 	;WTE_flags
	offset RecursiveAccessDeniedTriggerTable 	;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DISK_COPY_SOURCE,			;WTE_warning
	DiskCopyPromptSourceStr,			;WTE_string
	mask DETF_USE_DS_DX_NAME or mask DETF_PROMPT,	;WTE_flags
	offset DiskCopyPromptSourceTriggerTable		;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DISK_COPY_DEST,				;WTE_warning
	DiskCopyPromptDestStr,				;WTE_string
	mask DETF_USE_DS_DX_NAME or mask DETF_PROMPT,	;WTE_flags
	offset DiskCopyPromptDestTriggerTable		;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DISK_COPY_NUM_SWAPS,			;WTE_warning
	DiskCopyNumSwapsStr,				;WTE_string
					; ds:dx = # of swaps
	mask DETF_USE_DS_DX_NAME or mask DETF_NO_CANCEL,;WTE_flags
	offset DiskCopyNumSwapsTriggerTable		;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DISK_COPY_DESTROY_DEST_NAME,			;WTE_warning
	DiskCopyDestroyDestNameStr,				;WTE_string
	mask DETF_USE_DS_DX_NAME or \
		mask DETF_NO_CANCEL or \
		mask DETF_DESTRUCTIVE,
	offset DiskCopyDestroyDestNameTriggerTable 	;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DISK_COPY_DESTROY_DEST_NO_NAME,			;WTE_warning
	DiskCopyDestroyDestNoNameStr,				;WTE_string
	mask DETF_USE_DS_DX_NAME or \
		mask DETF_NO_CANCEL or \
		mask DETF_DESTRUCTIVE,
	offset DiskCopyDestroyDestNoNameTriggerTable 	;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DISK_FORMAT_NO_NAME,			;WTE_warning
	DiskFormatNoNameStr,				;WTE_string
	mask DETF_NO_CANCEL,				;WTE_flags
	0						;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_FORMAT_LO_IN_HI,			;WTE_warning
	FormatLoInHiStr,				;WTE_string
	mask DETF_NO_CANCEL,				;WTE_flags
	0						;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_EMPTY_WASTEBASKET,			;WTE_warning
	EmptyWastebasket,				;WTE_string
	mask DETF_DESTRUCTIVE,
	YesNoTriggerTable				;WTE_customTriggers
    >
    WarningTableEntry	<
	WARNING_DELETING_APPLICATION,			;WTE_warning
	DeletingExecutable,				;WTE_string
	mask DETF_SHOW_FILENAME or \
		mask DETF_DESTRUCTIVE,
	YesNoTriggerTable				;WTE_customTriggers
    >
if _NEWDESKBA
    WarningTableEntry	<
	WARNING_ADDING_STUDENT,
	AddingStudentWarning,
	mask DETF_USE_DS_DX_NAME or mask DETF_NO_CANCEL,
	0
    >,
    <
	WARNING_ADDING_PROGRAM,
	AddingProgramWarning,
	mask DETF_USE_DS_DX_STRING or mask DETF_NO_CANCEL,
	0
    >,
    <
	WARNING_REMOVE,
	RemoveWarning,
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset RemoveTriggerTable
    >,
    <	
	WARNING_DELETE,
	DeleteFileWarningStr,
	mask DETF_SHOW_FILENAME or mask DETF_DESTRUCTIVE,
	offset DeleteTriggerTable
    >,
    <
	WARNING_CREATING_STUDENT_UTILITY_DRIVE,
	CreatingStudentUtilityWarning,
	mask DETF_USE_DS_DX_NAME or mask DETF_NO_CANCEL,
	0
    >,
    <
	WARNING_REMOVING_STUDENT_UTILITY_DRIVE,		;WTE_warning
	RemovingStudentUtilityWarning,			;WTE_string
	mask DETF_DESTRUCTIVE,				;WTE_flags
	offset YesNoTriggerTable			;WTE_customTriggers
    >
endif

if _CONNECT_MENU
    WarningTableEntry	<
	WARNING_FILE_TRANSFER,
	FileTransferWarning,
	0,
	offset FileTransferWarningTriggerTable
    >
endif
if _KEEP_MAXIMIZED
    WarningTableEntry	<
	WARNING_FILE_LINKING,
	FileLinkingWarning,
	mask DETF_NO_CANCEL,
	0,
    >
endif

    WarningTableEntry	<
	WARNING_OPERATION_FILE_IN_USE,
	OperationFileInUseWarningStr,
	mask DETF_USE_DS_DX_NAME or mask DETF_NO_CANCEL,
	0
    >
    WarningTableEntry	<
	WARNING_MOVE_READONLY,
	MoveReadOnlyWarning,
	mask DETF_NO_CANCEL,
	0
    >
    WarningTableEntry	<
	WARNING_TREAT_REMOTE_FILES_LIKE_READ_ONLY,
	TreatRemoteFilesLikeReadOnly,
	mask DETF_NO_CANCEL,
	0
    >
	word	NIL				; end of table

DeleteFileWarningTriggerTable	label	StandardDialogResponseTriggerTable
	word	3
	StandardDialogResponseTriggerEntry <
		DeleteFileWarning_Yes,
		IC_YES
    	>
	StandardDialogResponseTriggerEntry <
		DeleteFileWarning_No,
		IC_NO
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,
		IC_DISMISS
	>

if _NEWDESKBA

RemoveTriggerTable	StandardDialogResponseTriggerTable  <3>

	StandardDialogResponseTriggerEntry	\
	<	RemoveMoniker,		IC_YES		>,
	<	SkipMoniker,		IC_NO		>,
	<	CancelOperationMoniker,	IC_DISMISS	>


DeleteTriggerTable	StandardDialogResponseTriggerTable <3>

	StandardDialogResponseTriggerEntry	\
	<	DeleteMoniker,			IC_YES		>,
	<	SkipMoniker,			IC_NO		>,
	<	CancelOperationMoniker,		IC_DISMISS	>

endif

DeleteDirWarningTriggerTable	label	StandardDialogResponseTriggerTable
	word	3
	StandardDialogResponseTriggerEntry <
		DeleteDirWarning_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		DeleteDirWarning_No,
		IC_NO
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,
		IC_DISMISS
	>

DeleteReadOnlyWarningTriggerTable label	StandardDialogResponseTriggerTable
	word	3
	StandardDialogResponseTriggerEntry <
		DeleteReadOnlyWarning_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		DeleteReadOnlyWarning_No,
		IC_NO
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,
		IC_DISMISS
	>

ThrowAwayFileWarningTriggerTable label	StandardDialogResponseTriggerTable
	word	3
	StandardDialogResponseTriggerEntry <
		ThrowAwayFileWarning_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		DeleteFileWarning_No,
		IC_NO
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,	
		IC_DISMISS
	>

ThrowAwayDirWarningTriggerTable	label	StandardDialogResponseTriggerTable
	word	3
	StandardDialogResponseTriggerEntry <
		ThrowAwayDirWarning_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		DeleteDirWarning_No,		; these are same as delete
		IC_NO
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,	
		IC_DISMISS
	>

ThrowAwayReadOnlyWarningTriggerTable label StandardDialogResponseTriggerTable
	word	3
	StandardDialogResponseTriggerEntry <
		ThrowAwayReadOnlyWarning_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		DeleteFileWarning_No,
		IC_NO
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,	
		IC_DISMISS
	>

ReplaceFileWarningTriggerTable	label	StandardDialogResponseTriggerTable
	word	3
	StandardDialogResponseTriggerEntry <
		ReplaceFileWarning_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		ReplaceFileWarning_No,
		IC_NO
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,
		IC_DISMISS
	>

DeleteItemsWarningTriggerTable	label	StandardDialogResponseTriggerTable
	word	2
	StandardDialogResponseTriggerEntry <
		DeleteItemsWarning_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,
		IC_DISMISS
	>

ThrowAwayItemsWarningTriggerTable label	StandardDialogResponseTriggerTable
	word	2
	StandardDialogResponseTriggerEntry <
		ThrowAwayItemsWarning_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,
		IC_DISMISS
	>

RecursiveAccessDeniedTriggerTable label	StandardDialogResponseTriggerTable
	word	2
	StandardDialogResponseTriggerEntry <
		RecursiveAccessDenied_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,
		IC_DISMISS
	>

DiskCopyPromptSourceTriggerTable label	StandardDialogResponseTriggerTable
	word	2
	StandardDialogResponseTriggerEntry <
		DiskCopyPromptSource_OK,
		IC_YES				; we check for this in the code
	>
	StandardDialogResponseTriggerEntry <
		DiskCopyCancelMoniker,
		IC_DISMISS
	>

DiskCopyPromptDestTriggerTable	label	StandardDialogResponseTriggerTable
	word	2
	StandardDialogResponseTriggerEntry <
		DiskCopyPromptDest_OK,
		IC_YES				; we check for this in the code
	>
	StandardDialogResponseTriggerEntry <
		DiskCopyCancelMoniker,
		IC_DISMISS
	>

DiskCopyNumSwapsTriggerTable	label	StandardDialogResponseTriggerTable
	word	2
	StandardDialogResponseTriggerEntry <
		DiskCopyNumSwaps_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		DiskCopyCancelMoniker,
		IC_NO
	>

DiskCopyDestroyDestNameTriggerTable label StandardDialogResponseTriggerTable
	word	2
	StandardDialogResponseTriggerEntry <
		DiskCopyDestroyDestName_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		DiskCopyCancelMoniker,
		IC_NO
	>

DiskCopyDestroyDestNoNameTriggerTable label StandardDialogResponseTriggerTable
	word	2
	StandardDialogResponseTriggerEntry <
		DiskCopyDestroyDestNoName_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		DiskCopyCancelMoniker,
		IC_NO
	>

YesNoTriggerTable	label	StandardDialogResponseTriggerTable
	word 2
	StandardDialogResponseTriggerEntry <
		YesMoniker,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		NoMoniker,
		IC_NO
	>

if _CONNECT_MENU
FileTransferWarningTriggerTable label StandardDialogResponseTriggerTable
	word	2
	StandardDialogResponseTriggerEntry <
		FileTransferWarning_Yes,
		IC_YES
	>
	StandardDialogResponseTriggerEntry <
		CancelOperationMoniker,
		IC_NO
	>
endif


;
; called by:
;	DesktopOKError (same segment)
;	DesktopYesNoWarning (same segment)
;	TakeDownFileOpBox (diff. segment)
;
InformActiveBoxOfAttention	proc	far
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	mov	ax, MSG_APP_ACTIVE_ATTENTION
	mov	bx, handle Desktop
	mov	si, offset Desktop
	call	ObjMessageCall
	.leave
	ret
InformActiveBoxOfAttention	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopOKError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	displays dialog box showing error with OK icon

CALLED BY:	INTERNAL

PASS:		ax - error code

		fileOperationInfoEntryBuffer - 32 and 8.3 name info
			(if mask DETF_SHOW_FILENAME used in DesktopErrorTable)
		dx - handle of buffer containing filename causing error
			(if mask DETF_USE_DX_BUFFER_NAME used in
				DesktopErrorTable)
			(if 8.3 name, must be in GEOS character set)
		ss:[recurErrorFlag] = 1 if recursive file operation error
			(pathBuffer must be in GEOS character set)

RETURN:		carry set if error was processed and reported
		carry clear if error was ignored
		ax = original error code or DESK_DB_DETACH if detached while
			error box was up

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		since we use UserStandardDialog we have the consequence
		of using UserDoDialog to put up the error box, which
		blocks our thread, not allowing updating of application-
		views if they are exposed

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/5/89		Initial version
	brianc	10/12/89	added return status
	brianc	5/17/90		updated to use UserStandardDialog

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopOKError	proc	far
	push	ds, si
	segmov	ds, cs
	mov	si, offset PseudoResident:DesktopErrorTable
	call	DesktopErrorReporter
	pop	ds, si
	ret
DesktopOKError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopErrorReporter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	displays dialog box showing error with OK icon

CALLED BY:	INTERNAL

PASS:		ax - error code
		ds:si - table of error codes and error strings
					...
		fileOperationInfoEntryBuffer - 32 and 8.3 name info
			(if mask DETF_SHOW_FILENAME used in DesktopErrorTable)
		dx - handle of buffer containing filename causing error
			(if mask DETF_USE_DX_BUFFER_NAME used in
				DesktopErrorTable)
			(if 8.3 name, must be in GEOS character set)
		ss:[recurErrorFlag] = 1 if recursive file operation error
			(pathBuffer must be in GEOS character set)

RETURN:		carry set if error was processed and reported
		carry clear if error was ignored
		ax = original error code or DESK_DB_DETACH if detached while
			error box was up
		frees dx if mask DETF_USE_DX_BUFFER_NAME was passed

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		since we use UserStandardDialog we have the consequence
		of using UserDoDialog to put up the error box, which
		blocks our thread, not allowing updating of application-
		views if they are exposed

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/5/89		Initial version
	brianc	10/12/89	added return status
	brianc	5/17/90		updated to use UserStandardDialog

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopErrorReporter	proc	far
	uses	bx, cx, dx, ds, si, es, di, bp

errorCode	local	word	push	ax
filenameBuffer	local	hptr.char
errorString	local	optr.char

	.enter

	;
	; find correct string to use for given error code
	;
	clr	bx				; clear flags, in case no match
errorLoop:
	cmp	ds:[si].DETE_error, NIL		; end of table?
	je	noErrorMatch			; yes, no match
	cmp	ds:[si].DETE_error, ax		; does this one match?
	je	foundErrorEntry			; yes, use it
	add	si, size DesktopErrorTableEntry	; move to next entry
	jmp	errorLoop
	;
	; error code not found, put up generic error message
	;
noErrorMatch:
	mov	ss:[errorString].handle, handle GenericErrStr
	mov	ss:[errorString].offset, offset GenericErrStr
	jmp	haveErrorString
	;
	; found error string for this error
	;
foundErrorEntry:

	;
	; Found the entry -- fetch the flags and optr of the error
	; string. 
	;

	mov	bx, ds:[si].DETE_flags
	movdw	ss:[errorString], ds:[si].DETE_string, ax
	tst	ax
LONG	jz	ignoreError			; yes, ignore
	cmp	ax, NIL				; ignore w/error?
	stc					; assume ignore, but return C=1
LONG	je	ignoreError			; yes, ignore

if _ZMGR
	;
	; On ZMGR, if write-protect error on StandardPath (which is in ROM
	; or in GFS, or in writable-RAM disk), give special error message.
	;
	cmp	ss:[errorString].offset, offset WriteProtectedErrStr
	jne	notSP
	cmp	ss:[errorString].handle, handle WriteProtectedErrStr
	jne	notSP
	; cur dir is destination
	push	bx, cx
	mov	cx, 0				; no buffer
	call	FileGetCurrentPath		; bx = disk handle
	mov_tr	ax, bx				; ax = disk handle
	pop	bx, cx
	test	ax, DISK_IS_STD_PATH_MASK	; SP? (ROM)
	jnz	isSP
	push	bx
	mov_tr	bx, ax				; bx = disk handle
	call	DiskGetDrive			; al = drive number
	pop	bx
	cmp	al, 0				; ROM disk?
	je	isSP
	call	DriveGetExtStatus		; ax = DriveExtendedStaus
	test	ax, mask DES_READ_ONLY		; read-only? (GFS)
	jz	notSP
isSP:
						; else, is on StandardPath
	mov	ss:[errorString].offset, offset CantModifyFileErrStr
	mov	ss:[errorString].handle, handle CantModifyFileErrStr
notSP:
endif

;;	;
;;	; bring down any file-op pprogress box before putting up error box
;;	;
;;	call	RemoveFileOpProgressBox
	;
	; set up filename for error box, if needed
	;	bx = error flags
	;	fileOperationInforEntryBuffer - filename info
	;	pathBuffer - name if recurErrorFlag set
	;	dx - handle of buffer with name if DETF_USE_DX_BUFFER_NAME set
	;
	test	bx, mask DETF_USE_DX_BUFFER_NAME	; use buffer?
	jz	notBuffer				; nope

	push	bx
	mov	ss:[filenameBuffer], dx
	mov	bx, dx
	call	MemLock				; lock name buffer
	pop	bx				; retrieve flags
	mov	cx, ax				; cx:dx = name
	clr	dx
	jmp	short haveName

notBuffer:
	mov	cx, ss				; cx:dx = longname
	mov	dx, offset dgroup:fileOperationInfoEntryBuffer.FOIE_name
	cmp	ss:[recurErrorFlag], 1		; recursive file-op error?
	jne	haveName			; nope, use normal name
	mov	dx, offset dgroup:pathBuffer	; else, use this
	mov	ss:[recurErrorFlag], 0		; reset flag

haveName:
haveErrorString:
	;
	; set up error string
	;	cx:dx = filename
	;	bx = flags
	;
	push	bp				; frame ptr
	push	bx
	movdw	bxsi, ss:[errorString]
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	mov	di, ds
	mov	bp, si
	pop	bx

	;
	; set up and call UserStandardDialog
	;	di:bp = error string
	;	cx:dx = filename string (if needed)
	;	bx = flags
	;
						; custom box
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		    (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	test	bx, mask DETF_NOTICE		; not notice, use error
	jz	44$
	mov	ax, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
		    (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
44$:
	test	bx, mask DETF_SYS_MODAL		; system modal box?
	jz	46$				; nope
	ornf	ax, mask CDBF_SYSTEM_MODAL
46$:
	cmp	ss:[willBeDetaching], TRUE	; detach waiting?
	je	60$				; yes, don't put up box
	cmp	ss:[detachActiveHandling], TRUE	; detach waiting?
	jne	afterActive			; no, continue
	call	InformActiveBoxOfAttention	; else, change text in active
						;	box
afterActive:
	mov	ss:[modalBoxUp], TRUE
	call	DeskCallUserStandardDialog	; put up box
	mov	ss:[modalBoxUp], FALSE
60$:
	pop	bp				; frame ptr

	;
	; clean up filename and error string
	;	ax = response
	;	bx = flags
	;	si = filename buffer handle (if any)
	;
	push	bx
	mov	bx, ss:[errorString].handle
	call	MemUnlock
	pop	bx

	test	bx, mask DETF_USE_DX_BUFFER_NAME	; used filename buffer?
	jz	afterFree			; nope
	mov	bx, ss:[filenameBuffer]
	call	MemFree				; else, free filename buffer
afterFree:
	stc					; indicate error reported
	jmp	short fixResponse

ignoreError:
	mov	ax, NIL				; maintain orig. error code
fixResponse:

	;
	; process UserStandardDialog response
	;
	pushf					; save error report status
	cmp	ss:[willBeDetaching], TRUE	; detach waiting?
	je	90$				; yes, indicate this
	cmp	ss:[detachActiveHandling], TRUE	; detach waiting?
	je	90$				; yes, indicate this
	cmp	ax, IC_NULL			; application detached?
	jne	95$				; no, keep error code
90$:
	mov	ss:[errorCode], DESK_DB_DETACH
95$:
	popf					; retreive error status

	mov	ax, ss:[errorCode]
	.leave
	ret
DesktopErrorReporter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskCallUserStandardDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call UserStandardDialog

CALLED BY:	DesktopErrorReporter

PASS:		ax - CustomDialogBoxFlags
		di:bp = error string
		cx:dx = arg 1
		bx:si = arg 2

RETURN:		ax - InteractionCommand

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskCallUserStandardDialog	proc	near

	; we must push 0 on the stack for SDP_helpContext

	push	bp, bp			;push dummy optr
	mov	bp, sp			;point at it
	mov	ss:[bp].segment, 0
	mov	bp, ss:[bp].offset

.assert (offset SDP_customTriggers eq offset SDP_stringArg2+4)
	push	ax		; don't care about SDP_customTriggers
	push	ax
.assert (offset SDP_stringArg2 eq offset SDP_stringArg1+4)
	push	bx		; save SDP_stringArg2 (bx:si)
	push	si
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	cx		; save SDP_stringArg1 (cx:dx)
	push	dx
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	di		; save SDP_customString (di:bp)
	push	bp
.assert (offset SDP_customFlags eq 0)
	push	ax		; SDP_customFlags
				; params are on stack
	call	UserStandardDialog
	ret
DeskCallUserStandardDialog	endp

DesktopErrorTable	label	DesktopErrorTableEntry

	DesktopErrorTableEntry	<
		ERROR_PATH_NOT_FOUND,
		PathNotFoundErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_ACCESS_DENIED,
		AccessDeniedErrStr,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry	<
		ERROR_SHARING_VIOLATION,
		AccessDeniedErrStr,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry	<
		ERROR_FILE_IN_USE,
		AccessDeniedErrStr,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry	<
		ERROR_INVALID_DRIVE,
		InvalidVolumeErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_IS_CURRENT_DIRECTORY,
		IsCurrentDirectoryErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_WRITE_PROTECTED,
		WriteProtectedErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_UNKNOWN_VOLUME,
		UnknownVolumeErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_DRIVE_NOT_READY,		; 21
		DriveNotReadyErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_CRC_ERROR,		; 23
		DriveNotReadyErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_SEEK_ERROR,		; 25
		DriveNotReadyErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_UNKNOWN_MEDIA,		; 26
		DriveNotReadyErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_SECTOR_NOT_FOUND,		; 27
		DriveNotReadyErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_WRITE_FAULT,		; 29
		DriveNotReadyErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_READ_FAULT,		; 30
		DriveNotReadyErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_GENERAL_FAILURE,		; 31
		DriveNotReadyErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_FILE_EXISTS,
		FileExistsErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_LINK_EXISTS,
		LinkExistsErrStr,
		0
	>
;;cannot enter wildcard chars - 6/12/90
;;	DesktopErrorTableEntry	<
;;		ERROR_NO_WILDCARDS,
;;		NoWildcardsErrStr,
;;		0
;;	>
	DesktopErrorTableEntry	<
		ERROR_SAME_FILE,
		SameFileErrStr,
;		NIL,				; ignore but return error
		0
	>
	DesktopErrorTableEntry	<
		ERROR_COPY_MOVE_TO_CHILD,
		CopyMoveToChildErrStr,
;		NIL,				; ignore but return error
		0
	>
	DesktopErrorTableEntry	<
		ERROR_REPLACE_PARENT,
		ReplaceParentErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_FILE_NOT_FOUND,
		FileNotFoundErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_ROOT_FILE_OPERATION,
		RootFileOperationErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_TOO_MANY_FOLDER_WINDOWS,
		TooManyFolderWindowsErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_INVALID_NAME,
		InvalidNameErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_CANT_OPEN_FILE,
		CantOpenFileErrStr,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry	<
		ERROR_CANT_FORMAT_SYSTEM_DRIVE,
		CantFormatSysDriveErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_NO_PARENT_APPLICATION,
		NoParentApplicationErrString,
		mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME
	>
	DesktopErrorTableEntry	<
		ERROR_INSUFFICIENT_SPACE,
		InsufficientSpaceErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_INSUFFICIENT_SPACE_NO_SUGGESTION,
		InsufficientSpaceNoSuggestionErrStr,
		0
	>
	DesktopErrorTableEntry <
		ERROR_COPY_DEST_PATH_TOO_LONG,
		CopyDestPathTooLong,
		0
	>
if (not _FCAB and not _ZMGR)
	DesktopErrorTableEntry <
		ERROR_THROW_AWAY_DEST_PATH_TOO_LONG,
		ThrowAwayDestPathTooLong,
		0
	>
endif		; if ((not _FCAB) and (not _ZMGR))
	DesktopErrorTableEntry	<
		ERROR_WASTEBASKET_FULL,
		WastebasketFullErrStr,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry	<
		ERROR_INSUFFICIENT_MEMORY,
		NotEnoughMemoryErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_TOO_MANY_OPEN_FILES,
		NotEnoughMemoryErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_DOS_EXEC_IN_PROGRESS,
		DosExecInProgressErrStr,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry	<
		ERROR_DIRECTORY_NOT_EMPTY,
		DirNotEmptyErrStr,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry	<
		ERROR_TOO_MANY_FILES,
		TooManyFilesErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_DISK_RENAME,
		DiskRenameErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_CANT_CREATE_DIR,
		CantCreateDirErrStr,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry	<
		ERROR_PATH_TOO_LONG,
		PathTooLongErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_SYSTEM_FOLDER_DESTRUCTION,
		SystemFolderDestructionErrStr,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry	<
		ERROR_BAD_VOLUME_NAME,
		BadVolumeNameErrStr,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_MASTER_LAUNCHER_MISSING,
		MasterLauncherMissing,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_MASTER_LAUNCHER_BAD,
		MasterLauncherBad,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_LAUNCHER_FAILED,
		LauncherFailed,
		0
	>
	DesktopErrorTableEntry	<
		ERROR_LAUNCHER_NAME_CONFLICT,
		LauncherNameConflict,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry <
		ERROR_RECOVER_TO_WASTEBASKET,
		RecoverToWastebasket,
		mask DETF_NOTICE
	>
	DesktopErrorTableEntry <
		ERROR_THROW_AWAY_FILE_IN_WB,
		ThrowAwayFileInWB,
		mask DETF_NOTICE
	>
	DesktopErrorTableEntry <
		ERROR_NO_SELECTION,
		ErrorNoSelection,
		mask DETF_NOTICE
	>
	DesktopErrorTableEntry <
		ERROR_CANNOT_MOVE,
		CannotMove,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry <
		ERROR_CANNOT_COPY,
		CannotCopy,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry <
		ERROR_CANNOT_DELETE,
		CannotDelete,
		mask DETF_SHOW_FILENAME
	>
	DesktopErrorTableEntry <
		ERROR_BLANK_NAME,
		BlankName,
		0
	>
	DesktopErrorTableEntry <
		ERROR_TOO_MANY_LINKS,
		TooManyLinks,
		0
	>
if _FCAB
	DesktopErrorTableEntry <
		ERROR_FILE_CABINET_CANNOT_DELETE_FILE,
		FileCabinetCannotDeleteFile,
		mask DETF_SHOW_FILENAME
	>
endif		; if _FCAB
	DesktopErrorTableEntry <
		ERROR_LINK_TARGET_GONE,
		LinkTargetGone,
		0
	>
if _NEWDESK
	DesktopErrorTableEntry <
		ERROR_DRIVE_LINK_TARGET_GONE,
		DriveLinkTargetGone,
		0
	>
	DesktopErrorTableEntry <
		ERROR_ND_OBJECT_NOT_ALLOWED,
		NDObjectNotAllowed,
		mask DETF_SHOW_FILENAME
	>
if GPC_FOLDER_WINDOW_MENUS
	DesktopErrorTableEntry <
		ERROR_DRAG_NOT_ALLOWED,
		DragNotAllowed,
		0
	>
endif
	DesktopErrorTableEntry <
		ERROR_CANNOT_OVERWRITE_THIS_WOT,
		CannotOverwriteThisWOT,
		mask DETF_SHOW_FILENAME
	>
endif		; if _NEWDESK
if _NEWDESKBA
	DesktopErrorTableEntry <
		ERROR_OPEN_INCORRECT_SELECTION,
		OpenIncorrectSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_THROW_AWAY_NO_SELECTION,
		ThrowAwayNoSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_RECOVER_NO_SELECTION,
		RecoverNoSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_COPY_NO_SELECTION,
		CopyNoSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_DISTRIBUTE_NO_SELECTION,
		DistributeNoSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_DISTRIBUTE_WRONG_OBJECT_TYPE,
		DistributeWrongObjectType,
		0
	>
	DesktopErrorTableEntry <
		ERROR_STUDENT_MANAGE_INCORRECT_SELECTION,
		StudentManageIncorrectSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_CLASS_DELETE_NO_SELECTION,
		ClassDeleteNoSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_CLASS_MANAGE_INCORRECT_SELECTION,
		ClassManageIncorrectSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_CLASS_MODIFY_INCORRECT_SELECTION,
		ClassModifyIncorrectSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_ROSTER_REMOVE_NO_SELECTION,
		RosterRemoveNoSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_CLASS_OPEN_INCORRECT_SELECTION,
		ClassOpenIncorrectSelection,
		0
	>
	DesktopErrorTableEntry <
		ERROR_HOME_UNSUPPORTED_TRANSFER_OPERATION,
		HomeUnsupportedTransferOperation,
		mask DETF_USE_DS_DX_NAME
	>
	DesktopErrorTableEntry <
		ERROR_CLASSES_UNSUPPORTED_TRANSFER_OPERATION,
		ClassesUnsupportedTransferOperation,
		mask DETF_USE_DS_DX_NAME
	>
	DesktopErrorTableEntry <
		ERROR_LIST_TOO_MANY_SELECTIONS,
		ListTooManySelections,
		0
	>
	DesktopErrorTableEntry <
		ERROR_ROSTER_UNSUPPORTED_TRANSFER_OPERATION,
		RosterUnsupportedTransferOperation,
		mask DETF_USE_DS_DX_NAME
	>
	DesktopErrorTableEntry <
		ERROR_DESKTOP_UNSUPPORTED_TRANSFER_OPERATION,
		DesktopUnsupportedTransferOperation,
		0
	>
	DesktopErrorTableEntry <
		ERROR_FOLDER_UNSUPPORTED_TRANSFER_OPERATION,
		FolderUnsupportedTransferOperation,
		0
	>
	DesktopErrorTableEntry <
		ERROR_REJECT_ENTRY,
		RejectEntry,
		0
	>
	DesktopErrorTableEntry <
		ERROR_INVALID_CLASS_DESCRIPTION,
		InvalidClassDescription,
		0
	>
	DesktopErrorTableEntry <
		ERROR_DUPLICATE_CLASS_DESCRIPTION,
		DuplicateClassDescription,
		0
	>
	DesktopErrorTableEntry <
		ERROR_TOO_MANY_CLASSES,
		TooManyClasses,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_CREATE_CLASS,
		UnableToCreateClass,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_CREATE_STUDENT_LINK,
		UnableToCreateLinkFromStudent,
		0
	>
	DesktopErrorTableEntry <
		ERROR_CREATING_STUDENT_UTILITY,
		CreatingStudentUtilityError,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_ADD_STUDENT,
		UnableToAddStudent,
		0
	>
	DesktopErrorTableEntry <
		ERROR_CANT_ADD_STUDENT_TWICE,
		CantAddStudentTwice,
		0
	>
	DesktopErrorTableEntry <
		ERROR_CANT_ADD_PROGRAM_TWICE,
		CantAddProgramTwice,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_ADD_COURSEWARE,
		UnableToAddCourseware,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_ADD_SPECIAL_UTILITY,
		UnableToAddSpecialUtility,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_ADD_OFFICE_APP,
		UnableToAddOfficeApp,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_REMOVE_STUDENT,
		UnableToRemoveStudent,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_REMOVE_CLASS,
		UnableToRemoveClass,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_REMOVE_COURSEWARE,
		UnableToRemoveCourseware,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_REMOVE_SPECIAL_UTILITY,
		UnableToRemoveSpecialUtility,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_REMOVE_OFFICE_APP,
		UnableToRemoveOfficeApp,
		0
	>
 	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_MODIFY_CLASS,
		UnableToModifyClass,
		0
	>
 	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_CHANGE_PASSWORD,
		UnableToChangePassword,
		0
	>
 	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_SET_BOOKMARK,
		UnableToSetBookmark,
		0
	>
 	DesktopErrorTableEntry <
		ERROR_CLASS_BOOKMARK_NO_SELECTION,
		SelectFileForBookmark,
		0
	>
 	DesktopErrorTableEntry <
		ERROR_ONLY_FILE_CAN_BE_SELECTED,
		OnlyFileCanBeSelected,
		0
	>
 	DesktopErrorTableEntry <
		ERROR_FILE_OPEN,
		CannotOpenFile,
		0
	>
 	DesktopErrorTableEntry <
		ERROR_INVALID_FILE_FORMAT,
		InvalidFileFormat,
		0
	>
 	DesktopErrorTableEntry <
		ERROR_NO_MATCHING_STUDENTS,
		NoMatchingStudents,
		0
	>
 	DesktopErrorTableEntry <
		ERROR_NO_MATCHING_PROGRAMS,
		NoMatchingPrograms,
		0
	>
	DesktopErrorTableEntry <
		ERROR_STUDENT_HAS_TOO_MANY_CLASSES,
		StudentHasTooManyClasses,
		0
	>
	DesktopErrorTableEntry <
		ERROR_TOO_MANY_STUDENTS_IN_CLASS,
		TooManyStudentsInClass,
		0
	>
	DesktopErrorTableEntry <
		ERROR_TOO_MANY_PROGRAMS_IN_CLASS,
		TooManyProgramsInClass,
		0
	>
	DesktopErrorTableEntry <
		ERROR_TOO_MANY_PROGRAMS_IN_HOME,
		TooManyProgramsInHome,
		0
	>
	DesktopErrorTableEntry <
		ERROR_CANT_CREATE_STUDENT_UTILITY_FROM_LIST,
		CreatingStudentUtilityFromList,
		0
	>
	DesktopErrorTableEntry <
		ERROR_DELETE_COURSEWARE_NOT_ALLOWED,
		DeleteCoursewareNotAllowed,
		0
	>
	DesktopErrorTableEntry <
		ERROR_MANAGE_CLASS_SUBFOLDERS_NOT_ALLOWED,
		ManageClassSubfoldersNotAllowed,
		0
	>
	DesktopErrorTableEntry <
		ERROR_DELETE_IN_THIS_FOLDER_NOT_ALLOWED,
		DeleteInThisFolderNotAllowed,
		0
	>
	DesktopErrorTableEntry <
		ERROR_GENERIC_HOME_NOT_OPENABLE,
		GenericHomeNotOpenable,
		0
	>
	DesktopErrorTableEntry <
		ERROR_TRANSFER_TO_GENERIC_HOME_NOT_ALLOWED,
		TransferToGenericHomeNotAllowed,
		0
	>
	DesktopErrorTableEntry <
		ERROR_GENERICS_CANT_BE_STUDENT_UTILITY,
		GenericsCantBeStudentUtility,
		0
	>
	DesktopErrorTableEntry <
		ERROR_CANT_ADD_OFFICE_APPS_TO_CLASS,
		CantAddOfficeAppsToClass,
		0
	>
	DesktopErrorTableEntry <
		ERROR_APPLICATION_ALREADY_RUNNING,
		ApplicationAlreadyRunning,
		0
	>
	DesktopErrorTableEntry <
		ERROR_NO_DELETE_FROM_TEACHER_LIBRARY,
		NoDeleteFromTeacherLibrary,
		0
	>
	DesktopErrorTableEntry <
		ERROR_UNABLE_TO_REMOVE_STUDENT_UTILITY_DRIVE,
		RemovingStudentUtilityError,
		0
	>
	DesktopErrorTableEntry <
		ERROR_BA_DRIVE_NO_LONGER_VALID,
		BADriveNoLongerValid,
		0
	>
endif		; if _NEWDESKBA

if _CONNECT_TO_REMOTE
	DesktopErrorTableEntry <
		ERROR_RFSD_ACTIVE,
		RFSDActiveError,
		0
	>
if _KEEP_MAXIMIZED
	DesktopErrorTableEntry <
		ERROR_RFSD_ACTIVE_2,
		RFSDActiveError2,
		0
	>
endif ; _KEEP_MAXIMIZED
endif ; _CONNECT_TO_REMOTE

if (_ZMGR and not _PMGR)
	DesktopErrorTableEntry <
		ERROR_TOO_MANY_WORLD_DIRS,
		TooManyWorldDirsError,
		0
	>
endif

	DesktopErrorTableEntry	<
		YESNO_NO,
		0,				; ignore these errors
						; (return Carry set)
		0
	>
	DesktopErrorTableEntry	<
		YESNO_YES,
		0,				; ignore these errors
						; (return Carry clear)
		0
	>
	DesktopErrorTableEntry	<
		YESNO_CANCEL,
		0,				; ignore these errors
						; (return Carry set)
		0
	>
	DesktopErrorTableEntry	<
		DESK_DB_DETACH,
		0,				; ignore these errors
						; (return Carry set)
		0
	>
if	_PCMCIA_FORMAT
	DesktopErrorTableEntry	<
		ERROR_UNABLE_TO_EXECUTE_DOS_PROGRAM_TO_FORMAT_PCMCIA,
		UnableToExecuteDosProgramToFormatPCMCIAStr,			
		mask DETF_NO_CANCEL
	>
	DesktopErrorTableEntry	<
		FORMAT_PCMCIA_EXIT_TO_DOS_SHORT,		
		FormatPCMCIAExitToDOSShortStr,
		mask DETF_NO_CANCEL or mask DETF_NOTICE
	>
	DesktopErrorTableEntry	<
		FORMAT_PCMCIA_EXIT_TO_DOS_LONG,		
		FormatPCMCIAExitToDOSLongStr,
		mask DETF_NO_CANCEL or mask DETF_NOTICE
	>
	DesktopErrorTableEntry	<
		FORMAT_PCMCIA_FLASH_SUCCESSFUL,
		FormatPCMCIAFlashSuccessfulStr,
		mask DETF_NO_CANCEL or mask DETF_NOTICE
	>
	DesktopErrorTableEntry	<
		FORMAT_PCMCIA_FAILED_DISPLAY_ERROR_NUMBER,
		FormatPCMCIAFailedButWeLackGoodErrorTextStr,
		mask DETF_NO_CANCEL or mask DETF_USE_DX_BUFFER_NAME
	>
	DesktopErrorTableEntry	<
		FORMAT_PCMCIA_WRITE_PROTECTED,
		FormatPCMCIAWriteProtectedStr,
		mask DETF_NO_CANCEL
	>
	DesktopErrorTableEntry	<
		PARTITION_PCMCIA_ATA_FAILED,
		PartitionPCMCIAATAFailedStr,
		mask DETF_NO_CANCEL
	>
	DesktopErrorTableEntry	<
		FORMAT_PCMCIA_FAILED_FOR_UNKNOWN_REASON,
		FormatPCMCIAFailedForUnknownReasonStr,
		mask DETF_NO_CANCEL
	>

endif
	DesktopErrorTableEntry <
		ERROR_NO_PRINTER,
		NoPrinterError,
		mask DETF_NO_CANCEL
	>
	word	NIL				; end of table



PseudoResident	ends


