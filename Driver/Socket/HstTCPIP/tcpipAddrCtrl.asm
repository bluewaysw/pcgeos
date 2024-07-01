COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

			GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		
FILE:		tcpipAddrCtrl.asm

AUTHOR:		Jennifer Wu, Oct 31, 1994

ROUTINES:
	Name				Description
	----				-----------
	IPAddressControlGetInfo
	IPAddressControlGenerateUI
	IPAddressControlInitialize
	IPAddressControlDestroy	

	IPAddressControlGetAddresses
	IPAddressControlSetAddresses

	IPAddressControlAddChild 	Add address controller of link
					driver as a child, if any
	IPAddressControlBuildAddress	Build extended SACAddress
	IPAddressControlComputeSize	Compute size of new SACAddress element
	IPAddressControlCopyInfo	Copy the link info to the new SACAddress
					and add IP info to it.

	IPParseDecimalAddr		Parse a dotted-decimal IP address 
					into its binary form

	IPAddressTextEmptyStatusChanged

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/31/94		Initial revision

DESCRIPTION:
	Code for IP Address Controller.

	$Id: tcpipAddrCtrl.asm,v 1.20 97/12/17 21:07:21 jwu Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddressCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the info structure needed by the IP address 
		controller.

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= IPAddressControlClass object
		es 	= segment of IPAddressControlClass
		cx:dx	= GenControlDupInfo structure to fill in
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	GenControlBuildInfo structure filled

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressControlGetInfo	method dynamic IPAddressControlClass, 
					MSG_GEN_CONTROL_GET_INFO
		uses	cx
		.enter

		mov	si, offset IPC_dupInfo
		segmov	ds, cs				; ds:si = source
		mov	es, cx
		mov	di, dx				; es:di = dest
		mov	cx, size GenControlBuildInfo
		rep	movsb

		.leave
		ret
IPAddressControlGetInfo	endm

IPC_dupInfo	GenControlBuildInfo <
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST,	;GCBI_flags
	0,					; GCBI_initFileKey
	0,					; GCBI_gcnList
	0,					; GCBI_gcnCount
	0,					; GCBI_notificationList
	0,					; GCBI_notificationCount
	0,					; GCBI_controllerName

	handle IPAddrCtrlDialog,		; GCBI_dupBlock
	IPC_childList,				; GCBI_childList
	length IPC_childList,			; GCBI_childCount
	IPC_featuresList,			; GCBI_featuresList
	length IPC_featuresList,		; GCBI_featuresCount
	1,					; GCBI_features
	0,					; GCBI_toolBlock
	0,					; GCBI_toolList
	0,					; GCBI_toolCount
	0,					; GCBI_toolFeaturesList
	0,					; GCBI_toolFeaturesCount
	0,					; GCBI_toolFeatures 	

	0,					; GCBI_helpContext
	0>					; GCBI_reserved

if _FXIP
ControlInfoXIP	segment	resource
endif

IPC_childList	GenControlChildInfo	\
	< offset IPAddrCtrlDialog,
	  0,
	  mask GCCF_IS_DIRECTLY_A_FEATURE or mask GCCF_ALWAYS_ADD>

IPC_featuresList GenControlFeaturesInfo	\
	< offset IPAddrCtrlDialog,
	  0,
	  1>

if _FXIP
ControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the UI for the controller, adding any child
		address controllers.  Also take the opportunity to set
		the output of the text object so we can get the empty
		status changed message.

CALLED BY:	MSG_GEN_CONTROL_GENERATE_UI
PASS:		*ds:si	= IPAddressControlClass object
		es	= segment of IPAddressControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Call superclass
		If link address controller is not already instantiated,
			Add the link driver's address controller as a child, 
			if any.  
			Set output of text object to the controller.
		Else just return 

