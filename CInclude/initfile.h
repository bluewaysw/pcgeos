/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	initfile.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines .ini file structures and routines.
 *
 *	$Id: initfile.h,v 1.1 97/04/04 15:58:03 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__INITFILE_H
#define __INITFILE_H

extern void	/*XXX*/
    _pascal InitFileWriteData(const char *category, const char *key,
		      const void *buffer, word bufSize);

/***/

extern void	/*XXX*/
    _pascal InitFileWriteString(const char *category, const char *key, const char *str);

/***/

extern void	/*XXX*/
    _pascal InitFileWriteInteger(const char *category, const char *key, word value);

/***/

extern void	/*XXX*/
    _pascal InitFileWriteBoolean(const char *category, const char *key, Boolean bool);

/***/

extern void 	/*XXX*/
    _pascal InitFileWriteStringSection(const char *category,
			       const char *key,
			       const char *string);

/***/

extern Boolean		/* true if error */	/*XXX*/
    _pascal InitFileReadDataBuffer(const char *category,
			   const char *key,
			   void *buffer,
			   word bufSize,
			   word *dataSize);

extern Boolean		/* true if error */	/*XXX*/
    _pascal InitFileReadDataBlock(const char *category,
			  const char *key,
			  MemHandle *block,
			  word *dataSize);

/***/

#define	MAX_INITFILE_CATEGORY_LENGTH 64

typedef ByteEnum InitFileCharConvert;
#define IFCC_INTACT 0
#define IFCC_UPCASE 1
#define IFCC_DOWNCASE 2

typedef WordFlags InitFileReadFlags;
#define IFRF_CHAR_CONVERT	0xc000
#define IFRF_READ_ALL	        0x2000
#define IFRF_FIRST_ONLY	    	0x1000
#define IFRF_SIZE		0x0fff

#define IFRF_CHAR_CONVERT_OFFSET 14

/*
 *  An enumerated type for specifying a category/key
 *  combination in the INI-file.  Used in conjunction
 *  with the GCNSLT_NOTIFY_INIT_FILE_CHANGE GCN list;
 *  an etype is used because passing the actual key  
 *  and category would force clients to do costly
 *  string comparisons, which would degrade system
 *  performance.
 */
typedef enum {
  IFE_DATE_TIME_FORMAT=0,
  IFE_NUMBER_FORMAT=1,
  IFE_SYSTEM_SOUND=2,
  IFE_INK_THICKNESS=3,
  IFE_CURRENCY_FORMAT=4,
  IFE_PUNCTUATION=5,
  IFE_OWNER_INFO=6
} InitFileEntry;

extern Boolean		/* true if error */	/*XXX*/
    _pascal InitFileReadStringBuffer(const char *category, const char *key,
			     char *buffer,
			     InitFileReadFlags flags, word *dataSize);

extern Boolean		/* true if error */	/*XXX*/
    _pascal InitFileReadStringBlock(const char *category, const char *key,
			   MemHandle *block, InitFileReadFlags flags,
			   word *dataSize);

/***/

extern Boolean		/* true if error */	/*XXX*/
    _pascal InitFileReadStringSectionBuffer(const char *category,
				    const char *key,
				    word section,
				    char *buffer,
				    InitFileReadFlags flags,
				    word *dataSize);

extern Boolean		/* true if error */	/*XXX*/
    _pascal InitFileReadStringSectionBlock(const char *category, const char *key,
				  word section, MemHandle *block,
				  InitFileReadFlags flags, word *dataSize);

/***/

extern Boolean	    	/* true if error */ 	/*XXX*/
    _pascal InitFileEnumStringSection(const char *category,
			      const char *key,
			      InitFileReadFlags flags,
			      PCB(Boolean, callback,   /* TRUE to stop */
			      	      (const char *stringSection,
				       word sectionNum,
				       void *enumData)),
			      void *enumData);

/***/

