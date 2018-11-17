COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        ResEdit/Document
FILE:		documentClipboard.asm

AUTHOR:		Cassie Hartzog, Jan 11, 1993

ROUTINES:
	Name			Description
	----			-----------
	DocumentNotifyNormalTransferItemChanged	Contents of the clipboard have 
				changed, update the EditMenu. 
	DocumentNotifySelectStateChange	Sends out a GWNT_SELECT_STATE_CHANGE 
				type notification with the proper info 
	DocumentIsItemPasteable	Checks for a pasteable item on the clipboard. 
	DocumentGetEditMenuState	Determine the state of the Cut and Copy 
				EditMenu triggers, and the type of item. 
	SetEditMenuState	The target has transferred between original and 
				translation item, or the current chunk has 
				changed. Update the state of the EditMenu 
				triggers appropriately. 
	DocumentIsSomethingSelected	Determines if some text is selected, or 
				if the current chunk is graphics or bitmap, in 
				which case it is always considered selected. 
	CheckIfShortcutModified	Compare translation shortcut to original, to 
				see if it has been modified. 
	DocumentClipboardCopyCut	 
	CreateTransferItemCommon	Copy a graphics item to the clipboard. 
	BuildTransferBlockGStringFormat	Create a VMChain containig the gstring 
				that is to be put on the clipboard. 
	BuildGStringTransferBlock	Build a CIF_GRAPHICS_STRING data block. 
	BuildBitmapTransferBlock	Build a VMChain containing bitmap. 
	BuildTransferBlockBitmapFormat	Create a VMChain containing the gstring 
				that is to be put on the clipboard. 
	DocumentClipboardPaste	User has pasted something. 
	PasteGString		Paste a scrap into a gstring. 
	CheckGStringCompatibility	Check that gstring being pasted is the 
				same size as the original. 
	CopyGStringWithSizeAdjust	Copies the passed source gstring to the 
				destination gstring, but also adjusts the width 
				and height of the destination by filtering out 
				any GR_SET_GSTRING_BOUNDS opcodes. If the 
				filtered gstring still isn't the right size, 
				carry is returned set. Remedy for bug 28886. 
	CopyGStringWithFilter	Copies the source gstring to the destination 
				gstring, filtering op_codes specified by the 
				passed filter routine. Returns the width and 
				height of the filtered destination. 
	FilterSetBounds		Accepts all elements except 
				GR_SET_GSTRING_BOUNDS. 
	FilterAllButDrawBitmap	Rejects all opcodes except GR_DRAW_BITMAP. 
	DestroySourceAndDestGStrings	Destroys the passed source and 
				destination gstrings. Source's data is left. 
				Destination's data is killed. 
	PasteBitmap		paste a bitmap 
	CheckBitmapCompatibility	Check that bitmap being pasted is the 
				same size as the original. 
	CheckBitmapSizeCompatible	See if the gstring, stripped of its 
				GR_SET_GSTRING_BOUNDS, matches the expected 
				bitmap size. 
	GetBitmapFormat		Check that bitmap being pasted is of the same 
				size as the original. 
	HugeBitmapToSimpleBitmap	Converts a huge-bitmap (<64k) into a 
				regular bitmap in an item. 
	HugeBitmapGetSizeInBytes	Returns the total number of bytes (data 
				only) in the bitmap. 
	AllocAndLockItemAndGetMonikerType	Allocate and lock a new 
				translation item. Return moniker type of 
				original gstring. 
	GetGStringSize		Get the height and width of a gstring or bitmap 
	CopyGStringToVMChain	Copy a gstring to a temporary VMChain in the 
				document file. 
	LockCurrentItem		Lock the item, translation or original, for the 
				current element. 
	SendToTargetText	Sends a message on to the target text object. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	1/11/93		Initial revision


DESCRIPTION:
	Methods for implementing cut, copy and paste.

	$Id: documentClipboard.asm,v 1.1 97/04/04 17:14:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DocumentClipboardSegment	segment	resource

DocClip_ObjMessage_fixupDS	proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DocClip_ObjMessage_fixupDS	endp

DocClip_ObjMessage_call		proc	near
ForceRef DocClip_ObjMessage_call
	push	di
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di
	ret
DocClip_ObjMessage_call		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentNotifyNormalTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Contents of the clipboard have changed, update the
		EditMenu.

CALLED BY:	MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

PASS:		*ds:si	- document
		ds:di	- document

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	01/27/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentNotifyNormalTransferItemChanged	method	ResEditDocumentClass,
			MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

	call	DocumentGetEditMenuState	; cx <- SelectionDataType
						; bx <- cut/copy boolean 
						; al <- paste boolean

	FALL_THRU	DocumentNotifySelectStateChange

DocumentNotifyNormalTransferItemChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentNotifySelectStateChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out a GWNT_SELECT_STATE_CHANGE type notification
		with the proper info

CALLED BY:	

PASS:		al = BB_TRUE if paste should be enabled; BB_FALSE otherwise
		bl = BB_TRUE if copy should be enabled; BB_FALSE otherwise
		bh = BB_TRUE if cut should be enabled; BB_FALSE otherwise
		cx = SelectionDataType

RETURN:		nothing

DESTROYED:	ax,bx,cx,si,di,es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/17/93			stole from Image app
	cassie	10/8/93			stolen from Icon app

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentNotifySelectStateChange	proc far
	uses	dx,bp
	.enter

	;
	; alloc data block
	;
	push	ax, bx, cx
	mov	ax, size NotifySelectStateChange
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8
	call	MemAlloc
	jc	done
	mov	es, ax
	mov	ax, 1
	call	MemInitRefCount
	pop	ax, dx, cx	

	;
	; initialize block
	;
	mov	es:[NSSC_selectAllAvailable], BB_FALSE
	mov	es:[NSSC_selectionType], cx
	mov	es:[NSSC_clipboardableSelection], dl
	mov	es:[NSSC_deleteableSelection], dh
	mov	es:[NSSC_pasteable], al
	call	MemUnlock

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
	
	GetResourceHandleNS	ResEditApp, bx
	mov	si, offset	ResEditApp
	mov	di, mask MF_STACK
	mov	ax, MSG_META_GCN_LIST_SEND
	call	ObjMessage
		
	add	sp, size GCNListMessageParams
done:
	.leave
	ret
DocumentNotifySelectStateChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentIsItemPasteable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for a pasteable item on the clipboard.

CALLED BY:	EXT - utility
PASS:		ds:di - document
RETURN:		carry set if pasteable
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentIsItemPasteable		proc	near
	uses ax,bx,cx,dx,bp
	.enter

	cmp	ds:[di].REDI_curChunk, PA_NULL_ELEMENT
	stc
	je	exit				; nothing to paste into
	cmp	ds:[di].REDI_curTarget, ST_ORIGINAL 
	stc
	je	exit				; can't paste into original
	test	ds:[di].REDI_chunkType, mask CT_OBJECT
	clc
	je	exit				; can't paste into object

	clr	bp				; check normal item
	call	ClipboardQueryItem		; returns: bx:ax = header block
						;	   bp = format count
	tst	bp				; any normal item?
	stc
	jz	exit				; no normal item, done

	; check for format of current chunk type
	;
	mov	dx, CIF_TEXT
	test	ds:[di].REDI_chunkType, mask CT_TEXT
	jnz	testFormat
	mov	dx, CIF_GRAPHICS_STRING
	test	ds:[di].REDI_chunkType, CT_GRAPHICS
	stc
	jz	done
	
