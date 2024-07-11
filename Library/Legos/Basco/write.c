/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Code saving
FILE:		write.c

AUTHOR:		Paul L. DuBois, Jan 10, 1995

ROUTINES:
	Name			Description
	----			-----------
    GLB BascoWriteResources	Writes out resource file containing complex
				data.

    GLB BascoWriteCode		Top-level routine to write out code

    INT WriteInitFile		Create a new output VM file

    INT WriteAddHeader		Add a header block to the file

    INT WriteAddComplex		Add a complex VM tree to resource file

    INT WriteAddPage		Add a page to the file

    INT WriteCloseFile		Finish off and close a code file

    EXT WriteCreateHeader	Create a header suitable for writing to a
				file

   ?INT Write_AddStructInfo	Write out structure creation information

    INT Write_AddSTable		Add a list of strings to a page

    INT Write_AddFuncTable	Append func table info to a header

    INT Write_AddGlobalVarTable	Write var table info to header

    EXT WriteCreatePage		Create a page of functions

    INT Write_AddFunc		Add a function to a mem block

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/10/95   	Initial version.

DESCRIPTION:
	Routines for writing pages to disk.
	Routines for creating code pages.

	$Id: write.c,v 1.1 98/10/13 21:44:01 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include "mystdapp.h"
#include <gstring.h>
#include <win.h>
#include <Legos/basrun.h>
#include "codeint.h"
#include "stable.h"
#include "vars.h"
#include "vtab.h"
#include "ftab.h"
#include "write.h"

extern word setDSToDgroup(void);
extern void restoreDS(word oldDS);

#define FormatIDFromManufacturerAndType(m,t) 	((((dword)(t)) << 16) | (m) )
#define ManufacturerFromFormatID(id) 		((word) (id))
#define TypeFromFormatID(id) 			((word) ((id) >> 16))

#ifdef NEED_SWAP
#define SwapWord(x) (((x&0x00ff)<<8)|((x&0xff00)>>8))
#define SwapDword(x) ((unsigned long)(SwapWord((x&0x0000ffff))<<16)|(unsigned long)SwapWord((x&0xffff0000)>>16))
#else
#define SwapWord(x) x
#define SwapDword(x) x
#endif


/*********************************************************************
 *			BascoWriteResources
 *********************************************************************
 * SYNOPSIS:	Writes out resource file containing complex data.
 *	Should usually be used in conjunction with BascoWriteCode;
 *	pass the same name given to BascoWriteCode.  The 3 letter
 *	extension will be changed to .RSC.
 *
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	For now, just use the same map block as is used for code files.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 7/20/95	Initial version
 * 
 *********************************************************************/
Boolean
BascoWriteResources(TCHAR* name, optr complexArray, RunHeapInfo* rhi,
		    Boolean liberty)
{
    TCHAR	path[PATH_LENGTH_ZT];
    TCHAR*	cp;
    word	oldDS;
    VMFileHandle	vmfh;

    oldDS = setDSToDgroup();

    /* name should match '*.BC\0' but we won't be strict about the BC part
     * replace trailer with .RSC, if there's room.
     */
    strcpy(path, name);
    cp = strrchr(path, C_PERIOD);

    /* If no period on the end, just tack on .RSC */
    if (cp == NULL)
    {
	strcat(path, _TEXT(".RSC"));
	goto goodName;
    } 
    
    if ( strlen(cp) > 4	/* longer than ".BC" or ".BAS" */
	|| (cp-path)+3 >= PATH_LENGTH_ZT)
    {
	goto errorDone;
    }
    strcpy(cp+1, _TEXT("RSC"));
goodName:    

    if (liberty) {
	word	sig;

	sig = SwapWord(RSL_FILE_SIGNATURE);
	path[strlen(path)-1] = C_CAP_L;
	vmfh = FileCreate(path, FCF_NATIVE | FILE_CREATE_TRUNCATE | 
			  FILE_ACCESS_W | FILE_DENY_RW, 0);
	/* write in the signature word */
	FileWrite(vmfh, (byte *)&sig, sizeof(sig), 0);
    } else {
	vmfh = WriteInitFile(path);
    }
    if (vmfh == NullHandle) goto errorDone;

    if (complexArray != NullOptr)
    {
	word	    	i, count, j, passes;
	dword	    	pos;
	RunHeapToken	rht;

	MemLock(OptrToHandle(complexArray));

#if ERROR_CHECK
	;{
	    ChunkArrayHeader *cah;
	    cah = LMemDeref(complexArray);
	    EC_ERROR_IF(cah->CAH_elementSize != sizeof(RunHeapToken),
			BE_FAILED_ASSERTION);
	}
#endif

	count = ChunkArrayGetCount(complexArray);
	passes = 1;
	if (liberty)
	{
	    /* write in the signature word */
	    int	    c;

	    c = SwapWord(count);
	    FileWrite(vmfh, (byte *)&c, sizeof(c), 0);
	    pos = FilePos(vmfh, 0L, FILE_POS_RELATIVE);
	    EC_ERROR_IF(sizeof(RSLHeader) != pos, -1);
	    /* allow one extra value for the EOF so we know how large
	     * the last piece of data is
	     */
	    pos += (count + 1) * sizeof(dword);

	    /* in the liberty case, we do two passes, one to create the
	     * map, and one to write out the resources, the GEOS case
	     * is handled automatically by the VM file support
	     */
	    passes++;
	}
	for (j = 0; j < passes; j++)
	{
	    for (i = 0; i < count; i++)
	    {
		ChunkArrayGetElement(complexArray, i, &rht);
		if (liberty) {
		    WriteAddComplexForLiberty(vmfh, rht, rhi, j ? NULL : &pos);
		} else {
		    WriteAddComplex(vmfh, rht, rhi);
		}
	    }

	    /* write out one extra value for the EOF */
	    if (liberty && !j) 
	    {
		dword	position;
		
		position = SwapDword(pos);
		FileWrite(vmfh, &position, sizeof(dword), 0);
	    }
	}
	MemUnlock(OptrToHandle(complexArray));
    }

    if (liberty) {
	FileClose(vmfh, FILE_NO_ERRORS);
    } else {
	VMClose(vmfh, FILE_NO_ERRORS);
    }
    restoreDS(oldDS);
    return TRUE;

 errorDone:
    restoreDS(oldDS);
    return FALSE;
}

