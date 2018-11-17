COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Config
MODULE:		
FILE:		uiNoGraphicsText.asm

AUTHOR:		Andrew Wilson, Dec 14, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/14/92		Initial revision

DESCRIPTION:
	Text object that allows no graphics to be inserted.

	$Id: uiNoGraphicsText.asm,v 1.1 97/04/07 11:16:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextClassStructures	segment	resource
	NoGraphicsTextClass
TextClassStructures	ends

if not NO_CONTROLLERS

TextSRControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoGraphicsTextFilterViaCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Filters out graphics.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NoGraphicsTextFilterViaCharacter	method	NoGraphicsTextClass,
					MSG_VIS_TEXT_FILTER_VIA_CHARACTER
	.enter
	cmp	cx, C_GRAPHIC
	jnz	exit
	clr	cx
exit:
	.leave
	ret
NoGraphicsTextFilterViaCharacter	endp

TextSRControlCode ends

endif		; not NO_CONTROLLERS
