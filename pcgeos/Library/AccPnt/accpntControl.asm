COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	socket
MODULE:		access point database
FILE:		accpntControl.asm

AUTHOR:		Eric Weber, May  3, 1995

ROUTINES:
	Name			Description
	----			-----------
	AccessPointControlGetInfo
	AccessPointControlTweakDuplicatedUI
	AddDefineTrigger
	CopyListMoniker
	MakeListMultiselectable
	AccessPointControlGenControlAddAppUi

	AccessPointControlAddToGCNLists
	AccessPointControlRemoveFromGCNLists

    INT AccessPointInitializeList 
				Initialize the chunk array and dynamic list

	AccessPointControlNotifyWithDataBlock

    INT NewAccessPointHandler   A new access point has been created

    INT DeletedAccessPointHandler 
				An access point has been deleted
    INT ChangedAccessPointHandler 
				Possibly update a moniker
    INT MultiDeletedAccessPointHandler
				Multiple access points have been deleted

	AccessPointControlSetType
	AccessPointControlGetType
	AccessPointControlSetSelection

    INT SetSelectionLow

	AccessPointControlGetSelection
	GetSelectionFromVardata
	GetSelectionFromList
	SetSelectionInVardata

	AccessPointControlGetNumSelections
	AccessPointControlGetMultipleSelections
	AccessPointMapSelectionsToIDs

	AccessPointControlUpdateSelection
	AccessPointControlUpdateSingleSelection
	AccessPointControlUpdateNoSelection
	AccessPointUpdateTriggers
	AccessPoitnControlUpdateManySelections

	AccessPointControlGenApply

    INT GetSelectionLow         Get the current selection

    INT GetChildSegment         Get the segment containing the controller
				UI


	AccessPointControlGetEditMsg
	AccessPointControlSetEditMsg
	AccessPointControlSendEditMsg

	AccessPointControlSetEnableDisable
	AccessPointControlGetEnableDisable

	AccessPointControlChangingLevels
	AccessTwoLevelTriggerInitialize
	AccessTwoLevelTriggerActivatedOtherLevel

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/ 3/95   	Initial revision


DESCRIPTION:
	Implementation of AccessPointControlClass
		
	$Id: accpntControl.asm,v 1.33 98/05/29 18:59:40 jwu Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ControlCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return our build info

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= AccessPointControlClass object
		cx:dx - GenControlBuildInfo structure to fill in
RETURN:		nothing	
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlGetInfo	method dynamic AccessPointControlClass, 
					MSG_GEN_CONTROL_GET_INFO
		uses	cx
		.enter
		mov	si, offset APC_dupInfo
		segmov	ds, cs				; ds:si = source
		mov	es, cx
		mov	di, dx				; es:di = dest
		mov	cx, size GenControlBuildInfo
		rep	movsb
		.leave
		ret
AccessPointControlGetInfo	endm

APC_dupInfo	GenControlBuildInfo <
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ;GCBI_flags
	0,					; GCBI_initFileKey
	0,					; GCBI_gcnList
	0,					; GCBI_gcnCount
	0,					; GCBI_notificationList
	0,					; GCBI_notificationCount
	0,					; GCBI_controllerName

	handle AccessPointTemplate,		; GCBI_dupBlock
	APC_childList,				; GCBI_childList
	length APC_childList,			; GCBI_childCount
	APC_featuresList,			; GCBI_featuresList
	length APC_featuresList,		; GCBI_featuresCount
	mask APCF_LIST,				; GCBI_features
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

if _EDIT_ENABLE
APC_childList	GenControlChildInfo	\
	< offset AccessList,
	  mask APCF_LIST,
	  mask GCCF_IS_DIRECTLY_A_FEATURE>,
	< offset AccessTrigChild,
	  mask APCF_EDIT or mask APCF_TWOLEVEL,
	  0>

APC_featuresList GenControlFeaturesInfo	\
	< offset AccessList,
	  0,
	  0>,
	< offset AccessEditTrigger,
	  0,
	  0>,
	< offset AccessBackTrigger,
	  0,
	  0>

else
APC_childList	GenControlChildInfo	\
	< offset AccessList,
	  mask APCF_LIST,
	  mask GCCF_IS_DIRECTLY_A_FEATURE>

APC_featuresList GenControlFeaturesInfo	\
	< offset AccessList,
	  0,
	  0>
endif
	  
if _FXIP
ControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlTweakDuplicatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the list a popup and init edit buttons

CALLED BY:	MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
PASS:		*ds:si	= AccessPointControlClass object
		cx	= duplicated block handle
		dx	= features mask
RETURN:		nothing
DESTROYED:	ax,bx,cx,ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlTweakDuplicatedUI	method dynamic AccessPointControlClass, 
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
		.enter
if	_EDIT_ENABLE
	;
	; if we've got a two-level trigger, add it to the APP_UI list
	;
		test	dx, mask APCF_EDIT
		jz	checkList
		test	dx, mask APCF_TWOLEVEL
		jz	noTwoLevel
		call	AddDefineTrigger
	;
	; see if we should activate the second level now
	;
		mov	ax,  ATTR_ACCESS_POINT_CONTROL_SECOND_LEVEL_ACTIVE
		call	ObjVarFindData
		jnc	checkList
	;
	; if there's no two-level trigger, or if we're supposed to start
	; on the second level, make the edit triggers usable
	;
noTwoLevel:
		push	dx, si
		mov	ax, MSG_GEN_SET_USABLE
		mov	dx, VUM_DELAYED_VIA_UI_QUEUE
		mov	bx, cx
		mov	si, offset AccessTrigGroup
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	dx, si
endif
	;
	; initialize list if necessary
	;
checkList::
		test	dx, mask APCF_LIST
		jz	done
	;
	; intall a moniker on the list, if needed
	;
		call	CopyListMoniker
	;
	; Make list non-exclusive, if needed.
	;
		call	MakeListMultiselectable
	;
	; look for the minimize hint
	;
		mov	ax, HINT_ACCESS_POINT_CONTROL_MINIMIZE_SIZE
		call	ObjVarFindData			; carry set if found
		jnc	done
	;
	; lock the child block
	;
		mov	bx, cx
		call	ObjLockObjBlock
		mov	ds, ax
	;
	; add the hints to the dynamic list
	;
		mov	si, offset AccessList		; *ds:si = list
		clr	cx				; no extra data
	;
	; add item group hints
	;
		mov	ax, HINT_ITEM_GROUP_MINIMIZE_SIZE
		call	ObjVarAddData
		mov	ax, HINT_ITEM_GROUP_DISPLAY_CURRENT_SELECTION
		call	ObjVarAddData
	;
	; release child block
	;
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
done:
		.leave
		ret
