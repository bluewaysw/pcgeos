COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Util
FILE:		utilCode.asm

ROUTINES:
	INT	CheckQuickTransferType - check if quick-transfer item
						supports CIF_FILES
	INT	CreateNewFolderWindow - create new window for newly opened
						folder
	INT	CheckFolderWindow - check if a new Folder Window should be
					created for this folder
	INT	SaveNewFolder - save handle of new Folder Object's block
					in global table
	INT	BroadcastToFolderWindows - send message to all folder windows
	INT	CallGenCopyVisMoniker - set new vis moniker for object
	INT	GetDiskInfo - get volume label, etc.
	INT	MarkWindowForUpdate - mark the specified folder window(s)
					as in need of updating
	INT	UpdateMarkedWindows - update the marked folder window(s)
	INT	GetLoadAppGenParent - stuff AppLaunchBlock with genParent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/89		Initial version

DESCRIPTION:
	This file contains desktop utility routines.

	$Id: cutilUtil.asm,v 1.3 98/06/03 13:51:14 joon Exp $

------------------------------------------------------------------------------@

UtilCode segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilAddToFileChangeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the object to the system-level file-change notification
		list, as well as the application object's active list, so
		we can remove it from the file-change list on detach.

CALLED BY:	(EXTERNAL) FolderScan, Tree...
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	object is added to both the GCNSLT_FILE_SYSTEM list and the
     		application object's active list. object will want to handle
		MSG_META_DETACH and call UtilRemoveFromFileChangeList

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilAddToFileChangeList proc	far
	uses	bp, si
	.enter

	;
	; Add to the file-change list
	; 
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	call	GCNListAdd
	
	;
	; Add to the app's active list.
	; 
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST or \
						mask GCNLTF_SAVE_TO_STATE
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ax, MSG_META_GCN_LIST_ADD
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GCNListParams

	.leave
	ret
UtilAddToFileChangeList		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilRemoveFromFileChangeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the object from the system-wide file-change list

CALLED BY:	(EXTERNAL) FolderClose, FolderDetach, Tree...
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilRemoveFromFileChangeList proc	far
	class	FolderClass
	uses	bp, si
	.enter
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GCNListRemove

	;
	; Remove from the app's active list.
	; 
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST or \
						mask GCNLTF_SAVE_TO_STATE
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ax, MSG_META_GCN_LIST_REMOVE
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GCNListParams
	.leave
	ret
UtilRemoveFromFileChangeList		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckQuickTransferType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if quick-transfer item supports CIF_FILES

CALLED BY:	EXTERNAL

PASS:		nothing
RETURN:		carry clear if CIF_FILES is supported
			ax - feedback data
			bx - remote flag
		carry set if CIF_FILES not supported

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/13/91	Initial version
	dlitwin	01/21/93	Added Wizard support and new QuickTransfer
				feedback data and remote flag

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckQuickTransferType	proc	far
	uses	cx, dx, di, si, bp, es
	.enter
	mov	bp, mask CIF_QUICK
	call	ClipboardQueryItem		; bp = # formats, cx:dx = owner
	push	bx, ax				; bx:ax = VM file:VM block
	tst	bp
	stc					; assume no quick-transfer item
	jz	done				; no item (carry set)

BA<	push	bx, ax				>
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_FILES
	call	ClipboardRequestItemFormat	; is CIF_FILES there?
						; cx = extra1 = feedback data
						; dx = extra2 = remote flag

BA<	tst	ax				>
BA<	pop	bx, ax				>
BA<	jnz	done				>
BA<	mov	cx, MANUFACTURER_ID_WIZARD	>
BA<	mov	dx, CIF_FILES			>
BA<	call	ClipboardRequestItemFormat	; is CIF_FILES there?	>
BA<						; cx = extra1 = feedback data >
BA<						; dx = extra2 = remote flag >

	tst	ax
	stc					; assume not
	jz	done				; nope (carry set)
	clc					; else, indicate found
done:
	pop	bx, ax				; retrieve header
	pushf					; save result flag
	call	ClipboardDoneWithItem
	popf					; retreive result flag
	mov	ax, cx				; feedback flag
	mov	bx, dx				; remote flag
	.leave
	ret
CheckQuickTransferType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareDiskHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if two disk handles are "the same", for the purposes
		of quick-transfer and determining what the default
		quick-transfer action should be.

CALLED BY:	GetQuickTransferMethod, various DeskDisplay tools
PASS:		ax	= disk handle #1
		dx	= disk handle #2
RETURN:		flags set so je will take if two disks are "the same"
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		While the comparison of disk handles would appear fairly
		simple, it is complicated by the existence of StandardPath
		constants. For our purposes, if both ax and dx are StandardPath
		constants, they're "the same". If one is a StandardPath and
		the other is the system disk, the are also "the same". If
		ax and dx are numerically the same, they are also "the same"

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareDiskHandles proc	far
	uses	bp, es
	.enter
	clr	bp				; assume same

	test	ax, DISK_IS_STD_PATH_MASK	; src a standard path?
	jnz	axIsStdPath			; yes
	xchg	ax, dx				; ax <- dest, dx <- src
	test	ax, DISK_IS_STD_PATH_MASK	; dest a standard path?
	jnz	axIsStdPath			; yes

	cmp	dx, ax				; same/diff disk?
	je	done				; yes
setCopy:
	dec	bp				; different
done:
	tst	bp
	.leave
	ret

axIsStdPath:
	test	dx, DISK_IS_STD_PATH_MASK	; other handle also s.p.?
	jnz	done				; yes => move
NOFXIP<	segmov	es, dgroup, ax						>
FXIP<	mov	dx, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, dx							>
	cmp	dx, es:[geosDiskHandle]		; other handle is system disk?
	je	done				; yes => move
	jmp	setCopy				; else copy
CompareDiskHandles endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateNewFolderWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create new folder window to show folder contents

CALLED BY:	InheritAndCreateNewFolderWindow,
		DesktopOpenApplication

PASS:		dx:bp - folder's pathname
		bx - disk handle for folder window
		ds - assumed to be pointing to object block
			(MF_FIXUP_DS performed)
		es:ax - FolderRecord of folder to open (for NewDesk only)
			if ax == NIL then no FolderRecord
		ds:si - FolderClass instance data
			only if ax != NIL

		(NewDesk):
		cx - NewDeskObjectType			

RETURN:		carry clear if new Folder Window created
		carry set if not
			ax - 0 if existing Folder Window brought to front
			ax - ERROR_TOO_MANY_FOLDER_WINDOWS
			ax - NIL if other error
		(preserves ds, si)

		^lcx:dx - OD of new FolderClass object created

DESTROYED:	bx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/24/89		Initial version
	brianc	8/30/89		changed folder windows to GenDisplay

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateNewFolderWindow	proc	far
	uses	di
	.enter

GM<	clr	di		; GMGR has no normal setup behavior	>
ND<	mov	di, offset NDFolderSetup				>
	call	CreateFolderWindowCommon

	; On a network, if this machine has one of its CWDs
	; set to a common directory, it's possible that the directory
	; will be nuked by another user, in which case NETX drops that
	; drive entirely, causing all kinds of problems.  Doing a
	; FilePopDir doesn't solve this, as it doesn't actually
	; communicate that we no longer need that directory to NETX
	; (maybe it should).  The only fix is to set the CWD to
	; something else, which is a total hack, and is certainly only
	; going to solve the problem in a very small number of cases,
	; but this case is probably the only one the testers will
	; test, so here it is.   Note that this causes a performance
	; penalty for the opening of every folder, but it's rather
	; small. 

BA <	mov	ax, SP_TOP				>
BA <	call	FileSetStandardPath			>


	.leave
	ret
CreateNewFolderWindow	endp



if _GMGR
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateMaxFolderWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up and calls CreateFolderWindowCommon with the
		call back routine MaximizeWindow, which puts up the 
		window in Full Screen mode, not overlapping mode.

CALLED BY:	InitSetFolderDispOpts, ...

PASS:		dx:bp - Pathname at which to create new folder
		bx - disk handle for folder window
		ds - assumed to be pointing to object block
			(MF_FIXUP_DS performed)
		

RETURN:		^lcx:dx - OD of new folder object

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/23/92   	added header 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateMaxFolderWindow	proc	far
	uses	di
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dxbp					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	mov	di, offset MaximizeWindow
	call	CreateFolderWindowCommon
	.leave
	ret
CreateMaxFolderWindow	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateFolderWindowCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to create a folder window

CALLED BY:	CreateNewFolderWindow, CreateMaxFolderWindow

PASS:		dx:bp - Pathname at which to create new folder
		bx - disk handle for folder 
		ds - assumed to be pointing to object block
			(MF_FIXUP_DS performed)
		di - callback routine.
		es:ax - FolderRecord of folder to open (for NewDesk only)
			if ax == NIL then no FolderRecord
		ds:si - FolderClass instance data
			only if ax != NIL

		(NewDesk):
		cx - NewDeskObjectType of new folder

RETURN:		^lcx:dx - OD of new folder object

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/13/92   	added header 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateFolderWindowCommon	proc near

	uses	si

	xchg	dx, bp

	pathname		local	fptr	push	bp, dx
	diskHandle		local	word	push	bx
	callback		local	nptr	push	di
ND<	objectType		local	NewDeskObjectType push cx 	>
ND<	folderRecord		local	fptr	push	es, ax		>
ND<	containingFolder	local	fptr	push	ds, si		>
ND<	iconBounds		local	Rectangle			>
	windowBlock		local	hptr
	folderBlock		local	hptr

	.enter

if _NEWDESK

	ForceRef	folderRecord		; These locals are used in
	ForceRef	containingFolder	;   a called routine that
	ForceRef	iconBounds		;   inherits this stack

; Make sure the passed NewDeskObjectType is valid, since it was added
; as an afterthought...


EC <	test	cx, 1				>
EC <	ERROR_NZ 	DESKTOP_FATAL_ERROR	>
EC <	cmp	cx, -OFFSET_FOR_WOT_TABLES	>
EC <	ERROR_L		DESKTOP_FATAL_ERROR	>
EC <	cmp	cx, NewDeskObjectType		>
EC <	ERROR_G		DESKTOP_FATAL_ERROR	>

