COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	socket
MODULE:		access point database
FILE:		accpntList.asm

AUTHOR:		Eric Weber, May 18, 1995

ROUTINES:
	Name			Description
	----			-----------
	AccessPointSelectorQueryItemMoniker
INT	SelectorCreateCompoundMoniker

	APSSetSingleSelection	Set single selection & update triggers

	AccessPointSelectorDelete
	AccessPointSelectorDeleteOne
	AccessPointSelectorDeleteMulti

	AccessPointSelectorCreate
	AccessPointSelectorEdit	


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95   	Initial revision


DESCRIPTION:
	AccessPointSelectorClass
		

	$Id: accpntList.asm,v 1.20 98/05/29 19:01:39 jwu Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ControlCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSelectorQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name of an access point

CALLED BY:	MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
PASS:		*ds:si	= AccessPointSelectorClass object
		ds:di	= AccessPointSelectorClass instance data
		bp	= position of item requested
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointSelectorQueryItemMoniker	method dynamic AccessPointSelectorClass, 
					MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
		.enter
	;
	; if there are no real entries, this must be for the dummy item
	;
		mov	dx, si
		mov	si, offset AccessPointIDMap
		call	ChunkArrayGetCount			; cx = count
		jcxz	placeholder
	;
	; fetch the access point ID
	;
		mov	ax, bp
		call	ChunkArrayElementToPtr			; ds:di = elt
EC <		ERROR_C CORRUPT_ACCESS_ID_MAP			>
		mov	ax, ds:[di]
		mov	si, dx					; *ds:si = obj
	;
	; read the access point name
	;
		push	bp
		clr	cx
		mov	dx, APSP_NAME
		clr	bp
		call	AccessPointGetStringProperty		; ^hbx = name
		pop	bp
		jcxz	nullName
	;
	; add a bitmap, if needed
	;
		push	bx
		call	AccessPointGetType
		mov	ax,bx
		pop	bx
		mov	di, offset TelnetItemMoniker
		cmp	ax, APT_TELNET
		je	bitmapMoniker
		mov	di, offset TerminalItemMoniker
		cmp	ax, APT_TERMINAL
		je	bitmapMoniker
	;
	; set the list moniker to a simple string
	;
textMoniker::
		call	MemLock
		mov	cx, ax
		clr	dx					; cx:dx = name
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjCallInstanceNoLock
		call	MemFree
		jmp	done
	;
	; this is a dummy entry
	;
placeholder:
		call	GetPlaceholderString			; *es:di = str
		jmp	common
nullName:
		mov	di, offset NullNameString
		jc	common					; no tmp blk
		call	MemFree					; free tmp blk
common:
		mov	bx, handle AccessPointStrings
		call	MemLock
		mov	es, ax
		mov	cx, ax
		mov	dx, es:[di]				; cx:dx = str
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		mov	si, offset AccessList
		call	ObjCallInstanceNoLock
		call	MemUnlock
		jmp	done
	;
	; set the list moniker to a VisMoniker
	;
bitmapMoniker:
		call	SelectorCreateCompoundMoniker
		mov	ax,bp
		sub	sp, size ReplaceItemMonikerFrame
		mov	bp,sp
		mov	ss:[bp].RIMF_source.handle, bx
		clr	ss:[bp].RIMF_source.offset
		mov	ss:[bp].RIMF_sourceType, VMST_HPTR
		mov	ss:[bp].RIMF_dataType, VMDT_GSTRING
		mov	ss:[bp].RIMF_length, cx
		clr	ss:[bp].RIMF_width
		clr	ss:[bp].RIMF_height
		clr	ss:[bp].RIMF_itemFlags
		mov	ss:[bp].RIMF_item, ax
		
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
		mov	si, offset AccessList
		call	ObjCallInstanceNoLock
		add	sp, size ReplaceItemMonikerFrame
		call	MemFree
done:
		.leave
		ret
		
AccessPointSelectorQueryItemMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPlaceholderString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine what moniker to use for an empty list

CALLED BY:	(INTERNAL) AccessPointSelectorQueryItemMoniker
PASS:		ds	- segment of list object
RETURN:		di	- offset of string in string segment
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	5/16/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPlaceholderString	proc	near
		uses	ax,bx,cx,dx,si,bp
		.enter
	;
	; ask the controller what type it is
	;
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_TYPE
		call	ObjBlockGetOutput
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; is it a calling card controller?
	;
		cmp	ax, APT_CALLING_CARD
		jne	normal
		mov	di, offset PhonePlaceholderString
		jmp	done
	;
	; all other types get the generic string
	;
normal:
		mov	di, offset PlaceholderString
done:
		.leave
		ret
GetPlaceholderString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectorCreateCompoundMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a compound moniker

CALLED BY:	AccessPointSelectorQueryItemMoniker
PASS:		^hbx	- item name
		cx	- item name length
		di	- offset of bitmap
