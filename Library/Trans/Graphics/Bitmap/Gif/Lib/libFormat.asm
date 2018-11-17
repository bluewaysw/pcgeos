COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		libFormat.asm

AUTHOR:		Maryann Simmons, May  4, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jimmy	1/92		Initial revision


DESCRIPTION:
	This is the main assembly file for the library module of the 
	gif translation library
		

	$Id: libFormat.asm,v 1.1 97/04/07 11:27:17 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefTransLib

DefTransFormat	GF_GIF_B, \
		"GIF", \
		"*.gif", \
		0, \
		ExportOptions, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>


EndTransLib	<mask IDC_GRAPHICS>


idata	segment
	threadSem	hptr	0
idata	ends






