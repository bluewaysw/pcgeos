COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	socket
MODULE:		socket preference module
FILE:		prefsock.asm

AUTHOR:		Steve Jang, Nov  8, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/ 8/94   	Initial revision


DESCRIPTION:
	Socket preference module code.

	$Id: prefsock.asm,v 1.1 97/04/05 01:43:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def

include object.def
include	graphics.def
include gstring.def
include	win.def

include char.def
include initfile.def
include	driver.def
include medium.def
include	file.def

;-----------------------------------------------------------------------------
;	Libraries used
;-----------------------------------------------------------------------------

UseLib	ui.def
UseLib	config.def
UseLib	Objects/vTextC.def
UseLib	socket.def
UseDriver Internal/serialDr.def
UseDriver Internal/socketDr.def

;-----------------------------------------------------------------------------
;	DEF FILES
;-----------------------------------------------------------------------------

include prefsock.def
include prefsock.rdef

;-----------------------------------------------------------------------------
;
;	RESIDENT CODE
;
;-----------------------------------------------------------------------------

PrefSocketResidentCode	segment resource

PrefSocketResidentCode	ends


PrefSocketCode	segment resource

global	PrefSocketGetPrefUITree:far
global	PrefSocketGetModuleInfo:far

;-----------------------------------------------------------------------------
;
;	EXPORTED ROUTINES
;
;-----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSocketGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		none

RETURN:		dx:ax - OD of root of tree

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSocketGetPrefUITree	proc	far
		mov	dx, handle PrefSocketRoot
		mov	ax, offset PrefSocketRoot
		ret
PrefSocketGetPrefUITree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSocketGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr

PASS:		ds:si - PrefModuleInfo structure to be filled in

RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSocketGetModuleInfo	proc	far
	clr	ax
		
	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle PrefSocketMonikerList
	mov	ds:[si].PMI_monikerList.offset,	offset PrefSocketMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'S' or ('K' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL
	ret
PrefSocketGetModuleInfo	endp


; --------------------------------------------------------------------------
;
;   INITIALIZATION
;
; --------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDPrefInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the main dialog

CALLED BY:	MSG_PREF_INIT
PASS:		*ds:si	= PrefSocketDialogClass object
		ds:di	= PrefSocketDialogClass instance data
		ds:bx	= PrefSocketDialogClass object (same as *ds:si)
		es 	= segment of PrefSocketDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
PSEUDO CODE/STRATEGY:

	1. Find all the available drivers for socket library
	   - construct a table of them
	2. Disable edit button
	3. Initialize the driver list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDPrefInit	method dynamic PrefSocketDialogClass,
		MSG_PREF_INIT
		uses	es
		.enter
	;
	; Call super
	;
		mov	di, offset PrefSocketDialogClass
		call	ObjCallSuperNoLock
	;
	; Initialize driver list
	;
		mov	si, offset PrefSocketDriverList
		mov	ax, MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		call	ObjCallInstanceNoLock
	;
	; Nothing is selected by default
	;
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		call	ObjCallInstanceNoLock
		.leave
		ret
PSDPrefInit	endm


; --------------------------------------------------------------------------
;
;   BRINGING UP EDIT DIALOG
;
; --------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDPrefSocketDriverSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable edit button.

CALLED BY:	MSG_PREF_SOCKET_DRIVER_SELECTED
PASS:		*ds:si	= PrefSocketDialogClass object
		ds:di	= PrefSocketDialogClass instance data
		ds:bx	= PrefSocketDialogClass object (same as *ds:si)
		es 	= segment of PrefSocketDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDPrefSocketDriverSelected	method dynamic PrefSocketDialogClass, 
					MSG_PREF_SOCKET_DRIVER_SELECTED
		.enter

		mov	si, offset PrefSocketEditButton
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_ENABLED
		call	ObjCallInstanceNoLock
		
		.leave
		ret
PSDPrefSocketDriverSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept IC_APPLY and bring up edit dialog for the driver
		selected.

		Intercept IC_DISMISS and unload any driver that is currently
		loaded.

CALLED BY:	MSG_GUP_INTERACTION_COMMAND
PASS:		*ds:si	= PrefSocketDialogClass object
		ds:di	= PrefSocketDialogClass instance data
		ds:bx	= PrefSocketDialogClass object (same as *ds:si)
		es 	= segment of PrefSocketDialogClass
		ax	= message #
		cx	= interaction command
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDGupInteractionCommand	method dynamic PrefSocketDialogClass, 
					MSG_GEN_GUP_INTERACTION_COMMAND
		.enter
	;
	; Intercept IC_APPLY only
	;
		cmp	cx, IC_APPLY			; continue normally
		jne	cont
	;
	; Bring up edit dialog
	;
		call	PrefSocketLaunchEditDialog
		jmp	done
cont:
	;
	; Intercept IC_DISMISS
	;
		cmp	cx, IC_DISMISS
		jne	cont2
	;
	; Unload driver
	;
		push	es
		GetDgroup es, bx
		call	UnloadPreviousDriver
		pop	es
cont2:
	;
	; Callsuper
	;
		mov	di, offset PrefSocketDialogClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret
PSDGupInteractionCommand	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSocketLaunchEditDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up edit dialog for the selected driver

CALLED BY:	PSDGupInteractionCommand
PASS:		ds	= duplicated PrefSocketUI segment
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSocketLaunchEditDialog	proc	near
		uses	bx,si,di
		.enter
	;
	; Mark busy
	;
		call	GeodeGetProcessHandle	; bx = process handle
		call	GeodeGetAppObject	; ^lbx:si = preference module
		mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Unload any driver that is currently loaded
	;
		GetDgroup es, bx
		call	UnloadPreviousDriver	; nothing changed
	;
	; Get path to the driver
	;
		mov	si, offset PrefSocketDriverList
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_PATH
		call	ObjCallInstanceNoLock
		push	ds			; preserve PrefSocketUI segment
	;
	; cx:dx = full path
	; ax    = handle of same
	; bp    = disk handle
	; Load driver in question
	;
		movdw	dssi, cxdx
		clr	ax, bx
		call	GeodeUseDriver		; bx = driver handle
		jc	loadError
	;
	; Store driver handle and strategy in dgroup
	;
		mov	es:driverHandle, bx
		call	GeodeInfoDriver	; ds:si = socketDriverInfoStruct
		movdw	bxdx, ds:[si].DIS_strategy
		movdw	es:driverStrategy, bxdx
		mov	bx, ds:[si].SDIS_prefInfo
		mov	es:prefInfo, bx
		pop	ds		; restore PrefSocketUI segment
	;
	; Reconfigure edit dialog accroding to SocketDriverPrefOptions
	; of the driver
	; ds = PrefSocketUI segment
	; bx = SocketDriverPrefOptions
	;
		call	PrefSocketConfigureEditDialog
	;
	; Instantiate and attach preference controller if desired
	; ds = a copy of PrefSocketUI
	; bx = SocketDriverPrefOptions
	;
		push	es
		GetDgroup es, ax		; prefControl = 0 by default
		clr	es:prefControl		; (which means no custion ui)
		pop	es
		test	bx, mask SDPO_CUSTOM_UI
		jz	cont
		call	PrefSocketInstantiateCustomUI
cont:
	;
	; Bring up edit dialog
	;
		mov	si, offset PrefSocketEditDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
loadError:
	;
	; Couldn't load the driver( ax = GeodeLoadError )
	;
		pop	ds
	;
	; Mark the appl non-busy
	;
		call	GeodeGetProcessHandle	; bx = process handle
		call	GeodeGetAppObject	; ^lbx:si = preference module
		mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; display the dialog indicating drive load error
	;
		call	PrefSocketDisplayLoadDriverError
		jmp	done
PrefSocketLaunchEditDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnloadPreviousDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unloads any driver that is currently loaded

CALLED BY:	PrefSocketLauncheditDialog
PASS:		es	= dgroup
RETURN:		nothing ( any previous driver was unloaded )
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnloadPreviousDriver	proc	near
		uses	bx
		.enter
		clr	bx
		xchg	bx, es:driverHandle
		tst	bx
		jz	done
		call	GeodeFreeLibrary
done:
		.leave
		ret
UnloadPreviousDriver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSocketConfigureEditDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set usable or not usable for gadgets in edit dialog
		according to SocketDriverPrefOptions.
CALLED BY:	PrefSocketLaunchEditDialog
PASS:		ds	= PrefSocketUI
		bx 	= SocketDriverPrefOptions
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; One gadget per bit position)( 0 = no gadget )
;
PrefOptionTable	nptr \
	0,0,0,0,0,0,0,0,
	PrefSocketMediaOption,
	PrefSocketSerialPortOption,
	PrefSocketBaudrateOption,
	PrefSocketUnitList,
	PrefSocketMaxPktSize,
	PrefSocketSublayerOption,
	PrefSocketAddressOption,
	PrefSocketTypeOption
