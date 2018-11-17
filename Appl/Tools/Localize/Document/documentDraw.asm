COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS	
MODULE:		ResEdit/Document
FILE:		documentDraw.asm

AUTHOR:		Cassie Hartzog, Sep 29, 1992

ROUTINES:
	Name			Description
	----			-----------
	GetVisibleRange		Need to determine which elements are in the 
				exposed region. 
	VisDrawCommon		Handles the common functionality for the 
				MSG_VIS_DRAW handlers. 
	VisDrawCallback		This item is in the exposed region and needs to 
				redraw its text. 
	GetMnemonicFromOriginalItem	Need the original item's mnemonic so 
				that it can be underlined. 
	DrawGraphics		Draw some graphics. 
	RecalcChunkPositions	Recalculates the size/position of the chunks 
	RecalcChunkPosCallback	Calculate the new height of a chunk, given the 
				new width. 
	GetOldChunkHeight	Translation item has changed height, and is now 
				smaller than the original item. Check if a 
				redraw needs to be done. 
	GetChunkHeight		Find the height either original or translation 
				item. 
	RecalcChunkHeight	Calculate the new height of a chunk, given the 
				new width. 
	DocumentChangeHighlight	The current highlight needs to be changed 
				because the views are being exposed, or the 
				current chunk is changing, or the height of the 
				current chunk has changed. 
	HighlightCurChunk	Update the highlights in the view associated 
				with the passed gstate. Unhighlight the current 
				highlight, and highlight the new current chunk. 
	DrawHighlight		Draw the highlight around the current chunk. 
	DocumentHeightNotify	Height of the translation item has changed, 
				need to update PosArray and redraw the view, if 
				necessary. 
	UpdatePosArray		Size of an element has changed. Update the 
				PosArray. 
	DocumentSaveChunk	Current chunk has been modified. Save changes 
				to transItem, and update the document instance 
				data and ResourceArrayElement. 
	REDVisUpdateGeometry	Do the normal thing unless we're in batch mode. 
	REVSetDocBounds		Do the normal thing unless we're in batch mode. 
	REDMetaUpdateWindow	Update window if we're not in batch mode. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CH	9/29/92		Initial revision


DESCRIPTION:
        This file contains the part of the code which deals with drawing
        in the two views. It will handle drawing the contents, 
	resizing the views.

	$Id: documentDraw.asm,v 1.1 97/04/04 17:14:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata 	segment
	ResEditViewClass
idata	ends

DocumentDrawCode	segment	resource

DocDraw_ObjMessage_stack		proc	near
	push	di
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	GOTO	DocDraw_ObjMessage_common, di
DocDraw_ObjMessage_stack		endp

DocDraw_ObjMessage_call	proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	DocDraw_ObjMessage_common, di
DocDraw_ObjMessage_call	endp

DocDraw_ObjMessage_common	proc	near
	call	ObjMessage
	FALL_THRU_POP	di
	ret
DocDraw_ObjMessage_common	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetVisibleRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to determine which elements are in the exposed region.

CALLED BY:	(INTERNAL) VisDrawCommon

PASS:		*ds:si	- document
		bx 	- top of exposed region
		dx 	- bottom of exposed region
			(actually, its the top of the next region)

RETURN:		cx	- number of elements to draw
		dx	- starting element

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetVisibleRange		proc	near
	uses	ax,si,di,bp,es
	.enter

	; lock the PosArray
	;
	push	bx
	DerefDoc
	mov	cx, ds:[di].REDI_numChunks
	mov	bx, ds:[di].REDI_posArray
	tst	bx
	jz	noPosArray
	call	MemLock
	mov	es, ax
	pop	bx

	; The value passed in dx is actually the top of the next element.
	; Subtract 1 pixel to get the real element size.
	;
	dec	dx

	clr	ax, si, bp
getRange:
	; check if the top of the element falls within the mask region
	; is so, include it in the range
	;
	mov	bp, es:[si].PE_top
	cmp	bp, bx				;if elt top < mask region top
	jb	before				;  elt starts before region
	cmp	bp, dx				;if elt top > region bottom
	jae	after				;  elt starts after region
	inc 	ax
	jmp	next

before:
	; check if bottom of the element falls before the mask region
	; if so, don't include it in the range
	;
	add	bp, es:[si].PE_height		;get bottom of element,
	add	bp, (SELECT_LINE_WIDTH*2)	;  including select border
	cmp	bp, bx				;if bottom is before region,
	jbe	next				;  element is not in region
	inc	ax				;  else include it
next:
	add	si, size PosElement
	loop	getRange
	
after:
	mov	bx, ds:[di].REDI_posArray
	call	MemUnlock

	; cx = number elements remaining to be examined + 1
	; ax = number of elements to enum

	mov	dx, ds:[di].REDI_numChunks
	sub	dx, cx				;dx=last element in range
	sub	dx, ax				;dx=first-1 element in range
	mov_tr	cx, ax				;cx = number of elements
done:
	.leave
	ret

noPosArray:
	; For some reason, MSG_VIS_DRAW was delivered to the document
	; after it receieved DETACH_UI which frees the PosArray.
	; Just return cx = 0 elements to draw.
	;
	pop	bx
	clr	cx
	jmp	done

GetVisibleRange		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisDrawCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles the common functionality for the MSG_VIS_DRAW
		handlers.

CALLED BY:	DocumentVisDraw, ContentVisDraw

PASS:		*ds:si	= document 
		ds:di	= instance data
		^hbp	= gstate
		cl	= DrawFlags
		dl	= SourceType

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,bp,es

