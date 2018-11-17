COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PROJECT:	Practice Project
MODULE:		Uki program
FILE:		ukiCommon.asm

Author		Jimmy Lefkowitz, January 14, 1991

	$Id: ukiCommon.asm,v 1.1 97/04/04 15:47:12 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include ukiCommon.def

include uki.def
include	uki.asm

CommonCode 	segment resource

include ukiKbd.asm
include ukiMouse.asm

; jfh - these need to be the same as in the ui file
ukiCategoryString		char	"Uki",0
ukiLevelString		char	"boardSize",0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** UkiProcess code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= UkiProcessClass instance data.
		ds:di	= *ds:si.
		es	= Segment of UkiProcessClass.
		ax	= Method.
		bp 	= handle to the state file

RETURN:		???

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDOCODE/STRATEGY:	???

KNOWN BUGS/SIDEFFECTS/CAVEATS/IDEAS:	???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BMT	2/ 3/92		Initial version.
	jfh  5/8/00	Added board size check base on scrn rez

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiOpenApplication	method	dynamic	UkiProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
	uses	ax,cx,dx,bp
	.enter

	push	bp
	mov	di, offset UkiProcessClass
	call	ObjCallSuperNoLock
	pop	bp

	; if uki already open then loadin saved values from state file
	call	UkiLoadSavedState

	; if mono use different color scheme
	call	UkiAdjustDisplayScheme	

	; get level from ini (if any)
	mov	cx, cs
	mov	ds, cx
	mov	si, offset ukiCategoryString		;category
	mov	dx, offset ukiLevelString		;key
	call	InitFileReadInteger			;look into the .ini file
	jc	noLevel
	mov_trash	cx, ax				;cx <- which setting
	jmp  gotLevel
noLevel:
	mov  cx, 8					; default to 8x8
gotLevel:
	push cx						; save the level

	; check size of display
	call	UserGetDisplayType	; rtn ah = DisplayType, al = flag
	tst	al
	jz	Res640			; assume 640x480 if not initialized
	and	ah, mask DT_DISP_SIZE
	cmp	ah, DS_LARGE shl offset DT_DISP_SIZE
	jne	Res640
	mov  ax, MSG_GEN_SET_USABLE
	jmp  doLevel
Res640:
	mov	ax, MSG_GEN_SET_NOT_USABLE

	;if the ini level is > 12 then set start level back to 12
	cmp  cx, 14
	jl   doLevel
	mov  cx, 12
doLevel:
	GetResourceHandleNS	BoardSize14, bx
	mov	si, offset BoardSize14
	mov  dl, VUM_NOW
	clr	di
	call	ObjMessage
	GetResourceHandleNS	BoardSize16, bx
	mov	si, offset BoardSize16
	mov  dl, VUM_NOW
	clr	di
	call	ObjMessage
	GetResourceHandleNS	BoardSize18, bx
	mov	si, offset BoardSize18
	mov  dl, VUM_NOW
	clr	di
	call	ObjMessage

	;and set the level
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	GetResourceHandleNS	UkiBoardSizeList, bx
	mov	si, offset UkiBoardSizeList
	clr	di
	call	ObjMessage

	pop  cx

	.leave
	ret
UkiOpenApplication	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiLoadSavedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	????

PASS:		bp = handle to the state file

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 3/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiLoadSavedState	proc	near
	uses	ax, bx, cx, dx, ds, di, si
	.enter

	push	es
	;if no saved state to the normal thing
	tst	bp
	jz	initSound
	
	push	es				; save the segment
	mov	bx, bp
	call	MemLock				; lock the saved block
	push	bx
	mov	ds, ax
	mov	cx, (StateVariableEnd - StateVariableStart)
	clr	si
	mov	di, offset StateVariableStart
	rep	movsb				; copy it into my idata

	; ds:si = beginning of game board data

	tst	es:[cells]
	jz	cont
	call	UkiRestoreGameBoard
	call	UkiSetPtrImage
cont:
	pop	bx
	call	MemUnlock
	pop	es				; restore es
	clr	ax				; only do functions
	call	UkiChooseUki
	jmp	done
initSound:
	call	UkiSetSoundFromPreferences
done:
	call	TimerGetDateAndTime
	pop	es
	mov	es:[randomSeed], dx

	.leave
	ret
UkiLoadSavedState	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiRestoreGameBoard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	loadd the saved game data into the game board

CALLED BY:	????

PASS:		ds:si = saved game data

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 3/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiRestoreGameBoard	proc	near
	uses	es
	.enter

	; calculate number of cells in board
	call	UkiAllocBoard
	mov	bx, es:[gameBoard]
	mov	cx, es:[maxcells]
	call	MemLock
	mov	es, ax
	clr	di
	rep	movsb
	call	MemUnlock
	.leave
	ret
UkiRestoreGameBoard	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiAdjustDisplayScheme
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	change color scheme for mono

CALLED BY:	OpenApplication

PASS:		????

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiAdjustDisplayScheme	proc	near
	uses	ax, bx, cx, dx, di, si
	.enter

	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	call	GenCallApplication
	andnf	ah, mask DT_DISP_CLASS
	cmp	ah, DC_GRAY_1 shl offset DT_DISP_CLASS
	je	blackAndWhite
	mov	es:[borderColor], C_WHITE
	mov	es:[viewColor], C_LIGHT_GREY
	mov	es:[backGroundColor1], C_LIGHT_GREY
	mov	es:[backGroundColor2], C_DARK_GREY
	mov	es:[player1].SP_pieceColor, PLAYER1_COLOR
	mov	es:[player2].SP_pieceColor, PLAYER2_COLOR
	mov	es:[boardColor], C_LIGHT_GREY
	jmp	done
blackAndWhite:
	mov	es:[boardColor], C_BW_GREY
	mov	es:[obstacleLighterColor], C_R4_G4_B4 
	mov	es:[obstacleDarkerColor], C_R4_G4_B4 
	mov	es:[obstacleColor], C_R4_G4_B4 
	mov	es:[player2].SP_pieceColor, C_BLACK
	mov	es:[player1].SP_pieceColor, C_WHITE
	mov	es:[borderColor], C_BLACK
	mov	es:[backGroundColor1], C_BLACK
	mov	es:[backGroundColor2], C_BLACK
	mov	es:[viewColor], C_R2_G2_B4
done:
	.leave
	ret
UkiAdjustDisplayScheme	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	save away state info

PASS:		*ds:si	= UkiProcessClass instance data.
		ds:di	= *ds:si.
		es	= Segment of UkiProcessClass.
		ax	= Method.

RETURN:		???

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDOCODE/STRATEGY:	???

KNOWN BUGS/SIDEFFECTS/CAVEATS/IDEAS:	???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BMT	2/ 3/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCloseApplication	method	dynamic	UkiProcessClass,
					MSG_GEN_PROCESS_CLOSE_APPLICATION
	uses	ax,dx,bp
	.enter

	push	es
	mov	al, es:[cells]
	mul	al
	add	ax, (StateVariableEnd  -  StateVariableStart)
	mov	cx, ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE or (mask HAF_LOCK shl 8)
	call	MemAlloc
	mov	es, ax
	mov	cx, (StateVariableEnd - StateVariableStart)
	clr	di
	mov	si, offset StateVariableStart
	rep	movsb

	mov	cx, bx
	mov	bx, es
	pop	es
	call	UkiSaveGameBoard

	tst	es:[gameBoard]
	jz	cont
	mov	bx, es:[gameBoard]
	call	MemFree
	mov	es:[gameBoard], 0	; mark it as NULL
	mov	es:[firstWin], 0	; reset firstWin so
					; if we reopen it will restart things
	mov	bx, cx
	call	MemUnlock
cont:
	.leave
	ret
UkiCloseApplication	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiSaveGameBoard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save away the game board

CALLED BY:	????

PASS:		bx:di	= where to save board to
		es 	= DGROUP

RETURN:		Void.

DESTROYED:	di, si

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 3/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiSaveGameBoard	proc	near
	uses	es, ds, cx
	.enter
	
	push	bx, di
	mov	bx, es:[gameBoard]
	call	MemLock
	mov	ds, ax
	clr	si
	mov	cx, es:[maxcells]
	pop	es, di
	rep	movsb
	call	MemUnlock	

	.leave
	ret
UkiSaveGameBoard	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
FUNCTION:      	UkiDetach

DESCRIPTION:   must stop the computer from continuing play on a detach


PASS:          

RETURN:		???

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDetach	method	UkiProcessClass, MSG_META_DETACH
	clr	es:[gameOver]		; stop current game
;	clr	es:[computerTwoPlayer]	; stop computers from starting again

	mov	di, offset UkiProcessClass
	call	ObjCallSuperNoLock	; pass on detach
	ret
UkiDetach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** UkiPrimary code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:

PASS:		*ds:si	= UkiPrimaryClass instance data.
		ds:di	= *ds:si.
		es	= Segment of UkiPrimaryClass.
		ax	= Method.

RETURN:		???

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDOCODE/STRATEGY:	this routine resets the playing mode to two
			player if the computer is playing itself when 
			the app gets iconified

