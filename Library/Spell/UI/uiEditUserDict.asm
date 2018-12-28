COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Spell
MODULE:		UI
FILE:		uiEditUserDict.asm

AUTHOR:		Andrew Wilson, Sep 27, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/27/92		Initial revision

DESCRIPTION:
	Contains code for the EditUserDict controller.	

	$Id: uiEditUserDict.asm,v 1.1 97/04/07 11:08:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellClassStructures	segment	resource
	EditUserDictionaryControlClass
SpellClassStructures	ends

SpellControlCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	EditUserDictionaryControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for EditUserDictionaryControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of EditUserDictionaryControlClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
EditUserDictionaryControlGetInfo	method dynamic	EditUserDictionaryControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset EUDC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep	movsb
	ret
EditUserDictionaryControlGetInfo	endm

EUDC_dupInfo	GenControlBuildInfo	<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST,
	offset EUDC_IniFileKey,		; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	EditUserDictionaryName,		; GCBI_controllerName

	handle EditUserDictControlUI,	; GCBI_dupBlock
	offset EUDC_childList,		; GCBI_childList
	length EUDC_childList,		; GCBI_childCount
	offset EUDC_featuresList,	; GCBI_featuresList
	length EUDC_featuresList,	; GCBI_featuresCount
	EUDC_DEFAULT_FEATURES,		; GCBI_features

	handle SpellControlToolboxUI,	; GCBI_toolBlock
	offset EUDC_toolList,		; GCBI_toolList
	length EUDC_toolList,		; GCBI_toolCount
	offset EUDC_toolFeaturesList,	; GCBI_toolFeaturesList
	length EUDC_toolFeaturesList,	; GCBI_toolFeaturesCount
	EUDC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	EUDC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
SpellControlInfoXIP	segment	resource
endif
EUDC_helpContext	char	"dbEditDict", 0


EUDC_IniFileKey	char	"editUserDictionary", 0

;---

EUDC_childList	GenControlChildInfo	\
	<offset EditDictionaryGroup, mask EUDF_EDIT_USER_DICTIONARY, mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

EUDC_featuresList	GenControlFeaturesInfo	\
	<offset EditDictionaryGroup, EditUserDictionaryName, 0>

EUDC_toolList		GenControlChildInfo \
	<offset EditUserDictToolTrigger, mask EUDTF_EDIT_USER_DICTIONARY, mask GCCF_IS_DIRECTLY_A_FEATURE>

EUDC_toolFeaturesList	GenControlFeaturesInfo \
	<offset EditUserDictToolTrigger, SpellName, 0>

if FULL_EXECUTE_IN_PLACE
SpellControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWordFromUserDictionaryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine returns the requested word from the user
		dictionary list

CALLED BY:	GLOBAL
PASS:		bx - block containing user dictionary list
		es:di <- ptr to where to put block
		ax - index of entry to get 
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetWordFromUserDictionaryList	proc	near	uses	ax, bx, cx, dx, bp, di, ds, si
	.enter
	push	es, di
	xchg	dx, ax
	call	MemLock
	mov	es, ax
EC <	cmp	dx, es:[UDLI_numEntries]				>
EC <	ERROR_AE	-1						>
	clr	al
	mov	di, es:[UDLI_lastFoundPtr]	;DI <- last word returned
	mov	cx, es:[UDLI_lastFoundIndex]	;CX <- index of last word 
	mov	es:[UDLI_lastFoundIndex], dx	;
	sub	dx, cx				;DX <- # words to skip
						; forward or backward
	jz	exit				;If no words to skip, branch
	jns	skipForward			;If pos # words, branch forward

	mov	cx, di
	sub	cx, size UserDictionaryListInfo	;CX <- # chars to scan
	sub	di,2				;ES:DI <- ptr before null 
						; term of the previous string

;	SKIP BACKWARD 0-DX WORDS

	std
skipBackward:
	clr	al
	repne	scasb
			;ES:DI <- ptr before null byte
	inc	dx
	jnz	skipBackward
	cld
	add	di, 2	;Skip forward past null byte to point to word	
EC <	cmp	di, size UserDictionaryListInfo				>
EC <	ERROR_B	-1							>
	jmp	exit

skipForward:
	mov	cx, -1

;	SKIP FORWARD DX WORDS

skipForwardLoop:
	repne	scasb
	dec	dx
	jnz	skipForwardLoop
