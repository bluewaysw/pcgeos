COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial revision

DESCRIPTION:
		
	$Id: setupUtils.asm,v 1.1 97/04/04 16:28:12 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetEntryPos

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		^lbx:si - optr of list object

RETURN:		cx - LET_POSITION of user entry

DESTROYED:	ax,bx,dx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version
	dloft	5/14/92		GenList->GenItemGroup changes
-------------------------------------------------------------------------------@

GetEntryPos	proc	near
	push	bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
;	mov     bp, LET_POSITION shl offset LF_ENTRY_TYPE or \
;		mask LF_REFERENCE_USER_EXCL
	mov	di, mask MF_CALL
	call	ObjMessage			;ax <- LET_POSITION
	mov	cx, ax
	pop	bp
	ret
GetEntryPos	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MyError

DESCRIPTION:	Beeps and puts up error message in a summons.

CALLED BY:	INTERNAL ()

PASS:		bp - chunk handle of error string in Strings

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version
	dloft	5/92		Updated to 2.0

-------------------------------------------------------------------------------@

MyError	proc	near	uses	ds
	uses	ds, ax, bx, bp
	.enter
	mov	bx, handle Strings
	call	MemLock
	;
	; setup args
	;
	mov	ds, ax
	mov	bx, ds:[bp]			; get offset to error string
	sub	sp, size StandardDialogParams
	mov	bp, sp

	mov	ss:[bp].SDP_customFlags, ((CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE))
	mov	ss:[bp].SDP_customString.segment, ax
	mov	ss:[bp].SDP_customString.offset, bx
	clr	ss:[bp].SDP_helpContext.segment

	call	UserStandardDialog

	mov	bx, handle Strings
	call	MemUnlock
	.leave
	ret
MyError	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetRangeMax

DESCRIPTION:	Sets the range maximum.

CALLED BY:	INTERNAL ()

PASS:		bx:si - range object
		cx - range maximum

RETURN:		

DESTROYED:	ax,dx,bp,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version
	dloft	7/92		GenRange->GenValue changes

-------------------------------------------------------------------------------@

SetRangeMax	proc	far	uses	cx
	.enter
	mov	dx, cx
	clr	cx
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	clr	di
	call	ObjMessage
	.leave
	ret
SetRangeMax	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetRange

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		bx:si - od of range object

RETURN:		cx - range value

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version
	dloft	7/92		GenRange->GenValue changes
-------------------------------------------------------------------------------@

GetRange	proc	far
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_CALL
	call	ObjMessage			;dx <- integer part
	mov	cx, dx
	ret
GetRange	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetupQuitAppl

DESCRIPTION:	Shut ourselves down.

CALLED BY:	SetupOpenApplication, SetupReenterGEOS

PASS:		nothing

RETURN:		nothing

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

SetupQuitAppl	proc	near

	call	InitFileCommit

	;new! need to send to appl object, not process

	mov	ax, MSG_META_QUIT
	mov	bx, handle SetupApp
	mov	si, offset SetupApp
;	mov	dx, QL_BEFORE_UI
;	clr	cx
	mov     di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
SetupQuitAppl	endp


if	ERROR_CHECK

CheckDSDgroup	proc	near
	push	ax
	mov	ax, ds
	cmp	ax, dgroup
	ERROR_NE BAD_DS
	pop	ax
	ret
CheckDSDgroup	endp


CheckESDgroup	proc	near
	push	ax
	mov	ax, es
	cmp	ax, dgroup
	ERROR_NE BAD_ES
	pop	ax
	ret
CheckESDgroup	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Graphical setup is complete. Put up the final screen with
		the appropriate message.

CALLED BY:	EXTERNAL
PASS:		si	= offset of GenTextDisplay in Interface to be set
			  usable as the summing-up text of the whole thing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupComplete	proc	near
		.enter
	;
	; Turn on the final text.
	;
		mov	bx, handle DoneScreen
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL
		clr	di
		call	ObjMessage
	;
	; Put up the DoneScreen
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	si, offset DoneScreen
		clr	di
		call	ObjMessage
		.leave
		ret
