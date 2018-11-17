COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		UI
FILE:		uiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/3/92		Initial version

DESCRIPTION:
	Manager file for the GeoDex UI.

	$Id: uiManager.asm,v 1.1 97/04/04 15:50:51 newdeal Exp $

------------------------------------------------------------------------------@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	geodexGeode.def

include Mailbox/spooltd.def
include Mailbox/faxsendtd.def

;-----------------------------------------------------------------------------
;	Resources
;-----------------------------------------------------------------------------
include uiMain.rdef
