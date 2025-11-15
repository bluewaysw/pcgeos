COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Navigate Controller
MODULE:		Notification
FILE:		navcontrolNotify.asm

AUTHOR:		Alvin Cham, Oct  3, 1994

ROUTINES:
	Name			Description
	----			-----------

    	NavigateSendNotification    
    	    	    	    	- send a notification

    	NavigateAllocNotification   
    	    	    	    	- allocate a notification block

    	NavigateUnlockSendNotification
    	    	    	    	- send the notification off to GCN list

    	NavigateRecordNotifEvent
    	    	    	    	- record a notification event

    	NavigateSendNotifToAppGCN
    	    	    	    	- send notification block to GCN
    	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 3/94   	Initial revision


DESCRIPTION:
	This file contains the routines for managing the notifications.

	$Id: navcontrolNotify.asm,v 1.1 97/04/05 01:24:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
notificationCount   word
idata	ends

NavigateControlCode  segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NavigateSendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate and send a notification.

CALLED BY:	GLOBAL
PASS:		cx:dx	= moniker of entry
    	    	bp  	= ChunkHandle of selector
    	    	ax  	= NotifyNavContextChangeFlags
RETURN:	    	nothing		
DESTROYED:	ax, bx, cx, dx, di, ds, es, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NavigateSendNotification	proc	near
	.enter inherit 

    	; allocate a notification block
    	mov 	bx, (size NotifyNavContextChange)
    	call	NavigateAllocNotification
    	; bx = handle of NotifyHelpContextChange
    	; es = seg addr of NotifyHelpContextChange

    	mov 	es:NNCC_flags, ax
	test	ax, mask NNCCF_updateHistory	;Only need update
    	jz  	notify

    	mov 	es:NNCC_selector, bp
    	mov 	di, offset NNCC_moniker
    	movdw	dssi, cxdx    	
    	call	NCStringCopy

notify:
    	; unlock the notification and send it off
    	mov 	cx, GAGCNLT_NOTIFY_NAVIGATE_ENTRY_CHANGE
    	mov 	dx, GWNT_NAVIGATE_ENTRY_CHANGE

    	; increment the counter which makes the notification unique
    	push	es
    	mov 	ax, segment idata
    	mov 	es, ax
    	inc 	es:notificationCount
    	mov 	ax, es:notificationCount
    	pop 	es
    	mov 	es:NNCC_counter, ax
    	call	NavigateUnlockSendNotification

    	.leave
	ret
NavigateSendNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NavigateAllocNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a notification block

CALLED BY:	INTERNAL
PASS:		bx  = size of block to allocate
RETURN:		bx  = handle of NotifyNavContextChange
    	    	es  = seg addr of NotifyNavContextChange
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NavigateAllocNotification	proc	near
	uses	ax,cx
	.enter

    	mov 	ax, bx
    	mov 	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
    	    	    or (mask HAF_ZERO_INIT shl 8)
    	call	MemAlloc
    	mov 	es, ax	    	    	    ; seg addr of block

	.leave
	ret
NavigateAllocNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NavigateUnlockSendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send off a notification to the appropriate GCN lists

CALLED BY:	NavigateSendNotification
PASS:		bx  = handle of notification
    	    	cx  = GenAppCGNListType
    	    	dx  = notification type
RETURN:		none
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NavigateUnlockSendNotification	proc	near
    	; unlock the notification block
    	call	MemUnlock

    	; initialize the reference count for one send below
    	mov 	ax, 1
    	call	MemInitRefCount

    	; send it
    	mov 	di, 1	    	    	    ; with data block
    	mov 	ax, cx	    	    	    ; GenAppGCNListType
    	call	NavigateRecordNotifEvent    ; di = record event
    	mov 	cx, ax	    	    	    ; GenAppGCNListType
    	call	NavigateSendNotifToAppGCN
	ret
NavigateUnlockSendNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NavigateRecordNotifEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record a notification event for later sending

CALLED BY:	
PASS:		bx  = notification data handle
    	    	dx  = notification type
    	    	di  = 1 if there is a data block
    	    	      0 if there is no data block
RETURN:		di  = recorded event
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NavigateRecordNotifEvent	proc	near
	uses	ax, bp
	.enter 

    	mov 	bp, bx	    	    	    	; handle of notification
    	mov 	cx, MANUFACTURER_ID_GEOWORKS	; manufactureID
    	mov 	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
    	tst 	di
    	jnz  	withBlock
    	mov 	ax, MSG_META_NOTIFY

withBlock:
    	mov 	di, mask MF_RECORD
    	call	ObjMessage

	.leave
	ret
NavigateRecordNotifEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NavigateSendNotifToAppGCN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification block to app GCN via the process

CALLED BY:	
PASS:		bx  = handle of notification block
    	    	cx  = GenAppGCNListType
    	    	di  = recorded event
RETURN:		none
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NavigateSendNotifToAppGCN	proc	near
	uses	bx,si,bp
	.enter 

    	mov 	dx, size GCNListMessageParams	; dx = size of stack
						; frame
    	sub 	sp, dx	    	    	    	; create the stack
						; frame
    	mov 	bp, sp
    	mov 	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
    	mov 	ss:[bp].GCNLMP_ID.GCNLT_type, cx
    	mov 	ss:[bp].GCNLMP_block, bx
    	mov 	ss:[bp].GCNLMP_event, di

    	; set appropriate flags
    	mov 	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS

    	; sent to the GCN list via the process -- NOTE: do not change
	; this to send via the app obj, as notification may be sent
	; from either the app thread or the UI thread.
    	mov 	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
    	call	GeodeGetProcessHandle 
    	clr 	si 
    	mov 	di, mask MF_STACK
    	call	ObjMessage

    	add 	sp, dx	    	    	    ; clean up stack
	.leave
	ret
NavigateSendNotifToAppGCN	endp

NavigateControlCode  ends