SetupComplete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupHidePointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hide the pointer on the default video driver

CALLED BY:	SetupOpenApplication, SetupLoadMouseDriver
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupHidePointer proc	far	uses ds, si, es
		.enter
		mov	di, DR_VID_HIDEPTR
		lds	si, ds:[defaultVideo]
		call	ds:[si].DIS_strategy
		.leave
		ret
SetupHidePointer endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupShowPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the pointer on the default video driver

CALLED BY:	SetupLoadMouseDriver
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupShowPointer proc	far	uses ds, si, es
		.enter
		mov	di, DR_VID_SHOWPTR
		lds	si, ds:[defaultVideo]
		call	ds:[si].DIS_strategy
		.leave
		ret
SetupShowPointer endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupClearContinueSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the continue setup key in the [system] category so
		we don't get run next time.

CALLED BY:	SetupRevertVideo, SetupReenterGEOS
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupClearContinueSetup	proc	far
		.enter
		mov	ax, FALSE
		mov	si, offset systemCatString
		mov	cx, ds
		mov	dx, offset continueSetupString
		call	InitFileWriteBoolean

ifdef	GPC_VERSION
	;
	; Indicate that continuing setup is no longer running, so that next
	; time when the system boots, the UI lib won't think that the user
	; power-cycles the machine without finishing setup, which causes it
	; to switch back to the system default video mode.
	;
		mov	dx, offset continueSetupRunningString
		call	InitFileDeleteEntry
endif	; GPC_VERSION

		.leave
		ret
SetupClearContinueSetup	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSetRestartMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the mode in which we'll restart next time.

CALLED BY:	EXTERNAL
PASS:		bp	= SetupMode
RETURN:		ds	= dgroup
DESTROYED:	si, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupSetRestartMode	proc	near
		.enter
		segmov	ds, dgroup, si
		mov	si, offset systemCatString
		mov	cx, ds
		mov	dx, offset setupModeString
		call	InitFileWriteInteger
		.leave
		ret
SetupSetRestartMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupLockString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down and dereference a string from our Strings resource

CALLED BY:	EXTERNAL
PASS:		si	= chunk handle of string in Strings resource
RETURN:		ds:si	= locked string
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Caller should

			mov	bx, handle Strings
			call	MemUnlock

		when it's done with the string.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupLockString	proc	far	uses bx, ax
		.enter
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]
		.leave
		ret
SetupLockString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupNextSerialScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has chosen a serial port. Put up an interrupt-number-
		request screen if the port isn't known yet. Else put up the
		next screen.

CALLED BY:	EXTERNAL (mouse & printer stuff)
PASS:		ds	= dgroup
		^lbx:si	= screen to put up if port is known
		^lcx:dx	= screen to put up if port is unknown. NOTE: THE
			  SECOND GENERIC CHILD OF THIS SCREEN MUST BE A
			  GENRANGE.
		ax	= SerialPortNum
RETURN:		carry set if port was unknown
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	We don't have to worry about setting a current interrupt level here,
	b/c if there were an interrupt level provided in the ini file, the
	serial driver would have this port as existing... if the port doesn't
	actually physically exist, then we don't care what the old interrupt
	level was -- the port's not there.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/90	Initial version
	dloft	7/92		GenRange->GenValue changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
suggestedIRQs	word	4, 3, 4, 3	; Standard interrupt levels for
					;  regular serial ports (COM1-COM4)
SetupNextSerialScreen	proc	far
		.enter
		push	ax
		push	cx
		xchg	cx, ax
		mov	ax, 1
		shl	ax, cl
		xchg	cx, ax
		mov	di, DR_STREAM_GET_DEVICE_MAP
		call	ds:[serialDriver]
		test	ax, cx
		pop	cx
		pop	ax
		jz	unknown
