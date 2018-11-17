COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Globalpc 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Parental Control library
FILE:		parentControl.asm

AUTHOR:		Edwin Yu, July  27, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	7/27/99   	Initial revision


DESCRIPTION:
	$Id: $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include timedate.def

idata	segment
	ParentalControlClass
idata	ends

PCCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCControlBringupPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the Password dialog, for either setting a new
		password, or enter a password for authentication.

CALLED BY:	Other library or application.
PASS:		*ds:si	= ParentalControlClass object
		ds:di	= ParentalControlClass instance data
		ds:bx	= ParentalControlClass object (same as *ds:si)
		es 	= segment of ParentalControlClass
		ax	= message
		cx	= PC_ON - bring up the 'set password' dialog
			  PC_OFF - bring up the 'enter password' dialog
RETURN:		ax = IC_OK - password(s) is verified.
		     IC_CANCEL - password not set, or incorrect.
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	(1) Duplicate the Password resource segment
	(2) Append the top password dialog to the controller object,
	    set it usable.
	(3) UserDoDialog
	(4) Destroy the duplicated resource block
	(5) Return the user interaction flag: IC_OK, IC_CANCEL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	7/28/99   	Initial version
	jfh	6/5/02	added im and ftp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
accessCat	char	"PCtrl", 0
accessBrowser	char	"BWS", 0
accessBrowserL	char	"BWSL", 0
accessEmail	char	"EML", 0
accessNewsgroup	char	"NWS", 0
accessChat	char	"CHT", 0
accessIM	char	"IM", 0
accessFTP	char	"FTP", 0
accessState	char	"TURN", 0
PCControlBringupPassword	method dynamic ParentalControlClass, 
					MSG_PC_BRING_UP_PASSWORD_DB
	uses	di
	.enter
	;
	;  First, duplicate the right resource block.
	;
	mov	di, offset SetPassword
	cmp	cx, 0	; 0 == user selected ParentalCcontrol_ON 
	je	SetPasswd
	mov	di, offset EnterPassword
SetPasswd:
	mov	bx, handle PCControlPasswordUI
	call	DuplicateResourceAndAddChildToRoot
	jc	done
tryAgain:
	call	UserDoDialog
	cmp	ax, IC_NULL
	je	cancelAction
	cmp	ax, IC_DISMISS
	je	cancelAction
	;
	; If we're dealing with Set Password, verify the first entered and 
	; the re-confirmed passwords are the same.
	; If we're dealing with Enter Password, check the authentication of
	; entered password against the stored one.
	cmp	cx, 0	; 0 == user selected ParentalControl_ON
	je	compare2passwds
	; Otherwise verify authentication
	call	VerifyAuthentication
	jmp	result
compare2passwds:
	call	VerifyEnteredPasswords
result:
	jnc	same
	jmp	tryAgain	; password(s) is(are) invalid(inconsistent)
same:
	;
	;  Set parental control ON/OFF in the ini file
	;
	push	ds, si, ax, dx
	mov	dx, 1
	jcxz	setOn
	clr	dx
setOn:
	mov	ax, dx
	segmov	ds, cs
	mov	si, offset accessCat     ; ds:si - category ASCIIZ string
	mov	cx, cs
	mov	dx, offset accessState   ; cx:dx - key ASCIIZ string
	call	InitFileWriteBoolean
	pop	ds, si, ax, dx

cancelAction:
	call	UserDestroyDialog
done:
	.leave
	ret
PCControlBringupPassword	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCControlBringupWebSiteControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the web site control dialog.

CALLED BY:	
PASS:		*ds:si	= ParentalControlClass object
		ds:di	= ParentalControlClass instance data
		ds:bx	= ParentalControlClass object (same as *ds:si)
		es 	= segment of ParentalControlClass
		ax	= message
		cx	= PC_ON - bring up the 'set password' dialog
			  PC_OFF - bring up the 'enter password' dialog
