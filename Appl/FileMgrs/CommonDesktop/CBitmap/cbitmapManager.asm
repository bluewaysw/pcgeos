COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop/CBitmap
FILE:		cbitmapManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version

DESCRIPTION:
	This file assembles the Bitmaps/ module of the desktop.

	$Id: cbitmapManager.asm,v 1.1 97/04/04 15:00:03 newdeal Exp $

------------------------------------------------------------------------------@

_Bitmap = 1

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

include cbitmapGeneric.asm

end
