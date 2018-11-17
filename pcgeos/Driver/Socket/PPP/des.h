/***********************************************************************
 *
 *	Copyright (c) Global PC 1998 -- All Rights Reserved
 *
 *			GLOBAL PC CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  des.h
 *
 * AUTHOR:  	  Brian Chin: October 6, 1998
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/6/98	  brianc    Initial version
 *
 * DESCRIPTION:
 *	Header file for DES.
 *
 *
 * 	$Id$
 *
 ***********************************************************************/

#ifndef __DES_INCLUDE__

/* des.h */
/* Copyright (C) 1993 Eric Young - see README for more details */

typedef unsigned char u_char;

typedef unsigned char des_cblock[8];
typedef struct des_ks_struct
	{
	union	{
		des_cblock _;
		/* make sure things are correct size on machines with
		 * 8 byte longs */
		unsigned long pad[2];
		} ks;
#define _	ks._
	} des_key_schedule[16];

#define DES_KEY_SZ 	(sizeof(des_cblock))
#define DES_ENCRYPT	1
#define DES_DECRYPT	0

/*
 *  DES routines
 */
void des_set_odd_parity(des_cblock *key);
int des_set_key(des_cblock *key, des_key_schedule schedule);
int des_ecb_encrypt(des_cblock *input, des_cblock *output, des_key_schedule ks, int encrypt);


#define __DES_INCLUDE__
#endif /* __DES_INCLUDE__ */
