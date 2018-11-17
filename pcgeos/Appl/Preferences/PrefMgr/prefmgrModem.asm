COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefmgrModem.asm

AUTHOR:		Don Reeves, May 18, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/18/92		Initial revision

DESCRIPTION:
	Code implements the modem support for PC/GEOS

	$Id: prefmgrModem.asm,v 1.1 97/04/04 16:27:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata	segment

; The original modem port, so we know whether to adjust the medium for the
; port.
origModemPort	SerialPortNum

udata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetModemPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the current port selection for the modem.

CALLED BY:	(INTERNAL) VisOpenModem, PrefMgrModemTweakMedia
PASS:		nothing
RETURN:		ax	= SerialPortNum/-1 (None)
DESTROYED:	bx, cx, dx, si, di, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetModemPort proc	near
	.enter
	mov	bx, handle ModemPortGroup
	mov	si, offset ModemPortGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
GetModemPort endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	VisOpenModem

DESCRIPTION:	

CALLED BY:	INTERNAL (PrefMgrVisOpen)

PASS:		ds, es - dgroup

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

----------------------------------------------------------------------------@

VisOpenModem	proc	far


if 0
; Currently, the modem name is hard-coded.  If this changes, make sure
; the category gets set *before* MSG_GEN_INTERACTION_INITIATE is sent to
; the dialog object


	call	GetModemName			;ds:si <- name, bx <- handle
	push	bx

	mov	cx, ds
	mov	dx, si
	mov	bx, handle ModemDialog
	mov	si, offset ModemDialog
	mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_META_LOAD_OPTIONS
	clr	di
	call	ObjMessage

	pop	bx
	call	MemFree
endif

	;
	; Set the modem name for the serial options
	;

	call	GetModemName			; ds:si = DBCS name for SSOC
	push	bx
	mov	cx, ds
	mov	dx, si
	call	SerialSetOptionsCategory

	pop	bx
	call	MemFree
	
	;
	; Record the current modem port, so we can change the medium for
	; that port back to GMID_SERIAL_CABLE if the user changes the port.
	;
	; XXX: This would be better implemented by adding a GET_ORIGINAL_-
	; SELECTION to PrefItemGroup, but I don't want to change the API today.
	; 				-- ardeb 1/23/95
	;
	call	GetModemPort
	
	segmov	ds, dgroup, cx
	mov	ds:[origModemPort], ax

	ret
VisOpenModem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSerialDialogMakeApplyable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the serial options dialog becoming applyable

CALLED BY:	
PASS:		*ds:si - PrefSerialDialogClass object
RETURN:		
DESTROYED:	
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	In an ideal world, this would only be called if we knew we were
	working with the modem. But as the modem and printer sections
	share this dialog, well...
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/24/02		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefSerialDialogMakeApplyable	method PrefSerialDialogClass,
							MSG_GEN_MAKE_APPLYABLE
	;
	; do normal stuff
	;
		mov	di, offset PrefSerialDialogClass
		call	ObjCallSuperNoLock
	;
	; make the modem dialog applyable, too
	;
		mov	bx, handle ModemDialog
		mov	si, offset ModemDialog
		mov	ax, MSG_GEN_MAKE_APPLYABLE
		clr	di
		GOTO	ObjMessage
PrefSerialDialogMakeApplyable	endm


COMMENT @--------------------------------------------------------------------

FUNCTION:	PrefMgrModemApply

DESCRIPTION:	

CALLED BY:	EXTERNAL (MSG_MODEM_APPLY)

PASS:		

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	for release 1, support only 1 modem

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

----------------------------------------------------------------------------@

pppCat		char "ppp",0
portKey		char "port",0
baudKey		char "baud",0

PrefMgrModemApply	method	PrefMgrClass, MSG_MODEM_APPLY

	mov	bx, handle ModemPortGroup
	mov	si, offset ModemPortGroup
	call	UtilGetSelection

	; If "none" chosen, delete category
	cmp	cx, GIGS_NONE
	jne	modemChosen
	mov	si, offset modemCatString
	call	InitFileDeleteCategory

	push	ds
if DBCS_PCGEOS
	call	GetModemIniName		;ds:si <- SBCS name, bx <- handle
