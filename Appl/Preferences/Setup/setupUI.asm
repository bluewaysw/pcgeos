COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1998 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		setupUI.asm

AUTHOR:		Gene Anderson

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/1/98		Initial revision


DESCRIPTION:
	Code for UI selection of Setup

	$Id: setupUI.asm,v 1.3 98/06/19 10:40:09 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata segment
	SetupUIListClass
idata ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUICheckRestart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_SETUP_UI_CHECK_RESTART
PASS:		ds = es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/1/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupUICheckRestart method	SetupClass, MSG_SETUP_UI_CHECK_RESTART
		.enter

	;
	; See if anything changed; assume so
	;
		call	CheckSPUIChanged
		mov	si, offset UIRestartScreen
		mov	bx, handle UIRestartScreen
		jne	gotScreen			;branch if changed
	;
	; Nothing changed -- bring up the next screen or exit
	;
		cmp	ds:[mode], MODE_UPGRADE_UI_CHANGE
		je	spuiDone
	;
	; Bring up the next (mouse) screen
	;
		mov	si, offset MouseSelectScreen
		mov	bx, handle MouseSelectScreen
gotScreen:
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage
done:

		.leave
		ret

	;
	; Only here to set the SPUI
	;
spuiDone:
		mov	si, offset SPUIDoneText
		call	SetupComplete
		jmp	done
SetupUICheckRestart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSPUIChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the SPUI has been changed

CALLED BY:	SetupUISelectionComplete()
PASS:		none
RETURN:		z flag - clear (jne) if changed
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/1/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

uiCategory	char	"ui", 0
specificNameKey	char	"specname", 0
specificKey	char	"specific", 0

GetINISPUI	proc	near
	;
	; Get the current setting from the .INI file
	;
		push	bp
		mov	{TCHAR}es:[di], NULL
		segmov	ds, cs, cx
		mov	si, offset uiCategory
		mov	dx, offset specificNameKey
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0,
						(size FileLongName)>
		call	InitFileReadString
		pop	bp
		ret
GetINISPUI	endp

CheckSPUIChanged	proc	near
		uses	ds, si, es, di
spuiBuf		local	FileLongName
		.enter

	;
	; Get the current setting from the .INI file
	;
		segmov	es, ss
		lea	di, ss:spuiBuf
		call	GetINISPUI
	;
	; Get the SPUI selected by the user
	;
		call	GetSelectedUI
	;
	; Compare the strings
	;
		clr	cx				;cx <- NULL-terminated
		segmov	es, ss, di
		lea	di, ss:spuiBuf			;es:di <- .INI setting
		call	LocalCmpStringsNoCase
	;
	; unlock our string
	;
		mov	bx, handle Strings
		call	MemUnlock
done::

		.leave
		ret
CheckSPUIChanged	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name of the selected SPUI

CALLED BY:	CheckSPUIChanged()
PASS:		none
RETURN:		ds:si - ptr to string
		Strings - locked
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/1/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetSelectedUI	proc	near
		uses	ax, dx, bp, di
		.enter

	;
	; get the selection
	;
		mov	si, offset UISelectList
		mov	bx, handle UISelectList
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
	;
	; get a ptr to the string 
	;
		mov	si, (size UICombo)
		mul	si
		mov_tr	si, ax				;si <- offset
		mov	si, cs:uicombos[si].UIC_name	;si <- chunk of name
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]			;ds:si <- ptr to name

		.leave
		ret
GetSelectedUI	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteCUILink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the CUI link ("NewDeal Desktop")

CALLED BY:	SetUIOptions

PASS:		none
RETURN:		none
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/00   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

LocalDefNLString cuiLink <"DESKTOP\\\\xxxxxxx Easy Desktop",0>

DeleteCUILink	proc	near
		uses	ds
		.enter
	;
	; delete the "NewDeal Desktop" (i.e., CUI) link
	;
		call	FilePushDir
		mov	ax, SP_TOP
		call	FileSetStandardPath
		segmov	ds, cs, ax
		mov	dx, offset cuiLink		;ds:dx <- filename
		call	FileDelete
		call	FilePopDir

		.leave
		ret
