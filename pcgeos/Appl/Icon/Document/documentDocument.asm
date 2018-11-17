COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GEOS 2.0
MODULE:		Icon editor
FILE:		documentDocument.asm

AUTHOR:		Steve Yegge, Sep  2, 1992

ROUTINES:

Name					Description
----					-----------
IconSetOptions			- handles a change in the options menu
IconSetFormatArea		- sets usable or not-usable the format area
IconSetFatbits			- sets usable or not-usable the fatbits view

METHOD HANDLERS:

Name							Description	
----							-----------
MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE		File-new
MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT			File-open & new
MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT		File-close
MSG_GEN_DOCUMENT_PHYSICAL_REVERT			File-revert
MSG_GEN_DOCUMENT_PHYSICAL_SAVE				File-save
MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE		File save-as
MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED			File save-as
MSG_GEN_DOCUMENT_OPEN					open

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/ 2/92		Initial revision


DESCRIPTION:
	
	This file implements the GenDocumentControl for the icon editor.

	$Id: documentDocument.asm,v 1.1 97/04/04 16:06:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
idata	segment
		
nullString		char	0
		
idata	ends
		
DocumentCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerInitializeDocumentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implements the code for creating a new icon database.

CALLED BY:	MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

PASS: 		*ds:si	= instance data
		ds:di	= instance data

RETURN:		carry set if error
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- store vm File Handle
	- store filename
	- set FindIconList moniker to current filename
	- create an empty icon list in the file
	- allocate a map block, stuff it and set it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerInitializeDocumentFile	method dynamic DBViewerClass,
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
		.enter
		push	ds:[LMBH_handle], si
	; 
	; Create the icon list. (empty)
	;
		mov	bx, ds:[di].GDI_fileHandle	; our vm file
		mov	cx, size IconHeader		; #bytes per element
		clr	di				; no custom header
		call	HugeArrayCreate			; di = hugearray handle
	;
	;  Allocate a block for the Map Block and lock it.
	;
		mov	cx, size IconMapBlockStruct
		call	VMAlloc			; alloc block, ax = handle
		push	ax			; save handle
		call	VMLock			; returns segment in ax
	;
	;  Indicate that there is no icon being edited yet, and
	;  set the icon list to be the huge array we just created
	;
		mov	ds, ax			; segment of locked map block
		mov	ds:[IMBS_iconList], di	; huge array handle = icon list
		call	VMDirty
		call	VMUnlock		; pass bp = mem handle
	;
	; set the map block -- dirties header as well.  Flush the blocks.
	;
		pop	ax				; restore block handle
		call	VMSetMapBlock			; pass ax = block handle
	;
	;  Set up a temporary vm file for the vis-bitmap object.
	;
		pop	bx, si
		call	MemDerefDS			; *ds:si = DBViewer
		call	CreateVisBitmapTempFile
		jc	done
	;
	;  Create a new blank file icon for the user to poke on,
	;  and set the name to "untitled."
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		call	FileIconHandler

		push	ax, si				; icon number
		GetResourceHandleNS	IconStrings, bx
		mov	si, offset UntitledString	; new name
		call	MemLock
		mov	es, ax
		mov	dx, es:[si]			; dereference string
		mov	cx, es				; cx:dx = name

		pop	ax, si				; icon number
		call	FinishInitializingIcon		; sets preview colors
		call	MemUnlock
		
		clc					; return no error

done:
		.leave
		ret
DBViewerInitializeDocumentFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerAttachUIToDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up UI for a new database opening.

CALLED BY:	MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

PASS: 		*ds:si	= DBViewer object
		ds:[di]	= instance data

RETURN:		nothing
DESTROYED:	ax, cx, cx, bp

