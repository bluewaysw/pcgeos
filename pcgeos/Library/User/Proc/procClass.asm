COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Proc
FILE:		procClass.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenProcessClass		Superclass of all processes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	11/89		Added Application, Restore & Engine invocation

DESCRIPTION:
	This file contains routines to implement the UI_ class

	$Id: procClass.asm,v 1.1 97/04/07 11:44:16 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

			GenProcessClass

Synopsis
--------

GenProcessClass is the superclass of all processes that use the user interface.  This
class defines methods for standard user interface interaction.

	NOTE: The section between "Declaration" and "Methods declared" is
	      copied into ui.def by "pmake def"

Additional documentation
------------------------

From the perspective of the ProcessClass:

        MSG_META_ATTACH calls:

		MSG_PROCESS_STARTUP_UI_THREAD, which checks to see if there
		are any resources of the application which are marked as 
		"ui-object", that is, to be run by a UI thread.  If so, it
		then calls MSG_PROCESS_CREATE_UI_THREAD to create that thread,
		then marks the "ui-object" blocks as being run by that thread.

		Then, MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE, if
		MSG_META_ATTACH was called called with an appMode of
		MSG_GEN_PROCESS_RESTORE_FROM_STATE.

	MSG_META_ATTACH then calls MSG_META_APP_STARTUP on the application
		object. Any document passed in the AppLaunchBlock is opened
		by the document control at this point.

        MSG_META_ATTACH then calls ONE, & ONLY ONE, of:

                MSG_GEN_PROCESS_OPEN_APPLICATION, to cause the application to
                come up on screen.  This is implemented in the default handler
                by setting the application object USABLE.

                MSG_GEN_PROCESS_OPEN_ENGINE, which does nothing but mark the
                application as being in engine mode (Non-visual).  Currently,
                the only thing that ever happens in engine mode is that
                the desktop sends the process a MSG_GEN_PROCESS_INSTALL_TOKEN,
                which has a default handler which installs the application's
                moniker into the Token database.

		MSG_GEN_PROCESS_RESTORE_FROM_STATE, which gets whatever the app
		mode was the last time it was run, and restarts it.

        The process, in either case, receives a MSG_META_DETACH when it is
        to be shut down and exited.   MSG_META_DETACH calls:

                MSG_GEN_PROCESS_CLOSE_APPLICATION, to fetch any additional state
                that the application wants to save away (This block of
                data is returned to the application the next time it is loaded
		with the state file, in MSG_GEN_PROCESS_OPEN_APPLICATION),
		or MSG_GEN_PROCESS_CLOSE_ENGINE if opened in ENGINE mode.
		If the detach was *not* initiated by a MSG_META_QUIT, it
		then creates/attaches to a state file if none was passed
		earlier, then shuts down to state. If it was done by
		MSG_META_QUIT, we do not attach to a state file, but instead
		just exit. If we had already attached to a state file, we
		call ObjDisassocVMFile, and then delete the state file.


------------------------------------------------------------------------------@

UserClassStructures	segment resource

	GenProcessClass	mask CLASSF_NEVER_SAVED

UserClassStructures	ends

;---------------------------------------------------

AppAttach segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_Attach -- MSG_META_ATTACH for GenProcessClass

DESCRIPTION:	Attach the process.  Also called directly by a process
		to do default initialization

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax - MSG_META_ATTACH

Pass:
	dx	- Block handle to block of structure AppLaunchBlock

Return:
	Nothing

RETURN:

DESTROYED:
	ax, bx, cx, dx, bp, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

1) The default MSG_META_ATTACH will associate the process with any state
   file passed.  If a state file is not passed, it will not create a state
   file unless/until it receives a MSG_META_DETACH later.

2) The AppObj will be sent a MSG_META_ATTACH.  This method is NOT processed
   by the GenActiveList, but instead is processed by merely adding the
   application object into the generic tree.
   (Nothing is sent to the active list until the application is set USABLE)

3) The application mode method passed will be sent to the process, passed
   along with the AppLaunchBlock, any extra state block returned from
   the ObjAssocVMFile (if the app mode method is RESTORE_FROM_STATE), &
   AppAttachFlags.

4) Finally, any AppLaunchBlock passed, & any extra state block that was
   brought out of any state file passed, is freed.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	11/89		Added Application, Restore & Engine invocation

-------------------------------------------------------------------------------@

UI_Attach	method static	GenProcessClass, MSG_META_ATTACH	

	push	dx
	mov	ax, MSG_GEN_SYSTEM_MARK_BUSY
	call	UserCallSystem
	pop	dx

	; Update Field w/what geode handle we turned out to be, so it can
	; put up our icon as progress indication, if an "Activate" dialog
	; is on-screen for us.
	;
	push	ds
	push	dx
	mov	bx, dx				; dx = AppLaunchBlock
	call	MemLock
	mov	ds, ax
	call	GeodeGetProcessHandle
	mov	cx, bx				; get cx = geode
	mov	bx, ds:[ALB_genParent].handle	; get ^lbx:si = GenField
	mov	si, ds:[ALB_genParent].chunk
	mov	ax, MSG_GEN_FIELD_ACTIVATE_UPDATE
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	dx
	mov	bx, dx
	call	MemUnlock
	pop	ds

;Do this after setting the initial path specified in the AppLaunchBlock,
;as the UI thread will inherit our path.  The problem was that if you
;have an app on a PCMCIA card, its UI thread's path will be on the card
;and when hard icon apps are started on that UI thread, the hard icon apps
;will inherit that card path, a bad thing when the card is removed
;-brianc 7/15/93
;	; Startup UI thread for application, if it needs one.
;	;
;	push	dx			; Preserve AppLaunchBlock
;	mov	ax, MSG_PROCESS_STARTUP_UI_THREAD
;	call	GeodeGetProcessHandle
;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
;	call	ObjMessage
;	pop	dx

	push	es
	mov	bx, handle dgroup
	call	MemDerefES
	mov	bx, dx
EC <	tst	bx		; See if AppLaunchBlock passed		>
EC <	ERROR_Z	NO_APP_LAUNCH_BLOCK_PASSED_TO_APPLICATION		>

	; Set path for new application, if specified
	push	ds
	call	MemLock
	mov	ds, ax
	push	bx

	cmp	ds:[ALB_appMode], 0	; see if default mode should be used
	jne	haveMode		;Branch if not
	mov	ds:[ALB_appMode], MSG_GEN_PROCESS_OPEN_APPLICATION
haveMode:
	;
	; If we are running in UILM_TRANSPARENT mode and doing a
	; OPEN_APPLICATION, then stuff in the transparent state file name
	; for this geode and set RESTORE_FROM_STATE mode.  If there is no
	; such state file yet (the very first time the application is run,
	; or after a reset-after-crash), then
	; MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE will just behave
	; as if we are in OPEN_APPLICATION mode.
	;
	; NOTE:  If the application is running in desk accessory mode, then we
	; don't mess with it, as desk accessories are not affected by
	; UILM_TRANSPARENT mode.
	;
;	; NOTE:  We leave an existing state file alone.  This can only
;	; happen if this app is the single app that the field is currently
;	; saving in it's instance data.  In this case, we didn't use the
;	; transparent state file name when detaching.
; The above NOTE has been changed because we actually always save the state
; file with the transparent state file name, so in any case, we have the
; correct state file name if we have MSG_GEN_PROCESS_RESTORE_FROM_STATE
; - brianc 6/16/93
	;
	;	ds - AppLaunchBlock
	;	es - dgroup
	;
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	jne	afterTransparent

; Desk accessories are now transparently detachable just like other apps
; (only the user can choose to detach them before the system would)
;
;	test	ds:[ALB_launchFlags], mask ALF_DESK_ACCESSORY
;	jnz	afterTransparent

	cmp	ds:[ALB_appMode], MSG_GEN_PROCESS_OPEN_APPLICATION
	jne	afterTransparent

	;
	; If we are passed a datafile, then we don't want to restore from
	; state.  The existing state file will be truncate when we save to
	; state. - brianc 6/10/93
	;
	;	ds - AppLaunchBlock
	;
SBCS <	cmp	{byte} ds:[ALB_dataFile], 0				>
DBCS <	cmp	{wchar}ds:[ALB_dataFile], 0				>
	jne	afterTransparent		; have datafile

						; force restore from state
	mov	ds:[ALB_appMode], MSG_GEN_PROCESS_RESTORE_FROM_STATE
	push	es
	segmov	es, ds				; es:di = state file name buffer
	mov	di, offset ALB_appRef.AIR_stateFile
.assert (size AIR_stateFile ge FILE_LONGNAME_BUFFER_SIZE)
	call	GetTransparentStateFileName
	pop	es

afterTransparent:

	mov	cx, ds:[ALB_appMode]		; cx = app mode

