
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		LaserJet printer driver
FILE:		printcomPCLPage.asm

AUTHOR:		Dave Durran

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
	Dave	1/92	initial version from laserdwnPage.asm

DESCRIPTION:

	$Id: printcomPCLPage.asm,v 1.1 97/04/18 11:50:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

include	Page/pageStart.asm
include	Page/pageEndASFOnly.asm