else
	call	GetModemName		;ds:si <- SBCS name, bx <- handle
endif
	call	InitFileDeleteCategory
	call	MemFree
	pop	ds
	jmp	short done

modemChosen:
	;-------------------------------------------------------------------
	;store number of modems (always 1)

	mov	si, offset modemCatString
	mov	cx, ds
	mov	dx, offset numberOfModemsKeyString
	mov	bp, 1
	call	InitFileWriteInteger

	;--------------------------------------------------------------------
	;store name of modem

	call	ModemCreateName		;dgroup:printerNameBuf <- modem name
	mov	di, offset printerNameBuf
	segmov	es, ds

	mov	si, offset modemCatString
	mov	cx, dgroup
	mov	ds, cx
	mov	dx, offset modemsKeyString
	call	InitFileWriteString


	;--------------------------------------------------------------------
	;store port & dial type under "My modem" category.

	mov	ax, MSG_META_SAVE_OPTIONS
	mov	bx, handle ModemDialog
	mov	si, offset ModemDialog
	clr	di
	call	ObjMessage

	push	ds, si, bp
	;--------------------------------------------------------------------
	;store port under "ppp" category, too
	mov	bx, handle ModemPortGroup
	mov	si, offset ModemPortGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	bp, ax				;bp <- value
	segmov	ds, cs, cx
	mov	si, offset pppCat		;ds:si <- category
	mov	dx, offset portKey		;cx:dx <- key
	call	InitFileWriteInteger
	;--------------------------------------------------------------------
	;store baud under "ppp" category, too
	mov	bx, handle BaudRateList
	mov	si, offset BaudRateList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL		;no MF_FIXUP_DS (ds = cs)
	call	ObjMessage
	mov	bp, ax				;bp <- value
	segmov	ds, cs, cx
	mov	si, offset pppCat		;ds:si <- category
	mov	dx, offset baudKey		;cx:dx <- key
	call	InitFileWriteInteger

	pop	ds, si, bp

done:
	;--------------------------------------------------------------------
	;commit changes to .ini file

	call	InitFileCommit

	;--------------------------------------------------------------------
	;set the media/port
	call	PrefMgrModemTweakMedia
	ret
PrefMgrModemApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrModemTweakMedia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mess with the [media] category and the serial driver's
		record of the medium attached to the new and old modem
		port(s)

CALLED BY:	(INTERNAL) PrefMgrModemApply
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nonModemMedia	MediumType	<GMID_SERIAL_CABLE, MANUFACTURER_ID_GEOWORKS>
faxDataModemMedia MediumType	<GMID_FAX_MODEM, MANUFACTURER_ID_GEOWORKS>
dataModemMedia	MediumType	<GMID_DATA_MODEM, MANUFACTURER_ID_GEOWORKS>
mediaCatStr	char	'media', 0
comPort1Str	char	'com1', 0
comPort2Str	char	'com2', 0
comPort3Str	char	'com3', 0
comPort4Str	char	'com4', 0
comPortMediaKeys nptr.char comPort1Str, comPort2Str, comPort3Str, comPort4Str

PrefMgrModemTweakMedia proc	near
		.enter
	;
	; Set the old port back to serial cable, if the old port ain't the
	; same as the new, and it actually existed...
	;
		call	GetModemPort	; ax <- port
		mov	bx, ds:[origModemPort]
		push	ax
		cmp	bx, ax
		je	setNew
		
		cmp	bx, -1
		je	setNew			; => was none, before
		mov	si, offset nonModemMedia
		mov	cx, 1
		call	PrefMgrModemSetMediaForPort
setNew:
	;
	; See if the user has indicated it's a fax/data modem.
	;
		mov	bx, handle ModemFaxList
		mov	si, offset ModemFaxList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bx		; bx <- modem port
		
		cmp	bx, -1
		je	done		; => no modem, now

		mov	si, offset faxDataModemMedia	; assume yes
		mov	cx, 2				; cx <- # media types
		tst	ax
		jnz	haveNewMedia
	;
	; Just a data modem...
	;
		mov	si, offset dataModemMedia
		mov	cx, 1
