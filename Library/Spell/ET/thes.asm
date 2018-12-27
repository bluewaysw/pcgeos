COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spell Library
FILE:		thes.asm

ROUTINES:

	Name			Description
	----			-----------
	ThesaurusOpen		Initializes the Thesaurus for use
	ThesaurusGetMeanings	Gets the meanings/senses for a given word
	ThesaurusGetSynonyms	Gets the synonyms for the last word looked up
	ThesaurusClose		Closes the Thesaurus

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tyj	8/92		Initial Version

DESCRIPTION:

	This file contains library routines to interface Houghton-Mifflin's
	Electronic Thesaurus code. 

	$Id: thes.asm,v 1.1 97/04/07 11:07:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ThesaurusCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes Thesaurus - must be called before using thesaurus.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax = ET_SUCCESS (1) or error code 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesaurusOpen	proc	far
	uses	bx, cx, dx, ds, es, si, di, bp
	.enter

	;
	; Set the directory path to find the db file, com_thes.dis in pubdata
	;
	call	FILEPUSHDIR
	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs, dx
	mov	dx, offset thesPathName
	call	FileSetCurrentPath	

	;
	; Set up the initial et_ctrl structure:
	;
	; First, allocate memory for the EtCtrl and Lookup structures
	; 	plus a buffer for the filename
	; 
	mov	ax, ((size EtCtrl) + (size Lookup) + WORDLEN)
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK)shl 8) \
			or mask HF_SWAPABLE or mask HF_SHARABLE
	mov	bx, handle 0
	call	MemAllocSetOwner	; bx=block,ax=seg,cx destroyed	
	jc	markFlagDisabled	; exit on error
	mov	cx, segment udata
	mov	ds, cx
	mov	ds:[anEtCtrlBlock], bx	; save the block handle

	;
	; Initialize fields in the et_ctrl structure
	;
	mov	ds, ax			; ds:0 -> anEtCtrl
	clr	ds:ramsectors
	segmov	es, ds, cx		; es:di -> filename buffer
	mov	di, ((size EtCtrl) + (size Lookup))
	call	ThesaurusGetFilename	; buffer filled
	mov	ds:db_fname.segment, ax
	mov	ds:db_fname.offset, ((size EtCtrl) + (size Lookup))
	mov	ds:thisLookup.segment, ax
	mov	ds:thisLookup.offset, size EtCtrl ; Lookup alloc in same block

	;
	; Push args to et_load in reverse order
	;
	push	ds  		; push the pointer to the et_ctrl structure
	clr	cx		
	push	cx
	mov	ax, THES_1K_LOAD_SECTORS	; push kbytes
	push	ax	

ifdef __BORLANDC__
	call	_et_load
else
	call	et_load			; ax = 1 for success
endif

	;
	; Restore the stack
	;
	add	sp, 6			; pushed 3 word args = 6 bytes

	;
	; Unlock the EtCtrl block
	;
	mov	cx, segment udata
	mov	ds, cx
	mov	bx, ds:[anEtCtrlBlock]
	call	MemUnlock

	;
	; Mark that we've opened the thesaurus
	;
	mov	ds:[thesaurusOpened], 1
	
	;
	; Set the disabledFlag to 1 if et_load failed, otherwise clear it
	;
	cmp	ax, 1
	jne 	markFlagDisabled
	mov	bx, segment udata
	mov	ds, bx
	clr	ds:[disabledFlag]

exit:
	call 	FILEPOPDIR

	.leave
	ret
markFlagDisabled:
	mov	bx, segment udata
	mov	ds, bx
	mov	ds:[disabledFlag], 1
	jmp 	exit
ThesaurusOpen	endp
ForceRef ThesaurusOpen


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusGetMeanings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a word, returns a chunk array of meaning strings and
		an array of parts of speech (1 per meaning)

CALLED BY:	global (ThesDictLookup from UICThesDictControl)

PASS:		cx:dx = word to look up (DBCS)

RETURN:		^lbx:si = chunk array of null terminated strings,
		each of which is one meaning. Note if size = 0, word not found

			NOTE: in the REDWOOD case, this is returned as an array
			of synonyms which correspond to that meaning, instead of
			the definition for the meaning.		EDS 1/7/94

		^lbx:dx = integer array chunk (0..25). Integers range 
		from 0 to 3, and represent the part of speech of the 
		corresponding meaning (if that meaning exists). 
		0 = adj, 1 = noun, 2 = adverb, 3 = verb.

		ax = success/failure indicator:
		         number of synonyms/meanings found = success
			 0 = word not found
			 negative => see thesConstant.def (ET_NO_ERROR, et al)
 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ThesaurusGetMeanings		proc	far
	uses	cx, di, bp, es, ds
	textBufferBlock		local word
	textBufferSegment 	local word
	returnBlock		local word
	chunkArrayOffset	local word	
	grammarArrayHandle	local word
	grammarArrayOffset	local word
	indicator		local word
;DBCS <	sbcsWordBuf		local MAX_ENTRY_LENGTH dup (char)	>
DBCS <	sbcsWordBuf		local 26 dup (char)	>
	.enter

	push	cx, dx

	call	ThesPSem		; set the thesaurus semaphore

