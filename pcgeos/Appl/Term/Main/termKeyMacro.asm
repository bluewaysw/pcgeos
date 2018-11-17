COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Dove
MODULE:		
FILE:		termKeyMacro.asm

AUTHOR:		Eric Yeh, Oct 15, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/15/96   	Initial revision


DESCRIPTION:
		
	Key Macro related module.  This module stores the key macros in a
datastore file titled "NetworkKeyMacros."

	$Id: termKeyMacro.asm,v 1.1 97/04/04 16:55:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


udata segment

	KeyMacroDsToken		word	; datastore token for Key macro file

udata ends

; datastore file name
KeyMacroFileName	wchar	"NetworkKeyMacros",0

; datastore field name
KeyMacroNameFieldString	wchar	"Macro Text",0

; ---------------------------------------------------------------------------
;
;		Dove Network App Specific Routines
;
; ---------------------------------------------------------------------------

MacroFieldTable		word	offset KeyMacro1Field, offset KeyMacro2Field, offset KeyMacro3Field, offset KeyMacro4Field, offset KeyMacro5Field


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermWriteKeyMacro1,2,3,4,5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes out appropriate key macro

CALLED BY:	MSG_TERM_WRITE_KEY_MACRO
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #

RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: *** note *** this is specific to the Dove Network
application.  It grabs the text from appropriate text object in the
SetKeyMacro dialog box.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermWriteKeyMacro1	method dynamic TermClass, 
					MSG_TERM_WRITE_KEY_MACRO1

	uses	ax, cx, dx, bp
	.enter
	
	;shl	cx	; word offset
	;mov	di, cx
	
	mov	si, cs:[MacroFieldTable]	; set offset to field
	mov	bx, handle KeyMacro1Field
	
	mov	dx, es
	mov	bp, offset StringBuffer
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage	

	
;if DBCS_PCGEOS
;	shl	cx	; since SendBuffer sends size in bytes
;endif ; DBCS_PCGEPS

	segmov	ds, es, bx
	mov	si, bp	; set to StringBuffer

	call	BufferedSendBuffer	; write out to com port

	.leave
	ret
TTermWriteKeyMacro1	endm

TTermWriteKeyMacro2	method dynamic TermClass, 
					MSG_TERM_WRITE_KEY_MACRO2

	uses	ax, cx, dx, bp
	.enter
	
	;shl	cx	; word offset
	;mov	di, cx
	
	mov	si, cs:[MacroFieldTable][2]	; set offset to field
	mov	bx, handle KeyMacro1Field
	
	mov	dx, es
	mov	bp, offset StringBuffer
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage	

	
;if DBCS_PCGEOS
;	shl	cx	; since SendBuffer sends size in bytes
;endif ; DBCS_PCGEPS

	segmov	ds, es, bx
	mov	si, bp	; set to StringBuffer

	call	BufferedSendBuffer	; write out to com port

	.leave
	ret
TTermWriteKeyMacro2	endm

TTermWriteKeyMacro3	method dynamic TermClass, 
					MSG_TERM_WRITE_KEY_MACRO3

	uses	ax, cx, dx, bp
	.enter
	
	;shl	cx	; word offset
	;mov	di, cx
	
	mov	si, cs:[MacroFieldTable][4]	; set offset to field
	mov	bx, handle KeyMacro1Field
	
	mov	dx, es
	mov	bp, offset StringBuffer
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage	

	
;if DBCS_PCGEOS
;	shl	cx	; since SendBuffer sends size in bytes
;endif ; DBCS_PCGEPS

	segmov	ds, es, bx
	mov	si, bp	; set to StringBuffer

	call	BufferedSendBuffer	; write out to com port

	.leave
	ret
TTermWriteKeyMacro3	endm

TTermWriteKeyMacro4	method dynamic TermClass, 
					MSG_TERM_WRITE_KEY_MACRO4

	uses	ax, cx, dx, bp
	.enter
	
	;shl	cx	; word offset
	;mov	di, cx
	
	mov	si, cs:[MacroFieldTable][6]	; set offset to field
	mov	bx, handle KeyMacro1Field
	
	mov	dx, es
	mov	bp, offset StringBuffer
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage	

	
;if DBCS_PCGEOS
;	shl	cx	; since SendBuffer sends size in bytes
;endif ; DBCS_PCGEPS

	segmov	ds, es, bx
	mov	si, bp	; set to StringBuffer

	call	BufferedSendBuffer	; write out to com port

	.leave
	ret
