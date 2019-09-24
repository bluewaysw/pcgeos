COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus Font Converter
FILE:		ninfnt.asm

MANAGER:	Gene Anderson, Apr 17, 1991
AUTHOR:		John D. Mitchell, Apr 17, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/17/91		Initial revision
	JDM	91.05.06	Big merge.
	JDM	91.05.07	Added handler for list converter.
	JDM	91.05.08	Modified for reworked UI.
	JDM	91.05.13	Optional system shutdown.
	JDM	91.05.13	Conversion status indicator.
	JDM	91.05.15	Fixed list canceling.
	JDM	91.05.20	Fixed weight/style finding.
	JDM	91.06.11	Fixed conversion status re-exposure.

DESCRIPTION:
	This file contains the front end code for the Nimbus Font
	Converter.

	$Id: ninfnt.asm,v 1.1 97/04/04 16:16:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; include files
;
include type.def
include geos.def
include geosmacro.def
include errorcheck.def
include library.def
include localmem.def
include graphics.def
include gstring.def
include win.def
include	geode.def
include object.def
include event.def
include metaClass.def
include processClass.def
include	geodeBuild.def
include thread.def
include timer.def
include timedate.def
include cursor.def
include mouse.def
include vm.def
include localization.def
include system.def
include character.def
include chunkarray.def
include fileEnum.def
include fontEnum.def

ACCESS_FONT = 1
include font.def

UseLib	ui.def

include	coreBlock.def
include	geode.def
include	geodeBuild.def



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include ninfntConstant.def
include ninfntNimbusConstant.def


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Object Class Include Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; fontInstall.def contains all of the generic font installation
; class definitions.
;
include	fontInstall.def



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Class & Method Definitions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; This is the class for this application's process.
;

NimbusFontInstallProcessClass	class	UI_Class

;
; METHOD DEFINITIONS:  these methods are defined for this class.
;
METHOD_NIMBUS_INSTALL_DIRECTORY_SELECTED	method
METHOD_NIMBUS_INSTALL_KILL_APPLICATION		method
METHOD_NIMBUS_INSTALL_NAME_SELECTED		method
METHOD_NIMBUS_INSTALL_CHANGE_TYPEFACE_NAME	method
METHOD_NIMBUS_INSTALL_KILL_LIST			method

;
; This method exists so that the list can inform the application that
; a new font has been selected by the user.
; This is a serious (or is that totally frivolous :-) hack!
; This is necessitated by the fact that the GenList's output OD is
; used for both the reqesting of monikers and it's regular duties.
; Therefore either the application has to have handlers for all of the
; needed list methods (yes most of them would just pawn off to the list)
; or you get this hack.
;
METHOD_APP_INSTALL_LIST_SET_SELECTED_FONT	method

;
; NOTE: This method exists so that the conversion process can run under
;	something besides the UI thread.
;
METHOD_FONT_INSTALL_LIST_CONVERT_FONT		method

;
; NOTE:	These method exists so that the conversion code can let the
;	application know the status of the conversion.
;
METHOD_CONVERSION_STATUS_INIT			method
METHOD_CONVERSION_STATUS_SET_FILE		method
METHOD_CONVERSION_STATUS_SET_CHAR		method


NimbusFontInstallProcessClass	endc

;
; VisRectangle.
;
VisRectangleClass	class	VisClass

;
; METHOD DEFINITIONS:  these methods are defined for this class.
;
METHOD_VIS_RECTANGLE_INC_HORIZ_SIZE	method
METHOD_VIS_RECTANGLE_CLEAR		method

;
; Instance data.
;
	VR_color	word

VisRectangleClass	endc



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			Resources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include		ninfnt.rdef


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Variables & Class Declarations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	ninfntVariable.asm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Include Code Files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	fontInstall.asm
include string.asm
include ninfntTables.asm
include ninfntStrings.asm
include ninfntChar.asm
include ninfntFont.asm
include ninfntFile.asm
include ninfntUtils.asm
include ninfntIDs.asm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Code Resource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Method Handlers for NimbusFontInstallProcessClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NFIOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This method is sent to this application as it is detached
		from the system.

PASS:		DS	= Segment of DGroup (idata, udata, stack, etc)
		ES	= Segment of class definition (is in DGroup)
		BP	= Handle of block on global heap which contains
			  the saved variables.

RETURN:		DS, SI, ES = Same

DESTROYED:	???.

PSEUDO CODE/STRATEGY:
	If there is anything that should be retrieved from the state file:
		Iff there is actually something to be retrieved:
			Save all of the trashed regs.
			Lock the passed in block.
			Copy the stuff verbatim from the buffer into
			our appropriate idata area.
			Unlock the block.
			Restore the trashed stuff.
	Pass on to the superclass.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Save data must contain an even number of bytes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	4/91		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NFIOpenApplication	method	NimbusFontInstallProcessClass,
				METHOD_UI_OPEN_APPLICATION

; Was there anything saved?
IF	(SaveEnd - SaveStart)

	; A handle is passed iff there is something for us to retrive
	tst	bp			;is there a passed handle?
	jz	callSuper		;skip if not...

	; Save the scratched regs.
	DoPush	ax, bx, cx, dx, si, ds

	; Lock the block, so we get its segment.
	mov	bx, bp			;set bx = handle of block
	call	MemLock			;returns ax = segment of block

	; Copy it into our variable area.
	mov	ds, ax			;set ds:si = block on global heap
	clr	si
	mov	di, offset SaveStart	;set es:di = variable area in idata
	mov	cx, (SaveEnd-SaveStart)/2 ;cx = number of words to copy
	rep	movsw			;copy words to idata area

	call	MemUnlock		;unlock the block

	; Restore the scratched regs.
	DoPopRV	ax, bx, cx, dx, si, ds

callSuper:

ENDIF
	; Call superclass (UI_Class for default handling)
	mov	di, offset NimbusFontInstallProcessClass
	GOTO	ObjCallSuperNoLock
NFIOpenApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NFICloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This method is sent to this application as it is removed
		from the system.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.

RETURN:		DS, SI, ES = Same
		CX	= Handle of global block which contains the data
			  to be saved.  Zero if nothing to save.

DESTROYED:	AX, BX, CX, DI, SI, ES.

