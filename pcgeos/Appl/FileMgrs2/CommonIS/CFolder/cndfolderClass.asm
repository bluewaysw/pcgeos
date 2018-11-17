COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonND/CFolder
FILE:		cndfolderClass.asm
AUTHOR:		David Litwin

ROUTINES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/25/92		Initial version

DESCRIPTION:
	This file contains the class routines of the NDFolderClass

	$Id: cndfolderClass.asm,v 1.5 98/08/18 00:45:44 joon Exp $

------------------------------------------------------------------------------@

NDFolderCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	init's the NDFOI_popUpType and then calls the superclass

CALLED BY:	MSG_META_START_MOVE_COPY

PASS:		*ds:si - NDFolderClass object
		ds:bx - NDFolderClass instance data

RETURN:		none

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderStartMoveCopy	method dynamic NDFolderClass, MSG_META_START_MOVE_COPY

	movdw	ds:[di].NDFOI_mousePos, cxdx
	mov	ds:[di].NDFOI_popUpType, WPUT_SELECTION
	mov	di, offset NDFolderClass
	GOTO	ObjCallSuperNoLock
NDFolderStartMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDWhiteSpacePopUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	called when an EndMoveCopy in the whitespace of a folder has
		happend, signaling that the Folder's pop-up should appear

CALLED BY:	FolderEndMoveCopy

PASS:		*ds:si - NDFolderClass object

RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDWhiteSpacePopUp	proc	far
	uses	ax, bx, cx, dx, si, di, bp
	class	NDDriveClass	; because we might need Drive instance data
	.enter

	DerefFolderObject	ds, si, di
	mov	ds:[di].NDFOI_popUpType, WPUT_WHITESPACE
	mov	bp, ds:[di].NDFOI_ndObjType	; get object type
	call	NDValidateWOT

	cmp	bp, WOT_DESKTOP
	jne	notDesktop
	mov	cx, handle NDDesktopMenu
	mov	dx, offset NDDesktopMenu
	jmp	bringUpMenu

notDesktop:
	;
	; Only allow the popup to come up if this is the top folder in
	; entry level.
	;
BA<	call	UtilAreWeInEntryLevel?			>
BA<	jnc	continue				>

BA<	mov	ax, MSG_BA_APP_GET_PWA_TOP		>
BA<	call	UserCallApplication			>

BA<	cmp	cx, ds:[di].FOI_windowBlock		>
BA<	jne	exit					>
BA<continue:						>

	mov	cx, ds:[di].FOI_windowBlock
	mov	dx, FOLDER_MENU_OFFSET

bringUpMenu:
	push	cx, dx				; save menu optr
	mov	ax, MSG_SEND_DISPLAY_OPTIONS
	call	ObjCallInstanceNoLock
	pop	cx, dx				; restore menu optr

	call	NDStartPopUp
exit:
	.leave
	ret
NDWhiteSpacePopUp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDObjectPopUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when an EndMoveCopy on glyph (object) of a folder has
		happend, signaling that the selection's pop-up should appear.
		Sets the NDFOI_popUpType variable to WPUT_SELECTION or
		WPUT_OBJECT depending on whether or not the glyph the user 
		clicked on was part of a selection or not.

CALLED BY:	FolderEndMoveCopy

PASS:		*ds:si - NDFolderClass object
		es:di - FolderRecord of pop-up object

RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDObjectPopUp	proc	far
	class	NDFolderClass
	uses	ax, bx, cx, dx, bp, di, si

	.enter

EC <	call	ECCheckFolderObjectDSSI		>
EC <	call	ECCheckFolderRecordESDI			>

	call	NDIsItemInSelectionList			; sets NDFOI_popUpType
	jnc	itemNotInSelectionList			; and NDFOI_nonSelect
							;  if not selected.
	call	NDGetFlagsForMultipleSelections
	jmp	gotGlobalMenuFlags

itemNotInSelectionList:
	mov	bp, es:[di].FR_desktopInfo.DI_objectType
	call	NDValidateWOT
	cmp	bp, WOT_DESKTOP
	jne	notDesktop

	mov	ax, MSG_SEND_DISPLAY_OPTIONS
	call	ObjCallInstanceNoLock		; set the Sort/View UI correctly

	mov	cx, handle NDDesktopMenu
	mov	dx, offset NDDesktopMenu
	jmp	short startPopup

notDesktop:
	call	NDCheckDriveType		; bp is WOT of object
	clr	ax				; move flags into cxdx
	call	NDGetGlobalMenuFlagsForWOT

BA<	call	BABookmarksMenuItemCheck	; bp is WOT of object	>
BA<	call	BACreateFolderMenuItemCheck				>
	call	NDWastebasketMenuItemCheck
	call	NDOpenedMenuItemCheck

gotGlobalMenuFlags:
	jnc	notSingleOpened

	call	NDSetSortViewUIForOpenedFolder

notSingleOpened:
	call	NDGlobalMenuGrabSortViewUI
	call	NDSetGlobalMenuFromFlags
	jc	exit				; if no menu items, exit

	mov	cx, handle GlobalMenu
	mov	dx, offset GlobalMenu

startPopup:
	call	NDStartPopUp
exit:
	.leave
	ret
NDObjectPopUp	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDSetSortViewUIForOpenedFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	es:di is a an opened single selection, if it has an opened
		folder (as opposed to an opened document or executable that 
		has no associated open folder) we set the Sor/View UI from 
		the folder of that opened selection.

CALLED BY:	NDObjectPopUp

PASS:		*ds:si	- NDFolderClass object of containing folder
		es:di	- FolderRecord of opened single item

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDSetSortViewUIForOpenedFolder	proc	near
	uses	ax,bx,cx,dx,bp,si,di,ds,es
	.enter

EC <	call	ECCheckFolderObjectDSSI		>
EC <	call	ECCheckFolderRecordESDI			>
	call	FilePushDir

	mov	bp, es:[di].FR_desktopInfo.DI_objectType
	call	NDValidateWOT
	call	NDIsThisAFolderTypeWOT
	jnc	exit				; no SortView if not foldertype

	call	Folder_GetDiskAndPath
	lea	dx, ds:[bx].GFP_path
	mov	bx, ax
	call	FileSetCurrentPath		; current path is folder's path

	segmov	ds, es
	mov	si, di				; ds:si is FolderRecord
CheckHack< offset FR_name eq 0 >
	mov	bp, di
	mov	dx, ds
	clr	cx				; cx, dx:bp is object's path

	cmp	ds:[si].FR_desktopInfo.DI_objectType, WOT_DRIVE
	jne	notDrive

	call	FindOpenDriveWindow
	jmp	gotOpenedFolderBlock

notDrive:
	mov	di, mask MF_CALL
	call	FindFolderWindow
	call	ShellFreePathBuffer		;  nuke returned path buffer

gotOpenedFolderBlock:
	jnc	exit				; exit on error

	mov	si, FOLDER_OBJECT_OFFSET
	mov	ax, MSG_SEND_DISPLAY_OPTIONS
	call	ObjMessageCall
exit:
	call	FilePopDir
	.leave
	ret
NDSetSortViewUIForOpenedFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDGlobalMenuGrabSortViewUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts the Sort/View UI under the GlobalMenu before it sets
		its UI, as it may set the Sort/View item usable, for which
		it needs to be in a Gen tree.

CALLED BY:	NDOpenPopUp

PASS:		*ds	- object block of folder object bringing up this popup
		cxdx	- GlobalMenuBitfield of flags for this popup
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/29/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDGlobalMenuGrabSortViewUI	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	;
	; If GMBL_SORT is not set, we won't be setting the Sort/View UI
	; usable, and so we don't really need to have a parent...
	;   We do this before the .enter to save all the push/pops.
	;
	test	dx, mask GMBL_SORT
	jz	exit

	.enter
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	bx, handle GlobalMenuSortAndView
	mov	si, offset GlobalMenuSortAndView
	mov	dl, VUM_NOW
	call	ObjMessageCallFixup
	and	ss:[globalMenuState].GMB_low, not(mask GMBL_SORT)

	mov	ax, MSG_GEN_FIND_PARENT
	call	ObjMessageCallFixup
	
	xchg	bx, cx				; swap parent and child
	xchg	si, dx				; so ^bx:si is parent and
	tst	bx				; ^lcx:dx is child
	jz	noParent

	cmp	bx, handle GlobalMenuOther
	jne	notUnderGlobalMenu
	cmp	si, offset GlobalMenuOther
	je	done

notUnderGlobalMenu:
	mov	ax, MSG_GEN_REMOVE_CHILD
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjMessageCallFixup

noParent:
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bx, handle GlobalMenuOther
	mov	si, offset GlobalMenuOther
	mov	bp, 2				; after "Create Folder"
	call	ObjMessageCallFixup

	mov	ax, MSG_GEN_SET_USABLE
	mov	bx, cx
	mov	si, dx				; put Sort/View in ^lbx:si
	mov	dl, VUM_NOW
	call	ObjMessageCallFixup
	or	ss:[globalMenuState].GMB_low, mask GMBL_SORT
done:
	.leave
exit:	
	ret
NDGlobalMenuGrabSortViewUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDStartPopUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the popup via force queue
		(made it force queue to itself for timing reasons)

CALLED BY:	NDWhiteSpacePopUp, NDObjectPopUp

PASS:		*ds:si	= NDFolderClass object
		^lcx:dx	= popup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/10/93	  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDStartPopUp	proc	near
	class	NDFolderClass

EC <	call	ECCheckFolderObjectDSSI		>

	mov	ax, MSG_ND_FOLDER_BRING_UP_POPUP
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
NDStartPopUp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderBringUpPopUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the pop up if the folder for which it is bring
		brought up is still the target.

CALLED BY:	MSG_ND_FOLDER_BRING_UP_POPUP, forced on queue by NDStartPopUp

PASS:		*ds:si	= NDFolderClass object
		^lcx:dx	= PopUp object (an interaction) to bring up
RETURN:		none
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/ 1/93   	Initial version
	dlitwin	3/10/93		Changed to be message and check targetFolder

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderBringUpPopUp	method dynamic NDFolderClass, 
					MSG_ND_FOLDER_BRING_UP_POPUP
	.enter

EC <	call	ECCheckFolderObjectDSSI		>
	;
	; Don't bring up a popup for the wrong folder
	;
	mov	ax, ds:[LMBH_handle]
	cmp	ax, ss:[targetFolder]
	jne	exit

	mov	bp, di			; ds:[bp] = instance data
	movdw	axbx, ds:[bp].NDFOI_mousePos
	mov	di, ds:[bp].DVI_window
	tst	di
	jz	noWindow
	call	WinTransform		; transform to screen coordinates
noWindow:
	xchg	ax, cx			; ^lax,dx	(cx,bx)
	xchg	ax, bx			; ^lbx:dx	(cx,ax)
	xchg	ax, dx			; ^lbx:ax	(cx,dx)
	mov_tr	si, ax			; ^lbx:si	(cx,dx)

	mov	ax, MSG_VIS_SET_POSITION
	call	ObjMessageCall

	mov	ax, MSG_ND_POPUP_MENU_SET_FOLDER_INITIATED
	call	ObjMessageCall

	mov	ax, MSG_ND_POPUP_MENU_PRE_POPUP
	call	ObjMessageCall

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageCall
exit:
	.leave
	ret
NDFolderBringUpPopUp	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMCControlPanelCreateItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent screen lock button from being added if user does
		not have permission.

CALLED BY:	MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
PASS:		*ds:si	= EMCControlPanelClass object
		ds:di	= EMCControlPanelClass instance data
		ds:bx	= EMCControlPanelClass object (same as *ds:si)
		es 	= segment of EMCControlPanelClass
		ax	= message #
		ss:bp	= CreateExpressMenuControlItemParams
		dx	= size CreateExpressMenuControlItemParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%% This is for EMCControlPanelClass %%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NEWDESKBA

EMCControlPanelCreateItem	method dynamic EMCControlPanelClass, 
					MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
	cmp	ss:[bp].CEMCIP_feature, CEMCIF_UTILITIES_PANEL
	jne	callSuper
	cmp	ss:[bp].CEMCIP_itemPriority, CEMCIP_SAVER_SCREEN_LOCK
	jne	callSuper

	call	IclasGetSecurityLockStatus
	jc	callSuper

	ret	; ignore request to create item

callSuper:
	mov	di, offset EMCControlPanelClass
	GOTO	ObjCallSuperNoLock	

EMCControlPanelCreateItem	endm

endif


if _NEWDESKBA

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BABookmarksMenuItemCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if an object is a piece of DOS courseware
		that can have bookmarks set for it.

CALLED BY:	NDObjectPopUp

PASS:		bp	- WOT of object to check
		*ds:si	- NDFolderClass object of the containing folder
		es:di	- FolderRecord of file in question
		cxdx	- GlobalMenuBitfield flags

RETURN:		cxdx	- updated correctly

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	1/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BABookmarksMenuItemCheck	proc	near
	uses	ax,bx

