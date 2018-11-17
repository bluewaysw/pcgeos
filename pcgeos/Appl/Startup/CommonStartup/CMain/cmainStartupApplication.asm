COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Startup
FILE:		cmainStartupApplication.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/89		Initial version

DESCRIPTION:
	This file contains a Startup application

	$Id: cmainStartupApplication.asm,v 1.1 97/04/04 16:52:16 newdeal Exp $

------------------------------------------------------------------------------@

;##############################################################################
;	Initialized data
;##############################################################################

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

	StartupApplicationClass
	StartupFieldClass

idata	ends

;##############################################################################
;	Code
;##############################################################################

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupApplicationSwitchToApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept request from user for this app to be made active
		(Generally by selection from Express menu) to handle by
		forcing the main screen to appear.

CALLED BY:	GLOBAL
PASS:		*ds:si = StartupApp
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupApplicationSwitchToApp	method	StartupApplicationClass,
					MSG_STARTUP_APP_SWITCH_TO_STARTUP
	;
	; Reset return field.
	;
	mov	ax, MSG_STARTUP_APP_SET_RETURN_FIELD
	clr	cx, dx
	call	ObjCallInstanceNoLock
ifdef GPC
	;
	; GPC version defaults to CUI
	;
	mov	cx, SF_FIELD1
	mov	ax, MSG_STARTUP_PROCESS_GOTO_FIELD
	mov	bx, handle 0
	clr	di
	GOTO	ObjMessage
else
	;
	; make overview primary usable
	;
	push	si
	mov	bx, handle StartupWindow
	mov	si, offset StartupWindow
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	si

ifdef ISTARTUP
	call	StartupApplicationSetDefaultRoom
endif
	;
	; bring Startup app to top
	;
	mov	ax,  MSG_GEN_BRING_TO_TOP
	call	ObjCallInstanceNoLock
	;
	; bring parent field to top
	; XXX: might cause undesired restore-apps
	;
	mov	ax,  MSG_GEN_BRING_TO_TOP
	GOTO	GenCallParent
endif

StartupApplicationSwitchToApp	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupApplicationSetDefaultRoom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to set the default on one of the room triggers.

CALLED BY:	StartupApplicationSwitchToApp
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	2/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

StartupApplicationSetDefaultRoom	proc	near
	uses	ds, si
	.enter

	mov	bx, handle IniStrings		;Lock resource
	call	MemLock
	mov	ds, ax
	assume	ds:IniStrings
	mov_tr	cx, ax				;cx = IniStrings segment
	mov	dx, ds:[DefaultRoomKeyString]	;CX:DX <- key string
	mov	si, ds:[CategoryString]		;DS:SI <- category string
	mov	di, offset initRoomBuf		;ES:DI <- ptr to dest for str.
	mov	bp, INITFILE_DOWNCASE_CHARS or 2;Only get first char + null
	call	InitFileReadString
	mov	bx, handle IniStrings
	call	MemUnlock

	mov	al, 0
	xchg	al, es:[initRoomBuf][0]		;AL <- First char of string

ifdef MOUSETUTORIAL
	jc	mouse				;if string not found,
						; mouse tut should have focus
endif
	mov	cx, handle Room1
	mov	dx, offset Room1		;assume room 1
	cmp	al, '1'
	je	grabFocus

	mov	cx, handle Room2
	mov	dx, offset Room2		;assume room 2
	cmp	al, '2'
	je	grabFocus

	mov	cx, handle Room3
	mov	dx, offset Room3		;assume room 3

ifdef MOUSETUTORIAL
	cmp	al, '3'
	je	grabFocus

mouse:
	mov	cx, handle MouseTutTrigger	;default to mouse tutorial
	mov	dx, offset MouseTutTrigger
endif

grabFocus:
	movdw	bxsi, cxdx
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
StartupApplicationSetDefaultRoom	endp

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupApplicationQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify logout, and logout the user.  If logout is confirmed,
		decide on whether to do a slow or fast logout.  If Wizard is
		being run from Windows, then do a slow logout. Otherwise look
		at the slowLogout key in the initfile.

