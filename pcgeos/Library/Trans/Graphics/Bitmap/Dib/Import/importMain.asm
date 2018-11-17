COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		importMain.asm

AUTHOR:		Maryann Simmons, Mar  1, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT ImpexImportGraphicsConvertToTransferItem This routine converts the
				passed DIB metafile to a VMChain transfer
				item

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/ 1/92		Initial revision


DESCRIPTION:
	
		

	$Id: importMain.asm,v 1.1 97/04/07 11:29:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------------------------------
;	Code
;---------------------------------------------------------------------------


ImportCode	segment resource
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes parameters as set up for FileRead and calls
		fread with stream.

CALLED BY:	
PASS:		al	-flags(0)
		bx	-file(lower word of stream pointer)
		cx	-num bytes to read
		ds:dx	-buffer into which to read
RETURN:
		carry set if error
		carry clear if no error, ax destroyed,cx num bytes read
		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Assume	al=0 meaning return errors
		Assume high word of stream is zero		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	8/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FRead	proc	far
	uses bx,dx
	.enter
	push	cx		; save itemSize	
	push	ds,dx		; buffer
	push	cx		; itSize
	mov	cx,1		; num items
	push	cx
	clr	cx		
	push	cx,bx		; stream(high word zero)
	call	FREAD
	pop	cx		; element size
	tst	ax
	stc
	jz	done
	mul	cx		; num elements* element size = numbytes
	mov	cx,ax
	clc
done:
	.leave
	ret
FRead	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSeek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes parameters for FIlePos and calls fseek with 
		stream pointer	

CALLED BY:	
PASS:		al  -FilePosMode
		bx  -file( lower word of stream pointer)
		cx:dx - offset
RETURN:		
		ax	= 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Assumes	upper word of stream is always zero
		Assumes FilePosMode stays as is currently:

			FILE_POS_START		0
			FILE_POS_RELATIVE 	1
			FILE_POS_END		2
			these mirror the fseek modes
	Assumes	dont need dxax new position normally returned by FilePos

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	8/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSeek	proc	far
	uses	si,bx,cx
	.enter

	clr	si
	push	si,bx		;stream
	push	cx,dx		;bOffset
	clr	ah	
	push	ax		;mode	
	call	FSEEK
	.leave
	ret
FSeek	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexImportGraphicsConvertToTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	This routine converts the passed DIB metafile to a
		VMChain transfer item

CALLED BY:	
PASS:		bp: handle of Metafile(DIB FIle)
		di: handle of VMFile(open)

RETURN:		dx:cx	-Created Transfer Item(HugeArray holding GString)
		ax	-clear if no error, Else TransError
		bx	-mem Handle with text error string if ax = TE_CUSTOM

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	* the DIB source file stream pointer is passed to the DIB Library
	 in bx. This is actually  the low word of the stream pointer,
	 as the high word is always  zero.
	 ALL OF THE FOLLOWING DIB ROUTINES DEPEND UPON THIS!!!
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	4/ 9/92		Initial version
	Jim	5/92		Changed code to reflect change in 
				GrCreateGString, so VMAlloc here was unnecc.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ModeFlagsR	char	'r',0

ImpexImportGraphicsConvertToTransferItem	proc  far	
	uses	di, si
	.enter
	
;create VMBlock for transfer Item.Will be the first in VMChain holding the 
; GString with the imported bitmap

	ConvertFileHandleToStream bp, <offset ModeFlagsR>
	push	dx,cx		; save to close stream later
	mov	bx,cx		; bx <= DIB stream pointer
	mov	dx,di		; dx <= VMFile

	call	ImportDIB	; imports the DIB format into a GString

	mov	di, ax
	mov	si, bx
	call	FDCLOSE
	mov	ax, di		; restore error and possible block handle to
	mov	bx, si		; custom error string if ax = TE_CUSTOM

	.leave
	ret

ImpexImportGraphicsConvertToTransferItem	endp

public	ImpexImportGraphicsConvertToTransferItem	

ImportCode	ends







