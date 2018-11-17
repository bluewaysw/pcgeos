COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Sokoban
FILE:		sokobanDocument.asm

AUTHOR:		Steve Yegge, Nov 18, 1992

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE 
				Creates a blank saved-game.

    INT InitializeGameFile      Set up data structures associated with a
				game.

    INT GetUserName             Get the user name into the map block.

    MTD MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT 
				User opened a saved game (or a newly
				created one).

    INT ReadInGameFromFile      Initialize game from existing game file.

    INT DetermineVideoMode      Determine our video DisplayType and act
				accordingly.

    MTD MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE 
				Save map & data block.

    INT SaveGameToFile          Save the various game variables into the
				game file.

    MTD MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE 
				Setup stuff after opening a game

    INT ReadCachedDataFromFile  Read in the raw data from the file.

    MTD MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT 
				See if we made the high score list.

    MTD MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE 
				User saves game under a new name

    MTD MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED 
				"Save as" completed

    MTD MSG_GEN_PROCESS_OPEN_APPLICATION 
				Start 'er up.

    INT OpenAndInitGameFile     Open the game file

    MTD MSG_GEN_PROCESS_CLOSE_APPLICATION 
				Shut down the game and close application.

    INT SaveAndCloseGameFile    Save the game and close the game file.

    INT DirtyTheSavedGame       Tells the document control the game has
				been dirtied

    INT SokobanMarkBusy         Marks the app as busy.

    INT SokobanMarkNotBusy      Marks the app as not-busy

    MTD MSG_GEN_PROCESS_INSTALL_TOKEN 
				Install tokens.

    MTD MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT 
				Update a game file from a previous sokoban

    INT UpdateEarlierIncompatibleMapBlock 
				upgrade the map block in an old document

    INT UpdateEarlierIncompatibleMap 
				Restore saved game map

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial revision

DESCRIPTION:
	
	document control routines for Sokoban

	$Id: sokobanDocument.asm,v 1.1 97/04/04 15:13:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata	segment

vmFileHandle	word

udata	ends

DocumentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanInitializeDocumentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a blank saved-game.

CALLED BY:	MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE

PASS: 		es = dgroup
		bp = file handle

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- read level 1 into currentMap
	- make a block that contains the saved-game info
	- read currentMap into the save-block
	- make a Map Block and save the save-block's handle in it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL

SokobanInitializeDocumentFile	method dynamic SokobanProcessClass, 
			MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE

		call	InitializeGameFile

		clc
		
		ret
SokobanInitializeDocumentFile	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeGameFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up data structures associated with a game.

CALLED BY:	SokobanInitializeDocumentFile or SokobanOpenApplication,
		depending on whether the DOCUMENT_CONTROL flag is set.

PASS:		bp = file handle
		es = dgroup

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	initializes some global variables

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not DOCUMENT_CONTROL
docToken	GeodeToken <"SOKd", MANUFACTURER_ID_GEOWORKS>
endif

