/*********************************************************************/
/*								     */
/*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     */
/*								     */
/* 	PROJECT:	PC GEOS					     */
/* 	MODULE:							     */	
/* 	FILE:		ccitt.h				     */
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
/*	$Id: ccitt.h,v 1.1 97/04/07 11:28:16 newdeal Exp $
/*							   	     */
/*********************************************************************/


typedef struct S_T4 
   {
   int  cd,    // code                
        bc,    // bit count of the code    
        rl,    // run length            
        mk;    // masking of the code
   } T4;


extern int whtcnt, blkcnt;
extern T4 wht[], blk[], whtsrt[], blksrt[];
extern T4 whttbl[], blktbl[];

