COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Icon editor
FILE:		documentTransfer.asm

AUTHOR:		Steve Yegge, Apr  1, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/ 1/93		Initial revision

DESCRIPTION:

	This file contains routines for implementing clipboard support
	for the icon database.

	An icon database is not stored as a VM tree, for efficiency
	reasons.  Deleting blocks is made easier by the chunk-array
	structure actually used. See iconFile.def for more details.

	The clipboard format generated must be a VM tree.  To make
	the translation as simple as possible, the following data
	structure will be used for the clipboard:

		* The block passed to the clipboard will be a
		  VMChainTree, with VMCT_count = #icons being cut.
		  The handles stored after the VMChainTree struct
		  are handles to VMChainTrees, 1 per icon.

		* The VMChainTree for each icon is a block with
		  a VMChainTree struct followed by an IconHeader.
		  VMCT_count is set to the number of formats.
		  The handles for the format huge-arrays are
		  stored after this.

	$Id: documentTransfer.asm,v 1.1 97/04/04 16:06:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransferCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconUpdateEditControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send GWNT_SELECT_STATE_CHANGE

CALLED BY:	DBViewerNormalTransferItemChanged

PASS:		ah = BB_TRUE if cut & copy should be enabled
		     BB_FALSE otherwise
		bh = BB_TRUE if delete should be enabled; BB_FALSE otherwise
		bl = BB_TRUE if paste should be enabled; BB_FALSE otherwise

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	epw	2/16/93			Initial version
	stevey	4/17/93			stole from Image app

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconUpdateEditControl	proc	far
		uses	ax,bx,cx,dx,bp,si,di,es
		.enter

		call	UpdateEditControlUndo
	;
	; allocate state block
	;
		push	ax, bx			; save booleans
		mov	ax, size NotifySelectStateChange
		mov	cx, (mask HAF_LOCK shl 8) or mask HF_SHARABLE
		call	MemAlloc
	;
	; init state block
	;
		pop	cx, dx			; restore booleans
		mov	es, ax
		mov	es:[NSSC_selectionType], SDT_OTHER
		mov	es:[NSSC_clipboardableSelection], ch
		mov	es:[NSSC_selectAllAvailable], BB_TRUE
		mov	es:[NSSC_deleteableSelection], dh
		mov	es:[NSSC_pasteable], dl
		
		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount
	;		
	; record notification
	; 
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	bp, bx			; save data block
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_SELECT_STATE_CHANGE
		clr	bx			; no destination specified
		clr	si
		mov	di, mask MF_RECORD
		call	ObjMessage		; ^hdi = classed event
	;		
	; send message
	;
		mov	dx, size GCNListMessageParams
		sub	sp, dx
		mov	bx, bp			; bx = data block
		mov	bp, sp			; ss:bp = stack frame
		
		mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLMP_ID.GCNLT_type,  \
				GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
		mov	ss:[bp].GCNLMP_block, bx
		mov	ss:[bp].GCNLMP_event, di
		mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
		
		GetResourceHandleNS	IconApp, bx
		mov	si, offset	IconApp
		mov	di, mask MF_STACK
		mov	ax, MSG_META_GCN_LIST_SEND
		call	ObjMessage
		
		add	sp, size GCNListMessageParams

		.leave
		ret
IconUpdateEditControl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconQueryClipboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	determine whether the current clip is pasteable

CALLED BY:	IconUpdateEditControl

PASS:		nothing

RETURN:		bl - BB_TRUE if pasteable, BB_FALSE if not

DESTROYED:	bh

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	epw	2/17/93			Initial version
	stevey	4/17/93			stole from image app

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconQueryClipboard	proc	far
		uses	ax, cx, dx, bp
		.enter
		
		clr	bp
		call	ClipboardQueryItem	; bp <- # of formats
						; cx:dx <- owner of item
						; bx:ax <- VM addr of item
		tst	bp
		jnz	item_exists
		mov	cl, BB_FALSE
		jmp	done
		
item_exists:
		pushdw	bxax
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, CIF_ICON_LIST
		call	ClipboardRequestItemFormat	; ax:bp <- VM chain or 0
							; bx <- VM file
							; cx,dx - extra words
		mov	cl,BB_TRUE
		tst	ax
		popdw	bxax
		jnz	done
		mov	cl, BB_FALSE
		
done:
		call	ClipboardDoneWithItem

		mov	bx, cx
		.leave
		ret