AccessPointControlTweakDuplicatedUI	endm

if _EDIT_ENABLE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddDefineTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add AccessDefineTrigger to APP_UI vardata

CALLED BY:	AccessPointControlTweakDuplicatedUI
PASS:		*ds:si	- controller
		cx	- duplicted block handle
RETURN:		*ds:si	- controller (possibly moved)
DESTROYED:	nothing
SIDE EFFECTS:	may cause block or chunk to move
		discards any previous values in the attribute

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddDefineTrigger	proc	near
		uses	bx
		.enter
	;
	; check whether we already have app UI
	;
		push	cx
		mov	ax, ATTR_GEN_CONTROL_APP_UI
		mov	cx, size optr
		call	ObjVarAddData
		pop	cx
	;
	; put in optr of define trigger
	;
		mov	ds:[bx].handle, cx
		mov	ds:[bx].offset, offset AccessDefineTrigger

		.leave
		ret
AddDefineTrigger	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy moniker from vardata to list object

CALLED BY:	AccessPointControlTweakDuplicatedUI
PASS:		*ds:si	= AccessPointControl object
		cx	= child block
RETURN:		ds	- fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyListMoniker	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; look for a moniker attribute
	;
		mov	ax, ATTR_ACCESS_POINT_CONTROL_LIST_MONIKER
		call	ObjVarFindData			; **ds:bx = text
		jnc	done
		mov	si, ds:[bx]			; *ds:si = text
		mov	di, ds:[si]			; ds:di = text
	;
	; update a normal moniker
	;
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	bx, cx
		mov	si, offset AccessList		; ^lbx:si = list
		movdw	cxdx, dsdi			; cx:dx = mkr string
		mov	bp, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret
CopyListMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeListMultiselectable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make list multiselectable if needed.

CALLED BY:	AccessPointControlTweakDuplicatedUI

PASS:		*ds:si	= AccessPointControl object
		cx	= child block

RETURN:		ds	= fixed up

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/ 1/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeListMultiselectable	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter
	;
	; If the hint exists, make list non-exclusive.
	;
		mov	ax, HINT_ACCESS_POINT_CONTROL_MULTISELECTABLE
		call	ObjVarFindData
		jnc	done
		
		mov	bx, cx
		mov	si, offset AccessList
		mov	ax, MSG_GEN_ITEM_GROUP_SET_BEHAVIOR_TYPE
		mov	cl, GIGBT_NON_EXCLUSIVE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret
MakeListMultiselectable	endp


if _EDIT_ENABLE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlGenControlAddAppUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the define trigger to the UI

CALLED BY:	MSG_GEN_CONTROL_ADD_APP_UI
PASS:		*ds:si	= AccessPointControlClass object
		ds:di	= AccessPointControlClass instance data
		^lcx:dx	= object to add
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlGenControlAddAppUi	method dynamic AccessPointControlClass, 
					MSG_GEN_CONTROL_ADD_APP_UI
	;
	; rearrange pointers
	;
		movdw	bxsi, cxdx
		movdw	cxdx, ds:[di].APCI_defineParent
		mov	bp, ds:[di].APCI_defineSlot
	;
	; the only object we should see here is the define trigger
	;
		Assert	objectOD, bxsi, AccessTwoLevelTriggerClass
	;
	; tell the trigger to initialize itself and add itself into
	; the gen tree
	;
		mov	ax, MSG_ACCESS_TWO_LEVEL_TRIGGER_INITIALIZE
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; when we return, GenControlClass will set the trigger usable
	;
		ret
AccessPointControlGenControlAddAppUi	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlAddToGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add controller to GCNSLT_ACCESS_POINT_CHANGE

CALLED BY:	MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
PASS:		*ds:si	= AccessPointControlClass object
		ds:di	= AccessPointControlClass instance data
RETURN:		nothing
DESTROYED:	bx,ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlAddToGCNLists	method dynamic AccessPointControlClass, 
					MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
		uses	ax, cx, dx, bp
		.enter
	;
	; add ourselves to the GCN list
	;
		mov	bp, ds:[di].APCI_type
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_ACCESS_POINT_CHANGE
		call	GCNListAdd
	;
	; see if we have UI to update
	;
		call	GetChildSegment		; ax=segment, bx=features
		jz	done
		mov	ds, ax
		Assert	record, bx, AccessPointControlFeatures
		test	bx, mask APCF_LIST
		jz	noList
	;
	; update it
	;
		mov	ax, bp			; ax = APCI_type
		call	AccessPointInitializeList
noList:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
done:
		.leave
		ret
AccessPointControlAddToGCNLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlRemoveFromGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove controller from GCNSLT_ACCESS_POINT_CHANGE

CALLED BY:	MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
PASS:		*ds:si	= AccessPointControlClass object
		ds:di	= AccessPointControlClass instance data
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlRemoveFromGCNLists	method dynamic AccessPointControlClass, 
					MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
		uses	ax, cx, dx, bp
		.enter
	;
	; remove ourselves from the GCN list
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_ACCESS_POINT_CHANGE
		call	GCNListRemove
		.leave
		ret
AccessPointControlRemoveFromGCNLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointInitializeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the chunk array and dynamic list

CALLED BY:	AccessPointGenerateUI,
		AccessPointControlNotifyWithDataBlock
PASS:		ds	= child segment
		ax	= value of APCI_type
		bx	= feature mask
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointInitializeList	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; if no list, get out
	;
		Assert	record, bx, AccessPointControlFeatures
		test	bx, mask APCF_LIST
		jz	done
	;
	; initialize the chunk array
	;
		mov	si, offset AccessPointIDMap
		call	AccessPointGetEntries		; *ds:si = array
	;
	; figure out how many entries to put in the list
	;
	; there will always be at least one, since a placeholder is
	; displayed if there are no entry points
	;
		call	ChunkArrayGetCount		; cx = count
		tst	cx
		jnz	gotCount
		inc	cx
