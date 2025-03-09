COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:    	Navigation Library	
MODULE:		Navigate controller -- History list
FILE:		navControlHistory.asm

AUTHOR:		Alvin Cham, Sep 26, 1994

ROUTINES:
	Name			Description
	----			-----------
    
    	class methods:
    	--------------

    	NCGotoHistory	    	- go to a particular history entry

    	NCGotoHomePage	    	- go to the home page

    	NCPreviousPage	    	- go to the previous page

    	NCNextPage  	    	- get the next page

    	NCSetPrevNextTriggerState   
    	    	    	    	- set the state for 'Prev' and 'Next' 
    	    	    	    	triggers

    	NCInitHistoryList   	- initialize the history list

    	NCFreeHistoryList   	- free the history list

    	NCInsertEntry	    	- insert an entry

    	NCGetStateBlock	    	- get the state block that will be returned

    	NCGoBack    	    	- go back a link

    	NCGoForward 	    	- go forward a link

    	NCGetHistoryListMoniker	- get the moniker of a list entry

    	class procedures:
    	-----------------

    	NCCheckMainPage	    	- check if we are at the main page

    	NCIndexMoveRequest  	- a request to move the entry index

    	NCGotoHistoryEntry  	- goto a particular list entry

    	NCSendDisplayToOutput	- send a display notification to output

    	NCSendDeleteToOutput	- send a deletion notification to output
	
    	NCGetHistoryEntry   	- get a particular entry

    	NCGetHistoryCount   	- count the number of items in list

    	NCInitializeList    	- initialize the list

    	NCGetIndex  	    	- get the index of current entry

    	NCSetIndex  	    	- set the index of current entry

    	NCMoveIndexForward  	- move index forward or backward

    	NCRedrawHistoryList 	- re-displays the list

    	NCSetHistoryListSelection
    	    	    	    	- set the selection of the list

    	NCRecordHistory	    	- record the info. for an entry

    	NCDeleteHistory	    	- delete list entry or entries

    	NCUpdateHistoryForLink	- update list after a new link

    	NCFreeHistoryArray  	- free the list array

    	NCLockHistoryArray  	- lock the list array

    	NCUnlockHistoryArray	- unlock the list array


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/26/94   	Initial revision


DESCRIPTION:
	History list code for the Navigate controller

	$Id: navcontrolHistory.asm,v 1.1 97/04/05 01:24:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NavigateControlCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGotoHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goto a particular history entry

CALLED BY:	MSG_NC_GOTO_HISTORY
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
    	    	cl  	= NavigateHistoryListType

RETURN:		nothing
DESTROYED:	ax, cx, dx, di, ds, es, bx, si 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGotoHistory	method dynamic NavigateControlClass, 
					MSG_NC_GOTO_HISTORY
NAVIGATION_LOCALS
	.enter

    	mov 	bx, ds:[di].NCI_historyBlock

    	; init various useful things
    	call	NCGetToolBlockAndToolFeaturesLocals
    	call	NCGetChildBlockAndFeaturesLocals
    	
    	; get selected history entry's number

    	push	bp, si
    	mov 	si, offset  NavigateHistoryList
    	mov 	di, offset  NavigateHistoryGroup

    	push	di
    	mov 	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
    	mov 	di, mask MF_CALL or mask MF_FIXUP_DS
    	call	ObjMessage  	    	    	; ax = entry #

EC  <	ERROR_C	NAV_CONTROL_NOTHING_SELECTED_IN_HISTORY_LIST	>
    	pop 	si

    	; restore focus to text object
    	push	ax  	    	    	    	; entry #
    	mov 	ax, MSG_META_RELEASE_FOCUS_EXCL
    	clr 	di
    	call	ObjMessage
    	pop 	ax  	    	    	    	; entry #

    	pop 	bp, si

    	; get the entry for the bp-th entry from the end.  This is
	; because the most recent history is displayed at the top of
	; the list, but is stored last in the array
    	call	NCGetHistoryCount   	    	; cx = # entries
EC  <	tst 	cx  	    	    	    	>
EC  <	ERROR_Z	NAV_CONTROL_NO_HISTORY_ENTRY   	>
    	dec 	cx
    	sub 	cx, ax	    	    	    	; cx = # from end

    	; go to that history entry and update index
    	push	cx
    	call	NCGotoHistoryEntry
    	pop 	bx
    	call	NCSetIndex

    	; send a notification for trigger changes
    	clr 	ax  	    	    	    	; flag for notification
    	tst 	bx
    	jnz 	notify
    	or  	ax, mask NNCCF_displayMain  	; display main page if
						; index = 0
notify:
    	call	NavigateSendNotification
	.leave
	ret
NCGotoHistory	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGotoHomePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the Home Page of the history list entry

CALLED BY:	MSG_NC_GOTO_HOME_PAGE
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGotoHomePage	method dynamic NavigateControlClass, 
					MSG_NC_GOTO_HOME_PAGE
