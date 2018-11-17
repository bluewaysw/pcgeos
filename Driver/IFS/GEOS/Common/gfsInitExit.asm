COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gfsInitExit.asm

AUTHOR:		Adam de Boor, Apr 13, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/13/93		Initial revision


DESCRIPTION:
	From the filename, you'd probably think this was initialization
	and exit routines for the driver, and you'd be right...
		

	$Id: gfsInitExit.asm,v 1.1 97/04/18 11:46:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the driver.

CALLED BY:	DR_INIT
PASS:		nothing
RETURN:		carry set on error
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Call the device-specific routine to initialize the device.
		If that's happy, register with the kernel and create the
		sole drive we manage.
		
		At some point, we'll want to add ourselves to SP_TOP

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSInit		proc	far
if _PCMCIA
		ret
else
		.enter
	;
	; See if the primary FSD has been loaded yet and ensure its aux 
	; protocol number is compatible.
	; 
		mov	ax, GDDT_FILE_SYSTEM
		call	GeodeGetDefaultDriver
		tst	ax
		jz	fail			; not loaded, so we can do
						;  nothing
		mov_tr	bx, ax
		call	GeodeInfoDriver
		
		mov	ax, ds:[si].FSDIS_altStrat.offset
		mov	bx, ds:[si].FSDIS_altStrat.segment
		mov	cx, ds:[si].FSDIS_altProto.PN_major
		mov	dx, ds:[si].FSDIS_altProto.PN_minor

		segmov	ds, dgroup, di
		mov	ds:[gfsPrimaryStrat].offset, ax
		mov	ds:[gfsPrimaryStrat].segment, bx
		cmp	cx, DOS_PRIMARY_FS_PROTO_MAJOR
		jne	fail
		cmp	dx, DOS_PRIMARY_FS_PROTO_MINOR
		jb	fail
	;
	; Initialize the device.
	; 
		call	GFSDevInit
		jc	done
		call	GFSInitVerifyFS
		jc	closeFail
	;
	; That was successful, so register with the system.
	; 
		call	GFSInitRegister

	;
	; For some devices, we will now want to re-open all of the running
	; geodes so that they are read from the megafile.
	;

FILE <		call	GFSReOpenAllGeodes				>

	;
	; For some devices, we may want to remove the bootstrap directory
	; from SP_TOP once we are loaded, to prevent dir scans which can
	; be handled by the MegaFile from scanning the bootstrap directory.
	; (This is enabled by a key in the .INI file.)
	;

FILE <		call	GFSForgetBootstrapDir				>

		clc
done:
		.leave
		ret
closeFail:
	;
	; Couldn't get root directory, so close the device again before
	; returning failure.
	; 
		call	GFSDevExit
fail:
		stc
		jmp	done
endif
GFSInit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSInitVerifyFS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the filesystem we just opened is something we can
		handle and record its parameters

CALLED BY:	(INTERNAL) GFSInit
PASS:		nothing
RETURN:		carry set on error
DESTROYED:	ax, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _PCMCIA
GFSInitVerifyFS	proc	near
		.enter
	;
	; Fetch the root directory and filesystem header block
	; 
		clr	al
		call	GFSDevLock
		clrdw	dxax
		mov	cx, size GFSDirEntry + size GFSFileHeader
		segmov	es, dgroup, di
CheckHack <offset gfsRootDir eq offset gfsFileHeader + size gfsFileHeader>
		mov	di, offset gfsFileHeader
		call	GFSDevRead
		call	GFSDevUnlock
		jc	fail

	;
	; Make sure we understand the filesystem.
	; 
		cmp	{word}es:[gfsFileHeader].GFSFH_signature[0],
			'G' or ('F' shl 8)
		jne	fail
		cmp	{word}es:[gfsFileHeader].GFSFH_signature[2],
			'S' or (':' shl 8)
		jne	fail
		cmp	es:[gfsFileHeader].GFSFH_versionMajor, GFS_PROTO_MAJOR
		jne	fail
		cmp	es:[gfsFileHeader].GFSFH_versionMinor, GFS_PROTO_MINOR
		ja	fail

	;
	; Figure the location of its extended attributes and save that.
	; 
		movdw	dxax, <size GFSFileHeader>
		mov	cx, 1
		call	GFSDevFirstEA
		movdw	es:[gfsRootEA], dxax
		clc
