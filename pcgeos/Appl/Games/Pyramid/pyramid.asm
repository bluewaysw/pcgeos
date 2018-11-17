COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1991-1995.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Pyramid
FILE:		pyramid.asm

AUTHOR:		Jon Witort, Jan 17, 1991

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_GEN_PROCESS_OPEN_APPLICATION 
				Sends the game object a
				MSG_GAME_SETUP_STUFF which readies
				everything for an exciting session of
				pyramid!

    INT PyramidCheckIfGameIsOpen 
				Will check if the varData
				ATTR_PYRAMID_GAME_OPEN exists for
				MyPlayingTable

    INT PyramidMarkGameOpen     Will add the varData ATTR_PYRAMID_GAME_OPEN
				to MyPlayingTable

    INT PyramidSetViewBackgroundColor 
				Set the background color of the view to
				green if on	 a color display and white
				if on a black and white display

    MTD MSG_GEN_PROCESS_CLOSE_APPLICATION 
				Misc shutdown stuff.

    INT PyramidUpdateOptions    Get options from INI file and update UI.

    INT PyramidIgnoreAcceptInput 
				Ignore or accept input.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/7/91		Initial version
	jacob	6/15/95		initial Jedi version
	stevey	8/8/95		added Undo feature (+comments :)

DESCRIPTION:

  Some terminology:
			   _/\_
			 _/    \_
		       _/        \_
                     _/	           \_
		   _/	             \_
	         _/	               \_
	       _/	  Cards 	 \_
	     _/	  (aka Tableau Elements)   \_
	   _/         = decks 4-31           \_
         _/            (or A1-G7) 	       \_
	/					 \
       +------------------------------------------+

	+--------+	+--------+      +--------+
	|	 |	|	 |      |	 |
	|	 |	| TopOf- |      |  My-	 |
	| MyHand |	| MyHand |      | Talon  |
	|	 |	|	 |      |	 |
	|(deck 1)|	|(deck 2)|      |(deck 3)|
	|	 |	|	 |      |	 |
	+--------+     	+--------+      +--------+

  There's also a MyDiscard deck sitting around that you can't see.

	$Id: pyramid.asm,v 1.1 97/04/04 15:15:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Application		= 1

include	stdapp.def
include initfile.def
include	assert.def

;-----------------------------------------------------------------------------
;			Product shme
;-----------------------------------------------------------------------------

	_JEDI			equ	FALSE


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	cards.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		myMacros.def
include		sizes.def
include		pyramid.def
include 	pyramid.rdef

include		pyramidGame.asm
include		pyramidDeck.asm

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PyramidOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the game object a MSG_GAME_SETUP_STUFF which readies
		everything for an exciting session of pyramid!


CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:	 	cx	- AppAttachFlags
		dx	- Handle of AppLaunchBlock, or 0 if none.
		  	  This block contains the name of any document file
			  passed into the application on invocation.  Block
			  is freed by caller.
		bp	- Handle of extra state block, or 0 if none.
		  	  This is the same block as returned from
		  	  MSG_GEN_PROCESS_CLOSE_APPLICATION, in some previous
			  MSG_META_DETACH.  Block is freed by caller.

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11/90		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidOpenApplication method dynamic	PyramidProcessClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION
	.enter

	call	PyramidSetViewBackgroundColor
	call	PyramidCheckIfGameIsOpen	; check for the Lazaurs case
	jnc	gameNotOpen			; the game isn't open

gameAlreadyOpen::

	mov	di, segment PyramidProcessClass
	mov	es, di
	mov	di, offset PyramidProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock
	jmp	done

gameNotOpen:
	test	cx, mask AAF_RESTORING_FROM_STATE
	jz	startingUp
	;
	;  We're restoring from state!  Restore card bitmaps.
	;
	push	cx, dx, bp			; save passed values
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_GAME_RESTORE_BITMAPS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp			; restore passed values

	mov	di, segment PyramidProcessClass
	mov	es, di
	mov	di, offset PyramidProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock

	jmp	markGameOpen