endif	; _NEWDESK


	call	ShowHourglass

	;
	; check if we can open a window for this folder
	; (can't if we have MAX_NUM_FOLDER_WINDOWS opened already or
	;  if a window for this folder is already opened.  In the latter
	;  case, just bring it to the front.)
	;
	mov	cx, bx				; cx = disk handle
	mov	si, dx		
	mov	dx, ss:[pathname].segment	; dx:si - pathname
ND<	mov	ax, ss:[objectType]			>
	call	CheckFolderWindow
	LONG jc	exit				; if can't open, exit

	;
	; create a new folder object for the window
	; In GeoManager this means copying the normal FolderObject but
	; in the NewDesk and BA cases it means copying different templates
	; of FolderObject subclasses according to which folder we are
	; opening (determined by the path).  All folder objects must be the
	; only (or at least the first) object in their template resource so
	; the offset "FolderObjectTemplate:FolderObject" is the same handle
	; for all the different subclasses (i.e. no offset table needed)
	; Since the FolderWindow (a DisplayControl in GeoManager and a primary
	; in NewDesk) and associated view are the first two objects in their
	; object template blocks the offsets for these objects can be reached
	; by using FolderWindow and FolderView.  In comments these will
	; be refered to as "common offsets" because the GeoManager offset
	; will be used to reference the chunk for any template.
	;

GM<	mov	bx, handle FolderObjectTemplate	; GMGR is always normal >

if _NEWDESK
	mov	si, ss:[objectType]

		CheckHack <segment FolderObjectTemplateTable eq @CurSeg>
	mov	bx, cs:[FolderObjectTemplateTable+OFFSET_FOR_WOT_TABLES][si]
	cmp	bx, 0				; if the block is 0, this is
	stc					;  a non-openable WOT
	LONG	je exit

	push	si				; NewDeskObjectType
endif		; if _NEWDESK

	clr	ax				; have current geode own block
	mov	cx, -1				; copy running thread
	call	ObjDuplicateResource
	mov	folderBlock, bx			; save folder object's block
	mov	si, FOLDER_OBJECT_OFFSET	; common offset

	;
	; create a new folder window
	;
GM<	mov	bx, handle FolderWindowTemplate >

if _NEWDESK
	pop	si				; NewDeskObjectType
	mov	bx, cs:[FolderWindowTemplateTable+OFFSET_FOR_WOT_TABLES][si]
endif	; NewDesk

	clr	ax				; have current geode own block
	mov	cx, -1				; copy running thread
	call	ObjDuplicateResource		; duplicate it
	mov	windowBlock, bx
	;
	; attach new folder object to new folder window via OD
	;	bx = folder window's block
	;
	mov	cx, folderBlock			; cx:dx = object to be output
	mov	dx, FOLDER_OBJECT_OFFSET	; common offset
						; bx:si = view to set output of

	;
	; Set the content of the view
	; ^lcx:dx - folder

	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	mov	si, FOLDER_VIEW_OFFSET ; common offset
	call	ObjMessageFixup

	;
	; Also, set the block's output, so that other objects in the window
	; block can send messages to the folder
	;

	mov	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
	call	ObjMessageFixup

	;
	; GeoManager has its folder windows built on the GenDisplay and
	; attaches  them under a GenDisplayControl.  It has a folder info
	; line in every window to show file sizes etc. and an updir button.
	;
if _GMGR
	;
	; add new folder window to display control
	;
	push	bp
	mov	cx, bx				; cx:dx = new folder window
	mov	dx, FOLDER_WINDOW_OFFSET
	mov	bx, handle FileSystemDisplayGroup	; bx:si = DC
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
	call	ObjMessageCallFixup
	pop	bp
	;
endif				; if _GMGR

	;
	; NewDesk has its folder windows built on the GenPrimary and
	; attaches them under the app.
	;
if _NEWDESK
	call	UtilBringUpFolderWindow
endif
	;
	; call folder object to initialize itself
	;
	mov	cx, windowBlock			; cx = folder window's block
						;	(pass to INIT_FOLDER)
	push	bp
	mov	bx, folderBlock			; ^lbx:si = new folder object
	mov	si, FOLDER_OBJECT_OFFSET
	mov	ax, MSG_INIT
	mov	bp, diskHandle			; bp = disk handle
	call	ObjMessageCallFixup
	pop	bp

	;
	; store new folder object into global table
	;

		call	SaveNewFolder

	;
	; Set folder's path
	;

		push	bp
		movdw	cxdx, pathname
		mov	bp, diskHandle
		mov	ax, MSG_FOLDER_SET_PATH
		call	ObjMessageCallFixup

if _NEWDESK
ifdef SMARTFOLDERS		; compilation flag, see local.mk

		pop	bp

	;
	; Set the primary's path.
	;

		push	bp
		push	bx, si
		movdw	cxdx, pathname
		mov	bx, windowBlock		  ; bx:si = new folder primary
		mov	si, FOLDER_WINDOW_OFFSET	; common offset
		mov	bp, diskHandle
		mov	ax, MSG_GEN_PATH_SET
		call	ObjMessageCallFixup
		pop	bx, si

