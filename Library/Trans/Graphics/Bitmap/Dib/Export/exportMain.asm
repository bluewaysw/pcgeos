COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- DIB Graphics Translation Library
FILE:		exportMain.asm

AUTHOR:		Maryann Simmons	1/92

ROUTINES:
	Name			Description
	----			-----------
    GLB ImpexExportGraphicsConvertToDIBMetafile Exports a GString into a
				DIB metafile format

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:
	This file contains the main interface to the export side of the 
	DIB library
		

	$Id: exportMain.asm,v 1.1 97/04/07 11:29:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes parameters as set up for FileWrite and call fwrite	
		with stream pointer
CALLED BY:	
PASS:		al	- flags (0)
		bx	- file ( lower word of stream pointer)
		cx	- number of bytes to write
		ds:dx	- buffer from which to write
		
RETURN:		carry set if error
		no error cx = num bytes written
		ax destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
		Assumes	al=0 meaning return errors
		Assumes upper word of stream is always zero

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	8/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FWrite	proc	far
	uses	bx,dx
	.enter

	push	cx		; save element size
	push	ds,dx		; buffer
	push	cx		; itSize
	mov	cx,1		; num items
	push	cx
	clr	cx		
	push	cx,bx		; stream(high word zero)
	call	FWRITE
	pop	cx		; element size
	tst	ax
	stc
	jz	done
	mul	cx		;element size * num elements = bytes written
	mov	cx,ax
	clc
done:
	.leave
	ret
FWrite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexExportGraphicsConvertToDIBMetafile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports a GString into a DIB metafile format

CALLED BY:	GLOBAL

PASS:		di:	-VMFile Handle
		dx:cx   -VM Chain
		bp	-DIB Metafile Handle
		ds:si	-ExportMetaInfo struct
				has EMI_bitCount
				    EMI_clipboardFormat
				    EMI_manufacturerID
	
RETURN:		ax 	-TransError Code
		bx      -handle of block of trans error text if ax = TE_CUSTOM
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
	MS	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ModeFlagsW	char	'w',0

ImpexExportGraphicsConvertToDIBMetafile	proc	far
	uses	bx,dx,si,di
	.enter


	mov	bx,di	;bx = VMFile
	push	dx	;VM Block
	ConvertFileHandleToStream bp, <offset ModeFlagsW>
	mov	di,cx	;dx:cx = stream(upper word=0)
	mov	ax,dx	;axdi is stream
	pop	dx	;dx = VMBlock Handle
	push	ax,cx	;stream

	mov	cx,ds:[si].EMI_clipboardFormat
	mov	ax,ds:[si].EMI_manufacturerID
	mov	si,ds:[si].EMI_bitCount

	xchg	si, dx

;Export from the GString into the DIB format
	call	ExportDIB 
	mov	di,ax	;save TransError
	call	FDCLOSE
	mov	ax,di	;Restore TransError
	.leave
	ret
ImpexExportGraphicsConvertToDIBMetafile	endp
;---------------------------------------------------------------------------

ExportCode	ends
