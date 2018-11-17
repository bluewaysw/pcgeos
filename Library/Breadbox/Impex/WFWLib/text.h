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
 * File:    text.h
 *
 ***************************************************************************/

extern dword TextCurPos;   /* insertion position in output text object */

void TextInit(optr obj);
void TextAppendText(char *pText);
void TextAppendCharAttrs(VisTextCharAttr *pAttrs);
void TextAppendParaAttrs(VisTextParaAttr *pAttrs);

#define VISTEXTPARAATTRSIZE(pPara)  ( sizeof(VisTextParaAttr) + ((pPara)->VTPA_numberOfTabs * sizeof(Tab)) )

#define C_SECTION_BREAK C_CTRL_K
#define C_PAGE_BREAK    C_CTRL_L
#define C_COLUMN_BREAK  C_PAGE_BREAK