RETURN:		ax = IC_OK or IC_CANCEL
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	(1) Duplicate the Password resource segment
	(2) Append the top password dialog to the controller object,
	    set it usable.
	(3) UserDoDialog
	(4) Destroy the duplicated resource block
	(5) Return the user interaction flag: IC_OK, IC_CANCEL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	7/28/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCControlBringupWebSiteControl	method dynamic ParentalControlClass,
					MSG_PC_BRING_UP_WEBSITE_DB
	uses	di
	.enter

	call	PCEnsureOpenData

	mov	di, offset WWWDialog
	mov	bx, handle PCControlWebSiteUI
	call	DuplicateResourceAndAddChildToRoot  ; bx = object block
	jc	done
	;
	; before putting up dialog, set trigger data to pass block handle
	;
	push	si
	mov	si, offset DeleteButton
	call	setTrigData
	mov	si, offset PermissionAddButton
	call	setTrigData
	mov	si, offset PermissionChangeButton
	call	setTrigData
	pop	si
  	call	UserDoDialog
	;
	; close child dialogs (in case closed by shutdown)
	;
	push	ax, si
	mov	si, offset PermissionAddDialog
	call	closeDialog
	mov	si, offset PermissionModifyDialog
	call	closeDialog
	pop	ax, si
	call	UserDestroyDialog
done:
	call	PCCloseData
	.leave
	ret

setTrigData	label	near
	sub	sp, size AddVarDataParams + size word
	mov	bp, sp
	mov	ss:[bp].AVDP_data.segment, ss
	mov	ss:[bp].AVDP_data.offset, bp
	add	ss:[bp].AVDP_data.offset, size AddVarDataParams
	mov	ss:[bp].AVDP_dataSize, size word
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	{word}ss:[bp][(size AddVarDataParams)], bx  ; our handle
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	add	sp, size AddVarDataParams + size word
	retn

closeDialog	label	near
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	retn
PCControlBringupWebSiteControl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCControlBringupWebSiteControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the web site control dialog.

CALLED BY:	Other applications.
PASS:		*ds:si	= ParentalControlClass object
		ds:di	= ParentalControlClass instance data
		ds:bx	= ParentalControlClass object (same as *ds:si)
		es 	= segment of ParentalControlClass
		ax	= message
RETURN:		ax = IC_OK or IC_CANCEL
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	(1) Duplicate the Password resource segment
	(2) Append the top password dialog to the controller object,
	    set it usable.
	(3) UserDoDialog
	(4) Destroy the duplicated resource block
	(5) Return the user interaction flag: IC_OK, IC_CANCEL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	7/28/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCControlCheckPassWordControl	method dynamic ParentalControlClass,
					MSG_PC_CHECK_PASSWORD_DB
	uses	di
	.enter

	mov	di, offset CheckPassWordDialog
	mov	bx, handle PCControlCheckPasswordUI
	call	DuplicateResourceAndAddChildToRoot
	jc	exit
	call	ChangeDialogTitle
tryAgain:
	call	UserDoDialog
	cmp	ax, IC_NULL
	je	done
	cmp	ax, IC_DISMISS
	je	done
	call	VerifyAuthentication2
	jc	tryAgain
done:
	call	UserDestroyDialog
exit:
	.leave
	ret
PCControlCheckPassWordControl	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCControlStoreWebSites
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the entered web sites into the database file.

CALLED BY:	
PASS:		*ds:si	= ParentalControlClass object
		ds:di	= ParentalControlClass instance data
		ds:bx	= ParentalControlClass object (same as *ds:si)
		es 	= segment of ParentalControlClass
		ax	= message
		cx	= object block
RETURN:		none
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	8/03/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCControlStoreWebSites	method dynamic ParentalControlClass,
					MSG_PC_SET_WEBSITES
	.enter
	;
	;  Get duplicated resource block handle (passed in CX)
	;

	mov	bx, cx
	mov	si, offset PermissionAddInput
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx
	mov	di, mask MF_CALL
	call	ObjMessage	; cx - block handle, ax - length

	push	bx
	mov	bx, cx
	call	MemLock		; ax:0 - input text input field.

	call	ParseWebSiteList

	call	MemFree

	pop	bx
	call	PCDataGetCount	; dx:ax - count
	mov	cx, ax
	mov	si, offset PermissibleList ; bx:si = PermissbleList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL
	call	ObjMessage
	;
	; send out changes
	;
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_PARENTAL_CONTROL_WEBSITE_LIST_CHANGE
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_PARENTAL_CONTROL_WEBSITE_LIST_CHANGES
	mov	bp, PCWLCT_ADD
	call	SendPCGCN

	.leave
	ret
PCControlStoreWebSites	endm


