COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		swarmpref.asm

AUTHOR:		Adam de Boor, Dec  3, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 3/92	Initial revision


DESCRIPTION:
	Saver-specific preferences for Swarm app
		

	$Id: swarmpref.asm,v 1.1 97/04/04 16:47:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; include the standard suspects
include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include library.def

include object.def
include graphics.def
include gstring.def

UseLib ui.def
UseLib config.def		; Most objects we use come from here
UseLib saver.def

;
; Include constants from the saver, for use in our objects.
;
include ../swarm.def

;
; Now the object tree.
; 
include	swarmpref.rdef

idata	segment

idata	ends

SwarmPrefCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwarmPrefGetPrefUITree
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
SwarmPrefGetPrefUITree	proc far
	mov	dx, handle RootObject
	mov	ax, offset RootObject
	ret
SwarmPrefGetPrefUITree	endp

global SwarmPrefGetPrefUITree:far


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwarmPrefGetModuleInfo
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
SwarmPrefGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	movdw	ds:[si].PMI_monikerList, axax
	mov	{word} ds:[si].PMI_monikerToken,  ax
	mov	{word} ds:[si].PMI_monikerToken+2, ax
	mov	{word} ds:[si].PMI_monikerToken+4, ax

	.leave
	ret
SwarmPrefGetModuleInfo	endp

global SwarmPrefGetModuleInfo:far


SwarmPrefCode	ends
