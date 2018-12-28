COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spell Library
FILE:		thesCtrl.asm

ROUTINES:

	Name				Description
	----				-----------

	METHODS 
	-------
	ThesControlGetInfo		returns controller build UI info 
	ThesControlUpdateUI		handles notification attrib change
	ThesControlDestroyUI		frees memory when actually called
	ThesControlGetMeaningMoniker 	sets monikers in meaning list 
	ThesControlGetSynonymMoniker	sets monikers in synonym list 
	ThesControlGetBackupMoniker	sets monikers in backup list
	ThesControlLookup		primary routine looks up the word
 	ThesControlSynonymSelected	handler for selection in synonym list
	ThesControlSynonymDoubleClick	handler for double-click in syn list 
	ThesControlMeaningSelected	handler for selecting a meaning
	ThesControlBackupSelected	handler for selecting a backup item
	ThesControlTakeText		handler for taking text from text objt
	ThesControlGetText		handler for getting text from object
	ThesControlReplace		replaces selected text with current wrd
	ThesControlActionDone		handler for returned action done mssgs

	PROCEDURES
	----------
	ThesControlAddToBackupList	adds a string to the backup list
	ThesControlAddMeanings		adds new meanings to the meaning list
	ThesControlGetChildBlock	gets the controller's child block
	ThesControlFormatLookupWord	formats the lookup word for lookup
	ThesControlStripPunctuation	strips leading and trailing punctuation
	ThesControlStripNonCharacters	strips all non-printable characters
	ThesControlAddWordToMeaningMoniker copies looked up word to mng-moniker
	ThesControlCreateBackupStrings	creates the backup strings chunk array
	ThesControlStringLength		gets length of passed string
	ThesControlDisable		disables the entire thesaurus
	SendMessageToItemsInList	sends passed message to items in list


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tyj	7/92		Initial Version

DESCRIPTION:
	This file contains routines to implement ThesControlClass, a thesaurus
	controller. 

	$Id: thesCtrl.asm,v 1.1 97/04/07 11:08:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpellClassStructures	segment	resource
	ThesControlClass		; declare the class record
SpellClassStructures	ends

TextControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MESSAGE:	ThesControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ThesControlClass

DESCRIPTION:	Return group
		Creates the controller information to build it.

PASS:		*ds:si - instance data
		cx:dx - GenControlBuildInfo structure to fill in

RETURN: 	nothing

DESTROYED:	es, di, ds, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tyj	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlGetInfo	method dynamic	ThesControlClass,
					MSG_GEN_CONTROL_GET_INFO
	mov	si, offset TC_dupInfo
	FALL_THRU	CopyDupInfoCommon

ThesControlGetInfo	endm

CopyDupInfoCommon	proc	far
	push	cx
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs, cx
	mov	cx, size GenControlBuildInfo
	rep movsb
	pop	cx
	ret
CopyDupInfoCommon	endp


;-----------------------------------------------------------
TC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY  	; GCBI_flags
	  or mask GCBF_CUSTOM_ENABLE_DISABLE,
	offset TC_IniFileKey,		; GCBI_initFileKey
	TC_gcnList,			; GCBI_gcnList
	length TC_gcnList,		; GCBI_gcnCount
	TC_notifyTypeList,		; GCBI_notificationList
	length TC_notifyTypeList,	; GCBI_notificationCount
	TCName,				; GCBI_controllerName

	handle ThesControlUI,		; GCBI_dupBlock
	offset TC_childList,		; GCBI_childList
	length TC_childList,		; GCBI_childCount
	offset TC_featuresList,		; GCBI_featuresList
	length TC_featuresList,		; GCBI_featuresCount
	TC_GCM_FEATURES,		; GCBI_features

	handle ThesControlToolboxUI,	; GCBI_toolBlock
	offset TC_toolList,		; GCBI_toolList
	length TC_toolList,		; GCBI_toolCount
	offset TC_toolFeaturesList,	; GCBI_toolFeaturesList
	length TC_toolFeaturesList,	; GCBI_toolFeaturesCount
	TC_GCM_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	TC_helpContext>			; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
SpellControlInfoXIP	segment resource
endif

TC_helpContext	char	"dbThes", 0


;------------------------------------------------------------------------------
TC_IniFileKey	char	"ThesaurusControl", 0

TC_gcnList	GCNListType \
   <MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE>,
   <MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE>

TC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SELECT_STATE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPELL_ENABLE_CHANGE>

;-------------------------------------------------------

TC_childList	GenControlChildInfo	\
	<offset ThesControlGroup, mask TDF_THESDICT,
			mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TC_featuresList	GenControlFeaturesInfo	\
	<offset ThesControlGroup, TCName, 0>
;------------------------------------------------------
TC_toolList	GenControlChildInfo	\
	<offset ThesToolTrigger, mask TDTF_THESDICT,
			mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset ThesToolTrigger, TCName, 0>

if FULL_EXECUTE_IN_PLACE
SpellControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MESSAGE:	ThesControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for ThesControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:		*ds:si - instance object
		*ds:di - instance data
		es - segment of ThesControlClass
		ss:bp - GenControlUpdateUIParams

RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tyj	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ThesControlUpdateUI	method dynamic ThesControlClass,
				MSG_GEN_CONTROL_UPDATE_UI
	objectBlock 	local 	word
	objectOffset	local 	word
	objectSegment	local 	word
	instanceOffset	local 	word
	updateOffset	local 	word
	childBlock	local 	word
	enableMessage  	local 	word
	.enter

	;
	; Save object info
	;
	mov	objectBlock, ds
	mov	objectOffset, si
	mov	instanceOffset, di
	mov	objectSegment, es
	mov	di, ss:[bp]			; updateOffset = passed bp
	mov	updateOffset, di
 	mov	bx, ss:[di].GCUUIP_childBlock	; bx = UI block 
	mov	childBlock, bx

	;
	; Check if this is a spell-enable change, or a selection change notice
	;
	cmp	ss:[di].GCUUIP_changeType, GWNT_SPELL_ENABLE_CHANGE
LONG	jne	doSelectionChange

	;
	; Set paste triggers and replacetext enabled iff text obj targeted
	;
	mov	bx, ss:[di].GCUUIP_dataBlock
	tst	bx
	jnz	15$
	mov	cx, 0
	jmp 	17$
15$:
	call	MemLock
	mov	es, ax
	mov	cx, es:[NSEC_spellEnabled]
	call	MemUnlock
17$:
	mov	ax, ATTR_THES_CONTROL_INTERACT_ONLY_WITH_TARGETED_TEXT_OBJECTS
	call	ObjVarFindData
	jnc	noDisable

	tst	cx
	mov	enableMessage, MSG_GEN_SET_NOT_ENABLED
	jz	30$
noDisable:
	mov	enableMessage, MSG_GEN_SET_ENABLED

30$:
	;
 	; Set the definition text to not scroll to end of text all the time
 	;
 	mov	ax, MSG_GEN_TEXT_SET_ATTRS
 	mov	cl, mask GTA_DONT_SCROLL_TO_CHANGES
 	mov	ch, mask GTA_TAIL_ORIENTED
	mov	bx, childBlock
 	mov	si, offset ThesDefinitionText
 	mov	di, mask MF_CALL
	push 	bp
 	call	ObjMessage	
	pop	bp

	;
	; Enable/disable the copy/paste triggers and replacetext field
	;
	mov	ax, enableMessage
	mov	si, cs 
	mov	dl, VUM_NOW
	mov	di, offset ThesTargetedTextEnableList

	call	SendMessageToItemsInList
	jmp 	exit

doSelectionChange:
	;
	; Get the MSG_META_NOTIFY_WITH_DATABLOCK datablock and check if there
	; 	is a selection.
	;
	mov	bx, ss:[di].GCUUIP_dataBlock
	tst	bx
	jz	10$
	call	MemLock
	mov	ds, ax
	mov	al, ds:[NSSC_deleteableSelection]	; is there selection?
	call	MemUnlock

	mov	es, objectSegment
	mov	ds, objectBlock
	mov	si, objectOffset
	mov	di, instanceOffset

	;
	; Mark whether or not selection exists
	;
	cmp	al, BB_TRUE
	jne	10$
	or	ds:[di].TCI_status, mask SF_SELECTION_EXISTS
	jmp	40$
10$:	and	ds:[di].TCI_status, not (mask SF_SELECTION_EXISTS)

40$:	
	;
	; If during another action, ignore changed selection
	;
	mov	ax, ds:[di].TCI_status
	test	ax, mask SF_DOING_REPLACE or mask SF_DOING_SELECT \
			or mask SF_DOING_REPLACE_AND_SELECT
	jnz	exit

	;
	; If no selection exists, clear Replace field and exit
	;
	test	ds:[di].TCI_status, mask SF_SELECTION_EXISTS
	jz	clearReplaceText

	;
	; Get the selection and look it up
	;
	push	bp
	call	ThesControlGetTextAuto
	pop	bp

