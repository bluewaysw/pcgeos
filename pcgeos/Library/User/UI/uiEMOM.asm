COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ui
FILE:		uiEMOM.asm,  ExpressMenuObjectManager (EMOM)

AUTHOR:		Ian Porteous, May 23, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB EMObjectManagerClass	Express Menu Object Manager, creates
				and manages objects in the express
				menu

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/23/94   	Initial revision


DESCRIPTION:
	Method handlers for the EMObjectManager class
		

	$Id: uiEMOM.asm,v 1.1 97/04/07 11:46:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserClassStructures	segment	resource
	EMObjectManagerClass	
UserClassStructures	ends


EMOMCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	initialize the a new EMObjectManager object... takes
		an optr	to a ChunkArray of
		CreateExpressMenuControlItemParams and creates a copy
		of the ChunkArray for its instance data.

CALLED BY:	MSG_EMOM_SETUP (INTERNAL)
PASS:		*ds:si	= EMObjectManagerClass object
		ds:di	= EMObjectManagerClass instance data
		ds:bx	= EMObjectManagerClass object (same as *ds:si)
		es 	= segment of EMObjectManagerClass
		ax	= message #
		cx:dx	= optr to ChunkArray of 
			CreateExpressMenuControlItemParams
RETURN:		carry - if could not allocate chunk
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMSetup	method dynamic EMObjectManagerClass, 
					MSG_EMOM_SETUP
	uses	bp
	.enter

	mov	bx, cx
	call 	ObjLockObjBlock
	mov	es, ax
	mov	ax, dx
	Assert	ChunkArray esax

	mov	bp,  mask CCF_MARK_DIRTY 
	call	GenCopyChunk

	call	MemUnlock
	mov	di, ds:[si]
	mov	ds:[di].EMOMI_classes, ax	; EMOMI_classes < new
						; chunk
	; 
	; make sure that it is a valid chunk array
	;
	Assert	ChunkArray dsax

	;
	; Check to make sure that all of the classes in CEMCIP_class
	; are valid.  It is possible that someone accidently passed an
	; array with unrelocated far pointers in EMOMI_class.
	;
EC<	mov	si, ax							>
EC<	mov	bx, cs							>
EC<	mov	di, offset EMOMCheckClass_callback			>
EC<	call	ChunkArrayEnum						>

	.leave
	ret
EMOMSetup	endm

if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMCheckClass_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that CEMCIP_class contains a valid ClassStruct *

CALLED BY:	EMOMSetup via ChunkArrayEnum (PRIVATE)
PASS:		ds:di	= CreateExpressMenuControlItemParams
RETURN:		nothing
DESTROYED:	es
SIDE EFFECTS:	

Fatal error if CEMCIP_class does not contain a valid pointer

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMCheckClass_callback	proc	far
	.enter

	movdw	esdi, ds:[di].CEMCIP_class
	call	ECCheckClass

	.leave
	ret
EMOMCheckClass_callback	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMMetaAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify all express menus to create and add the object
		from the array of classes in EMOMI_classes

CALLED BY:	MSG_META_ATTACH 
PASS:		*ds:si	= EMControlObjectClass object
		ds:di	= EMControlObjectClass instance data
		ds:bx	= EMControlObjectClass object (same as *ds:si)
		es 	= segment of EMControlObjectClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMMetaAttach	method dynamic EMObjectManagerClass, 
					MSG_META_ATTACH
	.enter
	
	;
	; Place an extra reference on the geode that defines the actual class
	; of this object, so it won't go away until we're detached. This is
	; necessary for some standalone libraries and drivers, you know (e.g.
	; handwriting...)
	; 
	call	EMOMGetClassOwnerGeode
	call	GeodeAddReference
	;
	; check to make sure that the EMOMI_classes points to a valid
	; chunk array
	;
EC<	push	ax							>
EC<	mov	ax, ds:[di].EMOMI_classes				>
EC<	Assert	ChunkArray dsax						>
EC<	pop	ax							>
	;
	; check to make sure that there is not duplicate responseData
	; entries in EMOMI_classes.
	;
EC<	call	ECEMOMCheckResponseData					>
	;
	; Call the superclass first.
	; 
	mov	di, offset EMObjectManagerClass
	call	ObjCallSuperNoLock
	;
	; Hook any and all express menus
	; 
	call	EMOMHookExpressMenus
	;
	; If we're supposed to detach with the system, add ourselves to the ui's
	; application object's active list
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	call	EMOMAddRemoveUIActiveList

	.leave
	ret
EMOMMetaAttach	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMGetClassOwnerGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the handle of the geode that defined this object's
		class.

CALLED BY:	(INTERNAL) EMOMMetaAttach, EMOMMetaDetachComplete
PASS:		*ds:si	= EMObjectManager (subclass) object
RETURN:		bx	= geode handle
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMGetClassOwnerGeode proc	near
		class	EMObjectManagerClass
		uses	di, cx, ax
		.enter
		mov	di, ds:[si]
		mov	cx, ds:[di].MB_class.segment
		call	MemSegmentToHandle
		mov	bx, cx
		mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
		call	MemGetInfo
		mov_tr	bx, ax
		.leave
		ret