InitializeGameFile	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter

		Assert	dgroup	es
		Assert	vmFileHandle	bp
	;
	;  Make sure level 1 is in currentMap, because save gets called after
	;  this...
	;
		mov	es:[vmFileHandle], bp
		mov	es:[level], 1

	;
	;  Set up the game state.
	;
		andnf	es:[gameState], not (mask SGS_MOVED_BAG or \
						mask SGS_SAVED_BAG or \
						mask SGS_UNSAVED_BAG or \
						mask SGS_CAN_UNDO)
		clr	es:[moves]
		clr	es:[pushes]
		call	ConvertTextMap		; reads into currentMap
	;
	;  Create a block for the saved-position map
	;
		Assert	dgroup	es
		mov	bx, es:[vmFileHandle]	; file handle
		mov	cx, size Map
		clr	ax			; user id
		call	VMAlloc
		push	ax			; save handle
	;
	;  Create a block to hold the saved map.
	;
		mov	bx, es:[vmFileHandle]	; file handle
		mov	cx, size Map
		clr	ax			; user id
		call	VMAlloc
	;
	;  Move level 1 into the save-block.
	;
		segmov	ds, es, cx		; ds = dgroup
		push	ax			; save block handle
		call	VMLock
		mov	es, ax			; es = save block
		clr	di			; es:di = save block
		mov	si, offset currentMap	; ds:si = level 1
		mov	cx, size Map
		rep	movsb
		call	VMDirty
		call	VMUnlock
	;
	;  Create a map block for holding saved-game info.
	;
		mov	cx, size SokobanMapBlock
		clr	ax			; user-specified id
		call	VMAlloc			; ax = block handle
	;
	;  Store the save-block vm handle in the map block, and
	;  intialize the other data.
	;
		push	ax			; save handle
		call	VMLock			; returns segment in ax
		mov	ds, ax			; segment of locked map block
		pop	ax			; restore map block handle
		pop	ds:[SMB_map]		; restore save block handle
		pop	ds:[SMB_savedMap]	; restore save-pos handle
		clr	ds:[SMB_moves]
		clr	ds:[SMB_pushes]
		clr	ds:[SMB_state]		; flags
		mov	ds:[SMB_level], 1
if HIGH_SCORES
	;
	;  Get the user's name for the high score list and
	;  store it in the map block.
	;
		call	GetUserName
endif
	;
	;  Set the map block.
	;
		Assert	vmFileHandle	bx
		call	VMDirty
		call	VMUnlock		; pass bp = mem handle
		call	VMSetMapBlock		; pass ax = block handle

if not DOCUMENT_CONTROL
	;
	; Some stuff has to be done manually that would otherwise be done
	; by the document control.  Set the document token.
	;
		segmov	es, cs
		mov	di, offset docToken
		mov	cx, size GeodeToken
		mov	ax, FEA_TOKEN
		call	FileSetHandleExtAttributes ; ignore errors
	;
	; Set the creator token.
	;
		sub	sp, size GeodeToken
		mov	di, sp
		segmov	es, ss			; es:di = token buffer
		mov	ax, GGIT_TOKEN_ID
		push	bx			; save file handle
		clr	bx
		call	GeodeGetInfo		; es:di = GeodeToken
		pop	bx			; restore file handle
		mov	ax, FEA_CREATOR
		call	FileSetHandleExtAttributes
		add	sp, size GeodeToken

endif ; not DOCUMENT_CONTROL


		.leave
		ret
InitializeGameFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetUserName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the user name into the map block.

CALLED BY:	SokobanInitializeDocumentFile

PASS:		ds = map block

RETURN:		SMB_name initialized

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if HIGH_SCORES

GetUserName	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	;  Fill the buffer with zeroes in advance.
	;
		segmov	es, ds, cx
		mov	di, offset SMB_name
		mov	cx, MAX_USER_NAME_LENGTH/2
		clr	ax
		rep	stosw
	;
	;  Select all the text.
	;
		GetResourceHandleNS	EnterNameText, bx
		mov	si, offset	EnterNameText
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		call	ObjMessage
	;
	;  Initiate the interaction for typing in their name.
	;
		GetResourceHandleNS	EnterNameDialog, bx
		mov	si, offset	EnterNameDialog
		call	UserDoDialog		; block until they respond
	;
	;  Get the name from the dialog.
	;
		mov	dx, ds			; dx = map block
		mov	bp, offset SMB_name	; dx.bp = name buffer
		GetResourceHandleNS	EnterNameText, bx
		mov	si, offset	EnterNameText
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage

		.leave
		ret
GetUserName	endp

endif	; HIGH_SCORES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanAttachUIToDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User opened a saved game (or a newly created one).

CALLED BY:	MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT

PASS:		es = dgroup
		bp = file handle

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- clear the scoring information from prior game, if any
	- get the map block
	- get the save-block handle from the map block
	- get the save-block and lock it
	- get the map and read it into currentMap
	- invalidate the content

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL
SokobanAttachUIToDocument	method dynamic SokobanProcessClass, 
			MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT
		.enter
	;
	;  Call common routine for setting up game.
	;
		call	ReadInGameFromFile

		clc			; success! (?)

		.leave
		ret
