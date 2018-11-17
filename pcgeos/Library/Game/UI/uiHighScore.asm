COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiHighScore.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 9/92   	Initial version.
	BCHOW	3/11/93		Added custom high scores.
	DEH	3/ 1/2000	Added app-specific help context.

DESCRIPTION:

	$Id: uiHighScore.asm,v 1.1 97/04/04 18:04:20 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @--------------------------------------------------------------------
	IMPLEMENTATION ISSUES/DETAILS
-----------------------------------------------------------------------------
Since the high score object is just an organizational interaction with
2 dialog children, it never gets spec built, which means that normally
it would never get MSG_GEN_CONTROL_GENERATE_UI.   Therefore, we just
send it to ourself when we first notice that the children haven't been
built.  This is probably a hack, but it seems to work.


We could use a name array instead of a chunk array of pointers to DB
items -- this would probably simplify a few things...

The high score object should contain the name of the game, so that it
says something like "Tetris Hall Of Fame" rather than just "Hall Of Fame"

----------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

MESSAGE:	HighScoreGetInfo --
		MSG_GEN_CONTROL_GET_INFO for HighScoreClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of HighScoreClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
HighScoreGetInfo	method dynamic	HighScoreClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset HS_dupInfo
	GOTO	CopyDupInfoCommon
HighScoreGetInfo	endm


HS_dupInfo	GenControlBuildInfo	<
	mask GCBF_CUSTOM_ENABLE_DISABLE or mask \
		GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST or \
		mask GCBF_IS_ON_ACTIVE_LIST,
	HS_IniFileKey,			; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	0,				; GCBI_controllerName

	handle HighScoreUI,		; GCBI_dupBlock
	HS_childList,			; GCBI_childList
	length HS_childList,		; GCBI_childCount
	HS_featuresList,		; GCBI_featuresList
	length HS_featuresList,		; GCBI_featuresCount
	HIGH_SCORE_DEFAULT_FEATURES,	; GCBI_features
	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0				; GCBI_toolFeatures
	>

HS_IniFileKey	char	"high score",0

;---

HS_childList	GenControlChildInfo	\
	<offset GetNameBox, 0, mask GCCF_ALWAYS_ADD>,
	<offset HighScoreDisplayBox, 0, mask GCCF_ALWAYS_ADD>,
	<offset ShowHighScoresTrigger, mask HSF_SHOW_HIGH_SCORES_TRIGGER, mask GCCF_IS_DIRECTLY_A_FEATURE>



; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

HS_featuresList	GenControlFeaturesInfo	\
	<offset ShowHighScoresTrigger, 0, 0>,
	<offset	HighScoreExtraGroup, 0, 0>,
	<offset	HighScoreDateGroup, 0, 0>,
	<offset	HighScoreScoreGroup, 0, 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Open the high scores file

PASS:		*ds:si	= HighScoreClass object
		ds:di	= HighScoreClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HighScoreAttach	method	dynamic	HighScoreClass, 
					MSG_META_ATTACH
	uses	ax
	.enter

	call	HighScoreOpenFile

	.leave
	mov	di, offset HighScoreClass
	GOTO	ObjCallSuperNoLock
HighScoreAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Closes the data file, if one was open.

PASS:		*ds:si	= HighScoreClass object
		ds:di	= HighScoreClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HighScoreDetach	method	dynamic	HighScoreClass, 
					MSG_META_DETACH

	uses	ax

	.enter
	clr	bx
	xchg	bx, ds:[di].HSI_fileHandle
	tst	bx			;Exit if we couldn't open the file
	jz	exit
	mov	al, FILE_NO_ERRORS
	call	VMClose
exit:
	.leave
	mov	di, offset HighScoreClass
	GOTO	ObjCallSuperNoLock

HighScoreDetach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNullTerminatedStringIntoDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies data into a DB Item

CALLED BY:	GLOBAL
PASS:		bx - handle of DB file
		ds:si - null-terminated data to copy in
RETURN:		ax.di - DB item
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNullTerminatedStringIntoDBItem	proc	near
	uses	es, cx
	.enter	
	segmov	es, ds
	mov	di, si			;ES:DI <- ptr to string
	LocalStrSize	includeNull	;CX <- # bytes in the string
	mov	ax, DB_UNGROUPED
	call	DBAlloc
	pushdw	axdi
	call	DBLock
	mov	di, es:[di]
	rep	movsb
	call	DBDirty
	call	DBUnlock
	popdw	axdi
	.leave
	ret
CopyNullTerminatedStringIntoDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a sound to make the user feel good about himself/herself.

CALLED BY:	EXTERNAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	2/24/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef HIGH_SCORE_SOUND

HighScoreSound	proc	far
	uses	ax, bx, cx, dx, di, es

soundToken	local	GeodeToken
	.enter

	; Retrieve our GeodeToken.
	segmov	es, ss, ax
	lea	di, soundToken
	mov	bx, handle 0		; bx <- library geode token
	mov	ax, GGIT_TOKEN_ID
	call	GeodeGetInfo

	; Play the sound.
	mov	cx, es
	mov	dx, di
	clr	bx			; sound # = 0
	call	WavPlayInitSound
	.leave
	ret
HighScoreSound	endp

endif		;HIGH_SCORE_SOUND


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreGetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the name under which to register a high score

CALLED BY:	GLOBAL
PASS:		dx:bp - dest for name

RETURN:		cx = string length (not counting NULL)

DESTROYED:	ax, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreGetName	method	HighScoreClass, MSG_HIGH_SCORE_GET_NAME
	uses	bx
	.enter

ifdef HIGH_SCORE_SOUND
	; If ATTR_HIGH_SCORE_DONT_PLAY_SOUND is present, don't make a sound.
	mov	ax, ATTR_HIGH_SCORE_DONT_PLAY_SOUND
	call	ObjVarFindData
	jc	skipSound
	call	HighScoreSound
skipSound:
endif
	mov	es, dx
SBCS <	clr	{char}es:[bp]						>
DBCS <	clr	{wchar}es:[bp]						>

	call	HighScoreGetChildBlockAndFeatures

	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	si, offset GetNameText
	clr	di
	call	ObjMessage

	mov	si, offset GetNameBox
	call	UserDoDialog
	
	cmp	ax, IC_OK
	jne	exit

	;
	; Fetch the text from the text object and add it to the file
	;

	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	si, offset GetNameText
	mov	di, mask MF_CALL
	call	ObjMessage
