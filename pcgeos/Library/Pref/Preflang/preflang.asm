COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		preflang
FILE:		preflang.asm

AUTHOR:		Paul Canavese, Jan 23, 1995

ROUTINES:
	Name			Description
	----			-----------
	PrefLangGetPrefUITree	Return the root of the ui tree for 
				"Preferences".
	PrefLangGetModuleInfo	Fill in the PrefModuleInfo buffer so
				that PrefMgr can decide whether to
				show this button
	PLDPrefDialogReboot	Restart PC/GEOS.  But first make sure
				the state and TOC files are deleted so
				that the ui will be rebuilt on
				reentry.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PJC	1/23/95		Initial revision
	Don	12/28/00	Added support for the "GPC" version of
				switching languages, which involves pointing
				the .INI file to a different system tree.

DESCRIPTION:
	Code for Language module of Preferences. 

	$Id: preflang.asm,v 1.1 97/04/05 01:43:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def

include object.def
include	graphics.def
include gstring.def
include	win.def

include char.def
include initfile.def
include system.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include preflang.def
include preflang.rdef

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata segment

	PrefLangDialogClass
	PrefLangIniDynamicListClass

idata ends

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PrefLangCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLangGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		none

RETURN:		dx:ax - OD of root of tree

DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLangGetPrefUITree	proc far
		mov	dx, handle PrefLangRoot
		mov	ax, offset PrefLangRoot
		ret
PrefLangGetPrefUITree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefLangGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr

PASS:		ds:si - PrefModuleInfo structure to be filled in

RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefLangGetModuleInfo	proc far
		.enter

		clr	ax
		mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
		mov	ds:[si].PMI_prohibitedFeatures, ax
		mov	ds:[si].PMI_minLevel, ax
		mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
		mov	ds:[si].PMI_monikerList.handle, handle  PrefLangMonikerList
		mov	ds:[si].PMI_monikerList.offset, offset PrefLangMonikerList
		mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
		mov	{word} ds:[si].PMI_monikerToken+2, 'L' or ('A' shl 8)
		mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

		.leave
		ret
PrefLangGetModuleInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLDPrefDialogConfirmReboot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display reboot confirmation message to user (GPC-only).
		We override the default message as that one has been deemed
		to be "too scary". :)

CALLED BY:	MSG_PREF_DIALOG_CONFIRM_REBOOT

PASS:		*ds:si	= PrefLangDialogClass object
		ds:di	= PrefLangDialogClass instance data
		ds:bx	= PrefLangDialogClass object (same as *ds:si)
		es 	= segment of PrefLangDialogClass
		ax	= message #

RETURN:		carry	= set to confirm reboot (i.e. do it!)
			- or -
		carry	= clear to abort reboot

