COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Folder
FILE:		folderButton.asm
AUTHOR:		Brian Chin

ROUTINES:
	INT	StartFolderObjectIconMove - dragging folder object icon
	INT	LaunchGeoApplication - attempt to launch PC/GEOS application
	INT	BuildOpenFilePathname - build complete pathname of file to open
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/29/89		broken out from folderClass.asm
	ron	9/23/92		added code for run NewDeskBA special shadows

DESCRIPTION:
	This file contains button handling routines for the Folder class.

        $Id: cfolderButton.asm,v 1.2 98/06/03 13:25:03 joon Exp $

------------------------------------------------------------------------------@

FolderAction	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartDragMoveOrCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	FolderDragSelect

PASS:		*ds:si - folder object
		cx, dx - position of mouse click
		bp low - UIButtonFlags
		bp high - UIFunctionsActive
		dgroup variable:
		[fileDragging] - file drag status

RETURN:		carry clear if quick-transfer successfully started
		carry set otherwise

DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/16/89	Initial version
	brianc	12/8/89		changed from FolderStartDragMoveOrCopy
					method handler to StartDragMoveOrCopy
					routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartDragMoveOrCopy	proc	near

	uses	si
	
	class	FolderClass

	.enter

	call	GetFolderDriverStrategy		; ax:bx = driver strategy

	;
	; allocate StartQuickTransfer parameter block on stack
	;
	sub	sp, size ClipboardQuickTransferRegionInfo	; alloc. params
	mov	bp, sp				; ss:[bp] = params.
	mov	ss:[bp].CQTRI_strategy.high, ax
	mov	ss:[bp].CQTRI_strategy.low, bx
	mov	ss:[bp].CQTRI_region.high, handle DragIconResource

	call	SelectCorrectIconRegion

	DerefFolderObject	ds, si, di
	mov	di, ds:[di].DVI_gState
	mov	ax, cx
	mov	bx, dx
	call	GrTransform		; doc -> screen coords
	mov	cx, ax
	mov	dx, bx
	sub	ax, DRAG_REGION_WIDTH/2
	sub	bx, DRAG_REGION_HEIGHT/2
	mov	ss:[bp].CQTRI_regionPos.P_x, ax		; mouse position
	mov	ss:[bp].CQTRI_regionPos.P_y, bx
	;
	; start the UI part of the quick move/copy
	;	cx, dx = mouse position in screen coords
	;	(don't push stuff as StartQuickTransfer takes stuff
	;	 on stack)
	;
	mov	di, si				; save instance handle
	mov	bx, handle DragIconResource	; lock icon region resource
	call	MemLock		;	to ensure in-memory
						; use region and notification
	mov	si, mask CQTF_USE_REGION or mask CQTF_NOTIFICATION
	mov	ax, CQTF_MOVE			; initial cursor
	mov	bx, ds:[LMBH_handle]		; bx:di = notification OD
	call	ClipboardStartQuickTransfer
	mov	bx, handle DragIconResource	; lock icon region resource
	call	MemUnlock			; unlock it (preserves carry)
						; restore stack pointer
						; (preserves carry)
	lea	sp, ss:[bp]+(size ClipboardQuickTransferRegionInfo)
	jc	done				; q-t already in progress, done
	mov	si, di				; retrieve instance handle

	DerefFolderObject	ds, si, bx
	ornf	ds:[bx].FOI_folderState, mask FOS_FEEDBACK_ON

	;
	; create and register transfer item
	;	*ds:si = Folder object
	;
	call	GenerateDragFileListItem	; bx:ax = transfer
						;  (VM file hndl):(VM blk hndl)
	jc	quickTransferError		; error, don't register
						; else, register item
	mov	bp, mask CIF_QUICK		; not RAW, QUICK
	call	ClipboardRegisterItem
;no error returned for quick-transfer
;	jc	quickTransferError
	;
	; successfully started quick-transfer, now allow mouse to move all
	; over the screen
	;

if _PEN_BASED
	;
	; for ZMGR's START_SELECT quick-transfer, must maintain grab -- we'll
	; only release as we leave the view (DesktopViewClass handles
	; RAW_UNIV_LEAVE and RAW_UNIV_ENTER)
	;
	test	ss:[fileDragging], mask FDF_SELECT_MOVECOPY
	jnz	startedQT
endif
	mov	ax, MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER
	mov	di, mask MF_CALL
	call	FolderCallView

startedQT::
	clc
	jmp	done

quickTransferError:
	;
	; handle error with starting quick-transfer
	;
	call	FolderStopQuickTransferFeedback	; stop feedback
	call	ClipboardAbortQuickTransfer	; abort our failed attempt
						; (clears cursor, etc.)
	mov	ax, ERROR_INSUFFICIENT_MEMORY	; report error
	call	DesktopOKError
	stc					; indicate error
done:
	.leave
	ret
StartDragMoveOrCopy	endp


GetFolderDriverStrategy	proc	near
	class	FolderClass

	uses	cx, dx, ds, si, bp
	.enter
	DerefFolderObject	ds, si, bx
	mov	bx, ds:[bx].FOI_windowBlock	; bx:si = GenDisplay
	mov	si, FOLDER_WINDOW_OFFSET
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, VUQ_VIDEO_DRIVER
	call	ObjMessageCall			; ax = handle

	mov	bx, ax
	call	GeodeInfoDriver			; ds:[si] = DriverInfoStruct
	mov	ax, ds:[si].DIS_strategy.segment
	mov	bx, ds:[si].DIS_strategy.offset
	.leave
	ret
GetFolderDriverStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectCorrectIconRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		*ds:si - Folder object
		ss:bp - ClipboardQuickTransferRegionInfo
		ss:[fileToMoveCopy] - if select list is empty

RETURN:		ss:[bp].CQTRI_region.low set correclty

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectCorrectIconRegion	proc	near
	class	FolderClass

	uses	ax, bx, cx, si, di, es
	.enter
	call	FolderLockBuffer

	DerefFolderObject	ds, si, di
	mov	di, ds:[di].FOI_selectList	; ds:di = head of select list
	cmp	di, NIL				; empty select list?
	je	30$				; yes, use saved file
	push	di				; save select list head

selectLoop:
	cmp	di, ss:[fileToMoveCopy]		; is it in select list?
	je	25$				; yes, use full select list
						;	(carry clear)
	mov	di, es:[di].FR_selectNext	; get next in select list
	cmp	di, NIL				; end of select list?
	jne	selectLoop			; if not, check next
	stc					; else, use saved file
25$:
	pop	di				; retrieve select list head
	jnc	40$				; if C clear, use select list
30$:
	mov	di, ss:[fileToMoveCopy]		; else, use saved file
	mov	es:[di].FR_selectNext, NIL	; end select list with it
40$:
	;
	; es:di = start of drag file list
	;
	mov	cx, offset multiIconRegion	; assume multi-file
	cmp	es:[di].FR_selectNext, NIL	; only file in select list?
	jne	haveIconRegion			; nope, multi-file
	mov	cx, offset folderIconRegion	; assume single folder
	test	es:[di].FR_fileAttrs, mask FA_SUBDIR
	jnz	haveIconRegion			; yes, single folder
	mov	cx, offset fileIconRegion	; else, single file
haveIconRegion:

	call	FolderUnlockBuffer
	mov	ss:[bp].CQTRI_region.low, cx	; save offset to correct icon
	.leave
	ret
SelectCorrectIconRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateDragFileListItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create transfer item for dragging files around

CALLED BY:	INTERNAL
			StartDragMoveOrCopy

PASS:		*ds:si - FolderClass object
		ss:[fileDragging] - file drag status

RETURN:		carry clear if successful
			bx:ax - transfer VM file and block handle
		carry set if memory allocation error
			(no transfer block allocated)