exit:
	.leave
	ret
HighScoreGetName	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindUserName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the user name in the list 

CALLED BY:	GLOBAL
PASS:		es:di - null-terminated name to find
		*ds:si - HighScore object
		bx - file handle
RETURN:		carry set if name found
		ax - index of score found
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindUserName	proc	near
	uses	bx,cx,dx,bp,di,si,es,ds
	.enter
	pushdw	esdi
	call	HighScoreLockMap


	; Enumerate all entries, and find the name

	clr	ax
	mov	cx, bx		;CX <- file handle
	mov	bx, cs
	popdw	esbp		;ES:BP <- null terminated name to match
	mov	di, offset HighScoreFindNameCB
	call	ChunkArrayEnum
	
	segmov	es, ds
	call	DBUnlock
	.leave
	ret
FindUserName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreFindNameCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks for a name

CALLED BY:	GLOBAL
PASS:		ax - index of this name
		cx - file handle
		ds:di - HighScoreArrayElement
RETURN:		carry set if name matched name associated with current score
		ax - updated 
DESTROYED:	bx, di, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreFindNameCB	proc	far
	uses	cx, es, bp, ds
	.enter
	push	ax
	mov	bx, cx			;BX <- file handle
	mov	ax, ds:[di].HSAE_name.high
	mov	di, ds:[di].HSAE_name.low
	segmov	ds, es			;DS:SI <- name to match
	mov	si, bp
	call	DBLock

	mov	di, es:[di]		;ES:DI <- name associated with score
	call	LocalCmpStrings

	call	DBUnlock
	pop	ax

	stc
	jz	exit			;Exit with carry set if strings matched
	inc	ax			;Else, update index to point to next
	clc				; entry, and return carry clear
exit:
	.leave
	ret
HighScoreFindNameCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreAddScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Add a new entry to the high score

PASS:		*ds:si	= HighScoreClass object
		ds:di	= HighScoreClass instance data
		es	= Segment of HighScoreClass.
		dx:cx	- score
		
RETURN:		carry set if score was added, clear otherwise.

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HighScoreAddScore	method	dynamic	HighScoreClass, 
					MSG_HIGH_SCORE_ADD_SCORE
	uses	cx,dx,bp

extraBlock	local	hptr	\
		push	bp

score		local	dword	\
		push	dx, cx

hiScoreObject	local	lptr	\
		push	si

fileHandle	local	hptr

scoreWasAdded	local	byte
scoreNotAddedReason	local HighScoreNotAddedReason

placeToInsertScore	local	word
SBCS< userName	local	MAX_USER_NAME_LENGTH+1 dup (char)			>
DBCS< userName	local	MAX_USER_NAME_LENGTH+1 dup (wchar)		>

	.enter
	mov	scoreNotAddedReason,HSNAR_COULDNT_OPEN_FILE
	clr	scoreWasAdded			; default to no score added
	mov	bx, ds:[di].HSI_fileHandle
	tst	bx				;Exit if couldn't open the file
	jz	done
	mov	fileHandle, bx

;
;  Grab exclusive access to the file for reading. We don't want to have
;  exclusive access while waiting for user feedback (while the user is 
;  entering his name), so grab the exclusive, release it while we get the
;  user name, then grab it again (for writing) when we add the name to
;  the file.   	
;	

	mov	ax, VMO_READ
	clr	cx			;Get exclusive access to the high score
	call	VMGrabExclusive		; file. Block until it's free

	movdw	dxcx, score
	call	FindPlaceToInsertScore	;AX <- place to insert score (0 based)

	call	VMReleaseExclusive

	mov	scoreNotAddedReason,HSNAR_SCORE_NOT_GOOD_ENOUGH
	cmp	ax, MAX_HIGH_SCORES
EC <	ERROR_A	TOO_MANY_HIGH_SCORES					>
	je	done


	mov	scoreNotAddedReason,HSNAR_NAME_NOT_ENTERED
	mov	placeToInsertScore, ax

	push	bp
	mov	dx, ss	
	lea	bp, userName
	mov	ax, MSG_HIGH_SCORE_GET_NAME
	call	ObjCallInstanceNoLock
	pop	bp
SBCS <	tst	{char}ss:userName					>
DBCS <	tst	{wchar}ss:userName					>
	jnz	addAndShowScore
	
done:
	mov	bx, extraBlock
	tst	bx
	jz	noExtraData
	call	MemFree
noExtraData:
	;
	;  Return the carry set if they made it.
	;
	mov	ax,scoreNotAddedReason
	tst_clc	scoreWasAdded
	jz	exit
	stc
exit:
	.leave
	ret

releaseDone:
	mov	bx, fileHandle
	call	VMReleaseExclusive
	jmp	done

addAndShowScore:

	mov	ax, VMO_WRITE
	clr	cx			;Block until we get exclusive access
	call	VMGrabExclusive
	cmp	ax, VMSERV_NO_CHANGES
	je	noChangesWhileEnteringName

;	The high score file was modified while the user was entering their
;	name, so find the new place to put their score.

	mov	scoreNotAddedReason, HSNAR_HOSED_BY_OTHER_HIGH_SCORE
	movdw	dxcx, score
	call	FindPlaceToInsertScore
	cmp	ax, MAX_HIGH_SCORES
EC <	ERROR_A	TOO_MANY_HIGH_SCORES					>
	je	releaseDone		;XXX <- We should probably tell the
					; user what happened here - NAAH!
	mov	placeToInsertScore, ax

noChangesWhileEnteringName:

	mov	di, ds:[si]
	add	di, ds:[di].HighScore_offset
	test	ds:[di].HSI_attrs, mask HSA_ONE_SCORE_PER_NAME
	jz	addScore

;	If the user already has a score on the high score list, check
;	to see if we this one is higher.
;
;	If so, delete the existing score, and add the new score
;	If not, don't add this new score	

	mov	scoreNotAddedReason, HSNAR_DIDNT_BEAT_EXISTING_PERSONAL_SCORE
	mov	bx, fileHandle
	segmov	es, ss			;ES:DI <- name
	lea	di, userName
	call	FindUserName		;Find any existing scores under this
	jnc	addScore		; name - branch if none found
	cmp	ax, placeToInsertScore	;If existing score is above current
	jb	releaseDone		; score, just exit

