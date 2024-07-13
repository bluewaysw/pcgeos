COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           spriteManager.asm

AUTHOR:         Martin Turon, Nov  8, 1994

ROUTINES:
	Name                    Description
	----                    -----------

	
REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	martin  11/8/94         Initial version


DESCRIPTION:
	
		

	$Id: manager.asm,v 1.1 98/07/06 19:04:50 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;                       Includes
;----------------------------------------------------------------------------

include stdapp.def
include game.def
UseLib  sprite.def

include sprite.rdef

;----------------------------------------------------------------------------
;                       Class Declarations
;----------------------------------------------------------------------------

idata segment
SpriteClass
SpriteContentClass
idata ends

;-----------------------------------------------------------------------------
;                       Source Files
;-----------------------------------------------------------------------------

SpriteCode      segment

include spriteMain.asm
include spriteContent.asm

SpriteCode      ends



