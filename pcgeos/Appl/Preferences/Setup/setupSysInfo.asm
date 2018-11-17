COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		setup
FILE:		setupSysInfo.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version
	Tom	 9/97		Hacked to stop looking for geos.ini

DESCRIPTION:
	This file contains code to generate the system information file

	$Id: setupSysInfo.asm,v 1.3 98/05/14 00:00:56 gene Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

SYS_INFO_BUFFER_SIZE	=	8000

BufferHeader	struct
    BH_handle	hptr
    BH_file	word
    BH_ptr	word
BufferHeader	ends

BitfieldEntry	struct
    BE_value	word
    BE_string	word
BitfieldEntry	ends

EnumEntry	struct
    EE_value	word
    EE_string	word
EnumEntry	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

idata	ends

;---------------------------------------------------

udata	segment

udata	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

SysInfoCode segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoGenerateFile

DESCRIPTION:	Generate the system information file.

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoGenerateFile	proc	far	uses ax, bx, cx, dx, si, di, bp, ds, es
	.enter

	; Open the file.  If an error is encountered then bail out

	call	FilePushDir
	mov	ax, SP_TOP
	call	FileSetStandardPath

	segmov	ds, cs
	mov	dx, offset sysinfoFile
	mov	ah, FILE_CREATE_TRUNCATE or mask FCF_NATIVE
	mov	al, FileAccessFlags <FE_EXCLUSIVE, FA_READ_WRITE>
	clr	cx				;no special attributes
	call	FileCreate			;ax = file handle
	LONG jc	exitNoClose
	mov	dx, ax				;dx = file handle

	mov	ax, SYS_INFO_BUFFER_SIZE
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	es, ax
	mov	es:[BH_handle], bx
	mov	es:[BH_file], dx
	mov	es:[BH_ptr], size BufferHeader
	call	MemUnlock

	; print header, date and time

	mov	ax, C_TAB
	call	SysInfoPrintChar
	mov	si, offset HeaderString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF
	call	SysInfoPrintCRLF
	mov	si, offset HeaderString1
	call	SysInfoPrintString
	call	SysInfoPrintCRLF
	mov	si, offset HeaderString2
	call	SysInfoPrintString
	call	SysInfoPrintCRLF
	call	SysInfoPrintCRLF

	call	SysInfoPrintDate
	call	SysInfoPrintTime

	; print release and protocol

	call	SysInfoPrintRelease
	call	SysInfoPrintProtocol

	; print SysConfig info

	call	SysInfoPrintSysConfig
	call	SysInfoPrintTonyIndex
	call	SysInfoPrintDOSVersion

	; print other system info

	call	SysInfoPrintMemInfo
	call	SysInfoPrintDriveInfo
	call	SysInfoPrintDriverMaps

	; dump parts of various ROM areas

	call	SysInfoPrintBIOS

	; print geos.ini, config.sys, autoexec.bat files

if 0
	call	SysInfoPrintINIFile
endif

	push	bx
	clr	bx		; assume system disk

	; Use the COMSPEC envariable to tell us where the boot drive is.
	push	ds, es
	segmov	ds, cs
	mov	si, offset comspec
	segmov	es, ss
	mov	cx, 2		; just need the drive letter...
	sub	sp, cx
	mov	di, sp
	call	SysGetDosEnvironment
	pop	ax
	pop	ds, es
	jc	goToRoot	; not found => use system disk
	sub	al, 'a'		; convert to 0-origin drive number, assuming l.c.
	jge	getDisk
	add	al, 'a' - 'A'	; actually upper-case, so shift back into range
getDisk:
	call	DiskRegisterDiskSilently
	; bx = disk, or 0 if couldn't register => system disk
goToRoot:
	mov	dx, offset rootPath
	call	FileSetCurrentPath
	pop	bx

	call	SysInfoPrintCONFIGFile
	call	SysInfoPrintAUTOEXECFile
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	call	SysInfoPrintOldCONFIGFile
	call	SysInfoPrintOldAUTOEXECFile

	call	SysInfoFlush
	call	MemLock
	mov	ds, ax
	push	ds:[BH_file]
	call	MemFree
	pop	bx
	clr	ax
	call	FileClose
exitNoClose:
	call	FilePopDir
	.leave
	ret

SysInfoGenerateFile	endp

SBCS <sysinfoFile	char	"sysinfo", 0				>
DBCS <sysinfoFile	wchar	"sysinfo", 0				>

SBCS <rootPath	char	C_BACKSLASH, 0					>
DBCS <rootPath	wchar	C_BACKSLASH, 0					>

comspec		char	"COMSPEC",0


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintDate

