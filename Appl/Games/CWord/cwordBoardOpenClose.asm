COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		
FILE:		cwordBoardOpenClose.asm

AUTHOR:		Peter Trinh, Aug 30, 1994

ROUTINES:
	Name			Description
	----			-----------

	METHODS
	-------
	CwordOpenApplication
	CwordBoardOpenApplication
	CwordCloseApplication
	CwordExit
	BoardVisOpen			Grabs focus, target,
					initializes bounds and instance data
	BoardVisClose			Releases focus, target
	BoardInitializeBoard		Initializes the Board for new puzzle
	BoardCleanUp			Un-build the Board object and
					clear all unused memory.  

	PRIVATE/INTERNAL ROUTINES
	-------------------------
	CwordVUMNOWMessageToKeyboardQuickTips
	CwordVUMNOWMessageToPenQuickTips


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/30/94   	Initial revision


DESCRIPTION:
	
	These are the routines that are called when opening and
	closing the Crossword application, as well as starting and
	ending a game in the application.


	$Id: cwordBoardOpenClose.asm,v 1.1 97/04/04 15:14:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include initfile.def
include iapp.def

CwordFileCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop up the puzzle selector box.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		*ds:si	= CwordProcessClass object
		ds:di	= CwordProcessClass instance data
		ds:bx	= CwordProcessClass object (same as *ds:si)
		es 	= segment of CwordProcessClass
		ax	= message #

	 	cx	- AppAttachFlags
		dx	- Handle of AppLaunchBlock, or 0 if none.
		  	  This block contains the name of any document file
			  passed into the application on invocation.  Block
			  is freed by caller.
		bp	- Handle of extra state block, or 0 if none.
		  	  This is the same block as returned from
		  	  MSG_GEN_PROCESS_CLOSE_APPLICATION, in some previous
			  MSG_META_DETACH.  Block is freed by caller.

RETURN:		
DESTROYED:	
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordOpenApplication	method dynamic CwordProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
	uses	ax, cx, dx, bp
	.enter

	push	cx,dx				; attach flags, block
	mov	di, offset CwordProcessClass
	call	ObjCallSuperNoLock
	pop	cx,dx				; attach flags, block

	; Tell the File Module that we are opening.
	mov	bx, handle SelectorBox		; single-launchable
	mov	si, offset SelectorBox
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CFB_OPEN_APPLICATION
	call	ObjMessage

	mov	bx, handle Board
	mov	si, offset Board
	mov	di, mask MF_FIXUP_DS or mask MF_CALL	;happen now
	mov	ax, MSG_CWORD_BOARD_OPEN_APPLICATION
	call	ObjMessage

	test	cx, mask AAF_RESTORING_FROM_STATE
	jz	normalStart

	; we are restoring from state so the last puzzle played must
	; be displayed by this application

	mov	bx, handle SelectorBox		; single-launchable
	mov	si, offset SelectorBox
	mov	ax, MSG_CFB_LOAD_LAST_PUZZLE_PLAYED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
finish:
	.leave
	ret

normalStart:
	mov	bx,dx				;AppLaunchBlock
	call	MemLock
	mov	es,ax
	tst	es:[ALB_dataFile]
	call	MemUnlock
	jnz	openFile

if PEN_POSSIBLE
	call	SysGetPenMode
	cmp	ax,TRUE
	je	enablePen

	mov	ax,MSG_GEN_SET_USABLE
	call	CwordVUMNOWMessageToKeyboardQuickTips
	mov	ax,MSG_GEN_SET_NOT_USABLE
	call	CwordVUMNOWMessageToPenQuickTips
endif

initiate::
        ;
        ; Check first to see if the user really wants to see a quick tip.
		  ;
	; nah - blow off the tips...
	;     call    CwordCheckGetQuickTipsStartup
	;	  jc      letsPlay
		  jmp      letsPlay

	mov	bx, handle HelpInteraction	; single-launchable
	mov	si, offset HelpInteraction
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage
	jmp	finish

