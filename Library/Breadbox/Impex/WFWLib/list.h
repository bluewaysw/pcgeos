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

#include "structs.h"

Boolean ListRead(FIBFCLCB plcfLst, FIBFCLCB plfLfo);
void 	ListFree(void);
Boolean ListApplyPapx(PAP *pap);
Boolean ListApplyChpx(short ilfo, ushort ilvl, CHP *chp);
Boolean ListInsertText(ushort ilvl, char *cSpace);