PSEUDO CODE/STRATEGY:
	Iff there is anything to be saved:
		Allocate a block to pass the saved data in.
		Copy the appropriate stuff from our idata area into
		the allocated buffer.
		Unlock the block.
		Return the block handle.
	Otherwise:
		Return CX == 0 so as to notify the system that there
		ain't anything to be saved.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Save data must contain an even number of bytes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	4/91		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NFICloseApplication	method	NimbusFontInstallProcessClass,
				METHOD_UI_CLOSE_APPLICATION

; Is there anything to save?
IF	(SaveEnd - SaveStart)

	; Allocate a block on the global heap, and lock it.
	mov	ax, SaveEnd-SaveStart	;get size of save area
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc		;returns ax = segment of block

	; Copy our variables into this block.
	mov	es, ax			;set es:di = address of block
	clr	di
	mov	si, offset SaveStart	;set ds:si = address of variables
	mov	cx, (SaveEnd-SaveStart)/2	; cx = size in words
	rep	movsw			;copy words to block

	;unlock the block and return its handle to caller.
	call	MemUnlock
	mov	cx, bx			;return cx = handle

	; Get outta here.
	ret

ENDIF
	; This is only reached if nothing in the save area.
	clr	cx				; Notify the system.

	ret
NFICloseApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NFIQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This method is sent to this application before the
		system is shutdown.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.
		DX	= QuitLevel.
		if DX == QL_AFTER_DETACH then
			SI:CX = ACK OD to be passed on to METHOD_QUIT_ACK.

RETURN:		Void.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	If QuitLevel == QL_BEFORE_UI then
		If there were any fonts converted then
			Inform the user that the fonts just converted
			won't be available until the system is next
			started.
			Ask the user if they want us to re-start the
			system now.
			If yes then
				Set flag to restart system later.
	else if QuitLevel == QL_AFTER_DETACH then
		If restart flag set then
			Force a system restart.
	Pass on to super.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	NOTE:	There is a bug in the documentation for METHOD_QUIT
		concerning the cleared state of CX upon entry.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.11	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NFIQuit	method	NimbusFontInstallProcessClass, METHOD_QUIT
	uses	ax,cx,dx,bp

	.enter

	; Save the goodies.
	DoPush	cx,dx,ds,es,di,si

	; QuitLevel == QL_BEFORE_UI?
	cmp	dx, QL_BEFORE_UI
	jnz	checkAfterDetach		; Nope. Next!

	; Was anything converted?
	mov	di, offset NimbusConvertFlag
	cmp	{byte} ds:[di], FALSE
	jz	exitACK				; Nope.  Bail.

	; Otherwise, inform the user and find out what they want to do.
	mov	ax, offset NimbusFontInstallRestartSystemQueryString
	call	DoConfirmation

	; What's the verdict?
	cmp	ax, SDBR_AFFIRMATIVE		; Restart?
	jnz	exitACK				; Nope.  Bail.

	; Otherwise, set the restart flag for later.
	mov	si, offset NimbusRestartFlag
	mov	{byte} ds:[si], TRUE

	jmp	exitACK				; See ya!

checkAfterDetach:
	; QuitLevel == QL_AFTER_DETACH?
	cmp	dx, QL_AFTER_DETACH
	jnz	exitACK				; Nope.  Bail!

	; Restart flag set?
	mov	di, offset NimbusRestartFlag
	cmp	{byte} ds:[di], FALSE
	jnz	doShutDown			; Yep.

	; Otherwise pass on to super.
	DoPopRV	cx,dx,ds,es,di,si		; Restore the goodies.
	mov	ax, METHOD_QUIT
	mov	di, offset NimbusFontInstallProcessClass
	call	ObjCallSuperNoLock
	jmp	exit

doShutDown:
	mov	ax, SST_RESTART
	call	SysShutdown
	jmp	exit			; XXX: => can't restart. notify
					;  user!

exitACK:
	; Pass on to super.
	DoPopRV	cx,dx,ds,es,di,si		; Restore the goodies.
	mov	ax, METHOD_QUIT
	mov	di, offset NimbusFontInstallProcessClass
	call	ObjCallSuperNoLock

exit:
	.leave
	ret
NFIQuit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NFIDirectorySelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Front end to handle the users selection of a directory
		to scan for font files.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Minimal stack usage.
	Total register usage.

PSEUDO CODE/STRATEGY:
	Make the user's selected directory the current path.
	Allocate a temporary buffer for reading files.
	Initialize the FontInstallList.
	Process each of the files in the directory.
	Free the temporary buffer.
	Set the text of the base (typeface) name editor to the first
	list entry.
	If any valid files found then initiate the selection process.
	Otherwise restart the directory selection process.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Seems kinda long.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.09	Initial version
	JDM	91.05.03	Reworked for FontInfoEntry.
	JDM	91.05.15	Added name editor updating.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NFIDirectorySelected	method	NimbusFontInstallProcessClass,
				METHOD_NIMBUS_INSTALL_DIRECTORY_SELECTED
	uses	ax,cx,dx,bp

	.enter

	; Save any important registers.
	DoPush	ds, es

	; Save DGroup access.
	push	ds

	; Get the user's directory selection from the FileSelector.
	; CX:DX is where to copy the chosen path.
	; BP will end up with the disk handle to the given selection.
	mov	cx, ds				; CX:DX = global temp.
	mov	dx, offset NimbusSelectedPath	; Selection buffer.
	mov	ax, METHOD_FILE_SELECTOR_GET_PATH	; Message to send.
	mov	bx, handle NimbusFontInstallFileSelector	; Object.
	mov	si, offset NimbusFontInstallFileSelector
	mov	di, mask MF_CALL		; Does it matter???
	call	ObjMessage

	; Save the disk handle of the selected path.
	pop	ds				; Restore DGroup access.
	mov	ds:[NimbusSelectedPathHandle], bp

	; Set the current directory to the the selected directory.
	DoPush	ds, es
	mov	bx, ds:[NimbusSelectedPathHandle]	; Directory handle.
	mov	dx, offset NimbusSelectedPath	; DS:DX = Path.
	call	FileSetCurrentPath
	DoPopRV	ds, es
	jnc	directorySetOk			; No error, so continue.

	; Otherwise, Notify user and bail!
	mov	ax, offset NimbusFontInstallSetDirectoryFailedString
	call	DoNotification