CALLED BY:	GLOBAL
PASS:		*ds:si = StartupApp
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/92	Initial version
	Chung	5/5/93		Slow/Fast login, Windows support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef ISTARTUP	; not ISTARTUP ------------------------------------------------

StartupApplicationQuit	method	StartupApplicationClass, MSG_META_QUIT

	;
	; do an exit-to-DOS via parent field
	;
	push	si
	mov	ax,  MSG_GEN_FIELD_EXIT_TO_DOS
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = event
	pop	si
	mov	cx, di			; cx = event
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	GOTO	ObjCallInstanceNoLock

StartupApplicationQuit	endm

endif		; ifndef ISTARTUP ---------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupApplicationAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab target excl when IStartup starts up.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= StartupApplicationClass object
		ds:di	= StartupApplicationClass instance data
		ds:bx	= StartupApplicationClass object (same as *ds:si)
		es 	= segment of StartupApplicationClass
		ax	= message #
		dx	= AppLaunchBlock
		bp	= Extra state block from state file, or 0 if none.
		  	  This is the same block as returned from
		  	  MSG_GEN_PROCESS_CLOSE_APPLICATION, in some previous
			  detach
RETURN:		AppLaunchBlock - preserved
		extra state block - preserved
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

StartupApplicationAttach	method dynamic StartupApplicationClass, 
					MSG_META_ATTACH
	mov	di, offset StartupApplicationClass
	call	ObjCallSuperNoLock
	;
	; Bring IStartup to top to ensure that the SystemField0 will have
	; a target so it won't start shutting down when you logout after
	; exiting to DOS with the PrinterControlPanel open.
	;
	mov	ax, MSG_GEN_BRING_TO_TOP
	GOTO	ObjCallInstanceNoLock

StartupApplicationAttach	endm

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupApplicationFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent user from quitting IStartup by disabling F3 (Quit).
		Allow user to logout (Quit) by pressing ESC.
		Allow user to run mouse tutorial by pressing 'M' or 'm'.

CALLED BY:	MSG_META_FUP_KBD_CHAR
PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_FUP_KBD_CHAR
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef WELCOME	;--------------------------------------------------------------

StartupApplicationFupKbdChar	method dynamic StartupApplicationClass, 
					MSG_META_FUP_KBD_CHAR

	; Check F9, F10, F11, F12 and consume them so the index apps 
	; don't get launched in this field.

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	callSuper
	test	dl, mask CF_FIRST_PRESS
	jz	callSuper
	tst	dh
	jnz	callSuper

SBCS <	cmp	cx, VC_F9 or (CS_CONTROL shl 8)				>
DBCS <	cmp	cx, C_SYS_F9						>
	je	consume
SBCS <	cmp	cx, VC_F10 or (CS_CONTROL shl 8)			>
DBCS <	cmp	cx, C_SYS_F10						>
	je	consume
SBCS <	cmp	cx, VC_F11 or (CS_CONTROL shl 8)			>
DBCS <	cmp	cx, C_SYS_F11						>
	je	consume
SBCS <	cmp	cx, VC_F12 or (CS_CONTROL shl 8)			>
DBCS <	cmp	cx, C_SYS_F12						>
	je	consume

callSuper:
	mov	di, offset StartupApplicationClass
	GOTO	ObjCallSuperNoLock

consume:
	stc						;consumed here
	ret
StartupApplicationFupKbdChar	endm

endif ; WELCOME ---------------------------------------------------------------

ifdef ISTARTUP	;--------------------------------------------------------------

StartupApplicationFupKbdChar	method dynamic StartupApplicationClass, 
					MSG_META_FUP_KBD_CHAR
	test	es:[keySequenceMode], mask KSM_EDLAN or mask KSM_LOGOUT_QUERY
	jnz	done			; ignore all fup's if we're busy

	tst	dh					;if ShiftState
	jnz	callSuper				; then call superclass

	test	dl, mask CF_FIRST_PRESS			;if not first press
	jz	callSuper				; then call superclass

	cmp	cx, VC_F3 or (VC_ISCTRL shl 8)		;if F3 and no ShiftSt
	je	done					; then eat it.. yummy.

	cmp	cx, VC_ESCAPE or (VC_ISCTRL shl 8)	; if ESC and no ShiftSt
	jne	notESC

	mov	ax, MSG_GEN_APPLICATION_GET_MODAL_WIN
	call	ObjCallInstanceNoLock			; don't bring up logout
	tst	cx					;  dialog if we already
	jnz	callSuper				;  have a modal dialog.

	mov	ax, MSG_STARTUP_APP_LOGOUT		; logout
	mov	cx, TRUE				; query user
	GOTO	ObjCallInstanceNoLock

