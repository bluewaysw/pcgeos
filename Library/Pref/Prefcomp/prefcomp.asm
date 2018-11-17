COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		prefcomp.asm

AUTHOR:		Adam de Boor, Jan 18, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/18/93		Initial revision


DESCRIPTION:
	Computer section of Preferences.
		

	$Id: prefcomp.asm,v 1.1 97/04/05 01:33:09 newdeal Exp $

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
include system.def

include char.def
include Objects/inputC.def
include initfile.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def
UseLib	Objects/vTextC.def
UseDriver	Internal/serialDr.def
UseDriver	Internal/parallDr.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include prefcomp.def
include prefcomp.rdef

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------

idata	segment
	PrefCompMemItemClass
	PrefCompMemItemGroupClass
	PrefCompSerialValueClass
	PrefCompParallelItemGroupClass
idata	ends
 
include prefcompSerialValue.asm

PrefCompCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		nothing 

RETURN:		dx:ax - OD of root of tree

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompGetPrefUITree	proc far
		mov	dx, handle PrefCompRoot
		mov	ax, offset PrefCompRoot
		ret
PrefCompGetPrefUITree	endp
			public	PrefCompGetPrefUITree




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr

PASS:		ds:si - PrefModuleInfo structure to be filled in

RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompGetModuleInfo	proc far
		.enter

		clr	ax

		mov	ds:[si].PMI_requiredFeatures, mask PMF_HARDWARE
		mov	ds:[si].PMI_prohibitedFeatures, ax
		mov	ds:[si].PMI_minLevel, ax
		mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
		mov	ds:[si].PMI_monikerList.handle, handle  CompMonikerList
		mov	ds:[si].PMI_monikerList.offset, offset  CompMonikerList
		mov	{word} ds:[si].PMI_monikerToken,  'P' or ('C' shl 8)
		mov	{word} ds:[si].PMI_monikerToken+2, 'O' or ('M' shl 8)
		mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

		.leave
		ret
PrefCompGetModuleInfo	endp
			public	PrefCompGetModuleInfo

;==============================================================================
;
;			 PrefCompMemItemClass
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompMemItemCheckIfInInitFileKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this item should be selected on load-options.

CALLED BY:	MSG_PREF_STRING_ITEM_CHECK_IF_IN_INIT_FILE_KEY
PASS:		*ds:si	= PrefCompMemItem object
		ds:di	= PrefCompMemItemInstance
		ss:bp	= PrefItemGroupStringVars
RETURN:		carry set if should be selected
		carry clear if not
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Rather than even look at the ini file string, we just look
		for the device driver having been loaded. We might want to
		change this eventually, so we're selected if either the
		entry's in the .ini file or the driver is loaded...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompMemItemCheckIfInInitFileKey method dynamic PrefCompMemItemClass, 
				MSG_PREF_STRING_ITEM_CHECK_IF_IN_INIT_FILE_KEY
		.enter
		segmov	es, ds
		mov	di, ds:[di].PCMII_driverName
		tst	di
		jz	done
EC <		ChunkSizeHandle	ds, di, ax				>
EC <		cmp	ax, GEODE_NAME_SIZE+1				>
EC <		ERROR_NE	DRIVER_NAME_NOT_GEODE_NAME_SIZE		>
EC <		dec	ax		; ignore null byte		>
NEC <		mov	ax, GEODE_NAME_SIZE				>
		mov	di, ds:[di]
		mov	cx, mask GA_DRIVER	; must be driver
		clr	dx			; anything else
		call	GeodeFind		; returns carry set if driver
						;  found
done:
		.leave
		ret
PrefCompMemItemCheckIfInInitFileKey endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompMemItemVerifySelectionOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take care of ATTR_PREF_COMP_MEM_ITEM_CHECK*