exit:
;
;	ES:DI <- ptr to string we wanted to index
;
	mov	es:[UDLI_lastFoundPtr], di	;Save ptr to string
	segmov	ds, es
	mov	si, di

;	GET SIZE OF INDEXED STRING

	clr	al
	mov	cx, -1
	repne	scasb
	not	cx
	pop	es, di				;Restore ptr to dest

;	COPY STRING TO DESTINATION

if DBCS_PCGEOS
	clr	ah
80$:
	lodsb
	stosw
	loop	80$
else
	rep	movsb
endif
	call	MemUnlock
	.leave
	ret
GetWordFromUserDictionaryList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlRequestAlternate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the method sent from the alternate spelling dynamic
		list when it wants a moniker.

CALLED BY:	GLOBAL
PASS:		cx:dx <- list to send reply to
		bp - index of alternate requested
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlRequestAlternate	method	EditUserDictionaryControlClass,
				MSG_EUDC_GET_USER_DICTIONARY_LIST_MONIKER

SBCS <altString	local	SPELL_MAX_WORD_LENGTH	dup (char)		>
DBCS <altString	local	SPELL_MAX_WORD_LENGTH	dup (wchar)		>

	mov	ax, bp		;AX <- entry # to return
	.enter

	push	cx, dx			; OD of dynamic list
	mov	di, ds:[si]
	add	di, ds:[di].EditUserDictionaryControl_offset
	mov	bx, ds:[di].EUDCI_userDictList
	segmov	es, ss
	lea	di, altString
	call	GetWordFromUserDictionaryList	

	pop	bx, si			;dynamic list od

	push	bp
	mov_tr	bp, ax
	mov	cx, es
	mov	dx, di
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	.leave
	ret
EditUserDictionaryControlRequestAlternate	endp

ObjMessageFixupDS	proc	near
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
ObjMessageFixupDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeEditBuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine frees up the edit buffer if one exists.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeEditBuff	proc	near	uses	si
	class	EditUserDictionaryControlClass
	.enter
	mov	si, ds:[si]
	add	si, ds:[si].EditUserDictionaryControl_offset
	clr	bx
	xchg	bx, ds:[si].EUDCI_userDictList
	tst	bx
	jz	exit
	call	MemFree				;Free up the edit box info.
exit:
	.leave
	ret
FreeEditBuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up extra data.

CALLED BY:	GLOBAL

PASS:		*ds:si - object

RETURN:		nada

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlDetach	method	EditUserDictionaryControlClass,
					MSG_META_DETACH,
					MSG_GEN_CONTROL_DESTROY_UI
	.enter
	mov	di, offset EditUserDictionaryControlClass
	call	ObjCallSuperNoLock

	call	FreeEditBuff

	mov	di, ds:[si]
	add	di, ds:[di].EditUserDictionaryControl_offset
	clr	bx
	xchg	bx, ds:[di].EUDCI_icBuff
	tst	bx
	jz	exit

	call	ICUpdateUser
	call	ICExit
exit:
	.leave
	ret
EditUserDictionaryControlDetach	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlAddToGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the controller to the GCNSLT_DICTIONARY GCN list so it
		will know if/when the user dictionary is changed.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlAddToGCNLists	method EditUserDictionaryControlClass,
					MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
	.enter
	mov	di, offset EditUserDictionaryControlClass
	call	ObjCallSuperNoLock
	
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_DICTIONARY
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GCNListAdd

	.leave
	ret
EditUserDictionaryControlAddToGCNLists	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlRemoveFromGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the controller from the GCNSLT_DICTIONARY GCN list 
		(see EditUserDictionaryControlAddToGCNLists).

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlRemoveFromGCNLists	method EditUserDictionaryControlClass,
					MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
	.enter
	mov	di, offset EditUserDictionaryControlClass
	call	ObjCallSuperNoLock
	
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_DICTIONARY
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GCNListRemove

	.leave
	ret
EditUserDictionaryControlRemoveFromGCNLists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlUpdateSelectedWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has clicked on one of the words in the user
		dictionary. Replace the text in the text object with
		this text.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlUpdateSelectedWord	method	dynamic EditUserDictionaryControlClass,
				MSG_EUDC_UPDATE_SELECTED_WORD
SBCS <altString	local	SPELL_MAX_WORD_LENGTH	dup (char)		>
DBCS <altString	local	SPELL_MAX_WORD_LENGTH	dup (wchar)		>
bufHandle	local	hptr

	.enter

	push	bp			;Save ptr to locals
	mov	bx, ds:[di].EUDCI_userDictList
	tst	bx
	LONG jz	disableExit
	mov	bufHandle, bx

