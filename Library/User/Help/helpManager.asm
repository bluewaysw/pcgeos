COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Help
FILE:		helpManager.asm

AUTHOR:		Gene Anderson, Oct 22, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/22/92		Initial revision


DESCRIPTION:
	Manager file for Help module of UI library

	$Id: helpManager.asm,v 1.1 97/04/07 11:47:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Standard Includes
;------------------------------------------------------------------------------

include uiGeode.def
include timer.def	
UseLib	Objects/vTextC.def

UseLib	compress.def
;------------------------------------------------------------------------------
;			Our Includes
;------------------------------------------------------------------------------

include helpConstant.def
include helpText.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include helpControl.rdef

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include helpEC.asm

include helpControl.asm
include helpLink.asm
include helpTextUtils.asm
include helpFile.asm
include helpHistory.asm
include helpName.asm
include helpUtils.asm
include helpHint.asm
include helpFirstAid.asm
include helpHelp.asm

include helpTextClass.asm

include helpPointerImage.asm

include helpRoutines.asm

include helpC.asm
