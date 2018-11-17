COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax Printer Driver
FILE:		group3StartJob.asm

AUTHOR:		Jacob Gabrielson, Apr 12, 1993

ROUTINES:
	Name			Description
	----			-----------
    INT ECCheckDGroupES

    INT PrintStartJob		Handle the start of a print job

    INT Group3OpenFile		Opens the output file for the printer
				driver.

    INT Group3GenerateFileName	Opens the actual VM fax file and tries to
				generate a unique name for the file

    INT CheckDiskSpace		Checks the amount of disk space there is
				and guesses if there will be enough memory.
				It then querry's the user if he wants to
				continue.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/12/93   	Initial revision
	AC	9/ 8/93		Changed for Group3


DESCRIPTION:
	
		

	$Id: group3StartJob.asm,v 1.1 97/04/18 11:52:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		Initialized data
;-----------------------------------------------------------------------------

idata	segment

if ERROR_CHECK
        DGROUP_PROTECT1 equ     0xA6D3
        dgroupHere      word    DGROUP_PROTECT1 ; protect word
endif

idata	ends

;-----------------------------------------------------------------------------
;		Data initialized to 0
;-----------------------------------------------------------------------------

udata	segment

errorFlag		byte		; A flag that will be passed
					; from start job to end job to
					; indicate if an error has
					; occurred.
					; Must indicate no error to start

outputVMFileHan		hptr		; output file for fax
outputHugeArrayHan	hptr		; handle to huge array for fax

faxPageCount		word		; tells what page is currently
					; being printed

gstringFileName		byte	DOS_DOT_FILE_NAME_LENGTH+1	dup (?)
	
udata	ends



;
; An error-checking routine that can be called to verify that ds
; points to our dgroup.  It's not totally 100% accurate, but almost...
;
if ERROR_CHECK

ECCheckDGroupES proc    far
                pushf
                cmp     es:[dgroupHere], DGROUP_PROTECT1
                ERROR_NE -1
                popf
                ret
ECCheckDGroupES endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the start of a print job

CALLED BY:	DriverStrategy
PASS:		bp	= PState segment
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	- Check if this is an error job by looking at the FaxSpoolID
	- Check if there's enough disk space.

	- Set CWD to fax directory.  If it doesn't exist, make one.
	- Create the output file.
	- Update printer data in the fax file header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/12/93    	Initial version
	AC	9/13/93		Modified for Group3

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintStartJob	proc	far
		uses	ax, bx, cx, dx, bp, si, di, ds, es
		.enter
	;
	;  Check for some error conditions:
	; 	- first check if the job should be nuked because 
	; 	  it has an error FaxSpoolID.
	;	- then check to see if there will be enough disk space.
	;
		mov	es, bp			; point at PState
		.warn	-field
		cmpdw	es:[PS_jobParams].JP_printerData.FFH_spoolID, \
			FAX_ERROR_SPOOL_ID
		.warn	@field
		LONG	jz	badJobError

	;
	;  Check to see if there's enough disk space to make the fax file
	;
		call	CheckDiskSpace
		LONG	jc	notEnoughDiskSpace		
	;
	;  Store the name of the spooler file for the end-job handler.
	;
		segmov	ds, es, bx			; ds = PState
		mov	bx, segment dgroup
		mov	es, bx				; es = dgroup
		mov	di, offset gstringFileName	; es:di = dest buffer
		lea	si, ds:[PS_jobParams].JP_fname	; ds:si = filename
		mov	cx, DOS_DOT_FILE_NAME_LENGTH+1	; +1 for null
		rep	movsb
		segmov	es, ds, bx			; es = PState
	;
	;  Open a VM file so we can store the fax information into it.
	;

		mov	bx, es:[PS_deviceInfo]	; bx <- device specific info
		call	MemLock			; ax <- device info segment
		mov	ds, ax			; ds <- device info segment
		mov	al, ds:[PI_type]	; get PrinterType field
		mov	ah, ds:[PI_smarts]	; get PrinterSmart field
		mov	{word} es:[PS_printerType], ax ; set both in PState
	;
	;  I think the following is normally set by the UI eval routine,
	;  but since the Fax modem is ASF only, it seems best to set it 
	;  here...
	;
		mov	al, ds:[PI_paperInput]	; al <- PaperInput record
		mov	es:[PS_paperInput], al	; copy record into PState
		mov	al, ds:[PI_paperOutput] ; al <- PaperOutput record
		mov	es:[PS_paperOutput], al	; copy record into PState

		call	MemUnlock
	;
	;  Create the fax file:
	;	* cx:dx will be buffer to put file name.
	;  	  (This buffer will be in the PState)
	;  	* if an error occured, kill the fax job.
	;
		.warn	-field

		mov	cx, es
		lea	dx, es:[PS_jobParams].JP_printerData.FFH_fileName
		call	Group3OpenFile		; cx:dx filled
						; bx <- file handle
		LONG	jc	cannotMakeFile
		.warn	@field

	;
	;  Get the fax file's header. 
	;
		mov	ax, segment dgroup		; ax <- dgroup
		mov	ds, ax
		mov	ds:[outputVMFileHan], bx
		mov	ds:[faxPageCount], 1		; start the page count
		call	FaxFileGetHeader		; ds:si = FaxFileHeader
		LONG	jc	cannotMakeFile

		push	bp				; save mem handle # 2
	;
	;  Write misc information into the fax file's header.
	;
		movdw	ds:[si].FFH_pageWidth, FAXFILE_HORIZONTAL_SIZE
		movdw	ds:[si].FFH_pageHeight, FAXFILE_VERTICAL_SIZE
		mov	ds:[si].FFH_xRes, FAX_X_RES
		mov	ds:[si].FFH_compressionType, FCT_CCITT_T4_1D
		mov	ds:[si].FFH_imageType, FIT_BILEVEL
	;
	;  Find out what vertical resolution to use.
	;
		clr	bx
		mov	bl, es:[PS_mode]
		mov	bx, cs:FaxVerticalResolution[bx]
		mov	ds:[si].FFH_yRes, bx
	;
	;  Find out if there is a cover page. If there is a cover page
	;  we have to inc the faxPageCounter since we should start at page
	;  2.  If there is not a cover page we do nothing and a branch in
	;  PrintStartPage will skip the Group3AddHeader.
	;
		.warn	-field
		test	es:[PS_jobParams].JP_printerData.FFH_flags, 
			mask FFF_COVER_PAGE
		.warn	@field
		jz	noCoverPage
		push	es			; save PState
		segmov	es, dgroup, bx		; es <- dgroup
		inc	es:[faxPageCount]
		pop	es			; es <- PState
