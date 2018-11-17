COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		doveDs.asm

AUTHOR:		Eric Yeh, Sep 12, 1996

ROUTINES:
	Name			Description
	----			-----------
; ----------------------------------------------------------------------
;
;		Opens appropriate access point datastore
;
; ----------------------------------------------------------------------

OpenService				given the network service #, opens
					the appropriate access point
					datastore, closing the old access
					point datastore 

; ----------------------------------------------------------------------
;
;		Open acc pt with UID.
;
; ----------------------------------------------------------------------

OpenAccPtUID				Opens access point by its UID. Note
					that it is presumed that acc points
					already exist in current datastore.
					If UID = 0, or nonexistent, will
					open 1st acc point in datastore.

; ----------------------------------------------------------------------
;
;		Sets records in their appropriate datastores
;
; ----------------------------------------------------------------------


CreateNewAccPtRecord			creates a new acc point record and
					sets its field values to the default
					values (given by spec). 

CreateNewIAPLRecord			creates new IAPL record in current
					IAPL datastore and instantiates the
					fields to default values. 

SetIAPLRecords				sets the record fields of the IAPL
					record entry to match the text
					entries in Network Element dialog
					(3.5)
 
; ----------------------------------------------------------------------
;
;		Data Store Field Access Routines
;
; ----------------------------------------------------------------------

GetIAPLFieldString			given existing record buffer, field
					ID, and a buffer to write to,loads
					that field into the buffer from IAPL
					ds file

GetAccessFieldString			given an existing record buffer and
					buffer to write to, and a record
					existing in buffer, counts the
					length of the field and stores the
					string into the buffer, and then
					discards the record. 

GetIAPLFieldAndCheckLengthList		given item#, field ID, and a buffer
					to write to, loads that field into
					the buffer from IAPL ds file  

GetAccessFieldAndCheckLengthList	given the index number of the access
					point name to look up and buffer to
					write to, loads and locks the
					record, counts the length of it and
					stores the string into the buffer,
					and then discards the record.


SetIAPLAccPtRef				sets the Access Point Reference ID
					field of the currently loaded IAPL
					record. 
   

; ----------------------------------------------------------------------
;			
;			Opens datastores used by network
;
; ----------------------------------------------------------------------

OpenAccessPointDataStore		opens access pt database

OpenIAPLDataStore			opens info of access pt database.

; ----------------------------------------------------------------------
;
;			Get and Set info from datastores
;
; ----------------------------------------------------------------------

GetTerminalInfoAccPt			Gets the terminal information from
					the current access point selected. 

SaveTerminalInfoAccPt			saves terminal information of access
					point to datastore 

; ----------------------------------------------------------------------
;
;			Creation Routines
;
; ----------------------------------------------------------------------

NewIAPLEntry				creates new IAPL entry.  If >20,
					exits with error 


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/12/96   	Initial revision


DESCRIPTION:
		
	routines that call DataStore in Dove

	$Id: doveDs.asm,v 1.1 97/04/04 16:55:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





; /* **************************************************
;		Strings used in this module
; ************************************************** */
IAPLFileName			wchar	"IAPL List",0
NetworkIDFieldString		wchar	"Network ID",0
NetworkPasswordFieldString	wchar	"Network Password",0
NetworkServiceFieldString	wchar	"Network Service",0
AccessPointUIDFieldString	wchar	"Access Pt ID",0
IAPLNameFieldString		wchar	"Name",0			
IAPLOrderFieldString		wchar	"Order",0	; since don't want
							; them sorted at all!

BSDMbyteFieldString		wchar	"BSDMbyte",0
PFKbyteFieldString		wchar	"PFKbyte",0
CTbyteFieldString		wchar	"CTbyte",0
UserCreatedString		wchar	"UserCreated",0
TelephoneNumberFieldString	wchar	"Telephone Number",0
AccessPointFieldString		wchar	"Access Point",0

; file names for access points datastores
PCVANAPFileName		wchar	"PCVANAPFile",0
NiftyServeAPFileName	wchar	"NiftyServeAPFile",0
ASCIINETAPFileName	wchar	"ASCIINETAPFile",0
PeopleAPFileName	wchar	"PeopleAPFile",0
OtherAPFileName		wchar	"OtherAPFile",0

TestEmptyString		wchar	" ",0

AccessPtFileOffsetTable	word	offset PCVANAPFileName, offset NiftyServeAPFileName, offset ASCIINETAPFileName, offset PeopleAPFileName, offset OtherAPFileName

; ----------------------------------------------------------------------
;
;		Opens appropriate access point datastore
;
; ----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenService
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: given the network service #, opens the appropriate access point
datastore, closing the old access point datastore.	

CALLED BY:	
PASS:		bx = service # (0 based)
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	gets offset to access point file name string and opens it.	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenService	proc	near
	uses	ax,bx,cx,bp
	.enter

	mov	cx, segment dgroup	; set up segment
	mov	es, cx
	
	mov {byte} al, es:[AccPtValidFlag]
	cmp {byte} al, ACC_PT_INVALID
	

;	mov	ax, es:[AccessPointDsToken]
;	cmp	ax, es:[IAPLDsToken]	; if AccessPointDsToken ==
					; IAPLDsToken, then we know that no
					; access points have been loaded up
					; yet (since IAPL ds loaded first,
					; and both vars are initialy 0).

	jz	continue_open_service

;	call	DataStoreUnlockRecord
;	call	DataStoreDiscardRecord
;EC <	ERROR_C	ERROR_DS_DISCARD_RECORD_OPEN_SERVICE	>

	mov	ax, es:[AccessPointDsToken]
	call	DataStoreClose		; close current AccessPoint, if any
EC <	ERROR_C	ERROR_DS_CLOSE_OPEN_SERVICE	>
	; now open the corresponding access point
continue_open_service:
	shl	bx	; word offset
	mov	dx, cs:[AccessPtFileOffsetTable][bx]
	mov	cx, cs	; set up target segment
	call	OpenAccessPointDataStore	; open the datastore

	.leave
	ret
OpenService	endp


; ----------------------------------------------------------------------
;
;		Open acc pt with UID.
;
; ----------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenAccPtUID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens access point by its UID.  If UID = 0, or nonexistent,
will then open the 1st access point in the datastore.

CALLED BY:	
PASS:		es = dgroup
		dx.cx = UID to open
		AccessPointDsToken = valid access point datastore token

RETURN:		- valid access point record in buffer
		carry set if error,
			dx.cx - preserved
		carry clear if no error, 
			dx.cx - record number
		