if DBCS_PCGEOS
	;
	; create SBCS version
	;
	push	cx, si, es, di
	mov	ds, cx
	mov	si, dx
	segmov	es, ss
	lea	di, sbcsWordBuf
	mov	cx, length sbcsWordBuf
10$:
	lodsw
	stosb
	tst	ax
	loopne	10$
	pop	cx, si, es, di
endif
	
	;
	; Check if the thesaurus has been initialized. If not, do it now.
	;
	mov	ax, segment udata
	mov	ds, ax
	tst	ds:[thesaurusOpened]
	jnz	initialized
	call	ThesaurusOpen

initialized:
	;
	; Set the directory path to find the db file, com_thes.dis in pubdata
	;
	call	FILEPUSHDIR
	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs, dx
	mov	dx, offset thesPathName
	call	FileSetCurrentPath

	;
	; If file wasn't opened right, don't do anything else
	;
	push	ds
	mov	ax, segment udata
	mov	ds, ax
	tst	ds:[disabledFlag]
	pop	ds

;------------
;EDS 1/11/94: bug fix - should pop regs before exiting.
;OLD:
;LONG	jnz	exit

;NEW:
	jz	allocBuffer

	mov	indicator, ET_FILE_OPEN_ERROR
	pop	cx, dx
	jmp	exit
;------------

allocBuffer:
	;
	; Allocate a buffer for the call to ET
	;
	mov	ax, MAX_MEANINGS_ARRAY_SIZE
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK)shl 8) \
			or mask HF_SWAPABLE
	mov	bx, handle 0
	call	MemAllocSetOwner	; bx=block,ax=seg,cx destroyed
	jnc	3$

	mov	indicator, THES_MEMALLOC_ERROR
	pop	cx, dx
	jmp	exit

3$:
	mov	textBufferBlock, bx
	mov	textBufferSegment, ax

	;
	; Allocate a locked block for the chunk array and grammar array. 
	;
	mov	ax, MAX_MEANINGS_ARRAY_SIZE * 2
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK)shl 8) \
			or mask HF_SWAPABLE
	mov	bx, handle 0
	call	MemAllocSetOwner	; bx=block,ax=seg,cx destroyed
	jnc	5$

	mov	indicator, THES_MEMALLOC_ERROR
	pop	cx, dx
	jmp	freeBufferExit

5$:
	mov	returnBlock, bx

	;
	; Create an lmem heap in the block
	;
	mov	ds, ax				; ds = block segment
	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, MAX_DEFINITIONS
	mov	dx, size LMemBlockHeader
	mov	si, MAX_MEANINGS_ARRAY_SIZE
	clr	di
	call	LMemInitHeap			; ds = block seg, may change

	;
	; Create the chunk array
	;
	clr	bx				; var sized elements
	clr	ax, cx, si
	call	ChunkArrayCreate 		; *ds:si = chunk array
	mov	chunkArrayOffset, si	
 	
	;
	; Create the grammar array
	;
	clr	ax
	mov	cx, GRAMMAR_ARRAY_SIZE		; (small)
	call	LMemAlloc			; ax = chunk handle
	mov	grammarArrayHandle, ax
	mov	di, ax
	mov	ax, ds:[di] 			; deref the handle
	mov	grammarArrayOffset, ax

	;
	; Lock the anEtCtrl block
	;
	push	ds, bx
	mov	ax, segment udata
	mov	ds, ax
	mov	bx, ds:[anEtCtrlBlock]
	call	MemLock				; ax = segment
	mov	ds, ax
	mov	ds:thisLookup.segment, ax	; set Lookup segment right
	mov	ds:db_fname.segment, ax		; set filename segment right
	pop	ds, bx

	;
	; Push args in reverse ord to Croutine
	;
	pop	cx, dx				; cx:dx -> lookup word
	push	ds				; save ds = chunk array block

if DEFINITIONLESS_THESAURUS	
	push	cx, dx
endif

	push	ax				; ctrl (EtCtrl ptr)
	clr	ax
	push	ax

	mov	ax, ds				; pos (grammar array)
	push	ax
	mov	ax, grammarArrayOffset
	push	ax

	mov	ax, textBufferSegment		; stringout fptr
	push	ax
	clr	ax 
	push	ax

	clr 	ax				; option 
	push	ax

if DBCS_PCGEOS
	push	ss
	lea	ax, sbcsWordBuf
	push	ax
else
	push	cx				; wordin
	push	dx
endif

ifdef __BORLANDC__
	call	_et
else
	call	et		; H-M's electronic thesaurus "get meanings"
				; returns # of meanings found in ax (?)
endif

	add	sp, 18		; take parameters off stack (9words = 18 bytes)

if DEFINITIONLESS_THESAURUS	
	pop	cx, bx		;cx:bx = current word
