/*********************************************************************

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		
FILE:		printDr.h

AUTHOR:		Chris Boyke, Jan 19, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/95   	Initial version.

DESCRIPTION:
	Header file for accessing printer drivers from "C"
	No "wrapper" routines are provided here, just constant
	and data definitions

	$Id: printDr.h,v 1.1 97/04/04 15:53:55 newdeal Exp $

*********************************************************************/

/* ---------------------------------------------------------------------------
 * 		Print Driver Function Calls
 * ---------------------------------------------------------------------------*/

#include <spoolInt.h>
/*
 *  Protocol number for this interface. Adjust the final numbers, below, if the
 *  interface is changed.
 */
#define PRINT_PROTO_MAJOR	(DRIVER_EXT_PROTO_MAJOR+2)
#define PRINT_PROTO_MINOR	(DRIVER_EXT_PROTO_MINOR+0)

/* enum PrintFunction */
typedef enum {		

/*
 * 	These are the first four functions to be supported
 *  DR_INIT		0
 *  DR_EXIT		2
 *  DRE_TEST_DEVICE	4
 *  DRE_SET_DEVICE	6
 */

/*  functions that are resident in the Entry module */

/*
 *  return ptr to info blk
 * 	PASS: 		nothing
 * 	RETURN:		dx:si	= handle:offset to driver info structure
 * 			  	  (structure type DriverExtendedInfoTable)
 * 			          the structure PrintDriverInfo is located
 * 			          immediately after DriverExtendedInfoTable
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_DRIVER_INFO = 0x0C,

/*
 *  return ptr to info blk
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		dx:si	= handle:offset to device info structure
 * 			  	  (structure type PrinterInfo)
 * 	DESTROYS: 	nothing
 * 
 * 	This function assumes that a specific device type has already been
 * 	setup in the PState via a DR_PRINT_SET_DEVICE call
 */
    DR_PRINT_DEVICE_INFO = 0x0E,

/*
 *  set printing mode
 * 	PASS: 		bx	= handle to PState
 * 			cl	= mode to print in
 * 			ax	= width of paper size (points)
 * 			si	= height of paper size (points)
 * 	RETURN:		nothing
 * 	DESTROYS: 	nothing
 * 
 * 	This function is used to set the device printing mode and some
 * 	paper options
 */
    DR_PRINT_SET_MODE = 0x10,

/*
 *  set final destination
 * 	PASS: 		bx	= handle to PState
 * 			cx	= stream token
 * 			dx	= stream device driver handle
 * 			si	= stream device type (PrinterPortType)
 * 	RETURN:		nothing
 * 	DESTROYS: 	nothing
 * 
 * 	This function is used to set the final destination (some I/O driver)
 * 	of the data that passes through the printer driver 
 */
    DR_PRINT_SET_STREAM = 0x12,


/*
 *  reset current position
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		nothing
 * 	DESTROYS: 	nothing
 * 
 * 	Sets the cursor back to 0,0
 */
    DR_PRINT_HOME_CURSOR = 0x14,

/* ---------------------------------------------------------------------------
 * 		Functions normally resident in other modules
 * 	see the definition of DR_PRINT_LAST_RESIDENT
 * ---------------------------------------------------------------------------*/

/*
 *  get current position
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		WWFixed:
 * 			cx.bx	= current x position of cursor
 * 			dx.ax	= current y position of cursor
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_GET_CURSOR = 0x16,


/*
 *  set current position
 * 	PASS: 		bx	= handle to PState
 * 			WWFixed:
 * 			cx.bx	= new x position of cursor
 * 			dx.ax	= new y position of cursor
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_SET_CURSOR = 0x18,

/*
 *  reset current position
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		dx.ax	= line spacing, WWFixed, in points
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_GET_LINE_SPACING = 0x1A,

/*
 *  reset current position
 * 	PASS: 		bx	= handle to PState
 * 			dx.ax	= line spacing, WWFixed, in points
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_SET_LINE_SPACING = 0x1C,

/*
 *  set a new font to use
 * 	PASS: 		bx	= handle to PState
 * 			cx	= desired FontID
 * 			dx	= desired point size
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 * 
 * 	This function will choose a default font (printer dependent) if the
 * 	desired font is not available.
 */
    DR_PRINT_SET_FONT = 0x1E,

/*
 *  return the color format
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		al	= BitMap Format enum
 * 	DESTROYS: 	nothing
 * 
 * 	Used for getting the format to send the bitmap to the print driver.
 */
    DR_PRINT_GET_COLOR_FORMAT = 0x20,

/*
 *  set new color for output
 * 	PASS: 		bx	= handle to PState
 * 			al	= R byte
 * 			dl	= G byte
 * 			dh	= B byte
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_SET_COLOR = 0x22,

/*
 *  get current mode settings
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		cx	= current text mode style bit settings
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_GET_STYLES = 0x24,

/*
 *  set current mode settings
 * 	PASS: 		bx	= handle to PState
 * 			dx	= style word to set (PrinterTextStyles record)
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_SET_STYLES = 0x26,

/*
 *  test for legal mode
 * 	PASS: 		bx	= handle to PState
 * 			dx	= style word to check (PrinterTextStyle record)
 * 	RETURN:		dx	= style word as it would be set
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_TEST_STYLES = 0x28,

/*
 *  print an ascii string
 * 	PASS: 		bx	= handle to PState
 * 			dx:si	= pointer to string
 * 			cx	= character count, or 0 for NULL-terminated
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_TEXT = 0x2A,

/*
 *  send unadulterated bytes
 * 	PASS: 		bx	= handle to PState
 * 			dx:si	= pointer to buffer
 * 			cx	= byte count
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_RAW = 0x2C,

/*
 *  print a style run
 * 	PASS: 		bx	= handle to PState
 * 			ax	= X offset into the PAPER area to start this
 * 					tile. for most one tile pages ax will be
 * 					the left printer margin value.
 * 			cx	= Y offset into the PAPER area to start this
 * 					tile. for most one tile pages cx will be
 * 					the top printer margin value.
 * 			dx:si	= pointer to style run info structure
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_STYLE_RUN = 0x2E,

/*
 *  print a page wide swath 
 * 	PASS: 		bx	= handle to PState
 * 			dx:si	= pointer to bitmap to print
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_SWATH = 0x30,

/*
 * start page stuff
 * 	PASS: 		bx	= handle to PState
 * 			cl	= flag to signal suppressformfeed mode
 * 					C_FF = normal form-feed at end of page;
 * 					else no form-feed, and cursor left at
 * 					next line down against the left margin.
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 * 
 * 	Sets the cursor back to 0,0
 */
    DR_PRINT_START_PAGE = 0x32,

/*
 * END page stuff
 * 	PASS: 		bx	= handle to PState
 * 			cl	= flag to signal suppressformfeed mode
 * 					C_FF = normal form-feed at end of page;
 * 					else no form-feed, and cursor left at
 * 					next line down against the left margin.
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 * 
 * 	Does form-feed
 */
    DR_PRINT_END_PAGE = 0x34,

/*
 *  get imageable area
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		ax	= left side coordinate   (points)
 * 			si	= top side coordinate    (points)
 * 			cx	= right side coordinate  (points)
 * 			dx	= bottom side coordinate (points)
 * 	DESTROYS: 	nothing
 * 
 * 	This function is used to set the size of the bitmap needed to
 * 	render the page.
 */
    DR_PRINT_GET_PRINT_AREA = 0x36,

/*
 *  get the margin info.
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		ax	= Left Margin 
 * 			si	= Top Margin
 * 			cx	= Right Margin
 * 			dx	= Bottom Margin
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_GET_MARGINS = 0x38,

/*
 *  get the paper path options.
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		al	= PaperInputOptions record
 * 			ah	= PaperOutputOptions record
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_GET_PAPER_PATH = 0x3A,

/*
 *  get the paper path options.
 * 	PASS: 		bx	= handle to PState
 * 			al	= PaperInputOptions record
 * 			ah	= PaperOutputOptions record
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_SET_PAPER_PATH = 0x3C,

/*
 *  do init for print job
 * 	PASS: 		bx	= handle to PState
 * 
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 * 
 * 	This function should be called when starting a print job.  It handles
 * 	any initialization required, and should be matched with a corresponding
 * 	DR_PRINT_END_JOB when the job is completed.  A job can span multiple
 * 	pages or documents (up to the caller to decide).
 */
    DR_PRINT_START_JOB = 0x3E,

/*
 *  deal w/death for print job
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 * 
 * 	This function should be called when ending a print job.  It handles
 * 	any shutting down required, and should be matched with a corresponding
 * 	DR_PRINT_START_JOB when the job is started.  
 */
    DR_PRINT_END_JOB = 0x40,


/*
 *  return OD for print DB
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		cx:dx	= OD of generic UI tree to place in print DB
 * 	DESTROYS: 	nothing
 * 
 * 	Return the OD of a generic tree to be duplicated and placed into
 * 	the main print dialog box.
 */
    DR_PRINT_GET_MAIN_UI = 0x42,

/*
 *  return OD for options
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		cx:dx	= OD of generic UI tree to place in options DB
 * 	DESTROYS: 	nothing
 * 
 * 	Return the OD of a generic tree to be duplicated and placed into
 * 	the options print dialog box.
 */
    DR_PRINT_GET_OPTIONS_UI = 0x44,

/*
 *  evaluate main print UI
 * 	PASS:		bx	= PState handle
 * 			cx	= Handle of the duplicated generic tree
 * 				  displayed in the main print dialog box.
 * 				  (= 0 to indicate do nothing)
 * 			dx	= Handle of the duplicated generic tree
 * 				  displayed in the options dialog box
 * 				  (= 0 to indicate do nothing)
 * 			es:si	= JobParameters structure
 * 			ax	= Handle of JobParameters block
 * 	RETURN: 	carry	= clear (success)
 * 				- or -
 * 			cx	= memory handle holding error message
 * 			carry	= set (failure)
 * 	DESTROYS:	nothing
 * 
 * 	Evaluate the contents of the generic tree(s) holding print UI objects,
 * 	and write directly into the JobParameters storing any needed state.
 * 
 * 	NOTE:		Data returned is internal to the print driver, and
 * 			is not read by the spooler or anyone else
 */
    DR_PRINT_EVAL_UI = 0x46,

/*
 *  evaluate main print UI
 * 	PASS:		bx	= PState handle
 * 			cx	= Handle of the duplicated generic tree
 * 				  displayed in the main print dialog box.
 * 				  (= 0 to indicate do nothing)
 * 			dx	= Handle of the duplicated generic tree
 * 				  displayed in the options dialog box
 * 				  (= 0 to indicate do nothing)
 * 			es:si	= JobParameters structure
 * 			ax	= Handle of JobParameters block
 * 	RETURN: 	nothing
 * 	DESTROYS:	nothing
 * 
 * 	Take the data written into JobParameters from a prior all to
 * 	DR_PRINT_EVAL_UI, and stuff it back into the UI object found
 * 	in the duplicated tree. 
 */
    DR_PRINT_STUFF_UI = 0x48,
} PrintFunction;

