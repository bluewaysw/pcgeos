COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		saverPassword.asm

AUTHOR:		Gene Anderson, Apr 16, 1991

ROUTINES:
	Name			Description
	----			-----------
    INT SaverPasswordMonitor	Make sure keystrokes we don't want to go
				through, don't.

    INT SaverEnsurePasswordBlock Make sure we've duplicated the necessary
				resource for asking the user for a
				password.

    INT SaverPasswordDisplayError Put up the 'incorrect password' DB

    EXT	SPCheckNetwork		See if a network from which we can obtain
				a password is active.

   MTHD	MSG_SAVER_APP_LOCK_SCREEN
   MTHD	MSG_SAVER_APP_UNLOCK_SCREEN

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/16/91		Initial revision
	stevey	1/7/93		port to 2.0

DESCRIPTION:

	Password-related handlers and routines.

	$Id: saverPassword.asm,v 1.1 97/04/07 10:44:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

;
; Input monitor for password-protection
;
passwordMonitor	Monitor	<>

FXIP <SaverFixedCode segment resource					>
SaverContentClass	; ye olde class record
FXIP <SaverFixedCode	ends						>
idata	ends

SaverFixedCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverPasswordMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure keystrokes we don't want to go through, don't.

CALLED BY:	im::ProcessUserInput

PASS:		al	= mask MF_DATA
		di	= event type
		MSG_META_KBD_CHAR:
			cx	= character value
			dl	= CharFlags
			dh	= ShiftState
			bp low	= ToggleState
			bp high = scan code
		METHOD_PTR_CHANGE:
			cx	= pointer X position
			dx	= pointer Y position
			bp<15>	= X-is-absolute flag
			bp<14>	= Y-is-absolute flag
			bp<0:13>= timestamp
		si	= event data

RETURN:		al	= mask MF_DATA if event is to be passed through
			  0 if we've swallowed the event

DESTROYED:	ah, bx, ds, es (possibly)
		cx, dx, si, bp (if event swallowed)
		
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/14/91		Initial version
	stevey	1/7/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverPasswordMonitor	proc	far
	.enter

	test	al, mask MF_DATA
	jz	done
	cmp	di, MSG_META_KBD_CHAR
	jne	done
	
if DBCS_PCGEOS
	cmp	cx, C_SYS_F2
	je	swallow
ifdef GPC
	cmp	cx, C_SYS_F4
else
	cmp	cx, C_SYS_F3
endif
	je	swallow
	cmp	cx, C_SYS_ESCAPE
	je	swallow
	cmp	cx, C_SYS_SYSTEM_RESET
	je	swallow
else
	cmp	ch, CS_CONTROL		; anything but control chars we 
	jne	done			;  let through unconditionally.
	
	;
	; These are a few of my (least) favorite things...
	;

	cmp	cl, VC_F2
	je	swallow
ifdef GPC
	cmp	cl, VC_F4
else
	cmp	cl, VC_F3
endif
	je	swallow
	cmp	cl, VC_ESCAPE
	je	swallow
	cmp	cl, VC_SYSTEMRESET
	je	swallow
endif
done:
	.leave
	ret

swallow:
	clr	al			; munch
	jmp	short	done

SaverPasswordMonitor	endp
SaverFixedCode	ends

SaverOptionCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPCheckNetwork
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there's a network active from which we can get
		a password.

CALLED BY:	(EXTERNAL) SALoadOptions
PASS:		nothing
RETURN:		carry set if network exists
		carry clear if either network not active, or we can't
			get a password from it.
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SPCheckNetwork	proc	far
		uses	ds, si, ax
		.enter

	;
	; See if we can get the user login name
	;
		sub	sp, (size NetLoginNameZT)
		segmov	ds, ss
		mov	si, sp
		mov	ax, enum NetUserGetLoginName
		call	SaverCallNetLib
		lea	sp, ds:[si+(size NetLoginNameZT)]
		cmc

		.leave
		ret
SPCheckNetwork	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverCallNetLib
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to call the dynamically loaded net library

CALLED BY:	SPCheckNetwork(), SACheckPassword()
PASS:		ax - enum of net library routine to call
		rest depends on function
RETURN:		carry - set if error (undefined for NetVerifyUserPassword)
		depends on function