EMOMGetClassOwnerGeode endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMAddRemoveUIActiveList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this manager is marked as wanting to shut down with the
		system, add or remove it from the ui application's
		active list.

CALLED BY:	(INTERNAL) EMOMMetaAttach, EMOMMetaDetach
PASS:		*ds:si	= EMObjectManager object
		ax	= MetaMessage to send to add/remove
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMAddRemoveUIActiveList proc	near
		class	EMObjectManagerClass
		uses	bx, cx, dx, si, di, bp
		.enter
	;
	; See if we should be messing with the active list.
	; 
		mov	di, ds:[si]
		test	ds:[di].EMOMI_attrs, mask EMOMA_DETACH_WITH_SYSTEM
		jz	done
	;
	; Yes. Set up the parameters for the add/remove: the list to manipulate
	; and the object requesting the manipulation.
	; 
		mov	dx, size GCNListParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST
		
		mov	bx, ds:[LMBH_handle]
		movdw	ss:[bp].GCNLP_optr, bxsi
	;
	; Call the UI's application object to do it.
	; 
		mov	bx, handle UIApp
		mov	si, offset UIApp
		mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
		call	ObjMessage
		add	sp, size GCNListParams
done:
		.leave
		ret
EMOMAddRemoveUIActiveList endp

if ERROR_CHECK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECEMOMCheckResponseData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go through EMOMI_classes array and make sure that
		there is no duplicate response data

CALLED BY:	EMOMMetaArrach (PRIVATE)
PASS:		ds:di	= EMObjectManager object instance data
RETURN:		carry set if there is duplicate data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECEMOMCheckResponseData	proc	near
	class	EMObjectManagerClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	mov	si, ds:[si]			
	mov	si, ds:[si].EMOMI_classes	
	call	ChunkArrayGetCount		
	shl	cx, 1		 		
	; 
	; ss:bp <- array of words to store the CEMCIP_responseData
	; entries while we verify that they are unique.  Should not be
	; a problem storing this array on the stack since it is
	; unlikely that many objects will be created in each express menu
	;
	sub	sp, cx				
	mov	bp, sp				
	mov	bx, cs
	mov	di, offset EMOMCheckResponseData_callback	
	clr	dx				
	push	cx				
	;
	; Enum through the array of CEMCIP structs.  For each one,
	; check the responseData for this one against the responseData
	; for all previous ones stored in an array at ss:bp 
	;
	call	ChunkArrayEnum			
 	pop	cx				
	add	sp, cx				
	.leave
	ret
ECEMOMCheckResponseData	endp
endif


if ERROR_CHECK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMCheckResponseData_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the response data for this
		CreateExpressMenuControlItempParams is unique

CALLED BY:	
PASS:		ds:[di]	= ptr to array element of type 
				CreateExpressMenuControlItemParams 
		dx	= number of entries checked
		ss:bp	= array of CEMCIP_responseData entries to
				check against
RETURN:		carry-set if there is a duplicate responseData
		else clc
DESTROYED:	cx, bx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

check CEMCIP_responseData against all of the responseData entries in
	the array stored at ss:bp
	return carry if there is a matching one, indicating that a
		duplicate was found	

add ds:[di].CEMCIP_responseData to the array of responseData(s) at
	ss:bp

increment the count of the number of entries

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMCheckResponseData_callback	proc	far
	.enter
	
	mov	cx, dx			; cx < # of array elements scanned
					; so far
	jcxz	doneChecking
	mov	ax, ds:[di].CEMCIP_responseData
testLoop:	
	mov	bx, cx
	dec	bx
	shl	bx, 1			; change to index to offset
	add	bx, bp			; ss:bx <- array offset to
					; check
	cmp	ax, ss:[bx]
	je	match
	loop	testLoop

doneChecking:
	mov	bx, dx
	shl	bx, 1
	add	bx, bp			; ss:bx <- array offset to
					; insert this entry
	mov	ax, ds:[di].CEMCIP_responseData
	mov	ss:[bx], ax
	inc	dx			; inc how many responseData
					; entries there are to check
	clc
	.leave
	ret
match:
	ERROR	EMOM_SLOT_ALREADY_FILLED	

EMOMCheckResponseData_callback	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMHookExpressMenus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create passed objects in the existing express menus
		and setup to be told about new ones.

CALLED BY:	EMOMMetaAttach (PRIVATE)
PASS:		*ds:si	= EMObjectManager
		
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	message is sent to all existing express menu controllers
			to create an object. they will send back a
			MSG_EMOM_EXPRESS_MENU_OBJECT_CREATED when the
			object is created
