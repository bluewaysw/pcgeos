COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		textMethodManip.asm

AUTHOR:		John Wedgwood, Oct 25, 1989

METHODS:
	Name			Description
	----			-----------
	MSG_VIS_TEXT_GET_ALL
	MSG_VIS_TEXT_GET_SELECTION
	MSG_VIS_TEXT_SELECT_RANGE
	MSG_VIS_TEXT_SELECT_NONE
	MSG_VIS_TEXT_ENTER_OVERSTRIKE_MODE
	MSG_VIS_TEXT_ENTER_INSERT_MODE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/25/89	Initial revision

DESCRIPTION:
	Methods for manipulating the actual text.

	$Id: textMethodManip.asm,v 1.1 97/04/07 11:17:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextInstance segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextEnterOverstrikeMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter overstrike mode, leave insert mode.

CALLED BY:	via MSG_VIS_TEXT_ENTER_OVERSTRIKE_MODE
PASS:		ds:*si	= instance ptr.
		es	= class segment.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextEnterOverstrikeMode	method dynamic	VisTextClass,
				MSG_VIS_TEXT_ENTER_OVERSTRIKE_MODE

	test	ds:[di].VTI_state, mask VTS_OVERSTRIKE_MODE
	jnz	done
	call	TSL_SelectIsCursor		; Check for is a cursor
	jnc	done				; done if we have a range.
	call	EditUnHilite			; Unhilite in insert mode.
	ornf	ds:[di].VTI_state, mask VTS_OVERSTRIKE_MODE
	call	EditHilite			; Rehilite in replace mode.
done:
	ornf	ds:[di].VTI_state, mask VTS_OVERSTRIKE_MODE
	ret
VisTextEnterOverstrikeMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextEnterInsertMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter insert mode, leave overstrike mode.

CALLED BY:	via MSG_VIS_TEXT_ENTER_INSERT_MODE
PASS:		ds:*si	= instance ptr.
		es	= class segment.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextEnterInsertMode	method dynamic	VisTextClass, MSG_VIS_TEXT_ENTER_INSERT_MODE

	test	ds:[di].VTI_state, mask VTS_OVERSTRIKE_MODE
	jz	done

	call	TSL_SelectIsCursor		; Check for is cursor
	jnc	done				; Quit if selection is range.
	call	EditUnHilite			; Unhilite in replace mode.
	and	ds:[di].VTI_state, not mask VTS_OVERSTRIKE_MODE
	call	EditHilite			; Rehilite in insert mode.
done:
	and	ds:[di].VTI_state, not mask VTS_OVERSTRIKE_MODE
	ret
VisTextEnterInsertMode	endm

TextInstance	ends
