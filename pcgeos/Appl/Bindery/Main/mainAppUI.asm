COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		mainAppUI.asm

ROUTINES:
	Name			Description
	----			-----------
    INT AIE_ObjMessageSendNow	Detach the application.

    INT AIE_ObjMessageSend	Detach the application.

    INT AIE_ObjMessage		Detach the application.

    INT AIE_GetBooleans		Detach the application.

    INT AIE_ObjMessageCall	Detach the application.

    INT SetBarState		Set the state of the "show bar" boolean
				group

METHODS:
	Name			Description
	----			-----------
    StudioApplicationAttach	Deal with starting Studio

				MSG_META_ATTACH
				StudioApplicationClass

    StudioApplicationDetach	Detach the application.

				MSG_META_DETACH
				StudioApplicationClass

    StudioApplicationLoadOptions Open the app

				MSG_META_LOAD_OPTIONS,
				StudioApplicationClass

    StudioApplicationSetBarState Set the bar state

				MSG_STUDIO_APPLICATION_SET_BAR_STATE
				StudioApplicationClass

    StudioApplicationForceDrawingToolsVisible  
				Force the drawing tools to be visible

				MSG_STUDIO_APPLICATION_FORCE_DRAWING_TOOLS_VISIBLE
				StudioApplicationClass

    StudioApplicationGraphicsWarn  
				Give warning about the graphics menu

				MSG_STUDIO_APPLICATION_GRAPHICS_WARN
				StudioApplicationClass

    StudioApplicationUpdateBars	Update toolbar states

				MSG_STUDIO_APPLICATION_UPDATE_BARS
				StudioApplicationClass

    StudioApplicationToolbarVisibility  
				Notification that the toolbar visibility
				has changed

				MSG_STUDIO_APPLICATION_TOOLBAR_VISIBILITY
				StudioApplicationClass

    StudioApplicationUpdateMiscSettings  
				Update misc settings

				MSG_STUDIO_APPLICATION_UPDATE_MISC_SETTINGS
				StudioApplicationClass

    StudioApplicationUpdateAppFeatures  
				Update feature states

				MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
				StudioApplicationClass

    StudioApplicationSetUserLevel  
				Set the user level

				MSG_STUDIO_APPLICATION_SET_USER_LEVEL
				StudioApplicationClass

    StudioApplicationChangeUserLevel  
				User change to the user level

				MSG_STUDIO_APPLICATION_CHANGE_USER_LEVEL
				StudioApplicationClass

    StudioApplicationCancelUserLevel  
				Cancel User change to the user level

				MSG_STUDIO_APPLICATION_CANCEL_USER_LEVEL
				StudioApplicationClass

    StudioApplicationQueryResetOptions  
				Make sure that the user wants to reset
				options

				MSG_STUDIO_APPLICATION_QUERY_RESET_OPTIONS
				StudioApplicationClass

    StudioApplicationUserLevelStatus  
				Update the "Fine Tune" trigger

				MSG_STUDIO_APPLICATION_USER_LEVEL_STATUS
				StudioApplicationClass

    StudioApplicationInitiateFineTune  
				Bring up the fine tune dialog box

				MSG_STUDIO_APPLICATION_INITIATE_FINE_TUNE
				StudioApplicationClass

    StudioApplicationFineTune	Set the fine tune settings

				MSG_STUDIO_APPLICATION_FINE_TUNE
				StudioApplicationClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/92		Initial version

DESCRIPTION:
	This file contains the scalable UI code for StudioApplicationClass

	$Id: mainAppUI.asm,v 1.1 97/04/04 14:39:44 newdeal Exp $

------------------------------------------------------------------------------@

idata segment

changingLevels	BooleanByte	BB_FALSE
contentFileList	hptr.MemHandle

idata ends

;---

HelpEditCode segment resource

HE_ObjMessageCall	proc	near
	push	di
	mov	di, mask MF_CALL
	call	HE_ObjMessage
	pop	di
	ret
HE_ObjMessageCall	endp

HE_ObjMessageSend	proc	near
	push	di
	clr	di
	call	HE_ObjMessage
	pop	di
	ret
HE_ObjMessageSend	endp

HE_ObjMessage	proc	near
	call	ObjMessage
	ret
HE_ObjMessage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SABookNameTextVisibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If BookNameText is opening, give it the focus.

CALLED BY:	MSG_STUDIO_APPLICATION_BOOK_NAME_TEXT_VISIBILITY
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioApplicationClass
		ax - the message
		^lcx:dx - object which has become visible
		bp - non-zero if open, zero if close
RETURN:		nada
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SABookNameTextVisibility       method dynamic StudioApplicationClass,
			       MSG_STUDIO_APPLICATION_BOOK_NAME_TEXT_VISIBILITY

		tst	bp
		jz	done

		movdw	bxsi, cxdx
		mov	ax, MSG_META_GRAB_FOCUS_EXCL
		clr	di
		call	ObjMessage
done:
		ret
SABookNameTextVisibility		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SASetContentFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to current document, telling it to
		update the file name in ContentFileNameText.

CALLED BY:	MSG_STUDIO_APPLICATION_SET_CONTENT_FILE_NAME
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioApplicationClass
		ax - the message
		bp - non-zero if open, zero if close
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SASetContentFileName		method dynamic StudioApplicationClass,
				MSG_STUDIO_APPLICATION_SET_CONTENT_FILE_NAME
		tst	bp
		jz	done

		push	si
		mov	ax, MSG_STUDIO_DOCUMENT_SET_CONTENT_FILE_NAME
		mov	bx, es
		mov	si, offset StudioDocumentClass	;bx:si<-StudioDocClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		pop	si
		
		mov	cx, di
		mov	dx, TO_APP_MODEL
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		call	ObjCallInstanceNoLock
done:		
		ret
SASetContentFileName		endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationBitmapResolutionChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has changed the bitmap resolution selection in 
		the generate help file dialog

CALLED BY:	MSG_STUDIO_APPLICATION_RESOLUTION_CHANGED
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg remover of StudioApplicationClass
		ax - the message
		cx - Bitmap resolution (72, 300, or 0 (custom))

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationBitmapResolutionChanged method dynamic StudioApplicationClass,
			MSG_STUDIO_APPLICATION_BITMAP_RESOLUTION_CHANGED
	;
	; Enable or disable the custom resolution object
	;
		mov	ax, MSG_GEN_SET_ENABLED
		jcxz	setState
		mov	ax, MSG_GEN_SET_NOT_ENABLED

