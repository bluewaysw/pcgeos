COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Preferences
MODULE:		Lights Out
FILE:		preflo.asm

AUTHOR:		Adam de Boor

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/7/92		Initial Version  	

DESCRIPTION:
		
	$Id: preflo.asm,v 1.1 97/04/05 01:32:20 newdeal Exp $

-----------------------------------------------------------------------------@



;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def

include object.def
include	graphics.def
include gstring.def
include	win.def

include char.def
include Objects/inputC.def
include initfile.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def
UseLib	saver.def
UseLib	Objects/vTextC.def
UseLib	Internal/im.def
UseLib	net.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include preflo.def
include preflo.rdef

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------

idata	segment
	PrefLODialogClass
	PrefLOPasswordTextClass
idata	ends
 
PrefLOCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLOGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		nothing 

RETURN:		dx:ax - OD of root of tree

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLOGetPrefUITree	proc far
	mov	dx, handle PrefLORoot
	mov	ax, offset PrefLORoot
	ret
PrefLOGetPrefUITree	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLOGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr

PASS:		ds:si - PrefModuleInfo structure to be filled in

RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLOGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle  LOMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset  LOMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'L' or ('O' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	.leave
	ret
PrefLOGetModuleInfo	endp

;==============================================================================
;
;		       PrefLOPasswordTextClass
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLOPTStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for quick move/copy -- refuse to do it.

CALLED BY:	MSG_META_START_MOVE_COPY
PASS:		*ds:si	= instance data
RETURN:		ax	= MouseReturnFlags (not processed)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLOPTStartMoveCopy method dynamic PrefLOPasswordTextClass, 
					MSG_META_START_MOVE_COPY
		.enter
		clr	ax		; not processed
		.leave
		ret
PLOPTStartMoveCopy endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLOPTCatchTextChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of another character being typed into the object.

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= PrefLOPasswordText object
		ds:bx	= PrefLOPasswordTextBase
		ds:di	= PrefLOPasswordTextInstance
		es	= dgroup
		cx	= char value
		dl	= CharFlags
				CF_RELEASE - set if release
				CF_STATE - set if shift, ctrl, etc.
				CF_TEMP_ACCENT - set if accented char pending
		dh 	= ShiftState
		bp low 	= ToggleState (unused)
		bp high = scan code (unused)
				
RETURN:		cx, dx, bp - preserved
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Remember the number of chars in the text at the start.
	Call the superclass.
	If the object has changed from empty to non-empty, or
		non-empty to empty, enable or disable the Lock Screen
		trigger appropriately.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLOPTCatchTextChange	method dynamic	PrefLOPasswordTextClass,
				MSG_VIS_TEXT_REPLACE_TEXT,
				MSG_META_KBD_CHAR,
				MSG_META_CLIPBOARD_PASTE
		uses	cx, dx, bp
		.enter
	;
	; If marked for only wholesale replacement, nuke everything
	; 
		test	ds:[di].PLOPTI_state, mask PLOPTS_REPLACE_ALL
		jz	passItUp
		
		andnf	ds:[di].PLOPTI_state, not mask PLOPTS_REPLACE_ALL

		push	ax, cx, dx, bp
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		mov	di, offset PrefLOPasswordTextClass
		call	ObjCallSuperNoLock

		mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
		call	ObjCallSuperNoLock

		mov	ax, MSG_GEN_MAKE_APPLYABLE
		call	ObjCallSuperNoLock

		pop	ax, cx, dx, bp
passItUp:
	;
	; Let our superclass handle the message (whatever it is).
	;
		mov	di, offset PrefLOPasswordTextClass
		call	ObjCallSuperNoLock
	;
	; If we are the master and we have no text now, disable our pair.
	; 
		mov	di, ds:[si]
		mov	bx, di
		add	di, ds:[di].PrefLOPasswordText_offset
		test	ds:[di].PLOPTI_state, mask PLOPTS_AM_MASTER
		jz	comparePasswords
		add	bx, ds:[bx].GenText_offset
		mov	bx, ds:[bx].GTXI_text
		ChunkSizeHandle ds, bx, cx
		dec	cx		; don't count null

	; edigeron 10/9/00 - when we disable the paired object, clear out
	; the text in it. If we don't, then the user has to do that before
	; clearing this one in order to stop the module from complaining
	; that the passwords don't match.

		mov	dl, VUM_NOW
		push	si
		mov	si, ds:[di].PLOPTI_pair
		mov	ax, MSG_GEN_SET_ENABLED
		jnz	enableDisablePair
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjCallInstanceNoLock
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
enableDisablePair:
		call	ObjCallInstanceNoLock
		pop	si
comparePasswords:
	;
	; See if the passwords now match and act accordingly
	; 
		call	PLOPTVerifyPassword

		.leave
		ret
PLOPTCatchTextChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLOPTVerifyPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passwords in this object and its pair are the
		same, and set PLOPTS_PASSWORD_VERIFIED in both if so.

CALLED BY:	PLOPTCatchTextChange
PASS:		*ds:si	= PrefLOPasswordText object
		es	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLOPTVerifyPassword proc	near
		class	PrefLOPasswordTextClass
		uses	es, dx, si, bp
		.enter
		mov	dx, si			; self
	;
	; Clear the passwordVerified bit for this object, coincidentally
	; fetching the chunk of its pair, and the chunk that stores its
	; text.
	; 
		mov	di, ds:[si]
		mov	bx, di			; for getting the text chunk...
		add	di, ds:[di].PrefLOPasswordText_offset
		andnf	ds:[di].PLOPTI_state, not mask PLOPTS_PASSWORD_VERIFIED

		add	bx, ds:[bx].GenText_offset
		mov	si, ds:[bx].GTXI_text
		mov	bx, di			; save our instance for possibly
						;  setting passwordVerified bit
		mov	di, ds:[di].PLOPTI_pair	; *ds:di <- paired object
	;
	; Clear the passwordVerified bit for the paired object, coincidentally
	; fetching the chunk that stores its text.
	; 
		mov	di, ds:[di]
		mov	bp, di			; for getting the text chunk...
		add	di, ds:[di].PrefLOPasswordText_offset
		andnf	ds:[di].PLOPTI_state, not mask PLOPTS_PASSWORD_VERIFIED
		add	bp, ds:[bp].GenText_offset
		mov	bp, ds:[bp].GTXI_text	; *ds:bp <- text
		xchg	di, bp			; ds:bp <- pair's instance, for
						;  possibly setting
						;  passwordVerified bit.
						; *ds:di <- pair's text
	;
	; ds:bx	= master PLOPT
	; ds:bp	= slave PLOPT
	; *ds:si = master text
	; *ds:di = slave text

		ChunkSizeHandle ds, si, ax
		ChunkSizeHandle ds, di, cx
		
		cmp	ax, cx
		jne	done		; if not same length, can't be same
		dec	cx		; don't count null in comparison

	; if password is zero length, still verified as Null string
		jz	verifiedPassword	
			

		mov	si, ds:[si]	; ds:si <- source
		segmov	es, ds
		mov	di, ds:[di]	; es:di <- dest
		repe	cmpsb
		jne	done


verifiedPassword:
	;
	; The passwords are the same non-zero length and equal in all their
	; characters, so they match (really? gosh!)
	; 
		ornf	ds:[bx].PLOPTI_state, mask PLOPTS_PASSWORD_VERIFIED
		ornf	ds:[bp].PLOPTI_state, mask PLOPTS_PASSWORD_VERIFIED

done:
		.leave
		ret

PLOPTVerifyPassword endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLOPTLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load text from the ini file.

CALLED BY:	MSG_GEN_LOAD_OPTIONS
PASS:		*ds:si	= PrefLOPasswordText object
		ss:bp	= GenOptionsParams
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version
	llin	8/4/94		fix bug (no warning message when
				password mismatch)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLOPTLoadOptions method dynamic PrefLOPasswordTextClass, MSG_GEN_LOAD_OPTIONS
		.enter
	;
	; Make room for fetching the encrypted password from the .ini file on
	; the stack.
	; 
SBCS <		sub	sp, SAVER_MAX_PASSWORD				>
DBCS <		sub	sp, SAVER_MAX_PASSWORD*(size wchar)		>
		mov	di, sp
		push	ds, si
		segmov	es, ss, cx		; es:di <- buffer
		mov	ds, cx
		lea	si, ss:[bp].GOP_category; ds:si <- category
		lea	dx, ss:[bp].GOP_key	; cx:dx <- key
SBCS <		mov	bp, SAVER_MAX_PASSWORD-1; bp <- size		>
DBCS <		mov	bp, (SAVER_MAX_PASSWORD-1)*(size wchar); bp <- size>
		call	InitFileReadData	; cx <- # bytes
		pop	ds, si

	; if the no password input, still display 0 asterisk
	; because we need to enable the apply button
	;
		jnc	displayAsterisk
		clr	cx			; # of asterisk

displayAsterisk:
	;
	; Set our text to be as many asterisks as there were in the password
	; we encrypted, also enable the Apply button
	; 
if DBCS_PCGEOS
		shr	cx, 1
		mov	ax, '*'
		rep	stosw
		clr	ax
		stosw
else
		mov	al, '*'
		rep	stosb
		clr	al
		stosb
endif
		mov	bp, sp
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock
	;
	; Select everything, so it's a bit more obvious what we'll do if the
	; user types something...
	; 
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		call	ObjCallInstanceNoLock
	;
	; Tell ourselves to wipe the whole thing out if the user tries to
	; change the object.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].PrefLOPasswordText_offset
		ornf	ds:[di].PLOPTI_state, mask PLOPTS_REPLACE_ALL or \
				mask PLOPTS_WAS_REPLACE_ALL or \
				mask PLOPTS_PASSWORD_VERIFIED
	;
	; Enable the pair ed object, if we're the master, as we've got some
	; text.
	; edigeron 10/9/00 - only enable paired text object if we have
	; text in this object.
	; 
		test	ds:[di].PLOPTI_state, mask PLOPTS_AM_MASTER
		jz	done
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		tst	ax	; password can't be dword length
		jz	done
		mov	si, ds:[di].PLOPTI_pair
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
done:
	;
	; Clear the stack.
	; 
