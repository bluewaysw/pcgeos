COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Blank
FILE:		blank.asm

AUTHOR:		Gene, Mar  25, 1991

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/23/91		Initial revision

DESCRIPTION:
	This is a specific screen-saver library

	$Id: blank.asm,v 1.1 97/04/04 16:44:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

UseLib	saver.def

;==============================================================================
;
;		       CONSTANTS AND DATA TYPES
;
;==============================================================================

BlankProcessClass	class	GenProcessClass
BlankProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	blank.rdef

udata	segment

udata	ends

idata	segment

	BlankProcessClass	mask CLASSF_NEVER_SAVED

idata	ends

