COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS GeoComm/Terminal
MODULE:		Main
FILE:		mainConnection.asm

AUTHOR:		Eric Weber, May 22, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT TermClearFocus		Clear the focus in a dialog

    INT TermUpdateFromAccessPoint
				Load data from access point database

    INT TermLoadConnectionText	Load settings text object from database

    INT TermLoadConnectionItem	Load settings GenItemGroup object from
				database

    INT TermLoadConnectionAccPnt
				Load internet access point to UI

    INT TermSaveFocus		Save the object which has the focus

    INT TermSaveConnectionText	Save settings text object to database

    INT TermDataBitsChanged	If data bits is 8, set parity to none and
				disable. Else, enable parity setting.

    INT TermSaveConnectionAccPnt
				Save internet access point ID

    INT TermTelnetCreateErrToErrorString
				Convert a TelnetCreateErr to correct
				ErrorString to report to user

    INT TermMakeConnectionInit	Init variables and other objects before
				making terminal connection.

    INT TermResetForConnect	Reset terminal screen, clearing screen
				first, if needed.  (Telnet: Also reset
				disconnection indicator dialog text.)

    INT QuickDial		Dial the phone number

    INT InitiateConnectionIndicator
				Initiate the connection indicator

    INT InitiateConnectionIndicatorMakeStatusText
				Construct the initial status text of
				connection indicator

    INT InitiateConnectionIndicatorMakeDescText
				Construct the description text of
				connection indicator

    INT DestroyConnectionIndicator
				Destroy connection indicator

    INT SendTextObjStrings	Send the text in a text obj text and a CR
				char to serial line

    INT TermMakeConnectionExit	common clean up code for TermMakeConnection

    INT TermDoConnectionEnum	Enumerate an operation on a group of
				connection objects

    INT TermShouldWaitForECI	Should we wait for ECI_CALL_RELEASE?

    EXT TermValidatePhone	Validate a phone number

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/22/95   	Initial revision
	simon	6/14/95		Use more Access Point properties

DESCRIPTION:
	Handle the ConnectionSettingsDialog
		

	$Id: mainConnection.asm,v 1.1 97/04/04 16:55:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _ACCESS_POINT

;============================================================================
; 			Tables
;============================================================================

;
; To ensure we can use "GetResourceHandleNS" once for all these objects
;
if 	_TELNET
CheckHack <(segment ConnectionNameText eq segment ConnectionDestHostText)>

else
CheckHack <(segment ConnectionNameText eq segment ConnectionPhoneText) AND \
	   (segment ConnectionPhoneText eq segment ConnectionInitText) AND \
	   (segment ConnectionInitText eq segment ConnectionDataChoices) AND \
	   (segment ConnectionDataChoices eq segment ConnectionStopChoices) AND \
	   (segment ConnectionStopChoices eq segment ConnectionParityChoices) AND \
	   (segment ConnectionParityChoices eq segment ConnectionLocalChoices) AND \
	   (segment ConnectionLocalChoices eq segment ConnectionBSChoices)>
endif	; _TELNET

;
; Think carefully about what happens in TermInitForIncoming before changing
; any of these tables, please.
;

;
; A list of connections related objects to be updated with access
; point database.
;
ConnectionObjTable	nptr \
	offset ConnectionNameText,
if	_TELNET
	offset ConnectionDestHostText,
else
	offset ConnectionPhoneText,
	offset ConnectionInitText,
	offset ConnectionDataChoices,
	offset ConnectionStopChoices,
	offset ConnectionParityChoices,
	offset ConnectionLocalChoices,
endif 	; _TELNET
	offset ConnectionBSChoices

if 	_TELNET
NUM_TEXT_SETTINGS	equ	2
NUM_ITEM_SETTINGS	equ	1
else
NUM_TEXT_SETTINGS	equ	3
NUM_ITEM_SETTINGS	equ	5

;
; These are the number of settings to skip when setting incoming call
; serial
; params.
;
NUM_ITEM_SETTINGS_TO_SKIP_FOR_INCOMING_CALL   equ     3

endif	; _TELNET

;
; A list of connection setting GenItemGroup default selections
;
if	_TELNET

ConnectionItemDefaultSelectionTable	word \
	DEFAULT_BS_SELECTION

else

ConnectionItemDefaultSelectionTable	word \
	DEFAULT_DATA_BIT_SELECTION,
	DEFAULT_STOP_BIT_SELECTION,
	DEFAULT_PARITY_SELECTION,
	DEFAULT_LOCAL_ECHO_SELECTION,
	DEFAULT_BS_SELECTION
endif	; _TELNET

;
; A list of routines to update internal variables from access point
; database.
;
if	_TELNET

CheckHack	<segment SetOutputBackspaceKey eq segment Main>	

else

CheckHack	<segment TermAdjustFormat1 eq segment Main>
CheckHack	<segment TermAdjustFormat2 eq segment TermAdjustFormat1>
CheckHack	<segment TermAdjustFormat3 eq segment TermAdjustFormat2>
CheckHack	<segment TermSetDuplex eq segment TermAdjustFormat3>
CheckHack	<segment SetOutputBackspaceKey eq segment TermSetDuplex>

endif 	; _TELNET

if 	_TELNET

ConnectionUpdateRoutineTable	nptr \
	offset	SetOutputBackspaceKey

else

ConnectionUpdateRoutineTable	nptr \
	offset TermAdjustFormat1,
	offset TermAdjustFormat2,
	offset TermAdjustFormat3,
	offset TermSetDuplex,
	offset SetOutputBackspaceKey

endif	; _TELNET

if	not _TELNET

;
; Define the serial format entries for ConnectionAPSPTable to make sure they
; are contiguous.
;
DefSerialConnectionAPSPTableEntry	macro	apspEntry
SERIAL_ENTRY_COUNTER=SERIAL_ENTRY_COUNTER+1
.assert ((apspEntry eq APSP_DATA_BITS) or (apspEntry eq APSP_STOP_BITS) or \
	(apspEntry eq APSP_PARITY)), \
	<DefSerialConnectionAPSPTableEntry: Invalid access point entry type>
.assert (SERIAL_ENTRY_COUNTER le NUM_ITEM_SETTINGS_TO_SKIP_FOR_INCOMING_CALL),
	<DefSerialConnectionAPSPTableEntry: Too many entries>

		AccessPointStandardProperty	apspEntry

.assert (($-ConnectionAPSPTableSerialSettings) eq \
	 (SERIAL_ENTRY_COUNTER * (size AccessPointStandardProperty))), \
	<DefSerialConnectionAPSPTableEntry: serial settings not contiguous>

endm

endif	; !_TELNET

;
; Define the text entries of the table. Make sure they are contiguous.
;
DefTextConnectionAPSPTableEntry		macro	apspEntry
TEXT_ENTRY_COUNTER=TEXT_ENTRY_COUNTER+1

if	_TELNET

.assert ((apspEntry eq APSP_NAME) or (apspEntry eq APSP_HOSTNAME)), \
	<DefTextConnectionAPSPTableEntry: Invalid access point entry type>

else

.assert ((apspEntry eq APSP_NAME) or (apspEntry eq APSP_PHONE) or \
	 (apspEntry eq APSP_MODEM_INIT)), \
	<DefTextConnectionAPSPTableEntry: Invalid access point entry type>

endif	; _TELNET

.assert (TEXT_ENTRY_COUNTER le NUM_TEXT_SETTINGS), \
	<DefTextConnectionAPSPTableEntry: Too many entries>

		AccessPointStandardProperty	apspEntry

