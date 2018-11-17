COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:    	Text/TextGraphic
FILE:		tgOptimize.asm

AUTHOR:		Cassie Hartzog, Mar  9, 1994

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	3/ 9/94		Initial revision


DESCRIPTION:
	Code for optimizing the size of VisTextGraphic GStrings.

	$Id: tgOptimize.asm,v 1.1 97/04/07 11:19:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextGraphic segment resource
GSflags record  
    :1,			
    GSF_FIGURE_BOUNDS:1,		; 1 to calc bounds instead of play
    GSF_COMPACT_BITMAPS:1,		; 1 to always compact BMs when writing
    GSF_VMEM_LOCKED:1,			; HugeArray is locked down
    GSF_CONTINUING:1,			; continuing from previous call 
    GSF_XFORM_SAVED:1,			; 1 if transform has been saved
    GSF_ERROR:1, 			; 1 if some error (probably disk)
    GSF_ELEMENT_READY:1,		; 1 if elem ready, but not executed.
    GSF_HANDLE_TYPE GStringType:3	; type of gstring
GSflags end  

GString	struct
    GSS_header		LMemBlockHeader <> ; LMem header
    GSS_flags		GSflags	<>	; holds file/mem flags, etc.
    GSS_fileBuffer	lptr		; handle to file buffer or
					;  gstring chunk (mem strings)
    GSS_hString		hptr		; file handle or mem handle
					;  (to gstring)
    GSS_firstBlock	word		; starting VM block handle or
					;  chunk handle 
    GSS_curPos		dword		; current string pointer
    GSS_cacheLink	hptr.GString	; used for GString struc cache
    GSS_lastKern 	fptr.far	; kernel graphics routine
    GSS_lastRout 	fptr.far	; gstring play routine
    GSS_lastSize 	word		; size of element
    GSS_lastPtr		fptr		; pointer to element
    GSS_vmemNext 	word		; count of elements left in this block
    GSS_vmemPrev 	word		; count of prev elements in this block
    GSS_filePos		dword		; initial file position for STREAM ones
GString	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGraphicCompressGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compress the bitmaps in a VisTextGraphic

CALLED BY:	GLOBAL 
PASS:		on stack - VisTextGraphicCompressParams
			
RETURN:		dx:ax - VMChain of gstring in destination file
		(If the source file and destination file are the same
		 and no compression was possible, the VMChain will
		 not have changed.  If compression was not possible
		 and the files are different, the gstring will 
		 just be copied to the destination file.)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompressGraphicFrame	struct
    CGF_params		VisTextGraphicCompressParams
    CGF_sourceGS	hptr.GState		; source gstate
    CGF_destGS		hptr.GState		; destination gstate
    CGF_bitmapOD	optr			; VisBitmap object
    CGF_drawCommand	byte			; actual graphic opcode
    CGF_opcodeSize	word			; size of draw bitmap opcode
    CGF_curPos		dword			; saved GSS_curPos
    CGF_bitmapMode	BitmapMode		; bitmap editing mode - tells
						;  us whether to edit the mask
						;  or draw the bitmap
    CGF_bitmapLib	hptr.GeodeHandle	; bitmap library handle
    CGF_x		word			; bitmap's x coordinate
    CGF_y		word			; bitmap's y coordinate
    CGF_returnVal	GSRetType		; graphics routine return vals
    CGF_signature	word			; used by EC code only
align word
CompressGraphicFrame	ends

VisTextGraphicCompressGraphic	proc  far   params:VisTextGraphicCompressParams
		uses	bx,cx,si,di,ds,es,bp
		.enter

if FULL_EXECUTE_IN_PLACE
	;
	; Validate that the graphic is *not* in a movable code segment
	;
EC<		push	bx, si						>
EC<		movdw	bxsi, ss:[params].VTGCP_graphic			>
EC<		call	ECAssertValidFarPointerXIP			>
EC<		pop	bx, si						>
endif