PSEUDO CODE/STRATEGY:
	Find those elements who actually need to be redrawn.
	Call ChunkArrayEnum with a callback routine to 
	actually draw those elements.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisDrawCommon		method	ResEditDocumentClass, 
				MSG_RESEDIT_DOCUMENT_DRAW

	; Do we really want to do this?

	call	IsBatchMode
	jc	done

	cmp	ds:[di].REDI_curResource, PA_NULL_ELEMENT
	LONG	je	done

	tst	ds:[di].REDI_numChunks
	LONG	jz	done

	;
	; start the draw operation - ignore text height changes
	;
	ornf	ds:[di].REDI_state, (mask DS_IGNORE_HEIGHT_CHANGES)

	;
	; set up the parameters to pass on to the callback routine
	;
	mov	di, bp				;^hdi <- gstate
	sub	sp, size VisDrawParams
	mov	bp, sp			

	mov	ss:[bp].VDP_gstate, di
	mov	ss:[bp].VDP_data.SDP_sourceType, dl
	mov	ss:[bp].VDP_drawFlags, cl
	mov	bx, ds:[LMBH_handle]
	movdw	ss:[bp].VDP_document, bxsi

	;
	; get the top and bottom coords of the exposed region,
	; and the number of elements visible in this region
	;
	call	GrGetMaskBounds			;bx = top, dx = bottom
	call	GetVisibleRange			;cx<- # elts, dx<- starting elt
	tst	cx				
	LONG	jz	noDraw

	DerefDoc
	mov	bx, ds:[di].REDI_resourceGroup
	mov	ss:[bp].VDP_data.SDP_group, bx

	mov	bx, ds:[di].REDI_curChunk
	mov	ss:[bp].VDP_curChunk, bx

	;
	; lock the ResourceArray for this resource
	;
	call	GetFileHandle
	mov	ss:[bp].VDP_data.SDP_file, bx
	mov	ax, ds:[di].REDI_resourceGroup
	mov	di, ds:[di].REDI_resArrayItem
	call	DBLock_DS			;*ds:si = array

	mov	ss:[bp].VDP_chunkNum, -1	
	mov	bx, cs
	mov	di, offset VisDrawCallback

	;
	; bx:di = callback, *ds:si = array, *ss:bp = VisDrawParams
	; dx = starting element, cx = number of elements in range
	;
	call	ChunkArrayEnum
	call	DBUnlock_DS

	movdw	bxsi, ss:[bp].VDP_document
	call	MemDerefDS
	DerefDoc

	;
	; Return the target and focus to its rightful owner.
	;
	mov	dl, ss:[bp].VDP_data.SDP_sourceType	;dl <- ST being drawn
	call	InitializeEdit

	call	InitializeMnemonicList			;reset mnemonic list

	;
	; get some info before nuking VDP
	;
	mov	cx, ss:[bp].VDP_curChunk	; cx is for HighlightCurChunk
	mov	bp, ss:[bp].VDP_gstate

	add	sp, size VisDrawParams

	mov	dx, PA_NULL_ELEMENT
	call	HighlightCurChunk		;draw highlight

done:
	DerefDoc
	andnf	ds:[di].REDI_state, not (mask DS_IGNORE_HEIGHT_CHANGES)
	ret

noDraw:
	
	add	sp, size VisDrawParams		;restore sp
	jmp	done

VisDrawCommon		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisDrawCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This item is in the exposed region and needs to
		redraw its text.

CALLED BY:	ChunkArrayEnum (VisDrawCommon)
PASS:		*ds:si	= ResourceArray
		ds:di	= ResourceArrayElement
		ss:bp	= VisDrawParams
		cx	= number of elements to draw
		dx	= starting number

RETURN:		cx,dx,ss,bp unchanged

DESTROYED:	di,si,ax,bx,es

PSEUDO CODE/STRATEGY:
	Check if this element meets the filter criteria.
	Increment the match count.
	Check whether it is within the range of elements to be drawn.
	Draw it.
	If it was the last element in the range, set the carry flag
	to end the enumeration.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisDrawCallback		proc	far
	uses	cx, dx
	.enter

	push	ds:[LMBH_handle]

	push	si,ds
	movdw	bxsi, ss:[bp].VDP_document
	call	MemDerefDS
	mov	si, ds:[si]
	add	si, ds:[si].ResEditDocument_offset
	mov	al, ds:[si].REDI_stateFilter
	mov	ah, ds:[si].REDI_typeFilter
	pop	si, ds

	;
	; does this element meet the filter criteria?
	;
	call	FilterElement
	LONG	jnc	done
	inc	ss:[bp].VDP_chunkNum			;another match!

	; 
	; is this element within the range of elements to be redrawn?
	;
	cmp	ss:[bp].VDP_chunkNum, dx		;dx <- first element #
	clc
	LONG	jl	done

	;
	; save the number of the last element to be drawn
	; dx = starting element #, cx = # elements to draw
	mov	ax, dx				
	add	ax, cx
	push	ax					;ax <- last element #

EC <	call	ChunkArrayGetCount			>
EC <	cmp	ss:[bp].VDP_chunkNum, cx		>
EC <	ERROR_AE RESEDIT_OUT_OF_ARRAY_BOUNDS		>

	;
	; Get ChunkType and the item number for this element.
	; If there is no translation item, use the original item
	;
	mov	al, ds:[di].RAE_data.RAD_chunkType
	mov	ss:[bp].VDP_data.SDP_chunkType, al
	mov	bx, ds:[di].RAE_data.RAD_origItem
	cmp	ss:[bp].VDP_data.SDP_sourceType, ST_ORIGINAL
	je	haveItem
	tst	ds:[di].RAE_data.RAD_transItem
	jz	haveItem
	mov	bx, ds:[di].RAE_data.RAD_transItem

haveItem:
	test	al, mask CT_TEXT
	jz	storeItem

	mov	cx, ds:[di].RAE_data.RAD_maxSize
	mov	ss:[bp].VDP_data.SDP_maxLength, cx

	; We have the item number, now get the mnemonic if it has one.
	; 
	test	al, mask CT_MONIKER
	jz	storeItem
	;
	; RAD_mnemonicType and -Char are for the transItem.
	; The mnemonic for the origItem is stored in the
	; item's VisMoniker structure.
	;
	mov	cl, ds:[di].RAE_data.RAD_mnemonicType