/*********************************************************************
 *			BascoWriteCode
 *********************************************************************
 * SYNOPSIS:	Write out code in one of various formats
 * CALLED BY:	GLOBAL
 * RETURN:	TRUE if successful
 * SIDE EFFECTS:
 * STRATEGY:
 *	Uses task->liberty to determine format
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	10/ 5/95	Initial version
 * 
 *********************************************************************/
Boolean
BascoWriteCode(TCHAR* name, MemHandle taskHan)
{
    TaskPtr	task;
    Boolean	retval;
    word	oldDS;
    word	i, count;

    oldDS = setDSToDgroup();
    task = (TaskPtr) MemLock(taskHan);

    /* Should this just do a BascoCompileCode?
     * At least this will catch errors.
     */
    count = FTabGetCount(task->funcTable);
    for (i=0; i<count; i++)
    {
	FTabEntry*	ftab;
	CompStatus	status;
	ftab = FTabLock(task->funcTable, i);
	status = ftab->compStatus;
	FTabUnlock(ftab);
	if (status < CS_CODE_GENERATED) return FALSE;
    }

    if (task->liberty) {
	retval = Write_WriteBCL(name, taskHan);
    } else {
	retval = Write_WriteBC(name, taskHan);
    }

    MemUnlock(taskHan);
    restoreDS(oldDS);
    return retval;
}


/*********************************************************************
 *			Write_WriteBC
 *********************************************************************
 * SYNOPSIS:	Write out code in GEOS .bc format
 * CALLED BY:	INTERNAL
 * RETURN:	TRUE if successful
 * SIDE EFFECTS:
 * STRATEGY:
 *	Uses task->liberty to determine how to write out file.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/17/95	Initial version			     
 * 
 *********************************************************************/
Boolean
Write_WriteBC(TCHAR* name, MemHandle taskHan)
{
    VMFileHandle	vmfh;
    TaskPtr		task;
    MemHandle	header, page;
    GeodeToken	token;
    int	    	start = 0, numFuncs;
    /* Compiler barfed on direct initialization. Soo..... */


    memcpy(token.GT_chars, "LAUN", 4);
    token.GT_manufID = MANUFACTURER_ID_GEOWORKS;

    vmfh = WriteInitFile(name);
    if (vmfh == NullHandle) {
	return FALSE;
    }


    task = (TaskPtr) MemLock(taskHan);
    header = WriteCreateHeader(task, NULL, MAX_CODE_PAGE_SIZE);
    WriteAddHeader(vmfh, header);

    /* write out the functions as reasonable sized pages */
    numFuncs = FTabGetCount(task->funcTable);
    while (start < numFuncs)
    {
	page = WriteCreatePage(task, NULL, &start, MAX_CODE_PAGE_SIZE);
	if (page == NullHandle) {
	    break;
	}
	WriteAddPage(vmfh, page, APPEND_PAGE);
    }

    MemUnlock(taskHan);

    WriteCloseFile(vmfh);
    
    FileSetPathExtAttributes(name, FEA_CREATOR, &token, 
			     sizeof(GeodeToken));
    
    return TRUE;
}


/*********************************************************************
 *			Write_WriteBCL
 *********************************************************************
 * SYNOPSIS:	Write out file in liberty .bcl format
 * CALLED BY:	INTERNAL
 * RETURN:      TRUE if successful
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 7/19/95	Initial version
 * 
 *********************************************************************/
Boolean
Write_WriteBCL(TCHAR* name, MemHandle taskHan)
{
    TaskPtr	task;
    MemHandle	header;
    FileHandle	fhan;
    int		headerSize;
    int		numPages=0;
    byte*	bytePtr;
    int	    	start = 0, numFuncs, i;
    MemHandle	pages[64];
    word       	sizes[64];
    dword	pos;

    fhan = FileCreate(name,
		      FILE_CREATE_TRUNCATE | FCF_NATIVE|
		      FILE_ACCESS_W | FILE_DENY_RW, 0);

    if (fhan == NullHandle) 
	return FALSE;

    task = (TaskPtr) MemLock(taskHan);
    header = WriteCreateHeader(task, &headerSize, MAX_CODE_PAGE_SIZE);

    /* write out the functions as reasonable sized pages */
    numFuncs = FTabGetCount(task->funcTable);
    while (start < numFuncs)
    {
	EC_ERROR_IF(numPages >= 64, -1);
	sizes[numPages] = 0;
	pages[numPages] = WriteCreatePage(task, (int *)&sizes[numPages], 
					  &start, MAX_CODE_PAGE_SIZE);
	if (pages[numPages] == NullHandle) {
	    break;
	}
	numPages++;
    }
    MemUnlock(taskHan);

    /* first write out the number of pages */
    FileWrite(fhan, (byte*)&numPages, sizeof(word), 0);

    /* now write out all file positions */
    /* the first page starts after the table of dwords and after the header */

    pos = sizeof(word) + numPages * sizeof(dword) + headerSize;
    for (i = 0; i < numPages; i++)
    {
	FileWrite(fhan, (byte*)&pos, sizeof(dword), 0);
	pos += sizes[i];
    }

    if (header == NullHandle) return FALSE;
    bytePtr = MemLock(header);
    FileWrite(fhan, bytePtr, headerSize,0);
    MemFree(header);

    for (i = 0; i < numPages; i++)
    {
	bytePtr = MemLock(pages[i]);
	FileWrite(fhan, bytePtr, sizes[i], 0);
	MemFree(pages[i]);
    }
    FileClose(fhan, 0);

    return TRUE;
}

