COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cdromSecondary.asm

AUTHOR:		Adam de Boor, Apr  6, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 6/92		Initial revision


DESCRIPTION:
	Secondary-IFS-driver functions to aid the primary to do our bidding.
		

	$Id: cdromSecondary.asm,v 1.1 97/04/10 11:55:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment resource	; XXX



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMGetExtAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch an extended attribute for a file that's not supported
		by the primary FSD

CALLED BY:	DR_DSFS_GET_EXT_ATTRIBUTE
PASS:		ds:si	= FileExtAttrDesc
		ax:dx	= far pointer. If segment non-zero, points to the
			  name of the file being messed with, in the current
			  directory. If segment is 0, the offset is the DOS
			  file handle.
RETURN:		carry set if attribute also not supported by secondary or
		    isn't present for the file:
			ax	= ERROR_ATTR_NOT_FOUND
				= ERROR_ATTR_NOT_SUPPORTED
		carry clear if attribute fetched.
DESTROYED:	di, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMGetExtAttribute proc	far
		.enter
		mov	ax, ERROR_ATTR_NOT_SUPPORTED
		stc
		.leave
		ret
CDROMGetExtAttribute endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMSetExtAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a particular extended attribute the primary IFS driver
		can't handle.

CALLED BY:	DR_SFS_SET_EXT_ATTRIBUTE
PASS:		ds:si	= FileExtAttrDesc
		ax:dx	= far pointer. If segment non-zero, points to the
			  name of the file being messed with, in the current
			  directory. If segment is 0, the offset is the DOS
			  file handle.
RETURN:		carry set if attribute also not supported by secondary or
		    isn't present for the file:
			ax	= ERROR_ATTR_NOT_FOUND
				= ERROR_ATTR_NOT_SUPPORTED
		carry clear if attribute fetched.
DESTROYED:	di, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMSetExtAttribute proc	far
		.enter
		mov	ax, ERROR_ATTR_CANNOT_BE_SET
		stc
		.leave
		ret
CDROMSetExtAttribute endp

Resident	ends