DESCRIPTION:	Print the date

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintDate	proc	near
	.enter

	mov	si, offset DateString
	call	SysInfoPrintString

	push	bx
	call	TimerGetDateAndTime
	mov	cx, bx				;cx = day and month
	pop	bx

	push	ax
	clr	ax
	mov	al, cl				;ax = month
	call	SysInfoPrintInteger
	mov	ax, '/'
	call	SysInfoPrintChar
	clr	ah
	mov	al, ch				;ax = day
	call	SysInfoPrintInteger
	mov	ax, '/'
	call	SysInfoPrintChar
	pop	ax				;ax = year
	call	SysInfoPrintInteger

	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintDate	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintTime

DESCRIPTION:	Print the time

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintTime	proc	near
	.enter

	mov	si, offset TimeString
	call	SysInfoPrintString

	push	bx
	call	TimerGetDateAndTime
	pop	bx

	clr	ax
	mov	al, ch				;ax = hours
	call	SysInfoPrintInteger
	mov	ax, ':'
	call	SysInfoPrintChar
	clr	ah
	mov	al, dl				;ax = minutes
	call	SysInfoPrintInteger
	mov	ax, ':'
	call	SysInfoPrintChar
	clr	ah
	mov	al, dh				;ax = seconds
	call	SysInfoPrintInteger

	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintTime	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintRelease

DESCRIPTION:	Print kernel release

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	carry - set on error

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintRelease	proc	near	uses es
release		local	ReleaseNumber
	.enter

	mov	si, offset ReleaseString
	call	SysInfoPrintString

	push	bx
	segmov	es, ss
	lea	di, release
	mov	ax, GGIT_GEODE_RELEASE
	mov	bx, handle geos
	call	GeodeGetInfo
	pop	bx

	mov	ax, release.RN_major
	call	SysInfoPrintInteger
	mov	ax, '.'
	call	SysInfoPrintChar
	mov	ax, release.RN_minor		;ax = part B
	call	SysInfoPrintInteger
	mov	ax, '.'
	call	SysInfoPrintChar
	mov	ax, release.RN_change		;ax = part C
	call	SysInfoPrintInteger
	mov	ax, '.'
	call	SysInfoPrintChar
	mov	ax, release.RN_engineering	;ax = part D
	call	SysInfoPrintInteger

	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintRelease	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintProtocol

DESCRIPTION:	Print the date

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintProtocol	proc	near	uses es
protocol	local	ProtocolNumber
	.enter

	mov	si, offset ProtocolString
	call	SysInfoPrintString

	push	bx
	segmov	es, ss
	lea	di, protocol
	mov	ax, GGIT_GEODE_PROTOCOL
	mov	bx, handle geos
	call	GeodeGetInfo
	pop	bx

	mov	ax, protocol.PN_major		;ax = part A
	call	SysInfoPrintInteger
	mov	ax, '.'
	call	SysInfoPrintChar
	mov	ax, protocol.PN_minor		;ax = part B
	call	SysInfoPrintInteger

	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintProtocol	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintSysConfig

DESCRIPTION:	Print the system configuration

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintSysConfig	proc	near
	.enter

	push	bx
	call	SysGetConfig			;al = SysConfigFlags
						;dl = SysProcessorType
						;dh = SysMachineType
	pop	bx

	push	dx
	clr	ah
	mov	si, offset configTable
	mov	cx, length configTable
	call	SysInfoPrintBitfield
	pop	cx

	mov	si, offset ProcessorString
	call	SysInfoPrintString
	push	cx
	clr	ax
	mov	al, cl				;ax = SysProcessorType
	mov	si, offset processorTable
	mov	cx, length processorTable
	call	SysInfoPrintEnum
	call	SysInfoPrintCRLF
	pop	cx

	mov	si, offset MachineString
	call	SysInfoPrintString
	clr	ax
	mov	al, ch				;ax = SysMachineType
	mov	si, offset machineTable
	mov	cx, length machineTable
	call	SysInfoPrintEnum
	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintSysConfig	endp

configTable	BitfieldEntry	\
	<mask SCF_2ND_IC, offset SecondICString>,
	<mask SCF_RTC, offset ClockString>,
	<mask SCF_COPROC, offset MathString>,
	<mask SCF_MCA, offset MCAString>

processorTable	EnumEntry	\
	<SPT_8088, offset CPU8088String>,
	<SPT_8086, offset CPU8086String>,
	<SPT_80186, offset CPU80186String>,
	<SPT_80286, offset CPU80286String>,
	<SPT_80386, offset CPU80386String>,
	<SPT_80486, offset CPU80486String>

machineTable	EnumEntry	\
	<SMT_UNKNOWN, offset MachineUnknownString>,
	<SMT_PC, offset MachinePCString>,
	<SMT_PC_CONV, offset MachinePCConvString>,
	<SMT_PC_JR, offset MachinePCJRString>,
	<SMT_PC_XT, offset MachinePCXTString>,
	<SMT_PC_XT_286, offset MachinePCXT286String>,
	<SMT_PC_AT, offset MachinePCATString>,
	<SMT_PS2_30, offset MachinePS230String>,
	<SMT_PS2_50, offset MachinePS250String>,
	<SMT_PS2_60, offset MachinePS260String>,
	<SMT_PS2_80, offset MachinePS280String>,
	<SMT_PS1, offset MachinePS1String>


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintTonyIndex

DESCRIPTION:	Print the tony index

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintTonyIndex	proc	near
	.enter

	mov	si, offset TonyIndexString
	call	SysInfoPrintString

	mov	ax, SGIT_CPU_SPEED
	call	SysGetInfo			;ax = speed * 10

	; ax = rating * 10

	clr	dx				; we're using 32/16 division
	mov	cx, 10				;  to avoid divide overflow
						;  error on fast processors
						;  with a cache
						;  	-- ardeb 9/21/95  
	div	cx				;ax = quotient, dx = remainder
	call	SysInfoPrintInteger
	mov	ax, '.'
	call	SysInfoPrintChar
	mov_tr	ax, dx
	call	SysInfoPrintInteger

	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintTonyIndex	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintDOSVersion

DESCRIPTION:	Print the date

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintDOSVersion	proc	near
	.enter

	mov	si, offset DosVersionString
	call	SysInfoPrintString

	; check for DR-DOS

	push	bx
	mov	ax, DRDOS_GET_VERSION
	call	FileInt21			;ax = DRDosVersion
	pop	bx
	jc	notDRDos

	mov	si, offset DRDOSString
	call	SysInfoPrintString
	mov	si, offset drdosTable
	mov	cx, length drdosTable
	call	SysInfoPrintEnum
	jmp	done

notDRDos:
	push	bx
	mov	ah, MSDOS_GET_VERSION
	call	FileInt21			;al.ah = version
	pop	bx				;bx & cx = serial #

	push	ax
	clr	ah
	call	SysInfoPrintInteger
	mov	ax, '.'
	call	SysInfoPrintChar
	pop	ax
	mov	al, ah
	clr	ah
	call	SysInfoPrintInteger

done:
	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintDOSVersion	endp

drdosTable	EnumEntry	\
	<DVER_3_40, offset DRDOS3_40String>,
	<DVER_3_41, offset DRDOS3_41String>,
	<DVER_5_0, offset DRDOS5_0String>


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintMemInfo

DESCRIPTION:	Print heap info

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintMemInfo	proc	near
	.enter

	; print system memory

	mov	si, offset SystemMemoryString
	call	SysInfoPrintString

	push	ds
	mov	ax, BIOS_DATA_SEG
	mov	ds, ax
	mov	ax, ds:BIOS_MEMORY_SIZE
	pop	ds

	call	SysInfoPrintInteger

	mov	ax, 'K'
	call	SysInfoPrintChar

	call	SysInfoPrintCRLF

	; print heap size

	mov	si, offset HeapString
	call	SysInfoPrintString

	mov	ax, SGIT_HEAP_SIZE
	call	SysGetInfo			;ax = heap size (paragraphs)

	mov	cl, 6				;divide by 32 to get size in K
	shr	ax, cl
	call	SysInfoPrintInteger

	mov	ax, 'K'
	call	SysInfoPrintChar

	call	SysInfoPrintCRLF

	; print extended memory size

	mov	si, offset ExtendedMemoryString
	call	SysInfoPrintString

	push	bx
	mov	ah, 88h
	int	15h				;ax = extended memory (K)
	pop	bx
	test	ah, 0x80
	jnz	noExtendedMemory
	call	SysInfoPrintInteger
	mov	ax, 'K'
	call	SysInfoPrintChar
	jmp	common
noExtendedMemory:
	mov	si, offset NoneString
	call	SysInfoPrintString
common:

	call	SysInfoPrintCRLF

	; print segment of kcode

	mov	si, offset KCodeSegmentString
	call	SysInfoPrintString
	mov	ax, segment MemAlloc
	call	SysInfoPrintHexWord
	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintMemInfo	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintDriveInfo

DESCRIPTION:	Print the date

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintDriveInfo	proc	near
	.enter

	call	SysInfoPrintCRLF
	mov	si, offset DriveString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	clr	ax
driveLoop:
	push	ax
	call	DriveGetStatus
	LONG jc	next

	; print "A: "

	push	ax
	clr	ah
	add	ax, 'A'
	call	SysInfoPrintChar
	mov	ax, ':'
	call	SysInfoPrintChar
	mov	ax, ' '
	call	SysInfoPrintChar
	pop	ax

	; print drive attributes

	test	ah, mask DS_MEDIA_REMOVABLE
	jz	notRemovable
	mov	si, offset RemovableString
	call	SysInfoPrintString
notRemovable:

	test	ah, mask DS_NETWORK
	jz	notUnknownFormat
	mov	si, offset NetworkString
	call	SysInfoPrintString