gotCount:
	;
	; initialize the list with the count
	;
		mov	si, offset AccessList
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallInstanceNoLock
	;
	; redisplay current selection
	;
		call	GetSelectionFromVardata		; cx = selection
		call	SetSelectionLow			; cx = first item
		jnc	done
	;
	; if that doesn't work, just go with the first item
	;
		call	SetSelectionInVardata
		mov     ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
                clr     cx, dx
                call    ObjCallInstanceNoLock
done:
		.leave
		ret
AccessPointInitializeList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle change notifications

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK
PASS:		*ds:si	= AccessPointControlClass object
		es 	= segment of AccessPointControlClass
		ax	= message #

		cx	= NT_manuf
		dx	= NT_type
		bp	= data block
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	screen message to be sure it's one we want to handle
	if so, pass it to a handler function based on the change type
	if the handler can't locate the specific point to be updated,
          update the entire list instead

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

notifyHandlerTable	nptr.near \
	NewAccessPointHandler,
	DeletedAccessPointHandler,
	ChangedAccessPointHandler,
	MultiDeletedAccessPointHandler,
	LockAccessPointHandler

AccessPointControlNotifyWithDataBlock	method dynamic AccessPointControlClass, 
					MSG_META_NOTIFY_WITH_DATA_BLOCK
		uses	ax, cx, dx, bp, si, ds, es
		.enter
	;
	; only handle access point changes
	;
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	done
		cmp	dx, GWNT_ACCESS_POINT_CHANGE
		jne	done
	;
	; only handle changes to the right type of access point
	;
		mov	bx, bp
		call	MemLock
		mov	es, ax
		mov	ax, es:[APCD_accessType]
		cmp	ax, ds:[di].APCI_type
		jne	unlockData
	;
	; lock the child block
	; if no child block - do nothing
	;
		mov	dx, ax
		call	GetChildSegment		; ax=seg (z set if none),
						; bx=features
		jz	unlockData
		mov	ds, ax
		Assert	record, bx, AccessPointControlFeatures
		test	bx, mask APCF_LIST
		jz	unlockChild
	;
	; call the appropriate handler
	;
		mov	si, es:[APCD_changeType]
		Assert	etype, si, AccessPointChangeType
		cmp	si, size notifyHandlerTable
		jae	unlockData
		call	cs:[notifyHandlerTable][si]	; carry to reinitialize
		jnc	unlockChild
	;
	; we couldn't find the referenced access point
	; reinitialize the list
	;
		mov	ax, es:[APCD_accessType]
		call	AccessPointInitializeList
	;
	; unlock the child block
	;
unlockChild:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
	;
	; unlock the notification block
	;
unlockData:
		mov	bx, bp
		call	MemUnlock
	;
	; let superclass decrement ref count on block
	;
done:
		.leave
		mov	di, offset AccessPointControlClass
		GOTO	ObjCallSuperNoLock
AccessPointControlNotifyWithDataBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NewAccessPointHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A new access point has been created

CALLED BY:	AccessPointControlNotifyWithDataBlock
PASS:		ds	- child segment
		es	- AccessPointChangeDescription
		dx	- AccessPointType
		bx	- feature mask
RETURN:		carry set to reinitialize list
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NewAccessPointHandler	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; if this is the first access point, always reinitialize
	; the list to get rid of the placeholder
	;
		mov	si, offset AccessPointIDMap
		mov	di, ds:[si]
		tst	ds:[di].CAH_count
		stc
		jz	done
		mov	ax, dx
		call	AccessPointGetEntries		; *ds:si = array
	;
	; locate the newly added item
	;
		mov	ax, es:[APCD_id]
		mov	di, ds:[si]
		segmov	es, ds
		mov	cx, es:[di].CAH_count
		mov	dx, cx
		add	di, es:[di].CAH_offset
		repne	scasw
		stc
		jne	done			; somebody is confused
	;
	; compute it's index
	;
		sub	cx, dx
		not	cx			; cx = 0 based index
	;
	; insert an item in list
	;
		push	ax
		mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
		mov	dx,1
		mov	si, offset AccessList
		call	ObjCallInstanceNoLock
		pop	cx			; cx = AccessPointID
	;
	; If in multiselect mode, set the selection to ensure we get
	; out of multiselect mode and update triggers.  Must use
	; AccessPointControl API to make sure that all state gets
	; updated correctly.  
	;
		push	cx
		call	ObjBlockGetOutput	; ^lbx:si = AccessPointControl
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_NUM_SELECTIONS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ax = # selections
		pop	cx
		
		cmp	ax, 1
		jbe	clcDone
		
		mov	ax, MSG_ACCESS_POINT_CONTROL_SET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
clcDone:
		clc
done:
		.leave
		ret
NewAccessPointHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeletedAccessPointHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An access point has been deleted

CALLED BY:	AccessPointControlNotifyWithDataBlock
PASS:		ds	- child segment
		es	- AccessPointChangeDescription
		dx	- AccessPointType
		bx	- feature mask
RETURN:		carry set to reinitialize list
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeletedAccessPointHandler	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; look up the access point
	;
		mov	ax, es:[APCD_id]
		segmov	es, ds
		mov	si, offset AccessPointIDMap
		mov	di, ds:[si]
		mov	cx, es:[di].CAH_count
		mov	dx, cx			; dx = count
		add	di, es:[di].CAH_offset
		repne	scasw
		stc
		jne	exit		; we're confused
	;
	; delete the array entry
	;
		dec	di
		dec	di
		call	ChunkArrayDelete
	;
	; get the selection index of current selection (in case
	; it has changed since Delete was pressed).
	;
		push	cx, dx
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	si, offset AccessList
		call	ObjCallInstanceNoLock
		pop	cx, dx			; cx = # after match
	;
	; delete the list entry and update triggers in case list
	; has become empty
	;
		push	ax			; ax = selection
		sub	cx, dx
		not	cx			; cx = index of accpnt in list
		push	cx, dx
		mov	dx,1
		mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
		call	ObjCallInstanceNoLock
		pop	cx, dx			; cx = item removed, dx = count
		pop	ax			; ax = old selection
	;
	; If we removed the selection, select the next item by
	; setting the selection to the index we just removed.
	; If we removed the last selection, select last item.
	;
		dec	dx		; dx = new count
		jz	empty

		cmp	ax, cx		; cmp selection to item removed
		jne	done
		cmp	ax, dx		; cmp selection to size of list
		jb	setSel
		mov	ax, dx
		dec	ax		; ax = last index
