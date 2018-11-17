COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- Bmp Graphics Translation Library
FILE:		importMain.asm

AUTHOR:		Maryann Simmons 2/92

ROUTINES:
	Name			Description
	----			-----------
    GLB TransImport		perform import of a Bmp graphics format
				into a GString

    INT GraphicsGetImportOptions returns any Import Options for the DIB
				Library, pushes options for the C
				translation Libraries. The Bmp Library has
				no import options

    INT TransGetFormat		Determine if the file is BMP format

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:
	This file contains the main interface to the import side of the 
	Bmp library
		

	$Id: importMain.asm,v 1.1 97/04/07 11:26:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef __HIGHC__
MAINIMPORTC	segment	word	public 'CODE'
global	ImportBmp:far
MAINIMPORTC	ends

MAINEXPORTC	segment	word	public	'CODE'
global	ExportBmp:far
MAINEXPORTC	ends
else
global	IMPORTBMP:far
endif

ImportCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform import of a Bmp graphics format into a GString

CALLED BY:	GLOBAL(IMPEX LIBRARY)

PASS:		ds:si = ImportFrame

RETURN:		ax	- TransError error code( clear if no error)
		bx:	- ClipboardItemFormat OR
				handle to block with error string if ax=TE_CUSTOM
		dx:cx	- VMChain(cx = 0) containing transfer format

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransImport	proc	far

	.enter
	
ifdef __HIGHC__
	mov	bx,vseg _ImportBmp	;segment of the Bmp main import routine
	mov	ax,offset _ImportBmp	;offset  of the Bmp main import routine
else
	mov	bx,vseg IMPORTBMP	;segment of the Bmp main import routine
	mov	ax,offset IMPORTBMP	;offset  of the Bmp main import routine
endif
	call	GraphicsImportCommon	;Import the Bmp file

	tst	ax
	jnz	done
	mov	bx, CIF_BITMAP
done:
	.leave
	ret
TransImport	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsGetImportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns any Import Options for the DIB Library, pushes
		options for the C translation Libraries.
		The Bmp Library has no import options	

CALLED BY:	GraphicsImportCommon
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		*for future use if needed

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GraphicsGetImportOptions	proc	near
	clc
	ret
GraphicsGetImportOptions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the file is BMP format	

CALLED BY:	Impex	- GLOBAL
PASS:		SI	= fileHandle, open
RETURN:		AX	= TransError (0 = no error)
		CX	= format number if valid format
			  or NO_IDEA_FORMAT if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransGetFormat	proc	far
	uses	bx,dx,ds
bmpHeader	local	word
	.enter

	mov	cx,2
	segmov	ds,ss			;read into local header struct
	lea	dx,bmpHeader
	clr	al			;flags = 0
	mov	bx,si			;file
	call	FileRead		;rewind to beginning of file
	jc	notBmpFormat		;couldnt read header

	cmp	bmpHeader,0x4d42
	jne	notBmpFormat
	clr	cx			;cx <- format number
done:
	clr	ax			;ax <- TE_NO_ERROR
	.leave
	ret
notBmpFormat:
	mov	cx,NO_IDEA_FORMAT
	jmp	done
TransGetFormat	endp


ImportCode	ends