PSEUDO CODE/STRATEGY: 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMHookExpressMenus	proc	near
	class	EMObjectManagerClass
	uses	si
	.enter
	;
	; get number of classes to instantiate in each express menu so
	; we know how large to make the array elements which keep
	; track of such things.
	;
	push	si
	mov	si, ds:[si]
	mov	si, ds:[si].EMOMI_classes
	call	ChunkArrayGetCount
	pop	si
	mov	di, ds:[si]
	mov	ds:[di].EMOMI_numClasses, cx
	;
	; Create an array in which to track these things.
	; 
	push	si
	shl	cx, 1
	shl	cx, 1
			
	CheckHack <size optr eq 4>

	mov_tr	bx, cx			; bx < #classes * size
					; optr
	add	bx, size EMOMExpressMenu
	clr	cx, si		; default header size, create chunk
				;  for me, please.
	mov	al, mask OCF_IGNORE_DIRTY
	call	ChunkArrayCreate
	mov_tr	ax, si
	pop	si
	mov	di, ds:[si]
	mov	ds:[di].EMOMI_expressMenus, ax
	;
	; First, add ourselves to the GCNSLT_EXPRESS_MENU_CHANGE system
	; notification list so we can create classes
	; in new Express Menu Control objects
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
	call	GCNListAdd
	;
	; now enumerate through the classes, adding each one to the
	; express menus.
	;
	mov	bp, si			; *ds:bp <- EMOM for callback
	mov	si, ds:[di].EMOMI_classes
	mov	bx, cs	
	mov	di, offset EMOMHEM_callback
	call	ChunkArrayEnum
	.leave
	ret
EMOMHookExpressMenus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMHEM_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use the passed in CreateExpressMenuControlItemParams
		to create the class in the express menus.
CALLED BY:	EMOMHookExpressMenus via ChunkArrayEnum (PRIVATE)
PASS:		bp 	= offset of EMObjectManagerClass
		ds:[di]	= ptr to array element of type 
				CreateExpressMenuControlItemParams 
		*ds:bp	= EMObjectManagerClass object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMHEM_callback	proc	far
	.enter
	;
	; record a message to create this class
	;
	mov	bx, mask MF_RECORD
	mov	si, bp
	call	EMOMCreateClassCommon
	;
	; send the recoded message to all of the active express menu
	; controllers 
	;
	call EMOMSendToExpressMenuControllers

	.leave
	ret
EMOMHEM_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMCreateClassCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to express menu controller to create
		the passed class, or record a message to be sent

CALLED BY:	EMOMHEM_callback, AddObjectToMenu_callback (PRIVATE)
PASS:		*ds:si	- EMObjectManagerObject
		ds:di	- CreateExpressMenuControlItemParams
		bx	- message flags
		if bx != MF_RECORD
			^lcx:dx = controller
RETURN:		if bx = MF_RECORD
			di = recorded message
DESTROYED:	ax, si, es
SIDE EFFECTS:	
		ds	- maybe fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMCreateClassCommon	proc	near
	uses	bx, cx, dx, bp
	.enter

	mov	ax, ds:[LMBH_handle]
	mov	ds:[di].CEMCIP_responseDestination.handle, ax
	mov	ds:[di].CEMCIP_responseDestination.chunk, si
	mov	ds:[di].CEMCIP_responseMessage, MSG_EMOM_EXPRESS_MENU_OBJECT_CREATED
	clrdw	ds:[di].CEMCIP_field.handle
	;
	; copy the CreateExpressMenuItemControlParams onto the stack
	; to send it off in the message
	;
	sub	sp, size CreateExpressMenuControlItemParams
	mov	si, di
	mov	di, sp
	mov	bp, sp
	segmov	es, ss
	push	cx
	mov	cx, size CreateExpressMenuControlItemParams
	rep	movsb
	pop	cx
	;
	; record the message to send	
	;
	mov	di, bx
	clr	bx, si
	test	di, mask MF_RECORD

	jnz 	sendMessage
	ornf	di, mask MF_FIXUP_DS
	movdw	bxsi, cxdx

sendMessage:
	ornf	di, mask MF_STACK
	mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
	mov	dx, size CreateExpressMenuControlItemParams
	call	ObjMessage

	add	sp, size CreateExpressMenuControlItemParams
	.leave
	ret
EMOMCreateClassCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMSendToExpressMenuControllers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a recorded message to all the active express menu
		controllers.

CALLED BY:	EMOMCreateClasses (PRIVATE)
PASS:		di	- recorded message
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMSendToExpressMenuControllers	proc	near
	class	EMObjectManagerClass
	uses	bp
	.enter
	mov	cx, di				; cx = event handle
	clr	dx				; no extra data block
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_OBJECTS
	clr	bp				; no cached event
	call	GCNListSend			; send to all EMCs
	.leave
	ret
EMOMSendToExpressMenuControllers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMNotifyExpressMenuChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to express menu change notification. 

CALLED BY:	MSG_NOTIFY_EXPRESS_MENU_CHANGE
PASS:		*ds:si	= EMObjectManagerClass object
		ds:di	= EMObjectManagerClass instance data
		ds:bx	= EMObjectManagerClass object (same as *ds:si)
		es 	= segment of EMObjectManagerClass
		ax	= message #
		bp	= GCNExpressMenuNotificationType
		^lcx:dx	= optr of affected express menu control
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

If an express menu was created, notify it to create the
objects, and add a record to EMOMI_expressMenus to
track it