DESTROYED:	cx, dx, es, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateDragFileListItem	proc	near
	class	FolderClass
	uses	bp
	.enter

	mov	bp, ds:[LMBH_handle]		; our object block handle

	call	FolderLockBuffer
	stc
	jz	exit

	call	BuildDragFileList		; ax = VM handle of list

	call	FolderUnlockBuffer
	jc	exit				; if memory error, exit
	push	dx				; save remote flag
	mov	dx, bp				; move block handle to dx
	push	cx				; save feedback data
	push	ax				; save VM handle of list
	mov	cx, size ClipboardItemHeader
	call	ClipboardGetClipboardFile	; bx = UI's transfer VM file
	call	VMAlloc				; ax = VM transfer block handle
	push	ax				; save VM block handle
	call	VMLock				; ax = segment, bp = mem handle
	mov	es, ax				; ds = transfer item
	;
	; set up header of transfer item
	;
	mov	es:[CIH_owner].handle, dx
	mov	es:[CIH_owner].chunk, si
	mov	es:[CIH_flags], mask CIF_QUICK
	mov	es:[CIH_sourceID].handle, 0	; no associated document
	mov	es:[CIH_sourceID].chunk, 0
	mov	es:[CIH_formatCount], 1
	mov	es:[CIH_formats][0].CIFI_format.CIFID_manufacturer, \
							MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats][0].CIFI_format.CIFID_type, CIF_FILES
	pop	ax				; ax = transfer VM block handle
	pop	es:[CIH_formats][0].CIFI_vmChain.high
	clr	es:[CIH_formats][0].CIFI_vmChain.low

	pop	es:[CIH_formats][0].CIFI_extra1	; feedback data
	pop	es:[CIH_formats][0].CIFI_extra2	; remote flag

	call	VMUnlock		; unlock transfer item (pass bp)
	clc				; indicate no error
exit:
	.leave
	ret
GenerateDragFileListItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildDragFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create list of files to drag for move/copy

CALLED BY:	INTERNAL
			GenerateDragFileListItem

PASS:		*ds:si - FolderClass object
		es - segment of locked folder buffer
		(if no file is selected, uses ss:[fileToMoveCopy])
		ss:[fileDragging] - file drag status

RETURN:		carry clear if successful
			ax - VM handle of file quick transfer block
			cx - feedbackData (true diskhandle)
			dx - remote flag

		carry set if memory allocation error
			(no transfer block allocated)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildDragFileList	proc	near
	class	FolderClass
	uses	bx, bp, ds, si, es, di
	.enter

	;
	; allocate buffer for file name list (with some initial size)
	;

	push	es				; save folder buffer segment
	mov	cx, (INIT_NUM_DRAG_FILES * size FileOperationInfoEntry) + \
				size FileQuickTransferHeader
	push	cx				; save size
	call	ClipboardGetClipboardFile	; bx = UI's transfer VM file
	call	VMAlloc				; ax = VM transfer block handle
	push	ax				; save it
	call	VMLock				; ax = segment, bp = mem handle
	mov	bx, bp				; bx = VM mem handle
	pop	bp				; bp = transfer VM blk handle
	mov	es, ax				; es = buffer segment
	;
	; save pathname of folder containing files in header
	;
	mov	ax, ATTR_FOLDER_PATH_DATA
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	mov	di, offset FQTH_pathname
	mov	cx, size FQTH_pathname
	push	bx
	call	GenPathGetObjectPath
	pop	bx
	pop	dx				; retrieve size as EOF
	mov	es:[FQTH_diskHandle], cx	
	;
	; init rest of header
	;
	mov	es:[FQTH_nextBlock], 0		; no next block
	mov	es:[FQTH_UIFA], 0		; no flags yet
	mov	es:[FQTH_numFiles], 0		; no files yet
	;
	; go through selected files, adding the name of each to the
	; filename buffer. First have to deal with ability to drag file
	; that's not selected. fileToMoveCopy is the file/folder clicked on.
	; if it's in the select list, we use the whole list. If it's not,
	; we use just that file.
	;
	DerefFolderObject	ds, si, di
	mov	si, ds:[di].FOI_actualDisk	; save actual disk for later
	mov	di, ds:[di].FOI_selectList	; ds:di = head of select list
	pop	ds				; retrieve folder buffer segment
	cmp	di, NIL				; empty select list?
	je	30$				; yes, use saved file
	push	di				; save select list head
selectLoop:
	cmp	di, ss:[fileToMoveCopy]		; is it in select list?
	je	25$				; yes, use full select list
						;	(carry clear)
	mov	di, ds:[di].FR_selectNext	; get next in select list
	cmp	di, NIL				; end of select list?
	jne	selectLoop			; if not, check next
	stc					; else, use saved file
25$:
	pop	di				; retrieve select list head
	jnc	40$				; if C clear, use select list
30$:
	mov	di, ss:[fileToMoveCopy]		; else, use saved file
	mov	ds:[di].FR_selectNext, NIL	; end select list with it
40$:
	push	bp				; save VM block handle
	mov	bp, di				; ds:bp = head of select list
	mov	di, size FileQuickTransferHeader	; es:di - skip header
	call	GetFolderBufferNames		; pass: ds:bp, es:di, bx, dx
						; ret:	cx - number of files
						; 	dx - remote flag
						; destroy: bp, di
	jc	error
	mov	es:[FQTH_numFiles], cx		; store number of files
	mov	cx, si				; put true diskhandle in cx
error:
	mov	bp, bx				; bp = VM mem handle
	call	VMUnlock			; unlock filename buffer
	pop	ax				; return VM block handle
	jnc	done				; if no error, done
	call	ClipboardGetClipboardFile	; bx = UI's transfer VM file
	call	VMFree				; clean up UI's transfer VM file
	stc					; indicate error
done:
	.leave
	ret
BuildDragFileList	endp

FolderAction ends

;-----------------------------------------------------------------------------



FolderOpenCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpenESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	attempt to open file; supports folders, PCGEOS applications,
		and MS-DOS applications

CALLED BY:	INTERNAL
			FolderObjectPress
			FolderOpenSelectList

PASS:		es:di - FolderRecord of file to open
		*ds:si - FolderClass object 

RETURN:		if carry clear and a folder was opened,
			^lcx:dx	= optr of FolderClass object

DESTROYED:	ax,bx,bp

PSEUDO CODE/STRATEGY:
	Save the OD of the opened folder or application in the FolderRecord

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpenESDI	proc	far

		uses	ds, si
		
		class	FolderClass
		
		.enter
		
	;
	; XXX: We should change this routine to send a
	; MSG_SHELL_OBJECT_OPEN to a dummy with the correct NewDeskObjectType
	;
		
if _NEWDESK
		cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_LOGOUT
		jne	notLogout

if _NEWDESKBA
		mov	ax, MSG_DESKTOP_CONFIRM_LOGOUT
		mov	bx, handle 0
else
		mov	ax, MSG_META_QUIT
		mov	bx, handle Desktop
		mov	si, offset Desktop
endif
		call	ObjMessageForce
		jmp	done
		
notLogout:
		
if not GPC_NO_PRINT
		cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_PRINTER
		jne	notPrinter
		call	NDBringUpPrinterControl
		jmp	done
		
notPrinter:
endif
		
endif		; if _NEWDESK
		
	;
	; See if the file's a subdirectory. 
	;
		
		test	es:[di].FR_fileAttrs, mask FA_SUBDIR
		jz	openAppl
		
	;
	; double-click on folder, create new Folder window to show contents
	;
		
		call	BuildOpenFilePathname		; get complete
							; pathname of sub.
NOFXIP<		mov	dx, segment pathBuffer				>
FXIP <		push	ds						>
FXIP	<	GetResourceSegmentNS dgroup, ds				>
FXIP	<	mov	dx, ds				; dx = dgroup	>
FXIP	<	pop	ds						>
		mov	bp, offset pathBuffer
		mov	bx, ss:[openFileDiskHandle]
		call	InheritAndCreateNewFolderWindow
		jc	done
		
if _NEWDESK
	;
	; Mark this folder as opened, unless the thing is a drive,
	; since we won't be able to get file change notification when
	; the drive closes, for various nasty reasons.
	;
		
EC <		call	ECCheckFolderRecordESDI	>

		cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_DRIVE
		je	afterOpen
		
		ornf	es:[di].FR_state, mask FRSF_OPENED

	;
	; But only redraw the thing if this constant is on, which it isn't.
	;
		
if OPEN_CLOSE_NOTIFICATION
		mov	ax, mask DFI_CLEAR or mask DFI_DRAW
		call	ExposeFolderObjectIcon
endif
afterOpen:

endif ; _NEWDESK

		jmp	done
		
	;
	; double-click on file (not folder), try to open PCGEOS/MS-DOS
	; application
	;
openAppl:
		
