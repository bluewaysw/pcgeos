COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Ico Translation Library
FILE:		libMain.asm

AUTHOR:		Steve Yegge, March 29, 1993

ROUTINES:
	Name			Description
	----			-----------
    GLB TransGetExportOptions	Return the handle of the block containing
				export options

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	4/28/92		Initial revision


DESCRIPTION:
 
	$Id: libMain.asm,v 1.1 97/04/07 11:29:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the handle of the block containing export options

CALLED BY:	GLOBAL

PASS:		dx	- handle of object block holding UI gadgetry
			  (zero if default options are desired)

RETURN:		dx	- handle of block containing ICOExportBlock structure
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
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransGetExportOptions proc	far
		uses ax,bx,cx,bp,ds,si,di
		.enter
	;
	; get Export Options from the UI
	;
		push	dx		; save handle of ui gadgetry
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	bx, dx		; block of the UI passed in
		mov	si, offset SelectBitCount
		mov	di, mask MF_CALL
		call 	ObjMessage
		
		pop	dx		; retore ui block handle
		push	ax		; the BitCount selection
		
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	si, offset SelectFormat
		mov	di, mask MF_CALL
		call 	ObjMessage
		
		push	ax	 	; the format number selected
	;
	; allocate a block to hold the Export Options
	;
		mov	ax, size ICOExportBlock
		mov	cl, mask HF_SHARABLE or mask HF_SWAPABLE
		mov	ch, mask HAF_LOCK
		call 	MemAlloc
		jc	error
		
		segmov	ds, ax		; address of allocated block
		
		pop	ax		; get Format selection
		mov	ds:[IEO_format], ax
		
		pop	ax		; restore BitCount selection
		mov	ds:[IEO_bitCount], al
		
		call 	MemUnlock
		mov	dx, bx		; return block in dx
		clc
done:
		.leave	
		ret
error:
		clr	dx
		add	sp,4		; fixup stack
		jmp 	done
		
TransGetExportOptions endp

ExportCode	ends