If an express menu was destroyed, delete the record in
EMOMI_expressMenus for it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMNotifyExpressMenuChange	method dynamic EMObjectManagerClass, 
					MSG_NOTIFY_EXPRESS_MENU_CHANGE
	.enter
	test	ds:[di].EMOMI_attrs, mask EMOMA_DETACHING
	jnz	exit
	
	cmp	bp, GCNEMNT_CREATED
	jne	checkDestroyed
	;
	; new express menu created, so let's add all of our objects to it 
	;
	mov	bp, si
	mov	si, ds:[di].EMOMI_classes
	mov	bx, cs	
	mov	di, offset AddObjectToMenu_callback
	call	ChunkArrayEnum		
exit:
	.leave
	ret

checkDestroyed:
	cmp	bp, GCNEMNT_DESTROYED
	jne 	exit
	;
	; Find and remove the record for the controller from our array --
	; the controller will destroy all our children for us.
	;
	mov	bp, si
	mov	si, ds:[di].EMOMI_expressMenus
	mov	bx, cs	
	mov	di, offset RemoveExpressMenuEntry_callback
	call	ChunkArrayEnum		
	jmp	exit

EMOMNotifyExpressMenuChange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddObjectToMenu_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add object to passed menu

CALLED BY:	EMOMNotifyExpressMenuChange via ChunkArrayEnum (PRIVATE)
PASS:		^lcx:dx	= express menu to add to
		ds:di	= CreateExpressMenuControlItemParams
		*ds:bp  = EMObjectManagerObject

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddObjectToMenu_callback	proc	far
	.enter
	;
	; send a message to the express menu control to create the
	; class
	;
	clr	bx
	mov	si, bp
	call	EMOMCreateClassCommon
		
	.leave
	ret

AddObjectToMenu_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveExpressMenuEntry_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the entry for the express menu being deleted
		from our list of express menus

CALLED BY:	EMOMNotifyExpressMenuChange via ChunkArrayEnume (PRIVATE)
PASS:		^lcx:dx	= express menu to remove
		ds:di = EMOMExpressMenu struct
		*ds:bp= EMObjectManagerObject
RETURN:		nothing
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveExpressMenuEntry_callback	proc	far
	class	EMObjectManagerClass
	uses	cx, dx
	.enter
	cmp	cx, ds:[di].EMOMEM_expressMenu.handle
	jne	notThisOne
	cmp	dx, ds:[di].EMOMEM_expressMenu.chunk
	jne	notThisOne

	;
	; remove objects created under this express menu
	;	ds:di = EMOMExpressMenu being removed
	;	*ds:bp = EMObjectManager
	;
	call	ChunkArrayPtrToElement		; ax = element #
	push	ax
	call	RemoveExpressMenuItems
	pop	ax				; ax = element #

	mov	cx, -1				; delete 1 item
	call	ChunkArrayDeleteRange
	;
	; decrement the count of the number of objects we manage by
	; the number of objects in this express menu.  number of
	; classes = number of objects in this express menu (we assume)
	;
	mov	di, ds:[bp]
	mov	ax, ds:[di].EMOMI_numClasses
	sub	ds:[di].EMOMI_objectCount, ax
	stc

	jmp	exit

notThisOne:
	clc
exit:
	.leave
	ret
RemoveExpressMenuEntry_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveExpressMenuItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	function to remove the objects for each express menu
		control object

CALLED BY:	RemoveExpressMenuEntry_callback (PRIVATE)
PASS:		ds:di	= EMOMExpressMenu
		*ds:bp	= EMObjectManager object
RETURN:		
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We need to remove the created objects when we remove
		the express menu entry, otherwise they could be left in
		the express menu tree after the owning library has
		exited.  Then we'd be in trouble when the express menu gets
		set not-usable.  Note that we don't use
		MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM since that
		will generate unwanted ACKs to be sent.  Rather, the objects
		are just unhooked from the express menu and left in the
		object block.  The object block will eventually be freed.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveExpressMenuItems	proc	near
	class	EMObjectManagerClass
	uses	si, bp
	.enter
	;
	; get the number of objects that we have to destroy
	;
	mov	bx, ds:[bp]
	mov	ax, ds:[bx].EMOMI_numClasses	
	tst	ax
	jz	done
	;
	; Loop through the array of objects created for this express
	; menu and remove them.
	;
	mov	bp, si		; *ds:bp = array
	lea	di, ds:[di].EMOMEM_createdObject
loopArray:
	movdw	bxsi, ds:[di]	; ^lcx:dx = object to delete
	tst	bx
	jz	nextObject	; => didn't get created yet?!
	; 
	; Nuke the object
	;
	sub	di, ds:[bp]	; save the offset into the chunk
	push	di, ax, bp
	mov	ax, MSG_GEN_REMOVE
	mov	dl, VUM_NOW
	mov	bp, mask CCF_MARK_DIRTY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di, ax, bp

	add	di, ds:[bp]	; restore the offset into the chunk
nextObject:
	add	di, size optr
	dec	ax
	jnz	loopArray
done:
	.leave
	ret
RemoveExpressMenuItems	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	destroy all managed objects

