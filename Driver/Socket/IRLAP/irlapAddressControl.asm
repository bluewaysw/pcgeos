COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		irlapAddressControl.asm

AUTHOR:		Steve Jang, Nov 15, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/15/94   	Initial revision


DESCRIPTION:
	Code for address controller for IrLAP		

	$Id: irlapAddressControl.asm,v 1.1 97/04/18 11:57:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapClassStructures	segment resource

IrlapAddrCtrlChildList	GenControlChildInfo	\
	< offset IrlapAddrCtrlBox,
	  0,
	  mask GCCF_IS_DIRECTLY_A_FEATURE or mask GCCF_ALWAYS_ADD>

IrlapAddrCtrlFeaturesList GenControlFeaturesInfo	\
	< offset IrlapAddrCtrlBox,
	  0,
	  1>

IrlapClassStructures	ends

IrlapActionCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize non-zero parts of our instance data.

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= IrlapAddressControl object
		ds:di	= IrlapAddressControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACMetaInitialize method dynamic IrlapAddressControlClass, MSG_META_INITIALIZE
	CheckHack <SocketAddressControl_offset eq IrlapAddressControl_offset>
		mov	ds:[di].SACI_geode, handle 0

		mov	di, offset IrlapAddressControlClass
		GOTO	ObjCallSuperNoLock
IACMetaInitialize endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACGenControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The GenControl object calls the message to get information
		about the controller.  The structure returned allows
		GenControlClass to implement a wide range of default behavior.

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= IrlapAddressControlClass instance data
		ds:bx	= IrlapAddressControlClass object (same as *ds:si)
		es 	= segment of IrlapAddressControlClass
		ax	= message #
		cx:dx	= GenControlDupInfo structure to fill in
RETURN:		GenControlDupInfo field filled in
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACGenControlGetInfo	method dynamic IrlapAddressControlClass, 
					MSG_GEN_CONTROL_GET_INFO
		uses	cx
		.enter

		segmov	ds, cs				; ds:si = source
		mov	si, offset IrlapAddrCtrlInfo
		mov	es, cx
		mov	di, dx				; es:di = dest
		mov	cx, size GenControlBuildInfo
		rep	movsb

		.leave
		ret
IACGenControlGetInfo	endm

IrlapAddrCtrlInfo	GenControlBuildInfo <
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ;GCBI_flags
	0,					; GCBI_initFileKey
	0,					; GCBI_gcnList
	0,					; GCBI_gcnCount
	0,					; GCBI_notificationList
	0,					; GCBI_notificationCount
	0,					; GCBI_controllerName

	handle IrlapAddrCtrlBox,		; GCBI_dupBlock
	IrlapAddrCtrlChildList,			; GCBI_childList
	length IrlapAddrCtrlChildList,		; GCBI_childCount
	IrlapAddrCtrlFeaturesList,		; GCBI_featuresList
	length IrlapAddrCtrlFeaturesList,	; GCBI_featuresCount
	1,					; GCBI_features
	0,					; GCBI_toolBlock
	0,					; GCBI_toolList
	0,					; GCBI_toolCount
	0,					; GCBI_toolFeaturesList
	0,					; GCBI_toolFeaturesCount
	0,					; GCBI_toolFeatures 	

	0,					; GCBI_helpContext
	0					; GCBI_reserve
>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACGenControlGenerateUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate UI for a custom controller