EC <		mov	bx, ss:[params].VTGCP_sourceFile		>
EC <		call	ECCheckFileHandle				>
EC <		mov	bx, ss:[params].VTGCP_destFile			>
EC <		call	ECCheckFileHandle				>
		
		segmov	ds, ss, ax
		mov	es, ax			
		lea	si, ss:[params]		; ds:si <- passed params
		sub	sp, size CompressGraphicFrame 
		mov	bp, sp
		mov	di, bp			; es:di <- CompressGraphicFrame

	;
	; Fill params with zeros and set the EC signature
	;
EC <		push	di					>
EC <		mov	cx, size CompressGraphicFrame		>
EC <		mov	ax, 0					>
EC <		rep	stosb					>
EC <		pop	di					>
EC <		mov	ss:[bp].CGF_signature, 0xcaca		>

	;
	; copy the passed parameters to the params structure
	; and intialize some fields to zero
	;
		mov	cx, size VisTextGraphicCompressParams		
		rep	movsb
		clr	ss:[bp].CGF_bitmapLib		
		clr	ss:[bp].CGF_bitmapOD.handle
	;
	; Load the source gstring
	;
		mov	bx, ss:[bp].CGF_params.VTGCP_sourceFile
		lds	di, ss:[bp].CGF_params.VTGCP_graphic
		call	LoadGString			;^hsi - gstate
		tst	si				; any data?
		LONG 	jz	noCompression		; nope, we're done
	;
	; Load the bitmap library and save its handle for later use
	;
		call	LoadBitmapLibrary		; bx <- lib handle
		jc	noCompression			; if not loaded, can't
		mov	ss:[bp].CGF_bitmapLib, bx	;  do the compression
	;
	; Allocate a block and create a VisBitmap to use for bitmap compression
	;
		call	CreateVisBitmap
	;
	; create the destination gstring to hold the compacted data
	;
		call	CreateGString			;si - gstring's VMBlock
	;
	; Copy the source gstring to the destination gstring,
	; compressing bitmaps as we encounter them.  
	;
		push	si				; save the VMBlock
		mov	ss:[bp].CGF_returnVal, GSRT_COMPLETE
		call	TG_CopyCompressGString	
	;
	; destroy the original gstring, leaving its data
	;
		mov	si, ss:[bp].CGF_sourceGS
		clr	di
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString
	;
	; destroy the destination gstring, leaving its data if no error,
	; killing it otherwise
	;
		mov	si, ss:[bp].CGF_destGS
		clr	di
		mov	dl, GSKT_LEAVE_DATA
		cmp	ss:[bp].CGF_returnVal, GSRT_FAULT
		jne	leaveData
		mov	dl, GSKT_KILL_DATA
leaveData:		
		call	GrDestroyGString
		pop	ax				; restore VMBlock
	;
	; was the compression successful?  If not, just do a straight copy
	;
		cmp	ss:[bp].CGF_returnVal, GSRT_COMPLETE
		jne	noCompression
		clr	dx				;ax:dx <- new VMChain
		
done:
	;
 	; Free the bitmap library and VisBitmap block
	;
		call	FreeVisBitmap
		xchg	ax, dx				;dx:ax <- new VMChain
		add	sp, size CompressGraphicFrame 

		.leave
		ret

noCompression:
	;
	; Don't bother to copy it if source and dest files are the same.
	;
		push	bp
		lds	di, ss:[bp].CGF_params.VTGCP_graphic	
		mov	bx, ss:[bp].CGF_params.VTGCP_sourceFile
		mov	dx, ss:[bp].CGF_params.VTGCP_destFile
		movdw	axbp, ds:[di].VTG_vmChain
		cmp	bx, dx				;same file?
		je	noCopy
		call	VMCopyVMChain			;ax:bp <- new VMChain
noCopy:
		mov	dx, bp				;ax:dx <- VMChain
		pop	bp
		jmp	done
VisTextGraphicCompressGraphic		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TG_CopyCompressGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the source gstring to new gstring.

CALLED BY:	VisTextGraphicCompressGraphic 
PASS:		ss:bp - CompressGraphicFrame
RETURN:		
DESTROYED:	ax, bx, cx, dx, di, si, bp, es