DESTROYED:	dx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	NOTE the following are presumed:
		- an access point datastore already exists	
		- the access point datastore has at least one record in it.
		- buffer is clear

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	eyeh    	2/20/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenAccPtUID	proc	near
	uses	ax,bx,si,di,bp
	.enter
		

	; first check to see if UID is 0.  If so, load in 1st record
	; since is dword, have to test both portions
	tst	dx
	jnz	OACPTUID_load_record	
	tst	cx
	jz	OACPTUID_load_first_record	; UID = 0, load 1st record

OACPTUID_load_record:
	; attempt to load the record.  If fails, load 1st record
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreLoadRecord		; datastore call
	mov	es:[CurrentAccessPoint], cx	; set current access point
						; on list
	jnc	OACPTUID_exit			; success, exit

OACPTUID_load_first_record:
						; if fail, try loading in
						; 1st record.
	mov	ax, es:[AccessPointDsToken]
	clr	dx, cx				; load in record #0 (1st
						; record)
	mov	es:[CurrentAccessPoint], cx	; set to 0
	call	DataStoreLoadRecordNum		

	jnc	OACPTUID_exit			; success - leave
EC <	ERROR_C	ERROR_OPEN_ACC_POINT_UID_LOAD_RECORD_NUM	>

	
OACPTUID_exit:
	
	.leave
	ret
OpenAccPtUID	endp


; ----------------------------------------------------------------------
;
;		Sets records in their appropriate datastores
;
; ----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNewAccPtRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	creates a new acc point record and sets its field values to the
default values (given by spec). 

CALLED BY:	
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: call DataStoreNewRecord with the currently opened
datastore session, then sets each field to its default value.  Also loads
this record into the access point record buffer.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNewAccPtRecord	proc	near
	uses	bx,cx,dx,di,bp
	.enter

	; set up dgroup pointer
	mov	bx, segment dgroup
	mov	ds, bx

	; create new record
	mov	ax, ds:[AccessPointDsToken]
	call	DataStoreNewRecord
EC <	ERROR_C	ERROR_NEW_RECORD_INIT_ACC_PT_RECORD	>

	; Now instantiate the fields

	; set up a null character string
	sub	sp, 2	; double word or not, keep even to keep swat happy
	mov	di, sp	; set di to sp	

	mov {byte}	ss:[di], NULL_CHAR	; NULL char portion of arg
if DBCS_PCGEOS
	mov {byte} ss:[di+1], NULL_CHAR_HIGH   ; put in high word of null
endif
	mov	cx, 0			; 2 characters (blank & null)

	segmov	es, ss, bx		; set up target segment to stack

	clr	bx			; use field ID's to access
	; set the access point field
	mov	ax, ds:[AccessPointDsToken]
	mov	dl, ACCESS_POINT_LIST_ACCESS_POINT_FIELD_ID
	clr	bx			; use field ID only
	call	DataStoreSetField
EC <	ERROR_C	ERROR_SET_FIELD_INIT_ACC_PT_RECORD	>

	; set up the telephone number field
	mov	ax, ds:[AccessPointDsToken]
	mov	dl, ACCESS_POINT_LIST_TELEPHONE_NUMBER_FIELD_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_SET_FIELD_INIT_ACC_PT_RECORD	>
	
	; set up the ACCESS_POINT_LIST_BSDM_BYTE_FIELD_ID field
	mov	ax, ds:[AccessPointDsToken]
	mov	dl, ACCESS_POINT_LIST_TELEPHONE_NUMBER_FIELD_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_SET_FIELD_INIT_ACC_PT_RECORD	>
	
	; bsdm byte
	mov	ax, ds:[AccessPointDsToken]
	mov	ss:[di], BSDM_DEFAULT
	mov	cx, 1				; one byte
	mov	dl, ACCESS_POINT_LIST_BSDM_BYTE_FIELD_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_SET_FIELD_INIT_ACC_PT_RECORD	>
	
	; pfk byte
	mov	ax, ds:[AccessPointDsToken]
	mov {byte}	ss:[di], PFK_DEFAULT
	mov	dl, ACCESS_POINT_LIST_PFK_BYTE_FIELD_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_SET_FIELD_INIT_ACC_PT_RECORD	>
	
	; ct byte
	mov	ax, ds:[AccessPointDsToken]
	mov {byte}	ss:[di], CT_DEFAULT	
	mov	dl, ACCESS_POINT_LIST_CT_BYTE_FIELD_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_SET_FIELD_INIT_ACC_PT_RECORD	>

	; user created
	mov	ax, ds:[AccessPointDsToken]
	mov {byte}	ss:[di], USER_CREATED
	mov	dl, ACCESS_POINT_LIST_USER_CREATED_FIELD_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_SET_FIELD_INIT_ACC_PT_RECORD	>
	
	
exit_initialize_acc_pt_record:
	add	sp, 2			; restore stack

	.leave
	ret

CreateNewAccPtRecord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CreateNewIAPLRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	creates new IAPL record in current IAPL datastore and
instantiates the fields to default values.

CALLED BY:	
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	create a new IAPL record in current datastore session with
DataStoreCreate, then instantiate each field by calling DataSetField with
the default values.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNewIAPLRecord	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; set up ds to point to dgroup
	mov	bx, segment dgroup
	mov	ds, bx	

	; first flush current record from buffer
	mov	ax, ds:[IAPLDsToken]
	call	DataStoreDiscardRecord
;EC <	ERROR_C	ERROR_DISCARD_RECORD_INIT_IAPL_RECORD	> 

	; create new record in IAPL datastore session
	mov	ax, ds:[IAPLDsToken]
	call	DataStoreNewRecord
EC <	ERROR_C	ERROR_NEW_RECORD_INIT_IAPL_RECORD	>

	sub	sp, 8		; use stack to pass arguments
	mov	di, sp		; use di to reference stack args

	; set up null character on stack

	mov {byte}	ss:[di], BLANK_CHAR
if DBCS_PCGEOS
	mov {byte}	ss:[di+1], BLANK_CHAR_HIGH	
	mov {byte}	ss:[di+2], BLANK_CHAR
	mov {byte}	ss:[di+3], BLANK_CHAR_HIGH
	mov {byte}	ss:[di+4], NULL_CHAR
	mov {byte}	ss:[di+5], NULL_CHAR_HIGH
else
	mov {byte}	ss:[di+1], BLANK_CHAR
	mov {byte}	ss:[di+2], NULL_CHAR