noCoverPage:
	;
	;  Copy information in the JobParameters into the fax file header
	;  es:cx <- fax file header
	;  ds:dx <- JobParameters
	;
		segxchg	es, ds			; ds = PState segment
		mov	cx, si			; es:cx <- fax file header

		lea	dx, ds:[PS_jobParams]	; ds:dx <- JobParameters

		mov	bx, size word * (length StartJobParameterOffsets - 1)
copyInfo:
	;
	;  Get ds:si to point to correct location in the JobParameters.
	;
		mov	si, dx		
		add	si, cs:StartJobParameterOffsets[bx]
	;
	;  Get es:di to point to the correct location in the fax 
	;  file header.
	;
		mov	di, cx
		add	di, cs:StartJobFaxFileOffsets[bx]
	;
	;  Copy each string from the JobParameters to the FaxFileHeader.
	;  LocalCopyString is fine and all, but it only works if the
	;  string is null-terminated, so there had better not be garbage
	;  in any of the fields or it will destroy the entire header
	;  after the string in question.  -stevey 3/8/94
	;
		LocalCopyString

		dec	bx
		dec	bx
		jns	copyInfo
	;
	;  Copy the flags from the JobParameters to the FaxFileHeader
	;  es:di <- begining of actual FaxFileHeader
	;  ds:si <- JobParameters.JP_printerData (FaxFileHeader)
	;
		mov	si, dx				; ds:si = JobParameters
		lea	si, ds:[si].JP_printerData	; ds:si = JP_printerData

		mov	di, cx				; es:di = FaxFileHeader
		mov	ax, ds:[si].FFH_flags		; flags from JobParams
		mov	es:[di].FFH_flags, ax		; copy to FaxFileHeader
	;
	;  Copy the Fax Spool ID into the file.
	;
		movdw	es:[di].FFH_spoolID, ds:[si].FFH_spoolID, ax
	;
	;  Make sure to write in the fax file header that the file is 
	;  currently disabled.  This is done so the fax spooler can tell
	;  if the fax file is valid or not.
	;
		mov	es:[di].FFH_status, FFS_DISABLED
	;
	;  Copy the FaxSpoolDateTime structure from the JobParameters into
	;  the fax file header.
	;
		mov	cx, size FaxSpoolDateTime
		lea	di, es:[di].FFH_spoolDateTime
		lea	si, ds:[si].FFH_spoolDateTime
		rep	movsb
	;
	;  Unlock the block that contains the fax file header.
	;
		pop	bp			; # 2
		call	VMDirty			; bp has mem handle
		call	VMUnlock

		clc
