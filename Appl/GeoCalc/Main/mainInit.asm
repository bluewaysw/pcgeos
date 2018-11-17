COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Init
FILE:		mainInit.asm

AUTHOR:		Gene Anderson, Feb 19, 1990

ROUTINES:
	Name			Description
	----			-----------
	GeoCalcOpenApplication	MSG_GEN_PROCESS_OPEN_APPLICATION
	GeoCalcCloseApplication	MSG_GEN_PROCESS_CLOSE_APPLICATION
	GeoCalcInstallToken	MSG_GEN_PROCESS_INSTALL_TOKEN
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/1/91		Initial revision

DESCRIPTION:
	Contains intialization routines for PC/GEOS GeoCalc
		
	$Id: mainInit.asm,v 1.1 97/04/04 15:49:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize GeoCalc -- build a fonts menu
CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		cx - AppAttachFlags
		dx - Handle of AppLaunchBlock
		bp - Handle of extra state block
		ds - dgroup
RETURN:		none
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _USE_FEP
LocalDefNLString fepDir	<"FEP",0>
fepCategory	char	"fep",0
fepDriverKey	char	"driver",0

udata	segment
;
; fep variables
;
fepDriverHandle	hptr
fepStrategy	fptr.far
udata	ends
endif

GeoCalcOpenApplication	method GeoCalcProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION

	push	bp				;save extra block handle
	push	ax, cx, dx

if _USE_FEP
	;
	; load FEP reference
	;
	push	si
	push	ds				; save dgroup
	segmov	ds, cs, cx
	mov	si, offset fepCategory
	mov	dx, offset fepDriverKey
	clr	bp				; get heap block
	call	InitFileReadString		; carry set if none
	mov	ax, 0				; in case no FEP
	jc	noFEP
	push	bx
	call	FilePushDir
	mov	bx, SP_SYSTEM
	segmov	ds, cs
	mov	dx, offset fepDir
	call	FileSetCurrentPath
	jc	noFEPPop
	pop	bx
	push	bx
	call	MemLock
	mov	ds, ax
	clr	si, ax, bx
	call	GeodeUseDriver
	call	FilePopDir
	mov	ax, 0				; in case no FEP
	jc	noFEPPop
	mov	dx, bx				; dx = fep driver handle
	call	GeodeInfoDriver			; ds:si = driver info
	mov	ax, ds:[si].DIS_strategy.segment
	mov	si, ds:[si].DIS_strategy.offset
noFEPPop:
	pop	bx
	call	MemFree
noFEP:
	pop	ds				; ds = dgroup
	mov	ds:[fepStrategy].segment, ax
	mov	ds:[fepStrategy].offset, si
	mov	ds:[fepDriverHandle], dx
	pop	si
endif

	;
	; register ourselves
	;
	call	GeodeGetProcessHandle		;bx <- process handle
	mov	cx, bx
	clr	dx
	call	ClipboardAddToNotificationList

	;
	; Add to INI file change notification list.
	;
	pop	ax, cx, dx

if not _SAVE_TO_STATE
	;
	; stuff last file, if any, into AppLaunchBlock
	;
	push	ax, cx, dx, bp, si, ds, es
	mov	bx, dx				;bx = AppLaunchBlock
	push	bx				;save AppLaunchBlock
	call	MemLock
	mov	es, ax
	mov	ax, cs
	mov	ds, ax
	mov	si, offset saveFileCategory
	mov	cx, ax
	mov	dx, offset saveFilePathKey
	mov	di, offset ALB_path
	mov	bp, size PathName
	call	InitFileReadData		;read path
	jc	noDoc
	mov	cx, cs
	mov	dx, offset saveFileNameKey
	mov	di, offset ALB_dataFile
	mov	bp, size FileLongName
	call	InitFileReadData		;read filename
	jc	noDoc
	mov	cx, cs
	mov	dx, offset saveFileDiskKey
	clr	bp				; allocate buffer
	call	InitFileReadData		; bx = buffer, cx = size
	jc	noDoc
	call	MemLock
	mov	ds, ax				; ds:si = DiskSave data
	clr	si
	clr	cx				; no callback
	call	DiskRestore			; ax = disk handle
	pushf
	call	MemFree				; free DiskSave data
	popf
	jc	noDoc				; couldn't restore
	mov	es:[ALB_diskHandle], ax
noDoc:
	pop	bx				;unlock AppLaunchBlock
	call	MemUnlock
	;
	; delete last file for next time
	;
	mov	cx, cs
	mov	dx, offset saveFileNameKey
	mov	ds, cx
	mov	si, offset saveFileCategory
	call	InitFileDeleteEntry
	mov	dx, offset saveFilePathKey
	call	InitFileDeleteEntry
	mov	dx, offset saveFileDiskKey
	call	InitFileDeleteEntry
	pop	ax, cx, dx, bp, si, ds, es
endif

	;
	; Call our superclass to get the ball rolling...
	;
	mov	di, offset GeoCalcProcessClass
	call	ObjCallSuperNoLock


	pop	bx				;bx <- block handle for data

if (size procVars) gt (size GenProcessInstance)
	tst	bx				;check for no block
	jz	quit				;branch if no state data

	call	MemLock				;lock state variables
	
	mov	ds, ax				;ds:si <- source
	clr	si
	
	GetResourceSegmentNS	dgroup, es	;es:di <- dest
	mov	di, offset dgroup:procVars
	
	mov	cx, size procVars		;cx <- byte count
	rep	movsb				;copy the state data
	
	call	MemUnlock			;release the state block
