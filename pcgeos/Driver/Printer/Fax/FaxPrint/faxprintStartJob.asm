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
 
    INT PrintStartJob		Handle the start of a print job

    INT FaxprintInitSwathBuffers
				Allocates two bitmap buffers for keeping
				the last print swath line, as required by
				the 2d compress code.

    INT FaxprintGetIniFlags	Loads up dgroup's faxoutFlags with flags
				from the .ini file.

    INT CheckDiskSpace		Checks the amount of disk space there is
				and guesses if there will be enough disk
				space for this job.  It sets a flag if not.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/12/93   	Initial revision
	AC	9/ 8/93		Changed for Faxprint
	jdashe	1/25/95		Tiramisu-ized.
	jimw	4/12/95		Updated for multiple-page cover pages
	jdashe	9/27/95		Added support for clipping blank lines at the
				 end of pages.

DESCRIPTION:
	
		

	$Id: faxprintStartJob.asm,v 1.1 97/04/18 11:53:05 newdeal Exp $

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

swathBuffer1Handle	hptr		; handle to swath bitmap buffer 1
swathBuffer2Handle	hptr		; handle to swath bitmap buffer 2
compressedLineHandle	hptr		; handle to compressed line buffer

twoDCompressedLines	word		; counts lines on the current page, and
					;  also indicates which swathBuffer
					;  contains the last line's image.
					;  Reset in PrintStartPage.

faxPageCount		word		; tells what page is currently
					;  being printed. (per job) 

faxFileFlags		word		; copy of the flags
absoluteCurrentLine	word		; keeps absolute line number, used
					;  before and during
					;  *replacing* scan lines

lastCPHeight		word		; the height of the last page in the
					;  cover page in scan lines

cpPageCount		word 		; # pages in the CP
bodyPageCount		word		; # pages in the body

progressOptr		dword		; output optr for progress
progressMessage		word		; message for progress

diskSpace		dword		; amount of disk space left, as best
					;  we can tell

faxoutFlags		FaxoutDialFlags	; interesting flags for this print job.

lowestNonBlankLine	word		; the lowest non-blank scanline in a
					;  particular page.  This is used if
					;  fax pages are to be only as large as
					;  they need to be -- with blank lines
					;  at the end of the page discarded.

udata	ends

;
; An error-checking routine that can be called to verify that ds
; points to our dgroup.  It's not totally 100% accurate, but almost...
;
if ERROR_CHECK

ECCheckDGroupES proc    far
;;		Assert	dgroup, es		; takes too long...
                pushf
                cmp     es:[dgroupHere], DGROUP_PROTECT1
                ERROR_NE -1
                popf
                ret
ECCheckDGroupES endp

ECCheckDGroupDS proc    far
;;		Assert	dgroup, ds		; takes too long...
                pushf
                cmp     ds:[dgroupHere], DGROUP_PROTECT1
                ERROR_NE -1
                popf
                ret
ECCheckDGroupDS endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the start of a print job

CALLED BY:	DriverStrategy

