COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spool/Lib
FILE:		libC.asm

AUTHOR:		Don Reeves, Oct 17, 1992

ROUTINES:
	Name			    	Description
	----			    	-----------
	SPOOLGETDEFAULTPAGESIZEINFO 	Get the default page size info.
	SPOOLSETDEFAULTPAGESIZEINFO 	Set the default page size info.
	SPOOLGETNUMPAPERSIZES	    	Return the number of paper sizes
    	    	    	    	    	 defined.
	SPOOLGETPAPERSTRING 	    	Fill a passed buffer with the string
    	    	    	    	    	 for a paper size.
	SPOOLGETPAPERSIZE   	    	Get the dimensions and default page
    	    	    	    	    	 layout for a paper size.
	SPOOLCONVERTPAPERSIZE	    	Return the paper size number for a
    	    	    	    	    	 given width and height.
	SPOOLGETPAPERSIZEORDER	    	Get the current paper size order array
	SPOOLSETPAPERSIZEORDER		Set a new paper size order to be
    	    	    	    	    	 displayed.
	SPOOLCREATEPAPERSIZE	    	Create a new paper size and store it
    	    	    	    	    	 in the .INI file.
	SPOOLDELETEPAPERSIZE	    	Delete a paper size.
	SPOOLGETNUMPRINTERS 	    	Return the number of printers
    	    	    	    	    	 currently installed.
	SPOOLGETPRINTERSTRING	    	Fill a passed buffer with a printer's
    	    	    	    	    	  name.
	SPOOLCREATEPRINTER	    	Add a new printer to the end of the
    	    	    	    	    	 printer list
	SPOOLDELETEPRINTER  		Delete a printer from the current
    	    	    	    	    	  printer list.
	SPOOLSETDEFAULTPRINTER		Set the current default printer.
	SPOOLCREATESPOOLFILE	    	Create and open a unique spool file
		    	    	    	  in the SP_SPOOL standard directory.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/92	Initial version
    	jenny	9/03/93	    	Added 15 stubs

DESCRIPTION:
	Contains the C stubs for the library module

	$Id: libC.asm,v 1.1 97/04/07 11:10:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Spool	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLGETDEFAULTPAGESIZEINFO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the default page size info.

CALLED BY:	GLOBAL
PARAMETERS:	void (PageSizeReport *psr)
RETURN:		*psr filled with the default page size info
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLGETDEFAULTPAGESIZEINFO	proc far	psr:fptr.PageSizeReport
		uses si, ds	
		.enter

		lds	si, psr
		call	SpoolGetDefaultPageSizeInfo

		.leave
		ret
SPOOLGETDEFAULTPAGESIZEINFO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLSETDEFAULTPAGESIZEINFO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default page size info.

CALLED BY:	GLOBAL
PARAMETERS:	void (PageSizeReport *psr)
RETURN:		nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLSETDEFAULTPAGESIZEINFO	proc far	psr:fptr
		uses si, ds	
		.enter

		lds	si, psr
		call	SpoolSetDefaultPageSizeInfo

		.leave
		ret
SPOOLSETDEFAULTPAGESIZEINFO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLGETNUMPAPERSIZES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of paper sizes defined.

CALLED BY:	GLOBAL
PARAMETERS:	void (NumPaperSizesInfo *sizesInfo, PageType pageType)
RETURN:		*sizesInfo filled with the number of paper sizes and
		the default size. Currently, the default size returned
		is always 0.
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NumPaperSizesInfo	struct
	NPSI_numSizes		word
	NPSI_defaultSize	word
NumPaperSizesInfo	ends

SPOOLGETNUMPAPERSIZES	proc	far	sizesInfo:fptr.NumPaperSizesInfo,
					pageType:PageType
		uses	ds, si
		.enter
		mov	bp, ss:[pageType]
		call	SpoolGetNumPaperSizes
		lds	si, ss:[sizesInfo]
		mov	ds:[si].NPSI_numSizes, cx
		mov	ss:[si].NPSI_defaultSize, dx	; dx currently always 0
		.leave
		ret
SPOOLGETNUMPAPERSIZES	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLGETPAPERSTRING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a passed buffer with the string for a paper size.

CALLED BY:	GLOBAL
PARAMETERS:	word (char *stringBuf, word paperSizeNum, PageType pageType)
RETURN:		length (not counting final null) of null-terminated string
		now stored in *stringBuf
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLGETPAPERSTRING	proc	far	stringBuf:fptr.char,
					paperSizeNum:word,
					pageType:PageType
		uses	es, di
		.enter
		les	di, ss:[stringBuf]
		mov	ax, ss:[paperSizeNum]
		mov	bp, ss:[pageType]
		call	SpoolGetPaperString
		mov_tr	ax, cx				; ax <- string length
		.leave
		ret