exit:
	mov	ds, objectBlock
	mov	di, instanceOffset
	and	ds:[di].TCI_status, not (mask SF_DOING_REPLACE_AND_SELECT)
	.leave
	ret	

clearReplaceText:
	push	bp
FXIP <	clr	dx				;making null str	>
FXIP <	push	dx							>
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
NOFXIP<	mov	dx, cs							>
FXIP <	mov	dx, ss							>
	mov	bx, childBlock
	mov	si, offset ThesReplaceText
NOFXIP<	mov	bp, offset ThesNullList		;dx:bp = null str	>
FXIP <	mov	bp, sp				;dxbp = null str	>
	clr	cx
	mov	di, mask MF_CALL
	call	ObjMessage
FXIP <	pop	bp				;restore the stack	>
	pop	bp
	jmp 	exit

ThesTargetedTextEnableList label lptr
	lptr	offset ThesReplaceText
	lptr	offset ThesReplaceTrigger
	lptr	0

ThesNullList	label lptr
	lptr	0
ThesControlUpdateUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlDestroyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just intercepts this to free any created memory.
		Normally won't be called at all, and memory will be
		freed automatically. 

CALLED BY:	MSG_GEN_CONTROL_DESTROY_UI
PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data
		ds:bx	= ThesControlClass object (same as *ds:si)
		es 	= segment of ThesControlClass
		ax	= message #

RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/12/92   	Initial version
	Don	 2/ 8/94	Clear out any reference to the memory handle

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlDestroyUI	method dynamic ThesControlClass, 
					MSG_GEN_CONTROL_DESTROY_UI
	;
	; Free all memory blocks that hold data for the UI elements
	; Note that we should be using ".handle" instead of ".segment",
	; but the person who orignally wrote this code evidently did
	; not understand the differences between an lptr & fptr.
	;
	clr	bx
	xchg	bx, ds:[di].TCI_backups.segment
	tst	bx
	jz	meanings
	call	MemFree
meanings:
	clr	bx
	xchg	bx, ds:[di].TCI_meanings.segment
	tst	bx
	jz	synonyms
	call	MemFree
synonyms:
	clr	bx
	xchg	bx, ds:[di].TCI_synonyms.segment
	tst	bx
	jz	exit
	call	MemFree
exit:
	clr	ds:[di].TCI_status
	mov	di, offset ThesControlClass
	GOTO	ObjCallSuperNoLock

ThesControlDestroyUI	endm

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If database is not available, don't enable the thesaurus.

CALLED BY:	MSG_SPEC_BUILD
PASS:		nothing
RETURN:		nothing
DESTROYED:	allowed to destroy: di, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	12/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlSetEnabled	method dynamic ThesControlClass, MSG_SPEC_BUILD
	push	bp, ds, si
	push	bp
	mov	di, offset ThesControlClass
	call	ObjCallSuperNoLock
	pop	bp
	test	bp, mask SBF_WIN_GROUP
	jz	checkDisable
exit:
	pop	bp, ds, si
	ret
checkDisable:
	call	ThesaurusCheckAvailable		; cx = 0 if not found
	jcxz	doDisable			; disable if not found
	jmp	exit
doDisable:
	pop	bp, ds, si
	mov	di, offset ThesControlClass
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	ObjCallSuperNoLock
	ret
ThesControlSetEnabled	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlGetMeaningMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when the meaning list wants another entry, this sets
		the item's text to the next meaning.

CALLED BY:	MSG_TC_GET_MEANING_MONIKER

PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data
		bp	= position of the item requested
		ax  	= message number

RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tyj	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlGetMeaningMoniker	method dynamic ThesControlClass, 
					MSG_TC_GET_MEANING_MONIKER
SBCS <	textBuffer local (MAX_DEFINITION_SIZE + MAX_GRAMMAR_STRING) dup(char)>
DBCS <	textBuffer local (MAX_DEFINITION_SIZE + MAX_GRAMMAR_STRING) dup(wchar)>
	objectBlock	local word
	objectOffset 	local word
	instanceOffset 	local word
	chunkHandle	local word
	grammarClass	local word
	.enter

	;
	; Save instance data and object address
	;
	mov	objectBlock, ds
	mov	instanceOffset, di
	mov	objectOffset, si
	mov	cx, ss:[bp]			; cx = selection

	;
	; Get the grammar class
	;
	movdw	bxsi, ds:[di].TCI_grammars 	; bx:si -> grammar array
	call	MemLock				; lock the block; ax = segment
	mov	es, ax				; es = grammar seg
	mov	si, es:[si]			; deref; si = offset
	add	si, cx				; indexing words by selection#
	add	si, cx
	mov	ax, es:[si]			; ax = grammar class code
	mov	grammarClass, ax
	call	MemUnlock			; unlock grammar array block

	;
	; Get the grammar string
	;
	mov	si, offset grammarLookupTable
	add 	si, ax			; indexing words so add twice 
	add	si, ax
	mov	si, cs:[si]		; *(TS):si -> correct grammar string
	mov	bx, handle ThesStrings
	call	MemLock
	segmov	ds, ax			; *ds:si -> correct grammar string
	mov	si, ds:[si]		; ds:si -> correct grammar string

	;
	; Copy the grammar string to the buffer
	;
	segmov	es, ss, ax		; es = stack seg
	lea	di, textBuffer	 	; es:di -> textBuffer
	mov	ax, MAX_GRAMMAR_STRING	
	mov	dx, cx			; dx = selection
	call	ThesControlStringLength	; cx = length of grammar string
	LocalCopyNString		; es:di -> buffer w/grammar string
	mov	cx, dx 			; cx = selection
	LocalPrevChar	esdi		; go back one char pre null terminator
	mov	dx, di			; store di offset -> buffer w/grammar
	mov	ds, objectBlock		; ds:di -> instancedata
	mov	di, instanceOffset
	mov	bx, handle ThesStrings
	call	MemUnlock

	;
	; Get the chunk array 
	;
	movdw	bxsi, ds:[di].TCI_meanings,ax	; bx:si -> meaning chunkArray
	mov	di, dx			; restore di offset -> buff w/grammar
	mov	chunkHandle, bx		; save chunk array blockh
	call	MemLock			; ax = segment
	mov	ds, ax			; *ds:si -> chunk array

	;
	; Get the element we want
	;
	push	cx			; save selection
	mov	ax, cx			; ax = element to get
	mov	cx, es			; cx:dx -> buffer to fill
	mov	dx, di			
	call	ChunkArrayGetElement	; buffer filled, ax = size
	pop	cx			; restore cx = selection

	;
	; If the definition is longer than we have room to display, shorten
	; 	it to end of last word that fits (with ellipses).
	;
	mov	dx, grammarClass
	call	ThesControlFitStringWithEllipses

	;
	; Replace the moniker 
	;
	mov	ds, objectBlock		; ds:si -> object
	mov	si, objectOffset
	lea	dx, textBuffer	
	push 	bp			; save stack frame pointer
	mov	bp, cx
	mov	cx, ss				; cx:dx -> textBuffer
	call	ThesControlGetChildBlock	; bx = childBlock
	mov	si, offset ThesMeaningList
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp			; restore bp = stack frame ptr

	;
	; Unlock the chunk array block
	;
	mov	bx, chunkHandle
	call	MemUnlock
	
	.leave
	ret
ThesControlGetMeaningMoniker	endm

grammarLookupTable	word	\
	offset	adjectiveString,	
	offset	nounString,
	offset	adverbString,
	offset	verbString	

ThesStrings	segment	lmem	LMEM_TYPE_GENERAL
LocalDefString	adjectiveString 	<'(adj) ',0>
LocalDefString	nounString		<'(n) ',0>
LocalDefString	adverbString		<'(adv) ',0>
LocalDefString	verbString		<'(v) ',0>
ThesStrings	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlGetSynonymOrBackupMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the right moniker for the synonym or backup list.

CALLED BY:	MSG_TC_GET_BACKUP_MONIKER, MSG_TC_GET_SYNONYM_MONIKER

PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data
		bp	= position of the item requested
		ax  	= message number
		cx:dx 	= BackupList
RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlGetSynonymOrBackupMoniker	method dynamic ThesControlClass, 
				MSG_TC_GET_BACKUP_MONIKER,
				MSG_TC_GET_SYNONYM_MONIKER
	;
	; Get the chunk array block handle for the moniker list that's called
	;
	cmp	ax, MSG_TC_GET_BACKUP_MONIKER
	jne	synonymMoniker
	movdw	bxsi, ds:[di].TCI_backups
	jmp	commonGetMoniker
synonymMoniker:	
	movdw	bxsi, ds:[di].TCI_synonyms
