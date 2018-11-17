COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	Amateur Night
FILE:		hiscore.asm

AUTHOR:		Andrew Wilson, Jan  3, 1991

ROUTINES:
	Name			Description
	----			-----------
	HiScoreInit		Initializes the hiscore display and database
	HiScoreAddScore		Adds a new score to the high score table if
				it is high enough, and if so, displays the
				high score table.
	HiScoreDisplay		Displays the high score database
	HiScoreExit		Exits from the high score database

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 3/91		Initial revision

DESCRIPTION:
	This file contains routines to implement the hiscore tables for Tetris.
	It would probably be a good idea to bump this to a library or something
	eventually. The format for the database file map block is:

		word	# scores in the file
		dword	first score
		dw	Group, Item of name for first score
		dword	second score
		dw	Group, Item of name for second score
			...


	$Id: amateurHiScore.asm,v 1.1 97/04/04 15:11:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