notUnknownFormat:

	; print drive type

	mov	si, offset DriveTypeString
	call	SysInfoPrintString
	push	ax
	mov	al, ah
	and	al, mask DS_TYPE
	clr	ah
	mov	si, offset driveTypeTable
	mov	cx, length driveTypeTable
	call	SysInfoPrintEnum
	pop	ax

	; print default media

	mov	si, offset DefaultMediaString
	call	SysInfoPrintString
	push	ax
	call	DriveGetDefaultMedia	;ah = MediaType
	mov	al, ah
	clr	ah
	mov	si, offset mediaTypeTable
	mov	cx, length mediaTypeTable
	call	SysInfoPrintEnum
	pop	ax

	; print free space if fixed

	push	ax
	mov	bp, bx				;bp = file
	test	ah, mask DS_MEDIA_REMOVABLE
	jnz	notFixed

	;
	; ...unless drive type is something other than DRIVE_FIXED
	; (might be an interlink drive, for example, which shows up as
	; UNKNOWN when not connected.
	;

	andnf	ah, mask DS_TYPE
	cmp	ah, DRIVE_FIXED shl offset DS_TYPE
	jne	notFixed

	call	DiskRegisterDisk		;bx = disk handle
	xchg	bx, bp				;bx = file, bp = disk
	jc	notFixed
	mov	si, offset FreeSpaceString
	call	SysInfoPrintString
	xchg	bx, bp
	call	DiskGetVolumeFreeSpace		;dx.ax = free space
	xchg	bx, bp

	mov	cx, 10				;convert to K
10$:
	shr	dx
	rcr	ax
	loop	10$

	call	SysInfoPrintInteger
	mov	ax, 'K'
	call	SysInfoPrintChar

notFixed:
	pop	ax

	call	SysInfoPrintCRLF

next:
	pop	ax
	inc	al
	cmp	al, DRIVE_MAX_DRIVES
	LONG jnz	driveLoop

	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintDriveInfo	endp

driveTypeTable	EnumEntry	\
	<DRIVE_5_25, offset Drive5_25String>,
	<DRIVE_3_5, offset Drive3_5String>,
	<DRIVE_FIXED, offset DriveFixedString>,
	<DRIVE_RAM, offset DriveRamString>,
	<DRIVE_CD_ROM, offset DriveCDRomString>,
	<DRIVE_8, offset Drive8String>

mediaTypeTable	EnumEntry	\
	<MEDIA_160K, offset Media160KString>,
	<MEDIA_180K, offset Media180KString>,
	<MEDIA_320K, offset Media320KString>,
	<MEDIA_360K, offset Media360KString>,
	<MEDIA_720K, offset Media720KString>,
	<MEDIA_1M2, offset Media1M2String>,
	<MEDIA_1M44, offset Media1M44String>,
	<MEDIA_FIXED_DISK, offset MediaFixedDiskString>,
	<MEDIA_CUSTOM, offset MediaCustomString>


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintDriverMaps

DESCRIPTION:	Print the stream and swap device maps

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintDriverMaps	proc	near
	.enter

	; print swap drivers

	mov	si, offset SwapDriverString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	push	bx
	mov	bp, bx				;pass file in bp
	mov	ax, DRIVER_TYPE_SWAP
	clr	bx				;start at first one
	mov	di, cs
	mov	si, offset DriverCallback	;di:si = callback routine
	call	GeodeForEach
	pop	bx

	; print stream drivers

	call	SysInfoPrintCRLF
	mov	si, offset StreamDriverString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	push	bx
	mov	bp, bx				;pass file in bp
	mov	ax, DRIVER_TYPE_STREAM
	clr	bx				;start at first one
	mov	di, cs
	mov	si, offset DriverCallback	;di:si = callback routine
	call	GeodeForEach
	pop	bx

	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintDriverMaps	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DriverCallback

DESCRIPTION:	Callback to look for swap drivers

CALLED BY:	INTERNAL

PASS:
	ax - driver type to look for
	bp - file handle
	bx - geode handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@


DriverCallbackTypes	etype	word
DCT_SWAP		enum DriverCallbackTypes
DCT_SERIAL		enum DriverCallbackTypes
DCT_PARALLEL		enum DriverCallbackTypes

DriverCallback	proc	far	uses ax, bx

DBCS <driverNameBuf	local GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE dup (wchar)>

	.enter

	push	ax
	mov	ax, GGIT_TYPE
	call	GeodeGetInfo			;ax = GeodeType
	mov	dx, ax
	pop	ax
	cmp	dx, GEODE_TYPE_DRIVER
	jz	5$
toDone:
	jmp	done
5$:

	; its a driver -- is it a swap driver ?

	call	GeodeInfoDriver			;ds:si = DriverInfoStruct
	cmp	ax, ds:[si].DIS_driverType
	jnz	toDone

	; -- call DR_SWAP_GET_MAP

	push	ax				;save type
	mov	di, DR_SWAP_GET_MAP
	cmp	ax, DRIVER_TYPE_SWAP
	jz	10$
	mov	di, DR_STREAM_GET_DEVICE_MAP
10$:
	call	ds:[si].DIS_strategy		;ax = segment of swap map
	pop	dx				;dx = type passed
	tst	ax
	jz	toDone
	push	ax				;save map segment

	; print driver name

	mov	cx, (GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE)
	sub	sp, cx
	segmov	ds, ss
	segmov	es, ss
	mov	si, sp				;ds:si = buffer
	mov	di, sp				;es:di = buffer
	mov	ax, GGIT_PERM_NAME_AND_EXT
	call	GeodeGetInfo

	; figure out appropriate driver type

	mov	ax, DCT_SWAP
	cmp	dx, DRIVER_TYPE_SWAP
	jz	20$
	cmp	{char} ds:[si], 's'		;serial starts with an 's'
						; -- I know, a HACK
	mov	ax, DCT_SERIAL
	jz	20$
	mov	ax, DCT_PARALLEL
20$:
	mov	dx, ax				;dx = type

	; print name

if DBCS_PCGEOS
	;
	; convert to DBCS string
	;	ds:si = SBCS buffer
	;	cx = length
	;
	push	cx
	clr	ah
	lea	di, driverNameBuf		;es:di = DBCS buffer
convertLoop:
	lodsb
	stosw
	loop	convertLoop
	lea	si, driverNameBuf		;ds:si = DBCS buffer
	pop	cx
endif

SBCS <	mov	bx, bp				;bx = file		>
DBCS <	mov	bx, ss:[bp]			;bp stored at ss:bp	>
	call	SysInfoBufferedFileWrite
	add	sp, cx

	pop	ax				;ax = swap map

	cmp	dx, DCT_SWAP
	jnz	notSwap

	mov	ds, ax
	mov	ax, ','
	call	SysInfoPrintChar
	mov	ax, ' '
	call	SysInfoPrintChar
	mov	ax, ds:[SM_total]
	call	SysInfoPrintInteger
	mov	si, offset Swap1String
	call	SysInfoPrintString
	mov	ax, ds:[SM_page]
	call	SysInfoPrintInteger
	mov	si, offset Swap2String
	call	SysInfoPrintString
	mov	ax, ds:[SM_numFree]
	call	SysInfoPrintInteger
	mov	si, offset Swap3String
	call	SysInfoPrintString
	jmp	common

notSwap:
	mov	si, offset SerialPortString
	mov	cx, 8
	cmp	dx, DCT_SERIAL
	jz	serialParallelCommon
	mov	si, offset ParallelPortString
	mov	cx, 4
serialParallelCommon:

	mov	dx, ax
	mov	ax, 1
portLoop:
	shr	dx
	jnc	nextPort
	call	SysInfoPrintString
	call	SysInfoPrintInteger
nextPort:
	shr	dx				;skip bit
	inc	ax
	loop	portLoop

common:
	call	SysInfoPrintCRLF
done:
	clc					;keep going
	.leave
	ret

DriverCallback	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintBIOS

DESCRIPTION:	Print the first bytes of BIOS

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintBIOS	proc	near
	.enter

	; dump f800

	mov	si, offset BIOS1String
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	mov	ax, 0f800h			;segment
	mov	cx, 512/16			;# lines
	call	SysInfoDumpBytes

	call	SysInfoPrintCRLF

	; dump f000

	mov	si, offset BIOS2String
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	mov	ax, 0f000h			;segment
	mov	cx, 512/16			;# lines
	call	SysInfoDumpBytes

	call	SysInfoPrintCRLF

	; dump c000

	mov	si, offset VideoROMString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	mov	ax, 0c000h			;segment
	mov	cx, 512/16			;# lines
	call	SysInfoDumpBytes

	call	SysInfoPrintCRLF

	; dump bios data area

	mov	si, offset BiosDataString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	mov	ax, 40h				;segment
	mov	cx, 256/16			;# lines
	call	SysInfoDumpBytes

	call	SysInfoPrintCRLF

	.leave
	ret

SysInfoPrintBIOS	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintINIFile

DESCRIPTION:	Print the geos.ini file

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

if 0
SysInfoPrintINIFile	proc	near
	.enter

	; make sure that the file is up to date

	call	InitFileCommit

	call	SysInfoPrintCRLF
	mov	si, offset IniFileString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	mov	ax, SP_TOP
	call	FileSetStandardPath
	mov	dx, offset iniFileName
	call	SysInfoCopyFile

	.leave
	ret

SysInfoPrintINIFile	endp

; changed "geos.ini" to "make.txt"
;
; This is a hack. The real solution is for the routine to be granted
; access to the geos.ini file for copying.
;



if DBCS_PCGEOS
if	ERROR_CHECK
iniFileName	wchar	"make.txt", 0
else
iniFileName	wchar	"make.txt", 0
endif
else
if	ERROR_CHECK
iniFileName	char	"make.txt", 0
else
iniFileName	char	"make.txt", 0
endif
endif

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintCONFIGFile

DESCRIPTION:	Print the config.sys file

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintCONFIGFile	proc	near
	.enter

	call	SysInfoPrintCRLF
	mov	si, offset ConfigFileString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	mov	dx, offset configFileName
	call	SysInfoCopyFile

	.leave
	ret

SysInfoPrintCONFIGFile	endp

SBCS <configFileName	char	"config.sys", 0				>
DBCS <configFileName	wchar	"config.sys", 0				>


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintAUTOEXECFile

DESCRIPTION:	Print the autoexec.bat file

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintAUTOEXECFile	proc	near
	.enter

	call	SysInfoPrintCRLF
	mov	si, offset AutoexecFileString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	mov	dx, offset autoexecFileName
	call	SysInfoCopyFile

	.leave
	ret

SysInfoPrintAUTOEXECFile	endp

SBCS <autoexecFileName	char	"autoexec.bat", 0			>
DBCS <autoexecFileName	wchar	"autoexec.bat", 0			>


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintOldCONFIGFile

DESCRIPTION:	Print the old config.sys file

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintOldCONFIGFile	proc	near
	.enter

	call	SysInfoPrintCRLF
	mov	si, offset OldConfigFileString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	mov	dx, offset oldConfigFileName
	call	SysInfoCopyFile

	.leave
	ret

SysInfoPrintOldCONFIGFile	endp

SBCS <oldConfigFileName	char	"config.old", 0				>
DBCS <oldConfigFileName	wchar	"config.old", 0				>


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintOldAUTOEXECFile

DESCRIPTION:	Print the autoexec.bat file

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintOldAUTOEXECFile	proc	near
	.enter

	call	SysInfoPrintCRLF
	mov	si, offset OldAutoexecFileString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF

	mov	dx, offset oldAutoexecFileName
	call	SysInfoCopyFile

	.leave
	ret

SysInfoPrintOldAUTOEXECFile	endp

SBCS <oldAutoexecFileName	char	"autoexec.old", 0		>
DBCS <oldAutoexecFileName	wchar	"autoexec.old", 0		>


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintString

DESCRIPTION:	Print a string for sys info code

CALLED BY:	INTERNAL

PASS:
	bx - file handle
	si -chunk handle of text (in SysInfoUI resource)

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintString	proc	near	uses ax, bx, cx, dx, si, bp, ds
	.enter

	mov	bp, bx			;bp = file handle
	mov	bx, handle SysInfoUI
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]		;ds:si = string
	ChunkSizePtr	ds, si, cx	;cx = length