setSel:
		mov_tr	cx, ax
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		call	ObjCallInstanceNoLock
	;
	; mark the list modified
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
		mov	cx, BW_TRUE
		call	ObjCallInstanceNoLock
	;
	; is list in delayed mode?
	;
		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, GUQT_DELAYED_OPERATION
		call	ObjCallInstanceNoLock		; ax=nonzero if delayed
		tst	ax
		jnz	done
	;
	; if not, have it notify control of new selection
	;
		mov	ax, MSG_GEN_APPLY
		call	ObjCallInstanceNoLock
done:
		clc
exit:
		.leave
		ret
empty:
	;
	; list is now empty
	;
	; punt to AccessPointInitializeList, which will insert the
	; placeholder entry
	;
		stc
		jmp	exit
DeletedAccessPointHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangedAccessPointHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Possibly update a moniker

CALLED BY:	AccessPointControlNotifyWithDataBlock
PASS:		ds	- child segment
		es	- AccessPointChangeDescription
		dx	- AccessPointType
RETURN:		carry set to reinitialize list
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangedAccessPointHandler	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; see if the name changed
	;
		mov	di, offset APCD_property
		mov	dx, APSP_NAME
		call	AccessPointCompareStandardProperty	; z if equal
		clc
		jne	done
	;
	; look up the access point
	;
		mov	ax, es:[APCD_id]
		segmov	es, ds
		mov	si, offset AccessPointIDMap
		mov	di, ds:[si]
		mov	cx, es:[di].CAH_count
		mov	dx, cx
		add	di, es:[di].CAH_offset
		repne	scasw
		stc
		jne	done				; we're confused
	;
	; update it
	;
		sub	cx, dx
		not	cx
		mov	bp, cx				; bp = item index
		mov	cx, ds:[LMBH_handle]
		mov	dx, offset AccessList
		mov	ax, MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
		mov	si, offset AccessList
		call	ObjCallInstanceNoLock
		clc
done:
		.leave
		ret
ChangedAccessPointHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MultiDeletedAccessPointHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A group of access points have been deleted.

CALLED BY:	AccessPointControlNotifyWithDataBlock

PASS:		ds	= child segment
		es	= AccessPointChangeDescription
		dx	= AccessPointType
		bx	= feature mask

RETURN:		carry set to reinitialize list

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/ 1/97			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MultiDeletedAccessPointHandler	proc	near
	;
	; Eventually this routine needs to enumerate through the list of
	; IDs, removing each one from the chunk array and from the dynamic
	; list.  If we delete all of the selections (either the selections
	; stored in vardata or the selections of the dynamic list), we
	; need to choose a new selection in a reasonable way.
	;
	; For now, we skip all of that and just rebuild the list from
	; scratch.
	;
		stc
		ret
		
MultiDeletedAccessPointHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockAccessPointHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An access point's lock status has changed.  Update UI
		if necessary.

CALLED BY:	AccessPointControlNotifyWithDataBlock

PASS:		ds	= child segment
		es	= AccessPointChangeDescription
		dx	= AccessPointType
		bx	= feature mask

RETURN:		carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If no triggers or multiple selections, do nothing.
		Get current selection.  If same as access point that
		changed, enable/disable edit, delete triggers &
		enableDisable object depending if access point is
		now in use or not.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/18/97			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockAccessPointHandler	proc	near
		uses	ax, bx, cx, dx, di, si, bp
		.enter
if _EDIT_ENABLE
	;
	; Do nothing if there are no triggers.
	;
		test	bx, mask APCF_EDIT or mask APCF_LIST
		jz	exit
	;
	; If more than one selection, do nothing.  Multiselection
	; allows delete even if one of the selected accpnts is locked.
	;
		call	ObjBlockGetOutput		; ^lbx:si
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_NUM_SELECTIONS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax = # selections
		cmp	ax, 1
		jne	exit
	;
	; If changed access point is current selection, update UI.
	;
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_SELECTION 
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		jc	exit				; ax = selected ID

		mov	cx, es:[APCD_id]
		cmp	cx, ax
		jne	exit
	;
	; Update UI.
	;
		mov	si, offset AccessPointIDMap	; *ds:si = id array
		call	ChunkArrayGetCount		; cx = # accpnts
		call	UpdateTriggersForSelection
exit:
endif	; _EDIT_ENABLE
		.leave
		ret
LockAccessPointHandler	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlSetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the APCI_type field

CALLED BY:	MSG_ACCESS_POINT_CONTROL_SET_TYPE
PASS:		ds:di	= AccessPointControlClass instance data
		cx	= AccessPointType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlSetType	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_SET_TYPE
		.enter
		Assert	etype, cx, AccessPointType
		mov	ds:[di].APCI_type, cx
		.leave
		ret
AccessPointControlSetType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlGetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the APCI_type field

CALLED BY:	MSG_ACCESS_POINT_CONTROL_GET_TYPE
PASS:		ds:di	= AccessPointControlClass instance data
RETURN:		ax	= AccessPointType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlGetType	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_GET_TYPE
		.enter
		mov	ax, ds:[di].APCI_type
		.leave
		ret
AccessPointControlGetType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlSetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a particular access point

CALLED BY:	MSG_ACCESS_POINT_CONTROL_SET_SELECTION
PASS:		*ds:si	= AccessPointControlClass object
		cx	= access ID
RETURN:		carry set if not in list
DESTROYED:	bx,si,di,es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If the list is not built, we assume the ID is valid and store
	it as the selection.  If it turns out to be invalid later,
	AccessPointInitializeList will discard it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlSetSelection	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_SET_SELECTION
		uses	ax, cx, dx, bp
		.enter
	;
	; save point to ourself
	;
		push	si
		push	ds:[LMBH_handle]
	;
	; lock down the array
	;
		call	GetChildSegment		; ax=seg (z set if none),
						; bx=features
		jz	noChild
		mov	ds, ax
		Assert	record, bx, AccessPointControlFeatures
		test	bx, mask APCF_LIST	; carry clear
		jz	cleanup
	;
	; set the selection in the list
	;
		push	cx
		call	SetSelectionLow
		pop	cx
		jc	cleanup
	;
	; release child segment
	;
cleanup:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
	;
	; restore *ds:si = this object
	;
