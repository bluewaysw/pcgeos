/*********************************************************************/
/*								     */
/*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     */
/*								     */
/* 	PROJECT:	PC GEOS					     */
/* 	MODULE:							     */	
/* 	FILE:		isfile.h				     */
/*								     */
/*	AUTHOR:		jimmy lefkowitz				     */
/*								     */
/*	REVISION HISTORY:					     */
/*								     */
/*	Name	Date		Description			     */
/*	----	----		-----------			     */
/*	jimmy	1/27/92		Initial version			     */
/*								     */
/*	DESCRIPTION:						     */
/*								     */
/*	$Id: isfile.h,v 1.1 97/04/07 11:28:18 newdeal Exp $
/*							   	     */
/*********************************************************************/

 
struct strFilterList
   {
   char    *flExtension;
   char    *flDescription;
   char    *flType;            // "B" or "V"
   };
 
extern struct strFilterList flFaxExportFilter[];
 
#define TYPE_DRAW      1   // PIC extensions
#define TYPE_STORY     2
#define TYPE_PICT      3
#define TYPE_HALO      4
 
#define BMP_WIN20      5
#define BMP_WIN30      6
#define BMP_PM10       7
 
#define S_STORYBD      "IBM Storyboard"
#define S_DRHALO       "Dr. Halo"
#define S_PAINTBRUSH   "PaintBrush"
#define S_TIFF         "TIFF"
#define S_BITMAP       "Windows/OS2 Bitmap"
#define S_CLPBDBMP     "Windows Clipboard Bitmap"
 
#define FAX_GENERIC    "CCITT Group III Fax"
#define FAX_INTEL      "Intel FAX Board"
#define FAX_OAZ        "OAZ Fax Board"
#define FAX_RICOH      "Ricoh FAXNET"
#define FAX_XFX        "JetFAX"
#define FAX_JT         "JT FAX"
#define FAX_IMAVOX     "IMAVOX TurboFax"
#define FAX_GAMMA      "GammaLink"
#define FAX_FRECOM     "Frecom Fax/9600"
#define FAX_TELEFAX    "Telefax"