DeleteCUILink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUIOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the options for our CUI combo

CALLED BY:	PrefUICDialogApply

PASS:		di - offset in uicombos
RETURN:		none
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/00   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UICombo	struct
	UIC_environment	BooleanByte
	UIC_specific	nptr.TCHAR
	UIC_launcher	nptr.TCHAR
	UIC_advLauncher	nptr.TCHAR
	UIC_bitmap	optr
	UIC_name	lptr.TCHAR
	UIC_room	word
UICombo ends

uicombos UICombo <
	BB_TRUE,
	offset NewUIStr,
	offset WelcomeStr,
	offset NewDeskStr,
	CUIMoniker,
	offset cuiNameStr,
	1
>,<
	BB_FALSE,
	offset NewUIStr,
	offset WelcomeStr,
	0,
	NewUIMoniker,
	offset auiNameStr,
	3
>,<
	BB_FALSE,
	offset MotifStr,
	offset NewManagerStr,
	0,
	MotifMoniker,
	offset motifNameStr,
	0
>

haveEnvAppKey char "haveEnvironmentApp", 0
defaultLauncherKey char "defaultLauncher", 0
uiFeaturesCat char "uiFeatures", 0
uiAdvFeaturesCat char "uiFeatures - advanced", 0
fileManagerCat char "fileManager", 0
linksDoneKey char "linksDone", 0
welcomeCat char "welcome", 0
startRoomKey char "startuproom", 0

if ERROR_CHECK
LocalDefNLString MotifStr <"motifec.geo", 0>
LocalDefNLString NewUIStr <"newuiec.geo", 0>
LocalDefNLString NewManagerStr <"managere.geo", 0>
LocalDefNLString NewDeskStr <"newdeske.geo", 0>
LocalDefNLString WelcomeStr <"welcomee.geo", 0>
else
LocalDefNLString MotifStr <"motif.geo", 0>
LocalDefNLString NewUIStr <"newui.geo", 0>
LocalDefNLString NewManagerStr <"File Manager", 0>
LocalDefNLString NewDeskStr <"newdesk.geo", 0>
LocalDefNLString WelcomeStr <"welcome.geo", 0>
endif

SetUIOptions	proc	near
		uses	ds, si, es
		.enter

	;
	; get the table entry
	;
		segmov	ds, cs, cx
		mov	es, cx
	;
	; handle haveEnvironmentApp key
	;
		mov	si, offset uiCategory
		mov	dx, offset haveEnvAppKey
		mov	al, cs:uicombos[di].UIC_environment
		clr	ah
		call	InitFileWriteBoolean
		tst	ax
		jnz	keepLink
		call	DeleteCUILink
afterLink:
	;
	; handle [ui] specific = key
	;
		push	di
		mov	dx, offset specificKey
		mov	di, cs:uicombos[di].UIC_specific
		call	InitFileWriteString
		pop	di
	;
	; handle [uiFeatures] defaultLauncher = key
	;
		push	di
		mov	si, offset uiFeaturesCat
		mov	dx, offset defaultLauncherKey
		mov	di, cs:uicombos[di].UIC_launcher
		call	InitFileWriteString
		pop	di
	;
	; handle [uiFeatures - advanced] defaultLauncher = key
	;
		push	di
		mov	si, offset uiAdvFeaturesCat
		mov	di, cs:uicombos[di].UIC_advLauncher
		tst	di
		jz	noAdvLauncher
		call	InitFileWriteString
noAdvLauncher:
		pop	di
	;
	; handle the start room [welcome] startuproom = key
	;
		push	di, bp
		mov	bp, cs:uicombos[di].UIC_room
		tst	bp
		jz	noRoom
		mov	si, offset welcomeCat
		mov	dx, offset startRoomKey
		call	InitFileWriteInteger
noRoom:
		pop	di, bp

		.leave
		ret

	;
	; obscure case: tell the file manager to rebuild the links
	;