endif
	mov	cx, 2		; set size of arg to 2 characters

	segmov	es, ss, bx		; set up target segment to stack

	; set up name field
	mov	ax, ds:[IAPLDsToken]
	mov	dl, IAPL_NAME_FIELD_ID
	clr	bx	; use field id's
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_INIT_IAPL_RECORD	>

	; set up network id field
	mov	ax, ds:[IAPLDsToken]
	mov	dl, IAPL_NETWORK_ID_FIELD_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_INIT_IAPL_RECORD	>

	; set up network password field
	mov	ax, ds:[IAPLDsToken]
	mov	dl, IAPL_NETWORK_PASSWORD_FIELD_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_INIT_IAPL_RECORD	>

	; set up network service field
	mov {byte}	ss:[di], DEFAULT_IAPL_NETWORK_SELECTION
	mov	ax, ds:[IAPLDsToken]
	mov	dl, IAPL_NETWORK_SERVICE_FIELD_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_INIT_IAPL_RECORD	>

	
	; set up access point unique ID
	mov {word}	ss:[di], 0	; clear fields
	mov {word}	ss:[di+2], 0
	mov {word}	ss:[di+4], 0	
	mov {word}	ss:[di+6], 0	


	mov	ax, ds:[IAPLDsToken]
	mov	dl, IAPL_NETWORK_ACC_PT_REF_ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_INIT_IAPL_RECORD	>

exit_init_iapl_record:
	add	sp, 8		; restore stack

	.leave
	ret


CreateNewIAPLRecord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNetworkRecords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the record fields of the datastores to match the
text entries in Network Element dialog (3.5).

CALLED BY:	
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: gets ptrs from each text field, if modified, and sets
the corresponding field in the IAPL record to that text.
		
use MSG_GEN_TEXT_IS_MODIFIED to check if entry is modified.  If so, grab
the text using MSG_VIS_TEXT_GET_ALL_PTR into StringBuffer.  Or if possible,
access the GTXI_text to get the pointer and use the pointer instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNetworkRecords	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	
	; set up segment
	mov	bx, segment dgroup
	mov	es, bx	

	; IAPL fields: Network ID, Network Password
	
	; check to see if NetworkID is modified, if so, commit change to
	; datastore
	mov	bx, handle NetworkElementNetworkID
	mov	si, offset NetworkElementNetworkID
	mov	di, mask MF_CALL
	
	mov	ax, MSG_GEN_TEXT_IS_MODIFIED
	call	ObjMessage
	jnc	check_network_password_set_iapl_records

	; carry set, so modified
	mov	dx, es		; set up target parameters
	mov	bp, offset StringBuffer	; put data into StringBuffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage	

if DBCS_PCGEOS
	shl	cx	; db chars
endif

	; now set the field

	clr	bx		; use field ID
	mov	dx, IAPL_NETWORK_ID_FIELD_ID
	mov	di, bp		; point to StringBuffer
	mov	ax, es:[IAPLDsToken]
	call	DataStoreSetField
EC <	ERROR_C ERROR_SET_FIELD_SET_NETWORK_RECORDS	 >

check_network_password_set_iapl_records:
	; check to see if Network Password is modified, if so, commit change to
	; datastore
	mov	bx, handle NetworkElementNetworkPassword
	mov	si, offset NetworkElementNetworkPassword
	mov	di, mask MF_CALL
	
	mov	ax, MSG_GEN_TEXT_IS_MODIFIED
	call	ObjMessage
	jnc	check_accpt_set_accpt_records

	; carry set, so modified
	mov	dx, es		; set up target parameters
	mov	bp, offset StringBuffer	; put data into StringBuffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage	

if DBCS_PCGEOS
	shl	cx	; db chars
endif

	; now set the field

	clr	bx		; use field ID
	mov	dx, IAPL_NETWORK_PASSWORD_FIELD_ID
	mov	di, bp		; point to StringBuffer
	mov	ax, es:[IAPLDsToken]
	call	DataStoreSetField
EC <	ERROR_C ERROR_SET_FIELD_SET_NETWORK_RECORDS	 >


check_accpt_set_accpt_records:
	; Access point fields: Access Point, Telephone Number

	; check to see if Access Point is modified, if so, commit change to
	; datastore
	mov	bx, handle NetworkElementAccessPoint
	mov	si, offset NetworkElementAccessPoint
;	mov	di, mask MF_CALL
	
;	mov	ax, MSG_GEN_TEXT_IS_MODIFIED
;	call	ObjMessage
;	jnc	check_accpt_set_telephone_records

	; carry set, so modified
	; force write to buffer, since new record may or may not have been
	; created. 
	mov	dx, es		; set up target parameters
	mov	bp, offset StringBuffer	; put data into StringBuffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage	

if DBCS_PCGEOS
	shl	cx	; db chars
endif

	; now set the field
	mov	ax, es:[AccessPointDsToken]
	clr	bx		; use field ID
	mov	dx, ACCESS_POINT_LIST_ACCESS_POINT_FIELD_ID
	mov	di, bp		; point to StringBuffer

	call	DataStoreSetField
EC <	ERROR_C ERROR_SET_FIELD_SET_NETWORK_RECORDS	 >

check_accpt_set_telephone_records:
	; check to see if Telephone Number is modified, if so, commit change
	; to datastore
	mov	bx, handle NetworkElementTelephoneNumber
	mov	si, offset NetworkElementTelephoneNumber
	mov	di, mask MF_CALL
	
;	mov	ax, MSG_GEN_TEXT_IS_MODIFIED
;	call	ObjMessage
;	jnc	exit_set_network_records

	; carry set, so modified
	; force write to buffer
	mov	dx, es		; set up target parameters
	mov	bp, offset StringBuffer	; put data into StringBuffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage	

if DBCS_PCGEOS
	shl	cx	; db chars
endif

	; now set the field
	mov	ax, es:[AccessPointDsToken]
	clr	bx		; use field ID
	mov	dx, ACCESS_POINT_LIST_TELEPHONE_NUMBER_FIELD_ID
	mov	di, bp		; point to StringBuffer

	call	DataStoreSetField
EC <	ERROR_C ERROR_SET_FIELD_SET_NETWORK_RECORDS	 >

exit_set_network_records:
	.leave
	ret

SetNetworkRecords	endp


if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IntegrityCheck
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
	eyeh	10/10/96    	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IntegrityCheck	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	mov	bx, segment dgroup
	mov	es, bx

one:
	call	ClearStringBuffer
	mov	ax, es:[IAPLDsToken]
	clr	bx
	mov	di, offset StringBuffer
	mov	cx, 32
	mov	dx, IAPL_NAME_FIELD_ID
	call	DataStoreGetField

two:
	call	ClearStringBuffer
	mov	ax, es:[IAPLDsToken]
	clr	bx
	mov	di, offset StringBuffer
	mov	cx, 32
	mov	dx, IAPL_NETWORK_ID_FIELD_ID
	call	DataStoreGetField

