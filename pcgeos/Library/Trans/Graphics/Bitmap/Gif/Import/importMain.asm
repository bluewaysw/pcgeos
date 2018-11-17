COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		importMain.asm<2>

AUTHOR:		Maryann Simmons, May  4, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB TransImport		perform import of a Gif graphics file into
				a GString

    INT GraphicsGetImportOptions Return any import Options for the DIB
				library,push any options for the C
				translation Library.	 The GIF library
				has no import options

    INT TransGetFormat		Determines if the file is a valid GIF
				format by examining the header info

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 4/92		Initial revision


DESCRIPTION:
	
		

	$Id: importMain.asm,v 1.1 97/04/07 11:27:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ifdef __HIGHC__
MAINIMPORTC	segment	word	public 'CODE'
global	ImportGif:far
MAINIMPORTC	ends

MAINEXPORTC	segment	word	public	'CODE'
global	ExportGif:far
MAINEXPORTC	ends

else
global	IMPORTGIF:far
endif

ImportCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform import of a Gif graphics file into a GString

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
	mov	bx,vseg _ImportGif	;segment of the Gif main import routine
	mov	ax,offset _ImportGif	;offset  of the Gif main import routine
else
	mov	bx,vseg IMPORTGIF	;segment of the Gif main import routine
	mov	ax,offset IMPORTGIF	;offset  of the Gif main import routine
endif
	call 	GraphicsImportCommon	;call common code to do the import

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

SYNOPSIS:	Return any import Options for the DIB library,push any
		options for the C translation Library.	
		The GIF library has no import options

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

SYNOPSIS:	Determines if the file is a valid GIF format by
		examining the header info	

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
	uses	bx,dx,ds,si,di,bp
gifHeader	local	GIFHeader
	.enter

	mov	cx,size GIFHeader
	segmov	ds,ss			;read into local header struct
	lea	dx,gifHeader
	clr	al			;flags = 0
	mov	bx,si			;file
	call	FileRead
	jc	notGifFormat		;unsuccessful in reading header

	cmp	gifHeader.GH_sig1,'G'
	jne	notGifFormat
	cmp	gifHeader.GH_sig2,'I'
	jne	notGifFormat
	cmp	gifHeader.GH_sig3,'F'
	jne	notGifFormat
	cmp	gifHeader.GH_ver1,'8'
	jne	notGifFormat
	cmp	gifHeader.GH_ver2,'7'
	jne	ver1
ver2:
	cmp	gifHeader.GH_ver3,'a'
	jne	notGifFormat
	clr	cx			;cx <- format number
done:
	clr	ax			;ax <- TE_NO_ERROR
	.leave
	ret
ver1:
	cmp	gifHeader.GH_ver2,'9'
	je	ver2
notGifFormat:
	mov	cx,NO_IDEA_FORMAT
	jmp	done
TransGetFormat	endp



ImportCode	ends

















