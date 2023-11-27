/*
        GEOS.H

        by Marcus Gr�ber 1992-95

        Include file for the PC/GEOS file format
*/


#if !defined(_GEOS_H)
#define _GEOS_H

#pragma pack(1)

#define GEOS_TOKENLEN 4
typedef struct {                        /*** ID for file types/icons */
  char str[GEOS_TOKENLEN];              // 4 byte string
  unsigned short num;                         // additional id number (?)
} GEOStoken;

typedef struct {                        /*** Protocol/version number */
  unsigned short vers;                        // protocol
  unsigned short rev;                         // sub revision
} GEOSprotocol;

typedef struct {                        /*** "Release" */
  unsigned short versmaj,versmin;             // "release" x.y
  unsigned short revmaj,revmin;               // value "a-b" behind "release"
} GEOSrelease;

/******************************************************************************
 *               GEOS standard file header (all file types)                   *
 ******************************************************************************/
#define GEOS_LONGNAME 36                // length of filename
#define GEOS_INFO     100               // length of user file info

#define GEOS_ID 0x53CF45C7              // GEOS file identification "magic"

typedef struct {                        /*** Standard-Dateikof */
  unsigned char ID[4];                              // GEOS id magic: C7 45 CF 53
  unsigned char class[2];                       // 00=applciation, 01=VM file
  unsigned char flags[2];                       // flags ??? (always seen 0000h)
  GEOSrelease release;                  // "release"
  GEOSprotocol protocol;                // protocol/version
  GEOStoken token;                      // file type/icon
  GEOStoken appl;                       // "token" of creator application
  char name[GEOS_LONGNAME];             // long filename
  char info[GEOS_INFO];                 // user file info
  char _copyright[24];                  // original files: Copyright notice
} GEOSheader;

/******************************************************************************
 *                         GEOS program files ("geodes")                      *
 ******************************************************************************/
#define GEOS_FNAME 8                    // Length of internale filename/ext
#define GEOS_FEXT  4

typedef struct {                        /*** Additional geode file header */
                        char _x1[8];    // this is actually not part of the app
                                        //   header, but for historical reasons,
                                        //   I keep it in... :-)
  unsigned short _attr;                       // attribute (see below)
  unsigned short _type;                       // program type (see below)
  GEOSprotocol kernalprot;              // expected kernel protocoll
  unsigned short _numseg;                     // number of segments
  unsigned short _numlib;                     // number of included libraries
  unsigned short _numexp;                     // number of exported locations
  unsigned short stacksize;                   // default stack size
  unsigned short x2_ofs;                      // if application: segment/offset of ???
  unsigned short x2_seg;
  unsigned short tokenres_item;               // if application: segment/item of
  unsigned short tokenres_seg;                //   ressource with application token
                        char _x21[2];
  unsigned short attr;                        // attribute
  unsigned short type;                        // program type: 01=application
                                        //               02=library
                                        //               03=device driver
  GEOSrelease release;                  // "release"
  GEOSprotocol protocol;                // protocol/version
  unsigned short CRC;                         // possibly header checksum (???)
  char name[GEOS_FNAME],ext[GEOS_FEXT]; // internal filename/ext (blank padded)
  GEOStoken token;                      // file type/icon
                        char _x3[2];
  unsigned short startofs;                    // if driver: entry location
  unsigned short startseg;                    //              "     "
  unsigned short initofs;                     // if library: init location (?)
  unsigned short initseg;                     //               "      "
                        char _x33[2];
  unsigned short numexp;                      // number of exports
  unsigned short numlib;                      // number of included libraries
                        char _x4[2];
  unsigned short numseg;                      // Number of program segments
                        char _x5[6];
} GEOSappheader;

typedef struct {                        /*** Base type of "exported" array */
  unsigned short ofs;                         // Routine entry location
  unsigned short seg;                         //    "      "      "
} GEOSexplist;

typedef struct {                        /*** Base typ of library array */
  char name[GEOS_FNAME];                // library name
  unsigned short type;                        // library type: 2000h=driver
                                        //               4000h=library
  GEOSprotocol protocol;                // required lib protocol/version
} GEOSliblist;

typedef unsigned short GEOSseglen;            /*** Base type of segment size array */
typedef int GEOSsegpos;                /*** Base type of segment loc array */
typedef unsigned short GEOSsegfix;            /*** Base type of fixup tab size ary */
typedef unsigned short GEOSsegflags;          /*** Base type of flag array:
                                               xxxx xxxx xxxx xxxxb
                                         */

typedef struct {                        /*** Base typ of segment fixup table */
  unsigned short type;                        // Type of fixup:
                                        //   xxxxh
                                        //   �ٳ�
                                        //   � �0 = 16/16 pointer to routine #
                                        //   � �1 = 16    offset to routine #
                                        //   � �2 = 16    segment of routine #
                                        //   � �3 = 16    segment
                                        //   � �4 = 16/16 pointer (seg,ofs!)
                                        //   � 0 = kernel
                                        //   � 1 = library
                                        //   � 2 = program
                                        //   xx = if library: library ord #
  unsigned short ofs;                         // Offset relative to segment
} GEOSfixup;


/******************************************************************************
 *                        GEOS VM files (documents etc.)                      *
 ******************************************************************************/