#define DR_PRINT_FIRST_PSTATE_NEEDED	(DRE_SET_DEVICE)

/*
 * declared in each printer - specific constants file. DJD 9-11-90
 * DR_PRINT_LAST_RESIDENT  =	DR_PRINT_HOME_CURSOR
 */

#define DR_PRINT_FIRST_MOD	(DR_PRINT_LAST_RESIDENT + 2)
#define DR_PRINT_LAST_GRAPHICS	(DR_PRINT_SWATH)
#define DR_PRINT_LAST_TEXT	(DR_PRINT_TEST_MODES)
#define DR_PRINT_LAST_FUNCTION	(DR_PRINT_TEST_MODES)

/* ---------------------------------------------------------------------------
 * 		Printer driver standard escapes
 * ---------------------------------------------------------------------------*/

/*
 *  codes from 0x8000-0x80ff are standard escape codes common
 *  to all drivers (see geode.def)
 */

/*
 *      standard printer escapes range from 0x8100 to 0xbfff
 *  user-defined printer escapes range from 0xc000 to 0xffff
 */

/* enum PrintEscCode */
typedef enum {		

/*
 *  print bitmap(LaserJet)
 * 	PASS:
 * 		bx	=	Handle to PState
 * 		dx:si	=	pointer to bitmap to print
 * 	RETURN:
 * 	DESTROYS:
 * 
 * 	This call prints a bitmap out at the current cursor location. It is
 * 	used for printing a less than full page of graphics. The bitmap is 
 * 	printed in the previously set resolution.
 */
    DR_PRINT_ESC_PRINT_BITMAP = 0x8100,


/*
 *  for PDL printers
 *      PASS:           bx      = handle to PState
 *                      dx:si   = pointer to TransMatrix
 *      RETURN:         nothing
 *      DESTROYS:       nothing
 * 
 *      This call establishes the transformation matrix that should be
 *      applied to all elements drawn on the current page.  This is used
 *      by the spooler to do rotation, thumbnails...
 */
    DR_PRINT_ESC_SET_PAGE_TRANSFORM,


/*
 *  for PDL printers
 *      PASS:           bx      = handle to PState
 *                      cx      = GString flags (record, type GSControl)
 *                      si      = GString handle
 *      RETURN:         ax      = GString return flags (enum GSRetType)
 *                      bx      = data returned with GSRetType	
 *      DESTROYS:       nothing
 * 
 *      This is the main drawing call for PDL printers.  The passed graphics
 *      string should be read and translated into the specific page
 *      description and passed onto the printer.  The GSControl flags
 *      that are passed are compatible with the flags expected by
 *      GrDrawGString and indicate when to stop drawing from the passed
 *      graphics string.  This may be called more than once per page.
 */
    DR_PRINT_ESC_PRINT_GSTRING,


/*
 *  color transfer func
 *      PASS:           bx      = handle to PState
 *      RETURN:         ax      = handle of block containing transfer tables
 *      DESTROYS:       nothing
 * 
 *      This function allows the printer drivers to adjust the color mapping 
 *      from RGB to RGB or to CMYK or to Gray.  A transfer function table is
 *      just an array of 256 bytes.  The mapping is done by a simple table
 *      lookup, using the raw component value.  The value in the array at that
 *      index is used in its place.  Thus there is one table for the grey
 *      mapping function (useful for monochrome printers), three tables for
 *      an RGB device (useful for film recorders), and four tables for a
 *      CMYK device (most color printers).
 */
    DR_PRINT_ESC_GET_COLOR_TRANSFER,

/*
 * set the number of copies
 * 	PASS:		bx	= handle of PState
 * 			ax	= number of copies desired
 * 	RETURN:		ax	= number of copies successfully set
 * 				(there may be a limit on the number of copies
 * 				available at the printer, and if the caller
 * 				tries to exceed that number, then ax will
 * 				reflect the max number available)
 * 			carry set by communication error.
 * 	DESTROYS:	nothing
 */
    DR_PRINT_ESC_SET_COPIES,

/*
 * prepend a page (or pages)
 * 	PASS:		bx	= handle of PState
 * 			ax	= handle of GState to draw to
 * 			cx	= handle of duplicated "Main" tree
 * 			dx	= handle of duplicated "Options" tree
 * 	RETURN:		nothing
 * 	DESTROYS:	nothing
 */
    DR_PRINT_ESC_PREPEND_PAGE,

/*
 * append a page (or pages)
 * 	PASS:		bx	= handle of PState
 * 			ax	= handle of GState to draw to
 * 			cx	= handle of duplicated "Main" tree
 * 			dx	= handle of duplicated "Options" tree
 * 	RETURN:		nothing
 * 	DESTROYS:	nothing
 */
    DR_PRINT_ESC_APPEND_PAGE,

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 * 	following are Print Escapes that may only be applicable for
 * 	dedicated word processors
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/*
 * initialize mechanism
 * 	PASS		bx	=  handle of PState
 *        RETURN:         nothing
 *        DESTROYS:       nothing
 * 
 *        This function initializes the printer mechanism without starting a
 * 	print job. Called at boot time for captive printer devices.
 */
    DR_PRINT_ESC_INIT_PRINT_ENGINE,

/*
 * Set printer TOD.
 * 	PASS:		bx      = handle of PState
 * 	RETURN:		nothing
 * 	DESTROYS:	nothing
 * 
 * 	This function sets the time and date in the printer using the DOS
 * 	(and GEOS) TOD values.
 */
    DR_PRINT_ESC_SET_TOD,

/*
 * cap the printhead.
 *        PASS:           bx      = handle of PState
 *        RETURN:         nothing
 *        DESTROYS:       nothing
 * 
 *        This function caps the printhead immediately.
 */
    DR_PRINT_ESC_CAP_HEAD,

/*
 * clean the printhead.
 *        PASS:           bx      = handle of PState
 *        RETURN:         nothing
 *        DESTROYS:       nothing
 * 
 *        This function cleans the printhead immediately.
 */
    DR_PRINT_ESC_CLEAN_HEAD,

/*
 * get any printer specific error
 * 	PASS		bx      = handle of PState
 * 	RETURNS:	(Printer specific)
 * 	DESTROYS:	(Printer specific)
 * 
 * 	This escape returns any printer-specific error codes.
 */
    DR_PRINT_ESC_GET_ERRORS,

/*
 * wait for the printer
 * 						  mechanicals to stop
 * 	PASS		bx      = handle of PState
 * 	RETURNS:	nothing
 * 	DESTROYS:	nothing
 */
    DR_PRINT_ESC_WAIT_FOR_MECH,

/*
 * park the printhead off the 
 * 						  printable area
 * 	PASS            bx      = handle of PState
 *        RETURNS:        nothing
 *        DESTROYS:       nothing
 */
    DR_PRINT_ESC_PARK_HEAD,

/*
 *  set current position
 * 	PASS: 		bx	= handle to PState
 * 			WWFixed:
 * 			cx.bx	= new x position of cursor
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_ESC_MOVE_IN_X_ONLY,

/*
 *  set current position
 * 	PASS: 		bx	= handle to PState
 * 			WWFixed:
 * 			dx.ax	= new y position of cursor
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_ESC_MOVE_IN_Y_ONLY,

/*
 *  Load paper
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_ESC_INSERT_PAPER,

/*
 *  Eject paper
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		carry set by communication error.
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_ESC_EJECT_PAPER,

/*
 *  return PrintJobLock
 * 	PASS: 		bx	= handle to PState
 * 	RETURN:		(Printer Specific)
 * 	DESTROYS: 	nothing
 * 			
 * 	This escape returns the state of a job (whether it is interruptable
 * 		or not)
 */
    DR_PRINT_ESC_GET_JOB_STATUS,

/*
 *  return PrintJobLock
 * 	PASS: 		bx	= handle to PState
 * 			al	- TRUE - job is in progress
 * 				- FALSE - job is not in progress
 * 	RETURN:		nothing
 * 	DESTROYS: 	nothing
 */
    DR_PRINT_ESC_SET_JOB_STATUS,
} PrintEscCode;


