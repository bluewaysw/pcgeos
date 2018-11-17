COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex - Icon Translation Library
FILE:		exportMain.asm

AUTHOR:		Steve Yegge, May 29, 1993

ROUTINES:
	Name			Description
	----			-----------
   GLB	TransExport		perform export of a GString into Ico format

   INT	GraphicsGetExportOptions returns the BitCount option to be used
				by the DIB library.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/29/93		Initial revision

DESCRIPTION:
	

	$Id: exportMain.asm,v 1.1 97/04/07 11:29:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef __HIGHC__
MAINEXPORTC	segment	word	public	'CODE'
global	ExportIco:far
MAINEXPORTC	ends
else
global	EXPORTICO:far
endif

ExportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	peform export of a GString into ICO format

CALLED BY:	GLOBAL

PASS:		ds:si	= ExportFrame

RETURN:		ax	= TransError error code; clear if no error
		bx	= handle to block containing Error String
			  if ax = TE_CUSTOM

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/29/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransExport	proc	far
		uses	cx
		.enter

ifdef __HIGHC__
		mov	bx, vseg _ExportIco	; segment of ICO Export routine
		mov	ax, offset _ExportIco	;  offset of ICO Export routine
else
		mov	bx, vseg EXPORTICO	; segment of ICO Export routine
		mov	ax, offset EXPORTICO	;  offset of ICO Export routine
endif
		clr	cx			; no additional export options
		call	GraphicsExportCommon	; call common code for export

		.leave
		ret
TransExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the BitCount option to be used by the DIB library,
		and pushes the ICO export format type for the C translation
		library call.

CALLED BY:	GraphicsExportCommon

PASS:		ds:si	= ExportFrame
		ss:bp	= location on stack to store export options

RETURN:		si	= bitcount
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/29/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GraphicsGetExportOptions	proc	near
		uses	ax,bx,ds
		.enter

		mov	bx,ds:[si].EF_exportOptions
		tst	bx		;handle to options block
		jz	setDefault
		call	MemLock		;lock Option block:bx=handle ax address
		jc	setDefault	;unable to lock Options Block
		
		segmov	ds,ax		;address of options block
		clr	ah		;will mov bitCount into al
		mov	al,ds:[IEO_bitCount]	;get Bit Count
		mov	si,ax		;si=Export Options( bit count)
		
		mov	ax,ds:[IEO_format]
		mov	ss:[bp],ax	;save output format
		call	MemUnlock	;have extracted necessary data
done:
		.leave
		ret
setDefault:
	; if there is no options block, set the default options
		mov	si,1		; Monochrome
		mov	ax, ICO_WIN30 
		mov	ss:[bp], ax	; Ico output format
		jmp	done
		
GraphicsGetExportOptions	endp

ExportCode	ends
