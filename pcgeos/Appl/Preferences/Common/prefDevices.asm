COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Preferences -- Common Code
FILE:		prefDevices.asm

AUTHOR:		Adam de Boor, Oct  2, 1990

ROUTINES:
	Name			Description
	----			-----------
	PrefDeviceEnum		Locate all devices supported by drivers with
				a specific token
	PrefDeviceSetMoniker	Set the moniker for a dynamic list entry from
				the array of known devices.
	PrefDeviceFetchDevice	Fetch the device descriptor for a particular
				device number.
	PrefDeviceFree		Clean up a device descriptor block.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/ 2/90	Initial revision


DESCRIPTION:
	Functions to implement device-enumeration for preferences.
		

	$Id: prefDevices.asm,v 1.1 97/04/04 16:28:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefSaveVideo
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
screen0		char	'screen0', 0
PrefSaveVideo	proc	far	

		uses ds, es, di, dx, cx, si, bx

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
		mov	dx, offset deviceKey
		push	bp
		mov	bp, INITFILE_INTACT_CHARS or size oldDevice
		call	InitFileReadString
EC <		ERROR_C	SCREEN_0_DEVICE_MISSING				>
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
		.leave
		ret
PrefSaveVideo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefRestoreVideo
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
PrefRestoreVideo	proc	far	

		uses ds, es, di, dx, cx, si, bx

SBCS <oldDevice	local	GEODE_MAX_DEVICE_NAME_LENGTH dup(char)	>
DBCS <oldDevice	local	GEODE_MAX_DEVICE_NAME_LENGTH dup(wchar)	>
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
		mov	bp, INITFILE_INTACT_CHARS or size oldDevice
		call	InitFileReadString
EC <		ERROR_C	SCREEN_0_DEVICE_MISSING				>
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
		.leave
		ret
PrefRestoreVideo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDiscardSavedVideo
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
PrefDiscardSavedVideo	proc	far	

		uses ds, si, cx, dx, ax, bx

		.enter

		segmov	ds, cs, cx
		mov	si, offset screen0
		mov	dx, offset oldDeviceKey
		call	InitFileDeleteEntry
		
		mov	dx, offset oldDriverKey
		call	InitFileDeleteEntry

		.leave
		ret
PrefDiscardSavedVideo	endp
