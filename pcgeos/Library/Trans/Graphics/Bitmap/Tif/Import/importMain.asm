COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- tif Graphics Translation Library
FILE:		importMain.asm

AUTHOR:		Maryann 2/92

ROUTINES:
	Name			Description
	----			-----------
    GLB TransImport		perform import of a Tif graphics file into
				a GString

    INT GraphicsGetImportOptions Return any import Options for the DIB
				library, push any options for the C
				translation Library. The Tif Library has no
				import options

    INT TransGetFormat		determine if file is a TIFF format bitmap
				by reading in some header info.

REVISION HISTORY:
	Name	Date		Description



DESCRIPTION:
	This file contains the main interface to the import side of the 
	library
		

	$Id: importMain.asm,v 1.1 97/04/07 11:27:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef __HIGHC__
MAINIMPORTC	segment	word	public 'CODE'
global	ImportTif:far
MAINIMPORTC	ends

MAINEXPORTC	segment	word	public	'CODE'
global	ExportTif:far
MAINEXPORTC	ends
else
global	IMPORTTIF:far
endif

ImportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform import of a Tif graphics file into a GString

CALLED BY:	GLOBAL(Impex Library)

PASS:		ds:si = ImportFrame:

RETURN:		ax	- TransError error code( clear if no error)
		bx:	- clipboardItemFormat OR
				handle to block with error string if ax=TE_CUSTOM
		dx:cx	- VMChain(cx = 0) containing transfer format

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransImport	proc	far
	.enter

ifdef __HIGHC__
	mov	bx,vseg	_ImportTif	;segment of the TIF main import routine
	mov	ax,offset _ImportTif	;offset  of the TIF main import routine
else
	mov	bx,vseg	IMPORTTIF	;segment of the TIF main import routine
	mov	ax,offset IMPORTTIF	;offset  of the TIF main import routine
endif
	
	call	GraphicsImportCommon	;call common code to import Tif file

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

SYNOPSIS:	Return any import Options for the DIB library, push any
		options for the C translation Library.
		The Tif Library has no import options		

CALLED BY:	GraphicsImportCommon
PASS:		nothing	
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		* for future use if needed

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

SYNOPSIS:	determine if file is a TIFF format bitmap by reading in
		some header info.

CALLED BY:	Impex 	 -GLOBAL
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
tifHeader	local	TIFHeader
	.enter

	mov	cx,size TIFHeader
	segmov	ds,ss			;read into local header struct
	lea	dx,tifHeader
	clr	al			;flags = 0
	mov	bx,si			;file
	call	FileRead		;read in the header info
	jc	notTifFormat		;error in reading header
	
	cmp	tifHeader.TH_byteOrder,TIFF_BYTE_ORDER_INTEL
	je	version
	cmp	tifHeader.TH_byteOrder,TIFF_BYTE_ORDER_MOTOR
	je	version
	jmp	notTifFormat
version:
	cmp	tifHeader.TH_version,TIFF_VERSION
	jne	notTifFormat
	clr	cx			;cx <- format number
done:
	clr	ax			;ax <- TE_NO_ERROR
	.leave
	ret
notTifFormat:
	mov	cx,NO_IDEA_FORMAT	;not a tiff file
	jmp	done
TransGetFormat	endp


ImportCode	ends







