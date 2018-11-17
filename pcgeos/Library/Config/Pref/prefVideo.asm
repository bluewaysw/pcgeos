COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefUtils.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 9/92   	Initial version.

DESCRIPTION:
	Misc utilities

	$Id: prefVideo.asm,v 1.1 97/04/04 17:50:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PREFSAVEVIDEO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the video settings for screen 0

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
oldDeviceKey	char	'old'
deviceKey	char	'device',0
oldDriverKey	char	'old'
driverKey	char	'driver',0

screen0		char	'screen0', 0

PREFSAVEVIDEO	proc	far	uses ds, es, di, dx, cx, si, bx

SBCS <oldDevice	local	GEODE_MAX_DEVICE_NAME_LENGTH dup(char)		>
DBCS <oldDevice	local	GEODE_MAX_DEVICE_NAME_LENGTH dup(wchar)		>

	.enter
	;
	; Fetch the previous device.  It may be the case that we're
	; running on an autodetect system, so don't whine if we can't
	; find a key, just bail.
	;

	segmov	es, ss			; es:di <- buffer
	lea	di, ss:[oldDevice]
	segmov	ds, cs, cx		; ds, cx <- cs
	mov	si, offset screen0
	mov	dx, offset deviceKey
	push	bp
	mov	bp, INITFILE_INTACT_CHARS or length oldDevice
	call	InitFileReadString
	jc	donePop

	;
	; Write it out again under a different name.
	; 

	mov	cx, cs
	mov	dx, offset oldDeviceKey
	call	InitFileWriteString

	;
	; Do the same for the previous driver.
	;

	mov	dx, offset driverKey
	call	InitFileReadString
EC <		ERROR_C	SCREEN_0_DRIVER_MISSING				>
	mov	cx, cs
	mov	dx, offset oldDriverKey
	call	InitFileWriteString
	pop	bp
done:
	.leave
	ret

donePop:
	pop	bp
	jmp	done
PREFSAVEVIDEO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PREFRESTOREVIDEO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the video settings for screen 0

CALLED BY:	EXTERNAL

PASS:		nothing

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PREFRESTOREVIDEO	proc	far	uses ds, es, di, dx, cx, si, bx

SBCS <oldDevice	local	GEODE_MAX_DEVICE_NAME_LENGTH dup(char)		>
DBCS <oldDevice	local	GEODE_MAX_DEVICE_NAME_LENGTH dup(wchar)		>

	.enter

	;
	; Fetch the previous device.
	;

	segmov	es, ss			; es:di <- buffer
	lea	di, ss:[oldDevice]
	segmov	ds, cs, cx		; ds, cx <- cs
	mov	si, offset screen0
	mov	dx, offset oldDeviceKey
	push	bp
	mov	bp, INITFILE_INTACT_CHARS or length oldDevice
	call	InitFileReadString
	jc	noPrevious

	;
	; Write it out again as the current device
	; 

	mov	cx, cs
	mov	dx, offset deviceKey
	call	InitFileWriteString
	;
	; Do the same for the previous driver.
	;
	mov	dx, offset oldDriverKey
	call	InitFileReadString
EC <		ERROR_C	SCREEN_0_DRIVER_MISSING				>
	mov	cx, cs
	mov	dx, offset driverKey
	call	InitFileWriteString
	pop	bp
	call	PrefDiscardSavedVideo
	call	InitFileCommit
done:
	.leave
	ret


noPrevious:
	
	;
	; Well, there's no "old" device, which means we'll have to go
	; back to autodetect, by nuking the current device & driver keys.
	;
	mov	cx, cs
	mov	dx, offset deviceKey
	mov	si, offset screen0
	call	InitFileDeleteEntry

	mov	dx, offset driverKey
	mov	si, offset screen0
	call	InitFileDeleteEntry
	pop	bp
	jmp	done

PREFRESTOREVIDEO	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PREFDISCARDSAVEDVIDEO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discard the video settings saved against the possibility of
	having chosen an incorrect video driver.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PREFDISCARDSAVEDVIDEO	proc	far	uses ds, si, cx, dx, ax, bx
	.enter
	segmov	ds, cs, cx
	mov	si, offset screen0
	mov	dx, offset oldDeviceKey
	call	InitFileDeleteEntry
	
	mov	dx, offset oldDriverKey
	call	InitFileDeleteEntry
	.leave
	ret
PREFDISCARDSAVEDVIDEO	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PrefTestVideoDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the selected video device is available on the machine.

CALLED BY:	EXTERNAL

PASS:		^lbx:si	= PrefDeviceList

RETURN:		carry clear if device is available, or we can't tell if it's
		present
			ax	= DisplayType (al, really)

		carry set if device is unavailable:
			ax	= 0 if definitely not present
				= GeodeLoadError+1 if just couldn't load the
				  driver for some reason.
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
	Just invoke the appropriate method of the list and invert the
	sense of the carry to what our caller expects.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTestVideoDevice	proc	far
	mov	ax, MSG_PREF_TOC_LIST_CHECK_DEVICE_AVAILABLE
	mov	di, mask MF_CALL
	call	ObjMessage
	cmc
	ret
PrefTestVideoDevice	endp

