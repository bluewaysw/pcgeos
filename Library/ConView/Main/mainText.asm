COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		main - view and text
FILE:		mainText.asm

AUTHOR:		Jonathan Magasin, May 10, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT MTConnectTextAttributes Connect various text attribute structures
				to our text object

    INT MTCreateTextStorage Create storage for the ContentText.

    INT MTGetTextForContext Get the text for a context and stuff it in the
				text display

    INT MTUncompressText Uncompress a page's worth of text

    INT MTFindNameForContext Find the name entry for a given context

    INT CTSelectStartAndMakeUndrawable 
				Selects start of the text and makes 
				text undrawable.

    INT CTMakeDrawableAndResetSelection 
				Make the text drawable again, and set 
				the selection so that it will be
				hilited.

    INT CTGetWidestGraphicWidth Gets the width of the widest graphic in the
				text.

    INT CTGetWidestGraphicWidthCallback 
				Callback routine that returns the width 
				of the widest graphic in the passed
				text object (or 0).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/10/94   	Initial revision


DESCRIPTION:
	Code that characterizes the ContentText.
		

	$Id: mainText.asm,v 1.1 97/04/04 17:49:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


BookFileCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTConnectTextAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect various text attribute structures to our text object

CALLED BY:	MLDisplayText()
PASS:		*ds:si - ContentGenView instance
		ax - ContentTextRequestFlags
			CTRF_searchText set if should operate on the
			search text object whose optr is store in vardata
RETURN:		ax - VM handle of name array
		ds - fixed up
DESTROYED:	bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: also sets the file handle for the text object to the help file
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTConnectTextAttributes		proc	far
	uses	dx, es, di, si
	.enter	
EC <	call	AssertIsCGV				>	
	;
	; Create new text storage
	;
	call	MTCreateTextStorage
	;
	; Get the map block of the help file
	;
	call	MFGetFile			;bx <- handle of help file
	call	DBLockMap			;*es:di <- map block
EC <	tst	di				;>
EC <	ERROR_Z HELP_FILE_HAS_NO_MAP_BLOCK	;>
	mov	di, es:[di]			;es:di <- ptr HelpFileMapBlock
	;
	; Connect the object to the help file
	;
	push	di
	mov	di, ax				;pass flags in di
	mov	cx, bx				;cx <- handle of help file
	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	call	MUObjMessageSend
	pop	bx				;es:bx = map block
	;
	; Connect the various attribute arrays
	; NOTE: the order is important -- the names must be done first
	; NOTE: see vTextC.def for details
	;
	mov	ch, TRUE			;ch <- handles are VM
	push	bp
	clr	bp				;bp <- use 1st element
	mov	ax, MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY

	mov	dx, es:[bx].CFMB_names		;dx <- VM handle of names
	push	dx
	mov	cl, VTSF_NAMES
	call	MUObjMessageSend
	mov	dx, es:[bx].CFMB_charAttrs	;dx <- VM handle of char attrs
	mov	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	call	MUObjMessageSend
	mov	dx, es:[bx].CFMB_paraAttrs	;dx <- VM handle of para attrs
	mov	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	call	MUObjMessageSend
	mov	dx, es:[bx].CFMB_graphics	;dx <- VM handle of graphics
	mov	cl, mask VTSF_GRAPHICS
	call	MUObjMessageSend
	mov	dx, es:[bx].CFMB_types		;dx <- VM handle of types
	mov	cl, mask VTSF_TYPES
	call	MUObjMessageSend
	pop	ax				;ax <- VM handle of names
	pop	bp
	;
	; Finished with the map block of the help file
	;
	call	DBUnlock

	.leave
EC <	call	AssertIsCGV				>	
	ret
MTConnectTextAttributes		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTCreateTextStorage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create storage for the ContentText.

CALLED BY:	MTConnectTextAttributes
PASS:		*ds:si - ContentGenView
		ax - ContentTextRequestFlags
RETURN:		ds - fixed up
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTCreateTextStorage		proc	near
	uses	ax
	.enter
EC <	call	AssertIsCGV				>

	;
	; Create storage for the text object
	;
	mov	di, ax				; pass flags in di
	mov	cx, mask VTSF_MULTIPLE_CHAR_ATTRS or \
			mask VTSF_MULTIPLE_PARA_ATTRS or \
			mask VTSF_GRAPHICS or \
			mask VTSF_TYPES		;ch <- no regions
	mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
	call	MUObjMessageSend

	.leave
	ret
MTCreateTextStorage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTGetTextForContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the text for a context and stuff it in the text display

