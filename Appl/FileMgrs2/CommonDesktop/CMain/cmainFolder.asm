COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cmainFolder.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/15/92   	Initial version.

DESCRIPTION:
	

	$Id: cmainFolder.asm,v 1.2 98/06/03 13:37:33 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PseudoResident	segment resource

if _GMGR

;This method is sent by the GenDisplayGroup when it or the targeted
;GenDisplay has a state change.

;
; pass:
;	cx:dx = notification type
;	bp = data block
;
DesktopNotifyDCState	method	DesktopClass, \
				MSG_META_NOTIFY_WITH_DATA_BLOCK
	cmp	cx, MANUFACTURER_ID_GEOWORKS
LONG	jne	callSuper
	cmp	dx, GWNT_DISPLAY_CHANGE
LONG	jne	callSuper

	tst	bp			; no data block, oh well...
	jz	callSuper

	;
	; make es = dgroup
	;
NOFXIP<	segmov	es, dgroup, bx						>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	push	ax, cx, dx, bp
if _GMGRONLY		; no max/restore buttons in Icon Area
if _ICON_AREA
	push	es
	mov	bx, bp
	call	MemLock				; lock down data block
	mov	es, ax
	mov	al, es:[NDC_overlapping]	; al = BooleanByte
	call	MemUnlock
	pop	es
	cbw					; ax = BooleanByte

if _WINDOW_MENU
	mov	bx, handle QuickViewToggle
	mov	si, offset QuickViewToggle
	mov	cx, mask QVTI_FULL_SIZED	; assume max'ed

	tst	ax				; max?
	jz	haveExcl			; yes

	mov	cx, mask QVTI_OVERLAPPING	; not max'ed

haveExcl:
	push	ax				; save Boolean
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				; no indeterminates
	call	ObjMessageCallFixup
;up-arrow available in both modes
	pop	cx				; retrieve state
else
	mov_tr	cx, ax
endif


endif		; _ICON_AREA
endif		; if _GMGRONLY

if _FCAB
	mov	cx, BW_TRUE			; always maximized
endif		; if _FCAB

	;
	; make sure that we don't have more folders open than we are
	; supposed to
	cmp	cx, es:[displayIsMaximized]
	je	noChange
	call	CheckNumberOfFolders
noChange:
	mov	ax, MSG_UPDATE_UP_DIR_BUTTON
	mov	di, mask MF_CALL
	call	BroadcastToFolderWindows
if CLOSE_IN_OVERLAP
	;
	; mark all Displays as being in restore-mode (will not close up when
	; another Display is opened when in maximized mode), if currently
	; in restored (overlapping windows) mode; else, mark otherwise
	;
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED
	call	ObjMessageCallFixup		; carry set if maximized
	jc	doneWithNotify			; if maximized, don't mark
						; changed into restore-mode,
						;	mark as no-close
	push	bx, si				; save display control optr
	mov	bx, segment DeskDisplayClass	; method only valid for this
	mov	si, offset DeskDisplayClass	;	class
	mov	cx, FALSE
	mov	ax, MSG_DESKDISPLAY_SET_OPEN_STATE	; pass cx = state
	mov	di, mask MF_RECORD		; create event
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event
	pop	bx, si				; restore display control optr
	mov	ax, MSG_GEN_SEND_TO_CHILDREN

	call	ObjMessageCallFixup		; send to children
endif		; if CLOSE_IN_OVERLAP
doneWithNotify:
	pop	ax, cx, dx, bp
callSuper:
	segmov	es, <segment DesktopClass>, di
	mov	di, offset DesktopClass
	call	ObjCallSuperNoLock		; call super to deal with data
						;	block
	ret
DesktopNotifyDCState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNumberOfFolders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	DesktopNotifyDCState
PASS:		cx = 0 means that we're going from full size to
			overlapping, else the other way
		es = dgroup
	
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	closes excess folders if they are open

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNumberOfFolders	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
EC<	ECCheckDGroup	es						>

	mov	es:[displayIsMaximized], cx

	mov	ax, es:[numFolderWindows]
	clr	bx

	tst	cx				; max?

	mov	bl, es:[lruNumber]		; assume max
	jz	checkFolders

	mov	bx, es:[maxNumFolderWindows]