.assert (($-ConnectionAPSPTable) eq \
	 (TEXT_ENTRY_COUNTER * (size AccessPointStandardProperty))), \
	<DefTextConnectionAPSPTableEntry: text settings not contiguous>
endm

;
; Counters for items defined in ConnectionAPSPTable
;		
TEXT_ENTRY_COUNTER=0
NTELT <SERIAL_ENTRY_COUNTER=0						>

;
; A list of AccessPointStandardProperty for our use. The text entries should
; always cluster at the beginning of the list, followed by GenItem lists. The
; text entries and GenItem lists are contiguous for each group. The order is
; important and there are assertions to make sure the order is in place.
;
ConnectionAPSPTable	label	AccessPointStandardProperty
DefTextConnectionAPSPTableEntry		APSP_NAME

if _TELNET

DefTextConnectionAPSPTableEntry		APSP_HOSTNAME

else

DefTextConnectionAPSPTableEntry		APSP_PHONE
DefTextConnectionAPSPTableEntry		APSP_MODEM_INIT

ConnectionAPSPTableSerialSettings	label	AccessPointStandardProperty
DefSerialConnectionAPSPTableEntry	APSP_DATA_BITS
DefSerialConnectionAPSPTableEntry	APSP_STOP_BITS
DefSerialConnectionAPSPTableEntry	APSP_PARITY

	AccessPointStandardProperty	APSP_DUPLEX
endif ; _TELNET
	AccessPointStandardProperty	APSP_BS

if	not _TELNET
.assert (SERIAL_ENTRY_COUNTER eq NUM_ITEM_SETTINGS_TO_SKIP_FOR_INCOMING_CALL),\
	<Not enough entries defined by DefSerialConnectionAPSPTableEntry>
endif	; !_TELNET

.assert (TEXT_ENTRY_COUNTER eq NUM_TEXT_SETTINGS), \
	<Not enough entries defined by DefTextConnectionAPSPTableEntry>

if	_VSER

ConnectionAPSPTableEnd	label	byte		; denote end of
						; ConnectionAPSPTable 

ITEM_APSP_TABLE_BASE            equ     (offset ConnectionAPSPTable + NUM_TEXT_SETTINGS * size AccessPointStandardProperty)
ITEM_APSP_TABLE_END		equ	offset ConnectionAPSPTableEnd

endif	; _VSER
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermEditConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Edit a connection

CALLED BY:	MSG_TERM_EDIT_CONNECTION
PASS:		ds	= dgroup
		cx	= id to edit
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermEditConnection	method dynamic TermClass, 
					MSG_TERM_EDIT_CONNECTION
		uses	ax, cx, dx, bp
		.enter
	;
	; Load data from Access Point database
	;
		call	TermUpdateFromAccessPoint
	;
	; forget any existing focus in the dialog
	;
		GetResourceHandleNS ConnectionSettingsDialog, bx
		mov	si, offset ConnectionSettingsDialog
		call	TermClearFocus
	;
	; initiate the dialog
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage
		
		.leave
		ret
TermEditConnection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermClearFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the focus in a dialog

CALLED BY:	(INTERNAL) TermEditConnection
PASS:		^lbx:si	- dialog object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	may invalidate stored segments

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermClearFocus	proc	near
		uses	ax, bx, cx, dx, bp, si, di
		.enter
	;
	; get the current focus under the dialog
	;
		mov	ax, MSG_META_GET_FOCUS_EXCL
		mov	di, mask MF_CALL
		call	ObjMessage		; ^lcx:dx = current focus
		jcxz	done
	;
	; make it not the focus
	;
		pushdw	bxsi
		movdw	bxsi, cxdx
		mov	ax, MSG_META_RELEASE_FOCUS_EXCL
		mov	di, mask MF_CALL
		call	ObjMessage
		popdw	bxsi
done:
		.leave
		ret
TermClearFocus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermUpdateFromAccessPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load data from access point database

CALLED BY:	(INTERNAL) TermEditConnection, TermMakeConnectionInit
PASS:		cx	= access point ID
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Set up params;
	Load string fields;
	Load GenItemGroup fields;

	Since there are many UI objects and access point properties to
	handle, we arrange the data as tables to deal with.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/15/95    	Initial version
	jwu	4/22/96		Add backspace setting for Telnet

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermUpdateFromAccessPoint	proc	near
		uses	ax, bx, si, dx, bp
		.enter
EC <		Assert_dgroup	ds					>
	;
	; set up common parameters
	;
		mov	ds:[settingsConnection], cx
		mov	ax,cx
		GetResourceHandleNS ConnectionSettingsContent, bx
		CheckHack <segment ConnectionSettingsContent eq \
			   segment ConnectionNameText>
		mov	si, offset ConnectionObjTable
						; si <- index to
						; ConnectionObjTable 
		mov	di, offset ConnectionAPSPTable
						; di <- index to
						; ConnectionAPSPTable 
	;
	; load string fields
	;
		mov	cx, NUM_TEXT_SETTINGS
		mov	bp, offset TermLoadConnectionText
		call	TermDoConnectionEnum	; cx destroyed
						; si <- next
						; ConnectionObjTable entry 
						; di <- next
						; ConnectionAPSPTable entry 
if	_TELNET
	;
	; Load internet access point from file
	;
		call	TermLoadConnectionAccPnt
endif	; _TELNET

	;
	; load item fields
	;
		CheckHack <segment TermLoadConnectionItem eq \
			segment ConnectionUpdateRoutineTable>
		mov	bp, offset ConnectionUpdateRoutineTable
						; bp <- index to
						; ConnectionUpdateRoutineTable
		mov	cx, NUM_ITEM_SETTINGS 
		CheckHack <segment TermLoadConnectionItem eq \
			segment ConnectionItemDefaultSelectionTable>
		mov	bx, offset ConnectionItemDefaultSelectionTable
enumLoop:
	;
	; ^hBX <- UI obj block
	;
		push	si, di, bp, bx
		mov	si, cs:[si]		; ^lbx:si <-optr to UI obj
		mov	dx, cs:[di]		; dx <-
						; AccessPointStandardProperty
		mov	di, cs:[bp]		; di <- nptr of routine in
						; ConnectionUpdateRoutineTable
EC <		Assert_nptr	di, cs					>
		mov	bp, cs:[bx]		; bp <- default GenItem
						; selection 
		GetResourceHandleNS ConnectionSettingsContent, bx
		call	TermLoadConnectionItem
		pop	si, di, bp, bx		; restore indices
		add	di, 2			; update table index
		add	si, 2			; update table index
		add	bp, 2			; update table index
		add	bx, 2			; update table index
		loop	enumLoop
				
		.leave
		ret
TermUpdateFromAccessPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermLoadConnectionText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load settings text object from database

CALLED BY:	(INTERNAL)
PASS:		^lbx:si	- text object
		dx	- AccessPointStandardProperty
		ax	- access point ID
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get string property;
	if (got property) {
		Fill in the string in UI text object with property got;
		Free up the block;
	} else {
		Empty string in UI text object;
	} 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermLoadConnectionText	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; fetch text value in a block
	;
		push	bx
		clr	cx				; use standard string
		clr	bp				; allocate block
		call	AccessPointGetStringProperty	; ^hbx=text, cx=size
		mov	dx,bx
		pop	bx
		jc	clear
	;
	; send it to text object and set cursor at start
	;
		push	dx				
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_BLOCK
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; free text block
	;
		pop	bx				; bx = text block
		call	MemFree
done:
		.leave
		ret
clear:
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	done

TermLoadConnectionText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermLoadConnectionItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load settings GenItemGroup object from database

