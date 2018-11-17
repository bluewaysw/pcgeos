COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Icon Editor
FILE:		documentToken.asm

AUTHOR:		Steve Yegge, Mar 17, 1993

ROUTINES:
	Name			Description
	----			-----------

DBViewerImportTokenDatabase	Top-level routine for importing tokens
ImportSelectedTokens		Imports all graphical tokens into database
MakeIconFromToken		Adds an icon given a position in the token.db
MakeFormatFromToken		Creates a format from a specific moniker
GetVisMonikerHeader		Returns VisMonikerListEntryType for moniker
GetTokenMonikerByPosition	Gets a gstring moniker from a token
VisMonikerToHugeBitmap		Puts a VisMoniker in the BMO, basically.
GetTokenCharsByPosition		Gets token chars from offset into token.db
UpdateProgressDialog		Updates the percent-complete progress dialog

IconUpdateTokenViewer		Re-scans the token.db for the dynamic list
IconSelectAllTokens		User selects all tokens at once using trigger
IconSelectTokenFromList		Sets "TokenDBNumSelected" genValue
IconTokenListGetItemMoniker	Returns a moniker for the dynamic list

IconGetAppToken			Shows the moniker for the selected app.
UpdateDialogMoniker		Utility routine for setting the moniker.
DBViewerChangeAppToken		Top-level routine for installing a token
GetTokenCharsFromFileSelector	Returns token characters for current selection
FillInMonikerList		Makes a moniker list from an icon
MakeMonikerFromFormat		Creates a vis-moniker from an icon format
StoreMonikerInList		Stores passed moniker in passed moniker-list
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/17/93		Initial revision

DESCRIPTION:

	Routines for viewing & importing tokens from token_da.000
 
	$Id: documentToken.asm,v 1.1 97/04/04 16:05:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

rootString	char	"\\",0

idata	ends

TokenCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerImportTokenDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets selected graphical tokens and sticks them in the 
		current icon database.

CALLED BY:	MSG_DB_VIEWER_IMPORT_TOKEN_DATABASE

