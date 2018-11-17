COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inboxApplicationList.asm

AUTHOR:		Adam de Boor, Jun  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 3/94		Initial revision


DESCRIPTION:
	
		

	$Id: inboxApplicationList.asm,v 1.1 97/04/05 01:20:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS		; ENTIRE FILE IS A NOP UNLESS THIS IS TRUE

MailboxClassStructures	segment	resource
	InboxApplicationListClass
MailboxClassStructures	ends

InboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IALGetApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the application the user has selected.

CALLED BY:	MSG_IAL_GET_APPLICATION
PASS:		cx	= application index
RETURN:		carry clear if found
			cxdxbp	= GeodeToken
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IALGetApplication	method dynamic InboxApplicationListClass, 
					MSG_IAL_GET_APPLICATION

	;
	; Get elt # in app token array.
	;
	call	IALMapItemNumToEltNum	; CF set if found, ax = elt #
	cmc				; CF clear if found
	jc	unlock			; jump if not found

	;
	; Get GeodeToken of the app token.
	;
	call	ChunkArrayElementToPtr	; ds:di = InboxAppData, CF clear
	movdw	dxcx, ds:[di].IAD_token.GT_chars
	mov	bp, ds:[di].IAD_token.GT_manufID	; cxdxbp = GeodeToken

unlock:
	GOTO	UtilVMUnlockDS		; unlock token array (flags preserved)

IALGetApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IALMapItemNumToEltNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	(INTERNAL)
PASS:		cx	= item # of application within app list
RETURN:		*ds:si	= token array (must be unlocked by caller)
		carry set if found
			ax	= element # of application token in token array
		carry clear if not found
			ax	= CA_NULL_ELEMENT
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IALMapItemNumToEltNum	proc	near
	uses	bx, di
	.enter

	call	IATGetTokenArray	; *ds:si = token array
	mov	ax, cx			; ax = item #
	mov	bx, SEGMENT_CS
	mov	di, offset IALCheckIfAppHasMessages
	call	ElementArrayUsedIndexToToken	; CF set if found, ax = elt #

	.leave
	ret
IALMapItemNumToEltNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IALCheckIfAppHasMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if application that token represents has messages in inbox.

CALLED BY:	(INTERNAL)
PASS:		ds:di	= InboxAppData
RETURN:		carry set if app has messages pending (ref count >= 2)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The reference count of a bound alias cannot be >= 2.  So we can safely
	skip checking whether the token is a bound alias.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IALCheckIfAppHasMessages	proc	far

	; There should be no free element in array since we never remove
	; tokens
	Assert	ne, ds:[di].IAD_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT

	;
	; Instead of comparing WAAH_high with 0 and do "ja", we compare it
	; with 1 and do "jae" such that carry flag will be exactly opposite
	; of what we want.
	;
	cmp	ds:[di].IAD_meta.REH_refCount.WAAH_high, 1
	jae	done
	cmp	ds:[di].IAD_meta.REH_refCount.WAAH_low, 2
done:
	cmc				; CF set if count >= 2

if ERROR_CHECK
	; Make sure if ref count >= 2, it cannot be a bound alias
	jnc	EC_done			; okay if ref count < 2
	test	ds:[di].IAD_flags, mask IAF_IS_ALIAS
	jz	EC_setCarry		; okay if not alias
	Assert	e, ds:[di].IAD_nameRef, IAD_UNKNOWN	; die if alias is bound
EC_setCarry:
	stc
EC_done:
endif

	ret
IALCheckIfAppHasMessages endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IALSetApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the application we've selected for the user.

CALLED BY:	MSG_IAL_SET_APPLICATION
PASS:		*ds:si	= InboxApplicationListClass object
		ds:di	= InboxApplicationListClass instance data
		cxdxbp	= GeodeToken (bp = INBOX_TOKEN_NUM_ALL if select "All")
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IALSetApplication	method dynamic InboxApplicationListClass, 
					MSG_IAL_SET_APPLICATION

	cmp	bp, INBOX_TOKEN_NUM_ALL
	je	selectAll

	;
	; Get elt # of token in token array.
	;
	push	ds, si, di
	push	bp, dx, cx		; ss:sp = GeodeToken
	movdw	esdx, sssp
	call	IATFindTokenInArray	; ax = elt #, *ds:si = array
	add	sp, size GeodeToken
	mov	bp, ax			; bp = elt #

	;
	; Get item # of the application in list (same as used index in token
	; array)
	;
	mov	bx, SEGMENT_CS
	mov	di, offset IALCheckIfAppHasMessages
	call	ElementArrayTokenToUsedIndex	; ax = used index
	call	UtilVMUnlockDS		; unlock token map
	mov_tr	cx, ax			; cx = item # in app list
	pop	ds, si, di		; *ds:si = self, ds:di = instance data

