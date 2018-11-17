COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentHelp.asm

AUTHOR:		Gene Anderson, Sep 20, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT LoadCompressLibrary	Loads the compress library.

    GLB GetHelpOptions		Gets the help options.

    INT CreateHelpFile		Create the help file

    INT EnumArticlesForDocumentPages 
				Enumerate the articles in a document to
				enumerate the page

    INT EnumPagesForArticle	Callback routine to enumerate pages for one
				article

    GLB CompressData		Compresses the passed data

    GLB CompressDBItem		Compresses the passed DBItem

    INT CopyOneHelpPage		Copy one page of help to the help file

    INT AllocTempText		Allocate a temporary text object for
				copying text

    INT FreeTempText		Free the temporary text object

    INT StoreDBItemForPage	Store the DB item for a page's help text

    INT LockElementArray	Lock the name array for a file (either
				Studio doc or help)

    GLB PutupHelpBox		Displays an error box.

    INT CheckForTOCPage		Verify that there is a TOC page in the doc

    INT GetContextTypeRun	Find the type run containing a context token
    INT GetContextTypeRunCallback

    INT CheckFixHelpNames	Check (and fix if necessary) the names for
				help.

    INT CheckOneHelpName	Check a help name to see if it is short
				enough

    INT FixOneHelpName		Fix one help name by shortening it if
				necessary

    INT CheckTruncatedHelpName	See if a name in the name array conflicts
				with the passed name

    INT CopyGraphicData		Copy graphic data associated with each
				graphic element

    INT AddSpaceToNameArray	Update an older name array to have
				additional space in it for help that we
				should have allowed for earlier but in a
				fit of something or another, didn't.

    INT AddSpaceToOneName	Update one name to have extra space for
				help

    INT FixChunkArraySizes	Fix the sizes in a chunk array

    INT NukeStyleSheetRefs	Nuke any references to style sheets in an
				element array

    INT NukeOneStyleSheetRef	Nuke one style sheet reference

METHODS:
	Name			Description
	----			-----------
    StudioDocumentSetContentFileName
				Replace text in ContentFileNameText with
				name of current file.

				MSG_STUDIO_DOCUMENT_SET_CONTENT_FILE_NAME

    StudioDocumentGenerateHelpFile  
				Generate a help file from a Studio
				document

				MSG_STUDIO_DOCUMENT_GENERATE_HELP_FILE


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/20/92		Initial revision


DESCRIPTION:
	Code for creating help files.

	$Id: documentHelp.asm,v 1.1 97/04/04 14:38:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpEditCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SDSetContentFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace text in ContentFileNameText with name of current file.

CALLED BY:	MSG_STUDIO_DOCUMENT_SET_CONTENT_FILE_NAME
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
SDSetContentFileName		method dynamic StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_SET_CONTENT_FILE_NAME

		sub	sp, FileLongName
		mov	dx, sp
		mov	cx, ss
		mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
		call	ObjCallInstanceNoLock

		mov	si, offset ContentFileNameText
		call	SetText		
		add	sp, FileLongName
		ret
SDSetContentFileName		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentGenerateHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a help file from a Studio document

CALLED BY:	MSG_STUDIO_DOCUMENT_GENERATE_HELP_FILE
PASS:		*ds:si - instance data
		es - seg addr of StudioDocumentClass
		ax - the message
		cx - HFF_HELP_FILE if user wants to generate a help file
			instead of a content file
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentGenerateHelpFile		method dynamic StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_GENERATE_HELP_FILE

.warn -unref_local

documentObj	local	optr		;document object
articleObj	local	optr		;associated article object
pageCallback	local	fptr		;callback routine for each page
charCount	local	dword		;characters seen so far
nameArrayVM	local	word		;VM handle of name array
writeFile	local	hptr		;handle of Studio file
helpFile	local	hptr		;handle of help file
tempText	local	optr		;OD of temporary text object
compressLib	local	hptr
compressType	local	HelpCompressType
pageArrayVM	local	word		;VM handle of page array 
pageCount	local	word
helpFlags	local	HelpFileFlags
fileType	local	HelpFileType
helpOptions	local	HelpOptions
bitmapRes	local	word
bitmapFormat	local	BMFormat
notificationObj	local	optr		;notification dialog 
.warn @unref_local

	.enter
		
	mov	ss:compressType, HCT_NONE
	or	cx, mask HFF_CREATED_BY_STUDIO
	mov	ss:helpFlags, cx
	mov	al, HFT_HELP
	test	cx, mask HFF_HELP_FILE
	jnz	haveType
	mov	al, HFT_CONTENT
haveType:
	mov	ss:fileType, al
	call	GetHelpOptions
	cmp	ax, IC_CREATE_HELP
	LONG	jne	exit

	clr	bx
	test	dx, mask HO_COMPRESS_TEXT
	jz	noCompressLib
	call	LoadCompressLibrary
	LONG 	jc	exit
	mov	ss:compressType, HCT_PKZIP
noCompressLib:
	mov	ss:compressLib, bx
	;
	; Suspend the document and mark the app not busy
	;
	mov	bx, ds:[LMBH_handle]		;^lbx:si <- document object
	movdw	ss:documentObj, bxsi
	call	GetFileHandle			;bx <- handle of Studio file
	mov	ss:writeFile, bx
	call	SuspendAndMarkBusy

	call	CheckForTOCPage			;warn user if no TOC page
	;
	; Make sure the names are reasonable, and attempt to fix them
	; if they are not.
	;
	call	CheckFixHelpNames
	;
	; Create the help file, if possible
	;
	mov	al, ss:fileType
	call	CreateHelpFile		; dx <- file handle
					; es:di <- map block
	LONG jc	quit			; branch if error
	mov	ss:helpFile, dx
	;
	; Get the map block of the Studio file
	;
	mov	bx, ss:writeFile
	call	LockMapBlockDS			;ds <- seg addr of Studio map
	mov	ax, ss:helpFlags
	mov	es:[di].CFMB_flags, ax
	;
	; Copy all the element arrays from studio file to help file.
	;
	call	CopyElementArrays		
	mov	bx, dx				;bx <- handle of help file
	;
	; Create a temporary text object to use for copying
	; help text from Studio to the help file.
	;
	mov	ax, mask VTSF_MULTIPLE_CHAR_ATTRS or \
			mask VTSF_MULTIPLE_PARA_ATTRS or \
			mask VTSF_TYPES or \
			mask VTSF_GRAPHICS	;ah <- no regions
	call	AllocTempText
	movdw	ss:tempText, bxsi
	call	AllocPageArray		
	mov	ss:pageArrayVM, ax
	;
	; Unlock the help file map block
	;
	call	DBUnlock
	;
	; For the text, we run through each article (although
	; currently there is only one) and for each page of
	; the article, we copy the text to the help file.
	;
	clr	ss:pageCount
	mov	ss:pageCallback.segment, cs
	mov	ss:pageCallback.offset, offset CopyOneHelpPage
	call	EnumArticlesForDocumentPages
	;
	; Free the temporary text object we used for copying
	;
	lahf
	movdw	bxsi, ss:tempText
	call	FreeTempText
	;
	; Unlock the GeoWrite file map block
	;
	mov	cx, ds:MBH_totalPages
	call	VMUnlockDS
	sahf
	jc	abort		
	;
	; Now we can compress the graphics, as the text has been
	; copied to the help file and the text transfer code no longer
	; needs to access the graphics in their original form
	;
	test	ss:helpOptions, mask HO_COMPRESS_GRAPHICS
	jz	noCompressGraphics		
	call	CompressGraphicData
noCompressGraphics:		
	;
	; Add extra space the help object needs in the name array
	; and add the extra page info for content files
	;
	call	AddSpaceToNameArray
	call	AddPageInfoToNameArray
				   
abort:		
	call	FreePageArray
	;
	; Close the help document
	;
	mov	bx, ss:helpFile			;bx <- handle of help file
	mov	al, FILE_NO_ERRORS
	call	VMClose

	call	DestroyNotificationDialog
		
quit:
	mov	bx, ss:compressLib
	tst	bx
	jz	afterFree
	call	GeodeFreeLibrary
afterFree:
	movdw	bxsi, ss:documentObj
	call	MemDerefDS
	mov	bx, ss:writeFile
	call	UnsuspendAndMarkNotBusy
exit:
	.leave
	ret
StudioDocumentGenerateHelpFile		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyElementArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS:		ds - segment of MapBlockHeader
		es:di - HelpFileMapBlock
		^hbx - bindery file
		^hdx - help file

RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyElementArrays		proc	near
	.enter inherit StudioDocumentGenerateHelpFile
	;
	; For the character, paragraph, graphic and type elements,
	; we can simply copy them from the Studio document to the
	; help file
	;
	mov	ax, ds:MBH_charAttrElements	;ax <- VM block
	call	VMCopyVMBlock
	mov	es:[di].HFMB_charAttrs, ax
	call	NukeStyleSheetRefs
	mov	ax, ds:MBH_paraAttrElements	;ax <- VM block
	call	VMCopyVMBlock
	mov	es:[di].HFMB_paraAttrs, ax
	call	NukeStyleSheetRefs
	mov	ax, ds:MBH_graphicElements	;ax <- VM block
	call	VMCopyVMBlock
	mov	es:[di].HFMB_graphics, ax
	;
	; For graphics, we need to copy the graphic data, too,
	; which are VM chains associated with each element.
	;
	call	CopyGraphicData

	mov	ax, ds:MBH_typeElements		;ax <- VM block
	call	VMCopyVMBlock
	mov	es:[di].HFMB_types, ax
	mov	ax, ds:MBH_nameElements		;ax <- VM block
	call	VMCopyVMBlock
	mov	es:[di].HFMB_names, ax
	mov	es:[di].HFMB_protocolMajor, HELP_FILE_PROTO_MAJOR
	mov	es:[di].HFMB_protocolMinor, HELP_FILE_PROTO_MINOR
	mov	bl, compressType
	mov	es:[di].HFMB_compressType, bl
	mov	ss:nameArrayVM, ax
	.leave
	ret
