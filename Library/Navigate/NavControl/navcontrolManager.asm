COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:    	Navigation Library	
MODULE:		Navigate Controller
FILE:		navControlMgr.asm

AUTHOR:		Alvin Cham, Sep 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/26/94   	Initial revision


DESCRIPTION:

	$Id: navcontrolManager.asm,v 1.1 97/04/05 01:24:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------------------------------
;   	Common Geode stuff
;---------------------------------------------------------------------------

include navigateGeode.def

DefLib	navigate.def

;---------------------------------------------------------------------------
;   	Resource definitions  	
;---------------------------------------------------------------------------
idata	segment

    NavigateControlClass    	    ; declare the class record

idata	ends


;---------------------------------------------------------------------------
;   	Resources
;---------------------------------------------------------------------------
include navcontrolManager.rdef


;---------------------------------------------------------------------------
;   	Code
;---------------------------------------------------------------------------

include navcontrolHistory.asm
include navcontrolUtils.asm
include navcontrol.asm
include navcontrolNotify.asm