setState:
		mov	si, offset BitmapCustomResolutionValue
		GOTO	SetStateLow
StudioApplicationBitmapResolutionChanged		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationCompressOptionsChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has changed the bitmap resolution selection in 
		the generate help file dialog

CALLED BY:	MSG_STUDIO_APPLICATION_COMPRESS_OPTIONS_CHANGED
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg remover of StudioApplicationClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationCompressOptionsChanged method dynamic StudioApplicationClass,
			MSG_STUDIO_APPLICATION_COMPRESS_OPTIONS_CHANGED
	;
	; Enable or disable the bitmap gadgetry 
	;
		mov	ax, MSG_GEN_SET_ENABLED
		test	cx, mask HO_COMPRESS_GRAPHICS
		jnz	setState
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setState:
		push	ax
		mov	si, offset BitmapResolutionInteraction
		call	SetStateLow
		pop	ax
		mov	si, offset BitmapFormatItemGroup
		GOTO	SetStateLow
		
StudioApplicationCompressOptionsChanged		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationResetBookInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the BookInfoDialog to its default state

CALLED BY:	MSG_STUDIO_APPLICATION_RESET_BOOK_INFO
PASS:		*ds:si - application
RETURN:		nothing
DESTROYED:	ax, cx, dx, bx, bp, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationResetBookInfo	method	StudioApplicationClass,
				MSG_STUDIO_APPLICATION_RESET_BOOK_INFO
		
	; clear the Book name from the status bar

		GetResourceHandleNS	BookNameText, bx
		mov	si, offset BookNameStatusBar
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	HE_ObjMessageSend

	; set content file path to userdata 

		clr	ax
		push	ax
		mov	cx, ss
		mov	dx, sp			;cx:dx <- NULL
		call	SetBookPath
		add	sp, size word		;clear NULL from stack
		
		call	ResetBookInfoCommon
	;
	; Close the Manage Files and Book Options DBs
	;
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	si, offset ManageFilesSubgroup
		call	HE_ObjMessageSend

		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	si, offset ViewerToolsSubgroup
		call	HE_ObjMessageSend

		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	si, offset BookOptionsSubgroup
		call	HE_ObjMessageSend
	;
	; Disable the ManageFiles and BookOptions triggers
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	si, offset ManageFilesTrigger
		call	SetStateLow
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	si, offset BookOptionsTrigger
		call	SetStateLow
		
		ret
StudioApplicationResetBookInfo	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ResetBookInfoCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset those gadgets which need to be reset when we
		are defining a new book.

CALLED BY:	StudioApplicationResetBookInfo, StudioProcessDefineBook 
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetBookInfoCommon		proc	far
		uses	cx, dx
		.enter

	; free the content file list

		call	FreeContentFileList

	; remove everything from the content file list

		clr	cx
		call	InitializeContentFileList

	; Clear first page name and define book text object

		GetResourceHandleNS	BookNameText, bx
		mov	si, offset FirstPageContextName
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	HE_ObjMessageSend
		mov	si, offset BookNameText
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	HE_ObjMessageSend

	; reset the ViewerToolsList to its default state

		mov	si, offset ViewerFeaturesList
		mov	cx, DEFAULT_VIEWER_FEATURES
		call	SetViewerFlags	
		mov	si, offset ViewerToolsList
		mov	cx, DEFAULT_VIEWER_TOOLS
		call	SetViewerFlags

		.leave
		ret
ResetBookInfoCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationLoadBook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a book and restore UI 

CALLED BY:	MSG_STUDIO_APPLICATION_LOAD_BOOK
PASS:		*ds:si - application
		cx - chunk handle of object with book name 
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationLoadBook		method	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_LOAD_BOOK

	; open the book file

		mov	di, cx
		sub	sp, size FileLongName
		mov	dx, sp
		mov	cx, ss
		push	ds
		call	OpenBookFile		;bx <- file handle
		pop	ds
		cmp	ax, OBFE_NONE
		jne	noBook
		
	; put the name in the status bar and BookNameText 

		mov	si, offset BookNameStatusBar
		call	SetText
		
		call	RestoreBookUI	;set state for rest of UI

		clr 	ax
		call	VMClose
done:
	;
	; Now that a book has been specified, enable other book gadgetry
	;
		mov	ax, MSG_GEN_SET_ENABLED
		mov	si, offset ManageFilesTrigger
		call	SetStateLow
		mov	ax, MSG_GEN_SET_ENABLED
		mov	si, offset BookOptionsTrigger
		call	SetStateLow
exit:
		add	sp, size FileLongName
		ret

noBook:
		cmp	ax, OBFE_NAME_NOT_FOUND
		je	noNewBook
		
	; couldn't find a file of the given name, ask the user what to do
	;
		call	BookFileNotFoundQuery
		cmp	ax, IC_YES		;YES = new book
		jne	noNewBook

	; put the name in the status bar and BookNameText

		mov	si, offset BookNameStatusBar
		call	SetText
		mov	si, offset BookNameText
		call	SetText
		mov	ax, MSG_GEN_SET_ENABLED
		jmp	done

noNewBook:
	;
	; There is no book, so reset the book info dialog to its
	; default state
	;
		mov	ax, MSG_STUDIO_APPLICATION_RESET_BOOK_INFO
		call	ObjCallInstanceNoLock
		jmp	exit

StudioApplicationLoadBook	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the text in an object

CALLED BY:	StudioApplicationRestoreBookState, SetFirstPageInfo
PASS:		cx:dx - null-terminated text
		si - chunk handle of text object		
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetText		proc	far
		uses bx, cx, dx, bp
		.enter
		mov	bp, cx
		xchg	bp, dx			;dx:bp <- book name
		clr	cx			;it's null terminated
		GetResourceHandleNS	BookNameText, bx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	HE_ObjMessageCall
		.leave
		ret
SetText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreBookUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set state of the objects in BookInfoDialog based on
		the book file's contents.