EC <	call	ECCheckFolderObjectDSSI		>
EC <	call	ECCheckFolderRecordESDI			>

	cmp	bp, WOT_DOS_COURSEWARE			; skip all push/pops
	jne	exit					; if we are just going
							; to exit.
	.enter
	call	FilePushDir

	call	Folder_GetDiskAndPath
	push	dx
	add	bx, offset GFP_path
	mov	dx, bx
	mov	bx, ax				; bx, ds:dx is folder's path
	call	FileSetCurrentPath
	pop	dx

	clr	bx				; use current path (folder's)
	call	BADosCoursewareShowBoomarks	; es:di is courseware's name

	jc	done
	and	cx, not(mask GMBH_BOOKMARKS)	; remove Bookmarks menu item
done:
	call	FilePopDir
	.leave
exit:
	ret
BABookmarksMenuItemCheck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BADosCoursewareShowBoomarks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figures out if bookmarks should be a menu option for 
		the given piece of courseware

CALLED BY:	BABookmarksMenuItemCheck
PASS:		es:di				; courseware name
		bx				; diskhandle, 0
		PWD = class 
RETURN:		CarrySet	if bookmarks stays in menu
		CarryClear	if bookmarks should be removed.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		See if it is the users home dir by comparing the path
		to:
		DESKTOP\user_full_name
		see if it is a special utility by checking for SPECIALS in
		the path

REVISION HISTORY:
	Name	Date		Description
 	----	----		-----------
	RB	2/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
bookmarkKeyString	char 	"SPECIALS", C_BACKSLASH, 0
BOOKMARK_KEYSTRING_LENGTH = $ - bookmarkKeyString
homeString	char ND_DESKTOP_RELATIVE_PATH, C_BACKSLASH
HOME_STRING_LENGTH = $ - homeString

BADosCoursewareShowBoomarks	proc	near
	uses	ax,bx,cx,dx,si,di,bp,es,ds
pBuffer	local	PathName
lname	local	USER_ID_LENGTH dup (char)
fullName local	USER_FULL_NAME_LENGTH + 8 dup  (char)	
; 8 is for DESKTOP
	.enter

	;
	; If this is home clc, leave
	;
		push	bx, es, di		; disk Handle, courseware
		; create what we think the home path should be
		segmov	ds, ss
		lea	si, ss:[lname]
		mov	cx, ss
		lea	dx, ss:[fullName]
		mov	di, dx
		add	dx, 8			; leave room for DESKTOP
		call 	NetUserGetLoginName
		call	NetUserGetFullName
		; write DESKTOP\ into path for comparing
		mov	es, cx
		mov	cx, HOME_STRING_LENGTH
		segmov	ds, cs
		mov	si, offset homeString
		rep	movsb
		
		; Get current path to compare to.

		mov	cx, size PathName
		segmov	ds, ss
		lea	si, pBuffer
		call	FileGetCurrentPath

		segmov	es, ss
		lea	di, fullName
						; es:di --> built name
						; ds:si --> path of folder
	
		; compare the 2 strings
		clr	cx
		call	LocalCmpStrings
		
		
		pop	bx, es, di		; disk handle, CW name

		jz	inHome
EC <	call	ECCheckFolderRecordESDI			>
		
		segmov	ds, es
		mov	dx, di			; ds:dx = courseware name
		segmov	es, ss
		lea	di, pBuffer		; es:di =buffer to write
						; path of target
		mov	cx, size PathName
		call	FileReadLink
		call	LocalStringLength
		inc	cx
	;
	; Is the string "SPECIALS\" in the string?
	;
		segmov	ds, cs
		mov	si, offset bookmarkKeyString
		mov	dx, BOOKMARK_KEYSTRING_LENGTH
		call	SubSearchString
bye:	.leave
	ret
inHome:
	clc
	jmp	bye
	
BADosCoursewareShowBoomarks	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BACreateFolderMenuItemCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if an object is a piece of DOS courseware
		that can have bookmarks set for it.

CALLED BY:	NDObjectPopUp

PASS:		cxdx	- GlobalMenuBitfield flags

RETURN:		cxdx	- updated correctly

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/4/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BACreateFolderMenuItemCheck	proc near
	uses	ax
	.enter

	call	IclasGetUserPermissions
	test	ax, mask UP_CREATE_FOLDER
	jnz	havePermission

	and	dx, not (mask GMBL_CREATE_FOLDER)

havePermission:
	.leave
	ret
BACreateFolderMenuItemCheck	endp

endif		; if _NEWDESKBA



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDOpenedMenuItemCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the file isn't opened, certain menu items shouldn't
		be present on some objects.

CALLED BY:	NDObjectPopUp, NDWhiteSpacePopUp

PASS:		es:di	- FolderRecord of file in question
		cxdx	- GlobalMenuBitfield flags

RETURN:		cxdx	- updated correctly
		carry	- set if item was opened
			- clear if it wasn't

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDOpenedMenuItemCheck	proc near
	.enter

EC <	call	ECCheckFolderRecordESDI			>

	test	es:[di].FR_state, mask FRSF_OPENED
	stc
	jnz	done					; remove menu
							; items that 
	and	cx, not(UNOPENED_MENU_ITEMS_HIGH)	;  apply only to opened
	and	dx, not(UNOPENED_MENU_ITEMS_LOW)	;   objects
	clc
done::
	.leave
	ret
NDOpenedMenuItemCheck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDWastebasketMenuItemCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the file is the Wastebasket , certain menu items shouldn't
		be present on some objects.

CALLED BY:	NDObjectPopUp, NDWhiteSpacePopUp

PASS:		*ds:si	- NDFolderClass object of the containing folder
		cxdx	- GlobalMenuBitfield flags

RETURN:		cxdx	- updated correctly

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDWastebasketMenuItemCheck	proc near
	uses	ds, si, ax, bx
	.enter

EC <	call	ECCheckFolderObjectDSSI		>

	call	Folder_GetDiskAndPath
	push	dx
	mov	dx, ax
	lea	si, ds:[bx].GFP_path
	call	IsThisInTheWastebasket
	pop	dx
	jnc	done					; not in the Wastebasket

	and	cx, not(NON_WASTEBASKET_MENU_ITEMS_HIGH)
	and	dx, not(NON_WASTEBASKET_MENU_ITEMS_LOW)
	or	cx, WASTEBASKET_MENU_ITEMS_HIGH
	or	dx, WASTEBASKET_MENU_ITEMS_LOW

done:
	.leave
	ret
NDWastebasketMenuItemCheck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDCheckDriveType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the drive number of the drive link and passes it
		to NDSetDriveUIIfRemovable.

CALLED BY:	NDObjectPopUp

PASS:		bp - WOT of the object in es:di
		*ds:si - NDFolderClass object
		es:di  - FolderRecord entry of object
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDCheckDriveType	proc	near
	uses	ax
	.enter

EC <	call	ECCheckFolderObjectDSSI		>
EC <	call	ECCheckFolderRecordESDI			>

	cmp	bp, WOT_DRIVE
	jne	exit

	call	NDGetDriveNumberFromFolderRecord
	call	NDSetDriveUIIfRemovable	

exit:
	.leave
	ret
NDCheckDriveType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDGetDriveNumberFromFolderRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the drive number of a drive link given the optr of the
	containing folder and a pointer to the FolderRecord that is the drive
	link within that folder.

CALLED BY:	NDCheckDriveType

PASS:		*ds:si - NDFolderClass object
		es:di  - FolderRecord of a drive link
RETURN:		al - drive number of drive link
DESTROYED:	ah

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	2/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDGetDriveNumberFromFolderRecord	proc	near
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter

EC <	call	ECCheckFolderObjectDSSI		>
EC <	call	ECCheckFolderRecordESDI			>

if 0
	; edigeron 11/10/00 - This check doesn't appear to be right, as this
	; function gets called on any folder window when it gets closed.
	; NC doesn't show any problems, but EC FatalErrors here whenever
	; you attempt to close a folder window that isn't the root of a drive.
EC <	cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_DRIVE	>
EC<	ERROR_NE	INVALID_DESKTOP_OBJECT_TYPE		>
endif
		
	call	FilePushDir

	call	Folder_GetDiskAndPath
	lea	dx, ds:[bx].GFP_path
	mov	bx, ax					; bx, ds:dx is the path
	call	FileSetCurrentPath			; set current path to
							; the parent dir
	segmov	ds, es
	mov	dx, di
		; current path, ds:dx is the drive link's path
	mov	cx, size PathName
	sub	sp, cx					; allocate stack buffer
	segmov	es, ss, di
	mov	di, sp					; es:di is the buffer
	call	FileReadLink

	segmov	ds, es
	mov	dx, sp					; ds:dx is link target
	call	FSDLockInfoShared
	mov	es, ax
	call	DriveLocateByName
	add	sp, size PathName			; pop buffer off stack 

	mov	al, es:[si].DSE_number
	call	FSDUnlockInfoShared
	call	FilePopDir

	.leave
	ret
NDGetDriveNumberFromFolderRecord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDSetDriveUIIfRemovable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if a given drive is removable, and sets the
		GlobalMenuFormatDrive and GlobalMenuCopyDrive usable if
		they are.  If not it makes sure they are not usable.

CALLED BY:	NDWhiteSpacePopUp, NDCheckDriveType

PASS:		al - drive number

RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDSetDriveUIIfRemovable	proc	near
	uses	ax, bx, dx, di, si
	.enter

	;
	; See if the thing is formattable, and only set the CopyDisk
	; and FormatDisk items usable if so (is this correct?)  
	;

	call	DriveGetExtStatus
	
	push	ax
	test	ax, mask DES_FORMATTABLE

	mov	ax, MSG_GEN_SET_USABLE
	jnz	setEm

	mov	ax, MSG_GEN_SET_NOT_USABLE

setEm:
	mov	bx, handle GlobalMenuResource
	mov	si, offset GlobalMenuFormatDisk
	mov	dl, VUM_NOW
	call	ObjMessageNone

	mov	si, offset GlobalMenuCopyDisk
	call	ObjMessageNone

	; edigeron 11/2/00 - if a disk is read only (i.e. CD), disable the
	; Rename Disk option.
	pop	ax
	test	ax, mask DES_READ_ONLY
	mov	ax, MSG_GEN_SET_USABLE
	jz	setIt
	mov	ax, MSG_GEN_SET_NOT_USABLE

setIt:
	mov	si, offset GlobalMenuRenameDisk
	call	ObjMessageNone

	.leave
	ret
NDSetDriveUIIfRemovable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDIsItemInSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if a file is one of the selected files in a
		folder.  Sets the folder's NDFOI_popUpType instance data to
		indicate whether or not it is a selected glyph or not, also
		sets NDFOI_nonSelect to the file offset if the file is not
		in the selection list.

CALLED BY:	NDObjectPopUp

PASS:		*ds:si - NDFolderClass object
		es:di - FolderRecord of the file to check

RETURN:		carry set if it is selected
		carry clear if it is not selected

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	09/02/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDIsItemInSelectionList	proc	near
	uses	bx, bp
	class NDFolderClass
	.enter

EC <	call	ECCheckFolderRecordESDI			>

	DerefFolderObject	ds, si, bp
	test	es:[di].FR_state, mask FRSF_SELECTED
	jz	isNotSelected

	mov	ds:[bp].NDFOI_popUpType, WPUT_SELECTION
	stc
	jmp	done
isNotSelected:
	mov	ds:[bp].NDFOI_popUpType, WPUT_OBJECT
	mov	ds:[bp].NDFOI_nonSelect, di
	mov	es:[di].FR_selectNext, NIL		; make sure single
	clc
done:
	.leave
	ret
NDIsItemInSelectionList	endp

 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDGetFlagsForMultipleSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Runs down the selection list and takes the AND of the
		GlobalMenuBitfields of the selected items so only the menu
		items that apply to all of the objects are displayed.  It
		also masks out certian menu items that shouldn't show up
		in multiple selection menus even though all the objects
		contain these menus.
			New stuff:  If we have selected a single opened item,
		chances are it is a folder type object and so we need to 
		set the Sort/View UI to the opened folder, not the folder
		containing the icon of the opened folder, as it would otherwise
		default to.

CALLED BY:	NDObjectPopUp

PASS:		*ds:si - NDFolderClass object
		es    - segment of the locked down folderBuffer 

RETURN:		cxdx - double word of GlobalMenuBitfield flags

		carry	- clear: more than one item selected, or item not opened
			- set:   a single opened item was selected

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	09/02/92	Initial version
	dlitwin 12/28/92	Added special Desktop popup support
	dlitwin 03/26/93	Added single opened popup support, removed
				Desktop popup support, as it isn't necessary
				anymore.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDGetFlagsForMultipleSelections	proc near
	uses	ax, bx, bp, di
	class	NDFolderClass
	.enter

	DerefFolderObject	ds, si, di
	mov	di, ds:[di].FOI_selectList
EC <	call	ECCheckFolderRecordESDI			>
	mov	bp, es:[di].FR_desktopInfo.DI_objectType
	call	NDValidateWOT

	call	NDCheckDriveType
	clr	ax				; move flags into cxdx
	call	NDGetGlobalMenuFlagsForWOT

BA<	call	BABookmarksMenuItemCheck	; bp is WOT of object	>
BA<	call	BACreateFolderMenuItemCheck				>
	call	NDOpenedMenuItemCheck
BA<	clr	bx					; no deletes yet>
BA<	call	BAStoreGenericDeleteInfo				>

	test	es:[di].FR_state, mask FRSF_OPENED
	jz	notOpened

	mov	di, es:[di].FR_selectNext
	cmp	di, NIL					; if multiple selections
	jne	multipleItems
	;
	;  Single, Opened item.
	;
	call	NDWastebasketMenuItemCheck		; single opened file
	stc						;  so return carry set
	jmp	exit

notOpened:
	mov	di, es:[di].FR_selectNext
	cmp	di, NIL					; if single selection
	je	notMultiple				; skip non-multiples

multipleItems:
	;
	; Anding cxdx with 0's for non-multiple items.  These items do not
	; show up if there are multiple items selected, only for single items.
	;
	and	cx, not(NON_MULTIPLE_MENU_ITEMS_HIGH)
	and	dx, not(NON_MULTIPLE_MENU_ITEMS_LOW)
NDONLY<	mov	ax, -1			; and flags with cxdx in this loop >

andLoop:
	mov	bp, es:[di].FR_desktopInfo.DI_objectType
	call	NDValidateWOT

NDONLY<	call	NDGetGlobalMenuFlagsForWOT				>
BA<	call	BAStoreGenericDeleteInfo				>

BA<	call	BABookmarksMenuItemCheck	; bp is WOT of object	>
BA<	call	BACreateFolderMenuItemCheck				>
	call	NDOpenedMenuItemCheck

	mov	di, es:[di].FR_selectNext
	cmp	di, NIL
	jne	andLoop

BA<	call	BASetGenDeleteIfNeeded					>
	call	NDClearSortViewUI
notMultiple:
	call	NDWastebasketMenuItemCheck
	clc						; not the Desktop
exit:
	.leave
	ret
NDGetFlagsForMultipleSelections	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDClearSortViewUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In the event of all the selected objects being opened, the
		Sort and View menus will be present, but as the UI now
		applies to multiple folders, having it show a certain
		selection doesn't make any sense, as all the folders might
		be Viewed or Sorted in different ways.  Because of this we
		don't show any selected Sort or View styles  when mulitple
		objects are all open.

CALLED BY:	NDGetFlagsForMultipleSelections

PASS:		cxdx - GlobalMenuBitfield flags for the selection
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDClearSortViewUI	proc	near
	uses	ax,bx,cx,dx,si,di,bp

	;
	; if any one of the selections is not Opened, then GMBL_SORT won't 
	; be set (as it is an opened item type) and so if it is set then we
	; know that all are set.  Of course if the multiple menu doesn't
	; contain Sort and View, this doesn't matter either.  There is nothing
	; we can do about the "Hidden" attribute, as it is either "on" or
	; "off".  We just leave it alone.  Sigh.
	;	We do this check outside of the .enter so we don't push and
	; pop all those registers for nothing if we fail (probably most of
	; the time).
	;
	test	dx, mask GMBL_SORT
	jz	exit
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_SET_INDETERMINATE_STATE
	mov	bx, handle GlobalMenuDisplayViewModes
	mov	si, offset GlobalMenuDisplayViewModes
	mov	cl, 1
	call	ObjMessageNone

	mov	ax, MSG_GEN_ITEM_GROUP_SET_INDETERMINATE_STATE
	mov	bx, handle GlobalMenuDisplaySortByList
	mov	si, offset GlobalMenuDisplaySortByList
	mov	cl, 1
	call	ObjMessageNone

	.leave
exit:
	ret
NDClearSortViewUI	endp


if _NEWDESKBA
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BAStoreGenericDeleteInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the current FolderRecord's menu flags for
		GMBL_THROW_AWAY, GMBL_DELETE, GMBH_DEL_STUDENT,
		GMBH_DEL_CLASS and sets the GMBH_GENERIC_DELETE flag
		if more than one is set.

CALLED BY:	NDGetFlagsForMultipleSelections

PASS:		bp	- NewDeskObjectType
		bx	- flags of previous menu items.
		cxdx	- dword of GlobalMenuBitfield flags

RETURN:		bx	- set with flag if that flag is set for this file
		cxdx	- anded with correct flags for bp object

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BAStoreGenericDeleteInfo	proc	near
	uses	ax, di, bp
	.enter

	shl	bp, 1				; make word -> dword
	mov	di, ss:[baUserTypeIndex]	; get UserType index
	add	bp, cs:[BAPopUpTablesTable][di]	; add table offset to WOT
	mov	ax, cs:[bp].GMB_low

	test	ax, mask GMBL_THROW_AWAY
	jz	notThrowAway
	or	bx, 1

notThrowAway:
	test	ax, mask GMBL_DELETE
	jz	notDelete
	or	bx, 2

notDelete:
	and	dx, ax
	mov	ax, cs:[bp].GMB_high

	test	ax, mask GMBH_DEL_STUDENT
	jz	notDelStudent
	or	bx, 4

notDelStudent:
	test	ax, mask GMBH_DEL_CLASS
	jz	notDelClass
	or	bx, 8

notDelClass:
	and	cx, ax

	.leave
	ret
BAStoreGenericDeleteInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BASetGenDeleteIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the Generic Delete flag if more than one of the delete
		flags is set.

CALLED BY:	NDGetFlagsForMultipleSelections

PASS:		bx	- 1 bit set/clear (bits 1-4) for each delete flag
				(order is totally irrelavent)
		cxdx	- doubleword of GlobalMenuBitfield flags.

RETURN:		cxdx	- updated with GMBH_GENERIC_DELETE set if necessary

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BASetGenDeleteIfNeeded	proc	near
	.enter

	clr	ax				; start with no flags

	test	bx, 1
	jz	bit2
	inc	ax
bit2:
	test	bx, 2
	jz	bit3
	inc	ax
bit3:
	test	bx, 4
	jz	bit4
	inc	ax
bit4:
	test	bx, 8
	jz	gotFlagCount
	inc	ax
gotFlagCount:
	cmp	ax, 2				; if any more than one men item
	jl	noChange			;  should be shown, show generic

	or	cx, mask GMBH_GENERIC_DELETE

noChange:
	.leave
	ret
BASetGenDeleteIfNeeded	endp
endif		; if _NEWDESKBA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDSetGlobalMenuFromFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets items in the GlobalMenu usable or notUsable depending
		on what flags are passed in.

CALLED BY:	NDObjectPopUp, NDWhiteSpacePopUp

PASS:		cxdx - GlobalMenuBitfield
		ds - object block

RETURN:		GlobalMenu and globalMenuState updated appropriately
		carry	- set if all menus have been set not usable
			- clear if there are menus usable in the popup

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	09/02/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDSetGlobalMenuFromFlags	proc	near
	uses	si, di, bp
	.enter

	xor	cx, ss:[globalMenuState].GMB_high	; get differing items
	xor	dx, ss:[globalMenuState].GMB_low	; get differing items
	xor	ss:[globalMenuState].GMB_high, cx	; place new state in mem
	xor	ss:[globalMenuState].GMB_low, dx	; place new state in mem

	tst	ss:[globalMenuState].GMB_high
	jnz	setUI
	tst	ss:[globalMenuState].GMB_low
	jnz	setUI
							; if nothing in popup,
	xor	ss:[globalMenuState].GMB_high, cx	; restore old menu state
	xor	ss:[globalMenuState].GMB_low, dx	;  in mem because we
							;  won't change ui
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle NDNoPopUpMenuItems
	mov	si, offset NDNoPopUpMenuItems
	call	ObjMessageCallFixup
	stc
	jmp	exit

setUI:
	clr	di
	mov	bp, END_OF_GLOBAL_MENU_ITEM_TABLE	; length of table
loopTop:
	test	dx, 1					; item to toggle?
	jz	noChange
	mov	si, cs:[NDGlobalMenuItemTable][di]
	tst	si
	jz	noChange
	call	NDToggleGlobalMenuItemsUsability
noChange:
	shrdw	cxdx					; next bit
	inc	di
	inc	di					; next item
	dec	bp
	tst	bp
	jnz	loopTop

	clc
exit:
	.leave
	ret
NDSetGlobalMenuFromFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDToggleGlobalMenuItemsUsability
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle the usability of a item in the GlobalMenu.

CALLED BY:	NDSetGlobalMenuFromFlags

PASS:		si - offset to GlobalMenu item in the GlobalMenuResource
		ds - object block

RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	09/02/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDToggleGlobalMenuItemsUsability	proc	near
	uses	ax, bx, cx, dx, bp, di
	.enter

	mov	ax, MSG_GEN_GET_USABLE
	mov	bx, handle GlobalSortViewMenuResource
	cmp	si, offset GlobalMenuSortAndView
	je	gotHandle
	mov	bx, handle GlobalMenuResource
gotHandle::
	call	ObjMessageCallFixup
	mov	ax, MSG_GEN_SET_NOT_USABLE
	jc	gotMessage
	mov	ax, MSG_GEN_SET_USABLE
gotMessage:
	mov	dl, VUM_NOW
	call	ObjMessageCallFixup
	.leave
	ret
NDToggleGlobalMenuItemsUsability	endp


NDGlobalMenuItemTable	label	word
	word	offset	GlobalMenuOpen			; GMBL_OPEN
	word	offset	GlobalMenuHelp			; GMBL_HELP
	word	offset	GlobalMenuWastebasket		; GMBL_WASTEBASKET
	word	offset	GlobalMenuDrive			; GMBL_DRIVE
	word	offset	GlobalMenuDriveRescanDrive	; GMBL_RESCAN_DRIVE
	word	offset	GlobalMenuPrinter		; GMBL_PRINTER
BA<	word	offset	GlobalMenuLogoutGroup		; GMBL_LOGOUT >
NDONLY<	word	offset	GlobalMenuLogout		; GMBL_LOGOUT >
;	word	offset	GlobalMenuOptions		; GMBL_OPTIONS
	word	0
	word	offset	GlobalMenuCopy			; GMBL_COPY
	word	offset	GlobalMenuMove			; GMBL_MOVE
	word	offset	GlobalMenuRename		; GMBL_RENAME
	word	offset	GlobalMenuDelete		; GMBL_DELETE
	word	offset	GlobalMenuThrowAway		; GMBL_THROW_AWAY
	word	offset	GlobalMenuSelectAll		; GMBL_SELECT_ALL
	word	offset	GlobalSortViewMenuResource:GlobalMenuSortAndView
							; GMBL_SORT
	word	offset	GlobalMenuCreateFolder		; GMBL_CREATE_FOLDER
	word	offset	GlobalMenuClose			; GMBH_CLOSE
	word	offset	GlobalMenuPrint			; GMBH_PRINT
	word	offset	GlobalMenuDuplicate		; GMBH_DUPLICATE
	word	offset	GlobalMenuRecover		; GMBH_RECOVER
BA<	word	offset	GlobalMenuRemoveStudent		; GMBH_DEL_STUDENT    >
BA<	word	offset	GlobalMenuRemoveClass		; GMBH_DEL_CLASS      >
BA<	word	offset	GlobalMenuGenericDelete		; GMBH_GENERIC_DELETE >
BA<	word	offset	GlobalMenuHomeFolder		; GMBH_HOME	      >
BA<	word	offset	GlobalMenuChangeIcon		; GMBH_CHANGE_ICON    >
BA<	word	offset	GlobalMenuClassesFolder		; GMBH_CLASSES	      >
BA<	word	offset	GlobalMenuClassFolder		; GMBH_CLASS	      >
BA<	word	offset	GlobalMenuAddStudent		; GMBH_ADD_STUDENT    >
BA<	word	offset	GlobalMenuMakeStudentUtilDrive	; GMBH_MAKE_STD_DRIVE >
BA<	word	offset	GlobalMenuBookmarks		; GMBH_BOOKMARKS      >
BA<	word	offset	GlobalMenuDistribute		; GMBH_DISTRIBUTE     >
BA<	word	offset	GlobalMenuRemoveFiles		; GMBH_REMOVE_FILES   >

END_OF_GLOBAL_MENU_ITEM_TABLE = ($-NDGlobalMenuItemTable)/(size word)




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDGetGlobalMenuFlagsForWOT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the menu flags for a WOT into cxdx.  If Wizard (newdeskba)
		the the user type will be passed in ah and used accordingly.

CALLED BY:	NDWhiteSpacePopUp, NDObjectPopUp

PASS:		bp - WOT of object to get flags for
		ax	- 0 to set cxdx to the flags
			- non-zero to and cxdx with the flags
		es:di - FolderRecord

RETURN:		cxdx - GlobalMenuBitfield struct

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/03/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDGetGlobalMenuFlagsForWOT	proc	near
	uses	bx, bp
	.enter

	shl	bp, 1				; make word -> dword

NDONLY<	add	bp, (offset NDPopUpTable)+(2*OFFSET_FOR_WOT_TABLES)	>

BA<	mov	bx, ss:[baUserTypeIndex]				>
BA<	add	bp, cs:[BAPopUpTablesTable][bx]	; add table offset to WOT >

	tst	ax
	jnz	andFlags

	movdw	cxdx, cs:[bp]
	jmp	exit

andFlags:
	and	cx, cs:[bp].GMB_high
	and	dx, cs:[bp].GMB_low

exit:
	.leave
	ret

NDGetGlobalMenuFlagsForWOT	endp


if _NEWDESKBA
BAPopUpTablesTable	label	word
	word	(offset NDPopUpTable) + (2*OFFSET_FOR_WOT_TABLES)
							; UT_GENERIC
	word	(offset NDPopUpTable) + (2*OFFSET_FOR_WOT_TABLES)
							; UT_STUDENT
	word	(offset BATeacherPopUpTable) + (2*OFFSET_FOR_WOT_TABLES)
							; UT_ADMIN
	word	(offset BATeacherPopUpTable) + (2*OFFSET_FOR_WOT_TABLES)
							; UT_TEACHER
	word	(offset BAOfficePopUpTable) + (2*OFFSET_FOR_WOT_TABLES)
							; UT_OFFICE
endif		; if _NEWDESKBA


;-----------------------------------------------------------------------
;		PopUp Menu Tables
;	These tables determine which menu items occur for which objects.
;-----------------------------------------------------------------------
;
; This table defines the standard menu items to come up in the popup menu
; of each of the NewDeskObjectTypes.
;
NDPopUpTable	label	GlobalMenuBitfield
if _NEWDESKBA
	GlobalMenuBitfield	<			; WOT_STUDENT_UTILITY
		GM_STUDENT_UTILITY_MENUS_LOW,
		GM_STUDENT_UTILITY_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_OFFICE_COMMON
		GM_OFFICE_COMMON_MENUS_LOW,
		GM_OFFICE_COMMON_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_COMMON
		GM_TEACHER_COMMON_MENUS_LOW,
		GM_TEACHER_COMMON_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_OFFICE_HOME
		GM_OFFICE_HOME_MENUS_LOW,
		GM_OFFICE_HOME_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_COURSE
		GM_STUDENT_CLASS_MENUS_LOW,
		GM_STUDENT_CLASS_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_HOME
		GM_STUDENT_HOME_MENUS_LOW,
		GM_STUDENT_HOME_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_GEOS_COURSEWARE
		GM_GEOS_COURSEWARE_MENUS_LOW,
		GM_GEOS_COURSEWARE_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DOS_COUSEWARE
		GM_DOS_COURSEWARE_MENUS_LOW,
		GM_DOS_COURSEWARE_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_OFFICEAPP_LIST
		GM_OFFICE_APP_LIST_MENUS_LOW,
		GM_OFFICE_APP_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_SPECIALS_LIST
		GM_SPECIALS_LIST_MENUS_LOW,
		GM_SPECIALS_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_COURSEWARE_LIST
		GM_COURSEWARE_LIST_MENUS_LOW,
		GM_COURSEWARE_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_PEOPLE_LIST
		GM_STUDENT_BODY_LIST_MENUS_LOW,
		GM_STUDENT_BODY_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_CLASSES
		GM_STUDENT_CLASSES_MENUS_LOW,
		GM_STUDENT_CLASSES_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_HOME_TVIEW
		GM_STUDENT_MENUS_LOW,
		GM_STUDENT_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_COURSE
		GM_TEACHER_CLASS_MENUS_LOW,
		GM_TEACHER_CLASS_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_ROSTER
		GM_ROSTER_MENUS_LOW,
		GM_ROSTER_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_CLASSES
		GM_TEACHER_CLASSES_MENUS_LOW,
		GM_TEACHER_CLASSES_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_HOME
		GM_TEACHER_HOME_MENUS_LOW,
		GM_TEACHER_HOME_MENUS_HIGH
	>
endif		; if _NEWDESKBA
	GlobalMenuBitfield	<			; WOT_FOLDER
		GM_FOLDER_MENUS_LOW,
		GM_FOLDER_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DESKTOP
		GM_DESKTOP_MENUS_LOW,
		GM_DESKTOP_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_PRINTER
		GM_PRINTER_MENUS_LOW,
		GM_PRINTER_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_WASTEBASKET
		GM_WASTEBASKET_MENUS_LOW,
		GM_WASTEBASKET_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DRIVE
		GM_DRIVE_MENUS_LOW,
		GM_DRIVE_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DOCUMENT
		GM_DOCUMENT_MENUS_LOW,
		GM_DOCUMENT_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_EXECUTABLE
		GM_EXECUTABLE_MENUS_LOW,
		GM_EXECUTABLE_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_HELP
		GM_HELP_MENUS_LOW,
		GM_HELP_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_LOGOUT
		GM_LOGOUT_MENUS_LOW,
		GM_LOGOUT_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_SYSTEM_FOLDER
		GM_SYSTEM_FOLDER_MENUS_LOW,
		GM_SYSTEM_FOLDER_MENUS_HIGH
	>

.assert (($ - NDPopUpTable) eq					\
	 ((NewDeskObjectType + OFFSET_FOR_WOT_TABLES) * 2))
; we multiply by two because this table's entries are dwords, and
; the NewDeskObjectType is a word.


if _NEWDESKBA
;-----------------------------------------------------------------------------
; This table defines a teacher's menu items to come up in the popup menu
; of each of the NewDeskObjectTypes.
;-----------------------------------------------------------------------------
BATeacherPopUpTable	label	GlobalMenuBitfield

	GlobalMenuBitfield	<			; WOT_STUDENT_UTILITY
		GM_STUDENT_UTILITY_MENUS_LOW,
		GM_STUDENT_UTILITY_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_OFFICE_COMMON
		GM_OFFICE_COMMON_MENUS_LOW,
		GM_OFFICE_COMMON_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_COMMON
		GM_TEACHER_COMMON_MENUS_LOW,
		GM_TEACHER_COMMON_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_OFFICE_HOME
		GM_OFFICE_HOME_MENUS_LOW,
		GM_OFFICE_HOME_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_COURSE
		GM_STUDENT_CLASS_MENUS_LOW,
		GM_STUDENT_CLASS_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_HOME
		GM_STUDENT_HOME_MENUS_LOW,
		GM_STUDENT_HOME_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_GEOS_COURSEWARE
		TEACHER_GEOS_COURSEWARE_LOW,
		TEACHER_GEOS_COURSEWARE_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DOS_COUSEWARE
		TEACHER_DOS_COURSEWARE_LOW,
		TEACHER_DOS_COURSEWARE_HIGH
	>
	GlobalMenuBitfield	<			; WOT_OFFICEAPP_LIST
		GM_OFFICE_APP_LIST_MENUS_LOW,
		GM_OFFICE_APP_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_SPECIALS_LIST
		GM_SPECIALS_LIST_MENUS_LOW,
		GM_SPECIALS_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_COURSEWARE_LIST
		GM_COURSEWARE_LIST_MENUS_LOW,
		GM_COURSEWARE_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_PEOPLE_LIST
		GM_STUDENT_BODY_LIST_MENUS_LOW,
		GM_STUDENT_BODY_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_CLASSES
		GM_STUDENT_CLASSES_MENUS_LOW,
		GM_STUDENT_CLASSES_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_HOME_TVIEW
		GM_STUDENT_MENUS_LOW,
		GM_STUDENT_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_COURSE
		GM_TEACHER_CLASS_MENUS_LOW,
		GM_TEACHER_CLASS_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_ROSTER
		GM_ROSTER_MENUS_LOW,
		GM_ROSTER_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_CLASSES
		GM_TEACHER_CLASSES_MENUS_LOW,
		GM_TEACHER_CLASSES_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_HOME
		GM_TEACHER_HOME_MENUS_LOW,
		GM_TEACHER_HOME_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_FOLDER
		TEACHER_FOLDER_MENUS_LOW,
		TEACHER_FOLDER_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DESKTOP
		GM_DESKTOP_MENUS_LOW,
		GM_DESKTOP_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_PRINTER
		GM_PRINTER_MENUS_LOW,
		GM_PRINTER_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_WASTEBASKET
		GM_WASTEBASKET_MENUS_LOW,
		GM_WASTEBASKET_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DRIVE
		GM_DRIVE_MENUS_LOW,
		GM_DRIVE_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DOCUMENT
		TEACHER_DOCUMENT_MENUS_LOW,
		TEACHER_DOCUMENT_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_EXECUTABLE
		TEACHER_EXECUTABLE_MENUS_LOW,
		TEACHER_EXECUTABLE_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_HELP
		GM_HELP_MENUS_LOW,
		GM_HELP_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_LOGOUT
		GM_LOGOUT_MENUS_LOW,
		GM_LOGOUT_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_SYSTEM_FOLDER
		GM_SYSTEM_FOLDER_MENUS_LOW,
		GM_SYSTEM_FOLDER_MENUS_HIGH
	>

.assert (($ - BATeacherPopUpTable) eq					\
	 ((NewDeskObjectType + OFFSET_FOR_WOT_TABLES) * 2))


;-----------------------------------------------------------------------------
; This table defines a office worker's menu items to come up in the popup menu
; of each of the NewDeskObjectTypes.
;-----------------------------------------------------------------------------
BAOfficePopUpTable	label	GlobalMenuBitfield

	GlobalMenuBitfield	<			; WOT_STUDENT_UTILITY
		GM_STUDENT_UTILITY_MENUS_LOW,
		GM_STUDENT_UTILITY_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_OFFICE_COMMON
		GM_OFFICE_COMMON_MENUS_LOW,
		GM_OFFICE_COMMON_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_COMMON
		GM_TEACHER_COMMON_MENUS_LOW,
		GM_TEACHER_COMMON_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_OFFICE_HOME
		GM_OFFICE_HOME_MENUS_LOW,
		GM_OFFICE_HOME_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_COURSE
		GM_STUDENT_CLASS_MENUS_LOW,
		GM_STUDENT_CLASS_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_HOME
		GM_STUDENT_HOME_MENUS_LOW,
		GM_STUDENT_HOME_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_GEOS_COURSEWARE
		OFFICE_GEOS_COURSEWARE_LOW,
		OFFICE_GEOS_COURSEWARE_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DOS_COUSEWARE
		OFFICE_DOS_COURSEWARE_LOW,
		OFFICE_DOS_COURSEWARE_HIGH
	>
	GlobalMenuBitfield	<			; WOT_OFFICEAPP_LIST
		GM_OFFICE_APP_LIST_MENUS_LOW,
		GM_OFFICE_APP_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_SPECIALS_LIST
		GM_SPECIALS_LIST_MENUS_LOW,
		GM_SPECIALS_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_COURSEWARE_LIST
		GM_COURSEWARE_LIST_MENUS_LOW,
		GM_COURSEWARE_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_PEOPLE_LIST
		GM_STUDENT_BODY_LIST_MENUS_LOW,
		GM_STUDENT_BODY_LIST_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_CLASSES
		GM_STUDENT_CLASSES_MENUS_LOW,
		GM_STUDENT_CLASSES_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_STUDENT_HOME_TVIEW
		GM_STUDENT_MENUS_LOW,
		GM_STUDENT_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_COURSE
		GM_TEACHER_CLASS_MENUS_LOW,
		GM_TEACHER_CLASS_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_ROSTER
		GM_ROSTER_MENUS_LOW,
		GM_ROSTER_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_CLASSES
		GM_TEACHER_CLASSES_MENUS_LOW,
		GM_TEACHER_CLASSES_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_TEACHER_HOME
		GM_TEACHER_HOME_MENUS_LOW,
		GM_TEACHER_HOME_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_FOLDER
		GM_FOLDER_MENUS_LOW,
		GM_FOLDER_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DESKTOP
		GM_DESKTOP_MENUS_LOW,
		GM_DESKTOP_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_PRINTER
		GM_PRINTER_MENUS_LOW,
		GM_PRINTER_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_WASTEBASKET
		GM_WASTEBASKET_MENUS_LOW,
		GM_WASTEBASKET_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DRIVE
		GM_DRIVE_MENUS_LOW,
		GM_DRIVE_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_DOCUMENT
		GM_DOCUMENT_MENUS_LOW,
		GM_DOCUMENT_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_EXECUTABLE
		GM_EXECUTABLE_MENUS_LOW,
		GM_EXECUTABLE_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_HELP
		GM_HELP_MENUS_LOW,
		GM_HELP_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_LOGOUT
		GM_LOGOUT_MENUS_LOW,
		GM_LOGOUT_MENUS_HIGH
	>
	GlobalMenuBitfield	<			; WOT_SYSTEM_FOLDER
		GM_SYSTEM_FOLDER_MENUS_LOW,
		GM_SYSTEM_FOLDER_MENUS_HIGH
	>

.assert (($ - BAOfficePopUpTable) eq					\
	 ((NewDeskObjectType + OFFSET_FOR_WOT_TABLES) * 2))

endif		; if _NEWDESKBA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderSetPopupType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the folder's NDFOI_popUpType instance data.

CALLED BY:	MSG_ND_FOLDER_SET_POPUP_TYPE
PASS:		*ds:si	= NDFolderClass object
		ds:di	= NDFolderClass instance data
		cl	= NewDeskPopUpType

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderSetPopupType	method dynamic NDFolderClass, 
					MSG_ND_FOLDER_SET_POPUP_TYPE
	.enter

	mov	ds:[di].NDFOI_popUpType, cl

	.leave
	ret
NDFolderSetPopupType	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderSendAsWhitespace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This is a message that is used by the drop-down template
		menus of each folderwindow's primary.  These messages go
		directly to the folder object by because they are  sent to 
		TO_OBJ_BLOCK_OUTPUT which is connected to their personal
		folder object.  This sets the folder's popUpType to 
		whitespace (because dropdown menus are the same as white-
		space menus) and then sends the message, so the folder
		thinks it received it from a whitespace click.

PASS:		*ds:si	- NDFolderClass object
		ds:di	- NDFolderClass instance data
		cx	- message to send to dummy or real object
		dx	- message data to pass in cx when sending message

RETURN:		nothing 

DESTROYED:	all

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderSendAsWhitespace	method	dynamic	NDFolderClass,
					MSG_ND_FOLDER_SEND_AS_WHITESPACE
	mov	ds:[di].NDFOI_popUpType, WPUT_WHITESPACE
	mov	ax, cx				; put message into ax
	mov	cx, dx				; put data into cx
	call	ObjCallInstanceNoLock
	ret
NDFolderSendAsWhitespace	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderSendAsSelectedItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This is a message that is used by those wanting to send
	a message to a folder as if it were sent by a popup from a
	selected list of files.  It takes bp as a DesktopErrors error to
	display in the event that no files were selected.  If bp is zero,
	it will procede with sending the message despite its better
	judgement in the case of nothing selected.  It sets the popUpType
	of the folder to WPUT_SELECTION to fool the folder into thinking
	that the message came from a selection popup.

PASS:		*ds:si	- NDFolderClass object
		ds:bx	- NDFolderClass instance data
		cx	- message to send to dummy or real object
		dx	- message data to pass in cx when sending message
		bp	- error code (DesktopErrors) to display if no file
				is selected

RETURN:		nothing 

DESTROYED:	all

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderSendAsSelectedItems	method	dynamic	NDFolderClass,
					MSG_ND_FOLDER_SEND_AS_SELECTED_ITEMS

	tst	bp				; if no error message, skip
	jz	pastSelectionCheck		;  the error cases and send.

	cmp	ds:[di].FOI_selectList, NIL
	je	error

	tst	ds:[di].FOI_buffer
	jz	error

pastSelectionCheck:
	mov	ds:[di].NDFOI_popUpType, WPUT_SELECTION
	mov	ax, cx				; put message into ax
	mov	cx, dx				; put data into cx
	call	ObjCallInstanceNoLock
	jmp	done

error:
	mov	ax, bp				; put error code into ax
	call	DesktopOKError
done:
	ret
NDFolderSendAsSelectedItems	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderSendAsSingleSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This is a message that is used by those wanting to send
	a message to a folder as if it were sent from a single (for
	multiple see MSG_ND_FOLDER_SEND_AS_SELECTED_ITEMS) selected file.
	This is *not* the WPUT_OBJECT case, because that is a non-selected
	file, and depends on the mouse pointer, so it will be handled
	by a PopUp menu.
		It takes bp as a DesktopErrors error to display in the
	event that no files were selected.  If this is zero, it will
	procede with sending the message despite its better judgement in
	the case of nothing selected.  It sets the popUpType of the folder
	to WPUT_SELECTION to fool the folder into thinking that the message
	came from a selection popup.


PASS:		*ds:si	- NDFolderClass object
		ds:bx	- NDFolderClass instance data
		cx	- message to send
		dx	- message data to pass in cx when sending message
		bp	- error code (DesktopErrors) to display if no file
				is selected

RETURN:		nothing 

DESTROYED:	all

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderSendAsSingleSelection	method	dynamic	NDFolderClass,
					MSG_ND_FOLDER_SEND_AS_SINGLE_SELECTION

	tst	bp				; if no error message, skip
	jz	pastSelectionCheck		;  the error cases and send.

	mov	di, ds:[bx].FOI_selectList
	cmp	di, NIL
	je	error

	call	FolderLockBuffer
	jz	error

	cmp	es:[di].FR_selectNext, NIL	; only one item?
	call	FolderUnlockBuffer
	jne	error				; error if not single selection

pastSelectionCheck:
	mov	ds:[bx].NDFOI_popUpType, WPUT_SELECTION
	mov	ax, cx				; put message into ax
	mov	cx, dx				; put data into cx
	GOTO	ObjCallInstanceNoLock		; EXIT

		
error:
	mov	ax, bp				; put error code into ax
	call	DesktopOKError
	ret
NDFolderSendAsSingleSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderSendFromPopUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This is a message that enumerates through the selected
	files of a folder (this selection may not be the true selection,
	but the false selection built out because of a WPUT_OBJECT or
	WPUT_WHITESPACE).  This is called only from triggers in the popUp
	menu (the GlobalMenu,  in which case the popUpType will be set
	correctly, meaning that there will be a selection if the popUpType
	is WPUT_SELECTION) or if sent as data to a
	MSG_ND_FOLDER_SEND_AS_SELECTED_ITEMS or
	MSG_ND_FOLDER_SEND_AS_SINGLE_SELECTION in which case the
	WPUT_SELECTION will be set as well.
		For each item it sends a passed in message (and data in cx)
	to the object or (if the object is not open) the dummy object
	corresponding to the type of the selection (after stuffing the
	path of the dummy object with the path of the selection).

PASS:		*ds:si	- NDFolderClass object
		ds:bx	- NDFolderClass instance data
		cx	- message to send to dummy or real object
		dx	- message data to pass in cx when sending message

RETURN:		nothing 

DESTROYED:	all

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/25/92   	Initial version.
	dlitwin	11/16/92	renamed from NDFolderSendToSelected

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderSendFromPopUp	method	dynamic	NDFolderClass,
						MSG_ND_FOLDER_SEND_FROM_POPUP

	cmp	ds:[bx].NDFOI_popUpType, WPUT_WHITESPACE
	jne	sendToObject		; if they clicked in whitespace, then
					;  we send the message to ourselves
	mov	ax, cx				; put message into ax
	mov	cx, dx				; put data into cx
	GOTO	ObjCallInstanceNoLock

	;
	; if they clicked on something selected, start with the
	; ND_selectionList and loop through all selected.  If they clicked on
	; a non selected object, start with the NDFOI_nonSelect, and it will
	; not loop further, as it will (by defintion) have no FR_selectNext.
	;	For each FolderRecord entry, call SendToOpenedOrDummy, which
	; will send the message passed in (in cx) to the object belonging to
	; the item (glyph) or a dummy object of the same WOT and stuffed with
	; the path of the item.
	;
sendToObject:				
	mov	di, ds:[bx].FOI_selectList
	cmp	ds:[bx].NDFOI_popUpType, WPUT_SELECTION
	je	gotFirstObject
	mov	di, ds:[bx].NDFOI_nonSelect

gotFirstObject:
	call	FolderLockBuffer
	jz	done

sendLoop:
	call	SendToOpenedOrDummy
	mov	di, es:[di].FR_selectNext
	cmp	di, NIL
	jne	sendLoop

	call	FolderUnlockBuffer
done:
	.leave
	ret
NDFolderSendFromPopUp	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToOpenedOrDummy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This routine takes a NDFolderObject or subclass, an item
		in its list of files and a message to send.
			If the item is of a NDFolder type or subclass
		that has been opened on the screen it will send its message
		to that object.  If it has not been opened it will send
		the message to a dummy object of the same WOT that has been
		stuffed with the path of the item.

PASS:		*ds:si	- NDFolderClass object
		es:di	- FolderRecord of item
		cx	- message to send to dummy or real object
		dx	- message data to send in cx with message

RETURN:		carry clear if OK
		      set on error (ax is FileError)

DESTROYED:	ax, bx, bp

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToOpenedOrDummy	proc	near
	uses	cx, dx, ds, si, es, di
	.enter

EC <	call	ECCheckFolderObjectDSSI		>
EC <	call	ECCheckFolderRecordESDI		>

	call	CheckAndHandleNonFolderWOT
	LONG	jnc	exit				; carry clear if handled
							;  set if folder WOT
	clc						; clear carry

	call	FilePushDir
	call	Folder_GetDiskAndPath
	push	dx					; save message data
	lea	dx, ds:[bx].GFP_path			; ds:dx is path
	mov	bx, ax					; diskhandle in bx
	call	FileSetCurrentPath
	pop	bp					; put data into bp
	LONG jc	errorExit

	mov	ax, sp					; get pre-buffer pos.
	sub	sp, size PathName			; allocate stack buffer
	mov	dx, sp					; ss:dx is stack buffer
	push	ax					; save pre-buffer pos.
	push	bp					; save message + data
	push	cx
	;
	; Build out the full path to test if it is already opened and 
	; to stuff the dummy object with if not.
	;	  **NOTE**
	; This is done despite the immediate call to FileConstructActualPath
	; done inside of FindFolderWindow, because later this path will be
	; used if we need to set the path of the dummy.  Setting the dummy
	; with the returned Actualpath that FindFolderWindow gives us (which
	; we promptly free) would not imitate the object we want, but what
	; the object we want might point to (be a link to). dlitwin 3/26/93
	;

	call	NDGetDriveNumberFromFolderRecord	; drive number -> al
	segmov	ds, es, si
CheckHack< offset FR_name eq 0 >
	mov	si, di				; ds:si is file name
	clr	bx				; use current dir
	segmov	es, ss, di
	mov	di, dx				; es:di is stack buffer
	mov	bp, dx				; save buff pos in bp
	clr	dx				; no <drivename:> needed
	mov	cx, size PathName		; size of buffer
	;
	;	Yes, FileConstruct*Full*Path is used, not
	; FileConstruct*Actual*Path is used here, as we don't want the path
	; of a potential link's target, but the path of the object itself.
	;
	call	FileConstructFullPath
	jc	gotObject			; exit if error

	mov	cx, bx				; put diskhandle in cx
	mov	dx, ss				; cx, dx:bp is path

	cmp	ds:[si].FR_desktopInfo.DI_objectType, WOT_DRIVE
	jne	notDrive

	call	FindOpenDriveWindow
	cmc
	jc	getDummy			; send to Dummy if not found
	jmp	gotObject

notDrive:
	mov	di, mask MF_CALL		; no fixup 'cause ds
	call	FindFolderWindow		; is not an object block
	call	ShellFreePathBuffer		;  nuke returned path buffer
	jnc	getDummy

	tst	bx
	jz	getDummy

	clc
	mov	si, FOLDER_OBJECT_OFFSET
	jmp	gotObject

getDummy:
	;
	; No object exists for this path, so stuff it into the dummy
	; object of the same type and send that the message.
	; Register usage:
	;	DS:SI	= FolderRecord
	;	AL	= Drive number (only if WOT_DRIVE)
	;	CX	= Disk handle
	;	DX:BP	= Path
	;
	mov	si, ds:[si].FR_desktopInfo.DI_objectType
	xchg	bp, si
	call	NDValidateWOT
	xchg	bp, si

	xchg	cx, bp				; bp - disk, cx - offset
	xchg	cx, dx				; cx - seg, dx - offset
	call	UtilGetDummyFromTableWithHelp	; ^lbx:si - dummy
	mov	ax, MSG_FOLDER_SET_PATH

	;
	; Don't bother stuffing the path if we're just trying to
	; display help (apparently).
	;
	XchgTopStack	dx
	cmp	dx, MSG_ND_FOLDER_HELP		; allow help w/o set path
	XchgTopStack	dx			; (preserves flags)
	je	gotObject			; (carry clear)
	push	di				; save path offset
	call	ObjMessageCall			; stuff path into dummy
	pop	di

	;
	; Send the message on to the object (or dummy object)
	;
gotObject:
	pop	dx				; restore message + data
	pop	cx
	jnc	sendMessage			; send message if no error

	cmp	dx, MSG_ND_DRIVE_FORMAT		; skip on error unless format
	stc					; make sure carry set for error
	jne	afterMessageSent		; (maybe an unformatted disk)

sendMessage:
	mov	ax, dx				; put message into ax
	call	ObjMessageForce			; send it off!

afterMessageSent:
	pop	ax				; pop pre-buffer pos.
	mov	sp, ax				; pop stack buffer

errorExit:
	call	FilePopDir
exit:
	.leave
	ret
SendToOpenedOrDummy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAndHandleNonFolderWOT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If a WOT is of a non folder nature (not openable) then it
		doesn't need to have its path set, or bother to check if it
		has already been opened.  This routine checks for this and
		sends off the message immediately if so.

CALLED BY:	SendToOpenedOrDummy

PASS:		*ds:si	- NDFolderClass object
		es:di	- FolderRecord of item
		cx	- message to send to dummy or real object
		dx	- message data to send in cx with message

RETURN:		carry set if folder type WOT (*not* handled)
		      clear if it *not* a folder type, handled

DESTROYED:	ax, bx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	2/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckAndHandleNonFolderWOT	proc	near
	uses	si, di
	.enter

EC <	call	ECCheckFolderObjectDSSI		>
EC <	call	ECCheckFolderRecordESDI			>

	mov	bp, es:[di].FR_desktopInfo.DI_objectType
	call	NDIsThisAFolderTypeWOT
	jc	exit

	mov	si, bp
	call	UtilGetDummyFromTable
	mov	ax, cx				; message into ax
	mov	cx, dx				; data into cx
	call	ObjMessageForce
	clc					; not a folder type WOT

exit:
EC<	Destroy ax, bx, bp >
	.leave
	ret
CheckAndHandleNonFolderWOT	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDIsThisAFolderTypeWOT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if an object is a folder type object or not.

CALLED BY:	CheckAndHandleNonFolderWOT, NDSetSortViewUIForOpenedFolder
 
PASS:		bp	- NewDeskObjectType
RETURN:		carry	- set if object is a folder type WOT
			- clear if it is *not* a folder type WOT
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDIsThisAFolderTypeWOT	proc	near
	.enter

	call	NDValidateWOT

BA<	cmp	bp, WOT_GEOS_COURSEWARE	>
BA<	je	notFolder		>
BA<	cmp	bp, WOT_DOS_COURSEWARE	>
BA<	je	notFolder		>

	cmp	bp, WOT_EXECUTABLE
	je	notFolder
	cmp	bp, WOT_DOCUMENT
	je	notFolder
	cmp	bp, WOT_HELP
	je	notFolder
	cmp	bp, WOT_LOGOUT
	stc					; assume a Folder type WOT
	jne	exit

notFolder:
	clc
exit:
	.leave
	ret
NDIsThisAFolderTypeWOT	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindOpenDriveWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the opened NDDriveFolder object corresponding to the
		path passed in.

CALLED BY:	SendToOpenedOrDummy

PASS:		ds:[si]	- FolderRecord of object to find
		current directory is that of the containing folder

RETURN:		carry	- clear if it wasn't found
				ds:[si] preserved as FolderRecord of object
				bx, si preserved as passed in 
			- set if it was found
				^lbx:si is object

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindOpenDriveWindow	proc	near
	uses	ax,cx,dx,di,bp,ds,es
	.enter

	push	bx, si					; save passed bx, si
CheckHack< offset FR_name eq 0 >
	mov	dx, si					; ds:dx is filename
		; current path, ds:dx is the drive link's path
	mov	cx, size PathName
	sub	sp, cx					; allocate stack buffer
	segmov	es, ss, di
	mov	di, sp					; es:di is the buffer
	call	FileReadLink

	segmov	ds, es
	mov	dx, sp					; ds:dx is link target
	call	FSDLockInfoShared
	mov	es, ax
	call	DriveLocateByName
	add	sp, size PathName			; pop buffer off stack 

	clr	ax					; make sure ah is zero
	mov	al, es:[si].DSE_number			; al is drive number
	call	FSDUnlockInfoShared

	mov	bp, ax					; bp is drive number
	clr	si					; init index into table
folderLoop:
	mov	bx, ss:[folderTrackingTable][si].FTE_folder.handle
	tst	bx
	jz	next

	push	si
	push	bp
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	cx, ss					; defined in dgroup
	mov	dx, offset NDDriveClass
	mov	si, ss:[folderTrackingTable][si].FTE_folder.chunk
	call	ObjMessageCall
	pop	bp
	jnc	notNDDriveClass				; skip if not a drive

	mov	ax, MSG_ND_DRIVE_CHECK_DRIVE_NUMBER
	call	ObjMessageCall			; carry set if same drive

notNDDriveClass:
	pop	ax				; get table offset
	jnc	notSameDrive

	pop	ax, ax				; clean up stack by getting
	jmp	done				; rid of passed bx, si

notSameDrive:
	mov	si, ax				; restore table offset to si
next:
	add	si, size FolderTrackingEntry		; move to next window
	cmp	si, MAX_NUM_FOLDER_WINDOWS * (size FolderTrackingEntry) ; end?
	jne	folderLoop				; if not, check next

	pop	bx, si				; restore passed bx, si
	clc
done:
	.leave
	ret
FindOpenDriveWindow	endp

NDFolderCode	ends


; Moved into separate resource for workset optimization -chrisb


FolderOpenCode	segment resource


if _NEWDESKBA
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BAConstrainDropDownMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes certain items in a drop down menu of a folder WOT
		not usable according to the UserType of the person
		viewing the menu.
			*NOTE*  This could have been put in the subclass
		handler of the MSG_ND_FOLDER_SETUP message for each WOT,
		in fact the NDDriveClass (WOT_DRIVE) does just that to
		determine format/copy permissions on different types of 
		drives.
			This was *NOT* handled this way because it would
		require handlers for every single WOT, and the tabling 
		scheme that is used is simple and flexible like the
		GlobalMenuBitfield tables.

CALLED BY:	NDFolderSetup

PASS:		*ds:si - NDFolderClass Object or subclass
		^lcx:dx - NDFolderWindow or subclass

RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	
	This is implemented by a table of tables of tables.
	UserType determines the first set of tables.  For each UserType
	there is a table for each WOT.  This table contains the offset
	to a final table that is a variable length list of offsets to menu
	items to be set not usable.  This final object offset list is
	variable length, terminated by a zero value.  Zero values in any
	other of the tables means there are no constraints for that
	UserType or UserType/WOT combination.

		AAARRRGGGHHH!!!   As it turns out this whole general,
	flexible architecture for menu restrictions (constraints) is 
	pretty much unneeded because constraints are only necessary in
	**very** few places.  While I could rip out all this code and
	replace it with a few special hacks, I'd rather leave it in as
	it doesn't take up much space (because of the lack of unnecessary
	tables) and is fairly quick (only a few memory references to 
	determine nothing needs to be constrained).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	1/6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BAConstrainDropDownMenu	method dynamic NDFolderClass,
					MSG_BA_CONSTRAIN_DROP_DOWN_MENU
	uses	ax, cx, dx, bp
	.enter

