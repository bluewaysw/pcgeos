COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Document
FILE:		documentIcon.asm

AUTHOR:		Steve Yegge

ROUTINES:

Name				Description
----				-----------
DBViewerEditIcon		-- MSG_DB_VIEWER_EDIT_ICON handler
CheckIconDirtyAndDealWithIt	-- see if current icon needs saving (far)
SwitchIcons		-- sets bitmap-object's bitmap to new one
SetUpPreviewStuff	-- updates entire preview area

DBViewerDeleteIcons		-- Deletes 1 or more icons, prompting
DBViewerDeleteIconsNoConfirm	-- Deletes 1 or more icons, no prompting
DeleteTheIcon		-- actually deletes the icon & its data structures
DeleteIconByNumber	-- utility routine called by DeleteTheIcon
DBViewerDeleteCurrentIcon	-- Deletes current icon, no prompt

ReplaceBMOBitmap	-- sets new bitmap into BMO, w/ new resolution, etc...
DBViewerRenameIcon	-- renames the selected icon in viewer
EnableEditing		-- enables user-editing of the bitmap object
DisableEditing		-- disables user-editing of the bitmap object

ResizeBMOAndFatbits	-- resizes bitmap displays
CreateBitmapInBMO	-- creates a bitmap (smartly) and returns it.
CreateBitmapDataOnly	-- creates a bitmap, nukes window & gstate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/4/92		initial revision

DESCRIPTION:

	Miscellaneous routines that haven't found a home yet.

	$Id: documentIcon.asm,v 1.1 97/04/04 16:06:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
DocumentCode segment resource
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerEditIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switches to a new icon in the database.

CALLED BY:	MSG_DB_VIEWER_EDIT_ICON

PASS:		*ds:si	= DBViewer object
		ds:[di]	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- save the icon if dirty (prompt for save)
	- update currentIcon in dgroup
	- get one of the formats for the icon
	- replace vis-bitmap's bitmap with the new format
	- invalidate contents & views for redraw
	- update the preview object for this icon	
	- enable the UI for the new icon
	- Make sure a tool is selected or death, death, death

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	WARNING:  Make sure DBVI_currentIcon is set to either:

		* NO_CURRENT_ICON, or
		* the previously edited icon.

	It cannot be set to the icon we're editing currently.
	Well, it can, I guess, but it'll slow things down
	appreciably, since we first discard all the mem handles
	associated with DBVI_currentIcon.  If we do it to the
	icon we're about to switch to, it'll have to re-load
	all the blocks.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerEditIcon	method dynamic DBViewerClass,
					MSG_DB_VIEWER_EDIT_ICON
		uses	ax, cx, dx, bp
		.enter
	;
	;  Get the current selection in the database viewer.
	;
		mov	ax, MSG_DB_VIEWER_GET_FIRST_SELECTION
		call	ObjCallInstanceNoLock		; cx <- selection
		jc	bail				; none selected
		
		mov_tr	ax, cx				; ax = selection
	;
	;  If the current Icon is dirty, prompt for save and save it.
	;  Except if there is no current icon.
	;
		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		je	noCurrentIcon
		call	CheckIconDirtyAndDealWithIt	; preserves ax
		jc	bail				; user cancelled
	;
	;  Switch edit to new icon, and update preview area.
	;
noCurrentIcon:
		; DBVI_currentIcon gets set in SwitchIcons
		call	SwitchIcons		; actually switches editing
		call	SetUpPreviewStuff	; updates the preview area
	;
	;  Enable appropriate UI stuff
	;
		push	si, ax			; save DBViewer and icon

		mov	ax, MSG_DB_VIEWER_INIT_CHANGE_ICON_DIALOG
		call	ObjCallInstanceNoLock

		mov	si, offset FormatViewer
		mov	ax, MSG_FORMAT_CONTENT_RESCAN_LIST
		call	ObjCallInstanceNoLock
	;
	;  Have the bitmap object broadcast its colors and whatnot.
	;
		mov	si, offset BMO
		mov	ax, MSG_ICON_BITMAP_SEND_NOTIFICATIONS
		call	ObjCallInstanceNoLock
		pop	si, ax			; DBViewer & icon number
	;
	;  Enable editing if we're editing an icon.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		je	doneEnable

		call	EnableEditing