SBCS <	mov	ch, ds:[di].RAE_data.RAD_mnemonicChar			>
DBCS <	mov	dx, ds:[di].RAE_data.RAD_mnemonicChar			>
	cmp	bx, ds:[di].RAE_data.RAD_transItem	; is it transItem?
	je	haveMnemonic			; yes, we have the mnemonic
	push	bp			
	lea	bp, ss:[bp].VDP_data
	call	GetMnemonicFromOriginalItem	;cl <-mnemType, ch/dx <-mnemChar
	pop	bp

haveMnemonic:
	clr	ss:[bp].VDP_data.SDP_mnemonicCount
	clr	ss:[bp].VDP_data.SDP_mnemonicPos
	mov	ss:[bp].VDP_data.SDP_mnemonicType, cl
SBCS <	mov	ss:[bp].VDP_data.SDP_mnemonicChar, ch			>
DBCS <	mov	ss:[bp].VDP_data.SDP_mnemonicChar, dx			>

storeItem:
	mov	ss:[bp].VDP_data.SDP_item, bx

	; get info from the document and stuff it into SetDataParams
	;
	movdw	bxdi, ss:[bp].VDP_document
	call	MemDerefDS
	mov	di, ds:[di]
	add	di, ds:[di].ResEditDocument_offset
	mov	cx, ds:[di].REDI_viewWidth

	; get the PosArray element for the element number in ax
	; (PosArray contains only those elements that meet the filter criteria)
	mov	ax, ss:[bp].VDP_chunkNum
	mov	bx, ds:[di].REDI_posArray
	mov	dl, size PosElement
	mul	dl
	mov	si, ax
	call	MemLock
	mov	es, ax					;es:si <- PosElement

	mov	ss:[bp].VDP_data.SDP_left, SINGLE_BORDER_SIZE	
	mov	ss:[bp].VDP_data.SDP_border, SINGLE_BORDER_SIZE	
	mov	dx, es:[si].PE_top		
	mov	ss:[bp].VDP_data.SDP_top, dx		;top position of 
	mov	ax, es:[si].PE_height	
	mov	ss:[bp].VDP_data.SDP_height, ax		;height of chunk
	sub	cx, TOTAL_BORDER_SIZE
	mov	ss:[bp].VDP_data.SDP_width, cx		;width of view
	
	call	MemUnlock

	; Is it text, or is it a graphic?
	;
	mov	al, ss:[bp].VDP_data.SDP_chunkType
	test	al, mask CT_TEXT or mask CT_OBJECT
	jz 	tryBitmap			

	mov	bx, ds:[di].REDI_editText.handle
	mov	si, offset TransDrawText
	cmp	ss:[bp].VDP_data.SDP_sourceType, ST_TRANSLATION
	je	drawIt
	mov	si, offset OrigDrawText
drawIt:
	mov	ax, MSG_RESEDIT_TEXT_DRAW
	call	DocDraw_ObjMessage_call
	jmp	doneDrawing

tryBitmap:
	test	al, mask CT_BITMAP or mask CT_GSTRING
	jz	doneDrawing
	call	DrawGraphics

doneDrawing:
	pop	ax
	dec	ax				
	cmp	ss:[bp].VDP_chunkNum, ax	;is this the last element?
	clc					;carry clear to continue 
	jne	done				;no, continue
	stc					;yes, carry set to stop

done:
	pop	bx
	call	MemDerefDS
	.leave
	ret
		
VisDrawCallback		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMnemonicFromOriginalItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need the original item's mnemonic so that it can 
		be underlined.

CALLED BY:	VisDrawCallback, InitializeOrigText

PASS:		ss:bp	- SetDataParams
		bx	- original item

RETURN:		cl	- mnemonicType
		ch	- mnemonicChar (SBCS)
		dx	- mnemonicChar (DBCS)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMnemonicFromOriginalItem		proc	far
	uses	ax,bx,di,es
	.enter

EC <	tst	bx					>
EC <	ERROR_Z INVALID_ITEM				>

	clr	cx
	cmp	ss:[bp].SDP_chunkType, mask CT_MONIKER or mask CT_TEXT
	jne	done

	mov	di, bx
	mov	ax, ss:[bp].SDP_group
	mov	bx, ss:[bp].SDP_file
	call	DBLock	
	mov	di, es:[di]

SBCS <	mov	ch, es:[di].VM_data.VMT_mnemonicOffset			>
DBCS <	clr	dh							>
DBCS <	mov	dl, es:[di].VM_data.VMT_mnemonicOffset			>
	mov	cl, es:[di].VM_data.VMT_mnemonicOffset
	cmp	cl, VMO_MNEMONIC_NOT_IN_MKR_TEXT
	jne	unlock

	ChunkSizePtr	es, di, bx
	LocalPrevChar	esbx
	add	di, bx
SBCS <	mov	ch, {byte}es:[di]					>
DBCS <	mov	dx, {word}es:[di]					>
unlock:
	call	DBUnlock
done:
	.leave
	ret
GetMnemonicFromOriginalItem		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawGraphics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw some graphics.

CALLED BY:	VisDrawCallback

PASS:		ss:bp	- VisDrawParams

RETURN:		nothing

DESTROYED:	ax,bx,dx

PSEUDO CODE/STRATEGY:
	If the item is a bitmap, read it into a gstring first.
	Then draw the gstring, leaving a border for drawing a highlight.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawGraphics		proc	far
	uses	si, di, ds
	.enter

	; lock down the item containing the bitmap or gstring
	;
	mov	bx, ss:[bp].VDP_data.SDP_file
	mov	ax, ss:[bp].VDP_data.SDP_group
	mov	di, ss:[bp].VDP_data.SDP_item
	call	DBLock_DS			;*ds:si <- item
	mov	si, ds:[si]
	test	ss:[bp].VDP_data.SDP_chunkType, mask CT_BITMAP
	jnz	drawBitmap

	test	ss:[bp].VDP_data.SDP_chunkType, mask CT_MONIKER
	jz	notMoniker
	add	si, MONIKER_GSTRING_OFFSET