exit:		
		.leave
		ret
	;
	; 	---------------------------
	;	E R R O R   H A N D L E R S
	;	---------------------------
	;

	;
	; Handle error if the user wants to abort because they don't
	; think there's enough room on the disk.
	;
notEnoughDiskSpace:
		mov	cl, PDEC_USER_SAYS_NO_DISK_SPACE
		jmp	short 	writeErrorFlag
	;
	; Handle the error if it can't create the fax file.  
	;
cannotMakeFile:
		mov	cl, PDEC_CANNOT_CREATE_FAX_FILE
		jmp	short 	writeErrorFlag
	;
	; This job was deleted because we couldn't make enough
	; space for the job parameters.
	;
badJobError:
		mov	cl, PDEC_CANNOT_RESIZE_JOB_PARAMETERS
		jmp	short 	writeErrorFlag
	;
	; This routine is used to by the error handlers above
	; to write an error flag so PrintEndJob will no if an
	; error condition has canceled the job.
	;
writeErrorFlag:
		mov	ax, segment dgroup
		mov	ds, ax
		mov	ds:[errorFlag], cl
		stc
		jmp	exit
		
PrintStartJob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3OpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens the output file for the printer driver.

CALLED BY:	PrintStartJob

PASS:		cx:dx	= buffer to put file name

RETURN:		^lbx	= file handle
		cx:dx	= file name filled

		carry set if file is not able to be open 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
	- Sets the thread's directory to the document directory
	- Creates a file 
	- Opens the file
	- Make the fax file header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3OpenFile	proc	near
		uses	ax, cx, dx, di, ds, es
		.enter
	;
	; Set the current directory to the fax directroy which is at
	; SP_PRIVATE_DATA/FaxDir
	;
		call	FilePushDir
		call	PutThreadInFaxDir
		jc	exit
		
openTheFile::
	;
	; Open the file.  Returns file handle and buffer cx:dx filled
	; with file name.
	;
		call	Group3GenerateFileName		; bx <- filehandle
		jc	exit
	;
	; Make the VM file into a fax file
	;
		call	FaxFileInitialize
	;
	; Write the name of the file to the header.
	;
		call	FaxFileGetHeader		; ds:si = header
		segmov	es, ds, di
		lea	di, ds:[si].FFH_fileName	; es:di = name buffer

		movdw	dssi, cxdx			; ds:si = filename

if ((size FileLongName and 1) eq 0)
		mov	cx, size FileLongName / 2
		rep	movsw
else
		mov	cx, size FileLongName
		rep	movsb
endif
		call	VMDirty				; dirty FaxFileHeader...
		call	VMUnlock			; ...and unlock it
		mov	cx, ds				; cx:dx = filename	
exit:
		call	FilePopDir

		.leave
		ret
Group3OpenFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3GenerateFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens the actual VM fax file and tries to generate a unique
		name for the file

CALLED BY:	Group3OpenFile

PASS:		cx:dx	= buffer to put file name

RETURN:		bx	- file handle
		cx:dx	= filled with new filename
		carry returned if can't make the file

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3GenerateFileName	proc	near
	uses	ax, cx, dx, di, si, bp, ds, es
	.enter

	;
	; Generate the filename. Now copy the prefix of the string 
	; to the filename.
	;
		segmov	ds, cs, si
		mov	si, offset faxFilePrefix
		mov	es, cx
		mov	di, dx			; es:di <- buffer to write
		mov	bp, dx			; save offset for later
		LocalCopyString
		dec	di			; place to write number to.
	;
	; Start the increment of the filenames
	;
		clr	ax
		segmov	ds, es, dx

makeFilename:
		clr	dx
		inc	ax
		push	ax				; save ... count?
		mov	cx, mask UHTAF_INCLUDE_LEADING_ZEROS or \
			    mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii	; cx <- length of string
	;
	;  Open the file with the generated filename.  Make sure
	;  it's sync-update in order to prevent tons of notifications
	;  going out during spooling.
	;
		mov	ax, (VMO_CREATE_ONLY shl 8) or \
			mask VMAF_FORCE_READ_WRITE or\
			mask VMAF_FORCE_SHARED_MULTIPLE


		clr	cx				; default compression

		mov	dx, bp
		call	VMOpen				; bx <- filehandle
		mov_tr	cx, ax				; preserves carry
		jc	noSetAttrs			; couldn't open it

		clr	ah				; bits to clear
		mov	al, mask VMA_SYNC_UPDATE or mask VMA_SINGLE_THREAD_ACCESS; bits to set
		call	VMSetAttributes
