COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1998 -- All Rights Reserved

PROJECT:	Newdeal
MODULE:		
FILE:		prefintModem.asm

AUTHOR:		Gene Anderson, Apr 4, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/4/98		Initial revision


DESCRIPTION:
	Code for Internet module of Preferences

	$Id: prefintModem.asm,v 1.2 98/04/24 00:22:20 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefIntCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefModemDialogInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes self apply-able so that new changes will be accepted.

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= PrefModemDialogClass object
		ds:di	= PrefModemDialogClass instance data
		es 	= segment of PrefModemDialogClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefModemDialogInitiate	method dynamic PrefModemDialogClass, 
					MSG_GEN_INTERACTION_INITIATE
		.enter

	;
	; Set up the modem UI
	;
		call	ResetModemUI
	;
	; call the superclass to bring the dialog up
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, offset PrefModemDialogClass
		call	ObjCallSuperNoLock
	;
	; Make the Modem dialog applyable so even if the user makes no changes
	; the settings get applied to the [ppp] and [tcpip] sections from
	; what we figure out in [My Modem]
	;
		mov	ax, MSG_GEN_MAKE_APPLYABLE
		call	ObjCallInstanceNoLock

		.leave
		ret
PrefModemDialogInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefModemDialogReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset our UI changes

CALLED BY:	MSG_GEN_RESET
PASS:		*ds:si	= PrefModemDialogClass object
		ds:di	= PrefModemDialogClass instance data
		es 	= segment of PrefModemDialogClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefModemDialogReset	method dynamic PrefModemDialogClass, 
							MSG_GEN_RESET
		.enter

	;
	; Reset up the modem UI
	;
		call	ResetModemUI
	;
	; call the superclass to reset the dialog
	;
		mov	ax, MSG_GEN_RESET
		mov	di, offset PrefModemDialogClass
		call	ObjCallSuperNoLock

		.leave
		ret
PrefModemDialogReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefModemDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply our UI changes

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= PrefModemDialogClass object
		ds:di	= PrefModemDialogClass instance data
		es 	= segment of PrefModemDialogClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

tcpipCat	char "tcpip", 0

PrefModemDialogApply	method dynamic PrefModemDialogClass, 
							MSG_GEN_APPLY
		.enter

	;
	; call the superclass to apply the dialog
	;
		mov	ax, MSG_GEN_APPLY
		mov	di, offset PrefModemDialogClass
		call	ObjCallSuperNoLock
	;
	; Write the port # out to the [tcpip] category as well
	; as the [ppp] category (our superclass will handle that
	; from the UI).
	;
		mov	si, offset PortList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		mov	bp, ax				;bp <- value
		segmov	ds, cs, cx
		mov	si, offset tcpipCat		;ds:si <- category
		mov	dx, offset portKey		;cx:dx <- key
		call	InitFileWriteInteger

		.leave
		ret
PrefModemDialogApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetModemUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the modem dialog's UI

CALLED BY:	PrefModemDialogInitiate()
PASS:		*ds:si - PrefModemDialog object
RETURN:		al - non-zero if changes made
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/6/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

pppCat		char "ppp", 0
baudKey		char "baud", 0
modemCat	char "modem", 0
modemsKey	char "modems", 0
baudRateKey	char "baudRate", 0
portKey		char "port", 0
toneDialKey	char "toneDial", 0

ResetModemUI	proc	near
		uses	es, si, ax
stringBuf	local	MAX_INITFILE_CATEGORY_LENGTH dup (TCHAR)
catBuf		local	MAX_INITFILE_CATEGORY_LENGTH dup (TCHAR)
		.enter
ForceRef stringBuf
ForceRef catBuf
	;
	; See if there are settings already in [ppp].  If so, we're done.
	;
		push	ds, si
		segmov	ds, cs, cx
		mov	si, offset pppCat		;ds:si <- category
		mov	dx, offset baudKey		;cx:dx <- key
		call	InitFileReadInteger
		pop	ds, si
		mov	al, 0				;al <- no changes
		jnc	done				;branch if exists
	;
	; Get the modem category
	;
		call	GetModemCategory
		jc	noModems			;branch if no category
	;
	; Get the baud rate and convert it
	;
		call	ConvertBaudRate
		jc	noModems
	;
	; Get the port string "COM#" and convert it
	;
		call	ConvertComPort
		jc	noModems
	;
	; Get the tone dial setting and convert it
	;
		call	ConvertTonePulse
		mov	al, -1				;al <- changed
done::
		.leave
		ret

	;
	; No modems configured -- tell the user?
	;
noModems:
		jmp	done
ResetModemUI	endp

SetList		proc	near
		push	dx, bp
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx				;dx <- not indtrmnt.
		call	ObjCallInstanceNoLock
		pop	dx, bp
		ret
SetList		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetModemCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the 'My Modems' category or equivalent