if PEN_POSSIBLE
	enablePen:
	mov	ax,MSG_GEN_SET_NOT_USABLE
	call	CwordVUMNOWMessageToKeyboardQuickTips
	mov	ax,MSG_GEN_SET_USABLE
	call	CwordVUMNOWMessageToPenQuickTips
	jmp	initiate
endif

openFile:
	;    Use MF_CALL so that AppLaunchBlock is not destroyed before
	;    we get the name out of it.
	;

	mov	bx, handle SelectorBox		
	mov	si, offset SelectorBox
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_CFB_LOAD_PUZZLE_FROM_APP_LAUNCH_BLOCK
	call	ObjMessage
	jmp	finish

letsPlay:
        mov     bx, handle SelectorBox
        mov     si, offset SelectorBox
        mov     di, mask MF_FIXUP_DS
        mov     ax, MSG_CFB_LOAD_LAST_PUZZLE_PLAYED
        call    ObjMessage
        jmp     finish

CwordOpenApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordIACPNewConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open passed puzzle.

CALLED BY:	MSG_META_IACP_NEW_CONNECTION
PASS:		*ds:si	= CwordApplicationClass object
		ds:di	= CwordApplicationClass instance data
		ds:bx	= CwordApplicationClass object (same as *ds:si)
		es 	= segment of CwordApplicationClass
		ax	= message #

		cx	- Handle of AppLaunchBlock, or 0 if none.
		  	  This block contains the name of any document file
			  passed into the application on invocation.  Block
			  is freed by caller.
	 	dx	- non-zero if just launched (will get OPEN_APPLICATION)
		bp	- IACPConnection

RETURN:		
DESTROYED:	
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/19/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordIACPNewConnection	method dynamic CwordApplicationClass, 
					MSG_META_IACP_NEW_CONNECTION
	uses	ax, cx, dx, bp, si
	.enter
	; Anything to do? (new datafile when already running)
	tst	dx
	jnz	done
	push	cx
	mov_tr	bx, cx				; ^hbx = ALB
	push	ds				; save ds
	call	MemLock
	mov	ds, ax				; ds:0 = ALB
	tst	ds:[ALB_dataFile]		; filename present?
	call	MemUnlock
	pop	ds				; restore ds
	jz	popDone				; branch if no file
doIt:
	; close open box, but leave quick tips
	mov	bx, handle SelectorInteraction
	mov	si, offset SelectorInteraction
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	; save current file
	mov	bx, handle SelectorBox
	mov	si, offset SelectorBox
	mov	ax, MSG_CFB_SAVE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx				; dx = app launch block
	jc	done				; error saving, don't open new
	; open new file
	mov	ax, size AppLaunchBlock
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jc	done				; mem error, don't open new
	push	ds, es
	mov	es, ax				; es:di = dest
	clr	di
	xchg	bx, dx				; bx = ALB, dx = copy
	call	MemLock
	mov	ds, ax				; ds:si = src
	clr	si
	mov	cx, size AppLaunchBlock
	rep movsb
	call	MemUnlock			; unlock AppLaunchBlock
	pop	ds, es
	mov	bx, handle SelectorBox
	mov	si, offset SelectorBox
	; send copy of ALB (dx) so we can call superclass which frees ALB
	mov	ax, MSG_CFB_LOAD_PUZZLE_FROM_LAUNCH_BLOCK_COPY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	.leave
	mov	di, offset CwordApplicationClass
	call	ObjCallSuperNoLock
	ret
popDone:
	pop	cx
	jmp	done
CwordIACPNewConnection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordCheckGetQuickTipsStartup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the application is first launched, the Quick Tips
                dialog is normally automatically initiated.  That dialog
                contains a Boolean that the user may check to prevent this
                from happening.

CALLED BY:	CwordOpenApplication

PASS:		ds - object block segment

