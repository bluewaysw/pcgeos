COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex Library/Map
FILE:		mapCtrl.asm

ROUTINES:
	Name				Description
	----				-----------
 GLB	ImpexMapControlGetInfo		Gets controller info 
 GLB	ImpexMapControlMapEntry		Handles "Map" button of controller
 GLB	ImpexMapControlUnMapEntry	Handles "UnMap" button of controller
 GLB	ImpexMapControlMapDone		Handles "Done" button of controller
 GLB	ImpexMapControlMapCancel	Handles "Cancel" button of controller
 GLB	ImpexMapControlGetMapData	Sends map data block to trans. library 
 GLB	ImpexMapControlUpdateUI		Create the UI for the map controller
 INT	UpdateAppUI			Update control UI using app data block
 INT	UpdateLibraryUI			Update control UI using lib. data block
 INT	InitializeSourceList		Initialize source dynamic list
 INT	InitializeDestList		Initialize destination dynamic list
 INT	CreateMapListBlock		Create map list block
 INT	AddMapListEntry			Add a new entry to map list block
 INT	DeleteMapListEntry		Delete an entry from the map list block
 GLB	ImpexMapRequestSourceMoniker	Get moniker for destination list
 GLB	ImpexMapRequestDestMoniker	Get moniker for source list
 GLB	ImpexMapRequestMapMoniker	Get moniker for map list
 INT	GetImpexMapDynamicListMoniker   Grab the moniker string from data block
 INT	ConvertWordToAscii		Convert hex number to ascii string

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	5/92		Initial version

DESCRIPTION:
	This file contains routines to implement ImpexMapControlClass

	$Id: mapCtrl.asm,v 1.1 97/04/05 00:25:17 newdeal Exp $

-------------------------------------------------------------------------------@

MapControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	ImpexMapControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ImpexMapControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of ImpexMapControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

------------------------------------------------------------------------------@
ImpexMapControlGetInfo	method dynamic	ImpexMapControlClass,
					MSG_GEN_CONTROL_GET_INFO

	; Copy the data, and ensure the proper help context is included
	;
	test	ds:[di].IMCI_flags, mask IMF_EXPORT
	mov	si, offset IMC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	jz	done				; if not export, we're OK
	mov	di, dx
	mov	es:[di].GCBI_helpContext.offset, offset IMC_exportHelpContext
done:
	ret
ImpexMapControlGetInfo	endm

IMC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY or \
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST,	; GCBI_flags
	IMC_IniFileKey,			; GCBI_initFileKey
	IMC_gcnList,			; GCBI_gcnList
	length IMC_gcnList,		; GCBI_gcnCount
	IMC_notifyTypeList,		; GCBI_notificationList
	length IMC_notifyTypeList,	; GCBI_notificationCount
	IMCName,			; GCBI_controllerName

	handle ImpexMapControlUI,	; GCBI_dupBlock
	IMC_childList,			; GCBI_childList
	length IMC_childList,		; GCBI_childCount
	IMC_featuresList,		; GCBI_featuresList
	length IMC_featuresList,	; GCBI_featuresCount
	IMC_DEFAULT_FEATURES,		; GCBI_features

	0, 0, 0, 0, 0, 0,		; no tool box
	IMC_importHelpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ImpexControlInfoXIP	segment	resource
endif
IMC_IniFileKey	char	"impexMapControl", 0

IMC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_APP_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_LIBRARY_CHANGE>

IMC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_MAP_APP_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_MAP_LIBRARY_CHANGE>

IMC_childList	GenControlChildInfo	\
	<offset ImpexMapControlBox, mask IMCF_MAP, mask GCCF_ALWAYS_ADD>

IMC_featuresList	GenControlFeaturesInfo	\
	<offset ImpexMapControlBox, ImpexMapBoxName, 0>

IMC_importHelpContext	char	"dbMapImport", 0
IMC_exportHelpContext	char	"dbMapExport", 0

if FULL_EXECUTE_IN_PLACE
ImpexControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapControlMapEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles "Map" button from Map Control Dialog Box.

CALLED BY:	MSG_IMC_MAP_ENTRY

PASS:		*ds:si - instance data
		ds:di - instance data

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexMapControlMapEntry	method	dynamic	ImpexMapControlClass, MSG_IMC_MAP_ENTRY

	; Get the identifier of item selected from ImpexMapSourceList

	mov	bx, ds:[di].IMCI_childBlock	; bx - handle of obj block

	mov	di, offset ImpexMapSourceList
	call	getSelection

	cmp	ax, GIGS_NONE
	je	exit

	; Get the identifier of item selected from ImpexMapDestList

	push	ax
	mov	di, offset ImpexMapDestList
	call	getSelection
	mov_tr	cx, ax
	pop	ax

	cmp	cx, GIGS_NONE
	je	exit

	mov	si, ds:[si]		; re-deref, in case we need to
	add	si, ds:[si].ImpexMapControl_offset

	; Check to see if this item has already been mapped

	call	AddMapListEntry		; add this entry to chunk array
	jc	error			; exit if already been mapped


	; Add the new item to the MapList

	mov	bx, ds:[si].IMCI_childBlock	; bx - handle of obj block
	mov	cx, GDLP_LAST			; add item at the end of list
	mov	dx, 1				; add one item
	mov	si, offset ImpexMapMapList 	; bx:si - ImpexMapMapList 
	mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage			; draw the dynamic list
	
	; Get the identifier of the item selected from the MapList

	mov     si, offset ImpexMapMapList	; bx:si - OD ImpexMapMapList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; ax - identifier selected item 

	; Give the new selection to this new entry

	mov	cx, ax
	inc	cx				; cx - identifier
	mov	si, offset ImpexMapMapList 	; bx:si - ImpexMapMapList 
	clr	dx				; dx - not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION	
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage			; make the new selection
	jmp	exit

	; source or dest field has already been mapped, put up a dialog box 