/*********************************************************************
 *			WriteInitFile
 *********************************************************************
 * SYNOPSIS:	Create a new output VM file
 * CALLED BY:	INTERNAL, BascoWriteCode
 * RETURN:	VMFileHandle of new file
 * SIDE EFFECTS:
 * STRATEGY:
 *	Populate the VM file with a map block
 *	Don't confuse the VM file's header (which is really just
 *	a repository for VMBlockHandles) and the vm block
 *	CFH_header, which contains initial info for the runtime.
 *
 * REVISION HISTORY:
 *
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/17/95	Initial version			     
 * 
 *********************************************************************/
VMFileHandle
WriteInitFile(TCHAR *fileName)
{
    VMFileHandle	vmfh;
    VMBlockHandle	headerVH;
    MemHandle		headerH;
    CodeFileHeader*	header;

    ChunkHandle	pageArray;
    ChunkHandle dataArray;

    /* Create a new VM file
     */
    FileDelete(fileName);		/* temp hack */
    vmfh = VMOpen(fileName, VMAF_FORCE_READ_WRITE, VMO_CREATE_TRUNCATE, 0);
    if (vmfh == NullHandle) return NullHandle;
    VMSetAttributes(vmfh, VMA_SINGLE_THREAD_ACCESS, 0);

    /* Create, populate, initialize the header block
     */
    headerVH = VMAllocLMem(vmfh, LMEM_TYPE_GENERAL, sizeof(CodeFileHeader));
    VMSetMapBlock(vmfh, headerVH);
    header = VMLock(vmfh, headerVH, &headerH);
    pageArray = ChunkArrayCreate(headerH, sizeof(word), 0, 0);
    dataArray = ChunkArrayCreate(headerH, sizeof(ComplexDataElt), 0, 0);
    
    header = MemDeref(headerH);

    header->CFH_revision = CODE_FILE_REVISION;
    header->CFH_header = NullHandle;
    header->CFH_pageArray = pageArray;
    header->CFH_complexDataArray = dataArray;

    VMDirty(headerH);
    VMUnlock(headerH);

    return vmfh;
}

/*********************************************************************
 *			WriteAddHeader
 *********************************************************************
 * SYNOPSIS:	Add a header block to the file
 * CALLED BY:	INTERNAL, BascoWriteCode
 * RETURN:
 * SIDE EFFECTS:
 *	VMAttach is called on the mem block, so don't try and
 *	MemFree it.  MemUnlock if necessary, though.
 *
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/17/95	Initial version			     
 * 
 *********************************************************************/
void
WriteAddHeader(VMFileHandle vmfh, MemHandle codeHeaderH)
{
    MemHandle		headerH;
    CodeFileHeader*	header;

    header = VMLock(vmfh, VMGetMapBlock(vmfh), &headerH);

    /* CFH_header is initialized to NullHandle, so VMAttach
     * does the right thing...
     */
    header->CFH_header = VMAttach(vmfh, header->CFH_header, codeHeaderH);

    VMDirty(headerH);
    VMUnlock(headerH);
    return;
}

/*********************************************************************
 *	    	    ConvertComplexDataToGString
 *********************************************************************
 * SYNOPSIS:	return a gstate:gstring 
 * CALLED BY:	WriteAddComplexForLiberty
 * PASS:
 * RETURN:  	handle to GString as returned by GrLoadGString
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/ 7/95	Initial version
 * 
 *********************************************************************/
GStateHandle InputComplexData(RunHeapInfo *rhi, RunHeapToken data,
			      dword      *format,
			      VMFileHandle  *vmf)
{
    LegosComplex* lc;
    VMFileHandle  vmfh;
    VMBlockHandle vmbh;
    GStateHandle    retval = NullHandle;

    /* check for Null data before going ahead */
    if (data != NULL_TOKEN)
    {
	RunHeapLock(rhi, data, (void**)(&lc));
	
	*vmf = vmfh = lc->LC_vmfh;
	vmbh = OptrToHandle(lc->LC_chain);
	*format = lc->LC_format;

	RunHeapUnlock(rhi, data);

	if (*format ==
	    FormatIDFromManufacturerAndType(MANUFACTURER_ID_GEOWORKS,
					    CIF_GRAPHICS_STRING))
	{
	    retval  = GrLoadGString(vmfh, GST_VMEM, vmbh);
	}
    }
    return retval;
}

/*********************************************************************
 *			WriteAddComplexForLiberty
 *********************************************************************
 * SYNOPSIS:	Add a complex VM tree to resource file
 * CALLED BY:	INTERNAL
 * RETURN:	Nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 2/14/95	Initial version			     
 * 
 *********************************************************************/
