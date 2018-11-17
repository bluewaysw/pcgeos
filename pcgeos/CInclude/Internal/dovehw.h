/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Dove
 * MODULE:	  Hardware constants
 * FILE:	  dovehw.h
 *
 * AUTHOR:  	  Allen Yuen: Dec 26, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	allen	12/26/96   	Initial version
 *
 * DESCRIPTION:
 *
 *	A bunch of equates for the dove hardware
 *
 * 	$Id: dovehw.h,v 1.1 97/04/04 15:53:53 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _DOVEHW_H_
#define _DOVEHW_H_



/*
 * EMS window segment
 *
 * These are defined here because they can be relocated (and they may well be
 * moved later..).  So, knowing that, please use these constants whenever
 * possible.
 */
#define DOVE_EMS_WINDOW_0	0xb000
#define DOVE_EMS_WINDOW_1	0xb400
#define DOVE_EMS_WINDOW_2	0xb800
#define DOVE_EMS_WINDOW_3	0xbc00



#define DOVE_IRQSTS1	0x1010		/* 8-bit, DoveIrqSts1Flags */
#define DOVE_IRQINT	0x1012		/* 16-bit, DoveIrqIntFlags */
#define DOVE_IRQMSK	0x1014		/* 16-bit, DoveIrqMskFlags */

#define DOVE_POWCTRL	0x1020		/* 16-bit, DovePowCtrlFlags */
#define DOVE_POWCTRL1	DOVE_POWCTRL
#define DOVE_POWCTRL2	(DOVE_POWCTRL + 1)

#define DOVE_TPCCTRL	0x1070		/* 8-bit, DoveTpcCtrlFlags */
#define DOVE_TP4BYTEX	0x1074		/* 16-bit, DoveTp4ByteFlags */
#define DOVE_TP4BYTEY	0x1076		/* 16-bit, DoveTp4ByteFlags */
#define DOVE_LCDCONT	0x1080		/* 8-bit, 0x00 - 0x1f */

#define DOVE_BUZVOL	0x10b0		/* 8-bit, 0x00 - 0x03 */

#define DOVE_IRQ13MSK	0x10e0		/* 8-bit, DoveIrq13MskFlags */
#define DOVE_IRQ13ST	0x10e4		/* 8-bit, DoveIrq13StFlags */
#define	DOVE_SUBWDT	0x10e6		/* 8-bit, 0x00 - 0x04 */



/*
 * For DOVE_IRQSTS1
 */
typedef ByteFlags DoveIrqSts1Flags;
#define	DIS1F_PDCRST	0x80
#define	DIS1F_PDCTCHF	0x40
#define	DIS1F_SUBLOW	0x20
#define	DIS1F_ACIN	0x10
#define	DIS1F_LIDSW	0x08
#define	DIS1F_TPONINT	0x04
#define	DIS1F_PDCSEND	0x02
#define	DIS1F_PDCEND	0x01



/*
 * For DOVE_IRQINT
 */
typedef WordFlags DoveIrqIntFlags;
/* for DOVE_IRQINT2 */
/* 3 bits unused */
#define	DIIF_DZWUFLG	0x1000
#define	DIIF_SLWUFLG	0x0800
#define	DIIF_PHMCFLG	0x0400
/* 1 bit unused */
#define	DIIF_TPDOKFLG	0x0100

/* for DOVE_IRQINT1 */
#define	DIIF_PHRSTFLG	0x0080
#define	DIIF_PHTCHFLG	0x0040
#define	DIIF_SUBLWFLG	0x0020
#define	DIIF_ACINFLG	0x0010
#define	DIIF_LIDSWFLG	0x0008
#define	DIIF_TPONFLG	0x0004
#define	DIIF_PHSNDFLG	0x0002
#define	DIIF_PHENDFLG	0x0001

#define DOVE_IRQ_INT_FLAGS_WIDTH	13



/*
 * For DOVE_IRQMSK
 */
typedef WordFlags DoveIrqMskFlags;
/* for DOVE_IRQMSK2 */
/* 3 bits unused */
#define	DIMF_DZWUMSK	0x1000
#define	DIMF_SLWUMSK	0x0800
#define	DIMF_DPRSVMSK	0x0400
/* 1 bit unused */
#define	DIMF_TPDOKMSK	0x0100

/* for DOVE_IRQMSK1 */
#define	DIMF_PHRSTMSK	0x0080
#define	DIMF_PHTCHMSK	0x0040
#define	DIMF_SUBLWMSK	0x0020
#define	DIMF_ACINMSK	0x0010
#define	DIMF_LIDSWMSK	0x0008
#define	DIMF_TPONMSK	0x0004
#define	DIMF_SENDMSK	0x0002
#define	DIMF_ENDMSK	0x0001



/*
 * For DOVE_POWCTRL
 */
typedef WordFlags DovePowCtrlFlags;
/* for DOVE_POWCTRL2 */
/* 1 bit unused */
#define	DPCF_SUBRST	0x4000
#define	DPCF_14MON	0x2000
#define	DPCF_PWBOOST	0x1000
/* 1 bit unused */
#define	DPCF_FLSHON1	0x0400
/* 1 bit unused */
#define	DPCF_BCHKSW1	0x0100

/* for DOVE_POWCTRL1 */
/* 3 bits unused */
#define	DPCF_SEPCSTBY	0x0010
#define	DPCF_IRON	0x0008
#define	DPCF_MODEMON	0x0004
#define	DPCF_PICOON	0x0002
/* 1 bit unused */



/*
 * For DOVE_TPCCTRL
 */
typedef ByteEnum TpcMode;
#define	TM_CONTINUE		0x00
#define	TM_MAKE			0x01
#define	TM_MAKE_AND_BREAK	0x02
#define	TM_REQUEST		0x03

typedef ByteFlags DoveTpcCtrlFlags;
/* 4 bits unused */
#define	DTCF_TPDATASEL		0x08	/* 0: 1-byte method, 1: 4-byte method*/
#define	DTCF_TPDREQ		0x04
#define	DTCF_TPCMODE		0x03	/* TpcMode */

#define DTCF_TPCMODE_OFFSET	0



/*
 * For DOVE_TP4BYTEX and DOVE_TP4BYTEY
 */
typedef WordFlags DoveTp4ByteFlags;
/* 5 bits unused */
#define	DTBF_RELEASE		0x0400		/* 0 = touch, 1 = release */
#define	DTBF_DATA		0x03ff

#define DTBF_DATA_OFFSET	0



/*
 * For DOVE_IRQ13MSK
 */
typedef ByteFlags DoveIrq13MskFlags;
/* 6 bits unused */
#define DI13MF_WDTMSK		0x02
#define DI13MF_BATMSK		0x01



/*
 * For DOVE_IRQ13ST
 */
typedef ByteFlags DoveIrq13StFlags;
/* 6 bits unused */
#define DI13SF_WDTST		0x02
#define DI13SF_BATST		0x01

#define DOVE_IRQ_13_ST_FLAGS_WIDTH	2



#endif /* _DOVEHW_H_ */
