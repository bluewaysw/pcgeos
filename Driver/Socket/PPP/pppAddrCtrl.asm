COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
			
			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		PPP Driver
FILE:		pppAddrCtrl.asm

AUTHOR:		Jennifer Wu, Apr 20, 1995

ROUTINES:
	Name				Description
	----				-----------
	PPPACGetInfo
	PPPACInitialize

	PPPACGenerateUI

	PPPACGetAddresses
	PPPACGetPhoneNumber
	PPPACGetAccessPoint
	PPPACStoreAccessName

	PPPACSetAddresses
	
	PPPACTextEmptyStatusChanged

	PPPSpecialTextCut		(aka PPPSpecialTextCopy)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	4/20/95		Initial revision

DESCRIPTION:
	Code for PPP address controller and password dialog.

	$Id: pppAddrCtrl.asm,v 1.6 96/04/03 14:52:34 jwu Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


AddressCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPACGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the info structure needed by the PPP address 
		controller.

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= PPPAddressControlClass object
 		es 	= segment of PPPAddressControlClass
		cx:dx	= GenControlBuildInfo structure to fill in

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	GenControlBuildInfo structure filled in


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	4/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPACGetInfo	method dynamic PPPAddressControlClass, 
					MSG_GEN_CONTROL_GET_INFO
		uses	cx
		.enter

		mov	si, offset pppBuildInfo
		segmov	ds, cs			; ds:si = source
		mov	es, cx
		mov	di, dx			; es:di = dest
		mov	cx, size GenControlBuildInfo
		rep	movsb

		.leave
		ret
PPPACGetInfo	endm

pppBuildInfo	GenControlBuildInfo <
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST,	; GCBI_flags
	0,					; GCBI_initFileKey
	0,					; GCBI_gcnList
	0,					; GCBI_gcnCount
	0,					; GCBI_notificationList
	0,					; GCBI_notificationCount
	0,					; GCBI_controllerName

	handle PPPAddrCtrlDialog,		; GCBI_dupBlock
	pppChildList,				; GCBI_childList
	length pppChildList,			; GCBI_childCount
	pppFeaturesList,			; GCBI_featuresList
	length pppFeaturesList,			; GCBI_featuresCount
	1,					; GCBI_features
	0,					; GCBI_toolBlock
	0,					; GCBI_tookList
	0,					; GCBI_toolCount
	0,					; GCBI_toolFeaturesList
	0,					; GCBI_toolFeaturesCount
	0,					; GCBI_toolFeatures

	0,					; GCBI_helpContext
	0>					; GCBI_reserved

if _FXIP
ControlInfoXIP	segment resource
endif

pppChildList	GenControlChildInfo \
	<offset PPPAddrCtrlDialog,
	 0,
	 mask GCCF_IS_DIRECTLY_A_FEATURE or mask GCCF_ALWAYS_ADD>

pppFeaturesList GenControlChildInfo \
	<offset PPPAddrCtrlDialog,
	 0,
	 1>

if _FXIP
ControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPACInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to initialize instance data to non-zero defaults.

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= PPPAddressControlClass object
		ds:di	= PPPAddressControlClass instance data
		ds:bx	= PPPAddressControlClass object (same as *ds:si)
		es 	= segment of PPPAddressControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		call superclass
		set SACI_geode to this driver's handle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	4/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPACInitialize	method dynamic PPPAddressControlClass, 
					MSG_META_INITIALIZE

		mov	di, offset PPPAddressControlClass
		call	ObjCallSuperNoLock

		mov	ax, handle 0
		mov	di, ds:[si]
		add	di, ds:[di].PPPAddressControl_offset
		mov	ds:[di].SACI_geode, ax

		ret
PPPACInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPACGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the opportunity to set the output of the text object
		so we can get the empty status changed message.

