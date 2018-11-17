COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Mine
FILE:		mine.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik   1/92		Initial program

DESCRIPTION:
	This file is the source code for the Mine application, a clone of 
	the popular 'MineSweeper' game for Windows.

RCS STAMP:
	$Id: mine.asm,v 1.1 97/04/04 14:51:59 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include timer.def
include timedate.def
include system.def
include dbase.def
include object.def
include graphics.def
include gstring.def	; included for ICON usage
include Internal/threadIn.def
include initfile.def

include Objects/winC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def
UseLib game.def
UseLib sound.def
UseLib Objects/vTextC.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;Here we define "MineProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of this class
;will be created, and will handle all application-related events (messages).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

MineProcessClass	class	GenProcessClass
	MSG_SHOW_HIGH_SCORES	message
	
MineProcessClass	endc	;end of class definition

;  the app class to save options

MineApplicationClass	class	GenApplicationClass

MineApplicationClass	endc

idata	segment
	MineApplicationClass
idata	ends


; 	Define MineFieldClass

MineFieldClass		class	VisClass

	MF_Width	byte	(?)
	MF_Height	byte	(?)
	MF_Mines	byte	(?)
	MF_MinesLeft	byte	(?)
	MF_GameState	byte 	(?)

	MSG_MINE_SET_LEVEL	message
	MSG_MINE_START_NEW_GAME	message
	MSG_MINE_INITIALIZE	message
	MSG_MINE_CLOCK		message

MineFieldClass		endc



;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment
	MineProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because ProcessClass
				;objects are hybrid objects.
	MineFieldClass


TotTilesLeft	word	381
TilesLeft	word	381
MineArraySize	word	480
GraphicsMode	byte	VGA_COLOR


idata	ends

udata 	segment

MineArray	hptr	0
Time		dword	0
temp1		word
counter		word
tmp_X		byte
tmp_Y		byte
b_temp1		byte
b_temp2		byte
TimerID 	hptr
TimerHandle	hptr

mineGameWonSoundHandle	hptr
mineHitSoundHandle	hptr
mineFlagSoundHandle	hptr

udata 	ends

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;
; Insik is a hoser - these should be enumerated types and records
;
MINE_EXPOSED 	= 020h
MINE_FLAGGED 	= 010h
MINE_ISAMINE 	= 00eh
MINE_MASK1   	= 008h
MINE_MASK2   	= 004h

NEW_GAME	= 001h
GAME_ON		= 002h
GAME_OVER	= 004h

OPT_SOUND	= 001h
SOUND_ON	= 001h

VGA_COLOR	= 001h
VGA_MONO	= 002h

MineSoundSetting			etype	byte
MS_SOUND_ON				enum	MineSoundSetting
MS_SOUND_OFF				enum	MineSoundSetting
MS_SOUND_USE_SYSTEM_DEFAULT		enum	MineSoundSetting

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		mine.rdef		;include compiled UI definitions
include		input.asm
include		output.asm

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

CallObjectNS	macro	objName, message, diMask
	GetResourceHandleNS objName, bx
	mov	si, offset objName
	mov	ax, message
	mov	di, mask diMask or mask MF_FIXUP_DS
	call	ObjMessage
endm

CommonCode	segment	resource	;start of code resource

; jfh - hack.  These need to be the same as in the ui file
mineCategoryString		char	"MineSweeper",0
mineLevelString		char	"Level",0

COMMENT @----------------------------------------------------------------------

FUNCTION:	StartMineAppl

DESCRIPTION:	Start of app... initializes game for expert mode.

PASS:		*ds:si	= instance data of the object

RETURN:		ds,si = same
 
CAN DESTROY:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	1/92		initial version

------------------------------------------------------------------------------@
StartMineAppl	method	MineProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION
	
	mov	di, offset MineProcessClass
	call	ObjCallSuperNoLock	; send to superclass first

	call	MineSoundInit

	;
	; get level from ini (if any)
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset mineCategoryString		;category
	mov	dx, offset mineLevelString		;key
	call	InitFileReadInteger			;look into the .ini file
	jc	noLevel
	mov_trash	cx, ax				;cx <- which setting
	jmp  gotLevel
  ;	mov	dx, 0					;not indeterminate
  ;	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
  ;	mov	bx, handle DifficultyList
  ;	mov	si, offset DifficultyList
  ;	clr	di
  ;	call	ObjMessage
noLevel:
	mov  cx, 0
gotLevel:
	push cx

	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	GetResourceHandleNS	MineApp,bx
	mov	si, offset MineApp
	mov	di, mask MF_CALL	; Determine Video Display mode
	call 	ObjMessage
	push	ax
	andnf	ah, mask DT_DISP_CLASS
	cmp	ah,DC_GRAY_1 shl offset DT_DISP_CLASS
	pop	ax
	jne	notMono
	mov	es:[GraphicsMode],VGA_MONO
