COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		UserInterface/Gen
FILE:		genAppMisc.asm

ROUTINES:
	Name			Description
	----			-----------
    INT LogDetachAction         This file contains routines to implement
				the GenApplication class.

    MTD MSG_META_INITIALIZE     Initialize object

    MTD MSG_GEN_APPLICATION_INSTALL_TOKEN 
				Install application's token and moniker
				list into token database

    MTD MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS 
				Return launch flags (GAI_launchFlags)

    MTD MSG_SPEC_BUILD          set our geode parent object (to deal with
				getting focus)

    MTD MSG_META_GET_INI_CATEGORY 
				Get the .ini category for the application

    INT GAGetAttrCommon         Common code to get get attr stuff for
				GenApplication objects

    MTD MSG_META_GET_HELP_FILE  Get the help file for an application

    MTD MSG_META_SAVE_OPTIONS   Make sure that the ini file is committed

    MTD MSG_META_LOAD_OPTIONS   Send to options list

    MTD MSG_GEN_APPLICATION_BRING_UP_HELP 
				Bring up help for the application

    MTD MSG_META_BRING_UP_HELP  Brings up help on the responder platform

    MTD MSG_META_GET_HELP_TYPE  Return help type for an application

    MTD MSG_GEN_APPLICATION_GET_FLOATING_KEYBOARD_OD

    GLB BringUpKeyboard         Brings up the floating keyboard if the app
				has the focus. Also performs some funky
				positioning junk as well.

    GLB HideKbd                 Brings up the floating keyboard if the app
				has the focus. Also performs some funky
				positioning junk as well.

    GLB CheckIfFocusApp         Checks if the application has the focus

    GLB DoHardIconBarFunction   Performs the passed HardIconBarFunction

    MTD MSG_GEN_APPLICATION_ROTATE_DISPLAY 
				Alter orientation of Display

    GLB StartupApp              Starts up the app, or brings it to the
				front if necessary.

    GLB CallApp                 Starts up the app, or brings it to the
				front if necessary.

    GLB StartupIndexedApp       Starts up the app whose information is kept
				in the "appXX" ini file key (where XX is
				the ascii string corresponding to the value
				in BP)

    GLB ProcessKbdStatus        Processes the keyboard status - this
				consists of either bringing the keyboard
				down, or checking to see if the keyboard
				should be on screen and bringing it up.

    GLB GetKbdOD                Returns the OD of the floating kbd

    GLB BringDownKeyboard       Brings down the floating keyboard, if it
				exists.

    MTD MSG_META_NOTIFY         handle hard icon bar for UIApp (when UI
				dialog has focus)

    MTD MSG_META_QUERY_IF_PRESS_IS_INK

    MTD MSG_META_REMOVING_DISK  Notifies any apps or document controls that
				a disk is being removed.  Objects that
				originated from this disk will shut
				themselves down.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of genApplication.asm

DESCRIPTION:
	This file contains routines to implement the GenApplication class.

	$Id: genAppMisc.asm,v 1.1 97/04/07 11:45:27 newdeal Exp $

------------------------------------------------------------------------------@


UserClassStructures	segment resource

; Declare the class records
	UIApplicationClass
	GenApplicationClass
UserClassStructures	ends

idata segment

	displayKeyboard	byte	0xff
	; If zero, the user wants the floating keyboard to come up
	; Else, if 0xff, the user wants the floating keyboard to disappear


idata ends

;------------------------------------------------------------
; DEBUGGING STUFF
;
; This is used primarily for debugging strange IACP/Lazarus interactions.
; At various strategic points during the startup/shutdown procedure of
; the application, it will record, in a global log, where it has gotten
; in the detach/quit process. Because so many IACP/Lazarus problems are
; very timing-dependent, having a trace of what went on in realtime is often
; the only way to figure out where the thing went wrong.
;
; detachPtr points to the next entry to be filled in in the detachLog, which
; is simply a circular buffer. If you say "p detachPtr-&detachLog[0]" in
; Swat, you should get the index of that entry, then be able to say
; "p detachLog[index-20..index-1]", where index is of course the index thus
; determined, and see the most recent 20 events... if, of course, index-20 >= 0
; 

LOG_DETACH_CRUFT	equ	FALSE

if LOG_DETACH_CRUFT

include Internal/heapInt.def
AppLogAction	etype	byte
    ALA_APP_MODE_COMPLETE	enum	AppLogAction
    ALA_AMC_IN_APP_MODE		enum	AppLogAction
    ALA_AMC_NOT_IN_APP_MODE	enum	AppLogAction
    ALA_AMC_MORE_CONNECTIONS	enum	AppLogAction
    ALA_AMC_SHUTDOWN		enum	AppLogAction
    ALA_AMC_LAZARUS		enum	AppLogAction
    ALA_AMC_FOR_IACP_ONLY	enum	AppLogAction
    ALA_AMC_QUIT		enum	AppLogAction
    
    ALA_QUIT_AFTER_UI		enum	AppLogAction
    ALA_QAUI_LEPER		enum	AppLogAction
    ALA_QAUI_MORE_CONNECTIONS	enum	AppLogAction
    ALA_QAUI_QUITTING		enum	AppLogAction
    ALA_QAUI_ABORT		enum	AppLogAction

    ALA_NOT_QUITTING		enum 	AppLogAction

    ALA_ATTACH			enum	AppLogAction
    ALA_OPEN_COMPLETE		enum	AppLogAction
    
    ALA_FINISH_QUIT		enum	AppLogAction
    ALA_FINISH_QUIT_ABORT	enum	AppLogAction
    
    ALA_QUIT			enum	AppLogAction
    
    ALA_DETACH			enum	AppLogAction
    ALA_DETACH_NESTED		enum	AppLogAction
    ALA_DETACH_COMPLETE		enum	AppLogAction
    
    ALA_APP_SHUTDOWN		enum	AppLogAction
    ALA_SHUTDOWN_COMPLETE	enum	AppLogAction

    ALA_SHUTDOWN_CONNECTION	enum	AppLogAction
    ALA_LOST_CONNECTION		enum	AppLogAction

    ALA_SWITCH_TO_APP_MODE	enum	AppLogAction
    ALA_STAM_FOR_USER		enum	AppLogAction
    ALA_STAM_HAVE_DOCUMENT	enum	AppLogAction
    ALA_STAM_BRING_TO_TOP	enum	AppLogAction
    ALA_STAM_SWITCHING		enum	AppLogAction

    ALA_NO_MORE_CONNECTIONS	enum	AppLogAction
    ALA_NMC_NOT_USABLE		enum	AppLogAction
    ALA_NMC_HAVE_CONNECTIONS	enum	AppLogAction
    ALA_NMC_STICKING_AROUND	enum	AppLogAction
    ALA_NMC_SENDING_QUIT	enum	AppLogAction
    ALA_NMC_DETACHING_PROCESS	enum	AppLogAction
    
    ALA_NEW_CONNECTION		enum 	AppLogAction

    ALA_CLOSE_COMPLETE		enum	AppLogAction

AppLog	struct
    AL_thread	hptr
    AL_action	AppLogAction
AppLog	ends

NUM_DETACH_LOG_ENTRIES	equ	512

udata	segment
detachLog	AppLog	NUM_DETACH_LOG_ENTRIES dup(<>)

udata	ends

idata	segment
detachPtr	nptr.AppLog	detachLog
idata	ends

Resident	segment	resource

