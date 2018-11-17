COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	icon editor
MODULE:		format
FILE:		formatTransform.asm

AUTHOR:		Steve Yegge, Sep 17, 1992

ROUTINES:

	Name			Description
	----			-----------
DBViewerInitTFDialog		- sets monikers in the transform-format dialog
TransformDisplayDraw		- draws the format in the transform dialog
TransformDisplayRecalcSize	- recalc-size handler for transform vis-objects
SetDestinationValues		- sets destination width, height, and options
DBViewerTransformFormat		- Sets up a transform
TransformFormat			- actually does the transform
CreateScratchBitmap		- makes a temporary bitmap for the transform
DBViewerTestTransform		- lets the user see what the transform would do
ReadyContentForTest		- sets dest transform vis-object not-drawable
RestoreContentAfterTest		- sets dest transform vis-object drawable
DBViewerCancelTransform		- reinitializes TFDialog after user cancels
ApplyScaleToGState		- determines proper scaling and sets it.
GetSourceBitmap			- returns the bitmap user wants for 'source'
TFSetSourceFormat		- updates source transform vis-object
TFSetDestFormat			- updates dest transform vis-object

MESSAGE HANDLERS:

Name					Description
----					-----------
MSG_VIS_RECALC_SIZE 	for the TransformDisplayClass
MSG_VIS_DRAW 		for the TransformDisplayClass
MSG_GEN_INTERACTION_INITIATE	for the TransformFormatDialogClass


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/17/92		Initial revision
	lester	1/12/94		changed the TFDialog to be of the class
				TransformFormatDialog and added a handler
				for the message MSG_GEN_INTERACTION_INITIATE
				for the TransformFormatDialogClass. Now we
				update the TFDialog when it comes on screen 
				not whenever the current icon changes
DESCRIPTION:
	
	This file contains routines for transforming formats.

	$Id: formatTransform.asm,v 1.1 97/04/04 16:06:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerInitTFDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the source & dest monikers in the TF dialog

CALLED BY:	DBViewerTransformFormat, TransformFormatDialogInitiate

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

	This routine must be called with the current icon unlocked.

PSEUDO CODE/STRATEGY:

	- lock the current icon
	- get the first format
	- make a moniker out of it
	- replace the moniker in the source-glyph-thingy
	- get the second format, if any
	- set the dest-moniker-glyph-thingy
	- set the destination-size genValues to same as source format...
	- unlock the current icon
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerInitTFDialog	proc	far
		class	DBViewerClass
		uses	ax,cx,dx,bp
		.enter
	;
	;  If no current icon, bail
	;
		mov	ax, ds:[di].DBVI_currentIcon
		cmp	ax, NO_CURRENT_ICON
		je	done
		
		mov	bx, ds:[LMBH_handle]
		push	bx, si
	;
	;  Tell the source-display view to redraw.
	;
		mov	si, offset TFSourceDisplayObject
		mov	di, mask MF_CALL
		mov	cl, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_MARK_INVALID
		call	ObjMessage
	;
	;  Tell the destination format to redraw.
	;		
		mov	si, offset TFDestDisplayObject
		mov	di, mask MF_CALL
		mov	cl, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_MARK_INVALID
		call	ObjMessage
		
		pop	bx, si
		call	MemDerefDS			; *ds:si = DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		call	SetDestinationValues
	;
	;  Set the current maximum values for source & dest format.
	;
		call	SetSourceAndDestGenValues
done:
		.leave
		ret
DBViewerInitTFDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransformDisplayDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws whatever format into the content.

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= TransformDisplayClass object
		ds:di	= TransformDisplayClass instance data
		bp 	= gstate to draw through

RETURN:		nothing
DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransformDisplayDraw	method dynamic TransformDisplayClass, 
		MSG_VIS_DRAW
		uses	cx, dx
		.enter
	;
	;  Get the current icon and vm file handle from the document.
	;
		mov	di, bp				; di = gstate
		call	GetFileHandleDisplayHandleAndIcon
		
		cmp	dx, NO_CURRENT_ICON
		je	done
		
		mov	bx, ds:[si]
		add	bx, ds:[bx].Vis_offset		; ds:bx = instance
	;
	;  See if we're displaying the source or the destination format,
	;  and grab the appropriate bitmap from the database.
	;
		push	bp, si, dx, di
		
		cmp	ds:[bx].TDI_secretIdentity, TDT_SOURCE_FORMAT
		je	sourceFormat
		
		mov	si, offset TFDestGenValue
		jmp	short	getBitmap
sourceFormat:
		mov	si, offset TFSourceGenValue