void
WriteAddComplexForLiberty(VMFileHandle resFile, RunHeapToken rht, 
			  RunHeapInfo	*rhi,
			  dword	    	*position)
{
    MemHandle	    	data;
    dword		format;
    VMFileHandle    	vmfh;
    MemHandle		tbufHan;
    byte		*tbuf;
    /* first get data into memory */
    data = InputComplexData(rhi, rht, &format, &vmfh);

    if (data == NullHandle) {
	return;
    }
    if (format ==
	FormatIDFromManufacturerAndType(MANUFACTURER_ID_GEOWORKS,
					CIF_GRAPHICS_STRING))
    {
	Rectangle    	rect;
	GStateHandle	gstate;
	VMBlockHandle	vmbh;
	word	    	last, count, i;
	GSRetType   	retType;
	int 	    	width, height;
	byte	    	bmt;
	byte		adjustSize;
	/* totalSize starts out as just the header info for a bitmap
	 * plus the RSL_BITMAP byte
	 */
	int 	    	totalSize = sizeof(RSLBitmapHeader)+1;

	GrGetGStringBounds(data, NullHandle, 0, &rect);
	/* subtract two to get rid of border */
	width = rect.R_right - rect.R_left + 1 - 2;
	height = rect.R_bottom - rect.R_top + 1 - 2;
	bmt = BMF_MONO;
	vmbh = GrCreateBitmap(BMF_MONO, width+2, height+2, vmfh, 
			      NullOptr, &gstate);
	
	if (position == NULL)
	{
	    byte    type;

	    /* write out type info and some bitmap info */
	    type = RSLD_BITMAP;
	    FileWrite(resFile, &type, sizeof(bmt), 0);
	    FileWrite(resFile, &bmt, sizeof(bmt), 0);
	    bmt = 0;	/* unused byte for now */
	    FileWrite(resFile, &bmt, sizeof(bmt), 0);
	    width = SwapWord(width);
	    height = SwapWord(height);
	    FileWrite(resFile, &width, sizeof(width), 0);
	    FileWrite(resFile, &height, sizeof(height), 0);

	    /* this is used by the code below that gets rid of the border */
	    tbufHan = MemAlloc(1024, HF_SWAPABLE | HF_SHARABLE, HAF_LOCK);
	    tbuf = (byte *)MemDeref(tbufHan);
	}
	retType = GrDrawGString(gstate, data, -rect.R_left, -rect.R_top, 0, 
				&last);
	retType = retType;	/* quiet warning */
	/* calculate total size */
	count = HugeArrayGetCount(vmfh, vmbh);

	/* see if the change in width brings us past a byte boundary */
	adjustSize = 0;
	if ((width > 5) && ((unsigned int)(((width+2) % 8)-1) <= 1)) {
	    adjustSize = 1;
	}

	for (i = 1; i < count - 1; i++)
	{
	    void        	*bptr;
	    word        	esize;
	    char                *eptr;
	    int                 carry;

	    HugeArrayLock(vmfh, vmbh, i, (void**)&bptr, &esize);
	    esize -= adjustSize;

	    if (position == NULL) {
		/* deal with getting rid of white border from data */
		memcpy(tbuf, bptr, esize);
		carry = 0;
		for (eptr = (char*)tbuf+(esize-1) ; TRUE; eptr--)
		{
		    int c;

		    c = carry;
		    carry = (*(char *)eptr) & 0x80;
		    *(char *)eptr <<= 1;
		    if (c) {
			(*(char *)eptr) |= 0x01;
		    }
		    if (eptr == (char *)tbuf) {
			break;
		    }
		}
		FileWrite(resFile, tbuf, esize, 0);
	    } else {
		totalSize += esize;
	    }
	    HugeArrayUnlock(bptr);
	}
	HugeArrayDestroy(vmfh, vmbh);
	GrDestroyGString(data, NullHandle, GSKT_LEAVE_DATA);
	WinClose(gstate);
	if (position == NULL) {
	    MemFree(tbufHan);
	} 
	else
	{
	    dword   p;

	    p = SwapDword(*position);
	    FileWrite(resFile, &p, sizeof(dword), 0);
	    *position += totalSize;
	}
    }
    return;
}

/*********************************************************************
 *			WriteAddComplex
 *********************************************************************
 * SYNOPSIS:	Add a complex VM tree to resource file
 * CALLED BY:	INTERNAL
 * RETURN:	Nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 2/14/95	Initial version			     
 * 
 *********************************************************************/
void
WriteAddComplex(VMFileHandle resFile, RunHeapToken rht, RunHeapInfo* rhi)
{
    MemHandle		cfhH;
    CodeFileHeader*	cfh;

    ComplexDataElt*	elt;
    VMChain		destChain;

    dword		format;

    ;{
	LegosComplex*	lc;

	RunHeapLock(rhi, rht, (void**)(&lc));
	destChain = VMCopyVMChain_FIX(lc->LC_vmfh, lc->LC_chain, resFile);
	format = lc->LC_format;
	RunHeapUnlock(rhi, rht);
    }

    cfh = VMLock(resFile, VMGetMapBlock(resFile), &cfhH);

    elt = ChunkArrayAppendHandles(cfhH, cfh->CFH_complexDataArray, 0);
    elt->CDE_format = format;
    elt->CDE_chain = destChain;

    VMDirty(cfhH);
    VMUnlock(cfhH);
    return;
}



/*********************************************************************
 *			WriteAddPage
 *********************************************************************
 * SYNOPSIS:	Add a page to the file	
 * CALLED BY:	INTERNAL, BascoWriteCode
 * RETURN:	Page number
 * SIDE EFFECTS:
 * STRATEGY:
 *	See MemHandle caveats in WriteAddHeader
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/17/95	Initial version			     
 * 
 *********************************************************************/