CALLED BY:	MSG_GEN_CONTROL_GENERATE_UI
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= instance variables
		es 	= segment of IrlapAddressControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACGenControlGenerateUi	method dynamic IrlapAddressControlClass, 
					MSG_GEN_CONTROL_GENERATE_UI
		.enter
	;
	; Call superclass
	;
		mov	di, offset IrlapAddressControlClass
		call	ObjCallSuperNoLock
	;
	; Gen childBlock information
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData	; ds:bx = TempGenControlInstance
		mov	di, ds:[si]
		add	di, ds:[di].IrlapAddressControl_offset
		movm	ds:[di].IACI_childBlock, ds:[bx].TGCI_childBlock, cx
	;
	; Set the output of the test object
	;
		push	si			; save self lptr
		mov	cx, ds:LMBH_handle
		mov	dx, si			; ^lcx:dx = control object
		mov	bx, ds:[di].IACI_childBlock ; ^lbx:si = prompt
		mov	si, offset IrlapAddrCtrlPrompt
		mov	ax, MSG_VIS_TEXT_SET_OUTPUT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Get information about socket client in IrLAP driver
	; Initialize IrLAP address controller
	;
		GetDgroup es, ax
		mov	ax, es
		pop	si			; *ds:si = self
		mov	di, ds:[si]
		add	di, ds:[di].IrlapAddressControl_offset
		mov	ds:[di].IACI_irlapDgroup, ax
		call	IrlapFindSocketClient	; es:si = IrlapClient struct
		jc	nullSeg
		movm	ds:[di].IACI_irlapStation, es:[si].IC_station, ax
done:
		.leave
		ret
nullSeg:
		movm	ds:[di].IACI_irlapStation, NULL_SEGMENT, ax
		jmp	done
IACGenControlGenerateUi	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACSocketAddressControlGetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the block of data that holds the addresses selected by
		the user to pass to the transport driver.

CALLED BY:	MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= IrlapAddressControlClass instance data
		ds:bx	= IrlapAddressControlClass object (same as *ds:si)
		es 	= segment of IrlapAddressControlClass
		ax	= message #
RETURN:
		if ok:
			ax	= ChunkArray of SACAddress structures
				  in same block as controller
		else
			ax	= 0

DESTROYED:	cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACSocketAddressControlGetAddresses method dynamic IrlapAddressControlClass, 
				    MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES
		.enter
	;
	; Allocate a buffer on the stack
	;
		sub	sp, IRLAP_ADDRESS_LEN + size word
		mov	bp, sp
		mov	dx, ss
	;
	; Get the text from IrlapAddrCtrlPrompt
	;
		mov	bx, ds:[di].IACI_childBlock
		mov	si, offset IrlapAddrCtrlPrompt
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage		; dx:bp = string
		push	dx, bp
		push	cx

	;
	; Allocate a chunk array for SACAddress structures
	;
		mov	bx, IRLAP_ADDRESS_LEN + IRLAP_ADDRESS_LEN + \
			    size SACAddress
		clr	cx, si, ax
		call	ChunkArrayCreate	; *ds:si = array
		jc	destroy
		mov	ax, si			; ax = chunk array handle
		call	ChunkArrayAppend	; ds:di = element
		jc	error
		pop	cx
		mov	bx, cx
		inc	cx			; include null terminator
		mov	ds:[di].SACA_opaqueSize, cx
		add	di, offset SACA_opaque	; add SACA_opaqueSize field
		segmov	es, ds			; es:di = chunk array elt
		pop	ds, si			; ds:si = address to copy
		mov	{byte}ds:[si][bx], 0	; make sure str terminates w/ 0
		push	si, cx
		rep	movsb			; copy opaque address
		pop	si, cx
		rep	movsb			; copy user-readable address
done:
	;
	; Deallocate the buffer we allocated at the beginning
	;
		add	sp, IRLAP_ADDRESS_LEN + size word
		.leave
		ret
destroy:
		mov_tr	ax, si
		call	LMemFree
error:
		pop	ax, ax, ax		; pop saved registers
		clr	ax
		jmp	done
		
IACSocketAddressControlGetAddresses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACSocketAddressControlSetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current user-editable address to the passed address.