KNOWN BUGS/SIDEFFECTS/CAVEATS/IDEAS:	???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BMT	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiVisClose	method	dynamic	UkiPrimaryClass, MSG_VIS_CLOSE
	uses	ax,cx,dx,bp

	.enter
	mov	di, offset UkiPrimaryClass
	call	ObjCallSuperNoLock	; pass on detach

	tst	es:[computerTwoPlayer]
	jz	done
	
	mov	al, es:[computerTwoPlayer]
	mov	es:[gameOver], al
done:
	.leave
	ret
UkiVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** UkiContent code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiViewWinOpened
			
SYNOPSIS:	saves the window handle for later use

CALLED BY:	Global

PASS:		ES	= DGroup
		bp	= window handle

RETUNR		nothing


Known BUGS/SIDE EFFECTS/IDEAS
		

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UkiViewWinOpened	method	dynamic	UkiContentClass, 
					MSG_META_CONTENT_VIEW_WIN_OPENED
	push	si, di

	mov	es:[viewWindow], bp
	mov	di, offset UkiContentClass
	call	ObjCallSuperNoLock

	; when we get a window subview created then I must check to
	; see if  the computer was playing itself when we closed it down,
	; if so then start it up again when the window is opened


	; if it was two players then get it going again else
	; just put the list back to what it should be
	tst	es:[firstWin]
	jnz	checkTwoPlayers

	; firstWin is zero until the first time we open up the window
	; this happens when we open the app, this inits the first game
	mov	es:[firstWin], 1

	mov	si, offset UkiBoardSizeList
	mov	cx, 8				; default uki size
	call	UkiInitItemGroup
	call	UkiSetBoardSizeCommon

	pop	si, di
	mov	ax, 0				; do partial init
	call	UkiChooseUki

	mov	cx, UPM_PLAY_WHITE
	mov	si, offset UkiPlayingModeList
	call	UkiInitItemGroup
	call	UkiSetPlayMode		

	call	UkiCommonInitGame

	mov	si, offset UkiObstaclesList
	GetResourceHandleNS	Interface, bx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL
	push	si
	call	ObjMessage		; ax <- current selection
	pop	si
	mov_tr	cx, ax
	call	UkiSetObstaclesCommon

;	call	UkiPlayerOne
	jmp	done
checkTwoPlayers:
	; as long as the game isn't over contiune playing, so to speak
	pop	si, di
	mov	al, es:[gameOver]
	cmp	al, UPM_COMPUTER
	je	doTwoPlayer
	cmp	al, UPM_COMPUTER_CONTINUOUS
	jne	done
doTwoPlayer:
	mov	es:[computerTwoPlayer], al
	mov	ax, MSG_UKI_START
	call	ObjCallInstanceNoLock	
done:
	ret
UkiViewWinOpened	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiInitItemGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	init an item group...

CALLED BY:	GLOBAL

PASS:		si = offset of ItemGroup object
		cx = value to set if current value is GIGS_NONE

RETURN:		cx = value set

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/18/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiInitItemGroup	proc	far
	.enter
	push	cx		; save default value
	GetResourceHandleNS	Interface, bx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	push	si
	call	ObjMessage		; ax <- current selection
	pop	si
	mov_tr	cx, ax			; cx <- current selection
	pop	ax			; ax <- default value
	cmp	cx, GIGS_NONE
	jne	done
	mov_tr	cx, ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	GetResourceHandleNS	Interface, bx
	clr	dx				; determinate
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	push	cx
	call	ObjMessage
	pop	cx
done:
	.leave
	ret
UkiInitItemGroup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiSetBoardSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Sets the number of rows & columns in the board

PASS:		*ds:si	= UkiContentClass instance data.
		ds:di	= *ds:si.
		es	= Segment of UkiContentClass.
		ax	= Method.
		cl	= number of cells to a side (ie 7x7 board, cl = 7)

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDOCODE/STRATEGY:	sets the  global variables that contain the
			new board size and calculate the number of cells

KNOWN BUGS/SIDEFFECTS/CAVEATS/IDEAS:	???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BMT	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiSetBoardSize	method	UkiContentClass, MSG_UKI_SET_BOARD_SIZE

	; Store cells, & calculate the number of obstacles if necessary
	;
	; Resize board & start a new game
	call	UkiSetBoardSizeCommon

	; now turn off the game, this gets cleared in GameInit
	; so any pending moves from the last game get ignored
	mov	es:[gameOver], 1
	mov	ax, MSG_UKI_START
	mov	bx, ds:[LMBH_handle]	; OD => BX:SI
	mov	di, mask MF_CHECK_DUPLICATE or mask MF_FORCE_QUEUE 
	GOTO	ObjMessage

UkiSetBoardSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiSetBoardSizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	a common routine for setting up the board size

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	allocate an appropriate sized board

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/18/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiSetBoardSizeCommon	proc	near
	.enter
	mov	es:[cells], cl
	tst	es:[maxObstacles]
	jz	done
	mov	al, cl
	mul	al
	mov	cl, 2
	shr	ax
	mov	es:[maxObstacles], ax
done:
	call	UkiAllocBoard
	.leave
	ret
UkiSetBoardSizeCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiSetObstacles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set whether or not obstacles are dispayed

CALLED BY:	GLOBAL (MSG_UKI_SET_OBSTACLES)

PASS:		ES	= DGroup
		CX	= 0 (no obstacles) or 1 (obstacles)

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiSetObstacles	method UkiContentClass, MSG_UKI_SET_OBSTACLES

	; Calculate the number of obstacles
	;
	call	UkiSetObstaclesCommon
	; Resize board & start a new game
	mov	ax, MSG_UKI_START
	mov	bx, ds:[LMBH_handle]	; OD => BX:SI
	mov	di, mask MF_CHECK_DUPLICATE or mask MF_FORCE_QUEUE 
	GOTO	ObjMessage
UkiSetObstacles	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiSetObstaclesCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common routine for setting up obstacles

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/18/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiSetObstaclesCommon	proc	near
	.enter
	mov	es:[maxObstacles], cx
	jcxz	done
	mov	cl, 2
	mov	ax, es:[maxcells]
	shr	ax, cl
	mov	es:[maxObstacles], ax
done:
	.leave
	ret
UkiSetObstaclesCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiExposed

DESCRIPTION:   exposed handler, redraws games


PASS:          nothing

RETURN:        nothing

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiExposed	method	UkiContentClass, MSG_META_EXPOSED
	
	mov	di, es:[viewWindow]
	; there are cases when we get a CLOSE_APPLICATION followed by an 
	; EXPOSED and then an OPEN_APPLICATION so our gameBoard has been
	; freed and we don't really have anything to display 
	tst	es:[gameBoard]
	jz	done
	call	GrCreateState
	call	GrBeginUpdate
	call	UkiRescale
	call	UkiDrawGame
	call	GrEndUpdate
	call	GrDestroyState
done:
	ret
UkiExposed	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiStartGame

DESCRIPTION:   start a new game


PASS:          nothing

RETURN:        nothing

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiStartGame	method UkiContentClass, MSG_UKI_START
	.enter

        ; Get a graphics state to use.
	;
	mov	di, es:[viewWindow]
        call    GrCreateState
	push	di
	call	UkiCommonInitGame
	call	UkiRescale
	call	UkiDrawGame
	pop	di
        call    GrDestroyState

	cmp	es:[playMode], UPM_COMPUTER
	jne	checkComputerTurn
	; ok computer should play itself, so set things up
	mov	es:[computerPlayer], offset player1
	mov	es:[computerTwoPlayer], UPM_COMPUTER
checkComputerTurn:
	; if the computer goes first then start it off right away
	cmp	es:[computerPlayer], offset player1
	jnz	done

	call	UkiCallComputerMove
done:
	; make sure the game button releases the focus back to the view
	GetResourceHandleNS Interface, bx
	mov	si, offset NewGameButton
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	mov	di, 0
	call	ObjMessage
	.leave
	ret
UkiStartGame	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiRescale

DESCRIPTION:	rescale the board given a graphics handle

PASS:
		es - idata
		di - gstate handle

RETURN:
		ax - xStartCoord
		bx - yStartCoord
		cx - xEndCoord
		dx - xEndCoord

DESTROYED:      bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version
	rsf	6/27/91		rewrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiRescale	proc	near

	tst	es:[cells]
	jz	done

	call	GrGetWinBounds		; get screen size
	jc	done			; the window is closing!
	push	ax, bx, cx

	; now get smaller of width and height and use it to decide
	; how big to make the cells
	sub	dx, bx
	sub	cx, ax
	cmp	cx, dx
	jbe	smallerInUse
	mov	cx, dx
smallerInUse:
	
	; dx is now the size in pixels

	; now make sure we didn't get toooo small, if so bring up
	; the size to the minimun acceptable size
	mov	al, es:[cells]		;get the board's dimension in cells
	add	al, 2			;leave room for a border on each side
	mov	bl, UKI_MIN_CELL_SIZE;get the minimum cell size
	mul	bl
	cmp	ax, cx
	jae	enoughScreenSpace
	mov	ax, cx			;large enough, use it
