COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CD ROM Library
FILE:		cdextensions.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		Initial version
	Fred	11/91		Revised version

DESCRIPTION:
	This file contains the CD calls which interface with the MSCDEX
	CD-ROM extensions, version 2.2.

RCS STAMP:
	$Id: cdextensions.asm,v 1.1 97/04/04 17:43:59 newdeal Exp $

------------------------------------------------------------------------------@
CommonCode	segment	resource	;start of code resource

	global	CDRomEntry:far
	global	CDGetDriveNumbers:far
	global	CDGetDriveList:far
	global	CDGetCopyright:far
	global	CDGetAbstract:far
	global	CDGetBibliography:far
	global	CDGetVTOC:far
	global	CDGetDiskRead:far
	global	CDGetDiskWrite:far
	global	CDGetDriveCheck:far
	global	CDGetExtenVersion:far
	global	CDGetDriveLetters:far
	global	CDGetVolDescriptor:far
	global	CDGetDirectoryEntry:far
	global	CDInit:far
	global	CDInputFlush:far
	global  CDOutputFlush:far
	global  CDDeviceOpen:far
	global  CDDeviceClose:far
	global	CDReadAddressDeviceHeader:far
	global	CDHeadLocation:far
	global	CDAudioChannelInfo:far
	global	CDReadDriveBytes:far
	global	CDDeviceStatus:far
	global	CDSectorSize:far
	global	CDVolumeSize:far
	global	CDMediaChanged:far
	global	CDAudioDiskInfo:far
	global	CDAudioTrackInfo:far
	global	CDQChannelInfo:far
	global	CDSubChannelInfo:far
	global	CDUpcCode:far
	global	CDAudioStatus:far
	global	CDIOCTLInput:far
	global	CDIOCTLOutput:far
	global	CDEjectDisk:far
	global	CDLockDoor:far
	global	CDResetDrive:far
	global	CDAudioChannelControl:far
	global	CDCloseTray:far
	global	CDSeek:far
	global	CDPlayAudio:far
	global	CDStopAudio:far
	global	CDResumeAudio:far
	global	CDReadLong:far
	global	CDReadLongPrefetch:far
	global	CDWriteLong:far
	global	CDWriteLongVerify:far

	global	CDPlayTrack:far
	global	ConvertRedBookToAbsolute:far
	global	Int2f:far




;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------
ACCESS_FILE_INT		= 1


include	geos.def
include geode.def
include	library.def
include resource.def
include	win.def
include lmem.def
include timer.def
include	system.def
include	file.def
include	fileEnum.def
include	vm.def
include thread.def
include Objects/metaC.def
include Internal/fileInt.def

DefLib cdrom.def




COMMENT @---------------------------------------------------------------------

FUNCTION:	CDRomEntry

DESCRIPTION:	Entry point for library

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	8/91		initial version

------------------------------------------------------------------------------@
CDRomEntry	proc	far
	clc				; this is needed for all library
	ret				; entry points
CDRomEntry endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetDriveNumbers

DESCRIPTION:	MSCDEX will return the number of CD-ROM drives and the starting
		drive letter. The first CD-ROM device will be installed at
		starting drive letter. 

		This function can be used to determine if MSCDEX is installed
		by setting BX to zero before executing int 2fh.

PASS:

RETURN:		bx	= number of CD-ROM drive letters used
		bx 	= 0, MSCDEX not installed
		cx	Starting drive letter of CD-ROMS(A=0, B=1, ...Z=25)


DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetDriveNumbers	proc	far
	mov	bx, 0
	mov	ax, CD_GET_DRIVE_NUMBER
	call	Int2f
	ret
CDGetDriveNumbers endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetDriveList

DESCRIPTION:	Use the MSCDEX CD extension call to get number of CD
		drives in use, and also the starting drive letter.

PASS:		es:bx	= pointer to Buffer. Must be at least 15 bytes long.

RETURN:		es:bx	= pointer to Buffer.  Buffer filled as follows

		Buffer	byte 	0	; subunit of driver on first CD drive
			dword	<far address of device header> 


DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetDriveList	proc	far
	mov	ax, CD_GET_DRIVE_LIST
	call	Int2f
	ret
CDGetDriveList  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetCopyright

DESCRIPTION:	MSCDEX will copy the name of the copyright file in the
		VTOC for that drive letter into the buffer space provided.

PASS:		es:bx   = Transfer address; pointer to 38 byte buffer
		cx	= CD-ROM drive number

RETURN:		es:bx	= pointer to  copyright file name string
		carry	= set on error
		ax	=  If drive letter is not CD-ROM drive
			   ERROR_INVALID_DRIVE returned
	
DESTROYED:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetCopyright	proc	far
	mov	ax, CD_GET_COPYRIGHT
	call	Int2f
	ret
CDGetCopyright  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetAbstract

DESCRIPTION:	MSCDEX will copy the name of the abstract file in the VTOC
		for that drive letter into the buffer space provided.

PASS:		es:bx   = Transfer address; pointer to 38 byte buffer
		cx	= CD-ROM drive number

