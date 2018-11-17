COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	Config
MODULE:		UserInterface/User	
FILE:		userStrings.asm

AUTHOR:		Andrew Wilson, Sep 26, 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/26/90		Initial revision

DESCRIPTION:
	This file contains the localizable strings for the UI.	

	$Id: userStrings.asm,v 1.4 98/03/18 02:07:52 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Strings	segment	lmem	LMEM_TYPE_GENERAL

if GENERAL_DEVICE_STRINGS
LocalDefString outOfDiskSpaceStr1 <"There is no memory left is to create",0>
LocalDefString outOfDiskSpaceStr2 <"the work area state file.",0>
LocalDefString cannotCreateFileStr1 <"Could not create state file.",0>
LocalDefString cannotCreateFileStr2 <"Error encountered.", 0>
LocalDefString cannotCreateFileStr2PDA <"Error encountered.", 0>
else
LocalDefString outOfDiskSpaceStr1 <"The disk is too full to create",0>
LocalDefString outOfDiskSpaceStr2 <"the work area state file. (UI-01)",0>
LocalDefString cannotCreateFileStr1 <"Could not create state file.",0>
LocalDefString cannotCreateFileStr2 <"DOS or network error encountered. (UI-02)", 0>
LocalDefString cannotCreateFileStr2PDA <"DOS error encountered. (UI-02)", 0>
endif


ife	ERROR_CHECK
LocalDefString cannotLoadSPUIError <"Unable to load the specific UI library file. You may need to reinstall the software. (UI-03)",0>

if GENERAL_DEVICE_STRINGS

LocalDefString transferFileError <"Unable to open the clipboard file.",0>
LocalDefString sharedTokenDBOpenError <"Unable to open the shared token database file using the path specified in GEOS.INI.",0>
LocalDefString	localTokenDBOpenError <"Unable to open the local token database file in the PRIVDATA directory.",0>
LocalDefString tokenDBProtocolError	<"The shared token database file on the path specified in the GEOS.INI file is out of date and must be replaced.",0>

else

LocalDefString transferFileError <"Unable to open the clipboard file. (UI-04)",0>

LocalDefString sharedTokenDBOpenError <"Unable to open the shared token database file using the path specified in GEOS.INI (UI-25)",0>

LocalDefString	localTokenDBOpenError <"Unable to open the local token database file in the PRIVDATA directory. Try deleting the file. (UI-26)",0>

LocalDefString tokenDBProtocolError	<"The shared token database file on the path specified in the GEOS.INI file is out of date and must be replaced. (UI-27)",0>

endif	; _JEDI

.assert (length sharedTokenDBOpenError) le 130
.assert (length localTokenDBOpenError) le 130
.assert (length tokenDBProtocolError) le 130

endif

if GENERAL_DEVICE_STRINGS

LocalDefString cannotEnterPenModeError <"Unable to allocate enough memory",0>
LocalDefString cannotEnterPenModeErrorTwo <"to collect pen input.",0>

if 	not _UI_NO_HWR
LocalDefString cannotLoadHWRLibraryError <"Unable to load the Handwriting",0>
LocalDefString cannotLoadHWRLibraryErrorTwo <"Recognition Library.",0>
endif	; not _UI_NO_HWR

else

LocalDefString cannotEnterPenModeError <"Unable to allocate enough memory",0>
LocalDefString cannotEnterPenModeErrorTwo <"to collect pen input. (UI-05)",0>

LocalDefString cannotLoadHWRLibraryError <"Unable to load the Handwriting",0>
LocalDefString cannotLoadHWRLibraryErrorTwo <"Recognition Library. (UI-06)",0>

endif	; _JEDI

if GENERAL_DEVICE_STRINGS
LocalDefString cannotLoadAppError <"Unable to load application.",0 >
else
LocalDefString cannotLoadAppError <"Unable to load application. (UI-07)",0 >
endif

if GENERAL_DEVICE_STRINGS
LocalDefString loadSpoolerErrorOne <"Unable to load print spooler.",0>
LocalDefString loadSpoolerErrorTwo <"Error encountered.",0>
else
LocalDefString loadSpoolerErrorOne <"Unable to load print spooler.",0>
LocalDefString loadSpoolerErrorTwo <"You may need to reinstall the software. (UI-08)",0>
endif	; _JEDI