endif

	mov	indicator, ax	; save the success/failure return
	pop	ds			; ds:si -> chunk Array

	;
	; Check if word found (ax between 1 and MAX_DEFINITIONS)
	;
	cmp	ax, MAX_DEFINITIONS
	jg	notFound
	cmp	ax, 0	
	jle	notFound

	segmov	es, textBufferSegment	; es:di -> text buffer
	clr	di
	mov	dx, grammarArrayHandle	; dx = grammar array chunk handle
	mov	si, chunkArrayOffset	; ds:si -> chunk array

	;Registers:
	;	ax	= number of meanings found (1 - MAX_DEFINITIONS)
	;	es:di	= text buffer containing the list of meanings, as
	;			returned by ET.
	;	di	= 0
	;	*ds:dx	= grammer array
	;	*ds:si	= empty chunk array, to be filled in with the text
	;			of each meaning.
	;	ss:bp	= stack frame
	;
	;  redwood only:
	;	cx:bx	= current word

if not DEFINITIONLESS_THESAURUS	
	;Parse the meaningString

	call 	ThesaurusMeaningsParse
else	
	;nondef thesaurus: since we don't have a list of meanings
	;(definitions) returned from ET, we are going to instead use the
	;synonym list that corresponds to each meaning (1 to AX).

	call	ThesaurusUseSynonymListsForMeanings
endif	

notFound:
	;
	; Unlock the anEtCtrl block
	;
	mov	ax, segment udata
	mov	ds, ax
	mov	bx, ds:[anEtCtrlBlock]
	call	MemUnlock	

	;
	; Unlock the chunk array block
	;
	mov	bx, returnBlock
	call	MemUnlock

freeBufferExit:
	;
	; Free the buffer block
	;
	mov	bx, textBufferBlock
	call	MemFree

exit:

	call 	FILEPOPDIR

	call	ThesVSem		; unset the thesaurus semaphore

	mov	ax, indicator
	mov	bx, returnBlock

	.leave
	ret
ThesaurusGetMeanings	endp
ForceRef ThesaurusGetMeanings


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusMeaningsParse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an HM meanings string and parses it into a chunk array

CALLED BY:	ThesaurusGetMeanings (INTERNAL)

PASS:		*ds:si = chunk array (ds may move if array resized)
				(DBCS)
		es:di = source HM string

RETURN:		nothing

DESTROYED:	nothing (warning: ds may have moved)

PSEUDO CODE/STRATEGY:
		source HM string contains definitions separated by periods
		(hopefully), and ends with a double period. So we just search
		for the first period, copy that much of the string into the
		current chunk array element, and repeat until two periods 
		(or a null terminator of course) are found.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not DEFINITIONLESS_THESAURUS	

ThesaurusMeaningsParse	proc	far
	uses	ax, bx, cx, dx, es, di, si, bp
	.enter

10$:	
	clr	ah
	mov	al, es:[di]		; remove leading spaces
	cmp	al, " "
	jne 	notSpace
	inc 	di
	jmp 	10$
notSpace:
	mov	al, "."			; scan for period
	mov	cx, MAX_DEFINITION_SIZE	
scan:
	repne	scasb
	jcxz	foundEnd

	cmp	{byte}es:[di], '.'	; found end if double period
	je	foundEnd
	cmp	{byte}es:[di], 'A'	; found end if next character is a
	jb	scan			;  capital letter
	cmp	{byte}es:[di], 'Z'	;
	ja	scan			; else continue scanning for end

foundEnd:
	neg	cx			; set es:di -> start of substring
	add	cx, MAX_DEFINITION_SIZE	; cx = number of chars in substring
	sub	di, cx			; es:di -> start of current substring
	mov	dx, di			; dx = offset start of substring
	dec	cx			; don't copy the period

	mov	ax, cx			; size = cx
	inc	ax			; plus null terminator 
DBCS <	shl	ax, 1			; # chars -> # bytes		>
	call	ChunkArrayAppend	; ds:di -> new element
	push	ds, si			; save ds:si->chunk array(maybe moved)
	segxchg	ds, es, si		; ds:si -> start of substring
	mov	si, dx			; and es:di -> new element
if DBCS_PCGEOS
	clr	ah
20$:
	lodsb				; copy substring to chunk array element
	stosw
	loop	20$
	clr	ax
	mov	es:[di], ax		; add null terminator
else
	rep	movsb			; copy substring to chunk array element
	clr	al
	mov	es:[di], al		; add null terminator
endif
	inc	si			; move es:di past the period	

	segmov	es, ds, di		; set es:di -> rest of source string
	mov	di, si
	pop	ds, si			; ds:si -> chunk array
	mov	al, es:[di]		; test for end of string 
	cmp	al, "."
	je 	exit
	tst	al
	je	exit
	jmp 	10$
	
exit:
	.leave
	ret
ThesaurusMeaningsParse	endp

endif				


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusUseSynonymListsForMeanings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redwood-specific hack: since we don't have a list of meanings
		(definitions) returned from ET, we are going to instead use the
		synonym list that corresponds to each meaning (1 to AX).

CALLED BY:	ThesaurusGetMeanings (INTERNAL)

PASS:		*ds:si	= empty chunk array (ds may move if array resized)
		es:di	= source HM string (IGNORED)
		cx:bx	= current word