/* ---------------------------------------------------------------------------
 * 		Enums, Records and Structure Definitions
 * ---------------------------------------------------------------------------*/

/*
 *  PrintDevice enum
 *  This enum is filled out by each driver in its DriverInfo.asm file.
 *  It advances by two so that it can be used as an index into the 
 *  various info tables maintained in the DriverInfo resource.
 */
/* enum PrintDevice */
typedef enum {		/* CHECKME */
/*  invalid enum */
    PD_INVALID_DEVICE = 0xfffe,
} PrintDevice;


/*
 * ___________________________________________________________________________
 * 
 * 	The following enums and structures are used in the specific device
 * 	info resources.
 * ___________________________________________________________________________
 */

typedef ByteEnum PrinterTech;		/* CHECKME */
/*  raster technology */
#define PT_RASTER	0x0
/*  vector technology */
#define PT_VECTOR	0x1

typedef ByteFlags PrinterType;		/* CHECKME */
/* 5 bits unused */
/* 4 bits unused */
#define PrinterTech	(nil)
/* in graphics.def */
#define BMFormat	(nil | nil | nil)
#define BMFormat_OFFSET	-5

/*
 * Printer port information
 * These bits define how the PC/GEOS can communicate with
 * a device. The enums are defined to make things easier to 
 * read in source code, and SWAT.
 */