notESC:

ifdef MOUSETUTORIAL
	cmp	cx, 'm'					; if 'm'
	je	runMouseTut				;  run mouse tutorial
	cmp	cx, 'M'					; if 'M'
	jne	callSuper				;  run mouse tutorial

runMouseTut:
	mov	ax, MSG_STARTUP_MOUSE_TUTORIAL
	call	GeodeGetProcessHandle			; bx = process handle
	clr	di
	GOTO	ObjMessage
endif

callSuper:
	mov	ax, MSG_META_FUP_KBD_CHAR
	mov	di, offset StartupApplicationClass
	GOTO	ObjCallSuperNoLock
done:
	ret
StartupApplicationFupKbdChar	endm

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupApplicationLogout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify logout, and logout the user.  If logout is confirmed,
		decide on whether to do a slow or fast logout.  If Wizard is
		being run from Windows, then do a slow logout. Otherwise look
		at the slowLogout key in the initfile.

CALLED BY:	MSG_STARTUP_APP_LOGOUT
PASS:		*ds:si	= StartupApplicationClass object
		ds:di	= StartupApplicationClass instance data
		ds:bx	= StartupApplicationClass object (same as *ds:si)
		es 	= segment of StartupApplicationClass
		ax	= message #
		cx	= TRUE or FALSE (should we query user?)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	4/30/93   	Initial version
	Chung	5/5/93		Slow/Fast login, Windows support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

loginCategoryStr	char	"login", 0
slowLogoutKeyStr	char	"slowLogout", 0
windowsDosVariableStr	char	"W", 0

StartupApplicationLogout	method dynamic StartupApplicationClass, 
					MSG_STARTUP_APP_LOGOUT
	;
	; Should we query user?
	;
	tst	cx
	jz	logout
	;
	; Query user
	;
	ORNF	es:[keySequenceMode], mask KSM_LOGOUT_QUERY

	push	ds:[LMBH_handle]
	call	IclasQueryForLogout
	pop	bx
	call	MemDerefDS

	ANDNF	es:[keySequenceMode], not mask KSM_LOGOUT_QUERY
	cmp	ax, IC_YES
	LONG jne done

logout:
	;
	; Tell iclas (and thereby the verify thread) that we want to logout
	;
	call	IclasSetAbort

	;
	; Reset our return field
	;
	mov     ax, MSG_STARTUP_APP_SET_RETURN_FIELD
	clr     cx, dx
	call	ObjCallInstanceNoLock
	;
	; Check if we are logged in through a passthru, and should 
	; return to the original server via slow logout.  If the environment
	; variable S is of length > 0, then we should do a slow logout.
	;
	push	ds, si, es, di
	segmov	ds, cs
	mov	si, offset cs:[sVarStr]
	segmov	es, dgroup, di
	mov	di, offset initRoomBuf	; es:di = 2 byte buffer
	mov	cx, 2			; we only check the first byte because
					; all we want to know is if the 
					; variable is not NULL.
	call	SysGetDosEnvironment
	mov	cl, es:[di]
	pop	ds, si, es, di
	jc	checkWin
	tst	cl
	jnz	slowLogout
checkWin:
	;
	; Check if we are being run from Windows. The DOS environment 
	; variable W is 1 if Windows is running.
	;
	push	ds, si
	segmov	ds, cs
	mov	si, offset cs:[windowsDosVariableStr]
	segmov	es, dgroup, di
	mov	di, offset initRoomBuf	; es:di = 2 byte buffer
	mov	cx, 2
	call	SysGetDosEnvironment
	pop	ds, si
	jc	checkSlowLogoutKey

	cmp	{byte} es:[di], '1'	; looking for W = "1"
	je	slowLogout