commonGetMoniker:

	push	ds, cx, dx 			; save ds, Backup list
	;
	; Lock the chunk array block
	;
	call	MemLock			; ax = segment
	mov	ds, ax			; ds:si -> synonym chunkArray

	;
	; Get the element we want
	;
	mov	ax, bp			; element to find
	call	ChunkArrayElementToPtr	; cx=size, ds:di -> element
	
	;
	; Replace the moniker 
	;
	mov	cx, ds			; cx:dx -> null term array elt 
	mov	dx, di
	mov	ax, bx			; ax = chunk array blockh
	pop	ds, bx, si	 	; restore ds; bx:si -> list to send to
	push	ax			; save chunk array blockh
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	;
	; Unlock the chunk array block
	;
	pop	bx			; chunk array blockh
	call	MemUnlock
	ret
ThesControlGetSynonymOrBackupMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlLookup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	"look up" the word that is currently in the NextText field:
		copy it to the backup list, fill in Meanings and Synonyms.
		This is essentially the top level routine of the Thesaurus. 

CALLED BY:	MSG_TC_LOOKUP 
PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data

RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlLookup	method dynamic ThesControlClass, 
					MSG_TC_LOOKUP

SBCS <	textBuffer		local (MAX_ENTRY_LENGTH) dup(char)	>
DBCS <	textBuffer		local (MAX_ENTRY_LENGTH) dup(wchar)	>
	textBufferOffset	local word	; pointer into textBuffer
	numMeanings		local word
	childBlock		local word
	objectBlock		local word
	objectOffset		local word
	instanceOffset		local word

	;
	; We'll need extra stack space - get it now
	;
	mov	ax, di	
	mov	di, 1200
	call	ThreadBorrowStackSpace
	push	di
	mov	di, ax

	.enter

	;
	; Save passed object stuff
	;
	mov	objectBlock, ds	
	mov	objectOffset, si
	mov	instanceOffset, di

	;
	; Put message in definition text that we're busy looking up a word
	;
	push	bp
	call	ThesControlGetChildBlock		; bx = child block
	mov	childBlock, bx				; save childBlock
	mov	si, offset ThesDefinitionText
	mov 	bp, offset lookingUpString
	call	ThesStringSet
	pop	bp

	;
	; Mark the application as busy (just changes the cursor)
	;
	mov	si, objectOffset
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	mov	bx, segment GenApplicationClass
	mov	di, offset GenApplicationClass
	call	GenControlSendToOutputRegs

	;
	; Get the NextText field to a buffer
	;
	push	bp
	mov	bx, childBlock			; bx:si -> definition text
	mov	si, offset ThesNextText		; bx:si -> ThesNextText
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR		
	mov	dx, ss				; dx:bp -> text buffer
	lea	bp, textBuffer
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call  	ObjMessage			; cx = string length
	pop	bp

	;
	; Do a little fixing up of the lookup word  
	;
	segmov	es, ss, di			; es:di -> textBuffer
	lea	di, textBuffer	
	mov	cx, MAX_ENTRY_LENGTH
	call	ThesControlFormatLookupWord	; pass es:di -> textBuffer
				; returns es:di -> first nonspace in textBuffer
				; ax = 1 if two words, else ax = 0
				; will be null terminated past one or two words

	mov	textBufferOffset, di	; textBOffset -> first nonspace char
	mov	di, ax			; di = twoWords indicator

	;
	; Get meanings
	;
	mov	cx, ss			; cx:dx -> NEXT word
	mov	dx, textBufferOffset
	call	ThesaurusGetMeanings 	; ^lbx:si -> chunk array of meanings
					; ^lbx:dx -> grammar array
					; ax = size/failure

	tst	di			; if we're not checking two words first
	jz	gotMeanings		; then we're done, go to gotMeaning
	cmp	ax, 0			; if phrase was found, 
	jg	gotMeanings		; then go to gotMeanings
	cmp	ax, 0			; if error
LONG	jl 	notFound		; then go to notFound
	
	;
	; Phrase wasn't found, but no error... so try just first word
	; first free the array block created for the failed phrase lookup
	;
	call	MemFree

	;
	; Find the first space and change it to a null char
	;
	mov	di, textBufferOffset	
	mov	cx, (MAX_ENTRY_LENGTH-1) 
	LocalLoadChar	ax, C_SPACE
	LocalFindChar
	LocalPrevChar	esdi		; go back to the space
	LocalClrChar	ax
	LocalPutChar	esdi, ax, NO_ADVANCE ; change it to a null

	;
	; Since we are now searching only the first word of the phrase,
	; replace the phrase with this first word in the ThesNextText field
	;
	push	bp
	mov	bx, childBlock			; bx:si -> definition text
	mov	si, offset ThesNextText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, textBufferOffset
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
	
	;
	; Get meanings
	;
	mov	cx, ss			; cx:dx -> NEXT word
	mov	dx, textBufferOffset
	call	ThesaurusGetMeanings 	; ^lbx:si -> chunk array of meanings
					; ^lbx:dx -> grammar array
					; ax = size/failure
gotMeanings:
	;
	; Check if word was found or not (empty chunk array -> not found)
	;
	cmp	ax, 0			; if ax = 0 or negative then not found
LONG	jle	notFound
	mov	numMeanings, ax		; save number of meanings

	;
	; Copy this word to lastWordLookedUp
	;
	push	si
	segmov	es, ds, ax			; es:di -> lastWordLookedUp
	segmov	ds, ss, ax			; ds:si -> textBuffer
	mov	si, textBufferOffset
	mov	di, instanceOffset
	lea	di, es:[di].TCI_lastWord
	mov	ax, MAX_ENTRY_LENGTH 
	call 	ThesControlStringLength		; cx = string length
	LocalCopyNString			; copy word to lastWordLookedUp
	LocalClrChar	ax
	LocalPutChar	esdi, ax, NO_ADVANCE	; add a null terminator
	pop	si

	;
	; Copy the word to the MeaningMoniker text
	;
	push	dx, bx
	mov	ax, ss
	mov	dx, textBufferOffset
	mov	bx, childBlock
	call	ThesControlAddWordToMeaningMoniker
	pop 	dx, bx
	
	;
	; Free previous meaning chunk array block
	;
	mov	es, objectBlock			; es:di -> instance data
	mov	di, instanceOffset
	mov	ax, bx				; ax = stored chunkArrayBlock
	push	bp
	movdw	bxbp, es:[di].TCI_meanings, cx	; bx = chunkArray block
	pop	bp
	tst 	bx				; if zero, don't free
	jz	10$
	call	MemFree 
10$:	mov	bx, ax				; bx = chunk array block

	;
	; Store the chunk array and grammar array locations
	;
	movdw	es:[di].TCI_grammars, bxdx		; *bxdx
	movdw	es:[di].TCI_meanings, bxsi		; ^lbxsi

	;
	; Add the word to backup list
	;
	mov	bx, childBlock	
	segmov	ds, ss, ax			; ds:si -> textBuffer
	mov	si, textBufferOffset
	call	ThesControlAddToBackupList

	;
	; Add the meanings to the displayed list
	;
	mov	cx, numMeanings
	call	ThesControlAddMeanings		; pass bx=childblk,cx=#meanings

	;
	; Select the first Meaning
	;
	push	bp
	clr	cx, dx
	mov	si, offset ThesMeaningList		
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage		
	pop	bp	

	;
	; Fill synonym list by sending MSG_TC_MEANING_SELECTED
	;
	mov	ds, objectBlock			; ds:di -> instance data
	mov	di, instanceOffset			
	mov	si, objectOffset		; ds:si -> object
	clr	cx 				; first meaning
	mov	ax, MSG_TC_MEANING_SELECTED
	call	ObjCallInstanceNoLock

exit:
	;
	; Mark the application as no longer busy (just changes the cursor)
	;
	mov	ds, objectBlock
	mov	si, objectOffset
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	mov	bx, segment GenApplicationClass
	mov	di, offset GenApplicationClass
	call	GenControlSendToOutputRegs

	.leave
	
	;
	; Return our extra stack space
	;
	pop	di
	call	ThreadReturnStackSpace
	ret

notFound:
	push	ds
	GetResourceSegmentNS 	idata, ds, <TRASH_BX>
	mov	cx, ds
	pop	ds
	tst 	ax			; ax=0 => word not found, no error
	jnz	error			; else error
	
	;
	; Notify word not found by placing message in definition field and
	; clearing all other areas
	;
	push	bp
	mov	bx, childBlock			; bx:si -> definition text
	mov	si, offset ThesDefinitionText
	mov 	bp, offset wordNotFoundString
	call	ThesStringSet
	pop	bp

if not DEFINITIONLESS_THESAURUS	
	;
	; Clear ThesMeaningMonikerText1
	;
	push	bp
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx
	mov	bx, childBlock
	mov	si, offset ThesMeaningMonikerText1
FXIP <	clr	dx				;making null str	>
FXIP <	push	dx				;nullstr on stack	>
FXIP <	movdw	dxbp, sssp			;dx:bp = null str	>
NOFXIP<	mov	dx, cs							>
NOFXIP<	mov	bp, offset ThesNullList					>
	mov	di, mask MF_CALL
	call	ObjMessage
FXIP <	pop	bp				;restore the stack	>
	pop 	bp
