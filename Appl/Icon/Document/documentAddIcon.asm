COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Icon editor
MODULE:		Document
FILE:		documentAddIcon.asm

AUTHOR:		Steve Yegge, Sep 11, 1992

ROUTINES:

	Name				Description
	----				-----------
	GetPreviewSettings		-- gets preview colors and object
	FileIconHandler			-- creates a new file icon
	ToolIconHandler			-- creates a new tool icon
	PtrImageHandler			-- creates a new pointer image
	CustomIconHandler		-- creates a new custom icon
	GetUserCustomSettings		-- checks dialog for height & width
	GetCustomIconFormatParameters   -- return a VisMonikerListEntryType 
					   for the custom icon format

METHOD HANDLERS:

	Name				Description
	----				-----------
	MSG_DB_VIEWER_ADD_ICON		-- creates a new icon into database
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/11/92		Initial revision


DESCRIPTION:
	
	This file contains routines for creating a new icon.

	$Id: documentAddIcon.asm,v 1.1 97/04/04 16:06:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocAddIcon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerAddIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new icon.

CALLED BY:	MSG_DB_VIEWER_ADD_ICON

PASS:		*ds:si	= DBViewer object
		ds:[di]	= DBViewer instance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- see if the current icon is dirty and prompt for save
	- fill in anIconHeader in udata:
		- get name
		- get preview settings
		- get type
		- create the format(s)
	- update the database viewer
	- dirty the vm file
	- enable ui gadgetry
	- switch editing to new icon
	- set the map block in the database to edit this icon

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	 8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerAddIcon	method dynamic DBViewerClass,
						MSG_DB_VIEWER_ADD_ICON
		uses	ax, cx, dx, bp
		
		nameBuffer	local	FileLongName
		
		.enter
	;
	;  Set up the format based on the type of icon we're adding.
	;
		push	si, bp				; save DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	bx, ds:[di].GDI_display
		mov	si, offset AddTypeGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	; returns in ax
		call	ObjMessage
		pop	si, bp				; *ds:si = DBViewer
		push	ax				; save icon type
	;
	;  Get the name of the icon and store it on the stack.
	;
		push	si, bp				; save DBViewer
		mov	dx, ss
		lea	bp, ss:[nameBuffer]
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	bx, ds:[di].GDI_display
		mov	si, offset	AddNameField	; ^lbx:si = target
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage			; cx = length
		inc	cx				; include NULL
		pop	si, bp				; restore DBViewer
	;
	;  Set up and call AddIconCommon.
	;
		pop	bx				; bx = icon type
		lea	dx, ss:[nameBuffer]
		mov	cx, ss				; cx:dx = name
		
		call	AddIconCommon

		.leave
		ret
DBViewerAddIcon	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddIconCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common functionality for creating an icon.

CALLED BY:	DBViewerAddIcon, DBViewerInitializeDocumentFile

PASS:		*ds:si	= DBViewer object
		bx	= CreateNewIconType
		cx:dx	= buffer containing icon name (null terminated)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/ 2/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddIconCommon	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;		
	;  Mark the app as busy.
	;
		call	IconMarkBusy
	;
	;  Check to see if the current icon is dirty, and deal with it.
	;
		call	CheckIconDirtyAndDealWithIt
		LONG	jc	done			; user cancelled
	;
	;  Use the passed CreateNewIconType to get the
	;  appropriate handler.
	;
