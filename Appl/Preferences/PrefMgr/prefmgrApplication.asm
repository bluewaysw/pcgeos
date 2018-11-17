COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefmgrApplication.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/13/92   	Initial version.

DESCRIPTION:
	
	$Id: prefmgrApplication.asm,v 1.1 97/04/04 16:27:34 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take care of nuking the current module, in addition to
		whatever our superclass does.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= PrefMgrApplication object
		^ldx:bp	= ack OD
		cx	= ack ID
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrAppDetach method dynamic PrefMgrApplicationClass,
						MSG_META_DETACH

		push	ax, cx, dx

ifdef USE_EXPRESS_MENU
		call	PrefMgrDestroyExistingExpressMenuObjects
endif
	;
	; Remove the app object from file system notification
	;
	
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_FILE_SYSTEM
		call	GCNListRemove
		pop	ax, cx, dx
		
		mov	di, offset PrefMgrApplicationClass

	;
	; There's a strange bug in the UI, where if a GenApplication
	; subclass handles MSG_META_DETACH and calls ObjEnableDetach,
	; the ACK can be sent back to the process more than once (if
	; detach is called more than once).  The work-around is to
	; avoid calling ObjEnableDetach, etc. if we've already been
	; called. 
	;
		tst	es:[moduleHandle]
		jnz	continue
		GOTO	ObjCallSuperNoLock

continue:
		call	ObjInitDetach

		call	ObjIncDetach

		push	dx, bp
		mov	dx, ds:[LMBH_handle]
		mov	bp, si
		call	FreeModule
		pop	dx, bp
	
		call	ObjCallSuperNoLock
		call	ObjEnableDetach
		ret
PrefMgrAppDetach		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefMgrApplicationClass object
		ds:di	- PrefMgrApplicationClass instance data
		es	- dgroup
		ss:[bp]	- GenOptionsParams
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/23/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrAppLoadOptions	method	dynamic	PrefMgrApplicationClass, 
					MSG_GEN_LOAD_OPTIONS

		push	ds, si
		mov	cx, ss
		mov	ds, cx
		lea	dx, ss:[bp].GOP_key
		lea	si, ss:[bp].GOP_category
		call	InitFileReadInteger
		pop	ds, si
		jc	done

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset 
		mov	ds:[di].GAI_appFeatures, ax
		call	ObjMarkDirty
		
done:
		ret
PrefMgrAppLoadOptions	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Turn off the internal modules, if our flags say to do
		so.  Add ourselves to the file change notification
		list, and scan for modules

PASS:		*ds:si	- PrefMgrApplicationClass object
		ds:di	- PrefMgrApplicationClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/27/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
ifdef PREFMGR
InternalModuleTableEntry 	struct
	IMTE_flag	PrefMgrFeatures		<>
	IMTE_object	optr
InternalModuleTableEntry	ends

internalModuleTable InternalModuleTableEntry	\
	<mask PMF_INTERNAL_1, TextTrigger>,
	<mask PMF_INTERNAL_2, ModemTrigger>,
	<mask PMF_INTERNAL_3, PrinterTrigger>
endif