/* IEEE-488 bus devices. */
typedef ByteEnum IEEE488Connection;		/* CHECKME */
#define IC_NO_IEEE488	0x0
#define IC_IEEE488	0x1

/*
 * The print driver includes the port driver. This is useful for the 
 * FAX drivers, and anything that has its own custom interface.
 */
typedef ByteEnum CustomConnection;		/* CHECKME */
#define CC_NO_CUSTOM	0x0
#define CC_CUSTOM	0x1

/* SCSI bus devices */
typedef ByteEnum SCSIConnection;		/* CHECKME */
#define SC_NO_SCSI	0x0
#define SC_SCSI	0x1

/* Most common serial devices */
typedef ByteEnum RS232CConnection;		/* CHECKME */
#define RC_NO_RS232C	0x0
#define RC_RS232C	0x1

/* Most common parallel devices */
typedef ByteEnum CentronicsConnection;		/* CHECKME */
#define CC_NO_CENTRONICS	0x0
#define CC_CENTRONICS	0x1

/*
 * Output to a file. Most drivers will let you print to a file of
 * raw printer data, but the filesize for the high resolution bit-mapped
 * devices may be too large for some media.
 */
typedef ByteEnum FileConnection;		/* CHECKME */
#define FC_NO_FILE	0x0
#define FC_FILE	0x1

/* Appletalk/flashtalk network devices. */
typedef ByteEnum AppletalkConnection;		/* CHECKME */
#define AC_NO_APPLETALK	0x0
#define AC_APPLETALK	0x1

/*
 *  Printer Connection
 *  This record specifies the interfaces available for the device
 */
typedef ByteFlags PrinterConnections;		/* CHECKME */
/* 7 bits unused */
/*  future bits */
/* 1 bit unused */
/*  IEEE-488 device */
#define IEEE488Connection	(nil)
/*  printdriver custom port driver */
#define CustomConnection	(nil)
/*  SCSI device */
#define SCSIConnection	(nil)
/*  RS-232C serial device */
#define RS232CConnection	(nil)
/*  Centronics parallel device */
#define CentronicsConnection	(nil)
/*  raw output to a file */
#define FileConnection	(nil)
/*  apple/flashtalk device */
#define AppletalkConnection	(nil)


/*
 *  Printer Smarts
 *  determines whether driver takes gstrings or a built out bitmap
 */
