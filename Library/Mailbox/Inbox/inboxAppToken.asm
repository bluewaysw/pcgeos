COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inboxAppToken.asm

AUTHOR:		Adam de Boor, Jun  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 3/94		Initial revision


DESCRIPTION:
	Functions to maintain the token -> app name mapping
		

	$Id: inboxAppToken.asm,v 1.1 97/04/05 01:20:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InboxCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATEnsureTokenExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed token is in the app-token array

CALLED BY:	(INTERNAL) InboxNotifyNewIACPBinding,
			   InboxCheckAppUnknown
PASS:		bxcxdx	= GeodeToken
RETURN:		*ds:si	= app-token array
		ax	= element # of token
DESTROYED:	nothing
SIDE EFFECTS:	token added to array, if wasn't there before

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATEnsureTokenExists proc	near
	uses	bx, cx, dx
	.enter
	;
	; Allocate InboxAppData on stack and stuff in destApp token
	;
	mov	ax, IAD_UNKNOWN		; assume name unknown if new token
	push	ax			; push IAD_nameRef.IAN_name
	push	dx, cx, bx		; push IAD_token
	sub	sp, offset IAD_token	; ss:sp = InboxAppData
	mov	bx, sp
	clr	dl			; assume not alias if new token
	cmp	ax, MANUFACTURER_ID_GENERIC
	jne	notAlias		; not generic, hence not alias
	mov	dl, mask IAF_IS_ALIAS	; generic, hence alias
notAlias:
	; set alias flag.  We know nothing about IAF_DONT_QUERY_IF_FOREGROUND
	mov	ss:[bx].IAD_flags, dl

	;
	; Add the new token to token array
	;
	movdw	cxdx, sssp		; cx:dx = InboxAppData
	call	IATAddIADToTokenArray	; ax = elt #, *ds:si = array, CF
	jc	done
	;
	; Already existed, so remove the reference we just placed on the thing
	;
	clr	bx
	call	ElementArrayRemoveReference
done:
	add	sp, size InboxAppData
	.leave
	ret
IATEnsureTokenExists endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxNotifyNewIACPBinding
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note the binding of a token to an application, effectively
		as an alias for some other token.

CALLED BY:	(EXTERNAL) MainMailboxNotify
PASS:		bxcxdx	= GeodeToken (bx = GT_chars[0..1], cx = GT_chars[2..3],
			  dx = GT_manufID)
			  Token will be ignored if not MANUFACTURER_ID_GENERIC.
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	messages may have their tokens switched from the bound token
     			to the real application's token
		display panel may be brought up

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxNotifyNewIACPBinding proc	far
	uses	ds
	.enter

	;
	; Alias token must be of MANUFACTURER_ID_GENERIC.  If not, this is
	; an invalid alias, and we just ignore it.
	;
	cmp	dx, MANUFACTURER_ID_GENERIC
EC <	WARNING_NE MANUFACTURER_ID_GENERIC_MUST_BE_USED_FOR_ALIAS_TOKEN	>
	jne	notGeneric

	call	IATEnsureTokenExists

	;
	; Break old binding (if any) and mark it to be rescanned
	;
	call	ChunkArrayElementToPtr	; ds:di = InboxAppData of alias
	mov	ds:[di].IAD_flags, mask IAF_IS_ALIAS
					; turn off no-rescan flag
	mov	ds:[di].IAD_nameRef.IAN_aliasFor, IAD_UNKNOWN

	;
	; Get binding of this alias, get app name of real app, remap any
	; messages.
	;
	clr	dx
	call	IATUpdateTokenInArray	; dx = rebuild flag, ax += 1
	tst	dx
	jz	noRebuild
	call	IRSendRebuild
noRebuild:

	;
	; Cleanup
	;
	call	UtilVMDirtyDS
	call	UtilVMUnlockDS		; unlock app token map
	call	UtilUpdateAdminFile

notGeneric:
	.leave
	ret
InboxNotifyNewIACPBinding endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxNotifyRemoveIACPBinding
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the binding of an alias token to an application has
		been removed.

CALLED BY:	(EXTERNAL) MainMailboxNotify
PASS:		bxcxdx	= GeodeToken (bx = GT_chars[0..1], cx = GT_chars[2..3],
			  dx = GT_manufID)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	new messages for this token will be left unmapped.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxNotifyRemoveIACPBinding	proc	far
	uses	ds,es
	.enter

EC <	cmp	dx, MANUFACTURER_ID_GEOWORKS				>
EC <	WARNING_NE MANUFACTURER_ID_GENERIC_MUST_BE_USED_FOR_ALIAS_TOKEN	>

	;
	; Find this alias in token map
	;
	push	dx, cx, bx		; ss:sp = GeodeToken of alias
	movdw	esdx, sssp
	call	IATFindTokenInArray	; *ds:si = token array, ax = elt #
	jnc	done			; do nothing if not found

	;
	; Break the link to real app token in IAD
	;
	call	ChunkArrayElementToPtr	; ds:di = InboxAppData
	mov	ds:[di].IAD_nameRef.IAN_aliasFor, IAD_UNKNOWN
	call	UtilVMDirtyDS
	call	UtilUpdateAdminFile

done:
	add	sp, size GeodeToken
	call	UtilVMUnlockDS

	.leave
	ret
InboxNotifyRemoveIACPBinding	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATMatchTokenCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback used via ChunkArrayEnum to see if an app-token exists
		in token array

CALLED BY:	(INTERNAL)
PASS:		ds:di	= InboxAppData in array
		ax	= current elt #
		es:dx	= GeodeToken to search for
RETURN:		CF set if tokens match
			ax	= unchanged
		CF clear if tokens different
			ax	= incremented by 1
DESTROYED:	cx, si, di (bx, si, di allowed by ChunkArrayEnum)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATMatchTokenCallback	proc	far

	lea	si, ds:[di].IAD_token	; ds:si = GeodeToken of elt in array
	mov	di, dx			; es:di = GeodeToken to search for
		CheckHack <(size GeodeToken and 1) eq 0>
	mov	cx, size GeodeToken / 2
	repe	cmpsw
	stc				; assume match
	je	done
	inc	ax
	clc				; tokens not match

done:
	ret
IATMatchTokenCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxNotifyAppLoaded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that an application has been loaded or changed state

CALLED BY:	(EXTERNAL) MainMailboxNotify
PASS:		bxcxdx	= GeodeToken (bx = GT_chars[0..1], cx = GT_chars[2..3],
			  dx = GT_manufID)
		ah	= IACPServerFlags
		al	= IACPServerMode
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	display panel may be brought up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxNotifyAppLoaded proc	far

	;
	; Do nothing if not user interactible
	;
	cmp	al, IACPSM_USER_INTERACTIBLE
	je	interactible
	ret

