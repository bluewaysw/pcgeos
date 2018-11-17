
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet print driver
FILE:		pcl4Tables.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision


DESCRIPTION:
	This file contains any printer specific fixed code tables
		
	$Id: pcl4Tables.asm,v 1.1 97/04/18 11:52:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



;--------------------------------------------------------------------------
;	Escape codes supported and routine table
;--------------------------------------------------------------------------

escCodes	label	word			; escape codes supported
	word	DR_PRINT_ESC_SET_COPIES

NUM_ESC_ENTRIES	equ	($ - escCodes)/2


escHanJumpTable label	word
                hptr    handle  CommonCode

escOffJumpTable label	word
                word    offset  PrintEscSetCopies