TTermWriteKeyMacro4	endm

TTermWriteKeyMacro5	method dynamic TermClass, 
					MSG_TERM_WRITE_KEY_MACRO5

	uses	ax, cx, dx, bp
	.enter
	
	;shl	cx	; word offset
	;mov	di, cx
	
	mov	si, cs:[MacroFieldTable][8]	; set offset to field
	mov	bx, handle KeyMacro1Field
	
	mov	dx, es
	mov	bp, offset StringBuffer
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage	

	
;if DBCS_PCGEOS
;	shl	cx	; since SendBuffer sends size in bytes
;endif ; DBCS_PCGEPS

	segmov	ds, es, bx
	mov	si, bp	; set to StringBuffer

	call	BufferedSendBuffer	; write out to com port

	.leave
	ret
TTermWriteKeyMacro5	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateKeyMacroDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	updates key macros fields of the Set Key Macro (3.6) dialog

CALLED BY:	
PASS:	update options:
		C set = reset menu monikers
		C clear = don't reset menu monikers
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		- open key macro datastore
		- set fields
		- sets field modified bit to NOT_MODIFIED
		- close key macro datastore

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MacroOffsetList	word	offset MacroTrigger1, offset MacroTrigger2, offset MacroTrigger3, offset MacroTrigger4, offset MacroTrigger5;

UpdateKeyMacroDialog	proc	near
localFlag	local	byte
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	push	bp
	; set localFlag based on carry
	jc	set_local_flag_update_key_macro_dialog
	clr	localFlag	; cleared, don't reset menu monikers

set_local_flag_update_key_macro_dialog:
	mov	localFlag, 1	; set, reset menu monikers

start_update_key_macro_dialog:
	call	OpenKeyMacroFile
	
	clr	cx	; start at 0

assign_loop_update_key_macro:
	; get offset to field
	mov	bx, handle KeyMacro1Field	; set handle
	mov	di, cx
	shl	di	; word offset
	mov	si, cs:[MacroFieldTable][di]	; get identifier
	call	GetKeyMacroSetText	; set the text field	

	tst	localFlag	; see if menu monikers should be updated or
				; not. 
	jz	continue_loop_update_key_macro_dialog	

if DBCS_PCGEOS
	shl	ax	; set to byte size
endif ; DBCS_PCGEOS

	; set field to not modified
	push	cx, di, ax ; store current #, offset, and length of string
			   ; (bytes). 
	clr	cx
	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	mov	di, mask MF_CALL
	call	ObjMessage

	; set string and add null to the end
	call	ClearStringBuffer
	mov	dx, segment dgroup
	mov	bp, offset StringBuffer
	mov	bx, handle KeyMacro1Field
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage

	mov	di, offset StringBuffer

	; hmm.. problems with length when grabbing from field, so grab
	; the length from datastore directly


	pop	cx	; restore byte size to cx (stored in ax originally)

	add	di, cx

	mov	bx, segment dgroup
	mov	es, bx

	mov {byte}	es:[di], NULL_CHAR
if DBCS_PCGEOS
	mov {byte}	es:[di+1], NULL_CHAR_HIGH
endif ; DBCS_PCGEOS

	mov	cx, es	; set target string for below
	mov	dx, offset StringBuffer


	; now change the visMoniker of the key macro menu item
	pop	di	; restore offset to menu item



	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bx, handle MacroTrigger1	; all in same block
	mov	si, cs:[MacroOffsetList][di]
	clr	di	; no message flags
	mov	bp, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessage
	pop	cx	; restore count #

	
	
continue_loop_update_key_macro_dialog:

	inc	cx
	cmp	cx, KEY_MACRO_COUNT	; 0 based, so exits out once all
					; done. 
	jnz	assign_loop_update_key_macro	
		

	call	CloseKeyMacroFile
	pop	bp
	.leave
	ret