RETURN:		es:bx	= pointer to abstract file name string
		carry	= set on error
		ax	=  If drive letter is not CD-ROM drive, 
			   ERROR_INVALID_DRIVE returned
	

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetAbstract	proc	far
	mov	ax, CD_GET_ABSTRACT
	call	Int2f
	ret
CDGetAbstract  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetBibliography

DESCRIPTION:	MSCDEX will copy the name of the bibliographic documentation
		file in the VTOC for that drive letter into the buffer space
		provided.

PASS:		es:bx   = Transfer address; pointer to 38 byte buffer
		cx	= CD-ROM drive number

RETURN:		es:bx	= bibliography file name string
		carry	= set on error
		ax	=  If drive letter is not CD-ROM drive, 
			   ERROR_INVALID_DRIVE returned
	
DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetBibliography	proc	far
	mov	ax, CD_GET_BIBLIOGRAPHY
	call	Int2f
	ret
CDGetBibliography  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetVTOC

DESCRIPTION:	MSCDEX CD extension call to scan volume descriptors on a disk.

PASS:		es:bx   = Transfer address; pointer to 2048 byte buffer
		cx	= CD-ROM drive number
		dx	= sector index 		0 reads first vol descriptor
						1 reads 2nd volume descriptor
						and so on

RETURN:		carry	= set on error
		ax	if no error
				  1    = standard volume descriptor read
				0ffh = volume descriptor terminator
				  0    = all other types
			if error
		al	= ERROR_INVALID_DRIVE or ERROR_NOT_READY


DESTROYED:	cx, dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetVTOC	proc	far
	mov	ax, CD_READ_VTOC
	call	Int2f
	ret
CDGetVTOC  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetDiskRead

DESCRIPTION:	Absolute disk read. Function corresponds to DOS interrupt 25h

PASS:		es:bx   = Disk Transfer address; pointer to copy data to
		cx	= CD ROM drive number
		dx	= Number of sectors to read
		si	= High word of starting sector
		di	= Low word of starting sector

RETURN:		carry	= set on error
			= if error
		al	= ERROR_INVALID_DRIVE or ERROR_NOT_READY


DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetDiskRead	proc	far
	mov	ax, CD_DISK_READ
	call	Int2f
	ret
CDGetDiskRead  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetDiskWrite

DESCRIPTION:	Absolute disk write. Function corresponds to DOS interrupt
		26h. Not supported at this time and is reserved

PASS:		es:bx   = Disk Transfer address; pointer to copy data from
		cx	= CD ROM drive letter
		dx	= Number of sectors to read
		si:di	= Starting sector

RETURN:		carry	= set on error


DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetDiskWrite	proc	far
	mov	ax, CD_DISK_WRITE
	call	Int2f
	ret
CDGetDiskWrite  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetDriveCheck

DESCRIPTION:	Returns whether or not a drive letter is a CD-ROM drive
		supported by MSCDEX

PASS:		cx	= CD-ROM drive letter (A=0, B=1,...Z=25)

RETURN:		ax	= 0 - drive not supported by MSCDEX
			= nonzero - drive supported by MSCDEX
		bx	= 0xADAD if extensions are installed

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetDriveCheck	proc	far
	mov	ax, CD_DRIVE_CHECK
	call	Int2f
	ret
CDGetDriveCheck  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetExtenVersion

DESCRIPTION:	Returns the version number of the CD-ROM extensions 
		installed. Does not work on versions less than 2.0

PASS:		bx	= 0

RETURN:		bh	= major version number in binary
		bl	= minor version number in binary


DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetExtenVersion	proc	far
	mov	ax, CD_MSCDEX_VERSION
	call	Int2f
	ret
CDGetExtenVersion  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetDriveLetters

DESCRIPTION:	Returns a list of CD drive letters.
		This command exists because the CD-ROM
		drive letters may be noncontiguous in a network
		environment.

PASS:		es:bx	= Transfer address; pointer to buffer to copy drive
			  letter device list. Buffer size will be a 
			  multiple of number of drives returned by
			  GetCDDriveNumbers. 

RETURN:		es:bx  = pointer to transfer address

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetDriveLetters	proc	far
	mov	ax, CD_DRIVE_LETTERS
	call	Int2f
	ret
CDGetDriveLetters  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetVolDescriptor

DESCRIPTION:	Allows user to get supplementary volume descriptor from drive
		

PASS:		bx	= 0 - Get Preference
			  1 - Set Preference
		cx	= CD-ROM Drive letter
		dx	= if BX = Get Preference
			  dx = 0
			  
			  if BX = Set Preference
			   dh = Volume Descriptor Preference
				1  PVD	Primary Volume Descriptor
			        2  SVD	Supplementary Volume Descriptor
			   dl = Supplementary Volume Descriptor Preference
				if dh = PVD
				dl = 0
				if dh = SVD
				  1 - shift-kanji 

RETURN:		carry - set on error
		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetVolDescriptor	proc	far
	mov	ax, CD_VOLUME_DESCRIPTORS
	call	Int2f
	ret
