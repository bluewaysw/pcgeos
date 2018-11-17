COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Hyperlink Library
FILE:		hyperlinkManager.asm

AUTHOR:		Jenny Greenwood, May 23, 1994

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JG	5/23/94   	Initial revision


DESCRIPTION:
	Manager file for hyperlink controller.	
		

	$Id: hyperlinkManager.asm,v 1.1 97/04/04 18:09:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;			System Includes
;-----------------------------------------------------------------------------

include	geos.def
include	resource.def
include	heap.def
include	ec.def			; Error checking macros.
include geode.def
include object.def		; Object support.
include library.def

include geoworks.def		; Controller notification enums

;-----------------------------------------------------------------------------
;			System Libraries
;-----------------------------------------------------------------------------

UseLib	Objects/vTextC.def

;-----------------------------------------------------------------------------
;			Library Declaration
;-----------------------------------------------------------------------------

DefLib	hyprlnk.def

;-----------------------------------------------------------------------------
;			Local includes
;-----------------------------------------------------------------------------

include hyperlink.rdef
include	hyperlinkConstant.def	; Global constants.

idata segment
idata ends

HyperlinkClassStructures	segment	resource
	HyperlinkControlClass			;declare the class record
	PageNameControlClass			;declare the class record
HyperlinkClassStructures	ends

include hyperlinkMain.asm
include hyperlinkUtils.asm
include pageMain.asm
