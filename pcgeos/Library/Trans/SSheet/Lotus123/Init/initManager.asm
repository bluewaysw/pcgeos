
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:
		
	$Id: initManager.asm,v 1.1 97/04/07 11:41:54 newdeal Exp $


-------------------------------------------------------------------------------@

_Init = 1

include lotus123Geode.def
include lotus123Constant.def

DefTransLib
if DBCS_PCGEOS	;1994-09-05(Mon)TOK ----------------
;;DefTransFormat	TF_LOTUS_2J, \
;;		"Lotus 1-2-3 R2J(experiment)", \
;;		"*.WJ1", \
;;		0, \
;;		0, \
;;		<mask IFI_IMPORT_CAPABLE>
;;
DefTransFormat	TF_LOTUS_21J_TO_23J, \
		"Lotus 1-2-3 R2.1J-R2.3J", \
		"*.WJ2", \
		0, \
		0, \
		<mask IFI_IMPORT_CAPABLE>
;;
;;DefTransFormat	TF_LOTUS_24J, \
;;		"Lotus 1-2-3 R2.4J(experiment)", \
;;		"*.WJ3", \
;;		0, \
;;		0, \
;;		<mask IFI_IMPORT_CAPABLE>
else
DefTransFormat	TF_LOTUS_10_OR_1A, \
		"Lotus 1-2-3, version 1.0 or 1A", \
		"*.WKS", \
		0, \
		0, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>
DefTransFormat	TF_LOTUS_20_TO_22, \
		"Lotus 1-2-3, version 2.0 - 2.3", \
		"*.WK1", \
		0, \
		0, \
		<mask IFI_IMPORT_CAPABLE or \
		 mask IFI_EXPORT_CAPABLE>

EndTransLib	<mask IDC_SPREADSHEET>
endif
ResidentCode	segment	resource
	global	TransLibraryEntry:far

	include	init.asm
ResidentCode	ends

end