CALLED BY:	(INTERNAL) TermUpdateFromAccessPoint
PASS:		^lbx:si	= GenItemGroup object to update
		dx	= AccessPointStandardProperty
		ax	= access point ID
		bp	= default selection if not found from Access Point
			database
		ds	= dgroup
		di	= nptr to function to call to update internal
			variable.

			The function must take:
				ds = dgroup
				cx = bits to adjust
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get integer property from access point;
	if (no property) {
		property = default property;
	}
	Set the property in GenItemGroup;
	Call routine passed in to update internal status;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermLoadConnectionItem	proc	near
		uses	ax, bx, cx, dx, di, si, bp
		.enter
EC <		Assert_dgroup	ds					>
EC <		Assert_nptr	di, cs					>
	;
	; Get the data from access point
	;
		clr	cx			; use standard string
		call	AccessPointGetIntegerProperty
						; carry set if error
						; ax <- value of property
		mov_tr	cx, ax			; cx <- selection
		jnc	gotProperty		; jmp if no error
		mov	cx, bp			; cx <- default selection

gotProperty:
	;
	; Set the GenItemGroup
	;
		push	di, cx
		clr	dx			; determinate
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjMessage		; ax,cx,dx,bp,di destroyed
		pop	di, cx			; di <- nptr to routine
	;
	; Call the function to update internal variables. 
	;
		call	di
		
		.leave
		ret		
TermLoadConnectionItem	endp

if	_TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermLoadConnectionAccPnt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load internet access point to UI

CALLED BY:	(INTERNAL)
PASS:		ax	= access point ID
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	9/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermLoadConnectionAccPnt	proc	near
		uses	ax, bx, cx, dx, si, di
		.enter
EC <		Assert_dgroup	ds					>
		clr	cx		; use standard string
		mov	dx, APSP_INTERNET_ACCPNT
		call	AccessPointGetIntegerProperty
					; ax <- internet access point selection
					; carry set if error
		jc	noPrevAccPnt    ; don't set if no predefined value
	;
	; Update access point here. We could update access point controller
	; and then later on get current selection from it. However, we may
	; run into the problem that the controller has not been brought up to
	; UI and thus not built. Then we cannot set the selection here and
	; will not get any selection later.
	;
		mov	ds:[remoteExtAddr].APESACA_accessPoint, ax
		mov_tr	cx, ax		; cx <- selection
	;
	; Set the selection in internet access controller
	;
		GetResourceHandleNS	ConnectionInternetAccessControl, bx
		mov	si, offset ConnectionInternetAccessControl
		mov	di, mask MF_CALL
		mov	ax, MSG_ACCESS_POINT_CONTROL_SET_SELECTION
		call	ObjMessage	; di destroyed
					; carry set if not in list
		jmp	done
noPrevAccPnt:
		mov	ds:[remoteExtAddr].APESACA_accessPoint, \
                        ACCESS_POINT_INVALID_ID
	
done:
		.leave
		ret
TermLoadConnectionAccPnt	endp

endif	; _TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSettingsContentGenNavigateToNextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate and save, then continue if everything is ok

CALLED BY:	MSG_GEN_NAVIGATE_TO_NEXT_FIELD
		MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
		MSG_GEN_GUP_INTERACTION_COMMAND

PASS:		*ds:si	= TermSettingsContentClass object
		es 	= segment of TermSettingsContentClass
		ax	= message #
		cx	= InteractionCommand (M_G_G_I_C only)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSettingsContentGenNavigateToNextField	method dynamic TermSettingsContentClass, 
					MSG_GEN_NAVIGATE_TO_NEXT_FIELD,
					MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD,
					MSG_GEN_GUP_INTERACTION_COMMAND
	;
	; in the case of M_G_G_I_C, we only care about IC_DISMISS
	;
		cmp	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		jne	validate
		cmp	cx, IC_DISMISS
		jne	goSuper
if	_TELNET
	;
	; the access point will not have been updted unless the
	; user changed it, so get its value now
	;
		push	ax, cx, si, es
		mov	si, offset ConnectionInternetAccessControl
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_SELECTION
		call	ObjCallInstanceNoLock		; ax = selection
	;
	; save the value
	;
		mov	bp, ax				; value to write
		clr	cx				; using APSP
		mov	dx, APSP_INTERNET_ACCPNT	; field to modify
		mov	bx, handle dgroup
		call	MemDerefES
		mov	ax, es:[settingsConnection]	; point to modify
		call	AccessPointSetIntegerProperty
		pop	ax, cx, si, es		
endif	; _TELNET
	
	;
	; if there is invalid data, abort the navigation
	;
validate:
		call	TermSaveFocus
		jc	done
	;
	; otherwise let the superclass carry out the navigation
	;
goSuper:
		mov	di, offset TermSettingsContentClass
		call	ObjCallSuperNoLock
done:
		ret
TermSettingsContentGenNavigateToNextField	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSaveFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the object which has the focus

CALLED BY:	(INTERNAL) TermSettingsContentGenNavigateToNextField
PASS:		*ds:si - content
RETURN:		carry set to abort current operation
		carry clear if OK to continue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSaveFocus	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; get the current focus
	;
		mov	ax, MSG_META_GET_FOCUS_EXCL	; ^lcx:dx = focus
		call	ObjCallInstanceNoLock
	;
	; if it's not in this segment, disregard
	;
		cmp	cx, ds:[LMBH_handle]
		clc
		jne	done
	;
	; is it dirty?
	;
		mov	ax, dx
		call	ObjGetFlags
		test	al, mask OCF_DIRTY		; clear carry
		jz	done
	;
	; is it a text setting?
	;
		mov	si, dx
		mov	cx, NUM_TEXT_SETTINGS
		mov	di, offset ConnectionObjTable
top:
		cmp	si, cs:[di]
		je	found
		add	di, size lptr
		loop	top
		clc
		jmp	done
	;
	; get the APSP
	;
found:
		sub	di, offset ConnectionObjTable
		add	di, offset ConnectionAPSPTable
		mov	dx, cs:[di]
	;
	; get the access point
	;
		mov	bx, handle dgroup
		call	MemDerefES
		mov	ax, es:[settingsConnection]
	;
	; validate phone number
	;
if not _TELNET
		cmp	dx, APSP_PHONE
		jne	save
		call	TermValidatePhone
		jc	done
save:
endif
	;
	; save it
	;
		call	TermSaveConnectionText
		jc	done
	;
	; mark it clean
	;
		mov	ax, si
		mov	bh, mask OCF_DIRTY
		clr	bl
		call	ObjSetFlags
		clc
done:		
		.leave
		ret
TermSaveFocus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSaveConnectionText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save settings text object to database

CALLED BY:	(INTERNAL) TermSaveFocus
PASS:		*ds:si	- text object
		dx	- AccessPointStandardProperty
		ax	- access point ID
RETURN:		nothing
DESTROYED:	ds	(only if carry set)
SIDE EFFECTS:	

FoamWarnIfNotEnoughSpace could move object blocks, but only if it
really warns, which means if we are low on disk space.  It should only
muck with the block containing the application object, but don't count
on that without further testing.

PSEUDO CODE/STRATEGY:
	Get string text from Text object;
	Lock string block;
	Set string property of access point;
	Free string block;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSaveConnectionText	proc	near
		uses	ax,bx,cx,dx,di
		.enter
	;
	; fetch value from text object
	;
		push	ax,dx
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		clr	dx				; alloc block
		call	ObjCallInstanceNoLock		; cx=block, ax=size
		mov	bx,cx
		tst	ax
		jz	clear
	;
	; get a pointer to text
	;
		call	MemLock
		mov	es,ax
		clr	di				; es:di = text
	;
	; write out the new value
	;
