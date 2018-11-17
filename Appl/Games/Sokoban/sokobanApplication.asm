COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992-1995.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Sokoban
FILE:		sokobanApplication.asm

AUTHOR:		Steve Yegge, Dec 20, 1993

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_LOAD_OPTIONS   Load our options from the ini file.

    MTD MSG_META_SAVE_OPTIONS   Save our options to the ini file.

    INT SaveThemOptions         Writes options to ini file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/93	Initial revision

DESCRIPTION:

	Load/save options stuff.

	$Id: sokobanApplication.asm,v 1.1 97/04/04 15:12:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ApplicationCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanAppLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= SokobanApplicationClass object
		ds:di	= SokobanApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanAppLoadOptions	method dynamic SokobanApplicationClass,
						MSG_META_LOAD_OPTIONS
		.enter
	;
	;  Call the superclass.
	;
		mov	di, offset SokobanApplicationClass
		call	ObjCallSuperNoLock
	;		
	;  Get the ini file category.
	;
		sub	sp, INI_CATEGORY_BUFFER_SIZE
		movdw	cxdx, sssp
		
		mov	ax, MSG_META_GET_INI_CATEGORY
		call	ObjCallInstanceNoLock
		
		mov	ax, sp
	;
	;  Get the background color.
	;
		segmov	ds, ss
		mov_tr	si, ax				; ds:si = category
		mov	cx, cs				; cx:dx = key
		mov	dx, offset colorKey
		call	InitFileReadInteger		; ax = value
		jc	noColor
		
		mov	es:[colorOption], ax	
		jmp	short	doneColor
noColor:
		mov	es:[colorOption], C_WHITE	; default
doneColor:
	;
	;  Get the sound prefs.
	;
		mov	cx, cs				; cx:dx = key
		mov	dx, offset soundKey
		call	InitFileReadInteger		; ax = value
		jc	noOption
		mov	es:[soundOption], ax
		
		jmp	short	doneSound
noOption:
	;
	;  User hasn't previously saved options...use SSO_USE_DEFAULT.
	;
		mov	es:[soundOption], SSO_USE_DEFAULT
doneSound:
		add	sp, INI_CATEGORY_BUFFER_SIZE
	;
	;  Set the view's background color based on the INI setting.
	;
		call	UpdateViewColor

		.leave
		ret
		
colorKey	char	"color",0
soundKey	char	"sound",0

SokobanAppLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanAppSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save our options to the ini file.

CALLED BY:	MSG_META_SAVE_OPTIONS

PASS:		*ds:si	= SokobanApplicationClass object
		ds:di	= SokobanApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanAppSaveOptions	method dynamic SokobanApplicationClass, 
						MSG_META_SAVE_OPTIONS
		.enter
	;
	;  Call the superclass.
	;
		mov	di, offset SokobanApplicationClass
		call	ObjCallSuperNoLock
	;
	;  Mark busy.
	;
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	ObjCallInstanceNoLock
	;
	;  Save options to ini file.
	;
		call	SaveThemOptions
	;
	;  Mark not busy.
	;
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	ObjCallInstanceNoLock
		
		.leave
		ret
SokobanAppSaveOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveThemOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes options to ini file.

CALLED BY:	SokobanAppSaveOptions

PASS:		*ds:si	= SokobanApplication object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/16/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveThemOptions	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;		
	;  Get the ini file category.
	;
		sub	sp, INI_CATEGORY_BUFFER_SIZE
		mov	bp, sp				; ss:bp = category
		movdw	cxdx, ssbp
		
		mov	ax, MSG_META_GET_INI_CATEGORY
		call	ObjCallInstanceNoLock

		segmov	ds, ss

if SET_BACKGROUND_COLOR
	;
	;  Get the background color.
	;
		push	bp
		GetResourceHandleNS	BackgroundColorSelector, bx
		mov	si, offset	BackgroundColorSelector
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage		; ax = color

		pop	bp
		xchg	ax, bp			; bp = color, ss:ax = category
	;
	;  Write background color to ini file.
	;
		mov_tr	si, ax				; ds:si = category
		mov	cx, cs				; cx:dx = key
		mov	dx, offset colorKey
		call	InitFileWriteInteger

endif	; SET_BACKGROUND_COLOR

if PLAY_SOUNDS		
	;
	;  Get the sound options.
	;
		push	si
		GetResourceHandleNS	SoundItemGroup, bx
		mov	si, offset	SoundItemGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
		pop	si			; ds:si = category
		mov_tr	bp, ax			; bp = sound option
	;
	;  Write sound option to ini file.
	;
		mov	cx, cs
		mov	dx, offset soundKey
		call	InitFileWriteInteger
endif		
		add	sp, INI_CATEGORY_BUFFER_SIZE

		.leave
		ret
SaveThemOptions	endp


ApplicationCode	ends