notMono:

	; if on CGA then start at intermediate mode, and don't let the user
	; change to a higher level

 ;	mov	cx, 2			;Expert mode
	andnf	ah, mask DT_DISP_SIZE
	cmp	ah, DS_TINY shl offset DT_DISP_SIZE
	mov	ax, MSG_GEN_SET_USABLE
	jne	notSmall

	mov	ax, MSG_GEN_SET_NOT_USABLE
  ;	mov	cx, 1			;Intermediate mode
notSmall:
	mov	dl, VUM_NOW
	GetResourceHandleNS	Level2, bx
	mov	si, offset Level2
	clr	di
	call	ObjMessage

	GetResourceHandleNS	Level3, bx
	mov	si, offset Level3
	clr	di
	call	ObjMessage

  ; - now lets see if were in the CUI or 640x480 - if so dump the master level

	pop  cx
	call UserGetDefaultUILevel     ;returned in ax
	cmp  ax, UIIL_INTRODUCTORY
	je   CUIMode

	; check size of display
	call	UserGetDisplayType	; rtn ah = DisplayType, al = flag
	tst	al
	jz	CUIMode			; assume CUI/640 if not initialized
	and	ah, mask DT_DISP_SIZE
	cmp	ah, DS_LARGE shl offset DT_DISP_SIZE
	jne	CUIMode
	mov  ax, MSG_GEN_SET_USABLE
	jmp  doLevel
CUIMode:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	cmp  cx, 3
	jne  doLevel
	dec  cx
doLevel:
	GetResourceHandleNS	Level3, bx
	mov	si, offset Level3
	mov  dl, VUM_NOW
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	GetResourceHandleNS	DifficultyList, bx
	mov	si, offset DifficultyList
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cx, -1
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_APPLY
	clr	di
	GOTO	ObjMessage




StartMineAppl	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	EndMineAppl

DESCRIPTION:	Clean-up function

PASS:		*ds:si	= instance data of the object

RETURN:		ds,si = same
 
CAN DESTROY:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	2/4/92		initial version

------------------------------------------------------------------------------@

EndMineAppl	method	MineProcessClass, MSG_META_DETACH

	mov	di, offset MineProcessClass
	call	ObjCallSuperNoLock	; Send to Superclass

	clr	bx
	xchg	bx, es:[MineArray]
	tst	bx
	jz	noArray
	call	MemFree
noArray:
	clr	bx
	xchg	bx, es:[TimerHandle]
	tst	bx
	jz	exit
	mov	ax, es:[TimerID]
	call	TimerStop
exit:
	call	MineSoundStop
	ret	

EndMineAppl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MineSoundInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize minesweeper sounds

CALLED BY:	StartMineAppl
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MineSoundInit	proc	near
	uses	bx,cx,dx,si
	.enter
	segmov	es, dgroup, bx

	mov	cx, 1			;One voice
	GetResourceHandleNS	MineGameWonSoundBuffer, bx
	call	SoundInitMusic
	mov	es:[mineGameWonSoundHandle], bx

	;
	;  Set us up as the owner
	mov_tr	ax, bx
	call	GeodeGetProcessHandle
	xchg	ax, bx
	call	SoundChangeOwner

	mov	cx, 1
	GetResourceHandleNS	MineHitSoundBuffer, bx
	call	SoundInitMusic
	mov	es:[mineHitSoundHandle], bx

	mov_tr	ax, bx
	call	GeodeGetProcessHandle
	xchg	ax, bx
	call	SoundChangeOwner

	GetResourceHandleNS	MineFlagSoundBuffer, bx
	mov	cx, 1				; uses 1 voice
	call	SoundInitMusic
	mov	es:[mineFlagSoundHandle], bx	; save handle in udata

	mov_tr	ax, bx
	call	GeodeGetProcessHandle
	xchg	ax, bx
	call	SoundChangeOwner

	.leave
	ret
MineSoundInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MineSoundStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop all minesweeper sounds

CALLED BY:	EndMineAppl
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	DEH 	4/25/2000	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MineSoundStop	proc	near
	uses	ax,bx,es
	.enter
	segmov	es, dgroup, ax

	mov	bx, es:[mineGameWonSoundHandle]
	call	SoundStopMusic

	mov	bx, es:[mineHitSoundHandle]
	call	SoundStopMusic

	mov	bx, es:[mineFlagSoundHandle]
	call	SoundStopMusic

	.leave
	ret
MineSoundStop	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	InitMineField

DESCRIPTION:	Makes new Minefield for play 

PASS:		*ds:si	= instance data of the object

RETURN:		ds,si = same
 
CAN DESTROY:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	1/92		initial version

------------------------------------------------------------------------------@
InitMineField	method	MineFieldClass, MSG_MINE_INITIALIZE

	test	ds:[di].MF_GameState,GAME_ON	;is the game in progress?
	jz	1$	
	mov	bx,es:[TimerHandle]		;if so, stop the timer
	mov	ax,es:[TimerID]
	call	TimerStop
