COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiManager.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 8/92   	Initial version.

DESCRIPTION:
	

	$Id: uiManager.asm,v 1.1 97/04/04 18:04:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include gameGeode.def

;-----------------------------------------------------------------------------
;	DEF files		
;-----------------------------------------------------------------------------

include uiHighScore.def		; moved up by edwdig

GameClassStructures	segment	resource

	GameStatusControlClass
	HighScoreClass
	UnderlinedGlyphClass

GameClassStructures	ends

ifdef HIGH_SCORE_SOUND
UseLib	wav.def
endif

;-----------------------------------------------------------------------------
;	UI files		
;-----------------------------------------------------------------------------
 
include uiMain.rdef

;-----------------------------------------------------------------------------
;	Asm files		
;-----------------------------------------------------------------------------

GameControlCode	segment resource

include uiStatus.asm
include uiHighScore.asm
include uiControl.asm

GameControlCode	ends