RETURN:		carry set if dialog should not be initiated.

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
                check the init file for the setting
                set the Boolean's state to reflect
                only return with carry set if setting is found and TRUE

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        dhunter 2/3/2000        Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordCheckGetQuickTipsStartup   proc    near
        uses    ax, bx, cx, dx, si, di, bp, ds
        .enter

	mov	bx, handle CWordCategory
	call	MemLock
	mov	cx, ax
	mov	ds, ax
	mov	si, offset CWordCategory
	mov	si, ds:[si]	; ds:si - category ASCIIZ string
	mov	di, offset CWordStartupKey
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string
	mov	bp, InitFileReadFlags <IFCC_INTACT, 1, 0, 0>
	call	InitFileReadBoolean
        call    MemUnlock
	jc	showit          ; default to initiate
        
        tst     ax
        jz      showit          ; setting was FALSE

        ; The user didn't want to see that annoying dialog after all.
	clr	cx
	jmp	short setit

showit:
        mov     cx, SHOW_ON_STARTUP

setit:
        push    cx
        clr     dx
        mov     bx, handle ShowOnStartupGroup
        mov     si, offset ShowOnStartupGroup
        mov     di, mask MF_CALL
        mov     ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
        call    ObjMessage
        pop     cx

        stc
        jcxz    done		; cx is zero if INI setting is TRUE
        clc
done:
        .leave
        ret
CwordCheckGetQuickTipsStartup   endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordCheckSetQuickTipsStartup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the state of that Boolean in the Quick Tips dialog.

CALLED BY:	CwordCloseApplication

PASS:		ds - object block segment

RETURN:         
                nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
                update the init file with the current setting

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        dhunter 2/3/2000        Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordCheckSetQuickTipsStartup   proc    near
        uses    ax, bx, cx, dx, si, di, ds
        .enter

        mov     bx, handle ShowOnStartupGroup
        mov     si, offset ShowOnStartupGroup
        mov     di, mask MF_CALL
        mov     ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
        call    ObjMessage
	
	and	ax, SHOW_ON_STARTUP	; filter out other garbage
	xor	ax, SHOW_ON_STARTUP	; setting should be TRUE if checkbox CLEARED
        push    ax
        
	mov	bx, handle CWordCategory
	call	MemLock
	mov	cx, ax
	mov	ds, ax
	mov	si, offset CWordCategory
	mov	si, ds:[si]	; ds:si - category ASCIIZ string
	mov	di, offset CWordStartupKey
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string
        pop     ax
	call	InitFileWriteBoolean
        call    MemUnlock

        .leave
        ret
CwordCheckSetQuickTipsStartup   endp

if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordDoFloatingKeyboardStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The first time the crossword puzzle launches on a pen system
		we don't want the keyboard up. This is being ill behaved, 
		but we don't want the user to think this is intended as
		a keyboard type game.

CALLED BY:	CwordOpenApplication

PASS:		ds - object block segment

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordDoFloatingKeyboardStuff	proc	near
	uses	ax,cx,dx,bp,bx,di,si

proto	local	ProtocolNumber

	.enter

	;    The routine we need to call is only in 2.1. The protocol
	;    number of that ui is 743.3. Make sure the routine
	;    exists before we call it.
	;	

	segmov	es,ss
	lea	di,proto
	mov	ax,GGIT_GEODE_PROTOCOL
	mov	bx,handle ui
	call	GeodeGetInfo
	cmp	proto.PN_major,743
	jb	done
	cmp	proto.PN_minor,3
	jb	done

	mov	bx, handle ui
	mov	ax, enum UserGetFloatingKbdEnabledStatus
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	tst	ax
	jnz	takeItDown
done:
	.leave
	ret

takeItDown:
	mov	ax,MSG_GEN_APPLICATION_TOGGLE_FLOATING_KEYBOARD	
	call	UserCallApplication
	jmp	done


CwordDoFloatingKeyboardStuff	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordBoardOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of MSG_CWORD_BOARD_OPEN_APPLICATION

RETURN:		
		nothing
	