PSEUDO CODE/STRATEGY:
	If element is GrEscape or GrComment, skip it.
	If element is a draw or fill bitmap command, compress the bitmap.
	Else just copy the element to the destination gstring.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TG_CopyCompressGString		proc	near

		mov	si, ss:[bp].CGF_sourceGS
		mov	di, ss:[bp].CGF_destGS
copyLoop:
EC <		cmp	ss:[bp].CGF_signature, 0xcaca			>
EC <		ERROR_NE BAD_COMPRESS_GRAPHIC_PARAMS_STRUCT		>

	;
	; Copy everything but OUTPUT elements, ESCAPE and LABEL elements
	;
		mov	dx, mask GSC_OUTPUT or mask GSC_ESCAPE \
			or mask GSC_LABEL
		call	GrCopyGString
		cmp	dx, GSRT_COMPLETE
		je	endOfGString
		cmp	dx, GSRT_FAULT			
		je	error
	;
	; If it is an escape element or a label, don't copy it to the
	; destination gstring, it's just a waste of space.
	;
		cmp	dx, GSRT_ESCAPE
		je	copyLoop
		cmp	dx, GSRT_LABEL
		je	copyLoop
EC <		cmp	dx, GSRT_OUTPUT					>
EC <		ERROR_NE VIS_TEXT_GRAPHIC_BAD_GSTRING_ELEMENT		>

	;
	; Check for a draw bitmap opcode.  Get the bitmap element if
	; it is one.
	;
		call	CheckForBitmap			; ds:bx <- bitmap
		jnc	copyElement
		call	TG_OptimizeBitmap
		cmp	dx, GSRT_FAULT			
		je	error
		
copyElement:
	;
	; Either this element is not a draw bitmap command, or it is but
	; it couldn't be compressed for some reason.  Just copy it.
	;
		mov	dx, mask GSC_ONE
		call	GrCopyGString
		cmp	dx, GSRT_FAULT
		je	error
		cmp	dx, GSRT_COMPLETE
		jne	copyLoop

endOfGString:
		call	GrEndGString
		mov	dx, ax
error:
		mov	ss:[bp].CGF_returnVal, dx
		ret

TG_CopyCompressGString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TG_OptimizeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Optimize a gstring's bitmap element by reformating, changing
		the resolution and compacting it.

CALLED BY:	TG_CopyCompressGString

PASS:		ss:bp - CompressGraphicFrame
		ds:bx - bitmap element
RETURN:		dx - GSRT_FAULT if unrecoverable error
DESTROYED:	ax,bx,cx,dx,ds,es

PSEUDO CODE/STRATEGY:
	Get the bitmap gstring element
	Create the VisBitmap's bitmap
	Draw the mask to it, if there is one
	Draw the bitmap to it
	Change the bitmap's format and resolution, and compress it
	Copy that bitmap to the destination gstring
	Unlock the VisBitmap block.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TG_OptimizeBitmap		proc	near
		class	VisBitmapClass
		uses	si, di, bp
		.enter

EC <		cmp	ss:[bp].CGF_signature, 0xcaca			>
EC <		ERROR_NE BAD_COMPRESS_GRAPHIC_PARAMS_STRUCT		>

		push	ds, bx, bp
		add	bx, ss:[bp].CGF_opcodeSize
		mov	al, ds:[bx].B_type
		mov	cx, ds:[bx].B_width
		mov	dx, ds:[bx].B_height
	;
	; Check if bitmap is masked. If so, create the VisBitmap
	; with the transparent flag set.
	;
		mov	ss:[bp].CGF_bitmapMode, mask BM_EDIT_MASK
		movdw	bxsi, ss:[bp].CGF_bitmapOD
		push	ax
		call	ObjLockObjBlock			
		mov	ds, ax
		mov	di, ds:[si]
		add	di, ds:[di].VisBitmap_offset
		ornf	ds:[di].VBI_undoFlags, mask VBUF_TRANSPARENT
		pop	ax
		test	al, mask BMT_MASK
		jnz	isMasked
		clr	ss:[bp].CGF_bitmapMode	
		andnf	ds:[di].VBI_undoFlags, not (mask VBUF_TRANSPARENT)
