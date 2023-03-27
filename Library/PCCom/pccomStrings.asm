COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        PCCom Library
FILE:		pccomStrings.asm

AUTHOR:		Cassie Hartzog, Nov 12, 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	11/12/93	Initial revision


DESCRIPTION:
	Contains localizable strings used by pccom.	

	$Id: pccomStrings.asm,v 1.1 97/04/05 01:26:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Strings		segment lmem LMEM_TYPE_GENERAL

;
;  File transfer strings
;
createError	chunk.char	": error creating file" , 0
cantOpen	chunk.char	": error opening file", 0
filenameError	chunk.char	cr, "Error reading filename" , 0
noSuchFile	chunk.char	cr, "File not found", 0
receiving	chunk.char	cr, "Receiving: ", 0
sending		chunk.char	cr, "Sending: ", 0
csErr		chunk.char	cr, "Checksum error", 0
writeErr	chunk.char	cr, "Error writing file", 0
transmitError	chunk.char	cr, "Error sending file ", 0
abortString	chunk.char	cr, "Transfer aborted.", cr, 0
xferComplete	chunk.char	cr, "File transfer complete. ", cr, 0
timeout		chunk.char	cr, "Timed out", 0
requesting	chunk.char	cr, "Requesting: ", 0

;
;  Path and File operation strings
;
DirectoryMadeString	chunk.char	"Directory created", 0
DirectoryRemovedString	chunk.char	"Directory removed", 0
FileRemovedString	chunk.char	"File removed", 0
FileRenamedString	chunk.char	"File renamed", 0
FileCopiedString	chunk.char	"File copied", 0

dirString 		chunk.char	'<DIR> ', 0
spaceString		chunk.char	'    ', 0
DirectoryOfString 	chunk.char	'Directory of ',0

;
;  Error strings for file operations
;
BadArgumentString	chunk.char	"Could not read argument", 0
UnknownFileError	chunk.char	"Unknown file error.",0
PathNotFoundString	chunk.char	"Path not found.", 0
FileNotFoundString	chunk.char	"File not found.", 0
FileExistsString	chunk.char	"File already exists.",0
FileInUseString		chunk.char	"File in use.",0
AccessDeniedString	chunk.char	"Access denied.", 0
CurrentDirectoryString	chunk.char	"Current directory", 0
DirectoryNotEmptyString	chunk.char	"Directory not empty.", 0
InsufficientSpace	chunk.char	"Insufficient space for destination file.", 0
InsufficientMemory	chunk.char	"Insufficient memory.",0

InvalidDrvStr		chunk.char	"no drive matches that name", 0
NoDiskStr		chunk.char	"there is no disk in that drive", 0
FreeSpaceStr		chunk.char	"> Free space: ", 0

;
;  Strings for miscellaneous operations
;
AckBackStr		chunk.char	"Acknowledge = ", 0
localize not
EchoBackStr		chunk.char	"Echoback = ", 0
localize not
onStr			chunk.char	"on", 0
localize not
offStr			chunk.char	"off", 0
localize not

InvalidArgStr		chunk.char	"Invalid argument format", 0
ArgDelimiterStr		chunk.char	"Argument delimiter is: ", 0
DelimiterErrStr		chunk.char	"Invalid delimiter.", 0

;
;  The remote PathTroubleRetryQuestion string is displayed by the a
;  pccomFileSelector if it has problems changing directories on the
;  remote machine.  If the use replies affirmative, we try the op
;  again, else we zap the FS
;

remotePathTroubleRetryQuestion	chunk.char	"Error encountered while changing directories.  Would you like to retry?", 0


Strings		ends