;	cmp	byte ptr ds:[ALB_path], 0
;	jz	AfterSet		;Branch if not path passed
;				; Set the new current path for application
;	mov	bx, ds:[ALB_diskHandle] 
;	mov	dx, offset ALB_path
;	call	FileSetCurrentPath
;
;AfterSet:
;To prevent problems with threads being stuck on a PCMCIA card when the card
;is removed, just use SP_TOP here.  Apps will manually have to deal with
;setting up the right directory to access datafiles passed through the ALB.
;The document control correctly does this.  Always set SP_TOP, regardless of
;existance of passed path. - brianc 7/19/93
	mov	ax, SP_TOP
	call	FileSetStandardPath

				; If a state file was passed, set flag
				; in AppAttachFlags (for application's
				; sake)
	clr	ax		;Assume no state block
EC <	cmp	byte ptr ds:[ALB_appRef.AIR_stateFile], 0		>
EC <	jz	10$							>
EC <	cmp	ds:[ALB_appMode], MSG_GEN_PROCESS_RESTORE_FROM_STATE	>
EC <	ERROR_NZ STATE_FILE_PASSED_BUT_MODE_WAS_NOT_RESTORE_FROM_STATE	>
EC <10$:								>

	pop	bx		;Unlock the passed AppLaunchBlock
	call	MemUnlock
	pop	ds

;moved here from above - brianc 7/15/93
	; Startup UI thread for application, if it needs one.
	;
	push	ax, bx, cx
	mov	ax, MSG_PROCESS_STARTUP_UI_THREAD
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, bx, cx

	; Associate with a VM file
	; If a state file has been passed in, attach to it, else, just
	; continue onward without a state file.

	cmp	cx, MSG_GEN_PROCESS_RESTORE_FROM_STATE
	jnz	noStateFile	; If no statefile passed, branch
	push	bx		; Preserve AppLaunchBlock handle
	push	cx
	mov	dx, bx		; pass handle in dx
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE
	call	ObjMessage	; Returns ax = extra state block, if any
	pop	cx
	pop	bx

noStateFile:
	push	bx		;Save AppLaunchBlock
	mov	dx, bx		; pass AppLaunchBlock in dx
	push	ax		; Save extra state block returned from 
				; MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE
				; (if no state file, AX is 0 here, so it will
				; be as if no extra state was saved off).

; Ask the application object to attach itself into system generic tree.  Also
; copies app filename & state file name into local instance data. If document
; was passed, it is opened by the document control during this call (for
; dual-threaded apps, it is actually only opened after this method is
; complete, since the META_APP_STARTUP message will be queued for the
; GenDocumentGroup until we return).

	mov	ax, MSG_META_APP_STARTUP
	call	GenCallApplication

	pop	bp		;Restore extra state block
	pop	bx		;Restore handle of AppLaunchBlock

	push	ds		;
	call	MemLock		;Lock AppLaunchBlock (again!)
	mov	ds, ax		;
	mov	ax, ds:[ALB_appMode]	; fetch app attach mode to use

;	Set up AppAttachFlags in CX for the method handler we're about to call

	clr	cx
	cmp	ax, MSG_GEN_PROCESS_RESTORE_FROM_STATE
	jnz	UI_AfterStateTest
	ornf	cx, mask AAF_STATE_FILE_PASSED
UI_AfterStateTest:
				; If a data file was passed, set flag
				; in AppAttachFlags (for application's
				; sake)
SBCS <	cmp	byte ptr ds:[ALB_dataFile], 0				>
DBCS <	cmp	{wchar}ds:[ALB_dataFile], 0				>
	jz	UI_AfterDataTest
	ornf	cx, mask AAF_DATA_FILE_PASSED
UI_AfterDataTest:

	call	MemUnlock	; Unlock the AppLaunchBlock
	pop	ds

	push	bx		; Save handle of AppLaunchBlock
	mov	dx, bx		; pass AppLaunchBlock in dx
	push	bp		; Save extra state block
	call	GeodeGetProcessHandle

;	Here, AX is either MSG_GEN_PROCESS_RESTORE_FROM_STATE or
;	MSG_GEN_PROCESS_OPEN_APPLICATION or MSG_GEN_PROCESS_OPEN_ENGINE
;
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx
				; NUKE the extra state block, unless it's
				; saved away for later use
	tst	bx
	jz	UI_AfterStateBlockNuked
	call	RetrieveTempGenAppExtraStateBlock
	cmp	bx, cx
	je	UI_AfterStateBlockNuked
	call	MemFree
UI_AfterStateBlockNuked:
	pop	bx

				; NUKE the passed AppLaunchBlock
EC <	tst	bx							>
EC <	ERROR_Z	NO_APP_LAUNCH_BLOCK_PASSED_TO_APPLICATION		>
	call	MemFree
	pop	es

	; Notify whoever is listening that the app was started.
	; NOTE: This msg has existed for a long time but was never
	;       sent by anybody until now.  --JimG 9/13/99
	mov	ax, MSG_NOTIFY_APP_STARTED
	call	GeodeGetProcessHandle
	mov	dx, bx
	clr	bx, si				; bx:si == everyone!
	mov	di, mask MF_RECORD
	call	ObjMessage			; ^hdi = recorded event
	mov	cx, di
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_APPLICATION
	mov	bp, mask GCNLSF_FORCE_QUEUE	; GCNListSendFlags
	call	GCNListSend

	mov	ax, MSG_GEN_SYSTEM_MARK_NOT_BUSY
	call	UserCallSystem
	ret
UI_Attach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTransparentStateFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build state file name for application detached for
		UILM_TRANSPARENT mode.

CALLED BY:	

PASS:		es:di - buffer for transparent state file name
				(must be at least FILE_LONGNAME_BUFFER_LENGTH)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS < LocalDefNLString transparentStateFilePostfix <" (transparent)",0>>
DBCS < LocalDefNLString transparentStateFilePostfix <" (t)",0>		>
TRANSPARENT_STATE_FILE_POSTFIX_LENGTH = (length transparentStateFilePostfix)

GetTransparentStateFileName	proc	far
	uses	ax, bx, cx, ds, si, di
	.enter
.assert (FILE_LONGNAME_BUFFER_SIZE ge ((GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE) + TRANSPARENT_STATE_FILE_POSTFIX_LENGTH))
SBCS <	mov	ax, GGIT_PERM_NAME_AND_EXT				>
DBCS <	mov	ax, GGIT_PERM_NAME_AND_EXT_DBCS				>
	clr	bx				; for current geode
	call	GeodeGetInfo
SBCS <	add	di, GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE		>
DBCS <	add	di, (GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE)*(size wchar)>
	segmov	ds, cs
	mov	si, offset transparentStateFilePostfix
	mov	cx, TRANSPARENT_STATE_FILE_POSTFIX_LENGTH
	LocalCopyNString			;rep movsb/movsw
	.leave
	ret
GetTransparentStateFileName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessCreateUIThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept message to create a new UI thread, for the purpose
		of altering the default stack size -- specifically, up it to
		allow for the recursive nature of UI trees (if the app hasn't
		itself specified a size to use)

CALLED BY:	MSG_PROCESS_CREATE_UI_THREAD
PASS:		es	= kdata
RETURN:		carry clear if thread created
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessCreateUIThread method	GenProcessClass,
					MSG_PROCESS_CREATE_UI_THREAD
	tst	bp
	jnz	haveStackSize

	mov	bp, INTERFACE_THREAD_DEF_STACK_SIZE

haveStackSize:
	mov	di, offset GenProcessClass
	CallSuper	MSG_PROCESS_CREATE_UI_THREAD
	ret
GenProcessCreateUIThread endm


COMMENT @----------------------------------------------------------------------

METHOD:		UI_AttachToPassedStateFile

DESCRIPTION:	Attaches the process to the passed state file, if possible

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax	- MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE
	cx	- AppAttachMode
	dx	- Block handle to block of structure AppLaunchBlock
Return:
	ax 	- handle of extra block of state data (0 for none)
	carry	- set if error

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

AttachToFile {
	Push cur directory
	Change to state file dir

Loop
	IF state file passed in AppLaunchBlock try to open the VM file
	IF error opening VM file {
		create new VM file
	}
	Pop cur directory
	Associate the VM file with the process
}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Moved here from UI_Attach
	atw	9/90		Now don't create new state files until end
------------------------------------------------------------------------------@

UI_AttachToPassedStateFile	method static	GenProcessClass, MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE
	call	FilePushDir	; save current dir
	mov	ax, SP_STATE	;Go to the hot&juicy state directory
	call	FileSetStandardPath
