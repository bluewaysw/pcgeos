COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		fontcomEscape.asm
FILE:		fontcomEscape.asm

AUTHOR:		Gene Anderson, Jan 21, 1992

ROUTINES:
	Name			Description
	----			-----------
	FontQueryEscape		Query for escape support
	Font

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/21/92		Initial revision

DESCRIPTION:
	Common code for supporting escape functions

	$Id: fontcomEscape.asm,v 1.1 97/04/18 11:45:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontQueryEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query for escape support for this driver
CALLED BY:	FontCallEscape

PASS:		di - escape code to test for
RETURN:		carry clear if supported
			di - offset of escape code in table
		carry set if not supported
			di - destroyed
			ax = 0 (why?)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The following must be defined:
		cs:escCodes - DefEscapeTable + DefEscape entries
		NUM_ESC_ENTRIES - # of entries in table
	These are correctly defined by using the DefEscapeTable and DefEscape
	macros defined in driver.def
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontQueryEscape	proc	near
	uses	ax, cx, es
	.enter

	segmov	es, cs, ax			;es <- driver segment
	mov	ax, di				;ax <- escape function
	mov	di, offset escCodes		;es:di <- ptr to esc code tab
	mov	cx, NUM_ESC_ENTRIES		;cx <- # of escapes
	repne	scasw				;scan me jesus
	jne	notFound
	;
	; function is supported, return carry clear
	;
	clc
done:
	.leave
	ret

	;
	; function not supported, return carry set and ax=0
	;
notFound:
	mov	ax, 0				;why?
	stc
	jmp	done
FontQueryEscape	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontCallEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute some escape function
CALLED BY:	GLOBAL

PASS:		di - escape code
RETURN:		di - unchanged if handled
		   - set to 0 if escape not supported
DESTROYED:	see functions

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The following must be defined:
		cs:escCodes - DefEscapeTable + DefEscape entries
		NUM_ESC_ENTRIES - # of entries in table
	These are correctly defined by using the DefEscapeTable and DefEscape
	macros defined in driver.def
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontCallEscape	proc	near
	.enter

	push	di
	call	FontQueryEscape			;supported function?
	jc	notFound			;branch if not supported

	;
	; function is supported, call through vector
	;
	call	cs:[di][((offset escRoutines)-(offset escCodes)-2)]
	pop	di
done:
	.leave
	ret

	;
	; function not supported, return di==0
	;
notFound:
	pop	di
	clr	di				;di <- function not handled
	jmp	done
FontCallEscape	endp