NAVIGATION_LOCALS
	.enter

    	mov 	bx, ds:[di].NCI_historyBlock

    	; init various useful things
    	call	NCGetToolBlockAndToolFeaturesLocals
    	call	NCGetChildBlockAndFeaturesLocals
    	
    	call	NCGetHistoryCount   	    	; cx = # entries
EC  <	tst 	cx  	    	    	    	>
EC  <	ERROR_Z	NAV_CONTROL_NO_HISTORY_ENTRY   	>

    	; go to the zero-th history entry and update index
    	clr 	cx
    	call	NCGotoHistoryEntry
    	clr 	bx
    	call	NCSetIndex

    	; send a notification for trigger changes
    	clr 	ax  	    	    	    	; flag for notification
    	or  	ax, mask NNCCF_displayMain  	; display main page if
						; index = 0
    	call	NavigateSendNotification
	.leave
	ret
NCGotoHomePage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCPreviousPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the previous page

CALLED BY:	MSG_NC_PREVIOUS_PAGE
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	cx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCPreviousPage	method dynamic NavigateControlClass, 
					MSG_NC_PREVIOUS_PAGE
    	mov 	bp, NCGPT_PREVIOUS_PAGE	    ; data to send
    	mov 	cx, NSTOT_DATA      	    ; we are sending data
    	mov 	dx, GWNT_NAVIGATE_ENTRY_CHANGE
    	call	NCSendToOutput    	

    	clr 	ax  	    	    	    ; flags
    	call	NCCheckMainPage
    	call	NavigateSendNotification
	ret
NCPreviousPage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCNextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next page

CALLED BY:	MSG_NC_NEXT_PAGE
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	cx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCNextPage	method dynamic NavigateControlClass, 
					MSG_NC_NEXT_PAGE
    	mov 	bp, NCGPT_PREVIOUS_PAGE	    ; data to send
    	mov 	cx, NSTOT_DATA      	    ; we are sending data
    	mov 	dx, GWNT_NAVIGATE_ENTRY_CHANGE
    	call	NCSendToOutput    	

    	clr 	ax  	    	    	    ; flags
    	call	NCCheckMainPage
    	call	NavigateSendNotification
	ret
NCNextPage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCSetPrevNextTriggersState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enabling/Disabling the "Prev Page" Trigger

CALLED BY:	MSG_NC_SET_PREV_NEXT_TRIGGERS_STATE
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
    	    	cx  	= "prev page" state
    	    		NPTST_ENABLE	= set it enable
    	    	    	NPTST_DISABLE	= set it disable
    	    	dx  	= "next page" state
    	    	    	NNTST_ENABLE	= set it enable
    	    	    	NNTST_DISABLE	= set it disable

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCSetPrevNextTriggersState	method dynamic NavigateControlClass, 
					MSG_NC_SET_PREV_NEXT_TRIGGERS_STATE
CheckHack   <	NPTST_ENABLE	eq 	0   	    	    >
CheckHack   <	NNTST_ENABLE	eq  	0   	    	    >

    	clr 	ax  	    	    	    ; flag
    	call	NCCheckMainPage	    	    ; ax = new flag

    	tst 	cx
    	jnz 	checkNextTrigger
    	or  	ax, mask NNCCF_prevEnabled

checkNextTrigger:
    	tst 	dx
    	jnz 	notify
    	or  	ax, mask NNCCF_nextEnabled

notify:
    	or  	ax, mask NNCCF_pageTriggerStateChanged
    	call	NavigateSendNotification
	ret
NCSetPrevNextTriggersState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCInitHistoryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the history list interaction

CALLED BY:	MSG_NC_INIT_HISTORY_LIST
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:  	bx, si, di, ds, es (method handler)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCInitHistoryList	method dynamic NavigateControlClass, 
					MSG_NC_INIT_HISTORY_LIST
    	mov 	bx, ds:[di].NCI_historyBlock
    	mov	si, offset	NavigateHistoryGroup
EC <	call	ECCheckOD   	    	                          >
    	mov 	ax, MSG_GEN_INTERACTION_INITIATE
    	clr 	di
    	GOTO	ObjMessage
NCInitHistoryList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCFreeHistoryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Getting rid of the history list array and
    	    	reinitialize the field gobackIndex

CALLED BY:	MSG_NC_FREE_HISTORY_LIST
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
    	    	(1) Set up argument values and call subprocedures.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCFreeHistoryList	method dynamic NavigateControlClass, 
					MSG_NC_FREE_HISTORY_LIST
    	mov 	bx, -1	    	    	
    	call	NCSetIndex
    	call	NCFreeHistoryArray

	ret
NCFreeHistoryList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCInsertEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displaying the entry of selected thing.