endif

	;
	; Clear synonym and meaning lists
	;
	push	bp
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	clr	cx
	mov	bx, childBlock
	mov	si, offset ThesMeaningList
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	push	bp
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	clr	cx
	mov	bx, childBlock
	mov	si, offset ThesSynonymList
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	jmp 	exit
error:
	;
	; Disable the entire controller
	;
	mov	bx, childBlock
	mov	ax, offset lookupErrorString	; error message
	call	ThesControlDisable
	jmp 	exit

ThesUsableList 	label lptr	 	; list SendMessageToItemsInList
	lptr 	offset ThesControlGroup
	lptr	offset ThesDefinitionText
	lptr	offset ThesReplaceText
	lptr	offset ThesLookupTrigger
	lptr	offset ThesReplaceTrigger
	lptr	offset ThesNextText
	lptr	offset ThesBackupList
if not DEFINITIONLESS_THESAURUS	
	lptr	offset ThesMeaningMonikerText1
endif
	lptr	offset ThesMeaningList
	lptr	offset ThesSynonymList
	lptr	offset ThesToolTrigger
	lptr	0
ThesControlLookup	endm

ThesStrings	segment	lmem	LMEM_TYPE_GENERAL
LocalDefString lookingUpString		<'Looking up...',0>
LocalDefString wordNotFoundString 	<'The word was not found. Check for misspellings.',0>
LocalDefString lookupErrorString	<'An error occurred while looking for synonyms. The file ""COM_THES.DIS"" may be missing or contain errors. You may need to reinstall the software.\\\r\\\rError Code: TH-02',0>
ThesStrings	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlSynonymSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the NextText field the synonym.

CALLED BY:	MSG_TC_SYNONYM_SELECTED
PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data
		cx 	= selected item

RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlSynonymSelected	method dynamic ThesControlClass, 
					MSG_TC_SYNONYM_SELECTED

	cmp	cx, GIGS_NONE 			; if none selected
	je	exit				; then do nothing

	;
	; Get child position
	;
	push	di
	call	ThesControlGetChildBlock	; bx = ui child blockh
	mov 	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset ThesSynonymList
	mov	di, mask MF_CALL
	call	ObjMessage			; ax=selection,cxdxbp destroyed
	mov	cx, ax
	pop	di

	;
	; Set bx:si -> synonym chunk array
	;
	mov	ax, bx				; ui handle
	movdw	bxsi, ds:[di].TCI_synonyms
	push	bx				; save chunkArray handle
	push	ax 				; save ui handle
	
	;
	; Lock the chunk array block
	;
	call	MemLock				; ax = segment
	mov	ds, ax				; ds:si -> synonym chunkArray

	;
	; Get the text of the child that was selected
	;
	mov	ax, cx 
	call	ChunkArrayElementToPtr		; cx=size; ds:di -> synonym elt

	;
	; Send the text to the NextText field
	;
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ds				; dx:bp -> synonym elt
	mov	bp, di
	pop	bx				; ui blockh
	mov	si, offset ThesNextText		; bx:si -> ThesNextText
	clr 	cx 
	mov	di, mask MF_CALL
	call	ObjMessage

	;
	; Unlock the chunk array block
	;
	pop	bx				; ca blockh	
	call	MemUnlock
exit:
	ret
ThesControlSynonymSelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlSynonymDoubleClick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls ThesControlSynonymSelected followed by ThesControlLookup
		to handle a double-click in the synonym list.

CALLED BY:	MSG_TC_SYNONYM_DOUBLE_CLICK
PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data
		cx 	= current selection

RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlSynonymDoubleClick	method dynamic ThesControlClass, 
					MSG_TC_SYNONYM_DOUBLE_CLICK

	mov	ax, MSG_TC_SYNONYM_SELECTED
	call	ObjCallInstanceNoLock

	mov	ax, MSG_TC_LOOKUP
	call	ObjCallInstanceNoLock

	ret
ThesControlSynonymDoubleClick	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlMeaningSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets synonyms for selected meaning and puts them in syn list

