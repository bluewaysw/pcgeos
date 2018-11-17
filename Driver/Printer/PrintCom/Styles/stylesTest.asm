COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		stylesTest.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintTestStyles		Test legality of printer text style word

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial revision
	Dave	3/92		Moved in a bunch of common test routines
	Dave	5/92		Parsed from printcomText.asm
	Dave	7/92		changed to new 1 word style test mode.


DESCRIPTION:

	$Id: stylesTest.asm,v 1.1 97/04/18 11:51:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintTestStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Gets rid of illegal style combinations in the passed style word.

CALLED BY: 	GLOBAL

PASS:		bp	- Segment of PSTATE	
		dx	- style word to check for illegal combinations
	

RETURN:		bp	- Segment of PSTATE
		dx	- legalized style word

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:
		the passed style word is anded with the legal styles word,
		and ored to set any mandatory bits a font may need.
		NLQ is stuffed in before if the mode is hi text.

		CONDENSED compatability bit	b15	Highest Priority
		SUBSCRIPT compatability bit	b14		|
		SUPERSCRIPT compatability bit	b13		|
		NLQ compatability bit		b12		|
		BOLD compatability bit		b11		|
		ITALIC compatability bit	b10		|
		UNDERLINE compatability bit	b9		|
		STRIKE-THRU compatability bit	b8		|
		SHADOW compatability bit	b7		|
		OUTLINE compatability bit	b6		|
		REVERSED OUT compatability bit	b5		|
		DOUBLE WIDTH compatability bit	b4		|
		DOUBLE HEIGHT compatability bit	b3		|
		QUAD HEIGHT compatability bit	b2		|
		FUTURE USE compatability bit	b1	       \|/
		FUTURE USE compatability bit	b0	Lowest Priority

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	02/90		Initial version
		Dave	07/92		Initial 2.0 version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintTestStyles	proc	far
	uses	es
	.enter

		; make sure the NLQ bit is set if we need it.

	mov	es, bp
	cmp	es:[PS_mode], PM_TEXT_NLQ
	jne	testEm
	or	dx, mask PTS_NLQ

testEm:
		;get rid of illegal style bits
	and 	dx,es:[PS_curFont].[FE_styles]

		;add in any necessary style bits for this font.
	or	dx,es:[PS_curFont].[FE_stylesSet]
	
	.leave
	ret

PrintTestStyles	endp