EC <		cmp	bx, CreateNewIconType				>
EC <		ERROR_AE INVALID_CREATE_ICON_TYPE			>
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset		; ds:di = instance
		
		mov	bx, cs:[handlerTable][bx]
		call	bx
	;
	;  ax = new icon's number...get the name & preview colors for it.
	;
		call	FinishInitializingIcon
	;
	;  Do lots of other stuff.  EnableEditing causes the block to
	;  move, so we make sure to re-dereference the instance data after.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset		; ds:di = instance
		call	EnableEditing			; ui gadgetry
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		clr	ds:[di].DBVI_currentFormat	; for IconDrawFormats
	;
	;  Show the new icon in various places:  the preview dialog,
	;  the export-icon dialog, and the format viewer.
	;
		mov	ax, MSG_DB_VIEWER_UPDATE_PREVIEW_AREA
		call	ObjCallInstanceNoLock	; sets preview monikers

		mov	ax, MSG_DB_VIEWER_INIT_CHANGE_ICON_DIALOG
		call	ObjCallInstanceNoLock

		push	si
		mov	si, offset FormatViewer
		mov	ax, MSG_FORMAT_CONTENT_RESCAN_LIST
		call	ObjCallInstanceNoLock

		mov	si, offset BMO
		mov	ax, MSG_ICON_BITMAP_SEND_NOTIFICATIONS
		call	ObjCallInstanceNoLock
		pop	si
	;
	;  Create a vis-icon in the viewer.
	;
		mov	ax, MSG_DB_VIEWER_RESCAN_DATABASE
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
		call	ObjCallInstanceNoLock
	;
	;  Mark the app as unbusy.
	;
		call	IconMarkNotBusy
done:
		.leave
		ret

handlerTable	word	\
		offset	FileIconHandler,
		offset	ToolIconHandler,
		offset	PtrImageHandler,
		offset	CustomIconHandler

AddIconCommon	endp
 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileIconHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new file icon.

CALLED BY:	DBViewerAddIcon

PASS:		*ds:si	= DBViewer object
		ds:[di]	= DBViewerInstance

