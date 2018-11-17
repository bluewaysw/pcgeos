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
 * File:    codepage.h
 *
 ***************************************************************************/

/*----------------------------------------------------------------------------
	%%File: CODEPAGE.H
	%%Unit: CORE
	%%Contact: smueller

	Codepage definitions
----------------------------------------------------------------------------*/

#ifndef CODEPAGE_H
#define CODEPAGE_H

#if defined(WIN16) || defined(MAC)
#define CP_ACP		0
#define CP_OEMCP	1
#define CP_MACCP	2
#endif

#define CP_NIL				(-1)
#define CP_SYMBOL			42
#define CP_OEM_437			437
#define CP_THAI				874
#define CP_JAPAN			932
#define CP_CHINA			936
#define CP_KOREA			949
#define CP_TAIWAN			950
#define CP_EASTEUROPE		1250
#define CP_RUSSIAN			1251
#define CP_WESTEUROPE		1252
#define CP_GREEK			1253
#define CP_TURKISH			1254
#define CP_HEBREW			1255
#define CP_ARABIC			1256
#define CP_BALTIC			1257
#define CP_JOHAB			1361
#define CP_MAC_ROMAN		10000
#define CP_MAC_JAPAN		10001
#define CP_MAC_GREEK		10006
#define CP_MAC_CYRILLIC		10007
#define CP_MAC_LATIN2		10029
#define CP_MAC_TURKISH		10081
#define CP_UTF8				65001
#if MAC
#define CP_DEFAULT			CP_MACCP
#else
#define CP_DEFAULT			CP_ACP
#endif


#endif // CODEPAGE_H