CALLED BY:	MSG_SOCKET_ADDRESS_CONTROL_SET_ADDRESSES
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= IrlapAddressControlClass instance data
		ds:bx	= IrlapAddressControlClass object (same as *ds:si)
		es 	= segment of IrlapAddressControlClass
		ax	= message #
		^lcx:dx	= ChunkArray of SACAddress structures
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACSocketAddressControlSetAddresses	method dynamic IrlapAddressControlClass, 
				MSG_SOCKET_ADDRESS_CONTROL_SET_ADDRESSES

	;
	; Locate SACAddress.
	;
	movdw	bxsi, cxdx		; ^lbx:si = SACAddress array
	mov	dx, ds:[di].IACI_childBlock	; ^hdx = child block
	call	ObjLockObjBlock
	mov	ds, ax			; *ds:si = SACAddress array
	call	ChunkArrayGetCount	; cx = count
EC <	cmp	cx, 1							>
EC <	WARNING_NE IRLAP_NOT_SINGLE_ADDRESS				>
	jcxz	done			; ignore if no address

	clr	ax			; get first elt
	call	ChunkArrayElementToPtr	; ds:di = SACAddress, cx = size

	;
	; Copy user-readable string onto stack (because the array may be in
	; the same block as us).
	;
	lea	si, ds:[di].SACA_opaque
	add	si, ds:[di].SACA_opaqueSize	; ds:si = user-readable addr
	sub	sp, size IrlapUserAddress
EC <	movdw	esdi, dssi						>
EC <	SBStringLength		; cx = length excl. null		>
EC <	Assert	be, cx, <IRLAP_ADDRESS_LEN - 1>				>
	movdw	esdi, sssp


if DBCS_PCGEOS
charLoop:
	lodsb				; al = source char
	stosb				; copy to es:[di]
	tst	al			; check for null
	jz	doneCopy
	loop	charLoop
doneCopy:
else
	LocalCopyString
endif
	call	MemUnlock		; unlock SACAddress array

	;
	; Pass the string to the prompt.
	;
	mov	bx, dx
	mov	si, offset IrlapAddrCtrlPrompt	; ^lbx:si = IrlapAddrCtrlPrompt
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	movdw	dxbp, sssp		; dx:bp = addr string to use
	clr	cx			; null-termiated
	mov	di, mask MF_CALL	; we're passing a buffer ...
	call	ObjMessage
	add	sp, size IrlapUserAddress

done:
	ret
IACSocketAddressControlSetAddresses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACIrlapAddrStartDiscovery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the dialog for discovery

CALLED BY:	MSG_IRLAP_ADDR_START_DISCOVERY
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= IrlapAddressControlClass instance data
		ds:bx	= IrlapAddressControlClass object (same as *ds:si)
		es 	= segment of IrlapAddressControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACIrlapAddrStartDiscovery	method dynamic IrlapAddressControlClass, 
					MSG_IRLAP_ADDR_START_DISCOVERY
		uses	ax, cx, dx, bp
		.enter
	;
	; If we are not registered, we can't do discovery
	;
		cmp	ds:[di].IACI_irlapStation, NULL_SEGMENT
		je	done
	;
	; Bring up the dialog
	;
		push	di
		mov	bx, ds:[di].IACI_childBlock
		mov	si, offset IrlapAddrCtrlDiscoveryDialog
		mov	di, mask MF_FIXUP_DS
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage
		pop	di
	;
	; Disable select button
	;
		push	di
		mov	bx, ds:[di].IACI_childBlock
		mov	si, offset IrlapAddrCtrlDiscoverySelect
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjMessage
		pop	di
	;
	; DoDiscovery
	;
		mov	es, ds:[di].IACI_irlapStation
		mov	bx, es:IS_clientHandle
		call	IrlapSocketDoDiscovery	; cx = num of addresses found
		movm	ds:[di].IACI_discoveryLogs, es:IS_discoveryLogBlock, ax
		mov	ds:[di].IACI_addrSelection, IRLAP_ADDRESS_NOT_SELECTED
	;
	; Initialize available address list
	;
		mov	bx, ds:[di].IACI_childBlock
		mov	si, offset IrlapAddrCtrlAddressList
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjMessage
done:
		.leave
		ret