DESTROYED:	
		bx, si, di, ds

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordBoardOpenApplication	method dynamic CwordBoardClass,
					MSG_CWORD_BOARD_OPEN_APPLICATION
						
	uses	ax,cx,dx,bp
	.enter

	mov	ds:[di].CBI_drawOptions, BOARD_DEFAULT_DRAW_OPTIONS

	call	SysGetPenMode
	mov	ds:[di].CBI_system, ST_PEN
	andnf	ds:[di].CBI_drawOptions, not BOARD_INPUT_DRAW_OPTIONS	
	ornf	ds:[di].CBI_drawOptions, BOARD_PEN_DRAW_OPTIONS
	mov	ds:[di].CBI_highlightStatus, BOARD_PEN_HIGHLIGHT_STATUS
	cmp	ax, TRUE
	je	displayScheme

	mov	ds:[di].CBI_system, ST_KEYBOARD

	andnf	ds:[di].CBI_drawOptions, not BOARD_INPUT_DRAW_OPTIONS	
	ornf	ds:[di].CBI_drawOptions, BOARD_KEYBOARD_DRAW_OPTIONS
	mov	ds:[di].CBI_highlightStatus, BOARD_KEYBOARD_HIGHLIGHT_STATUS

displayScheme:
	BitClr	ds:[di].CBI_drawOptions, DO_COLOR	;assume
	mov	bx, handle ui
	call	GeodeGetUIData			; bx <- UI data
	mov	ax, SPIR_GET_DISPLAY_SCHEME
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable		; ah - DisplayType
	andnf	ah,mask DT_DISP_CLASS
	cmp	ah,DC_COLOR_2
	jb	done
	BitSet	ds:[di].CBI_drawOptions, DO_COLOR

done:
if 0
	; removed by edwdig
	; we want to check tv/not tv. this checks cui/aui
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	notCUI
endif

	; inserted by edwdig... tv check
	push	di
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	test	ah, mask DT_DISP_ASPECT_RATIO
	pop	di
	jz	notCUI

	push	di
	GetResourceHandleNS	ShowNumberOption, bx
	mov	si, offset ShowNumberOption
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	clr	dx
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjMessage
	pop	di

	mov	ds:[di].CBI_hideNumber, mask SHOW_TRIANGLE

notCUI:
	.leave
	ret
CwordBoardOpenApplication		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the current puzzle.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		*ds:si	= CwordProcessClass object
		ds:di	= CwordProcessClass instance data
		ds:bx	= CwordProcessClass object (same as *ds:si)
		es 	= segment of CwordProcessClass
		ax	= message #

RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordCloseApplication	method dynamic CwordProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION
	uses	ax
	.enter

	call	CwordCheckSetQuickTipsStartup

	mov	bx, handle SelectorBox		; single-launchable
	mov	si, offset SelectorBox
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CFB_SAVE
	call	ObjMessage

	clr	cx				; no block handle

	.leave
	ret
CwordCloseApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InstallTokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Install document token and call super class to install
		application token

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of CwordProcessClass

RETURN:		
		nothing
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InstallTokens	method dynamic CwordProcessClass, MSG_GEN_PROCESS_INSTALL_TOKEN
	.enter
	;
	; Call our superclass to install application icon
	;
	mov	di, offset CwordProcessClass
	call	ObjCallSuperNoLock

	mov	ax, ('C') or ('W' shl 8)	; ax:bx:si = token used for
	mov	bx, ('0') or ('0' shl 8)	;	datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	done				; yes, do nothing
	mov	cx, handle DatafileMonikerList	; cx:dx = OD of moniker list
	mov	dx, offset DatafileMonikerList
	clr	bp				; moniker list is in data
						;  resource and so is already
						;  relocated
	call	TokenDefineToken		; add icon to token database
done:

	Destroy ax,cx,dx,bp

	.leave
	ret
InstallTokens		endm

serverAppToken	GeodeToken	<"WMat",16431>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSG_CWORD_PROCESS_LAUNCH_WORD_MATCHER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch Word Matcher application

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of CwordProcessClass