NOTES:		A zero link address controller field in instance data 
		may mean the link driver has no address controller but
		checking link address controller is easier than checking
		the output of the text object.  (Link address controller
		isn't destroyed until IP address controller is destroyed.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	11/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressControlGenerateUI	method dynamic IPAddressControlClass, 
					MSG_GEN_CONTROL_GENERATE_UI
		uses	ax, cx, dx, bp
		.enter
	;
	; Remember this message has been handled already while we 
	; still have a pointer to instance data, then call superclass.
	;
		mov	bl, TRUE
		xchg	bl, ds:[di].IPACI_addedChild

		mov	di, offset IPAddressControlClass
		call	ObjCallSuperNoLock
	;
	; Only instantiate the link address controller once.  It doesn't
	; get destroyed until this controller is destroyed.
	;
		tst	bl
		jne	setOutput			; already added child

		call	IPAddressControlAddChild
setOutput:
	;
	; Set output of text object to the controller so we can get
	; the empty status changed message.
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData

		mov	cx, ds:[LMBH_handle]
		mov	dx, si				; ^lcx:dx = controller
		mov	bx, ds:[bx].TGCI_childBlock
		mov	si, offset IPAddrCtrlText
		mov	ax, MSG_VIS_TEXT_SET_OUTPUT
		mov	di, mask MF_CALL
		call	ObjMessage			; destroys ax,cx,dx,bp

		.leave
		ret
IPAddressControlGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressControlInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to initialize instance data to non-zero defaults.

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= IPAddressControlClass object
		ds:di	= IPAddressControlClass instance data
		es 	= segment of IPAddressControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		call superclass
		set SACI_geode to this driver's handle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	12/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressControlInitialize	method dynamic IPAddressControlClass, 
					MSG_META_INITIALIZE
		
		mov	di, offset IPAddressControlClass
		call	ObjCallSuperNoLock

		mov	ax, handle 0
		mov	di, ds:[si]		; ds:di = instance data
		add	di, ds:[di].IPAddressControl_offset
		mov	ds:[di].SACI_geode, ax

		ret
IPAddressControlInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressControlDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to destroy link address controller, if any.  

CALLED BY:	MSG_GEN_DESTROY
PASS:		*ds:si	= IPAddressControlClass object
		ds:di	= IPAddressControlClass instance data
		es 	= segment of IPAddressControlClass
		ax	= message #
		dl	= VisUpdateMode
		bp	= mask CCF_MARK_DIRTY if we want to mark parent as
			  dirty
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

NOTES:		This has to be done because the link address controller
		isn't allocated in the child block.  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressControlDestroy	method dynamic IPAddressControlClass, 
					MSG_GEN_DESTROY
	;
	; If link address controller exists, destroy it so 
	; the ref count for the link driver will be decremented.
	;
		mov	ax, ATTR_GEN_CONTROL_APP_UI
		call	ObjVarFindData			; ds:bx = data
		jnc	callSuper

		push	dx, bp, si
		mov	si, ds:[bx].chunk
		mov	bx, ds:[bx].handle		; ^lbx:si = link ctrllr
		mov	ax, MSG_GEN_DESTROY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	dx, bp, si
callSuper:
		mov	ax, MSG_GEN_DESTROY
		mov	di, offset IPAddressControlClass
		call	ObjCallSuperNoLock

		ret
IPAddressControlDestroy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressControlGetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the block of data that holds the addresses selected
		by the user.  The controller allocates the chunk array 
		in its own object block and returns the chunk handle.

CALLED BY:	MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES
PASS:		*ds:si	= IPAddressControlClass object
		ds:di	= IPAddressControlClass instance data

RETURN:		if ok:
			*ds:ax = ChunkArray of SACAddress structures
		else 	
			ax = 0

DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

		Get link address.

		Build the SACAddress structure, appending what the user
		entered in the text object to transparent part and opaque
		parts of of link address to get the extended address.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressControlGetAddresses	method dynamic IPAddressControlClass, 
				MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES

ipAddrBuffer	local	MAX_IP_ADDR_STRING_LENGTH_ZT dup (TCHAR)
ipAddrLen	local	word
linkSACArray	local	word			
linkOpaqueSize	local	word
linkTotalSize	local	word
		.enter
	;
	; Get the link address from the child controller.
	;
		clr	ax
		mov	linkOpaqueSize, ax
		mov	linkTotalSize, ax
		mov	linkSACArray, ax
		mov	ax, ATTR_GEN_CONTROL_APP_UI
		call	ObjVarFindData		; ds:bx = data
		jnc	getIPAddr			

		push	si
		mov	si, ds:[bx].chunk
		mov	bx, ds:[bx].handle	; ^lbx:si = link addr ctrllr
		mov	ax, MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ax = chunk array of SACAddress 
		pop	si

		mov	linkSACArray, ax
	;
	; Get the address string from the text object.
	;		
getIPAddr:
		push	bp
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData
		
		mov	bx, ds:[bx].TGCI_childBlock
		mov	si, offset IPAddrCtrlText
 		mov	dx, ss
		lea	bp, ipAddrBuffer	; dx:bp = place for string
		
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cx = length (not counting null)
		pop	bp
	;
	; Build the extended SACAddress, combining the link address
	; and text entered by the user.
	;
		mov	ipAddrLen, cx
		call	IPAddressControlBuildAddress

		.leave
		ret
IPAddressControlGetAddresses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressControlSetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current user-editable address to be the passed one.

CALLED BY:	MSG_SOCKET_ADDRESS_CONTROL_SET_ADDRESSES
PASS:		*ds:si	= IPAddressControlClass object 
		ds:di	= IPAddressControlClass instance data
		^lcx:dx	= chunk array of SACAddress structures
		ax	= message

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If there are mulitple address, only use the first one.
	Tcp address may or may not exist.  If it does, it ends when
	the user readable part encounters a left paren.  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 8/95   	Initial version
	jwu	4/ 6/95		Added link addr controller support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressControlSetAddresses	method dynamic IPAddressControlClass, 
				MSG_SOCKET_ADDRESS_CONTROL_SET_ADDRESSES
	;
	; Pass along the address to the link address controller, if any.
	; The link address controller is responsible for finding the
	; user readable link address in the chunk array.
	;
		mov	ax, ATTR_GEN_CONTROL_APP_UI
		call	ObjVarFindData
		jnc	setOurPart
		
		push	cx, dx, di, si
		mov	si, ds:[bx].chunk
		mov	bx, ds:[bx].handle	; ^lbx:si = link addr ctrllr
		mov	ax, MSG_SOCKET_ADDRESS_CONTROL_SET_ADDRESSES
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx, dx, di, si
setOurPart:
	;
	; Get child block.
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData		; ds:bx = the data
		mov	si, dx			; ^lcx:si = SACA array
		mov	dx, ds:[bx].TGCI_childBlock
		tst	dx
EC <		WARNING_E TCPIP_NO_CHILD_FOR_SET_ADDRESSES	>
		LONG	je	done			
		mov	bx, cx			; ^lbx:si = SACA array
	;
	; Locate SACAddress.
	;
		call	ObjLockObjBlock		; ax = sptr
		mov	ds, ax			; *ds:si = array
		call	ChunkArrayGetCount	; cx = count
EC <		cmp	cx, 1						>
EC <		WARNING_NE TCPIP_NOT_SINGLE_ADDRESS			>
		jcxz	unlockArray		; ignore if no address

		clr	ax			; get first elt
		call	ChunkArrayElementToPtr	; ds:di = SACAddress, cx = size
	;
	; If first character is a left paren, there is no ip address.
	;		
		lea	si, ds:[di].SACA_opaque
		add	si, ds:[di].SACA_opaqueSize  ; ds:si = transp. tcp addr
		LocalCmpChar	ds:[si], C_LEFT_PAREN
		je	unlockArray
	;
	; Find the end of the tcp address in the user-readable string and 
	; copy onto stack (because the array may be in the same block as us)
	; 
		sub	sp, MAX_IP_ADDR_STRING_LENGTH_ZT * size TCHAR
		movdw	esdi, dssi
		call	LocalStringLength	; cx = addr length (no null)
EC <		tst	cx					>
EC <		ERROR_Z TCPIP_ADDRESS_CORRUPTED			>

		mov	ax, C_LEFT_PAREN
		LocalFindChar			
		jne	copyIt			; no need to backup pointer

		LocalPrevChar	esdi		; exclude left paren
		LocalPrevChar	esdi		; exclude space 
copyIt:
		mov	cx, di
		sub	cx, si			; cx = tcp addr size
EC <		Assert	be, cx, MAX_IP_ADDR_STRING_LENGTH * size TCHAR >
		movdw	esdi, sssp
		shr	cx
		rep	movsw
		jnc	addNull
		movsb
addNull:
		mov	ax, C_NULL
		LocalPutChar	esdi, ax
		call	MemUnlock		; unlock SACAddress array
	;
	; Pass the string to our text object.
	;
		mov	bx, dx
		mov	si, offset IPAddrCtrlText	; ^lbx:si = text object
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		movdw	dxbp, sssp		; dx:bp = addr string to use
		clr	cx			; null terminated
		mov	di, mask MF_CALL	; we're passing a buffer ...
		call	ObjMessage
		add	sp, MAX_IP_ADDR_STRING_LENGTH_ZT * size TCHAR
done:
		ret

unlockArray:
		call	MemUnlock		
		jmp	done

IPAddressControlSetAddresses	endm

;--------------------------------------------------------------------------
;			Subroutines
;--------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressControlAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the address controller of the main link driver
		as a child, if the link driver has an address controller.

CALLED BY:	IPAddressControlGenerateUI	

PASS:		*ds:si	= IPAddressControlClass object
		es	= segment of IPAddressControlClass

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	ax, bx, cx, dx, di, es (allowed/preserved by caller)

PSEUDO CODE/STRATEGY:
		If main link driver is not loaded,
			load it and get its strategy routine 
		query link driver for the address controller
		unload link driver

		if have child {
			instantiate controller in this object block
			store optr in instance data
			add controller as last child
			set controller usable
		}

NOTES:		Link address controller is not instantiated in the 
		child block (as children normally are) to minimize
		the number of times the link driver has to be loaded
		to get the link address controller's class.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/ 6/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressControlAddChild	proc	near
		uses	si
linkDrvr	local	hptr
linkStrategy	local	fptr
		.enter
		class	IPAddressControlClass
	;	
	; Find out if link driver is loaded or not.  If loaded, get
	; its strategy routine, else load the driver and get the 
	; strategy routine from there.
	;
		mov	linkDrvr, 0
		push	ds
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		;call	LinkTableGetEntry	; ds:di = LCB
						; ^hbx = link table
		movdw	linkStrategy, ds:[di].LCB_strategy, ax
		mov	ax, ds:[di].LCB_drvr
		call	MemUnlockExcl
		pop	ds

		tst	ax
		jnz	driverLoaded

		;call	LinkLoadLinkDriverFar	; bx = driver handle
		LONG	jc	exit
		mov	linkDrvr, bx

		push	ds, si
		call	GeodeInfoDriver		; ds:si = DriverInfoStruct
		movdw	linkStrategy, ds:[si].DIS_strategy, ax
		pop	ds, si
driverLoaded:
	;
	; Query the link driver for its address controller.  Then unload
	; link driver if loaded just for the query.
	;
		mov	ax, SGIT_ADDR_CTRL
		mov	di, DR_SOCKET_GET_INFO
		pushdw	linkStrategy		
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; cx:dx = addr ctrl class
		lahf

		tst	linkDrvr
		jz	checkChild

		mov	bx, linkDrvr
		;call	LinkUnloadLinkDriverFar
checkChild:
	;
	; If there is a child, instantiate the controller in this object
	; block and store optr in instance data.  
	;
		sahf
		jc	exit

		push	si			; save object chunk handle
		mov	es, cx
		mov	di, dx
		mov	bx, ds:[LMBH_handle]	; handle of our object block
		call	ObjInstantiate		; *ds:si = link controller

		mov	cx, bx
		mov	dx, si			; ^lcx:dx = link controller
		pop	si			; *ds:si = IP addr controller
	;
	; Make the link controller be APP_UI to avoid the optimized
	; controller unbuilding and one-way linkage problems.
	; 
		push	cx
		mov	ax, ATTR_GEN_CONTROL_APP_UI
		mov	cx, size optr
		call	ObjVarAddData		; ds:bx = extra data
		pop	cx
		movdw	ds:[bx], cxdx
	;
	; Add link controller as the last child and then set it usable.
	; Must be last child because APP_UI will be added after normal
	; children are added.
	;
		push	bp
		mov	bp, CCO_LAST
		mov	ax, MSG_GEN_ADD_CHILD
		call	ObjCallInstanceNoLock
		
		movdw	bxsi, cxdx		; ^bx:si = link controller
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_USABLE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
exit:
		.leave
		ret
IPAddressControlAddChild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressControlBuildAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate chunk array in object block and build an 
		extended SACAddress, combining link address and IP 
		address entered by user.

CALLED BY:	IPAddressControlGetAddresses

PASS:		*ds:si 	= IPAddressControlClass
		cx	= ipAddrLen
		inherited stack frame from IPAddressControlGetAddresses
		  (only ipAddrBuffer, ipAddrLen, linkSACArray filled in,
		   linkTotalSize and linkOpaqueSize initialized to zero)

RETURN:		if okay:
			*ds:ax	= chunk array of SACAddress structures 
				  containing extended SACAddress info 
		else
			ax	= 0
DESTROYED:	ax, bx, cx, dx, di, si, ds, es  (allowed/preserved by caller)

PSEUDO CODE/STRATEGY:
		If no IP address and no link address, just return because
			ax is already zero  (ain't that dandy?)
		Else, compute size of chunk array to allocate
		copy information into the chunk array

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/ 6/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressControlBuildAddress	proc	near
		.enter	inherit IPAddressControlGetAddresses
	;
	; If no link nor IP address, then don't do anything.  
	;
		tst	linkSACArray
		jnz	makeAddr
		jcxz	noAddr
makeAddr:
	;
	; Allocate variable sized chunk array to contain SACAddress struct.
	;
		push	cx
		clr	bx, cx, si, ax		; variable-sized, default hdr
						; alloc a chunk, no flags
		call	ChunkArrayCreate	; *ds:si = chunk array
		pop	cx
		jc	noAddr
	;
	; Compute size of SACAddress element to allocate and then fill
	; in the structure.  
	;
		call	IPAddressControlComputeSize	; ax = element size
		call	ChunkArrayAppend		; ds:di = new element
		jc	giveUp

		call	IPAddressControlCopyInfo
		jmp	freeLinkSAC
giveUp:
	;
	; Free newly allocated chunk array.
	;
		mov_tr	ax, si
		call	LMemFree
		clr	si				; for return value
freeLinkSAC:
		mov	ax, linkSACArray
		tst	ax
		jz	setVal
		call	LMemFree
setVal:
		mov_tr	ax, si				; return value
		jmp	exit
noAddr:
		clr	ax
exit:
		.leave
		ret
IPAddressControlBuildAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressControlComputeSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute size of SACAddress element to allocate.

CALLED BY:	IPAddressControlBuildAddress

PASS:		cx	= length of IP address (not including null)
		inherited stack frame from IPAddressControlGetAddresses
		  (only ipAddrBuffer, ipAddrLen, linkSACArray filled in,
		   linkTotalSize and linkOpaqueSize initialized to zero)

RETURN:		ax	= size for element

DESTROYED:	nothing

SIDE EFFECTS:
		fills in linkTotalSize and linkOpaqueSize in stack frame

PSEUDO CODE/STRATEGY:

		It's okay to allocate a few bytes extra space because
		the user readable part is a null-terminated string so 
		the end can be reliably found.

		So, the size returned will be:
			2*size of ip address + size of link address + 
			TCPIP_MISC_ADDRESS_BYTES
 
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/ 6/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressControlComputeSize	proc	near
		uses	cx, di, si
		.enter	inherit IPAddressControlGetAddresses
	
		mov_tr	ax, cx			; ax = IP addr length
DBCS <		shl	ax						>
		shl	ax			; room for 2 strings
		add	ax, TCPIP_MISC_ADDRESS_BYTES

		tst	linkSACArray
		jz	done

		push	ax
		mov	si, linkSACArray
		clr	ax
		call	ChunkArrayElementToPtr	; ds:di = link SACAddress
						; cx = size
		mov	ax, ds:[di].SACA_opaqueSize
		mov	linkOpaqueSize, ax
		mov	linkTotalSize, cx	; cx = size of link SACAddress
		pop	ax

		add	ax, cx
done: 
		.leave
		ret
IPAddressControlComputeSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressControlCopyInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the link information to the new SACAddress and
		add in any IP information to form an extended address.	

CALLED BY:	IPAddressControlBuildAddress

PASS: 		ds:di	= SACAddress element to fill in
		inherited stack frame from IPAddressControlGetAddresses
			(all stack vars filled in)
RETURN:		nothing			

DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
		deref link SACAddress

		opaque size = size of opaque link part + 1 byte for link size
				+ size of opaque ip part

		append opaque link address, if any
		append opaque IP address

		append transparent IP address
		replace null terminator with a space
		append an open paren
		append transparent link address, if any
p		replace null terminator with a close paren
		null terminate string

NOTES:
		Routine takes advantage of REP MOVSW not doing anything
		if CX is zero to avoid doing tests and jumps.  Makes
		code cleaner.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/ 6/95			Initial version
	PT	7/24/96			DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressControlCopyInfo	proc	near
		uses	si, es
		.enter	inherit	IPAddressControlGetAddresses

EC <		tst	linkSACArray					>
EC <		jnz	okay						>
EC <		tst	linkOpaqueSize					>
EC <		ERROR_NZ TCPIP_INTERNAL_ERROR	; should be zero!	>
EC <		tst	linkTotalSize					>
EC <		ERROR_NZ TCPIP_INTERNAL_ERROR	; should be zero!	>
EC <okay:								>

	;
	; Deref the link SACAddress element, if any.
	;
		segmov	es, ds, ax			; es:di = dest SACAddress
		tst	linkSACArray
		jz	gotoWork

		push	di
		mov	si, linkSACArray
		clr	ax
		call	ChunkArrayElementToPtr		; ds:di = link SACAddress
							; cx = size
		mov	si, di				; ds:si = link SACAddress
		pop	di				; es:di = dest SACAddress
gotoWork:
	;
	; Compute size of opaque address and stick in SACA_opaqueSize 
	; for dest SACAddress.  
	;
		mov	cx, linkOpaqueSize
		mov	ax, ipAddrLen
DBCS <		shl	ax						>
		inc	ax				; space for link size
		inc	ax
		add	ax, cx
		mov	es:[di].SACA_opaqueSize, ax
		add	di, offset SACA_opaque
	;
	; Start filling in the opaque address.  ES:DI = destination for
	; opaque address.  CX = opaque link address size. 
	;
		mov	es:[di].ESACA_linkSize, cx
		
		add	di, offset ESACA_opaque		; es:di = dest
		add	si, offset SACA_opaque		; ds:si = link opaque
		shr	cx
		rep	movsw
		jnc	doOpaqueIP
		movsb
doOpaqueIP:
	;
	; ES:DI = place for opaque IP address.  
	; DS:SI = user readable link address (null terminated)
	; Do not use LocalCopyString because we don't want null from IP addr.
	;
		mov	cx, ipAddrLen
		jcxz	linkOnly

		push	ds, si				
		segmov	ds, ss, si
		lea	si, ipAddrBuffer		; ds:si = IP addr
		push	si
SBCS <		rep	movsb						>
DBCS <		rep	movsw						>
		pop	si				; ds:si = IP addr still
	;
	; User readable part is IP address, with user-readable link
	; address appended in parentheses.  Must be null terminated.  
	; If no link SACAddress, then stop after copying IP address.  
	; If no Ip address, just do link address in parenthesis.  
	; Must have one or the other!
	; ES:DI = place for user-readable address
	;
		LocalCopyString
		LocalPrevChar	esdi			; es:di points to null
		pop	ds, si				; ds:si = user-readable
							;   link address
		tst	linkSACArray
		jz	exit

		mov	ax, C_SPACE
		LocalPutChar	esdi, ax
linkOnly:		
		mov	ax, C_LEFT_PAREN
		LocalPutChar	esdi, ax

		LocalCopyString
		LocalPrevChar	esdi

		mov	ax, C_RIGHT_PAREN
		LocalPutChar	esdi, ax

		mov	ax, C_NULL
		LocalPutChar	esdi, ax
exit:
		.leave
		ret

IPAddressControlCopyInfo	endp

COMMENT @----------------------------------------------------------------

C FUNCTION:	IPParseDecimalAddr

DESCRIPTION:	Parse an IP address string in x.x.x.x format into a
		binary IP address in network order.

C DECLARATION:	extern dword
		_far _pascal IPParseDecimalAddr (char *addr, int addrLen);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	9/14/95		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
IPPARSEDECIMALADDR	proc	far	addr:fptr.byte,
					addrLen:word
		uses	ds, si
		.enter

		lds	si, addr
		mov	cx, addrLen
		call	IPParseDecimalAddr	
		jnc	exit

		clrdw	dxax
exit:
		.leave
		ret

IPPARSEDECIMALADDR	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPParseDecimalAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse an IP address string in x.x.x.x format into a binary
		IP address.  MUST NOT destroy passed in string!

CALLED BY:	TcpipResolveAddr

PASS:		ds:si	= address string (not null terminated)
		cx	= string length 

RETURN:		carry set if invalid address string
		dx	unchanged
		else
		dxax	= IP address in network order

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if string size is too long, return error

		Warning will get printed more than once but I didn't know
		where else to put it in the loop...

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/31/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPParseDecimalAddr	proc	far
		uses	bx, cx, di, si, es
origDX		local	word		push	dx	
laddr		local	dword		
		.enter
	;
	; Make sure address is a reasonable length, stripping any
	; trailing white space.  Any non-digits end up getting stripped
	; as well.
	;
		push	si
		add	si, cx
DBCS <		add	si, cx						>
		clr	ax
scanLoop:
		LocalPrevChar	dssi			; ds:si = last valid char
		LocalGetChar	ax, dssi, NO_ADVANCE	
		call	LocalIsDigit
		jnz	doneScanning

		dec	cx
		jnz	scanLoop	
doneScanning:
		pop	si

		jcxz	error
		cmp	cx, MAX_IP_DECIMAL_ADDR_LENGTH
		ja	error
	;
	; Convert the string to the binary address, detecting
	; any errors.  Each part of the address must begin with 
	; a digit.  The rest may be a digit or a dot, except for
	; the last part.  Max value of each part is 255.
	;
		lea	di, laddr
		clr	bx				; offset into laddr
digitOnly:
		clr	ax
		LocalGetChar	ax, dssi	
		sub	ax, '0'
		cmp	ax, 9				
		ja	error				; not a digit
		dec	cx
		jz	noMore
digitOrDot:
		clr	dx
		LocalGetChar	dx, dssi
		cmp	dx, '.'
		je	isDot
		sub	dx, '0'
		cmp	dx, 9
		ja	error				; not a digit

		push	cx
		mov	cl, 10
		mul	cl
		pop	cx
		add	ax, dx
		tst	ah
		jnz	error				; overflow

		loop	digitOrDot
		jmp	noMore
isDot:
		mov	ss:[bx][di], al
		inc	bx
		cmp	bx, NUM_DOTS_IN_DECIMAL_IP_ADDR
		ja	error				; too many parts

		loop	digitOnly
		jmp	error				; cannot end with dot
noMore:
	;
	; Store the final value and make sure there are enough
	; parts for a valid IP address.
	;
		mov	ss:[bx][di], al
		cmp	bx, NUM_DOTS_IN_DECIMAL_IP_ADDR
		jne	error

		movdw	dxax, laddr
		jmp	exit				; carry clear
error:
;EC < 		WARNING TCPIP_PARSER_DETECTED_INVALID_ADDRESS		>
		mov	dx, origDX
		stc
exit:
		.leave 
		ret

IPParseDecimalAddr	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPAddressTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The text object has either beocme empty or not empty.

CALLED BY:	MSG_META_TEXT_EMPTY_STATUS_CHANGED
PASS:		*ds:si	= IPAddressControlClass object
		bp	= non-zero if text is becoming non-empty
		es	= segment of IPAddressControlClass
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Send valid message if text object becoming non-empty,
		else send invalid message.

		valid = non-zero bp 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IPAddressTextEmptyStatusChanged	method dynamic IPAddressControlClass, 
					MSG_META_TEXT_EMPTY_STATUS_CHANGED
		uses	ax, cx
		.enter
	;
	; Send set valid message to socket address controller.
	;
		mov	cx, bp			; cx = zero if text is empty
		jcxz	setState		; invalid? 

		mov	cx, TRUE
setState:
		mov	ax, MSG_SOCKET_ADDRESS_CONTROL_SET_VALID_STATE
		mov	di, offset IPAddressControlClass
		call	ObjCallSuperNoLock

		.leave
		ret
IPAddressTextEmptyStatusChanged	endm


AddressCode	ends