;	FIND OUT WHICH ELEMENT IS SELECTED

	call	GetFeaturesAndChildBlock
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset EditDictionaryList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	ax, GIGS_NONE
	je	disableExit

;	GET THE SUGGESTED WORD IN "altString"

	pop	bp

	push	bx
	segmov	es, ss
	lea	di, altString		;ES:DI <- dest to store data
	mov	bx, bufHandle		;
	call	GetWordFromUserDictionaryList
	pop	bx


;	SET THE TEXT IN THE NEW WORD AREA

	push	bp
	mov	si, offset EditDictionaryNewWord
	mov	dx, ss			;DX:BP <- ptr to string
	lea	bp, altString
	clr	cx

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_VIS_TEXT_SELECT_ALL	;Select all the replacement
						; text so the user can type
						; over it easily.
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

;	DISABLE THE "ADD NEW WORD" TRIGGER

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	mov	si, offset EditDictionaryAddWordTrigger
	call	ObjMessageFixupDS

	mov	ax, MSG_GEN_SET_ENABLED
	mov	si, offset EditDictionaryDeleteSelectedWordTrigger
	call	ObjMessageFixupDS
exit:
	pop	bp
	.leave	
	ret
disableExit:

	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	si, offset EditDictionaryNewWord
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	tst	ax
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	90$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
90$:
	mov	dl, VUM_NOW
	mov	si, offset EditDictionaryAddWordTrigger
	call	ObjMessageFixupDS

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	si, offset EditDictionaryDeleteSelectedWordTrigger
	call	ObjMessageFixupDS
	jmp	exit
EditUserDictionaryControlUpdateSelectedWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetUserDictList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine resets the user dictionary list

CALLED BY:	GLOBAL

PASS:		*ds:si - object

RETURN:		nada

DESTROYED:	bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetUserDictList	proc	near	uses	es, si, ax
	class	EditUserDictionaryControlClass
	.enter
	call	GetFeaturesAndChildBlock	;If no children, just exit
	tst	bx
	jz	exit
	clr	cx
	mov	di, ds:[si]
	add	di, ds:[di].EditUserDictionaryControl_offset
EC <	tst	ds:[di].EUDCI_userDictList				>
EC <	ERROR_NZ	-1						>

	mov	bx, ds:[di].EUDCI_icBuff
	tst	bx
	jz	10$
	call	ICBuildUserList
	tst	bx
	jz	10$
	mov	ds:[di].EUDCI_userDictList, bx

	call	MemLock
	mov	es, ax
	mov	cx, es:[UDLI_numEntries]
	call	MemUnlock
10$:

;	Set the # items in the list

	call	GetFeaturesAndChildBlock
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	si, offset EditDictionaryList
	call	ObjMessageFixupDS

;	Select the first item, or none.

	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	jcxz	common
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
common:
	clr	dx
	clr	cx
	call	ObjMessageFixupDS

	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	ObjMessageFixupDS
exit:
	.leave
	ret
ResetUserDictList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler inits the user dictionary edit box and
		brings it up.

CALLED BY:	GLOBAL
PASS:		ds - idata
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlGenerateUI	method	dynamic EditUserDictionaryControlClass,
				MSG_GEN_CONTROL_GENERATE_UI
	mov	di, offset EditUserDictionaryControlClass
	call	ObjCallSuperNoLock

	call	GetFeaturesAndChildBlock
	test	ax, mask EUDF_EDIT_USER_DICTIONARY
	jz	exit

	call	EditGetICBuff
	tst	bx
	jz	errorExit

	mov	di, ds:[si]
	add	di, ds:[di].EditUserDictionaryControl_offset
	tst	ds:[di].EUDCI_userDictList
	jnz	10$
	call	ResetUserDictList
10$:
	call	GetFeaturesAndChildBlock

	mov	ax, MSG_VIS_TEXT_SELECT_ALL	;Select all the replacement
						; text so the user can type
						; over it easily.
	mov	si, offset EditDictionaryNewWord
	call	ObjMessageFixupDS
exit:
	ret
errorExit:
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	ObjMessage
EditUserDictionaryControlGenerateUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the box comes up, this routine ensures that we
		have an ICBuff first, otherwise the box won't come up.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryInitiate	method	EditUserDictionaryControlClass,
				MSG_GEN_INTERACTION_INITIATE
	.enter
	call	EditGetICBuff
	tst	bx		
	jz	exit		; if bx = 0 -> error, so exit.
	mov	di, ds:[si]
	add	di, ds:[di].EditUserDictionaryControl_offset