IconQueryClipboard	endp


			

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerNotifyNormalTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The contents of the clipboard have changed; update edit menu.

CALLED BY:	MSG_META_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		ax	= the message

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerNotifyNormalTransferItemChanged	method dynamic DBViewerClass, 
			MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
		uses	ax
		.enter
	;
	;  See if the new format is pasteable.
	;
		call	IconQueryClipboard		; bl = paste boolean
	;
	;  See if we have any selections...
	;
		tst	ds:[di].DBVI_numSelected
		jz	noneSelected
	;
	;  Enable cut, copy & delete.
	;
		mov	ah, BB_TRUE
		mov	bh, ah
		jmp	short	update
noneSelected:
	;
	;  Disable cut, copy & delete.
	;
		mov	ah, BB_FALSE		; disable cut & copy
		mov	bh, ah			; disable delete
update:
	;
	;  Update the edit control triggers appropriately.
	;
		call	IconUpdateEditControl

		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerNotifyNormalTransferItemChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBViewer method for MSG_META_CLIPBOARD_CUT

CALLED BY:	MSG_META_CLIPBOARD_CUT

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		ax	= the message

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerCut	method dynamic DBViewerClass, 	MSG_META_CLIPBOARD_CUT
		uses	ax, cx, dx, bp
		.enter
	;
	;  Create transfer item and register it with clipboard.
	;
		call	CreateTransferFormatCommon	; ^vbx:ax = item
		jc	done

		clr	bp
		call	ClipboardRegisterItem
	;
	;  Delete the icons that were cut.
	;
		mov	ax, MSG_DB_VIEWER_DELETE_ICONS
		call	ObjCallInstanceNoLock
	;
	;  Enable the paste trigger, and disable cut, copy & delete.
	;
		mov	ah, BB_FALSE			; cut/copy
		mov	bh, ah				; delete
		mov	bl, BB_TRUE			; paste
		call	IconUpdateEditControl
done:		
		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerCut	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBViewer method for MSG_META_DELETE

CALLED BY:	MSG_META_DELETE

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerDelete	method dynamic DBViewerClass, 
					MSG_META_DELETE
		uses	ax, cx, dx, bp
		.enter
	;
	;  Delete the selections.
	;
		mov	ax, MSG_DB_VIEWER_DELETE_ICONS
		call	ObjCallInstanceNoLock
	;
	;  Update the clipboard (disable everything except "select all")
	;
		mov	ah, BB_FALSE
		mov	bh, ah
		mov	bl, ah
		call	IconUpdateEditControl

		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerDelete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerSelectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBViewer method for MSG_META_SELECT_ALL

CALLED BY:	MSG_META_SELECT_ALL

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerSelectAll	method dynamic DBViewerClass, 
					MSG_META_SELECT_ALL
		uses	ax, cx, dx, bp
		.enter
	;
	;  Send a MSG_VIS_ICON_SET_SELECTION to all children.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	ax, MSG_VIS_ICON_SET_SELECTION
		mov	dx, 1				; selecting
		call	VisSendToChildren
	;
	;  Enable cut, copy & delete on the edit menu, and perhaps
	;  paste as well.
	;
		call	IconQueryClipboard		; paste (in bl)

		mov	ah, BB_TRUE			; cut/copy
		mov	bh, ah				; delete

		call	IconUpdateEditControl
		
		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerSelectAll	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBViewer method for MSG_META_CLIPBOARD_COPY

CALLED BY:	MSG_META_CLIPBOARD_COPY

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		ax	= the message

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerCopy	method dynamic DBViewerClass, 	MSG_META_CLIPBOARD_COPY
		uses	ax, cx, dx, bp
		.enter
	;
	;  Create transfer item and register it with clipboard.
	;
		call	CreateTransferFormatCommon	; ^vbx:ax = item
		jc	done

		clr	bp				; flags
		call	ClipboardRegisterItem
	;
	;  Enable the paste trigger, and disable cut, copy & delete.
	;
		mov	ah, BB_FALSE			; cut/copy
		mov	bh, ah				; delete
		mov	bl, BB_TRUE			; paste
		call	IconUpdateEditControl
done:
		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DBViewer method for MSG_META_CLIPBOARD_PASTE

