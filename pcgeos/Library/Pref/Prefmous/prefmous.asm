COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefmous.asm

AUTHOR:		Gene Anderson, Aug 25, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/25/92		Initial revision


DESCRIPTION:
	Code for mouse module of Preferences

	$Id: prefmous.asm,v 1.1 97/04/05 01:37:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include stdapp.def
include	library.def
include Objects/inputC.def
include	Internal/im.def
include Internal/mouseDr.def
include Internal/geodeStr.def
include driver.def
include system.def
include initfile.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def
UseLib	Objects/vTextC.def
UseDriver Internal/serialDr.def
UseDriver Internal/videoDr.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include prefmous.def
include prefmousDialog.def
include prefmousDriverDialog.def
include prefmousList.def
include prefmousPortList.def
include prefmousTrigger.def

include prefmous.rdef

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PrefMousCode	segment resource

include prefmousDialog.asm
include prefmousDriverDialog.asm
include prefmousList.asm
include prefmousPortList.asm
include prefmousTrigger.asm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		none

RETURN:		dx:ax - OD of root of tree

DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMousGetPrefUITree	proc far
	mov	dx, handle PrefMousRoot
	mov	ax, offset PrefMousRoot
	ret
PrefMousGetPrefUITree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMousGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr

PASS:		ds:si - PrefModuleInfo structure to be filled in

RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECSnd/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMousGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, ax
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle  PrefMousMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset PrefMousMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'M' or ('O' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	.leave
	ret
PrefMousGetModuleInfo	endp


PrefMousCode	ends