notMoniker:
EC <	mov	ax, si				> ;ds:ax <- gstring
	mov	cl, GST_PTR
	mov	bx, ds				;bx:si <- gstring data
	call	GrLoadGString			;^hsi <- gstring

	; get the bounds of the drawn gstring 
	;
	clr	di	
	clr	dx				;go through entire string
	call	GrGetGStringBounds
;EC <	ERROR_C	DRAW_GRAPHICS_ERROR			>
EC <	jnc	okay					>
EC <	clr	bx					>
EC <okay:						>
	; GrGetGStringBounds returns:
	; ax - left side coord of smallest rect enclosing string
	; bx - top coord, cx - right coord, dx - bottom coord
	;
	; now adjust these coordinates so that the gstring
	; is drawn relative to the element's offset in the view
	;
	neg	ax
	neg	bx
	add	ax, ss:[bp].VDP_data.SDP_left	;x position
	add	bx, ss:[bp].VDP_data.SDP_top	;y position
	add	bx, ss:[bp].VDP_data.SDP_border

	push	ax
	mov	di, ss:[bp].VDP_gstate
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos
	pop	ax

	clr	dx				;no callback routine
	call	GrDrawGString
EC <	cmp	dx, GSRT_FAULT				>
EC <	ERROR_E	DRAW_GRAPHICS_ERROR			>

	mov	dl, GSKT_LEAVE_DATA
	clr	di
	call	GrDestroyGString

done:
	call	DBUnlock_DS

	.leave
	ret

drawBitmap:
	; if it is a bitmap, pass the x, y position in ax, bx
	; and draw the bitmap
	;
	clr	dx				;no callback
	mov	ax, ss:[bp].VDP_data.SDP_left	;x position
	mov	bx, ss:[bp].VDP_data.SDP_top	;y position
	add	bx, ss:[bp].VDP_data.SDP_border
	mov	di, ss:[bp].VDP_gstate
	call	GrDrawBitmap
	jmp	done
DrawGraphics		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcChunkPositions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculates the size/position of the chunks

CALLED BY:	(EXTERNAL) DocumentViewSizeChanged, DocumentChangeResource
PASS:		*ds:si 	= document object
		ds:di 	= document instance data
		cx 	= new view width

RETURN:		dx 	= calculated height

DESTROYED:	di,bp,es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	For each item in the ResourceArray for the current resource
	that meets the filter criteria, 
	recalc the height of its text at the given width.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CH	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcChunkPositions	proc	far
	uses	ax,bx,cx,si,bp
	.enter

	; Bypass all this if we're in batch mode.

		call	IsBatchMode
		jc	exit

	push	ds:[LMBH_handle], si
	DerefDoc
	mov	dx, ds:[di].REDI_numChunks
	tst	dx
	LONG	jz	noChunks

	;
	; setup the parameters for the callback
	;
	sub	sp, size RecalcPosParams
	mov	bp, sp

	mov	bx, ds:[LMBH_handle]	
	movdw	ss:[bp].RPP_document, bxsi
	mov	ss:[bp].RPP_count, dx
	mov	ss:[bp].RPP_element, -1
	mov	al, ds:[di].REDI_stateFilter
	mov	ah, ds:[di].REDI_typeFilter
	mov	ss:[bp].RPP_filters, ax
	mov	bx, ds:[di].REDI_posArray
	mov	ss:[bp].RPP_posArray, bx

	call	MemLock
	mov	es, ax

	;
	; Recalc the height of all of the chunks in this resource.
	; pass *ss:bp = RecalcPosParams, cx = width, es = PosArray segment
	;
	call	GetFileHandle				;^hbx <- file handle
	mov	ax, ds:[di].REDI_resourceGroup
	mov	di, ds:[di].REDI_resArrayItem	
	call	DBLock_DS				;*ds:si = ResourceArray
	mov	bx, cs
	mov	di, offset RecalcChunkPosCallback	
	clr	dx					;start with dx = 0 
	call	ChunkArrayEnum				;dx <- bottom last elt
	call	DBUnlock_DS
	mov	bx, ss:[bp].RPP_posArray
	call	MemUnlock
	
	add	sp, size RecalcPosParams

	;
	; put the new height in dx, set the new document bounds
	;
	pop	bx, si
	call	MemDerefDS
	mov	ax, MSG_VIS_SET_SIZE
	call	SendToContentObjects

done:
	;
	; now set the new doc bounds in the two views
	;
	DerefDoc
	mov	ds:[di].REDI_docHeight, dx

	mov	bx, ds:[di].GDI_display
	mov	si, offset RightView			;^lbx:si <- RightView

	mov	cx, ds:[di].REDI_viewWidth
	push	cx, dx					;cx,dx <- width, height
	mov	di, mask MF_FIXUP_DS
	call	GenViewSetSimpleBounds
	pop	cx, dx
	mov	si, offset LeftView			;^lbx:si <- LeftView
	mov	di, mask MF_FIXUP_DS
	call	GenViewSetSimpleBounds

exit:
	.leave
	ret

noChunks:
	pop	bx, si
	call	MemDerefDS
	clr	cx
	clr	dx
	mov	ax, MSG_VIS_SET_SIZE
	call	SendToContentObjects
	jmp	done
RecalcChunkPositions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcChunkPosCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the new height of a chunk, given the new width.

CALLED BY:	(INTERNAL) RecalcChunkPositions (via ChunkArrayEnum)

PASS:		*ds:si	= ResourceArray
		ds:di	= ResourceArrayElement being enumerated
		ss:bp	= RecalcPosParams
		cx 	= new view width
		dx	= top of this element
		es	= segment of locked PosArray

