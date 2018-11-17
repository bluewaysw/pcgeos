COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- Tif Translation Library	
FILE:		libFormat.asm

AUTHOR:		Maryann Simmons, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/12/92		Initial revision


DESCRIPTION:
	This is the main assembly file for the library module of the 
	tif translation library		

	$Id: libFormat.asm,v 1.1 97/04/07 11:27:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefTransLib

DefTransFormat	GF_TIF_B, \
		"TIFF", \
		"*.tif", \
		0, \
		ExportOptions, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>

EndTransLib	<mask IDC_GRAPHICS>


idata	segment
	threadSem	hptr	0
idata	ends

