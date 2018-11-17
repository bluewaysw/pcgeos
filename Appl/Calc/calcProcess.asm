COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calculator Accessory
FILE:		calcProcess.asm

AUTHOR:		Adam de Boor, Mar 22, 1990

ROUTINES:
	Name			Description
	----			-----------
	MSG_UI_OPEN_APPLICATION
	MSG_UI_CLOSE_APPLICATION
	MSG_CALC_CHANGE_MODE
	MSG_CALC_RESET
	MSG_CALC_SET_PRECISION
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/22/90		Initial revision


DESCRIPTION:
	Process-class for the calculator
		

	$Id: calcProcess.asm,v 1.1 97/04/04 14:46:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	CalcClass	mask CLASSF_NEVER_SAVED

calcVars	CalcInstance <
		<>,			; Meta instance
		CM_INFIX,		; Default to Infix mode
		CD_DEFAULT_PRECISION	; default precision
>

modeTable	CalcMode	<
	InfixEngine, InfixDisplay, InfixTop, InfixEqual
>
ifndef GCM
		CalcMode	<
	RPNEngine, RPNDisplay, RPNTop, RPNEnter
>
endif

	CalcBogusInteractionClass	; Declare the class record
	CalcBogusPrimaryClass		; Declare the class record

idata	ends

Main		segment resource
ifdef	GCM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Copied from procClass.asm
;
;	Default method for creating a new state file name, opening the
; new file & stuffing the name back into the AppAttachBlock.  Called
; from within UI_AttachToStateFile if no state file was passed.  Can
; be subclassed to provide forced state file usage/different naming scheme,
; etc.
;
;	Pass:
;		dx - Block handle to block of structure AppInstanceReference
;
;		CurPath	- Set to state directory
;
;	Return:
;		ax - VM file handle (0 if you want no state file)
;

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 2/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcCreateNewStateFile	method	CalcClass,
					MSG_UI_CREATE_NEW_STATE_FILE
	clr	ax		;No state file
	ret
CalcCreateNewStateFile	endp

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform initial processing to open as an interactive
		application

CALLED BY:	MSG_UI_OPEN_APPLICATION
PASS:		ds	= dgroup
		cx	= AppAttachFlags (ignored)
		dx	= handle of AppLaunchBlock (ignored)
		bp	= handle of block from which to restore state
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcOpenApplication method	CalcClass, MSG_UI_OPEN_APPLICATION
		.enter
		DoPush	ax, bx, cx, dx, bp, si
		tst	bp
		jz	restoreState

		mov	bx, bp
		call	MemLock
		jc	restoreState
	;
	; Copy entire state block to our own.
	;
		push	ds
		mov	ds, ax
		mov	cx, size CalcInstance
		clr	si
		mov	di, offset calcVars
		rep	movsb
		;
		; Unlock the state block
		;
		call	MemUnlock
		pop	ds
restoreState:
ifdef GCM
	;
	; Need to do some adjusting of things if we're on a CGA:
	;	- InfixButtons needs to wrap based on GCM_S_BUTTON_HEIGHT
	;	  not GCM_BUTTON_HEIGHT
	;	- InfixDisplay needs to use a 30-point LED font, not 40-point.
	; 
		mov	ax, MSG_CBI_ADJUST_HINTS
		mov	si, offset InfixButtons
		GetResourceHandleNS	InfixButtons, bx
		mov	di, mask MF_CALL
		call	ObjMessage
endif

	;
	; Fetch the numeric-formatting information for the local system.
	;
		call	LocalGetNumericFormat
		mov	ds:[decimalPoint], cl

		DoPopRV	ax, bx, cx, dx, bp, si
		mov	di, offset CalcClass
		CallSuper	MSG_UI_OPEN_APPLICATION
		.leave
		ret
CalcOpenApplication endp


ifdef GCM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcBogusInteractionAdjustHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform necessary adjustments of hints and sizes if we're
		running on a very-squished display.

CALLED BY:	MSG_CBI_ADJUST_HINTS
PASS:		*ds:si	= instance data
		ds:bx	= CalcBogusInteractionBase
		ds:di	= CalcBogusInteractionInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcBogusInteractionAdjustHints method	dynamic CalcBogusInteractionClass,
					MSG_CBI_ADJUST_HINTS
		.enter
		assume	ds:Infix
;		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
;		call	GenCallApplication

;		andnf	ah, mask DT_DISP_ASPECT_RATIO
;		cmp	ah, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
;		jne	noAdjust

		mov	dx, size GadgetSizeHintArgs
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].GSHA_width, GCM_S_BUTTON_HEIGHT
		clr	ss:[bp].GSHA_height
		
		mov	dl, VUM_MANUAL		;update not necessary
		mov	ax, MSG_GEN_SET_FIXED_SIZE
		call	ObjCallInstanceNoLock
		add	sp, size GadgetSizeHintArgs
		
		mov	bx, ds:[InfixDisplayStyle]
		mov	ds:[bx].VTCA_pointSize.WBF_int, GCM_S_FONTSIZE
		assume	ds:dgroup
noAdjust:
		assume	ds:dgroup
		.leave
		ret
CalcBogusInteractionAdjustHints endp

endif	; GCM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish off interactive mode.

CALLED BY:	MSG_UI_CLOSE_APPLICATION
PASS:		ds=es=group
RETURN:		cx	= handle of block to save
DESTROYED:	ax, cx, es, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcCloseApplication method	CalcClass, MSG_UI_CLOSE_APPLICATION
		.enter
		;
		; Allocate a block o' memory for the state
		;
		mov	ax, size CalcInstance
		mov	cx, ALLOC_DYNAMIC_LOCK
		clr	bx		; clear bx in case of error
		call	MemAlloc
		jc	error
		
		;
		; Transfer all of calcVars to the state block for
		; next time -- it's the only state we need.
		;