PrefSocketConfigureEditDialog	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
		clr	di			; stat from position 0
		mov	cx, 000000000000000001b ; current mask
optionLoop:
		mov	si, cs:[PrefOptionTable][di]
		tst	si
		jz	next
		test	bx, cx
		jz	notUsable
		mov	ax, MSG_GEN_SET_USABLE
		jmp	sendMsg
notUsable:
		mov	ax, MSG_GEN_SET_NOT_USABLE
sendMsg:
		mov	dl, VUM_NOW
		push	cx
		call	ObjCallInstanceNoLock
		pop	cx
next:
		shl	cx, 1
		add	di, size nptr
		cmp	di, 32		; = 16 * 2
		jb	optionLoop
		.leave
		ret
PrefSocketConfigureEditDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSocketInstantiateCustomUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Instantiate preference controller for the driver, and attach
		it to edit dialog.

CALLED BY:	PrefSocketLaunchEditDialog
PASS:		ds	= duplicated PrefSocketUI
RETURN:		nothing( ds adjusted to point to the correct segment )
DESTROYED:	nothing
		* ds might change as the object block might move around
		  while instantiating controller.  Properly updated ds
		  will be returned.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSocketInstantiateCustomUI	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; Get address pref control class
	;
		GetDgroup es, bx
		mov	ax, SGIT_PREF_CTRL
		mov	di, DR_SOCKET_GET_INFO
		pushdw	es:driverStrategy
		call	PROCCALLFIXEDORMOVABLE_PASCAL ; cxdx = class
	;
	; Instantiate the address controller
	;
		push	es
		movdw	esdi, cxdx
		mov	bx, ds:LMBH_handle
		call	ObjInstantiate	; *ds:si = handle to new obj
		pop	es
		mov	es:prefControl, si
	;
	; Store offset to controller obj
	;
		mov	cl, mask GIA_MODAL
		clr	ch
		mov	ax, MSG_GEN_INTERACTION_SET_ATTRS
		call	ObjCallInstanceNoLock
	;
	; Set its prefInteractionAttrs
	;
		push	bx
		mov	bx, ds:[si]
		mov	di, ds:[bx].Pref_offset
		mov	ds:[bx][di].PII_attrs, \
			mask PIA_LOAD_OPTIONS_ON_INITIATE or \
			mask PIA_SAVE_OPTIONS_ON_APPLY
		pop	bx
	;
	; Add it to the dialog
	;
		push	si
		mov	cx, bx
		mov	dx, si				; cxdx = obj to add
		mov	si, offset PrefSocketEditDialog
		mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
		mov	ax, MSG_GEN_ADD_CHILD
		call	ObjCallInstanceNoLock
		pop	si
	;
	; Set it usable
	;
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

		.leave
		ret
PrefSocketInstantiateCustomUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSocketDisplayLoadDriverError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displayt drive load error dialog