RETURN:		dx 	= bottom of this element
		carry	- set to end (always returned clear)

DESTROYED:	ax,bx,si,di - by ChunkArrayEnum

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Recalc the height of both the original and translated item.
	The max height of the two + the passed top + 2*SELECT_LINE_WIDTH
	is the next item's top, and is returned in dx.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcChunkPosCallback	proc	far
	
	push	cx				;save view width

	;
	; if this element does not meet the filter criteria,
	; don't need its height for the PosArray
	;
	mov	ax, ss:[bp].RPP_filters
	call	FilterElement
	jnc	done
	inc	ss:[bp].RPP_element		;inc # elements in  PosArray

	;
	; calculate height of the translation item, if there is one
	; (transItem = 0, no changes have been made from the original)
	;
	push	dx
	mov	bl, ds:[di].RAE_data.RAD_chunkType
	mov	ax, ds:[di].RAE_data.RAD_transItem
	tst	ax
	jz	noTransItem
EC<	mov	bh, ST_TRANSLATION				>
	movdw	dxsi, ss:[bp].RPP_document
	call	RecalcChunkHeight		; dx <- height
	mov	ax, dx				

noTransItem:
	; calulate height of the original item, take the max of the two
	;
	push	ax				;save transItem height
	mov	ax, ds:[di].RAE_data.RAD_origItem
	movdw	dxsi, ss:[bp].RPP_document
EC<	mov	bh, ST_ORIGINAL					>
	call	RecalcChunkHeight		;dx <- origItem height
	pop	cx				;cx <- transItem height
	cmp	cx, dx
	jae	haveHeight	
	mov	cx, dx				; cx <- max height

haveHeight:	
	pop	dx

	;
	; get the PosArray element for this chunk
	;
	push	dx
	mov	ax, ss:[bp].RPP_element
	mov	di, size PosElement
	mul	di				; ax <- offset of element
	mov	si, ax
	pop	dx

	; Save my height.  My top position is the passed-in bottom
	; plus 2 select line-widths for the select rectangle.  
	; Return my bottom position in bp.
	;
	mov	es:[si].PE_height, cx		;save chunk height
	mov	es:[si].PE_top, dx		;store my top position
	add	dx, cx 				;dx <- my bottom
	add	dx, (SELECT_LINE_WIDTH*2)	;leave room for highlight
	
	;
	; see if this is the last element which meets the filter
	; criteria, so that the enumeration can be terminated
	;
	mov	ax, ss:[bp].RPP_element
	inc	ax				;ordinal number
	cmp	ax, ss:[bp].RPP_count
	jl	done

	pop	cx				;restore width
	stc
	ret

done:
	pop	cx				;restore width
	clc
	ret

notEditable::
	mov	cx, NOT_EDITABLE_CHUNK_HEIGHT
	jmp	haveHeight
RecalcChunkPosCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOldChunkHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translation item has changed height, and is now smaller 
		than the original item.  Check if a redraw needs to be done.

CALLED BY:	INTERNAL (DocumentHeightNotify)

PASS:		dx	- OrigItem height
		ds:di	- ResEditDocument

RETURN:		carry set if need to redraw, and 
		cx - height to use (height of OrigItem)

DESTROYED:	ax,bx,dx,bp,es

PSEUDO CODE/STRATEGY:
	Compare size of the old translation item to the original item's size.
	If old trans item height > original item height, a resize is needed.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetOldChunkHeight		proc	near

	mov	cx, dx				;cx <- size of orig item
	mov	bx, ds:[di].REDI_posArray
	call	MemLock
	mov	es, ax
	mov	ax, ds:[di].REDI_curChunk	;ax <- chunk which changed
	mov	dl, size PosElement
	mul	dl
	mov	bp, ax				;es:bp <- PosArray element
	mov	dx, es:[bp].PE_height		;dx <- old trans item height
	call	MemUnlock
	cmp	cx, dx				;is orig item < old trans item
	jb	resize				;yes, need to resize
	clc
	ret

resize:
	stc
	ret

GetOldChunkHeight		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChunkHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the height either original or translation item.

