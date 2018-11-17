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
 * File:    sprm.h
 *
 ***************************************************************************/

#include "structs.h"
#include <sstor.h>

word SprmUpgradeOpcode(byte sprm);
word SprmGetCount(word op);
Boolean SprmReadGrpprl(StgStream hStream, word cbGrpprl, void *p, ushort sgc);
Boolean SprmReadGrpprlMem(byte *pGrpprl, word cbGrpprl, void *p, ushort sgc);
Boolean SprmProcess(word op, word cch, byte *pData, void *p, ushort sgc);

typedef struct
{
    byte STE_opcode;            /* lower 8 bits of sprm opcode */
    word STE_offset;            /* offset into Word struct */
    word STE_extra;
} SprmTableEntry;

