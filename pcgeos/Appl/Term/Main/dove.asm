COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		dove.asm

AUTHOR:		Eric Yeh, Aug  6, 1996

ROUTINES:
	Name				Description
	----				-----------
ClearStringBuffer			clears string buffer, filling it
					with ' ' char (BLANK_CHAR) 

GetOrdinalityFromTable			given an identifier and offset to
					table, returns the identifier's 
					ordinality  

; ----------------------------------------------------------------------
;			Buttons!  Buttons!
; ----------------------------------------------------------------------
MSG_TERM_CONNECT_BUTTON_HIT		handles when connect button in main 
					window is hit.


MSG_TERM_CANCEL_BUTTON_HIT		Flushes current IAPL and Access
					Point data from record buffer.  Then
					calls up connection setting dialog.


MSG_TERM_CONNECT_OK_BUTTON_HIT		runs the script to connect
; ----------------------------------------------------------------------
;			GenDynamicList update routines
; ----------------------------------------------------------------------
MSG_TERM_UPDATE_NETWORK_NAME_LIST	query messages from Network service 
					dynamic lists call this to update
					text items.



MSG_TERM_UPDATE_ACCESS_POINT_LIST	updates gendynamic list calls for an
					access point.  Note that this
					operates relative to the offset of
					the record number in
					AccessPointOffset.  If
					NO_ACCESS_POINT, then no access
					points are available. 

; ----------------------------------------------------------------------
;			Dialog Activation Routines
; ----------------------------------------------------------------------
ActivateConnectionConfirm		sets selection to current network
					service 

MSG_TERM_ACTIVATE_CONNECTION_CONFIRM	calls ActivateConnectionConfirm

ActivateConnectionSetting		sets up appropriate children
					triggers and brings up connection
					confirm dialog. 

MSG_TERM_ACTIVATE_CONNECTION_SETTING	calls ActivateConnectionSetting

ActivateNetworkSelection		sets up appropriate children
					triggers and brings up network
					selection dialog. 

MSG_TERM_ACTIVATE_NETWORK_SELECTION_CHANGE	calls
						ActivateNetworkSelection and
						sets up appropriate text
						selection.  Uses IAPL entry
						in record buffer.  
			
MSG_TERM_ACTIVATE_NETWORK_SELECTION_NEW	calls ActivateNetworkSelection and
					clears text entry.  Creates new
					record in record buffer 
					(discarding old if any).


MSG_TERM_INITIALIZE_NETWORK_ELEMENT	loads the proper set of access
					points for current record, and calls
					up network element dialog. 


MSG_TERM_ACTIVATE_SET_KEY_MACRO		calls update for 3.8, and brings up
					dialog 3.6

MSG_TERM_ACTIVATE_SET_TERMINAL		sets up fields of set terminal
					(dialog 3.7) and then activates the
					dialog.  

MSG_TERM_ACTIVATE_CONFIRM_SAVE		sets up cofirm save data details
					field and brings up dialog 3.8

; ----------------------------------------------------------------------
;			Dialog & UI update routines
; ----------------------------------------------------------------------
UpdateConnectionDialog			updates the fields in the connection
					confirm/setting dialog. 

UpdateSetTerminal			sets the fields in the set terminal
					dialog

ResetSetNumItems			resets and sets new numItems count
					for genDynamicList 

GetServiceAccessPointCount		returns the number of access points
					for this service 

UpdateNetworkElementFields		updates fields in network element
					box (3.5) to correspond to
					information from that access point 

UpdateNetworkIDPasswd			updates network ID and passwd fields

ClearNetworkElementFields		used to clear text objects in
					network element dialog 

UpdateConfirmSaveDataFields		update confirm save data dialog info
					fields from current info in global
					memory (not access point).

UpdateConfirmSaveDetails		updates the fields for Connection
					Save Data AP (details), dialog 3.9.  

; ----------------------------------------------------------------------
;			String processing routines
; ----------------------------------------------------------------------
ProcessBufferIntoPassword		given a string length (in terms of
					characters), places the equivalent
					string blatted out with '*' in
					StringBuffer. 

StringBufferCharCount			returns the # of characters up to
					and including NULL in StringBuffer.
					If max elements reached, returns max
					elements. 

ProcessNameMoniker			concatenates service name and access
					point into one name


; ----------------------------------------------------------------------
;			Set Terminal Routines
; ----------------------------------------------------------------------
MSG_TERM_SET_NETWORK_SELECTION		sets current network selection to
					selected value and updates text
					field to match selection of dynamic
					list in dialog 3.4 if blank 

MSG_TERM_SET_IAPL_SELECTION		calls SetCurrIAPLSelection

SetCurrIAPLSelection			Given selection #, loads that IAPL
					record into the buffer, closing old
					accpt datastore and opening new one
					corresonding to its service.  

MSG_TERM_SET_ACCESS_POINT		Given accpt record in buffer, sets
					CurrentAccessPoint and loads that
					accpt record into the buffer,
					discarding previous record if any.


MSG_TERM_SAVE_ACCESS_POINT		commits changes to access point
					datastore 

SetDataByteItem				sets the bits for a given selection
					in a given data byte


MSG_TERM_SET_KANJI_CODE			sets the Kanji code sleection in
					PFKbyte 

MSG_TERM_DOVE_SET_BAUD_RATE		sets data byte then calls main
					handler to set baud rate 

MSG_TERM_DOVE_SET_DATA_BIT		sets data byte then calls main
					handler to set data bit

; ----------------------------------------------------------------------
;			Variable Query Handler
; ----------------------------------------------------------------------

TermGetVariable				gets string corresponding to
					variable. 


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/ 6/96   	Initial revision


DESCRIPTION:
	Dove specific routines for managing the UI movement and access
points using datastore.
		

	$Id: dove.asm,v 1.1 97/04/04 16:55:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
ProtectedGenTextClass	; class declaration
idata	ends

udata	segment
	IAPLDsToken		word	; Inform of Access Points List data
					; store token.
	AccessPointDsToken	word	; access point data store token

	

	StringBuffer		byte	64 dup (0); buffer for strings

	; offset in access point list and existing # of access points
	AccessPointCount	word	; # of existing access points for 
					; the current network service

	; current selections
	CurrentIAPLSelection	byte	; index #
	CurrentAccessPoint	word	; index #

	; whether or not to write to history buffer (flag)
	LogHistoryFlag		byte	; used to internally determine
					; whether or not the history is
					; currently being written or not.

	WriteHistoryBufferFlag	byte	; Logging history, should write to
					; file or not? (based on user button
					; preference). 	

	KBDToggleFlag		byte
	

	; new creation flags
	NewIAPLRecordFlag	byte	; keeps track of whether or not
					; creating a new IAPL record.

	NewAccPtRecordFlag	byte	; keeps track of whether or not a
					; new access point has been created.
					; This needed since only one access
					; point can be created per UI sequence.
	; access point file valid flag
	AccPtValidFlag		byte	; keeps track of whether or not an
					; access point ds session is open or
					; not.


	; state information.  All changes are made here until commit is
	; sent, then these are saved to datastore.

	; why even use these if all these are kept in record buffer?
	; just call commit on record buffer on save, otherwise discarded as
	; usual. 
	; Should not since we can have several datastores open at once, with
	; the record buffer potentially overwritten several times.

	NetworkPassword		byte	30 dup (0)	
	NetworkPasswordLength	word	; length of network password

	BSDMbyte		byte
	PFKbyte			byte	
	CTbyte			byte

udata	ends


; strings used in this portion
IAPLString		wchar	"Information of Access Points",0




; Network services strings
PCVANString		wchar	"PC-VAN",0
NiftyServeString	wchar	"Nifty-Serve",0
ASCIINETString		wchar	"ASCII-NET",0
PeopleString		wchar	"People",0
OtherString		wchar	"Other",0


AccessPointString	wchar	"Access Point",0	;NOTE: localize this!
TelephoneNumberString	wchar	"Telephone Number",0	


;/* ****************************************
;	Settings strings
;**************************************** */
;/* stop bit monikers */
OneStopBitText		wchar	"1",0
OnePtFiveStopBitText	wchar	"1.5",0
TwoStopBitText		wchar	"2",0

;/* data bit Texts */
FiveDataBitText 	wchar	 "5",0
SixDataBitText		wchar	 "6",0
SevenDataBitText 	wchar	 "7",0
EightDataBitText 	wchar	 "8",0

;/* parity Texts */
NoParityText 	wchar	 "None",0
OddParityText 	wchar	 "Odd",0
EvenParityText 	wchar	 "Even",0
SpaceParityText	wchar	 "Space",0
MarkParityText 	wchar	 "Mark",0


;/* Flow control Texts */
FlowHardwareText 	wchar	 "Hardware",0
FlowSoftwareText  	wchar	 "Software",0
FlowNoneText		wchar	 "None",0

;/* Baud rate Texts */
Baud38400Text 	wchar	 "38400",0	
Baud19200Text 	wchar	 "19200",0
Baud9600Text 	wchar	 "9600",0
Baud4800Text 	wchar	 "4800",0
Baud2400Text 	wchar	 "2400",0
Baud1200Text 	wchar	 "1200",0
Baud300Text 	wchar	 "300",0

;/* Combo Box History Method Texts */
;AutomaticText	wchar	"Automatic",0
;ManualText	wchar	"Manual",0


;/* Kanji Font Text */
ShiftJISText 	wchar	 "Shift JIS",0
JISText 	wchar	 "JIS",0
OldJISText 	wchar	 "Old JIS",0
NECText 	wchar	 "NEC",0
EUCText		wchar	 "EUC",0

;Terminal StringTables
TTYText		wchar	"TTY",0
ANSIText	wchar	"ANSI",0
WYSE50Text	wchar	"WYSE50",0
VT52Text	wchar	"VT52",0
VT100Text	wchar	"VT100",0
IBM3101Text	wchar	"IBM3101",0
TVI950Text	wchar	"TVI950",0

; Tables used for grabbing identifiers and their order

baudIdentifierTable	word	SB_300, SB_1200, SB_2400, SB_4800, SB_9600, SB_19200, SB_38400

dataBitsIdentifierTable	word	(SL_5BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8),(SL_6BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8),(SL_7BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8),(SL_8BITS shl offset SF_LENGTH) or (mask SF_LENGTH shl 8)

stopBitsIdentifierTable	word	SBO_ONE, SBO_ONEANDHALF, SBO_TWO

parityBitsIdentifierTable	word	(SP_NONE shl offset SF_PARITY) or (mask SF_PARITY shl 8),(SP_ODD shl offset SF_PARITY) or (mask SF_PARITY shl 8),(SP_EVEN shl offset SF_PARITY) or (mask SF_PARITY shl 8),(SP_MARK shl offset SF_PARITY) or (mask SF_PARITY shl 8),(SP_SPACE shl offset SF_PARITY) or (mask SF_PARITY shl 8)

flowIdentifierTable	word	mask FFB_NONE, mask SFC_HARDWARE, mask SFC_SOFTWARE

terminalTypeIdentifierTable	word	TTY, ANSI, WYSE50,  VT52, VT100, IBM3101, TVI950  

kanjiFontIdentifierTable	word	 CODE_PAGE_SJIS, CODE_PAGE_JIS, CODE_PAGE_EUC


; Tables for grabbing offsets to strings used
stopBitStringTable	word	offset OneStopBitText, offset OnePtFiveStopBitText, offset TwoStopBitText

dataBitStringTable	word	offset FiveDataBitText, offset SixDataBitText, offset SevenDataBitText, offset EightDataBitText

parityStringTable	word	offset NoParityText, offset OddParityText, offset EvenParityText, offset MarkParityText, offset SpaceParityText

flowStringTable	word	offset FlowNoneText, offset FlowHardwareText, offset FlowSoftwareText 

baudStringTable	word	offset Baud300Text, offset Baud1200Text, offset Baud2400Text, offset Baud4800Text, offset Baud9600Text, offset Baud19200Text, offset Baud38400Text

;comboBoxStringTable	word	offset AutomaticText, ManualText

terminalStringTable	word TTYText, offset  ANSIText, offset WYSE50Text, offset VT52Text,  offset VT100Text, offset IBM3101Text, offset TVI950Text 

kanjiFontStringTable	word	offset ShiftJISText, offset JISText, offset OldJISText, offset NECText, offset EUCText

networkServiceNameTable	word	offset PCVANString, offset NiftyServeString,offset ASCIINETString, offset PeopleString, offset OtherString


; ----------------------------------------------------------------------
;
;			Utility Routines
;
; ----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearStringBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clears string buffer, filling it with ' ' char

CALLED BY:	various
PASS:		none
RETURN:		none
DESTROYED:	nothing
SIDE EFFECTS:	clears string buffer, filling it with ' ' char

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearStringBuffer	proc	near
	uses	ax,cx,di,ds,di,bp
	.enter
	mov	cx, segment dgroup
	mov	ds, cx				; set segment
	mov	di, offset StringBuffer		; get offset of buffer

if DBCS_PCGEOS
	clr	cx

string_buffer_erase_loop:
	mov {byte}	ds:[di], BLANK_CHAR	; blank character
	inc	di
	mov {byte} 	ds:[di], BLANK_CHAR_HIGH	;  zero
	inc	di
	add	cx, 2
	cmp	cx, STRING_BUFFER_SIZE
	jnz	string_buffer_erase_loop

else

	; clear string buffer first
	cld	; left to right
	mov	ax, BLANK_CHAR				; clear buffer
	mov	cx, STRING_BUFFER_SIZE
	rep	stosb
endif	; DBCS
	
	.leave
	ret
ClearStringBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOrdinalityFromTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: given an identifier and offset to table, returns the identifier's
ordinality.

CALLED BY:	thse suckers below
PASS:		di	= offset to table
		cx	= identifier to match
RETURN:		cx	= # in sequence (0 based)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:  given an offset to the table and an identifier, this
searches the table and returns the ordinality.  This is presuming that the
user is intelligent enough to present an identifier that is on the proper
table.  If cannot find, it exits with last item.
		
NOTE: the comparisons are word based.


*** also need to place in ability to detect no matches ***

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetOrdinalityFromTable	proc	near
	uses	ax,bx,di,bp
	.enter

	clr	ax	; counter

get_ordinality_loop:

	mov	bx, cs:[di]	; store word in table
	cmp	bx, cx		; compare to identifier
	je	exit_get_ordinality

	; item not found, increment and continue
	inc	ax
	add	di, 2	; increment by word size
	jmp	get_ordinality_loop

exit_get_ordinality:
	mov	cx, ax		; return # in cx

	.leave
	ret
GetOrdinalityFromTable	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermCloseNetworkDatastore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	closes datastores

CALLED BY:	MSG_TERM_CLOSE_NETWORK_DATASTORE
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermCloseNetworkDatastore	method dynamic TermClass, 
					MSG_TERM_CLOSE_NETWORK_DATASTORE
	uses	ax, cx, dx, bp
	.enter
	.leave
	ret
TTermCloseNetworkDatastore	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermConnectButtonHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_TERM_CONNECT_BUTTON_HIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ds	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	si, di	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
If an access point is currently selected, this calls the routine to bring
up and initialize the Connection Confirm (3.2 in spec) dialog.  
If an access point is not selected, this calls up the Network Selection
(3.4) dialog box initialization routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;TestString	wchar	"TestString",0

TermConnectButtonHit	method dynamic TermClass, 
					MSG_TERM_CONNECT_BUTTON_HIT
	uses	ax, cx, dx, bp
	.enter
	
	; open port if necessary
	mov	cx, DOVE_COM_PORT
	dec	cx
	call	TermSetPort
	jcxz	exit_term_connect_button_hit

	mov	es:[AccPtValidFlag],INVALID	; no access point
							; records open  	



	; discard old IAPL selection
	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord	

	; discard old AccessPoint selection
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreDiscardRecord

	call	OpenIAPLDataStore

	; check to see if any connection records- if not, create new one
	mov	ax, es:[IAPLDsToken]
	call	DataStoreGetRecordCount
	cmp	ax, 0
	jne	get_selection_term_connect_button_hit
	; create new IAPL record and bring up Network selection
	mov	bx, ds:[termProcHandle]
	mov	ax, MSG_TERM_ACTIVATE_NETWORK_SELECTION_NEW
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	exit_term_connect_button_hit

	; check to see which selection is selected by
	; ConnectionConfirmAccessPointName, load that record and its
	; service, along with its first access point.
get_selection_term_connect_button_hit:
	mov	bx, handle ConnectionConfirmAccessPointName
	mov	si, offset ConnectionConfirmAccessPointName
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL	; block until result is processed
	call	ObjMessage

if ERROR_CHECK
	cmp	ax, GIGS_NONE
	jnz	continue_term_connect_button_hit
	ERROR	ERROR_NO_SELECTIONS_TERM_CONNECT_BUTTON_HIT
continue_term_connect_button_hit:
endif	; ERROR_CHECK


	mov	cx, ax	; set up parameters for call to initialize record
			; buffers. 
			; NOTE: es = dgroup segment 

	call	SetCurrIAPLSelection
	
	; update the dialog fields
	call	UpdateConnectionDialog
	call	ActivateConnectionConfirm
	mov	ax, es:[IAPLDsToken]
;	call	DataStoreGetRecordCount
;	cmp	ax, 0
;	jz	exit_term_connect_button_hit	; if no records, then
						; nothing in buffer
	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord	; discard record
EC <	ERROR_C	ERROR_DS_DISCARD_RECORD_CONNECT_BUTTON_HIT	>	

	

exit_term_connect_button_hit:
	.leave
	ret
TermConnectButtonHit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSettingsButtonHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	same as connectbuttonhit, but brings up settings box.