if _CONNECT_MENU or _CONNECT_TO_REMOTE
	;
	; don't allow if RFSD is active
	;
		cmp	ss:[connection], CT_FILE_LINKING
		jne	notLinking
		mov	ax, ERROR_RFSD_ACTIVE
		call	DesktopOKError
		jmp	done
notLinking:
endif
		
		test	es:[di].FR_fileAttrs, mask FA_LINK
		jz	notLink
		
		call	ValidateExecutableLink
		jc	done
		
notLink:
		cmp	es:[di].FR_fileType, GFT_NOT_GEOS_FILE
		je	notGeosFile
		
openGeosApp:
		call	LaunchGeosFile		; GEOS appl. or datafile
		jmp	done
		
	;
	; not a GEOS application or datafile
	; might be DOS application or associated DOS datafile
	;
notGeosFile:
BA <		test	es:[di].FR_fileAttrs,  mask FA_LINK 	>
BA <		jnz	openGeosApp 				>

		call	PrepESDIForError	; save filename for
						; error report 

if _ZMGR
		test	es:[di].FR_state, mask FRSF_DOS_FILE_WITH_TOKEN
		jz	cantOpenFile
endif

		test	es:[di].FR_state, mask FRSF_DOS_FILE_WITH_CREATOR
		jnz	openGeosApp
		
		add	di, offset FR_name	; es:di = name
		call	CheckAssociation	; check if associated data file
		jc	notDOSAssoc		; if not, check if DOS appl.
		call	OpenAssociatedDataFile	; else, open associated appl.
		jmp	done


notDOSAssoc:
	;
	; not an associated DOS datafile, might be DOS executable
	;
if NDO_LAUNCH_DOS_EXE
		call	CheckDOSExecutable
		jz	openDOSAppl
endif
	;
	; report that we can't open this file
	;	fileOperationInfoEntryBuffer - filename info
	;
if _ZMGR
cantOpenFile:
endif
		mov	ax, ERROR_CANT_OPEN_FILE	; error code
		call	DesktopOKError			; report it
		jmp	done

if NDO_LAUNCH_DOS_EXE
openDOSAppl:
		call	LaunchMSDOSApplication
endif

done:
		.leave
		ret
FileOpenESDI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValidateExecutableLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the target of the link (to a supossed 
		executable) exists, and if not puts up an error.
		If we are looking at a courseware link, then don't bother
		to validate it.  We will do so later.

CALLED BY:	FileOpenESDI (same resource)
		FilePrintESDI (different resource)

PASS:		es:di - FolderRecord
		ds:si - FolderClass instance data

RETURN:		carry set if target was missing, error already handled

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	2/22/93    	Initial version
	ron	6/9/93		Added hack for moved courseware

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValidateExecutableLink	proc	far
	uses	ax,bx,cx,dx,si,di,ds,es

dummyPath	local	PathName

	.enter
if  _NEWDESKBA
	;
	; if this is courseware, always return clc
	;
		clc
		cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_DOS_COURSEWARE
		je	exit
		cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_GEOS_COURSEWARE
		je	exit
endif 

	call	BuildOpenFilePathname

	clr	dx				; no drive name requested
	mov	bx, ss:[openFileDiskHandle]
	segmov	ds, ss, si
	mov	si, offset pathBuffer		; bx, ds:si is path to construct
	segmov	es, ss, di
	lea	di, ss:[dummyPath]
	mov	cx, size PathName		; es:di is destination
	call	FileConstructActualPath
	jnc	exit

	cmp	ax, ERROR_PATH_NOT_FOUND
	je	linkBogus
	cmp	ax, ERROR_FILE_NOT_FOUND
	jne	doError

linkBogus:
	mov	ax, ERROR_LINK_TARGET_GONE

doError:
	call	DesktopOKError
	stc
exit:
	.leave
	ret
ValidateExecutableLink	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InheritAndCreateNewFolderWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new folder window with the same attributes as
		the current one

CALLED BY:	FileOpenESDI (same segment)
		FolderUpDir (different segment)

PASS:		*ds:si - FolderClass object 
		es:di - FolderRecord
		dx:bp - folder's pathname
		bx - disk handle for folder window

RETURN:		carry set on error,
		carry clear if OK
		^lcx:dx - OD of new folder object

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InheritAndCreateNewFolderWindow	proc	far
		class	FolderClass

		uses	si
		.enter
		
if _NEWDESK
		test	ss:[browseMode], mask FIBM_SINGLE
		jz	openNewWindow
	; If we're trying to open a window by opening an object on the
	; desktop, then make a new window instead of trying to reuse an
	; existing one.
		push	ax, bx, cx, dx, si, bp
		mov	bx, ds:[0]
		mov	si, FOLDER_OBJECT_OFFSET
		call	checkIfDesktop
		pop	ax, bx, cx, dx, si, bp
		jc	openNewWindow