RETURN:		nothing

DESTROYED:	warning: ds may have moved
		bx, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EDS	1/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DEFINITIONLESS_THESAURUS	

MAX_LENGTH_SYNONYM_LIST_STRING	= 26+5
			;(based on MAX_ENTRY_LENGTH+5, as it appears in the
			; .ui file.)

ThesaurusUseSynonymListsForMeanings	proc	far
	uses	ax, dx, es, di, si, bp
	.enter

	;see if there are any meanings at all.

	tst	ax			;necessary?
	jz	done			;skip to end if not...

	mov	dx, cx			;dx:bx = current word
	mov	cx, 1			;start with meaning #1

getSynonyms:
	;Registers:
	;	ax	= number of meanings to look-up
	;	cx	= current meaning #
	;	dx:bx	= current word
	;	*ds:si	= chunk array

	;for this meaning, get the list of synonyms from ET.

	push	ax, bx, cx, dx

	push	ds, si

	mov	ds, dx			;ds:si = current word
	mov	si, bx

					;pass cx = meaning #
	call	ThesaurusGetSynonymsListAsString
					;returns: ^bx = es:0 = text block
	pop	ds, si

	tst	bx			;text block returned?
	jz	nextMeaning		;skip if not...

	dec	ax			;any error returned?
	js	freeBlock		;skip if so...

	;Since we will be displaying this string in a GenList, we only need
	;to copy a fixed number of characters. Create a new chunk array
	;element, and copy the string to it.

	mov	ax, MAX_LENGTH_SYNONYM_LIST_STRING+1
					;ax = length of element, including
					;null term.
	call	ChunkArrayAppend	;ds:di -> new element
					;DS MAY MOVE
	push	ds, si
	mov	cx, MAX_LENGTH_SYNONYM_LIST_STRING
	segxchg	ds, es			;es:di = new element in array
	clr	si			;ds:si = source string
	rep	movsb

	mov	al, 0			;append a null-term, in case the string
	stosb				;is long and one was not already copied
	pop	ds, si

freeBlock:
	;unlock the block returned by ThesaurusGetSynonymsListAsString

	call	MemFree

nextMeaning:
	;on to the next meaning...

	pop	ax, bx, cx, dx
	inc	cx
	cmp	cx, ax
	jbe	getSynonyms

done:
	.leave
	ret
ThesaurusUseSynonymListsForMeanings	endp

endif				


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusGetSynonyms
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes the number of the sense that is desired (see 
		ThesaurusGetMeanings) and returns a chunk array of null
		terminated strings, one per synonym.

CALLED BY:	GLOBAL

PASS:		ds:si = word to lookup (DBCS)
		cx = sense number corresponding to sense to get synonyms for
		
RETURN:		^ldx:si = chunk array of null-terminated synonym strings

		ax = success/failure indicator:
			number of senses = success
			0 = word not found
			negative = error (see thesConstant.def ET_NO_ERROR etc)
	
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:		
		call et (getmeanings) then et (getsynonyms) so that
		the shared et-ctrl structure is set right. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ThesaurusGetSynonyms		proc	far
	uses	bx, cx, es, ds, di, bp
	textBufferBlock		local word
	textBufferSegment	local word
	returnBlock		local word
	returnSegment		local word
	chunkArrayOffset	local word	
	grammarArrayHandle	local word
	grammarArrayOffset	local word
	anEtCtrlSegment		local word
;DBCS <	sbcsWordBuf		local MAX_ENTRY_LENGTH dup (char)	>
DBCS <	sbcsWordBuf		local 26 dup (char)	>
	.enter

	call	ThesPSem		; set the thesaurus semaphore

if DBCS_PCGEOS
	;
	; create SBCS version
	;
	push	cx, si, es, di
	segmov	es, ss
	lea	di, sbcsWordBuf
	mov	cx, length sbcsWordBuf
10$:
	lodsw
	stosb
	tst	ax
	loopne	10$
	pop	cx, si, es, di
endif

	;
	; Check if the thesaurus has been opened. If not, do it now	
	;
	push	ds
	mov	ax, segment udata
	mov	ds, ax
	tst	ds:[thesaurusOpened]
	jnz	initialized
	call	ThesaurusOpen

initialized:
	pop	ds
	;
	; Set the directory path to find the db file, com_thes.dis in pubdata
	;
	push	ds, si, cx		; save wordin
	call	FILEPUSHDIR
	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs, dx
	mov	dx, offset thesPathName
	call	FileSetCurrentPath

	;
	; If file wasn't opened right, don't do anything else
	;
	push	ds
	mov	ax, segment udata
	mov	ds, ax
	tst	ds:[disabledFlag]
	mov	ax, ET_FILE_OPEN_ERROR
	pop	ds

;--------------
;EDS 1/94: this is getting old...
;OLD:
;LONG	jnz	exit

;NEW:
	jnz	popDSSICX_exit
