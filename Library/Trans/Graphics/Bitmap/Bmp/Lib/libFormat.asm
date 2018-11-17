COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- Bmp Translation Library	
FILE:		libFormat.asm

AUTHOR:		

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/12/92		Initial revision


DESCRIPTION:
	This is the main assembly file for the library module of the 
	Bmp translation library		

	$Id: libFormat.asm,v 1.1 97/04/07 11:26:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefTransLib	

DefTransFormat	GF_BMP_B, \
		"BMP", \
		"*.bmp", \
		0, \
		ExportOptions, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>
		
EndTransLib	<mask IDC_GRAPHICS>


idata	segment
	threadSem	hptr	0
idata	ends