CDGetVolDescriptor  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDGetDirectoryEntry

DESCRIPTION:	Gets directory entry. The pathname expected is a 
		null-terminated string like '\a\b\c.txt'. The path must
		consist only of valid High Sierra or ISO-9660 filename
		characters and must not contain any wildcards nor may it
		contain entries for '.' or '..'.
		installed

PASS:		cl	= CD-ROM Drive letter
		ch	= copy flags (bit 0: 0 - direct copy, 1 - copied to 
			  structure)
		es:bx   = pointer to buffer with null-terminated pathname
		si:di   = pointer to buffer copy directory record information

RETURN:		ax	= 0 if disk is High Sierra
			= 1 if disk is ISO-9660
		carry	= set on error
		ax	= error codes if carry set

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDGetDirectoryEntry	proc	far
	mov	ax, CD_DIRECTORY_ENTRY
	call	Int2f
	ret
CDGetDirectoryEntry  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDInit

DESCRIPTION:	Use the MSCDEX CD extension call to init CD drive when device
		is installed. 

PASS:		es:bx	- Pointer to InitStruc
 		cx - drive number

RETURN:		ax - error code

DESTROYED:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDInit	proc	far
	mov	es:[bx].I_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].I_Header.CD_subunit, 0
	mov	es:[bx].I_Header.CD_status, 0
	mov	es:[bx].I_Header.CD_code, CDSR_INIT

	mov	ax, CD_SEND_REQUEST		; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].I_Header.CD_status	; return error code
	ret
CDInit	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:  CDInputFlush

DESCRIPTION:	Requestthat the device driver free all input buffers and 
		clear any pending requests.

PASS:		es:bx - Pointer to FlushInput structure
	
RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	11/91		initial version

------------------------------------------------------------------------------@
CDInputFlush  proc	far
	mov	es:[bx].IF_Header.CD_code, CDSR_INPUT_FLUSH
	mov	es:[bx].IF_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].IF_Header.CD_subunit, 0
	mov	es:[bx].IF_Header.CD_status, 0

	mov	ax, CD_SEND_REQUEST		; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].IF_Header.CD_status	; return error code
	ret
CDInputFlush  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDOutputFlush

DESCRIPTION:	Request that the device driver write all unwritten buffers to
		disk.

PASS:		es:bx - Pointer to FlushOutput structure
	
RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	11/91		initial version

------------------------------------------------------------------------------@
CDOutputFlush  proc	far
	mov	es:[bx].OF_Header.CD_code, CDSR_OUTPUT_FLUSH
	mov	es:[bx].OF_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].OF_Header.CD_subunit, 0
	mov	es:[bx].OF_Header.CD_status, 0

	mov	ax, CD_SEND_REQUEST		; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].OF_Header.CD_status	; return error code
	ret
CDOutputFlush  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDDeviceOpen

DESCRIPTION:	Used by the device driver to monitor how many different 
		callers are currently using the CD-ROM device driver.

PASS:		es:bx - Pointer to DeviceOpen structure
	
RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	11/91		initial version

------------------------------------------------------------------------------@
CDDeviceOpen  proc	far
	mov	es:[bx].DO_Header.CD_code, CDSR_DEVICE_OPEN
	mov	es:[bx].DO_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].DO_Header.CD_subunit, 0
	mov	es:[bx].DO_Header.CD_status, 0

	mov	ax, CD_SEND_REQUEST		; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].DO_Header.CD_status	; return error code
	ret
CDDeviceOpen endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDDeviceClose

DESCRIPTION:	Used by the device driver to monitor how many different 
		callers are currently using the CD-ROM device driver.

PASS:		es:bx - Pointer to DeviceClose structure
	
RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	11/91		initial version

------------------------------------------------------------------------------@
CDDeviceClose  proc	far
	mov	es:[bx].DC_Header.CD_code, CDSR_DEVICE_CLOSE
	mov	es:[bx].DC_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].DC_Header.CD_subunit, 0
	mov	es:[bx].DC_Header.CD_status, 0

	mov	ax, CD_SEND_REQUEST		; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].DC_Header.CD_status	; return error code
	ret
CDDeviceClose endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDReadAddressDeviceHeader

DESCRIPTION:	Use the MSCDEX CD extension call to read CD drive device header

PASS:		es:bx	- pointer to IOCTLI structure
		ds:di   - pointer to RAddr structure
		cx - drive number
RETURN:		Address of read address request header
		ax -  error code
DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDReadAddressDeviceHeader	proc	far
	mov	ax, LENGTH_RETURN_ADDRESS
	mov	ds:[di].ReturnCode, CDI_RETURN_ADDRESS_DEVICE_HEADER
	call	CDIOCTLInput
	ret
CDReadAddressDeviceHeader	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDHeadLocation

DESCRIPTION:	The device driver will return a 4-byte address that indicates
		where the head is located. The value will be interpreted
		based on the addressing mode. This information can also
		be obtained by monitoring the Q-channel.

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to LocHead structure
		dl - addressing mode
			HSG_MODE
			RED_BOOK_MODE
		cx - drive number