CALLED BY:	RestoreBookFileState
PASS:		bx - Book file handle
		es - dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreBookUI		proc	near
		uses	bx
		.enter
		
		call	FreeContentFileList

	; lock the BookFileHeader

		call	VMGetMapBlock			;ax <- map block
		call	VMLock				;bp <- for unlock
		mov	ds, ax

		mov	cx, ds:[BFH_featureFlags]
		mov	si, offset ViewerFeaturesList
		call	SetViewerFlags	
		mov	si, offset ViewerToolsList
		mov	cx, ds:[BFH_toolFlags]
		call	SetViewerFlags	

		mov	cx, ds
		lea	dx, ds:[BFH_path]
		call	SetBookPath

		mov	cx, ds:[BFH_count]
		call	InitializeContentFileList	;initialize list
		jcxz	noFiles				;any files?
		
	; get the size of the content file name list
		
		clr	dx
		mov	ax, size FileLongName
		mul	cx
EC <		tst	dx						>
EC <		ERROR_NZ	INVALID_CONTENT_FILE_LIST_LENGTH	>
		
		push	ax, bx
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		GetResourceSegmentNS	dgroup, es
		mov	es:contentFileList, bx
		mov	es, ax
		pop	cx, bx
		shr	cx				;# words in list

		push	bp, ds
		mov	ax, ds:[BFH_nameList]
EC <		tst	ax						>
EC <		ERROR_Z ERROR_BOOK_HAS_NO_NAME_LIST			>
		call	VMLock
		mov	ds, ax

	; copy names from book file to contentList block
		
		clr	si, di
		rep	movsw

		call	VMUnlock		;unlock nameList block
		pop	bp, ds
		
	; set the first page UI state

		call	SetFirstPageInfo
		
		GetResourceSegmentNS	dgroup, es
		mov	bx, es:contentFileList
		call	MemUnlock

done:
		call	VMUnlock		;unlock map block

		.leave
		ret

noFiles:
	; If there are no content files, at least clear the first page name
	;
		GetResourceHandleNS	BookNameText, bx
		mov	si, offset FirstPageContextName
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	HE_ObjMessageSend
		jmp	done
		
RestoreBookUI		endp

;---

FreeContentFileList	proc	near
		push	bx, es
		GetResourceSegmentNS	dgroup, es
		clr	bx
		xchg	bx, es:contentFileList
		tst	bx
		jz	noList
		call	MemFree
noList:
		pop	bx, es
		ret
FreeContentFileList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFirstPageInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the first page UI

CALLED BY:	GenerateBookFileLow
PASS:		ds  - BookFileHeader
		es - segment of file list
RETURN:		nothing
DESTROYED:	si, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFirstPageInfo		proc	near
		uses	bx, bp
		.enter

		mov	cx, ds
		lea	dx, ds:[BFH_firstPage]		;cx:dx - page name
		mov	si, offset FirstPageContextName
		call	SetText

	; get the file name from the list

		mov	ax, ds:[BFH_firstFile]
		cmp	ax, ds:[BFH_count]				
		jb	setIt
		mov	ax, -1
setIt:
		mov	cx, ax
		call	SetMainFileSelection
		.leave
		ret
SetFirstPageInfo		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMainFileSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the main file in the MainFileList

CALLED BY:	INTERNAL
PASS:		cx - file number to select
RETURN:		nothing
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMainFileSelection		proc	near
		uses	bx, dx, bp, si
		.enter
		GetResourceHandleNS	MainFileList, bx
		mov	si, offset MainFileList
		clr	dx			; not indeterminate
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	HE_ObjMessageSend
		.leave
		ret
SetMainFileSelection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFileSelectorSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selection for a file selector

CALLED BY:	INTERNAL
PASS:		cx:dx - buffer with selection name
		si - chunk of file selector
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFileSelectorSelection		proc	far
		uses	bx, cx, dx, bp
		.enter

		push	cx, dx
		GetResourceHandleNS	BookPathFileSelector, bx
		mov	cx, TEMP_GEN_FILE_SELECTOR_DATA
		mov	ax, MSG_META_DELETE_VAR_DATA
		call	HE_ObjMessageCall
		pop	cx, dx

		mov	ax, MSG_GEN_FILE_SELECTOR_SET_SELECTION
		call	HE_ObjMessageCall
		
		.leave
		ret
SetFileSelectorSelection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetViewerFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set ViewerToolsList state

CALLED BY:	SetBookInfoDialogState
PASS:		cx - ViewerToolFlags
		si - chunk handle of GenBooleanGroup
RETURN:		nothing
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetViewerFlags		proc	near
		uses	bx, di
		.enter

		clr	dx
		GetResourceHandleNS	ViewerToolsList, bx
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
		call	HE_ObjMessageSend

	; any time we modify the feature list, we need to update the
	; enabled state of the tool list items
		
		cmp	si, offset ViewerFeaturesList
		jne	done
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG
		call	HE_ObjMessageSend

done:
		.leave
		ret
SetViewerFlags		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBookPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the BookPathFileSelector's path and the first page
		file selector's path

CALLED BY:	SetBookInfoDialogState

PASS:		cx:dx	- path name

RETURN:		nothing

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBookPath		proc	near
		uses	bx, si, bp, es
		.enter

		push	cx, dx		
		mov	si, offset BookPathFileSelector
		GetResourceHandleNS	BookPathFileSelector, bx
		mov	bp, SP_USER_DATA
		mov	ax, MSG_GEN_PATH_SET
		call	HE_ObjMessageCall
		pop	cx, dx

		segmov	es, cx, ax
		mov	bp, dx
		mov	{word}es:[bp], '.'
		call	SetFileSelectorSelection
if 0
		mov	ax, MSG_META_RELEASE_FOCUS_EXCL
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		
		mov	si, offset BookNameText
		mov	ax, MSG_META_GRAB_FOCUS_EXCL
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
endif		
		.leave
		ret
SetBookPath		endp

HelpEditCode ends

;---

AppInitExit segment resource

AIE_ObjMessageSendNow	proc	near
	mov	dl, VUM_NOW
	FALL_THRU	AIE_ObjMessageSend
AIE_ObjMessageSendNow	endp

AIE_ObjMessageSend	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	AIE_ObjMessage
	pop	di
	ret
AIE_ObjMessageSend	endp

AIE_ObjMessage	proc	near
	call	ObjMessage
	ret
AIE_ObjMessage	endp

;---

	; returns ax = booleans