error:
	call	ImpexShowError	 		; does not block UI
exit:
	ret

getSelection:
	; Fetch the selection from the item group ^lbx:di
	; destroys cx,dx,bp
	;
	push	si
	mov	si, di				
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage		; ax - identifier of selected item  
	pop	si
	retn

ImpexMapControlMapEntry	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapControlUnMapEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle the "UnMap" button press

PASS:		*ds:si - instance data
		ds:di - instance data

RETURN:		nothing

DESTROYED:	ax, bx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexMapControlUnMapEntry	method	dynamic	ImpexMapControlClass,
						MSG_IMC_UNMAP
	; Get the identifier of current map list entry selected 

	mov	bx, ds:[di].IMCI_childBlock	; bx - handle of obj block
	push	di
	mov     si, offset ImpexMapMapList	; bx:si - OD ImpexMapMapList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; ax - identifier selected item 
	pop	di

	cmp	ax, GIGS_NONE			; nothing selected?
	je	exit				; then exit

	; Delete this entry from ImpexMapMapList

	push	di
	mov	cx, ax				; cx - item to delete  
	mov	dx, 1				; remove just one item
	mov     si, offset ImpexMapMapList	; bx:si - OD ImpexMapMapList
	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS	
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage			; delete this entry
	pop	di				; ds:di - instance data

	call	DeleteMapListEntry		; delete entry from map block

	; Was the 1st entry removed from the list?

	mov	bx, ds:[di].IMCI_childBlock	; bx - handle of obj block
	tst	cx
	jne	notEmpty			; if not, skip

	; if so, check to see how many entries are left

	mov     si, offset ImpexMapMapList	; *ds:si - OD ImpexMapMapList
	mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS	
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; get number of entries

	tst	cx				; empty list?
	je	exit				; if so, exit
	clr	cx				; if not, give selection to 1st
	jmp	common
notEmpty:
	dec	cx				; cx - identifier
common:
	clr	dx				; dx - not indeterminate
	mov	si, offset ImpexMapMapList 	; bx:si - ImpexMapMapList 
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION	
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; make the new selection
exit:
	ret
ImpexMapControlUnMapEntry	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapControlMapDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles "Done" button from Map Control Dialog Box.
		Decrements the reference count of notification data blocks.

CALLED BY:	MSG_IMC_MAP_DONE	

PASS:	 	*ds:si - instance data
		ds:di - instance data

RETURN:		nothing

DESTROYED:	bx, si, ds

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexMapControlMapDone		method	dynamic	ImpexMapControlClass,
						MSG_IMC_MAP_DONE
	; lock the data block with map list entries

	mov	bx, ds:[di].IMCI_mapListBlock	; bx - handle of map list block

	; if there is no map block, put up a warning message

	tst	bx
	je	warning

	call	MemLock				; lock this block
	mov	ds, ax
	clr	si				; ds:si - header 
	mov	si, ds:[si].MLBH_chunk1		; si - chunk handle

	; get number of entries in the chunk array

	call	ChunkArrayGetCount	
	tst	cx		
	jne	noWarning			; skip if not empty

	call	MemUnlock			; unlock the map block

	; if chunk array is empty, put up a warning message
warning:
	mov	bp, IE_MAP_NO_MAP_ENTRY_ERROR	; error enum
	call	ImpexShowError	 		; does not block UI
	jmp	exit
noWarning:
	call	MemUnlock
exit:
	ret
ImpexMapControlMapDone		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexShowError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display an error dialog box w/o blocking the UI thread	

CALLED BY:	(INTERNAL) ImpexMapControlMapEntry, ImpexMapControlMapDone  

PASS:		bp - ImpexError

RETURN:		nothing

DESTROYED:	ax, bx, si, di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	2/12/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexShowError	proc 	near
		uses	cx, dx, bp
		.enter

		; Lock the string down, display the error, and unlock
		; the string.
		
		call	LockImpexError

		clr	bx, si			; no OD to send back a message
		call	ShowDialog
		mov	bx, handle Strings
		call	MemUnlock

		.leave
		ret
ImpexShowError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapControlMapCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles "Cancel" button from Map Control Dialog Box.
		Decrements the reference count of notification data blocks.

CALLED BY:	MSG_IMC_MAP_CANCEL	

PASS:	 	*ds:si - instance data
		ds:di - instance data

RETURN:		nothing

DESTROYED:	bx

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexMapControlMapCancel	method	dynamic	ImpexMapControlClass,
						MSG_IMC_MAP_CANCEL
	mov	bx, ds:[di].IMCI_mapListBlock	; bx - handle of map list block
	tst	bx				; already deleted?
	je	exit				; if so, exit
	call	MemFree				; delete this block
	clr	ds:[di].IMCI_mapListBlock	; clear handle of map list block

	; now clear the map list

	clr	cx				; no entries in the list yet
	mov	bx, ds:[di].IMCI_childBlock	; bx - handle of obj block
	mov	si, offset ImpexMapMapList 	; *ds:si - ImpexMapMapList 
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; draw the dynamic list
exit:
	ret
ImpexMapControlMapCancel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapControlGetMapData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the handle of map list block to translation library.

CALLED BY:	MSG_IMC_MAP_GET_MAP_DATA (from translation library)

PASS:	 	*ds:si - instance data
		ds:di - instance data

RETURN:		dx - handle of map list block

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexMapControlGetMapData	method	dynamic	ImpexMapControlClass,
						MSG_IMC_MAP_GET_MAP_DATA
	mov	dx, ds:[di].IMCI_mapListBlock   ; dx - handle of map list blk
	clr	ds:[di].IMCI_mapListBlock	; clear handle of map list block
	ret
