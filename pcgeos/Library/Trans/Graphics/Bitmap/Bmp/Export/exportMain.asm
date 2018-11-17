COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- BmpGraphics Translation Library
FILE:		exportMain.asm

AUTHOR:		

ROUTINES:
	Name			Description
	----			-----------
    GLB TransExport		perform export of a GString into Bmp format

    INT GraphicsGetExportOptions returns the bitcount to be used by the DIB
				library, as well as pushes the BMP export
				format type for the C translation library
				call.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:
	This file contains the main interface to the export side of the 
	bmp library
		

	$Id: exportMain.asm,v 1.1 97/04/07 11:26:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef __HIGHC__
MAINEXPORTC	segment	word	public	'CODE'
global	ExportBmp:far
MAINEXPORTC	ends
else
global	EXPORTBMP:far
endif

ExportCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform export of a GString into Bmp format

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
	mov	bx,vseg _ExportBmp	;segment of Pcx Export routine to call
	mov	ax,offset _ExportBmp	;offset  of Pcx Export routine to call
else
	mov	bx,vseg EXPORTBMP	;segment of Pcx Export routine to call
	mov	ax,offset EXPORTBMP	;offset  of Pcx Export routine to call
endif
	mov	cx,2			;number of bytes required for export
					;options
	call	GraphicsExportCommon	;call graphics Common Code to do work
	
	.leave
	ret
TransExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the bitcount to be used by the DIB library, as well 
		as pushes the BMP export format type for the C translation
		library call.	

CALLED BY:	GraphicsExportCommon
PASS:		ds:si	- ExportFrame
		ss:bp	- Location on stack to store export options
		
RETURN:		si	-bit count
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		* save away the return address so that the format can be pushed
		  on the stack for the upcoming C routine call

		* Lock down the Export Options block
		
		* extract the Bitcount to be returned

		* push the BMP export format

		* restore the return address to the stack

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
	call	MemLock			;lock Option block:bx=handle ax address
	jc	setDefault		;unable to lock Options Block

	segmov	ds,ax			;address of options block
	clr	ah			;will mov bitCount into al
	mov	al,ds:[BEO_bitCount]	;get Bit Count
	mov	si,ax			;si=Export Options( bit count)

	mov	ax,ds:[BEO_format]
	mov	ss:[bp],ax		;save output format
	call	MemUnlock		;have extracted necessary data
done:
	.leave
	ret
setDefault:
	; if there is no options block, set the default options
	mov	si,1			; Monochrome
	mov	ax, BMP_WIN30 
	mov	ss:[bp], ax	; Bmp output format
	jmp	done

GraphicsGetExportOptions	endp


ExportCode	ends