RETURN:		
		nothing
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LaunchWordMatcher	method dynamic CwordProcessClass, MSG_CWORD_PROCESS_LAUNCH_WORD_MATCHER
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Create a launch block to pass to IACPConnect
	;
	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock ; dx = handle to AppLaunchBlock
	;
	; Clear launch flags 
	;
	mov	bx, dx			; bx <- handle of AppLaunchBlock
	call	MemLock			; ax = AppLaunchBlock segment
	mov	es, ax
	mov	es:[ALB_launchFlags], mask ALF_OVERRIDE_MULTIPLE_INSTANCE
	push	bx
	lea	di, es:[ALB_dataFile]
	mov	{byte}es:[di], 0              ; leave the first byte empty
	inc	di
	mov	ax, GGIT_PERM_NAME_AND_EXT
	clr	bx
	call	GeodeGetInfo		; es:di = GeodeToken
	pop	bx
	call	MemUnlock
	;
	; Connect to the desired server
	;
	mov	di, offset cs:[serverAppToken]
	segmov	es, cs, dx			; es:di points to GeodeToken
	mov	ax, mask IACPCF_FIRST_ONLY	; ax <- connect flag
	call	IACPConnect			; bp = IACPConnection
	jc	done
	;
	; Shut down connection
	;
	clr	cx, dx
	call	IACPShutdown

done:
	.leave
	ret
LaunchWordMatcher		endm

browserAppToken	GeodeToken	<"GlbI",16431>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSG_CWORD_PROCESS_LAUNCH_WEB_BROWSER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch Web Browser application with a URL

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of CwordProcessClass

RETURN:		
		nothing
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LaunchWebBrowser	method dynamic CwordProcessClass, MSG_CWORD_PROCESS_LAUNCH_WEB_BROWSER
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Create a launch block to pass to IACPConnect
	;
	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock ; dx = handle to AppLaunchBlock
	;
	; Clear launch flags 
	;
	mov	bx, dx			; bx <- handle of AppLaunchBlock
	call	MemLock			; ax = AppLaunchBlock segment
	mov	es, ax
	mov	es:[ALB_launchFlags], mask ALF_OVERRIDE_MULTIPLE_INSTANCE
	push	bx
	;
	;  allocate a block containing the URL we want to load
	;
	call	AllocateURLBlock	; alloc URL launch block in bp
	cmp	bp, 0
	je	noURL
	lea	di, es:[ALB_extraData]
	mov	es:[di], bp
	;
	;
	lea	di, es:[ALB_dataFile]
	mov	{byte}es:[di], 0              ; leave the first byte empty
	inc	di
	mov	ax, GGIT_PERM_NAME_AND_EXT
	clr	bx
	call	GeodeGetInfo		; es:di = GeodeToken
	pop	bx
	call	MemUnlock
	;
	; Connect to the desired server
	;
	mov	di, offset cs:[browserAppToken]
	segmov	es, cs, dx			; es:di points to GeodeToken
	mov	ax, mask IACPCF_FIRST_ONLY	; ax <- connect flag
	call	IACPConnect			; bp = IACPConnection
	jc	done
	;
	; Shut down connection
	;
	clr	cx, dx
	call	IACPShutdown

done:
	.leave
	ret
noURL:
	pop	bx
	call	MemFree
	jmp	done
LaunchWebBrowser		endm