checkFolders:
	sub	ax, bx

checkAndDecrement:
	cmp	ax, 0
	jle	exit

	dec	ax
	push	ax
	call	CloseOldestWindow
	pop	ax
	jnc	checkAndDecrement
exit:
	.leave
	ret
CheckNumberOfFolders	endp

endif				; if _GMGR

PseudoResident	ends

UtilCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopWindowsRefresh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rescan Tree Window and all Folder Windows

CALLED BY:	MSG_WINDOWS_REFRESH_ALL

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopWindowsRefreshAll	method	DesktopClass,
						MSG_WINDOWS_REFRESH_ALL
if SINGLE_DRIVE_DOCUMENT_DIR
	;
	; If there are no open windows, then create a new one.
	;
	tst	ss:[folderTrackingTable].FTE_folder.handle
	jnz	rescan

	; Just simulate a click on the drive icon

	mov	cl, DOCUMENT_DRIVE_NUM
	mov	ax, MSG_DRIVETOOL_INTERNAL
	mov	bx, handle 0
	clr	di
	call	ObjMessage

rescan::
endif

	mov	ax, MSG_WINDOWS_REFRESH_CURRENT
	mov	di, mask MF_FIXUP_DS
	call	SendToTreeAndBroadcast

afterRescan::

if INSTALLABLE_TOOLS
	;
	; build tool library list via process thread
	;
	mov	bx, handle ToolGroup
	mov	si, offset ToolGroup
	mov	ax, MSG_TM_REBUILD
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = event
	mov	cx, di			; cx = event
	mov	bx, handle 0		; via process
	mov	dx, 0			; MessageFlags
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
endif

	ret
DesktopWindowsRefreshAll	endm

DesktopWindowsRefreshCurrent	method	DesktopClass, \
						MSG_WINDOWS_REFRESH_CURRENT
	mov	ax, MSG_WINDOWS_REFRESH_CURRENT
	call	DesktopSendToCurrentOrTree
	ret
DesktopWindowsRefreshCurrent	endm


if _GMGR
DesktopWindowsCloseTarget	method	DesktopClass, \
						MSG_WINDOWS_CLOSE_TARGET
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_META_GET_TARGET_EXCL
	call	ObjMessageCallFixup		; cx:dx = target
	tst	cx				; any?
	jz	done				; nope
	mov	bx, cx				; bx:si = target
	mov	si, dx
	mov	ax, MSG_GEN_DISPLAY_CLOSE
	call	ObjMessageNone			; close it
done:
	ret
DesktopWindowsCloseTarget	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopWindowsCloseAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close all Folder Windows and Directory Tree

CALLED BY:	MSG_WINDOWS_CLOSE_ALL

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopWindowsCloseAll	method	DesktopClass, \
						MSG_WINDOWS_CLOSE_ALL
	mov	ax, MSG_CLOSE_FOLDER_WIN
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	BroadcastToFolderWindows	; send to 'em all
if not _ZMGR
if _TREE_MENU		
ifndef GEOLAUNCHER	; no Tree Window for GeoLauncher
	;
	; close Tree Window
	;
	cmp	ss:[treeRelocated], TRUE
	jne	done				; no tree yet
	mov	bx, handle TreeWindow
	mov	si, offset TreeWindow
	mov	ax, MSG_GEN_DISPLAY_CLOSE
	call	ObjMessageNone
done:
endif
endif		; if _TREE_MENU
endif
	ret
DesktopWindowsCloseAll	endm
endif			; if _GMGR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopSendToCurrentWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the incoming method to the current window

CALLED BY:	various methods

PASS:		ax - method number
		cx, dx, bp - data to send

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/14/89		Initial version
	brianc	8/29/89		changed to user TARGET stuff
	ron     10/5/92		added messages specific to NEWDESK and BA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _GMGR
DesktopSendToCurrentWindow	method	DesktopClass,
				MSG_SELECT_ALL,
				MSG_DESELECT_ALL,
				MSG_SET_VIEW_MODE,
				MSG_SET_SORT_MODE,
				MSG_SET_VIEW_OPTIONS,
				MSG_FOLDER_CLOSE