CALLED BY:	MSG_META_DETACH 
PASS:		*ds:si	= EMObjectManagerClass object
		ds:di	= EMObjectManagerClass instance data
		ds:bx	= EMObjectManagerClass object (same as *ds:si)
		es 	= segment of EMObjectManagerClass
		ax	= message #
		cx 	= caller's ID (value to be returned in
				MSG_META_DETACH_COMPLETE to
				this object, & in MSG_META_ACK to
				caller) 
		^ldx:bp	= OD to send MSG_META_ACK to when all done.

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMMetaDetach	method dynamic EMObjectManagerClass, 
					MSG_META_DETACH
	.enter

	Assert	ne, ds:[di].EMOMI_classes, 0
	Assert 	ne, ds:[di].EMOMI_numClasses, 0

	;
	; Begin the detach sequence, paving the way to add the necessary
	; references to make the DETACH_COMPLETE notification happen
	; automatically once everyone who's interested in us is gone.
	;
	; We will not add or delete objects while we are in the process of
	; detaching. 
	;
	push	dx, bp, cx
	call	ObjInitDetach

	;
	; Note that we're detaching, for various uses.
	; 
	mov	di, ds:[si]
	ornf	ds:[di].EMOMI_attrs, mask EMOMA_DETACHING

	;
	; Remove ourselves from the UI application's active list if we put
	; ourselves on it.
	; 
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	EMOMAddRemoveUIActiveList

	;
	; Add a detach reference for each object we created. When we destroy
	; them they will send us EMOM_ACK messages which we will convert to
	; META_ACK messages, which will eventually allow us to go away.
	; 
	mov	di, ds:[si]
	mov	cx, ds:[di].EMOMI_objectCount
	jcxz	refsAdded
refLoop:
	call	ObjIncDetach
	loop	refLoop
refsAdded:

	;
	; Destroy all of the created objects, and remove ourselves
	; from the express menu change notification list
	;	
	call	EMOMUnhookExpressMenu

	;
	; Add reference for the META_ACK we're about to queue to ourselves.
	; 
	call	ObjIncDetach
	;
	; send ourselves MSG_META_ACK with force queue.  Since this
	; will arive after any GCNSLT_EXPRESS_MENU_CHANGE notifications
	; have been sent, we know not to respond to those
	; notifications.  Delete EMOMI_expressMenus only after we 
	; have completed detaching in EMOMMetaDetachComplete
	;
	clr	dx, bp, cx
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_META_ACK
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage

	pop	dx, bp, cx
	mov	di, offset EMObjectManagerClass
	mov	ax, MSG_META_DETACH
	call	ObjCallSuperNoLock

	call	ObjEnableDetach

	.leave
	ret
EMOMMetaDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMMetaDetachComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach has been completed.  

CALLED BY:	MSG_META_DETACH_COMPLETE
PASS:		*ds:si	= EMObjectManagerClass object
		ds:di	= EMObjectManagerClass instance data
		ds:bx	= EMObjectManagerClass object (same as *ds:si)
		es 	= segment of EMObjectManagerClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
Free the memory allocated to keep track of the express menus

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMMetaDetachComplete	method dynamic EMObjectManagerClass, 
					MSG_META_DETACH_COMPLETE
	.enter

	;
	; free the chunk allocated to keep track of the express menus
	;
	mov	ax, ds:[di].EMOMI_expressMenus
	tst	ax
	jz 	callSuper

	call	LMemFree

callSuper:
	mov	ax, MSG_META_DETACH_COMPLETE
	mov	di, offset EMObjectManagerClass
	call	ObjCallSuperNoLock
	;
	; Remove our reference to the geode that defined this object class.
	; We assume, of course, that by returning we will not be going back
	; to subclass code, which could well vanish during the call to
	; GeodeRemoveReference.
	;
	call	EMOMGetClassOwnerGeode
	call	GeodeRemoveReference
	.leave
	ret

EMOMMetaDetachComplete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	decrement the count of the number of objects that are
		managed.

CALLED BY:	MSG_EMOM_ACK
PASS:		*ds:si	= EMObjectManagerClass object
		ds:di	= EMObjectManagerClass instance data
		ds:bx	= EMObjectManagerClass object (same as *ds:si)
		es 	= segment of EMObjectManagerClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMAck	method dynamic EMObjectManagerClass, 
					MSG_EMOM_ACK
	.enter
	dec	ds:[di].EMOMI_objectCount
	;
	; If we're detaching, send ourselves the ack we're waiting to receive
	; from this object.
	; 
	test	ds:[di].EMOMI_attrs, mask EMOMA_DETACHING
	jz	done
	mov	ax, MSG_META_ACK
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
EMOMAck	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMUnhookExpressMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	destroy all of the object in the express menus, and
		remove ourselves from the express menu notification list

CALLED BY:	EMOMMetaDetach (PRIVATE)
PASS:		*ds:si	= EMObjectManager object

RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMUnhookExpressMenu	proc	near
	uses	si
	class	EMObjectManagerClass
	.enter
	;
	; Now nuke all the objects
	; 
	mov	di, ds:[si]
	mov	bp, si
	mov	si, ds:[di].EMOMI_expressMenus
	mov	bx, cs
	mov	di, offset EMOMUEM_callback
	tst	si		; not allocated (app object didn't
				;  get attached, as we never entered
				;  app mode)
	jz	done
	Assert	ChunkArray dssi
	call	ChunkArrayEnum