SBCS <		add	sp, SAVER_MAX_PASSWORD				>
DBCS <		add	sp, SAVER_MAX_PASSWORD*(size wchar)		>
		.leave
		ret

PLOPTLoadOptions endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLOPTApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Foil our superclass' attempt to clear the MODIFIED
		flag.  Otherwise our SAVE_OPTIONS handler won't work.

PASS:		*ds:si	- PrefLOPasswordTextClass object
		ds:di	- PrefLOPasswordTextClass instance data
		es	- dgroup

RETURN:		nothing

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefLOPTApply	method	dynamic	PrefLOPasswordTextClass, 
					MSG_GEN_APPLY

		mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
		call	ObjCallInstanceNoLock
		push	cx
		
		mov	di, offset PrefLOPasswordTextClass
		call	ObjCallSuperNoLock

		pop	cx
		jcxz	done

		mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
		GOTO	ObjCallInstanceNoLock 
done:
		ret
PrefLOPTApply	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLOPTGenPreApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To reset the password dialog box.

CALLED BY:	MSG_GEN_PRE_APPLY
PASS:		*ds:si	= PrefLOPasswordTextClass object
		ds:di	= PrefLOPasswordTextClass instance data
		ds:bx	= PrefLOPasswordTextClass object (same as *ds:si)
		es 	= segment of PrefLOPasswordTextClass
		ax	= message #