doneEnable:
		mov	ds:[di].DBVI_currentIcon, ax
		clr	ds:[di].DBVI_iconDirty
bail:
		.leave
		ret
DBViewerEditIcon	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIconDirtyAndDealWithIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're editing an icon, and if it needs to be saved.

CALLED BY:	DBViewerAddIcon

PASS:		*ds:si	= DBViewer object

RETURN:		carry set if user cancelled
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
	- if icon is dirty, prompt the user for save, throw away, cancel.
	- if user wants to save it, save it.
	- set carry if they cancel.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIconDirtyAndDealWithIt	proc	far
		class	DBViewerClass
		uses	ax,bx,si,di
		.enter

		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		
		tst	ds:[di].DBVI_iconDirty	; is the icon dirty?
		jz	done			; nope, we're done
	;	
	;  Prompt the user for saving the icon.
	;
		push	ds:[LMBH_handle], si	; save DBViewer
		mov	si, offset	PromptForSaveIconText
		call	DisplaySaveChangesYesNo

		pop	bx, si			; restore DBViewer	
		call	MemDerefDS		; *ds:si = DBViewer

		cmp	ax, IC_YES		; do they want to save it?
		jne	noWayMan		; nope, quit

		mov	ax, MSG_DB_VIEWER_SAVE_CURRENT_FORMAT
		call	ObjCallInstanceNoLock
		clc				; return no cancel
		jmp	short	done
noWayMan:
	;
	;  They selected either "no" or "cancel" -- if cancel, set the carry.
	;
		cmp	ax, IC_NO
		je	nope
		
		stc				; they cancelled
		jmp	short	done
nope:
		clc				; return no cancel
done:
		.leave
		ret
CheckIconDirtyAndDealWithIt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwitchIcons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch editing to a given icon.

CALLED BY:	DBViewerEditIcon

PASS:		*ds:si	= DBViewer object
		ds:[di]	= DBViewer instance
		ax = icon number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- nuke the previous icon (free its memory handles)
	- edit the first format
	- make sure es:[selectedFormat] is set correctly
	- get the format
	- set the format as the BMO's bitmap
	- make sure the appropriate color-selector is enabled
	- make sure the current color & line width are set in the BMO

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwitchIcons	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Ensure the memory handles from the previous icon are freed.
	;
		push	ax
		mov	bp, ds:[di].GDI_fileHandle
		mov	ax, ds:[di].DBVI_currentIcon
		call	FreeMemHandles
	;
	;  Store passed icon as current icon, and edit first format.
	;
		pop	ax
		mov	ds:[di].DBVI_currentIcon, ax
		clr	ds:[di].DBVI_currentFormat
	;	
	;  Replace the bitmap in the bitmap object and resize everything.
	;
		clr	bx			; bp = file handle, bx = format
		call	IdGetFormat		; returns ^vcx:dx
		tst	dx			; no bitmap!
		jz	done
		call	ReplaceBMOBitmap
	;
	;  Size the fatbits correctly for the current format.
	;
		push	ax			; current icon
		call	IdGetFormatDimensions	; cx = width, dx = height
		call	IconAppGetImageBitSize	; returns in al
		call	ResizeBMOAndFatbits
		pop	ax			; current icon
	;
	;  If we're editing a mouse-cursor icon, set the selection
	;  for header-type in the WriteSourceDialog.
	;
		call	IdGetFlags			; bx = flags
		test	bx, mask IF_PTR_IMAGE		; cursor?
		jz	notCursor

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset

		mov	bx, ds:[di].GDI_display
		mov	si, offset WriteSourceHeaderList
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, WSHT_PTR_IMAGE
		clr	dx
		call	ObjMessage
		
		jmp	short	done
notCursor:
		mov	bx, ds:[di].GDI_display
		mov	si, offset WriteSourceHeaderList
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, WSHT_VIS_MONIKER
		clr	dx				; not indeterminate
		call	ObjMessage
done:
	.leave
	ret
SwitchIcons	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpPreviewStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the preview object and moniker for the current icon.

CALLED BY:	DBViewerEditIcon

PASS:		*ds:si	= DBViewer object

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS/IDEAS:

