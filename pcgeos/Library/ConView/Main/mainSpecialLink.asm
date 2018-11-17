COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	ConView Library
MODULE:		Main
FILE:		mainSpecialLink.asm

AUTHOR:		Cassie Hartzog, January 26, 1995

MESSAGES:

ROUTINES:
	Name			Description
	----			-----------
    INT MSLHandleSpecialLink	Looks for and handles special links.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cassie	1/26/95   	Initial revision


DESCRIPTION:
	Code needed for dealing with special hyperlinks.
		

	$Id: mainSpecialLink.asm,v 1.1 97/04/04 17:49:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; First, some useful macros.
;
ClrZero		macro
	mov	ax, 1
	or	ax, ax				; clear zero flag
endm

SetZero		macro
	xor	ax, ax				; clear zero flag
endm


BookFileCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLHandleSpecialLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for and handle special hyperlinks

CALLED BY:	CGVFollowLinkLow
PASS:		*ds:si - ContentGenView
		ss:bp - ContentTextRequest		
RETURN:		Z flag - clear if caller needs to follow link in CTR, 
			 (CTR_context may have been modified)
		       - set if caller shouldn't follow link
DESTROYED:	anything but ds, si, bp may be destroyed

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLHandleSpecialLink		proc	near
		cmp	{tchar}ss:[bp].CTR_context, '!'
		je	handleSpecial		
		ret

handleSpecial:
	;
	; The next char tells us what kind of special link this is.
	;
SBCS <		mov	al, ss:[bp].CTR_context.[1]		>
SBCS <		sub	al, ' '					>
DBCS <		mov	ax, ss:[bp].CTR_context.[1]		>
DBCS <		sub	ax, ' '					>
EC <		WARNING_S	INVALID_SPECIAL_LINK_CHAR	>
		js	done

SBCS <		cmp	al, length specialLinkHandlerTable	>
DBCS <		cmp	ax, length specialLinkHandlerTable	>
EC <		WARNING_A	INVALID_SPECIAL_LINK_CHAR	>
		ja	done
	;
	; Find the special handler's offset in the table below
	;
SBCS <		clr	ah					>

		shl	ax			; word align the index  
		mov	bx, ax
EC < swatLabel::						>
		call	cs:specialLinkHandlerTable[bx]
done:
		ret

MSLHandleSpecialLink		endp