DESTROYED:	depends on function

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EC <LocalDefNLString	netLibName <"EC Net Library",0>			>
NEC <LocalDefNLString	netLibName <"Net Library",0>			>

SaverCallNetLib		proc	near
		uses	bx
		.enter

	;
	; Try loading the library
	;
		push	ax, ds, si
		call	FilePushDir
		mov	ax, SP_SYSTEM		;ax <- StandardPath
		call	FileSetStandardPath
		segmov	ds, cs
		mov	si, offset netLibName	;ds:si <- library name
		clr	ax, bx			;ax, bx <- expected protocol
		call	GeodeUseLibrary
		call	FilePopDir		;preserves flags
		pop	ax, ds, si
		jc	exitError		;branch if error
	;
	; Call the library
	;
		push	bx
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable
		pop	bx
	;
	; Unload the library
	;
		pushf				;save flags from library call
		call	GeodeFreeLibrary
		popf
exitError:

		.leave
		ret
SaverCallNetLib		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverEnsurePasswordBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we've duplicated the necessary resource for
		asking the user for a password.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= SaverApplication object
RETURN:		bx	= password block
DESTROYED:	nothing
SIDE EFFECTS:	resource is created and generic child added to app object,
     			if none created before.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverEnsurePasswordBlock proc	near
		class	SaverApplicationClass
		uses	ax, cx, dx, si, di, bp
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		mov	bx, ds:[di].SAI_passwordBlock
		tst	bx
		jnz	done
	;
	; Make a copy of the password-dialog resource for ourselves.
	;
		clr	ax, cx				; own by current thread
		mov	bx, handle SaverUnlock
		call	ObjDuplicateResource		; ^bx = new block
		mov	ds:[di].SAI_passwordBlock, bx
	;
	; Attach the password dialog to the generic tree (as our child).
	;
		mov	cx, bx
		mov	dx, offset SaverUnlock		; ^lcx:dx = dialog
		clr	bp				; flags
		mov	ax, MSG_GEN_ADD_CHILD
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
SaverEnsurePasswordBlock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SALockScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up sysmodal dialog for getting password from user.

CALLED BY:	SAStop

PASS:		*ds:si = SaverApplication object
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- empty the password text-object
	- bring up the password sys-modal dialog
	- fire up an input monitor

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/14/91		Initial version
	stevey	1/7/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SALockScreen	method dynamic SaverApplicationClass, MSG_SAVER_APP_LOCK_SCREEN
		class	SaverApplicationClass
		.enter

		ornf	ds:[di].SAI_state, mask SSF_SCREEN_LOCKED
		call	SaverEnsurePasswordBlock
	;
	; Set up RectDWord for setting document bounds of the view.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		mov	ax, ds:[di].SAI_bounds.R_bottom
		cwd
		pushdw	dxax

		mov	ax, ds:[di].SAI_bounds.R_right
		cwd
		pushdw	dxax

		mov	ax, ds:[di].SAI_bounds.R_top
		cwd
		pushdw	dxax

		mov	ax, ds:[di].SAI_bounds.R_left
		cwd
		pushdw	dxax
	;
	; Now set those bounds. This should cause the view (which is marked
	; as scale to fit) to scale things appropriately for our drawing
	; pleasure.
	; 
		mov	bp, sp
		mov	dx, size RectDWord
		mov	si, offset PasswordView
		mov	ax, MSG_GEN_VIEW_SET_DOC_BOUNDS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
		call	ObjMessage
		add	sp, size RectDWord
	;
	; Empty the unlock password text field so a hoser can't re-use the
	; hard work of the machine's owner...
	;
		mov	si, offset	PasswordUnlockText
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	ObjMessage
	;
	; Initiate the password dialog. When the content is told the
	; window has been created, that's when we'll start things rolling.
	; 
		mov	si, offset	SaverUnlock
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjMessage	

		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage
	;
	; Install an input monitor to filter various nasties out.
	;
		segmov	ds, dgroup, bx
		mov	bx, offset passwordMonitor
		mov	al, ML_DRIVER		; after the driver but before
						;  Welcome, heh
		mov	cx, segment SaverPasswordMonitor
		mov	dx, offset SaverPasswordMonitor
		call	ImAddMonitor

		.leave
		ret
SALockScreen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAUnlockScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop obstructing the user.

