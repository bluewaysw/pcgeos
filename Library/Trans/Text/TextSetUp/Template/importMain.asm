COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Impex
MODULE:		Template Translation Library
FILE:		importMain.asm

AUTHOR:		Jenny Greenwood, 2 September 1992

ROUTINES:
	Name				Description
	----				-----------
    GLB TransImport		Import from Template file to transfer item

    GLB TransGetFormat		Determines if the file is in Template
				format.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/2/92		Initial version

DESCRIPTION:
	This file contains the main interface to the import side of the 
	library
		

	$Id: importMain.asm,v 1.1 97/04/07 11:40:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


IMPORTMAINC	segment	word	public 'CODE'

global	ImportFromTemplate:far
global	TemplateGetFormat:far

IMPORTMAINC	ends

TextCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import from Template file to transfer item

CALLED BY:	GLOBAL
PASS:		ds:si	- ImportFrame on stack
RETURN:		ax	- TransError (0 = no error)
		bx	- memory handle of error text if ax = TE_CUSTOM
		dx:cx	- VM chain containing transfer item

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		Pass TextCommonImport the address of the routine to call.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jenny	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransImport		proc	far
		mov	bx, vseg ImportFromTemplate
		mov	ax, offset ImportFromTemplate
		call	TextCommonImport
		ret
TransImport		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the file is a Template format.	

CALLED BY:	GLOBAL
PASS:		si	- file handle (open for read)	
RETURN:		ax	- TransError (0 = no error)
		cx	- format number if valid format
			  or NO_IDEA_FORMAT if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransGetFormat	proc	far
		uses	bx, di
		.enter
		mov	bx, vseg TemplateGetFormat
		mov	di, offset TemplateGetFormat
		call	TextCommonGetFormat
		.leave
		ret
TransGetFormat	endp

TextCommonCode	ends
