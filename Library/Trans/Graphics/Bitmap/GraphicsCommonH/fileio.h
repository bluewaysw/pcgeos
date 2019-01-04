/*********************************************************************/
/*								     */
/*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     */
/*								     */
/* 	PROJECT:	PC GEOS					     */
/* 	MODULE:							     */	
/* 	FILE:		fileio.h				     */
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
/*	$Id: fileio.h,v 1.1 97/04/07 11:28:20 newdeal Exp $          */
/*							   	     */
/*********************************************************************/


#ifndef FLATMEMORY


#ifndef _FILEIO_

#define _FILEIO_
#include <file.h>
    


#define _llseek(fh,offset,mode)     ( fseek((fh),(offset),(mode)),ftell(fh))

/* The following C routines are called with siz being a DWORD, whereas the 
   corresponding AnsiC routines take words. The check is to ensure that
   siz does not exceed a word ( MS )
       _lwrite returns bytes read, if less than requested, generally considered an error.
*/

#define _lwrite(fh,buf,siz)  fwrite((buf),1,(siz),(fh))

/* lfread and lfwrite return num bytes read, not num elements, as does fread
   and fwrite */

#define lfread 	fread
#define lfwrite fwrite

#endif

#endif