CALLED BY:	ResetModemUI()
PASS:		ss:bp - inherited locals
RETURN:		carry - set if category doesn't exist
DESTROYED:	
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/6/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetModemCategory	proc	near
		uses	ds, bp
		.enter	inherit	ResetModemUI
	;
	; Get the [My Modem] category name.  In theory this could
	; be something besides [My Modem], although Preferences
	; currently only uses that.
	;
		segmov	ds, cs, cx
		mov	si, offset modemCat		;ds:si <- category
		mov	dx, offset modemsKey		;cx:dx <- key
		segmov	es, ss
		lea	di, ss:catBuf			;es:di <- buffer
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, size(stringBuf)>
		call	InitFileReadString

		.leave
		ret
GetModemCategory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertBaudRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the baud rate from 'My Modems' and convert it

CALLED BY:	ResetModemUI()
PASS:		ss:bp - inherited locals
RETURN:		carry - set if info doesn't exist
DESTROYED:	
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/6/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertBaudRate		proc	near
		.enter	inherit ResetModemUI
		push	ds
		segmov	ds, ss
		lea	si, ss:catBuf			;ds:si <- category
		mov	cx, cs
		mov	dx, offset baudRateKey		;cx:dx <- key
		call	InitFileReadInteger
		pop	ds
		jc	noModems			;branch if no setting
	;
	; Convert it to a divisor and set it in our list
	;
		call	BaudRateToDivisor
		jc	noModems			;branch if unknown rate
		mov	cx, ax				;cx <- divisor
		mov	si, offset BaudList
		call	SetList
		clc					;carry <- no error
noModems:
		.leave
		ret
ConvertBaudRate		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BaudRateToDivisor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a baud rate to a 115200 divisor

CALLED BY:	ConvertBaudRate()
PASS:		ax - baud rate (low word if 115200)
RETURN:		carry - set if unknown baud rate
		ax - divisor
DESTROYED:	
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/6/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BaudRateToDivisor	proc	near
		uses	cx, dx
		.enter

		cmp	ax, 0xc200			;low word of 115200?
		je	is115200			;branch if so

		mov	cx, ax				;ax <- baud rate
		movdw	dxax, 115200
		div	cx				;ax <- divisor

noError:
		clc					;carry <- no error

		.leave
		ret

is115200:
		mov	ax, 1				;ax <- divisor
		jmp	noError
BaudRateToDivisor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertComPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the com port from 'My Modems' and convert it

CALLED BY:	ResetModemUI()
PASS:		ss:bp - inherited locals
RETURN:		carry - set if info doesn't exist
DESTROYED:	
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/6/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertComPort	proc	near
		.enter	inherit	ResetModemUI

		push	ds, bp
		segmov	ds, ss
		lea	si, ss:catBuf			;ds:si <- category
		mov	cx, cs
		mov	dx, offset portKey		;cx:dx <- key
		segmov	es, ss
		lea	di, ss:stringBuf		;es:di <- buffer
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, size(stringBuf)>
		call	InitFileReadString
		pop	ds, bp
		jc	noModems			;branch if no settings
	;
	; Convert it to a number by skipping "COM"
	;
		add	di, (size TCHAR)*3
		LocalGetChar ax, esdi, NO_ADVANCE	;ax <- character
		call	LocalIsDigit
		jz	noModems			;branch if not digit
		sub	ax, '0'+1			;ax <- port #-1
		shl	ax, 1				;ax <- (port #-1)*2
		mov	cx, ax				;cx <- port
CheckHack <SERIAL_COM3-SERIAL_COM2 eq 2>
	;
	; Set it in the our list
	;
		mov	si, offset PortList
		call	SetList
		clc					;carry ,- no error
noModems:
		.leave
		ret
ConvertComPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertTonePulse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the toneDial from 'My Modems' and convert it

CALLED BY:	ResetModemUI()
PASS:		ss:bp - inherited locals
RETURN:		carry - set if info doesn't exist
DESTROYED:	
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/6/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertTonePulse	proc	near
		.enter	inherit	ResetModemUI
	;
	; Get the tone dial setting
	;
		push	ds, bp
		segmov	ds, ss
		lea	si, ss:catBuf			;ds:si <- category
		mov	cx, cs
		mov	dx, offset toneDialKey		;cx:dx <- key
		mov	ax, TRUE			;ax <- assume TRUE
		call	InitFileReadBoolean
		pop	ds, bp
	;
	; Convert it from TRUE/FALSE to 'T'/'P' and set it in our list
	;
		mov	cx, MDT_TONE			;cx <- ModemDialType
		cmp	ax, TRUE
		je	gotTonePulse
		mov	cx, MDT_PULSE			;cx <- ModemDialType
gotTonePulse:
		mov	si, offset DialTypeList	
		call	SetList
		clc					;carry <- no error
		.leave
		ret
ConvertTonePulse	endp

PrefIntCode	ends