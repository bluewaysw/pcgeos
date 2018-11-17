COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All rights reserved

PROJECT:	Peanut command	
MODULE:		--
FILE:		amateurMain

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:
	This file links all the other .asm files together

	$Id: amateurMain.asm,v 1.1 97/04/04 15:11:54 newdeal Exp $
-----------------------------------------------------------------------------@



;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include	stdapp.def
include gstring.def
include timer.def
include system.def
include Objects/inputC.def
include Objects/vTextC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	sound.def
UseLib	game.def

include	amateurMacros.def
include	amateurConstants.def
include amateurObjects.def	

include amateur.rdef

;-----------------------------------------------------------------------------
;	CLASS RECORDS		
;-----------------------------------------------------------------------------
 
idata	segment

	AmateurProcessClass	mask	CLASSF_NEVER_SAVED
	AmateurContentClass
	MovableObjectClass	mask	CLASSF_NEVER_SAVED	
	AmateurPelletClass	mask	CLASSF_NEVER_SAVED	
	AmateurPeanutClass	mask	CLASSF_NEVER_SAVED	
	AmateurCloudClass	mask	CLASSF_NEVER_SAVED	
	TomatoClass		mask	CLASSF_NEVER_SAVED
	BitmapClass
	ClownClass	
	BlasterClass	

include	circles.def

idata 	ends

AmateurCode	segment

include amateurCommon.asm
include amateurContent.asm
include amateurPellet.asm
include amateurCloud.asm 
include amateurClown.asm
include amateurProcess.asm
include	amateurPeanut.asm
include amateurTomato.asm
include amateurDisplay.asm
include amateurRandom.asm
include amateurJoke.asm
include amateurBitmap.asm
include amateurBlaster.asm

AmateurCode	ends

include amateurSound.asm
include amateurHiScore.asm