RETURN:		ax - error code
		Returns head location in LocHead structure

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDHeadLocation	proc	far
	mov	ds:[di].AddrMode, dl
	mov	ds:[di].LocCode, CDI_HEAD_LOCATION

	mov	ax, LENGTH_HEAD_LOCATION
	call	CDIOCTLInput
	ret
CDHeadLocation	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDAudioChannelInfo

DESCRIPTION:	This function returns the present settings of the audio
		channel control set with the Audio Channel Control
		IOCTL write function. The default settings for the audio
		channel control are for each input channel to be assigned
		to its corresponding output channel(0 to 0, 1 to 1..) and
		for the volume to be set to 0xff.

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to AudInfo structure
		cx - drive number

RETURN:		

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDAudioChannelInfo	proc	far
	mov	ax, LENGTH_AUDIO_INFO
	mov	ds:[di].AudInfoCode, CDI_AUDIO_CHANNEL_INFO
	call	CDIOCTLInput
	ret
CDAudioChannelInfo	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDReadDriveBytes

DESCRIPTION:	Read up to 128 bytes from the disk. This function exists to
		provide access to device-specific features that are not
		supported elsewhere in the specification.

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to DrvBytes structure
		cx - drive number

RETURN:		number of bytes requested in DrvBytes structure

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version
 
------------------------------------------------------------------------------@
CDReadDriveBytes  proc	far
	mov	ax, LENGTH_READ_DRIVE
	mov	ds:[di].RDrvCode, CDI_READ_DRIVE_BYTES
	call	CDIOCTLInput
	ret
CDReadDriveBytes  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDDeviceStatus

DESCRIPTION:    Obtains CD device status

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to DevStat structure
		cx - drive number

RETURN:		ds:di - DevStat structure. Status is returned in Parameters
			field

	Status is returned as follows
		Bit 0		0	Door closed
				1	Door open
		Bit 1		0	Door locked
				1	Door unlocked
		Bit 2		0	Supports only cooked reading
				1	Supports raw and cooked reading
		Bit 3		0	Read only
				1	Read/Write
		Bit 4		0	Data read only
				1	Data read and play audio/video tracks
		Bit 5		0	No interleaving
				1	Supports ISO-9660 interleave
		Bit 6 			Reserved
		Bit 7		0	No prefetch
				1	Supports prefetching requests
		Bit 8		0	No audio channel manipulation
				1	Supports channel manipulation
		Bit 9		0	Supports HSG addressing mode
				1	Supports HSG & Red Book addressing mode
		Bit 10 			Reserved
		Bit 11		0	Disk present in drive
				1	No disk present in drive
DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDDeviceStatus  proc	far
	mov	ax, LENGTH_DEVICE_STATUS
	mov	ds:[di].DevCode, CDI_DEVICE_STATUS
	call	CDIOCTLInput
	ret
CDDeviceStatus  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDSectorSize

DESCRIPTION:	Returns sector size of device given the read mode provided.
		For CD-ROM, cooked sector size is 2048, raw sector size is 2352

PASS:		cx - drive number
		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to SectSize structure

RETURN:
		ax - error code	

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDSectorSize  proc	far
	mov	ax, LENGTH_SECTOR_SIZE
	mov	ds:[di].SectCode, CDI_RETURN_SECTOR_SIZE
	call	CDIOCTLInput
	ret
CDSectorSize  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDVolumeSize

DESCRIPTION:	The device driver will return the number of sectors in the
		 device. The size returned is the address of the lead-out
		 track in the TOC converted to a binary value according to
		 FRAME + (SEC*75) +(MIN*60*75). A disc with a lead out track
		 starting at 31:14.63 would return a volume size of 140613.
		 The address of the lead-out track is assumed to point to the
		 first sector following the last addressable sector recorded
		 on the disc.

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to VolSize structure
		cx - drive number

RETURN:		VolSize

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDVolumeSize  proc	far
	mov	ax, LENGTH_VOLUME_SIZE
	mov	ds:[di].VolCode, CDI_RETURN_VOLUME_SIZE
	call	CDIOCTLInput
	ret
CDVolumeSize  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDMediaChanged

DESCRIPTION:	Function to determine if media has been changed in drive

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to MedChng structure
		cx - drive number

RETURN:		In MedChng structure
			CDMedia = 1	Media not changed
			  	  0	Unsure
				 0ffh	Media changed

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDMediaChanged  proc	far
	mov	ax, LENGTH_MEDIA_CHANGED
	mov	ds:[di].MediaCode, CDI_MEDIA_CHANGED
	call	CDIOCTLInput
	ret
CDMediaChanged  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDAudioDiskInfo

DESCRIPTION:	Returns TOC(table of contents) information from Q-channel
		in the lead-in track indicating first and last track
		numbers and Red Book address for lead-out track. First and
		last track numbers are binary, not BCD.

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to DiskInfo structure
		cx - drive number