DBCS <	shr	cx, 1			;# bytes -> # chars		>
	dec	cx			;don't count null-terminator

	xchg	bx, bp			;bx = file handle, bp = mem handle
	call	SysInfoBufferedFileWrite

	mov	bx, bp			;bx = mem handle
	call	MemUnlock

	.leave
	ret

SysInfoPrintString	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoBufferedFileWrite

DESCRIPTION:	Print a string to the file, buffered

CALLED BY:	INTERNAL

PASS:
	ds:si - string
	bx - mem handle
	cx - size (# chars)

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoBufferedFileWrite	proc	near	uses	ax, cx, si, di, es
	.enter

	call	MemLock
	mov	es, ax				;es = dest
	mov	di, es:[BH_ptr]

copyLoop:
SBCS <	movsb								>
DBCS <	movsw								>
	cmp	di, SYS_INFO_BUFFER_SIZE-(size BufferHeader)
	jnz	notFull

	; flush

	mov	es:[BH_ptr], di
	call	SysInfoFlush
	mov	di, es:[BH_ptr]

notFull:
	loop	copyLoop
	mov	es:[BH_ptr], di

	call	MemUnlock

	.leave
	ret

SysInfoBufferedFileWrite	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoFlush

DESCRIPTION:	Flush the buffer block

CALLED BY:	INTERNAL

PASS:
	bx - mem handle

RETURN:
	none

DESTROYED:
	ax, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoFlush	proc	near	uses ax, cx, dx, ds
	.enter

	call	MemLock
	mov	ds, ax
	mov	dx, size BufferHeader		;ds:dx = byte to write
	mov	cx, ds:[BH_ptr]
	sub	cx, dx
	jz	done

	; convert to DOS character set

if DBCS_PCGEOS
	shr	cx, 1				; # bytes -> # chars
	xchg	dx, si				;ds:si = string
	push	ax, bx, dx, di
	mov	ax, '.'
	ERROR_C	0
	segmov	es, ds
	mov	di, si
	clr	bx, dx
	call	LocalGeosToDos			;cx = new size
	pop	ax, bx, dx, di
	xchg	dx, si
	jc	done
else
	push	ax, cx, di
	xchg	dx, si				;ds:si = string
	mov	ax, '.'
	call	LocalGeosToDos
	xchg	dx, si
	pop	ax, cx, di
endif

	clr	ax
	push	bx
	mov	bx, ds:[BH_file]
	call	FileWrite
	pop	bx

done:
	mov	ds:[BH_ptr], size BufferHeader

	call	MemUnlock

	.leave
	ret

SysInfoFlush	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintChar

DESCRIPTION:	Print a char for sys info code

CALLED BY:	INTERNAL

PASS:
	bx - file handle
	ax - character

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintChar	proc	near	uses ax, cx, si, ds
	.enter

	push	ax			;ss:bp points at CHAR, 0
	segmov	ds, ss
	mov	si, sp
	mov	cx, 1			;write 1 chracter
	call	SysInfoBufferedFileWrite
	pop	ax

	.leave
	ret

SysInfoPrintChar	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintCRLF

DESCRIPTION:	Print a CR, LF

CALLED BY:	INTERNAL

PASS:
	bx - file handle

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintCRLF	proc	near	uses ax
	.enter

SBCS <	mov	ax, C_CR						>
DBCS <	mov	ax, C_CARRIAGE_RETURN					>
	call	SysInfoPrintChar

SBCS <	mov	ax, C_LF						>
DBCS <	mov	ax, C_LINE_FEED						>
	call	SysInfoPrintChar

	.leave
	ret

SysInfoPrintCRLF	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintInteger

DESCRIPTION:	Print an integer for sys info code

CALLED BY:	INTERNAL

PASS:
	bx - file handle
	ax - integer

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@


MAX_INTEGER_LENGTH	=	12

SysInfoPrintInteger	proc	near	uses ax, cx, dx, si, di, ds, es
	.enter

	sub	sp, MAX_INTEGER_LENGTH
	segmov	es, ss
	mov	di, sp			;es:di = buffer

	clr	dx			;dx.ax = number
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii

	segmov	ds, ss
	mov	si, di			;ds:dx = buffer

	call	LocalStringLength	;cx = length w/o null

	call	SysInfoBufferedFileWrite

	add	sp, MAX_INTEGER_LENGTH

	.leave
	ret

SysInfoPrintInteger	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintEnum

DESCRIPTION:	Print an enumerated type for sys info code

CALLED BY:	INTERNAL

PASS:
	bx - file handle
	cs:si - table of EnumEntry's
	cx - number of entries in table
	ax - value

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintEnum	proc	near	uses cx, si
	.enter

searchLoop:
	cmp	ax, cs:[si].EE_value
	jz	found
	add	si, size EnumEntry
	loop	searchLoop

	mov	si, offset UnknownString
	jmp	common

found:
	mov	si, cs:[si].EE_string

common:
	call	SysInfoPrintString

	.leave
	ret

SysInfoPrintEnum	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintBitfield

DESCRIPTION:	Print a bitfield type for sys info code

CALLED BY:	INTERNAL

PASS:
	bx - file handle
	cs:si - table of BitfieldEntry's
	cx - number of entries in table
	ax - value

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintBitfield	proc	near	uses cx, si
	.enter

bitLoop:
	push	si
	mov	si, cs:[si].BE_string
	call	SysInfoPrintString
	pop	si
	test	ax, cs:[si].EE_value
	call	SysInfoPrintBoolean
	call	SysInfoPrintCRLF
	add	si, size BitfieldEntry
	loop	bitLoop

	.leave
	ret

SysInfoPrintBitfield	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintBoolean

DESCRIPTION:	Print an boolean for sys info code

CALLED BY:	INTERNAL

PASS:
	zero flag - set for NO, clear for YES
	bx - file handle

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Usage:

	test	ax, mask FLAG
	call	SysInfoPrintBoolean

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintBoolean	proc	near	uses si
	.enter

	mov	si, offset YesString
	jnz	common
	mov	si, offset NoString
common:
	call	SysInfoPrintString

	.leave
	ret

SysInfoPrintBoolean	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoCopyFile

DESCRIPTION:	Copy a file for sys info code

CALLED BY:	INTERNAL

PASS:
	cs:dx - file name to copy from
	bx - file handle

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version
	dloft	5/7/92		Updated FullFileAccessFlags
------------------------------------------------------------------------------@


COPY_BUFFER_SIZE	=	200

SBCS <SysInfoCopyFile	proc	near	uses ax, cx, dx, si, di, ds	>
DBCS <SysInfoCopyFile	proc	near	uses ax, cx, dx, si, di, ds, es	>
	.enter

	call	SysInfoPrintCRLF

	; open the file, ignoring normal permissions

	segmov	ds, cs
	mov	al, FullFileAccessFlags <0, FE_NONE, 0, 1, FA_READ_ONLY>
	call	FileOpen			;ax = file
	jc	cannotOpen
	mov	si, ax				;si = source

	segmov	ds, ss
DBCS <	segmov	es, ss							>
SBCS <	sub	sp, COPY_BUFFER_SIZE					>
DBCS <	sub	sp, COPY_BUFFER_SIZE*3					>
	mov	dx, sp				;ds:dx = buffer
	mov	di, sp				;ds:di = buffer

copyLoop:
	xchg	bx, si				;bx = source, si = dest
	clr	ax				;return errors
	mov	cx, COPY_BUFFER_SIZE
	call	FileRead
	jnc	noReadError

	cmp	ax, ERROR_SHORT_READ_WRITE
	jnz	doneGotSource
	jcxz	doneGotSource

noReadError:

	; fix up non-ascii chars

	push	cx, di
if DBCS_PCGEOS
	push	dx				;save buffer
	push	bx, si				;save src file, dest file
	mov	si, di				;ds:si = source
	lea	di, ss:[di][COPY_BUFFER_SIZE]	;es:di = dest
	mov	ax, '.'
	clr	bx, dx
	call	LocalDosToGeos			;cx = new size
	pop	dx, bx				;dx = src, bx = dest

	mov	si, di				;ds:si = buffer
	call	SysInfoBufferedFileWrite
	mov	si, dx				;si = source
	pop	dx				;dx = buffer
	pop	cx, di
else
asciiLoop:
	mov	al, {char} ds:[di]
	cmp	al, C_CR
	jz	asciiOK
	cmp	al, C_LF
	jz	asciiOK
	cmp	al, C_TAB
	jz	asciiOK
	cmp	al, 0x20
	jb	nonAscii
	cmp	al, 0x80
	jb	asciiOK
nonAscii:
	mov	{char} ds:[di], '.'
asciiOK:
	inc	di
	loop	asciiLoop
	pop	cx, di

	xchg	bx, si				;bx = dest, si = source
	xchg	dx, si				;dx = source file, si = buffer
	call	SysInfoBufferedFileWrite
	xchg	dx, si				;dx = buffer, si = source
endif

	cmp	cx, COPY_BUFFER_SIZE
	jz	copyLoop

	xchg	bx, si				;bx = source, si = dest
doneGotSource:
	clr	ax
	call	FileClose
SBCS <	add	sp, COPY_BUFFER_SIZE					>
DBCS <	add	sp, COPY_BUFFER_SIZE*3					>

	mov	bx, si				;bx = dest
exit:
	.leave
	ret

cannotOpen:
	mov	si, offset FileNotPresentString
	call	SysInfoPrintString
	call	SysInfoPrintCRLF
	jmp	exit

SysInfoCopyFile	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintHexWord

DESCRIPTION:	Print a hex word

CALLED BY:	INTERNAL

PASS:
	ax - word
	bx - file handle

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintHexWord	proc	near
	.enter

	xchg	al, ah			;al = high byte
	call	SysInfoPrintHexByte
	xchg	al, ah			;al = low byte
	call	SysInfoPrintHexByte

	.leave
	ret

SysInfoPrintHexWord	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintHexByte

DESCRIPTION:	Print a hex byye

CALLED BY:	INTERNAL

PASS:
	al - byte
	bx - file handle

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintHexByte	proc	near	uses ax
	.enter

	push	ax
	and	al, 0xf0
	shr	al
	shr	al
	shr	al
	shr	al
	call	SysInfoPrintHexNibble
	pop	ax
	and	al, 0x0f
	call	SysInfoPrintHexNibble

	.leave
	ret

SysInfoPrintHexByte	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoPrintHexNibble

DESCRIPTION:	Print a hex nibble

CALLED BY:	INTERNAL

PASS:
	al - nibble
	bx - file handle

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoPrintHexNibble	proc	near	uses ax
	.enter

	add	al, '0'
	cmp	al, '9'
	jbe	common

	add	al, 'a'-'0'-10
common:
	clr	ah
	call	SysInfoPrintChar

	.leave
	ret

SysInfoPrintHexNibble	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysInfoDumpBytes

DESCRIPTION:	Print the date

CALLED BY:	INTERNAL

PASS:
	ax - segment
	cx - number of lines (16 bytes each)
	bx - file handle

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version

------------------------------------------------------------------------------@

SysInfoDumpBytes	proc	near	uses ax, cx, dx, si, ds
	.enter

	mov	ds, ax
	clr	si				;ds:si = source

	; print address

outerLoop:
	mov	ax, si
	call	SysInfoPrintHexWord
	mov	ax, ':'
	call	SysInfoPrintChar
	mov	ax, ' '
	call	SysInfoPrintChar

	mov	dx, 16
innerLoop1:
	lodsb
	call	SysInfoPrintHexByte
	mov	ax, ' '
	call	SysInfoPrintChar
	dec	dx
	jnz	innerLoop1

	sub	si, 16
	mov	ax, ' '
	call	SysInfoPrintChar
	call	SysInfoPrintChar
	mov	ax, '"'
	call	SysInfoPrintChar

	mov	dx, 16
innerLoop2:
	lodsb
	cmp	al, 32
	jb	nonPrintable
	cmp	al, 127
	jb	printable
nonPrintable:
	mov	al, '.'
printable:
	clr	ah
	call	SysInfoPrintChar
	dec	dx
	jnz	innerLoop2

	mov	ax, '"'
	call	SysInfoPrintChar
	call	SysInfoPrintCRLF

	loop	outerLoop

	.leave
	ret

SysInfoDumpBytes	endp

SysInfoCode	ends