done:
		.leave
		ret
fail:
		stc
		jmp	done
GFSInitVerifyFS	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSInitRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register ourselves and our filesystem with the system.

CALLED BY:	(INTERNAL) GFSInit
PASS:		nothing
RETURN:		gfsFSD and gfsDrive set
DESTROYED:	ax, bx, cx, dx, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _PCMCIA
GFSInitRegister	proc	near
		.enter
	;
	; Register ourselves.
	; 
		mov	cx, segment GFSStrategy
		mov	dx, offset GFSStrategy
		mov	ax, FSD_FLAGS
		mov	bx, handle 0
		clr	di		; no private data stored with disk
		call	FSDRegister
		
		segmov	ds, dgroup, ax
		mov	ds:[gfsFSD], dx
	;
	; Create the lone drive we manage.
	; 
		mov	al, -1
		mov	ah, MEDIA_FIXED_DISK
		mov	cx, mask DES_LOCAL_ONLY or mask DES_READ_ONLY or \
				mask DS_PRESENT or \
				(DRIVE_FIXED shl offset DS_TYPE)
		mov	si, offset gfsDriveName
		call	FSDInitDrive
		
	;
	; Remember the thing for later.
	; 
		segmov	ds, dgroup, ax
		mov	ds:[gfsDrive], dx
		.leave
		ret
GFSInitRegister	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSReOpenAllGeodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to re-open all of the running geodes so that they are
		read from the megafile.

CALLED BY:	GFSInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	all (like its caller)
SIDE EFFECTS:	files opened and closed, coreblocks updated.

PSEUDO CODE/STRATEGY:
		Scan the list of geodes. For each:
			lock its coreblock
			get its permanent name
			use the permanent name to lookup the path and filename
				for the .GEO file for that geode
			call kernel to open that file
			compare the serial numbers for the two files
			if same, then
				stuff the new file handle into the coreblock,
					getting the old handle
				close the old .GEO file
			else
				close the new .GEO file
			unlock the coreblock

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	4/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _FILE

GFSReOpenAllGeodes	proc	near

	;in case we decide to open any files, save our current dir

	call	FilePushDir

	;scan the list of geodes

	clr	bx
	mov	di, SEGMENT_CS
	mov	si, offset GFSReOpenAllGeodes_callback
	call	GeodeForEach

	call	FilePopDir
	ret
GFSReOpenAllGeodes	endp


;called from GeodeForEach. BX = geode handle

.assert (size GH_geodeSerial eq 2)

GFSReOpenAllGeodes_callback	proc	far

  newSerialNumber local	word		;holds GH_geodeSerial value

	.enter

	;Lock the coreblock, and loop through our list of well-known geode
	;permanent names, to see if we can handle this geode.

	push	bx
	call	MemLock			;lock the coreblock
	mov	ds, ax			;ds = coreblock for geode
	tst	ds:[GH_geoHandle]	;If the geode is XIPed, don't bother
	jz	finishUp		; reopening the fucking thing

	segmov	es, cs, ax		;es:di = lookup table
	mov	di, (offset geodeInfoList) - (size GeodeInfoListEntry)

searchLoop:
	;for each entry in the table:

	add	di, size GeodeInfoListEntry	;es:di = GeodeInfoListEntry

	tst	es:[di].GILE_sysRelPathAndName
	jz	finishUp			;skip if reached end of table...

	mov	si, offset GH_geodeName	;ds:si = permanent name for this geode

	push	di
	mov	cx, GEODE_NAME_SIZE	;cx = number of chars to compare
	repe	cmpsb			;compare (case sensitive, but fast)
	pop	di

	jne	searchLoop		;loop if not found

