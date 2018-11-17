COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driStrings.asm

AUTHOR:		Adam de Boor, Oct 30, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/30/91	Initial revision


DESCRIPTION:
	Localizable strings for this here driver.
		

	$Id: dosStrings.asm,v 1.1 97/04/10 11:55:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Strings		segment	lmem LMEM_TYPE_GENERAL
;------------------------------------------------------------------------------
;
;		       BAD BOOT SECTOR STRINGS
;
;------------------------------------------------------------------------------
InvalidFirstByteMsg	chunk.char "Missing jump instruction", 0
InvalidThirdByteMsg	chunk.char "Missing NOP in third byte", 0
InvalidSectorMsg	chunk.char "Invalid boot sector on drive ", 0
CouldNotReadBootSector	chunk.char "Couldn't read boot sector from drive ", 0

;------------------------------------------------------------------------------
;
;			   CRITICAL ERRORS
;
;------------------------------------------------------------------------------

LocalDefString writeProtected <'Disk is write-protected', 0>

LocalDefString driveNotReady <'No or unformatted disk in drive', 0>

LocalDefString unknownCommand <'Unknown command given to device', 0>

LocalDefString dataError <'Invalid data on disk (CRC error)', 0>

LocalDefString badRequest <'Invalid request given to device', 0>

LocalDefString seekError <'Could not seek to requested track', 0>

LocalDefString unknownMedia <'Unknown disk type in drive', 0>

LocalDefString sectorNotFound <'Cannot locate desired disk sector', 0>

LocalDefString writeFault <'Unable to write to disk', 0>

LocalDefString readFault <'Unable to read from disk', 0>

LocalDefString generalFailure <'Critical error: general failure', 0>

LocalDefString shareOverflow1 <'SHARE.EXE table overflow', 0>

LocalDefString deviceTimeout, <'XXXXXXXX not responding', 0>
	localize	"X's are replaced by 8-char device name when DRIVE_NOT_READY comes in for a character device. They must come first."

;------------------------------------------------------------------------------
;
;			 RANDOM OTHER STRINGS
;
;------------------------------------------------------------------------------
noBooteeString	chunk.char	"This disk is not bootable.\r\nSystem HALTED\r\n", 0

;LocalDefString insertMsg <'Put proper disk into drive \1', 0>

MS <LocalDefString tooFewFiles, <"Not enough file handles left for other tasks.", 0>>

LocalDefString ceDriveString, <'(drive \1)', 0>
	localize	"Second string in SysNotify box when critical error occurs for a disk device. @1 is replaced with the drive letter"

Strings		ends