;--------------

	;
	; Allocate a buffer for the call to ET
	;
	mov	ax, MAX_MEANINGS_ARRAY_SIZE
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK)shl 8) \
			or mask HF_SWAPABLE
	mov	bx, handle 0
	call	MemAllocSetOwner		; bx=block,ax=seg,cx destroyed
	jnc	3$

	mov	ax, THES_MEMALLOC_ERROR

popDSSICX_exit:
	pop	ds, si, cx
	jmp	exit

3$:
	mov	textBufferBlock, bx
	mov	textBufferSegment, ax

	;
	; Allocate a locked block for the chunk array - 
	; note that it will be unlocked soon, we won't do it. 
	;
	mov	ax, MAX_SYNONYMS_ARRAY_SIZE * 2
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8) \
			or mask HF_SWAPABLE
	mov	bx, handle 0			
	call	MemAllocSetOwner	; bx = blockhandle, ax = segment
	jnc	5$

	mov	ax, THES_MEMALLOC_ERROR
	pop	ds, si, cx
	jmp 	freeBufferExit

5$:	
	mov	returnBlock, bx
	
	;
	; Create an lmem heap in the block
	;
	mov	ds, ax
	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, MAX_SYNONYMS
	mov	dx, size LMemBlockHeader
	mov	si, MAX_SYNONYMS_ARRAY_SIZE
	clr	di
	call	LMemInitHeap			; ds=block seg (may change) 
	mov	returnSegment, ds
	
	;
	; Create the chunk array
	;
	clr	bx				; size is variable
	clr	ax, cx, si
	call	ChunkArrayCreate 		; *ds:si = chunk array
	mov 	chunkArrayOffset, si	

	;
	; Create the grammar array
	;
	clr	ax
	mov	cx, GRAMMAR_ARRAY_SIZE		; (small)
	call	LMemAlloc			; ax = chunk handle
	mov	grammarArrayHandle, ax
	mov	si, ax
	mov	ax, ds:[si] 			; deref the handle
	mov	grammarArrayOffset, ax

	;
	; Lock the anEtCtrl block
	;
	mov	ax, segment udata
	mov	ds, ax
	mov	bx, ds:[anEtCtrlBlock]
	call	MemLock				; ax = segment
	mov	anEtCtrlSegment, ax
	mov	ds, ax
	mov	ds:thisLookup.segment, ax	; set pointer to Lookup
	mov	ds:db_fname.segment, ax		; set pointer to filename

	;
	; Get meanings
	;
	; Push args (in reverse order) to et()
	;

	pop	ds, si, cx
	push	ds, si, cx

	push	ax				; ctrl (EtCtrl ptr)	
	clr	bx
	push	bx

	mov	ax, returnSegment		; pos (grammar array)
	push	ax
	mov	ax, grammarArrayOffset
	push	ax
	mov	ax, textBufferSegment
	push	ax				; stringout
	clr	ax
	push	ax
	clr 	ax				; option 
	push	ax

if DBCS_PCGEOS
	push	ss
	lea	ax, sbcsWordBuf
	push	ax
else
	push	ds				; wordin
	push	si
endif
	
ifdef __BORLANDC__
	call	_et
else
	call	et				; ax = number of meanings found
endif

	add	sp, 18		; take parameters off stack (9words = 18 bytes)

	pop	ds, si, cx

	;
	; Check if word found (ax between 1 and MAX_DEFINITIONS)
	;
	cmp	ax, MAX_DEFINITIONS
	jg	unlockExit
	cmp	ax, 0	
	jle	unlockExit

	;
	; Get synonyms
	; Push args (in reverse order) to et()
	;

	mov	ax, anEtCtrlSegment		; anEtCtrl
	push	ax
	clr	ax
	push	ax
	
	mov	ax, returnSegment		; pos (grammar array)
	push	ax
	mov	ax, grammarArrayOffset
	push	ax

	mov	ax, textBufferSegment		; stringout
	push	ax
	clr	ax
	push	ax

	push	cx				; option = sense# (passd in cx)

if DBCS_PCGEOS
	push	ss
	lea	ax, sbcsWordBuf
	push	ax
else
	push	ds				; wordin
	push	si
endif
	
ifdef __BORLANDC__
	call	_et
else
	call	et		; H-M's electronic thesaurus "get meanings"
				; returns # of synonyms found in ax (?)
endif

	add	sp, 18		; take parameters off stack (9words = 18 bytes)

	;
	; Check if synonyms found (ax between 1 and MAX_DEFINITIONS)
	;
	cmp	ax, MAX_SYNONYMS
	jg	unlockExit
	cmp	ax, 0	
	jle	unlockExit

	;
	; Parse the synonym string into the chunk array
	;
	mov	es, textBufferSegment		; es:di -> synonymString
;EDS 1/94: Not necessary because of ThesaurusSynonymsParse rewrite.
;	clr	di

	mov	ds, returnSegment
	mov	si, chunkArrayOffset

	call 	ThesaurusSynonymsParse

unlockExit:
	mov	bx, returnBlock
	call	MemUnlock
	mov	dx, bx				; return dx:si -> chunk array

