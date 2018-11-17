COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Tif Translation Library
FILE:		libMain.asm

AUTHOR:		Maryann Simmons, May  5, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB TransGetExportOptions	Return the handle of the block containing
				export options

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 5/92		Initial revision


DESCRIPTION:
	
		

	$Id: libMain.asm,v 1.1 97/04/07 11:27:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ExportCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the handle of the block containing export options

CALLED BY:	GLOBAL

PASS:		dx	- handle of object block holding UI gadgetry
			  (zero if default options are desired)

RETURN:		dx	- handle of block containing TIFExportBlock structure
			  (or zero if no options)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		extract the options from the UI gadgetry and setup the
		structure

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		caller is expected to free the block when finished

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransGetExportOptions proc	far
	uses	ax,bx,cx,bp,ds,si,di
	.enter
	
;get Export Options from the UI
	push 	dx			;save handle of UI gadgetry
	mov	ax,MSG_GEN_ITEM_GROUP_GET_SELECTION 
					;returns ax= selection or GIGS_NONE-1
					; carry set *** cx,dx,bp destroyed
	mov	bx,dx			;block of UI
	mov	si,offset SelectBitCount;GenItem List
	mov	di,mask MF_CALL 
	call	ObjMessage		;bx:si= object, di = flags

	pop	dx			;restore handle to ui
	push	ax			;save bitcount selection

	mov	ax,MSG_GEN_ITEM_GROUP_GET_SELECTION 
	mov	si,offset SelectCompression
	mov	di,mask MF_CALL 
	call	ObjMessage		;bx:si= object, di = flags

	push	ax			;compression format selected
;allocate a block to hold the ExportOptions
	mov	ax,size TIFExportBlock
	mov	cl,mask	HF_SHARABLE or mask HF_SWAPABLE
	mov	ch,mask	HAF_LOCK	;want block locked down
	call	MemAlloc		;ax=size,cl=HeapFlags,ch=HeapAllocFLags
	jc	error			;not enough memory

	segmov	ds,ax			;address of allocated block
;set compression format
	pop	ax			;get compression selection
	mov	ds:[TEO_compress],ax	;set compression format
;set Bitcount
	pop	ax			;get bitcount
	mov	ds:[TEO_bitCount],al
	
	call	MemUnlock	;bx = handle of the block
	mov	dx,bx		;return handle of the block
	clc
done:
	.leave	
	ret

error:	clr	dx
	add	sp,4		;fixup stack pointer
	jmp	done
TransGetExportOptions endp

ExportCode	ends
