COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Taipei (Trivia project: PC GEOS application)
FILE:		TaipeiInit.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/23/95		Initial version

DESCRIPTION:
	This file is a source code for the Taipei application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS Stamp:

	$Id: taipeiInit.asm,v 1.1 97/04/04 15:14:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;		Uninitialized global variables
;------------------------------------------------------------------------------

udata	segment

udata	ends

TaipeiClassStructures 	segment resource
	TaipeiApplicationClass
TaipeiClassStructures	ends

;------------------------------------------------------------------------------
;				Code
;------------------------------------------------------------------------------
InitCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the method handler for the method that is sent out
		when the application is started up or restarted from
		state. After calling our superclass, we do any initialization
		that is necessary.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		ax = the message
		ds = es = dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp destroyed

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiOpenApplication	method dynamic TaipeiProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
	tst	cx
	jnz	loadFromStateFile
	;
	; Randomize Index array
	;
		call	TaipeiRandomizeIndexArray	; nothing destroyed
	;
	; Create and initialize the tiles
	;
		call	TaipeiInitContentAndTiles	; nothing destroyed
	;
	; the timer will be started when TaipeiViewContent is initialized.
	;
	;	call	TaipeiStartTimer		; nothing destroyed
	;
	; Now call our superclass.
	;
loadFromStateFile:
		mov	di, offset TaipeiProcessClass
		GOTO	ObjCallSuperNoLock

TaipeiOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TPGenProcessCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't create a state file on Jedi.

CALLED BY:	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE

PASS:		*ds:si	= TaipeiProcessClass object
		ds:di	= TaipeiProcessClass instance data

RETURN:		ax = 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;if _JEDI

;TPGenProcessCreateNewStateFile	method dynamic TaipeiProcessClass, 
;					MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE

;		clr	ax

;		ret
;TPGenProcessCreateNewStateFile	endm

;endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiCloseApplication
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
	kho	1/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiCloseApplication	method dynamic TaipeiProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION
	;
	; call ViewContent to turn off the timer
	;
		call	TaipeiStopTimer			; nothing destroyed
	;
	; Exit by calling our superclass.
	;
		mov	di, offset TaipeiProcessClass
		GOTO	ObjCallSuperNoLock
TaipeiCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiRandomizeIndexArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the chunk array that holds the tile info, 
		and randomize it

CALLED BY:	TaipeiOpenApplication (by MSG_GEN_PROCESS_OPEN_APPLICATION)

PASS:		*ds:si = app object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		Get the BoardInfo chunk array
		for (i = 0; i < INITIAL_NUMBER_OF_TILES; i++) {
			j = GameRandom(INITIAL_NUMBER_OF_TILES);
			swap(   BoardInfo[i].BCT_type,
				BoardInfo[j].BCT_type  );
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/31/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiRandomizeIndexArray	proc	far
		uses	ax, bx, cx, dx, ds, di, si, bp
		.enter
		GetResourceHandleNS DataResource, bx	; bx <- handle of
							; DataResource 
		call	MemLock				; ax <- segment of
							; lmem block
		mov	ds, ax				; ds <- segment lmem
		mov	si, offset BoardInfo		; *ds:si <- chunk
							; array 

		clr	bx
changeOne:	cmp	bx, INITIAL_NUMBER_OF_TILES
		jge	finish

	;
	; Pick a random number
	;
		mov	dx, INITIAL_NUMBER_OF_TILES
		call	GameRandom			; dx <- Random(144)
							; ds _NOT_ destroyed
	;
	; Get the (bx)th ptr
	;		
		mov	ax, bx
		call	ChunkArrayElementToPtr		; ds:di - element
		segmov	bp, di				; ds:bp - (bx)th

	;
	; Get the (dx)th ptr
	;
		mov	ax, dx
		call	ChunkArrayElementToPtr		; ds:di - (dx)th

	;
	; Swap
	;
		mov	cx, ds:[di].BCT_type
		mov	dx, ds:[bp].BCT_type
EC <		Assert	etype, cx, TaipeiTileType			>
EC <		Assert	etype, dx, TaipeiTileType			>
		
		mov	ds:[di].BCT_type, dx
		mov	ds:[bp].BCT_type, cx
		
		inc	bx
		jmp	changeOne
		
finish:		GetResourceHandleNS DataResource, bx	; bx <- handle of
							; DataResource 
		call	MemUnlock			; ds destroyed
							; in EC
		.leave
		ret
TaipeiRandomizeIndexArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiInitContentAndTiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the ViewContent, and create the vobj tiles

CALLED BY:	TaipeiNewFile
PASS:		ds = dgroup		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiInitContentAndTiles	proc	near
		uses	ax, bx, dx, di, si
		.enter
	;
	; Call MSG_TAIPEI_CONTENT_INITIALIZE
	; TaipeiViewContent is in AppInterface (*.ui)
	;
		GetResourceHandleNS AppInterface, bx    
		mov     si, offset TaipeiViewContent	; ^lbx:si <- object
		mov     ax, MSG_TAIPEI_CONTENT_INITIALIZE
		mov     di, mask MF_CALL
		call    ObjMessage                      ; ax, di destroyed
	;
	; Call MSG_TAIPEI_CONTENT_CREATE_TILES
	; TaipeiViewContent is in AppInterface (*.ui)
	;
		mov     ax, MSG_TAIPEI_CONTENT_CREATE_TILES	
		mov     di, mask MF_CALL
		call    ObjMessage                      ; ax, dx, di destroyed
		.leave		
		ret

TaipeiInitContentAndTiles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiStopTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the timer by sending a message to TaipeiViewContent

CALLED BY:	INTERNAL
PASS:		(?)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiStopTimer	proc	near
		uses	ax, bx, di, si
		.enter
	;
	; Call MSG_TAIPEI_CONTENT_STOP_TIMER
	; TaipeiViewContent is in AppInterface (*.ui)
	;
		GetResourceHandleNS AppInterface, bx    
		mov     si, offset TaipeiViewContent	; ^lbx:si <- object
		mov     ax, MSG_TAIPEI_CONTENT_STOP_TIMER
;		mov     di, mask MF_CALL             ; this causes deadlock
;		clr	di
		mov	di, mask MF_FIXUP_DS		
		call    ObjMessage                      ; ax, di destroyed
		.leave
		ret
TaipeiStopTimer	endp




InitCode	ends		;end of InitCode resource

