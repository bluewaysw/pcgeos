/***********************************************************************
 *
 *	Copyright (c) GlobalPC 1998.  All rights reserved.
 *	GLOBALPC CONFIDENTIAL
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  card.h
 *
 * AUTHOR:  	  : Oct 01, 1998
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Todd    	10/01/98   	Initial version
 *
 * DESCRIPTION:
 *
 *	
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _CARD_H_
#define _CARD_H_

#ifndef _SPLASH_C_

int CardInit(void);
void CardClearVMem(void);
void CardSetVideoMode(void);
void CardDisableOutput(void);
void CardEnableOutput(void);

unsigned long CardGetMapSize(void);
unsigned char far *CardMapPage(int);
void CardWriteScan(unsigned char *, unsigned int);

void CardSetPalette(unsigned char *);

#else

extern int CardInit(void);
extern void CardClearVMem(void);
extern void CardSetVideoMode(void);
extern void CardDisableOutput(void);
extern void CardEnableOutput(void);

extern unsigned long CardGetMapSize(void);
extern unsigned char far *CardMapPage(int);
extern void CardWriteScan(unsigned char *, unsigned int);

extern void CardSetPalette(unsigned char *);

#endif

#endif /* _CARD_H_ */