CALLED BY:	MSG_TC_MEANING_SELECTED
PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data
		cx 	= selected item

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (message handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlMeaningSelected	method dynamic ThesControlClass, 
					MSG_TC_MEANING_SELECTED,
					MSG_TC_MEANING_DOUBLE_CLICK
	objectBlock	local word
	objectOffset	local word
	instanceOffset	local word

if not DEFINITIONLESS_THESAURUS	
	arrayBlock	local word
endif

	uiBlock		local word
	selection	local word

	;
	; Get some extra stack space
	;
	mov	ax, di
	mov	di, 1200
	call	ThreadBorrowStackSpace
	push	di	
	mov	di, ax

	.enter

	cmp	cx, GIGS_NONE			; if none selected, do nothing
	jne 	5$
	jmp	exit
5$:
	;
	; Save object stuff, selection
	;
	mov	selection, cx
	mov	objectBlock, ds
	mov	objectOffset, si
	mov	instanceOffset, di

	call	ThesControlGetChildBlock	; bx = UI childblockhandle
	mov	uiBlock, bx

	;
	; If not null, send last word looked up to NextText field
	;
	push	bp, si, cx, di, bx
	tst	ds:[di].TCI_lastWord
	jz	8$
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ds				; dx:bp -> moniker
	lea	bp, ds:[di].TCI_lastWord
	mov	si, offset ThesNextText		; bx:si -> ThesNextText
	clr 	cx 
	mov	di, mask MF_CALL
	call	ObjMessage	
	pop	bp, si, cx, di, bx
	
	;
	; And select the word in NextText
	;
	push	bp, si, cx, di, bx
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	si, offset ThesNextText
	clr	di
	call	ObjMessage
	pop	bp, si, cx, di, bx

8$:

if not DEFINITIONLESS_THESAURUS	
	;
	; Set ds:si -> meaning chunk array
	;
	movdw	bxsi, ds:[di].TCI_meanings	; ^hbx:si -> meaningCA
	mov	arrayBlock, bx

	;
	; Lock the chunk array block
	;
	call	MemLock				; ax = segment
	mov	ds, ax				; ds:si -> meaningChunkArray

	;
	; Get the text of the child that was selected
	;
	push	bp	
	mov	bp, selection 			; bp = selection id
	mov	ax, cx
	call	ChunkArrayElementToPtr		; cx=size,ds:di->meaning elmnt 
	pop	bp

	;
	; Send the text to the DefinitionText field
	;
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ds				; dx:bp	-> meaning elmnt
	mov	bx, uiBlock
	push	bp
	mov	bp, di
	mov	si, offset ThesDefinitionText
	clr 	cx 
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp	

	;
	; Unlock the chunk array block
	;
	mov	bx, arrayBlock
	call	MemUnlock

else	;DEFINITIONLESS_THESAURUS	

	;The "definition" text object is just a status display area. Clear it.

	mov	bx, uiBlock
	mov	si, offset ThesDefinitionText

	push	bp
	mov	dx, cs				; dx:bp -> text
	mov	bp, offset nullText

	clr 	cx 
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp	

endif	;DEFINITIONLESS_THESAURUS	

	;
	; Get the synonyms for this sense
 	;
	mov	cx, selection
	inc	cx				; cx = meaning# (range is 1+)
	mov	es, objectBlock			; es:di -> instance data
	mov	di, instanceOffset
	segmov	ds, es, si			; ds:si -> last word looked up
	lea	si, es:[di].TCI_lastWord	
	call	ThesaurusGetSynonyms		; ^ldx:si=chunk array; ax=size
	
	cmp	ax, 0				; if error, don't continue
	jl	error		
	tst	ax				; if not found, exit
	jz	exit

	;
	; Free the previous synonym chunk array block
	;
	push	bp
	movdw	bxbp, es:[di].TCI_synonyms, cx		; bx = block handle
	tst	bx					; if null, don't free!
	jz	10$
	call	MemFree					; else free the block
10$:	pop	bp

	;
	; Store the chunk array location
	;
	movdw	es:[di].TCI_synonyms, dxsi

	;
	; Initialize the gendynamiclist to the number of synonyms
	;
	mov	cx, ax
	mov	bx, uiBlock			; bx:si -> ThesSynonymList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	si, offset ThesSynonymList
	mov	di, mask MF_CALL
	push	bp
	call	ObjMessage
	pop	bp

	;
	; Set the synonym list display to the top of the list. 
	;
	clr	cx				; first item
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	mov	bx, uiBlock
	mov	si, offset ThesSynonymList
	mov	di, mask MF_CALL
	push	bp
	call	ObjMessage
	pop	bp

exit:
	.leave

	;
	; Return our extra stack space
	;
	pop 	di
	call	ThreadReturnStackSpace
	ret

error: 
	push	bp
	mov	bx, uiBlock				; bx:si -> ThesDefText
	mov	si, offset ThesDefinitionText
	mov	bp, offset synonymErrorString	
	call	ThesStringSet
	pop	bp
	jmp	exit
ThesControlMeaningSelected	endm

ThesStrings	segment	lmem	LMEM_TYPE_GENERAL
LocalDefString synonymErrorString	<'There was an error while searching for synonyms.\\\r\\\rError Code: TH-01', 0>
ThesStrings	ends


if DEFINITIONLESS_THESAURUS	
nullText	char	0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlBackupSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks up the selected BackupList item. 

CALLED BY:	
PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data
		cx = current selection
		es = segment ThesControlClass

RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlBackupSelected	method dynamic ThesControlClass, 
					MSG_TC_BACKUP_SELECTED

	call	ThesControlGetChildBlock	; bx = childBlockHandle

	;
	; Set ds:si -> item's string
	;
	push	ds, di, si, bx			; save object stuff
	segmov	es, ds, ax			; es:di -> instance data
	mov	dx, bx				; save bx = childBlock
	movdw	bxsi, es:[di].TCI_backups	; ^lbx:si -> backups chnk array
	push	bx				; save the chunk array block
	call	MemLock				; lock the chunk array
	mov	bx, dx				; restore childblock
	mov	ds, ax				; ds:si -> chunk array
	mov	ax, cx				; ax = element to find
	call	ChunkArrayElementToPtr		; ds:di -> element

	;
	; Move the string to next field
	;
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ds				; dx:bp -> moniker
	mov	bp, di
	mov	si, offset ThesNextText		; bx:si -> ThesNextText
	clr 	cx 
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	bx				; bx = chunk array block
	call	MemUnlock

	;
	; Call lookup on the new item
	;
	mov	ax, MSG_TC_LOOKUP
	pop	ds, di, si, bx			; restore object stuff
	call	ObjCallInstanceNoLock	

	;
	; Get the identifier of the first item
	;
	clr	cx				; find the first item
	mov	si, offset ThesBackupList
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	di, mask MF_CALL
	call	ObjMessage			; cx:dx -> item

	push	bx
	mov	bx, cx				; bx:si -> item
	mov	si, dx
	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER	; ax = identifier
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bx

	;
	; Select the first item
	;
	clr	dx
	mov	cx, ax				; cx = identifier
	mov	si, offset ThesBackupList	; bx:si -> ThesBackupList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage		
	ret
ThesControlBackupSelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes the block of selected text sent from the text object,
		moves it to the ReplaceText field, then formats it and 
		moves it to the NextText field.

CALLED BY:	MSG_META_CONTEXT
PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data
		bp 	= handle of global block containing the text

RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	9/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlContext	method dynamic ThesControlClass, 
					MSG_META_CONTEXT
	textBlock	local	word	\
			push	bp
	obj		local	lptr	\
			push	si
	childBlock 	local	word
	.enter

	;
	; Save the input
	;
	call	ThesControlGetChildBlock	; bx = childblock
	mov	childBlock, bx			; save childBlock

	;
	; Lock the text block
	;
	mov	bx, textBlock			; bx = handle of text block
	call	MemLock				; ax = block segment
	mov	es, ax				; es:di -> text
	mov	di, offset CD_contextData
	
	;
	; Check for no characters at all
	;
	tstdw	es:CD_numChars
	jz	freeBlock

	;
	; Filter out any unprintable characters or graphics
	;
	call	ThesControlStripNonCharacters

	;
	; Copy to ReplaceText
	;
	push	bp
	mov	bx, childBlock			; bx:si -> ThesReplaceText
	mov	si, offset ThesReplaceText	;
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	movdw	dxbp, esdi			; dx:bp -> text
	clr 	cx 				;Null-terminated
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	mov	di, offset CD_contextData	; es:di -> word(s)
	call	ThesControlFormatLookupWord	; es:di -> formatted word(s)
	
	;
	; Copy to NextText 
	;
	push 	bp
	mov	bx, childBlock			; bx:si -> ThesNextText
	mov	si, offset ThesNextText		; 
	movdw	dxbp, esdi
	clr 	cx 
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp	

freeBlock:
	mov	bx, textBlock
	call	MemFree				; free the text block

IF LOOKUP_WHEN_WORD_CHANGES

; set this constant to 0 if thesaurus should not lookup words automatically
; when the selection state changes (for instance, when machine is too slow).
; Normally should be set to 1 causing lookup whenever selected word changes.

	mov	si, obj
	mov	di, ds:[si]
	add	di, ds:[di].ThesControl_offset
	mov	ax, ds:[di].TCI_status

	;
	; Lookup only if doing no actions AND a selection exists
	;
	test	ax, mask SF_SELECTION_EXISTS
	jz	exit

	push	bp
	mov	ax, MSG_TC_LOOKUP	; lookup the word
	call	ObjCallInstanceNoLock
	pop	bp

ENDIF

exit:
 	.leave
	ret

ThesControlContext	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the word from the text object and display ourselves.

CALLED BY:	via MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= Instance
		ds:di	= Instance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 2/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlInteractionInitiate	method dynamic ThesControlClass, 
					MSG_GEN_INTERACTION_INITIATE
	;
	; Call superclass to bring up the interaction.
	;
	mov	di, offset ThesControlClass
	call	ObjCallSuperNoLock
	
	;
	; Get the selected word into our buffer...
	;
	call	ThesControlGetTextAuto
	ret
ThesControlInteractionInitiate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlGetTextAuto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Messages the text object to send us the selected text again.

CALLED BY:	ThesControlUpdateUI

PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data
		es 	= segment of ThesControlClass

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	9/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlGetTextAuto	proc	near
	class	ThesControlClass

	;
	; Send MSG_META_GET_CONTEXT (to the controlled text object)
	;
	mov	dx, size GetContextParams
	sub	sp, dx
	mov	bp, sp
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[bp].GCP_replyObj, axsi
	mov	ss:[bp].GCP_numCharsToGet, MAX_ENTRY_LENGTH-1
	mov	ss:[bp].GCP_location, CL_SELECTED_WORD
	mov	ax, MSG_META_GET_CONTEXT
	clrdw 	bxdi
	call	GenControlOutputActionStack
	add	sp, dx
	ret
ThesControlGetTextAuto	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlReplace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the selected word/phrase in the text object (or 
		the cursor) with the current NextText word, and selects that
		word as well. 

CALLED BY:	MSG_TC_REPLACE
PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data

RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlReplace	method dynamic ThesControlClass, 
					MSG_TC_REPLACE
	;
	; Create a block of memory to hold the text we will send to replace
	;
SBCS <	mov	ax, MAX_ENTRY_LENGTH			; size of the block>
DBCS <	mov	ax, MAX_ENTRY_LENGTH*(size wchar)	; size of the block>
	mov	cx, ((mask HAF_LOCK or mask HAF_NO_ERR)shl 8) \
			or mask HF_SWAPABLE
	mov	bx, handle 0
	call	MemAllocSetOwner			; bx = handle, ax = seg

	;
	; Get the NextText field to a buffer
	;
	push	bp, ds, si, bx, di, ax
	mov	dx, ax					; dx:bp -> text block
	clr	bp	
	call	ThesControlGetChildBlock		; bx=childblk
	mov	si, offset ThesNextText			; bx:si -> ThesNextText
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR		
	mov	di, mask MF_FIXUP_DS or mask MF_CALL	; set flags
	call  	ObjMessage				; cx = string length
	pop	bp, ds, si, bx, di, ax

	;
	; Copy the NextText field to the ReplaceText field
	;
	push 	bp, ds, si, bx, di, cx
	call	ThesControlGetChildBlock	; bx:si -> ThesReplaceText
	mov	si, offset ThesReplaceText
	mov	dx, ax				; dx:bp -> text
	clr	bp	
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr 	cx 
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp, ds, si, bx, di, cx

	push	cx					; save string length

	;
	; Send MSG_THES_REPLACE_SELECTED_WORDS to the controlled object
	;
	mov	ax, ds:[LMBH_handle]
	push	ax				; param RSWP_output on stack
	push	si

	mov	ax, MSG_TC_REPLACE_DONE		; param RSWP_message on stack
	push	ax

	push	bx				; param RSWP_string on stack
	clr	ax
	mov	bp, sp

	;
	; Set status word to indicate we are pasting a word, since we don't 
	; 	want to cause a lookup when the selection changes. 
	;
	or	ds:[di].TCI_status, mask SF_DOING_REPLACE \
				    or mask SF_DOING_REPLACE_AND_SELECT \
				    or mask SF_DOING_SELECT

	mov	ax, MSG_THES_REPLACE_SELECTED_WORDS
	mov 	dx, size ReplaceSelectedWordParameters
	clrdw	bxdi
	call	GenControlOutputActionStack
	add	sp, size ReplaceSelectedWordParameters

	;
	; Select the word we just pasted by sending MSG_THES_SELECT_WORD to
	; 	the controlled object
	;
	pop	cx

	mov	ax, ds:[LMBH_handle]
	push	ax				; param SWP_output on stack
	push	si

	mov	ax, MSG_TC_SELECT_DONE		; param SWP_message on stack
	push	ax

	push	cx				; param SWP_numChars

	mov	ax, 1				; param SWP_type = 1 since
	push	ax				; want to select from cursor

	mov	ax, MSG_THES_SELECT_WORD
	clrdw	bxdi
	mov	bp, sp 
	mov	dx, size SelectWordParameters
	call	GenControlOutputActionStack
	add	sp, size SelectWordParameters	; restore stack
	ret
ThesControlReplace	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlActionDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Marks the status word to indicate that an operation is 
		finished. 

CALLED BY:	MSG_THES_REPLACE_DONE, MSG_THES_SELECT_DONE, MSG_THES_COPY_DONE
PASS:		*ds:si	= ThesControlClass object
		ds:di	= ThesControlClass instance data

RETURN:		nothing
DESTROYED:	allowed to destroy: ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlActionDone		method dynamic ThesControlClass, 
					MSG_TC_COPY_DONE,
					MSG_TC_REPLACE_DONE,
					MSG_TC_SELECT_DONE
	cmp 	ax, MSG_TC_COPY_DONE
	jne	5$
5$:	cmp	ax, MSG_TC_REPLACE_DONE
	jne 	10$
	and	ds:[di].TCI_status, not (mask SF_DOING_REPLACE) 
	ret
10$:	and	ds:[di].TCI_status, not (mask SF_DOING_SELECT)
	and 	ds:[di].TCI_status, not (mask SF_DOING_REPLACE_AND_SELECT)
	ret
ThesControlActionDone	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlAddToBackupList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a new word to the backup list.

CALLED BY:	ThesControlLookup

PASS:		ds:si -> null terminated string holding word to add to list
		es:di -> ThesControlClass instance data
		bx = controller child block

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlAddToBackupList	proc	near 
				class ThesControlClass
	uses	ax,bx,cx,dx,si,di,bp,es
	instanceData	local dword
	wordString	local dword
	childBlock	local word
	arraySegment	local word
	.enter

	;
	; Save the input
	;
	movdw 	instanceData, esdi, ax 
	movdw	wordString, dssi, ax
	mov	childBlock, bx	

	;
	; Enable the backup list and create backup strings if not already
	;
	test	es:[di].TCI_status, mask SF_BACKUP_ENABLED
LONG	jz	enableBackup

continue:
	;
	; Get the backup item
	;
	movdw	esdi, instanceData, cx		; es:di -> instance data
	movdw	bxsi, es:[di].TCI_backups	; ^lds:si -> backup chunk array
	call	MemLock				; ax = segment
	mov	ds, ax
	mov	arraySegment, ax
	clr	ax				; first item
	call	ChunkArrayElementToPtr		; ds:di -> backup string elemnt
	segmov	es, ds, ax			; es:di -> backup string
	movdw	dssi, wordString, bx		; restore ds:si -> new string

	;
	; Check if the word to add is the same as the word at the top of the
	; backup list, and if so don't add it. (Can be elsewhere in the list).
	;
	mov	ax, MAX_ENTRY_LENGTH
	call	ThesControlStringLength		; cx = length new string
	mov	dx, cx				; dx = length new string
	dec 	cx				; don't compare null term
	mov	ax, MAX_ENTRY_LENGTH
SBCS <	repe	cmpsb				; compare strings	>
DBCS <	repe	cmpsw				; compare strings	>
	tst	cx
	jnz	addNew				; if matched this far, add it
	LocalGetChar	cx, dssi, NO_ADVANCE
	LocalIsNull	cx			; if matched, EOS, don't add
	jz	exit				; (else fall through, add it)

addNew:
	;
	; Insert a new element at the start of the backup list array
	;
	movdw	esdi, instanceData, bx		; es:di -> instance data
	movdw	dssi, es:[di].TCI_backups	; ^lds:si -> backup chunk array
	mov	ds, arraySegment		; ds:si -> backup chunk array
	clr	ax
	call	ChunkArrayElementToPtr		; ds:di -> first backup string
	mov	ax, dx				; ax = size of new word to add
DBCS <	shl	ax, 1				; # chars -> # bytes	>
	call	ChunkArrayInsertAt		; ds:di -> new element
	call	ChunkArrayGetCount		; cx = number of elements
	mov	bx, cx				; bx = number of last element

	;
	; Copy the new word to the new element
	;
	push	ds, si				; save ds:si -> chunk array
	segmov	es, ds, ax
	movdw	dssi, wordString, ax
	mov	cx, dx
	LocalCopyNString
	pop	ds, si				; restore ds:si->chunk array

	;
	; If too many elements, delete the last (and decrement the count bx)
	;
	cmp 	bx, MAX_BACKUP_LIST_SIZE
	jge	deleteLast
doneDeleting:
	;
	; Add the element to the displayed backup list
	;
	mov	cx, bx
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	bx, childBlock			; bx:si -> backuplist
	mov	si, offset ThesBackupList
	mov	di, mask MF_CALL
	push	bp
	call	ObjMessage
	pop	bp

	;
	; Select the new first item 
	;
	clr	cx				; first item
	mov	bx, childBlock			; bx:si -> ThesBackupList
	clr	dx
	mov	si, offset ThesBackupList		
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	push	bp
	call	ObjMessage
	pop	bp
exit: 	
	;
	; Unlock the chunk array block
	;
	movdw	dsdi, instanceData, bx
	movdw	bxsi, ds:[di].TCI_backups
	call	MemUnlock

	.leave
	ret

enableBackup:
	or	es:[di].TCI_status, mask SF_BACKUP_ENABLED	
	tst	es:[di].TCI_backups.segment
	jnz	50$
	mov	bx, childBlock
	call	ThesControlCreateBackupStrings
50$:
	mov	si, offset ThesBackupList
	mov	dx, VUM_NOW
	mov	ax, MSG_GEN_SET_ENABLED
	mov	di, mask MF_CALL
	push	bp
	call	ObjMessage
	pop	bp
	jmp	continue

deleteLast:
	mov	ax, bx
	dec	ax			; ax = last element number
	mov	cx, 1
	call	ChunkArrayDeleteRange	
	dec	bx
	jmp 	doneDeleting
ThesControlAddToBackupList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlAddMeanings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the meaning list to the correct number of new
		meanings - the list will then send messages asking for the
		new monikers, which is handled by ThesControlGetMeaningMoniker

CALLED BY:	ThesControlLookup

PASS:		bx = controller UI block
		cx = number of meanings
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlAddMeanings	proc	near
	uses	ax,cx,dx,bp
	.enter

	;
	; Initialize the gendynamiclist to the number of meanings
	;
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	si, offset ThesMeaningList
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
ThesControlAddMeanings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlGetChildBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets a controller's child block handle

CALLED BY:	(internal) various
PASS:		*ds:si  = controller object 
RETURN:		bx = controller childBlock handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlGetChildBlock	proc	near
	push	ax
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	bx, ds:[bx].TGCI_childBlock
	pop	ax
	ret
ThesControlGetChildBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlGetStringToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a word token from a string. The delimiter is
		either a space or a punctuation.  	

CALLED BY:	ThesControlFormatLookupWord.
PASS:		es:di = Address of string to get the token.
		cx = the length of string.
RETURN:		cx = the new length of string after a first token is found.
		di = the offset of string at the first delimiter.
		bx = 0 space delimiter encountered.
		bx = 1 punctuation delimiter encountered.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CuongLe	6/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlGetStringToken	proc	near
	.enter

	clr 	ah
	clr	bx
	jcxz	exitLoop
continueLoop:
	LocalGetChar ax, esdi, noAdvance
	call	LocalIsSpace			; scan for space; cx = rem len
	jnz	exitLoop			; it's a space	
	call	LocalIsPunctuation
	jnz	punctuationFound		; it's a punctuation
	LocalNextChar esdi
	dec	cx
	jcxz	exitLoop
	jmp	continueLoop

punctuationFound:
	inc	bx
exitLoop:

	.leave
	ret
ThesControlGetStringToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlFormatLookupWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes leading and trailing spaces and punctuation, cuts off 
		extra words beyond the maximum of two, returns new pointer into
		given buffer and null terminates after two (or one) words if 
		buffer contains more than one word. Also indicates whether 
		one or two words are returned. Additionally: removes
		"non-printable" characters (anything less than C_SPACE). 

CALLED BY:	ThesControlLookup

PASS:		es:di -> null terminated string
		
RETURN:		es:di -> first nonspace or null in string
		ax = 0 if one (or none) words, ax = 1 if two words. 

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Remove any leading or trailing spaces or punctuation
	Get positions of null, 1st space, 2nd space.
	
	If null before first space,
		then one word, return as is (null term after 1 word)
	Else if first space followed by null or another space,
		then one word, replace the first space with a null and return
	Else if second space before null, 
		then two words, null the second space and return
	Else (null terminated after second word) two words, return as is.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	9/28/92		Initial version
	Don	6/22/95		Fix to prevent writing beyond end of buffer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlFormatLookupWord	proc	near
	uses	bx,cx,dx,si,bp

	nonSpaceMaxLength	local 	word
	inBufferOffset		local	word		
	outBufferOffset		local 	word
	nullPos			local	word
	space1Pos		local	word
	space2Pos		local	word

	.enter

	;
	; First strip out any non-printable characters
	;
	call	ThesControlStripNonCharacters

	;
	; Save es:di -> original string
	;
	mov	inBufferOffset, di

	;
	; Determine length of the string, so that we won't modify
	; some data beyond the end of the passed buffer -Don 6/22/95
	;
	LocalStrLength			; string length => CX
	mov	di, inBufferOffset

	;
	; Remove leading whitespace (note that this is really wrong,
	; but it will have to be fixed at a later time -Don 6/22/95)
	;
	LocalLoadChar	ax, C_SPACE
SBCS <	repe	scasb			; scan until non-space char found>
DBCS <	repe	scasw			; scan until non-space char found>
	LocalPrevChar	esdi
	inc	cx

	LocalGetChar	ax, esdi, NO_ADVANCE
	LocalIsNull	ax
LONG	jz	emptyWord		; if first non-space null, string empty
	tst	cx
LONG	jz	emptyWord		; if all spaces, string is empty

	mov	outBufferOffset, di	; else set pointer to start of 1st word
	mov	nonSpaceMaxLength, cx
	
	;
	; Calculate nullPos, space1Pos, space2Pos
	;
	LocalClrChar	ax
	LocalFindChar				; scan to first null char
	neg	cx				; cx = - rem chars after null
	add	cx, nonSpaceMaxLength		; bx = position of first null
	mov	nullPos, cx

	mov	di, outBufferOffset		; es:di -> first nonSpace
	mov	cx, nonSpaceMaxLength		; cx = remaining chars in strng

	call	ThesControlGetStringToken
	tst	bx				
	jnz	getOneWord			; punctuation is found

	mov	bx, cx 
	neg	bx	
	add	bx, nonSpaceMaxLength		; bx = pos first space in strng
	mov	space1Pos, bx
	LocalNextChar esdi
	call	ThesControlGetStringToken
	neg	cx				; cx= -rem chars past 2nd space
	add	cx, nonSpaceMaxLength		; bx = pos of 2nd space in strg
	mov	space2Pos, cx

	;
	; Figure out what part of the string to return (see algorithm in headr)
	;
	mov	ax, nullPos
	mov	bx, space1Pos
	cmp	ax, bx
	jle	oneWord				; if nul before space do oneWrd

	sub	ax, bx
	cmp	ax, 1
	je	nullFirstSpace			; null after 1st, so null space

	mov	bx, space1Pos
	mov	cx, space2Pos
	sub	cx, bx
	cmp	cx, 1
	je 	nullFirstSpace			; 2nd space follows 1st,nul 1st

	mov	ax, nullPos
	mov	cx, space2Pos
	cmp	ax, bx
	jg	nullSecondSpace			; if null before 2nd, null 2nd
	
	mov	di, outBufferOffset		; return two words nulled as is
	mov	ax, 1
	jmp 	exit	

nullFirstSpace:
	mov	di, outBufferOffset
	mov	si, di				; save outBufferOffset
	mov	cx, nonSpaceMaxLength
	LocalLoadChar	ax, C_SPACE
	LocalFindChar 				; scan for first space
	LocalPrevChar	esdi			; backup to space character
	LocalClrChar	ax
	LocalPutChar	esdi, ax, NO_ADVANCE	; replace space with null
	mov	di, si 				; di = outBufferOffset
	clr	ax
	jmp 	exit

nullSecondSpace:
	mov	di, outBufferOffset		
	mov	si, di				; save outBufferOffset
	mov	cx, nonSpaceMaxLength
	LocalLoadChar	ax, C_SPACE
	LocalFindChar
	LocalFindChar
	LocalPrevChar	esdi
	LocalClrChar	ax
	LocalPutChar	esdi, ax, NO_ADVANCE	; replace space with null
	mov	di, si				; di = outBufferOffset
	mov	ax, 1
exit:
	call	ThesControlStripPunctuation	; es:di -> string past punct
	.leave
	ret

getOneWord:
	clr	al				; null terminate to
	mov	es:[di], al			; get the first word
						; when punctuation is found.
oneWord:
	mov 	di, outBufferOffset
	clr	ax
	jmp 	exit
emptyWord:
	mov	di, inBufferOffset		; just return everything as was
	clr	ax				; and ax = 0 => no words
	jmp	exit
ThesControlFormatLookupWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlStripPunctuation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes extraneous punctuation marks from the beginning and end
		of the lookup string.

CALLED BY:	ThesControlFormatLookupWord	
PASS:		es:di -> string
RETURN:		es:di -> string past leading punctuation
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Just increment di until past all punctuations, 
		then set di to end of string and decrement past
		all punctuations (nulling along the way).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlStripPunctuation	proc	near
	uses	ax,bx,cx,dx,si,es,ds
	.enter

	;
	; Set dx = offset first char, bx = offset last char
	;
	mov	dx, di				; dx = position of first char
	segmov	ds, es, cx			; ds:si -> string
	mov	si, di
	mov	ax, MAX_ENTRY_LENGTH
	call	ThesControlStringLength		; cx = length of the string
	sub	cx, 2				; don't count null, start at 0
DBCS <	shl	cx, 1				; # chars -> # bytes	>
	add	cx, di
	mov	bx, cx				; bx = position of last char

	;
	; Move past all punctuation at the start of the string
	;
SBCS <	clr	ah							>
	mov	di, dx				; es:di -> start of string
frontLoop:
	LocalGetChar	ax, esdi, NO_ADVANCE	; cl = character in string
	LocalIsNull	ax
	jz	exitFrontLoop			; if end of string, exit front
	call	LocalIsPunctuation
	jz	exitFrontLoop			; if not punct char, exit front
	LocalNextChar 	esdi			; move to next char in string
	jmp 	frontLoop
exitFrontLoop:
	mov	dx, di				; es:dx -> new start of string

	;
	; Move back through any punctuation at the end of the string
	;
	mov	di, bx				; es:di -> last char in string
rearLoop:
	LocalGetChar	ax, esdi, NO_ADVANCE	; ax = character in string
	cmp	di, dx				
	je	exitRearLoop			; if last char=first char,exit
	call	LocalIsPunctuation
	jz 	exitRearLoop			; if not a punct char, exit
	LocalClrChar	cx
	LocalPutChar	esdi, cx, NO_ADVANCE	; null the punct char
	LocalPrevChar	esdi			; move to previous char in strg
	jmp 	rearLoop
exitRearLoop:

	mov	di, dx				; es:di -> new start of string
	.leave
	ret
ThesControlStripPunctuation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlStripNonCharacters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes all non-characters from the string

CALLED BY:	ThesControlFormatLookupWord
PASS:		es:di -> string
RETURN:		es:di -> unchanged, string without unprintable characters
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlStripNonCharacters	proc	near
	uses	ax,bx,cx,di,si,ds
	.enter

	segmov	ds, es, si
	mov	si, di
	mov	ax, MAX_ENTRY_LENGTH
	call	ThesControlStringLength		; cx = string length
	dec	cx				; don't include the null
	tst	cx				; if null string, exit
	jz	exit

SBCS <	clr	ah							>
stripLoop:
	LocalGetChar	ax, esdi, NO_ADVANCE	; ax = char to test
	call	LocalIsPrintable		; is it printable
	jz	removeChar			; if not, remove it
	LocalNextChar	esdi			; else go to next char
	loop	stripLoop

exit:
	.leave
	ret

removeChar:
	mov	si, di			; ds:si -> char to remove
	LocalNextChar	dssi		; ds:si -> one past char to rem
	mov	ax, cx			; ax = loop control var (str len)
	mov	bx, di			; save es:bx -> next char to scan 
	LocalCopyNString
	mov	cx, ax			; restore loop control var (str len)
	mov	di, bx			; es:di -> next char to scan
SBCS <	clr	ah							>
	loop stripLoop
	jmp 	exit
ThesControlStripNonCharacters	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlAddWordToMeaningMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the "moniker" text of the meaninglist to be 
		"Meanings for: <passed word>"

CALLED BY:	ThesControlLookup
PASS:		ax:dx -> word string 
		bx -> ThesControlClass childblock
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlAddWordToMeaningMoniker	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, axdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

if not DEFINITIONLESS_THESAURUS	
	;
	; Copy the word to ThesMeaningMonikerText1
	;
	mov	bp, dx 				; dx:bp -> word
	mov	dx, ax
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	si, offset ThesMeaningMonikerText1  ; bx:si -> text to replace
	mov	di, mask MF_CALL
	call	ObjMessage
endif
	.leave
	ret
ThesControlAddWordToMeaningMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlCreateBackupStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the backup strings chunk array and saves its location

CALLED BY:	ThesControlUpdateUI
PASS:		es:di -> controller instance data
		bx = childBlock
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	10/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlCreateBackupStrings	proc	near
				class	ThesControlClass
	uses	ax,bx,cx,dx,si
	childBlock	local	word	push bx
	.enter

	push 	es, di
	
	;
	; Create a block of memory for the backup list chunk array
	;
	mov	ax, MAX_MEANINGS_ARRAY_SIZE * 2
	mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK)shl 8) \
			or mask HF_SWAPABLE
	mov	bx, handle 0
	call	MemAllocSetOwner	; bx=block,ax=seg,cx destroyed
	jc	noMemoryError
	push	bx			; save block

	;
	; Create an lmem heap in the block
	;
	mov	ds, ax			; ds = block segment
	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, MAX_DEFINITIONS
	mov	dx, size LMemBlockHeader
	mov	si, MAX_MEANINGS_ARRAY_SIZE
	clr	di
	call	LMemInitHeap		; ds = block segment (may change) 

	;
	; Create the chunk array
	;
	clr	bx			; var sized elements
	clr	ax, cx, si
	call	ChunkArrayCreate 	; *ds:si = chunk array

	;
	; Save the backup list location
	;
	pop	bx			; bx = chunk array block
	pop	es, di
	movdw	es:[di].TCI_backups, bxsi, ax

	call 	MemUnlock		; unlock the block