EC <	cmp	cx, MSG_GEN_PROCESS_RESTORE_FROM_STATE			>
EC <	ERROR_NZ STATE_FILE_PASSED_BUT_MODE_WAS_NOT_RESTORE_FROM_STATE	>
				;This should only be called if we are
				; restoring from state

	push	cx		; Save AppAttachBlock, mode for later
	push	dx		;
	push	ds		;

	; Try & open any passed state file

	mov	bx, dx		; Get handle of AppLaunchBlock
	call	MemLock		;

	mov	ds, ax		;
				; Setup ds:dx as filename to open
	mov	dx, offset ALB_appRef.AIR_stateFile

				; Open existing VM file
	mov	ax, (VMO_OPEN shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx		; use standard compaction threshhold
	call	VMOpen		; Go ahead, open it!
	call	FilePopDir
	pop	ds
	mov	dx, bx		;Save VM handle
	pop	bx
	pop	cx
	call	MemUnlock	;Unlock the AppLaunchBlock
	xchg	bx, dx		;BX <- VM handle, DX <- AppLaunchBlock
	jc	error		; Branch if error

				; bx = VM file handle
	; Call the kernel to associate the state file with the current process
	; passing the VM handle in bx

	call	ObjAssocVMFile
	jnc	exit

	clr	al
	call	VMClose			;Close file
	call	FileDelete		;Delete file
error:
	mov	bx, dx
	call	MemLock
	mov	ds, ax
	mov	ds:[ALB_appMode], MSG_GEN_PROCESS_OPEN_APPLICATION
	clr	ax			;No extra state
SBCS <	mov	ds:[ALB_appRef.AIR_stateFile], al	;Nuke statefile name >
DBCS <	mov	ds:[ALB_appRef.AIR_stateFile], ax	;Nuke statefile name >
	call	MemUnlock
	stc
exit:
	ret
	
UI_AttachToPassedStateFile	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveTempGenAppExtraStateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves a state block in temp var data in the app object.  Set
		the temp var data regardless of whether there is a state
		block, as this is also a flag that we're coming back with
		state.

CALLED BY:	INTERNAL
PASS:		cx		- state block, if any
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaveTempGenAppExtraStateBlock	proc	far
	uses	ax, bx, cx, dx, si, di
varDataParams	local	AddVarDataParams
varDataData	local	hptr
	.enter
	mov	varDataData, cx
	mov	varDataParams.AVDP_dataType, TEMP_GEN_APPLICATION_EXTRA_STATE_BLOCK
	mov	varDataParams.AVDP_dataSize, size hptr
	mov	ax, ss
	mov	varDataParams.AVDP_data.segment, ax
	lea	ax, varDataData
	mov	varDataParams.AVDP_data.offset, ax
	mov	dx, size AddVarDataParams
	push	bp
	lea	bp, varDataParams
	clr     bx
	call    GeodeGetAppObject
	mov	ax, MSG_META_ADD_VAR_DATA
	mov     di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage
	pop	bp
	.leave
	ret
SaveTempGenAppExtraStateBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RetrieveTempGenAppExtraStateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieves a state block from temp var data in the app object,
		if any.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		cx		- state block, if any
		carry		- set if VarData entry found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RetrieveTempGenAppExtraStateBlock	proc	far
	uses	ax, bx, dx, si, di
varDataParams local	GetVarDataParams
varDataData	local	hptr
	.enter

	mov	varDataParams.GVDP_dataType, TEMP_GEN_APPLICATION_EXTRA_STATE_BLOCK
	mov	varDataParams.GVDP_bufferSize, size hptr
	mov	ax, ss
	mov	varDataParams.GVDP_buffer.segment, ax
	lea	ax, varDataData
	mov	varDataParams.GVDP_buffer.offset, ax
	mov	dx, size AddVarDataParams
	push	bp
	lea	bp, varDataParams
	clr     bx
	call    GeodeGetAppObject
	mov	ax, MSG_META_GET_VAR_DATA
	mov     di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage
	pop	bp
	mov	cx, varDataData
	cmp	ax, -1		; Test to see if vardata was found
	je	notFound
	stc			; found
exit:

RTGAESB_exit	label near	; Needed for showcalls -a
	ForceRef	RTGAESB_exit

	.leave
	ret

notFound:
	clr	cx		; return 0 for state block if not found
	clc			; not found
	jmp	short exit
RetrieveTempGenAppExtraStateBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyTempGenAppExtraStateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys state block temp var data in the app object, if 
		present.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DestroyTempGenAppExtraStateBlock	proc	far
	uses	ax, cx, dx, bp
	.enter
	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	cx, TEMP_GEN_APPLICATION_EXTRA_STATE_BLOCK
	call	UserCallApplication
	.leave
	ret
DestroyTempGenAppExtraStateBlock	endp



COMMENT @-----------------------------------------------------------------------

METHOD:		UI_CreateNewStateFile

DESCRIPTION:	Either creates a new state file for the process to use, or
	finds one which can/should be used instead of a new one.

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (not dgroup)

	ax	- MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
	dx	- Block handle to block of structure AppLaunchBlock

	CurPath	- Set to state directory

Return:
	ax	- VM file handle (0 if we don't want a state file/couldn't
		  create one).

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

CreateNewStateFile {
	Loop
		Make up a new file name for a state file (8.3, using app's name)
		Try to create a NEW VM file with that name
	} until we have a VM file
}


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Moved here from UI_Attach

-------------------------------------------------------------------------------@

UI_CreateNewStateFile	method static	GenProcessClass, \
					MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
	segmov	es, dgroup, ax
	PSem	es, uiAttachSem		; Create state files just one at a
					; time, to avoid problems w/multiple
					; instances of apps trying to do
					; this at the same time.

	sub	sp, FILE_LONGNAME_BUFFER_SIZE
	mov	di, sp			;ds:si = buffer
	segmov	es, ss

	push	dx			; Save AppLaunchBlock handle for later

	; If doing a transparent detach, use transparent state file name
	;	es:di = buffer for state file name
	;
	; NOTE: we should not check UILM_TRANSPARENT here as we may be
	; running another field by the time this app is exiting

	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	GenCallApplication	; ax = ApplicationStates
;	test	ax, mask AS_TRANSPARENT_DETACHING
;instead of check AS_TRANSPARENT_DETACHING, check the new AS_TRANSPARENT as
;we want to use transparent state file even if running DOS app or exiting to
;DOS - brianc 6/16/93
	test	ax, mask AS_TRANSPARENT
	jz	normalStateFile
	call	GetTransparentStateFileName
	segmov	ds, es			; ds:dx = name
	mov	dx, di
	mov	si, di			; ds:si = name
					; create new or truncate existing
	mov	ax, (VMO_CREATE_TRUNCATE shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx		; Use standard compaction threshhold
	call	VMOpen
	LONG jnc	ATSF_creationOK		; success
					; If out of disk space, we're 
					; completely hosed.  Crash & burn.
					; (GeodeLoad is supposed to try & make
					; sure this doesn't happen)
	mov	si, offset outOfDiskSpaceStr1
	mov	di, offset outOfDiskSpaceStr2
	cmp	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
	LONG je	exitWithError
	jmp	generalFileError

normalStateFile:

	; Get the file's permanent name and use that as the starting source
	; of the state file, by changing the last 2 positions to be a #,
	; & then adding '.sta' to the end.

	clr	bx			; Get name for current process
SBCS <	mov	ax, GGIT_PERM_NAME_AND_EXT				>
DBCS <	mov	ax, GGIT_PERM_NAME_AND_EXT_DBCS				>
	call	GeodeGetInfo
	segmov	ds, es
	mov	si, di

	push	si
	mov	cx, GEODE_NAME_SIZE
FindEnd:
	LocalGetChar ax, dssi
	LocalCmpChar ax, ' '
	je	EndFound
	LocalCmpChar ax, '.'
	je	EndFound
	LocalCmpChar ax, '0'
	je	EndFound
	loop	FindEnd
	jmp	short	ValidName

EndFound:
	LocalPrevChar dssi
extendLoop:
SBCS <	mov	byte ptr ds:[si],'_'	; legitimize char, to stretch name >
DBCS <	mov	{wchar}ds:[si],'_'	; legitimize char, to stretch name >
	LocalNextChar dssi
	loop	extendLoop		; for each char left in core length,
					; make it valid
ValidName:
	pop	si
					; Start with ending chars of "00.sta"
if DBCS_PCGEOS
	mov	{wchar}ds:[si+GEODE_NAME_SIZE*2], '.'
	mov	{wchar}ds:[si+GEODE_NAME_SIZE*2+2], 's'
	mov	{wchar}ds:[si+GEODE_NAME_SIZE*2+4], 't'
	mov	{wchar}ds:[si+GEODE_NAME_SIZE*2+6], 'a'
	mov	{wchar}ds:[si+GEODE_NAME_SIZE*2-4], '0'
ATSF_TryCreateNextDecade:
	mov	{wchar}ds:[si+GEODE_NAME_SIZE*2-2], '0'
ATSF_TryCreate:
				; Null terminate this sucker.
	mov	{wchar}ds:[si+GEODE_NAME_SIZE*2+8], 0
else
	mov	word ptr ds:[si+GEODE_NAME_SIZE], '.' or ('s' shl 8)
	mov	word ptr ds:[si+GEODE_NAME_SIZE+2], 't' or ('a' shl 8)
	mov	byte ptr ds:[si+GEODE_NAME_SIZE-2], '0'
ATSF_TryCreateNextDecade:
	mov	byte ptr ds:[si+GEODE_NAME_SIZE-1], '0'
ATSF_TryCreate:
				; Null terminate this sucker.
	mov	byte ptr ds:[si+GEODE_NAME_SIZE+4], 0
endif

	mov	ax, (VMO_CREATE_ONLY shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE

	clr	cx		; Use standard compaction threshhold
	mov	dx,si		; Setup ds:dx as pointer
	call	VMOpen		; Go ahead, open it!

	jnc	ATSF_creationOK

	cmp	ax, VM_SHARING_DENIED	; If somebody else using, try again
	je	ATSF_TryNext

	cmp	ax, VM_FILE_EXISTS	; See if because file already exists
	je	fileExists		; if so, branch & try another name

					; If out of disk space, we're 
					; completely hosed.  Crash & burn.
					; (GeodeLoad is supposed to try & make
					; sure this doesn't happen)
	mov	si, offset outOfDiskSpaceStr1
	mov	di, offset outOfDiskSpaceStr2
	cmp	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
	je	exitWithError
	jmp	generalFileError

fileExists:
	call	DeleteIfBadStateFile	; Let's do a little cleanup work here.
					; We can't use this file, because
					; it already exists.  However,
					; we can see whether it is a valid
					; state file or not, & if not, 
					; trash it, to clean up the state
					; directory.

ATSF_TryNext:
				; INC tail end # of filename
if DBCS_PCGEOS
	inc	{wchar}ds:[si+GEODE_NAME_SIZE*2-2]
	cmp	{wchar}ds:[si+GEODE_NAME_SIZE*2-2], '9'+1
	jb	ATSF_TryCreate
	inc	{wchar}ds:[si+GEODE_NAME_SIZE*2-4]
	cmp	{wchar}ds:[si+GEODE_NAME_SIZE*2-4], '9'+1
	jb	ATSF_TryCreateNextDecade
else
	inc	byte ptr ds:[si+GEODE_NAME_SIZE-1]
	cmp	byte ptr ds:[si+GEODE_NAME_SIZE-1], '9'+1
	jb	ATSF_TryCreate
	inc	byte ptr ds:[si+GEODE_NAME_SIZE-2]
	cmp	byte ptr ds:[si+GEODE_NAME_SIZE-2], '9'+1
	jb	ATSF_TryCreateNextDecade
endif

					; ACK!  100 attempts & no file!
generalFileError:
					; If other error, also crash & burn,
					; but w/general error message

	mov	si, offset cannotCreateFileStr1
	mov	di, offset cannotCreateFileStr2		;No second string
	call	UserCheckIfPDA
	jnc	exitWithError		; not PDA, use this error
	mov	di, offset cannotCreateFileStr2PDA	; else, this one
exitWithError:
	mov	bx, handle outOfDiskSpaceStr1
	call	MemLock	;Lock the strings resource
	mov	ds, ax			;DS:SI <- string to display
	mov	si, ds:[si]
	mov	di, ds:[di]
	mov	ax, mask SNF_CONTINUE
	call	SysNotify
	call	MemUnlock		;Unlock the strings resource
skipStateFile::
	pop	dx			;Restore handle of AppInstanceReference
	add	sp, FILE_LONGNAME_BUFFER_SIZE
	clr	ax			;No state file
	jmp	short done

ATSF_creationOK:
	mov	dx, bx		; Keep VM file handle in dx for a moment

				; Copy state file name into AppLaunchBlock
	pop	bx		; Get handle of AppLaunchBlock
	call	MemLock
	push	bx
	mov	es, ax
				; ds:si is file created
				; Set es:di to state file name stored
				; in AppInstanceReference
	mov	di, offset AIR_stateFile
	mov	cx, length AIR_stateFile
	LocalCopyNString	; rep movsb/movsw

	pop	bx
	call	MemUnlock

				; Fix stack
	add	sp, FILE_LONGNAME_BUFFER_SIZE

	xchg	ax, dx		; return VM file handle in ax

done:
	mov	bx, seg idata
	mov	es, bx
	VSem	es, uiAttachSem	; & release semaphore -- let others create
				; state files.
	ret


UI_CreateNewStateFile	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteIfBadStateFile

DESCRIPTION:	Delete the file passed if it is not a good state file

CALLED BY:	INTERNAL

PASS:
	ds:si	- pointer to null-terminated filename string
	(ds:si *cannot* be pointing into the movable XIP resource.)

RETURN:
	Nothing

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version
------------------------------------------------------------------------------@

DeleteIfBadStateFile	proc	near
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
		
	mov	dx, si		; Setup ds:dx as pointer to filename
	mov	ax, (VMO_OPEN shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx		; Use standard compaction threshhold
	call	VMOpen		; Go ahead, open it!
	jnc	OpenedOK	; branch if successful, file is OK
				; If file not found, just quit
	cmp	ax, VM_FILE_NOT_FOUND
	je	Quit
	call	FileDelete	; If any error in opening delete the file,
				; it is not good as a state file
				; (Includes invalid VM file error)
				; & Ignore any error flags returned from
				; FileDelete - what do we care?
	jmp	short Quit

OpenedOK:
	clr	al
	call	VMClose		; just close it & return
Quit:
	ret
DeleteIfBadStateFile	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_LarusApplication

DESCRIPTION:

	This is sent to the process itself from the application object,
	when it has determined that the app should lazarus, i.e. return
	to app mode.

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax 	- MSG_GEN_PROCESS_TRANSITION_FROM_ENGINE_TO_APPLICATION_MODE
	cx	- AppAttachFlags
	dx	- Handle of AppLaunchBlock, or 0 if none.
		  This block contains the name of any document file passed
		  into the application on invocation.

RETURN:
	Nothing
	AppLaunchBlock	- preserved

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/93		Initial version

-------------------------------------------------------------------------------@
UI_LazarusApplication	method	GenProcessClass,
		MSG_GEN_PROCESS_TRANSITION_FROM_ENGINE_TO_APPLICATION_MODE

	; Fetch extra state block, which at this point is just stored at the
	; app object.
	;
	push	cx
	call	RetrieveTempGenAppExtraStateBlock
	pushf
	call	DestroyTempGenAppExtraStateBlock
	popf
	mov	bp, cx			; bp <- extra state block
	pop	cx
	jnc	afterState		; carry clear if vardata entry not
					; found, meaning there's no state.
	; If it is found, set "restoring from state flag" because we're coming
	; back with state, so to speak. This keeps the app as much
	; like it was as possible, keeping it from re-loading options, &
	; re-starting windows, etc.
	;
	ornf	cx, mask AAF_RESTORING_FROM_STATE
afterState:

	; Find out if we were in the process of quitting before this happened.
	; 
	push	cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	UserCallApplication
	pop	cx, dx, bp
	test	ax, mask AS_QUITTING
	jz	afterQuitting

	; If we're coming back from a quit, record this fact by setting
	; AAF_RESTORING_FROM_QUIT -- despite coming back with the UI in
	; whatever state it happens to be in, the act of QUITTING itself 
	; reverts some UI to is virgin state -- such as is the case with
	; document control & open documents -- after a QUIT, there are no
	; open documents.  The document control therefore responds to this
	; bit being set by starting up documents just as it would were
	; this a fresh launch.
	;
	ornf	cx, mask AAF_RESTORING_FROM_QUIT
afterQuitting:

	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL
	push	bp
	call	ObjMessage
	pop	bx			; NUKE the extra state block
	tst	bx
	jz	afterStateBlockNuked
	call	MemFree
afterStateBlockNuked:

	ret
UI_LazarusApplication	endm
		


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_OpenApplication

DESCRIPTION:

	This is sent to the process itself from MSG_META_ATTACH, whenever the
	application is being restored to mode APPLICATION, or whenever it is
	being invoked as in APPLICATION mode.  Data passed is the same as
	that in MSG_META_ATTACH.  The default handler sets the application
	object USABLE.  This method may be intercepted to open up any data
	file passed, before the UI for the application is actually set USABLE.
	Note that the blocks passed need not be freed, as this is done by the
	caller upon return of this routine.

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax - MSG_GEN_PROCESS_OPEN_APPLICATION

	cx	- AppAttachFlags
	dx	- Handle of AppLaunchBlock, or 0 if none.
		  This block contains the name of any document file passed
		  into the application on invocation.
	bp	- Handle of extra state block, or 0 if none.
		  This is the same block as returned from
		  MSG_GET_STATE_TO_SAVE, in some previous MSG_META_DETACH

RETURN:
	Nothing
	AppLaunchBlock	- preserved
	extra stae block - preserved

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

-------------------------------------------------------------------------------@


UI_OpenApplication	method	GenProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION

	push	cx
	push	dx
	push	bp

				; Get OD of app object in ^lbx:si
	clr	bx
	call	GeodeGetAppObject

				; Store application mode in use in app obj
	mov	cx, MSG_GEN_PROCESS_OPEN_APPLICATION
	mov	ax, MSG_GEN_APPLICATION_SET_APP_MODE_MESSAGE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	bp
	pop	dx
	pop	cx
				; ATTACH application object
	mov	ax, MSG_META_ATTACH
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

UI_OpenApplication	endm



COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_RestoreFromState

DESCRIPTION:

	This is sent to the process itself from MSG_META_ATTACH, whenever the
	application is being restored to mode RESTORE_FROM_STATE
	Data passed is the same as that in MSG_META_ATTACH.
	The default handler fetches the app state mode method stored
	in the application object & sends it to the process

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax - MSG_GEN_PROCESS_RESTORE_FROM_STATE

	cx	- AppAttachFlags

	dx	- Handle of AppLaunchBlock, or 0 if none.
		  This block contains the name of any document file passed
		  into the application on invocation.
	bp	- Handle of extra state block, or 0 if none.
		  This is the same block as returned from
		  MSG_GEN_PROCESS_CLOSE_APPLICATION
		  in some previous MSG_META_DETACH
		     
RETURN:
	Nothing
	AppLaunchBlock	- preserved
	extra stae block - preserved

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

-------------------------------------------------------------------------------@


UI_RestoreFromState	method	GenProcessClass, MSG_GEN_PROCESS_RESTORE_FROM_STATE

	push	dx, bp, cx

				; Fetch method from app object
	clr	bx
	call	GeodeGetAppObject

	mov	ax, MSG_GEN_APPLICATION_GET_APP_MODE_MESSAGE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jcxz	stateFileWasBad

haveMessage:
				;Set bit in app object to say that we are 
				; attached to a state file.
	push	cx
	mov	ax, MSG_GEN_APPLICATION_SET_ATTACHED_TO_STATE_FILE
	clr	di
	call	ObjMessage	

	pop	ax		; put the mode method in ax
	pop	dx, bp, cx	;Restore AppAttachFlags	

	; The extra state block is now the realm of OPEN_APPLICATION only.
	; If we're about to call anything else, save off the extra state
	; block & pass 0 here.	-- Doug 5/14/93
	;
	cmp	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	je	goAhead
	push	cx
	mov	cx, bp
	call	SaveTempGenAppExtraStateBlock	; Save it in app obj
	clr	bp				; Pass NULL here, just in 
						; case old code looks at it.
	pop	cx
goAhead:
				; Change AppAttachFlags to show what is
				; going on.
	ornf	cx, mask AAF_RESTORING_FROM_STATE
				; Send the attach mode method to the process
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

stateFileWasBad:
	;
	; App mode saved in app object is 0, meaning we may have attached to
	; a state file, but for some reason it didn't have state for the
	; app object (user may have rebooted inopportunely), so assume
	; OPEN_APPLICATION
	; 
	mov	cx, MSG_GEN_PROCESS_OPEN_APPLICATION
	jmp	haveMessage
UI_RestoreFromState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UI_GetParentField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the parent field of the associated app object

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		CX:DX <- optr of parent field
DESTROYED:	ax, bx, bp, di, si
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UI_GetParentField	method	GenProcessClass, MSG_GEN_PROCESS_GET_PARENT_FIELD
	clr	bx
	call	GeodeGetAppObject		;^lBX:SI <- app object
	mov	ax, MSG_GEN_FIND_PARENT	;Get the parent of the app obj
	mov	di, mask MF_CALL		;
	GOTO	ObjMessage			;
UI_GetParentField	endm

AppAttach ends

TokenUncommon segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_OpenEngine

DESCRIPTION:

	This is sent to the process itself from MSG_META_ATTACH, whenever the
	application is being restored to mode ENGINE, or whenever it is
	being invoked as in ENGINE mode.  Data passed is the same as
	that in MSG_META_ATTACH.  The default handler only stores the ENGINE
	mode in the app object.  This method may be intercepted to open up
	any data file passed, before engine operations commence.
	Note that the blocks passed need not be freed, as this is done by the
	caller upon return of this routine.

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax - MSG_GEN_PROCESS_OPEN_ENGINE

	cx	- AppAttachFlags:
	dx	- Handle of AppLaunchBlock, or 0 if none.
		  This block contains the name of any document file passed
		  into the application on invocation.
RETURN:
	Nothing
	AppLaunchBlock	- preserved
	extra stae block - preserved

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

-------------------------------------------------------------------------------@


UI_OpenEngine	method	GenProcessClass, MSG_GEN_PROCESS_OPEN_ENGINE

				; Get OD of app object in ^lbx:si
	clr	bx
	call	GeodeGetAppObject

				; Store application mode in use in app obj
	mov	cx, MSG_GEN_PROCESS_OPEN_ENGINE
	mov	ax, MSG_GEN_APPLICATION_SET_APP_MODE_MESSAGE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

UI_OpenEngine	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_InstallToken -- MSG_GEN_PROCESS_INSTALL_TOKEN for GenProcessClass

DESCRIPTION:	Add token and moniker list to token database

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax - method

	cx - ?
	dx - ?
	bp - ?
	si - ?

RETURN:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/19/89	Initial version

-------------------------------------------------------------------------------@
UI_InstallToken	method	GenProcessClass, MSG_GEN_PROCESS_INSTALL_TOKEN

				; Get OD of app object in ^lbx:si
	clr	bx
	call	GeodeGetAppObject

				; just do it
	mov	ax, MSG_GEN_APPLICATION_INSTALL_TOKEN
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

UI_InstallToken	endm

TokenUncommon ends


AppDetach segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_Detach -- MSG_META_DETACH for GenProcessClass

DESCRIPTION:	Detach the process

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax - method

	cx	- ? (MSG_META_ACK sent to caller will have cx = error code)
	dx:bp	- ackOD (May be the GenField, or possibly the app itself,
				or who knows?)
	si - ?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	12/89		Revised detach methodology

-------------------------------------------------------------------------------@

UI_Detach	method	GenProcessClass, MSG_META_DETACH

	
	; Add ourselves to the list of detaching processes, so the kernel
	; can speed up our demise if necessary, by changing thread priorities.
	;
	segmov	es, dgroup, bx
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	jne	afterTransparentDetachStuff
	push	ax, dx, bp
	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_IN_PROGRESS
	call	GCNListAdd
	pop	ax, dx, bp
afterTransparentDetachStuff:

	mov	cx, dx			; Keep original app-killer's OD
					; in cx:bp, so that we will have it
					; in MSG_META_ACK later

					; Detach the object world, & wait for
					; an ACK
	call	GeodeGetProcessHandle
	mov	dx, bx					; dx = process handle
							; for ACK, cx:bp 
							; actually contains OD
							; of original app-killer
							; We lose its word of
							; data, though.
	clr	bx
	call	GeodeGetAppObject

	; Pass MSG_META_DETACH on to application object. We'll continue our
	; detach when receive MSG_META_ACK back from the application object.
	;
	mov	di, mask MF_CALL
	GOTO	ObjMessage		;send it to the UI

UI_Detach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessCreateStateFileIfAppropriate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and attach to a state file for the process if we need
		one.

CALLED BY:	UI_Ack
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	state file created and associated with the process if
     			not quitting and didn't have a state file already.
		pre-existing state file closed and deleted if quitting.

PSEUDO CODE/STRATEGY:
		since there are two bits (quitting and attached-to-state-file)
		    there are four cases:
		    1) quitting, but already attached to a state file
		    2) not quitting, and already attached to a state file
		    3) quitting, and have no state file
		    4) not quitting, and have no state file
		only cases 1 and 4 require any work here:

		fetch application state
		if quitting && attached to state file (case 1):
			- close state file
			- delete it
		else if !quitting && !attached to state file (case 4):
			- create state file
			- if actually created, associate with it and
			  set the attached_to_state_file state of the app obj

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessCreateStateFileIfAppropriate proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter
		clr	bx
		call	GeodeGetAppObject
		mov	ax, MSG_GEN_APPLICATION_GET_STATE
		mov	di, mask MF_CALL
		call	ObjMessage		; ax <- ApplicationStates
		
		test	al, mask AS_QUITTING or mask AS_ATTACHED_TO_STATE_FILE
		jz	createStateFile		; => neither
			CheckHack <offset AS_QUITTING lt 8 and \
				   offset AS_ATTACHED_TO_STATE_FILE lt 8>
		jpe	nukeExistingStateFile	; => both
	;
	; else either quitting and not attached (no need for state file), or
	; not quitting and attached (no need to nuke or create state file),
	; so we have nothing else to do.
	;
done:
		.leave
		ret

	;--------------------
	;
	; Not quitting and don't have a state file yet: create one and attach
	; to it.
	; 
createStateFile:
	;
	; Get handle of current AppInstanceReference
	; 
		mov	ax, MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Call ourselves to create a new state file, storing its name in the
	; AppInstanceReference structure.
	; 
		call	FilePushDir
		mov	ax, SP_STATE
		call	FileSetStandardPath
		call	GeodeGetProcessHandle
		mov	ax, MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		mov	di, mask MF_CALL
		push	dx			; save AppRef handle
		call	ObjMessage		; ax <- file handle or 0
		pop	dx
		call	FilePopDir
		tst	ax
		jz	freeAppRef		;=> wants no state file
	;
	; Associate the state file with this process.
	; 
		mov_tr	bx, ax
		call	ObjAssocVMFile
		jc	closeFileFreeAppRef	; => error during assoc
		mov	cx, ax				; Extra block in cx (0)
		call	SaveTempGenAppExtraStateBlock	; Save it in app obj
	;
	; Set the modified AppInstanceReference, now with state file name, as
	; the one the app object should send to the field when instructed.
	; 
		clr	bx
		call	GeodeGetAppObject
		mov	ax, MSG_GEN_APPLICATION_SET_APP_INSTANCE_REFERENCE
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Tell the application object it's now attached to a state file.
	; 
		mov	ax, MSG_GEN_APPLICATION_SET_ATTACHED_TO_STATE_FILE
		clr	di
		call	ObjMessage
		jmp	done

closeFileFreeAppRef:
		clr	al
		call	VMClose
freeAppRef:
		mov	bx, dx
		call	MemFree
		jmp	done

	;--------------------
	;
	; Quitting and are attached to state file: close it and nuke it.
	; 
nukeExistingStateFile:
		mov	ax, MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE
		mov	di, mask MF_CALL
		call	ObjMessage		; dx <- AIR block
		
		call	ObjCloseVMFile

		push	bx, ds
		mov	bx, dx
		call	MemLock
		mov	ds, ax
	;
	; Push to SP_STATE, where the state file must be
	; 
		call	FilePushDir
		mov	ax, SP_STATE
		call	FileSetStandardPath
	;
	; Nuke it.
	; 
		mov	dx, offset AIR_stateFile
		call	FileDelete
		call	FilePopDir
	;
	; Clear AIR_stateFile[0] and set as new AIR, just to be safe (frees AIR
	; block, too).
	; 
		mov	ds:[AIR_stateFile][0], 0
		call	MemUnlock
		pop	bx, ds
		mov	ax, MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE
		clr	di
		call	ObjMessage
	;
	; Make sure app obj knows we're not attached to a state file any more.
	; 
		mov	ax, MSG_GEN_APPLICATION_SET_NOT_ATTACHED_TO_STATE_FILE
		mov	di, mask MF_CALL
		call	ObjMessage
		jmp	done
GenProcessCreateStateFileIfAppropriate endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_Ack -- MSG_META_ACK for GenProcessClass

DESCRIPTION:	Handle acknowledge that the object world for this application
		has been shut down.

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax - method

	cx:si	- OD of original ackOD sent to MSG_META_DETACH
	dx:bp	- object from with the MSG_META_ACK is coming from (app object)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	12/89		Revised detach methodology

-------------------------------------------------------------------------------@
UI_Ack	method	GenProcessClass, MSG_META_ACK

	; Check to see if ACK coming from App object
	;
	push	si
	clr	bx
	call	GeodeGetAppObject
	cmp	bp, si
	pop	si
	jne	notAppObject
	cmp	dx, bx
	je	ackFromAppObject	; branch if so
notAppObject:

	; Otherwise, we must assume it was UI thread notifying us of its demise.
	; (It is dangerous to compare free handles, & in any case, we don't
	; have any copy around to compare with)
	;
					; Do FINAL_DETACH again, but this time
					; w/ui thread dead, so it will continue.
	mov	dx, cx			; get Ack OD into dx:bp
	mov	bp, si
	call	GeodeGetProcessHandle
	mov	ax, MSG_GEN_PROCESS_FINAL_DETACH
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage


ackFromAppObject:
	; If we get here, then the it means we've just finished a 
	; MSG_META_DETACH sequence on the GenApplication object, meaning the
	; entire UI tree has now been detached.  We respond to this by
	; continuing the detach, first sending the appropriate CLOSE message
	; to the process, both as notification & to get any extra state 
	; block, then by letting the app know that the whole CLOSE sequence
	; is complete, & we're back in engine mode (if we weren't already
	; there).  In any case, it is then free to start a REAL_DETACH the
	; moment there isn't some other IACP reason to hang around.
	;
	push	cx		; preserve OD to send ack to
	push	si


	; create and attach to a state file *now* so the close method can
	; use ObjMapSavedToState to keep track of duplicated blocks if it
	; needs to.

	call	GenProcessCreateStateFileIfAppropriate

	; Send MSG_GEN_PROCESS_CLOSE_APPLICATION now, if in app mode.  (If in
	; engine or custom mode, the CLOSE message is sent in REAL_DETACH)
	;
	; Test to see if closing from app mode (need to deal w/extra state block
	; in that case, but not others)
	;
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_GEN_APPLICATION_GET_APP_MODE_MESSAGE
	mov	di, mask MF_CALL
	call	ObjMessage			;returns cx = mode method
	cmp	cx, MSG_GEN_PROCESS_OPEN_APPLICATION
	jne	afterAppMode

	; Get application process's state to save
	;
	mov	ax, MSG_GEN_PROCESS_CLOSE_APPLICATION
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL
	call	ObjMessage		; Returns cx = extra state block

	; Save it away where we can get at it later
	; 
	call	SaveTempGenAppExtraStateBlock

afterAppMode:

	pop	bp			; Restore OD of original app-killer 
	pop	dx			; into dx:bp

	; We're done closing.  Send CLOSE_COMPLETE notification back to 
	; application, which will fix up bits to indicate we're no longer in
	; app mode, then call MSG_GEN_APPLICATION_APP_MODE_COMPLETE to figure
	; out where to go from there.
	;
	mov	ax, MSG_GEN_APPLICATION_CLOSE_COMPLETE
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_CALL
	GOTO	ObjMessage

UI_Ack	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_GetStateToSave

DESCRIPTION:	Default handler for methods requesting block to save
		with state file.  Returns 0 for none.

		Actually, state may now only be returned from
		MSG_GEN_PROCESS_CLOSE_APPLICATION.  We continue to handle
		all these & return 0, just for backwards compatibility.

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax - MSG_GEN_PROCESS_CLOSE_APPLICATION, MSG_GEN_PROCESS_CLOSE_ENGINE
	     or MSG_GEN_PROCESS_CLOSE_CUSTOM

RETURN:
	cx - handle

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	1/90		Switched to be handler for CLOSE_APP

-------------------------------------------------------------------------------@

UI_GetStateToSave	method	GenProcessClass, MSG_GEN_PROCESS_CLOSE_APPLICATION, MSG_GEN_PROCESS_CLOSE_ENGINE, MSG_GEN_PROCESS_CLOSE_CUSTOM
	clr	cx
	ret

UI_GetStateToSave	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_UIRealDetach -- MSG_GEN_PROCESS_REAL_DETACH for GenProcessClass

DESCRIPTION:	Really detach the process

PASS:
	ds - dgroup of the current process
	es - segment of GenProcessClass (UI's dgroup)

	ax - method

	dx:bp	- original ackOD sent to MSG_META_DETACH
	si 	- ?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

-------------------------------------------------------------------------------@

UI_UIRealDetach	method	GenProcessClass, MSG_GEN_PROCESS_REAL_DETACH

	push	dx,bp			;Save ACK OD

	;
	; If running in ENGINE mode or CUSTOM mode, send the CLOSE_ENGINE or
	; CLOSE_CUSTOM.  (CLOSE_APPLICATION is handled back in our MSG_META_ACK
	; handler, not here, as the CLOSE needs to happen even if hanging
	; around for iacp or if lazarusing, neither of which result in
	; this message being called, as the process isn't really going way)
	;
	mov	ax, MSG_GEN_APPLICATION_GET_APP_MODE_MESSAGE
	call	GenCallApplication	;cx = mode message
	cmp	cx, MSG_GEN_PROCESS_OPEN_APPLICATION
	je	noCloseMethod		;app mode, CLOSE_APP already sent
	mov	ax, MSG_GEN_PROCESS_CLOSE_ENGINE
	cmp	cx, MSG_GEN_PROCESS_OPEN_ENGINE
	je	haveCloseMethod
	mov	ax, MSG_GEN_PROCESS_CLOSE_CUSTOM
haveCloseMethod:
	call	GeodeGetProcessHandle
	mov	di, mask MF_CALL
	call	ObjMessage
noCloseMethod:

	;
	; Find out if we're quitting.
	; 
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	GenCallApplication	;Returns ax <- app mode bits
	
	;
	; If not quitting and if not doing a transparent detach, send info
	; about ourselves and our state file to the field on which we sit,
	; so it can restart us.
	;
	test	ax, mask AS_QUITTING or mask AS_TRANSPARENT_DETACHING
	jnz	shutdownApp

	mov	ax, MSG_GEN_APPLICATION_SEND_APP_INSTANCE_REFERENCE_TO_FIELD
	call	GenCallApplication

shutdownApp:
	;
	; Tell the app object to shut itself down, disconnecting from the
	; field, etc. This will send us a MSG_META_SHUTDOWN_ACK when it's
	; done, and we'll take it from there...
	; 
	mov	ax, MSG_META_APP_SHUTDOWN
	call	GeodeGetProcessHandle
	mov	dx, bx
	pop	cx, bp			;send ^lcx:si back to us in SHUTDOWN_ACK
					; as ACK od for our own detach
	GOTO	GenCallApplication

UI_UIRealDetach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenProcessShutdownAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field acknowledgement that the application object has
		shut down (and unlinked itself from the field) and use
		it to continue our own exit.

CALLED BY:	MSG_META_SHUTDOWN_ACK
PASS:		ds 	= dgroup
		^lcx:si	= ack OD
		^ldx:bp	= object send ack back to us
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenProcessShutdownAck method dynamic GenProcessClass, MSG_META_SHUTDOWN_ACK

	push	cx, si

	;
	; Get application state before we shunt the beast into a state file.
	; 
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	GenCallApplication	; ax <- ApplicationStates
	push	ax

	;
	; Detach from any state file to which we're attached.
	; 
	call	RetrieveTempGenAppExtraStateBlock	; First get state block
	call	DestroyTempGenAppExtraStateBlock
	call	ObjSaveExtraStateBlock			; & save it
	call	ObjDisassocVMFile

	;
	; Now that we've sent the app object to the state file, we can't
	; flush through it anymore, so set the input object to be the
	; process.
	;
	call	GeodeGetProcessHandle
	mov	cx, bx			; bx = cx = process handle
	clr	dx
	call	WinGeodeSetInputObj
	pop	dx			; dx = ApplicationStates

	pop	cx,si			;CX:SI <- ack OD

	;
	; If quitting, sequencing is being handled by MSG_META_QUIT_ACK
	; mechanism, so just "ACK" the completion of UI DETACH at this
	; time.  It will shortly thereafter call MSG_GEN_PROCESS_FINAL_DETACH
	; itself.
	; 

	test	dx, mask AS_QUITTING	;Are we quitting?
	mov	dx, QL_DETACH		;Ack this level of quit
	mov	ax, MSG_META_QUIT_ACK	;
	jne	common
					; Otherwise, do FINAL_DETACH directly
					; from here.
	mov	dx, cx			; get Ack OD into dx:bp
	mov	bp, si
	mov	ax, MSG_GEN_PROCESS_FINAL_DETACH

common:
	; Flush full input queue before starting to nuke things.
	;
	call	GeodeGetProcessHandle	;Get bx = handle of this process obj
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			; Pass Event in cx
	mov	dx, bx			; handle of block in dx
	clr	bp			; Init next stop
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	clr	di
	GOTO	ObjMessage		; Call self to start flush
GenProcessShutdownAck endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CleanupUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanup the undo blocks, etc.

CALLED BY:	GLOBAL
PASS:		es - dgroup
RETURN:		nada
DESTROYED:	ax, cx, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CleanupUndo	proc	near	uses	ds,dx,bp, bx
	.enter

EC <	push	ax, bx							>
EC <	mov	bx, es							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
EC <	pop	ax, bx							>

;	Get the handle of the undo block

	clr	bx
	mov	di, es:[undoOffset]
	mov	cx, 1
	sub	sp, 2
	mov	si, sp			;DS:SI <- ptr to place to read
	segmov	ds, ss			; handle of undo block
	call	GeodePrivRead
	pop	bx			;BX <- value read
	tst	bx			;If no undo block, just exit
	jz	exit

EC <	call	MemLock							>
EC <	mov	ds, ax							>
EC <	tst	ds:[ULMBH_startCount]					>
EC <	ERROR_NZ	UNDO_START_COUNT_NON_ZERO_WHEN_PROCESS_EXITED	>

EC <	tst	ds:[ULMBH_ignoreCount]					>
EC <	ERROR_NZ	UNDO_IGNORE_COUNT_NON_ZERO_WHEN_PROCESS_EXITED	>

	call	MemFree			;Free up the undo block
exit:
	.leave
	ret
CleanupUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UI_UIFinalDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finishes up the detach process.

CALLED BY:	GLOBAL
PASS:		DX:BP <- ACK OD
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UI_UIFinalDetach	method	GenProcessClass, MSG_GEN_PROCESS_FINAL_DETACH


	; If we still have a UI thread, embark on a detour to DESTROY it now.
	; We'll get a MSG_META_ACK once that has occured, at which point we'll
	; resume our own destruction.
	;
	call	GeodeGetProcessHandle
	push	ds
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[PH_uiThread]
	call	MemUnlock
	pop	ds
	tst	ax
	jz	afterUIThreadDetached

						; dx = process handle
						; for ACK, cx:bp 
						; actually contains OD
						; of original app-killer
	push	dx, bp
	mov	cx, dx				; pass CX:BP = orig ACK OD, as
						; expected by our ACK handler
	mov	dx, bx				; setup DX ACK OD = this proc
	mov	bx, ax				; send message to uiThread
	clr	si				; nothing interesting in si
	mov	ax, MSG_META_DETACH
	clr	di
	call	ObjMessage
	pop	dx, bp
	jmp	short done

afterUIThreadDetached:

	push	es
	segmov	es, dgroup, cx			; SH
	call	CleanupUndo
	pop	es

	clr	cx				; set exit code = 0
	clr	si

	; This is the point where we finally ask ProcessClass to nuke the 
	; process.  There's one exception to the desire to do this:  If the
	; process under the gun just happens to be the UI library's process.
	; In this case only, ACK the detach as being complete, but don't 
	; actually nuke the process;  this is taken care of only after the
	; whole system as a whole has been completely shut down.  (See
	; UserClass for details)
	;
	cmp	bx, handle 0
	jne	notUIProcess

	mov	ax, MSG_META_ACK
	xchg	bx, dx			; get ^lbx:si = OD to send ACK to,
	xchg	si, bp			; dx = process which is ACK'ing, bp=0
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	short done

notUIProcess:

	; OK, at the very last moment that we can, take ourselves off the
	; "detaching" GCN list, before the geode itself is nuked from memory
	; & the GCN list points at garbage.
	;
	call	TakeOffTransparentDetachInProgressList

	; DO NOT send MSG_META_ACK to the superclass, since MetaClass will
	; try & handle this as if we'd called ObjInitDetach, which we HAVE NOT.
	; Instead, send MSG_META_DETACH to our superclass, "ProcessClass,"
	; which we didn't do earlier.  ProcessClass will send the
	; MSG_META_ACK for us.

	mov	di, offset GenProcessClass
	mov	ax, MSG_META_DETACH		;pass method
	CallSuper	MSG_META_DETACH
done:
	ret
UI_UIFinalDetach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TakeOffTransparentDetachInProgressList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take geode off the GCNSLT_TRANSPARENT_DETACH_IN_PROGRESS if
		we're still on it.

CALLED BY:	INTERNAL
		UI_UIFinalDetach
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TakeOffTransparentDetachInProgressList	proc	near
	uses	ax, bx, cx, dx, es
	.enter
	;
        ; If on a system using transparent detach, we need to take the
        ; geode off the GCN list being kept for this person.
	;
	segmov	es, dgroup, ax
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	jne	exit


	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_IN_PROGRESS
	call	GCNListRemove

exit:
	.leave
	ret
TakeOffTransparentDetachInProgressList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UI_Quit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler gets the appropriate QuitLevel enum passed
		in DX. The method handler for each level of quit should then
		send MSG_META_QUIT_ACK with the same QuitLevel when it is done.
		See the declaration of QuitLevel for more info

CALLED BY:	GLOBAL
PASS:		dx - QuitLevel
		bp - data (possibly?)
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UI_Quit	method	GenProcessClass, MSG_META_QUIT
EC <	cmp	dx, QuitLevel						>
EC <	ERROR_AE UI_PROCESS_INVALID_QUIT_LEVEL				>
	mov	di,dx
	shl	di,1
	call	cs:[QuitRoutines][di]
	ret
UI_Quit	endm

QuitRoutines	nptr	QuitAck		; QL_BEFORE_UI -> Just ack the method
		nptr	QuitUI		; QL_UI -> 	Send quit off to the UI
		nptr	QuitAfterUI	; QL_AFTER_UI -> Check w/app obj
		nptr	QuitDetach	; QL_DETACH -> 	Detach process
		nptr	QuitAfterDetach	; QL_AFTER_DETACH -> Finish your ack


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UI_QuitAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the next level of MSG_META_QUIT off to the process.

CALLED BY:	GLOBAL
PASS:		cx - abort flag (non-zero if aborting)
			- or (if quit level is QL_DETACH or later -
		cx:si - OD for detach ack later
		bp - data to pass to next level of quit
		dx - current quit level
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UI_QuitAck	method	GenProcessClass, MSG_META_QUIT_ACK
	call	GeodeGetProcessHandle		;
	inc	dx				;Go to next UI level
	cmp	dx, QuitLevel			;Is this the highest level?
	je	detach				;Branch if so...
	cmp	dx, QL_DETACH+1			;If ack of DETACH, have OD in
						;	CX:SI
	je	10$
	tst	cx				;Check abort flag
	jne	abort				;Branch if aborting...
10$:
						;If DX != QL_AFTER_DETACH, 
						; CX MUST = 0!	
	mov	ax, MSG_META_QUIT		;Else, just send next level of
	mov	di, mask MF_FORCE_QUEUE		; quit.
	GOTO	ObjMessage			;
detach:						;
	mov	dx,cx				;DX:BP <- ack OD
	mov	bp,si				;
	mov	ax, MSG_GEN_PROCESS_FINAL_DETACH	;Finish up the detach
	mov	di, mask MF_FORCE_QUEUE		;
	GOTO	ObjMessage			;
abort:						;
						;Clear out the quit state
	mov	ax, MSG_GEN_APPLICATION_SET_NOT_QUITTING
	GOTO	GenCallApplication	;Clear out the quit state
UI_QuitAck	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuitAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just sends a MSG_META_QUIT_ACK to the process

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuitAck	proc	near
	call	GeodeGetProcessHandle
	clr	cx				;No abort
	mov	ax, MSG_META_QUIT_ACK		;Send MSG_META_QUIT_ACK off to 
	mov	di, mask MF_FORCE_QUEUE		; the process
	call	ObjMessage
	ret
QuitAck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuitUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start QUIT sequence for the UI in this application

CALLED BY:	GLOBAL
PASS:		DX - quit level
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuitUI	proc	near
	clr	cx				;No aborting...
	mov	ax, MSG_GEN_APPLICATION_INITIATE_UI_QUIT
						;Send MSG_META_QUIT off to all
	call	GenCallApplication		; items on the active lists
	ret					; under the application.
QuitUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuitAfterUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give app object one last chance to abort QUIT, or OK process
		for detach.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuitAfterUI	proc	near
	mov	ax, MSG_GEN_APPLICATION_QUIT_AFTER_UI
	call	GenCallApplication
	ret
QuitAfterUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuitDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a MSG_META_DETACH to ourself, to start
		a DETACH of this application (with no ACK OD)

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuitDetach	proc	near
	call	GeodeGetProcessHandle
	clr	si
	clr	dx				; no ack OD
	clr	bp
	mov	ax, MSG_META_DETACH		;Send MSG_META_DETACH off to 
	mov	di, mask MF_FORCE_QUEUE		;ourselves
	call	ObjMessage
	ret
QuitDetach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuitAfterDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acks the last quit level.

CALLED BY:	GLOBAL
PASS:		bp - handle of AppInstanceReference
		CX:SI - ack OD to be passed on to MSG_META_QUIT_ACK
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuitAfterDetach	proc	near
	mov	dx, QL_AFTER_DETACH	;Ack the quit level
	call	GeodeGetProcessHandle	;
	mov	ax, MSG_META_QUIT_ACK	;Send MSG_META_QUIT_ACK off to 
	mov	di, mask MF_FORCE_QUEUE	; the process
	call	ObjMessage
	ret
QuitAfterDetach	endp

AppDetach ends

LessCommon	segment	resource


COMMENT @----------------------------------------------------------------------

MESSAGE:	UI_VMFileDirty -- MSG_META_VM_FILE_DIRTY for GenProcessClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of GenProcessClass

	ax - The message

	cx - file handle

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
UI_VMFileDirty	method dynamic	GenProcessClass, MSG_META_VM_FILE_DIRTY

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di
	mov	ax, MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE
	mov	bx, segment GenDocumentGroupClass
	mov	si, offset GenDocumentGroupClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				;cx = message

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_MODEL
	call	GenCallApplication
	pop	di
	call	ThreadReturnStackSpace

	ret

UI_VMFileDirty	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	UI_FinalBlockFree

DESCRIPTION:	free the block

PASS:
	ds - 	core block of geode

	ax - 	MSG_PROCESS_FINAL_BLOCK_FREE
	cx - 	block handle

RETURN:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version

------------------------------------------------------------------------------@

; This function is currently never called, as the UI thread ends up performing
; the MSG_PROCESS_FINAL_BLOCK_FREE.  As soon as applications have their own UI thread,
; this code should be moved to that class.	-- Doug
;
if	(0)
if	ERROR_CHECK
UI_FinalBlockFree	method dynamic GenProcessClass, MSG_PROCESS_FINAL_BLOCK_FREE

	push	cx
	mov	ax, MSG_VIS_VUP_EC_ENSURE_OBJ_BLOCK_NOT_REFERENCED
	call	GenCallApplication
	pop	cx

	mov	di, offset GenProcessClass
	GOTO	ObjCallSuperNoLock

UI_FinalBlockFree	endm
endif
endif

LessCommon	ends

Common	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	UI_SendToAppGCNList

DESCRIPTION:	Relays request to GenApplication object as
		MSG_META_GCN_LIST_SEND.   See method declaration for detailed
		info on why we do this.

PASS:		ds - core block of geode

		ax - MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
		dx - size GCNListMessageParams
		ss:bp - ptr to GCNListMessageParams

RETURN: 	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version

------------------------------------------------------------------------------@


UI_SendToAppGCNList	method dynamic GenProcessClass, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	mov	ax, MSG_META_GCN_LIST_SEND
	clr	bx
	call	GeodeGetAppObject
	tst	bx
	jz	eatUpdate
	mov	di, mask MF_STACK
	GOTO	ObjMessage

eatUpdate:
	; free up reference to block, if any
	;
	mov     bx, ss:[bp].GCNLMP_block
	call	MemDecRefCount

	; & nuke the unused status event.
	;
	mov	bx, ss:[bp].GCNLMP_event
	call	ObjFreeMessage
	ret

UI_SendToAppGCNList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UI_VMFileAutoSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Records and queues a message to autosave a particular
		document.  This is used by the VM temp-async mechanism.

CALLED BY:	MSG_META_VM_FILE_AUTO_SAVE
PASS:		cx	= file handle
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di (message handler)

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	10/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UI_VMFileAutoSave	method dynamic GenProcessClass, 
					MSG_META_VM_FILE_AUTO_SAVE

	mov	ax, MSG_GEN_DOCUMENT_GROUP_AUTO_SAVE_BY_FILE
	mov	bx, segment GenDocumentGroupClass
	mov	si, offset GenDocumentGroupClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				;cx = message

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_MODEL
	call	GenCallApplication

	ret
UI_VMFileAutoSave	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UI_VMFileSetInitialDirtyLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provides a hook which subclassed apps can use to set
		an app-specific VM dirty limit.

CALLED BY:	MSG_META_VM_FILE_SET_INITIAL_DIRTY_LIMIT
PASS:		cx	= file handle
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di (message handler)

SIDE EFFECTS:	may cause file to be saved and update modes changed

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	11/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UI_VMFileSetInitialDirtyLimit	method dynamic GenProcessClass, 
					MSG_META_VM_FILE_SET_INITIAL_DIRTY_LIMIT
	.enter
	mov	ax, MSG_GEN_DOCUMENT_GROUP_SET_DIRTY_LIMIT_BY_FILE
	mov	bx, segment GenDocumentGroupClass
	mov	si, offset GenDocumentGroupClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_MODEL
	call	GenCallApplication
	.leave
	ret
UI_VMFileSetInitialDirtyLimit	endm

Common	ends