.assert segment BADropDownTableOfTablesTable eq @CurSeg
EC <	call	ECCheckFolderObjectDSSI		>

	;
	; Get Table 2 (table of tables) by indexing into
	; Table 1 (table of tables of tables) by UserType
	;
	mov	bx, cx				; template handle in bx

	mov	di, ds:[di].NDFOI_ndObjType
	mov	bp, ss:[baUserTypeIndex]
	mov	bp, cs:[BADropDownTableOfTablesTable][bp]
	tst	bp
	jz	noConstraint			; none for this UserType

	xchg	bp, di
	call	NDValidateWOT
	xchg	bp, di
	;
	; Get Table 3 (offset table) by indexing into Table 2
	; (table of tables) by WOT)
	;
	mov	bp, cs:[bp][di][OFFSET_FOR_WOT_TABLES]
	tst	bp
	jz	noConstraint			; none for this UserType/WOT
						;   combination
	;
	; Get first item by starting with the first item of Table 3
	;
	mov	si, cs:[bp]			; first item
	;
	; Loop through Table 3 (offset table) until a 0 is reached.
	;
removeLoop:
	tst	si
	jz	noConstraint			; all constraints satisfied
	push	bp, di
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	call	ObjMessageCall
	pop	bp, di
	inc	bp
	inc	bp
	mov	si, cs:[bp]
	jmp	removeLoop

	; di = WOT of folder being opened
	; bx = handle of template window block