AIE_GetBooleans	proc	near
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	FALL_THRU	AIE_ObjMessageCall
AIE_GetBooleans	endp

;---

AIE_ObjMessageCall	proc	near
	push	di
	mov	di, mask MF_CALL
	call	AIE_ObjMessage
	pop	di
	ret
AIE_ObjMessageCall	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationLoadOptions -- MSG_META_LOAD_OPTIONS
						for StudioApplicationClass

DESCRIPTION:	Open the app

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@

SettingTableEntry	struct
    STE_showBars	StudioBarStates
    STE_features	StudioFeatures
SettingTableEntry	ends

settingsTable	SettingTableEntry	\
 <INTRODUCTORY_BAR_STATES, INTRODUCTORY_FEATURES>,
 <BEGINNING_BAR_STATES, BEGINNING_FEATURES>,
 <INTERMEDIATE_BAR_STATES, INTERMEDIATE_FEATURES>,
 <ADVANCED_BAR_STATES, ADVANCED_FEATURES>

featuresKey		char	"features", 0

;---

StudioApplicationLoadOptions	method dynamic	StudioApplicationClass,
							MSG_META_LOAD_OPTIONS,
							MSG_META_RESET_OPTIONS

	mov	di, offset StudioApplicationClass
	call	ObjCallSuperNoLock

	; if no features settings are stored then use
	; defaults based on the system's user level

	sub	sp, INI_CATEGORY_BUFFER_SIZE
	movdw	cxdx, sssp

	mov	ax, MSG_META_GET_INI_CATEGORY
	call	ObjCallInstanceNoLock

	mov	ax, sp

	push	si, ds
	segmov	ds, ss
	mov_tr	si, ax
	mov	cx, cs
	mov	dx, offset featuresKey
	call	InitFileReadInteger
	pop	si, ds
	mov	bp, sp
	lea	sp, ss:[bp+INI_CATEGORY_BUFFER_SIZE]
	jnc	common

	; no .ini file settings -- set objects correctly based on level

	;
	; For Studio, we always want the Advanced stuff. To save time,
	; we leave the miscellaneous User Level code in and just set
	; this here.
	;
	push	si
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	cx, ADVANCED_FEATURES
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	AIE_ObjMessageSend
	mov	cx, 1					;mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	AIE_ObjMessageSend
	mov	ax, MSG_GEN_APPLY
	call	AIE_ObjMessageSend
	;
	; For Studio, we always want the Advanced stuff.
	;
	mov	cx, ADVANCED_BAR_STATES
	call	SetBarState
	pop	si

common:

	; tell the GrObjHead to send notification about the current tool

	GetResourceHandleNS	StudioHead, bx
	mov	si, offset StudioHead
	mov	ax, MSG_GH_SEND_NOTIFY_CURRENT_TOOL
	mov	di, mask MF_FORCE_QUEUE
	call	AIE_ObjMessageSend

	ret

StudioApplicationLoadOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationSetBarState --
		MSG_STUDIO_APPLICATION_SET_BAR_STATE for StudioApplicationClass

DESCRIPTION:	Set the bar state

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx - new bar state

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationSetBarState	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_SET_BAR_STATE
	call	SetBarState
	ret

StudioApplicationSetBarState	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetBarState

DESCRIPTION:	Set the state of the "show bar" boolean group

CALLED BY:	INTERNAL

PASS:
	cx - new state

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/92		Initial version

------------------------------------------------------------------------------@
SetBarState	proc	near	uses si
	.enter

	push	cx
	GetResourceHandleNS	ShowBarList, bx
	mov	si, offset ShowBarList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	AIE_ObjMessageCall			;ax = bits set
	pop	cx

	xor	ax, cx					;ax = bits changed
	jz	done

	push	ax
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx
	call	AIE_ObjMessageSend
	pop	cx
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	call	AIE_ObjMessageSend
	mov	ax, MSG_GEN_APPLY
	call	AIE_ObjMessageSend
done:
	.leave
	ret

SetBarState	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationForceDrawingToolsVisible --
		MSG_STUDIO_APPLICATION_FORCE_DRAWING_TOOLS_VISIBLE
						for StudioApplicationClass

DESCRIPTION:	Force the drawing tools to be visible

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/22/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationForceDrawingToolsVisible	method dynamic	\
						StudioApplicationClass,
			MSG_STUDIO_APPLICATION_FORCE_DRAWING_TOOLS_VISIBLE

	mov	cx, ds:[di].SAI_barStates
	mov	bp, mask SBS_SHOW_DRAWING_TOOLS
	test	cx, bp
	jnz	done

	ornf	cx, bp
	call	SetBarState
done:
	ret

StudioApplicationForceDrawingToolsVisible	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationGraphicsWarn --
		MSG_STUDIO_APPLICATION_GRAPHICS_WARN for StudioApplicationClass

DESCRIPTION:	Give warning about the graphics menu

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/22/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationGraphicsWarn	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_GRAPHICS_WARN

	mov	ax, offset GraphicsWarnString
	clr	cx
	mov	dx,
		 CustomDialogBoxFlags <0, CDT_NOTIFICATION, GIT_NOTIFICATION,0>
	call	ComplexQuery

	ret

StudioApplicationGraphicsWarn	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationUpdateBars -- MSG_STUDIO_APPLICATION_UPDATE_BARS
						for StudioApplicationClass

DESCRIPTION:	Update toolbar states

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx - Booleans currently selected
	bp - Booleans whose state have been modified

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationUpdateBars	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_UPDATE_BARS

	mov	ds:[di].SAI_barStates, cx
	mov_tr	ax, cx				;ax = new state

	test	bp, mask SBS_SHOW_STYLE_BAR
	jz	noStyleBarChange
	push	ax
	clr	cx				;never avoid popout update
	GetResourceHandleNS	StyleToolbar, bx
	mov	di, offset StyleToolbar
	test	ax, mask SBS_SHOW_STYLE_BAR
	mov	ax, 0				;clear "parent is popout" flag
	call	updateToolbarUsability
	pop	ax
noStyleBarChange:

	test	bp, mask SBS_SHOW_FUNCTION_BAR
	jz	noFunctionBarChange
	push	ax
	clr	cx				;never avoid popout update
	GetResourceHandleNS	FunctionToolbar, bx
	mov	di, offset FunctionToolbar
	test	ax, mask SBS_SHOW_FUNCTION_BAR
	mov	ax, 0				;clear "parent is popout" flag
	call	updateToolbarUsability
	pop	ax