CALLED BY:	MSG_TERM_SETTING_BUTTON_HIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	si, di	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
If an access point is currently selected, this calls the routine to bring
up and initialize the Connection Confirm (3.2 in spec) dialog.  
If an access point is not selected, this calls up the Network Selection
(3.4) dialog box initialization routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	10/1/96		initial

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


TermSettingsButtonHit	method dynamic TermClass, 
					MSG_TERM_SETTING_BUTTON_HIT
	uses	ax, cx, dx, bp
	.enter
	
	;call	InitializeNetworkDataStore	; for now
	mov	es:[AccPtValidFlag],INVALID	; no access point
							; records open  	


	; discard old IAPL selection
	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord	

	; discard old AccessPoint selection
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreDiscardRecord

	call	OpenIAPLDataStore

	; check to see if any connections exist.  If not, automatically
	; default to Select Network, create new record option.
	mov	ax, es:[IAPLDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_DS_GET_RECORD_COUNT_SETTINGS_BUTTON_HIT	>
	cmp	ax, 0	
	jne	get_selection_term_settings_button_hit
	; create new IAPL record and bring up Network selection
	mov	bx, ds:[termProcHandle]
	mov	ax, MSG_TERM_ACTIVATE_NETWORK_SELECTION_NEW
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	exit_term_settings_button_hit


	; check to see which selection is selected by
	; ConnectionConfirmAccessPointName, load that record and its
	; service, along with its first access point.
get_selection_term_settings_button_hit:
	mov	bx, handle ConnectionConfirmAccessPointName
	mov	si, offset ConnectionConfirmAccessPointName
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL	; block until result is processed
	call	ObjMessage

if ERROR_CHECK
	cmp	ax, GIGS_NONE
	jnz	continue_term_settings_button_hit
	ERROR	ERROR_NO_SELECTIONS_TERM_CONNECT_BUTTON_HIT
continue_term_settings_button_hit:
endif	; ERROR_CHECK

	mov	cx, ax	; set up parameters for call to initialize record
			; buffers. 
			; NOTE: es = dgroup segment 

	call	SetCurrIAPLSelection
	
	; update the dialog fields
	call	UpdateConnectionDialog
	call	ActivateConnectionSetting
;	mov	ax, es:[IAPLDsToken]
;	call	DataStoreGetRecordCount
;EC <	ERROR_C	ERROR_DS_GET_RECORD_COUNT_SETTINGS_BUTTON_HIT	>
;	cmp	ax, 0
;	jz	exit_term_settings_button_hit	; if no records, then
						; nothing in buffer
	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord	; discard record
EC <	ERROR_C	ERROR_DS_DISCARD_RECORD_CONNECT_BUTTON_HIT	>	

exit_term_settings_button_hit:
	.leave
	ret
TermSettingsButtonHit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermCancelButtonHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flushes current IAPL and Access Point data from record
buffer.  Then calls up connection setting dialog.

CALLED BY:	MSG_TERM_CANCEL_BUTTON_HIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: removes changes to records, and reloads the previous
information: IAPL record and AccessPoint record.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermCancelButtonHit	method dynamic TermClass, 
					MSG_TERM_CANCEL_BUTTON_HIT
	uses	ax, cx, dx, bp
	.enter

	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord
	jnc	check_access_point_cancel_button
	cmp	ax, DSDE_RECORD_BUFFER_EMPTY
	jz	check_access_point_cancel_button
EC <	ERROR	ERROR_DISCARD_RECORD_CANCEL_BUTTON_HIT >

check_access_point_cancel_button:
	; first check to see if access point buffer is valid, if not, skip
	; over discard
	cmp	es:[AccPtValidFlag], INVALID
	je	continue_cancel_button_hit 
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreDiscardRecord
	jnc	continue_cancel_button_hit
	cmp	ax, DSDE_RECORD_BUFFER_EMPTY
	jz	continue_cancel_button_hit
EC <	ERROR	ERROR_DISCARD_RECORD_CANCEL_BUTTON_HIT >

continue_cancel_button_hit:
	clr	ch
	mov {byte}	cl, es:[CurrentIAPLSelection]
	call	SetCurrIAPLSelection
	call	UpdateConnectionDialog
	call	ActivateConnectionSetting
	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord	; discard record
	jnc	cancel_button_hit
	cmp	ax, DSDE_RECORD_BUFFER_EMPTY	; if no record declared yet,
						; no problem with discarding
						; it here (since no changes
						; to speak of).
	je	cancel_button_hit
EC <	ERROR	ERROR_DISCARD_RECORD_CANCEL_BUTTON_HIT >

	; reset key macros here
cancel_button_hit:

	.leave
	ret

TTermCancelButtonHit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermNetworkSettingsCancelButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_TERM_NETWORK_SETTINGS_CANCEL_BUTTON
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	12/11/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermNetworkSettingsCancelButton	method dynamic TermClass, 
					MSG_TERM_NETWORK_SETTINGS_CANCEL_BUTTON
	.enter

	mov	bx, handle LoseChangesString
	mov	bp, offset LoseChangesString
	call	MemLock
	push	bx, es
	mov	di, ax
	mov	es, ax
	mov	bp, es:[bp]
	; bring up confirmation dialog
	mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE \
			or mask CDBF_SYSTEM_MODAL 	; to bring to top
	call	TermUserStandardDialog
	pop	bx,es
	call	MemUnlock

	cmp	ax, IC_YES
	je	continue_cancel_normally

	; don't cancel changes
	mov	bx, handle NetworkElementDialog
	mov	si, offset NetworkElementDialog
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage
	.leave
	ret

continue_cancel_normally:
	mov	bx, ds:[termProcHandle]
	mov	ax, MSG_TERM_CANCEL_BUTTON_HIT
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
TTermNetworkSettingsCancelButton	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermConfirmSaveCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_TERM_CONFIRM_SAVE_CANCEL
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	12/11/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermConfirmSaveCancel	method dynamic TermClass, 
					MSG_TERM_CONFIRM_SAVE_CANCEL
	.enter

	mov	bx, handle LoseChangesString
	mov	bp, offset LoseChangesString
	call	MemLock
	push	bx, es
	mov	di, ax
	mov	es, ax
	mov	bp, es:[bp]
	; bring up confirmation dialog
	mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE \
			or mask CDBF_SYSTEM_MODAL 	; to bring to top
	call	TermUserStandardDialog
	pop	bx,es
	call	MemUnlock

	cmp	ax, IC_YES
	je	continue_cancel_normally

	; don't cancel changes
	mov	bx, handle ConfirmSaveDataDialog
	mov	si, offset ConfirmSaveDataDialog
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage
	.leave
	ret

continue_cancel_normally:
	mov	bx, ds:[termProcHandle]
	mov	ax, MSG_TERM_CANCEL_BUTTON_HIT
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
TTermConfirmSaveCancel	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermDisconnectButtonHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	closes history file (if open), and then calls
MSG_TERM_HANG_UP. 

CALLED BY:	MSG_TERM_DISCONNECT_BUTTON_HIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermDisconnectButtonHit	method dynamic TermClass, 
					MSG_TERM_DISCONNECT_BUTTON_HIT
	uses	ax, cx, dx, bp
	.enter

	cmp	es:[LogHistoryFlag], LOG_HISTORY
	jne	continue_disconnect

	; kill history
	mov	ax, MSG_FILE_RECV_STOP
	mov	bx, ds:[termProcHandle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	; hang up
continue_disconnect:
	mov	bx, ds:[termProcHandle]
	mov	ax, MSG_HANG_UP
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	; force input back to main screen object
	mov	ax, MSG_GEN_MAKE_FOCUS
	mov	bx, handle TermView
	mov     si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
TTermDisconnectButtonHit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermConnectOkButtonHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	runs the script to connect

CALLED BY:	MSG_TERM_CONNECT_OK_BUTTON_HIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/27/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
testScriptFile	wchar	"MYSCRIPT.MAC",0

TTermConnectOkButtonHit	method dynamic TermClass, 
					MSG_TERM_CONNECT_OK_BUTTON_HIT
	uses	ax, cx, dx, bp
	.enter

; demo stuff

; Unlock, discard record buffer, and close datastore session.
	
	; close access point datastore
	clr	ah
	mov {byte}	al, es:[AccPtValidFlag]
	cmp	ax, INVALID	; if no session in memory, then skip
					; ahead and discard iapl datastore
					; session. 
	jz	close_iapl_session_finish_button_hit
	mov	ax, es:[AccessPointDsToken]
;	call	DataStoreUnlockRecord
	call	DataStoreClose
	mov	es:[AccPtValidFlag], INVALID	; set to invalid
close_iapl_session_finish_button_hit:


	; check to see if history should be logged
	; first query status of history checkbox
	mov	bx, handle LogHistoryGroup
	mov	si, offset LogHistoryGroup
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjMessage

	cmp	ax, LOG_HISTORY	; see if log history or not
	mov	es:[LogHistoryFlag], INVALID
	jne	continue_connect_ok_button_hit
	mov	es:[LogHistoryFlag], VALID

;	; begin log history
;	mov	es:[LogHistoryFlag], VALID
;	mov	ax, MSG_ASCII_RECV_START
;	mov	bx, ds:[termProcHandle]
;	mov	di, mask MF_FORCE_QUEUE
;	call	ObjMessage


; now bring up the macrofilebox
continue_connect_ok_button_hit:
;	mov	bx, handle MacroFileBox
;	mov	si, offset MacroFileBox
;	mov	di, mask MF_CALL
;	mov	ax, MSG_GEN_INTERACTION_INITIATE
;	call	ObjMessage

	call	NetworkRunScriptFile	; activate script

	; close IAPL Datastore session
	mov	ax, es:[IAPLDsToken]
	call	DataStoreClose

	.leave
	ret
TTermConnectOkButtonHit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermProtocolOkButtonHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Commits terminal settings to data bytes.

CALLED BY:	MSG_TERM_PROTOCOL_OK_BUTTON_HIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermProtocolOkButtonHit	method dynamic TermClass, 
					MSG_TERM_PROTOCOL_OK_BUTTON_HIT
	uses	ax, cx, dx, bp
	.enter
	
	call	GetTerminalSettings	; commit changes to databytes only
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle NetworkElementDialog
	mov	si, offset NetworkElementDialog
	mov	di, mask MF_CALL
	call	ObjMessage	; raise NetworkElement dialog

	.leave
	ret
TTermProtocolOkButtonHit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermProtocolCancelButtonHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns terminal settings to previous values or default
settings.  Then brings up Network Element dialog.

CALLED BY:	MSG_TERM_PROTOCOL_CANCEL_BUTTON_HIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermProtocolCancelButtonHit	method dynamic TermClass, 
					MSG_TERM_PROTOCOL_CANCEL_BUTTON_HIT
	uses	ax, cx, dx, bp
	.enter

;	call	GetTerminalInfoAccPt	; restore previous settings
	call	UpdateSetTerminal	; restore previous UI settings

	; now bring up the dialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle NetworkElementDialog
	mov	si, offset NetworkElementDialog
	clr	di		; no flags
	call	ObjMessage
	

	.leave
	ret
TTermProtocolCancelButtonHit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermKeyMacroCancelButtonHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	discards all changes to key macro dialog and reloads info.
Returns to main screen.

CALLED BY:	MSG_TERM_KEY_MACRO_CANCEL_BUTTON_HIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermKeyMacroCancelButtonHit	method dynamic TermClass, 
					MSG_TERM_KEY_MACRO_CANCEL_BUTTON_HIT
	uses	ax, cx, dx, bp
	.enter

	clc	; no point in updating menu moniekrs (not set).
	call	UpdateKeyMacroDialog	; restore all settings

	.leave
	ret
TTermKeyMacroCancelButtonHit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermKeyMacroOkButtonHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Commits changes to key macro datastore (if any) and
reupdates menus and dialogs.  Returns to main screen.

CALLED BY:	MSG_TERM_KEY_MACRO_OK_BUTTON_HIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermKeyMacroOkButtonHit	method dynamic TermClass, 
					MSG_TERM_KEY_MACRO_OK_BUTTON_HIT
	uses	ax, cx, dx, bp
	.enter

	call	UpdateKeyMacros		; update datastores
	stc				; update all
	call	UpdateKeyMacroDialog	; update dialog & menus

	.leave
	ret
TTermKeyMacroOkButtonHit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermFinishButtonHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes both datastore sessions

CALLED BY:	MSG_TERM_FINISH_BUTTON_HIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/ 4/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermFinishButtonHit	method dynamic TermClass, 
					MSG_TERM_FINISH_BUTTON_HIT
	uses	ax, cx, dx, bp
	.enter

	; Unlock, discard record buffer, and close datastore session.
	
	; close access point datastore
	clr	ah
	mov {byte}	al, es:[AccPtValidFlag]
	cmp	ax, INVALID	; if no session in memory, then skip
					; ahead and discard iapl datastore
					; session. 
	jz	close_iapl_session_finish_button_hit
	mov	ax, es:[AccessPointDsToken]
;	call	DataStoreUnlockRecord
	call	DataStoreClose
	mov	es:[AccPtValidFlag], INVALID	; set to invalid
close_iapl_session_finish_button_hit:
	; close IAPL Datastore session
	mov	ax, es:[IAPLDsToken]
	call	DataStoreClose

	.leave
	ret
TTermFinishButtonHit	endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermToggleSettingChanges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enables/disables terminal settings

CALLED BY:	MSG_TERM_TOGGLE_SETTING_CHANGES
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: queries status of ChangeSettingsCheckBox via querying
ChangeSettingsGroup and enables/disables terminal settings
(ProtocolSettingsContent). 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermToggleSettingChanges	method dynamic TermClass, 
					MSG_TERM_TOGGLE_SETTING_CHANGES
	uses	ax, cx, dx, bp
	.enter

	; query for status (checked or not checked)
	mov	bx, handle ChangeSettingsGroup
	mov	si, offset ChangeSettingsGroup
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjMessage

	jc	change_toggle_not_selected

	; since there is only one item in this group, if anything is
	; selected, it must be the check box.  So enable.
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	change_toggle_update

change_toggle_not_selected:
	; not selected, disable 
	mov	ax, MSG_GEN_SET_NOT_ENABLED

change_toggle_update:
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	bx, handle ProtocolSettingsContent
	mov	si, offset ProtocolSettingsContent
	mov	di, mask MF_CALL
	call	ObjMessage	; update

	.leave
	ret
TTermToggleSettingChanges	endm


; ----------------------------------------------------------------------
;
;		History Routines
; 
; ----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermHistoryToggle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggles flag to write history buffer to log.

CALLED BY:	MSG_TERM_HISTORY_TOGGLE
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	Note: history genBoolean and flag must be set to
write to buffer.  This also updates moniker.

Right now, temporarily use strings as visMoniker for button.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
bookOpenString	 wchar "Open" ,0
bookClosedString wchar "Closed",0

TTermHistoryToggle	method dynamic TermClass, 
					MSG_TERM_HISTORY_TOGGLE
	.enter

	cmp	es:[WriteHistoryBufferFlag], INVALID
	je	history_toggle_set_valid
	
history_toggle_set_invalid:
	mov	es:[WriteHistoryBufferFlag], INVALID
	mov	dx, offset bookClosedString
	jmp	exit_history_toggle

history_toggle_set_valid:
	mov	es:[WriteHistoryBufferFlag], VALID
	mov	dx, offset bookOpenString

exit_history_toggle:
if	0
	mov	cx, cs	
	mov	bx, handle HistoryToggle
	mov	si, offset HistoryToggle
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	clr	di
	call	ObjMessage
endif
	.leave
	ret
TTermHistoryToggle	endm




; ----------------------------------------------------------------------
;
;		Dynamic List routines for lists of network services
;	
; ----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermUpdateIAPLNameList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	updates the gendynamic list that calls it by grabbing the
network name from the IAPL record.

CALLED BY:	MSG_TERM_UPDATE_IAPL_NAME_LIST
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #

		cx:dx	= optr of the dynamic list
		bp	= item # requested
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Given the dynamic list of network services and the item # requested,
MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_TEXT is used to send the text
field of the appropriate message.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TTermUpdateIAPLNameList	method dynamic TermClass, 
					MSG_TERM_UPDATE_IAPL_NAME_LIST

	; set optr target to dynamic list
	mov	bx, cx				; store handle to list
	mov	si, dx				; store offset to list
	
	mov	cx, segment dgroup
	mov	es, cx

	call	ClearStringBuffer

	mov	cx, bp
	mov	dl, IAPL_NAME_FIELD_ID
	mov	di, offset StringBuffer
	call	GetIAPLFieldAndCheckLengthList


	; now point cx:dx to string entry
	mov	cx, es
	mov	dx, di

	mov	di, mask MF_CALL  
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	call	ObjMessage

exit_term_update_network_name_list:
	ret
TTermUpdateIAPLNameList	endm










; ----------------------------------------------------------------------
;
;		routines for updating and displaying dynamic
;		lists of access points
;
; ----------------------------------------------------------------------





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermUpdateAccessPointList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	updates gendynamic list calls for an access point.  Note
that this operates relative to the offset of the record number in
AccessPointOffset.  If NO_ACCESS_POINT, then no access points are available.

CALLED BY:	MSG_TERM_UPDATE_ACCESS_POINT_LIST
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermUpdateAccessPointList	method dynamic TermClass, 
					MSG_TERM_UPDATE_ACCESS_POINT_LIST
	

	; entries exist so find in relative to offset
		; set optr target to dynamic list
	mov	bx, cx				; store handle to list
	mov	si, dx				; store offset to list
	
	mov	cx, segment dgroup
	mov	es, cx

	call	ClearStringBuffer

	mov	cx, bp

	mov	dx, ACCESS_POINT_LIST_ACCESS_POINT_FIELD_ID	
	mov	di, offset StringBuffer
	call	GetAccessFieldAndCheckLengthList

	; now point cx:dx to string entry
	mov	cx, es
	mov	dx, di

	mov	di, mask MF_CALL  
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	call	ObjMessage

exit_term_update_access_point_list:
	ret
TTermUpdateAccessPointList	endm







;---------------------------------------------------------------------------
;
;		Activation routines for dialogs
;
; SYPNOSIS: Many of the dialogs require special information to be displayed
; depending on the state, so routines for activating these dialogs and
; initializing their ui's to fit the state information are placed here.
;
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ActivateConnectionConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: sets up appropriate children triggers and brings up connection  
confirm dialog.  

CALLED BY:	TTermActivateConnectionConfirm
PASS:		none
RETURN:		none
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	checks to see if proper children are attached.  If not, then detaches
the other set of children and reattaches proper set.  Note that this is
working off the assumption that a set of children is always attached.  This
also sets the message text on the bottom of the dialog to be active.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ActivateConnectionConfirm	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter	

; First check to see if the right set of triggers are on the tree.
	mov	bx, handle ConnectionConfirmDialog
	mov	si, offset ConnectionConfirmDialog
	mov	cx, handle ConnectionConfirmTriggers
	mov	dx, offset ConnectionConfirmTriggers
	mov	ax, MSG_GEN_FIND_CHILD
	
	mov	di, mask MF_CALL	; block so events occur sequentially
	call	ObjMessage

	jnc	connection_confirm_call_dialog	; proper children already
						; attached, so just jump
						; ahead and instantiate
						; dialog

	; remove previous children
	; First set them unusable
	mov	bx, handle ConnectionSettingTriggers
	mov	si, offset ConnectionSettingTriggers
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE

	mov	di, mask MF_CALL	; block so events occur sequentially
	call	ObjMessage

	; now decapi-err detach them

	mov	bx, handle ConnectionConfirmDialog
	mov	si, offset ConnectionConfirmDialog
	mov	cx, handle ConnectionSettingTriggers
	mov	dx, offset ConnectionSettingTriggers
	mov	bp, mask CCF_MARK_DIRTY			; must save to state
	mov	ax, MSG_GEN_REMOVE_CHILD

	mov	di, mask MF_CALL	; block so events occur sequentially
	call	ObjMessage

connection_confirm_attach_triggers:
	; set up the children
	mov	bx, handle ConnectionConfirmDialog
	mov	si, offset ConnectionConfirmDialog
	mov	cx, handle ConnectionConfirmTriggers
	mov	dx, offset ConnectionConfirmTriggers
	clr	bp			; no frills
	mov	ax, MSG_GEN_ADD_CHILD

	mov	di, mask MF_CALL	; block so events occur sequentially
	call	ObjMessage


	; now set these suckers usable
	mov	bx, handle ConnectionConfirmTriggers
	mov	si, offset ConnectionConfirmTriggers
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessage

connection_confirm_call_dialog:

	; NOTE: not sure if this will move just yet, but placing here for
	; future adaptability

;	mov	ax, es:[IAPLDsToken]
;	call	DataStoreGetRecordCount

	; put some ec code here to check against a carry set

	; presuming that we will have a reasonable # of
	; services... i.e. limited to 20...

;	mov	cx, ax	; set # of items

;	mov	bx, handle ConnectionConfirmAccessPointName
;	mov	si, offset ConnectionConfirmAccessPointName
;	call	ResetSetNumItems
	; set text message usable
;	mov	bx, handle ConnectionConfirmTextField
;	mov	si, offset ConnectionConfirmTextField
;	mov	ax, MSG_GEN_SET_USABLE
;	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
;	call	ObjMessage

	; set network selection to point to current selection
	mov	bx, handle ConnectionConfirmAccessPointName
	mov	si, offset ConnectionConfirmAccessPointName
	mov	cx, segment dgroup
	mov	es, cx
	clr	ch
	mov	cl, es:[CurrentIAPLSelection]
	clr	dx	; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessage

	
	; bring up the dialog 
	mov	bx, handle ConnectionConfirmDialog
	mov	si, offset ConnectionConfirmDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE


	call	ObjMessage

	; make sure network service is loaded up

	; if state of network service selection is indeterminate, then don't
	; set the data fields.
	
	; now set the fields of the dialog box to show the current selection



	.leave
	ret
ActivateConnectionConfirm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermActivateConnectionConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initializes ui fields of dialog to fit state information

CALLED BY:	MSG_TERM_ACTIVATE_CONNECTION_CONFIRM
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: calls ActivateConnectionConfirm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermActivateConnectionConfirm	method dynamic TermClass, 
					MSG_TERM_ACTIVATE_CONNECTION_CONFIRM
	uses	ax, cx, dx, bp
	.enter

	call	ActivateConnectionConfirm

	.leave
	ret
TTermActivateConnectionConfirm	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ActivateConnectionSetting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: sets up appropriate children triggers and brings up connection  
confirm dialog.  

CALLED BY:	TTermActivateConnectionConfirm
PASS:		none
RETURN:		none
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	checks to see if proper children are attached.  If not, then detaches
the other set of children and reattaches proper set.  Note that this is
working off the assumption that a set of children is always attached.  This
also sets the message text on the bottom of the dialog to be in-active.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ActivateConnectionSetting	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter	

	; First check to see if the wrong set of triggers are on the tree.
	; If so, set them unusable and detach them.
	mov	bx, handle ConnectionConfirmDialog
	mov	si, offset ConnectionConfirmDialog
	mov	cx, handle ConnectionSettingTriggers
	mov	dx, offset ConnectionSettingTriggers
	mov	ax, MSG_GEN_FIND_CHILD

	mov	di, mask MF_CALL	; block so events occur sequentially
	call	ObjMessage

	jnc	connection_setting_call_dialog		; proper children in
							; place, so just
							; skip ahead and put
							; dialog on.

	; remove previous children
	; First set them unusable
	mov	bx, handle ConnectionConfirmTriggers
	mov	si, offset ConnectionConfirmTriggers
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE

	mov	di, mask MF_CALL	; block so events occur sequentially
	call	ObjMessage

	; now decapi-err detach them
	mov	bx, handle ConnectionConfirmDialog
	mov	si, offset ConnectionConfirmDialog
	mov	cx, handle ConnectionConfirmTriggers
	mov	dx, offset ConnectionConfirmTriggers
	mov	bp, mask CCF_MARK_DIRTY			; must save to state
	mov	ax, MSG_GEN_REMOVE_CHILD

	mov	di, mask MF_CALL	; block so events occur sequentially
	call	ObjMessage


	; set up the children
	mov	bx, handle ConnectionConfirmDialog
	mov	si, offset ConnectionConfirmDialog
	mov	cx, handle ConnectionSettingTriggers
	mov	dx, offset ConnectionSettingTriggers
	clr	bp			; no frills
	mov	ax, MSG_GEN_ADD_CHILD

	mov	di, mask MF_CALL	; block so events occur sequentially
	call	ObjMessage

	; now set these suckers usable
	mov	bx, handle ConnectionSettingTriggers
	mov	si, offset ConnectionSettingTriggers
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE

	mov	di, mask MF_CALL	; block so events occur sequentially
	call	ObjMessage
	
connection_setting_call_dialog:

	; NOTE: not sure if this will move just yet, but placing here for
	; future adaptability

	mov	bx, segment dgroup
	mov	es, bx


	mov	ax, es:[IAPLDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_GET_RECORD_COUNT_ACTIVATE_CONNECTION_SETTING	>

	; affect change trigger
	mov	bx, handle ConnectionSettingChangeButton
	mov	si, offset ConnectionSettingChangeButton
	mov	di, mask MF_CALL

	tst	ax
	jnz	usable_change_trigger
	; no iapl, do not use change trigger
	mov	ax, MSG_GEN_SET_NOT_ENABLED	
	jmp	continue_connection_set
usable_change_trigger:
	mov	ax, MSG_GEN_SET_ENABLED	; else can use
continue_connection_set:
	push	ax	; store message
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessage

	; now using same message, set delete trigger
	pop	ax	; restore message
	mov	bx, handle DeleteButton
	mov	si, offset DeleteButton
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage
	

	; presuming that we will have a reasonable # of
	; services... i.e. limited to 20...

;	mov	cx, ax	; set # of items

;	mov	bx, handle ConnectionConfirmAccessPointName
;	mov	si, offset ConnectionConfirmAccessPointName
;	call	ResetSetNumItems

	; if no selections set, then disable change button
	;mov	bx, handle ConnectionSettingChangeButton
	;mov	si, handle ConnectionSettingChangeButton
	;mov	di, mask MF_CALL
	;mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	;jcxz	set_not_enable_activate_connection_setting

	;mov	ax, MSG_GEN_SET_ENABLED	; no items, so gray it out.
	;jmp	continue_activate_connection_setting

;set_not_enable_activate_connection_setting:
;	mov	ax, MSG_GEN_SET_NOT_ENABLED		; set button enabled

;continue_activate_connection_setting:
	;call	ObjMessage	

	; set text message un-usable
;	mov	bx, handle ConnectionConfirmTextField
;	mov	si, offset ConnectionConfirmTextField
;	mov	ax, MSG_GEN_SET_NOT_USABLE
;	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
;	call	ObjMessage

	; set network selection to point to current selection
	mov	bx, handle ConnectionConfirmAccessPointName
	mov	si, offset ConnectionConfirmAccessPointName
	mov	cx, segment dgroup
	mov	es, cx
	clr	ch
	mov	cl, es:[CurrentIAPLSelection]	
	clr	dx	; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessage

	; bring up the dialog 
	mov	bx, handle ConnectionConfirmDialog
	mov	si, offset ConnectionConfirmDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	; make sure network service is loaded up

	; if state of network service selection is indeterminate, then don't
	; set the data fields.
	
	; now set the fields of the dialog box to show the current selection

	.leave
	ret
ActivateConnectionSetting	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermActivateConnectionSetting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the ConnectionConfirm dialog to make it look like the
connection setting dialog by removing the old children, hiding the text
field, and attaching the new children.  It also initializes ui fields of
dialog to fit state information.

CALLED BY:	MSG_TERM_ACTIVATE_CONNECTION_SETTING
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermActivateConnectionSetting	method dynamic TermClass, 
					MSG_TERM_ACTIVATE_CONNECTION_SETTING
	uses	ax, cx, dx, bp
	.enter

	call	ActivateConnectionSetting

	.leave
	ret
TTermActivateConnectionSetting	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ActivateNetworkSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets selection to current network service	

CALLED BY:	TTermActivateConnectionConfirm
PASS:		none
RETURN:		none
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	checks current network service, and then sets it to be the current
selection in the dynamic list of dialog 3.4

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ActivateNetworkSelection	proc	near
	
	mov	cx, segment dgroup
	mov	es, cx

	; NOTE: not sure if this will move just yet, but placing here for
	; future adaptability

;	mov	ax, es:[IAPLDsToken]
;	call	DataStoreGetRecordCount
;	mov	cx, ax	; set # of items

;	mov	bx, handle NetworkSelectionServicesList
;	mov	si, offset NetworkSelectionServicesList
;	call	ResetSetNumItems

	; bring up the dialog
	mov	bx, handle NetworkSelectionDialog
	mov	si, offset NetworkSelectionDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage

	ret
ActivateNetworkSelection endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermActivateNetworkSelectionChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calls ActivateNetworkSelection without creating new record.

CALLED BY:	MSG_TERM_ACTIVATE_NETWORK_SELECTION_CHANGE
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: calls ActivateNetworkSelection, and also sets the
current text item.  Uses currently selected record entry, so selects that
entry and places it into the record buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermActivateNetworkSelectionChange	method dynamic TermClass, 
					MSG_TERM_ACTIVATE_NETWORK_SELECTION_CHANGE
	uses	ax, cx, dx, bp
	.enter

	; Not a new record, so set flag appropriately
	mov	es:[NewIAPLRecordFlag], INVALID

	; mirroring the set network routines of above, will also reset the
	; currently selected access point to the first one.

;	mov	es:[CurrentAccessPoint],0

	; Change mode, so grab name of current selection
	; set the current text, if a selection exists
	; grab the text
	
	mov	ax, es:[IAPLDsToken]	; set datastore token
	mov	cl, es:[CurrentIAPLSelection]
	clr	ch
	clr	dx
	; load the IAPL record (choke point for loading IAPL record into
	; record buffer)
	call	DataStoreLoadRecordNum	; Load the record in. From now on,
					; do not clear the IAPL buffer until
					; entry back into the Connection
					; dialogs via a cancel!
EC <	ERROR_C	ERROR_LOAD_RECORD_ACTIVATE_NETWORK_SELECTION_CHANGE	>


	; set the current selection to selected service (from buffer)

	sub	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1		; allocate
	mov	di, sp						; space on
								; stack to
								; save data 
	
					; +1 is to keep swat happy (even sp)
	mov	ax, es:[IAPLDsToken]
	segmov	es, ss, bx
	clr	bx
	mov	dl, IAPL_NETWORK_SERVICE_FIELD_ID
	mov	cx, IAPL_NETWORK_SERVICE_FIELD_SIZE
	call	DataStoreGetField
EC <	ERROR_C	ERROR_GET_FIELD_ACTIVATE_NETWORK_SELECTION_CHANGE	>
	mov {byte} cx, ss:[di]
	clr	ch
	add	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1	; restore stack

	; now call genItemgroup to set selection
	mov	bx, handle NetworkSelectionServicesList
	mov	si, offset NetworkSelectionServicesList
	clr	di	; no message flags
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION	
	call	ObjMessage	

	; new spec requires that network ID and password fields be updated
	; here
	clc	; clear NetworkID and Password fields only
	call	ClearNetworkElementFields
	call	UpdateNetworkIDPasswd

	call	ActivateNetworkSelection



	.leave
	ret
TTermActivateNetworkSelectionChange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermActivateNetworkSelectionNew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calls ActivateNetworkSelection and sets text item.

CALLED BY:	MSG_TERM_ACTIVATE_NETWORK_SELECTION_NEW
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: calls ActivateNetworkSelection, clears the
current text item, and creates new IAPL entry in record buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermActivateNetworkSelectionNew	method dynamic TermClass, 
					MSG_TERM_ACTIVATE_NETWORK_SELECTION_NEW
	uses	ax, cx, dx, bp
	.enter

	; New record, so set flag appropriately
	mov	es:[NewIAPLRecordFlag], VALID

	; mirroring the set network routines of above, will also reset the
	; currently selected access point to the first one.

	mov	es:[CurrentAccessPoint],0

	call	NewIAPLEntry		; check to see if 20 records, if not
					; create & instantiate IAPL record.
	jc	error_activate_network_selection_new

	; new spec requires that network ID and password fields be updated
	; here
	clc	; clear NetworkID and Password fields only
	call	ClearNetworkElementFields
	call	UpdateNetworkIDPasswd

	call	ActivateNetworkSelection

exit_activate_network_selection_new:
	.leave
	ret

error_activate_network_selection_new:
	; error occurred in NewIAPLEntry, so now just bring back old dialog
	mov	bx, handle ConnectionConfirmDialog
	mov	si, offset ConnectionConfirmDialog
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage
	jmp	exit_activate_network_selection_new

TTermActivateNetworkSelectionNew	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeNetworkElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	loads the proper set of access points for current record,
and calls up network element dialog.  Also sets networkID and network
password fields.

CALLED BY:	TTermInitializeNetworkElement
PASS:		none
RETURN:		none
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeNetworkElement	proc	near


; discard old access point if any
	; But first check to see if access pt datastore is valid
	cmp	es:[AccPtValidFlag], INVALID
	je	continue_update_network_element	; if no access point
						; datastore open, just
						; continue. 
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreDiscardRecord		; the only permissible error
						; here is to try to discard
						; an empty buffer (ignored).
	jnc	continue_update_network_element
	cmp	ax, DSDE_RECORD_BUFFER_EMPTY
	je	continue_update_network_element
	ERROR	ERROR_DS_DISCARD_RECORD_INIT_NETWORK_ELT; error	

continue_update_network_element:

	; get selection and load in the appropriate datastore
	mov	bx, handle NetworkSelectionServicesList
	mov	si, offset NetworkSelectionServicesList
	mov	di, mask MF_CALL	
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage

	; set up argment to DataStoreSetField on stack
	push	es, ax	; store dgroup and selection
	sub	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1 ; + 1 since original
							; field is odd sized.
	mov	di, sp
	mov	ss:[di], ax	; store selection

	; set network selection
	mov	ax, es:[IAPLDsToken]
	mov	dl, IAPL_NETWORK_SERVICE_FIELD_ID
	mov	cx, IAPL_NETWORK_SERVICE_FIELD_SIZE	
	segmov	es, ss, bx
	clr	bx	 ; use field ID only
	call	DataStoreSetField	; set the selection
EC <	ERROR_C ERROR_SET_FIELD_INIT_NETWORK_ELT >

	add	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1	; restore stack
	pop	es, ax	; restore dgroup and selection

	mov	bx, ax	; call openservice to open the access point
			; datastore for that service
	call	OpenService



	; Need to put # of access points in cx here
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C ERROR_GET_RECORD_COUNT_NETWORK_ELT >
	mov	cx, ax

resize_list_network_element:

	; resize the list
	mov	bx, handle NetworkElementAccessPointList
	mov	si, offset NetworkElementAccessPointList
	call	ResetSetNumItems


	; set current selection to CurrentAccessPoint
	mov	cx, es:[CurrentAccessPoint]
	clr	dx	; determinate
	mov	bx, handle NetworkElementAccessPointList
	mov	si, offset NetworkElementAccessPointList
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessage

	stc	; clear only the access point fields
	call	ClearNetworkElementFields	


update_network_element_dialog:
	
	; if no access points, don't load
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C ERROR_GET_RECORD_COUNT_NETWORK_ELT >
	tst	ax	
	jz	no_access_points
	mov	cx, es:[CurrentAccessPoint]
	clr	dx
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreLoadRecordNum
EC <	ERROR_C	ERROR_DS_LOAD_RECORD_NUM_ACTIVATE_SET_KEY_MACRO	>

	call	UpdateNetworkElementFields

	call	GetTerminalInfoAccPt	; get access point infomration
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreDiscardRecord	
EC <	ERROR_C	ERROR_DS_DISCARD_RECORD_INIT_NETWORK_ELT	>	

	; access points available, enable delete
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	raise_network_element_dialog

no_access_points:

	; no access points, so fill in with default information
	mov	es:[BSDMbyte], BSDM_DEFAULT
	mov	es:[PFKbyte], PFK_DEFAULT
	mov	es:[CTbyte], CT_DEFAULT


	; no access points, so set delete unusable
	mov	ax, MSG_GEN_SET_NOT_ENABLED


raise_network_element_dialog:
	; set usability of delete button
	mov	bx, handle NetworkElementDeleteButton
	mov	si, offset NetworkElementDeleteButton
	mov	di, mask MF_CALL
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessage

	; now bring up the network element dialog
	mov	bx, handle NetworkElementDialog
	mov	si, offset NetworkElementDialog
	clr	di	; no flags
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	mov	es:[NewAccPtRecordFlag], INVALID

exit_intialize_network_element:

	ret
InitializeNetworkElement	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermInitializeNetworkElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	loads the proper set of access points for current record,
and calls up network element dialog.  Also sets networkID and network
password fields.

CALLED BY:	MSG_TERM_INITIALIZE_NETWORK_ELEMENT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #

RETURN:		
DESTROYED:	di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:  calls InitializeNetworkElement

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermInitializeNetworkElement	method dynamic TermClass, 
					MSG_TERM_INITIALIZE_NETWORK_ELEMENT

	uses	ax, cx, dx, bp
	.enter

	call	InitializeNetworkElement

	.leave
	ret

TTermInitializeNetworkElement	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermActivateSetKeyMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calls update for 3.8, and brings up dialog 3.6

CALLED BY:	MSG_TERM_ACTIVATE_SET_KEY_MACRO
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: used to cause update to 3.8

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	8/30/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermActivateSetKeyMacro	method dynamic TermClass, 
					MSG_TERM_ACTIVATE_SET_KEY_MACRO
	uses	ax, cx, dx, bp
	.enter
	

if ERROR_CHECK
	call	IntegrityCheck
endif ; ERROR_CHECK

	mov	bx, handle SetKeyMacroDialog
	mov	si, offset SetKeyMacroDialog
	clr	di
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	.leave
	ret
TTermActivateSetKeyMacro	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermActivateSetTerminal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets up fields of set terminal (dialog 3.7) and then
activates the dialog.

CALLED BY:	MSG_TERM_ACTIVATE_SET_TERMINAL
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	bx, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: calls UpdateSetTerminal then
MSG_GEN_INTERACTION_INITIATES the set terminal dialog.
Also calls update for dialog 3.9 (see termlogbook for rationale)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	8/28/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermActivateSetTerminal	method dynamic TermClass, 
					MSG_TERM_ACTIVATE_SET_TERMINAL
	uses	ax, cx, dx, bp
	.enter

	call	UpdateSetTerminal	; update it to current info in
					; datastore. 

	; by default gray out change settings (for user's safety)
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	bx, handle ProtocolSettingsContent
	mov	si, offset ProtocolSettingsContent
	mov	di, mask MF_CALL
	call	ObjMessage	; update

	; now remove check from change settings check box
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	cx, dx	; set off, and no booleans indeterminate
	mov	bx, handle ChangeSettingsGroup
	mov	si, offset ChangeSettingsGroup
	mov	di, mask MF_CALL
	call	ObjMessage	; update
	

	; now bring up the dialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle ProtocolBox
	mov	si, offset ProtocolBox
	clr	di		; no flags
	call	ObjMessage
	
	.leave
	ret
TTermActivateSetTerminal	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermActivateConfirmSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calls update for confirm save data details, then brings up
dialog 3.8 ( confirm save dialog ).

CALLED BY:	MSG_TERM_ACTIVATE_CONFIRM_SAVE
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/ 8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermActivateConfirmSave	method dynamic TermClass, 
					MSG_TERM_ACTIVATE_CONFIRM_SAVE
	uses	ax, cx, dx, bp
	.enter

	; first check all fields to see if valid
	call	CheckNetworkEltFields
	jnc	check_field_mod_activate_confirm_save

	; error has occured, restart Network Element box and exit.
;	call	InitializeNetworkElement

	mov	bx, handle NetworkElementDialog
	mov	si, offset NetworkElementDialog
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	jmp	exit_activate_confirm_save

	; This is the new choke point for loading the access point into
	; memory. 
	; check to see if either the access point field or telephone field
	; is modified.  If so, then create a new buffer and save records in
	; there, else load in appropriate access point

	; First check to see if one has already been loaded.  If so, just
	; continue on.
check_field_mod_activate_confirm_save:

	cmp	es:[NewAccPtRecordFlag], VALID
	je	continue_activate_confirm_save

	mov	bx, handle NetworkElementAccessPoint
	mov	si, offset NetworkElementAccessPoint
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_TEXT_IS_MODIFIED
	call	ObjMessage
	jc	create_new_acc_pt

	mov	bx, handle NetworkElementTelephoneNumber
	mov	si, offset NetworkElementTelephoneNumber
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_TEXT_IS_MODIFIED
	call	ObjMessage
	jc	create_new_acc_pt


	; load current existing access point
	mov	ax, es:[AccessPointDsToken]
	clr	dx	; not that many records
	mov	cx, es:[CurrentAccessPoint]
	call	DataStoreLoadRecordNum
EC <	ERROR_C	ERROR_DS_LOAD_RECORD_NUM_CONFIRM_SAVE_DATA_FIELDS	>
	jmp	continue_activate_confirm_save

create_new_acc_pt:
	; discard old record, if any
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreDiscardRecord

	; create new access point record	
	call	CreateNewAccPtRecord
	; set flag
	mov	es:[NewAccPtRecordFlag], VALID

continue_activate_confirm_save:
	call	SetNetworkRecords	; set record info to match network
					; element dialog text.

	; now call to update state information
	call	UpdateConfirmSaveDataFields

	call	UpdateConfirmSaveDetails

	mov	bx, handle ConfirmSaveDataDialog
	mov	si, offset ConfirmSaveDataDialog
	clr	di
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

exit_activate_confirm_save:
	.leave
	ret
TTermActivateConfirmSave	endm




; ----------------------------------------------------------------------
;
;			dialog update routines
;
; ----------------------------------------------------------------------




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			UpdateConnectionDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	updates the fields in the connection confirm/setting dialog.


CALLED BY:	
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:  Updates fields of connection dialog with information
currently in the IAPL and AccessPoint records.  Presumes that a record
is loaded from IAPL datastore.  Also loads the network password and length
into their respective vars (to be used in connecting).
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/ 9/96    	Initial version
	eyeh	9/27/96		Removed calls to StringBuffer.  Gets field 
				ptrs instead.  Updates with buffer info 
				instead of loading it up.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateConnectionDialog	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	mov	bx, segment dgroup
	mov	es, bx

	mov	es:[CurrentAccessPoint], 0	; default focus for access
						; point list.

	mov	ax, es:[IAPLDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_COUNT_RECORD_UPDATE_CONNECTION_DIALOG	>
	; set the # of items in the dynamic list
	mov	cx, ax	; set # of items
	mov	bx, handle ConnectionConfirmAccessPointName
	mov	si, offset ConnectionConfirmAccessPointName
	call	ResetSetNumItems

	tst	cx
	jnz	update_connection_dialog
	call	ClearConnectionDialogFields	; clear fields and exit
	jmp	exit_update_connection_dialog

update_connection_dialog:
	; get current network service
	; allocate space on stack first
	sub	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE +1	; +1 = keep swat
							; happy 
	mov	ax, es:[IAPLDsToken]
	mov	dl, IAPL_NETWORK_SERVICE_FIELD_ID
	mov	cx, IAPL_NETWORK_SERVICE_FIELD_SIZE	
	segmov	es, ss, bx
	clr	bx
	mov	di, sp	; set string offset
	call	DataStoreGetField
EC <	ERROR_C	ERROR_DS_GET_FIELD_UPDATE_CONNECTION_DIALOG	>

	mov {byte} bl, ss:[di]
	add	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1	;restore stack
							; +1 = keep swat
							; happy 


	; update the text fields	

	; network service
	shl	bx
	mov	di, bx	; set offset into service name table
	mov	bp, cs:[networkServiceNameTable][di]	
	mov	bx, handle ConnectionConfirmNetworkName
	mov	si, offset ConnectionConfirmNetworkName
	clr	cx	; null terminated
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	mov	dx, cs	; restore segment
	call	ObjMessage

	; network ID
	mov	ax, es:[IAPLDsToken]
	call	DataStoreLockRecord
EC <	ERROR_C	ERROR_LOCK_RECORD_UPDATE_CONNECTION_DIALOG	>

	mov	dx, IAPL_NETWORK_ID_FIELD_ID
	call	DataStoreGetFieldPtr
EC <	ERROR_C	ERROR_GET_FIELD_PTR_UPDATE_CONNECTION_DIALOG	>

if DBCS_PCGEOS
	shr	cx
endif	; DBCS_PCGEOS

	mov	dx, ds	; point to string
	mov	bp, di	

	mov	bx, handle ConnectionConfirmNetworkID
	mov	si, offset ConnectionConfirmNetworkID
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	
	call	ObjMessage

	mov	ax, es:[IAPLDsToken]
	call	DataStoreUnlockRecord	

	; First get network password length
	mov	ax, es:[IAPLDsToken]
	clr	bx
	mov {byte} dl, IAPL_NETWORK_PASSWORD_FIELD_ID
	call	DataStoreGetFieldSize
EC <	ERROR_C	ERROR_DS_GET_FIELD_SIZE_UPDATE_CONNECTION_DIALOG >
	mov	cx, ax	; store size in cx
DBCS <	shr	ax	; store char length >
	mov	es:[NetworkPasswordLength], ax	; store char length 

	; Store the network password and length
	; Have to store it somewhere, since display of password is blotted
	; out by '*'
	mov	ax, es:[IAPLDsToken]	
	clr	bx	; use field ID
	mov {byte} dl, IAPL_NETWORK_PASSWORD_FIELD_ID
	mov	di, offset NetworkPassword
	call	DataStoreGetField	; get the information
EC <	ERROR_C ERROR_DS_GET_FIELD_UPDATE_CONNECTION_DIALOG	>
	

	; If there are no access points related to this service, clear the
	; fields, else fill them in.
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_GET_RECORD_COUNT_UPDATE_CONNECTION_DIALOG	>
	tst	ax
	jnz	update_connection_fill_fields

	call	ClearConnectionDialogFields
	jmp	exit_update_connection_dialog
	

update_connection_fill_fields:
	; get UID of acc pt associated with IAPL connection and load it in

	push	es	; store dgroup
	sub	sp, IAPL_NETWORK_ACC_PT_REF_FIELD_SIZE	; set space on stack
	mov	cx, IAPL_NETWORK_ACC_PT_REF_FIELD_SIZE	; set size of data
							; to grab.
	mov	ax, es:[IAPLDsToken]	
	mov {byte} dl, IAPL_NETWORK_ACC_PT_REF_ID	; grab UID #
	segmov	es, ss, bx	; store data to stack
	mov	di, sp		; set offset to stack
	clr	bx	; use field ID

	call	DataStoreGetField
EC <	ERROR_C ERROR_DS_GET_FIELD_UPDATE_CONNECTION_DIALOG	>
	mov	cx, ss:[di]	; store loword
	mov	dx, ss:[di+2]	; load hiword
	add	sp, IAPL_NETWORK_ACC_PT_REF_FIELD_SIZE	; restore stack
	
	pop	es	; restore dgroup
	call	OpenAccPtUID	; load in access point.  Default to 1st if deleted.

	; update: grab access point from connection info.  If UID = 0, then
	; access 1st access point in datastore
;	mov	ax, es:[IAPLDsToken]
;	clr	bx	; use field ID
;	mov {byte} dl, IAPL_NETWORK_ACC_PT_REF_ID
;	call	DataStoreGetField	; get UID of acc point	
	
	; access point related information
	mov	ax, es:[AccessPointDsToken]	
	call	DataStoreLockRecord
EC <	ERROR_C	ERROR_LOCK_RECORD_UPDATE_CONNECTION_DIALOG	>

	push	ds, si	; store record header
	; telephone number	
	mov	dx, ACCESS_POINT_LIST_TELEPHONE_NUMBER_FIELD_ID
	call	DataStoreGetFieldPtr
EC <	ERROR_C	ERROR_GET_FIELD_PTR_UPDATE_CONNECTION_DIALOG	>

if DBCS_PCGEOS
	shr	cx
endif	; DBCS_PCGEOS

	mov	dx, ds	
	mov	bp, di

	mov	bx, handle ConnectionConfirmTelephoneNumber
	mov	si, offset ConnectionConfirmTelephoneNumber
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	call	ObjMessage

	pop	ds, si	; restore record header
	; access point
	mov	ax, es:[AccessPointDsToken]
	mov	dx, ACCESS_POINT_LIST_ACCESS_POINT_FIELD_ID
	call	DataStoreGetFieldPtr
EC <	ERROR_C	ERROR_GET_FIELD_PTR_UPDATE_CONNECTION_DIALOG	>

if DBCS_PCGEOS
	shr	cx
endif	; DBCS_PCGEOS

	mov	dx, ds	; restore segment
	mov	bp, di		; restore offset

	mov	bx, handle ConnectionConfirmAccessPoint
	mov	si, offset ConnectionConfirmAccessPoint
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	call	ObjMessage

	mov	ax, es:[AccessPointDsToken]
	call	DataStoreUnlockRecord

	call	GetTerminalInfoAccPt		; load terminal information,
						; as might directly go to
						; connect from connection
						; dialog. 


	; finished with access point, now discard record
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreDiscardRecord
EC <	ERROR_C	ERROR_DISCARD_RECORD_UPDATE_CONNECTION_DIALOG	>

	; connection method
;	clr	ch
;	mov	cl, es:[CTbyte]
;	mov	si, cx
;	mov	cl, CT_COMBO_BOX_OFFSET
;	shr	si, cl	
;	and	si, CT_COMBO_BOX_MASK
;	shl	si	; word offset
;	mov	bp, cs:[comboBoxStringTable][si]

;	mov	bx, handle ConnectionConfirmConnectionMethod
;	mov	si, offset ConnectionConfirmConnectionMethod
;	clr	cx	; null terminated
;	mov	di, mask MF_CALL
;	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
;	mov	dx, cs	; restore segment

;	call	ObjMessage

	call	UpdateSetTerminal		; Now update the modem settings
	mov	bx, handle ProtocolBox
	mov	si, offset ProtocolBox
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_APPLY
	call	ObjMessage			; call each element to set
						; their setting functions.



exit_update_connection_dialog:

	.leave
	ret


UpdateConnectionDialog	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearConnectionDialogFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clears dialog fields of the connection confirm/setting
dialog. 

CALLED BY:	MSG_TERM_UPDATE_CONNECTION_DIALOG	
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		fills each field with a null character.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearConnectionDialogFields	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	mov	bx, segment dgroup
	mov	es, bx

	call	ClearStringBuffer

	; set up StringBuffer as target buffer
	mov	ax, segment dgroup
	mov	es, ax	
	
	mov	di, offset StringBuffer
	mov {byte}	es:[di], NULL_CHAR	; set first as null
	

	; network Name
	mov	bx, handle ConnectionConfirmNetworkName
	mov	si, offset ConnectionConfirmNetworkName
	clr	cx	; null terminated
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	mov	dx, es	; restore segment
	mov	bp, offset StringBuffer		; restore offset

	call	ObjMessage

	; networkID
	mov	bx, handle ConnectionConfirmNetworkID
	mov	si, offset ConnectionConfirmNetworkID
	clr	cx	; null terminated
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	mov	dx, es	; restore segment
	mov	bp, offset StringBuffer		; restore offset

	call	ObjMessage

	; telephone number
	mov	bx, handle ConnectionConfirmTelephoneNumber
	mov	si, offset ConnectionConfirmTelephoneNumber
	clr	cx	; null terminated
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	mov	dx, es	; restore segment
	mov	bp, offset StringBuffer		; restore offset

	call	ObjMessage


	; access point
	mov	bx, handle ConnectionConfirmAccessPoint
	mov	si, offset ConnectionConfirmAccessPoint
	clr	cx	; null terminated
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	mov	dx, es	; restore segment
	mov	bp, offset StringBuffer		; restore offset

	call	ObjMessage


	; connection method
;	mov	bx, handle ConnectionConfirmConnectionMethod
;	mov	si, offset ConnectionConfirmConnectionMethod
;	clr	cx	; null terminated
;	mov	di, mask MF_CALL
;	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

;	mov	dx, es	; restore segment
;	mov	bp, offset StringBuffer		; restore offset

;	call	ObjMessage

	.leave
	ret
ClearConnectionDialogFields	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSetTerminal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the fields in the set terminal dialog

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		sets the selections in the fields of set terminal to match
those of the currently selected access point. (saved version of the point)

Note: presumes data bytes already valid.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	8/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateSetTerminal	proc	near
	uses	ax,bx,cx,dx,si,di,es,bp
	.enter

	

	; set the selections for each of the dynamic lists based off the
	; values already in access point buffer.

	; set up dgroup segment 
	mov	bx, segment dgroup
	mov	es, bx



	; Baud
	clr	ah
	mov {byte} al, es:[BSDMbyte]
	mov	cl, BSDM_BAUD_RATE_OFFSET
	shr	ax, cl
	mov	dx, BSDM_BAUD_RATE_MASK
	and	ax, dx	; extract value by mask
	mov	di, offset baudIdentifierTable
	shl	ax	; word sized offsets
	add	di, ax	; get offset to baud identifier
	mov	cx, cs:[di]

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	mov	bx, handle BaudList
	mov	si, offset BaudList
	clr	dx
	call	ObjMessage	


	; Stop Bit
	clr	ah
	mov {byte} al, es:[BSDMbyte]
	mov	cl, BSDM_STOP_BIT_OFFSET
	shr	ax, cl
	mov	dx, BSDM_STOP_BIT_MASK
	and	ax, dx
	mov	di, offset stopBitsIdentifierTable
	shl	ax
	add	di, ax
	mov	cx, cs:[di]

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	mov	bx, handle StopList
	mov	si, offset StopList
	clr	dx
	call	ObjMessage


	; Data Bit
	clr	ah
	mov {byte} al, es:[BSDMbyte]
	mov	cl, BSDM_DATA_BIT_OFFSET
	shr	ax, cl
	mov	dx, BSDM_DATA_BIT_MASK
	and	ax, dx
	mov	di, offset dataBitsIdentifierTable
	shl	ax
	add	di, ax
	mov	cx, cs:[di]

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	mov	bx, handle DataList
	mov	si, offset DataList
	clr	dx
	call	ObjMessage


	; --------------------------------------------------
	;	PFK related information
	; --------------------------------------------------
	

	; Parity Bits
	clr	ah
	mov {byte} al, es:[PFKbyte]
	mov	cl, PFK_PARITY_BIT_OFFSET
	shr	ax, cl
	mov	dx, PFK_PARITY_BIT_MASK
	and	ax, dx
	mov	di, offset parityBitsIdentifierTable
	shl	ax
	add	di, ax
	mov	cx, cs:[di]

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	mov	bx, handle ParityList
	mov	si, offset ParityList
	clr	dx
	call	ObjMessage


	; Flow Control
	clr	ah
	mov {byte} al, es:[PFKbyte]
	mov	cl, PFK_FLOW_CONTROL_OFFSET 
	shr	ax, cl
	mov	dx, PFK_FLOW_CONTROL_MASK
	and	ax, dx
	push	ax	; store result

	tst	ax
	jnz	not_zero_none_boolean

	mov	dx, 1	; set boolean true
	jmp	set_none_boolean
not_zero_none_boolean:
	clr	dx	; set boolean false
set_none_boolean:
	mov	cx, cs:[flowIdentifierTable][PFK_FLOW_CONTROL_NOTHING * 2]
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	di, mask MF_CALL
	mov	bx, handle FlowList
	mov	si, offset FlowList
	; set none value boolean
	call	ObjMessage

	pop	ax	; restore & store value
	push	ax

	; get & set high bit (soft)
	mov	dx, ax	; store value
	and	dx, 1	; get first bit (hard)
	mov	cx, cs:[flowIdentifierTable][PFK_FLOW_CONTROL_HARDWARE * 2]
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	di, mask MF_CALL
	mov	bx, handle FlowList
	mov	si, offset FlowList
	call	ObjMessage

	pop	ax	; restore result
	; get & set low bit (hard)
	mov	dx, ax	; store value
	shr	dx	; get value of high bit (soft)
	mov	cx, cs:[flowIdentifierTable][PFK_FLOW_CONTROL_SOFTWARE * 2]
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	di, mask MF_CALL
	mov	bx, handle FlowList
	mov	si, offset FlowList
	call	ObjMessage



	; extract kanji code
	clr	bh
	mov {byte} bl, es:[PFKbyte]	; store data byte into bx
	mov	cl, PFK_KANJI_CODE_OFFSET
	shr	bx, cl	
	and	bx, PFK_KANJI_CODE_MASK

	shl	bx	; word offset
	mov	cx, cs:[kanjiFontIdentifierTable][bx]

	clr	dx	; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	mov	bx, handle KanjiFontList
	mov	si, offset KanjiFontList
	call	ObjMessage
	
	; --------------------------------------------------
	;	CT data: combo box and terminal settings
	; --------------------------------------------------
	
	; extract combo box
;	clr	bh
;	mov {byte} bl, es:[CTbyte]	; store data byte into bx
;	mov	cl, CT_COMBO_BOX_OFFSET
;	shr	bx, cl	
;	and	bx, CT_COMBO_BOX_MASK
;	mov	cx, bx	; set up target parameter
;	clr	dx	; not indeterminate
;	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
;	mov	di, mask MF_CALL
;	mov	bx, handle ComboBoxList
;	mov	si, offset ComboBoxList
;	call	ObjMessage

	; extract terminal
	clr	bh
	mov {byte} bl, es:[CTbyte]	; store data byte into bx
	mov	cl, CT_TERMINAL_OFFSET
	shr	bx, cl	
	and	bx, CT_TERMINAL_MASK
	shl	bx	; word offset
	mov	cx, cs:[terminalTypeIdentifierTable][bx]

	clr	dx	; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	mov	bx, handle TerminalList
	mov	si, offset TerminalList
	call	ObjMessage


	.leave
	ret
UpdateSetTerminal	endp


; ----------------------------------------------------------------------
;
; Routines for maintaining consistency of access point data between dialogs
; 3.2, 3.3, 3.5, 3.6, 3.7, 3.8, and 3.9
;
; ----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetSetNumItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	resets and sets new numItems count for genDynamicList

CALLED BY:	
PASS:		bx:si	=	optr to dynamic list
		cx	=	# of new items
RETURN:		
DESTROYED:	ax,  di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Because access points for various network services are stored all
together, it is very possible for a listing to start in middle of the list
and show everything in the rest of the list, because the numItems
is greater than the # of access points for that service.  This routine is
passed the new amount of items to display, along with an optr to the list.
It calls MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS, removing all those items with
MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS, and then calls
MSG_GEN_DYNAMIC_LIST_ADD_ITEMS to place in the new amount.
		
Note: if the # of items to remove and set is equal, this routine wouldn't
even bother.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetSetNumItems	proc	near
	uses	cx, dx, bp
	.enter	

	push	cx	; store # new items 

	mov	dx, cx	; store new item count into dx
	mov	di, mask MF_CALL	; want linear sequence, so block
	mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
	call	ObjMessage
	
	pop	dx	; restore # of items	
	cmp	cx, dx
	jz	exit_reset_num_items	; if equal, don't bother
					; attaching any new ones.

	push	dx	; store # of new items

	mov	dx, cx		; remove all items in previous list
	mov	cx, GDLP_FIRST	; remove them from the front
	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS	; remove them
	call	ObjMessage	

	
	pop	dx	; restore # of new items
	mov	cx, GDLP_FIRST
	mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS	; add new items
	call	ObjMessage	; add'em

exit_reset_num_items:

	.leave
	ret
ResetSetNumItems	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetServiceAccessPointCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the number of access points for this service

CALLED BY:	
PASS:		none
RETURN:		cx = count
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:	Note: we are presuming a word sized limit on the
number of access points (since I think that's as much as a gendynamic list
can handle).
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetServiceAccessPointCount	proc	near

	uses	ax,bx,dx,di,bp
	.enter
	
	mov	ax, segment dgroup
	mov	es, ax

	mov	ax, es:[AccessPointDsToken]
	call	DataStoreGetRecordCount
	mov	cx, ax	

	.leave
	ret
GetServiceAccessPointCount	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateNetworkElementFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	updates fields in network element box (3.5) to correspond to
information from current access point in buffer

CALLED BY:	
PASS:		none
RETURN:		
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:  Loads up the fields from the selected access point
and displays them in the fields of 3.5.
		
This updates the following fields:
	access point, telephone number

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateNetworkElementFields	proc	near

	; set up pointer to dgroup
	mov	ax, segment dgroup
	mov	es, ax	

	; First check to see if there are any entries, if not, just skip
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_GET_RECORD_COUNT_UPDATE_NETWORK_ELEMENT_FIELDS	>

	cmp	ax, 0
	jz	exit_update_network_element_fields

	; lock record (to get the handle)
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreLockRecord
EC <	ERROR_C	ERROR_LOCK_FIELD_UPDATE_NETWORK_ELEMENT_FIELDS	>

	push	ax, ds, si	; store token and record handle

	; Access Point 
	; grab the text pointer
	mov	dl, ACCESS_POINT_LIST_ACCESS_POINT_FIELD_ID
	call	DataStoreGetFieldPtr
EC <	ERROR_C	ERROR_GET_FIELD_UPDATE_NETWORK_ELEMENT_FIELDS	>

	; set pointers
	mov	dx, ds
	mov	bp, di

	; change 
	mov	bx, handle NetworkElementAccessPoint
	mov	si, offset NetworkElementAccessPoint

if DBCS_PCGEOS
	shr	cx
endif ; DBCS_PCGEOS

	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	call	ObjMessage

	; set the field's modified status to not modified, so that if user
	; changes the recorded value, then create a new acc point entry.
	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	clr	cx	
	call	ObjMessage

	; Telephone Number
	; grab the text pointer
	pop	ax, ds, si	; restore token and record handle
	mov	dl, ACCESS_POINT_LIST_TELEPHONE_NUMBER_FIELD_ID
	call	DataStoreGetFieldPtr
EC <	ERROR_C	ERROR_GET_FIELD_UPDATE_NETWORK_ELEMENT_FIELDS	>

	; set pointers
	mov	dx, ds
	mov	bp, di

	; change 
	mov	bx, handle NetworkElementTelephoneNumber
	mov	si, offset NetworkElementTelephoneNumber

if DBCS_PCGEOS
	shr	cx
endif ; DBCS_PCGEOS

	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	call	ObjMessage

	; set the field's modified status to not modified, so that if user
	; changes the recorded value, then create a new acc point entry.
	mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
	clr	cx	
	call	ObjMessage

	mov	ax, es:[AccessPointDsToken]
	call	DataStoreUnlockRecord
;	call	DataStoreDiscardRecord
EC <	ERROR_C	ERROR_DISCARD_RECORD_UPDATE_NETWORK_ELEMENT_FIELDS	>

exit_update_network_element_fields:

	ret

UpdateNetworkElementFields	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateNetworkIDPasswd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	updates network ID and passwd fields

CALLED BY:	
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateNetworkIDPasswd	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; if a new record, keep fields blank.
	mov {byte} al, es:[NewIAPLRecordFlag]
	cmp {byte} al, VALID
	jz	exit_update_network_ID_passwd

	; Need to lock current record when grabbing field ptrs
	mov	ax, es:[IAPLDsToken]
	call	DataStoreLockRecord
EC <	ERROR_C	ERROR_LOCK_RECORD_INIT_NETWORK_ELT	>
	push	ds, si		; store pointer to record header

	; get ptr to text
	mov	dl, IAPL_NETWORK_ID_FIELD_ID
	call	DataStoreGetFieldPtr
EC <	ERROR_C	ERROR_LOAD_IAPL_FIELD_NETWORK_ELT>

	; set up target pointer to point to field text
	mov	dx, ds
	mov	bp, di

	; fill in ID and password fields
	; Network ID
	mov	bx, handle NetworkElementNetworkID
	mov	si, offset NetworkElementNetworkID
if DBCS_PCGEOS
	shr	cx
endif ;DBCS_PCGEOS
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	call	ObjMessage

	; Network Password
	; grab the ptr to text
	pop	ds, si	; restore token and pointer
	mov	ax, es:[IAPLDsToken]

	mov	dl, IAPL_NETWORK_PASSWORD_FIELD_ID
	call	DataStoreGetFieldPtr
EC <	ERROR_C	ERROR_LOAD_IAPL_FIELD_NETWORK_ELT	>

if DBCS_PCGEOS
	shr	cx	; set to terms of characters
endif ; DBCS_PCGEOS

	call	ProcessBufferIntoPassword		; display stars
							; instead of actual
							; password 
	; set password
	mov	bx, handle NetworkElementNetworkPassword
	mov	si, offset NetworkElementNetworkPassword

	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	mov	dx, es	; restore segment
	mov	bp, offset StringBuffer		; restore offset

	call	ObjMessage

	; unlock record
	mov	ax, es:[IAPLDsToken]
	call	DataStoreUnlockRecord

exit_update_network_ID_passwd:

	.leave
	ret
UpdateNetworkIDPasswd	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearNetworkElementFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	used to clear text objects in network element dialog

CALLED BY:	
PASS:		C set = clear access point fields only
		C clear = clear ID and passwd fields only
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		clears StringBuffer, and then has all fields point to that

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearNetworkElementFields	proc	near
uses	ax, bx, cx, dx, di, si, bp
	.enter	

	; set dx here to determine if access point fields should be
	; cleared or not.
	mov	dx, 0 
	jnc	continue_clear_network_element_fields
	mov	dx, 1

continue_clear_network_element_fields:
	call	ClearStringBuffer

	; set up StringBuffer as target buffer
	mov	ax, segment dgroup
	mov	es, ax	
	
	mov	di, offset StringBuffer
	mov {byte}	es:[di], NULL_CHAR	; set first as null

if DBCS_PCGEOS
	mov {byte}	es:[di+1], NULL_CHAR_HIGH
endif	; DBCS_PCGEOS

	; check localFlag.  If false, then don't clear accpt related fields
	tst	dx
	jz	clear_network_id_passwd

	; Access Point Name

	mov	bx, handle NetworkElementAccessPoint
	mov	si, offset NetworkElementAccessPoint
	clr	cx	; null terminated
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	mov	dx, es	; restore segment
	mov	bp, offset StringBuffer		; restore offset

	call	ObjMessage



	; Telephone Number

	mov	bx, handle NetworkElementTelephoneNumber
	mov	si, offset NetworkElementTelephoneNumber
	clr	cx	; null terminated

	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	mov	dx, es	; restore segment
	mov	bp, offset StringBuffer		; restore offset

	call	ObjMessage

	jmp	exit_clear_network_element_fields


clear_network_id_passwd:
	; Network ID
	mov	bx, handle NetworkElementNetworkID
	mov	si, offset NetworkElementNetworkID
	clr	cx	; null terminated

	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	mov	dx, es	; restore segment
	mov	bp, offset StringBuffer		; restore offset

	call	ObjMessage


	; Network Password
	mov	bx, handle NetworkElementNetworkPassword
	mov	si, offset NetworkElementNetworkPassword
	clr	cx	; null terminated

	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	

	mov	dx, es	; restore segment
	mov	bp, offset StringBuffer		; restore offset

	call	ObjMessage

exit_clear_network_element_fields:
	.leave
	ret
ClearNetworkElementFields	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNetworkEltFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure network element field entries are valid.  

CALLED BY:	MSG_TERM_ACTIVATE_CONFIRM_SAVE
PASS:		none
RETURN:		C set = error occured (a field is not valid)
		C none = no error (all fields valid).
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	For each field, calls MSG_VIS_TEXT_GET_ALL_PTR.  If target is length
zero, return the appropriate error and then exit with error.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
errorStringHandleTable	word	handle EnterAccessPointStr, handle EnterAccessNumberStr, handle EnterNetworkIDStr, handle EnterNetworkPasswordStr

errorStringOffsetTable	word	offset EnterAccessPointStr, offset EnterAccessNumberStr, offset EnterNetworkIDStr, offset EnterNetworkPasswordStr

netEltFieldHandleTable	word	handle NetworkElementAccessPoint, handle NetworkElementTelephoneNumber, handle NetworkElementNetworkID, handle NetworkElementNetworkPassword

netEltFieldOffsetTable	word	offset NetworkElementAccessPoint, offset NetworkElementTelephoneNumber, offset NetworkElementNetworkID, offset NetworkElementNetworkPassword

CheckNetworkEltFields	proc	near

	uses	ax,bx,cx,dx,si,di,bp
	.enter

	clr	cx			; set up count
	
	mov	dx, es			; set up StringBuffer as target
	mov	bp, offset StringBuffer
	

check_field_check_net_elt_fields_loop:	
	mov	si, cx
	shl	si	; set offset
	push	cx	; save counter offset
	mov	di, mask MF_CALL	; di and ax trashed, even though
					; spec says they arent. ???
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	bx, cs:[netEltFieldHandleTable][si]
	mov	si, cs:[netEltFieldOffsetTable][si]
	call	ObjMessage
	tst	cx	; test result
	pop	cx	; restore counter offset 
	jz	check_net_elt_fields_error_dialog	; if empty field,
							; then activate
							; appropriate error
							; and exit.
	inc	cx	; increment cx
	cmp	cx, 4	; okay, this is bad (should be replaced by a
			; constant), but since even tables hard coded for
			; this value...
;	je	no_error_exit_check_network_elt_fields	; if hit limit, exit
	jb	check_field_check_net_elt_fields_loop	; else continue loop

no_error_exit_check_network_elt_fields:
	clc	; no errors, clear carry
	.leave
	ret
;	jmp	exit_check_network_elt_fields	; exit

check_net_elt_fields_error_dialog:
	; error occured, bring up the error dialog.
	; load string 
	mov	di, cx	; prepare offset
	shl	di	; word sized offset
	mov	bx, cs:[errorStringHandleTable][di]
	mov	bp, cs:[errorStringOffsetTable][di]
	call	MemLock		; lock string 
	push	bx		; save handle
	push	es		; store dgroup

	mov	di, ax		; set segment of error string
	mov	es, ax		; set segment (to grab actual offset)
	mov	bp, es:[bp]	; grab actual offset

	; bring up confirmation dialog
	mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE \
			or mask CDBF_SYSTEM_MODAL 	; to bring to top
	call	TermUserStandardDialog
	pop	es		; restore dgroup
	pop	bx	
	call	MemUnlock	; unlock string
	stc			; set carry (error occured).

exit_check_network_elt_fields:
	
	.leave
	ret
CheckNetworkEltFields	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateConfirmSaveDataFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update confirm save data dialog info fields from current
info in global memory (not access point).

CALLED BY:	
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:  updates from state information in memory, as this
asks to see if user wishes to save or not.  Note that this information is
updated from entry into dialog 3.6, to prevent redudant updates.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	8/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateConfirmSaveDataFields	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; set up dgroup
	mov	bx, segment dgroup
	mov	ds, bx

	; Network Service
	sub	sp, 2				; set up stack to receive
						; data
	mov	dx, IAPL_NETWORK_SERVICE_FIELD_ID
	segmov	es, ss, bx			; set up target segment
	mov	di, sp				; set up target offset
	mov	cx, 1				; max 5 services
	mov	ax, ds:[IAPLDsToken]		; set up target
	clr	bx				; use field ID only
	call	DataStoreGetField
EC <	ERROR_C	ERROR_DS_GET_FIELD_UPDATE_CONFIRM_SAVE_DATA_FIELDS	>

	mov	ax, ss:[di]			; grab argument
	clr	ah				; byte argument, hiword is
						; trash	
	add	sp, 2				; restore stack
	shl	ax	; word offset
	mov	si, ax	; use si to reference offset to data
	mov	bp, cs:[networkServiceNameTable][si]

	mov	bx, handle ConfirmSaveDataNetworkName
	mov	si, offset ConfirmSaveDataNetworkName
	clr	cx				; null terminated
	mov	dx, cs				; set target segment
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessage

	segmov	es, ds, bx	; set es to point to dgroup here

if ERROR_CHECK
test_code:
	; Test code
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreGetRecordCount

	mov	ax, es:[AccessPointDsToken]
	clr	bx
	mov	dx, ACCESS_POINT_LIST_TELEPHONE_NUMBER_FIELD_ID
	mov	di, offset StringBuffer
	mov	cx, 64
	call	DataStoreGetField
	; end test code
endif ;ERROR_CHECK

	; Access Point 
	
	mov	ax, es:[AccessPointDsToken]
	mov	dx, ACCESS_POINT_LIST_ACCESS_POINT_FIELD_ID
	clr	bx		; use field ID to get field
	call	DataStoreGetFieldSize
	mov	cx, ax
	call	ClearStringBuffer
	mov	ax, es:[AccessPointDsToken]
	mov	di, offset StringBuffer
	call	DataStoreGetField
EC <	ERROR_C	ERROR_DS_GET_FIELD_UPDATE_CONFIRM_SAVE_DATA_FIELDS	>

if DBCS_PCGEOS
	shr	cx
endif	; DBCS_PCGEOS

	mov	bp, di
	mov	bx, handle ConfirmSaveDataAccessPoint
	mov	si, offset ConfirmSaveDataAccessPoint
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	mov	dx, ds	; store segment
	call	ObjMessage

	; Telephone Number
	mov	dx, ACCESS_POINT_LIST_TELEPHONE_NUMBER_FIELD_ID
	clr	bx		; use field ID to get field
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreGetFieldSize
EC <	ERROR_C	ERROR_DS_GET_FIELD_SIZE_UPDATE_CONFIRM_SAVE_DATA_FIELDS	>
	mov	cx, ax

	call	ClearStringBuffer
	mov	ax, es:[AccessPointDsToken]
	mov	di, offset StringBuffer
	call	DataStoreGetField
EC <	ERROR_C	ERROR_DS_GET_FIELD_UPDATE_CONFIRM_SAVE_DATA_FIELDS	>

if DBCS_PCGEOS
	shr	cx
endif	; DBCS_PCGEOS

	mov	bp, di
	mov	bx, handle ConfirmSaveDataTelephoneNumber
	mov	si, offset ConfirmSaveDataTelephoneNumber
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	mov	dx, ds	; store segment
	call	ObjMessage

	; IAPL name
	;
	; if new IAPL record, use default title, else use stored name
	cmp	es:[NewIAPLRecordFlag], VALID
	jz	use_default_IAPL_name

	call	ClearStringBuffer
	mov	ax, es:[IAPLDsToken]
	mov	di, offset StringBuffer		; StringBuffer = target
	clr	bx				; use field ID
	mov	dl, IAPL_NAME_FIELD_ID
	call	DataStoreGetFieldSize
EC <	ERROR_C	ERROR_DS_GET_FIELD_SIZE_UPDATE_CONFIRM_SAVE_DATA_FIELDS	>
	mov	cx, ax			; set size (bytes)
	mov	ax, es:[IAPLDsToken]
	call	DataStoreGetField
EC <	ERROR_C	ERROR_DS_GET_FIELD_UPDATE_CONFIRM_SAVE_DATA_FIELDS	>
DBCS <	shr	cx	>	; bytes-->chars length
	mov	dx, es
	mov	bp, di	; set StringBuffer as output target
	jmp	write_out_IAPL_name

use_default_IAPL_name:
	call	ProcessNameMoniker
	mov	bp, dx	; set offset
	mov	dx, cx	; set segment
	clr	cx	; null terminated

write_out_IAPL_name:
	mov	bx, handle ConfirmSaveDataIAPLName
	mov	si, offset ConfirmSaveDataIAPLName
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	call	ObjMessage

	; Network ID
	mov	ax, es:[IAPLDsToken]
	mov	dx, IAPL_NETWORK_ID_FIELD_ID
	clr	bx		; use field ID to get field
	call	DataStoreGetFieldSize
EC <	ERROR_C	ERROR_DS_GET_FIELD_SIZE_UPDATE_CONFIRM_SAVE_DATA_FIELDS	>
	mov	cx, ax
	
	call	ClearStringBuffer
	mov	ax, es:[IAPLDsToken]
	mov	di, offset StringBuffer
	call	DataStoreGetField
EC <	ERROR_C	ERROR_DS_GET_FIELD_UPDATE_CONFIRM_SAVE_DATA_FIELDS	>

if DBCS_PCGEOS
	shr	cx
endif	; DBCS_PCGEOS

	mov	bp, di
	mov	bx, handle ConfirmSaveDataNetworkID
	mov	si, offset ConfirmSaveDataNetworkID
	mov	dx, ds
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
	call	ObjMessage

exit_update_csdf:
	.leave
	ret

UpdateConfirmSaveDataFields	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateConfirmSaveDetails
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	updates the fields for Connection Save Data AP (details),
dialog 3.9.  

CALLED BY:	MSG_TERM_ACTIVATE_SET_TERMINAL
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: gets information from the current state (memory), not
the datastore, as the changes set may not ahve been stored.  Not that this
is called from MSG_TERM_ACTIVATE_SET_TERMINAL to save redundant updatings 
if switching between dialogs 3.8 and 3.9.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	8/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;CSDDKeyMacroFieldOffsetTable	word	offset ConfirmSaveDataDetailsKeyMacro1, offset ConfirmSaveDataDetailsKeyMacro2, offset ConfirmSaveDataDetailsKeyMacro3, offset ConfirmSaveDataDetailsKeyMacro4, offset ConfirmSaveDataDetailsKeyMacro5  


UpdateConfirmSaveDetails	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	
	;mov	dx, segment Baud300Text	; resource where all strings reside.


	; extract baud rate
	clr	bh
	mov	bl, es:[BSDMbyte]	; store data byte into bx
	mov	cl, BSDM_BAUD_RATE_OFFSET
	shr	bx, cl	
	and	bx, BSDM_BAUD_RATE_MASK
	shl	bx	; word offset
	mov	dx, cs	; set up target segment
	; set the baud
	mov	bp, cs:[baudStringTable][bx]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ConfirmSaveDataDetailsBaud
	mov	si, offset ConfirmSaveDataDetailsBaud
	mov	di, mask MF_CALL
	clr	cx	; null terminated
	call	ObjMessage


	; extract stop bit
	clr	bh
	mov	bl, es:[BSDMbyte]	; store data byte into bx
	mov	cl, BSDM_STOP_BIT_OFFSET
	shr	bx, cl	
	and	bx, BSDM_STOP_BIT_MASK
	shl	bx	; word offset
	mov	dx, cs	; set up target segment
	; set the baud
	mov	bp, cs:[stopBitStringTable][bx]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ConfirmSaveDataDetailsStopBits
	mov	si, offset ConfirmSaveDataDetailsStopBits
	mov	di, mask MF_CALL
	clr	cx	; null terminated
	call	ObjMessage


	; extract data bit
	clr	bh
	mov	bl, es:[BSDMbyte]	; store data byte into bx
	mov	cl, BSDM_DATA_BIT_OFFSET
	shr	bx, cl	
	and	bx, BSDM_DATA_BIT_MASK
	shl	bx	; word offset
	mov	dx, cs	; set up target segment
	; set the databit
	mov	bp, cs:[dataBitStringTable][bx]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ConfirmSaveDataDetailsDataBits
	mov	si, offset ConfirmSaveDataDetailsDataBits
	mov	di, mask MF_CALL
	clr	cx	; null terminated
	call	ObjMessage


	; extract combo box
	clr	bh
	mov	bl, es:[CTbyte]	; store data byte into bx
	mov	cl, CT_COMBO_BOX_OFFSET
	shr	bx, cl	
	and	bx, CT_COMBO_BOX_MASK
	shl	bx	; word offset
	mov	dx, cs	; set up target segment
	; set the combobox
;	mov	bp, cs:[comboBoxStringTable][bx]
;	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
;	mov	bx, handle ConfirmSaveDataDetailsConnectionMethod
;	mov	si, offset ConfirmSaveDataDetailsConnectionMethod
;	mov	di, mask MF_CALL
;	clr	cx	; null terminated
;	call	ObjMessage


	; extract parity
	clr	bh
	mov	bl, es:[PFKbyte]	; store data byte into bx
	mov	cl, PFK_PARITY_BIT_OFFSET
	shr	bx, cl	
	and	bx, PFK_PARITY_BIT_MASK
	shl	bx	; word offset
	mov	dx, cs	; set up target segment
	; set the parity
	mov	bp, cs:[parityStringTable][bx]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ConfirmSaveDataDetailsParityBit
	mov	si, offset ConfirmSaveDataDetailsParityBit
	mov	di, mask MF_CALL
	clr	cx	; null terminated
	call	ObjMessage

	; extract Terminal
	clr	bh
	mov	bl, es:[CTbyte]	; store data byte into bx
	mov	cl, CT_TERMINAL_OFFSET
	shr	bx, cl	
	and	bx, CT_TERMINAL_MASK
	shl	bx	; word offset
	mov	dx, cs	; set up target segment
	; set the terminal
	mov	bp, cs:[terminalStringTable][bx]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ConfirmSaveDataDetailsTerminalType
	mov	si, offset ConfirmSaveDataDetailsTerminalType
	mov	di, mask MF_CALL
	clr	cx	; null terminated
	call	ObjMessage




	; extract flow
	clr	bh
	mov	bl, es:[PFKbyte]	; store data byte into bx
	mov	cl, PFK_FLOW_CONTROL_OFFSET
	shr	bx, cl	
	and	bx, PFK_FLOW_CONTROL_MASK
	shl	bx	; word offset
	mov	dx, cs	; set up target segment
	; set the flow
	mov	bp, cs:[flowStringTable][bx]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ConfirmSaveDataDetailsFlowControl
	mov	si, offset ConfirmSaveDataDetailsFlowControl
	mov	di, mask MF_CALL
	clr	cx	; null terminated
	call	ObjMessage

	
	; extract kanji code
	clr	bh
	mov	bl, es:[PFKbyte]	; store data byte into bx
	mov	cl, PFK_KANJI_CODE_OFFSET
	shr	bx, cl	
	and	bx, PFK_KANJI_CODE_MASK
	shl	bx	; word offset
	mov	dx, cs	; set up target segment
	; set the kanji code
	mov	bp, cs:[kanjiFontStringTable][bx]
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ConfirmSaveDataDetailsKanjiFont
	mov	si, offset ConfirmSaveDataDetailsKanjiFont
	mov	di, mask MF_CALL
	clr	cx	; null terminated
	call	ObjMessage


	; Now place in key macro text
	; Update from the dialog fields
;	clr	bx	; start at 0
;	mov	dx, segment dgroup	; set target buffer StringBuffer
;	mov	bp, offset StringBuffer
		
;update_key_macro_loop:
;	push	bx	; store count
;	shl	bx	; word offset
;	push	bx	; store offset
;	mov	si, cs:[MacroFieldTable][bx]
;	mov	bx, handle KeyMacro1Field

;	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
;	mov	di, mask MF_CALL
;	call	ObjMessage

;	pop	bx	; restore offset
;	mov	si, cs:[CSDDKeyMacroFieldOffsetTable][bx]
;	mov	bx, handle ConfirmSaveDataDetailsKeyMacro1
;	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
;	call	ObjMessage

;	pop	bx	; restore count
;	inc	bx
;	cmp	bx, MAX_KEY_MACRO
;	jl	update_key_macro_loop

	.leave
	ret
UpdateConfirmSaveDetails	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessBufferIntoPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given a string length (in terms of characters), places the
equivalent string blatted out with '*' in StringBuffer.

CALLED BY:	UpdateNetworkElementFields
PASS:		cx = length (in terms of characters)
RETURN:		String Buffer full of '*'
DESTROYED:	nothing
SIDE EFFECTS:	clears StringBuffer and writes '*' into it.

PSEUDO CODE/STRATEGY: given a string i.e. "Ultraman",
converts it into "********", which is suitable for displaying
passwords. This new string is placed into StringBuffer.
		
Loops until it hits a null character

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessBufferIntoPassword	proc	near
	uses	bx,cx,si,es,bp
	.enter
	call	ClearStringBuffer

	mov	bx, segment dgroup
	mov	es, bx
	mov	si, offset StringBuffer

	mov	ds, bx

process_into_passwd_loop:

	tst	cx
	jcxz	exit_process_string_buffer_into_password

continue_process_password:
	mov {byte}	es:[si], STAR_CHAR
	inc	si
	dec	cx

if DBCS_PCGEOS
	mov {byte}	es:[si], STAR_CHAR_HIGH
	inc	si

endif ; DBCS_PCGEOS

	jmp	process_into_passwd_loop

exit_process_string_buffer_into_password:
	mov {byte}	es:[si], NULL_CHAR	; null terminate password

if DBCS_PCGEOS
	mov {byte}	es:[si+1], NULL_CHAR_HIGH ; top byte of null char
endif ; DBCS_PCGEOS

	.leave
	ret
ProcessBufferIntoPassword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringBufferCharCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the # of characters up to but not including NULL in
StringBuffer.  If max elements reached, returns max elements.

CALLED BY:	
PASS:		none	
RETURN:		cx = char count
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StringBufferCharCount	proc	near
	uses	bx,di,es,bp
	.enter
		
	; set of target segments first
	mov	bx, segment dgroup
	mov	es, bx

	mov	di, offset StringBuffer
	clr	cx	

sbcc_count_loop:
	; check to see if max limit hit.  If so, exit out

if DBCS_PCGEOS
	cmp	cx, STRING_BUFFER_SIZE / 2	; size always even
else
	cmp	cx, STRING_BUFFER_SIZE
endif
	jz	sbcc_exit_loop
	
	; now check to see if char is a null
	cmp {byte}	es:[di], NULL_CHAR
	
if DBCS_PCGEOS
	jnz	sbcc_continue_check	; lo byte correlates to null, now
					; check the hi byte of db null char
	cmp {byte}	es:[di+1], 0
	jz	sbcc_null_char

sbcc_continue_check:
	add	di, 2			; increment by a char (db)
	
else
	jz	sbcc_null_char
	inc	di			; increment by a char (sb)
endif
	inc	cx
	jmp	sbcc_count_loop		; continue counting

sbcc_null_char:
;	inc	cx			; count the NULL

sbcc_exit_loop:

	.leave
	ret
StringBufferCharCount	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessNameMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	concatenates service name and access point into one name

CALLED BY:	
PASS:		none
RETURN:		cx:dx = fptr to Name string
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		First load the network service into the buffer.  Then, pointing
to the end of the name in StringBuffer, use that location as the new place
to get the string for the access point.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessNameMoniker	proc	near
	uses	ax,bx,si,di,bp
	.enter

	mov	bx, segment dgroup	; set up segment
	mov	es, bx	

	call	ClearStringBuffer	; clear string buffer first

	; set up argument on the stack
	sub	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1; even to keep swat
						       ; happy 
	; get the service #
	mov	ax, es:[IAPLDsToken]	; set to IAPL datastore
	clr	bx			; use field ID
	mov	dl, IAPL_NETWORK_SERVICE_FIELD_ID
	mov	di, sp			; point to stack
	mov	cx, IAPL_NETWORK_SERVICE_FIELD_SIZE	; copy data size
	call	DataStoreGetField	; grab text into StringBuffer
	clr	ch
	mov {byte}	cl, ss:[di]		; put service # into cx
	add	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1	; restore stack

	; now get the string offset to the network service
	shl	cx			; word sized offsets
	mov	di, cx			; set for offset
	mov	si, cs:[networkServiceNameTable][di]	; get offset to di
	
	; Now copy the string into the StringBuffer
	; Note that a check has to be implemented here to make sure the
	; string buffer max size isn't crossed over.
	;
	; both strings in segment es
	; 
	;	di = offset to StringBuffer
	;	si = offset to service name string
	;

	mov	di, offset StringBuffer	; set di to beginning of
					; StringBuffer
	
		
process_Name_copy_loop:
	cmp {byte} cs:[si], NULL_CHAR		; check to see if bottom byte is
					; null 
if DBCS_PCGEOS	
	jnz	continue_process_Name_copy

	cmp {byte}	cs:[si+1], 0		; check to see if top byte is 0
	jz	exit_process_Name_copy_loop	; reached null char, so
						; finish
continue_process_Name_copy:
	; else continue copy
	mov	ax, cs:[si]
	mov	es:[di], ax
	mov	ax, cs:[si+1]
	mov	es:[di+1],ax
	
	; increment si, di
	add	si, 2	; 2 for double byte size
	add	di, 2
	jmp	process_Name_copy_loop
else
	jz	exit_process_Name_copy_loop
	mov	ax, cs:[si]
	mov	es:[di], ax
	jmp	process_Name_copy_loop
endif

exit_process_Name_copy_loop:

	; add in ':' to end of string

	mov {byte} es:[di], COLON_CHAR
	inc	di
if DBCS_PCGEOS
	mov {byte} es:[di], COLON_CHAR_HIGH
	inc	di	
endif	

	; Get length of Access Point string
	mov	bp, di			; set target to end of string in
					; StringBuffer.
	mov	ax, es:[AccessPointDsToken]
	mov	dl, ACCESS_POINT_LIST_ACCESS_POINT_FIELD_ID	
	call	DataStoreGetFieldSize	; get size 
EC <	ERROR_C ERROR_GET_DS_FIELD_SIZE_PROCESS_NAME_MONIKER	>

	; Got size, now get the actual data at the end

	mov	cx, ax			; store size into cx 
	mov	ax, es:[AccessPointDsToken]

if DBCS_PCGEOS
	shl	cx		; bytes here, not characters 
endif ; DBCS_PCGEOS

	call	DataStoreGetField
EC <	ERROR_C ERROR_GET_DS_FIELD_PROCESS_NAME_MONIKER	>

	; now add null character to end
	add	di, cx			
	; should add error handler to avoid running over StringBuffer size 
	mov {byte} es:[di], NULL_CHAR	; place in NULL

if DBCS_PCGEOS
	mov {byte} es:[di+1], 0		; for top part of null char (db)
endif

	; now return string
	mov	cx, es
	mov	dx, offset StringBuffer


	; remove Name changes

	; Everything set up, so set vis moniker to the StringBuffer
	; contents for each dialog from 3.5 on
		
	; point to StringBuffer
;	mov	cx, es
;	mov	dx, offset StringBuffer
	
;	mov	bp, VUM_DELAYED_VIA_APP_QUEUE	; update mode



;	mov	bx, handle NetworkElementDialog
;	mov	si, offset NetworkElementDialog
;	clr	di
;	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
;	call	ObjMessage

;	mov	cx, es
;	mov	dx, offset StringBuffer
;	mov	bp, VUM_DELAYED_VIA_APP_QUEUE
;	mov	bx, handle SetKeyMacroDialog
;	mov	si, offset SetKeyMacroDialog
;	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
;	call	ObjMessage

;	mov	cx, es
;	mov	dx, offset StringBuffer
;	mov	bp, VUM_DELAYED_VIA_APP_QUEUE
;	mov	bx, handle ProtocolBox
;	mov	si, offset ProtocolBox
;	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
;	call	ObjMessage

;	mov	cx, es
;	mov	dx, offset StringBuffer
;	mov	bp, VUM_DELAYED_VIA_APP_QUEUE
;	mov	bx, handle ConfirmSaveDataDialog
;	mov	si, offset ConfirmSaveDataDialog
;	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
;	call	ObjMessage;

;	mov	cx, es
;	mov	dx, offset StringBuffer
;	mov	bp, VUM_DELAYED_VIA_APP_QUEUE
;	mov	bx, handle ConfirmSaveDataDetailsDialog
;	mov	si, offset ConfirmSaveDataDetailsDialog
;	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
;	call	ObjMessage


exit_process_Name_moniker:

	.leave
	ret

ProcessNameMoniker	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermSetNetworkSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets current IAPL record buffer's network selection to
selected value.

CALLED BY:	MSG_TERM_SET_NETWORK_SELECTION
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
		
		cl	= index # of selection
RETURN:		
DESTROYED:	ax, dx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/28/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermSetNetworkSelection	method dynamic TermClass, 
					MSG_TERM_SET_NETWORK_SELECTION
	uses	bp
	.enter

	push	es

	; store selection onto stack
	sub	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1
	mov	di, sp		; set target offset
	mov {byte} ss:[di], cl ; move arg onto stack

	; store current network service to IAPL record buffer
	mov	ax, es:[IAPLDsToken]
	mov	dl, IAPL_NETWORK_SERVICE_FIELD_ID
	mov	cx, IAPL_NETWORK_SERVICE_FIELD_SIZE
	segmov	es, ss, bx	; set target segment
	clr	bx	; use field ID
	call	DataStoreSetField	; set the field
EC <	ERROR_C	ERROR_DS_SET_FIELD_SET_NETWORK_SELECTION	>

	add	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1	; restore stack
	pop	es	; restore dgroup 

;	mov	es:[CurrentAccessPoint], 0 ; default to top selection

exit_set_network_selection:
	.leave
	ret

TTermSetNetworkSelection	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNetEltDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Using currently loaded access point, determines if it can
be deleted or not and sets delete button appropriately.

CALLED BY:	
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: queries UserCreated field of access point.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNetEltDelete	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, SHORT_SIZE	; use stack as target
	mov	di, sp		; set offset to target
	
	mov	ax, es:[AccessPointDsToken]
	push	es	; save dgroup
	segmov	es, ss, bx	; set segment of target
	clr	bx	; use field id 
	mov	cx, 1	; information is one byte big
	mov	dl, ACCESS_POINT_LIST_USER_CREATED_FIELD_ID
	
	call	DataStoreGetField
EC <	ERROR_C ERROR_DS_GET_FIELD_SET_NET_ELT_DELETE	>

	cmp {byte} es:[di], USER_CREATED
	je	user_created_enable_delete

	; not user created, disable it
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jmp	set_net_elt_delete_button

user_created_enable_delete:
	mov	ax, MSG_GEN_SET_ENABLED	

set_net_elt_delete_button:
	; set up call variables
	mov	bx, handle NetworkElementDeleteButton 
	mov	si, offset NetworkElementDeleteButton 
	mov	di, mask MF_CALL
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE	; set visupdate mode
	; call ObjMessage to set the state
	call	ObjMessage

	pop	es	; restore dgroup
	add	sp, SHORT_SIZE	; restore stack

	.leave
	ret
SetNetEltDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermDeleteIaplRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	runs through procedure for deleting IAPL account record in
dialog 4.2 (Connection Settings).

CALLED BY:	MSG_TERM_DELETE_IAPL_RECORD
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: brings up modal dialog to query whether to quit or
not, and then performs appropriate action.  Afterwards, calls up appropriate
dialog. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/18/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermDeleteIaplRecord	method dynamic TermClass, 
					MSG_TERM_DELETE_IAPL_RECORD
	uses	ax, cx, dx, bp
	.enter

	mov	bx, handle DeleteConnectionStr
	mov	bp, offset DeleteConnectionStr
	call	MemLock		; lock string 
	push	bx		; save handle
	push	es		; store dgroup

	mov	di, ax		; set segment of error string
	mov	es, ax		; set segment (to grab actual offset)
	mov	bp, es:[bp]	; grab actual offset

	; bring up confirmation dialog
	mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE \
			or mask CDBF_SYSTEM_MODAL or mask CDBF_DESTRUCTIVE_ACTION		; to bring to top
	call	TermUserStandardDialog
	pop	es		; restore dgroup

delete_iapl_debug_flag:
	pop	bx		; restore handle
	call	MemUnlock	; unlock string resource

	cmp	ax, IC_YES
	jne	no_delete_iapl_record

	; ok to delete current selection
	mov	ax, es:[IAPLDsToken]
	clr	dx
	clr	ch
	mov	cl, es:[CurrentIAPLSelection]
	call	DataStoreDeleteRecordNum
;EC <	ERROR_C	ERROR_DS_DELETE_IAPL_RECORD	>

	mov	ax, es:[IAPLDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_DS_GET_RECORD_COUNT_DELETE_IAPL_RECORD	>
Assert_srange	ax 0 MAX_IAPL_COUNT 
	tst	ax
	jz	continue_delete_iapl_record	; no records, so keep
						; current selection at 0
						; (since curr selection will
						; be 0 anyways before last
						; item is deleted).

	cmp {byte}  es:[CurrentIAPLSelection], al 	; check to see if
							; curr selection 
	jl	continue_delete_iapl_record	; is greater than # records
	dec	ax	; count is 1 based, identifier is 0 based
	mov	es:[CurrentIAPLSelection], al		; if so, set curr
	mov	cx, ax					; selection 
							; to # records

continue_delete_iapl_record:
	call	SetCurrIAPLSelection
	call	UpdateConnectionDialog
	call	ActivateConnectionSetting	; update

	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord	; discard record
	jnc	exit_term_delete_iapl_record
	cmp	ax, DSDE_RECORD_BUFFER_EMPTY
	je	exit_term_delete_iapl_record	; if buffer already clear,
						; Ok, continue.
EC <	ERROR_C	ERROR_DS_DISCARD_RECORD_DELETE_IAPL_RECORD >
exit_term_delete_iapl_record:

	.leave
	ret

no_delete_iapl_record:
	mov	bx, handle ConnectionConfirmDialog
	mov	si, offset ConnectionConfirmDialog
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	jmp	exit_term_delete_iapl_record

TTermDeleteIaplRecord	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermDeleteAccessPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_TERM_DELETE_ACCESS_POINT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/18/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermDeleteAccessPoint	method dynamic TermClass, 
					MSG_TERM_DELETE_ACCESS_POINT
	uses	ax, cx, dx, bp
	.enter

	GetResourceHandleNS	DeleteAccessPointStr, bx
	mov	bp, offset DeleteAccessPointStr
	call	MemLock		; lock string 
	push	bx		; save handle
	push	es		; store dgroup

	mov	di, ax		; set segment of error string
	mov	es, ax		; set segment (to grab actual offset)
	mov	bp, es:[bp]	; grab actual offset

	; bring up confirmation dialog
	mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE \
			or mask CDBF_SYSTEM_MODAL or mask CDBF_DESTRUCTIVE_ACTION		; to bring to top
	call	TermUserStandardDialog
	pop	es		; restore dgroup

delete_iapl_debug_flag:
	pop	bx		; restore handle
	call	MemUnlock	; unlock string resource

	cmp	ax, IC_YES
	jne	no_delete_acc_pt_record

	; ok to delete current selection
	mov	ax, es:[AccessPointDsToken]
	clr	dx
	mov	cx, es:[CurrentAccessPoint]
	call	DataStoreDeleteRecordNum

	mov	ax, es:[AccessPointDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_DS_GET_RECORD_COUNT_DELETE_ACC_PT_RECORD	>
	tst	ax
	jz	continue_delete_acc_pt_record	; if no access points, just
						; continue.

	cmp	es:[CurrentAccessPoint], ax	; make sure
	jl	continue_delete_acc_pt_record	; CurrentAccessPoint !>
						; actual # records

	dec	ax	; count 1 based, identifier 0 based
	mov	es:[CurrentAccessPoint],ax	; If so, set to current max

continue_delete_acc_pt_record:
	call	InitializeNetworkElement	; bring up network element
						; dialog 
exit_term_delete_acc_pt_record:
	.leave
	ret

no_delete_acc_pt_record:
	mov	bx, handle NetworkElementDialog
	mov	si, offset NetworkElementDialog
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	jmp	exit_term_delete_acc_pt_record

TTermDeleteAccessPoint	endm



; ----------------------------------------------------------------------
;
;			routines for handling
;			state information
;
; ----------------------------------------------------------------------




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurrentIAPLSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets current network service (CurrentNetworkService).

CALLED BY:	MSG_TERM_SET_IAPL_SELECTION
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #

		cx	= selection #
RETURN:		
DESTROYED:	es	
SIDE EFFECTS:	Sets the current network service to the selected value,
passed by the GenDynamicList.  Also updates the dialogs for connection
confirm/setting. Loads in IAPL record and opens corresponding service.
Loads in first access point record of service datastore as well.

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/ 6/96   	Initial version
	eyeh	9/27/96		Loads IAPL and access point info into record
				buffer now.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCurrentIAPLSelection	method dynamic TermClass, 
					MSG_TERM_SET_IAPL_SELECTION
	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord	; discard previous record
	mov {byte} es:[CurrentIAPLSelection], cl	
	call	SetCurrIAPLSelection
	call	UpdateConnectionDialog	; update dialogs
	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord	; discard record

	ret


SetCurrentIAPLSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurrIAPLSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given selection #, loads that IAPL record into the buffer,
closing old accpt datastore and opening new one corresonding to its service.

CALLED BY:	SetCurrentIAPLSelection, TermConnectButtonHit
PASS:		cx = selection #	
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	loads the record corresponding to the CurrentIAPLSelection.  Also
loads in its service datastore, discarding previous datastore.  Also resets
CurretnAccessPoint selection to 0 (default focus to top).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCurrIAPLSelection	proc	near
	uses	ax,bx,cx,dx,di,bp, es
	.enter

	; set up segment
	mov	bx, segment dgroup
	mov	es, bx

	; check to see if IAPL contains any records. If none, just skip
	; ahead to UpdateConnectionDialog, which clears fields.
	mov	ax, es:[IAPLDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_DS_GET_RECORD_COUNT_SET_CURRENT_IAPL_SELECTION >
	cmp	ax, 0
	jz	exit_set_curr_iap_selection

	; else records exist and load in new IAPL selection
	mov	ax, es:[IAPLDsToken]
	clr	dx				; gendynamiclists can't handle
	call	DataStoreLoadRecordNum		; that many items, so clear dx.
EC <	ERROR_C	ERROR_LOAD_RECORD_SET_CURRENT_IAPL_SELECTION	>

	; get network service #
	sub	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1	; set stack as target	
	mov	di, sp					; set target offset
	mov	dx, IAPL_NETWORK_SERVICE_FIELD_ID
	segmov	es, ss, bx	; set up target segment
	clr	bx		; use field ID's only
	mov	cx, IAPL_NETWORK_SERVICE_FIELD_SIZE	
	mov	ax, es:[IAPLDsToken]
	call	DataStoreGetField
EC <	ERROR_C	ERROR_GET_FIELD_SET_CURR_IAPL_SELECTION	>

	mov {byte} bl, ss:[di]	; store network service into bx (used by
				; OpenService call).
	add	sp, IAPL_NETWORK_SERVICE_FIELD_SIZE + 1 ; restore stack

	call	OpenService	; open up the associated access point


exit_set_curr_iap_selection:


	.leave
	ret
SetCurrIAPLSelection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermSetAccessPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given accpt record in buffer, sets CurrentAccessPoint and
loads that accpt record into the buffer, discarding previous record if any.

CALLED BY:	MSG_TERM_SET_ACCESS_POINT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #

		cx	= selection #
RETURN:		
DESTROYED:	everything (irrelevant)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: Sets current access point to selected value (in the
genDynamicList) and loads in the new record, discarding the old access point
record.   This discards the new record, since the only point where an access
point is committed to the buffer is going between 3.5 and 3.6

In addition, it updates the access point reference pointer for the current
IAPL record.

Also checks the status of the access point currently selected. If it is user
created, keeps delete button enabled, otherwise it is grayed out.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/26/96   	Initial version
	eyeh	9/27/96		Discards old AccessPoint info in buffer and 
				loads in new info corresponding to current
				selection.
	eyeh	2/5/97		add support for acc pt refs for IAPL records
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermSetAccessPoint	method dynamic TermClass, 
					MSG_TERM_SET_ACCESS_POINT

	mov	es:[CurrentAccessPoint], cx	; store selection

	mov	ax, es:[AccessPointDsToken]
	call	DataStoreDiscardRecord		; the only permissible error
						; here is to try to discard
						; an empty buffer (ignored).
	jnc	continue_set_access_point
	cmp	ax, DSDE_RECORD_BUFFER_EMPTY
	je	continue_set_access_point
	ERROR	ERROR_DS_DISCARD_RECORD_SET_ACCESS_POINT ; error	

continue_set_access_point:
	mov	ax, es:[AccessPointDsToken]
	clr	dx				; GenDynamicLists apparently
						; cannot handle doubleword
						; sized # of entries.

	call	DataStoreLoadRecordNum		; Commit access point to
						; record buffer.  From now
						; on this cannot be changed
						; until a cancel or commit.
EC <	ERROR_C	ERROR_LOAD_RECORD_SET_ACCESS_POINT	>

	; store record ID
	call	SetIAPLAccPtRef

	call	UpdateNetworkElementFields	; update all fields related
						; to access points in dialog
						; 3.5 (this is where this is
						; being called from).	


	call	GetTerminalInfoAccPt	; get access point information
	call	SetNetEltDelete		; see if record is user created or
					; not.  If so, then it can be
					; deleted (enable button).

	mov	ax, es:[AccessPointDsToken]
	call	DataStoreDiscardRecord		; dispose of record
EC <	ERROR_C	ERROR_DS_DISCARD_RECORD_SET_ACCESS_POINT	>
	
	mov	es:[NewAccPtRecordFlag], INVALID	  ; set false, since
							  ; an existing
							  ; access point has
							  ; been chosen.

exit_set_acc_pt:
	ret


TTermSetAccessPoint	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermSaveAccessPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	commits changes to access point and IAPL datastores

CALLED BY:	MSG_TERM_SAVE_ACCESS_POINT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: calls appropriate routines for saving access point
info.   Then calls up the Connection Setting dialog

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermSaveAccessPoint	method dynamic TermClass, 
					MSG_TERM_SAVE_ACCESS_POINT
	uses	bp
	.enter

	; first check to see if user has entered a connection name or not.
	mov	dx, es	; set up StringBuffer as target
	mov	bp, offset StringBuffer

	mov	bx, handle ConfirmSaveDataIAPLName
	mov	si, offset ConfirmSaveDataIAPLName
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage
	tst	cx	; test result
	jz	save_access_point_name_field_error	; must have name!@

	call	SaveTerminalInfoAccPt	; save terminal information

	mov	bx, segment dgroup
	mov	es, bx

	; sanity
	;mov	ax, es:[IAPLDsToken]
	;call	DataStoreGetRecordCount

	; since DataStoreSaveRecord discards the IAPL and Access Point
	; records from the buffer, reload both.

	; reload the IAPL record.

	clr	cx, dx
	mov {byte} cl, es:[CurrentIAPLSelection]
	mov	ax, es:[IAPLDsToken]
	call	DataStoreLoadRecordNum
EC <	ERROR_C	ERROR_DS_LOAD_RECORD_NUM_SAVE_ACCESS_POINT	>

	; force IAPL list to reupdate
	mov	ax, es:[IAPLDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_DS_GET_RECORD_COUNT_SAVE_ACCESS_POINT	>
	mov	cx, ax			; set up # of records for next call.

	mov	bx, handle ConnectionConfirmAccessPointName
	mov	si, offset ConnectionConfirmAccessPointName
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ObjMessage

	call	UpdateConnectionDialog
	call	ActivateConnectionSetting

	mov	ax, es:[IAPLDsToken]
	call	DataStoreDiscardRecord	; discard record
EC <	ERROR_C	ERROR_DS_DISCARD_RECORD_SAVE_ACCESS_POINT	>	

	.leave
	ret

save_access_point_name_field_error:
	; user didn't enter a name for the IAPL connection.  Bring up
	; warning and return back to confirm save dialog

	mov	bx, handle PleaseEnterconnectionNameString
	mov	bp, offset PleaseEnterconnectionNameString
	call	MemLock		; lock string 
	push	bx		; save handle
	push	es		; store dgroup

	mov	di, ax		; set segment of error string
	mov	es, ax		; set segment (to grab actual offset)
	mov	bp, es:[bp]	; grab actual offset

	; bring up error notification dialog
	mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE \
			or mask CDBF_SYSTEM_MODAL 	; to bring to top
	call	TermUserStandardDialog
	pop	es		; restore dgroup
	pop	bx	
	call	MemUnlock	; unlock string

	; we now return you to your previously viewed programming...
	mov	bx, handle ConfirmSaveDataDialog
	mov	si, offset ConfirmSaveDataDialog
	mov	di, mask MF_CALL	
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	.leave
	ret

TTermSaveAccessPoint	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDataByteItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the bits for a given selection in a given data byte.

CALLED BY:	
PASS:		ax	= selection #
		bx	= code mask
		cx	= code offset
		di	= data byte (word offset to)
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:  a generic routine for setting the bits pertaining to
a specific selection in a data byte.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDataByteItem	proc	near
	uses	ax,bx,cx,dx,di,bp,es
	.enter

	mov	dx, segment dgroup
	mov	es, dx

	mov	dx, ax	; store selection into dx

	; clear the old selection region of the data byte first
	shl	bx, cl	; prepare mask
	not	bx
	
	clr	ah
	mov	al, es:[di] 
	and	ax, bx	; mask out old selection
		

	; prepare new selection
	shl	dx, cl	; shift new selection over to proper offset
	or	ax, dx	; insert new selection into PFKbyte

	mov	es:[di], al	; store new PFkbyte

	.leave
	ret
SetDataByteItem	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermSetComboBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_TERM_SET_COMBO_BOX
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #

		cx = identifier
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/10/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;TTermSetComboBox	method dynamic TermClass, 
;					MSG_TERM_SET_COMBO_BOX
;	uses	ax, cx, dx, bp
;	.enter

;	mov	ax, cx	; set selection
;	clr	ch
	; set offset and mask
;	mov	bx, CT_COMBO_BOX_MASK
;	mov	cl, CT_COMBO_BOX_OFFSET
;	mov	di, offset CTbyte	; offset to data byte

;	call	SetDataByteItem	; set the item


;	.leave
;	ret
;TTermSetComboBox	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermSetMakeCheckBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_TERM_SET_MAKE_CHECK_BOX
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/10/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermSetMakeCheckBox	method dynamic TermClass, 
					MSG_TERM_SET_MAKE_CHECK_BOX
	uses	ax, cx, dx, bp
	.enter

	mov	ax, cx	; set selection
	clr	ch
	; set offset and mask
	mov	bx, BSDM_MAKE_COMBO_BOX_MASK
	mov	cl, BSDM_MAKE_COMBO_BOX_OFFSET
	mov	di, offset BSDMbyte	; offset to data byte

	call	SetDataByteItem	; set the item

	.leave
	ret
TTermSetMakeCheckBox	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTerminalSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets databytes based on protocolbox ui selections

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTerminalSettings	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	
	; set baud 
	mov	bx, handle BaudList
	mov	si, offset BaudList
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage
	mov	di, offset baudIdentifierTable
	mov	cx, ax
	call	GetOrdinalityFromTable
	mov	ax, cx	; set selection
	clr	ch
	; set offset and mask
	mov	bx, BSDM_BAUD_RATE_MASK
	mov	cl, BSDM_BAUD_RATE_OFFSET
	mov	di, offset BSDMbyte	; offset to data byte
	call	SetDataByteItem	; set the item

	; set stop bit 
	mov	bx, handle StopList
	mov	si, offset StopList
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage
	mov	di, offset stopBitsIdentifierTable
	mov	cx, ax
	call	GetOrdinalityFromTable
	mov	ax, cx	; set selection
	clr	ch
	; set offset and mask
	mov	bx, BSDM_STOP_BIT_MASK
	mov	cl, BSDM_STOP_BIT_OFFSET
	mov	di, offset BSDMbyte	; offset to data byte
	call	SetDataByteItem	; set the item

	; set data bit 
	mov	bx, handle DataList
	mov	si, offset DataList
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage
	mov	di, offset dataBitsIdentifierTable
	mov	cx, ax
	call	GetOrdinalityFromTable
	mov	ax, cx	; set selection
	clr	ch
	; set offset and mask
	mov	bx, BSDM_DATA_BIT_MASK
	mov	cl, BSDM_DATA_BIT_OFFSET
	mov	di, offset BSDMbyte	; offset to data byte
	call	SetDataByteItem	; set the item

	; set parity bit 
	mov	bx, handle ParityList
	mov	si, offset ParityList
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage
	mov	di, offset parityBitsIdentifierTable
	mov	cx, ax
	call	GetOrdinalityFromTable
	mov	ax, cx	; set selection
	clr	ch
	; set offset and mask
	mov	bx, PFK_PARITY_BIT_MASK
	mov	cl, PFK_PARITY_BIT_OFFSET
	mov	di, offset PFKbyte	; offset to data byte
	call	SetDataByteItem	; set the item


	; set flow bit 
	mov	bx, handle FlowList
	mov	si, offset FlowList
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjMessage

;	mov	dx, ax	; store result in dx
;	mov	cx, dx	; store copy in cx
;	clr	ax	; default = none (0)	

	; see if it noen is selected.  If so, then go on, since this
	; excludes the others from being selected.
;	cmp	dx, mask FFB_NONE	
;	jnz	check_rest_flow
	
;	jmp	set_pfk_byte_flow_bits	; none selected, go directly to set
					; databyte. 

;check_rest_flow:
;	and	dx, mask SFC_HARDWARE
;	jz	check_soft_flow
;	or	ax, PFK_FLOW_CONTROL_HARDWARE	

;check_soft_flow:
	
;	and	cx, mask SFC_SOFTWARE
;	jz	set_pfk_byte_flow_bits
;	or	ax, PFK_FLOW_CONTROL_SOFTWARE

	; set offset and mask
set_pfk_byte_flow_bits:
	mov	di, offset flowIdentifierTable
	mov	cx, ax
	call	GetOrdinalityFromTable
	mov	ax, cx	; set selection
	clr	ch

	mov	bx, PFK_FLOW_CONTROL_MASK
	mov	cl, PFK_FLOW_CONTROL_OFFSET
	mov	di, offset PFKbyte	; offset to data byte
	call	SetDataByteItem	; set the item


	; set kanji
	mov	bx, handle KanjiFontList
	mov	si, offset KanjiFontList
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage
	mov	di, offset kanjiFontIdentifierTable
	mov	cx, ax
	call	GetOrdinalityFromTable
	mov	ax, cx	; set selection
	clr	ch
	; set offset and mask
	mov	bx, PFK_KANJI_CODE_MASK
	mov	cl, PFK_KANJI_CODE_OFFSET
	mov	di, offset PFKbyte	; offset to data byte
	call	SetDataByteItem	; set the item


	; set combo (history method) box
;	mov	bx, handle ComboBoxList
;	mov	si, offset ComboBoxList
;	mov	di, mask MF_CALL
;	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
;	call	ObjMessage

;	mov	ax, cx	; set selection
;	clr	ch
;	; set offset and mask
;	mov	bx, CT_COMBO_BOX_MASK
;	mov	cl, CT_COMBO_BOX_OFFSET	
;	mov	di, offset CTbyte	; offset to data byte
;	call	SetDataByteItem	; set the item
	


	; set terminal
	mov	bx, handle TerminalList
	mov	si, offset TerminalList
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage
	mov	di, offset terminalTypeIdentifierTable
	mov	cx, ax
	call	GetOrdinalityFromTable
	mov	ax, cx	; set selection
	clr	ch
	; set offset and mask
mov	bx, CT_TERMINAL_MASK
	mov	cl, CT_TERMINAL_OFFSET
	mov	di, offset CTbyte	; offset to data byte
	call	SetDataByteItem	; set the item

	


	.leave
	ret
GetTerminalSettings	endp





if _SCRIPT_VARIABLE
; ----------------------------------------------------------------------
;			Variable Query Handler
; ----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetVariable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given the variable text, returns pointer to text that should
be outputted in its place.

CALLED BY:	DoSend
PASS:		cx:dx	= pointer to variable indicator string (past first
			  '$')

		bp	= length of string (characters)

RETURN:			
	 - proper variable
		cx:dx	= string to output
		bp	= length of this string (characters)
	
	 - improper variable
		cx:dx	= trashed
		bp	= 0
DESTROYED:	see above
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:  Since there are only 3 possible "personalized" items
to send out (ID, password, phone #), only the first character needs to be
recognized.  The ID is indicated in Network by $ID$,  password by
$PASSWORD$, and telephone number by $TELEPHONE$ 

Since connection occurs from Connection Confirm dialog (3.2), grab ID and
password text from that dialog's gentext fields.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/17/96   	Initial version
	eyeh	10/28/96	put into scriptLocal and made into proc call
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetVariable	proc	far
	uses	ax, bx, di, es, ds
	.enter

	mov	bx, segment dgroup
	mov	es, bx


	call	ClearStringBuffer	; use StringBuffer as target.
	
	; check to see if ID
	LocalLoadChar	ax, ID_VAR_STRING_FIRST_CHAR

	mov	ds, cx	; set up pointer to variable string
	mov	di, dx

SBCS <	cmp	ds:[di], al	>	
DBCS <	cmp	ds:[di], ax	>
	jne	check_password_get_var

	; is ID, now output it. 
	mov	si, offset ConnectionConfirmNetworkID
	jmp	get_variable_get_var
	
check_password_get_var:
	; check to see if PASSWORD
	LocalLoadChar	ax, PASSWORD_VAR_STRING_FIRST_CHAR
SBCS <	cmp	ds:[di], al	>	
DBCS <	cmp	ds:[di], ax	>
	jne	check_telephone_num_get_var
	
	; is password, now output it. 
	mov	cx, es	; set target segment
	mov	dx, offset NetworkPassword
	mov	bp, es:[NetworkPasswordLength]
	jmp	exit_get_var	; no need to call ObjMessage

check_telephone_num_get_var:
	; check to see if TELEPHONE
	LocalLoadChar	ax, TELEPHONE_NUM_VAR_STRING_FIRST_CHAR
SBCS <	cmp	ds:[di], al	>	
DBCS <	cmp	ds:[di], ax	>
	jne	not_var_declared_get_var

	; is Telephone#, now output it. 
	mov	si, offset ConnectionConfirmTelephoneNumber

get_variable_get_var:	
	; call to get the string
	mov	dx, segment dgroup
	mov	bp, offset StringBuffer

	mov	bx, handle ConnectionConfirmDialog ; all info in same
						   ; segment
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage
	
	mov	ax, cx	; store length of string (characters) in ax
	; now set up return vars
	mov	cx, es
	mov	dx, bp	; offset to StringBuffer
	mov	bp, ax	; set length

exit_get_var:
	.leave
	ret

not_var_declared_get_var:
	clr	bp	; no string

	jmp	exit_get_var

GetVariable	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDialVariable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given pointer to identifier string, matches it with string
to send out (usually telephone number).

CALLED BY:	DoDial (in scriptLocal.asm)
PASS:		ds	- dgroup
		dx:bp	- pointer to variable name

RETURN:		es:di	- pointer to string to return
		cx	- length of string (chars)

DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:  
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDialVariable	proc	far
	uses	ax,bx,dx,si,bp
	.enter

	; should probably do a variable check here, but since there is only
	; one thing the user would want (in Network) from using a variable
	; in the dial command is the current telephone number, well, return
	; the telephone number.  It's probably cleaner to do a check and
	; all, but hey, path of least resistance.

	; set up StringBuffer as target
	mov	dx, ds
	mov	bp, offset StringBuffer

	; grab telephone number from connection box ui
	mov	bx, handle ConnectionConfirmTelephoneNumber
	mov	si, offset ConnectionConfirmTelephoneNumber
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage

	; point esdi to returned string (in StringBuffer)
	mov	es, dx
	mov	di, bp

	.leave
	ret
GetDialVariable	endp


endif ; SCRIPT_VARIABLE



;--------------------------------------------------------------------------------
;			DUD, REMOVE WHEN FINISHED
;--------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermWriteFileContents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_TERM_WRITE_FILE_CONTENTS
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	11/11/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;captureFileName	wchar	"capture.txt",0

;TTermWriteFileContents	method dynamic TermClass, 
;					MSG_TERM_WRITE_FILE_CONTENTS
;	uses	ax, cx, dx, bp

;	fileHandle	local	word

;	.enter
	
	; --------------------------------------------------
	; Open the capture.txt file
	; --------------------------------------------------
;	mov	ax, SP_DOCUMENT
;	call	FileSetStandardPath
	
;	mov	al, (mask FFAF_RAW) or FILE_ACCESS_R or FILE_DENY_NONE
;	segmov	ds, cs, bx
;	mov	dx, offset captureFileName
;	call	FileOpen
;	mov	fileHandle, ax

	; --------------------------------------------------
	; read bytes and transfer to StringBuffer
	; --------------------------------------------------
;	call	ClearStringBuffer
;	clr	al	; clear flags
;	mov	bx, fileHandle
;	mov	cx, 12
;	segmov	ds, es, dx	
;	mov	dx, offset StringBuffer
;	call	FileRead

	; --------------------------------------------------	
	; Send buffer contents to screen
	; --------------------------------------------------
;	mov	si, offset StringBuffer
;;	call	BufferedSendBuffer	
;	call	SendBuffer

	; --------------------------------------------------
	; Finished, close file
	; --------------------------------------------------
;	clr	al	
;	mov	bx, fileHandle
;	call	FileClose		

;	.leave
;	ret
;TTermWriteFileContents	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTermCheckLogHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_TERM_CHECK_LOG_HISTORY
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	12/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTermCheckLogHistory	method dynamic TermClass, 
					MSG_TERM_CHECK_LOG_HISTORY
	.enter

	cmp	ds:[LogHistoryFlag], VALID
	jne	finish_history_check

begin_log_history:
	; begin log history
	mov	ax, MSG_ASCII_RECV_START
	mov	bx, ds:[termProcHandle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

finish_history_check:

	.leave
	ret
TTermCheckLogHistory	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TToggleKbd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_TERM_TOGGLE_KBD
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	12/11/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TToggleKbd	method dynamic TermClass, 
					MSG_TERM_TOGGLE_KBD

	.enter

	cmp	es:[KBDToggleFlag], KBD_ON
	je	switch_keyboard_off

switch_keyboard_on:
	mov	dx, DOVE_REDUCED_ROW_COUNT
	mov	cx, KBD_ON
	jmp	continue_toggle_kbd

switch_keyboard_off:
	mov	dx, DOVE_ROW_COUNT
	mov	cx, KBD_OFF
	jmp	continue_toggle_kbd

continue_toggle_kbd:
	mov	es:[KBDToggleFlag], cl
	mov	bx, handle screenObject
	mov	si, offset screenObject
	mov	di, mask MF_CALL
	mov	ax, MSG_SCR_SET_WIN_LINES
	call	ObjMessage

	mov	bx, handle TermPrimary
	mov	si, offset TermPrimary
	mov	ax, MSG_GEN_TOGGLE_FLOATING_KBD
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
TToggleKbd	endm