PASS:		bp	- PState segment

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
	AC	9/13/93		Modified for Faxprint
	jdashe	10/31/94	Updated for tiramisu
	jimw	4/12/95		Updated for multi-page cover pages
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintStartJob	proc	far
		uses	ax, bx, cx, dx, bp, si, di, ds, es
		.enter
	;
	;  Check to see if there's still enough disk space to add to the
	;  fax file.
	;
		call	CheckDiskSpace
	LONG	jc	notEnoughDiskSpace		
	;
	;  Store some device information from the PrinterInfo block into the
	;  PState.
	;
		mov	es, bp			; point at PState
		mov	bx, es:[PS_deviceInfo]	; bx <- device specific info
		call	MemLock			; ax <- device info segment
		mov	ds, ax			; ds <- device info segment
		mov	al, ds:[PI_type]	; get PrinterType field
		mov	ah, ds:[PI_smarts]	; get PrinterSmart field
		mov	{word} es:[PS_printerType], ax ; set both in PState
	;
	;  The Fax modem is ASF only...
	;
		mov	al, ds:[PI_paperInput]	; al <- PaperInput record
		mov	es:[PS_paperInput], al	; copy record into PState
		mov	al, ds:[PI_paperOutput] ; al <- PaperOutput record
		mov	es:[PS_paperOutput], al	; copy record into PState

		call	MemUnlock
	;
	; Initialize the swath bitmap buffers used by the 2d compress routines.
	;
		call	FaxprintInitSwathBuffers
	LONG 	jc	cannotInitBuffers

	;
	;  Get the fax file's header.  Load some dgroup vars. 
	;
		mov	ax, {word} ({FaxFileHeader}es:[PS_jobParams].JP_printerData).FFH_fileHandle
		Assert	fileHandle	ax

		tst	ax			; do we have a file?
	LONG	jz	badJobError

		mov	bx, handle dgroup
		call	MemDerefDS		; ds <- dgroup
