COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Icon Editor
FILE:		documentImpex.asm

AUTHOR:		Steve Yegge, Nov  9, 1992

ROUTINES:

	Name			Description
	----			-----------
IconImport			Handler for MSG_IC0N_IMPORT (imports a graphic)
DealWithImportedGString		Makes an icon out of the passed gstring
AddIconFromImportedBitmap	Makes an icon out of BMO's main bitmap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/9/92		Initial revision

DESCRIPTION:
	
	Routines for importing graphics via the Import library.

	$Id: documentImpex.asm,v 1.1 97/04/04 16:06:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata	segment

continueImporting	byte

udata	ends

ImportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User wants to import something.

CALLED BY:	MSG_DB_VIEWER_IMPORT

PASS: 		*ds:si	= DBViewer object
		ss:bp	= ImpexTranslationParams

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerImport	method dynamic DBViewerClass,  MSG_DB_VIEWER_IMPORT
		uses	ax, cx, dx, bp
		.enter
	;
	;  Is it a bitmap?
	;
		cmp	ss:[bp].ITP_clipboardFormat, CIF_BITMAP
		jne	done
	;
	;  Get the bitmap file & block handles.
	;
		mov	cx, ss:[bp].ITP_transferVMFile
		mov	dx, ss:[bp].ITP_transferVMChain.high
		call	DealWithImportedGString

		call	ImpexImportExportCompleted
done:
		.leave
		ret
DBViewerImport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DealWithImportedGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up to edit the imported transfer gstring

CALLED BY:	IconImport

PASS:		^vcx:dx = huge bitmap to import
		*ds:si	= DBViewer object

RETURN:		nothing
DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This routine will simply display an error and return if
	the imported graphic will be larger than 64k bytes.

PSEUDO CODE/STRATEGY:

	- create a bitmap from the gstring
	- create an icon in the database from the bitmap
	- switch editing to the new icon  (similar to IconAddIcon)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DealWithImportedGString	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Decide whether the bitmap is to large to be an icon.
	;  First lock the bitmap, and get its height, width, & color.
	;
		push	cx, dx, ds:[LMBH_handle]	; save bitmap
		call	HugeBitmapGetFormatAndDimensions
		call	CheckFormatTooLargeAndDealWithIt
		pop	cx, dx, bx
		LONG	jc	done			; no can do.
	;
	;  Make sure the bitmap is 72 dpi, or it'll screw everything
	;  up.  Of course, it'll distort the bitmap depending on
	;  how far it differs from 72 dpi (x & y res), but "oh well."
	;
		call	EnsureBitmapIs72dpi
	;
	;  The bitmap didn't come with a mask, more than likely,
	;  so we have to give it one.  Also unset the BMT_PALETTE bit.
	;
		call	EnsureBitmapHasAMask
	;
	;  Create a new bitmap in the BMO of the correct dimensions.  
	;  Tell it to get the bounds from the passed gstring
	;
		push	si
		mov	si, offset BMO
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_BITMAP_REPLACE_WITH_TRANSFER_FORMAT
		call	ObjMessage
		pop	si
	;
	;  Now make an icon entry in the database from the main bitmap.
	;
		call	MemDerefDS
		call	AddIconFromImportedBitmap	; returns ax = icon #

		clr	bx				; format 0
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormatDimensions		; cx=width, dx=height
	;
	;  Resize the fatbits.
	;
		push	ds:[LMBH_handle]
		push	ax				; icon number
		mov	al, IBS_8
		call	ResizeBMOAndFatbits
		pop	ax
	;
	;  Set the name of the new icon to "untitled"
	;
		GetResourceHandleNS IconStrings, bx
		mov	di, bx				; save block handle
		push	ax				; icon number
		call	MemLock
		mov	ds, ax
		mov	bx, offset UntitledString
		mov	dx, ds:[bx]			; dereference chunk
		mov	bx, ds				; ds:bx = string
		mov	cx, 9				; ouch!
		pop	ax				; icon number
		call	IdSetIconName
		mov	bx, di				; restore strings block
		call	MemUnlock
		pop	bx
		call	MemDerefDS
	;
	;  Add the icon to the dynamic list for viewing
	;
		mov	ax, MSG_DB_VIEWER_RESCAN_DATABASE
		call	ObjCallInstanceNoLock
	;
	;  Do lots of other stuff
	;
		call	EnableEditing			; ui gadgetry

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset

		clr	ds:[di].DBVI_currentFormat	; (DBViewerDrawFormats)

		mov	ax, MSG_DB_VIEWER_UPDATE_PREVIEW_AREA
		call	ObjCallInstanceNoLock

		mov	ax, MSG_DB_VIEWER_INIT_CHANGE_ICON_DIALOG
		call	ObjCallInstanceNoLock

		mov	si, offset FormatViewer
		mov	ax, MSG_FORMAT_CONTENT_RESCAN_LIST
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
DealWithImportedGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddIconFromImportedBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new database icon after importing a bitmap.

