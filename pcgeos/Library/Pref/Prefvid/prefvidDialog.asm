COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefvidDialog.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/93   	Initial version.

DESCRIPTION:
	

	$Id: prefvidDialog.asm,v 1.1 97/04/05 01:36:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	GPC_VERSION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVDPrefInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the TV control UI and hide the video driver UI if we
		are in TV mode.

CALLED BY:	MSG_PREF_INIT

PASS:		*ds:si	= PrefVidDialogClass object
		es 	= segment of PrefVidDialogClass
		ax	= message #
		cx	= PrefMgrFeatures
		dx	= UIInterfaceLevel
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/23/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
tvCuiHelpContext	char	"dbVidC", 0
tvAuiHelpContext	char	"dbVidA", 0

PVDPrefInit	method dynamic PrefVidDialogClass, 
					MSG_PREF_INIT

	push	ax			; save msg

	call	CheckIfTvMode		; ZF set if TV mode
	jnz	callSuper		; => monitor used

	;
	; TV is used.  Set video mode selection not usable and TV controls
	; usable.  Also set OK trigger to close the dialog, since the TV
	; controls don't need to reboot the system to take effect.
	;
	push	cx, dx			; save MSG_PREF_INIT params
	push	si			; save self lptr

	mov	si, offset PrefVidDriverGroup	; *ds:si = PrefVidDriverGroup
	call	SetNotUsable

	mov	si, offset PrefVOK	; *ds:si = offset PrefVOK
	call	SetNotUsable

	mov	ax, MSG_GEN_SET_ATTRS
	mov	cx, mask GA_SIGNAL_INTERACTION_COMPLETE	; ch = nothing to clear
	call	CallInstance

	call	SetUsable

	mov	si, offset PrefVidTvGroup	; *ds:si = PrefVidTvGroup
	call	SetUsable

	;
	; Check whether we are in CUI or AUI.  We only provide TV size
	; controls if we are in CUI.
	;
	call	UserGetDefaultUILevel	; ax = UIInterfaceLevel
		CheckHack <UIIL_INTRODUCTORY eq 0>
	tst	ax			; ax == UIIL_INTRODUCTORY?
	mov	bp, offset PrefVidTvPosHelpString	; assume AUI
	mov	di, offset tvAuiHelpContext	; cs:di = AUI help context
	jne	replaceHelpText		; => in AUI

	;
	; We are in CUI.  Add the TV size borders window to the app object.
	;
	mov	ax, MSG_GEN_ADD_CHILD
	mov	cx, ds:[OLMBH_header].LMBH_handle
	mov	dx, offset PrefVidTvSizeBorders	; ^lcx:dx = primary win
	mov	bp, CompChildFlags <0, CCO_LAST>
	call	UserCallApplication
	mov	si, dx			; *ds:si = PrefVidTvSizeBorders
	call	SetUsable

	;
	; Set the TV size controls usable.
	;
	mov	si, offset PrefVidTvSizeGroup
	call	SetUsable

	;
	; Change the help text to that about TV pos and size.
	;
	mov	bp, offset PrefVidTvPosSizeHelpString
	mov	di, offset tvCuiHelpContext	; cs:di = CUI help context

replaceHelpText:
	mov	si, offset PrefVidHelp	; *ds:si = PrefVidHelp
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	dx, ds:[OLMBH_header].LMBH_handle	; ^ldx:bp = string
	clr	cx			; null-terminated
	call	CallInstance

	;
	; Change the help context to that for CUI or AUI on TV.
	;
	pop	si			; *ds:si = self

	mov	ax, ATTR_GEN_HELP_CONTEXT
		CheckHack <size tvCuiHelpContext eq size tvAuiHelpContext>
	mov	cx, size tvCuiHelpContext
	call	ObjVarAddData		; ds:bx = extra data
	push	es			; save PrefVidDialogClass segment
	pushdw	dssi			; save self
	segmov	es, ds
	movdw	dssi, csdi		; ds:si = help context src
	mov	di, bx			; es:di = help context dest
	rep	movsb
	popdw	dssi			; *ds:si = self
	pop	es			; es = PrefVidDialogClass segment

	pop	cx, dx			; cx, dx = params for MSG_PREF_INIT

callSuper:
	pop	ax			; ax = MSG_PREF_INIT
	mov	di, offset PrefVidDialogClass
	call	CallSuperNoLock

	ret
PVDPrefInit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfTvMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if a TV display is used.