CopyElementArrays		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadCompressLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the compress library. 
		
CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if couldn't load library
		ELSE:
			bx - handle of library
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
NEC <LocalDefNLString compressLibName <"PKware Lib",0>>
EC <LocalDefNLString compressLibName <"EC PKware Lib",0>>
else
NEC <LocalDefNLString compressLibName <"PKware Compression Library",0>>
EC <LocalDefNLString compressLibName <"EC PKware Compression Library",0>>
endif
LoadCompressLibrary	proc	near	uses	ax, bp, ds, si
	.enter
	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	segmov	ds, cs
	mov	si, offset compressLibName
	mov	ax, COMPRESS_PROTO_MAJOR
	mov	bx, COMPRESS_PROTO_MINOR
	call	GeodeUseLibrary
	call	FilePopDir
	jnc	exit
	mov	ax, 	(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	bx, offset NoCompressLibraryString
	call	PutupHelpBox
	stc
exit:
	.leave
	ret
LoadCompressLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHelpOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the help options.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - InteractionCommand
			= IC_CREATE_HELP if user wants to proceed
		bx - Resolution
		cx - BitmapFormat
		dx - HelpOptions
				
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHelpOptions	proc	near	uses	bp, si
		.enter inherit StudioDocumentGenerateHelpFile

		GetResourceHandleNS	GenerateContentFileDialog, bx
		mov	si, offset GenerateContentFileDialog
		call	UserDoDialog
		cmp	ax, IC_CREATE_HELP
		jne	abort

		push	bp
	;
	; Find out what type of compression is desired
	;
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		GetResourceHandleNS	CompressOptionsList, bx
		mov	si, offset CompressOptionsList
		call	HE_ObjMessageCall	;ax = HelpOptions
	;
	; Get the bitmap resolution
	;
		push	ax
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	si, offset BitmapResolutionItemGroup
		call	HE_ObjMessageCall
	;
	; If custom or unknown, assume custom
	;
		tst	ax			;see if custom
		jz	getValue
		cmp	ax, GIGS_NONE
		jne	haveResolution
	;
	; Ask the GenValue for the custom selection
	;
getValue:
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		mov	si, offset BitmapCustomResolutionValue
		call	HE_ObjMessageCall
		mov_tr	ax, dx			; resolution => AX

haveResolution:
	; 
	; Get the format to use for bitmaps
	;
		push	ax
		mov	si, offset BitmapFormatItemGroup
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	HE_ObjMessageCall	; ax = format
		pop	cx			; cx = resolution
		pop	dx			; dx = help options

		pop	bp
		mov	ss:bitmapFormat, al
		mov	ss:bitmapRes, cx
		mov	ss:helpOptions, dx

		mov	ax, IC_CREATE_HELP
abort:
		.leave
		ret

GetHelpOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the help file

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS:		*ds:si	= StudioDocumentClass object
		es	= seg addr of StudioDocumentClass
		al	= HelpFileType

RETURN:		carry	= set if error
		dx	= file handle of help file
		es:di	= ptr to map block

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Creates the help file and initializes the map block
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateHelpFile		proc	near
		uses	bx, cx, bp
		.enter inherit StudioDocumentGenerateHelpFile

		call	FilePushDir

		sub	sp, size FileLongName 
		mov	dx, sp
	;
	; Change to the correct directory for help/content file
	;
		call	SetDestinationDirectory
		jc	error
	;
	; get the file name
	;
		mov	cx, ss
		push	ax, cx, dx, bp
		mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
		call	ObjCallInstanceNoLock
		pop	ax, cx, dx, bp
	;
	; create the file
	;
		call	CreateFileLow			;bx <- file handle
		jc	error
	;
	; Let the user know the full path name of file we're generating
	;
		call	DisplayFileCreateNotification
		movdw	ss:notificationObj, cxdx
	;
	; Allocate and initialize the map block
	;
		mov	ax, DB_UNGROUPED		;allocate ungrouped
		mov	cx, (size HelpFileMapBlock)	;cx <- size of block
		call	DBAlloc				;allocate a map item
		call	DBSetMap			;make it the map item
		call	DBLockMap
		call	DBDirty
		mov	di, es:[di]			;es:di <- ptr to map
		push	di
		clr	al				;al <- byte to store
		rep	stosb	
		pop	di
		mov	dx, bx				;dx <- handle of file
	;
	; Return to the original directory
	;
		clc					;carry <- no error
quit:
		lahf
		add	sp, size FileLongName		
		call	FilePopDir			;preserves flags
		sahf
		
		.leave
		ret
error:
		mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		mov	bx, offset ErrorCreatingHelpFileString
		call	PutupHelpBox
		stc
		jmp	quit
		
CreateHelpFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayFileCreateNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a warning DB showing full pathname of new file.

CALLED BY:	CreateHelpFile
PASS:		*ds:si - StudioDocument
		ss:dx - filename
		path is set to file's destination directory
RETURN:		^lcx:dx - optr of Notification dialog
DESTROYED:	ax,di,es,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayFileCreateNotification		proc	near
		uses	bx, si, bp
		.enter

		push	ds:[LMBH_handle]
		
	; Make room to hold two PathNames on the stack
		
		sub	sp, size PathName * 2 

	; get current disk handle, and copy relative path to *second*
	; pathname buffer slot
		
		mov	cx, size PathName
		segmov	ds, ss, ax
		mov	es, ax
		mov	si, sp	
		add	si, cx				;ds:si <- buffer
		call	FileGetCurrentPath		;bx <- disk handle

	; contstruct the full path in the *first* filename buffer

		mov	cx, size PathName
		mov	di, sp				;es:di <- buffer
		push	dx				;save filename offset
		mov	dx, -1				;add drive letter
		call	FileConstructFullPath		;es:di <- NULL
		pop	si
		jc	done
		
	; copy filename after the full pathname.  It may run over into
	; the *second* pathname buffer, but that's okay.

SBCS <		mov	al, 0x5c					>
SBCS <		stosb							>
		LocalCopyString
		mov	di, sp				;es:di <- full name

		GetResourceHandleNS	GenerateFileNotificationTemplate, bx
		mov	si, offset GenerateFileNotificationTemplate
		call	UserCreateDialog

		push	si
		mov	si, offset NotificationText
		movdw	dxbp, esdi
		mov	ax, MSG_VIS_TEXT_APPEND_PTR
		clr	cx
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	cx, bx
		pop	dx

		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL 
		call	ObjMessage

		movdw	cxdx, bxsi			;cx:dx =  dialog optr

done:		
		add	sp, size PathName * 2
		pop	bx
		call	MemDerefDS
		.leave
		ret
DisplayFileCreateNotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyNotificationDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the notification dialog

CALLED BY:	StudioDocumentGenerateHelpFile
PASS:		inherited locals
RETURN:		nothing
DESTROYED:	lots of things

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyNotificationDialog		proc	near
		.enter inherit StudioDocumentGenerateHelpFile
		movdw	bxsi, ss:notificationObj
		call	UserDestroyDialog
		.leave
		ret
DestroyNotificationDialog		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDestinationDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the proper director for the help/content file

CALLED BY:	CreateHelpFile
PASS:		*ds:si - document
		al - HelpFileType
RETURN:		carry set if couldn't change to or create the directory
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDestinationDirectory		proc	near
		uses	ax, bx, dx, ds
		.enter

		cmp	al, HFT_HELP
		je	help

		sub	sp, size PathName
		mov	cx, ss
		mov	dx, sp				;cx:dx <- path buffer
		mov	di, offset BookPathFileSelector
		call	GetPathName
		segmov	ds, ss, ax	
		mov	bx, SP_USER_DATA
		call	FileSetCurrentPath
		add	sp, size PathName
done:
		.leave
		ret

help:
		mov	ax, SP_HELP_FILES		;ax <- StandardPath
		call	FileSetStandardPath
		jmp	done
SetDestinationDirectory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateFileLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a file in the current directory

CALLED BY:	INTERNAL
PASS:		cx:dx - file name
		al - HelpFileType
RETURN:		carry set if error creating file
		bx - file handle of *open* file
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateFileLow		proc	far
		.enter
	;
	; Create the help file
	;
		push	ax, ds
		mov	ds, cx			;ds:dx <- ptr to filename
		mov	al, mask VMAF_FORCE_DENY_WRITE
		mov	ah, VMO_CREATE_TRUNCATE
		clr	cx			;cx <- compression threshold
		call	VMOpen			;bx <- file handle
		pop	ax, ds
		jc	quit			;branch if error
	;
	; Set the token & creator to something nice
	;
		segmov	es, cs
		mov	di, offset tokenTable
		mov	cl, size TokenStruct
		clr	ah
		mul	cl
		add	di, ax				;es:di <- file token

		mov	cx, (size GeodeToken)		;cx <- size of buffer
		mov	ax, FEA_TOKEN		;ax <- FileExtendedAttribute
		call	FileSetHandleExtAttributes
		jc	quit				;branch if error

		add	di, size GeodeToken		;es:di <- file creator
		mov	ax, FEA_CREATOR		;ax <- FileExtendedAttribute
		call	FileSetHandleExtAttributes

quit:
		.leave
		ret
CreateFileLow		endp

TokenStruct	struct
    TS_token	GeodeToken
    TS_creator	GeodeToken
TokenStruct	ends
;
; Table is in this order: content file, book file, help file.
; NOTE:  Since we don't want content files to be opened directly, set
; 	 their creator token to something other than cntv.
;
tokenTable	TokenStruct 	\
	<<"cntf", MANUFACTURER_ID_GEOWORKS>,
	 <"cntf", MANUFACTURER_ID_GEOWORKS>>,
	<<"cntb", MANUFACTURER_ID_GEOWORKS>,
	 <"cntv", MANUFACTURER_ID_GEOWORKS>>,
	<<"hlpf", MANUFACTURER_ID_GEOWORKS>,
	 <"hlpv", MANUFACTURER_ID_GEOWORKS>>




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumAllArticles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the articles in a document to enumerate the page

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS:		ds - seg addr of article array
		bx:di - fptr to callback routine
		ss:bp - inherited locals
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, si, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumAllArticles		proc	far
	.enter	

	mov	si, offset ArticleArray
	call	ChunkArrayEnum			

	.leave
	ret
EnumAllArticles		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumArticlesForDocumentPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the articles in a document to enumerate the page

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS:		ds - seg addr of article array
		ss:bp - inherited locals
RETURN:		none
DESTROYED:	ax, bx, di, si, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumArticlesForDocumentPages		proc	near
	.enter	inherit	StudioDocumentGenerateHelpFile

	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset EnumPagesForArticle
	clrdw	ss:charCount
	call	ChunkArrayEnum

	.leave
	ret
EnumArticlesForDocumentPages		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumPagesForArticle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to enumerate pages for one article

CALLED BY:	StudioDocumentGenerateHelpFile() via ChunkArrayEnum()
PASS:		ds:di - ArticleArrayElement
		ss:bp - inherited locals
		    pageCallback - callback routine for each page
RETURN:		carry - set to abort
DESTROYED:	ax, bx, si, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumPagesForArticle		proc	far
	uses	di
	.enter	inherit	StudioDocumentGenerateHelpFile

	push	ds:[LMBH_handle]
	segmov	es, ds				;es <- map block

	mov	bx, ss:writeFile		;bx <- handle of VM file
	call	GetArticleMemHandle	; bx <- mem handle
	call	ObjLockObjBlock
	mov	ds, ax				;ds <- article block
	mov	bx, ds:[LMBH_handle]
	mov	ss:articleObj.handle, bx
	mov	ss:articleObj.offset, offset ArticleText
	;
	; Callback for each region / page in the article to copy it
	;
	movdw	bxdi, ss:pageCallback		;bx:di <- callback routine
	mov	si, offset ArticleRegionArray	;*ds:si <- region array
	call	ChunkArrayEnum
	;
	; Unlock the region array
	;
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	;
	; Redereference the article array block in case it moved
	;
	pop	bx				;bx <- handle of map block
	call	MemDerefDS

	clc
	.leave
	ret
EnumPagesForArticle		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompressData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compresses the passed data

CALLED BY:	GLOBAL
PASS:		ds:si - source
		es:di - dest for compacted data
		cx - # bytes in source
		bx - handle of compress library
RETURN:		cx - # bytes in compacted data (0 if error)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompressData	proc	near	uses	ax
	.enter
	push	bx
	mov	ax, CL_COMP_BUFFER_TO_BUFFER or mask CLF_MOSTLY_ASCII
	push	ax
	push	ax			;sourceFileHan (not used)
	pushdw	dssi			;sourceBuff
	push	cx			;sourceBuffSize
	push	ax			;destFileHan (not used)
	pushdw	esdi			;destBuffer

	mov	ax, enum CompressDecompress
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	pop	bx
	tst	ax
	jz	error

EC <  	call	ECLMemValidateHeap					>
EC <	push	ds							>
EC <	segmov	ds, es							>
EC <  	call	ECLMemValidateHeap					>
EC <	pop	ds							>

;	Make sure that the data uncompacts OK

	push	ax, bx, cx, dx, bp, di, si, es, ds
	push	bx, ax
	mov_tr	ax, cx			;AX <- # bytes to load
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	ds, ax
	pop	ax, cx
	push	bx			;Save handle of block
	mov_tr	bx, ax			;BX <- compress lib handle

	mov	ax, CL_DECOMP_BUFFER_TO_BUFFER or mask CLF_MOSTLY_ASCII
	push	ax
	clr	ax
	push	ax		;sourceFileHan (not used)
	pushdw	esdi		;sourceBuff
	push	cx		;sourceBuffSize
	push	ax		;destFileHan (unused)
	pushdw	dsax		;destBuffer

	mov	ax, enum CompressDecompress
	call	ProcGetLibraryEntry	
	call	ProcCallFixedOrMovable
	pop	bx
	call	MemFree
	tst	ax
	pop	ax, bx, cx, dx, bp, di, si, es, ds
	jz	uncompressError

	mov_tr	cx, ax
exit:
	.leave
	ret
uncompressError:
	mov	ax, offset BadDecompressErrorString
	jmp	errorCommon
error:
	mov	ax, offset CompressMemoryErrorString
errorCommon:
	push	bx
	mov_tr	bx, ax
	mov	ax, 	(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	PutupHelpBox
	pop	bx
	clr	cx
	jmp	exit
CompressData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompressDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compresses the passed DBItem

CALLED BY:	GLOBAL
PASS:		bx - file
		ax - handle of compression library
		cx:dx - DBItem to compress
RETURN:		cx:dx - DBItem (0 if error)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompressDBItem	proc	near		uses	ax, bx, bp, di, si, es, ds
	oldItem		local	dword	\
			push	cx, dx
	compressLib	local	hptr	\
			push	ax
	.enter
	movdw	axdi, cxdx
	call	DBLock			;
	segmov	ds, es			;*DS:SI <- data
EC <  	call	ECLMemValidateHeap					>
	mov	si, di
	mov	di, es:[si]
	ChunkSizePtr	es, di, cx
	push	cx
	mov	ax, cx
	shr	ax
	add	cx, ax			;We assume that the result will be no
					; larger than 1.5 times the original

;	Allocate an item to hold the compressed data (I don't believe that
;	the compaction code can handle compacting in place).

	mov	ax, DB_UNGROUPED
	call	DBAlloc
	pop	cx
	pushdw	axdi

	call	DBLock
EC <  	call	ECLMemValidateHeap					>
EC <	push	ds							>
EC <	segmov	ds, es							>
EC <  	call	ECLMemValidateHeap					>
EC <	pop	ds							>
	mov	di, es:[di]			;ES:DI <- dest for compression
	mov	es:[di], cx
	add	di, size word
	mov	si, ds:[si]			;DS:SI <- uncompressed data
						;CX has size of uncmprsd data

;	Compress the data 

	push	bx				;Save file handle
	mov	bx, compressLib
	call	CompressData			;CX <- size of compacted data
	pop	bx				;Restore file handle

EC <  	call	ECLMemValidateHeap					>
EC <	push	ds							>
EC <	segmov	ds, es							>
EC <  	call	ECLMemValidateHeap					>
EC <	pop	ds							>

	add	cx, size word			;Add the size word we put
						; at the start
;	Now that we've made a compacted copy of the data, free the old
;	DBItem.

	call	DBUnlock
	segmov	es, ds
	call	DBUnlock			;Unlock/free old item
	movdw	axdi, oldItem
	call	DBFree

;	Re-allocate the DBItem to be exactly as large as the compressed data.

	popdw	axdi				;
	cmp	cx, size word			;If error returned from 
						; CompressData, branch
	je	compressError					
	call	DBReAlloc			;
	movdw	cxdx, axdi			;CX.DX <- DB Item
exit:
	.leave
	ret
compressError:
	call	DBFree
	clrdw	cxdx
	jmp	exit
CompressDBItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyOneHelpPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one page of help to the help file

CALLED BY:	EnumPagesForArticle() via ChunkArrayEnum()

PASS:		ds:di - ptr to VisLargeTextRegionArrayElement
		ss:bp - inherited locals
RETURN:		carry - set to abort
DESTROYED:	ax, bx, cx, si, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: pages that do not have a page name character
	be ignored and will not be copied into the help document.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/21/92		Initial version
	cassie	11/3/94		broke out CopyText

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyOneHelpPage		proc	far
	uses	dx
	.enter	inherit	EnumPagesForArticle

	movdw	cxdx, ss:charCount		;dx:cx <- current pos in text
	adddw	ss:charCount, ds:[di].VLTRAE_charCount, ax
	mov	bx, ds:[di].VLTRAE_flags	;bx <- VisLargeTextRegionFlags
	test	bx, mask VLTRF_EMPTY		;empty page?
	LONG jnz	quit			;branch if empty page
	;
	; If there is no context for the start of the page, quit
	;
	call	GetPageType
	cmp	ax, -1				;any context?
	LONG jz	quit				;branch if no type
	call	StorePageToken
	push	ax				;save type token
	;
	; Copy the text for the page
	;
	call	CopyText			;^lbx:si <- temp text
	;
	; We don't want the hyperlinks in the content file to have
	; boxes around them, so clear the hyperlink style.
	;
CheckHack <FALSE eq 0>
	clr	cx
	call	ToggleShowHyperlinkStyle
	;
	; Delete all page name graphics, one at a time.  Loop until
	; no more are found in the copied page.
	;
$10:		
	call	DeleteVariableGraphics		;carry set if found one
	jc	$10				;loop while more 
	;
	; Store the text and runs into the help file
	;
	push	bp
	clrdw	cxdx				;cx:dx <- alloc DBItem
	mov	bp, mask VTSDBF_TEXT or \
			(VTST_RUNS_ONLY shl offset VTSDBF_CHAR_ATTR) or \
			(VTST_RUNS_ONLY shl offset VTSDBF_PARA_ATTR) or \
			(VTST_RUNS_ONLY shl offset VTSDBF_TYPE) or \
			(VTST_RUNS_ONLY shl offset VTSDBF_GRAPHIC)
	mov	ax, MSG_VIS_TEXT_SAVE_TO_DB_ITEM
	call	HE_ObjMessageCall
	pop	bp
	
	mov	bx, ss:helpFile
	mov	ax, ss:compressLib
	tst	ax
	jz	noCompress
	call	CompressDBItem
	jcxz	popExit			;If error compressing, exit
noCompress:	
	;
	; Save the DB item of this page into the appropriate name entry
	; cx:dx - DBGroupAndItem
	; ax - name token for page
	;
	pop	ax				;ax <- name token for page
	call	StoreDBItemForPage

	mov	bx, ss:helpFile
	call	VMUpdate		
quit:
	inc	ss:pageCount
	clc					;carry <- don't abort
exit:
	.leave
	ret
popExit:
	pop	ax
	stc
	jmp	exit

CopyOneHelpPage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from the Bindery document to the help file's
		temporary text object.

CALLED BY:	CopyOneHelpPage
PASS:		cx.dx - range start
		ss:charCount - # of chars on page
		bx - VisLargeTextRegionFlags
		locals inherited from StudioDocumentGenerateHelpFile

RETURN:		^lbx:si - temp text
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyText		proc	near
	uses	bp
	.enter inherit StudioDocumentGenerateHelpFile

	sub	sp, (size CommonTransferParams)
	mov	di, sp				;ss:di <- ptr to params
	movdw	ss:[di].CTP_range.VTR_start, cxdx
	movdw	ss:[di].CTP_range.VTR_end, ss:charCount, ax
	;
	; See if the page ends in a column break -- if so adjust the range
	; by one so we don't try to copy the column break.
	;
	test	bx, mask VLTRF_ENDED_BY_COLUMN_BREAK
	jz	noBreak				;branch if no break
	decdw	ss:[di].CTP_range.VTR_end
noBreak:
	mov	ax, ss:helpFile
	mov	ss:[di].CTP_vmFile, ax		;pass VM file
	clr	ss:[di].CTP_pasteFrame		;not quick paste
	mov	ax, MSG_VIS_TEXT_CREATE_TRANSFER_FORMAT	
	call	CallArticle			;ax <- transfer VMBlock
	;
	; Paste it into the temporary text object
	;
	movdw	bxsi, ss:tempText		;^lbx:si <- OD of temp text
	mov	bp, di				;ss:bp <- ptr to params
	mov	ss:[bp].CTP_vmBlock, ax
	clrdw	ss:[bp].CTP_range.VTR_start
	movdw	ss:[bp].CTP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
	call	HE_ObjMessageCall
	;
	; Free the transfer item, lest the file fill with cruft...
	;
	push	bx
	mov	bx, ss:[bp].CTP_vmFile		;bx <- help file handle
	mov	ax, ss:[bp].CTP_vmBlock
	clr	bp				;ax:bp <- VM chain for transfer
	call	VMFreeVMChain
	pop	bx
	add	sp, (size CommonTransferParams)

	.leave
	ret
CopyText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToggleShowHyperlinkStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set or clear the hyperlink style in a text object

CALLED BY:	INTERNAL	CopyOneHelpPage()

PASS:		^lbx:si - temp text object
		cx	= TRUE to show, FALSE to stop showing

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToggleShowHyperlinkStyle	proc	near
		uses	si, bp		
		.enter 
	;
	; We want to set the hyperlinks in the whole article to be
	; either boxed and unboxed. Start setting up the stack.
	;
		mov	dx, (size VisTextSetTextStyleParams)
		sub	sp, dx
		mov	bp, sp		; ss:bp <- params
		clr	ax
		mov	ss:[bp].VTSTSP_range.VTR_start.high, ax
		mov	ss:[bp].VTSTSP_range.VTR_start.low, ax
		movdw	ss:[bp].VTSTSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	;
	; Leave the TextStyle alone, whatever it may be. We're
	; interested in the extended style only.
	;
		mov	ss:[bp].VTSTSP_styleBitsToSet, ax
		mov	ss:[bp].VTSTSP_styleBitsToClear, ax
	;
	; Assume we're going to show the hyperlinks; then check if
	; that's true.
	;
		mov	ss:[bp].VTSTSP_extendedBitsToSet, mask VTES_BOXED 
		mov	ss:[bp].VTSTSP_extendedBitsToClear, ax
		cmp	cx, TRUE
		je	showHyperlinks
		mov	ss:[bp].VTSTSP_extendedBitsToSet, ax
		mov	ss:[bp].VTSTSP_extendedBitsToClear, mask VTES_BOXED
showHyperlinks:
	;
	; Set the style.
	;
		mov	ax, MSG_VIS_TEXT_SET_HYPERLINK_TEXT_STYLE
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage
		add	sp, (size VisTextSetTextStyleParams)

		.leave
		ret
ToggleShowHyperlinkStyle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteVariableGraphics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all variable graphics from tempText

CALLED BY:	CopyOneHelpPage
PASS:		^lbx:si - tempText
RETURN:		nothing
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/20/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteVariableGraphics		proc	near
		uses	bp, si, ds
		.enter	inherit StudioDocumentGenerateHelpFile

	;
	; Lock the temp text's object block 
	;
		call	ObjLockObjBlock
		mov	ds, ax				;*ds:si <- text object

		push	bp
		mov	bx, ss:helpFile
		call	DBLockMap
		mov	di, es:[di]
		mov	ax, es:[di].HFMB_graphics
		call	DBUnlock
		call	VMLock
		mov	es, ax
		pop	bp
		
		mov	ax, ATTR_VIS_TEXT_GRAPHIC_RUNS		
		call	ObjVarFindData
EC <		ERROR_NC GRAPHIC_RUNS_NOT_FOUND				>
		mov	si, {word}ds:[bx]	;*ds:si <- run array
	;
	; Pass inherited locals and locked element array to callback.
	; It returns carry set if it found a page name graphic
	;
		mov	bx, cs
		mov	di, offset DeleteThisPageNameGraphic
		call	ChunkArrayEnum		;cx.dx <- position of graphic
		call	VMUnlockES		;unlock element array
		jnc	done
	;
	; Tell temp text object to delete that char
	;
		movdw	bxsi ss:tempText
		push	bp
		mov	ax, dx
		mov	dx, size VisTextReplaceParameters
		sub	sp, dx
		mov	bp, sp
		movdw	ss:[bp].VTRP_range.VTR_start, cxax
		incdw	cxax
		movdw	ss:[bp].VTRP_range.VTR_end, cxax
		movdw	ss:[bp].VTRP_insCount, 0
		mov	ss:[bp].VTRP_flags, 0

		mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		add	sp, size VisTextReplaceParameters
		pop	bp
		stc
done:
		mov	bx, ss:tempText.high
		call	MemUnlock		;unlock temp text block

		.leave
		ret
DeleteVariableGraphics		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteThisPageNameGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	DeleteVariableGraphics (via ChunkArrayEnum)
PASS:		ds:di - TextRunArrayElement
		es - segment of graphic element array
		bp - inherited locals frame pointer
RETURN:		cx.dx - text position of variable graphic
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteThisPageNameGraphic		proc	far
		.enter inherit StudioDocumentGenerateHelpFile

		mov	bx, ds:[di].TRAE_token
		call	IsGraphicAPageNameGraphic
		cmc
		jnc	continue		;it's not a page name graphic
	;
	; Get the position of the char
	;
		clr	ch
		mov	cl, ds:[di].TRAE_position.WAAH_high
		mov	dx, ds:[di].TRAE_position.WAAH_low
		stc				;stop enumerating
continue:
		.leave
		ret
DeleteThisPageNameGraphic		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the type token for the page which starts at
		the passed text offset 

CALLED BY:	CopyOneHelpPage, 
PASS:		ss:bp - inherited locals
		cx.dx - text offset
RETURN:		ax - token for page
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPageType		proc	near
		.enter	inherit	EnumPagesForArticle

		sub	sp, size VisTextRange
		mov	di, sp
		movdw	ss:[di].VTR_start, cxdx
		mov	ax, MSG_STUDIO_ARTICLE_GET_PAGE_NAME
		call	CallArticle		;ax <- page name token
		add	sp, size VisTextRange
		.leave
		ret
GetPageType		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallArticle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls article text with parameters passed on stack

CALLED BY:	CopyOneHelpPage, GetTextType
PASS:		ss:bp - inherited locals
		ss:di - message params
RETURN:		ax - depends on message
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallArticle		proc	near
		uses	bx,si,cx,dx,bp,di
		.enter	inherit	EnumPagesForArticle

		movdw	bxsi, ss:articleObj
		mov	bp, di			;di <- ptr to message params
		call	HE_ObjMessageCall
		.leave
		ret
CallArticle		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocTempText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a temporary text object for copying text

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS: 		al - VisTextStorageFlags for object
		ah - non-zero to create regions for object
		bx - help file to associate object with
		es:di - ptr to map block of help file

RETURN: 	^lbx:si - VisTextObject to use

DESTROYED: 	none

PSEUDO CODE/STRATEGY:

	NOTE: A *very* important step here is attaching the the
	element arrays in the help file to the text object.
	Without this, the tokens used in the run arrays for the text
	as it is copied would be adjusted to be relative to the
	transfer item.  This means they wouldn't match the element
	arrays we had copied to the help file, which would be bad.

	NOTE: Related to the above is another important item.
	There are two copies of each of the element arrays, one in
	the Studio document, and one if the help file.  We attach
	the temporary text object to the ones in the help file, not
	the Studio document, because the act of pasting into it
	will be incrementing the reference counts on the various elements.
	We could correct this by deleting the text from the temporary
	text object when we are done, but this has the negatives of
	(a) wasting a bit of time (b) dirtying the Studio file

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocTempText		proc	near
	uses	ax, cx, dx, bp
	.enter

	push	ax				;save storage flags
	push	bx				;save passed file
	;
	; allocate object in a new block
	;
	mov	ax, TGIT_THREAD_HANDLE
	clr	bx
	call	ThreadGetInfo			;ax <- current thread
	mov_tr	bx, ax
	call	UserAllocObjBlock		;bx <- block

	push	es, di
	mov	di, segment VisTextClass
	mov	es, di
	mov	di, offset VisTextClass
	call	ObjInstantiate			;bx:si <- object
	pop	es, di
	;
	; associate the object with the passed file
	;
	pop	cx				;cx <- passed file
	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	call	objMessageSend
	;
	; make appropriate structures
	;
	pop	cx				;cl, ch <- VisTextStorageFlags
	mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
	call	objMessageSend
	;
	; Connect the various attribute arrays
	; NOTE: the order is important -- the names must be done first
	; NOTE: see vTextC.def for details
	;
	mov	ch, TRUE			;ch <- handles are VM
	clr	bp				;bp <- use 1st element
	mov	ax, MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY

	mov	dx, es:[di].HFMB_names		;dx <- VM handle of names
	mov	cl, VTSF_NAMES
	call	objMessageSend
	mov	dx, es:[di].HFMB_charAttrs	;dx <- VM handle of char attrs
	mov	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	call	objMessageSend
	mov	dx, es:[di].HFMB_paraAttrs	;dx <- VM handle of para attrs
	mov	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	call	objMessageSend
	mov	dx, es:[di].HFMB_graphics	;dx <- VM handle of graphics
	mov	cl, mask VTSF_GRAPHICS
	call	objMessageSend
	mov	dx, es:[di].HFMB_types		;dx <- VM handle of types
	mov	cl, mask VTSF_TYPES
	call	objMessageSend

	.leave
	ret

objMessageSend:
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	retn
AllocTempText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeTempText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the temporary text object

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS:		^lbx:si - OD of temp
RETURN:		none
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeTempText		proc	near
	.enter

	call	MemFree

	.leave
	ret
FreeTempText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocPageArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and intialize the page array VMBlock

CALLED BY:	WriteDocumentGenerateHelpFile
PASS: 		inherited variables
RETURN:		ax - VMBlock handle of page array in Help File
DESTROYED:	nothing
		
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocPageArray		proc	near
		uses	bx, cx, si, es
		.enter inherit StudioDocumentGenerateHelpFile

		mov	bx, ss:helpFile
		mov	cx, ds:MBH_totalPages		
		shl	cx				;#bytes = #pages * 2
		mov	ax, 0				;no ID
		call	VMAlloc				;ax <- VMBlock handle
	;
	; initialize page array with -1 (no token)
	;
		push	ax, bp
		call	VMLock
		mov	es, ax
		clr	di				;es:di <- 1st element
		shr	cx				;cx <- # words
		mov	ax, -1
		rep	stosw

		call	VMUnlock
		pop	ax, bp
		
		.leave
		ret
AllocPageArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreePageArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the page array VM block

CALLED BY:	StudioDocumentGenerateHelpFile
PASS:		ss:bp - inherited locals
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreePageArray		proc	near
		.enter inherit	StudioDocumentGenerateHelpFile
		mov	bx, ss:helpFile
		mov	ax, ss:pageArrayVM
		call	VMFree
		.leave
		ret
FreePageArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreDBItemForPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the DB item for a page's help text

CALLED BY:	CopyOneHelpPage()
PASS:		ss:bp - inherited locals
		cx:dx - DBGroupAndItem for text
		ax - name token for page
RETURN:		none
DESTROYED:	bx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreDBItemForPage		proc	near
	uses	ds, bp
	.enter	inherit CopyOneHelpPage

	push	ax				;save name token
	;
	; Lock the name array
	;
	mov	bx, ss:helpFile			;bx <- handle of help file
	mov	ax, ss:nameArrayVM		;ax <- VM handle of names
	call	LockElementArray
	pop	ax				;ax <- name token
	;
	; Get a pointer to the name entry and stuff the DB item and group.
	;
	push	cx
	call	ChunkArrayElementToPtr		;ds:di <- ptr to element
	pop	ds:[di].VTNAE_data.VTND_helpText.DBGI_group
	mov	ds:[di].VTNAE_data.VTND_helpText.DBGI_item, dx
	;
	; Mark the name array as dirty and unlock it
	;
	call	VMDirty
	call	VMUnlock

	.leave
	ret
StoreDBItemForPage		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StorePageToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store token for this page in page array 

CALLED BY:	CopyOneHelpPage
PASS:		ax - context token for page
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StorePageToken		proc	near
		uses	ax, bx, cx, si, ds, bp
		.enter	inherit CopyOneHelpPage

		push	ax
		mov	bx, ss:helpFile
		mov	ax, ss:pageArrayVM
		mov	cx, ss:pageCount	; get page # (count from 0)
		call	VMLock
		mov	ds, ax
		clr	si
		shl	cx			; page * 2 = array index
		add	si, cx
		pop	ds:[si]			; store token number
		call	VMUnlock
		
		.leave
		ret
StorePageToken		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockElementArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the name array for a file (either Studio doc or help)

CALLED BY:	UTILITY
PASS:		bx - handle of file
		ax - VM handle of name array
RETURN:		*ds:si - name array
		bp - memory handle of VM block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockElementArray		proc	near
	uses	ax
	.enter

	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK	;*ds:si <- name array

	.leave
	ret
LockElementArray		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutupHelpBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays an error box.

CALLED BY:	GLOBAL
PASS:		ax - CustomDialogBoxFlags
		bx - chunk handle of string in StringsUI
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutupHelpBox	proc	far	uses	bp, cx, dx
		.enter
		clr	cx			;no custom triggers
		mov	dx, ax			;dx <- flags
		mov	ax, bx			;ax <- string chunk
		call	ComplexQuery
		.leave
		ret
PutupHelpBox	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForTOCPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there is a page named TOC anywhere in the document.

CALLED BY:	StudioDocumentGenerateHelpFile
PASS:		*ds:si - StudioDocument
RETURN:		carry clear if this content file has no TOC page
		(carry is always set for non HFT_CONTENT files)
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString TOCString <"TOC",0>
CheckForTOCPage		proc	near
		uses	si, ds
		.enter inherit StudioDocumentGenerateHelpFile
	;
	; We're only concerned about content files
	;
		cmp	ss:fileType, HFT_CONTENT
		stc
		jne	done
	;
	; Get the names array
	;
		mov	bx, ss:writeFile
		call	LockMapBlockES
		mov	ax, es:MBH_nameElements		;ax <- VMblock of names
		call	VMUnlockES			;unlock map block
		push	bp
		call	LockElementArray		;*ds:si <- name array
		pop 	bp
	;
	; Check if TOC name exists
	;
		segmov	es, cs, ax
		mov	di, offset TOCString		;es:di <- name to find
		clr	cx, dx				;cx <- null terminated,
							;dx - don't return data
		call	NameArrayFind			;ax <- name token
		call	VMUnlockDS			;unlock name array
		jnc	warning				;carry set if found
	;
	; Now see if there is a context type run containing this token
	;
		movdw	bxsi, ss:documentObj
		call	MemDerefDS
		call	LockMapBlockDS
		mov	cx, ax				;cx <- TOC token
		mov	bx, cs
		mov	di, offset GetContextTypeRun	;bx:di <- callback
		call	EnumAllArticles
		call	VMUnlockDS			;unlock map block
		jc	done				;carry set if found
warning:
		mov	ax, (CDT_WARNING shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		mov	bx, offset WarningNoTOCPageString
		call	PutupHelpBox
done:
		.leave
		ret
CheckForTOCPage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContextTypeRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the section & page number for the context referred to
		by the graphic.

CALLED BY:	(INTERNAL)
PASS:		ds:di	= ArticleArrayElement
		cx 	= token to find
RETURN:		carry set if found
DESTROYED:	ax, bx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContextTypeRun	proc	far
		uses	cx, ds, si
		.enter inherit StudioDocumentGenerateHelpFile
	;
	; Get the article object
	;
		mov	bx, ss:writeFile	
		call	GetArticleMemHandle	; bx <- mem handle
		call	ObjLockObjBlock
		mov	ds, ax	
		mov	si, offset ArticleText		;*ds:si <- Article obj
	;
	; Find the type run array.
	; 
		mov	ax, ATTR_VIS_TEXT_TYPE_RUNS
		call	ObjVarFindData
EC <		ERROR_NC	MUST_HAVE_TYPE_RUNS_TO_USE_CONTEXT_VARS	>
   		mov	ax, ds:[bx]	; ax <- run array, for getting elt
		mov	dx, ax		; dx <- run array, for passing to HAE
	;
	; Lock down the run array so we can get to the element block
	; 
		mov	bx, ss:writeFile
		push	bp
		call	VMLock
		mov	es, ax
		mov	ax, es:[TLRAH_elementVMBlock]
		call	VMUnlock

		call	VMLock		; lock down the element block
		mov	es, ax
		pop	bp
	;
	; Now set up the args for HugeArrayEnum to find the run with the
	; graphic's context token.
	; 
		push	bx		; file handle
   		push	dx		; run array handle
		push	cs
		mov	ax, offset GetContextTypeRunCallback
		push	ax		; callback
		clr	ax		; start w/first element
		push	ax, ax
		dec	ax		; and process all of them
		push	ax, ax

		call	HugeArrayEnum	; carry set if found

		call	VMUnlockES	; unlock element block
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock	; unlock article object
		.leave
		ret
GetContextTypeRun	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContextTypeRunCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the given element is for the token we're after

CALLED BY:	(INTERNAL) GetContextTypeRun via HugeArrayEnum
PASS:		ds:di	= TextRunArrayElement
		es	= segment of element array block
		cx	= context token for which we seek
RETURN:		carry set to stop (found the run):
		carry clear to keep going
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContextTypeRunCallback proc	far
		uses	ds, si
		.enter

		mov	bx, ds:[di].TRAE_token
	;
	; Hacked optimization of ChunkArrayElementToPtr for type run...
	; bx	= element #
	; 
		segmov	ds, es
		mov	si, ds:[LMBH_offset]
		mov	si, ds:[si]
EC <		cmp	ds:[si].CAH_elementSize, 10			>
EC <		ERROR_NE	TYPE_ELEMENTS_NOT_10_BYTES_LONG		>
		shl	bx		; *2
		mov	ax, bx
		shl	bx		; *4
		shl	bx		; *8
		add	bx, ax		; *10
		add	bx, ds:[si].CAH_offset	; bx <- offset from base of
						;  chunk array
		cmp	cx, ds:[si][bx].VTT_context
		clc
		jne	done
		stc			; stop enumerating
done:
		.leave
		ret
GetContextTypeRunCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFixHelpNames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check (and fix if necessary) the names for help.

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS:		*ds:si - instance of StudioDocument object
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFixHelpNames		proc	near
	uses	ax, bx, cx, dx, ds, si, di, bp
	.enter

	;
	; Get the names array
	;
	call	GetFileHandle			;bx <- handle of file
	call	LockMapBlockDS
	mov	ax, ds:MBH_nameElements		;ax <- VM block of names
	call	VMUnlockDS
	call	LockElementArray		;*ds:si <- name array
	;
	; For each name, see if is too long.
	;
	mov	bx, cs
	mov	di, offset CheckOneHelpName	;bx:di <- callback
	call	ChunkArrayEnum
	jnc	done				;branch if names OK
	;
	; Put up an annoying box telling AndrewC the problem and
	; giving him the option to try to correct the names.
	;
	mov	ax,	(CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	mov	bx, offset HelpNamesTooLongString
	call	PutupHelpBox

	cmp	ax, IC_YES			;update names?
	jne	done				;branch if not updating
	;
	; For each name, truncate it to the legal maximum
	;
	mov	bx, cs
	mov	di, offset FixOneHelpName	;bx:di <- callback
	call	ChunkArrayEnum
	;
	; Finally, mark the name array as dirty to record our changes
	;
	call	VMDirtyDS
done:
	call	VMUnlockDS

	.leave
	ret
CheckFixHelpNames		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckOneHelpName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a help name to see if it is short enough

CALLED BY:	CheckFixHelpNames() via ChunkArrayEnum()
PASS:		*ds:si - name array
		ds:di - current VisTextNameArrayElement
RETURN:		carry - set if name is too long
		    ax - element # that is too large
		    cx - length of name (w/o NULL)
		    dx - legal maximum for element
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckOneHelpName		proc	far
	.enter

	;
	; Make sure this element is in use
	;
	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	emptyElement
	;
	; Figure out what the maximum is based on the type
	;
	mov	dx, FILE_LONGNAME_LENGTH	;dx <- assume filename
	cmp	ds:[di].VTNAE_data.VTND_type, VTCT_FILE
	je	isFile
	mov	dx, MAX_CONTEXT_NAME_SIZE	;dx <- context name
isFile:
	;
	; See how long the name actually is
	;
	call	ChunkArrayPtrToElement		;ax <- element #
	call	ChunkArrayElementToPtr		;cx <- size of element
	sub	cx, (size VisTextNameArrayElement)
DBCS <	shr	cx, 1				;cx <- length>
	cmp	cx, dx				;name too large?
	ja	nameTooLarge			;branch if too large
emptyElement:
	clc					;carry <- name OK
done:

	.leave
	ret

nameTooLarge:
	stc					;carry <- name too large
	jmp	done
CheckOneHelpName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixOneHelpName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix one help name by shortening it if necessary

CALLED BY:	CheckFixHelpNames() via ChunkArrayEnum()
PASS:		*ds:si - name array
		ds:di - current VisTextNameArrayElement
RETURN:		carry - set to abort
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixOneHelpName		proc	far
	uses	es
SBCS <nameBuffer	local	NAME_ARRAY_MAX_NAME_SIZE dup (char)	>
DBCS <nameBuffer	local	NAME_ARRAY_MAX_NAME_SIZE/2 dup (wchar)	>
	.enter

	;
	; See if the name is OK
	;
	call	CheckOneHelpName		;name OK?
	jnc	done				;branch if name OK
	;
	; Copy the name to a local variable for ease of use
	;
	push	si, di, cx
	lea	si, ds:[di][(size VisTextNameArrayElement)]
	segmov	es, ss
	lea	di, ss:nameBuffer		;es:di <- dest
	LocalCopyNString			;copy cx chars
	clr	cx
	LocalPutChar esdi, cx, NO_ADVANCE	;NULL terminate me jesus
	pop	si, di, cx
	;
	; The name is too long -- see if the truncated version
	; will conflict with another name.
	;
	mov	cx, ax				;cx <- element # for nameBuffer
	mov	bx, cs
	mov	di, offset CheckTruncatedHelpName
	call	ChunkArrayEnum
	jc	nameNoTruncate
	;
	; Whee!  Truncating the name won't cause a problem, so do it!
	;	cx = token of current name
	;	dx = maximum length allowed for current name
	;	*ds:si = name array
	;
	lea	di, ss:nameBuffer		;es:di <- new name
	mov	ax, cx				;ax <- token for name
	mov	cx, dx				;cx <- length of name
	call	NameArrayChangeName
done:
	clc					;carry <- don't abort
	.leave
	ret

	;
	; The name could not be truncated because it would
	; conflict with another name.  Put up an annoying box
	; telling AndrewC which name couldn't be truncated.
	;
nameNoTruncate:
	push	ds, si, di, bp
	mov	si, offset NameCannotTruncateString
	lea	di, ss:nameBuffer		;ss:di <- ptr to name
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		    (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	DoStandardDialog
	pop	ds, si, di, bp
	jmp	done
FixOneHelpName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTruncatedHelpName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a name in the name array conflicts with the passed name

CALLED BY:	FixOneHelpName() via ChunkArrayEnum()
PASS:		*ds:si - name array
		ds:di - current VisTextNameArrayElement
		ss:bp - inherited locals
			nameBuffer - name to check against
		cx - element # that nameBuffer represents
		dx - maximum length nameBuffer can be
RETURN:		carry - set if name conflicts
DESTROYED:	si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckTruncatedHelpName		proc	far
	uses	ax, cx, dx
	.enter	inherit	FixOneHelpName

	;
	; Make sure this element is in use.  If not, this element
	; obviously doesn't conflict...
	;
	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	nameOK
	;
	; Make sure the name we're looking at isn't our original name
	;
	call	ChunkArrayPtrToElement		;ax <- current element #
	cmp	ax, cx				;same element?
	je	nameOK				;branch if same element
	;
	; See if the name would conflict -- use the length of the
	; current name as the maximum to compare.  The name in nameBuffer
	; is NULL terminated, so LocalCmpStrings() will do the right thing
	; when comparing it...
	;
	call	ChunkArrayElementToPtr
	sub	cx, (size VisTextNameArrayElement)
DBCS <	shr	cx, 1				;cx <- length>
	cmp	cx, dx				;names different length?
	jb	nameOK				;OK if current name shorter
	lea	si, ds:[di][(size VisTextNameArrayElement)]
	segmov	es, ss
	lea	di, ss:nameBuffer		;es:di <- name #2
	call	LocalCmpStrings
	stc					;carry <- assume conflict
	je	done				;branch if conflict
nameOK:
	clc					;carry <- no conflict
done:
	.leave
	ret
CheckTruncatedHelpName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyGraphicData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy graphic data associated with each graphic element

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS:		bx - handle of Studio file
		dx - handle of help file
		ds - seg addr of MapBlockHeader for Studio document
		es:di - ptr to HelpFileMapBlock
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyGraphicData		proc	near
	uses	cx, si, di, ds, es, bp
	.enter

	call	DiscardAllGraphicVMChains	;ds:si <- 1st element
	jcxz	unlockExit			;cx <- # elements
	;
	; Lock the graphic elements in the help file
	;
	push	bx
	mov	bx, dx				;bx <- handle of help file
	mov	ax, es:[di].HFMB_graphics
	call	VMLock
	mov	es, ax
	mov	di, es:[VM_ELEMENT_ARRAY_CHUNK]
EC <	cmp	es:[di].CAH_elementSize, (size VisTextGraphic) 	>
EC <	ERROR_NE FAILED_ASSERTION_GENERATING_HELP_FILE 		>
	pop	bx

EC <	cmp	cx, es:[di].CAH_count		;		>
EC <	ERROR_NE FAILED_ASSERTION_GENERATING_HELP_FILE >
	;
	; For each graphics element, copy the graphic data chain
	;
	add	di, es:[di].CAH_offset		;es:di <- ptr to 1st element
copyGraphicsLoop:
	cmp	ds:[si].VTG_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	nextElement			;branch if unused element
	movdw	axbp, ds:[si].VTG_vmChain	;ax:bp <- VM chain
	tst	ax				;any chain?
	jz	nextElement			;branch if no chain
	call	VMCopyVMChain
	movdw	es:[di].VTG_vmChain, axbp	;store copied chain
	;
	; Discard the VMChain in the Bindery document, to free its handle
	;
	mov	ax, ds:[si].VTG_vmChain.high
	call	DiscardVMChain

nextElement:
	add	si, (size VisTextGraphic)
	add	di, (size VisTextGraphic)
	loop	copyGraphicsLoop		;loop while more elements
	;
	; Dirty and unlock the graphic elements in the help file
	;
	call	VMDirtyES
	call	VMUnlockES
unlockExit:
	;
	; Done with the graphic elements in the Studio file
	;
	call	VMUnlockDS

	.leave
	ret
CopyGraphicData		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscardAllGraphicVMChains
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		ds - Studio document map block header
		^hbx - Studio file
RETURN:		ds:si - first graphic element
		cx - number of elements
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscardAllGraphicVMChains		proc	near
	.enter
	;
	; Lock the graphic elements in the Studio document
	;
	mov	ax, ds:MBH_graphicElements	;ax <- VM handle of graphics
	call	LockElementArray
	mov	si, ds:[si]			;ds:si <- graphic elements
	mov	cx, ds:[si].CAH_count
EC <	cmp	ds:[si].CAH_elementSize, (size VisTextGraphic) >
EC <	ERROR_NE FAILED_ASSERTION_GENERATING_HELP_FILE	       >
	;
	; For each graphics element, copy the graphic data chain
	;
	add	si, ds:[si].CAH_offset		;ds:si <- ptr to 1st element
	jcxz	done
	push	cx, si
copyGraphicsLoop:
	cmp	ds:[si].VTG_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	nextElement			;branch if unused element
	mov	ax, ds:[si].VTG_vmChain.high	;ax <- VM block
	tst	ax				;any chain?
	jz	nextElement			;branch if no chain
	call	DiscardVMChain			;discard the chain
nextElement:
	add	si, (size VisTextGraphic)
	loop	copyGraphicsLoop		;loop while more elements
	pop	cx, si		
done:
	.leave
	ret
DiscardAllGraphicVMChains		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscardVMChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discards the blocks of a VM chain and frees up the handles.

CALLED BY:	GLOBAL

PASS:		bx	= vm file handle of vm chain to discard
		ax	= vm block handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- Walk the VM chain, freeing the memory handle for each block.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	8/24/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscardVMChain	proc	near
		uses	ax,bx,cx,dx,di,bp,ds
		.enter
freeLoop:
	;
	;  Lock the block & get the handle of the NEXT block.
	;
		mov	cx, ax			; cx = current vm block handle
		call	VMLock			; ax = segment
		mov	ds, ax
		mov	dx, ds:[VMCL_next]	; dx = handle of next block
		call	VMUnlock
	;
	;  Detach the memory block from the VM block.
	;
		mov_tr	ax, cx			; ax = current vm block handle
		clr	cx			; our geode owns it
		call	VMDetach		; di = memory handle
	;
	;  Free the memory block.
	;
		xchg	bx, di			; bx = mem handle
		call	MemFree
		xchg	bx, di			; bx = vm file handle

		mov	ax, dx			; ax = next VM block
		tst	ax
		jnz	freeLoop
doneLoop::
		.leave
		ret
DiscardVMChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompressGraphicData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compress the gstring associated with each graphic element
		in the help file

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS:		inherited variables
RETURN:		none
DESTROYED:	ax, bx, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompressGraphicData		proc	near
	uses	cx, dx, si, di, bp
	.enter	inherit	StudioDocumentGenerateHelpFile

	;
	; Update the file so that all dirty blocks are written to file,
	; then put the file into backup mode, so that no compression
	; is done in the process of compressing graphics.  Saves a lot
	; of time...
	;
	mov	bx, ss:helpFile
	call	VMUpdate
	clr 	ah
	mov	al, mask VMA_BACKUP		
	call	VMSetAttributes
		
	call	DBLockMap
	mov	di, es:[di]
	mov	ax, es:[di].HFMB_graphics
	call	DBUnlock			;unlock map block
	;
	; Lock the graphic elements in the help file
	;
	push	bp
	call	VMLock
	pop	bp
	mov	ds, ax
	mov	si, ds:[VM_ELEMENT_ARRAY_CHUNK]
EC <	cmp	ds:[si].CAH_elementSize, (size VisTextGraphic) 	>
EC <	ERROR_NE FAILED_ASSERTION_GENERATING_HELP_FILE 		>
	mov	cx, ds:[si].CAH_count
	tst	cx				;any graphics?
	LONG	jz	unlockExit		;branch if no graphics
	;
	; Set up the parameters for the call to VisTextGraphicCompressGrahic
	;
	mov	al, ss:bitmapFormat		;get the compress flags
	mov	dx, ss:bitmapRes		;dx <- desired resolution
	sub	sp, size VisTextGraphicCompressParams
	mov	bp, sp
	mov	ss:[bp].VTGCP_sourceFile, bx
	mov	ss:[bp].VTGCP_destFile, bx
	mov	ss:[bp].VTGCP_xDPI, dx
	mov	ss:[bp].VTGCP_yDPI, dx
	mov	ss:[bp].VTGCP_format, al
	mov	ss:[bp].VTGCP_compressFlag, 1	;non-zero to compress bitmaps
	;
	; For each graphics element, copy the graphic data chain
	;
	add	si, ds:[si].CAH_offset		;ds:si <- ptr to 1st element
copyGraphicsLoop:
	cmp	ds:[si].VTG_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	nextElement			;branch if unused element
	tst	ds:[si].VTG_vmChain.high	;any chain?
	jz	nextElement			;branch if no chain
	;
	; Compress all the bitmaps in this VisTextGraphic, if it is a gstring
	;
	movdw	ss:[bp].VTGCP_graphic, dssi
	call	VisTextGraphicCompressGraphic	;dx:ax <- new VMChain
EC <	call ECCheckBounds						>
EC <	call ECLMemValidateHeap						>
	;
	; Save the new chain in the VisTextGraphic, and free the old chain
	;
	push	bp
	cmpdw	dxax, ds:[si].VTG_vmChain
	je	noFree
	push	ax
	movdw	axbp, ds:[si].VTG_vmChain	;get the old chain
	call	VMFreeVMChain
	pop	ax
noFree:
	movdw	ds:[si].VTG_vmChain, dxax	;save the new chain
	mov	ax, dx
	call	DiscardVMChain
	pop	bp
nextElement:
	add	si, (size VisTextGraphic)
	loop	copyGraphicsLoop		;loop while more elements
	add	sp, size VisTextGraphicCompressParams
	;
	; Dirty and unlock the graphic elements in the help file
	;
	call	VMDirtyDS
unlockExit:
	call	VMUnlockDS

	;
	; Take the file out of backup mode so that compression is enabled,
	; and save it to get rid of all the dup blocks.
	;
	clr 	al
	mov	ah, mask VMA_BACKUP		
	call	VMSetAttributes
	call	VMSave

	.leave
	ret
CompressGraphicData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPageInfoToNameArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add page info to the help file's name array

CALLED BY:	StudioDocumentGenerateHelpFile

PASS:		ss:bp - inherited locals
		cx - total number of pages in page array
RETURN:		nothing
DESTROYED:	ax, bx, cx, si, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddPageInfoToNameArray		proc	near
		uses	dx, bp, ds
		.enter	inherit StudioDocumentGenerateHelpFile
	;
	; Lock the name array
	;
		mov	ax, ss:pageArrayVM
		push	ax
		mov	bx, ss:helpFile		;bx <- handle of help file
		mov	ax, ss:nameArrayVM	;ax <- VM block of names
		call	LockElementArray	;*ds:si <- name array
		pop	ax
	;
	; Lock the page array
	;
		call	VMLock
		push	bp
		mov	es, ax
		clr	bp			;es:bp <- page array
		call	CoalescePageArray	;bx <- # pages after coalesce

		call	ChunkArrayGetCount	;cx <- number of name elements
		tst	cx
		jz	unlock
infoLoop:
	;
	; es - segment of page array
	; *ds:si - name array
	; bx - number of pages
	; cx - name array element number (token)
	; 
		push	cx
		mov	ax, cx
		dec	ax
		call	ChunkArrayElementToPtr	;ds:di <- name element
		pop	cx
		
		cmp	ds:[di].PNAE_meta.VTNAE_meta.NAE_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
		je	continue			;branch if empty
		cmp	ds:[di].PNAE_meta.VTNAE_data.VTND_type, VTNT_FILE
		je	continue
EC <		cmp	ds:[di].PNAE_meta.VTNAE_data.VTND_type, VTNT_CONTEXT >
EC <		ERROR_NE FAILED_ASSERTION_GENERATING_HELP_FILE >

		push	cx
		push	di
		clr	di			;es:di <- page array
		mov	cx, bx			;cx <- # entries in page array
		jcxz	notFound
		repne 	scasw			;look for token in page array
		jnz	notFound	
		sub	di, size word		;es:di <- page entry
		mov	bp, di			;es:bp <- page entry
		mov	cx, di			;cx <- page offset (word based)
		shr	cx			;cx <- page number (from 0)
		inc	cx			;cx <- page number (from 1)
		pop	di
		
	; save the page number
		mov	ds:[di].PNAE_pageNumber, cx
		pop	cx

		mov	ax, -1			;default: no token
		mov	ds:[di].PNAE_upPage, ax ;no up page support yet
		
		tst	bp			;at first page?
		jz	noPrev			; then no prev page
		mov	ax, es:[bp][-2]		;get prev page
noPrev:		
		mov	ds:[di].PNAE_prevPage, ax

		push	bx
		dec	bx			;bx <- page # of last page
		shl	bx			;bx <- offset of last page
		mov	ax, -1			;default: no token
		cmp	bp, bx			;at last page?
		je	noNext			; then no next page
		mov	ax, es:[bp][2]		;get next page
noNext:
		pop	bx			;restore page count
		mov	ds:[di].PNAE_nextPage, ax

continue:
		loop 	infoLoop
unlock:		
	;
	; unlock the page array
	;
		pop	bp
		call	VMUnlock
		
	;
	; Mark the names as dirty and unlock them
	;
		call	VMDirtyDS
		call	VMUnlockDS

		.leave
		ret

notFound:
	; This context name's token does not appear in the
	; page array - it must not be set on any page.  Don't 
	; modify its PageNameArrayElement fields.
	;
		pop	di
		pop	cx
		jmp	continue
		
AddPageInfoToNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CoalescePageArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove null entries from the page array

CALLED BY:	AddPageInfoToNameArray

PASS:		es:bp - page array
		cx - total number of pages in page array
RETURN:		bx - number of pages after removing null entries
		es:bp - unchanged
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CoalescePageArray		proc	near
		uses	si, di, ds
		.enter

		segmov	ds, es, ax
		mov	si, bp			;ds:si <- page array
		push	cx
coalesceLoop:
		lodsw				;ax <- page token
						; ds:si <- next entry
		cmp	ax, -1
		je	nullEntry
		loop	coalesceLoop
done:
		pop	cx
		mov	bx, cx			;assume no null entries
		mov	di, bp			;es:di <- page array
		mov	ax, -1			;find first null token
		repne	scasw			;cx <- # null pages
		jnz	$10			;none found
		inc	cx
		sub	bx, cx			;bx <- # non-null pages
$10:
		.leave
		ret
		
nullEntry:
	; A page with no token was found.  Search the remaining entries
	; for the next non-null page and exchange tokens.
	; 	ax = -1
	; 	cx = # pages remaining
	; 	ds:si = entry after the null entry
	;
		mov	bx, cx			;save # pages remaining
		dec	cx			;loop counts from 1, we count
		jz	done			; from 0, so stop if cx-1=0.
		mov	di, si			;es:di <- next entry
		repe	scasw			;look for first non-null
		je	done			;not found? we're done
		sub	di, size word		;es:di <- found non-null page
		xchg	ax, es:[di]		;ax <- real token
		sub	si, size word		;ds:si <- null entry
		mov	di, si			;es:di <- null entry
		stosw				;store the real token, inc di
		mov	si, di			;ds:si <- next entry
		mov	cx, bx			;restore # pages remaining
		loop	coalesceLoop		;continue looping
		jmp	done
CoalescePageArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddSpaceToNameArray()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update an older name array to have additional space
		in it for help that we should have allowed for earlier
		but in a fit of something or another, didn't.

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS:		ss:bp - inherited locals
			helpFile - handle of help file
			nameArrayVM - VM handle of names
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddSpaceToNameArray		proc	near
	uses	ax, bx, cx, dx, bp, si, di, ds
	.enter	inherit	StudioDocumentGenerateHelpFile

	;
	; Lock the name array
	;
	mov	bx, ss:helpFile			;bx <- handle of help file
	mov	ax, ss:nameArrayVM		;ax <- VM block of names
	call	LockElementArray		;*ds:si <- name array
	;
	; Figure out how big the change is
	;
	mov	di, ds:[si]			;ds:di <- ptr to name array
	mov	dx, (size HelpFileNameArrayElement)-(size NameArrayElement)
	sub	dx, ds:[di].NAH_dataSize	;dx <- change in size
	add	ds:[di].NAH_dataSize, dx	;update header size
	mov	cx, ds:[di].CAH_count		;cx <- # of names
	jcxz	noNames				;branch if no names
	;
	; For each element in the name array, insert some additional space.
	;
	clr	ax				;ax <- start with 0th element
nameLoop:
	;
	; Calculate the pointer to the current name.  This is a little
	; tricky since we've updated any elements before this point,
	; so they are the new size not the old.  This is why we don't
	; use ChunkArrayEnum() for this -- it gets confused, and doesn't
	; like us using LMemInsertAt() anyway.
	;
	push	ax, cx
	call	ChunkArrayElementToPtr
	call	AddSpaceToOneName
	pop	ax, cx
	je	nextElement			;branch if empty element
	;
	; Fix up the chunk array size table
	;
	call	FixChunkArraySizes
	;
	; Go to next name, if any
	;
nextElement:
	inc	ax				;ax <- next name
	loop	nameLoop			;loop while more names
noNames:
	;
	; Mark the names as dirty and unlock them
	;
	call	VMDirty
	call	VMUnlock

	.leave
	ret
AddSpaceToNameArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddSpaceToOneName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update one name to have extra space for help

CALLED BY:	AddSpaceToNameArray()
PASS:		*ds:si - chunk array
		ds:di - current element
		dx - change in size
RETURN:		ds - updated
		z flag - set (jz) if element is empty
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddSpaceToOneName		proc	near
	uses	si
	.enter

	;
	; Insert additional space -- NOTE: LMemInsertAt() zeros
	; the new space, which is what we want.
	;
	mov	ax, si				;ax <- chunk
	mov	cx, dx				;cx <- # of bytes to insert
	mov	si, ds:[si]			;ds:si <- ptr to chunk array
	mov	bx, di				;ds:bx <- ptr to current element
	cmp	ds:[bx].NAE_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	done				;branch if empty
	add	bx, ds:[si].NAH_dataSize
	sub	bx, dx
	add	bx, (size NameArrayElement)	;ds:bx <- past existing data
	sub	bx, si				;bx <- offset from chunk
	call	LMemInsertAt
	cmp	ax, 0				;clear z flag
done:

	.leave
	ret
AddSpaceToOneName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixChunkArraySizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix the sizes in a chunk array

CALLED BY:	AddSpaceToNameArray()
PASS:		*ds:si - 
		ax - element that has changed size
		dx - amount of change
RETURN:		none
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixChunkArraySizes		proc	near
	uses	ax
	.enter

	mov	di, ds:[si]			;ds:di <- ptr to header
	mov	bx, ax				;bx <- element #
	shl	bx
	add	bx, ds:[di].CAH_offset		;ds:bx <- offset to element
	add	bx, di				;ds:bx <- ptr to element
elementLoop:
	inc	ax				;next element
	cmp	ax, ds:[di].CAH_count		;at last element?
	je	lastElement			;branch if last element
	add	bx, (size word)
	add	ds:[bx], dx			;adjust offset
	jmp	elementLoop

lastElement:

	.leave
	ret
FixChunkArraySizes		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeStyleSheetRefs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke any references to style sheets in an element array

CALLED BY:	StudioDocumentGenerateHelpFile()
PASS:		dx - VM file handle of help file
		ax - VM handle of element array
RETURN:		none
DESTROYED:	nnone

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukeStyleSheetRefs		proc	near
	uses	ax, bx, cx, dx, si, di, bp, ds
	.enter

	mov	bx, dx				;bx <- VM file handle
	call	LockElementArray		;*ds:si <- element array
	;
	; Enum the elements to nuke the refs from the Kansas vs. Cal game
	;
	mov	bx, cs
	mov	di, offset NukeOneStyleSheetRef	;bx:di <- callback
	call	ChunkArrayEnum
	;
	; Mark the element array dirty and unlock it
	;
	call	VMDirty
	call	VMUnlock

	.leave
	ret
NukeStyleSheetRefs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeOneStyleSheetRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke one style sheet reference

CALLED BY:	NukeStyleSheetRefs() via ChunkArrayEnum()
PASS:		ds:di - ptr to element (StyleSheetElementHeader)
RETURN:		carry - set to abort
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukeOneStyleSheetRef		proc	far
	.enter

	cmp	ds:[di].SSEH_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	done				;skip if free element
	;
	; Nuke the style sheet reference
	;
	mov	ds:[di].SSEH_style, CA_NULL_ELEMENT
	;
	; NOTE: The following is a hack. Look away if you're the
	; squeamish sort...OK, I warned you.
	;
	; The problem is that MSG_VIS_TEXT_LOAD_FROM_DB_ITEM doesn't
	; deal quite properly with reference counts.  For help, this
	; is fine until we go to destroy the storage for our text
	; object in preparation for connecting it to a new file's
	; element arrays.  It does deal with the reference counts,
	; meaning that they get decremented as the runs that refer to
	; them are deleted.  Do this enough times, and you get zero,
	; and the element is deleted.  This would be fine, except for
	; a transitory moment where the text and structures are deleted
	; and the text object goes to redraw.  It tries to use a paragraph
	; attribute that has -- you guessed it -- been deleted.  Meaning
	; it draws in very lovely random colors and patterns.  So
	; we set it a nice big number.
	;
	clr	ds:[di].SSEH_meta.REH_refCount.WAAH_high
	mov	ds:[di].SSEH_meta.REH_refCount.WAAH_low, 0xeca
done:
	clc					;carry <- don't abort

	.leave
	ret
NukeOneStyleSheetRef		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuspendAndMarkBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare to generate the content file by suspending the
		document and marking the application busy.

CALLED BY:	StudioDocumentGenerateHelpFile
PASS:		*ds:si - document
		^hbx - document's file
RETURN:		nothing
DESTROYED:	ax, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SuspendAndMarkBusy		proc	near
		uses	bp
		.enter

		call	LockMapBlockES
		call	SuspendDocument
		call	VMUnlockES			;unlock map block
		
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	GenCallApplication		
		.leave
		ret
SuspendAndMarkBusy		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnsuspendAndMarkNotBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Content file generation has finished, so unsuspend the
		document and mark the application not busy.

CALLED BY:	StudioDocumentGenerateHelpFile
PASS:		*ds:si - document
		^hbx - document's file
RETURN:		nothing
DESTROYED:	ax, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnsuspendAndMarkNotBusy		proc	near
		uses	bp
		.enter

		call	LockMapBlockES
		call	UnsuspendDocument
		call	VMUnlockES			;unlock map block
		
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	GenCallApplication		
		.leave
		ret
UnsuspendAndMarkNotBusy		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetArticleMemHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the mem handle for an article.

CALLED BY:	INTERNAL

PASS:		ds:[di]	= ArticleArrayElement
RETURN:		bx	= mem handle
DESTROYED:	ax
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/15/94    	Broke out of EnumPagesForArticle

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetArticleMemHandle	proc	near

		mov	ax, ds:[di].AAE_articleBlock
		call	VMVMBlockToMemBlock
		mov_tr	bx, ax

		ret
GetArticleMemHandle	endp

HelpEditCode	ends