PSEUDO CODE/STRATEGY:

	- store the file handle and huge array handle in udata
	- get the map block
	- initialize the find-icon GenDynamicList

	Note to me:  this message is received for file-new, file-revert
	and file-open.  Thus IconReadDatabase has to handle base case
	(no entries in array) as well as the case for opening a file
	with icons in it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerAttachUIToDocument	method dynamic DBViewerClass, 
					MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	;
	;  Have the superclass do its thing.
	;
		mov	di, offset DBViewerClass
		call	ObjCallSuperNoLock
	;
	;  Register with the clipboard
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	ClipboardAddToNotificationList
	;
	;  Set up a temporary vm file for the vis-bitmap object if
	;  it hasn't been done already.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		tst	ds:[di].DBVI_bitmapVMFileHandle
		jnz	doneCreate
		
		call	CreateVisBitmapTempFile
doneCreate:
	;
	;  Link all the views to the contents.
	;
		call	LinkDisplayViewsToDocumentContents
		call	InitializeGenValues	; set reasonable defaults
	;
	;  Make sure we've got the right options from options menu.
	;
		push	si
		GetResourceHandleNS	OptionsBooleanGroup, bx
		mov	si, offset	OptionsBooleanGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjMessage		; returns options in ax
		pop	si

		mov_tr	cx, ax			; cx <- options
		mov	ax, MSG_DB_VIEWER_SET_OPTIONS
		call	ObjCallInstanceNoLock
	;
	;  Force editing of an icon...we do this because countless
	;  people demo'ing the software bitched that they couldn't 
	;  start using the editor until they'd created an icon.
	;  If there's no icon, it means the user deliberately
	;  opened a previously-created database with no icons in
	;  it, so we'll assume they know what they're doing.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetIconCount		; ax = count
		tst	ax
		jz	noIcon
	;
	;  Set the selection in the viewer (IconEditIcon needs this),
	;  and switch editing to first icon.  First we have to add a
	;  child for each icon in the database, and then set the 
	;  selection to the current icon (DBViewerEditIcon requires
	;  this).
	;
		mov	ax, MSG_DB_VIEWER_RESCAN_DATABASE
		call	ObjCallInstanceNoLock
	;
	;  I used to set DBVI_currentIcon to zero here, but it's
	;  somewhat redundant, since it gets done in DBViewerEditIcon.
	;  Also, it now makes the app crash, since DBViewerEditIcon
	;  attempts to discard the mem blocks from the previous icon.
	;  We set it to NO_CURRENT_ICON instead.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON

		clr	cx			; edit first icon
		mov	ax, MSG_DB_VIEWER_SET_SINGLE_SELECTION
		clr	bp			; UIFunctionsActive
		call	ObjCallInstanceNoLock

		mov	ax, MSG_DB_VIEWER_EDIT_ICON
		call	ObjCallInstanceNoLock
		
		jmp	short	done
noIcon:
	;
	;  Disable editing, since there's no icon to edit.
	;
		call	DisableEditing
done:
		ret
DBViewerAttachUIToDocument	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerWriteCachedDataToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the icon & updates the UI.

CALLED BY:	MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerWriteCachedDataToFile	method dynamic DBViewerClass, 
				MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE
		uses	ax
		.enter

		mov	ax, MSG_DB_VIEWER_SAVE_CURRENT_ICON
		call	ObjCallInstanceNoLock

		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerWriteCachedDataToFile	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateVisBitmapTempFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates and sets the temporary vm file used by the bitmap.

CALLED BY:	DBViewerAttachUIToDocument

PASS:		*ds:si	= DBViewer object
		es	= dgroup