RETURN:		

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDAudioDiskInfo  proc	far
	mov	ax, LENGTH_AUDIO_DISK
	mov	ds:[di].DiskCode, CDI_AUDIO_DISK_INFO
	call	CDIOCTLInput		; returns ax as error code
	ret
CDAudioDiskInfo  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDAudioTrackInfo

DESCRIPTION:	This function takes a binary track number from within the range
		specified by the lowest and hightest track numbner given by the
		Audio Disk Info command, and re4turns the Red Book address for
		the starting point of the track and the track control 
		information for that track.  The track control information 
		byte corresponds to the byte in the TOC in the lead-in track 
		containing the two 4-bit fields for CONTROL and ADR in the 
		entry for that track.  The CONTROL information is in the most 
		significant 4 bits and the ADr information is in the lower 4 
		bits.

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to TnoInfo structure
		cx - drive number
		dl - track number

RETURN:		

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDAudioTrackInfo  proc	far
	mov	ds:[di].TnoCode, CDI_AUDIO_TRACK_INFO
	mov	ds:[di].TrackNum, dl

	mov	ax, LENGTH_AUDIO_TRACK
	call	CDIOCTLInput
	ret
CDAudioTrackInfo  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDQChannelInfo

DESCRIPTION:	This function reads and returns the latest Q channel 
		address presently available. 

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to QInfo structure
		cx - drive number

RETURN:	
		ax - COMMAND_NOT_SUPPORTED, if command not supported

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDQChannelInfo  proc	far
	mov	ax, LENGTH_Q_CHANNEL
	mov	ds:[di].QCode, CDI_AUDIO_QCHANNEL_INFO
	call	CDIOCTLInput
	ret
CDQChannelInfo  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDSubChannelInfo

DESCRIPTION:	Reads subchannel data from CD Rom drive

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to SubChanInfo structure
		cx - drive number

RETURN:	

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDSubChannelInfo  proc	far
	mov	ax, LENGTH_SUB_CHANNEL
	mov	ds:[di].SubCode, CDI_AUDIO_SUBCHANNEL_INFO
	call	CDIOCTLInput
	ret
CDSubChannelInfo  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDUpcCode

DESCRIPTION:	Returns UPC bar code. The UPC code is 13 successive BCD
		digits followed by 12 bits of 0. If CONTROL/ADR byte is 
		0 or the 13 digits are 0, there is no catalog number on
		disk or device driver missed it. 

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to UPCCode structure
		cx - drive number

RETURN:		ax - error code
		     UNKNOWN_COMMAND - does not support this command
		     SECTOR_NOT_FOUND - If disk does not have UPC Code
DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDUpcCode  proc	far
	mov	ax, LENGTH_UPC_CODE
	mov	ds:[di].UPC_Code, CDI_UPC_CODE
	call	CDIOCTLInput
	ret
CDUpcCode  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDAudioStatus

DESCRIPTION:	Returns audio disk paused bit, and starting and ending location	
		for last Play or next Resume

PASS:		es:bx - pointer to IOCTLI structure
		ds:di   - Pointer to AudStat structure
		cx - drive number

RETURN:		ax - error code

DESTROYED:

 REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDAudioStatus  proc	far
	mov	ax, LENGTH_AUDIO_STATUS
	mov	ds:[di].AudCode, CDI_AUDIO_STATUS_INFO
	call	CDIOCTLInput
	ret
CDAudioStatus  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDIOCTLInput 

DESCRIPTION:	Handler for all the routines that go through the IOCTL
		input pathway

PASS:		es:bx - pointer to IOCTLIStruc structure
		ds:di - pointer to secondary structure
		ax - length parameter
		cx - drive number
	
RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDIOCTLInput  proc	far
	mov	es:[bx].IOI_Header.CD_code, CDSR_IOCTL_INPUT	
	mov	es:[bx].IOI_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].IOI_numBytes, ax
	clr	ax
	mov	es:[bx].IOI_Header.CD_subunit, al	;clear
	mov	es:[bx].IOI_Header.CD_status, ax	;clear

	mov	es:[bx].IOI_MediaType, al 		;clear
	mov	es:[bx].IOI_startSector, ax		;clear
	mov	es:[bx].IOI_errorPtr.segment, ax	;clear
	mov	es:[bx].IOI_errorPtr.offset, ax		;clear

	mov	ax, ds
	mov	es:[bx].IOI_transfer.segment, ax
	mov	es:[bx].IOI_transfer.offset, di

	mov	ax, CD_SEND_REQUEST		; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].IOI_Header.CD_status	; return error code
	ret
CDIOCTLInput  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDIOCTLOutput 

DESCRIPTION:	Handler for all the routines that go through the IOCTL
		output pathway

PASS:
		es:bx - pointer to IOCTLOStruc structure
		ds:di - pointer to secondary structure
		ax - length of passed data structure