getBitmap:
	;
	;  Here's the part where we actually get the format's bitmap.
	;
		mov	bx, cx				; display block handle
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; returns in dx
		call	ObjMessage
		dec	dx				; 0-indexed formats
		pop	bp, si, ax, di
		
		mov	bx, dx				; bx <- format number
		call	IdGetFormat			; returns ^vcx:dx
		tst	dx				; valid format?
		jz	done
		
		xchg	dx, cx				; ^vcx:dx = bitmap
		clrdw	axbx				; draw position
		call	GrDrawHugeBitmap
done:
		.leave
		ret
TransformDisplayDraw	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileHandleDisplayHandleAndIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current icon, the database handle and the display block.

CALLED BY:	TransformDisplayDraw, TransformDisplayRecalcSize

PASS:		ds = segment address of the active document

RETURN:		dx = current icon
		cx = display block handle
		bp = database file handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/25/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFileHandleDisplayHandleAndIcon	proc	near
		uses	si
		.enter
		
		mov	si, offset IconDBViewerTemplate
		mov	ax, MSG_DB_VIEWER_GET_CURRENT_ICON
		call	ObjCallInstanceNoLock		; ax = current icon
		mov_tr	dx, ax				; dx = current icon
		
		mov	ax, MSG_DB_VIEWER_GET_DISPLAY
		call	ObjCallInstanceNoLock		; bp = display
		mov	cx, bp				; cx = display
		
		mov	ax, MSG_DB_VIEWER_GET_DATABASE
		call	ObjCallInstanceNoLock		; bp = file handle
		
		.leave
		ret
GetFileHandleDisplayHandleAndIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransformDisplayRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the dimensions of the selected bitmap.

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		*ds:si	= TransformDisplay object
		ds:di	= TransformDisplayClass instance data
		cx	= suggested width
		dx	= suggested height

RETURN:		cx 	= width to use
		dx	= height to use

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransformDisplayRecalcSize	method dynamic TransformDisplayClass, 
		MSG_VIS_RECALC_SIZE
	;
	;  Get current icon, database file handle and display block handle.
	;
		call	GetFileHandleDisplayHandleAndIcon
		
		cmp	dx, NO_CURRENT_ICON
		je	noBitmap
	;
	;  See if we're displaying the source or the dest format, and
	;  grab the appropriate bitmap.
	;
		mov	bx, ds:[si]
		add	bx, ds:[bx].Vis_offset	; ds:bx = instance
		
		push	bp, si, dx		; database, chunk, currentIcon
		
		cmp	ds:[bx].TDI_secretIdentity, TDT_SOURCE_FORMAT
		je	sourceFormat
		
		mov	si, offset TFDestGenValue
		jmp	short	getBitmap
sourceFormat:
		mov	si, offset TFSourceGenValue
getBitmap:
		mov	bx, cx				; display block handle
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; returns in dx
		call	ObjMessage
		dec	dx				; 0-indexed formats
		pop	bp, si, ax			; ax = current icon
		
		mov	bx, dx
		call	IdGetFormat			; returns ^vcx:dx
		tst	dx				; valid bitmap?
		jz	noBitmap
		
		call	HugeBitmapGetFormatAndDimensions
		jmp	short	done
noBitmap:
		clrdw	cxdx
done:
		ret
TransformDisplayRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDestinationValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets TFWidthValue, TFHeightValue, and fomat options selectors
		from the desination format values

