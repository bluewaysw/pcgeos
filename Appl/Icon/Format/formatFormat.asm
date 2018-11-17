COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Icon Editor
MODULE:		Format
FILE:		formatFormat.asm

AUTHOR:		Steve Yegge, Aug 31, 1992

ROUTINES:
	Name				Description
	----				-----------
    INT DBViewerAddFormat	Adds a new format to the current icon and
				switches to it.

    INT GetAddFormatParameters	Returns user-specified height, width, color
				scheme and aspect ratio.  And display size.

    INT SetNewFormatParameters	Set up the VisMonikerListEntryType for the
				format.

    INT DBViewerDeleteFormat	Deletes the current format.

    INT DBViewerSwitchFormat	Switches editing to a different (existing)
				format

    INT CheckFormatDirtyAndDealWithIt 
				See if current format is dirty, and prompt
				for save.

    INT CheckFormatTooLargeAndDealWithIt 
				See if the new format would be >64k (or
				just too big)

    INT DBViewerResizeFormat	Resizes the current format.

    INT CheckResizeTooLargeAndDealWithIt 
				See if the user's trying to resize it too
				big.

    INT CreateBitmapForResize	Creates a bitmap ready-made for the new
				(resized) format

    INT ApplyResizeScaleFactor	Scales the gstate (only if the user wants
				to squeeze the bitmap)

METHODS:
	Name
	----
MSG_DB_VIEWER_ADD_FORMAT
MSG_DB_VIEWER_DELETE_FORMAT
MSG_DB_VIEWER_RESIZE_FORMAT
MSG_DB_VIEWER_SWITCH_FORMAT
MSG_DB_VIEWER_DRAW_FORMATS
MSG_DB_VIEWER_GET_SELECTED_FORMATS
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/31/92		Initial revision


DESCRIPTION:

	This file contains routines for supporting multiple-format
	icons (adding, deleting, switching and resizing formats).

	formatUI.asm contains most of the code for *viewing* formats.
	
	$Id: formatFormat.asm,v 1.1 97/04/04 16:06:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerAddFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a new format to the current icon and switches to it.

CALLED BY:	MSG_DB_VIEWER_ADD_FORMAT

PASS:		*ds:si	= DBViewer object
		ds:[di]	= DBViewerInstance

RETURN:		nothing
DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

	-see if the requested size is too large
	-make a new bitmap for the new format (MSG_VIS_BITMAP_CREATE_BITMAP)
	-set up the database entry for this format
	-redraw the format list
	-switch editing to the new format

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerAddFormat	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter
	;
	;  If we're not editing an icon, bail.
	;
		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		LONG	je	quit
	;
	;  Don't let them add another one if there are already
	;  too damned many.
	;
		mov	bp, ds:[di].GDI_fileHandle
		mov	ax, ds:[di].DBVI_currentIcon
		call	IdGetFormatCount
		cmp	bx, MAX_FORMATS
		LONG	je	tooDamnedMany
	;
	;  Discard all the old VM chains.
	;
		call	FreeMemHandles		
	;
	;  Get the user-specified stuff.
	;
		call	GetAddFormatParameters

		call	CheckFormatTooLargeAndDealWithIt
		jc	quit			; too big

		call	CheckFormatDirtyAndDealWithIt
		jc	quit			; user cancelled the add.

		call	IconMarkBusy
	;
	;  Create a new bitmap in the BMO.
	;
		call	CreateBitmapInBMO	; returns ^vcx:dx = bitmap
	;
	;  Update IH_formatCount
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdIncFormatCount
		call	IdGetFormatCount	; bx = count
		dec	bx			; 0-indexed formats
	;
	;  Now ax = icon, bx = new format number, and ^vcx:dx = new format.
	;
		push	cx
		mov	cx, 1			; add 1 format
		call	IdCreateFormats
		pop	cx			; format vm block
		call	IdSetFormat
	;
	;  Set the format parameters for the new format.
	;
		call	SetNewFormatParameters
	;
	;  Now update all the UI.
	;
		push	bx, si			; save format & instance
		mov	si, offset FormatViewer
		mov	ax, MSG_FORMAT_CONTENT_RESCAN_LIST
		call	ObjCallInstanceNoLock

		pop	cx, si
		mov	ax, MSG_DB_VIEWER_SWITCH_FORMAT
		call	ObjCallInstanceNoLock

		call	IconMarkNotBusy