PCControlDeleteWebSite	method dynamic ParentalControlClass,
					MSG_PC_DELETE_WEBSITE
	.enter
	;
	;  Get duplicated resource block handle (passed in CX)
	;
	;
	;  Delete the current selection
	;
	push	cx
	mov	bx, cx
	mov	si, offset PermissibleList ; bx:si = PermissbleList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage	; ax - selection
	
	call	PCDataDeleteItem
	call	PCDataGetCount	; dx:ax - count
	mov	cx, ax
	pop	bx
	mov	si, offset PermissibleList ; bx:si = PermissbleList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL
	call	ObjMessage

	call	DisableDeleteModifyTriggers
	;
	; send out changes
	;
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_PARENTAL_CONTROL_WEBSITE_LIST_CHANGE
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_PARENTAL_CONTROL_WEBSITE_LIST_CHANGES
	mov	bp, PCWLCT_DELETE
	call	SendPCGCN
	.leave
	ret
PCControlDeleteWebSite	endm


PCControlModifyWebSite	method dynamic ParentalControlClass,
					MSG_PC_MODIFY_WEBSITE
	.enter
	;
	;  Get duplicated resource block handle (passed in CX)
	;
	;
	;  Delete the current selection
	;
	push	cx
	mov	bx, cx
	mov	si, offset PermissibleList ; bx:si = PermissbleList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage	; ax - selection
	
	call	PCDataDeleteItem
	;
	;  Read the modified text
	;
	mov	si, offset PermissionModifyInput
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx
	mov	di, mask MF_CALL
	call	ObjMessage	; cx - block handle, ax - length

	mov	bx, cx
	call	MemLock		; ax:0 - input text input field.

	call	ParseWebSiteList

	call	MemFree

	call	PCDataGetCount	; dx:ax - count
	mov	cx, ax
	pop	bx
	mov	si, offset PermissibleList ; bx:si = PermissbleList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL
	call	ObjMessage

	call	DisableDeleteModifyTriggers
	;
	; send out changes
	;
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_PARENTAL_CONTROL_WEBSITE_LIST_CHANGE
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_PARENTAL_CONTROL_WEBSITE_LIST_CHANGES
	mov	bp, PCWLCT_MODIFY
	call	SendPCGCN
	.leave
	ret
PCControlModifyWebSite	endm


;
; Internal code.
; User friedly: disable modify and delete button.
;
DisableDeleteModifyTriggers	proc	near
	uses	ax, si, cx, dx, di, bp
	.enter

	mov	si, offset ModifyButton ; bx:si = ModifyButton
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage	; ax - selection

	mov	si, offset DeleteButton ; bx:si = ModifyButton
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage	; ax - selection

	.leave
	ret
DisableDeleteModifyTriggers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParentalControlGetAccessInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current access settings of the following:
                WWW browser, email, newsgroup reading, chat room discussion.
PASS:		nothing
RETURN:		ax = AccessFlags

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	7/28/99   	Initial version
	jfh   6/5/02	added im and ftp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParentalControlGetAccessInfo	proc	far
	uses	bx, cx, dx, ds, si
	.enter

	clr	bx
	segmov	ds, cs
	mov	si, offset accessCat     ; ds:si - category ASCIIZ string
	mov	cx, cs
	mov	dx, offset accessBrowser ; cx:dx - key ASCIIZ string
	clr	ax
	call	InitFileReadBoolean
	tst	ax
	jz	BrowserOff
	or	bx, mask AF_WWWBROWSING
	;
	;  Is it limited browsing?
	;
	mov	dx, offset accessBrowserL ; cx:dx - key ASCIIZ string
	clr	ax
	call	InitFileReadBoolean
	tst	ax
	jz	BrowserOff
	or	bx, mask AF_WWWLIMITED

BrowserOff:
	;
	;  Is email off?
	;
	mov	dx, offset accessEmail ; cx:dx - key ASCIIZ string
	clr	ax
	call	InitFileReadBoolean
	tst	ax
	jz	EmailOff
	or	bx, mask AF_EMAIL

EmailOff:
	;
	;  Is newsgroup off?
	;
	mov	dx, offset accessNewsgroup ; cx:dx - key ASCIIZ string
	clr	ax
	call	InitFileReadBoolean
	tst	ax
	jz	NewsgroupOff
	or	bx, mask AF_NEWSGROUP

