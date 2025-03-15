COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Impex
MODULE:		Template Translation Library
FILE:		exportMain.asm

AUTHOR:		Jenny Greenwood, 2 September 1992

ROUTINES:
	Name			Description
	----			-----------
GLB	TransExport		Exports from transfer item to output file

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/2/92		Initial version

DESCRIPTION:
	This file contains the main interface to the export side of the 
	library
		

	$Id: exportMain.asm,v 1.1 97/04/07 11:40:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EXPORTMAINC	segment	word	public	'CODE'

global	ExportToTemplate:far

EXPORTMAINC	ends

TextCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export from transfer item to final Template file

CALLED BY:	GLOBAL
PASS:		ds:si	- ExportFrame on stack
RETURN:		ax	- TransError (0 = no error)
		bx	- memory handle of error text if ax = TE_CUSTOM

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		Pass TextCommonExport the address of the routine to call.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jenny	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransExport	proc	far
		mov	bx, vseg ExportToTemplate
		mov	ax, offset ExportToTemplate
		call	TextCommonExport
		ret
TransExport		endp

TextCommonCode	ends