PrefMgrAppAttach	method	dynamic	PrefMgrApplicationClass, 
					MSG_META_ATTACH
	;
	; Position the window appropriately (if we are running under
	; the Consumer UI (Global PC UI). "Appropriately" is on top
	; of the array of triggers in the Utilities screen. Different
	; positions are set for different screen sizes.
	;
		call	UserGetDefaultUILevel
		cmp	ax, UIIL_INTRODUCTORY
		LONG	jne	continueAttach
		push	bx, cx, dx, di, si, bp
		mov	dx, (size AddVarDataParams) + (size SpecWinSizePair)
		sub	sp, dx
		mov	bp, sp
		mov	si, bp
		add	si, size AddVarDataParams
		mov	ss:[bp].AVDP_data.segment, ss
		mov	ss:[bp].AVDP_data.offset, si
		mov	ss:[bp].AVDP_dataSize, size SpecWinSizePair
		mov	ss:[bp].AVDP_dataType, \
				HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT
		mov	ss:[si].SWSP_x, mask SWSS_RATIO or PCT_25
		mov	ss:[si].SWSP_y, mask SWSS_RATIO or PCT_25
		call	UserGetDisplayType
		and	ah, mask DT_DISP_SIZE
		cmp	ah, DS_STANDARD shl offset DT_DISP_SIZE
		je	addVardata
		mov	ss:[si].SWSP_x, mask SWSS_RATIO or PCT_30
		mov	ss:[si].SWSP_y, mask SWSS_RATIO or PCT_30
addVardata:
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	bx, handle PrefMgrPrimary
		mov	si, offset PrefMgrPrimary
		mov	di, mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
		call	ObjMessage
	;
	; Also don't allow window to be moved in the CUI
	;
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	dx, (size AddVarDataParams)
		mov	bp, sp
		mov	ss:[bp].AVDP_data.segment, 0
		mov	ss:[bp].AVDP_data.offset, 0
		mov	ss:[bp].AVDP_dataSize, 0
		mov	ss:[bp].AVDP_dataType, HINT_NOT_MOVABLE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
		call	ObjMessage
		add	sp, (size AddVarDataParams) + (size SpecWinSizePair)
		pop	bx, cx, dx, di, si, bp
	;
	; Call our superclass to complete attach process
	;
continueAttach:	
		mov	ax, MSG_META_ATTACH
		mov	di, offset PrefMgrApplicationClass
		call	ObjCallSuperNoLock
	;
	; Add this object to the FileChangeNotification list
	;
		mov	ax, MSG_PREF_MGR_APPLICATION_SCAN_FOR_MODULES
		call	ObjCallInstanceNoLock

		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_FILE_SYSTEM
		call	GCNListAdd
	;
	; Hide any modules as needed (see PrefMgrAppLoadOptions)
	;
ifdef PREFMGR
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	cx, ds:[di].GAI_appFeatures
		clr	bp
startLoop:
		test	cx, cs:[internalModuleTable][bp].IMTE_flag
		jnz	next
		movdw	bxsi, cs:[internalModuleTable][bp].IMTE_object
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		clr	di
		call	ObjMessage
next:
		add	bp, size InternalModuleTableEntry
		cmp	bp, size internalModuleTable
		jl	startLoop
endif
		ret
PrefMgrAppAttach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppScanForModules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefMgrApplicationClass object
		ds:di	- PrefMgrApplicationClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrAppScanForModules method	dynamic	PrefMgrApplicationClass, 
				MSG_PREF_MGR_APPLICATION_SCAN_FOR_MODULES

ifdef USE_EXPRESS_MENU
		call	PrefMgrDestroyExistingExpressMenuObjects
else
	;
	; Remove all the module triggers.  To do this, create a
	; MSG_GEN_DESTROY for GenTriggerClass
	;
		push	si			; app object
		
		mov	ax, MSG_GEN_DESTROY
		mov	bx, segment GenTriggerClass
		mov	si, offset GenTriggerClass
		mov	di, mask MF_RECORD
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		clr	bp
		call	ObjMessage		; di - event handle

	;
	; Now, send it to the children of the PrefDialogGroup
	;

		mov	cx, di
		mov	ax, MSG_GEN_SEND_TO_CHILDREN
		LoadBXSI	PrefMgrDialogGroup
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	si			; app object
endif		
	;
	; Go to the SYSTEM\PREF directory and scan for modules.
	;
		
		call	PrefMgrSetPath

		call	FileGetCurrentPathIDs
		jnc	gotIDs
		clr	ax
gotIDs:
		call	ObjMarkDirty
		mov	di, ds:[si]
		add	di, ds:[di].PrefMgrApplication_offset
		xchg	ds:[di].PMAI_pathIDs, ax
		tst	ax
		jz	afterFree
		call	LMemFree
afterFree:
		call	ScanForModulesLow
		
		ret
PrefMgrAppScanForModules	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppNotifyFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	See if we should rescan

PASS:		*ds:si	- PrefMgrApplicationClass object
		ds:di	- PrefMgrApplicationClass instance data
		es	- dgroup
		bp 	- handle of FileChangeNotificationData
		dx	- FileChangeNotificationType

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrAppNotifyFileChange method dynamic PrefMgrApplicationClass, 
					MSG_NOTIFY_FILE_CHANGE

		uses	ax, dx, bp, es
		.enter
		
		mov	bx, bp
		call	MemLock
		push	bx		; notification block handle
		
		mov	es, ax
		clr	di

		call	PrefMgrAppNotifyFileChangeLow
		
		jnc	done

		mov	ax, MSG_PREF_MGR_APPLICATION_SCAN_FOR_MODULES
		mov	bx, ds:[LMBH_handle]
		clr	cx, dx, bp
		mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE
		call	ObjMessage
		
done:
		pop	bx		; notification block handle
		call	MemUnlock
		.leave
		mov	di, offset PrefMgrApplicationClass
		GOTO	ObjCallSuperNoLock

PrefMgrAppNotifyFileChange	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppNotifyFileChangeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to handle a file change

CALLED BY:	PrefMgrApplicationNotifyFileChange,
		PrefMgrAppNotifyFileChangeLow 

PASS:		*ds:si - PrefMgrApplicationClass object
		dx - FileChangeNotificationType
		es:di - FileChangeNotificationData

RETURN:		carry SET if should rescan, carry clear otherwise

DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrAppNotifyFileChangeLow	proc near
		class	PrefMgrApplicationClass

EC <		cmp	dx, FileChangeNotificationType	>
EC <		ERROR_AE ILLEGAL_VALUE
		mov	bx, dx
		shl	bx
		jmp	cs:[notificationTable][bx]

notificationTable	nptr.near	\
	notifyCreate,			; FCNT_CREATE
	notifyRename,			; FCNT_RENAME
	notifyOpen,			; FCNT_OPEN
	notifyDelete,			; FCNT_DELETE
	notifyContents,			; FCNT_CONTENTS
	notifyAttributes,		; FCNT_ATTRIBUTES
	notifyFormat,			; FCNT_DISK_FORMAT
	notifyClose,			; FCNT_CLOSE
	notifyBatch,			; FCNT_BATCH
	notifySPAdd,			; FCNT_ADD_SP_DIRECTORY
	notifySPDelete,			; FCNT_DELETE_SP_DIRECTORY
	notifyFileUnread,		; FCNT_FILE_UNREAD
	notifyFileRead			; FCNT_FILE_READ
.assert ($-notificationTable)/2 eq FileChangeNotificationType

notifyCreate:
		movdw	cxdx, es:[di].FCND_id
		mov	bp, es:[di].FCND_disk
		GOTO	PrefMgrAppCheckIDIsOurs

;-------------------
notifyOpen:
notifyContents:
notifyAttributes:
notifyFormat:
notifyClose:
notifyFileUnread:
notifyFileRead:
noRescan:
		clc
		ret
;-------------------
notifyDelete:
notifyRename:
		movdw	cxdx, es:[di].FCND_id
		GOTO	PrefMgrAppCheckModuleIDs

;-------------------
notifySPAdd:
notifySPDelete:
		mov	ax, es:[di].FCND_disk
		cmp	ax, SP_SYSTEM
		je	rescan

			CheckHack <SP_TOP eq 1>
		dec	ax
		jnz	noRescan
rescan:
		stc
		ret
		
;-------------------
notifyBatch:
		mov	bx, es:[FCBND_end]
		mov	di, offset FCBND_items
batchLoop:
		cmp	di, bx		; done with all entries?
		jae	batchLoopDone	; (carry clear)
	;
	; Perform another notification. Fetch the type out
	; 
		mov	dx, es:[di].FCBNI_type
		push	di, dx, bx
	;
	; Point to the start of the stuff that resembles a
	; FileChangeNotificationData structure and recurse
	; 
		add	di, offset FCBNI_disk
		call	PrefMgrAppNotifyFileChangeLow
		pop	di, dx, bx
		jc	batchLoopDone

	;
	; Move on to next item
	;
		
		add	di, size FileChangeBatchNotificationItem

		CheckHack <FCNT_CREATE eq 0 and FCNT_RENAME eq 1>

		cmp	dx, FCNT_RENAME
		ja	batchLoop
		add	di, size FileLongName
		jmp	batchLoop
		
batchLoopDone:
		ret

PrefMgrAppNotifyFileChangeLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppCheckIDIsOurs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine whether the passed file ID matches one of
		the file IDs associated with this folder.

CALLED BY:	PrefMgrAppCheckIDIsOurs

PASS:		*ds:si - PrefMgrApplicationClass object
		cx:dx - file ID
		bp - disk handle, or 0 to just compare IDs		

RETURN:		if match:
			carry set
		else
			carry clear

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 2/93   	copied from GeoManager
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrAppCheckIDIsOurs	proc near
		class	PrefMgrApplicationClass
		uses	ax,bx
		.enter


		mov	bx, ds:[si]
		add	bx, ds:[bx].PrefMgrApplication_offset
		mov	bx, ds:[bx].PMAI_pathIDs
		tst	bx
		jz	done
		
	;
	; Figure the offset past the last entry.
	;
		mov	bx, ds:[bx]
		ChunkSizePtr	ds, bx, ax
		add	ax, bx		; ds:ax <- end

		call	PrefMgrAppCheckIDAgainstListCommon
done:
		.leave
		ret
PrefMgrAppCheckIDIsOurs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppCheckIDAgainstListCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the passed ID against the list

CALLED BY:	PrefMgrAppCheckIDIsOurs

PASS:		cx:dx - file ID
		bp - disk handle (or zero)
		ds:bx - file ID list
		ds:ax - end of list

RETURN:		carry SET if found

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrAppCheckIDAgainstListCommon	proc near
		.enter

compareLoop:
	;
	; See if this entry matches the passed ID
	; 
		cmp	cx, ds:[bx].FPID_id.high
		jne	next
		cmp	dx, ds:[bx].FPID_id.low
		jne	next

		cmp	bp, ds:[bx].FPID_disk
		je	done
next:
	;
	; Nope -- advance to next, please.
	; 
		add	bx, size FilePathID
		cmp	bx, ax
		jb	compareLoop
		stc
done:
		cmc		; return carry *set* if found
	
		.leave
		ret
PrefMgrAppCheckIDAgainstListCommon	endp



				


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppCheckModuleIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look in the module array for this item.  Note that
		we'll get a false match if a file is deleted on a
		different disk that has the same file ID as one of our
		modules. This is no big deal -- we'll just do an
		unnecessary rescan.

CALLED BY:	PrefMgrAppNotifyFileChangeLow

PASS:		cx:dx - file ID

RETURN:		carry SET if match

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrAppCheckModuleIDs	proc near
		uses	es
		.enter
		segmov	es, dgroup, ax

		mov	ax, offset PrefMgrAppCheckModuleCB
		call	TocGetFileHandle
		push	bx			; file handle
		push	es:[moduleArray]
		push	cs, ax			; callback

		clr	ax
		push	ax, ax			; first element
		dec	ax
		push	ax, ax			; do 'em all

		clr	dx			; element counter
		call	HugeArrayEnum
		.leave
		ret
PrefMgrAppCheckModuleIDs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppCheckModuleCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to check file IDs

CALLED BY:	PrefMgrAppCheckModuleIDs via HugeArrayEnum

PASS:		ds:di - PrefModuleElement
		cx:dx - file ID to check

RETURN:		if match
		    carry set
		else
		    carry clear 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrAppCheckModuleCB	proc far

		cmp	cx, ds:[di].PME_fileID.high
		je	found
		cmp	dx, ds:[di].PME_fileID.low
		je	found
		clc
done:
		ret
found:
		stc
		jmp	done
PrefMgrAppCheckModuleCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppRemovingDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefMgrApplicationClass object
		ds:di	- PrefMgrApplicationClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrAppRemovingDisk	method	dynamic	PrefMgrApplicationClass, 
					MSG_META_REMOVING_DISK

		push	cx
		mov	di, offset PrefMgrApplicationClass
		call	ObjCallSuperNoLock
		pop	cx
		
	;
	; See if the module that's currently in-use lives on the
	; passed disk.
	;
		mov	bx, es:[moduleHandle]
		tst	bx
		jz	done

		push	ds
		clr	ax
		call	MemLock
		mov	ds, ax
		test	ds:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN
		jz	unlock
		mov	ax, ds:[GH_geoHandle]
unlock:
		call	MemUnlock
		pop	ds

		tst	ax
		jz	done
		mov_tr	bx, ax
		call	FileGetDiskHandle
		cmp	bx, cx
		jne	done

		tst	es:[moduleUI].handle
		jz	afterRemove

		mov	ax, MSG_GEN_APPLICATION_REMOVE_ALL_BLOCKING_DIALOGS
		call	ObjCallInstanceNoLock
afterRemove:

		clr	dx
		call	FreeModule
done:
		.leave
		ret
PrefMgrAppRemovingDisk	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrApplicationResolveVariant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefMgrApplicationClass object
		ds:di	- PrefMgrApplicationClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 8/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrApplicationResolveVariant method	dynamic	PrefMgrApplicationClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

		cmp	cx, Pref_offset
		jne	gotoSuper
		mov	cx, segment GenApplicationClass
		mov	dx, offset  GenApplicationClass
		ret
gotoSuper:
		mov	di, offset PrefMgrApplicationClass
		GOTO	ObjCallSuperNoLock
PrefMgrApplicationResolveVariant	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppVisibilityNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefMgrApplicationClass object
		ds:di	- PrefMgrApplicationClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 8/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrAppVisibilityNotification method	dynamic	PrefMgrApplicationClass, 
				MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION
		tst	bp
		jnz	done

		cmpdw	cxdx, es:[moduleUI]
		jne	done

		mov	ax, MSG_PREF_MGR_APPLICATION_FREE_MODULE
		mov	di, mask MF_FORCE_QUEUE
		mov	bx, ds:[LMBH_handle]
		call	ObjMessage

	;
	; If we are in single-module mode, exit the app now.
	;
		segmov	ds, dgroup
		tst	ds:[singleModuleMode]
		jz	done
		mov	ax, MSG_META_QUIT
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

done:
		ret
PrefMgrAppVisibilityNotification	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrApplicationFreeModule
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Free the currently-loaded module

PASS:		*ds:si	- PrefMgrApplicationClass object
		ds:di	- PrefMgrApplicationClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 8/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrApplicationFreeModule	method	dynamic	PrefMgrApplicationClass, 
					MSG_PREF_MGR_APPLICATION_FREE_MODULE

		clr	dx
		call	FreeModule
		ret
PrefMgrApplicationFreeModule	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAppLostFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	For Express Menu Preferences, nuke the current module
		when another app comes in front of it.

PASS:		*ds:si	- PrefMgrApplicationClass object
		ds:di	- PrefMgrApplicationClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 8/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef USE_EXPRESS_MENU
PrefMgrAppLostTargetExcl	method	dynamic	PrefMgrApplicationClass, 
					MSG_META_LOST_TARGET_EXCL

		mov	di, offset PrefMgrApplicationClass
		call	ObjCallSuperNoLock

		clr	dx
		call	FreeModule
		ret
PrefMgrAppLostTargetExcl	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PMAMetaIacpNewConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch to the module specified by the IACP client.

CALLED BY:	MSG_META_IACP_NEW_CONNECTION

PASS:		*ds:si	= PrefMgrApplicationClass object
		es 	= segment of PrefMgrApplicationClass
		ax	= message #
		cx	= handle of AppLaunchBlock passed to IACPConnect. DO
			  NOT FREE THIS BLOCK.
		dx	= non-zero if recipient was just launched (i.e. it
			  received the AppLaunchBlock in its MSG_META_ATTACH
			  call)
		bp	= IACPConnection that is now open.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	9/16/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PMAMetaIacpNewConnection	method dynamic PrefMgrApplicationClass, 
					MSG_META_IACP_NEW_CONNECTION

	push	cx, dx
	mov	di, offset PrefMgrApplicationClass
	call	ObjCallSuperNoLock
	pop	cx, dx

	;
	; If the app was just launched, the MSG_GEN_PROCESS_OPEN_APPLICATION
	; handler would've already brought up the right module.  So we don't
	; need to do anything.
	;
	tst	dx
	jnz	done			; => just launched

	;
	; Switch to the passed module if a module name is passed in
	; ALB_dataFile.
	;
	mov	bx, cx
	call	MemLock
	mov	es, ax
	mov	di, offset ALB_dataFile	; es:di = ALB_dataFile
	LocalIsNull	es:[di]
	jz	unlock
	call	SwitchToModuleByName

unlock:
	call	MemUnlock

done:
	.leave
	ret
PMAMetaIacpNewConnection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Crtl-E to bring up a debug dialog box
PASS:		*ds:si	- PrefMgrGenPrimaryClass object
		ds:di	- PrefMgrGenPrimaryClass instance data
		es	- dgroup
		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

Return:		carry set if character was handled by someone (and should
		not be used elsewhere).

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	2/25/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef GPC_ONLY

systemCategoryString	char	"system", 0
versionKeyString	char	"version", 0
serialNumberKeyString	char	"serialNumber", 0

PrefMgrGenPrimaryKbd	method	dynamic	PrefMgrGenPrimaryClass, 
					MSG_META_FUP_KBD_CHAR

		test	dl, mask CF_FIRST_PRESS
		jz	done
		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jz	done
		push	ax, bx, cx, dx, bp, si
	
		cmp	cl, 'i'
		je	infoDB
		cmp	cl, 'I'
		je	infoDB
		cmp	cl, 'e'
		je	debugModeDB
		cmp	cl, 'E'
		jne	donePop
	;
	; Display the appropriate "Debug Mode" DB to the user
	;
debugModeDB:
		GetResourceHandleNS	DebugModeDB, bx
		mov	si, offset DebugModeDB
		mov	ax, MSG_PDGI_INITIALIZE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		GetResourceHandleNS	DebugModeDB, bx
		mov	si, offset DebugModeDB
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; We're done - exit out of here
	;
donePop:
		pop	ax, bx, cx, dx, bp, si
done:
		mov	di, offset PrefMgrGenPrimaryClass
		call	ObjCallSuperNoLock
		ret
	;
	; Display the serial number and version information
	;
infoDB:
		push	ds, es
		sub	sp, 100			; 50 for ver, 50 for ser num
		segmov	es, ss
		mov	di, sp			; buffer for version => ES:DI
		segmov	ds, cs, cx
		mov	si, offset systemCategoryString
		mov	dx, offset versionKeyString
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, 50>
		call	InitFileReadString
		jcxz	noVersion
readSerialNumber:
		add	di, 50			; buffer for serial # => ES:DI
		mov	cx, cs
		mov	dx, offset serialNumberKeyString
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0, 50>
		call	InitFileReadString
		jcxz	noSerialNumber
displayInfoDB:
		clr	ax
		pushdw	axax			; SDP_helpContext
		pushdw	axax			; SDP_customTriggers
		pushdw	esdi			; SDP_stringArg2 (serial number)
		sub	di, 50
		pushdw	esdi			; SDP_stringArg1 (version str)
		mov	bx, handle Strings
		mov	si, offset Strings:VersionNumberString
		call	StringLock		; string => DX:BP
		pushdw	dxbp			; SDP_customString
		mov	ax, CustomDialogBoxFlags <0, CDT_NOTIFICATION, \
						  GIT_NOTIFICATION, 0>
		push	ax
		call	UserStandardDialog
		call	MemUnlock		; unlock Strings block
		add	sp, 100
		pop	ds, es
		jmp	donePop
	;
	; No version was found in the .INI file. This should never
	; happen, so to make life esy on ourselves we'll just blast
	; an error string into the buffer we allocated on the stack
	;
noVersion:
		push	di
		mov	al, '0'
		stosb
		mov	al, '.'
		stosb
		mov	al, '0'
		stosb
		clr	ax
		stosb
		pop	di
		jmp	readSerialNumber
	;
	; No serial number was found in the .INI file. This should never
	; happen, so to make life esy on ourselves we'll just blast
	; an error string into the buffer we allocated on the stack
	;
noSerialNumber:
		push	di
		mov	al, 'n'
		stosb
		mov	al, 'o'
		stosb
		mov	al, 'n'
		stosb
		mov	al, 'e'
		stosb
		clr	ax
		stosb
		pop	di
		jmp	displayInfoDB
PrefMgrGenPrimaryKbd	endm


PrefMgrGenPrimaryOpen	method	dynamic	PrefMgrGenPrimaryClass, 
					MSG_VIS_OPEN
	mov	di, offset PrefMgrGenPrimaryClass
	call	ObjCallSuperNoLock

	mov	bx, handle DebugCategory
	call	MemLock
	mov	cx, ax
	mov	ds, ax
	mov	si, offset DebugCategory
	mov	si, ds:[si]	; ds:si - category ASCIIZ string
	mov	di, offset DebugKey
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string	
	call	InitFileReadBoolean
	jc	noFoundKey
	tst	ax
	jz	noFoundKey
	;
	;  Replace the Preferences text moniker
	;
	GetResourceHandleNS	PrefMgrPrimary, bx
	mov	si, offset PrefMgrPrimary
	mov	cx, handle PrefMgrText2Moniker 
	mov	dx, offset PrefMgrText2Moniker
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
noFoundKey:
	mov	bx, handle DebugCategory
	call	MemUnlock
		
	ret
PrefMgrGenPrimaryOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	MSG_PDGI_INITIALIZE for PrefDebugGenInteractionClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize the db with the right triggers.
Pass:		Nothing
Returns:	Nothing

DESTROYED:	ax, cx, dx, bp -- destroyed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	2/25/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDebugOpen	method	dynamic	PrefDebugGenInteractionClass,
					MSG_PDGI_INITIALIZE
	mov	bx, handle DebugCategory
	call	MemLock
	mov	cx, ax
	mov	ds, ax
	mov	si, offset DebugCategory
	mov	si, ds:[si]	; ds:si - category ASCIIZ string

	mov	di, offset DebugKey
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string	
	call	InitFileReadBoolean
	jc	noFoundKey
	tst	ax
	jz	noFoundKey
	;
	;  current in debug mode.  Show the right UI.
	;
	GetResourceHandleNS	NoDebugModeText, bx
	mov	si, offset NoDebugModeText
	call	PrefDebugSetNotUsable

	mov	si, offset DebugModeText
	call	PrefDebugSetUsable

	mov	si, offset SwitchNoDebug
	call	PrefDebugSetUsable

	mov	si, offset SwitchDebug
	call	PrefDebugSetNotUsable

	jmp	done
noFoundKey:
	;
	;  Currently in no debug mode.  Show the right UI.
	;
	GetResourceHandleNS	NoDebugModeText, bx
	mov	si, offset NoDebugModeText
	call	PrefDebugSetUsable

	mov	si, offset DebugModeText
	call	PrefDebugSetNotUsable

	mov	si, offset SwitchNoDebug
	call	PrefDebugSetNotUsable

	mov	si, offset SwitchDebug
	call	PrefDebugSetUsable

done:
	mov	bx, handle DebugCategory
	call	MemUnlock

	ret
PrefDebugOpen	endm

PrefDebugSetNotUsable	proc far
	uses	bx
	.enter
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	.leave
	ret
PrefDebugSetNotUsable	endp

PrefDebugSetUsable	proc far
	uses	bx
	.enter
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	.leave
	ret
PrefDebugSetUsable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	MSG_PDGI_SET_DEBUG_MODE
	MSG_PDGI_SET_NO_DEBUG_MODE  for PrefDebugGenInteractionClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Writing to the ini file about the debug mode.
Pass:		Nothing
Returns:	Nothing

DESTROYED:	ax, cx, dx, bp -- destroyed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	2/25/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefDebugSetDebug	method	dynamic	PrefDebugGenInteractionClass,
					MSG_PDGI_SET_DEBUG_MODE
	;
	; write to the ini file
	;
	mov	bx, handle DebugCategory
	call	MemLock
	mov	cx, ax
	mov	ds, ax
	mov	si, offset DebugCategory
	mov	si, ds:[si]	; ds:si - category ASCIIZ string
	mov	di, offset DebugKey
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string
	mov	ax, 1
	call	InitFileWriteBoolean
	;
	; Make a copy of noDriveLink
	;
	mov	di, offset DebugNoDriveLink
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string
	mov	bp, InitFileReadFlags <IFCC_INTACT, 1, 0, 0>
	call	InitFileReadString
	push	cx
		
	call	MemLock
	mov	cx, ds
	mov	di, offset DebugNoDriveLinkSafe
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string
	mov	es, ax
	clr	di		; es:di - data
	call	InitFileWriteString
	call	MemUnlock
	;
	; Erase noDriveLink
	;
	mov	di, offset DebugNoDriveLink
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string
	pop	di
	call	InitFileWriteString

	mov	bx, handle DebugCategory
	call	MemUnlock
	;
	;  Take care of the UIs
	;
	GetResourceHandleNS	DebugModeDB, bx
	mov	si, offset DebugModeDB
	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	GetResourceHandleNS	DebugActivatedDB, bx
	mov	si, offset DebugActivatedDB
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	ret
PrefDebugSetDebug	endm

PrefDebugSetNoDebug	method	dynamic	PrefDebugGenInteractionClass,
					MSG_PDGI_SET_NO_DEBUG_MODE
	.enter
	;
	; write to the ini file
	;
	mov	bx, handle DebugCategory
	call	MemLock
	mov	cx, ax
	mov	ds, ax
	mov	si, offset DebugCategory
	mov	si, ds:[si]	; ds:si - category ASCIIZ string
	mov	di, offset DebugKey
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string
	clr	ax
	call	InitFileWriteBoolean

	mov	di, offset DebugNoDriveLinkSafe
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string
	call	InitFileDeleteEntry
	mov	di, offset DebugNoDriveLink
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string
	call	InitFileDeleteEntry

	mov	bx, handle DebugCategory
	call	MemUnlock
	;
	;  Take care of the UIs
	;
	GetResourceHandleNS	DebugModeDB, bx
	mov	si, offset DebugModeDB
	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	GetResourceHandleNS	DebugModeDB, bx
	mov	si, offset DebugModeDB
	mov	ax, MSG_PDGI_SYS_SHUTDOWN
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	.leave		
	ret
PrefDebugSetNoDebug	endm

PrefDebugSysShutDown	method	dynamic	PrefDebugGenInteractionClass,
					MSG_PDGI_SYS_SHUTDOWN

	GetResourceHandleNS	DebugActivatedDB, bx
	mov	si, offset DebugActivatedDB
	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	mov	ax, SST_RESTART
	call	SysShutdown
	ret
PrefDebugSysShutDown	endm
endif

ifdef GPC_VERSION

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE  for PrinterGenDynamicListClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Disable "Set as Default Printer" trigger if the
                selected printer is already the default printer.
Pass:		Nothing
Returns:	Nothing

DESTROYED:	ax, cx, dx, bp -- destroyed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	3/19/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrinterListModified	method	dynamic	PrinterGenDynamicListClass,
					MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE,
					MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	mov	di, offset PrinterGenDynamicListClass
	call	ObjCallSuperNoLock

	; Grab the current printer number
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	mov	bx, handle PrinterInstalledList
	mov	si, offset PrinterInstalledList
	call	ObjMessage			; selection => AX
	cmp	ax, GIGS_NONE			; a valid selection ??
	je	done				; nope, so we're done
	mov	bx, ax
	tst	bx
	jz	getDefault

	; Convert the device number into the printer number (the
	; default printer count needs to ignore all non-printer
	; types of devices)
	;
	call	ConvertToPrinterNumber
	mov	bx, ax
getDefault:
	call	SpoolGetDefaultPrinter		; printer # => AX
	cmp	ax, bx
	je	disableTrigger
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	ok
enabled:
	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	cx, ATTR_GEN_FOCUS_HELP
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	ret

disableTrigger:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
ok:
	GetResourceHandleNS	PrinterDefault, bx
	mov	si, offset PrinterDefault
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	GetResourceHandleNS PrinterDefault, bx
	mov	si, offset PrinterDefault

	cmp	ax, MSG_GEN_SET_NOT_ENABLED
	jne	enabled

	mov	dx, size AddVarDataParams + (size optr)
	sub	sp, dx
	mov	bp, sp
	mov	ax, handle PrinterUI
	mov	di, offset HelpOnHelp
	mov	({optr}ss:[bp][(size AddVarDataParams)]).handle, ax
	mov	({optr}ss:[bp][(size AddVarDataParams)]).offset, di
	lea	ax, ss:[bp][(size AddVarDataParams)]
	mov	ss:[bp].AVDP_data.segment, ss
	mov	ss:[bp].AVDP_data.offset, ax
	mov	ss:[bp].AVDP_dataSize, size optr
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_FOCUS_HELP
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size AddVarDataParams + (size optr)
	jmp	done
PrinterListModified	endm

endif