if CONSISTENT_USER_DICT
	clr	bx
	xchg	bx, ds:[di].EUDCI_userDictList
	tst	bx
	jz	noFree
	call	MemFree
noFree:
	call	ResetUserDictList
else
	tst	ds:[di].EUDCI_userDictList				
	jnz	callSuper
	call	ResetUserDictList
callSuper:
endif
	mov	di, offset EditUserDictionaryControlClass
	call	ObjCallSuperNoLock
exit:
	.leave
	ret
EditUserDictionaryInitiate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendChangeNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine sends a change notification to the flow object
		that tells all instances of the EditControl that the user 
		dictionary has changed.

CALLED BY:	GLOBAL
PASS:		ds - lmem block containing object
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendChangeNotification	proc	near	uses	ax, bx, cx, dx, bp, di, si
	.enter
	mov	ax, MSG_NOTIFY_USER_DICT_CHANGE	; ax = message to send
	mov	dx, ds:[LMBH_handle]
	clr	bp
	clr	di				; no special send flags
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	si, GCNSLT_DICTIONARY
	call	GCNListRecordAndSend
	.leave
	ret
SendChangeNotification	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlDeleteSelectedWordFromUserDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the selected word from the user dictionary and updates
		the display of words.

CALLED BY:	GLOBAL
PASS:		ds - idata
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlDeleteSelectedWordFromUserDictionary	method	dynamic EditUserDictionaryControlClass,
		MSG_EUDC_DELETE_SELECTED_WORD_FROM_USER_DICTIONARY
SBCS <	altString	local	SPELL_MAX_WORD_LENGTH	dup (char)	>
DBCS <	altString	local	SPELL_MAX_WORD_LENGTH	dup (wchar)	>
	selectedItem	local	word
	.enter
EC <	tst	ds:[di].EUDCI_userDictList				>
EC <	ERROR_Z	-1							>
EC <	tst	ds:[di].EUDCI_icBuff					>
EC <	ERROR_Z	-1							>

;	FIND OUT WHICH ITEM IS SELECTED

	call	GetFeaturesAndChildBlock
	push	si, bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset EditDictionaryList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, bp
	cmp	ax, GIGS_NONE			;Exit if no item is selected.
	jz	disableExit

;	GET WORD TO DELETE


	mov	selectedItem, ax
	mov	bx, ds:[si]
	add	bx, ds:[bx].EditUserDictionaryControl_offset
	mov	bx, ds:[bx].EUDCI_userDictList
	segmov	es, ss			;ES:DI <- ptr to stack space to store
	lea	di, altString		; string.
	call	GetWordFromUserDictionaryList

;	DELETE THE WORD FROM THE USER DICTIONARY

	mov	bx, ds:[si]
	add	bx, ds:[bx].EditUserDictionaryControl_offset
	mov	bx, ds:[bx].EUDCI_icBuff

	push	ds, si
	segmov	ds, ss
	lea	si, altString			;DS:SI <- ptr to string
	call	ICDeleteUser
if CONSISTENT_USER_DICT
	cmp	ax, IC_RET_OK
	jne	noUpdate
	call	ICUpdateUser
noUpdate:
endif
	pop	ds, si

	cmp	ax, IC_RET_OK
	jne	errorDelete

	call	SendChangeNotification

;	RE-BUILD THE LIST OF ITEMS

	mov	di, ds:[si]
	add	di, ds:[di].EditUserDictionaryControl_offset
	clr	bx
	xchg	bx, ds:[di].EUDCI_userDictList
EC <	tst	bx							>
EC <	ERROR_Z	-1							>
	call	MemFree
	mov	bx, ds:[di].EUDCI_icBuff
	call	ICBuildUserList
	mov	ds:[di].EUDCI_userDictList, bx

	call	GetFeaturesAndChildBlock

;	DELETE THE ITEM FROM THE LIST, AND MARK THE LIST AS HAVING NOTHING
;	SELECTED.

	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
	mov	cx, selectedItem
	mov	dx, 1
	mov	si, offset EditDictionaryList
	call	ObjMessageFixupDS

disableExit:
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	mov	si, offset EditDictionaryList
	call	ObjMessageFixupDS

	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	ObjMessageFixupDS
exit:
	.leave
	ret