CALLED BY:	DealWithImportedGString

PASS:		*ds:si	= DBViewer object
RETURN:		ax	= new icon number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddIconFromImportedBitmap	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di,bp,ds
		.enter
	;
	;  Add a blank icon to the database.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bp, ds:[di].GDI_fileHandle
		mov	cx, 1				; only 1 format
		call	IdAddIcon			; returns ax = number
		mov	ds:[di].DBVI_currentIcon, ax
	;
	;  To add the icon to the database, we initialize es:anIconHeader.
	;  First set the preview object & colors from their current values.
	;
		mov	bx, 1
		call	IdSetFormatCount
	;
	;  Now set the preview colors in the icon (query the selectors).
	;
		call	GetPreviewSettings
		call	IdSetPreviewObject
		call	IdSetPreviewColors
	;
	;  Set the 1st format to be the imported bitmap
	;
		push	si, ax, bp			; save format info
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
		call	ObjMessage
		pop	si, ax, bp			; restore format info

		clr	bx
		call	IdSetFormat
	;
	;  Set up the VisMonikerListEntryType to something reasonable.
	;  First get the actual color scheme for the bitmap.
	;
		push	ax			; save icon number
		movdw	bxdi, cxdx		; bx:di = huge array
		call	HugeArrayLockDir	; ax = segment
		mov	ds, ax
		clr	bh
		mov	bl, ds:[(size HugeArrayDirectory)].CB_simple.B_type
		call	HugeArrayUnlockDir
		andnf	bx, mask BMT_FORMAT	; isolate BMFormat
	;
	;  dx is the color scheme.  Convert to a DisplayClass
	;
EC <		cmp	bl, BMF_24BIT					>
EC <		ERROR_A	INVALID_BITMAP_FORMAT				>
		mov	bl, cs:[classTable][bx]	; bx = DisplayClass
		clr	bh			; not strictly necessary
	;
	;  Initialize most of the values to constants, and then
	;  stick in the color.
	;
		mov	cx, VisMonikerListEntryType \
			<DS_STANDARD,VMS_ICON,,TRUE,DAR_NORMAL,DC_COLOR_4>
		andnf	cx, not (mask VMLET_GS_COLOR)
		ornf	cx, bx			; set color scheme
		pop	ax			; icon number
		clr	bx			; this is the only format
		call	IdSetFormatParameters	; do it!

		.leave
		ret

classTable	byte	\
		DC_GRAY_1,			; BMF_MONO = 0
		DC_COLOR_4,			; BMF_4BIT = 1
		DC_COLOR_8,			; BMF_8BIT = 2
		DC_CF_RGB			; BMF_24BIT = 3

AddIconFromImportedBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureBitmapIs72dpi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuffs the xRes & yRes fields of the EB_bm header

CALLED BY:	DealWithImportedGString