NewsgroupOff:
	;
	;  Is Chatroom off?
	;
	mov	dx, offset accessChat ; cx:dx - key ASCIIZ string
	clr	ax
	call	InitFileReadBoolean
	tst	ax
	jz	ChatroomOff
	or	bx, mask AF_CHATROOM

ChatroomOff:
	;
	;  Is IM off?
	;
	mov	dx, offset accessIM ; cx:dx - key ASCIIZ string
	clr	ax
	call	InitFileReadBoolean
	tst	ax
	jz	FTPOff
	or	bx, mask AF_IM

FTPOff:
	;
	;  Is FTP off?
	;
	mov	dx, offset accessFTP ; cx:dx - key ASCIIZ string
	clr	ax
	call	InitFileReadBoolean
	tst	ax
	jz	ParentalControl
	or	bx, mask AF_FTP

ParentalControl:
	;
	;  Is parental control on?
	;
	mov	dx, offset accessState ; cx:dx - key ASCIIZ string
	clr	ax
	call	InitFileReadBoolean
	tst	ax
	jz	done
	or	bx, mask AF_PCON
		
done:
	;	mov	ax, mask AF_WWWBROWSING or mask AF_CHATROOM
	mov	ax, bx
	.leave
	ret
ParentalControlGetAccessInfo	endp

;
; bx:ax = GCNSLT_
; cx:dx = manuf ID:GWNT_
; bp = data
; 
SendPCGCN	proc	near
	push	bx, ax
	mov	ax, MSG_META_NOTIFY
	clr	bx, si				; let any object class handle
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	bx, ax
	mov	cx, di				; cx = notify event
	clr	dx				; no data block
	mov	bp, mask GCNLSF_FORCE_QUEUE	; (just in case)
	call	GCNListSend
	ret
SendPCGCN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParentalControlSetAccessInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current access settings to the ini file.
                WWW browser, email, newsgroup reading, chat room discussion.
PASS:		ax = AccessFlags
RETURN:		nothing

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	7/28/99   	Initial version
   jfh	6/5/02	added IM & FTP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParentalControlSetAccessInfo	proc	far
	uses	ax, bx, cx, dx, ds, si, di, bp
	.enter

	mov	bx, ax

	segmov	ds, cs
	mov	si, offset accessCat     ; ds:si - category ASCIIZ string
	mov	cx, cs
	mov	dx, offset accessBrowser ; cx:dx - key ASCIIZ string
	clr	ax
	test	bx, mask AF_WWWBROWSING
	jz	browserOff
	mov	ax, TRUE
browserOff:
	call	InitFileWriteBoolean

	;
	;  Is it limited browsing?
	;
	mov	dx, offset accessBrowserL ; cx:dx - key ASCIIZ string
	clr	ax
	test	bx, mask AF_WWWLIMITED
	jz	limitedOff
	mov	ax, TRUE
limitedOff:
	call	InitFileWriteBoolean

	;
	;  Is email off?
	;
	mov	dx, offset accessEmail ; cx:dx - key ASCIIZ string
	clr	ax
	test	bx, mask AF_EMAIL
	jz	emailOff
	mov	ax, TRUE
emailOff:
	call	InitFileWriteBoolean

	;
	;  Is newsgroup off?
	;
	mov	dx, offset accessNewsgroup ; cx:dx - key ASCIIZ string
	clr	ax
	test	bx, mask AF_NEWSGROUP
	jz	newsgroupOff
	mov	ax, TRUE
newsgroupOff:
	call	InitFileWriteBoolean

	;
	;  Is Chatroom off?
	;
	mov	dx, offset accessChat ; cx:dx - key ASCIIZ string
	clr	ax
	test	bx, mask AF_CHATROOM
	jz	chatroomOff
	mov	ax, TRUE
chatroomOff:
	call	InitFileWriteBoolean

	;
	;  Is IM off?
	;
	mov	dx, offset accessIM ; cx:dx - key ASCIIZ string
	clr	ax
	test	bx, mask AF_IM
	jz	IMOff
	mov	ax, TRUE
IMOff:
	call	InitFileWriteBoolean

	;
	;  Is FTP off?
	;
	mov	dx, offset accessFTP ; cx:dx - key ASCIIZ string
	clr	ax
	test	bx, mask AF_FTP
	jz	FTPOff
	mov	ax, TRUE