killApplication:
	; Abort the program by sending ourself a KILL_APPLICATION message.
	mov	ax, METHOD_NIMBUS_INSTALL_KILL_APPLICATION
	mov	bx, handle 0			; Handle to the object.
	mov	di, mask MF_CALL		; Does it matter???
	clr	dx
	call	ObjMessage
	jmp	exit				; Shouldn't occur!

directorySetOk:
	; Allocate a tag buffer for the FileScanner routine.
	mov	ax, NIMBUS_TAG_BLOCK_SIZE	; Size to allocate.
	mov	cx, ALLOC_DYNAMIC_LOCK		; Swapable, movable.
	call	MemAlloc
	jnc	allocOk				; No error, so continue.

allocFailed:
	; Otherwise, allocation failed.
	; Notify user.
	mov	ax, offset NimbusFontInstallAllocFailedString
	call	DoNotification
	jmp	killApplication			; Kill the application.

allocOk:
	; Save the block handle.
	mov	ds:[NimbusTagBlockHandle], bx

	; Initialize the font install list.
	mov	ax, METHOD_FONT_INSTALL_LIST_INIT	; Message to send.
	mov	bx, handle NFINS_NamesList	; Handle to object.
	mov	si, offset NFINS_NamesList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	; Do it now!
	call	ObjMessage
	jc	allocFailed			; Died! Tell user.

	; Set up the stack for the FileEnumParams.
	sub	sp, size FileEnumParams
	mov	bp, sp

	; Search for everything.
	mov	ss:[bp].FEP_fileTypes,	mask FEFT_FILES or \
					mask FEFT_NON_GEOS
	mov	ss:[bp].FEP_searchFlags, mask FESF_CALLBACK
	clr	ax
	mov	ss:[bp].FEP_returnFlags, al
	mov	ss:[bp].FEP_skipCount, ax
	mov	ss:[bp].FEP_bufSize, ax
	mov	ax, cs
	mov	ss:[bp].FEP_callback.high, ax
	mov	ss:[bp].FEP_callback.low, offset NimbusFileScanner
	call	FileEnum

	; Free the allocated block.
	mov	ax, dx				; Save the file count.
	mov	bx, ds:[NimbusTagBlockHandle]
	call	MemFree

	; Were any font files found?
	tst	ax
	jnz	goGetFonts			; Yep.

	; Notify the user of the vacuous font file list.
	mov	ax, offset NimbusFontInstallNoFontFilesFoundString
	call	DoNotification
	jmp	exit

goGetFonts:
	; Set the initial text of the base (typeface) name editor.
	clr	cx
	mov	ax, METHOD_APP_INSTALL_LIST_SET_SELECTED_FONT
	mov	bx, handle 0
	mov	di, mask MF_CALL
	call	ObjMessage

	; Set the Font Install List in action (delayed until we exit).
	mov	ax, METHOD_GEN_INITIATE_INTERACTION
	mov	bx, handle NimbusFontInstallNamesSummons
	mov	si, offset NimbusFontInstallNamesSummons
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

exit:
	; Restore the important registers.
	DoPopRV	ds, es

	.leave
	ret
NFIDirectorySelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NFIKillApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	User decided to forget the whole damn thing.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.

RETURN:		Void.

DESTROYED:	AX, BX, DX, SI, DI.

REGISTER/STACK USAGE:
	AX, BX, DX, SI, DI.

PSEUDO CODE/STRATEGY:
	Kill the application by sending a QUIT message to the application
	object.  In other words this thing nukes the application!

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	What could possibly be wrong with this?!?  :-)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.09	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NFIKillApplication	method	NimbusFontInstallProcessClass,
				METHOD_NIMBUS_INSTALL_KILL_APPLICATION

	; Send the application object a METHOD_QUIT.
	mov	ax, METHOD_QUIT			; Message to send.
	mov	bx, handle NimbusFontInstallApp	; Handle to the object.
	mov	si, offset NimbusFontInstallApp
	mov	di, mask MF_CALL		; Does it matter???
	clr	dx
	call	ObjMessage

	ret
NFIKillApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NFIFontSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Convert the all the files associated with the user's
		base (typeface) name list selection.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Dynamic method register file saving.
	AX, BX, SI, DI.

PSEUDO CODE/STRATEGY:
	Let the user know what's happening.
	Make the list do all of the conversion work.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	The conversion status must be dismissed by somebody else.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.06	Initial version
	JDM	91.05.09	Added user notification.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NFIFontSelected	method	dynamic	NimbusFontInstallProcessClass,
				METHOD_NIMBUS_INSTALL_NAME_SELECTED
	uses	ax,cx,dx,bp

	.enter

	; Initiate the user conversion progress notification.
	mov	ax, METHOD_GEN_INITIATE_INTERACTION
	mov	bx, handle NimbusFontInstallConversionStatus
	mov	si, offset NimbusFontInstallConversionStatus
	mov	di, mask MF_CALL
	call	ObjMessage

	; Tell the list to go convert the currently selected typeface.
	mov	ax, METHOD_FONT_INSTALL_LIST_CONVERT_SELECTED_FONT
	mov	bx, handle NFINS_NamesList
	mov	si, offset NFINS_NamesList
	mov	di, mask MF_CALL		; Do it now.  We'll wait.
	call	ObjMessage

	.leave
	ret
NFIFontSelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NFISetSelectedFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the font base (typeface) name editing field to
		reflect a change of the given list entry.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.
		CX	= List entry selected.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Dynamic method register file saving.
	AX, BX, SI, DI.