enoughScreenSpace:

	; calculate the size of the cell

	; the size of a cell is the smallest dimension divided by
	; the number of cells and room for both borders.  Each
	; border is as wide a cell so add two to the number of cells.
	mov	bl, es:[cells]
	add	bl, 2
	div	bl
	clr	ah
	mov	es:[cellSize], ax
	mov	es:[borderWidth],ax

	; when drawing stuff on the board we would like to know how 
	; deep to make an object.  Store this.
	mov	bp, ax			;store cell size
	mov	cl, 4
	shr	al, cl
	inc	al
	mov	es:[cellDepth], al


	mov	ax, bp			;restore cell size
	sub	bl, 2			;don't include borders - just board
	mul	bl			;width of board
	mov	bp, ax			;bp = width of board in pixels

	pop	ax, bx, cx		;retrieve screen coordinates

	; now do the actual calculations 
;	es:[xStartCoord] = (xsize - es:[cellSize]*CELLS)/2
;	es:[yStartCoord] = (ysize - es:[cellSize]*CELLS)/2
;	es:[xEndCoord] = es:[xStartCoord] + es:[cellSize]*CELLS
;	es:[yEndCoord] = es:[yStartCoord] + es:[cellSize]*CELLS
;	this is the code :) (i LOVE assembly!)

	;calculate the x and y start coordinates of the board
	;the board is to be centered within the window
	;REMEMBER: StartCoord is at the top left cell, not at the border!
	sub	cx, ax
	sub	dx, bx
	sub	cx, bp
	sub	dx, bp
	shr	cx, 1
	shr	dx, 1
	mov	es:[xStartCoord], cx
	mov	es:[yStartCoord], dx
	add	cx, bp
	add	dx, bp
	mov	es:[xEndCoord], cx
	mov	es:[yEndCoord], dx
	
done:
	ret
UkiRescale	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiDrawGame

DESCRIPTION:   draws the board and pieces


PASS:          nothing	

RETURN:       nothing

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawGame	proc	near
	call	UkiClearView
	call	UkiDrawGrid
	call	UkiDrawPlayers
	call	UkiDrawActivePiece
	call	UkiDrawHint
	call	UkiDrawKbdPosition
	ret
UkiDrawGame	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiGetNode

DESCRIPTION:   gets data for the board position al, bl


PASS:          al, bl : board position

RETURN:        cl, board data for that position

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
	the data for the game board is stored in a cells x cells array
	so to get and element (x, y) we must get the data from
	x * cells + y nodes into the game board

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiGetNode	proc	far 
	uses ax, bx, es
	.enter

	clr	bh
	mov	ah, bh
if 0
	mov	cl, BAD_COORD
	tst	al
	jl	done
	tst	bl
	jl	done
	cmp	al, es:[cells]
	jge	done
	cmp	bl, es:[cells]

	jge	done
endif
	; if it is a legal x,y position get the data
	push	bx
	mov	bl, es:[cells]
	mul	bl				; bx <- cells * x
	pop	bx
	add	bx, ax				; bx <- cells * x + y		
	push	bx
	mov	bx, es:[gameBoard]
	call	MemLock
	mov	es, ax
	xchg	ax, bx
	pop	bx
	mov	cl, es:[bx]		; cl <- data
	xchg	ax, bx
	call	MemUnlock
;done:
	.leave
	ret
UkiGetNode	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiGetNodeNL

DESCRIPTION:   gets data for the board position al, bl


PASS:          al, bl : board position
	       ds : gameBoard segment
	       es : dgroup

RETURN:        cl, board data for that position

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
	the data for the game board is stored in a cells x cells array
	so to get and element (x, y) we must get the data from
	x * cells + y nodes into the game board

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiGetNodeNL	proc	far 
	uses ax, bx
	.enter
	clr	bh
	mov	ah, bh

	; if it is a legal x,y position get the data
	mov	cl, es:[cells]
	mul	cl				; ax <- cells * x
	add	bx, ax				; bx <- cells * x + y	
	mov	cl, ds:[bx]		; cl <- data
;done:
	.leave
	ret
UkiGetNodeNL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiSetNode

DESCRIPTION:   sets node for game board position al, bl


PASS:          al, bl : gameboard position
		cl = what to set node to

RETURN:        nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
	the data for the game board is stored in a cells x cells array
	so to get and element (x, y) we must get the data from
	x * cells + y nodes into the game board

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
    

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiSetNode	proc	far 
	uses ax, bx, es
	.enter
EC <	cmp	al, es:[cells] 				>
EC <	ERROR_GE	BAD_COORDINATE			>
EC <	cmp	bl, es:[cells] 				>
EC <	ERROR_GE	BAD_COORDINATE			>
EC <	tst	al					>
EC <	ERROR_L		BAD_COORDINATE			>
EC <	tst	bl					>
EC <	ERROR_L		BAD_COORDINATE			>
	clr	ah
	mov	bh, ah
	push	bx
	mov	bl, es:[cells]
	mul	bl
	pop	bx
	add	bx, ax
	push	bx
	mov	bx, es:[gameBoard]
	call	MemLock
	mov	es, ax
	xchg	ax, bx
	pop	bx
	mov	es:[bx], cl
	xchg	ax, bx
	call	MemUnlock
	.leave
	ret
UkiSetNode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiDrawPlayer

DESCRIPTION:    draws a single piece at position al,bl


PASS:           al, bl : position  to draw  (cell position)
		cl	color index
		di: GSTATE

RETURN:		nothing

DESTROYED:      dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawPlayer	proc	far
	uses	ax, bx, cx
	.enter

	cmp	al, BAD_COORD
	jz	done
	; save the color
	mov	ch, CF_INDEX
	mov	bp, cx

	call	UkiDrawGetCellCoords

	; don't overwrite the raised and lowered edges
	inc	ax
	inc	bx
	dec	cx
	dec	cx
	dec	dx
	dec	dx

	; set the background color
	push	ax
	mov	al, es:[backGroundColor2]
	mov	ah, CF_INDEX
	call	GrSetAreaColor
	pop	ax
;	call	GrFillEllipse
	call	UkiDrawPlayerShape
	; set the piece in the passed color
	xchg	ax, bp				;switch x pos with color
	call	GrSetAreaColor
	mov	al, es:[cellDepth]
	clr	ah
	sub	cx, ax 
	sub	dx, ax
	xchg	ax, bp				;restore the x pos
	inc	ax
	inc	bx
;	call	GrFillEllipse
	call	UkiDrawPlayerShape
done:
	.leave
	ret
UkiDrawPlayer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiDrawPlayerShape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw a piece

CALLED BY:	UkiDrawPlayer

PASS:		ax,bx: upper left corner
		cx, dx: lower right corner

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/30/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawPlayerShape	proc	near
points	local	9	dup(dword)

	uses	ax, bx, cx, dx, si, ds
	.enter
	push	cx
	sub	cx, ax
	shr	cx
	shr	cx
	mov	si, cx		; bp = offset from real corners
	pop	cx
	add	ax, si
	mov	ss:[points].high, bx
	mov	ss:[points].low, ax
	sub	cx, si
	mov	ss:[points][4].high, bx
	mov	ss:[points][4].low, cx
	add	bx, si
	add	cx, si
	mov	ss:[points][8].high, bx
	mov	ss:[points][8].low, cx
	sub	dx, si
	mov	ss:[points][12].high, dx
	mov	ss:[points][12].low, cx
	add	dx, si
	sub	cx, si
	mov	ss:[points][16].high, dx
	mov	ss:[points][16].low, cx

	mov	ss:[points][20].high, dx
	mov	ss:[points][20].low, ax
	sub	dx, si
	sub	ax, si
	mov	ss:[points][24].high, dx
	mov	ss:[points][24].low, ax

	mov	ss:[points][28].high, bx
	mov	ss:[points][28].low, ax
	sub	bx, si
	add	ax, si
	mov	ss:[points][32].high, bx
	mov	ss:[points][32].low, ax
	mov	cx, 9

	clr	al
	segmov 	ds, ss
	lea	si, points
	call	GrFillPolygon
	.leave
	ret
UkiDrawPlayerShape	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiDrawActivePiece
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	????

PASS:		????

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/19/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawActivePiece	proc	near
	uses	bp, ax, bx, cx, dx, si, di
	.enter
	mov	bp, es:[whoseTurn]
	mov	cl, es:[bp].SP_activeColor
	mov	al, es:[activePiece].x_pos
	mov	bl, es:[activePiece].y_pos
	call	UkiDrawPlayer
	.leave
	ret
UkiDrawActivePiece	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiDrawCurrentPlayer

DESCRIPTION:   


PASS:          al, bl = cell position
		di = GSTATE
RETURN:        

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawCurrentPlayer	proc	far
	uses	ax, bx
	.enter
	mov	si, es:[whoseTurn]
	mov	cl, es:[si].SP_pieceColor
	call	UkiDrawPlayer
	.leave
	ret
UkiDrawCurrentPlayer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiDrawObstacle

DESCRIPTION:   draw an obstacle


PASS:          al, bl = cell position
		cl	cell info
		di - GSTATE
RETURN:        

DESTROYED:      dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawObstacle	proc	near
	uses	ax, bx, cx
	.enter
	; DRAW THE SHADOWING EFFECT
	; first draw a dark grey box
	push	ax
	mov	ah, CF_INDEX
