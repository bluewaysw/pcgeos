COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		lol.asm

AUTHOR:		Adam de Boor, Dec 10, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/10/92		Initial revision


DESCRIPTION:
	Simple launcher to load the selected specific saver.
		

	$Id: lol.asm,v 1.1 97/04/04 16:13:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include initfile.def

UseLib	saver.def

LOLProcessClass	class	GenProcessClass
LOLProcessClass	endc

include	lol.rdef

idata	segment
category	char	'Lights Out', 0
key		char	'specific', 0

SBCS <saverPath	char	C_BACKSLASH, 'SAVERS', C_BACKSLASH		>
DBCS <saverPath	wchar	C_BACKSLASH, "SAVERS", C_BACKSLASH		>
saverName	FileLongName	<>

LOLProcessClass	mask CLASSF_NEVER_SAVED

idata	ends

Code	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LOLOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the saver specified in the [Lights Out]::specific key.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		ds	= dgroup
		cx	= AppAttachFlags
		dx	= AppLaunchBlock handle
		bp	= saved state
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LOLOpenApplication method dynamic LOLProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION
		.enter
	;
	; Fetch the key from the .ini file.
	; 
		mov	di, offset LOLProcessClass
		call	ObjCallSuperNoLock
		mov	di, offset saverName
		mov	bp, size saverName	; fetch chars intact
		mov	cx, ds
		mov	dx, offset key
		mov	si, offset category
		call	InitFileReadString
		jc	done
	;
	; Create a launch block for the beast.
	; 
		mov	cx, ds
		mov	dx, offset saverPath	; cx:dx <- path
		mov	bp, SP_SYSTEM		; bp <- disk handle
		call	SaverCreateLaunchBlock
	;
	; Now load it.
	; 
		mov	dx, bx			; dx <- AppLaunchBlock

		mov	bx, handle ui
		mov	di, mask MF_CALL
		mov	ax, MSG_USER_LAUNCH_APPLICATION
		call	ObjMessage
done:
		mov	ax, MSG_META_QUIT
		mov	bx, handle LOLApp
		mov	si, offset LOLApp
		clr	di
		call	ObjMessage
		.leave
		ret
LOLOpenApplication endm

Code	ends
