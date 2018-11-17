COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userLibrary.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	???			???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to implement the User Interface library.

	$Id: userLibrary.asm,v 1.1 97/04/07 11:46:02 newdeal Exp $

-------------------------------------------------------------------------------@

Init segment resource
if 0

COMMENT @----------------------------------------------------------------------

FUNCTION:	LibraryEntry

DESCRIPTION:	Library entry/exit routine for UI library.

CALLED BY:	GLOBAL

PASS:	ds	- core block
	di	- LibraryCallType - LCT_ATTACH or LCT_DETACH
	cx:dx	- command line parameters

RETURN:
	carry	- clear to indicate no error

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

LibraryEntry	proc	far
;	cmp	di, LCT_ATTACH
;	jnz	LE_exit

	clc
	ret

;LE_exit:
;	clc
;	ret

LibraryEntry	endp

endif
Init ends
