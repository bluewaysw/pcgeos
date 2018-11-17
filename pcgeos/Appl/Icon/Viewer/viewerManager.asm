COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1994.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Icon editor
MODULE:		Viewer
FILE:		viewerManager.asm

AUTHOR:		Steve Yegge, Jun 17, 1994

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/17/94		Initial revision

DESCRIPTION:

	Manager file for Viewer module.

	$Id: viewerManager.asm,v 1.1 97/04/04 16:06:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	iconGeode.def

include	viewerConstant.def

;-----------------------------------------------------------------------------
;		Classes
;-----------------------------------------------------------------------------

idata	segment
	VisIconClass
idata	ends

;-----------------------------------------------------------------------------
;		Code
;-----------------------------------------------------------------------------

include	viewerVisIcon.asm
include	viewerMain.asm
include	viewerKbd.asm
include	viewerUI.asm
