COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Net Library
FILE:		netDir.asm

AUTHOR:		Chung Liu, Dec 29, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/29/92   	Initial revision


DESCRIPTION:
	Entry points for directory services.
		

	$Id: netDir.asm,v 1.1 97/04/05 01:24:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetCommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetGetVolumeName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the volume name given the volume number

CALLED BY:	global
PASS:		ds:si	- buffer large enough to fit the volume name.
                          (for NetWare, at least NETWARE_VOLUME_NAME_SIZE
 			  bytes long.)
		dl	- volume number.
RETURN:		ds:si   - filled in with volume name.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/29/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetGetVolumeName	proc	far
	uses	di
	.enter
	mov	di, DR_NET_GET_VOLUME_NAME
	call	NetCallDriver
	.leave
	ret
NetGetVolumeName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetGetDriveCurrentPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current directory (full path) for a given
		drive.

CALLED BY:	global

PASS:		ds:si	- buffer large enough to fit the path.
			(At least DOS_STD_PATH_LENGTH long.)

		dl	- drive letter ('Y', for example.)

RETURN:		al	- return code (0 = successful)
		ds:si   - filled in with path name, null terminated.

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eric	4/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetGetDriveCurrentPath	proc	far
	uses	di
	.enter
	mov	di, DR_NET_GET_DRIVE_CURRENT_PATH
	call	NetCallDriver
	.leave
	ret
NetGetDriveCurrentPath	endp

NetCommonCode	ends