setSelection:
	;
	; Send message to ourselves.
	;
	mov	ds:[di].IALI_selectedTokenNum, bp
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	GOTO	ObjCallInstanceNoLock

selectAll:
	;
	; Get item # of "All".
	;
	    CheckHack <GenDynamicList_offset eq InboxApplicationList_offset>
	mov	cx, ds:[di].GDLI_numItems
	Assert	ne, cx, 0		; there must be some items
	dec	cx			; cx = item # of "All"
	jmp	setSelection

IALSetApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IALGenApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A new selection has been made in the application list

CALLED BY:	MSG_GEN_APPLY
PASS:		*ds:si	= InboxApplicationListClass object
		ds:di	= InboxApplicationListClass instance data
		es 	= segment of InboxApplicationListClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IALGenApply	method dynamic InboxApplicationListClass, 
					MSG_GEN_APPLY

	push	ax
	push	ds, si, di

	;
	; Get elt # of GeodeToken of newly selected app.
	;
	mov	cx, ds:[di].GIGI_selection
	Assert	ne, cx, GIGS_NONE
	call	IALMapItemNumToEltNum	; *ds:si = token array, ax = elt #
	call	UtilVMUnlockDS		; flags preserved
	jc	store			; jump if "All" is not selected

	;
	; "All" is selected.  Store INBOX_TOKEN_NUM_ALL in elt num
	;
		CheckHack <INBOX_TOKEN_NUM_ALL eq CA_NULL_ELEMENT - 1>
	dec	ax			; ax = INBOX_TOKEN_NUM_ALL

store:
	;
	; Record it.
	;
	pop	ds, si, di		; *ds:si = ds:di = self
	mov	ds:[di].IALI_selectedTokenNum, ax

	pop	ax
	mov	di, offset InboxApplicationListClass
	GOTO	ObjCallSuperNoLock

IALGenApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IALRebuildList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rebuild the list of possible applications.

CALLED BY:	MSG_IAL_REBUILD_LIST
PASS:		*ds:si	= InboxApplicationListClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IALRebuildList	method dynamic InboxApplicationListClass, MSG_IAL_REBUILD_LIST

	;
	; Find # of applications that has messages.
	;
	pushdw	dssi
	call	IATGetTokenArray	; *ds:si = array
	mov	bx, SEGMENT_CS
	mov	di, offset IALCheckIfAppHasMessages
	call	ElementArrayGetUsedCount	; ax = # of apps having msgs

	;
	; Init display.
	;
	segmov	es, ds			; es = app token map
	popdw	dssi			; *ds:si = self
	mov_tr	cx, ax			; cx = # of apps that have messages
	push	cx
	inc	cx			; add one for "All" selection
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ObjCallInstanceNoLock
	pop	cx			; cx = item # of "All" (same as # of
					;  apps that have messages)

	;
	; Select the first item (which maybe "All") if nothing was selected
	; before.
	;
	clr	dx			; assume no apply needed

	pushdw	dssi
	mov	si, ds:[si]
	add	si, ds:[si].InboxApplicationList_offset
	mov	ax, ds:[si].IALI_selectedTokenNum
	segmov	ds, es			; ds = app token map
		CheckHack <CA_NULL_ELEMENT eq 0xffff>
	inc	ax
	jz	selectFirst

	;
	; Select "All" if it was previously selected.
	;
		CheckHack <INBOX_TOKEN_NUM_ALL eq CA_NULL_ELEMENT - 1>
	inc	ax
	jz	setSelection		; jump if "All" should be selected

	;
	; See if the previously selected item still has messages.  (We have
	; to do it ourselves because ElementArrayTokenToUsedIndex doesn't
	; return an error even if the token is "not used".)  If not, select
	; the first item.
	;
	dec	ax
	dec	ax			; ax = elt # of token
	mov	si, ds:[ITMH_meta].LMBH_offset	; *ds:si = token array
	call	ChunkArrayElementToPtr	; ds:di = InboxAppData
	call	IALCheckIfAppHasMessages	; CF set if app has mesgs
	jnc	selectFirst

	;
	; Else, find the item # of the app that was previously selected.
	;
	mov	di, offset IALCheckIfAppHasMessages
	call	ElementArrayTokenToUsedIndex	; ax = item #
	mov_tr	cx, ax

