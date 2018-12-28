/****************************************************************************
 *
 * ==CONFIDENTIAL INFORMATION== 
 * COPYRIGHT 1994-2000 BREADBOX COMPUTER COMPANY --
 * ALL RIGHTS RESERVED  --
 * THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
 * NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
 * RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
 * NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
 * CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
 * AGREEMENT.
 *
 * Project: Word For Windows Core Library
 * File:    import.c
 *
 ***************************************************************************/

#include <geos.h>
#include <xlatLib.h>
#include <resource.h>
#include "wfwinput.h"
#include "global.h"
#include "text.h"
#include "warnings.h"
#include "charset.h"
#include "style.h"
#include "wfwlib.h"
#include <Ansi/string.h>
#include "debug.h"

/*****************************************************************************/

void FillImportDataBlock(WFWTransferData* data)
{
    GlobalGetPageSetup(&data->WFWTD_pageInfo);
}

/***********************************************************************
 * WFWImport
 *
 * Read a Windows for Word docfile into a VisText object.
 *
 * Pass: source - file handle of docfile
 *       dest - optr of large VisText to receive text
 *
 * Returns: TransError
 ***********************************************************************/

TransError _pascal WFWImport (FileHandle source, optr dest, WFWTransferData* data)
{
    TransError retval;
#ifdef DEBUG
    FileHandle fh;
#endif
    
     _asm push ds;
     GeodeLoadDGroup( GeodeGetCodeProcessHandle() );

#ifdef DEBUG
    fh = FileCreate("impex.log", FCF_NATIVE | FILE_CREATE_TRUNCATE
      | FILE_ACCESS_W | FILE_DENY_W, 0);
    SetDebugFile(fh);
#endif

    SetError(TE_NO_ERROR);
    TextBufferInit();

    if (StyleInit())
    {
	if (InputInit(source))
	{
	    TextInit(dest);
	    
	    if (!InputTrans() && GetError() == TE_NO_ERROR)
		SetError(TE_IMPORT_ERROR);
	    FillImportDataBlock(data);
	}
	else if (GetError() == TE_NO_ERROR)
	    SetError(TE_IMPORT_ERROR);

	InputFree();
    }
    StyleFree();
    
    TextBufferFree();
    WFWSetCodePage(SHUTDOWN_CODEPAGE);

#ifdef DEBUG
    FileClose(fh, FALSE);
#endif

    retval = GetError();
    _asm pop ds;
    
    return retval;
}