freeBufferExit:
	mov	bx, textBufferBlock		; free the buffer block
	call	MemFree

	;
	; Unlock the anEtCtrl block
	;
	push	ax
	mov	ax, segment udata
	mov	ds, ax
	mov	bx, ds:[anEtCtrlBlock]
	call	MemUnlock	
	pop	ax

exit:
	call 	FILEPOPDIR

	call	ThesVSem			; unset the thesaurus semaphore

	mov	bx, returnBlock

	.leave
	ret
ThesaurusGetSynonyms	endp
ForceRef ThesaurusGetSynonyms


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusGetSynonymsListAsString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an ascii string containing the list of synonyms which
		correspond to a given meaning.

CALLED BY:	ThesaurusUseSynonymListsForMeanings

PASS:		ds:si = word to lookup 
		cx = sense number corresponding to sense to get synonyms for

		*** THES SEMAPHORE ALREADY GRABBED BY CALLER ***
		
RETURN:		^hbx	= es:0	= block containing list of synonyms
			CALLER MUST FREE THAT BLOCK IF BX!=0

		ax = success/failure indicator:
			number of senses = success
			0 = word not found
			negative = error (see thesConstant.def ET_NO_ERROR etc)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:		
		call et (getmeanings) then et (getsynonyms) so that
		the shared et-ctrl structure is set right. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EDS	1/94		Adapted from ThesaurusGetSynonyms

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DEFINITIONLESS_THESAURUS	

ThesaurusGetSynonymsListAsString		proc	far
	uses	cx, bp

	textBufferBlock		local word
	textBufferSegment	local word

	returnBlock		local word
	returnSegment		local word

	grammarArrayHandle	local word
	grammarArrayOffset	local word

	anEtCtrlSegment		local word

	.enter

	mov	textBufferBlock, 0	;indicate that we have not yet
					;allocated the text block.

	;
	; Set the directory path to find the db file, com_thes.dis in pubdata
	;

	push	ds, si, cx		; save wordin
	call	FILEPUSHDIR
	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs, dx
	mov	dx, offset thesPathName
	call	FileSetCurrentPath

	;
	; If file wasn't opened right, don't do anything else
	;
	push	ds
	mov	ax, segment udata
	mov	ds, ax
	tst	ds:[disabledFlag]
	mov	ax, ET_FILE_OPEN_ERROR
	pop	ds
	jz	allocBuffer

	pop	ds, si, cx
	jmp	exit

allocBuffer:
	;
	; Allocate a buffer for the call to ET
	;
	mov	ax, MAX_MEANINGS_ARRAY_SIZE
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK)shl 8) \
			or mask HF_SWAPABLE
	mov	bx, handle 0
	call	MemAllocSetOwner	; bx=block,ax=seg,cx destroyed
	jnc	3$

	mov	ax, THES_MEMALLOC_ERROR
	pop	ds, si, cx
	jmp	exit
3$:
	mov	textBufferBlock, bx
	mov	textBufferSegment, ax

	;
	; Allocate a locked block for the chunk array - 
	; note that it will be unlocked soon, we won't do it. 
	;

	mov	ax, MAX_SYNONYMS_ARRAY_SIZE * 2
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8) \
			or mask HF_SWAPABLE
	mov	bx, handle 0
	call	MemAllocSetOwner	; bx = blockhandle, ax = segment
	jnc	5$

	mov	ax, THES_MEMALLOC_ERROR
	pop	ds, si, cx
	jmp 	unlockECtrl
5$:	
	mov	returnBlock, bx

	;
	; Create an lmem heap in the block
	;

	mov	ds, ax
	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, MAX_SYNONYMS
	mov	dx, size LMemBlockHeader
	mov	si, MAX_SYNONYMS_ARRAY_SIZE
	clr	di
	call	LMemInitHeap			; ds=block seg (may change) 
	mov	returnSegment, ds
	
	;
	; Create the grammar array
	;

	clr	ax
	mov	cx, GRAMMAR_ARRAY_SIZE		; (small)
	call	LMemAlloc			; ax = chunk handle
	mov	grammarArrayHandle, ax
	mov	si, ax
	mov	ax, ds:[si] 			; deref the handle
	mov	grammarArrayOffset, ax

	;
	; Lock the anEtCtrl block
	;

	mov	ax, segment udata
	mov	ds, ax
	mov	bx, ds:[anEtCtrlBlock]
	call	MemLock				; ax = segment
	mov	anEtCtrlSegment, ax
	mov	ds, ax
	mov	ds:thisLookup.segment, ax	; set pointer to Lookup
	mov	ds:db_fname.segment, ax		; set pointer to filename

	;
	; Get meanings
	;
	; Push args (in reverse order) to et()
	;

	pop	ds, si, cx
	push	ds, si, cx

	push	ax				; ctrl (EtCtrl ptr)	
	clr	bx
	push	bx

	mov	ax, returnSegment		; pos (grammar array)
	push	ax
	mov	ax, grammarArrayOffset
	push	ax
	mov	ax, textBufferSegment
	push	ax				; stringout
	clr	ax
	push	ax
	clr 	ax				; option 
	push	ax
	push	ds				; wordin
	push	si
	
