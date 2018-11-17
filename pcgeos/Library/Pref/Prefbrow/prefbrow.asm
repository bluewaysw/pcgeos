COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) MyTurn.com 2001.  All rights reserved.
	MYTURN.COM CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Browser pref module
FILE:		prefbrow.asm

AUTHOR:		Brian Chin, Mar 30, 2001

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc  3/30/01   	Initial revision


DESCRIPTION:
		
	Code for browser module of Preferences

	$Id$

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
include initfile.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------

UseLib	ui.def
UseLib	config.def

;-----------------------------------------------------------------------------
;	CLASSES		
;-----------------------------------------------------------------------------

PrefbrowDialogClass	class	PrefDialogClass

PrefbrowDialogClass	endc

;-----------------------------------------------------------------------------
;	DEFINITIONS	
;-----------------------------------------------------------------------------

include prefbrow.rdef

global	PrefbrowGetPrefUITree:far
global	PrefbrowGetModuleInfo:far

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------
 
idata	segment
	PrefbrowDialogClass
idata	ends

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PrefbrowCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefbrowGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr
PASS:		none
RETURN:		dx:ax - OD of root of tree
DESTROYED:	none
SIDE EFFECTS:	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc  3/30/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefbrowGetPrefUITree	proc	far
	mov	dx, handle PrefbrowRoot
	mov	ax, offset PrefbrowRoot
	ret
PrefbrowGetPrefUITree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefbrowGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr
PASS:		ds:si - PrefModuleInfo structure to be filled in
RETURN:		ds:si - buffer filled in
DESTROYED:	ax,bx 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc  3/30/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefbrowGetModuleInfo	proc	far
	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle PrefbrowMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset PrefbrowMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'B' or ('r' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	ret
PrefbrowGetModuleInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefbrowDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has entered a new home page.  Make sure
		home page setting will take effect in browser.

CALLED BY:	MSG_GEN_APPLY

PASS:		*ds:si	= PreflvlDialogClass object
		ds:di	= PreflvlDialogClass instance data
		ds:bx	= PreflvlDialogClass object (same as *ds:si)
		es 	= segment of PreflvlDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything allowed
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc  3/30/01   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

browserCat	char "htmlview",0
homeKey		char "url",0

PrefbrowDialogApply	method dynamic PrefbrowDialogClass, 
					MSG_GEN_APPLY
	;
	; Save the new home page.
	;
		mov	di, offset PrefbrowDialogClass
		call	ObjCallSuperNoLock
	;
	; Write home page activation settings.
	;
		segmov	ds, cs, cx
		mov	si, offset browserCat
		mov	dx, offset homeKey
		mov	bp, 0x629e
		call	InitFileWriteInteger
		ret
PrefbrowDialogApply	endm

PrefbrowCode	ends
