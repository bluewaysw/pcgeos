COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1998 -- All Rights Reserved

PROJECT:	Newdeal
MODULE:		
FILE:		prefint.asm

AUTHOR:		Gene Anderson, Mar 25, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/25/98		Initial revision


DESCRIPTION:
	Code for Internet module of Preferences

	$Id: prefintDialog.asm,v 1.2 98/04/24 00:22:15 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefIntCode	segment resource

accessCat	char "accessPoint0001",0
phoneKey	char "phone",0
ipaddrKey	char "ipaddr",0
dns1Key		char "dns1",0
secretKey	char "secret",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefIntDialogInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes self apply-able so that new changes will be accepted.

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= PrefIntDialogClass object
		ds:di	= PrefIntDialogClass instance data
		es 	= segment of PrefIntDialogClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefIntDialogInitiate	method dynamic PrefIntDialogClass, 
					MSG_GEN_INTERACTION_INITIATE,
					MSG_GEN_RESET
		.enter

	;
	; Set up the UI that can't automatically be set from the .INI file
	;
		push	si, es, ax
		call	ResetMainUI
		pop	si, es, ax
	;
	; call the superclass to bring the dialog up
	;
		mov	di, offset PrefIntDialogClass
		call	ObjCallSuperNoLock

		.leave
		ret
PrefIntDialogInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefIntDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply the changes to our UI

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= PrefIntDialogClass object
		ds:di	= PrefIntDialogClass instance data
		es 	= segment of PrefIntDialogClass
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

PrefIntDialogApply	method dynamic PrefIntDialogClass, 
					MSG_GEN_APPLY

stringBuf	local	MAX_INITFILE_CATEGORY_LENGTH dup (TCHAR)

		.enter
	;
	; Call our superclass to apply most of the changes
	;
		push	bp
		mov	di, offset PrefIntDialogClass
		call	ObjCallSuperNoLock
		pop	bp
	;
	; Write out the phone number: T(one)/P(ulse) followed by the number
	;
	; Get the T(one)/P(ulse)
	;
		push	bp
		mov	si, offset DialTypeList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pop	bp
SBCS <		mov	ss:stringBuf, al		>
DBCS <		mov	ss:stringBuf, ax		>
	;
	; Get the phone number
	;
		push	bp
		mov	si, offset PhoneNumber
		mov	dx, ss
		lea	bp, ss:stringBuf[1]		;dx:bp <- buffer
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; Write the results out
	;
		push	ds
		segmov	ds, cs, cx
		mov	si, offset accessCat		;ds:si <- category
		mov	dx, offset phoneKey		;cx:dx <- key
		segmov	es, ss, ax
		lea	di, ss:stringBuf
		call	InitFileWriteString
		pop	ds
ifdef SCRAMBLED_INI_STRINGS
	;
	; Get the password
	;
		push	bp
		mov	si, offset Password
		mov	dx, ss
		lea	bp, ss:stringBuf		;dx:bp <- buffer
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; Munge it
	;
		lea	si, ss:stringBuf		;ss:si <- buffer
	;
	; Write out the password
	;
		push	ds, bp
		lea	di, ss:stringBuf
		mov	bp, cx				;bp <- # bytes
		segmov	ds, cs, cx
		mov	si, offset accessCat		;ds:si <- category
		mov	dx, offset secretKey		;cx:dx <- key
		segmov	es, ss, ax
		call	InitFileWriteData
		pop	ds, bp
endif

		.leave
		ret
PrefIntDialogApply	endm

ifdef SCRAMBLED_INI_STRINGS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MungePassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Munge a password

CALLED BY:	PrefIntDialogApply
PASS:		ss:si - ptr to password buffer
RETURN:		none
DESTROYED:	
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MungePassword	proc	near
		uses	ax, cx, si
		.enter

		clr	cx				;cx <- # chars
mungeLoop:
		LocalGetChar ax, sssi, NO_ADVANCE	;ax <- char
		LocalIsNull ax				;NULL?
		jz	doneMunge			;branch if so
SBCS <		xor	{byte}ss:[si], 0xbc		;munge char>
DBCS <		xor	{word}ss:[si], 0xbcbc		;munge char>
		LocalNextChar sssi			;ss:si <- next char
		inc	cx				;cx <- 1 more char
DBCS <		inc	cx				;cx <- 1 more char >
		jmp	mungeLoop
doneMunge:
		.leave
		ret
MungePassword	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetMainUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the main dialog's UI

CALLED BY:	PrefIntDialogInitiate()
PASS:		*ds:si - PrefIntDialog object
RETURN:		none
DESTROYED:	
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResetMainUI	proc	near
stringBuf	local	MAX_INITFILE_CATEGORY_LENGTH dup (TCHAR)
		.enter