CALLED BY:	MSG_SAVER_APP_UNLOCK_SCREEN
PASS:		*ds:si	= SaverApplication object
		ds:di	= SaverApplicationInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	SSF_LOCK_SCREEN and SSF_SCREEN_LOCKED bits are cleared

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAUnlockScreen	method dynamic SaverApplicationClass, MSG_SAVER_APP_UNLOCK_SCREEN
		uses	bp
		.enter
		mov	bx, ds:[di].SAI_passwordBlock
		BitClr	ds:[di].SAI_state, SSF_SCREEN_LOCKED
		
	;
	; Stop the saver by hand, rather than waiting for the view to close, as
	; we need to be sure things stop before putting up the main screen
	; saver window again.
	; 
		mov	dx, ds:[di].SAI_curWindow
		mov	ax, MSG_SAVER_APP_UNSET_WIN
		call	ObjCallInstanceNoLock
		jnc	bringDownBox	; => wasn't current window, so gstate
					;  already gone

		mov	di, bp
		call	GrDestroyState
bringDownBox:
	;
	;  Dismiss the password interaction.
	;

		mov	si, offset SaverUnlock	; ^lbx:si = SaverUnlock dialog
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		call	ObjMessage

		mov	si, offset PasswordErrorGlyph
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	; Remove the input monitor that filters unhealthy keystrokes
	; 
		segmov	ds, dgroup, bx
		mov	al, mask MF_REMOVE_IMMEDIATE
		mov	bx, offset passwordMonitor
		call	ImRemoveMonitor

		.leave
		ret
SAUnlockScreen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACheckPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the password entered is valid.

CALLED BY:	MSG_SAVER_APP_CHECK_PASSWORD

PASS:		*ds:si = SaverApplication Object
		es = dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/14/91		Initial version
	stevey	1/7/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACheckPassword	method	dynamic	SaverApplicationClass, 
					MSG_SAVER_APP_CHECK_PASSWORD


SBCS <curPassword	local	SAVER_MAX_PASSWORD+1 dup(char)		>
DBCS <curPassword	local	SAVER_MAX_PASSWORD+1 dup(wchar)		>

userName	local	NetLoginName

		.enter

	;
	; Fetch what the user has typed.
	;

		push	bp, si				; stack frame
		mov	dx, ss
		lea	bp, ss:[curPassword]		; dx:bp = buffer

		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		mov	bx, ds:[di].SAI_passwordBlock
		mov	si, offset PasswordUnlockText
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage			; cx <- length

		pop	bp, si				; stack frame

	;
	; If on Novell, check network password(s)
	;

		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		test	ds:[di].SAI_mode, mask SMF_USE_NETWORK
		jz	noNetwork		; branch if not on network

	;
	;  We're on the network.  Get the user's login name and
	;  verify the password.  (We have to upcase the password first).
	;

		push	 ds:[LMBH_handle], si	; save app object

		segmov	ds, ss, si
		lea	si, ss:[userName]	; ds:si = buffer for name
		mov	ax, enum NetUserGetLoginName
		call	SaverCallNetLib

		segmov	es, ds, di
		mov	di, si			; es:di = user name
		call	LocalStringSize		; cx = string length w/o NULL
		mov	dl, cl			; dl = length of username

		segmov	es, ss, di
		lea	di, ss:[curPassword]	; es:di <- ptr to password

		call	LocalStringSize		; cx = password length
		mov	dh, cl			; dh = password length

		mov	ax, enum NetVerifyUserPassword
		call	SaverCallNetLib		; al = 0 if password matches
		pop	bx, si
		call	MemDerefDS		; *ds:si = saver app
		tst	al			; password correct?
		jnz	fail			; branch if failure
		jmp	short success		; branch if success

cantCreateCryptMachine:
		pop	ds, si
		jmp	fail

noNetwork:
	;
	; Compare against the password stored in our instance data
	;

		push	ds, si
		segmov	ds, ss
		lea	si, ss:[curPassword]	; ds:si <- key
		call	SaverCryptInit		; bx <- machine
		jc	cantCreateCryptMachine
		call	SaverCryptEncrypt	; encrypt the key itself
		call	SaverCryptEnd		; nuke the machine
		pop	ds, si