LogDetachAction	proc	far
	pushf
	push	ds, bx
	segmov	ds, dgroup, bx
	mov	bx, ds:[detachPtr]
	mov	ds:[bx].AL_action, al
	mov	ax, ss:[TPD_threadHandle]
	mov	ds:[bx].AL_thread, ax
	add	bx, size AppLog
	cmp	bx, offset detachLog + size detachLog
	jb	done
	mov	bx, offset detachLog
done:
	mov	ds:[detachPtr], bx
	pop	ds, bx
	popf
	ret
LogDetachAction	endp

Resident	ends

LOG	macro	what
	push	ax
	mov	ax, what
	call	LogDetachAction
	pop	ax
	endm

else

LOG	macro	what
	endm

endif



;---------------------------------------------------

BuildUncommon segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenApplicationInitialize

DESCRIPTION:	Initialize object

PASS:
	*ds:si - instance data
	es - segment of GenApplicationClass
	ax - MSG_META_INITIALIZE

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	NOTE:  THIS ROUTINE ASSUME THAT THE OBJECT HAS JUST BEEN CREATED
	AND HAS INSTANCE DATA OF ALL 0'S FOR THE VIS PORTION

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@

GenApplicationInitialize	method static	GenApplicationClass, MSG_META_INITIALIZE

	or	ds:[di].GI_attrs, mask GA_TARGETABLE

	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock
	ret

GenApplicationInitialize	endm

BuildUncommon	ends

;
;------------
;

TokenUncommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenApplicationInstallToken

DESCRIPTION:	Install application's token and moniker list into token
		database

CALLED BY:	EXTERNAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/19/89	Initial version

------------------------------------------------------------------------------@

GenApplicationInstallToken	method	dynamic GenApplicationClass,
					MSG_GEN_APPLICATION_INSTALL_TOKEN
	push	di
	sub	sp, size GeodeToken
	segmov	es, ss
	mov	di, sp
	mov	bx, ds:[LMBH_handle]
	call	MemOwner		; bx <- owning geode
	mov	ax, GGIT_TOKEN_ID
	call	GeodeGetInfo		; copy token to es:di
		CheckHack <size GeodeToken eq 6 and offset GT_chars eq 0 and \
			   offset GT_manufID eq 4>
	pop	ax		; GT_chars[0]
	pop	bx		; GT_chars[2]
	pop	si		; GT_manufID
	pop	di		; ds:di <- gen instance
	call	TokenGetTokenInfo		; is it already there?
	jnc	alreadyThere			; yes
	mov	cx, ds:[LMBH_handle]		; cx:dx = moniker list
	mov	dx, ds:[di].GI_visMoniker
	tst	dx
	jz	notMonikerList			; no moniker!
	;
	; don't try this with monikers that are not lists
	;
	mov	bp, dx
	mov	bp, ds:[bp]
	test	ds:[bp].VM_type, mask VMT_MONIKER_LIST
	jz	notMonikerList
	clr	bp				; moniker list already
						;	relocated
	call	TokenDefineToken
alreadyThere:
notMonikerList:
	ret
GenApplicationInstallToken	endm

TokenUncommon ends

;-----

AppGCN	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppGetLaunchFlags -- MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS for
			GenApplicationClass

DESCRIPTION:	Return launch flags (GAI_launchFlags)

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS

RETURN: al	- AppLaunchFlags

ALLOWED TO DESTROY:
	ah, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@


GenAppGetLaunchFlags	method	dynamic GenApplicationClass, \
				MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS

	mov	al, ds:[di].GAI_launchFlags
	ret

GenAppGetLaunchFlags	endm

AppGCN	ends

;
;--------------
;

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UIAppSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set our geode parent object (to deal with getting focus)

CALLED BY:	MSG_SPEC_BUILD

PASS:		*ds:si	= UIApplicationClass object
		ds:di	= UIApplicationClass instance data
		es 	= segment of UIApplicationClass
		ax	= MSG_SPEC_BUILD

		bp	= SpecBuildFlags

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/14/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UIAppSpecBuild	method	dynamic	UIApplicationClass, MSG_SPEC_BUILD
	;
	; call superclass
	;
	mov	di, offset UIApplicationClass
	call	ObjCallSuperNoLock
	;
	; set our parent "object" to be the system object
	;
	push	ds
	mov	bx, segment uiSystemObj
	mov	ds, bx
	mov	bx, handle 0
	mov	cx, ds:[uiSystemObj].handle
	mov	dx, ds:[uiSystemObj].chunk
	call	WinGeodeSetParentObj
	pop	ds
	ret
UIAppSpecBuild	endm

Init ends

;
;----------
;

IniFile	segment

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenAppGetIniCategory -- MSG_META_GET_INI_CATEGORY
						for GenApplicationClass

DESCRIPTION:	Get the .ini category for the application

PASS:
	*ds:si - instance data
	es - segment of GenApplicationClass

	ax - The message

	cx:dx - buffer (INI_CATEGORY_BUFFER_SIZE)

RETURN:
	carry - set if buffer filled in

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/21/91		Initial version

------------------------------------------------------------------------------@
GenAppGetIniCategory	method dynamic	GenApplicationClass,
						MSG_META_GET_INI_CATEGORY

	mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
	FALL_THRU	GAGetAttrCommon
GenAppGetIniCategory	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GAGetAttrCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to get get attr stuff for GenApplication objects

CALLED BY:	GenAppGetIniCategory(), GenAppGetHelpFile()
PASS:		*ds:si - GenApplication object
		ax - vardata to check
		cx:dx - buffer for attr
RETURN:		cx:dx - buffer filled in
		carry - set 
DESTROYED:	ax, bx, di, si, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GAGetAttrCommon		proc	far

	movdw	esdi, cxdx			;es:di <- dest

	call	ObjVarFindData
	jc	categoryExists
	;
	; if no category locally then use the permanent name of the owning geode
	;
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov	ax, GGIT_PERM_NAME_ONLY
	call	GeodeGetInfo
	;
	; NULL-terminate the geode name
	;
	mov	{char}es:[di+GEODE_NAME_SIZE], 0
	call	RemoveTrailingSpacesFromHelpFileName
	stc					;carry <- buffer filled
	ret

categoryExists:
	push	cx
	mov	si, bx
	VarDataSizePtr	ds, si, cx		;cx <- size of attr
	push	di
	rep	movsb				;copy me jesus
	pop	di
	call	RemoveTrailingSpacesFromHelpFileName
	pop	cx
	stc					;carry <- buffer filled
	ret
GAGetAttrCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppGetHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the help file for an application

CALLED BY:	MSG_META_GET_HELP_FILE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GenApplicationClass
		ax - the message

		cx:dx - buffer for filename (FILE_LONGNAME_BUFFER_SIZE)

RETURN:		cx:dx - filled in

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppGetHelpFile		method dynamic GenApplicationClass,
						MSG_META_GET_HELP_FILE
	;
	; Call our superclass first, in case there is other (ie. GenClass)
	; behavior we want to support. In this case GenClass will query up
	; the generic tree.  Failing that, it will check for the attribute
	; ATTR_GEN_HELP_FILE_FROM_INIT_FILE.
	;
	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock
	jc	done				;branch if handled
	;
	; Our superclass didn't handle it -- check locally for attrs
	;
	mov	ax, ATTR_GEN_HELP_FILE
	call	GAGetAttrCommon			;sets carry always
done:
	ret
GenAppGetHelpFile		endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenApplicationOptionsChanged --
		MSG_GEN_APPLICATION_OPTIONS_CHANGED for GenApplicationClass

DESCRIPTION:	Enable Save Options and Disable Options triggers, if any

PASS:
	*ds:si - instance data
	es - segment of GenApplicationClass

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
	brianc	1/7/98		Initial version