RETURN:		CF set if dialog box of warning message is brought up
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LL	8/ 4/94   	Initial version
				fix bug: no warning when password mismatch

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLOPTGenPreApply	method dynamic PrefLOPasswordTextClass, 
					MSG_GEN_PRE_APPLY
	uses	ax, bp
	.enter

	; if the text has not modified yet, no warning message is
	; needed
	
		mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
		call	ObjCallInstanceNoLock
		jcxz	done

	;
	; check whether the password is verified
	; 
		test	ds:[di].PLOPTI_state, mask PLOPTS_AM_MASTER
		jz	done

		test	ds:[di].PLOPTI_state, mask PLOPTS_PASSWORD_VERIFIED
		jnz	done

		push	si
	;
	; reset the password dialog box just in case the user clicks
	; cancel to exit
	;
		mov	si, offset LOPasswordOptions
		mov	ax, MSG_GEN_RESET
		call	ObjCallInstanceNoLock

	; reset the state of the text to be not modified in case the
	; user clicks cancel to exit and ok to exit Lights out, to
	; prevent the dialog box comes up again.
	;
		pop	si
		mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
		call	ObjCallInstanceNoLock

	; 
	; Bring up a dialog box notifying the user that the password
	; not verified
	;
		sub	sp, size StandardDialogOptrParams
		mov	bp, sp
		mov	ss:[bp].SDOP_customFlags, \
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) \
			or (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)


		mov	ss:[bp].SDOP_customString.handle, handle MismatchStr
		mov	ss:[bp].SDOP_customString.chunk, offset MismatchStr
		mov	ss:[bp].SDOP_stringArg1.handle, NULL
		mov	ss:[bp].SDOP_stringArg2.handle, NULL
		mov	ss:[bp].SDOP_customTriggers.segment, NULL
		mov	ss:[bp].SDOP_helpContext.segment, NULL
		call	UserStandardDialogOptr
		stc
