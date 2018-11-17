COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		mainTextMessages.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/15/93   	Initial version.

DESCRIPTION:
	

	$Id: mainTextMessages.asm,v 1.1 97/04/04 16:52:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupBeginPollingForMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set things up so that we'll poll for incoming messages

CALLED BY:	StartupOpenApplication

PASS:		ds - dgroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IStartupBeginPollingForMessages	proc near

	uses	ax,bx,cx,dx,di,si,bp

	.enter

	;
	; set the new timer interval
	;

	mov	bx, handle 0			;^hbx = process
	mov	cx, TICKS_PER_POLL_SERVER_FOR_MESSAGES
						;cx = ticks
	mov	ax, TIMER_EVENT_CONTINUAL	;ax = type
	clr	si
	mov	dx, MSG_STARTUP_POLL_SERVER_FOR_MESSAGES
	mov	di, cx				;interval
	call	TimerStart

assume	ds:dgroup

	mov	ds:[timerHandle],bx		;save OD of timer
	mov	ds:[timerID],ax

	.leave
	ret
IStartupBeginPollingForMessages	endp



InitCode	ends

CommonCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupSendTextMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Launch netmsg

PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
netmsgToken	GeodeToken	<<'N','M','S','G'>,0>
EC < netmsgName	char	"netmsgec.geo"	>
NEC < netmsgName	char	"netmsg.geo"	>

IStartupSendTextMessage	method	dynamic	StartupClass, 
					MSG_STARTUP_SEND_TEXT_MESSAGE
	.enter

	;
	; set up AppLaunchBlock for UserLoadApplication
	;

	mov	ax, size AppLaunchBlock
	mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_SHARABLE or \
					ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jc	done


	;
	; Copy the app filename in
	;

	mov	es, ax
	segmov	ds, cs
	mov	si, offset netmsgName
	mov	di, offset ALB_appRef.AIR_fileName
	mov	cx, size netmsgName
	rep	movsb

	;
	; Set the initial directory (do we need to do this?)
	;

	mov	es:[ALB_diskHandle], SP_DOCUMENT
	mov	{word} es:[ALB_path], C_BACKSLASH

	call	MemUnlock


	segmov	es, cs
	mov	ax, mask IACPCF_FIRST_ONLY
	mov	di, offset netmsgToken
	clr	cx, dx
	call	IACPConnect

	jc	done		; should put up an error, I suppose

	clr	cx
	call	IACPShutdown

done:
	.leave
	ret

IStartupSendTextMessage	endm





COMMENT @----------------------------------------------------------------------

FUNCTION:	IStartupStopTimer

DESCRIPTION:	Stop our timer.

CALLED BY:	IStartupOpenApplication, IStartupCloseApplication

PASS:		ds	= dgroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

IStartupStopTimer	proc	far

	clr	ax, bx

	xchg	bx, ds:[timerHandle]		;is there already a timer?
	tst	bx
	jz	done				;skip if not...

	xchg	ax, ds:[timerID]
	call	TimerStop

done:
	ret
IStartupStopTimer	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	IStartupPollServerForMessages --
					MSG_NET_POLL_SERVER_FOR_MESSAGES

DESCRIPTION:	Poll the NetWare file server for any console or personal
		messages that are queued for this workstation.

PASS:		ds, es - dgroup

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@
crString char	13,0

IStartupPollServerForMessages	method	dynamic StartupClass,
					MSG_STARTUP_POLL_SERVER_FOR_MESSAGES

	sub	sp, NET_TEXT_MESSAGE_BUFFER_SIZE
	mov	si, sp
	segmov	ds, ss

	call	NetTextMessagePoll
	jnc	done

haveMessage::
	mov	dx, ds				;set dx:bp = text string
	mov	bp, si

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle AlertText
	mov	si, offset AlertText

	tst	es:[alertMessageDisplayed]
	jz	setText

	;
	; If the text inside is not already too long, then let's append
	; to it. Otherwise, drop this on the floor.
	;

	push	dx, bp
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	dx, bp

MAX_ALERT_MESSAGE_TEXT_LENGTH equ 200

	cmp	ax, MAX_ALERT_MESSAGE_TEXT_LENGTH
	ja	done				;skip if already too much...

	;OK: the text object is not yet full. Just append to the end of it.
	;First, append a carriage return

	mov	ax, MSG_VIS_TEXT_APPEND_PTR	;default method
	push	ax, dx, bp
	clr	cx
	mov	dx, cs
	mov	bp, offset crString
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	ax, dx, bp

setText:

	;
	; Now, set (or append) the text.  dx:bp points to the
	; null-terminated string
	;

	clr	cx
	mov	di, mask MF_CALL
	call	ObjMessage

	;and make sure this dialog box is visible

	;set flag: the box has been displayed

	mov	es:[alertMessageDisplayed], TRUE

	mov	bx, handle AlertInteraction
	mov	si, offset AlertInteraction
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage

	mov	ax, SST_NOTIFY
	call	UserStandardSound		; play the sound

done:
	add	sp, NET_TEXT_MESSAGE_BUFFER_SIZE

	ret
IStartupPollServerForMessages	endm




COMMENT @----------------------------------------------------------------------

FUNCTION:	IStartupAlertCloseSummons -- MSG_NET_ALERT_CLOSE_SUMMONS

DESCRIPTION:	Close the alert dialog box, and allow our timer to
		check for other alerts.

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

IStartupAlertCloseSummons	method	StartupClass,
					MSG_STARTUP_CLOSE_ALERT_INTERACTION

	clr	ds:[alertMessageDisplayed]	;set to FALSE
	ret
IStartupAlertCloseSummons	endm

CommonCode	ends
