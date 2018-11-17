COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiC.asm

AUTHOR:		Maryann Simmons, Jul 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	7/30/92		Initial revision


DESCRIPTION:
	
		

	$Id: uiC.asm,v 1.1 97/04/04 22:03:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

ImpexUICode	segment resource

COMMENT @---------------------------------------------------------------------
CFUNCTION:	ImpexImportExportCompleted

C DECLARATION:	extern void 
		  ImpexImportExportCompleted( ImpexTranslationParams itParams)
							
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	maryann	7/30	Initial version

-----------------------------------------------------------------------------@
IMPEXIMPORTEXPORTCOMPLETED	proc far itParams:fptr
	.enter
	mov	bp, itParams.offset
	call	ImpexImportExportCompleted
	.leave
	ret
IMPEXIMPORTEXPORTCOMPLETED endp


ImpexUICode	ends

	SetDefaultConvention

