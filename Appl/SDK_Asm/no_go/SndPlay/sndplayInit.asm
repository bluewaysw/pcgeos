COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		SndPlay (Sample PC GEOS application)
FILE:		sndplayInit.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/1/92		Initial version

DESCRIPTION:
	This file source code for the SndPlay application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: sndplayInit.asm,v 1.1 97/04/04 16:34:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SndPlayOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the method handler for the method that is sent out
		when the application is started up or restarted from
		state. After calling our superclass, we do any initialization
		that is necessary.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		ax = the message
		ds = es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SndPlayOpenApplication	method dynamic SndPlayGenProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
		uses	ax, cx, dx, bp
		.enter
	;
	;  Set up the list so we can store notes.
	;
		call	SoundPlayInitializeList		; nothing destroyed
	;
	;  Set up voices so we can make noise.
	;
		call	SoundPlayInitializeVoice	; nothing destroyed
	;
	;  Now call our superclass.
	;
		.leave
		mov	di, offset SndPlayGenProcessClass
		GOTO	ObjCallSuperNoLock
SndPlayOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SndPlayCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the method handler for the method that is sent out
		when the application is exited.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		ax = the message
		ds = es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SndPlayCloseApplication	method dynamic SndPlayGenProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION
		uses	ax, cx, dx, bp
		.enter
	;
	;  Turn off our voices.
	;
		call	SoundPlayCloseVoice		; nothing destroyed
	;
	;  Free up the notes-list.
	;		
		call	SoundPlayDestroyList		; nothing destroyed
	;
	;  Exit by calling our superclass.
	;
		.leave
		mov	di, offset SndPlayGenProcessClass
		GOTO	ObjCallSuperNoLock
SndPlayCloseApplication	endm


InitCode	ends		;end of CommonCode resource