three:
	call	ClearStringBuffer
	mov	ax, es:[IAPLDsToken]
	clr	bx
	mov	di, offset StringBuffer
	mov	cx, 32
	mov	dx, IAPL_NETWORK_PASSWORD_FIELD_ID
	call	DataStoreGetField

four:
	call	ClearStringBuffer
	mov	ax, es:[IAPLDsToken]
	clr	bx
	mov	di, offset StringBuffer
	mov	cx, 32
	mov	dx, IAPL_NETWORK_SERVICE_FIELD_ID
	call	DataStoreGetField

five:
	call	ClearStringBuffer
	mov	ax, es:[AccessPointDsToken]
	clr	bx
	mov	di, offset StringBuffer
	mov	cx, 32
	mov	dx, ACCESS_POINT_LIST_ACCESS_POINT_FIELD_ID
	call	DataStoreGetField

six:
	call	ClearStringBuffer
	mov	ax, es:[AccessPointDsToken]
	clr	bx
	mov	di, offset StringBuffer
	mov	cx, 32
	mov	dx, ACCESS_POINT_LIST_TELEPHONE_NUMBER_FIELD_ID
	call	DataStoreGetField

seven:
	call	ClearStringBuffer
	mov	ax, es:[AccessPointDsToken]
	clr	bx
	mov	di, offset StringBuffer
	mov	cx, 32
	mov	dx, ACCESS_POINT_LIST_BSDM_BYTE_FIELD_ID
	call	DataStoreGetField

eight:
	call	ClearStringBuffer
	mov	ax, es:[AccessPointDsToken]
	clr	bx
	mov	di, offset StringBuffer
	mov	cx, 32
	mov	dx, ACCESS_POINT_LIST_PFK_BYTE_FIELD_ID
	call	DataStoreGetField

nine:
	call	ClearStringBuffer
	mov	ax, es:[AccessPointDsToken]
	clr	bx
	mov	di, offset StringBuffer
	mov	cx, 32
	mov	dx, ACCESS_POINT_LIST_CT_BYTE_FIELD_ID
	call	DataStoreGetField


	.leave
	ret
IntegrityCheck	endp

endif ; ERROR_CHECK




; ----------------------------------------------------------------------
;
;		Data Store Field Access Routines
;
; ----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetIAPLFieldString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given existing buffer, field ID, and a buffer to write to,
loads that field into the buffer from IAPL ds file

CALLED BY:	TTermUpdateIAPLNameList
PASS:		dl	= field ID to look up
		es:di	= buffer to write to
RETURN:		es:di	= buffer (written into)
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
Given existing record in buffer and field to look up, checks to see how long
(in bytes) it is, and the copies it over to the StringBuffer.

	Note: adds null character to the end of the string

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/20/96    	Initial version
	CEY	9/16/96		buffer version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetIAPLFieldString	proc	near
	uses	ax, bx, cx, dx, es, ds, di, bp
	.enter
	
	mov	bx, segment dgroup
	mov	ds, bx

	mov	ax, ds:[IAPLDsToken]	

	; now load the text field into our StringBuffer
	clr	bx				; use field ids to access
	
	call	DataStoreGetFieldSize		; first get size of string

	jc	update_IAPL_list_error_get_field_size

if DBCS_PCGEOS
	shl	ax	; db char size
endif
	
	mov	cx, ax				; grab size of string
						; (bytes)
	mov	ax, ds:[IAPLDsToken]	; load token
	call	DataStoreGetField		; grab the field
	jc	update_IAPL_list_error_get_field

	; now place null character at the end
	add	di, cx
	mov {byte}	es:[di], NULL_CHAR

if DBCS_PCGEOS
	mov {byte} ds:[di+1], 0	; top word of db null char
endif

	sub	di, cx	

exit_get_IAPL_service_field:
	.leave
	ret

update_IAPL_list_error_get_field:
	ERROR	ERROR_UPDATE_IAPL_LIST_GET_FIELD
	jmp	exit_get_IAPL_service_field

update_IAPL_list_error_get_field_size:
	ERROR	ERROR_UPDATE_IAPL_LIST_GET_FIELD_SIZE
	jmp	exit_get_IAPL_service_field

GetIAPLFieldString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAccessFieldString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given the index number of the access point name to look
up and buffer to write to, and a record existing in buffer, counts the
length of the field and stores the string into the buffer, and then discards
the record.

CALLED BY:	TTermUpdateNetworkNameList, UpdateNetworkElementFields
PASS:		dx	= field id # to in record to look up
		es:di	= buffer to write to

RETURN:		es:di	= buffer (written into)
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Note: adds null character to the end of the string

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/20/96    	Initial version
	CEY	9/16/96		buffer version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAccessFieldString	proc	near
	uses	ax, bx, cx, dx, ds, bp
	.enter
	mov	ax, segment dgroup
	mov	ds, ax	

	mov	ax, ds:[AccessPointDsToken]	

	; now load the text field into our StringBuffer
	clr	bx				; use field ids to access

	call	DataStoreGetFieldSize		; first get size of string

	jc	update_access_point_error_get_field_size
	
if DBCS_PCGEOS
	shl	ax	; db char size
endif
	
	mov	cx, ax				; grab size of string
						; (bytes)
	mov	ax, ds:[AccessPointDsToken]	; load token

	call	DataStoreGetField		; grab the field
	jc	update_access_point_error_get_field

	; now place null character at the end
	add	di, cx
	mov {byte}	ds:[di], NULL_CHAR

if DBCS_PCGEOS
	mov {byte} ds:[di+1], 0	; top word of db null char
endif
	sub	di, cx	

exit_get_access_point_field:
	.leave
	ret

update_access_point_error_get_field:
	ERROR	ERROR_GET_ACCESS_FIELD_STRING_GET_FIELD
	jmp	exit_get_access_point_field

update_access_point_error_get_field_size:
	ERROR	ERROR_GET_ACCESS_FIELD_STRING_GET_FIELD_SIZE
	jmp	exit_get_access_point_field


GetAccessFieldString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetIAPLFieldAndCheckLengthList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: given item#, field ID, and a buffer to write to, loads that
field into the buffer from IAPL ds file

CALLED BY:	TTermUpdateIAPLNameList
PASS:		cx	= index # of the record to look up
		dl	= field ID to look up
		es:di	= buffer to write to
RETURN:		es:di	= buffer (written into)
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	primarily done so that bp will be retained by the previous call, so
that TTermUpdateNetworkNameList can be used generically, instead of creating
one for each individual gen dynamic list.  

	This opens the record, checks to see how long (in bytes) it is, and