typedef ByteEnum PrinterSmart;		/* CHECKME */
/*  do everything for me */
#define PS_DUMB_RASTER	0x0
/*  has scalable and downloadable fonts */
#define PS_DOES_FONTS	0x1
/*  can deal with raw graphics strings */
#define PS_PDL	0x2

	

typedef struct {
    word	PM_left;
    word	PM_top;
    word	PM_right;
    word	PM_bottom;
} PrinterMargins;


/*
 *  Paper Input
 *  This record specifies the type of paper path for the device.
 *  When used in the printer info structure, the 
 *  fields of the record indicate the quantity of 
 *  a given feature (for example, a "2" in the PIO_TRACTOR field 
 *  would indicate the device has two tractor feed units).
 *  However, when being passed to the printer driver to set the 
 *  desired paper path options for the current print job (see
 *  DR_PRINT_SET_MODE), the field indicates which one to select.  (for
 *  example, a "2" in the PIO_TRACTOR field would indicate that the
 *  driver should use tractor unit #2).
 */

typedef ByteEnum ManualFeed;
#define MF_NO_MANUAL		0x0	/* No Manual paper input. */
#define MF_MANUAL1		0x1	/* manual feed path #1 */
#define MF_MANUAL2		0x2	/* manual feed path #2 */
#define MF_MANUAL3		0x3	/* manual feed path #3 */

typedef ByteEnum TractorFeed;
#define TF_NO_TRACTOR		0x0	/* No Tractor Feed. */
#define TF_TRACTOR1		0x1	/* tractor feeder #1 */
#define TF_TRACTOR2		0x2	/* tractor feeder #2 */
#define TF_TRACTOR3		0x3	/* tractor feeder #3 */

typedef ByteEnum AutoSheetFeed;
#define ASF_NO_TRAY		0x0	/* No ASF trays */
#define ASF_TRAY1		0x1	/* ASF tray #1 */
#define ASF_TRAY2		0x2	/* ASF tray #2 */
#define ASF_TRAY3		0x3	/* ASF tray #3 */
#define ASF_TRAY4		0x4	/* ASF tray #4 */
#define ASF_TRAY5		0x5	/* ASF tray #5 */
#define ASF_TRAY6		0x6	/* ASF tray #6 */
#define ASF_TRAY7		0x7	/* ASF tray #7 */

typedef ByteFlags PaperInputOptions;
/* 1 bit unused */
#define ManualFeed		0x60	/* manual feed paths */
#define ManualFeed_OFFSET	5
#define AutoSheetFeed		0x1c	/* cut-sheet feed bins */
#define AutoSheetFeed_OFFSET	2
#define TractorFeed		0x03	/* tractor feed paths */
#define TractorFeed_OFFSET	0

/*
 *  Paper Output
 *  This record specifies the type of output path for the device
 *  It is very similar to the PaperInputOptions record in that the 
 *  number of output bins works the same way. Additional information
 *  is included for duplex modes, and the normal way that paper is
 *  outputted from the printer (only relevant for printers with ASF
 *  or manual paper inputs)
 */

/*
 * Output Copies specifies that the printer can produce multiple copies
 * of the page by itself. Used by the spooler to see if a page needs to
 * be sent to the printer multiple times or not.
 */
typedef ByteEnum OutputCopies;
#define OC_NO_COPIES		0x0	/* no multiple copies */
#define OC_COPIES		0x1	/* multiple copies */

/*
 *  Paper Sort Order
 *  This enum specifies how the paper is normally received in the
 *  output tray. 
 */

typedef ByteEnum PaperSorted;
#define PS_NORMAL		0x0	/* face down on output */
#define PS_REVERSE		0x1	/* face up on output */

typedef ByteEnum OutputDuplex;
#define OD_SIMPLEX		0x0	/* no duplex printing */
#define OD_DUPLEXLO		0x1	/* duplex printing, long edge bd */
#define OD_DUPLEXSO		0x2	/* duplex printing, short edge bd */

typedef ByteEnum StapledOutput;
#define SO_NO_STAPLER		0x0	/* no stapling the output */
#define SO_STAPLER		0x1	/* Stapler #1 */

typedef ByteEnum OutputSorter;
#define OS_NO_SORTER		0x0	/* no sorting the output. */
#define OS_SORTER		0x1	/* sorter #1 */

typedef ByteEnum OutputBin;
#define OB_NO_OUTPUTBIN		0x0	/* no bin (only for tractor only) */
#define OB_OUTPUTBIN1		0x1	/* Output Bin #1 */
#define OB_OUTPUTBIN2		0x2	/* Output Bin #2 */
#define OB_OUTPUTBIN3		0x3	/* Output Bin #3 */

typedef ByteFlags PaperOutputOptions;
/* 6 bits unused */
#define OutputCopies		0x80
#define PaperSorted		0x40	/* which way cut-sheets come out */
#define OutputDuplex		0x30	/* duplex printing features. */
#define OutputDuplex_OFFSET	0x04
#define StapledOutput		0x08	/* Stapled? */
#define OutputSorter		0x04	/* # of sorters */
#define OutputBin		0x03	/* # of output bins */
#define OutputBin_OFFSET	0x00

/* DO NOT CHANGE THE ORDER OF THESE! */
typedef ByteEnum PrinterCountryCode;
#define PCC_FRANCE	0x0
#define PCC_GERMANY	0x1
#define PCC_UK		0x2
#define PCC_DENMARK1	0x3
#define PCC_SWEDEN	0x4
#define PCC_ITALY	0x5
#define PCC_SPAIN1	0x6
#define PCC_JAPAN	0x7
#define PCC_NORWAY	0x8
#define PCC_DENMARK2	0x9
#define PCC_SPAIN2	0xa
#define PCC_LAT_AMERICA	0xb
#define PCC_LEGAL	0xc
#define PCC_USA		0xff