ifdef __BORLANDC__
	call	_et
else
	call	et				; ax = number of meanings found
endif

	add	sp, 18		; take parameters off stack (9words = 18 bytes)

	pop	ds, si, cx

	;
	; Check if word found (ax between 1 and MAX_DEFINITIONS)
	;

	cmp	ax, MAX_DEFINITIONS
	jg	unlockExit

	cmp	ax, 0	
	jle	unlockExit

	;
	; Get synonyms
	; Push args (in reverse order) to et()
	;

	mov	ax, anEtCtrlSegment		; anEtCtrl
	push	ax
	clr	ax
	push	ax
	
	mov	ax, returnSegment		; pos (grammar array)
	push	ax
	mov	ax, grammarArrayOffset
	push	ax

	mov	ax, textBufferSegment		; stringout
	push	ax
	clr	ax
	push	ax

	push	cx				; option = sense# (passd in cx)

	push	ds				; wordin
	push	si
	
ifdef __BORLANDC__
	call	_et
else
	call	et		; H-M's electronic thesaurus "get meanings"
				; returns # of synonyms found in ax (?)
endif

	add	sp, 18		; take parameters off stack (9words = 18 bytes)

	;return AX = # synonyms found (between 1 and MAX_SYNONYMS)

unlockExit:
	mov	bx, returnBlock
	call	MemFree

unlockECtrl:
	; Unlock the anEtCtrl block

	push	ax
	mov	ax, segment udata
	mov	ds, ax
	mov	bx, ds:[anEtCtrlBlock]
	call	MemUnlock	
	pop	ax

exit:
	call 	FILEPOPDIR

	;return info about the text block

	mov	bx, textBufferBlock		; return ^hbx = block containing
						; ascii string. (locked)
	mov	es, textBufferSegment		; es:0 = same

	.leave
	ret
ThesaurusGetSynonymsListAsString	endp
endif			


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusSynonymsParse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an HM synonym string and parses it into a chunk array

CALLED BY:	ThesaurusGetSynonyms (INTERNAL)

PASS:		*ds:si = synonym chunk array
				(DBCS)
		es:0 = HM synonym source string		

RETURN:		nothing

DESTROYED:	nothing (warning: ds may have moved)

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		HM string should have synonyms separated by commas and ending
		with a period so we just search for the next comma, copy that
		much string into the synonym chunk array element, and repeat
		until a period (or null term) is found. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/19/92		Initial version
	EDS	1/11/94		Rewritten to fix more bugs than you can
				shake a stick at.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ThesaurusSynonymsParse	proc far
	uses	ax, bx, cx, dx, es, di, si
	.enter
	
	mov	di, -1

	;loop for each synonym that we find in the string:

skipSpaces:
	;first, skip any leading white space

	inc	di
	mov	al, es:[di]
	cmp	al, ' '
	je	skipSpaces

	;At this point, we are at the start of a valid synonym, or at the
	;end of the string.

	cmp	al, '.'			;reached end of string?
	jz	done			;skip if so...

	;Determine the length of this synonym by finding the next period
	;or comma character. (We are making the assumption that this synonym
	;is at least one character long.)

	mov	dx, di			;es:dx = start of synonym

scanForEndOfSynonym:
	inc	di
	mov	bl, es:[di]
	cmp	bl, ','
	je	foundEnd

	cmp	bl, '.'
	jnz	scanForEndOfSynonym

foundEnd:
	;We've found the end of this synonym. Determine its length,
	;and create a new element in the chunk array to hold it (plus null term)

	push	di			;save pointer to real end of synonym
	mov	ax, di			;ax = pointer to real end of synonym

	sub	ax, dx			;di = length
	cmp	ax, MAX_SYNONYM_SIZE	;too large?
	jb	createNewElement	;skip if not...

	mov	ax, MAX_SYNONYM_SIZE	;yes: reduce length

createNewElement:
	mov	cx, ax			;cx = length (for rep movsb, below)
	inc	ax			;ax = length + 1 for null term
DBCS <	shl	ax, 1			; #chars -> # bytes		>
	call	ChunkArrayAppend	;WARNING: DS MAY MOVE
					;returns ds:di = new element

	;copy the synonym into the chunk array element

	segxchg	es, ds			;ds:si = source (synonym)
	xchg	si, dx			;es:di = destination (new element)
					;*ds:dx = chunk array

if DBCS_PCGEOS
	clr	ah
20$:
	lodsb				; copy substring to chunk array element
	stosw
	loop	20$
	clr	ax
	stosw				; add a null terminator
else
	rep	movsb			;copy the string
	clr	ax
	stosb				;append null terminator
endif

	segxchg	es, ds			;restore *ds:si = chunk array
	mov	si, dx			;and es:0 = string

	;move onto the next synonym

	pop	di			;es:di = end of this synonym (either
					;a comma or period)

	cmp	bl, ','			;this synonym ended with a comma?
	je	skipSpaces		;loop if so (will increment DI,
					;so that we skip this comma before
					;starting to skip spaces.)