SPOOLGETPAPERSTRING	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLGETPAPERSIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dimensions and default page layout for a paper size.

CALLED BY:	GLOBAL
PARAMETERS:	void (PaperSizeInfo *sizeInfo, word paperSizeNum,
		      PageType pageType)
RETURN:		*sizeInfo filled with the width and height (in points)
		of the paper size, plus the default page layout
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PaperSizeInfo	struct
	PSI_width		word
	PSI_height  		word
	PSI_defaultLayout  	PageLayout
PaperSizeInfo	ends

SPOOLGETPAPERSIZE	proc	far	sizeInfo:fptr.PaperSizeInfo,
					paperSizeNum:word,
					pageType:PageType
		uses	ds, si
		.enter
		mov	ax, ss:[paperSizeNum]
		mov	bp, ss:[pageType]
		call	SpoolGetPaperSize
		lds	si, ss:[sizeInfo]
		mov	ds:[si].PSI_width, cx
		mov	ds:[si].PSI_height, dx
		mov	ds:[si].PSI_defaultLayout, ax
		.leave
		ret
SPOOLGETPAPERSIZE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLCONVERTPAPERSIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the paper size number for a given width and height.

CALLED BY:	GLOBAL
PARAMETERS:	word (word width, word height, PageType pageType)
RETURN:		on success returns paper size number
		on failure returns -1
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLCONVERTPAPERSIZE	proc	far
		C_GetThreeWordArgs cx, dx, ax,  bx	; cx <- width
							; dx <- height
							; ax <- pageType
		push	bp
		mov_tr	bp, ax				; bp <- pageType
		call	SpoolConvertPaperSize
		pop	bp
		ret
SPOOLCONVERTPAPERSIZE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLGETPAPERSIZEORDER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current paper size order array

CALLED BY:	GLOBAL
PARAMETERS:	void (byte *orderBuf, byte *userDefBuf,
		      PaperSizeOrderInfo *numBuf)
RETURN:		*orderBuf filled with the current paper size order array,
		*userDefBuf filled with the user-defined paper size array,
		*numBuf holding the number of ordered sizes and the number
		of unused sizes
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PaperSizeOrderInfo	struct
	PSOI_numOrdered	word
	PSOI_numUnused	word
PaperSizeOrderInfo	ends

SPOOLGETPAPERSIZEORDER	proc	far	orderBuf:fptr.byte,
					userDefBuf:fptr.byte,
					numBuf:fptr.PaperSizeOrderInfo
		uses	ds, es, di, si
		.enter
		les	di, ss:[orderBuf]
		lds	si, ss:[userDefBuf]
		call	SpoolGetPaperSizeOrder
		les	di, ss:[numBuf]
		mov	es:[di].PSOI_numOrdered, cx
		mov	es:[di].PSOI_numUnused, dx
		.leave
		ret
SPOOLGETPAPERSIZEORDER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLSETPAPERSIZEORDER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a new paper size order to be displayed.

CALLED BY:	GLOBAL
PARAMETERS:	void (byte *orderArray, word numEntries, PageType pageType)
RETURN:		nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLSETPAPERSIZEORDER	proc	far	orderArray:fptr.byte,
					numEntries:word,
					pageType:PageType
		uses	ds, si
		.enter
		lds	si, ss:[orderArray]
		mov	cx, ss:[numEntries]
		mov	bp, ss:[pageType]
		call	SpoolSetPaperSizeOrder
		.leave
		ret
SPOOLSETPAPERSIZEORDER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLCREATEPAPERSIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new paper size and store it in the .INI file.

CALLED BY:	GLOBAL
PARAMETERS:	word (char *paperSizeString, word width, word height,
		      PageLayout layout, PageType pageType)
RETURN:		on success, returns the new paper size (between 128 and 255)
		on failure, returns 0
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLCREATEPAPERSIZE	proc	far	paperSizeString:fptr.char,
					pWidth:word,
					height:word,
					layout:PageLayout,
					pageType:PageType
		uses	es, di
		.enter
		les	di, ss:[paperSizeString]
		mov	cx, ss:[pWidth]
		mov	dx, ss:[height]
		mov	ax, ss:[layout]
		mov	bp, ss:[pageType]
		call	SpoolCreatePaperSize
		jnc	done
		clr	ax
done:
    	    	.leave
		ret
SPOOLCREATEPAPERSIZE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLDELETEPAPERSIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a paper size.