exit:
	.leave
	ret

noMemoryError:
	mov	ax, offset NoMemoryString
	mov	bx, childBlock
	call	ThesControlDisable
	jmp	exit
ThesControlCreateBackupStrings	endp

ThesStrings	segment	lmem	LMEM_TYPE_GENERAL
LocalDefString NoMemoryString	<'Out of memory',0>
ThesStrings	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlFitStringWithEllipses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shortens the string to fit within the meaning moniker and 
		adds ellipses (if the string is too long). 

CALLED BY:	ThesControlGetMeaningMoniker (LOCAL)
PASS:		es:di -> string buffer
		dx = grammar class
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Check if the string is too long to fit in moniker. If so, 
		Then find the end of the last word that fits (with space for
		the ellipses at the end...) and add the ellipses and null
		terminate the string after the ellipses. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	12/ 2/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlFitStringWithEllipses	proc	near
	uses	ax,cx,dx,si,di,ds
	grammarStringSize	local	word
	maxStringSize		local 	word
	.enter

	;
	; Get the size of the grammar string
	;	
	cmp	dx, 0
	jne	notAdj
	mov	grammarStringSize, 6
	jmp	grammarSizeDone
notAdj:	
	cmp	dx, 1
	jne	notNoun
	mov	grammarStringSize, 4
	jmp	grammarSizeDone