RETURN:		
		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDIOCTLOutput  proc	far
	mov	es:[bx].IOO_Header.CD_code, CDSR_IOCTL_OUTPUT
	mov	es:[bx].IOO_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].IOO_numberBytes, ax

	clr	ax
	mov	es:[bx].IOO_Header.CD_subunit, al
	mov	es:[bx].IOO_Header.CD_status, ax

	mov	es:[bx].IOO_mediaType, al
	mov	es:[bx].IOO_startSector, ax
	mov	es:[bx].IOO_errorPtr.segment, ax
	mov	es:[bx].IOO_errorPtr.offset, ax

	mov	ax, ds
	mov	es:[bx].IOO_transfer.segment, ax
	mov	es:[bx].IOO_transfer.offset, di

	mov	ax, CD_SEND_REQUEST		; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].IOO_Header.CD_status	; return error code
	ret
CDIOCTLOutput  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDEjectDisk

DESCRIPTION:	Ejects disk from drive

PASS:		es:bx - pointer to IOCTLO structure
		ds:di   - Pointer to Eject structure
		cx - drive nummber

RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDEjectDisk  proc	far
	mov	ds:[di].EjectCode, EJECT_DISK
	mov	ax, LENGTH_EJECT_DISK
	call	CDIOCTLOutput
	ret
CDEjectDisk  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDLockDoor

DESCRIPTION:	If CD drive has locking door, allows software to lock and 
		unlock door.

PASS:		es:bx - pointer to IOCTLO structure
		ds:di   - Pointer to LockDoor structure
		cx - drive number

RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDLockDoor  proc	far
	mov	ds:[di].LockCode, LOCK_DOOR
	mov	ax, LENGTH_LOCK_DOOR
	call	CDIOCTLOutput
	ret
CDLockDoor  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDResetDrive

DESCRIPTION:	Directs the device driver to reset and reinitialize the drive

PASS:		es:bx - pointer to IOCTLO structure
		ds:di   - Pointer to LockDoor structure
		cx - drive number

RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDResetDrive  proc	far
	mov	ds:[di].ResetCode, RESET_DRIVE
	mov	ax, LENGTH_RESET_DRIVE
	call	CDIOCTLOutput
	ret
CDResetDrive  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDAudioChannelControl

DESCRIPTION:	This function provides playback control of audio information
		on the disk. It allows input channels on the CD-ROM to be
		assigned to specified output speaker connections. The purpose
		of  this function is to allow two input channels to be
		recorded - in different languages for example - and to play
		back only one of them at a time. 
		This function also provides volume control.

PASS:		dl - volume channel 0 (left channel)
		dh - volume channel 1 (right channel)
		al - channel input    (left channel)
		ah - channel input    (right channel)

		cx - drive number
	    	ds:di   - Pointer to AudInfo structure
RETURN:	

DESTROYED:	dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDAudioChannelControl  proc	far

	mov	ds:[di].AOI_Volume0, dl
	mov	ds:[di].AOI_Volume1, dh
	mov	ds:[di].AOI_InputChan0, al
	mov	ds:[di].AOI_InputChan1, ah
	mov	ds:[di].AOI_Code, AUDIO_CONTROL

	mov	ax, LENGTH_AUDIO_CONTROL
	call	CDIOCTLOutput
	ret
CDAudioChannelControl  endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDCloseTray

DESCRIPTION:	Close tray on drive

PASS:		es:bx - pointer to CD data structure
		cx - drive number

RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
CDCloseTray  proc	far
	mov	es:[bx].IOO_numberBytes, LENGTH_CLOSE_TRAY

	mov	ax, CD_SEND_REQUEST		; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].IOO_Header.CD_status	; return error code
	ret
CDCloseTray  endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDSeek

DESCRIPTION:	Use the MSCDEX CD extension call to relocate head to
		begin play of audio or video

PASS:		al - address mode		RED_BOOK_MODE
						HSC_MODE
		es:bx - pointer to SeekReq structure
		cx - drive number

RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDSeek	proc	far
	mov	es:[bx].SR_Header.CD_addressHeader, size RequestHeader
	mov	es:[bx].SR_Header.CD_subunit, 0
	mov	es:[bx].SR_Header.CD_status, 0
	mov	es:[bx].SR_Header.CD_code, CDSR_SEEK

	mov	es:[bx].SR_numSectors, 0
	mov	es:[bx].SR_transferAddr.segment, 0
	mov	es:[bx].SR_transferAddr.offset, 0
	mov	es:[bx].SR_addressMode, al

	mov	ax, CD_SEND_REQUEST	; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].SR_Header.CD_status	; return error code
	ret
CDSeek	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDPlayAudio

DESCRIPTION:	Use the MSCDEX CD extension call to command CD
		drive to play audio

PASS:		al - address mode	RED_BOOK_MODE
					HSC_MODE
		es:bx	pointer to PlayReq structure
		ds:di	pointer to play data structure
		cx - drive number

