/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  ccp.h
 *
 * AUTHOR:  	  Jennifer Wu: Aug 19, 1996
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/19/96	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	CCP global declarations.
 *
 *
 * 	$Id: ccp.h,v 1.2 97/11/20 18:56:01 jwu Exp $
 *
 ***********************************************************************/
#ifndef _CCP_H_
#define _CCP_H_

/*
 *	ccp.h - Compression Control Protocol definitions.
 */

/*
 *	Configuration options
 */
# define CI_OUI			0	/* OUI */
# define CI_PREDICTOR1		1	/* Predictor type 1 */
# define CI_PREDICTOR2		2	/* Predictor type 2 */
# define CI_PUDDLE_JUMPER	3	/* Puddle Jumper */
# define CI_HP_PPC		16	/* Hewlett-Packard PPC */
# define CI_STAC_LZS		17	/* Stac Electronics LZS */
# define CI_MICROSOFT_PPC	18	/* Microsoft PPC */
# define CI_GANDALF_FZA		19	/* Gandalf FZA */
# define CI_V42BIS		20	/* V.42bis */
# define CI_BSD_LZW		21	/* BSD LZW compress */
# define CI_LZS_DCP 	    	23  	/* LZS-DCP */

# define CCP_MAXCI		23	/* Largest supported conf. option */


/*
 * Types of compression to offer.  Barring any user configuration, 
 * our preference is Stac LZS, then Predictor 1.
 */
# define COMPRESS_PRED1		0x1	/* Offer Predictor-1 */
# define COMPRESS_STAC		0x2	/* Offer Stac LZS */
# define COMPRESS_MPPC		0x4	/* Offer MS PPC */


/*
 * Useful values for working with a Coherency Count (Stac LZS and MPPC). 
 */
# define COHERENCY_COUNT_MASK	0x0fff	    	/* for extracting count */
# define COHERENCY_FLAGS_MASK	0xa000	    	/* for extracting flag */

/* 
 * CCP options structure.  
 */
typedef struct ccp_options
{
    WordFlags ccp_neg;	    	    	/* record of protocols negotiated */

    unsigned short ccp_comp_type;	/* current compression type */

#ifdef STAC_LZS
    unsigned char ccp_stac_check_mode;	    
#endif /* STAC_LZS */

    int rxnaks[CCP_MAXCI + 1];	    	/* No. of Configure-Naks peer sent */
} ccp_options;


extern fsm ccp_fsm[];
extern ccp_options ccp_wantoptions[];
extern ccp_options ccp_gotoptions[];
extern ccp_options ccp_allowoptions[];
extern ccp_options ccp_heroptions[];


/*
 * CCP control structure.
 */

struct ccp
{
    IntCallback *ccp_compressor;    	    /* Compress routine */
    IntCallback *ccp_decompressor;  	    /* Decompress routine */
    IntCallback *ccp_resetcompressor;	    /* Compress reset routine */
    VoidCallback *ccp_resetdecompressor;    /* Decompress reset routine */

    int	ccp_resetting;
    word ccp_orig_mtu;
};    

#ifdef LOGGING_ENABLED
# define CCP_DEFWARNNAKS 8	/* Print a warning every 8 Naks received */
#endif /* LOGGING_ENABLED */

extern void ccp_init();
extern void ccp_open();
extern void ccp_close();
extern void ccp_lowerup();
extern void ccp_lowerdown();
extern byte ccp_input();
extern void ccp_protrej();

extern byte compress_input();

extern void ccp_select_comp_type(); 	
extern void ccp_resetack(); 	    	
extern void ccp_resettimeout();

/*---------------------------------------------------------------------
 	    	    Predictor 1
                  RFC 1978 - August 1996
----------------------------------------------------------------------*/
#ifdef PRED_1

# define CI_PRED1_LEN  	    	2   	/* size of predictor CCP option */

extern int predictor1_initcomp();
extern int predictor1_initdecomp();
extern int predictor1_resetcomp();
extern void predictor1_resetdecomp();
extern int predictor1_comp();
extern int predictor1_decomp();
extern void predictor1_down();	    /* free memory used for compress tables */

#endif  /* PRED_1 */

/*---------------------------------------------------------------------
 	    	    Stac LZS 
                 RFC 1974 - August 1996
----------------------------------------------------------------------*/

#ifdef STAC_LZS

# define CI_STAC_LEN	    	5   	/* size of stac lzs CCP option */

# define STAC_HISTORY_COUNT 	1   	/* we only support 1 history */

/*
 * Check modes.
 */ 
# define STAC_CHECK_LCB		1	/* xor ffh with each byte of data */
# define STAC_CHECK_CRC		2	/* same as FCS */
# define STAC_CHECK_SEQ	    	3   	/* use seq numbers to synchronize */
# define STAC_CHECK_EXTENDED	4   	/* extended mode */

/*
 * For extended mode use.  Helps sort out parts of coherency count field.
 */
# define STAC_PACKET_FLUSHED    0x8000  	/* bit A in coherency count */
# define STAC_COMPRESSED  	0x2000	    	/* bit C in coherency count */

extern int stac_initcomp();
extern int stac_initdecomp();
extern int stac_resetcomp();
extern void stac_resetdecomp();
extern int stac_comp();
extern int stac_decomp();
extern void stac_down();    	    /* free memory used for compress tables */

#endif	/* STAC_LZS */

/*---------------------------------------------------------------------
			Microsoft PPC
		    RFC 2118 - March 1997
----------------------------------------------------------------------*/

#ifdef MPPC

#define CI_MPPC_LEN		6	    /* size of MPPC CCP option */

#define MPPC_SUPPORTED_BITS	0x00000001L  /* in host format */

/*
 * Range of PPP protocol numbers which the MPPC processor is 
 * allowed to compress. 
 */
#define MPPC_MIN_COMPRESS_LIMIT	    0x0021
#define MPPC_MAX_COMPRESS_LIMIT	    0x00fa

/*
 * Bits in compressed header.
 */
#define MPPC_PACKET_FLUSHED	0x8000		/* bit A in host order */
#define MPPC_PACKET_AT_FRONT	0x4000		/* bit B in host order */
#define MPPC_PACKET_COMPRESSED  0x2000		/* bit C in host order */

extern int mppc_initcomp();
extern int mppc_initdecomp();
extern int mppc_resetcomp();
extern void mppc_resetdecomp();
extern int mppc_comp();
extern int mppc_decomp();
extern void mppc_down();	    /* free memory used for compress tables */

#endif /* MPPC */


#endif /* _CCP_H_ */
