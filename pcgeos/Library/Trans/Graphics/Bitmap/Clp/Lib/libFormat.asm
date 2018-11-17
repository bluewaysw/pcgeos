COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		libFormat.asm

AUTHOR:		Maryann Simmons, May 12, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/12/92		Initial revision


DESCRIPTION:
	
		

	$Id: libFormat.asm,v 1.1 97/04/07 11:26:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DefTransLib

DefTransFormat	GF_CLP_B, \
		"CLP", \
		"*.clp", \
		0, \
		ExportOptions, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>

EndTransLib	<mask IDC_GRAPHICS>


idata	segment
	threadSem	hptr	0
idata	ends