IACIrlapAddrStartDiscovery	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACIrlapAddrDoDiscovery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do discovery again

CALLED BY:	MSG_IRLAP_ADDR_DO_DISCOVERY
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= IrlapAddressControlClass instance data
		ds:bx	= IrlapAddressControlClass object (same as *ds:si)
		es 	= segment of IrlapAddressControlClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACIrlapAddrDoDiscovery	method dynamic IrlapAddressControlClass, 
					MSG_IRLAP_ADDR_DO_DISCOVERY
		uses	ax, cx, dx, bp
		.enter
	;
	; Disable select button
	;
		push	di
		mov	bx, ds:[di].IACI_childBlock
		mov	si, offset IrlapAddrCtrlDiscoverySelect
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjMessage
		pop	di
	;
	; DoDiscovery
	;
		segmov	es, ds:[di].IACI_irlapStation, ax
		mov	bx, es:IS_clientHandle
		call	IrlapSocketDoDiscovery	; cx = num of addresses found
		movm	ds:[di].IACI_discoveryLogs, es:IS_discoveryLogBlock, ax
		mov	ds:[di].IACI_addrSelection, IRLAP_ADDRESS_NOT_SELECTED
	;
	; Initialize available address list
	;
		mov	bx, ds:[di].IACI_childBlock
		mov	si, offset IrlapAddrCtrlAddressList
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjMessage

		.leave
		ret
IACIrlapAddrDoDiscovery	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACIrlapAddrSetAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User selected an address from IrlapAddrCtrlAddressList

CALLED BY:	MSG_IRLAP_ADDR_SET_ADDR
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= IrlapAddressControlClass instance data
		ds:bx	= IrlapAddressControlClass object (same as *ds:si)
		es 	= segment of IrlapAddressControlClass
		ax	= message #
		cx	= index to the item element in the list
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACIrlapAddrSetAddr	method dynamic IrlapAddressControlClass, 
				MSG_IRLAP_ADDR_SET_ADDR
		.enter
	;
	; Set the current address selected by the user
	;
		mov	ds:[di].IACI_addrSelection, cx
	;
	; Eable select button
	;
		mov	bx, ds:[di].IACI_childBlock
		mov	si, offset IrlapAddrCtrlDiscoverySelect
		mov	dl, VUM_NOW
		clr	di
		mov	ax, MSG_GEN_SET_ENABLED
		call	ObjMessage
		
		.leave
		ret
IACIrlapAddrSetAddr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACIrlapAddrConfirmAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User confirms the address s/he selected
		Replace the address string in IrlapAddrCtrlPrompt to
		the address selected in IACI_discoveryLogs
		We guaranteed not to receive this message unless the user
		selected some address in discovery logs already.

CALLED BY:	MSG_IRLAP_ADDR_CONFIRM_ADDR
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= IrlapAddressControlClass instance data
		ds:bx	= IrlapAddressControlClass object (same as *ds:si)
		es 	= segment of IrlapAddressControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACIrlapAddrConfirmAddr	method dynamic IrlapAddressControlClass, 
					MSG_IRLAP_ADDR_CONFIRM_ADDR
		.enter
	;
	; Find the appropriate address string in discoveryLogs
	;
		mov	bx, ds:[di].IACI_discoveryLogs
		call	MemLock
		mov	dx, ax
		mov	ax, size DiscoveryLog
		mov	cx, ds:[di].IACI_addrSelection
		mul	cl
		add	ax, size DiscoveryLogBlock + DL_info
		mov_tr	bp, ax
		push	bx
	;
	; Replace the string in IrlapAddrCtrlPrompt with the address found
	; above
	;
		mov	bx, ds:[di].IACI_childBlock
		mov	si, offset IrlapAddrCtrlPrompt
		clr	cx
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjMessage
	;
	; Highlight string in IrlapAddrCtrlPrompt
	;
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		call	ObjMessage
	;
	; Dismiss the dialog
	;
		mov	si, offset IrlapAddrCtrlDiscoveryDialog
		mov	cx, IC_DISMISS
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		call	ObjMessage
	;
	; Unlock discovery block
	;
		pop	bx
		call	MemUnlock
		.leave
		ret