CALLED BY:	MSG_META_CLIPBOARD_PASTE

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		ax	= the message

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerPaste	method dynamic DBViewerClass,	MSG_META_CLIPBOARD_PASTE
		uses	ax, cx, dx, bp
		.enter
	;
	;  Call the common-code routine, which does everything.
	;
		clr	bp			; ClipboardItemFlags
		call	ViewerPasteCommon

		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerPasteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for DBViewerPaste and DBViewerEndMoveCopy

CALLED BY:	DBViewerPaste and DBViewerEndMoveCopy

PASS:		bp	= ClipboardItemFlags

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/24/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerPasteCommon	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		call	IconMarkBusy
	;
	;  Get the transfer item.
	;
		call	ClipboardQueryItem
		push	bx, ax			; save clipboard item
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, CIF_ICON_LIST
		call	ClipboardRequestItemFormat
	;
	;  Copy the vm chain into the icon database (temporarily).
	;
		mov	dx, ds:[di].GDI_fileHandle
		call	VMCopyVMChain		; ax = new vm chain
		mov_tr	dx, ax			; save it
	;
	;  Indicate we're done with the item in ^vbx:ax.
	;
		pop	bx, ax			; ^vbx:ax = requested item
		call	ClipboardDoneWithItem
	;
	;  Get the icons out of the transfer format and append
	;  them to the icon database.
	;
		mov_tr	ax, dx			; ax = copied chain
		call	GetIconsFromTransferFormat
	;
	;  Free the VM chain transfer format, as it's no longer needed.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].GDI_fileHandle
		call	VMFreeVMChain
	;
	;  Rescan the database viewer.
	;
		mov	ax, MSG_DB_VIEWER_RESCAN_DATABASE
		call	ObjCallInstanceNoLock

		call	IconMarkNotBusy

		.leave
		ret
ViewerPasteCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTransferFormatCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a transfer format for cut & copy.

CALLED BY:	DBViewerCut, DBViewerCopy

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewer instance

RETURN: 	carry clear if successful
		ax	= vm chain handle of clipboard item
		bx	= clipboard vm file
		carry set if unsuccessful
		ax	= 0

DESTROYED:	nothing  (ds fixed up)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTransferFormatCommon	proc	near
		class	DBViewerClass
		uses	cx,dx,si,di,bp
		.enter
	;
	;  Allocate a block to hold our selections.  This block
	;  will be freed by DBViewerCreateTransferFormat.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	ax, size word
		mov	cx, ds:[di].DBVI_numSelected
		mul	cx				; ax = block size
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	done
	;
	;  Get the selections into the block and unlock it.
	;
		push	bx				; block handle
		mov	cx, ax				; cx = segment
		clr	dx				; cx:dx = buffer
		mov	ax, MSG_DB_VIEWER_GET_MULTIPLE_SELECTIONS
		call	ObjCallInstanceNoLock
		pop	bx				; block handle
		call	MemUnlock
	;
	;  Get the clipboard file, and actually create the transfer format.
	;
		mov	dx, bx				; dx = selection block
		call	ClipboardGetClipboardFile
		mov	cx, bx				; cx = transfer file
		mov	ax, MSG_DB_VIEWER_CREATE_TRANSFER_FORMAT
		call	ObjCallInstanceNoLock		; ax = vm chain handle
		tst	ax
		jz	error

		clc
done:
		.leave
		ret
error:
		stc
		jmp	short	done
CreateTransferFormatCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerCreateTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a transfer format in the passed vm file.

CALLED BY:	MSG_DB_VIEWER_CREATE_TRANSFER_FORMAT

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		cx	= vm file handle
		dx	= handle of block containing icons to include
			  in the transfer file (each a word-size number).

RETURN:		ax	= newly created vm chain handle
		ax	= 0 if unsuccessful

