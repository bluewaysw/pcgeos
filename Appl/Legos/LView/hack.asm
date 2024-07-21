COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		hack.asm

AUTHOR:		jimmy, Mar 25, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/25/96   	Initial revision


DESCRIPTION:
	this code allows us to free up stuff after the system goes
	Idle, prevent problems with objects and runtasks going away
	too early. this used to happen because of our use of
	UserDoDialog, RunMainMessageDispatch which send message from
	the queue on before their normal time
		

	$Id: hack.asm,v 1.4 98/10/15 13:31:18 martin Exp $
	$Revision: 1.4 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include resource.def
include Internal/heapInt.def
include ec.def


ifdef __BORLANDC__
EC  <LVHACK_E_TEXT	segment  public "CODE" byte			>
NEC <LVHACK_G_TEXT	segment  public "CODE" byte			>
	global	_LViewSendDestroyMsg:far
NEC <LVHACK_G_TEXT	ends						>
EC  <LVHACK_E_TEXT	ends						>
elifdef __WATCOMC__
	global	_LViewSendDestroyMsg:far
else
	global	LViewSendDestroyMsg:far
endif

lvhack_TEXT 	segment  public "CODE" byte

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LViewIdleHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		the idea is that we want to destroy the extra runtasks
	and objects that got created during the run. we have waited
	until the system is idle, as that seems to be the only way we
	can be sure it is safe to destroy objects and runtasks.

	the first things we do is remove ourselves from the idle
	intercept list since we only need to get called once, then we
	send the app object a message telling it to free everything
	up. this seems to work in all cases and eliminates the need to
	destroying things in a delayed manner as we used to do.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LViewIdleHandler	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	; remove ourselves from the idle intercept list first
		mov	dx, cs
		mov	ax, offset LViewIdleHandler
		call	SysRemoveIdleIntercept
	; send the app object a destroy stuff message
	; (written in GOC for convenience)
ifdef __BORLANDC__
		call	_LViewSendDestroyMsg
elifdef __WATCOMC__
		call	_LViewSendDestroyMsg
else
		call	LViewSendDestroyMsg
endif
		.leave
		ret
LViewIdleHandler	endp
	
lvhack_TEXT	ends



lvview_TEXT segment public  "CODE"  byte

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InstallSysIdleHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	install a sys idle handler

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	add ourselves to the idle intercept list so we can find out
	when the system has gone idle		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_InstallSysIdleHandler	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		mov	dx, segment LViewIdleHandler
		mov	ax, offset LViewIdleHandler
		call	SysAddIdleIntercept
		.leave
		ret
_InstallSysIdleHandler	endp
	public _InstallSysIdleHandler

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UninstallSysIdleHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	uninstall a sys idle handler

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	add ourselves to the idle intercept list so we can find out
	when the system has gone idle		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_UninstallSysIdleHandler	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		mov	dx, segment LViewIdleHandler
		mov	ax, offset LViewIdleHandler
		call	SysRemoveIdleIntercept
		.leave
		ret
_UninstallSysIdleHandler	endp
	public _UninstallSysIdleHandler
		
lvview_TEXT ends
