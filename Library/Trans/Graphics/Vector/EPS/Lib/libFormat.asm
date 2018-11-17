COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- EPS Translation Library	
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
	Pcx translation library		

	$Id: libFormat.asm,v 1.1 97/04/07 11:25:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefTransLib

DefTransFormat	GF_EPS, \
		"EPS", \
		"*.eps", \
		0, \
		0, \
		<mask IFI_EXPORT_CAPABLE>

EndTransLib	<mask IDC_GRAPHICS>