checkSlowLogoutKey:
	;
	; check for the slowLogout key under the [login] category.
	;
	push	ds, si
	mov	cx, cs
	mov	dx, offset cs:[slowLogoutKeyStr]
	mov	ds, cx
	mov	si, offset cs:[loginCategoryStr]
	call	InitFileReadBoolean
	pop	ds, si
	jc	fastLogout
	tst	ax
	jz	fastLogout

slowLogout:
	mov	ax, SST_CLEAN
	clr	cx, dx, bp
	call	SysShutdown
	ret				; <==== RETURN HERE

fastLogout:
	;
	; Return to login field.
	;
	mov	ax, MSG_STARTUP_OPEN_FIELD
	mov	bx, handle 0
	mov	cx, handle LoginRoomField
	mov	dx, offset LoginRoomField
	clr	di
	GOTO	ObjMessage
done:
	ret
StartupApplicationLogout	endm

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupApplicationSetReturnField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the field we should return to after a shutdown to DOS.

CALLED BY:	MSG_STARTUP_APP_SET_RETURN_FIELD
PASS:		*ds:si	= StartupApplicationClass object
		ds:di	= StartupApplicationClass instance data
		ds:bx	= StartupApplicationClass object (same as *ds:si)
		es 	= segment of StartupApplicationClass
		ax	= message #
		^lcx:dx	= field to return to after a shutdown to DOS
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	12/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupApplicationSetReturnField	method dynamic StartupApplicationClass,
					MSG_STARTUP_APP_SET_RETURN_FIELD
ifdef ISTARTUP
	cmp	cx, handle LoginRoomField
	jne	setField
	clrdw	cxdx

setField:
endif
	movdw	ds:[di].returnField, cxdx

ifdef ISTARTUP
	mov	di, offset initRoomBuf		;ES:DI <- ptr to dest for str.
	mov	{word} es:[di], '1'
	cmp	cx, handle Room1Field
	je	writeIni
	mov	{word} es:[di], '2'
	cmp	cx, handle Room2Field
	je	writeIni
	mov	{word} es:[di], '3'
	cmp	cx, handle Room3Field
	jne	done

writeIni:
	mov	bx, handle IniStrings		;Lock resource
	call	MemLock
	mov	ds, ax
	assume	ds:IniStrings
	mov	si, ds:[CategoryString]		;DS:SI <- category string
	mov	cx, ds
	mov	dx, ds:[DefaultRoomKeyString]	;CX:DX <- key string
	call	InitFileWriteString
	mov	bx, handle IniStrings
	call	MemUnlock
done:
endif
	;
	; similar to above, but use StartupRoomKeyString instead of
	; DefaultRoomKeyString
	;
ifdef GPC
	mov	bp, 1
	cmp	cx, handle Room1Field
	je	writeIni
	inc	bp				;bp = 2
	cmp	cx, handle Room2Field
	je	writeIni
	inc	bp				;bp = 3
	cmp	cx, handle Room3Field
	jne	done

writeIni:
	mov	bx, handle IniStrings		;Lock resource
	call	MemLock
	mov	ds, ax
	assume	ds:IniStrings
	mov	si, ds:[CategoryString]		;DS:SI <- category string
	mov	cx, ds
	mov	dx, ds:[StartupRoomKeyString]	;CX:DX <- key string
	call	InitFileWriteInteger
	mov	bx, handle IniStrings
	call	MemUnlock
done:
endif
	ret
StartupApplicationSetReturnField	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupApplicationGetReturnField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the field we should return to.

CALLED BY:	MSG_STARTUP_APP_GET_RETURN_FIELD
PASS:		*ds:si	= StartupApplicationClass object
		ds:di	= StartupApplicationClass instance data
		ds:bx	= StartupApplicationClass object (same as *ds:si)
		es 	= segment of StartupApplicationClass
		ax	= message #