RETURN:		cx	- size of gstring
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectorCreateCompoundMoniker	proc	near
		uses	ax,bx,dx,si,di,bp,ds,es
		.enter
	;
	; make room in the block containing the name
	;
mra::
DBCS <		shl	cx						>
		push	cx
		mov	ax, cx
		add	ax, size OpDrawBitmapOptr + size OpDrawText + size OpEndGString + size TCHAR
		mov	ch, mask HAF_LOCK
		call	MemReAlloc		; ax = segment
		pop	cx
	;
	; now shift the string down to make room for the bitmap and the
	; text headers
	;
sdown::
		push	cx,di
		mov	ds,ax
		mov	es,ax
		mov	si, cx
		mov	di, si
		add	di, size OpDrawBitmapOptr + size OpDrawText
		inc	cx			; include null
DBCS <		inc	cx						>
		std
		rep	movsb
		cld
		pop	cx,di
	;
	; put an OpDrawBitmapOptr at the top of the block
	;
odbop::
		mov	ds:[ODBOP_opcode], GR_DRAW_BITMAP_OPTR
		clr	ds:[ODBOP_x]
		clr	ds:[ODBOP_y]
		mov	ds:[ODBOP_optr].handle, handle AccessPointStrings
		mov	ds:[ODBOP_optr].offset, di
	;
	; get the width of the bitmap
	;
gwidth::
		push	bx
		mov	bx, handle AccessPointStrings
		call	MemLock
		mov	es,ax
		mov	di, es:[di]
		mov	ax, es:[di].B_width
		call	MemUnlock
		pop	bx
		add	ax, ITEM_BITMAP_SPACING
	;
	; now put in the text opcode
	;
odt::
		mov	ds:[size OpDrawBitmapOptr][ODT_opcode], GR_DRAW_TEXT
		mov	ds:[size OpDrawBitmapOptr][ODT_x1], ax
		mov	ds:[size OpDrawBitmapOptr][ODT_y1], 0
DBCS <		shr	cx						>
		mov	ds:[size OpDrawBitmapOptr][ODT_len], cx
DBCS <		shl	cx						>
	;
	; add an END marker
	;
oegs::
		add	cx, size OpDrawBitmapOptr + size OpDrawText + size TCHAR
		mov	si, cx
		mov	{byte}ds:[si], GR_END_GSTRING
	;
	; return size of string
	;
rval::
		add	cx, size OpEndGString
		.leave
		ret
SelectorCreateCompoundMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APSSetSingleSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a single selection in the list.  Intercepted to
		enable/disable triggers as may be affected by selection
		and number of entries in list.

CALLED BY:	MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
PASS:		*ds:si	= AccessPointSelectorClass object
		es	= segment of AccessPointSelectorClass
		ax	= message #
		cx	= identifier of the item to select
		dx	= non-zero if indeterminate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		Let superclass make selection.
		If no triggers, don't do anything.
		Get selection ID if any and update triggers.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	12/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APSSetSingleSelection	method dynamic AccessPointSelectorClass, 
					MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	;
	; Let superclass make the selection first.
	;
		push	cx
		mov	di, offset AccessPointSelectorClass
		call	ObjCallSuperNoLock
		pop	cx
if _EDIT_ENABLE
	;
	; Do nothing if there are no triggers.
	;
		push	cx
		call	ObjBlockGetOutput
		mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES	
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax = features mask
		pop	cx

		Assert	record, ax, AccessPointControlFeatures
		test	ax, mask APCF_EDIT
		jz	done
	;
	; If no access points, the selection is a dummy.
	;
		mov	ax, cx				; save index
		mov	si, offset AccessPointIDMap
		call	ChunkArrayGetCount		; cx = count
		jcxz	noEntries
	;
	; Map selection to ID & update triggers.
	;
		mov	si, offset AccessPointIDMap
		call	ChunkArrayElementToPtr
		mov	ax, ds:[di]			; ax = accpnt ID
noEntries:
		call	UpdateTriggersForSelection
done:
endif ; _EDIT_ENABLE
		ret


APSSetSingleSelection	endm

if _EDIT_ENABLE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateTriggersForSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/disable triggers based on selection(s).

CALLED BY:	APSSetSingleSelection
		LockAccessPointHandler

PASS:		ds	= segment of object block
		ax	= accpnt ID of selection, if any
		cx	= number of accpnts total

RETURN:		nothing

DESTROYED:	ax, bx,cx, dx, bp, di, si, es

PSEUDO CODE/STRATEGY:
		If no access points or accpnt in use, disable edit
		else enable edit

		if more than 1 access point, update delete same as edit
		else disable delete

		if list is not empty, enable app's object
		else disable app's object

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/18/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateTriggersForSelection	proc	near

		.enter
	;
	; If access point is in use by a connection, disable edit
	; trigger.  Else enable it.
	;
		mov	dx, cx				; save count
		jcxz	noEntries

		mov	cx, MSG_GEN_SET_ENABLED
		call	AccessPointInUse
		jnc	update