endif		; _GMGR
if _NEWDESKBA
DesktopSendToCurrentWindow	method	DesktopClass,
				MSG_SELECT_ALL,
				MSG_DESELECT_ALL,
				MSG_FOLDER_CLOSE,
				MSG_ND_FOLDER_SEND_FROM_POPUP,
				MSG_NDBA_SET_BOOKMARK,
				MSG_BA_DISTRIBUTE_FILES
endif		; if _NEWDESKBA
if _NEWDESKONLY
DesktopSendToCurrentWindow	method	DesktopClass,
				MSG_SELECT_ALL,
				MSG_DESELECT_ALL,
				MSG_FOLDER_CLOSE,
				MSG_ND_FOLDER_SEND_FROM_POPUP
endif		; _NEWDESKONLY
	;
	; get current target folder object
	;
	mov	bx, ss:[targetFolder]		; bx:si = target folder object
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	tst	bx				; check if folder window
	jz	done				; if no window, bail out
	call	ObjMessageCall
done:
	ret
DesktopSendToCurrentWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopSendToCurrentOrTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the incoming method to the current window OR
			to Tree Window object

CALLED BY:	various methods

PASS:		ax - method number
		cx, dx, bp - data to send

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopSendToCurrentOrTree	method	DesktopClass,
					MSG_OPEN_SELECT_LIST,
					MSG_FM_START_PRINT,
					MSG_FM_START_RENAME,
					MSG_FM_START_DELETE,
					MSG_FM_START_THROW_AWAY,
					MSG_FM_START_RECOVER,
					MSG_FM_START_CREATE_DIR,
					MSG_FM_START_MOVE,
					MSG_FM_START_COPY,
					MSG_FM_START_DUPLICATE,
					MSG_FM_GET_INFO,
					MSG_FM_START_CHANGE_ATTR,
					MSG_FM_START_CHANGE_TOKEN,
					MSG_FM_START_CREATE_LINK

	;
	; get current target folder object
	;
	mov	bx, ss:[targetFolder]		; bx:si = target folder object
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	tst	bx				; check if any target
ND<	jz	done				>

if not _ZMGR
if _TREE_MENU	; no Tree Window for NIKE
if _GMGRONLY	; no Tree Window for GeoLauncher

	jnz	sendCommon			; if target exists, use it
	cmp	ss:[treeRelocated], TRUE
	jne	done				; no tree yet
	mov	bx, handle DesktopUI		; else, use tree object
	mov	si, offset DesktopUI:TreeObject
sendCommon:
endif		; if _GMGRONLY
endif		; if _TREE_MENU
endif		; if (not _ZMGR)
if _FCAB
	jz	done
endif		; if _FCAB

	call	ObjMessageCall
done:
	ret
DesktopSendToCurrentOrTree	endp


if _NEWDESK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopSetSortViewUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put the itemGroup number (passed in cx) into dx and send a
		MSG_ND_FOLDER_SEND_FROM_POPUP to the current folder with
		MSG_SET_SORT_MODE as the message.
			MSG_ND_FOLDER_SEND_FROM_POPUP sends the message
		(passed in ax) and passes the data (passed in dx) in cx.

CALLED BY:	UI objects

PASS:		cx - genItem data

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopSetSortViewUI	method	DesktopClass,	MSG_SET_SORT_MODE,
						MSG_SET_VIEW_MODE,
						MSG_SET_VIEW_OPTIONS
	.enter

	mov	dx, cx				; put genItem data in dx
	mov	cx, ax				; put MSG_SET_... in cx
	mov	ax, MSG_ND_FOLDER_SEND_FROM_POPUP
	;
	; get current target folder object
	;
	mov	bx, ss:[targetFolder]		; bx:si = target folder object
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	tst	bx				; check if folder window
	jz	done				; if no window, bail out
	call	ObjMessageCall
done:
	.leave
	ret
NDDesktopSetSortViewUI	endm