write::
		pop	ax,dx
		clr	cx				; use standard string
		call	AccessPointSetStringProperty	; ^hbx=text, cx=size
EC <		ERROR_C TERM_CONNECTION_DEFINITION_FAILED		>
		call	MemFree
		clc
done:
		.leave
		ret
	;
	; the text object is empty
	;
clear:
		pop	ax,dx
		clr	cx				
		call	AccessPointDestroyProperty
		clc
		jmp	done
	;
	; no disk space
	;
TermSaveConnectionText	endp


if	_TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSaveConnectionAccPnt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save internet access point ID

CALLED BY:	(INTERNAL) TermSaveConnection
PASS:		ax	= access point ID
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	9/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSaveConnectionAccPnt	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter
	;
	; Get access point ID from controller
	;
		push	ax			; save access point ID
		GetResourceHandleNS	ConnectionInternetAccessControl, bx
		mov	si, offset ConnectionInternetAccessControl
		mov	di, mask MF_CALL
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_SELECTION
		call	ObjMessage		; di destroyed
						; ax <- selectionID
						; carry set if no selection
		mov_tr	bp, ax			; bp <- selection to save
		pop	ax			; ax <- access point ID
		jc	warn
	;
	; Save the internet access point
	;
		clr	cx			; use std property
		mov	dx, APSP_INTERNET_ACCPNT
		call	AccessPointSetIntegerProperty

done:
		.leave
		ret

warn:
	;
	; Display warning about no internet access points.
	;
		push	ds
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bp, ERR_NO_INTERNET_ACCESS
		call	DisplayErrorMessage
		pop	ds
		jmp	done

TermSaveConnectionAccPnt	endp


endif	; _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermMakeConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make connection from defined access point

CALLED BY:	MSG_TERM_MAKE_CONNECTION
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		es 	= segment of TermClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get access point ID of current selection;
	Update internal variables and UI from properties associating that
		access point;
	Send out internal modem init command;
	Send out user specified modem init command;
	Dial phone number;
	Bring up main view dialog;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermMakeConnection	method dynamic TermClass, 
					MSG_TERM_MAKE_CONNECTION
		uses	ax, cx, dx, bp
		.enter
	
if	_MODEM_STATUS and not _TELNET
		segmov	es, ds, bx
	;
	; Make sure that we have permission to call the serial thread.
	; Otherwise, the serial thread might be blocking for us,
	; and cause deadlock.  Requeue this message, but
	; take a trip through the serial thread first,
	; so we don't loop ourselves to death.
	;
	; DO NOT PUT ANY CODE BEFORE THIS THAT YOU DON'T WANT
	; EXECUTED MORE THAN ONCE PER CONNECTION.
	; 
		BitTest	es:[statusFlags], TSF_PROCESS_MAY_BLOCK
		jnz	okToConnect

		mov	bx, handle 0
		mov	di, mask MF_RECORD
		call	ObjMessage		; di = event

		mov	cx, di			; cx = event
		mov	dx, mask MF_FORCE_QUEUE or \
			    mask MF_CHECK_DUPLICATE or \
			    mask MF_REPLACE	; In case user pressed more
						; than once.
		mov	ax, MSG_META_DISPATCH_EVENT
		SendSerialThread

		jmp	error
okToConnect:
endif	; not _TELNET

	;
	; Init variables first
	;
		call	TermMakeConnectionInit	
					; ax,bx,cx,di,si,ds,es,bp destroyed
					; carry set if com port not opened
if _TELNET
		LONG	jc noInternetErr
else
		LONG	jc comOpenError
endif
		call	TermResetForConnect	; carry set if out of memory

if	_TELNET
	;
	; If user cancels connection, ignore any error
	;
		lahf
		GetResourceSegmentNS	dgroup, es, TRASH_BX
		mov_tr	bx, ax
		mov	ax, TCE_USER_CANCEL
		BitTest	es:[statusFlags], TSF_USER_CANCEL_CONNECTION
		jnz	checkUserCancel
		mov_tr	ax, bx
		sahf
		LONG	jc outOfMemError
	;-----------------------------------
	; Preparing telnet connection
	;-----------------------------------
		call	TelnetConnectInternetProvider
					; carry set if error 
					;   ax <- TelnetCreateErr 
		LONG jc	connectInternetErr
	
		GetResourceHandleNS	ConnectionDestHostText, bx
		mov	si, offset ConnectionDestHostText
		call	TelnetResolveAddress
					; carry set if error in parsing addr
					;   ax <- TelnetCreateErr
		LONG jc	resolveAddrErr
		call	TelnetCreateConnection
					; carry set if error
					;   ax <- TelnetCreateErr
	
else	; _TELNET
	
	;
	; If user cancels, ignore any error
	;
		lahf
		GetResourceSegmentNS	dgroup, es
		cmp	es:[responseType], TMRT_USER_CANCEL
		je	generalError
		sahf
	LONG	jc	outOfMemError
	;
	; Check if phone number is correct. Mostly copied from
	; TermQuickDial. We don't really need to care about DBCS here since
	; the modem commands are in bytes. 
	;
		GetResourceHandleNS	ConnectionPhoneText, bx
		mov	si, offset ConnectionPhoneText
		call	CheckPhoneNumber;first check if number legit 
	LONG 	jz	phoneNumError	; exit if no number to dial

if	_MODEM_STATUS
	;
	; Tell serial line to start keep track of modem response
	;
		mov	ax, MSG_SERIAL_CHECK_MODEM_STATUS_START
		GetResourceSegmentNS	dgroup, es
		CallSerialThread	; ax,cx destroyed
	LONG	jc	outOfMemError
	
	;
	; Send whatever init string we need to send before users'
	;
		mov	es:[modemInitStart], TRUE
		mov	dl, TIMIS_FACTORY
		mov	ax, MSG_SERIAL_SEND_INTERNAL_MODEM_COMMAND
		call	TermWaitForModemResponse
					; carry set if error
	LONG	jc	comWriteError
		cmp	es:[responseType], TMRT_OK
	LONG	jne	generalError	; error if modem isn't OK
	;
	; Send services' modem init string
	;
		call	TermSendDatarecModemInit
					; carry set if error
					; ax,bx,cx,dx,bp,ds,si destroyed
					; es <- dgroup
		mov	es:[modemInitStart], FALSE
	LONG	jc	comWriteError
		cmp	es:[responseType], TMRT_OK
	LONG	jne	generalError	; error if modem isn't OK
endif	; if _MODEM_STATUS
	;
	; Send modem initialization code
	;
		GetResourceHandleNS	ConnectionInitText, bx
		mov	si, offset ConnectionInitText
		clr	al		; send custom string
		call	SendTextObjStrings
					; carry set if error
					; al <- 0 if connection err
					; al <- 1 if no text
if	_MODEM_STATUS
		jnc	waitForDial
else
		jnc	sendIntModemInit
endif
		tst	al		; connection err or no modem command?
	LONG	jz	comWriteError	; exit if can't connect
		jmp	dial		; continue if modem init command
	
if	_MODEM_STATUS
waitForDial:
EC <		Assert_dgroup	es					>
		cmp	es:[responseType], TMRT_OK
		je	sendIntModemInit
		cmp	es:[responseType], TMRT_TIMEOUT
		jne	generalError	
		mov	es:[responseType], TMRT_ERROR
		jmp	generalError	; if timeout, modem init string must
					; be wrong