CALLED BY:	INTERNAL
PASS:		*ds:si - object to get the display type for (not really used)
RETURN:		ZF set if TV mode, clear if monitor mode.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/01/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfTvMode	proc	near
	uses	ax
	.enter

	call	UserGetDisplayType	; ah = DisplayType, al = flag
	Assert	e, al, TRUE
	and	ah, mask DT_DISP_ASPECT_RATIO
	cmp	ah, DAR_TV shl offset DT_DISP_ASPECT_RATIO

	.leave
	ret
CheckIfTvMode	endp

endif	; GPC_VERSION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefVidDialogSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Intercept MSG_META_SAVE_OPTIONS and drop it on the
		floor.  We don't want to save options unless the video
		device checks out OK.  This is a hack.

PASS:		*ds:si	- PrefVidDialogClass object
		ds:di	- PrefVidDialogClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefVidDialogSaveOptions	method	dynamic	PrefVidDialogClass, 
					MSG_META_SAVE_OPTIONS

ifdef	GPC_VERSION
	;
	; We can't simply drop MSG_META_SAVE_OPTIONS on the floor, as the
	; TV group may need to save its settings without rebooting.  So
	; We forward the msg directly to the TV group if we're in TV mode.
	;
	call	CheckIfTvMode		; ZF set if TV mode
	jnz	done			; => monitor used

	mov	si, offset PrefVidTvGroup
	call	CallInstance

	GOTO_ECN EnsureTvSizeBordersRemoved

done:
endif	; GPC_VERSION

	ret
PrefVidDialogSaveOptions	endm

ifdef	GPC_VERSION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PVDGenReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the TV size borders primary on reset.

CALLED BY:	MSG_GEN_RESET

PASS:		*ds:si	= PrefVidDialogClass object
		es 	= segment of PrefVidDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/01/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PVDGenReset	method dynamic PrefVidDialogClass, 
					MSG_GEN_RESET

	mov	di, offset PrefVidDialogClass
	call	CallSuperNoLock

	FALL_THRU_ECN EnsureTvSizeBordersRemoved

PVDGenReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureTvSizeBordersRemoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that the borders primary is removed from the app
		object.

CALLED BY:	(INTERNAL)
PASS:		ds	= block containing PrefVidTvSizeBorders
RETURN:		ds fixed-up
DESTROYED:	ax, cx, dx, si, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/01/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureTvSizeBordersRemoved	proc	ecnear

	;
	; If we're not in TV mode, do nothing.
	;
	call	CheckIfTvMode		; ZF set if TV mode
	jnz	done

	;
	; If the borders primary is not usable, the primary has already been
	; removed.
	;
	mov	si, offset PrefVidTvSizeBorders	; *ds:si = PrefVidTvSizeBorders
	mov	ax, MSG_GEN_GET_USABLE
	call	CallInstance		; CF set if usable
	jnc	done			; => already removed

	;
	; Remove it.
	;
	call	SetNotUsable
	mov	ax, MSG_GEN_REMOVE_CHILD
	mov	cx, ds:[OLMBH_header].LMBH_handle
	mov	dx, si		; ^lcx:dx = PrefVidTvSizeBorders
	clr	bp		; don't mark link dirty
	call	UserCallApplication

done:
	ret
EnsureTvSizeBordersRemoved	endp

endif	; GPC_VERSION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefVidDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:		

PASS:		*ds:si	- PrefVidDialogClass object
		ds:di	- PrefVidDialogClass instance data
		es	- dgroup

DESTROYED:	ax, cx, dx, bp 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
systemCatString			char	"system", 0
continueSetupString		char	"continueSetup", 0
setupModeString			char	"setupMode", 0


PrefVidDialogApply	method	dynamic	PrefVidDialogClass, 
					MSG_GEN_APPLY

ifndef GPC_VERSION
	;
	; save the options for the large mouse setting
	;
		push	si
		mov	ax, MSG_META_SAVE_OPTIONS
		mov	si, offset PrefVidLargeMouse
		call	CallInstance
		pop	si
endif

ifdef	GPC_VERSION
	;
	; If we're in TV mode, the user is not allowed to change video
	; driver or screen resolution.  Hence when we need to reboot, we
	; don't need to test for the new video device/driver and then invoke
	; Setup after reboot to give the user a chance to switch back to the
	; original device/driver setting.  Therefore, here we simply call
	; superclass to let it perform the usual reboot confirmation.
	;
		call	CheckIfTvMode	; ZF set if TV mode
		jz	callSuper