noConstraint:
	call	IclasGetUserPermissions
	test	ax, mask UP_CREATE_FOLDER
	jnz	canCreateFolders

	mov	si, di
	call	BAGetCreateFolderOffset
	tst	si
	jz	canCreateFolders		; or has no CreateFolder...

	cmp	di, WOT_DESKTOP
	jne	gotHandle
	mov	bx, handle DesktopMenuCreateFolder
gotHandle:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	call	ObjMessageCall

canCreateFolders:
	.leave
	ret
BAConstrainDropDownMenu	endp


BADropDownTableOfTablesTable	word	\
	offset BAStudentDropDownTablesTable,		; UT_GENERIC
	offset BAStudentDropDownTablesTable,		; UT_STUDENT
	0,	;  no restrictions for an administrator	; UT_ADMIN
	0,	;  no restrictions for a teacher	; UT_TEACHER
	offset BAStudentDropDownTablesTable		; UT_OFFICE
		; it turns out the office worker has the very same
		; restriction that a student has...  ah well, someone 
		; might really use this damn scheme one day...

BAStudentDropDownTablesTable	word	\
	0,				; WOT_STUDENT_UTILITY
	0,				; WOT_OFFICE_COMMON
	0,				; WOT_TEACHER_COMMON
	0,				; WOT_OFFICE_HOME
	0,				; WOT_STUDENT_COURSE
	0,				; WOT_STUDENT_HOME
	0,				; WOT_GEOS_COURSEWARE
	0,				; WOT_DOS_COURSEWARE
	0,				; WOT_OFFICEAPP_LIST
	0,				; WOT_SPECIALS_LIST
	0,				; WOT_COURSEWARE_LIST
	0,				; WOT_PEOPLE_LIST
	0,				; WOT_STUDENT_CLASSES
	0,				; WOT_STUDENT_HOME_TVIEW
	0,				; WOT_TEACHER_COURSE
	0,				; WOT_ROSTER
	0,				; WOT_TEACHER_CLASSES
	0,				; WOT_TEACHER_HOME
	offset BAStudentFolderRestrictions,	; WOT_FOLDER
	0,				; WOT_DESKTOP
	0,				; WOT_PRINTER
	0,				; WOT_WASTEBASKET
	0,				; WOT_DRIVE
	0,				; WOT_DOCUMENT
	0,				; WOT_EXECUTABLE
	0,				; WOT_HELP
	0,				; WOT_LOGOUT
	0,				; WOT_SYSTEM_FOLDER