startingUp:
	;
	;  Startup up for 1st time.
	;
	push	cx, dx, bp			; save passed values
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_GAME_SETUP_STUFF
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp			; restore passed values

	mov	di, segment PyramidProcessClass
	mov	es, di
	mov	di, offset PyramidProcessClass
	mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	ObjCallSuperNoLock

	;
	;  We're not restoring from state, so we need to create a full
	;  deck and start a new game here
	;

	CallObject MyHand, MSG_HAND_MAKE_FULL_HAND, MF_FIXUP_DS
	CallObject MyPlayingTable, MSG_PYRAMID_NEW_GAME, MF_FORCE_QUEUE

	;
	;  Update options from INI file.
	;
	call	PyramidUpdateOptions

markGameOpen:
	;
	;  Mark game as "open" for avoiding Lazarus bugs.
	;
	call	PyramidMarkGameOpen
done:
	.leave
	ret
PyramidOpenApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidCheckIfGameIsOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will check if the varData ATTR_PYRAMID_GAME_OPEN 
		exists for MyPlayingTable

CALLED BY:	PyramidOpenApplication

PASS:		nothing

RETURN:		carry set if vardata found
		carry clear if not found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	7/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidCheckIfGameIsOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, size GetVarDataParams
	mov	bp, sp
	mov	ss:[bp].GVDP_dataType, \
		ATTR_PYRAMID_GAME_OPEN
	mov	{word} ss:[bp].GVDP_bufferSize, 0
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_META_GET_VAR_DATA
	mov	dx, size GetVarDataParams
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size GetVarDataParams
	cmp	ax, -1				; check if not found
	stc
	jne	varDataFound
	clc

varDataFound:

	.leave
	ret
PyramidCheckIfGameIsOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidMarkGameOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will add the varData ATTR_PYRAMID_GAME_OPEN to
		MyPlayingTable

CALLED BY:	PyramidOpenApplication

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	7/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidMarkGameOpen	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	sub	sp, size AddVarDataParams
	mov	bp, sp
	mov	ss:[bp].AVDP_dataType, \
		ATTR_PYRAMID_GAME_OPEN
	mov	{word} ss:[bp].AVDP_dataSize, size byte
	clrdw	ss:[bp].AVDP_data
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size AddVarDataParams

	.leave
	ret
PyramidMarkGameOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidSetViewBackgroundColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the background color of the view to green if on	
		a color display and white if on a black and white
		display

CALLED BY:	PyramidOpenApplication

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get the display mode
	- if color, set view color to green
	- of monochrome, set to white

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidSetViewBackgroundColor		proc	near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	;
	;  Use VUP_QUERY to field to avoid building GenApp object.
	;

        mov     bx, segment GenFieldClass
        mov     si, offset GenFieldClass
        mov     ax, MSG_VIS_VUP_QUERY
        mov     cx, VUQ_DISPLAY_SCHEME          ; get display scheme
        mov     di, mask MF_RECORD
        call    ObjMessage                      ; di = event handle

        mov     cx, di                          ; cx = event handle
        mov     bx, handle PyramidApp
        mov     si, offset PyramidApp
        mov     ax, MSG_GEN_CALL_PARENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
        call    ObjMessage	          ; ah = display type, bp = ptsize

	;
	;  Assume color display.
	;
	mov	cx, ((CF_INDEX or (CMT_DITHER shl offset  CMM_MAP_TYPE)) \
				shl 8) or C_GREEN
	and 	ah, mask DT_DISP_CLASS
	cmp	ah, DC_GRAY_1 shl offset DT_DISP_CLASS
	jne	setColor
	mov	cx, ((CF_INDEX or (CMT_DITHER shl offset  CMM_MAP_TYPE)) \
				shl 8) or C_WHITE
setColor:
	mov	bx, handle PyramidView
	mov	si, offset PyramidView
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GEN_VIEW_SET_COLOR
	call	ObjMessage

	.leave
	ret
PyramidSetViewBackgroundColor		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Misc shutdown stuff.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		es = segment of PyramidProcessClass

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidCloseApplication	method dynamic PyramidProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION
	uses	ax, cx, dx, bp, si
	.enter

	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_GAME_SHUTDOWN
	call	ObjMessage

	.leave
	mov	di, offset PyramidProcessClass
	GOTO	ObjCallSuperNoLock
PyramidCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine saves the current settings of the options menu
		to the .ini file.

CALLED BY:	MSG_META_SAVE_OPTIONS

PASS:		nothing
RETURN:		nothing

DESTROYED:	ax, cx, cx, bp
 
PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidSaveOptions	method	PyramidProcessClass, MSG_META_SAVE_OPTIONS

	;
	; Save which back
	;
	mov	ax, MSG_GAME_GET_WHICH_BACK
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	mov	di, mask MF_CALL
	call	ObjMessage		; cx <- starting level

	mov	bp, cx			; bp <- value
	mov	cx, cs
	mov	ds, cx
	mov	si, offset pyramidCategoryString
	mov	dx, offset pyramidWhichBackString
	call	InitFileWriteInteger

	;
	; Save the number of cards to flip each time
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	bx, handle SumToList
	mov	si, offset SumToList
	mov	di, mask MF_CALL
	call	ObjMessage		; ax <- starting level

	mov_tr	bp, ax			; bp <- value
	mov	cx, ds
	mov	si, offset pyramidCategoryString
	mov	dx, offset pyramidSumString
	call	InitFileWriteInteger

	;
	;  Save fade mode.
	;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	bx, handle GameOptions
	mov	si, offset GameOptions
	mov	di, mask MF_CALL
	call	ObjMessage		;LES_ACTUAL_EXCL set if on...

 ;	and	ax, 1			;filter through fade bit  ???? jfh
	mov  bp, ax               ; get bools info to integer
	mov	cx, ds
	mov	si, offset pyramidCategoryString
	mov	dx, offset pyramidOptionsString
	call	InitFileWriteInteger
	call	InitFileCommit

	ret
PyramidSaveOptions	endm

pyramidCategoryString		char	"pyramid",0
pyramidWhichBackString		char	"whichBack",0
pyramidSumString		char	"sumTo",0
pyramidOptionsString		char	"options",0
pyramidStatusBarString		char	"statusBar",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidUpdateOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get options from INI file and update UI.

CALLED BY:	PyramidOpenApplication

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 8/95		broke out of PyramidOpenApplication

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidUpdateOptions	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	;  Get which card back we're using.
	;
	mov	cx, cs
	mov	ds, cx			;DS:SI <- ptr to category string
	mov	si, offset pyramidCategoryString
	mov	dx, offset pyramidWhichBackString
	call	InitFileReadInteger
	jc	sumTo

	mov_trash	cx, ax				;cx <- which back
	mov	ax, MSG_GAME_SET_WHICH_BACK
	mov	bx, handle MyPlayingTable
	mov	si, offset MyPlayingTable
	clr	di
	call	ObjMessage

sumTo:
	;
	;  Get the sum-to number.
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset pyramidCategoryString
	mov	dx, offset pyramidSumString
	call	InitFileReadInteger
	jc	hide

	mov_tr	cx, ax				;cx <- which back
	clr	dx				; not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, handle SumToList
	mov	si, offset SumToList
	clr	di
	call	ObjMessage
hide:
	;
	; Get options & update UI.
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset pyramidCategoryString	; category
	mov	dx, offset pyramidOptionsString		; key
	call	InitFileReadInteger
	jc	statusBar

	mov_tr	cx, ax
	clr	dx
	mov	bx, handle GameOptions
	mov	si, offset GameOptions
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE	
	clr	di
	call	ObjMessage

statusBar:
	;
	; Set usable or not the "Status Bar"
	;
	clr	ax				; assume FALSE
	mov	cx, cs
	mov	ds, cx
	mov	si, offset pyramidCategoryString	;category
	mov	dx, offset pyramidStatusBarString	;key
	call	InitFileReadBoolean		;look into the .ini file
	tst	ax
	jz	done				; if not present, do nothing

	mov	ax, MSG_GEN_SET_USABLE
	mov	bx, handle StatusBar
	mov	si, offset StatusBar
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	di
	call	ObjMessage
done:
	.leave
	ret
PyramidUpdateOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PyramidIgnoreAcceptInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore or accept input.

CALLED BY:	UTILITY

PASS:		ax = MSG_GEN_APPLICATION_ACCEPT_INPUT,
		     MSG_GEN_APPLICATION_IGNORE_INPUT,
		     MSG_GEN_APPLICATION_MARK_BUSY, or
		     MSG_GEN_APPLICATION_MARK_NOT_BUSY

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PyramidIgnoreAcceptInput	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		mov	bx, handle PyramidApp
		mov	si, offset PyramidApp
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
PyramidIgnoreAcceptInput	endp


CommonCode	ends