UpdateKeyMacroDialog	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateKeyMacros
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks key macro dialog to see which fields are modified.
Those which are modified will be saved to datastore.

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if any fields modified, opens datastore, saves to datastore, then
closes datastore.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateKeyMacros	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	
	call	OpenKeyMacroFile
	
	clr	cx	; start at 0
	mov	bx, handle KeyMacro1Field	; set handle

check_loop_update_key_macro:
	; get offset to field
	mov	di, cx
	shl	di	; word offset
	mov	si, cs:[MacroFieldTable][di]	; set offset to field

	; query to see if field is modified
	mov	ax, MSG_GEN_TEXT_IS_MODIFIED
	mov	di, mask MF_CALL
	push	cx
	call	ObjMessage
	pop	cx

	jnc	continue_check_update_key_macro	; no carry = no change

	call	SetMacroFieldFromText	; else set the macro entry

continue_check_update_key_macro:
	inc	cx
	cmp	cx, KEY_MACRO_COUNT	; 0 based, so exits out once all
					; done. 
	jnz	check_loop_update_key_macro	
		

	call	CloseKeyMacroFile	; finished committing changes, now
					; close the datastore session.

	.leave
	ret
UpdateKeyMacros	endp




; ---------------------------------------------------------------------------
; 
;		Key Macro DataStore Manipulation Routines
;
; ---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetKeyMacroSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a 0 based offset and a text object to set, sets that
text object's contents to the key macro's contents.

CALLED BY:	
PASS:		cx = macro # (0 based).
		bx:si = text object to change
RETURN:		ax = string length (chars)
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetKeyMacroSetText	proc	near
	uses	bx,cx,dx,si,di, bp
	.enter

	push	bx, si	; store text object pointer

	mov	bx, segment dgroup
	mov	es, bx

	mov	ax, es:[KeyMacroDsToken]
	clr	dx
	call	DataStoreLoadRecordNum
EC <	ERROR_C	ERROR_DS_LOAD_RECORD_NUM_GET_KEY_MACRO	>
	
	mov	ax, es:[KeyMacroDsToken]
	call	DataStoreLockRecord
EC <	ERROR_C	ERROR_DS_LOCK_RECORD_GET_KEY_MACRO	>
	
	mov	dl, KEY_MACRO_TEXT_FIELD_ID
	call	DataStoreGetFieldPtr
EC <	ERROR_C	ERROR_DS_GET_FIELD_PTR_GET_KEY_MACRO	>


if DBCS_PCGEOS
	shr	cx