;
;	Delete existing score, and mark the map block dirty
;

	push	ds, si
	call	HighScoreLockMap	;*DS:SI <- chunk array w/scores
	call	DeleteScore		;Delete the score whose index is in AX
	segmov	es, ds
	call	DBDirty
	call	DBUnlock
	pop	ds, si

addScore:
	;
	;  Save the fact that we're adding the score, for when we return.
	;
	dec	scoreWasAdded
		
	;
	; Store the user's name in a new DB item
	;
	mov	bx, fileHandle
	push	ds			
	segmov	ds, ss
	lea	si, ss:[userName]
	call	CopyNullTerminatedStringIntoDBItem
	pop	ds			; *ds:si - self
	pushdw	axdi			; group, item

	clrdw	axdi
	mov	bx, extraBlock		;If no extra block, branch
	tst	bx
	jz	noExtraBlock

	push	ds
	call	MemLock			;Lock down the extra data block, 
	mov	ds, ax			; figure out the length, and copy
	clr	si			; the data into a DB Item
	mov	bx, fileHandle
	call	CopyNullTerminatedStringIntoDBItem

	mov	bx, extraBlock		;Unlock the extra data block
	call	MemUnlock
	pop	ds
noExtraBlock:
	pushdw	axdi			;Group/Item of extra data (0 if none)

	;
	; Now, lock the map item, and add /insert a new element into
	; the array
	;
	mov	si, hiScoreObject
	call	HighScoreLockMap
	mov	ax, placeToInsertScore
	call	ChunkArrayElementToPtr
	jc	append
	call	ChunkArrayInsertAt
	jmp	storeData
append:
	call	ChunkArrayAppend

storeData:
	movdw	ds:[di].HSAE_score, score, ax
	call	TimerGetDateAndTime
	mov	ds:[di].HSAE_year, ax
	mov	ds:[di].HSAE_month, bl
	mov	ds:[di].HSAE_day, bh
	popdw	ds:[di].HSAE_extra
	popdw	ds:[di].HSAE_name		; item #

	;
	; Nuke last item, if such exists (allowing up to MAX_HIGH_SCORES
	; items to stay)
	;
	mov	ax, MAX_HIGH_SCORES
	mov	bx, fileHandle 
	call	DeleteScore


	segxchg	es, ds
	call	DBDirty
	call	DBUnlock

	;
	;  Release exclusive access to the file.
	;

	mov	bx, fileHandle
	call	VMReleaseExclusive

	push	bp	
	mov	cx, placeToInsertScore
	mov	si, hiScoreObject
	mov	ax, MSG_HIGH_SCORE_SHOW_SCORES
	call	ObjCallInstanceNoLock
	pop	bp

	call	HighScoreUpdate
	jmp	done
HighScoreAddScore	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the passed score

CALLED BY:	GLOBAL
PASS:		*ds:si - chunk array of scores
		bx - file handle
		ax - index of score to delete (0 based)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteScore	proc	near
	.enter

	call	ChunkArrayElementToPtr	;Exit if score does not exist
	jc	afterNuke

;	Free up the extra information stored with this score (the name and
;	extra information)

	push	di
	mov	ax, ds:[di].HSAE_name.high
	mov	di, ds:[di].HSAE_name.low
	call	DBFree
	pop	di
	push	di
	mov	ax, ds:[di].HSAE_extra.high
	mov	di, ds:[di].HSAE_extra.low
	tstdw	axdi
	jz	noExtra
	call	DBFree
noExtra:
	pop	di
	call	ChunkArrayDelete
afterNuke:

	.leave
	ret
DeleteScore	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceMonikerOnObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the VisMoniker on the passed object

CALLED BY:	GLOBAL
PASS:		^lCX:DX <- new moniker to use (do nothing if dx=0)
		^lBX:SI <- object
		DS <- Fixupable block
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceMonikerOnObject	proc	near
	uses	ax, dx, bp, di
	.enter
	tst	dx
	jz	exit
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	bp, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	.leave
	ret
ReplaceMonikerOnObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMonikerFromVardata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the moniker from the data stored in vardata

CALLED BY:	GLOBAL
PASS:		*ds:si - high score object
		^lbx:di - child object for which to set moniker
		cx - vardata type to look for
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 5/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMonikerFromVardata	proc	near	uses	ax, cx, dx
	.enter
	push	bx
	mov_tr	ax, cx
	call	ObjVarFindData		;^lCX:DX <- string for "Show Scores"
	mov	cx, ds			; trigger (branch if no custom moniker)
	mov	dx, ds:[bx]
	pop	bx
	jnc	exit

	push	si
	mov	si, dx
	mov	dx, ds:[si]		;CX:DX <- string to display
	mov	si, di			;^lbx:si <- object to set moniker
	call	SetMonikerFromString
	pop	si
exit:
	.leave
	ret
SetMonikerFromVardata	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We do various UI setup here.

CALLED BY:	MSG_GEN_CONTROL_GENERATE_UI
PASS:		*ds:si	= HighScoreClass object
		ds:di	= HighScoreClass instance data
		ds:bx	= HighScoreClass object (same as *ds:si)
		es 	= segment of HighScoreClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	3/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreGenerateUI	method dynamic HighScoreClass, 
					MSG_GEN_CONTROL_GENERATE_UI
	uses	ax, cx, dx, bp
	.enter
	mov	di, offset HighScoreClass
	call	ObjCallSuperNoLock

	;
	; Get highScoreTitle from user's .ui file, and if not zero,
	; set HighScoreDisplayBox's moniker.
	;
	call	HighScoreGetChildBlockAndFeatures


;	Set the "Show High Scores" trigger not-usable depending upon
;	whether or not the file was opened


	test	ax, mask HSF_SHOW_HIGH_SCORES_TRIGGER
	jz	10$


	mov	di, ds:[si]
	add	di, ds:[di].HighScore_offset

	push	si
	mov	si, offset ShowHighScoresTrigger
	tst	ds:[di].HSI_fileHandle
	jnz	setMoniker

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

setMoniker:
	pop	si

;	Set up any custom moniker for the "Show High Scores" trigger

	mov	ax, ATTR_HIGH_SCORE_SHOW_SCORES_TRIGGER_MONIKER
	call	ObjVarFindData
	jnc	10$			;Branch if not found
	push	si
	mov	dx, ds:[bx]
	mov	cx, ds:[LMBH_handle]	;CX:DX <- moniker
	call	HighScoreGetChildBlockAndFeatures
	mov	si, offset ShowHighScoresTrigger
	call	ReplaceMonikerOnObject
	pop	si