quit:

		.leave
		ret
tooDamnedMany:
	;
	;  Tell them they're bad.
	;
		mov	si, offset TooManyFormatsText
		call	DisplayError
		jmp	quit
DBViewerAddFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAddFormatParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns user-specified height, width, color scheme and
		aspect ratio.  And display size.

CALLED BY:	DBViewerAddFormat

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		cx	= width
		dx	= height
		al	= BMFormat

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/ 8/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAddFormatParameters	proc	near
		class	DBViewerClass
		uses	bx,si,di,bp
		.enter
	;
	;  Get the width.
	;
		mov	bx, ds:[di].GDI_display
		mov	si, offset AddFormatWidth
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; dx <- width
		call	ObjMessage
		push	dx			; save width
	;
	;  Get the height.
	;
		mov	si, offset AddFormatHeight
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; dx <- height
		call	ObjMessage
		push	dx			; save height
	;
	;  Get the color scheme.
	;
		mov	si, offset AddFormatColorScheme
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	
		call	ObjMessage		; al <- color scheme
	;
	;  Put everything in the right registers.
	;
		pop	dx			; dx = height
		pop	cx			; cx = width

		.leave
		ret
GetAddFormatParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNewFormatParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the VisMonikerListEntryType for the format.

CALLED BY:	DBViewerAddFormat

PASS:		ds:di	= DBViewerInstance
		ax	= icon number
		bx	= format number
		bp	= database file handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/21/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNewFormatParameters	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp

		fileHandle	local	word	push	bp
		icon		local	word	push	ax
		format		local	word	push	bx
		displaySize	local	word
		style		local	word
		aspectRatio	local	word
		colorScheme	local	word
		
		.enter
	;
	;  Get the user-specified aspect ratio.
	;
		push	bp				; locals
		mov	bx, ds:[di].GDI_display
		mov	si, offset AddFormatAspectRatio
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage			; ax = ratio
		pop	bp

		mov	aspectRatio, ax
	;
	;  Get the user-specified color scheme.
	;
		push	bp
		mov	si, offset AddFormatColorScheme
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage			; ax = BMFormat
		pop	bp

		mov	colorScheme, ax
	;
	;  Get the user-specified style.
	;
		push	bp
		mov	si, offset AddFormatStyle
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp

		mov	style, ax
	;
	;  Get the user-specified display size.
	;
		push	bp
		mov	si, offset AddFormatDisplaySize
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp
		
		mov	displaySize, ax
	;
	;  Start setting up the record in dx.
	;
		mov	dx, VisMonikerListEntryType <0,0,0,TRUE,0,0>
		mov	cl, offset VMLET_GS_SIZE
		shl	ax, cl
		ornf	dx, ax

		mov	cl, offset VMLET_GS_ASPECT_RATIO
		mov	ax, aspectRatio
		shl	ax, cl
		ornf	dx, ax

		mov	cl, offset VMLET_STYLE
		mov	ax, style
		shl	ax, cl
		ornf	dx, ax
	;
	;  The color scheme has to be converted from a BMFormat
	;  into a DisplayClass.  Sigh.  (Of course that's easier
	;  than going the other way).
	;
		mov	bx, colorScheme
		clr	ah
		mov	al, cs:[classTable][bx]
		jmp	gotDisplayClass

classTable	byte	\
		DC_GRAY_1,			; BMF_MONO = 0
		DC_COLOR_4,			; BMF_4BIT = 1
		DC_COLOR_8,			; BMF_8BIT = 2
		DC_CF_RGB			; BMF_24BIT = 3
		
gotDisplayClass:
		mov	cl, offset VMLET_GS_COLOR
		shl	ax, cl
		ornf	dx, ax
	;
	;  Now we have a valid VisMonikerListEntryType for the
	;  format.  Stick it into the database.
	;
		push	bp
		mov	ax, icon
		mov	bx, format
		mov	bp, fileHandle
		mov	cx, dx			; cx = VisMonikerListEntryType
		mov	dx, 1			; pass custom VMLET in cx
		call	IdSetFormatParameters
		pop	bp

		.leave
		ret
SetNewFormatParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerDeleteFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the current format.

CALLED BY:	MSG_DB_VIEWER_DELETE_FORMAT

PASS:		*ds:si	= DBViewer object
		ds:[di]	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Calls UserStandardDialog to see if they're sure, then
	calls database routine DeleteFormat to do all the work.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerDeleteFormat	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter

		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		LONG	je	done
	;
	;  See if this is the last format left to the icon.
	;
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormatCount	; returns in bl
		cmp	bx, 1			; at least 1 left?
		ja	okToDelete
	;
	;  Put up a dialog asking if they want to delete the icon
	;  (which is what we do if they delete the last format).
	;
		push	si
		mov	si, offset	CantDeleteLastFormatText
		call	DisplayQuestion
		pop	si
		cmp	ax, IC_YES
		LONG	jne	done
	;
	;  They want to delete the icon.
	;
		mov	ax, MSG_DB_VIEWER_DELETE_CURRENT_ICON
		call	ObjCallInstanceNoLock

		jmp	done
okToDelete:
	;
	;  See if confirm-on-delete is set
	;
		push	si			; save DBViewer
		GetResourceHandleNS	OptionsBooleanGroup, bx
		mov	si, offset	OptionsBooleanGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjMessage		; nukes cx, dx, bp
		pop	si			; DBViewer chunk handle

		test	ax, mask IO_CONFIRM_DELETE
		jz	noDialog
	;
	;  Put up the dialog asking if they're sure.
	;
		push	si			; DBViewer
		mov	si, offset	PromptForDeleteFormatText
		call	DisplayQuestion		; returns user response in ax.
		pop	si			; DBViewer
				
		cmp	ax, IC_YES
		jne	done
