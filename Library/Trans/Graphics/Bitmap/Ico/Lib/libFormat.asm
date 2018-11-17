COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- Ico Translation Library	
FILE:		libFormat.asm

AUTHOR:		Steve Yegge, March 29, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/12/92		Initial revision
	stevey	5/29/93		port to ICO


DESCRIPTION:

	This is the main assembly file for the library module of the 
	Ico translation library		

	$Id: libFormat.asm,v 1.1 97/04/07 11:29:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefTransLib	

DefTransFormat	GF_ICO_B, \
		"ICO", \
		"*.ico", \
		0, \
		0, \
		<mask IFI_IMPORT_CAPABLE>
		
EndTransLib	<mask IDC_GRAPHICS>


idata	segment
	threadSem	hptr	0
idata	ends

