COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		cNDDesktopPrimaryClass.asm

AUTHOR:		Joon Song, May 19, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/19/93   	Initial revision


DESCRIPTION:
	This file contains code for NDDesktopPrimaryClass

	$Id: cNDDesktopPrimaryClass.asm,v 1.3 98/06/03 13:06:52 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDPrimaryCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopPrimaryVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save Desktop window optr.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= NDDesktopPrimaryClass object
		ds:di	= NDDesktopPrimaryClass instance data
		ds:bx	= NDDesktopPrimaryClass object (same as *ds:si)
		es 	= segment of NDDesktopPrimaryClass
		ax	= message #
		bp	= 0 if top window, else window for object to open on
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	6/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopPrimaryVisOpen	method dynamic NDDesktopPrimaryClass, 
					MSG_VIS_OPEN
	push	es
	mov	bx, segment dgroup
	mov	es, bx
	mov	bx, ds:[LMBH_handle]
	movdw	es:[desktopFolderWindow], bxsi
	pop	es

	mov	di, offset NDDesktopPrimaryClass
	GOTO	ObjCallSuperNoLock

NDDesktopPrimaryVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopPrimaryKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept Shift-ESC.  (Ignore)

CALLED BY:	MSG_META_KBD_CHAR
		MSG_META_FUP_KBD_CHAR
PASS:		*ds:si	= NDDesktopPrimaryClass object
		ds:di	= NDDesktopPrimaryClass instance data
		ds:bx	= NDDesktopPrimaryClass object (same as *ds:si)
		es 	= segment of NDDesktopPrimaryClass
		ax	= message #
		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code
RETURN:		carry set if character was handled by someone (and should
		not be used elsewhere).
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopPrimaryKbdChar method dynamic NDDesktopPrimaryClass, 
				MSG_META_KBD_CHAR, MSG_META_FUP_KBD_CHAR
if DBCS_PCGEOS
	cmp	cx, C_SYS_ESCAPE
else
	cmp	cx, (VC_ISCTRL shl 8) or VC_ESCAPE
endif
	jne	callSuper

	test	dh, mask SS_LSHIFT or mask SS_RSHIFT
	jz	callSuper

	test	dh, not (mask SS_LSHIFT or mask SS_RSHIFT)
	jnz	callSuper

	stc	; <== IGNORE KEY
	ret

callSuper:
	mov	di, offset NDDesktopPrimaryClass
	GOTO	ObjCallSuperNoLock

NDDesktopPrimaryKbdChar endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopPrimaryClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore MSG_GEN_DISPLAY_CLOSE

CALLED BY:	MSG_GEN_DISPLAY_CLOSE
PASS:		*ds:si	= NDDesktopPrimaryClass object
		ds:di	= NDDesktopPrimaryClass instance data
		ds:bx	= NDDesktopPrimaryClass object (same as *ds:si)
		es 	= segment of NDDesktopPrimaryClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	6/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopPrimaryClose	method dynamic NDDesktopPrimaryClass, 
					MSG_GEN_DISPLAY_CLOSE
	ret
NDDesktopPrimaryClose	endm

NDPrimaryCode	ends
