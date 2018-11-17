COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Clp Translation Library
FILE:		libMain.asm

AUTHOR:		Maryann Simmons, May 12, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB TransGetExportOptions	Return the handle of the block containing
				export options

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/12/92		Initial revision


DESCRIPTION:
	
		

	$Id: libMain.asm,v 1.1 97/04/07 11:26:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ExportCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the handle of the block containing export options

CALLED BY:	GLOBAL

PASS:		dx	- handle of object block holding UI gadgetry
			  (zero if default options are desired)

RETURN:		dx	- handle of block containing PSExportOpts structure
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
	mov	ax,MSG_GEN_ITEM_GROUP_GET_SELECTION ;returns ax= selection
		;or GIGS_NONE(-1) ,carry set *** cx,dx,bp destroyed
	mov	bx,dx		;block of UI
	mov	si,offset SelectBitCount ;GenItem List
	mov	di,mask MF_CALL 
	call	ObjMessage	;bx:si= object, di = flags

	push	ax		;save selection
;allocate a block to hold the ExportOptions
	mov	ax,size CLPExportBlock
	mov	cl,mask	HF_SHARABLE or mask HF_SWAPABLE
	mov	ch,mask	HAF_LOCK
	call	MemAlloc	;ax= size,cl=HeapFlags,ch=HeapAllocFlags
	jc	error		;not enough memory


	segmov	ds,ax		;address of block
	pop	ax		;bitCount		
	mov	ds:[CEO_bitCount],al
	
	call	MemUnlock	;bx = handle of the block
	mov	dx,bx		;return handle of the block
	clc
done:
	.leave	
	ret

error:	clr	dx
	add	sp,2
	jmp	done
TransGetExportOptions endp

ExportCode	ends
