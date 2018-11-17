COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Prefpag
FILE:		prefpagManager.asm

AUTHOR:		Jennifer Wu, Apr  1, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	4/ 1/93		Initial revision

DESCRIPTION:
	

	$Id: prefpagManager.asm,v 1.1 97/04/05 01:29:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def

include object.def
include	graphics.def
include gstring.def
include	win.def

include char.def
include Objects/inputC.def
include initfile.def
include fileEnum.def
include driver.def


;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def
UseLib	Objects/vTextC.def
UseLib	emailtmp.def			; for iacp stuff

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------

include pagerwatcher.def		; for communicating with pager watcher
 
include prefpag.def
include prefpag.rdef


idata	segment
	PrefPagDialogClass
	PrefPagDynamicListClass
idata	ends
 

;-------------------------------------------------------------------------
;	RESOURCES
;-------------------------------------------------------------------------
include	prefpag.asm