#define GEOS_IDVM 0xADEB                // identification "magic" of VM file
#define GEOS_IDvmfdir 0x00FB            // identification for VM directory hdr

typedef struct {                        /*** Additional VM file header */
  char _x1[8];
  unsigned short IDVM;                        // VM id "magic"
  unsigned short dirsize;                     // size of directory block (bytes)
  long dirptr;                          // absolute file pos of dir block
} GEOSvmfheader;

typedef struct {                        /*** File header of directory block */
  unsigned short IDvmfdir;                    // ID sequence (?) 0xFB 0x00
  unsigned short hdl_1stfree;                 // handle of first free block
  unsigned short hdl_lastfree;                // handle of last free block
  unsigned short hdl_1stunused;               // first unused handle entry
  unsigned short dirsize;                     // total size of directory record
  unsigned short nblocks_free;                // number of free blocks
  unsigned short nhdls_free;                  // number of unused handle entries
  unsigned short nblocks_used;                // number of used blocks
  unsigned short nblocks_loaded;              // number of loded blocks (?)
  char _x2[2];
  unsigned short hdl_first;                   // handle of map data block
  char _x2b[2];
  long totalsize;                       // Total size of allocated blocks
  unsigned short flags;                       // flags (?)
  unsigned short hdl_dbmap;                   // handle of DB map data block
} GEOSvmfdirheader;                     // (handle table follows)

typedef struct {                        /*** Entry in handle table */
  union {
    struct {                            /*** Belegter Block */
      unsigned short hdl;                     // handle in memory, if loaded (?)
      unsigned short flags;                   // flags for this block:
                                        // 000000xx11111xx1
                                        //       ��     ��� 0 = not SAVEd
                                        //       ��     ��� 0 = unSAVEed changes
                                        //       ��             block exists
                                        //       ���������� 1 = has LMem heap
                                        //       ���������� 1 = not SAVEd
      unsigned short ID;                      // block type (application dependant)
                                        // if block with unSAVEd changes exists,
                                        //   handle of block with recent changes
    } used;
    struct {                            /*** free block */
      unsigned short next;                    // VM handle of next free block
      unsigned short prev;                    // VM handle of previous free block
      unsigned short size;                    // size of free block
    } free;
  };
  unsigned short blocksize;                   // size of block (bytes, 0 if free)
  long blockptr;                        // file pointer to beginning of block
                                        // (0=unused handle entry)
} GEOSvmfdirrec;

// Note: "Handles" in the global VM directory are offsets relative to the
//   beginning of the block directory structure that point into the directory
//   array immediately following the header

typedef struct {                        /*** Header of block with LMem heap */
  unsigned short seg;                         // same as GEOSvmfdirrec.hdl
  unsigned short hdllistofs;                  // block rel offset of local handle list
  unsigned short LMBH_flags;                  // flags
  unsigned short LMBH_lmemType;               // type of data in block
  unsigned short blocksize;                   // number of bytes under heap control
  unsigned short hdllistnum;                  // number of entries in handle list
  unsigned short freeofs;                     // offset of first free block
  unsigned short freesize;                    // free heap memory in this block
//unsigned hdl_block;                   // global handle of this block
//unsigned dbblock;                     // block index in group, if dbman file
} GEOSlocalheap;

typedef unsigned GEOSlocallist;         /*** Base type of local heap table */

/* macros to operate on VM block directory as on an array */
#define GeosHdl2Idx(hdl)\
        (((hdl)-sizeof(GEOSvmfdirheader))/sizeof(GEOSvmfdirrec))
#define GeosIdx2Hdl(idx)\
        ((idx)*sizeof(GEOSvmfdirrec)+sizeof(GEOSvmfdirheader))


/******************************************************************************
 *             GEOS database manager files (subtype of VM files)              *
 ******************************************************************************/
typedef struct {                        /*** Database adress in dbman file */
  unsigned short group;                       // VM handle of group index
  unsigned short item;                        // item number in that group
} GEOSdbadr;

typedef struct {                        /*** Header block of dbmanager file */
  unsigned short hdl;                         // VM file handle
  unsigned short seg;                         // Memory handle (?)
  GEOSdbadr prim;                       // db adress of primary item
  unsigned short x;
  char _x1[6];
} GEOSdbheader;

typedef struct {                        /*** Header of group index block */
  unsigned short hdl;                         // VM file handle
  unsigned short seg;                         // Memory handle (?)
  unsigned short flags;
  unsigned short maxitemlist;                 // top of item list space
  unsigned short curitemlist;                 // current top of item list
  unsigned short curblocklist;                // curent top of block list
  unsigned short blocksize;                   // size of index data in block
} GEOSdbidx;

typedef struct {                        /*** Base type of item list */
  unsigned short block;                       // Pointer to block record
  unsigned short hdl;                         // Local handle within that block
} GEOSdbitemlist;

typedef struct {                        /*** Base type of storage block list */
  unsigned short _x;
  unsigned short hdl;                         // VM handle of storage block
  unsigned short num;                         // number of items in that block
} GEOSdbblocklist;
#pragma pack()

/*** Nimbus Q font files (Geos-specific format) ***/
#include "nimbus.h"                     

#endif