CALLED BY:	EXTERNAL (DocumentHeightNotify, DocumentRedrawCurrentChunk)
PASS:		ds:di	- document
		carry set to get the original item's height
		carry clear to get the translation item's height
		   (will return original item's height if no trans item)

RETURN:		dx	- height
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChunkHeight		proc	far
	uses	ax,bx,cx,si
	.enter

	mov	dx, ds:[LMBH_handle]		;^ldx:si <- document
	mov	cx, ds:[di].REDI_viewWidth
	mov	bl, ds:[di].REDI_chunkType
	mov	ax, ds:[di].REDI_origItem
	jc	getHeight
	tst	ds:[di].REDI_transItem
	jz	getHeight
	mov	ax, ds:[di].REDI_transItem
getHeight:
	call	RecalcChunkHeight		;dx <- origItem height

	.leave
	ret
GetChunkHeight		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcChunkHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the new height of a chunk, given the new width.

CALLED BY:	(INTERNAL) 
PASS: 		^ldx:si	- document
		ax	= chunk item number
		cx	= new width
		bl	= chunk type

RETURN:		dx	= height

DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Calculate the height of the object at the passed view width
	less the total size of the left and right borders.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecalcChunkHeight	proc	far
	uses	bx,cx,bp,si,di,ds
	.enter

EC <	tst	ax						>
EC <	ERROR_Z INVALID_ITEM					>

	push	bx
	mov	bx, dx
	call	MemDerefDS
	DerefDoc
	pop	dx

	sub	sp, size SetDataParams
	mov	bp, sp

	sub	cx, TOTAL_BORDER_SIZE		;subtract off L/R border size
	mov	ss:[bp].SDP_width, cx
	mov	cx, ds:[di].REDI_resourceGroup	; group number
	mov	ss:[bp].SDP_group, cx
	mov	ss:[bp].SDP_item, ax
	mov	ss:[bp].SDP_chunkType, dl
EC<	mov	ss:[bp].SDP_sourceType, dh				>

	call	GetFileHandle
	mov	ss:[bp].SDP_file, bx

	mov	bx, ds:[di].REDI_editText.handle

	test	dl, mask CT_TEXT or mask CT_OBJECT
	jz	tryGraphics

	;
	; Replace the text in HeightText, which we use for calculating height
	; and printing, with the text in the item.
	; (if CT_OBJECT, text is textual representation of its kbdShortcut)
	;
	GetResourceHandleNS	HeightText, bx
	mov	si, offset HeightText
	mov	dx, size SetDataParams
	mov	ax, MSG_RESEDIT_TEXT_RECALC_HEIGHT
	call	DocDraw_ObjMessage_stack
	jmp	done

tryGraphics:	
	test	dl, mask CT_BITMAP or mask CT_GSTRING
	jz	unknown
	GetResourceHandleNS	HeightGlyph, bx
	mov	si, offset HeightGlyph
	mov	dx, size SetDataParams
	mov	ax, MSG_RESEDIT_GLYPH_RECALC_HEIGHT
	call	DocDraw_ObjMessage_stack

done:
	; add an extra border so highlight won't overlap element
	;
	add	dx, SELECT_LINE_WIDTH

	add	sp, size SetDataParams

	.leave
	ret
unknown:
	clr	dx
	jmp	done

RecalcChunkHeight		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentChangeHighlight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current highlight needs to be changed because the
		views are being exposed, or the current chunk is changing,
		or the height of the current chunk has changed.

CALLED BY:	(EXTERNAL) DocumentChangeChunk, DocumentHeightNotify

PASS:		*ds:si	- document
		cx	- new element to highlight
		dx	- old element to unhighlight
		
RETURN:		nothing
DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentChangeHighlight		proc	far
	uses	di,bp
	.enter

	; create a gstate for the document's view and draw highlights
	;
	push	cx, dx
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock			;^hbp <- gstate
	pop	cx, dx

	call	HighlightCurChunk
	mov	di, bp
	call	GrDestroyState

	DerefDoc

	; create a gstate for the content's view and draw highlights
	;
	push	cx, dx, si
	mov	bx, ds:[di].REDI_editText.handle
	mov	si, offset OrigContent
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	DocDraw_ObjMessage_call
	pop	cx, dx, si

	call	HighlightCurChunk
	mov	di, bp					;^hdi <- orig. gstate
	call	GrDestroyState

	.leave
	ret
DocumentChangeHighlight		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighlightCurChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the highlights in the view associated with the passed
		gstate.  Unhighlight the current highlight, and highlight 
		the new current chunk.

CALLED BY:	(EXTERNAL) DocumentChangeHighlight, VisDrawCommon

PASS:		*ds:si - instance data
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx - element to highlight
		dx - element to unhighlight
		^hbp - gstate 
		     or 0 if one should be created

RETURN:		nothing

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
	If VisDrawCommon calls this routine, it will pass a gstate.
	If either cx or dx is 0, don't draw/undraw the highlight.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighlightCurChunk	proc	near
	uses	cx,dx,si,di,bp
	.enter

	DerefDoc
	mov	bx, ds:[di].REDI_viewWidth

	sub	sp, size Rectangle
	mov	di, sp

	; initialize the highlight bounds
	;
	clr	ss:[di].R_left				;left is always 0
	sub	bx, SELECT_LINE_WIDTH			;move right in
	mov	ss:[di].R_right, bx

	mov	bx, cx					;bx <- to be highlighted
	mov	ax, dx					;ax <- cur highlight
	xchg	di, bp					;ss:bp <- rectangle
							;^hdi <- gstate

	; find out if the highlighted chunk is still visible
	; so no unnecessary drawing is done to remove its highlight
	;
	push	bx					;save curChunk
	cmp	ax, PA_NULL_ELEMENT
	je 	notVisible
	call	IsChunkVisible
	cmp	cl, VT_NOT_VISIBLE
	je	notVisible
	
	; get the bounds of the current highlight rectangle	

	call	GetChunkBounds				;cx, dx <- top,bottom
	mov	ss:[bp].R_top, cx
	sub	dx, SELECT_LINE_WIDTH			;move bottom up
	mov	ss:[bp].R_bottom, dx

	; first clear the current highlight 
	mov	bl, HS_CLEAR
	call	DrawHighlight

notVisible:
	; see if there is a current chunk that needs to be highlighted
	; there won't be if this is called by REDQueryMoniker, which
	; is changing resources and wants to clear the screen 
	;
	pop	ax					;ax <- new curChunk
	cmp	ax, PA_NULL_ELEMENT
	je	done
	call	GetChunkBounds	
	mov	ss:[bp].R_top, cx			;cx <- current top
	sub	dx, SELECT_LINE_WIDTH			;move bottom up
	mov	ss:[bp].R_bottom, dx			

	; now draw the highlight rectangles on the current chunk
	mov	bl, HS_SET
	call	DrawHighlight
done:
	add	sp, size Rectangle

	.leave
	ret
HighlightCurChunk		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHighlight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the highlight around the current chunk.

CALLED BY:	(INTERNAL) HighlightCurChunk

PASS:		di	= gstate
		bl	= HighlightState
		ss:bp	= Rectangle to draw

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawHighlight		proc	near
	uses	ax,bx,cx,dx
	.enter

	call	GrSaveState
	
	mov	ax, (CF_INDEX shl 8) or C_BLACK		;set the highlight
	cmp	bl, HS_SET			
	je	draw
	mov	ax, (CF_INDEX shl 8) or C_WHITE		;clear the highlight
	
draw:
	call	GrSetLineColor
	mov	al, MM_COPY
	call	GrSetMixMode
	clr	ax
	mov	dx, SELECT_LINE_WIDTH
	call	GrSetLineWidth
	mov	al, LJ_BEVELED
	call	GrSetLineJoin

	mov	ax, ss:[bp].R_left 
	mov	bx, ss:[bp].R_top
	mov	cx, ss:[bp].R_right
	mov	dx, ss:[bp].R_bottom
	call	GrDrawRect
	call	GrRestoreState

	.leave
	ret

DrawHighlight		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Height of the translation item has changed, need to update
		PosArray and redraw the view, if necessary.

CALLED BY:	MSG_RESEDIT_DOCUMENT_HEIGHT_NOTIFY
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		dx - new height

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	If the OrigItem is the larger of the two, and the TransItem is
	getting smaller, there is no need to update the PosArray and
	size of the document, content and views.  Only if changes to
	the translation item require the view to grow or shrink does that 
	stuff need to be done.

	Take focus from EditText, so that cursor is off.
	Mark the entire image invalid so it is undrawn.
	Get the height of the OrigItem, compare it to passed new
	TransItem height and take the maximum.
	Find the height of this element in PosArray.
	If the max is the same as the height in PosArray, skip this part:
		Recalculate tops of all elements below this in PosArray.
		Set the new size in the document and content.
		Set the new size in the views.
		Mark the content and document images invalid (necessary if
		they are larger now).
		Make the curChunk visible, in case size changed forced it
		partially off screen.
	Update the document and content windows.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentHeightNotify		method dynamic ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_HEIGHT_NOTIFY

	; if not currently editing, don't care if height has changed.
	; (as when using the text object to draw the text on screen)
	;
	test	ds:[di].REDI_state, mask DS_IGNORE_HEIGHT_CHANGES
	LONG	jnz	done

	; check if the translation item is larger than the original item,
	; in which case its size is the size used for both
	;
	mov	cx, dx				;cx <- new height
	stc					;get only orig item's height
	call	GetChunkHeight			;dx <- height of orig item
	cmp	dx, cx				;is OrigItem < TransItem?
	jb	redraw				;yes, a redraw is needed

	; TransItem is smaller than OrigItem.  See if it has changed 
	; from being larger than OrigItem to being smaller.
	;
	call	GetOldChunkHeight		;cx <- height to use
	LONG	jnc	done

redraw:
	; The size of EditText needs to either grow or shrink.
	;
	push	cx				;save new height
	movdw	cxdx, ds:[di].REDI_editText
	mov	bp, mask MAEF_FOCUS
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock

	; undraw the highlight on the current chunk in both views
	;
	mov	dx, ds:[di].REDI_curChunk	;unhighlight this element
	mov	cx, PA_NULL_ELEMENT		;don't draw new highlight
	call	DocumentChangeHighlight

	; At some point, add code to invalidate only the part that needs
	; to be redrawn, instead of the entire image.
	;
        mov     ax, MSG_VIS_MARK_INVALID       
        mov     cl, mask VOF_IMAGE_INVALID      ; image is invalid
	mov	dl, VUM_NOW
	call	SendToContentObjects
	pop	dx

	call	UpdatePosArray			; dx <- new doc height
	jc	updateWindow			; no change? proceed

	; set the new document bounds
	;
	mov	cx, ds:[di].REDI_viewWidth	; cx, dx <- height, width
	mov	ax, MSG_VIS_SET_SIZE
	call	SendToContentObjects

	push	si, di
	movdw	bxsi, ds:[di].GCI_genView
	mov	di, mask MF_FIXUP_DS
	call	GenViewSetSimpleBounds
	pop	si, di

	; now invalidate the new image, which could be larger than the
	; old, and would not be invalidated by the MARK_INVALID above
	;
        mov     ax, MSG_VIS_MARK_INVALID       
        mov     cl, mask VOF_IMAGE_INVALID      ; image is invalid
	mov	dl, VUM_MANUAL			; let it happen with update
	call	SendToContentObjects

	; should this come _after_ the update??
	;
	mov	cx, ds:[di].REDI_curChunk
	call	MakeChunkVisible		; make this chunk visible

updateWindow:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	call	SendToContentObjects

done:	
	ret

DocumentHeightNotify		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePosArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Size of an element has changed.  Update the PosArray.

CALLED BY:	DocumentHeightNotify.
PASS:		ds:di	- document
		dx - new height

RETURN:		dx - total height of view
		carry set if height did not change

DESTROYED:	ax,cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePosArray		proc	near
	uses	bx,bp,es
	.enter

	;
	; given the new height of current chunk, change the position
	; of each subsequent element in the PosArray
	;
	mov	bx, ds:[di].REDI_posArray
	call	MemLock
	mov	es, ax

	mov	ax, ds:[di].REDI_curChunk	;ax <- chunk which changed
	mov	cx, ds:[di].REDI_numChunks
	sub	cx, ax
	dec	cx				;cx <- # of chunks to update

	push	dx
	mov	dl, size PosElement
	mul	dl
	mov	bp, ax				;es:bp <- PosArray element
	pop	dx				

	cmp	dx, es:[bp].PE_height		;did max height change?
	stc
	je	noMore				;no, don't change anything

	mov	es:[bp].PE_height, dx		;save the new height
	add	dx, es:[bp].PE_top
	add	dx, (SELECT_LINE_WIDTH*2)	;get my bottom
	tst	cx				;any more elements to update?
	jz	noMore
	add	bp, size PosElement		;go to next element

next:
	mov	es:[bp].PE_top, dx		;save its new top
	add	dx, es:[bp].PE_height		;add its height
	add	dx, (SELECT_LINE_WIDTH*2)	;add select border
						;now dx = next top
	add	bp, size PosElement		
	loop	next
	clc

noMore:
	call	MemUnlock

	.leave
	ret
UpdatePosArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentSaveChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Current chunk has been modified.  Save changes to transItem,
		and update the document instance data and ResourceArrayElement.

CALLED BY:	FinishEditText, ViewSizeChanged, DocumentGetMnemonic,
		DocumentSearch

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		nothing

DESTROYED:	ax,bx,si,di,ds,es (by message handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentSaveChunk		method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_SAVE_CHUNK
	uses	dx, bp
	.enter

	clr	cx
	cmp	ds:[di].REDI_curChunk, PA_NULL_ELEMENT
	LONG	je	done

	; If the chunk is an object, it has a keyboard shortcut, which
	; gets saved at the time it is changed.
	;
	test	ds:[di].REDI_chunkType, mask CT_OBJECT
	LONG	jnz	done

	; if chunk is not text, it can't have been edited
	; (graphics can be cut or pasted, in which case the changes
	; are saved at that point)
	;
	test	ds:[di].REDI_chunkType, mask CT_TEXT
	LONG	jz	done

	call	ObjMarkDirty

	; set up common params
	;
	sub	sp, size SetDataParams
	mov	bp, sp
	mov	dx, size SetDataParams

	mov	ax, ds:[di].REDI_resourceGroup
	mov	ss:[bp].SDP_group, ax
	mov	ax, ds:[di].GDI_fileHandle
	mov	ss:[bp].SDP_file, ax
	mov	al, ds:[di].REDI_chunkType
	mov	ss:[bp].SDP_chunkType, al

	mov	cl, ds:[di].REDI_state
	mov	ss:[bp].SDP_state, cl
	mov	cx, ds:[di].REDI_transItem
	mov	ss:[bp].SDP_item, cx
	mov	cx, ds:[di].REDI_origItem

	; now add text moniker-only parameters
	;
	mov	al, ds:[di].REDI_mnemonicType
	mov	ss:[bp].SDP_mnemonicType, al
	mov	al, ds:[di].REDI_mnemonicPos
	mov	ss:[bp].SDP_mnemonicPos, al
	mov	al, ds:[di].REDI_mnemonicCount
	mov	ss:[bp].SDP_mnemonicCount, al
SBCS <	mov	al, ds:[di].REDI_mnemonicChar				>
DBCS <	mov	ax, ds:[di].REDI_mnemonicChar				>
SBCS <	mov	ss:[bp].SDP_mnemonicChar, al				>
DBCS <	mov	ss:[bp].SDP_mnemonicChar, ax				>

	push	si
	movdw 	bxsi, ds:[di].REDI_editText
	mov	ax, MSG_RESEDIT_TEXT_SAVE_TEXT		;cx <- item
							;dx <- new mnemonic
							;ah <- mnemType (DBCS)
	call	DocDraw_ObjMessage_stack
	pop	si

	add	sp, size SetDataParams

	; save new transItem, new mnemonic in document instance data
	; and the ResourceArrayElement
	; 
	mov	ds:[di].REDI_transItem, cx	;cx <- possibly new transItem
	push	cx				;save the transItem
DBCS <	push	ax				;save mnemonicType	>
	mov	ax, ds:[di].REDI_curChunk
	call	DerefElement			;ds:di <- ResourceArrayElement
DBCS <	pop	ax				;restore mnemonicType	>

	pop	ds:[di].RAE_data.RAD_transItem	; store the new transItem
SBCS <	mov	ds:[di].RAE_data.RAD_mnemonicType, dh			>
DBCS <	mov	ds:[di].RAE_data.RAD_mnemonicType, ah			>
SBCS <	mov	ds:[di].RAE_data.RAD_mnemonicChar, dl			>
DBCS <	mov	ds:[di].RAE_data.RAD_mnemonicChar, dx			>
	call	DBDirty_DS
	call	DBUnlock_DS

done:
	.leave
	ret

DocumentSaveChunk		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDVisUpdateGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the normal thing unless we're in batch mode.

CALLED BY:	MSG_VIS_UPDATE_GEOMETRY
PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	9/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDVisUpdateGeometry	method dynamic ResEditDocumentClass, 
					MSG_VIS_UPDATE_GEOMETRY
		.enter

	; Are we in batch mode?

		call	IsBatchMode
		jc	dontProcess

	; Let the superclass do its thing, which it does so well.

		mov	di, offset ResEditDocumentClass
		call	ObjCallSuperNoLock

done:
		.leave
		ret

dontProcess:
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID)	
		jmp	done

REDVisUpdateGeometry	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDGenViewSetDocBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the normal thing unless we're in batch mode.

CALLED BY:	MSG_GEN_VIEW_SET_DOC_BOUNDS
PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	9/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REVSetDocBounds	method dynamic ResEditViewClass, 
					MSG_GEN_VIEW_SET_DOC_BOUNDS
		.enter

	; Are we in batch mode?

		call	IsBatchMode
		jc	done

	; Let the superclass do its thing, which it does so well.

		mov	di, offset ResEditViewClass
		call	ObjCallSuperNoLock

done:
		.leave
		ret
REVSetDocBounds	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDMetaUpdateWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update window if we're not in batch mode.

CALLED BY:	MSG_META_UPDATE_WINDOW
PASS:		*ds:si	= ResEditDisplayClass object
		ds:di	= ResEditDisplayClass instance data
		ds:bx	= ResEditDisplayClass object (same as *ds:si)
		es 	= segment of ResEditDisplayClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	10/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDMetaUpdateWindow	method dynamic ResEditDisplayClass, 
					MSG_META_UPDATE_WINDOW
		uses	ax, cx, dx, bp
		.enter

	; Are we in batch mode?

		call	IsBatchMode
		jc	done

	; Let the superclass do its thing, which it does so well.

		mov	di, offset ResEditDisplayClass
		call	ObjCallSuperNoLock

done:
		.leave
		ret
REDMetaUpdateWindow	endm


DocumentDrawCode	ends



