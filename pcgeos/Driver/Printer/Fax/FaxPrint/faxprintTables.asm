COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Tiramisu
MODULE:		Fax Print Driver
FILE:		faxprintTables.asm

AUTHOR:		Andy Chiu, Oct  2, 1993
		Jeremy Dashe, Oct 7, 1994

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 2/93   	Initial revision
	jdashe	10/ 7/94   	Tiramisu-ized


DESCRIPTION:
	This file contains any printer specific fixed code tables
		
	$Id: faxprintTables.asm,v 1.1 97/04/18 11:53:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;--------------------------------------------------------------------------
;	Escape codes supported and routine table
;--------------------------------------------------------------------------

if 0
escCodes	label	word			; escape codes supported
	word	DR_PRINT_ESC_PREPEND_PAGE

NUM_ESC_ENTRIES	equ	($ - escCodes)/2


escHanJumpTable hptr	handle CommonCode

escOffJumpTable nptr.far	\
			FaxInfoPrintCoverSheet
endif