CALLED BY:	MSG_NC_INSERT_ENTRY
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
    	    	cx:dx	= moniker of entry
    	    	bp  	= ChunkHandle of selectorChunk

RETURN:		nothing
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
    	    	(1) Send a notification.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCInsertEntry	method dynamic NavigateControlClass, 
					MSG_NC_INSERT_ENTRY

    	; should fill in the context and other info 
    	; set up the arguments for sending a notification
    	clr 	ax

    	; get the current index to see if we have any entries
    	call	NCGetIndex  	    	    ; bx = index
    	inc 	bx  	    	    	    ; check if bx == -1
    	tst 	bx
    	jnz 	haveIndex
    	BitSet	ax, NNCCF_displayMain	    ; this is the main page too!!

haveIndex:
    	BitSet 	ax, NNCCF_updateHistory
    	call	NavigateSendNotification    	
	ret
NCInsertEntry	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGetStateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the handle of the history list and sets
    	    	NCI_historyList to null

CALLED BY:	MSG_NC_GET_HISTORY_STATE_BLOCK
    	    	Application calls this message from:

    	    	MSG_GEN_PROCESS_CLOSE_APPLICATION 

    	    	when app is being exited directly to DOS.
    	    	NCI_historyList and NCI_hotList are needed by the app
    	    	so that it can save the history list to state.
    	    	NCI_historyList and NCI_hotList need to be cleared so
    	    	that we won't come back up with an invalid handle. 

PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
RETURN:		cx  	= MemHandle of list block  	
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGetStateBlock		method dynamic NavigateControlClass, 
					MSG_NC_GET_STATE_BLOCK
    	clr 	cx
    	xchg	cx, ds:[di].NCI_historyList 	    	; handle of array

    ; check if both handles are valid handles
EC  <	jcxz	ecDone	 	    	    	    	    >
EC  <	xchg	bx, cx	    	    	    	    	    >
EC  <	call	ECCheckMemHandleNS    	    	    	    >
EC  <	xchg	bx, cx
EC  <ecDone:		    	    	    	    	    >
	ret
NCGetStateBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGoBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go back to previous entry we've linked from

CALLED BY:	MSG_NC_GO_BACK
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
RETURN:		none
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGoBack	method dynamic NavigateControlClass, 
					MSG_NC_GO_BACK
NAVIGATION_LOCALS
	.enter

    	mov 	cx, -1
    	call	NCIndexMoveRequest

	.leave
	ret
NCGoBack	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGoForward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go forward to the next entry that we've linked from

CALLED BY:	MSG_NC_GO_FORWARD
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #
RETURN:		none
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGoForward	method dynamic NavigateControlClass, 
					MSG_NC_GO_FORWARD
NAVIGATION_LOCALS
	.enter

    	mov 	cx, 1
    	call	NCIndexMoveRequest

	.leave
	ret
NCGoForward	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGetHistoryListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get moniker for a history list entry

CALLED BY:	MSG_NC_GET_HISTORY_LIST_MONIKER
PASS:		*ds:si	= NavigateControlClass object
		ds:di	= NavigateControlClass instance data
		ds:bx	= NavigateControlClass object (same as *ds:si)
		es 	= segment of NavigateControlClass
		ax	= message #

    	    	^lcx:dx	= OD of list requesting
    	    	bp  	= position of list entry
RETURN:		nothing
DESTROYED:  	bx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGetHistoryListMoniker	method dynamic NavigateControlClass, 
					MSG_NC_GET_HISTORY_LIST_MONIKER

EC  <	call	AssertIsNavController  	    	    	    	    >

    	pushdw	cxdx	      	    	    	; the "list" optr
    	push	bp  	    	    	    	; the position

    	; lock the history array
    	call	NCLockHistoryArray
    	; *ds:si = array

    	; get the text for the bp-th entry FROM THE END
    	; since the most updated entry is at the top
    	call	ChunkArrayGetCount  	    	; cx = # of entries
EC  <	tst 	cx	    	    	    	    	    	 >
EC  <	ERROR_Z	NAV_CONTROL_CHUNK_ARRAY_CONTAINS_NO_ELEMENTS   	 >
    	dec 	cx
    	sub 	cx, bp  	    	    	; cx = # of from end
    	
    	; could get stray messages from previous lists
    	jns 	okay
    	pop 	bp  	    	    	    	; the position
    	popdw	bxsi	    	    	    	; the "list" optr
    	jmp 	done

okay:
    	mov 	ax, cx	    	    	    	; ax = entry # to get
    	call	ChunkArrayElementToPtr
    	; ds:di	= element, cx = elementSize
EC  <	ERROR_Z	NAV_CONTROL_CHUNK_ARRAY_OUT_OF_BOUNDS	    	>
    	
    	; get the ptr of the text
    	mov 	di, ds:[di].NLE_moniker	    	
    	mov 	cx, ds
    	mov 	dx, ds:[di] 	    	    	; cx:dx = ptr to text

    	; set the entry in the list
    	pop 	bp  	    	    	    	; the position
    	popdw	bxsi	    	    	    	; the "list" optr
    	mov 	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
    	mov 	di, mask MF_CALL
    	call	ObjMessage