keepLink:
		mov	si, offset fileManagerCat
		mov	dx, offset linksDoneKey
		mov	ax, FALSE
		call	InitFileWriteBoolean
		jmp	afterLink
SetUIOptions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSPUIEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the entry for the currently selected SPUI

CALLED BY:	SetupSPUISampleDraw()
PASS:		ds - fixupable
RETURN:		di - offset in spuiBitmapTable
		carry - set if error (di = default)
DESTROYED:	si, es, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/2/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetSPUIEntry	proc	near
		uses	ax, bx, cx, dx, bp
		.enter

		mov	si, offset UISelectList
		mov	bx, handle UISelectList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
		jc	done				;branch if no selection

		mov	di, (size UICombo)
		mul	di
		mov_tr	di, ax				;di <- offset
		clc					;carry <- no error

done:

		.leave
		ret
GetSPUIEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSPUISampleDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the SPUI sample

CALLED BY:	MSG_VIS_DRAW
PASS:		bp - GState
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/1/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupSPUISampleDraw method SetupSPUISampleClass, MSG_VIS_DRAW
	;
	; Get our bounds
	;
		call	VisGetBounds
		mov	dx, bx				;(ax,dx) <- (x,y)
	;
	; Get the currently selected SPUI
	;
		call	GetSPUIEntry			;cs:di <- entry
		jc	done				;branch if error
	;
	; Get the bitmap
	;
		push	ax, dx
		mov	bx, cs:uicombos[di].UIC_bitmap.handle
		mov	dx, bx
		call	MemLock
		mov	ds, ax
		mov	si, cs:uicombos[di].UIC_bitmap.offset
		mov	si, ds:[si]			;ds:si <- ptr to bitmap
		pop	ax, bx				;(ax,bx) <- (x,y)
		push	dx
	;
	; Draw it
	;
		mov	di, bp				;di <- GState
		clr	dx				;dx <- no callback
		call	GrDrawBitmap
	;
	; Unlock the bitmap
	;
		pop	bx				;bx <- bitmap resource
		call	MemUnlock
done:

		.leave
		ret
SetupSPUISampleDraw	endm

SetupSPUIRecalcSize	method dynamic SetupSPUISampleClass,
							MSG_VIS_RECALC_SIZE

		call	GetDisplayType
		mov	cx, 342
		mov	dx, cs:sampleHeights[si]
		ret
SetupSPUIRecalcSize	endm

;
; NOTE: this table is used instead of using 1/2 the actual display
; size to allow for larger displays (e.g., 1024x768) which still
; use the same size color sample as VGA.
;

sampleHeights word \
	256,	;SDT_COLOR
	256,	;SDT_BW
	100	;SDT_CGA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDisplayType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current display type

CALLED BY:	SetupSPUISampleDraw()
PASS:		none
RETURN:		si - SetupDisplayType
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/2/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetDisplayType	proc	near
		uses	ax, es
		.enter

		segmov	es, dgroup, ax
	;
	; Assume color
	;
		mov	si, SDT_COLOR			;si <- SetupDisplayType
		call	SetupGetDisplayType		;ah <- DisplayType
		mov	al, ah
	;
	; Check for B&W
	;
		andnf	al, mask DT_DISP_CLASS
		cmp	al, DC_GRAY_1 shl offset DT_DISP_CLASS
		jne	gotType				;branch if not B&W
		mov	si, SDT_BW			;si <- SetupDisplayType
	;
	; Check for CGA
	;
		andnf	ah, mask DT_DISP_ASPECT_RATIO
		cmp	ah, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
		jne	gotType				;branch if not CGA
		mov	si, SDT_CGA			;si <- SetupDisplayType
gotType:
		.leave
		ret
GetDisplayType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUIRestartForUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restart for a new UI

CALLED BY:	MSG_SETUP_UI_RESTART_FOR_UI
PASS:		cx - current selection
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/1/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

resetKey		char "forceDeleteStateFilesOnceOnly",0