the copies it over to the StringBuffer.

	Note: adds null character to the end of the string

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetIAPLFieldAndCheckLengthList	proc	near
	uses	ax, bx, cx, dx, es, ds, di, bp
	.enter
	
	push	dx	; preserve ID field		

	mov	bx, segment dgroup
	mov	ds, bx

	; now load the appropriate record
	mov	ax, ds:[IAPLDsToken]	
	clr	dx				; cx is the record #	
	call	DataStoreLoadRecordNum		; load the record
	pop	dx				; restore field ID

EC <	ERROR_C	ERROR_LOAD_RECORD_GET_IAPL_FIELD_LIST	>


	; now load the text field into our StringBuffer
	clr	bx				; use field ids to access
	
	mov	ax, ds:[IAPLDsToken]
	call	DataStoreGetFieldSize		; first get size of string
EC <	ERROR_C	ERROR_GET_FIELD_SIZE_GET_IAPL_FIELD_LIST	>
	
if DBCS_PCGEOS
	shl	ax	; db char size
endif
	
	mov	cx, ax				; grab size of string
						; (bytes)
	mov	ax, ds:[IAPLDsToken]	; load token

	call	DataStoreGetField		; grab the field
EC <	ERROR_C	ERROR_GET_FIELD_GET_IAPL_FIELD_LIST	>

	; now place null character at the end
	add	di, cx
	mov {byte}	es:[di], NULL_CHAR
if DBCS_PCGEOS
	mov {byte} ds:[di+1], 0	; top word of db null char
endif
	sub	di, cx	

get_IAPL_flush_current_record_list:
	; call	DataStoreUnlockRecord	;unlock the record
	call	DataStoreDiscardRecord	;flush record

exit_get_IAPL_service_field_list:
	.leave
	ret

GetIAPLFieldAndCheckLengthList	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAccessFieldAndCheckLengthList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given the index number of the access point name to look
up and buffer to write to, loads and locks the record, counts the length of
it and stores the string into the buffer, and then discards the record. 

CALLED BY:	TTermUpdateNetworkNameList, UpdateNetworkElementFields
PASS:		cx	= index # of the record to look up
		dx	= field id # to in record to look up
		es:di	= buffer to write to

RETURN:		es:di	= buffer (written into)
DESTROYED:	nothing 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	primarily done so that bp will be retained by the previous call, so
that TTermUpdateAccessPointList can be used generically, instead of creating
one for each individual gen dynamic list.  

	This opens the record, checks to see how long (in bytes) it is, and
the copies it over to the StringBuffer.

	Note: adds null character to the end of the string

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAccessFieldAndCheckLengthList	proc	near
	uses	ax, bx, cx, dx, ds, bp
	.enter
	mov	ax, segment dgroup
	mov	ds, ax	

	; now load the appropriate record, presumign that es = dgroup
	mov	ax, ds:[AccessPointDsToken]	
	push	dx, ax	; store field id # and token
	clr	dx	; not that many records
	call	DataStoreLoadRecordNum		; load the record
	pop	dx, ax	; restore field id #
EC <	ERROR_C	ERROR_LOAD_RECORD_GET_ACCESS_POINT_LIST	>

	; now load the text field into our StringBuffer
	clr	bx				; use field ids to access

	mov	ax, ds:[AccessPointDsToken]
	call	DataStoreGetFieldSize		; first get size of string

EC <	ERROR_C	ERROR_GET_FIELD_SIZE_GET_ACCESS_POINT_LIST	>

if DBCS_PCGEOS
	shl	ax	; db char size
endif
	
	mov	cx, ax				; grab size of string
						; (bytes)
	mov	ax, ds:[AccessPointDsToken]	; load token

	call	DataStoreGetField		; grab the field
EC <	ERROR_C	ERROR_GET_FIELD_GET_ACCESS_POINT_LIST	>

	; now place null character at the end
	add	di, cx
	mov {byte}	ds:[di], NULL_CHAR
if DBCS_PCGEOS
	mov {byte} ds:[di+1], 0	; top word of db null char
endif
	sub	di, cx	

get_access_point_flush_current_record_list:
	; call	DataStoreUnlockRecord
	call	DataStoreDiscardRecord	;flush record
EC <	ERROR_C	ERROR_DISCARD_RECORD_GET_ACCESS_POINT_LIST	> 

exit_get_access_point_field_list:
	.leave
	ret

GetAccessFieldAndCheckLengthList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetIAPLAccPtRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the Access Point Reference ID field of the currently
loaded IAPL record.

CALLED BY:	
PASS:		dx.cx = new record ID to set
		es = dgroup
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	NOTE:  a valid IAPL record must be loaded in the record buffer
before this is called, otherwise an error will occur.		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	eyeh    	2/ 6/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetIAPLAccPtRef	proc	near
	uses	ax,bx,si,di, bp
	.enter

	mov	ax, es:[IAPLDsToken]	; load IAPL datastore's token

	sub	sp, IAPL_NETWORK_ACC_PT_REF_FIELD_SIZE	; set aside space on
							; stack to store data
	mov	di, sp
	mov	ss:[di], cx	; loword
	mov	ss:[di+2], dx	; hiword
	call	DataStoreSetField
	add	sp, IAPL_NETWORK_ACC_PT_REF_FIELD_SIZE	; restore stack

	.leave
	ret
SetIAPLAccPtRef	endp




; ----------------------------------------------------------------------
;			
;			Opens datastores used by network
;
; ----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenAccessPointDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	opens access pt database with the given name

CALLED BY:	
PASS:		cx:dx	= string name of access point datastore to open
RETURN:		carry clear = no error,
		carry set   = error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenAccessPointDataStore	proc	near
	uses	ax,bx,cx,dx,si,di,bp, es
	.enter

	clc	; everything okay (initially)

	; open the network service file
	mov	es, cx	; set offset to title string
	mov	di, dx
	
	clr	cx, dx	; null object

open_acc_pt_datastore:
	clr	al	; cleared flags for now

	call	DataStoreOpen	
	jc	create_access_point_data_error

assign_token_open_access_point:
	; store ds session token
	mov	cx,segment dgroup
	mov	es, cx
	mov	es:[AccessPointDsToken], ax
	
exit_open_access_point:
	mov	es:[AccPtValidFlag], ACC_PT_VALID	; Valid acc point
							; session loaded
	.leave
	ret

create_access_point_data_error:
	; check to see if it is a datastore not exist error
	cmp	ax, DSE_DATASTORE_NOT_FOUND
	jz	open_access_point_create_file

	cmp	ax, DSE_DATASTORE_ALREADY_OPEN
	jz	exit_open_access_point

	stc	; set carry
EC <	ERROR_C	ERROR_DS_OPEN_OPEN_ACC_PT_DATASTORE	>
	jmp	exit_open_access_point

