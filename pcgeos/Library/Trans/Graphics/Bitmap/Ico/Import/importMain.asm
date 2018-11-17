COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		importMain.asm

AUTHOR:		Steve Yegge, May 29, 1993

ROUTINES:
	Name			Description
	----			-----------
    GLB TransImport		perform import of an Ico graphics format
				into a GString

    INT GraphicsGetImportOptions returns any Import Options for the DIB
				Library, pushes options for the C
				translation Libraries. The Ico Library has
				no import options

    INT TransGetFormat		Determine if the file is ICO format
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/29/93		Initial revision

DESCRIPTION:

	This file contains the main interface to the import side of the 
	Ico library

	$Id: importMain.asm,v 1.1 97/04/07 11:29:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef __HIGHC__
MAINIMPORTC	segment	word	public 'CODE'
global	ImportIco:far
MAINIMPORTC	ends

MAINEXPORTC	segment	word	public	'CODE'
global	ExportIco:far
MAINEXPORTC	ends
else
global	IMPORTICO:far
endif


ImportCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform import of an Ico graphics format into a GString

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
		stevey	5/29/93		initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransImport	proc	far

	.enter
	
ifdef __HIGHC__
	mov	bx,vseg _ImportIco	;segment of the Ico main import routine
	mov	ax,offset _ImportIco	;offset  of the Ico main import routine
else
	mov	bx,vseg IMPORTICO	;segment of the Ico main import routine
	mov	ax,offset IMPORTICO	;offset  of the Ico main import routine
endif
	call	GraphicsImportCommon	;Import the Ico file

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
		The Ico Library has no import options	

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
	stevey	5/29/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GraphicsGetImportOptions	proc	near
	clc
	ret
GraphicsGetImportOptions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the file is ICO format	

CALLED BY:	Impex	- GLOBAL

PASS:		SI	= fileHandle, open
RETURN:		AX	= TransError (0 = no error)
		CX	= format number if valid format
			  or NO_IDEA_FORMAT if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Won't work until I:

		* define an IcoHeader structure somewhere
		* figure out how to tell if it's a valid icon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/28/92		Initial version
	stevey	5/29/92		grabbed for ICO library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IcoHeader	struct
	IH_rsvd		word
	IH_type		word
IcoHeader	ends

TransGetFormat	proc	far
		uses	bx,dx,ds
		
		icoHeader	local	IcoHeader
		
		.enter
		
		mov	cx, size IcoHeader
		segmov	ds, ss			; read into local header struct
		lea	dx, icoHeader
		clr	al			; flags = 0
		mov	bx, si			; file
		call	FileRead		; rewind to beginning of file
		jc	notIcoFormat		; couldn't read header
		
		tst	icoHeader.IH_rsvd
		jnz	notIcoFormat

		cmp	icoHeader.IH_type, 1
		jne	notIcoFormat

		clr	cx			; cx <- format number
done:
		clr	ax			; ax <- TE_NO_ERROR
		.leave
		ret
notIcoFormat:
		mov	cx, NO_IDEA_FORMAT
		jmp	short	done
		
TransGetFormat	endp


ImportCode	ends