interactible:
	uses	ds, es
	.enter

	;
	; Allocate InboxAppData on stack.
	;
	mov	di, IAD_UNKNOWN
	push	di			; push IAD_nameRef.IAN_name
	push	dx, cx, bx		; push IAD_token
	sub	sp, offset IAD_token	; ss:sp = InboxAppData
	mov	dx, sp

	;
	; If IACPSF_MAILBOX_DONT_ASK_USER is not set, don't add token to
	; array.  Just see if token already exists and there are any messages
	; pending.  Display app panel if so.
	;
	test	ah, mask IACPSF_MAILBOX_DONT_ASK_USER
	jnz	noQueryApp
	mov	cx, 1			; blcx = 1 (ref count = 1, fake that
	mov	bl, ch			;  token exists but there's no message)
	segmov	es, ss			; es:dx = InboxAppData of app
	add	dx, offset IAD_token	; es:dx = GeodeToken of app
	call	IATFindTokenInArray	; CF set if found, ax = elt #
	jnc	checkRefCount		; jump if not found, leave count = 1
	call	ChunkArrayElementToPtr	; ds:di = IAD
	mov	cx, ds:[di].IAD_meta.REH_refCount.WAAH_low
	mov	bl, ds:[di].IAD_meta.REH_refCount.WAAH_high	; blcx = count
	jmp	checkRefCount

noQueryApp:
	;
	; IACPSF_MAILBOX_DONT_ASK_USER is set.  Add app token to token map if
	; not already exist.
	;
	mov	cx, ss			; cx:dx = InboxAppData
	push	ax			; save IACPServerFlags in ah
	call	IATAddIADToTokenArray	; ax = elt #, CF set if newly added
	jc	keepRef			; new token, no need to remove ref
	clr	bx			; no callback
	call	ElementArrayRemoveReference	; old token, remove one ref
keepRef:
	pop	bx			; bh = IACPServerFlags

	;
	; Set IAF_DONT_QUERY_IF_FOREGROUND flag
	;
	call	ChunkArrayElementToPtr	; ds:di = InboxAppData
	mov	cx, ds:[di].IAD_meta.REH_refCount.WAAH_low
	mov	bl, ds:[di].IAD_meta.REH_refCount.WAAH_high	; blcx = count
	ornf	ds:[di].IAD_flags, mask IAF_DONT_QUERY_IF_FOREGROUND
	call	UtilVMDirtyDS
	call	UtilUpdateAdminFile

checkRefCount:
	;
	; If ref count (blcx) > 1, display app panel
	;
	call	UtilVMUnlockDS		; unlock token map

if	_CONTROL_PANELS
	tst	bl
	jnz	displayAppPanel
	dec	cx
	jnz	displayAppPanel

	add	sp, size InboxAppData
	jmp	done

displayAppPanel:
	;
	; Allocate criteria.  Send MSG_MA_DISPLAY_INBOX_PANEL.
	;
	mov	ax, size MailboxDisplayPanelCriteria
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc		; bx = hptr, ax = sptr
	mov	ds, ax
	; ss:sp = InboxAppData.  Get GeodeToken from stack
	add	sp, offset IAD_token	; pop stuff before IAD_token
	pop	{word} ds:[MDPC_byApp].MDBAD_token.GT_chars[0]
	pop	{word} ds:[MDPC_byApp].MDBAD_token.GT_chars[2]
	pop	ds:[MDPC_byApp].MDBAD_token.GT_manufID
	add	sp, size InboxAppData - (offset IAD_token + size IAD_token)
					; pop stuff after IAD_token
	call	MemUnlock		; unlock criteria block
	mov	ax, MSG_MA_DISPLAY_INBOX_PANEL
	mov	cx, MDPT_BY_APP_TOKEN
	mov	dx, bx			; ^hdx = MailboxDisplayPanelCriteria
	call	UtilSendToMailboxApp	; block freed

done:
else
	;
	; Just clear the stack, please.
	; 
	add	sp, size InboxAppData
endif	; _CONTROL_PANELS

	.leave
	ret
InboxNotifyAppLoaded endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxNotifyAppNotLoaded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that an app is no longer loaded

CALLED BY:	(EXTERNAL) MainMailboxNotify
PASS:		bxcxdx	= GeodeToken (bx = GT_chars[0..1], cx = GT_chars[2..3],
			  dx = GT_manufID)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	display panel may come down (yeah, right)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxNotifyAppNotLoaded proc	far
		.enter
		.leave
		ret
InboxNotifyAppNotLoaded endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxNotifyNewForegroundApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notifies the Mailbox library that a new app is the focus
		(i.e. foreground) application. If an app is the focus app,
		and the IAF_DONT_QUERY_IF_FOREGROUND flag is set, any
		message arriving for the app will be delivered immediately

CALLED BY:	(EXTERNAL)
PASS:		bxcxdx	= GeodeToken (bx = GT_chars[0..1], cx = GT_chars[2..3],
			  dx = GT_manufID)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	inboxFocusApp is changed

PSEUDO CODE/STRATEGY:
		We don't do anything with any existing messages, as we
		assume there's been a panel up and the user has elected not
		to deliver the things. Of course, any other message coming
		in will ship them all off...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxNotifyNewForegroundApp proc far
		uses	ds
		.enter
		segmov	ds, dgroup, ax
		mov	{word}ds:[inboxFocusApp].GT_chars[0], bx
		mov	{word}ds:[inboxFocusApp].GT_chars[2], cx
		mov	ds:[inboxFocusApp].GT_manufID, dx

if	_ALWAYS_DELIVER_WHEN_FOREGROUND
		sub	sp, size SendMsgAvailableNotifParams
		mov	bp, sp
		movtok	ss:[bp].SMANP_destApp, bxcxdx
		call	AdminGetInbox
		mov	cx, SEGMENT_CS
		mov	dx, offset IATNotifyNewForegroundAppCallback
		call	DBQEnum
		add	sp, size SendMsgAvailableNotifParams
endif	; !_ALWAYS_DELIVER_WHEN_FOREGROUND
		.leave
		ret
InboxNotifyNewForegroundApp endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATNotifyNewForegroundAppCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the foreground app of any messages pending for 
		it in the inbox.

CALLED BY:	(INTERNAL) InboxNotifyNewForegroundApp via DBQEnum
PASS:		bx	= admin file
		sidi	= MailboxMessage
		ss:bp	= SendMsgAvailableNotifParams
RETURN:		carry clear to continue enumerating
DESTROYED:	ax, cx, dx, di, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_ALWAYS_DELIVER_WHEN_FOREGROUND
IATNotifyNewForegroundAppCallback proc	far
		uses	ds
		.enter
	;
	; See if this here message is for the foreground application.
	;
		movdw	dxax, sidi
		call	MessageLock
		mov	di, ds:[di]
		mov	cx, {word}ds:[di].MMD_destApp.GT_chars[0]
		cmp	{word}ss:[bp].SMANP_destApp.GT_chars[0], cx
		jne	done

		mov	cx, {word}ds:[di].MMD_destApp.GT_chars[2]
		cmp	{word}ss:[bp].SMANP_destApp.GT_chars[2], cx
		jne	done

		mov	cx, ds:[di].MMD_destApp.GT_manufID
		cmp	ss:[bp].SMANP_destApp.GT_manufID, cx
		jne	done
	;
	; It is -- send ourselves a message to notify the app (avoiding
	; deadlock, you know...).
	;
	; First add a reference to the message so it stays around the whole
	; time.
	;
		call	MailboxGetAdminFile
		call	DBQAddRef

		movdw	ss:[bp].SMANP_message, dxax
		mov	bx, handle 0
		mov	ax, MSG_MP_SEND_MESSAGE_AVAILABLE_NOTIFICATION
		mov	dx, size SendMsgAvailableNotifParams
		mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
		call	ObjMessage
done:
		call	UtilVMUnlockDS
		clc			; keep enumerating
		.leave
		ret
IATNotifyNewForegroundAppCallback endp
endif	; _ALWAYS_DELIVER_WHEN_FOREGROUND


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATLockDirTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the block holding the directory trees.

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		ds	= the locked directory tree block
DESTROYED:	nothing
SIDE EFFECTS:	inboxDirMap may be set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATLockDirTree	proc	near
		uses	ax, bx
		.enter
if	_HAS_SWAP_SPACE
		segmov	ds, dgroup, ax
		mov	bx, ds:[inboxDirMap]
		tst	bx
		jnz	grabIt
	;
	; This can only happen on the mailbox:0 thread during initialization,
	; so no synchronization is needed.
	;
		push	cx
		mov	ax, LMEM_TYPE_GENERAL
		mov	cx, size InboxTokenMapHeader
		call	MemAllocLMem
		mov	ax, mask HF_SHARABLE
		call	MemModifyFlags
		pop	cx
		mov	ds:[inboxDirMap], bx

		call	MemLock
		mov	ds, ax
		clr	ax
		mov	ds:[ITMH_appDirTree], ax
		mov	ds:[ITMH_sysAppDirTree], ax
		call	MemUnlock

grabIt:
		call	MemThreadGrab
else
	;
	; Lock down the VM block holding the app token map and the directory
	; trees.
	;
		push	bp
		call	AdminGetAppTokens
		call	VMLock
		pop	bp
endif	; _HAS_SWAP_SPACE
		mov	ds, ax
		.leave
		ret
IATLockDirTree	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATUnlockDirTreeDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the block holding the directory tree.

CALLED BY:	(INTERNAL)
PASS:		ds	= locked directory tree block
RETURN:		nothing
DESTROYED:	ds (flags preserved)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATUnlockDirTreeDS proc	near
		.enter
if	_HAS_SWAP_SPACE
		push	bx
		mov	bx, ds:[LMBH_handle]
		call	MemThreadRelease
		pop	bx
else
		call	UtilVMUnlockDS
endif	; _HAS_SWAP_SPACE
		.leave
		ret
IATUnlockDirTreeDS endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATDirtyDirTreeDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the block holding the directory tree dirty

CALLED BY:	(INTERNAL)
PASS:		ds	= locked directory tree block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	guess what?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_HAS_SWAP_SPACE
IATDirtyDirTreeDS	macro
		endm
else
IATDirtyDirTreeDS	macro
		call	UtilVMDirtyDS
		endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxNotifyFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that there is some change in the file system, possibly
		a new app being added.

CALLED BY:	(EXTERNAL) MANotifyFileChangeCallCallback
PASS:		dx	= FileChangeNotificationType
		es:di	= FileChangeNotificationData
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxNotifyFileChange	proc	far

	cmp	dx, FCNT_CREATE
	je	checkID
	cmp	dx, FCNT_ADD_SP_DIRECTORY
	jne	done

	;
	; A directory has been added to a standard path.  Check if it affects
	; application directories.
	;
	call	IATStandardPathAdded
	ret

checkID:
	call	IATMarkRescanIfNewAppCreated

done:
	ret
InboxNotifyFileChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATStandardPathAdded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A directory is added to a standard path, which might mean
		there are more applications.

CALLED BY:	(INTERNAL) InboxNotifyFileChange
PASS:		es:di	= FileChangeNotificationData
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Rebuild appropriate dir tree if either app path or sys-app path is
	affected.
	Mark unknown app tokens to be rescanned if either tree is rebuilt.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATStandardPathAdded	proc	near
	uses	ax,bx,cx,si,di,bp,ds
	.enter

	clr	cx			; will be set non-zero if tree rebuilt
	mov	bp, es:[di].FCND_disk

	;
	; If SP_APPLICATION gets a new component, it is possible that more
	; apps are available.
	;
	mov	bx, SP_APPLICATION
	cmp	bp, bx
	je	appAffected

	;
	; If SP_APPLICATION is a subdir of the affected path, SP_APPLICATION
	; can be affected.
	;
	call	FileStdPathCheckIfSubDir	; ax = 0 if bx is subdir of bp
	tst	ax
	jnz	checkSysAppl

appAffected:
	;
	; SP_APPLICATION is affected.  Rebuild appDirTree.
	;
	call	IATRebuildDirTree
	inc	cx			; mark that a tree is rebuilt

checkSysAppl:
	;
	; If SP_SYS_APPLICATION gets a new component, it is possible that more
	; apps are available.
	;
	mov	bx, SP_SYS_APPLICATION
	cmp	bp, bx
	je	sysAppAffected

	;
	; If SP_SYS_APPLICATION is a subdir of the affected path,
	; SP_APPLICATION can be affected.
	;
	call	FileStdPathCheckIfSubDir	; ax = 0 if bx is subdir of bp
	tst	ax
	jnz	checkIfMarkTokenRescan

sysAppAffected:
	call	IATRebuildDirTree
	inc	cx			; mark that a tree is rebuilt

checkIfMarkTokenRescan:
	;
	; If either tree is rebuilt, we need to mark unknown tokens to be
	; rescanned.
	;
	jcxz	done			; done if no tree is rebuilt

	call	IATGetTokenArray	; *ds:si = token array, bx = code
					;  seg/vseg
	mov	di, offset IATMarkTokenRescan
	clr	al
	call	ChunkArrayEnum		; al = TRUE if something's changed
	tst	al
	jz	notDirty
	call	UtilVMDirtyDS
notDirty:
	call	UtilVMUnlockDS

done:
	.leave
	ret
IATStandardPathAdded	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATRebuildDirTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free existing directory tree and build a new one.

CALLED BY:	(INTERNAL)
PASS:		bx	= either SP_APPLICATION or SP_STS_APPLICATION
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATRebuildDirTree	proc	far
	uses	ax,bx,dx,bp,si,di,ds,es
	.enter

	;
	; See if we're playing with app tree or sys-app tree.
	;
	mov_tr	ax, bx
	mov	si, offset ITMH_appDirTree
	cmp	ax, SP_APPLICATION
	je	gotOffset
	Assert	e, ax, SP_SYS_APPLICATION
	mov	si, offset ITMH_sysAppDirTree

gotOffset:
	call	FilePushDir
	call	FileSetStandardPath

	;
	; Free old tree, if any.
	;
	call	IATLockDirTree		; ds <- app token map
	mov	ax, ds:[si]		; *ds:ax = old tree
	tst	ax
	jz	noFree
	call	IATFreeDirNode		; free old tree
noFree:

	;
	; Create new tree.
	;
	segmov	es, cs			; IATCreateDirNode is in the same
					;  segment.  That's why we can use cs.
	mov	di, offset nullDir	; es:di = null path
	call	IATCreateDirNode		; *ds:ax = new tree
	mov	ds:[si], ax
	call	FilePopDir

	IATDirtyDirTreeDS
	call	IATUnlockDirTreeDS

	.leave
	ret
IATRebuildDirTree	endp

LocalDefNLString	nullDir, C_NULL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATFreeDirNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	(INTERNAL)
PASS:		*ds:ax	= InboxDirNode of ID tree to free
RETURN:		nothing (node freed)
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Recursion.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATFreeDirNode	proc	near
	uses	cx, si
	.enter

	Assert	chunk, ax, ds

	push	ax			; save lptr of this node
	mov_tr	si, ax
	mov	si, ds:[si]		; ds:si = InboxDirNode
	mov	cx, ds:[si].IDN_numSubDirs
	jcxz	freeThisNode
	mov	ax, size FilePathID
	mul	ds:[si].IDN_numIDs
	Assert	e, dx, 0		; assert no overflow
	add	si, offset IDN_id	; ds:si = first FilePathID
	add	si, ax			; ds:si = first lptr.InboxDirNode

	;
	; Recursively free all subdir nodes.
	;
dirLoop:
	;
	; Free the node representing this subdir.
	;
	mov	ax, ds:[si]		; *ds:ax = InboxDirNode of this subdir
	call	IATFreeDirNode		; recurse
	inc	si
	inc	si			; ds:si point to next lptr in array
	loop	dirLoop

freeThisNode:
	;
	; Free this node.
	;
	pop	ax			; *ds:ax = InboxIDNode of this node
	call	LMemFree

	.leave
	ret
IATFreeDirNode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATCreateDirNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a dir tree node for the current directory

CALLED BY:	(INTERNAL)
PASS:		ds	= lmem block to create a node in
		current dir set to the directory being scanned.
		es:di	= name of current dir (FileLongName)
RETURN:		*ds:ax	= node for this directory (InboxDirNode) (ds fixed-up)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Recursion.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATCreateDirNode	proc	near
	uses	bx,cx,dx,bp,si,di,es
	.enter

	Assert	segment, ds
	Assert	fptr, esdi

	;
	; Get all the subdirs in this directory
	;
	sub	sp, size FileEnumParams
	mov	bp, sp
	mov	ss:[bp].FEP_searchFlags, mask FESF_DIRS
	clr	ss:[bp].FEP_returnAttrs.segment
	mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME
	mov	ss:[bp].FEP_returnSize, size FileLongName
	clr	ss:[bp].FEP_matchAttrs.segment
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
	clr	ss:[bp].FEP_skipCount
	call	FileEnum		; ^hbx = hptr of buffer, cx = count
	jnc	noFileEnumError

	;
	; FileEnum returns error.  Just assume there's no subdir.
	;
	clr	cx
noFileEnumError:

	;
	; Get all ID's for this directory
	;
	call	FileGetCurrentPathIDs	; *ds:ax = array of FilePathID's
	jc	error
	push	ax			; save lptr of node

	;
	; Enlarge chunk to get space for other information of this node
	;

	; First insert space for chunk header
	mov	si, ax			; *ds:si = chunk to resize
	ChunkSizeHandle	ds, si, dx	; dx = size of FilePathID array
	mov	bp, cx			; bp = # of subdirs
	push	bx			; save hptr of FileEnum buffer
	clr	bx			; insert at front
	mov	cx, size InboxDirNode
	call	LMemInsertAt
	pop	bx			; bx = hptr of FileEnum buffer

	; Then insert space for lptr array for subdirs
	mov	cx, bp			; cx = # of subdirs
	shl	cx, 1			; cx = size of lptr array for subdirs
	add	cx, dx			; add space for FilePathID array
	add	cx, size InboxDirNode	; cx = size of this node needed
	call	LMemReAlloc

	; Now fill in the counts
	mov_tr	ax, dx
	clr	dx			; dxax = size of FilePathID array
	mov	cx, size FilePathID
	div	cx			; ax = # of FilePathID's
	Assert	e, dx, 0
	mov	si, ds:[si]
	mov	ds:[si].IDN_numIDs, ax
	mov	ds:[si].IDN_numSubDirs, bp

	; Finally fill in the name of this dir
		CheckHack <offset IDN_name eq 0>	; ds:si = IDN_name
	segxchg	es, ds
	xchg	di, si			; es:di = IDN_name to fill in
					; ds:si = name of this dir
		CheckHack <(size FileLongName and 1) eq 0>
	mov	cx, size FileLongName / 2
	rep	movsw

	;
	; Loop thru all subdirs to create child nodes
	;
	pop	si			; *es:si = InboxDirNode
	mov	cx, bp			; cx = # of subdirs
	jcxz	noSubDir
	call	MemLock
	call	IATCreateDirNodeEnumSubdir	; es fixed up
	call	MemFree			; free subdir name array

noSubDir:
	;
	; return stuff
	;
	movdw	dsax, essi		; *ds:ax = InboxDirNode of this dir

	.leave
	ret
error:

IATCreateDirNode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATCreateDirNodeEnumSubdir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	(INTERNAL) IATCreateDirNode
PASS:		ax:0	= FileLongName array of subdirectories
		cx	= # of subdirs (non-zero)
		*es:si	= InboxDirNode
RETURN:		es fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Recursion.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATCreateDirNodeEnumSubdir	proc	near
subDirCount		local	word			push	cx
offsetToLptrArray	local	word
	uses	ax,bx,cx,dx,di,ds
	.enter

	Assert	segment, ax
	Assert	ne, cx, 0
	Assert	chunk, si, es

	push	ax			; save subdir name array sptr
	mov	di, es:[si]
	mov	ax, size FilePathID
	mul	es:[di].IDN_numIDs
	Assert	e, dx, 0
	add	ax, offset IDN_id	; es:ax = offset to beginning of
					;  lptr array withid IDN
	mov	ss:[offsetToLptrArray], ax
	mov	cx, es			; cx = tree block
	pop	es			; es = subdir name block
	; dx already set to 0.  es:dx = first subdir name

nextSubDir:
	;
	; Chdir down to subdir
	;
	call	FilePushDir
	clr	bx			; relative to current dir
	segmov	ds, es			; ds:dx = subdir name
	
	; before we change the directory, we should check
	; whether it is a link or a real directory.
	; links should be rejected to avoid scanning whole drives or
	; even circular links.

	push	cx
	push	ax
	clr	cx
	call	FileReadLink		; this returns an error if it is no link
	pop	ax
	pop	cx
	mov	bx,0
	jnc	skipdir			; if no error (carry clear) then
					; it is a link and will be skipped
	call	FileSetCurrentPath
	; if an error occurs, skip this folder as a new node
	jc	skipdir			; file error if carry
	;
	; Create a node for this subdir
	;
	mov	ds, cx			; ds = tree block
	mov	di, dx			; es:di = name of this subdir
	call	IATCreateDirNode		; *ds:ax = node for this subdir
	mov	cx, ds

	;
	; Add new node to current InboxDirNode
	;
	mov	di, ds:[si]
	add	di, ss:[offsetToLptrArray]
	mov	ds:[di], ax

skipdir:
	;
	; Chdir up to current dir
	;
	call	FilePopDir

	;
	; Loop for next subdir
	;
	add	ss:[offsetToLptrArray], size lptr
	add	dx, size FileLongName
	dec	ss:[subDirCount]
	jnz	nextSubDir

	;
	; return stuff
	;
	mov	es, cx

	.leave
	ret
IATCreateDirNodeEnumSubdir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATMarkTokenRescan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark token to be rescanned if it's an unknown token

CALLED BY:	(INTERNAL) IATStandardPathAdded via ChunkArrayEnum
PASS:		ds:di	= InboxAppData
RETURN:		carry always clear
		If IAD_flags is changed
			al	= TRUE
		else
			ax unchanged
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATMarkTokenRescan	proc	far

	; We don't care whether it's an alias token or not.
	cmp	ds:[di].IAD_nameRef, IAD_UNKNOWN
	jne	done
	BitClr	ds:[di].IAD_flags, IAF_DONT_TRY_TO_LOCATE_SERVER_AGAIN
	mov	al, TRUE

done:
	clc

	ret
IATMarkTokenRescan	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATMarkRescanIfNewAppCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the created file is in one of the application 
		directories and, if so, note that all unknown tokens need to 
		be resought when next they are asked for.

CALLED BY:	(INTERNAL) InboxNotifyFileChange
PASS:		es:di	= FileChangeNotificationData
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATMarkRescanIfNewAppCreated	proc	near
filePath	local	PathName
;
; Current filePath is built out if the file sits in either tree, but it's
; never used afterwards.  The path building code can be removed if we decide
; it will never be needed.  --- AY 9/23/94.
;
	uses	ax,bx,dx,si,ds
	.enter

	call	IATLockDirTree		; ds <- app token map
	mov	dx, ss
	lea	bx, ss:[filePath]	; dx:bx = filePath

	;
	; First scan appDirTree.
	;
	mov	si, ds:[ITMH_appDirTree]	; *ds:si = app dir tree
	call	IATMatchIDInNode	; CF set if match
	jc	found

	;
	; Then scan sysAppDirTree.
	;
	mov	si, ds:[ITMH_sysAppDirTree]	; *ds:si = sys-app dir tree
	call	IATMatchIDInNode	; CF set if match
found:
	call	IATUnlockDirTreeDS
	jnc	done

	;
	; Replace backslash terminator with null.
	;
	LocalPrevChar	ssbx
	LocalClrChar	ss:[bx]


	;
	; Mark all unknown tokens to be rescaned.
	;
	push	di			; save FileChangeNotificationData nptr
	call	IATGetTokenArray
	mov	di, offset IATMarkTokenRescan
	clr	al
	call	ChunkArrayEnum		; al = TRUE if something's changed

	;
	; Mark the VM block dirty only if something has changed, to avoid
	; unnecessary disk update.
	;
	tst	al
	jz	notDirty
	call	UtilVMDirtyDS
notDirty:
	pop	di			; es:di = FilechangeNotificationData
	call	UtilVMUnlockDS
done:

	.leave
	ret
IATMarkRescanIfNewAppCreated	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATMatchIDInNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	(INTERNAL) IATMarkRescanIfNewAppCreated
PASS:		es:di	= FileChangeNotificationData
		*ds:si	= InboxDirNode of subtree to match
		dx:bx	= buffer for appending path name
RETURN:		carry set if id matches something in this subtree
			buffer appended with path name of matching directory
			(backslash terminated)
			bx	= offset after last backslash in path
		carry clear if id doesn't match
			bx unchanged
DESTROYED:	ax, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Recursion.

	Append directory name into buffer only when necessary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATMatchIDInNode	proc	near
	uses	cx,bp
	.enter

	Assert	chunk, si, ds
	Assert	fptr, dxbx

	mov	bp, ds:[si]		; ds:bp = InboxDirNode
	mov	cx, ds:[bp].IDN_numIDs
	lea	si, ds:[bp].IDN_id	; ds:si = first FilePathID

	;
	; See if given ID matches anything in this dir
	;
nextID:
	mov	ax, es:[di].FCND_disk
	cmp	ax, ds:[si].FPID_disk
	jne	notMatchID
	cmpdw	es:[di].FCND_id, ds:[si].FPID_id, ax
	je	matchID

notMatchID:
	add	si, size FilePathID
	loop	nextID

	;
	; Given ID doesn't match any ID in this dir.  See if there're any
	; subdir in this dir.
	;
	mov	cx, ds:[bp].IDN_numSubDirs
	clc				; assume no match in this subtree
	jcxz	done			; done if no subdir

	;
	; There are subdirectories.  Append name of current directory and
	; loop thru subdirs.
	;
	push	bx			; preserve old offset of end of path
					;  in case no subdir matches
	call	appendDirName
	mov	bp, si			; ds:bp = first lptr for subdir node

nextSubDir:
	mov	si, ds:[bp]		; *ds:si = InboxDirNode of subdir
	call	IATMatchIDInNode	; recurse
	jc	doneSubDir		; jump if ID matches in subtree
	inc	bp			; CF preserved
	inc	bp			; bp += size lptr, ds:bp = next lptr
	loop	nextSubDir		; CF preserved

doneSubDir:
	pop	ax			; ax = old offset of end of path
	jc	done			; if match, don't restore old offset
	mov_tr	bx, ax			; else, restore old offset
	jmp	done

matchID:
	;
	; Given ID matches an ID in this dir.  Append name of this dir into
	; buffer and quit.
	;
	call	appendDirName
	stc

done:
	.leave
	ret

appendDirName:
	pushdw	esdi			; save FileChangeNotificationData fptr

	xchg	si, bp			; ds:si = InboxDirNode; bp = old si
		CheckHack <offset IDN_name eq 0>    ; ds:si = name of this dir
	movdw	esdi, dxbx
	LocalCopyString			; es:di = char after null
	mov	bx, di			; dx:bx = beginning of buffer for
					;  subdir
	LocalPrevChar	esdi
	LocalLoadChar	ax, C_BACKSLASH
	LocalPutChar	esdi, ax	; backslash-terminate it
	mov	si, bp			; restore si

	popdw	esdi			; es:di = FileChangeNotificationData
	ret

IATMatchIDInNode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATGetAppName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for an application and attempt to ensure it has a
		name. The token must already be in the array for this
		to do anything.

CALLED BY:	(INTERNAL) InboxGetAppName
PASS:		bxcxdx	= GeodeToken being sought
RETURN:		carry set if application name not known
			ds	= locked app token array block
			bp	= handle of same
			es, cx, dx, di = destroyed
		carry clear if application name known
			ds:di	= name of app in app token array block
				  (not null-terminated)
			bp	= handle of same
			cx	= size of the name, w/null terminator added
			es	= ds
			dx	= 0
DESTROYED:	ax, bx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/95		Initial version (broken out of InboxGetAppName)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATGetAppName	proc	near
		.enter
	;
	; Get token array
	;
	push	dx, cx, bx		; ss:sp = GeodeToken to look for
	movdw	esdx, sssp
	call	IATFindTokenInArray	; ax = elt #, CF set if found
	mov	bp, sp
	lea	sp, ss:[bp+size GeodeToken] ; pop token

	mov	bp, ds:[LMBH_handle]	; bp = hptr of app token map
	jnc	appNotFound

if ERROR_CHECK
	; Make sure token is not a bound alias
	call	ChunkArrayElementToPtr
	test	ds:[di].IAD_flags, mask IAF_IS_ALIAS
	jz	EC_okay
	Assert	e, ds:[di].IAD_nameRef.IAN_aliasFor, IAD_UNKNOWN
EC_okay:
endif

	;
	; See if token has a nameRef.
	; ax = elt # within token array
	;
tryAgainWithToken:
	call	ChunkArrayElementToPtr	; ds:di = InboxAppData (token can
					;  either be an alias or a real app)
	mov_tr	bx, ax			; bx = elt # of token
	mov	ax, ds:[di].IAD_nameRef
		CheckHack <IAD_UNKNOWN eq -1>

	;
	; ax = element # within app-name name array, or -1 if name not known.
	;
	inc	ax
	jz	nameNotYetKnown
	dec	ax

tryAgainWithName:
	;
	; Token has a nameRef, hence it must be a real app token.  Get entry
	; in name array
	;
	inc	si
	inc	si			; *ds:si = name array
	Assert	ChunkArray, dssi
	call	ChunkArrayElementToPtr	; ds:di = NameArrayElement, cx = size
	segmov	es, ds
	add	di, offset NAE_data	; es:di = app name (no null)
	sub	cx, offset NAE_data - size TCHAR; cx = size of name + null
	clr	dx			; dx=0 means caller won't need to
					;  lock uiUnknownApp block (clears
					;  carry)
done:
	.leave
	ret

appNotFound:
	stc
	jmp	done

nameNotYetKnown:
	;
	; Either it's an unbound alias or an app token without app name.
	; See if we can get more info (by IACPLocateServer) for the token now.
	;

	mov_tr	ax, bx			; ax = elt # of token
	clr	dx			; dx <- rebuild not needed yet
	call	IATUpdateTokenInArray	; ax incremented by 1, dx = flag
	tst	dx
	jz	noRebuild
	call	IRSendRebuild		; rebuild app list
noRebuild:
	dec	ax			; ax = elt # of token
	call	ChunkArrayElementToPtr	; de-ref again, ds:di = IAD, cx = size

	;
	; If name is still unknown by now, just say unknown app.
	;
	mov	ax, ds:[di].IAD_nameRef
	inc	ax
	jz	appNotFound
	dec	ax

	;
	; If token now becomes a bound alias, the real app that the alias is
	; bound to must also have a name by now.  Follow link to get real
	; app token.
	;
	test	ds:[di].IAD_flags, mask IAF_IS_ALIAS
	jz	tryAgainWithName	; not alias, ax = elt # of app name
	jmp	tryAgainWithToken	; alias, ax = elt # of real app token
IATGetAppName	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxGetAppName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the name to use for a token.

CALLED BY:	(EXTERNAL) MMDrawInboxSubject
PASS:		bxcxdx	= GeodeToken
		ds	= locked lmem block in which to store the string
RETURN:		*ds:ax	= application name string (something standard if
			  token is for an unknown application)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	NOTE: This routine should never be called with a bound alias token,
	      since a message for a bound alias should have been remapped to
	      the real app token.

	      This routine can be called with either an app token or an
	      unbound alias token, though.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	7/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxGetAppName	proc	far
	uses	bx,cx,dx,bp,si,di,es
	.enter

	push	ds:[LMBH_handle]	; save block to create name string

	call	IATGetAppName
	jnc	gotAppName

	;
	; Still can't find app.  Use "Unknown Application".
	;
	mov	bx, handle uiUnknownApp
	mov	dx, bx
	call	MemLock
	mov	es, ax
	assume	es:segment uiUnknownApp
	mov	di, es:[uiUnknownApp]	; es:di = string for unknown app
	ChunkSizePtr	es, di, cx	; cx = size of string

gotAppName:
	; es:di = app name (with/without null-terminator)
	; cx = size of name (space for null included)
	; (if cx = size TCHAR, es:di is ignored and a null string is created)
	; if es:di points to a string in ROStrings block
	; 	dx = hptr of ROStrings block (to be unlocked later)
	; else
	;	dx = 0

	;
	; Create chunk for string
	;
	call	MemDerefStackDS		; ds = block to create string
	mov	al, mask OCF_DIRTY	; in case it's an object block
	call	LMemAlloc		; *ds:ax = new chunk
	mov_tr	bx, ax			; *ds:bx = buffer
	mov	si, ds:[bx]		; ds:si = buffer for app name

	;
	; Copy app name
	;
	segxchg	ds, es
	xchg	si, di
	dec	cx			; cx = size excl. null
DBCS <	dec	cx			; cx = size excl. null		>
	rep	movsb
	LocalClrChar	ax
	LocalPutChar	esdi, ax	; stuff in null

	;
	; Cleanup
	;
	call	VMUnlock		; unlock token map
	tst	dx
	jz	noUnlockStrBlk
	call	UtilUnlockDS		; unlock uiUnknownApp block
noUnlockStrBlk:
	segmov	ds, es
	mov_tr	ax, bx			; *ds:ax = app name

	.leave
	ret
InboxGetAppName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATUpdateTokenMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the app token map with as much available information
		as possible.
		- Bind any unbound alias tokens to real app tokens.
		- Map messages for newly bound alias tokens to real app tokens
		- Add names of apps whose names are still unknown to name array

		This routine uses as much info as it can find in the file
		system.  Some alias token might still be left unbound and some
		app might still be left without a name.

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0		; not used, currently
IATUpdateTokenMap	proc	near
	uses	ax,bx,cx,dx,bp,si,di,ds
	.enter

	;
	; Get token array
	;
	call	AdminGetAppTokens	; ^vbx:ax = app token map
	call	VMLock			; ax = sptr, bp = hptr
	mov	ds, ax
	mov	si, ds:[LMBH_offset]
	Assert	ChunkArray, dssi

	;
	; Enumerates all existing token.  Note that as alias token are
	; processed, new app tokens might be added at the end of the array
	; (because there should be no free element in the middle of the array
	; since we never remove tokens.)
	; We don't need to enumerate thru these newly added tokens because we
	; know for sure that these are real app tokens and their names are
	; already added to app name array.  (It won't hurt to enumerate new
	; tokens too, but we just want to save a little time.)
	;
	call	ChunkArrayGetCount	; cx = # of tokens
	mov	bx, SEGMENT_CS
	mov	di, offset IATUpdateTokenInArray
	clr	ax, dx			; start from 1st token, ax=0 is also
					;  passed to callback when called the
					;  the first time
					; dx=0 to clear rebuild flag
	call	ChunkArrayEnumRange	; dx = update flag

	;
	; Rebuild app list if necessary
	tst	dx
	jz	done
	call	IRSendRebuild

done:
	call	VMUnlock		; unlock token map

	.leave
	ret
IATUpdateTokenMap	endp
endif ; 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATUpdateTokenInArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update one token in token map with as much info as possible.
		The routine tries to bind an alias token, finds app name of
		an real app token, and remaps destinations of messages.

		The token is ignored if either it is already bound (alias
		token) or its app name is already known (real app token).

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= token array
		ds:di	= InboxAppData within token array
		ax	= current element #
		dx	= rebuild flag for app list (BooleanWord)
			  (when it returns, dx will be either unchanged or
			  set to BW_TRUE.  Useful for propagating a flag to
			  rebuild app list when called as a callback.)
RETURN:		carry always clear
		ds	= fixed up to point to the same block as passed
		ax	= incremented by one
		If Inbox App List needs to be rebuilt (either because destApp
		  of some message has been changed or name of some app has been
		  found)
			dx	= BW_TRUE
		else
			dx	= unchanged
DESTROYED:	di
SIDE EFFECTS:
	New app token may be added at the end of the token array.
	New app name may be added to name array.

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

PSEUDO CODE/STRATEGY:
	- Ignore token if either it is a bound alias or an app token that
	  already has a name.
	-

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATUpdateTokenInArray	proc	far

if ERROR_CHECK
	;
	; Make sure the passed elt # is for the passed element pointer.
	;
	push	bx
	mov_tr	bx, ax
	call	ChunkArrayPtrToElement	; dies if ptr does not point to an elt
	Assert	e, bx, ax
	pop	bx

	;
	; There should be no free element in array because we never remove
	; tokens.
	;
	Assert	ne, ds:[di].IAD_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT

	;
	; Make sure alias token has MANUFACTURER_ID_GENERIC iff it is an alias
	;
	Assert	record, ds:[di].IAD_flags, InboxAppFlags
	test	ds:[di].IAD_flags, mask IAF_IS_ALIAS
	jnz	EC_alias
	cmp	ds:[di].IAD_token.GT_manufID, MANUFACTURER_ID_GENERIC
	WARNING_E MANUFACTURER_ID_GENERIC_MUST_BE_USED_FOR_ALIAS_TOKEN
	jmp	EC_done
EC_alias:
	cmp	ds:[di].IAD_token.GT_manufID, MANUFACTURER_ID_GENERIC
	WARNING_NE MANUFACTURER_ID_GENERIC_MUST_BE_USED_FOR_ALIAS_TOKEN
EC_done:
endif

	;
	; Ignore token if either it's bound (alias) or it already has a name
	; (real app token).  Also ignore if an attempt to find the server has
	; been made earlier.
	;
	cmp	ds:[di].IAD_nameRef, IAD_UNKNOWN
	LONG jne noNeedToProcess
	test	ds:[di].IAD_flags, mask IAF_DONT_TRY_TO_LOCATE_SERVER_AGAIN
					; clears carry
	LONG jnz noNeedToProcessCarryClear

cArraySptr	local	sptr.LMemBlockHeader	push	ds
curTokenEltNum	local	word			push	ax
rebuildFlag	local	BooleanWord		push	dx
realAppIAD	local	InboxAppData
aliasTokenFptr	local	fptr.GeodeToken
AIRHptr		local	hptr.AppInstanceReference
SBCS <	rootDir	local	2 dup(char)					>
DBCS <	rootDir	local	2 dup(wchar)					>
	uses	bx,cx,es
	.enter

	;
	; Hack for mailbox app, which otherwise gets no name.
	;
	cmp	ds:[di].IAD_token.GT_manufID, MANUFACTURER_ID_GEOWORKS
	jne	findServer
	cmp	{word}ds:[di].IAD_token.GT_chars[0], 'M' or ('B' shl 8)
	jne	findServer
	cmp	{word}ds:[di].IAD_token.GT_chars[2], 'O' or ('X' shl 8)
	jne	findServer
	
	mov	bx, handle uiMboxApp
	push	ax
	call	MemLock
	mov	es, ax
	assume	es:segment uiMboxApp
	pop	ax
	mov	di, es:[uiMboxApp]
	ChunkSizePtr	es, di, cx
	mov	ss:[AIRHptr], bx
	jmp	addName

findServer:
	;
	; Find server of token.
	;
	clr	ss:[AIRHptr]
	mov	dl, ds:[di].IAD_flags
	segmov	es, ds
	add	di, offset IAD_token	; es:di = GeodeToken
	call	IACPLocateServer	; ^hbx = AppInstanceReference
	LONG jc	notFound		; do nothing if app not found
	sub	di, offset IAD_token	; es:di = InboxAppData
	mov	ss:[AIRHptr], bx

	;
	; If token is not an alias, no need to go thru binding stuff
	;
	call	MemLock
	mov	es, ax			; es = AIR
	mov	ax, ss:[curTokenEltNum]
	test	dl, mask IAF_IS_ALIAS
	LONG jz	processRealToken

	;
	; Chdir to root dir of disk containing app
	;
	call	FilePushDir
	mov	bx, es:[AIR_diskHandle]
SBCS <	mov	{word} ss:[rootDir], C_BACKSLASH or (C_NULL shl 8)	>
DBCS <	mov	ss:[rootDir], C_BACKSLASH				>
DBCS <	mov	ss:[rootDir + size wchar], C_NULL			>
	segmov	ds, ss
	lea	dx, ss:[rootDir]
	call	FileSetCurrentPath

	;
	; Get real token of app
	;
	segmov	ds, es			; ds = AIR
		CheckHack <offset AIR_fileName eq 0>
	clr	dx			; ds:dx = app path name
	mov	ax, FEA_TOKEN
	segmov	es, ss
	lea	di, ss:[realAppIAD].IAD_token
	mov	cx, size GeodeToken
	call	FileGetPathExtAttributes
	call	FilePopDir
	segmov	es, ds			; es = AIR
	mov	ds, ss:[cArraySptr]	; *ds:si = token array
	LONG jc	notFound		; file not found, do nothing

	;
	; Add real app token to token array (but don't add ref if token
	; already exists).
	;
	clr	ss:[realAppIAD].IAD_flags	; this is a real app token
	mov	ss:[realAppIAD].IAD_nameRef.IAN_name, IAD_UNKNOWN
	mov	cx, ss
	lea	dx, ss:[realAppIAD]
	mov	bx, SEGMENT_CS
	mov	di, offset IATMatchTokenInIAD
	call	ElementArrayAddElement	; ax = elt #, CF set if newly added
	jc	keepRef			; new token, no need to remove ref
	clr	bx			; no callback
	call	ElementArrayRemoveReference	; old token, remove one ref
keepRef:

	;
	; Bind alias token to this app token
	;
	mov_tr	bx, ax			; bx = real app token elt #
	mov	ax, ss:[curTokenEltNum]
	call	ChunkArrayElementToPtr	; ds:di = IAD of alias
	mov	ds:[di].IAD_nameRef.IAN_aliasFor, bx
	push	bx			; save real app token elt #

	;
	; If there are messages for this alias, remap them to the app token.
	;
	cmp	ds:[di].IAD_meta.REH_refCount.WAAH_low, 1
	jne	remapMsg
	cmp	ds:[di].IAD_meta.REH_refCount.WAAH_high, 0
	je	noRemap

remapMsg:
	add	di, offset IAD_token
	movdw	ss:[aliasTokenFptr], dsdi	; GeodeToken of alias
	call	AdminGetInbox		; ^vbx:di = inbox queue
	mov	cx, SEGMENT_CS
	mov	dx, offset IATRemapMessageDest
	call	DBQEnum
	mov	ss:[rebuildFlag], BW_TRUE

noRemap:
	pop	ax
	call	ChunkArrayElementToPtr	; ds:di = IAD of real app token

processRealToken:
	; ds:di = IAD of real app token
	; ax = elt # of real app token
	; es = AppInstanceReference

	;
	; If app name wasn't know, add app name to name array
	;
	cmp	ds:[di].IAD_nameRef.IAN_name, IAD_UNKNOWN
	jne	done			; done if name already exists
	clr	di			; es:di = AIR_fileName
	call	UtilLocateFilenameInPathname	; es:di = filename, cx = size
					;  incl. null
addName:
	inc	si
	inc	si			; *ds:si = name array
	Assert	ChunkArray, dssi
DBCS <	shr	cx, 1			; cx = length			>
	dec	cx			; cx = length excl. null
	clr	bx			; no replace
	push	ax			; save elt # of real app token
	call	NameArrayAdd		; ax = elt # of name

	;
	; Store name elt # in app token
	;
	dec	si
	dec	si			; *ds:si = token array
	mov_tr	bx, ax			; bx = elt # of name
	pop	ax			; ax = elt # of real app token
	call	ChunkArrayElementToPtr	; ds:di = IAD of real app token
	mov	ds:[di].IAD_nameRef.IAN_name, bx

	;
	; If there are messages for this app (ref count > 1), we need to
	; rebuild inbox app list because we have just found the app name.
	;
	cmp	ds:[di].IAD_meta.REH_refCount.WAAH_high, 0
	ja	markRebuild
	cmp	ds:[di].IAD_meta.REH_refCount.WAAH_low, 1
	jbe	done
markRebuild:
	mov	ss:[rebuildFlag], BW_TRUE

done:
	mov	ax, ss:[curTokenEltNum]
doneHasAX:
	mov	dx, ss:[rebuildFlag]

	;
	; Free AIR block
	;
	mov	bx, ss:[AIRHptr]
	tst	bx
	jz	noFree
	cmp	bx, handle uiMboxApp
	je	unlockStrings
	call	MemFree
noFree:

	.leave

noNeedToProcess:
	clc
noNeedToProcessCarryClear:
	inc	ax
	ret

notFound:
	mov	ax, ss:[curTokenEltNum]
	call	ChunkArrayElementToPtr
	BitSet	ds:[di].IAD_flags, IAF_DONT_TRY_TO_LOCATE_SERVER_AGAIN
	jmp	doneHasAX

unlockStrings:
	call	MemUnlock
	jmp	noFree
IATUpdateTokenInArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATRemapMessageDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to Change dest-app of message for the alias
		token to the actual token

		This routine is called when a new binding has occured for an
		alias token that has some messages pending.

CALLED BY:	(INTERNAL) IATUpdateTokenInArray via DBQEnum
PASS:		sidi	= MailboxMessage
		ss:bp	= inherited stack frame from IATUpdateTokenInArray
			  - aliasTokenFptr points to GeodeToken of alias
			  - realAppIAD.IAD_token contains GeodeToken of app
RETURN:		carry always clear (always continue)
DESTROYED:	ax, cx, dx (ax allowed by DBQEnum)
SIDE EFFECTS:	MSG_IAL_REBUILD_LIST is sent when message is remapped

PSEUDO CODE/STRATEGY:
	If dest-app of message matches alias
		send message removed notif
		change token to actual token of app
		send message added notif

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATRemapMessageDest	proc	far
	uses	si,di,ds,es
	.enter inherit IATUpdateTokenInArray
	Assert	stackFrame, bp

	;
	; See if dest-app of this message is the alias
	;
	mov	dx, si
	mov_tr	ax, di			; dxax = MailboxMessage
	call	MessageLock		; *ds:di = MailboxMessageDesc
	mov	si, ds:[di]
	add	si, offset MMD_destApp	; ds:si = destApp token
	push	si			; save offset of MMD_destApp
	les	di, ss:[aliasTokenFptr]	; es:di = alias token
		CheckHack <(size GeodeToken and 1) eq 0>
	mov	cx, size GeodeToken / 2
	repe	cmpsw
	pop	di			; di = offset of MMD_destApp
	call	UtilVMUnlockDS
	jne	done			; do nothing if msg not for this alias

	
	segmov	ds, ss
	lea	si, ss:[realAppIAD].IAD_token
	call	InboxRetargetMessage

done:
	clc

	.leave
	ret
IATRemapMessageDest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATAddIADToTokenArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock token map and add an InboxAppData to token array

CALLED BY:	(INTERNAL)
PASS:		cx:dx	= InboxAppData to add (IAD_token must be initialized,
			  other fields can contain trash)
RETURN:		*ds:si	= token array (ds must be unlocked by caller)
		ax	= element #
		carry set if element newly added
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATAddIADToTokenArray	proc	near
	uses	bx,di
	.enter

	call	IATGetTokenArray	; bx = code seg/vseg
	mov	di, offset IATMatchTokenInIAD	; bx:di = callback
	call	ElementArrayAddElement	; ax = elt #, CF set if newly added

	.leave
	ret
IATAddIADToTokenArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATMatchTokenInIAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare GeodeTokens of InboxAppData's

CALLED BY:	(INTERNAL) IATAddIADToTokenArray via ElementArrayAddElement
PASS:		es:di	= 1st InboxAppData
		ds:si	= 2nd InboxAppData 
RETURN:		CF set if tokens match
DESTROYED:	cx (can destory ax, bx, cx, dx)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATMatchTokenInIAD	proc	far
	uses	si, di
	.enter

	add	si, offset IAD_token
	add	di, offset IAD_token
		CheckHack <(size GeodeToken and 1) eq 0>
	mov	cx, size GeodeToken / 2
	repe	cmpsw
	clc				; assume not match
	jne	done
	stc				; tokens match

done:
	.leave
	ret
IATMatchTokenInIAD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATFindTokenInArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock token map and search for an entry in token array

CALLED BY:	(INTERNAL)
PASS:		es:dx	= GeodeToken to find
RETURN:		*ds:si	= token array (ds must be unlocked by caller)
		carry set if token found
			ax	= elt # of InboxAppData for the token
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATFindTokenInArray	proc	far
	uses	bx,cx,di
	.enter

	call	IATGetTokenArray	; bx = code seg/vseg
	mov	di, offset IATMatchTokenCallback	; bx:di = callback
	clr	ax			; init elt # count
	call	ChunkArrayEnum

	.leave
	ret
IATFindTokenInArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATGetTokenArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subroutine to lock app token array

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		*ds:si	= token array (must be unlocked be caller)
		ax	= ds
		bx	= segment/vseg of InboxCode
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IATGetTokenArray	proc	far
	uses	bp
	.enter

	call	AdminGetAppTokens	; ^vbx:ax = token map
	call	VMLock			; bp = hptr, ax = sptr
	mov	ds, ax
	mov	si, ds:[LMBH_offset]	; *ds:si = token array
	Assert	ChunkArray, dssi
	mov	bx, SEGMENT_CS

	.leave
	ret
IATGetTokenArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxCheckAppUnknown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the destination app is unknown

CALLED BY:	(EXTERNAL) MailboxRegisterMessage,
			   InboxRetargetMessage
PASS:		ds:si	= GeodeToken to check
RETURN:		carry set if application not available on this system
DESTROYED:	nothing
SIDE EFFECTS:	token added to array and name found, if app is available
     			but had never been seen before

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_NO_UNKNOWN_APPS_ALLOWED
InboxCheckAppUnknown proc	far
		uses	ax, bx, cx, dx, si, di, ds, es, bp
		.enter
	;
	; Make sure there's an entry in the array for the token, so we can
	; remember what the thing's name is once we've gone through all the
	; work to locate it.
	;
		movtok	bxcxdx, ds:[si]
		call	IATEnsureTokenExists
		call	UtilVMUnlockDS
	;
	; Now there's an entry, go see if the thing has a name.
	;
		call	IATGetAppName		; carry <- set if not found
		call	UtilVMUnlockDS
		; XXX: SHOULD WE REMOVE THE ELEMENT FROM THE ARRAY HERE IF
		; NOT FOUND?
		.leave
		ret
InboxCheckAppUnknown endp
endif	; _NO_UNKNOWN_APPS_ALLOWED


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATNotifyIndicator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the necessary notifications to let the indicator
		app know exactly what's in the inbox.

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATGenerateOneIndicatorNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate indicator application notification for a single
		application.

CALLED BY:	(INTERNAL) IATNotifyIndicator via ChunkArrayEnum
PASS:		ds:di	= InboxAppData to examine
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	nothing
SIDE EFFECTS:	notification may be sent

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IATCreateNotificationText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the notification text from the template string in
		ROStrings

CALLED BY:	(INTERNAL) IATGenerateOneIndicatorNotification
PASS:		ds:bx	= InboxAppData whose app name is to go into the 
			  template
		si	= chunk handle of template string
		es:di	= place to store result (INDICATOR_MAX_DOCUMENT_-
			  STRING_LENGTH characters long)
RETURN:		buffer filled with null-terminated string
DESTROYED:	ax, cx, si, di, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InboxCode	ends