ForceRef stringBuf
	;
	; Skip the T(one) or P(ulse) from the phone number
	;
		mov	cx, cs
		mov	dx, offset phoneKey		;cx:dx <- key
		call	ReadAccessString
		jc	afterPhoneNumber
		cmp	{TCHAR}ss:[di], MDT_TONE
		je	skipChar
		cmp	{TCHAR}ss:[di], MDT_PULSE
		jne	afterSkip
skipChar:
		inc	di				;skip 'T' or 'P'
afterSkip:
	;
	; Set the text in the Phone Number field
	;
		push	bp
		mov	dx, ss
		mov	bp, di				;dx:bp <- ptr to text
		mov	si, offset PhoneNumber
		call	ReplaceText
		pop	bp
afterPhoneNumber:
	;
	; See if the IP address is server assigned (0.0.0.0)
	;
		mov	dx, offset ipaddrKey		;cx:dx <- key
		mov	si, offset IPList		;si <- list
		call	SetIPList
	;
	; See if the DNS address is server assigned (0.0.0.0)
	;
		mov	dx, offset dns1Key		;cx:dx <- key
		mov	si, offset DNSList		;si <- list
		call	SetIPList
ifdef SCRAMBLED_INI_STRINGS
	;
	; Get the password
	;
		push	ds, bp
		segmov	es, ss, di
		mov	ds, di
		lea	di, ss:stringBuf		;es:di <- buffer
		segmov	ds, cs, cx
		mov	si, offset accessCat		;ds:si <- category
		mov	dx, offset secretKey		;cx:dx <- key
		mov	bp, MAX_INITFILE_CATEGORY_LENGTH
		call	InitFileReadData
		pop	ds, bp
		mov	si, cx
		mov	ss:stringBuf[si], 0		;NULL-terminate
	;
	; Munge it
	;
		lea	si, ss:stringBuf
		call	MungePassword
	;
	; Set the text
	;
		push	bp
		mov	si, offset Password		;si <- text obj
		mov	dx, ss
		lea	bp, ss:stringBuf		;dx:bp <- buffer
		call	ReplaceText
		pop	bp
endif

		.leave
		ret
ResetMainUI	endp


;
; pass:
;	ss:bp - inherited locals
;	cx:dx - ptr to INI key
;
ReadAccessString	proc	near
		uses	ds, si
		.enter	inherit	ResetMainUI

		segmov	ds, cs, si
		mov	si, offset accessCat		;ds:si <- category
		call	ReadIniString

		.leave
		ret
ReadAccessString	endp

;
; pass:
;	ss:bp - inherited locals
;	ds:si - ptr to INI category
;	cx:dx - ptr to INI key
;
ReadIniString	proc	near
		uses	bp, es
		.enter	inherit	ResetMainUI

		segmov	es, ss, di
		lea	di, ss:stringBuf		;es:di <- buffer
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, size(stringBuf)>
		call	InitFileReadString

		.leave
		ret
ReadIniString	endp

;
; pass:
;	dx:bp - ptr to NULL-terminated text
;	si - text object to replace text in
;
ReplaceText	proc	near
		uses	ax, cx
		.enter

		clr	cx				;cx <- NULL-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock

		.leave
		ret
ReplaceText	endp

;
; pass:
;	ss:bp - inherited locals
;	cs:dx - ptr to INI key
;	*ds:si - list to set
;
SetIPList	proc	near
		.enter	inherit	ResetMainUI

	;
	; Check the .INI file for 0.0.0.0
	;
		mov	cx, cs
		call	ReadAccessString
		jc	serverAssignedIP
		segmov	es, ss, di
		lea	di, ss:stringBuf
		call	CheckNullIP
		mov	cx, IPAS_SERVER			;cx <- ID
		je	serverAssignedIP
		mov	cx, IPAS_USER			;cx <- ID
serverAssignedIP:
	;
	; Set the selection -- server or user assigned
	;
		push	bp
		clr	dx				;dx <- not indtrmnt.
		mov	ax, MSG_PREF_ITEM_GROUP_SET_ORIGINAL_SELECTION
		call	ObjCallInstanceNoLock
	;
	; Force the list to enable/disable things by updating the status
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		clr	cx
		call	ObjCallInstanceNoLock
		pop	bp

		.leave
		ret
SetIPList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNullIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a string is the null IP address 0.0.0.0

CALLED BY:	SetIPList()
PASS:		es:di - ptr to string
RETURN:		z flag - set (jz) if null IP
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDefNLString nullIP <"0.0.0.0",0>

CheckNullIP	proc	near
	uses	ds, si
	.enter

	segmov	ds, cs, si
	mov	si, offset nullIP			;ds:si <- ptr to nullIP
	call	LocalCmpStrings

	.leave
	ret
CheckNullIP	endp

PrefIntCode	ends
