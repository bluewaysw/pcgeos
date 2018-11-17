COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Iclas -- IconList	
FILE:		iconDisplayMain.asm

AUTHOR:		Martin Turon, Oct 20, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/20/92	Initial version


DESCRIPTION:
	
		

RCS STAMP:
	$Id: icondisplayMain.asm,v 1.1 97/04/07 10:45:24 newdeal Exp $


=============================================================================@



COMMENT @-------------------------------------------------------------------
		IconDisplayGetCurrentIcon
----------------------------------------------------------------------------

DESCRIPTION:	

CALLED BY:	GLOBAL

PASS:		*ds:si	= IconDisplayClass object
		ds:di	= IconDisplayClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/20/92   	Initial version

----------------------------------------------------------------------------@
IconDisplayGetCurrentIcon	method dynamic IconDisplayClass, 
					MSG_ICON_DISPLAY_GET_CURRENT_ICON

		push	si
		movdw	bxsi, ds:[di].IDI_iconList
		mov	ax, MSG_ICON_LIST_GET_SELECTED
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		pop	si
		mov	bp, ax
		FALL_THRU	IconDisplaySetIcon

IconDisplayGetCurrentIcon	endm




COMMENT @-------------------------------------------------------------------
		IconDisplaySetIcon
----------------------------------------------------------------------------

DESCRIPTION:	

CALLED BY:	GLOBAL

PASS:		*ds:si	 = IconDisplayClass object
		bp:cx:dx = GeodeToken

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Two exit points... Watch it!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/28/92   	Initial version

----------------------------------------------------------------------------@
IconDisplaySetIcon	method	IconDisplayClass, 
					MSG_ICON_DISPLAY_SET_ICON

		mov	ax, bp
		call	ShellLoadMoniker
		jc	error

		push	cx

		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		mov	bp, VUM_NOW
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_MAKE_APPLYABLE
		call	ObjCallInstanceNoLock

		pop	bx
		GOTO	MemFree				; <--- EXIT!
error:
		ret					; <--- EXIT!

IconDisplaySetIcon	endm


