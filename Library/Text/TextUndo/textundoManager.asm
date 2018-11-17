COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textUndoManager.asm

AUTHOR:		John Wedgwood, Apr 17, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 4/17/92	Initial revision

DESCRIPTION:
	Manager file for the TextUndo module.

	$Id: textundoManager.asm,v 1.1 97/04/07 11:22:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	textGeode.def
include texttext.def
include textstorage.def
include textssp.def
include textattr.def
include textselect.def
include textregion.def
include texttrans.def
include textline.def
include textundo.def

include Internal/im.def
include system.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include	tuConstant.def

;-----------------------------------------------------------------------------
;	Include variables and tables for this module
;-----------------------------------------------------------------------------

include	tuVariables.asm
include tuStrings.rdef
include tuMain.asm