10$:

;	Set up the various monikers for the score display areas here.

	call	HighScoreGetChildBlockAndFeatures
	mov	cx, ATTR_HIGH_SCORE_NAME_TITLE_MONIKER
	mov	di, offset HighScoreNameTitleGlyph
	call	SetMonikerFromVardata

	test	ax, mask HSF_SCORE
	jz	noScore

	mov	cx, ATTR_HIGH_SCORE_SCORE_TITLE_MONIKER
	mov	di, offset HighScoreScoreTitleGlyph
	call	SetMonikerFromVardata

noScore:
	test	ax, mask HSF_DATE
	jz	noDate

	mov	cx, ATTR_HIGH_SCORE_DATE_TITLE_MONIKER
	mov	di, offset HighScoreDateTitleGlyph
	call	SetMonikerFromVardata

noDate:
	test	ax, mask HSF_EXTRA_DATA
	jz	noExtraData

	mov	cx, ATTR_HIGH_SCORE_EXTRA_TITLE_MONIKER
	mov	di, offset HighScoreExtraTitleGlyph
	call	SetMonikerFromVardata

noExtraData:
	mov	di, ds:[si]
	add	di, ds:[di].HighScore_offset
	push	si
	push	ds:[di].HSI_highScoreLine4
	push	ds:[di].HSI_highScoreLine3
	push	ds:[di].HSI_highScoreLine2
	push	ds:[di].HSI_highScoreLine1

	mov	cx, ds:[LMBH_handle]
	mov	dx, ds:[di].HSI_highScoreTitle

	mov	si, offset HighScoreDisplayBox
	call	ReplaceMonikerOnObject

	pop	dx		;DX <- HSI_highScoreLine1
	mov	si, offset GetNameTitle1
	call	ReplaceMonikerOnObject

	pop	dx		;DX <- HSI_highScoreLine2
	mov	si, offset GetNameTitle2
	call	ReplaceMonikerOnObject

	pop	dx		;DX <- HSI_highScoreLine3
	mov	si, offset GetNameTitle3
	call	ReplaceMonikerOnObject

	pop	dx		;DX <- HSI_highScoreLine4
	mov	si, offset GetNameTitle4
	call	ReplaceMonikerOnObject

	pop	si

;	Copy the help context from this object (the parent controller) into
;	the high score display dialog.

	mov	ax, ATTR_GEN_HELP_CONTEXT
	call	ObjVarFindData		; ds:bx <- ptr to help context
	jnc	noHelpContext		; branch if not found

	; Get the length of the help context, including null.
	mov	di, bx
	segmov	es, ds, ax
	clr	al
	mov	cx, -1
	repne	scasb			; cx <- -(NZ-string length + 1)
	not	cx			; cx <- NZ-string length

	; Setup the AddVarDataParams struct
	mov	dx, size AddVarDataParams
	sub	sp, dx
	mov	bp, sp
	movdw	ss:[bp].AVDP_data, dsbx
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_HELP_CONTEXT
	mov	ss:[bp].AVDP_dataSize, cx
	call	HighScoreGetChildBlockAndFeatures
	mov	si, offset HighScoreDisplayBox	; *bx:si <- high score box
	mov	di, mask MF_STACK or mask MF_CALL
	mov	ax, MSG_META_ADD_VAR_DATA
	call	ObjMessage
	add	sp, size AddVarDataParams

noHelpContext:
	.leave
	ret
HighScoreGenerateUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPlaceToInsertScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	See if the passed high score cuts the mustard

PASS:		*ds:si	= HighScoreClass object
		dx:cx 	= high score