done:
    	; unlock the history array
    	call	NCUnlockHistoryArray

	ret
NCGetHistoryListMoniker	endm

;--------------------------------------------------------------------------
;   	Class procedures
;--------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCCheckMainPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to check to see if we are at the main page index

CALLED BY:	NCGoBack, NCGoForward, NCSetPrevNextTriggersStates
PASS:		ax  	= NotifyNavContextChangeFlags
RETURN:		ax  	= with NNCCF_displayMain either set or not
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCCheckMainPage	proc	near
    	call	NCGetIndex  	    	    ; bx = index
    	tst 	bx
    	jnz  	done
    	or  	ax, mask NNCCF_displayMain
done:
	ret
NCCheckMainPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCIndexMoveRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for after moving an index

CALLED BY:	NCGoForward, NCGoBack
PASS:		*ds:si	= a NavigateControlClass Object
    	    	cx  	= -1 moving backward
    	    	    	=  1 moving forward
RETURN:		none
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCIndexMoveRequest	proc	near
class	NavigateControlClass
NAVIGATION_LOCALS
	.enter inherit

EC  <	call	AssertIsNavController	    	    	    >

    	call	NCGetToolBlockAndToolFeaturesLocals
    	call	NCGetChildBlockAndFeaturesLocals

    	; get index into history array for context we're switching to 
    	call	NCMoveIndexForward	    ; go back/forward by one entry
    	; cx = new entry #

    	push	cx
    	call	NCGotoHistoryEntry  	    ; goto that entry
    	pop 	cx

    	clr 	ax  	    	    	    ; flags
    	; want to check if we are back to the first entry, if so, then
	; we also want to disable the main page trigger

    	tst 	cx  	    	    	    ; first entry?
    	jnz 	notFirstIndex
    	BitSet	ax, NNCCF_displayMain

notFirstIndex:
    	call	NavigateSendNotification
	.leave
	ret
NCIndexMoveRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGotoHistoryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to go to a history entry

CALLED BY:	NCGotoHistory, NCGoBack
PASS:		*ds:si	= controller
    	    	ss:bp	= inherited locals
    	    	    	childBlock = handle of child block
    	    	cx  	= history # to go to
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGotoHistoryEntry	proc	near
    	uses	bp
NAVIGATION_LOCALS
	.enter inherit
EC  <	call	AssertIsNavController	    	    	    >

    	; get the context & file
    	call	NCGetHistoryEntry

    	; display the text here
   	call	NCSendDisplayToOutput

	.leave
	ret
NCGotoHistoryEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCSendDisplayToOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sending a display to the output object

CALLED BY:	GotoHistoryEntry
PASS:		ds:si	= a NavigateControlObject
    	    	ss:bp	= inherited locals
RETURN:		nothing
DESTROYED:	ax, cx, bx, dx, es, di  
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCSendDisplayToOutput	proc	near
NAVIGATION_LOCALS
	.enter inherit

EC  <	call	AssertIsNavController	    	    	    >
    	; here, we need to create a block that would hold all of the
	; information contained in a history list entry

    	mov 	ax, (size NavigateHistoryListInfo)
    	mov 	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or \
    	    	    (mask HAF_ZERO_INIT shl 8)
    	call	MemAlloc    
    	mov 	es, ax	    ; seg addr of new block

    	pushdw	dssi
    	segmov 	ds, ss, ax

    	mov 	di, offset NHLI_moniker     ; moniker name
    	lea 	si, ss:moniker
    	call	NCStringCopy

    	mov 	ax, ss:selector	    	    ; selector chunk    
    	mov 	es:[NHLI_selector], ax	
    	popdw	dssi

    	; send it over to output
    	mov 	bp, bx	    	    ; handle of block
    	mov 	cx, NSTOT_BLOCK	    ; we are sending a block
    	mov 	dx, GWNT_NAVIGATE_ENTRY_CHANGE
    	call	NCSendToOutput

	.leave
	ret
NCSendDisplayToOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCSendDeleteToOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the deleted entry information to output

CALLED BY:	NCDeleteHistory
PASS:		^lbx:si -- optr of NavController
    	    	ds:di -- ptr to the chunk array entry
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCSendDeleteToOutput	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

    	push	bx,si  	    	    	    ; optr of nav controller

    	mov 	ax, (size NavigateHistoryListInfo)
    	mov 	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or \
    	    	    (mask HAF_ZERO_INIT shl 8)
    	call	MemAlloc    
    	mov 	dx, bx	    ; handle of block
    	mov 	es, ax	    ; seg addr of new block

    	mov 	ax, ds:[di].NLE_selector    ; copy the selector info
    	mov 	es:[NHLI_selector], ax	    ; to block

    	mov 	si, ds:[di].NLE_moniker	    ; copy the moniker info
    	mov 	si, ds:[si] 	    	    ; deref
    	mov 	di, offset NHLI_moniker	    ; to block
    	call	NCStringCopy

    	pop 	bx,si	    	    	    ; optr of nav controller

   	call	MemDerefDS