SetupUIRestartForUI	method	SetupClass, MSG_SETUP_UI_RESTART_FOR_UI
		.enter

	;
	; set most of the stuff
	;
		call	GetSPUIEntry
		call	SetUIOptions
	;
	; Reset the state files to handle changing the defaultLauncher
	;
		segmov	ds, cs, cx
		mov	si, offset uiCategory
		mov	dx, offset resetKey
		mov	ax, TRUE
		call	InitFileWriteBoolean
	;
	; Save the current settings
	;
		mov	bx, handle UISelectList
		mov	si, offset UISelectList
		mov	di, mask MF_CALL
		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjMessage
	;
	; Set the mode
	;
		segmov	ds, dgroup, ax
		mov	bp, MODE_UPGRADE_UI_CHANGE
		cmp	ds:[mode], MODE_UPGRADE_UI_CHANGE
		je	gotMode
		mov	bp, MODE_AFTER_SETUP_UI_CHANGE
gotMode:
		call	SetupSetRestartMode
	;
	; Restart the system
	;
		mov	ax, SST_RESTART
		call	SysShutdown

		.leave
		ret
SetupUIRestartForUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUIListGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a moniker for the SPUI list

CALLED BY:	MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
PASS:		ss:bp - GetItemMonikerParams
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/15/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupUIListGetMoniker	method SetupUIListClass,
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
	;
	; find the corresponding table entry
	;
		mov	ax, ss:[bp].GIMP_identifier
		mov	di, (size UICombo)
		mul	di
		mov_tr	di, ax				;di <- offset
	;
	; get the name
	;
		mov	si, cs:uicombos[di].UIC_name
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]			;ds:si <- ptr to name
		ChunkSizePtr ds, si, cx			;cx <- # bytes
	;
	; copy the name to the buffer
	;
		movdw	esdi, ss:[bp].GIMP_buffer
		cmp	cx, ss:[bp].GIMP_bufferSize
		ja	bufferTooSmall
DBCS <		shr	cx, 1				;>
		mov	bp, cx				;bp <- # of chars
		LocalCopyNString

done:
		call	MemUnlock
		ret

bufferTooSmall:
		clr	bp
		jmp	done
SetupUIListGetMoniker	endm

SetupUIListBuildArray	method SetupUIListClass,
					MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		mov	cx, length uicombos
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		GOTO	ObjCallInstanceNoLock
SetupUIListBuildArray	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUIListGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a moniker for the SPUI list

CALLED BY:	MSG_PREF_DYNAMIC_LIST_FIND_ITEM
PASS:		cx:dx - NULL-terminated string
		bp - nonzero to find best fit
RETURN:		if found:
			ax - item #
			carry - clear
		else:
			carry - set
			ax - first item after requested
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/15/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupUIListFindItem	method SetupUIListClass,
					MSG_PREF_DYNAMIC_LIST_FIND_ITEM
		push	ds, si
		movdw	esdi, cxdx
		call	LocalStringLength		;cx <- str length
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		clr	si				;si <- offset
		clr	ax				;ax <- index
strLoop:
		push	si
		mov	si, cs:uicombos[si].UIC_name
		mov	si, ds:[si]			;ds:si <- ptr to name
		call	LocalCmpStringsNoCase
		pop	si
		je	foundString
		inc	ax				;ax <- next index
		add	si, (size UICombo)
		cmp	si, (size uicombos)
		jb	strLoop				;branch while more
		pop	ds, si
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		stc					;carry <- not found
		jmp	done

foundString:
		pop	ds, si
		clc
done:
		call	MemUnlock
		ret
SetupUIListFindItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUISelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has selected a new SPUI

CALLED BY:	MSG_SETUP_UI_LIST_SELECTED
PASS:		cx - current selection
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/1/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupUISelected method	SetupUIListClass, MSG_SETUP_UI_LIST_SELECTED
		.enter

		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		mov	si, offset UISelectSample
		mov	bx, handle UISelectSample
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		ret
SetupUISelected	endm
