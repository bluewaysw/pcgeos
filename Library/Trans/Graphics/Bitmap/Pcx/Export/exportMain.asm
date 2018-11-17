COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		exportMain.asm<2>

AUTHOR:		Maryann Simmons, Apr 28, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB TransExport		perform export of a GString into PCX file
				format

    INT GraphicsGetExportOptions Returns the BitCount option to be used by
				the DIB library.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	4/28/92		Initial revision


DESCRIPTION:
	
		

	$Id: exportMain.asm,v 1.1 97/04/07 11:28:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef __HIGHC__
MAINEXPORTC	segment	word	public	'CODE'
global	ExportPcx:far 
MAINEXPORTC	ends
else
global	EXPORTPCX:far 
endif

ExportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform export of a GString into PCX file format

CALLED BY:	GLOBAL

PASS:		ds:si	ExportFrame

RETURN:		ax	- TransError error code, clear if no error
		bx	- handle to block containing Error String 
			  if ax = TE_CUSTOM
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		* just pass the Pcx export Translation routine that you want
		  to call and let the common code do the work

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
	mov	bx,vseg _ExportPcx	;segment of Pcx Export routine to call
	mov	ax,offset _ExportPcx	;offset  of Pcx Export routine to call
else
	mov	bx,vseg EXPORTPCX	;segment of Pcx Export routine to call
	mov	ax,offset EXPORTPCX	;offset  of Pcx Export routine to call
endif
	clr	cx			;no additional export options
	call	GraphicsExportCommon	;call the Common code to do the export

	.leave
	ret
TransExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the BitCount option to be used by the DIB library.
	
CALLED BY:	GraphicsExportCommon	
PASS:		ds:si	-ExportFrame
RETURN:		si 	-bitcount
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
	mov 	al,ds:[PEO_bitCount]	;get bitcount
	mov	si,ax
	call	MemUnlock		;have extracted necessary data
done:
	.leave
	ret

; if no options block was created, just set the default options
;
setDefault:
	mov	si,1			; there is no options block, so set the
					; default to monochrome
	jmp	done
GraphicsGetExportOptions	endp


ExportCode	ends