------------------------------------------------------------------------------@
GenApplicationOptionsChanged	method dynamic	GenApplicationClass,
					MSG_GEN_APPLICATION_OPTIONS_CHANGED
	mov	cx, MSG_GEN_SET_ENABLED
	call	SetOptionsTriggers
	ret
GenApplicationOptionsChanged	endm

SetOptionsTriggers	proc	near
	mov	ax, ATTR_GEN_APPLICATION_SAVE_OPTIONS_TRIGGER
	call	ObjVarFindData
	jnc	noTriggers
	mov	di, bx
	mov	ax, ATTR_GEN_APPLICATION_RESET_OPTIONS_TRIGGER
	call	ObjVarFindData
	jnc	noReset
	cmp	cx, MSG_GEN_SET_NOT_ENABLED
	je	noReset		; reset trig disabled manually in RESET_OPTIONS
	call	enableTrigger
noReset:
	mov	bx, di		; ds:[bx] = save options
	call	enableTrigger
noTriggers:
	ret
		
enableTrigger	label	near
	push	cx, si, di
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov	ax, cx
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, si, di
	retn
SetOptionsTriggers	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenApplicationMetaSaveOptions -- MSG_META_SAVE_OPTIONS
						for GenApplicationClass

DESCRIPTION:	Make sure that the ini file is committed

PASS:
	*ds:si - instance data
	es - segment of GenApplicationClass

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
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
GenApplicationMetaSaveOptions	method dynamic	GenApplicationClass,
						MSG_META_SAVE_OPTIONS,
						MSG_META_RESET_OPTIONS

	cmp	ax, MSG_META_RESET_OPTIONS
	jnz	notReset

	push	ax
	sub	sp, INI_CATEGORY_BUFFER_SIZE
	movdw	cxdx, sssp

	mov	ax, MSG_META_GET_INI_CATEGORY	; call self to fetch category
	call	ObjCallInstanceNoLock		; (UserGetInitFileCategory is
						; actually less efficient here)

	mov	ax, sp

	; delete the .ini file category

	push	si, ds
	segmov	ds, ss
	mov_tr	si, ax
	call	InitFileDeleteCategory
	pop	si, ds

	add	sp, INI_CATEGORY_BUFFER_SIZE
	pop	ax


notReset:

	;
	; allow for GenApplication to have options itself
	;
	push	ax
	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock
	pop	ax

	;
	; now send to startup-load options list
	;
	push	ax
	mov	di, GAGCNLT_STARTUP_LOAD_OPTIONS
	call	SendToGenAppGCNList
	pop	ax

	;
	; then send to self-load options list
	;
	push	ax
	mov	di, GAGCNLT_SELF_LOAD_OPTIONS
	call	SendToGenAppGCNList

	call	InitFileCommit

	;
	; update options triggers
	;
	mov	cx, MSG_GEN_SET_NOT_ENABLED
	call	SetOptionsTriggers
	;
	; force queue a disable for Reset button if we just reset
	;
	pop	ax
	cmp	ax, MSG_META_RESET_OPTIONS
	jne	done
	mov	ax, ATTR_GEN_APPLICATION_RESET_OPTIONS_TRIGGER
	call	ObjVarFindData
	jnc	done
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov	dl, VUM_NOW
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	ret




GenApplicationMetaSaveOptions	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenApplicationMetaLoadOptions -- MSG_META_LOAD_OPTIONS
						for GenApplicationClass

DESCRIPTION:	Send to options list

PASS:
	*ds:si - instance data
	es - segment of GenApplicationClass

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
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
GenApplicationMetaLoadOptions	method dynamic	GenApplicationClass,
						MSG_META_LOAD_OPTIONS

	;
	; allow for GenApplication to have options itself
	;
	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock

	;
	; now send to startup-load options list
	;
	mov	ax, MSG_META_LOAD_OPTIONS
	mov	di, GAGCNLT_STARTUP_LOAD_OPTIONS
	call	SendToGenAppGCNList

	ret

GenApplicationMetaLoadOptions	endm

IniFile	ends

;
;------------
;

AppGCN	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationGCNListSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Intercept message to implement GCNListSendFlag
		GCNLSF_IGNORE_IF_STATUS_TRANSITIONING

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax	- MSG_META_GCN_LIST_SEND
		dx	- size GCNListMessageParams
		ss:bp	- ptr to GCNListMessageParams

                NOTE:  If NotificationDataBlock is passed in, & we don't call
		       the superclass, it is our responsibility to dec its
		       in-use count.
 
RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenApplicationGCNListSend	method	GenApplicationClass, \
					MSG_META_GCN_LIST_SEND
	
	test	ss:[bp].GCNLMP_flags, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
	jnz	testHandles

callSuper:
	; If bit not sent, just do regular stuff
	;
	; Call "superclass", or GenClass, statically, to save a trip through
	; ObjCallSuperNoLock.  Handler either calls the superclass of GenClass
	; for this object, or if it is not built out, calls MetaClass directly.
	;
	mov	ax, MSG_META_GCN_LIST_SEND
	call	GenCallMeta
	ret

	;
	; If we are running out of handles than we do not want to
	; allocate more handles by putting messages on the queue
	;
testHandles:
	push	dx
	mov	ax, SGIT_NUMBER_OF_FREE_HANDLES
	call	SysGetInfo
	cmp	ax, LOW_ON_FREE_HANDLES_THRESHOLD
	pop	dx
	jl	callSuper

doIt::
	; Otherwise, implement request

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_DETACHING
	jnz	callSuper			; no optimization if detaching

	mov	ax, TEMP_META_GCN
	call	ObjVarFindData			; look for ptr to
						; TempGenAppGCNList
	jnc	callSuper			; if not found, no optimization

	push	si
	mov	di, ds:[bx].TMGCND_listOfLists	; get list of lists chunk
	mov     bx, ss:[bp].GCNLMP_ID.GCNLT_manuf
	mov     ax, ss:[bp].GCNLMP_ID.GCNLT_type
						; carry set, may create list
	call	GCNListFindListInBlock
	mov	di, si
	pop	si
	jnc	callSuper			; if not found, no optimization

	mov	di, ds:[di]			; dereference GCNListHeader
	mov	cx, ds:[di].GCNLH_statusCount	; fetch current count

	; Need to send message to self, via UI then app queue...

	push	si				; save chunk of app object

	mov	ax, MSG_GEN_APPLICATION_GCN_LIST_SEND_INTERNAL
	mov	bx, ds:[LMBH_handle]		; Send to self
	mov	di, mask MF_STACK or mask MF_RECORD
	call	ObjMessage			; wrap up into event

	mov	cx, di
	mov	dx, ds:[LMBH_handle]		; pass a block owned by process
	mov	bp, OFIQNS_PROCESS_OF_OWNING_GEODE	; Process is next stop
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	mov	bx, ds:[LMBH_handle]	; get handle of app object
	pop	si			; & chunk of app object
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	ObjMessage

GenApplicationGCNListSend	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationGCNListSendInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Either toss the status update, or set it, depending on
		whether the list has "gone idle" or not.  If it's been updated
		since we first looked at it, toss the event.  If not, the
		status update we have is "for real" & should be set.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax	- MSG_GEN_APPLICATION_GCN_LIST_SEND_INTERNAL
		cx	- status count at time of original
				MSG_META_GCN_LIST_SEND
		dx	- size GCNListMessageParams
		ss:bp	- ptr to GCNListMessageParams

                NOTE:  If NotificationDataBlock is passed in, & we don't call
		       the superclass, it is our responsibility to dec its
		       in-use count.
 
RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenApplicationGCNListSendInternal	method	GenApplicationClass, \
				MSG_GEN_APPLICATION_GCN_LIST_SEND_INTERNAL

	; Otherwise, implement request

	mov	ax, TEMP_META_GCN
	call	ObjVarFindData		; look for ptr to TempGenAppGCNList
EC <	ERROR_NC	GEN_APP_GCN_INTERNAL_ERROR			>

	push	si
	mov	di, ds:[bx].TMGCND_listOfLists	; get list of lists chunk
	mov     bx, ss:[bp].GCNLMP_ID.GCNLT_manuf
	mov     ax, ss:[bp].GCNLMP_ID.GCNLT_type
						; carry set, may create list
	call	GCNListFindListInBlock
	mov	di, si
	pop	si
EC <	ERROR_NC	GEN_APP_GCN_INTERNAL_ERROR			>

	mov	di, ds:[di]			; dereference GCNListHeader
	cmp	cx, ds:[di].GCNLH_statusCount	; fetch current count
	jne	nukeEvent

;callSuper:
	mov	ax, MSG_META_GCN_LIST_SEND
	mov	di, offset GenApplicationClass
	GOTO	ObjCallSuperNoLock

nukeEvent:
	; free up reference to block, if any
	;
	mov     bx, ss:[bp].GCNLMP_block
	call	MemDecRefCount

	; & nuke the unused status event.
	;
	mov	bx, ss:[bp].GCNLMP_event
	call	ObjFreeMessage
	ret

