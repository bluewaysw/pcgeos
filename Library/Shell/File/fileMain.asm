COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- File
FILE:		fileMain.asm

AUTHOR:		Martin Turon, October 21, 1992

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/21/92	Initial version

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: fileMain.asm,v 1.1 97/04/07 10:45:34 newdeal Exp $

=============================================================================@



COMMENT @-------------------------------------------------------------------
			ShellSetObjectType
----------------------------------------------------------------------------

DESCRIPTION:	Sets the first word of the FileDesktopInfo of the
		given file to the given value.  The rest of the
		FileDesktop for the file is not affected.

CALLED BY:	GLOBAL - 
			when IclasSetDesktopInfo is replaced:
				IclasCreateSpecialLink

PASS:		ds:dx	= filename
		ax	= (WShellObjectType)

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/2/92		Initial version
	martin	10/13/92	converted from FolderCreateSpecialLink
	martin	10/14/92	added code to get new magical artwork	

---------------------------------------------------------------------------@
ShellSetObjectType	proc	far
		uses	cx, di, es

desktopInfo	local	word
		.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
	;
	; Set correct ShellObjectType in first word
	;
		mov	ss:[desktopInfo], ax
	;
	; Make the call to set the attribute in the link
	;
		lea	di, ss:[desktopInfo]
		segmov	es, ss
		mov	cx, size desktopInfo
		mov	ax, FEA_DESKTOP_INFO
		call	FileSetPathExtAttributes		
		.leave
		ret
ShellSetObjectType	endp



COMMENT @-------------------------------------------------------------------
			ShellGetObjectType
----------------------------------------------------------------------------

DESCRIPTION:	Returns the ShellObjectType for a file.

CALLED BY:	GLOBAL

PASS:		ds:dx	= filename

RETURN:		IF ERROR:
			carry set
			ax	= FileError
		ELSE:
			carry clear
			ax	= (WShellObjectType)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/28/92	Initial version

---------------------------------------------------------------------------@
ShellGetObjectType	proc	far
		uses	cx, di, es
desktopInfo	local	word
		.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
		segmov	es, ss, ax
		mov	ax, FEA_DESKTOP_INFO
		mov	cx, size desktopInfo
		lea	di, ss:desktopInfo
		call	FileGetPathExtAttributes
		jc	error

		mov	ax, ss:[desktopInfo]
error:
		.leave
		ret
ShellGetObjectType	endp



COMMENT @-------------------------------------------------------------------
			ShellSetToken
----------------------------------------------------------------------------

DESCRIPTION:	Sets the token for the given file.

CALLED BY:	GLOBAL -	LinksSetSpecialToken, 
				IclasVerifyRunFromALink
				IconListSetTokenOfFile

PASS:		ax:cx:di	= GeodeToken
		ds:dx		= filename

RETURN:		IF ERROR:
			carry set
			ax	= FileError
		ELSE:
			carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/18/92	Initial version

---------------------------------------------------------------------------@
ShellSetToken	proc	far
token		local	GeodeToken	push	di, cx, ax
		uses	es, di, ax, cx
		.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
		mov	ax, FEA_TOKEN
		segmov	es, ss
		lea	di, ss:token
		mov	cx, size GeodeToken
		call	FileSetPathExtAttributes

		.leave
		ret
ShellSetToken	endp




COMMENT @-------------------------------------------------------------------
			ShellGetToken
----------------------------------------------------------------------------

DESCRIPTION:	Returns the GeodeToken for the given file.

CALLED BY:	GLOBAL

PASS:		ds:dx		 = filename

RETURN:		IF ERROR:
			carry set
			ax	 = FileError
			cx, di	 = destroyed
		ELSE:
			carry clear
			ax:cx:di = GeodeToken

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/28/92	Initial version

---------------------------------------------------------------------------@
ShellGetToken	proc	far
		uses	es
token		local	GeodeToken
		.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
		segmov	es, ss
		lea	di, ss:token
		mov	ax, FEA_TOKEN
		mov	cx, size GeodeToken
		call	FileGetPathExtAttributes

		mov	ax, {word}ss:[token][GT_chars]
		mov	cx, {word}ss:[token+2][GT_chars]
		mov	di, ss:[token][GT_manufID]

		.leave
		ret
ShellGetToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellSetFileHeaderFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the GeosFileHeaderFlags for a file

CALLED BY:	GLOBAL

PASS:		ax - flags to SET
		bx - flags to CLEAR
		ds:dx - path to file.  If DS is zero, then DX contains
		a file handle instead.

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear
			ax - old flags


DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShellSetFileHeaderFlags	proc far

	uses	es,di,bx,cx,dx

setFlags	local	GeosFileHeaderFlags	push	ax
clearFlags	local	GeosFileHeaderFlags	push	bx
oldFlags	local	GeosFileHeaderFlags
newFlags	local	GeosFileHeaderFlags

	.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<	mov	cx, ds						>