PSEUDO CODE/STRATEGY:
	Allocate a temporary block to hold the font name string.
	Get the font name of the given list entry from the list.
	Set the text of the name editing field to the new font name.
	Free the temporary buffer.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Having the list have to send this method out is a by product of
	the insanity of the dynamic GenList world.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.08	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NFISetSelectedFont	method	dynamic	NimbusFontInstallProcessClass,
				METHOD_APP_INSTALL_LIST_SET_SELECTED_FONT
	uses	ax,cx,dx,bp

	.enter

	; Save the list entry's index.
	push	cx

	; Make a buffer to hold the font name string.
	mov	ax, MAX_FONT_NAME_LENGTH
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc			; AX = locked segment.

	; Get the base (typeface) name of the given entry.
	mov	cx, ax				; CX:DX = buffer.
	clr	dx
	pop	bp				; Restore entry index.
	push	bx				; Save block handle.
	mov	ax, METHOD_FONT_INSTALL_LIST_GET_FONT_NAME
	mov	bx, handle NFINS_NamesList
	mov	si, offset NFINS_NamesList
	mov	di, mask MF_CALL		; Do it now.  We'll wait.
	call	ObjMessage

	; Set the text of the the base (typeface) name editing field.
	; NOTE:	CX:DX = string from above.
	mov	bp, dx				; DX:BP = name string.
	mov	dx, cx
	clr	cx				; Null-terminated.
	mov	ax, METHOD_SET_TEXT
	mov	bx, handle NFINS_NameEdit
	mov	si, offset NFINS_NameEdit
	mov	di, mask MF_CALL		; We'll wait.
	call	ObjMessage

	; Get rid of the temporary font name block.
	pop	bx				; Restore block handle.
	call	MemFree

	.leave
	ret
NFISetSelectedFont	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NFITextDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	METHOD_TEXT_MADE_DIRTY

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of NimbusFontInstallProcessClass
		ax - the method
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NFITextDirty	method dynamic NimbusFontInstallProcessClass, \
						METHOD_TEXT_MADE_DIRTY
	call	GeodeGetProcessHandle
	mov	ax, METHOD_NIMBUS_INSTALL_CHANGE_TYPEFACE_NAME
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bx, handle NFINS_NameEdit
	mov	si, offset NFINS_NameEdit	;^lbx:si <- OD of text object
	mov	ax, METHOD_SET_CLEAN
	mov	di, mask MF_CALL
	call	ObjMessage			;clean me jesus
	ret
NFITextDirty	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NFIChangeTypefaceName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle the user changing the base (typeface) name for
		the currently selected font.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file saving.

PSEUDO CODE/STRATEGY:
	Get the users string for the font's base (typeface) name.
	(This will allocate a block and copy the string into it for
	us.)
	Update the list's idea of what the name is.
	Free the allocated name string block.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.08	Initial version
	JDM	91.05.14	Added null-string abortion/notification.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

doofusString	char "?",0

NFIChangeTypefaceName	method	dynamic	NimbusFontInstallProcessClass,
				METHOD_NIMBUS_INSTALL_CHANGE_TYPEFACE_NAME
	uses	ax,cx,dx,bp

	.enter

	; Get the user's idea of what the currently selected font's
	; base (typeface) name should be.
	clr	cx
	mov	ax, METHOD_GET_TEXT
	mov	bx, handle NFINS_NameEdit
	mov	si, offset NFINS_NameEdit
	mov	di, mask MF_CALL
	call	ObjMessage

	; Check for a null-string.
	tst	cx
	jnz	lockBlock			; Nope.  Continue.

	mov	cx, cs
	mov	dx, offset doofusString		;cx:dx <- ptr to string
	mov	bp, length doofusString		;bp <- length of string
	call	UpdateList
	jmp	exit

lockBlock:
	; Lock the name block.
	push	ax				; Save block handle.
	mov	bx, ax
	call	MemLock

	mov	bp, cx				; Length of string.
	inc	bp				; Include terminator.
	mov	cx, ax				; CX:DX = name string.
	clr	dx
	call	UpdateList

	; Get rid of the temporary name buffer.
	pop	bx				; Restore block handle.
	call	MemFree

exit:
	.leave
	ret
NFIChangeTypefaceName	endm

UpdateList	proc	near
	; Tell the list to update itself.
	; cx:dx - ptr to name
	; bp - length of name (including NULL)
	;
	mov	ax, METHOD_FONT_INSTALL_LIST_SET_SELECTED_FONT_NAME
	mov	bx, handle NFINS_NamesList
	mov	si, offset NFINS_NamesList
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
UpdateList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NFIKillList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Bring down the Font Names List and associated text
		edit.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file saving.

PSEUDO CODE/STRATEGY:
	Clear out the base (typeface) name editor.
	Have the list clear itself out.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This is hooked from a Cancel trigger that is set to complete
	the interaction, therefore the entire interaction that contains
	the trigger will be brought down before this is called.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.15	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NFIKillList	method	dynamic	NimbusFontInstallProcessClass,
				METHOD_NIMBUS_INSTALL_KILL_LIST
	uses	ax,cx,dx,bp

	.enter

	; Tell the list to clear itself out (sounds pretty kinky to me!).
	mov	ax, METHOD_FONT_INSTALL_LIST_KILL
	mov	bx, handle NFINS_NamesList
	mov	si, offset NFINS_NamesList
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
NFIKillList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertThreadCatcher
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run the conversion routine under something other than
		the UI's thread.

CALLED BY:	FontInstallListCovertSelectedFont.

PASS:		CX = Handle of global FontThreadInfoEntry.

RETURN:		Void.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Lock the passed in FontThreadInfoEntry block.
	Lock the data block.
	Get access to the FontConvertEntry that corresponds to the
	currently selected list item.
	Go convert it.
	Unlock the data block.
	Free the passed global data block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The block with the given FontThreadInfoEntry will be freed!
	This exists under the applications thread so that the long and
	involved conversion is not run under the UI thread.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.06	Initial version
	JDM	91.05.09	Added user status notification.
	JDM	91.05.10	Added user abort handling.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertThreadCatcher	method	dynamic	NimbusFontInstallProcessClass,
				METHOD_FONT_INSTALL_LIST_CONVERT_FONT
	uses	ax,cx,dx,bp

	.enter

	; Lock the passed in FontThreadInfoEntry block.
	push	cx				; Save block access.
	mov	bx, cx
	call	MemLock
	
	; Lock the global FontInstallList data block.
	mov	ds, ax				; AX from above.
	mov	si, offset FTIE_infoBlock
	mov	bx, ds:[si]
	push	bx				; Save data block access.
	call	MemLock
	jc	exit				; Ah!!

	; Get access to the selected list entry's corresponding
	; FontConvertEntry out of the ChunkArray.
	push	ax				; Save block access.
	mov	si, offset FTIE_currItem	; AX = current item.
	mov	ax, ds:[si]
	mov	si, offset FTIE_arrayHandle	; *DS:SI = chunk array.
	mov	si, ds:[si]
	pop	ds
	call	ChunkArrayElementToPtr		; DS:DI = Element.

	; Go convert the damn thing.
	mov	si, di				; DS:SI = FontConvertEntry.
	call	ConvertNimbusFont

	; Save for later status checking.
	pushf

	; Kill the user conversion progress notification.
	mov	ax, METHOD_GEN_DISMISS_INTERACTION
	mov	bx, handle NimbusFontInstallConversionStatus
	mov	si, offset NimbusFontInstallConversionStatus
	mov	di, mask MF_CALL
	call	ObjMessage

	; Check the status of the conversion.
	popf					; Restore carry flag.
	jc	skipFinishMessage		; Conversion error!

	; Tell the user that we're done.
	mov	ax, offset NimbusFontInstallConversionCompleteString
	call	DoNotification

	; Set the global 'we have converted something' flag.
	segmov	ds, idata, ax
	mov	si, offset NimbusConvertFlag
	mov	{byte} ds:[si], TRUE