LocalDefString transferItemFilename <"Clipboard",0>

if GENERAL_DEVICE_STRINGS
LocalDefString cannotAllocUndoError <"Unable to allocate undo space.",0>
else
LocalDefString cannotAllocUndoError <"Unable to allocate undo space. (UI-09)",0>
endif

if DBCS_PCGEOS
appAlreadyRunning	chunk.wchar	C_DOUBLE_TURNED_COMMA_QUOTATION_MARK,
					"\1",
					C_DOUBLE_COMMA_QUOTATION_MARK,
					" is already running. ",
					"Would you like to bring the already-",
					"running copy to the front?",0
else
appAlreadyRunning	chunk.char	C_QUOTEDBLLEFT, "\1", C_QUOTEDBLRIGHT,
					" is already running. ",
					"Would you like to bring the already-",
					"running copy to the front?",0
endif

if DBCS_PCGEOS
openDocInRunningApp	chunk.wchar	"The application that created ",
					C_DOUBLE_TURNED_COMMA_QUOTATION_MARK,
					"\1",
					C_DOUBLE_COMMA_QUOTATION_MARK,
					" is already running. Would you like ",
					"the already-running copy to open ",
					"this document?", 0
else
openDocInRunningApp	chunk.char	"The application that created ",
					C_QUOTEDBLLEFT, "\1", C_QUOTEDBLRIGHT,
					" is already running. Would you like ",
					"the already-running copy to open ",
					"this document?", 0
endif

LocalDefString noKeyboardMessage <"You have no keyboard connected, and therefore cannot exit to DOS.",0>

LocalDefString shutdownConfirmMessage <"Are you sure you want to exit\1\2?",0 >
	localize "Shutdown confirmation message.  String argument @2 is the 'productName' key in the 'ui' category.  It defaults to null.  String argument @1 is a space padding if there is a 'productName', else is also null.";

;------------------------------------------------------------------------------
;	Misc strings
;------------------------------------------------------------------------------

ifdef SOFTWARE_EXPIRES	; in case SOFTWARE_EXPIRES isn't defined
if SOFTWARE_EXPIRES
LocalDefString softwareExpiredError <"This test version of the software has expired -- please download a new version.", 0>
endif
endif

LocalDefString spaceString <" ",0>

LocalDefString nullString 0

LocalDefString deskAccessoryPathname <"Desk Accessories",0 >

LocalDefString genValuePercentSign, <"%", 0>
	localize "This is the suffix for a GenValue that is displaying a percentage. You'll find such a beast in a mailbox-library progress box, for example. The percentage appears first, followed immediately by this string."

;------------------------------------------------------------------------------
;	Geode Load errors
;------------------------------------------------------------------------------

if DBCS_PCGEOS
LauncherErrorTextOne	chunk.wchar "Unable to start the launcher application ",
				C_DOUBLE_TURNED_COMMA_QUOTATION_MARK,
				"\1",
				C_DOUBLE_COMMA_QUOTATION_MARK,
				": \2", 0
GEOSExecErrorTextOne	chunk.wchar	"Unable to start the application ",
				C_DOUBLE_TURNED_COMMA_QUOTATION_MARK,
				"\1",
				C_DOUBLE_COMMA_QUOTATION_MARK,
				": \2", 0
else

LauncherErrorTextOne	chunk.char	"Unable to start the launcher application \322\1\323: \2",0

GEOSExecErrorTextOne	chunk.char	"Unable to start the application \322\1\323: \2",0

endif

if GENERAL_DEVICE_STRINGS

LocalDefString GeodeLoadNoMemError <"There\'s not enough memory available to start this application.",0>
LocalDefString GeodeLoadFileNotFoundError <"The application could not be found.",0>
LocalDefString GeodeLoadLibraryNotFoundError <"An associated library file could not be found.",0>

else