notNoun:
	cmp	dx, 2
	jne	notAdverb
	mov	grammarStringSize, 6
	jmp	grammarSizeDone
notAdverb:
	mov	grammarStringSize, 4
grammarSizeDone:

	;
	; Get the size of the string
	;
	segmov	ds, es, ax
	mov	si, di
	mov	ax, MAX_DEFINITION_SIZE
	call	ThesControlStringLength		; cx = length

	;
	; Get the size of the maximum string that will fit
	;
	mov	maxStringSize, MAX_ENTRY_LENGTH+5 ; this value must match the
						  ; width of the two boxes, 
						  ; ThesMeaningList and 
						  ; ThesDefinitionText
	mov	dx, grammarStringSize
	sub	maxStringSize, dx

	;
	; If the string will fit as it is, exit now.
	;
	cmp	cx, maxStringSize
	jl	exit

	;
	; Set maxStringSize to include three periods (the ellipses)
	;
	mov	dx, 3
	sub	maxStringSize, dx

	;
	; The string is too long. Search backwards from the last place we can
	; break the word (and fit the ellipses) and find the first delimiter.
	;	
	mov	si, di
	add	di, maxStringSize
DBCS <	add	di, maxStringSize	; # chars -> # bytes		>
SBCS <	clr	ah							>
searchLoop:
	LocalGetChar	ax, esdi, NO_ADVANCE	; al = current character
	call	LocalIsSpace
	jnz	endLoop			; If it's a space, break here.
	call	LocalIsPunctuation
	jnz	endLoop			; If it's punctuation, break here.
	LocalPrevChar	esdi		; Else move to previous character
	cmp	di, si	
	jle	exit			; If we're at the string start, cancel
	jmp	searchLoop		; Loop again