endif 	; ifdef SMARTFOLDERS
endif	; if _NEWDESK

	;
	; call folder object to read directory contents
	;	bx:si = new folder object (still there)
	;

		mov	ax, MSG_SCAN
		call	ObjMessageCallFixup
		pop	bp

	;
	; local variable "pathname" is no longer valid!
	; (callback routines can't use it!)
	;

	mov	cx, windowBlock			; bx:si = new folder window
	mov	dx, FOLDER_WINDOW_OFFSET	; common offset
	mov	bx, folderBlock
	mov	si, FOLDER_OBJECT_OFFSET	; common offset

	mov	di, callback
	tst	di
	jz	noCallback
	call	di				; call the callback routine

noCallback:
	;
	; make new folder window usable
	;
	mov	bx, windowBlock			; bx:si = new folder window
	mov	si, FOLDER_WINDOW_OFFSET
	mov	dl, VUM_NOW			; udpate now
	mov	ax, MSG_GEN_SET_USABLE		; (also brings it up)
	call	ObjMessageCallFixupAndSaveBP

	mov	ax, MSG_FOLDER_SET_PRIMARY_MONIKER
	mov	bx, folderBlock			; bx:si = new folder object
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	call	ObjMessageCallFixup

	mov	ax, MSG_FOLDER_GET_STATE
	call	ObjMessageCallFixupAndSaveBP	; cx = FolderObjectStates
	test	cx, mask FOS_BOGUS		; will be closed b/c of error?
	stc					; assume so
	mov	ax, -1				; AX<>0 -> don't close current
						;	Folder Window
	jnz	done				; yes, don't bring up visually

if _GMGR			; Display Control stuff
if CLOSE_IN_OVERLAP
	call	GetDCMaxState			; cx = TRUE if maximized
	push	cx
	mov	ax, MSG_DESKDISPLAY_SET_OPEN_STATE
	call	ObjMessageCallFixupAndSaveBP
	;
	; before closing old Folder Window, register the new Folder Window
	; in the LRU table
	;
	mov	bx, windowBlock			; bx:si = Folder Window
	mov	si, FOLDER_WINDOW_OFFSET	; common offset
	call	UpdateWindowLRUStatus
	;
	; close oldest
	;
	pop	cx				; cx = TRUE if maximized
	cmp	cx, TRUE
	jne	noClose				; don't close if overlapping
	call	CloseOldestWindowIfPossible
noClose:
endif		; if CLOSE_IN_OVERLAP
endif		; if _GMGR
	clr	ax				; no error
	jmp	exit
done:
	cmp	ax, -1				; error creating new Folder
						;	Window?
	jne	exit				; nope, finis
	mov	bx, folderBlock			; bx:si = new folder object
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	mov	ax, MSG_CLOSE_FOR_BAD_CREATE
	push	bp
	call	ObjMessageForce			; destroy Folder Object
	pop	bp
	mov	ax, NIL				; signal real error
exit:
if _GMGR
	; See if we excceded the max files allowed
	mov	cx, ss:[maxNumFiles]
	mov	dx, ss:[numFiles]

	; zero means no limit
	jcxz	okToHaveOpened

	cmp	cx, dx
	jge	okToHaveOpened

	; close oldest window(s) until either we have enough space or
	; all but the newest one are closed

	mov	bx, folderBlock
	push	bp
	call	CheckMaxNumFiles
	pop	bp

okToHaveOpened:
endif	; if _GMGR

	; Return folder's OD to caller
	mov	cx, folderBlock
	mov	dx, FOLDER_OBJECT_OFFSET	; common offset

	call	HideHourglass

	.leave
	ret
CreateFolderWindowCommon	endp


if _NEWDESK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilBringUpFolderWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the UI objects for this folder (NewDesk only)

CALLED BY:	CreateFolderWindowCommon

PASS:		bx - handle of UI objects
		ds - object block to be fixed up

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilBringUpFolderWindow	proc near
	uses	ax,bx,cx,dx,di,si,bp

	.enter

BA <	call	UtilBringUpEntryLevelFolder				>

	;
	; Add the child LAST so that setting it usable doesn't cause
	; all the other children of the app object to be loaded.
	;

	mov	cx, bx
	mov	dx, FOLDER_WINDOW_OFFSET	; common offset
	mov	bx, handle GenAppInterface
	mov	si, offset Desktop
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, mask CCF_MARK_DIRTY or CCO_FIRST	; don't use CCO_LAST
							; because if an older
							; sibling is marked
							; ignore dirty, our
							; linkage be get
							; screwed up when we
							; restore from state
	call	ObjMessageCallFixup

	.leave
	ret

UtilBringUpFolderWindow	endp


;-----------------------------------------------------------------------------
; For each NewDeskObjectType, there are 2 blocks of UI that are
; duplicated -- one for each thread.  Below are tables that match the
; NewDeskObjectType to the handle of the template block to be
; duplicated.  Note that the offsets of the Folder and GenView objects
; within each template must be identical.
;
;	The tables are laid out with the BA items first, as the BA
; enumerated types start from a fixed negative such that they end at -2.
; The NewDesk items begin with 0 and grow up from there.  This was done to
; allow either NewDesk or BA to gain WOT's without changing any of the
; existing WOT's stored on disk in links.  When adding BA WOT's, add them
; to the negative end of the list, when adding NewDesk WOT's add them to
; the end of the enumerated type.
;-----------------------------------------------------------------------------
 
;
; This is the table of template folder objects.  There must be one for
; each NewDeskObjectType, and the offsets of each must be the same.
;

FolderObjectTemplateTable	label	word
if _NEWDESKBA
	word	handle	BAStudentUtilityObject		; WOT_STUDENT_UTILITY
	word	handle	BAOfficeCommonObject		; WOT_OFFICE_COMMON
	word	handle	BATeacherCommonObject		; WOT_TEACHER_COMMON
	word	handle	BAOfficeHomeObject		; WOT_OFFICE_HOME
	word	handle	BAStudentCourseObject		; WOT_STUDENT_COURSE
	word	handle	BAStudentHomeObject		; WOT_STUDENT_HOME
	word	0					; WOT_GEOS_COURSEWARE
	word	0					; WOT_DOS_COURSEWARE
	word	handle	BAOfficeAppListObject		; WOT_OFFICEAPP_LIST
	word	handle	BASpecialUtilitiesListObject	; WOT_SPECIALS_LIST
	word	handle	BACoursewareListObject		; WOT_COURSEWARE_LIST
	word	handle	BAPeopleListObject		; WOT_PEOPLE_LIST
	word	handle	BAStudentClassesObject		; WOT_STUDENT_CLASSES
	word	handle	BAStudentHomeTViewObject	; WOT_STUDENT_HOME_TVIEW
	word	handle	BATeacherCourseObject		; WOT_TEACHER_COURSE
	word	handle	BARosterObject			; WOT_ROSTER
	word	handle	BATeacherClassesObject		; WOT_TEACHER_CLASSES
	word	handle	BATeacherHomeObject		; WOT_TEACHER_HOME
endif		; if _NEWDESKBA
	word	handle	NDFolderObject			; WOT_FOLDER
	word	handle	NDDesktopFolderObject		; WOT_DESKTOP
	word	0					; WOT_PRINTER
	word	handle	NDWastebasketObject		; WOT_WASTEBASKET
if 1
	word	handle	NDFolderObject			; WOT_DRIVE
else
	word	handle	NDDriveObject			; WOT_DRIVE
endif
	word	0					; WOT_DOCUMENT
	word	0					; WOT_EXECUTABLE
	word	0					; WOT_HELP
	word	0					; WOT_LOGOUT
	word	handle	NDSystemFolderObject		; WOT_SYSTEM_FOLDER

.assert (($ - FolderObjectTemplateTable) eq			\
	 (NewDeskObjectType + OFFSET_FOR_WOT_TABLES))

.assert (offset NDFolderObject eq FOLDER_OBJECT_OFFSET)
.assert (offset NDSystemFolderObject eq FOLDER_OBJECT_OFFSET)
.assert (offset NDDesktopFolderObject eq FOLDER_OBJECT_OFFSET)
.assert (offset NDWastebasketObject eq FOLDER_OBJECT_OFFSET)
.assert (offset NDDriveObject eq FOLDER_OBJECT_OFFSET)
if _NEWDESKBA
.assert	(offset BATeacherHomeObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BATeacherClassesObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BARosterObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BATeacherCourseObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BAStudentHomeTViewObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BAStudentClassesObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BAPeopleListObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BACoursewareListObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BASpecialUtilitiesListObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BAOfficeAppListObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BAOfficeCommonObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BATeacherCommonObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BAOfficeHomeObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BAStudentCourseObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BAStudentHomeObject eq FOLDER_OBJECT_OFFSET)
.assert (offset BAStudentUtilityObject eq FOLDER_OBJECT_OFFSET)
endif		; if _NEWDESKBA


; This is the  table of UI resources for each folder block.  There
; must be one for each NewDeskObjectType, and the offsets of each must
; be the same.  The GenViews are asserted to have the same offsets --
; the same must be true for the primaries (but no .assert is made here
; -- it should be, though...)
;

FolderWindowTemplateTable	label	hptr

if _NEWDESKBA
hptr	handle	BAStudentUtilityView,		; WOT_STUDENT_UTILITY
	handle	BAOfficeCommonView,		; WOT_OFFICE_COMMON
	handle	BATeacherCommonView,		; WOT_TEACHER_COMMON
	handle	BAOfficeHomeView,		; WOT_OFFICE_HOME
	handle	BAStudentCourseView,		; WOT_STUDENT_COURSE
	handle	BAStudentHomeView,		; WOT_STUDENT_HOME
	0,					; WOT_GEOS_COURSEWARE
	0,					; WOT_DOS_COURSEWARE
	handle	BAOfficeAppListView,		; WOT_OFFICEAPP_LIST
	handle	BASpecialUtilitiesListView,	; WOT_SPECIALS_LIST
	handle	BACoursewareListView,		; WOT_COURSEWARE_LIST
	handle	BAPeopleListView,		; WOT_PEOPLE_LIST
	handle	BAStudentClassesView,		; WOT_STUDENT_CLASSES
	handle	BAStudentHomeTViewView,		; WOT_STUDENT_HOME_TVIEW
	handle	BATeacherCourseView,		; WOT_TEACHER_COURSE
	handle	BARosterView,			; WOT_ROSTER
	handle	BATeacherClassesView,		; WOT_TEACHER_CLASSES
	handle	BATeacherHomeView		; WOT_TEACHER_HOME
endif		; if _NEWDESKBA

hptr	handle	NDFolderView,		; WOT_FOLDER
	handle	NDDesktopFolderView,	; WOT_DESKTOP
	0,				; WOT_PRINTER
	handle	NDWastebasketView,	; WOT_WASTEBASKET
if 1
	handle	NDFolderView,		; WOT_DRIVE
else
	handle	NDDriveView,		; WOT_DRIVE
endif
	0,				; WOT_DOCUMENT
	0,				; WOT_EXECUTABLE
	0,				; WOT_HELP
	0,				; WOT_LOGOUT
	handle	NDFolderView		; WOT_SYSTEM_FOLDER

.assert (($ - FolderWindowTemplateTable) eq			\
	 (NewDeskObjectType + OFFSET_FOR_WOT_TABLES))	; table length

.assert (offset NDFolderView eq FOLDER_VIEW_OFFSET)
.assert (offset NDDesktopFolderView eq FOLDER_VIEW_OFFSET)
.assert (offset NDWastebasketView eq FOLDER_VIEW_OFFSET)
.assert (offset NDDriveView eq FOLDER_VIEW_OFFSET)
if _NEWDESKBA
.assert	(offset BATeacherHomeView eq FOLDER_VIEW_OFFSET)
.assert (offset BATeacherClassesView eq FOLDER_VIEW_OFFSET)
.assert (offset BARosterView eq FOLDER_VIEW_OFFSET)
.assert (offset BATeacherCourseView eq FOLDER_VIEW_OFFSET)
.assert (offset BAStudentHomeTViewView eq FOLDER_VIEW_OFFSET)
.assert (offset BAStudentClassesView eq FOLDER_VIEW_OFFSET)
.assert (offset BAPeopleListView eq FOLDER_VIEW_OFFSET)
.assert (offset BACoursewareListView eq FOLDER_VIEW_OFFSET)
.assert (offset BASpecialUtilitiesListView eq FOLDER_VIEW_OFFSET)
.assert (offset BAOfficeAppListView eq FOLDER_VIEW_OFFSET)
.assert (offset BAOfficeCommonView eq FOLDER_VIEW_OFFSET)
.assert (offset BATeacherCommonView eq FOLDER_VIEW_OFFSET)
.assert (offset BAOfficeHomeView eq FOLDER_VIEW_OFFSET)
.assert (offset BAStudentCourseView eq FOLDER_VIEW_OFFSET)
.assert (offset BAStudentHomeView eq FOLDER_VIEW_OFFSET)
.assert (offset BAStudentUtilityView eq FOLDER_VIEW_OFFSET)
endif		; if _NEWDESKBA

endif	; NEWDESK

if _GMGR
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaximizeWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a folder window Full Sized (as opposed to
		Overlapping).

CALLED BY:	CreateFolderWindowCommon

PASS:		^lbx:si	folder object
		^lcx:dx	folder window

RETURN:		none

DESTROYED:	???

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/23/92   	added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MaximizeWindow	proc	near
	push	bp
	push	cx, dx				; save Folder Window
	mov	bx, segment GenDisplayGroupClass
	mov	si, offset GenDisplayGroupClass
	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event handle
	pop	bx, si
	mov	ax, MSG_GEN_CALL_PARENT
	call	ObjMessageCallFixup
	pop	bp
	ret
MaximizeWindow	endp
endif		; if _GMGR


if _NEWDESK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to itself to setup any special behavior
		dealing with the FolderWindow and FolderObject.  This
		is basically a hook to allow subclasses special setup
		circumstances.

CALLED BY:	CreateFolderWindowCommon

PASS:		^lbx:si - NDFolderObject or subclass
		^lcx:dx - NDFolderWindow or subclass

RETURN:		none

DESTROYED:	all but bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderSetup	proc	near
	uses	bp
	.enter

	call	NDFolderStoreIconBounds

BA<	mov	ax, MSG_BA_CONSTRAIN_DROP_DOWN_MENU	>
BA<	call	ObjMessageCallFixup			>

	mov	ax, MSG_ND_SET_CONTROL_BUTTON_MONIKER
	call	ObjMessageCallFixup

	mov	ax, MSG_ND_FOLDER_SETUP		; hook for subclasses.
	call	ObjMessageCallFixup

	.leave
	ret
NDFolderSetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderStoreIconBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the icon bounds of a folder so when it is brought
		on screen its zoom lines come from the right place.

CALLED BY:	NDFolderSetup

PASS:		none
RETURN:		none

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/15/92	Store icon bounds for zoom-lines
	dlitwin	7/31/92		broke out from NDFolderSetup

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderStoreIconBounds	proc	near
	class	DeskVisClass
	uses	bx, si, cx, dx
	.enter	inherit CreateFolderWindowCommon

	cmp	ss:[folderRecord].offset, NIL
	jne	getIconBounds

noIconBounds:
	mov	ax, PARAM_0
	mov	ss:[iconBounds].R_left, ax
	mov	ss:[iconBounds].R_top, ax
	mov	ss:[iconBounds].R_right, ax
	mov	ss:[iconBounds].R_bottom, ax
	jmp	short setIconBounds

getIconBounds:
	push	ds
	lds	si, ss:[containingFolder]
	mov	di, ds:[si].DVI_window
	pop	ds
	tst	di
	jz	noIconBounds

	call	WinGetWinScreenBounds

	les	di, ss:[folderRecord]
	mov	cx, es:[di].FR_iconBounds.R_left
	add	cx, ax
	mov	ss:[iconBounds].R_left, cx
	mov	dx, es:[di].FR_iconBounds.R_top
	add	dx, bx
	mov	ss:[iconBounds].R_top, dx
	add	ax, es:[di].FR_iconBounds.R_right
	mov	ss:[iconBounds].R_right, ax
	add	bx, es:[di].FR_iconBounds.R_bottom
	mov	ss:[iconBounds].R_bottom, bx

setIconBounds:
	mov	ax, MSG_ND_PRIMARY_INITIALIZE
	mov	bx, ss:[windowBlock]
	mov	si, FOLDER_WINDOW_OFFSET	; bx:si = new folder window
	mov	cx, ss
	lea	dx, ss:[iconBounds]
	call	ObjMessageCallFixup

ifdef SMARTFOLDERS
	;
	; now check if we loaded display options from dir info file
	;
	push	bp
	sub	sp, size GetVarDataParams + size NDPSavedDisplayOptions
	mov	bp, sp
	mov	ss:[bp].GVDP_buffer.segment, ss
	lea	ax, ss:[bp][(size GetVarDataParams)]
	mov	ss:[bp].GVDP_buffer.offset, ax
	mov	ss:[bp].GVDP_bufferSize, size NDPSavedDisplayOptions
	mov	ss:[bp].GVDP_dataType, ATTR_ND_PRIMARY_SAVED_DISPLAY_OPTIONS
	mov	ax, MSG_META_GET_VAR_DATA
	mov	dx, size GetVarDataParams
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	push	bp
	call	ObjMessage
	pop	bp
	mov	cl, ss:[bp][(size GetVarDataParams)].NDPSDO_types
	mov	ch, ss:[bp][(size GetVarDataParams)].NDPSDO_attrs
	mov	dl, ss:[bp][(size GetVarDataParams)].NDPSDO_sort
	mov	dh, ss:[bp][(size GetVarDataParams)].NDPSDO_mode
	add	sp, size GetVarDataParams + size NDPSavedDisplayOptions
	pop	bp
	cmp	ax, size NDPSavedDisplayOptions
	jne	noOptions
	;
	; sanity check the options
	;
	tst	dl				; must have sort mode
	jz	noOptions
	tst	dh				; must have display mode
	jz	noOptions
	mov	bx, ss:[folderBlock]
	mov	si, FOLDER_OBJECT_OFFSET
	mov	ax, MSG_RESTORE_DISPLAY_OPTIONS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	mov	ax, MSG_REDRAW
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
noOptions:
endif

	.leave
	ret
NDFolderStoreIconBounds	endp
endif		; if _NEWDESK


if _GMGR
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDCMaxState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns if the state of the the document control object
		for the GeoManagers folder windows is maximized or not.

CALLED BY:	

PASS:		none
RETURN:		cx =	TRUE if it is in maximized state
			FALSE if it is not in maximized state

DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	12/30/92	added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDCMaxState	proc	near
	push	bx, si				; save new folder window
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED
	call	ObjMessageCallFixupAndSaveBP	; carry set if maximized
	mov	cx, FALSE			; assume not maximized
	jnc	done
	mov	cx, TRUE			; maximized
done:
	pop	bx, si				; bx:si = new folder window
	ret
GetDCMaxState	endp
endif		; if _GMGR



ObjMessageCallFixupAndSaveBP	proc	near
	push	bp
	call	ObjMessageCallFixup
	pop	bp
	ret
ObjMessageCallFixupAndSaveBP	endp


if _GMGR
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseOldestWindowIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	closes oldest Folder Window or Tree Window, if possible

CALLED BY:	EXTERNAL
			CreateFolderWindowCommon (opening new Folder Window)
			TreeWindowCommon (opening Tree Window)

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseOldestWindowIfPossible	proc	far
	uses	bp
	.enter

	mov	ax, MSG_GEN_COUNT_CHILDREN
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	call	ObjMessageCallFixup
	cmp	dl, ss:[lruNumber]		; initilized by .ini file
	jbe	done				; can't be anything to close

	mov	ss:[oldestUsage], 0xffff
	mov	ss:[oldestWindow].handle, 0
	mov	ss:[closableCount], 0
	;
	; ask all Windows to check if they are the one to be axed
	; (ask via DisplayControl)
	;
;still set from above
;	mov	bx, handle FileSystemDisplayGroup
;	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_DESKDG_CLOSE_OLDEST_CHECK
	call	ObjMessageCallFixup
	jnc	done				; nothing found to close
	;
	; axe oldest Window, if any
	;
	mov	bx, ss:[oldestWindow].handle
	tst	bx				; any?
	je	done				; nope
	mov	si, ss:[oldestWindow].offset	; bx:si = Window to close
	mov	ax, MSG_GEN_DISPLAY_CLOSE
	call	ObjMessageCallFixup
done:
	.leave
	ret
CloseOldestWindowIfPossible	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseOldestWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	closes oldest window

CALLED BY:	CheckMaxNumFiles
PASS:		bx - newest folder's handle
RETURN:		carry set - if we're tryimg to close the window that
			we just opened
		carry clear - if we closed an old window successfully
DESTROYED:	evrything, but cx
SIDE EFFECTS:	ss:[numFiles] gets updated	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseOldestWindow	proc	far
	uses	cx
	.enter

	;
	; save handle of newest folder
	;
	push	bx

	;
	; erase all memory of previuosly oldestWindow
	;
	mov	ss:[oldestUsage], 0xffff
	mov	ss:[oldestWindow].handle, 0
	mov	ss:[closableCount], 0
	;
	; ask all Windows to check if they are the one to be axed
	; (ask via DisplayControl)
	;
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_DESKDG_CLOSE_OLDEST
	call	ObjMessageCallFixup
	;
	; axe oldest Window, if any
	;
	mov	bx, ss:[oldestWindow].handle
	tst	bx				; any?

	; restore current folder handle
	pop	bp

	je	doneNoMoreClose			; nope

	; save again
	push	bp

	mov	si, offset FolderWindowTemplate:FolderView
	;
	; get the folder (which is the content) of the display
	;
	mov	ax, MSG_GEN_VIEW_GET_CONTENT
	call	ObjMessageCallFixup

	; restore again and see if we're trying to close the one we
	; just opened
	pop	bp
	cmp	bp, cx
	je	doneNoMoreClose

	; close the folder that we found to be the oldest
	movdw	bxsi, cxdx
	mov	ax, MSG_FOLDER_CLOSE
	call	ObjMessageCallFixup

	clc
exit:
	.leave
	ret

doneNoMoreClose:
	stc
	jmp	exit

CloseOldestWindow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWindowLRUStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update usage of window in LRU table

CALLED BY:	EXTERNAL
			FolderGainTarget, TreeGainTarget
			CreateFolderWindowCommon
			TreeWindowCommon

PASS:		bx:si = Folder Window or Tree Window (GenDisplay)
		ds	= segment that can be fixed up

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateWindowLRUStatus	proc	far
	uses	ax, cx, dx, di, bp
	.enter
	inc	ss:[windowUsageCount]
	mov	cx, ss:[windowUsageCount]
	mov	ax, MSG_DESKDISPLAY_SET_USAGE
	call	ObjMessageCallFixup
	.leave
	ret
UpdateWindowLRUStatus	endp
endif		; if _GMGR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFolderWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks if we can open another window for this folder and
		if there is already an open window for this folder; in the
		latter case, just bring that window to the front

CALLED BY:	CreateNewFolderWindow

PASS:		dx:si - folder's pathname
		cx - disk handle of folder
		ds - fixupable segment
	ND<	ax = object type	>

RETURN:		carry	- set if window CANNOT be created
				ax = 0 if brought to front
				otherwise handles the errors:
				ax = ERROR_TOO_MANY_FOLDER_WINDOWS
				ax = ERROR_LINK_TARGET_GONE
				ax = ERROR_DRIVE_LINK_TARGET_GONE

		carry	- clear if window CAN be created

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Could optimize opening of folders by returning actual path (from
		FindFolderWindow) to the caller.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFolderWindow	proc	near
	uses	ax, bx, cx, dx, si, di, bp, ds, es
	.enter

	mov	bp, si				; dx:bp = pathname
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	FindFolderWindow		; check if already opened
	; For NewDesk, we want to allow multiple windows in the same folder
if _GMGR
	jnc	notFound			; if not, check # windows
	;
	; If an error occurred for a student, put up error about generic
	; students.  If for a drive, put up message about drives.  Otherwise
	; we've got a link whose target has dissappeared.
	;
BA<	cmp	ax, WOT_STUDENT_HOME_TVIEW		>
BA<	je	isStudent				>
BA<	cmp	ax, WOT_STUDENT_UTILITY			>
BA<	jne	checkOtherTypes				>
BA<isStudent:						>
BA<	mov	ax, ERROR_GENERIC_HOME_NOT_OPENABLE	>
BA<	jmp	gotErrorMsg				>
BA<checkOtherTypes:					>
ND<	cmp	ax, WOT_DRIVE				>
	mov	ax, ERROR_LINK_TARGET_GONE
ND<	jne	gotErrorMsg				>
ND<	mov	ax, ERROR_DRIVE_LINK_TARGET_GONE	>
ND<gotErrorMsg:						>
	tst	bx
	jz	errorButCheckSPLink

	;
	; found matching folder window, bring to front
	;	bx = folder window block
	;
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	mov	ax, MSG_FOLDER_BRING_TO_FRONT
	call	ObjMessageCallFixup		; tell window to come to front
						;	via the FolderObject
	clr	ax				; no error
	jmp	short noCreate			; brought-to-front,
						; don't create

errorButCheckSPLink:
	;
	; If we have a ERROR_LINK_TARGET_GONE error, but if the path is a
	; StandardPath, CD'ing to that directory will create it (the kernel
	; ensures this).  Pretend we didn't find the folder window if this
	; is the case - brianc 6/18/93
	;	dx:si = path
	;	cx = disk handle
	;
	cmp	ax, ERROR_LINK_TARGET_GONE
	jne	error
	push	es, di, bx, ax
	movdw	esdi, dxsi
	mov	bx, cx
	call	FileParseStandardPath
	test	ax, DISK_IS_STD_PATH_MASK	; (clears carry)
	jz	popAndErrorNC			; is not SP, return error