RETURN:		if there is a field we should return to,
			carry set, ^lcx:dx = field to return to
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	12/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupApplicationGetReturnField	method dynamic StartupApplicationClass,
					MSG_STARTUP_APP_GET_RETURN_FIELD
	movdw	cxdx, ds:[di].returnField, cxdx
	tstdw	cxdx
	jz	done
	stc			; set carry to indicate that we have a field
done:
	ret
StartupApplicationGetReturnField	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupAppKeyboardDriverChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle keyboard message sent by Keyboard driver

CALLED BY:	MSG_STARTUP_APP_KEYBOARD_DRIVER_CHAR
PASS:		*ds:si	= StartupApplicationClass object
		ds:di	= StartupApplicationClass instance data
		ds:bx	= StartupApplicationClass object (same as *ds:si)
		es 	= segment of StartupApplicationClass
		ax	= message #
		
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	
		Be careful with what's on the stack

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

SCANCODE_CR	=	1ch
SCANCODE_SPACE	=	39h

StartupAppKeyboardDriverChar	method dynamic StartupApplicationClass, 
					MSG_STARTUP_APP_KEYBOARD_DRIVER_CHAR
	pushdw	es:[keyboardDriverStrategy]	; push strategy routine

	;
	; We end EDLan mode when we get a carriage return or a space.
	;
	cmp	cx, SCANCODE_CR
	je	removeHotkey
;	cmp	cx, SCANCODE_SPACE
;	je	removeHotkey

	mov	di, DR_KBD_PASS_HOTKEY
	retf					; call keyboard driver

removeHotkey:
	ANDNF	es:[keySequenceMode], not (mask KSM_EDLAN)

	mov	di, DR_KBD_REMOVE_HOTKEY
	clr	ax
	mov	cx, (VC_ISCTRL shl 8) or VC_INVALID_KEY
	call	es:[keyboardDriverStrategy]	; call keyboard driver

	mov	di, DR_KBD_CANCEL_HOTKEY
	retf					; call keyboard driver

StartupAppKeyboardDriverChar	endm

endif		;--------------------------------------------------------------



;==============================================================================
;			StartupFieldClass
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupFieldLogoutConfirmationResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We intercept this internal message so we can do either a
		fast logout or a slow logout.

CALLED BY:	MSG_GEN_FIELD_EXIT_TO_DOS_CONFIRMATION_RESPONSE
PASS:		*ds:si	= StartupFieldClass object
		ds:di	= StartupFieldClass instance data
		ds:bx	= StartupFieldClass object (same as *ds:si)
		es 	= segment of StartupFieldClass
		ax	= message #
		cx	= InteractionCommand (IC_YES or IC_NO)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

StartupFieldLogoutConfirmationResponse	method dynamic StartupFieldClass, 
				MSG_GEN_FIELD_EXIT_TO_DOS_CONFIRMATION_RESPONSE
	cmp	cx, IC_YES
	LONG jne done
	;
	; Reset our return field
	;
	push	si
	mov	bx, handle StartupApp
	mov	si, offset StartupApp
	mov     ax, MSG_STARTUP_APP_SET_RETURN_FIELD
	clr     cx, dx
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call    ObjMessage
	pop	si
	;
	; Check if we are logged in through a passthru, and should 
	; return to the original server via slow logout.  If the environment
	; variable S is of length > 0, then we should do a slow logout.
	;
	push	ds, si, es, di
	segmov	ds, cs
	mov	si, offset cs:[sVarStr]
	segmov	es, dgroup, di
	mov	di, offset initRoomBuf	; es:di = 2 byte buffer
	mov	cx, 2			; we only check the first byte because
					; all we want to know is if the 
					; variable is not NULL.
	call	SysGetDosEnvironment
	mov	cl, es:[di]
	pop	ds, si, es, di
	jc	checkWin
	tst	cl
	jnz	slowLogout

checkWin:	
	;
	; Check if we are being run from Windows. The DOS environment 
	; variable W is 1 if Windows is running.
	;
	push	ds, si, es, di
	segmov	ds, cs
	mov	si, offset cs:[windowsDosVariableStr]
	segmov	es, dgroup, di
	mov	di, offset initRoomBuf	; es:di = 2 byte buffer
	mov	cx, 2
	call	SysGetDosEnvironment
	mov	cl, es:[di]
	pop	ds, si, es, di
	jc	checkSlowLogoutKey

	cmp	cl, '1'			; looking for W = "1"
	je	slowLogout