endLoop:
	;
	; If the characters before the current space/punctuation character
	; 	are also space/punctuation, move backwards past them too
	;

finishLoop:
	clr	cx
	LocalPrevChar	esdi
	cmp	di, si			
	jle 	exit			; if we're at string start, cancel
	LocalGetChar	ax, esdi, NO_ADVANCE	; al = current character
	call	LocalIsPunctuation
	jz	notPunctuation	
	inc	cx			; if punctuation, mark it in cx
notPunctuation:
	call	LocalIsSpace		
	jz	notSpace
	inc	cx			; if space, mark it in cx
notSpace:
	jcxz	breakWord		; if was a space or punctuation, loop
	jmp	finishLoop		; 	again, otherwise we're done

breakWord:
	LocalNextChar 	esdi		; back to break point
	;
	; We're at the point we want to break. Just copy three periods (the
	;	ellipses) and null terminate.
	;
	LocalLoadChar	ax, C_PERIOD
	LocalPutChar	esdi, ax
	LocalPutChar	esdi, ax
	LocalPutChar	esdi, ax
	LocalClrChar	ax
	LocalPutChar	esdi, ax	; null terminator

exit:
	.leave
	ret
ThesControlFitStringWithEllipses	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes a null-terminated string and returns its length
		(length includes the null character).

CALLED BY:	various local routines
PASS:		ds:si => the string
		ax = maximum string length
RETURN:		cx = length of string (includes the null term)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	7/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlStringLength	proc	near
	uses	ax, bx, di, es
	.enter
	;
	; Search through the string until the null character is reached 
	;
	mov	bx, ax
	mov	di, si			; set es:di -> string
	segmov	es, ds, cx
	mov	cx, bx			; cx = maximum string length
	clr 	ax			; search for 0 = null character
	LocalFindChar			; cx = max length - string length
	sub	cx, bx			; cx = - string length
	neg	cx			; cx = string length

	.leave
	ret
ThesControlStringLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesControlDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables the entire thesaurus and posts an error message

CALLED BY:	LOCAL
PASS:		cs:ax = null terminated error string (in code segment)
		bx    = childBlock
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/24/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesControlDisable	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	push	ax
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	clr 	dx
	mov	dl, VUM_NOW			; for MSG_GEN_SET_USABLE 
	mov	di, offset ThesUsableList	; si:di -> list of items
	mov	si, cs
	call	SendMessageToItemsInList
	pop	ax

	;
	; Report an error message by copying the error message to Def Text
	;
	mov	si, offset ThesDefinitionText	; bx:si -> DefinitionText
	mov	bp, ax
	call	ThesStringSet

	.leave
	ret
ThesControlDisable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesStringSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set ThesString string in given text object

CALLED BY:	LOCAL
PASS:		bp = chunk handle of string in ThesString resource
		^lbx:si = text object
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesStringSet	proc	near
	uses	ds
	.enter
	push	bx
	mov	bx, handle ThesStrings
	call	MemLock
	mov	ds, ax
	mov	bp, ds:[bp]
	mov	dx, ax				; dx:bp = string
	pop	bx				; ^lbx:si = text object
	clr	cx				; null-terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	push	bx
	mov	bx, handle ThesStrings
	call	MemUnlock
	pop	bx
	.leave
	ret
ThesStringSet	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMessageToItemsInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Passes a method to all the objects in the passed table.

CALLED BY:	global
PASS:		si:di <- far ptr to null-terminated list of chunk handles
		bx - handle of block containing objects
		ax -method to send
		cx, dx, bp - data

RETURN:		nada
DESTROYED:	si, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendMessageToItemsInList	proc	near	
	uses	es
	.enter
	mov	es, si
10$:
	mov	si, es:[di]			;*ds:si <- next object in list
	tst	si				;If at end of list, exit
	jz	exit
	push	ax, cx, dx, bp, di
	clr	di
	call	ObjMessage
	pop	ax, cx, dx, bp, di
	add	di, 2
	jmp	10$
exit:
	.leave
	ret
SendMessageToItemsInList	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThesaurusControlScanFeatureHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This nukes all features if the system is not pen based.

CALLED BY:	GLOBAL
PASS:		cx - GenControlUIType
		dx:bp - ptr to GenControlScanInfo struct to fill in
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThesaurusControlScanFeatureHints	method	ThesControlClass, 
				MSG_GEN_CONTROL_SCAN_FEATURE_HINTS
	.enter
	push	cx, dx, bp
	mov	di, offset ThesControlClass
	call	ObjCallSuperNoLock
	pop	cx, es, di

	call	ThesaurusCheckAvailable
	tst	cx
	jnz	exit

;	We don't have a thesuarus file,

	mov	es:[di].GCSI_appProhibited, mask ThesDictFeatures
	cmp	cx, GCUIT_TOOLBOX
	jz	exit
	mov	es:[di].GCSI_appProhibited, mask ThesDictToolboxFeatures
exit:
	.leave
	ret
ThesaurusControlScanFeatureHints	endp

TextControlCode ends