noDialog:
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset

		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		mov	bp, ds:[di].GDI_fileHandle
		call	IdDeleteFormat		; actually deletes the format
	;
	;  Since the format we just deleted wasn't the last one, we'll
	;  just switch-format to the first in the list. (and clear dx
	;  to tell switch-format that we're coming from DeleteFormat)
	;
		clr	cx			; switch to 1st format
		mov	ax, MSG_DB_VIEWER_SWITCH_FORMAT
		call	ObjCallInstanceNoLock

		mov	si, offset FormatViewer
		mov	ax, MSG_FORMAT_CONTENT_RESCAN_LIST
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
DBViewerDeleteFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerSwitchFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switches editing to a different (existing) format

CALLED BY:	MSG_DB_VIEWER_SWITCH_FORMAT

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewer instance
		cx	= new format number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	-save current format into database (prompt for save?) unless
	 we're coming from just having deleted the current format
	-get format that they want to edit out of the database and
	 place it into the bitmap object. 
	-enable tools for the new color scheme
	-update preview area...place new format in preview objects
	-set currently-edited format in database to this one.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerSwitchFormat	proc	far
		class	DBViewerClass
		uses	ax,cx,dx,bp
		.enter
	;
	;  update instance variables for new & old selected formats.
	;
		mov	ax, ds:[di].DBVI_currentFormat
		mov	ds:[di].DBVI_lastFormat, ax	; current -> old
		mov	ds:[di].DBVI_currentFormat, cx
	;
	;  Get current format and stick into vis-bitmap object.
	;
		mov	ax, ds:[di].DBVI_currentIcon	; ax <- icon number
		mov	bx, cx				; cx <- format number
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormat		; returns ^vcx:dx = format

		call	ReplaceBMOBitmap
	;
	;  Update the preview area (requires ^vcx:dx = bitmap)
	;
		call	SetPreviewMonikers
 	;
	;  Redraw the previously selected format.
	;
		push	si			; save DBViewer
		mov	cx, ds:[di].DBVI_lastFormat
		mov	si, offset FormatViewer
		mov	ax, MSG_FORMAT_CONTENT_REDRAW_FORMAT
		call	ObjCallInstanceNoLock
		pop	si			; restore DBViewer
	;
	;  Redraw the currently selected format.
	;
		push	si
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	cx, ds:[di].DBVI_currentFormat
		mov	si, offset FormatViewer
		mov	ax, MSG_FORMAT_CONTENT_REDRAW_FORMAT
		call	ObjCallInstanceNoLock
		pop	si			; *ds:si = DBViewer object
	;
	;  Get all the stuff for ResizeBMOAndFatbits, and do it.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormatDimensions	; cx <- width, dx <- height
		call	IconAppGetImageBitSize	; returns in ax	

		call	ResizeBMOAndFatbits

		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		clr	ds:[di].DBVI_iconDirty
	;
	;  Redraw the whole display...
	;
		mov	bx, ds:[di].GDI_display
		mov	si, offset IconDBDisplay
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjMessage

		.leave
		ret
DBViewerSwitchFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFormatDirtyAndDealWithIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if current format is dirty, and prompt for save.

CALLED BY:	INTERNAL

PASS:		*ds:si	= DBViewer object

RETURN:		carry set if user cancelled the change.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	If the current format has changed, ask the user if they'd
	like to save it before continuing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFormatDirtyAndDealWithIt	proc	near
		class	DBViewerClass
		uses	ax, si, di, bx
		.enter

		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		tst	ds:[di].DBVI_iconDirty	; is the icon dirty?
		jz	done			; nope, we're done
	;	
	;  Prompt the user for saving the icon.  First set up
	;  the StandardDialogResponseTriggerTable.
	;
		push	ds:[LMBH_handle], si	; DBViewer object

		mov	si, offset PromptForSaveFormatText
		call	DisplaySaveChangesYesNo	; ax = InteractionCommand

		pop	bx, si			; DBViewer object
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
CheckFormatDirtyAndDealWithIt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFormatTooLargeAndDealWithIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the new format would be >64k (or just too big)

CALLED BY:	INTERNAL

PASS:		cx = width
		dx = height
		al = BMFormat

RETURN:		carry set if too large
DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

PSEUDO CODE/STRATEGY:

	Figure out the total space that will be required by the
	bitmap (including the mask), and disallow the bitmap's
	creation (by setting the carry on exit) if it's >64k.

	Put up an error dialog if the format's too big.

	Also, return carry set if either dimension is larger than
	the max allowable size.  (We have this check for when we
	are importing graphics).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFormatTooLargeAndDealWithIt	proc	far
		uses	ax,bx,cx,dx,si,di
		.enter
	;
	;  Quick check to see if either dimension is too large.
	;
		cmp	cx, MAX_FORMAT_WIDTH
		ja	tooWideOrTall

		cmp	dx, MAX_FORMAT_HEIGHT
		ja	tooWideOrTall
	
		jmp	short	notTooWideOrTall
tooWideOrTall:
	;
	;  The format is either too wide or too tall...display error.
	;
		mov	si, offset FormatTooWideOrTallText
		call	DisplayError

		stc
		jmp	short	done
notTooWideOrTall:
		cmp	al, BMF_MONO			; test the format type
		je	mono

		cmp	al, BMF_8BIT			; 256-color bitmap?
		je	color256
	;
	;  For a color bitmap (4 bits per pixel), the total space
	;  required is width*height/2 + (width*height)/8
	;  (i.e. bitmap data + mask data)
	;
		movdw	sidi, cxdx		; si <- width, di <- height
	;
	; calculate the data size
	;
		mov_tr	ax, dx			; ax <- height
		mul	cx			; dx.ax = size in pixels
		shrdw	dxax			; divide by 2
		pushdw	dxax			; save data size
	;
	; calculate the mask size
	;
		movdw	axcx, sidi		; ax <- width, cx <- height
		mul	cx
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax			; divide by 8
	;
	; add data size and mask size
	;
		popdw	bxcx			; bx.cx = data size
		adddw	dxax, bxcx
		jc	tooBig			; overflow
	;
	; if dx is nonzero, we spilled over 64k.
	;
		tst	dx			; quotient over 64k?
		jnz	tooBig
	;
	;  Now see if we're still below the limit.
	;
		cmp	ax, MAX_SAFE_MONIKER_SIZE
		ja	tooBig
		jmp	short	ok
mono:
	;
	;  For a monochrome bitmap, the total space required is
	;  (width*height/8)*2  (since the mask and data are the
	;  same size).
	;
		mov_tr	ax, dx
		mul	cx			; dx.ax = size in pixels
		shrdw	dxax
		shrdw	dxax			; divide by 4
		tst	dx			; quotient over 64k?
		jnz	tooBig
		jmp	short	ok
tooBig:
	;
	;  Display an error message
	;
		mov	si, offset FormatTooLargeText
		call	DisplayError

		stc
		jmp	short	done
color256:
	;
	;  for an 8-bit-per-pixel bitmap, space = width*height + mask
	;
		mov_tr	ax, dx			; ax = height
		mul	cx			; dx.ax = data size
		movdw	bxcx, dxax		; save data size
		shrdw	dxax
		shrdw	dxax
		shrdw	dxax			; divide by 8
		adddw	dxax, bxcx		; dx.ax = total size
	;
	;  If dx is nonzero, we're over 64k.
	;
		tst	dx
		jnz	tooBig
ok:	
		clc
done:
	;
	;  Well, well, well.  I have had nothing but trouble
	;  from this stupid routine, which doesn't let me make
	;  big icons when I really need to do so (for example,
	;  I import a color one that I'm going to change to
	;  black & white later).  I'm adding the "clc" here so
	;  that it prints out the error message, but allows you
	;  to create the icon anyway.  -stevey 12/23/94
	;
		clc				; let them do what they want

		.leave
		ret
CheckFormatTooLargeAndDealWithIt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerResizeFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resizes the current format.

CALLED BY:	MSG_DB_VIEWER_RESIZE_FORMAT

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- create a scratch bitmap.

	- figure out whether they want to scale the bitmap,
	  and if they do, calculate the scale factor and apply
	  it to the gstate returned from creating the scratch
	  bitmap.

	- draw the current format's bitmap into the scratch bitmap
	- delete the current format from the database
	- create a new format using the scratch bitmap.
	- resize everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerResizeFormat	proc	far
		class	DBViewerClass
		uses	ax,cx,dx,bp
		.enter
	
		call	CheckFormatDirtyAndDealWithIt
		LONG	jc	done		; user cancelled
	
		call	CheckResizeTooLargeAndDealWithIt
		LONG	jc	done
		
		call	CreateBitmapForResize	; ^vbx:ax, di = gstate,
						; cx = width, dx = height
		pushdw	bxax			; save new bitmap
	
		call	ApplyResizeScaleFactor	; applies it to gstate in di
	;
	;  Draw the current format into the scratch bitmap
	;
 		mov	bx, ds:[si]
		add	bx, ds:[bx].DBViewer_offset	; ds:bx = instance
		mov	ax, ds:[bx].DBVI_currentIcon
		mov	bp, ds:[bx].GDI_fileHandle
		mov	bx, ds:[bx].DBVI_currentFormat
		call	IdGetFormat		; returns ^vcx:dx
		
		clrdw	bxax			; coordinates to draw at
		xchg	cx, dx
		call	GrDrawHugeBitmap
		push	cx, dx			; save bitmap
	
		clr	dx			; no color transfer info
		mov	ax, mask BM_EDIT_MASK
		call	GrSetBitmapMode

		pop	cx, dx			; restore bitmap
		clrdw	bxax
		call	GrFillHugeBitmap
	;
	;  Nuke the scratch bitmap's window & gstate now that they're
	;  no longer needed.
	;
		mov	al, BMD_LEAVE_DATA
		call	GrDestroyBitmap
	;
	;  Set the currently edited format from the scratch bitmap,
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
	
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		mov	bp, ds:[di].GDI_fileHandle

		popdw	cxdx			; ^vcx:dx = new bitmap
		call	IdClearAndSetFormat
	;
	;  Rescan the database.
	;
		mov	ax, MSG_DB_VIEWER_RESCAN_DATABASE
		call	ObjCallInstanceNoLock
	;
	;  Switch editing to the new format (this causes all the
	;  contents to be resized, and UI updated).
	;
		mov	cx, bx			; cx = new format
		mov	ax, MSG_DB_VIEWER_SWITCH_FORMAT
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
DBViewerResizeFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckResizeTooLargeAndDealWithIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the user's trying to resize it too big.

CALLED BY:	DBViewerResizeFormat

PASS:		*ds:si	= DBViewer object
		ds:si	= DBViewerInstance

RETURN:		carry clear if it's OK to resize the format
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get the desired height & width, and current color scheme,
	  and call CheckFormatDirtyAndDealWithIt to do the work.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckResizeTooLargeAndDealWithIt	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Get new width.
	;
		push	si				; save DBViewer
		mov	bx, ds:[di].GDI_display
		mov	si, offset ResizeWidthValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; returns in dx
		call	ObjMessage
		pop	si
		push	dx				; save width
	;
	;  Get new height.
	;
		push	si
		mov	si, offset	ResizeHeightValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjMessage
		pop	si				; *ds:si = DBViewer
	;
	;  Get the format's color scheme.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset

		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormatColorScheme		; returns in al
	;
	;  Pass values to CheckFormatTooLargeAndDealWithIt.
	;
		pop	cx				; restore width
		call	CheckFormatTooLargeAndDealWithIt

		.leave
		ret
CheckResizeTooLargeAndDealWithIt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateBitmapForResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a bitmap ready-made for the new (resized) format

CALLED BY:	DBViewerResizeFormat

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewer instance

RETURN:		ax	= vm block
		bx	= vm file handle
		di	= gstate handle
		cx	= width of new bitmap
		dx	= height of new bitmap

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateBitmapForResize	proc	near
		class	DBViewerClass
		uses	si,bp
		.enter
	;
	;  Get the color scheme (use the current format's color scheme)
	;
		push	si				; DBViewer
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormatColorScheme
		push	ax				; save color scheme
	;
	;  Get new width.
	;
		mov	bx, ds:[di].GDI_display
		mov	si, offset ResizeWidthValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; returns in dx
		call	ObjMessage
		push	dx
	;
	;  Get new height.
	;
		mov	si, offset ResizeHeightValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; dx <- height
		call	ObjMessage

		pop	cx				; restore width
		pop	ax				; restore color
		or	al, mask BMT_MASK
	;
	;  Create the bitmap.  Don't nuke window & gstate until later.
	;
		pop	si
		mov	di, ds:[si]			; *ds:si = DBViewer
		add	di, ds:[di].DBViewer_offset
		mov	bx, ds:[di].DBVI_bitmapVMFileHandle	; convenient.
		clrdw	sidi			; OD for exposure event
		call	GrCreateBitmap		; returns ax = vm block,

		.leave
		ret
CreateBitmapForResize	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ApplyResizeScaleFactor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scales the gstate (only if the user wants to squeeze the
		bitmap)

CALLED BY:	DBViewerResizeFormat

PASS:		*ds:si	= DBViewer object
		di = gstate
		cx = target width (what the user's resizing to)
		dx = target height

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ApplyResizeScaleFactor	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		push	si, di, dx, cx		; save input parameters
	;
	;  Find out whether to scale the bitmap or not.
	;
		mov	bx, ds:[si]
		add	bx, ds:[bx].DBViewer_offset
		mov	bx, ds:[bx].GDI_display
		mov	si, offset ResizeFormatOptionsGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	; returns in ax
		call	ObjMessage

		pop	si, di, dx, cx
	;
	;  If we're not going to be scaling the bitmap, quit.
	;
		cmp	al, RFOT_SCALE_BITMAP
		jne	done			; don't bother if not scaling

		push	di			; save GState
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
	;
	;  OK, we're scaling the bitmap.  Figure out the scale factor.
	;
		mov	si, cx			; si = target width
		mov	bp, dx			; bp = target height

		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		push	bp			; save target width
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormatDimensions	; cx = width, dx = height
		pop	bp			; restore target width
		push	dx			; save current height

		mov	bx, cx			; bx <- current width
		mov	dx, si			; dx <- target width
		clrdw	cxax			; divide dest. by source
		call	GrUDivWWFixed		; returns dx.cx = scale

		pop	bx			; restore current height
		pushdw	dxcx			; save x-scale factor
	;
	;  Do the height.
	;
		mov	dx, bp			; dx <- target height
		clrdw	cxax
		call	GrUDivWWFixed		; returns dx.cx = y scale
		movdw	bxax, dxcx		; bx.ax = y scale

		popdw	dxcx			; dx.cx = x scale
		pop	di
		call	GrApplyScale
done:
		.leave
		ret
ApplyResizeScaleFactor	endp

FormatCode	ends