noChild:
		pop	bx
		call	MemDerefDS
		pop	si
	;
	; locate and update vardata
	;
		mov	ax, ATTR_ACCESS_POINT_CONTROL_SELECTION or mask VDF_SAVE_TO_STATE
		push	cx
		mov	cx, size word
		call	ObjVarAddData		; ds:bx = data
		pop	ds:[bx]
		
		.leave
		ret

AccessPointControlSetSelection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSelectionLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current selection of the controller

CALLED BY:	AccessPointControlSetSelection, AccessPointInitializeList
PASS:		ds	- child segment
		cx	- selection to set
RETURN:		carry set if not in list
		cx	- first item in list, or 0 if list empty
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSelectionLow	proc	near
		uses	ax,bx,dx,bp,si,di,es
		.enter
	;
	; search for the requested ID
	;
		segmov	es, ds, ax
		mov	ax, cx			; ax = ID to locate
		mov	di, offset AccessPointIDMap
		mov	di, es:[di]
		mov	cx, es:[di].CAH_count	; cx = length of list
		jcxz	empty
		mov	dx, cx
		add	di, es:[di].CAH_offset	; es:di = data to search
		mov	bx, es:[di]		; bx = first element
		repne	scasw
		stc
		jne	missing
	;
	; compute its index based on number of iterations
	;
		sub	cx, dx			; cx = negated 1 based index
		not	cx			; cx = 0 based index
	;
	; set the new selection
	;
		clr	dx			; selection is determinate
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	si, offset AccessList
		call	ObjCallInstanceNoLock
		clc
done:
		mov	cx,bx
		.leave
		ret
	;
	; list was empty
	;
empty:
		clr	bx
	;
	; selection not found
	;
missing:
		stc
		jmp	done
		
SetSelectionLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlGetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the ID of the current selection

CALLED BY:	MSG_ACCESS_POINT_CONTROL_GET_SELECTION
PASS:		ds:di	= AccessPointControlClass instance data
RETURN:		ax	= selection ID (0 if none)
		carry set if no selection
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlGetSelection	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_GET_SELECTION
		uses	bx, cx, dx
		.enter
	;
	; fetch the selection from vardata
	;
	; we do this first because it could be used by either of two
	; branches below, at least in EC code
	;
		clr	dx
		mov	ax, ATTR_ACCESS_POINT_CONTROL_SELECTION
		call	ObjVarFindData		; ds:bx = selection
		jnc	skipVardata
		mov	dx, ds:[bx]
skipVardata:
	;
	; try to get the selection from the list
	;
		call	GetSelectionFromList		; cx = selection
		jcxz	useVardata
	;
	; if we got a real selection from the list, and the list
	; is not modified, it should agree with vardata
	;
		mov	ax, cx
EC <		jc	done			; jmp if list modified 	>
EC <		cmp	cx, dx						>
EC <		ERROR_NE  INCONSISTENT_SELECTION			>
		jmp	done			; jump with carry clear
	;
	; use the vardata value, and set carry if it is null
	;
useVardata:
		tst	dx
		lahf				; bit 6 = z flag
		rcl	ah			; big 7 = z flag
		rcl	ah			; carry = z flag
		mov	ax, dx
done:
		.leave
		ret
AccessPointControlGetSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectionFromVardata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current selection out of controller vardata

CALLED BY:	AccessPointInitializeList, AccessPointSelectorCreate,
		AccessPointSelectorEdit, AccessPointSelectorDelete
PASS:		ds	- segment of child block
RETURN:		cx	- selection, or 0 if none
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectionFromVardata	proc	near
		uses	bx,si,ds
		.enter
	;
	; locate vardata
	;
		clr	cx
		call	ObjBlockGetOutput	; ^lbx:si = control
		call	MemDerefDS
		mov	ax, ATTR_ACCESS_POINT_CONTROL_SELECTION
		call	ObjVarFindData		; ds:bx = data
		jnc	noData
	;
	; read selection
	;
		mov	cx, ds:[bx]
noData:
		.leave
		ret
GetSelectionFromVardata	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                GetSelectionFromList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Get the current selection from the dynamic list

CALLED BY:      AccessPointControlGetSelection
PASS:           nothing
RETURN:		if no list, no access points, or no selection in list:
			cx = 0
			carry undefined
		otherwise
			cx = selected ID
			carry set if list is modified
DESTROYED:      nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	In this case, "indeterminate" means that the list is modified,
	so the vardata will not match the list selection.

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        EW      5/18/95         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectionFromList proc    far
                uses    ax,dx,bp,si,di
		.enter
	;
	; get the child block
	;
		clr	cx
		call	GetChildSegment		; ax = segment, bx = features
		jz	abort			; UI not built
		test	bx, mask APCF_LIST
		jz	done
		mov	ds, ax
        ;
        ; if no access points, the selection is a dummy
        ;
                mov     si, offset AccessPointIDMap
                call    ChunkArrayGetCount      ; cx = count
		jcxz    done
        ;
        ; get the selection index
        ;
                mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
                mov     si, offset AccessList
		call    ObjCallInstanceNoLock
		mov	cx, 0
		jc	done
        ;
        ; look up index in map table
        ;
lookup::
                mov     si, offset AccessPointIDMap
                call    ChunkArrayElementToPtr
		ERROR_C CORRUPT_ACCESS_ID_MAP
                mov     cx, ds:[di]
	;
	; check whether the list was modified
	;
		push	cx
		mov	ax, MSG_GEN_ITEM_GROUP_IS_MODIFIED
		mov	si, offset AccessList
		call	ObjCallInstanceNoLock
		pop	cx
	;
	; release child block, preserving flags
	;
done:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
abort:
                .leave
		ret
GetSelectionFromList endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSelectionInVardata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current selection in vardata 

CALLED BY:	AccessPointInitializeList
PASS:		cx	- value to set
		ds	- segment of child block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSelectionInVardata	proc	near
		uses	ax,bx,si,ds
		.enter
	;
	; locate vardata 
	;
		push	cx
		call	ObjBlockGetOutput	; ^lbx:si = control
		call	MemDerefDS
		mov	ax, ATTR_ACCESS_POINT_CONTROL_SELECTION or mask VDF_SAVE_TO_STATE
		mov	cx, size word
		call	ObjVarAddData		; ds:bx = data
	;
	; set selection
	;
		pop	cx
		mov	ds:[bx], cx
		.leave
		ret
SetSelectionInVardata	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlGetNumSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current number of selections in the access
		point list.  Returns zero if there is no selection.