isMasked:
		clr	bp				; no initial gstring
		mov	ax, MSG_VIS_BITMAP_CREATE_BITMAP
		call	ObjCallInstanceNoLock

		mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
		call	ObjCallInstanceNoLock
		mov	di, bp				; ^hdi - VisBitmap's
							;  gstring
		call	MemUnlock
EC <		call	ECCheckGStateHandle				>
		pop	ds, si, bp			; ds:si <- bitmap 
		
		test	ss:[bp].CGF_bitmapMode, mask BM_EDIT_MASK
		jz	drawBitmap			
	;
	; Draw the bitmap mask to the VisBitmap's gstring. 
	;
		call	TG_DrawMaskToVisBitmap		; ds:si <- bitmap elt
		cmp	dx, GSRT_FAULT
		je	done
drawBitmap:
	;
	; Either the mask has been drawn, or there is no mask.
	; Draw the bitmap to the VisBitmap's gstring.
	;
		call	TG_DrawBitmapToVisBitmap

	;
	; Unlock the bitmap element only *after* copying it and resetting
	; the opcode in TG_DrawMaskToVisBitmap, "lest it get discarded in
	; strange and seldom-encountered situations because it's clean..."
	;
		call	HugeArrayUnlock			

		cmp	dx, GSRT_FAULT
		je	done
	;
	; Now convert the bitmap to the format we want it to be in.
	;
		push	bp
		movdw	bxsi, ss:[bp].CGF_bitmapOD
EC <		call	ECCheckOD					>
		mov	cl, ss:[bp].CGF_params.VTGCP_format
EC <		cmp	cl, BMF_24BIT					>
EC <		ERROR_A	VIS_TEXT_ILLEGAL_BITMAP_FORMAT			>
		mov	dx, ss:[bp].CGF_params.VTGCP_xDPI
		mov	bp, ss:[bp].CGF_params.VTGCP_yDPI
		mov	ax, MSG_VIS_BITMAP_SET_FORMAT_AND_RESOLUTION
		mov	di, mask MF_CALL 
		call	ObjMessage
		pop	bp
	;
	; If compression is desired, This will compact the bitmap
	;
		tst	ss:[bp].CGF_params.VTGCP_compressFlag
		jz	noCompression
		mov	ax, MSG_VIS_BITMAP_BECOME_DORMANT
		mov	di, mask MF_CALL 
		call	ObjMessage
noCompression:
	;
	; Now that the bitmap is compacted, has the right format and
	; resolution, copy it to the destination gstring.
	;
		call	TG_CopyBitmap
done:
		.leave
		ret

TG_OptimizeBitmap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TG_DrawMaskToVisBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the bitmap from the source gstring to the VisBitmap,
		while it is in edit mask mode.

CALLED BY:	TG_OptimizeBitmap
PASS:		ss:bp - CompressGraphicFrame
		ds:si - bitmap element
		^hdi - gstate of VisBitmap
RETURN:		dx = GSRT_ONE if successful
			ds:si - bitmap element (must be unlocked by caller)
		dx = GSRT_FAULT if error
			bitmap element unlocked
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TG_DrawMaskToVisBitmap		proc	near
	;
	; First, set the bitmap into the proper mode.  If the bitmap
	; was not put into edit mask mode, we can't edit the mask, so
	; don't even try.
	;
		mov	ax, ss:[bp].CGF_bitmapMode
		clr	dx
		call	GrSetBitmapMode			;ax<-flags actually set
EC <		and	ax, mask BM_EDIT_MASK				>
EC <		mov	ss:[bp].CGF_bitmapMode, ax			>
EC <		jz	done						>

		call	GrGetMixMode
		push	ax				; save current mix mode
		mov	al, MM_SET
		call	GrSetMixMode
	;
	; Figure out which fill bitmap opcode to use
	;
		mov	cl, GR_FILL_BITMAP
		cmp	ss:[bp].CGF_drawCommand, GR_DRAW_BITMAP
		je	$10
		mov	cl, GR_FILL_BITMAP_CP