EC <		push	es						>
		mov	es, ax
		clr	di
		mov	si, offset calcVars
		mov	cx, size CalcInstance
		rep	movsb
EC <		pop	es						>
		call	MemUnlock
error:
		mov	cx, bx
		.leave
		ret
CalcCloseApplication endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the current calculator engine

CALLED BY:	MSG_CALC_RESET
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		ship MSG_CE_RESET to the current engine.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcReset	method	CalcClass, MSG_CALC_RESET
		.enter
		mov	bx, ds:calcVars.CI_mode
		mov	si, ds:modeTable[bx].CM_engine.chunk
		mov	bx, ds:modeTable[bx].CM_engine.handle
		mov	ax, MSG_CE_RESET
		clr	di		; No need to call or fixup
		call	ObjMessage
		.leave
		ret
CalcReset	endp


ifndef GCM

if 0	; text object sends the return up the focus tree. Since we already
	; handle that in CalcBogusPrimary, there's no need for it here...

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDisplayReturn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Activate the default for the current mode.

CALLED BY:	MSG_CALC_DISPLAY_RETURN
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDisplayReturn	method	CalcClass, MSG_CALC_DISPLAY_RETURN
		.enter
		mov	bx, ds:calcVars.CI_mode
		mov	si, ds:modeTable[bx].CM_default.chunk
		mov	bx, ds:modeTable[bx].CM_default.handle
		mov	ax, MSG_GEN_ACTIVATE
		clr	di		; No need to call or fixup
		call	ObjMessage
		.leave
		ret
CalcDisplayReturn	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcForwardToDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forward a clipboard method to the current display

CALLED BY:	MSG_CUT, MSG_COPY, MSG_PASTE
PASS:		ds	= dgroup
		ax	= method number
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcForwardToDisplay method CalcClass, MSG_CUT, MSG_COPY, MSG_PASTE
		.enter
	;
	; Fetch the OD of the current display and forward the message on
	;
		mov	bx, ds:calcVars.CI_mode
		mov	si, ds:modeTable[bx].CM_display.chunk
		mov	bx, ds:modeTable[bx].CM_display.handle
		mov	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
CalcForwardToDisplay endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcChangeMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch to a different operating mode.

CALLED BY:	MSG_CALC_CHANGE_MODE
PASS:		ds	= dgroup
		cx	= new mode
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcChangeMode	method	CalcClass, MSG_CALC_CHANGE_MODE
		.enter
		mov	bx, ds:calcVars.CI_mode
		cmp	cx, bx
		je	done
		mov	ds:calcVars.CI_mode, cx
	;
	; Set the new group usable in manual-update mode
	;
		push	bx
		mov	bx, cx
		mov	si, ds:modeTable[bx].CM_group.chunk
		mov	bx, ds:modeTable[bx].CM_group.handle
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Set the old group not-usable in immediate mode
	;
		pop	bx		; recover old mode
		mov	si, ds:modeTable[bx].CM_group.chunk
		mov	bx, ds:modeTable[bx].CM_group.handle
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Tell the new display the current precision
	;
		mov	cx, ds:calcVars.CI_precision
		mov	bx, ds:calcVars.CI_mode
		mov	si, ds:modeTable[bx].CM_display.chunk
		mov	bx, ds:modeTable[bx].CM_display.handle
		mov	ax, MSG_CD_SET_PRECISION
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Make the display the target and focus object
	; 
		mov	ax, MSG_GEN_MAKE_FOCUS
		clr	di
		call	ObjMessage
		mov	ax, MSG_GEN_MAKE_TARGET
		clr	di
		call	ObjMessage
done:
		.leave
		ret
CalcChangeMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcSetPrecision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the current display to use a different precision.

CALLED BY:	MSG_CALC_SET_PRECISION
PASS:		ds	= dgroup
		cx	= number of decimal digits to use
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcSetPrecision method CalcClass, MSG_CALC_SET_PRECISION
		.enter
		mov	ds:calcVars.CI_precision, cx
		mov	ax, MSG_CD_SET_PRECISION
		mov	bx, ds:calcVars.CI_mode
		mov	si, ds:modeTable[bx].CM_display.chunk
		mov	bx, ds:modeTable[bx].CM_display.handle
		mov	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
CalcSetPrecision endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcBogusPrimaryActivateInteractionDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do not actually activate the default for the primary.
		Instead, forward the event to our application object
		as a FUP_KBD_CHAR so it gets handled as a regular
		accelerator.

CALLED BY:	MSG_GEN_ACTIVATE_INTERACTION_DEFAULT
PASS:		*ds:si	= CalcBogusPrimary object
		registers for keyboard event
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcBogusPrimaryActivateInteractionDefault method CalcBogusPrimaryClass,
				MSG_GEN_ACTIVATE_INTERACTION_DEFAULT
		.enter
		cmp	cx, (CS_CONTROL shl 8) or '\r'
		je	fupMeJesus
		mov	di, offset CalcBogusPrimaryClass
		CallSuper MSG_GEN_ACTIVATE_INTERACTION_DEFAULT
		jmp	done

fupMeJesus:
		mov	ax, MSG_META_FUP_KBD_CHAR
		call	GenCallApplication
done:
		.leave
		ret
CalcBogusPrimaryActivateInteractionDefault endm


ifdef	GCM
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

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
	atw	7/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcHelp	method	CalcClass, MSG_UI_HELP

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GetResourceHandleNS	HelpBox, bx
	mov	si, offset HelpBox
	clr	di
	GOTO	ObjMessage
CalcHelp	endm
endif
Main		ends