noFunctionBarChange:

	test	bp, mask SBS_SHOW_GRAPHIC_BAR
	jz	noGraphicBarChange
	push	ax
	clr	cx				;never avoid popout update
	GetResourceHandleNS	GraphicsToolbar, bx
	mov	di, offset GraphicsToolbar
	test	ax, mask SBS_SHOW_GRAPHIC_BAR
	mov	ax, 0				;clear "parent is popout" flag
	call	updateToolbarUsability
	pop	ax
noGraphicBarChange:

	test	bp, mask SBS_SHOW_DRAWING_TOOLS
	jz	noDrawingToolsChange
	push	ax
	mov	cx, bp
	and	cx, mask SBS_SHOW_BITMAP_TOOLS		; set cx to non-zero if
							; bitmap tools are on
	GetResourceHandleNS	GrObjDrawingTools, bx
	mov	di, offset GrObjDrawingTools
	test	ax, mask SBS_SHOW_DRAWING_TOOLS
	mov	ax, 1				;set "parent is popout" flag
	call	updateToolbarUsability
	pop	ax

	; if turning drawing tools off then change to the Studio tool

	push	ax, si, bp
	test	ax, mask SBS_SHOW_DRAWING_TOOLS
	jnz	drawingToolsOn

	GetResourceHandleNS	StudioHead, bx
	mov	si, offset StudioHead
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	cx, segment EditTextGuardianClass
	mov	dx, offset EditTextGuardianClass
	clr	bp
	call	AIE_ObjMessageSend
	jmp	afterDrawingToolChange

drawingToolsOn:

	; if we only have a simple graphics layer then warn the user

	mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
	call	ObjCallInstanceNoLock
	test	ax, mask SF_GRAPHICS_LAYER or mask SF_COMPLEX_GRAPHICS
	jnz	afterDrawingToolChange

	; we want to delay once through the queue before doing this so that
	; the drawing tools have a chance to come up

	mov	ax, MSG_STUDIO_APPLICATION_GRAPHICS_WARN
	mov	bx, ds:[LMBH_handle]

if 0
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	dx, mask MF_FORCE_QUEUE
	mov	ax, MSG_META_DISPATCH_EVENT
endif

	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

afterDrawingToolChange:
	pop	ax, si, bp
noDrawingToolsChange:

	test	bp, mask SBS_SHOW_BITMAP_TOOLS
	jz	noBitmapToolsChange
	push	ax
	mov	cx, bp
	and	cx, mask SBS_SHOW_DRAWING_TOOLS		; set cx to non-zero if
							; drawing tools are on
	GetResourceHandleNS	GrObjBitmapTools, bx
	mov	di, offset GrObjBitmapTools
	test	ax, mask SBS_SHOW_BITMAP_TOOLS
	mov	ax, 1				;set "parent is popout" flag
	call	updateToolbarUsability
	pop	ax
noBitmapToolsChange:

	ret

;---

	; pass:
	;	ax - non-zero if parent is the popout
	;	*ds:si - application object
	;	bxdi - toolbar
	;	zero flag - set for usable
	;	cx - non-zero to avoid popout update
	;	ax - non-zero if parent is the popout
	; destroy:
	;	ax, bx, cx, dx, di

updateToolbarUsability:
	push	bp

	mov_tr	bp, ax				;bp = parent flag
	mov	ax, MSG_GEN_SET_USABLE
	jnz	gotMessage
	mov	ax, MSG_GEN_SET_NOT_USABLE
gotMessage:

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	dl, VUM_NOW
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	gotMode
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
gotMode:
	pop	di

	push	si
	mov	si, di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	cmp	ax, MSG_GEN_SET_USABLE
	jnz	usabilityDone			;if not "set usable" then done
	tst	cx
	jnz	usabilityDone			;if avoid popout update flag
						;set then done

	tst	bp
	jz	afterParentFlag
	mov	ax, MSG_GEN_FIND_PARENT
	call	AIE_ObjMessageCall		;cxdx = parent
	movdw	bxsi, cxdx
afterParentFlag:
	mov	ax, MSG_GEN_INTERACTION_POP_IN
	call	AIE_ObjMessageSend

usabilityDone:
	pop	si
	pop	bp
	retn

StudioApplicationUpdateBars	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationToolbarVisibility --
		MSG_STUDIO_APPLICATION_TOOLBAR_VISIBILITY
						for StudioApplicationClass

DESCRIPTION:	Notification that the toolbar visibility has changed

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx - StudioBarStates
	bp - non-zero if opening, zero if closing

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationToolbarVisibility	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_TOOLBAR_VISIBILITY

	test	ds:[di].GAI_states, mask AS_DETACHING
	jnz	done

	tst	es:[changingLevels]
	jnz	done

	tst	bp				;if opening then bail
	jnz	done

	; if closing then we want to update the bar states appropriately

	mov	bp, cx
	mov	cx, ds:[di].SAI_barStates		;cx = old
	not	bp
	and	cx, bp
	cmp	cx, ds:[di].SAI_barStates
	jz	done

	; if we are iconifying then we don't want to turn the beasts off

	push	cx, si
	GetResourceHandleNS	StudioPrimary, bx
	mov	si, offset StudioPrimary
	mov	ax, MSG_GEN_DISPLAY_GET_MINIMIZED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;carry set if minimized
	pop	cx, si
	jc	done

	mov	ax, MSG_STUDIO_APPLICATION_SET_BAR_STATE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

done:
	ret

StudioApplicationToolbarVisibility	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationUpdateMiscSettings --
		MSG_STUDIO_APPLICATION_UPDATE_MISC_SETTINGS for StudioApplicationClass