RETURN:		ax	= new icon number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
	File icons start with 5 formats:
		standard color: 	48x30 16-color		normal
		standard mono:		48x30 mono		normal
		standard CGA:	  	48x14 mono		verySquished

		tiny color:		32x20 16-color		normal
		tiny mono:		32x20 mono		normal

	These formats are created in reverse order, so that the last
	one is in the Vis-bitmap object when we begin editing (the
	color one.)  They get stored in the database with tiny mono last,
	so we start by pointing di to the 5th format, and move it
	back until we get to the first one.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
	An explanation of the data structure for the database can be
	found in iconFile.def

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileIconHandler	proc	far
		class	DBViewerClass
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	;  Add a blank icon to the database, with n blank formats.
	;
		mov	bp, ds:[di].GDI_fileHandle
		mov	cx, DEFAULT_STARTING_FILE_FORMATS
		call	IdAddIcon			; returns position in ax
		mov	ds:[di].DBVI_currentIcon, ax
	;
	;  Set the format count to 5, since that's what we start with.
	;  IH_format is already set to 0 by IdAddIcon.
	;
		mov	bx, DEFAULT_STARTING_FILE_FORMATS
		call	IdSetFormatCount
	;
	;  Make a 32x20 monochrome bitmap & copy it (zoomer mono).
	;
		mov	ax, BMF_MONO
		mov	cx, TINY_MONO_FILE_MONIKER_WIDTH
		mov	dx, TINY_MONO_FILE_MONIKER_HEIGHT
		mov	bx, bp			; file handle
		call	CreateBitmapDataOnly	; create the actual bitmap

		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, 4			; 5th format
		call	IdSetFormatNoCopy	; stick in database

		mov	cx, FP_TINY_MONO_FILE
		clr	dx			; passing etype
		call	IdSetFormatParameters
	;
	;  Make a 32x20 color bitmap and copy it into database.
	;
		mov	ax, BMF_4BIT
		mov	cx, TINY_COLOR_FILE_MONIKER_WIDTH
		mov	dx, TINY_COLOR_FILE_MONIKER_HEIGHT
		mov	bx, bp			; file handle
		call	CreateBitmapDataOnly	; create the actual bitmap

		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, 3			; 4th format 
		call	IdSetFormatNoCopy	; stick in database

		mov	cx, FP_TINY_COLOR_FILE
		clr	dx			; passing etype
		call	IdSetFormatParameters
	;
	;  Make a 48x14 monochrome bitmap & copy it. (CGA)
	;
		mov	ax, BMF_MONO		; monochrome
		mov	cx, STANDARD_CGA_FILE_MONIKER_WIDTH
		mov	dx, STANDARD_CGA_FILE_MONIKER_HEIGHT
		mov	bx, bp			; file handle
		call	CreateBitmapDataOnly	; returns ^vcx:dx = bitmap
		
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, 2			; it'll be the 3rd format
		call	IdSetFormatNoCopy

		mov	cx, FP_STANDARD_CGA_FILE
		clr	dx			; FormatParameters passed
		call	IdSetFormatParameters
	;
	;  Now make a 48x30 monochrome bitmap and copy it. (MCGA)
	;
		mov	ax, BMF_MONO
		mov	cx, STANDARD_MONO_FILE_MONIKER_WIDTH
		mov	dx, STANDARD_MONO_FILE_MONIKER_HEIGHT
		mov	bx, bp
		call	CreateBitmapDataOnly	; returns ^vcx:dx = bitmap
		
		mov	bx, 1
		mov	ax, ds:[di].DBVI_currentIcon
		call	IdSetFormatNoCopy
		
		mov	cx, FP_STANDARD_MCGA_FILE
		clr	dx			; FormatParameters passed
		call	IdSetFormatParameters
	;
	;  Make a 48x30 color bitmap and copy it, as the first format.
	;  This one will be edited, right away, so we stick it in the
	;  vis-bitmap.
	;
		mov	ax, BMF_4BIT
		mov	cx, STANDARD_COLOR_FILE_MONIKER_WIDTH
		mov	dx, STANDARD_COLOR_FILE_MONIKER_HEIGHT
		
		call	CreateBitmapInBMO	; returns ^vcx:dx = bitmap
		
		clr	bx
		mov	ax, ds:[di].DBVI_currentIcon
		call	IdSetFormat
		
		mov	cx, FP_STANDARD_VGA_FILE
		clr	dx			; FormatParameters passed
		call	IdSetFormatParameters
	;
	;  Now make the views resize around the new bitmap (0th format).
	;
 		call	IconAppGetImageBitSize	; ax = ImageBitSize
		mov	cx, STANDARD_COLOR_FILE_MONIKER_WIDTH
		mov	dx, STANDARD_COLOR_FILE_MONIKER_HEIGHT
		call	ResizeBMOAndFatbits
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].DBVI_currentIcon
		
		.leave
		ret
FileIconHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolIconHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Creates a new tool icon.

CALLED BY:	DBViewerAddIcon

PASS:		*ds:si	= DBViewer object
		ds:[di]	= DBViewerInstance

