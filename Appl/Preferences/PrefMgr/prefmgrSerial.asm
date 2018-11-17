COMMENT @--------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 6/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial revision

DESCRIPTION:
		
	$Id: prefmgrSerial.asm,v 1.1 97/04/04 16:27:27 newdeal Exp $

----------------------------------------------------------------------------@

CheckHack <offset SF_LENGTH eq 0>
;
; If this hack ain't true, change every occurrence of SL_8BITS (etc)
; to be shifted left by the offset SF_LENGTH


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetOptionsCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the initfile category for the serial options

CALLED BY:	INTNERAL

PASS:		CX:DX	= Pointer to category hodling serial options
				(DBCS if DBCS)

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialSetOptionsCategory	proc	near
	uses	cx, dx
	.enter

	; First set the initfile category
	;
	push	cx, dx
	mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
	call	SerialOptionsObjMessageCall

	; Now set the text
	;
	mov	bx, handle ComPortText
	mov	si, offset ComPortText
	pop	dx, bp
	call	SetText

	.leave
	ret
SerialSetOptionsCategory	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the options stored in the UI gadgets to the initfile

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Assumes that the initfile category has already been set
		with an earlier call to SerialSetOptionsCategory

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialSaveOptions	proc	near
	mov	ax, MSG_META_SAVE_OPTIONS
	GOTO	SerialOptionsObjMessageCall
SerialSaveOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrSerialSetWordLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a selection of the word length

CALLED BY:	GLOBAL (MSG_SERIAL_SET_WORD_LENGTH)

PASS:		DS, ES	= DGroup
		CX	= Word length

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrSerialSetWordLength	method dynamic	PrefMgrClass,
						MSG_SERIAL_SET_WORD_LENGTH
	.enter

	cmp	cx, SL_5BITS shl offset SF_LENGTH
	jne	not5

	;if entry '2' has the exclusive, move it to '1'
	;
	mov	cx, SB_2
	jmp	checkEntrySelected

	;if entry '1.5' has the exclusive, move it to '1'
not5:
	mov	cx, SB_1_5

checkEntrySelected:
	mov	ax, MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
	mov	bx, handle StopBitsList
	mov	si, offset StopBitsList
	mov	di, mask MF_CALL
	call	ObjMessage
	jnc	done

	mov	cx, SB_1
	call	UtilSetSelection
done:
	.leave
	ret
PrefMgrSerialSetWordLength	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrSerialSetStopRemote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If neither of the "stop remote" things are set, then
		turn off the HARDWARE item

CALLED BY:	GLOBAL (MSG_SERIAL_SET_STOP_REMOTE)

PASS:		DS, ES	= DGroup
		CX	= Selection, or GIGS_NONE if none

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrSerialSetStopRemote	method dynamic	PrefMgrClass,
						MSG_SERIAL_SET_STOP_REMOTE
	.enter

	; Turn off the HARDWARE item in the handshake list.
	;
	cmp	cx, GIGS_NONE
	jne	done
	mov	ax, MSG_GEN_ITEM_GROUP_SET_ITEM_STATE
	mov	cx, mask SFC_HARDWARE
	clr	dx
	mov	bx, handle HandshakeList
	mov	si, offset HandshakeList
	clr	di
	call	ObjMessage
done:
	.leave
	ret
PrefMgrSerialSetStopRemote	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialObtainSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the setttings for a serial port

CALLED BY:	VerifyPortSelection
	
PASS:		BP	= Local data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialObtainSettings	proc	near
installing	local	word	; non-zero if we're installing a printer
portParams	local	PrintPortInfo
	.enter	inherit

	; for serial ports, we need to fetch a whole lot more data.
	; assume all the UI objects are in one resource

	mov	serialParams.SPP_portNum, cx
	mov	bx, handle SerialUI

	; query the various UI objects to get the other pieces. Start
	; with the baud rate.
    
	mov	si, offset SerialUI:BaudRateList
	call	UtilGetSelection		; cx <- baud rate
	mov	serialParams.SPP_baud, cx
	
	; next get the parity setting

	mov	si, offset SerialUI:ParityList
	call	UtilGetSelection		; cl <- parity setting
	mov	serialParams.SPP_format, cl
	
	; next get the word length setting

	mov	si, offset SerialUI:WordLengthList
	call	UtilGetSelection		; cl <- word length
	or	serialParams.SPP_format, cl
	mov	serialParams.SPP_mode, SM_COOKED ; assume cooked
	cmp	cl, SL_7BITS		; if seven bits
	je	getStopBits		;  then we're OK
	mov	serialParams.SPP_mode, SM_RAW ; must be raw

	; check for extra stop bits
getStopBits:
	mov	si, offset SerialUI:StopBitsList
	call	UtilGetSelection
	tst	cl
	jz	afterExtra
	or	serialParams.SPP_format, mask SF_EXTRA_STOP

afterExtra:
	; get the handshake bits.

	mov	bx, handle HandshakeList
	mov	si, offset HandshakeList
	call	UtilGetSelectedBooleansFromItemGroup
	
	mov	serialParams.SPP_flow, al

	mov	bx, handle StopRemoteList
	mov	si, offset StopRemoteList
	call	UtilGetSelectedBooleansFromItemGroup
	mov	serialParams.SPP_stopRem, al	; assume DTR

	mov	bx, handle StopLocalList
	mov	si, offset StopLocalList
	call	UtilGetSelectedBooleansFromItemGroup
	mov	serialParams.SPP_stopLoc, al

	.leave
	ret
SerialObtainSettings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialOptionsObjMessageCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the serial dialog box with the passed message

CALLED BY:	INTERNAL

PASS:		AX	= Message

RETURN:		see message documentation

DESTROYED:	see messaage documentation, BX, SI, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialOptionsObjMessageCall	proc	near
	mov	bx, handle SerialPortDialog
	mov	si, offset SerialPortDialog
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
SerialOptionsObjMessageCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilGetSelectedBooleansFromItemGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return the bitwise OR of all the identifiers of all
		the selected items in a non-exclusive item group, for
		those times when you need to use PrefStringItem children
		and so can't use a PrefBooleanGroup

CALLED BY:

PASS:		^lbx:si - item group


RETURN:		ax - selected booleans

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UGSBFIG_MAX_SELECTIONS	equ	16	; at most 16 bits, so...

UtilGetSelectedBooleansFromItemGroup	proc near
	uses	cx,dx,bp
	.enter
	mov	bp, UGSBFIG_MAX_SELECTIONS
	sub	sp, size word * UGSBFIG_MAX_SELECTIONS
	mov	cx, ss
	mov	dx, sp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	bp, UGSBFIG_MAX_SELECTIONS
	sub	bp, ax		; bp <- number of extra words to clear
	mov_tr	cx, ax
	clr	ax
	jcxz	mergeDone
mergeLoop:
	pop	dx
	or	ax, dx
	loop	mergeLoop
mergeDone:
	shl	bp
	add	sp, bp
	.leave
	ret
UtilGetSelectedBooleansFromItemGroup	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the options for the a serial port

CALLED BY:	INTERNAL

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Assumes that the initfile category has already been set
		with an earlier call to SerialSetOptionsCategory

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialLoadOptions	proc	near
	mov	ax, MSG_META_LOAD_OPTIONS
	GOTO	SerialOptionsObjMessageCall
SerialLoadOptions	endp