testFormat:
	mov	cx, MANUFACTURER_ID_GEOWORKS
	call	ClipboardTestItemFormat		; carry clear if such an item
	
done:
	;
	; tell the clipboard that we are finished with this item
	;	bx:ax = (Transfer VM File):(VM block handle) of item's
	;		header block
	;
	pushf
	call	ClipboardDoneWithItem		; pass bx:ax = header block
	popf

exit:
	.leave
	ret
DocumentIsItemPasteable		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentGetEditMenuState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the state of the Cut and Copy EditMenu triggers,
		and the type of item.

CALLED BY:	EXT - (DocumentNotifyNormalTransferItemChanged, 
			SetEditMenuState)
PASS:		*ds:si - document
		ds:di - document
RETURN:		cx - SelectionDataType
		al = BB_TRUE if paste should be enabled; BB_FALSE otherwise
		bl = BB_TRUE if copy should be enabled; BB_FALSE otherwise
		bh = BB_TRUE if cut should be enabled; BB_FALSE otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentGetEditMenuState		proc	near
	.enter

	mov	bl, BB_FALSE			; don't enable copy
	mov	bh, BB_FALSE			; don't enable cut
	call	DocumentIsSomethingSelected	
	jnc	nothingSelected
	mov	bl, BB_TRUE			; do enable copy
nothingSelected:
	;
	; check if Cut trigger should also be enabled
	;
 	cmp	ds:[di].REDI_curTarget, ST_ORIGINAL
	je	haveCutState			; don't enable if in OrigItem
	test	ds:[di].REDI_chunkType, CT_GRAPHICS
	jnz	haveCutState			; don't enable if graphics
	mov	bh, BB_TRUE

haveCutState:
	mov	al, BB_FALSE
	call	DocumentIsItemPasteable
	jc	havePasteState
	mov	al, BB_TRUE

havePasteState:
	;
	; get the selection type
	;
	mov	cx, SDT_GRAPHICS
	test	ds:[di].REDI_chunkType, CT_GRAPHICS
	jnz	haveType
	mov	cx, SDT_TEXT

haveType:
	.leave
	ret
DocumentGetEditMenuState		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEditMenuState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The target has transferred between original and translation
		item, or the current chunk has changed.  Update the state
		of the EditMenu triggers appropriately.

CALLED BY:	InitializeEdit, TransferTarget

PASS:		*ds:si	- document
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetEditMenuState	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	DerefDoc
	cmp	ds:[di].REDI_curChunk, PA_NULL_ELEMENT	; if no element, no
	je	done					;    enable.

	; If this is an original item, disable the undo trigger
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
 	cmp	ds:[di].REDI_curTarget, ST_ORIGINAL
	je	setUndoTrigger

	; If there is a transItem, enable the Undo trigger
	;
	mov	ax, MSG_GEN_SET_ENABLED
 	tst	ds:[di].REDI_transItem
	jnz	setUndoTrigger
	
	; Else if it is an object, check to see if the shortcut has changed.
	;
	test	ds:[di].REDI_chunkType, mask CT_OBJECT
	jz	notAnObject
	call	CheckIfShortcutModified			;zero clear if modified
	jnz	setUndoTrigger				;

notAnObject:	
	; The chunk is not marked dirty, has no transItem, or if it is an
	; object, its shortcut has not changed so disable the Undo trigger.
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED

setUndoTrigger:
	push	si
	GetResourceHandleNS	EditUndo, bx
	mov	si, offset EditUndo
	mov	dl, VUM_NOW
	call	DocClip_ObjMessage_fixupDS
	pop	si

	test	ds:[di].REDI_chunkType, mask CT_OBJECT
	jnz	done

	; 
	; Notify the EditMenu of the change.
	;
	call	DocumentGetEditMenuState
	call	DocumentNotifySelectStateChange

done:
	.leave
	ret

SetEditMenuState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentIsSomethingSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if some text is selected, or if the current
		chunk is graphics or bitmap, in which case it is 
		always considered selected.

CALLED BY:	SetEditMenuState
PASS:		ds:di	- document
RETURN:		carry set if something is selected
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentIsSomethingSelected		proc	near
	uses	ax,bx,cx,dx,si,bp
	.enter

	test	ds:[di].REDI_chunkType, CT_GRAPHICS
	stc
	jnz	done
	test	ds:[di].REDI_chunkType, mask CT_TEXT or mask CT_OBJECT
	clc
	jz	done

	movdw	bxsi, ds:[di].REDI_editText
	cmp	ds:[di].REDI_curTarget, ST_TRANSLATION
	je	getRange 
	mov	si, offset OrigText
getRange:
	sub	sp, size VisTextRange
	mov	bp, sp
	mov	dx, ss					;dx:bp <- VisTextRange
	mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
	call	DocClip_ObjMessage_fixupDS
	movdw	axbx, ss:[bp].VTR_start
	movdw	cxdx, ss:[bp].VTR_end
	add	sp, size VisTextRange

	cmpdw	axbx, cxdx
	stc
	jne	done
	clc
done:
	.leave
	ret
DocumentIsSomethingSelected		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfShortcutModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare translation shortcut to original, to see if
		it has been modified.

CALLED BY:	SetEditMenuState
PASS:		*ds:si	- document
		ds:di	- document
RETURN:		zero set if not modified
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfShortcutModified		proc	near
	uses	ax,bx,cx,si,di,ds
	.enter

EC <	call	AssertIsResEditDocument			>
	call	GetFileHandle
	mov	cx, ds:[di].REDI_kbdShortcut
	mov	ax, ds:[di].REDI_resourceGroup
	mov	di, ds:[di].REDI_origItem
	call	DBLock_DS
	mov	si, ds:[si]			;ds:si <- orig shortcut text

	sub	sp, SHORTCUT_BUFFER_SIZE
	mov	di, sp
	segmov	es, ss, bx	
	mov	ax, cx
	call	ShortcutToAscii			;es:di <- new shortcut text

	call	LocalCmpStrings
	lahf
	add	sp, SHORTCUT_BUFFER_SIZE
	sahf
	call	DBUnlock_DS

	.leave
	ret
CheckIfShortcutModified		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentClipboardCopyCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_CLIPBOARD_COPY, MSG_META_CLIPBOARD_CUT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentClipboardCopyCut		method  ResEditDocumentClass,
					MSG_META_CLIPBOARD_COPY,
					MSG_META_CLIPBOARD_CUT

	test	ds:[di].REDI_chunkType, mask CT_TEXT
	jz	notText
	call	SendToTargetText
	ret

notText:
EC<	cmp	ax, MSG_META_CLIPBOARD_CUT			>
EC<	ERROR_E	CANNOT_CUT_GRAPHICS				>
	clr	bp			; ClipboardItemFlags - normal copy
	FALL_THRU CreateTransferItemCommon

DocumentClipboardCopyCut		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTransferItemCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a graphics item to the clipboard.