CALLED BY:	MSG_ACCESS_POINT_CONTROL_GET_NUM_SELECTIONS
PASS:		*ds:si	= AccessPointControlClass object
RETURN:		ax	= number of selections
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	12/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlGetNumSelections	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_GET_NUM_SELECTIONS
	;
	; Get the child block.
	;
		clr	cx
		call	GetChildSegment		; ax = segment, bx = features
		jz	abort			; UI not built
		test	bx, mask APCF_LIST
		jz	done
		mov	ds, ax
	;
	; If no access points, the selection is a dummy.
	;
		mov	si, offset AccessPointIDMap
		call	ChunkArrayGetCount	; cx = count
		jcxz	done
	;
	; Get the number of selections.
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS
		mov	si, offset AccessList
		call	ObjCallInstanceNoLock	; ax = number of selections
done:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
abort:
		ret
AccessPointControlGetNumSelections	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlGetMultipleSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns multiple selections in the access point list. 

CALLED BY:	MSG_ACCESS_POINT_CONTROL_GET_MULTIPLE_SELECTIONS
PASS:		*ds:si	= AccessPointControlClass object
		cx:dx	= buffer to hold the accpnt IDs of selections
		bp	= max selections

RETURN:		cx:dx	= preserved, filled in with the accpnt IDs of
			  the selections
		ax	= number of selections

DESTROYED:	bp


PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	12/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlGetMultipleSelections	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_GET_MULTIPLE_SELECTIONS

maxIds		local	word	push bp
idBuffer	local	fptr	push cx, dx
		.enter
	;
	; Get the child block.
	;
		clr	cx
		call	GetChildSegment		; ax = segment, bx = features
		jz	abort			; UI not built
		test	bx, mask APCF_LIST
		jz	done
		mov	ds, ax
	;
	; If no access points, the selection is a dummy.
	;
		mov	si, offset AccessPointIDMap
		call	ChunkArrayGetCount	; cx = count
		jcxz	done
	;
	; Get the selections.
	;
		push	bp
		movdw	cxdx, idBuffer
		mov	bp, maxIds
		mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
		mov	si, offset AccessList
		call	ObjCallInstanceNoLock	; ax = num selections
		pop	bp

		cmp	ax, maxIds
		ja	done
	;
	; Convert selection identifiers to access point Ids.
	;
		call	AccessPointMapSelectionsToIDs
done:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
abort:
		.leave
		ret
AccessPointControlGetMultipleSelections	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointMapSelectionsToIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a buffer of selection identifiers to access point IDs.

CALLED BY:	AccessPointControlGetMultipleSelections

PASS:		cx:dx	= buffer of selections
		ax	= number of selections
		ds	= segment of child locked block

RETURN:		nothing

DESTROYED:	bx, si, di, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/19/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointMapSelectionsToIDs	proc	near
		uses	ax, cx, dx, ds
		.enter

		mov	es, cx
		mov	bx, dx				; es:bx = buffer
		mov_tr	cx, ax				; cx = num selections

		mov	si, offset AccessPointIDMap	; *ds:si = id map
mapLoop:
	;
	; Convert selection to accpnt ID and store in buffer,
	; overwriting selection.
	;
		push	cx
		mov	ax, es:[bx]			; ax = selection 
		call	ChunkArrayElementToPtr
		mov	ax, ds:[di]			; ax = accpnt ID
		mov	es:[bx], ax
		pop	cx

		inc	bx
		inc	bx
		loop	mapLoop

		.leave
		ret
AccessPointMapSelectionsToIDs	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlUpdateSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set vardata selection when user changes dlist selection

CALLED BY:	MSG_ACCESS_POINT_CONTROL_UPDATE_SELECTION
PASS:		*ds:si	= AccessPointControlClass object
		cx	= selection index
		bp	= number of selections

RETURN:		cx	= selection ID if only 1 selected
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlUpdateSelection	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_UPDATE_SELECTION
		.enter
        ;
        ; lock the child block and make sure we really do have a list
        ;
                call    GetChildSegment ;ax=seg, bx=features, z if no seg
EC <		ERROR_Z UPDATE_FROM_NONEXISTENT_LIST			>
                mov     ds, ax
		Assert  record, bx, AccessPointControlFeatures
EC <		test	bx, mask APCF_LIST				>
EC <		ERROR_Z UPDATE_FROM_NONEXISTENT_LIST			>
        ;
        ; if no access points, the selection is a dummy
	;
		mov	ax, cx			; save index
                mov     si, offset AccessPointIDMap
		call    ChunkArrayGetCount      ; cx = count
                jcxz	cleanup
	;
	; Process differently depending on number of items selected.
	;
		cmp	bp, 1
		jb	noSelection
		ja	manySelections
		call	AccessPointControlUpdateSingleSelection
		jmp	cleanup
noSelection:
		call	AccessPointControlUpdateNoSelection
		jmp	cleanup
manySelections:
		call	AccessPointControlUpdateManySelections
	;
	; release child block
	;
cleanup:
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
		.leave
		ret
AccessPointControlUpdateSelection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlUpdateSingleSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle new single item selected.  

CALLED BY:	AccessPointControlUpdateSelection

PASS:		ax	= selection index
		ds	= segment of locked child block 

RETURN:		cx	= selection ID 

DESTROYED:	ax, bx, dx, di, si, bp

PSEUDO CODE/STRATEGY:
		map selection index to accpnt ID
		store ID in vardata

		update triggers if needed
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/19/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlUpdateSingleSelection	proc	near

	;
	; Look up ID in map table
	;
		mov	si, offset AccessPointIDMap
		call	ChunkArrayElementToPtr
EC <            ERROR_C CORRUPT_ACCESS_ID_MAP                   >
		mov     cx, ds:[di]		; cx = selection ID
	;
	; Store ID in vardata.
	;
		call	SetSelectionInVardata
if _EDIT_ENABLE
	;
	; Update triggers. 
	;
		push	cx
		call	ObjBlockGetOutput
		mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx				; cx = selection ID

		Assert	record, ax, AccessPointControlFeatures
		test	ax, mask APCF_EDIT
		jz	done

		push	cx
		mov	ax, cx				; ax = accpnt ID
		mov	si, offset AccessPointIDMap
		call	ChunkArrayGetCount		; cx = # accpnts
		call	UpdateTriggersForSelection
		pop	cx				; cx = selection ID
