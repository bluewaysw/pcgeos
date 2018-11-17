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
 * File:    wfwlib.h
 *
 ***************************************************************************/

typedef struct
    {
    PageSetupInfo WFWTD_pageInfo;
    }
WFWTransferData;

/***********************************************************************
 * WFWImport
 *
 * Read a Windows for Word docfile into a VisText object.
 *
 * Pass: source - file handle of docfile
 *       dest - optr of large VisText to receive text
 *       data - pointer to data block to be filled in
 *
 * Returns: TransError
 ***********************************************************************/
extern TransError _export _pascal WFWImport(FileHandle source,
    optr dest, WFWTransferData* data);