done:	

	.leave
	ret
PLOPTGenPreApply	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLOPTSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the text out, encrypted.

CALLED BY:	MSG_GEN_SAVE_OPTIONS
PASS:		*ds:si	= PrefLOPasswordText object
		ss:bp	= GenOptionsParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version
	llin	8/4/94		fix bug
				(no warning message when password mismatch)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLOPTSaveOptions method dynamic PrefLOPasswordTextClass, MSG_GEN_SAVE_OPTIONS
		.enter
;
; Can't make this check as the text object sets itself not-user-modified
; on the GEN_APPLY that caused the MSG_GEN_SAVE_OPTIONS
;
	;
	; Make sure we've even been modified. If not, there's nothing new
	; to save, and saving what we've got would be detrimental, seeing as
	; it's garbage...
	; 
		mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
		call	ObjCallInstanceNoLock
		clc
		jcxz	doneNoClear

	;
	; Make room on the stack for the current text and fetch it.
	; 
SBCS <		sub	sp, SAVER_MAX_PASSWORD				>
DBCS <		sub	sp, SAVER_MAX_PASSWORD*(size wchar)		>

		test	ds:[di].PLOPTI_state, mask PLOPTS_AM_MASTER
		jz	done		; if not master, don't mess with things
		
		push	bp
		
		test	ds:[di].PLOPTI_state, mask PLOPTS_PASSWORD_VERIFIED
		jz	reset		; if not verified, => no password

		mov	bp, sp
		inc	bp
		inc	bp
		mov	dx, ss		; dx:bp <- buffer
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock	; cx <- # chars w/o null

		LONG	jcxz	noPassword	; => empty, so nuke key
	;
	; Use that as the key by which we'll encrypt it.
	; 
		movdw	dssi, dxbp		; ds:si <- key
		call	SaverCryptInit	; bx <- machine token
		LONG	jc	noPassword	; => couldn't create, so act as if no
					;  password entered
	;
	; Encrypt the key with itself (cx remains # chars w/o null)
	; 
		call	SaverCryptEncrypt
		pop	bp		; ss:bp <- GenOptionsParams

	;
	; Write the result to the ini file as raw data.
	; 
DBCS <		shl	cx, 1				; # chars -> # bytes>
		lea	si, ss:[bp].GOP_category
		lea	dx, ss:[bp].GOP_key
		mov	di, sp
		segmov	es, ss, bp			; es:di <- buffer
		mov	ds, bp				; ds:si <- category
		xchg	cx, bp				; cx:dx <- key,
							; bp <- # bytes
		call	InitFileWriteData
	;
	; Nuke the encryption machine.
	; 
		call	SaverCryptEnd
done:
	;
	; Clear the stack and return.
	; 
SBCS <		add	sp, SAVER_MAX_PASSWORD				>
DBCS <		add	sp, SAVER_MAX_PASSWORD*(size wchar)		>
doneNoClear:
		.leave
		ret

reset:
	;
	; If password not verified, reset both objects to their original
	; condition.
	; 
		push	si
		mov	ax, MSG_GEN_RESET
		call	ObjCallInstanceNoLock
		mov	di, ds:[si]
		add	di, ds:[di].PrefLOPasswordText_offset
		mov	si, ds:[di].PLOPTI_pair
		mov	ax, MSG_GEN_RESET
		call	ObjCallInstanceNoLock

		pop	si

noPassword:
	;
	; No password entered. Signal this by nuking the key from the
	; ini file.
	; 
		pop	bp
		segmov	ds, ss, cx	; ds, cx <- ss
		lea	si, ss:[bp].GOP_category
		lea	dx, ss:[bp].GOP_key
		call	InitFileDeleteEntry
		jmp	done
		
PLOPTSaveOptions endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLOPTReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the object to the way it was on startup.

CALLED BY:	MSG_GEN_RESET
PASS:		*ds:si	= PrefLOPasswordText object
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLOPTReset	method dynamic PrefLOPasswordTextClass, MSG_GEN_RESET
		.enter
		mov	di, offset PrefLOPasswordTextClass
		call	ObjCallSuperNoLock
	;
	; If was replace-all when options loaded, make sure it still is,
	; and select the whole thing again.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].PrefLOPasswordText_offset
		test	ds:[di].PLOPTI_state, mask PLOPTS_WAS_REPLACE_ALL
		jz	done
		ornf	ds:[di].PLOPTI_state, mask PLOPTS_REPLACE_ALL
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
PLOPTReset	endm