EC  <	call	AssertIsNavController	    	    	    >

    	mov 	bp, dx	    	    	    ; handle of block
    	mov 	cx, NSTOT_BLOCK	    	    ; we are sending a block
    	mov 	dx, GWNT_NAVIGATE_DELETE_ENTRY
    	call	NCSendToOutput

	.leave
	ret
NCSendDeleteToOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGetHistoryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the nth history entry

CALLED BY:	UTILITY
PASS:		*ds:si	= controller
    	    	ss:bp	= inherited locals
    	    	cx  	= # of history entry to get
RETURN:		ss:bp	= inherited locals
    	    	    	filename    
    	    	    	context
    	    	    	selector
DESTROYED:	ax, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGetHistoryEntry	proc	near
	uses	ds, si, cx
NAVIGATION_LOCALS
	.enter inherit

    	call	NCLockHistoryArray

    	mov 	ax, cx	    	    	    ; history #
    	call	ChunkArrayElementToPtr	   
EC  <	ERROR_C	NAV_CONTROL_CHUNK_ARRAY_OUT_OF_BOUNDS    >
    	mov 	si, di	    	    	    ; ds:si = ptr to element
    
    	segmov	es, ss, ax
    	lea 	di, ss:moniker	    	    ; es:di = destination
    	mov 	cx, ds:[si].NLE_moniker	    ; cx = chunk of name
    	call	getHistoryName

    	mov 	cx, ds:[si].NLE_selector    ; selectorChunk
    	mov 	{word} ss:selector, cx	

    	call	NCUnlockHistoryArray

    	.leave
EC  <	call	AssertIsNavController	    	    >
    	ret

;----------------------------------------------------------------------
;
;   getHistoryName
;
;   PASS:   *ds:cx  = name to copy
;   	    es:di   = dest buffer
;----------------------------------------------------------------------
getHistoryName:
    	tst 	cx  	    	    	; no chunk
    	jz  	done
    	push	si
    	mov 	si, cx	    	    	; *ds:si = name
    	mov 	si, ds:[si] 	    	; ds:si = ptr to name
    	ChunkSizePtr	ds, si, cx  	; cx = # of bytes
    	rep 	movsb	    	    	; copy
    	pop 	si
done:
    	retn
NCGetHistoryEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGetHistoryCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of items in the history array

CALLED BY:	UTILITY
PASS:		*ds:si	= a NavigateControlClass object
RETURN:		cx  	= # of items in history
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGetHistoryCount	proc	near
class	NavigateControlClass
	uses	bx
	.enter

EC  <	call	AssertIsNavController	    	    	    >
    	push	ds:[LMBH_handle], si

    	call	NCLockHistoryArray  	    	; *ds:si = array    

    	call	ChunkArrayGetCount

    	call	NCUnlockHistoryArray

    	pop 	bx, si
    	call	MemDerefDS

	.leave
	ret
NCGetHistoryCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCInitializeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the history popup list

CALLED BY:	NCRedrawHistoryList
PASS:		*ds:si	= a NavigateControlClass object
    	    	cx  	= # of items in history list
RETURN:		none
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCInitializeList	proc	near
class	NavigateControlClass
	uses	cx,si
	.enter
EC  <	call	AssertIsNavController	    	    	    >

    	; make sure the list won't get too large
    	cmp 	cx, MAXIMUM_HISTORY_ENTRIES 	; too many entries? 	    
    	jbe 	lengthOK
    	mov 	cx, MAXIMUM_HISTORY_ENTRIES 	; set to maximum

lengthOK:
    	mov 	di, ds:[si]
    	add 	di, ds:[di].NavigateControl_offset
    	mov 	bx, ds:[di].NCI_historyBlock
    	mov 	si, offset  NavigateHistoryList	; ^lbx:si = "list"
EC  <	call	ECCheckOD   	    	    	    	    >
    	mov 	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
    	call	NCObjMessageCheckAndSend

	.leave
	ret
NCInitializeList    endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCGetIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the NCI_gobackIndex instance

CALLED BY:	UTILITY
PASS:		*ds:si	= a NavigateControlClass object
RETURN:		bx  	= index
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCGetIndex	proc	near
class	NavigateControlClass

EC  <	call	AssertIsNavController	    	    	    >

    	mov 	bx, ds:[si]
    	add 	bx, ds:[bx].NavigateControl_offset
    	mov 	bx, ds:[bx].NCI_index

	ret
NCGetIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCSetIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set NCI_gobackIndex instance

CALLED BY:	UTILITY
PASS:		*ds:si	= a NavigateControlClass object
    	    	bx  	= index
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCSetIndex	proc	near
class	NavigateControlClass
	uses	si
	.enter

EC  <	call	AssertIsNavController	    	    	    >

    	mov 	si, ds:[si]
    	add 	si, ds:[si].NavigateControl_offset
    	mov 	ds:[si].NCI_index, bx

	.leave
	ret
NCSetIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCMoveIndexForward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the history array index corresponding to the
    	    	context we're switching to if the user pressed "go
    	    	back"  Also decrements the goback array index iff cx > 0 

CALLED BY:	NCNavigateGoBack, NCRedrawHistoryList
PASS:		*ds:si	= a NavigateControlClass object
    	    	cx  	= 0 if should NOT decrement goback index
    	    	    	= -1 decrement it
    	    	    	= 1 increment it
RETURN:		cx  	= history index
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCMoveIndexForward	proc	near
class	NavigateControlClass
	uses	bx
	.enter
EC  <	call	AssertIsNavController	    	    	    >
    	call	NCGetIndex    	    ; bx = gobackIndex

    	cmp 	cx, 0
    	jns  	increment   	    ; not negative

EC  <	jcxz	ecDone		    	    	    	    >
EC  <	cmp 	bx, 0  	    	    	    	    	    >
EC  <	ERROR_LE    ARRAY_INDEX_CANNOT_GO_BACK 	    	    > 	
EC  <ecDone:	    	    	    	    	    	    >

    	dec 	bx
    	jmp 	done

increment:
    	; add some EC code here to check for maximum

    	jcxz	done
    	inc 	bx

done:
    	call	NCSetIndex
    	mov 	cx, bx
	.leave
	ret
NCMoveIndexForward	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCRedrawHistoryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redisplays the history list

CALLED BY:	NavigationReceiveNotification
PASS:		*ds:si	= a NavigateControlClass object
    	    	ss:bp	= inherit locals
    	    	    childBlock
    	    	    toolBlock
    	    	    features
    	    	    toolFeatures
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCRedrawHistoryList	proc	near
class	NavigateControlClass
	uses	ax
NAVIGATION_LOCALS
	.enter	inherit

 EC  <	call	AssertIsNavController	    	    	    	>

    	call	NCGetHistoryCount   	    	; cx = # entries
    	call	NCInitializeList

    	; get the go back index - we want to select that item in the
	; list
    	mov 	dx, cx
    	clr 	cx  	    	    	    	; don't dec goback index
    	call	NCMoveIndexForward	    	; cx = history entry #

    	; calculate the list entry number from the history entry
	; number
    	cmp 	cx, -1	    	    	    	; no go back index?
    	je  	done
    	xchg	cx, dx
    	sub 	cx, dx
    	dec 	cx  	    	    	    	; list entry to select

    	; set the lists' selection
    	call	NCSetHistoryListSelection
done:
	.leave
	ret
NCRedrawHistoryList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCSetHistoryListSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selection in the history list

CALLED BY:	INTERNAL
PASS:		*ds:si 	= a NavigateControlClass object
    	    	cx  	= list entry to select
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCSetHistoryListSelection	proc	near
class	NavigateControlClass
	uses	si
	.enter
EC  <	call	AssertIsNavController	    	    	    	>

    	mov 	di, ds:[si]
    	add 	di, ds:[di].NavigateControl_offset
    	mov 	bx, ds:[di].NCI_historyBlock
    	mov 	si, offset  NavigateHistoryList   ; ^lbx:si = "list"

EC  <	call	ECCheckOD   	    	    	    	    	>
    	mov 	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
    	clr 	dx  	       	    	    ; not indeterminate
      	call	NCObjMessageCheckAndSend

	.leave
	ret
NCSetHistoryListSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCRecordHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the current filename and context for history

CALLED BY:	NCUpdateHistoryForLink
PASS:		*ds:si - controller
		ss:bp - inherited locals
			filename - name of help file
			context - name of context
    	    	    	selector - the selector string
			childBlock - handle of child block
			features - features that are on
RETURN:		cx - element number of new history item
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	acham	9/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCRecordHistory		proc	near
	uses	di, es
NAVIGATION_LOCALS
	.enter	inherit
EC <	call	AssertIsNavController			>

	push	ds:[LMBH_handle], si

	; Delete a history entry if necessary, to make room for this entry
	call	NCDeleteHistory

	; Add a new entry
	call	NCLockHistoryArray
	mov	ax, (size NavigateListElement)
	call	ChunkArrayAppend	;ds:di <- ptr to new entry
	call	ChunkArrayPtrToElement		;ax <- entry #
	push	ax

	; Allocate chunks for the names and copy them in
	lea	di, ss:moniker			;ss:di <- ptr to context
	call	allocCopy
	mov	cx, ax				;cx <- chunk of context

    	mov 	dx, ss:selector	    	    	; selectorChunk
	pop	ax				;ax <- entry #

	call	ChunkArrayElementToPtr		;ds:di <- ptr to entry