RETURN: 	ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDPlayAudio	proc	far
	mov	es:[bx].PR_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].PR_Header.CD_subunit, 0
	mov	es:[bx].PR_Header.CD_code, CDSR_PLAY_AUDIO
	mov	es:[bx].PR_Header.CD_status, 0
	mov	es:[bx].PR_Header.CD_Reserved, 0

	mov	es:[bx].PR_addressMode, al

	mov	ax, ds:[di].startSector.low
	mov	es:[bx].PR_startSector.low, ax
	mov	ax, ds:[di].startSector.high
	mov	es:[bx].PR_startSector.high, ax

	mov	ax, ds:[di].trackLen.low
	mov	dx, ds:[di].trackLen.high
	mov	es:[bx].PR_numSectors.low, ax
	mov	es:[bx].PR_numSectors.high, dx

	mov	ax, CD_SEND_REQUEST	; MSCDEX interface call
	call	Int2f

	mov	ax, es:[bx].PR_Header.CD_status	; return error code
	ret
CDPlayAudio	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDStopAudio

DESCRIPTION:	Use the MSCDEX CD extension call to command CD drive to 
		stop audio play


PASS:		es:bx	- Pointer to StopReq structure
		cx - drive number

RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDStopAudio	proc	far
	localStruct	local	StopReq	  ; data structure for Stop command

	.enter
	push	es
	segmov	es, ss

	lea	bx, localStruct			; es:bx to CDStrucs
	mov	localStruct.ST_Header.CD_addressHeader, size CDRequestHeader
	mov	localStruct.ST_Header.CD_subunit, 0
	mov	localStruct.ST_Header.CD_code, CDSR_STOP_AUDIO
	mov	localStruct.ST_Header.CD_status, 0

	mov	ax, CD_SEND_REQUEST	; MSCDEX interface call
	call	Int2f
	mov	ax,  localStruct.ST_Header.CD_status	; return error code
	pop	es
	.leave
	ret
CDStopAudio	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDResumeAudio

DESCRIPTION:	Use the MSCDEX CD extension call to command CD
		drive to resume audio play

PASS: 		es:bx	= Pointer to ResumeReq structure
		cx	Active drive

RETURN: 	ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDResumeAudio	proc	far
	mov	es:[bx].RES_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].RES_Header.CD_subunit, 0
	mov	es:[bx].RES_Header.CD_status, 0
	mov	es:[bx].RES_Header.CD_code, CDSR_RESUME_AUDIO

	mov	ax, CD_SEND_REQUEST	; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].RES_Header.CD_status	; return error code
	ret
CDResumeAudio	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	CDReadLong

DESCRIPTION:	Read sectors from CD Device

PASS:		es:bx	- ReadL structure

RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDReadLong	proc	far
	mov	es:[bx].RL_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].RL_Header.CD_subunit, 0
	mov	es:[bx].RL_Header.CD_status, 0
	mov	es:[bx].RL_Header.CD_code, CDSR_READ_LONG

	mov	ax, CD_SEND_REQUEST	; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].RL_Header.CD_status	; return error code
	ret
CDReadLong	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDReadLongPrefetch

DESCRIPTION:	Similar to CDReadLong, but control returns immediately to
		the requesting process.

PASS:		es:bx	- pointer to ReadLPre structure

RETURN:		ax - error code

DESTROYED:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	11/91		initial version

------------------------------------------------------------------------------@
CDReadLongPrefetch	proc	far
	mov	es:[bx].RLP_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].RLP_Header.CD_subunit, 0
	mov	es:[bx].RLP_Header.CD_status, 0
	mov	es:[bx].RLP_Header.CD_code, CDSR_READ_LONG_PRE

	mov	ax, CD_SEND_REQUEST	; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].RLP_Header.CD_status	; return error code
	ret
CDReadLongPrefetch	endp




COMMENT @---------------------------------------------------------------------

FUNCTION:	CDWriteLong

DESCRIPTION:	The device will copy the data at the transfer address to the
		CD-RAM device at the sector indicated. The media must be
		writable for this function to work. Data is written sector
		by sector, depending on the current write mode and the
		interleave parameters.

PASS:		cx - drive number
		es:bx	- pointer to WriteL structure

RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDWriteLong	proc	far
	mov	es:[bx].WL_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].WL_Header.CD_subunit, 0
	mov	es:[bx].WL_Header.CD_status, 0
	mov	es:[bx].WL_Header.CD_code, CDSR_WRITE_LONG

	mov	ax, CD_SEND_REQUEST	; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].WL_Header.CD_status	; return error code
	ret
CDWriteLong	endp




COMMENT @---------------------------------------------------------------------

FUNCTION:	CDWriteLongVerify

DESCRIPTION:	The device will copy the data at the transfer address to the
		CD-RAM device at the sector indicated. The media must be
		writable for this function to work. Data is written sector
		by sector, depending on the current write mode and the
		interleave parameters.

PASS:		cx - drive number
		es:bx	- pointer to WriteLV structure

RETURN:		ax - error code

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	3/91		initial version

------------------------------------------------------------------------------@
CDWriteLongVerify	proc	far
	mov	es:[bx].WLV_Header.CD_addressHeader, size CDRequestHeader
	mov	es:[bx].WLV_Header.CD_subunit, 0
	mov	es:[bx].WLV_Header.CD_status, 0
	mov	es:[bx].WLV_Header.CD_code, CDSR_WRITE_LONG_VERIFY

	mov	ax, CD_SEND_REQUEST	; MSCDEX interface call
	call	Int2f
	mov	ax, es:[bx].WLV_Header.CD_status	; return error code
	ret
