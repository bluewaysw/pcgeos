COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		utilsGlobal.asm

AUTHOR:		Adam de Boor, Jun  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 3/94		Initial revision


DESCRIPTION:
	Utility routines that are globally exported.
		

	$Id: utilsGlobal.asm,v 1.1 97/04/05 01:19:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UtilCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxLoadTransportDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to load a transport driver.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxTransport
RETURN:		carry set if couldn't load:
			ax	= GeodeLoadError
			bx	= destroyed
		carry clear if driver loaded:
			ax	= destroyed
			bx	= handle of driver
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxLoadTransportDriver proc	far
		.enter
		call	AdminGetTransportDriverMap
		call	DMapLoad
		.leave
		ret
MailboxLoadTransportDriver endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxLoadDataDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to load a data driver.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxStorage
RETURN:		carry set if couldn't load:
			ax	= GeodeLoadError
			bx	= destroyed
		carry clear if driver loaded:
			ax	= destroyed
			bx	= handle of driver
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxLoadDataDriver proc	far
		.enter
		call	AdminGetDataDriverMap
		call	DMapLoad
		.leave
		ret
MailboxLoadDataDriver endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxLoadDataDriverWithError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the data storage driver indicated by the given
		MailboxStorage token. Driver should be unloaded using
		MailboxFreeDriver.

		If the data driver cannot be loaded, because it cannot be
		found, the passed error string will be used to prompt the
		user to make the driver available, with the option to retry
		the load. If ax is 0, this is the same as MailboxLoadDataDriver

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxStorage
		*ds:ax	= error string to use
RETURN:		carry set if couldn't load:
			ax	= GeodeLoadError
			bx	= destroyed
		carry clear if driver loaded:
			bx	= handle of driver
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxLoadDataDriverWithError proc	far
		.enter
		call	MailboxLoadDataDriver
		.leave
		ret
MailboxLoadDataDriverWithError endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxFreeDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Negotiate with the DMap module to unload the passed driver

CALLED BY:	(GLOBAL)
PASS:		bx	= handle of driver to unload
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	driver may be unloaded

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxFreeDriver proc	far
		uses	ds, si, cx, dx, ax
		.enter
	;
	; Figure the map to use and what the driver's token is.
	; 
		call	GeodeInfoDriver
		movdw	cxdx, ds:[si].MBTDI_transport	; assume it's transport,
							;  as both storage &
							;  transport have this
							;  in the same place...
		cmp	ds:[si].DIS_driverType, DRIVER_TYPE_MAILBOX_TRANSPORT
		je	getTrans

		Assert	e, ds:[si].DIS_driverType, DRIVER_TYPE_MAILBOX_DATA
		call	AdminGetDataDriverMap
		jmp	haveMap
getTrans:
		call	AdminGetTransportDriverMap
haveMap:
		call	DMapUnload
		.leave
		ret
MailboxFreeDriver endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxPushToMailboxDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the thread's current directory and then change to
		the mailbox directory

CALLED BY:	(GLOBAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAILBOXPUSHTOMAILBOXDIR proc	far
		.enter
		call	FilePushDir
		call	MailboxChangeToMailboxDir
		.leave
		ret
MAILBOXPUSHTOMAILBOXDIR endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxChangeToMailboxDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to the mailbox library's spool directory

CALLED BY:	(GLOBAL) MailboxPushToMailboxDir
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	directory is created if it didn't exist

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAILBOXCHANGETOMAILBOXDIR proc	far
		uses	bx, ds, dx, ax
		.enter
		mov	bx, handle uiMailboxDir
		call	MemLock
		mov	ds, ax
		assume	ds:segment uiMailboxDir
		mov	dx, ds:[uiMailboxDir]
tryAgain:
		mov	bx, SP_PRIVATE_DATA
		call	FileSetCurrentPath
		jc	create

		call	UtilUnlockDS
		.leave
		ret
create:
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
		call	FileCreateDir
		jnc	tryAgain
		ERROR	UNABLE_TO_CREATE_MAILBOX_DIRECTORY
MAILBOXCHANGETOMAILBOXDIR endp

UtilCode	ends