skipFinishMessage:
	; Unlock the global data block.
	pop	bx				; Restore data block.
	call	MemUnlock

	; Get rid of the passed FontThreadInfoEntry block.
	pop	bx
	call	MemFree

exit:
	.leave
	ret
ConvertThreadCatcher	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConversionStatusInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize the conversion status indicator.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file.
	AX, BX, CX, DX, SI.

PSEUDO CODE/STRATEGY:
	Initialize the view's text moniker to the first file.
	Tell the VisRectangle to increment itself to the next size.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	The actual rectangle initialization is handled automatically.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.14	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConversionStatusInit	method	dynamic	NimbusFontInstallProcessClass,
				METHOD_CONVERSION_STATUS_INIT
	uses	ax,cx,dx,bp

	.enter

	; Set the text moniker to the first one.
	mov	cx, offset FileOneMoniker
	mov	dl, VUM_NOW
	mov	ax, METHOD_GEN_SET_VIS_MONIKER
	mov	bx, handle NFICS_StatusView
	mov	si, offset NFICS_StatusView
	mov	di, mask MF_CALL
	call	ObjMessage

	; Tell the VisRectangle to increment itself.
	mov	ax, METHOD_VIS_RECTANGLE_INC_HORIZ_SIZE
	mov	bx, handle NFISC_StatusRectangle
	mov	si, offset NFISC_StatusRectangle
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
ConversionStatusInit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConversionStatusSetFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the conversion status indicator.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.
		CX	= File number that is being processed.
			  (Zero based).

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file.
	AX, BX, CX, DX, SI.

PSEUDO CODE/STRATEGY:
	Set the view's text moniker based on the file count.
	Tell the VisRectangle to clear itself and current drawing area.
	Tell the VisRectangle to increment itself to the next size.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Any file count passed that is bigger than four (4) just shows
	up with the FileFourMoniker.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.13	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConversionStatusSetFile	method	dynamic	NimbusFontInstallProcessClass,
				METHOD_CONVERSION_STATUS_SET_FILE
	uses	ax,cx,dx,bp

	.enter

	; Set the text moniker.
	; First figure out which moniker to use.
	tst	cx				; File 1?
	jnz	checkFileTwo			; Nope.  Next!

	; Otherwise, use FileOne moniker.
	mov	cx, offset FileOneMoniker
	jmp	setMoniker

checkFileTwo:
	cmp	cx, 1				; File 2?
	jnz	checkFileThree			; Nope. Next!

	; Otherwise, use FileTwo moniker.
	mov	cx, offset FileTwoMoniker
	jmp	setMoniker

checkFileThree:
	cmp	cx, 2				; File 3?
	jnz	assumeFileFour			; Nope. Next!

	; Otherwise, use FileThree moniker.
	mov	cx, offset FileThreeMoniker
	jmp	setMoniker

assumeFileFour:
	; Otherwise, use FileFour moniker.
	mov	cx, offset FileFourMoniker

	; Fall though.
setMoniker:
	; NOTE:	CX already set.
	mov	dl, VUM_NOW			; Update it now!
	mov	ax, METHOD_GEN_SET_VIS_MONIKER
	mov	bx, handle NFICS_StatusView
	mov	si, offset NFICS_StatusView
	mov	di, mask MF_CALL
	call	ObjMessage

	; Tell the VisRectangle to clear out it's current size.
	mov	ax, METHOD_VIS_RECTANGLE_CLEAR
	mov	bx, handle NFISC_StatusRectangle
	mov	si, offset NFISC_StatusRectangle
	mov	di, mask MF_CALL
	call	ObjMessage

	; Tell the VisRectangle to increment itself.
	mov	ax, METHOD_VIS_RECTANGLE_INC_HORIZ_SIZE
	mov	bx, handle NFISC_StatusRectangle
	mov	si, offset NFISC_StatusRectangle
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
ConversionStatusSetFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConversionStatusNewChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the conversion status indicator.

PASS:		DS	= Segment of DGroup.
		ES	= Segment of Class definition.
		CX	= Index (number) of character about to be
			  processed.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file.
	AX, BX, CX, DX, SI.

PSEUDO CODE/STRATEGY:
	Tell the VisRectangle to increment itself to the next size.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Looks pretty simple to me.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.14	Initial version
	JDM	91.06.11	Fixed for UI based rectangle.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConversionStatusNewChar	method	dynamic	NimbusFontInstallProcessClass,
				METHOD_CONVERSION_STATUS_SET_CHAR
	uses	ax,cx,dx,bp

	.enter

	; Tell the VisRectangle to increment itself.
	mov	ax, METHOD_VIS_RECTANGLE_INC_HORIZ_SIZE
	mov	bx, handle NFISC_StatusRectangle
	mov	si, offset NFISC_StatusRectangle
	clr	di
	call	ObjMessage

	.leave
	ret
ConversionStatusNewChar	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Utility Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusFileScanner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the given file for Nimbus font file tag bytes.

CALLED BY:	FileEnum (callback)

PASS:		ES:DI = DosFileInfoStruct for current file.
		SS:BP = FileEnumParams struct. (Not used.)

