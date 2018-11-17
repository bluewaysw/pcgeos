COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		exportMain.asm<2>

AUTHOR:		Maryann Simmons, Apr 28, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB TransExport		perform export of a GString into Gif file
				format

    INT GraphicsGetExportOptions Returns the Bitcount option to be used by
				the DIB library

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	4/28/92		Initial revision


DESCRIPTION:
	
		

	$Id: exportMain.asm,v 1.1 97/04/07 11:26:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef __HIGHC__
MAINEXPORTC	segment	word	public	'CODE'
global	_ExportGif:far 
MAINEXPORTC	ends
else
global	EXPORTGIF:far 
endif

ExportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform export of a GString into Gif file format

CALLED BY:	GLOBAL

PASS:		ds:si	ExportFrame

RETURN:		ax	- TransError error code, clear if no error
		bx	- handle to block containing Error String 
			  if ax = TE_CUSTOM
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransExport	proc	far
	uses cx
	.enter

ifdef __HIGHC__
	mov	bx,vseg	_ExportGif	;segment of the GIF main import routine
	mov	ax,offset _ExportGif	;offset  of the GIF main import routine
else
	mov	bx,vseg	EXPORTGIF	;segment of the GIF main import routine
	mov	ax,offset EXPORTGIF	;offset  of the GIF main import routine
endif
	clr	cx			;no additional export options

	call	GraphicsExportCommon	;call common code to do the export
	.leave
	ret
TransExport	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the Bitcount option to be used by the DIB library

CALLED BY:	GraphicsExportCommon
PASS:		ds:si	- ExportFrame

RETURN:		si	-BitCount		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GraphicsGetExportOptions	proc	near
	uses	ax,bx,ds
	.enter

	mov	bx,ds:[si].EF_exportOptions
	tst	bx			;handle to options block
	jz	setDefault	
	call	MemLock			;takes bx=handle,ret ax = address 
	jc	setDefault		;unable to lock Options Block
	segmov	ds,ax			;address of options block
	clr	ah
	mov 	al,ds:[GEO_bitCount]	;get bitcount
	mov	si,ax			;si:export Option( bit count) 

	call	MemUnlock		;have extracted necessary data
done:
	.leave
	ret
setDefault:
	mov	si,1			; set default bitcount to monochrome
	jmp	done
GraphicsGetExportOptions	endp


ExportCode	ends