;	mov	al, OBSTACLE_LIGHTER_COLOR
	mov	al, es:[obstacleLighterColor]
	call	GrSetAreaColor
	pop	ax

	call	UkiDrawGetCellCoords
	call	GrFillRect

	; CHANGE THE COLOR BACK
	; now draw a lighter color box to get lighting effect
	push	ax
	mov	ah, CF_INDEX
	mov	al, es:[obstacleDarkerColor]
;	mov	al, OBSTACLE_DARKER_COLOR
	call	GrSetAreaColor
	pop	ax

	; DRAW THE OBSTACLE
	; now draw the obstacle itself onto of the lighting effects
	mov	bp, ax
	mov	al, es:[cellDepth]
	clr	ah
	xchg	ax, bp
	add	ax, bp
	add	bx, bp
	call	GrFillRect
	push	ax
;	mov	al, OBSTACLE_COLOR
	mov	al, es:[obstacleColor]
	mov	ah, CF_INDEX
	call	GrSetAreaColor
	pop	ax
	sub	cx, bp
	sub	dx, bp
	call	GrFillRect
	
	.leave
	ret
UkiDrawObstacle	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiDrawGetCellCoords

DESCRIPTION:   


PASS:          al, bl = cell position

RETURN:        ax, bx, cx, dx = rect of cell

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	to go from an x,y position to pixel values we do

	xStartCoord + cellSize * x, ystartCoord + cellSize * y
	xStartCoord + cellSize * (x+1), ytartCoord + cellSize * (y+1)     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawGetCellCoords	proc	far
	clr	ah
	mov	bh, ah
	push	ax
	mov	al, bl
	mov	dx, es:[cellSize]
	mul	dl
	add	ax, es:[yStartCoord]
	mov	bx, ax

	pop	ax
	mul	dl
	add	ax, es:[xStartCoord]

	mov	cx, es:[cellSize]
	mov	dx, cx
	add	cx, ax
	add	dx, bx
	ret
UkiDrawGetCellCoords	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiDrawPlayers

DESCRIPTION:   draws the pieces from data in the GameBoard


PASS:          di: GState

RETURN:        nothing

DESTROYED:      ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawPlayers	proc	far

	clr	ax
	mov	bx, ax

drawloop:
	call	UkiGetNode

	; for each cell, if it is zero, draw nothing
	tst	cl

	; else if its player1 draw a piece in player1's color
	jz	contLoop
	test	cl, mask GDN_OBSTACLE
	jnz	drawObstacle

	test	cl, mask GDN_PLAYER1
	jz	usePlayer2Color
	mov	cl, es:[player1].SP_pieceColor; PLAYER1_COLOR
	jmp	drawPiece
usePlayer2Color:
	mov	cl, es:[player2].SP_pieceColor; PLAYER2_COLOR
drawPiece:
	call	UkiDrawPlayer
	jmp	contLoop

drawObstacle:
	call	UkiDrawObstacle
contLoop:
	; do inner loop
	inc	al
	cmp	al, es:[cells]
	jl	drawloop

;do_next_outer:
	; do outer loop
	clr	al
	inc	bl
	cmp	bl, es:[cells]
	jl	drawloop
	ret
UkiDrawPlayers	endp
if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiDrawPlayersCommon

DESCRIPTION:   


PASS:
		al, bl = cell position to draw to
		di = GSTATE
		ch = what to draw (ie which player or an obstacle)
		cl	draw color index

RETURN:        

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawPlayersCommon	proc	near
	uses	ax, bx, dx
	.enter

	; see if player matches current piece, if so draw it
	and	dl, ch
	tst	dl
	jz	done
	cmp	ch, mask GDN_OBSTACLE
	jz	doObstacle

	; if its an obstacle draw an obstacle, else draw a player
	call	UkiDrawPlayer
	jmp	done
doObstacle:
	push	ax
	mov	al, cl
	mov	ah, CF_INDEX
	call	GrSetAreaColor
	pop	ax
	call	UkiDrawObstacle
done:
	.leave
	ret
UkiDrawPlayersCommon	endp
endif
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiDrawGrid

DESCRIPTION:   draws the game grid


PASS:          di: Gstate

RETURN:        nothing

DESTROYED:      ax, bx, dx, cx, si, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version
	rsf	7/27/91		added 3D effect

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawGrid	proc	near

	tst	es:[cells]
	LONG	jz	done
	call	UkiDrawGridBorder

	; the x,y EndCoord is actually one beyond the last cell's raised edge
	; inc at the end of this procedure
	dec	es:[xEndCoord]
	dec	es:[yEndCoord]

	; The number of lines to draw is equal to the number of cells
	mov	al, es:[cells]
	clr	ah
	mov	bp, ax			;store this value away for quick access

	; draw a LT_GRAY rectangle without a border to remove any
	; prior display
	clrwwf	dxax
	call	GrSetLineWidth
	mov	ah, CF_INDEX
	mov	al, es:[boardColor]; BACKGROUND_COLOR
	call	GrSetAreaColor
	
	; get the coordinates of the game board
	mov	ax, es:[xStartCoord]
	mov	bx, es:[yStartCoord]
	mov	cx, es:[xEndCoord]
	mov	dx, es:[yEndCoord]
	call	GrFillRect

	; the board will be drawn with a line width of one
	mov	dx, 1
	clr	ax
	call	GrSetLineWidth

;horiz_loop:
	; draw the top part of each grid box

	mov	ah, CF_INDEX
	mov	al, C_DARK_GRAY
	call	GrSetLineColor

	mov	ax, es:[xStartCoord]	;was trashed by above
	mov	dx, es:[yStartCoord]
	clr	si			;si is counter for loop, start at 0

gridBoxTop:
	call	GrDrawLine	
	add	bx, es:[cellSize]
	mov	dx, bx
	inc	si
	cmp	si, bp			; si == num lines?
	jl	gridBoxTop

	; draw the left part of each grid box
	; the line color is DK_GRAY

	mov	ax, es:[xStartCoord]
	mov	bx, es:[yStartCoord]
	mov	cx, es:[xStartCoord]
	mov	dx, es:[yEndCoord]
	clr	si

gridBoxLeft:
	; draw the vertical lines
	call	GrDrawLine	
	add	ax, es:[cellSize]
	mov	cx, ax
	inc	si
	cmp	si, bp			; si == num lines?
	jl	gridBoxLeft

	; draw the bottom part of each grid box

	mov	ah, CF_INDEX
	mov	al, C_WHITE
	call	GrSetLineColor

	; get the coordinates of the upper right and lower left corners
	mov	ax, es:[xStartCoord]
	mov	bx, es:[yStartCoord]
	add	bx, es:[cellSize]
	dec	bx
	mov	cx, es:[xEndCoord]
	mov	dx, bx

	clr	si			;si is counter for loop, start at 0

gridBoxBottom:

	; draw the horizontal lines
	call	GrDrawLine	
	add	bx, es:[cellSize]
	mov	dx, bx
	inc	si
	cmp	si, bp			; si == num lines?
	jl	gridBoxBottom

	; draw the right part of each grid box
	; the line color is white

	mov	ax, es:[xStartCoord]
	add	ax, es:[cellSize]
	dec	ax
	mov	bx, es:[yStartCoord]
	mov	cx, ax
	mov	dx, es:[yEndCoord]

	clr	si			;si is counter for loop, start at 0

gridBoxRight:

	; draw the vertical lines
	call	GrDrawLine	
	add	ax, es:[cellSize]
	mov	cx, ax
	inc	si
	cmp	si, bp			; si == num lines?
	jl	gridBoxRight

	inc	es:[xEndCoord]
	inc	es:[yEndCoord]
done:
	ret

UkiDrawGrid	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiDrawGridBorder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a border around the playing board to give it
		a framed look

CALLED BY:	UkiDrawGrid

PASS:		es - idata
		di - gstate

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BMT	6/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawGridBorder	proc	near	uses	ax,bx,cx,dx,si,bp
	.enter

	mov	bp, es:[cellSize]	;store this for quick reference
	shr	bp, 1

	;set the line's width to 1
	mov	dx, 1
	clr	ax
	call	GrSetLineWidth

	;draw the raised edges (top and left) in white
	mov	ah, CF_INDEX
	mov	al, es:[borderColor]
	call	GrSetLineColor

	;top left coordinate
	mov	ax, es:[xStartCoord]
	sub	ax, bp
	mov	bx, es:[yStartCoord]
	sub	bx, bp

	;top right coordinate
	mov	cx, es:[xEndCoord]
	add	cx, bp
	mov	dx, bx
	call	GrDrawLine

	;bottom left coordinate
	mov	cx, ax
	mov	dx, es:[yEndCoord]
	add	dx, bp
	call	GrDrawLine
	


	;draw the lowered edges (top and left) in dark grey
	mov	ah, CF_INDEX
	mov	al, es:[backGroundColor2]
	call	GrSetLineColor

	;bottom right coordinate
	mov	cx, es:[xEndCoord]
	add	cx, bp
					;dx is set from the last line

	;top right coordinate
	mov	ax, cx
	mov	bx, es:[yStartCoord]
	sub	bx, bp
	call	GrDrawLine

	;bottom left coordinate
	mov	ax, es:[xStartCoord]
	sub	ax, bp
	mov	bx, dx
	call	GrDrawLine
	
	.leave
	ret
