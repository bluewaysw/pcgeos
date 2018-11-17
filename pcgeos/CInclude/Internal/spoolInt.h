/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * PROJECT:	  GEOS
 * MODULE:	  CInclude
 * FILE:	  spoolInt.h
 *
 * AUTHOR:  	  Jenny Greenwood: Aug 31, 1993
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jenny	8/31/93   	Initial version
 *
 * DESCRIPTION:
 *	Header containing internal spool library definitions.
 *
 * 	$Id: spoolInt.h,v 1.1 97/04/04 15:54:20 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _SPOOLINT_H_
#define _SPOOLINT_H_

#include    <serialDr.h>
#include    <parallDr.h>

/*-----------------------------------------------------------------------------
 *		Port-dependent structures
 *---------------------------------------------------------------------------*/
	
/*
 * maximum # of characters for device in a printer driver
 */
#define MAX_DEVICE_NAME_SIZE 40

/*
 * what type of port is the printer hooked to
 */
typedef enum /* word */ {
    PPT_SERIAL  	= 0,
    PPT_PARALLEL	= 2,
    PPT_FILE    	= 4,
    PPT_NOTHING 	= 6,
    PPT_CUSTOM  	= 8
} PrinterPortType;

/*
 * serial port parameters
 */
typedef struct {
    SerialPortNum   	SPP_portNum;	/* which port number */
    SerialFormat    	SPP_format;	/* #stop bits, parity, word length...*/
    SerialMode	    	SPP_mode;	/* XON/XOFF, ...*/
    SerialBaud	    	SPP_baud;   	/* baud rate enum */
    SerialFlowControl	SPP_flow;	/* hardware, software */
    SerialModem	    	SPP_stopRem;	/* signal received that indicates STOP */
    SerialModemStatus	SPP_stopLoc;	/* signal to send that indicates STOP */
} SerialPortParams;
		
/*
 * parallel port parameters
 */
typedef struct {
    ParallelPortNum PPP_portNum;    	/* which port number */
} ParallelPortParams;
		
/*
 * print to file parameters
 */
typedef struct {
    char    FPP_fileName[FILE_LONGNAME_BUFFER_SIZE];
    char    FPP_path[PATH_BUFFER_SIZE];	    	/* allow complete path */
    word    FPP_diskHandle;			/* disk handle */
    word    FPP_file;			    	/* file handle to close it */
    word    FPP_unit;				/* unit number w/filestr driver */
} FilePortParams;

/*
 * custom port parameters
 */
typedef struct {
    word    CPP_null;
} CustomPortParams;

/*
 * union of port parameters
 */
typedef union {
    SerialPortParams	PP_serial;	/* if serial port is used */
    ParallelPortParams	PP_parallel;	/* if parallel port is used */
    FilePortParams  	PP_file;	/* if file is used */
    CustomPortParams	PP_custom;	/* if custom is used */
} PortParams;

/*
 * Printer port info.
 * This structure is used to specify the attributes of the
 * port the printer is hooked up to.
 */
typedef struct _PrintPortInfo {
    PrinterPortType PPI_type;		/* serial, parallel... */
    PortParams	    PPI_params;	    	/* initializing info */
} PrintPortInfo;

/*
 *  this enum is stored in the JobParameters block by the
 *  caller of SpoolAddJob and determines what the spooler
 *  should do with the file when its finished
 */
typedef ByteEnum SpoolFileType;
/*  save the spool file when done */
#define SFT_SAVE_FILE	0x0
/*  delete the spool file when done */
#define SFT_DELETE_FILE	0x1

/*
 *  this enum is stored in the JobParameters block by the
 *  caller of SpoolAddJob and determines how the spooler
 *  should order multiple copies.  It is ignored if there 
 *  is only one copy to produce
 */
typedef ByteEnum SpoolCollate;
/*  save the spool file when done */
#define SC_DONT_COLLATE	0x0
/*  delete the spool file when done */
#define SC_COLLATE	0x1

/*
 *  this enum is stored in the JobParameters block by the
 *  caller of SpoolAddJob and forces the output to be 
 *  rotated if set.  The spooler normally determines if the
 *  output should be rotated by seeing if the document is in
 *  landscape mode.  This flag can be used to force the output
 *  to be printed (and perhaps tiled) in landscape fashion, and
 *  might be used by a spreadsheet program to do sideways 
 *  printing, for example.
 */
typedef ByteEnum SpoolRotate;
/*  leave the output as is */
#define SC_DONT_ROTATE	0x0
/*  force rotation of output */
#define SC_ROTATE	0x1

/*
 *  this enum indicates whether the normal order of printing
 *  should be followed (0->n), or whether a custom page ordering
 *  should take place
 */
typedef ByteEnum SpoolOrder;
#define SO_NORMAL_ORDER	0x0
#define SO_CUSTOM_ORDER	0x1

/*
 *  this enum indicated whether or not the document should
 *  be "scaled-to-fit"
 */
typedef ByteEnum SpoolScale;
#define SS_TILE	0x0
#define SS_SCALE_TO_FIT	0x1