if 0
	;
	; check if already opened
	;
		push	bx, cx, es, di
		mov	cx, bx			; cx = disk handle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	FindFolderWindow	; (don't need ax=obj type)
		call	ShellFreePathBuffer
		pop	bx, cx, es, di
		jc	openNewWindow		; branch to front existing
endif
	;
	; if opening wastebasket, use regular routine (will bring
	; already opened wastebasket window to the front)
	;
		push	ds, si, es, di, dx, bx
		movdw	esdi, dxbp
		mov	dx, bx
		mov	cx, SP_WASTE_BASKET
		clr	ax
		push	ax
		segmov	ds, ss
		mov	si, sp
		call	FileComparePathsEvalLinks	; returns al
		pop	cx
		jnc	noError
		mov	al, PCT_EQUAL		; error, don't reuse
noError:
		cmp	al, PCT_EQUAL
		pop	ds, si, es, di, dx, bx
		je	openNewWindow		; waste, don't reuse
	;
	; find any folder window other than desktop and
	; wastebasket
	;
		push	cx, si, di
		push	bx, dx, bp
	;
	; prefer target folder, unless wastebasket or desktop
	;
		mov	bx, ss:[targetFolder]
		mov	si, FOLDER_OBJECT_OFFSET
		call	checkIfDesktop
		jc	checkOthers		; target is desktop, try others
		call	checkIfTrash		; is target wastebasket?
		jnc	openHere		; not trash, use it
	;
	; search other folders
	;
checkOthers:
		mov	bp, -(size FolderTrackingEntry) ; will start at 1st one
checkNext:
		add	bp, size FolderTrackingEntry
		cmp	bp, (size FolderTrackingEntry) * MAX_NUM_FOLDER_WINDOWS
		je	popAndTest		; C clear
		movdw	bxsi, ss:[folderTrackingTable][bp].FTE_folder
		tst	bx
		jz	checkNext
		call	checkIfTrash
		jc	checkNext		; don't reuse wastebasket
		call	checkIfDesktop
		jc	checkNext		; don't reuse Desktop
	;
	; must FORCE_QUEUE as caller may be looping through select
	; list, so we can't go changing the folder buffer
	;
openHere:
		pop	bp, cx, dx		; bp = disk, cx:dx = path
		push	bp, cx, dx		; save again for finish
		push	bx, ds, si
		movdw	dssi, cxdx
		mov	cx, ALLOC_DYNAMIC_LOCK
		mov	ax, PATH_BUFFER_SIZE
		call	MemAlloc
		jc	errorPop
		mov	es, ax
		clr	di
		LocalCopyString
		call	MemUnlock
		mov	dx, bx			; dx = path block
		clc				; no error
errorPop:
		pop	bx, ds, si
		jc	couldntOpen
		mov	ax, MSG_FOLDER_DISPLAY_NEW_PATH
		call	ObjMessageForce
couldntOpen:
		stc
popAndTest:
		pop	bx, dx, bp
		pop	cx, si, di
		jc	short done
openNewWindow:
endif
		
		DerefFolderObject	ds, si, si
if _NEWDESK

	;
	; Copy the display options to dgroup for the new folder
	;
		
		mov	al, ds:[si].FOI_displayTypes
		mov	ss:[defDisplayTypes], al
		mov	al, ds:[si].FOI_displayAttrs
		mov	ss:[defDisplayAttrs], al
		mov	al, ds:[si].FOI_displaySort
		mov	ss:[defDisplaySort], al
		mov	al, ds:[si].FOI_displayMode
		mov	ss:[defDisplayMode], al
		mov	cx, es:[di].FR_desktopInfo.DI_objectType
else
		
EC <		mov	ax, NULL_SEGMENT				>
EC <		mov	es, ax						>

endif
		
		mov	ax, di		; offset to FolderRecord
		call	CreateNewFolderWindow
done::
		.leave
		ret
		
if _NEWDESK
checkIfTrash	label	near
		mov	cx, segment NDWastebasketClass
		mov	dx, offset NDWastebasketClass
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		call	ObjMessageCallFixup	; C set if so
		retn

checkIfDesktop	label	near
		mov	cx, segment NDDesktopClass
		mov	dx, offset NDDesktopClass
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		call	ObjMessageCallFixup	; C set if so
		retn
endif
InheritAndCreateNewFolderWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderDisplayNewPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Show new path in folder window.  For single window
		browsing mode.

PASS:		*ds:si	- FolderClass object
		es	- segment of FolderClass
		
		dx	- path block
		bp	- disk handle

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/22/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NEWDESK

FolderDisplayNewPath	method	dynamic	FolderClass, 
					MSG_FOLDER_DISPLAY_NEW_PATH
	;
	; Nuke various pieces of vardata that will get in the way when
	; we try to set this object's path
	;
		push	cx
		mov	bx, offset newPathNukeVarDataList
		mov	cx, length newPathNukeVarDataList
nukeLoop:
		mov	ax, cs:[bx]
		call	ObjVarDeleteData
		add	bx, size word
		loop	nukeLoop
		pop	cx
	;
	; Remove this folder from the FileChangeNotification list,
	; since adding the file IDs will add it back in.
	;
		push	cx, dx
		call	UtilRemoveFromFileChangeList
		pop	cx, dx

		mov	bx, dx
		call	MemLock
		mov	cx, ax
		clr	dx
		mov	ax, MSG_FOLDER_SET_PATH
		call	ObjCallInstanceNoLock
		mov	ax, MSG_FOLDER_SET_PRIMARY_MONIKER
		call	ObjCallInstanceNoLock
		mov	ax, MSG_SCAN
		call	ObjCallInstanceNoLock
		mov	ax, MSG_REDRAW
		call	ObjCallInstanceNoLock
		mov	ax, MSG_FOLDER_BRING_TO_FRONT
		call	ObjCallInstanceNoLock
		call	MemFree
	; looks like i don't have to save bx, but it says it's not destroyed...
		push	bx, si
		mov	ax, MSG_GEN_VIEW_SCROLL_TOP
		mov	di, ds:[si]
		mov	bx, ds:[di].FOI_windowBlock
		mov	si, offset FOLDER_VIEW_OFFSET
		call	ObjMessageForce
		pop	bx, si
		ret
FolderDisplayNewPath	endm

newPathNukeVarDataList	word	\
	ATTR_FOLDER_PATH_DATA,
	TEMP_FOLDER_SAVED_DISK_HANDLE,
	ATTR_FOLDER_ACTUAL_PATH,
	TEMP_FOLDER_ACTUAL_SAVED_DISK_HANDLE,
	TEMP_FOLDER_PATH_IDS

endif
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LaunchGeosFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	attempt to launch GEOS application or datafile

CALLED BY:	INTERNAL
			FileOpenESDI

PASS:		es:di - folder buffer entry of file to launch
		ds:si - instance data of parent folder object

RETURN:		nothing 

DESTROYED:	bx,cx,dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/8/89		Initial version
	brianc	12/18/89	modified for datafiles
	ron	9/23/92		added code to check special links in wizardBA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LaunchGeosFile	proc	near
	class	FolderClass
	uses	es, di, ds, si, ax, bp
	.enter

	call	PrepESDIForError		; setup filenames for error

if _NEWDESKBA
	;
	; Is this a special Wizard item
	;
	mov	cx, es:[di].FR_desktopInfo.DI_objectType
	cmp	cx, WOT_DOS_COURSEWARE
	je	courseware
	cmp	cx, WOT_GEOS_COURSEWARE
	jne	normalGeode

courseware:
	call	ShowHourglass
	call	LaunchSetupCoursewareLaunch
	call	HideHourglass
	tst	ax
	jnz	error

	cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_GEOS_COURSEWARE
	je	geosCourseware

	push	bp, bx
	call	ShowHourglass
	call	MemLock				; Iclas ArgumentBlock
	mov	es, ax
	clr	bp				; es:bp = CoursewareInfoStruct
	call	IclasExecItemLine
	call	HideHourglass
	pop	bp, bx
	call	MemFree				; free IclasArgumentBlock
	mov	bx, bp
	call	MemFree				; free item line buffer
	jmp	done

geosCourseware:
	call	ShowHourglass
	call	LaunchCreateGeosCoursewareLaunchBlock
	call	HideHourglass
	jmp	haveLaunchBlock

normalGeode:
endif		; if _NEWDESKBA

	;
	; set up AppLaunchBlock for UserLoadApplication
	;
	call	LaunchCreateAppLaunchBlock

haveLaunchBlock::
	tst	ax
	jnz	error
	mov	ax, cx				; move token to ax:bx:si

	;
	; dx = AppLaunchBlock
	; ax:bx:si = token of application (creator or double-clicked file)
	;
	; send method to our process to launch application
	;
	call	GetErrFilenameBuffer		; cx = error filename buffer
	mov	ax, ERROR_INSUFFICIENT_MEMORY	; assume error
	jcxz	error				; (cx = 0 for MemAlloc err)
	mov	ax, MSG_DESKTOP_LOAD_APPLICATION
	mov	bx, handle 0
	call	ObjMessageForce
	jmp	done
error:
	call	DesktopOKError
done:
	.leave
	ret
LaunchGeosFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			LaunchCreateAppLaunchBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates AppLaunchBlock for file passed.  (Used for both 
		opening & printing)

CALLED BY:	LaunchGeosFile, PrintGeosFile
PASS:		es:di - FolderRecord of file to launch
		ds:si - instance data of parent folder object

RETURN:		dx	- handle of AppLaunchBlock
		cx:bx:si = token of application (creator or double-clicked file)
			   NOTE:  this is generally need in ax:bx:si.  Caller
			   should 'move	ax, cx' after checking for error.

		ax	- error, if any

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LaunchCreateAppLaunchBlock	proc	far	uses	bp, di, ds, es
	.enter
	;
	; set up AppLaunchBlock for UserLoadApplication
	;
	mov	ax, size AppLaunchBlock
	mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_SHARABLE or \
					ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jnc	allocOK				; if no error, continue
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jmp	error				; else, report it

allocOK:
	mov	dx, bx				; dx = AppLaunchBlock
	cmp	es:[di].FR_fileType, GFT_EXECUTABLE
 	jne	datafile

	;
	; We're launching an application, so set up the application
	; pathname.
	;
	;		es:di = entry
	;		ds:si = instance data
	;		bx = dx = AppLaunchBlock handle
	;		ax = AppLaunchBlock segment
	;
	push	{word}es:[di].FR_token.GT_chars[0],
		{word}es:[di].FR_token.GT_chars[2],
		es:[di].FR_token.GT_manufID

	call	BuildOpenFilePathname		; build file pathname

NOFXIP<	mov	si, segment pathBuffer		; ds:si = complete path	>
NOFXIP<	mov	ds, si				;	of application	>
FXIP  <	mov	si, bx							>
FXIP  <	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP  <	mov	bx, si							>
	mov	si, offset pathBuffer
	mov	es, ax
	mov	di, offset ALB_appRef.AIR_fileName
	call	CopyNullTermString

	mov	ax, ss:[openFileDiskHandle]	; store application disk handle
	mov	es:[ALB_appRef.AIR_diskHandle], ax

	;
	;  Have the app's initial directory be SP_DOCUMENT
	;
	mov	es:[ALB_diskHandle], SP_DOCUMENT
	mov	{word} es:[ALB_path], C_BACKSLASH
DBCS <	mov	es:[ALB_path][2], 0					>

	pop	cx, bx, si
	jmp	unlockAppLaunchBlock

	;
	; launching datafile
	;	set up datafile pathname
	;	figure out parent application
	;		ds:si = folder instance data
	;		es:di = entry to launch
	;

datafile:
	push	es, di				; save entry
	mov	es, ax				; es <- ALB
	call	Folder_GetDiskAndPath
	lea	si, ds:[bx].GFP_path

;	mov	es:[ALB_diskHandle], ax		; set up starting directory
	mov	di, offset ALB_path
;	call	CopyNullTermString
;resolve links
	push	dx				; save AppLaunchBlock
	mov	bx, ax
	clr	dx				; no drive letter
	mov	cx, size ALB_path
	call	FileConstructActualPath		; ignore error
	mov	es:[ALB_diskHandle], bx
	pop	dx				; dx = AppLaunchBlock

	pop	ds, si				; ds:si = entry
	push	si				; nptr to entry
	add	si, offset FR_name
	mov	di, offset ALB_dataFile
	call	CopyNullTermString
	pop	si				; nptr to entry
	mov	cx, {word} ds:[si].FR_creator.GT_chars[0]
	mov	bx, {word} ds:[si].FR_creator.GT_chars[2]
	mov	si, ds:[si].FR_creator.GT_manufID
	mov	es:[ALB_appRef].AIR_diskHandle, 0	; Tell IACP to find it

unlockAppLaunchBlock:
	; dx = AppLaunchBlock
	; cx:bx:si = token of application (creator or double-clicked file)
	xchg	bx, dx				; unlock AppLaunchBlock
	call	MemUnlock			;	before running
	xchg	bx, dx

	clr	ax				; no error

error:
	.leave
	ret
LaunchCreateAppLaunchBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LaunchSetupCoursewareLaunch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup arguments to launch courseware

CALLED BY:	LaunchGeosFile
PASS:		es:di	= folder buffer entry of file to launch
		cx	= NewDeskObjectType
RETURN:		ds:dx	= item line buffer
		bp	= item line buffer block
		cx	= item line length
		bx 	= ^h IclasArgumentBlock

		ax = error code if any

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/17/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NEWDESKBA	;--------------------------------------------------------------

LaunchSetupCoursewareLaunch	proc	near
	uses	di,es
	.enter

	call	SetupIclasSpawnArguments
	jc	done

	mov	bp, ds:[ISLIS_myHandle]		; IclasSpawnLaunchInfoStruct

	push	ds
	mov	bx, IGAT_COURSEWARE
	clr	dx				; no quick transfer block
	call	IclasBuildArguments
	call	MemUnlock
	segmov	es, ds				; es:0 = IclasArgumentBlock
	pop	ds				;      = CoursewareInfoStruct

getGeodeName:
	;
	; Get Geode name from .itm file
	;
	push	bx				; bx ?= IclasArgumentBlock
	clr	ax				
	mov	bx, ds:[ISLIS_targetDiskHandle]	
	mov	dx, offset ISLIS_coursewareTarget
	call	IclasFileOpenAndReadReadOnlyCorrectServer
	xchg	bp, bx				; bp = item line buffer
	pushf
	call	MemFree				; IclasSpawnLaunchInfoStruct
	popf
	pop	bx				; bx ?= IclasArgumentBlock
	mov	ax, ERROR_FILE_OPEN
	jc	done				; return with error

	clr	ax				; no errors	
done:
	.leave
	ret
LaunchSetupCoursewareLaunch	endp

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LaunchCreateGeosCoursewareLaunchBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a launch block for geos courseware

CALLED BY:	LaunchGeosFile
PASS:		es:di	= folder buffer entry of file to launch
		ds:dx	= item line
		bp	= item line buffer handle
		cx	= length of item line
		bx	= extra block to put is ALB
RETURN:		dx	= handle of AppLaunchBlock
		cx:bx:si= token of application
		ax	= error code if any
DESTROYED:	nothing

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NEWDESKBA	;--------------------------------------------------------------

LaunchCreateGeosCoursewareLaunchBlock	proc	near
	uses	ds
	.enter

	push	bx				; extra block for ALB
	call	IclasGetGeodeNameFromItmLine

	;
	; Create and init AppLaunchBlock
	;
	mov	ax, size AppLaunchBlock
	mov	cx, (mask HAF_ZERO_INIT shl 8) or \
			mask HF_SHARABLE or ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jnc	allocOK
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jmp	done					; return with error

allocOK:
	mov	dx, bx					; dx = AppLaunchBlock
	pop	cx					; extra block
	push	es, di
	mov	es, ax

	mov	es:[ALB_extraData], cx
	mov	di, offset ALB_appRef.AIR_fileName
	call	CopyNullTermString

EC <	; Search back for backslash					>
EC <	std								>
EC <	push	ds, si							>
EC <	segmov	ds, es							>
EC <	mov	si, di							>
EC <slashLoop:								>
EC <	lodsb								>
EC <	cmp	al, C_BACKSLASH						>
EC <	je	addEC							>
EC <	cmp	si, -1							>
EC <	jne	slashLoop						>
EC <	dec	si							>
EC <	; Add 'EC ' to filename						>
EC <addEC:								>
EC <	inc	si							>
EC <	inc	si					; ds:si = file	>
EC < 	mov	cx, size ALB_appRef.AIR_fileName - 3			>
EC <	sub	cx, si							>
EC <	mov	si, size ALB_appRef.AIR_fileName - 4			>
EC <	mov	di, size ALB_appRef.AIR_fileName - 1			>
EC <	rep	movsb							>
EC <	mov	al, ' '							>
EC <	stosb								>
EC <	dec	di							>
EC <	mov	ax, 'EC'						>
EC <	stosw								>
EC <	pop	ds, si							>
EC <	cld								>

	mov	es:[ALB_appRef].AIR_diskHandle, SP_APPLICATION
	mov	es:[ALB_diskHandle], SP_DOCUMENT
	mov	{word} es:[ALB_path], C_BACKSLASH
	pop	es, di

	call	MemUnlock				; unlock AppLaunchBlock

	mov	bx, bp
	call	MemFree					; free itmline buffer

	;
	; Setup return arguments
	;
	mov	cx, {word} es:[di].FR_token.GT_chars[0]
	mov	bx, {word} es:[di].FR_token.GT_chars[2]
	mov	si, {word} es:[di].FR_token.GT_manufID
	clr	ax					; no errors
done:
	.leave
	ret
LaunchCreateGeosCoursewareLaunchBlock	endp

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetErrFilenameBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	build buffer containing filename to use when reporting
		errors

CALLED BY:	LaunchGeosFile

PASS:		fileOperationInfoEntryBuffer - 32 and 8.3 name info
		ax:bx:si - application token

RETURN:		cx = buffer containing app token and app/document name

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetErrFilenameBuffer	proc	far
	uses	ax, bx, dx, ds, si, es, di, bp
	.enter
	mov_tr	di, ax
	mov	dx, bx

	mov	ax, size LoadAppData
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jc	error
	mov	es, ax
	
	mov	{word}es:[LAD_token].GT_chars[0], di
	mov	{word}es:[LAD_token].GT_chars[2], dx
	mov	es:[LAD_token].GT_manufID, si
		CheckHack <offset LAD_file eq 0>	
	clr	di
NOFXIP<	mov	si, segment fileOperationInfoEntryBuffer		>
NOFXIP<	mov	ds, si				;ds = dgroup		>
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, si							>
	mov	si, offset fileOperationInfoEntryBuffer.FOIE_name
	mov	cx, size LAD_file
	rep movsb				; copy name into buffer
	call	MemUnlock
	mov	cx, bx				; cx = mem handle
	jmp	short done

error:
	clr	cx				; error, cx = 0
done:
	.leave
	ret
GetErrFilenameBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LaunchMSDOSApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	attempt to launch MSDOS application

CALLED BY:	INTERNAL
			FileOpenESDI

PASS:		es:di - name of file to attempt to launch
		*ds:si - FolderClass object 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,ds,es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/9/89		Initial version
	martin	7/19/93		Added warning dialog for Bullet

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if NDO_LAUNCH_DOS_EXE
LaunchMSDOSApplication	proc	near
	class	FolderClass

parentString	local	PathName
childString	local	PathName
DOSPathString	local	PathName


	.enter

	;
	; put up warning dialog if no keyboard is attached.
	;
if _BMGR
	call	WarnIfNoKeyboard
	jc	done
endif

	call	Folder_GetDiskAndPath
	
	push	es, di				; save filename
	lea	si, ds:[bx].GFP_path		; ds:si <- path
	mov_tr	bx, ax				; bx <- disk handle

	;
	; copy pathname to pathname buffer for DosExec.  
	;

	segmov	es, ss
	lea	di, ss:[DOSPathString]
	call	CopyNullTermString

	;
	; build parent and child strings
	;

	lea	di, ss:[parentString]
	call	CopyNullSlashString		; (start with pathname + '\')
	pop	ds, si				; filename to launch


	call	CopyNullTermString		; tack on filename to launch
	segmov	ds, ss
	lea	di, ss:[childString]
	lea	si, ss:[parentString]

	;
	; MS-DOS *.EXE or *.COM
	;	(ds:si) parent string = complete pathname of *.EXE or *.COM
	;	(es:di) child string = associated default parameters, if any
	;			(null otherwise)
	;

	push	bx				; save application disk handle
	push	bp				; save locals
	call	CheckParameters			; check for def. params
	mov	cx, bp				; dx:cx = parameters (if any)
	pop	bp				; retreive locals
	pop	bx				; retrieve disk handle
	jnc	haveParams			; if parameters, use them
	tst	ax				; detaching?
	jnz	noParams			; if not, skip
	jmp	done				; else, done

haveParams:
	push	ds, si				; save appl. name
	mov	ds, dx				; ds:si = parameters
	mov	si, cx
	call	CopyNullString			; put params. in child string
	pop	ds, si				; retrieve appl. name
noParams:
	LocalClrChar	ax			; es:di = null-term
						; child string
	LocalPutChar	esdi, ax
	lea	di, ss:[childString]
	mov	ax, bx				; execution directory's disk
						;    handle is same as
						;    executable's disk handle
	push	bp
	mov	dx, ss
	lea	bp, ss:[DOSPathString]
NOTBA <	call	FindPromptOnReturnState	>	; cl <- DosExecFlags
BA <	mov	cx, mask DEF_FORCED_SHUTDOWN >
	call	DosExec				; queues exit
	pop	bp

	jnc	done				; if no error, done

	cmp	ax, ERROR_DOS_EXEC_IN_PROGRESS	; don't try to put up an error
	je	done				; box if we are exiting

	call	DesktopOKError			; report error returned in AX
done:
	.leave
	ret
LaunchMSDOSApplication	endp
endif ; NDO_LAUNCH_DOS_EXE

if _BMGR


COMMENT @-------------------------------------------------------------------
			WarnIfNoKeyboard
----------------------------------------------------------------------------

DESCRIPTION:	Checks if a keyboard is attached, and warns the user
		if one isn't.

CALLED BY:	INTERNAL - LaunchMSDOSApplication

PASS:		nothing
RETURN:		CF 	= clear if user wants to continue operation
			  set otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/22/93		Initial version

---------------------------------------------------------------------------@
WarnIfNoKeyboard	proc	near
		uses	ax, bx, di
		.enter
	;
	; Call keyboard driver to see if a keyboard is attached
	;
		mov	ax, GDDT_POWER_MANAGEMENT
		call	GeodeGetDefaultDriver
		tst	ax
		jz	keyboardExists		; assume keyboard exists
		push	ds, si
		mov_tr	bx, ax
		call	GeodeInfoDriver		; ds:si = DriverInfoStruct
		mov	di, DR_POWER_DEVICE_ON_OFF
		mov	ax, PDT_KEYBOARD
		call	ds:[si].DIS_strategy
		pop	ds, si
		jnc	keyboardExists		; if yes, run DOS app w/o fuss

	;
	; Bring up dialog if necessary
	;
		clr	ax
		pushdw	axax		; don't care about SDOP_helpContext
		pushdw	axax		; don't care about SDOP_customTriggers
		pushdw	axax		; don't care about SDOP_stringArg2
		pushdw	axax		; don't care about SDOP_stringArg1

		mov	bx, offset noKeyboardWarningString
		pushdw	csbx		; save SDOP_customString

		mov	bx, CustomDialogBoxFlags <
					TRUE,
					CDT_QUESTION,
					GIT_AFFIRMATION,
					0
			>
		push	bx		; save SDOP_customFlags
		call	UserStandardDialog
	;
	; Set carry flag correctly
	;
		cmp	ax, IC_NO
		stc
		je	exit
keyboardExists:
		clc
exit:
		.leave
		ret
WarnIfNoKeyboard	endp

noKeyboardWarningString		char	"You have no keyboard!  ",
					"Do you still wish to run ",
					"this DOS application?",0

endif	; BMGR


if not _NEWDESKBA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPromptOnReturnState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if prompt-on-return is set and return a DosExecFlags
		record accordingly.

CALLED BY:	LaunchMSDOSApplication

PASS:		nothing

RETURN:		cl	= DosExecFlags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindPromptOnReturnState proc near
ifndef	ZMGR
ifndef	GEOLAUNCHER
	uses bx, si, dx, bp, di, ax
	.enter
	mov	bx, handle OptionsList
	mov	si, offset OptionsList
	mov     ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	mov	cx, mask OMI_ASK_BEFORE_RETURNING
	call    ObjMessageCall			; prompt-on-return set?
	mov	cl, mask DEF_PROMPT		; assume yes
	jc	done				; yes
	clr	cl				; wrong assumption -- no prompt
done:
	.leave
else
	mov	cl, mask DEF_PROMPT		; for GeoLauncher, always YES
endif
else
	clr	cl				; no prompt on return
endif
	ret
FindPromptOnReturnState endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAssociation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if the file we are attempting to open is a
		data file associated with some MS-DOS application

CALLED BY:	INTERNAL
			FileOpenESDI

PASS:		es:di = file name
		*ds:si - FolderClass object 

RETURN:		C clear if associated data file
			dx:bp - MS-DOS application name
		C set if not an associated data file

DESTROYED:	preserves ds, si, es, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/23/89	Initial version
	brianc	1/25/90		updated to use mapping-style entries
	dloft	11/29/92	updated with changes to GetTailComponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckAssociation	proc	near
	class	FolderClass

	uses	ds, si, es, di

	.enter

	; XXX: should this construct the full path? need a buffer for it
	; then...
	;
	call	Folder_GetDiskAndPath
	lea	si, ds:[bx].GFP_path		; ds:si = datafile's path

	mov	bx, ss:[dosAssociationMapBuffer]	; lock buffer
	tst	bx
	stc					; in case no buffer
	LONG jz	done				; if no buffer, exit with C set
	push	bx				; save handle of mapping list
	call	MemLock				; lock mapping list
	mov	bx, ax				; bx:cx = mappings
	clr	cx
nextMapping:
	;
	;	bx:cx = mapping string
	;	es:di = datafile's name
	;	ds:si = datafile's path
	;
	push	ds
	mov	ds, bx				; ds:si = mapping string
	xchg	si, cx
	call	GetNextMappingEntry		; mappingField1, mappingField2
	xchg	si, cx				; bx:cx = mapping string
	pop	ds				; ds:si = datafile's path
	jc	noMore				; if no more, exit with C set
	push	ds, si, es, di			; save for next time around
	;
	; compare this entry with filename we want to find application for
	;	es:di = datafile's name
	;	ds:si = datafile's path
	;
	push	es, di				; save datafile's name
	push	ds, si				; save datafile's path
NOFXIP<	segmov	ds, dgroup, dx			; ds:dx=ds:si=mask's pathname >
FXIP  <	mov	dx, bx				; save bx value		>
FXIP  <	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP  <	mov	bx, dx				; restore bx		>
	mov	dx, offset mappingField1
	mov	si, dx
	call	GetTailComponent		; ds:dx = mask's pathname tail
	cmp	dx, si				; is it only a tail component?
	pop	es, di				; es:di = datafile's path
	je	maskOnlyTail			; only tail, handle it
	push	ax, bx
	LocalClrChar	ax
	mov	bx, dx
SBCS <	xchg	{byte} ds:[bx]-1, al		; null-term. mask's path>
DBCS <	xchg	{wchar} ds:[bx]-2, ax		; null-term. mask's path>
						; ds:si = mask's path
	call	CompareString			; compare paths
SBCS <	mov	{byte} ds:[bx]-1, al		; restore null'ed char	>
DBCS <	mov	{wchar} ds:[bx]-2, ax		; restore null'ed char	>
	pop	ax, bx
	pop	es, di				; es:di = datafile's name
	jne	checkNextEntry			; no match, try next
	mov	si, dx				; ds:si = mask's name
	jmp	short checkTail
maskOnlyTail:
	pop	es, di				; es:di = datafile's name
checkTail:
	call	CheckFilemaskLowFar		; matches our datafile?
	je	foundAssoc			; yes!, found association
checkNextEntry:
	pop	ds, si, es, di			; retrieve name and path
	jmp	short nextMapping
	;
	; found associated application for this datafile
	;
foundAssoc:
	add	sp, 8
;	pop	ds, si, es, di			; retrieve name and path
	;
	; return associated application name in fixed buffer (we will be
	; unlocking association list buffer, so cannot return pointer into
	; that)
	;
NOFXIP<	mov	dx, segment dgroup					>
NOFXIP<	mov	es, dx				; dx:bp = es:di = return buf >
FXIP  <	GetResourceSegmentNS dgroup, es		; es = dgroup		>
FXIP  <	mov	dx, es				; dx = dgroup		>
	mov	di, offset assocApplicationBuffer
	mov	bp, di
	mov	ds, dx				; ds:si = buffer with assoc'ed
	mov	si, offset mappingField2	;		application
	call	CopyNullTermString		; copy it over
	clc					; indicate success
noMore:
	pop	bx				; retrieve buffer handle
	pushf					; save status
	call	MemUnlock			; unlock assoc. buffer
	popf					; retrieve status
done:
	.leave
	ret
CheckAssociation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenAssociatedDataFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	open MS-DOS application, passing data file

CALLED BY:	FileOpenESDI

PASS:		es:di = name of data file
		dx:bp = name of application (user entered association)
		*ds:si - FolderClass object 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di,es,ds,si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/23/89	Initial version
	chrisb	12/92		changed to use local vars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenAssociatedDataFile	proc	near

appOffset	local	word	push	bp
parentString	local	PathName
childString	local	PathName
DOSPathString	local	PathName

	.enter

	class	FolderClass

	call	Folder_GetDiskAndPath
	
	push	ax				; save disk handle
	push	es, di				; save filename
	lea	si, ds:[bx].GFP_path		; ds:si <- path

	;
	; copy pathname to pathname buffer for DosExec
	;
	segmov	es, ss
	lea	di, ss:[DOSPathString]
	call	CopyNullTermString

	;
	; build child string (complete pathname of data file)
	;
	push	dx				; save assoc'd appl. name
	lea	di, ss:[childString]		; es:di = child buffer
	mov	ds, dx				; ds:si = assoc'd appl. name
	mov	si, ss:[appOffset]
	push	bp				; save locals
	call	CheckParameters			; any associated params?
	mov	cx, bp				; dx:cx = parameters (if any)
	pop	bp				; retreive locals
	jnc	haveParams			; if parameters, use them
	tst	ax
	jnz	OADF_noParams			; if not detaching, skip
	add	sp, 8				; clean up stack
	jmp	done				; else, done

haveParams:
	mov	ds, dx				; ds:si = params.
	mov	si, cx
	call	CopyNullString			; copy params into child str.
	LocalLoadChar	ax, ' '			; delimit from data file
	LocalPutChar	esdi, ax
OADF_noParams:
	pop	dx				; retrieve assoc'd appl. name
	pop	ds, si				; ds:si = data file to run
	call	CopyNullTermString		; tack it on to child string

	;
	; build parent string (application name)
	;	dx:appOffset = user-entered associated application name
	;

	mov	ds, dx				; ds:si = assoc'd appl. name
	mov	si, appOffset
	lea	di, ss:[parentString]		; es:di = parent buffer
	call	CopyNullTermString

	;
	; do it
	;

	mov	dx, ss
	mov	es, dx
	lea	di, ss:[childString]	; es:di = data file pathname
	mov	ds, dx
	lea	si, ss:[parentString]	; ds:si = application name
NOTBA <	call	FindPromptOnReturnState	>	; cl <- DosExecFlags
BA <	mov	cx, mask DEF_FORCED_SHUTDOWN >
	clr	bx				; use current disk/DOS PATH
						;	for associated appl.
	pop	ax				; ax = datafile disk handle
	push	bp
	lea	bp, ss:[DOSPathString]		; dx:bp = current directory
	call	DosExec				; queues exit
	pop	bp
	jnc	done				; if no error, done
	call	DesktopOKError			; report error returned in AX
done:
	.leave
	ret
OpenAssociatedDataFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if the file we are attempting to open has
		associated default parameters

CALLED BY:	INTERNAL
			LaunchMSDOSApplication
			OpenAssociatedDataFile

PASS:		ds:si = application name
			complete pathname of appl. clicked on (LaunchMSDOS...)
			user-entered associated appl name (OpenAssoc...)

RETURN:		C clear if application has parameters
			dx:bp - parameters for application
		C set if application has no parameters
		- or -
		if detaching with modal DOS parameters box up
			ax <> 0 if no parameters
			ax = 0 if detaching

DESTROYED:	preserves ds, si, es, di

PSEUDO CODE/STRATEGY:
		write an inefficient, ugly routine that shows how easy
		it is to abuse local variables

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/25/89	Initial version
	brianc	1/25/90		updated to use mapping-style entries

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckParameters	proc	near
	uses	ds, si, es, di
	.enter

	mov	bx, ss:[dosParameterMapBuffer]	; lock buffer
	tst	bx
	stc					; in case no buffer
	mov	ax, NIL				; (not detaching)
	jz 	done				; if no buffer, exit with C set
	push	bx				; save handle of mapping list
	call	MemLock				; lock mapping list
	mov	bx, ax				; bx:cx = mappings
	clr	cx
nextMapping:
	;
	;	bx:cx = mapping string
	;	ds:si = application name
	;
	push	ds
	mov	ds, bx				; ds:si = mapping string
	xchg	si, cx
	call	GetNextMappingEntry		; mappingField1, mappingField2
	xchg	si, cx				; bx:cx = mapping string
	pop	ds				; ds:si = datafile's path
	mov	ax, NIL				; (not detaching)
	jc	noMore				; if no more, exit with C set
	;
	; compare this entry with application we want to find params for
	;	four possible cases:
	;		1) application specified with complete pathname
	;			entry specified with complete pathname
	;		--> compare complete paths verbatim
	;
	;		2) application specified with complete pathname
	;			entry specified with just filename
	;		--> compare tail component of application with entry
	;
	;		3) application specified with just filename
	;			entry specified with complete pathname
	;			(must have come from OpenAssociatedDataFile,
	;			 in which case, the user should specify
	;			 the same application name in the
	;			 dosParameters field as in the dosAssociations
	;			 field if they want to get parameters for an
	;			 associated application)
	;		--> no match
	;
	;		4) application specified with just filename
	;			entry specified with just filename
	;		--> compare
	;