errorDelete:
	mov	bx, offset SpellUserDictDeleteGenericString
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE or mask CDBF_SYSTEM_MODAL)
	call	SpellPutupBox
	jmp	exit

EditUserDictionaryControlDeleteSelectedWordFromUserDictionary	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindStringInUserDictionaryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine looks for the just-added string in the user list.

CALLED BY:	GLOBAL
PASS:		ds:si <- ptr to string to search for (DBCS if DBCS)
		es:di <- ptr to array of null terminated strings to look for
		es:0 - UserDictionaryListInfo
RETURN:		dx <- index of word in array (0 to N-1)
DESTROYED:	ax, cx, si, di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindStringInUserDictionaryList	proc	near
	sourceStringLen	local	word
	sourcePtr	local	word
	arrayPtr	local	word
	.enter
	push	es, di
	segmov	es, ds			;ES:DI <- size of source string
	mov	di, si
SBCS <	clr	al							>
DBCS <	clr	ax							>
	mov	cx, -1
SBCS <	repne	scasb			;				>
DBCS <	repne	scasw			;				>
	not	cx			;CX <- size of source string + null
	pop	es, di			;Restore ptr to array

	mov	sourcePtr, si
	mov	sourceStringLen, cx
	clr	dx
if DBCS_PCGEOS
	mov	ax, ds:[si]
	tst	ah
	jnz	nextWord
	mov	ah, al			;AH <- first char in string
else
	mov	ah, ds:[si]		;AH <- first char in string
endif
10$:
	mov	arrayPtr, di
	cmp	dx, es:[UDLI_numEntries]				
EC <	ERROR_A	JUST_ADDED_WORD_NOT_FOUND_IN_USER_DICT_LIST		>
NEC <	ja	notFound						>
   	cmp	ah, es:[di]		;Do first chars match?
	je	compareWords		;Branch if so.

nextWord:
	clr	al			;
	mov	cx, -1			;
	repne	scasb			;Go to next item in list
	inc	dx
	jmp	10$

ife	ERROR_CHECK

;	If, for some reason, the word was not found in the list (this
;	can only happen if somehow a word was added with characters that
;	were not in the DEC character set, which should not happen, since
;	there are filters on the EditDictionaryNewWord object), don't
;	despair, just select the first item, instead of crashing...

notFound:
	clr	dx
	jmp	done	
endif
		
compareWords:
	mov	cx, sourceStringLen	;CX <- length of search word
if DBCS_PCGEOS
80$:
	lodsw
	tst	ah
	jnz	90$
	inc	di
	cmp	al, es:[di-1]
	loope	80$
90$:
else
	repe	cmpsb			;
endif
	mov	si, sourcePtr		;
	mov	di, arrayPtr		;
	jne	nextWord
NEC <done:								>
	.leave
	ret
FindStringInUserDictionaryList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlAddNewWordToUserDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the selected word from the user dictionary and updates
		the display of words.

CALLED BY:	GLOBAL
PASS:		ds - idata
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlAddNewWordToUserDictionary	method	dynamic EditUserDictionaryControlClass,
		MSG_EUDC_ADD_NEW_WORD_TO_USER_DICTIONARY
SBCS <	altString	local	SPELL_MAX_WORD_LENGTH	dup (char)	>
DBCS <	altString	local	SPELL_MAX_WORD_LENGTH	dup (wchar)	>
		
	.enter

EC <	tst	ds:[di].EUDCI_icBuff					>
EC <	ERROR_Z	-1							>

	call	GetFeaturesAndChildBlock

	push	bp, si

	; Disable the "add" trigger so that user won't press it again.

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	mov	si, offset EditDictionaryAddWordTrigger
	call	ObjMessageFixupDS

	mov	ax, MSG_VIS_TEXT_SELECT_ALL	;Select all the replacement
						; text so the user can type
						; over it easily.
	mov	si, offset EditDictionaryNewWord
	call	ObjMessageFixupDS

	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	call	ObjMessageFixupDS		;Set object "not user modified"
						; so the next typing will
						; enable the Add New Word
						; trigger

;	GET WORD TO ADD

	mov	dx, ss			;CX:DX <- ptr to stack space to store
	lea	bp, altString		; string.
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	bp, si
	tst	cx
	LONG jz	noNewWord

;	ADD THE WORD TO THE USER DICTIONARY

	mov	di, ds:[si]
	add	di, ds:[di].EditUserDictionaryControl_offset
	mov	bx, ds:[di].EUDCI_icBuff

	push	ds, si
	segmov	ds, ss
	lea	si, altString		;DS:SI <- ptr to string
	call	ICAddUser