CDWriteLongVerify	endp


COMMENT @---------------------------------------------------------------------

FUNCTION:	ConvertRedBookToAbsolute

DESCRIPTION:    Converts CD-DA Red book address to absolute sector address.
		Formula relating sector to Red Book time is
		Sector = Minute*60*75 + Second*75 + Frame - 150
PASS:		
		al	frames
		ah	seconds
		cl	minutes

RETURN:		ax	low word
		cx 	high word

DESTROYED:	bx, dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@

ConvertRedBookToAbsolute proc	far
	push	ax
	mov	al, cl
	mov	bl, 75		; minute calculation
	mul	bl
	mov	bx, 60
	mul	bx
	mov	cx, ax		; output is dx:cx

	pop	ax
	mov	bh, ah
	clr	ah
	add	cx, ax		; add frame
	adc	dx, 0
	sub	cx, 150		; subtract 150
	sbb	dx, 0

	clr	ah		; seconds calculation
	mov	al, bh
	mov	bl, 75
	mul	bl
	add	ax, cx
	adc	dx, 0
	mov	cx, dx		; cx:ax is absolute sector as dword
	ret
ConvertRedBookToAbsolute	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	CDPlayTrack

DESCRIPTION:	Play from start track to end track without using TOC
		To play the end track on the CD, set dh to one greater	
		than the last track number		

CALLED BY:

PASS:		cx - CD drive number
		dl - start track
		dh - end track

RETURN:		nothing

DESTROYED:	ax, bx, dx, si, di

REGISTER/STACK USE:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	7/91		initial version

------------------------------------------------------------------------------@
CDPlayTrack	proc	far
	localUnion	local	CDStrucs	; data structures for MSCDEX

	localPlayThing  local	PStruct		; structure for play information
	localDrive	local	word		; active cd drive

	localInput  	local	TnoInfo		; TnoInfo for CDPlay command
	localDiskInfo  	local	DiskInfo	; DiskInfo for CDPlay command

	.enter
	push	ds, es
	mov	localDrive, cx			; save disc number
	push	dx				; save tracks
	segmov	es, ss
	segmov	ds, ss

	lea	bx, localUnion			; es:bx to CDStrucs
	mov	cx, localDrive			; must stop drive
	call	CDStopAudio
						
	lea	bx, localUnion			; es:bx = localUnion
	lea	di, localDiskInfo		; ds:di = localDiskInfo
	mov	cx, localDrive
	call	CDAudioDiskInfo			; get number of tracks
						; and lead-out address
						; es:bx = localUnion
	lea	di, localInput			; ds:di to TnoInfo
	mov	cx, localDrive
	call	CDAudioTrackInfo		; 

	mov	ax, localInput.StartPoint.low
	mov	cx, localInput.StartPoint.high
	mov	localPlayThing.startSector.low, ax	; save start point
	mov	localPlayThing.startSector.high, cx	; save start point

	call	ConvertRedBookToAbsolute   ; get absolute length -pass ax and cx

	pop	dx
	xchg	dh, dl			; get end track

	push	cx			; save StartPoint.high
	push	ax			; save StartPoint.low

	cmp	dl, localDiskInfo.HiTrackNum
	jle	normal
	mov	ax, localDiskInfo.LeadOut.low
	mov	cx, localDiskInfo.LeadOut.high
	jmp	maximum
normal:
	lea	bx, localUnion		; ConvertRedBookToAbsolute destroys bx
	lea	di, localInput		; ds:di to TnoInfo
	mov	cx, localDrive
	call	CDAudioTrackInfo
	mov	ax, localInput.StartPoint.low
	mov	cx, localInput.StartPoint.high

maximum:
	call	ConvertRedBookToAbsolute
	pop	dx			; get StartPoint.low
	sub	ax, dx			; calculate track length - low word
	pop	dx			; get StartPoint.high
	sbb	cx, dx			; calculate track length - high word

	mov	localPlayThing.trackLen.low, ax
	mov	localPlayThing.trackLen.high, cx

	lea	bx, localUnion		; ConvertRedBookToAbsolute destroys bx
	lea	di, localPlayThing
	mov	al, RED_BOOK_MODE
	mov	cx, localDrive
	call	CDPlayAudio
	pop	ds, es
	.leave
	ret
CDPlayTrack	endp



COMMENT @---------------------------------------------------------------------

FUNCTION:	Int2f

DESCRIPTION:	Calls int 2fh, the network and CD-ROM interrupt. Obtains 
		file lock before making int 2fh call.

PASS:		registers for int 2fh

RETURN:	

DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Fred	4/91		initial version

------------------------------------------------------------------------------@
Int2f		proc	far
	push	es			; save es
	call	SysLockBIOS		; go get system lock

 	int 	2fh			; do CD interrupt
	call	SysUnlockBIOS		; and give it back

	pop	es			; restore es
	ret
Int2f	endp

CommonCode	ends