endif ; DBCS_PCGEO

	; check here to see if the string is just a blank char.  If so,
	; clear the field (that way blank char would not be the first
	; character in the field text.
	
	cmp {byte}	ds:[di], BLANK_CHAR
	jnz	continue_update_key_macro

if DBCS_PCGEOS
	cmp {byte}	ds:[di+1], BLANK_CHAR_HIGH	
	jnz	continue_update_key_macro	
endif ; DBCS_PCGEOS
	clr	cx	; write over Stringbuffer with null character
	segmov	ds, es, bx
	mov	di, offset StringBuffer
	mov {byte}	ds:[di], NULL_CHAR
DBCS <	mov {byte}	ds:[di+1], NULL_CHAR_HIGH	>

continue_update_key_macro:

	mov	dx, ds	; store segment of text returned
	pop	bx, si	; restore text object pointer
	push	cx	; store length (chars)
	mov	bp, di	; set offset to text returned
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR


	call	ObjMessage

	
	mov	ax, es:[KeyMacroDsToken]
	call	DataStoreUnlockRecord

	mov	ax, es:[KeyMacroDsToken]
	call	DataStoreDiscardRecord
EC <	ERROR_C	ERROR_DS_DISCARD_RECORD_GET_KEY_MACRO	>

	pop	ax	; restore length in ax
	.leave
	ret
GetKeyMacroSetText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMacroFieldFromText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a text object and an index #, sets the #'d macro to
that value and saves it to the datastore.

CALLED BY:	
PASS:		bx:si	= text object
		cx	= index #
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Calls text object & stores string in StringBuffer.  Then string is
passed to datastore using DataStoreSetField

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMacroFieldFromText	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	ax, segment dgroup
	mov	es, ax

	; load the appropriate record	
	clr	dx
	mov	ax, es:[KeyMacroDsToken]
	call	DataStoreLoadRecordNum
EC <	ERROR_C	ERROR_DS_LOAD_RECORD_NUM_SET_MACRO_FIELD_FROM_TEXT	>

	; get the text
	call	ClearStringBuffer
	mov	dx, es
	mov	bp, offset StringBuffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage	

	mov	di, bp	; set offset to StringBuffer contents

	; need to check if length 0. If so, set length to 1 and have it be a
	; blank character.  Datastore doesn't save field if length is 0.
	tst	cx
	jnz	write_to_key_macro_datastore

	mov {byte}	es:[di], BLANK_CHAR
if DBCS_PCGEOS
	mov {byte}	es:[di+1], BLANK_CHAR_HIGH
endif ; DBCS_PCGEOS	

	mov	cx, 1

write_to_key_macro_datastore:
if DBCS_PCGEOS
	shl	cx	; char length --> byte length
endif ; DBCS_PCGEOS 

	mov	ax, es:[KeyMacroDsToken]
	clr	bx	; use field ID only
	mov	dl, KEY_MACRO_TEXT_FIELD_ID	; set field ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_SET_MACRO_FIELD_FROM_TEXT	>

	; commit record to datastore
	mov	ax, es:[KeyMacroDsToken]
	clr	cx,dx	; no callback
	call	DataStoreSaveRecord
EC <	ERROR_C	ERROR_DS_SAVE_RECORD_SET_MACRO_FIELD_FROM_TEXT	>

	.leave
	ret
SetMacroFieldFromText	endp



; ---------------------------------------------------------------------------
; 
;		Key Macro DataStore Open/Close
;
; ---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenKeyMacroFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	opens the key macro datastore.  Also performs any initial
initializations.

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	sets KeyMacroDsToken

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenKeyMacroFile	proc	near
	uses	ax,bx,cx,dx,bp
	.enter
	
	segmov	es, cs, bx
	mov	di, offset KeyMacroFileName	; set to filename
	clr	cx, dx		; no notification object
	clr	ax
	call	DataStoreOpen
	jc	error_open_key_macro_file
;EC <	ERROR_C	ERROR_DS_OPEN_OPEN_KEY_MACRO_FILE	>


exit_open_key_macro_file:
	mov	bx, segment dgroup
	mov	es, bx

	mov	es:[KeyMacroDsToken], ax	; store ds token to key
						; macro file
	.leave
	ret

error_open_key_macro_file:
	; error opening key macro file here.  Check to see if the error is
	; of type DSE_DATASTORE_NOT_FOUND. If not found, create it, else
	; signal an error
	cmp	ax, DSE_DATASTORE_NOT_FOUND
	jz	create_ds_key_macro_file
EC <	ERROR	ERROR_DS_OPEN_OPEN_KEY_MACRO_FILE	>

create_ds_key_macro_file:
	call	CreateKeyMacroDataStore
	; try again, if error, dump out now immediately.  Did this to avoid
	; problems with infinite looping.
	mov	di, offset KeyMacroFileName	; set to filename
	clr	cx, dx		; no notification object	
	clr	ax		; no flags
	call	DataStoreOpen
EC <	ERROR_C	ERROR_DS_OPEN_OPEN_KEY_MACRO_FILE	>
	jmp	exit_open_key_macro_file

OpenKeyMacroFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseKeyMacroFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes key macro file, performing cleaning up if needed.

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseKeyMacroFile	proc	near
	uses	ax,bx,bp
	.enter

	mov	bx, segment dgroup
	mov	es, bx

	mov	ax, es:[KeyMacroDsToken]	
	call	DataStoreClose

	.leave
	ret
CloseKeyMacroFile	endp




; ---------------------------------------------------------------------------
;
;		Key Macro Datastore Creation Routines
;
; ---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateKeyMacroDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
CALLED BY:	
PASS:		
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateKeyMacroDataStore	proc	near

	keylist	local	word

	uses	bx, si, di, es, bp
	.enter
	
	mov	bx, segment dgroup
	mov	es, bx

	; Now set up parameters for creating datastore
	sub	sp, size DataStoreCreateParams + 1; +1 = keep swat happy
	mov	di, sp			; set to use offset

	; set datastore file name 
	mov	si, offset KeyMacroFileName
	movdw	ss:[di].DSCP_name, cssi	
	
	; set flags
	mov	ss:[di].DSCP_flags, 0

	; set ptr to key list
	mov	cx, ss:[keylist]	 	
	movdw	ss:[di].DSCP_keyList, 0
	
	; set keycount
	mov	ss:[di].DSCP_keyCount, 0 ; no primary keys, only order of
					 ; creation 
	movdw	ss:[di].DSCP_notifObject, 0	; no notify object
	mov	ss:[di].DSCP_openFlags, 0	

	
	; Now call datastore create
	segmov	ds, ss, bx
	mov	si, di	; set offset
	call	DataStoreCreate
EC <	ERROR_C	ERROR_DS_CREATE_CREATE_KEY_MACRO_DS	>
	mov	es:[KeyMacroDsToken], ax
	add	sp, size DataStoreCreateParams + 1	; +1 = keep swat
							; happy 
	
	; now to flesh out the fields
	call	FleshOutKeyMacroDataStore

;	mov	ax, es:[KeyMacroDsToken]
;	call	DataStoreClose


;	push	es
;	segmov	es, cs
;	clr	cx, dx, ax
;	mov	si, offset KeyMacroFileName
;	call	DataStoreOpen		; reopen it?
;	pop	es
;	mov	es:[KeyMacroDsToken], ax

	; Now create entries to store in
	; Set up a null char on StringBuffer as target
	call	ClearStringBuffer	
	
	mov	di, offset StringBuffer

if DBCS_PCGEOS
	mov {byte}	es:[di], BLANK_CHAR
	mov {byte}	es:[di+1], BLANK_CHAR_HIGH
	mov {byte}	es:[di+2], NULL_CHAR
	mov {byte}	es:[di+3], NULL_CHAR_HIGH
else
	mov {byte}	es:[di], NULL_CHAR
endif ; DBCS_PCGEOS

	clr	cx	; begin count
create_record_loop_create_key_macro:
	push	cx	; store count
	mov	ax, es:[KeyMacroDsToken]
	call	DataStoreNewRecord
EC <	ERROR_C	ERROR_DS_NEW_RECORD_CREATE_KEY_MACRO_DS	>
	clr	bx


if DBCS_PCGEOS
	mov	cx, 2
else
	mov	cx, 1
endif ; DBCS_PCGEOS

;	clr	cx	; whoops, single null, so set to 0 to prevent bad
;			; field data error.	

	mov	ax, es:[KeyMacroDsToken]
	mov	dl, KEY_MACRO_TEXT_FIELD_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_SET_FIELD_CREATE_KEY_MACRO_DS	>
	
	clr	cx, dx
	mov	ax, es:[KeyMacroDsToken]
	call	DataStoreSaveRecord	; save record
EC <	ERROR_C	ERROR_DS_SAVE_RECORD_CREATE_KEY_MACRO_DS	>
	pop	cx	;  restore count
	inc	cx
	cmp	cx, KEY_MACRO_COUNT
	jnz	create_record_loop_create_key_macro

; close session
	call	CloseKeyMacroFile

KeyMacro_ds_create_exit:
	.leave
	ret


KeyMacro_ds_create_error:
	; error handler here eep!
	jmp	KeyMacro_ds_create_exit

CreateKeyMacroDataStore	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FleshOutKeyMacroDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FleshOutKeyMacroDataStore	proc	near
	uses	bx, di, si, ds, es, bp
	.enter

	mov	bx, segment dgroup
	mov	ds, bx

	; Info of Acc Pt Name
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_STRING	
	mov	ss:[di].FD_category, FC_NONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset KeyMacroNameFieldString  ; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ax, ds:[KeyMacroDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
EC <	ERROR_C	ERROR_DS_ADD_FIELD_FLESH_KEY_MACRO_DS	>
	add	sp, size FieldDescriptor + 1	; restore stack



KeyMacro_create_field_exit:
;	mov	ax, ds:[KeyMacroDsToken]
;	call	DataStoreClose

	.leave
	ret

FleshOutKeyMacroDataStore	endp