PSEUDO CODE/STRATEGY:
		
	- get the preview object from the database, and set it.
	- set the preview-menu selection to the new object
	- get the colors for the preview object from the icon entry
	- set the preview object to be those colors.
	- set the color-selector item groups to the right selections
	- get a format for the icon (3rd for now, but this will change)
	- convert the format to a moniker
	- replace the moniker for the preview object
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpPreviewStuff	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;	
	;  Get the preview object for this icon, and set it.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].DBVI_currentIcon
		cmp	ax, NO_CURRENT_ICON
		je	done
		
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetPreviewObject	; returns in cx

		mov	ax, MSG_DB_VIEWER_SET_PREVIEW_OBJECT
		call	ObjCallInstanceNoLock
	;
	;  Set the preview menu selection  (selection passed in cx)
	;		
		push	si
		GetResourceHandleNS	PreviewListGroup, bx
		mov	si, offset	PreviewListGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx			; not indeterminate
		call	ObjMessage		; nukes cx, dx, bp
		pop	si			; *ds:si = DBViewer
	;
	;  Finish applying the color changes by setting the selections
	;  in the color-selector toolboxes, and actually setting the
	;  colors in the preview object.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetPreviewColors	; returns cx = on, dx = off
		movdw	axbx, cxdx			; ax <- on, bx <- off
		call	SetColorSelectorSelections	; set color-selectors

		call	ChangePreviewObjectColors
	;	
	;  Get a format for the icon and set the preview monikers to that
	;  bitmap.
	;	
		mov	ax, ds:[di].DBVI_currentIcon
		clr	bx			; get first format
		call	IdGetFormat		; returns ^vcx:dx = bitmap
		
		call	SetPreviewMonikers
done:		
		.leave
		ret
SetUpPreviewStuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerDeleteIcons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes some icons from the database.

CALLED BY:	MSG_DB_VIEWER_DELETE_ICONS

PASS:		*ds:si	= DBViewer object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Call UserStandardDialog to ask if they're sure, then
	call a helper routine (DeleteIcon) that gets all the
	selections in the dynamic list and deletes them.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerDeleteIcons	method dynamic DBViewerClass, 
					MSG_DB_VIEWER_DELETE_ICONS
		uses	ax, cx, dx, bp
		.enter
	;
	;  See if confirm-on-delete is set
	;
 		push	si			; save object
		GetResourceHandleNS	OptionsBooleanGroup, bx
		mov	si, offset	OptionsBooleanGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjMessage		; nukes cx, dx, bp
		pop	si			; *ds:si = DBViewer
		
		test	ax, mask IO_CONFIRM_DELETE
		jz	noDialog
	;
	;  Get the number of selections and put up the appropriate
	;  dialog.
	;
		mov	ax, MSG_DB_VIEWER_GET_NUM_SELECTIONS
		call	ObjCallInstanceNoLock
		
		tst	cx			; any selections?
		jz	done
		
		push	si			; save DBViewer
		
		cmp	cx, 1
		je	oneSelection
		
		mov	si, offset PromptForDeleteIconsText
		jmp	short	ask

oneSelection:
		mov	si, offset PromptForDeleteIconText
ask:
		call	DisplayQuestion		; will clean up stack.
		
		pop	si			; restore DBViewer
		cmp	ax, IC_YES
		jne	done
noDialog:
	;
	;  Now we do the deleting in earnest. 
	;
		mov	ax, MSG_DB_VIEWER_DELETE_ICONS_NO_CONFIRM
		call	ObjCallInstanceNoLock
	;
	;  Since we don't set any selections after deleting 1 or
	;  more icons, we disable the "Export to Token Database"
	;  dialog (as well as emptying it out).
	;
		call	DisableExportTokenDBTrigger

		mov	ax, MSG_DB_VIEWER_INIT_CHANGE_ICON_DIALOG
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
DBViewerDeleteIcons	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerDeleteIconsNoConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the selected icons without prompting.

CALLED BY:	MSG_DB_VIEWER_DELETE_ICONS_NO_CONFIRM

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerDeleteIconsNoConfirm	method dynamic DBViewerClass, 
					MSG_DB_VIEWER_DELETE_ICONS_NO_CONFIRM
		uses	ax, cx, dx, bp
		.enter
	;
	;  Mark the app as busy.
	;
		call	IconMarkBusy
	;
	;  Delete all the selected icons (so get how many there are).
	;
		mov	ax, MSG_DB_VIEWER_GET_NUM_SELECTIONS
		call	ObjCallInstanceNoLock
		jcxz	doneDelete
	;
	;  Actually delete them...
	;
		call	DeleteSomeIcons		; does all the work
