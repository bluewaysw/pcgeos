COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefintl.asm

AUTHOR:		Gene Anderson, Aug 25, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/25/92		Initial revision


DESCRIPTION:
	Code for keyboard module of Preferences

	$Id: prefintl.asm,v 1.1 97/04/05 01:39:07 newdeal Exp $

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
include initfile.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def
UseLib	Objects/vTextC.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include prefintl.def
include prefintlDialog.def
include prefintlCustomSpin.def
if PZ_PCGEOS	; Gengo defines
include prefintlGengo.def
endif
include prefintl.rdef

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata segment

idata ends


ForceRef	secondToken
ForceRef	secondTokenPrefix
ForceRef	thirdToken
ForceRef	thirdTokenPrefix
ForceRef	fourthToken
ForceRef	fourthTokenPrefix

ForceRef	SpaceMoniker
ForceRef	CurrFormat1
ForceRef	CurrFormat2
ForceRef	CurrFormat3
ForceRef	CurrFormat4
ForceRef	CurrFormat5
ForceRef	CurrFormat6
ForceRef	CurrFormat7
ForceRef	LeadingZeroOn

if PZ_PCGEOS	;Koji
ForceRef	LBMoniker
ForceRef	SBMoniker
ForceRef	LGMoniker
ForceRef	SGMoniker
endif

ForceRef	LWMoniker
ForceRef	SWMoniker
ForceRef	LDMoniker
ForceRef	SDMoniker
ForceRef	ZDMoniker
ForceRef	PDMoniker
ForceRef	LMMoniker
ForceRef	SMMoniker
ForceRef	NMMoniker
ForceRef	ZMMoniker
ForceRef	PMMoniker
ForceRef	LYMoniker
ForceRef	SYMoniker
ForceRef	NoneMoniker2
ForceRef	APMoniker
ForceRef	APMoniker3
ForceRef	HHMoniker
ForceRef	ZHMoniker
ForceRef	SHMoniker
ForceRef	HHMoniker24
ForceRef	ZHMoniker24
ForceRef	SHMoniker24
ForceRef	MMMoniker2
ForceRef	ZMMoniker2
ForceRef	SMMoniker2
ForceRef	SSMoniker
ForceRef	ZSMoniker
ForceRef	PSMoniker

ForceRef	MetricSystem

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PrefIntlCode	segment resource

include prefintlDialog.asm
include prefintlCustomSpin.asm

if PZ_PCGEOS	; Gengo modules
include prefintlGengo.asm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefIntlGetPrefUITree
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
PrefIntlGetPrefUITree	proc far
	mov	dx, handle PrefIntlRoot
	mov	ax, offset PrefIntlRoot
	ret
PrefIntlGetPrefUITree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefIntlGetModuleInfo
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
PrefIntlGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle  PrefIntlMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset PrefIntlMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'I' or ('N' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	.leave
	ret
PrefIntlGetModuleInfo	endp

PrefIntlCode	ends