SokobanAttachUIToDocument	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadInGameFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize game from existing game file.

CALLED BY:	SokobanAttachUIToDocument or OpenAndInitGameFile
		depending on whether DOCUMENT_CONTROL is set.

PASS:		bp = file handle
		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadInGameFromFile	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		Assert	dgroup	es
		Assert	vmFileHandle	bp
if not DOCUMENT_CONTROL
	;
	;  Read in some of the data.  This gets called separately
	;  in the document-control version of the game.
	;
		call	ReadCachedDataFromFile
endif
	;
	;  Initialize information about the video mode, to be used
	;  later in determining the right bitmaps to draw. Must be done before
	;  UpdateContentSize, else that routine'll think everything's 0,0
	;  when the app is first launched.
	;
		call	DetermineVideoMode
	;
	;  Don't scan the map here.  We either scan the map for the
	;  first time in SokobanInitializeDocumentFile, or we get the
	;  map out of the save-map block in our document file.
	;
if HIGH_SCORES
		clr	es:[scoreLevel]
		clr	es:[scoreMoves]
		clr	es:[scorePushes]
endif
		call	UpdateLevelData
		call	UpdateBagsData
		call	UpdateSavedData
		call	UpdateMovesData
		call	UpdatePushesData

		call	UpdateContentSize
	;
	;  We can neither restore position nor undo if we quit
	;  & restart a game, so disable both triggers.
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	EnableRestoreTrigger		; preserves ax
		call	EnableUndoTrigger		; me too
	;
	;  Make the map update.  This happens automatically
	;  when we open the app, but not when we switch games.
	;
		GetResourceHandleNS	TheMap, bx
		mov	si, offset	TheMap
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjMessage
	;
	;  Set-usable or not-usable the "Replay Level" dialog
	;  based on whether they are in won-game mode.
	;
		call	UpdateReplayLevelDialog
if PLAY_SOUNDS
	;
	;  Update the sound option selector and color selector.
	;
		mov	cx, es:[soundOption]
		GetResourceHandleNS	SoundItemGroup, bx
		mov	si, offset	SoundItemGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx			; not indeterminate
		call	ObjMessage
endif

if SET_BACKGROUND_COLOR
		mov	cx, es:[colorOption]
		GetResourceHandleNS	BackgroundColorSelector, bx
		mov	si, offset	BackgroundColorSelector
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx			; not indeterminate
		call	ObjMessage
endif		
		.leave
		ret
ReadInGameFromFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DetermineVideoMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine our video DisplayType and act accordingly.

CALLED BY:	SokobanAttachUIToDocument

PASS:		es = dgroup

RETURN:		nothing (sets dgroup:videoMode)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DetermineVideoMode	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		Assert	dgroup	es

	;
	;  Get the display scheme.
	;
		GetResourceHandleNS	SokobanApp, bx
		mov	si, offset	SokobanApp
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
		call	ObjMessage		; ah = DisplayType
	;
	;  Store an enumeration of SokobanVideoMode in idata.
	;
		mov	al, ah
		andnf	ax, mask DT_DISP_ASPECT_RATIO or  \
				(mask DT_DISP_CLASS shl 8)
		cmp	al, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
		je	cgaMode
		cmp	al, DAR_SQUISHED shl offset DT_DISP_ASPECT_RATIO
		je	cgaMode
		
		cmp	ah, DC_GRAY_1 shl offset DT_DISP_CLASS
		je	mcgaMode
	;
	;  Default to VGA artwork.
	;
		mov	es:[videoMode], SVM_VGA
		mov	es:[bitmapWidth], VGA_BITMAP_WIDTH
		mov	es:[bitmapHeight], VGA_BITMAP_HEIGHT
		ornf	es:[walkInfo], mask WS_MODE
		jmp	short	done
cgaMode:
		mov	es:[videoMode], SVM_CGA
		mov	es:[bitmapWidth], CGA_BITMAP_WIDTH
		mov	es:[bitmapHeight], CGA_BITMAP_HEIGHT
		jmp	short	done