$10:
	;
	; Store new, save old opcode
	;
		mov	ch, ds:[si]		;get original opcode
		mov	ds:[si], cl		;store new opcode

		push 	{word}ds:[si]+1		;save coords
		push 	{word}ds:[si]+3		;save coords
		clr	{word}ds:[si]+1		;clear 'em for bitmap
		clr	{word}ds:[si]+3		;to bitmap transfer
	;
 	; Copy the bitmap element from source to destination gstring
	;
		push	cx, si			;save opcode, bitmap ptr
		mov	si, ss:[bp].CGF_sourceGS
		mov	dx, mask GSC_ONE
		call	GrCopyGString		;dx <- GSRetType
		pop	cx, si

		pop 	{word}ds:[si]+3
		pop 	{word}ds:[si]+1		;restore original coords

		mov	ds:[si], ch		;restore original opcode
	;
	; Reset the gstring position to point to the bitmap draw command
	; 
		call	SetGStringPos		

		pop	ax
		call	GrSetMixMode			; restore the mix mode

		cmp	dx, GSRT_FAULT
		je	error
		cmp	dx, GSRT_ONE
		jne	error
		mov	dx, GSRT_ONE
done:
		ret
error:
		call	HugeArrayUnlock
		mov	dx, GSRT_FAULT
		jmp	done
TG_DrawMaskToVisBitmap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TG_DrawBitmapToVisBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the bitmap from the source gstring to the VisBitmap

CALLED BY:	TG_OptimizeBitmap
PASS:		ss:bp - CompressGraphicFrame
		ds:si - bitmap element
		^hdi - gstate of VisBitmap
RETURN:		dx - GSRetType
		source gstring points to element after bitmap command
		CGF_bitmapMode  - cleared
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TG_DrawBitmapToVisBitmap		proc	near
	;
	; First, clear the edit bitmap mask mode flag in the gstate, and
	; reset the flag in CompressGraphicFrame for the next call to
	; TG_OptimizeBitmap.
	;
		clr	ax, dx
		mov	ss:[bp].CGF_bitmapMode, ax
		call	GrSetBitmapMode			;ax<-flags actually set

		push 	{word}ds:[si]+1		;save coords
		push 	{word}ds:[si]+3		;save coords
		clr	{word}ds:[si]+1		;clear 'em for bitmap
		clr	{word}ds:[si]+3		;to bitmap transfer

		push	si
		mov	si, ss:[bp].CGF_sourceGS
		mov	dx, mask GSC_ONE
		call	GrCopyGString
		pop	si

		pop 	{word}ds:[si]+3
		pop 	{word}ds:[si]+1		;restore original coords

		ret
TG_DrawBitmapToVisBitmap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TG_CopyBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the optimized bitmap to the destination gstring.

CALLED BY:	TG_OptimizeBitmap
PASS:		ss:bp - CompressGraphicFrame
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di,ds

PSEUDO CODE/STRATEGY:
	VisBitmap stores the bitmap as a huge bitmap.  We'll draw it to
	the destination gstring using the GrDrawHugeBitmap commands to
	make life easier.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TG_CopyBitmap		proc	near
		.enter

EC <		cmp	ss:[bp].CGF_signature, 0xcaca			>
EC <		ERROR_NE BAD_COMPRESS_GRAPHIC_PARAMS_STRUCT		>
	;
	; Get the bitmap's VMBlock from the VisBitmap object
	;
		movdw	bxsi, ss:[bp].CGF_bitmapOD
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
		mov	di, mask MF_CALL
		call	ObjMessage			;^vcx:dx <- bitmap
		xchg	cx, dx				;^vdx:cx <- bitmap
		push	dx, cx
	;
	; Convert the original graphic bitmap command to its Huge counterpart
	;
		mov	di, ss:[bp].CGF_destGS
		mov	si, ss:[bp].CGF_x
		mov	bx, ss:[bp].CGF_y
		mov	al, ss:[bp].CGF_drawCommand

		cmp	al, GR_DRAW_BITMAP
		jne	$10
		mov	ax, si
		call 	GrDrawHugeBitmap
		jmp	done