IACIrlapAddrConfirmAddr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACMetaTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a MSG_SOCKET_ADDRESS_CONTROL_SET_VALID_STATE when text
		object status changes

CALLED BY:	MSG_META_TEXT_EMPTY_STATUS_CHANGED
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= IrlapAddressControlClass instance data
		ds:bx	= IrlapAddressControlClass object (same as *ds:si)
		es 	= segment of IrlapAddressControlClass
		ax	= message #
		-------------------
		cx:dx	= test obj
		bp	= non-zero if text is becoming non-empty
			  zero if becoming empty
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACMetaTextEmptyStatusChanged	method dynamic IrlapAddressControlClass, 
					MSG_META_TEXT_EMPTY_STATUS_CHANGED
		uses	ax, cx
		.enter
		mov	cx, bp
		jcxz	testEmpty
		mov	cx, TRUE		; cx = whether status is valid
testEmpty:
		mov	ax, MSG_SOCKET_ADDRESS_CONTROL_SET_VALID_STATE
		mov	di, offset IrlapAddressControlClass
		call	ObjCallSuperNoLock
		.leave
		ret
IACMetaTextEmptyStatusChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACIrlapAddrGetAddrStr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to qauery message from IrlapAddrCtrlAddressList by
		returning an address string

CALLED BY:	MSG_IRLAP_ADDR_GET_ADDR_STR
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= IrlapAddressControlClass instance data
		ds:bx	= IrlapAddressControlClass object (same as *ds:si)
		es 	= segment of IrlapAddressControlClass
		ax	= message #
		bp	= index of address string to return
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACIrlapAddrGetAddrStr	method dynamic IrlapAddressControlClass, 
					MSG_IRLAP_ADDR_GET_ADDR_STR
		.enter
	;
	; Find appropriate address string in ICAI_discoveryLogs
	;
		mov	bx, ds:[di].IACI_discoveryLogs
		call	MemLock
		mov	cx, ax
		mov	ax, size DiscoveryLog
		mov	dx, bp
		mul	dl
		add	ax, size DiscoveryLogBlock + DL_info
		mov_tr	dx, ax
	;
	; Send a message to IrlapAddrCtrlAddressList
	;
		push	bx
		mov	bx, ds:[di].IACI_childBlock
		mov	si, offset IrlapAddrCtrlAddressList
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjMessage
		pop	bx
		call	MemUnlock
		
		.leave
		ret
IACIrlapAddrGetAddrStr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACIrlapAddrDiscoveryDismiss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dismisses discovery dialog

CALLED BY:	MSG_IRLAP_ADDR_DISCOVERY_DISMISS
PASS:		*ds:si	= IrlapAddressControlClass object
		ds:di	= IrlapAddressControlClass instance data
		ds:bx	= IrlapAddressControlClass object (same as *ds:si)
		es 	= segment of IrlapAddressControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACIrlapAddrDiscoveryDismiss	method dynamic IrlapAddressControlClass, 
					MSG_IRLAP_ADDR_DISCOVERY_DISMISS
		.enter
	;
	; Dismiss discovery dialog
	;
		mov	bx, ds:[di].IACI_childBlock
		mov	si, offset IrlapAddrCtrlDiscoveryDialog
		mov	cx, IC_DISMISS
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		call	ObjMessage
		
		.leave
		ret
IACIrlapAddrDiscoveryDismiss	endm



IrlapActionCode		ends