initiate:
		pushf
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage
		popf
		.leave
		ret
unknown:
		push	cx, dx, ax
	;
	; Locate the range child of the screen. It *must* be the second child
	; (child 1 in our 0-based numbering system).
	; 
		mov	bx, cx
		mov	si, dx
		mov	cx, 1
		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Now set the initial value for the range based on the suggested
	; level for the serial port.
	; 
		mov	si, dx
		pop	bx				; bx <- serial port
		mov	bx, cs:suggestedIRQs[bx]
		mov	dx, bx
		mov	bx, cx			; bx <- range handle,
						; dx <- IRQ
		clr	cx			; dx:cx = int.fract
		clr	bp			; not indeterminate
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		call	ObjMessage
	;
	; Recover the interrupt screen optr and slap that puppy up on screen.
	; 
		pop	bx, si
		stc
		jmp	initiate
SetupNextSerialScreen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupDefineSerialPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do whatever is necessary to define a previously-undefined
		serial port.

CALLED BY:	EXTERNAL (mouse & printer stuff)
PASS:		ax	= SerialPortNum
		cl	= chosen interrupt level
		ds	= dgroup
RETURN:		carry set if the port couldn't be defined.
DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
portBases	word	0x3f8, 0x2f8, 0x3e8, 0x2e8	; base ports for
							;  standard serial ports
SetupDefineSerialPort	proc	far
		.enter
	;
	; Now tell the current serial driver about it. CL still contains
	; the interrupt level for the port.
	; 
		push	ax
		push	cx
		mov	bx, ax
		mov	ax, cs:portBases[bx]
		mov	bx, -1			; not PCMCIA, we assume
		mov	di, DR_SERIAL_DEFINE_PORT
		call	ds:[serialDriver]
		pop	cx
		pop	ax
		jc	portError
	;
	; Now tell future generations of serial drivers about it by
	; adding a port<n> = entry in the [serial] category of the
	; ini file with a value of the interrupt level chosen.
	; 
		shr	ax
		add	al, '1'
		mov	ds:[serialPortKeyNum], al
		mov	bp, cx
		mov	si, offset serialCatString
		mov	cx, ds
		mov	dx, offset serialPortKeyString
		call	InitFileWriteInteger
		call	InitFileCommit
done:
		.leave
		ret

portError:
		mov	bp, offset portExistethNot
		call	MyError
		stc
		jmp	done
SetupDefineSerialPort	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FMDupAndAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate a resource from a tool library and make one of
		the objects in that resource a generic child of one of
		our own.

CALLED BY:	MSG_FM_DUP_AND_ADD
PASS:		^lcx:dx	= object to add as generic child, after its resource
			  has been duplicated
		bp	= FileManagerParent to which to add the duplicated
			  object
RETURN:		^lcx:dx	= duplicated object
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FMDupAndAdd	method extern dynamic SetupClass, MSG_FM_DUP_AND_ADD

EC <		cmp	bp, FMP_APPLICATION				>
EC <		ERROR_NE INVALID_FM_PARENT				>
	;
	; Fetch and save generic parent.
	; 
		mov	bx, handle SetupApp
		mov	si, offset SetupApp
		push	bx, si
	;
	; Figure thread running parent to use as thread to run duplicated
	; block.
	; 
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
	;
	; Duplicate the resource itself.
	; 
		mov	bx, cx		; bx <- resource to duplicate
		mov_tr	cx, ax		; cx <- thread to run duplicate
		clr	ax		; owned by us, please
		call	ObjDuplicateResource
	;
	; Now add the indicated object within the duplicate as the last child
	; of the appropriate generic parent.
	; 
		mov	cx, bx		; ^lcx:dx <- new child
		pop	bx, si
		mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
		mov	ax, MSG_GEN_ADD_CHILD
		mov	di, mask MF_CALL
		call	ObjMessage
		
		ret
FMDupAndAdd	endm