ImpexMapControlGetMapData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapResetLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the map list (ui) and sets the selection to
		the top of source & dest lists.

CALLED BY:	ImpexMapControlInitInteraction()
PASS:		ds:si - instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexMapResetLists	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	class	ImpexMapControlClass

	clr	cx				; clear the list
	mov	bx, ds:[si].IMCI_childBlock	; bx - handle of obj block
	tst	bx
	jz	done
	mov	si, offset ImpexMapMapList 	; *ds:si - ImpexMapMapList 
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; draw the dynamic list

	mov	si, offset ImpexMapSourceList
	clr	cx, dx				; first item in list
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; set the selection

	mov	si, offset ImpexMapDestList
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; set the selection
done:
	.leave
	ret
ImpexMapResetLists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapControlInitInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create map list block if none has been created.

CALLED BY:	MSG_GEN_INTERACTION_INITIATE

PASS:	 	*ds:si - instance data
		ds:di - instance data

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexMapControlInitInteraction	method	dynamic ImpexMapControlClass,
						MSG_GEN_INTERACTION_INITIATE
	; check to see whether import or export operation

	push	ax, bx, cx, dx, bp, si
	mov	si, di				; ds:si - instance data

	; create map list block if none has been created

	mov	bx, ds:[si].IMCI_mapListBlock	; bx - handle of map list block
	tst	bx
	jne	done
	call	CreateMapListBlock		; create map list block
	call	ImpexMapResetLists		; reset ui lists
	mov     ds:[si].IMCI_mapListBlock, bx   ; save the handle
done:
	; let superclass finish up
	
	pop	ax, bx, cx, dx, bp, si
	mov	di, offset ImpexMapControlClass
	call	ObjCallSuperNoLock
	ret
ImpexMapControlInitInteraction	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	ImpexMapControlSpecBuildBranch -- MSG_SPEC_BUILD_BRANCH
					for ImpexMapControlClass

DESCRIPTION:	Handle building by adding ourselves to
		 GAGCNLT_SELF_LOAD_OPTIONS list.

PASS:		*ds:si - instance data
		ds:di - instance data
		es - segment of ImpexMapControlClass
		ax - The message
		bp - SpecBuildFlags

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

------------------------------------------------------------------------------@
ImpexMapControlSpecBuildBranch	method dynamic ImpexMapControlClass,
				MSG_SPEC_BUILD_BRANCH
	;
	; first add ourselves to GAGCNLT_SELF_LOAD_OPTIONS list
	;
	push	ax, cx, dx, bp
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_SELF_LOAD_OPTIONS
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[bp].GCNLP_optr, axsi
	mov	dx, size GCNListParams
	mov	ax, MSG_META_GCN_LIST_ADD
	call	GenCallApplication
	add	sp, size GCNListParams
	;
	; then let superclass finish up
	;
	pop	ax, cx, dx, bp
	mov	di, offset ImpexMapControlClass
	call	ObjCallSuperNoLock
	ret
ImpexMapControlSpecBuildBranch	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	ImpexMapControlMetaDetach -- MSG_META_DETACH
					for ImpexMapControlClass

DESCRIPTION:	Handle unbuilding by removing ourselves from
		 GAGCNLT_SELF_LOAD_OPTIONS list.

PASS:		*ds:si - instance data
		ds:di - instance data
		es - segment of ImpexMapControlClass
		ax - The message

		cx - caller's ID
		dx:bp - ack OD

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version
	chris	3/11/94		Moved to MSG_META_DETACH, so the map block
				isn't freed before it is needed in unbuild-
				Controllers = true setups.

------------------------------------------------------------------------------@
ImpexMapControlMetaDetach	method dynamic ImpexMapControlClass,
				MSG_META_DETACH

	; free the map list block if there was one

	mov	bx, ds:[di].IMCI_mapListBlock	; bx - handle of map list block
	tst	bx				; already deleted?
	je	skip				; if so, exit
	call	MemFree				; delete this block
	clr	ds:[di].IMCI_mapListBlock	; clear handle of map list block
skip:
	; finally,  let superclass do its thing
	
	mov	di, offset ImpexMapControlClass
	GOTO	ObjCallSuperNoLock

ImpexMapControlMetaDetach	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	ImpexMapControlSpecUnbuildBranch -- MSG_SPEC_UNBUILD_BRANCH
					for ImpexMapControlClass

DESCRIPTION:	Handle unbuilding by removing ourselves from
		 GAGCNLT_SELF_LOAD_OPTIONS list.

PASS:		*ds:si - instance data
		ds:di - instance data
		es - segment of ImpexMapControlClass
		ax - The message
		bp - SpecBuildFlags

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

------------------------------------------------------------------------------@
ImpexMapControlSpecUnbuildBranch	method dynamic ImpexMapControlClass,
					MSG_SPEC_UNBUILD_BRANCH

	mov	di, offset ImpexMapControlClass
	call	ObjCallSuperNoLock
	;
	; Remove ourselves from GAGCNLT_SELF_LOAD_OPTIONS list
	;
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_SELF_LOAD_OPTIONS
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[bp].GCNLP_optr, axsi
	mov	dx, size GCNListParams
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	GenCallApplication
	add	sp, size GCNListParams
	ret
ImpexMapControlSpecUnbuildBranch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the UI for the map controller

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GENERATE_UI)