RETURN:		ax = position in high scores file (element #), 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindPlaceToInsertScore	proc	near
	uses	bx,cx,dx,bp,di,si,es,ds
	class	HighScoreClass
	.enter

	call	HighScoreLockMap

	; compare current score with each entry

	mov	di, es:[di]
	add	di, es:[di].HighScore_offset
	mov	al, es:[di].HSI_attrs
	mov	bx, cs
	mov	di, offset HighScoreTestScoreCB
	call	ChunkArrayEnum
	jc	gotEntry

	; score was lower than ones in the file -- set CX to chunk
	; array count

	call	ChunkArrayGetCount
gotEntry:
	mov_tr	ax, cx		; return element #
	segmov	es, ds
	call	DBUnlock
	.leave
	ret
FindPlaceToInsertScore	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreTestScoreCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to test a score

CALLED BY:	HighScoreTestScore via ChunkArrayEnum

PASS: 		dx:cx - dword representing current score
		ds:di - high score entry
		al - HighScoreAttributes

RETURN:		IF current score beats score at ds:di
			cx = current element #
			carry set
		ELSE
			carry clear
			cx unchanged

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
+
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreTestScoreCB	proc far	uses	ax
	.enter

	test	al, mask HSA_LOW_SCORE_IS_BETTER
	jnz	lowScoreBetter

	jgedw	dxcx, ds:[di].HSAE_score, pass

	; Score failed the test
fail:
	clc
done:
	.leave
	ret
pass:
	call	ChunkArrayPtrToElement
	mov	cx, ax
	stc
	jmp	done

lowScoreBetter:
	jledw	dxcx, ds:[di].HSAE_score, pass
	jmp	fail

HighScoreTestScoreCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GotoHighScoreDataDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to SP_PUBLIC_DATA/GAME

CALLED BY:	GLOBAL

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString programDirName <"GAME",0>

GotoHighScoreDataDir	proc	near
	uses	ds,dx,bx
	.enter
	mov	ax, SP_PUBLIC_DATA
	call	FileSetStandardPath

	clr	bx			; no disk handle
	segmov	ds, cs
	mov	dx, offset programDirName
	call	FileSetCurrentPath
	jnc	done

	call	FileCreateDir
EC <	ERROR_C UNABLE_TO_CREATE_GAME_DIRECTORY	>
	call	FileSetCurrentPath
done:
	.leave
	ret
GotoHighScoreDataDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreOpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates/verifies a database file to hold the high scores.

CALLED BY:	HighScoreAttach

PASS:		*ds:si - HighScore object

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear

DESTROYED:	nothing 
 
PSEUDO CODE/STRATEGY:
	Store file handle in var data if opened.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 3/91		Initial version
	chrisb  1/93		moved to game library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
hsiProtocol ProtocolNumber <HIGH_SCORE_FILE_MAJOR_PROTOCOL, 
				HIGH_SCORE_FILE_MINOR_PROTOCOL>

HighScoreOpenFile	proc	near		
		uses	ax, cx, dx, bp, di, si, es


	class	HighScoreClass

	.enter




	call	GotoHighScoreDataDir

	
;	TRY TO OPEN THE FILE

	mov	ax, (VMO_OPEN shl 8) or mask VMAF_FORCE_SHARED_MULTIPLE
	mov	di, ds:[si]
	add	di, ds:[di].HighScore_offset
	mov	bx, ds:[di].HSI_fileName
	mov	dx, ds:[bx]
	clr	cx
	call	VMOpen
	jc	create

	;
	; Check the major protocol.  If it's an old
	; version of the file, nuke it.
	;

	mov	ax, FEA_PROTOCOL
	sub	sp, size ProtocolNumber
	mov	di, sp
	segmov	es, ss
	mov	cx, size ProtocolNumber
	call	FileGetHandleExtAttributes

		CheckHack <size ProtocolNumber eq 4>
		CheckHack <offset PN_major eq 0>
		CheckHack <offset PN_minor eq 2>

	pop	ax			; major
	pop	cx			; minor

	cmp	ax, HIGH_SCORE_FILE_MAJOR_PROTOCOL
	jne	closeAndDelete
	cmp	cx, HIGH_SCORE_FILE_MINOR_PROTOCOL
	jne	closeAndDelete

saveHandle:

	mov	di, ds:[si]
	add	di, ds:[di].HighScore_offset
	mov	ds:[di].HSI_fileHandle, bx

done:
	.leave
	ret

closeAndDelete:
	; bx - VM file handle

	call	VMClose

	
	;
	; Delete the bad DB file.  If unable to, then just exit,
	; otherwise create a new one.
	;

	mov	bx, ds:[di].HSI_fileName
	mov	dx, ds:[bx]
	call	FileDelete
	jc	error

create:
	call	HighScoreCreateFile
	jnc	saveHandle
error:
        sub     sp, size StandardDialogOptrParams
        mov     bp, sp
        mov     ss:[bp].SDOP_customFlags, \
                   CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION,0>

	mov	ss:[bp].SDOP_customString.handle, handle cannotOpenFile
        mov     ss:[bp].SDOP_customString.chunk, offset cannotOpenFile
        clr     ax                              ;none of these are passed
        mov     ss:[bp].SDOP_stringArg1.handle, ax
        mov     ss:[bp].SDOP_stringArg2.handle, ax
        mov     ss:[bp].SDOP_customTriggers.handle, ax
	clr	ss:[bp].SDOP_helpContext.segment
        call    UserStandardDialogOptr          ; pass params on stack
	jmp	done



HighScoreOpenFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreCreateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new high score file, since for some reason,
		the old one's no good (or none exists)

CALLED BY:	HighScoreOpenFile

PASS:		*ds:si - HighScore object

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear
			bx - file handle

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/30/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreCreateFile	proc near
	uses	ds, es, si

	class	HighScoreClass

	.enter

	;
	; Create the monster
	;

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].HSI_fileName
	mov	dx, ds:[bx]
	mov	ax, (VMO_CREATE_TRUNCATE shl 8)
	call	VMOpen
	jc	done

	;
	; Set the protocol numbers
	;

	segmov	es, cs
	mov	di, offset hsiProtocol
	mov	ax, FEA_PROTOCOL
	mov	cx, size hsiProtocol
	call	FileSetHandleExtAttributes


;	ALLOCATE A NEW MAP ITEM -- CHUNK ARRAY

	push	bx				; VM file handle
	mov	ax, DB_UNGROUPED
	mov	cx, size ChunkArrayHeader	;Save word # items in block
	call	DBAlloc
	call	DBSetMap
       	call	DBLock				;Lock/Init map block
	segmov	ds, es
	mov	si, di
	mov	bx, size HighScoreArrayElement
	clr	ax, cx
	call	ChunkArrayCreate
	segmov	es, ds				; in case segment moved
	call	DBDirty				; Mark as dirty
	call	DBUnlock

	pop	bx				; VM file handle
	call	HighScoreUpdate		;Write the data out

done:
	.leave
	ret
HighScoreCreateFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the high score file and make sure it is saved to disk.

CALLED BY:	GLOBAL
PASS:		bx = file handle
RETURN:		nada

DESTROYED:	nothing 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreUpdate	proc	near
	uses	ax
	.enter
	call	VMUpdate			;Update database information
	mov	al, FILE_NO_ERRORS		;
	call	FileCommit			;Update file on disk
	.leave
	ret
HighScoreUpdate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreShowScores
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Bring up the high scores dialog box

PASS:		*ds:si	= HighScoreClass object
		es	= Segment of HighScoreClass.
		cx 	= high score to highlight

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreShowScores	method dynamic 	HighScoreClass, 
					MSG_HIGH_SCORE_SHOW_SCORES
	uses	cx,dx

.warn -unref_local
fileHandle	local	hptr	\
		push	ds:[di].HSI_fileHandle
object		local	word	\
		push	si
highlight	local	word	\
		push	cx		

buffer		local	SCORE_BUFFER_SIZE dup (char)
.warn @unref_local
counter		local	word
childBlock	local	hptr
features	local	HighScoreFeatures

	.enter
EC <	cmp	highlight, -1						>
EC <	jz	skipEC							>
EC <	cmp	highlight, MAX_HIGH_SCORES				>
EC <	ERROR_AE INVALID_SCORE_INDEX					>
EC <skipEC:								>

	clr	counter

	call	HighScoreGetChildBlockAndFeatures
	mov	ss:[childBlock], bx
	mov	ss:[features], al

;	If we don't want to highlight anything, nuke the gadgetry that does
;	the highlighting.

	mov	ax, MSG_GEN_SET_USABLE
	cmp	highlight, -1
	jz	setUsable
	mov	ax, MSG_GEN_SET_NOT_USABLE