foundName::
	;Found the permanent name in our table, so we will want to re-open
	;this file. First, see which disk the file is currently opened on.

	segxchg	ds, es			;ds:di = GeodeInfoListEntry
					;es = coreblock

	mov	bx, es:[GH_geoHandle]	;bx = existing .GEO file handle
	call	FileGetDiskHandle
	mov	cx, bx			;cx = disk handle for that file

	;Try to re-open the .GEO file.

	mov	dx, ds:[di].GILE_sysRelPathAndName
					;ds:dx = filename

	mov	ax, SP_SYSTEM		;go to the SYSTEM directory
	call	FileSetStandardPath

	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
	call	FileOpen
	jc	finishUp		;ignore if any file error...

	;See if both files are on the same disk. If so, no need to re-open.

	mov	bx, ax			;bx = new file handle
	call	FileGetDiskHandle	;set bx = disk handle for new file
	cmp	bx, cx			;same as existing file?

	mov	bx, ax			;in any case, set bx = new file handle

	je	closeFile		;skip if so (the existing file was
					;already opened from the megafile,
					;or from the local tree)...

	;Make sure that the serial numbers are IDENTICAL. Otherwise,
	;next time we try to read a resource in from the file, we may read
	;garbage.

	.assert (offset GFH_coreBlock.GH_geodeSerial) lt 256

	clr	cx
	mov	dx, offset GFH_coreBlock.GH_geodeSerial
	mov	al, FILE_POS_START
	call	FilePos			;seek to the location of the serial #

	segmov	ds, ss, ax
	lea	dx, newSerialNumber	;ds:dx = stack frame to hold new ser #

	mov	cx, size GH_geodeSerial
	clr	ax			;we can handle errors
	call	FileRead		;read CX bytes to DS:DX
	jc	closeFile		;skip if there was an error

	mov	si, dx
	mov	ax, ds:[si]		;grab new file's serial #
	cmp	ax, es:[GH_geodeSerial]	;compare the two serial numbers

EC <	WARNING_NE CANNOT_ADOPT_BOOTSTRAP_EXEC_FILE_BECAUSE_SERIAL_NUMBER_DIFFERS >

	jne	closeFile		;skip if they are not the same...

adoptNewFile::
	;we can adopt this new file. Stuff it's handle into
	;the coreblock, then fallthru to close the old file

	xchg	bx, es:[GH_geoHandle]	;bx = old file

closeFile:
	;close the old file, or the new file, depending on how we are called

	mov	al, FILE_NO_ERRORS
	call	FileClose

finishUp:
	pop	bx			;^hbx = coreblock handle
	call	MemUnlock		;unlock the coreblock

	clc				;continue with next geode

	.leave
	ret
GFSReOpenAllGeodes_callback	endp


;each of the entries in our lookup table looks like this:

GeodeInfoListEntry	struc
    GILE_permName		char GEODE_NAME_SIZE dup (?)
					;8 character geode permanent name
    GILE_sysRelPathAndName	nptr.char
					;offset to path and filename string
GeodeInfoListEntry	ends

.assert (GEODE_NAME_SIZE eq 8)

geodeInfoList	GeodeInfoListEntry \
	<"geos    ", geosSysRelPath>,
	<"ms4     ", ms4SysRelPath>,
	<"ms3     ", ms3SysRelPath>,
	<"megafile", megafileSysRelPath>,
	<"os2     ", os2SysRelPath>,
	<"dri     ", driSysRelPath>,
	<"msnet   ", msnetSysRelPath>,
	<"cdrom   ", cdromSysRelPath>,
	<0, 0>				;end of list

NEC   <	geosSysRelPath	char	"geos.geo", 0				>
EC    <	geosSysRelPath	char	"geosec.geo", 0				>

NEC   <	ms4SysRelPath	char	"fs\\\\ms4.geo", 0			>
EC    <	ms4SysRelPath	char	"fs\\\\ms4ec.geo", 0			>