DESCRIPTION:	Update misc settings 

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx - Booleans currently selected
	bp - Booleans whose state have been modified

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationUpdateMiscSettings	method dynamic	StudioApplicationClass,
				MSG_STUDIO_APPLICATION_UPDATE_MISC_SETTINGS

	mov	es:[miscSettings], cx
	mov_tr	ax, cx				;ax = selected booleans

	; if the "show invisibles" flag has changed then recalculate
	; all cached gstates

	test	bp, mask SMS_SHOW_INVISIBLES
	jz	noShowInvisiblesChange
	push	ax, bp

	; send a MSG_VIS_RECREATE_CACHED_GSTATES to all documents

	mov	ax, MSG_VIS_RECREATE_CACHED_GSTATES
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				;cx = event
	GetResourceHandleNS	StudioDocGroup, bx
	mov	si, offset StudioDocGroup
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	call	AIE_ObjMessageSend

	; move hotspots to account for extra space taken by 
	; page name characters

	mov	cl, 1				;recalc from current page
	mov	ax, MSG_STUDIO_DOCUMENT_RECALC_HOTSPOTS
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				;cx = event
	mov	dx, TO_APP_TARGET
	GetResourceHandleNS	StudioDisplayGroup, bx
	mov	si, offset StudioDisplayGroup
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	AIE_ObjMessageSend
	pop	ax, bp

noShowInvisiblesChange:

	; if the "display page and section" flag or the "show invisibles"
	; flag has changed then redraw all views

	test	bp, mask SMS_DISPLAY_SECTION_AND_PAGE or \
		    mask SMS_SHOW_INVISIBLES
	jz	noRedrawChange
	push	ax, bp
	GetResourceHandleNS	StudioViewControl, bx
	mov	si, offset StudioViewControl
	mov	ax, MSG_GVC_REDRAW
	call	AIE_ObjMessageSend
	pop	ax, bp
noRedrawChange:

	; if the "automatic layout recalc" flag has changed to ON then
	; recalculate as needed

	test	bp, mask SMS_AUTOMATIC_LAYOUT_RECALC
	jz	noRecalcChange
	push	ax, bp
	test	ax, mask SMS_AUTOMATIC_LAYOUT_RECALC
	pushf

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jnz	10$
	mov	ax, MSG_GEN_SET_ENABLED
	GetResourceHandleNS	RecalcTrigger, bx
	mov	si, offset RecalcTrigger
	mov	dl, VUM_NOW
	call	AIE_ObjMessageSend
10$:

	popf
	jz	afterRecalc
	mov	ax, MSG_STUDIO_DOCUMENT_RECALC_LAYOUT
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	GetResourceHandleNS	StudioDocGroup, bx
	mov	si, offset StudioDocGroup
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	call	AIE_ObjMessageSend
afterRecalc:
	pop	ax, bp
noRecalcChange:

	ret

StudioApplicationUpdateMiscSettings	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationUpdateAppFeatures --
		MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
					for StudioApplicationClass

DESCRIPTION:	Update feature states

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	ss:bp - GenAppUpdateFeaturesParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@

; This table has an entry corresponding to each feature bit.  The entry is a
; point to the list of objects to turn on/off

usabilityTable	fptr	\
	editFeaturesEntry,	;SF_EDIT_FEATURES
	simpleTextAttributesList, ;SF_SIMPLE_TEXT_ATTRIBUTES
	simplePageLayoutList,	;SF_SIMPLE_PAGE_LAYOUT
	simpleGraphicsLayerList, ;SF_SIMPLE_GRAPHICS_LAYER
	characterMenuList,	;SF_CHARACTER_MENU
	colorList,		;SF_COLOR

	graphicLayerList,	;SF_GRAPHICS_LAYER_ENTRY
	miscOptionsList,	;SF_MISC_OPTIONS
	complexTextAttributeList, ;SF_COMPLEX_TEXT_ATRIBUTES

	rulerControlList,	;SF_RULER_COLTROL
	complexPageLayoutList,	;SF_COMPLEX_PAGE_LAYOUT
	complexGraphicsList	;SF_COMPLEX_TEXT_ATRIBUTES

;	helpEditorList		;SF_HELP_EDITOR


editFeaturesEntry	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple StudioSearchReplaceControl
	GenAppMakeUsabilityTuple StudioTextCountControl
	GenAppMakeUsabilityTuple StudioThesaurusControl, end

simpleTextAttributesList label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple StudioFontControl, recalc
	GenAppMakeUsabilityTuple StudioTextStyleControl, recalc
	GenAppMakeUsabilityTuple StudioPointSizeControl, recalc
	GenAppMakeUsabilityTuple InsertSubMenu
	GenAppMakeUsabilityTuple StudioMarginControl
	GenAppMakeUsabilityTuple StudioTabControl
	GenAppMakeUsabilityTuple BorderSubMenu
	GenAppMakeUsabilityTuple ShowToolsPopup
	GenAppMakeUsabilityTuple ShowStyleBarEntry, toolbar
	GenAppMakeUsabilityTuple StudioJustificationControl, popup
	GenAppMakeUsabilityTuple StudioLineSpacingControl, popup
	GenAppMakeUsabilityTuple StudioTextStyleSheetControl, end

simplePageLayoutList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple PageMenuGroup
	GenAppMakeUsabilityTuple StudioPageSetupDialog, end

simpleGraphicsLayerList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowDrawingToolsEntry, toolbar, end

characterMenuList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple StudioTextStyleControl, reversed, reparent
	GenAppMakeUsabilityTuple StudioPointSizeControl, reversed, reparent
	GenAppMakeUsabilityTuple StudioFontControl, reversed, reparent
	GenAppMakeUsabilityTuple CharacterMenu
	GenAppMakeUsabilityTuple StyleToolbar, restart, end

colorList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple StudioParaBGColorControl
	GenAppMakeUsabilityTuple StudioCharFGColorControl
	GenAppMakeUsabilityTuple StudioCharBGColorControl
	GenAppMakeUsabilityTuple StudioBorderColorControl

graphicLayerList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple StudioGrObjToolControl, recalc, end
;	GenAppMakeUsabilityTuple ShowGraphicBarEntry, toolbar 

miscOptionsList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowFunctionBarEntry, toolbar
	GenAppMakeUsabilityTuple MiscSettingsPopup
	GenAppMakeUsabilityTuple StudioToolControl, end