CALLED BY:	DocumentClipboardCopy

PASS:		*ds:si 	- document
		ds:di	- document
		bp	- ClipboardItemFlags
			0 for normal items
			CIF_QUICK for quick-transfer item

RETURN:		carry set if error on normal copy (not quick copy)

DESTROYED:	ax,bx,cx,dx,bp,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/27/93		Initial version
	jmagasin 5/12/95	Added bitmap transfer format

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTransferItemCommon	proc	far
	uses	si
	.enter

	mov	bx, bp
	call	BuildTransferBlockGStringFormat	;ax:bp <- transfer VMChain
	push	ax, bp, cx, dx			;cx,dx <- gstring width,height
	call	BuildTransferBlockBitmapFormat	;ax:bp <- transfer VMChain
	push	ax, bp, cx, dx			;cx,dx <- bitmap width,height
	mov	dx, bx

	call	ClipboardGetClipboardFile	;^hbx <- transfer VM file
	mov	ax, 1111			;VM block ID
	mov	cx, size ClipboardItemHeader
	call	VMAlloc				;^hax <- VM block handle

	push	ax
	call	VMLock
	mov	es, ax				; es <- segment of VM block
	mov	cx, bp				;^hcx <- handle of VM block
	pop	ax

	mov	es:[CIH_flags], dx		; quick or normal flag
	mov	dx, ds:[LMBH_handle]
	movdw	es:[CIH_sourceID], dxsi
	movdw	es:[CIH_owner], dxsi
	;
	; fill in name for clipboard item
	;
SBCS <	mov	{byte}es:[CIH_name], 0		; no name		>
DBCS <	mov	{word}es:[CIH_name], 0		; no name		>
	;
	; fill in pointer to data block as the only format
	;
	mov	es:[CIH_formatCount], 2		;CIF_GRAPHICS_STRING
						; and CIF_BITMAP formats

	mov	es:[CIH_formats][0].CIFI_format.CIFID_manufacturer, \
						MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats][0].CIFI_format.CIFID_type, CIF_BITMAP
	pop	es:[CIH_formats][0].CIFI_extra2		;gstring height
	pop	es:[CIH_formats][0].CIFI_extra1		;gstring width
	pop	es:[CIH_formats][0].CIFI_vmChain.low
	pop	es:[CIH_formats][0].CIFI_vmChain.high

	mov	si, size ClipboardItemFormatInfo
	mov	es:[CIH_formats][si].CIFI_format.CIFID_manufacturer, \
						MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats][si].CIFI_format.CIFID_type, CIF_GRAPHICS_STRING
	pop	es:[CIH_formats][si].CIFI_extra2	;bitmap height
	pop	es:[CIH_formats][si].CIFI_extra1	;bitmap width
	pop	es:[CIH_formats][si].CIFI_vmChain.low
	pop	es:[CIH_formats][si].CIFI_vmChain.high

	push	es:[CIH_flags]
	mov	bp, cx
	call	VMDirty
	call	VMUnlock			; unlock header block

	;
	; now, actually put it on the clipboard
	; bx:ax = (Transfer VM File):(VM block handle) of header block
	;
	pop	bp
	call	ClipboardRegisterItem		; (return carry flag)

	.leave
	ret
CreateTransferItemCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildTransferBlockGStringFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a VMChain containig the gstring that is to
		be put on the clipboard.

CALLED BY:	
PASS:		*ds:si - document
		ds:di - document
RETURN:		ax:bp - VMChain
		cx, dx - width, height of gstring
DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildTransferBlockGStringFormat	proc	near
	.enter

	mov	al, ds:[di].REDI_chunkType
	test	al, mask CT_GSTRING	
	jz	buildBitmap
	call	BuildGStringTransferBlock
done:
	clr	bp				; ax:bp <- VMChain
	.leave
	ret

buildBitmap:
EC <	test	al, mask CT_BITMAP			>
EC <	ERROR_Z BAD_CHUNK_TYPE				>
	call	BuildBitmapTransferBlock
	jmp	done
BuildTransferBlockGStringFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildGStringTransferBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a CIF_GRAPHICS_STRING data block.

CALLED BY:	INTERNAL - BuildTransferBlockGStringFormat

PASS:		*ds:si	- document
		ds:di	- document
		al - chunk type

RETURN:		ax	- VM block containing gstring
		cx	- gstring width
		dx	- gstring height

DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildGStringTransferBlock		proc	near
	uses	bx,si,di,ds
	.enter

	;
	; lock the item
	;
EC <	test	al, mask CT_GSTRING			>
EC <	ERROR_Z BAD_CHUNK_TYPE				>
	call	LockCurrentItem			; ds:si <- item

	; if this is a moniker, the size of the gstring is cached 
	; otherwise, we have to figure it out ourselves
	;
	test	al, mask CT_MONIKER
	jz	notMoniker
	push	ds:[si].VM_width
	add	si, offset VM_data
	push	ds:[si].VMGS_height
	sub	si, offset VM_data

copy:
	;
	; now copy the gstring from the moniker structure into
	; a temporary VM block
	;
	call	CopyGStringToVMChain		; ax <- VMChain block
	call	DBUnlock_DS
	pop	cx, dx				;return gstring width, height

	.leave
	ret

notMoniker:
	; calculate the height and width of the gstring
	;
	call	GetGStringSize
	push	cx, dx
	jmp	copy

BuildGStringTransferBlock		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildBitmapTransferBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a VMChain containing bitmap.

CALLED BY:	INTERNAL - CopyBitmapCommon

PASS:		*ds:si	- document
		ds:di	- document

RETURN:		ax	- VM block containing gstring which draws bitmap
		cx	- gstring width
		dx	- gstring height

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildBitmapTransferBlock		proc	near
	uses	bx,si,di,ds
	.enter

	;
	; Lock the bitmap
	;
EC <	test	al, mask CT_BITMAP			>
EC <	ERROR_Z BAD_CHUNK_TYPE				>
	call	LockCurrentItem			; ds:si <- Bitmap

	; save the bitmap's dimensions
	;
	push	ds:[si].B_width, ds:[si].B_height

	;
	; create a gstring in the translation file to hold the bitmap
	;
	push	si
	call	ClipboardGetClipboardFile
	mov	cl, GST_VMEM
	call	GrCreateGString		; ^hdi = gstring
	mov	ax, si			; ax = VM block handle
	pop	si			; ds:si -> bitmap

	push	ax			; save block handle
	clr	ax, bx, dx		; draw at 0,0; no callback
	call	GrDrawBitmap		; draw bitmap to gstring

	call	GrEndGString
	cmp	ax, GSET_NO_ERROR

	mov	si, di
	clr	di			; no gstate
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString

	pop	ax			; ax <- VM block holding gstring

	call	DBUnlock_DS		; unlock the item

	pop	cx, dx

	.leave
	ret
BuildBitmapTransferBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildTransferBlockBitmapFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a VMChain containing the gstring that is to
		be put on the clipboard.

CALLED BY:	CreateTransferItemCommon
PASS:		*ds:si - document
		ds:di - document
		ax:bp - VMChain of gstring created by 
			BuildTransferBlockGStringFormat, which was
			called just before this
