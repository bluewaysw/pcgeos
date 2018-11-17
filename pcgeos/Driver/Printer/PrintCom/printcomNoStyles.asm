
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet Print Driver
FILE:		printcomNoStyles.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/22/92		Initial revision from laserjetStyles.asm


DC_ESCRIPTION:
	This file contains all the style setting far calls for dummy routines
		
	$Id: printcomNoStyles.asm,v 1.1 97/04/18 11:50:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetStyles  proc far
	clr	cx
PrintSetStyles  label    far
	clc
	ret
PrintGetStyles  endp

PrintTestStyles proc    far
	clr	dx
	clc
	ret
PrintTestStyles endp

PrintClearStyles  proc    near
	clc
	ret
PrintClearStyles  endp