$10:
		cmp	al, GR_DRAW_BITMAP_CP
		jne	$20
		call 	GrDrawHugeBitmapAtCP
		jmp	done
$20:
		cmp	al, GR_FILL_BITMAP
		jne	$30
		mov	ax, si
		call	GrFillHugeBitmap
		jmp	done
$30:
EC <		cmp	al, GR_FILL_BITMAP_CP				>
EC <		ERROR_NE VIS_TEXT_BAD_BITMAP_COMMAND			>
		call	GrFillHugeBitmapAtCP

done:
		pop	bx, ax				;^vbx:ax <- bitmap
	;
	; Free the bitmap, now that it has been drawn to destination gstring
	;
		push	bp
		clr	bp				; ax:bp <- VMChain
		call	VMFreeVMChain
		pop	bp

		.leave
		ret
TG_CopyBitmap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetGStringPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the source gstring position.

CALLED BY:	INTERNAL
PASS:		ss:bp - CompressGraphicFrame
RETURN:		source gstring pointing at correct element
DESTROYED:	es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGStringPos		proc	near
		uses	ax, bx, cx, dx, si
		.enter

		call	LockSourceGString		;es <- GString
		movdw	dxax, ss:[bp].CGF_curPos	;pos we want to be at
		subdw	dxax, es:[GSS_curPos]		;dxax <- difference
		call	MemUnlock

EC <		cmp	dx, -1						>
EC <		ERROR_NE VIS_TEXT_GRAPHIC_BAD_GSTRING_ELEMENT		>
		mov	cx, ax				;cx <- #elts to back up
		mov	si, ss:[bp].CGF_sourceGS
		mov	al, GSSPT_RELATIVE
		call	GrSetGStringPos
		.leave
		ret
SetGStringPos		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a gstring from file.

CALLED BY:	VisTextGraphicCompressGraphic
PASS:		^hbx - file
		ds:di - VisTextGraphic
RETURN:		^hsi - gstring,
		     - 0 if nothing to compress
		(gstring is also stored in ss:[bp].CGF_sourceGS)
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
	All VisTextGraphic gstrings are stored in VMBlocks.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadGString		proc	near

EC <		cmp	ds:[di].VTG_type, VisTextGraphicType		>
EC <		ERROR_A VIS_TEXT_BAD_GRAPHIC_ELEMENT			>
EC <		cmp	ds:[di].VTG_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT>
EC <		ERROR_E	TEXT_ATTRIBUTE_ELEMENT_IS_FREE			>
	;
	; We can only compress gstring graphics
	;
		clr	si				;assume no gstring
		cmp	ds:[di].VTG_type, VTGT_GSTRING
		jne	done
	;
	; Load the gstring from file
	;
EC <		tst	ds:[di].VTG_vmChain.low		;if 0, its in VMBlock>
EC <		ERROR_NZ VIS_TEXT_CAN_ONLY_LOAD_GSTRING_FROM_VMBLOCK	>
		
		mov	cl, GST_VMEM	
		mov	si, ds:[di].VTG_vmChain.high
		tst	si
		jz	done
		call	GrLoadGString			;^hsi <- source gstate
		mov	ss:[bp].CGF_sourceGS, si
done:
		ret
LoadGString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new gstring in a VMBlock in the text 
		object's file.

CALLED BY:	INTERNAL - VisTextGraphicCompressGraphic
PASS:		ss:bp - CompressGraphicFrame
RETURN:		^hdi - new gstring, saved in CGF_destGS
		si - VMBlock 
DESTROYED:	bx, cx, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateGString		proc	near
		
EC <		cmp	ss:[bp].CGF_signature, 0xcaca		>
EC <		ERROR_NE BAD_COMPRESS_GRAPHIC_PARAMS_STRUCT		>

		mov	cl, GST_VMEM
		mov	bx, ss:[bp].CGF_params.VTGCP_destFile
		call	GrCreateGString
	;
	; Store the new GString in params
	;
		mov	ss:[bp].CGF_destGS, di
		ret