SBCS <	cmp	{byte} es:[di], 0		; no tail?		>
DBCS <	cmp	{wchar} es:[di], 0		; no tail?		>
	stc					; assume no tail, say not found
	je	popAndErrorNC			; no tail, fall thru to notFound
	clc					; else, return error
popAndErrorNC:
	pop	es, di, bx, ax
	jnc	error

notFound:
endif	; _GMGR
	;
	; Removed call to CheckIfLinkIsValid.  Most links are, so the
	; time we waste checking isn't worth it.  If the link isn't
	; valid, the folder will go away soon enough...
	;

	;
	; folder window isn't open yet, check if we can open any
	; more folder windows without exceeding the max
	;

if _GMGR
	clr	ax
	mov	al, ss:[lruNumber]

	; maxNumFolderWindows is the maximum for overlapping windows,
	; check if we're overlapping or maximized

	tst	ss:[displayIsMaximized]
	jz	isMaximized

	mov	ax, ss:[maxNumFolderWindows]

isMaximized:
	cmp	ss:[numFolderWindows], ax
	jl	canCreate			; if so, signal can create

	call	CloseOldestWindow
	jnc	canCreate

else	; if _GMGR

	cmp	ss:[numFolderWindows], MAX_NUM_FOLDER_WINDOWS
	jne	canCreate			; if so, signal can create

