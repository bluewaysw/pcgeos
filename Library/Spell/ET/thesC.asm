COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spell Library
FILE:		thesC.asm

AUTHOR:		Joon Song, Sep 23, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/23/94   	Initial revision


DESCRIPTION:
	This file contains C interface routines for the geode routines
		

	$Id: thesC.asm,v 1.1 97/04/07 11:08:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_ThesaurusCode segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThesaurusGetMeanings

C DECLARATION:	extern word
			_far _pascal ThesaurusGetMeanings(
					const char _far *name,
					MeaningsRetParams *params);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
THESAURUSGETMEANINGS	proc	far	lookupWord:fptr, meaningsRetParams:fptr
	uses	es, si, di
	.enter

	movdw	cxdx, lookupWord
	call	ThesaurusGetMeanings
	les	di, meaningsRetParams
	xchg	ax, bx
	stosw
	mov_tr	ax, si
	stosw
	mov_tr	ax, dx
	stosw
	xchg	ax, bx	

	.leave
	ret
THESAURUSGETMEANINGS	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ThesaurusGetSynonyms

C DECLARATION:	extern word
			_far _pascal ThesaurusGetSynonyms(
					const char _far *name,
					word senseNumber,
					optr *synonyms);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
THESAURUSGETSYNONYMS	proc	far	lookupWord:fptr,
					senseNumber:word,
					synonyms:fptr
	uses	ds, si
	.enter

	movdw	dssi, lookupWord
	mov	cx, senseNumber
	call	ThesaurusGetSynonyms
	mov	cx, si
	lds	si, synonyms
	movdw	ds:[si], dxcx

	.leave
	ret
THESAURUSGETSYNONYMS	endp

C_ThesaurusCode ends

	SetDefaultConvention