sendIntModemInit:
		mov	es:[modemInitStart], TRUE
		mov	dl, TIMIS_INTERNAL
		mov	ax, MSG_SERIAL_SEND_INTERNAL_MODEM_COMMAND
		call	TermWaitForModemResponse
					; carry set if error
		mov	es:[modemInitStart], FALSE
	LONG	jc	comWriteError
		cmp	es:[responseType], TMRT_OK
	LONG	jne	generalError	; error if modem isn't OK
		
endif	; if _MODEM_STATUS

dial:
	;
	; Dial the number
	;
		call	QuickDial	; carry set if connect error
		jc	comWriteError
		cmp	es:[responseType], TMRT_CONNECT
		jne	generalError	; we have to receive CONNECT!!!
		call	DestroyConnectionIndicator
endif	; !_TELNET

if	_TELNET
		jc	telnetConnectErr
		call	TelnetStartConnectionTimer
		call	DestroyConnectionIndicator
endif	; _TELNET
		
if	_VSER
	;
	; Set the disconnection moniker in MainDialog
	;
		mov	dx, CMST_LPTR
		mov	cx, CMT_HANGUP
		clr	ax
		call	TermReplaceDisconnectMoniker
	;
	; don't make app go away on disconnect
	;
EC <		Assert_dgroup	es					>
		mov	es:[buryOnDisconnect], BB_FALSE
		
endif	; _VSER
	
	;
	; Bring up the MainDialog. (BX = same resource as
	; ConnectionsGroupList) 
	;
		push	bp
		GetResourceHandleNS	MainDialog, bx
		mov	si, offset MainDialog
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage	; ax,cx,dx,bp,di destroyed
		pop	bp
		clc				; signal no error
exit:
if	_TELNET
		jc	error
else	; _TELNET
if	_MODEM_STATUS
		call	TermMakeConnectionExit
endif	; _MODEM_STATUS
endif	; _TELNET

done:
		.leave
		ret

error:
		jmp	done
	;
	; Error reporting to users
	;
if	_TELNET
noInternetErr:
		mov	bp, ERR_NO_INTERNET_ACCESS
		jmp	displayError
	
connectInternetErr:
	;
	; If the connection is not open, don't close it
	;
		BitTest	ds:[telnetStatus], TTS_MEDIUM_OPEN
		jz	mediumClosed

telnetConnectErr:
resolveAddrErr:
checkUserCancel:
	;
	; Close domain medium first to make sure nothing is connected.
	;
		call	TelnetCloseDomainMedium		; carry set if error
	;
	; If user cancels or if TCE_PHONE_OFF, no note is displayed.
	;
mediumClosed:
		cmp	ax, TCE_USER_CANCEL
		je	userCancel

		cmp	ax, TCE_QUIET_FAIL
		jne	parseTelnetCreateErr
userCancel:
		call	DestroyConnectionIndicator
		stc				; signal error to exit code
		jmp	error
	
parseTelnetCreateErr::
		call	TermTelnetCreateErrToErrorString
						; bp <- ErrorString
						; bp <- 0 if no string
		tst 	bp			; if there is no string, just 
		stc				;   like user cancel
		jz	userCancel
		jmp	displayError
else	; _TELNET
		
if	_MODEM_STATUS
generalError:
	;
	; The error we have should not include TMRT_OK and TMRT_CONNECT since
	; these are not errors. The error string table assumes
	; TMRT_USER_CANCEL is the last enum type.
	;
		CheckHack <TMRT_USER_CANCEL+2 eq TermModemResponseType>
		mov	bx, es:[responseType]
		cmp	bx, TMRT_USER_CANCEL	; not error if user cancel
		je	exitCloseComPort
		sub	bx, TMRT_ERROR		; bx <- beginning error type
						; among TermModemResponseType
		jae	getErrorString		; for OK and CONNECT
						; received, they're unexpected
		mov	bp, ERR_CONNECT_MODEM_INIT_ERROR
		jmp	displayError
		
getErrorString:
		shr	bx			; index is byte size
EC <		cmp	bx, MODEM_RESPONSE_ERR_STRING_TABLE_LENGTH	>
EC <		ERROR_AE TERM_INVALID_MODEM_RESPONSE_ERR_STRING_TABLE_INDEX>
		mov	al, cs:[modemResponseErrorStringTable][bx]
		clr	ah
		mov	bp, ax			; bp <- ErrorString
		jmp	displayError

timeoutError:
		mov	bp, ERR_CONNECT_TIMEOUT
		jmp	displayError

phoneNumError:
		mov	bp, ERR_CONNECT_NO_PHONE_NUM
		jmp	displayError
		
comOpenError:
		mov	bp, ERR_COM_OPEN
		jmp	displayError
comWriteError:
		mov	bp, ERR_CONNECT_TEMP_ERROR
		jmp	displayError

endif	; if _MODEM_STATUS
endif	; _TELNET
		
outOfMemError:
		mov	bp, ERR_NO_MEM_ABORT
displayError:
		segmov	ds, es, ax
		call	DestroyConnectionIndicator
		BitSet	bp, DEF_SYS_MODAL
		call	DisplayErrorMessage	; ax, bx destroyed
NTELT <		call	CloseComPort					>
		stc				; signal error to clean up code
		jmp	exit			; clean up modem status

if	not _TELNET
exitCloseComPort:
	;
	; Display connection cancelling dialog
	;
		call	TermDisplayCancelConnectionDialog
		segmov	ds, es, ax
	;
	; If we are waiting for dial response and need to send out
	; ECI_CALL_RELEASE, we handle that in a special message handler.
	;
	; If we have init file key set to false, we don't
	; wait for ECI_CALL_RELEASE before exiting.
	;
		BitTest	ds:[statusFlags], TSF_WAIT_FOR_DIAL_RESPONSE
		jz	exitCloseComPortReal

		call	TermShouldWaitForECI	; carry set if wait for ECI
		jc	sendReleaseCall
		BitClr	ds:[statusFlags], TSF_WAIT_FOR_DIAL_RESPONSE

exitCloseComPortReal:
		call	CloseComPort
	;
	; Dismiss connection cancelling dialog
	;
		call 	TermDismissCancelConnectionDialog
		stc
		jmp	exit			; clean up modem status

sendReleaseCall:
	;
	; We need to specially handle the call release situation and
	; we don't want this thread to block. So, any cleanup work
	; that TermMakeConnection will be done in this message
	; handler. 
	;
		call	GeodeGetProcessHandle
		mov	ax, MSG_TERM_SEND_ECI_CALL_RELEASE_AFTER_CANCEL
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		stc
		jmp	done
endif	; !_TELNET
TermMakeConnection	endm

if	not _TELNET

	;
	; Make sure the table is defined in order of TermModemResponseType
	; for this lookup table to work.
	;
DefModemResponseErrStringTable	macro	errorStr, respType
.assert (respType-TMRT_ERROR) ge 0, \
	<Modem response string table: response type must be greater than TMRT_ERROR>
.assert (($-modemResponseErrorStringTable) eq ((respType-TMRT_ERROR)/2)) AND \
	((respType AND 00000001b) ne 1), \
	<Modem response string table: strings must be defined in the same order of TermModemResponseType>
		ErrorString	errorStr
endm

modemResponseErrorStringTable	label	ErrorString
	

DefModemResponseErrStringTable	ERR_CONNECT_MODEM_INIT_ERROR, 	TMRT_ERROR
DefModemResponseErrStringTable	ERR_CONNECT_DATAREC_INIT_ERROR, TMRT_DATAREC_INIT_ERROR
DefModemResponseErrStringTable	ERR_CONNECT_TIMEOUT, 		TMRT_TIMEOUT
DefModemResponseErrStringTable	ERR_CONNECT_NOT_CONNECT,	TMRT_BUSY
DefModemResponseErrStringTable	ERR_CONNECT_NOT_CONNECT,	TMRT_NOCARRIER
DefModemResponseErrStringTable	ERR_CONNECT_NOT_CONNECT,	TMRT_NODIALTONE
DefModemResponseErrStringTable	ERR_CONNECT_NOT_CONNECT,	TMRT_NOANSWER
DefModemResponseErrStringTable	ERR_CONNECT_RING,		TMRT_RING
DefModemResponseErrStringTable	ERR_NO_MESSAGE,			TMRT_UNEXPECTED_RESPONSE