noEntries:
		mov	cx, MSG_GEN_SET_NOT_ENABLED
update:
		push	cx, dx				; save count & msg
		mov_tr	ax, cx
		mov	dl, VUM_NOW
		mov	si, offset AccessEditTrigger
		call	ObjCallInstanceNoLock
		pop	ax, dx				; ax = msg, dx = count
	;
	; Treat the delete trigger the same as edit.
	;
		push	dx				; save count for later
		mov	dl, VUM_NOW
		mov	si, offset AccessDeleteTrigger
		call	ObjCallInstanceNoLock		
	;
	; Get enableDisable object and enable it if it exists.
	; If there are no entries, then we disable it.
	; 
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_ENABLE_DISABLE
		call	ObjBlockGetOutput	; ^lbx:si = output
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		movdw	bxsi, cxdx		; ^lbx:si = object to enable
		pop	dx			; dx = count

		tst	bx
		jz	done

		mov	ax, MSG_GEN_SET_ENABLED
		tst	dx
		jnz	updateEnableDisable

		mov	ax, MSG_GEN_SET_NOT_ENABLED
updateEnableDisable:
		mov	dl, VUM_NOW
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		call	ObjMessage

done:
		.leave
		ret
UpdateTriggersForSelection	endp
endif ; _EDIT_ENABLE		
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSelectorDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an access point

CALLED BY:	MSG_ACCESS_POINT_SELECTOR_DELETE
PASS:		*ds:si	= AccessPointSelectorClass object
		ds:di	= AccessPointSelectorClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/27/95   	Initial version
	jwu	1/01/97		multiple deletions supported

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AccessPointSelectorDelete	method dynamic AccessPointSelectorClass, 
					MSG_ACCESS_POINT_SELECTOR_DELETE
		.enter
	;
	; make sure there are at least two items
	;
		mov	si, offset AccessPointIDMap
		call	ChunkArrayGetCount		; cx=count
		cmp	cx,1
EC <		WARNING_BE IGNORING_DELETE_REQUEST			>
		jbe	done

	;
	; suspend input
	;
		clr	bx
		call	GeodeGetAppObject
		mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Figure out how many items we're deleting.  Single &
	; multiple deletes require different processing & error msgs.
	;
		call	ObjBlockGetOutput
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_NUM_SELECTIONS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax = count

		cmp	ax, 1
		jb	resume
		ja	multi

		call	AccessPointSelectorDeleteOne
		jmp	resume
multi:
		call	AccessPointSelectorDeleteMulti		; dx = type


resume:
	;
	; record a resume-input event
	;
		clr	bx
		call	GeodeGetAppObject
		mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
		mov	di, mask MF_RECORD
		call	ObjMessage			; di = event
	;
	; after the controller has handled the deletion notification
	; it will dispatch the resume-input event on to the application
	;
		call	ObjBlockGetOutput		; ^lbx:si = controller
		mov	ax, MSG_META_DISPATCH_EVENT
		mov	cx, di				; event to send
		mov	dx, mask MF_FORCE_QUEUE		; flags for sending it
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		.leave
		ret

AccessPointSelectorDelete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSelectorDeleteOne
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete one access point.

CALLED BY:	AccessPointSelectorDelete

PASS:		^lbx:si	= controller
		ds	= segment of AccessPointSelectorClass object	
		
RETURN:		carry set if deletion failed

DESTROYED:	ax, cx, dx, di, bp  

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/ 1/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointSelectorDeleteOne	proc	near

	;
	; Figure out which access point to delete & delete it
	; from the database.
	;
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax = selection

		call	AccessPointDestroyEntry		; carry set if error

		ret
AccessPointSelectorDeleteOne	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSelectorDeleteMulti
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete more than one access point.

CALLED BY:	AccessPointSelectorDelete

PASS:		^lbx:si	= controller
		ds	= segment of AccessPointSelectorClass object
		ax	= number of selections

RETURN:		carry set if one or more couldn't be deleted
		dx	= entry type

DESTROYED:	ax, bx, cx, di, si, bp, es

