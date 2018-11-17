
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		importMain.asm

AUTHOR:		Jim DeFrisco, 12 Feb 1991

ROUTINES:
	Name			Description
	----			-----------
	TransGetImportUI	returns resource handle of Import UI
	TransGetImportOptions	gets options from UI gadgets
	TransImport		import function

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/91		Initial revision


DESCRIPTION:
	This file contains the main interface to the import side of the 
	library
		

	$Id: importMain.asm,v 1.1 97/04/07 11:25:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform import of a graphics file

CALLED BY:	GLOBAL

PASS:		dx	- block containing options, zero to use default
		si	- file handle for source file 
		di	- gstring handle to destination for import

RETURN:		ax	- TransError error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		perform the importation

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransImport	proc	far
		mov	ax, TE_IMPORT_NOT_SUPPORTED	; just return error
		ret
TransImport	endp

ImportCode	ends
