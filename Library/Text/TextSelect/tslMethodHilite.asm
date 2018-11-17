COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tslMethodHilite.asm

AUTHOR:		John Wedgwood, Apr 20, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 4/20/92	Initial revision

DESCRIPTION:
	Methods related to hiliting.

	$Id: tslMethodHilite.asm,v 1.1 97/04/07 11:20:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSelect	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextHilite --
		MSG_VIS_TEXT_HILITE for VisTextClass

DESCRIPTION:	Highlights the cursor.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_TEXT_HILITE

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 8/90		Initial version

------------------------------------------------------------------------------@

VisTextHilite	proc	far	; MSG_VIS_TEXT_HILITE
	call	TextGStateCreate
	call	EditHilite
	jmp	DestroyGState
VisTextHilite	endp


COMMENT @----------------------------------------------------------------------

METHOD:		VisTextUnHilite --
		MSG_VIS_TEXT_UNHILITE for VisTextClass

DESCRIPTION:	Turns off the cursor.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_TEXT_UNHILITE

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 8/90		Initial version

------------------------------------------------------------------------------@

VisTextUnHilite	proc	far	; MSG_VIS_TEXT_UNHILITE
	call	TextGStateCreate
	call	EditUnHilite

DestroyGState_RestoreOverride	label	near
	call	TextGStateDestroy
	ret
VisTextUnHilite	endp


TextSelect	ends
