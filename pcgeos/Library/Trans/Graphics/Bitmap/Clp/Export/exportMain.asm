COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		exportMain.asm

AUTHOR:		Maryann Simmons, May 12, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB TransExport		perform export of a GString into Clp file
				format

    INT GraphicsGetExportOptions Returns the bit Count to be used by the
				DIB Library

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/12/92		Initial revision


DESCRIPTION:
	
		

	$Id: exportMain.asm,v 1.1 97/04/07 11:26:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	
ifdef __HIGHC__
MAINEXPORTC	segment	word	public	'CODE'
global	ExportClp:far 
MAINEXPORTC	ends
else
global	EXPORTCLP:far 
endif

ExportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform export of a GString into Clp file format

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
	mov	bx,vseg _ExportClp	;segment of Clp Export routine to call
	mov	ax,offset _ExportClp	;offset  of Clp Export routine to call
else
	mov	bx,vseg EXPORTCLP	;segment of Clp Export routine to call
	mov	ax,offset EXPORTCLP	;offset  of Clp Export routine to call
endif
	clr	cx

	call	GraphicsExportCommon	;call the Common code to do the export

	.leave
	ret
TransExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GraphicsGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the bit Count to be used by the DIB Library	

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

	mov	bx,ds:[si].EF_exportOptions	;handle to options block
	tst	bx
	jz	setDefault	
	call	MemLock			;takes bx=handle,ret ax = address 
	jc	setDefault			;unable to lock Options Block
	
	segmov	ds,ax			;address of options block
	clr	ah
	mov 	al,ds:[CEO_bitCount]	;get bitcount
	mov	si,ax			;si:export Option( bit count) 

	call	MemUnlock		;have extracted necessary data
done:
	.leave
	ret
setDefault:
	mov	si,1			; set bit count to default mono
	jmp	done
GraphicsGetExportOptions	endp

ExportCode	ends
