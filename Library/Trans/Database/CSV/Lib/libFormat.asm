COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CSV/Lib		
FILE:		libFormat.asm

AUTHOR:		Ted H. Kim, 4/7/92

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	4/92		Initial revision

DESCRIPTION:
	This file contains the library definition of CSV.	

	$Id: libFormat.asm,v 1.1 97/04/07 11:42:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefTransLib	

DefTransFormat	TF_COMMA_SEPARATED, \
		"Comma Separated Value", \
		"*.CSV", \
		ImportOptionsGroup, \
		ExportOptionsGroup, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>

EndTransLib	<mask IDC_SPREADSHEET>

idata   segment
	ImpexMappingControlClass
idata   ends