CALLED BY:	MSG_GEN_CONTROL_GENERATE_UI
PASS:		*ds:si	= PPPAddressControlClass object
		es 	= segment of PPPAddressControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Set output of text object to the controller.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPACGenerateUI	method dynamic PPPAddressControlClass, 
					MSG_GEN_CONTROL_GENERATE_UI
		uses	ax, cx, dx, bp
		.enter

		mov	di, offset PPPAddressControlClass
		call	ObjCallSuperNoLock
	;
	; Set output of text object to the controller so we can
	; get the empty status changed message.
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData

		mov	cx, ds:[LMBH_handle]	
		mov	dx, si				; ^lcx:dx = controller
		mov	bx, ds:[bx].TGCI_childBlock
EC <		tst	bx						>
EC <		ERROR_Z PPP_MISSING_CHILD_BLOCK				>
		mov	si, offset PhoneText
		mov	ax, MSG_VIS_TEXT_SET_OUTPUT
		mov	di, mask MF_CALL
		call	ObjMessage			; destroys ax,cx,dx,bp

		.leave
		ret
PPPACGenerateUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPACGetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the block of data that holds the address selected
		by the user.

CALLED BY:	MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES
PASS:		*ds:si	= PPPAddressControlClass object
		es 	= segment of PPPAddressControlClass

RETURN:		if ok:
			ax = ChunkArray of SACAddress structures in same 
			     block as controller
		else
			ax = 0

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
	Get phone number from text object into stack buffer
	If phone number length is non-zero,
	    store length in addrLen and nameLen
	    store link type as LT_ADDR
	else ask access point UI for ID
	    if none, return 0
	    else store ID in addr buffer 
	         store link type as LT_ID
	         get username into a block and store namelen

	allocate chunk array and an element 
	   (size of element equals addrLen + nameLen + some extra bytes)
	if failed, free array, free block if allocated
	else
	    store opaqueSize from addrLen
	    store link type
	    copy addrBuffer to element
	    if phone number,
	       copy addr buffer again (user readable addr)
	    else 
	       lock username block and copy to element

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	4/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPACGetAddresses	method dynamic PPPAddressControlClass, 
				MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES
addrBuffer	local	MAX_PHONE_NUMBER_LENGTH_ZT dup (TCHAR)
opaqSize	local	word			
userBlk		local	hptr
userSize	local	word
addrType	local	LinkType

		.enter
	;
	; Get phone number from text object.
	;
		mov	userBlk, 0

		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData
		mov	bx, ds:[bx].TGCI_childBlock
EC <		tst	bx						>
EC <		ERROR_Z PPP_MISSING_CHILD_BLOCK				>

		mov 	addrType, LT_ADDR		; assume a number
		call	PPPACGetPhoneNumber		
		tst	ax
		jnz	makeArray
	;
	; Get access point info instead.
	;
		mov	addrType, LT_ID			; assume access ID
		call	PPPACGetAccessPoint		
		jc	exit
makeArray:
	;
	; Store address sizes, create chunk array and allocate element.
	;
		mov	opaqSize, ax
		mov	userSize, cx

		clr	bx, cx, si, ax		; var size, default hdr,
						;  alloc a chunk, no flags
		call	ChunkArrayCreate	; *ds:si = array
		jc	noAddr

		mov	cx, opaqSize
		mov	ax, cx
		add	ax, userSize
		add	ax, PPP_EXTRA_ADDR_SPACE
		call	ChunkArrayAppend	; ds:di = SACAddress
		jnc	storeAddr

		mov_tr	ax, si	
		call	LMemFree		; free array
noAddr:
		clr	ax
		jmp	done
storeAddr:
	;
	; Store opaque address size, link type, and opaque address.
	;
		segmov	es, ds			; es:di = SACAddress
		mov	ax, cx			; ax = opaque size
		inc	ax			; include byte for link type
		stosw				; store opaque size

		mov	al, addrType		
		stosb

		mov_tr	ax, si			; *ds:ax = array
		segmov	ds, ss, si
		lea	si, addrBuffer		; ds:si = address
		push	si, cx
		rep	movsb
		pop	si, cx
	;
	; If using phone number, store the addrBuffer contents again.
	;
		cmp	addrType, LT_ID
		je	storeName

		inc	cx			; include null this time
DBCS <		inc	cx					>
		rep	movsb
		jmp	exit