extern Boolean		/* true if error */	/*XXX*/
    _pascal InitFileReadInteger(const char *category, const char *key, word *i);

/***/

extern Boolean	    	/* true if error */ 	/*XXX*/
    _pascal InitFileReadAllInteger(const char *category,
			      const char *key,
			      PCB(Boolean, callback,   /* TRUE to stop */
			      	      (word integerValue,
				       void *enumData)),
			      void *enumData);

/***/

extern Boolean		/* true if error */	/*XXX*/
    _pascal InitFileReadBoolean(const char *category, const char *key, Boolean *bool);

/***/

extern dword	/*XXX*/
    _pascal InitFileGetTimeLastModified(void);

/***/

extern Boolean		/* true if error */	/*XXX*/
    _pascal InitFileSave(void);

/***/

extern Boolean		/* true if error */	/*XXX*/
    _pascal InitFileRevert(void);

/***/

extern void	/*XXX*/
    _pascal InitFileCommit(void);

/***/

extern void 	/*XXX*/
    _pascal InitFileDeleteStringSection(const char *category,
				const char *key,
				word stringNum);

/***/

extern void	/*XXX*/
    _pascal InitFileDeleteEntry(const char *category, const char *key);

/***/

extern void	/*XXX*/
    _pascal InitFileDeleteCategory(const char *category);

extern word
    _pascal InitFileGrab(MemHandle mem,	FileHandle fh,	word size); 

extern void
    _pascal InitFileRelease(void);

extern void
    _pascal InitFileMakeCanonicKeyCategory(char *keyCat, const TCHAR *src);

#ifdef __HIGHC__
pragma Alias(InitFileWriteData, "INITFILEWRITEDATA");
pragma Alias(InitFileWriteString, "INITFILEWRITESTRING");
pragma Alias(InitFileWriteInteger, "INITFILEWRITEINTEGER");
pragma Alias(InitFileWriteBoolean, "INITFILEWRITEBOOLEAN");
pragma Alias(InitFileWriteStringSection, "INITFILEWRITESTRINGSECTION");
pragma Alias(InitFileReadDataBuffer, "INITFILEREADDATABUFFER");
pragma Alias(InitFileReadDataBlock, "INITFILEREADDATABLOCK");
pragma Alias(InitFileReadStringBuffer, "INITFILEREADSTRINGBUFFER");
pragma Alias(InitFileReadStringBlock, "INITFILEREADSTRINGBLOCK");
pragma Alias(InitFileReadStringSectionBuffer, "INITFILEREADSTRINGSECTIONBUFFER");
pragma Alias(InitFileReadStringSectionBlock, "INITFILEREADSTRINGSECTIONBLOCK");
pragma Alias(InitFileEnumStringSection, "INITFILEENUMSTRINGSECTION");
pragma Alias(InitFileReadInteger, "INITFILEREADINTEGER");
pragma Alias(InitFileReadAllInteger, "INITFILEREADALLINTEGER");
pragma Alias(InitFileReadBoolean, "INITFILEREADBOOLEAN");
pragma Alias(InitFileGetTimeLastModified, "INITFILEGETTIMELASTMODIFIED");
pragma Alias(InitFileSave, "INITFILESAVE");
pragma Alias(InitFileRevert, "INITFILEREVERT");
pragma Alias(InitFileCommit, "INITFILECOMMIT");
pragma Alias(InitFileDeleteStringSection, "INITFILEDELETESTRINGSECTION");
pragma Alias(InitFileDeleteEntry, "INITFILEDELETEENTRY");
pragma Alias(InitFileDeleteCategory, "INITFILEDELETECATEGORY");
pragma Alias(InitFileGrab, "INITFILEGRAB");
pragma Alias(InitFileRelease, "INITFILERELEASE");
pragma Alias(InitFileMakeCanonicKeyCategory, "INITFILEMAKECANONICALKEYCATEGORY");
#endif

#endif