;==============================================================================
;
;			  PrefLODialogClass
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODSetScreenBlank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the system what the new state of the screen blanking is

CALLED BY:	MSG_PLOD_AUTO_SCREEN_BLANK
PASS:		*ds:si	= PrefLODialog object
		cx	= TRUE to enable blanking, FALSE to disable it.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLODSetScreenBlank method dynamic PrefLODialogClass, MSG_PLOD_AUTO_SCREEN_BLANK
		jcxz	disable
		mov	ax, MSG_IM_ENABLE_SCREEN_SAVER
		call	PLODCallIM
	;
	; enabling, start up saver, launcher
	;
		push	si
		mov	si, offset LOList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock	; ax = current saver
		pop	si
		jc	done
		mov	cx, ax			; cx = current saver
		jcxz	done			; no selection
		mov	ax, MSG_PLOD_CHANGE_SAVER
		call	ObjCallInstanceNoLock
done:
		ret
 
disable:
		call	PLODSetForNothingSpecial
		mov	ax, MSG_IM_DISABLE_SCREEN_SAVER
		GOTO	PLODCallIM
PLODSetScreenBlank endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODSetTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the screen-saver timeout.

CALLED BY:	MSG_PLOD_SET_TIMEOUT
PASS:		*ds:si	= PrefLODialog object
		dx.cx	= timeout (minutes)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLODSetTimeout	method dynamic PrefLODialogClass, MSG_PLOD_SET_TIMEOUT
		mov	ax, MSG_IM_SET_SCREEN_SAVER_DELAY
		mov	cx, dx		; cx <- time
		FALL_THRU	PLODCallIM
PLODSetTimeout	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODCallIM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the input manager for something.

CALLED BY:	(INTERNAL) PLODSetTimeout, PLODSetScreenBlank
PASS:		ax	= message to send
		*ds:si	= PrefLODialog object
		cx, dx, bp = arguments to same
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLODCallIM	proc	far
		call	ImInfoInputProcess
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		ret
PLODCallIM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to all savers on the "SSAV",0 list.

