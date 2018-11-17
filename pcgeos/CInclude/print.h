/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * PROJECT:	  GEOS  
 * MODULE:	  CInclude
 * FILE:	  print.h
 *
 * AUTHOR:  	  Jenny Greenwood: Aug 31, 1993
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jenny	8/31/93   	Initial version
 *
 * DESCRIPTION:
 *	Header containing externally visible printer driver definitions.
 *
 * 	$Id: print.h,v 1.1 97/04/04 15:57:58 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _PRINT_H_
#define _PRINT_H_

/*
 * Different printer modes.
 */
typedef ByteEnum PrinterMode;
#define PM_GRAPHICS_LOW_RES	0       /* lowest quality...fastest... */
#define PM_GRAPHICS_MED_RES	2	/* medium quality...slower... */
#define PM_GRAPHICS_HI_RES	4	/* best quality...slowest... */
#define PM_TEXT_DRAFT		6	/* fastest ascii output */
#define PM_TEXT_NLQ		8	/* best quality ascii output */

#define PM_FIRST_TEXT_MODE	PM_TEXT_DRAFT 
                                        /* equate to make the code easier */
/*
 * Page type
 */
typedef enum /* word */ {
    PT_PAPER	= 0,
    PT_ENVELOPE	= 2,
    PT_LABEL	= 4,
    PT_POSTCARD = 6
} PageType;
#define PaperType	PageType

/* 
 * Page layout options for paper
 */
typedef ByteEnum PaperOrientation;
#define PO_PORTRAIT  	0
#define PO_LANDSCAPE 	1

typedef WordFlags PageLayoutPaper;
#define PLP_ORIENTATION	0x0008	    	    	/* PaperOrientation */
#define	PLP_TYPE	0x0007	    	    	/* PageType: PT_PAPER */

/* 
 * Page layout options for envelopes
 */
typedef ByteEnum EnvelopeOrientation;
#define EO_PORTRAIT 	0
#define EO_LANDSCAPE	1

typedef WordFlags PageLayoutEnvelope;
#define PLE_ORIENTATION	0x0008	    	    	/* EnvelopeOrientation */
#define PLE_TYPE	0x0007			/* PageType: PT_ENVELOPE */

/*
 * Page layout options for labels
 */
typedef WordFlags PageLayoutLabel;
#define PLL_ROWS	0x7e00			/* labels down */
#define PLL_COLUMNS	0x01f8			/* labels across */
#define PLL_TYPE	0x0007			/* PageType: PT_LABEL */

/*
 * Page layout options for postcards
 */
typedef ByteEnum PostcardOrientation;
#define PCO_PORTAIT 	0
#define PCO_LANDSCAPE	1

typedef WordFlags PageLayoutPostcard;
#define PLPC_ORIENTATION 0x0008	    	    	/* PostcardOrientation */
#define PLPC_TYPE   	 0x0007	    	    	/* PageType: PT_POSTCARD */

/*
 * A union of all the page layout options.
 */
typedef union {
    PageLayoutPaper 	PL_paper;
    PageLayoutEnvelope	PL_envelope;
    PageLayoutLabel	PL_label;
    PageLayoutPostcard	PL_postcard;
} PageLayout;

/*
 * Margin structure
 */
typedef struct {
    word	PCMP_left;	/* left margin */
    word	PCMP_top;	/* top margin */
    word	PCMP_right;	/* right margin */
    word	PCMP_bottom;	/* bottom margin */
} PCMarginParams;

/*
 * Dimensions structure
 */
typedef struct {
    dword	PCDSP_width;	/* width of the document */
    dword	PCDSP_height;	/* height of the document */
} PCDocSizeParams;

/*
 * PageSizeReport structure
 */
typedef struct {
    dword	    PSR_width;	        /* width of the page */
    dword	    PSR_height;		/* height of the page */
    PageLayout	    PSR_layout;	 	/* layout options */
    PCMarginParams  PSR_margins;	/* document margins */
} PageSizeReport;

/* 
 * This enumerated type indicates the type of printer driver
 * that we are dealing with, as printer drivers are really a broad
 * class of output device drivers
 */
typedef ByteEnum PrinterDriverType;
#define	PDT_PRINTER	0
#define	PDT_PLOTTER	1
#define	PDT_FACSIMILE	2
#define	PDT_CAMERA	3
#define	PDT_OTHER	4

#define	PDT_ALL	        (-1)	/* all printers of all types
				 * - do NOT pass to SpoolGetNumPrinters
				 */

#define	PDT_ALL_LOCAL_AND_NETWORK 0x00ff
                                /* all printers of all types
				 * - CAN be passed to SpoolGetNumPrinters
				 */

#endif /* _PRINT_H_ */