LocalDefString GeodeLoadNoMemError <"There\'s not enough memory available to start this application. Free up some memory by closing windows and applications you\'re not using. Then try again.\r\rError Code: UI-12",0>

LocalDefString GeodeLoadFileNotFoundError <"The application could not be found. The file may be missing, or it may contain errors or be damaged. You may wish to reinstall the software. Or, if you are attached to a network, there may be an error in the network configuration.\r\rError Code: UI-13",0>

LocalDefString GeodeLoadLibraryNotFoundError <"An associated library file could not be found. The file may be missing, or it may contain errors or be damaged. You may wish to reinstall the software. Or, if you are attached to a network, there may be an error in the network configuration.\r\rError Code: UI-14",0>
endif

if GENERAL_DEVICE_STRINGS
LocalDefString GeodeLoadFileNotFoundErrorPDA <"The application could not be found.",0>
LocalDefString GeodeLoadLibraryNotFoundErrorPDA <"An associated library file could not be found.",0>
else
LocalDefString GeodeLoadFileNotFoundErrorPDA <"The application could not be found. The file may be missing, or it may contain errors.\r\rError Code: UI-13",0>

LocalDefString GeodeLoadLibraryNotFoundErrorPDA <"An associated library file could not be found. The file may be missing, or it may contain errors.\r\rError Code: UI-14",0>
endif

if GENERAL_DEVICE_STRINGS
LocalDefString GeodeLoadMiscFileError <"Couldn\'t load the application.",0>
else
LocalDefString GeodeLoadMiscFileError <"Couldn\'t read the disk. The disk may be damaged or unformatted. If this is a diskette drive, the door may not be closed or the disk may not be fully inserted. Or, if you are attached to a network, there may be an error in the network configuration.\r\rError Code: UI-15",0>
endif

if GENERAL_DEVICE_STRINGS
LocalDefString GeodeLoadMiscFileErrorPDA <"Couldn\'t load the application.",0>
else
LocalDefString GeodeLoadMiscFileErrorPDA <"Couldn\'t read the disk. The disk may be damaged or unformatted.\r\rError Code: UI-15",0>
endif

if GENERAL_DEVICE_STRINGS
LocalDefString GeodeLoadDiskFullError <"There\'s not enough memory.",0>
else
LocalDefString GeodeLoadDiskFullError <"There\'s not enough room on the disk. You may want to move files not in use to another disk or delete unnecessary files.\r\rError Code: UI-17",0>
endif

if GENERAL_DEVICE_STRINGS
LocalDefString GeodeLoadProtocolError <"The application is incompatible with this version of the system software.",0>
LocalDefString GeodeLoadMultiLaunchError <"The application is already open.",0>
LocalDefString GeodeLoadFieldDetachingError <"The system is shutting down.",0>
LocalDefString GeodeLoadHeapSpaceError <"There\'s too much activity already in progress.",0>
else
LocalDefString GeodeLoadProtocolError <"The application is incompatible with this version of the system software.\r\rError Code: UI-16",0>

LocalDefString GeodeLoadMultiLaunchError <"The application is already open.",0>

LocalDefString GeodeLoadFieldDetachingError <"The system is shutting down.",0>

LocalDefString GeodeLoadHeapSpaceError <"There\'s too much activity already in progress.  Please close active applications and try again.\r\rError Code: UI-28",0>
endif

;For UILM_TRANSPARENT mode:
if GENERAL_DEVICE_STRINGS
LocalDefString GeodeLoadHeapSpaceErrorTransparent <"There\'s too much activity already in progress.",0>
else
LocalDefString GeodeLoadHeapSpaceErrorTransparent <"There\'s too much activity already in progress.\r\rError Code: UI-28",0>
endif

;------------------------------------------------------------------------------
;	Screen-related
;------------------------------------------------------------------------------

LocalDefString cgaDevName <'CGA: 640x200 Mono', 0>
	localize "Name for default CGA-compatible video driver.  Must match one of the names in the CGA driver exactly.";

LocalDefString egaDevName <'EGA: 640x350 16-color', 0>
	localize "Name for default EGA-compatible video driver.  Must match one of the names in the EGA driver exactly.";