setUsable:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset HighScoreHighlightGroup
	clr	di
	call	ObjMessage
	mov	si, object


	;
	;  Grab exclusive access to the file for reading.
	;

	mov	bx, fileHandle
	mov	ax, VMO_READ
	clr	cx			;Block, don't timeout
	call	VMGrabExclusive

	call	HighScoreLockMap

	mov	bx, cs
	mov	di, offset HighScoreSetupScoresCB
	call	ChunkArrayEnum

	call	ChunkArrayGetCount

	segmov	es, ds
	call	DBUnlock

	;
	; Set all the objects beyond the end of the array not usable.
	;
	mov	bx, ss:[childBlock]
	mov	al, features

	push	cx	; edwdig
startLoop:
	cmp	cx, MAX_HIGH_SCORES
	je	endLoop
	call	SetNotUsable
	inc	cx
	jmp	startLoop

endLoop:

	; edwdig
	pop	cx
	tst	cx
	jnz	scoresExist	
	mov	ax, MSG_GEN_SET_USABLE
	jmp	scoresDontExist
scoresExist:
	mov	ax, MSG_GEN_SET_NOT_USABLE
scoresDontExist:
	mov	bx, childBlock
	mov	si, offset NoScoresGlyph
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	di
	call	ObjMessage	
	

	;
	;  Release exclusive access to the file.
	;
	mov	bx, fileHandle
	call	VMReleaseExclusive

	mov	bx, childBlock
	mov	si, offset HighScoreDisplayBox

	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage

	.leave
	ret
HighScoreShowScores	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatAsMoney
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats the passed data as money

CALLED BY:	GLOBAL
PASS:		dx.ax - score
		es:di - dest buffer
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/29/93   	Initial version
	srs	8/25/93		Added support for currency symbol position

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatAsMoney	proc	near
	uses	ax,bx,cx,es,di
	.enter

	pushdw	dxax					;score
	call	LocalGetCurrencyFormat		;--> values in ax,bx,cx,dx, es:di
	popdw	dxcx					;score

	test	al,mask CFF_SYMBOL_BEFORE_NUMBER
	jz	afterNumber

	;    Find null terminator after currency symbol (es:di), keeping
	;    in mind that there may be no currency symbol, and
	;    point di at the null terminator.
	;

if DBCS_PCGEOS
	push	ax
	clr	ax				;ax <- 
	repne	scasw				;scan me jesus
	pop	ax
	LocalPrevChar esdi			;es:di <- ptr to NULL
else
findNull:
	mov	ah,es:[di]
	inc	di
	tst	ah
	jnz	findNull		
	dec	di				;point at null termintor
endif

	;    Store space after symbol if necessary.
	;

	test	al, mask CFF_SPACE_AROUND_SYMBOL
	jz	formatAsPoints
	mov	al,C_SPACE
	stosb

formatAsPoints:
	;    Stick the number characters after the symbol garbage,
	;    null terminate it and run.
	;

	mov_tr	ax,cx					;score low word
	call	FormatAsPoints

done:
	.leave
	ret

afterNumber:
	;    Write the number characters over the symbol and
	;    don't stick a null termination at the end.
	;

	xchg	ax,cx				;score low word, CFF's
	call	FormatAsPointsNoTermination

	;   Write the space, if needed, and the symbol characters
	;   after the number characters. LocalGetCurrencyFormat
	;   will null terminate the string for us.
	;

	test	cl,mask CFF_SPACE_AROUND_SYMBOL
	jz	getSymbolForAfter
	mov	al,C_SPACE
	stosb
getSymbolForAfter:
	call	LocalGetCurrencyFormat
	jmp	done

FormatAsMoney	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatAsPointsNoTermination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format the passed number as ascii characters without
		adding a null terminator at the end

CALLED BY:	FormatAsMoney
		FormatAsPoints

PASS:		es:di - buffer to store data
		dx.ax - score

RETURN:		
		di - pointer to byte after last character in number string

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/25/93   	Yanked from FormatAsPoints

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatAsPointsNoTermination		proc	near
	uses	ax,bx,cx,dx,bp
	.enter

	mov_tr	ax, dx			;AX:DX <- score

;	Convert number from AX:DX to ASCII string with thousands separators
;	(Stolen from ASCIIizeDWordAXDX)

	mov	bx, 10				;print in base ten
	clr	cx				;initialize character count
nextDigit:
	mov	bp, dx				;bp = low word
	clr	dx				;dx:ax = high word
	div	bx
	xchg	ax, bp				;ax = low word, bp = quotient
	div	bx
	xchg	ax, dx				;ax = remainder, dx = quotient

	add	al, '0'				;convert to ASCII
	push	ax				;save character
	inc	cx

	mov	ax, bp				;retrieve quotient of high word
	or	bp, dx				;check if done
	jnz	nextDigit			;if not, do next digit

nextChar:
	pop	ax				;retrieve character
	LocalPutChar esdi, ax
	cmp	cx, 10
	je	storeComma
	cmp	cx, 7
	je	storeComma
	cmp	cx, 4
	jne	afterComma
storeComma:
	call	GetThousandsSeparator
	LocalPutChar esdi, ax
afterComma:
	loop	nextChar			;loop to print all

	.leave
	ret
FormatAsPointsNoTermination		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatAsPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats the passed data as points

CALLED BY:	GLOBAL
PASS:		es:di - buffer to store data
		dx.ax - score

RETURN:		nada

DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/29/93   	Initial version
	srs	8/24/93		Broke out FormatAsPointsNoTermination

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatAsPoints	proc	near
	.enter

	call	FormatAsPointsNoTermination

SBCS <	clr	al				; null-terminate	>
DBCS <	clr	ax				; null-terminate	>
	LocalPutChar esdi, ax

	.leave
	ret
FormatAsPoints	endp
;
; pass: nothing
; returns: al = thousands separator
; destroys: ah
GetThousandsSeparator	proc	near
	uses	bx, cx, dx
	.enter
	call	LocalGetNumericFormat
SBCS <	mov	al, bl				; al = thousands separator>
DBCS <	mov	ax, bx				; al = thousands separator>
	.leave
	ret
GetThousandsSeparator	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToHMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the passed value to Hours/Minutes/Seconds

CALLED BY:	GLOBAL
PASS:		dx.ax - value
RETURN:		ch - hours
		dl - minutes
		dh - seconds
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NUM_SECONDS_PER_MINUTE	equ	60
NUM_MINUTES_PER_HOUR	equ	60
ConvertToHMS	proc	near	uses	ax, bx
	.enter
	mov	bx, NUM_SECONDS_PER_MINUTE * NUM_MINUTES_PER_HOUR
	div	bx