FTPOff:
	call	InitFileWriteBoolean

	;
	; notify of change
	;
	mov	bp, bx				; bp = new AccessFlags
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_PARENTAL_CONTROL_CHANGE
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_PARENTAL_CONTROL_CHANGE
	call	SendPCGCN

	.leave
	ret
ParentalControlSetAccessInfo	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	The following are the internal code.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; Internal code
;
; Pass: ax:0 - starting address of URLs, separated by white spaces by
;              assumption.
; Return: dx - number of items added to the database file
; Strategy:  - scan through the input entry,
;            - extract URLs, and
;            - store the URLs into the database file
;
ParseWebSiteList	proc	near
	uses	ds, si, di, ax, cx, bp
	.enter

	mov	ds, ax
	clr	si, di		; ds:[si] points to the url addresses
	clr	cx, dx		; dx - counter of entered URLs
nextUrl:

	cmp	{TCHAR}ds:[si], C_SPACE
	je	whiteSpace
ifdef DO_DBCS
	cmp	{TCHAR}ds:[si], C_HORIZONTAL_TABULATION
	je	whiteSpace
	cmp	{TCHAR}ds:[si], C_CARRIAGE_RETURN
	je	whiteSpace
	cmp	{TCHAR}ds:[si], C_LINE_FEED
	je	whiteSpace
else
	cmp	{TCHAR}ds:[si], C_TAB
	je	whiteSpace
	cmp	{TCHAR}ds:[si], C_CR
	je	whiteSpace
	cmp	{TCHAR}ds:[si], C_LF
	je	whiteSpace
endif
	cmp	{TCHAR}ds:[si], C_NULL
	je	whiteSpace
	; edwdig was here
	cmp	{TCHAR}ds:[si], ','
	je whiteSpace
	cmp	{TCHAR}ds:[si], ';'
	je whiteSpace
	; end edwdig
	jcxz	newUrl
	jmp	ok

newUrl:
	mov	cx, 1	; turn on a flag that we got a non-white space char
	mov	di, si
	jmp	ok
whiteSpace:
	cmp	cx, 1
	jne	skipWhiteSpace
	;  From ds:[di] to ds:[si] is the new URL
	;  store the new URL into a database
	call	PCStoreURLs
	mov	cx, 0
	jnc	skipWhiteSpace	; already there, didn't store
	inc	dx	; dx - counter of URLs
skipWhiteSpace:
	mov	di, si
ok:
	tst	{TCHAR}ds:[si]
	jz	noMore
	LocalNextChar	dssi
	jmp	nextUrl

noMore:

	.leave
	ret
ParseWebSiteList	endp



; Internal code
;
; Verify the two entered new passwords are the same.
;
; Pass: ^lbx:si - dialog object
;
VerifyEnteredPasswords	proc	near
passwdBuf		local	MAX_PASSWORD_SOURCE_LENGTH + 1 dup (TCHAR)
passwd2Buf		local	MAX_PASSWORD_SOURCE_LENGTH + 1 dup (TCHAR)
	uses	ax, cx, dx, bp, di, si, ds, es
	.enter

	push	bp
	mov	dx, ss
	lea	bp, passwdBuf
	mov	si, offset SetPasswordInput
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage			; passwdBuf filled
	pop	bp
	push	bp
	lea	bp, passwd2Buf
	mov	si, offset ConfirmPassword
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage			; passwd2Buf filled
	pop	bp

	segmov	ds, ss
	segmov	es, ss
	lea	si, passwdBuf
	lea	di, passwd2Buf
	clr	cx			; compare full null-term'ed length
	call	LocalCmpStrings
	jz	equal
	;
	; The confirmation password is different from the first
	; entered password.  Bring up a warning.
	;
	mov	si, offset PasswordInconsistent
	call	UserDoDialog
	stc
	jmp	exit
equal:
	call	StorePasswordToInit
	clc
exit:
	.leave
	ret
VerifyEnteredPasswords	endp