1$:	movdw	es:[Time], -1			;set clock to -1
	mov	ax,MSG_MINE_CLOCK		;display timer
	mov	si,offset TheMineField
	call	ObjCallInstanceNoLock		;reset clock to 0
	mov	ds:[di].MF_GameState,NEW_GAME	;set game status

	mov	al,ds:[di].MF_Mines
	mov	ds:[di].MF_MinesLeft,al		;mines left = max
	call	UpdateMineDisplay		;display mine:

	mov	ax,es:[MineArraySize]		;ax = array size
	mov	dx,ax				;dx = array size

; First we see if a minefield array was previously set up.  If so,
; we must re-allocate it

	mov	bx,es:[MineArray]
	tst	bx
	jz	10$

	; Here, we must re-allocate a previously set minefield

	mov	ch,mask HAF_LOCK
	call	MemReAlloc			;re-alloc
	push 	es	
	mov	es,ax				;es = mem block
	mov	cx,dx				;array size
	cld
	sub	al,al
	push	di	
	sub	di,di
	rep	stosb				;zero mem block
	mov	ax,es
	pop	di
	pop	es
	jmp	30$

	; We set up a new minefield, first allocating a new array

10$:	mov 	cx, (mask HF_SWAPABLE) or \
		    ((mask HAF_LOCK or mask HAF_ZERO_INIT) shl 8)
	call 	MemAlloc			;allocate and lock
	mov	es:[MineArray], bx

30$: 	push 	ds
	push	si				;save ds:si
	sub	ch,ch
	mov	cl,ds:[di].MF_Mines		
	mov 	ds,ax	
	mov	bx,dx				;bx = Max #
Randomize:					;Loop to allocate mines
20$:	mov 	dx,bx
	call	GameRandom
	mov	si,dx
	test	{byte} ds:[si],MINE_ISAMINE
	jnz	20$				;if already a mine, repick #
	mov	{byte} ds:[si],MINE_ISAMINE		;set it
	loop 	Randomize

	mov	bx,es:[MineArray]
	call 	MemUnlock			;unlock
	pop	si
	pop	ds

	ret
	
InitMineField	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	StartNewGame

DESCRIPTION:	Starts a New game (duh!)
			Calls Initialize method, then redraws the board

PASS:		*ds:si	= instance data of the object

RETURN:		ds,si = same
 
CAN DESTROY:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	1/92		initial version

------------------------------------------------------------------------------@

MineStartNewGame	method	MineFieldClass,	MSG_MINE_START_NEW_GAME

	mov	ax,es:[TotTilesLeft]		;reset # of tiles left
	mov	es:[TilesLeft],ax
	
	mov	ax,MSG_MINE_INITIALIZE		;initialize new minefield
	mov	si,offset TheMineField
	call	ObjCallInstanceNoLock


	mov	ax,MSG_VIS_VUP_CREATE_GSTATE	; get gstate of minefield
	call 	ObjCallInstanceNoLock
	push	bp
	
	mov	ax,MSG_VIS_DRAW			; draw new minefield
	call	ObjCallInstanceNoLock	
	pop	di
	call	GrDestroyState
	ret

MineStartNewGame	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MineSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass message on to objects that need to save their options.



CALLED BY:	MSG_META_SAVE_OPTIONS
PASS:		*ds:si	= Application object
			es 	= segment of MineApplicationClass

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jfh	4/14/00  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MineSaveOptions	method dynamic MineApplicationClass,
					MSG_META_SAVE_OPTIONS
	uses	ax, bx, cx, dx, di, bp
	.enter

	push	si				; save si
	
	;
	; Broadcast message to all objects that need their options saved.
	;
	CallObjectNS	DifficultyList, MSG_META_SAVE_OPTIONS, MF_FORCE_QUEUE
	CallObjectNS	SoundInteraction, MSG_META_SAVE_OPTIONS, MF_FORCE_QUEUE

	pop	si				; restore si
	
	;
	; Pass message to superclass.
	;
	mov	ax, MSG_META_SAVE_OPTIONS
	mov	di, offset MineApplicationClass
	call	ObjCallSuperNoLock

	.leave
	ret
MineSaveOptions	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MineCheckIfSoundOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will check if sound is on when called before sound producing
		events

CALLED BY:	sound events

PASS:		nothing

RETURN:		carry set if sound on
			carry clear if not

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jfh	5/16/00  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MineCheckIfSoundOn	proc	far
	uses	ax,bx,cx,dx,di,si
	.enter

   ;	call	GetGameSoundSetting		;bp <- GameSoundSetting
 	mov	bx, handle SoundList
	mov	si, offset SoundList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage
   ;	mov	bp, ax

	cmp	ax, MS_SOUND_OFF
	je	soundOff

	cmp	ax, MS_SOUND_ON
	je	soundOn

	;
	;	System default
	;
	mov	cx,cs
	mov	dx,offset soundString
	mov	ds,cx
	mov	si,offset uiCategory
	call	InitFileReadBoolean                
	jc	soundOn				;no string assume on
	tst	ax
	jz	soundOff				;off if false

soundOn:
	stc
	jmp  done

soundOff:
	clc

done:
	.leave
	ret

MineCheckIfSoundOn	endp

uiCategory	char	"ui",0
soundString	char	"sound",0

CommonCode	ends		;end of CommonCode resource