PASS:		ES	= Segment of ImpexMapControlClass
		*DS:SI	= ImpexMapControlClass object
		DS:DI	= ImpexMapControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/12/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexMapControlGenerateUI	method dynamic	ImpexMapControlClass,
				MSG_GEN_CONTROL_GENERATE_UI
		.enter
	;
	; Keep track of our child block, as good ol' Ted decided to store
	; it in the instance data for this class (instead of using the
	; existing vardata), and it would be too much of a pain to fix all
	; of his code to do otherwise
	;
		mov	di, offset ImpexMapControlClass
		call	ObjCallSuperNoLock
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarFindData
		jnc	done
		mov	bx, ds:[bx].TGCI_childBlock
		mov	di, ds:[si]
		add	di, ds:[di].ImpexMapControl_offset
		mov	ds:[di].IMCI_childBlock, bx
done:
		.leave
		ret
ImpexMapControlGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapControlDestroyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the UI for the map controller

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_DESTROY_UI)

PASS:		ES	= Segment of ImpexMapControlClass
		*DS:SI	= ImpexMapControlClass object
		DS:DI	= ImpexMapControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/12/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexMapControlDestroyUI	method dynamic	ImpexMapControlClass,
				MSG_GEN_CONTROL_DESTROY_UI
	;
	; Clear out the reference to this child block, and then call superclass
	;
		clr	ds:[di].IMCI_childBlock
		mov	di, offset ImpexMapControlClass
		GOTO	ObjCallSuperNoLock
ImpexMapControlDestroyUI	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	ImpexMapControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for ImpexMapControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:		 *ds:si - instance data
		ds:di - instance data
		es - segment of ImpexMapControlClass
		ax - The message
		ss:bp - GenControlUpdateUIParams

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

------------------------------------------------------------------------------@
ImpexMapControlUpdateUI	method dynamic ImpexMapControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

        ; first save the handle of data block and child block

	mov	si, di				; ds:si - instance data

	mov	bx, ss:[bp].GCUUIP_dataBlock	; bx - handle of data block
	call	MemIncRefCount			; increment reference count

	; check to see who sent the notification data block

	cmp	ss:[bp].GCUUIP_changeType, GWNT_MAP_APP_CHANGE
	jne	lib				; if sent by trans lib, skip 

	mov	ds:[si].IMCI_dataBlock1, bx	; save app data block handle
	jmp	common
lib:
	mov	ds:[si].IMCI_dataBlock2, bx	; save lib data block handle
common:
	mov	bx, ds:[si].IMCI_mapListBlock	; bx - handle of map list block
	call	CreateMapListBlock		; create map list block
	mov     ds:[si].IMCI_mapListBlock, bx   ; save the handle

	; check to see who sent the notification data block

	cmp	ss:[bp].GCUUIP_changeType, GWNT_MAP_APP_CHANGE
	jne	libUpdate		; if sent by trans lib, then skip 

	call	UpdateAppUI		; update UI using data blk from app 
	jmp	update			; jump to update map list block
libUpdate:
	call	UpdateLibraryUI 	; update UI using data blk from lib.
update:
	tst	cx			; dest list initialized?
	je	initMap			; if not, skip
	mov	bx, ds:[si].IMCI_mapListBlock	; bx - handle of map list block
	call	MemLock				; lock it
	mov	es, ax
	clr	di				; es:di - LMem header
        mov	es:[di].MLBH_numDestFields, cx  ; save number of output fields
	call	MemUnlock			; unlock it
initMap:
	; now decrement the reference count of data block

	cmp	ss:[bp].GCUUIP_changeType, GWNT_MAP_APP_CHANGE
	jne	lib2				; if sent by trans lib, skip 

	mov	bx, ds:[si].IMCI_dataBlock1	; bx - handle of data block
	jmp	common2
lib2:
	mov	bx, ds:[si].IMCI_dataBlock2	; bx - handle of data block
common2:
	call	MemDecRefCount

	; now initialize the map list

	clr	cx				; no entries in the list yet
	mov	bx, ds:[si].IMCI_childBlock	; bx - handle of obj block
	mov	si, offset ImpexMapMapList 	; *ds:si - ImpexMapMapList 
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; draw the dynamic list
	ret
ImpexMapControlUpdateUI	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateAppUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the dynamic lists using the information
		from the notification data block sent in by the application.

CALLED BY:	(INTERNAL) ImpexMapControlUpdateUI

PASS:		ds:si - ImpexMapControlClass instance data

RETURN:		cx - number of destination list entries 

DESTROYED:	ax, bx, cx, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateAppUI	proc	near

        class   ImpexMapControlClass

	clr	cx
	test	ds:[si].IMCI_flags, mask IMF_IMPORT	; import operation?
	jnz	exit				; if so, skip

	; get number of fields from the application data block

	mov	bx, ds:[si].IMCI_dataBlock1	; bx - handle of data block
	tst	bx
	je	exit				; exit if no app data block
	call	MemLock				; lock the file info block
	mov	es, ax
	clr	di				; es:di - ptr to LMemHeader
	mov	cx, es:[di].IMFIH_numFields	; cx - number of app fields
	call	MemUnlock			; unlock this block

	call	InitializeSourceList		; init. source list
	call	InitializeDestList		; init. destination list
exit:
	ret
UpdateAppUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateLibraryUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the dynamic lists using the information
		from the notification data block sent in by trans library.

CALLED BY:	ImpexMapControlUpdateUI (INTERNAL)

PASS:		ds:si - ImpexMapControlClass instance data

RETURN:		cx - number of destination list entries 