GenApplicationGCNListSendInternal	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationGCNListGetListOfLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Just returns lists of lists chunk, so that caller (must be
		running from UI thread, can directly work with GCN data
		structures.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax	- MSG_GEN_APPLICATION_GET_GCN_LIST_OF_LISTS
 
RETURN:		ax	- lists of lists chunk, or zero if none exists
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenApplicationGCNListGetListOfLists	method	GenApplicationClass, \
				MSG_GEN_APPLICATION_GET_GCN_LIST_OF_LISTS
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData		; look for ptr to TempGenAppGCNList
	jnc	noList
	mov	ax, ds:[bx].TMGCND_listOfLists	; get list of lists chunk
	ret
noList:
	clr	ax
	ret

GenApplicationGCNListGetListOfLists	endm

AppGCN	ends

;
;------------
;

BuildUncommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenApplicationBuildDialogFromTemplate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Utility message to create a new object block & hook it
		into the generic tree

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_APPLICATION_BUILD_DIALOG_FROM_TEMPLATE

		^lcx:dx	- Object block, chunk offset of top object to duplicate

RETURN:		^lcx:dx	- duplicated block, object object
		bp	- CustomDialogBoxFlags

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	9/8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenApplicationBuildDialogFromTemplate	method	GenApplicationClass, \
				MSG_GEN_APPLICATION_BUILD_DIALOG_FROM_TEMPLATE
	mov	bx, cx
	clr	ax		; set owner to be the same as the geode owning
				; the currently running thread
	clr	cx		; have block run by current thread
	call	ObjDuplicateResource
	mov	cx, bx

	; Add the summons as the last child of the application.
	;
	push	cx, dx,bp
	mov	bp, CCO_LAST
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock
	pop	cx, dx,bp

	; set it USABLE
	;
	push	bp
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	mov	di, mask MF_CALL	;  mask MF_FIXUP_DS not needed here.
	call	ObjMessage
	pop	bp

	mov	cx, bx		; Return new dialog in cx:dx
	mov	dx, si

	clr	bp		; For now -- no CustomDialogBoxFlags
	ret

GenApplicationBuildDialogFromTemplate	endm

BuildUncommon	ends



;---


HelpControlCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppBringUpHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up help for the application

CALLED BY:	MSG_GEN_APPLICATION_BRING_UP_HELP
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GenApplicationClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This is normally brought up by pressing <F1>, but may be
	brought up by a dedicated help key on some systems.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppBringUpHelp		method dynamic GenApplicationClass,
					MSG_GEN_APPLICATION_BRING_UP_HELP
	;
	; Record a message to bring up help
	;
	push	si
	mov	ax, MSG_META_BRING_UP_HELP
	mov	di, mask MF_RECORD
	clr	bx, si				;bx:si <- no class
	call	ObjMessage
	mov	cx, di				;cx <- ClassedEvent
	pop	si
	;
	; Send the recorded message to the focus
	;
	mov	dx, TO_APP_FOCUS		;dx <- TravelOption
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjCallInstanceNoLock
GenAppBringUpHelp		endm




if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	GenApplicationMetaBringUpHelp -- 
	MSG_META_BRING_UP_HELP for GenApplicationClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Brings up help on the responder platform

PASS:		*ds:si 	- instance data of GenApplicationClass object
		ds:di	- GenApplicationClass instace data
		ds:bx	- GenApplicationClass object (same as #ds:si)
		es     	- segment of GenApplicationClass
		ax 	- MSG_META_BRING_UP_HELP

RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/16/94		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
endif ; 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppGetHelpType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return help type for an application

CALLED BY:	MSG_META_GET_HELP_TYPE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GenApplicationClass
		ax - the message

RETURN:		dl - HelpType
		carry - set if help type found

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppGetHelpType		method dynamic GenApplicationClass,
						MSG_META_GET_HELP_TYPE
	;
	; Call our superclass to see if we have help defined locally
	;
	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock
	jc	helpFound			;branch if help found
	;
	; Return default help type
	;
	mov	dl, HT_SYSTEM_HELP
	stc					;carry <- help found
helpFound:
	ret
GenAppGetHelpType		endm

HelpControlCode ends

Ink segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppFloatingKeyboardClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification that the floating keyboard has been closed

CALLED BY:	GLOBAL
PASS:		*ds:si - app object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppFloatingKeyboardClosed	method	GenApplicationClass,
				MSG_GEN_APPLICATION_FLOATING_KEYBOARD_CLOSED
	uses	es
	.enter

	segmov	es, dgroup, ax
	clr	es:[displayKeyboard]

	.leave
	ret
GenAppFloatingKeyboardClosed	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppGetFloatingKbdOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEN_APPLICATION_GET_FLOATING_KEYBOARD_OD
PASS:		*ds:si	= GenApplicationClass object
		ds:di	= GenApplicationClass instance data
		ds:bx	= GenApplicationClass object (same as *ds:si)
		es 	= segment of GenApplicationClass
		ax	= message #
RETURN:		
DESTROYED:	

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppGetFloatingKbdOD	method dynamic GenApplicationClass, 
				MSG_GEN_APPLICATION_GET_FLOATING_KEYBOARD_OD
	.enter

if STATIC_PEN_INPUT_CONTROL
	;
	; should we return 0 to indicate this app has no floating keyboard,
	; or should we return the SystemHWRBox optr?
	;
	clr	bx, si
else
	call	GetKbdOD
endif

	.leave
	ret
GenAppGetFloatingKbdOD	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppDisplayFloatingKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays a floating keyboard, creating one if necessary.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	ax, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GenAppDisplayFloatingKeyboard	method	GenApplicationClass,
				MSG_GEN_APPLICATION_TOGGLE_FLOATING_KEYBOARD

if STATIC_PEN_INPUT_CONTROL
	
	;
	; hard icon button only brings up HWR box, doesn't toggle
	;
	mov	bx, handle SystemHWRBox
	mov	si, offset SystemHWRBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage
	ret

else

	uses	es
	.enter

	mov	ax, TEMP_GEN_APPLICATION_FLOATING_KEYBOARD_INFO
	call	ObjVarFindData
	jnc	noKeyboardPossible

	segmov	es, dgroup, ax
	xor	es:[displayKeyboard], 0xff
	jnz	bringUpKeyboard

	call	BringDownKeyboard
	jc	exit				;carry set == success

	mov	es:[displayKeyboard], 0xff	;Keyboard still onscreen
	jmp	noKeyboardPossible

bringUpKeyboard:
	clr	ax				;Keyboard is already offscreen
	call	BringUpKeyboard
	jc	exit				;carry set == success

	clr	es:[displayKeyboard]		;Keyboard not onscreen
	jmp	noKeyboardPossible
exit:
	.leave
	ret

noKeyboardPossible:
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
	jmp	exit

endif

GenAppDisplayFloatingKeyboard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BringUpKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the floating keyboard if the app has the focus.
		Also performs some funky positioning junk as well.

CALLED BY:	GLOBAL
PASS:		es - dgroup
		ax - non-zero if we want to bring the keyboard down before
		     bringing it up (this is used when the keyboard is
		     changing layers - when a sysModal box is coming on/off
		     screen, for example)
		*ds:si - GenApplication object
RETURN:		carry set if we brought up floating kbd
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not STATIC_PEN_INPUT_CONTROL
BringUpKeyboard	proc	far
	.enter
	;
	; If we don't have the focus, then don't bother
	; bringing the keyboard up.
	;
	call	CheckIfFocusApp
	clc					;assume not initiated
	jne	exit

	push	ax				; preserve bringKbdDown flag
	mov	ax, TEMP_GEN_APPLICATION_FLOATING_KEYBOARD_INFO
	call	ObjVarFindData
EC <	ERROR_NC CANNOT_BRING_UP_KEYBOARD_WITHOUT_FLOATING_KEYBOARD_INFO>

	clr	di
	xchg	ds:[bx].FKI_defaultPosition, di
	mov	ax, MSG_VIS_GET_SIZE		;Get the width of the parent 
	call	GenCallParent			; field (in case we have to
						; center the object)
	push	cx
	call	GetKbdOD
	movdw	bxsi, cxdx
	pop	cx

	tst	di				;If flag set, then move to
	jz	noPositionChange		; default position

	pop	ax				; set bringKbdDown if we are
	mov	ax, -1				;  initially positioning
	push	ax

	mov	ax, MSG_GEN_PEN_INPUT_CONTROL_SET_TO_DEFAULT_POSITION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	; We bring the box up via the queue, so as not to disturb the quirky
	; gained/lost focus mechanism - see BringDownKeyboard for more details.
	;
noPositionChange:
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_GEN_GET_ENABLED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax		; clean up stack in case we have to exit
	jnc	exit

	push	ax				; re-push bringKbdDown flag
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	pop	cx				; restore bringKbdDown flag
	jcxz	initiated

	;
	; Bring the keyboard down before bringing it up - since we are
	; inserting messages at the front of the queue, this message
	; will be handled *before* the MSG_GEN_INTERACTION_INITIATE.
	;
	call	HideKbd
initiated:
	stc					;initiated floating keyboard
exit:
	.leave
	ret
BringUpKeyboard	endp

HideKbd	proc	near

;	Send MSG_GEN_GUP_INTERACTION_COMMAND to the object via
;	MSG_META_SEND_CLASSED_EVENT, so we can tell the difference between
;	an application-sent dismiss, and one caused by a user action.

	pushdw	bxsi	
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	clrdw	bxsi
	mov	di, mask MF_RECORD
	call	ObjMessage
	popdw	bxsi

	mov	cx, di
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_SELF
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	ret
HideKbd	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfFocusApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the application has the focus

CALLED BY:	GLOBAL
PASS:		*ds:si - GenApplication
RETURN:		z flag set if has focus (jz appHasFocus)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not STATIC_PEN_INPUT_CONTROL
CheckIfFocusApp	proc	near	uses	ax, cx, dx, bp
	.enter

	;
	; ask our parent (the Field) who has focus.
	;
	mov	ax, MSG_META_GET_FOCUS_EXCL
	call	GenCallParent		;^lCX:DX <- OD of focus app
	jc	gotOptr

	;
	; if MSG_META_GET_FOCUS_EXCL returns carry clear then our parent
	; isn't a focus node, because we are in the rare case where our
	; app is the UI's app (UIApp) which is under the GenScreen and not
	; the GenField.  Because of this we need to ask the GenSystem
	; object (the next up of the focus nodes), not our parent.
	;
	mov	ax, MSG_META_GET_FOCUS_EXCL
	call	UserCallSystem

gotOptr:
	cmp	cx, ds:[LMBH_handle]	;See if it is us
	jne	exit			;Exit if some other app has the focus
	cmp	dx, si
exit:
	.leave
	ret
CheckIfFocusApp	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoHardIconBarFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs the passed HardIconBarFunction

CALLED BY:	GLOBAL
PASS:		bp - HardIconBarFunction to perform
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DoHardIconBarFunction	proc	near
	.enter
	cmp	bp, length hardIconBarMessages	;Exit if this is not a handled
	jae	exit				; function.

;	Send the message approprate for this app

	push	ax, cx, dx, bp
	shl	bp, 1
	mov	ax, cs:[hardIconBarMessages][bp]
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
exit:
	.leave
	ret
DoHardIconBarFunction	endp
hardIconBarMessages	word	\
			MSG_GEN_APPLICATION_TOGGLE_EXPRESS_MENU,
			MSG_GEN_APPLICATION_TOGGLE_CURRENT_MENU_BAR,
			MSG_GEN_APPLICATION_TOGGLE_FLOATING_KEYBOARD,
			MSG_GEN_APPLICATION_BRING_UP_HELP,
			MSG_GEN_APPLICATION_ROTATE_DISPLAY



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppRotateDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter orientation of Display

CALLED BY:	MSG_GEN_APPLICATION_ROTATE_DISPLAY
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Alters orientation of screen

PSEUDO CODE/STRATEGY:
		See specific platform below...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	1/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenAppRotateDisplay	method dynamic GenApplicationClass, 
					MSG_GEN_APPLICATION_ROTATE_DISPLAY

	ret
GenAppRotateDisplay	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppChangeDisplayMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change various display attributes

CALLED BY:	MSG_GEN_APPLICATION_CHANGE_DISPLAY_MODE
PASS:		*ds:si	= GenApplicationClass object
		ds:di	= GenApplicationClass instance data
		ds:bx	= GenApplicationClass object (same as *ds:si)
		es 	= segment of GenApplicationClass
		ax	= message #
		cx	= requested DisplayMode
RETURN:		cx	= DisplayMode as set
		carry set if requested mode is not supported
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The Responder platform only supports definition changes, so we only
	bother parsing that part of the request.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/24/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppChangeDisplayMode	method dynamic GenApplicationClass, 
					MSG_GEN_APPLICATION_CHANGE_DISPLAY_MODE
		mov	cx, (DMC_DEFAULT shl offset DM_color) or \
				(DMO_DEFAULT shl offset DM_orientation) or \
				(DMD_DEFAULT shl offset DM_definition) or \
				DMR_DEFAULT
		stc
		ret
GenAppChangeDisplayMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts up the app, or brings it to the front if necessary.

CALLED BY:	GLOBAL
PASS:		bx - handle with path of app (is freed after use)
RETURN:		nada
DESTROYED:	ax, cx, dx, di, si, 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/25/92	Initial version
	pjc	5/23/95		Added multi-language support.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupApp	proc	near	uses	bp
	.enter
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	CallApp
	push	bx
	call	MemLock
	mov	ds, ax
	clr	si		;DS:SI <- app to launch
	clr	ah		;normal launch mode
	clr	cx		;Use default attach mode
	clr	dx		;No data file or state file
	clr	bx		;search system dirs
	clrdw	dibp		;No default
	call	PrepAppLaunchBlock
	mov	bx, dx		;BX <- AppLaunchBlock

;	Get a pointer to the GeodeToken

	segmov	es, ss
	sub	sp, size GeodeToken
	mov	di, sp			;ES:DI <- ptr to GeodeToken

	call	FilePushDir

	mov	ax, SP_APPLICATION

if MULTI_LANGUAGE
	; If we are in multi-language mode, look at the file links in
	; PRIVDATA\LANGUAGE\<Current Language>\WORLD, which have the correct
	; translated names.

	call	IsMultiLanguageModeOn
	jc	setPath
	call	GeodeSetLanguageStandardPath
	jmp	afterSetPath
endif

setPath:
	call	FileSetStandardPath
afterSetPath::
	push	ax
	mov	ax, FEA_TOKEN
	mov	cx, size GeodeToken
	mov	dx, si			;DS:DX <- name of app to start up
	call	FileGetPathExtAttributes
	pop	cx
	jnc	gotToken

	cmp	cx, SP_SYS_APPLICATION
	je	noToken

	mov	ax, SP_SYS_APPLICATION
	jmp	setPath			;try again in SP_SYS_APPLICATION
noToken:
	stc				;we failed!!!
gotToken:
	call	FilePopDir
	jc	reportError
	

	mov	ax, mask IACPCF_FIRST_ONLY or \
			(IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	call	IACPConnect
	jc	reportError
	clr	cx
	call	IACPShutdown
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	CallApp
exit:
	add	sp, size GeodeToken
	pop	bx
	call	MemFree
	.leave
	ret
reportError:
	push	ax
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	CallApp
	pop	ax

	mov	di, offset GEOSExecErrorTextOne
	clr	si		;DS:SI <- app name
	call	ReportLoadAppError
	jmp	exit
StartupApp	endp

CallApp	proc	near	uses	bx, si, di
;
;	Save as UserCallApplication, without fixing up DS
;
	.enter
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
CallApp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupIndexedApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts up the app whose information is kept in the
		"appXX" ini file key (where XX is the ascii string
		corresponding to the value in BP)

CALLED BY:	GLOBAL
PASS:		bp - index of app to start up
RETURN:		nada
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
hardIconBarCategory	char	"hardIconBar",0
StartupIndexedApp	proc	near	uses	ax, cx, dx, bp, di, si, ds, es
	index	local	word	\
		push	bp
	appKey	local UHTA_NO_NULL_TERM_BUFFER_SIZE+1 + 3 dup (char)
	.enter
	segmov	es, ss
	lea	di, appKey
	mov	ax, "AP"
	mov	es:[di], ax		;Write "APP" out to the app
	mov	es:[di]+2, ah
	add	di, 3
	mov	ax, index
	clr	dx
	mov	cx, mask UHTAF_NULL_TERMINATE or mask UHTAF_SBCS_STRING
	call	UtilHex32ToAscii

;	Get the app name

	push	bp, ds
	mov	cx, ss
	lea	dx, appKey
	segmov	ds, cs
	mov	si, offset hardIconBarCategory
.assert IFCC_INTACT eq 0
	clr	bp
	call	InitFileReadString
	pop	bp, ds
EC <	WARNING_C	NO_INDEXED_APP_KEY_FOUND			>
EC <	jc	exit							>
NEC <	jc	exit							>

	push	ds:[LMBH_handle]
    	call	StartupApp
	pop	bx
	call	MemDerefDS
exit:
	.leave
	ret
StartupIndexedApp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessKbdStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Processes the keyboard status - this consists of either 
		bringing the keyboard down, or checking to see if the 
		keyboard should be on screen and bringing it up.

CALLED BY:	GLOBAL
PASS:		*ds:si - GenApp object
		bp - block containing NotifyFocusWinKbdStatus structure
RETURN:		nada
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not STATIC_PEN_INPUT_CONTROL

ProcessKbdStatus	proc	near	uses	ax, cx, dx, bp, es, si
	.enter
	tst	bp
	jz	bringKeyboardDown
	mov	bx, bp
	call	MemLock
	mov	es, ax
	tst	es:[NFWKS_needsFloatingKbd]
	jnz	dispKeyboard

;	The current app has its own embedded keyboard, so bring down the
;	floating box.

	call	MemUnlock
bringKeyboardDown:
	mov	ax, TEMP_GEN_APPLICATION_FLOATING_KEYBOARD_INFO
	call	ObjVarDeleteData

	call	BringDownKeyboard
exit:
	.leave
	ret
dispKeyboard:

;	The currently focused window wants the keyboard, so reflect that
;	fact in vardata.

	push	bx, si

	mov	ax, TEMP_GEN_APPLICATION_FLOATING_KEYBOARD_INFO
	call	ObjVarFindData
	jc	setVardata
	mov	cx, size FloatingKeyboardInfo
	call	ObjVarAddData
setVardata:
	clr	ds:[bx].FKI_defaultPosition
	cmp	es:[NFWKS_kbdPosition].P_x, -1
	jne	10$
	mov	ds:[bx].FKI_defaultPosition, TRUE
10$:

;	Set the flag that says whether the current window is sysModal or not.
;
;	If the current window is sysModal, and the previously focused window
;	was not, or vice-versa, then we need to bring the floating keyboard
;	off screen so it'll re-open its window in the correct layer.
;

	mov	ax, es:[NFWKS_sysModal]
	xchg	ds:[bx].FKI_sysModal, ax		;AX <- non-zero if
							; changing from modal
	xor	ax, es:[NFWKS_sysModal]			; to sysModal
	call	GetKbdOD
	movdw	bxsi, cxdx

;	If we want to position the window at a specific position, do it

	cmp	es:[NFWKS_kbdPosition].P_x, -1
	jz	defaultPosition

	push	ax
	mov	dh, WPT_AT_SPECIFIC_POSITION
	mov	cx, es:[NFWKS_kbdPosition].P_x
	mov	bp, es:[NFWKS_kbdPosition].P_y
	
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_WIN_POSITION

	call	ObjMessageFixupDS
	pop	ax

defaultPosition:
	mov	cx, es:[NFWKS_sysModal]
	tst	ax
	jnz	changeLayerPriority

doneChangingLayerPriority:

	pop	bx, si				;*DS:SI <- app obj
						;BX <- notification block
	call	MemUnlock



;	If the app has the focus, and the user has the "displayKeyboard" toggle
;	set appropriately, then bring the box up.

	segmov	es, idata, cx
	tst	es:[displayKeyboard]
	jz	exit			;Exit if user has keyboards turned off

	call	BringUpKeyboard		;
	jmp	exit

changeLayerPriority:
;
;	Change the layer priority of the window, if we are changing from
;	having a sysModal to non-sysModal, or vice-versa.
;
;	CX = non-zero if focused window is sysModal
;
	jcxz	nonSysModal

;	This is a system modal box, so add a special layer id and priority

	clr	cx
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
	call	AddWordOfVardata

	mov	cx, LAYER_PRIO_MODAL-1
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	call	AddWordOfVardata
	mov	ax, TRUE
	jmp	doneChangingLayerPriority

nonSysModal:

;	If this is not a sys modal box, then nuke the custom layerID and
;	priority

	mov	cx, ATTR_GEN_WINDOW_CUSTOM_LAYER_ID
	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, TRUE
	jmp	doneChangingLayerPriority

AddWordOfVardata:

;	AX - vardata type to add
;	CX - word of data

	mov	dx, size AddVarDataParams
	sub	sp, dx
	mov	bp, sp
	push	cx
	movdw	ss:[bp].AVDP_data, sssp	;SS:SP <- ptr to pushed CX
	mov	ss:[bp].AVDP_dataSize, size word
	mov	ss:[bp].AVDP_dataType, ax
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	ObjMessage
	add	sp, size AddVarDataParams + size word
	retn

ObjMessageFixupDS:
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	retn
ProcessKbdStatus	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetKbdOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the OD of the floating kbd

CALLED BY:	GLOBAL
PASS:		*ds:si - GenApp
RETURN:		^lCX:DX <- OD of floating kbd 
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not STATIC_PEN_INPUT_CONTROL

GetKbdOD	proc	far	uses	ax, bx, bp, di, si, es
	.enter

;	Get the OD of the kbd to display.

	mov	ax, ATTR_GEN_APPLICATION_KBD_OBJ
	call	ObjVarFindData		
	jnc	createKbd		;If no kbd provided by the app,
					; create one.
	movdw	cxdx, ds:[bx]
if	ERROR_CHECK

;	Ensure that the object is a subclass of GenInteraction

	push	cx, dx
	movdw	bxsi, cxdx
	mov	cx, segment GenInteractionClass
	mov	dx, offset GenInteractionClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	cx, dx
	
	ERROR_NC	FLOATING_KEYBOARD_MUST_BE_SUBCLASS_OF_GEN_INTERACTION
endif
exit:
	.leave
	ret

createKbd:

;	Create a floating keyboard to display, and store the OD in vardata

	mov	dx, si
	mov	di, segment GenPenInputControlClass
	mov	es, di
	mov	di, offset GenPenInputControlClass
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate		;^lBX:SI <- GenPenInputControl object
					;^lBX:DX <- GenApplication object


	mov	ax, MSG_GEN_SET_NOT_ENABLED
	push	dx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	pop	dx

if (0)	; This is screwing things up (bug #33003). - Joon (5/7/95)
	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_INITIATE_WHEN_ENABLED or \
			mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
endif

	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_IS_FLOATING_KEYBOARD or mask VDF_SAVE_TO_STATE
	clr	cx			;Tell the pen input control that it is
	call	ObjVarAddData		; the special app-specific kbd

	xchg	dx, si
	mov	ax, ATTR_GEN_APPLICATION_KBD_OBJ or mask VDF_SAVE_TO_STATE
	mov	cx, size optr
	call	ObjVarAddData
	mov	cx, ds:[LMBH_handle]	;^lCX:DX <- GenPenInputControl object
	mov	ds:[bx].chunk, dx
	mov	ds:[bx].handle, cx
	mov	ax, si			;*ds:ax = GenApplication object
	mov	bx, mask OCF_VARDATA_RELOC	; set this, clear none
	call	ObjSetFlags

;	Add this object as a child of the app object

	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, mask CCF_DIRTY or CCO_FIRST
	call	ObjCallInstanceNoLock

	mov	si, dx			;*DS:SI <- GenPenInputControl object

;	Set the object usable, and not user initiatable

if 0
;
; 	We might be in the middle of a UserDoDialog, so the
;	MSG_GEN_INTERACTION_INITIATE may never get to the object. We tell
;	the object to get on the GAGCNLT_CONTROLLERS_WITHIN_USER_DO_DIALOGS
;	GCN list now, so it'll get the MSG_GEN_INTERACTION_INITIATE.
;
;	This is done automatically when I set the box usable
;
	mov	ax, MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
	call	ObjCallInstanceNoLock
endif

	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	mov	cl, GIV_DIALOG
	call	ObjCallInstanceNoLock

;	mov	ax, MSG_GEN_INTERACTION_SET_TYPE ;This makes the box so it 
;	mov	cl, GIT_MULTIPLE_RESPONSE	 ; cannot be closed by the
;	call	ObjCallInstanceNoLock		 ; user

;	Try it with no title, for now

if 0
	mov	bx, handle InitiatePenInputName
	call	MemLock
	mov	es, ax
	mov_tr	cx, ax
	mov	dx, es:[InitiatePenInputName]

	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_MANUAL
	call	ObjCallInstanceNoLock

	call	MemUnlock
endif

	mov	ax, MSG_GEN_INTERACTION_SET_ATTRS
	mov	cx, mask GIA_NOT_USER_INITIATABLE
	call	ObjCallInstanceNoLock

	mov   	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	jmp	exit
GetKbdOD	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BringDownKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings down the floating keyboard, if it exists.

CALLED BY:	GLOBAL
PASS:		*ds:si - gen app object
RETURN:		carry set if we brought down floating kbd
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not STATIC_PEN_INPUT_CONTROL
BringDownKeyboard	proc	far
	.enter

	; If an application object exists, tell it to go away

	mov	ax, ATTR_GEN_APPLICATION_KBD_OBJ
	call	ObjVarFindData
	jnc	exit

	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle

	; We only bring it down if it is enabled

	mov	ax, MSG_GEN_GET_ENABLED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jnc	exit

	; Bring up the box via the queue - the problem is that we may be in the
	; middle of the GAINED_FOCUS handler for some box, and bringing up/
	; taking down boxes now can confuse the application (To generate the
	; GAINED_FOCUS notifications, the app gets rid of the SYS exclusive,
	; sends the notification out, then grabs the SYS exclusive - if we
	; end up forcing the app object to grab the SYS exclusive from the
	; GAINED_FOCUS handler, then when we return and try to grab it again,
	; in FlowGrabWithinLevel, we die).

	call	HideKbd
	stc
exit:
	.leave
	ret
BringDownKeyboard	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles various standard notifications.

CALLED BY:	GLOBAL
PASS:		cx - ManufacturerID
		dx - NotificationType
		bp - data
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppNotify	method	GenApplicationClass, 
					MSG_META_NOTIFY,
					MSG_META_NOTIFY_WITH_DATA_BLOCK

	call	GenCheckIfSpecGrown		;Ignore this message if 
	jnc	callMeta			; shutting down.

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper

	cmp	dx, GWNT_HARD_ICON_BAR_FUNCTION
	je	doIconBarFunction

	cmp	dx, GWNT_STARTUP_INDEXED_APP
	je	startupIndexedApp

if not STATIC_PEN_INPUT_CONTROL
	cmp	dx, GWNT_FOCUS_WINDOW_KBD_STATUS
	je	bringUpOrBringDownFloatingKeyboard
endif

callSuper:
	mov	di, offset GenApplicationClass
	GOTO	ObjCallSuperNoLock

callMeta:
	mov	di, segment MetaClass
	mov	es, di
	mov	di, offset MetaClass
	GOTO	ObjCallClassNoLock

if not STATIC_PEN_INPUT_CONTROL
bringUpOrBringDownFloatingKeyboard:
	call	ProcessKbdStatus
	jmp	callSuper
endif
	
doIconBarFunction:
	call	informSPUI
	call	DoHardIconBarFunction
	jmp	callSuper

startupIndexedApp:
	call	informSPUI
	call	StartupIndexedApp
	jmp	callSuper

informSPUI	label	near
	;
	; let specific ui do some stuff (like close express menu)
	;
	push	ax, cx, dx, bp

		
	mov	di, offset GenClass
	call	ObjCallSuperNoLock
	pop	ax, cx, dx, bp
	retn

GenAppNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UIApplicationNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle hard icon bar for UIApp (when UI dialog has focus)

CALLED BY:	MSG_META_NOTIFY, MSG_META_NOTIFY_WITH_DATA_BLOCK

PASS:		*ds:si	= UIApplicationClass object
		ds:di	= UIApplicationClass instance data
		es 	= segment of UIApplicationClass
		ax	= MSG_META_NOTIFY, MSG_META_NOTIFY_WITH_DATA_BLOCK

		cx	= ManufacturerId
		dx	= NotificationType
		bp	= data

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/8/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UIApplicationNotify	method	dynamic	UIApplicationClass, MSG_META_NOTIFY,
						MSG_META_NOTIFY_WITH_DATA_BLOCK

	call	GenCheckIfSpecGrown		;Ignore this message if 
	jnc	callMeta			; shutting down.

	segmov	es, dgroup, di			; es <- dgroup

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_HARD_ICON_BAR_FUNCTION
	je	mightBeKeyboard
	cmp	dx, GWNT_STARTUP_INDEXED_APP
	je	sendToFirstRealApp

callSuper:
	mov	di, segment UIApplicationClass
	mov	es, di
	mov	di, offset UIApplicationClass
	GOTO	ObjCallSuperNoLock

beepCallMeta:
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
callMeta:
	mov	di, segment MetaClass
	mov	es, di
	mov	di, offset MetaClass
	GOTO	ObjCallClassNoLock

	;
	; We allow the keyboard to come up and down even if the password
	; screen is up.
	;
mightBeKeyboard:
	cmp	bp, HIBF_DISPLAY_FLOATING_KEYBOARD
	jne	notKeyboard

	;
	; If the focus of the System is us (the UIApp), then call our
	; superclass to have us handle the keyboard.  If not, then the
	; focus is the field, so get the field's top app.
	;
	push	ax, cx, dx, bp
	mov	ax, MSG_META_GET_FOCUS_EXCL
	call	UserCallSystem
	cmp	cx, ds:[OLMBH_header].LMBH_handle	; the UIApp block handle
	jne	skipChunkCheck
	cmp	dx, si			; the UIApp chunk handle
skipChunkCheck:
	pop	ax, cx, dx, bp
	je	callSuper
	jmp	sendToAppNoPasswordCheck

notKeyboard:

	tst	es:[passwordActive]
	jnz	beepCallMeta
	cmp	bp, HIBF_DISPLAY_HELP
	je	callSuper			; UIApp can handle help
	;
	; fall through to let first real app handle express menu, toggle menu
	; bar and floating keyboard
	;
sendToFirstRealApp:
	tst	es:[passwordActive]
	jnz	beepCallMeta

sendToAppNoPasswordCheck:
	push	ax, cx, dx, bp			; save message params
	mov	ax, MSG_GEN_SYSTEM_GET_DEFAULT_FIELD
	call	UserCallSystem			; ^lcx:dx = current field
	push	si
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_FIELD_GET_TOP_GEN_APPLICATION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ^lcx:dx = top app (or 0)
	pop	si
	movdw	bxdi, cxdx
	pop	ax, cx, dx, bp			; restore message params
	tst	bx
	jz	allowOnlyExpress		; no first app, let UIApp
						;	handle Express menu
	mov	si, di				; ^lbx:si = first app
	clr	di
	GOTO	ObjMessage

allowOnlyExpress:
	cmp	dx, GWNT_HARD_ICON_BAR_FUNCTION
	LONG jne	callMeta			; eat it
		CheckHack <HIBF_TOGGLE_EXPRESS_MENU eq 0>
	tst	bp			; see if bp = HIBF_TOGGLE_EXPRESS_MENU
	LONG jne	callMeta
	jmp	callSuper			; let super toggle express menu

UIApplicationNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UIApplicationQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_QUERY_IF_PRESS_IS_INK
PASS:		*ds:si	= UIApplicationClass object
		ds:di	= UIApplicationClass instance data
		ds:bx	= UIApplicationClass object (same as *ds:si)
		es 	= segment of UIApplicationClass
		ax	= message #
		CX, DX - position of START_SELECT

RETURN:		AX - InkReturnValue

		if AX = IRV_DESIRES_INK or IRV_INK_WITH_STANDARD_OVERRIDE,
				BP - handle of block with InkDestinationInfo
					- or -
				BP - 0
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if STATIC_PEN_INPUT_CONTROL
UIApplicationQueryIfPressIsInk	method dynamic UIApplicationClass, 
					MSG_META_QUERY_IF_PRESS_IS_INK
	call	GenCheckIfSpecGrown
	jnc	notGrown

	push	ax, cx, dx, si
	;
	; check if mouse press in SystemHWRBox bounds
	;
	movdw	axbx, cxdx
	call	VisQueryWindow			; di = our window
	tst	di
	jz	callSuper
	call	WinTransform			; (ax, bx) = screen coords
	push	ax, bx
	mov	bx, handle SystemHWRBox
	mov	si, offset SystemHWRBox
	mov	ax, MSG_VIS_QUERY_WINDOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cx = window, if any
	pop	si, bp				; (ax, bp) = mouse pos
	jcxz	callSuper
	mov	di, cx				; di = window
	call	WinGetWinScreenBounds		; (ax, cx) (bx, dx) = bounds
	jc	callSuper
	cmp	si, ax
	jl	callSuper
	cmp	si, cx
	jg	callSuper
	cmp	bp, bx
	jl	callSuper
	cmp	bp, dx
	jg	callSuper
	;
	; mouse press in SystemHWRBox bounds, send ink query to our
	; active or implied grab via VisContent
	;
	pop	ax, cx, dx, si
	call	VisContentQueryIfPressIsInk
	ret

callSuper:
	pop	ax, cx, dx, si
	mov	di, offset UIApplicationClass
	GOTO	ObjCallSuperNoLock

notGrown:
	mov	cx, IRV_NO_INK
	mov	ax, MSG_GEN_APPLICATION_INK_QUERY_REPLY
	GOTO	ObjCallInstanceNoLock

UIApplicationQueryIfPressIsInk	endm
endif

Ink ends



RemoveDisk		segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppRemovingDisk -- 
		MSG_META_REMOVING_DISK for GenApplicationClass

DESCRIPTION:	Notifies any apps or document controls that a disk is being
		removed.   Objects that originated from this disk will shut
		themselves down.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_REMOVING_DISK

		cx	- disk handle

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
	chris	4/16/93         Initial Version

------------------------------------------------------------------------------@

GenAppRemovingDisk	method dynamic	GenApplicationClass, 
					MSG_META_REMOVING_DISK
	;
	; Fetch the handle for the app's executable file from the core block.
	; 
	call	GeodeGetProcessHandle
	call	MemLock
	mov	es, ax
	clr	ax				; assume not open
	test	es:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN
	jz	checkHandle
	mov	ax, es:[GH_geoHandle]		; is open; fetch handle
checkHandle:
	call	MemUnlock

	mov_tr	bx, ax
	tst	bx
	jz	done

	call	FileGetDiskHandle
	cmp	cx, bx
	je	quitApp				;no match, exit
done:
	ret

quitApp:

;	We don't want to create a state file, but we also don't want to
;	be able to abort the shutdown, so mimic a QUIT by setting the quit
;	flag, but send DETACH to the process instead, so there won't be
;	any aborting allowed.

	ornf	ds:[di].GAI_states, mask AS_QUITTING
	call	GeodeGetProcessHandle
	mov	ax, MSG_META_DETACH		;quit, without saving state.
	clr	cx, dx, bp
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage
GenAppRemovingDisk	endm



RemoveDisk		ends