DESTROYED:	ax,cx,dx,bp,ds

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/26/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	GPC_VERSION
PLDPrefDialogConfirmReboot	method dynamic PrefLangDialogClass, 
				MSG_PREF_DIALOG_CONFIRM_REBOOT
		.enter
	;
	; Just ask the user a question and wait for a response
	;
		clr	ax
		push	ax, ax		; SDOP_helpContext
		push	ax, ax		; SDOP_customTriggers
		push	ax, ax		; SDOP_stringArg2
		push	ax, ax		; SDOP_stringArg1
		mov	ax, handle prefSystemLanguageRebootString
		push	ax
		mov	ax, offset prefSystemLanguageRebootString
		push	ax
		mov	ax, (CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
		push	ax		; SDOP_customFlags
	CheckHack <size StandardDialogOptrParams eq 22>

		call	UserStandardDialogOptr
	;
	; Return carry = set *only* if the user answered "yes".
	; Treat any other response as an abort.
	;
		cmp	ax, IC_YES
		stc
		je	done
		clc
done:
		.leave
		ret
PLDPrefDialogConfirmReboot	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLDPrefDialogReboot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restart PC/GEOS.  But first make sure the state and
		TOC files are deleted so that the ui will be rebuilt
		on reentry.

CALLED BY:	MSG_PREF_DIALOG_REBOOT

PASS:		*ds:si	= PrefLangDialogClass object
		ds:di	= PrefLangDialogClass instance data
		ds:bx	= PrefLangDialogClass object (same as *ds:si)
		es 	= segment of PrefLangDialogClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp,ds

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	11/ 8/94   	Initial version
	jfh	5/16/05	fixes bug where vid has been changed then language
   					changed on GPC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
deleteStateFilesCategory	char	'ui',0
deleteStateFilesKey		char	'forceDeleteStateFilesOnceOnly',0
deleteTocFileCategory		char	'pref',0
deleteTocFileKey		char	'forceDeleteTocOnceOnly',0
deleteScreen0Category		char	'screen0',0

PLDPrefDialogReboot	method dynamic PrefLangDialogClass, 
					MSG_PREF_DIALOG_REBOOT
		.enter

	; Do regular handling.

		mov	di, offset PrefLangDialogClass
		call	ObjCallSuperNoLock

	; Make sure the state files will be deleted.

		mov	cx, cs
		mov	ds, cx
		mov	si, offset deleteStateFilesCategory
		mov	dx, offset deleteStateFilesKey
		mov	ax, TRUE
		call	InitFileWriteBoolean

	; Make sure Table Of Content (TOC) file will be deleted.

		mov	si, offset deleteTocFileCategory
		mov	dx, offset deleteTocFileKey
		mov	ax, TRUE
		call	InitFileWriteBoolean

	; jfh - kill any video reference in the geos.ini

		mov	si, offset deleteScreen0Category
		call	InitFileDeleteCategory

		.leave
		Destroy	ax,cx,dx,bp
		ret
PLDPrefDialogReboot	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLIDLItemGroupGetItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When switching languages, we need to back up the old
		.ini file and read in the new language's .ini file.

CALLED BY:	MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER

PASS:		*ds:si	= PrefLangIniDynamicListClass object
		ds:di	= PrefLangIniDynamicListClass instance data
		ds:bx	= PrefLangIniDynamicListClass object (same as *ds:si)
		es 	= segment of PrefLangIniDynamicListClass
		ax	= message #
		ss:bp	= GetItemMonikerParams

RETURN:		bp	= number of characters returned

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/28/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	GPC_VERSION
PLIDLItemGroupGetItemMoniker	method dynamic	PrefLangIniDynamicListClass, 
				MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
		.enter
	;
	; Create the language-specific .INI category holding the language
	; strings that will be displayed to the user
	;
		mov	bx, bp
		sub	sp, MAX_INITFILE_CATEGORY_LENGTH
		mov	bp, sp			; category buffer => SS:BP
		call	ConstructLanguageCategoryString
	;
	; Now get the language string (should just be a one- or two-digit
	; numeric string, though anything is OK).
	;
		mov	si, ds:[di].PIDLI_array
		mov	ax, ss:[bx].GIMP_identifier
		call	ChunkArrayElementToPtr
		add	di, offset NAE_data	; language string => DS:DI
	;
	; Finally, use this string to look up the user-visible string
	; and store it in the passed buffer.
	;
		mov	cx, ds
		mov	dx, di			; key string => CX:DX
		segmov	ds, ss
		mov	si, bp			; cateogry string => DS:SI
		les	di, ss:[bx].GIMP_buffer	; destination buffer => ES:DI
		mov	bp, ss:[bx].GIMP_bufferSize
		call	InitFileReadString
		mov	bp, cx			; character length => BP
		add	sp, MAX_INITFILE_CATEGORY_LENGTH

		.leave
		ret
PLIDLItemGroupGetItemMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConstructLanguageCategoryString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Crreate the language-specific category string

CALLED BY:	Various

PASS:		ss:bp	= Buffer to hold string

RETURN:		ss:bp	= Buffer filled with string

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/28/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

sysLanguageCatStr	char	"system", 0
sysLanguageKeyStr	char	"systemLanguage", 0
baseLanguageCatStr	char	"language_"		; *no* NULL-terminator!

ConstructLanguageCategoryString	proc	near
		uses	ax, bx, cx, dx, di, si, bp, ds, es
		.enter
	;
	; Determine the appropriate .INI category holding the language
	; strings that will be displayed to the user by looking up
	; the current language.
	;
		segmov	ds, cs, cx
		mov	si, offset sysLanguageCatStr
		mov	dx, offset sysLanguageKeyStr
		mov	ax, SL_ENGLISH		; assume English for default
		call	InitFileReadInteger	; StandardLanguage => AX
	;
	; Now construct the .INI file category string
	;
		mov	si, offset baseLanguageCatStr
		mov	cx, length baseLanguageCatStr
		segmov	es, ss
		mov	di, bp			; category buffer => SS:DI
		rep	movsb
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii

		.leave
		ret
ConstructLanguageCategoryString	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PLIDLGenSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implement the switching of the language by saving settings
		to the .INI file and performing other necessary actions

CALLED BY:	MSG_GEN_SAVE_OPTIONS

PASS:		*ds:si	= PrefLangIniDynamicListClass object
		ds:di	= PrefLangIniDynamicListClass instance data
		ds:bx	= PrefLangIniDynamicListClass object (same as *ds:si)
		es 	= segment of PrefLangIniDynamicListClass
		ax	= message #
		ss:bp	= GenOptionsParams

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		For the GPC_VERSION:
==> NOT DONE!	- rename the World sub-directories
		- call superclass to update language setting
		- write the new reference to the system .INI file
		- write the new reference to the system "top"
		- write the new reference to the shared token DB

		For standard version (multi-language enabled in the Kernel):
		- save the current .INI file
		- call superclass to update language setting
		- make the new language's .INI file the current one

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/26/95   	Initial version
	Don	12/29/00	Implemented GPC version of multiple languages

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	GPC_VERSION
pathsCatStr		char	"paths", 0
pathsTopKeyStr		char	"top", 0
pathsIniKeyStr		char	"ini", 0
pathsTokenDBKeyStr	char	"sharedTokenDatabase", 0
endif

PLIDLGenSaveOptions	method dynamic	PrefLangIniDynamicListClass, 
					MSG_GEN_SAVE_OPTIONS
		.enter

ifndef	GPC_VERSION
	;
	; Backup the old language's .ini file.
	;
		call	InitFileBackupLanguage
endif
	;
	; Call superclass to record the new language in the .ini file.
	;
		mov	di, offset PrefLangIniDynamicListClass
		call	ObjCallSuperNoLock

ifdef	GPC_VERSION
	;
	; Create the language-specific .INI category holding the settings
	; for the new language
	;
		sub	sp, MAX_INITFILE_CATEGORY_LENGTH
		mov	bp, sp			; category buffer => SS:BP
		call	ConstructLanguageCategoryString
	;
	; Now reset the .INI entries based upon the language's settings
	;
		segmov	ds, ss
		mov	si, bp			; category string => DS:SI
		mov	cx, cs
		mov	dx, offset pathsTopKeyStr
		call	resetInitFileString
		mov	dx, offset pathsIniKeyStr
		call	resetInitFileString
		mov	dx, offset pathsTokenDBKeyStr
		call	resetInitFileString
		add	sp, MAX_INITFILE_CATEGORY_LENGTH
else
	;
	; Switch language .ini files.
	;
		call	InitFileSwitchLanguages
endif
		.leave
		Destroy	ax, cx, dx, bp
		ret

ifdef	GPC_VERSION
	;
	; Re-write an .INI entry (string) based upon another .INI-based string
	;
	; Pass:
	;	DS:SI	= Source .INI category
	;	CX:DX	= Source (& destination) .INI key
	; Returns:
	;	Carry	= Clear if success, set if error (no source string)
	; Destroys:
	;	AX, BX, BP
	;
resetInitFileString:
		push	di, si, ds, es
		clr	bp
		push	cx
		call	InitFileReadString
		pop	cx
EC <		ERROR_C	ERROR_PREF_LANG_SOURCE_INI_STRING_NOT_FOUND	>
NEC <		jc	resetStringError				>
		call	MemLock
		mov	es, ax
		clr	di			; string to write => ES:DI
		segmov	ds, cs
		mov	si, offset pathsCatStr	; destination category => DS:SI
		call	InitFileWriteString
		call	MemFree			; free string we copied
		clc
resetStringError::
		pop	di, si, ds, es
		retn
endif
PLIDLGenSaveOptions	endm

PrefLangCode	ends