AllocateURLBlock	proc	near
	uses	ax, bx, cx, dx, si, di, es, ds
	.enter


	mov	bx, handle CWordCategory
	call	MemLock
	mov	cx, ax
	mov	ds, ax
	mov	si, offset CWordCategory
	mov	si, ds:[si]	; ds:si - category ASCIIZ string
	mov	di, offset CWordKey
	mov	dx, ds:[di]	; cx:dx - key ASCIIZ string
	mov	bp, InitFileReadFlags <IFCC_INTACT, 1, 0, 0>
	call	InitFileReadString
	clr	bp
	jc	notFound
	;
	; bx - ini url key string handle, cx - length
	;
	push	bx		; put handle in dx

	mov	ax, size InternetAppBlock
	add	ax, cx
	inc	ax
	push	cx		; save size
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	mov	bx, handle ui
	call	MemAllocSetOwner	; returns handle in bx
	pop	cx			; restore size
	jc	notAllocated		; no memory left
	mov	dx, bx			; dx - data buffer handle
	mov	es, ax
	mov	di, size InternetAppBlock ; es:di target to buffer
	pop	bx
	call	MemLock			; Lock ini url key string handle
	push	bx
	mov	ds, ax
	clr	si			; ds:si source
	rep	movsb	
	mov	{byte}es:[di], 0
	call	MemUnlock		; unlock ini url key string handle
	clr	di
	mov	es:[di].IAB_type, IADT_URL	
	mov	bx, dx
	call	MemUnlock		; unlock the launc app block
	mov	bp, bx
notAllocated:
	pop	bx			; ini key string handle
	call	MemFree
notFound:
	mov	bx, handle CWordCategory
	call	MemUnlock

	.leave
	ret
AllocateURLBlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the Crossword application

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	8/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordExit	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	bx, handle CwordApp
	mov	si, offset CwordApp
	clr	di
	mov	ax, MSG_META_QUIT
	call	ObjMessage

	.leave
	ret
CwordExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will grab to focus and target.  

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		bp	= 0 if top window, else window for object to
			  open on 

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardVisOpen	method dynamic CwordBoardClass, 
					MSG_VIS_OPEN
	.enter

	call	MetaGrabFocusExclLow
	call	MetaGrabTargetExclLow

;	mov	ax, MSG_META_NOTIFY
;	mov	cx, MANUFACTURER_ID_GEOWORKS
;	mov	dx, GAGCNLT_NOTIFY_FOCUS_TEXT_OBJECT

	mov	ax, MSG_VIS_OPEN
	mov	di, offset CwordBoardClass
	call	ObjCallSuperNoLock

EC <	pushf						>	
EC <	Destroy ax, cx, dx, bp				>
EC <	popf						>

	.leave
	ret


BoardVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Releases the focus and target.

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardVisClose	method dynamic CwordBoardClass, 
					MSG_VIS_CLOSE
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	call	MetaReleaseFocusExclLow
	call	MetaReleaseTargetExclLow

	mov	di, offset CwordBoardClass
	call	ObjCallSuperNoLock

EC <	pushf						>	
EC <	Destroy ax, cx, dx, bp				>
EC <	popf						>

	.leave
	ret
BoardVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardInitializeBoard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method is received when the Board is to be
		initialized.

CALLED BY:	MSG_CWORD_BOARD_INITIALIZE_BOARD
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		bp	= stack pointer to BoardInitializeData
			  structure

RETURN:		ax	= InitReturnValue

DESTROYED:	none
SIDE EFFECTS:	

	NOTE:	In the case of an initialization failure, will clean
		up the Board and the two ClueLists.

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardInitializeBoard	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_INITIALIZE_BOARD
	uses	cx, dx, bp
	.enter

; USES BP???

;;; Verify argument(s)
;;;;;;;;

	tst	ds:[di].CBI_engine
	jz	noExistingData

	mov	ax, MSG_CWORD_BOARD_CLEAN_UP
	call	ObjCallInstanceNoLock

noExistingData:
	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	ds:[di].CBI_cellWidth, BOARD_DEFAULT_CELL_SIZE
	mov	ds:[di].CBI_cellHeight, BOARD_DEFAULT_CELL_SIZE
	mov	ax, BOARD_DEFAULT_TEXT_SIZE_NO_NUMBER
	test	ds:[di].CBI_hideNumber, mask SHOW_TRIANGLE
	jnz	gotTextSize
	mov	ax, BOARD_DEFAULT_TEXT_SIZE
