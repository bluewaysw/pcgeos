COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Hearts (trivia project)
FILE:		heartsHand.asm

AUTHOR:		Peter Weck, Mar 17, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/17/93   	Initial revision


DESCRIPTION:
	
		

	$Id: heartsHand.asm,v 1.1 97/04/04 15:19:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

	HeartsHandClass

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

udata	ends


;------------------------------------------------------------------------------
;		Code for HeartsHandClass
;------------------------------------------------------------------------------
CommonCode	segment resource		;start of code resource






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HeartsHandSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	will save the state of the Hand.

CALLED BY:	HeartsGameRestoreState
PASS:		*ds:si	= HeartsHandClass object
		ds:di	= HeartsHandClass instance data


RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	3/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HeartsHandSaveState	method dynamic HeartsHandClass, 
					MSG_DECK_SAVE_STATE
	.enter

	call	ObjMarkDirty

	.leave
	ret
HeartsHandSaveState	endm




CommonCode	ends				;end of CommonCode resource