open_access_point_create_file:
	; not found, so create the new access point
	mov	cx, es
	mov	dx, di	; set offsets to strings
	call	CreateAccessPointDataStore
	; now reattempt to open it.  If error, dump out here
	clr	cx, dx, ax
	call	DataStoreOpen
EC <	ERROR_C	ERROR_DS_OPEN_OPEN_ACC_PT_DATASTORE	>
	jmp	assign_token_open_access_point

OpenAccessPointDataStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenIAPLDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	opens info of access pt database.

CALLED BY:	
PASS:		none
RETURN:		none
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CEY	8/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenIAPLDataStore	proc	near
	uses	ax,cx,dx,si,di,bp,es
	.enter

	; open the network service file
	segmov	es, cs
	mov	di, offset IAPLFileName	
	
	clr	cx, dx	; null object
	clr	al	; cleared flags for now

	call	DataStoreOpen
	jnc	continue_open_iapl_datastore

	; only "allowable" error here is trying to open a datastore that's
	; already open.  In that case just ignore and continue using opened
	; datastore.   If the datastore is not found, then call the creation
	; routine. 
	cmp	ax, DSE_DATASTORE_ALREADY_OPEN
	jz	exit_open_IAPL_service
	cmp	ax, DSE_DATASTORE_NOT_FOUND
	jz	create_iapl_datastore
EC <	ERROR	ERROR_DATA_STORE_OPEN_OPEN_IAPL_DATA_STORE	>

create_iapl_datastore:
	; create new iapl datastore
	call	CreateIAPLDataStore
	segmov	es, cs, ax
	mov	di, offset IAPLFileName	
	clr	cx, dx, ax
	call	DataStoreOpen	; attempt to reopen it
EC <	ERROR_C	ERROR_DATA_STORE_OPEN_OPEN_IAPL_DATA_STORE	>

continue_open_iapl_datastore:
	; store ds session token
	mov	cx,segment dgroup
	mov	es, cx
	mov	es:[IAPLDsToken], ax

exit_open_IAPL_service:
	.leave
	ret
OpenIAPLDataStore	endp


; ----------------------------------------------------------------------
;
;			Get and Set info from datastores
;
; ----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTerminalInfoAccPt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the terminal information from the current access point
selected.