mcgaMode:
		mov	es:[videoMode], SVM_MONO
		mov	es:[bitmapWidth], VGA_BITMAP_WIDTH
		mov	es:[bitmapHeight], VGA_BITMAP_HEIGHT
done:


	;
	; Set the increment for the view to be the width/height of a bitmap.
	; 
		mov	dx, size PointDWord
		sub	sp, dx
		mov	bp, sp

		mov	ax, es:[bitmapWidth]
		mov	ss:[bp].PD_x.low, ax
		mov	ss:[bp].PD_x.high, 0

		mov	ax, es:[bitmapHeight]
		mov	ss:[bp].PD_y.low, ax
		mov	ss:[bp].PD_y.high, 0

		GetResourceHandleNS	TheView, bx
		mov	si, offset TheView
		mov	ax, MSG_GEN_VIEW_SET_INCREMENT
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage
		add	sp, size PointDWord
		.leave
		ret
DetermineVideoMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanWriteCachedDataToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save map & data block.

CALLED BY:	MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE

PASS: 		es = dgroup
		bp = file handle

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL
SokobanWriteCachedDataToFile	method dynamic SokobanProcessClass, 
			MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE
		
		mov	es:[vmFileHandle], bp
	;
	;  Call common routine for saving data.
	;
		mov	bx, bp
		call	SaveGameToFile

		clc
		
		ret
SokobanWriteCachedDataToFile	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveGameToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the various game variables into the game file.

CALLED BY:	SokobanWriteCachedDataToFile (DOCUMENT_CONTROL = TRUE)
		or SokobanAdvanceLevel/SaveAndCloseGameFile
			(DOCUMENT_CONTROL = FALSE)

PASS:		es = dgroup
		bx = file handle

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	does NOT close the file.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveGameToFile	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	;  Get the save-block handle, and also save the globals:
	;  level, moves, pushes, saved, position.  We won't be
	;  rescanning the map, so we need to record all this info
	;  in the document file.
	;
		call	VMGetMapBlock		; returns in ax
		call	VMLock
		mov	ds, ax
		push	ds:[SMB_savedMap]
		push	ds:[SMB_map]
		mov	cx, es:[level]
		mov	ds:[SMB_level], cx
		mov	cx, es:[moves]
		mov	ds:[SMB_moves], cx
		mov	cx, es:[pushes]
		mov	ds:[SMB_pushes], cx
		mov	cl, es:[walkInfo]
		mov	ds:[SMB_walkState], cl
		mov	cx, es:[internalLevel]
		mov	ds:[SMB_internalLevel], cx
		mov	cx, es:[tempSave].TSS_moves
		mov	ds:[SMB_savedMoves], cx
		mov	cx, es:[tempSave].TSS_pushes
		mov	ds:[SMB_savedPushes], cx
	;
	;  Only the state bits which represent information which is valid
	;  across resets are stored.
	;
		mov	cx, es:[gameState]
		andnf	cx, mask SGS_WON_GAME or \
			    mask SGS_EXTERNAL_LEVEL or mask SGS_SAVED_POS
		mov	ds:[SMB_state], cx	; state record
	;
	;  Dirty & unlock the map block.
	;
		call	VMDirty
		call	VMUnlock
	;
	;  Lock the save-block and read currentMap into it.
	;
		pop	ax			; restore save-block handle
		segmov	ds, es, cx		; ds = dgroup
		call	VMLock
		mov	es, ax
		clr	di			; es:di = saved map
		mov	si, offset currentMap	; ds:si = currentMap

		mov	cx, size Map
		rep	movsb
		call	VMDirty
		call	VMUnlock
	;
	; Lock the saved-pos map and read savedMap into it
	;
		pop	ax			; restore save-block handle
		call	VMLock
		mov	es, ax
		clr	di			; es:di = saved map
		mov	si, offset saveMap	; ds:si = currentMap

		mov	cx, size Map
		rep	movsb
		call	VMDirty
		call	VMUnlock

		.leave
		ret
SaveGameToFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanReadCachedDataFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup stuff after opening a game

CALLED BY:	MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE

PASS: 		es = dgroup
		bp = file handle

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL
SokobanReadCachedDataFromFile	method dynamic SokobanProcessClass, 
			MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE
		
		mov	es:[vmFileHandle], bp
		call	ReadCachedDataFromFile

		ret
SokobanReadCachedDataFromFile	endm
endif	; DOCUMENT_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadCachedDataFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in the raw data from the file.

CALLED BY:	SokobanReadCachedDataFromFile or ReadInGameFromFile,
		depending on the value of the DOCUMENT_CONTROL option.

PASS:		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadCachedDataFromFile	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		Assert	dgroup	es
		Assert	vmFileHandle	bp
	;
	;  Get the map block, lock it, and get its stuff.
	;
		mov	bx, bp
		call	VMGetMapBlock		; returns ax = handle
		
		call	VMLock			; lock map block
		mov	ds, ax
		push	ds:[SMB_map]		; save-game block handle
		push	ds:[SMB_savedMap]	; save-position block handle

		mov	dx, ds:[SMB_level]
		mov	es:[level], dx
		mov	dx, ds:[SMB_moves]
		mov	es:[moves], dx
		mov	dx, ds:[SMB_pushes]
		mov	es:[pushes], dx
		mov	dx, ds:[SMB_internalLevel]
		mov	es:[internalLevel], dx
		mov	dl, ds:[SMB_walkState]
		mov	es:[walkInfo], dl
		mov	dx, ds:[SMB_savedMoves]
		mov	es:[tempSave].TSS_moves, dx
		mov	dx, ds:[SMB_savedPushes]
		mov	es:[tempSave].TSS_pushes, dx
	;
	;  Since we're only storing the necessary state bits in the file,
	;  we can just move the whole record into the state variable.
	;  (none of the other bits should be set at this point).
	;
		mov	dx, ds:[SMB_state]
		mov	es:[gameState], dx
		call	VMUnlock		; unlock map block
	;
	;  Lock the saved-position block and read its info into saveMap.
	;
		pop	ax			; SMB_savedMap
		call	VMLock
		mov	ds, ax
		clr	si			; ds:si = saved-position
		
		mov	di, offset saveMap	; global variable save map
		mov	cx, size Map
		rep	movsb			; copy away!
		call	VMUnlock		; unlock SMB_savedMap
	;
	;  Lock the save block and read its info into currentMap.
	;
		pop	ax			; ax = save game handle
		call	VMLock
		mov	ds, ax
		clr	si			; ds:si = map
		
		mov	di, offset currentMap	; read in current game
		mov	cx, size Map
		rep	movsb
		call	VMUnlock

		.leave
		ret
ReadCachedDataFromFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanDetachUIFromDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we made the high score list.

CALLED BY:	MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT

PASS: 		es = dgroup
RETURN:		carry clear if successful
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL
SokobanDetachUIFromDocument	method dynamic SokobanProcessClass, 
				MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT
		.enter
if HIGH_SCORES
	;
	;  Do the high score thing, if they've gone up a level.
	;
		tst	es:[scoreLevel]
		jz	noScore
		call	UpdateScoreList
noScore:
endif
		.leave
		mov	di, offset SokobanProcessClass
		GOTO	ObjCallSuperNoLock
SokobanDetachUIFromDocument	endm
endif	; DOCUMENT_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanPhysicalSaveAsFileHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User saves game under a new name

CALLED BY:	MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE

PASS:		es = dgroup
		bp = file handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL
SokobanPhysicalSaveAsFileHandle	method dynamic SokobanProcessClass, 
			MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE
		
		mov	es:[vmFileHandle], bp
		
		clc
		
		ret
SokobanPhysicalSaveAsFileHandle	endm
endif	; DOCUMENT_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanSaveAsCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	"Save as" completed

CALLED BY:	MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_COMPLETED

PASS:		es = dgroup
		bp = file handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL
SokobanSaveAsCompleted	method dynamic SokobanProcessClass, 
					MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED
		
		mov	es:[vmFileHandle], bp
		
		clc
		
		ret
SokobanSaveAsCompleted	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start 'er up.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		ds = es = dgroup
		cx	- AppAttachFlags
		dx	- Handle of AppLaunchBlock, or 0 if none.
		  	  This block contains the name of any document file
			  passed into the application on invocation.  Block
			  is freed by caller.
		bp	- Handle of extra state block, or 0 if none.
		  	  This is the same block as returned from
		  	  MSG_GEN_PROCESS_CLOSE_APPLICATION, in some previous
			  MSG_META_DETACH.  Block is freed by caller.

RETURN: 	nothing
		AppLaunchBlock - preserved
		extra state block - preserved
		
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanOpenApplication	method dynamic SokobanProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
		uses	ax, cx, dx, bp
		.enter
if LEVEL_EDITOR
	;
	;  See if there is a state block.
	;
		tst	bp
		jz	noStateBlock
	;
	;  Restore the editor map.
	;
		push	ax, cx
		mov	bx, bp
		call	MemLock		; ax = segment of state block
		mov	ds, ax
		mov	di, offset es:[editorMap]
		clr	si
		mov	cx, size Map
		rep	movsb
		call	MemUnlock
		pop	ax, cx		; restore AppAttachFlags
		segmov	ds, es		; restore dgroup ptr
noStateBlock:		
endif	; LEVEL_EDITOR

if not DOCUMENT_CONTROL
	;
	;  No document control shme -- open the document file and
	;  initialize it if necessary.
	;
		call	OpenAndInitGameFile

endif	; (not DOCUMENT_CONTROL)

if PLAY_SOUNDS
	;
	;  Start the sound stuff.
	;
		CallMod	SoundSetupSounds
	;
	;  Play something.
	;
		mov	cx, SS_START_GAME
		CallMod	SoundPlaySound
endif
		.leave
	;
	;  Call the superclass.
	;
		mov	di, offset SokobanProcessClass
		GOTO	ObjCallSuperNoLock				
SokobanOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenAndInitGameFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the game file

CALLED BY:	SokobanOpenApplication

PASS:		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	saves file handle in global variable

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not DOCUMENT_CONTROL

sokobanFileName	char	"SOKOBAN.000",0
nullPath	char "\\",0

OpenAndInitGameFile	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	;  Make sure the file is in SP_DOCUMENT.
	;
		call	FilePushDir

		segmov	ds, cs, dx
		mov	dx, offset nullPath
		
		mov	bx, SP_DOCUMENT
		call	FileSetCurrentPath
	;
	;  Attempt to open the file.
	;
		mov	ax, (VMO_CREATE shl 8) or mask VMAF_FORCE_READ_WRITE
		mov	dx, offset sokobanFileName
		clr	cx
		call	VMOpen			; bx = file handle
		jc	fail
	;
	;  We've successfully opened the file.
	;
		mov	bp, bx
		cmp	ax, VM_CREATE_OK	; new file?
		jne	oldFile
		call	InitializeGameFile
oldFile:
	;
	;  Existing file - read in game.
	;
		call	ReadInGameFromFile		
done::
	;
	;  Store file handle in global variable.
	;
		Assert	dgroup	es
		mov	es:[vmFileHandle], bx
exit:
	;
	;  Restore working directory.
	;
		call	FilePopDir

		.leave
		ret
fail:
	;
	;  Whine at user.
	;
		mov	ax, SST_ERROR
		call	UserStandardSound
		jmp	exit

OpenAndInitGameFile	endp

endif	; not DOCUMENT_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shut down the game and close application.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		ds = es = dgroup

RETURN:		cx = handle of block to save (0 for none)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanCloseApplication	method dynamic SokobanProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION
		uses	ax, dx, bp, es
		.enter
if PLAY_SOUNDS
	;
	;  Shut down the sound stuff.
	;
		call	SoundShutOffSounds
