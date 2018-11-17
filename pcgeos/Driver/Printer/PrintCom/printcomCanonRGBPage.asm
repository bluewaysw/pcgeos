
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) MyTurn.com 2000 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		printcomCanonRGBPage.asm

AUTHOR:		Dave Hunter

ROUTINES:
	Name		Description
	----		-----------
	PrintStartPage	initialize the page-related variables, called once/page
			by EXTERNAL at start of page.
	PrintEndPage	Tidy up the page-related variables, called once/page
			by EXTERNAL at end of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	DH	5/19/00	Initial version

DESCRIPTION:

	$$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

include	Page/pageStartCanonRGB.asm
include	Page/pageEndCanonRGB.asm