gotTextSize:
	mov	ds:[di].CBI_pointSize.WBF_int, ax
	clr	ds:[di].CBI_pointSize.WBF_frac
	mov	ax, ss:[bp].BID_engine
	mov	ds:[di].CBI_engine, ax

	mov	dx, ax				; engine token
	call	EngineGetPuzzleDimensions
	mov	cl,al				;number of rows
	call	BoardSetViewPuzzleData

	mov	ds:[di].CBI_upLeftCoord.P_x, BOARD_DEF_UL_COORD_X
	mov	ds:[di].CBI_upLeftCoord.P_y, BOARD_DEF_UL_COORD_Y
	mov	ax, ss:[bp].BID_cell
	mov	ds:[di].CBI_cell, ax
	mov	ax, ss:[bp].BID_direction
	mov	ds:[di].CBI_direction, ax
	mov	ax, ss:[bp].BID_acrossClue
	mov	ds:[di].CBI_acrossClue, ax
	mov	ax, ss:[bp].BID_downClue
	mov	ds:[di].CBI_downClue, ax
	mov	ds:[di].CBI_verifyMode, VMT_OFF

	call	BoardInitBounds
	call	BoardRedoPrimaryGeometry
	call	CwordEnableDisableClearXSquares
	mov	ax,ss:[bp].BID_cell
	call	BoardEnsureWordsVisible

	; Initialize both clue lists.
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	mov_tr	ax, bp				; ^hGState
	BoardAllocStructOnStack		ClueListInitParams
EC <	ClearBufferForEC	ssbp, ClueListInitParams	>

	mov_tr	ss:[bp].CLIP_gState, ax
	mov	ax, ds:[di].CBI_engine
	mov_tr	ss:[bp].CLIP_engine, ax
	mov	ax, ds:[di].CBI_acrossClue
	mov_tr	ss:[bp].CLIP_acrossClue, ax
	mov	ax, ds:[di].CBI_downClue
	mov_tr	ss:[bp].CLIP_downClue, ax

	;   In pen mode highlight both lists and in keyboard mode
	;   highlight direction list

	clr	dx				;assume highlight both
	cmp	ds:[di].CBI_system,ST_PEN
	je	setListsToHighlight
	mov	dx,ds:[di].CBI_direction
setListsToHighlight:

	mov	ss:[bp].CLIP_listToHighlight,dx
	mov	dx, size ClueListInitParams

	mov	ax, ACROSS
	mov_tr	ss:[bp].CLIP_direction, ax
	mov	bx, handle AcrossClueList		; single-launchable
	mov	si, offset AcrossClueList
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_CLUE_LIST_INITIALIZE_OBJECT
	call	ObjMessage
	cmp	ax, IRV_FAILURE				; error if not clear
	je	err

	mov	ax, DOWN
	mov_tr	ss:[bp].CLIP_direction, ax
	mov	bx, handle DownClueList			; single-launchable
	mov	si, offset DownClueList
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_CLUE_LIST_INITIALIZE_OBJECT
	call	ObjMessage
	cmp	ax, IRV_FAILURE
	je	err

if _SINGLE_CLUE_LIST
	mov	ax, MSG_GEN_SET_NOT_USABLE		; make Down invisible
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP	; update whole group
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
endif ; _SINGLE_CLUE_LIST

	mov	ax,MSG_GEN_SET_ENABLED
	call	BoardVUMNOWMessageTofeaturesUI

	
exit:
	mov	di, ss:[bp].CLIP_gState
	call	GrDestroyState
	BoardDeAllocStructOnStack	ClueListInitParams

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	mov	ax, MSG_CWORD_BOARD_CLEAN_UP
	mov	si, offset Board
	call	ObjCallInstanceNoLock
	mov	ax, IRV_FAILURE
	jmp	exit

BoardInitializeBoard	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardCleanUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the field CBI_engine, and tells the ClueList to
		clean up.