done::
endif
		ret
AccessPointControlUpdateSingleSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlUpdateNoSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process access point list having all items unselected.

CALLED BY:	AccessPointControlUpdateSelection

PASS:		ds	= segment of locked child block

RETURN:		cx	= selection ID

DESTROYED:	ax, bx, dx, di, si, bp

PSEUDO CODE/STRATEGY:
		Get selection ID from vardata
		Attempt to set the list with it
		if failed, just select the first item so we don't
		let the list have nothing selected

SIDE EFFECTS:
		Triggers get enabled/disabled according to selection.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/19/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlUpdateNoSelection	proc	near

	;
	; Use the focus item and make that the current selection.
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_FOCUS_ITEM
		mov	si, offset AccessList
		call	ObjCallInstanceNoLock		; cx = selection
		cmp	cx, GIGS_NONE
		jne	setIt

		CheckHack <GIGS_NONE eq -1>
		inc	cx				; use first one
setIt:
		mov_tr	ax, cx
		push	ax, si
		mov	si, offset AccessPointIDMap
		call	ChunkArrayElementToPtr
		mov	cx, ds:[di]			; cx = accpnt ID
		call	SetSelectionInVardata
		mov_tr	ax, cx				; ax = ID
		pop	cx, si				; cx = selection

		push	ax				; save selection ID
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
		pop	cx				; recover selection ID

		ret
AccessPointControlUpdateNoSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlUpdateManySelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle more than one item being selected.

CALLED BY:	AccessPointControlUpdateSelection

PASS:		ds	= segment of locked child block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	12/19/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlUpdateManySelections	proc	near

if _EDIT_ENABLE
	;
	; Disable edit trigger.
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	si, offset AccessEditTrigger
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
	;
	; Enable delete trigger.
	;
		mov	ax, MSG_GEN_SET_ENABLED
		mov	si, offset AccessDeleteTrigger
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
endif
	;
	; Get enableDisable object and disable it if it exists.
	;
		mov	ax, MSG_ACCESS_POINT_CONTROL_GET_ENABLE_DISABLE
		call	ObjBlockGetOutput	; ^lbx:si = output
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		movdw	bxsi, cxdx		; ^lbx:si = object to enable

		tst	bx
		jz	done

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		call	ObjMessage		
done:
		ret
AccessPointControlUpdateManySelections	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlGenApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply the dynamic list

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= AccessPointControlClass object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlGenApply	method dynamic AccessPointControlClass, 
					MSG_GEN_APPLY
		.enter
	;
	; check if we have a list
	;
		mov     ax, TEMP_GEN_CONTROL_INSTANCE
		call    ObjVarDerefData
		mov	cx, ds:[bx].TGCI_childBlock
		jcxz	done
		test	ds:[bx].TGCI_features, mask APCF_LIST
		jz	done
	;
	; if so, apply it
	;
		mov	ax, MSG_GEN_APPLY
		mov	bx, dx
		mov	si, offset AccessList
		mov	di, mask MF_CALL
		call	ObjMessage
done:
		.leave
		ret
AccessPointControlGenApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the segment containing the controller UI

CALLED BY:	INTERNAL
PASS:		*ds:si	- controller object
RETURN:		ax	- child segment (0 if none)
		bx	- feature flags
		z flag	- set if no child segment
		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildSegment	proc	far
		uses	dx,ds
		.enter
		
		mov     ax, TEMP_GEN_CONTROL_INSTANCE
		call    ObjVarDerefData
		mov	dx, ds:[bx].TGCI_features
                mov     bx, ds:[bx].TGCI_childBlock	; bx <- child block
		tst	bx
		jz	done
		call	ObjLockObjBlock
		tst	ax				; clear zero flag
done:
		mov	bx, dx
		.leave
		ret
GetChildSegment	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlGetEditMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the value of APCI_editMsg

CALLED BY:	MSG_ACCESS_POINT_CONTROL_GET_EDIT_MSG
PASS:		ds:di	= AccessPointControlClass instance data
RETURN:		ax	= APCI_editMsg
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlGetEditMsg	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_GET_EDIT_MSG
		mov	ax, ds:[di].APCI_editMsg
		ret
AccessPointControlGetEditMsg	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlSetEditMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the value of APCI_editMsg

CALLED BY:	MSG_ACCESS_POINT_CONTROL_SET_EDIT_MSG
PASS:		ds:di	= AccessPointControlClass instance data
		cx	= APCI_editMsg
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlSetEditMsg	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_SET_EDIT_MSG
		mov	ds:[di].APCI_editMsg, cx
		ret
AccessPointControlSetEditMsg	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlSendEditMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the edit message to the controller's output

CALLED BY:	MSG_ACCESS_POINT_CONTROL_SEND_EDIT_MSG
PASS:		*ds:si	= AccessPointControlClass object
		ds:di	= AccessPointControlClass instance data
		cx	= access point to edit
RETURN:		nothing
DESTROYED:	bx,si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlSendEditMsg	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_SEND_EDIT_MSG
		uses	ax, cx, dx, bp
		.enter
	;
	; record an event
	;
		push	si
		mov	ax, ds:[di].APCI_editMsg
		clrdw	bxsi				; no class
		mov	di, mask MF_RECORD
		call	ObjMessage			; di = classed event
		pop	si
	;
	; dispatch it
	;
		mov	bp, di				; bp = event
		mov	ax, MSG_GEN_CONTROL_OUTPUT_ACTION
		call	ObjCallInstanceNoLock
		
		.leave
		ret
AccessPointControlSendEditMsg	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlSetEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the object to be enabled

CALLED BY:	MSG_ACCESS_POINT_CONTROL_SET_ENABLE_DISABLE
PASS:		ds:di	= AccessPointControlClass instance data
		^lcx:dx = object to enable
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlSetEnableDisable	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_SET_ENABLE_DISABLE
		movdw	ds:[di].APCI_enableDisable, cxdx
		ret
AccessPointControlSetEnableDisable	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlGetEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the object to be enabled

CALLED BY:	MSG_ACCESS_POINT_CONTROL_GET_ENABLE_DISABLE
PASS:		ds:di	= AccessPointControlClass instance data
RETURN:		^lcx:dx	= object to be enabled
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlGetEnableDisable	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_GET_ENABLE_DISABLE
		movdw	cxdx, ds:[di].APCI_enableDisable
		ret