PASS: 		*ds:si	= DBViewerObject
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- initiate the stop-import dialog
	- make a copy of the current bitmap in BMO
	- call a routine to import the tokens using the BMO
	- send the stop-import dialog into hell
	- recover the old bitmap in BMO

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerImportTokenDatabase	method dynamic DBViewerClass, 
					MSG_DB_VIEWER_IMPORT_TOKEN_DATABASE
		uses	ax, cx, dx, bp
		.enter

		mov	es:[continueImporting], 1	; TRUE
	;
	;  Initiate the stop-import dialog.
	;
		push	si, di
		GetResourceHandleNS	ImportProgressDialog, bx
		mov	si, offset	ImportProgressDialog
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage
		pop	si, di				; restore DBViewer
	;
	;  Get the current bitmap and save it.
	;
		mov	cx, ds:[di].DBVI_bitmapVMFileHandle

		push	si				; save DBViewer
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_CREATE_TRANSFER_FORMAT
		call	ObjMessage
		pop	si				; restore DBViewer
		mov_tr	dx, ax			; ^vcx:dx = transfer format
	;
	;  Find out which tokens are selected and import them.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		push	ds:[LMBH_handle], si		; save DBViewer
		call	ImportSelectedTokens
	;
	;  Restore the original bitmap to BMO (it's still in ^vcx:dx).
	;
		pop	bx, si				; restore DBViewer
		call	MemDerefDS
		push	si
		mov	si, offset BMO
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_REPLACE_WITH_TRANSFER_FORMAT
		call	ObjMessage
		pop	si

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	;  Free the copy of the old bitmap.
	;
		mov_tr	ax, dx				; transfer format
		clr	bp
		mov	bx, ds:[di].DBVI_bitmapVMFileHandle
		call	VMFreeVMChain
	;
	;  Rescan the database to add the new child.
	;
		mov	ax, MSG_DB_VIEWER_RESCAN_DATABASE
		call	ObjCallInstanceNoLock
	;
	;  Free any leftover memory handles in the database.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	bp, ds:[di].GDI_fileHandle
		call	IdDiscardIconList
	;
	;  Get rid of the stop-import dialog
	;
		GetResourceHandleNS	ImportProgressDialog, bx
		mov	si, offset	ImportProgressDialog
		mov	di, mask MF_CALL
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		call	ObjMessage
	;
	;  Clear the stop-import dialog's percent-progress indicator.
	;
		GetResourceHandleNS	ImportProgressValue, bx
		mov	si, offset	ImportProgressValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	bp
		clr	dx			; integer value
		call	ObjMessage

		sub	sp, size ReplaceVisMonikerFrame
		mov	bp, sp
		mov	dx, size ReplaceVisMonikerFrame
		mov	ss:[bp].RVMF_dataType, VMDT_NULL
		mov	ss:[bp].RVMF_updateMode, VUM_NOW

		GetResourceHandleNS	ImportProgressGlyph, bx
		mov	si, offset	ImportProgressGlyph
		mov	di, mask MF_STACK
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		call	ObjMessage

		add	sp, size ReplaceVisMonikerFrame

		.leave
		ret
DBViewerImportTokenDatabase	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportSelectedTokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Queries the token-db viewer for selections, and imports 
		them into the active database.

CALLED BY:	DBViewerImportTokenDatabase

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get a list of the selections in the TokenDBViewer
	- loop through the selections, checking to see if
	  the user wants to continue the import process, and
	  if so, converting them to icons and adding them to
	  the current icon database.  Also update the progress
	  (stop-import) dialog for each token imported.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/25/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportSelectedTokens	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	;  Find out how many selections there are in the viewer.
	;
		push	si
		GetResourceHandleNS	TokenDBViewer, bx
		mov	si, offset	TokenDBViewer
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS
		call	ObjMessage		; returns in ax
		pop	si			; restore DBViewer

		tst	ax
		LONG jz	done			; don't bother...no selection
	;
	;  Allocate a buffer for the (word-sized) selections.
	;
		mov	bp, ax			; bp <- #selections
		shl	ax			; 2 bytes per selection
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; bx = handle
		jc	done			; out of memory
		push	bx			; save selection-block

		mov	cx, ax			; segment address
		clr	dx			; cx:dx = buffer
	;
	;  Ask the TokenDBViewer to return its selections in the buffer.
	;
		push	si			; save DBViewer
		GetResourceHandleNS	TokenDBViewer, bx
		mov	si, offset	TokenDBViewer
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
		call	ObjMessage
		pop	si			; restore DBViewer

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset

		mov	bp, ax			; number of selections
		mov	es, cx			; es:0 = selection list
		clr	cx			; counter
tokenLoop:
	;
	;  Now for each selection get the moniker(s) and make an icon.
	;  We're not using the loop instruction, because we want
	;  the tokens to be added in the same order as they appear
	;  in the token database viewer.  (So we count up from zero).
	;
		mov	ax, es			; save selection segment

		GetResourceSegmentNS	dgroup, es
		tst	es:[continueImporting]	; user bailed?
		jz	doneLoop

		mov	es, ax			; restore selection segment

		mov	bx, cx			; counter
		shl	bx			; word-sized identifiers
		mov	bx, {word} es:[bx]	; bx <- position (selection)

		call	UpdateProgressDialog	; show current moniker
		call	MakeIconFromToken

		inc	cx
		cmp	cx, bp
		jb	tokenLoop
doneLoop:
	;
	;  Just for fun we'll put "100" in the progress dialog, so
	;  the user knows we really finished.
	;
		mov	dx, 100
		clr	cx
		GetResourceHandleNS	ImportProgressValue, bx
		mov	si, offset	ImportProgressValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	bp			; not indeterminate
		call	ObjMessage

		pop	bx			; restore selection-block
		call	MemFree
done:
		.leave
		ret
ImportSelectedTokens	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeIconFromToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds an icon to the database from a VisMoniker.

CALLED BY:	DBViewerImportTokenDatabase

PASS:		*ds:si	= DBViewer object
		bx	= token's position in the token database

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- create a "blank" icon in the current database
	- attempt to get 3 monikers from the token
	- for each moniker that gets returned, make a format for it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeIconFromToken	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter

		push	bx			; store token's position
	;
	;  Make a blank icon and add to icon database.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bp, ds:[di].GDI_fileHandle
		clr	cx			; no formats for now.
		call	IdAddIcon		; ax = icon number
	;
	;  Set the name in anIconHeader from the token chars.
	;
		mov_tr	dx, ax			; dx = icon number
		call	GetTokenCharsByPosition	; ax, bx = chars (4)

		sub	sp, size GeodeToken
		mov	bp, sp			; ss:bp = name buffer

		mov	{word}ss:[bp], ax
		mov	{word}ss:[bp+2], bx
		clr	{byte}ss:[bp+4]

		mov_tr	ax, dx			; ax = icon number	
		mov	bx, ss
		mov	dx, bp
		mov	cx, size GeodeToken
		mov	bp, ds:[di].GDI_fileHandle
		call	IdSetIconName

		add	sp, size GeodeToken
	;
	;  Now set the preview colors in the icon (query the selectors).
	;
		call	GetPreviewSettings
		call	IdSetPreviewObject
		call	IdSetPreviewColors
	;
	; Attempt to get 4 monikers from the token.  Make formats from
	; them (if they exist).  
	;
		clr	dx			; dl = format counter
		mov	di, ax			; di = icon number
		pop	bx			; restore position

		call	SeeIfWeShouldDoSVGA	; if yes, clears carry
		jc	noSVGA

		mov	cl, SVGA_DISPLAY_TYPE
		mov	ax, BMF_4BIT
		call	MakeFormatFromToken
		jc	noSVGA
		inc	dx
noSVGA:
		mov	cl, VGA_DISPLAY_TYPE	; cl = DisplayType
		mov	ax, BMF_4BIT		; ax = BMFormat
		call	MakeFormatFromToken
		jc	noVGA
		inc	dx			; format counter
noVGA:
		mov	cl, MCGA_DISPLAY_TYPE
		mov	ax, BMF_MONO		; BMFormat
		call	MakeFormatFromToken
		jc	noMCGA
		inc	dx			; format counter
noMCGA:
		mov	cl, CGA_DISPLAY_TYPE
		mov	ax, BMF_MONO		; BMFormat
		call	MakeFormatFromToken
		jc	noCGA
		inc	dl			; format counter
noCGA:
		mov	ax, di			; icon number
		mov	bx, dx			; format count
		call	IdSetFormatCount	; done in MakeFormatFromToken
	;
	;  Discard all the memory blocks associated with the new icon.
	;  (Happily bp is still the file handle, and ax is the icon).
	;
		call	IdDiscardIcon
	;
	;  Update the database viewer
	;
		mov	ax, MSG_DB_VIEWER_ADD_CHILD
		call	ObjCallInstanceNoLock

		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset

		.leave
		ret
MakeIconFromToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeeIfWeShouldDoSVGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry clear if we're importing SVGA monikers.

CALLED BY:	MakeIconFromToken

PASS:		nothing

RETURN:		carry set if no
		carry clear if yes

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This routine (and the associated UI in the import-token
	dialog) is a bit of a hack.  At the time of this writing,
	about half of the super-VGA monikers for GEOS apps are
	just blanks.  When you import them you get a 64x40 blank
	moniker, which looks terrible.  However, we don't really
	want to make it impossible for the user to get to the
	SVGA moniker if it exists, so I've put in this option.

	At some point in the distant future, all GEOS apps will
	have valid SVGA monikers, GeoManager will display them
	in SVGA video modes, and I then I will be able to take
	this option out.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeeIfWeShouldDoSVGA	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Just get the UI setting, and set the carry accordingly.
	;
		GetResourceHandleNS	ImportSVGAMonikersBGroup, bx
		mov	si, offset	ImportSVGAMonikersBGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjMessage

		test	ax, mask ITO_IMPORT_SVGA
		jz	nope

		clc					; yep
		jmp	short	done
nope:
		stc					; nope
done:
		.leave
		ret
SeeIfWeShouldDoSVGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeFormatFromToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempts to create a format in an icon, from a token.

CALLED BY:	MakeIconFromToken

PASS:		*ds:si	= DBViewer object
		cl = DisplayType
		bx = position of token in token.db (gstring tokens only)
		di = icon number
		dx = format number
		ax = BMFormat to set in BMO

RETURN:		carry set if the moniker didn't exist for the DisplayType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/4/92			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeFormatFromToken	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp

		displayType	local	word	push	cx
		bmFormat	local	word	push	ax
		icon		local	word	push	di
		format		local	word	push	dx
		monikerBlock	local	word
		monikerChunk	local	word
		
		.enter

		mov	ax, (VMS_ICON shl offset VMSF_STYLE) or \
				mask VMSF_GSTRING
		call	GetTokenMonikerByPosition 	; ^lcx:dx = moniker
		LONG	jc	done
	;
	;  We have the right moniker.  Tell the BMO to be color or
	;  monochrome or whatever.
	;
		mov	monikerBlock, cx
		mov	monikerChunk, dx

		push	bp, si			; save locals
		mov	cx, bmFormat
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO		; ^lbx:si = vis-bitmap
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	dx, STANDARD_ICON_DPI	; x resolution
		mov	bp, dx			; y resolution
		mov	ax, MSG_VIS_BITMAP_SET_FORMAT_AND_RESOLUTION
		call	ObjMessage
		pop	bp, si			; restore locals
	;
	;  Convert the moniker to a bitmap and set it in database.
	;
		mov	cx, monikerBlock
		mov	dx, monikerChunk	; ^lcx:dx = moniker
		call	VisMonikerToHugeBitmap	; ^vcx:dx = huge bitmap

		mov	ax, icon
		mov	bx, format
		push	bp			; locals
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bp, ds:[di].GDI_fileHandle

		push	cx			; save bitmap block
		mov	cx, 1			; create 1 blank format
		call	IdCreateFormats
		pop	cx			; restore bitmap block
		
		call	IdSetFormat		; save bitmap in format
		pop	bp			; locals
	;
	;  Compute the VisMonikerListEntryType value for the format
	;  and store it in IF_type.  If we don't do this, all our
	;  effort for importing the moniker from the token database
	;  is wasted, because the specific UI then can't pick the 
	;  right moniker.
	;
		mov	cx, monikerBlock
		mov	dx, monikerChunk
		mov	ax, displayType
		call	GetVisMonikerHeader	; cx = VisMonikerListEntryType

		push	bp			; locals
		mov	ax, icon
		mov	bx, format
		mov	bp, ds:[di].GDI_fileHandle
		mov	dx, 1			; pass VisMonikerListEntryType
		call	IdSetFormatParameters
		pop	bp			; locals

		mov	bx, monikerBlock
		call	MemFree

		clc				; return no error
done:
		.leave
		ret
MakeFormatFromToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetVisMonikerHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the VisMonikerListEntryType (for IF_type).

CALLED BY:	MakeFormatFromToken

PASS:		^lcx:dx = VisMoniker
		al	= DisplayType

RETURN:		cx	= VisMonikerListEntryType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	A VisMonikerListEntryType record is 2 bytes.  The low byte
	is exactly the same as a VisMonikerType record, which is
	the first byte of a VisMoniker.  So we grab that and stick
	it in the low byte of our VisMonikerListEntryType.

	The high byte of the VisMonikerListEntryType has 2 fields:
	VMLET_GS_SIZE (DisplaySize) and VMLET_STYLE (VMStyle).
	The DisplaySize we can nab from the passed DisplayType.
	The style field we can assume is VMS_ICON, because the
	token database doesn't store tool icons, and we're not
	interested in other kinds.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/11/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetVisMonikerHeader	proc	near
		uses	ax,bx,dx,si,di,bp,ds
		.enter
	;
	;  First lock the moniker block and get the VisMonikerType.
	;
		mov	bp, ax			; save passed DisplayType
		mov	bx, cx
		call	MemLock
		mov	ds, ax
		mov	si, dx			; *ds:si = VisMoniker
		mov	di, ds:[si]		; ds:di = VisMoniker
		mov	cl, ds:[di].VM_type	; initialize low byte
		call	MemUnlock
	;
	;  Set the VMLET_STYLE field.
	;
		mov	ch, VMS_ICON
	;
	;  Now get the DisplaySize from the passed DisplayType.
	;
		mov	ax, bp			; al = DisplayType
		andnf	al, mask DT_DISP_SIZE	; isolate DisplaySize
		shr	al
		shr	al
		ornf	ch, al			; set the bits

		.leave
		ret
GetVisMonikerHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTokenMonikerByPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns moniker for a token based on position in token.db

CALLED BY:	INTERNAL

PASS:		bx = position (0-indexed) in token database
		ax = VisMonikerSearchFlags
		cl = DisplayType

RETURN:		^lcx:dx = moniker
		carry set if no match, clear otherwise

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	You have to free the moniker block returned by this
	routine when you're finished with it or you'll have
	a nice core leak.

PSEUDO CODE/STRATEGY:

	- get a list of the tokens
	- index into the list
	- load the correct token
	- free the list block

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	11/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTokenMonikerByPosition	proc	near
		uses	ax,bx,si,di,bp,ds

		position	local	word	push	bx
		searchFlags	local	word	push	ax
		displayType	local	byte
		listBlock	local	hptr
		monikerBlock	local	hptr

		.enter
	
		mov	displayType, cl
	;
	;  Get a list of the tokens in the token.db file.  GString only.
	;
		mov	ax, mask TRF_ONLY_GSTRING
		clr	bx
		call	TokenListTokens
		mov	listBlock, bx

		call	MemLock
		mov	ds, ax			; ds:0 = token list

		mov	ax, size GeodeToken
		mov	bx, position
		mul	bx			; ax = index into list
		mov	si, ax			; ds:[si] = desired token

		mov	ax, LMEM_TYPE_GENERAL
		clr	cx			; block header size
		call	MemAllocLMem		; returns bx = block handle
		mov	monikerBlock, bx
	;
	;  Set up parameters to TokenLoadMoniker
	;
		mov	di, searchFlags
		push	di			; VisMonikerSearchFlags

		mov	cx, bx			; cx = lmem block handle
		clr	di			; create a chunk for moniker
		mov	ax, {word} ds:[si].GT_chars	; get Token
		mov	bx, {word} ds:[si].GT_chars+2
		mov	si, ds:[si].GT_manufID

		push	di			; pass unused buffer size

		mov	dh, displayType
		call	TokenLoadMoniker	; di = chunk handle
		jc	noToken
	;
	;  Free the list-block and return the new moniker
	;
		mov	bx, listBlock
		call	MemFree

		mov	cx, monikerBlock
		mov	dx, di				; ^lcx:dx = moniker

		clc
		jmp	short	done
noToken:
		stc
done:
		.leave
		ret
GetTokenMonikerByPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisMonikerToHugeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes a vismoniker and returns a huge bitmap.  Uses BMO.

CALLED BY:	MakeIconFromToken

PASS:		^lcx:dx	= VisMoniker
		ds	= segment of DBViewer

RETURN:		^vcx:dx = huge bitmap
DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This routine nukes whatever bitmap was in the BMO, so be
	sure to save it if you needed it.

PSEUDO CODE/STRATEGY:

	- save the bitmap currently in the BMO
	- load the gstring from the moniker
	- create a bitmap in the BMO using the gstring
	- get the main bitmap from the BMO (we return this)
	- put the original bitmap back in the BMO

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	11/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisMonikerToHugeBitmap	proc	near
		uses	ax,bx,si,di,bp,es
		.enter

		segmov	es, ds, bx		; es = DBViewer segment
		movdw	bxsi, cxdx
	;
	;  Load the gstring from the VisMoniker
	;
		push	bx			; save block handle
		call	MemLock
		mov	ds, ax
		mov	bx, ax			; bx = segment address
		mov	si, ds:[si]		; bx:si = VisMoniker
		add	si, size VisMoniker + size VisMonikerGString	
						; bx:si=gstring
		mov	cl, GST_PTR
		call	GrLoadGString		; returns si = gstring handle
		push	si			; save handle to free...

		mov	bp, si			; bp = gstring
	;
	;  Create a bitmap in the BMO using the gstring.  Free up
	;  any old data structures first.
	;
		segmov	ds, es, bx
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_BECOME_DORMANT
		call	ObjMessage

		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		clr	cx			; get bounds from gstring
		mov	ax, MSG_VIS_BITMAP_CREATE_BITMAP
		call	ObjMessage
	;
	;  Get the bitmap and return it.
	;
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
		call	ObjMessage		; returns ^vcx:dx
	;
	;  Free up the gstring we created, and unlock the vismoniker block.
	;
		pop	si			; restore gstring handle
		clr	di			; no gstate
		mov_tr	ax, dx			; ^vcx:ax = bitmap
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString

		pop	bx			; restore block handle
		call	MemUnlock

		mov_tr	dx, ax			; ^vcx:dx = bitmap
		
 		.leave
		ret
VisMonikerToHugeBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateProgressDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the ImportProgressDialog to show progress.

CALLED BY:	DBViewerImportTokenDatabase

PASS:		cx = token that we're on
		bx = position in the token database
		bp = total number of tokens to import

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- multiply the numerator (cx) by 100
	- divide
	- take integer result and stick it in ImportProgressValue
	- get the moniker from the database
	- use it to update the ImportProgressGlyph

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateProgressDialog	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	
		push	bx			; save position
	;
	;  Figure out what percentage we're on, rounded to nearest percent
	;
		jcxz	divideZero		; 0 percent

		mov	ax, 100
		mul	cx
		clr	dx			; high word of dividend
		div	bp			; ax = percent (integer)
		mov	dx, ax			; dx = percent
		jmp	short	doneMult
divideZero:
		mov	dx, cx
doneMult:
		GetResourceHandleNS	ImportProgressValue, bx
		mov	si, offset	ImportProgressValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	bp			; not indeterminate
		call	ObjMessage
	;
	;  Now update the display glyph
	;
		GetResourceHandleNS	IconApp, bx
		mov	si, offset	IconApp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
		call	ObjMessage

		mov	cl, ah			; DisplayType

		pop	bx			; bx = item number
		mov	ax, (VMS_ICON shl offset VMSF_STYLE) or \
				mask VMSF_GSTRING
		call	GetTokenMonikerByPosition	; ^lcx:dx = moniker
		push	cx
	
		GetResourceHandleNS	ImportProgressGlyph, bx
		mov	si, offset	ImportProgressGlyph
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		mov	bp, VUM_NOW
		call	ObjMessage
	;
	;  Free the block returned by GetTokenMonikerByPosition
	;
		pop	bx
		call	MemFree

		.leave
		ret
UpdateProgressDialog	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTokenCharsByPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the GT_chars for the token, given a position.

CALLED BY:	INTERNAL

PASS:		bx = position

RETURN:		ax = {word} GT_chars
		bx = {word} GT_chars+2

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- make a list of the gstring tokens
	- use the passed position as an index into the list
	- get the token chars and return them

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	11/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTokenCharsByPosition	proc	near
		uses	cx,dx,si,ds
		.enter

		mov	dx, bx			; save position
		mov	ax, mask TRF_ONLY_GSTRING
		clr	bx
		call	TokenListTokens		; bx = list-block handle

		call	MemLock
		mov	cx, bx			; save handle
		mov	ds, ax			; ds:0 = token list

		mov	ax, size GeodeToken
		mov	bx, dx			; restore position
		mul	bx			; ax = index into list
		mov	si, ax			; ds:[si] = desired token

		mov	ax, {word} ds:[si].GT_chars	; get Token
		mov	bx, {word} ds:[si].GT_chars+2

		xchg	bx, cx			; bx <- handle of list block
		call	MemFree
		xchg	bx, cx			; bx <- chars

		.leave
		ret
GetTokenCharsByPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconApplicationUpdateTokenViewer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a list of the tokens in the token.db

CALLED BY:	MSG_ICON_APPLICATION_UPDATE_TOKEN_VIEWER

PASS:		nothing
RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- delete all children in viewer
	- count tokens in token.db file
	- add that many children to viewer
	- clear TokenDBNumSelected
	- initialize TokenDBNumTokens

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	11/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconApplicationUpdateTokenViewer	method	IconApplicationClass,
				MSG_ICON_APPLICATION_UPDATE_TOKEN_VIEWER
		.enter
	;
	;  First get rid of all the items currently in the list
	;
		GetResourceHandleNS	TokenDBViewer, bx
		mov	si, offset	TokenDBViewer
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
		call	ObjMessage		; returns in cx
		jcxz	doneRemove	

		mov	dx, cx			; number of items to remove
		GetResourceHandleNS	TokenDBViewer, bx
		mov	si, offset	TokenDBViewer
		mov	di, mask MF_CALL
		mov	cx, GDLP_FIRST
		mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
		call	ObjMessage

doneRemove:
	;
	;  Count number of tokens in token.db and add that many children
	;
		mov	ax, mask TRF_ONLY_GSTRING
		clr	bx
		call	TokenListTokens		; ax = # tokens in list
		call	MemFree			; get rid of the actual list
	
		push	ax			; save number
		mov	dx, ax			; dx = number of items to add
		GetResourceHandleNS	TokenDBViewer, bx
		mov	si, offset	TokenDBViewer
		clr	di
		mov	cx, GDLP_LAST
		mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
		call	ObjMessage
	;
	;  Initialize the GenValues in the viewer box.
	;
		pop	dx	
		GetResourceHandleNS	TokenDBNumTokens, bx
		mov	si, offset	TokenDBNumTokens
		clr	di
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	bp			; not indeterminate
		clr	cx			; fractional value
		call	ObjMessage

		GetResourceHandleNS	TokenDBNumSelected, bx
		mov	si, offset	TokenDBNumSelected
		clr	di
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clrdw	cxdx			; integer.fraction
		clr	bp			; not indeterminate
		call	ObjMessage

		.leave
		ret
IconApplicationUpdateTokenViewer	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconSelectAllTokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Selects all the icons in the token.db viewer

CALLED BY:	MSG_ICON_SELECT_ALL_TOKENS

PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- count the tokens
	- make a block containing identifers (0-numChildren)
	- pass the block to the item group, selecting them all
	- update TokenDBNumSelected

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconSelectAllTokens	method dynamic IconProcessClass,
					MSG_ICON_SELECT_ALL_TOKENS
	;
	;  Get a buffer with all the identifiers in the list.
	;  It should be sequential integers, so just query the
	;  list for the number of children
	;
		GetResourceHandleNS	TokenDBViewer, bx
		mov	si, offset	TokenDBViewer
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS	; returns in cx
		call	ObjMessage

		mov_tr	ax, cx			; ax = number of selections
		mov	bp, ax			; bp = num selections
		shl	ax			; ax = bytes to allocate
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	done			; out of memory
		push	bx			; save block handle
	;
	;  set the identifiers in the block (0 at position 0, 1 at
	;  position 1, etc).
	;
		mov	ds, ax			; segment address
		clr	cx			; counter
blockLoop:
		mov	si, cx			; index
		shl	si			; word-sized identifiers
		mov	ds:[si], cx		; position = value
		inc	cx
		cmp	cx, bp
		jb	blockLoop
	;
	;  Now set the selections
	;	
		mov	cx, ds
		clr	dx			; cx:dx = buffer

		push	bp			; save num selections
		GetResourceHandleNS	TokenDBViewer, bx
		mov	si, offset	TokenDBViewer
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS
		call	ObjMessage
	
		pop	dx			; dx = num selections
		GetResourceHandleNS	TokenDBNumSelected, bx
		mov	si, offset	TokenDBNumSelected
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clrdw	cxbp
		call	ObjMessage

		pop	bx			; restore block handle
		call	MemFree			; free the selection block
done:
		ret
IconSelectAllTokens	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconSelectTokenFromList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the "selected" genValue in the token.db dialog.

CALLED BY:	MSG_ICON_SELECT_TOKEN_FROM_LIST

PASS:		cx = selection

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- count the selections, and put them in the "selected" box

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconSelectTokenFromList	method dynamic IconProcessClass,
					MSG_ICON_SELECT_TOKEN_FROM_LIST
	;
	;  See if the item was selected or unselected
	;
		GetResourceHandleNS	TokenDBViewer, bx
		mov	si, offset	TokenDBViewer
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_NUM_SELECTIONS
		call	ObjMessage

		mov	dx, ax				; num selections
		GetResourceHandleNS	TokenDBNumSelected, bx
		mov	si, offset	TokenDBNumSelected
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clrdw	cxbp
		call	ObjMessage

		ret
IconSelectTokenFromList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconTokenListGetItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	TokenDBViewer wants another token's moniker.

CALLED BY:	MSG_ICON_TOKEN_LIST_GET_ITEM_MONIKER

PASS: 		bp = item number

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- get the display scheme
	- pull out the best moniker available from the token.db
	  for the passed item/position.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconTokenListGetItemMoniker	method dynamic IconProcessClass,
					MSG_ICON_TOKEN_LIST_GET_ITEM_MONIKER
	;	
	;  Get the current DisplayType
	;
		push	bp			; save item number
		GetResourceHandleNS	IconApp, bx
		mov	si, offset	IconApp
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
		call	ObjMessage

		mov	cl, ah			; DisplayType

		pop	bx			; bx = item number
		mov	ax, (VMS_ICON shl offset VMSF_STYLE) or \
				mask VMSF_GSTRING
		call	GetTokenMonikerByPosition	; ^lcx:dx = moniker
		jc	done			; no token
		push	cx			; save moniker block

		mov	bp, bx			; bp = item number
		GetResourceHandleNS	TokenDBViewer, bx
		mov	si, offset	TokenDBViewer
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
		mov	di, mask MF_CALL
		call	ObjMessage

		pop	bx			; restore moniker block
		call	MemFree			; free the moniker	
done:
		ret
IconTokenListGetItemMoniker	endm

TokenCode	ends

ChangeIconCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconGetAppToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shows user the current moniker for selected application.

CALLED BY:	MSG_ICON_GET_APP_TOKEN

PASS:		ds	= dgroup
		bp	= GenFileSelectorEntryFlags

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	This routine is called when the user selects a file in
	the GenFileSelector.  We look up the token for that
	geode in the token database, and if it has one, we get
	the appropriate moniker and display it in the dialog.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconGetAppToken	method dynamic IconProcessClass, 
					MSG_ICON_GET_APP_TOKEN
		.enter

		andnf	bp, mask GFSEF_TYPE	; isolate type enum
		cmp	bp, GFSET_FILE
		LONG	jne	done		; don't deal with dirs

		call	GetTokenCharsFromFileSelector
		call	UpdateDialogMoniker
done:		
		.leave
		ret
IconGetAppToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDialogMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the moniker in the dialog.

CALLED BY:	UTILITY

PASS:		ax:cx:si = token
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/20/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDialogMoniker	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Get the moniker out of the database.
	;
		push	ax, cx, si
		GetResourceHandleNS	IconApp, bx
		mov	si, offset	IconApp
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
		call	ObjMessage		; ah = DisplayType
		mov	dh, ah

		mov	ax, LMEM_TYPE_GENERAL
		clr	cx			; block header size
		call	MemAllocLMem		; returns bx = block handle
		mov	cx, bx			; cx = handle
		
		pop	ax, bx, si		; six bytes of token

		push	cx			; save block handle
		mov	di, (VMS_ICON shl offset VMSF_STYLE) or \
				mask VMSF_GSTRING
		push	di			; VisMonikerSearchFlags
		clr	di			; create chunk in cx block
		push	di			; pass unused buffer size
		call	TokenLoadMoniker	; di <- chunk handle
		pop	cx			; ^lcx:di = moniker
	;
	;  Replace the CurrentTokenGlyph's moniker
	;
		tst	di
		jz	noMoniker		; oops
		mov	dx, di			; ^lcx:dx = moniker
		push	cx			; save moniker block
		GetResourceHandleNS	CurrentTokenGlyph, bx
		mov	si, offset	CurrentTokenGlyph
		mov	di, mask MF_CALL
		mov	bp, VUM_NOW
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		call	ObjMessage
	;
	;  Now nuke the moniker block.
	;
		pop	bx
		call	MemFree
		jmp	short	done
noMoniker:
		sub	sp, size ReplaceVisMonikerFrame
		mov	bp, sp
		mov	dx, size ReplaceVisMonikerFrame
		mov	ss:[bp].RVMF_dataType, VMDT_NULL
		mov	ss:[bp].RVMF_updateMode, VUM_NOW

		GetResourceHandleNS	CurrentTokenGlyph, bx
		mov	si, offset	CurrentTokenGlyph
		mov	di, mask MF_STACK
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		call	ObjMessage

		add	sp, size ReplaceVisMonikerFrame
done:
		.leave
		ret
UpdateDialogMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerChangeAppToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the app's token.db entry with the current icon.

CALLED BY:	MSG_DB_VIEWER_CHANGE_APP_TOKEN

PASS: 		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		es	= dgroup
		
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- create a moniker list from the current icon
	- get the token chars for the selected Geode
	- call TokenDefineToken with the moniker list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerChangeAppToken	method dynamic DBViewerClass,
				MSG_DB_VIEWER_CHANGE_APP_TOKEN
		uses	ax, cx, dx, bp
		.enter

		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		LONG	je	done
	;
	;  If the icon's dirty, see if they want to save it.
	;
		call	CheckIconDirtyAndDealWithIt
		LONG	jc	done

		call	IconMarkBusy
	;
	;  Find out how many formats there are in the icon.
	;
		push	ds:[LMBH_handle]
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle		
		call	IdGetFormatCount	; bx = count
		push	bx			; save format count
	;
	;  Allocate a chunk with that many VisMonikerListEntry structures.
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		call	MemAllocLMem		; bx = block
		call	MemLock
		mov	ds, ax			; ds = block
		mov	cx, size VisMonikerListEntry
		pop	ax			; ax = format count
		mul	cx			; ax = block size
		mov_tr	cx, ax
		clr	al			; flags
		call	LMemAlloc		; ^lbx:ax = moniker list
		call	MemUnlock
	;
	;  For each format, make a moniker out of it and store the
	;  VisMonikerListEntryType and actual moniker in the list entry.
	;
		pop	cx			; DBViewer block handle
		xchg	bx, cx
		call	MemDerefDS		; *ds:si = DBViewer
		mov	bx, cx			; bx = moniker list block
		call	FillInMonikerList
		mov_tr	dx, ax			; ^lbx:dx = moniker list
		push	bx			; save block handle
	;
	;  Set the moniker list as the entry (in token database) for geode.
	;
		call	GetUserTokenChars
		jcxz	noChars
		push	ax, bx, si		; save token chars
		xchg	bx, cx			; ax:bx:si = token chars
						; ^lcx:dx = moniker list
		clr	bp			; TokenFlags
		call	TokenDefineToken

		pop	ax, bx, si		; restore token chars
		call	UpdateDialogMoniker
	;
	;  Notify user of the change.
	;
		mov	si, offset ChangedAppIconText
		call	DisplayNotification
noChars:
	;
	;  Nuke the handle of the moniker list.
	;
		pop	bx
		call	MemFree

		call	IconMarkNotBusy
done:
		.leave
		ret
DBViewerChangeAppToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetUserTokenChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns token characters specified by dialog ui.

CALLED BY:	DBViewerChangeAppToken, IconResetAppToken

PASS:		nothing

RETURN:		ax:cx:si = GeodeToken

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/ 3/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetUserTokenChars	proc	near
		uses	bx, dx, di, bp
		.enter
	;
	;  See whether the user wants to use the file selector or the
	;  token-chars text & genvalue.
	;
		GetResourceHandleNS	ChangeIconSourceSelector, bx
		mov	si, offset	ChangeIconSourceSelector
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
	;
	;  Call the appropriate handler.
	;
EC <		cmp	ax, ChangeIconSourceType			>
EC <		ERROR_AE INVALID_CHANGE_ICON_SOURCE_TYPE		>
		mov_tr	bx, ax
		mov	bx, cs:[sourceTable][bx]
		call	bx

		.leave
		ret

sourceTable	word \
		offset	GetTokenCharsFromFileSelector,
		offset	GetTokenCharsFromTokenGroup

GetUserTokenChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTokenCharsFromFileSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the token chars for the selected geode.

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		ax:cx:si	= token chars

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/11/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTokenCharsFromFileSelector	proc	near
		uses	bx,dx,di,bp,ds
		.enter
	;
	;  Get the selection from the file selector.
	;
		sub	sp, (size PathName + size FileLongName)
		mov	cx, ss
		mov	dx, sp			; cx:dx = buffer for name
		sub	sp, (size GeodeToken)
		GetResourceHandleNS	ChangeIconFileSelector, bx
		mov	si, offset	ChangeIconFileSelector
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
		call	ObjMessage		; cx:dx = path
	;
	;  Get the extended attributes (FEA_TOKEN) from the file.
	;
		push	dx			; save path
		call	FilePushDir
		mov	bx, ax
		GetResourceSegmentNS	dgroup, ds
		mov	dx, offset ds:rootString	; ds:dx = "\\",0
		call	FileSetCurrentPath
		pop	dx			; restore path

		mov	ax, FEA_TOKEN
		segmov	es, ss, di
		mov	di, sp			; es:di = buffer for token
		mov	cx, size GeodeToken
		call	FileGetPathExtAttributes

		call	FilePopDir
	;
	;  Move the token chars into ax:cx:si
	;
		mov	bp, sp			; ss:bp = GeodeToken
		mov	ax, {word}ss:[bp].GT_chars
		mov	cx, {word}ss:[bp].GT_chars+2
		mov	si, {word}ss:[bp].GT_manufID
		add	sp, (size GeodeToken + size PathName \
					     + size FileLongName)
		.leave
		ret
GetTokenCharsFromFileSelector	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTokenCharsFromTokenGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns token characters from text object & GenValue

CALLED BY:	utility

PASS:		nothing

RETURN:		ax:cx:si = GeodeToken

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/ 3/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTokenCharsFromTokenGroup	proc	near
		uses	bx,dx,di,bp
		.enter
	;
	;  Get the characters.
	;
		sub	sp, size GeodeToken
		mov	dx, ss
		mov	bp, sp				; dx.bp = buffer
		
		GetResourceHandleNS	TokenCharsText, bx
		mov	si, offset	TokenCharsText
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage			; cx = string length
	;
	; Get the manufacturer ID.
	;
		GetResourceHandleNS	ManufIDValue, bx
		mov	si, offset	ManufIDValue
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjMessage			; dx = integer value
	;
	;  Put the token in ax:cx:si
	;
		mov	bp, sp				; ss:bp = token chars
		mov	ax, {word}ss:[bp].GT_chars
		mov	cx, {word}ss:[bp].GT_chars+2
		mov	si, dx				; manufacturer ID

		add	sp, size GeodeToken

		.leave
		ret
GetTokenCharsFromTokenGroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillInMonikerList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates monikers from each of the icon's formats.

CALLED BY:	DBViewerChangeAppToken

PASS:		*ds:si	= DBViewer object
		^lbx:ax = chunk for moniker list (already created)

RETURN:		^lbx:ax = list (initialized)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

  Don't add the format if it's larger than 64K.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/11/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillInMonikerList	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		
		monikerBlock	local	hptr	push	bx
		monikerChunk	local	word	push	ax
		
		.enter

		push	bp				; locals
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bp, ds:[di].GDI_fileHandle
		mov	ax, ds:[di].DBVI_currentIcon
		call	IdGetFormatCount		; bx = count
		pop	bp				; locals
		mov	cx, bx				; cx = #formats
		clc					; no formats = no error
		jcxz	done
		mov	bx, monikerBlock
		clr	si				; offset into list
	;
	;  Loop through the formats, creating chunks for them in the
	;  passed block, saving the moniker optrs.
	;
formatLoop:
	;
	;  Get the next format, make it a moniker and store it in list.
	;
		dec	cx				; 0-indexed formats
		mov	ax, cx
		call	MakeMonikerFromFormat		; ^lbx:dx = moniker
		jc	done
							; ax = IF_type
		push	cx				; save counter
		mov_tr	cx, ax				; cx = IF_type
		mov	ax, monikerChunk		; ax = monikerlist
		call	StoreMonikerInList
		pop	cx				; restore counter
		add	si, size VisMonikerListEntry	; point to next
		inc	cx				; decremented at top
		loop	formatLoop
		clc					; no error
done:
		.leave
		ret
FillInMonikerList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeMonikerFromFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a vis-moniker given a format number and a block.

CALLED BY:	FillInMonikerList

PASS:		ds:di	= DBViewerInstance
		ax	= format number
		bx	= block to create moniker in

RETURN:		^lbx:dx = moniker
		ax	= IF_type
		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/11/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeMonikerFromFormat	proc	near
		class	DBViewerClass
		uses	bx,cx,si,di,bp
		.enter

		push	bx				; passed block
		mov	bx, ax
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormat			; ^vcx:dx = format
		push	cx, dx				; save bitmap
		call	IdGetFormatParameters		; cx = IF_type
		mov	di, cx
		pop	cx, dx				; restore bitmap
		pop	bx				; passed block
		
		call	JohnCreateMonikerFromBitmap	; ^lcx:dx = moniker
		jc	done
		mov_tr	ax, di				; return IF_type
		clc
done:
		.leave
		ret
MakeMonikerFromFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreMonikerInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores passed moniker in passed list (must be in same block).

CALLED BY:	FillInMonikerList

PASS:		^lbx:ax = moniker list
		^lbx:dx = moniker
		cx	= VisMonikerListEntryType for the moniker
		si	= offset of VisMonikerListEntry in ax chunk

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Well, there's only one trick--we have to set the 
	VMLET_MONIKER_LIST bit in the VisMonikerListEntryType passed
	in cx.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/11/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreMonikerInList	proc	near
		uses	ax,cx,dx,di,bp,es
		.enter

		mov	di, ax			; ^lbx:di = moniker list

		ornf	cl, mask VMLET_MONIKER_LIST

		call	MemLock
		mov	es, ax
		mov	bp, es:[di]		; es:bp = moniker list
		mov	es:[bp][si].VMLE_moniker.handle, bx
		mov	es:[bp][si].VMLE_moniker.chunk, dx
		mov	es:[bp][si].VMLE_type, cx
		call	MemUnlock

		.leave
		ret
StoreMonikerInList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconTextUserModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User types in a token character.

CALLED BY:	MSG_META_TEXT_USER_MODIFIED

PASS:		*ds:si	= IconProcessClass object
		ds:di	= IconProcessClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconTextUserModified	method dynamic IconProcessClass, 
					MSG_META_TEXT_USER_MODIFIED
		uses	ax, cx, dx, bp
		.enter
	;
	;  Mark the text as not-user modified so we'll get this
	;  message when they type another character.
	;
		GetResourceHandleNS	TokenCharsText, bx
		mov	si, offset	TokenCharsText
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
		call	ObjMessage
	;
	;  Call the common routine for updating stuff.
	;
		call	GetTokenCharsFromTokenGroup
		call	UpdateDialogMoniker

		.leave
		ret
IconTextUserModified	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TokenValueSetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User changed the manufacturer ID in the change-icon dialog.

CALLED BY:	MSG_GEN_VALUE_SET_VALUE

PASS:		*ds:si	= TokenValueClass object
		ds:di	= TokenValueClass instance data
		ax	= the message
		dx	= the integer value

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TokenValueSetValue	method dynamic TokenValueClass, 
					MSG_GEN_VALUE_SET_VALUE
		uses	ax, cx, dx, bp
		.enter
	;
	;  Let the superclass do its little thing.
	;
		mov	di, offset TokenValueClass
		call	ObjCallSuperNoLock
	;
	;  Call the common routine.
	;
		call	GetTokenCharsFromTokenGroup	; ax:cx:si = token
		call	UpdateDialogMoniker
		
		.leave
		ret
TokenValueSetValue	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerInitExportTokenDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the moniker of the change-icon glyph.

CALLED BY:	MSG_DB_VIEWER_INIT_CHANGE_ICON_DIALOG

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Don't do this if the icon is > 64K.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerInitExportTokenDialog	method dynamic DBViewerClass, 
					MSG_DB_VIEWER_INIT_CHANGE_ICON_DIALOG
		uses	ax, cx, dx, bp
		.enter
	;
	;  See if there's an icon being edited.
	;
		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		je	noMoniker
	;
	;  Create a moniker using the first format in the list.
	;
		push	bp
		mov	bp, ds:[di].GDI_fileHandle
		mov	ax, ds:[di].DBVI_currentIcon
		clr	bx				; first format
		call	IdGetFormat			; ^vcx:dx = bitmap
		pop	bp
	;
	;  Create the moniker.
	;
		clr	bx				; create new block
		call	JohnCreateMonikerFromBitmap	; ^lcx:dx = moniker
		jc	noMoniker			; don't display
	;
	;  Now replace the moniker.
	;
		push	cx, bp			; save block handle
		GetResourceHandleNS	ChangeTokenGlyph, bx
		mov	si, offset	ChangeTokenGlyph
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		mov	bp, VUM_NOW
		call	ObjMessage
		
		pop	bx, bp			; restore block handle
		call	MemFree
		jmp	done
noMoniker:
	;
	;  Just clear out the glyph.
	;
		push	bp				; locals
		sub	sp, size ReplaceVisMonikerFrame
		mov	bp, sp
		mov	dx, size ReplaceVisMonikerFrame
		mov	ss:[bp].RVMF_dataType, VMDT_NULL
		mov	ss:[bp].RVMF_updateMode, VUM_NOW

		GetResourceHandleNS	ChangeTokenGlyph, bx
		mov	si, offset	ChangeTokenGlyph
		mov	di, mask MF_STACK
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		call	ObjMessage

		add	sp, size ReplaceVisMonikerFrame
		pop	bp				; locals
done:
		.leave
		ret
DBViewerInitExportTokenDialog	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportValueGetValueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append a "%" onto the value.

CALLED BY:	MSG_GEN_VALUE_GET_VALUE_TEXT

PASS:		*ds:si	= ImportValueClass object
		ds:di	= ImportValueClass instance data
		cx:dx	= pointer to buffer to put text, must be at
			  least GEN_VALUE_MAX_TEXT_LEN bytes long.
		bp	= GenValueType

RETURN:		cx:dx	= buffer, filled in with the textual representation

DESTROYED:	nothing
		
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/25/93   	Initial version
	stevey	2/ 2/94   	used jwu's code for spacing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportValueGetValueText	method dynamic ImportValueClass, 
					MSG_GEN_VALUE_GET_VALUE_TEXT
		uses	ax, cx, dx, bp
		.enter
	;
	; Call the superclass.
	;	
		mov	di, offset ImportValueClass
		call	ObjCallSuperNoLock
	;
	; Add some spaces in the beginning of the string to pad it 
	; so that the text will look centered.
	;
		sub	sp, GEN_VALUE_MAX_TEXT_LEN
		segmov	es, ss, ax
		mov	di, sp				; es:di <-  our buffer
		push	es, di				; save our buffer
	;
	; Figure out how much padding we need and put them in the buffer.
	; Returns with ES:DI pointing to the end of the spaces in the buffer.
	;
		call	ImportValuePadText		
	;
	; Append the value text string to the spaces.  
	;
		mov	ds, cx
		mov	si, dx				; ds:si = value text str
		push	cx, dx				; save passed buffer
		LocalCopyString
		dec	di				; remove null term.
	;
	; Tack a "%" onto the string.
	;
		mov	ax, C_PERCENT
		LocalPutChar	esdi, ax
		mov	ax, C_NULL
		LocalPutChar	esdi, ax
	;
	; Now finally, put the whole string back into the passed buffer.
	;
		pop	es, di				; es:di <- passed buffer
		pop	ds, si				; ds:si <- our buffer
		LocalCopyString
		add	sp, GEN_VALUE_MAX_TEXT_LEN
		
		.leave
		ret
ImportValueGetValueText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportValuePadText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figures out how many spaces to pad the value text string
		with to center it.

CALLED BY:	ImportValueGetValueText

PASS:		*ds:si	= ImportValueClass object
		es:di	= buffer to put spaces in (GEN_VALUE_MAX_TEXT_LEN)
		
RETURN:		es:di	= position in buffer immediately after last space

DESTROYED:	ax, si  

PSEUDO CODE/STRATEGY:
		This is a hack to cause the text of a GenValue to be 
		centered.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 3/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IMPORT_VALUE_CHARS		equ	3
IMPORT_VALUE_PADDING_ESTIMATE	equ	22

ImportValuePadText	proc	near
		uses	cx, dx
		.enter
	;
	; Figure out the amount of space needed to the left of center for
	; the GenValue.
	;
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock		; cx <- width
	;
	; A hack for when this gets called before the object has been built:
	; just estimate how many spaces it will take.
	;
		jcxz	estimate
		shr	cx, 1				; divide by 2
	;
	; Find out the width of a space character.
	;
		push	di				; save buffer pointer
		
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock		; ^hbp <- gstate
		mov	di, bp				; di <- gstate handle

		mov	ax, C_SPACE
		call	GrCharWidth			; dx <- width 

		call	GrDestroyState
	;
	; Divide the amount of space to the left of center by the width
	; of a space character to determine the number of spaces needed.
	;
		mov_tr	ax, cx				; ax <- space to left
		div	dl				; al = # chars needed
		clr	ah				
	;
	; Insert the computed # of spaces into the buffer, taking into
	; account the characters in the value text string.
	;
		pop	di				; restore buffer pointer
		mov_tr	cx, ax				; cx <- # chars needed
		jcxz	done
		sub	cx, IMPORT_VALUE_CHARS		; cx <- # spaces to use
padLoop:
		mov	ax, C_SPACE
		LocalPutChar	esdi, ax
		loop	padLoop
done:	
		.leave
		ret
estimate:
		mov	cx, IMPORT_VALUE_PADDING_ESTIMATE
		jmp	short padLoop

ImportValuePadText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconResetAppToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the token from the database.

CALLED BY:	MSG_ICON_RESET_APP_TOKEN

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconResetAppToken	method dynamic IconProcessClass, 
					MSG_ICON_RESET_APP_TOKEN
		uses	ax, cx
		.enter
	;
	;  Get the token chars and remove the token.
	;
		call	GetUserTokenChars		; ax:cx:si = token
		mov	bx, cx
		call	TokenRemoveToken
	;
	;  Clear the current-icon glyph.
	;
		sub	sp, size ReplaceVisMonikerFrame
		mov	bp, sp
		mov	dx, size ReplaceVisMonikerFrame
		mov	ss:[bp].RVMF_dataType, VMDT_NULL
		mov	ss:[bp].RVMF_updateMode, VUM_NOW

		GetResourceHandleNS	CurrentTokenGlyph, bx
		mov	si, offset	CurrentTokenGlyph
		mov	di, mask MF_STACK
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		call	ObjMessage

		add	sp, size ReplaceVisMonikerFrame
	;
	;  Notify user of the change.
	;
		mov	si, offset RemovedTokenText
		call	DisplayNotification
		
		.leave
		ret
IconResetAppToken	endm


ChangeIconCode	ends