UkiDrawGridBorder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCommonInitGame

DESCRIPTION:   generic initialization stuff

PASS:          nothing

RETURN:        nothing

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCommonInitGame	proc	near
	uses	di, ds
	.enter

	clr	es:[gameOver]

	; initialize all the data for player1 and player2

	mov	es:[player1].SP_numberOfGuys, NUMBER_OF_INITIAL_PLAYERS
	mov	es:[player2].SP_numberOfGuys, NUMBER_OF_INITIAL_PLAYERS
	mov	es:[whoseTurn], offset player1
	mov	es:[player1].SP_opponent, offset player2
	mov	es:[player2].SP_opponent, offset player1
	mov	es:[player1].SP_activeColor, PLAYER1_ACTIVE_COLOR
	mov	es:[player2].SP_activeColor, PLAYER2_ACTIVE_COLOR
	mov	es:[player1].SP_player, mask GDN_PLAYER1
	mov	es:[player2].SP_player, mask GDN_PLAYER2
	mov	es:[player1].SP_noMoveString, offset Player1NoMove
	mov	es:[player2].SP_noMoveString, offset Player2NoMove
	mov	es:[player1].SP_human, 1
	mov	es:[player2].SP_human, 1
	mov	al, BAD_COORD
	mov	es:[activePiece].x_pos, al
	mov	es:[hintMoveCoord].x_pos, al
	tst	es:[computerTwoPlayer]
	jz	skipComputer
	; if there is a computer player set appropriate values
	mov	es:[player1].SP_human, 0
	mov	es:[player2].SP_human, 0
	mov	es:[player1].SP_noMoveString, offset ComputerNoMove
	mov	es:[player2].SP_noMoveString, offset ComputerNoMove
	mov	es:[computerPlayer], offset player1
skipComputer:
	tst	es:[computerPlayer]
	jz	cont
	mov	bx, es:[computerPlayer]
	mov	es:[bx].SP_noMoveString, offset ComputerNoMove
	mov	es:[bx].SP_human, 0

 ; jfh - try this to set the other no move to "you"
	tst  es:[player1].SP_human
	jz   p2NoMove
	mov	es:[player1].SP_noMoveString, offset YouNoMove
	jmp  cont
p2NoMove:
	mov	es:[player2].SP_noMoveString, offset YouNoMove
  ; end of try this ;-)
  
cont:
	; now set the maxcells value based on size of board
	; and set the lines value also based on size of board

;	call	UkiAllocBoard
	mov	cx, es:[maxcells]
	mov	bx, es:[gameBoard]
	push	es
	call	MemLock
	mov	es, ax
	clr	di
	clr	ax
	rep	stosb
	call	MemUnlock
	pop	es
	call	UkiCallInitGame
	call	UkiDoScore

	call	UkiSetPtrImage

	.leave
	ret
UkiCommonInitGame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiAllocBoard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	allocate or reallocate memory for game board

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	allocate aboard with one byte per cell

KNOWN BUGS/SIDEFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 3/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiAllocBoard	proc	near
	uses	ax, bx, cx, dx
	.enter
	mov	al, es:[cells]
	mul	al
	mov	es:[maxcells], ax
	clr	ah
	mov	al, es:[cells]
	inc	al
	mov	es:[lines], ax

	mov	ax, es:[maxcells]
	mov	bx, es:[gameBoard]
	mov	cx, ALLOC_DYNAMIC or ((mask HAF_NO_ERR) shl 8)
	; if we need to allocate a memory block for the board the do it
	tst	bx
	jnz	doRealloc

	call	MemAlloc
	mov	es:[gameBoard], bx

	jmp	done
doRealloc:
	; else just realloc to the corent size
	call	MemReAlloc
done:
	.leave
	ret
UkiAllocBoard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiSetPlayMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the player mode

CALLED BY:	GLOBAL (MSG_UKI_SET_PLAY_MODE)

PASS:		*DS:SI	= UkiContentClass object
		DS:DI	= UkiContentClassInstance
		CX	= UkiPlayMode

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ukiPlayModes	nptr.near \
		UkiTwoPlayer,
		UkiPlayerOne,
		UkiPlayerTwo,
		UkiComputer,
		UkiComputerContinuous

UkiSetPlayMode	method UkiContentClass, MSG_UKI_SET_PLAY_MODE
		.enter

		; Call the proper set-up routine
		;
		mov	es:[playMode], cl
		mov	bx, cx
		call	cs:[ukiPlayModes][bx]

		.leave
		ret
UkiSetPlayMode	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiTwoPlayer

DESCRIPTION:   sets mode to two player


PASS:          nothing

RETURN:        nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiTwoPlayer	proc	near
	clr	es:[computerPlayer]
	clr	es:[computerTwoPlayer]
	mov	es:[player1].SP_human, 1
	mov	es:[player2].SP_human, 1
	mov	es:[player1].SP_noMoveString, offset Player1NoMove
	mov	es:[player2].SP_noMoveString, offset Player2NoMove
	ret
UkiTwoPlayer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiPlayerOne

DESCRIPTION:   set for human to play player1


PASS:          nothing

RETURN:        nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiPlayerOne	proc	near
	mov	es:[computerPlayer], offset player2
	clr	es:[computerTwoPlayer]
	mov	es:[whoseTurn], offset player1
	mov	es:[player1].SP_human, 1
	mov	es:[player2].SP_human, 0
	mov	es:[player1].SP_noMoveString, offset YouNoMove
	mov	es:[player2].SP_noMoveString, offset ComputerNoMove
	call	UkiSetPtrImage
	ret
UkiPlayerOne	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiPlayerTwo

DESCRIPTION:   set for human to play player2


PASS:          nothing

RETURN:        nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiPlayerTwo	proc	near
	mov	es:[computerPlayer],offset player1
	clr	es:[computerTwoPlayer]
	mov	es:[whoseTurn], offset player2
	mov	es:[player1].SP_human, 0
	mov	es:[player2].SP_human, 1
	mov	es:[player1].SP_noMoveString, offset ComputerNoMove
	mov	es:[player2].SP_noMoveString, offset YouNoMove
	call	UkiSetPtrImage
	ret
UkiPlayerTwo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiComputer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up for the computer to play itself

CALLED BY:	UkiSetPlayMode

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/15/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiComputer	proc	near
	tst	es:[cells]
	jz	done
	mov	es:[computerPlayer], offset player1
	mov	es:[computerTwoPlayer], UPM_COMPUTER
	tst	es:[kbdVisible]
	jz	cont

	mov	di, es:[viewWindow]
        ; Get a graphics state to use.
        ; DI = ^h of grapics state block.
        call    GrCreateState
	push	di
	call	UkiDrawKbdPosition
	pop	di
	call	GrDestroyState
	mov	es:[kbdVisible], 0
cont:
	mov	es:[kbdState].x_pos, BAD_COORD
	call	UkiStartGame
done:
	ret
UkiComputer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiComputerContinuous
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up for the computer to play itself

CALLED BY:	UkiSetPlayMode

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/15/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiComputerContinuous	proc	near
	tst	es:[cells]
	jz	done
	mov	es:[computerPlayer], offset player1
	mov	es:[computerTwoPlayer], UPM_COMPUTER_CONTINUOUS
	tst	es:[kbdVisible]
	jz	cont

	mov	di, es:[viewWindow]
        ; Get a graphics state to use.
        ; DI = ^h of grapics state block.
        call    GrCreateState
	push	di
	call	UkiDrawKbdPosition
	pop	di
	call	GrDestroyState
	mov	es:[kbdVisible], 0
cont:
	mov	es:[kbdState].x_pos, BAD_COORD
	call	UkiStartGame
done:
	ret
UkiComputerContinuous	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	UkiClearView

DESCRIPTION:	Clears the view

PASS:		DI	= GState

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
	jimmy	2/91		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiClearView    proc	near
	uses	ax, bx, cx, dx
	.enter

        ;set the area color to white
        mov     ah, CF_INDEX
        mov     al, es:[viewColor]
        call    GrSetAreaColor

        ; Clear out the viewing window.
        call    GrGetWinBounds                 ; DI already set
        call    GrFillRect

	.leave
        ret
UkiClearView    endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiEndGameDialog

DESCRIPTION:   this routine puts up a dialog box indicating that the
		game is over

PASS:      	si = offset of string to put up    

RETURN:        

DESTROYED:      ???

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


UkiEndGameDialog	proc	far
	uses	es, bp, ax
	.enter

	; Do we need to display anything??
	;
	tst	es:[gameOver]
	jg	done
	inc	es:[gameOver]
	tst	es:[computerTwoPlayer]
	jz	doDialog
	cmp	es:[computerTwoPlayer], UPM_COMPUTER_CONTINUOUS
	je	done
	mov	ax, es:[player2].SP_numberOfGuys
	cmp	es:[player1].SP_numberOfGuys, ax
	je	doDialog
	jl	computerTwo
	mov	si, offset Computer1Wins
	jmp	doDialog
computerTwo:
	mov	si, offset Computer2Wins
doDialog:
	call	UkiStandardDialog
done:
	.leave
	ret
UkiEndGameDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiEndSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do sound for end of game

