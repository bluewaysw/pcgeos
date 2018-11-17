COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- Tif Graphics Translation Library
FILE:		exportMain.asm

AUTHOR:		Maryann Simmons	1/92

ROUTINES:
	Name			Description
	----			-----------
    GLB TransExport		perform export of a GString into Tif file
				format

    INT GraphicsGetExportOptions returns the bitcount to be used by the DIB
				library, as well as pushes the TIF export
				compression type for the C translation
				library call.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------


DESCRIPTION:
	This file contains the main interface to the export side of the 
	tif library
		

	$Id: exportMain.asm,v 1.1 97/04/07 11:27:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef __HIGHC__
MAINEXPORTC	segment	word	public	'CODE'
global	ExportTif:far 
MAINEXPORTC	ends
else
global	EXPORTTIF:far		
endif
	
ExportCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform export of a GString into Tif file format

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
	mov	bx,vseg	_ExportTif	;segment of the main Tif export routine
	mov	ax,offset _ExportTif	;offset  of the main Tif export routine
else
	mov	bx,vseg	EXPORTTIF	;segment of the main Tif export routine
	mov	ax,offset EXPORTTIF	;offset  of the main Tif export routine
endif
	mov	cx,2			;num bytes required for export options
	call	GraphicsExportCommon	;call the common code to export to Tif

	.leave
	ret

TransExport	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the bitcount to be used by the DIB library, as well
		as pushes the TIF export compression type for the C
		translation library call.

CALLED BY:	GraphicsExportCommon
PASS:		ds:si	- ExportFrame		
		ss:bp	- location to put the export options

RETURN:		si	- Bit Count
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		* save away the return address so that the format can be
		  pushed on the stack for the upcoming C routine call

		* Lock down the Export Options block

		* extract the Bitcount to be returned 
	
		* push the TIF compression format 

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
	call	MemLock			;takes bx=handle,ret ax = address 
	jc	setDefault			;unable to lock Options Block
	
	segmov	ds,ax			;address of options block
	clr	ah
	mov 	al,ds:[TEO_bitCount]	;get bitcount
	mov	si,ax			;si export Option( bit count) 

	mov	ax,ds:[TEO_compress]
	mov	ss:[bp],ax		;save compression format

	call	MemUnlock		;have extracted necessary data

done:
	.leave
	ret
setDefault:
	mov	si,1			; set default bitcount to monochrome
	mov	ax, TIF_AUTOCMPR	; set default to auto compression
	mov	ss:[bp], ax		
	jmp	done
GraphicsGetExportOptions	endp


ExportCode	ends