CALLED BY:	PrefSocketLaunchEditDialog
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Lock Strings resource
	Set up StandardDialogParams
	Display dialog
	Unlock Strings resource

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	3/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSocketDisplayLoadDriverError	proc	near
                uses    ax, bx, si, bp, ds
                .enter
	;
	; Lock strings resource and dereference string
	;
		mov	bx, handle Strings
		call	MemLock			; carry set if err
						; ax <- sptr to block
		jc	error			; just ignore if we can't
						; lock string  
		mov	ds, ax
		mov	si, offset LoadDriverErrorString
						; *ds:si <- error string
		mov	si, ds:[si]		; deref error string
EC <		call	ECCheckBounds					>
        ;
        ;  Code from Skarpi's DisplayError routine.
        ;
                sub     sp, size StandardDialogParams
                mov     bp, sp
                mov     ss:[bp].SDP_customFlags, 
                CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION,0>
        ;	
        ;  Display the error box.
        ;
                mov     ss:[bp].SDOP_customString.segment, ds 
                mov     ss:[bp].SDOP_customString.offset, si

                clrdw   ss:[bp].SDOP_stringArg1
                clrdw   ss:[bp].SDOP_stringArg2
                clr     ss:[bp].SDP_helpContext.segment

                call    UserStandardDialog      ; cleans up stack
	;
	;  Unlock strings resources
	;
		call	MemUnlock		; bx destroyed
error:
                .leave
                ret
PrefSocketDisplayLoadDriverError	endp

; --------------------------------------------------------------------------
;
;  INSIDE EDIT DIALOG
;
; --------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSEGenInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize edit dialog; sets its title bar and init file
		category

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= PrefSocketEditClass object
		ds:di	= PrefSocketEditClass instance data
		ds:bx	= PrefSocketEditClass object (same as *ds:si)
		es 	= segment of PrefSocketEditClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
PSEUDO CODE/STRATEGY:
	A lot of hack in this routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSEGenInteractionInitiate	method dynamic PrefSocketEditClass, 
				MSG_GEN_INTERACTION_INITIATE
		.enter
		push	si		; save object handle
	;
	; Get driver name
	;
		mov	si, offset PrefSocketDriverList
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_PATH
		call	ObjCallInstanceNoLock	; cxdx = path; ax,bp destroyed
	;
	; Eliminate path part
	;
		cld
		mov	es, cx
		mov	di, dx
	;
	; Go to the end of the string
	;
		clr	al
		repne	scasb
		dec	di
	;
	; Scan back until we find '\'( HACK!! we are guaranteed to have this )
	;
		std
		mov	al, 92		; al = '\'
		repne	scasb
		add	di, 2		; exclude '\'
		cld
	;
	; If EC, get rid of "EC " prefix
	;
EC <		add	di, 3		; get rid of "EC "		>
	;
	; Set new moniker for edit dialog
	; cx:dx = File name
	;
		movdw	cxdx, esdi
		mov	si, offset PrefSocketEditDialog
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	bp, VUM_NOW
		call	ObjCallInstanceNoLock
	;
	; Change the category name
	;
		mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
		mov	cx, GEODE_NAME_SIZE+1
		call	ObjVarAddData		; ds:bx = buffer
		segmov	es, ds, ax
		mov	di, bx
	;
	; es:di = buffer for name
	;
		push	ds			; save obj block seg
		GetDgroup ds, bx
		mov	ax, GGIT_PERM_NAME_ONLY
		mov	bx, ds:driverHandle
		call	GeodeGetInfo
		mov	{byte}es:[di+GEODE_NAME_SIZE], 0 ; make it null term.
		pop	ds			; restore obj block seg
	;
	; Call super
	;
		pop	si			; restore object handle
		mov	di, segment PrefSocketClassStructures
		mov	es, di
		mov	di, offset PrefSocketEditClass
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallSuperNoLock
	;
	; Send initiate message
	;
		GetDgroup es, bx
		mov	si, es:prefControl
		tst	si
		jz	skipCustomUI
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
skipCustomUI:
	;
	; Change back the mouse pointer image to normal pointer
	;
		call	GeodeGetProcessHandle	; bx = process handle
		call	GeodeGetAppObject	; ^lbx:si = preference module
		mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		
		.leave
		ret
PSEGenInteractionInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSEGenGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept IC_dismiss command to unload driver

CALLED BY:	MSG_GEN_GUP_INTERACTION_COMMAND
PASS:		*ds:si	= PrefSocketEditClass object
		ds:di	= PrefSocketEditClass instance data
		ds:bx	= PrefSocketEditClass object (same as *ds:si)
		es 	= segment of PrefSocketEditClass
		ax	= message #
		cx	= InteractionCommand
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSEGenGupInteractionCommand	method dynamic PrefSocketEditClass, 
					MSG_GEN_GUP_INTERACTION_COMMAND
		.enter
	;
	; Intercept IC_DISMISS and unload the driver
	;
		cmp	cx, IC_DISMISS
		jne	callSuper
		call	PrefSocketUnloadDriver
callSuper:
	;
	; Call super
	;
		mov	di, segment PrefSocketClassStructures
		mov	es, di
		mov	di, offset PrefSocketEditClass
		call	ObjCallSuperNoLock
		.leave
		ret
PSEGenGupInteractionCommand	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSocketUnloadDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unload the driver loaded for editing

CALLED BY:	PSEGenGupInteractionCommand
PASS:		*ds:si = PrefSocketEditDialog
		ds:di  = PrefSocketEditDialog instance field
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSocketUnloadDriver	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; Get dgroup
	;
		GetDgroup es, bx
		test	es:prefInfo, mask SDPO_CUSTOM_UI
		jz	noCustomUI
	;
	; Detach preference controller if necessary
	;
		mov	si, es:prefControl
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjCallInstanceNoLock
	
		mov	cx, ds:LMBH_handle
		mov	dx, si
		push	dx
		mov	si, offset PrefSocketEditDialog
		mov	bp, mask CCF_MARK_DIRTY
		mov	ax, MSG_GEN_REMOVE_CHILD
		call	ObjCallInstanceNoLock
		
	;
	; Release all the resources that belong to pref controller
	;
		pop	si			; si = pref control obj
		mov	ax, MSG_GEN_CONTROL_DESTROY_UI
		call	ObjCallInstanceNoLock
	;
	; Free pref controller itself
	;
		mov	ax, MSG_GEN_DESTROY
		mov	dl, VUM_NOW
		clr	bp
		call	ObjCallInstanceNoLock
noCustomUI:
	;
	; Unload driver right before you load another driver
	; This is because we cannot be sure when this driver's pref controller
	; object is actually destroyed.
	;
	;	mov	bx, es:driverHandle
	;	call	GeodeFreeLibrary
	;	
		.leave
		ret
PrefSocketUnloadDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSEPrefSocketPortSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable serialPortOptions button according to
		port selection

CALLED BY:	MSG_PREF_SOCKET_PORT_SELECTED
PASS:		*ds:si	= PrefSocketEditClass object
		ds:di	= PrefSocketEditClass instance data
		ds:bx	= PrefSocketEditClass object (same as *ds:si)
		es 	= segment of PrefSocketEditClass
		ax	= message #
		cx	= selection
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSEPrefSocketPortSelected	method dynamic PrefSocketEditClass, 
					MSG_PREF_SOCKET_PORT_SELECTED
		uses	ax, cx, dx, bp
		.enter
		cmp	cx, 3
		jnb	enable
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		jmp	sendMsg
enable:
		mov	ax, MSG_GEN_SET_ENABLED
sendMsg:
		mov	si, offset PrefSocketSerialPortOption
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		.leave
		ret
PSEPrefSocketPortSelected	endm



PrefSocketCode	ends