CALLED BY:	InitializeTFDialog
		TFSetDestFormat	

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- user selects a destination format (n)
	- if (n > # existing formats) n = n-1
	- we get the info on format n and use it to set:

		- height & width
		- color scheme
		- aspect ratio
		- display size
		- format style

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/14/92	Initial version
	lester	 1/ 5/94	added code to set display size, format style
				changed name from SetHeightAndWidthGenValues
				to SetDestinationValues

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDestinationValues	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Figure out what the new destination format is.
	;
		push	si
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFDestGenValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjMessage			; dx = value
		dec	dx				; zero-indexed formats
		pop	si
	;
	;  See if it's higher than the current number of
	;  formats, and decrement it if so.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormatCount		; bx = format count
		tst	bx
		LONG	jz	done			; we outta here

		dec	bx				; zero-indexed formats
		cmp	dx, bx
		jle	numberOK
		dec	dx
numberOK:
	;
	;  Get the height & width from this bitmap and set
	;  the GenValues accordingly.
	;
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		mov	bx, dx				; bx = format
		call	IdGetFormatDimensions		; cx=width, dx=height
		push	ax, bx, bp			; save format stuff
	;
	;  cx has width; dx has height.  Set the values of the GenValues.
	;
		push	dx				; save height
		mov	bx, ds:[di].GDI_display
		mov	si, offset	TFWidthValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		clr	bp				; not indeterminate
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		call	ObjMessage
		
		pop	cx				; cx <- height
		mov	si, offset TFHeightValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		clr	bp				; not indeterminate
		call	ObjMessage
		mov	di, bx				; GDI_display
	;
	;  Get the VisMonikerListEntryType for the format, so
	;  we can set the aspect ratio and color scheme.
	;
		pop	ax, bx, bp			; format stuff
		call	IdGetFormatParameters		; cx = VMLET
		push	cx				; save for later

		andnf	cx, mask VMLET_GS_ASPECT_RATIO	; isolate aspect ratio
		
CheckHack < offset VMLET_GS_ASPECT_RATIO eq 4 >
	
		shr	cx
		shr	cx
		shr	cx
		shr	cx				; cx = aspect ratio

		mov	bx, di				; bx = GDI_display
		mov	si, offset TFAspectRatioSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		call	ObjMessage
	;
	;  Set the color scheme selector.
	;
		pop	cx				; cx = VMLEType
		push	cx				; save for later
		andnf	cx, mask VMLET_GS_COLOR		; cx = DisplayClass
		cmp	cx, DC_GRAY_1
		jne	notMono
mono::
		mov	cx, BMF_MONO
		jmp	gotColor
notMono:
		cmp	cx, DC_COLOR_4
		jne	not4Color

		mov	cx, BMF_4BIT
		jmp	gotColor
not4Color:
		mov	cx, BMF_8BIT
gotColor:
		mov	si, offset TFColorSchemeSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		call	ObjMessage
	;
	;  Set the display size selector.
	;
		pop	dx				; dx = VMLEType
		push	dx				; save for later
		andnf	dx, mask VMLET_GS_SIZE		; isolate DisplaySize
		mov	cl, offset VMLET_GS_SIZE
		shr	dx, cl
		mov	cx, dx				; cx = display size

		mov	si, offset TFDisplaySizeSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		call	ObjMessage
	;
	;  Set the format style selector.
	;
		pop	dx				; dx = VMLEType
		andnf	dx, mask VMLET_STYLE		; isolate Style
		mov	cl, offset VMLET_STYLE
		shr	dx, cl
		mov	cx, dx				; cx = style

		mov	si, offset TFStyleSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx
		call	ObjMessage
done:		
		.leave
		ret
SetDestinationValues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerTransformFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs a transformation on a format, to another format.

CALLED BY:	MSG_DB_VIEWER_TRANSFORM_FORMAT

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewer instance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- if there's no current icon, quit
	- test to see if we're transforming into a color bitmap,
	  and call the appropriate routine to do the transform

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerTransformFormat		proc	far
		class	DBViewerClass
		.enter
	;
	;  If there's no current icon, bail
	;
		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		je	done
		
		call	CheckFormatDirtyAndDealWithIt
		jc	done			; user cancelled
		
		call	CheckDestinationTooLargeAndDealWithIt
		jc	done			; not doable
		
		call	TransformFormat		; returns new number in cx
		call	RestoreContentAfterTest

		mov	ax, MSG_DB_VIEWER_INIT_TF_DIALOG
		call	ObjCallInstanceNoLock	; force the UI to update
	;
	;  switch editing to the new format (policy decision)
	;
		mov	ax, MSG_DB_VIEWER_SWITCH_FORMAT
		call	ObjCallInstanceNoLock
	;
	;  Send a message to the format list to rescan.
	;
		mov	ax, MSG_FORMAT_CONTENT_RESCAN_LIST
		mov	si, offset FormatViewer
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
DBViewerTransformFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDestinationTooLargeAndDealWithIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the proposed destination format would be < 64k.

CALLED BY:	DBViewerTransformFormat, DBViewerTestTransform

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		carry set if the format is too large, or if
		the user cancelled.

		carry clear if the format is OK.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDestinationTooLargeAndDealWithIt	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFWidthValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjMessage
		push	dx				; save width
		
		mov	si, offset TFHeightValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjMessage
		push	dx				; save height
		
		mov	si, offset TFColorSchemeSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage			; returns in ax
		
		pop	dx, cx				; restore height, width
		
		call	CheckFormatTooLargeAndDealWithIt
		
		.leave
		ret
CheckDestinationTooLargeAndDealWithIt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransformFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transforms the source format into a monochrome destination.

CALLED BY:	DBViewerTransformFormat

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		cx	= new format number
		ds	- updated to point to DBViewer block if necessary

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- create a new bitmap in the destination format slot.  we'll get a
	  gstate from GrCreateBitmap, and use it for the transform.

	- calculate the scale factor to apply to the GState.  We just
	  divide the destination height by the source height, and the
	  destination width by the source width.

	- draw the source bitmap to the destination GState.  This 
	  doesn't set the mask bits in the destination, though, so
	  we do it twice.  The second time we use BM_EDIT_MASK.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransformFormat	proc	near
		class	DBViewerClass
		uses	ax,bx,dx,si,di,bp
		
		sourceBitmap	local	dword
		scratchBitmap	local	dword
		
		.enter
	;
	;  Create a bitmap from the user's input parameters.
	;
		call	CreateScratchBitmap	; returns ^vbx:ax = bitmap
						;	di = gstate,
						;	cx = width,
						;	dx = height
		movdw	scratchBitmap, bxax	; save destination bitmap
	;	
	;  Set up the GState appropriately and draw the source to the dest.
	;  The called routines check the transform-format dialog to find
	;  the appropriate scale factor & color scheme.
	;
		call	ApplyScaleToGState

		call	GetSourceBitmap		; returns in cx & dx
		movdw	sourceBitmap, cxdx	; save source bitmap
		xchg	cx, dx			; GrDrawHugeBitmap needs this
		clrdw	axbx			; coordinates to draw at
		call	GrDrawHugeBitmap
		
		push	dx			; save bitmap
		clr	dx			; no color transfer info
		mov	ax, mask BM_EDIT_MASK
		call	GrSetBitmapMode
		pop	dx			; restore bitmap

		clrdw	bxax			; position to draw at
		call	GrFillHugeBitmap

		clr	dx			; no color transfer info
		call	GrSetBitmapMode		; ax is still zero.

		mov	al, BMD_LEAVE_DATA
		call	GrDestroyBitmap		; scratch gstate & window
	;
	;  Stick the format into the database and get a base
	;  VisMonikerListEntryType for the format.
	;
		call	SetFormatInDatabase	; cx = format number
		call	GetDestinationFormatParameters	; dx = VisMonikerListEntryType
	;
	;  Set the format parameters.
	;
		push	bp			; locals
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bp, ds:[di].GDI_fileHandle
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, cx			; format number
		mov	cx, dx			; FormatParameters
		mov	dx, 1			; passing VisMonikerListEntryType
		call	IdSetFormatParameters
		pop	bp			; locals

		mov	cx, bx		; return the format number

		.leave
		ret
TransformFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFormatInDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes the newly-created format and sticks in in the database.

CALLED BY:	TransformFormat

PASS:		*ds:si	= DBViewer object
		ss:bp	= stack frame from TransformFormat

RETURN:		cx	= destination format number

DESTROYED:	nothing (ds updated to point to new block, if necessary)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/ 8/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFormatInDatabase	proc	near
		class	DBViewerClass
		uses	ax,bx,dx,si,di,bp
		.enter inherit TransformFormat
	;
	;  Save the newly-transformed format into the database, and 
	;  update the format list.  We'll just get the value from 
	;  TFDestGenValue first, since we use this number both for
	;  saving the format and for drawing it.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset

		push	bp, si			; save locals & DBViewer
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFDestGenValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjMessage		; nukes ax, cx, bp
		pop	bp, si			; restore locals & instance

		dec	dx			; 0-indexed format list
		push	dx			; save dest format number
	;
	;  To save the new bitmap, we first check if one exists.
	;  If it does, we call IdClearAndSetFormat so that the
	;  old one will be deleted with no race condition.  If
	;  no prior bitmap existed, we merely call IdSetFormat.
	;  Also, if no bitmap existed previously we have to create
	;  the slot for it.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, dx			; destination format

		push	bp			; save locals
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormat		; ^vcx:dx = format
		pop	bp			; restore locals

		tst	dx			; check the block handle
		jnz	priorBitmap
noBitmap::
	;
	;  Create the slot & increment the format count.
	;
		push	bp			; save locals
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdIncFormatCount
		mov	cx, 1			; create 1 format
		call	IdCreateFormats
		pop	bp			; restore locals
	;
	;  Save the destination bitmap into the database. 
	;  NOTICE:  we are popping here!
	;
		mov	ax, ds:[di].DBVI_currentIcon
		pop	bx			; dest. format number
		movdw	cxdx, scratchBitmap
		
		push	bp			; save locals
		mov	bp, ds:[di].GDI_fileHandle
		call	IdSetFormat		; copies the passed chain
		pop	bp			; restore locals

		jmp	doneSetting
priorBitmap:
	;
	;  Save the destination bitmap into the database while
	;  (atomically, more or less) deleting the old bitmap.
	;  NOTICE:  we are popping here!
	;
		mov	ax, ds:[di].DBVI_currentIcon
		pop	bx			; format number
		movdw	cxdx, scratchBitmap
		
		push	bp			; save locals
		mov	bp, ds:[di].GDI_fileHandle
		call	IdClearAndSetFormat	; copies the passed chain
		pop	bp			; restore locals
doneSetting:
		push	bx			; save format number
		
		push	bp			; save locals
		mov	bx, cx			; scratch vm file handle
		mov	ax, dx			; scratch vm block handle
		clr	bp			; ax.bp = vm chain to free
		call	VMFreeVMChain		; nuke scratch bitmap
		pop	bp			; restore locals
		
		pop	cx			; cx <- dest. format number

		.leave
		ret
SetFormatInDatabase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDestinationFormatParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a VisMonikerListEntryType for the new format.

CALLED BY:	TransformFormat

PASS:		*ds:si	= DBViewer object

RETURN:		dx	= VisMonikerListEntryType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/ 8/93		Initial version
	lester	1/ 5/94		completely re-wrote and added size & style

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDestinationFormatParameters	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,si,di,bp
		.enter
	;
	;  dx = generic VisMonikerListEntryType
	; 
		mov	dx, cs:[genericEntryType]
		push	dx		; save the VisMonikerListEntryType
	;
	;  Get the display size.
	;		
		push	si				; save DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFDisplaySizeSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage		; al = DisplaySize
		pop	si				; restore DBViewer
		
		mov	cl, offset VMLET_GS_SIZE
		shl	ax, cl
		
		pop	dx		; restore the VisMonikerListEntryType
		andnf	dx, not mask VMLET_GS_SIZE
		ornf	dx, ax			; set display size
		push	dx		; save the VisMonikerListEntryType
	;
	;  Get the format style.
	;			
		push	si				; save DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFStyleSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage		; al = format style
		pop	si				; restore DBViewer
		
		mov	cl, offset VMLET_STYLE
		shl	ax, cl
		
		pop	dx		; restore the VisMonikerListEntryType
		andnf	dx, not mask VMLET_STYLE
		ornf	dx, ax			; set the format style
		push	dx		; save the VisMonikerListEntryType
	;
	;  Get the aspect ratio.
	;			
		push	si				; save DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFAspectRatioSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage		; al = aspect ratio
		pop	si				; restore DBViewer
		
		mov	cl, offset VMLET_GS_ASPECT_RATIO
		shl	ax, cl
		
		pop	dx		; restore the VisMonikerListEntryType
		andnf	dx, not mask VMLET_GS_ASPECT_RATIO
		ornf	dx, ax			; set aspect ratio
		push	dx		; save the VisMonikerListEntryType
	;
	;  Get the color scheme.
	;			
		push	si				; save DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFColorSchemeSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage		; al = color scheme
		pop	si				; restore DBViewer

		mov_tr	bx, ax
		shl	bx
		mov	bx, cs:[DisplayClassTable][bx]
		jmp	bx
		
DisplayClassTable	nptr	DCGray1,
				DCColor4,
				DCColor8,
				DCCFRGB
DCGray1:
		mov	ax, DC_GRAY_1 shl offset VMLET_GS_COLOR
		jmp	short	gotColor
DCColor4:
		mov	ax, DC_COLOR_4 shl offset VMLET_GS_COLOR
		jmp	short	gotColor
DCColor8:
		mov	ax, DC_COLOR_8 shl offset VMLET_GS_COLOR
		jmp	short	gotColor
DCCFRGB:
		mov	ax, DC_CF_RGB shl offset VMLET_GS_COLOR
gotColor:
	;
	;  Clear the current color from dx's VisMonikerListEntryType;
	;  set the new one.
	;
		pop	dx		; restore the VisMonikerListEntryType
		andnf	dx, not mask VMLET_GS_COLOR
		ornf	dx, ax
	;
	;  return the VisMonikerListEntryType in dx
	;
		.leave
		ret
GetDestinationFormatParameters	endp

genericEntryType VisMonikerListEntryType	\
	<DS_STANDARD,VMS_ICON,,TRUE,DAR_NORMAL,DC_COLOR_4>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateScratchBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the bitmap to be used as the destination format.

CALLED BY:	DBViewerTransformFormat, DBViewerTestTransform

PASS:		*ds:si	= DBViewer object

RETURN:		ax = vm block 
		bx = vm file handle
		di = gstate handle
		cx = width
		dx = height

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get user-defined color scheme
	- get user-defined height and width
	- create a bitmap using these parameters

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateScratchBitmap	proc	near
		class	DBViewerClass
		uses	si,bp
		.enter
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	;  get user-defined color scheme & size
	;
		push	si
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFColorSchemeSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage			; nukes cx, dx, bp
		push	ax				; save BMFormat
		
		mov	si, offset	TFWidthValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; returns in dx
		call	ObjMessage
		push	dx
		
		mov	si, offset	TFHeightValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; dx <- height
		call	ObjMessage
		
		pop	cx				; restore width
		pop	ax				; restore BMFormat
	;
	;  Initialize al with proper BMType (it's already got the BMFormat).
	;
		ornf	al, mask BMT_MASK
		pop	si				; instance data
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].DBVI_bitmapVMFileHandle	; convenient.
		clrdw	disi				; OD for exposure event
		call	GrCreateBitmap			; returns ax = vm block,
							; 	  di = gstate
		.leave
		ret
CreateScratchBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerTestTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Demonstrate transform without saving it to database.

CALLED BY:	MSG_DB_VIEWER_TEST_TRANSFORM

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp	

PSEUDO CODE/STRATEGY:

	We do essentially the same thing as in DBViewerTransformFormat,
	except that we need a scratch bitmap for the destination,
	because the user may not want to save the transform.

	We use the database file for the scratch format, except
	that we never actually save the handle into the database,
	and at the end of the routine we nuke the scratch format.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerTestTransform	proc	far
		class	DBViewerClass
		uses	bp
		
		sourceBitmap	local	dword
		scratchBitmap	local	dword
		
		.enter
	;
	;  If there's no current icon, bail
	;
		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		LONG	je	done
		
		call	CheckDestinationTooLargeAndDealWithIt
		LONG	jc	done
		
		call	ReadyContentForTest	; ready the content for test
	;
	;  Create a bitmap from the user's input parameters
	;
		call	CreateScratchBitmap	; returns ^vbx:ax = bitmap,
						;	  di = gstate,
						;	  cx = width,
						;	  dx = height
		movdw	scratchBitmap, bxax
	;	
	;  Set up the GState appropriately and draw the source to the
	;  scratch bitmap.   The called routines check the TFDialog to 
	;  find the appropriate scale factor & color scheme.
	;
		call	ApplyScaleToGState
		call	GetSourceBitmap		; returns in cx & dx
		movdw	sourceBitmap, cxdx
		xchg	cx, dx			; GrDrawHugeBitmap needs this.
		clrdw	axbx			; coordinates to draw at
		call	GrDrawHugeBitmap	; draw to gstate in di
		
		push	cx, dx			; save bitmap
		
		clr	dx			; no color transfer info
		mov	ax, mask BM_EDIT_MASK
		call	GrSetBitmapMode
		
		pop	cx, dx			; restore bitmap
		clrdw	bxax			; position to draw at
		call	GrFillHugeBitmap
		
		clr	ax, dx
		call	GrSetBitmapMode
		
		call	GrDestroyState
	;
	;  Draw the scratch bitmap to the view's window.
	;
		push	bp			; locals
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFDestDisplayView
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VIEW_GET_WINDOW	; cx = window
		call	ObjMessage
		pop	bp			; locals

		jcxz	noWindow		; oops, returned an error

		mov	di, cx
		call	GrCreateState		; di = gstate to view

		call	GrBeginUpdate
		call	GrEndUpdate
		
		clrdw	axbx			; draw from upper-left corner
		movdw	dxcx, scratchBitmap
		call	GrDrawHugeBitmap

		call	GrDestroyState		; ^hdi is still gstate
noWindow:
	;
	;  Nuke the scratch bitmap, since we're done with it.
	;
		push	bp			; save locals
		movdw	bxax, scratchBitmap
		clr	bp			; no DB items
		call	VMFreeVMChain
		pop	bp			; restore locals
done:
		.leave
		ret
DBViewerTestTransform	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadyContentForTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets TFDestDisplayObject not-drawable and invalidates the
		content.

CALLED BY:	DBViewerTestTransform

PASS:		*ds:si	= DBViewer object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- a vis-object lives in the content.  It thinks it has to
	  draw whatever format is actually selected (by the GenValue
	  next to the content).  We have to set this vis-object
	  not-drawable so that the test-transform has a nice clean
	  slate to draw on.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadyContentForTest	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	dl, VUM_NOW
		clr	cl				; bits to set
		mov	ch, mask VA_DRAWABLE		; bits to clear
	;
	;  First we set the vis-object not drawable, which makes it
	;  disappear.
	;
	;		mov	bx, ds:[LMBH_handle]
		mov	si, offset TFDestDisplayObject
	;		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_SET_ATTRS
	;		call	ObjMessage
		call	ObjCallInstanceNoLock
	;
	;  Next we invalidate the content, to clear out any junk
	;  from previous tests (if the user is testing repeatedly).
	;
		mov	si, offset TFDestDisplayContent
	;		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_INVALIDATE
	;		call	ObjMessage
		call	ObjCallInstanceNoLock
		
		.leave
		ret
ReadyContentForTest	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreContentAfterTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets display object drawable.

CALLED BY:	DBViewerCancelTransform, TFSetSourceFormat, TFSetDestFormat

PASS:		*ds:si	= DBViewer object

RETURN:		*ds:si updated to point to DBViewer if block moved
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We don't actually invalidate the content.  As soon as the
	user moves the window the vis-object will redraw.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreContentAfterTest	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	dl, VUM_NOW
		clr	ch				; bits to set
		mov	cl, mask VA_DRAWABLE		; bits to clear
		
		mov	bx, ds:[LMBH_handle]
		mov	si, offset TFDestDisplayObject
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_SET_ATTRS
		call	ObjMessage
		
		.leave
		ret
RestoreContentAfterTest	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerCancelTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the TFDestDisplayObject is drawable

CALLED BY:	MSG_DB_VIEWER_CANCEL_TRANSFORM

PASS:		*ds:si	= DBViewerObject
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerCancelTransform	proc	far
		.enter
		
		call	RestoreContentAfterTest
		
		.leave
		ret
DBViewerCancelTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ApplyScaleToGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the scale factor and applies it to the gstate
		associated with the destination bitmap.

CALLED BY:	INTERNAL (DBViewerTestTransform)

PASS:		*ds:si	 = DBViewer object (for subroutines)
		di = gstate to apply scaling to
		cx = dest. bitmap width
		dx = dest. bitmap height

RETURN:		di = gstate (after adding scaling)
DESTROYED:	ds

PSEUDO CODE/STRATEGY:

	- determines the scale factor by dividing the heights of the
	  source & dest bitmaps, and also their widths.
	- calls GrApplyScale on the passed gstate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ApplyScaleToGState	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		
		sourceWidth	local	word
		destWidth	local	word
		sourceHeight	local	word
		destHeight	local	word
		
		.enter
		
		mov	destWidth, cx		; save passed width
		mov	destHeight, dx		; save passed height
	;
	;  Get source bitmap
	;
		push	di			; save passed gstate
		call	GetSourceBitmap		; returns in cx:dx
	;
	;  get the source bitmap's height & width
	;
		call	HugeBitmapGetFormatAndDimensions
		mov	sourceWidth, cx
		mov	sourceHeight, dx
	;
	; divide dest width by source width
	;
		mov	dx, destWidth
		mov	bx, sourceWidth
		clrdw	axcx			; low word of each height = 0
		call	GrUDivWWFixed		; returns dx.cx = quotient
		pushdw	dxcx			; save xscale
	;
	;  divide dest height by source height
	;
		mov	dx, destHeight
		mov	bx, sourceHeight
		clrdw	axcx			; fractional parts
		call	GrUDivWWFixed		; takes di = GState
		movdw	bxax, dxcx		; bx.ax = y scale
		popdw	dxcx			; dx.cx = x scale
		
		pop	di			; restore gstate
		call	GrApplyScale
		
		.leave
		ret
ApplyScaleToGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSourceBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the bitmap user wants to be the 'source' format.

CALLED BY:	INTERNAL

PASS:		*ds:si	= DBViewer object

RETURN:		cx = vm file handle
		dx = vm block handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
	- query source gen-value for its value
	- get the bitmap for that format slot

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSourceBitmap	proc	near
		class	DBViewerClass
		uses	ax,bx,si,di,bp
		.enter
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	;  Query the Source GenValue for its value
	;
		push	si, di
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFSourceGenValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE	; returns in dx
		call	ObjMessage			; nukes ax, cx, bp
		pop	si, di
		dec	dx				; 0-indexed
		
		mov	ax, ds:[di].DBVI_currentIcon	; icon number
		mov	bx, dx				; format number
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormat		; returns bitmap in cx:dx
		
		.leave
		ret
GetSourceBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerTFSetSourceFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User changed the source-format for the transform.

CALLED BY:	MSG_DB_VIEWER_TF_SET_SOURCE_FORMAT

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- mark the content invalid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/29/92    	Initial version
	lester	1/12/92		changed to send a MSG_VIS_INVALIDATE instead
				of a MSG_VIS_MARK_INVALID
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerTFSetSourceFormat	proc	far
		class	DBViewerClass
		.enter
		
		call	RestoreContentAfterTest
		
		mov	bx, ds:[LMBH_handle]
		mov	si, offset TFSourceDisplayContent
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
;		mov	ax, MSG_VIS_MARK_INVALID
;		mov	cl, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
;		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjMessage
		
		.leave
		ret
DBViewerTFSetSourceFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerTFSetDestFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User changed the destination-format for the transform.

CALLED BY:	MSG_DB_VIEWER_TF_SET_DEST_FORMAT

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- mark the content invalid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/29/92    	Initial version
	lester	1/12/92		changed to send a MSG_VIS_INVALIDATE instead
				of a MSG_VIS_MARK_INVALID

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerTFSetDestFormat	proc	far
		class	DBViewerClass
		.enter
	;
	;  Clear the destination-format view in case we had been
	;  running a test.
	;
		call	RestoreContentAfterTest
	;
	;  Ensure that it updates.
	;
		push	si				; save DBViewer
		mov	bx, ds:[LMBH_handle]
		mov	si, offset TFDestDisplayContent
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
;		mov	ax, MSG_VIS_MARK_INVALID
;		mov	cl, mask VOF_IMAGE_INVALID or mask VOF_GEOMETRY_INVALID
;		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjMessage
		pop	si				; *ds:si = DBViewer
	;
	;  Update all the stuff in the dialog to refect the state
	;  of the new destination format.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		call	SetDestinationValues
		
		.leave
		ret
DBViewerTFSetDestFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSourceAndDestGenValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure user can't select too high a format number.

CALLED BY:	DBViewerInitTFDialog

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We can't just subclass MSG_GEN_VALUE_SET_VALUE for the
	source & dest format selectors, and ask the DBViewer how
	many formats there are.  The selectors are run by the UI
	thread and can't block while waiting for a response from
	the document.

	So we have this routine, which sets instance data in the
	source & dest GenValue subclasses saying how high they
	can go.  Destination format can go one higher than the
	source format (so we can append formats on the end).

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSourceAndDestGenValues	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Get the current format count.
	;
		mov	bp, ds:[di].GDI_fileHandle
		mov	ax, ds:[di].DBVI_currentIcon
		call	IdGetFormatCount		; bx = count
		mov	dx, bx		
	;
	;  Tell both values what the format count is.
	;
		push	dx
		clr	cx
		mov	bx, ds:[di].GDI_display
		mov	si, offset TFSourceGenValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		call	ObjMessage

		pop	dx
		inc	dx
		clr	cx
		mov	si, offset TFDestGenValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		call	ObjMessage

		.leave
		ret
SetSourceAndDestGenValues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransformFormatDialogInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the dialog UI when it comes on screen

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= TransformFormatDialogClass object
		ds:di	= TransformFormatDialogClass instance data
		ds:bx	= TransformFormatDialogClass object (same as *ds:si)
		es 	= segment of TransformFormatDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We record the messages that we want to send to the DBViewer
	and then deliver them using the TO_APP_MODEL TravelOption.

BUGS:
	It would be better if the UI in the TFDialog was updated before it
	comes on screen but it is not that big of a deal. Right now the
	dialog comes up before the UI is updated because the message
	MSG_DB_VIEWER_INIT_TF_DIALOG is delayed throught the app queue.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	1/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransformFormatDialogInitiate	method dynamic TransformFormatDialogClass, 
					MSG_GEN_INTERACTION_INITIATE
		uses	ax, cx, dx, bp
		.enter
	;
	;  record a message to save the current format
	;
		push	si
		GetResourceSegmentNS	dgroup, es
		mov	bx, es
		mov	si, offset DBViewerClass
		mov	ax, MSG_DB_VIEWER_SAVE_CURRENT_FORMAT
		mov	di, mask MF_RECORD
		call	ObjMessage
		; ^hdi = ClassedEvent
		mov	cx, di		
		; ^hcx = the MSG_DB_VIEWER_SAVE_CURRENT_FORMAT ClassedEvent
	;
	;  record a message to initialize the UI for the 
	;  Transform Format Dialog 
	;
		mov	ax, MSG_DB_VIEWER_INIT_TF_DIALOG
		mov	di, mask MF_RECORD
		call	ObjMessage
		; ^hdi = the MSG_DB_VIEWER_INIT_TF_DIALOG ClassedEvent	
		pop	si
	;
	;  now send the two recorded messages to the app model
	;
	;  first send the MSG_DB_VIEWER_SAVE_CURRENT_FORMAT ClassedEvent
	;
		; ^hcx = the MSG_DB_VIEWER_SAVE_CURRENT_FORMAT ClassedEvent
		mov	dx, TO_APP_MODEL
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		call	ObjCallInstanceNoLock
	;
	;  now send the MSG_DB_VIEWER_INIT_TF_DIALOG ClassedEvent
	;
		mov	dx, TO_APP_MODEL
		mov	cx, di		; Pass handle of ClassedEvent in cx
		call	ObjCallInstanceNoLock

	;
	;  have the super class do its thing
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, offset TransformFormatDialogClass
		call	ObjCallSuperNoLock

		.leave
		ret
TransformFormatDialogInitiate	endm

FormatCode	ends