MODEM_RESPONSE_ERR_STRING_TABLE_LENGTH	equ	$-modemResponseErrorStringTable

endif	; !_TELNET

if	_TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermTelnetCreateErrToErrorString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a TelnetCreateErr to correct ErrorString to report to
		user 

CALLED BY:	(INTERNAL) TermMakeConnection
PASS:		ax	= TelnetCreateErr
RETURN:		bp	= ErrorString
			= 0 if no string is defined for TelnetCreateErr
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If TCE_USER_CANCEL, return;
	If TelnetCreateErr is not supported, return;
	Map by a table;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	11/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Make sure the following strings are in the same order of TelntCreateErr
; Also make sure TelnetCreateErr increments by 2.
;
DefTCEToErrorString	macro	telnetCreateError, errorStr
.assert	($-TCEErrorStringTable) eq telnetCreateError
.assert (((size TelnetCreateErr) eq 2) AND \
	(telnetCreateError AND 00000001b) ne 1)
	word	errorStr
endm
	
TCEErrorStringTable	label word
DefTCEToErrorString	TCE_USER_CANCEL, ERR_NO_MESSAGE	; shouldn't be used
DefTCEToErrorString	TCE_INSUFFICIENT_MEMORY, ERR_CONNECT_TEMP_ERROR
DefTCEToErrorString	TCE_INTERNET_REFUSED, ERR_CONNECT_REFUSED
DefTCEToErrorString	TCE_INTERNET_TEMP_FAIL, ERR_CONNECT_TEMP_ERROR
DefTCEToErrorString	TCE_CANNOT_RESOLVE_ADDR, ERR_RESOLVE_ADDR_ERROR
DefTCEToErrorString	TCE_CANNOT_PARSE_ADDR, ERR_IP_ADDR
DefTCEToErrorString	TCE_INVALID_INTERNET_ACCPNT, ERR_NO_INTERNET_ACCESS
DefTCEToErrorString	TCE_CANNOT_CREATE_TELNET_CONNECTION, ERR_CONNECT_TEMP_ERROR
DefTCEToErrorString	TCE_NO_USERNAME, ERR_NO_USERNAME
DefTCEToErrorString	TCE_AUTH_FAILED, ERR_AUTH_FAILED
DefTCEToErrorString	TCE_LINE_BUSY, ERR_LINE_BUSY
DefTCEToErrorString	TCE_NO_ANSWER, ERR_NO_ANSWER
DefTCEToErrorString	TCE_COM_OPEN, ERR_COM_OPEN
DefTCEToErrorString	TCE_DIAL_ERROR, ERR_DIAL_ERROR
DefTCEToErrorString	TCE_PROVIDER_ERROR, ERR_CONNECT_PROVIDER_ERROR
DefTCEToErrorString	TCE_INTERNAL_ERROR, ERR_CONNECT_GENERAL_ERROR

TCE_ERROR_STRING_TABLE_SIZE	equ	($-TCEErrorStringTable)
	
TermTelnetCreateErrToErrorString	proc	near
		.enter
EC <		Assert_etype	ax, TelnetCreateErr			>
		CheckHack <TCE_USER_CANCEL eq 0>
	;
	; Don't map error if TelnetCreateErr is not within the string table
	;
		clr	bp			; default: no string
		cmp	ax, TCE_ERROR_STRING_TABLE_SIZE
		jae	done
	
		mov	bp, offset TCEErrorStringTable
		add	bp, ax
		mov	bp, cs:[bp]
EC <		Assert_etype	bp, ErrorString				>
done:
		.leave
		ret
TermTelnetCreateErrToErrorString	endp

endif	; _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermMakeConnectionInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init variables and other objects before making terminal
		connection. 

CALLED BY:	(INTERNAL) TermMakeConnection
PASS:		ds	= dgroup
RETURN:		Telnet only:
			carry set if internet access point invalid

		carry set if com port is not open
DESTROYED:	ax, bx, cx, di, si, ds, es, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermMakeConnectionInit	proc	near
		.enter
EC <		Assert_dgroup	ds					>
	;
	; Default first response type
	;
NTELT <		mov	ds:[responseType], TMRT_OK			>

if	_TELNET
	;
	; If we are launched via IACP, we can use the preset accpnt
	;
		BitTest	ds:[statusFlags], TSF_LAUNCHED_BY_IACP
		jz	getAccpntFromList

		mov	cx, ds:[settingsConnection]
EC <		cmp	cx, ACCESS_POINT_INVALID_ID			>
EC <		ERROR_E TERM_ERROR					>
		jmp	updateFromAccpnt

getAccpntFromList:
endif	; _TELNET

	;
	; Get the item (ID) selected
	;
		GetResourceHandleNS	ConnectionsGroupList, bx
		mov	si, offset ConnectionsGroupList
		mov	di, mask MF_CALL
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_SELECTION
		call	ObjMessage	; ax <- selection ID, di destroyed
	;
	; Initialize internal variables
	;
		mov	cx, ax		; cx <- selection ID
		mov	ds:[settingsConnection], ax

updateFromAccpnt::
		call	TermUpdateFromAccessPoint
	;
	; Initiate connection dialog
	;
		call	InitiateConnectionIndicator

if	_TELNET
	;
	; Clear the flag status flags: no TSF_USER_CANCEL_CONNECTION and no
	; TSF_IGNORE_USER_CONNECTION_CANCEL 
	;
		andnf	ds:[statusFlags], not (mask \
			TSF_USER_CANCEL_CONNECTION or mask \
			TSF_IGNORE_USER_CONNECTION_CANCEL) 
	;
	; Check if we have valid internet access point
	;
		mov	ax, ds:[remoteExtAddr].APESACA_accessPoint
		call	AccessPointIsEntryValid
					; carry set if invalid
else
	;
	; Check if com port is open. If not, open it
	;
EC <		cmp	ds:[serialPort], NO_PORT			>
EC <		ERROR_NE TERM_SERIAL_PORT_SHOULD_NOT_BE_OPEN		>
		mov	cx, SERIAL_COM1	; Responder default com port
		call	OpenPort	; cx = 0 if com port no opened
					; ax,bx,dx,si,di destroyed
		stc			; default is com port can't be opened
		jcxz	done
	;
	; Reset any necessary status flags
	;
RSP <		mov	ds:[eciStatus], TECIS_NO_CONNECTION    		>
RSP <		clr	ds:[dataCallID]					>
	;
	; Clear blacklist for Responder
	;
RSP <		call	TermClearBlacklist				>
	;
	; Restore previous state and parameters
	;
		call	RestoreState	
		clc			; No problem opening com port
	
endif	; _TELNET
	
done::
		.leave
		ret
TermMakeConnectionInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermResetForConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset terminal screen, clearing screen first, if needed.  
		(Telnet: Also reset disconnection indicator dialog text.)

CALLED BY:	(INTERNAL) TermMakeConnection
PASS:		ds	= dgroup

RETURN:		carry set if insufficient memory (if _CLEAR_SCR_BUF)
		else carry clear

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
		This code used to be at the end of TermMakeConnectionInit.
		Moved to a separate routine so the error returned by 
		MSG_SCR_CLEAR_SCREEN_AND_SCROLL_BUF can be processed.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 8/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermResetForConnect	proc	near