CALLED BY:	MLDisplayText()
PASS:		*ds:si - ContentGenView instance
RETURN:		carry - set if error (context name doesn't exist)
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTGetTextForContext		proc	far
		class	ContentGenViewClass
		uses	bp, si
		.enter

EC <		call	AssertIsCGV					>

		lea	di, ss:[bp].CTR_context		;ss:di <- context 
		sub	sp, size ContentFileNameData
		mov	bp, sp
		mov	bx, bp				;ss:bx <- name data
	;
	; Find the name for the context
	;
		clr	ax				;clr CTRF_searchText
		call	MTFindNameForContext
		jc	quit				;branch if error
	;
	; Tell our text object to load the text
	;
		mov	dx, ss:[bp].CFND_text.VTND_helpText.DBGI_item
		tst	dx			;any item?
		stc				;carry <- in case of error
		jz	quit			;branch if no error
		mov	cx, ss:[bp].CFND_text.VTND_helpText.DBGI_group
		mov	di, ds:[si]
		add	di, ds:[di].ContentGenView_offset
		tst	ds:[di].CGVI_compressLib
		jnz	uncompress
	;
	; If no compression, just have the text be loaded up normally
	;
		mov	ax, MSG_CT_LOAD_FROM_DB_ITEM_AND_UPDATE_SCROLLBARS
		clr	bp			;bp <- use VTI_vmFile
		clr	di			;clear CTRF_searchText
		call	MUObjMessageSend

noError:
		clc				;carry <- no error
quit:
		lahf
		add	sp, size ContentFileNameData
		sahf

		.leave
EC <		call	AssertIsCGV				>
		ret

uncompress:
	;
	; CX.DX <- group/item of compressed data
	;
		mov	ax, ds:[di].CGVI_compressLib
		mov	bx, ds:[di].CGVI_curFile
		call	MTUncompressText		;cx <- data segment
							;dx <- handle of block
		mov	bp, dx				;bp <-handle
		jc	quit

		mov	ax, MSG_CT_LOAD_FROM_DB_ITEM_FORMAT_AND_FREE_BLOCK
		clr	di
		call	MUObjMessageSend
		jmp	noError

MTGetTextForContext		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTUncompressText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompress a page's worth of text

CALLED BY:	MTGetTextForContext, MSGetTextForContext
PASS:		*ds:si - ContentGenView
		^hax - handle of compression library
		^hbx - content file
		cx.dx - DBItem
RETURN:		carry set if error uncompressing text
		carry clear if no error
			cx - segment of data
			^hdx - block containing data
DESTROYED:	ax, bx, es, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTUncompressText		proc	far
		uses	si, ds
		.enter

		mov	si, ax			;^hsi <- compression library
		movdw	axdi, cxdx
		call	DBLock
	;
	; The first word is the uncompacted size
	;
		mov	di, es:[di]
		mov	ax, es:[di]		;AX <- size of uncompacted data
		ChunkSizePtr	es, di, dx	;DX <- size of compacted data
		sub	dx, size word
		add	di, size word
	;
	;	Allocate a block large enough to hold the uncompacted data
	;
EC <		push	ax			;save block size	>
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		mov	ds, ax
EC <		pop	cx			;restore block size	>
		jc	uncompressError

		push	bx			;Save handle of data block
EC <		push	cx			;Save block size	>
		mov	ax, CL_DECOMP_BUFFER_TO_BUFFER or mask CLF_MOSTLY_ASCII
		push	ax
		clr	ax						
		push	ax			;sourceFileHan (unused)
		pushdw	esdi			;sourceBuff
		push	dx			;sourceBuffSize
		push	ax			;destBuffHan
		pushdw	dsax			;destBuffer
		mov	bx, si
		mov	ax, enum CompressDecompress
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable	;AX <- # bytes written out
						; (0 if err)
EC <		pop	dx			;restore block size	>
		tst	ax
		jz	uncompressFreeError
EC <		cmp	dx, ax			;enough bytes written out?>
EC <		ERROR_NE BAD_NUM_BYTES_WRITTEN_OUT			>
		call	DBUnlock		;Unlock the DB item
	;
	; Set up return values
	;
		pop	dx			;dx <- block handle
		mov	cx, ds			;cx <- segment of block
		clc
quit:
		.leave
EC <		call	AssertIsCGV				>
		ret

uncompressFreeError:
		pop	bx			;bx <- block handle
		call	MemFree
uncompressError:
		call	DBUnlock
		stc
		jmp	quit

MTUncompressText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTFindNameForContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the name entry for a given context

CALLED BY:	
PASS:		*ds:si - ContentGenView instance
		ss:di - context - name to find
		ss:bx - name data buffer
RETURN:		ss:bx - nameData - data for name entry
		ax - name token
		carry - set if error (context does not exist)
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTFindNameForContext		proc	far
		uses	ds, si, es, di
		.enter	inherit 
	;
	; Get the data for the name
	;
		call	MNLockNameArray
		segmov	es, ss, dx		;es:di <- name to find
		mov	ax, bx			;dx:ax <- name data buffer
		clr	cx			;cx <- NULL terminated
		call	NameArrayFind
		cmc				;carry <- set if not found
		call	MNUnlockNameArray

		.leave
EC <		call	AssertIsCGV				>
		ret
MTFindNameForContext		endp

BookFileCode	ends


ContentLibraryCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTFreeStorageAndFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call MSG_VIS_TEXT_FREE_STORAGE and then
		clear the stored VM file handle

CALLED BY:	MSG_CT_FREE_STORAGE_AND_FILE
PASS:		*ds:si	= ContentTextClass object
		ds:di	= ContentTextClass instance data
		ds:bx	= ContentTextClass object (same as *ds:si)
		es 	= segment of ContentTextClass
		ax	= message #
		cx	= notification message to send to ContentGenView
			  0 for none
		bp 	= handle of file
	
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/25/94   	Initial version
	martin	8/11/94		Added notification callback

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTFreeStorageAndFile			method dynamic ContentTextClass, 
					MSG_CT_FREE_STORAGE_AND_FILE
		push	cx
		push	bp

		mov	ax, TEMP_CONTENT_TEXT_NO_DELETE
		clr	cx
		call	ObjVarAddData

	; suspend the text object so the DELETE_ALL handler won't
	; try to access non-existent runs when updating the highlight
		
		mov	ax, MSG_META_SUSPEND
		call	ObjCallInstanceNoLock

	; free text storage, without destroying element arrays

		clr	cx			;cx <- don't destroy elements
		mov	ax, MSG_VIS_TEXT_FREE_STORAGE
		call	ObjCallInstanceNoLock

	; *now* we can delete the text, since the runs are gone
		
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	ObjCallInstanceNoLock

	; Before unsuspending, modify VisTextSuspendData so that the
	; object doesn't try to do anything that will cause deadlock
	; while opening a new book (just changing the selection can
	; cause FlowMessageClassedEvent() to be called, which is run
	; by the UI thread, which is waiting for this method to return).

		mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
		call	ObjVarFindData
EC <		ERROR_NC -1						>
		mov	ds:[bx].VTSD_needsRecalc, BB_FALSE
		movdw	ds:[bx].VTSD_showSelectionPos, 0xffffffff
	
	; Mark the view as invalid, so it clears itself.  If we
	; are in the process of deleting a book, we want to clear
	; the screen without redrawing the text.

		mov	ax, TEMP_CONTENT_TEXT_NO_DRAW
		call	ObjVarFindData
		jnc	noInvalidate
		mov	cl, mask VOF_WINDOW_INVALID
		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_MARK_INVALID
		call	MUCallView
noInvalidate:
		mov	ax, MSG_META_UNSUSPEND
		call	ObjCallInstanceNoLock

	; remove file handle from instance data
		
		mov	di, ds:[si]
		add	di, ds:[di].VisText_offset
		clr	ds:[di].VTI_vmFile

	; close the file

		pop	bx
		tst	bx
		jz	noClose
		mov	al, FILE_NO_ERRORS
		call	VMClose
noClose:
	; send notification message to ContentGenView
		
		pop	ax
		tst	ax
		jz	done
		call	MUCallView
done:
		ret
CTFreeStorageAndFile	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTVisTextDeleteAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If freeing storage, don't delete the text yet.

CALLED BY:	MSG_VIS_TEXT_DELETE_ALL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentTextClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTVisTextDeleteAll		method dynamic ContentTextClass,
						MSG_VIS_TEXT_DELETE_ALL
		push	ax
		mov	ax, TEMP_CONTENT_TEXT_NO_DELETE
		call	ObjVarDeleteData	; carry set if not found
		pop	ax
		jnc	done
		mov	di, offset ContentTextClass
		call	ObjCallSuperNoLock
done:
		ret
CTVisTextDeleteAll		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTLoadFromDBItemFormatAndFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call LOAD_FROM_DB_ITEM_FORMAT and free block.

CALLED BY:	MSG_CT_LOAD_FROM_DB_ITEM_FORMAT_AND_FREE_BLOCK
PASS:		*ds:si	= ContentTextClass object
		ds:di	= ContentTextClass instance data
		es 	= segment of ContentTextClass
		ax	= message #

		bp	= block handle
		cx	= segment of locked block
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	4/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTLoadFromDBItemFormatAndFreeBlock	method dynamic ContentTextClass, 
				MSG_CT_LOAD_FROM_DB_ITEM_FORMAT_AND_FREE_BLOCK
	;
	; First load the DB item from its locked block.
	;
	push	bp
	clr	dx				; cx:dx <- data
	mov	ax, MSG_CT_LOAD_FROM_DB_ITEM_FORMAT_AND_UPDATE_SCROLLBARS
	call	ObjCallInstanceNoLock
	pop	bx
	;
	; Now free the block.
	;
	call	MemFree
	ret
CTLoadFromDBItemFormatAndFreeBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTLoadFromDbItemAndUpdateScrollbars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads new page into text object and tells the
		view to update its scrollbars.

CALLED BY:	MSG_CT_LOAD_FROM_DB_ITEM_FORMAT_AND_UPDATE_SCROLLBARS
PASS:		*ds:si	= ContentTextClass object
		ds:di	= ContentTextClass instance data
		es 	= segment of ContentTextClass
		ax	= message #
		cx.dx	= DBItem to load from (LOAD_FROM_DB_ITEM)
		cx:dx	= ptr to data to load (LOAD_FROM_DB_ITEM_FORMAT)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Select start of current page.  (Luckily, the current
	  page doesn't get redrawn, which would cause an 
	  annoying flicker just before the new page was loaded.
	  However, the scrollbars do get set to the top/left for
	  the new text instead of remaining at the scroll position
	  for the current text.)
	Make text not drawable to prevent flicker.  (Don't want to
	  draw the text until the scrollbar status has been figured
	  out.)
	Send MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_FORMAT or
	     MSG_VIS_TEXT_LOAD_FROM_DB_ITEM.
	Tell the view to update its scrollbars.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTLoadFromDbItemAndUpdateScrollbars	method dynamic ContentTextClass, 
			MSG_CT_LOAD_FROM_DB_ITEM_FORMAT_AND_UPDATE_SCROLLBARS,
			MSG_CT_LOAD_FROM_DB_ITEM_AND_UPDATE_SCROLLBARS

	push	ax
	call	CTSelectStartAndMakeUndrawable
	pop	di		

	;
	;  Nuke the TEMP_CONTENT_TEXT_INVERT_HOTSPOTS property
	;

	mov	ax, TEMP_CONTENT_TEXT_INVERT_HOTSPOTS
	call	ObjVarDeleteData

	;
	; Load the text.
	;
	mov	ax, MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_FORMAT
	cmp	di, MSG_CT_LOAD_FROM_DB_ITEM_FORMAT_AND_UPDATE_SCROLLBARS
	je	loadIt
	mov	ax, MSG_VIS_TEXT_LOAD_FROM_DB_ITEM
loadIt:		
	call	ObjCallInstanceNoLock
	;
	; Tell view to update its scrollbars.  Force queued so as to 
	; make sure content's VCNI_view field has had time to be 
	; initialized.
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_CT_TELL_VIEW_UPDATE_SCROLLBARS
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage
CTLoadFromDbItemAndUpdateScrollbars	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTSelectStartAndMakeUndrawable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Selects start of the text and makes text undrawable.

CALLED BY:	CTLoadFromDbItemAndUpdateScrollbars, 
PASS:		*ds:si	- text object
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTSelectStartAndMakeUndrawable	proc	near
	uses	cx, dx, bp
	.enter

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	;
	; Make text not drawable.  Need to adjust scrollbars before
	; drawing.
	;
	mov	ax, MSG_VIS_SET_ATTRS
	clr	cx
	or	ch, mask VA_DRAWABLE
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock
	;
	; Select start, so that when a new page is displayed, the
	; start of that page is visible.
	;
	mov	ax, MSG_VIS_TEXT_SELECT_START
	call	ObjCallInstanceNoLock

	.leave
	ret
CTSelectStartAndMakeUndrawable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTTellViewUpdateScrollbars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends message to the view to update its
		scrollbars.  Also sets the size of the
		ContentText and ContentDoc.

CALLED BY:	CTLoadFromDbItemAndTellView,
		CTLoadFromDbItemFormatAndTellView
PASS:		*ds:si	= ContentTextClass
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get some text data for the view.*
	Send MSG_CGV_UPDATE_SCROLLBARS to view.

	*Want the text object to initiate the updating
	 of the scrollbars so that we can avoid deadlock.
	 Before, when the view initiated the update, it
	 MF_CALLed the text object for some data required
	 in determining whether scrollbars should be 
	 enabled.  Result was deadlock.  This way, text
	 object just gets the data from itself and ships
	 it off to the view.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTTellViewUpdateScrollbars		method dynamic ContentTextClass, 
					MSG_CT_TELL_VIEW_UPDATE_SCROLLBARS
viewWidth 	local	word
viewHeight	local	word
textWidth	local	word
textHeight	local	word
widestGraphic	local	word
currentDimAttrs	local	word
newDimAttrs	local	word
		.enter

	;
	; Check if scrollbars really need updating.
	;
	mov	ax, MSG_CGV_GET_UPDATE_SCROLLBARS_STATE
	call	MUCallView		
	LONG	jcxz	done

	mov	ss:textHeight, 0		;initialize for loop below
	mov	ss:currentDimAttrs, 0		;initialize for loop below
	mov	ss:newDimAttrs, -1		;initialize for loop below
	;
	; Get text's width.  Need to check for any wide graphics in 
	; the text, which is the minimum text width.
	;
	call	CTGetWidestGraphicWidth		;ax <- widest graphic
	mov	ss:widestGraphic, ax		;save min text width
	mov	ss:textWidth, ax		
	;
	; Get width of view without scrollbars.
	;
	mov	ax, MSG_CGV_GET_DOC_SIZE
	call	MUCallView_SaveBP		;cx,dx = width, height
	mov	ss:viewWidth, cx
	mov	ss:viewHeight, dx

resizeLoop:
	;
	; Initial text width is MAX(view width, widest graphic width)
	;	pass: cx - GenView's dimension attrs
	;
	mov	ax, ss:viewWidth
	cmp	ax, ss:textWidth
	jbe	haveWidth
	mov	ss:textWidth, ax
haveWidth:
	;
	; If there was no change in scrollbar state, we're done
	;
	mov	cx, ss:newDimAttrs
	cmp	cx, ss:currentDimAttrs
	je	setSizes
	mov	ss:currentDimAttrs, cx		
	;
	; Need height of text for its new width.
	;
	mov	cx, ss:textWidth
	clr	dx
	mov 	ax, MSG_VIS_TEXT_CALC_HEIGHT
	call	ObjCallInstanceNoLock_SaveBP
	mov	ss:textHeight, dx	
	;
	; Tell the ContentGenView to update the scrollbars given the
	; text's desired minimum width and height at that width.
	; Pass: (on stack) 	view width
	;			view height
	;			text width
	;			text height
	push	bp
	push	dx				; dx = textHeight
	push	ss:textWidth
	push	ss:viewHeight		
	push	ss:viewWidth
	mov	bp, sp
	mov	cx, size UpdateScrollbarParams		
	mov	ax, MSG_CGV_UPDATE_SCROLLBARS	
	call	MUCallViewStack
	add	sp, size UpdateScrollbarParams	

	mov	ax, MSG_GEN_VIEW_GET_DIMENSION_ATTRS
	call	MUCallView
	and	cx, (mask GVDA_SCROLLABLE or mask GVDA_SCROLLABLE shl 8)
	pop	bp
	mov	ss:newDimAttrs, cx
	;
	; Get new view win bounds, as it may have added or 
	; removed scrollbars. 
	; 
	call	GetWinBounds			; ax <- view win width
	mov	ss:viewWidth, ax		; save new view width
	mov	ss:viewHeight, dx		; save new view width
	;
	; Text width should be wider of widest graphic
	; and current view win width
	;
	mov	ax, ss:widestGraphic
	mov	ss:textWidth, ax		
	jmp	resizeLoop
		
setSizes::
	;
	; View must adjust its scroll area for new text dimensions.
	;
	mov	cx, ss:textWidth
	mov	dx, ss:textHeight
	mov	ax, MSG_CGV_SET_SIMPLE_BOUNDS
	call	MUCallView_SaveBP
	;
	; Now set size of text and content (doc) to (cx,dx) =
	; (text width,height).
	;
	mov	cx, ss:textWidth
	mov	dx, ss:textHeight
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock_SaveBP

	mov	cx, ss:textWidth
	mov	dx, ss:textHeight
	mov	si, offset ContentDocTemplate
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock_SaveBP
	;
	; Force text to be recalculated.
	;
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	mov	si, offset ContentTextTemplate
	call	ObjCallInstanceNoLock_SaveBP
	;
	; Make text drawable.
	;
	call	CTMakeDrawableAndResetSelection
done:
	.leave
	ret
CTTellViewUpdateScrollbars	endm

;---

MUCallView_SaveBP		proc	near
		push	bp
		call	MUCallView
		pop	bp
		ret
MUCallView_SaveBP		endp
		
ObjCallInstanceNoLock_SaveBP	proc	near
		push	bp
		call	ObjCallInstanceNoLock
		pop	bp
		ret
ObjCallInstanceNoLock_SaveBP	endp

;---
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWinBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the actual visible window bounds for the view
		which this object is a vis descendant of.

CALLED BY:	CTTellViewUpdateScrollbars, 
PASS:		*ds:si - ContentTextClass
RETURN:		ax - current view window width
		dx - window height
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetWinBounds		proc	near
		uses	bx, cx, bp
		.enter
EC <		call	AssertIsCText					>
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock		;bp <- gstate
EC <		ERROR_NC JM_SEE_BACKTRACE		>

		mov_tr	di, bp
		call	GrGetWinBounds
EC <		ERROR_C JM_SEE_BACKTRACE		>
		sub	cx, ax				;cx <- width
		mov	ax, cx				;ax <- width
		sub	dx, bx				;dx <- height
		call	GrDestroyState

		.leave
		ret
GetWinBounds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTMakeDrawableAndResetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the text drawable again, and set the selection
		so that it will be hilited.
CALLED BY:	
PASS:		*ds:si - ContentText 
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTMakeDrawableAndResetSelection		proc	near
		uses	bp
		class	VisTextClass
		.enter
	;
	; Invalidate the text object, so that the entire thing is
	; redrawn after loading a new page and scrolling to the top.
	; There were cases where the bottom of the new page would be
	; clipped, and this fixes that.
	;
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
	;
	; Now make the text drawable.
	;
		mov	ax, MSG_VIS_SET_ATTRS
		clr	cx
		or	cl, mask VA_DRAWABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

	;
	; Make sure the text knows it is hilited.  This is necessary because
	; of the case where a search match has been found on the page that
	; has just been made visible, and a range was selected while the
	; text was not drawable.  VTIF_HILITED won't be set, but when the
	; text is drawn, it draws the selection hilited.  
	; 
		mov	di, ds:[si]
		add	di, ds:[di].VisText_offset
		ornf	ds:[di].VTI_intFlags, mask VTIF_HILITED
	;
	; Make sure ContentGenView has the target - this is done to
	; make search matches more apparent, because if ContentText
	; doesn't have target and focus, the selection won't be hilited.
	; 
		mov	ax, MSG_META_GRAB_TARGET_EXCL	;Give target to CGV
		call	MUCallView
	;
	; Force the text to show its selection. If a search match was
	; found somewhere outside the visible range, it won't be 
	; visible if the text object was undrawable at the time
	; MSG_VIS_TEXT_SHOW_POSITION was called (as when match is in a 
	; different file).  For some reason, MSG_VIS_TEXT_SHOW_SELECTION
	; doesn't work here.  We are going use the position of the
	; selection start as the point to make visible.
	;
		sub	sp, size VisTextConvertOffsetParams
		mov	bp, sp
		movdw	dxax, ds:[di].VTI_selectStart
		movdw	ss:[bp].VTCOP_offset, dxax
		call	CallVisTextConvertOffsetToCoordinate		
		movdw	dxax, ss:[bp].VTCOP_xPos
		movdw	cxbx, ss:[bp].VTCOP_yPos
		add	sp, size VisTextConvertOffsetParams

		sub	sp, size VisTextShowSelectionArgs
		mov	bp, sp

		movdw	ss:[bp].VTSSA_params.MRVP_bounds.RD_left, dxax
		incdw	dxax
		movdw	ss:[bp].VTSSA_params.MRVP_bounds.RD_right, dxax
		movdw	ss:[bp].VTSSA_params.MRVP_bounds.RD_top, cxbx
		incdw	cxbx
		movdw	ss:[bp].VTSSA_params.MRVP_bounds.RD_bottom, cxbx

		clr	ax
		mov	ss:[bp].VTSSA_flags, ax
		mov	ss:[bp].VTSSA_params.MRVP_xFlags, ax
		mov	ss:[bp].VTSSA_params.MRVP_yFlags, ax
	;
	; We need to use MRVM_100_PERCENT to make search matches visible.
	;
		mov	ss:[bp].VTSSA_params.MRVP_xMargin, MRVM_100_PERCENT
		mov	ss:[bp].VTSSA_params.MRVP_yMargin, MRVM_100_PERCENT

		mov	ax, MSG_VIS_TEXT_SHOW_SELECTION
		call	ObjCallInstanceNoLock

		add	sp, size VisTextShowSelectionArgs
		
		.leave
		ret
CTMakeDrawableAndResetSelection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTGetWidestGraphicWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the width of the widest graphic in the text.

CALLED BY:	CTTellViewUpdateScrollbars
PASS:		*ds:si	= text object
RETURN:		ax = width of widest graphic
		     in the text object
DESTROYED:	bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTGetWidestGraphicWidth	proc	near
	class	ContentTextClass
	uses	si,cx,dx,bp
	.enter
	;
	; Get VM file
	;
	mov	di, ds:[si]
	add	di, ds:[di].ContentText_offset
	mov	cx, ds:[di].VTI_vmFile
	jcxz	noTextYet

	mov	al, ds:[di].VTI_lrMargin
	clr	ah
	push	ax		
	;
	; Get VM block of graphic runs.
	;
	mov	ax, ATTR_VIS_TEXT_GRAPHIC_RUNS
	call	ObjVarFindData
EC <	ERROR_NC CONTENT_COULDNT_FIND_VARDATA_ITEM		>
	mov	bx, ds:[bx]		;chunk of graphic runs
	mov	si, bx
	mov	bx, ds:[bx]		;ds:bx <- graphic run array
	;
	; Lock graphic run array, and get element block.
	;
	mov	ax, ds:[bx].TRAH_elementVMBlock
	mov	bx, ds:[bx].TRAH_elementArray	; bx <- file handle
	;
	; Find the maximum width in the graphics run
	;
	call	VMLock			; lock elt array
	push	bp
	mov	dx, VM_ELEMENT_ARRAY_CHUNK
	mov_tr	cx, ax			;*cx:dx=element array
	clr	bp			;initial width = 0

	mov	bx, cs
	mov	di, offset CTGetWidestGraphicWidthCallback
	call	ChunkArrayEnum
	mov	ax, bp			;ax <- width of widest graphic

	pop	bp
	call	VMUnlock		;run array
	;
	; Since the ContentText object has a non-zero lrMargin 
	; (to fix bug 31666 on the zoomer), we add the margin to
	; the graphic width to make sure the view is wide enough to 
	; account for the text area and the margin.
	;
	pop	cx			; cx = lrMargin value
	shl	cx			; cx = sum of left and right margins
	add	ax, cx			; ax = graphic width + margins
done:
	.leave
	ret

noTextYet:
	mov	ax, 0
	jmp	done
CTGetWidestGraphicWidth	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTGetWidestGraphicWidthCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine that returns the width of the
		widest graphic in the passed text object (or 0).

CALLED BY:	CTTellViewUpdateScrollbars
PASS:		bp - biggest width found so far
		*ds:si - graphic run array
		ds:di - graphic run array element 
			being enumerated
		*cx:dx - graphic element array

RETURN:		bp - width of widest graphic
		     found so far
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTGetWidestGraphicWidthCallback	proc	far
	.enter

	push	ax
	mov	ax, ds:[di].TRAE_token
	cmp	ax, -1
	je	done
	push	ds, si
	mov	ds, cx
	mov	si, dx
	call	ChunkArrayElementToPtr
EC <	ERROR_C JM_SEE_BACKTRACE		>
	mov	bx, ds:[di].VTG_size.XYS_width
	pop	ds, si
	cmp	bp, bx
	jge	done
	mov_tr	bp, bx
done:
	pop	ax
	clc
	.leave
	ret
CTGetWidestGraphicWidthCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTMetaClipboardCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy selected text, or entire text if none selected,
		to the clipboard.

CALLED BY:	MSG_META_CLIPBOARD_COPY
PASS:		*ds:si	= ContentTextClass object
		ds:di	= ContentTextClass instance data
		ds:bx	= ContentTextClass object (same as *ds:si)
		es 	= segment of ContentTextClass
		ax	= message #
RETURN:		nothing
DESTROYED:	whatever superclass destroys
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTMetaClipboardCopy	method dynamic ContentTextClass, 
					MSG_META_CLIPBOARD_COPY
	;
	; Get the selected text.
	;
		sub	sp, (size VisTextRange)
		mov	bp, sp
		
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		call	ObjCallInstanceNoLock
		pushdw	ss:[bp].VTR_start
		pushdw	 ss:[bp].VTR_end
		push	bp

		cmpdw	ss:[bp].VTR_start, ss:[bp].VTR_end, ax
		jne	gotSelection
	;
	; No selection => copy whole page.
	;
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		call	ObjCallInstanceNoLock

gotSelection:
	;
	; Pretend that the text object has no type info and thus no 
	; name array. We do this because the BookReader changes the
	; name array and it causes problems if we copy it back into
	; Bindery.
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisText_offset
	;
	; The ContentText had type info when it was 
	;  created in MTCreateTextStorage
	;
EC <		test	ds:[di].VTI_storageFlags, mask VTSF_TYPES	>
EC <		ERROR_Z	CONTENT_TEXT_HAS_NO_TYPE_INFO			>
		BitClr	ds:[di].VTI_storageFlags, VTSF_TYPES

		mov	ax, MSG_META_CLIPBOARD_COPY
		mov	di, segment ContentTextClass
		mov	es, di
		mov	di, offset ContentTextClass
		call	ObjCallSuperNoLock		

		mov	di, ds:[si]
		add	di, ds:[di].VisText_offset
		BitSet	ds:[di].VTI_storageFlags, VTSF_TYPES
	;
	; If nothing was selected, restore selection to what it was
	; before MSG_VIS_TEXT_SELECT_ALL was sent.
	;
		pop	bp
		popdw	ss:[bp].VTR_end
		popdw	ss:[bp].VTR_start
		cmpdw	ss:[bp].VTR_start, ss:[bp].VTR_end, ax
		jne	done
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE
		call	ObjCallInstanceNoLock

done:
		add	sp, (size VisTextRange)
	
		ret
CTMetaClipboardCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTVisTextVariableGraphicDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We don't support variable graphics, so just return
		width = 0 and height = 1.  (Can't return 0,0)

CALLED BY:	MSG_VIS_TEXT_VARIABLE_GRAPHIC_DRAW
PASS:		*ds:si	= ContentTextClass object
		ds:di	= ContentTextClass instance data
		ds:bx	= ContentTextClass object (same as *ds:si)
		es 	= segment of ContentTextClass
		ax	= message #
		cx - gstate with font and current position set
		dx:bp - VisTextGraphic (dx always = ss)

RETURN:		cx - width of graphic
		dx - height of graphic
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	7/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTVisTextVariableGraphicDraw	method dynamic ContentTextClass, 
					MSG_VIS_TEXT_GRAPHIC_VARIABLE_DRAW,
					MSG_VIS_TEXT_GRAPHIC_VARIABLE_SIZE

	clr	cx
	mov	dx, 1
	ret

CTVisTextVariableGraphicDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTUnselectText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reset text selection to selection start

CALLED BY:	MSG_CT_UNSELECT_TEXT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentTextClass
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTUnselectText		method dynamic ContentTextClass,
						MSG_CT_UNSELECT_TEXT

		mov	bx, ds:[LMBH_handle]
		sub	sp, size VisTextRange
		mov	bp, sp
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage

		movdw	dxax, ss:[bp].VTR_start
		movdw	ss:[bp].VTR_end, dxax
		mov	dx, size VisTextRange
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE
		mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
		call	ObjMessage
		add	sp, size VisTextRange
		ret
CTUnselectText		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CTKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle keyboard shortcuts for scrolling with
		arrow keys.

CALLED BY:	keyboard input

PASS:		cx - character value
			SBCS: ch = CharacterSet, cl = Chars
			DBCS: cx = Chars
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/12/95		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CTKbdChar	method	ContentTextClass, MSG_META_KBD_CHAR
;;;
;;; Copied from VisTextKbd
;;;
		test	dl, mask CF_RELEASE
		jz	notRelease		; Not release, do more
		cmp	cl, 80h			; Yes, this is gross
						; (Not as gross as putting
						; C_UA_DIERESIS, in my opinion)
		jae	sendUp			; FUP any releases of extended
						;   chars (and some control
						;   chars because I'm lazy.)
		jmp	done			; Throw away other releases
;;;
;;; 
;;;
notRelease:
	;
	; See if this is a kbd shortcut for ContentTextClass
	;
		push	ds, si
		segmov	ds, cs, ax
		mov	ax, (size CTKbdShortcuts)	;ax <- # shortcuts
		mov	si, offset CTKbdShortcuts	;ds:si <- shortcut tab
		call	FlowCheckKbdShortcut
		mov	bx, si				;bx<-offset of shortcut
		pop	ds, si				;ds:si <- ContentText
		jnc	sendUp				;branch if no match
	;
	; Get the message to be sent.
	;
.assert (length CTKbdShortcuts eq length CTKbdFunctions)
		mov	ax, cs:CTKbdFunctions[bx]	;ax <- message
		cmp	ax, MSG_CGV_GOTO_PAGE_FOR_NAV
		jne	sendMsg
	;
	; If it is MSG_CGV_GOTO_PAGE_FOR_NAV, make sure that the
	; book allows the use of the previous/next feature.
	; 
		push	bx
		mov	ax, MSG_CGV_GET_BOOK_FEATURE_FLAGS
		call	MUCallView
		pop	bx
		test	ax, mask BFF_PREV_NEXT
		jz	done
	;
	; If the offset into the CTKbdFunctions table is 0, the key
	; pressed was for VC_PREV_BUTTON, so pass PREVIOUS_PAGE, 
	; else it was the second entry, for VC_NEXT_BUTTON
	;
		mov	ax, MSG_CGV_GOTO_PAGE_FOR_NAV
		mov	cx, CNCGPT_PREVIOUS_PAGE
		tst	bx
		jz	sendMsg
		mov	cx, CNCGPT_NEXT_PAGE

sendMsg:
	;
	; Send the message to the view.  If the message was one of
	; MSG_GEN_VIEW_SCROLL_TOP or MSG_GEN_VIEW_SCROLL_BOTTOM, we
	; also need to send a message to tell the view to scroll to the
	; left or right edge, so that the beginning or end of the text
	; is displayed, not just the first or last line.
	;
		push	ax
		call	MUCallView
		pop	cx
		mov	ax, MSG_GEN_VIEW_SCROLL_LEFT_EDGE
		cmp	cx, MSG_GEN_VIEW_SCROLL_TOP
		je	sendMsg
		mov	ax, MSG_GEN_VIEW_SCROLL_RIGHT_EDGE
		cmp	cx, MSG_GEN_VIEW_SCROLL_BOTTOM
		je	sendMsg
done:		
		ret

sendUp:
		mov	ax, MSG_META_KBD_CHAR
		mov	di, offset ContentTextClass
		call	ObjCallSuperNoLock
		jmp	done
CTKbdChar	endm

	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
	;

if DBCS_PCGEOS

CTKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_PREV_BUTTON and mask KS_CHAR>,	;<Previous>
	<0, 0, 0, 0, C_SYS_NEXT_BUTTON and mask KS_CHAR>,	;<Next>
	<0, 0, 0, 0, C_SYS_HOME and mask KS_CHAR>,	;<Home>
	<0, 0, 0, 0, C_SYS_END and mask KS_CHAR>,	;<End>
	<1, 0, 1, 0, C_SYS_LEFT and mask KS_CHAR>,	;<ctrl + left arrow>
	<1, 0, 1, 0, C_SYS_RIGHT and mask KS_CHAR>,	;<ctrl + right arrow>
	<1, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,	;<left arrow>
	<1, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;<right arrow>
	<1, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,	;<down arrow>
	<1, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;<up arrow>
	<1, 0, 1, 0, C_SYS_DOWN and mask KS_CHAR>,	;<ctrl + down arrow>
	<1, 0, 1, 0, C_SYS_UP and mask KS_CHAR>		;<ctrl + up arrow>

else

CTKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_PREV_BUTTON>,	;<Previous>
	<0, 0, 0, 0, 0xf, VC_NEXT_BUTTON>,	;<Next>
	<0, 0, 0, 0, 0xf, VC_HOME>,		;<Home>
	<0, 0, 0, 0, 0xf, VC_END>,		;<End>
	<1, 0, 1, 0, 0xf, VC_LEFT>,		;<ctrl + left arrow>
	<1, 0, 1, 0, 0xf, VC_RIGHT>,		;<ctrl + right arrow>
	<1, 0, 0, 0, 0xf, VC_LEFT>,		;<left arrow>
	<1, 0, 0, 0, 0xf, VC_RIGHT>,		;<right arrow>
	<1, 0, 0, 0, 0xf, VC_DOWN>,		;<down arrow>
	<1, 0, 0, 0, 0xf, VC_UP>,		;<up arrow>
	<1, 0, 1, 0, 0xf, VC_DOWN>,		;<ctrl + down arrow>
	<1, 0, 1, 0, 0xf, VC_UP>		;<ctrl + up arrow>
endif


CTKbdFunctions word \
	MSG_CGV_GOTO_PAGE_FOR_NAV,		; previous
	MSG_CGV_GOTO_PAGE_FOR_NAV,		; next
	MSG_GEN_VIEW_SCROLL_TOP,		; home
	MSG_GEN_VIEW_SCROLL_BOTTOM,		; end
	MSG_GEN_VIEW_SCROLL_TOP,		; home
	MSG_GEN_VIEW_SCROLL_BOTTOM,		; end
	MSG_GEN_VIEW_SCROLL_LEFT,		; left arrow
	MSG_GEN_VIEW_SCROLL_RIGHT,		; right arrow
	MSG_GEN_VIEW_SCROLL_DOWN,		; down arrow
	MSG_GEN_VIEW_SCROLL_UP,			; up arrow
	MSG_GEN_VIEW_SCROLL_PAGE_DOWN,		; page down 
	MSG_GEN_VIEW_SCROLL_PAGE_UP		; page up 


;--------------------------------------------------------------------------
;		ContentGenView code for dealing with scrollbars
;--------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVUpdateScrollbars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables/disables the scrollbars as necessary
		for the displayed text.

		NOTE: Important that ContentGenView's dimensions are
		      small enough to fit into one word (each dimension).

CALLED BY:	MSG_CGV_UPDATE_SCROLLBARS
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		es 	= segment of ContentGenViewClass
		ax	= message #
		ss:bp 	= UpdateScrollbarParams
RETURN:		cx  	=  new dimension attrs
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	First, determine if text would fit in view without scrollbars.
	If text's minimum width > view's width
		enable horizontal scrollbar
	If text's calc'd height for view's width > view height
		enable vertical scrollbar
	After adding scrollbars, get view window's width and check if
		it has changed (by the addition of a vertical scrollbar).
	If view width has changed, check if widest graphic will fit in
		new, smaller width.  If not, enable horizontal scrollbar.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVUpdateScrollbars	method dynamic ContentGenViewClass, 
					MSG_CGV_UPDATE_SCROLLBARS

	;
	; Get current dimension attrs.
	;
		mov	ax, MSG_GEN_VIEW_GET_DIMENSION_ATTRS
		call	ObjCallInstanceNoLock_SaveBP 
		mov	bx, cx				;bx = current dim attrs
	;
	; Compare calc'd height with view's height.
	;
		clr	dl				;Assume not setting
		mov	ax, ss:[bp].USP_textHeight	;  vert scrollbar.
		cmp	ax, ss:[bp].USP_viewHeight
		jle	checkHorizontal
		or	dl, mask GVDA_SCROLLABLE	;add vert scrollbar
checkHorizontal:
	;
	; Compare calc'd width with view's width.
	;
		clr	cl				;Assume not setting
		mov	ax, ss:[bp].USP_viewWidth	;  horiz scrollbar.
		cmp	ss:[bp].USP_textWidth, ax
		jle	doUpdate
		or	cl, mask GVDA_SCROLLABLE	;add horiz. scrollbar

doUpdate:
		mov	al, dl				;(copy)
		not	bh
		and	dl, bh				;vert "set" attr
		or	bh, al
		not	bh
		mov	dh, bh				;vert "reset" attr

		mov	al, cl				;(copy)
		not	bl
		and	cl, bl				;horiz "set" attr
		or	bl, al
		not	bl
		mov	ch, bl				;horiz "reset" attr
	;
	; If we're not changing scrollbar state, we're done.
	;
		mov	ax, cx
		or	ax, dx
		tst	ax
		jz	noSet
setAttrs::
	;
	; In ensemble, if the scrollbar state changes, MSG_VIS_MARK_INVALID
	; is sent to the ContentGenView, which eventually results in a
	; MSG_META_CONTENT_VIEW_SIZE_CHANGED being sent to ContentDoc, which
	; then calls MSG_CT_TELL_VIEW_UPDATE_SCROLLBARS. To prevent it from
	; calling this message again, inc the "ignore update" count in 
	; ContentGenView vardata. This fixes the annoying second redraw when
	; scrollbar state changes. 
	;
	; In Jedi, where scrollbars are not drawn in the view window, but 
	; in the primary's title bar, MSG_CT_TELL_VIEW_UPDATE_SCROLLBARS
	; is not called a second time because the view size never changes,
	; regardless of scrollbar state.
	;
		push	bp

		mov	ax, MSG_CGV_IGNORE_UPDATE_SCROLLBARS
		call	ObjCallInstanceNoLock
		
		mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
		mov	bp, VUM_NOW
		call	ObjCallInstanceNoLock
		pop	bp

noSet:
		ret
CGVUpdateScrollbars	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVGetDocSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the width and height of the view.

CALLED BY:	MSG_CGV_GET_DOC_SIZE
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
RETURN:		cx	= width
		dx	= height
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVGetDocSize	method dynamic ContentGenViewClass, 
					MSG_CGV_GET_DOC_SIZE
	uses	bp
	.enter
	
	mov	ax, MSG_VIS_GET_SIZE
	call	ObjCallInstanceNoLock		;cx:dx has bounds

	.leave
	ret
CGVGetDocSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVSetSimpleBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets simple bounds of the CGView.

CALLED BY:	MSG_CGV_SET_SIMPLE_BOUNDS
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
		cx	= width
		dx	= height
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	8/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVSetSimpleBounds	method dynamic ContentGenViewClass, 
					MSG_CGV_SET_SIMPLE_BOUNDS
	uses	cx, dx, bp
	.enter

	mov	bx, ds:[LMBH_handle]
	clr	di
	call	GenViewSetSimpleBounds

	.leave
	ret
CGVSetSimpleBounds	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVGetUpdateScrollbarsState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check for TEMP_CONTENT_IGNORE_UPDATE_SCROLLBARS_COUNT

CALLED BY:	MSG_CGV_GET_UPDATE_SCROLLBARS_STATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentGenViewClass
		ax - the message
RETURN:		cx = non-zero if data not found
		cx = 0 if data was found
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVGetUpdateScrollbarsState		method dynamic ContentGenViewClass,
					MSG_CGV_GET_UPDATE_SCROLLBARS_STATE
		mov	ax, TEMP_CONTENT_IGNORE_UPDATE_SCROLLBARS_COUNT
		call	ObjVarFindData
		mov	cx, -1
		jnc	done
		inc	cx			; cx = 0
EC <		tst	{byte}ds:[bx]					>
EC <		ERROR_Z -1						>
		dec	{byte}ds:[bx]
		jnz	done
		call	ObjVarDeleteDataAt
done:		
		ret
CGVGetUpdateScrollbarsState		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVIgnoreUpdateScrollbars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	increment TEMP_CONTENT_IGNORE_UPDATE_SCROLLBARS_COUNT

CALLED BY:	MSG_CGV_GET_UPDATE_SCROLLBARS_STATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentGenViewClass
		ax - the message
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVIgnoreUpdateScrollbars		method dynamic ContentGenViewClass,
					MSG_CGV_IGNORE_UPDATE_SCROLLBARS
		
		mov	ax, TEMP_CONTENT_IGNORE_UPDATE_SCROLLBARS_COUNT
		call	ObjVarDerefData
		inc	{byte}ds:[bx]
EC <		ERROR_Z -1						>
NEC <		jnz	done						>
NEC <		dec	{byte}ds:[bx]					>

NEC < done:								>
		ret
CGVIgnoreUpdateScrollbars		endm


ContentLibraryCode	ends