AccessPointControlGetEnableDisable	endm

if _EDIT_ENABLE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointControlChangingLevels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has switched trigger sets

CALLED BY:	MSG_ACCESS_POINT_CONTROL_EXCHANGE_ICONS
PASS:		*ds:si	= AccessPointControlClass object
		ds:di	= AccessPointControlClass instance data
		ds:bx	= AccessPointControlClass object (same as *ds:si)
		es 	= segment of AccessPointControlClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Toggle existence of ATTR_ACCESS_POINT_CONTROL_SECOND_LEVEL_ACTIVE
	Exchange CMI_iconBitmap and APCI_altBitmap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointControlChangingLevels	method dynamic AccessPointControlClass, 
					MSG_ACCESS_POINT_CONTROL_CHANGING_LEVELS
		uses	ax, cx, dx, bp
		.enter
	;
	; save APCI_altBitmap while we've got a pointer handy
	;
		push	ds:[di].APCI_altBitmap
	;
	; toggle ATTR_ACCESS_POINT_CONTROL_SECOND_LEVEL_ACTIVE
	;
		mov	ax, ATTR_ACCESS_POINT_CONTROL_SECOND_LEVEL_ACTIVE or mask VDF_SAVE_TO_STATE
		call	ObjVarFindData
		jc	remove
		clr	cx
		call	ObjVarAddData
		jmp	checkMoniker
remove:
		call	ObjVarDeleteDataAt
	;
	; do nothing unless we have an alternate bitmap
	;
checkMoniker:
		pop	ax				; APCI_altBitmap
		tst	ax
		jz	done
	;
	; also do nothing if this is not a complex moniker
	;
		segmov	es, <segment ComplexMonikerClass>, ax
		mov	di, offset ComplexMonikerClass
		call	ObjIsObjectInClass
EC <		WARNING_NC IGNORING_EXCHANGE_ICONS_REQUEST		>
		jnc	done
	;
	; get the current moniker data
	;
		sub	sp, size GetComplexMoniker
		mov	dx,ss
		mov	bp,sp
		mov	ax, MSG_COMPLEX_MONIKER_GET_MONIKER
		call	ObjCallInstanceNoLock
	;
	; exchange the current lptr with the one in our instance data
	;
		mov	ax, ss:[bp].GCM_iconBitmap
		add	sp, size GetComplexMoniker
		mov	di, ds:[si]
		add	di, ds:[di].AccessPointControl_offset
		xchg	ax, ds:[di].APCI_altBitmap
	;
	; update the complex moniker icon
	;
		sub	sp, size ReplaceComplexMoniker
		mov	bp, sp
		clr	ss:[bp].RCM_textStyleSet
		clr	ss:[bp].RCM_textStyleClear
		clr	ss:[bp].RCM_fontSize
		clrdw	ss:[bp].RCM_topTextSource
		mov	ss:[bp].RCM_topTextSourceType, CMST_KEEP
		clr	ss:[bp].RCM_iconBitmapSource.high
		mov	ss:[bp].RCM_iconBitmapSource.low, ax
		mov	ss:[bp].RCM_iconBitmapSourceType, CMST_LPTR
		test	ax,1
		jz	done
		mov	ss:[bp].RCM_iconBitmapSourceType, CMST_CMB

		mov	ax, MSG_COMPLEX_MONIKER_REPLACE_MONIKER
		call	ObjCallInstanceNoLock
		add	sp, size ReplaceComplexMoniker
done:
		.leave
		ret
AccessPointControlChangingLevels	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessTwoLevelTriggerInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize AccessDefineTrigger

CALLED BY:	MSG_ACCESS_TWO_LEVEL_TRIGGER_INITIALIZE
PASS:		*ds:si	= AccessTwoLevelTriggerClass object
		^lcx:dx	= new parent object
		bp	= desired slot
RETURN:		nothing
DESTROYED:	bx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessTwoLevelTriggerInitialize	method dynamic AccessTwoLevelTriggerClass, 
					MSG_ACCESS_TWO_LEVEL_TRIGGER_INITIALIZE
		uses	ax, cx, dx, bp
		.enter
EC <		cmp	si, offset AccessDefineTrigger			>
EC <		ERROR_NE INITIALIZING_WRONG_TRIGGER			>
	;
	; set this object's instance data
	;
		CheckHack <AccessTwoLevelTrigger_offset	eq TwoLevelTrigger_offset>
		mov	bx, ds:[LMBH_handle]
		mov	ds:[di].TLTI_other_parent.handle, bx
		mov	ds:[di].TLTI_other_parent.offset, offset AccessTrigGroup
	;
	; initialize the slot hint
	;
		mov	ax, HINT_SEEK_SLOT
		push	cx
		mov	cx, size word
		call	ObjVarAddData		; dx:bx = data
		pop	cx
		mov	ds:[bx], bp
	;
	; add ourselves to the parent
	;
		mov	bx, ds:[LMBH_handle]
		xchg	bx, cx
		xchg	dx, si			; ^lbx:si = new parent,
						; ^lcx:dx = this object
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, CompChildFlags <1,CCO_LAST>
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; set our partner's instance data
	;
		mov	di, offset AccessBackTrigger
		mov	di, ds:[di]
		add	di, ds:[di].TwoLevelTrigger_offset
		movdw	ds:[di].TLTI_other_parent, bxsi
		
		.leave
		ret
AccessTwoLevelTriggerInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessTwoLevelTriggerActivateOtherLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch from view mode to edit mode or back again

CALLED BY:	MSG_TLT_ACTIVATE_OTHER_LEVEL
PASS:		*ds:si	= AccessTwoLevelTriggerClass object
		es	= segment of AccessTwoLevelTriggerClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	7/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessTwoLevelTriggerActivateOtherLevel	method dynamic AccessTwoLevelTriggerClass, 
					MSG_TLT_ACTIVATE_OTHER_LEVEL
		.enter
	;
	; tell the controller to change its icon
	;
		push	ax,si
		call	ObjBlockGetOutput
		mov	ax, MSG_ACCESS_POINT_CONTROL_CHANGING_LEVELS
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	ax,si
	;
	; let the superclass swap the triggers
	;
		mov	di, offset AccessTwoLevelTriggerClass
		.leave
		GOTO	ObjCallSuperNoLock
AccessTwoLevelTriggerActivateOtherLevel	endm

endif

ControlCode	ends