RETURN:		carry set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Create a temp file for the bitmap to use.  Note:  A year
	later I'm adding some code to clear VBI_mainKit.VBK_bitmap
	if VMInfo tells me it's a bad handle, to prevent crashes
	after saving to/restoring from state (what happens is the
	old temp file got nuked, but the bitmap object still has
	a handle to a bitmap in that file, so we have to clear it).

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/22/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateVisBitmapTempFile	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
		
		push	ds:[LMBH_handle], si	; save DBViewer object
	;
	;  Construct a pathname for SP_WASTE_BASKET.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		push	si
		
		mov	dx, 1			; add drive name to path
		mov	bx, SP_WASTE_BASKET	; put in the privdata dir.
		segxchg	es, ds			; es:di = name buffer
		lea	di, es:[di].DBVI_bitmapTempFileName
		mov	si, offset nullString	; ds:si = nullstring for tail
		mov	cx, size PathName
		call	FileConstructFullPath
		
		pop	si
		segmov	ds, es, di		; *ds:si = DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	;  Create a temporary VM file for the bitmap to use
	;
		mov	ah, VMO_TEMP_FILE	; this is a temporary file
		mov	al, mask VMAF_FORCE_READ_WRITE
		clr	cx			; use system default compression
		lea	dx, ds:[di].DBVI_bitmapTempFileName
		call	VMOpen			; returns bx = handle
		mov	cx, bx			; cx = handle
		
		pop	bx, si			; restore DBViewer object
		jc	error
		
		call	MemDerefDS		; *ds:si = DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].DBVI_bitmapVMFileHandle, cx
	;
	;  Tell the VisBitmap to use the VM file we just allocated
	;
		mov	si, offset BMO
		mov	ax, MSG_VIS_BITMAP_SET_VM_FILE
		call	ObjCallInstanceNoLock
	;
	;  Clear the bitmap's VBK_bitmap field if necessary.
	;
		mov	ax, MSG_ICON_BITMAP_CHECK_BITMAP
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
error:
		mov	si, offset CantCreateTempFileText
		call	DisplayError
		stc
		jmp	done
CreateVisBitmapTempFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeGenValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets defaults for GenValue objects in the application

CALLED BY:	DBViewerAttachUIToDocument

PASS:		*ds:si	= DBViewer object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- set values for resize-format width & height
	- set values for custom-size chooser (width & height)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeGenValues	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		
		mov	bx, ds:[di].GDI_display
		mov	si, offset CustomWidthValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	cx					; fraction
		mov	dx, DEFAULT_CUSTOM_WIDTH
		clr	bp					; determinate
		call	ObjMessage
		
		mov	si, offset	CustomHeightValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	cx
		mov	dx, DEFAULT_CUSTOM_HEIGHT
		clr	bp
		call	ObjMessage
		
		mov	si, offset	ResizeWidthValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	cx
		mov	dx, DEFAULT_RESIZE_WIDTH
		clr	bp
		call	ObjMessage
		
		mov	si, offset	ResizeHeightValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	cx
		mov	dx, DEFAULT_RESIZE_HEIGHT
		clr	bp
		call	ObjMessage
		
		.leave
		ret
InitializeGenValues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkDisplayViewsToDocumentContents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Manually sets up the links in the newly-duplicated blocks.

CALLED BY:	DBViewerAttachUIToDocument

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/22/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkDisplayViewsToDocumentContents	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  BMO and BMOView
	;
		push	si
		mov	bx, ds:[di].GDI_display		; view block
		mov	si, offset BMOView
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		mov	cx, ds:[LMBH_handle]
		mov	dx, offset BMOContent		; ^lcx:dx = content
		call	ObjMessage
		pop	si
	;
	;  Fatbits and fatbits view
	;
		push	si
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_display		; view block
		mov	si, offset FatbitsView
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		mov	cx, ds:[LMBH_handle]
		mov	dx, offset MyFatbitsContent	; ^lcx:dx = content
		call	ObjMessage
		pop	si
	;
	;  Fatbits and BMO
	;
		push	si
		mov	bx, ds:[LMBH_handle]
		mov	si, offset MyFatbits
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_FATBITS_SET_VIS_BITMAP
		mov	cx, bx
		mov	dx, offset BMO			; ^lcx:dx = bitmap
		call	ObjMessage
		pop	si
	;
	;  BMO and fatbits
	;
		push	si
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL
		mov	ax, MSG_ICON_BITMAP_SET_FATBITS
		mov	cx, bx
		mov	dx, offset MyFatbits
		call	ObjMessage
		pop	si
	;
	;  Formats and format view
	;
		push	si
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_display		; view block
		mov	si, offset FormatView
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		mov	cx, ds:[LMBH_handle]
		mov	dx, offset FormatViewer		; ^lcx:dx = content
		call	ObjMessage
		pop	si
	;
	;  Transform-dialog contents & views.
	;
		push	si
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFSourceDisplayView
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		mov	cx, ds:[LMBH_handle]
		mov	dx, offset TFSourceDisplayContent
		call	ObjMessage
		pop	si
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFDestDisplayView
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		mov	cx, ds:[LMBH_handle]
		mov	dx, offset TFDestDisplayContent
		call	ObjMessage

		.leave
		ret