.assert (($ - BAStudentDropDownTablesTable) eq	\
		(NewDeskObjectType + OFFSET_FOR_WOT_TABLES))


BAStudentFolderRestrictions	label word
	word	offset	NDFolderMenuDistribute
	word	0

BADropDownCreateFolderTable	label word
	word	offset BAStudentUtilityMenuCreateFolder	; WOT_STUDENT_UTILITY
	word	offset BAOfficeCommonMenuCreateFolder	; WOT_OFFICE_COMMON
	word	offset BATeacherCommonMenuCreateFolder	; WOT_TEACHER_COMMON
	word	offset BAOfficeHomeMenuCreateFolder	; WOT_OFFICE_HOME
	word	0					; WOT_STUDENT_COURSE
	word	offset BAStudentHomeMenuCreateFolder	; WOT_STUDENT_HOME
	word	0					; WOT_GEOS_COURSEWARE
	word	0					; WOT_DOS_COURSEWARE
	word	0					; WOT_OFFICEAPP_LIST
	word	0					; WOT_SPECIALS_LIST
	word	0					; WOT_COURSEWARE_LIST
	word	0					; WOT_PEOPLE_LIST
	word	0					; WOT_STUDENT_CLASSES
	word offset BAStudentHomeTViewMenuCreateFolder	; WOT_STUDENT_HOME_TVIEW
	word	offset BATeacherCourseMenuCreateFolder	; WOT_TEACHER_COURSE
	word	0					; WOT_ROSTER
	word	0					; WOT_TEACHER_CLASSES
	word	offset BATeacherHomeMenuCreateFolder	; WOT_TEACHER_HOME
	word	offset NDFolderMenuCreateFolder		; WOT_FOLDER
	word	offset DesktopMenuCreateFolder		; WOT_DESKTOP
	word	0					; WOT_PRINTER
	word	0					; WOT_WASTEBASKET
	word	offset NDDriveMenuCreateFolder		; WOT_DRIVE
	word	0					; WOT_DOCUMENT
	word	0					; WOT_EXECUTABLE
	word	0					; WOT_HELP
	word	0					; WOT_LOGOUT
	word	0					; WOT_SYSTEM_FOLDER
