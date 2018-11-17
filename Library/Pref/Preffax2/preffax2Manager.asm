COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Fax Software (Tiramisu)
MODULE:		Preferences
FILE:		preffax2Manager.asm

AUTHOR:		Peter Trinh, Jan 16, 1995

ROUTINES:
	Name			Description
	----			-----------

PrefFaxGetPrefUITree	Get the root of the preference UI tree.
PrefFaxGetModuleInfo	Returns PrefModuleInfo to determine visib of module.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/16/95   	Initial revision


DESCRIPTION:
	Includes all necessary .def and .asm files to implement the
	Fax Preference module.

	$Id: preffax2Manager.asm,v 1.1 97/04/05 01:43:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include assert.def
include	library.def

include object.def
include	graphics.def
include gstring.def
include	win.def

include char.def
include initfile.def

include	vm.def
include	fax.def
include Internal/serialDr.def
include Internal/heapInt.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def
UseLib	Objects/vTextC.def
UseLib	faxfile.def


;-----------------------------------------------------------------------------
;	Drivers used		
;-----------------------------------------------------------------------------
include Internal/faxDriver.def
include Internal/faxInDr.def
include Internal/faxOutDr.def
include driver.def


;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include preffax2.def
include preffax2Global.def
include preffax2.rdef

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata	segment
	PrefFaxDialogClass
	PrefInteractionSpecialClass
	PrefItemGroupSpecialClass
	PrefDialingCodeListClass
idata	ends

;-----------------------------------------------------------------------------
;		other code
;-----------------------------------------------------------------------------

include	preffax2PrefFaxDialog.asm
include preffax2DialingCodeList.asm
include preffax2ItemGroupSpecial.asm

PrefFaxCode	segment	resource;

;-----------------------------------------------------------------------------
;	Utilities for PrefFaxDialogClass
;-----------------------------------------------------------------------------



;-----------------------------------------------------------------------------
;	Required exported routine for preference modules.
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the root of the preference UI tree

CALLED BY:	PrefMgr

PASS:		Nothing

RETURN:		dx:ax	= OD of root of tree
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFaxGetPrefUITree	proc	far

	mov	dx, handle PrefFaxRoot
	mov	ax, offset PrefFaxRoot

	ret
PrefFaxGetPrefUITree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFaxGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns PrefModuleInfo to determine visibility of module

CALLED BY:	PrefMgr

PASS:		ds:si	= PrefModuleInfo buffer

RETURN:		ds:si	= PrefModuleInfo filled

DESTROYED:	ax, bx
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	1/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefFaxGetModuleInfo	proc	far

	clr	ax
	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle PrefFaxMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset PrefFaxMonikerList
	mov	{word} ds:[si].PMI_monikerToken, 'P' or ('F' shl 8) 
	mov	{word} ds:[si].PMI_monikerToken+2, 'A' or ('X' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	ret
PrefFaxGetModuleInfo	endp

PrefFaxCode	ends