FXIP  <	GetResourceSegmentNS dgroup, ds					>
FXIP  <	mov	dx, es				; dx = dgroup		>
NOFXIP<	segmov	ds, dgroup, dx			; es:bp = dx:bp = entry-appl >
	mov	es, dx				; es = ds
	mov	dx, offset mappingField1
	call	GetTailComponent		; ds:dx = entry-appl's tail
	mov	di, dx				; save tail
	cmp	dx, offset mappingField1	; is it only tail component?
	je	entryTail			; only tail, handle 2) & 4)
	;
	; case 1) or case 3)
	;
	mov	dx, si				; ds:dx = appl to get params
	call	GetTailComponent		; dx:bp = appl-param's tail
	cmp	dx, si				; complete pathname for appl?
	je	nextMapping			; if not, no match (case 3)
	;
	; case 1)	(appl complete, entry complete)
	;
	;	es:(offset mappingField1) = entry-appl
	;	ds:si = appl-param
	;
	mov	di, offset mappingField1	; es:di = entry-appl
	push	si				; save application name
;	call	CompareString			; compare complete pathname
;allow wildcards - 6/20/90
	call	CheckParamCompare
	pop	si				; retrieve application name
	jne	nextMapping			; if no match, try again
paramFound:
	;
	; return associated default parameters in fixed buffer (we will be
	; unlocking association list buffer, so cannot return pointer into
	; that)
	;
	push	ds, si				; save application to launch
