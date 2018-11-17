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
 * File:    list.h
 *
 ***************************************************************************/

#ifndef _WFWFONT_H
#define _WFWFONT_H

#include "structs.h"
#include <font.h>
#include <localize.h>

Boolean FontRead(FIBFCLCB sttbfffn);
FontID FontFindFont(word ftc, DosCodePage *);

#endif /* _WFWFONT_H */
