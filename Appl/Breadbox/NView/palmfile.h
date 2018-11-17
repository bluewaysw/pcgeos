/*
 *      PALMFILE.H - access routines for PalmOS files from Geos
 *
 *      by Marcus Groeber, mgroeber@compuserve.com
 *
 */

/* "Endian" conversions between Geos and PalmOS */
#define PalmWORD(w) ( (((word)(w))>>8) | (((word)(w))<<8) )
#define PalmDWORD(d) ( PalmWORD((d)>>16) | (((dword)PalmWORD(d))<<16) )

/* Opaque handle used for refering to an open file in PalmOS DB format. */
typedef MemHandle PalmDBHandle;

/* Open a Palm DB file, given its DOS name. */
PalmDBHandle PalmDBOpenDOS(char *dosname);

/* Close a Palm DB file. */
void PalmDBClose(PalmDBHandle db);

/* Read a record from a Palm DB file to a newly allocated block on the heap. */
MemHandle PalmDBReadRec(PalmDBHandle db, word recnr, word *size);

/* Get info about Palm database */
dword PalmDBGetInfo(PalmDBHandle db, word infoType);
  #define PALM_INFO_RECCOUNT    1
  #define PALM_INFO_CREATOR     2
  #define PALM_INFO_TYPE        3