quit:
endif
	;
	; Tell the GrObj to do something useful
	;
if _CHARTS
	GetResourceHandleNS	GCGrObjHead, bx
	mov	si, offset GCGrObjHead
	mov	ax, MSG_GH_SEND_NOTIFY_CURRENT_TOOL
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
endif
	;
	;    Ignore undo for the duration of this launch
	;
	clr	di
	call	GeodeGetProcessHandle
	mov	cx, 1					;flush actions
	mov	ax,MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS
	call	ObjMessage

	ret

GeoCalcOpenApplication	endm

if not _SAVE_TO_STATE

;	DO NOT CHANGE THESE UNLESS YOU ALSO CHANGE THE KEYS IN
;	Document/documentClass.asm

saveFileCategory	char	'geocalc',0
saveFileNameKey		char	'savedFilenameNew',0
saveFilePathKey		char	'savedFilepathNew',0
saveFileDiskKey		char	'savedFileDisk',0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down GeoCalc
CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		ds - dgroup
		es - seg addr of GeoCalcProcessClass
		ax - the method
RETURN:		cx - handle of block to save (0 for none)
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcCloseApplication	method dynamic GeoCalcProcessClass, \
					MSG_GEN_PROCESS_CLOSE_APPLICATION

if _USE_FEP
	;
	; done with FEP driver
	;
	mov	ax, 0
	xchg	ds:[fepStrategy].segment, ax
	tst	ax
	jz	noFep
	mov	bx, ds:[fepDriverHandle]
	call	GeodeFreeLibrary
noFep:
endif

	;
	; unregister ourselves
	;
	call	GeodeGetProcessHandle		; bx <- process handle
	mov	cx, bx
	clr	dx
	call	ClipboardRemoveFromNotificationList

	;
	; Remove ourselves from the INI file change list.
	; 
	clr	di
	call	GeodeGetProcessHandle
	mov	ax, MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS
	call	ObjMessage
	;
	; Do the superclass thing
	;
	mov	ax, MSG_GEN_PROCESS_CLOSE_APPLICATION
	mov	di, offset GeoCalcProcessClass
	call	ObjCallSuperNoLock
	;
	; Save the instance data
	;
if ((size procVars) le (size GenProcessInstance)) or not _SAVE_TO_STATE
	clr	cx
else
	;
	; Allocate a block to save the data into.
	;
	mov	ax, size procVars	; ax <- size of state variables
	mov	cx, mask HF_SWAPABLE or \
		((mask HAF_LOCK) shl 8)
	call	MemAlloc		; bx <- block handle
	mov	cx, 0			; cx <- in case of error
	jc	quit			; branch if error
					; ax <- segment address
	;
	; Copy the data from the procVars into the destination block.
	;
	mov	es, ax			; es:di <- destination
	clr	di
					; ds:si <- source
	mov	si, offset dgroup:procVars
	mov	cx, size procVars	; cx <- size

	;
	; Check if ds is pointing to DGroup
	;
EC<	push	ax, bx, ds						>
EC<	mov	ax, ds							>
EC<	GetResourceSegmentNS dgroup, ds					>
EC<	mov	bx, ds							>
EC<	cmp	ax, bx							>
EC<	ERROR_NE	-1						>
EC<	pop	ax, bx, ds						>

	rep	movsb			; Copy the state data
	
	;
	; Release the block and return the block handle.
	;
	call	MemUnlock		; Unlock the block
	mov	cx, bx			; cx <- block handle
quit:
endif
	ret
GeoCalcCloseApplication	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
PASS:		*ds:si	= GeoCalcProcessClass object
		ds:di	= GeoCalcProcessClass instance data
		ds:bx	= GeoCalcProcessClass object (same as *ds:si)
		es 	= segment of GeoCalcProcessClass
		ax	= message #
		dx	= Block handle to block of structure
				AppInstanceReference
		CurPath	- Set to state directory
RETURN:		ax - VM file handle (0 if you want no state file)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _SAVE_TO_STATE
GeoCalcCreateNewStateFile	method dynamic GeoCalcProcessClass, 
					MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
	clr	ax		; no state file
	ret
GeoCalcCreateNewStateFile	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcInstallToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install tokens
CALLED BY:	MSG_GEN_PROCESS_INSTALL_TOKEN

PASS:		none
RETURN:		none
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcInstallToken	method GeoCalcProcessClass, \
				MSG_GEN_PROCESS_INSTALL_TOKEN
	;
	; Call our superclass to get the ball rolling...
	;
	mov	di, offset GeoCalcProcessClass
	call	ObjCallSuperNoLock
	;
	; install datafile token
	;
	mov	ax, ('G') or ('C' shl 8)	; ax:bx:si = token used for
	mov	bx, ('D') or ('a' shl 8)	;	datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	done				; yes, do nothing
	mov	cx, handle GCDatafileMonikerList ; cx:dx = OD of moniker list
	mov	dx, offset GCDatafileMonikerList
	clr	bp				; list is in data resource...
	call	TokenDefineToken		; add icon to token database
done:
	ret

GeoCalcInstallToken	endm

InitCode	ends
