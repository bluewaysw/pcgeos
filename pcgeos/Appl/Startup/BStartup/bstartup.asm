COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	BULLET
MODULE:		startup
FILE:		bstartup.asm

AUTHOR:		Steve Yegge

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

	

DESCRIPTION:
		

	$Id: bstartup.asm,v 1.1 97/04/04 16:52:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		General stuff
;-----------------------------------------------------------------------------

include	stdapp.def
include initfile.def
include timedate.def
include localize.def
include	system.def

;-----------------------------------------------------------------------------
;		Mouse-dependent stuff
;-----------------------------------------------------------------------------

include	Objects/winC.def
include Objects/inputC.def
include Internal/mouseDr.def
include Internal/videoDr.def
include timer.def

;-----------------------------------------------------------------------------
;		Libraries used
;-----------------------------------------------------------------------------

UseLib	bullet.def
UseLib	Objects/vTextC.def
UseLib	config.def

;-----------------------------------------------------------------------------
;		Local include files
;-----------------------------------------------------------------------------

include	bstartup.def
include bstartup.rdef

;-----------------------------------------------------------------------------
;		included code
;-----------------------------------------------------------------------------

idata	segment

	BSProcessClass	mask CLASSF_NEVER_SAVED
	BSApplicationClass
	VisScreenContentClass
	VisScreenClass
	BSPrimaryClass
	BSTimeDateDialogClass
	WelcomeContentClass

	doingSomething		DoingSomething	DS_WELCOME
idata	ends

include	bsCalibrate.asm
include bsWelcome.asm
include bsTimeDate.asm

Code	segment	resource

include bsProcess.asm
include bsPrimary.asm

Code	ends