endif
if LEVEL_EDITOR
	;
	;  Create a state block
	;
		mov	ax, size Map
		mov	cx, (mask HAF_LOCK shl 8) or mask HF_SWAPABLE
		call	MemAlloc	; ax = segment, bx = handle
		jnc	copyMap
	;
	;  An error occurred trying to create the state block.
	;
		mov	ax, SST_ERROR
		call	UserStandardSound
		clr	cx
		jmp	done
copyMap:
	;
	;  Copy the editor map
	;
		mov	si, offset ds:[editorMap]
		mov	es,ax
		clr	di
		mov	cx, size Map
		rep	movsb
	;
	;  Unlock and return the state block.
	;
		call	MemUnlock
		mov	cx, bx

else	; not LEVEL_EDITOR
	;
	;  We don't need a state block for anything, since all
	;  our useful information is stored in the game file.
	;
		clr	cx			; no state block
endif

if not DOCUMENT_CONTROL
	;
	;  Save & close the file.
	;
		call	SaveAndCloseGameFile	; don't trash cx!
endif
done::
		.leave
		mov	di, offset SokobanProcessClass
		GOTO	ObjCallSuperNoLock
SokobanCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveAndCloseGameFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the game and close the game file.

CALLED BY:	SokonbanCloseApplication

PASS:		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	closes the file

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not DOCUMENT_CONTROL
SaveAndCloseGameFile	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		Assert	dgroup	es
	;
	;  Write the various global variables into the file.
	;
		clr	bx
		xchg	bx, es:[vmFileHandle]
		tst	bx
		jz	done

		Assert	vmFileHandle	bx
		call	SaveGameToFile
	;
	;  Close the file.
	;
		clr	ax				; flags
		call	VMClose
		jnc	done
	;
	;  Whine.
	;
		mov	ax, SST_ERROR
		call	UserStandardSound
done:
		.leave
		ret
SaveAndCloseGameFile	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DirtyTheSavedGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the document control the game has been dirtied

CALLED BY:	MoveBag, MovePlayer

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL	
DirtyTheSavedGame	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	bx, es:[vmFileHandle]
		call	VMGetMapBlock			; returns block in ax
		call	VMLock
		call	VMDirty
		call	VMUnlock
		
		.leave
		ret
DirtyTheSavedGame	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanMarkBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Marks the app as busy.

CALLED BY:	UTILITY

PASS:		nothing

RETURN:		nothing (ds fixed up)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanMarkBusy	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		GetResourceHandleNS	SokobanApp, bx
		mov	si, offset	SokobanApp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	ObjMessage

		.leave
		ret
SokobanMarkBusy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanMarkNotBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Marks the app as not-busy

CALLED BY:	UTILITY

PASS:		nothing

RETURN:		nothing (ds fixed up)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanMarkNotBusy	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		GetResourceHandleNS	SokobanApp, bx
		mov	si, offset	SokobanApp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	ObjMessage

		.leave
		ret
SokobanMarkNotBusy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanInstallToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install tokens.

CALLED BY:	MSG_GEN_PROCESS_INSTALL_TOKEN

PASS:		*ds:si	= SokobanProcessClass object
		ds:di	= SokobanProcessClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SokobanInstallToken	method dynamic SokobanProcessClass, 
					MSG_GEN_PROCESS_INSTALL_TOKEN
		.enter
	;
	;  Call our superclass to get the ball rolling...
	;
		mov	di, offset SokobanProcessClass
		call	ObjCallSuperNoLock
	;
	;  Install datafile token.
	;
		mov	ax, ('S') or ('O' shl 8)	; ax:bx:si = token used
		mov	bx, ('K') or ('d' shl 8)	;  for datafile
		mov	si, MANUFACTURER_ID_GEOWORKS
		call	TokenGetTokenInfo		; is it there yet?
		jnc	done				; yes, do nothing
		mov	cx, handle SokobanDatafileMonikerList
		mov	dx, offset SokobanDatafileMonikerList
		clr	bp			; list is in data resource...
		call	TokenDefineToken	; add icon to token database
