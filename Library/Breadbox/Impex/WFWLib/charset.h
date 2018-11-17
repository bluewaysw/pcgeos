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
 * File:    charset.h
 *
 ***************************************************************************/

#ifndef __CHARSET_H
#define __CHARSET_H

#include <localize.h>
#include "codepage.h"

#define DEFAULT_CODEPAGE	CP_WESTEUROPE
#define SHUTDOWN_CODEPAGE	CP_NIL
#define CP_UNICODE          (-2)

wchar WFWCodePageToGeos(wchar ch);
wchar WFWGeosToCodePage(wchar ch);
void WFWSetCodePage(DosCodePage nCP);

#endif /* __CHARSET_H */