EC <	tst	ah							>
EC <	ERROR_NZ	ELAPSED_TIME_TOO_LARGE				>
	mov	ch, al		;CL <- hours

	mov_tr	ax, dx		;AX <- # minutes/seconds (remainder)
	mov	bl, NUM_SECONDS_PER_MINUTE
	div	bl

	mov_tr	dx, ax		;DL <- minutes
				;DH <- seconds		
	.leave
	ret
ConvertToHMS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatAsElapsedTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats the passed data as an elapsed time

CALLED BY:	GLOBAL
PASS:		dx.ax - elapsed time in seconds
		es:di - dest buffer
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatAsElapsedTime	proc	near
	.enter
	call	ConvertToHMS
;
;	CH <- Hours
;	DL <- Minutes
;	DH <- Seconds
;
	mov	si, DTF_HMS_24HOUR
	tst	ch
	jnz	format
	mov	si, DTF_MS
	tst	dl
	jz	justAScore
format:
	call	LocalFormatDateTime
exit:
	.leave
	ret

justAScore:
	mov	al, dh
	clr	ah
	clr	dx
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	jmp	exit
FormatAsElapsedTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreFormatScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats the passed score into one of the three various
		formats

CALLED BY:	GLOBAL
PASS:		ss:bp - FormatScoreParams
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreFormatScore	method	HighScoreClass, MSG_HIGH_SCORE_FORMAT_SCORE
	.enter
	mov	bl, ds:[di].HSI_scoreType
	clr	bh
EC <	cmp	bx, length formatScoreRoutines				>
EC <	ERROR_AE	INVALID_SCORE_TYPE				>
	shl	bl, 1
	movdw	dxax, ss:[bp].FSP_score
	les	di, ss:[bp].FSP_dest
EC <	segxchg	ds, es							>
EC <	xchg	di, si							>
EC <	call	ECCheckBounds						>
EC <	xchg	di, si							>
EC <	segxchg	ds, es							>
	call	cs:[formatScoreRoutines][bx]
	.leave
	ret
HighScoreFormatScore	endp

formatScoreRoutines nptr	\
		    FormatAsPoints,
		    FormatAsElapsedTime,
		    FormatAsMoney

.assert length formatScoreRoutines eq ScoreType

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreSetupScoresCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to setup the high scores

CALLED BY:	HighScoreShowScores via ChunkArrayEnum

PASS:		ds:di - pointer to HighScoreArrayElement
		ss:bp - local vars inherited from HighScoreShowScores

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreSetupScoresCB	proc far

	.enter  inherit	HighScoreShowScores

	segxchg	es, ds		;ES:DI <- HSAE_score
	

	; Convert score to string
	test	features, mask HSF_SCORE
	jz	noScore

	push	bp
	lea	si, buffer
	pushdw	sssi
	pushdw	es:[di].HSAE_score
	mov	si, object

	mov	bp, sp
	mov	ax, MSG_HIGH_SCORE_FORMAT_SCORE
	call	ObjCallInstanceNoLock
	add	sp, size FormatScoreParams
.assert	size FormatScoreParams eq (size fptr + size dword)
	pop	bp
	

	mov	cx, ss
	lea	dx, buffer
	mov	bx, childBlock
	mov	si, ss:[counter]
	mov	si, cs:[scoreGlyphs][si]
	call	SetMonikerFromString

noScore:
	; Get DATE

	test	features, mask HSF_DATE
	jz	noDate

	mov	ax, es:[di].HSAE_year
	mov	bl, es:[di].HSAE_month
	mov	bh, es:[di].HSAE_day
	mov	si, DTF_SHORT
	
	push	es,di
	segmov	es, ss
	lea	di, buffer
	call	LocalFormatDateTime

	movdw	cxdx, esdi
	mov	bx, childBlock
	mov	si, ss:[counter]
	mov	si, cs:[dateGlyphs][si]
	call	SetMonikerFromString
	pop	es, di

noDate:

	test	features, mask HSF_EXTRA_DATA
	jz	noExtraData

;	Set the "extra data" glyphs

	mov	si, ss:[counter]
	mov	dx, cs:[extraGlyphs][si]
	mov	cx, childBlock
	mov	bx, fileHandle
	push	di
	mov	ax, es:[di].HSAE_extra.high
	mov	di, es:[di].HSAE_extra.low
	call	SetMonikerFromDBItem
	pop	di

noExtraData:

	; GET THE NAME 

	mov	si, ss:[counter]
	mov	dx, cs:[nameGlyphs][si]
	mov	cx, childBlock
	mov	bx, fileHandle
	push	di
	mov	ax, es:[di].HSAE_name.high
	mov	di, es:[di].HSAE_name.low
	call	SetMonikerFromDBItem
	pop	di


;	If the current name is the one we are trying to highlight, then
;	highlight it by setting the glyph next to it to have a '>'. Otherwise,
;	set it blank.

	clr	cx
DBCS <	clr	dx							>
	push	cx			;Push a NULL on the stack
	mov	si, ss:[highlight]
	shl	si, 1
	cmp	si, ss:[counter]
	mov	si, ss:[counter]
	jne	doHighlight
SBCS <	mov	cx, C_GREATER_THAN or (C_SPACE shl 8)			>
DBCS <	mov	cx, C_GREATER_THAN_SIGN					>
DBCS <	mov	dx, C_SPACE						>
doHighlight:
DBCS <	push	dx							>
	push	cx
	movdw	cxdx, sssp
	mov	si, cs:[highlightGlyphs][si]
	mov	bx, childBlock			;^lBX:SI <- item to highlight
	call	SetMonikerFromString
SBCS <	add	sp, size word*2						>
DBCS <	add	sp, size word*3						>
	add	ss:[counter], size lptr	; increment by 2's, since
					; we're going into a
					; word-sized table.

	segxchg	es, ds
	clc				;Continue with the enum

	.leave
	ret
HighScoreSetupScoresCB	endp
DBCS <highlightString wchar C_GREATER_THAN_SIGN, " "			>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMonikerFromDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the VisMoniker for the passed object with the data in
		the passed DBItem

CALLED BY:	GLOBAL
PASS:		ax:di - Group/Item of DBItem (or 0 for "no string")
		^lcx:dx - object to muck with
		bx - file handle
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMonikerFromDBItem	proc	near	uses	es, di
	.enter
	tstdw	axdi
	jz	setNull
	call	DBLock			;Lock the block with the name

	movdw	bxsi, cxdx		;^lBX:SI <- object to set moniker
	mov	cx, es
	mov	dx, es:[di]		;CX:DX <- ptr to name string

	call	SetMonikerFromString

	call	DBUnlock	
