COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mainLibrary.asm

AUTHOR:		Adam de Boor, Oct  6, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/ 6/94	Initial revision


DESCRIPTION:
	Library-entry routine.
		

	$Id: mainLibrary.asm,v 1.1 97/04/05 01:21:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry routine to make sure we're being loaded as an
		application and refuse to load otherwise.

CALLED BY:	(GLOBAL) kernel
PASS:		di	= LibraryCallType
		if LCT_ATTACH:
			^hdx	= AppLaunchBlock, if any (0 if none, under 2.2)
RETURN:		carry set if unhappy
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxLibraryEntry proc	far
		uses	ds, ax, bx
		.enter
		segmov	ds, dgroup, ax
		cmp	di, LCT_ATTACH
		jne	checkClientThread
		tst_clc	dx		; any ALB passed?
		jnz	done		; yes -- happy
		WARNING	YOU_NEED_TO_ADD_NO_MAILBOX_EQUAL_FALSE_TO_THE_UI_CATEGORY_SO_THE_MAILBOX_LIBRARY_GETS_LOADED_AS_AN_APPLICATION
		stc			; no -- refuse to load
done:
		.leave
		ret

checkClientThread:
	;
	; When OutboxFix and OutboxFix check the integrity of messages on
	; startup, they need to load and unload the data driver for each
	; message.  Since data driver (running on mailbox:0 in this case)
	; uses Mailbox lib, the system calls us with LCT_NEW_CLIENT_THREAD /
	; LCT_CLIENT_THREAD_EXIT, which would normally cause us to
	; force-queue MSG_MA_HAVE_CLIENTS_AGAIN / MSG_MA_CLIENTS_ALL_GONE to
	; the app object (also running on mailbox:0).  If there are too many
	; messages in outbox / inbox, we will run out of handles because of
	; too many events accumulated on mailbox:0.
	;
	; To avoid such a problem, we ignore LCT_NEW_CLIENT_THREAD /
	; LCT_CLIENT_THREAD_EXIT if the current thread is mailbox:0.  And
	; just for convenience, we ignore all other mailbox threads as well.
	; All mailbox threads are handled by the detach sequence, and there's
	; no need for the mainClientThreads hack to handle them.
	;
		call	GeodeGetProcessHandle	; bx = thread owner
		cmp	bx, handle 0
		je	done_clc

		cmp	di, LCT_NEW_CLIENT_THREAD
		jne	checkThreadExit

		inc	ds:[mainClientThreads]
		cmp	ds:[mainClientThreads], 1
		jne	done
		mov	ax, MSG_MA_HAVE_CLIENTS_AGAIN
		jmp	tellApp

checkThreadExit:
		cmp	di, LCT_CLIENT_THREAD_EXIT
		jne	done_clc
		
		Assert	ne, ds:[mainClientThreads], 0
		dec	ds:[mainClientThreads]
		jnz	done_clc
		
		mov	ax, MSG_MA_CLIENTS_ALL_GONE
tellApp:
		clr	di
		call	UtilForceQueueMailboxApp
done_clc:
		clc
		jmp	done
		
MailboxLibraryEntry endp
		public	MailboxLibraryEntry

Resident	ends