word
WriteAddPage(VMFileHandle vmfh, MemHandle page, word pageNum)
{
    MemHandle		headerH;
    CodeFileHeader*	header;
    optr		pageArray;
    word*		elt;	/* chunk array element */

    header = VMLock(vmfh, VMGetMapBlock(vmfh), &headerH);

    pageArray = ConstructOptr(headerH, header->CFH_pageArray);

    if (pageNum == APPEND_PAGE)
    {
	pageNum = ChunkArrayGetCount(pageArray);
	elt = ChunkArrayAppend(pageArray, 0);
	*elt = NullHandle;	/* init elt for VMAttach */
    } else {
	/* If passing a page number, must pass an existing elt number
	 */
	EC_ERROR_IF(pageNum >= ChunkArrayGetCount(pageArray),
		    BE_REPLACING_NONEXISTENT_PAGE);
	elt = ChunkArrayElementToPtr(pageArray, pageNum, NULL);
    }

    /* *header possibly invalid here; memderef if you need it */
    
    *elt = VMAttach(vmfh, *elt, page);

    VMDirty(headerH);
    VMUnlock(headerH);
    return pageNum;
}

/*********************************************************************
 *			WriteCloseFile
 *********************************************************************
 * SYNOPSIS:	Finish off and close a code file
 * CALLED BY:	INTERNAL, BascoWriteCode
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *	Might want to VMUpdate and check that everything is OK
 *	before closing.
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/17/95	Initial version			     
 * 
 *********************************************************************/
void
WriteCloseFile(VMFileHandle vmfh)
{
    VMClose(vmfh, FILE_NO_ERRORS);
    return;
}

/*********************************************************************
 *			WriteCreateHeader
 *********************************************************************
 * SYNOPSIS:	Create a header suitable for writing to a file
 * CALLED BY:	EXTERNAL
 * RETURN:	MemHandle of header block
 * SIDE EFFECTS:allocates memory
 * STRATEGY:
 *
 *	This routine is meant to be called after all code generation
 *	is complete.  It puts all module meta-information in a block
 *	of memory and returns that.  Currently, this includes info
 *	on how to recreate:
 *
 *	  module variable table (size, # vars, types)
 *	  run-time function table (size)
 *
 *	Later, this SHOULD include the string constant table.  It can
 *	also optionally include the stringIdent table and stringFunc
 *	table (although the format of the header should be flexible
 *	enough to allow for the absence of these sections)
 *
 *	The first function (assumed to be duplo_start) is also tacked
 *	on, because it's easier to not demand-load it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/ 3/95	Initial version			     
 * 
 *********************************************************************/
MemHandle
WriteCreateHeader(TaskPtr task, int *size, word pageSize)
{
    MemHandle	headerHan;
    byte*	header;
    word	headerSize;

    /* first two byte are revision info */
    headerSize = 2;
    headerHan = MemAlloc(headerSize, HF_SWAPABLE | HF_SHARABLE, HAF_LOCK);
    header = MemDeref(headerHan);
    header[0] = BC_MAJOR_REV;
    header[1] = BC_MINOR_REV;

    /* Next: some tables */
    Write_AddGlobalVarTable(headerHan, &headerSize, task);
    Write_AddFuncTable(headerHan, &headerSize, task, pageSize);

    /* These tables have PageMarkers */
    Write_AddStructInfo(headerHan, &headerSize, task);
#define ADD_STABLE(const, table, bool) \
    Write_AddSTable(headerHan, &headerSize, const, table, task, bool)
    ADD_STABLE(PM_STRING_CONST, task->stringConstTable, FALSE);
    ADD_STABLE(PM_EXPORT, task->exportTable, task->liberty);
    ADD_STABLE(PM_STRING_FUNC, task->stringFuncTable, task->liberty);

    /* End-of-header marker
     */
    if (!MemReAlloc(headerHan, headerSize+sizeof(PageMarker), 0))
	goto failFree;

    header = MemDeref(headerHan);
    CAST_ARR(PageMarker, header[headerSize]) = PM_HEADER_END;
    if (BIG_ENDIAN) {
	swapWord((word*)&header[headerSize]);
    }
    headerSize += sizeof(PageMarker);

    /* Additional things which are useful to have in the 1st page
     */

    /* mike asked for all functions on page 0, no functions in header
     * dubois 4/2/96
    Write_AddFunc(headerHan, &headerSize, task, 0);
     */
    
    if (!MemReAlloc(headerHan, headerSize+2, 0)) goto failFree;

    header = MemDeref(headerHan);
    CAST_ARR(PageMarker, header[headerSize]) = PM_END;
    if (BIG_ENDIAN) {
	swapWord((word*)&header[headerSize]);
    }

    MemUnlock(headerHan);
    headerSize +=2;

    if (size != NULL) {
	*size = headerSize;
    }

    return headerHan;

 failFree:
    MemFree(headerHan);
    return NullHandle;
}

/*********************************************************************
 *			Write_AddStructInfo
 *********************************************************************
 * SYNOPSIS:	Write out structure creation information
 * CALLED BY:	WriteCreateHeader
 * RETURN:	
 * SIDE EFFECTS:
 * STRATEGY:
 *	Writes out:
 *
 *	# structs		(word)
 *	<numStructs> times:
 *	  # fields		(word)
 *	  size of struct	(word)
 *	  <numFields> times:
 *	    type		(byte)
 *	    offset		(word)  -- removed mchen 5/17/96
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 6/20/95	Initial version
 * 
 *********************************************************************/