endif	; GPC_VERSION

	;
	; See if stuff has changed
	;
		push	si
		mov	si, offset PrefVideoList
		mov	ax, MSG_PREF_GET_REBOOT_INFO
		call	CallInstance
		pop	si
		tst	cx
		jnz	confirm

	;
	; Nothing changed -- just goto superclass
	;
		mov	ax, MSG_GEN_APPLY
callSuper::
		mov	di, offset PrefVidDialogClass
		call	CallSuperNoLock

		ret			; <- EXIT
		
confirm:
	;
	; Confirm reboot with the user (cx:dx - reboot string)
	;
		mov	ax, MSG_PREF_DIALOG_CONFIRM_REBOOT
		call	CallInstance
		jnc	done

	;
	; Check the device.  If it's there, then save the options, etc.
	;
		
		mov	si, offset PrefVideoList
		mov	ax, MSG_PREF_TOC_LIST_CHECK_DEVICE_AVAILABLE
		call	CallInstance
		jnc	deviceNotPresent
		
		call	PrefSaveVideo

		mov	ax, MSG_META_SAVE_OPTIONS
		call	CallInstance
		
	;
	; Write the proper stuff out so that SETUP will run.
	;		
		push	ds
		mov	cx, cs
		mov	ds, cx
		mov	si, offset systemCatString
		mov	dx, offset continueSetupString
		mov	ax, TRUE
		call	InitFileWriteBoolean
		
		mov	dx, offset setupModeString
		mov	bp, MODE_AFTER_PM_VIDEO_CHANGE
		call	InitFileWriteInteger
		pop	ds
		
	;
	; Let the user know what's going to happen and how s/he can get back
	; to the current video driver settings.
	;
		mov	bp, offset videoRestartNotice
		mov	ax, CustomDialogBoxFlags <
		0,			; CDBF_SYSTEM_MODAL
		CDT_NOTIFICATION,	; CDBF_DIALOG_TYPE
		GIT_NOTIFICATION	; CDBF_INTERACTION_TYPE
		,0>
		call	DoChunkStandardDialog
	;
	; if a shutdown happened while the dialog was up, don't reboot
	;
		
		cmp	ax, IC_NULL
		jz	done
	;
	; Now reboot the system.
	;
		mov	si, offset PrefVidRoot
		mov	ax, MSG_PREF_DIALOG_REBOOT
		call	CallInstance
		
done:
		ret					; <- exit
		
deviceNotPresent:
		mov	bp, offset noSuchDisplay
		tst	ax			; not there?
		jz	notifyTheUser		; right
		mov	bp, offset cantLoadVidDriver
notifyTheUser:
		mov	ax, CustomDialogBoxFlags <
		0,			; CDBF_SYSTEM_MODAL
		CDT_ERROR,		; CDBF_DIALOG_TYPE
		GIT_NOTIFICATION,	; CDBF_INTERACTION_TYPE
		0>
		call	DoChunkStandardDialog
		jmp	done

PrefVidDialogApply	endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoChunkStandardDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a standard dialog box using a string from our
		Strings resource.

CALLED BY:	EXTERNAL
PASS:		ax	= CustomDialogBoxFlags
		bp	= chunk in Strings resource of message.
RETURN:		ax	= StandardDialogBoxResponses
DESTROYED:	bx, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoChunkStandardDialog	proc	far
		uses	ds
		.enter

	;
	; Lock down the resource and put the segment in di and in ds (so
	; we can dereference the chunk handle)
	; 
		push	ax
		mov	bx, handle Strings
		call	MemLock
		mov	di, ax
		mov	ds, ax

		pop	ax			; recover DB flags
		mov	bp, ds:[bp]		; and point to string itself
		call	PrefMgrUserStandardDialog
	;
	; Unlock the resource now we're done.
	;
		mov	bx, handle Strings
		call	MemUnlock
		.leave
		ret
DoChunkStandardDialog		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrUserStandardDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up params and call UserStandardDialog

CALLED BY:	GLOBAL

PASS:		ax - CustomDialogBoxFlags
			(can't be GIT_MULTIPLE_RESPONSE)
		di:bp = error string
		cx:dx = arg 1
		bx:si = arg 2

RETURN:		ax = InteractionCommand response

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrUserStandardDialog	proc	far

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
.assert (offset SDP_customString eq offset SDP_customFlags+2)
.assert (offset SDP_customFlags eq 0)
	push	ax		; save SDP_type, SDP_customFlags
				; params passed on stack
	call	UserStandardDialog
	ret
PrefMgrUserStandardDialog	endp