done:	
	;
	; Remove ourselves from the GCN list for express menus.
	; 
	mov	si, bp
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
	call	GCNListRemove

	.leave
	ret
EMOMUnhookExpressMenu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMUEM_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	function to destroy the objects for each express menu
		control object

CALLED BY:	EMOMUnhookExpressMenu via ChunkArrayEnum (PRIVATE)
PASS:		ds:di	= EMOMExpressMenu
		*ds:bp	= EMObjectManager object
RETURN:		
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMUEM_callback	proc	far
	class	EMObjectManagerClass
	uses	si, bp
	.enter
	;
	; get the number of objects that we have to destroy
	;
	mov	bx, ds:[bp]
	mov	ax, ds:[bx].EMOMI_numClasses	

	Assert	g	ax, 0	; should not have 0 objects
	;
	; Loop through the array of objects created for this express
	; menu and remove them.
	;
	mov	bp, si		; *ds:bp = array
	movdw	bxsi, ds:[di].EMOMEM_expressMenu
	lea	di, ds:[di].EMOMEM_createdObject
loopArray:
	movdw	cxdx, ds:[di]	; ^lcx:dx = object to delete
	jcxz	nextObject	; => didn't get created yet?!
	; 
	; Nuke the object
	;
	sub	di, ds:[bp]	; save the offset into the chunk
	push	di, ax, bp
	mov	ax, MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM
	mov	bp, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di, ax, bp

	add	di, ds:[bp]	; restore the offset into the chunk
nextObject:
	add	di, size optr
	dec	ax
	jnz	loopArray

	clc	; keep enumerating	
	.leave
	ret
EMOMUEM_callback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reloc\Unreloc the CEMCIP_class fields in EMOM_classes

CALLED BY:	reloc (MSG_META_RELOCATE, MSG_META_UNRELOCATE)
PASS:		*ds:si	= EMObjectManagerClass object
		ds:di	= EMObjectManagerClass instance data
		ds:bx	= EMObjectManagerClass object (same as *ds:si)
		es 	= segment of EMOjectManagerClass
		ax	= message #
RETURN:		carry set - if relocation or unrelocation failed
DESTROYED:	bx, si, ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMReloc	method EMObjectManagerClass, reloc
	uses	bp
	.enter
	;
	; UnRelocate or Relocate the CEMCIP_class fields of the array
	; pointed to by EMOMI_classes
	;
	tst	ds:[di].EMOMI_classes
	jz	callSuper

	push	si
	mov	si, ds:[di].EMOMI_classes
	Assert	ChunkArray dssi
	mov	bx, cs
	mov	di, offset EMOMRelocReloc
	cmp	ax, MSG_META_RELOCATE
	je	doEnum
	mov	di, offset EMOMRelocUnreloc
doEnum:
	push	bp
	call	ChunkArrayEnum
	pop	bp
	pop	si
	;
	; return carry if ObjDoRelocation or ObjDoUnRelocation failed
	;
	jc	exit
callSuper:
	mov	di, offset EMObjectManagerClass
	call	ObjRelocOrUnRelocSuper
exit:
	.leave
	ret
EMOMReloc	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMRelocUnreloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ChunkArrayEnum callback routine which performs the neccessary
		UnReloc on the CEMCIP_class field of the chunk array.

		   When an EMOM object is in a block that is being
		brought into memory and EMOMI_classes points to a
		chunk array of CreateExpressMenuControlItemParams, the
		CEMCIP_class fields contain unrelocated pointers to
		class structures.  They are UnRelocated pointers
		because they point to locations which are not known
		until run-time.  
		   The job of EMOMRelocReloc is to convert
		CEMCIP_class fields to relocated far pointers after
		the resource containing EMOM is brought into memory.
		Conversly, when and EMOM object is being brought out
		of memory, EMOMRelocUnreloc converts the relocated
		pointers in CEMCIP_class to unrelocated far pointers.

CALLED BY:	EMOMReloc (PRIVATE)
PASS:		*ds:bp 	= EMObjectManager object
		ds:[di]	= ptr to array element of type 
				CreateExpressMenuControlItemParams 
RETURN:		
DESTROYED:	dx, cx, bx, al
SIDE EFFECTS:	
		
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMRelocUnreloc	proc	far
	class	EMObjectManagerClass

	movdw	dxcx, ds:[di].CEMCIP_class
	mov	bx, ds:[LMBH_handle]
	mov	al, RELOC_ENTRY_POINT
	call	ObjDoUnRelocation
	movdw	ds:[di].CEMCIP_class, dxcx

	ret
EMOMRelocUnreloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMRelocReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ChunkArrayEnum callback routine which performs the neccessary
		Reloc on the CEMCIP_class field of the chunk array.

		   When an EMOM object is in a block that is being
		brought into memory and EMOMI_classes points to a
		chunk array of CreateExpressMenuControlItemParams, the
		CEMCIP_class fields contain unrelocated pointers to
		class structures.  They are UnRelocated pointers
		because they point to locations which are not known
		until run-time.  
		   The job of EMOMRelocReloc is to convert
		CEMCIP_class fields to relocated far pointers after
		the resource containing EMOM is brought into memory.
		Conversly, when and EMOM object is being brought out
		of memory, EMOMRelocUnreloc converts the relocated
		pointers in CEMCIP_class to unrelocated far pointers.