checkSlowLogoutKey:
	;
	; check for the slowLogout key under the [login] category.
	;
	push	ds, si
	mov	cx, cs
	mov	dx, offset cs:[slowLogoutKeyStr]
	mov	ds, cx
	mov	si, offset cs:[loginCategoryStr]
	call	InitFileReadBoolean
	pop	ds, si
	jc	fastLogout
	tst	ax
	jz	fastLogout

slowLogout:
	;
	; Do slow logout by calling superclass
	;
	mov	ax, MSG_GEN_FIELD_EXIT_TO_DOS_CONFIRMATION_RESPONSE
	mov	cx, IC_YES
	mov	di, offset StartupFieldClass
	GOTO	ObjCallSuperNoLock

fastLogout:
	;
	; Logout by closing this field and returning to the login field.
	;
	mov	ax, MSG_GEN_FIELD_ABOUT_TO_CLOSE
	GOTO	ObjCallInstanceNoLock
done:
	ret
StartupFieldLogoutConfirmationResponse	endm
sVarStr		char	"S", C_NULL

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupFieldNotifyNoFocusWithinNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to turn off the GFF_NEED_DEFAULT_LAUNCHER flag so
		wshellba will be restored from state when we log back in.
		(needed only for Unguided, since Guided does not save state.)

CALLED BY:	MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE
PASS:		*ds:si	= StartupFieldClass object
		ds:di	= StartupFieldClass instance data
		ds:bx	= StartupFieldClass object (same as *ds:si)
		es 	= segment of StartupFieldClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

StartupFieldNotifyNoFocusWithinNode	method dynamic StartupFieldClass, 
				MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE
	mov	di, offset StartupFieldClass
	call	ObjCallSuperNoLock

	cmp	ds:[LMBH_handle], handle Room3Field
	jne	done

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].GFI_flags, not mask GFF_NEED_DEFAULT_LAUNCHER
done:
	ret
StartupFieldNotifyNoFocusWithinNode	endm

endif		;--------------------------------------------------------------

ifdef WELCOME	;--------------------------------------------------------------

StartupFieldNotifyNoFocusWithinNode	method dynamic StartupFieldClass, 
				MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE
appToken	local	GeodeToken
	.enter
	push	bp
	mov	di, offset StartupFieldClass
	call	ObjCallSuperNoLock
	pop	bp
	;
	; if there's only one app left (CUIApp), give it the focus
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GFI_genApplications
	mov	di, ds:[di]
	cmp	di, -1
	je	done			; empty chunk
	ChunkSizePtr	ds, di, ax
	cmp	ax, size optr
	je	giveFocus
	;
	; if only two, and one is dialer, focus the other (CUIApp)
	;
	cmp	ax, (size optr)*2
	jne	done
	push	di
	add	di, size optr		; point to second
	call	checkIfDialer		; check if second is dialer
	pop	di
	je	giveFocus		; yes, give focus to first
	call	checkIfDialer		; check if first is dialer
	jne	done			; neither is dialer
	add	di, size optr		; first is dialer, give focus to second
giveFocus:
	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk
	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	di, mask MF_FORCE_QUEUE
	push	bp
	call	ObjMessage
	pop	bp
done:
	.leave
	ret

;
; pass: ds:[di] = optr to check
;
checkIfDialer	label	near
	push	ax, bx, es, di
	mov	bx, ds:[di].handle
	call	MemOwner
	segmov	es, ss, di
	lea	di, appToken
	mov	ax, GGIT_TOKEN_ID
	call	GeodeGetInfo
	cmp	{word}es:[di].GT_chars, 'I' or ('D' shl 8)
	jne	notDialer
	cmp	{word}es:[di].GT_chars[2], 'I' or ('A' shl 8)
	jne	notDialer
	cmp	es:[di].GT_manufID, MANUFACTURER_ID_GEOWORKS