CALLED BY:	GLOBAL
PARAMETERS:	Boolean (word paperSizeNum, PageType pageType)
RETURN:		on success returns 0
		on failure returns non-zero
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLDELETEPAPERSIZE	proc	far
		C_GetTwoWordArgs ax, bx,  cx, dx	; ax <- paperSizeNum
							; bx <- pageType
		push	bp
		mov	bp, bx				; bp <- pageType
		call	SpoolDeletePaperSize
		mov	ax, TRUE			; pessimism
		jc	done
		clr	ax				; success
done:
		pop	bp
		ret
SPOOLDELETEPAPERSIZE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLGETNUMPRINTERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of printers currently installed.

CALLED BY:	GLOBAL
PARAMETERS:	word (PrinterDriverType driverType, byte localOnlyFlag)
RETURN:		number of printers
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLGETNUMPRINTERS	proc	far 	driverType:PrinterDriverType,
    	    	    	    	    	localOnlyFlag:byte
    	    	.enter
    	    	mov 	cl, ss:[driverType]
    	    	mov 	ch, ss:[localOnlyFlag]
		call	SpoolGetNumPrinters
    	    	.leave
		ret
SPOOLGETNUMPRINTERS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLGETPRINTERSTRING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a passed buffer with a printer's name.

CALLED BY:	GLOBAL
PARAMETERS:	Boolean (PrinterStringInfo *retInfo, word printerNum)
RETURN:		on success, returns 0 plus *retInfo filled with the
			desired name, the length of the name (excluding
			final null), and the driver type.
		on failure, returns non-zero
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrinterStringInfo	struct
SBCS <	PSI_stringBuf		char GEODE_MAX_DEVICE_NAME_LENGTH dup (?)>
DBCS <	PSI_stringBuf		wchar GEODE_MAX_DEVICE_NAME_LENGTH dup (?)>
	PSI_stringLength	word
	PSI_driverType		PrinterDriverType
PrinterStringInfo	ends


SPOOLGETPRINTERSTRING	proc	far	retInfo:fptr.PrinterStringInfo,
					printerNum:word
		uses	es, di
		.enter

	CheckHack <offset PSI_stringBuf eq 0>
		
		les	di, ss:[retInfo]	; es:di <- PSI_stringBuf
		mov	ax, ss:[printerNum]
		call	SpoolGetPrinterString
		mov	es:[di].PSI_stringLength, cx
		mov	es:[di].PSI_driverType, dl
		mov	ax, TRUE			; pessimism
		jc	done
		clr	ax				; success
done:
		.leave
		ret
SPOOLGETPRINTERSTRING	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLCREATEPRINTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new printer to the end of the printer list

CALLED BY:	GLOBAL
PARAMETERS:	word (char *printerName, PrinterDriverType driverType)
RETURN:		number of new printer
		or -1 if printer already exists
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLCREATEPRINTER	proc	far	printerName:fptr.char,
					driverType:PrinterDriverType
		uses	es, di
		.enter
		les	di, ss:[printerName]
		mov	cl, ss:[driverType]
		call	SpoolCreatePrinter
		jnc	done
		mov	ax, -1
done:
    	    	.leave
		ret
SPOOLCREATEPRINTER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLDELETEPRINTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a printer from the current printer list.

CALLED BY:	GLOBAL
PARAMETERS:	void (word printerNum)
RETURN:		nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLDELETEPRINTER	proc	far
		C_GetOneWordArg ax,  cx, dx	; ax <- printerNum
		call	SpoolDeletePrinter
		ret
SPOOLDELETEPRINTER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLSETDEFAULTPRINTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current default printer.

CALLED BY:	GLOBAL
PARAMETERS:	void (word printerNum)
RETURN:		nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLSETDEFAULTPRINTER	proc	far
		C_GetOneWordArg ax,  cx, dx	; ax <- printerNum
		call	SpoolSetDefaultPrinter
		ret
SPOOLSETDEFAULTPRINTER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLCREATESPOOLFILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and open a unique spool file in the SP_SPOOL
		standard directory.

CALLED BY:	GLOBAL
PARAMETERS:	FileHandle (char *fileNameBuf)
RETURN:		on success, returns handle of new file plus
			new file name stored in *fileNameBuf
		on failure, returns 0
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLCREATESPOOLFILE	proc	far	fileNameBuf:fptr.char

		uses	ds, si
		.enter
    	    	lds 	si, ss:[fileNameBuf]
		mov	dx, ds
		call SpoolCreateSpoolFile
		.leave
		ret
SPOOLCREATESPOOLFILE	endp

C_Spool ends

	SetDefaultConvention