LocalDefString vgaDevName <'VGA: 640x480 16-color', 0>
	localize "Name for default VGA-compatible video driver.  Must match one of the names in the VGA driver exactly.";

LocalDefString hgcDevName <'Hercules HGC: 720x348 Mono', 0>
	localize "Name for default HGC-compatible video driver.  Must match one of the names in the HGC driver exactly.";

LocalDefString mcgaDevName <'IBM MCGA: 640x480 Mono', 0>
	localize "Name for default MCGA-compatible video driver.  Must match one of the names in the MCGA driver exactly.";

LocalDefString svgaDevName <'VESA Compatible Super VGA: 800x600 16-color', 0>

	localize "Name for default Super VGA-compatible video driver.  Must match one of the names in the SVGA driver exactly.";


if GENERAL_DEVICE_STRINGS
LocalDefString noVideoMessage <"No working compatible video hardware found on this system.", 0>
else
LocalDefString noVideoMessage <"No working compatible video hardware found on this system. (UI-18)", 0>
endif


;------------------------------------------------------------------------------
;	DiskRestore errors/strings
;------------------------------------------------------------------------------
LocalDefString diskRestoreError	<"Unable to locate the expected disk: \1", 0>


if GENERAL_DEVICE_STRINGS
LocalDefString dreCouldntCreateNewDiskHandle <"There is not enough memory to keep track of the disk.", 0>
else
LocalDefString dreCouldntCreateNewDiskHandle <"There is not enough memory to keep track of the disk. Close some windows or applications to free up memory, then try again.\r\rError Code: UI-20", 0>
endif

if GENERAL_DEVICE_STRINGS
LocalDefString dreDriveNoLongerExists <"The drive in which it was located no longer exists. If you are attached to a network, there may be an error in the network configuration or you may not be logged in properly.", 0>
LocalDefString dreDriveNoLongerExistsPDA <"The drive in which it was located no longer exists.", 0>
else
LocalDefString dreDriveNoLongerExists <"The drive in which it was located no longer exists. If you are attached to a network, there may be an error in the network configuration or you may not be logged in properly.\r\rError Code: UI-19", 0>
LocalDefString dreDriveNoLongerExistsPDA <"The drive in which it was located no longer exists.\r\rError Code: UI-19", 0>
endif
	

if GENERAL_DEVICE_STRINGS
LocalDefString drePermissionDenied <"You do not have permission to use the appropriate network disk volume.", 0>
else
LocalDefString drePermissionDenied <"You do not have permission to use the appropriate network disk volume. See your computer system manager.\r\rError Code: UI-23", 0>
endif

if GENERAL_DEVICE_STRINGS

LocalDefString dreRemovableDriveIsBusy <"The drive in which the disk is located is otherwise occupied.", 0>
LocalDefString dreNotAttachedToServer <"You are not connected to the appropriate server to which the disk belongs.", 0>
LocalDefString drePermissionDeniedPDA <"You do not have permission to use the appropriate disk volume.", 0>
LocalDefString dreAllDrivesUsed <"There is no free drive letter to which the network disk may be mapped.", 0>
LocalDefString dreAllDrivesUsedPDA <"There is no free drive letter to which the disk may be mapped.", 0>

else

LocalDefString dreRemovableDriveIsBusy <"The drive in which the disk is located is otherwise occupied. You may wish to try again later.\r\rError Code: UI-21", 0>

LocalDefString dreNotAttachedToServer <"You are not connected to the appropriate server to which the disk belongs. See your computer system manager.\r\rError Code: UI-22", 0>

	
LocalDefString drePermissionDeniedPDA <"You do not have permission to use the appropriate disk volume.\r\rError Code: UI-23", 0>
	

LocalDefString dreAllDrivesUsed <"There is no free drive letter to which the network disk may be mapped. See your computer system manager.\r\rError Code: UI-24", 0>

LocalDefString dreAllDrivesUsedPDA <"There is no free drive letter to which the disk may be mapped.\r\rError Code: UI-24", 0>

endif	

LocalDefString diskRestorePrompt <"Please insert the disk \1 into drive \2 so that a file that was opened the last time you were using the software may be re-opened.", 0>
	