CALLED BY:	MSG_PREF_COMP_MEM_ITEM_VERIFY_SELECTION_OK
PASS:		*ds:si	= PrefCompMemItem object
		ds:di	= PrefCompMemItemInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompMemItemVerifySelectionOK method dynamic PrefCompMemItemClass, 
				MSG_PREF_COMP_MEM_ITEM_VERIFY_SELECTION_OK
	;
	; See if there's any key we're supposed to check.
	; 
		mov	ax, ATTR_PREF_COMP_MEM_ITEM_CHECK_KEY
		call	ObjVarFindData
		jnc	done
	;
	; There is. Find the category we use.
	; 
		sub	sp, INI_CATEGORY_BUFFER_SIZE
		mov	cx, ss
		mov	dx, sp
		mov	ax, MSG_META_GET_INI_CATEGORY
		call	ObjCallInstanceNoLock
		jnc	clearStackDone
		
		mov	ax, ATTR_PREF_COMP_MEM_ITEM_CHECK_KEY
		call	ObjVarFindData
		mov	ax, sp
		push	ds, si
		mov	cx, ds
		segmov	ds, ss
		mov	dx, bx
		mov_tr	si, ax
		call	InitFileReadBoolean
		pop	ds, si
		jc	clearStackDone	; doesn't exist, so not true
		tst	ax
		jz	clearStackDone	; false, so ok
	;
	; See if we're selected. If we're not, we're happy.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].GenItem_offset
		mov	cx, ds:[di].GII_identifier
		mov	ax, MSG_GEN_ITEM_GROUP_IS_ITEM_SELECTED
		call	GenCallParent
		jc	getConfirmation
clearStackDone:
		add	sp, INI_CATEGORY_BUFFER_SIZE
done:
		ret

getConfirmation:
		push	bp, ds, si
		mov	ax, ATTR_PREF_COMP_MEM_ITEM_CHECK_MESSAGE
		call	ObjVarFindData
EC <		ERROR_NC CHECK_MESSAGE_NOT_PROVIDED			>
		mov	si, ds:[bx].chunk
		mov	bx, ds:[bx].handle
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags,CustomDialogBoxFlags <
			0,			; CDBF_SYSTEM_MODAL
			CDT_WARNING,		; CDBF_TYPE
			GIT_AFFIRMATION,0	; CDBF_RESPONSE_TYPE
		>
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]
		movdw	ss:[bp].SDP_customString, dssi
		clr	ax
		mov	ss:[bp].SDP_helpContext.segment, ax
		mov	ss:[bp].SDP_customTriggers.segment, ax
		mov	ss:[bp].SDP_stringArg2.segment, ax
		mov	ss:[bp].SDP_stringArg1.segment, ax
		call	UserStandardDialog
		call	MemUnlock
		pop	bp, ds, si
		cmp	ax, IC_YES
		jne	deselect
		
	;
	; Nuke the vardata that got us here, as we won't go to state, and one
	; warning is sufficient for most users...
	; 
		mov	ax, ATTR_PREF_COMP_MEM_ITEM_CHECK_KEY
		call	ObjVarDeleteData
		jmp	clearStackDone

deselect:
	;
	; Deselect ourselves.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].GenItem_offset
		mov	cx, ds:[di].GII_identifier
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_ITEM_STATE
		call	GenCallParent
		jmp	clearStackDone
		
PrefCompMemItemVerifySelectionOK endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompMemItemGroupHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the selection of all our children before we let
		our superclass determine if our state has changed.

CALLED BY:	MSG_PREF_HAS_STATE_CHANGED
PASS:		*ds:si	= PrefCompMemItemGroup object
RETURN:		carry set if changed
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompMemItemGroupHasStateChanged method dynamic PrefCompMemItemGroupClass, 
					MSG_PREF_HAS_STATE_CHANGED
		mov	ax, MSG_PREF_COMP_MEM_ITEM_VERIFY_SELECTION_OK
		call	GenSendToChildren
		
		mov	ax, MSG_PREF_HAS_STATE_CHANGED
		mov	di, offset PrefCompMemItemGroupClass
		GOTO	ObjCallSuperNoLock
PrefCompMemItemGroupHasStateChanged endm