DESTROYED:	ax, bx, cx, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateLibraryUI		proc	near

        class   ImpexMapControlClass

	clr	cx

	test	ds:[si].IMCI_flags, mask IMF_EXPORT	; export operation?
	jnz	done				; if so, exit

	; get number of fields from the library data block

	mov	bx, ds:[si].IMCI_dataBlock2	; bx - handle of data block
	tst	bx
	je	done				; exit if no lib. data block
	call	MemLock				; lock the file info block
	mov	es, ax
	clr	di				; es:di - ptr to LMemHeader
	mov	cx, es:[di].IMFIH_numFields	; cx - number of source fields
	call	MemUnlock			; unlock this block

	call	InitializeSourceList		; init. source list

	mov	bx, ds:[si].IMCI_dataBlock1
	tst	bx
	je	dest

	call	MemLock				; lock the file info block
	mov	es, ax
	clr	di				; es:di - ptr to LMemHeader
	mov	dl, es:[di].IMFIH_flag		; dl - DefaultFieldNameUsage
	mov	ax, es:[di].IMFIH_numFields	; ax - number of source fields
	call	MemUnlock			; unlock this block

	cmp	dl, DFNU_FIXED
	jne	dest

	mov	cx, ax				

	;tst	ds:[si].IMCI_dataBlock1		; bx - handle of data block
	;jne	done
dest:
	call	InitializeDestList		; init. dest list
done:
	ret
UpdateLibraryUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeSourceList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the source dynamic list and set the selection.

CALLED BY:	UpdateAppUI, UpdateLibraryUI (INTERNAL)

PASS:		ds:si - instance data
		cx - number of source list entry

RETURN:		nothing

DESTROYED:	ax, bx, dx

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeSourceList	proc	near	uses	si, cx
	.enter

	class	ImpexMapControlClass

	; now initialize the source dynamic list

	mov	bx, ds:[si].IMCI_childBlock	; bx - handle of obj block
	mov	si, offset ImpexMapSourceList 	; bx:si - ImpexMapSourceList 
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage			; draw the dynamic list

	; Give the selection to the 1st entry of the source list

	clr	cx				; cx - identifier
	clr	dx				; dx - not indeterminate
	mov	si, offset ImpexMapSourceList 	; bx:si - ImpexMapSourceList 
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION	
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage			; make the new selection

	.leave
	ret
InitializeSourceList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeDestList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the destination dynamic list and set the selection.

CALLED BY:	UpdateAppUI, UpdateLibraryUI (INTERNAL)

PASS:		ds:si - instance data
		cx - number of destination list entry

RETURN:		nothing

DESTROYED:	ax, bx, dx

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeDestList	proc	near	uses	si, cx
	.enter

	class	ImpexMapControlClass

	; now initialize the destination dynamic list

	mov	bx, ds:[si].IMCI_childBlock	; bx - handle of obj block
	mov	si, offset ImpexMapDestList 	; bx:si - ImpexMapDestList 
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage			; draw the dynamic list

	; Give the selection to the 1st entry of the destination list

	clr	cx				; cx - identifier
	clr	dx				; dx - not indeterminate
	mov	si, offset ImpexMapDestList 	; bx:si - ImpexMapDestList 
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION	
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage			; make the new selection

	.leave
	ret
InitializeDestList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateMapListBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the data block to be used for storing mapping info 

CALLED BY:	ImpexMapControlUpdateUI

PASS:		ds:si - instance data
		bx - handle of current map list block

RETURN:		bx - handle of map list block

DESTROYED:	ax, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateMapListBlock	proc	near	uses	ds, si
	.enter

	tst	bx				; has it already been created?
	jne	skip				; if so, skip
create:
	mov	ax, LMEM_TYPE_GENERAL		; ax - LMemType
	mov	cx, size MapListBlockHeader	; cx - size of header  
	call	MemAllocLMem			; allocate a data block
	push	bx				; save the handle
	mov	ah, 0
	mov	al, mask HF_SHARABLE
	call	MemModifyFlags			; mark this block shareable
	call	MemLock				; lock this block
	mov	ds, ax
	mov	bx, size ChunkMapList		; bx - element size
	clr	cx				; cx - default ChunkArrayHeader
	clr	si				; allocate a chunk handle
	clr	al				; no ObjChunkFlags passed
	call	ChunkArrayCreate		; create a chunk array
	clr	di
	mov	ds:[di].MLBH_chunk1, si		; save the chunk handle
	pop	bx
	jmp	exit
skip:
	call	MemLock				; lock this block
	mov	ds, ax				; ds:di - LMem header
	clr	di
	mov	si, ds:[di].MLBH_chunk1		; ds:si - chunk handle
	call	ChunkArrayGetCount		; cx - number of elements
	tst	cx				; empty array?
	je	exit				; if so, just exit
	call	MemFree				; if not, delete this block
	jmp	create				; and create a new one
exit:
	call	MemUnlock			; unlock the map list block

	.leave
	ret
CreateMapListBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddMapListEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new element to the map list chunk array.

CALLED BY:	ImpexMapControlMapEntry

PASS:		ds:si - instance data
		ax - identifier from source list
		cx - identifier from destination list

RETURN:		carry set if the field has been already mapped 
		carry clear if a new element has been added
		bp - ImpexError if carry set

DESTROYED:	ax, bx, dx, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddMapListEntry		proc	near	uses	ds, si
	.enter

	class	ImpexMapControlClass

	mov	dx, ax				; dx - source field number 
	call	GetMapListChunkArray		; *ds:si - chunk array
	push	bx
	mov	bx, cs				; bx:di - callback routine
	mov	di, offset CallBack_CheckSourceList
	call	ChunkArrayEnum	; check to see if source field has been mapped
	mov	bp, IE_MAP_SOURCE_FIELD_ERROR	; bp - ImpexError
	jc	exit				; if so, exit

	mov	bx, cs				; bx:di - callback routine
	mov	di, offset CallBack_CheckDestList
	call	ChunkArrayEnum	; check to see if dest field has been mapped
	mov	bp, IE_MAP_DEST_FIELD_ERROR	; bp - ImpexError
	jc	exit				; if so, exit

	call	ChunkArrayAppend		; if not, add a new entry
	mov	ds:[di].CML_source, dx
	mov	ds:[di].CML_dest, cx
	clc					; new entry has been added 