RETURN:		ax:bp - VMChain
		cx, dx - width, height of gstring
		ds	- fixed up
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We'll use the gstring created by
		BuildTransferBlockGStringFormat to create a bitmap-
		format VMChain.

		Why are we doing this?  By providing a bitmap-format
		to the clipboard, GeoDraw won't expand the grobject
		that gets created when the user pastes.  The problem
		was ResEdit used to use just the gstring format, which
		the grobj would expand pasted grobjects by a line
		width along all borders.  Consequently ResEdit would
		not permit the "too large" gstrings to be pasted back
		in from GeoDraw (or GeoWrite).


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildTransferBlockBitmapFormat	proc	near
clipboardFile	local	word
bitmapObjRsrc	local	hptr
bitmapWidth	local	word
bitmapHeight	local	word
gstring		local	hptr
	uses	si,di
	push	bx
	.enter

	; Get gstring info.
	;
	call	ClipboardGetClipboardFile	; bx<-vm file handle
	mov	ss:[clipboardFile], bx	
	mov	si, ax				; source VM block
	mov	cl, GST_VMEM
	call	GrLoadGString			; ^hsi <- gstring
	mov	ss:[gstring], si
	clr	di,dx
	call	GrGetGStringBounds
EC <	ERROR_C RESEDIT_INTERNAL_ERROR		>
	sub	cx, ax				; cx<-width
	sub	dx, bx				; dx<-height
	mov	ss:[bitmapWidth], cx		; (w/h same size for
	mov	ss:[bitmapHeight], dx		; bm as for gstring)

	; Create a VisBitmapClass object.
	;
	GetResourceHandleNS	BitmapTemplate, bx
	clr	ax, cx
	call	ObjDuplicateResource		; ^hbx <- duplicate block
	mov	si, offset BitmapForClipboard	; ^lbx:si <- bitmap object
	mov	ss:[bitmapObjRsrc], bx

	; Have the bitmap object create a bitmap, and get it.
	;
	mov	cx, ss:[clipboardFile]
	mov	ax, MSG_VIS_BITMAP_SET_VM_FILE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	push	bp
	mov	cx, ss:[bitmapWidth]
	mov	dx, ss:[bitmapHeight]
	mov	bp, ss:[gstring]		; ^hbp <- gstring
	mov	ax, MSG_VIS_BITMAP_CREATE_BITMAP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cx:dx =^vfile:block
	pop	bp

	; Copy the bitmap to a VMChain.
	;
	push	bp
	mov	bx, cx				; bitmap's src file
	mov	ax, dx
	clr	bp				; ax:bp = src VMChain
	mov	dx, bx				; (dest file = src file)
	call	VMCopyVMChain			; ax:bp <- dest VMChain
	mov	cx, bp				; ax:cx = dest VMChain
	pop	bp

	; Cleanup -- rub out the gstring and bitmap object
	;
	mov	si, ss:[gstring]
	clr	di				; no gstate
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	mov	bx, ss:[bitmapObjRsrc]
	call	ObjFreeDuplicate

	; Prepare for return
	;
	mov	bx, ss:[bitmapWidth]
	mov	dx, ss:[bitmapHeight]

	.leave
	mov_tr	bp, cx				; ax:bp = VMChain
	mov_tr	cx, bx				; cx:dx = width:height
	pop	bx

	ret
BuildTransferBlockBitmapFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentClipboardPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has pasted something.

CALLED BY:	UI - MSG_META_CLIPBOARD_PASTE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	Paste into selected item at cursor.
	Check that pasted item and selected item are of same type.
	If not, put up an error dialog.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentClipboardPaste		method dynamic ResEditDocumentClass,
						MSG_META_CLIPBOARD_PASTE

EC <	cmp	ds:[di].REDI_curTarget, ST_ORIGINAL		>
EC <	ERROR_E	ORIGINAL_ITEM_NOT_EDITABLE			>

	; is it quick transfer or not?
	;
;	mov	bp, mask CIF_QUICK
	clr	bp

	call	ClipboardQueryItem		; bp should be non-zero
	pushdw	bxax
	tst	bp		
	jz	done

	test	ds:[di].REDI_chunkType, mask CT_TEXT
	jz	notText

	; check if the transfer item is text or not
	;
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT
	call	ClipboardTestItemFormat
	mov	cx, EV_PASTE_TEXT_WRONG_FORMAT
	LONG	jc	error

	; it's text, so pass the paste message on to EditText
	;
	mov	ax, MSG_META_CLIPBOARD_PASTE
	call	SendToTargetText
	
done:
	popdw	bxax
	call	ClipboardDoneWithItem
	ret

notText:
	mov	dl, ds:[di].REDI_chunkType
	mov	di, offset PasteGString
	test	dl, mask CT_GSTRING
	jnz	getFormat
EC<	test	dl, mask CT_BITMAP			>
EC<	ERROR_Z BAD_CHUNK_TYPE				>
	mov	di, offset PasteBitmap

getFormat:
	;
	; check if there is a gstring transfer 
	; pass: bx:ax - transfer item header (returned by ClipboardQueryItem)
	; this call returns the transfer item:
	;	bx - file handle of transfer item
	;	ax:bp - VM chain (0 if none)
	;	cx - width 
	;	dx - height
	;
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardRequestItemFormat
	tst	ax
	jnz	replaceGraphic
	mov	cx, EV_PASTE_GRAPHICS_WRONG_FORMAT
	jmp	error				; no transfer item of format


	; replace the old graphic with the new graphic
	;
replaceGraphic:
	call	di
	jc	errorAX

	push	ds
	mov	dx, ax
	DerefDoc
	mov	ds:[di].REDI_transItem, dx

	call	GetFileHandle			;^hbx <- trans file
	mov	bp, ds:[di].REDI_resourceGroup
	mov	ax, ds:[di].REDI_curChunk
	call	DerefElement			; ds:di <- current element

	xchg	dx, ds:[di].RAE_data.RAD_transItem
	call	DBDirty_DS
	call	DBUnlock_DS

	tst	dx
	jz	noOldTransItem
	mov	ax, bp
	mov	di, dx				; ax:di <- old trans item
	call	DBFree

noOldTransItem:
	pop	ds
	call	DocumentRedrawCurrentChunk
	;
	; now enable EditUndo trigger
	;
	GetResourceHandleNS	EditUndo, bx
	mov	si, offset EditUndo
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	DocClip_ObjMessage_fixupDS
	jmp	done

errorAX:
	mov_tr	cx, ax	
error:
	mov	ax, MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE
	call	ObjCallInstanceNoLock
	jmp	done

DocumentClipboardPaste		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Paste a scrap into a gstring.

CALLED BY:	DocumentClipboardPaste

PASS:		*ds:si - document instance data
		^hbx  - transfer file
		ax:bp - transfer item header (returned by ClipboardQueryItem)
 		cx, dx - gstring width, height

RETURN:		carry set if error
			ax - ErrorValue
		carry clear if successful
			ax - new item