doneDelete:
	;
	;  Make sure the deleted icons no longer appear in the viewer.
	;
		mov	ax, MSG_DB_VIEWER_RESCAN_DATABASE
		call	ObjCallInstanceNoLock
	;
	;  Mark the app as unbusy.
	;
		call	IconMarkNotBusy

		.leave
		ret
DBViewerDeleteIconsNoConfirm	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteSomeIcons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actually deletes the icons and associated data structures.

CALLED BY:	DBViewerDeleteIcons

PASS:		*ds:si	= DBViewer object
		cx = number of icons to delete

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- Find out which icons are selected for deleting
	- Delete the icons from the database and the viewer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteSomeIcons	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
		
		jcxz	done			; just in case
	;
	;  Allocate a block for the selections in the viewer.
	;
		mov	bp, cx			; bp = num selections
		mov_tr	ax, cx			; ax = size to allocate
		shl	ax			; word-sized selections
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; bx = handle, ax = segment
		jc	done
		
		push	bx			; save mem handle
		mov_tr	cx, ax
		clr	dx			; cx:dx = buffer
		
		mov	ax, MSG_DB_VIEWER_GET_MULTIPLE_SELECTIONS
		call	ObjCallInstanceNoLock
	;
	;  Loop through the selected icons, deleting them.  Delete
	;  them in reverse order or suffer the consequences (namely,
	;  trying to delete icons that don't exist).
	;
		mov	es, cx			; es:0 = selection buffer
		mov	di, bp			; di = num selections
		dec	di			; 0-indexed selections
		shl	di			; word-sized selections
deleteLoop:
		mov	cx, {word} es:[di]	; cx = selection
		call	DeleteIconByNumber
		dec	di
		dec	di			; si = next selection

		cmp	di, 0
		jge	deleteLoop
	;
	;  Make sure the changes are written...
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_fileHandle
		call	VMUpdate
		
		pop	bx			; handle of selection block
		call	MemFree
done:
		.leave
		ret
DeleteSomeIcons	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteIconByNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a single icon from the current database.

CALLED BY:	DeleteSomeIcons

PASS:		*ds:si	= DBViewer object
		cx = icon number to delete

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- find out if the icon is being edited
	- if so, disable editing 'n' stuff
	- if the icon being deleted is BEFORE (i.e., less than)
	  the current icon, then the current icon's number must
	  be decremented (because it gets one closer to the
	  first icon in the database).
	- delete the icon from the database
	- delete the vis-icon from the database viewer

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteIconByNumber	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		
		cmp	cx, ds:[di].DBVI_currentIcon
		jl	decCurrent
		jg	doDelete
	;
	;  We're deleting the current icon.  Disable editing.
	;  (No need to prompt for saving it since it's being deleted).
	;
		push	si, cx
		mov	si, offset FormatViewer
		mov	ax, MSG_FORMAT_CONTENT_DISABLE_LIST
		call	ObjCallInstanceNoLock
		pop	si, cx

		call	DisableEditing

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		clr	ds:[di].DBVI_iconDirty
		jmp	short doDelete
decCurrent:
		dec	ds:[di].DBVI_currentIcon
doDelete:
		mov_tr	ax, cx			; pass ax = icon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdFreeIconFormats		
		call	IdDeleteIcon		; deletes the database entry
		
		.leave
		ret
DeleteIconByNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerDeleteCurrentIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the currently-edited icon only (no prompt).

CALLED BY:	MSG_DB_VIEWER_DELETE_CURRENT_ICON

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/13/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerDeleteCurrentIcon	method dynamic DBViewerClass, 
					MSG_DB_VIEWER_DELETE_CURRENT_ICON
		uses	ax, cx
		.enter
	;
	;  Get the current icon and delete from database.
	;
		mov	cx, ds:[di].DBVI_currentIcon
		call	DeleteIconByNumber
	;
	;  Update the database viewer & stuff.
	;
		mov	ax, MSG_DB_VIEWER_RESCAN_DATABASE
		call	ObjCallInstanceNoLock

		.leave
		ret
DBViewerDeleteCurrentIcon	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceBMOBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	a smart version of replace-with-transfer-format

CALLED BY:	global  (SwitchIcons, DBViewerSwitchFormat)

PASS:		*ds:si	= DBViewer object
		^vcx:dx = new bitmap

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	call MSG_VIS_BITMAP_REPLACE_WITH_TRANSFER_FORMAT.
	
	We don't need to call MSG_VIS_BITMAP_SET_FORMAT_AND_RESOLUTION,
	or MSG_VIS_BITMAP_VIS_BOUNDS_MATCH_BITMAP_BOUNDS, since the
	bitmap object takes care of that now.

	However we DO need to call MSG_VIS_BITMAP_CREATE_BACKUP_BITMAP.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceBMOBitmap	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_REPLACE_WITH_TRANSFER_FORMAT
		call	ObjMessage

		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_CREATE_BACKUP_BITMAP
		call	ObjMessage
		
		.leave
		ret
ReplaceBMOBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerRenameIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Renames the currently selected icon in the database viewer.

CALLED BY:	MSG_DB_VIEWER_RENAME_ICON

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- gets the name from the Rename dialog box
	- sets the name of the icon in the database
	- updates the database viewer
	- if we just renamed the icon we're currently editing, 
	  set the primary long-term moniker

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerRenameIcon method dynamic DBViewerClass,
					MSG_DB_VIEWER_RENAME_ICON
		uses	ax,cx,dx,bp
		.enter
	;
	;  Get the selection from the viewer.
	;
		mov	ax, MSG_DB_VIEWER_GET_FIRST_SELECTION	; returns cx
		call	ObjCallInstanceNoLock
		jc	done				; no selection
		
	;
	;  Get the new name from the rename dialog.
	;
		sub	sp, size FileLongName
		mov	bp, sp			; ss:bp = buffer

		push	cx, si			; save icon number & instance
		mov	bx, ds:[di].GDI_display
		mov	si, offset RenameTextField
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	dx, ss			; dx.bp = buffer
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage		; cx = length (without NULL)
		pop	ax, si			; restore number & instance
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		
		inc	cx			; add 1 for null-terminator
		mov	bx, dx
		mov	dx, bp			; bx:dx = buffer
		mov	bp, ds:[di].GDI_fileHandle
		call	IdSetIconName

		add	sp, size FileLongName
	;
	;  Update the icon that got renamed.
	;
		push	ax			; save icon number
		mov_tr	cx, ax			; cx = icon number
		
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock	; ^lcx:dx = Vis-Icon
		pop	ax			; restore icon number
		jc	notFound
		
		push	si			; save DBViewer
		movdw	bxsi, cxdx		; ^lbx:si = destination
		mov	cx, ax			; cx = icon number
		pushdw	bxsi			; save the object
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_ICON_INITIALIZE
		call	ObjMessage
		
		popdw	bxsi
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjMessage
		pop	si			; restore DBViewer
notFound:
	;
	;  Dirty the database file
	;
 		mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
		call	ObjCallInstanceNoLock
done:	
		.leave
		ret
DBViewerRenameIcon	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableEditing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables UI gadgetry for editing an icon.

CALLED BY:	GLOBAL

PASS:		*ds:si	= DBViewer object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- enable WriteSourceDialog
	- enable the save icon trigger
	- enable the Preview icon trigger
	- enable MrFatbitsView
	- enable BMOView
	- enable format menu
	- set the tools usable and pick one.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableEditing	proc	far
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	;  Enable write-source dialog.
	;
		mov	bx, ds:[di].GDI_display
		mov	si, offset WriteSourceDialog
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Enable save-icon trigger.
	;
		mov	si, offset SaveIconTrigger
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Enable the Preview Icon trigger.
	;
		mov	si, offset PreviewLaunchTrigger
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Enable the fatbits.
	;
		mov	si, offset FatbitsView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Enable the bitmap object.
	;
		mov	si, offset BMOView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Enable the format menu.
	;
		mov	si, offset FormatMenu
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
		
		.leave
		ret
EnableEditing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableEditing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables UI gadgetry for editing an icon.

CALLED BY:	GLOBAL

PASS:		*ds:si	= DBViewer object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- disable write-source dialog
	- disable save-icon trigger
	- disable edit-icon trigger
	- disable the RenameCurrentIconDialog
	- disable the PreviewIcon Dialog
	- disable BMO view
	- disable fatbits view
	- clear the bitmap (don't leave old icon gunk lying around)
	- disable format menu

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableEditing	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Clear the change-token glyph in the change-icon dialog.
	;
		mov	ax, MSG_DB_VIEWER_INIT_CHANGE_ICON_DIALOG
		call	ObjCallInstanceNoLock
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		push	si
	;
	;  Disable the Write-source dialog
	;
		mov	bx, ds:[di].GDI_display
		mov	si, offset WriteSourceDialog
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Disable the save-icon trigger.
	;
		mov	si, offset SaveIconTrigger
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Disable the edit-icon trigger.
	;
		mov	si, offset EditIconTrigger
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Disable the rename icon dialog.
	;
		mov	si, offset RenameIconDialog
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Disable the Preview Icon trigger.
	;
		mov	si, offset PreviewLaunchTrigger
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Disable the format menu
	;
		mov	si, offset FormatMenu
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Close the transform dialog.
	;
		mov	si, offset TFDialog
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	cx, IC_INTERACTION_COMPLETE
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		call	ObjMessage
	;
	;  Create a new empty bitmap.
	;
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_PIXELS
		call	ObjMessage

		mov	al, BMF_4BIT
		call	CreateBitmapInBMO
	;	
	;  Make everything redraw
	;
		mov	si, offset MyFatbitsContent
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_NOW
		call	ObjMessage
		
		mov	si, offset BMOContent
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  set everything not-enabled
	;	
		pop	si
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset	; ds:di = DBViewerInstance
		
		push	si	
		mov	bx, ds:[di].GDI_display
		mov	si, offset FatbitsView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_ENABLED	
		mov	dl, VUM_NOW
		call	ObjMessage
		
		mov	si, offset BMOView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
	;
	;  Disable the format area
	;
		mov	si, offset FormatViewer
		mov	ax, MSG_FORMAT_CONTENT_DISABLE_LIST
		call	ObjCallInstanceNoLock
	;
	;  mark the icon as clean so it won't be saved...
	;
		pop	si			; *ds:si = DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		clr	ds:[di].DBVI_iconDirty
		
		.leave
		ret
DisableEditing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerSetFatbitSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a new image-bit-size for the fatbits display

CALLED BY:	MSG_DB_VIEWER_SET_FATBIT_SIZE

PASS:		*ds:si	= DBViewer object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
	- Find out what the new fatbit size is to supposed to be
	- Find out what it is currently
	- If the two are different,then:
	- call ResizeBMOAndFatbits with the new size

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerSetFatbitSize	method dynamic DBViewerClass, 
		MSG_DB_VIEWER_SET_FATBIT_SIZE
		uses	ax, cx, dx, bp
		.enter
	;
	;  See if there's a selection, and get it into ax.
	;
		push	si
		GetResourceHandleNS	FatbitImageSizeGroup, bx
		mov	si, offset	FatbitImageSizeGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	; ax = selection
		call	ObjMessage		; nukes cx, dx, bp
		pop	si
		jc	done			; whoops, no selection
		
		push	ax, si
		mov	bx, ds:[LMBH_handle]
		mov	si, offset	BMO
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_PIXELS
		call	ObjMessage		; returns cx & dx
		pop	ax, si			; restore ImageBitSize
		
		call	ResizeBMOAndFatbits
done:
		.leave
		ret
DBViewerSetFatbitSize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeBMOAndFatbits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up fatbits view/content and BMO view/content for new size.

CALLED BY:	INTERNAL

PASS:		*ds:si	= DBViewer object
		ax	= ImageBitSize  (word)
		cx	= width of bitmap
		dx	= height of bitmap

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This routine handles resizing the fatbits and real-icon
	content & view (and likely the inverse-icon content and
	view whenever they get implemented.)  We send a
	MSG_VIS_SET_SIZE to each content, followed by a 
	MSG_VIS_MARK_INVALID to force it to redraw.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeBMOAndFatbits	proc	far
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp

		bitSize		local	word	push	ax
		newWidth	local	word	push	cx
		newHeight	local	word	push	dx
		instance	local	word	push	si

		.enter
		
		push	bp			; locals
		mov	bp, ax			; bp <- image bit size
		clrdw	cxdx			; location
		mov	bx, ds:[LMBH_handle]
		mov	si, offset MyFatbits
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, \
		MSG_VIS_FATBITS_SET_IMPORTANT_LOCATION_AND_IMAGE_BIT_SIZE
		call	ObjMessage
		pop	bp			; locals
	;
	;  Set the item-group selection for the current fatbit size
	;
		push	bp			; locals
		GetResourceHandleNS	FatbitImageSizeGroup, bx
		mov	si, offset	FatbitImageSizeGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	cx, bitSize		; cx <- image bit size
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx			; pass nonzero for indeterminate
		call	ObjMessage
		pop	bp			; locals
	;
	;  Set size for the BMO content
	;
		mov	cx, newWidth
		mov	dx, newHeight
		push	bp			; locals
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMOContent
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_SET_SIZE
		call	ObjMessage
		pop	bp			; locals
	;
	;  Resize fatbits content.  First scale the width & height.
	;
		mov	cx, bitSize
		mov	ax, newWidth
		mov	bx, newHeight
		shl	ax, cl			; scale the width
		shl	bx, cl			; scale the height
		mov_tr	cx, ax			; cx <- scaled width
		mov	dx, bx			; dx <- scaled height
		push	cx, dx			; save scaled width & height

		push	bp			; locals
		mov	bx, ds:[LMBH_handle]
		mov	si, offset MyFatbitsContent
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_SET_SIZE
		call	ObjMessage
		pop	bp			; locals
	;
	;  Resize the fatbits.
	;
		pop	cx, dx			; restore scaled width & height

		push	bp			; locals
		mov	si, offset MyFatbits
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_SET_SIZE		
		call	ObjMessage
		pop	bp			; locals
	;
	;  Try to get everything to come out the right size.
	;
		push	bp
		mov	si, instance
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset	; ds:di = DBViewer instance
		mov	bx, ds:[di].GDI_display
		mov	si, offset IconDBDisplay
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		mov	dl, VUM_NOW
		call	ObjMessage
		pop	bp
		
		.leave
		ret
ResizeBMOAndFatbits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateBitmapInBMO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new bitmap using the BMO.

CALLED BY:	GLOBAL

PASS:		ds	= document block (locked)
		ax	= BMFormat	
		cx	= width
		dx	= height

RETURN:		cx = vm file handle for bitmap
		dx = vm block handle for bitmap

DESTROYED:	nothing (ds fixed up)

PSEUDO CODE/STRATEGY:

	When the file/tool handlers create the first two bitmaps
	(not the one to be edited) they need to save them somewhere,
	so they save them in the database entry for the icon.  This
	routine creates the bitmap and copies the vm chain to the file.
	The caller takes the returned handle and saves it in the format
	list.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateBitmapInBMO	proc	far
		class	DBViewerClass
		uses	ax,bx,si,di,bp
		.enter

		push	ax				; save color scheme
	;
	;  Free up data structures for existing bitmap.
	;
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO

		mov	ax, MSG_VIS_BITMAP_BECOME_DORMANT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	;  Create a new bitmap.
	;
		clr	bp				; no gstring for init.
		mov	ax, MSG_VIS_BITMAP_CREATE_BITMAP
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	;  Set color scheme and resolution
	;
		mov	ax, MSG_VIS_BITMAP_SET_FORMAT_AND_RESOLUTION
		pop	cx				; color scheme
		mov	dx, STANDARD_ICON_DPI		; 72 dpi (x resolution)
		mov	bp, dx				; y resolution
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	;  Make the vis bounds match the bitmap bounds -- important.
	;
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_VIS_BOUNDS_MATCH_BITMAP_BOUNDS
		call	ObjMessage
	;
	;  Return the newly-created vm chain
	;
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP	; ^vcx:dx
		call	ObjMessage

		mov	bx, cx
		call	VMUpdate
		
		.leave
		ret
CreateBitmapInBMO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateBitmapDataOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a bitmap and kills its Window & GState

CALLED BY:	GLOBAL

PASS:		al	= BMFormat
		bx	= vm file handle
		cx	= width
		dx	= height

RETURN:		^vcx:dx	= bitmap

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateBitmapDataOnly	proc	far
		uses	ax,bx,si,di
		.enter

		ornf	al, mask BMT_MASK

		clr	di, si			; OD
		call	GrCreateBitmap		; ^vbx:ax = bitmap
		pushdw	bxax

		mov	al, BMD_LEAVE_DATA
		call	GrDestroyBitmap
		call	VMUpdate		; bx is still file handle

		popdw	cxdx

		.leave
		ret
CreateBitmapDataOnly	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerMarkIconDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets DBVI_iconDirty

CALLED BY:	MSG_DB_VIEWER_MARK_ICON_DIRTY

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerMarkIconDirty	method dynamic DBViewerClass, 
					MSG_DB_VIEWER_MARK_ICON_DIRTY
		.enter

		mov	ds:[di].DBVI_iconDirty, 1

		.leave
		ret
DBViewerMarkIconDirty	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGetSelectedFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns selected format #

CALLED BY:	MSG_DB_VIEWER_GET_SELECTED_FORMATS

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		ax	= DBVI_currentFormat

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/25/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGetSelectedFormats	method	dynamic	DBViewerClass,
					MSG_DB_VIEWER_GET_SELECTED_FORMATS

		mov	ax, ds:[di].DBVI_currentFormat

		ret
DBViewerGetSelectedFormats	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGetCurrentIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the currently-edited icon.

CALLED BY:	MSG_DB_VIEWER_GET_CURRENT_ICON

PASS:		ds:di	= DBViewerInstance

RETURN:		ax = current icon

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/25/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGetCurrentIcon	method	dynamic	DBViewerClass,
					MSG_DB_VIEWER_GET_CURRENT_ICON

		mov	ax, ds:[di].DBVI_currentIcon

		ret
DBViewerGetCurrentIcon	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeMemHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up all memory handles for an icon.

CALLED BY:	GLOBAL

PASS:		bp	= vm file handle
		ax	= icon number

RETURN:		nothing
DESTROYED:	nothing (handles freed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	8/24/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeMemHandles	proc	far
		uses	ax,bx,cx,dx,bp
		.enter
	;
	;  If it's not an icon, quit.
	;
		cmp	ax, NO_CURRENT_ICON
		je	done
	;
	;  Call DiscardVMChain on each format.
	;
		call	IdGetFormatCount		; bx = count
		mov	cx, bx
		jcxz	done
formatLoop:
		push	cx, ax
		mov	bx, cx				; format number
		dec	bx				; zero-indexed
		call	IdGetFormat			; ^vcx:dx = format
		movdw	bxax, cxdx
		call	DiscardVMChain

		pop	cx, ax
		loop	formatLoop
done:
		.leave
		ret
FreeMemHandles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerInitiateResizeFormatDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings that baby up.

CALLED BY:	MSG_DB_VIEWER_INITIATE_RESIZE_FORMAT_DIALOG

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerInitiateResizeFormatDialog	method dynamic DBViewerClass, 
				MSG_DB_VIEWER_INITIATE_RESIZE_FORMAT_DIALOG
		.enter
	;
	;  Get the height & width for the current format.
	;
		mov	ax, ds:[di].DBVI_currentIcon
		cmp	ax, NO_CURRENT_ICON
		je	done
		
		mov	bp, ds:[di].GDI_fileHandle
		mov	bx, ds:[di].DBVI_currentFormat
		cmp	bx, NO_CURRENT_FORMAT
		je	done
		
		call	IdGetFormatDimensions	; cx = width, dx = height
	;
	;  Set the height & width GenValues appropriately.
	;
		push	dx			; save height
		mov	bx, ds:[di].GDI_display
		mov	si, offset ResizeWidthValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		clr	bp
		call	ObjMessage
		pop	cx 			; restore height

		mov	si, offset ResizeHeightValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		clr	bp
		call	ObjMessage
	;
	;  Bring up the interaction.
	;
		mov	si, offset ResizeFormatInteraction
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage
done:
		.leave
		ret
DBViewerInitiateResizeFormatDialog	endm


DocumentCode	ends
