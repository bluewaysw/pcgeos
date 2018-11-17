
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		printer drivers
FILE:		red64Page.asm

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
	Dave	2/93	initial version

DESCRIPTION:

	$Id: red64Page.asm,v 1.1 97/04/18 11:55:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

include	Page/pageStartRedwood.asm
include	Page/pageEndRedwood.asm