exit:
	pop	bx
	pushf					; save carry flag
	call	MemUnlock			; unlock map list block
	popf					; restore carry flag

	.leave
	ret
AddMapListEntry		endp

CallBack_CheckSourceList	proc	far
	cmp	ds:[di].CML_source, dx		; has source field been mapped?
	je	found				; if so, exit w/ carry set
	clc
	jmp	exit
found:
	stc					; if not, exit w/o carry bit
exit:
	ret
CallBack_CheckSourceList	endp

CallBack_CheckDestList	proc	far
	cmp	ds:[di].CML_dest, cx		; has dest field been mapped?
	je	found				; if so, exit w/ carry set
	clc
	jmp	exit
found:
	stc					; if not, exit w/o carry bit
exit:
	ret
CallBack_CheckDestList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteMapListEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an element from the map list chunk array.

CALLED BY:	ImpexMapControlUnMapEntry

PASS:		ds:di 	- instance data
		cx	- item to delete

RETURN:		nothing

DESTROYED:	ax, si

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteMapListEntry	proc	near	uses	ds, bx, cx, di
	.enter

	mov	si, di
	call	GetMapListChunkArray		; *ds:si - chunk array
	mov	ax, cx				; ax - element number
	call	ChunkArrayElementToPtr		; ds:di - ptr to element
	call	ChunkArrayDelete		; delete this element
	call	MemUnlock

	.leave
	ret
DeleteMapListEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMapListChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the map list block and find the start of its chunk array

CALLED BY:	INTERNAL	AddMapListEntry
				DeleteMapListEntry
				GetSourceAndDestIDs
	
PASS:		ds:si	= instance data for ImpexMapControlClass
RETURN:		ds:si	= map list chunk array
		bx	= handle of locked map list block
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	10/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMapListChunkArray	proc	near
	.enter
	class	ImpexMapControlClass

	mov     bx, ds:[si].IMCI_mapListBlock   ; bx - handle of map list blk
	call	MemLock				; lock this block
	mov	ds, ax
	clr	di				; ds:di - header 
	mov	si, ds:[di].MLBH_chunk1		; si - chunk handle
	.leave
	ret
GetMapListChunkArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapRequestDestMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the moniker for ImpexMapDestList

CALLED BY:	MSG_IMC_REQUEST_DEST_MONIKER

PASS:		bp - identifier
		*ds:si - instance data
		ds:di - instance data

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexMapRequestDestMoniker	method	dynamic	ImpexMapControlClass, 
						MSG_IMC_REQUEST_DEST_MONIKER
	; Locate the string to be used as a moniker

        mov     si, di
	mov	dx, DESTINATION			; get destination list moniker
	call	GetImpexMapDynamicListMoniker	; es:di - moniker string 	

	; Set the new moniker for this entry

	push	bx				; handle of block to unlock
	mov	bx, ds:[si].IMCI_childBlock	; bx - handle of obj block
	mov	si, offset ImpexMapDestList	; bx:si - ImpexMapDestList
	mov	cx, es
	mov	dx, di				; cx:dx - fptr to moniker text
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; copy the moniker
	pop	bx
	call	MemUnlock			; unlock this block
	ret
ImpexMapRequestDestMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapRequestSourceMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the moniker for ImpexMapSourceList

CALLED BY:	MSG_IMC_REQUEST_SOURCE_MONIKER

PASS:		bp - identifier
		*ds:si - instance data
		ds:di - instance data

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexMapRequestSourceMoniker	method	dynamic	ImpexMapControlClass, 
						MSG_IMC_REQUEST_SOURCE_MONIKER

	; Locate the string to be used as a moniker

        mov     si, di
	mov	dx, SOURCE			; get the source list moniker
	call	GetImpexMapDynamicListMoniker	; es:di - moniker string	

	; Set the new moniker for this entry

	push	bx				; handle of block to unlock
	mov	bx, ds:[si].IMCI_childBlock	; bx - handle of obj block
	mov	si, offset ImpexMapSourceList	; bx:si - ImpexMapSourceList
	mov	cx, es
	mov	dx, di				; cx:dx - fptr to moniker text
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			; copy the moniker
	pop	bx
	call	MemUnlock			; unlock this block
	ret
ImpexMapRequestSourceMoniker	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetImpexMapDynamicListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the pointer to string to be used as a moniker

CALLED BY:	ImpexMapRequest{Source, Dest, Map}Moniker

PASS:		ds:si - instance data
		dx - SOURCE or DESTINATION
		bp - identifier

RETURN:		bx - handle of block that must be unlocked  
		cx - number of bytes to copy
		es:di - fptr to moniker string 

DESTROYED:	ax

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	WARNING: This routine returns a fptr to a string that will be
		used as a moniker.  This string resides in a block
		is returned locked.  You must unlock this block
		after done using this string.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetImpexMapDynamicListMoniker	proc	near	uses	ds, si
	.enter

        class   ImpexMapControlClass

	cmp	dx, SOURCE			; source moniker requested?
	jne	dest				; if not, skip

	mov	bx, ds:[si].IMCI_dataBlock1	; assume export
	test	ds:[si].IMCI_flags, mask IMF_EXPORT	; export operation?
	jnz	common				; if not, skip

	; source moniker, import operation

	mov	bx, ds:[si].IMCI_dataBlock2	; bx - file info data block
	jmp	common
dest:
	mov	bx, ds:[si].IMCI_dataBlock1	; assume import 
	test	ds:[si].IMCI_flags, mask IMF_IMPORT	; import operation?
	jnz	common				; if so, skip

	; destination moniker, export operation 

	clr	bx