.assert (($ - BADropDownCreateFolderTable) eq	\
		(NewDeskObjectType + OFFSET_FOR_WOT_TABLES))


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BAGetCreateFolderOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the chunk handle of the CreateFolder menu item for a 
		particular WOT's template.

CALLED BY:	BAReCheckFolderPermissions
PASS:		si	- NewDeskObjectType
RETURN:		si	- chunk handle of the menu item
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/ 2/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BAGetCreateFolderOffset	proc	far
	.enter

.assert segment BADropDownCreateFolderTable eq @CurSeg
	mov	si, cs:[BADropDownCreateFolderTable+OFFSET_FOR_WOT_TABLES][si]

	.leave
	ret
BAGetCreateFolderOffset	endp

endif		; if _NEWDESKBA



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderOpenNewDeskObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a message that is used to open the first object in the
	folder object's FolderRecord buffer whose NewDeskObjectType matches the
	NewDeskObjectType passed in dx. 

CALLED BY:	MSG_ND_FOLDER_OPEN_NEWDESK_OBJECT
PASS:		*ds:si	= NDFolderClass object
		ds:di	= NDFolderClass instance data
		ds:bx	= NDFolderClass object (same as *ds:si)
		es 	= segment of NDFolderClass
		ax	= message #
		dx	= NewDeskObjectType
RETURN:		if carry clear
			ax = GeosFileType of object opened
			^lcx:dx	= NDFolderClass object if ax == GFT_DIRECTORY
		if carry set
			The object was not found or the buffer block
			couldn't be locked.
	
DESTROYED:	bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
 	JS	12/16/92   	Parts copied from Allen Yuen's Open Roster code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderOpenNewDeskObject	method dynamic NDFolderClass, 
					MSG_ND_FOLDER_OPEN_NEWDESK_OBJECT

	call	FolderLockBuffer	; return bx = hptr, es = sptr, ZF
	jnz	lockedBuffer
	stc				; exit with error
	ret				; <====	RETURN HERE

lockedBuffer:
	mov	cx, ds:[di].FOI_fileCount
	mov	di, offset FBH_buffer

objectLoop:
	cmp	es:[di].FR_desktopInfo.DI_objectType, dx
	je	found
	add	di, size FolderRecord
	loop	objectLoop

	stc
	jmp	short unlock

found:
	call	FileOpenESDI		; carry flag is preserved through ret
	mov	ax, es:[di].FR_fileType	; return GeosFileType

unlock:
	call	FolderUnlockBuffer
	ret
NDFolderOpenNewDeskObject	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderSetControlButtonMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the moniker of the primary with the small 
		control button moniker so that when it is built out
		the UI will stuff this into the control button place.

CALLED BY:	NDFolderSetup

PASS:		*ds:si	- NDFolderClass object

RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/31/92		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderSetControlButtonMoniker	method NDFolderClass,
					MSG_ND_SET_CONTROL_BUTTON_MONIKER
	uses	ax, cx, dx, bp
	.enter

	mov	bp, si				; save instance data handle
	mov	ax, MSG_ND_FOLDER_GET_TOKEN
	call	ObjCallInstanceNoLock		; ax, cx, dx = GeodeToken

	mov	bx, cx
	mov	si, dx				; ax, bx, si = GeodeToken
	push	ds:[LMBH_handle]		; save lmem blk handle
	mov	dh, ss:[desktopDisplayType]
	mov	cx,	(VMS_TOOL shl offset VMSF_STYLE) or	\
			mask VMSF_GSTRING

	push	cx, cx		; VisMonikerSearchFlags, any old bogus size 
	clr	cx				; return us a block
	call	TokenLoadMoniker		; block returned in di, 
	pop	bx				;  cx is length in bytes
	call	MemDerefDS			; fixup ds
	jc	exit				;  exit if no icon found

	push	di				; save vis moniker block handle

	DerefFolderObject	ds, bp, si
	mov	dx, size ReplaceVisMonikerFrame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].RVMF_source.high, di		; block's handle
	mov	ss:[bp].RVMF_source.low, 0		; no offset
	mov	ss:[bp].RVMF_sourceType, VMST_HPTR
	mov	ss:[bp].RVMF_dataType, VMDT_VIS_MONIKER
	mov	ss:[bp].RVMF_length, cx
	clr	ss:[bp].RVMF_width
	clr	ss:[bp].RVMF_height
	mov	ss:[bp].RVMF_updateMode, VUM_NOW
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	bx, ds:[si].FOI_windowBlock
	mov	si, FOLDER_WINDOW_OFFSET
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size ReplaceVisMonikerFrame

	pop	bx				; restore vismoniker block
	call	MemFree
exit:
	.leave
	ret
NDFolderSetControlButtonMoniker	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderGetToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the token characters associated with a
		NDFolderClass.

CALLED BY:	NDFolderSetControlButtonMoniker

PASS:		*ds:si	- NDFolderClass object

RETURN:		ax, cx, dx TokenCharacters

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/31/92		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderGetToken	method dynamic NDFolderClass, MSG_ND_FOLDER_GET_TOKEN
	uses	bp
	.enter

	mov	bp, ds:[di].NDFOI_ndObjType
	call	NDValidateWOT
	shl	bp, 1				; make word -> dword
CheckHack <size GeodeToken eq 6>
	mov	ax, {word} cs:[ndObjTokenTable+(2*OFFSET_FOR_WOT_TABLES)][bp]
	mov	cx, {word} cs:[ndObjTokenTable+(2*OFFSET_FOR_WOT_TABLES)+2][bp]
	mov	dx, MANUFACTURER_ID_GEOWORKS

	;
	; while we've got it, send a quick message over to the folder window
	; to set the token
	;
	push	ax, cx, dx
	mov	bp, dx
	mov	dx, cx
	mov	cx, ax
	mov	ax, MSG_ND_PRIMARY_SET_TOKEN
	mov	bx, ds:[di].FOI_windowBlock
	mov	si, FOLDER_WINDOW_OFFSET
	call	ObjMessageCallFixup
	pop	ax, cx, dx

	.leave
	ret
NDFolderGetToken	endm

ndObjTokenTable label GeodeToken
if _NEWDESKBA
	TokenChars	<'wbaS'>		; WOT_STUDENT_UTILITY
	TokenChars	<'wbaP'>		; WOT_OFFICE_COMMON
	TokenChars	<'wbaP'>		; WOT_TEACHER_COMMON
	TokenChars	<'wbaE'>		; WOT_OFFICE_HOME
	TokenChars	<'ba09'>		; WOT_STUDENT_COURSE
	TokenChars	<'wbaS'>		; WOT_STUDENT_HOME
	TokenChars	<'ba50'>		; WOT_GEOS_COURSEWARE
	TokenChars	<'ba50'>		; WOT_DOS_COURSEWARE
	TokenChars	<'wbaL'>		; WOT_OFFICEAPP_LIST
	TokenChars	<'wbaL'>		; WOT_SPECIALS_LIST
	TokenChars	<'wbaL'>		; WOT_COURSEWARE_LIST
	TokenChars	<'wbaL'>		; WOT_PEOPLE_LIST
	TokenChars	<'wbaC'>		; WOT_STUDENT_CLASSES
	TokenChars	<'wbaS'>		; WOT_STUDENT_HOME_TVIEW
	TokenChars	<'ba00'>		; WOT_TEACHER_COURSE
	TokenChars	<'wbaR'>		; WOT_ROSTER
	TokenChars	<'wbaC'>		; WOT_TEACHER_CLASSES
	TokenChars	<'wbaE'>		; WOT_TEACHER_HOME
endif		; if _NEWDESKBA
	TokenChars	<'nFDR'>		; WOT_FOLDER
	TokenChars	<'DESK'>		; WOT_DESKTOP
	TokenChars	<'nPTR'>		; WOT_PRINTER
	TokenChars	<'ndWB'>		; WOT_WASTEBASKET
	TokenChars	<'DESK'>		; WOT_DRIVE
	TokenChars	<'nFIL'>		; WOT_DOCUMENT
	TokenChars	<'nAPP'>		; WOT_EXECUTABLE
	TokenChars	<'nHLP'>		; WOT_HELP
	TokenChars	<'wbaO'>		; WOT_LOGOUT
	TokenChars	<'nFDR'>		; WOT_SYSTEM_FOLDER

.assert (($ - ndObjTokenTable)eq(2*(NewDeskObjectType + OFFSET_FOR_WOT_TABLES)))


FolderOpenCode	ends


NDFolderCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ND_FOLDER_HELP
PASS:		*ds:si	= NDFolderClass object
		ds:di	= NDFolderClass instance data

RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	1/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderHelp	method dynamic NDFolderClass, 
					MSG_ND_FOLDER_HELP
	.enter

	sub	sp, size FileLongName

	mov	ax, ATTR_FOLDER_HELP_CONTEXT
	call	ObjVarFindData
	jnc	noHelp

	push	bx				; ds:bx is context string
	mov	bx, handle GlobalMenuResource
	mov	si, offset GlobalMenu
	mov	ax, MSG_META_GET_HELP_TYPE
	call	ObjMessageCallFixup
	pop	si
	jnc	noHelp

	mov	bp, dx				; bp low is HelpType
	segmov	cx, ss
	mov	dx, sp				; cx:dx is stack buffer
	push	si
	mov	si, offset GlobalMenu
	mov	ax, MSG_META_GET_HELP_FILE
	call	ObjMessageCallFixup
	pop	si				; ds:si is context string
	jnc	noHelp

	segmov	es, cx
	mov	di, dx				; es:di is help file
	mov	ax, bp				; al is HelpType
	call	HelpSendHelpNotification
	;
	; No need to fixup ds around call to HelpSendHelpNotification()
	; since we don't use it after the call, and NDFolderHelp is
	; dynamic (and hence not called directly).
	;

noHelp:
	add	sp, size FileLongName
	.leave
	ret
NDFolderHelp	endm



ifdef SMARTFOLDERS		; compilation flag, see local.mk

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCloseAndSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Saves the size and position of the given folder in the
		DIRINFO file, and then closes the folder.

CALLED BY:	GLOBAL

PASS:		*ds:si	= FolderClass object
		ss:bp	= DirInfoWinInfo

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCloseAndSave	method dynamic FolderClass, 
					MSG_FOLDER_CLOSE_AND_SAVE

		test	ds:[di].FOI_folderState, mask FOS_BOGUS
		LONG jnz	afterSave

BA <		call	UtilAreWeInEntryLevel?				>
BA <		jc	afterSave					>