haveNewMedia:
	;
	; Set the media for the new port.
	;
		call	PrefMgrModemSetMediaForPort
done:
		.leave
		ret
PrefMgrModemTweakMedia endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrModemSetMediaForPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the serial driver and .ini file what the media for
		a port are.

CALLED BY:	(INTERNAL) PrefMgrModemTweakMedia
PASS:		bx	= SerialPortNum
		cs:si	= MediumType array
		cx	= # elements in the array
RETURN:		nothing
DESTROYED:	ax, bx, cx, di, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrModemSetMediaForPort proc	near
		uses	ds, si, es
		.enter
		
	;
	; First write the data to the [media] category.
	;
			CheckHack <size MediumType eq 4>
		mov	bp, cx
		shl	bp
		shl	bp			; bp <- size of data to write

		push	cx
		segmov	ds, cs, cx		; ds, cx <- cs (key/cat strings)
		mov	di, si
		mov	es, cx			; es:di <- buffer to write
	    ;
	    ; Compute the port key to use.
	    ;
		Assert	l, bx, <size comPortMediaKeys>
		mov	dx, ds:[comPortMediaKeys][bx] ; cx:dx <- key

		mov	si, offset mediaCatStr	; ds:si <- category
		call	InitFileWriteData
	;
	; Now tell the serial driver.
	;
		pop	cx			; cx <- # MediumTypes
		mov	dx, cs
		mov_tr	ax, di			; dx:ax <- MediumType array
		push	bx
		mov	bx, handle serial
		call	GeodeInfoDriver		; ds:si <- DriverInfoStruct
		pop	bx
		
		mov	di, DR_SERIAL_SET_MEDIUM
		call	ds:[si].DIS_strategy
		.leave
		ret
PrefMgrModemSetMediaForPort endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	ModemCreateName

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ds,es - dgroup

RETURN:		ds:[printerNameBuf] - ASCIIZ name

DESTROYED:	ax,bx,cx,dx,di,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

----------------------------------------------------------------------------@

ModemCreateName	proc	near	uses	ds,si
	.enter
EC<	call	CheckDSDgroup						>
EC<	call	CheckESDgroup						>

	call	GetModemName			;ds:si <- DBCS name, bx <- han
	mov	di, offset printerNameBuf
	LocalCopyString
	call	MemFree
	.leave
	ret
ModemCreateName	endp

GetModemName    proc    near
        mov     bx, handle ModemNameText
        mov     si, offset ModemNameText
        call    MyGetText               ;bx <- mem han, cx - # chars w/o null
        call    MemLock
        mov     ds, ax
        clr     si
	ret
GetModemName    endp

if DBCS_PCGEOS
GetModemIniName	proc	near
	uses	es, di
	.enter
	call	GetModemName		; ds:si = DBCS name, bx = han, cx = len
	push	cx, si
	segmov	es, ds
	mov	di, si
	inc	cx			; include null
convLoop:
	lodsw
	stosb
	loop	convLoop
	pop	cx, si
	.leave
	ret
GetModemIniName	endp
endif



COMMENT @--------------------------------------------------------------------

FUNCTION:	PrefMgrModemPortSelected

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_MODEM_PORT_SELECTED)

PASS:		cx	= SerialPortNum, or -1 if "None" chosen

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

----------------------------------------------------------------------------@

PrefMgrModemPortSelected	method	PrefMgrClass, MSG_MODEM_PORT_SELECTED


comPortName	local	64 dup (char)


	.enter

	cmp	cx, -1
	je	done

	mov	cx, ss
	lea	dx, ss:[comPortName]
	push	bp
	mov	bp, size comPortName
	mov	ax, MSG_PREF_ITEM_GROUP_GET_SELECTED_ITEM_TEXT
	LoadBXSI	ModemPortGroup
	mov	di, mask MF_CALL
	call	ObjMessage
	tst	bp
	pop	bp
	jz	done			; no item text

	push	bp
	mov	dx, ss
	lea	bp, ss:[comPortName]
	mov	bx, handle ComPortText
	mov	si, offset ComPortText
	call	SetText
	pop	bp

done:
	.leave
	ret
PrefMgrModemPortSelected	endm
