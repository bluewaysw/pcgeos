COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		importMain.asm

AUTHOR:		Maryann Simmons, May 12, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB TransImport		perform import of a Clp graphics file into
				a GString

    INT GraphicsGetImportOptions Returns any import Options for the DIB
				Library, Push any options for the C
				translation Libraries. The CLP Library has
				no import options.

    INT TransGetFormat		Determines if the file is of CLP format

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/12/92		Initial revision


DESCRIPTION:
	
		

	$Id: importMain.asm,v 1.1 97/04/07 11:26:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ifdef __HIGHC__
MAINIMPORTC	segment	word	public 'CODE'
global	ImportClp:far
MAINIMPORTC	ends

MAINEXPORTC	segment	word	public	'CODE'
global	ExportClp:far
MAINEXPORTC	ends
else
global	IMPORTCLP:far
endif


ImportCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform import of a Clp graphics file into a GString

CALLED BY:	GLOBAL( Impex Library )

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
	mov	bx,vseg _ImportClp	;segment of the Clp main import routine
	mov	ax,offset _ImportClp	;offset  of the Clp main import routine
else
	mov	bx,vseg IMPORTCLP	;segment of the Clp main import routine
	mov	ax,offset IMPORTCLP	;offset  of the Clp main import routine
endif
	call	GraphicsImportCommon	;call the common code to do the import
	
	tst	ax
	jnz	done
	mov	bx, CIF_BITMAP
done:
	.leave
	ret
TransImport	endp

;---------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsGetImportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns any import Options for the DIB Library, Push any
		options for the C translation Libraries.
		The CLP Library has no import options.

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

SYNOPSIS:	Determines if the file is of CLP format	

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
clpHeader	local	4 dup(byte)
	.enter

	mov	cx, 4
	segmov	ds,ss			;read into local header struct
	lea	dx,clpHeader
	clr	al			;flags = 0
	mov	bx,si			;file
	call	FileRead
	jc	notClpFormat		;unable to read header info
	
	clr	cx			;format number
	cmp	{word} clpHeader,0xc350
	je	done
	cmp	{word} clpHeader,0xe3c7
	je	done
	cmp	{word} clpHeader,0x0000
	jne	notClpFormat
	cmp	{word} clpHeader+2, 0x0002	; is it Lotus 123 format?
	je	notClpFormat	
done:
	clr	ax			;ax <- TE_NO_ERROR
	.leave
	ret

notClpFormat:
	mov	cx,NO_IDEA_FORMAT
	jmp	done
TransGetFormat	endp


ImportCode	ends
