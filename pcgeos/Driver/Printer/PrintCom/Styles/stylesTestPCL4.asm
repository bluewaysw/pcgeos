
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		stylesTestPCL4.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/15/92		Initial revision from pcl4Text.asm


DESCRIPTION:

	$Id: stylesTestPCL4.asm,v 1.1 97/04/18 11:51:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintTestStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Gets rid of illegal style combinations in the passed style word.
		DOES NOTHING IN LASERJET DOWNLOAD DRIVER!

CALLED BY: 	GLOBAL

PASS:		bp	- Segment of PSTATE	
		dx	- style word to check for illegal combinations
	

RETURN:		bp	- Segment of PSTATE
		dx	- legalized style word

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:
		The style word passed is scanned for a set bit.  The 
		corresponding word is then anded with the mode word to get 
		rid of any incompatible features requested.  The first 
		bits read are the highest priority, and the last are the lowest.

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintTestStyles	proc	far

	clc
	ret

PrintTestStyles	endp