LinkDisplayViewsToDocumentContents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerDetachUIFromDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the bitmap vm file.

CALLED BY:	MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerDetachUIFromDocument	method dynamic DBViewerClass, 
				MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
		uses	ax, si
		.enter
	;
	;  Save message and chunk handle for superclass
	;
		mov	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
	;
	;  Un-register with clipboard.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	ClipboardRemoveFromNotificationList
	;
	;  Tell the BMO content we're dying.  (ack)
	;
		push	si
		mov	si, offset BMOContent
		mov	ax, MSG_BMO_CONTENT_SHUTTING_DOWN
		call	ObjCallInstanceNoLock
		pop	si

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	;  Pop-in the format list (or suffer hideous death).
	;
		push	si
		mov	bx, ds:[di].GDI_display
		mov	si, offset FormatViewGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_INTERACTION_POP_IN
		call	ObjMessage
		pop	si
	;
	;  Tell the bitmap to be dormant.  This should be done so
	;  if we're shutting down to state, the bitmap doesn't come
	;  back up with a bunch of bad handles.  This also kills
	;  the selection ants.
	;
		push	si				; database viewer
		mov	si, offset BMO
		mov	ax, MSG_VIS_BITMAP_BECOME_DORMANT
		call	ObjCallInstanceNoLock
		pop	si
	;
	;  Clear out all the contents' pointers to the views.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		call	UnlinkDisplayViewsAndDocumentContents
	;
	;  Nuke the saved bitmap optr in the application object.
	;
		clrdw	cxdx				; no bitmap
		GetResourceHandleNS	IconApp, bx
		mov	si, offset	IconApp
		mov	di, mask MF_CALL
		mov	ax, MSG_ICON_APPLICATION_NEW_MODEL
		call	ObjMessage

		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerDetachUIFromDocument	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlinkDisplayViewsAndDocumentContents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears out the fields we set (by hand) in attach-ui-to-doc.

CALLED BY:	DBViewerDetachUIFromDocument

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- send a MSG_GEN_VIEW_SET_CONTENT to each view, passing 0 for the
	  optr.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/16/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlinkDisplayViewsAndDocumentContents	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  BMO and BMOView
	;
		mov	bx, ds:[di].GDI_display		; view block
		mov	si, offset BMOView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		clrdw	cxdx
		call	ObjMessage
	;
	;  Fatbits and fatbits view
	;
		mov	si, offset FatbitsView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		clrdw	cxdx
		call	ObjMessage
if 0
	;
	;  Fatbits and BMO
	;
		push	si
		mov	bx, ds:[LMBH_handle]
		mov	si, offset MyFatbits
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_FATBITS_SET_VIS_BITMAP
		mov	cx, bx
		mov	dx, offset BMO			; ^lcx:dx = bitmap
		call	ObjMessage
		pop	si
	;
	;  BMO and fatbits
	;
		push	si
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL
		mov	ax, MSG_ICON_BITMAP_SET_FATBITS
		mov	cx, bx
		mov	dx, offset MyFatbits
		call	ObjMessage
		pop	si