;		mov	ax, MSG_FOLDER_SAVE_ICON_POSITIONS
;		call	ObjCallInstanceNoLock
;the above doesn't save folder size and position, and it is already called
;from folder object when closing; what we need to do is save folder size
;and position into directory info file (unfortunately, the file could be
;updated twice (one here and once again for the file positions)
		push	bp
		mov	ax, MSG_FOLDER_SET_CUR_PATH
		call	ObjCallInstanceNoLock 
		pop	bp
		jc	afterSave

		call	UtilCheckWriteDirInfo
		jc	afterSave
		
		push	ds, si			; *ds:si - folder
NOFXIP<		segmov	ds, dgroup, dx		; ds:dx - filename to open >
FXIP	<	GetResourceSegmentNS dgroup, ds				>
		mov	dx, offset dirinfoFilename
		push	bp			; save FolderWindowInfo
		call	ShellCreateDirInfo	; bp = info block
		pop	cx			; ss:cx = FolderWindowInfo
		pop	ds, si			; *ds:si - folder
		jc	afterSave		; unable to open file
		
		push	bx, bp, es

		mov	bx, bp
		call	MemDerefES
		mov	bp, cx			; ss:bp = FolderWindowInfo
		mov	ax, ss:[bp].FWI_position.SWSP_x
		mov	es:[DIFH_winPosition].SWSP_x, ax
		mov	ax, ss:[bp].FWI_position.SWSP_y
		mov	es:[DIFH_winPosition].SWSP_y, ax
		mov	ax, ss:[bp].FWI_size.SWSP_x
		mov	es:[DIFH_winSize].SWSP_x, ax
		mov	ax, ss:[bp].FWI_size.SWSP_y
		mov	es:[DIFH_winSize].SWSP_y, ax

		cmp	es:[DIFH_protocol], 3
		jbe	noModes
		DerefFolderObject	ds, si, di
		mov	ch, ds:[di].FOI_displayTypes
		mov	cl, ds:[di].FOI_displayAttrs
		mov	dh, ds:[di].FOI_displaySort
		mov	dl, ds:[di].FOI_displayMode
		movdw	es:[DIFH_displayOptions], cxdx
noModes:

		pop	bx, bp, es
		call	VMDirty
		call	ShellCloseDirInfo

		BitSet	ds:[di].FOI_positionFlags, FIPF_WIN_SAVED

afterSave:

		mov	ax, MSG_FOLDER_CLOSE
		GOTO	ObjCallInstanceNoLock

FolderCloseAndSave	endm

endif 	; ifdef SMARTFOLDERS




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Tell this folder's child, and its parent, if any, that
		this folder is going away

PASS:		*ds:si	- NDFolderClass object
		ds:di	- NDFolderClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
	Maybe we should do this on MSG_META_OBJ_FREE ?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/28/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDFolderClose	method	dynamic	NDFolderClass, 
					MSG_FOLDER_CLOSE
	uses	ax,cx,dx,bp
	.enter

	tst	ds:[di].NDFOI_child.handle
	jz	afterChild
	
	clr	cx, dx
	movdw	bxsi, ds:[di].NDFOI_child
	mov	ax, MSG_ND_FOLDER_SET_PARENT_OPTR
	clr	di
	call	ObjMessage

afterChild:

	DerefFolderObject	ds, si, di
	tst	ds:[di].NDFOI_parent.handle
	jz	callSuper

	clr	cx, dx
	movdw	bxsi, ds:[di].NDFOI_parent
	mov	ax, MSG_ND_FOLDER_SET_CHILD_OPTR
	clr	di
	call	ObjMessage

callSuper:

	.leave
	mov	di, offset NDFolderClass
	GOTO	ObjCallSuperNoLock
NDFolderClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderSetParentOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Store the OD of the parent in our instance data

PASS:		*ds:si	- NDFolderClass object
		ds:di	- NDFolderClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/28/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDFolderSetParentOptr	method	dynamic	NDFolderClass, 
					MSG_ND_FOLDER_SET_PARENT_OPTR
	movdw	ds:[di].NDFOI_parent, cxdx
	ret
NDFolderSetParentOptr	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderSetChildOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Store the OD of the child in our instance data

PASS:		*ds:si	- NDFolderClass object
		ds:di	- NDFolderClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/28/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDFolderSetChildOptr	method	dynamic	NDFolderClass, 
					MSG_ND_FOLDER_SET_CHILD_OPTR

	movdw	ds:[di].NDFOI_child, cxdx
	ret
NDFolderSetChildOptr	endm


NDFolderCode	ends

; Moved into this resource for workset optimization

UtilCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDValidateWOT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if a WOT is valid, and if not errors in the EC
		case.  In the NONEC case it defaults to a WOT_DOCUMENT, as
		we need to handle cases where we might get a corrupt file.
		A document is the catch all if we don't know what something
		is, and so if we don't know the WOT, this is our default.

CALLED BY:	

PASS:		bp - NewDeskObjectType (supposedly)
RETURN:		bp - valid NewDeskObjectType
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	2/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDValidateWOT	proc	far
	.enter
	cmp	bp, -OFFSET_FOR_WOT_TABLES
	jl	badWOT

	cmp	bp, NewDeskObjectType
	jle	gotWOT

badWOT:
EC<	WARNING	BAD_WOT_TYPE		>
	mov	bp, WOT_DOCUMENT	; if its WOT is garbage, treat
					;   it like a generic document
gotWOT:

	.leave
	ret
NDValidateWOT	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildPathAndGetNewDeskObjectType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the NewDeskObjectType if need be

CALLED BY:	ProcessFiles, FolderRescanFolderEntry

PASS:		ds:[si] - FolderRecord of current path to check

RETURN:		FolderRecord in ds:[si] filled with NewDeskObjectType

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	09/02/92	Initial version
	ron	10/01/92	added support for links to non-folders
	chrisb	10/22/92	Removed call to GetFolderTypeFromPathName

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildPathAndGetNewDeskObjectType	proc	far
	uses	ax, bx, cx, es, di, bp
	.enter

	tst	ds:[si].FR_desktopInfo.DI_objectType
	jnz	done

	test	ds:[si].FR_fileAttrs, mask FA_SUBDIR
	jnz	done			; is a dir and has WOT_FOLDER
	;
	; If the GeosFileType says its an executable, then store that
	; value in the DesktopInfo field
	;

	mov	ds:[si].FR_desktopInfo.DI_objectType, WOT_EXECUTABLE
	cmp	ds:[si].FR_fileType, GFT_EXECUTABLE
	je	done

	segmov	es, ds, di
	mov	di, si					;es:[di] is
							;FolderRecord 
CheckHack < offset FR_name eq 0 >
	; (checking the first . is fine since a real BAT/COM/EXE will
	; only have one .)
	mov	cx, size FileLongName
	LocalLoadChar	ax, '.'
	LocalFindChar
	jne	itsADoc					; if no '.', not exe
	call	CheckIfBatComExe
	jnc	done					; if BatComExe, done
itsADoc:
	mov	ds:[si].FR_desktopInfo.DI_objectType, WOT_DOCUMENT
done:
	.leave
	ret
BuildPathAndGetNewDeskObjectType	endp

UtilCode	ends


FolderObscure	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle key presses for folder window

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= NDFolderClass object
		ds:di	= NDFolderClass instance data
		ds:bx	= NDFolderClass object (same as *ds:si)
		es 	= segment of NDFolderClass
		ax	= message #
		ch 	= CharacterSet
		cl 	= character value
		dl 	= CharFlags
		dh 	= ShiftState
		bp(low)	= ToggleState
		bp(high)= scan code
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKbdChar	method dynamic NDFolderClass, 
					MSG_META_KBD_CHAR
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper

	test	dh, mask SS_LALT or mask SS_RALT or \
		    mask SS_LCTRL or mask SS_RCTRL
	jnz	checkShortCuts

	cmp	cx, 'A'
	jb	checkShortCuts
	cmp	cx, 'Z'
	ja	checkShortCuts
	sub	cx, 'A'

	GOTO	NDFolderKeysOpenDiskDrive

checkShortCuts:
	push	ds, si, ax
	segmov	ds, cs
	mov	si, offset ndFolderKeysTable
	mov	ax, ND_FOLDER_KEYS_TABLE_SIZE
	call	FlowCheckKbdShortcut		; carry set if match (uses bp)
	mov	bx, si				; bx = table offset if match
	pop	ds, si, ax
	jnc	callSuper

	call	cs:[ndFolderKeysRoutineTable][bx]
	ret

callSuper:
	mov	di, offset NDFolderClass
	GOTO	ObjCallSuperNoLock		

NDFolderKbdChar	endm

	;P     C  S       C
	;h  A  t  h  S    h
	;y  l  r  f  e    a
	;s  t  l  t  t    r
if DBCS_PCGEOS
ndFolderKeysTable	KeyboardShortcut \
	<0, 0, 0, 1, C_SYS_F10 and mask KS_CHAR>,	;bring up popup menu
	<0, 1, 0, 0, C_SPACE>,	;bring up system menu
	<0, 1, 0, 0, C_SYS_ENTER and mask KS_CHAR>,	;get info
	<0, 0, 1, 0, 'G'>,		;get info
	<0, 0, 1, 0, 'g'>,		;get info
	<0, 0, 1, 0, 'P'>,		;print
	<0, 0, 1, 0, 'p'>,		;print
	<0, 0, 1, 0, 'A'>,		;select all
	<0, 0, 1, 0, 'a'>,		;select all
	<0, 0, 0, 0, C_SYS_INSERT and mask KS_CHAR>,	;create folder
	<0, 0, 0, 0, C_SYS_DELETE and mask KS_CHAR>,	;delete selected items
	<0, 0, 0, 0, C_SYS_F2 and mask KS_CHAR>,	;rename selected items
	<0, 0, 0, 0, C_SYS_F3 and mask KS_CHAR>,	;exit to dos
	<0, 0, 0, 0, C_SYS_F5 and mask KS_CHAR>,	;rescan folder
	<0, 0, 0, 0, C_SYS_F7 and mask KS_CHAR>,	;move selected items
	<0, 0, 0, 0, C_SYS_f8 and mask KS_CHAR>	;copy selected items
else
ndFolderKeysTable	KeyboardShortcut \
	<0, 0, 0, 1, 0xf, VC_F10>,	;bring up popup menu
	<0, 1, 0, 0, 0x0, C_SPACE>,	;bring up system menu
	<0, 1, 0, 0, 0xf, VC_ENTER>,	;get info
	<0, 0, 1, 0, 0x0, 'G'>,		;get info
	<0, 0, 1, 0, 0x0, 'g'>,		;get info
	<0, 0, 1, 0, 0x0, 'P'>,		;print
	<0, 0, 1, 0, 0x0, 'p'>,		;print
	<0, 0, 1, 0, 0x0, 'A'>,		;select all
	<0, 0, 1, 0, 0x0, 'a'>,		;select all
	<0, 0, 0, 0, 0xf, VC_INS>,	;create folder
	<0, 0, 0, 0, 0xf, VC_DEL>,	;delete selected items
	<0, 0, 0, 0, 0xf, VC_F2>,	;rename selected items
	<0, 0, 0, 0, 0xf, VC_F3>,	;exit to dos
	<0, 0, 0, 0, 0xf, VC_F5>,	;rescan folder
	<0, 0, 0, 0, 0xf, VC_F7>,	;move selected items
	<0, 0, 0, 0, 0xf, VC_F8>	;copy selected items
endif

ND_FOLDER_KEYS_TABLE_SIZE = ($-ndFolderKeysTable)/(size KeyboardShortcut)

ndFolderKeysRoutineTable	nptr.near \
	NDFolderKeysPopupMenu,		; Shift-F10
	NDFolderKeysSystemMenu,		; Alt-Space
	NDFolderKeysGetInfo,		; Alt-Enter
	NDFolderKeysGetInfo,		; Ctrl-G
	NDFolderKeysGetInfo,		; Ctrl-g
	NDFolderKeysPrintSelectedItems,	; Ctrl-P
	NDFolderKeysPrintSelectedItems,	; Ctrl-p
	NDFolderKeysSelectAll,		; Ctrl-A
	NDFolderKeysSelectAll,		; Ctrl-a
	NDFolderKeysCreateFolder,	; Insert
	NDFolderKeysDeleteSelectedItems,; Delete
	NDFolderKeysRenameSelectedItems,; F2
	NDFolderKeysExitToDos,          ; F3
	NDFolderKeysRescanFolder,	; F5
	NDFolderKeysMoveSelectedItems,	; F7
	NDFolderKeysCopySelectedItems	; F8


ND_FOLDER_KEYS_ROUTINE_TABLE_SIZE = length ndFolderKeysRoutineTable



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysOpenDiskDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open disk drive

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si	= NDFolder object
		ds:di	= folder instance data
		cx	= drive (A:=0 .. Z:=25)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	5/2/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysOpenDiskDrive	proc	far
	mov	ax, cx
	call	DriveGetStatus
	jc	done			; exit if no such drive

	push	cx
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	UserCallApplication
	pop	cx

	mov	bx, handle 0
	mov	ax, MSG_DRIVETOOL_INTERNAL
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	GOTO	UserCallApplication
done:
	ret
NDFolderKeysOpenDiskDrive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	NDFolderKeysPopupMenu	NDFolderKeysSystemMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up popup menu for selected icon or folder
		Bring up system menu

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	???
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysPopupMenu	proc	near
	class	NDFolderClass

EC <	call	ECCheckFolderObjectDSSI		>
	;
	; Check if foler has selection
	;
	mov	bp, ds:[di].FOI_selectList
	cmp	bp, NIL
	je	whiteSpace
	;
	; Folder has selection - Bring up object popup
	;
	call	FolderLockBuffer
	jz	done

	xchg	di, bp
	mov	cx, es:[di].FR_iconBounds.R_right
	mov	dx, es:[di].FR_iconBounds.R_top
	movdw	ds:[bp].NDFOI_mousePos, cxdx
	call	NDObjectPopUp

	call	FolderUnlockBuffer
done:
	ret

whiteSpace:
	;
	; Folder has no selection - Bring up system menu
	;
	FALL_THRU	NDFolderKeysSystemMenu

NDFolderKeysPopupMenu	endp

NDFolderKeysSystemMenu	proc	near
	class	NDFolderClass

	cmp	ds:[di].NDFOI_ndObjType, WOT_DESKTOP
	jne	notDesktop
	call	NDWhiteSpacePopUp
	ret

notDesktop:
	mov	bx, ds:[di].FOI_windowBlock
	mov	si, FOLDER_MENU_OFFSET
	clr	di
	mov	ax, MSG_GEN_ACTIVATE
	call	ObjMessage
	ret
NDFolderKeysSystemMenu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get info on selected items

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	5/2/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysGetInfo	proc	near
	mov	ax, MSG_ND_FOLDER_SEND_AS_SELECTED_ITEMS
	mov	cx, MSG_FM_GET_INFO
	clr	dx
	mov	bp, ERROR_NO_SELECTION
	call	ObjCallInstanceNoLock
	ret
NDFolderKeysGetInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysSelectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select all items

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	5/2/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysSelectAll	proc	near
	mov	ax, MSG_ND_FOLDER_SEND_AS_WHITESPACE
	mov	cx, MSG_SELECT_ALL
	call	ObjCallInstanceNoLock
	ret
NDFolderKeysSelectAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysPrintSelectedItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print selected items

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	5/2/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysPrintSelectedItems	proc	near
	mov	ax, MSG_ND_FOLDER_SEND_AS_SELECTED_ITEMS
	mov	cx, MSG_FM_START_PRINT
	clr	dx
	mov	bp, ERROR_NO_SELECTION
	call	ObjCallInstanceNoLock
	ret
NDFolderKeysPrintSelectedItems	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysCreateFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a folder

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	5/2/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysCreateFolder	proc	near
	mov	ax, MSG_ND_FOLDER_SEND_AS_WHITESPACE
	mov	cx, MSG_FM_START_CREATE_DIR
	call	ObjCallInstanceNoLock
	ret
NDFolderKeysCreateFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysDeleteSelectedItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete selected items

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	5/2/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysDeleteSelectedItems	proc	near
	mov	ax, MSG_ND_FOLDER_SEND_AS_SELECTED_ITEMS
	mov	cx, MSG_FM_START_THROW_AWAY
	clr	dx
	mov	bp, ERROR_NO_SELECTION
	call	ObjCallInstanceNoLock
	ret
NDFolderKeysDeleteSelectedItems	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysRenameSelectedItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename selected items

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	???
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	5/2/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDFolderKeysRenameSelectedItems	proc	near
	mov	ax, MSG_ND_FOLDER_SEND_AS_SELECTED_ITEMS
	mov	cx, MSG_FM_START_RENAME
	clr	dx
	mov	bp, ERROR_NO_SELECTION
	call	ObjCallInstanceNoLock
	ret
NDFolderKeysRenameSelectedItems	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysExitToDos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit from NewDesk to DOS

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	2000/7/27    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysExitToDos	proc	near
 	mov	ax, MSG_META_QUIT
 	call	UserCallApplication
	ret
NDFolderKeysExitToDos	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysRescanFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rescan folder

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	5/2/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysRescanFolder	proc	near
	mov	ax, MSG_ND_FOLDER_SEND_AS_WHITESPACE
	mov	cx, MSG_WINDOWS_REFRESH_CURRENT
	call	ObjCallInstanceNoLock
	ret
NDFolderKeysRescanFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysMoveSelectedItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move selected items

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	5/2/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysMoveSelectedItems	proc	near
	mov	ax, MSG_ND_FOLDER_SEND_AS_SELECTED_ITEMS
	mov	cx, MSG_FM_START_MOVE
	clr	dx
	mov	bp, ERROR_NO_SELECTION
	call	ObjCallInstanceNoLock
	ret
NDFolderKeysMoveSelectedItems	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDFolderKeysCopySelectedItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy selected items

CALLED BY:	NDFolderKbdChar
PASS:		*ds:si = NDFolder object
		ds:di = folder instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	5/2/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDFolderKeysCopySelectedItems	proc	near
	mov	ax, MSG_ND_FOLDER_SEND_AS_SELECTED_ITEMS
	mov	cx, MSG_FM_START_COPY
	clr	dx
	mov	bp, ERROR_NO_SELECTION
	call	ObjCallInstanceNoLock
	ret
NDFolderKeysCopySelectedItems	endp

FolderObscure	ends


if _NEWDESKBA

InitCode	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BAUpdateCreateFolderPermissions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sent to every opened folder on startup to make sure we update
		our UI wrt Create Folder permissions, as they might have 
		changed since we last logged out.

CALLED BY:	MSG_UPDATE_CREATE_FOLDER_PERMISSIONS
PASS:		*ds:si	= BAFolderClass object
		ds:di	= BAFolderClass instance data
		cx	= MSG_GEN_SET_USABLE or MSG_GEN_SET_NOT_USABLE
		dx	= chunk handle of the CreateFolder object residing in
			   the window block of this folder.
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BAUpdateCreateFolderPermissions	method dynamic NDFolderClass, 
					MSG_UPDATE_CREATE_FOLDER_PERMISSIONS
	uses	ax, cx, dx, bp
	.enter

	mov	ax, cx				; passed in Usable/notUsable 
	mov	bx, handle DesktopMenuCreateFolder
	cmp	ds:[di].NDFOI_ndObjType, WOT_DESKTOP
	je	gotHandle
	mov	bx, ds:[di].FOI_windowBlock
gotHandle:
	mov	si, dx
	mov	dl, VUM_NOW
	call	ObjMessageCall

	.leave
	ret
BAUpdateCreateFolderPermissions	endm
InitCode	ends

endif		; if _NEWDESKBA