CALLED BY:	(INTERNAL)
PASS:		bx	= AppLaunchBlock to use (0 if shouldn't launch)
		*ds:si	= PrefLODialog object
RETURN:		carry set if couldn't connect
		carry clear if connected:
			bp	= IACPConnection
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ssavToken	GeodeToken <<'SSAV'>, 0>

PLODConnect	proc	near
		uses	cx, dx, es, di
		.enter
		segmov	es, cs
		mov	di, offset ssavToken
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	al, mask IACPCF_CLIENT_OD_SPECIFIED
		call	IACPConnect
		.leave
		ret
PLODConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODGenerateAppLaunchBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an AppLaunchBlock for the current saver.

CALLED BY:	(INTERNAL) PLODChangeSaver
PASS:		*ds:si	= PrefLODialog object
		cx	= identifier
RETURN:		bx	= handle of AppLaunchBlock
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLODGenerateAppLaunchBlock proc	near
		uses	dx, si, di, bp, es
		.enter
	;
	; Get the path of the selected item.
	; 
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_PATH
		mov	si, offset LOList
		call	ObjCallInstanceNoLock
	;
	; Use that to generate the launch block.
	; 
		push	ax
		call	SaverCreateLaunchBlock
	;
	; Tell it it's the master saver.
	; 
		call	MemLock
		mov	es, ax
		mov	es:[ALB_extraData], mask SED_NOT_JUST_TESTING or \
				(SID_MASTER_SAVER shl offset SED_SAVER_ID)
		call	MemUnlock
		
	;
	; Free the block holding the saver's path.
	; 
		pop	ax
		xchg	ax, bx
		call	MemFree
		mov_tr	bx, ax
		.leave
		ret
PLODGenerateAppLaunchBlock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODSetForNothingSpecial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shut off any current screen saver and make sure the
		launcher isn't loaded on startup.

CALLED BY:	(INTERNAL) PLODChangeSaver, PLODSetScreenBlank
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLODSetForNothingSpecial proc	near
		.enter
		clr	bx			; don't launch
		call	PLODConnect
		jc	done			; => nothing in autoexec
						;  either, as we remove it
						;  whenever we disable things

		mov	ax, MSG_META_QUIT
		clr	bx			; no response
		call	PLODSendMessageToMaster
		
		segmov	ds, cs
		mov	si, offset launcherName
		call	UserRemoveAutoExec
done:
		.leave
		ret
PLODSetForNothingSpecial endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODChangeSaver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the master saver to change to the selected one.

CALLED BY:	MSG_PLOD_CHANGE_SAVER
PASS:		*ds:si	= PrefLODialog
		cx	= saver #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <launcherName	char	'Lights Out Launcher', 0		>
DBCS <launcherName	wchar	'Lights Out App', 0			>

PLODChangeSaver	method dynamic PrefLODialogClass, MSG_PLOD_CHANGE_SAVER
		.enter
		jcxz	quitMaster
	;
	; Do nothing if saver not on
	;
		push	si
		mov	si, offset LOEnableList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock	; ax = selection
		pop	si
		jc	done
		cmp	ax, TRUE		; on?
		jne	done			; nope
	;
	; Create an AppLaunchBlock that we use both for launching, and for
	; telling an existing master to change.
	; 
		call	PLODGenerateAppLaunchBlock

		call	PLODConnect		; connect, with ourselves
						;  as the client object
		jc	done			; couldn't connect

		clr	cx			; shutdown client end
		call	IACPShutdown
		
		segmov	ds, cs
		mov	si, offset launcherName
		call	UserAddAutoExec
done:
		.leave
		ret
quitMaster:
		call	PLODSetForNothingSpecial
		jmp	done
PLODChangeSaver	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODFreeAppLaunchBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the given ALB and close the connection

CALLED BY:	MSG_PLOD_FREE_APP_LAUNCH_BLOCK
PASS:		*ds:si	= PrefLODialog object
		^hcx	= AppLaunchBlock
		bp	= IACPConnection to close
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLODFreeAppLaunchBlock method dynamic PrefLODialogClass, 
				MSG_PLOD_FREE_APP_LAUNCH_BLOCK
		.enter
		mov	bx, cx
		call	MemFree
		clr	cx
		call	IACPShutdown
		.leave
		ret
PLODFreeAppLaunchBlock endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take care of telling the master saver to reload its options
		once we're sure they're all in the file.

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= PrefLODialog object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLODApply	method dynamic PrefLODialogClass, MSG_GEN_APPLY
		.enter
	;
	; Let superclass ensure everyone has done what they need to.
	; 
		mov	di, offset PrefLODialogClass
		call	ObjCallSuperNoLock
ifdef GPC_VERSION
		push ds, si
endif
	;
	; Now instruct the master saver to do likewise.
	; 
		clr	bx		; don't launch
		call	PLODConnect
		jc	done

		mov	ax, MSG_META_LOAD_OPTIONS
		clr	bx
		call	PLODSendMessageToMaster
ifdef GPC_VERSION
	;
	; Bring up a "How it works" db if it's a first time the user turn
	; on the feature.
	;
		pop	ds, si
		mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
		call	ObjVarFindData
		jnc	exit			; ds:bx - pointer to category

		mov	si, bx			; ds:si - category
		mov	bx, handle HowItWorks
		call	MemLock
		mov	cx, ax
		mov	es, ax
		mov	di, offset HowItWorks
		mov	dx, es:[di]		; cx:dx
		call	InitFileReadBoolean	; cx <- # bytes
		jnc	foundKey
		mov	ax, 1
		call	InitFileWriteBoolean	; cx <- # bytes

		mov	bx, ds:[OLMBH_header].LMBH_handle
		mov	si, offset FirstTime
		call	UserDoDialog
foundKey:
		mov	bx, handle Strings
		call	MemUnlock
		jmp	exit
endif
done:
ifdef GPC_VERSION
		pop	ds, si
exit:
endif
		.leave
		ret
PLODApply	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODSendMessageToMaster
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the master saver via IACP.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= PrefLODialog object
		ax	= message to send to master
		bx	= completion message to send back to us
		bp	= IACPConnection to use
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	connection is closed if no completion message, else
     		completion message is expected to shut it down (passed in
		bp)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLODSendMessageToMaster proc	near
		.enter
	;
	; Record the real message to send.
	; 
		push	bx, si
		clr	bx, si
		mov	di, mask MF_RECORD
		call	ObjMessage
	    ;
	    ; Change the owner of the recorded message to be the UI so it
	    ; doesn't get nuked if we should exit (ideally this would
	    ; be the owner of the server object, but we can't get to that
	    ; info)
	    ;
		mov	bx, di
		mov	ax, handle ui
		call	HandleModifyOwner
		pop	ax, si
		push	di

		clr	di		; assume no completion msg.
		tst	ax
		jz	haveCompletionMsg
	;
	; Record the completion message using the same (cx, dx, bp) parameters.
	; 
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_RECORD
		call	ObjMessage