CALLED BY:	MSG_CWORD_BOARD_CLEAN_UP
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardCleanUp	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_CLEAN_UP
	uses	ax,bx,cx,dx,bp,si
	.enter

	; Check if Clean Up is necessary
	;
	cmp 	ds:[di].CBI_engine, 0
	je	finish

	clr	ds:[di].CBI_engine

	call	CwordEnableDisableClearXSquares

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	; Clue Lists
	mov	bx, handle AcrossClueList
        mov     si, offset AcrossClueList
        mov     di, mask MF_CALL or mask MF_FIXUP_DS
        mov     ax, MSG_CWORD_CLUE_LIST_CLEAN_UP
        call    ObjMessage

	mov	bx, handle DownClueList
        mov     si, offset DownClueList
        mov     di, mask MF_CALL or mask MF_FIXUP_DS
        mov     ax, MSG_CWORD_CLUE_LIST_CLEAN_UP
        call    ObjMessage

	clr	cl					;no rows
	call	BoardSetViewPuzzleData

if _SINGLE_CLUE_LIST
	;
	; These messages to the ClueList must be after the
	; BoardSetViewPuzzleDta because they cause a resize to happen.
	; 6/30/95 - ptrinh
	;
	; Default is to have both clue list visible initially.
	;
	mov	bx, handle AcrossClueList
        mov     si, offset AcrossClueList
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, handle DownClueList
        mov     si, offset DownClueList
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
endif

	mov	ax,MSG_GEN_SET_NOT_ENABLED
	call	BoardVUMNOWMessageTofeaturesUI
finish:


	.leave
	ret
BoardCleanUp	endm



if _RESTRICTED_MENUS

featuresUI	optr	\
	VerifyButton,
	CheckWordButton,
	ClearButton,
	FindEmptyButton

else

featuresUI	optr	\
	VerifyButton,
	CheckButton,
	CheckWordButton,
	ClearButton,
	FindEmptyButton,
	SaveButton

endif





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardVUMNOWMessageTofeaturesUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a VUM_NOW message to the optrs in the featuresUI table

CALLED BY:	

PASS:		
		ax - message
		di - message flags
		bp - data for message

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardVUMNOWMessageTofeaturesUI		proc	near
	uses	cx,di,si,bx
	.enter

	clr	cx				;start at first entry

nextOne:
	mov	bx,offset featuresUI
	mov	di,cx
	shl	di				;
	shl	di				;double word table
	mov	si,cs:[bx][di].offset
	mov	bx,cs:[bx][di].handle
	mov	di,mask MF_FIXUP_DS
	mov	dl,VUM_NOW
	call	ObjMessage
	inc	cx
	cmp	cx,length featuresUI
	jl	nextOne

	.leave
	ret
BoardVUMNOWMessageTofeaturesUI		endp





if PEN_POSSIBLE
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordVUMNOWMessageToKeyboardQuickTips
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a VUM_NOW message to the KeyboardQuickTips 
		intercation

CALLED BY:	CwordOpenApplication

PASS:		
		ax - message that requires VUM_NOW parameter in dl
		ds - segment of object a block

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordVUMNOWMessageToKeyboardQuickTips		proc	near
	uses	bx,si,dx
	.enter

	mov	bx, handle KeyboardQuickTips	; single-launchable
	mov	si,offset KeyboardQuickTips
	mov	dl, VUM_NOW
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
CwordVUMNOWMessageToKeyboardQuickTips		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordVUMNOWMessageToPenQuickTips
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a VUM_NOW message to the PenQuickTips 
		intercation

CALLED BY:	CwordOpenApplication

PASS:		
		ax - message that requires VUM_NOW parameter in dl
		ds - segment of object a block

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordVUMNOWMessageToPenQuickTips		proc	near
	uses	bx,si,dx
	.enter

	mov	bx, handle PenQuickTips		; single-launchable
	mov	si,offset PenQuickTips
	mov	dl, VUM_NOW
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
CwordVUMNOWMessageToPenQuickTips		endp
endif   ; PEN_POSSIBLE


CwordFileCode	ends

