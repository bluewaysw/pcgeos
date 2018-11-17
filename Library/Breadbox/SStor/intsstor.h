/* Some standard typedefs and defines... */

typedef sword OFFSET;
typedef dword SECT;
typedef sdword SSECT;
typedef dword FSINDEX;
typedef word FSOFFSET;
typedef dword DFSIGNATURE;
typedef word DFPROPTYPE;
typedef dword SID;
typedef byte CLSID[16];
typedef CLSID GUID;
typedef struct tagFILETIME {
    dword dwLowDateTime;
    dword dwHighDateTime;
} FILETIME, TIME_T;

/* Now, for the Structured Storage stuff. */

/* Constants used in the FAT tables */
#define DIFSECT         0xFFFFFFFCUL
#define FATSECT         0xFFFFFFFDUL
#define ENDOFCHAIN      0xFFFFFFFEUL
#define FREESECT        0xFFFFFFFFUL

#define LASTVALIDSECT   0xFFFFFFFBUL

/* The header of a structured storage file. */
typedef struct {
    byte    SSH_abSig[8];       // [00H,08] {0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1,
                                // 0x1a, 0xe1} for current version, was {0x0e,
                                // 0x11, 0xfc, 0x0d, 0xd0, 0xcf, 0x11, 0xe0} on
                                // old, beta 2 files (late '92) which are also
                                // supported by the reference implementation
    CLSID   SSH_clid;           // [008H,16] class id (set with WriteClassStg,
                                // retrieved with GetClassFile/ReadClassStg)
    word    SSH_uMinorVersion;  // [018H,02] minor version of the format: 33
                                // is written by reference implementation
    word    SSH_uDllVersion;    // [01AH,02] major version of the dll/format:
                                // 3 is written by reference implementation
    word    SSH_uByteOrder;     // [01CH,02] 0xFFFE: indicates Intel byte-
                                // ordering
    word    SSH_uSectorShift;   // [01EH,02] size of sectors in power-of-two
                                // (typically 9, indicating 512-byte sectors)
    word    SSH_uMiniSectorShift;
                                // [020H,02] size of mini-sectors in power-of-
                                // two (typically 6, indicating 64-byte mini-
                                // sectors)
    word    SSH_usReserved;     // [022H,02] reserved, must be zero
    dword   SSH_usReserved1;    // [024H,04] reserved, must be zero
    dword   SSH_usReserved2;    // [028H,04] reserved, must be zero
    FSINDEX SSH_csectFat;       // [02CH,04] numbers of SECTs in the FAT chain
    SECT    SSH_sectDirStart;   // [030H,04] first SECT in the FAT Directory
                                // chain
    DFSIGNATURE SSH_signature;  // [034H,04] signature used for transactioning
                                // must be zero.  The reference implementation
                                // does not support transactioning
    dword   SSH_ulMiniSectorCutoff;
                                // [038H,04] maximum size for mini-streams:
                                // typically 4096 bytes
    SECT    SSH_sectMiniFatStart;
                                // [03CH,04] first SECT in the mini-FAT chain
    FSINDEX SSH_csectMiniFat;   // [040H,04] number of SECTs in the mini-FAT
                                // chain
    SECT    SSH_sectDifStart;   // [044H,04] first SECT in the DIF chain
    FSINDEX SSH_csectDif;       // [048H,04] number of SECTs in the DIF chain
    SECT    SSH_sectFat[109];   // [04CH,436] the SECTs of the first 109 FAT
                                // sectors
} StructuredStorageHeader;

#define SSH_SIG_LEN             8
#define SSH_NUM_FAT_SECTS       109
#define SSH_BYTE_ORDER_INTEL    0xFFFE

/* These are signatures written at the start of every file.  A file must
   contain one or the other signature to be considered valid. */

#define SSH_SIG_NEW 0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1
#define SSH_SIG_OLD 0x0e, 0x11, 0xfc, 0x0d, 0xd0, 0xcf, 0x11, 0xe0

/* Directory Sectors defines. */
typedef enum {
    STGTY_INVALID = 0,
    STGTY_STORAGE = 1,
    STGTY_STREAM = 2,
    STGTY_LOCKBYTES = 3,
    STGTY_PROPERTY = 4,
    STGTY_ROOT = 5
} STGTY;

typedef enum {
    DE_RED = 0,
    DE_BLACK = 1,
} DECOLOR;

typedef struct {
    byte    SSDE_ab[32*sizeof(wchar)];
                                // [00H,64] 64 bytes. The Element name in
                                // Unicode, padded with zeros to fill this byte
                                // array
    word    SSDE_cb;            // [040H,02] Length of the Element name in bytes
    byte    SSDE_mse;           // [042H,01] Type of object: value taken from
                                // the STGTY enumeration
    byte    SSDE_bflags;        // [043H,01] Value taken from DECOLOR enumeration
    SID     SSDE_sidLeftSib;    // [044H,04] SID of the left-sibling of this
                                // entry in the directory tree
    SID     SSDE_sidRightSib;   // [048H,04] SID of the right-sibling of this
                                // entry in the directory tree
    SID     SSDE_sidChild;      // [04CH,04] SID of the first child acting as
                                // the root of all the children of this element
                                // (SSDE_mse=STGTY_STORAGE)
    GUID    SSDE_clsId;         // [050H,16] CLSID of this storage
                                // (SSDE_mse=STGTY_STORAGE)
    dword   SSDE_dwUserFlags;   // [060H,04] User flags of this storage
                                // (SSDE_mse=STGTY_STORAGE)
    TIME_T  SSDE_time[2];       // [064H,16] Create/Modify time stamps
    SECT    SSDE_sectStart;     // [074H,04] starting SECT of the stream
    dword   SSDE_ulSize;        // [078H,04] size of stream in bytes
                                // (SSDE_mse=STGTY_STORAGE)
    DFPROPTYPE  SSDE_dptPropType;
                                // [07CH,02] Reserved for future use. Must be zero
} StructuredStorageDirectoryEntry;

#define SSDE_PADDED_SIZE 128
#define ROOT_SID    0
#define NULL_SID    0xFFFFFFFFUL