common:
	tst	bx				; is there a data block?
	je	noBlock				; if not, skip

	call	MemLock				; lock data block
	mov	es, ax
	clr	di				; es:di - ptr to LMemBlockHeader
	mov	dl, es:[di].IMFIH_flag		; dl - DefaultFieldNameUsage	
	mov	di, es:[di].IMFIH_fieldChunk	; *ds:di - chunk array 
	tst	di				; no chunk array?
	jz	default				; if not, use default field name

	push	ds, si				; save instance data

	mov	si, di
	segmov	ds, es				; *ds:si - chunk array
	mov	ax, bp				; ax - element number
	call	ChunkArrayElementToPtr		; ds:di - pointer to element
	segmov	es, ds				; es:di - pointer to string

	; ChunkArrayElementToPtr returns size of element in CX 
	; if it has variable size element, but we can't assume that. 
	; Hence, count the number of bytes in this chunk array element

	call	LocalStringLength		; cx <- length w/o NULL

	pop	ds, si				; *ds:si - instance data
	jmp	exit

default:
	call	MemUnlock			; unlock data block
noBlock:
	; convert the identifier to ascii string

	inc	bp
        mov	bx, handle ControllerStrings  
	call    MemLock			        ; lock the string block
	mov     es, ax                          ; set up the segment
assume	es:ControllerStrings
	mov     di, es:[DefaultFieldName1]  	; es:di - beginning of string
	test    ds:[si].IMCI_flags, mask IMF_IMPORT	; import operation?
	jz	useField			; skip if export
	cmp	dl, DFNU_COLUMN			; use "Column A, B, C" instead?
	jne	useField			; if not, skip
	mov     di, es:[DefaultFieldName2]  	; es:di - beginning of string
useField:
assume	es:dgroup
	push	di				; es:di - beg of string
	mov	cx, -1
	LocalLoadChar ax, ' '			; ax <- character to search for
	LocalFindChar				; search for ' '
	mov	ax, bp				; ax - number to convert
	cmp	dl, DFNU_COLUMN			; use "Column A, B, C" instead?
	je	useColumn			; if so, skip	
useField2:
	call	ConvertWordToAscii		; covnert the number to ascii
	jmp	afterConvert
useColumn:
	test    ds:[si].IMCI_flags, mask IMF_IMPORT	; import operation?
	jz	useField2			; if not, use "Field"
	call	ConvertWordToLetters		; convert number to letters
afterConvert:
	pop	si				; es:si - beg of string
	sub	di, si
	mov	cx, di				; cx - # of bytes to copy
DBCS <	shr	cx, 1							>
	dec	bp				; bp - identifier
	mov	di, si				; es:di - beg of string 
exit:
	.leave

	ret
GetImpexMapDynamicListMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an item's moniker from the source or dest list

CALLED BY:	ImpexMapRequestMapMoniker
PASS:		ax	= ID of item
		dx	= SOURCE or DESTINATION
		on stack:
			ptr to instance data for ImpexMapControlClass
RETURN:		*es:di	= moniker string
		cx	= length of string
		bx 	= handle of string block

DESTROYED:	nothing
SIDE EFFECTS:	
	The string block is returned locked and must be unlocked after
	the caller is done with the string.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	10/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMoniker	proc	near
	objectData	local		dword	; instance data
	.enter inherit

	push	bp
	movdw	dssi, objectData		; ds:si - instance data
	mov_tr	bp, ax
	call	GetImpexMapDynamicListMoniker	; es:di - moniker string
	pop	bp

	.leave
	ret
GetMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSourceAndDestIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the source and dest IDs for an entry in the mapListBlock

CALLED BY:	ImpexMapRequestMapMoniker
PASS:		ds:si	= instance data for ImpexMapControlClass
		cx	= ID of map list entry
RETURN:		ax	= source ID
		cx	= dest ID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	10/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSourceAndDestIDs	proc	near

	call	GetMapListChunkArray		; *ds:si <- chunk array
	mov_tr	ax, cx				; ax <- map list entry ID
	call	ChunkArrayElementToPtr		; ds:di <- ptr to element
EC <	ERROR_C -1							>
	mov	ax, ds:[di].CML_source
	mov	cx, ds:[di].CML_dest
	call	MemUnlock

	ret
GetSourceAndDestIDs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexMapRequestMapMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the moniker for ImpexMapMapList

CALLED BY:	MSG_IMC_REQUEST_MAP_MONIKER

PASS:		bp - identifier
		*ds:si - instance data

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version
	jenny	10/93		Fixed to return correct moniker in all cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImpexMapRequestMapMoniker	method	dynamic	ImpexMapControlClass, 
						MSG_IMC_REQUEST_MAP_MONIKER
mapID		local	word	push 	bp	; save identifier
objectData	local	fptr	push	ds, di
sourceID	local	word
destID		local	word
monikerBlock	local	hptr		; handle of moniker buffer 
childBlock	local	hptr		; handle of object block
	.enter

ForceRef	objectData	; used by called procedures

	; SETUP LOCALS

        mov     si, di

	mov	bx, ds:[si].IMCI_childBlock	; bx - handle of obj block
	mov	childBlock, bx
	mov	cx, mapID
	call	GetSourceAndDestIDs		; ax <- source ID
						; cx <- dest ID
	mov	sourceID, ax
	mov	destID, cx

	; create a data block to store the map moniker

	mov	ax, IMC_MAP_MONIKER_SIZE	; ax - size of mem block
        mov     cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or 0 ; HeapAllocFlags
	call	MemAlloc			; allocate a data block
	mov	monikerBlock, bx		; save the handle
	mov	es, ax
	clr	di				; es:di - moniker block 
	push	es, di				; save fptr

	; Locate the source list moniker

	mov	dx, SOURCE			; get the source list moniker
	mov	ax, sourceID
	call	GetMoniker			; es:di - moniker string
						; cx <- string length
	cmp	cx, IMC_MAP_MONIKER_SIZE-20	; if string too long...
	jle	notLong				; 
	shr	cx, 1				; ...display only half of it