storeName:
		call	PPPACStoreAccessName
done:
		mov	bx, userBlk
		tst	bx
		je	exit
		call	MemFree
exit:
		.leave
		ret

PPPACGetAddresses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPACGetPhoneNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the phone number, if any.

CALLED BY:	PPPACGetAddresses

PASS:		bx 	= handle of child block
		inherited stack frame

RETURN:		ax = opaque address size (no null)
		cx = user readable address size (no null)
		addrBuffer filled in

DESTROYED:	dx, di, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/18/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPACGetPhoneNumber	proc	near

		.enter	inherit PPPACGetAddresses

		push	bp
		mov	si, offset PhoneText
		mov	dx, ss
		lea	bp, addrBuffer		; dx:bp = dest for #
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cx = len (no null)
		pop	bp

DBCS <		shl	cx					>
		mov	ax, cx

		.leave
		ret
PPPACGetPhoneNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPACGetAccessPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get selected access point ID and access point name, if any.

CALLED BY:	PPPACGetAddresses

PASS:		bx	= handle of child block
		inherited stack frame

RETURN:		carry set if no access point
		else
			ax = opaque address size
			cx = user readable address size
			userBlk filled with handle of acc pnt name, if any
			addrBuffer filled with ID

DESTROYED:	dx, di, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/18/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPACGetAccessPoint	proc	near
		
		.enter	inherit PPPACGetAddresses
	;
	; Get access point ID from access point controller.
	;
		mov	si, offset AccPntUI		; ^lbx:si = AccPntUI
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ax = acc pnt ID (0 if none)

		tst	ax
		je	none
		mov	{word} ss:[addrBuffer], ax
	;
	; Get user name allocated into a block.  If none, then the 
	; link will have no user readable part.
	;
		push	bp
		clr	cx, bp			; standard property, alloc blk
		mov	dx, APSP_NAME
		call	AccessPointGetStringProperty	; cx = len, bx = blk
		pop	bp
		jnc	haveResult
		clr	bx, cx
haveResult:

DBCS <		shl	cx						>
		mov	userBlk, bx
		mov	ax, size word
		clc				
		jmp	exit
none:
		stc
exit:
		.leave
		ret
PPPACGetAccessPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPACStoreAccessName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the name from the name block into the SACAddress.

CALLED BY:	PPPACGetAddresses

PASS:		es:di 	= destination for name
		inherited stack frame

RETURN:		nothing

DESTROYED:	bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/18/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPACStoreAccessName	proc	near
		uses	ax
		.enter	inherit PPPACGetAddresses
	;
	; If no name, just store a null terminator.
	;
		mov	cx, userSize
		jcxz	storeNull

EC <		tst	userBlk					>
EC <		ERROR_E	-1	; missing name block!		>

		mov	bx, userBlk
		call	MemLock
		mov	ds, ax
		clr	si				; ds:si = name
		rep	movsb
		call	MemUnlock
storeNull:
		clr	ax
		LocalPutChar	esdi, ax

		.leave
		ret
PPPACStoreAccessName	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPACSetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current user-editable address to the passed 
		address.

CALLED BY:	MSG_SOCKET_ADDRESS_CONTROL_SET_ADDRESSES
PASS:		*ds:si	= PPPAddressControlClass object
		ds:di	= PPPAddressControlClass instance data
		es 	= segment of PPPAddressControlClass
		^lcx:dx	= ChunkArray of SACAddress structures
			  (SACAddress contains combined link and IP
			   addresses in ESACAddress format)

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		If opaque link address size is non-zero
			If link type is LT_ID,
				set the selection in AccPntUI
			else (link type is LT_ADDR)
				store opaque link address in PhoneText

NOTES:  	This is the only place where PPP is aware of the 
		ESACAddress format.  This is inconsistent, but it
		makes life much simpler for the IP address controller.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	4/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPACSetAddresses	method dynamic PPPAddressControlClass, 
					MSG_SOCKET_ADDRESS_CONTROL_SET_ADDRESSES
	;
	; Get child block.
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData		; ds:bx = the data
		mov	si, dx			; ^lcx:si = SACA array
		mov	dx, ds:[bx].TGCI_childBlock
		tst	dx
