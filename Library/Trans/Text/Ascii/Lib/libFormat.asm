COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Ascii Translation Library
FILE:		libMain.asm

AUTHOR: 	Jenny Greenwood, 2 September 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/2/92		Initial version
	witt	3/14/94 	Added JIS text for Pizza/J

DESCRIPTION:
	This file contains the defined formats for this translation library.
		
	$Id: libFormat.asm,v 1.1 97/04/07 11:40:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Define all of the formats we support, and the structures Impex expects.
;
DefTransLib

if DBCS_PCGEOS

DefTransFormat	TF_ASCII, \
		"SJIS Text", \
		"*", \
		0, \
		0, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>
CheckHack < TF_ASCII eq IDSF_ASCII >

DefTransFormat	TF_JIS, \
		"JIS Text", \
		"*", \
		0, \
		0, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>

CheckHack < TF_JIS eq IDSF_JIS >
else

DefTransFormat	TF_ASCII, \
		"ASCII or Plain Text", \
		"*", \
		0, \
		0, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>
CheckHack < TF_ASCII eq IDSF_ASCII >
endif

EndTransLib	<mask IDC_TEXT>