DESTROYED:	dx (handle freed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerCreateTransferFormat	method dynamic DBViewerClass, 
					MSG_DB_VIEWER_CREATE_TRANSFER_FORMAT
		uses	cx,bp
		.enter

	;
	;  Create the GString part of the tree in the transfer file.
	;
		call	CreateGStringInTransferFile
		LONG	jc	done
		push	ax			; save vm chain handle

	;
	;  Create the IconList part of the tree in the transfer file.  This routine
	;  also frees the selection block passed in dx.
	;
		call	CreateIconListTreeInTransferFile	; ax = vm chain tree
		LONG	jc	done
		push	ax			; save vm chain handle
	;
	;  Allocate a block for the transfer structure
	;
		mov	bx, cx			; bx = transfer file
		clr	ax			; user id
		mov	cx, size ClipboardItemHeader
		call	VMAlloc			; ax = handle
		mov	dx, ax			; save transfer block
		call	VMLock
		mov	es, ax
	;
	;  Set up the header.
	;
		mov	es:[CIH_sourceID].chunk, si
		mov	bx, ds:[LMBH_handle]
		mov	es:[CIH_sourceID].handle, bx
		mov	es:[CIH_owner].chunk, si
		mov	es:[CIH_owner].handle, bx
		mov	es:[CIH_formatCount], 2

	;
	;  IconList format
	;
		mov	es:[CIH_formats][0].CIFI_format.CIFID_manufacturer, \
					MANUFACTURER_ID_GEOWORKS
		mov	es:[CIH_formats][0].CIFI_format.CIFID_type, \
					CIF_ICON_LIST
		clr	es:[CIH_formats][0].CIFI_vmChain.low	; no DB items
		pop	es:[CIH_formats][0].CIFI_vmChain.high	; vm chain
		clr	es:[CIH_formats][0].CIFI_extra1
		clr	es:[CIH_formats][0].CIFI_extra2

	;
	;  GString format
	;
		mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].CIFI_format.CIFID_manufacturer, \
					MANUFACTURER_ID_GEOWORKS
		mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].CIFI_format.CIFID_type, \
					CIF_GRAPHICS_STRING
		mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].CIFI_vmChain.low, 0	; no DB items
		pop	es:[CIH_formats][(size ClipboardItemFormatInfo)].CIFI_vmChain.high	; vm chain
		mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].CIFI_extra1, 0
		mov	es:[CIH_formats][(size ClipboardItemFormatInfo)].CIFI_extra2, 0

	;
	;  Copy the name.
	;
		push	ds
		segmov	ds, cs, di
		mov	di, offset CIH_name	; es:di = dest
		mov	si, offset unnamedIconListString
		mov	cx, length unnamedIconListString
		rep	movsb
		pop	ds

		call	VMUnlock
		mov_tr	ax, dx			; ax = vm chain
		clc
done:
		.leave
		ret
;
;  Need to make this localizeable.
;
unnamedIconListString	char	"Unnamed Icon List",0

DBViewerCreateTransferFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateIconListTreeInTransferFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the icon database into a vm tree in passed file.

CALLED BY:	DBViewerCreateTransferFormat

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewer instance
		cx	= vm file handle
		dx	= selection block handle

