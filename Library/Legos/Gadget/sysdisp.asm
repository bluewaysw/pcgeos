COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		sysdisp.asm

AUTHOR:		RON, Mar 20, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial revision


DESCRIPTION:
	
		

	$Id: sysdisp.asm,v 1.1 98/03/11 04:30:31 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	SystemDisplayClass
idata	ends

makePropEntry display, width, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_DISPLAY_GET_WIDTH>, \
	PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_DISPLAY_SET_WIDTH>

makePropEntry display, height, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_DISPLAY_GET_HEIGHT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_DISPLAY_SET_HEIGHT>

makePropEntry display, type, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_DISPLAY_GET_TYPE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_DISPLAY_SET_TYPE>


compMkPropTable SystemDisplayProperty, display, width, height, type
MakeSystemPropRoutines SystemDisplay, display



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemDisplayMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the system know our real class tree. 

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= SystemDisplayClass object
		ds:di	= SystemDisplayClass instance data
		ds:bx	= SystemDisplayClass object (same as *ds:si)
		es 	= segment of SystemDisplayClass
		ax	= message #
RETURN:		cx:dx	= fptr to class
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemDisplayMetaResolveVariantSuperclass	method dynamic SystemDisplayClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
		
		compResolveSuperclass SystemDisplay, ML2

SystemDisplayMetaResolveVariantSuperclass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemDisplayMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear default bits on object

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= SystemDisplayClass object
		ds:di	= SystemDisplayClass instance data
		ds:bx	= SystemDisplayClass object (same as *ds:si)
		es 	= segment of SystemDisplayClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemDisplayMetaInitialize	method dynamic SystemDisplayClass, 
					MSG_META_INITIALIZE
		.enter
		mov	di, offset SystemDisplayClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
	; clear the visual bits
		andnf	ds:[di].EI_state, not (mask ES_IS_GEN or mask ES_IS_VIS)
		.leave
		ret
SystemDisplayMetaInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemDisplayEntGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= SystemDisplayClass object
		ds:di	= SystemDisplayClass instance data
		ds:bx	= SystemDisplayClass object (same as *ds:si)
		es 	= segment of SystemDisplayClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemDisplayEntGetClass	method dynamic SystemDisplayClass, 
					MSG_ENT_GET_CLASS
		.enter
		mov	cx, segment SystemDisplayString
		mov	dx, offset SystemDisplayString
		.leave
		ret
SystemDisplayEntGetClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemDisplayGetWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_SYSTEM_DISPLAY_GET_WIDTH
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version
	gene	9/15/97		Made it work

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemDisplayGetWidth	method dynamic SystemDisplayClass, 
					MSG_SYSTEM_DISPLAY_GET_WIDTH
		uses	bp
		.enter

		call	GetScreenDims
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		
		.leave
		Destroy	ax, cx, dx
		ret
SystemDisplayGetWidth	endm


method GadgetUtilReturnReadOnlyError, SystemDisplayClass, MSG_SYSTEM_DISPLAY_SET_HEIGHT

method GadgetUtilReturnReadOnlyError, SystemDisplayClass, MSG_SYSTEM_DISPLAY_SET_WIDTH

method GadgetUtilReturnReadOnlyError, SystemDisplayClass, MSG_SYSTEM_DISPLAY_SET_TYPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemDisplayGetHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_SYSTEM_DISPLAY_GET_HEIGHT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version
	gene	9/15/97		Made it work

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemDisplayGetHeight	method dynamic SystemDisplayClass, 
					MSG_SYSTEM_DISPLAY_GET_HEIGHT
		uses	bp
		.enter

		call	GetScreenDims
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, dx
		
		.leave
		Destroy	ax, cx, dx
		ret
SystemDisplayGetHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemDisplayGetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the "type" property of the display

CALLED BY:	MSG_SYSTEM_DISPLAY_GET_TYPE
PASS:		*ds:si	= SystemDisplay object
		ds:di	= SystemDisplay instance data
		ds:bx	= SystemDisplay object (same as *ds:si)
		es 	= segment of SystemDisplay
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/10/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemDisplayGetType	method dynamic SystemDisplayClass, 
					MSG_SYSTEM_DISPLAY_GET_TYPE
		uses	bp

		.enter

	;
	; Get the DisplayType
	;
		call	UserGetDisplayType
		mov	al, ah
		clr	ah			;ax <- DisplayType
	;
	; Return it as an integer
	;
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax

		.leave
		ret
SystemDisplayGetType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetScreenDims
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the screen dimensions

CALLED BY:	SystemDisplayGetWidth(), SystemDisplayGetHeight()
PASS:		none
RETURN:		cx - screen width
		dx - screen height
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This is something of a pain to do.  We need a GenClass object with
	which to get the screen object, from which we can get the size
	of the screen window.  We use our process' application object.

	Alternatively, we could get the video driver and called its
	info routine directly.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/10/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetScreenDims	proc	near
		uses	bp, di
		.enter

	;
	; Get the application object
	;
		clr	bx			;bx <- current process
		call	GeodeGetAppObject
	;
	; Get the screen window
	;
		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, GUQT_SCREEN
		mov	di, mask MF_CALL
		call	ObjMessage		;bp <- window handle
	;
	; Get its bounds
	;
		mov	di, bp			;di <- window handle
		call	WinGetWinScreenBounds	;cx=right, dx=bottom
		inc	cx			;cx <- width
		inc	dx			;dx <- height

		.leave
		ret
GetScreenDims	endp