FXIP  <	GetResourceSegmentNS dgroup, ds					>
FXIP  <	mov	dx, ds							>
NOFXIP<	segmov	ds, dgroup, dx						>
	mov	es, dx				; dx:bp = es:di = return buf
	mov	di, offset assocParametersBuffer
	mov	bp, di
						; ds:si = buffer with params
	mov	si, offset mappingField2
	LocalGetChar	ax, dssi		; skip starting ", if any>
SBCS <	LocalCmpChar	ax, C_QUOTE					>
DBCS <	LocalCmpChar	ax, C_QUOTATION_MARK				>
	je	99$
	LocalPrevChar	dssi			; not ", unskip it
99$:
	call	CopyNullString			; preserves al
	cmp	al, '"'				; are we quoted?
	jne	101$				; no, null-term
	LocalPrevChar	esdi			; else, move back to ending "
101$:
	LocalClrChar	ax
	LocalPutChar	esdi, ax		; null-terminate
	pop	ds, si				; ds:si = application to launch
	call	AskUserForParametersIfNeeded	; returns carry clear if
						;	params exists
						; ax = 0 if detaching
noMore:
	pop	bx				; retrieve buffer handle
	call	MemUnlock			; unlock mapping string
done:
	.leave
	ret			; <--- EXIT HERE

