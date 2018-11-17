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
 * File:    wfwinput.h
 *
 ***************************************************************************/

#include <file.h>
#include "structs.h"

#define EOF (-1)

Boolean InputInit(FileHandle fh);
void InputFree(void);
Boolean InputTrans(void);
CHP *InputGetChp(void);
PAP *InputGetPap(void);