;  Internal code
;  es:di - password
;
accessPassword	TCHAR	"drowssap", 0	; password
StorePasswordToInit	proc	near
passwordEncripted	local	PASSWORD_ENCRYPTED_SIZE + 1 dup (TCHAR)
	uses	cx, dx, si, ds
	.enter

	segmov	ds, es
	mov	si, di
	segmov	es, ss
	lea	di, passwordEncripted
	call	UserEncryptPassword
	; es:di - filled with enscripted password
	mov	{TCHAR}es:[di+8*(size TCHAR)], 0

	segmov	ds, cs
	mov	si, offset accessCat     ; ds:si - category ASCIIZ string
	mov	cx, cs
	mov	dx, offset accessPassword ; cx:dx - key ASCIIZ string
	; es:di - encripted password
	call	InitFileWriteString

	.leave
	ret
StorePasswordToInit	endp


; Internal code
;
; Verify the entered password is the same as stored.
;
; Pass:	    ^lbx:si - root dialog box
; Return:   carry clear - ok,passed.
;           carry set   - nope, intrusion.
;
VerifyAuthentication	proc	near
passwdBuf2		local	MAX_PASSWORD_SOURCE_LENGTH + 1 dup (TCHAR)
	uses	ax, cx, dx, bp, di, si, ds, es
	.enter

	push	bp
	mov	dx, ss
	lea	bp, passwdBuf2
	mov	si, offset EnterPasswordInput
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage		; dx:bp=passwd2Buf filled
	mov	cx, bp
	pop	bp
	; dx:cx = string to be compared with
	call	VerifyAuthenticationLow	
	jnc	equal
	;
	; The confirmation password is different from the first
	; entered password.  Bring up a warning.
	;
	mov	si, offset InvalidPassword
	call	UserDoDialog
	stc
equal:
	.leave
	ret
VerifyAuthentication	endp

; Internal code
;
; Verify the entered password is the same as stored.
;
; Pass:	    ^lbx:si - root dialog box
; Return:   carry clear - ok,passed.
;           carry set   - nope, intrusion.
;
VerifyAuthentication2	proc	near
passwdBuf2		local	MAX_PASSWORD_SOURCE_LENGTH + 1 dup (TCHAR)
	uses	ax, cx, dx, bp, di, si, ds, es
	.enter

	push	bp
	mov	dx, ss
	lea	bp, passwdBuf2
	mov	si, offset NewsReaderEnterPassword
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage		; dx:bp=passwd2Buf filled
	mov	cx, bp
	pop	bp
	; dx:cx = string to be compared with
	call	VerifyAuthenticationLow	
	jnc	equal
	;
	; The confirmation password is different from the first
	; entered password.  Bring up a warning.
	;
	mov	si, offset InvalidPassword2
	call	UserDoDialog
	stc
equal:
	.leave
	ret
VerifyAuthentication2	endp

;
;  Pass:  dx:cx = string to be compared with the one stored in ini file
;  Return: carry set if entered password is not same as stored.
;
VerifyAuthenticationLow	proc	near
StringSeg		local	word	push dx
StringOff		local	word	push cx
passwdBuf		local	PASSWORD_ENCRYPTED_SIZE + 1 dup (TCHAR)
passwordEncripted	local	PASSWORD_ENCRYPTED_SIZE + 1 dup (TCHAR)
dateTimeBuffer		local	DATE_TIME_BUFFER_SIZE dup (TCHAR)
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter

	mov	ds, dx
	mov	si, cx			; ds:si - original password text

	segmov	es, ss
	lea	di, passwordEncripted	; es:di - buffered encripted passwd
	call	UserEncryptPassword

	segmov	ds, cs
	mov	si, offset accessCat     ; ds:si - category ASCIIZ string
	mov	cx, cs
	mov	dx, offset accessPassword ; cx:dx - key ASCIIZ string
	lea	di, passwdBuf

	push	bp
	mov	bp, InitFileReadFlags <IFCC_INTACT,0,0,PASSWORD_ENCRYPTED_SIZE+1>
	call	InitFileReadString	; es:di - filled
	pop	bp
	jc	error

	segmov	ds, ss
	lea	si, passwordEncripted
	mov	cx, PASSWORD_ENCRYPTED_SIZE
