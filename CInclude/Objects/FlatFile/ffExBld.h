/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Flat file expression builder
 * FILE:	  ffExBld.h
 *
 * AUTHOR:  	  Jeremy Dashe: Feb  7, 1992
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	2/ 7/92	  jeremy    Initial version
 *
 * DESCRIPTION:
 *	This file contains structures and definitions for the flat file
 *	expression builder UI controller.
 *
 *
 * 	$Id: ffExBld.h,v 1.1 97/04/04 15:50:41 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _FFEXBLD_H_
#define _FFEXBLD_H_

/*
 * This defines the context for the available spreadsheet functions.
 * This array indicates whether or not a function is to be listed
 * in the "Functions" list of the flat file expression builders.
 * 
 *   The elements of the context array correspond to the function IDs
 * in the parse library.  Each element is a bit mask: if a particular
 * expression builder's bit is set for a function, that function is
 * added to the function list.
 *
 */

#ifndef FFEBFunctionContext
typedef	word FFEBFunctionContext;
#endif

#define	isalphanum(x)	(isalpha(x) || isdigit(x))

/* Function contexts */
#define	FFEBFC_DEFAULTS		(0x20)	/* 00000000 00100000 */
#define	FFEBFC_SUBSETS	    	(0x10)	/* 00000000 00010000 */
#define	FFEBFC_TOTALS	    	(0x08)	/* 00000000 00001000 */
#define	FFEBFC_SUBTOTALS	(0x04)	/* 00000000 00000100 */
#define	FFEBFC_SEARCHES		(0x02)	/* 00000000 00000010 */
#define	FFEBFC_COMPUTED_FIELDS	(0x01)	/* 00000000 00000001 */

#define	FFEBFC_ALL  	    	(0x3f)	/* 00000000 00111111 */
#define	FFEBFC_NONE  	    	(0)	/* 00000000 00000000 */

    	    	    	    	    	/* 00000000 00110001 */
#define	FFEBFC_TSD_AND_C	(FFEBFC_SUBSETS	    	| \
				 FFEBFC_DEFAULTS	| \
				 FFEBFC_COMPUTED_FIELDS)

/*
 * Here are the operator strings and IDs for the scropping operator lists.
 */

/* Math operators */
#define MODULO_STRING	    	"%"
#define EXPONENT_STRING	    	"^"
#define MULTIPLY_STRING	    	"*"
#define DIVISION_STRING	    	"\326" 
#define PLUS_STRING 	    	"+"
#define MINUS_STRING	    	"-"
#define LEFT_PARENS_STRING    	"\050"
#define RIGHT_PARENS_STRING 	")"

/* Logical operators */
#define AMPERSAND_STRING     	"&"
#define EQUALS_STRING 	    	"="
#define	NOTEQUAL_STRING	    	"\255"
#define LESSTHAN_STRING     	"<"
#define GREATERTHAN_STRING  	">"
#define	LESSEQUAL_STRING    	"\262"
#define	GREATEREQUAL_STRING 	"\263"

/* Define the longest string length for any operator. */
#define MAX_OPERATOR_LENGTH 	4

typedef ByteEnum OperatorIDs;
#define     FFEB_MODULO_ID  0
#define     FFEB_EXPONENT_ID 1
#define     FFEB_MULTIPLY_ID 2
#define     FFEB_DIVISION_ID 3
#define     FFEB_PLUS_ID 4
#define     FFEB_MINUS_ID 5
#define     FFEB_LEFT_PARENS_ID 6
#define     FFEB_RIGHT_PARENS_ID 7
#define     FFEB_AMPERSAND_ID 8
#define     FFEB_EQUALS_ID 9
#define     FFEB_NOTEQUAL_ID 10
#define     FFEB_LESSTHAN_ID 11
#define     FFEB_GREATERTHAN_ID 12
#define     FFEB_LESSEQUAL_ID 13
#define     FFEB_GREATEREQUAL_ID 14

#endif /* _FFEXBLD_H_ */
