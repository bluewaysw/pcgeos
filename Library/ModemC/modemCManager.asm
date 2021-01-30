COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		modemCManager.asm

AUTHOR:		Chris Thomas, Sep 23, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/23/96   	Initial revision


DESCRIPTION:
	
		

	$Id: modemCManager.asm,v 1.1 97/04/05 01:23:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%
;%%	Include files
;%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include geos.def
include ec.def
include	driver.def
include geode.def
include heap.def
include library.def
include resource.def
include object.def
include system.def
include	assert.def

include modemCConstant.def


UseDriver	Internal/streamDr.def
UseDriver	Internal/modemDr.def

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%
;%%	Global vars
;%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idata	segment

if _SUPPORTS_END_CALL_NOTIFICATION

	endCallDest	optr	0
	endCallMsg	word	0

endif ; _SUPPORTS_END_CALL_NOTIFICATION

idata	ends

udata	segment

	modemHandle	hptr			; handle of modem driver

	modemStrategy	fptr.far		; strategy routine of driver

  CCallbackInfo	struct
	CCI_callback	vfptr.far		; C routine for data
						;  notifications
	CCI_geode	hptr			; GeodeHandle of routine
						;  (for loading its dgroup)
  CCallbackInfo	ends

	dataCallback	CCallbackInfo

	respCallback	CCallbackInfo


udata	ends

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%
;%%	Code
;%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CommonCode	segment	resource

include modemC.asm
include modemCEci.asm

CommonCode	ends