RETURN:		ax	= new icon's number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
	Tool icons have 3 standard formats:
		tiny color: 15x15 16-color	
		tiny mono:  15x15 mono
		tiny CGA:   15x10 mono

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
	An explanation of the data structure for the databse can be
	found in iconFile.def

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolIconHandler	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	;  Add a blank icon to the database.
	;
		mov	bp, ds:[di].GDI_fileHandle
		mov	cx, 3				; 3 new formats
		call	IdAddIcon			; returns position in ax
		mov	ds:[di].DBVI_currentIcon, ax
	;
	;  Set the format count to 3, since that's what we start with.
	;  IH_format is already set to 0 by IdAddIcon.
	;
		mov	bx, 3
		call	IdSetFormatCount
	;
	;  Make a 15x10 monochrome bitmap & copy it.
	;
		mov	ax, BMF_MONO			; monochrome
		mov	cx, STANDARD_CGA_TOOL_MONIKER_WIDTH
		mov	dx, STANDARD_CGA_TOOL_MONIKER_HEIGHT
		mov	bx, bp		
		call	CreateBitmapDataOnly		; ^vcx:dx = bitmap
		
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, 2				; it'll be 3rd format
		call	IdSetFormatNoCopy

		mov	cx, FP_STANDARD_CGA_TOOL
		clr	dx
		call	IdSetFormatParameters
	;
	;  Now make a 15x15 monochrome bitmap and copy it. (decrement di)
	;
		mov	ax, BMF_MONO
		mov	cx, STANDARD_MONO_TOOL_MONIKER_WIDTH
		mov	dx, STANDARD_MONO_TOOL_MONIKER_HEIGHT
		mov	bx, bp
		call	CreateBitmapDataOnly		; ^vcx:dx = bitmap
		
		mov	bx, 1				; second format
		mov	ax, ds:[di].DBVI_currentIcon
		call	IdSetFormatNoCopy
		
		mov	cx, FP_STANDARD_MCGA_TOOL
		clr	dx
		call	IdSetFormatParameters
	;
	;  Make a 15x15 color bitmap and copy it, as the first format.
	;  This one will be edited immediately, so create it in the
	;  bitmap object.
	;
		mov	ax, BMF_4BIT
		mov	cx, STANDARD_COLOR_TOOL_MONIKER_WIDTH
		mov	dx, STANDARD_COLOR_TOOL_MONIKER_HEIGHT
		
		call	CreateBitmapInBMO		; ^vcx:dx = bitmap

		clr	bx				; first format
		mov	ax, ds:[di].DBVI_currentIcon
		call	IdSetFormat
		
		mov	cx, FP_STANDARD_VGA_TOOL
		clr	dx
		call	IdSetFormatParameters
	;
	;  Now make the views resize around the new bitmap (0th format).
	;
		call	IconAppGetImageBitSize		; al = ImageBitSize
		mov	cx, STANDARD_COLOR_TOOL_MONIKER_WIDTH
		mov	dx, STANDARD_COLOR_TOOL_MONIKER_HEIGHT
		call	ResizeBMOAndFatbits
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].DBVI_currentIcon
		
		.leave
		ret
ToolIconHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PtrImageHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new 16x16 icon (as a mouse cursor).

CALLED BY:	DBViewerAddIcon

PASS:		*ds:si	= DBViewer object
		ds:[di]	= DBViewerInstance

RETURN:		ax	= new icon's number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
	Pointer images have 1 format, and are 16x16 in 2.0.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	An explanation of the data structure for the database can be
	found in iconFile.def

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PtrImageHandler	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	;  Add a blank icon to the database.
	;
		mov	bp, ds:[di].GDI_fileHandle
		mov	cx, 1				; 1 blank format
		call	IdAddIcon			; returns position in ax
		mov	ds:[di].DBVI_currentIcon, ax
	;
	;  Set the format count to 1, since that's what we start with.
	;  IH_format is already set to 0 by IdAddIcon.
	;
		mov	bx, 1
		call	IdSetFormatCount
 	;
	;  Make a 16x16 color bitmap and copy it, as the first format.
	;  It will be edited immediately so create it in the BMO.
	;
		
		mov	ax, BMF_4BIT
		mov	cx, STANDARD_PTR_IMAGE_WIDTH
		mov	dx, STANDARD_PTR_IMAGE_HEIGHT
		
		call	CreateBitmapInBMO	; returns ^vcx:dx = bitmap
		
		clr	bx				; 1st format
		mov	ax, ds:[di].DBVI_currentIcon
		call	IdSetFormat
	;
	;  Make sure the fatbits are the right size.
	;
		call	IconAppGetImageBitSize		; al = fatbit size
		mov	cx, STANDARD_PTR_IMAGE_WIDTH
		mov	dx, STANDARD_PTR_IMAGE_HEIGHT
		call	ResizeBMOAndFatbits
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].DBVI_currentIcon
		
		.leave
		ret
PtrImageHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustomIconHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Creates a new icon of user-specified dimensions.

CALLED BY:	DBViewerAddIcon

PASS:		*ds:si	= DBViewer object
		ds:[di]	= DBViewer instance