RETURN:		Carry Flag:
			Cleared iff valid font file.
			Set otherwise.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Open the given file.
	If unable to open the file then
		Notify the user and see if they want to continue.
		If yes then skip this file and continue enumerating.
		Otherwise kill the application.
	Otherwise
		Lock the temporary buffer.
		Read in a buffer's worth of data from the file.
		Check to see if it's a valid Nimbus font file.
		If valid font file then
			Go install the appropriate information into the
			FontInstallList.
		Unlock the block.
		Close the file.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.09	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusFileScanner	proc	far	uses ax,bx,cx,dx,si,di,bp,ds,es

	; Local variables.
	DosFileInfoStructPtr	local	fptr.DosFileInfoStruct

	.enter

	; Save the arguments into the local.
	mov	ss:[DosFileInfoStructPtr].segment, es
	mov	ss:[DosFileInfoStructPtr].offset, di

	; Open the file.
	segmov	ds, es				; ES:DI.DFIS_name
	mov	dx, di
	add	dx, offset DFIS_name
	mov	ax, FileAccessFlags <FE_NONE, FA_READ_ONLY>
	call	FileOpen			; AX := handle|error code.
	jnc	openOk				; Successful.

	; Otherwise, notify the user that we couldn't do anything.
	mov	cx, es				; CX:DX = file name.
	mov	dx, di
	add	dx, offset DFIS_name
	mov	ax, offset NimbusFontInstallFileIgnoringString
	call	DoWarning
	jmp	exitBad				; Get outta here!

openOk:
	; Lock the tag block.
	push	ax				; Save file handle.
	push	ax				; Save file handle twice!
	mov	ax, segment dgroup		; Make DGroup accessible.
	mov	ds, ax
	mov	bx, ds:[NimbusTagBlockHandle]	; Block to lock.
	call	MemLock

	; Read a block from the file.
	mov	ds, ax				; DS:DX = Tag block buffer.
	pop	bx				; Restore file handle.
	clr	ax				; Accept errors.
	mov	dx, ax
	mov	cx, NIMBUS_TAG_BLOCK_SIZE	; Size of buffer.
	call	FileRead			; Blow off the errors. :-)

	; Check to see if it's a Nimbus Font file.
	mov	si, dx				; DS:SI = Tag block buffer.
	call	NimbusCheckFontTag
	jc	exitUnlockTagBlock		; No tag, so skip file.

	; Otherwise, go install the file into the font selection
	; list chunk arrary.
	; Note:  DS:SI and AX already set from above.
	les	di, ss:[DosFileInfoStructPtr]	
	add	di, offset DFIS_name		; ES:DI = file name.
	call	NimbusInstallFontNameList

	; Tell FileEnum to accept this file.
	clc

	; Fall through.

exitUnlockTagBlock:
	; Restore file handle.
	pop	cx

	; Preserve the carry flag.
	pushf

	; Unlock the tag block.
	mov	ax, segment dgroup		; Make DGroup accessible.
	mov	ds, ax
	mov	bx, ds:[NimbusTagBlockHandle]	; Block to lock.
	call	MemUnlock

	; Close the file.
	mov	al, FILE_NO_ERRORS		; hooey it.
	mov	bx, cx				; File handle from above.
	call	FileClose 

	; Restore the carry flag.
	popf
	jmp	exit

exitBad:
	; Tell FileEnum to disregard this file.
	stc

exit:
	.leave
	ret
NimbusFileScanner	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusInstallFontNameList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserts the appropriate information from the tag block
		into the font name selection list.

CALLED BY:	NimbusFileScanner

PASS:		ES:DI	= Font file name string.
		DS:SI	= Locked tag block buffer.

RETURN:		Void.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Create a FontInfoEntry on the stack.
	Initialize it with the appropriate information.
	Send it to the FontInstallList.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The locked tag buffer block is assumed to be able to handle
	added offsets of a few hundred without problem.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.15	Initial version
	JDM	91.05.01	Reworked for FontInfoEntry.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusInstallFontNameList	proc	uses	ax,bx,cx,dx,ds,si,es,di

	; Local variables.
	FIEntry	local	FontInfoEntry

	.enter

	; Initialize the FontInfoEntry.
	; FontInfo.FIE_font = full font name string field.
	; FontInfo.FIE_file = DOS (8.3) file name string.
	; FontInfo.FIE_weight = font weight string field.
	mov	ax, offset DTCFH_fullname
	add	ax, si				; DS:AX = font name.
	mov	ss:[FIEntry].FIE_font.segment, ds	
	mov	ss:[FIEntry].FIE_font.offset, ax
	mov	ax, offset DTCFH_weight
	add	ax, si				; DS:AX = font weight.
	mov	ss:[FIEntry].FIE_weight.segment, ds
	mov	ss:[FIEntry].FIE_weight.offset, ax
	mov	ss:[FIEntry].FIE_file.segment, es
	mov	ss:[FIEntry].FIE_file.offset, di

	; Have the FontInstallList object install the given font.
	push	bp				; Save stack access.
	mov	cx, ss				; CX:DX = SS:FIEntry
	lea	dx, FIEntry
	mov	ax, METHOD_FONT_INSTALL_LIST_PUT_ENTRY
	mov	bx, handle NFINS_NamesList
	mov	si, offset NFINS_NamesList
	mov	di, mask MF_CALL		; Do it now.
	call	ObjMessage
	pop	bp				; Restore stack access.
	jnc	exit				; Everything copacetic.

	; Otherwise, notify the user of our failure.
	mov	ax, offset NimbusFontInstallNameInsertFailedString
	call	DoNotification

exit:
	.leave
	ret
NimbusInstallFontNameList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusCheckFontTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a Nimbus font tag at the given location.

CALLED BY:	NimbusFileScanner

PASS:		DS:SI = Pointer to location to check for the font
			file flag.

RETURN:		Carry Flag:
			Clear iff tag found.
				AX = One of:
					NIMBUS_VERSION_2X
					NIMBUS_VERSION_3X
			Set otherwise.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Make the file tag variables accessible.
	Compare the first double word in the file against the Nimbus
	version 2.X font file tag.  If == then return the appropriate
	tag and clear carry.
	Otherwise, compare the first double word in the file against the
	Nimbus version 2.X font file tag.  If == then return the
	appropriate tag and clear carry.
	Otherwise, not a known Nimbus font file so return carry set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Relys on global variables initilized to the appropriate
	Nimbus font file tags.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.11	Initial version.
	JDM	91.04.19	Added ZSoft conversion support.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusCheckFontTag	proc	uses	ax,es,di
	.enter

	; Make the internal file tags accessible.
	mov	ax, segment dgroup
	mov	es, ax

	; Check for the Nimbus v2.x file header tag.
	mov	di, offset NimbusVersionTag2X	; Find the 2X tag.
	mov	ax, es:[di]
	cmp	ds:[si], ax
	jnz	checkVersion3X			; Nope. Try 3.X.
	mov	ax, es:[di+2]
	cmp	ds:[si+2], ax
	jz	isVersion2			; Found it!

	; Otherwise, FALL THROUGH!