endif	; if _GMGR
	mov	ax, ERROR_TOO_MANY_FOLDER_WINDOWS	; else, report error
	cmp	ss:[doingMultiFileLaunch], TRUE	; need to check flag?
	jne	error				; nope, report error
	cmp	ss:[tooManyFoldersReported], TRUE	; already reported?
	je	noCreate			; yes, skip error box
	mov	ss:[tooManyFoldersReported], TRUE	; mark as reported

error:
	call	DesktopOKError			; preserves AX

noCreate:
	stc					; carry set =
						; no-create-window
	jmp	short done

canCreate:
	clc					; carry clear = can-create-win

done:
	call	ShellFreePathBuffer
	.leave
	ret
CheckFolderWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFolderWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds a folder given a path if one exists

CALLED BY:	INTERNAL
			CheckFolderWindow
			DesktopDriveToolInternal
			NewDeskGetDummyOrRealObject
			SendToOpenedOrDummy
			NDOpenDropDownIfFolderType

PASS:		dx:bp = pathname to find
		cx = disk handle to match
		di = MessageFlags for the call to the FolderClass
			don't set to FIXUP_DS if ds isn't an object block!
		ax = object type

RETURN:		carry set if found, or error
			bx = block of matching folder object
			(bx=0 if path does not exist)

		carry clear if not found
		es = segment of path buffer containing the actual path of dx:bp
			(buffer should be freed by caller)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	BA-ONLY HACK:  If the folder we're trying to open is of type
	WOT_STUDENT_HOME_TVIEW or WOT_STUDENT_UTILITY and is a link to
	\GENERICS, then return carry set and bx = 0.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/06/90	broken out from CheckFolderWindow
	dlitwin	10/10/92	Made di be passed message flags, because
				we don't necessarily want to always fixup ds.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindFolderWindow	proc	far
	uses	ax, cx, dx, si, bp, di

	.enter

	;
	; Construct the actual path to find 
	;

	push	di, ds, ax
	mov	ds, dx
	mov	si, bp
	mov	bx, cx
	clr	dx
	call	ShellAllocPathBuffer
	call	FileConstructActualPath
	mov	bp, di
	pop	di, ds, ax

	jc	error

BA<	cmp	ax, WOT_STUDENT_HOME_TVIEW	>
BA<	je	student				>
BA<	cmp	ax, WOT_STUDENT_UTILITY		>
BA<	jne	notStudent			>
BA<student:					>
BA<	call	CheckForGenericsLink		>
BA<	jz	error				>
BA<notStudent:					>
	mov	dx, es
	mov	cx, bx			; cx, dx:bp - path to find

	clr	si				; init index into table
checkNext:
						; bx = handle of opened window
	mov	bx, ss:[folderTrackingTable][si].FTE_folder.handle
	tst	bx				; check if window here
	jz	tryNext				; if not, don't check it
	mov	ax, MSG_FOLDER_CHECK_PATH	; compare dx:bp to
						; this folder's pathname
						; (also have cx = disk handle)

	push	si, di
	mov	si, ss:[folderTrackingTable][si].FTE_folder.chunk
	call	ObjMessage			; carry set if different
	pop	si, di				; retrieve table offset + flags
	jnc	foundOrError			; if match, return BX
	;
	; this window's pathname doesn't match, try to match next window
	;
tryNext:
	add	si, size FolderTrackingEntry	; move to next window
						; check if end of list
	cmp	si, MAX_NUM_FOLDER_WINDOWS * (size FolderTrackingEntry)
	jne	checkNext			; if not, go back to check next

	;
	; Not found -- clear carry
	;

	clc				
	jmp	done

foundOrError:
	stc					; indicate found
done:
	.leave
	ret

error:
	clr	bx
	jmp	foundOrError

FindFolderWindow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForGenericsLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed path is \GENERICS

CALLED BY:	FindFolderWindow
PASS:		es:bp = actual path of some folder
RETURN:		zero flag set if path is \GENERICS
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _NEWDESKBA
genericsPath	char	C_BACKSLASH, 'GENERICS', C_NULL

CheckForGenericsLink		proc	near
		uses	ds, si, cx, di
		.enter

		segmov	ds, cs
		mov	si, offset cs:[genericsPath]
		mov	di, bp
		clr	cx			; null terminated
		call	LocalCmpStrings

		.leave
		ret
CheckForGenericsLink		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save the OD of the new folder into a global table and 
		increment count of opened windows

CALLED BY:	INTERNAL
			CreateNewFolderWindow

PASS:		^lbx:si - Folder OD

RETURN:		preserves bx
		numFolderWindows incremented

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewFolder	proc	far
	uses	bp
	.enter
	clr	bp
checkNext:
						; check if this is empty spot
	tst	ss:[folderTrackingTable][bp].FTE_folder.handle
	jz	foundFree			; if so, use it

	add	bp, size FolderTrackingEntry	; move to next spot
EC <	cmp	bp, MAX_NUM_FOLDER_WINDOWS * (size FolderTrackingEntry)	>
EC <	ERROR_Z	FOLDER_TRACKING_TABLE_FULL				>

	jmp	checkNext
foundFree:
	inc	ss:[numFolderWindows]		; bump window count
						; save new block
	movdw	ss:[folderTrackingTable][bp].FTE_folder, bxsi
	mov	ss:[folderTrackingTable][bp].FTE_state, 0
	.leave
	ret
SaveNewFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitForWindowUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	prepare for usage of MarkWindowForUpdate/UpdateMarkedWindows

CALLED BY:	file operation routines

PASS:		nothing

RETURN:		sets up update variables

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitForWindowUpdate	proc	far
	mov	ss:[updateSrcDiskHandle], 0		; preserve flags
	mov	ss:[updateDestDiskHandle], 0
	mov	ss:[updateSrcDiskOpened], FALSE
	mov	ss:[updateDestDiskOpened], FALSE
	ret
InitForWindowUpdate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuspendFolders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend any folders affected by the operation about to be
		performed.

CALLED BY:	(EXTERNAL)
PASS:		ds	= FileQuickTransfer block
		current dir = destination
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	file-changes are batched

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SuspendFolders	proc	far
	uses	ax
	.enter
	mov	ax, SUSPEND_UPDATE_STRATEGY
	call	MarkWindowForUpdate
	.leave
	ret
SuspendFolders	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnsuspendFolders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsuspend any folders affected by the operation just
		performed.

CALLED BY:	(EXTERNAL)
PASS:		ds	= FileQuickTransfer block
		current dir = destination
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	file-changes are flushed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnsuspendFolders	proc	far
	uses	ax
	.enter
	pushf
	mov	ax, UNSUSPEND_UPDATE_STRATEGY
	call	MarkWindowForUpdate
	popf
	.leave
	ret
UnsuspendFolders	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkWindowForUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks passed path(s) against all open folder windows
			and marks the ones that need to be updated

CALLED BY:	INTERNAL
			DesktopEndRename
			DesktopEndDelete
			DesktopEndCreateDir
			DesktopEndMove
			DesktopEndCopy