if 	_CLEAR_SCR_BUF
	;
	; Clear screen before making each connection.
	;
		Assert_dgroup	ds					
		mov	ax, MSG_SCR_CLEAR_SCREEN_AND_SCROLL_BUF
		mov	bx, ds:[termuiHandle]	
		CallScreenObj
		jc	exit
endif	; _CLEAR_SCR_BUF
	
	;
	; Reset terminal.
	;
		mov	ax, MSG_SCR_RESET_VT
		CallScreenObj
	;
	; For Telnet, local echo os turned on by default.
	;
TELT <		mov	ds:[halfDuplex], TRUE				>
	;								
	; Reset the text in DisconnectionIndicatorDialog		
	;								
TELT <		mov	bp, offset disconnectText			>
					; bp <- chunk of text		
TELT <		call	TelnetSetDisconnectDialogText			>

		clc
exit::
		ret
TermResetForConnect	endp


if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dial the phone number

CALLED BY:	(INTERNAL) TermMakeConnection
PASS:		nothing
RETURN:		carry set if connection error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	* The code is mostly copied from TermQuickDial.
	
	if (there is text inside) {
		Bring up connection dialog box;
		Send out dial prefix;
		if (dial tone) {
			Send dial tone character;
		} else {
			Send dial pulse character;
		}
		Get the phone number from text object and send it;
		Take down connection dialog box;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuickDial	proc	near
	uses	ax, bx, cx, dx, si, di, ds, es
	.enter

	GetResourceSegmentNS	dgroup, ds
	BitSet  ds:[statusFlags], TSF_WAIT_FOR_DIAL_RESPONSE
	
	;
	; Send out phone number
	;
	GetResourceHandleNS	ConnectionPhoneText, bx
	mov	si, offset ConnectionPhoneText
	mov	al, 1				; send dial command
	call	SendTextObjStrings		; carry set if error
						; al <- 0 if connection err
						; al <- 1 if no text
	jc	error
		
	;
	; Check response. If user cancel while we are dialing and wait for
	; response, we want to keep TSF_WAIT_FOR_DIAL_RESPONSE so that we
	; know later than we should send ECI_CALL_RELEASE besides ATH.
	;
	cmp	ds:[responseType], TMRT_USER_CANCEL
	je	done				; carry clear
	BitClr	ds:[statusFlags], TSF_WAIT_FOR_DIAL_RESPONSE
						; carry clear
	jmp	done

error:
        mov     ds:[systemErr], FALSE		; indicate error

done:
	.leave
	ret
QuickDial	endp
endif	; !_TELNET

if	_MODEM_STATUS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitiateConnectionIndicator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate the connection indicator

CALLED BY:	(INTERNAL) TermMakeConnectionInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitiateConnectionIndicator	proc	near
		uses	ax, bx, cx, dx, di, si, es, ds, bp
		.enter
	;
	; Construct connection indicator text
	;
TELT <		call	InitiateConnectionIndicatorMakeStatusText	>
						; ax,bx,cx,dx,si,di destroyed
		call	InitiateConnectionIndicatorMakeDescText		
						; everything destroyed
	;
	; Bring up the dialog
	;
		GetResourceHandleNS	ConnectionIndicatorDialog, bx
		mov	si, offset ConnectionIndicatorDialog
						; ^lcx:dx <- dialog
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage		; ax,cx,dx,bp destroyed
done:
		.leave
		ret
InitiateConnectionIndicator	endp

if	_TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitiateConnectionIndicatorMakeStatusText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct the initial status text of connection indicator

CALLED BY:	(INTERNAL) InitiateConnectionIndicator
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Set the initial status message to nothing;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	11/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitiateConnectionIndicatorMakeStatusText	proc	near
	nullText	local	TCHAR
		.enter
	;
	; Initialize the empty text so that old text will not show up
	; first. Here we put a NULL byte as the 1st byte 
	;
		clr	ss:[nullText]		; null byte
		mov	cx, ss
		lea	dx, ss:[nullText]
	;
	; Set status text
	;
		push	bp
		GetResourceHandleNS	ConnectionIndicatorDialog, bx
		mov	si, offset ConnectionIndicatorDialog
		mov	ax, MSG_FOAM_PROGRESS_DIALOG_SET_STATUS_TEXT
		mov	di, mask MF_CALL
		call	ObjMessage		; ax,cx,dx,bp destroyed
		pop	bp
		
		.leave
		ret
InitiateConnectionIndicatorMakeStatusText	endp
endif	; _TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitiateConnectionIndicatorMakeDescText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct the description text of connection indicator

CALLED BY:	(INTERNAL) InitiateConnectionIndicator
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Set 1st part of the description text to connection indicator dialog;
	Get the connection name text;
	if (no connection name text) {
		use default name text;
	}
	Append connection name text to description text;
	Clean up;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	11/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitiateConnectionIndicatorMakeDescText	proc	near
		.enter
	;
	; Set 1st part of description text of dialog "Making connection to.."
	;
		GetResourceHandleNS	ConnectionIndicatorDialog, bx
		mov	si, offset ConnectionIndicatorDialog
		mov	ax, MSG_FOAM_PROGRESS_DIALOG_SET_DESCRIPTION_TEXT_OPTR
		GetResourceHandleNS	indicatorText, cx
		mov	dx, offset indicatorText
		mov	di, mask MF_CALL
		call	ObjMessage		; ax,cx,dx,bp destroyed
	;
	; Get the connection name
	;
		call	GetCurrentAccessPointConnectName
						; carry set if error
						; cx <-#chars
						; ^hbx <- name block 
	;
	; It can't fail since there must a selection before a connerction is
	; made.
	;
		jc	done
		jcxz	cleanNameBlock		; no connect name

		push	bx			; save connect name text block
		call	MemLock
		mov_tr	cx, ax
		clr	dx			; cx:dx <- connection name
	;
	; Append connection name to description text
	;
EC <		Assert_nullTerminatedAscii	cxdx			>
		GetResourceHandleNS	ConnectionIndicatorDialog, bx
		mov	si, offset ConnectionIndicatorDialog
		mov	ax, MSG_FOAM_PROGRESS_DIALOG_APPEND_DESCRIPTION_TEXT
		mov	di, mask MF_CALL
		call	ObjMessage		; ax,cx,dx,bp,di destroyed
		pop	bx			; bx <- name block
	
cleanNameBlock:
		call	MemFree			; free name block
	
done:
		.leave
		ret
InitiateConnectionIndicatorMakeDescText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyConnectionIndicator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy connection indicator

CALLED BY:	(INTERNAL) TermMakeConnection
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	7/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyConnectionIndicator	proc	near
		uses	ax, bx, cx, dx, di, si, es, ds, bp
		.enter
	
if	_TELNET
	;
	; In Telnet, it is possible that the user is cancelling
	; connection, thus having a Connection cancelling dialog . So, we
	; have to make sure to close it as well. 
	;
		GetResourceSegmentNS	dgroup, es
		PSem	es, closeSem, TRASH_AX_BX
	;
	; Set the flag so that no connection cancellation dialog will be put
	; up.
	;
		BitSet	es:[statusFlags], TSF_IGNORE_USER_CONNECTION_CANCEL

		GetResourceHandleNS	CancelConnectionDialog, bx
		mov	si, offset CancelConnectionDialog
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjMessage		; ax,cx,dx,bp destroyed
endif	; _TELNET
		
		GetResourceHandleNS	ConnectionIndicatorDialog, bx
		mov	si, offset ConnectionIndicatorDialog
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjMessage		; ax,cx,dx,bp destroyed

TELT <		VSem	es, closeSem, TRASH_AX_BX			>
		.leave
		ret
DestroyConnectionIndicator	endp


endif	; if _MODEM_STATUS

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendTextObjStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the text in a text obj text and a CR char to serial line 

CALLED BY:	(INTERNAL) QuickDial, TermMakeConnection
PASS:		^lbx:si	= text object containing the string to send
		al	= 0: send custom modem command
			  1: send dial command
RETURN:		carry set if error
			al	= 0 if connection error
			al	= 1 if text object has no string
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get the string block from text object;
	if (there is text inside) {
		Lock down string block;
		Send the text inside to serial line;
		if (no connection error) {
			Send CR char;
		}
	}
	Free up string block;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendTextObjStrings	proc	near
		uses	bx, cx, dx, ds, es, si, di
		.enter
EC <		Assert_objectOD	bxsi, UnderlinedGenTextClass		>
EC <		Assert_inList	al, <0, 1>				>
		push	ax
	;
	; Get the string block from text object
	;
		clr	dx		; alloc new block
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		mov	di, mask MF_CALL
		call	ObjMessage	; cx <- block handle
					; ax <- string len excluding NULL
					; di destroyed
	;
	; Exit if no string in there
	;
		mov	bx, cx		; bx <- block handle
		mov_tr	cx, ax		; cx <- text length
		pop	dx		; dx <- dial/custom command
		stc			; default is error
		jcxz	emptyTextErr
	;
	; Lock down the string block and send it out
	;
EC <		tst	ch						>
EC <		ERROR_NZ TERM_DATAREC_MODEM_INIT_STRING_TOO_LONG	>
		push	bx		; save string block hptr
		call	MemLock		; ax <- sptr of string block
		xchg	dx, ax		; ax <- dial/custom command
		clr	bp		; dxbp <- fptr to string
		GetResourceSegmentNS	dgroup, es
		tst	al		; custom or dial command?
		jz	customCommand
		clr	ch		; long timeout
		mov	ax, MSG_SERIAL_SEND_DIAL_MODEM_COMMAND
		jmp	waitForResponse
	
customCommand:
		mov	ch, 1		; short timeout
		mov	ax, MSG_SERIAL_SEND_CUSTOM_MODEM_COMMAND
	
waitForResponse:
		call	TermWaitForModemResponse
					; carry set if error
		mov	al, 0		; default is connection error
		pop	bx		; ^hbx <- text block to free

freeTextBlock:
	;
	; Delete the string block
	;
		pushf			; restore flag
		call	MemFree		; bx destroyed
		popf			; restore flag
	
		.leave
		ret

emptyTextErr:
		mov	al, 1		; no text error
		jmp	freeTextBlock
SendTextObjStrings	endp

if	_MODEM_STATUS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermMakeConnectionExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common clean up code for TermMakeConnection

CALLED BY:	(INTERNAL) TermMakeConnection,
		TermSendEciCallReleaseAfterCancel 
PASS:		carry set 	= error exiting
		carry clear	= no error exiting
RETURN:		nothing
DESTROYED:	all (including es,ds)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Call MSG_SERIAL_CHECK_MODEM_STATUS_END;
	if (no error) {
		Allow serial to block;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermMakeConnectionExit	proc	far
		.enter
	
		pushf
		GetResourceSegmentNS	dgroup, es, TRASH_BX
		segmov	ds, es, ax
		mov	ax, MSG_SERIAL_CHECK_MODEM_STATUS_END
		CallSerialThread
		popf
	;
	; We're done calling the serial thread now. If no errors,
	; let the serial thread start calling us, until we request
	; otherwise.
	;
		jc	done
		call	TermAllowSerialToBlock
		
done:
		.leave
		ret
TermMakeConnectionExit	endp
endif	; _MODEM_STATUS

endif	; !_TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermDoConnectionEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate an operation on a group of connection objects

CALLED BY:	(INTERNAL) TermSaveConnection, TermUpdateFromAccessPoint
PASS:		ax	= access point ID
		bx	= hptr to resource of ConnectionObjTable objects
		si	= nptr to ConnectionObjTable entry to begin
		di	= nptr to ConnectionAPSPTable entry to begin
		cx	= # items to enumerate
		bp	= nptr to routine to call

			This routine takes:

			^lbx:si	= UI object
			dx	= AccessPointStandardProperty
			ax	= access point ID

RETURN:		si	= nptr to ConnectionObjTable entry past the last
			processed entry
		di 	= nptr to ConnectionAPSPTable entry past the last
			processed entry
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	while (item count-- > 0) {
		Get current UI object;
		Get current AccessPointStandardProperty;
		Call passed in routine;
		Update indices to ConnectionObjTable and ConnectionAPSPTable
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermDoConnectionEnum	proc	near
		uses	dx
		.enter
EC <		Assert_handle	bx					>
EC <		Assert_nptr	si, cs					>
EC <		Assert_nptr	di, cs					>
EC <		Assert_nptr	bp, cs					>
EC <		push	ax, si, di, dx					>
EC <		mov	ax, 2						>
EC <		mul	cx						>
EC <		add	si, ax						>
EC <		Assert_fptr	cssi		; past EOT?		>
EC <		add	di, ax						>
EC <		Assert_fptr	csdi		; past EOT?		>
EC <		pop	ax, si, di, dx					>
enumLoop:
		push	si
		mov	si, cs:[si]		; si <-lptr to UI obj
		mov	dx, cs:[di]		; dx <-
						; AccessPointStandardProperty
		call	bp		
		add	di, 2			; update table index
		pop	si			; si <- index
		add	si, 2			; update table index
		loop	enumLoop
		
		.leave
		ret
TermDoConnectionEnum	endp

if not _TELNET


UtilsCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermValidatePhone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate a phone number

CALLED BY:	(EXTERNAL) TermSaveFocus
PASS:		*ds:si	- object to validate
RETURN:		carry set if invalid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermValidatePhone	proc	far
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; get the phone number
	;
		clr	dx				; alloc a block
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		call	ObjCallInstanceNoLock		; cx=blk, ax=length
		mov	bx, cx
		mov	cx, ax
		clc
		jcxz	done
	;
	; skip first char
	;
		dec	cx
		jz	done
		mov	di, size TCHAR
	;
	; scan remaining characters for a '+'
	;
		call	MemLock
		mov	es, ax				; es:di = text
		mov	ax, C_PLUS
		LocalFindChar				; z set if found
		clc
		jnz	done
	;
	; we found an embedded plus, which isn't allowed
	;
		push	bx				; save temp block
		push	ds:[LMBH_handle]		; save obj block
		clr	ax
		push	ax
		push	ax		; SDOP_helpContext = 0
		push	ax
		push	ax		; SDOP_customTriggers = 0
		push	ax
		push	ax		; SDOP_stringArg2 = 0
		push	ax
		push	ax		; SDOP_stringArg1 = 0
		mov	ax, handle invalidPhoneErr
		push	ax
		mov	ax, offset invalidPhoneErr
		push	ax		; SDOP_customString=invalidPhoneErr
		mov	ax, CustomDialogBoxFlags <0,CDT_ERROR,GIT_NOTIFICATION,0>
		push	ax
		call	UserStandardDialogOptr		; ax = response
		pop	bx				; obj block
		call	MemDerefDS
		pop	bx				; temp block
		stc
done:
		lahf
		call	MemFree
		sahf
		.leave
		ret
TermValidatePhone	endp

UtilsCode	ends

endif	; if not _TELNET
endif	; if _ACCESS_POINT