;==============================================================================
;
;		       PrefCompParallelItemGroupClass
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompParallelItemGroupLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the interrupt level for the port from the serial
		driver and set our state accordingly.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= PrefCompParallelItemGroup object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	original value set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompParallelItemGroupLoadOptions method dynamic PrefCompParallelItemGroupClass, 
			       MSG_META_LOAD_OPTIONS
		.enter
		push	ds, si
		mov	bx, handle parallel
		call	GeodeInfoDriver
		segmov	es, ds
		mov	bp, si
		pop	ds, si
		
		mov	bx, ds:[di].PCPIGI_portNum
		mov	di, DR_PARALLEL_STAT_PORT
		call	es:[bp].DIS_strategy
		jc	disableForNow

		cbw
		mov_tr	cx, ax
		mov	ax, MSG_PREF_ITEM_GROUP_SET_ORIGINAL_SELECTION
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
disableForNow:
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		jmp	done
PrefCompParallelItemGroupLoadOptions endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompParallelItemGroupSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save our value to the .ini file and communicate it to the
		parallel driver as well.

CALLED BY:	MSG_GEN_SAVE_OPTIONS
PASS:		*ds:si	= PrefCompParallelItemGroup object
		ds:di	= PrefCompParallelItemGroupInstance
		ss:bp	= GenOptionsParams
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompParallelItemGroupSaveOptions method dynamic PrefCompParallelItemGroupClass, 
				MSG_GEN_SAVE_OPTIONS

		add	bx, ds:[bx].GenItemGroup_offset
EC <		cmp	ds:[bx].GIGI_numSelections, 1			>
EC <		ERROR_NE PARALLEL_ITEM_GROUP_MAY_HAVE_ONLY_ONE_THING_SELECTED>
		mov	ax, ds:[bx].GIGI_selection
	;
	; First verify things with the parallel driver.
	; 
		push	bp, ds, di, ax, si
		push	ds:[di].PCPIGI_portNum
		mov	bx, handle parallel
		call	GeodeInfoDriver
		mov	di, DR_PARALLEL_SET_INTERRUPT
		pop	bx
		call	ds:[si].DIS_strategy
		pop	bp, ds, di, cx, si
		jc	error
	;
	; Seems ok. Write the value to the ini file.
	; 
		mov_tr	ax, cx		; save irq #
		segmov	ds, ss, cx	; ds, cx <- ss
		lea	si, ss:[bp].GOP_category
		lea	dx, ss:[bp].GOP_key
		mov_tr	bp, ax		; bp <- value to write
		call	InitFileWriteInteger
		jmp	done

error:
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags,CustomDialogBoxFlags <
			0,			; CDBF_SYSTEM_MODAL
			CDT_ERROR,		; CDBF_TYPE
			GIT_NOTIFICATION,0	; CDBF_RESPONSE_TYPE
		>
		mov	di, offset ParallelIntTaken
		cmp	ax, STREAM_INTERRUPT_TAKEN
		je	haveErrString
		mov	di, offset SerialNoSuchDevice	; XXX: reuse :)
		cmp	ax, STREAM_NO_DEVICE
		je	haveErrString
		mov	di, offset SerialDeviceInUse	; XXX: reuse
EC <		cmp	ax, STREAM_DEVICE_IN_USE			>
EC <		WARNING_NE	UNHANDLED_STREAM_ERROR_CODE_FROM_DEFINE_PORT>
haveErrString:
		mov	bx, handle Strings
		call	MemLock
		mov	es, ax
		mov	ss:[bp].SDP_customString.segment, ax
		mov	di, es:[di]
		mov	ss:[bp].SDP_customString.offset, di
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	di, ds:[di].GI_visMoniker
EC <		tst	di						>
EC <		ERROR_Z	NEED_MONIKER_FOR_ERROR_MESSAGE			>
		mov	di, ds:[di]
		add	di, offset VM_data + offset VMT_text
		movdw	ss:[bp].SDP_stringArg1, dsdi
		clr	ax
		mov	ss:[bp].SDP_helpContext.segment, ax
		mov	ss:[bp].SDP_customTriggers.segment, ax
		mov	ss:[bp].SDP_stringArg2.segment, ax
		call	UserStandardDialog
done:
		ret
PrefCompParallelItemGroupSaveOptions endm

PrefCompCode	ends
