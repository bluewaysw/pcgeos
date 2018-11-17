/***********************************************************************
 *
 *	Copyright (c) Global PC 1998 -- All Rights Reserved
 *
 *			GLOBAL PC CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  chap_ms.c
 *
 * AUTHOR:  	  Brian Chin: October 6, 1998
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	ChapMS
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/6/98	  brianc    Initial version
 *
 * DESCRIPTION:
 *	MS-CHAP algorithm.
 *
 * 	$Id$
 *
 ***********************************************************************/
/*
 * chap_ms.c - Microsoft MS-CHAP compatible implementation.
 *
 * Copyright (c) 1995 Eric Rosenquist, Strata Software Limited.
 * http://www.strataware.com/
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by Eric Rosenquist.  The name of the author may not be used to
 * endorse or promote products derived from this software without
 * specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
 * Modifications by Lauri Pesonen / lpesonen@clinet.fi, april 1997
 *
 *   Implemented LANManager type password response to MS-CHAP challenges.
 *   Now pppd provides both NT style and LANMan style blocks, and the
 *   prefered is set by option "ms-lanman". Default is to use NT.
 *   The hash text (StdText) was taken from Win95 RASAPI32.DLL.
 *
 *   You should also use DOMAIN\\USERNAME as described in README.MSCHAP80
 */

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

#include "ppp.h"
#include "chap.h"
#include "chap_ms.h"
#include "md4.h"

#include "des.h"

#undef MSLANMAN


typedef struct {
    u_char LANManResp[24];
    u_char NTResp[24];
    u_char UseNT;		/* If 1, ignore the LANMan response field */
} MS_ChapResponse;
/* We use MS_CHAP_RESPONSE_LEN, rather than sizeof(MS_ChapResponse),
   in case this struct gets padded. */


static void	ChallengeResponse(u_char *, u_char *, u_char *);
static void	DesEncrypt(u_char *, u_char *, u_char *);
static void	MakeKey(u_char *, u_char *);
static u_char	Get7Bits(u_char *, int);
static void	ChapMS_NT(char *, int, char *, int, MS_ChapResponse *);
#ifdef MSLANMAN
static void	ChapMS_LANMan(char *, int, char *, int, MS_ChapResponse *);
#endif


static void
ChallengeResponse(u_char *challenge, u_char *pwHash, u_char *response)
    /* u_char *challenge;	IN   8 octets */
    /* u_char *pwHash;		IN  16 octets */
    /* u_char *response;	OUT 24 octets */
{
    char    ZPasswordHash[21];

    memset(ZPasswordHash, 0, sizeof(ZPasswordHash));
    memcpy(ZPasswordHash, pwHash, MD4_SIGNATURE_SIZE);

    DesEncrypt(challenge, ZPasswordHash +  0, response + 0);
    DesEncrypt(challenge, ZPasswordHash +  7, response + 8);
    DesEncrypt(challenge, ZPasswordHash + 14, response + 16);
}


static void
DesEncrypt(u_char *clear, u_char *key, u_char *cipher)
    /* u_char *clear;	IN  8 octets */
    /* u_char *key;	IN  7 octets */
    /* u_char *cipher;	OUT 8 octets */
{
    des_cblock		des_key;
    des_key_schedule	key_schedule;

    MakeKey(key, des_key);

    des_set_key(&des_key, key_schedule);

    des_ecb_encrypt((des_cblock *)clear, (des_cblock *)cipher, key_schedule, 1);
}


static u_char Get7Bits(u_char *input, int startBit)
{
    register unsigned int	word;

    word  = (unsigned)input[startBit / 8] << 8;
    word |= (unsigned)input[startBit / 8 + 1];

    word >>= 15 - (startBit % 8 + 7);

    return word & 0xFE;
}


static void MakeKey(u_char *key, u_char *des_key)
    /* u_char *key;	IN  56 bit DES key missing parity bits */
    /* u_char *des_key;	OUT 64 bit DES key with parity bits added */
{
    des_key[0] = Get7Bits(key,  0);
    des_key[1] = Get7Bits(key,  7);
    des_key[2] = Get7Bits(key, 14);
    des_key[3] = Get7Bits(key, 21);
    des_key[4] = Get7Bits(key, 28);
    des_key[5] = Get7Bits(key, 35);
    des_key[6] = Get7Bits(key, 42);
    des_key[7] = Get7Bits(key, 49);

    des_set_odd_parity((des_cblock *)des_key);
}


static void
ChapMS_NT(char *rchallenge, int rchallenge_len, char *secret, int secret_len, MS_ChapResponse *response)
{
    int			i;
    MD4_CTX		md4Context;
    u_char		hash[MD4_SIGNATURE_SIZE];
    u_char		unicodePassword[MAX_NT_PASSWORD * 2];

    /* Initialize the Unicode version of the secret (== password). */
    /* This implicitly supports 8-bit ISO8859/1 characters. */
    memset(unicodePassword, 0, sizeof(unicodePassword));
    for (i = 0; i < secret_len; i++)
	unicodePassword[i * 2] = (u_char)secret[i];

    MD4Init(&md4Context);
    MD4Update(&md4Context, unicodePassword, secret_len * 2 * 8);	/* Unicode is 2 bytes/char, *8 for bit count */

    MD4Final(hash, &md4Context); 	/* Tell MD4 we're done */

    ChallengeResponse(rchallenge, hash, response->NTResp);
}

#ifdef MSLANMAN
static u_char *StdText = (u_char *)"KGS!@#$%"; /* key from rasapi32.dll */

static void
ChapMS_LANMan(char *rchallenge, int rchallenge_len, char *secret, int secret_len, MS_ChapResponse *response)
{
    int			i;
    u_char		UcasePassword[MAX_NT_PASSWORD]; /* max is actually 14 */
    u_char		PasswordHash[MD4_SIGNATURE_SIZE];

    /* LANMan password is case insensitive */
    memset(UcasePassword, 0, sizeof(UcasePassword));
    for (i = 0; i < secret_len; i++)
       UcasePassword[i] = (u_char)toupper(secret[i]);
    DesEncrypt( StdText, UcasePassword + 0, PasswordHash + 0 );
    DesEncrypt( StdText, UcasePassword + 7, PasswordHash + 8 );
    ChallengeResponse(rchallenge, PasswordHash, response->LANManResp);
}
#endif


void
ChapMS(chap_state *cstate, char *rchallenge, int rchallenge_len, char *secret, int secret_len)
{
    MS_ChapResponse	response;
#ifdef MSLANMAN
    extern int ms_lanman;
#endif

    memset(&response, 0, sizeof(response));

    /* Calculate both always */
    ChapMS_NT(rchallenge, rchallenge_len, secret, secret_len, &response);

#ifdef MSLANMAN
    ChapMS_LANMan(rchallenge, rchallenge_len, secret, secret_len, &response);

    /* prefered method is set by option  */
    response.UseNT = !ms_lanman;
#else
    response.UseNT = 1;
#endif

    memcpy(cstate->us_myresponse, &response, MS_CHAP_RESPONSE_LEN);
    cstate->us_myresponse_len = MS_CHAP_RESPONSE_LEN;
}