DESTROYED:	bx, cx, dx, bp, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Load the transfer item from the clipboard into a gstring.
	Copy the gstring into another gstring, putting the data in 
	  a chunk in a local resource.
	Destroy the original gstring, leaving its data.
	Lock the copied gstring, get the chunk's size.
	Allocate a DBItem and copy the gstring data into the
	  DBItem, leaving room for VisMoniker if it is CT_MONIKER.
	Destroy the copied gstring, killing its data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteGString	proc near
document	local	optr	push ds:[LMBH_handle], si
gstringChunk	local	lptr
chunkType	local	byte
newItem		local	word
gswidth		local	word
gsheight	local	word
.warn -unref_local
oldWidth	local	word
oldHeight	local	word
.warn @unref_local
badSize		local	word	;if the grobj made the gstring
				;too big by adding "set_bounds," 
				;we'll try to shrink it
				;back down to size (see bug 28886)
	.enter

	mov	ss:[badSize], 0
	mov	ss:[gswidth], cx
	mov	ss:[gsheight], dx
	call	CheckGStringCompatibility
	jnc	sizeOK
	mov	ss:[badSize], 1			;size too big or small
sizeOK:

	DerefDoc
	mov	cl, ds:[di].REDI_chunkType
	mov	ss:[chunkType], cl

	; load the gstring to be pasted
	;
	mov_tr	si, ax			; si <- vmem block handle of string
	mov	cl, GST_VMEM
	call	GrLoadGString		; ^hsi = source GString 

	; Create destination GString in DummyResource
	;
	GetResourceHandleNS	DummyResource, bx
	push	si			;save source GString handle
	mov	cl, GST_CHUNK		
	call	GrCreateGString		;^hdi <- new gstring to draw to
	mov	ss:[gstringChunk], si	;^hsi <- chunk holding gstring
	pop	si

	; Copy source GString to destination GString
	;
	tst	ss:[badSize]
	jz	regularCopy
	call	CopyGStringWithSizeAdjust
	LONG	jc	sizeMismatch
	jmp	endGString
regularCopy:
	clr	dx			;no control flags
	call	GrCopyGString	
	cmp	dx, GSRT_COMPLETE
endGString:
	call	GrEndGString		;End the gstring	
EC<	cmp	ax, GSET_NO_ERROR				>

	; Destroy the source gstring, leaving its data.
	;
	push	di
	mov	dl, GSKT_LEAVE_DATA
	clr	di			; no gstate
	call	GrDestroyGString	
	pop	dx			; ^hdx <- destination gstring

	; lock the copied gstring and get its size
	;
	call	MemLock
	mov	ds, ax
	mov	si, ss:[gstringChunk]
	mov	si, ds:[si]			; ds:si <- copied GString
	ChunkSizePtr	ds, si, cx
	
	test	ss:[chunkType], mask CT_MONIKER
	jz	notMoniker
	add	cx, MONIKER_GSTRING_OFFSET	; cx <- size to allocate

notMoniker:
	; allocate/reallocate a transItem, lock it, and get the	
	; item's moniker type
	;
	push	cx, si
	movdw	bxsi, ss:[document]
	call	AllocAndLockItemAndGetMonikerType ;es:di <- item, cx DBItem
	mov	ss:[newItem], cx
	pop	cx, si

	mov	ax, ss:[oldWidth]		; same as gswidth/height
	mov	bx, ss:[oldHeight]
	test	[chunkType], mask CT_MONIKER
	jz	copy

	mov	es:[di].VM_width, ax	
	add	di, offset VM_data
	mov	es:[di].VMGS_height, bx	
	sub	di, offset VM_data
	mov	al, ss:[chunkType]
	mov	es:[di].VM_type, al
	add	di, MONIKER_GSTRING_OFFSET
	sub	cx, MONIKER_GSTRING_OFFSET	; cx <- size of gstring alone
copy:
	rep	movsb
	call	DBUnlock			; unlock the new item
	GetResourceHandleNS	DummyResource, bx
	call	MemUnlock			; unlock the gstring

	; Destroy the destination gstring and kill its data
	;
	mov	si, dx				;SI <- gstring to kill
	clr	di				;DI <- GState = NULL
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString

	mov	ax, ss:[newItem]
	clc

derefAndExit:
	movdw	bxsi, ss:[document]
	call	MemDerefDS
	.leave
	ret

sizeMismatch:
	call	DestroySourceAndDestGStrings
	mov	ax, EV_GSTRING_WRONG_SIZE
	stc
	jmp	derefAndExit
PasteGString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckGStringCompatibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that gstring being pasted is the same size
		as the original.

CALLED BY:	PasteGString only
PASS:		*ds:si	- document
		ss:bp	- inherited locals
RETURN:		carry set if not compatible
		 Might be set if the gstring is too
		    big, possibly  b/c the grobj set the
		    bounds of the gstring, increasing them
		    by line width
		    PasteGString will then try to shrink the gstring
		    to its proper size.
		fills in oldWidth and oldHeight of caller with width
		 and height of original gstring

DESTROYED:	ax,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckGStringCompatibility		proc	near
	uses	ax,bx,cx,dx,si
	.enter inherit PasteGString

	push	ds:[LMBH_handle]

	DerefDoc
	call	GetFileHandle
	push	ds:[di].REDI_resourceGroup
	mov	ax, ds:[di].REDI_curChunk
	call	DerefElement			; ds:di <- ResArrayElement
	mov	cl, ds:[di].RAE_data.RAD_chunkType
	mov	di, ds:[di].RAE_data.RAD_origItem
	call	DBUnlock_DS

	pop	ax
	call	DBLock
	mov	di, es:[di]
	test	cl, mask CT_MONIKER
	jz	okay

checkSize::
	mov	ax, es:[di].VM_width
	mov	ss:[oldWidth], ax
	add	di, offset VM_data
	mov	cx, es:[di].VMGS_height
	mov	ss:[oldHeight], cx

	cmp	cx, ss:[gsheight]
	jne	notCompatible
	cmp	ax, ss:[gswidth]
	jne	notCompatible

okay:
	clc
done:
	call	DBUnlock
	pop	bx
	call	MemDerefDS	
	.leave
	ret

notCompatible:
	stc	
	jmp	done
CheckGStringCompatibility		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyGStringWithSizeAdjust
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the passed source gstring to the destination
		gstring, but also adjusts the width and height of the
		destination by filtering out any GR_SET_GSTRING_BOUNDS
		opcodes.  If the filtered gstring still isn't the
		right size, carry is returned set.

		Remedy for bug 28886.

CALLED BY:	PasteGString
PASS:		si	- source gstring
		di	- destination gstring

RETURN:		carry	- set if filtered gstring is still wrong size
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This routine gives a second chance to a gstring whose size
	does not match the size of the original gstring.  The reason
	we don't give the second chance in CheckGStringCompatibility
	is that we need to create another, filtered, gstring to check
	its size.  The code for creation is in PasteGString, so we use
	it and reject the filtered gstring, if necessary, here.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyGStringWithSizeAdjust	proc	near
	uses	cx,dx
	.enter inherit PasteGString
	;
	; Filter out GR_SET_BOUNDS 
	;
	mov	cx, offset FilterSetBounds
	call	CopyGStringWithFilter
	cmp	cx, ss:[oldWidth]
	jne	error
	cmp	dx, ss:[oldHeight]
	jne	error
	clc					; Hey!  A match!