notLong:
	; Copy the source field name to moniker block

	mov	si, di
	segmov	ds, es				; ds:si - source
	pop	es, di				; es:di - destination
	LocalCopyNString			; copy the string to buffer
	call	MemUnlock			; unlock the string block

	; copy " -> " to the moniker buffer 

	LocalLoadChar ax, ' '
	LocalPutChar esdi, ax
	LocalLoadChar ax, '-'
	LocalPutChar esdi, ax
	LocalLoadChar ax, '>'
	LocalPutChar esdi, ax
	LocalLoadChar ax, ' '
	LocalPutChar esdi, ax
	push	es, di				; save fptr

	; Locate the destination field name string

	mov	dx, DESTINATION			; get destination list moniker
	mov	ax, destID
	call	GetMoniker			; es:di - moniker string
						; cx <- string length

	; Copy the destination field string to monikerBuffer

	mov	si, di
	segmov	ds, es				; ds:si - source string
	pop	es, di				; es:di - destination

	mov	dx, IMC_MAP_MONIKER_SIZE-1	; dx - size of moniker block-1
	sub	dx, di				; dx - space left in moniker blk
	cmp	cx, dx				; enough space left?
	jle	enough				; skip if so
	xchg	cx, dx				; cx - new # of bytes to copy
enough:
	LocalCopyNString			; copy string into monikerBlock
	LocalClrChar ax
	LocalPutChar esdi, ax			; null-terminate the string
	call	MemUnlock			; unlock string block

	; Set the new moniker

	push	bp
	mov	bx, childBlock			; bx - handle of object block
	mov	bp, mapID			; bp - identifier
	mov	si, offset ImpexMapMapList	; bx:si - OD of ImpexMapMapList
	mov	cx, es
	mov	dx, 0				; cx:dx - fptr to moniker text
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL
	call	ObjMessage			; copy the moniker
	pop	bp

	mov	bx, monikerBlock
	call	MemFree				; free the moniker block

	.leave
	ret
ImpexMapRequestMapMoniker	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ConvertWordToAscii

DESCRIPTION:	Converts a hex number into a non-terminated ASCII string.
		If a 0 is passed, a '0' will be stored.

CALLED BY:	INTERNAL ()

PASS:		ax - number to convert
		es:di - location to store ASCII chars

RETURN:		es:di - addr past last char converted

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	WARNING: Maximum number of ASCII chars returned will be 4.  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

ConvertWordToAscii	proc	far	uses	bx,cx,dx
	.enter

	; first clear the space with space characters 

	push	ax, di			; save the pointer
	LocalLoadChar ax, ' '
	LocalPutChar esdi, ax
	LocalPutChar esdi, ax
	LocalPutChar esdi, ax
	LocalPutChar esdi, ax
	pop	ax, di			; restore the pointer

	clr	cx			; init count
	mov	bx, 10			; divide the number by 10

convLoop:
	clr	dx
	div	bx			; ax <- quotient, dx <- remainder
	push	dx			; save digit
	inc	cx			; inc count
	cmp	cx, 4			; max # of bytes?
	je	storeLoop		; if so, exit
	tst	ax			; done?
	jnz	convLoop		; loop while not

storeLoop:
	pop	ax			; retrieve digit
	add	ax, '0'			; convert to ASCII
	LocalPutChar esdi, ax		; save it
	loop	storeLoop

	.leave
	ret
ConvertWordToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertWordToLetters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a column reference in the form "AAA"

CALLED BY:	FormatCellReference

PASS:		ax	= Column number (1-based)
		es:di	= Place to put the text

RETURN:		es:di	= Pointer past the inserted text.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	nDigits = 0
	while (column != 0) do
	    column&digit = column/26		(Divide and save remainder)

	    if (digit == 0) then		(Check remainder)
		value = 26
		if (column != 0) then
		    column--
		endif
	    endif
	    nDigits++
	    save digit
	end
	
	while (nDigits--) do
	    restore digit
	    write (digit + 'A' - 1)
	end

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertWordToLetters	proc	near
	uses	ax, cx, dx, si
	.enter

	;
	; This will die horribly if AX=0, trashing the stack and not
	; leaving a backtrace.  Yuck.
	;

EC <	tst	ax				>
EC <	ERROR_Z -1				>

	clr	si			; si <- # of digits
	mov	cx, 26			; cx <- amount to divide by
digitLoop:
	tst	ax			; Check for no more digits
	jz	writeDigits		; Write what we have if no more
	clr	dx
	div	cx			; dl <- remainder
					; ax <- column / 26
	tst	dl			; Check for zero
	jnz	saveDigit		; Branch if not zero
	mov	dl, 26			; Force to 'Z'
	tst	ax			; Check for zero column
	jz	saveDigit		; Branch if zero
	dec	ax			; Else decrement column
saveDigit:
	;
	; ax = column
	; dl = digit
	; si = # of digits
	;
	inc	si			; One more digit
	push	dx			; Save digit
	jmp	digitLoop		; Loop to process next one

writeDigits:
	;
	; si = # of digits
	;
	pop	ax			; Restore a digit
	add	al, 'A' - 1		; Force to ascii
	LocalPutChar esdi, ax		; Write the char
	dec	si			; One less digit
	jnz	writeDigits		; Branch to write the next one

	.leave
	ret
ConvertWordToLetters	endp

ImpexMapQueryNeedToBeOnActiveList	method	dynamic	ImpexMapControlClass, 
					MSG_GEN_QUERY_NEED_TO_BE_ON_ACTIVE_LIST
	clc				; return with carry clear
	ret
ImpexMapQueryNeedToBeOnActiveList	endm

MapControlCode ends