diskInDriveMoniker	chunk	VisMoniker
	VisMoniker <
		<		; VM_type
		    0,			; VMT_MONIKER_LIST
		    0,			; VMT_GSTRING
		    DAR_NORMAL,		; VMT_GS_ASPECT_RATIO
		    DC_TEXT		; VMT_GS_COLOR
		>,
		0		; VM_width
	>
	VisMonikerText <
		0			; VMT_mnemonicOffset
	>
if DBCS_PCGEOS
	wchar	"Disk Is In The Drive", 0
else
	char	"Disk Is In The Drive", 0
endif
diskInDriveMoniker	endc

cancelDiskRestoreMoniker	chunk	VisMoniker
	VisMoniker <
		<		; VM_type
		    0,			; VMT_MONIKER_LIST
		    0,			; VMT_GSTRING
		    DAR_NORMAL,		; VMT_GS_ASPECT_RATIO
		    DC_TEXT		; VMT_GS_COLOR
		>,
		0		; VM_width
	>
	VisMonikerText <
		0			; VMT_mnemonicOffset
	>
if DBCS_PCGEOS
	wchar	"Stop Trying To Reopen The File", 0
else
	char	"Stop Trying To Reopen The File", 0
endif
cancelDiskRestoreMoniker	endc


if GENERAL_DEVICE_STRINGS

LocalDefString NoClipboardToRemoteCopyError <"The clipboard is empty.\rClipboard transfer aborted.",0>
LocalDefString TimeoutError <"The connection to the remote machine was broken.\rClipboard transfer aborted.",0>
LocalDefString CreatePortError <"Could not open a connection to the other machine.\rYour system may not be configured correctly.\rClipboard transfer aborted.",0>
LocalDefString CreateSocketError <"Could not open a connection to the other machine.\rClipboard transfer aborted.",0>
LocalDefString BadRemoteIniSettingsError <"The connection has not been setup in Preferences.\rClipboard transfer aborted.",0>
LocalDefString NoNetLibraryError <"Unable to load the net library.",0>
LocalDefString NetDriverNotFoundError <"Could not load the COMM driver.",0>
LocalDefString NoConnectionError <"Could not establish a connection to the remote machine.\rClipboard transfer aborted.",0>
LocalDefString NetDriverPortInUseError <"The remote connection is already in use by another application or device.\rClipboard transfer aborted.",0>

else

LocalDefString NoClipboardToRemoteCopyError <"The clipboard is empty.\rClipboard transfer aborted.\r\rError Code: UI-29",0>
	

LocalDefString TimeoutError <"The connection to the remote machine was broken.\rClipboard transfer aborted.\r\rError Code: UI-30",0>
	

LocalDefString CreatePortError <"Could not open a connection to the other machine.\rYour system may not be configured correctly.\rClipboard transfer aborted.\r\rError Code: UI-31",0>
	

LocalDefString CreateSocketError <"Could not open a connection to the other machine.\rClipboard transfer aborted.\r\rError Code: UI-32",0>
	

LocalDefString BadRemoteIniSettingsError <"The connection has not been setup in Preferences.\rClipboard transfer aborted.\r\rError Code: UI-33",0>
	

LocalDefString NoNetLibraryError <"Unable to load the net library.\rYou may need to reinstall the software.\r\rError Code: UI-34",0>
	

LocalDefString NetDriverNotFoundError <"Could not load the COMM driver.\rThe file may be missing, or your system may not be configured correctly.\r\rError Code: UI-35",0>
	

LocalDefString NoConnectionError <"Could not establish a connection to the remote machine.\rClipboard transfer aborted.\r\rError Code: UI-36",0>
	

LocalDefString NetDriverPortInUseError <"The remote connection is already in use by another application or device.\rClipboard transfer aborted.\r\rError Code: UI-37",0>

endif
	

if 0
ClipboardSendComplete		chunk.char \
	"The clipboard has been transferred to the other machine.",0

ClipboardReceiveComplete	chunk.char \
	"The clipboard has been received from the other machine.",0
endif