FXIP<	jcxz	noSeg						>
FXIP<	push	bx, si						>
FXIP<	mov	bx, ds						>
FXIP<	mov	si, dx						>
FXIP<	call	ECAssertValidFarPointerXIP			>
FXIP<	pop	bx, si						>
FXIP<noSeg:							>
endif

	;
	; Set up pointers for attr fetch
	;

	segmov	es, ss
	lea	di, ss:[oldFlags]
	mov	ax, FEA_FLAGS
	mov	cx, size oldFlags

	mov	bx, ds
	tst	bx
	jz	fileHandle

	call	FileGetPathExtAttributes
	call	modify
	call	FileSetPathExtAttributes
	jmp	done

fileHandle:
	mov	bx, dx
	call	FileGetHandleExtAttributes
	call	modify
	call	FileSetHandleExtAttributes
done:

	mov	ax, ss:[oldFlags]
	.leave
	ret

	;
	; Take the old flags -- or in the SET values, and out the
	; CLEAR values, and then store the new flags, updating DI and
	; AX. 
	;

modify:
	mov	ax, ss:[oldFlags]
	ornf	ax, ss:[setFlags]
	not	ss:[clearFlags]
	andnf	ax, ss:[clearFlags]
	mov	ss:[newFlags], ax
	lea	di, ss:[newFlags]
	mov	ax, FEA_FLAGS
	retn

	
ShellSetFileHeaderFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellGetFileHeaderFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the GeosFileHeaderFlags from a file

CALLED BY:	GLOBAL

PASS:		ds:dx - filename

RETURN:		ax - GeosFileHeaderFlags

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 9/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellGetFileHeaderFlags	proc far
	uses	es, di, cx
	.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<	push	bx, si						>
FXIP<	mov	bx, ds						>
FXIP<	mov	si, dx						>
FXIP<	call	ECAssertValidFarPointerXIP			>
FXIP<	pop	bx, si						>
endif

EC <	call	ECCheckFilenameDSDX			>

	mov	cx, size GeosFileHeaderFlags
	sub	sp, cx
	segmov	es, ss
	mov	di, sp
	mov	ax, FEA_FLAGS
	call	FileGetPathExtAttributes
	pop	cx			; attributes of file
	jc	done
	mov_tr	ax, cx			; return them in AX
done:
	.leave
	ret
ShellGetFileHeaderFlags	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellPushToRoot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If BX is nonzero, do a FilePushDir, and CD to the root
		of the disk handle.  Use in conjunction with
		ShellPopDir. 

CALLED BY:	GLOBAL

PASS:		bx - disk handle, or zero 

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear
			directory pushed


DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
rootDir		char	'\\', 0

ShellPushToRoot	proc	far

		uses ds, dx, bx

		.enter

		call	FilePushDir
		tst	bx
		jz	done
	;
	; call FileSetCurrentPath to go to the root of the passed volume.
	;
		segmov	ds, cs
		mov	dx, offset rootDir
		call	FileSetCurrentPath
		jnc	done
	;
	; Yrg. Root doesn't exist. Pop the pushed directory and return carry
	; set (ax untouched).
	;
		call	FilePopDir
		stc
done:
		.leave
		ret
ShellPushToRoot	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellDropFinalComponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Drop the final component of the passed path

CALLED BY:	GLOBAL

PASS:		es:di - path

RETURN:		es:di - truncated.   Carry set if there was no final
		component. 
		

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
		"\"		->	"\"	CF set
		""		->	""	CF set
		"FOO"		->	""	
		"\FOO"		->	"\"
		"\FOO\BAR"	->	"\FOO"

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellDropFinalComponent	proc far
		uses	ax,bx,cx,dx,di,si,bp
		.enter

if ERROR_CHECK
	;
	; Validate that the path is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, es						>
FXIP<		mov	si, di						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
		mov	bx, di

	;
	; Go to the end, and get the string length
	;
		
		mov	cx, -1
		clr	al
		repne	scasb		; di points after NULL

	;
	; Point DI at the NULL.  If this is the only character, then
	; bail. 
	;
		
		dec	di
		cmp	di, bx
		stc
		je	done

	;
	; Point BEFORE the NULL.  If the string has only one
	; character, and it's a backslash, then leave it as is.
	;
		
		dec	di
		cmp	di, bx
		jne	continue
		cmp	{byte} es:[di], '\\'
		stc
		je	done
continue:

	;
	; Search backwards for a backslash.  If none found, just
	; return the null string
	;
		not	cx
		dec	cx
		mov	al, '\\'
		std
		repne	scasb
		cld
		jne	nullString

	;
	; Point DI at the backslash.  If it's the first character,
	; then store the null AFTER it.
	;
		
		inc	di		; es:di = backslash
		cmp	di, bx
		jne	storeNull
		inc	di		; go after leading backslash
storeNull:
		mov	{byte} es:[di], 0
		clc
done:
		.leave
		ret

nullString:
		mov	di, bx
		jmp	storeNull
ShellDropFinalComponent	endp

