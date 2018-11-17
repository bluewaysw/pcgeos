COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel database manager.
FILE:		Register.asm

AUTHOR:		John Wedgwood, Jul 19, 1989

ROUTINES:
	Name			Description
	----			-----------
	DBRegister		Register interest in a database item.
	DBGroupRegister		Register interest in a database group.
	DBFileRegister		Register interest in a database file.

	DBUnRegister		Register disinterest in a database item.
	DBGroupUnRegister	Register disinterest in a database group.
	DBFileUnRegister	Register disinterest in a database file.

	DBNotify		Notify someone of a database item change.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	7/19/89		Initial revision

DESCRIPTION:
	Contains routines needed to implement the register/notify portion
	of the database manager.

	Applications can register interest in database items, groups, or files.
	When an item, group, or file changes, the interested parties will be
	notified of the change. This allows applications to share data and
	be notified if the data changes behind their backs.

	Of interest:
		DBFileUnRegister() can be used when an application is exiting
		to unregister interest in the entire data file. This means that
		you can register interest in many items or groups, but can
		unregister completely with a single function call.

	$Id: dbaseRegister.asm,v 1.1 97/04/05 01:17:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RarelyUsed	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register interest in a database item.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group.
		di = item.
		dx:*bp = output descriptor to notify.
		cx     = action to invoke on output descriptor.
RETURN:		nothing
DESTROYED:	nothing

NOTES:		The data passed to the output descriptor will be:
			cx = Database file handle.
			dx = Group number of item that changed.
			     (0 if the entire file has been marked dirty).
			bp = Item number.
			     (0 if the entire group has been marked dirty).

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0		;Not currently used

DBRegister	proc	far
	ret
DBRegister	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGroupRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register interest in a database group.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group.
		dx:*bp = output descriptor to notify.
		cx     = action to invoke on output descriptor.
RETURN:		nothing
DESTROYED:	nothing

NOTES:		The data passed to the output descriptor will be:
			cx = Database file handle.
			dx = Group number of item that changed.
			     (0 if the entire file has been marked dirty).
			bp = Item number.
			     (0 if the entire group has been marked dirty).

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0		;Not currently used

DBGroupRegister	proc	far
	ret
DBGroupRegister	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBFileRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register interest in a database file.

CALLED BY:	External.
PASS:		bx = Database file handle.
		dx:*bp = output descriptor to notify.
		cx     = actionto invoke on output descriptor.
RETURN:		nothing
DESTROYED:	nothing

NOTES:		The data passed to the output descriptor will be:
			cx = Database file handle.
			dx = Group number of item that changed.
			     (0 if the entire file has been marked dirty).
			bp = Item number.
			     (0 if the entire group has been marked dirty).

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0		;Not currently used

DBFileRegister	proc	far
	ret
DBFileRegister	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBUnRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal disinterest in a database item.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group.
		di = database item.
		dx:*bp = output descriptor that was saved away.
		cx     = action which would be invoked.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0		;Not currently used

DBUnRegister	proc	far
	ret
DBUnRegister	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGroupUnRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal disinterest in a database group.
		Unregistering for a group will unregister for all items in
		the group.

CALLED BY:	External.
PASS:		bx = Database file handle.
		ax = group.
		dx:*bp = output descriptor.
		cx     = action which would have been invoked.
RETURN:		nothing.
DESTROYED:	nothing.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0		;Not currently used

DBGroupUnRegister	proc	far
	ret
DBGroupUnRegister	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBFileUnRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal disinterest in a database file.
		Unregistering for a file will unregister for all groups in
		the file, and likewise all items in the groups.

CALLED BY:	External.
PASS:		bx = Database file handle.
		dx:*bp = output descriptor.
		cx     = action.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0		;Not currently used

DBFileUnRegister	proc	far
	ret
DBFileUnRegister	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify someone that a change has occurred.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ax = group.
		di = item.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBNotify	proc	far
	ret
DBNotify	endp

RarelyUsed	ends