CALLED BY:	UkiCheckForEndOfGame

PASS:		ES	= DGroup
		BX	= 0 : tie game
			  mask GDN_PLAYER1 : player1 won
			  mask GDN_PLAYER2 : player2 won

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/14/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiEndSound	proc	near
	uses	si
	.enter

	tst	es:[computerTwoPlayer]
	jnz	done
	tst	es:[soundState]	; if sound option off, no sound
	jz	done

	; If tie, make nuetral sound
	;
	mov	cx, UKI_NEUTRAL_SOUND_BUFFER_SIZE
	mov	si, offset UkiNeutralSoundBuffer
	tst	bx
	jz	doSound

	; Else, make happy or sad sound
	;
	mov	cx, UKI_SAD_SOUND_BUFFER_SIZE
	mov	si, offset UkiSadSoundBuffer
	mov	bp, offset player1	
	and	bx, mask GDN_PLAYER1
	jnz	checkPlayer
	mov	bp, offset player2
checkPlayer:
	tst	es:[bp].SP_human
	jz	doSound			; computer won - so sad sound
	mov	cx, UKI_HAPPY_SOUND_BUFFER_SIZE
	mov	si, offset UkiHappySoundBuffer

	; Make some noise
doSound:
	mov	ax, SST_CUSTOM_BUFFER
	mov 	dx, cs			; sound buffer => DX:SI
	call	UserStandardSound
done:
	.leave
	ret
UkiEndSound	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiNoMoveDialogBox

DESCRIPTION:   this routine puts up a dialog box indicating that the
		current player whose turn it is has no legal move


PASS:         

RETURN:        

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiNoMoveDialogBox	proc	far
	uses	di, bx
	.enter
	push	es
	; first we make sure the game hasn't ended, of course if the
	; board is full, there are no legal moves, thus we don't need
	; to put up this dialog box
	mov	ax, es:[player1].SP_numberOfGuys
	add	ax, es:[player2].SP_numberOfGuys
	add	ax, es:[obstacles]
	cmp	ax, es:[maxcells]

	; test game Over bit, game could be over even if board isn't full
	je	done
	tst	es:[gameOver]
	jnz	done

	; if there is no computer player than show the dialog every time,
	; else, only show the first dialog is a series of moves
	mov	di, es:[whoseTurn]
	inc	es:[di].SP_noMoveCount
	tst	es:[computerPlayer]
	jz	doDialog
	cmp	es:[di].SP_noMoveCount, 1
	jg	done
doDialog:
	tst	es:[computerTwoPlayer]
	jnz	done
	; ok, game isn't over so lets put up the dialog box
	mov 	bx, es:[whoseTurn]
	mov	si, es:[bx].SP_noMoveString
	call	UkiStandardDialog
done:
	pop	es
	; now swap turns again since the other guy couldn't go
	mov	bx, es:[whoseTurn]
	mov	ax, es:[bx].SP_opponent
	mov	es:[whoseTurn], ax
	call	UkiSetPtrImage
	.leave
	ret
UkiNoMoveDialogBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:     	UkiCallStart

DESCRIPTION:   send a MSG_UKI_START to start up a new game


PASS:          

RETURN:        

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCallStart	proc	near

	clr	es:[gameOver]
	mov	ax, MSG_UKI_START
	GetResourceHandleNS	ContentBlock, bx
;	mov	bx, handle MyContent
	mov	si, offset MyContent
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE
	call	ObjMessage
	ret
UkiCallStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiMakeComputerMove

DESCRIPTION:   make a move for the computer


PASS:          nothing

RETURN:        nothing

DESTROYED:      ???

PSEUDO CODE/STRATEGY:
		if (no computer player) return
		if (not computers turn) return
		if (gameover) return
	
		if (computer has a move)
		{
			make the move
			if (next player is a computer player) return 
			/*if the next player is a computer this check is done
			    else where */
			else	check up on whether the next player can move
		}
		else
		{
			put up a dialog box saying no move 
				/*no dialogs for computer v. computer*/
			swap whoseTurn to next player
			check up on whether next player can move	
			if (no move for next player) game over
			else if (next player is a computer) call computer move
				else wait for human move
		}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiMakeComputerMove	method UkiContentClass, MSG_UKI_COMPUTER_MOVE

	; if there is no computer player than don't make a computer move
        tst     es:[computerPlayer]		
        jz      done

	; if its not the computer's turn then don't make a move
        mov     dx, es:[whoseTurn]
        cmp     dx, es:[computerPlayer]
        jnz     done
	; if the game is over than don't amke a move
        tst     es:[gameOver]
	jnz	done

	; now we get to make a move, first create a gstate
	mov	di, es:[viewWindow]
	call	GrCreateState
	push	di

	; now find a move
	call	UkiCallComputerFindMove
	; now make the move
	call	UkiComputerMakeBestMove
	; get current player
	; if carry == 0 then we didn't swap turns yet, so do that
	jnc	cont
	call	UkiNoMoveDialogBox
;	mov	bx, es:[whoseTurn]
;	mov	ax, es:[bx].SP_opponent
;	mov	es:[whoseTurn], ax
	
cont:
;	mov	bx, es:[whoseTurn]
;	tst	es:[bx].SP_human
;	jz	doneKillGS
	call	UkiCheckUpOnNextPlayer
;doneKillGS:
	pop	di
	call	GrDestroyState
done:
	ret		
UkiMakeComputerMove	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiJustMadeMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	????

PASS:		????

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
		since a move was just made we need to see if the game
		is over, so first we check for the end of the game

		if its not over, then swap whoseTurn to the next player
		and if its a computer player next, call off to computer move
		else wait for user input

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/20/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiJustMadeMove	proc	near
	.enter

	call	UkiCheckForEndOfGame
	tst	es:[gameOver]
	jnz	done
	; swap players turn
	call	UkiUndoHint
	mov	bx, es:[whoseTurn]
	mov	ax, es:[bx].SP_opponent
	mov	es:[whoseTurn], ax
	tst	es:[computerTwoPlayer]
	jz	doNextTurn
	mov	ax, es:[whoseTurn]
	mov	es:[computerPlayer], ax
doNextTurn:
	mov	ax, es:[computerPlayer]
	cmp	ax, es:[whoseTurn]
	jnz	done
	call	UkiCallComputerMove
done:
	call	UkiSetPtrImage
	.leave
	ret
UkiJustMadeMove	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCallComputerMove

DESCRIPTION:   send the computer move method off


PASS:          nothing

RETURN:        nothing

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


UkiCallComputerMove	proc	far uses di
	.enter
	
	;
	; Sleep for a bit, so we don't abuse the system
	;
	mov	ax, 6				;ax <- 6/60ths of a second
	call	TimerSleep
	;
	; Send ourselves a message to do another move
	;
	mov	ax, MSG_UKI_COMPUTER_MOVE
	GetResourceHandleNS	ContentBlock, bx
;	mov	bx, handle MyContent
	mov	si, offset MyContent
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE
	call	ObjMessage
	.leave
	ret
UkiCallComputerMove	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiComputerSuggestMove

DESCRIPTION:   


PASS:          

RETURN:        

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiComputerSuggestMove	method	UkiContentClass, MSG_UKI_COMPUTER_HINT

	tst	es:[computerTwoPlayer]
	jnz	done

	mov	di, es:[viewWindow]
	call	GrCreateState
	mov	cl, es:[activePiece].x_pos	; save active piece values
	mov	ch, es:[activePiece].y_pos
	mov	ax, es:[whoseTurn]
	call	UkiComputerMoveSearch	; find best move
	mov	es:[activePiece].x_pos, cl	; restore activePiece values
	mov	es:[activePiece].y_pos, ch

	; if the bestmoveCoord has a BAD_COORD then there waas no possible
	; move found
	cmp	es:[bestMoveCoord].x_pos,BAD_COORD 
	jz	done	; jump if no move found
	call	UkiDrawKbdPosition	; erase the KBC (if on screen)
	call	UkiUndoHint		; get rid of old one
	mov	al, es:[bestMoveCoord].x_pos
	mov	es:[hintMoveCoord].x_pos, al
	mov	al, es:[bestMoveCoord].y_pos
	mov	es:[hintMoveCoord].y_pos, al
	call	UkiDrawHint		; draw new one
	call	UkiDrawKbdPosition	; put back the KCB
	call	GrDestroyState
done:
	ret
UkiComputerSuggestMove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiDrawHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw a hint

CALLED BY:	global

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	get info from global bestMoveCoord and draw the hint

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/26/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawHint	proc	near
	.enter
	mov 	al, es:[hintMoveCoord].x_pos
	cmp	al, BAD_COORD
	jz	done	
	mov	bl, es:[hintMoveCoord].y_pos
	mov	cl, HINT_COLOR
	call	UkiDrawPlayer		
done:
	.leave
	ret
UkiDrawHint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiComputerMoveSearch

DESCRIPTION:   


PASS:          nothing

RETURN:        

