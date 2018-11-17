COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpFirstAid.asm

AUTHOR:		Gene Anderson, Dec 14, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	12/14/92		Initial revision


DESCRIPTION:
	

	$Id: helpFirstAid.asm,v 1.1 97/04/07 11:47:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlChooseFirstAid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle user choosing a first aid option

CALLED BY:	MSG_HC_CHOOSE_FIRST_AID
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message

		cx - VisTextContextType

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlChooseFirstAid		method dynamic HelpControlClass,
						MSG_HC_CHOOSE_FIRST_AID
HELP_LOCALS
	.enter

	call	HUGetChildBlockAndFeaturesLocals
EC <	test	ss:features, mask HPCF_HISTORY	;>
EC <	ERROR_NZ HELP_CANNOT_HAVE_HISTORY_FOR_FIRST_AID_HELP >
	;
	; Find the number of entries back to the *oldest* history entry
	; of the correct type. This means clicking on TOC, Chapter, or
	; Article will take the user to their original entry of the
	; given type.
	;
	; This is currently done in a somewhat inefficient manner, but it
	; is relatively small since it is mostly common code.  There should
	; never be enough history involved for this to really matter, in
	; any event, and will be swamped by the time to load, decompress,
	; calculate and display the text.
	;
	mov	al, cl				;al <- VisTextContextType
	call	HFAFindHistory			;cx <- # of items back
goBackLoop:
	call	HFAGoBackOne			;go back one item in history
	jc	noHistory			;branch if no history left
	loop	goBackLoop			;loop until far enough
	;
	; Display the new text
	;
	call	HLDisplayText
	jc	openError			;branch if error
	call	HFAUpdateForMode
openError:
quit:
	.leave
	ret

	;
	; We've run out of history -- rather than do nothing, bring
	; up the TOC as a last resort.
	;
noHistory:
	mov	ax, MSG_HC_BRING_UP_TOC
	call	ObjCallInstanceNoLock
	jmp	quit
HelpControlChooseFirstAid		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HFAUpdateForMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the First Aid UI for the current mode

CALLED BY:	HelpControlChooseFirstAid()
PASS:		ss:bp - inherited locals
RETURN:		none
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FAM_DONT_CARE	equ VTCT_FILE-1			;don't care about previous
FAM_NONE	equ VTCT_FILE-2			;if there is no previous

FirstAidModeStruct struct
    FAMS_prevContext	VisTextContextType	;previous context to match
    FAMS_curContext	VisTextContextType	;current context to match
    FAMS_listSetting	VisTextContextType	;setting for first aid list
    FAMS_chapterState	word			;enable or disable
    FAMS_articleState	word			;enable or disable
    FAMS_jumpState	word			;enable or disable
    FAMS_instructions	lptr			;instructions to display
FirstAidModeStruct ends

firstAidModes	FirstAidModeStruct <
	;
	; at "TOC" initially
	;
	FAM_NONE,				;previous
	VTCT_CATEGORY,				;current
	VTCT_CATEGORY,				;list state
	MSG_GEN_SET_NOT_ENABLED,		;chapter
	MSG_GEN_SET_NOT_ENABLED,		;article
	MSG_GEN_SET_NOT_ENABLED,		;jump back
	offset tocInst
>,<
	;
	; at "Chapter" initially (ie. no TOC)
	;
	FAM_NONE,				;previous
	VTCT_QUESTION,				;current
	VTCT_QUESTION,				;list state
	MSG_GEN_SET_ENABLED,			;chapter
	MSG_GEN_SET_NOT_ENABLED,		;article
	MSG_GEN_SET_NOT_ENABLED,		;jump back
	offset chapterInst
>,<
	;
	; at "Chapter" from TOC
	;
	VTCT_CATEGORY,				;previous
	VTCT_QUESTION,				;current
	VTCT_QUESTION,				;list state
	MSG_GEN_SET_ENABLED,			;chapter
	MSG_GEN_SET_NOT_ENABLED,		;article
	MSG_GEN_SET_NOT_ENABLED,		;jump back
	offset chapterInst
>,<
	;
	; at "Answer" from Chapter
	;
	VTCT_QUESTION,				;previous
	VTCT_ANSWER,				;current
	VTCT_ANSWER,				;list state
	MSG_GEN_SET_ENABLED,			;chapter
	MSG_GEN_SET_ENABLED,			;article
	MSG_GEN_SET_NOT_ENABLED,		;jump back
	offset articleInst