PASS:		^vcx:dx = bitmap

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/13/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureBitmapIs72dpi	proc	near
		uses	ax,bx,dx,si,ds
		.enter
	;
	;  1/13/94 -- added the line to unset the palette bit to
	;  fix the screwed-up-fatbits-colors problem.  -stevey
	;
		movdw	bxdi, cxdx
		call	HugeArrayLockDir
		mov	ds, ax
		mov	si, offset EB_bm	; ds:si = CBitmap
		mov	ds:[si].CB_xres, STANDARD_ICON_DPI
		mov	ds:[si].CB_yres, STANDARD_ICON_DPI
		and	ds:[si].CB_simple.B_type, not mask BMT_PALETTE
		call	HugeArrayUnlockDir

		.leave
		ret
EnsureBitmapIs72dpi	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureBitmapHasAMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put a mask in the bitmap if there is none.

CALLED BY:	DealWithImportedGString

PASS:		^vcx:dx = bitmap

RETURN:		^vcx:dx = new bitmap with mask.  Nukes the old one.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/16/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureBitmapHasAMask	proc	near
		uses	ax,bx,si,di,bp,ds

		bitmapFile	local	word	push	cx
		oldBitmapBlock	local	word	push	dx
		newBitmapBlock	local	word
		
		.enter
	;
	;  See if it has one already, and bail if so.
	;
		movdw	bxdi, cxdx			; bx:di = old bitmap
		call	HugeArrayLockDir
		mov	ds, ax
		mov	al, ds:[(size HugeArrayDirectory)].CB_simple.B_type
		mov	cx, ds:[(size HugeArrayDirectory)].CB_simple.B_width
		mov	dx, ds:[(size HugeArrayDirectory)].CB_simple.B_height
		call	HugeArrayUnlockDir

		test	al, mask BMT_MASK
		jnz	alreadyHasOne
	;
	;  No mask.  We got the size just in case -- create a new
	;  bitmap of that size, but masked.
	;
		ornf	al, mask BMT_MASK	; make it have a mask
		mov	bx, bitmapFile
		clr	di, si			; exposure OD
		call	GrCreateBitmap		; ax = block, di = gstate
		mov	newBitmapBlock, ax
	;
	;  Draw the old bitmap to the new bitmap.  Set all the
	;  mask bits, since (fucking) GrCreateBitmap clears them.
	;
		push	cx, dx			; width & height
		clr	ax, bx			; upper-left coordinate
		mov	dx, bitmapFile
		mov	cx, oldBitmapBlock	; ^vdx:cx = bitmap to draw
		call	GrDrawHugeBitmap

		mov	ax, (CF_INDEX shl 8 or C_BLACK)
		call	GrSetAreaColor

		clr	dx			; no color transfer info
		mov	ax, mask BM_EDIT_MASK
		call	GrSetBitmapMode

	;		call	GrSetMixMode

		mov	dx, bitmapFile
		mov	cx, newBitmapBlock	; ^vdx:cx = new bitmap
		clrdw	bxax			; position to draw at
		pop	cx, dx
		call	GrFillRect
		
		clr	ax, dx
		call	GrSetBitmapMode
	;
	;  Destroy the old bitmap and the new gstate.
	;
		mov	al, BMD_LEAVE_DATA	; just nuke the gstate.
		call	GrDestroyBitmap

		push	bp			; locals
		mov	bx, bitmapFile
		mov	ax, oldBitmapBlock
		clr	bp			; no DB items
		call	VMFreeVMChain
		pop	bp			; locals
	;
	;  Return the new bitmap.
	;
		mov	cx, bitmapFile
		mov	dx, newBitmapBlock

		jmp	done
alreadyHasOne:
		mov	cx, bitmapFile
		mov	dx, oldBitmapBlock
done:
		.leave
		ret
EnsureBitmapHasAMask	endp


ImportCode	ends