EC <	ERROR_C	NAV_CONTROL_CHUNK_ARRAY_OUT_OF_BOUNDS	;>
	mov	ds:[di].NLE_moniker, cx
    	mov 	ds:[di].NLE_selector, dx
	mov	cx, ax				;return entry # in cx

	; Unlock the history array
	call	NCUnlockHistoryArray
	pop	bx, si
	call	MemDerefDS

	.leave
EC <	call	AssertIsNavController			>
	ret

;---------------------------------------------------------------------------
; allocate a chunk and copy a name into it
; pass:
;	ds - seg addr of block
;	ss:di - ptr to name
; return:
;	ax - chunk of name
;---------------------------------------------------------------------------
allocCopy:
	push	si, cx
	segmov	es, ss				;es:di <- ptr to name
	call	LocalStringSize			;cx <- size of string
						;(w/o null) 
	LocalNextChar	escx			;cx <- advance 1 char
						;for null
	mov	al, mask OCF_DIRTY		;JM6/7: set the ObjChunkFlags
	call	LMemAlloc
	segxchg	ds, es
	mov	si, di				;ds:si <- ptr to name
	mov	di, ax				;*es:di <- new chunk
	mov	di, es:[di]			;es:di <- ptr to chunk
	rep	movsb				;copy cx bytes
	pop	si, cx
	segmov	ds, es				;ds <- (new) seg addr of array
EC <	push	ax				;>
EC <	mov	ax, 0xa000			;>
EC <	mov	es, ax				;>
EC <	pop	ax				;>
	retn
NCRecordHistory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCDeleteHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get and delete the oldest history entry (first one in array)
		if history array is full

CALLED BY:	NCRecordHistory
PASS:		*ds:si - controller
RETURN:		nothing
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY::
	name	date		description
	----	----		-----------
	gene	12/14/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCDeleteHistory		proc	near
class	NavigateControlClass
	uses	ax, bx, cx, di, bp
	.enter

EC <	call	AssertIsNavController				>
	push	ds:[LMBH_handle], si

	; Check if the go back index is somewhere down the history
	; list.  If so, we want to delete all entries after that, so
	; that it is the most recent entry.
	call	NCGetIndex		;bx <- gobackIndex

	call	NCLockHistoryArray  	    	; *ds:si = array
	call	ChunkArrayGetCount		;cx <- # entries
    	clr 	bp	    	    	    	; bp = tmp variable
	jcxz	done				;no entries? nothing
						; to delete
	dec	cx				;count from 0
	mov	dx, cx				;save count in dx
	cmp	bx, cx				;are we at most recent?
	je	noDelete			;yes, don't delete any
	sub	cx, bx				;cx <- # to delete

beforeDelete:
    	mov 	bp, cx	    	    	    	; remember # to delete
EC <	ERROR_C NAV_CONTROL_INVALID_NUMBER_TO_DELETE	    >

delete:		
	mov	ax, dx				;element # to delete
	call	ChunkArrayElementToPtr		;ds:di <- ptr to entry
EC <	ERROR_C	NAV_CONTROL_CHUNK_ARRAY_OUT_OF_BOUNDS	    >

    	mov 	ax, si	    	    	    	; chunk of chunk array

    	pop 	bx, si 	    	    	    	; optr of NavController
    	call	NCSendDeleteToOutput
    	push	bx, si	    	    	    	; optr of NavController

    	mov 	si, ax	    	    	    	; chunk of chunk array

	; delete any associated data
	mov	ax, ds:[di].NLE_moniker
	call	deleteChunk

	; delete the entry itself
	call	ChunkArrayDelete
	dec	dx
    
	loop	delete
		
done:
	call	NCUnlockHistoryArray
	pop	bx, si
	call	MemDerefDS
EC <	call	AssertIsNavController			>

    	tst 	bp  	    ; do we need to delete list items??
    	jz  	skip

    	push	si  	    ; chunk of NavigateControl object
    	mov 	di, ds:[si]
    	add 	di, ds:[di].NavigateControl_offset
    	mov 	bx, ds:[di].NCI_historyBlock
    	mov 	si, offset NavigateHistoryList	    ; ^lbx:si = list
EC  <	call	ECCheckOD   	    	    	    	>
    	mov 	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
    	mov 	cx, GDLP_FIRST
    	mov 	dx, bp 	    ; # of elements just got deleted
    	call	NCObjMessageCheckAndSend
    	pop 	si  	    ; chunk of NavigateControl object
    
skip:
	.leave
	ret