NDDesktopSetBrowseMode	method	DesktopClass, MSG_SET_BROWSE_MODE
	mov	ss:[browseMode], cl
	;
	; save to .ini file, we should do this in a SAVE_OPTIONS
	; handler and send SAVE_OPTIONS from here, but we don't
	; currently handle SAVE_OPTIONS...
	;
	clr	ch
	mov	bp, cx				; bp = value
	segmov	ds, cs, cx
	mov	si, offset browseCat
	mov	dx, offset browseKey
	call	InitFileWriteInteger
	ret
NDDesktopSetBrowseMode	endm

browseCat	char	"fileManager",0
browseKey	char	"browseMode",0

endif		; if _NEWDESK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to each folder, stopping if carry set

CALLED BY:	UTILITY

PASS:		ax,cx,dx,bp - message data

RETURN:		ax,cx,dx,bp - returned from folders called
		CARRY SET if enumeration stopped by folder

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 2/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderEnum	proc far
	uses	bx,di,si,es
	.enter

NOFXIP<	segmov	es, dgroup, di						>
FXIP<	mov	di, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, di							>
	clr	di

startLoop:
						; bx = handle of opened window
	mov	bx, es:[folderTrackingTable][di].FTE_folder.handle
	tst	bx		
	jz	next

	mov	si, ss:[folderTrackingTable][di].FTE_folder.chunk
	push	di
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di	
	jc	done

next:
	add	di, size FolderTrackingEntry
	cmp	di, MAX_NUM_FOLDER_WINDOWS * (size FolderTrackingEntry)
	jne	startLoop
	clc
done:

	.leave
	ret
FolderEnum	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopUpdateFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the free space for this disk

PASS:		*ds:si	- DesktopClass object
		ds:di	- DesktopClass instance data
		es	- segment of DesktopClass
		cx	- disk handle

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	If passed a disk that's not currently in the drive, just bail.	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DesktopUpdateFreeSpace	method	dynamic	DesktopClass, 
					MSG_DESKTOP_UPDATE_FREE_SPACE

	; Convert from a disk handle to a drive number, and then back
	; again. 

		mov	bx, cx
		call	DiskGetDrive			; al - drive #
		call	DiskRegisterDiskSilently
		jc	done

		call	DiskGetVolumeFreeSpace		; dx:ax = free space
		jc	done

		mov_tr	cx, ax
		xchg	cx, dx			; cx:dx = free space

		mov	bp, bx			; bp = disk handle with cx:dx

		push	ds
		mov	di, segment dgroup
		mov	ds, di
	;
	; Put the custom callback for the duplicate message check in
	; CheckMainDuplicate.  This callback will be used when the
	; call to ObjMessage is made in the broadcast routines.
	;
		mov	ds:[checkDuplicateProc].offset, offset CheckMainDuplicateUpdate
		mov	ds:[checkDuplicateProc].segment, cs
		pop	ds

		mov	di, mask MF_FORCE_QUEUE or \
			mask MF_CHECK_DUPLICATE or \
			mask MF_REPLACE or \
			mask MF_CUSTOM
		mov	ax, MSG_UPDATE_FREE_SPACE
		call	SendToTreeAndBroadcast		; update everyone
done:
		ret
DesktopUpdateFreeSpace	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMainDuplicateUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if duplicate messages have the same disk
		handle. 
CALLED BY:	
PASS:	ds:bx	= HandleEvent of an event already on queue
	ax	= message of the new event
	cx,dx,bp = data in the new event
	si	= lptr of destination of new event
RETURN:	bp	= new value to be passed in bp in new event
	di	= one of the PROC_SE_* values
CAN DESTROY:	si

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckMainDuplicateUpdate	proc	far
	.enter

	cmp	ds:[bx].HE_method, ax	; see if MSG_DESKTOP_UPDATE_FREE_SPACE 
	je	found
CheckHack <PROC_SE_CONTINUE eq 0>
notFound:
	clr	di			; di = PROC_SE_CONTINUE
	ret
found:
	;
	; Compare the disk handle in bp to the disk handle in the
	; message handle.  If they are the same then the message is a
	; duplicate and we should replace it.
	;
	cmp	ds:[bx].HE_bp, bp
	jne 	notFound
	mov	di, PROC_SE_EXIT

	.leave
	ret
CheckMainDuplicateUpdate	endp

UtilCode	ends