CALLED BY:	EMOMReloc (PRIVATE)
PASS:		*ds:bp 	- EMObjectManagerClass object
		ds:[di]	- ptr to array element of type 
				CreateExpressMenuControlItemParams 
RETURN:		
DESTROYED:	dx, cx, bx, al
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMRelocReloc	proc	far
	class	EMObjectManagerClass

	movdw	dxcx, ds:[di].CEMCIP_class
	mov	bx, ds:[LMBH_handle]
	mov	al, RELOC_ENTRY_POINT
	call	ObjDoRelocation
	movdw	ds:[di].CEMCIP_class, dxcx

	ret
EMOMRelocReloc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMExpressMenuObjectCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the new object created in the EMOMI_expressMenus array

CALLED BY:	MSG_EMOM_EXPRESS_MENU_OBJECT_CREATED
PASS:		*ds:si	= EMObjectManagerClass object
		ds:di	= EMObjectManagerClass instance data
		ds:bx	= EMObjectManagerClass object (same as *ds:si)
		es 	= segment of EMObjectManagerClass
		ax	= message #
		ss:bp 	= CreateExpressMenuControlItemResponseParams
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

If we already have an array entry for the express menu that created this
object in EMOMI_expressMenus, just add the object to the
EMOMEM_createdObject for that express menu

Otherwise, create an array entry for this express menu and add the
object to EMOMEM_createdObject

The index at which each object is put into the EMOMEM_createdObject
array is the same index as the entry in the EMOMI_class array with the
same responseData

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMExpressMenuObjectCreated	method dynamic EMObjectManagerClass, 
					MSG_EMOM_EXPRESS_MENU_OBJECT_CREATED
	uses	ax, cx, dx, bp
	.enter
	;
	; increment the count of how many object we currently manage
	; in all of the express menus
	;
	inc	ds:[di].EMOMI_objectCount
	;
	; get the index of which element in EMOMI_classes this object
	; was created from
	;
	push	di
	mov	ax, ss:[bp].CEMCIRP_data
	call	EMOMGetArrayIndexBasedOnData
	;
	; set the destination of MSG_EMOM_ACK if this is an EMTriggerClass
	; object
	;	
	call	EMOMSetAckDest

	shl	cx, 1		; change it to an offset into 
	shl	cx, 1		; EMOMEM_createdObject
	CheckHack <type EMOMEM_createdObject eq 4>
	pop	di
	;
	; Look for the controller in our array, storing the trigger's OD
	; in the proper place if we already know about this controller.
	; 
	mov	dx, si				; save EMOM chunk
	mov	si, ds:[di].EMOMI_expressMenus
	mov	bx, cs
	mov	di, offset EMOMEMOC_callback
	call	ChunkArrayEnum

	jc	sendMessage
	;
	; Not found, so create a new record for the controller.
	; 
	call	ChunkArrayAppend
	jc	exit
	
	movdw	ds:[di].EMOMEM_expressMenu, \
		ss:[bp].CEMCIRP_expressMenuControl, ax

	mov	bx, cx

	movdw	ds:[di].EMOMEM_createdObject[bx], \
		ss:[bp].CEMCIRP_newItem, ax

sendMessage:
	;
	; send MSG_EMOM_INITIALIZE_ITEM to ourselves so that the item
	; can be initialized
	;
	mov	si, dx				; *ds:si <- EMOM
	movdw	cxdx, ss:[bp].CEMCIRP_newItem	; ^lcx:dx <- new item
	mov	bp, ss:[bp].CEMCIRP_data	; bp <- response data
	mov	ax, MSG_EMOM_INITIALIZE_ITEM
	call	ObjCallInstanceNoLock
exit:
	.leave
	ret
EMOMExpressMenuObjectCreated	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMSetAckDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the new item created is of
		EMTriggerClass, if it is, set the destination of
		MSG_EMOM_ACK from the new item to this object.

		Increment the EMOMI_objectCount, the number of items
		we currently manage.

CALLED BY:	EMOMExpressMenuObjectCreated (Private)
PASS:		*ds:si	= EMObjectManagerClass object
		ds:di	= EMObjectManagerClass instance data
		ss:bp 	= CreateExpressMenuControlItemResponseParams
		cx	= index in EMOMI_classes data of this item
RETURN:		nothing
DESTROYED:	dx, ax, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMSetAckDest	proc	near
	uses	cx
	class	EMObjectManagerClass
	.enter
	;
	; check to see if this object is a subclass of EMTriggerClass
	; If it is, send it MSG_EMT_SET_EMOM_ACK_DEST to set this object as
	; the destanation of the MSG_EMOM_ACK, when it is destroyed.
	;
	push	ds, si
	mov	si, ds:[di].EMOMI_classes
	mov	ax, cx
	call	ChunkArrayElementToPtr		; ds:di = element
	movdw	cxdx, ds:[di].CEMCIP_class
 	segmov	ds, <segment EMTriggerClass>, si
	mov	si, offset EMTriggerClass
	movdw	esdi, cxdx
	call	ObjIsClassADescendant
	pop	ds, si
	jnc	doNotSetAck
	;
	; set the destination of MSG_EMOM_ACK
	;
	mov	cx, ds:[LMBH_handle]
	mov_tr	dx, si
	movdw	bxsi, ss:[bp].CEMCIRP_newItem
	mov	ax, MSG_EMT_SET_EMOM_ACK_DEST
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov_tr	si, dx
	mov	di, ds:[si]