SBCS <	repe	cmpsb						>
DBCS <	repe	cmpsw						>

	clc
	jz	equal
	;
	;  Not equal.  Let's check if the enetered password is
	;  equal to the date.
	;
	call	TimerGetDateAndTime	; ax = year, bl = month
					; bh = day, cl = day of week
	segmov	es, ss
	lea	di, dateTimeBuffer
	mov	si, DTF_SHORT
	call	LocalFormatDateTime	; cx = size w/o null
	clr	{TCHAR}es:[di+8]
	segmov	es, ss
	segmov	ds, ss
	lea	si, dateTimeBuffer
	lea	di, passwordEncripted	; es:di - buffered encripted passwd
	call	UserEncryptPassword

	mov	ds, StringSeg
	mov	si, StringOff
	mov	cx, PASSWORD_ENCRYPTED_SIZE
SBCS <	repe	cmpsb						>
DBCS <	repe	cmpsw						>

	clc
	jz	equal
error:
	stc
equal:
	.leave
	ret
VerifyAuthenticationLow	endp

;
; Internal code
;
; Duplicate the resource
;
; pass:    *ds:si - root object
;          di    - offset of the child dialog
;	   bx    - resource segment handle where the child locates
; Return carry clear if successful
;	  ^lbx:si - child object that is desired.
;	 carry set if error (no app object)
;	   ax = IC_OK
;
; Revision: edwin 7/28/99
;
DuplicateResourceAndAddChildToRoot	proc	near
	uses	ax, cx, dx, bp, di
	.enter

	mov	bp, bx			; bp = template resource
	mov	cx, ds:[LMBH_handle]	; ^lcx:dx = root object
	mov	dx, si
	clr	bx
	call	GeodeGetAppObject
	tst	bx
	mov	ax, IC_OK		; in case no app object
	stc
	jz	done
	push	cx, dx			; (1) ^lcx:dx = root object
	push	bx, si			; (2) ^lbx:si = app obj
	mov	ax, MGIT_OTHER_INFO
	call	MemGetInfo		; ax = burden thread
	mov	cx, ax
	mov	ax, 0
	mov	bx, bp
	call	ObjDuplicateResource	; bx - handle of duplicate block

	mov	cx, bx			; handle of duplicated block
	mov	dx, di			; ^lcx:dx - child object to append
	mov	bp, CCO_LAST
	pop	bx, si			; (2) ^lbx:si = app obj
	mov	ax, MSG_GEN_ADD_CHILD
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	movdw	bxsi, cxdx		; ^lbx:si = child object
	pop	cx, dx			; (1) ^lcx:dx = root object
	mov	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
	call	ObjMessage
	mov	ax, MSG_GEN_SET_USABLE	; set child object usable
	mov	dl, VUM_NOW
	call	ObjMessage
	clc
done:
	.leave
	ret
DuplicateResourceAndAddChildToRoot	endp


; Internal code
;
; Verify the entered password is the same as stored.
;
; Pass:
; Return:   carry clear - ok,passed.
;           carry set   - nope, intrusion.
;
ChangeDialogTitle	proc	near
	uses	ax, cx, dx, bp, di, si
	.enter
	cmp	cl, PC_WWW
	je	www
	cmp	cl, PC_CHAT
	je	chat
	cmp	cl, PC_NEWSGROUP
	je	newsgroup
	cmp	cl, PC_EMAIL
	je	email
	cmp	cl, PC_PARENTAL_CONTROL
	je	pctrl
	mov	bp, offset defaultTitle
	jmp	ok
www:
	mov	bp, offset wwwTitle
	jmp	ok
chat:
	mov	bp, offset chatTitle
	jmp	ok
newsgroup:
	mov	bp, offset newsgroupTitle
	jmp	ok
email:
	mov	bp, offset emailTitle
	jmp	ok
pctrl:
	mov	bp, offset pcTitle
ok:
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	dx, handle PCControlStrings
	mov	si, offset PasswordTitle
	clr	cx
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
ChangeDialogTitle	endp


;
; C stubs
;
SetGeosConvention

	global PARENTALCONTROLGETACCESSINFO:far
PARENTALCONTROLGETACCESSINFO	proc	far
		.enter
		call	ParentalControlGetAccessInfo  ; ax = flags
		.leave
		ret
PARENTALCONTROLGETACCESSINFO	endp

	global PARENTALCONTROLSETACCESSINFO:far
PARENTALCONTROLSETACCESSINFO	proc	far	flags:word
		.enter
		mov	ax, flags
		call	ParentalControlSetAccessInfo
		.leave
		ret
PARENTALCONTROLSETACCESSINFO	endp

PCCode	ends

