COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	Preferences
MODULE:		Link
FILE:		prefLink.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/8/92		Initial Version  	

DESCRIPTION:
		
	$Id: prefui.asm,v 1.1 97/04/05 01:42:43 newdeal Exp $

-----------------------------------------------------------------------------@



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

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include prefui.def
include prefui.rdef

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata segment

	PrefUIDialogClass

idata ends

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PrefUICode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUIGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		nothing 

RETURN:		dx:ax - OD of root of tree

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefUIGetPrefUITree	proc far
	mov	dx, handle PrefUIRoot
	mov	ax, offset PrefUIRoot
	ret
PrefUIGetPrefUITree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUIGetMonikerList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		^ldx:ax - server moniker list

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefUIGetMonikerList	proc far
	mov	dx, handle PrefUIMonikerList
	mov	ax, offset PrefUIMonikerList
	ret
PrefUIGetMonikerList	endp

;-------------------------------------------------------------

COMMENT @----------------------------------------------------------------------

MESSAGE:	PrefUIDialogApply -- MSG_GEN_APPLY
						for PrefUIDialogClass

DESCRIPTION:	Add functionality on APPLY

PASS:
	*ds:si - instance data
	es - segment of PrefUIDialogClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/16/92		Initial version

------------------------------------------------------------------------------@
PrefUIDialogApply	method dynamic	PrefUIDialogClass, MSG_GEN_APPLY

	mov	di, offset PrefUIDialogClass
	call	ObjCallSuperNoLock

	; delete the "ui options" category

	segmov	ds, cs
	mov	si, offset uiFeaturesCategory
	call	InitFileDeleteCategory

	ret

PrefUIDialogApply	endm

uiFeaturesCategory	char	"uiFeatures", 0


PrefUICode	ends