>,<
	;
	; at Answer from previous "Answer"
	;
	VTCT_ANSWER,				;previous
	VTCT_ANSWER,				;current
	FAM_NONE,				;list state
	MSG_GEN_SET_ENABLED,			;chapter
	MSG_GEN_SET_ENABLED,			;article
	MSG_GEN_SET_ENABLED,			;jump back
	offset jumpBackInst
>,<
	;
	; at "Answer" initially (ie. no Chapter, FAM_NONE)
	; or at "Answer" from TOC.  These are combined into
	; FAM_DONT_CARE, since the other cases with "Answer" are
	; dealt with above.
	;
	FAM_DONT_CARE,				;previous
	VTCT_ANSWER,				;current
	VTCT_ANSWER,				;list state
	MSG_GEN_SET_NOT_ENABLED,		;chapter
	MSG_GEN_SET_ENABLED,			;article
	MSG_GEN_SET_NOT_ENABLED,		;jump back
	offset noChapterInst
>,<
	;
	; error -- no history or nothing else found
	;
	FAM_DONT_CARE,				;previous
	FAM_DONT_CARE,				;current
	FAM_NONE,				;list state
	MSG_GEN_SET_NOT_ENABLED,		;chapter
	MSG_GEN_SET_NOT_ENABLED,		;article
	MSG_GEN_SET_NOT_ENABLED,		;jump back
	offset nullInst
>

HFAUpdateForMode		proc	near
	uses	di, si, cx
HELP_LOCALS
	.enter	inherit

	mov	bx, ss:childBlock
	;
	; Get the previous & current contexts
	;
	mov	dx, FAM_NONE or (FAM_NONE shl 8) ;dx <- no current, no prev
	call	HHGetHistoryCount		;cx <- # items in history
	jcxz	findMode			;branch if no history
	dec	cx
	call	HHGetHistoryEntry		;get last item
	mov	dl, ss:nameData.HFND_text.VTND_contextType
	jcxz	findMode
	dec	cx
	call	HHGetHistoryEntry		;get 2nd to last item
	mov	dh, ss:nameData.HFND_text.VTND_contextType
	;
	; See if we've been at an answer before -- it so, treat
	; everything like another answer.  If an answer is further
	; back than the most recent item in history, then it counts.
	;
	mov	al, VTCT_ANSWER			;al <- VisTextContextType
	call	HFAFindHistory
	cmp	cx, 0				;far enough back?
	je	findMode			;branch if recent enough
	mov	dx, VTCT_ANSWER or (VTCT_ANSWER shl 8)
	;
	; Find the corresponding mode entry
	;
findMode:
	clr	di				;di <- offset into table
modeLoop:
	cmp	cs:firstAidModes[di].FAMS_prevContext, FAM_DONT_CARE
	je	checkCurrent			;branch if don't care about prev
	cmp	dh, cs:firstAidModes[di].FAMS_prevContext
	jne	nextMode
checkCurrent:
	cmp	cs:firstAidModes[di].FAMS_curContext, FAM_DONT_CARE
	je	foundMode			;branch if don't care about cur
	cmp	dl, cs:firstAidModes[di].FAMS_curContext
	je	foundMode			;branch if match
nextMode:
	add	di, (size FirstAidModeStruct)
EC <	cmp	di, (size firstAidModes)	;>
EC <	ERROR_A	HELP_FIRST_AID_MODE_NOT_FOUND	;>
	jmp	modeLoop

	;
	; We've found the current mode -- update the UI
	;
foundMode:
	;
	; Enable and disable various UI components
	;
	test	ss:features, mask HPCF_FIRST_AID
	jz	noFirstAid
	mov	ax, cs:firstAidModes[di].FAMS_chapterState
	mov	si, offset HFALQuestionsEntry
	call	doEnableDisable
	mov	ax, cs:firstAidModes[di].FAMS_articleState
	mov	si, offset HFALAnswersEntry
	call	doEnableDisable
noFirstAid:
	test	ss:features, mask HPCF_FIRST_AID_GO_BACK
	jz	noFirstAidGoBack
	mov	ax, cs:firstAidModes[di].FAMS_jumpState
	mov	si, offset HelpFirstAidGoBack
	call	doEnableDisable