setSelection:
	call	UtilVMUnlockDS		; unlock token array
	popdw	dssi
	push	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjCallInstanceNoLock

	pop	cx			; cx <- non-z if apply needed
	jcxz	done

	;
	; Force apply message to be sent.
	;
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cx, TRUE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_APPLY
	GOTO	ObjCallInstanceNoLock

done:
	ret

selectFirst:
	clr	cx
	dec	dx			; flag apply needed
	jmp	setSelection

IALRebuildList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IALGenDynamicListQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the moniker for one of our entries

CALLED BY:	MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
PASS:		*ds:si	= InboxApplicationListClass object
		ds:di	= InboxApplicationListClass instance data
		bp	= the position of the item requested
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IALGenDynamicListQueryItemMoniker	method dynamic \
	InboxApplicationListClass, MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER

	push	bp			; save position of item

	;
	; This is the "All" item if it's the last item in the list.
	;
	mov	cx, bp			; cx = position of item
	inc	bp
	cmp	bp, ds:[di].GDLI_numItems
	je	useAllMoniker

	;
	; Get elt # in app token array.
	;
	mov	ax, MSG_IAL_GET_APPLICATION
	call	ObjCallInstanceNoLock	; cxdxbp = GeodeToken
	;
	; Sometimes because of timing problem, the messages of an app token
	; may have all been deleted before the QUERY_ITEM_MONIKER is
	; processed.  If the desired token was not the last used token in the
	; array, we have just got some wrong token from
	; MSG_IAL_GET_APPLICATION.  We will use the wrong token to get the app
	; name anyway (which doesn't hurt, since more list-update messages
	; later will replace this wrong moniker).  If the desired token was
	; the last used token in the array, however, we must have just gotten
	; an error here.  Then we simply ignore this QUERY_ITEM_MONIKER
	; message.	--- AY 3/1/95
	;
	jc	ignore

	;
	; Get name of app.  We have to call InboxGetAppName instead of looking
	; into the name array ourselves because we want it to perform any
	; necessary rescans.
	;
	; We don't want to create the name in the token map block since we
	; want to avoid making it dirty.  So we create the name in the object
	; block.  But then we cannot use MSG_..._REPLACE_ITEM_TEXT since it
	; takes a fptr and the name chunk might move while the list object is
	; building the moniker.
	;
	mov	bx, cx
	mov	cx, dx
	mov	dx, bp			; bxcxdx = GeodeToken
	call	InboxGetAppName		; *ds:ax = app name

	;
	; Fill in ReplaceItemMonikerFrame.  The position of item (RIMF_item)
	; is already pushed on stack, so we allocate one word fewer space now.
	;

	; Make sure RIMF_item is the last member in ReplaceItemMonikerFrame
CheckHack <(offset RIMF_item + size RIMF_item) eq size ReplaceItemMonikerFrame>
	sub	sp, offset RIMF_item	; push the rest of the frame
	mov	bp, sp			; ss:bp = ReplaceItemMonikerFrame
	mov	ss:[bp].RIMF_source.low, ax
	mov_tr	di, ax			; di = lptr of app name chunk
	mov	ax, ds:[OLMBH_header].LMBH_handle
	mov	ss:[bp].RIMF_source.high, ax
	mov	ss:[bp].RIMF_sourceType, VMST_OPTR
	mov	ss:[bp].RIMF_dataType, VMDT_TEXT
	clr	ss:[bp].RIMF_itemFlags

	;
	; Tell the list to use the moniker.
	;
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	mov	dx, size ReplaceItemMonikerFrame
	call	ObjCallInstanceNoLock
	add	sp, size ReplaceItemMonikerFrame

	;
	; Free the app name string
	;
	mov_tr	ax, di			; *ds:ax = app name string
	GOTO	LMemFree

useAllMoniker:
	;
	; Use "All" string
	;
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
	mov	cx, handle uiAllMoniker
	mov	dx, offset uiAllMoniker
	pop	bp			; bp = position of item
	GOTO	ObjCallInstanceNoLock
	; ---------------- proc normally returns here ------------------

ignore:
	pop	ax			; pop position of item to restore stack
	ret
IALGenDynamicListQueryItemMoniker	endm

InboxUICode	ends

endif	; _CONTROL_PANELS