/* ---------------------------------------------------------------------------
 * 		Printer driver info block
 * ---------------------------------------------------------------------------*/

/*
 * 	The printer device info table is a pretty gnarled beast.  We want to
 * 	be able to store the device info for as many actual devices as the
 * 	driver supports, allowing for the situation where a single driver 
 * 	could support multiple devices that have slightly different device
 * 	info tables.  So the overall structure of the device info table is
 * 	a list of devices the driver supports, and an array of device info
 * 	structures that specify the info about each device.  Two devices can
 * 	use the same device info structure if they have the same attributes.
 * 
 * 	The device info structures contain all the info about the device, 
 * 	and includes info like what kind of paper is used, is it a color 
 * 	device, and the like.  This structure also describes which of the
 * 	PrinterMode (see above) the device supports, and the particular
 * 	attributes of those modes for that device.
 */


/*
 *  DEVICE INFO BLOCK
 *  This structure contains the info about a specific device.
 */

typedef struct {		/* CHECKME */

/*  device capabilities. */

    PrinterType	PI_type;
    PrinterConnections	PI_connect;
    PrinterSmart	PI_smarts;

/* custom start job routine. */
    word	PI_customEntry;
/* custom end job routine. */
    word	PI_customExit;

/*
 *  Offsets to mode property tables.  
 *  O means the mode is not supported GraphicsProperties is a 
 *  fixed structure, while TextProperties is an array of the 
 *  TextProperties structure with a variable number of elements 
 *  (depends on how many pitches are supported in that mode).
 */

/* 	NO_SCALE and TEXT_PROOF removed by Dave 4/3/90 */

/*  PM_GRAPHICS_LOW_RES */
    word    	PI_lowRes;
/*  PM_GRAPHICS_MED_RES */
    word	PI_medRes;
/*  PM_GRAPHICS_HI_RES */
    word	PI_hiRes;
/*  PM_TEXT_DRAFT */
    word	PI_draft;
/*  PM_TEXT_NLQ */
    word	PI_nlq;

/*  offset to the table of the font characteristics (geometries) */
/*
 *  offset of the list of font
 *  geometry information
 */
    word	PI_fontGeometries;

/*  offset to the table of the font Symbol Sets (code pages) */
/*
 *  offset of the list of font
 *  Symbol set setting codes
 *  there MUST be at least as 
 *  many entries here in each
 *  device info as in the UI rtn.
 */
    word	PI_fontSymbolSets;

/*  margins (defines extent of printable area) */

/*  Tractor (continuous) margins */
    PrinterMargins	PI_marginTractor;
/*  ASF Margins. */
    PrinterMargins	PI_marginASF;

/*  paper path support */

/* paper input selections */
    PaperInputOptions	PI_paperInput;
/* paper Output selections */
    PaperOutputOptions	PI_paperOutput;
/*
 *  width of largest paper size
 *   accepted by the printer.
 *  (in points)
 */
    word	PI_paperWidth;

/*  user interface components to be displayed in the print dialog box */

/*  OD of gentree for main DB */
    optr	PI_mainUI;
/*  OD of gentree for options DB */
    optr	PI_optionsUI;


/*
 *  offset of the eval routine to call to get the data from the generic tree.
 */
    word	PI_evalRoutine;

} PrinterInfo;

/* offset to mode table. */
#define PI_firstMode	(PI_lowRes)

/* ---------------------------------------------------------------------------
 *  GRAPHICS MODE INFO STRUCTURE
 * ---------------------------------------------------------------------------
 *  attributes stored for each graphics mode
 */

typedef struct {		/* CHECKME */
/*  x resolution, dpi */
    word	GP_xres;
/*  y resolution, dpi */
    word	GP_yres;
/*  height of each band */
    byte	GP_bandHeight;
/*  height of each buffer */
    byte	GP_buffHeight;
/*
 *  interleave factor.
 *  offset in scanlines to next
 *  scanline for buffer.
 */
    byte	GP_interleaveFactor;
/*  1,4,8 or 24 bits/pixel */
    byte	GP_colorFormat;

/* pointer to color correction table. */

    word	GP_colorCorrection;
} GraphicsProperties;


/* ---------------------------------------------------------------------------
 *  	FONT INFO STRUCTURE
 * ---------------------------------------------------------------------------*/

/*
 *  enum for the more normal pitch modes.  The value stored is actually
 *  10 times the pitch number
 */
typedef ByteEnum TextPitch;		/* CHECKME */
/*  flag for prop font */
#define TP_PROPORTIONAL	0x0
/*  5 cpi */
#define TP_5_PITCH	0x1
/*  6 cpi */
#define TP_6_PITCH	0x2
/*  10 cpi */
#define TP_10_PITCH	0x3
/*  10.6 cpi */
#define TP_10_6_PITCH	0x6a
/*  12 cpi */
#define TP_12_PITCH	0x6b
/*  15 cpi */
#define TP_15_PITCH	0x6c
/*  16 cpi */
#define TP_16_PITCH	0x6d
/*  16.6 cpi */
#define TP_16_6_PITCH	0xa6
/*  17 cpi */
#define TP_17_PITCH	0xa7
/*  19.2 cpi */
#define TP_19_2_PITCH	0xc0
/*  20 cpi */
#define TP_20_PITCH	0xc1
/*  21.3 cpi */
#define TP_21_3_PITCH	0xd5
/*  24 cpi */
#define TP_24_PITCH	0xd6

/*
 *  PrinterSymbolSet
 *  This enum is stored with each font entry in the printer's device
 *  info table to indicate how the upper 128 characters of 8-bit ascii
 *  codes should be translated from the GEOS set to the printer's set.
 * 
 *  NOTE: If you add another enumerated type to this table, you MUST
 * 	create a translation table and add it to the spool library.
 * 	See the routine UpdateTranslationTable in the file 
 * 	Spool/Lib/libDriver.asm to see how this enum is used,
 * 	and one of the existing resources 
 * 	(e.g. Spool/Lib/libIBM8bitTab.asm) for an example of how to
 * 	format the table.  thanks.
 */