checkVersion3X:
	; Check for the Nimbus v3.x file header tag.
	mov	di, offset NimbusVersionTag3X	; Find the 3X tag.
	mov	ax, es:[di]
	cmp	ds:[si], ax
	jnz	checkZSoft			; Nope.
	mov	ax, es:[di+2]
	cmp	ds:[si+2], ax
	jz	isVersion3			; Found it!

	; Otherwise, FALL THROUGH!
checkZSoft:
	; Check for the ZSoft converted Nimbus file header tag.
	mov	di, offset NimbusVersionTagZSoft	; ZSoft?
	mov	ax, es:[di]
	cmp	ds:[si], ax
	jnz	noMatch				; Nope.
	mov	ax, es:[di+2]
	cmp	ds:[si+2], ax
	jz	isVersionZSoft			; Found it!

	; Otherwise no match!
noMatch:
	; Nothing valid.
	stc
	jmp	exit

isVersion2:
	; We've found the version 2.x flag.
	mov	ax, NIMBUS_VERSION_2X
	jmp	exitOk

isVersion3:
	; We've found the version 3.x flag.
	mov	ax, NIMBUS_VERSION_3X
	jmp	exitOk

isVersionZSoft:
	; We've found the version ZSoft flag.
	mov	ax, NIMBUS_VERSION_ZSOFT

	; Fall through.
exitOk:
	; Everything copacetic.
	clc

exit:
	.leave
	ret
NimbusCheckFontTag	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfirmUserLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level interface routine to UserStandardDialog.

CALLED BY:	ConfirmUser*

PASS:		CX:DX = Argument string to display.  (NULL if none.)
		BP = Chunk handle of StringsUI message to use.