endif
	;
	;  Formats and format view
	;
		mov	si, offset FormatView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		clrdw	cxdx
		call	ObjMessage
	;
	;  Transform-dialog contents & views.
	;
		mov	si, offset TFSourceDisplayView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		clrdw	cxdx
		call	ObjMessage

		mov	si, offset TFDestDisplayView
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		clrdw	cxdx
		call	ObjMessage

		.leave
		ret
UnlinkDisplayViewsAndDocumentContents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerPhysicalClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the bitmap vm file.

CALLED BY:	MSG_GEN_DOCUMENT_PHYSICAL_CLOSE

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		ax	= the message

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerPhysicalClose	method dynamic DBViewerClass, 
			MSG_GEN_DOCUMENT_PHYSICAL_CLOSE
		uses	ax, si
		.enter
	;
	;  Close the bitmap temp file. If there's no file, we must have had
	;  trouble creating it, so there's nothing to do here.
	;
		mov	bx, ds:[di].DBVI_bitmapVMFileHandle
		tst	bx
		jz	callSuper

		mov	al, FILE_NO_ERRORS
		call	VMClose
	;
	;  Delete the temp vm file we created for the bitmap object.
	;
		lea	dx, ds:[di].DBVI_bitmapTempFileName	
		call	FileDelete			; ds.dx = filename
		jnc	noError
	;
	;  carry set--we couldn't delete the vm file.
	;  don't display the error if we are detaching because the 
	;  UI is already gone and we can't respond to the dialog
	;		
		cmp	ds:[di].GDI_operation, GDO_DETACH
		je	noError
		mov	si, offset CantDeleteTempFileText
		call	DisplayError
noError:
	;
	;  Clear the handle field for the temp file, so that if
	;  we were shut down to state and restart, we'll create
	;  a brand new temp file instead of dying.
	;
		clr	ds:[di].DBVI_bitmapVMFileHandle

callSuper:
		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerPhysicalClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGainedModelExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the currently selected tool and sends to bitmap.

CALLED BY:	MSG_META_GAINED_MODEL_EXCL

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGainedModelExcl	method dynamic DBViewerClass,
			MSG_META_GAINED_MODEL_EXCL
		uses	ax, si
		.enter
	;
	;  This gets called twice on startup, once here and once
	;  when we edit the icon.  It'd be nice if we could make
	;  that just a single call...
	;
		call	SetUpPreviewStuff
	;
	;  Before we stick our optr in the application, we ask the
	;  old bitmap for its tool class.
	;
		GetResourceHandleNS	IconApp, bx
		mov	si, offset	IconApp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_ICON_APPLICATION_GET_BITMAP_OPTR
		call	ObjMessage			; ^lcx:dx = bitmap
		tst	dx
		jz	noTool

		movdw	bxsi, cxdx
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_ICON_BITMAP_GET_TOOL	; get current tool
		call	ObjMessage			; cx:dx = tool class

		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_CREATE_TOOL
		call	ObjMessage

		jmp	short	doneTool
noTool:
	;
	;  There was no previous bitmap, so we'll just create a pencil
	;  tool.  (There has to be a tool created or it will die when
	;  you try to edit the bitmap.)
	;
		mov	cx, segment	PencilToolClass
		mov	dx, offset	PencilToolClass
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_CREATE_TOOL
		call	ObjMessage
doneTool:
	;
	;  Notify the application that we've gained the model, and
	;  have the application object store the optr of our BMO.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, offset BMO			; ^lcx:dx = bitmap
		GetResourceHandleNS	IconApp, bx
		mov	si, offset	IconApp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_ICON_APPLICATION_NEW_MODEL
		call	ObjMessage
	;
	;  Send out all the controller notifications.
	;
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_ICON_BITMAP_SEND_NOTIFICATIONS
		call	ObjMessage
	;
	;  Make sure the BMO has the target.  (Hahaha, yeah right.)
	;
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_META_GRAB_TARGET_EXCL
		call	ObjMessage
	;
	;  Let the superclass do its thing.
	;
		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerGainedModelExcl	endm


DocumentCode ends