NEC   <	ms3SysRelPath	char	"fs\\\\ms3.geo", 0			>
EC    <	ms3SysRelPath	char	"fs\\\\ms3ec.geo", 0			>

NEC   <	megafileSysRelPath char	"fs\\\\megafile.geo", 0			>
EC    <	megafileSysRelPath char	"fs\\\\megafile.geo", 0			>
					;NOTE: IS 8.3 FILENAME, NOT 9.3

NEC   <	os2SysRelPath	char	"fs\\\\os2.geo", 0			>
EC    <	os2SysRelPath	char	"fs\\\\os2ec.geo", 0			>

NEC   <	driSysRelPath	char	"fs\\\\dri.geo", 0			>
EC    <	driSysRelPath	char	"fs\\\\driec.geo", 0			>

NEC   <	msnetSysRelPath	char	"fs\\\\msnet.geo", 0			>
EC    <	msnetSysRelPath	char	"fs\\\\msnetec.geo", 0			>

NEC   <	cdromSysRelPath	char	"fs\\\\cdrom.geo", 0			>
EC    <	cdromSysRelPath	char	"fs\\\\cdromec.geo", 0			>

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSForgetBootstrapDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we want to forget about the bootstrap directory,
		by dropping it from the SP_TOP list.

CALLED BY:	GFSInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	all (like its caller)
SIDE EFFECTS:	SP_TOP changed in (loaderVars.KLV_stdDirPaths)

PSEUDO CODE/STRATEGY:
		if there is a "bootstrapPath = PATH" key in the [gfs] category,
		then call FileDeleteStandardPathDirectory to delete it from
		the list of standard paths.

		In the future, we may also want to update other standard
		paths.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	4/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _FILE

gfsKeyStr2		char	'gfs', 0
bootstrapPathKeyStr	char	'bootstrapPath', 0

GFSForgetBootstrapDir	proc	near

	bootstrapPath	local	PathName

		.enter

	;
	; Fetch the name for the drive; use the default if nothing specified
	; 
		segmov	es, ss, di		;es:di = destination buffer
		lea	di, bootstrapPath

		segmov	ds, cs, si
		mov	si, offset gfsKeyStr2	;ds:si = category string

		mov	cx, cs			;cx:dx = key to find
		mov	dx, offset bootstrapPathKeyStr

		push	bp
		mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
				(size PathName)
		call	InitFileReadString
		pop	bp
		jc	done			;skip if not found...

	;
	; Ask the kernel to nuke this path from the SP_TOP list. Will be ignored
	; if is the FIRST SP_TOP path.
	;

		segmov	ds, es, ax		;ds:dx = path to delete
		mov	dx, di

		mov	ax, SP_TOP		;nuke it from the SP_TOP list
		call	FileDeleteStandardPathDirectory
						;ignore errors

done:
		.leave
		ret
GFSForgetBootstrapDir	endp

endif

Init		ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish with the device.

CALLED BY:	DR_EXIT
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	no further access to any file on the filesystem is allowed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSExit		proc	far
		.enter
		call	GFSDevExit
		.leave
		ret
GFSExit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend access to the filesystem

CALLED BY:	DR_SUSPEND
PASS:		cx:dx	= buffer in which to place reason for refusal, if
			  suspension refused
RETURN:		carry set if suspension refused
			cx:dx	= buffer filled with null-terminated reason,
				  standard PC/GEOS character set.
		carry clear if suspension approved
DESTROYED:	ax, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Perhaps we should close the device here? It's not likely to
		be in the extended SFT, but you never know...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSSuspend	proc	far
		.enter
		clc
		.leave
		ret
GFSSuspend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsuspend access to the filesystem

CALLED BY:	DR_UNSUSPEND
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Undo what we did in GFSSuspend. Currently, nothing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSUnsuspend	proc	far
		.enter
		clc
		.leave
		ret
GFSUnsuspend	endp

Resident	ends