entryTail:
	;
	; case 2) or case 4)
	;
	;	(entry-appl is just tail component)
	;	es:di = entry-appl
	;	ds:si = appl-param
	;
	push	si
	mov	dx, si				; ds:dx = appl to get params	
	call	GetTailComponent		; ds:dx = appl-param's tail
	mov	si, dx				; ds:si = tail of appl-param
;	call	CompareString			; compare tails
;allow wildcards - 6/20/90
	call	CheckParamCompare
	pop	si
	je	paramFound
	jmp	nextMapping

CheckParameters	endp

;
; pass:
;	ds:si = filename to params for
;	es:di = filename in association string (might be filemask)
;
CheckParamCompare	proc	near
	uses	ds, es
	.enter
	xchg	si, di				; ds:si = filemask
	segxchg	ds, es				; es:di = filename
	call	CheckFilemaskLowFar
	.leave
	ret
CheckParamCompare	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AskUserForParametersIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If geos.ini specifies '?' as the parameters for a
		DOS application, then we put up a dialog box asking the
		user for parameters when the DOS application is run.

CALLED BY:	INTERNAL
			CheckParameters

PASS:		dx:bp - parameters found in geos.ini file
		ds:si - application for which params found

RETURN:		carry clear if parameters available
			dx:bp = unchanged if '?' not specified
				= user entered parameters if '?' specified
		carry set if no parameters 
		- or -
		if detaching with modal DOS parameters box up
			ax <> 0 if no parameters
			ax = 0 if detaching

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/26/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AskUserForParametersIfNeeded	proc	near
	uses	bx, cx, dx, ds, si, es, di, bp
	.enter
	mov	es, dx				; ds:bp = geos.ini params