haveCompletionMsg:
		pop	cx
		push	di
	;
	; Now record the message we'll send through IACP that ensures what
	; we're sending goes only to the master saver.
	; 
		mov	ax, MSG_SAVER_APP_DISPATCH_EVENT_IF_MINE
		clr	bx, si
		mov	dx, SID_MASTER_SAVER
		mov	di, mask MF_RECORD
		call	ObjMessage
	;
	; Send the message.
	; 
		mov	bx, di		; bx <- message to send
		pop	cx		; cx <- completion message
		mov	dx, TO_SELF	; dx <- TravelOption
		mov	ax, IACPS_CLIENT
		push	cx
		call	IACPSendMessage
		pop	cx
		jcxz	closeConnection
done:
		.leave
		ret
closeConnection:
		call	IACPShutdown	; (cx already 0 => client)
		jmp	done
PLODSendMessageToMaster endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLODSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure if we're running on a network and enable or disable
		the UseNetPassword list appropriately.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= PrefDialog object
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PLODSpecBuild	method dynamic PrefLODialogClass, MSG_SPEC_BUILD
		.enter
		mov	di, offset PrefLODialogClass
		CallSuper	MSG_SPEC_BUILD
		push	ds
		sub	sp, (size NetLoginNameZT)
		segmov	ds, ss
		mov	si, sp
		mov	ax, enum NetUserGetLoginName
		call	LOCallNetLib
		lea	sp, ds:[si+(size NetLoginNameZT)]
		pop	ds
		mov	ax, MSG_GEN_SET_USABLE
		jnc	enableDisable
		mov	ax, MSG_GEN_SET_NOT_USABLE
enableDisable:
		mov	si, offset UseNetPassword
		mov	dl, VUM_NOW
		push	ax
		call	ObjCallInstanceNoLock
		pop	ax
		cmp	ax, MSG_GEN_SET_USABLE
		je	done
	;
	; UseNet not usable, so ensure password group is enabled.
	; 
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		mov	si, offset SaverPasswordGroup
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
PLODSpecBuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LOCallNetLib
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to call the dynamically loaded net library

CALLED BY:	PLODSpecBuild()
PASS:		ax - enum of net library routine to call
		rest depends on function (undefined for NetVerifyUserPassword)
RETURN:		carry - set if error
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

LOCallNetLib		proc	near
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
LOCallNetLib		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLODialogDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Close password and options dialogs on MSG_GEN_REMOVE and
		MSG_GEN_DESTROY_AND_FREE_BLOCK

PASS:		*ds:si	- PrefLODialogClass object
		ds:di	- PrefLODialogClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       	brianc	7/27/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLODialogDestroy	method	dynamic	PrefLODialogClass, 
					MSG_GEN_REMOVE,
					MSG_GEN_DESTROY_AND_FREE_BLOCK

		push	ax, si, dx, bp
		mov	si, offset LOGeneralOptions
		call	dismissIt
		mov	si, offset LOContainer
		call	dismissIt
		mov	si, offset LOPasswordOptions
		call	dismissIt
		pop	ax, si, dx, bp

		mov	di, offset PrefLODialogClass
		call	ObjCallSuperNoLock
		ret

dismissIt	label	near
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjCallInstanceNoLock
		retn
PrefLODialogDestroy	endm

PrefLOCode	ends