notDialer:
	pop	ax, bx, es, di
	retn
StartupFieldNotifyNoFocusWithinNode	endm

endif		;--------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupFieldVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't draw background bitmap when starting up AUI since
		it'll draw for us.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= StartupFieldClass object
		ds:di	= StartupFieldClass instance data
		ds:bx	= StartupFieldClass object (same as *ds:si)
		es 	= segment of StartupFieldClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		CUI has no BG bitmap, so just do for all fields

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/14/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef WELCOME	;--------------------------------------------------------------

StartupFieldVisDraw	method dynamic StartupFieldClass, MSG_VIS_DRAW
	;
	; if there's nothing here yet, don't draw BG
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GFI_processes
	mov	di, ds:[di]
	cmp	di, -1
	je	done			; empty chunk
	;
	; let superclass draw BG bitmap, if any
	;
	mov	di, offset StartupFieldClass
	call	ObjCallSuperNoLock
done:
	ret
StartupFieldVisDraw	endm

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupFieldStartSetUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off the GFF_HAS_DEFAULT_LAUNCHER flag so default
		launcher doesn't start, then open field and start set up
		app, and then restore GFF_HAS_DEFAULT_LAUNCHER flag so
		when set up finishes, default launcher will start

CALLED BY:	MSG_STARTUP_FIELD_START_SET_UP_IF_NEEDED
PASS:		*ds:si	= StartupFieldClass object
		ds:di	= StartupFieldClass instance data
		ds:bx	= StartupFieldClass object (same as *ds:si)
		es 	= segment of StartupFieldClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/9/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef GPC ;--------------------------------------------------------------

StartupFieldStartSetUp	method dynamic StartupFieldClass, 
				MSG_STARTUP_FIELD_START_SET_UP
	;
	; turn off GFF_HAS_DEFAULT_LAUNCHER
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].GFI_flags, not mask GFF_HAS_DEFAULT_LAUNCHER
	ret
StartupFieldStartSetUp	endm

StartupFieldFinishSetUp	method dynamic StartupFieldClass, 
				MSG_STARTUP_FIELD_FINISH_SET_UP
	;
	; restore GFF_HAS_DEFAULT_LAUNCHER so when set up app exits, we'll
	; start default launcher
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].GFI_flags, mask GFF_HAS_DEFAULT_LAUNCHER or \
		mask GFF_LOAD_DEFAULT_LAUNCHER_WHEN_NEXT_PROCESS_EXITS
	ret
StartupFieldFinishSetUp	endm

StartupFieldCleanUpSetUp	method dynamic StartupFieldClass, 
				MSG_STARTUP_FIELD_CLEAN_UP_SET_UP
	;
	; restore GFF_HAS_DEFAULT_LAUNCHER on error
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].GFI_flags, mask GFF_HAS_DEFAULT_LAUNCHER
	ret
StartupFieldCleanUpSetUp	endm

endif		;--------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupFieldRestoreApps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that the default launcher for each field is
		running in the event of a restore-from-state. This
		fixes a probem in the CUIApp which does not have a
		state file.

CALLED BY:	MSG_GEN_FIELD_RESTORE_APPS
PASS:		*ds:si	= StartupFieldClass object
		ds:di	= StartupFieldClass instance data
		ds:bx	= StartupFieldClass object (same as *ds:si)
		es 	= segment of StartupFieldClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/23/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef GPC ;--------------------------------------------------------------

StartupFieldRestoreApps	method dynamic StartupFieldClass, 
				MSG_GEN_FIELD_RESTORE_APPS
	;
	; first let our superclass do most of the work
	;
	mov	di, offset StartupFieldClass
	call	ObjCallSuperNoLock

	;
	; then if no express menu (CUI), ensure the default launcher is
	; running
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GFI_flags, mask GFF_NEEDS_WORKSPACE_MENU
	jz	ensureDefaultLauncher
	ret

ensureDefaultLauncher:
	mov	ax, MSG_GEN_FIELD_LOAD_DEFAULT_LAUNCHER
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage
StartupFieldRestoreApps	endm

endif		;--------------------------------------------------------------

CommonCode	ends