SBCS <	cmp	{word} es:[bp], C_QUESTION_MARK	; ? + null	>
DBCS <	cmp	{wchar} es:[bp], C_QUESTION_MARK		>
DBCS <	jne	done						>
DBCS <	cmp	{wchar} es:[bp]+2, C_NULL			>
	jne	done				; not ?, return passed params
	;
	; user wants to enter parameters, put up box
	;
	push	dx, bp				; save param buffer

	mov	dx, ds				; dx:bp = application name
	mov	bp, si
	mov	bx, handle MiscUI
	mov	si, offset DosParameterApplication
	call	CallSetText			; set application name in box

;	mov	bx, handle MiscUI		; put up box
	mov	si, offset DosParameterBox
	call	UserDoDialog

	pop	cx, dx				; return text in param buffer
						; (in case not detaching)

	cmp	ax, OKCANCEL_OK			; run with params?
	je	runWithParams			; yes
	clr	ax				; else, signal detaching
	stc					; indicate no params
	jmp	short exit			; detaching --> quit

runWithParams:
;	mov	bx, handle MiscUI		; get parameters entered
	mov	si, offset DosParameterEntry
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	push	cx, dx				; save buffer segment:offset
	mov	bp, dx				; bp <- offset
	mov	dx, cx				; dx <- segment
	call	ObjMessageCall			; cx <- size
	pop	dx, bp				; dx:bp = parameter buffer
	tst	cx				; any parmeters? (clears carry)
	jnz	done				; has params, exit with C clear
	stc					; no params, exit with C set
done:
	mov	ax, NIL				; not detaching
exit:
	.leave
	ret
AskUserForParametersIfNeeded	endp

if _NEWDESKBA

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupIclasSpawnArguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up arguments based on the current folder and selection
		for the call to IclasBuildArguments

CALLED BY:	LaunchGeosFile
PASS:		es:di - folder buffer entry of file to launch
		ds:si - instance data of parent folder object
RETURN:		ds 	= ^s IclasSpawnLaunchInfoStruct (locked)
		carry iff error
		ax	= possible error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RB	11/23/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
slashRootDir		char	C_BACKSLASH, C_NULL
SetupIclasSpawnArguments	proc	far
	uses	bx,cx,dx,si,di,es
thisFolderRecord	local	fptr	push	es, di
spawnBlock		local	sptr
endOfPath		local	nptr
	.enter
	; ------ First, Get Disk And Path of Folder ----------
	;; get path of folder launched from
;	ds:	= sptr of folder object
	call	IclasCreateSpawnBlock
LONG	jc	error
	call	MemLock
	jc	error
	mov	spawnBlock, ax
	
	call 	Folder_GetDiskAndPath
	; ax = disk handle, 0 if invalid
	; ds:bx = GenFilePath

	clr	dx
	lea	si, ds:[bx].GFP_path			; ds:si = tail of path
	mov	bx, ax					; disk handle of folder
	
	; ------- Write link folder name into spawn block as courseware name
	; ds:si = folder symbolic name
		push	si
		clr	dx				; no <disk:> 
		mov	es, spawnBlock
		mov	di, offset ISLIS_fullSymbolicName
		mov	cx, FILE_LONGNAME_BUFFER_SIZE + PATH_LENGTH
		call	FileConstructFullPath
		jc	popAndError
		mov	endOfPath, di
		mov	es:[ISLIS_linkDiskHandle], bx
		pop	si
	
	; ------- Get Actual DOS path of folder -----------------
	; ds:si = folder symbolic name
		mov	bx, ax				; disk handle of folder
		mov	di, offset ISLIS_actualContainingFolder
		call	FileConstructActualPath
		jc	noChance

;	--------- Append Selected File Name after path -------------
		mov	di, endOfPath
		mov	al, C_BACKSLASH
		cmp	es:[di-1], al
		je	gotSlash
		stosb
gotSlash:
		lds	si, thisFolderRecord
.assert	((offset FR_name) eq 0)
		; ds:si = file name
		LocalCopyString
;	--------- Get DOS path of selected file	----------------------
		mov	bx, es:[ISLIS_linkDiskHandle]
		segmov	ds, es
		mov	si, offset ISLIS_fullSymbolicName
		mov	di, offset ISLIS_coursewareTarget
		mov	cx, PATH_LENGTH + FILE_LONGNAME_BUFFER_SIZE
		clr	dx				; no drive name
		call	FileConstructActualPath
		jc	targetIsGone
		mov	es:[ISLIS_targetDiskHandle], bx
		clr	ax
done:
	mov	ds, spawnBlock
	.leave
	ret
popAndError:
	pop	ax
	mov	ax, ERROR_LINK_TARGET_GONE
	jmp	done
error:
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jmp	done

targetIsGone:
	;
	; Try to do a FileReadlink to get old .itm file
	;
	
		; go to root of drive of courseware
		push	ds
		segmov	ds, cs
		mov	dx, offset slashRootDir
		mov	bx, es:[ISLIS_linkDiskHandle]
		call	FileSetCurrentPath
		pop	ds

		mov	dx, si
		mov	cx, size ISLIS_coursewareTarget
		call	FileReadLink
		jc	noChance

		segmov	ds, es
		mov	si, offset ISLIS_actualContainingFolder
						; ds:si = path of Class
		mov	dx, offset ISLIS_fullSymbolicName
		call	IclasFindMissingCourseware
		jc	noChance
		jmp	done
noChance:
	stc
	mov	ax, ERROR_LINK_TARGET_GONE
	jmp	done
SetupIclasSpawnArguments	endp

endif  ; _NEWDESKBA

FolderOpenCode ends