DBCS <		shl	cx, 1			; # chars -> # bytes	>
		cmp	cx, ds:[di].SAI_passwordLen
		jne	fail			; if not same length, can't
						;  match (done after encryption
						;  to make it take the same
						;  amount of time)
		push	si, es
		lea	si, ds:[di].SAI_password	; ds:si = stored
							;  password
		segmov	es, ss
		lea	di, ss:[curPassword]		; es:di = entered
							;  password

		repe	cmpsb
		pop	si, es				; *ds:si = saver app
		jne	fail

success:
	;
	; Success! Clear the LOCK_SCREEN bit (will be set next time on start
	; if necessary) and tell ourselves to unlock the screen.
	;
		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		BitClr	ds:[di].SAI_state, SSF_LOCK_SCREEN
		
		mov	ax, MSG_SAVER_APP_UNLOCK_SCREEN
		call	ObjCallInstanceNoLock

done:

		.leave
		ret
fail:
		call	SaverPasswordDisplayError
		jmp	short done

SACheckPassword	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverPasswordDisplayError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up the 'incorrect password' DB

CALLED BY:	SLCheckPassword()

PASS:		*ds:si = SaverApplication object
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/16/91		Initial version
	stevey	1/7/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverPasswordDisplayError	proc	near
		class	SaverApplicationClass
		uses	bp, es
		.enter
	;
	;  Set-usable the error glyph.
	;

		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset

		mov	bx, ds:[di].SAI_passwordBlock
		push	bx
		mov	si, offset PasswordErrorGlyph
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Clear the user's incorrect password.
	;
		pop	bx
		mov	si, offset PasswordUnlockText
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	ObjMessage
	;
	; Beep annoyingly
	;

		mov	ax, SST_ERROR
		call	UserStandardSound

		.leave
		ret
SaverPasswordDisplayError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverContentViewWinOpened
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin saving the screen inside the view, now we've got
		the window.

CALLED BY:	MSG_META_CONTENT_VIEW_WIN_OPENED
PASS:		*ds:si	= SaverContent object
		cx	= width of view, in document coords
		dx	= height of view, in document coords
		bp	= handle of view window
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverContentViewWinOpened method dynamic SaverContentClass, 
			MSG_META_CONTENT_VIEW_WIN_OPENED
		.enter
		mov	di, offset SaverContentClass
		push	bp
		call	ObjCallSuperNoLock
		pop	bp
		
		mov	di, bp
		call	GrCreateState	; di <- gstate

		mov	dx, bp		; dx <- window handle
		mov	bp, di		; bp <- gstate
		mov	ax, MSG_SAVER_APP_SET_WIN
		call	UserCallApplication
		.leave
		ret
SaverContentViewWinOpened endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverContentViewWinClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin accepting input again, if we stopped accepting it
		before.

CALLED BY:	MSG_META_CONTENT_VIEW_WIN_CLOSED
PASS:		*ds:si	= SaverContent object
		ds:di	= SaverContentInstance
		bp	= handle of window that is gone
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverContentViewWinClosed method dynamic SaverContentClass, 
			  		MSG_META_CONTENT_VIEW_WIN_CLOSED
		test	ds:[di].SCI_state, mask SCS_ACCEPT_INPUT_ON_CLOSE
		jz	passItUp

		andnf	ds:[di].SCI_state, not mask SCS_ACCEPT_INPUT_ON_CLOSE
		push	bp, ax
		mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
		call	UserCallApplication
		pop	bp, ax
passItUp:
		mov	di, offset SaverContentClass
		GOTO	ObjCallSuperNoLock
SaverContentViewWinClosed endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverContentEndButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin saving the screen again, as the user has clicked in
		the view.

CALLED BY:	MSG_META_END_SELECT
PASS:		*ds:si	= SaverContent object
		random other cruft
RETURN:		ax	= MouseReturnFlags
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverContentEndButton method dynamic SaverContentClass, MSG_META_END_SELECT,
		      		MSG_META_END_MOVE_COPY,
				MSG_META_END_FEATURES,
				MSG_META_END_OTHER
		.enter
		test	ds:[di].SCI_state, mask SCS_ACCEPT_INPUT_ON_CLOSE
		jnz	done	; => already done this

		ornf	ds:[di].SCI_state, mask SCS_ACCEPT_INPUT_ON_CLOSE

		mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
		call	UserCallApplication

		mov	ax, MSG_SAVER_APP_FORCE_SAVE
		call	UserCallApplication
done:
		.leave
		ret
SaverContentEndButton endm


SaverOptionCode	ends