RETURN:		ax	= new icon's number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This routine gets the size out of the CustomHeightValue and
	CustomWidthValue objects, and the color out of the CustomColorScheme
	list.  After filling the idata structure it adds the icon
	to the database and creates a bitmap for the bitmap object.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

	An explanation of the data structure for the databse can be
	found in iconFile.def

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 5/92		Initial version
	lester	1/12/92		added code to set the format parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CustomIconHandler	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	;  First see if this sumbitch is too big.
	;
		call	GetUserCustomSettings
		call	CheckFormatTooLargeAndDealWithIt
		jc	done
	;
	;  Add a blank icon to the database.
	;
		mov	bp, ds:[di].GDI_fileHandle
		mov	cx, 1			; 1 new format
		call	IdAddIcon		; returns ax = number
		mov	ds:[di].DBVI_currentIcon, ax
	;
	;  Set the format count to 1, since that's what we start with.
	;  IH_format is already set to 0 by IdAddIcon.
	;
		mov	bx, 1
		call	IdSetFormatCount
	;
	;  Get the custom settings for the new bitmap and create it.
	;  (Using the bitmap object, since it will be edited immediately).
	;
		call	GetUserCustomSettings	; returns format, width, height
		push	cx, dx			; save width, height
		push	ax			; save BMFormat
		call	CreateBitmapInBMO	; returns ^vcx:dx = bitmap

		mov	ax, ds:[di].DBVI_currentIcon
		clr	bx			; first format
		call	IdSetFormat
	;
	;  Set the Format Parameters
	;
		pop	bx			; restore BMFormat
		call	GetCustomIconFormatParameters
		; cx	= VisMonikerListEntryType

		; bp = file handle
		; bx = format number
		mov	ax, ds:[di].DBVI_currentIcon
		mov	dx, 1		; pass VisMonikerListEntryType in cx
		call	IdSetFormatParameters
	;
	;  Make all the views and contents resize properly.
	;
		pop	cx, dx			; restore width, height
		call	IconAppGetImageBitSize
		call	ResizeBMOAndFatbits

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].DBVI_currentIcon
		clc
done:
		.leave
		ret
CustomIconHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCustomIconFormatParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return a VisMonikerListEntryType for the custom icon format

CALLED BY:	CustomIconHandler
PASS:		bl = BMFormat
RETURN:		cx = VisMonikerListEntryType
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

	We set the format color scheme and use default values for the format
	style (VMS_ICON), display size (DS_STANDARD), and aspect ratio
	(DAR_NORMAL).  
	If the user wants to alter the default settings, he can use the 
	transform format dialog.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	1/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCustomIconFormatParameters	proc	near
		uses	ax, bx
		.enter
	;
	;  cx = generic VisMonikerListEntryType
	; 
		mov	cx, cs:[customEntryType]
	;
	;  Get the color scheme.
	;
EC <		cmp	bl, BMF_24BIT					>
EC <		ERROR_A	INVALID_BITMAP_FORMAT				>
		
		clr	bh				; bx = DisplayClass
		shl	bx				; word table
		mov	ax, cs:[DisplayClassTable][bx]
	;
	;  Clear the current color from cx's VisMonikerListEntryType;
	;  set the new one.
	;
		andnf	cx, not mask VMLET_GS_COLOR
		ornf	cx, ax
	;
	;  return the VisMonikerListEntryType in cx
	;
		.leave
		ret

DisplayClassTable	word \
		DC_GRAY_1 shl offset VMLET_GS_COLOR,
		DC_COLOR_4 shl offset VMLET_GS_COLOR,
		DC_COLOR_8 shl offset VMLET_GS_COLOR,
		DC_CF_RGB shl offset VMLET_GS_COLOR

customEntryType VisMonikerListEntryType	\
	<DS_STANDARD,VMS_ICON,,TRUE,DAR_NORMAL,DC_COLOR_4>

GetCustomIconFormatParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetUserCustomSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets user-defined height, width and color scheme from dialog.