EC <		call	ECCheckDGroupDS					>
		mov	bx, ax			; bx <- fax file handle
		mov	ds:[outputVMFileHan], bx
	;
	; Load up print job flags from the .ini file.
	;
		call	FaxprintGetIniFlags
	;
	; Ok.  We want the cpPageCount no matter what.  But the faxPageCount
	; (which is used to figure the proper ttl line) will be 0 if 1) there's
	; no CP or 2) we're printing the CP. Otherwise we set it to the
	; cpPageCount, which is what the rest of the faxprint routines expect.
	;
		mov	ax, ({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
								FFH_cpPageCount
		mov	ds:[cpPageCount], ax
		test	({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
				FFH_flags, mask FFF_PRINTING_COVER_PAGE
		jnz	clrAX
		test	({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
			FFH_flags, mask FFF_COVER_PAGE
		jnz	getAX
clrAX:		
		clr	ax
getAX:
		mov	ds:[faxPageCount], ax	; faxprintStartPage incs this
	;
	; Get the rest of the vars we need in dgroup.
	;
		mov	ax, ({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
							FFH_bodyPageCount
		mov	ds:[bodyPageCount], ax
		mov	ax, ({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
								FFH_flags
		mov	ds:[faxFileFlags], ax
		clrdw	ds:[diskSpace]
	;
	;  Memorize the progress optr and message, if they exist.
	;
		mov	ax, \
			({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
							FFH_progressOptr.high
		mov	ds:[progressOptr].high, ax
		mov	ax, ({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
							FFH_progressOptr.low
		mov	ds:[progressOptr].low, ax
		mov	ax, ({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
					FFH_progressMsg
		mov	ds:[progressMessage], ax

		call	FaxFileGetHeader	; ds:si <- FaxFileHeader
						; bp    <- MemHandle for header
	LONG	jc	cannotReadFile

		push	bp			; save mem handle # 2
	;
	;  Write misc information into the fax file's header.
	;
		movdw	ds:[si].FFH_pageWidth, FAXFILE_HORIZONTAL_SIZE
		movdw	ds:[si].FFH_pageHeight, FAXFILE_VERTICAL_SIZE
		mov	ds:[si].FFH_xRes, FAX_X_RES
		mov	ds:[si].FFH_compressionType, FCT_CCITT_T4_2D
		mov	ds:[si].FFH_imageType, FIT_BILEVEL
	;
	;  Find out what vertical resolution to use.
	;
		clr	bx
		mov	bl, es:[PS_mode]
		mov	bx, cs:FaxVerticalResolution[bx]
		Assert	ne 	bx, 0
		mov	ds:[si].FFH_yRes, bx
	;
	;  Find out if we're currently printing the cover page.  If so, we're
	;  set.
	;
		test	({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
				FFH_flags, mask FFF_PRINTING_COVER_PAGE
	LONG	jnz	copyParams
	;
	;  We're not currently printing the cover page.  Find out if there is a
	;  cover page at all.  If there is, and it's a header, we
	;  have to set the faxPageCounter to the number in FFH_cpPageCount
	;  (because the body STARTS on the last page of the CP).  Also 
	;  calculate and remember how tall the TOP of the last cover page is.
	;  bx has the vert resolution...
	;
		test	({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
					FFH_flags, mask FFF_COVER_PAGE
	LONG	jz	copyParams

		test	({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
				FFH_flags, mask FFF_COVER_PAGE_IS_HEADER
		jz	copyParams
	;
	;  Yep.  Cover page is header...
	;
		mov	ax, ({FaxFileHeader}es:[PS_jobParams].JP_printerData).\
						 FFH_lastCoverPageHeight
	;
	; Calculate the number of scanlines we'll ultimately replace.
	;		
		tst	ax		;if no height, no do
		jz	copyParams
		mul	bx		;height * vert res
		mov	cx, 72		;pts per inch (doc coords)
  		div	cx		;divide that by doc coords
		inc	ax		;add one to round out (one sacnline!)
	;
	; Since this is a header, the faxPageCount needs to be decremented,
	; because one of the cp pages doesn't exist.
	;
		push	es			; save PState		
		mov	bx, handle dgroup
		call	MemDerefES		; es <- dgroup
		dec	es:[faxPageCount]
		mov	es:[lastCPHeight], ax
		pop	es			; es <- PState
copyParams:
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
		mov	cl, PDEC_RAN_OUT_OF_DISK_SPACE
		jmp	short 	writeErrorFlag
	;
	; Handle the error if it can't create the fax file.  
	;
cannotReadFile:
		mov	cl, PDEC_CANNOT_CREATE_FAX_FILE
		jmp	short 	writeErrorFlag
	;
	; This job was deleted because we couldn't make enough
	; space for the job parameters.
	;
badJobError:
		mov	cl, PDEC_CANNOT_RESIZE_JOB_PARAMETERS
		jmp	short 	writeErrorFlag

cannotInitBuffers:
	;
	; Not enough memory for the swath print buffers.
	;
		mov	cl, PDEC_NOT_ENOUGH_MEMORY
;; FALL_THRU to writeErrorFlag...
;;		jmp	short 	writeErrorFlag
	;
	; This routine is used to by the error handlers above
	; to write an error flag so PrintEndJob will no if an
	; error condition has canceled the job.
	;
writeErrorFlag:
		mov	bx, handle dgroup
		call	MemDerefDS		; ds <- dgroup
		mov	ds:[errorFlag], cl
		stc
		jmp	exit
		
PrintStartJob	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintInitSwathBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates two bitmap buffers for keeping the last print swath
		line, as required by the 2d compress code.

CALLED BY:	PrintStartJob

PASS:		nothing

RETURN:		if successful:
			carry flag	    - clear
			compressedLineHandle- handle of unlocked line buffer
			swathBuffer1Handle  - handle of fixed swath buffer 1
			swathBuffer2Handle  - handle of fixed swath buffer 2
		if unsuccessful:
			carry flag	    - set

DESTROYED:	cx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	11/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxprintInitSwathBuffers	proc	near
		uses	ax, bx, ds
		.enter
		mov	bx, handle dgroup
		call	MemDerefDS		; ds <- dgroup
EC <		call	ECCheckDGroupDS					>
	;
	; Allocate the compressed line block used in the print swath code.
	; Make it swappable, so between swaths its memory can be used.
	;
		mov	ax, FAXFILE_MAX_HORIZONTAL_BYTE_WIDTH
		mov	cx, (mask HAF_ZERO_INIT) shl 8 or (mask HF_SWAPABLE)
		call	MemAlloc		; bx <- handle to block
		jc	done			; jump on error
		mov	ds:[compressedLineHandle], bx
	;
	; Allocate the first swath block.
	;
		mov	ax, FAXFILE_HORIZONTAL_BYTE_WIDTH
		mov	cx, ((mask HAF_ZERO_INIT) shl 8) or \
			    (mask HF_FIXED)
		call	MemAlloc		; bx <- handle to block
		jc	noMemOhDear		; jump on error

		mov	ds:[swathBuffer1Handle], bx
	;
	; Allocate the second swath block.
	;
		mov	ax, FAXFILE_HORIZONTAL_BYTE_WIDTH
		mov	cx, ((mask HAF_ZERO_INIT) shl 8) or \
			    (mask HF_FIXED) 
		call	MemAlloc		; bx <- handle to block
		jnc	noProblems		; jump if all's well
	;
	; The second block didn't work out.  Free the compressed line block and
	; the first swath block and bail.
	;
		mov	bx, ds:[swathBuffer1Handle]
		call	MemFree
noMemOhDear:
		mov	bx, ds:[compressedLineHandle]
		call	MemFree
		stc				; set an error flag.
		jmp	done
		
noProblems:
		mov	ds:[swathBuffer2Handle], bx

done:
		.leave
		ret
FaxprintInitSwathBuffers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintGetIniFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads up dgroup's faxoutFlags with flags from the .ini file.

CALLED BY:	PrintStartJob

PASS:		ds	- dgroup

RETURN:		printFlags	- loaded

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	9/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
faxflagsCategory	char FAX_INI_FAXOUT_CATEGORY, 0
faxflagsKey		char FAX_INI_FAXOUT_FLAGS_KEY, 0

FaxprintGetIniFlags	proc	near
		uses	bx, cx, dx, si
		.enter
	;
	; Load the faxout flags from the .ini file.
	;
		segmov	ds, cs, cx		; ds:si <- category
		mov	si, offset faxflagsCategory
		mov	dx, offset faxflagsKey	; cx:dx <- key
		clr	al			; al <- default flags
		call	InitFileReadInteger

		mov	bx, handle dgroup
		call	MemDerefDS		; ds <- dgroup

		mov	ds:[faxoutFlags], al
		
		.leave
		ret
FaxprintGetIniFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDiskSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the amount of disk space there is and guesses if
		there will be enough disk space for this job.  It sets a flag
		if not. 

CALLED BY:	PrintStartJob

PASS:		bp = PState

RETURN:		carry - set if printing should abort
		dgroup errorFlag is nonzero if error

DESTROYED:	es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 5/94    	Initial version
	jdashe	11/4/94		Tiramisu version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; This'll probably not be used elsewhere... it's the high byte in the dword of
; a disk's free space to allow 999 fax pages to be in this job.  Used for
; trivial rejecting the disk space check when there's a kajilion gigs
; available.
;
FAX_HUGE_DISK_CHECK_HIGH_WORD equ ((1000*FAX_2D_STD_PAGE_SIZE_ESTIMATE) shr 16)

CheckDiskSpace	proc	near
		uses	ax, bx, cx, si, di, bp, ds
		.enter
	;
	;  Get available disk space.
	;
		mov	bx, FAX_FILE_STANDARD_PATH
		call	DiskGetVolumeFreeSpace		; dx:ax - bytes free
	;
	; This is pretty amusing... if we can fit more than 65,535 fax pages on
	; the disk (which can happen if we have a multiple-Gb hard drive), the
	; div below will generate an int 0!  To avoid this, see if the amount
	; of space is bigger than a 999 page (~498 fine page) print job.
	;
		cmp	dx, FAX_HUGE_DISK_CHECK_HIGH_WORD
		jnc	exit				; jump if plenty of spc.
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
		mov	cx, FAX_2D_STD_PAGE_SIZE_ESTIMATE
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
		mov	bx, handle dgroup
		call	MemDerefDS		; ds <- dgroup
		mov	{byte} ds:[errorFlag], PDEC_RAN_OUT_OF_DISK_SPACE
		stc
		jmp	exit
		
CheckDiskSpace	endp