PSEUDO CODE/STRATEGY:
		Alloc block (size = num selections + 1 for count and
			get selected IDs.
		Delete selected IDs without notification, allowing
			list to become empty.
		When done, generate batched notification.
NOTES:
		Do NOT free block.  Needed for notification.

		Letting the list become empty isn't very nice,
		but it's too hard to figure out which one not to
		delete.  

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/ 1/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointSelectorDeleteMulti	proc	near

	;
	; Allocate block for IDs of selections.  
	;
		push	ax, bx
		inc	ax				; add 1 for ocunt
		shl	ax				; word sized IDs
		mov	cx, (HAF_STANDARD_LOCK shl 8) or \
				(mask HF_SHARABLE or mask HF_SWAPABLE)
		call	MemAlloc
		mov	es, ax
		clr	di				
		mov	bp, bx				; save block handle
		pop	ax, bx				; ax = count
	;
	; Store count & get selection IDs.
	;
		push	bp		
		stosw					; es:di adjusted

		movdw	cxdx, esdi
		mov_tr	bp, ax				; bp = count
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_MULTIPLE_SELECTIONS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax = count
	;
	; Delete each of the selections.  Batch notifications
	; until the end.
	;
		push	ds
		movdw	dssi, cxdx			; ds:si = IDs
		mov_tr	cx, ax				; cx = count
		clr	bp
deleteLoop:
		lodsw					; ax = selection
		call	AccessPointDestroyEntryNoNotify ; dx = type

		adc	bp, 0				; track errors
		loop	deleteLoop
		pop	ds
	;
	; Unlock block of IDs and send notification.
	;
		pop	bx
		call	MemUnlock
		call	AccessPointMultiDestroyDone
	;
	; Report if there were any errors.
	;
		tst_clc	bp
		jz	done
		stc					; return error
done:
		ret

AccessPointSelectorDeleteMulti	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSelectorCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an access point

CALLED BY:	MSG_ACCESS_POINT_SELECTOR_CREATE
PASS:		*ds:si	= AccessPointSelectorClass object
		ds:di	= AccessPointSelectorClass instance data
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	
	
PSEUDO CODE/STRATEGY:
	We do not directly add the new access point to ourselves, but let
	the controller do that in response to a notification from
	AccessPointCreateEntry.  Since that notification is queued, we must
	also queue our requests to select and edit the new item, since
	it won't be valid until the notification is received.   Hence we
	have to do some fancy footwork to keep input suspended until the
	output has had a chance to see the edit message.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointSelectorCreate	method dynamic AccessPointSelectorClass, 
					MSG_ACCESS_POINT_SELECTOR_CREATE
		.enter
	;
	; check disk space
	;
	;
	; suspend input
	;
		clr	bx
		call	GeodeGetAppObject
		mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; ask the controller what type we are
	;
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_TYPE
		call	ObjBlockGetOutput		; ^lbx:si = controller
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax = type
	;
	; get current selection
	;
		push	ax
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax = selection
	;
	; create an entry in the database before the current selection
	; if no current selection (cx=0), it goes at the end
	;
		mov	bx, ax				; bx = selection
		pop	ax				; ax = type
		call	AccessPointCreateEntry		; ax = entry ID
	;
	; select it
	;
		mov	cx, ax
		call	ObjBlockGetOutput		; ^lbx:si = controller
		mov	ax, MSG_ACCESS_POINT_CONTROL_SET_SELECTION
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; edit it
	;
		mov	ax, MSG_ACCESS_POINT_CONTROL_SEND_EDIT_MSG
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; resume input, in a roundabout sorta way
	;
	; 1. list queues message to controller
	; 2. controller queues message to its output
	; 3. output object queues message back to application
	;
resume::
	;
	; step 3: tell application to resume input
	;
		clr	bx
		call	GeodeGetAppObject
		mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
		mov	di, mask MF_RECORD
		call	ObjMessage			; di = event
	;
	; step 2: tell something to do step 3
	;
		clrdw	bxsi
		mov	ax, MSG_META_DISPATCH_EVENT
		mov	cx, di
		mov	dx, mask MF_FORCE_QUEUE
		mov	di, mask MF_RECORD
		call	ObjMessage
	;
	; step 1: tell controller to tell output about step 2 
	;
		call	ObjBlockGetOutput
		mov	ax, MSG_GEN_CONTROL_OUTPUT_ACTION
		mov	bp, di
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done::		
		.leave
		ret
AccessPointSelectorCreate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSelectorEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Edit the current selection

CALLED BY:	MSG_ACCESS_POINT_SELECTOR_EDIT
PASS:		*ds:si	= AccessPointSelectorClass object
		ds:di	= AccessPointSelectorClass instance data
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointSelectorEdit	method dynamic AccessPointSelectorClass, 
					MSG_ACCESS_POINT_SELECTOR_EDIT
		.enter
	;
	; check disk space
	;
	;
	; get the current selection
	;
		call	ObjBlockGetOutput		; ^lbx:si = controller
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax = selection
		jc	done
	;
	; otherwise make it the current value
	;
		mov	cx, ax				; cx = selection
		mov	ax, MSG_ACCESS_POINT_CONTROL_SEND_EDIT_MSG
		mov	di, mask MF_CALL
		call	ObjMessage
done:
		.leave
		ret
AccessPointSelectorEdit	endm

ControlCode	ends