done:
	.leave
	ret
ThesaurusSynonymsParse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the thesaurus. Must be called to end thesaurus session.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax = ET_SUCCESS or ET_FILECLOSE_ERROR
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesaurusClose	proc	far
	uses	bx, cx, dx, es, ds, di, si, bp
	.enter

	;
	; Set the directory path to find the db file, com_thes.dis in pubdata
	;
	call	FILEPUSHDIR
	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs, dx
	mov	dx, offset thesPathName
	call	FileSetCurrentPath	; if not found, et_load returns error
					; later, so don't bother checking here

	;
	; If thesaurus wasn't opened right, don't do anything else
	;
	mov	ax, segment udata
	mov	ds, ax
	tst	ds:[disabledFlag]
	mov	ax, ET_FILE_OPEN_ERROR
	jnz	exit

	;
	; If thesaurus wasn't opened at all, don't do anything else
	;
	tst	ds:[thesaurusOpened]
	jz	exit

	;
	; Lock the anEtCtrl block
	;
	mov	ax, segment udata
	mov	ds, ax
	mov	bx, ds:[anEtCtrlBlock]
	call	MemLock				; ax = segment
	mov	ds, ax
	clrdw	ds:thisLookup			; NULL thisLookup segment
						; We must do this since the
						; Lookup structure is in the 
						; same block and EtClose will
						; try and Free the Lookup
						; structure unless it's null

	;
	; Push parameters to et_close (in reverse order)
	;
	push	ax				; et_ctrl
	clr	ax
	push	ax
	
ifdef __BORLANDC__
	call	_et_close
else
	call	et_close			; ax = success/failure
endif

	add 	sp, 4				; 2 words = 4 bytes off stack 

	;
	; Free the anEtCtrl block
	;	
	push	ax
	mov	ax, segment udata
	mov	ds, ax
	mov	bx, ds:[anEtCtrlBlock]
	call	MemFree
	pop	ax

exit:
	;
	; Mark that the thesaurus is no longer open.
	;
	clr	ds:[thesaurusOpened]
	call 	FILEPOPDIR
	.leave
	ret
ThesaurusClose	endp
ForceRef ThesaurusClose


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesPSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	P's the thesaurus semaphore

CALLED BY:	LOCAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/20/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesPSem	proc	near
	uses	ax, es, bx
	.enter

	mov	ax, segment dgroup
	mov 	es, ax
	mov	bx, es:[thesaurusSem]
	call	ThreadPSem

	.leave
	ret
ThesPSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesVSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	V's the thesaurus semaphore

CALLED BY:	LOCAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/20/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesVSem	proc	near
	uses	ax,bx,es
	.enter

	mov	ax, segment dgroup
	mov 	es, ax
	mov	bx, es:[thesaurusSem]
	call	ThreadVSem

	.leave
	ret
ThesVSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusCheckAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the thesaurus database file exists.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		cx = 0 if file not found, nonzero otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	12/ 8/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBCS <thesPathName	wchar	"DICTS",0				>
SBCS <thesPathName	char	"DICTS",0				>
ThesaurusCheckAvailable	proc	far
	uses		di, es, bx, ds, dx
SBCS <	thesFileName	local	WORDLEN dup(char)			>
DBCS <	thesFileName	local	WORDLEN dup(wchar)			>
	.enter

	;
	; Get the thesaurus file name, go to PUBDATA/DICTS and see if the
	; 	thesaurus file exists.
	;

	lea 	di, thesFileName		; es:di -> thesFileName
	segmov	es, ss
	call	ThesaurusGetFilename
	call	FilePushDir

	mov	bx, SP_PUBLIC_DATA
	segmov	ds, cs
	mov	dx, offset thesPathName
	call	FileSetCurrentPath
	jc	error

	segmov	ds, ss
	lea	dx, thesFileName
	call	FileGetAttributes
error:
	mov	cx, TRUE		; return cx nonzero if no error
	jnc	exit
	clr	cx	

exit:
	call	FilePopDir
	.leave
	ret
ThesaurusCheckAvailable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusGetFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the thesaurus database file name into the passed buffer.

CALLED BY:	LOCAL
PASS:		es:di = ptr to buffer for filename
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	12/ 8/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	thesTextCategory	char	"text",0
	thesKey			char	"thesaurus",0
SBCS <	thesName		char	"COM_THES.DIS",0		>
DBCS <	thesName		wchar	"COM_THES.DIS",0		>
ThesaurusGetFilename	proc	far
	uses	bp, bx, cx, ds, dx, si
	.enter

	mov	bp, WORDLEN or INITFILE_INTACT_CHARS
	mov	cx, cs
	mov	ds, cx
	mov	dx, offset thesKey
	mov	si, offset thesTextCategory
	call	InitFileReadString
	jnc	10$

	;
	; Filename not found in initfile, copy over default database name.
	;
SBCS <	mov	cx, size thesName					>
DBCS <	mov	cx, length thesName					>
	mov	si, offset thesName
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
10$:
	.leave
	ret
ThesaurusGetFilename	endp


ThesaurusCode ends