CALLED BY:	
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	grabs information from the saved access point	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTerminalInfoAccPt	proc	near
	uses	ax,bx,cx,dx,di,es,bp
	.enter

	mov	bx, segment dgroup	; set up segment
	mov	es, bx

	mov	ax, es:[AccessPointDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_DS_GET_RECORD_COUNT_GET_TERMINAL_INFO	>
	tst	ax
	jz	set_default_values	; no access points, so just set to
					; default values.

	mov	cx, es:[CurrentAccessPoint]


	; lock the record
	mov	ax, es:[AccessPointDsToken]
	call	DataStoreLockRecord
EC <	ERROR_C	ERROR_DS_LOCK_RECORD_GET_TERMINAL_INFO	>
	; bsdm byte
	mov	ax, es:[AccessPointDsToken]
	clr	bx	; use field id 
	mov	cx, 1	; information is one byte big
	mov	dl, ACCESS_POINT_LIST_BSDM_BYTE_FIELD_ID
	mov	di, offset BSDMbyte
	call	DataStoreGetField
EC <	ERROR_C	ERROR_DS_GET_FIELD_GET_TERMINAL_INFO	>

	; pfk  byte
	clr	bx	; use field id 
	mov	cx, 1	; information is one byte big
	mov	dl, ACCESS_POINT_LIST_PFK_BYTE_FIELD_ID
	mov	di, offset PFKbyte
	call	DataStoreGetField
EC <	ERROR_C	ERROR_DS_GET_FIELD_GET_TERMINAL_INFO	>

	; bsdm byte
	clr	bx	; use field id 
	mov	cx, 1	; information is one byte big
	mov	dl, ACCESS_POINT_LIST_CT_BYTE_FIELD_ID
	mov	di, offset CTbyte

	call	DataStoreGetField
EC <	ERROR_C	ERROR_DS_GET_FIELD_GET_TERMINAL_INFO	>

	mov	ax, es:[AccessPointDsToken]
	call	DataStoreUnlockRecord

exit_get_terminal_info: 

	.leave
	ret

set_default_values:
	mov	es:[BSDMbyte], BSDM_DEFAULT
	mov	es:[PFKbyte], PFK_DEFAULT
	mov	es:[CTbyte], CT_DEFAULT
	.leave
	ret

GetTerminalInfoAccPt	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveTerminalInfoAccPt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	saves terminal information of access point to datastore.

CALLED BY:	
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: saves the current state variables (BSDMbyte, PFKbyte,
CTbyte) in the record buffer for the current access point to the datastore.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveTerminalInfoAccPt	proc	near
	uses	ax,bx,cx,dx,di,bp
	.enter

	; set up dgroup segment 
	mov	bx, segment dgroup
	mov	ds, bx

	; now commit these to the record buffer (not saved yet).
	sub	sp, 2	; word align stack for a moment
	mov	si, sp

	segmov	es, ss	; set up target segment as stack
	; save bsdm byte
	mov	cl, ds:[BSDMbyte]
	mov	ss:[si], cl
	mov	ax, ds:[AccessPointDsToken]
	clr	bx
	mov	dl, ACCESS_POINT_LIST_BSDM_BYTE_FIELD_ID
	mov	cx, 1
	mov	di, sp
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_GET_TERMINAL_SETTINGS	>

	; save PFKbyte
	mov	ax, ds:[AccessPointDsToken]
	mov	cl, ds:[PFKbyte]
	mov	ss:[si], cl
	mov	dl, ACCESS_POINT_LIST_PFK_BYTE_FIELD_ID
	mov	cx, 1
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_GET_TERMINAL_SETTINGS	>

	; save CTbyte
	mov	ax, ds:[AccessPointDsToken]
	mov	cl, ds:[CTbyte]
	mov	ss:[si], cl
	mov	dl, ACCESS_POINT_LIST_CT_BYTE_FIELD_ID
	mov	cx, 1
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_GET_TERMINAL_SETTINGS	>

	; Now commit changes to datastore, using defaults index
	mov	ax, ds:[AccessPointDsToken]
	clr	dx, cx, bp	; use default, no callback, no data.
	call	DataStoreSaveRecord
EC <	ERROR_C	ERROR_DS_SAVE_RECORD_SAVE_TERMINAL_INFO_ACC_PT	>
	
	;set current access point to point to this selected record.

	mov	ds:[CurrentAccessPoint], ax

my_debug_flag:
	; save current access point's UID (bx.cx = acc pt ID)
	sub	sp, IAPL_NETWORK_ACC_PT_REF_FIELD_SIZE	; use stack 
	mov	di, sp	; set offset to stack

	mov	ss:[di], cx	; store dx.cx = acc pt ID
	mov	ss:[di+2], bx

	mov	cx, IAPL_NETWORK_ACC_PT_REF_FIELD_SIZE	; set target size
	segmov	es, ss,bx	; segment to stack
	mov	ax, ds:[IAPLDsToken]
	clr	bx	; use fieldID
	mov	dl, IAPL_NETWORK_ACC_PT_REF_ID	; field ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_GET_TERMINAL_SETTINGS	>

	add	sp, IAPL_NETWORK_ACC_PT_REF_FIELD_SIZE	; restore stack

	; set datastore field for IAPL name
	mov	dx, ds	; segment of StringBuffer (dgroup)
	mov	bp, offset StringBuffer

	mov	bx, handle ConfirmSaveDataIAPLName
	mov	si, offset ConfirmSaveDataIAPLName
	mov	di, mask MF_CALL	
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessage

DBCS <	shl	cx	> ; byte size <-- # chars
	mov	es, dx	; segment to StringBuffer
	mov	di, bp	; offset to StringBuffer
	mov	ax, ds:[IAPLDsToken]
	clr	bx	; use fieldID
	mov	dl, IAPL_NAME_FIELD_ID	; field ID
	call	DataStoreSetField
EC <	ERROR_C	ERROR_DS_SET_FIELD_GET_TERMINAL_SETTINGS	>
	
	; now commit changes to IAPL database
	mov	ax, ds:[IAPLDsToken]
	clr	dx, cx, bp	; use default, no callback, no data

	call	DataStoreSaveRecord
EC <	ERROR_C	ERROR_DS_SAVE_RECORD_SAVE_TERMINAL_INFO_ACC_PT	>

	; set current IAPL selection to point to this record, so that when
	; return to connection confirm dialog this information is available
	cmp	ds:[NewIAPLRecordFlag], NEW_IAPL_RECORD
	jnz	set_selection_save_term_info

new_record_save_term_info:
	mov	ax, ds:[IAPLDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_DS_GET_RECORD_COUNT_SAVE_TERMINAL_INFO_ACC_PT	>
	dec	ax	; 0 based
set_selection_save_term_info:
	mov {byte} ds:[CurrentIAPLSelection], al

exit_save_term_info:
	add	sp, 2	; restore stack
	.leave
	ret

SaveTerminalInfoAccPt	endp




; ----------------------------------------------------------------------
;		
;			Create DataStore Routines
;
; ----------------------------------------------------------------------




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateIAPLDataStore
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
DudFieldString wchar	"duh",0

CreateIAPLDataStore	proc	near

	keylist	local	word

	uses	bx, si, di, bp
	.enter

	; allocate space on stack for keylist
	; Name of Connection Account (primary key)
	sub	sp, size FieldDescriptor + 1; +1= keep swat happy
	mov	di, sp			; set to use offset
	mov	ss:[di].FD_type, DSFT_STRING	
	mov	ss:[di].FD_category, FC_NONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset DudFieldString	; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ss:[keylist], di	; store offset to keylist

	
	; Now set up parameters for creating datastore
	sub	sp, size DataStoreCreateParams + 1; +1 = keep swat happy
	mov	di, sp			; set to use offset

	; set datastore file name 
	mov	si, offset IAPLFileName
	movdw	ss:[di].DSCP_name, cssi	
	
	; set flags
	mov	ss:[di].DSCP_flags, 0

	; no keylist
	;movdw	ss:[di].DSCP_keyList, 0
	
	; due to some strange reason, datastores without any key fields are
	; dying when saved, so make a dud field.


	; set ptr to key list
	mov	cx, ss:[keylist]	 	
	movdw	ss:[di].DSCP_keyList, sscx 
	movdw	ss:[di].DSCP_keyList, 1

	; set keycount
	mov	ss:[di].DSCP_keyCount, 0 ; no primary keys, only order of
					 ; creation 
	movdw	ss:[di].DSCP_notifObject, 0	; no notify object
	mov	ss:[di].DSCP_openFlags, 0	

	
	; Now call datastore create
	segmov	ds, ss, bx
	mov	si, di	; set offset
	call	DataStoreCreate
	add	sp, size DataStoreCreateParams + 1	; +1 = keep swat
							; happy 
	add	sp, size FieldDescriptor + 1		; +1= keep swat
							; happy 
	jc	IAPL_ds_create_error
	
	; now to flesh out the fields
	mov	bx, segment dgroup
	mov	ds, bx
	mov	ds:[IAPLDsToken], ax
	call	FleshOutIAPLDataStore

IAPL_ds_create_exit:
	.leave
	ret


IAPL_ds_create_error:
	; error handler here eep!
	jmp	IAPL_ds_create_exit

CreateIAPLDataStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAccessPointDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: passing in a ptr to the string indicating the name of the
title, this creates an access point database using that title.

CALLED BY:	
PASS:		cx:dx	= fptr to title string
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAccessPointDataStore	proc	near

	keylist	local	word

	uses	bx, cx, dx, si, di, es, bp
	.enter
	push	cx, dx	; store string name
	
	; allocate space on stack for keylist
	; Name of Access Point (primary key)
	sub	sp, size FieldDescriptor + 1; +1= keep swat happy
	mov	di, sp			; set to use offset
	mov	ss:[di].FD_type, DSFT_STRING	
	mov	ss:[di].FD_category, FC_NONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset AccessPointFieldString	; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ss:[keylist], di	; store offset to keylist

	
	; Now set up parameters for creating datastore
	sub	sp, size DataStoreCreateParams +1; keep swat happy
	mov	di, sp	;set to use offset

	; set datastore file name 
	movdw	ss:[di].DSCP_name, cxdx
	
	; set flags
	mov	ss:[di].DSCP_flags, 0

	; set ptr to key list
	mov	cx, ss:[keylist]	 	
	movdw	ss:[di].DSCP_keyList, sscx 
	
	; set keycount
	mov	ss:[di].DSCP_keyCount, 1 ; 1 primary key for now
	movdw	ss:[di].DSCP_notifObject, 0	; no notify object
	mov	ss:[di].DSCP_openFlags, 0	

	
	; Now call datastore create
	segmov	ds, ss, bx
	mov	si, di	; set offset
	call	DataStoreCreate
	add	sp, size FieldDescriptor +1	; restore stack
	add	sp, size DataStoreCreateParams +1
	jc	acc_pt_ds_create_error

	; now to flesh out fields
	pop	cx, dx	; restore string name

	mov	bx, segment dgroup
	mov	es, bx

	mov	es:[AccessPointDsToken], ax	; store token for field flesher
	call	FleshOutAccPtDataStore
acc_pt_ds_create_exit:
	.leave
	ret


acc_pt_ds_create_error:
	; error handler here eep!
	jmp	acc_pt_ds_create_exit

CreateAccessPointDataStore	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FleshOutIAPLDataStore
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
FleshOutIAPLDataStore	proc	near
	uses	bx, di, si, bp
	.enter

	mov	bx, segment dgroup
	mov	ds, bx

	; Info of Acc Pt Name
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_STRING	
	mov	ss:[di].FD_category, FC_NAME
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset IAPLNameFieldString  ; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ax, ds:[IAPLDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
	add	sp, size FieldDescriptor + 1	; restore stack
	jc	IAPL_create_field_error


	; Network ID
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_STRING	
	mov	ss:[di].FD_category, FC_NONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset NetworkIDFieldString ; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ax, ds:[IAPLDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
	add	sp, size FieldDescriptor + 1	; restore stack
	jc	IAPL_create_field_error


	; Network Password
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_STRING	
	mov	ss:[di].FD_category, FC_NONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset NetworkPasswordFieldString ; name of field
	movdw	ss:[di].FD_name, cssi
	
	mov	ax, ds:[IAPLDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
	add	sp, size FieldDescriptor + 1	; restore stack
	jc	IAPL_create_field_error

	; Network Service
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_SHORT
	mov	ss:[di].FD_category, FC_NONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset NetworkServiceFieldString ; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ax, ds:[IAPLDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
	add	sp, size FieldDescriptor + 1	; restore stack
	jc	IAPL_create_field_error


	; UID of access point to piont to
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_LONG	; dword size RecordID
	mov	ss:[di].FD_category, FC_NONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset AccessPointUIDFieldString ; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ax, ds:[IAPLDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
	add	sp, size FieldDescriptor + 1	; restore stack
	jc	IAPL_create_field_error


IAPL_create_field_exit:
	mov	ax, ds:[IAPLDsToken]
	call	DataStoreClose

	.leave
	ret

IAPL_create_field_error:
	; error handler here
	jmp IAPL_create_field_exit

FleshOutIAPLDataStore	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FleshOutAccPtDataStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: given the title of an access point datastore, instantiates fields
used. 

CALLED BY:	
PASS:		cx:dx = fptr to title string	
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FleshOutAccPtDataStore	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	;call	OpenAccessPointDataStore	
	;jc	exit_acc_pt_create_field
	mov	bx, segment dgroup
	mov	ds, bx

	; Telephone Number
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_STRING
	mov	ss:[di].FD_category, FC_TELEPHONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset  TelephoneNumberFieldString ; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ax, ds:[AccessPointDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
	add	sp, size FieldDescriptor + 1	; restore stack
	jc	acc_pt_create_field_error

	; BSDMbyte
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_SHORT
	mov	ss:[di].FD_category, FC_TELEPHONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset BSDMbyteFieldString	; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ax, ds:[AccessPointDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
	add	sp, size FieldDescriptor + 1	; restore stack
	jc	acc_pt_create_field_error

	; PFKbyte
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_SHORT
	mov	ss:[di].FD_category, FC_TELEPHONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset PFKbyteFieldString	; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ax, ds:[AccessPointDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
	add	sp, size FieldDescriptor + 1	; restore stack
	jc	acc_pt_create_field_error

	; CTbyteFieldString
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_SHORT
	mov	ss:[di].FD_category, FC_TELEPHONE
	mov	ss:[di].FD_flags, 0		; ascending order
	mov	si, offset CTbyteFieldString	; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ax, ds:[AccessPointDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
	add	sp, size FieldDescriptor + 1	; restore stack
	jc	acc_pt_create_field_error

; User Created field
	sub	sp, size FieldDescriptor + 1
	mov	di, sp				; set to use offset
	mov	ss:[di].FD_type, DSFT_SHORT
	mov	ss:[di].FD_category, FC_NONE
	mov	ss:[di].FD_flags, 0		; no flags
	mov	si, offset UserCreatedString	; name of field
	movdw	ss:[di].FD_name, cssi

	mov	ax, ds:[AccessPointDsToken]
	segmov	es, ss, bx
	call	DataStoreAddField
	add	sp, size FieldDescriptor + 1	; restore stack
	jc	acc_pt_create_field_error


exit_acc_pt_create_field:
	mov	ax, ds:[AccessPointDsToken]
	call	DataStoreClose

	.leave
	ret

acc_pt_create_field_error:
	jmp	exit_acc_pt_create_field

FleshOutAccPtDataStore	endp



; ----------------------------------------------------------------------
;
;			Creation Routines
;
; ----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NewIAPLEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	creates new IAPL entry.  If >20, exits with error

CALLED BY:	
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		C clear	= okay, no error
		C set	= error occurred
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY: discards current record (if any) and then creates new
record entry.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	9/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewIAPLEntry	proc	near
	uses	ax, cx, dx, bp
	.enter
	mov	ax, segment dgroup
	mov	es, ax

	mov	ax, es:[IAPLDsToken]
	call	DataStoreGetRecordCount
EC <	ERROR_C	ERROR_DS_GET_RECORD_COUNT_NEW_IAPL_ENTRY	>
	
	; if too many entries don't enter
	cmp	ax, MAX_IAPL_COUNT
	jae	error_max_IAPL_entry

	mov	ax, es:[IAPLDsToken]
	call	CreateNewIAPLRecord	; create & instantiate
	clc				; no error

exit_new_IAPL_entry:
	.leave
	ret

error_max_IAPL_entry:
	mov	bx, handle MaxConnectionErrorStr
	mov	bp, offset MaxConnectionErrorStr
	call	MemLock			; lock string
	push	bx, es			; save handle & dgroup
	mov	di, ax			; set segment of error string
	mov	es, ax			; set segment (to get actual offset)
	mov	bp, es:[bp]		; get actual offset
	mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE \
			or mask CDBF_SYSTEM_MODAL 	; raise dialog
	call	TermUserStandardDialog
	pop	bx, es			; restore registers
	call	MemUnlock		; unlock string

	stc		; error occurred
	jmp exit_new_IAPL_entry


NewIAPLEntry	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyDudCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To handle the fact that datastore got changed under my
feet. This is used to sort the IAPL by order of creation, which somehow
seems to f**k up whenever sorting is done on datastores with no keylist
fields. 

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eyeh	10/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MyDudCallBack	proc	near
	mov	ax, -1	; always item1 < item2 (new record insert)
	ret
MyDudCallBack	endp




