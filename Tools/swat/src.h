/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  Swat
 * MODULE:	  Source-File Mapping
 * FILE:	  src.h
 *
 * AUTHOR:  	  Adam de Boor: Sep 29, 1992
 *
 * REVISION HISTORY:
 *	Name	  Date	    Description
 *	----	  ----	    -----------
 *	ardeb	  9/29/92    Initial version
 *
 * DESCRIPTION:
 *	Interface to the Src module.
 *
 *
 * 	$Id: src.h,v 1.3 97/04/18 16:40:21 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _SRC_H_
#define _SRC_H_

#include    <st.h>

extern Boolean Src_MapAddr(Handle handle, Address offset,
			   Patient *patientPtr,
			   ID *filePtr,
			   int *linePtr);

extern Boolean Src_FindLine(Patient 	    patient,
			    char    	    *file,
			    int	    	    line,
			    Handle  	    *handlePtr,
			    word    	    *offsetPtr);

extern int Src_ReadLine(Tcl_Interp	    *interp,
			char    	    *file,
			char    	    *lineNum,
			char    	    *numLines, 
			char    	    *data,
			unsigned short	    *doubleByteData);
			    	
extern void Src_Init(void);

#if defined(_WIN32)
/* 
 * needed for handling japanese characters (SJIS)
 */
# define SJIS_DB1_START_1	0x81
# define SJIS_DB1_END_1		0x9f
# define SJIS_DB1_START_2	0xe0
# define SJIS_DB1_END_2		0xef

# define SJIS_DB2_START_1	0x40
# define SJIS_DB2_END_1		0x7e
# define SJIS_DB2_START_2	0x80
# define SJIS_DB2_END_2		0xfc

# define SJIS_SB_START_1	0x00
# define SJIS_SB_END_1		0x7e
# define SJIS_SB_START_2	0xa1
# define SJIS_SB_END_2		0xdf


# define SJIS_DBCS_START_1	(SJIS_DB1_START_1 << 8) + SJIS_DB2_START_1
# define SJIS_DBCS_END_1	(SJIS_DB1_END_1 << 8) + 0xff
# define SJIS_DBCS_START_2	(SJIS_DB1_START_2 << 8) + SJIS_DB2_START_1
# define SJIS_DBCS_END_2	(SJIS_DB1_END_2 << 8) + 0xff
#endif  /* _WIN32 */

#endif /* _SRC_H_ */