exit:
	.leave
	ret
setNull:
	movdw	bxsi, cxdx
	clr	cx
	push	cx			;Push NULL on the stack, and make
	movdw	cxdx, sssp		; CX:DX point to it
	call	SetMonikerFromString
	add	sp, size word
	jmp	exit
SetMonikerFromDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMonikerFromString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the moniker for the passed object to the passed string

CALLED BY:	HighScoreSetupScoresCB

PASS:		cx:dx - string
		BX:SI - OD of object to set moniker

RETURN:		nothing 

DESTROYED:	ax, cx, dx
 
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 7/91		Initial version
	chrisb	1/93		modified for game library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMonikerFromString	proc	near	

	uses	bp, di
	.enter

	;
	; Create the moniker
	;

	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	

	;
	; Make sure the item is usable
	;

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	di
	call	ObjMessage

	.leave
	ret
SetMonikerFromString	endp
	





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNotUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set an object not usable

CALLED BY:	HighScoreShowScores

PASS:		cx - item number to set not usable
		bx - handle of children

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNotUsable	proc near
	uses	ax,bx,cx,dx,di,si,bp
	.enter
	mov	dh, al				;DH <- HighScoreFeatures
	mov	bp, cx
	shl	bp, 1

	mov	si, cs:[nameGlyphs][bp]
	clr	di
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessage

	test	dh, mask HSF_SCORE
	jz	noScore
	mov	si, cs:[scoreGlyphs][bp]
	clr	di
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjMessage
noScore:
	test	dh, mask HSF_DATE
	jz	noDate
	mov	si, cs:[dateGlyphs][bp]
	clr	di
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjMessage

noDate:
	test	dh, mask HSF_EXTRA_DATA
	jz	exit
	mov	si, cs:[extraGlyphs][bp]
	clr	di
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjMessage
exit:
	.leave
	ret
SetNotUsable	endp


nameGlyphs	lptr	\
		HighScoreName1, 
		HighScoreName2, 
		HighScoreName3,
		HighScoreName4,
		HighScoreName5,
		HighScoreName6,
		HighScoreName7,
		HighScoreName8,
		HighScoreName9,
		HighScoreName10

highlightGlyphs	lptr	\
		HighScoreHighlight1, 
		HighScoreHighlight2, 
		HighScoreHighlight3,
		HighScoreHighlight4,
		HighScoreHighlight5,
		HighScoreHighlight6,
		HighScoreHighlight7,
		HighScoreHighlight8,
		HighScoreHighlight9,
		HighScoreHighlight10

extraGlyphs	lptr	\
		HighScoreExtra1, 
		HighScoreExtra2, 
		HighScoreExtra3,
		HighScoreExtra4,
		HighScoreExtra5,
		HighScoreExtra6,
		HighScoreExtra7,
		HighScoreExtra8,
		HighScoreExtra9,
		HighScoreExtra10

scoreGlyphs	lptr	\
		HighScoreScore1,
		HighScoreScore2,
		HighScoreScore3,
		HighScoreScore4,
		HighScoreScore5,
		HighScoreScore6,
		HighScoreScore7,
		HighScoreScore8,
		HighScoreScore9,
		HighScoreScore10


dateGlyphs	lptr	\
		HighScoreDate1,
		HighScoreDate2,
		HighScoreDate3,
		HighScoreDate4,
		HighScoreDate5,
		HighScoreDate6,
		HighScoreDate7,
		HighScoreDate8,
		HighScoreDate9,
		HighScoreDate10


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreGetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the data block where the children live

CALLED BY:	HighScoreAddScore, HighScoreReadUserName,
		HighScoreShowScores 

PASS:		*ds:si - GenControl object

RETURN:		bx - child block
		ax - HighScoreFeatures

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/27/91	Initial version.
	ATW	4/9/93		Changed to return features too

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreGetChildBlockAndFeatures	proc near	
	.enter

	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	tst	bx
	jnz	done

	;
	; The child block hasn't been duplicated, so create it.
	;

	push	cx, dx, bp
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp

	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock

	
done:
	.leave
	ret
HighScoreGetChildBlockAndFeatures	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighScoreLockMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the map item.

CALLED BY:	HighScoreReadUserName, HighScoreTestScore, 
		HighScoreShowScores

PASS:		*ds:si - HighScore object

RETURN:		*ds:si - map item
		*es:di - HighScore object

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/30/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighScoreLockMap	proc near
	class	HighScoreClass
	uses	bx
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].HighScore_offset
	mov	bx, ds:[di].HSI_fileHandle

	call	DBLockMap
	segxchg	ds, es
	xchg	si, di

	.leave
	ret
HighScoreLockMap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnderlinedGlyphRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	calculate the size of the object

PASS:		stuff i'm too lazy to look up
		
RETURN:		width in cx, height in dx

DESTROYED:	probably something

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	Add 2 pixels to the default height of the glyph
			so that we can draw an underline

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwdig	1/14/00   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnderlinedGlyphRecalcSize	method	UnderlinedGlyphClass, 
					MSG_VIS_RECALC_SIZE
	.enter

	mov	di, offset UnderlinedGlyphClass
	call	ObjCallSuperNoLock
	add	dx, 2

	.leave
	ret
UnderlinedGlyphRecalcSize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnderlinedGlyphDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Lets the default draw handler work, then draws an
		underline

PASS:		you can look it up yourself elsewhere
		
RETURN:		ditto

DESTROYED:	stuff

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwdig	1/14/00   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnderlinedGlyphDraw	method	UnderlinedGlyphClass, 
					MSG_VIS_DRAW
	.enter

	push	bp
	mov	di, offset UnderlinedGlyphClass
	call	ObjCallSuperNoLock
	pop	di
	push	di
	call	GrGetTextColor
	mov	ah, CF_RGB
	call	GrSetLineColor
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	
	mov	ax, ds:[di].VI_bounds.R_left
	mov	bx, ds:[di].VI_bounds.R_bottom
	dec	bx
	mov	cx, ds:[di].VI_bounds.R_right
	dec	cx
	pop	di
	call	GrDrawHLine

	.leave
	ret
UnderlinedGlyphDraw	endm