/*
 *  this record is stored in the job parameters block and hold
 *  various pieces of info about the job.
 */
typedef ByteFlags SpoolOptions;		/* CHECKME */
/*  what to do with the file when done */
#define SO_DELETE	(0x80)
/*  how to organize multiple copies */
#define SO_COLLATE	(0x40)
/*  force rotation of output */
#define SO_FORCE_ROT	(0x20)
/*  print pages in reverse order */
#define SO_REVERSE_ORDER	(0x10)
/*  print odd, then even pages */
#define SO_ODD_EVEN	(0x08)
/*  scale to fit or not */
#define SO_SCALE	(0x04)
/* 2 bits unused */

/*  this is the info passed to SpoolAddJob */
typedef struct {		/* CHECKME */
/*  DO NOT CHANGE THE ORDER OF THESE FIRST FOUR ITEMS */
/*  std DOS (8.3) spool file name */
    char 	JP_fname[13];
/*  name of par. app */
    char JP_parent[FILE_LONGNAME_LENGTH+1];
/*  name of document */
    char JP_documentName[FILE_LONGNAME_LENGTH+1];
/*  # pages in document */
    word	JP_numPages;
    char JP_printerName[GEODE_MAX_DEVICE_NAME_SIZE+16+1];
/*  INI file category holding the printer name */
/*  name of device */
    char JP_deviceName[MAX_DEVICE_NAME_SIZE];
/*  union for type of port info */
    PrintPortInfo   JP_portInfo;
/*  what mode we're printing in */
    PrinterMode	    JP_printMode;
/*  paper size information */
    PageSizeReport	JP_paperSizeInfo;
/*  document size information */
    PageSizeReport	JP_docSizeInfo;
/*  delete file or not  */
    SpoolOptions 	JP_spoolOpts;
/*  how many to print */
    byte	JP_numCopies;
/*  timeout value to use */
    word	JP_timeout;
/*  maximum number of retries */
    byte	JP_retries;
/*  size of the JobParameters */
    word	JP_size;
/*  printer-specific data */
    word JP_printerData[10];
} JobParameters;

/* -----------------------------------------------------------------------------
 *  Text printing structures.  The text printing code builds
 *  out a list of strings that it needs to send to the driver,
 *  sorted in y order.  An LMem block is allocated to hold
 *  the strings, and the whole page is scanned (using DrawString
 *  before any text is sent.  This allows the text strings to
 *  be placed anywhere on the page at any point in the gstring.
 * 
 * 
 *        New style run info structure. The text is accumulated in ordered
 *        chunks along with the position, and a pointer to the TextAttributes
 *        elememt that matches it. The structure is called the StyleRunInfo
 *        structure, and it follows:
 */

typedef struct {		/* CHECKME */
/* Yposition of this text. */
    word	SRI_yPosition;
/* Xposition of this text. */
    word	SRI_xPosition;
/* number of characters in this run */
    word	SRI_numChars;
/* width of characters in this run */
    WBFixed	SRI_stringWidth;
/*
 * element number of this text's
 * attibute.
 */
    word	SRI_attributes;
/* text follows (DO NOT USE SIZE OF THIS */
    byte	SRI_text;
} StyleRunInfo;

/*
 *        The Attributes structure includes anything that the printer can use for
 *        setting fonts and styles at the printer. It is an element array pointed
 *        into from the StyleRunInfo array. Most of these are out of the TextAttr
 *        structure defined in the kernal graphics.def. The important difference
 *        is the ommision of the clearing fields for style and text mode.
 */
typedef struct {		/* CHECKME */
/*  doo for the element array */
    RefElementHeader	TAI_meta;
/*  RGB values or index */
    RGBValue 	TAI_color;
/*  draw mask */
    SystemDrawMask	TAI_mask;
/*
 *  text style bits to set
 *  (printer format)
 */
    word	TAI_style;
/*  text mode bits to set */
    TextMode	TAI_mode;
/*  space padding */
    WBFixed	TAI_spacePad;
/*  typeface */
    FontID	TAI_font;
/*  point size */
    WBFixed	TAI_size;
/*  track kerning */
    sword	TAI_trackKern;
/*  weight of font */
    FontWeight	TAI_fontWeight;
/*  width of font */
    FontWidth	TAI_fontWidth;
} TextAttrInfo;

/*
 *        These two structures , built out in the same lmem segment
 *	  are all that are needed to format the page from the
 *	  spooler point of view. The print driver now has the
 *	  responsibility of positioning them, and setting the font
 *	  info in the printer.
 *
 */

/*  structure for entire block */
typedef struct {		/* CHECKME */
/*  required header part */
    LMemBlockHeader 	TS_header;
/*  text attribute element to add */
    TextAttrInfo	TS_testAttribute;
/*  offset past gstring struc */
    word	TS_textOffset;
/*  handle of gstring buffer */
    word	TS_gsBuffer;
/*  handle of Text strings buffer */
    word	TS_styleRunInfo;
/*  handle of attributes buffer */
    word	TS_textAttributeInfo;
} TextStrings;
/* ----------------------------------------------------------------------------- */


#endif /* _SPOOLINT_H_ */