;
; This table is indexed by the PC GEOS character set.
;
specialLinkHandlerTable		nptr.near \
		DefaultLinkHandler,		; C_SPACE
		DefaultLinkHandler,		; '!'
		DefaultLinkHandler,		; '"'
		DefaultLinkHandler,		; '#'
		DefaultLinkHandler,		; '$'
		DefaultLinkHandler,		; '%'
		DefaultLinkHandler,		; '&'
		DefaultLinkHandler,		; '''
		DefaultLinkHandler,		; '('
		DefaultLinkHandler,		; ')'
		DefaultLinkHandler,		; '*'
		DefaultLinkHandler,		; '+'
		DefaultLinkHandler,		; ','
		DefaultLinkHandler,		; '-'
		DefaultLinkHandler,		; '.'
		DefaultLinkHandler,		; '/'
		MSLStandardSoundError,		; '0'
		MSLStandardSoundWarning,	; '1'
		MSLStandardSoundNotify,		; '2'
		MSLStandardSoundNoInput,	; '3'
		MSLStandardSoundKeyClick,	; '4'
		MSLStandardSoundAlarm,		; '5'
		DefaultLinkHandler,		; '6'
		DefaultLinkHandler,		; '7'
		DefaultLinkHandler,		; '8'
		DefaultLinkHandler,		; '9'
		DefaultLinkHandler,		; ':'
		DefaultLinkHandler,		; ';'
		DefaultLinkHandler,		; '<'
		DefaultLinkHandler,		; '='
		DefaultLinkHandler,		; '>'
		DefaultLinkHandler,		; '?'
		DefaultLinkHandler,		; '@'
		MSLLaunchApplicationAndQuit,	; 'A'
		MSLGoBack,			; 'B'
		DefaultLinkHandler,		; 'C'
		DefaultLinkHandler,		; 'D'
		DefaultLinkHandler,		; 'E'
		DefaultLinkHandler,		; 'F'
		DefaultLinkHandler,		; 'G'
		MSLInvertHotspots,		; 'H'
		DefaultLinkHandler,		; 'I'
		DefaultLinkHandler,		; 'J'
		DefaultLinkHandler,		; 'K'
		DefaultLinkHandler,		; 'L'
		DefaultLinkHandler,		; 'M'
		MSLNextPage,			; 'N'
		DefaultLinkHandler,		; 'O'
		MSLPreviousPage,		; 'P'
		MSLQuitBookReader,		; 'Q'
		DefaultLinkHandler,		; 'R'
;;;		MSLPlaySoundAndLink,		; 'S'  - doesn't work yet!
		DefaultLinkHandler,		; 'S'
		MSLGotoTOC,			; 'T'
		DefaultLinkHandler,		; 'U'
		DefaultLinkHandler,		; 'V'
		DefaultLinkHandler,		; 'W'
		DefaultLinkHandler,		; 'X'
		DefaultLinkHandler,		; 'Y'
		DefaultLinkHandler,		; 'Z'
		DefaultLinkHandler,		; '['
		DefaultLinkHandler,		; '\'
		DefaultLinkHandler,		; ']'
		DefaultLinkHandler,		; '^'
		DefaultLinkHandler,		; '_'
		DefaultLinkHandler,		; '`'
		MSLLaunchApplication,		; 'a'
		DefaultLinkHandler,		; 'b'
		DefaultLinkHandler,		; 'c'
		DefaultLinkHandler,		; 'd'
		DefaultLinkHandler,		; 'e'
		DefaultLinkHandler,		; 'f'
		DefaultLinkHandler,		; 'g'
		DefaultLinkHandler,		; 'h'
		DefaultLinkHandler,		; 'i'
		DefaultLinkHandler,		; 'j'
		DefaultLinkHandler,		; 'k'
		DefaultLinkHandler,		; 'l'
		DefaultLinkHandler,		; 'm'
		DefaultLinkHandler,		; 'n'
		DefaultLinkHandler,		; 'o'
		DefaultLinkHandler,		; 'p'
		DefaultLinkHandler,		; 'q'
		DefaultLinkHandler,		; 'r'
;;;		MSLPlaySound,			; 's' - doesn't work yet!
		DefaultLinkHandler,		; 's'
		DefaultLinkHandler,		; 't'
		DefaultLinkHandler,		; 'u'
		DefaultLinkHandler,		; 'v'
		DefaultLinkHandler,		; 'w'
		DefaultLinkHandler,		; 'x'
		DefaultLinkHandler,		; 'y'
		DefaultLinkHandler,		; 'z'
		DefaultLinkHandler,		; '{'
		DefaultLinkHandler,		; '|'
		DefaultLinkHandler,		; '}'
		DefaultLinkHandler		; '~'

.assert (length specialLinkHandlerTable eq ('~' - ' ')+1)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultLinkHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear zero flag, so that link is handled normally
		by CGVFollowLinkLow.

CALLED BY:	MSLHandleSpecialLink
PASS:		nothing
RETURN:		Z flag is clear, so that link is treated normally
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultLinkHandler		proc	near
		mov	ax, 1
		or	ax, ax				; clear zero flag
		ret
DefaultLinkHandler		endp

if 0		; this doesn't work yet

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLPlaySoundAndLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a .wav file whose name follows the ! in CTR_context,
		and is terminated by a '.', and is followed by the NULL-
		termianted name of a link to follow after playing the sound.

CALLED BY:	
PASS:		ss:bp - ContentTextRequest
RETURN:		Z flag clear if there is a link name following the wav filename
		Z flag set if no link name
DESTROYED:	ax, cx, es, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLPlaySoundAndLink		proc	near
		uses	si
		.enter
	;
	; Look for the '.' which terminates the wav filename
	; and replace it with a NULL.
	;
		segmov	es, ss, ax
		lea	di, ss:[bp].CTR_context
		mov	cx, CONTEXT_NAME_BUFFER_SIZE
		sub	cx, (size tchar) * 2		; sub NULL and '!S'
DBCS <		mov	ax, '.' 					>
SBCS <		mov	ax, '.' 					>
		LocalFindChar
		jnz	playSound			; '.' not found!
		sub	di, size tchar
		mov	{tchar}es:[di], C_NULL	

playSound:
		pushf
		push	di				; save offset to link
		call	MSLPlaySound	
		pop	si				; ds:si <- link name
		popf
		jnz	noLink				; is there a link?
	;
	; Move the link name to the front of CTR_context
	;
		lea	di, ss:[bp].CTR_context		; es:di - dest
		segmov	es, ds, ax
		LocalCopyString	
		ClrZero					; do follow the link
done:
		.leave
		ret
noLink:
		SetZero
		jmp	done

MSLPlaySoundAndLink		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLPlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a .wav file whose name follows the ! in CTR_context 
		and is NULL-terminated.

CALLED BY:	
PASS:		ss:bp - ContentTextRequest
RETURN:		Zero set
DESTROYED:	ax, bx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
standardWavExtension	 tchar	".wav",0

MSLPlaySound		proc	near
		uses	si, ds
		.enter
	;
	; Save The current directory, go to the book's directory
	;
		call	FilePushDir
		call	MFChangeToBookDirectory
	;
	; Copy the wav filename, which follows the '!' char, to our buffer
	; and tack on the ".wav" extension.
	;
		sub	sp, size FileLongName
		mov	di, sp
		segmov	es, ss, ax		; es:di <- filename buffer
		mov	ds, ax	
		lea	si, {tchar}ss:[bp].CTR_context.[2] 
		LocalCopyString

		sub	di, size tchar			; point to the null
		segmov	ds, cs, ax
		mov	si, offset standardWavExtension
		LocalCopyString
		mov	di, sp				; es:di <- wav filename

	; Play the .wav file.

		clr	bx
		mov	{tchar}ss:[bp].CTR_context, 0
		lea	dx, ss:[bp].CTR_context
		call	WavPlayFile

		call	FilePopDir
		add	sp, size FileLongName
		SetZero				; don't follow any link!

		.leave
		ret
MSLPlaySound		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLInvertHotspots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Causes the hotspots on the current page to toggle
		invert themselves.

CALLED BY:	
PASS:		*ds:si - ContentGenView
RETURN:		Zero flag set
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLInvertHotspots		proc	near
		mov	ax, MSG_CT_TOGGLE_INVERT_AND_INVERT
		clr	di
		call	MUObjMessageSend
		SetZero
		ret
MSLInvertHotspots		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLLaunchApplicationAndQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		Zero flag set
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLLaunchApplicationAndQuit		proc	near
		call	MSLLaunchApplication
		jcxz	done
		GOTO	MSLQuitBookReader
done:
		ret
MSLLaunchApplicationAndQuit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLLaunchApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch an application

CALLED BY:	
PASS:		nada
RETURN:		cx - non-zero app was successfully launched, as far as 
			we can tell
		   - 0 if error finding or launching app
		Zero flag set
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	changes to App directory

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLLaunchApplication		proc	near
		uses	si, ds
		.enter
	;
	; Copy the app's token chars to a buffer
	;
		segmov	ds, ss, ax
		mov	es, ax
		sub	sp, size GeodeToken
		mov	di, sp				; es:di <- buffer
		lea	si, ss:[bp].CTR_context.[2]	; ds:si <- TokenChars
		mov	cx, size TokenChars
		rep	movsb
		xchg	si, di				;ds:di<-manufID string
		call	LocalAsciiToFixed		;dx <- ManufID
		mov	es:[si], dx
		mov	di, sp				;es:di <- GeodeToken
	;
	; Create a launch block for IACP.
	; 
		mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACPCreateDefaultLaunchBlock
		mov	bx, dx
		jc	error
	;
	; Launch app using IACP.
	;
		push	bp
		mov	ax, mask IACPCF_FIRST_ONLY or \
			    mask IACPCF_OBEY_LAUNCH_MODEL or \
		(IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
		call	IACPConnect
		mov	dx, ax
		mov_tr	ax, bp
		pop	bp
		jc	error

		push	bp
		mov_tr	bp, ax
		clr	cx, dx
		call	IACPShutdown
		pop	bp
		
		mov	cx, 1			; no error
done:
		add	sp, size GeodeToken
		SetZero
		
		.leave
		ret

error:
		clr	cx			; return error 
		jmp	done
MSLLaunchApplication		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLQuitBookReader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shuts down the app

CALLED BY:	
PASS:		nothing
RETURN:		Zero flag set
DESTROYED:	ax, bx, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLQuitBookReader		proc	near
		mov	ax, MSG_META_QUIT
		call 	UserSendToApplicationViaProcess
		SetZero
		ret
MSLQuitBookReader		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLStandardSound.....
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a standard sound and optionally follow a link,
		if one follows the special hyperlink chars.

CALLED BY:	
PASS:		ss:bp - ContentTextRequest
RETURN:		Z flag clear if there is a link name, now in CTR_context
		Z flag set if no link name
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLStandardSoundError		proc	near
		mov	ax, SST_ERROR
		GOTO	callUserStandardSound
MSLStandardSoundError		endp

MSLStandardSoundWarning		proc	near
		mov	ax, SST_WARNING
		GOTO	callUserStandardSound
MSLStandardSoundWarning		endp

MSLStandardSoundNotify		proc	near
		mov	ax, SST_NOTIFY
		GOTO	callUserStandardSound
MSLStandardSoundNotify		endp

MSLStandardSoundNoInput		proc	near
		mov	ax, SST_NO_INPUT
		GOTO	callUserStandardSound
MSLStandardSoundNoInput		endp

MSLStandardSoundKeyClick	proc	near
		mov	ax, SST_KEY_CLICK
		GOTO	callUserStandardSound
MSLStandardSoundKeyClick	endp

MSLStandardSoundAlarm		proc	near
		mov	ax, SST_ALARM
		FALL_THRU callUserStandardSound
MSLStandardSoundAlarm		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		callUserStandardSound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play the sound and look for a link name following the
		special hyperlink chars.

CALLED BY:	
PASS:		*ds:si - ConGenView
RETURN:		Z flag clear if there is a link name, now in CTR_context
		Z flag set if no link name
DESTROYED:	ax, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
callUserStandardSound		proc	near
		uses	ds, si
		.enter
		call	UserStandardSound
		cmp	{tchar}ss:[bp].CTR_context.[2], 0
		jz	done
	;
	; Move the link name to the front of CTR_context
	;
		lea	di, ss:[bp].CTR_context		; es:di <- dest
		mov	si, di
		add	si, (size tchar) * 2		; move past !x
		segmov	es, ss, ax
		mov	ds, ax
		LocalCopyString	
		ClrZero					; do follow the link
done:
		.leave
		ret
callUserStandardSound		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLGoBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to go back to previously viewed page

CALLED BY:	MSLHandleSpecialLink
PASS:		nothing
RETURN:		Z flag is set
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLGoBack	proc	near
	;
	; Send a "go back" message to the nav controller.
	;
		mov 	ax, MSG_CNC_GO_BACK
		GOTO	SendMsgToCNCAndSetZFlag
MSLGoBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLGotoTOC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to goto the TOC

CALLED BY:	MSLHandleSpecialLink
PASS:		nothing
RETURN:		Z flag is set
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLGotoTOC	proc	near
	;
	; Send a "goto TOC" message to the nav controller.
	;
		mov 	ax, MSG_CNC_GOTO_TOC
		GOTO	SendMsgToCNCAndSetZFlag
MSLGotoTOC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLNextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a "goto next page" message to the nav controller.	

CALLED BY:	MSLHandleSpecialLink
PASS:		nothing
RETURN:		Z flag is set
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLNextPage	proc	near
	;
	; Send a "goto next page" message to the nav controller.
	;
		mov 	ax, MSG_CNC_NEXT_PAGE
		GOTO	SendMsgToCNCAndSetZFlag
MSLNextPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLPreviousPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a "goto next page" message to the nav controller.

CALLED BY:	MSLHandleSpecialLink
PASS:		nothing
RETURN:		Z flag is set
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLPreviousPage	proc	near
	;
	; Send a "goto next page" message to the nav controller.
	;
		mov 	ax, MSG_CNC_PREVIOUS_PAGE
		GOTO	SendMsgToCNCAndSetZFlag
MSLPreviousPage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMsgToCNCAndSetZFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force queue a message to ContentNavControl

CALLED BY:	INT - utility
PASS:		ax - message to send
		*ds:si - ContentGenView
RETURN:		Zero flag is set
DESTROYED:	ax, bx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendMsgToCNCAndSetZFlag		proc	near

	; record the passed message, which goes to ContentNavControl

		push	si		
		mov	bx, segment ContentNavControlClass
		mov	si, offset ContentNavControlClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di

	; record a classed event, which is sent to...

		mov	bx, segment ContentNavControlClass
		mov	si, offset ContentNavControlClass
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_SELF
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di
		pop	si

	; the process, which will see that this message makes it
	; to the NavControl.
			
		mov	ax, MSG_GEN_SEND_TO_PROCESS
		call	ObjCallInstanceNoLock

		SetZero	
		ret
SendMsgToCNCAndSetZFlag		endp

BookFileCode	ends