DESTROYED:   	ax, bx, di, si, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiComputerMoveSearch	proc	far
	uses	cx, dx
	.enter
	mov	es:[bestMoveCoord].x_pos, BAD_COORD
	tst	es:[gameOver]
	jnz	done

	mov	bx, es:[computerPlayer]
	push	bx
	mov	ax, es:[whoseTurn]
	mov	es:[computerPlayer], ax
	call	UkiCallComputerFindMove	
	
	pop	bx
	mov	es:[computerPlayer], bx
	mov	es:[activePiece].x_pos, BAD_COORD
done:
	.leave
	ret
UkiComputerMoveSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCheckForEndOfGame

DESCRIPTION:   check for end of game


PASS:          nothing

RETURN:        nothing   (se[208ts global gameOver flag)

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCheckForEndOfGame	proc	far

	tst	es:[player1].SP_numberOfGuys
	jz	player2win
;test2:
	tst	es:[player2].SP_numberOfGuys
	jz	player1win
;test3:
	mov	dx, es:[player2].SP_numberOfGuys
	add	dx, es:[player1].SP_numberOfGuys
	add	dx, es:[obstacles]
	cmp     dx, es:[maxcells]
	jl	notOver
	mov	dx, es:[player1].SP_numberOfGuys
	cmp	dx, es:[player2].SP_numberOfGuys
	jl	player2win
	jg	player1win
	mov	si, offset TieGame
	clr	bx
	jmp	doEnd
player1win:
;	mov	bl, mask GDN_PLAYER1
;	mov	si, offset Player1Wins
;	tst	es:[player1].SP_human
;	jnz	doEnd
;	mov	si, offset ComputerWins
;	jmp	doEnd

  ; jfh - also check for whether the opponent is a human or the GPC

	mov	bl, mask GDN_PLAYER1
	tst  es:[player2].SP_human
	jz   p1YouWin          ; player 2 is the GPC

	mov	si, offset Player1Wins
	tst	es:[player1].SP_human
	jnz	doEnd
	mov	si, offset ComputerWins
	jmp	doEnd
p1YouWin:
	mov	si, offset YouWin
	jmp	doEnd

player2win:
;	mov	bl, mask GDN_PLAYER2
;	mov	si, offset Player2Wins
;	tst	es:[player2].SP_human
;	jnz	doEnd
;   	mov	si, offset ComputerWins
;	jmp	doEnd

  ; jfh - also check for whether the opponent is a human or the GPC

	mov	bl, mask GDN_PLAYER2
	tst  es:[player1].SP_human
	jz   p2YouWin          ; player 1 is the GPC

	mov	si, offset Player2Wins
	tst	es:[player2].SP_human
	jnz	doEnd
	mov	si, offset ComputerWins
	jmp	doEnd
p2YouWin:
	mov	si, offset YouWin
	jmp	doEnd

done:
	ret

doEnd:
	call	UkiDoScore

	call	UkiEndSound

	call	UkiEndGameDialog
	cmp	es:[computerTwoPlayer], UPM_COMPUTER_CONTINUOUS
	je	restartGame
	clr	es:[computerTwoPlayer]
	jmp	done
restartGame:
	mov	es:[whoseTurn], mask GDN_PLAYER1
	call	UkiCallStart
	jmp	done

notOver:
	call	UkiCallAdjustMoveValues
	jmp	done
if 0
	tst	es:[computerTwoPlayer]
	jz	done
	call	UkiCallComputerMove
	jmp	done
endif
UkiCheckForEndOfGame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiComputerMakeBestMove

DESCRIPTION:   


PASS:          global best move coordinates

RETURN:        si = 1 if move made, else si = 0

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiComputerMakeBestMove	proc	near
	
	tst	es:[gameOver]
	jnz	done
	cmp	es:[bestMoveCoord].x_pos, BAD_COORD
	jz	noMoveFound
	mov	al, es:[bestMoveCoord].x_pos
	mov	bl, es:[bestMoveCoord].y_pos
	mov	cl, al
	mov	dl, bl
	; valid move returns the type of move
	; so move piece knows whether to jump or replicate
	call	UkiCallValidMove
	mov	ch, al
	mov	dh, bl
	call	UkiCallMovePiece
	clc
	jmp	done
noMoveFound:
	stc
	jmp	done
done:	
	ret
UkiComputerMakeBestMove	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiUndoHint

DESCRIPTION:   get rid of the hint indicator on the screen if its there...

PASS:		nothing

RETURN:        	Void.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiUndoHint	proc	far	
	uses	ax, bx, cx, dx
	.enter	
	cmp	es:[hintMoveCoord].x_pos, BAD_COORD
	jz	done
	mov	al, es:[boardColor]		; BACKGROUND_COLOR
	mov	ah, CF_INDEX
	call	GrSetAreaColor
	clr	ax
	mov	bx, ax
	mov	al, es:[hintMoveCoord].x_pos
	mov	bl, es:[hintMoveCoord].y_pos
	call	UkiDrawGetCellCoords
	inc	ax
	inc	bx
	dec	cx
	dec	dx
;	sub	cx, 2
;	sub	dx, 2
	call	GrFillRect
	mov	es:[hintMoveCoord].x_pos, BAD_COORD
done:
	.leave
	ret
UkiUndoHint	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiCheckUpOnNextPlayer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	this routine is calllled when a human player
		is about to go, so that if he has no move
		it will take care of things

CALLED BY:	????

PASS:		????

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCheckUpOnNextPlayer	proc	near
	uses	di
	.enter
	tst	es:[gameOver]
	jnz	done
	call	UkiComputerMoveSearch
	cmp	es:[bestMoveCoord].x_pos, BAD_COORD
	jnz	done
	; if no move found for either player, game is over
	; else if no move just the next player
	; was   found, then the computer should try to go again
	; first increment the no move count
	call	UkiNoMoveDialogBox
	tst	es:[computerTwoPlayer]
	jz	noChange
	mov	es:[computerPlayer], ax
noChange:
	mov	al, es:[player1].SP_noMoveCount
	tst	al
	jz	checkForHumanNext
	mov	al, es:[player2].SP_noMoveCount
	tst	al
	jz	checkForHumanNext
endOfGame:
	mov	ax, es:[maxcells]
	mov	es:[obstacles], ax
	call	UkiCheckForEndOfGame
	jmp	doNotMove
checkForHumanNext:
	mov	bx, es:[whoseTurn]
	tst	es:[bx].SP_human
	jz	done
	tst	es:[computerPlayer]
	jnz	done
	call	UkiComputerMoveSearch
	cmp	es:[bestMoveCoord].x_pos, BAD_COORD
	jnz	doNotMove
	jmp	endOfGame	
done:
	mov	ax, es:[whoseTurn]
	cmp	ax, es:[computerPlayer]
	jnz	doNotMove
	call	UkiCallComputerMove
doNotMove:
	.leave
	ret
UkiCheckUpOnNextPlayer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCallInitGame

DESCRIPTION:   do a far call through the variable es:initGame


PASS:          cx, dx = info to pass on to far routine

RETURN:        ??

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCallInitGame	proc	near
	mov	si, offset initGame
	call	UkiCallCommon
	mov	es:[kbdState].x_pos, BAD_COORD
	ret
UkiCallInitGame	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCallValidMove

DESCRIPTION:   do a far call through the variable es:initGame


PASS:          cx, dx = info to pass on to far routine

RETURN:        ??

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCallValidMove	proc	far
	mov	si, offset validMove
	call	UkiCallCommon
	ret
UkiCallValidMove	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCallMovePiece

DESCRIPTION:   do a far call through the variable es:initGame


PASS:          cx, dx = info to pass on to far routine

RETURN:        ??

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCallMovePiece	proc	far
	uses	ax
	.enter
	tst	 es:[kbdVisible]
	jz	doCommon
	call	UkiDrawKbdPosition
doCommon:
	mov	si, es:[whoseTurn]
	clr	es:[si].SP_noMoveCount
	mov	si, offset movePiece
	call	UkiCallCommon
	call	UkiDoScore
	tst	 es:[kbdVisible]
	jz	doAfterMove
	call	UkiDrawKbdPosition
doAfterMove:
	call	UkiJustMadeMove
	mov	bx, es:[whoseTurn]
	tst	es:[bx].SP_human
	jz	done
	call	UkiCheckUpOnNextPlayer
done:
	.leave
	ret
UkiCallMovePiece	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCallAdjustMoveValues

DESCRIPTION:   do a far call through the variable es:adjustMoveValues


PASS:          cx, dx = info to pass on to far routine

RETURN:        ??

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCallAdjustMoveValues	proc	far
	mov	si, offset adjustMoveValues
	call	UkiCallCommon
	ret
UkiCallAdjustMoveValues	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCallKeyboardPressed

DESCRIPTION:   do a far call through the variable es:userInput


PASS:          cx, dx = info to pass on to far routine

RETURN:        ??

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCallKeyboardPressed	proc	far
;	push	bx
;	mov	bx, es:[whoseTurn]
;	tst	es:[bx].SP_human
;	pop	bx
;	jz	done
	mov	si, offset userInput
	call	UkiCallCommon
	pushf
	call	UkiDoScore
	popf
	cmp	si, UKI_MOVE_MADE
	jz	moveMade
	cmp	si, UKI_ACTIVE_MOVE_MADE
	jz	done
	cmp	si, UKI_NO_MOVE_MADE
;	jz	swapTurn
	tst	es:[soundState]
	jz	done
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
	jmp	done
moveMade:
	call	UkiJustMadeMove
;checkForHuman:
	mov	bx, es:[whoseTurn]
	tst	es:[bx].SP_human
	jz	done
	call	UkiCheckUpOnNextPlayer
	jmp	done
;swapTurn:
;	mov	bx, es:[whoseTurn]
;	mov	ax, es:[bx].SP_opponent
;	mov	es:[whoseTurn], ax
;	jmp	checkForHuman
done:
	ret
	
UkiCallKeyboardPressed	endp
if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCallTypeOfMove

DESCRIPTION:   do a far call through the variable es:typeOfMove


PASS:          cx, dx = info to pass on to far routine

RETURN:        ??

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCallTypeOfMove	proc	far
	mov	si, offset typeOfMove
	call	UkiCallCommon
	call	UkiDoScore
	ret
UkiCallTypeOfMove	endp
endif
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCallUserInput

DESCRIPTION:   do a far call through the variable es:userInput
		this is equivalent to doing a keypress except that
		we first turn off the keyboard indicator if its on

PASS:          cx, dx = info to pass on to far routine

RETURN:        ??

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
UkiCallMouseClick	proc	far
	tst	es:[kbdVisible]
	jz	cont
	push	cx, dx
	call	UkiKbdEscape
	pop	cx, dx
cont:
	call	UkiCallKeyboardPressed
	ret
UkiCallMouseClick	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCallComputerFindMove

DESCRIPTION:   do a far call through the variable es:initGame


PASS:          cx, dx = info to pass on to far routine

RETURN:        ??

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCallComputerFindMove	proc	far
	mov	si, offset computerFindMove
	call	UkiCallCommon
	ret
UkiCallComputerFindMove	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCallComon

DESCRIPTION:   do a far call through the variable es:initGame


PASS:          cx, dx = info to pass on to far routine
		si = offset of routine to call
RETURN:        ??

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCallCommon	proc	far
	uses	ax, bx
	.enter
	mov	ax, es:[si].offset
	mov	bx, es:[si].handle 
	call	ProcCallModuleRoutine
	.leave
	ret
UkiCallCommon	endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiDoScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the current score

CALLED BY:	????

PASS:		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDoScore	proc	far
	uses	ax, bx, cx, dx, di, si, es
	.enter
	
	mov	ax, es:[player1].SP_numberOfGuys
	GetResourceHandleNS	Interface, bx
	mov	si, offset WhiteScore
	call	UkiDoScoreHelp

	mov	ax, es:[player2].SP_numberOfGuys
	mov	si, offset BlackScore
	call	UkiDoScoreHelp

	.leave
	ret
UkiDoScore	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiDoScoreHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the score for a player

CALLED BY:	UkiDoScore

PASS:		AX	= Score
		^lBX:SI	= Text object to hold score

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDoScoreHelp	proc	near
tempString 	local	UHTA_NULL_TERM_BUFFER_SIZE dup (char)
	.enter

	; Create the string
	;
	push	bp
	mov	cx, mask UHTAF_NULL_TERMINATE
	segmov	es, ss
	lea	di, tempString
	clr	dx
	call	UtilHex32ToAscii

	; Stuff it into the text object
	;
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss
	mov	bp, di			; string => DX:BP
	clr	cx			; it's NULL-terminated
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	.leave
	ret
UkiDoScoreHelp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiSetSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the state of sound output

CALLED BY:	GLOBAL (MSG_UKI_SET_SOUND)

PASS:		*DS:SI	= UkiContentClass object
		DS:DI	= UkiContentClassInstance
		CX	= UkiSound

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiSetSound	method dynamic	UkiContentClass, MSG_UKI_SET_SOUND
		.enter

		; Store the value away, and consult the .INI file
		; if necessary
		;
		mov	es:[soundState], cl
		cmp	cl, US_PREF
		jne	done
		call	UkiSetSoundFromPreferences
done:
		.leave
		ret
UkiSetSound	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FastRandom
			
SYNOPSIS:	Pseudo-random number generator

CALLED BY:	Global



PASS:		ES	= DGroup


RETUNR		dx	= Random Number

Known BUGS/SIDE EFFECTS/IDEAS
		stolen from Matt

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAGIC16_SEED	equ	2b41h	    	; magic seed

FastRandom 	proc	far 
	mov	dx, es:[randomSeed]	; dx<-current seed 
	shl	dx, 1
	ja	FR_5
	xor	dx, MAGIC16_SEED
FR_5:  	mov	es:[randomSeed], dx

	and	dx, 3ffh
	ret
FastRandom	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiSetSoundFromPrefrences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the sound variable according to user's pref. in
		geos.ini file
CALLED BY:	initUIComponents
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Get Boolean from init file

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

soundCategory	char	"ui",0
soundKey	char	"sound",0

UkiSetSoundFromPreferences		proc	near
	uses	ax, bx, cx, dx, ds, di, si
	.enter

	; Grab the value from the .INI file
	;
	mov	ax, US_ON			;assume sound is ON
	mov	cx, cs				;CX,DS <- segment of
	mov	ds, cx				;backgroundCategory/Key
	mov	si, offset soundCategory	;DS:SI <- category ASCIIZ str
	mov	dx, offset soundKey		;CX:DX <- key ASCIIZ str
	call	InitFileReadBoolean
	and	ax, 1				; ff -> 1
	mov	es:[soundState], al		; return value in ax

if	0
	; Now set the proper selection
	;
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, US_PREF
	clr	dx				;determinate
	GetResourceHandleNS	UkiSoundList, bx
	mov	si, offset UkiSoundList
	clr	di
	call	ObjMessage
endif

	.leave
	ret
UkiSetSoundFromPreferences		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiStandardDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display a standard dialog box

CALLED BY:	INTERNAL

PASS:		SI	= String chunk handle in DataBlock

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiStandardDialog	proc	near
	uses	ax, bx, bp, es
	.enter
	
	; Display a standard dialog box
	;
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, CustomDialogBoxFlags \
		<FALSE, CDT_NOTIFICATION, GIT_NOTIFICATION,FALSE>
	mov	bx, handle DataBlock
	call	MemLock
	mov	es, ax
	mov	ss:[bp].SDP_customString.segment, ax
	mov	ax, es:[si]
	mov	ss:[bp].SDP_customString.offset, ax
	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialog	; pops arguments from stack!
	call	MemUnlock

	.leave
	ret
UkiStandardDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiSetUpBoardSizeUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the UI determining the board size

CALLED BY:	UkiStartUki

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiSetUpBoardSizeUI	proc	far
	uses	ax, bx, cx, dx, di, si
	.enter
	
	mov_tr	cx, ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx			; determinate
	GetResourceHandleNS	UkiBoardSizeList, bx
	mov	si, offset UkiBoardSizeList
	clr	di
	call	ObjMessage

	.leave
	ret
UkiSetUpBoardSizeUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Uki Sound Bytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiNote	macro	note, duration, rest
	VoiceOn		0, note, FORTE
	DeltaTick	duration
	VoiceOff	0
	DeltaTick	rest
endm

UkiHappySoundBuffer	label	word
			ChangeEnvelope	0, IP_REED_ORGAN
			DeltaTick	0
			UkiNote 	MIDDLE_C, 10, 0
			UkiNote 	MIDDLE_E, 10, 0
			UkiNote 	MIDDLE_G, 10, 0
			UkiNote 	HIGH_C, 15, 0
			UkiNote 	MIDDLE_G, 8, 0
			UkiNote 	HIGH_C, 25, 0
			General		GE_END_OF_SONG

UKI_HAPPY_SOUND_BUFFER_SIZE	equ	$ - (offset UkiHappySoundBuffer)

UkiSadSoundBuffer	label	word
			ChangeEnvelope	0, IP_REED_ORGAN
			DeltaTick	0
			UkiNote 	LOW_D, 20, 1
			UkiNote 	LOW_D, 20, 1
			UkiNote 	LOW_D, 7, 1
			UkiNote 	LOW_D, 20, 0
			UkiNote 	LOW_F, 20, 0
			UkiNote 	LOW_E, 7, 1
			UkiNote 	LOW_E, 20, 0
			UkiNote 	LOW_D, 7, 1
			UkiNote 	LOW_D, 20, 0
			UkiNote 	LOW_D_b, 7, 0
			UkiNote 	LOW_D, 20, 0
			General		GE_END_OF_SONG

UKI_SAD_SOUND_BUFFER_SIZE	equ	$ - (offset UkiSadSoundBuffer)

UkiNeutralSoundBuffer	label	word
			ChangeEnvelope	0, IP_REED_ORGAN
			DeltaTick	0
			UkiNote 	MIDDLE_C, 10, 4
			UkiNote 	LOW_F, 6, 2
			UkiNote 	LOW_F, 6, 2
			UkiNote 	LOW_F_SH, 15, 2
			UkiNote 	LOW_F, 15, 10
			UkiNote 	LOW_B, 15, 4
			UkiNote 	MIDDLE_C, 15, 0
			General		GE_END_OF_SONG

UKI_NEUTRAL_SOUND_BUFFER_SIZE	equ	$ - (offset UkiNeutralSoundBuffer)

CommonCode	ends
