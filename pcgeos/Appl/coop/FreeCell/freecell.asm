COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		freecell.asm

AUTHOR:		Mark Hirayama, July 8, 1993

ROUTINES:
	Name				Description
	----				-----------
	FreeCellProcessOpenApplication	Initial handler that gets everything
					ready for a session of FreeCell.
					Also begins a new game.

	FreeCellProcessCloseApplication	Performs necessary cleaning up
					procedures when the application
					is exited.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/8/93		Initial verison

DESCRIPTION:
	Implementation of the FreeCell class

	$Id: freecell.asm,v 1.1 97/04/04 15:02:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the initial handler that gets everything
		ready for a session of FreeCell.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		*ds:si	= FreeCellProcessClass object
		es 	= segment of FreeCellProcessClass
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
	- Dispatch this message to superclass.
	- Dispatch SETUP_STUFF message to the FreeCell object.
	- Dispatch NEW_GAME message to the FreeCell object.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellProcessOpenApplication	method dynamic FreeCellProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
	uses	ax
	.enter

	;
	; Allow our superclass to handle this message also.
	;
		mov	di, offset es:FreeCellProcessClass
		call	ObjCallSuperNoLock
	;
	; Send SETUP_GAME_SETUP_STUFF message to FreeCell object
	;
		GetResourceHandleNS MyPlayingTable, bx
		mov	si, offset MyPlayingTable
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GAME_SETUP_STUFF
		call	ObjMessage
	;
	; Send NEW_GAME message to FreeCell object.
	;
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_FREECELL_NEW_GAME
		call	ObjMessage

	.leave
	ret
FreeCellProcessOpenApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCellProcessCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs necessary cleaning up procedures when the
		application is exited.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		*ds:si	= FreeCellProcessClass object
		es 	= segment of FreeCellProcessClass
		ax	= message #

RETURN:		cx - handle of block to save (returned by call to
		     superclass).

DESTROYED:	nothing

SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
	- Send SHUTDOWN message to the FreeCell object.
	- Dispatch this message to superclass.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCellProcessCloseApplication	method dynamic FreeCellProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION
	uses	ax, dx, bp
	.enter

	;
	; Send SHUTDOWN message to FreeCell object.
	;
		GetResourceHandleNS MyPlayingTable, bx
		mov	si, offset MyPlayingTable
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GAME_SHUTDOWN
		call	ObjMessage
	;
	; Allow our superclass to handle this message also.
	;
		mov	di, offset es:FreeCellProcessClass
		mov	ax, MSG_GEN_PROCESS_CLOSE_APPLICATION
		call	ObjCallSuperNoLock
		
	.leave
	ret
FreeCellProcessCloseApplication	endm



CommonCode	ends

