done:
		.leave
		ret
SokobanInstallToken	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanUpdateEarlierIncompatibleDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a game file from a previous sokoban

CALLED BY:	MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
PASS:		es	= dgroup
		^lcx:dx	= document object
		bp	= file handle
RETURN:		carry 	= set if error
		ax	= FileError if carry set, otherwise destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL
SokobanUpdateEarlierIncompatibleDocument method dynamic SokobanProcessClass, \
		MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
		uses	cx, dx, bp
		.enter
	;
	; allocate a block for the saved position
	;
		mov	bx,bp			; bx = VM file handle
		clr	ax			; user id
		mov	cx, size Map
		call	VMAlloc			; ax = block
	;
	; load the map block
	;
		push	ax
		call	VMGetMapBlock		; ax = map block handle
		call	VMLock			; ax = seg, bp = handle
		mov	ds,ax
		pop	ax			; ax = saved pos block
		
	;
	; update the map block
	;
		call	UpdateEarlierIncompatibleMapBlock
	;
	; unlock the map block and lock down the saved game
	;
		mov	cx, ds:[SMB_level]
		mov	ax, ds:[SMB_map]
		call	VMUnlock
		call	VMLock			; ax = seg, bp = mem hdl
	;
	; update the saved game and unlock it
	;
		call	UpdateEarlierIncompatibleMap
		call	VMUnlock
	;
	; set the protocol in the file
	;
		sub	sp, size ProtocolNumber
		mov	cx, size ProtocolNumber
		segmov	es,ss
		mov	di,sp
		mov	es:[di].PN_major, SOKOBAN_DOCUMENT_PROTO_MAJOR
		mov	es:[di].PN_minor, SOKOBAN_DOCUMENT_PROTO_MINOR
		mov	ax, FEA_PROTOCOL
		call	FileSetHandleExtAttributes
		add	sp, size ProtocolNumber
	;
	; tell the document control we were successful
	;
		clc
		.leave
		ret
SokobanUpdateEarlierIncompatibleDocument	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateEarlierIncompatibleMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	upgrade the map block in an old document

CALLED BY:	SokobanUpdateEarlierIncompatibleDocument
PASS:		ax = VM handle of saved position block
		bp = mem handle of map block
		ds = segment of map block
RETURN:		ds = segment of map block (may have changed)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL
UpdateEarlierIncompatibleMapBlock	proc	near
		uses	ax,bx,cx
		.enter
	;
	; resize the block
	;
		push	ax
		mov	ax, size SokobanMapBlock
		mov	bx, bp
		mov	ch, mask HAF_NO_ERR or mask HAF_ZERO_INIT
		call	MemReAlloc
		mov	ds,ax				; ds = map segment
		pop	ax
	;
	; initialize the new fields
	;
		mov	ds:[SMB_savedMap], ax
		andnf	ds:[SMB_state], not mask SGS_EXTERNAL_LEVEL
	;
	; mark the map block dirty
	;
		call	VMDirty
		.leave
		ret
UpdateEarlierIncompatibleMapBlock	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateEarlierIncompatibleMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore saved game map 

CALLED BY:	SokobanUpdateEarlierIncompatibleDocument
PASS:		bp = mem handle of saved game
		cx = current level
		es = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	just rescan the level

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOCUMENT_CONTROL
UpdateEarlierIncompatibleMap	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
		mov	es:[level], cx
	;
	; resize the block
	;
		mov	ax, size Map
		mov	bx, bp
		mov	ch, mask HAF_NO_ERR
		call	MemReAlloc		; ax = map segent
	;
	; reload the current level into currentMap
	;
		call	ConvertTextMap
	;
	; copy it to the VM block
	;
		segmov	ds,es
		mov	es,ax			; es = map segment
		mov	si, offset currentMap
		clr	di
		mov	cx, size Map
		rep	movsb
		segmov	es,ds
	;
	; dirty the block
	;
		call	VMDirty
		.leave
		ret
UpdateEarlierIncompatibleMap	endp
endif

DocumentCode	ends