done:
	.leave
	ret
error:
	stc
	jmp	done
CopyGStringWithSizeAdjust	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyGStringWithFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the source gstring to the destination gstring,
		filtering op_codes specified by the passed filter
		routine.  Returns the width and height of the filtered
		destination.

CALLED BY:	CopyGStringWithSizeAdjust, CheckBitmapSizeCompatible
PASS:		si	- source gstring
		di	- destination gstring
		cx	- offset to filter routine, which 
			   returns zf clear if op_code in cl passes
			   and GSRetType in dx pass through the
			   filter.  zf set if this element should be
			   skipped
RETURN:		cx	- filtered width
		dx	- filtered height
		di	- destination gstring, now filtered
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyGStringWithFilter	proc	near
	uses	ax,bx,si,di,bp
	.enter

	; Filter out undesirable op-codes.
	;
	mov	bx, cx				; save filter
	mov	bp, di				; save dest gstring
	jmp	doNextElement
advancePos:
	mov	al, GSSPT_SKIP_1
	call	GrSetGStringPos
doNextElement:
	clr	cx				; just want op-code
	clr	di				; no gstate
	call	GrGetGStringElement		; al<-op-code
	mov	di, bp				; recall destination
	cmp	al, GR_END_GSTRING
	je	doneFiltering

	call	bx				; zf set if filtered
	je	advancePos			; Skip this element.

	mov	dx, mask GSC_ONE
	call	GrCopyGString			; copy
	cmp	dx, GSRT_COMPLETE
	je	doneFiltering
	jmp	doNextElement

	; Get size of filtered gstring.
	;
doneFiltering:
	call	GrEndGString			; End our new source gstring
EC <	cmp	ax, GSET_NO_ERROR		>
EC <	ERROR_NE RESEDIT_INTERNAL_ERROR		>

	mov	si, di
	clr	di,dx
	call	GrGetGStringBounds
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR		>
	sub	cx, ax				; filtered width
	sub	dx, bx				; filtered height

	.leave
	ret
CopyGStringWithFilter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilterSetBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accepts all elements except GR_SET_GSTRING_BOUNDS.

CALLED BY:	CopyGStringWithFilter via CopyGStringWithSizeAdjusted
PASS:		al	- op-code
RETURN:		zf	- set if opcode *is* GR_SET_GSTRING_BOUNDS and
			  thus should *not* be copied
			- clr if this element may be copied
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilterSetBounds	proc	near
	.enter

	cmp	al, GR_SET_GSTRING_BOUNDS

	.leave
	ret
FilterSetBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilterAllButDrawBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rejects all opcodes except GR_DRAW_BITMAP.

CALLED BY:	CopyGStringWithFilter via CheckBitmapSizeCompatible
PASS:		al	- op-code
RETURN:		zf	- set if opcode is *not* GR_DRAW_BITMAP and
			  thus should *not* be copied
			- clr if this op-code is GR_DRAW_BITMAP, so ok
			  to copy
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilterAllButDrawBitmap	proc	near
	uses	ax
	.enter

	cmp	al, GR_DRAW_BITMAP
	lahf
	xor	ah, mask CPU_ZERO
	sahf

	.leave
	ret
FilterAllButDrawBitmap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroySourceAndDestGStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys the passed source and destination gstrings.
		Source's data is left.  Destination's data is killed.

CALLED BY:	PasteGString, CheckBitmapSizeCompatible
PASS:		si	- source gstring
		di	- destination gstring
RETURN:		nothing
DESTROYED:	si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroySourceAndDestGStrings	proc	near
	uses	dx
	.enter

	push	di				;save dest
	clr	di
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString		;kill source
	pop	si
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString		;kill dest

	.leave
	ret
DestroySourceAndDestGStrings	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	paste a bitmap

CALLED BY:	DocumentClipboardPaste

PASS:		*ds:si - document instance data
		^hbx  - transfer file
		ax:bp - transfer item header (returned by ClipboardQueryItem)
 		cx, dx - gstring width, height

RETURN:		carry set if error
			ax - ErrorValue
		carry clear if successful
			ax - new item

DESTROYED:	ax,bx,es

PSEUDO CODE/STRATEGY:
	Use a VisBitmap object to turn the transfer gstring into a 
	HugeBitmap, from which we can extract a simple bitmap.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteBitmap		proc	near

	document	local	optr	push	ds:[LMBH_handle], si
	bitmapVM	local	dword	
	sourceGString	local	hptr
	.enter

	call	CheckBitmapCompatibility ; al = format, cx:dx=width,height
					 ; ^hsi = loaded source gstring
	LONG	jc	sizeMismatch

	mov	ss:[sourceGString], si

	;
	; Pass the format, widht and height as returned by 
	; CheckBitmapCompatibility above.
	;
	clrdw	disi			; no object get MSG_META_EXPOSED
	call	GrCreateBitmap		; ^vbx:ax <- bitmap
	movdw	ss:[bitmapVM], bxax

	;
	; simple bitmaps are always 72 dpi
	;
	mov	ax, 72
	mov	bx, 72
	call	GrSetBitmapRes

 	;
 	;	Set the color map mode to pattern, writing to a black
 	;	background.
 	;
 	mov	al, CMT_DITHER
 	call	GrSetAreaColorMap
 	call	GrSetLineColorMap
 	call	GrSetTextColorMap

	mov	si, ss:[sourceGString]		; ^hsi <- string to draw
	clr	ax, bx, dx
	call	GrDrawGString
EC<	cmp	dx, GSRT_COMPLETE				>

	push	di
	clr	di				;di <- GState = NULL
	mov	dl, GSKT_KILL_DATA		;*NOT* killing the
						;clipboard item.
						;Killing the filtered
						;copy.
	call	GrDestroyGString
	pop	di				;di <- bitmap's gstate

	mov	si, ss:[document].chunk
	movdw	bxax, ss:[bitmapVM]
	call	HugeBitmapToSimpleBitmap	; ax <- new item

	push	ax
	mov	al, BMD_KILL_DATA
	call	GrDestroyBitmap
	pop	ax

	clc

derefAndExit:
	movdw	bxsi, ss:[document]
	call	MemDerefDS
	.leave
	ret

sizeMismatch:
	mov	ax, EV_GSTRING_WRONG_SIZE
	jmp	derefAndExit
PasteBitmap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckBitmapCompatibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that bitmap being pasted is the same size
		as the original.

CALLED BY:	PasteBitmap
PASS:		*ds:si	- document
		cx:dx 	- width, height of transfer item
			  (although no longer used for comparison)
		^hbx	- transfer file
		ax	- transfer item

RETURN:		carry set if not compatible
		al - format
		cx:dx - width, height of original bitmap
		^hsi	- source gstring if carry clear

DESTROYED:	di,es

PSEUDO CODE/STRATEGY:
	We make this routine load and return the source gstring
	so that the caller won't have to worry about whether the
	transfer item size didn't match, causing a filtered gstring to
	be created.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckBitmapCompatibility		proc	near
	.enter

	; Get the attributes of the original bitmap
	;
	push	bx
	mov	di, ax		; save item
	call	GetFileHandle	; al <- format; cx:dx <- width, height
	call	GetBitmapFormat
	pop	bx

	; Regardless of size, need to filter out all but GR_DRAW_BITMAP.
	;
	call	CheckBitmapSizeCompatible	;cf set if not compat.

	.leave
	ret