EC <		WARNING_E PPP_NO_CHILDREN_FOR_SET_ADDRESSES	>
		je	exit
	;
	; Locate SACAddress.
	;
		mov	bx, cx			
		call	ObjLockObjBlock
		mov	ds, ax			; *ds:si = SACA array

		call	ChunkArrayGetCount			
EC <		cmp	cx, 1						>
EC <		WARNING_NE PPP_NOT_SINGLE_ADDRESS			>
		jcxz	unlockArray

		clr	ax
		call	ChunkArrayElementToPtr	; ds:di = SACAddress, cx = size
		lea	si, ds:[di].SACA_opaque
		lodsw	
		mov_tr	cx, ax			; cx = link size 
		jcxz	unlockArray

		lodsb				; al = LinkType
		dec	cx

		push	bx			; save SAC array handle
		mov	bx, dx			; bx = child block
		cmp	al, LT_ADDR
		jne	useAccPnt
	;
	; Display phone number.  Have to copy to stack first because
	; the array may be in same block as us.
	;
		sub	sp, cx 
		movdw	dxbp, sssp		; dx:bp = phone number
		movdw	esdi, dxbp
		push	cx
		push	cx
		rep	movsb

		pop	cx
		mov	si, offset PhoneText	; ^lbx:si = text object
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, mask MF_CALL
		call	ObjMessage

		pop	cx
		add	sp, cx
		jmp	popUnlock
useAccPnt:
	;
	; Clear out phone number text object and display selected 
	; access point.
	;
		mov	cx, ds:[si]		; cx = access point ID

		push	cx
		mov	si, offset PhoneText
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx

		mov	si, offset AccPntUI
		mov	ax, MSG_ACCESS_POINT_CONTROL_SET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage
popUnlock:
		pop	bx			; ^hbx = SAC array block
unlockArray:
		call	MemUnlock
exit:
		ret

PPPACSetAddresses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPACTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The phone text object has either become empty or not empty.

CALLED BY:	MSG_META_TEXT_EMPTY_STATUS_CHANGED
PASS:		*ds:si	= PPPAddressControlClass object
		es 	= segment of PPPAddressControlClass
		bp	= non-zero if text is becoming non-empty
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Enable AccPntUI if text is becoming empty, else
		disable AccPntUI.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPACTextEmptyStatusChanged	method dynamic PPPAddressControlClass, 
					MSG_META_TEXT_EMPTY_STATUS_CHANGED
		uses	ax, cx, dx, bp
		.enter
	;
	; Get the child block and set up params for call.
	; Enable if text object is becoming empty.  Else disable.
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData
EC <		tst	bx						>
EC <		ERROR_Z PPP_MISSING_CHILD_BLOCK				>

		mov	bx, ds:[bx].TGCI_childBlock
		mov	si, offset AccPntUI
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL

		mov	ax, MSG_GEN_SET_ENABLED
		tst	bp
		je	sendMsg			
		mov	ax, MSG_GEN_SET_NOT_ENABLED
sendMsg:
		call	ObjMessage

		.leave
		ret
PPPACTextEmptyStatusChanged	endm


AddressCode	ends

;---------------------------------------------------------------------------
;
;			Code for PPP Password Dialog
;
;---------------------------------------------------------------------------

PPPTextCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PPPSpecialTextCut/PPPSpecialTextCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to prevent cut and copy.

CALLED BY:	MSG_META_CLIPBOARD_CUT/COPY
PASS:		*ds:si	= PPPSpecialTextClass object
		ds:di	= PPPSpecialTextClass instance data
		
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Do nothing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/ 1/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PPPSpecialTextCut	method dynamic PPPSpecialTextClass, 
					MSG_META_CLIPBOARD_CUT,
					MSG_META_CLIPBOARD_COPY

		mov	ax, SST_NO_INPUT
		call	UserStandardSound
		ret
PPPSpecialTextCut	endm


PPPTextCode	ends