RETURN:		ax	= vm chain
		(carry set if error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

SIDE EFFECTS/IDEAS:

	Instead of using VMAlloc and VMLock, which nukes bp and
	makes local variables difficult to use, I'll use MemAlloc,
	MemLock, and then VMAttach to put the block in the file.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateIconListTreeInTransferFile	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di,bp,ds,es

		transferFile	local	word	push	cx
		selectionBlock	local	word	push	dx
		rootBlock	local	word
		numIcons	local	word
		
		.enter
	;
	;  Get the number of icons.  Allocate a memory block for
	;  the "directory"  (holding handles of each icon VMChainTree).
	;
		mov	ax, ds:[di].DBVI_numSelected
		mov	numIcons, ax
		shl	ax
		shl	ax			; need 4 bytes per entry
		add	ax, size VMChainTree	; add room for header
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc		; ax = root block segment
		LONG	jc	done
		mov	rootBlock, bx
	;
	;  Initialize the VMChainTree structure in the root block.
	;
		mov	es, ax
		mov	es:[VMCT_meta].VMCL_next, VM_CHAIN_TREE
		mov	es:[VMCT_offset], size VMChainTree
		mov	ax, numIcons
		mov	es:[VMCT_count], ax
		mov	di, size VMChainTree
	;
	;  Now, for each icon in the selection block,
	;  create a VMChainTree and save the handle in the list.
	;
		mov	bx, selectionBlock
		call	MemLock			; ax = segment
		mov	bx, ds:[LMBH_handle]	; ^lbx:si = DBViewer
		mov	ds, ax			; ds = selection block
		clr	cx			; counter
iconLoop:
		mov	dx, transferFile
		push	bx			; save DBViewer handle
		mov	bx, cx			; bx = counter
		shl	bx			; bx = word offset
		mov	ax, {word}ds:[bx]	; ax = icon
		pop	bx			; ^lbx:si = DBViewer
		call	CreateIconVMChain	; ax = chain

		mov	{word}es:[di+2], ax	; save VM chain
	;
	;  Add four bytes to di:  2 for the handle and 2 for the word
	;  (that's already zeroed out) saying there's no DB items.
	;
		add	di, 4			; es:di = next vm chain slot
		inc	cx
		cmp	cx, numIcons
		jb	iconLoop
	;
	;  Unlock the selection block and the rootBlock
	;
		mov	bx, selectionBlock
		call	MemFree
		mov	bx, rootBlock
		call	MemUnlock
	;
	;  Attach the root block to the transfer file.
	;
		mov	cx, bx			; cx = root block
		mov	bx, transferFile
		clr	ax			; allocate new vm block
		call	VMAttach		; ax <- block
		clc
done:
		.leave
		ret
CreateIconListTreeInTransferFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateGStringInTransferFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the first icon in the icon database into a gstring in
		the passed file.

CALLED BY:	DBViewerCreateTransferFormat

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewer instance
		cx	= vm file handle
		dx	= selection block handle

RETURN:		ax	= vm block handle
		(carry set if error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

SIDE EFFECTS/IDEAS:

	Instead of using VMAlloc and VMLock, which nukes bp and
	makes local variables difficult to use, I'll use MemAlloc,
	MemLock, and then VMAttach to put the block in the file.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateGStringInTransferFile		proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di,bp,ds,es

		transferFile	local	word	push	cx		
		gStringHandle	local	hptr
		gStringGState	local	hptr
		iconBlockHandle	local	word
		iconFormat	local	IconFormat
		
		.enter
	;
	;  Create a new GString in the vm file
	;
		push	di		; save address of instance data
		mov	bx, cx		; bx = vm file handle
		mov	cl, GST_VMEM
		call	GrCreateGString	; di = GString handle, si = VMBlock handle
		mov	ss:[gStringHandle], di
		mov	ss:[iconBlockHandle], si		; save VMBlock handle

	;
	;  Set the GString up for editing so we can draw the
	;  bitmap for the icon to it.
	;
		call	GrEditGString	; di = GState Handle of GString
		mov	ss:[gStringGState], di

	;
	;  Get IconFormat for first icon in database.
	;
		clr	ax			; ax = icon number
		clr	bx			; bx = format number
		mov	cx, ss
		lea	dx, ss:[iconFormat]     ; cx:dx = destination
		pop	di			; di = address of instance data
		push	bp		
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetIconFormat		; copy IconFormat
		LONG	jc	errorPopBP

	;
	;  Draw the icon's bitmap to the gstring
	;
		clr	ax, bx
		mov	dx, bp			; dx = VM FileHandle
		pop	bp
		mov	cx, ss:[iconFormat].IF_bitmap	; cx = bitmap VMBlockHandle
		mov	di, ss:[gStringGState]
		call	GrDrawHugeBitmap

	;
	;  Done!
	;
		call	GrEndGString
		mov	si, ss:[gStringHandle]
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString		; destroy GState

	;
	;  Return VMBlockHandle
	;
		mov	ax, ss:[iconBlockHandle]
		jmp	done

errorPopBP:		
		pop	bp
		mov	bx, ss:[transferFile]
		mov	ax, ss:[iconBlockHandle]
		call	VMFree
		stc

done:
		.leave
		ret
CreateGStringInTransferFile		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateIconVMChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the vm chain for the passed icon.

CALLED BY:	CreateTreeInTransferFile

PASS:		^lbx:si	= DBViewer
		dx	= transfer file
		ax	= icon number

RETURN:		ax	= vm chain tree block
		(carry set if error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	create a VMChainTree structure that will hold:
 	  the IconHeader structure for the icon
	  copies of the IconFormat structure for each format
	  a table of the vm chain handles for the format's bitmaps
	copy the IconHeader into the VMChainTree structure
	for each format:
	  copy it's IconFormat structure into the VMChainTree structure
 	  copy the bitmap vm chain trees into the transfer file
	  save the bitmap vm chain handle into the VMChainTree structure


SIDE EFFECTS/IDEAS:

	Similar to CreateTreeInTransferFile, we'll use MemAlloc to
	create the tree block, and VMAttach to put it in the file.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	lester	10/18/93  		modified to copy the IconFormat 
					structure for each format
	stevey	4/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateIconVMChain	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di,bp,ds,es

		transferFile	local	word	push	dx
		iconNumber	local	word	push	ax
		rootBlock	local	word
		formatCount	local	word
		counter		local	word
		formatsSize	local	word
		tableOffset	local	word

		.enter

		call	MemDerefDS		; *ds:si = DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
	;
	;  Get the number of formats in the icon.
	;
		push	bp			; save locals
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormatCount	; bx = count
		pop	bp			; restore locals
		mov	formatCount, bx
	;
	;  Allocate the chain tree block, which will hold:
	;	- the VMChainTree structure
	;	- the IconHeader for the icon
	; 	- copies of all the IconFormat structures
	;	- a table of vm chain handles (4 bytes each), 1 per format
	;

	; calculate the size of all the IconFormat structures
		mov	ax, (size IconFormat) ; one IconFormat
		mul	bx			; ax = ax*bx = size of all IconFormat's
						; dx is trashed
		mov	formatsSize, ax	
		
	; calculate size of the table of vm chain handles 
		shl	bx		; 4 bytes per format
		shl	bx		; bx = size of vm chain handle table
		
	; calculate total size of memory block to allocate
		add	ax, bx
		add	ax, (size VMChainTree + size IconHeader)

		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		LONG	jc	done
		mov	rootBlock, bx
	;
	;  Initialize the VMChainTree structure.
	;
		mov	es, ax			; es:0 = tree block
		mov	es:[VMCT_meta].VMCL_next, VM_CHAIN_TREE
		mov	ax, formatsSize
		add	ax, (size VMChainTree + size IconHeader)
		mov	es:[VMCT_offset], ax
		mov	tableOffset, ax		; used in the loop below
		mov	ax, formatCount
		mov	es:[VMCT_count], ax	; format count
	;
	;  Initialize the IconHeader.
	;
		mov	ax, iconNumber
		mov	dx, size VMChainTree
		mov	cx, es			; cx:dx = IconHeader
		push	bp
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetIconHeader
		pop	bp			; locals

	;
	;  For each format, copy the IconFormat block into the transfer file,
	;  copy the bitmap vm chain into the transfer file, and save the 
	;  bitmap vm chain handle in the tree block.
	;
		mov	si, di			; ds:si = DBViewerInstance
		mov	di, (size VMChainTree + size IconHeader)
		clr	counter
formatLoop:
	;
	;  Get next IconFormat from database.
	;

		push	bp			; save locals
		mov	ax, iconNumber
		mov	bx, counter		; bx = format number
		mov	cx, es
		mov	dx, di			; cx:dx = destination 
		mov	bp, ds:[si].GDI_fileHandle
		call	IdGetIconFormat		; copy IconFormat

	;
	;  Copy format bitmap vm chain to transfer file.
	;
		mov	bx, bp			; bx = source file
		mov	ax, es:[di].IF_bitmap	; ax = VM handle
		pop	bp			; restore locals
		mov	dx, transferFile	; dx = destination file
		push	bp			; save locals
		clr	bp			; bp = 0 -> VM chain
		call	VMCopyVMChain		; ax = new vm chain handle
		pop	bp			; restore locals
	;
	;  Save the format's bitmap vm chain handle in the rootBlock.
	;
		mov	bx, tableOffset
		mov	{word}es:[bx+2], ax
		add	bx, 4			; point to next table entry
		mov	tableOffset, bx		; save table pointer
		add	di, (size IconFormat)	; point to next format block
		inc	counter
		mov	cx, counter
		cmp	cx, formatCount
		jb	formatLoop
	;
	;  Unlock the rootBlock & attach it to transfer file.
	;
		mov	bx, rootBlock
		call	MemUnlock

		mov	cx, bx
		clr	ax			; allocate new block
		mov	bx, transferFile
		call	VMAttach		; ax = new block
		clc
done:		
		.leave
		ret
CreateIconVMChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetIconsFromTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieves the icons from the vm chain tree and appends
		them to the icon database.

CALLED BY:	DBViewerPaste

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		ax	= vm block handle of transfer chain

RETURN:		nothing
DESTROYED:	nothing (ds fixed up)

PSEUDO CODE/STRATEGY:

SIDE EFFECTS/IDEAS:

	We assume there's at least one icon in the vm chain tree.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetIconsFromTransferFormat	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	;  Get the number of icons from the VMChainTree header.
	;
		mov	bx, ds:[di].GDI_fileHandle
		call	VMLock			; bp = grabbed mem handle
		mov	es, ax			; es:0 = VMChainTree

		mov	cx, es:[VMCT_count]	; number of icons
	;
	;  For each icon, get the handle of it's vm chain and pass
	;  it to ExtractIconFromChainTree, to extract them.
	;
		mov	si, ds:[si]		; ds:[si] = instance
		mov	di, size VMChainTree	; es:di = icon list
iconLoop:
		mov	ax, {word}es:[di+2]	; ^vbx:ax = icon chain tree
		call	ExtractIconFromChainTree
		add	di, 4			; next icon
		loop	iconLoop
	;
	;  Unlock the icon vm chain tree.
	;
		call	VMUnlock

		.leave
		ret
GetIconsFromTransferFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractIconFromChainTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pulls the icon header & IconFormats & bitmaps from the 
		passed vm chain, and sticks them in the icon database.

CALLED BY:	GetIconsFromTransferFormat

PASS:		ds:si	= DBViewerInstance
		bx	= database file handle
		ax	= vm chain containing icon header & formats

RETURN:		nothing (icon extracted)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

SIDE EFFECTS/IDEAS:

	This routine assumes that the icon has at least one format.

	This routine assumes the vm chain tree has already been
	copied to the database file.
	
	We should check if the VMLock failed.

	I made two loops because it was much cleaner but it is also slower
	because the formats keep getting locked and unlocked.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	lester	10/18/93  		modified to copy the IconFormat 
					structure for each format
	stevey	4/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtractIconFromChainTree	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	;  Find out how many formats there are in the icon.
	;
		call	VMLock
		push	bp			; grabbed mem handle
		mov	es, ax
		mov	cx, es:[VMCT_count]	; number of formats
	;
	;  Create an icon in the database.
	;
		mov	bp, bx			; database file handle
		call	IdAddIcon		; ax = new icon's number
	;
	;  Copy the header (doesn't overwrite the format list handle).
	;
		mov	cx, es
		mov	dx, size VMChainTree	; cx:dx = source header
		call	IdSetIconHeader
	;
	;  For each format, copy the format's IconFormat structure into the
	;  new 	icon.
	;
		mov	di, (size VMChainTree + size IconHeader)
		clr	bx			; first format
iconFormatLoop: 
		; ax = new icon number
		; bx = format number
		; bp = source file
		mov	cx, es
		mov	dx, di			; cx:dx = IconFormat to copy
		call	IdSetIconFormat

		add	di, (size IconFormat)	; next IconFormat
		inc	bx			; next format number
		cmp	bx, es:[VMCT_count]
		jb	iconFormatLoop

	;
	;  For each format, copy the format`s bitmap vm chain and store the new
	;  vm chain handle in the IF_bitmap field
	;
		; di should point to the table of VM chain handles
EC <		cmp	di, es:[VMCT_offset]				>
EC <		ERROR_NE	BAD_DI_IN_EXTRACT_ICON_FROM_CHAIN	>

		clr	bx			; first format
		mov	cx, bp			; source & dest file are same
bitmapLoop:
		; ax = new icon number
		; bx = format number
		; cx = bp = vm file handle
		mov	dx, {word}es:[di+2]	; ^vcx:dx = bitmap
		call	IdSetFormat
		add	di, 4			; next bitmap vm handle
		inc	bx			; next format number
		cmp	bx, es:[VMCT_count]
		jb	bitmapLoop
	;
	;  Unlock the icon vm chain tree.
	;
		pop	bp			; grabbed mem handle
		call	VMUnlock

		.leave
		ret
ExtractIconFromChainTree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerNotifyClipboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the edit control based on number of selections.

CALLED BY:	GLOBAL

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerNotifyClipboard	method	dynamic	DBViewerClass,
				MSG_DB_VIEWER_NOTIFY_CLIPBOARD
		uses	ax, cx
		.enter

		call	IconQueryClipboard	; bl = paste boolean

		mov	cx, ds:[di].DBVI_numSelected
		jcxz	noneSelected
	;
	;  We've got at least one selection; enable cut, copy & delete.
	;
		mov	ah, BB_TRUE		; cut & copy
		jmp	short	notify
noneSelected:
	;
	;  Disable cut, copy & delete.
	;
		mov	ah, BB_FALSE
notify:
		mov	bh, ah			; delete (same as cut/copy)
		call	IconUpdateEditControl

		.leave
		ret
DBViewerNotifyClipboard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does all the stuff for gaining the target. :)

CALLED BY:	MSG_META_GAINED_TARGET_EXCL

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- Notify the edit control that we can't undo anything.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGainedTargetExcl	method dynamic DBViewerClass, 
					MSG_META_GAINED_TARGET_EXCL
		uses	ax, cx, dx, bp, es
		.enter

		call	UpdateEditControlUndo
		
		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerGainedTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateEditControlUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the edit control we can't undo anything.

CALLED BY:	IconUpdateEditControl, DBViewerGainedTargetExcl

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/21/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateEditControlUndo	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; allocate state block
	;
		mov	ax, size NotifyUndoStateChange
		mov	cx, (mask HAF_LOCK shl 8) or mask HF_SHARABLE
		call	MemAlloc
	;
	; init state block
	;
		mov	es, ax
		clrdw	es:[NUSC_undoTitle]
		mov	es:[NUSC_undoType], UD_NOT_UNDOABLE

		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount
	;		
	; record notification
	; 
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	bp, bx			; save data block
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_UNDO_STATE_CHANGE
		clr	bx			; no destination specified
		clr	si
		mov	di, mask MF_RECORD
		call	ObjMessage		; ^hdi = classed event
	;		
	; send message
	;
		mov	dx, size GCNListMessageParams
		sub	sp, dx
		mov	bx, bp			; bx = data block
		mov	bp, sp			; ss:bp = stack frame
		
		mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLMP_ID.GCNLT_type,  \
				GAGCNLT_EDIT_CONTROL_NOTIFY_UNDO_STATE_CHANGE
		mov	ss:[bp].GCNLMP_block, bx
		mov	ss:[bp].GCNLMP_event, di
		mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
		
		GetResourceHandleNS	IconApp, bx
		mov	si, offset	IconApp
		mov	di, mask MF_STACK
		mov	ax, MSG_META_GCN_LIST_SEND
		call	ObjMessage
		
		add	sp, size GCNListMessageParams

		.leave
		ret
UpdateEditControlUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts a quick-copy op.

CALLED BY:	MSG_META_START_MOVE_COPY

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		ax	= MouseReturnFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerStartMoveCopy	method dynamic DBViewerClass, 
					MSG_META_START_MOVE_COPY
		uses	ax, cx, dx, bp
		.enter

		call	IconMarkBusy
	;
	;  See if we have any selections...if not, make one.
	;
		tst	ds:[di].DBVI_numSelected
		jnz	gotSelection

		mov	ax, MSG_DB_VIEWER_SET_SINGLE_SELECTION
		clr	cx, bp				; first one?
		call	ObjCallInstanceNoLock
gotSelection:
	;
	;  Start the ball rolling...
	;
		push	si
		mov	si, mask CQTF_COPY_ONLY
		mov	ax, CQTF_COPY			; cursor
		call	ClipboardStartQuickTransfer
		pop	si
	;
	;  Create the transfer item
	;
		call	CreateTransferFormatCommon	; ^vbx:ax = format
		jc	done

		mov	bp, mask CIF_QUICK		; ClipboardItemFlags
		call	ClipboardRegisterItem
	;
	;  Provide feedback saying we can't accept the copy.
	;
		mov	ax, CQTF_CLEAR
		call	ClipboardSetQuickTransferFeedback

		mov	ax, MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER
		call	ObjCallInstanceNoLock
done:
	;
	;  Finish up.
	;
		call	IconMarkNotBusy
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
DBViewerStartMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User dumped a copy on us.

CALLED BY:	MSG_META_END_MOVE_COPY

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		cx, dx  = location (not used)
		bp high = UIFunctionsActive

RETURN:		ax	= MouseReturnFlags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerEndMoveCopy	method dynamic DBViewerClass, 
					MSG_META_END_MOVE_COPY
		uses	cx, dx, bp
		.enter
	;
	;  Do the paste thing.
	;
		mov	bp, mask CIF_QUICK		; ClipboardItemFlags
		call	ViewerPasteCommon
	;
	;  Finish up.
	;
		mov	bp, mask CQNF_COPY
		call	ClipboardEndQuickTransfer
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
DBViewerEndMoveCopy	endm

TransferCode	ends