noDelete:
    	; We didn't delete any entries, so the list might be full.
	; Check if we need to make room for one more.
	; cx = dx = # entries in list - 1 
	;
	cmp	cx, MAXIMUM_HISTORY_ENTRIES-1	;is list full?
	jb	done				;nope, we're done
	mov	cx, 1				;only 1x through loop
	jmp	beforeDelete			;delete last entry
		
deleteChunk:
	tst	ax				;any chunk?
	jz	skipDelete			;branch if no chunk
	call	LMemFree
skipDelete:
	retn
NCDeleteHistory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUpdateHistoryForLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to update history after a link

CALLED BY:	NCGotoHistory, NCUpdateNormalUI
PASS:		*ds:si	= a NavigateControlClass object
    	    	ss:bp	= inherited locals
    	    	    	filename = filename we're linking to
    	    	    	context = context we're linking to
    	    	    	childBlock = handle of child block
    	    	    	features = features that are on
RETURN:		nothing
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUpdateHistoryForLink	proc	near
	uses	ax
NAVIGATION_LOCALS
	.enter	inherit

EC  <	call	AssertIsNavController	    	    	    >

    	call	NCRecordHistory	    	; cx = # of new history entry
    	mov 	bx, cx
    	call	NCSetIndex

	.leave
	ret
NCUpdateHistoryForLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCFreeHistoryArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	free the history array, if any

CALLED BY:	NCFreeHistoryList 
PASS:		*ds:si	- a NavigateControlClass object
RETURN:		none
DESTROYED:	ax, bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCFreeHistoryArray	proc	near
class	NavigateControlClass
	uses	di
	.enter

EC  	    <	call	AssertIsNavController	    	    	    	>

    	mov 	di, ds:[si]
    	add 	di, ds:[di].NavigateControl_offset
    
    	clr 	bx
    	xchg	bx, ds:[di].NCI_historyList 	; handle of array

    	; check if there was any preivous entries for the arrays
    	; if so, we call MemFree, otherwise we don't do anything
    	tst 	bx  	    	    	    
    	jz  	noFree

EC  <	call	ECCheckMemHandleNS  	    	    	    	    	>
    	call	MemFree

noFree:
    	.leave
	ret
NCFreeHistoryArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCLockHistoryArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock an array, allocating it if necessary

CALLED BY:	NCGetListMoniker
PASS:		*ds:si 	= a NavigateControllerClass object
RETURN:		*ds:si	= array
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		(1) Determine which array to lock
    	    	(2) Lock it/allocating it if necessary

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCLockHistoryArray	proc	near
class	NavigateControlClass
	uses	ax,bx,cx,dx
	.enter
EC  <	call	AssertIsNavController	    	    	    >

    	; see if we have already allocated an array
    	mov 	si, ds:[si]
    	add 	si, ds:[si].NavigateControl_offset
    	mov 	bx, ds:[si].NCI_historyList    	; handle of list arrays

    	tst 	bx  	    	    	    	; array allocated?
    	jnz 	allocated

    	; allocate a block for the array
    	; want history to be saved to state
    	mov 	ax, LMEM_TYPE_OBJ_BLOCK	    	; lmemtype
    	clr 	cx  	    	    	    	; lmem size header
    	call	MemAllocLMem	    	    	; bx = block handle

    	; assign block handle to the instance data
    	mov 	ds:[si].NCI_historyList, bx

    	; create the array
    	call	MemLock
EC <	ERROR_C	NAV_CONTROL_BAD_BLOCK_TO_LOCK	    	>
    	; ax = segment of block

    	; creating the list array
    	mov 	ds, ax
    	mov 	bx, (size NavigateListElement)
    	clr 	cx  	    	    	    	; standard size header
    	clr 	si  	    	    	    	; allocating a chunk
    	mov 	al, mask OCF_DIRTY  	    	; ObjChunkFlags
    	call	ChunkArrayCreate    
EC  <	ERROR_C	NAV_CONTROL_CHUNK_ARRAY_CANNOT_ALLOCATE	    	>
EC  <	cmp 	si, NAVIGATE_HISTORY_LIST_CHUNK	; 1st handle?	>
EC  <	ERROR_NE    NAV_CONTROL_BUFFER_NOT_EMPTY    	    	>
    	jmp 	done

allocated:
EC  <	call	ECCheckMemHandleNS  	    	    	    	>
    	call	MemLock
    	mov 	ds, ax
    	mov 	si, NAVIGATE_HISTORY_LIST_CHUNK	; history list array

done:
	.leave
	ret
NCLockHistoryArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCUnlockHistoryArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the history array

CALLED BY:	
PASS:		ds - seg addr of array
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCUnlockHistoryArray	proc	near
	uses	bx
	.enter

    	mov 	bx, ds:LMBH_handle
    	call	MemUnlock

	.leave
	ret
NCUnlockHistoryArray	endp

NavigateControlCode	ends


