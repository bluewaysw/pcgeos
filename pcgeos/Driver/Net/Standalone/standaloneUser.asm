COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		standaloneUser.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/20/92   	Initial version.

DESCRIPTION:
	

	$Id: standaloneUser.asm,v 1.1 97/04/18 11:48:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StandaloneUserFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the DR_NET_USER_FUNCTION ops

CALLED BY:	StandaloneStrategy

PASS:		al - NetUserFunction

RETURN:		see netDr.def

DESTROYED:	di

PSEUDO CODE/STRATEGY:	
	This procedure is a fixed-code stub -- the real proc is
	StandaloneUserRealFunction 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StandaloneResidentCode	segment resource
StandaloneUserFunction	proc near
	call	StandaloneUserRealFunction
	ret
StandaloneUserFunction	endp
StandaloneResidentCode	ends

StandaloneCommonCode	segment resource

StandaloneUserRealFunction	proc far
	.enter
	clr	ah
	mov	di, ax
	call	cs:[netUserFunctionTable][di]

	.leave
	ret
StandaloneUserRealFunction	endp

netUserFunctionTable	nptr.near	\
	StandaloneUserStub,		; GET LOGIN
	StandaloneUserGetFullName,	; GET_FULL
	StandaloneUserStub,		; ENUM_CONNECTED_USERS
	StandaloneUserStub,		; VERIFY_PASSWORD
	StandaloneUserStub,		; GET_CONNECTION_NUMBER
	StandaloneUserStub,		; CHECK_IF_IN_GROUP
	StandaloneUserStub		; ENUM_USERS

.assert ($-netUserFunctionTable eq NetUserFunction)



COMMENT @----------------------------------------------------------------------

FUNCTION:	StandaloneGetUserFullName

DESCRIPTION:	copy the login name to the full name

PASS:		ds:si  - fptr to users login name
		cx:dx - buffer to fill in with real name

RETURN:		buffer filled in

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	11/92		initial version

------------------------------------------------------------------------------@
StandaloneUserGetFullName	proc	near

	uses	ax,cx

	.enter

	mov	es, cx
	mov	di, dx
startLoop:
	lodsb
	stosb
	tst	al
	jnz	startLoop

	.leave
	ret
StandaloneUserGetFullName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StandaloneUserStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StandaloneUserStub	proc near
	ret
StandaloneUserStub	endp



StandaloneCommonCode	ends