CreateGString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadBitmapLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the bitmap library

CALLED BY:	TG_OptimizeBitmap
PASS:		nothing
RETURN:		^hbx - bitmap library
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <	bitmapLibName	char	"EC Bitmap Library", 0			>
NEC <	bitmapLibName	char	"Bitmap Library", 0			>
LoadBitmapLibrary		proc	near
		uses	ax,si,ds
		.enter

		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		segmov	ds, cs, ax
		mov	si, offset bitmapLibName	; ds:si <- lib name
		clr	ax				; any protocol # okay
		call	GeodeUseLibrary
		call	FilePopDir
		.leave
		ret
LoadBitmapLibrary		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetVisBitmapEntryPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the segment:offset of VisBitmapClass

CALLED BY:	TG_OptimizeBitmap
PASS:		ss:bp - CompressGraphicFrame
RETURN:		es:di - entry point
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetVisBitmapEntryPoint		proc	near
		uses	ax,bx
		.enter

		mov	bx, ss:[bp].CGF_bitmapLib
EC <		call	ECCheckLibraryHandle				>
		mov	ax, enum VisBitmapClass
		call	ProcGetLibraryEntry		;bx:ax <- entry point
		movdw	esdi, bxax
		
		.leave
		ret
GetVisBitmapEntryPoint		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateVisBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates a block with a VisBitmap in it.

CALLED BY:	VisTextGraphicCOmpressGraphic
PASS:		ss:bp - CompressGraphicFrame
RETURN:		nothing
DESTROYED:	ds, es, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateVisBitmap		proc	near
		uses	ax, bx, si
		.enter
	;
	; Allocate an object block in which to create VisBitmaps
	;
		call	GetVisBitmapEntryPoint		; es:di <- entry pt
		clr	bx				; run by this thread
		call	UserAllocObjBlock		; bx <- block
		call	ObjLockObjBlock			
		mov	ds, ax
		call	ObjInstantiate			; *ds:si <- VisBitmap
		movdw	ss:[bp].CGF_bitmapOD, bxsi
	;
	; Tell the VisBitmap to use the destination file
	;
		mov	cx, ss:[bp].CGF_params.VTGCP_destFile
		mov	ax, MSG_VIS_BITMAP_SET_VM_FILE
		call	ObjCallInstanceNoLock
		call	MemUnlock
		.leave
		ret
CreateVisBitmap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeVisBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the Bitmap Library and VisBitmap block

CALLED BY:	VisTextGraphicCOmpressGraphic
PASS:		ss:bp - CompressGraphicFrame	
RETURN:		nothing
DESTROYED:	bx, cx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeVisBitmap		proc	near
		uses	ax, dx, bp
		.enter
		
		tst	ss:[bp].CGF_bitmapLib
		jz	noBitmapLib
		mov	bx, ss:[bp].CGF_bitmapLib
		call	GeodeFreeLibrary
		
noBitmapLib:
		movdw	bxsi, ss:[bp].CGF_bitmapOD	;free the VisBitmap
		tst	bx
		jz	done
		mov	ax, MSG_META_BLOCK_FREE
		clr	di
		call	ObjMessage			; object block
done:		
		.leave
		ret
FreeVisBitmap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBitmapElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a ptr to the current bitmap element from the source
		gstring. Does not advance the gstring.

CALLED BY:	INTERNAL
PASS:		ss:bp - CompressGraphicFrame
RETURN:		ds:si - element 
		cl - opcode of element
		dx:ax - curPos
DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBitmapElement		proc	near
		uses	bx, di
		.enter

		call	LockSourceGString		;es:0 = GString
		push	bx				;save GString handle
		mov	bx, ss:[bp].CGF_params.VTGCP_sourceFile
		mov	di, es:[GSS_firstBlock]	;  and block handle
		movdw	dxax, es:[GSS_curPos]
		call	HugeArrayLock			; ds:si <- element
		mov	cl, ds:[si]			; cl <- opcode

		movdw	dxax, es:[GSS_curPos]		;return curPos
		pop	bx				;unlock GString
		call	MemUnlock
		.leave
		ret
GetBitmapElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if current gstring element is a bitmap.
		Save the original draw comand if it is, and the size
		of the opcode, and the (x,y) draw offset.

CALLED BY:	TG_CopyCompressGraphic
PASS:		ss:bp - CompressGraphicFrame
		cl - opcode
RETURN:		carry set if it is a bitmap, 
			ds:bx - bitmap element
			(caller must unlock it with HugeArrayUnlock)
		carry clear if not a bitmap
DESTROYED:	ax,cx,dx

PSEUDO CODE/STRATEGY:

 It is assumed that certain types of bitmap commands cannot
 occur in a gstring that has been pasted into the text layer:
 	Gr{Draw, Fill}BitmapOptr and Gr{Draw,Fill}BitmapPtr

 XXX: could we ever have fill commands here?

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForBitmap		proc	near
		uses	si
		.enter
;
; GrDrawBitmap uses this structure (and GrFillBitmap uses one that is
; exactly the same except the names are different)
; 
;	OpDrawBitmap	struct
;	    ODB_opcode	GStringElement	GR_DRAW_BITMAP
;	    ODB_x	word	?
;	    ODB_y	word	?
;	    ODB_size	word	?
;	OpDrawBitmap	ends
;
		cmp	cl, GR_DRAW_BITMAP
		jne	$10
		mov	bx, size OpDrawBitmap
		jmp	getBitmap
$10:
		cmp	cl, GR_FILL_BITMAP
		jne	$20
		mov	bx, size OpFillBitmap
		jmp	getBitmap

$20:
; It's not a GrDrawBitmap command, maybe it's a GrDrawBitmapAtCP.
; GrDrawBitmapAtCP (and GrFillBitmapAtCP) has this structure:
; 
;      	OpDrawBitmapAtCP	struct
;	    ODBCP_opcode	GStringElement	GR_DRAW_BITMAP_CP
;	    ODBCP_size	word	?
;	OpDrawBitmapAtCP	ends
;
		cmp	cl, GR_DRAW_BITMAP_CP
		jne	$30
		mov	bx, size OpDrawBitmapAtCP
		jmp	getBitmap

$30:
		cmp	cl, GR_FILL_BITMAP_CP
		clc
		jne	done
		mov	bx, size OpDrawBitmapAtCP
getBitmap:
	;
	; We need to mimic this bitmap draw command when drawing the bitmap
	; or mask to the new gstring, so it is necessary to save the
	; original draw command and the x, y coordinates used by it
	;
		mov	ss:[bp].CGF_opcodeSize, bx
		mov	ss:[bp].CGF_drawCommand, cl
		
		call	GetBitmapElement		; ds:si <- element
		movdw	ss:[bp].CGF_curPos, dxax

		clr	ax, dx				; assume no x, y
		cmp	bx, size OpDrawBitmap
		jne	noXY
		mov	ax, ds:[si+size GStringElement]		; x-Coord
		mov	dx, ds:[si+size GStringElement+2] 	; y-Coord
noXY:
		mov	ss:[bp].CGF_x, ax
		mov	ss:[bp].CGF_y, dx
		mov	bx, si				; ds:bx <- bitmap
		stc
done:		
		.leave
		ret

CheckForBitmap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockSourceGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the source GString

CALLED BY:	INTERNAL
PASS:		ss:bp - CompressGraphicFrame
RETURN:		es - segment of GString
		bx - handle of GString segment, caller must unlock it
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockSourceGString		proc	near
		uses	ax
		.enter
		mov	bx, ss:[bp].CGF_sourceGS
		call	MemLock				;lock the gstate
		mov	es, ax
		mov	ax, es:[GS_gstring]		;get gstring handle
		call	MemUnlock			;unlock gstate
		mov	bx, ax	
		call	MemLock				;lock gstring
		mov	es, ax
		.leave
		ret
LockSourceGString		endp

TextGraphic ends
