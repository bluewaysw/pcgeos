COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spell Library
FILE:		spellC.asm

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
		

	$Id: spellC.asm,v 1.1 97/04/07 11:05:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_SpellCode segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICCheckWord

C DECLARATION:	extern SpellResult
			_far _pascal ICCheckWord(MemHandle icBuff,
						 char *lookupWord);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICCHECKWORD	proc	far		icBuff:hptr, lookupWord:fptr
	uses	ds,si
	.enter

	mov	cx, icBuff
	lds	si, lookupWord
	call	ICCheckWord

	.leave
	ret
ICCHECKWORD	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICGetTextOffsets

C DECLARATION:	extern void
			_far _pascal ICGetTextOffsets(MemHandle icBuff,
						      word *firstOffset,
						      word *lastOffset);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICGETTEXTOFFSETS	proc	far	icBuff:hptr,
					firstOffset:fptr, lastOffset:fptr
	uses	es,di
	.enter

	mov	cx, icBuff
	call	ICGetTextOffsets
	les	di, firstOffset
	stosw
	les	di, lastOffset
	mov_tr	ax, cx
	stosw

	.leave
	ret
ICGETTEXTOFFSETS	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICGetErrorFlags

C DECLARATION:	extern void
			_far _pascal ICGetErrorFlags(MemHandle icBuff,
					SpellErrorFlags *errorFlags,
					SpellErrorFlagsHigh *errorFlagsHigh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICGETERRORFLAGS	proc	far		icBuff:hptr,
					errorFlags:fptr, errorFlagsHigh:fptr
	uses	es,di
	.enter

	mov	cx, icBuff
	call	ICGetErrorFlags
	les	di, errorFlags
	stosw
	les	di, errorFlagsHigh
	mov_tr	ax, cx
	stosw

	.leave
	ret
ICGETERRORFLAGS	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICResetSpellCheck

C DECLARATION:	extern void
			_far _pascal ICResetSpellCheck(MemHandle icBuff);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICRESETSPELLCHECK	proc	far		icBuff:hptr
	.enter

	mov	cx, icBuff
	call	ICResetSpellCheck

	.leave
	ret
ICRESETSPELLCHECK	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICCheckForEmbeddedPunctuation

C DECLARATION:	extern Boolean
			_far _pascal ICCheckForEmbeddedPunctuation(
							MemHandle icBuff);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICCHECKFOREMBEDDEDPUNCTUATION	proc	far	icBuff:hptr
	.enter

	mov	bx, icBuff
	call	ICCheckForEmbeddedPunctuation

	.leave
	ret
ICCHECKFOREMBEDDEDPUNCTUATION	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICGetLanguage

C DECLARATION:	extern StandardLanguage
			_far _pascal ICGetLanguage(MemHandle icBuff);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICGETLANGUAGE	proc	far		icBuff:hptr
	.enter

	mov	bx, icBuff
	call	ICGetLanguage

	.leave
	ret
ICGETLANGUAGE	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICInit

C DECLARATION:	extern SpellResult
			_far _pascal ICInit(MemHandle *icBuff);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICINIT	proc	far			icBuffPtr:fptr
	uses	ds, si
	.enter

	call	ICInit
	lds	si, icBuffPtr
	mov	ds:[si], bx

	.leave
	ret
ICINIT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICExit

C DECLARATION:	extern SpellErrors
			_far _pascal ICExit(MemHandle icBuff);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICEXIT	proc	far	icBuff:hptr
	.enter

	mov	bx, icBuff
	call	ICExit

	.leave
	ret
ICEXIT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICStopCheck

C DECLARATION:	extern void
			_far _pascal ICStopCheck(MemHandle icBuff);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICSTOPCHECK	proc	far		icBuff:hptr
	.enter

	mov	bx, icBuff
	call	ICStopCheck

	.leave
	ret
ICSTOPCHECK	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICSpl

C DECLARATION:	extern word
			_far _pascal ICSpl(MemHandle icBuff,
					   char *string);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICSPL	proc	far			icBuff:hptr, string:fptr
	uses	ds,si
	.enter

	mov	bx, icBuff
	lds	si, string
	call	ICSpl

	.leave
	ret
ICSPL	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICGetNumAlts

C DECLARATION:	extern word
			_far _pascal ICGetNumAlts(MemHandle icBuff);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICGETNUMALTS	proc	far		icBuff:hptr
	.enter

	mov	bx, icBuff
	call	ICGetNumAlts

	.leave
	ret
ICGETNUMALTS	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICGetAlternate

C DECLARATION:	extern void
			_far _pascal ICGetAlternate(MemHandle icBuff,
						    word index,
						    char *original,
						    char *alternate);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICGETALTERNATE	proc	far		icBuff:hptr, index:word,
					original:fptr, alternate:fptr
	uses	ds,si,es,di
	.enter

	mov	ax, index
	mov	bx, icBuff
	lds	si, original
	les	di, alternate
	call	ICGetAlternate

	.leave
	ret
ICGETALTERNATE	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICIgnore

C DECLARATION:	extern void
			_far _pascal ICIgnore(MemHandle icBuff,
					      char *ignoreWord);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICIGNORE	proc	far		icBuff:hptr, ignoreWord:fptr
	uses	ds,si
	.enter

	mov	bx, icBuff
	lds	si, ignoreWord
	call	ICIgnore

	.leave
	ret
ICIGNORE	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICAddUser

C DECLARATION:	extern void
			_far _pascal ICAddUser(MemHandle icBuff,
					       char *addWord,
					       SpellResult *spellResult,
					       UserResult *userResult);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICADDUSER	proc	far		icBuff:hptr, addWord:fptr,
					spellResult:fptr, userResult:fptr
	uses	ds,si
	.enter

	mov	bx, icBuff
	lds	si, addWord
	call	ICAddUser
	lds	si, spellResult
	mov	ds:[si], ax
	lds	si, userResult
	mov	ds:[si], dx

	.leave
	ret
ICADDUSER	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICDeleteUser

C DECLARATION:	extern void
			_far _pascal ICDeleteUser(MemHandle icBuff,
						  char *deleteWord,
						  SpellResult *spellResult,
						  UserResult *userResult);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICDELETEUSER	proc	far		icBuff:hptr, deleteWord:fptr,
					spellResult:fptr, userResult:fptr
	uses	ds,si
	.enter

	mov	bx, icBuff
	lds	si, deleteWord
	call	ICDeleteUser
	lds	si, spellResult
	mov	ds:[si], ax
	lds	si, userResult
	mov	ds:[si], dx

	.leave
	ret
ICDELETEUSER	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICBuildUserList

C DECLARATION:	extern MemHandle
			_far _pascal ICBuildUserList(MemHandle icBuff);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICBUILDUSERLIST	proc	far		icBuff:hptr
	.enter

	mov	bx, icBuff
	call	ICBuildUserList
	mov_tr	ax, bx

	.leave
	ret
ICBUILDUSERLIST	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICResetIgnore

C DECLARATION:	extern void
			_far _pascal ICGetAlternate(MemHandle icBuff);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICRESETIGNORE	proc	far		icBuff:hptr
	.enter

	mov	bx, icBuff
	call	ICResetIgnore

	.leave
	ret
ICRESETIGNORE	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICUpdateUser

C DECLARATION:	extern void
			_far _pascal ICUpdateUser(MemHandle icBuff);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICUPDATEUSER	proc	far		icBuff:hptr
	.enter

	mov	bx, icBuff
	call	ICUpdateUser

	.leave
	ret
ICUPDATEUSER	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICSetTask

C DECLARATION:	extern void
			_far _pascal ICSetTask(MemHandle icBuff,
					       SpellTask spellTask);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/94		Initial version

------------------------------------------------------------------------------@
ICSETTASK	proc	far		icBuff:hptr, spellTask:word
	.enter

	mov	bx, icBuff
	mov	ax, spellTask
	call	ICSetTask

	.leave
	ret
ICSETTASK	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICGetAnagrams

C DECLARATION:	extern SpellResult
			_far _pascal ICGetAnagrams(MemHandle icBuff,
						   char *lookupWord,
					       	   word minLength);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/94		Initial version

------------------------------------------------------------------------------@
ICGETANAGRAMS	proc	far		icBuff:hptr,
					lookupWord:fptr,
					minLength:word
	uses	ds,si
	.enter

if NO_ANAGRAM_WILDCARD_IN_SPELL_LIBRARY
EC <	ERROR	ANAGRAMS_AND_WILDCARDS_NOT_SUPPORTED			>
else
	mov	bx, icBuff
	mov	cx, minLength
	lds	si, lookupWord
	call	ICGetAnagrams
endif

	.leave
	ret
ICGETANAGRAMS	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	ICGetWildcards

C DECLARATION:	extern SpellResult
			_far _pascal ICGetWildcards(MemHandle icBuff,
						    char *lookupWord);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/94		Initial version

------------------------------------------------------------------------------@
ICGETWILDCARDS	proc	far		icBuff:hptr,
					lookupWord:fptr
	uses	ds,si
	.enter

if NO_ANAGRAM_WILDCARD_IN_SPELL_LIBRARY
EC <	ERROR	ANAGRAMS_AND_WILDCARDS_NOT_SUPPORTED			>
else
	mov	bx, icBuff
	lds	si, lookupWord
	call	ICGetWildcards
endif

	.leave
	ret
ICGETWILDCARDS	endp

C_SpellCode ends

	SetDefaultConvention