CALLED BY:	CustomIconHandler

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		al = BMFormat
		cx = width
		dx = height

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	The identifiers for the color-scheme selectors are all of type
	DisplayClass, so we have to convert into a BMFormat before
	returning.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetUserCustomSettings	proc	near
		class	DBViewerClass
		uses	bx,si,di,bp
		.enter
	;
	;  Get user-defined width for the custom icon
	;
		mov	bx, ds:[di].GDI_display
		mov	si, offset CustomWidthValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjMessage
		push	dx				; save block & width
	;
	;  Get user-defined height for the custom icon
	;
		mov	si, offset CustomHeightValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; dx = integer value
		call	ObjMessage			; nukes ax, bp
		push	dx				; save height
	;
	;  Get user-defined color scheme
	;
		mov	si, offset	CustomColorSchemeChooser
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage			; al = BMFormat
		
		pop	dx				; restore height
		pop	cx				; restore width
		
		.leave
		ret
GetUserCustomSettings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishInitializingIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the name & preview colors for the new icon.

CALLED BY:	DBViewerAddIcon, AddIconFromImportedBitmap

PASS:		*ds:si	= DBViewer object
		ax	= icon number
		cx:dx	= null-term buffer containing name

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/18/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FinishInitializingIcon	proc	far
		class	DBViewerClass
		uses	ax,bx,cx,dx,di,bp
		.enter
		
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
	;
	;  Set the name in the icon.
	;
		mov	bp, ds:[di].GDI_fileHandle
		mov	bx, cx				; bx:dx = name
		pushdw	esdi
		movdw	esdi, bxdx
		call	LocalStringLength
		inc	cx				; include NULL
		popdw	esdi
		call	IdSetIconName
	;
	;  Now set the preview colors in the icon (query the selectors).
	;
		call	GetPreviewSettings		; cx, dx = colors
							; bx = object
		call	IdSetPreviewObject
		call	IdSetPreviewColors

		.leave
		ret
FinishInitializingIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPreviewSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current preview settings.

CALLED BY:	DBViewerAddIcon, AddIconFromImportedBitmap

PASS: 		nothing

RETURN:		ch	= on color 1
		cl	= on color 2
		dh	= off color 1
		dl	= off color 2
		bx	= object type (PreviewGroupInteractionObject)

DESTROYED:	nothing (ds fixed up)

PSEUDO CODE/STRATEGY:

	Gets type and colors (on/off) by querying the Preview
	dialog.  This stuff needs to get stored in the database
	so when the icon is re-opened all the preview stuff can
	be set up properly.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPreviewSettings	proc	far
		class	DBViewerClass
		uses	ax,si,di,bp
		.enter
	;
	;  Get preview settings stuff, starting with type.
	;	
		GetResourceHandleNS	PreviewListGroup, bx
		mov	si, offset	PreviewListGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	; returns in ax
		call	ObjMessage			; nukes cx, cx, bp
		
		push	ax				; save object type
	;		
	; get preview colors
	;		
		GetResourceHandleNS	OnColorSelector1, bx
		mov	si, offset	OnColorSelector1
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	; returns in ax
		call	ObjMessage
		
		mov	ah, al				; ah = on-color 1
		push	ax				; save on-color 1
		
		GetResourceHandleNS	OnColorSelector2, bx
		mov	si, offset	OnColorSelector2
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
		
		pop	bx
		mov	bl, al				; bx = on-colors
		push	bx
		
		GetResourceHandleNS	OffColorSelector1, bx
		mov	si, offset	OffColorSelector1
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
		
		mov	ah, al				; ah = off-color 1
		push	ax
		
		GetResourceHandleNS	OffColorSelector2, bx
		mov	si, offset	OffColorSelector2
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
		
		pop	dx
		mov	dl, al				; dx = off-colors
		pop	cx				; cx = on-colors
		pop	bx				; bx = object type
		
		.leave
		ret
GetPreviewSettings	endp

DocAddIcon	ends