void
Write_AddStructInfo(MemHandle pageHan, word* size, TaskPtr task)
{
    byte*	page;
    word	i, j, nStructs;

    nStructs = StringTableGetCount(STRUCT_TABLE);
    PAGE_APPEND_WORD(PM_STRUCT_INFO);
    PAGE_APPEND_WORD(nStructs);

    for (i=0; i<nStructs; i++)
    {
	word	vtab, nVars;

	vtab = StringTableGetData(STRUCT_TABLE, i);
	nVars = VTGetCount(VTAB_HEAP, vtab);

	PAGE_APPEND_WORD(nVars);
	PAGE_APPEND_WORD(VTGetSize(VTAB_HEAP, vtab));

	for (j=0; j<nVars; j++)
	{
	    VTabEntry	vte;
	    BCLVTabEntry bvte;

	    VTLookupIndex(VTAB_HEAP, vtab, j, &vte);
	    bvte.type = vte.VTE_type;
/*	    bvte.offset = vte.VTE_offset; */
	    bvte.structType =
		vte.VTE_type == TYPE_STRUCT ? vte.VTE_extraInfo : 0;
	    PAGE_APPEND_THING(bvte);
	}
    }
    return;
}


#ifndef DO_DBCS
/*
 * This shouldn't be needed in DBCS
 */

/*********************************************************************
 *			memcpyPadded
 *********************************************************************
 * SYNOPSIS:	Copies a sbcs string to a buffer as a dbcs string.
 * CALLED BY:	Write_STableAdd
 * Pass:	char *	page		; destination buffer
 *		char *  source		; source string, sbcs
 *		int 	stringSize	; size of DBCS string
 * RETURN:	nothing
 * SIDE EFFECTS:	none
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	RON	12/12/95	Initial version
 * 
 *********************************************************************/
void
memcpyPadded(char *page, char *source, int stringSize)
{
    /*
     * This string size should be even as it is a dbcs string.
     */
    EC_ERROR_IF(stringSize != (stringSize >> 1) + (stringSize >> 1),
		BE_FAILED_ASSERTION);
    while (stringSize)
    {
	*page++ = *source++;
	*page++ = '\0';
	stringSize -=2;	/* dbcs size is passed in */
    }
    
}
#endif


/*********************************************************************
 *			Write_AddSTable
 *********************************************************************
 * SYNOPSIS:	Add a list of strings to a page
 * CALLED BY:	INTERNAL
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 *	This isn't the most efficient way to go about things (should
 *	really muck with the stable's hugearray and snarf from there)
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 2/ 1/95	Initial version			     
 * 
 *********************************************************************/
void
Write_AddSTable(MemHandle pageHan, word* size, PageMarker type, optr stable,
		TaskPtr task, Boolean addIndex)
{
    StringHeader *sh;
    byte*	page;
    word	numStrings, i;

    EC_ERROR_IF((type != PM_STRING_FUNC) &&
		(type != PM_STRING_CONST) &&
		(type != PM_EXPORT),
		BE_INVALID_PAGE_MARKER);

    /* word-align
     */
    if (*size & 1) {
	MemReAlloc(pageHan, *size+3, HAF_NO_ERR);
	page = MemDeref(pageHan);
	CAST_ARR(PageMarker, page[*size]) = PM_PAD_BYTE;
	page[*size+2] = 0xcc;
	*size += 3;
    }

    /* Tack on a StringHeader
     */
    MemReAlloc(pageHan, *size+sizeof(StringHeader), HAF_NO_ERR);
    page = MemDeref(pageHan);
    sh = (StringHeader*)(&page[*size]);
    *size += sizeof(StringHeader);

    sh->SH_marker = type;
    numStrings = StringTableGetCount(stable);
    sh->SH_numStrings = numStrings;
    
    if (BIG_ENDIAN) {
	swapWord((word*)&(sh->SH_marker));
	swapWord((word*)&(sh->SH_numStrings));
    }

    for (i=0; i<numStrings; i++)
    {
	/* Expand the page and copy the string into the new space.
	 * Since we know the size of the string, we get to use memcpy
	 * instead of strcpy... oh boy.
	 */
	TCHAR	*cp;
	word	stringSize;

	(void) StringTableLockNew(stable, i, &cp, &stringSize);

	EC_ERROR_IF(stringSize != (strlen(cp)+1)*sizeof(TCHAR), 
		    BE_FAILED_ASSERTION);
#ifndef DO_DBCS
	/*
	 * if sbcs and compiling for liberty, make dbcs strings;
	 */
	if (task->liberty)
	{
	    stringSize <<= 1;	/* double the size */
	}
#endif

	/* Append a number to each string for .bcl
	 * later .bc files might do this too
	 */
	if (addIndex) {
	    MemReAlloc(pageHan, *size+stringSize+2, HAF_NO_ERR);
	} else {
	    MemReAlloc(pageHan, *size+stringSize, HAF_NO_ERR);
	}

	page = ((byte*)MemDeref(pageHan)) + *size;
#ifndef DO_DBCS
	/*
	 * If sbcs and compiling for liberty write out DBCS string
	 * Else, write out normal string.
	 */
	if (task->liberty)
	{
	    memcpyPadded((char *)page, cp, stringSize);
	} else 
	{
	    (void) memcpy(page, cp, stringSize);
	}
	
#else
	/*
	 * IN dbcs, the string alread is DBCS
	 */
	(void) memcpy(page, cp, stringSize);
#endif
	*size += stringSize;
	
	if (addIndex) {
	    CAST_ARR(word, page[stringSize]) = i;
	    *size += 2;
	}

	StringTableUnlock(cp);
    }
}


/*********************************************************************
 *			Write_AddFuncTable
 *********************************************************************
 * SYNOPSIS:	Append func table info to a header
 * CALLED BY:	INTERNAL WriteCreateHeader
 * RETURN:	nothing
 * SIDE EFFECTS:may re-alloc the header.  If so, headerSize will
 *		be adjusted accordingly.
 * STRATEGY:
 *	headerHan is assumed to be LOCKED.
 *	Func table looks like:
 *
 *	number of functions		word
 *	page number for func 0		word
 *	page number for func 1		word
 *	 [...]
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/10/95	Initial version			     
 * 
 *********************************************************************/