complexTextAttributeList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ViewTypeSubGroup
	GenAppMakeUsabilityTuple InsertNumberMenu
	GenAppMakeUsabilityTuple InsertDateMenu
	GenAppMakeUsabilityTuple InsertTimeMenu
	GenAppMakeUsabilityTuple StudioFontAttrControl
	GenAppMakeUsabilityTuple StudioDefaultTabsControl
	GenAppMakeUsabilityTuple StudioParaAttrControl
	GenAppMakeUsabilityTuple StudioTextStyleControl, recalc
	GenAppMakeUsabilityTuple StudioLineSpacingControl, recalc
	GenAppMakeUsabilityTuple StudioParaSpacingControl
	GenAppMakeUsabilityTuple StudioBorderControl, recalc
	GenAppMakeUsabilityTuple StudioHyphenationControl
	GenAppMakeUsabilityTuple StudioTextStyleSheetControl, recalc, end


rulerControlList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple RulerPopup
	GenAppMakeUsabilityTuple StudioTextRulerControl
	GenAppMakeUsabilityTuple StudioRulerShowControl
	GenAppMakeUsabilityTuple StudioRulerTypeControl, end

complexPageLayoutList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ConfirmationEntry
	GenAppMakeUsabilityTuple AutomaticLayoutRecalcEntry
	GenAppMakeUsabilityTuple DoNotDeletePagesWithGraphicsEntry
	GenAppMakeUsabilityTuple PasteGraphicsToCurrentLayerEntry
	GenAppMakeUsabilityTuple RecalcTrigger, end

complexGraphicsList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple StudioGrObjToolControl, recalc, end

;helpEditorList		label	GenAppUsabilityTuple
;	GenAppMakeUsabilityTuple InsertContextNumberMenu,
;	GenAppMakeUsabilityTuple StudioPageNameControl, 
;	GenAppMakeUsabilityTuple StudioHyperlinkControl, end

;---

levelTable		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple StudioSearchReplaceControl, restart
	GenAppMakeUsabilityTuple StudioSpellControl, restart
	GenAppMakeUsabilityTuple SpellTools, restart
	GenAppMakeUsabilityTuple SearchReplaceTools, restart
	GenAppMakeUsabilityTuple StudioViewControl, recalc
	GenAppMakeUsabilityTuple StudioDisplayControl, recalc
	GenAppMakeUsabilityTuple StudioDocumentControl, recalc, end

;---

StudioApplicationUpdateAppFeatures	method dynamic	StudioApplicationClass,
					MSG_GEN_APPLICATION_UPDATE_APP_FEATURES

	mov	es:[changingLevels], BB_TRUE

	; call general routine to update usability

	mov	ss:[bp].GAUFP_table.segment, cs
	mov	ss:[bp].GAUFP_table.offset, offset usabilityTable
	mov	ss:[bp].GAUFP_tableLength, length usabilityTable
	mov	ss:[bp].GAUFP_levelTable.segment, cs
	mov	ss:[bp].GAUFP_levelTable.offset, offset levelTable

	GetResourceHandleNS	CharacterMenu, bx
	mov	ss:[bp].GAUFP_reparentObject.handle, bx
	mov	ss:[bp].GAUFP_reparentObject.offset, offset CharacterMenu

	;
	;  Handle "unreparenting" automatically
	;
	clrdw	ss:[bp].GAUFP_unReparentObject

	mov	ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
	call	ObjCallInstanceNoLock

	mov	es:[changingLevels], BB_FALSE

	ret

StudioApplicationUpdateAppFeatures	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationSetUserLevel --
		MSG_STUDIO_APPLICATION_SET_USER_LEVEL for StudioApplicationClass

