COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) MyTurn.com 2001.  All rights reserved.
	MYTURN.COM CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		User level pref module
FILE:		preflvl.asm

AUTHOR:		David Hunter, Jan 08, 2001

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 1/08/01   	Initial revision


DESCRIPTION:
		
	Code for user level module of Preferences

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

PreflvlDialogClass	class	PrefDialogClass

PreflvlDialogClass	endc

;-----------------------------------------------------------------------------
;	DEFINITIONS	
;-----------------------------------------------------------------------------

include preflvl.rdef

global	PreflvlGetPrefUITree:far
global	PreflvlGetModuleInfo:far

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------
 
idata	segment
	PreflvlDialogClass
idata	ends

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PreflvlCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreflvlGetPrefUITree
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
	dhunter 1/08/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreflvlGetPrefUITree	proc	far
	mov	dx, handle PreflvlRoot
	mov	ax, offset PreflvlRoot
	ret
PreflvlGetPrefUITree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreflvlGetModuleInfo
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
	dhunter 1/08/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreflvlGetModuleInfo	proc	far
	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, UIIL_BEGINNING
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle PreflvlMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset PreflvlMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'L' or ('v' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	ret
PreflvlGetModuleInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreflvlDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has chosen a new default launch level.  Have the
		level UI save that to INI, send MSG_META_LOAD_OPTIONS
		to the parent field to force the UI library to load the
		new level, and reset application features in INI if the
		user so indicated.

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
		Callsuper to send MSG_META_SAVE_OPTIONS
		send GUP GenFieldClass::MSG_META_LOAD_OPTIONS
		If ChangeUILevelReplaceGroup != 0,
			Reset app features

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 1/08/01   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreflvlDialogApply	method dynamic PreflvlDialogClass, 
					MSG_GEN_APPLY
	;
	; Save the new default launch level.
	;
		mov	di, offset PreflvlDialogClass
		call	ObjCallSuperNoLock
	;
	; Tell GenField to load the new default launch level.
	;
		push	si
		mov	bx, segment GenFieldClass
		mov	si, offset GenFieldClass
		mov	ax, MSG_META_LOAD_OPTIONS
		mov	di, mask MF_RECORD
		call	ObjMessage			; di = event handle
		mov	cx, di				; cx = event handle
		mov	ax, MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS
		clr	di
		mov	bx, ds:[LMBH_handle]
		pop	si				; bx:si = self
		call	ObjMessage
	;
	; Reset app features if ChangeUILevelReplaceItem is set.
	;
		mov	si, offset ChangeUILevelReplaceGroup
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjCallInstanceNoLock		; ax non-zero if set
		tst	ax
		jz	done				; branch if not set
		call	PreflvlResetAppFeatures
done:
		ret
PreflvlDialogApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreflvlResetAppFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There are a number of applications that have multiple skill
		levels, and we would like the recently set launch level to
		override whatever custom level may or may not be set in those
		applications.  We have an INI key containing a list of the
		INI categories for these applications, whose "features" key
		will be deleted by this procedure.

CALLED BY:	PreflvlDialogApply
PASS:		none
RETURN:		none
DESTROYED:	possibly everything
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		ax = 0
		Call InitFileReadStringSection
		While no carry, delete [category]/features, inc ax, call again

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 1/08/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreflvlCategory	TCHAR	"preflvl", 0
PreflvlKey	TCHAR	"resetAppCategories", 0
FeaturesKey	TCHAR	"features", 0

PreflvlResetAppFeatures	proc	near
	;
	; Make room on stack for INI category.
	;
		mov	bp, MAX_INITFILE_CATEGORY_LENGTH ; size of category
		sub	sp, bp
		mov	di, sp				; ss:di = stack cat
	;
	; Start out with ax = 0 and pointers to our category/key.
	;
		segmov	ds, cs, cx
		mov	si, offset PreflvlCategory	; ds:si = category
		mov	dx, offset PreflvlKey		; cx:dx = key
		segmov	es, ss, ax			; es:di = stack cat
		clr	ax				; ax = 0
	;
	; Get the next app category or set carry.
	;
next:
		call	InitFileReadStringSection	; cx = category size
		mov	cx, cs
		jc	done				; branch if done
	;
	; Delete the "features" key for the read category.
	;
		push	ds, si, dx
		segmov	ds, es
		mov	si, di				; ds:si = stack cat
		mov	dx, offset FeaturesKey		; cx:dx = key
		call	InitFileDeleteEntry
		pop	ds, si, dx
		inc	ax				; next string, please
		jmp	next
done:
		add	sp, bp				; restore stack
		ret
PreflvlResetAppFeatures	endp

PreflvlCode	ends