/*   */
/* enum PrinterSymbolSet */
typedef enum {		/* CHECKME */
/*  7-bit ascii (no 8 bit codes) */
    PSS_ASCII7 = 0x0,
/*  IBM Code Page 437 set */
    PSS_IBM437 = 0x2,
/*  IBM Code Page 850 set */
    PSS_IBM850 = 0x4,
/*  IBM Code Page 860 set */
    PSS_IBM860 = 0x6,
/*  IBM Code Page 863 set */
    PSS_IBM863 = 0x8,
/*  IBM Code Page 865 set */
    PSS_IBM865 = 0xa,
/*  Roman-8 (HP LaserJet) */
    PSS_ROMAN8 = 0xc,
/*  MS Windows  */
    PSS_WINDOWS = 0xe,
/*  Ventura (HP LaserJet) */
    PSS_VENTURA = 0x10,
/*  Latin set (HP LaserJet) */
    PSS_LATIN1 = 0x12,
/*  PCGEOS encoding */
    PSS_PCGEOS = 0x14,
} PrinterSymbolSet;

/*  bits for each type of settable attribute  */

typedef WordFlags PrintTextStyle;
#define PTS_CONDENSED	0x8000		/*  bit for condensed mode */
#define PTS_SUBSCRIPT	0x4000		/*  bit for subscript */
#define PTS_SUPERSCRIPT	0x2000		/*  bit for superscript */
#define PTS_NLQ		0x1000		/*  bit for NLQ mode */
#define PTS_BOLD	0x0800		/*  bit for bold */
#define PTS_ITALIC	0x0400		/*  bit for italic */
#define PTS_UNDERLINE	0x0200		/*  bit for underline */
#define PTS_STRIKETHRU	0x0100		/*  bit for strike-thru */
#define PTS_SHADOW	0x0080		/*  bit for shadowed */
#define PTS_OUTLINE	0x0040		/*  bit for outlined */
#define PTS_REVERSE	0x0020		/*  bit for reversed */
#define PTS_DBLWIDTH	0x0010		/*  bit for extra wide */
#define PTS_DBLHEIGHT	0x0008		/*  bit for extra high */
#define PTS_QUADHEIGHT	0x0004		/*  bit for extra-extra high */
#define PTS_OVERLINE	0x0002		/*  bit for over score (above) */
#define PTS_FUTURE	0x0001		/*  bit for future features */

/*
 *  Internal Fonts
 *  This structure is used to build a table of the fonts that are 
 *  available on the device.  
 */

typedef struct {		/* CHECKME */
/*  value to pass to select font */
    FontID		FE_fontID;
/*  size in points, 0 for any size */
    word		FE_size;
/*  pitch (for non-prop fonts) */
    TextPitch	FE_pitch;
/*  enum to specify char set */
    PrinterSymbolSet	FE_symbolSet;
/*  offset of the control code */
    word	FE_command;
/*  legal style bits */
    PrintTextStyle	FE_styles;
/*  mandatory style bits */
    PrintTextStyle	FE_stylesSet;
} FontEntry;

/*
 *  Optional font data used by special print drivers to do *special*
 *  things.......
 *  NOTE: not present in the device specific structures.
 */

typedef struct {
/* RGB values */
    RGBValue	OFE_color;
/* integer space padding. */
    word	OFE_spacePad;
/* trackKerning. */
    sword	OFE_trackKern;
/* custom weight.... */
    byte	OFE_fontWeight;
/* custom weight... */
    byte	OFE_fontWidth;
} OptFontEntry;

/*
 *  This structure has a FontID, its size, and a pointer to a table
 *  of pitch values. There is one of these structures for each size
 *  of each available font.
 */

typedef struct {		/* CHECKME */
/* font enum. */
    FontID	FG_fontID;
/* size for this set of pitches */
    word	FG_pointSize;
/* pointer to table of pitches */
    word	FG_pitchTab;
} FontGeometry;

/*
 * ___________________________________________________________________________
 * 
 *  Enummerated types, and structures used in the general driver info file.
 * ___________________________________________________________________________
 */

/* enum PrinterResend */
typedef enum {		/* CHECKME */
/*  dont resend char. after error. */
    PR_DONT_RESEND = 0x0,
/*  do resend char. after error. */
    PR_RESEND,
} PrinterResend;

/*  OVERALL DRIVER INFO HEADER */
typedef struct {		/* CHECKME */
/*  # seconds to set for timeout */
    word	PDI_timeoutValue;
    PrinterResend	PDI_resendOrNot;
/*  ISO substitution char table */
    word	PDI_subISOTable;
/*  lower ascii translation table */
    word	PDI_asciiTransChars;
/*  what type of printer driver */
    PrinterDriverType	PDI_driverType;
/*  what UI should be displayed */
    word	PDI_uiFeatures;
} PrintDriverInfo;

/*
 * ___________________________________________________________________________
 * 
 * 		PState Structure
 * ___________________________________________________________________________
 */