if CONSISTENT_USER_DICT
	cmp	ax, IC_RET_OK
	jne	noUpdate
	call	ICUpdateUser
noUpdate:
endif
	pop	ds, si
	cmp	ax, IC_RET_OK
	jne	noAddError

	call	SendChangeNotification

;	RE-BUILD THE LIST OF ITEMS

	mov	bx, ds:[di].EUDCI_userDictList
	call	MemFree
	mov	bx, ds:[di].EUDCI_icBuff
	call	ICBuildUserList
	mov	ds:[di].EUDCI_userDictList, bx
	call	MemLock
	mov	es, ax

;	FIND OUT THE INDEX OF THE ITEM THAT WAS ADDED, AND PASS IT ALONG

	push	ds, si
	segmov	ds, ss
	lea	si, altString			;DS:SI <- ptr to string to 
						; look for
	mov	di, size UserDictionaryListInfo	;ES:DI <- ptr to first string
	call	FindStringInUserDictionaryList	;Returns DX <- index of string
	pop	ds, si

;	PURGE ALL THE MONIKERS AND ADD A NEW ITEM

	mov	cx, es:[UDLI_numEntries]
	call	MemUnlock
	call	GetFeaturesAndChildBlock
	mov	si, offset EditDictionaryList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ObjMessageFixupDS

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, dx		;CX <- index of item to select
	clr	dx
	call	ObjMessageFixupDS

	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	ObjMessageFixupDS
exit:
	.leave
	ret


noAddError:

;	IF WE COULDN'T ADD THE WORD TO THE USER DICTIONARY, JUST IGNORE IT AND
;	INFORM THE USER.

	mov	bx, offset SpellUserDictFullString
	cmp	dx, UR_USER_DICT_FULL
	je	30$
	mov	bx, offset SpellUserDictWordAlreadyAddedString
	cmp	dx, UR_WORD_ALREADY_ADDED
	je	30$
	mov	bx, offset SpellUserDictAddGenericString
30$:
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE or mask CDBF_SYSTEM_MODAL)
	call	SpellPutupBox
	jmp	exit

noNewWord:
	mov	bx, offset SpellNoNewWordString
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE or mask CDBF_SYSTEM_MODAL)
	call	SpellPutupBox
	jmp	exit

EditUserDictionaryControlAddNewWordToUserDictionary	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlUserDictChangeNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When notified of a change to the user dictionary, this 
		method handler updates the dynamic list.
		

CALLED BY:	GLOBAL
PASS:		dx,bp - data
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlUserDictChangeNotification	method	dynamic EditUserDictionaryControlClass,
					MSG_NOTIFY_USER_DICT_CHANGE
	push	ax, cx, dx, bp
	cmp	dx, ds:[LMBH_handle]	;If we sent it out, ignore it.
	jz	exit			;

if CONSISTENT_USER_DICT
	;
	; force user dictionary file to be re-read
	;
	clr	bx
	xchg	bx, ds:[di].EUDCI_icBuff
	tst	bx
	jz	noUpdate
	call	ICExit
noUpdate:
	call	EditGetICBuff
endif
	clr	bx
	xchg	bx, ds:[di].EUDCI_userDictList
	tst	bx
	jz	exit
	call	MemFree
	call	ResetUserDictList
exit:
	;
	; call superclass to acknowledge receipt of notification
	;
	pop	ax, cx, dx, bp
	mov	di, offset EditUserDictionaryControlClass
	GOTO	ObjCallSuperNoLock
EditUserDictionaryControlUserDictChangeNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlReplacementTextUserModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out when the user modifies the AddNewWord text.

CALLED BY:	EditDictionaryNewWord object sends this when dirty

PASS:		ds - idata
		^lcx:dx - text object that sent it out.

RETURN:		nada

DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlReplacementTextUserModified	method	EditUserDictionaryControlClass,
					MSG_META_TEXT_USER_MODIFIED

	; Make sure the message is sent out by the right object

	cmp	dx, offset EditDictionaryNewWord
	jne	exit

;	NUKE THE CURRENT SELECTION

	call	GetFeaturesAndChildBlock
	push	si
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	mov	si, offset EditDictionaryList
	clr	dx
	call	ObjMessageFixupDS

	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	ObjMessageFixupDS

	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	si, offset EditDictionaryNewWord
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov_tr	bp, ax			;BP <- # chars in object

	mov	ax, MSG_META_TEXT_EMPTY_STATUS_CHANGED
	movdw	cxdx, bxsi
	mov	bx, ds:[LMBH_handle]
	pop	si
	call	ObjMessageFixupDS	