DESCRIPTION:	Set the user level

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx - user level (bits)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/16/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationSetUserLevel	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_SET_USER_LEVEL

	mov	ax, cx				;ax <- new features

	; find the corresponding bar states and level

	push	si
	clr	di, bp
	mov	cx, (length settingsTable)	;cx <- # entries
	mov	dl, UIIL_INTRODUCTORY		;dl <- UIInterfaceLevel
	mov	dh, dl				;dh <- nearest so far (level)
	mov	si, 16				;si <- nearest so far (# bits)
findLoop:
	cmp	ax, cs:settingsTable[di].STE_features
	je	found
	push	ax, cx
	;
	; See how closely the features match what we're looking for
	;
	mov	bx, ax
	xor	bx, cs:settingsTable[di].STE_features
	clr	ax				;no bits on
	mov	cx, 16
countBits:
	ror	bx, 1
	jnc	nextBit				;bit on?
	inc	ax				;ax <- more bit
nextBit:
	loop	countBits

	cmp	ax, si				;fewer differences?

	ja	nextEntry			;branch if not fewer difference
	;
	; In the event we don't find a match, use the closest
	;
	mov	si, ax				;si <- nearest so far (# bits)
	mov	dh, dl				;dh <- nearest so far (level)
	mov	bp, di				;bp <- corresponding entry
nextEntry:
	pop	ax, cx
	inc	dl				;dl <- next UIInterfaceLevel
	add	di, (size SettingTableEntry)
	loop	findLoop
	;
	; No exact match -- set the level to the closest
	;
	mov	dl, dh				;dl <- nearest level
	mov	di, bp				;di <- corresponding entry
	;
	; Set the app features and level
	;
found:
	pop	si
	clr	dh				;dx <- UIInterfaceLevel
	push	cs:settingsTable[di].STE_showBars
	push	dx
	mov	cx, ax				;cx <- features to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_FEATURES
	call	ObjCallInstanceNoLock
	pop	cx				;cx <- UIInterfaceLevel to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_LEVEL
	call	ObjCallInstanceNoLock
	pop	cx				;cx <- bar state

	; if we are attaching then don't change the toolbar states (so
	; that they are left the way the user set them)

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	done
	call	SetBarState
done:
	ret

StudioApplicationSetUserLevel	endm

if 0
COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationChangeUserLevel --
		MSG_STUDIO_APPLICATION_CHANGE_USER_LEVEL
						for StudioApplicationClass

DESCRIPTION:	User change to the user level

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationChangeUserLevel	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_CHANGE_USER_LEVEL

	push	si
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_APPLY
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	ret

StudioApplicationChangeUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationCancelUserLevel --
		MSG_STUDIO_APPLICATION_CANCEL_USER_LEVEL
						for StudioApplicationClass

DESCRIPTION:	Cancel User change to the user level

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationCancelUserLevel	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_CANCEL_USER_LEVEL

	mov	cx, ds:[di].GAI_appFeatures

	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	ret

StudioApplicationCancelUserLevel	endm
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationQueryResetOptions --
		MSG_STUDIO_APPLICATION_QUERY_RESET_OPTIONS
						for StudioApplicationClass

DESCRIPTION:	Make sure that the user wants to reset options

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/24/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationQueryResetOptions	method dynamic	StudioApplicationClass,
				MSG_STUDIO_APPLICATION_QUERY_RESET_OPTIONS

	; ask the user if she wants to reset the options

	push	ds:[LMBH_handle]
	clr	ax
	pushdw	axax				;SDOP_helpContext
	pushdw	axax				;SDOP_customTriggers
	pushdw	axax				;SDOP_stringArg2
	pushdw	axax				;SDOP_stringArg1
	GetResourceHandleNS	ResetOptionsQueryString, bx
	mov	ax, offset ResetOptionsQueryString
	pushdw	bxax
	mov	ax, CustomDialogBoxFlags <0, CDT_QUESTION, GIT_AFFIRMATION,0>
	push	ax
	call	UserStandardDialogOptr
	pop	bx
	call	MemDerefDS
	cmp	ax, IC_YES
	jnz	done

	mov	ax, MSG_META_RESET_OPTIONS
	call	ObjCallInstanceNoLock
done:
	ret

StudioApplicationQueryResetOptions	endm

if 0
COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationUserLevelStatus --
		MSG_STUDIO_APPLICATION_USER_LEVEL_STATUS
						for StudioApplicationClass

DESCRIPTION:	Update the "Fine Tune" trigger

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx - current selection

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/24/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationUserLevelStatus	method dynamic	StudioApplicationClass,
				MSG_STUDIO_APPLICATION_USER_LEVEL_STATUS

	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, ADVANCED_FEATURES
	jz	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
10$:
	mov	dl, VUM_NOW
	GetResourceHandleNS	FineTuneTrigger, bx
	mov	si, offset FineTuneTrigger
	call	AIE_ObjMessageSend
	ret

StudioApplicationUserLevelStatus	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationInitiateFineTune --
		MSG_STUDIO_APPLICATION_INITIATE_FINE_TUNE
						for StudioApplicationClass

DESCRIPTION:	Bring up the fine tune dialog box

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/22/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationInitiateFineTune	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_INITIATE_FINE_TUNE

	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	AIE_ObjMessageCall			;ax = features

	mov_tr	cx, ax
	clr	dx
	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	AIE_ObjMessageSend

	GetResourceHandleNS	FineTuneDialog, bx
	mov	si, offset FineTuneDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	AIE_ObjMessageSend

	ret

StudioApplicationInitiateFineTune	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationFineTune --
		MSG_STUDIO_APPLICATION_FINE_TUNE for StudioApplicationClass

DESCRIPTION:	Set the fine tune settings

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/22/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationFineTune	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_FINE_TUNE

	; get fine tune settings

	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	call	AIE_GetBooleans			;ax = new features

	mov_tr	cx, ax				;cx = new features
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	AIE_ObjMessageSend
	mov	cx, 1					;mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	AIE_ObjMessageSend
	ret

StudioApplicationFineTune	endm
endif


COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationAttach -- MSG_META_ATTACH
						for StudioApplicationClass

DESCRIPTION:	Deal with starting Studio

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx - AppAttachFlags
	dx - Handle of AppLaunchBlock, or 0 if none.
	bp - Handle of extra state block, or 0 if none.

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationAttach	method dynamic	StudioApplicationClass, MSG_META_ATTACH

	push	ax, cx, dx, si, bp

	GetResourceHandleNS	StudioEditControl, bx
	mov	si, offset StudioEditControl
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	AIE_ObjMessageSend

	; set things that are solely dependent on the UI state

	call	UserGetInterfaceOptions
	test	ax, mask UIIO_OPTIONS_MENU
	jnz	keepOptionsMenu
	GetResourceHandleNS	OptionsMenu, bx
	mov	si, offset OptionsMenu
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	AIE_ObjMessageSendNow
keepOptionsMenu:

	pop	ax, cx, dx, si, bp
	mov	di, offset StudioApplicationClass
	call	ObjCallSuperNoLock

	; get the misc settings

	push	si				; Save chunk handle
	GetResourceHandleNS	MiscSettingsList, bx
	mov	si, offset MiscSettingsList
	call	AIE_GetBooleans
	mov	es:[miscSettings], ax
	pop	dx				; Restore chunk handle
	mov	cx, ds:LMBH_handle		; ^lcx:dx <- optr for app obj
	
	;
	; Add ourselves to the clipboard notification list so we can set the
	; merge-items in the print dialog box correctly.
	;
	call	ClipboardAddToNotificationList	; Add app object to list

	; If we are not configured to have the Thesaurus then nuke it

	push	ds
	segmov	ds, cs
	mov	si, offset configureCategory
	mov	cx, cs
	mov	dx, offset noThesaurusKey
	call	InitFileReadBoolean
	pop	ds
	jc	afterThesaurus
	tst	ax
	jz	afterThesaurus

	; no thesaurus -- turn it off

	GetResourceHandleNS	StudioThesaurusControl, bx
	mov	si, offset StudioThesaurusControl
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	AIE_ObjMessageSendNow

afterThesaurus:

	; si and ds are trashed at this point

	ret

StudioApplicationAttach	endm

configureCategory	char	"configure", 0
noThesaurusKey		char	"noThesaurus", 0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach the application.

CALLED BY:	via MSG_META_DETACH
PASS:		*ds:si	= Instance
		... other args ...
RETURN:		whatever the superclass does
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationDetach	method dynamic	StudioApplicationClass, MSG_META_DETACH

	;
	; free the content file list block
	;
	clr	bx
	xchg	bx, es:contentFileList
	tst	bx
	jz	noFree
	call	MemFree
noFree:		
	;
	; Remove ourselves from the clipboard notification list
	;
	push	cx, dx				; Save info for superclass
	mov	cx, ds:LMBH_handle		; ^lcx:dx <- our object
	mov	dx, si
	call	ClipboardRemoveFromNotificationList
	pop	cx, dx				; Restore info for superclass
	;
	; Let superclass detach
	;
	mov	di, offset StudioApplicationClass
	call	ObjCallSuperNoLock
	ret
StudioApplicationDetach	endm

AppInitExit ends