noSetAttrs:
	;
	; Check to see if there were no errors in creating the file.
	;
		pop	ax				; ax <- counter
		cmp	cx, VM_FILE_EXISTS
		je	makeFilename
	;
	; See if the filename is a new filename
	;
		cmp	cx, VM_CREATE_OK
		jne	createError
	;
	; Success!  Save the filename (in ds:dx) into dgroup, in
	; case we need to delete the file, later.
	;
		clc
exit:
		.leave
		ret

createError:
		stc
		jmp	exit
		
Group3GenerateFileName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDiskSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the amount of disk space there is and guesses if
		there will be enough memory.  It then queries the user
		if they want to continue.

CALLED BY:	PrintStartJob

PASS:		bp = PState

RETURN:		carry - set if printing should abort
		dgroup errorState is nonzero if error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Estimates for how big each page will be (based on resolution).
;
;faxPageSize	dword	\
;	FAX_STD_PAGE_SIZE_ESTIMATE,	; PM_GRAPHICS_LOW_RES
;	0,				; PM_GRAPHICS_MED_RES (none)
;	FAX_FINE_PAGE_SIZE_ESTIMATE	; PM_GRAPHICS_HI_RES

CheckDiskSpace	proc	near
		uses	ax,bx,cx,si,di,bp
		.enter
	;
	;  Get available disk space.
	;
if _FLOPPY_BASED_FAX
		clr	al
		call	DiskRegisterDisk
		tst	bx
		jz	noFloppy
else
		mov	bx, FAX_DISK_HANDLE
endif
		call	DiskGetVolumeFreeSpace		; dx:ax - bytes free
	;
	;  Get appropriate estimate for space requirements/page.
	;
if 0
		mov	es, bp
		clr	bh
		mov	bl, es:[PS_mode]		; bx <- PrinterMode
		shl	bx				; dword table
		mov	cx, cs:[faxPageSize][bx]
endif
	;
	;  Divide how much space we have by page estimate.  That gives
	;  us the number of pages that will fit on the disk.  We then 
	;  compare that number with how many pages we need and take it 
	;  from there.
	;
	;  To keep us from having to do slow, ugly dword division,
	;  we'll make use of the fact that the required disk space
	;  for fine-res faxes is twice that for standard ones.
	;
		mov	cx, FAX_STD_PAGE_SIZE_ESTIMATE
		div	cx				; ax = #pages
	;
	;  We've got the estimate for standard-mode...
	;
		mov	es, bp
		cmp	es:[PS_mode], PM_GRAPHICS_LOW_RES
		je	gotPages
	;
	;  ...but we need an estimate for fine mode.  We can't
	;  just double the standard-mode estimate because the
	;  remainder of the division (in dx) may almost be enough
	;  for an entire page.  Well, who cares...it's only an
	;  estimate.  We've got code in PrintSwath() that prevents
	;  the file from actually eating up all the space...
	;
		shr	ax				; pages / 2 (fine)
gotPages:
		cmp	es:[PS_jobParams].JP_numPages, ax
		ja	notEnoughDiskSpace
		clc					; it'll fit!
exit:
		.leave
		ret

notEnoughDiskSpace:
	;
	; Pop up a dialog to let the user there's not enough disk space.
	;

		mov	si, offset NotEnoughDiskSpaceWarning
		mov	ax, CustomDialogBoxFlags \
				<1, CDT_WARNING, GIT_AFFIRMATION, 0 >
		call	DoDialog		; ax <- InteractionCommand
	;
	;  We don't want to make assumptions about whether IC_YES is
	;  greater than or less than IC_NO, so we do the following
	;  weirdness to get the carry set appropriately.
	;
		cmp	ax, IC_YES
		je	exit			; carry clear if they're equal
		stc				; might still be clear...
		jmp	exit

if _FLOPPY_BASED_FAX
noFloppy:
	;
	; Pop up a dialog to tell the user that we could not find a
	; floppy.
	;
		mov	si, offset NeedFloppy
		mov	ax, CustomDialogBoxFlags \
				<1, CDT_ERROR, GIT_NOTIFICATION, 0 >
		call	DoDialog		; ax <- InteractionCommand
		stc				
		jmp	exit		
endif
		
CheckDiskSpace	endp