exit:
	ret

EditUserDictionaryControlReplacementTextUserModified	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlReplacementTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the text is becoming empty/non-empty, enable/disable the
		trigger.

CALLED BY:	GLOBAL
PASS:		bp - non-zero if obj has chars now
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlReplacementTextEmptyStatusChanged	method	EditUserDictionaryControlClass,
					MSG_META_TEXT_EMPTY_STATUS_CHANGED
	.enter
	cmp	dx, offset EditDictionaryNewWord
	jne	exit

;	If the text object is not dirty, branch.

	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	movdw	bxsi, cxdx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	disableTrigger

;	IF NO TEXT, WE WANT TO DISABLE THE REPLACE TRIGGERS

	tst	bp
	je	disableTrigger
	mov	ax, MSG_GEN_SET_ENABLED
disableTrigger:

	mov	dl, VUM_NOW
	mov	si, offset EditDictionaryAddWordTrigger
	call	ObjMessageFixupDS
exit:
	.leave
	ret
EditUserDictionaryControlReplacementTextEmptyStatusChanged	endp


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If dict is not available, don't enable the spell control.

		TOOK THIS OUT 5/19/93, as it is unclear why we should care
		if the main dictionary exists or not.

CALLED BY:	GLOBAL
PASS:		params for MSG_GEN_SET_ENABLED
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlSetEnabled	method	EditUserDictionaryControlClass,
					MSG_GEN_SET_ENABLED
	.enter
	call	CheckIfSpellAvailable
	tst	ax
	jz	exit
	mov	ax, MSG_GEN_SET_ENABLED
	mov	di, offset EditUserDictionaryControlClass
	call	ObjCallSuperNoLock
exit:
	.leave
	ret
EditUserDictionaryControlSetEnabled	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlDismiss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notifies the output if the box is being closed.

CALLED BY:	GLOBAL
PASS:		cx - InteractionCommand
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUserDictionaryControlDismiss	method EditUserDictionaryControlClass,
					MSG_VIS_CLOSE
	mov	di, offset EditUserDictionaryControlClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].EditUserDictionaryControl_offset
	clr	bx
	xchg	bx, ds:[di].EUDCI_icBuff
	tst	bx
	jz	noUpdate
	call	ICUpdateUser
	call	ICExit
noUpdate:
	mov	ax, MSG_META_EDIT_USER_DICTIONARY_COMPLETED
	clrdw	bxdi
	call	GenControlOutputActionRegs
	ret
EditUserDictionaryControlDismiss	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUserDictionaryControlInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Stuck in here to put up a dialog on dismisses.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_GUP_INTERACTION_COMMAND
		cx	- InteractionCommand

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/ 6/94         	Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOPPY_BASED_USER_DICT

EditUserDictionaryControlInteractionCommand	method dynamic	\
				EditUserDictionaryControlClass, \
				MSG_GEN_GUP_INTERACTION_COMMAND

	cmp	cx, IC_DISMISS
	jne	callSuper

	;
	; First check for a disk.  If there is one in the drive, do nothing.
	; Otherwise, we'll ask *once* for a user dictionary.   6/14/94 cbh
	;
	push	ax
	mov	al, DOCUMENT_DRIVE_NUM
	call	DiskRegisterDisk		
	pop	ax
	jnc	callSuper

	push	ax
	call	WaitForUserDictInFloppy
	pop	ax

callSuper:
	mov	di, offset EditUserDictionaryControlClass
	GOTO	ObjCallSuperNoLock

EditUserDictionaryControlInteractionCommand	endm

endif





COMMENT @----------------------------------------------------------------------

ROUTINE:	WaitForUserDictInFloppy

SYNOPSIS:	Sets up the stupid user dictionary on the ramdisk for Redwood.
		Here we actually wait for the user to press OK.   We
		also put up a slightly different message, to save the
		dictionary.

CALLED BY:	EditUserDictionaryControlClose

PASS:		nothing

RETURN:		ax -- reply (IC_OK or IC_CANCEL)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/19/94       	Initial version

------------------------------------------------------------------------------@

if FLOPPY_BASED_USER_DICT

