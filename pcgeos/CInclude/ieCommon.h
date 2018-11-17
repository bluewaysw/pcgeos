/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	ieCommon.h
 * AUTHOR:	Tony Requist: February 12, 1991
 *
 * DECLARER:	Impex
 *
 * DESCRIPTION:
 *	This file defines common Impex definitions
 *
 *	$Id: ieCommon.h,v 1.1 97/04/04 15:59:02 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__IECOMMON_H
#define __IECOMMON_H

typedef struct {
    optr	        ITP_impexOD;
    Message	        ITP_returnMsg;
    word	        ITP_dataClass;
    FileHandle	        ITP_transferVMFile;
    VMChain	        ITP_transferVMChain;
    dword	        ITP_internal;
    ManufacturerID      ITP_manufacturerID;
    ClipboardItemFormat ITP_clipboardFormat;
} ImpexTranslationParams;

#endif