RETURN:		Carry:
			Set iff NO selected.
			Clear if YES selected.

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Display a dialog box prompting the user with the given message
	from the StringsUI resource and the given argument string.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If the chunk ain't in the StringsUI resource you get hosed!
	This code should be merged (if possible) with DisplayUserBox.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.04.09	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfirmUserLow	proc	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; Get and Lock the StringsUI resource (It contains the
	; error message strings.
	mov	bx, handle StringsUI
	push	bx				; Save it for later.
	call	GeodeLockResource

	; Point DI:BP to the actual error string.
	mov	di, ax				; Segment from previous.
	push	es
	mov	es, ax
	mov	bp, es:[bp]			; BP passed in.
	pop	es

	; Display a question dialog using the given string.
	mov	al, SDBT_CUSTOM
	mov	ah, CustomDialogBoxFlags <TRUE, CDT_QUESTION, SRS_YES_NO>
	call	UserStandardDialog

	; Figure out what the user decided.
	; NOTE:  Carry cleared by cmp if equal.
	cmp	ax, SDBR_AFFIRMATIVE		; YES?
	jz	exit				; Yep.

	; Otherwise, return with an error.
	stc

exit:
	; Free the StringsUI block.
	pop	bx
	call	MemUnlock

	.leave
	ret
ConfirmUserLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoWarning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the user of something by displaying a dialog box.

CALLED BY:	Global.

PASS:		AX = Chunk handle of the string to display

RETURN:		AX = Value from UserStandardDialog

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Set up BH with appropriate code for the call to DisplayUserBox.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:	The chunk specified in AX must be in the StringsUI
		resource.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoWarning	proc	far	uses	bx
	.enter

	; Set up and call DisplayUserBox.
	mov	bh, CustomDialogBoxFlags \
			<FALSE, CDT_WARNING, SRS_ACKNOWLEDGE>
	call	DisplayUserBox

	.leave
	ret
DoWarning	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the user of something by displaying a dialog box.

CALLED BY:	Global.

PASS:		AX = Chunk handle of the string to display

RETURN:		AX = Value from UserStandardDialog

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Set up BH with appropriate code for the call to DisplayUserBox.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:	The chunk specified in AX must be in the StringsUI
		resource.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoNotification	proc	far	uses	bx
	.enter

	; Set up and call DisplayUserBox.
	mov	bh, CustomDialogBoxFlags \
			<FALSE, CDT_NOTIFICATION, SRS_ACKNOWLEDGE>
	call	DisplayUserBox

	.leave
	ret
DoNotification	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a confirmation from the user after displaying a
		dialog box.

CALLED BY:	Global.

PASS:		AX = Chunk handle of the string to display

RETURN:		Ax = Value from UserStandardDialog

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Set up BH with appropriate code for the call to DisplayUserBox.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:	The chunk specified in AX must be in the StringsUI
		resource.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoConfirmation	proc	far	uses	bx
	.enter

	; Set up and call the actual display routine.
	mov	bh, CustomDialogBoxFlags <FALSE, CDT_QUESTION, SRS_YES_NO>
	call	DisplayUserBox

	.leave
	ret
DoConfirmation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayUserBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display a dialog box with the given attributes.

CALLED BY:	DoConfirmation, DoNotification

PASS:		AX = Chunk handle of the string to display
		Bh = CustomDialogBoxFlag for use with UserStandardDialog

RETURN:		Ax = Value from UserStandardDialog

DESTROYED:	Nada.

PSEUDO CODE/STRATEGY:
	Get the handle of the StringsUI resource and Lock it.
	Build a pointer to the requested string.
	Use the custom dialog box flags passed in.
	Display the appropriate dialog box.
	Unlock the resource block.
	Return the status code given by UserStandardDialogBox.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:	The chunk specified in AX must be in the StringsUI
		resource.
	This code should be merged (if possible) with ConfirmUserLow.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayUserBox	proc	near	uses	bx,cx,dx,si,di,bp,es
	.enter

	; Save the UserDialogFlags and chunk of the display string
	mov	si, bx
	mov	bp, ax

	; Lock the resource containing the UI message strings
	; Get resource handle into bx for call to Lock.
	GetResourceHandleNS	StringsUI, bx
	call	GeodeLockResource

	; Display a dialog box
	; Ax == segment of resource (from previous).
	; Point di:bp to our custom error string
	; Must indirect through the passed chunk to get actuall address
	mov	di, ax
	mov	es, ax
	mov	bp, es:[bp]

;	clr	cx
;	mov	dx, cx

	; Restore the CustomDialogBoxFlags into AX
	; Make al signify a custom set of flags
	; AX is returned with one of: SDBR_:	NULL, AFFIRMATIVE,
	;					NEGATIVE, CANCEL.
	mov	ax, si				; Load dialogs flags.
	mov	al, SDBT_CUSTOM
	call	UserStandardDialog

	; Unlock the StringsUI resource (locked by GeodeLockResource above).
	; NOTE: BX supposedly still contains resource handle
	call	MemUnlock

	.leave
	ret
DisplayUserBox	endp


CommonCode	ends




RectangleCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VRInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize the rectangle bounds to nothing.

PASS:		*DS:SI = VisRectangleClass object.
		DS:DI = Instance data.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file.

PSEUDO CODE/STRATEGY:
	Let the super do it's thing.
	Set the rectangle bounds to nothing.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Probably saving too much.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.14	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VRInit	method	VisRectangleClass, METHOD_VIS_OPEN
	uses	ax,cx,dx,bp

	.enter

	; Let the super do it's thang.
	mov	di, offset	VisRectangleClass
	call	ObjCallSuperNoLock
	
	; Initialize our rectangle size.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ds:[di].VI_bounds.R_top
	clr	ds:[di].VI_bounds.R_left
	clr	ds:[di].VI_bounds.R_bottom
	clr	ds:[di].VI_bounds.R_right

	.leave
	ret
VRInit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VRDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw the rectangle.

PASS:		*DS:SI = VisRectangleClass object.
		DS:DI = Instance data.
		BP = GState to draw to.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file.
	AX, BX, CX, DX, SI.

PSEUDO CODE/STRATEGY:
	Set the drawing color from the instance data.
	Draw the rectangle based on the dimensions from the VisClass
	level.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	The drawing color in the instance data is assumed to work
	(i.e. show up) when drawing on the default (white) background.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.13	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VRDraw	method	dynamic	VisRectangleClass, METHOD_DRAW
	uses	ax,cx,dx,bp

	.enter

	; Set the drawing pen color.
	mov	ax, ds:[di].VR_color
	mov	di, bp
	call	GrSetAreaColor

	; Get access to the master instance data.
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset

	; Draw the rectangle.
	mov	ax, ds:[si].VI_bounds.R_left
	mov	bx, ds:[si].VI_bounds.R_top
	mov	cx, ds:[si].VI_bounds.R_right
	mov	dx, ds:[si].VI_bounds.R_bottom
	call	GrFillRect

	.leave
	ret
VRDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VRClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw the rectangle.

PASS:		*DS:SI = VisRectangleClass object.
		DS:DI = Instance data.
		BP = GState to draw to.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file.
	AX, BX, CX, DX, SI.

PSEUDO CODE/STRATEGY:
	Set the drawing color from the instance data.
	Draw the rectangle based on the dimensions from the VisClass
	level.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Yeah, right.  Like you think that this works?!?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.13	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VRClear	method	dynamic	VisRectangleClass, METHOD_VIS_RECTANGLE_CLEAR
	uses	ax,cx,dx,bp

	.enter

	; Make a GState for the window so that we can do the draw.
	push	di				; Save instance access.
	mov	di, offset VisRectangleClass
	mov	ax, METHOD_VUP_CREATE_DRAW_GSTATE
	call	ObjCallSuperNoLock
	pop	di				; Restore instance access.
	push	bp				; Save the GState.

	; Set the erasing pen color.
	mov	ax, (COLOR_INDEX shl 8) or WHITE
	mov	di, bp
	call	GrSetAreaColor

	; Get access to the master instance data.
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset

	; Draw the rectangle.
	mov	ax, ds:[si].VI_bounds.R_left
	mov	bx, ds:[si].VI_bounds.R_top
	mov	cx, ds:[si].VI_bounds.R_right
	mov	dx, ds:[si].VI_bounds.R_bottom
	call	GrFillRect

	; Kill that GState.
	pop	di
	call	GrDestroyState

	; Reset the rectangle bounds to nothing.
	mov	ds:[si].VI_bounds.R_right, 0
	mov	ds:[si].VI_bounds.R_bottom, CONVERSION_RECT_MAX_VERT_SIZE

	.leave
	ret
VRClear	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VRIncrementSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Increment the size and redraw the conversion status
		indicator.

PASS:		*DS:SI = VisRectangleClass object.
		DS:DI = Instance data.

RETURN:		Void.

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Normal dynamic method register file.
	AX, BX, CX, DX, SI.

PSEUDO CODE/STRATEGY:
	Create a GState for the drawing.
	Increment the rectangle's horizontal size (to the right).
	Set the vertical size to the maximum.
	Redraw ourself.
	Kill the GState.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	ObjMessage is overkill.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	91.05.14	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VRIncrementSize	method	dynamic	VisRectangleClass,
				METHOD_VIS_RECTANGLE_INC_HORIZ_SIZE
	uses	ax,cx,dx,bp

	.enter
	
	; Make a GState for the window so that we can do the draw.
	push	di				; Save instance access.
	mov	di, offset VisRectangleClass
	mov	ax, METHOD_VUP_CREATE_DRAW_GSTATE
	call	ObjCallSuperNoLock
	pop	di				; Restore instance access.
	push	bp				; Save the GState.

	; Increment the horizontal rectangle's bounds.
	; Set the vertical size.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	inc	ds:[di].VI_bounds.R_right
	mov	ds:[di].VI_bounds.R_bottom, CONVERSION_RECT_MAX_VERT_SIZE

	; Redraw ourself.
	; NOTE:	BP already set.
 	mov	ax, METHOD_DRAW
	mov	bx, handle NFISC_StatusRectangle
	mov	si, offset NFISC_StatusRectangle
	mov	di, mask MF_CALL
	call	ObjMessage

	; Kill that GState.
	pop	di
	call	GrDestroyState

	.leave
	ret
VRIncrementSize	endp


RectangleCode	ends
