COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mainProcess.asm

AUTHOR:		Adam de Boor, May 31, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/31/94		Initial revision


DESCRIPTION:
	Process class, dude
		

	$Id: mainProcess.asm,v 1.1 97/04/05 01:21:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeThreadPriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes the priority for the current thread

CALLED BY:	GLOBAL
PASS:		al - new priority
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/24/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeThreadPriority	proc	near	uses	ax, bx
	.enter
	clr	bx
	mov	ah, mask TMF_BASE_PRIO
	call	ThreadModify
	.leave
	ret
ChangeThreadPriority	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	MailboxProcessAttach -- 
	MSG_META_ATTACH for MailboxProcessClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This method is called when we start up, so we lower our
		thread priority here...

PASS:		*ds:si 	- instance data of MailboxProcessClass object
		ds:di	- MailboxProcessClass instance data
		ds:bx	- MailboxProcessClass object (same as *ds:si)
		es     	- segment of MailboxProcessClass
		ax 	- MSG_META_ATTACH

RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/24/96	Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxProcessAttach	method dynamic	MailboxProcessClass, \
				MSG_META_ATTACH

	push	ax	
	mov	al, PRIORITY_LOW
	call	ChangeThreadPriority
	pop	ax
	mov	di, offset MailboxProcessClass
	GOTO	ObjCallSuperNoLock
MailboxProcessAttach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGenProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start le ball rollez

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		ds	= dgroup
		cx	= AppAttachFlags
		^hdx	= AppLaunchBlock
		bp	= handle of extra state block
RETURN:		nothing (ALB & state blocks *not* freed)
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGenProcessOpenApplication method MailboxProcessClass, 
				MSG_GEN_PROCESS_OPEN_APPLICATION
		.enter
	;
	; Attempt to open the admin file, FIRST so application object can mess
	; with it in META_ATTACH.
	; 
		call	AdminInit
		jc	dieYouGravySuckingPig

		mov	di, offset MailboxProcessClass
		call	ObjCallSuperNoLock
	;
	; Arrange to receive SST_MAILBOX notifications.
	; 
		mov	si, SST_MAILBOX
		mov	cx, vseg MainMailboxNotify
		mov	dx, offset MainMailboxNotify
		call	SysHookNotification

	;
	; Also, SST_MEDIUM notifications.
	;
		mov	si, SST_MEDIUM
		mov	cx, vseg MainMediumNotify
		mov	dx, offset MainMediumNotify
		call	SysHookNotification

	;
	; Load the serial driver to get notifications for the serial ports on
	; the machine.
	; XXX: should we just look in the [media] category ourselves, here?
	; 
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath

		segmov	ds, cs
		mov	si, offset serialName
		mov	ax, SERIAL_PROTO_MAJOR
		mov	bx, SERIAL_PROTO_MINOR
		call	GeodeUseDriver
		jc	serialStuffDone
	;
	; Now unload it again :) it will have generated the necessary
	; notifications about the media in the machine.
	; 
		call	GeodeFreeDriver
serialStuffDone:
	;
	; Notify ourselves that the mythical GMID_LOOPBACK medium is
	; available.
	;
	        mov     si, SST_MEDIUM
	        mov     di, MESN_MEDIUM_AVAILABLE
	        mov     cx, MANUFACTURER_ID_GEOWORKS
        	mov     dx, GMID_LOOPBACK
	        mov     al, MUT_NONE
		call	SysSendNotification

if _SHORT_MESSAGE_MEDIUM
	;
	; Notify ourselves that the GMID_SM medium is available.
	;
	        mov     si, SST_MEDIUM
	        mov     di, MESN_MEDIUM_AVAILABLE
	        mov     cx, MANUFACTURER_ID_GEOWORKS
        	mov     dx, GMID_SM
	        mov     al, MUT_NONE
		call	SysSendNotification
endif		
		call	FilePopDir


;	Change the priority back to normal
		mov	al, PRIORITY_FOCUS
		call	ChangeThreadPriority

		.leave
		ret

dieYouGravySuckingPig:
		ERROR	-1
MPGenProcessOpenApplication endm

EC <LocalDefNLString	serialName, <"SERIALEC.GEO",0>			>
NEC <LocalDefNLString	serialName, <"SERIAL.GEO",0>			>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGenProcessCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent us from saving to state...

CALLED BY:	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
PASS:		ds	= dgroup
RETURN:		ax	= new state file handle (0 => don't save to state)
DESTROYED:	nothing
SIDE EFFECTS:	having no state file means we also don't get restarted
     			by the system field when it restores from state,
			which is a Good Thing.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGenProcessCreateNewStateFile method MailboxProcessClass, 
				MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		.enter
		clr	ax
		.leave
		ret
MPGenProcessCreateNewStateFile endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPGenProcessCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close down everything

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		*ds:si	= MessageProcess object
		ds:di	= MessageProcessInstance
RETURN:		cx	= handle of extra state block (0 if none)
DESTROYED:	ax, dx, bp
SIDE EFFECTS:	admin file is closed & SST_MAILBOX notification released

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MPGenProcessCloseApplication method dynamic MailboxProcessClass, 
				MSG_GEN_PROCESS_CLOSE_APPLICATION
		.enter
		call	VMStoreExit
		call	AdminExit
	;
	; Stop getting mailbox notifications.
	; 
		mov	si, SST_MAILBOX
		mov	cx, vseg MainMailboxNotify
		mov	dx, offset MainMailboxNotify
		call	SysUnhookNotification
	;
	; Also, SST_MEDIUM notifications.
	;
		mov	si, SST_MEDIUM
		mov	cx, vseg MainMediumNotify
		mov	dx, offset MainMediumNotify
		call	SysUnhookNotification
		clr	cx		; no extra state block
		.leave
		ret
MPGenProcessCloseApplication endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPMetaQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore all quits.

CALLED BY:	MSG_META_QUIT
PASS:		ax	= message #
		dx	= QuitLevel
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/15/95   	Initial version (copied from SpoolQuit)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS
MPMetaQuit	method dynamic MailboxProcessClass, 
					MSG_META_QUIT

	; we just want to ignore all quits (this will happen e.g.
	; if the user presses F3 while the Outbox panel is up). So
	; send back a message that we're aborting the quit.

	call	GeodeGetProcessHandle	; bx = process handle
	mov_tr	cx, ax			; cx non-zero, want to abort the quit
	mov	ax, MSG_META_QUIT_ACK
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

MPMetaQuit	endm
endif	; _CONTROL_PANELS

Init		ends


