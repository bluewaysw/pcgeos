/*
        GEOS2.H

        by Marcus Groeber 1993-94

        Include file for the PC/GEOS 2 file format
        Requires GEOS.H to be included first.
*/

#include "geos.h"

#pragma pack(1)

/*
 *  Packed time and date structures; bitfield order is compiler dependant.
 */
typedef struct {
  unsigned short d:5;
  unsigned short m:4;
  unsigned short y:7;
} PackedFileDate;

typedef struct {
  unsigned short s_2:5;
  unsigned short m:6;
  unsigned short h:5;
} PackedFileTime;

/******************************************************************************
 *               GEOS standard file header (all file types)                   *
 ******************************************************************************/
#define GEOS2_ID 0x53C145C7             // GEOS2 file identification "magic"

typedef struct {                        /*** GEOS2 standard header: */
  int ID;                               // GEOS2 id magic: C7 45 CF 53
  char name[GEOS_LONGNAME];             // long filename
  unsigned short class;                       // geos filetype, see SDK docs
  unsigned short flags;                       // attributes
  GEOSrelease release;                  // "release"
  GEOSprotocol protocol;                // protocol/version
  GEOStoken token;                      // file type/icon
  GEOStoken appl;                       // "token" of creator application
  char info[GEOS_INFO];                 // user file info
  char _copyright[24];                  // original files: Copyright notice
  char _x[8];
  PackedFileDate create_date;
  PackedFileTime create_time;           // creation date/time in DOS format
  char password[8];                     // password, encrypted as hex string
  char _x2[44];                         // not yet decoded
} GEOS2header; /* ~~~os90File.h: GeosFileHeader2 */

typedef struct {                        /*** Additional geode file header */
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
  unsigned tokenres_seg;                //   ressource with application token
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
} GEOS2appheader; /* ~~~geode.h: GeodeHeader */

typedef struct {                        /*** Additional VM file header */
  unsigned short IDVM;                        // VM id "magic"
  unsigned short dirsize;                     // size of directory block (bytes)
  int dirptr;                          // absolute file pos of dir block
} GEOS2vmfheader;


/******************************************************************************
 ******************************************************************************/
typedef struct {                        /*** Additional obj block header */
    unsigned short           OLMBH_inUseCount;
    unsigned short           OLMBH_interactibleCount;
    unsigned short int       OLMBH_output;
    unsigned short           OLMBH_resourceSize;
} GEOSObjLMemBlockHeader;

typedef enum /* word */ {
    LMEM_TYPE_GENERAL,
    LMEM_TYPE_WINDOW,
    LMEM_TYPE_OBJ_BLOCK,
    LMEM_TYPE_GSTATE,
    LMEM_TYPE_FONT_BLK,
    LMEM_TYPE_GSTRING,
    LMEM_TYPE_DB_ITEMS
} LMemType;

/*** Heap flags (see HEAP.DEF for ESP structs) - also used for Geode segments */
#define HF_FIXED            0x80
#define HF_SHARABLE         0x40
#define HF_DISCARDABLE      0x20
#define HF_SWAPABLE         0x10
#define HF_LMEM             0x08
#define HF_DEBUG            0x04
#define HF_DISCARDED        0x02
#define HF_SWAPPED          0x01

#define HAF_ZERO_INIT       0x80
#define HAF_LOCK            0x40
#define HAF_NO_ERR          0x20
#define HAF_UI              0x10
#define HAF_READ_ONLY       0x08
#define HAF_OBJECT_RESOURCE 0x04
#define HAF_CODE            0x02
#define HAF_CONFORMING      0x01

#define GEOS2_DIRINFONAME "@DIRNAME.000"

#pragma pack()