noFirstAidGoBack:
	;
	; Set the list to the correct mode
	;
	mov	cl, cs:firstAidModes[di].FAMS_listSetting
	clr	ch				;cx <- item to set
	clr	dx				;dx <- no indeterminate (zero)
	cmp	cl, FAM_NONE			;indeterminate?
	jne	gotSetting
	dec	dx				;dx <- indeterminate (non-zero)
gotSetting:
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	si, offset HelpFirstAid
	call	HUObjMessageSend
	;
	; Set the instruction text, if any
	;
	test	ss:features, mask HPCF_INSTRUCTIONS
	jz	noInstructions
	push	bp
	mov	dx, handle HelpControlStrings
	mov	bp, cs:firstAidModes[di].FAMS_instructions
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	clr	cx				;cx <- NULL-terminated
	mov	si, offset HelpInstructionsText
	call	HUObjMessageSend
	pop	bp
noInstructions:

	.leave
	ret

doEnableDisable:
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	HUObjMessageSend
	retn
HFAUpdateForMode		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlFirstAidGoBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User hit "Jump Back"

CALLED BY:	MSG_HC_FIRST_AID_GO_BACK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlFirstAidGoBack		method dynamic HelpControlClass,
						MSG_HC_FIRST_AID_GO_BACK
HELP_LOCALS
	.enter

	call	HUGetChildBlockAndFeaturesLocals
	call	HFAGoBackOne			;go back one in history
EC <	ERROR_C	HELP_RECORDED_HELP_MISSING	;>
	call	HLDisplayText			;display new next
	jc	openError			;branch if error
	call	HFAUpdateForMode		;update the UI
openError:

	.leave
	ret
HelpControlFirstAidGoBack		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HFAGoBackOne
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go back one item for First Aid

CALLED BY:	HelpControlFirstAidGoBack(), HelpControlChooseFirstAid()
PASS:		*ds:si - help controller
		ss:bp - inherited locals
RETURN:		ss:bp - locals
			filename - previous filename
			context - previous context
		carry - set if no history to go back to
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HFAGoBackOne		proc	near
	uses	cx
HELP_LOCALS
	.enter	inherit
	;
	; Get the last entry & delete it
	;
	call	HHGetHistoryCount		;cx <- # of items in history
	stc					;carry <- assume no history
	jcxz	quit				;branch if no history
	dec	cx				;cx <- last item
	call	HHGetHistoryEntry		;get last entry
	call	HHDeleteHistory			;delete last; cx <- # left
	call	HHSameFile?			;same file?
	je	sameFile			;branch if same file
	clr	bx				;bx <- no new file
	call	HFSetFileCloseOld		;close current file
sameFile:
	;
	; Get the new last entry
	;
	stc					;carry <- assume no history
	jcxz	quit				;branch if no more history
	dec	cx				;cx <- last item
	call	HHGetHistoryEntry		;get last entry
	clc					;carry <- no error
quit:

	.leave
	ret
HFAGoBackOne		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HFAFindHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find oldest history entry of given type

CALLED BY:	HelpControlChooseFirstAid()
PASS:		*ds:si - controller
		ss:bp - inherited locals
		al - VisTextContextType to match
RETURN:		cx - # of entries to go back
		     (0 means one of:
			- no history
			- no history of the right type
			- the oldest history of the right type is the
			  current item
		      all these mean no going back is necessary)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HFAFindHistory		proc	near
	uses	bx, ds, si
	.enter

	;
	; Lock the history array
	;
	call	HHLockHistoryArray
	;
	; Get the total number of entries
	;
	call	ChunkArrayGetCount
	;
	; "Begin at the beginning..." and go until we find the first entry
	; of the correct type
	;
	mov	bx, cs
	mov	di, offset HFAFindHistoryCallback
	call	ChunkArrayEnum
	;
	; Unlock the history array
	;
	call	HHUnlockHistoryArray

	.leave
	ret
HFAFindHistory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HFAFindHistoryCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first history element of the specified type

CALLED BY:	HFAFindHistory() via ChunkArrayEnum()
PASS:		ds:di - current element
		al - VisTextContextType to match
		cx - # of entries left
RETURN:		carry - set to abort
		cx - new # of entries left
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HFAFindHistoryCallback		proc	far
	.enter

	dec	cx				;one less entry
	cmp	al, ds:[di].HHE_type		;correct type?
	clc					;carry <- assume mismatch
	jne	done				;branch if mismatch
	stc					;carry <- match
done:

	.leave
	ret
HFAFindHistoryCallback		endp

HelpControlCode	ends
