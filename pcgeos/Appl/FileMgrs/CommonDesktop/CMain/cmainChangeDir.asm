COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cmainChangeDir.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/15/92   	Initial version.

DESCRIPTION:
	

	$Id: cmainChangeDir.asm,v 1.1 97/04/04 15:00:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UtilCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopQuick{Appl,Doc,Max,Restore,Tree}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle icon area stuff and Tree Window

CALLED BY:	misc. methods

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/09/90	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GEOLAUNCHER		; no World button for GeoLauncher

DesktopQuickAppl	method	DesktopClass, MSG_QUICK_APPL
	mov	bx, SP_APPLICATION
	call	DesktopQuickApplDocCommon
	ret
DesktopQuickAppl	endm

DesktopQuickDosRoom	method	DesktopClass, MSG_QUICK_DOS_ROOM
	mov	bx, SP_DOS_ROOM
	call	DesktopQuickApplDocCommon
	ret
DesktopQuickDosRoom	endm

if not _FORCE_DELETE

DesktopQuickWastebasket	method	DesktopClass, MSG_QUICK_WASTEBASKET
	mov	bx, SP_WASTE_BASKET
	call	DesktopQuickApplDocCommon
	ret
DesktopQuickWastebasket	endm
endif ; not _FORCE_DELETE


DesktopQuickBackup	method	DesktopClass, MSG_QUICK_BACKUP
	mov	bx, SP_BACKUP
	call	DesktopQuickApplDocCommon
	ret
DesktopQuickBackup	endm

endif

DesktopQuickDoc	method	DesktopClass, MSG_QUICK_DOC
	mov	bx, SP_DOCUMENT
	call	DesktopQuickApplDocCommon
	ret
DesktopQuickDoc	endm


;
; pass:	bx = StandardPath
;
DesktopQuickApplDocCommon	proc	near
NOFXIP <	mov	dx, cs						>
NOFXIP <	mov	bp, offset DeskProcessNullPath	;dx:bp=null path for >
							;passed SP
FXIP <		clr	bp						>
FXIP <		push	bp						>
FXIP <		mov	dx, ss						>
FXIP <		mov	bp, sp		;dx:bp = null path 		>
	call	CreateNewFolderWindow
FXIP <		pop	bp						>
	ret
DesktopQuickApplDocCommon	endp

SBCS <DeskProcessNullPath	char	0				>
DBCS <DeskProcessNullPath	wchar	0				>

if _DOCMGR
DesktopQuickArchive	method	DesktopClass, MSG_QUICK_ARCHIVE
	mov	bx, SP_DOCUMENT
	mov	dx, cs
	mov	bp, offset DeskProcessArchivePath ;dx:bp=null path for
							;passed SP
	call	CreateNewFolderWindow
	ret
DesktopQuickArchive	endm

DeskProcessArchivePath	TCHAR	"Archive",0
endif

if _GMGR
ifndef GEOLAUNCHER		; no Icon Area buttons for GeoLauncher

;
; pass:
;	cx = identifier
;
DesktopOverlappingFullSizedToggle	method	DesktopClass, \
					MSG_OVERLAPPING_FULL_SIZED_TOGGLE
	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED	; assume full-sized
	test	cx, mask QVTI_FULL_SIZED
	jnz	haveMode
	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING	; else overlapping
haveMode:
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	call	ObjMessageCallFixup
	ret
DesktopOverlappingFullSizedToggle	endm

endif		; ifndef GEOLAUNCHER
endif		; if _GMGR

ifdef GEOLAUNCHER		; GeoLauncher has open/close directory buttons
DesktopOpenDirectory	method	DesktopClass, MSG_OPEN_DIRECTORY
	mov	ax, MSG_OPEN_SELECT_LIST	; simulate File:Open
	call	DesktopSendToCurrentWindow	; sends only to FolderClass obj.
	ret
DesktopOpenDirectory	endm

DesktopCloseDirectory	method	DesktopClass, MSG_CLOSE_DIRECTORY
	mov	ax, MSG_FOLDER_UP_DIR
	call	DesktopSendToCurrentWindow	; sends only to FolderClass obj.
	ret
DesktopCloseDirectory	endm

DesktopExitToDos	method	DesktopClass, MSG_EXIT_TO_DOS
	mov	bx, handle Desktop
	mov	si, offset Desktop
	mov	ax, MSG_GEN_GUP_QUERY
	mov	cx, GUQT_FIELD
	call	ObjMessageCallFixup		; ^lcx:dx = field
	mov	bx, cx
	mov	si, dx				; ^lbx:si = field
	mov	ax, MSG_GEN_FIELD_EXIT_TO_DOS
	call	ObjMessageForce
	ret
DesktopExitToDos	endm
endif

if _GMGR
if not _ZMGR
ifndef GEOLAUNCHER		; no "Show Tree Window" menu item
if _TREE_MENU
DesktopQuickTree	method	DesktopClass, MSG_QUICK_TREE
	call	IsTreeWindowUp
	jnc	needToCreate			; nope, create
	call	BringUpTreeWindow		; if so, just bring-to-front
	ret		; <-- EXIT HERE ALSO

needToCreate:
	;
	; get current tree drive from Tree Drive menu
	;
	mov	bx, handle TreeMenuDriveList
	mov	si, offset TreeMenuDriveList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessageCallFixup		; ax = drive #/media
	jnc	short haveDriveAL		; excl found, use drive #
	mov	bx, ss:[geosDiskHandle]		; else no excl, use system drive
	call	DiskGetDrive			; al = drive number
haveDriveAL:
	clr	ah
	mov	bp, ax				; bp = drive number
	;
	; create Tree Window if new drive contains good disk
	; else, do nothing but report error
	;	bp = drive number
	;
	call	SetTreeDriveAndShowTreeWindow
	ret
DesktopQuickTree	endm
endif		; ifdef  _TREE_MENU
endif		; ifndef GEOLAUNCHER
endif		; if (not _ZMGR)
endif		; if _GMGR

UtilCode	ends