CheckBitmapCompatibility		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckBitmapSizeCompatible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the gstring, stripped of its
		GR_SET_GSTRING_BOUNDS, matches the expected bitmap
		size.

CALLED BY:	CheckBitmapCompibility only
PASS:		cx:dx	- width:height of original bitmap
		^hbx	- transfer file
		di	- transfer item block
RETURN:		carry	- set if sizes different (not compatible)
		^hsi	- gstring if carry is clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Copy gstring to temp gstring, filtering out
	  GR_SET_GSTRING_BOUNDS.
	Compare size of temporary gstring to expected size.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckBitmapSizeCompatible	proc	near
	uses	ax,bx,cx,dx,di
origWidth	local	word	push	cx
origHeight	local	word	push	dx
	.enter 

	; Load the source gstring containing the bitmap.
	;
	mov_tr	si, di			; si <- vmem block handle of string
	mov	cl, GST_VMEM
	call	GrLoadGString		; ^hsi = source GString 

	; Create destination GString in DummyResource
	;
	GetResourceHandleNS	DummyResource, bx
	push	si			;save source GString handle
	mov	cl, GST_CHUNK		
	call	GrCreateGString		;^hdi <- new gstring to draw to
	pop	si

	; Filtered-copy source GString to destination GString and check
	; if size is okay.
	;
	mov	cx, offset FilterAllButDrawBitmap
	call	CopyGStringWithFilter		; cx:dx=width:height

	push	di				; Save source gstring
	push	dx				; Save height.
	clr	di
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString		; Done with xfer gstring
	pop	dx
	pop	si

	cmp	cx, ss:[origWidth]
	jne	error
	cmp	dx, ss:[origHeight]
	jne	error
	
	clc					; Paste is legal
done:
	.leave
	ret
error:
	stc
	jmp	done
CheckBitmapSizeCompatible	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBitmapFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that bitmap being pasted is of the same size
		as the original.

CALLED BY:	PasteBitmap
PASS:		*ds:si	- document
		^hbx - translation file 
RETURN:		al - BMFormat
		cx - width
		dx -height
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBitmapFormat		proc	near
	uses	bx, di
	.enter

	push	ds:[LMBH_handle], si

	DerefDoc
	push	ds:[di].REDI_resourceGroup
	mov	ax, ds:[di].REDI_curChunk
	call	DerefElement			; ds:di <- ResArrayElement
	mov	si, di
	pop	ax				
	mov	di, ds:[si].RAE_data.RAD_origItem ; ax:di <- orig DBItem
	call	DBUnlock_DS			; unlock ResourceArray
	call	DBLock_DS			; lock the OrigItem
	mov	di, ds:[si]			; es:si <- bitmap

	;
	; Compare the width, height and format of the original bitmap
	; (es:si) and the bitmap to be pasted (ds:di)
	;
	mov	cx, ds:[di].B_width	
	mov	dx, ds:[di].B_height
	mov	al, ds:[di].B_type
	andnf	al, mask BMT_FORMAT

	call	DBUnlock_DS
	pop	bx, si
	call	MemDerefDS

	.leave
	ret

GetBitmapFormat		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeBitmapToSimpleBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a huge-bitmap (<64k) into a regular bitmap 
		in an item.

CALLED BY:	GLOBAL

PASS:		^vbx:ax = huge bitmap 
		*ds:si - document

RETURN:		ax = bitmap item
		
DESTROYED:	bx,cx,dx,ds,es,si

PSEUDO CODE/STRATEGY:

	- find out how big the bitmap is
	- allocate an item big enough to hold the bitmap
	- copy the data from the huge-bitmap into the item

SIDE EFFECTS:

	Don't even think about passing a huge array that's larger
	than 64k.  It'll just return garbage.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/27/92    	Initial version
	cassie	10/07/93	modified for ResEdit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeBitmapToSimpleBitmap	proc	near
		uses	bp, di
		
	hugeBitmap	local	dword
	bitmapItem	local	word
	elemSize	local	word
		.enter
	;
	; GrCompactBitmap first?  Creates another HugeArray which
	; has variable sized elements.  Then won't know how big an
	; item needs to be created.  Could use pre-compaction size as
	; an upper limit.  Write to a buffer, copy buffer to new item
	; using amount of data in buffer as size.
	;
	;  Find out how big the huge bitmap is.
	;
		movdw	ss:[hugeBitmap], bxax	; save bitmap
		call	HugeBitmapGetSizeInBytes; returns in dx:ax, and cx
		mov	ss:[elemSize], cx	; save element size
		tst	dx			; larger than 64k?
		LONG	jnz	done		; error, actually

	;
	;  Allocate an item to hold the simple bitmap
	;
		DerefDoc
		mov	cx, ax			; cx <- size of bitmap
		add	cx, size Bitmap		; make room for header
		call	GetFileHandle		; ^hbx <- translation file
		mov	ax, ds:[di].REDI_resourceGroup
		call	DBAlloc			; di <- item
		mov	ss:[bitmapItem], di
		call	DBLock
		mov	di, es:[di]

	;
	;  Set up the loop.
	;	
		push	di			; save item offset
		add	di, size Bitmap		; skip the header
		push	di			; save bitmap data offset
		movdw	bxdi, ss:[hugeBitmap]
		clrdw	dxax			; lock first element
		call	HugeArrayLock		; ds:si = element
		pop	di		

elemLoop:		
	;
	;  Loop through the elements of the huge bitmap, copying the
	;  data to the chunk.
	;
		mov	bx, si			; save element sptr
		mov	cx, ss:[elemSize]
		rep	movsb
		mov	si, bx			; restore element sptr
		call	HugeArrayNext		; ds:si = next element
		tst	ax
		jnz	elemLoop
		
		call	HugeArrayUnlock		; unlock last element
	;
	;  Initialize the header for the simple bitmap by directly
	;  copying the header from the huge bitmap (the CB_simple part)
	;  into the header for the simple bitmap.
	;
		movdw	bxdi, ss:[hugeBitmap]
		call	HugeArrayLockDir
		mov	ds, ax
		lea	si, ds:[(size HugeArrayDirectory)].CB_simple
EC<		cmp	ds:[si].B_compact, BMC_UNCOMPACTED		>
EC<		ERROR_NE RESEDIT_INTERNAL_LOGIC_ERROR			>
		mov	cx, size Bitmap

		pop	di			; restore item offset
		rep	movsb
		call	HugeArrayUnlockDir
	;
	;  Two of the fields set in a huge bitmap are inappropriate for
	;  the simple bitmap, so we clear them here.
	;
		sub	di, size Bitmap
		andnf	es:[di].B_type, not mask BMT_HUGE
		andnf	es:[di].B_type, not mask BMT_COMPLEX
	;
	;  unlock the item and set up return values
	;
		call	DBUnlock
		mov	ax, ss:[bitmapItem]	; return ax = new item

done:
		.leave
		ret
HugeBitmapToSimpleBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeBitmapGetSizeInBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the total number of bytes (data only) in the bitmap.

CALLED BY:	GLOBAL

PASS:		^vbx:ax = bitmap

RETURN:		dx:ax = size of bitmap, in bytes
		cx    = size per element, in bytes

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Only works for uncompacted bitmaps with fewer than 64k scan lines.

PSEUDO CODE/STRATEGY:

	Count the elements, and multiply by the size-per-element.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/27/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeBitmapGetSizeInBytes	proc	near
		uses	bx,si,di,ds
		.enter
		
		mov	di, ax
		clrdw	dxax
		call	HugeArrayLock		; returns elem. size in dx
		push	dx
		
		call	HugeArrayUnlock
		call	HugeArrayGetCount	; dx.ax = #elements
		
		pop	dx			; dx <- size per element
		mov	cx, dx			; cx <- size per element
		mul	dx			; dx:ax = #bytes
		
		.leave
		ret
HugeBitmapGetSizeInBytes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocAndLockItemAndGetMonikerType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and lock a new translation item. 
		Return moniker type of original gstring.

CALLED BY:	DocumentClipboardPasteGString
PASS:		^lbx:si	- document
		cx - size to allocate

RETURN:		es:di - new item, locked
		al - VisMonikerType
		cx - new DBItem

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocAndLockItemAndGetMonikerType	proc	near
	uses	dx,ds
	.enter 

	; allocate a new translation item
	;
	call	MemDerefDS
	DerefDoc
	call	GetFileHandle			; ^hbx <- file handle
	mov	ax, ds:[di].REDI_resourceGroup
	mov	dx, ds:[di].REDI_origItem
	call	DBAlloc				; di <- new item
	mov	cx, di

	; get the moniker type from the orig item
	;
	mov	di, dx
	call	DBLock
	mov	di, es:[di]
	mov	dl, es:[di].VM_type
	call	DBUnlock

	; lock the new item
	;
	mov	di, cx
	call	DBLock			
	mov	di, es:[di]			; es:di <- new item
	mov	al, dl				; al <- VisMoniker type

	.leave
	ret
AllocAndLockItemAndGetMonikerType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGStringSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height and width of a gstring or bitmap

CALLED BY:	INTERNAL - BuildGStringTransferBlock

PASS:		ax:bp	- DBItem of gstring
		bx	- file handle
		ds:si	- gstring or bitmap
		cl	- ChunkType

RETURN:		cx	- width
		dx	- height

DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGStringSize		proc	near
	uses	ax, bx, si, di, ds
	.enter

	push	cx				;save the chunk type
	mov	cl, GST_PTR
	mov	bx, ds				; bx:si <- gstring data
	call	GrLoadGString			; ^hsi <- gstring

	;
	; get the bounds of the drawn gstring 
	;
	clr	di				; no gstate
	clr	dx				; go through entire string
	call	GrGetGStringBounds
EC <	jnc	okay					>
EC <	clr	bx					>
EC <okay:						>
	; GrGetGStringBounds returns:
	; ax - left side coord of smallest rect enclosing string
	; bx - top coord, cx - right coord, dx - bottom coord
	;
	sub	cx, ax				;cx <- width
	sub	dx, bx				;dx <- height

	; destroy the gstring, but leave the data
	;
	pop	ax				; al <- ChunkType
	push	dx
	mov	dl, GSKT_LEAVE_DATA		; assume it's a gstring
	clr	di
	call	GrDestroyGString
	pop	dx

	.leave
	ret

GetGStringSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyGStringToVMChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a gstring to a temporary VMChain in the document file.

CALLED BY:	INTERNAL - BuildGStringTransferBlock

PASS:		ds:si	- data
		al	- ChunkType

RETURN:		ax	- block of VMChain containing gstring
DESTROYED:	cx, es, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyGStringToVMChain	proc	near
	uses	si
	.enter
	
	ChunkSizePtr	ds, si, cx
	test	al, mask CT_MONIKER
	jz	notMoniker

	sub	cx, MONIKER_GSTRING_OFFSET	;dx <- size of gstring
	add	si, MONIKER_GSTRING_OFFSET	;ds:si <- gstring

notMoniker:
	;
	; Load the gstring from the translation file
	;
	mov	cl, GST_PTR
	mov	bx, ds				;bx:si <- gstring data
	call	GrLoadGString			;^hsi <- gstring

	;
	; Create a gstring in the clipboard file
	;
	push	si
	call	ClipboardGetClipboardFile
	mov	cl, GST_VMEM
	call	GrCreateGString		;^hdi <- clipboard gstring
	mov	bx, si			; dx <- VM block of gstring
	pop	si			;^hsi <- trans file gstring

	;
	; Copy the gstring from the translation file to the clipboard file
	; 
	clr	dx			; no flags
	call	GrCopyGString
	cmp	dx, GSRT_COMPLETE

	push	bx,si,di
	mov	si, di			; ^hsi=gstring (source)
	clr	dx			; GSControl - no flags
	clr	di			; no gstate
	call	GrGetGStringBounds	; ax,bx,cx,dx = l,t,r,b bounds
EC <	ERROR_C	RESEDIT_INTERNAL_ERROR		>
	mov	di, si			; ^hdi=gstring (destination)
	call	GrSetGStringBounds
	pop	bx,si,di

	call	GrEndGString
	cmp	ax, GSET_NO_ERROR

	;
	; Destroy both gstrings, leaving data.
	;
	push	di
	mov	dl, GSKT_LEAVE_DATA
	clr	di			; no gstate
	call	GrDestroyGString	; destroy source gstring
	pop	si
	call	GrDestroyGString	; destroy destination gstring

	mov	ax, bx

	.leave
	ret
CopyGStringToVMChain	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockCurrentItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the item, translation or original, for the
		current element.

CALLED BY:	BuildBitmapTransferBlock, BuildGStringTransferBlock

PASS:		*ds:si	- document
		ds:di	- document

RETURN:		ds:si	- data stored in item
		bx - document file handle

DESTROYED:	dx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockCurrentItem		proc	near
	uses	ax
	.enter

	call	GetFileHandle
	mov	ax, ds:[di].REDI_resourceGroup
	mov	dx, ds:[di].REDI_origItem
	cmp	ds:[di].REDI_curTarget, ST_ORIGINAL
	je	haveItem
	tst	ds:[di].REDI_transItem
	jz	haveItem
	mov	dx, ds:[di].REDI_transItem

haveItem:
	; now lock the item 
	;
	mov	di, dx
	mov	bp, di				;ax:bp <- DBItem
	call	DBLock_DS
	mov	si, ds:[si]

	.leave
	ret
LockCurrentItem		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToTargetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message on to the target text object.

CALLED BY:	INTERNAL
PASS:		*ds:si	- document
		ds:di	- document

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToTargetText		proc	near
	uses	bx, si, di
	.enter

	movdw	bxsi, ds:[di].REDI_editText
	cmp	ds:[di].REDI_curTarget, ST_TRANSLATION
	je	sendIt
	mov	si, offset OrigText
sendIt:
	clr	di
	call	ObjMessage

	.leave
	ret
SendToTargetText		endp

DocumentClipboardSegment	ends

