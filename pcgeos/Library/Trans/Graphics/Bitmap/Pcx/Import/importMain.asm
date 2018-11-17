COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- Pcx Graphics Translation Library
FILE:		importMain.asm

AUTHOR:		Maryann Simmons 2/92

ROUTINES:
	Name			Description
	----			-----------
    GLB TransImport		perform import of a Pcx graphics file into
				a GString

    INT GraphicsGetImportOptions Return any importOptions for the DIB
				Library,Push any options for the C
				translation Library. The PCX library has no
				import options.

    INT TransGetFormat		Determines if the file is a valid Pcx
				format by looking at the header info.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------



DESCRIPTION:
	This file contains the main interface to the import side of the 
	PCX library
		

	$Id: importMain.asm,v 1.1 97/04/07 11:28:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef __HIGHC__
MAINIMPORTC	segment	word	public 'CODE'
global	ImportPcx:far
MAINIMPORTC	ends

MAINEXPORTC	segment	word	public	'CODE'
global	ExportPcx:far
MAINEXPORTC	ends
else
global	IMPORTPCX:far
endif

ImportCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform import of a Pcx graphics file into a GString

CALLED BY:	GLOBAL( Impex Library )

PASS:		ds:si = ImportFrame:

RETURN:		ax	- TransError error code( clear if no error)
		bx:	- ClipboardItemFormat OR  
				handle to block with error string if ax=TE_CUSTOM
		dx:cx	- VMChain(cx = 0) containing transfer format

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		* just pass the common code the translation routine to call
		 and let the Common Code do the work
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransImport	proc	far
	.enter
	
ifdef __HIGHC__
	mov	bx,vseg _ImportPcx	;segment of the PCX main import routine
	mov	ax,offset _ImportPcx	;offset of the PCX main import routine
else
	mov	bx,vseg IMPORTPCX	;segment of the PCX main import routine
	mov	ax,offset IMPORTPCX	;offset of the PCX main import routine
endif
	call	GraphicsImportCommon	;Import the Pcx file

	tst	ax
	jnz	done
	mov	bx, CIF_BITMAP		; return a HugeBitmap
done:
	
	.leave
	ret
TransImport	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsGetImportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return any importOptions for the DIB Library,Push any
		options for the C translation Library.
		The PCX library has no import options.

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
GraphicsGetImportOptions	proc	far
	clc
	ret
GraphicsGetImportOptions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the file is a valid Pcx format by
		looking at the header info.	

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
pcxHeader	local	PCXHeader
	.enter

	mov	cx,size PCXHeader
	segmov	ds,ss			;read into local header struct
	lea	dx,pcxHeader
	clr	al			;flags = 0
	mov	bx,si			;file
	call	FileRead
	jc	notPcxFormat		;error in reading header

	cmp	pcxHeader.PH_manf,0xa	;check for valid Pcx info
	jne	notPcxFormat
	cmp	pcxHeader.PH_version,0
	jl	notPcxFormat
	cmp	pcxHeader.PH_version,5
	ja	notPcxFormat
	clr	cx			;cx <- format number
done:
	clr	ax			;ax <- TE_NO_ERROR
	.leave
	ret
notPcxFormat:
	mov	cx,NO_IDEA_FORMAT
	jmp	done
TransGetFormat	endp


ImportCode	ends



