PASS:		ax - flag for update strategy (FolderWindowUpdateFlags)
			mask FWUF_RESCAN_DEST - rescan folder containing
				file/directory specified by es:di
			mask FWUF_CLOSE_SOURCE - close all folders that are
					children of the directory specified
					by ds:dx
			mask FWUF_CLOSE_DEST - close all folders that are
					children of the directory specified
					by es:di
			mask FWUF_GREY_SOURCE_FILE - grey out source file
					in folder window to show file operation
					progress
			mask FWUF_REDRAW_SOURCE - redraw source folder window

		ds:si	= FileOperationInfoEntry containing
				pathname of renamed file/directory
				pathname of newly created directory
				pathname of deleted file/directory
				pathname of copied file
				pathname of moved file
		ds:0	= FileQuickTransferHeader


		es:di - destination of operation (in thread's current dir)
			name of new copy of file
			new name of moved file

RETURN:		appropriate folder windows marked in global folder window
		table.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (FWUF_RESCAN_SOURCE and/or FWUF_CLOSE_SOURCE)
			BuildCompletePath(ds:dx, source);
		if (FWUF_RESCAN_DEST and/or FWUF_CLOSE_DEST)
			BuildCompletePath(es:di, dest);
		if (FWUF_RESCAN_SOURCE)
			MarkForRescan(source);
		if (FWUF_REDRAW_SOURCE)
			MarkForRedraw(source);
		if (FWUF_GREY_SOURCE_FILE)
			GreySourceFile(source);
		if (FWUF_CLOSE_SOURCE)
			MarkChildrenForClose(source);
		if (FWUF_RESCAN_DEST)
			MarkForRescan(dest);
		if (FWUF_CLOSE_DEST)
			MarkChildrenForClose(dest);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkWindowForUpdate	proc	far

updateFlags	local	FolderWindowUpdateFlags	push	ax
updatePath	local	PathName


	uses	ax, bx, cx, dx, si, di, ds, es
	.enter

EC <	test	ax, not mask FolderWindowUpdateFlags			>
EC <	ERROR_NZ	BAD_MARK_WINDOW_FOR_UPDATE_FLAGS		>

	;
	; Load up registers for source path
	;
	test	ss:[updateFlags], mask FWUF_DS_IS_FQT_BLOCK
	jz	checkCurDirSrc 
	mov	ax, ds
	mov	bx, offset FQTH_pathname
	mov	cx, ds:[FQTH_diskHandle]
	jmp	handleSource

checkCurDirSrc:
	test	ss:[updateFlags], mask FWUF_CUR_DIR_HOLDS_SOURCE
	jz	checkFCNAsSrc
	
	push	ds, si
	segmov	ds, ss
	lea	si, ss:[updatePath]
	mov	cx, size updatePath
	call	FileGetCurrentPath
	mov	cx, bx			; cx <- disk handle
	mov	ax, ds
	mov	bx, si			; ax:bx <- path
	pop	ds, si
	jmp	handleSource

checkFCNAsSrc:
	; XXX: FILL THIS IN WHEN APPROPRIATE
	ERROR	DESKTOP_FATAL_ERROR

	;
	; Now perform whatever marking is appropriate with the source path
	; we've got.
	; 
handleSource:
	mov	ss:[updateSrcDiskHandle], cx

	test	ss:[updateFlags], mask FWUF_REDRAW_SOURCE
	jz	closeSource
	mov	dx, mask FTES_REDRAW
	call	MarkFoldersCommon

closeSource:
	test	ss:[updateFlags], mask FWUF_CLOSE_SOURCE
	jz	greySource
;closing is handled by file change notification
;	mov	dx, mask FTES_CLOSE
;	call	MarkFoldersCommon

greySource:
	test	ss:[updateFlags], mask FWUF_GREY_SOURCE_FILE
	jz	suspendSource
	call	GreySourceFile

suspendSource:
	test	ss:[updateFlags], mask FWUF_SUSPEND
	jz	unsuspendSource
;there is nothing to suspend - brianc 6/9/93
;	mov	dx, mask FTES_SUSPEND
;	call	MarkFoldersCommon

unsuspendSource:
	test	ss:[updateFlags], mask FWUF_UNSUSPEND
	jz	scanDest
; change to mark as suspended, to ensure unsuspend will happen when
; local standard path is created - brianc 6/9/93
if 0
;	mov	dx, mask FTES_UNSUSPEND
;	call	MarkFoldersCommon
else
	jmp	short handleUnsuspend
endif

scanDest:
	;
	; Any dest-related things?
	; 
	test	ss:[updateFlags], mask FWUF_CLOSE_DEST or \
			mask FWUF_SUSPEND or \
			mask FWUF_UNSUSPEND
	jz	done

EC <	test	ss:[updateFlags], mask FWUF_CUR_DIR_HOLDS_DEST			>
EC <	ERROR_Z	DESKTOP_FATAL_ERROR	; no other option yet		>

	;
	; Fetch current path for passing th marking routines
	; 
	push	ds, si
	segmov	ds, ss
	lea	si, ss:[updatePath]
	mov	cx, size updatePath
	call	FileGetCurrentPath
	mov	cx, bx
	mov	ax, ds
	mov	bx, si
	pop	ds, si
	mov	ss:[updateDestDiskHandle], cx

	test	ss:[updateFlags], mask FWUF_CLOSE_DEST
	jz	suspendDest

	mov	dx, mask FTES_CLOSE
	call	MarkFoldersCommon

suspendDest:
	test	ss:[updateFlags], mask FWUF_SUSPEND
	jz	unsuspendDest
;there is nothing to suspend - brianc 6/9/93
;	mov	dx, mask FTES_SUSPEND
;	call	MarkFoldersCommon

unsuspendDest:
; change to mark as suspended, to ensure unsuspend will happen when
; local standard path is created - brianc 6/9/93
if 0
	test	ss:[updateFlags], mask FWUF_UNSUSPEND
	jz	done
;	mov	dx, mask FTES_UNSUSPEND
;	call	MarkFoldersCommon
else
handleUnsuspend:
	;
	; loop through folders to unsuspend all suspended ones
	;
	clr	di				; start at the beginning...
checkLoop:
						; bx:si = folder obj
	movdw	bxsi, ss:[folderTrackingTable][di].FTE_folder
	tst	bx				; check if folder here
	jz	nextFolder			; if not, check next
	test	ss:[folderTrackingTable][di].FTE_state, mask FTES_SUSPEND
	jz	nextFolder			; not suspended, check next
	andnf	ss:[folderTrackingTable][di].FTE_state, not mask FTES_SUSPEND
	mov	ax, MSG_META_UNSUSPEND
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage			; else, queue an unsuspend
nextFolder:
	add	di, size FolderTrackingEntry
	cmp	di, (size FolderTrackingEntry) * MAX_NUM_FOLDER_WINDOWS
	jne	checkLoop			; if more, go back and check it
endif

done:
	.leave
	ret
MarkWindowForUpdate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkFoldersCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark all folders open to the given path

CALLED BY:	MarkWindowForUpdate
PASS:		dx	= FolderTrackingEntryState to set if
			  a folder is using the path
		cx	= disk handle of path to check
		ax:bx	= path to check
RETURN:		nothing

DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkFoldersCommon proc	near
	uses	bp, si, ax, bx, cx, es, di
	.enter

	call	ShellAllocPathBuffer		; es:di - buffer in
						; which to construct
						; actual path
	push	dx			; FTES
	mov	ds, ax
	mov	si, bx
	mov	bx, cx
	clr	dx
	call	FileConstructActualPath
	pop	ax			; FTES
	jc	exit

	mov	bp, di
	mov	dx, es
	mov	cx, bx			; cx, dx:bp - actual path

	clr	di				; start at the beginning...
checkLoop:
						; bx:si = folder obj
	movdw	bxsi, ss:[folderTrackingTable][di].FTE_folder
	tst	bx				; check if folder here
	jz	tryNextMarkerInAX		; if not, check next

	push	ax, di
	mov	ax, MSG_FOLDER_CHECK_PATH	; compare to this folder
	call	ObjMessageCall
	pop	bx, di
	jnc	markFolder			; match -- always mark

	test	bx, mask FTES_CLOSE
	jz	tryNext				; if not close, don't care
						;  about children
	tst	ax
	jnz	tryNext				; not a child, so don't mark

markFolder:
	test	bx, mask FTES_SUSPEND or mask FTES_UNSUSPEND
	jnz	actImmediately

	ornf	ss:[folderTrackingTable][di].FTE_state, bx

	test	bx, mask FTES_RESCAN or mask FTES_REDRAW
	jnz	exit				; exit, since only one window
						;	per folder
tryNext:
	mov_tr	ax, bx				; ax <- marking bit

tryNextMarkerInAX:
	add	di, size FolderTrackingEntry
	cmp	di, (size FolderTrackingEntry) * MAX_NUM_FOLDER_WINDOWS
	jne	checkLoop			; if more, go back and check it

exit:
	call	ShellFreePathBuffer
	.leave
	ret

actImmediately:
	;
	; Suspend happens right away, while unsuspend gets queued. Neither
	; modifies FTE_state. They also can only apply to one folder, so once
	; we've called the folder, we're done.
	; 
	test	bx, mask FTES_SUSPEND

; change to mark as suspended, to ensure unsuspend will happen when
; local standard path is created - brianc 6/9/93
EC <	ERROR_Z	DESKTOP_FATAL_ERROR					>
	test	ss:[folderTrackingTable][di].FTE_state, mask FTES_SUSPEND
	jnz	exit				; already suspended
	ornf	ss:[folderTrackingTable][di].FTE_state, mask FTES_SUSPEND

	mov	bx, ss:[folderTrackingTable][di].FTE_folder.handle
	mov	di, mask MF_CALL
	mov	ax, MSG_META_SUSPEND
; change to mark as suspended, to ensure unsuspend will happen when
; local standard path is created - brianc 6/9/93
;	jnz	haveMessage
;	mov	ax, MSG_META_UNSUSPEND
;	mov	di, mask MF_FORCE_QUEUE
;haveMessage:
	call	ObjMessage
	jmp	exit
MarkFoldersCommon endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GreySourceFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	greys out file icon in folder window to show progress in
		file operation

CALLED BY:	INTERNAL
			MarkWindowForUpdate

PASS:		bp	= FolderWinUpdateFlags
			if FWUF_DS_IS_FQT_BLOCK:
				ds:dx	= FileOperationInfoEntry of file
					  just processed
			if FWUF_CUR_DIR_HOLDS_SOURCE
				ds:dx	= name of file just processed
		ax:bx	= source path
		cx	= source disk handle

RETURN:		file in folder window grey'ed out

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GreySourceFile	proc	near

	uses	cx, dx, bp, si, es, di, bx, ax

	.enter

	mov	si, dx		; ds:si <- src name
		CheckHack <offset FOIE_name eq 0>

	push	ds, si

	mov_tr	dx, ax
	mov	bp, bx		; dx:bp <- path against which to compare
	;
	; search folderTrackingTable for Folder Window corresponding to
	; this pathname, if any
	;

	mov	ds, dx			; bx, ds:si - path
	mov	si, bp
	mov	bx, cx
	call	ShellAllocPathBuffer
	clr	dx
	call	FileConstructActualPath
	mov	dx, es			; cx, dx:bp - actual path
	mov	bp, di
	mov	cx, bx

	clr	di
searchLoop:
						; bx:si = folder obj
	movdw	bxsi, ss:[folderTrackingTable][di].FTE_folder
	tst	bx				; check if folder here
	jz	tryNext				; if not, check next
	mov	ax, MSG_FOLDER_CHECK_PATH	; compare to this folder
	push	di				;	window's pathname
	call	ObjMessageCall
	pop	di
	jc	tryNext				; if no match, try next

	;
	; found Folder Window for this pathname, now send filename to
	; associated Folder Object so it can do the grey'ing
	;	^lbx:si = Folder Object
	;	dx:bp = pathname
	;
	pop	dx, bp				; dx:bp <- file
	mov	ax, MSG_GREY_FILE
	call	ObjMessageCall			; wait for grey'ing to occur
	jmp	short exit			; done

tryNext:
	add	di, size FolderTrackingEntry
	cmp	di, (size FolderTrackingEntry) * MAX_NUM_FOLDER_WINDOWS
	jne	short searchLoop		; if more, go back and check it

	pop	ds, si				; restore FOIE
exit:
	call	ShellFreePathBuffer
	.leave
	ret
GreySourceFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateMarkedWindows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	updates the folder windows that are marked for rescan or
		for closing

CALLED BY:	INTERNAL
			DesktopEndRename
			DesktopEndDelete
			DesktopEndCreateDir
			DesktopEndMove
			DesktopEndCopy

PASS:		ss:[folderTrackingTable] - table of opened folder windows
		ss:[updateSrcDiskHandle]
		ss:[updateDestDiskHandle]
					- src and dest disk handles to update
						if no Folder Windows are
						actually marked for update
						(need to rescan free space)
						if 0, do nothing

RETURN:		marked windows updated

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
		go through all opened folder windows and check if
			they are marked for rescan or for close;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateMarkedWindows	proc	far
	uses	bp, di, bx, si, ax, ds
	.enter
	;
	; first,  update folder windows
	;
	clr	di				; init index into folder window
						;	table
UMW_loop:
						; bx:si = an open window
	movdw	bxsi, ss:[folderTrackingTable][di].FTE_folder
	tst	bx				; check if window here
	jz	UMW_checkNext			; if not, skip this one
	;
	; if this disk display in this Folder Window is involved in the
	;	file operation, flag that the disk's free space needs to
	;	be rescanned
	;
	mov	ax, ss:[folderTrackingTable][di].FTE_state
	call	SetExtraUpdateVars
	;
	; close this folder window, if so marked
	;
	test	ss:[folderTrackingTable][di].FTE_state, mask FTES_CLOSE
	jz	UMW_rescanCheck			; if not, check for rescan
	push	di				; save table offset
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	mov	ax, MSG_CLOSE_IF_GONE
	call	ObjMessageForce			; close it, clears entry from
						;	tracking table
						; queue this so other methods
						;	for the object are
						;	processed before it
						;	goes away
	pop	di				; retrieve table offset
	andnf	ss:[folderTrackingTable][di].FTE_state, not	\
				(mask FTES_CLOSE or mask FTES_RESCAN)
	jmp	short UMW_checkNext		; if closed, no rescan
	;
	; rescan this folder window, if so marked
	;
UMW_rescanCheck:
	test	ss:[folderTrackingTable][di].FTE_state, mask FTES_RESCAN
	jz	UMW_redrawCheck			; if not, check for redraw
	push	di				; save table offset
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	mov	ax, MSG_RESCAN
	call	ObjMessageCall			; rescan current directory
	mov	ax, MSG_REDRAW
	call	ObjMessageCall			; redraw the window
						; clear rescan flag
	pop	di				; retrieve table offset
	andnf	ss:[folderTrackingTable][di].FTE_state, \
			not (mask FTES_RESCAN or mask FTES_REDRAW)
	jmp	short UMW_checkNext		; if rescan, no need to redraw
	;
	; redraw this folder window, if so marked
	;
UMW_redrawCheck:
	test	ss:[folderTrackingTable][di].FTE_state, mask FTES_REDRAW
	jz	UMW_checkNext			; if not, check next
	push	di				; save table offset
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	mov	ax, MSG_REDRAW
	call	ObjMessageCall			; redraw the window
						; clear redraw flag
	pop	di				; retrieve table offset
	andnf	ss:[folderTrackingTable][di].FTE_state, not (mask FTES_REDRAW)
UMW_checkNext:
	add	di, size FolderTrackingEntry	; move to next window
						; check if end of list
	cmp	di, MAX_NUM_FOLDER_WINDOWS * (size FolderTrackingEntry)
	jne	UMW_loop			; if not, go back to check next

	.leave
	ret
UpdateMarkedWindows	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetExtraUpdateVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	???

CALLED BY:	UpdateMarkedWindows

PASS:		^lbx:si - FolderClass object
		ax	- FolderTrackingEntryFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/20/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetExtraUpdateVars	proc	near
	uses	ax, cx, dx, di, bp
	.enter
	sub	sp, size DiskInfoStruct
	mov	dx, ss
	mov	bp, sp
	push	ax				; save update flags
	push	bp				; save structure pointer
	mov	ax, MSG_GET_DISK_INFO
	call	ObjMessageCall			; get disk info for Folder Win.
						;  ax <- disk handle
	pop	bp				; ss:bp = DiskInfoStruct
	pop	cx				; cx = update flags
						; will be closed or rescanned?
	test	cx, mask FTES_CLOSE		; if Folder Window will be
	jnz	noEffect			;	closed, no effect
	test	cx, mask FTES_RESCAN
	jz	noScan				; nope
	;
	; since it's going to be rescanned, we don't need to do seperate
	; free-space scan --> clear disk handles to be free-space scanned
	;
	cmp	ax, ss:[updateSrcDiskHandle]	; is it source disk?
	jne	10$				; nope
	mov	ss:[updateSrcDiskHandle], 0	; yes, don't need extra update
10$:
	cmp	ax, ss:[updateDestDiskHandle]	; is it dest disk?
	jne	20$				; nope
	mov	ss:[updateDestDiskHandle], 0	; yes, don't need extra update
20$:
noScan:
	;
	; set flag saying that the src/dest disk handles have a Folder Window
	; opened on them (don't want to free-space scan disks involved in file
	; operation but don't have any Folder Windows opened on them)
	;
	cmp	ax, ss:[updateSrcDiskHandle]	; is it source disk?
	jne	30$				; nope
	mov	ss:[updateSrcDiskOpened], TRUE	; yes, flag disk valid
30$:
	cmp	ax, ss:[updateDestDiskHandle]	; is it dest disk?
	jne	40$				; nope
	mov	ss:[updateDestDiskOpened], TRUE	; yes, flag disk valid
40$:
noEffect:
	add	sp, size DiskInfoStruct
	.leave
	ret
SetExtraUpdateVars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BroadcastToFolderWindows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sends a message to all Folder objects

CALLED BY:	UTILITY

PASS:		ss:[folderTrackingTable] - table of opened folder windows
		ax, cx, dx, bp - message data
		di - MessageFlags for ObjMessage

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BroadcastToFolderWindows	proc	far
	uses	ax, bx, cx, dx, bp, si, es, di
	.enter
	test	di, mask MF_FIXUP_DS
	jnz	fixupDS
	push	ds
fixupDS:
	clr	si				; init index into folder window
						;	table
folderLoop:
	mov	bx, ss:[folderTrackingTable][si].FTE_folder.handle
	tst	bx				; check if window here
	jz	checkNext			; if not, skip this one
	;
	; send message
	;
	push	ax, cx, dx, bp, di, si		; save message data
	;
	; If their is a custom callback to check for duplicate
	; messages, retrieve it from checkDuplicateProc and put it on
	; the stack.
	;
	test	di, mask MF_CUSTOM
	jz	noCallback
	mov	bx, es
	push	bx
	mov	bx, segment dgroup
	mov	es, bx
	pop	bx
	push	es:[checkDuplicateProc].segment
	push	es:[checkDuplicateProc].offset
	mov	es, bx
	mov	bx, ss:[folderTrackingTable][si].FTE_folder.handle

noCallback:
	mov	si, ss:[folderTrackingTable][si].FTE_folder.chunk
	call	ObjMessage
	pop	ax, cx, dx, bp, di, si		; save method data
checkNext:
	add	si, size FolderTrackingEntry	; move to next window
						; check if end of list
	cmp	si, MAX_NUM_FOLDER_WINDOWS * (size FolderTrackingEntry)
	jne	folderLoop			; if not, go back to check next
	test	di, mask MF_FIXUP_DS
	jnz	fixedDS
	pop	ds
fixedDS:
	.leave
	ret
BroadcastToFolderWindows	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToTreeAndBroadcast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sends method to Tree Window (if opened) and to all
		Folder Windows

CALLED BY:	EXTERNAL

PASS:		ss:[folderTrackingTable] - table of opened folder windows
		ax - method to send
		cx, dx, bp - method data
		di - MessageFlags for ObjMessage

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/05/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToTreeAndBroadcast	proc	far
	uses	bx, si
	.enter
	;
	; send to tree, if opened
	;
if _GMGR
if not _ZMGR
ifndef GEOLAUNCHER		; no Tree Window for GeoLauncher
if _TREE_MENU		
	cmp	ss:[treeRelocated], TRUE	; tree alive?
	jne	noTree				; nope
	test	di, mask MF_FIXUP_DS
	jnz	fixupDS
	push	ds
fixupDS:
	push	ax, di, cx, dx, bp		; save method, flags
	;
	; If their is a custom callback to check for duplicate
	; messages, retrieve it from checkDuplicateProc and put it on
	; the stack.
	;
	test	di, mask MF_CUSTOM
	jz	noCallback
	mov	si, es
	mov	bx, segment dgroup
	mov	es, bx
	push	es:[checkDuplicateProc].segment
	push	es:[checkDuplicateProc].offset
	mov	es, si
noCallback:
	mov	bx, handle TreeObject
	mov	si, offset TreeObject
	call	ObjMessage
	pop	ax, di, cx, dx, bp		; retrieve method, flags
	test	di, mask MF_FIXUP_DS
	jnz	fixedDS
	pop	ds
fixedDS:
noTree:
endif		; if _TREE_MENU		
endif		; ifndef GEOLAUNCHER
endif		; if (not _ZMGR)
endif		; if _GMGR
	;
	; broadcast to Folder Windows
	;
	call	BroadcastToFolderWindows
	.leave
	ret
SendToTreeAndBroadcast	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDiskInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fetch volume name, free disk space, disk ID for this
		disk; reports error if disk not readable and asks for volume
		lable if none exists

CALLED BY:	INTERNAL
			DriveToolStartSelect

PASS:		ds:si = pointer to DiskInfoStruct
		al = drive number

RETURN:		carry set if error (reported)
		carry clear otherwise:
			bx	= disk handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version
	brianc	01/15/90	broken out
	brianc	03/13/90	rewritten

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDiskInfo	proc	far
	uses	ax, cx, dx, ds, si, es, di
	.enter
	;
	; attempt to register disk
	;
	call	DiskRegisterDiskSilently
	jnc	noRegisterError			; if no error, continue
	mov	ax, ERROR_DRIVE_NOT_READY	; else, report it
error:
	call	DesktopOKError
	stc					; indicate error
	jmp	done

noRegisterError:
	;
	; check if volume name exists
	;	bx = disk handle
	;
	segmov	es, ds				; es:di = volume name field
	mov	di, si
	call	DiskGetVolumeInfo
	jc	error				; if error, report it
done:
	.leave
	ret
GetDiskInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetVolumeNameAndFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fill in volume name and free space fields from disk handle
		field in DiskInfoStruct

CALLED BY:	INTERNAL
			FolderScan (Folder object)
			ReadVolumeLabel (Tree object)

PASS:		ds:si = DiskInfoStruct
		bx	= disk handle

RETURN:		carry clear if no error
			volume name and free space fields filled in
		carry set if error (reported)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetVolumeNameAndFreeSpace	proc	far
		uses	es, di, bx, cx, dx, bp
		.enter
	;
	; Get all the pertinent info at once.
	; 
		segmov	es, ds
		mov	di, si
		call	DiskGetVolumeInfo
		jc	error
if _GMGR
	;
	; Notify anyone interested in the free space for this disk of the
	; current amount of free space.
	; 
	mov	cx, ds:[si].DIS_freeSpace.high
	mov	dx, ds:[si].DIS_freeSpace.low
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE or \
			mask MF_REPLACE
	mov	ax, MSG_UPDATE_FREE_SPACE
	mov	bp, bx
	call	SendToTreeAndBroadcast
	clc
endif				; if _GMGR

done:
		.leave
		ret
error:
		call	DesktopOKError
		jmp	done
	
GetVolumeNameAndFreeSpace	endp

;not needed - usability 4/3/90
if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AskForVolumeLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ask user for volume for this disk, adds to disk

CALLED BY:	INTERNAL
			GetDiskInfo

PASS:		bx - disk handle

RETURN:		carry clear if successful
		carry set otherwise
			ax = error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AskForVolumeLabel	proc	near
	uses	bx, cx, dx, ds, si, es, di, bp
	.enter
	push	bx				; save disk handle
	mov	bx, handle MiscUI
	mov	si, offset MiscUI:VolumeNameEntry
NOFXIP<	mov	dx, cs							>
NOFXIP<	mov	bp, offset nukeVolumeEntry	; clear vol. entry field>
FXIP<	clr	dx							>
FXIP<	push	dx							>
FXIP<	mov	dx, ss							>
FXIP<	mov	bp, sp				; dx:bp = ptr to null	>	
	call	CallSetText
FXIP<	pop	si				; restore stack		>	
	mov	si, offset MiscUI:VolumeNameBox
	call	UserDoDialog
	pop	bx				; retrieve disk handle
	cmp	ax, OKCANCEL_OK			; continue?
	clc					; indicate no error
	jne	AFVL_done			; if not, done
	push	bx				; save disk handle
	mov	bx, handle MiscUI
	mov	si, offset MiscUI:VolumeNameEntry
	clr	cx				; use global memory block
	mov	ax, MSG_VIS_TEXT_GET_ALL
	call	ObjMessageCall			; ax = global mem block w/text
;deal with mapping from GEOS character set to DOS character set
	pop	bp				; retrieve disk handle
	tst	cx				; any text?
	clc					; indicate no error
	jz	AFVL_done			; if no text, no vol. label
	mov	bx, ax				; lock text block
	call	MemLock				; else, get vol. label
	mov	ds, ax				; ds:si = new vol label
	clr	si
spaceLoop:
	LocalGetChar ax, dssi			; skip leading spaces
	LocalCmpChar ax, ' '
	je	spaceLoop
	dec	si				; point at first non-space
DBCS <	dec	si							>
	tst	al
	jz	AFVL_done			; if only spaces + null, done
	mov	bx, bp				; bx = disk handle
	call	DiskFileSetVolumeName		; exit with error code
AFVL_done:
	.leave
	ret
AskForVolumeLabel	endp

SBCS <nukeVolumeEntry	byte	0					>
DBCS <nukeVolumeEntry	wchar	0					>

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLoadAppGenParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	stuff genParent field of AppLaunchBlock

CALLED BY:	EXTERNAL
			DesktopLoadApplication,
			CallApplToGetMoniker,
			

PASS:		dx - handle of AppLaunchBlock

RETURN:		ALB_genParent filled

DESTROYED:	ax, bx, cx, si, di, bp, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	DS is NO LONGER considered to be a fixupable object block.
	It's up to the caller to fixup DS if necessary

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLoadAppGenParent	proc	far
	uses	es
	.enter
	;
	; query for field to use as ALB_genParent
	;
	push	dx				; save AppLaunchBlock
	mov	bx, handle Desktop
	mov	si, offset Desktop
	mov	ax, MSG_GEN_GUP_QUERY
	mov	cx, GUQT_FIELD
	call	ObjMessageCall			; cx:dx = field
EC <	ERROR_NC	NO_RESPONSE_TO_GUQT_FIELD			>
	pop	bx
	call	MemLock				; lock AppLaunchBlock
	mov	es, ax
	mov	es:[ALB_genParent].handle, cx	; save genParent
	mov	es:[ALB_genParent].chunk, dx
	call	MemUnlock
	mov	dx, bx				; AppLaunchBlock in DX again
	.leave
	ret
GetLoadAppGenParent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilFormatDateAndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a FileDate and FileTime record into a standard
		display.

CALLED BY:	EXTERNAL
PASS:		ax	= FileTime
		bx	= FileDate
		es:di	= buffer into which to format it
RETURN:		buffer null-terminated
		cx	= # chars in the string w/o null term
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilFormatDateAndTime proc	far
	
	uses	bx, di, si
	.enter

	tst	bx
	jz	invalid

	;
	; Even though the name is LocalFormatFileDateTime, we don't seem to
	; have any format that combines the two, so do the formatting
	; in two parts, time first.
	; 
	xchg	ax, bx		; ax <- date, bx <- time
	mov	si, DTF_HMS
	call	LocalFormatFileDateTime

	;
	; Put space between the time and the date.
	; 
	add	di, cx				; es:di=byte after time
DBCS <	add	di, cx							>
	mov_tr	si, ax				; save date
	LocalLoadChar ax, ' '			; spacing btwn time and date
	LocalPutChar esdi, ax
	inc	cx
	LocalPutChar esdi, ax
	inc	cx
if GPC_NAMES_AND_DETAILS_TITLES
	LocalPutChar esdi, ax
	inc	cx
	LocalPutChar esdi, ax
	inc	cx
endif
	
	push	cx

	;
	; Now format the date appropriately
	; 
	mov_tr	ax, si
	mov	si, DTF_ZERO_PADDED_SHORT
	call	LocalFormatFileDateTime
	pop	ax
	add	cx, ax
done:
	.leave
	ret

invalid:
	;
	; Just use a minus sign if the date/time are invalid (as indicated by
	; the FileDate being 0)
	; 
	mov	ax, '-'
	stosw
DBCS <	clr	ax							>
DBCS <	stosw								>
DBCS <	mov	cx, 2							>
SBCS <	mov	cx, 1							>
	jmp	done
UtilFormatDateAndTime endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMaxNumFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checkes whether there is enough memory fro new folder

CALLED BY:	CreateFolderWindowCommon
PASS:		bx - folder's handle
		cx - maxNumFiles
		dx - numFiles
RETURN:		carry set - can't open any more
		carry not set - go ahead and open folder
DESTROYED:	everything
SIDE EFFECTS:	closes on an LRU basis if not enough memory available

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _GMGR

CheckMaxNumFiles	proc	near
	.enter

checkAgain:
	; close the oldest window
	call	CloseOldestWindow

	; did we get to last window
	jc	lastWindow

	; see if we need to close another one
	mov	dx, ss:[numFiles]	
	cmp	cx, dx
	jl	checkAgain

lastWindow:
	.leave
	ret
CheckMaxNumFiles	endp

endif	; if _GMGR

UtilCode	ends

if _PEN_BASED


PseudoResident	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendAbortQuickTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	stop quick transfer via process thread

CALLED BY:	END_OTHER handlers

PASS:		ds - fixupable block
		es - dgroup

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendAbortQuickTransfer	proc	far
	uses	ax, bx
	.enter
EC <	push	ds, bx, ax						>
EC <	GetResourceSegmentNS dgroup, ds					>
EC <	mov	ax, ds							>
EC <	mov	bx, es							>
EC <	cmp	bx, ax							>
EC <	ERROR_NE	DESKTOP_FATAL_ERROR				>
EC <	pop	ds, bx, ax						>
	;
	; as we are about to send MSG_DESKTOP_ABORT_QUICK_TRANSFER, which
	; unconditionally aborts, we can clear the fileDragging flags
	; - brianc 6/25/93
	;
	mov	es:[fileDragging], 0
	mov	es:[delayedFileDraggingEnd], BB_FALSE
	mov	ax, MSG_DESKTOP_ABORT_QUICK_TRANSFER
	mov	bx, handle 0
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SendAbortQuickTransfer	endp


PseudoResident	ends

endif


UtilCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCheckReadDirInfo, UtilCheckWriteDirInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if dir info file should read/written

CALLED BY:	EXTERNAL

PASS:		current directory set for folder

RETURN:		carry set if should _not_ read/write

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/22/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCheckReadDirInfo	proc	far
	; first check .ini override?
	call	UtilCheckDirInfoCommon
	ret
UtilCheckReadDirInfo	endp

UtilCheckWriteDirInfo	proc	far
	; first check .ini override?
	call	UtilCheckDirInfoCommon
	ret
UtilCheckWriteDirInfo	endp

UtilCheckDirInfoCommon	proc	near
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter
	call	ShellAlloc2PathBuffers		; es = PathBuffer2
	mov	cx, size PathName
	segmov	ds, es, si
	mov	si, offset PB2_path1
	call	FileGetCurrentPath		; bx = disk handle
	mov	di, offset PB2_path2
	clr	dx				; no drive name
	call	FileConstructActualPath		; bx = disk handle
	jc	done				; error, no r/w
	call	DiskGetDrive			; al = drive
	tst	al
	jz	noRW				; no r/w for drive A:
	call	DriveGetExtStatus		; ax = DriveExtendedStatus
	test	ax, mask DS_MEDIA_REMOVABLE
	jnz	noRW				; no r/w for removable
	test	ax, mask DES_READ_ONLY
	jnz	noRW				; no r/w for r/o
	call	FileParseStandardPath		; get StandardPath
	cmp	ax, SP_NOT_STANDARD_PATH
	je	noRW				; no r/w for non-StandardPath
	clc					; allow r/w
	jmp	short done

noRW:
	stc					; no r/w
done:
	call	ShellFreePathBuffer		; (flags preserved)
	.leave
	ret
UtilCheckDirInfoCommon	endp

UtilCode	ends