void
Write_AddFuncTable(MemHandle headerHan, word* headerSize, TaskPtr task,
		   word	pageSize)
{
    byte*	header;
    word	nFuncs, hc, i;
    word    	segment=0, totalSize=0;
/*
    nFuncs = HugeArrayGetCount(task->vmHandle, task->funcTable);
    
    MemReAlloc(headerHan, *headerSize+2, HAF_NO_ERR);
    CAST_ARR(word, header[*headerSize]) = nFuncs;
    *headerSize += 2;
    return;
*/    
    nFuncs = FTabGetCount(task->funcTable);

    MemReAlloc(headerHan, *headerSize+(nFuncs+1)*sizeof(word), HAF_NO_ERR);
    header = MemDeref(headerHan);

    hc = *headerSize;
    CAST_ARR(word, header[hc]) = nFuncs;
    if (BIG_ENDIAN) {
	swapWord((word*)(&header[hc]));
    }
 
    hc += 2;
    for (i=0; i<nFuncs; i++)
    {
	word	segSize;
	void	*segPtr;
	int 	j;
	FTabEntry   *ftab;

	CAST_ARR(word, header[hc]) = segment;
	hc += 2;

	/* keep track of the size of the current segment, if we go over
	 * the pageSize, then increment the segment value and reset the
	 * size, this way the segment values sync up with where the functions
	 * will actually go
	 */
	ftab = FTabLock(task->funcTable, i);
	for (j = ftab->startSeg; j < ftab->startSeg + ftab->size; j++)
	{
	    (void)HugeArrayLock(task->vmHandle, task->codeBlock, j,
				(void**)&segPtr, &segSize);
	    totalSize += segSize;
	    HugeArrayUnlock(segPtr);
	}

	/* each function will also have a FuncHeader and a word for
	 * the size
	 */
	totalSize += sizeof(FuncHeader) + sizeof(word);
	FTabUnlock(ftab);
	if (totalSize > pageSize) {
	    segment++;
	    totalSize = 0;
	}
    }
    *headerSize += sizeof(word) * (nFuncs+1);
    return;
}

/*********************************************************************
 *			Write_AddGlobalVarTable
 *********************************************************************
 * SYNOPSIS:	Write var table info to header
 * CALLED BY:	INTERNAL WriteCreateHeader
 * RETURN:	nothing
 * SIDE EFFECTS:will re-alloc the header, and mung headerSize appropriately.
 *
 * STRATEGY:
 *	headerHan is assumed to be LOCKED.
 *
 *	The var table goes at the beginning of the header.  Looks like:
 *
 *	size of runtime table		word
 *	# of following HVTabEntries	word
 *	
 *	
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/10/95	Initial version			     
 * 
 *********************************************************************/
void
Write_AddGlobalVarTable(MemHandle headerHan, word* headerSize, TaskPtr task)
{
    byte*	header;
    word	varTableSize, numVars, i;
    word	start, hc;		/* a cursor into header */

    numVars = VTGetCount(task->vtabHeap, GLOBAL_VTAB);
    start = hc = *headerSize;
    *headerSize += 2 * sizeof(word) + numVars * sizeof(HVTabEntry);

    MemReAlloc(headerHan, *headerSize, HAF_NO_ERR);
    header = MemDeref(headerHan);
    
    hc += 2;			/* fill in total size later */
    CAST_ARR(word, header[hc]) = numVars;
    if (BIG_ENDIAN) {
	swapWord((word*)&header[hc]);
    }
    hc += 2;

    /* 2 bytes for protocol, word size, word numVars */
    EC_ERROR_IF(hc != 6, BE_FAILED_ASSERTION);
    for (i = 0, varTableSize = 0;
	 i < numVars;
	 i++)
    {
	HVTabEntry*	hvte;
	VTabEntry	vte;
	word		entrySize;

	hvte = (HVTabEntry*) (&header[hc]);

	VTLookupIndex(task->vtabHeap, GLOBAL_VTAB, i, &vte);

	/* hvte->HVTE_type		= vte.VTE_type;*/
	if (vte.VTE_type & TYPE_ARRAY_FLAG)
	{
	    hvte->HVTE_type = TYPE_ARRAY;
	} else {
	    hvte->HVTE_type = vte.VTE_type;
	}
	hvte->HVTE_offset	= vte.VTE_offset;
	if (BIG_ENDIAN) {
	    swapWord((word*)&(hvte->HVTE_offset));
	}
	hc += sizeof(HVTabEntry);

	/* Right now all runtime variable storage entries are 5 bytes:
	 * 1 type, 4 data.  Later this will probably change, in which
	 * case feel free to nuke the EC.
	 */
	entrySize = vte.VTE_size;
	EC_ERROR_IF(entrySize != 5, BE_FAILED_ASSERTION);
	varTableSize += entrySize;
    }

    /* Should come right after protocol? */
    EC_ERROR_IF(start != 2, BE_FAILED_ASSERTION);
    CAST_ARR(word, header[start]) = varTableSize;
    if (BIG_ENDIAN) {
	swapWord((word*)&header[0]);
    }
}