LocalDefString SaveOptionsQuery <"You have changed the configuration of \1.  Would you like to save those changes?",0>

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;	Pre-defined pointer shapes
;------------------------------------------------------------------------------

pMove	chunk
	PointerDef <
	mask PDW_ALWAYS_SHOW_PTR or 16,	; PD_width
	16,				; PD_height
	0,				; PD_hotX
	0				; PD_hotY
>

	byte	11100000b, 00000000b,
		11111000b, 00000000b,
		11111110b, 00000000b,
		01111111b, 10000000b,
		01111111b, 11100000b,
		00111111b, 11110000b,
		00111111b, 11110000b,
		00011111b, 11100000b,
		00011111b, 11111111b,
		00001111b, 11111111b,
		00001111b, 11111111b,
		00000110b, 11111111b,
		00000000b, 11111111b,
		00000000b, 11111111b,
		00000000b, 11111111b,
		00000000b, 11111111b		

	byte	11100000b, 00000000b,
		10011000b, 00000000b,
		10000110b, 00000000b,
		01000001b, 10000000b,
		01000000b, 01100000b,
		00100000b, 00010000b,
		00100000b, 00010000b,
		00010000b, 01100000b,
		00010000b, 00111111b,
		00001001b, 00000001b,
		00001001b, 10111101b,
		00000110b, 10111101b,
		00000000b, 10111101b,
		00000000b, 10111101b,
		00000000b, 10000001b,
		00000000b, 11111111b		

pMove	endc

pCopy	chunk
	PointerDef <
	mask PDW_ALWAYS_SHOW_PTR or 16,	; PD_width
	16,				; PD_height
	0,				; PD_hotX
	0				; PD_hotY
>

	byte	11100000b, 00000000b,
		11111000b, 00000000b,
		11111110b, 00000000b,
		01111111b, 10000000b,
		01111111b, 11100000b,
		00111111b, 11110000b,
		00111111b, 11110000b,
		00011111b, 11100000b,
		00011111b, 11111111b,
		00001111b, 11111111b,
		00001111b, 11111111b,
		00000110b, 11111111b,
		00000000b, 11111111b,
		00000000b, 11111111b,
		00000000b, 11111111b,
		00000000b, 11111111b		

	byte	11100000b, 00000000b,
		10011000b, 00000000b,
		10000110b, 00000000b,
		01000001b, 10000000b,
		01000000b, 01100000b,
		00100000b, 00010000b,
		00100000b, 00010000b,
		00010000b, 01100000b,
		00010000b, 00111111b,
		00001001b, 00000001b,
		00001001b, 10000001b,
		00000110b, 10000001b,
		00000000b, 10000001b,
		00000000b, 10000001b,
		00000000b, 10000001b,
		00000000b, 11111111b		

pCopy	endc

pDefaultMoveCopy	chunk
	PointerDef <
	mask PDW_ALWAYS_SHOW_PTR or 16,	; PD_width
	16, 				; PD_height
	7,				; PD_hotX
	7				; PD_hotY
>

	byte	00000111b, 11000000b,
		00011111b, 11110000b,
		00111111b, 11111000b,
		01111111b, 11111100b,
		01111111b, 11111100b,
		11111111b, 11111110b,
		11111111b, 11111110b,
		11111111b, 11111110b,
		11111111b, 11111110b,
		11111111b, 11111110b,
		01111111b, 11111100b,
		01111111b, 11111100b,
		00111111b, 11111000b,
		00011111b, 11110000b,
		00000111b, 11000000b,
		00000000b, 00000000b

	byte	00000111b, 11000000b,
		00011000b, 00110000b,
		00100000b, 00001000b,
		01000111b, 11000100b,
		01000011b, 11100100b,
		10010001b, 11110010b,
		10011000b, 11110010b,
		10011100b, 01110010b,
		10011110b, 00110010b,
		10011111b, 00010010b,
		01001111b, 10000100b,
		01000111b, 11000100b,
		00100000b, 00001000b,
		00011000b, 00110000b,
		00000111b, 11000000b,
		00000000b, 00000000b

pDefaultMoveCopy	endc


Strings	ends


