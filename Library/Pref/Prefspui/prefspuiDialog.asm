COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Pref
MODULE:		Prefspui
FILE:		prefspuiDialog.asm

AUTHOR:		David Litwin, Sep 27, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/27/94   	Initial revision


DESCRIPTION:
	This file contains the code for the PrefSpuiDialog class

	$Id: prefspuiDialog.asm,v 1.1 97/04/05 01:42:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSpuiGetPrefSpuiTree
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
PrefSpuiGetPrefSpuiTree	proc far
	mov	dx, handle PrefSpuiRoot
	mov	ax, offset PrefSpuiRoot
	ret
PrefSpuiGetPrefSpuiTree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSpuiGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr

PASS:		ds:si - PrefModuleInfo structure to be filled in

RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECSnd/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSpuiGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle  PrefSpuiMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset PrefSpuiMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'U' or ('C' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	.leave
	ret
PrefSpuiGetModuleInfo	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	PrefSpuiDialogGetRebootInfo --
		MSG_PREF_GET_REBOOT_INFO for PrefSpuiDialogClass

DESCRIPTION:	Initialize the number of elements in the demo list

PASS:
	*ds:si - instance data
	es - segment of PrefSpuiDialogClass

	ax - The message

RETURN:
	cx:dx - OD of string to put up in confirm dialog

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/31/94		Initial version

------------------------------------------------------------------------------@
PrefSpuiDialogGetRebootInfo	method dynamic	PrefSpuiDialogClass,
					MSG_PREF_GET_REBOOT_INFO

	mov	cx, handle PrefSpuiRebootString
	mov	dx, offset PrefSpuiRebootString
	ret

PrefSpuiDialogGetRebootInfo	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDApplyComplex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Concatenate the .ini's in CINI and write them to a file,
		link the ini to this new one and reboot.

CALLED BY:	MSG_PSD_APPLY_COMPLEX
PASS:		*ds:si	= PrefSpuiDialogClass object
		ds:di	= PrefSpuiDialogClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDApplyComplex	method dynamic PrefSpuiDialogClass, 
					MSG_PSD_APPLY_COMPLEX
	.enter

	tst	ds:[di].PSDI_ignoreApply
	jnz	exit

	not	ds:[di].PSDI_ignoreApply	; we got our first apply,
						;  ignore the rest.

	;
	; build the .ini file by contatenating the four
	; areas: Metaphor, Input, User Level, Form Factor.
	;
	call	PSDBuildCiniFile
EC<	WARNING_C	WARNING_COULDNT_WRITE_OUT_CINI_FILE	>
	jc	exit

	;
	; write out the name of this file (CINI) to our .ini and reboot
	;
	segmov	es, cs, di
	mov	di, offset ciniFilename
	call	PSDSetIni

	mov	ax, MSG_GEN_APPLY			; cause the reboot
	mov	si, offset PrefSpuiRoot
	call	ObjCallInstanceNoLock

exit:
	.leave
	ret
PSDApplyComplex	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDBuildCiniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the .ini file by contatenating the four
		areas: Metaphor, Input, User Level, Form Factor.

CALLED BY:	PSDApplyComplex

PASS:		nothing
RETURN:		carry	= set if CINI couldn't be created
			= clear if all went well
DESTROYED:	ax, bx, cx, dx, bp, di, si, es

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDBuildCiniFile	proc	near
	uses	ds
	.enter

	call	FilePushDir

	mov	ax, SP_TOP
	call	FileSetStandardPath		; set path to: SP_TOP
	jc	exit

	push	ds
	mov	ah, mask FCF_NATIVE or \
			(FILE_CREATE_TRUNCATE shl offset FCF_MODE)
	mov	al, FILE_ACCESS_W or FILE_DENY_NONE
	clr	cx				; no attributes
	segmov	ds, cs, dx
	mov	dx, offset ciniFilename
	call	FileCreate
	pop	ds
	jc	exit

	mov	si, offset MetaphorList
	call	PSDAddListsIniText
	jc	errorClose

	mov	si, offset InputList
	call	PSDAddListsIniText
	jc	errorClose

	mov	si, offset UserLevelList
	call	PSDAddListsIniText
	jc	errorClose

	mov	si, offset FormFactorList
	call	PSDAddListsIniText
	jc	errorClose

	mov	bx, ax
	clr	al				; can handle errors
	call	FileClose

exit:
	call	FilePopDir

	.leave
	ret			; <---- EXIT HERE

errorClose:
	mov	bx, ax
	clr	al				; can handle errors
	call	FileClose			; ignore any fileclose errors,
	stc					;  as we already have an error
	jmp	exit
PSDBuildCiniFile	endp

LocalDefNLString	ciniFilename	<'CINI',C_BACKSLASH, 'CINI.INI', 0>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDAddListsIniText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the object's selected .ini file and write its contents
		to the end of the passed in file.

CALLED BY:	PSDBuildCiniFile

PASS:		ax	= cini filehandle open for writing
		current directory set to SP_TOP/CINI
		*ds:si	= optr of PrefSpuiDynamicListClass object
RETURN:		carry	= set on error
			= clear on success
DESTROYED:	cx, dx, bp, di, si, es

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDAddListsIniText	proc	near
	uses	ax,bx
	.enter

	mov	bp, ax				; save file handle in bp

	mov	ax, MSG_PSDL_GET_SELECTED_INI_FILE_TEXT
	call	ObjCallInstanceNoLock
	jc	exit
	jcxz	exit				; no list items

	mov	bx, dx
	push	bx, ds				; save handle for later freeing
	call	MemLock
	mov	ds, ax
	clr	dx				; ds:dx is our buffer
	clr	al				; can handle errors
	mov	bx, bp				; file handle
	call	FileWrite

	pop	bx, ds
	pushf
	call	MemFree
	popf

exit:

	.leave
	ret
PSDAddListsIniText	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDSetIni
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the ini key in the paths category to the supplied name

CALLED BY:	PSDApplyComplex, PSDDLApply

PASS:		es:di	= ini file to link to
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, es, si

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDSetIni	proc	near
	uses	bx, ds
defaultLauncherBuffer	local	PathName
	.enter

	call	LocalStringLength
	push	bp
	mov	bp, cx

	mov	cx, cs
	mov	dx, offset iniKey
	mov	ds, cx
	mov	si, offset pathsCategory
	call	InitFileWriteString
	pop	bp

	mov	cx, cs
	mov	dx, offset defaultLauncherKey
	mov	si, offset defaultLauncherCategory
	segmov	es, ss, di
	lea	di, ss:[defaultLauncherBuffer]
	push	bp				; save our stack frame
	mov	bp, size PathName
	call	InitFileReadString		; read in defaultLauncher

	mov	cx, cs
	mov	dx, offset oldDefaultLauncherKey
	call	InitFileWriteString		; write out oldDefaultLauncher
	pop	bp				; restore our stack frame

	.leave
	ret
PSDSetIni	endp

LocalDefNLString	pathsCategory	<'paths', 0>
LocalDefNLString	iniKey		<'ini', 0>

LocalDefNLString	defaultLauncherCategory	<'ui features',0>
LocalDefNLString	defaultLauncherKey	<'defaultLauncher',0>
LocalDefNLString	oldDefaultLauncherKey	<'oldDefaultLauncher',0>