doNotSetAck:
	.leave
	ret
EMOMSetAckDest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMGetArrayIndexBasedOnData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return the index of the EMOMI_classes entry that
		has CEMCIP_responseData = ax

CALLED BY:	EMOMExpressMenuObjectCreated (PRIVATE)
PASS:		ax	= data
		ds:di	= EMObjectManagerClass instance data
		*ds:si	= EMObjectManagerClass object
RETURN:		cx	= index

DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMGetArrayIndexBasedOnData	proc	near
	class	EMObjectManagerClass
	.enter

	push	si, di
	clr	cx
	mov	si, ds:[di].EMOMI_classes
	mov	bx, cs
	mov	di, offset EMOMGAIBOD_callback
	call	ChunkArrayEnum
	pop	si, di

	;
	; check to make sure found a class that had a matching index
	;
EC<	ERROR_NC EMOM_COULD_NOT_FIND_MATCHING_CLASS	>
	.leave

	ret
EMOMGetArrayIndexBasedOnData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMGAIBOD_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an entry with the indicated data and return its index


CALLED BY:	EMOMGetArrayIndexBasedOnData via ChunkArrayEnum (PRIVATE)
PASS:		cx	= index count
		ax	= data to compare
		ds:di	= CreateExpressMenuControlItemParams
RETURN:		if the data matches
			cx	= index of this entry
			stc
		if the data does not match
			cx 	= index of next entry
			clc
		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	increments cx  if this is not the the class with the
	data entry that matches ax, stc otherwise
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMGAIBOD_callback	proc	far
	.enter
	cmp	ax, ds:[di].CEMCIP_responseData
	je	foundIt
	;
	; did not find it so increment the index count and clc so that
	; it moves on to the next one
	;
	inc	cx
	clc
	jmp	exit	
foundIt:
	stc
exit:
	.leave
	ret
EMOMGAIBOD_callback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMOMEMOC_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches to see if the EMOMExpressMenu passed in
		contains the same ExpressMenuControl as the one passed in
		CEMCIRP_expressMenuControl. If it does, add the new item
		to the array kept for this express menu control

CALLED BY:	EMOMExpressMenuObjectCreated via ChunkArrayEnum (PRIVATE)
PASS:		ss:bp	- CreateExpressMenuControlItemResponseParams
		ds:di	- EMOMExpressMenu
		cx	- offset into array EMOMEM_createdObject

RETURN:		carry set if this record was for the same
			ExpressMenuControl
		carry clear if not

DESTROYED:	ax, bx, dx, si
SIDE EFFECTS:	created object will be destroyed if it's a duplicate

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMOMEMOC_callback	proc	far
	uses	bp
	.enter
	;
	; see if it is the same express menu control
	;
	mov	ax, ds:[di].EMOMEM_expressMenu.handle
	cmp	ax, ss:[bp].CEMCIRP_expressMenuControl.handle
	jne	diffControl
	mov	ax, ds:[di].EMOMEM_expressMenu.chunk
	cmp	ax, ss:[bp].CEMCIRP_expressMenuControl.chunk
	jne	diffControl
	;
	; Check to see if there is already an object in this slot. If
	; there is destroy the new object.
	;
	;   The reason for doing this is because we might get a
	; notification that an express menu has been created just
	; after we sent out a notification to add the objects to all
	; of the express menus.  We will respond to this express menu
	; created notification by adding our objects to it.  However,
	; this might be wrong, because our objects may have been
	; added to the express menu when we sent out the
	; notification for all express menus to add our objects,
	; thereby creating two of the same object in the express menu.
	; We get around this by deleting any objects with the same
	; response data in the same express menu here when the express
	; menu notifies us that the object was created.  
	;   During MSG_META_ATTACH we verify that no two entries in
	; EMOMI_classes have the same response data
	;
	mov	bx, cx

	tst	ds:[di].EMOMEM_createdObject[bx].handle		
	jz	addObject

	push	cx
	movdw	cxdx, ss:[bp].CEMCIRP_newItem
	movdw	bxsi, ss:[bp].CEMCIRP_expressMenuControl
	mov	ax, MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM
	mov	bp, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx

	jmp	done
	
	;
	; add the entry for this object to the array
	; EMOMEM_createdObject which keeps track of all of the objects
	; created for a particular express menu controller
	;
addObject:
	movdw	ds:[di].EMOMEM_createdObject[bx], \
		ss:[bp].CEMCIRP_newItem, ax
done:
	stc
	jmp	exit

diffControl:
	clc
exit:
	.leave
	ret
EMOMEMOC_callback	endp


EMOMCommon	ends