typedef struct {

/*  device variables */
/*  current printing mode */

    PrinterMode	PS_mode;

/* device enum (defined in each drivers DriverInfo.asm) */
    PrintDevice	PS_device;

/*  technology used by printer. */
    PrinterType	PS_printerType;

/*  printers capabilities. */
    PrinterSmart	PS_printerSmart;

/*  handle ptr to info block */
    word	PS_deviceInfo;

/*  handle ptr to info block */
    word	PS_expansionInfo;

/*  handle to the resource containing the printer fonts. */
    word	PS_fontInfo;

/*  input selections */
    PaperInputOptions 	PS_paperInput;

/*  output selections */
    PaperOutputOptions	PS_paperOutput;

/*  custom paper width */
    word	PS_customWidth;

/*  custom paper height */
    word	PS_customHeight;

/*  margins for this mode. */
    PrinterMargins	PS_currentMargins;

/*  current state variables */
/*  cursor position, points */
    Point	PS_cursorPos;

/*  buffer variables */
/*  handle of working block */
    word	PS_bufHan;

/*  segment of locked working blk */
    word	PS_bufSeg;

/*  size of allocated buffer */
    word	PS_bufSize;

/*  stream variables */
/*  stream interface token */
    word	PS_streamToken;

/*  PrinterPortType enum */
    word	PS_streamType;

/*  far address of i/o driver  */
    dword	PS_streamStrategy;

/*  graphics mode variables */

/*  error flag (0=no error) */
    byte	PS_error;

/*  height of band (scan lines) */
    word	PS_bandHeight;

/* height of band buffer (scan lines) */
    word	PS_buffHeight;

/*  pixel width of swath  */
    word	PS_bandWidth;

/*  byte width of swath  */
    word	PS_bandBWidth;

/* width of internal buffer Huge Bitmap variables */
    word	PS_intWidth;

/*  bitmap header for swath */
    Bitmap 	PS_swath;

/*  VM file and block handle */
    dword	PS_bitmap;

/*  number of interleaves. */
    word	PS_interleaveFactor;

/*  offset to current scan line */
    word	PS_curScanOffset;

/* number of current color in this scanline (from 0-3) */
    word	PS_curColorNumber;

/* new scan line number to be used by the HA stuff */
    word	PS_newScanNumber;

/*  current scan line number */
    word	PS_curScanNumber;

/*  starting scanline number in current block */
    word	PS_firstBlockScanNumber;

/* last scanline number in current block */
    word	PS_lastBlockScanNumber;

/*  text mode variables */
/*  text style bits */
    PrintTextStyle	PS_asciiStyle;

/*  line spacing  */
    word	PS_asciiSpacing;

/*  legal style/pitch combination table.  copied from dev info table */
/*  room for a font description */
    FontEntry	PS_curFont;

/*  rest of TextAttrs copied from GState.*/
    OptFontEntry	PS_curOptFont;

/*  number of the previous attr. */
    word	PS_previousAttribute;

/*  translation table for foreign ascii printing (normal 7-bit ascii) */
/*  room for all of ascii  */
    byte 	PS_asciiTrans[256];

/*  job parameters block. */
/** JobParameters	PS_jobParams; **/

/*
 *  WARNING! - because JobParameters is a variable-sized structure,
 *  using (size PState) is a potentially dangerous thing to do.
 *  You'll want to consult the size field JP_size when determining
 *  the overall size of JobParameters, and hence the PSTate
 */

} PState;

/* ------------------------------------------------------------------------------
 *        Internal structure used by the Print Driver UI code.
 * ------------------------------------------------------------------------------
 * this is stuck in the JobParamemters block at offset JP_printerData
 */

typedef struct {		/* CHECKME */
/* from options */
    PaperInputOptions	PUID_paperInput;
/* from main */
    PaperOutputOptions	PUID_paperOutput;
/* from options */
    word    PUID_amountMemory;
/* from options */
    byte    PUID_initMemory;
/* from options */
    byte    PUID_compressionMode;
/* from options */
    PrinterSymbolSet	PUID_symbolSet;
/* from options */
    PrinterCountryCode	PUID_countryCode;
} PrintDriverUIData;

/*
 * ___________________________________________________________________________
 * 
 * 	Error and status codes
 * ___________________________________________________________________________


/* ---------------------------------------------------------------------------
 * 		Possible Returned Error Codes 
 * ---------------------------------------------------------------------------*/

/* enum PrinterError */
typedef enum {		/* CHECKME */
/*  printer timeout error */
    PERROR_TIMEOUT = 0x0,
/*  printer warming up */
    PERROR_WARMUP = 0x2,
/*  printer needs servicing */
    PERROR_SERVICE = 0x4,
/*  paper entry misfeed */
    PERROR_PAPER_MISFEED = 0x6,
/*  no printer found */
    PERROR_NO_PRINTER = 0x8,
/*  printer out of toner */
    PERROR_NO_TONER = 0xa,
/*  printer out of paper */
    PERROR_NO_PAPER = 0xc,
/*  printer off line */
    PERROR_OFF_LINE = 0xe,
/*  some serial port error */
    PERROR_SERIAL_ERR = 0x10,
/*  some parallel port error */
    PERROR_PARALLEL_ERR = 0x12,
/*  some network error */
    PERROR_NETWORK_ERR = 0x14,
/*  bogus BUSY condition */
    PERROR_SOME_PROBLEM = 0x16,
/*
 *  some port error that says
 *   job must be canceled.
 */
    PERROR_FATAL = 0x18,
/*  file system full */
    PERROR_FILE_SYSTEM_FULL = 0x1a,
/*  file system error */
    PERROR_FILE_SYSTEM_ERROR = 0x1c,
} PrinterError;
	
/*  no error detected */
#define PERROR_NO_ERROR	(08000h)

/* ---------------------------------------------------------------------------
 * 		Possible Returned Status Codes 
 * ---------------------------------------------------------------------------*/

/* enum PrinterStatus */
typedef enum {		/* CHECKME */
/*  printer not in use */
    PS_IDLE = 0x0,
/*  printer in use */
    PS_BUSY = 0x2,
/*  printer waiting for input */
    PS_WAITING = 0x4,
/*  printer printing a page */
    PS_PRINTING = 0x6,
/*  printer in warmup stage */
    PS_WARMING_UP = 0x8,
} PrinterStatus;