WaitForUserDictInFloppy	proc	near	uses	bx, cx, dx, bp, si, di
	.enter
	push	ds:[LMBH_handle]
	mov	ax, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
		   (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE) or \
		   mask CDBF_SYSTEM_MODAL
	mov	bx, offset SpellFloppySaveUserDictString
	;
	; Pass a bunch of params on the stack.   Stack space will be released
	; on return (duh).
	;
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, ax
	mov	si, bx
	mov	bx, handle Strings
	call	MemLock
	push	ds
	mov	ds, ax
	mov	si, ds:[si]		;DS:SI <- ptr to string to display
	pop	ds
	mov	ss:[bp].SDP_customString.segment, ax
	mov	ss:[bp].SDP_customString.offset, si
	clr	ss:[bp].SDP_helpContext.segment
	clrdw	ss:[bp].SDP_customTriggers

	call	UserStandardDialog	;reply in ax
	mov	bx, handle Strings
	call	MemUnlock
	pop	bx
	call	MemDerefDS
	.leave
	ret
WaitForUserDictInFloppy	endp

	;
	; This declaration needed for MSG_EUDC_LOAD_DICTIONARY
	; to pop up the dialog to confirm loading another user
	; dictionary.
	;
loadOKCancelResponse	StandardDialogResponseTriggerTable <2>
	StandardDialogResponseTriggerEntry <
		DiskNotFound_OK,
		IC_OK
	>
	StandardDialogResponseTriggerEntry <
		LoadDictionaryCancel,
		IC_DISMISS
	>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EUDCLoadDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the user dictionary without leaving the user
		dictionary dialog box.

CALLED BY:	MSG_EUDC_LOAD_DICTIONARY
PASS:		*ds:si	= EditUserDictionaryControlClass object
		ds:di	= EditUserDictionaryControlClass instance data
		ds:bx	= EditUserDictionaryControlClass object (same as *ds:si)
		es 	= segment of EditUserDictionaryControlClass
		ax	= message #
RETURN:		Nothing.
DESTROYED:	bx, di, ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CuongLe	3/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EUDCLoadDictionary	method dynamic EditUserDictionaryControlClass, 
					MSG_EUDC_LOAD_DICTIONARY
	.enter

	;
	; Pop up the dialog box to confirm loading the user dictionary.
	;
	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, \
		CustomDialogBoxFlags <1, CDT_NOTIFICATION, GIT_MULTIPLE_RESPONSE, 1>
	mov	ss:[bp].SDOP_customString.handle, handle Strings
	mov	ss:[bp].SDOP_customString.chunk, \
				offset Strings:LoadUserDictConfirmString
	clr	ss:[bp].SDOP_stringArg1.handle
	clr	ss:[bp].SDOP_stringArg2.handle
	mov	ss:[bp].SDOP_customTriggers.segment, cs
	mov	ss:[bp].SDOP_customTriggers.offset, \
				offset loadOKCancelResponse
	clr	ss:[bp].SDOP_helpContext.segment

	call	UserStandardDialogOptr	; ax = InteractionCommand 

	cmp	ax, IC_OK	; check if the user clicked OK button.
	jnz	exitLoad	; exit if the user clicked Cancel button.
	;
	; Free the previous userDictList
	;
	clr	bx
	xchg	bx, ds:[di].EUDCI_userDictList	; bx = EUDCI_userDictList
	call	MemFree
	;
	; Close the current edit box first
	;
	mov	ax,MSG_EUDC_CLOSE_EDIT_BOX
	call	ObjCallInstanceNoLock
	;
	; Then load a new user dictionary
	; 
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjCallInstanceNoLock

exitLoad:
	.leave
	ret

EUDCLoadDictionary	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EUDCCloseEditBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close Edit User Dictionary Dialog Box without saving
		any changes.
	
CALLED BY:	MSG_EUDC_LOAD_DICTIONARY
PASS:		*ds:si	= EditUserDictionaryControlClass object
		ds:di	= EditUserDictionaryControlClass instance data
		ds:bx	= EditUserDictionaryControlClass object (same as *ds:si)
		es 	= segment of EditUserDictionaryControlClass
		ax	= message #
RETURN:		Nothing
DESTROYED:	Nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CuongLe	3/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EUDCCloseEditBox	method dynamic EditUserDictionaryControlClass, 
					MSG_EUDC_CLOSE_EDIT_BOX
	.enter

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, offset EditUserDictionaryControlClass
	GOTO	ObjCallSuperNoLock

	.leave
	ret
EUDCCloseEditBox	endm
endif
SpellControlCode	ends