/*********************************************************************
 *			WriteCreatePage
 *********************************************************************
 * SYNOPSIS:	Create a page of functions
 * CALLED BY:	EXTERNAL
 * RETURN:	MemHandle
 * SIDE EFFECTS:Allocate memory
 * STRATEGY:
 *	Puts all functions into a memblock (including first)
 *
 *  OLD COMMENT: (I'm not sure this is still valid?)
 *	The first is assumed to be duplo_start, which we cannot
 *	demand-load at this time, since it isn't called as a result
 *	of an OP_MODULE_CALL in RunMainLoop (it's called by hand)
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/ 9/95	Initial version			     
 * 
 *********************************************************************/
MemHandle
WriteCreatePage(TaskPtr task, int *passSize, int *start, word maxSize)
{
    MemHandle	pageHan;
    word	size, i, numFuncs;
    byte*	page;

    /* Must allocate something other than 0... 4 is arbitrary */
    pageHan = MemAlloc(4, HF_SWAPABLE, HAF_NO_ERR);
    (void) MemLock(pageHan);
    
    numFuncs = FTabGetCount(task->funcTable);
    if (numFuncs <= *start) goto failFree;

    for (i = *start, size=0; i<numFuncs; i++)
    {
	if (!Write_AddFunc(pageHan, &size, task, i)) goto failFree;

	(*start)++;
	if (size > maxSize) {
	    break;
	}
    }

    if (!MemReAlloc(pageHan, size+2, 0)) goto failFree;
    page = MemDeref(pageHan);
    CAST_ARR(PageMarker, page[size]) = PM_END;
    if (BIG_ENDIAN) {
	swapWord((word*)&page[size]);
    }
    MemUnlock(pageHan);

    size +=2;

    if (passSize != NULL) {
	*passSize = size;
    }

    return pageHan;

 failFree:
    MemFree(pageHan);
    return NullHandle;
}

/*********************************************************************
 *			Write_AddFunc
 *********************************************************************
 * SYNOPSIS:	Add a function to a mem block
 * CALLED BY:	INTERNAL, WriteCreatePage
 * RETURN:	nothing
 * SIDE EFFECTS:Adds to memhandle
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	dubois	 1/ 9/95	Initial version			     
 * 
 *********************************************************************/
Boolean
Write_AddFunc(MemHandle pageHan, word* size, TaskPtr task, word funcNum)
{
    FTabEntry*	ftab;
    FuncHeader*	funcHeader;
    byte*	page;
    word	startSeg, i;
    byte	numSegs;
    word	numLocals;
    Boolean	noSegs;

    noSegs = task->flags & COMPILE_NO_SEGMENTS;
    ftab = FTabLock(task->funcTable, funcNum);
    startSeg = ftab->startSeg;
    numSegs = ftab->size;

    numLocals = VTGetCount(task->vtabHeap, ftab->vtab);
    FTabUnlock(ftab);

    /* Add preliminary info about function to page
     */
    if (MemReAlloc(pageHan, *size+sizeof(FuncHeader), 0) == NullHandle)
	return FALSE;

    page = MemLock(pageHan);
    
    funcHeader = (FuncHeader*) (&page[*size]);
    funcHeader->FH_marker = PM_FUNC;
    funcHeader->FH_funcNumber = funcNum;
    if (noSegs) {
	funcHeader->FH_numSegs = 1;
    } else {
	funcHeader->FH_numSegs = numSegs;
    }
    funcHeader->FH_numLocals = numLocals;

    if (BIG_ENDIAN) {
	swapWord((word*)&(funcHeader->FH_marker));
	swapWord((word*)&(funcHeader->FH_funcNumber));
	swapWord((word*)&(funcHeader->FH_numLocals));
    }

    *size += sizeof(FuncHeader);
    
    if (noSegs)
    {
	/* Write one size at the very beginning
	 * Tack on all segments back-to-back
	 */
	word	totalSize = 0;
	word	segSize;
	byte*	segPtr;

	for (i=startSeg; i<startSeg+numSegs; i++)
	{
	    (void)HugeArrayLock(task->vmHandle, task->codeBlock, i,
				(void**)&segPtr, &segSize);
	    totalSize += segSize;
	    HugeArrayUnlock(segPtr);
	}
	if (!MemReAlloc(pageHan, *size+totalSize+2, 0)) goto failUnlock;
	page = MemDeref(pageHan);
	CAST_ARR(word, page[*size]) = totalSize;
	if (BIG_ENDIAN) { swapWord((word*)&page[*size]); }
	*size += sizeof(word);

	for(i=startSeg; i<startSeg+numSegs; i++)
	{
	    (void)HugeArrayLock(task->vmHandle, task->codeBlock, i,
				(void**)&segPtr, &segSize);
	    memcpy(&page[*size], segPtr, segSize);
	    *size += segSize;
	    HugeArrayUnlock(segPtr);
	}
    }
    else
    {
	/* Append segments to the page; each one is prepended by its size.
	 */
	for (i = startSeg; i < startSeg + numSegs; i++)
	{
	    word	segSize;
	    byte*	segPtr;

	    (void) HugeArrayLock(task->vmHandle, task->codeBlock,
				 i, (void**)&segPtr, &segSize);

	    if (MemReAlloc(pageHan, *size + segSize + sizeof(word), 0) 
		== NullHandle)
	    {
		HugeArrayUnlock(segPtr);
		goto failUnlock;
	    }

	    page = MemDeref(pageHan);
	    CAST_ARR(word, page[*size]) = segSize;

	    if (BIG_ENDIAN) {
		swapWord((word*)&page[*size]);
	    }

	    memcpy(&page[*size+2], segPtr, segSize);
	    *size += segSize+sizeof(word);
	
	    HugeArrayUnlock(segPtr);
	}
    }

    MemUnlock(pageHan);
    return TRUE;

 failUnlock:
    MemUnlock(pageHan);
    return FALSE;
}
