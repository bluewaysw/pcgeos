## 4.2 Data Structures F-K
----------
#### FALSE
    #define FALSE        0
    #define TRUE        (~0)    /* use as return value, not for comparisons */

----------
#### FFFieldMessageBlock
    typedef struct {
        char    textBuffer[100];
        int     startOffset;
    } FFFieldMessageBlock;

----------
#### FileAccess
    typedef ByteEnum FileAccess
        #define FA_READ_ONLY                0
        #define FA_WRITE_ONLY               1
        #define FA_READ_WRITE               2

----------
#### FileAccessFlags
    typedef ByteFlags FileAccessFlags;
        #define FILE_DENY_RW        0x10
        #define FILE_DENY_W         0x20
        #define FILE_DENY_R         0x30
        #define FILE_DENY_NONE      0x40
        #define FILE_ACCESS_R       0x00
        #define FILE_ACCESS_W       0x01
        #define FILE_ACCESS_RW      0x02
        #define FILE_NO_ERRORS      0x80

When you open a file for bytewise access, you must pass a record of 
**FileAccessFlags**. The **FileAccessFlags** record specifies two things: what 
kind of access the caller wants, and what type of access is permitted to other 
geodes. A set of **FileAccessFlags** is thus a bit-wise "or" of two different 
values. The first specifies what kind of access the calling geode wants and has 
the following values:

FILE_ACCESS_R  
The geode will only be reading from the file.

FILE_ACCESS_W  
The geode will write to the file but will not read from it.

FILE_ACCESS_RW  
The geode will read from and write to the file.

The second part specifies what kind of access other geodes may have. Note 
that if you try to deny a permission which has already been given to another 
geode (e.g. you open a file with FILE_DENY_W when another geode has the 
file open for write-access), the call will fail. It has the following values:

FILE_DENY_RW  
No geode may open the file for any kind of access, whether read, 
write, or read/write.

FILE_DENY_R  
No geode may open the file for read or read/write access.

FILE_DENY_W  
No geode may open the file for write or read/write access.

FILE_DENY_NONE  
Other geodes may open the file for any kind of access.

Two flags, one from each of these sets of values, are combined to make up a 
proper **FileAccessFlags** value. For example, to open the file for read-only 
access while prohibiting other geodes from writing to the file, you would pass 
the flags "(FILE_ACCESS_R | FILE_DENY_W)".

----------
#### FileAccessRights
    typedef char FileAccessRights[FILE_RIGHTS_SIZE];

----------
#### FileAttrs
    typedef ByteFlags FileAttrs;
        #define FA_ARCHIVE                      0x20
        #define FA_SUBDIR                       0x10
        #define FA_VOLUME                       0x8
        #define FA_SYSTEM                       0x4
        #define FA_HIDDEN                       0x2
        #define FA_RDONLY                       0x1
        #define FILE_ATTR_NORMAL                0
        #define FILE_ATTR_READ_ONLY             FA_RDONLY
        #define FILE_ATTR_HIDDEN                FA_HIDDEN
        #define FILE_ATTR_SYSTEM                FA_SYSTEM
        #define FILE_ATTR_VOLUME_LABEL          FA_VOLUME

Every DOS or GEOS file has certain attributes. These attributes mark such 
things as whether the file is read-only. With GEOS files, the attributes can be 
accessed by using the extended attribute FEA_FILE_ATTR. You can also 
access any file's standard attributes with the routines **FileGetAttributes()** 
and **FileSetAttributes()**; these routines work for both GEOS files and plain 
DOS files.

The **FileAttrs** field contains the following bits:

FA_ARCHIVE  
This flag is set if the file requires backup. Backup programs 
typically clear this bit.

FA_SUBDIR  
This flag is set if the "file" is actually a directory. Geodes may 
not change this flag.

FA_VOLUME  
This flag is set if the "file" is actually the volume label. This flag 
will be off for all files a geode will ever see. Geodes may not 
change this flag.

FA_SYSTEM  
This flag is set if the file is a system file. Geodes should not 
change this bit.

FA_HIDDEN  
This flag is set if the file is hidden.

FA_RDONLY  
This flag is set if the file is read-only.

**See Also:** FileGetAttrs(), FileSetAttrs()

**Include:** file.h

----------
#### FileChangeNotificationData
    typedef struct {
        PathName            FCND_pathname;
        DiskHandle          FCND_diskHandle;
        FileChangeType      FCND_changeType;
    } FileChangeNotificationData;

----------
#### FileChangeType
    typedef ByteEnum FileChangeType;
        #define FCT_CREATE              0
        #define FCT_DELETE              1
        #define FCT_RENAME              2
        #define FCT_CONTENTS            3
        #define FCT_DISK_FORMAT         4

----------
#### FileCopyrightNotice
    typedef char FileCopyrightNotice[GFH_NOTICE_SIZE];

----------
#### FileCreateFlags
    typedef WordFlags FileCreateFlags;
        #define FCF_NATIVE      0x8000
        #define FCF_MODE        0x0300 /* Filled with FILE_CREATE_* constant */
        #define FCF_ACCESS      0x00ff /* Filled with FileAccessFlags */

----------
#### FileDateAndTime
    typedef DWordFlags FileDateAndTime;
        #define FDAT_HOUR                       0xf8000000
        #define FDAT_MINUTE                     0x07e00000
        #define FDAT_2SECOND                    0x001f0000
        #define FDAT_YEAR                       0x0000fe00
        #define FDAT_MONTH                      0x000001e0
        #define FDAT_DAY                        0x0000001f
        #define FDAT_HOUR_OFFSET                27
        #define FDAT_MINUTE_OFFSET              21
        #define FDAT_2SECOND_OFFSET             16
        #define FDAT_YEAR_OFFSET                9
        #define FDAT_MONTH_OFFSET               5
        #define FDAT_DAY_OFFSET                 0
        #define FDAT_BASE_YEAR                  1980

Every GEOS file has two date and time stamps. One of them records the time 
the file was created, and one records the time the file was last modified. These 
stamps are recorded with the file's extended attributes; they are labeled 
FEA_CREATION and FEA_MODIFICATION, respectively. Non-GEOS files have 
a single date/time stamp, which records the time the file was last modified.

The date/time stamps are stored in a 32-bit bitfield. This field contains 
entries for the year, month, day, hour, minute, and second. Each field is 
identified by a mask and an offset. To access a field, simply clear all bits 
except those in the mask, then shift the bits to the right by the number of the 
offset. (Macros are provided to do this; they are described below.) 
**FileDateAndTime** contains the following fields, identified by their masks:

FDAT_YEAR  
This field records the year, counting from a base year of 1980. 
(The constant FDAT_BASE_YEAR is defined as 1980.) This field 
is at an offset of FDAT_YEAR_OFFSET bits from the low end of 
the value.

FDAT_MONTH  
This field records the month as an integer, with January being 
one. It is located at an offset of FDAT_MONTH_OFFSET.

FDAT_DAY  
This field records the day of the month. It is located at an offset 
of FDAT_DAY_OFFSET.

FDAT_HOUR  
This field records the hour on a 24-hour clock, with zero being 
the hour after midnight. It is located at an offset of 
FDAT_HOUR_OFFSET.

FDAT_MINUTE 
This field records the minute. It is located at an offset of 
FDAT_MINUTE_OFFSET.

FDAT_2SECOND 
This field records the second, divided by two; that is, a field 
value of 15 indicates the 30th second. (It is represented this 
way to let the second fit into 5 bits, thus letting the entire value 
fit into 32 bits.) It is located at an offset of 
FDAT_2SECOND_OFFSET.

Macros are provided to extract values from each of the fields of a 
**FileDateAndTime** structure. The macros are listed below:

    byte FDATExtractYear( /* returns year field, counted from 1980*/
            FileDateAndTime fdat);
    word FDATExtractYearAD( /* returns year field + base year */
            FileDateAndTime fdat);
    byte FDATExtractMonth( /* returns month field (1 = January, etc.) */
            FileDateAndTime fdat);
    byte FDATExtractDay( /* returns day field */
            FileDateAndTime fdat);
    byte FDATExtractHour( /* returns hour field */
            FileDateAndTime fdat);
    byte FDATExtractMinute( /* returns minute field */
            FileDateAndTime fdat);
    byte FDATExtract2Second( /* returns 2Second field */
            FileDateAndTime fdat);
    byte FDATExtractSecond( /* returns number of seconds (2 * 2Second) */
            FileDateAndTime fdat);
**Include:** file.h

----------
#### FileDesktopInfo
    typedef char FileDesktopInfo[FILE_DESKTOP_INFO_SIZE];

----------
#### FileDirID
    typedef dword FileDirID;

----------
#### FileFileID
    typedef dword FileFileID;

----------
#### FileExclude
    typedef ByteEnum FileExclude;
        #define FE_EXCLUSIVE            1
        #define FE_DENY_WRITE           2
        #define FE_DENY_READ            3
        #define FE_NONE                 4

----------
#### FileExtAttrDesc
    typedef struct {
        FileExtendedAttribute   FEAD_attr;  /* Attribute to get or set */
        void        *FEAD_value;        /* Pointer to buffer/new value */
        word        FEAD_size;          /* length of buffer/new value */
        chr         *FEAD_name;         /* If FEAD_attr == FEA_CUSTOM,
                                         * this points to null-
                                         * terminated ASCII string with
                                         * attribute's name; otherwise,
                                         * this is ignored. */
    } FileExtendedAttrDesc;

The routines to get and set extended attributes can be passed the attribute 
FEA_MULTIPLE. In this case, they will also be passed the address of an array 
of **FileExtAttrDesc** structures and the number of elements of the array. 
They will go through the array and read or write the appropriate 
information.

**FileEnum()** can also be passed arrays of **FileExtAttrDesc** structures. In 
this case, the number of elements in the array is not passed. Instead, each 
array ends with a **FileExtAttrDesc** with a FEAD_attr field set to 
FEA_END_OF_LIST.

**See Also:** FileExtendedAttribute

**Include:** file.h

----------
#### FileExtendedAttribute
    typedef enum /* word */ {
        FEA_MODIFICATION,
        FEA_FILE_ATTR,
        FEA_SIZE,
        FEA_FILE_TYPE,
        FEA_FLAGS,
        FEA_RELEASE,
        FEA_PROTOCOL,
        FEA_TOKEN,
        FEA_CREATOR,
        FEA_USER_NOTES,
        FEA_NOTICE,
        FEA_CREATION,
        FEA_PASSWORD,
        FEA_CUSTOM,
        FEA_NAME,
        FEA_GEODE_ATTR,
        FEA_PATH_INFO,
        FEA_FILE_ID,
        FEA_DESKTOP_INFO,
        FEA_DRIVE_STATUS,
        FEA_DOS_NAME,
        FEA_OWNER,
        FEA_RIGHTS,
        FEA_MULTIPLE = 0xfffe,
        FEA_END_OF_LIST = 0xffff,
    } FileExtendedAttribute;

Every GEOS file has a set of extended attributes. These attributes can be 
recovered with **FileGetPathExtAttributes()** or 
**FileGetHandleExtAttributes()**. You can also use **FileEnum()** to search a 
directory for files with specified extended attributes.

The above extended attributes have been implemented. More may be added 
with future releases of GEOS. The attributes are discussed at length in 
Section 17.5.3 of the Concepts book.

**See Also:** FileExtAttrDesc

**Include:** file.h

----------
#### FileHandle
    typedef Handle FileHandle;

----------
#### FileLongName
    typedef char FileLongName[FILE_LONGNAME_BUFFER_SIZE];

----------
#### FileOwnerName
    typedef char FileOwnerName[FILE_OWNER_NAME_SIZE];

----------
#### FilePassword
    typedef char FilePassword[FILE_PASSWORD_SIZE];

----------
#### FilePosMode
    typedef ByteEnum FilePosMode;
        #define FILE_POS_START              0
        #define FILE_POS_RELATIVE           1
        #define FILE_POS_END                2

----------
#### FileUserNotes
    typedef char FileUserNotes[GFH_USER_NOTES_BUFFER_SIZE];

----------
#### FindNoteHeader
    typedef struct {
        word    FNH_count;      /* The number of matching notes we've found */
    } FindNoteHeader;

----------
#### FloatExponent
    typedef WordFlags FloatExponent;
        #define FE_SIGN         0x8000
        #define FE_EXPONENT     0x7fff

----------
#### FloatNum
    typedef struct {
        word                    F_mantissa_wd0;
        word                    F_mantissa_wd1;
        word                    F_mantissa_wd2;
        word                    F_mantissa_wd3;
        FloatExponent           F_exponent;
    } FloatNum;

----------
#### FontAttrs
    typedef ByteFlags FontAttrs;
        #define FA_FIXED_WIDTH          0x40
        #define FA_ORIENT               0x20
        #define FA_OUTLINE              0x10
        #define FA_FAMILY               0x0f
        #define FA_FAMILY_OFFSET        0
**Include:** font.h

----------
#### FontEnumFlags
    typedef ByteFlags FontEnumFlags;
        #define FEF_ALPHABETIZE     0x80    /* Alphabetize returned list of fonts */
        #define FEF_FIXED_WIDTH     0x20    /* Return only fixed-width fonts */
        #define FEF_FAMILY          0x10
        #define FEF_STRING          0x08
        #define FEF_DOWNCASE        0x04    /* Returned font names will be lowercase */
        #define FEF_BITMAPS         0x02    /* Interested in bitmap fonts */
        #define FEF_OUTLINES        0x01    /* Interested in outline fonts */
**Include:** font.h

----------
#### FontEnumStruct
    typedef struct {
         FontIDs        FES_ID;
         char           FES_name[FID_NAME_LEN];
    } FontEnumStruct;
**Include:** font.h

----------
#### FontFamily
    typedef byte FontFamily;
        #define FF_NON_PORTABLE         0x0007
        #define FF_SPECIAL              0x0006
        #define FF_MONO                 0x0005
        #define FF_SYMBOL               0x0004
        #define FF_ORNAMENT             0x0003
        #define FF_SCRIPT               0x0002
        #define FF_SANS_SERIF           0x0001
        #define FF_SERIF                0x0000
**Include:** fontID.h

----------
#### FontGroup
    typedef enum /* word */ {
        #define FG_NON_PORTABLE         0x0e00
        #define FG_SPECIAL              0x0c00
        #define FG_MONO                 0x0a00
        #define FG_SYMBOL               0x0800
        #define FG_ORNAMENT             0x0600
        #define FG_SCRIPT               0x0400
        #define FG_SANS_SERIF           0x0200
        #define FG_SERIF                0x0000
    } FontGroup;
**Include:** fontID.h

----------
#### FontIDRecord
    typedef WordFlags FontIDRecord;
        #define FIDR_maker              0xf000
        #define FIDR_ID             0x0fff
        #define FIDR_maker_OFFSET                   12
        #define FIDR_ID_OFFSET                   0
**Include:** font.h

----------
#### FontID
    typedef word FontID;
        #define FID_PRINTER_20CPI                           0xfa05
        #define FID_PRINTER_17CPI                           0xfa04
        #define FID_PRINTER_16CPI                           0xfa03
        #define FID_PRINTER_15CPI                           0xfa02
        #define FID_PRINTER_12CPI                           0xfa01
        #define FID_PRINTER_10CPI                           0xfa00
        #define FID_PRINTER_PROP_SANS                       0xf200
        #define FID_PRINTER_PROP_SERIF                      0xf000
        #define FID_BITSTREAM_LETTER_GOTHIC                 0x3a03
        #define FID_PS_LETTER_GOTHIC                        0x2a03
        #define FID_DTC_LETTER_GOTHIC                       0x1a03
        #define FID_BITSTREAM_PRESTIGE_ELITE                0x3a02
        #define FID_PS_PRESTIGE_ELITE                       0x2a02
        #define FID_DTC_PRESTIGE_ELITE                      0x1a02
        #define FID_BITSTREAM_AMERICAN_TYPEWRITER           0x3a01
        #define FID_PS_AMERICAN_TYPEWRITER                  0x2a01
        #define FID_DTC_AMERICAN_TYPEWRITER                 0x1a01
        #define FID_BITSTREAM_URW_MONO                      0x3a00
        #define FID_PS_COURIER                              0x2a00
        #define FID_DTC_URW_MONO                            0x1a00
        #define FID_BITSTREAM_FUN_DINGBATS                  0x380d
        #define FID_PS_FUN_DINGBATS                         0x280d
        #define FID_DTC_FUN_DINGBATS                        0x180d
        #define FID_BITSTREAM_CHEQ                          0x380c
        #define FID_PS_CHEQ                                 0x280c
        #define FID_DTC_CHEQ                                0x180c
        #define FID_BITSTREAM_BUNDESBAHN_PI_3               0x380b
        #define FID_PS_BUNDESBAHN_PI_3                      0x280b
        #define FID_DTC_BUNDESBAHN_PI_3                     0x180b
        #define FID_BITSTREAM_BUNDESBAHN_PI_2               0x380a
        #define FID_PS_BUNDESBAHN_PI_2                      0x280a
        #define FID_DTC_BUNDESBAHN_PI_2                     0x180a
        #define FID_BITSTREAM_BUNDESBAHN_PI_1               0x3809
        #define FID_PS_BUNDESBAHN_PI_1                      0x2809
        #define FID_DTC_BUNDESBAHN_PI_1                     0x1809
        #define FID_BITSTREAM_U_GREEK_MATH_PI               0x3808
        #define FID_PS_U_GREEK_MATH_PI                      0x2808
        #define FID_DTC_U_GREEK_MATH_PI                     0x1808
        #define FID_BITSTREAM_U_NEWS_COMM_PI                0x3807
        #define FID_PS_U_NEWS_COMM_PI                       0x2807
        #define FID_DTC_U_NEWS_COMM_PI                      0x1807
        #define FID_BITSTREAM_ACE_I                         0x3806
        #define FID_PS_ACE_I                                0x2806
        #define FID_DTC_ACE_I                               0x1806
        #define FID_BITSTREAM_SONATA                        0x3805
        #define FID_PS_SONATA                               0x2805
        #define FID_DTC_SONATA                              0x1805
        #define FID_BITSTREAM_CARTA                         0x3804
        #define FID_PS_CARTA                                0x2804
        #define FID_DTC_CARTA                               0x1804
        #define FID_BITSTREAM_MICR                          0x3803
        #define FID_PS_MICR                                 0x2803
        #define FID_DTC_MICR                                0x1803
        #define FID_BITSTREAM_ZAPF_DINGBATS                 0x3802
        #define FID_PS_ZAPF_DINGBATS                        0x2802
        #define FID_DTC_ZAPF_DINGBATS                       0x1802
        #define FID_BITSTREAM_DINGBATS                      0x3801
        #define FID_PS_DINGBATS                             0x2801
        #define FID_DTC_DINGBATS                            0x1801
        #define FID_BITSTREAM_URW_SYMBOLPS                  0x3800
        #define FID_PS_SYMBOL                               0x2800
        #define FID_DTC_URW_SYMBOLPS                        0x1800
        #define FID_BITSTREAM_JUNIPER                       0x367f
        #define FID_PS_JUNIPER                              0x267f
        #define FID_DTC_JUNIPER                             0x167f
        #define FID_BITSTREAM_COTTONWOOD                    0x367e
        #define FID_PS_COTTONWOOD                           0x267e
        #define FID_DTC_COTTONWOOD                          0x167e
        #define FID_BITSTREAM_BANCO                         0x367d
        #define FID_PS_BANCO                                0x267d
        #define FID_DTC_BANCO                               0x167d
        #define FID_BITSTREAM_ARCADIA                       0x367c
        #define FID_PS_ARCADIA                              0x267c
        #define FID_DTC_ARCADIA                             0x167c
        #define FID_BITSTREAM_ZIPPER                        0x367b
        #define FID_PS_ZIPPER                               0x267b
        #define FID_DTC_ZIPPER                              0x167b
        #define FID_BITSTREAM_WEIFZ_RUNDGOTIFCH             0x367a
        #define FID_PS_WEIFZ_RUNDGOTIFCH                    0x267a
        #define FID_DTC_WEIFZ_RUNDGOTIFCH                   0x167a
        #define FID_BITSTREAM_WASHINGTON                    0x3679
        #define FID_PS_WASHINGTON                           0x2679
        #define FID_DTC_WASHINGTON                          0x1679
        #define FID_BITSTREAM_VICTORIAN                     0x3678
        #define FID_PS_VICTORIAN                            0x2678
        #define FID_DTC_VICTORIAN                           0x1678
        #define FID_BITSTREAM_VEGAS                         0x3677
        #define FID_PS_VEGAS                                0x2677
        #define FID_DTC_VEGAS                               0x1677
        #define FID_BITSTREAM_VARIO                         0x3676
        #define FID_PS_VARIO                                0x2676
        #define FID_DTC_VARIO                               0x1676
        #define FID_BITSTREAM_VAG_RUNDSCHRIFT               0x3675
        #define FID_PS_VAG_RUNDSCHRIFT                      0x2675
        #define FID_DTC_VAG_RUNDSCHRIFT                     0x1675
        #define FID_BITSTREAM_TRAJANUS                      0x3674
        #define FID_PS_TRAJANUS                             0x2674
        #define FID_DTC_TRAJANUS                            0x1674
        #define FID_BITSTREAM_TITUS                         0x3673
        #define FID_PS_TITUS                                0x2673
        #define FID_DTC_TITUS                               0x1673
        #define FID_BITSTREAM_TIME_SCRIPT                   0x3672
        #define FID_PS_TIME_SCRIPT                          0x2672
        #define FID_DTC_TIME_SCRIPT                         0x1672
        #define FID_BITSTREAM_THUNDERBIRD                   0x3671
        #define FID_PS_THUNDERBIRD                          0x2671
        #define FID_DTC_THUNDERBIRD                         0x1671
        #define FID_BITSTREAM_THOROWGOOD                    0x3670
        #define FID_PS_THOROWGOOD                           0x2670
        #define FID_DTC_THOROWGOOD                          0x1670
        #define FID_BITSTREAM_TARRAGON                      0x366f
        #define FID_PS_TARRAGON                             0x266f
        #define FID_DTC_TARRAGON                            0x166f
        #define FID_BITSTREAM_TANGO                         0x366e
        #define FID_PS_TANGO                                0x266e
        #define FID_DTC_TANGO                               0x166e
        #define FID_BITSTREAM_SYNCHRO                       0x366d
        #define FID_PS_SYNCHRO                              0x266d
        #define FID_DTC_SYNCHRO                             0x166d
        #define FID_BITSTREAM_SUPERSTAR                     0x366c
        #define FID_PS_SUPERSTAR                            0x266c
        #define FID_DTC_SUPERSTAR                           0x166c
        #define FID_BITSTREAM_STOP                          0x366b
        #define FID_PS_STOP                                 0x266b
        #define FID_DTC_STOP                                0x166b
        #define FID_BITSTREAM_STILLA_CAPS                   0x366a
        #define FID_PS_STILLA_CAPS                          0x266a
        #define FID_DTC_STILLA_CAPS                         0x166a
        #define FID_BITSTREAM_STILLA                        0x3669
        #define FID_PS_STILLA                               0x2669
        #define FID_DTC_STILLA                              0x1669
        #define FID_BITSTREAM_STENTOR                       0x3668
        #define FID_PS_STENTOR                              0x2668
        #define FID_DTC_STENTOR                             0x1668
        #define FID_BITSTREAM_SQUIRE                        0x3667
        #define FID_PS_SQUIRE                               0x2667
        #define FID_DTC_SQUIRE                              0x1667
        #define FID_BITSTREAM_SPRINGFIELD                   0x3666
        #define FID_PS_SPRINGFIELD                          0x2666
        #define FID_DTC_SPRINGFIELD                         0x1666
        #define FID_BITSTREAM_SLIPSTREAM                    0x3665
        #define FID_PS_SLIPSTREAM                           0x2665
        #define FID_DTC_SLIPSTREAM                          0x1665
        #define FID_BITSTREAM_SINALOA                       0x3664
        #define FID_PS_SINALOA                              0x2664
        #define FID_DTC_SINALOA                             0x1664
        #define FID_BITSTREAM_SHELLEY                       0x3663
        #define FID_PS_SHELLEY                              0x2663
        #define FID_DTC_SHELLEY                             0x1663
        #define FID_BITSTREAM_SERPENTINE                    0x3662
        #define FID_PS_SERPENTINE                           0x2662
        #define FID_DTC_SERPENTINE                          0x1662
        #define FID_BITSTREAM_RUBBER_STAMP                  0x3661
        #define FID_PS_RUBBER_STAMP                         0x2661
        #define FID_DTC_RUBBER_STAMP                        0x1661
        #define FID_BITSTREAM_ROMIC                         0x3660
        #define FID_PS_ROMIC                                0x2660
        #define FID_DTC_ROMIC                               0x1660
        #define FID_BITSTREAM_RIALTO                        0x365f
        #define FID_PS_RIALTO                               0x265f
        #define FID_DTC_RIALTO                              0x165f
        #define FID_BITSTREAM_REVUE                         0x365e
        #define FID_PS_REVUE                                0x265e
        #define FID_DTC_REVUE                               0x165e
        #define FID_BITSTREAM_QUENTIN                       0x365d
        #define FID_PS_QUENTIN                              0x265d
        #define FID_DTC_QUENTIN                             0x165d
        #define FID_BITSTREAM_PRO_ARTE                      0x365c
        #define FID_PS_PRO_ARTE                             0x265c
        #define FID_DTC_PRO_ARTE                            0x165c
        #define FID_BITSTREAM_PRINCETOWN                    0x365b
        #define FID_PS_PRINCETOWN                           0x265b
        #define FID_DTC_PRINCETOWN                          0x165b
        #define FID_BITSTREAM_PRESIDENT                     0x365a
        #define FID_PS_PRESIDENT                            0x265a
        #define FID_DTC_PRESIDENT                           0x165a
        #define FID_BITSTREAM_PREMIER                       0x3659
        #define FID_PS_PREMIER                              0x2659
        #define FID_DTC_PREMIER                             0x1659
        #define FID_BITSTREAM_POST_ANTIQUA                  0x3658
        #define FID_PS_POST_ANTIQUA                         0x2658
        #define FID_DTC_POST_ANTIQUA                        0x1658
        #define FID_BITSTREAM_PLAZA                         0x3657
        #define FID_PS_PLAZA                                0x2657
        #define FID_DTC_PLAZA                               0x1657
        #define FID_BITSTREAM_PLAYBILL                      0x3656
        #define FID_PS_PLAYBILL                             0x2656
        #define FID_DTC_PLAYBILL                            0x1656
        #define FID_BITSTREAM_PICCADILLY                    0x3655
        #define FID_PS_PICCADILLY                           0x2655
        #define FID_DTC_PICCADILLY                          0x1655
        #define FID_BITSTREAM_PEIGNOT                       0x3654
        #define FID_PS_PEIGNOT                              0x2654
        #define FID_DTC_PEIGNOT                             0x1654
        #define FID_BITSTREAM_PAPYRUS                       0x3653
        #define FID_PS_PAPYRUS                              0x2653
        #define FID_DTC_PAPYRUS                             0x1653
        #define FID_BITSTREAM_PADDINGTION                   0x3652
        #define FID_PS_PADDINGTION                          0x2652
        #define FID_DTC_PADDINGTION                         0x1652
        #define FID_BITSTREAM_OKAY                          0x3651
        #define FID_PS_OKAY                                 0x2651
        #define FID_DTC_OKAY                                0x1651
        #define FID_BITSTREAM_ODIN                          0x3650
        #define FID_PS_ODIN                                 0x2650
        #define FID_DTC_ODIN                                0x1650
        #define FID_BITSTREAM_OCTOPUSS                      0x364f
        #define FID_PS_OCTOPUSS                             0x264f
        #define FID_DTC_OCTOPUSS                            0x164f
        #define FID_BITSTREAM_MOTTER_FEMINA                 0x364e
        #define FID_PS_MOTTER_FEMINA                        0x264e
        #define FID_DTC_MOTTER_FEMINA                       0x164e
        #define FID_BITSTREAM_MICROGRAMMA                   0x364d
        #define FID_PS_MICROGRAMMA                          0x264d
        #define FID_DTC_MICROGRAMMA                         0x164d
        #define FID_BITSTREAM_MACHINE                       0x364c
        #define FID_PS_MACHINE                              0x264c
        #define FID_DTC_MACHINE                             0x164c
        #define FID_BITSTREAM_LINOTEXT                      0x364b
        #define FID_PS_LINOTEXT                             0x264b
        #define FID_DTC_LINOTEXT                            0x164b
        #define FID_BITSTREAM_LIBERTY                       0x364a
        #define FID_PS_LIBERTY                              0x264a
        #define FID_DTC_LIBERTY                             0x164a
        #define FID_BITSTREAM_LAZYBONES                     0x3649
        #define FID_PS_LAZYBONES                            0x2649
        #define FID_DTC_LAZYBONES                           0x1649
        #define FID_BITSTREAM_LATIN_WIDE                    0x3648
        #define FID_PS_LATIN_WIDE                           0x2648
        #define FID_DTC_LATIN_WIDE                          0x1648
        #define FID_BITSTREAM_KNIGHTSBRIDGE                 0x3647
        #define FID_PS_KNIGHTSBRIDGE                        0x2647
        #define FID_DTC_KNIGHTSBRIDGE                       0x1647
        #define FID_BITSTREAM_KAPITELLIA                    0x3646
        #define FID_PS_KAPITELLIA                           0x2646
        #define FID_DTC_KAPITELLIA                          0x1646
        #define FID_BITSTREAM_KALLIGRAPHIA                  0x3645
        #define FID_PS_KALLIGRAPHIA                         0x2645
        #define FID_DTC_KALLIGRAPHIA                        0x1645
        #define FID_BITSTREAM_ICE_AGE                       0x3644
        #define FID_PS_ICE_AGE                              0x2644
        #define FID_DTC_ICE_AGE                             0x1644
        #define FID_BITSTREAM_ICONE                         0x3643
        #define FID_PS_ICONE                                0x2643
        #define FID_DTC_ICONE                               0x1643
        #define FID_BITSTREAM_HORNDON                       0x3642
        #define FID_PS_HORNDON                              0x2642
        #define FID_DTC_HORNDON                             0x1642
        #define FID_BITSTREAM_HORATIO                       0x3641
        #define FID_PS_HORATIO                              0x2641
        #define FID_DTC_HORATIO                             0x1641
        #define FID_BITSTREAM_HIGHLIGHT                     0x3640
        #define FID_PS_HIGHLIGHT                            0x2640
        #define FID_DTC_HIGHLIGHT                           0x1640
        #define FID_BITSTREAM_HADFIELD                      0x363f
        #define FID_PS_HADFIELD                             0x263f
        #define FID_DTC_HADFIELD                            0x163f
        #define FID_BITSTREAM_GLASER_STENCIL                0x363e
        #define FID_PS_GLASER_STENCIL                       0x263e
        #define FID_DTC_GLASER_STENCIL                      0x163e
        #define FID_BITSTREAM_GILL_KAYO                     0x363d
        #define FID_PS_GILL_KAYO                            0x263d
        #define FID_DTC_GILL_KAYO                           0x163d
        #define FID_BITSTREAM_GALADRIEL                     0x363c
        #define FID_PS_GALADRIEL                            0x263c
        #define FID_DTC_GALADRIEL                           0x163c
        #define FID_BITSTREAM_FUTURA_DISPLAY                0x363b
        #define FID_PS_FUTURA_DISPLAY                       0x263b
        #define FID_DTC_FUTURA_DISPLAY                      0x163b
        #define FID_BITSTREAM_FUTURA_C_BLACK                0x363a
        #define FID_PS_FUTURA_C_BLACK                       0x263a
        #define FID_DTC_FUTURA_C_BLACK                      0x163a
        #define FID_BITSTREAM_FRANKFURTER                   0x3639
        #define FID_PS_FRANKFURTER                          0x2639
        #define FID_DTC_FRANKFURTER                         0x1639
        #define FID_BITSTREAM_FLORA                         0x3638
        #define FID_PS_FLORA                                0x2638
        #define FID_DTC_FLORA                               0x1638
        #define FID_BITSTREAM_FLANGE                        0x3637
        #define FID_PS_FLANGE                               0x2637
        #define FID_DTC_FLANGE                              0x1637
        #define FID_BITSTREAM_FLASH                         0x3636
        #define FID_PS_FLASH                                0x2636
        #define FID_DTC_FLASH                               0x1636
        #define FID_BITSTREAM_FLAMENCO                      0x3635
        #define FID_PS_FLAMENCO                             0x2635
        #define FID_DTC_FLAMENCO                            0x1635
        #define FID_BITSTREAM_FETTE_GOTILCH                 0x3634
        #define FID_PS_FETTE_GOTILCH                        0x2634
        #define FID_DTC_FETTE_GOTILCH                       0x1634
        #define FID_BITSTREAM_FETTE_FRAKTUR                 0x3633
        #define FID_PS_FETTE_FRAKTUR                        0x2633
        #define FID_DTC_FETTE_FRAKTUR                       0x1633
        #define FID_BITSTREAM_ENVIRO                        0x3632
        #define FID_PS_ENVIRO                               0x2632
        #define FID_DTC_ENVIRO                              0x1632
        #define FID_BITSTREAM_EINHORN                       0x3631
        #define FID_PS_EINHORN                              0x2631
        #define FID_DTC_EINHORN                             0x1631
        #define FID_BITSTREAM_ECKMANN                       0x3630
        #define FID_PS_ECKMANN                              0x2630
        #define FID_DTC_ECKMANN                             0x1630
        #define FID_BITSTREAM_DYNAMO                        0x362f
        #define FID_PS_DYNAMO                               0x262f
        #define FID_DTC_DYNAMO                              0x162f
        #define FID_BITSTREAM_DOM_CASUAL                    0x362e
        #define FID_PS_DOM_CASUAL                           0x262e
        #define FID_DTC_DOM_CASUAL                          0x162e
        #define FID_BITSTREAM_DAVIDA                        0x362d
        #define FID_PS_DAVIDA                               0x262d
        #define FID_DTC_DAVIDA                              0x162d
        #define FID_BITSTREAM_CROISSANT                     0x362c
        #define FID_PS_CROISSANT                            0x262c
        #define FID_DTC_CROISSANT                           0x162c
        #define FID_BITSTREAM_CRILLEE                       0x362b
        #define FID_PS_CRILLEE                              0x262b
        #define FID_DTC_CRILLEE                             0x162b
        #define FID_BITSTREAM_COUNTDOWN                     0x362a
        #define FID_PS_COUNTDOWN                            0x262a
        #define FID_DTC_COUNTDOWN                           0x162a
        #define FID_BITSTREAM_CORTEZ                        0x3629
        #define FID_PS_CORTEZ                               0x2629
        #define FID_DTC_CORTEZ                              0x1629
        #define FID_BITSTREAM_CONFERENCE                    0x3628
        #define FID_PS_CONFERENCE                           0x2628
        #define FID_DTC_CONFERENCE                          0x1628
        #define FID_BITSTREAM_COMPANY                       0x3627
        #define FID_PS_COMPANY                              0x2627
        #define FID_DTC_COMPANY                             0x1627
        #define FID_BITSTREAM_COLUMNA_SOLID                 0x3626
        #define FID_PS_COLUMNA_SOLID                        0x2626
        #define FID_DTC_COLUMNA_SOLID                       0x1626
        #define FID_BITSTREAM_CITY                          0x3625
        #define FID_PS_CITY                                 0x2625
        #define FID_DTC_CITY                                0x1625
        #define FID_BITSTREAM_CIRKULUS                      0x3624
        #define FID_PS_CIRKULUS                             0x2624
        #define FID_DTC_CIRKULUS                            0x1624
        #define FID_BITSTREAM_CHURCHWARD_BRUSH              0x3623
        #define FID_PS_CHURCHWARD_BRUSH                     0x2623
        #define FID_DTC_CHURCHWARD_BRUSH                    0x1623
        #define FID_BITSTREAM_CHROMIUM_ONE                  0x3622
        #define FID_PS_CHROMIUM_ONE                         0x2622
        #define FID_DTC_CHROMIUM_ONE                        0x1622
        #define FID_BITSTREAM_CHOC                          0x3621
        #define FID_PS_CHOC                                 0x2621
        #define FID_DTC_CHOC                                0x1621
        #define FID_BITSTREAM_CHISEL                        0x3620
        #define FID_PS_CHISEL                               0x2620
        #define FID_DTC_CHISEL                              0x1620
        #define FID_BITSTREAM_CHESTERFIELD                  0x361f
        #define FID_PS_CHESTERFIELD                         0x261f
        #define FID_DTC_CHESTERFIELD                        0x161f
        #define FID_BITSTREAM_CAROUSEL                      0x361e
        #define FID_PS_CAROUSEL                             0x261e
        #define FID_DTC_CAROUSEL                            0x161e
        #define FID_BITSTREAM_CAMELLIA                      0x361d
        #define FID_PS_CAMELLIA                             0x261d
        #define FID_DTC_CAMELLIA                            0x161d
        #define FID_BITSTREAM_CABARET                       0x361c
        #define FID_PS_CABARET                              0x261c
        #define FID_DTC_CABARET                             0x161c
        #define FID_BITSTREAM_BUXOM                         0x361b
        #define FID_PS_BUXOM                                0x261b
        #define FID_DTC_BUXOM                               0x161b
        #define FID_BITSTREAM_BUSTER                        0x361a
        #define FID_PS_BUSTER                               0x261a
        #define FID_DTC_BUSTER                              0x161a
        #define FID_BITSTREAM_BOTTLENECK                    0x3619
        #define FID_PS_BOTTLENECK                           0x2619
        #define FID_DTC_BOTTLENECK                          0x1619
        #define FID_BITSTREAM_BLOCK                         0x3618
        #define FID_PS_BLOCK                                0x2618
        #define FID_DTC_BLOCK                               0x1618
        #define FID_BITSTREAM_BINNER                        0x3617
        #define FID_PS_BINNER                               0x2617
        #define FID_DTC_BINNER                              0x1617
        #define FID_BITSTREAM_BERNHARD_ANTIQUE              0x3616
        #define FID_PS_BERNHARD_ANTIQUE                     0x2616
        #define FID_DTC_BERNHARD_ANTIQUE                    0x1616
        #define FID_BITSTREAM_BELSHAW                       0x3615
        #define FID_PS_BELSHAW                              0x2615
        #define FID_DTC_BELSHAW                             0x1615
        #define FID_BITSTREAM_BARCELONA                     0x3614
        #define FID_PS_BARCELONA                            0x2614
        #define FID_DTC_BARCELONA                           0x1614
        #define FID_BITSTREAM_BAUHAUS                       0x3613
        #define FID_PS_BAUHAUS                              0x2613
        #define FID_DTC_BAUHAUS                             0x1613
        #define FID_BITSTREAM_AUGUSTEA_OPEN                 0x3612
        #define FID_PS_AUGUSTEA_OPEN                        0x2612
        #define FID_DTC_AUGUSTEA_OPEN                       0x1612
        #define FID_BITSTREAM_AMERICAN_UNCIAL               0x3611
        #define FID_PS_AMERICAN_UNCIAL                      0x2611
        #define FID_DTC_AMERICAN_UNCIAL                     0x1611
        #define FID_BITSTREAM_ULTE_SCHWABACHER              0x3610
        #define FID_PS_ULTE_SCHWABACHER                     0x2610
        #define FID_DTC_ULTE_SCHWABACHER                    0x1610
        #define FID_BITSTREAM_ARNOLD_BOCKLIN                0x360f
        #define FID_PS_ARNOLD_BOCKLIN                       0x260f
        #define FID_DTC_ARNOLD_BOCKLIN                      0x160f
        #define FID_BITSTREAM_ALGERIAN                      0x360e
        #define FID_PS_ALGERIAN                             0x260e
        #define FID_DTC_ALGERIAN                            0x160e
        #define FID_BITSTREAM_PUMP                          0x360d
        #define FID_PS_PUMP                                 0x260d
        #define FID_DTC_PUMP                                0x160d
        #define FID_BITSTREAM_MARIAGE                       0x360c
        #define FID_PS_MARIAGE                              0x260c
        #define FID_DTC_MARIAGE                             0x160c
        #define FID_BITSTREAM_OLD_TOWN                      0x360b
        #define FID_PS_OLD_TOWN                             0x260b
        #define FID_DTC_OLD_TOWN                            0x160b
        #define FID_BITSTREAM_HOBO                          0x360a
        #define FID_PS_HOBO                                 0x260a
        #define FID_DTC_HOBO                                0x160a
        #define FID_BITSTREAM_GOUDY_HEAVYFACE               0x3609
        #define FID_PS_GOUDY_HEAVYFACE                      0x2609
        #define FID_DTC_GOUDY_HEAVYFACE                     0x1609
        #define FID_BITSTREAM_DATA_70                       0x3608
        #define FID_PS_DATA_70                              0x2608
        #define FID_DTC_DATA_70                             0x1608
        #define FID_BITSTREAM_LCD                           0x3607
        #define FID_PS_LCD                                  0x2607
        #define FID_DTC_LCD                                 0x1607
        #define FID_BITSTREAM_BALLOON                       0x3606
        #define FID_PS_BALLOON                              0x2606
        #define FID_DTC_BALLOON                             0x1606
        #define FID_BITSTREAM_BLIPPO_C_BLACK                0x3605
        #define FID_PS_BLIPPO_C_BLACK                       0x2605
        #define FID_DTC_BLIPPO_C_BLACK                      0x1605
        #define FID_BITSTREAM_COOPER_C_BLACK                0x3604
        #define FID_PS_COOPER_C_BLACK                       0x2604
        #define FID_DTC_COOPER_C_BLACK                      0x1604
        #define FID_BITSTREAM_COPPERPLATE                   0x3603
        #define FID_PS_COPPERPLATE                          0x2603
        #define FID_DTC_COPPERPLATE                         0x1603
        #define FID_BITSTREAM_STENCIL                       0x3602
        #define FID_PS_STENCIL                              0x2602
        #define FID_DTC_STENCIL                             0x1602
        #define FID_BITSTREAM_OLD_ENGLISH                   0x3601
        #define FID_PS_OLD_ENGLISH                          0x2601
        #define FID_DTC_OLD_ENGLISH                         0x1601
        #define FID_BITSTREAM_BROADWAY                      0x3600
        #define FID_PS_BROADWAY                             0x2600
        #define FID_DTC_BROADWAY                            0x1600
        #define FID_BITSTREAM_NUPITAL_SCRIPT                0x3430
        #define FID_PS_NUPITAL_SCRIPT                       0x2430
        #define FID_DTC_NUPITAL_SCRIPT                      0x1430
        #define FID_BITSTREAM_MEDICI_SCRIPT                 0x342f
        #define FID_PS_MEDICI_SCRIPT                        0x242f
        #define FID_DTC_MEDICI_SCRIPT                       0x142f
        #define FID_BITSTREAM_CHARME                        0x342e
        #define FID_PS_CHARME                               0x242e
        #define FID_DTC_CHARME                              0x142e
        #define FID_BITSTREAM_CASCADE_SCRIPT                0x342d
        #define FID_PS_CASCADE_SCRIPT                       0x242d
        #define FID_DTC_CASCADE_SCRIPT                      0x142d
        #define FID_BITSTREAM_LITHOS                        0x342c
        #define FID_PS_LITHOS                               0x242c
        #define FID_DTC_LITHOS                              0x142c
        #define FID_BITSTREAM_TEKTON                        0x342b
        #define FID_PS_TEKTON                               0x242b
        #define FID_DTC_TEKTON                              0x142b
        #define FID_BITSTREAM_VLADIMIR_SCRIPT               0x342a
        #define FID_PS_VLADIMIR_SCRIPT                      0x242a
        #define FID_DTC_VLADIMIR_SCRIPT                     0x142a
        #define FID_BITSTREAM_VAN_DIJK                      0x3429
        #define FID_PS_VAN_DIJK                             0x2429
        #define FID_DTC_VAN_DIJK                            0x1429
        #define FID_BITSTREAM_SLOGAN                        0x3428
        #define FID_PS_SLOGAN                               0x2428
        #define FID_DTC_SLOGAN                              0x1428
        #define FID_BITSTREAM_SHAMROCK                      0x3427
        #define FID_PS_SHAMROCK                             0x2427
        #define FID_DTC_SHAMROCK                            0x1427
        #define FID_BITSTREAM_ROMAN_SCRIPT                  0x3426
        #define FID_PS_ROMAN_SCRIPT                         0x2426
        #define FID_DTC_ROMAN_SCRIPT                        0x1426
        #define FID_BITSTREAM_RAGE                          0x3425
        #define FID_PS_RAGE                                 0x2425
        #define FID_DTC_RAGE                                0x1425
        #define FID_BITSTREAM_PRESENT_SCRIPT                0x3424
        #define FID_PS_PRESENT_SCRIPT                       0x2424
        #define FID_DTC_PRESENT_SCRIPT                      0x1424
        #define FID_BITSTREAM_PHYLLIS_INITIALS              0x3423
        #define FID_PS_PHYLLIS_INITIALS                     0x2423
        #define FID_DTC_PHYLLIS_INITIALS                    0x1423
        #define FID_BITSTREAM_PHYLLIS                       0x3422
        #define FID_PS_PHYLLIS                              0x2422
        #define FID_DTC_PHYLLIS                             0x1422
        #define FID_BITSTREAM_PEPITA                        0x3421
        #define FID_PS_PEPITA                               0x2421
        #define FID_DTC_PEPITA                              0x1421
        #define FID_BITSTREAM_PENDRY_SCRIPT                 0x3420
        #define FID_PS_PENDRY_SCRIPT                        0x2420
        #define FID_DTC_PENDRY_SCRIPT                       0x1420
        #define FID_BITSTREAM_PALETTE                       0x341f
        #define FID_PS_PALETTE                              0x241f
        #define FID_DTC_PALETTE                             0x141f
        #define FID_BITSTREAM_PALACE_SCRIPT                 0x341e
        #define FID_PS_PALACE_SCRIPT                        0x241e
        #define FID_DTC_PALACE_SCRIPT                       0x141e
        #define FID_BITSTREAM_NEVISON_CASUAL                0x341d
        #define FID_PS_NEVISON_CASUAL                       0x241d
        #define FID_DTC_NEVISON_CASUAL                      0x141d
        #define FID_BITSTREAM_HILL                          0x341c
        #define FID_PS_HILL                                 0x241c
        #define FID_DTC_HILL                                0x141c
        #define FID_BITSTREAM_LINOSCRIPT                    0x341b
        #define FID_PS_LINOSCRIPT                           0x241b
        #define FID_DTC_LINOSCRIPT                          0x141b
        #define FID_BITSTREAM_LINDSAY                       0x341a
        #define FID_PS_LINDSAY                              0x241a
        #define FID_DTC_LINDSAY                             0x141a
        #define FID_BITSTREAM_LE_GRIFFE                     0x3419
        #define FID_PS_LE_GRIFFE                            0x2419
        #define FID_DTC_LE_GRIFFE                           0x1419
        #define FID_BITSTREAM_KUNSTLERSCHREIBSCHRIFT        0x3418
        #define FID_PS_KUNSTLERSCHREIBSCHRIFT               0x2418
        #define FID_DTC_KUNSTLERSCHREIBSCHRIFT              0x1418
        #define FID_BITSTREAM_JULIA_SCRIPT                  0x3417
        #define FID_PS_JULIA_SCRIPT                         0x2417
        #define FID_DTC_JULIA_SCRIPT                        0x1417
        #define FID_BITSTREAM_ISBELL                        0x3416
        #define FID_PS_ISBELL                               0x2416
        #define FID_DTC_ISBELL                              0x1416
        #define FID_BITSTREAM_ISADORA                       0x3415
        #define FID_PS_ISADORA                              0x2415
        #define FID_DTC_ISADORA                             0x1415
        #define FID_BITSTREAM_HOGARTH_SCRIPT                0x3414
        #define FID_PS_HOGARTH_SCRIPT                       0x2414
        #define FID_DTC_HOGARTH_SCRIPT                      0x1414
        #define FID_BITSTREAM_HARLOW                        0x3413
        #define FID_PS_HARLOW                               0x2413
        #define FID_DTC_HARLOW                              0x1413
        #define FID_BITSTREAM_GLASTONBURY                   0x3412
        #define FID_PS_GLASTONBURY                          0x2412
        #define FID_DTC_GLASTONBURY                         0x1412
        #define FID_BITSTREAM_GILLIES_GOTHIC                0x3411
        #define FID_PS_GILLIES_GOTHIC                       0x2411
        #define FID_DTC_GILLIES_GOTHIC                      0x1411
        #define FID_BITSTREAM_FREESTYLE_SCRIPT              0x3410
        #define FID_PS_FREESTYLE_SCRIPT                     0x2410
        #define FID_DTC_FREESTYLE_SCRIPT                    0x1410
        #define FID_BITSTREAM_ENGLISCHE_SCHREIBSCHRIFT      0x340f
        #define FID_PS_ENGLISCHE_SCHREIBSCHRIFT             0x240f
        #define FID_DTC_ENGLISCHE_SCHREIBSCHRIFT            0x140f
        #define FID_BITSTREAM_DEMIAN                        0x340e
        #define FID_PS_DEMIAN                               0x240e
        #define FID_DTC_DEMIAN                              0x140e
        #define FID_BITSTREAM_CANDICE                       0x340d
        #define FID_PS_CANDICE                              0x240d
        #define FID_DTC_CANDICE                             0x140d
        #define FID_BITSTREAM_BRONX                         0x340c
        #define FID_PS_BRONX                                0x240c
        #define FID_DTC_BRONX                               0x140x
        #define FID_BITSTREAM_BRODY                         0x340b
        #define FID_PS_BRODY                                0x240b
        #define FID_DTC_BRODY                               0x140b
        #define FID_BITSTREAM_BIBLE_SCRIPT                  0x340a
        #define FID_PS_BIBLE_SCRIPT                         0x240a
        #define FID_DTC_BIBLE_SCRIPT                        0x140a
        #define FID_BITSTREAM_ARISTON                       0x3409
        #define FID_PS_ARISTON                              0x2409
        #define FID_DTC_ARISTON                             0x1409
        #define FID_BITSTREAM_ANGLIA                        0x3408
        #define FID_PS_ANGLIA                               0x2408
        #define FID_DTC_ANGLIA                              0x1408
        #define FID_BITSTREAM_MISTRAL                       0x3407
        #define FID_PS_MISTRAL                              0x2407
        #define FID_DTC_MISTRAL                             0x1407
        #define FID_BITSTREAM_BALMORAL                      0x3406
        #define FID_PS_BALMORAL                             0x2406
        #define FID_DTC_BALMORAL                            0x1406
        #define FID_BITSTREAM_COMMERCIAL_SCRIPT             0x3405
        #define FID_PS_COMMERCIAL_SCRIPT                    0x2405
        #define FID_DTC_COMMERCIAL_SCRIPT                   0x1405
        #define FID_BITSTREAM_KAUFMANN                      0x3404
        #define FID_PS_KAUFMANN                             0x2404
        #define FID_DTC_KAUFMANN                            0x1404
        #define FID_BITSTREAM_PARK_AVENUE                   0x3403
        #define FID_PS_PARK_AVENUE                          0x2403
        #define FID_DTC_PARK_AVENUE                         0x1403
        #define FID_BITSTREAM_BRUSH_SCRIPT                  0x3402
        #define FID_PS_BRUSH_SCRIPT                         0x2402
        #define FID_DTC_BRUSH_SCRIPT                        0x1402
        #define FID_BITSTREAM_VIVALDI                       0x3401
        #define FID_PS_VIVALDI                              0x2401
        #define FID_DTC_VIVALDI                             0x1401
        #define FID_BITSTREAM_ZAPF_CHANCERY                 0x3400
        #define FID_PS_ZAPF_CHANCERY                        0x2400
        #define FID_DTC_ZAPF_CHANCERY                       0x1400
        #define FID_BITSTREAM_AVANTE_GARDE_CONDENSED        0x323d
        #define FID_PS_AVANTE_GARDE_CONDENSED               0x223d
        #define FID_DTC_AVANTE_GARDE_CONDENSED              0x123d
        #define FID_BITSTREAM_INSIGNIA                      0x323c
        #define FID_PS_INSIGNIA                             0x223c
        #define FID_DTC_INSIGNIA                            0x123c
        #define FID_BITSTREAM_INDUSTRIA                     0x323b
        #define FID_PS_INDUSTRIA                            0x223b
        #define FID_DTC_INDUSTRIA                           0x123b
        #define FID_BITSTREAM_DORIC_BOLD                    0x323a
        #define FID_PS_DORIC_BOLD                           0x223a
        #define FID_DTC_DORIC_BOLD                          0x123a
        #define FID_BITSTREAM_AKZINDENZ_GROTESK             0x3239
        #define FID_PS_AKZINDENZ_GROTESK                    0x2239
        #define FID_DTC_AKZINDENZ_GROTESK                   0x1239
        #define FID_BITSTREAM_GROTESK                       0x3238
        #define FID_PS_GROTESK                              0x2238
        #define FID_DTC_GROTESK                             0x1238
        #define FID_BITSTREAM_TEMPO                         0x3237
        #define FID_PS_TEMPO                                0x2237
        #define FID_DTC_TEMPO                               0x1237
        #define FID_BITSTREAM_SYNTAX                        0x3236
        #define FID_PS_SYNTAX                               0x2236
        #define FID_DTC_SYNTAX                              0x1236
        #define FID_BITSTREAM_STONE_SANS                    0x3235
        #define FID_PS_STONE_SANS                           0x2235
        #define FID_DTC_STONE_SANS                          0x1235
        #define FID_BITSTREAM_SERIF_GOTHIC                  0x3234
        #define FID_PS_SERIF_GOTHIC                         0x2234
        #define FID_DTC_SERIF_GOTHIC                        0x1234
        #define FID_BITSTREAM_PRIMUS_ANTIQUA                0x3233
        #define FID_PS_PRIMUS_ANTIQUA                       0x2233
        #define FID_DTC_PRIMUS_ANTIQUA                      0x1233
        #define FID_BITSTREAM_PRIMUS                        0x3232
        #define FID_PS_PRIMUS                               0x2232
        #define FID_DTC_PRIMUS                              0x1232
        #define FID_BITSTREAM_PRAXIS                        0x3231
        #define FID_PS_PRAXIS                               0x2231
        #define FID_DTC_PRAXIS                              0x1231
        #define FID_BITSTREAM_PANACHE                       0x3230
        #define FID_PS_PANACHE                              0x2230
        #define FID_DTC_PANACHE                             0x1230
        #define FID_BITSTREAM_OCR_B                         0x322f
        #define FID_PS_OCR_B                                0x222f
        #define FID_DTC_OCR_B                               0x122f
        #define FID_BITSTREAM_OCR_A                         0x322e
        #define FID_PS_OCR_A                                0x222e
        #define FID_DTC_OCR_A                               0x122e
        #define FID_BITSTREAM_NEWTEXT                       0x322d
        #define FID_PS_NEWTEXT                              0x222d
        #define FID_DTC_NEWTEXT                             0x122d
        #define FID_BITSTREAM_NEWS_GOTHIC                   0x322c
        #define FID_PS_NEWS_GOTHIC                          0x222c
        #define FID_DTC_NEWS_GOTHIC                         0x122c
        #define FID_BITSTREAM_NEUZEIT_GROTESK               0x322b
        #define FID_PS_NEUZEIT_GROTESK                      0x222b
        #define FID_DTC_NEUZEIT_GROTESK                     0x122b
        #define FID_BITSTREAM_MIXAGE                        0x322a
        #define FID_PS_MIXAGE                               0x222a
        #define FID_DTC_MIXAGE                              0x122a
        #define FID_BITSTREAM_MAXIMA                        0x3229
        #define FID_PS_MAXIMA                               0x2229
        #define FID_DTC_MAXIMA                              0x1229
        #define FID_BITSTREAM_LUCIDA_SANS                   0x3228
        #define FID_PS_LUCIDA_SANS                          0x2228
        #define FID_DTC_LUCIDA_SANS                         0x1228
        #define FID_BITSTREAM_LITERA                        0x3227
        #define FID_PS_LITERA                               0x2227
        #define FID_DTC_LITERA                              0x1227
        #define FID_BITSTREAM_KABEL                         0x3226
        #define FID_PS_KABEL                                0x2226
        #define FID_DTC_KABEL                               0x1226
        #define FID_BITSTREAM_HOLSATIA                      0x3225
        #define FID_PS_HOLSATIA                             0x2225
        #define FID_DTC_HOLSATIA                            0x1225
        #define FID_BITSTREAM_HELVETICA_INSERAT             0x3224
        #define FID_PS_HELVETICA_INSERAT                    0x2224
        #define FID_DTC_HELVETICA_INSERAT                   0x1224
        #define FID_BITSTREAM_NEUE_HELVETICA                0x3223
        #define FID_PS_NEUE_HELVETICA                       0x2223
        #define FID_DTC_NEUE_HELVETICA                      0x1223
        #define FID_BITSTREAM_HELVETICA                     0x3222
        #define FID_PS_HELVETICA                            0x2222
        #define FID_DTC_HELVETICA                           0x1222
        #define FID_BITSTREAM_HAAS_UNICA                    0x3221
        #define FID_PS_HAAS_UNICA                           0x2221
        #define FID_DTC_HAAS_UNICA                          0x1221
        #define FID_BITSTREAM_GOUDY_SANS                    0x3220
        #define FID_PS_GOUDY_SANS                           0x2220
        #define FID_DTC_GOUDY_SANS                          0x1220
        #define FID_BITSTREAM_GOTHIC                        0x321f
        #define FID_PS_GOTHIC                               0x221f
        #define FID_DTC_GOTHIC                              0x121f
        #define FID_BITSTREAM_GILL_SANS                     0x321e
        #define FID_PS_GILL_SANS                            0x221e
        #define FID_DTC_GILL_SANS                           0x121e
        #define FID_BITSTREAM_GILL                          0x321d
        #define FID_PS_GILL                                 0x221d
        #define FID_DTC_GILL                                0x121d
        #define FID_BITSTREAM_FUTURA                        0x321c
        #define FID_PS_FUTURA                               0x221c
        #define FID_DTC_FUTURA                              0x121c
        #define FID_BITSTREAM_FOLIO                         0x321b
        #define FID_PS_FOLIO                                0x221b
        #define FID_DTC_FOLIO                               0x121b
        #define FID_BITSTREAM_FLYER                         0x321a
        #define FID_PS_FLYER                                0x221a
        #define FID_DTC_FLYER                               0x121a
        #define FID_BITSTREAM_FETTE_MIDSCHRIFT              0x3219
        #define FID_PS_FETTE_MIDSCHRIFT                     0x2219
        #define FID_DTC_FETTE_MIDSCHRIFT                    0x1219
        #define FID_BITSTREAM_FETTE_ENGSCHRIFT              0x3218
        #define FID_PS_FETTE_ENGSCHRIFT                     0x2218
        #define FID_DTC_FETTE_ENGSCHRIFT                    0x1218
        #define FID_BITSTREAM_ERAS                          0x3217
        #define FID_PS_ERAS                                 0x2217
        #define FID_DTC_ERAS                                0x1217
        #define FID_BITSTREAM_DIGI_GROTESK                  0x3216
        #define FID_PS_DIGI_GROTESK                         0x2216
        #define FID_DTC_DIGI_GROTESK                        0x1216
        #define FID_BITSTREAM_CORINTHIAN                    0x3215
        #define FID_PS_CORINTHIAN                           0x2215
        #define FID_DTC_CORINTHIAN                          0x1215
        #define FID_BITSTREAM_COMPACTA                      0x3214
        #define FID_PS_COMPACTA                             0x2214
        #define FID_DTC_COMPACTA                            0x1214
        #define FID_BITSTREAM_CLEARFACE_GOTHIC              0x3213
        #define FID_PS_CLEARFACE_GOTHIC                     0x2213
        #define FID_DTC_CLEARFACE_GOTHIC                    0x1213
        #define FID_BITSTREAM_OPTIMA                        0x3212
        #define FID_PS_OPTIMA                               0x2212
        #define FID_DTC_OPTIMA                              0x1212
        #define FID_BITSTREAM_CHELMSFORD                    0x3211
        #define FID_PS_CHELMSFORD                           0x2211
        #define FID_DTC_CHELMSFORD                          0x1211
        #define FID_BITSTREAM_CASTLE                        0x3210
        #define FID_PS_CASTLE                               0x2210
        #define FID_DTC_CASTLE                              0x1210
        #define FID_BITSTREAM_BRITANNIC                     0x320f
        #define FID_PS_BRITANNIC                            0x220f
        #define FID_DTC_BRITANNIC                           0x120f
        #define FID_BITSTREAM_BERLINER_GROTESK              0x320e
        #define FID_PS_BERLINER_GROTESK                     0x220e
        #define FID_DTC_BERLINER_GROTESK                    0x120e
        #define FID_BITSTREAM_BENGUIAT_GOTHIC               0x320d
        #define FID_PS_BENGUIAT_GOTHIC                      0x220d
        #define FID_DTC_BENGUIAT_GOTHIC                     0x120d
        #define FID_BITSTREAM_AVANTE_GARDE                  0x320c
        #define FID_PS_AVANTE_GARDE                         0x220c
        #define FID_DTC_AVANTE_GARDE                        0x120c
        #define FID_BITSTREAM_ANZEIGEN_GROTESK              0x320b
        #define FID_PS_ANZEIGEN_GROTESK                     0x220b
        #define FID_DTC_ANZEIGEN_GROTESK                    0x120b
        #define FID_BITSTREAM_ANTIQUE_OLIVE                 0x320a
        #define FID_PS_ANTIQUE_OLIVE                        0x220a
        #define FID_DTC_ANTIQUE_OLIVE                       0x120a
        #define FID_BITSTREAM_ALTERNATE_GOTHIC              0x3209
        #define FID_PS_ALTERNATE_GOTHIC                     0x2209
        #define FID_DTC_ALTERNATE_GOTHIC                    0x1209
        #define FID_BITSTREAM_AKZIDENZ_GROTESK_BUCH         0x3208
        #define FID_PS_AKZIDENZ_GROTESK_BUCH                0x2208
        #define FID_DTC_AKZIDENZ_GROTESK_BUCH               0x1208
        #define FID_BITSTREAM_AKZIDENZ_GROTESK              0x3207
        #define FID_PS_AKZIDENZ_GROTESK                     0x2207
        #define FID_DTC_AKZIDENZ_GROTESK                    0x1207
        #define FID_BITSTREAM_AVENIR                        0x3206
        #define FID_PS_AVENIR                               0x2206
        #define FID_DTC_AVENIR                              0x1206
        #define FID_BITSTREAM_UNIVERS                       0x3205
        #define FID_PS_UNIVERS                              0x2205
        #define FID_DTC_UNIVERS                             0x1205
        #define FID_BITSTREAM_FRANKLIN_GOTHIC               0x3204
        #define FID_PS_FRANKLIN_GOTHIC                      0x2204
        #define FID_DTC_FRANKLIN_GOTHIC                     0x1204
        #define FID_BITSTREAM_ANGRO                         0x3203
        #define FID_PS_ANGRO                                0x2203
        #define FID_DTC_ANGRO                               0x1203
        #define FID_BITSTREAM_EUROSTILE                     0x3202
        #define FID_PS_EUROSTILE                            0x2202
        #define FID_DTC_EUROSTILE                           0x1202
        #define FID_BITSTREAM_FRUTIGER                      0x3201
        #define FID_PS_FRUTIGER                             0x2201
        #define FID_DTC_FRUTIGER                            0x1201
        #define FID_BITSTREAM_URW_SANS                      0x3200
        #define FID_PS_URW_SANS                             0x2200
        #define FID_DTC_URW_SANS                            0x1200
        #define FID_BITSTREAM_GALLIARD_ROMAN_ITALIC         0x307e
        #define FID_PS_GALLIARD_ROMAN_ITALIC                0x207e
        #define FID_DTC_GALLIARD_ROMAN_ITALIC               0x107e
        #define FID_BITSTREAM_GRANJON                       0x307d
        #define FID_PS_GRANJON                              0x207d
        #define FID_DTC_GRANJON                             0x107d
        #define FID_BITSTREAM_GARTH_GRAPHIC                 0x307c
        #define FID_PS_GARTH_GRAPHIC                        0x207c
        #define FID_DTC_GARTH_GRAPHIC                       0x107c
        #define FID_BITSTREAM_BAUER_BODONI                  0x307b
        #define FID_PS_BAUER_BODONI                         0x207b
        #define FID_DTC_BAUER_BODONI                        0x107b
        #define FID_BITSTREAM_BELWE                         0x307a
        #define FID_PS_BELWE                                0x207a
        #define FID_DTC_BELWE                               0x107a
        #define FID_BITSTREAM_CHARLEMAGNE                   0x3079
        #define FID_PS_CHARLEMAGNE                          0x2079
        #define FID_DTC_CHARLEMAGNE                         0x1079
        #define FID_BITSTREAM_TRAJAN                        0x3078
        #define FID_PS_TRAJAN                               0x2078
        #define FID_DTC_TRAJAN                              0x1078
        #define FID_BITSTREAM_ADOBE_GARAMOND                0x3077
        #define FID_PS_ADOBE_GARAMOND                       0x2077
        #define FID_DTC_ADOBE_GARAMOND                      0x1077
        #define FID_BITSTREAM_ZAPF_INTERNATIONAL            0x3076
        #define FID_PS_ZAPF_INTERNATIONAL                   0x2076
        #define FID_DTC_ZAPF_INTERNATIONAL                  0x1076
        #define FID_BITSTREAM_ZAPF_BOOK                     0x3075
        #define FID_PS_ZAPF_BOOK                            0x2075
        #define FID_DTC_ZAPF_BOOK                           0x1075
        #define FID_BITSTREAM_WORCESTER_ROUND               0x3074
        #define FID_PS_WORCESTER_ROUND                      0x2074
        #define FID_DTC_WORCESTER_ROUND                     0x1074
        #define FID_BITSTREAM_WINDSOR                       0x3073
        #define FID_PS_WINDSOR                              0x2073
        #define FID_DTC_WINDSOR                             0x1073
        #define FID_BITSTREAM_WEISS                         0x3072
        #define FID_PS_WEISS                                0x2072
        #define FID_DTC_WEISS                               0x1072
        #define FID_BITSTREAM_WEIDEMANN                     0x3071
        #define FID_PS_WEIDEMANN                            0x2071
        #define FID_DTC_WEIDEMANN                           0x1071
        #define FID_BITSTREAM_WALBAUM                       0x3070
        #define FID_PS_WALBAUM                              0x2070
        #define FID_DTC_WALBAUM                             0x1070
        #define FID_BITSTREAM_VOLTA                         0x306f
        #define FID_PS_VOLTA                                0x206f
        #define FID_DTC_VOLTA                               0x106f
        #define FID_BITSTREAM_VENDOME                       0x306e
        #define FID_PS_VENDOME                              0x206e
        #define FID_DTC_VENDOME                             0x106e
        #define FID_BITSTREAM_VELJOVIC                      0x306d
        #define FID_PS_VELJOVIC                             0x206d
        #define FID_DTC_VELJOVIC                            0x106d
        #define FID_BITSTREAM_ADOBE_UTOPIA                  0x306c
        #define FID_PS_ADOBE_UTOPIA                         0x206c
        #define FID_DTC_ADOBE_UTOPIA                        0x106c
        #define FID_BITSTREAM_USHERWOOD                     0x306b
        #define FID_PS_USHERWOOD                            0x206b
        #define FID_DTC_USHERWOOD                           0x106b
        #define FID_BITSTREAM_URW_ANTIQUA                   0x306a
        #define FID_PS_URW_ANTIQUA                          0x206a
        #define FID_DTC_URW_ANTIQUA                         0x106a
        #define FID_BITSTREAM_TIMES_NEW_ROMAN               0x3069
        #define FID_PS_TIMES_NEW_ROMAN                      0x2069
        #define FID_DTC_TIMES_NEW_ROMAN                     0x1069
        #define FID_BITSTREAM_TIMELESS                      0x3068
        #define FID_PS_TIMELESS                             0x2068
        #define FID_DTC_TIMELESS                            0x1068
        #define FID_BITSTREAM_TIFFANY                       0x3067
        #define FID_PS_TIFFANY                              0x2067
        #define FID_DTC_TIFFANY                             0x1067
        #define FID_BITSTREAM_TIEPOLO                       0x3066
        #define FID_PS_TIEPOLO                              0x2066
        #define FID_DTC_TIEPOLO                             0x1066
        #define FID_BITSTREAM_SWIFT                         0x3065
        #define FID_PS_SWIFT                                0x2065
        #define FID_DTC_SWIFT                               0x1065
        #define FID_BITSTREAM_STYMIE                        0x3064
        #define FID_PS_STYMIE                               0x2064
        #define FID_DTC_STYMIE                              0x1064
        #define FID_BITSTREAM_STRATFORD                     0x3063
        #define FID_PS_STRATFORD                            0x2063
        #define FID_DTC_STRATFORD                           0x1063
        #define FID_BITSTREAM_STONE_SERIF                   0x3062
        #define FID_PS_STONE_SERIF                          0x2062
        #define FID_DTC_STONE_SERIF                         0x1062
        #define FID_BITSTREAM_STONE_INFORMAL                0x3061
        #define FID_PS_STONE_INFORMAL                       0x2061
        #define FID_DTC_STONE_INFORMAL                      0x1061
        #define FID_BITSTREAM_STEMPEL_SCHNEIDLER            0x3060
        #define FID_PS_STEMPEL_SCHNEIDLER                   0x2060
        #define FID_DTC_STEMPEL_SCHNEIDLER                  0x1060
        #define FID_BITSTREAM_SOUVENIR                      0x305f
        #define FID_PS_SOUVENIR                             0x205f
        #define FID_DTC_SOUVENIR                            0x105f
        #define FID_BITSTREAM_SLIMBACH                      0x305e
        #define FID_PS_SLIMBACH                             0x205e
        #define FID_DTC_SLIMBACH                            0x105e
        #define FID_BITSTREAM_SERIFA                        0x305d
        #define FID_PS_SERIFA                               0x205d
        #define FID_DTC_SERIFA                              0x105d
        #define FID_BITSTREAM_SABON_ANTIQUA                 0x305c
        #define FID_PS_SABON_ANTIQUA                        0x205c
        #define FID_DTC_SABON_ANTIQUA                       0x105c
        #define FID_BITSTREAM_SABON                         0x305b
        #define FID_PS_SABON                                0x205b
        #define FID_DTC_SABON                               0x105b
        #define FID_BITSTREAM_ROMANA                        0x305a
        #define FID_PS_ROMANA                               0x205a
        #define FID_DTC_ROMANA                              0x105a
        #define FID_BITSTREAM_ROCKWELL                      0x3059
        #define FID_PS_ROCKWELL                             0x2059
        #define FID_DTC_ROCKWELL                            0x1059
        #define FID_BITSTREAM_RENAULT                       0x3058
        #define FID_PS_RENAULT                              0x2058
        #define FID_DTC_RENAULT                             0x1058
        #define FID_BITSTREAM_RALEIGH                       0x3057
        #define FID_PS_RALEIGH                              0x2057
        #define FID_DTC_RALEIGH                             0x1057
        #define FID_BITSTREAM_QUORUM                        0x3056
        #define FID_PS_QUORUM                               0x2056
        #define FID_DTC_QUORUM                              0x1056
        #define FID_BITSTREAM_PROTEUS                       0x3055
        #define FID_PS_PROTEUS                              0x2055
        #define FID_DTC_PROTEUS                             0x1055
        #define FID_BITSTREAM_PLANTIN                       0x3054
        #define FID_PS_PLANTIN                              0x2054
        #define FID_DTC_PLANTIN                             0x1054
        #define FID_BITSTREAM_PERPETUA                      0x3053
        #define FID_PS_PERPETUA                             0x2053
        #define FID_DTC_PERPETUA                            0x1053
        #define FID_BITSTREAM_PACELLA                       0x3052
        #define FID_PS_PACELLA                              0x2052
        #define FID_DTC_PACELLA                             0x1052
        #define FID_BITSTREAM_NOVARESE                      0x3051
        #define FID_PS_NOVARESE                             0x2051
        #define FID_DTC_NOVARESE                            0x1051
        #define FID_BITSTREAM_NIMROD                        0x3050
        #define FID_PS_NIMROD                               0x2050
        #define FID_DTC_NIMROD                              0x1050
        #define FID_BITSTREAM_NIKIS                         0x304f
        #define FID_PS_NIKIS                                0x204f
        #define FID_DTC_NIKIS                               0x104f
        #define FID_BITSTREAM_NAPOLEAN                      0x304e
        #define FID_PS_NAPOLEAN                             0x204e
        #define FID_DTC_NAPOLEAN                            0x104e
        #define FID_BITSTREAM_MODERN_NO_216                 0x304d
        #define FID_PS_MODERN_NO_216                        0x204d
        #define FID_DTC_MODERN_NO_216                       0x104d
        #define FID_BITSTREAM_MODERN                        0x304c
        #define FID_PS_MODERN                               0x204c
        #define FID_DTC_MODERN                              0x104c
        #define FID_BITSTREAM_MINISTER                      0x304b
        #define FID_PS_MINISTER                             0x204b
        #define FID_DTC_MINISTER                            0x104b
        #define FID_BITSTREAM_MESSIDOR                      0x304a
        #define FID_PS_MESSIDOR                             0x204a
        #define FID_DTC_MESSIDOR                            0x104a
        #define FID_BITSTREAM_MERIDIEN                      0x3049
        #define FID_PS_MERIDIEN                             0x2049
        #define FID_DTC_MERIDIEN                            0x1049
        #define FID_BITSTREAM_MEMPHIS                       0x3048
        #define FID_PS_MEMPHIS                              0x2048
        #define FID_DTC_MEMPHIS                             0x1048
        #define FID_BITSTREAM_MELIOR                        0x3047
        #define FID_PS_MELIOR                               0x2047
        #define FID_DTC_MELIOR                              0x1047
        #define FID_BITSTREAM_MARCONI                       0x3046
        #define FID_PS_MARCONI                              0x2046
        #define FID_DTC_MARCONI                             0x1046
        #define FID_BITSTREAM_MAGNUS                        0x3045
        #define FID_PS_MAGNUS                               0x2045
        #define FID_DTC_MAGNUS                              0x1045
        #define FID_BITSTREAM_MAGNA                         0x3044
        #define FID_PS_MAGNA                                0x2044
        #define FID_DTC_MAGNA                               0x1044
        #define FID_BITSTREAM_MADISON                       0x3043
        #define FID_PS_MADISON                              0x2043
        #define FID_DTC_MADISON                             0x1043
        #define FID_BITSTREAM_LUCIDA                        0x3042
        #define FID_PS_LUCIDA                               0x2042
        #define FID_DTC_LUCIDA                              0x1042
        #define FID_BITSTREAM_LUBALIN_GRAPH                 0x3041
        #define FID_PS_LUBALIN_GRAPH                        0x2041
        #define FID_DTC_LUBALIN_GRAPH                       0x1041
        #define FID_BITSTREAM_LIFE                          0x3040
        #define FID_PS_LIFE                                 0x2040
        #define FID_DTC_LIFE                                0x1040
        #define FID_BITSTREAM_LEAWOOD                       0x303f
        #define FID_PS_LEAWOOD                              0x203f
        #define FID_DTC_LEAWOOD                             0x103f
        #define FID_BITSTREAM_KORINNA                       0x303e
        #define FID_PS_KORINNA                              0x203e
        #define FID_DTC_KORINNA                             0x103e
        #define FID_BITSTREAM_JENSON_OLD_STYLE              0x303d
        #define FID_PS_JENSON_OLD_STYLE                     0x203d
        #define FID_DTC_JENSON_OLD_STYLE                    0x103d
        #define FID_BITSTREAM_JANSON                        0x303c
        #define FID_PS_JANSON                               0x203c
        #define FID_DTC_JANSON                              0x103c
        #define FID_BITSTREAM_JAMILLE                       0x303b
        #define FID_PS_JAMILLE                              0x203b
        #define FID_DTC_JAMILLE                             0x103b
        #define FID_BITSTREAM_ITALIA                        0x303a
        #define FID_PS_ITALIA                               0x203a
        #define FID_DTC_ITALIA                              0x103a
        #define FID_BITSTREAM_IMPRESSUM                     0x3039
        #define FID_PS_IMPRESSUM                            0x2039
        #define FID_DTC_IMPRESSUM                           0x1039
        #define FID_BITSTREAM_HOLLANDER                     0x3038
        #define FID_PS_HOLLANDER                            0x2038
        #define FID_DTC_HOLLANDER                           0x1038
        #define FID_BITSTREAM_HIROSHIGE                     0x3037
        #define FID_PS_HIROSHIGE                            0x2037
        #define FID_DTC_HIROSHIGE                           0x1037
        #define FID_BITSTREAM_HAWTHORN                      0x3036
        #define FID_PS_HAWTHORN                             0x2036
        #define FID_DTC_HAWTHORN                            0x1036
        #define FID_BITSTREAM_GOUDY                         0x3035
        #define FID_PS_GOUDY                                0x2035
        #define FID_DTC_GOUDY                               0x1035
        #define FID_BITSTREAM_GAMMA                         0x3034
        #define FID_PS_GAMMA                                0x2034
        #define FID_DTC_GAMMA                               0x1034
        #define FID_BITSTREAM_GALLIARD                      0x3033
        #define FID_PS_GALLIARD                             0x2033
        #define FID_DTC_GALLIARD                            0x1033
        #define FID_BITSTREAM_FRIZ_QUADRATA                 0x3032
        #define FID_PS_FRIZ_QUADRATA                        0x2032
        #define FID_DTC_FRIZ_QUADRATA                       0x1032
        #define FID_BITSTREAM_FENICE                        0x3031
        #define FID_PS_FENICE                               0x2031
        #define FID_DTC_FENICE                              0x1031
        #define FID_BITSTREAM_EXCELSIOR                     0x3030
        #define FID_PS_EXCELSIOR                            0x2030
        #define FID_DTC_EXCELSIOR                           0x1030
        #define FID_BITSTREAM_ESPRIT                        0x302f
        #define FID_PS_ESPRIT                               0x202f
        #define FID_DTC_ESPRIT                              0x102f
        #define FID_BITSTREAM_ELAN                          0x302e
        #define FID_PS_ELAN                                 0x202e
        #define FID_DTC_ELAN                                0x102e
        #define FID_BITSTREAM_EGYPTIENNE                    0x302d
        #define FID_PS_EGYPTIENNE                           0x202d
        #define FID_DTC_EGYPTIENNE                          0x102d
        #define FID_BITSTREAM_EGIZIO                        0x302c
        #define FID_PS_EGIZIO                               0x202c
        #define FID_DTC_EGIZIO                              0x102c
        #define FID_BITSTREAM_EDWARDIAN                     0x302b
        #define FID_PS_EDWARDIAN                            0x202b
        #define FID_DTC_EDWARDIAN                           0x102b
        #define FID_BITSTREAM_EDISON                        0x302a
        #define FID_PS_EDISON                               0x202a
        #define FID_DTC_EDISON                              0x102a
        #define FID_BITSTREAM_DIGI_ANTIQUA                  0x3029
        #define FID_PS_DIGI_ANTIQUA                         0x2029
        #define FID_DTC_DIGI_ANTIQUA                        0x1029
        #define FID_BITSTREAM_DEMOS                         0x3028
        #define FID_PS_DEMOS                                0x2028
        #define FID_DTC_DEMOS                               0x1028
        #define FID_BITSTREAM_CUSHING                       0x3027
        #define FID_PS_CUSHING                              0x2027
        #define FID_DTC_CUSHING                             0x1027
        #define FID_BITSTREAM_CORONA                        0x3026
        #define FID_PS_CORONA                               0x2026
        #define FID_DTC_CORONA                              0x1026
        #define FID_BITSTREAM_CONGRESS                      0x3025
        #define FID_PS_CONGRESS                             0x2025
        #define FID_DTC_CONGRESS                            0x1025
        #define FID_BITSTREAM_CONCORDE_NOVA                 0x3024
        #define FID_PS_CONCORDE_NOVA                        0x2024
        #define FID_DTC_CONCORDE_NOVA                       0x1024
        #define FID_BITSTREAM_CONCORDE                      0x3023
        #define FID_PS_CONCORDE                             0x2023
        #define FID_DTC_CONCORDE                            0x1023
        #define FID_BITSTREAM_CLEARFACE                     0x3022
        #define FID_PS_CLEARFACE                            0x2022
        #define FID_DTC_CLEARFACE                           0x1022
        #define FID_BITSTREAM_CLARENDON                     0x3021
        #define FID_PS_CLARENDON                            0x2021
        #define FID_DTC_CLARENDON                           0x1021
        #define FID_BITSTREAM_CHELTENHAM                    0x3020
        #define FID_PS_CHELTENHAM                           0x2020
        #define FID_DTC_CHELTENHAM                          0x1020
        #define FID_BITSTREAM_CENTURY_OLD_STYLE             0x301f
        #define FID_PS_CENTURY_OLD_STYLE                    0x201f
        #define FID_DTC_CENTURY_OLD_STYLE                   0x101f
        #define FID_BITSTREAM_CENTURY                       0x301e
        #define FID_PS_CENTURY                              0x201e
        #define FID_DTC_CENTURY                             0x101e
        #define FID_BITSTREAM_CENTENNIAL                    0x301d
        #define FID_PS_CENTENNIAL                           0x201d
        #define FID_DTC_CENTENNIAL                          0x101d
        #define FID_BITSTREAM_CAXTON                        0x301c
        #define FID_PS_CAXTON                               0x201c
        #define FID_DTC_CAXTON                              0x101c
        #define FID_BITSTREAM_ADOBE_CASLON                  0x301b
        #define FID_PS_ADOBE_CASLON                         0x201b
        #define FID_DTC_ADOBE_CASLON                        0x101b
        #define FID_BITSTREAM_CASLON                        0x301a
        #define FID_PS_CASLON                               0x201a
        #define FID_DTC_CASLON                              0x101a
        #define FID_BITSTREAM_CANDIDA                       0x3019
        #define FID_PS_CANDIDA                              0x2019
        #define FID_DTC_CANDIDA                             0x1019
        #define FID_BITSTREAM_BOOKMAN                       0x3018
        #define FID_PS_BOOKMAN                              0x2018
        #define FID_DTC_BOOKMAN                             0x1018
        #define FID_BITSTREAM_BASKERVILLE_HANDCUT           0x3017
        #define FID_PS_BASKERVILLE_HANDCUT                  0x2017
        #define FID_DTC_BASKERVILLE_HANDCUT                 0x1017
        #define FID_BITSTREAM_BASKERVILLE                   0x3016
        #define FID_PS_BASKERVILLE                          0x2016
        #define FID_DTC_BASKERVILLE                         0x1016
        #define FID_BITSTREAM_BASILIA                       0x3015
        #define FID_PS_BASILIA                              0x2015
        #define FID_DTC_BASILIA                             0x1015
        #define FID_BITSTREAM_BARBEDOR                      0x3014
        #define FID_PS_BARBEDOR                             0x2014
        #define FID_DTC_BARBEDOR                            0x1014
        #define FID_BITSTREAM_AUREALIA                      0x3013
        #define FID_PS_AUREALIA                             0x2013
        #define FID_DTC_AUREALIA                            0x1013
        #define FID_BITSTREAM_NEW_ASTER                     0x3012
        #define FID_PS_NEW_ASTER                            0x2012
        #define FID_DTC_NEW_ASTER                           0x1012
        #define FID_BITSTREAM_ASTER                         0x3011
        #define FID_PS_ASTER                                0x2011
        #define FID_DTC_ASTER                               0x1011
        #define FID_BITSTREAM_AMERICANA                     0x3010
        #define FID_PS_AMERICANA                            0x2010
        #define FID_DTC_AMERICANA                           0x1010
        #define FID_BITSTREAM_AACHEN                        0x300f
        #define FID_PS_AACHEN                               0x200f
        #define FID_DTC_AACHEN                              0x100f
        #define FID_BITSTREAM_NICOLAS_COCHIN                0x300e
        #define FID_PS_NICOLAS_COCHIN                       0x200e
        #define FID_DTC_NICOLAS_COCHIN                      0x100e
        #define FID_BITSTREAM_COCHIN                        0x300d
        #define FID_PS_COCHIN                               0x200d
        #define FID_DTC_COCHIN                              0x100d
        #define FID_BITSTREAM_ALBERTUS                      0x300c
        #define FID_PS_ALBERTUS                             0x200c
        #define FID_DTC_ALBERTUS                            0x100c
        #define FID_BITSTREAM_ACCOLADE                      0x300b
        #define FID_PS_ACCOLADE                             0x200b
        #define FID_DTC_ACCOLADE                            0x100b
        #define FID_BITSTREAM_PALATINO                      0x300a
        #define FID_PS_PALATINO                             0x200a
        #define FID_DTC_PALATINO                            0x100a
        #define FID_BITSTREAM_GOUDY_OLD_STYLE               0x3009
        #define FID_PS_GOUDY_OLD_STYLE                      0x2009
        #define FID_DTC_GOUDY_OLD_STYLE                     0x1009
        #define FID_BITSTREAM_BERKELEY_OLD_STYLE            0x3008
        #define FID_PS_BERKELEY_OLD_STYLE                   0x2008
        #define FID_DTC_BERKELEY_OLD_STYLE                  0x1008
        #define FID_BITSTREAM_ARSIS                         0x3007
        #define FID_PS_ARSIS                                0x2007
        #define FID_DTC_ARSIS                               0x1007
        #define FID_BITSTREAM_UNIVERSITY_ROMAN              0x3006
        #define FID_PS_UNIVERSITY_ROMAN                     0x2006
        #define FID_DTC_UNIVERSITY_ROMAN                    0x1006
        #define FID_BITSTREAM_BEMBO                         0x3005
        #define FID_PS_BEMBO                                0x2005
        #define FID_DTC_BEMBO                               0x1005
        #define FID_BITSTREAM_GARAMOND                      0x3004
        #define FID_PS_GARAMOND                             0x2004
        #define FID_DTC_GARAMOND                            0x1004
        #define FID_BITSTREAM_GLYPHA                        0x3003
        #define FID_PS_GLYPHA                               0x2003
        #define FID_DTC_GLYPHA                              0x1003
        #define FID_BITSTREAM_BODONI                        0x3002
        #define FID_PS_BODONI                               0x2002
        #define FID_DTC_BODONI                              0x1002
        #define FID_BITSTREAM_CENTURY_SCHOOLBOOK            0x3001
        #define FID_PS_CENTURY_SCHOOLBOOK                   0x2001
        #define FID_DTC_CENTURY_SCHOOLBOOK                  0x1001
        #define FID_BITSTREAM_URW_ROMAN                     0x3000
        #define FID_PS_TIMES_ROMAN                          0x2000
        #define FID_DTC_URW_ROMAN                           0x1000
        #define FID_WINDOWS                                 0x0a01
        #define FID_BISON                                   0x0a00
        #define FID_LED                                     0x0600
        #define FID_PMSYSTEM                                0x0203
        #define FID_BERKELEY                                0x0202
        #define FID_UNIVERSITY                              0x0201
        #define FID_CHICAGO                                 0x0200
        #define FID_ROMA                                    0x0001
        #define FID_INVALID                                 0x0000

Fonts are normally referenced by FontID.

**Include:** fontID.h

----------
#### FontMaker
    typedef word FontMaker;
        #define FM_PRINTER              0xf000
        #define FM_MICROLOGIC           0xe000
        #define FM_ATECH                0xd000
        #define FM_PUBLIC               0xc000
        #define FM_AGFA                 0x4000
        #define FM_BITSTREAM            0x3000
        #define FM_ADOBE                0x2000
        #define FM_NIMBUSQ              0x1000
        #define FM_BITMAP               0x0000
**Include:** fontID.h

----------
#### FontMap
    typedef byte FontMap;
        #define FM_DONT_USE             0x00ff
        #define FM_EXACT                0x0000
**Include:** fontID.h

----------
#### FontWeight
    typedef ByteEnum FontWeight;
        #define FW_ULTRA_LIGHT              0
        #define FW_EXTRA_LIGHT              1
        #define FW_LIGHT                    2
        #define FW_BOOK                     3
        #define FW_NORMAL                   4
        #define FW_DEMI                     5
        #define FW_BOLD                     6
        #define FW_EXTRA_BOLD               7
        #define FW_ULTRA_BOLD               8
        #define FW_BLACK                    9
**Include:** font.h

----------
#### FontWidth
    typedef     ByteEnum FontWidth;
        #define FWI_NARROW                  0
        #define FWI_CONDENSED               1
        #define FWI_MEDIUM                  2
        #define FWI_WIDE                    3
        #define FWI_EXPANDED                4
**Include:** font.h

----------
#### FormatArray
    typedef ClipboardItemFormatInfo FormatArray[CLIPBOARD_MAX_FORMATS];

----------
#### FormatError
    typedef ByteEnum FormatError;
        #define FMT_DONE                                        0
        #define FMT_READY                                       1
        #define FMT_RUNNING                                     2
        #define FMT_DRIVE_NOT_READY                             3
        #define FMT_ERR_WRITING_BOOT                            4
        #define FMT_ERR_WRITING_ROOT_DIR                        5
        #define FMT_ERR_WRITING_FAT                             6
        #define FMT_ABORTED                                     7
        #define FMT_SET_VOLUME_NAME_ERR                         8
        #define FMT_CANNOT_FORMAT_FIXED_DISKS_IN_CUR_RELEASE    9
        #define FMT_BAD_PARTITION_TABLE                         10
        #define FMT_ERR_READING_PARTITION_TABLE                 11
        #define FMT_ERR_NO_PARTITION_FOUND                      12
        #define FMT_ERR_MULTIPLE_PRIMARY_PARTITIONS             13
        #define FMT_ERR_NO_EXTENDED_PARTITION_FOUND             14
        #define FMT_ERR_CANNOT_ALLOC_SECTOR_BUFFER              15
        #define FMT_ERR_DISK_IS_IN_USE                          16
        #define FMT_ERR_WRITE_PROTECTED                         17
        #define FMT_ERR_DRIVE_CANNOT_SUPPORT_GIVEN_FORMAT       18
        #define FMT_ERR_INVALID_DRIVE_SPECIFIED                 19
        #define FMT_ERR_DRIVE_CANNOT_BE_FORMATTED               20
        #define FMT_ERR_DISK_UNAVAILABLE                        21

----------
#### FunctionID
    typedef enum /* word */ {
        FUNCTION_ID_ABS,
        FUNCTION_ID_ACOS,
        FUNCTION_ID_ACOSH,
        FUNCTION_ID_AND,
        FUNCTION_ID_ASIN,
        FUNCTION_ID_ASINH,
        FUNCTION_ID_ATAN,
        FUNCTION_ID_ATAN2,
        FUNCTION_ID_ATANH,
        FUNCTION_ID_AVG, 
        FUNCTION_ID_CHAR,
        FUNCTION_ID_CHOOSE,
        FUNCTION_ID_CLEAN,
        FUNCTION_ID_CODE,
        FUNCTION_ID_COLS,
        FUNCTION_ID_COS,
        FUNCTION_ID_COSH,
        FUNCTION_ID_COUNT,
        FUNCTION_ID_CTERM,
        FUNCTION_ID_DATE,
        FUNCTION_ID_DATEVALUE,
        FUNCTION_ID_DAY,
        FUNCTION_ID_DDB,
        FUNCTION_ID_ERR,
        FUNCTION_ID_EXACT,
        FUNCTION_ID_EXP,
        FUNCTION_ID_FACT,
        FUNCTION_ID_FALSE,
        FUNCTION_ID_FIND,
        FUNCTION_ID_FV,
        FUNCTION_ID_HLOOKUP,
        FUNCTION_ID_HOUR,
        FUNCTION_ID_IF,
        FUNCTION_ID_INDEX,
        FUNCTION_ID_INT,
        FUNCTION_ID_IRR,
        FUNCTION_ID_ISERR,
        FUNCTION_ID_ISNUMBER,
        FUNCTION_ID_ISSTRING,
        FUNCTION_ID_LEFT,
        FUNCTION_ID_LENGTH,
        FUNCTION_ID_LN,
        FUNCTION_ID_LOG,
        FUNCTION_ID_LOWER,
        FUNCTION_ID_MAX,
        FUNCTION_ID_MID,
        FUNCTION_ID_MIN,
        FUNCTION_ID_MINUTE,
        FUNCTION_ID_MOD,
        FUNCTION_ID_MONTH,
        FUNCTION_ID_N,
        FUNCTION_ID_NA,
        FUNCTION_ID_NOW,
        FUNCTION_ID_NPV,
        FUNCTION_ID_OR,
        FUNCTION_ID_PI,
        FUNCTION_ID_PMT,
        FUNCTION_ID_PRODUCT,
        FUNCTION_ID_PROPER,
        FUNCTION_ID_PV,
        FUNCTION_ID_RANDOM_N,
        FUNCTION_ID_RANDOM,
        FUNCTION_ID_RATE,
        FUNCTION_ID_REPEAT,
        FUNCTION_ID_REPLACE,
        FUNCTION_ID_RIGHT,
        FUNCTION_ID_ROUND,
        FUNCTION_ID_ROWS,
        FUNCTION_ID_SECOND,
        FUNCTION_ID_SIN,
        FUNCTION_ID_SINH,
        FUNCTION_ID_SLN,
        FUNCTION_ID_SQRT,
        FUNCTION_ID_STD,
        FUNCTION_ID_STDP,
        FUNCTION_ID_STRING,
        FUNCTION_ID_SUM,
        FUNCTION_ID_SYD,
        FUNCTION_ID_TAN,
        FUNCTION_ID_TANH,
        FUNCTION_ID_TERM,
        FUNCTION_ID_TIME,
        FUNCTION_ID_TIMEVALUE,
        FUNCTION_ID_TODAY,
        FUNCTION_ID_TRIM,
        FUNCTION_ID_TRUE,
        FUNCTION_ID_TRUNC,
        FUNCTION_ID_UPPER,
        FUNCTION_ID_VALUE,
        FUNCTION_ID_VAR,
        FUNCTION_ID_VARP,
        FUNCTION_ID_VLOOKUP,
        FUNCTION_ID_WEEKDAY,
        FUNCTION_ID_YEAR,
        FUNCTION_ID_FILENAME,
        FUNCTION_ID_PAGE,
        FUNCTION_ID_PAGES,
        FUNCTION_ID_FIRST_EXTERNAL_FUNCTION=FUNCTION_ID_FIRST_EXTERNAL_FUNCTION_BASE
    } FunctionID;

----------
#### GCM_info
    typedef enum /* word */ {
        GCMI_MIN_X,
        GCMI_MIN_X_ROUNDED,
        GCMI_MIN_Y,
        GCMI_MIN_Y_ROUNDED,
        GCMI_MAX_X,
        GCMI_MAX_X_ROUNDED,
        GCMI_MAX_Y,
        GCMI_MAX_Y_ROUNDED,
    } GCM_info;

----------
#### GCNDriveChangeNotificationType
    typedef enum {
        GCNDCNT_CREATED,
        GCNDCNT_DESTROYED
    } GCNDriveChangeNotificationType;

----------
#### GCNExpressMenuNotificationType
    typedef enum {
        GCNEMNT_CREATED,
        GCNEMNT_DESTROYED
    } GCNExpressMenuNotificationType;

----------
#### GCNListBlockHeader
    typedef struct {
        LMemBlockHeader         GCNLBH_lmemHeader;
        ChunkHandle             GCNLBH_listOfLists;
    } GCNListBlockHeader;

----------
#### GCNListElement
    typedef struct {
        optr    GCNLE_item;
    } GCNListElement;

----------
#### GCNListHeader
    typedef struct {
        ChunkArrayHeader        GCNLH_meta;
        word                    GCNLH_statusEvent;
        MemHandle               GCNLH_statusData;
        word                    GCNLH_statusCount;
        /* Start of GCNListOfListElements */
    } GCNListHeader;

----------
#### GCNListOfListsElement
    typedef struct {
        GCNListType         GCNLOLE_ID;
        ChunkHandle         GCNLOLE_list;
    } GCNListOfListsElement;

----------
#### GCNListOfListsHeader
    typedef struct {
        ChunkArrayHeader                GCNLOL_meta;
        /* Start of GCNListOfListsElements */
    } GCNListOfListsHeader;

----------
#### GCNListParams
    typedef struct {
        GCNListType     GCNLP_ID;
        optr            GCNLP_optr;
    } GCNListParams;

----------
#### GCNListSendFlags
    typedef WordFlags GCNListSendFlags;
        #define GCNLSF_SET_STATUS                       0x8000
        #define GCNLSF_IGNORE_IF_STATUS_TRANSITIONING   0x4000

----------
#### GCNListType
    typedef struct {
        word    GCNLT_manuf;
        word    GCNLT_type;
    } GCNListType;

----------
#### GCNListTypeFlags
    typedef WordFlags GCNListTypeFlags;
        #define GCNLTF_SAVE_TO_STATE            0x8000

----------
#### GCNShutdownControlType
    typedef enum {
        GCNSCT_SUSPEND,
        GCNSCT_SHUTDOWN,
        GCNSCT_UNSUSPEND
    } GCNShutdownControlType;

----------
#### GCNStandardListType
    typedef enum {
        GCNSLT_FILE_SYSTEM,
        GCNSLT_APPLICATION,
        GCNSLT_DATE_TIME,
        GCNSLT_DICTIONARY,
        GCNSLT_EXPRESS_MENU,
        GCNSLT_SHUTDOWN_CONTROL
    } GCNStandardListType;

----------
#### GenAppGCNListTypes
    typedef enum /* word */ {
        GAGCNLT_GEN_CONTROL_OBJECTS,
        GAGCNLT_GEN_CONTROL_NOTIFY_STATUS_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_STYLE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_STYLE_SHEET_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_TYPE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_SELECTION_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_COUNT_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_STYLE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_FONT_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_POINT_SIZE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_FONT_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_JUSTIFICATION_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_FG_COLOR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_BG_COLOR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_CHART_TYPE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_CHART_GROUP_FLAGS,
        GAGCNLT_APP_TARGET_NOTIFY_CHART_AXIS_ATTRIBUTES,
        GAGCNLT_APP_TARGET_NOTIFY_CHART_MARKER_SHAPE,
        GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_EXPRESSION_BUILDER_STATUS_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_FIELD_PROPERTIES_STATUS_CHANGE,
        GAGCNLT_APP_NOTIFY_DOC_SIZE_CHANGE,
        GAGCNLT_APP_NOTIFY_PAPER_SIZE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_VIEW_STATE_CHANGE,
        GAGCNLT_CONTROLLED_GEN_VIEW_OBJECTS
    } GenAppGCNListTypes;

----------
#### GeneralEvent
    typedef enum {
        GE_NO_EVENT=0,                  /* dummy event (NOP) */
        GE_END_OF_SONG=2,               /* marks end of song */
        GE_SET_PRIORITY=4,              /* changes sound priority */
        GE_SET_TEMPO=6,                 /* changes sound tempo */
        GE_SEND_NOTIFICATION=8,         /* sends encoded message */
        GE_V_SEMAPHORE=10               /* V's a specified semaphore*/
    } GeneralEvent;

These represent some of the miscellaneous events which can make up a 
music buffer.

----------
#### GenTravelOption
The **GenClass** defines some values meant to be used in the place of a 
**TravelOption** enumerated value. See **TravelOption**.

----------
#### GeodeAttrs
    typedef WordFlags GeodeAttrs;
        #define GA_PROCESS                          0x8000
        #define GA_LIBRARY                          0x4000
        #define GA_DRIVER                           0x2000
        #define GA_KEEP_FILE_OPEN                   0x1000
        #define GA_SYSTEM                           0x0800
        #define GA_MULTI_LAUNCHABLE                 0x0400
        #define GA_APPLICATION                      0x0200
        #define GA_DRIVER_INITIALIZED               0x0100
        #define GA_LIBRARY_INITIALIZED              0x0080
        #define GA_GEODE_INITIALIZED                0x0040
        #define GA_USES_COPROC                      0x0020
        #define GA_REQUIRES_COPROC                  0x0010
        #define GA_HAS_GENERAL_CONSUMER_MODE        0x0008
        #define GA_ENTRY_POINTS_IN_C                0x0004

----------
#### GeodeDefaultDriverType
    typedef enum {
        GDDT_FILE_SYSTEM = 0,           /* File system driver */
        GDDT_KEYBOARD = 2,              /* Keyboard driver */
        GDDT_MOUSE = 4,                 /* Mouse driver */
        GDDT_VIDEO = 6,                 /* Video driver */
        GDDT_MEMORY_VIDEO = 8,          /* Vidmem driver */
        GDDT_POWER_MANAGEMENT = 10      /* Power management driver */
        GDDT_TASK = 12                  /* Task driver */
    } GeodeDefaultDriverType;

The default driver type has one value for each default driver type in GEOS. 
This type is used with **GeodeGetDefaultDriver()** and 
**GeodeSetDefaultDriver()**.

----------
#### GeodeGetInfoType
    typedef enum /* word */ {
        GGIT_ATTRIBUTES=0,
        GGIT_TYPE=2,
        GGIT_GEODE_RELEASE=4,
        GGIT_GEODE_PROTOCOL=6,
        GGIT_TOKEN_ID=8,
        GGIT_PERM_NAME_AND_EXT=10,
        GGIT_PERM_NAME_ONLY=12,
    } GeodeGetInfoType;

----------
#### GeodeHandle
    typedef Handle GeodeHandle;

A standard handle that contains information about a loaded geode. When a 
geode has been loaded, it is referred to by its handle.

----------
#### GeodeHeapVars
    typedef struct {
        word        GHV_heapSpace;
    } GeodeHeapVars;

----------
#### GeodeLoadError
    typedef enum {
        GLE_PROTOCOL_IMPORTER_TOO_RECENT,
        GLE_PROTOCOL_IMPORTER_TOO_OLD,
        GLE_FILE_NOT_FOUND,
        GLE_LIBRARY_NOT_FOUND,
        GLE_FILE_READ_ERROR,
        GLE_NOT_GEOS_FILE,
        GLE_NOT_GEOS_EXECUTABLE_FILE,
        GLE_ATTRIBUTE_MISMATCH,
        GLE_MEMORY_ALLOCATION_ERROR,
        GLE_NOT_MULTI_LAUNCHABLE,
        GLE_LIBRARY_PROTOCOL_ERROR,
        GLE_LIBRARY_LOAD_ERROR,
        GLE_DRIVER_INIT_ERROR,
        GLE_LIBRARY_INIT_ERROR,
        GLE_DISK_TOO_FULL,
        GLE_FIELD_DETACHING,
    } GeodeLoadError;

These errors may be returned by routines that load geodes, including 
**UserLoadApplication()**, **GeodeUseLibrary()**, **GeodeUseDriver()**, and 
**GeodeLoad()**.

----------
#### GeodeToken
    typedef struct {
        TokenChars              GT_chars;
        ManufacturerID          GT_manufID;
    } GeodeToken;

Defines a token identifier. The *GT_chars* field is four characters that identify 
the token; *GT_manufID* is the identifying number of the manufacturer of the 
item being referenced.

----------
#### GeosFileHeaderFlags
    typedef WordFlags GeosFileHeaderFlags;
        #define GFHF_TEMPLATE                   0x8000
        #define GFHF_SHARED_MULTIPLE            0x4000
        #define GFHF_SHARED_SINGLE              0x2000

----------
#### GeosFileType
    typedef enum /* word */ {
        GFT_NOT_GEOS_FILE,
        GFT_EXECUTABLE,
        GFT_VM,
        GFT_DATA,
        GFT_DIRECTORY,
        GFT_LINK
    } GeosFileType;

GEOS files are divided into several broad categories. You can find out a file's 
category by getting its FEA_FILE_TYPE extended attribute. This attribute is 
a member of the **GeosFileType** enumerated type. This type has the 
following values:

GFT_NOT_GEOS_FILE  
The file is not a GEOS file. This constant is guaranteed to be 
equal to zero.

GFT_EXECUTABLE  
The file is executable; in other words, it is some kind of geode.

GFT_VM  
The file is a VM file.

GFT_DATA  
The file is a GEOS byte file (see below).

GFT_DIRECTORY  
The file is a GEOS directory (not yet implemented).

GFT_LINK  
The file is a symbolic link (not yet implemented).

----------
#### GeoWorksGenAppGCNListType
    typedef enum /* word */ {
        GAGCNLT_SELF_LOAD_OPTIONS = 0x6800,
        GAGCNLT_GEN_CONTROL_NOTIFY_STATUS_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE,
        GAGCNLT_EDIT_CONTROL_NOTIFY_UNDO_STATE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_TYPE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_SELECTION_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_COUNT_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_STYLE_TEXT_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_STYLE_SHEET_TEXT_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_STYLE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_FONT_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_POINT_SIZE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_FONT_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_JUSTIFICATION_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_FG_COLOR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_BG_COLOR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_PARA_COLOR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_BORDER_COLOR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SEARCH_REPLACE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_CHART_TYPE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_CHART_GROUP_FLAGS,
        GAGCNLT_APP_TARGET_NOTIFY_CHART_AXIS_ATTRIBUTES,
        GAGCNLT_APP_TARGET_NOTIFY_CHART_MARKER_SHAPE,
        GAGCNLT_APP_TARGET_NOTIFY_GROBJ_CURRENT_TOOL_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_GROBJ_LINE_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_GROBJ_TEXT_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_STYLE_GROBJ_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_STYLE_SHEET_GROBJ_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_INSTRUCTION_FLAGS_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_GROBJ_GRADIENT_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_RULER_TYPE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_RULER_GRID_CHANGE,
        GAGCNLT_TEXT_RULER_OBJECTS,
        GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_TOOL_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_FORMAT_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_FIELD_PROPERTIES_STATUS_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_FIELD_LIST_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_RCP_STATUS_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_FIELD_APPEARANCE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_DUMMY_CHANGE_2,
        GAGCNLT_APP_TARGET_NOTIFY_FLAT_FILE_DUMMY_CHANGE_3,
        GAGCNLT_APP_NOTIFY_DOC_SIZE_CHANGE,
        GAGCNLT_APP_NOTIFY_PAPER_SIZE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_VIEW_STATE_CHANGE,
        GAGCNLT_CONTROLLED_GEN_VIEW_OBJECTS,
        GAGCNLT_APP_TARGET_NOTIFY_INK_STATE_CHANGE,
        GAGCNLT_CONTROLLED_INK_OBJECTS,
        GAGCNLT_APP_TARGET_NOTIFY_PAGE_STATE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_DOCUMENT_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_LIST_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SPLINE_MARKER_SHAPE,
        GAGCNLT_APP_TARGET_NOTIFY_SPLINE_POINT,
        GAGCNLT_APP_TARGET_NOTIFY_SPLINE_POLYLINE,
        GAGCNLT_APP_TARGET_NOTIFY_SPLINE_SMOOTHNESS,
        GAGCNLT_APP_TARGET_NOTIFY_SPLINE_OPEN_CLOSE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_ACTIVE_CELL_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_EDIT_BAR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_SELECTION_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_DOC_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_ATTR_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_NOTES_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_DATA_RANGE_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_TEXT_NAME_CHANGE,
        GAGCNLT_FLOAT_FORMAT_CHANGE,
        GAGCNLT_DISPLAY_OBJECTS_WITH_RULERS,
        GAGCNLT_APP_TARGET_NOTIFY_APP_CHANGE,
        GAGCNLT_APP_TARGET_NOTIFY_LIBRARY_CHANGE,
        GAGCNLT_WINDOWS,
        GAGCNLT_STARTUP_LOAD_OPTIONS
    } GeoWorksGenAppGCNListType;

----------
#### GeoWorksMetaGCNListType
    typedef enum /* word */ {
        MGCNLT_ACTIVE_LIST = 0x00,
        MGCNLT_APP_STARTUP = 0x02
    } GeoWorksMetaGCNListType;

----------
#### GeoWorksNotificationType
    typedef enum {
        GWNT_INK,
        GWNT_GEN_CONTROL_NOTIFY_STATUS_CHANGE,
        GWNT_SELECT_STATE_CHANGE,
        GWNT_UNDO_STATE_CHANGE,
        GWNT_STYLE_CHANGE,
        GWNT_STYLE_SHEET_CHANGE,
        GWNT_TEXT_CHAR_ATTR_CHANGE,
        GWNT_TEXT_PARA_ATTR_CHANGE,
        GWNT_TEXT_TYPE_CHANGE,
        GWNT_TEXT_SELECTION_CHANGE,
        GWNT_TEXT_COUNT_CHANGE,
        GWNT_TEXT_STYLE_CHANGE,
        GWNT_FONT_CHANGE,
        GWNT_POINT_SIZE_CHANGE,
        GWNT_FONT_ATTR_CHANGE,
        GWNT_JUSTIFICATION_CHANGE,
        GWNT_TEXT_FG_COLOR_CHANGE,
        GWNT_TEXT_BG_COLOR_CHANGE,
        GWNT_TEXT_PARA_COLOR_CHANGE,
        GWNT_TEXT_BORDER_COLOR_CHANGE,
        GWNT_SEARCH_REPLACE_ENABLE_CHANGE,
        GWNT_SPELL_ENABLE_CHANGE,
        GWNT_CHART_TYPE_CHANGE,
        GWNT_CHART_GROUP_FLAGS,
        GWNT_CHART_AXIS_ATTRIBUTES,
        GWNT_GROBJ_CURRENT_TOOL_CHANGE,
        GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE,
        GWNT_GROBJ_AREA_ATTR_CHANGE,
        GWNT_GROBJ_LINE_ATTR_CHANGE,
        GWNT_GROBJ_TEXT_ATTR_CHANGE,
        GWNT_GROBJ_BODY_INSTRUCTION_FLAGS_CHANGE,
        GWNT_GROBJ_GRADIENT_ATTR_CHANGE,
        GWNT_RULER_TYPE_CHANGE,
        GWNT_RULER_GRID_CHANGE,
        GWNT_RULER_GUIDE_CHANGE,
        GWNT_BITMAP_CURRENT_TOOL_CHANGE,
        GWNT_BITMAP_CURRENT_FORMAT_CHANGE,
        GWNT_FLAT_FILE_FIELD_PROPERTIES_STATUS_CHANGE,
        GWNT_FLAT_FILE_FIELD_LIST_CHANGE,
        GWNT_FLAT_FILE_RCP_STATUS_CHANGE,
        GWNT_FLAT_FIELD_APPEARANCE_CHANGE,
        GWNT_FLAT_FILE_DUMMY_CHANGE_2,
        GWNT_FLAT_FILE_DUMMY_CHANGE_3,
        GWNT_SPOOL_DOC_OR_PAPER_SIZE,
        GWNT_VIEW_STATE_CHANGE,
        GWNT_INK_HAS_TARGET,
        GWNT_PAGE_STATE_CHANGE,
        GWNT_DOCUMENT_CHANGE,
        GWNT_DISPLAY_CHANGE,
        GWNT_DISPLAY_LIST_CHANGE,
        GWNT_SPLINE_MARKER_SHAPE,
        GWNT_SPLINE_POINT,
        GWNT_SPLINE_POLYLINE,
        GWNT_SPLINE_SMOOTHNESS,
        GWNT_SPLINE_OPEN_CLOSE_CHANGE,
        GWNT_UNUSED_1,
        GWNT_SPREADSHEET_ACTIVE_CELL_CHANGE,
        GWNT_SPREADSHEET_EDIT_BAR_CHANGE,
        GWNT_SPREADSHEET_SELECTION_CHANGE,
        GWNT_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE,
        GWNT_SPREADSHEET_DOC_ATTR_CHANGE,
        GWNT_SPREADSHEET_CELL_ATTR_CHANGE,
        GWNT_SPREADSHEET_CELL_NOTES_CHANGE,
        GWNT_SPREADSHEET_DATA_RANGE_CHANGE,
        GWNT_FLOAT_FORMAT_CHANGE,
        GWNT_MAP_APP_CHANGE,
        GWNT_MAP_LIBRARY_CHANGE,
        GWNT_TEXT_NAME_CHANGE,
        GWNT_CARD_BACK_CHANGE,
        GWNT_TEXT_OBJECT_HAS_FOCUS,
        GWNT_TEXT_CONTEXT,
        GWNT_TEXT_REPLACE_WITH_HWR,
        GWNT_HELP_CONTEXT_CHANGE,
        GWNT_FLOAT_FORMAT_INIT,
        GWNT_HARD_ICON_BAR_FUNCTION,
        GWNT_STARTUP_INDEXED_APP,
        GWNT_SPOOL_PRINTING_COMPLETE,
        GWNT_MODAL_WIN_CHANGE,
        GWNT_SPREADSHEET_NAME_CHANGE,
        GWNT_DOCUMENT_OPEN_COMPLETE,
        GWNT_EMAIL_SCAN_INBOX,
        GWNT_FOCUS_WINDOW_KBD_STATUS,
        GWNT_TAB_DOUBLE_CLICK, 
        GWNT_PAGE_INFO_STATE_CHANGE,
        GWNT_CURSOR_POSITION_CHANGE,
        GWNT_FAX_NEW_JOB_CREATED,
        GWNT_FAX_NEW_JOB_COMPLETED,
        GWNT_EMAIL_DATABASE_CHANGE,
        GWNT_EMAIL_STATUS_CHANGE,
        GWNT_EMAIL_PAGE_PANEL_UPDATE,
        GWNT_PCCOM_DISPLAY_CHAR,
        GWNT_PCCOM_DISPLAY_STRING,
        GWNT_PCCOM_EXIT
    } GeoWorksNotificationType;

----------
#### GeoWorksVisContentGCNListType
    typedef enum {
        VCGCNLT_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE = 0x4a00,
        PADDING_VCGCNLT_INVALID_ITEM_000
    } GeoWorksVisContentGCNListType;

----------
#### GetMaskType
    typedef ByteEnum GetMaskType;
        #define GMT_ENUM                0
        #define GMT_BUFFER              1

----------
#### GetPalType
    typedef ByteEnum GetPalType;
        #define GPT_ACTIVE              0
        #define GPT_CUSTOM              1
        #define GPT_DEFAULT             2

----------
#### GFM_info
    typedef enum /* word */ {
         GFMI_HEIGHT=0, /* 0 */
         GFMI_HEIGHT_ROUNDED=1,
         GFMI_MEAN=2,
         GFMI_MEAN_ROUNDED=3,
         GFMI_DESCENT=4,
         GFMI_DESCENT_ROUNDED=5,
         GFMI_BASELINE=6,
         GFMI_BASELINE_ROUNDED=7,
         GFMI_LEADING=8,
         GFMI_LEADING_ROUNDED=9,
         GFMI_AVERAGE_WIDTH=10, /* 10 */
         GFMI_AVERAGE_WIDTH_ROUNDED=11,
         GFMI_ASCENT=12,
         GFMI_ASCENT_ROUNDED=13,
         GFMI_MAX_WIDTH=14,
         GFMI_MAX_WIDTH_ROUNDED=15,
         GFMI_MAX_ADJUSTED_HEIGHT=16,
         GFMI_MAX_ADJUSTED_HEIGHT_ROUNDED=17,
         GFMI_UNDER_POS=18,
         GFMI_UNDER_POS_ROUNDED=19,
         GFMI_UNDER_THICKNESS=20, /* 20 */
         GFMI_UNDER_THICKNESS_ROUNDED=21,
         GFMI_ABOVE_BOX=22,
         GFMI_ABOVE_BOX_ROUNDED=23,
         GFMI_ACCENT=24,
         GFMI_ACCENT_ROUNDED=25,
         GFMI_MANUFACTURER=26, /* 26 */
         GFMI_KERN_COUNT=28, /* 28 */
         GFMI_FIRST_CHAR=30, /* 30 */
         GFMI_LAST_CHAR=32, /* 32 */
         GFMI_DEFAULT_CHAR=34, /* 34 */
         GFMI_STRIKE_POS=36, /* 36 */
         GFMI_STRIKE_POS_ROUNDED=37,
         GFMI_BELOW_BOX=38,
         GFMI_BELOW_BOX_ROUNDED=39,
    } GFM_info;

----------
#### GraphicPattern
    typedef struct { 
        PatternType     HP_type;
        byte            HP_data;
    } GraphicPattern;

----------
#### GSControl
    typedef WordFlags GSControl;
        #define GSC_PARTIAL             0x0200
        #define GSC_ONE                 0x0100
        #define GSC_MISC                0x0080
        #define GSC_LABEL               0x0040
        #define GSC_ESCAPE              0x0020
        #define GSC_NEW_PAGE            0x0010
        #define GSC_XFORM               0x0008
        #define GSC_OUTPUT              0x0004
        #define GSC_ATTR                0x0002
        #define GSC_PATH                0x0001

----------
#### GSRetType
    typedef ByteEnum GSRetType;
        #define GSRT_COMPLETE               0
        #define GSRT_FORM_FEED              1
        #define GSRT_ONE                    2
        #define GSRT_ESCAPE                 3
        #define GSRT_OUTPUT                 4
        #define GSRT_ELEMENT                5
        #define GSRT_FAULT                  0xff

----------
#### GState
GStates are always referenced by means of GStateHandles, and are 
documented there.

----------
#### GStateHandle
    typedef Handle GStateHandle;

GStates, or graphics states, are used to interpret graphics commands. Any 
graphics command that draws anything takes a GStateHandle as an 
argument. Each GState is associated with a window, and the graphics system 
uses the GState to determine which window the command should affect.

The GState also holds considerable information determining how drawing 
commands will be carried out. For instance, it holds the line color. To draw a 
green line, first one routine set's the GState's line color to green. From then 
on (or until the line color is changed again), all lines drawn using that GState 
will be green. Thus, all commands that set color, pattern, or other drawing 
attributes take a GStateHandle argument.

GStateHandles are also used when creating bitmaps and graphics strings. In 
this case, the associated window is fake; all drawing commands passed a 
GStateHandle representing a bitmap or graphics string will affect the data 
structure instead of being drawn to screen.

----------
#### GString
    typedef void GString;

A GString (short for "Graphics Strings") represents a string of graphics 
commands. Each GString is made up of one or more GString elements, each 
of which corresponds to some standard graphics command.

GStrings may be created by means of drawing to a GStateHandle returned 
by **GrCreateState()**, but quite often GStrings are declared explicitly. The 
GString's data is often set up using macros like GSDrawLine(). These macros 
will output an opcode (of type **GStringElement**) and format their macro 
arguments into data expected with the opcode.

For instance,

    GSDrawLine(72, 144, 216, 288);

Would expand to the data:

    (GStringElement)    GR_DRAW_LINE
    (sword)             72, 144, 216, 288

Thus, these macros just represent data, though they look like normal kernel 
graphics commands.

----------
#### GStringElement
    typedef ByteEnum GStringElement;
        /* The following elements are defined :
                (Miscellaneous GString opcodes:)
        GR_END_STRING,
        GR_COMMENT,             (data: variable (word (length of code), code))
        GR_NULL_OP,
        GR_SET_GSTRING_BOUNDS,      (data: 8 bytes  (4 swords))
        GR_LABEL,                   (data: 2 bytes  (word))
        GR_ESCAPE,                  (data: variable (word (size of code), code))
        GR_NEW_PAGE,
                (Coordinate Transform opcodes:)
        GR_APPLY_ROTATION,          (data: 4 bytes  (WWFixed))
        GR_APPLY_SCALE,             (data: 8 bytes  (2 WWFixed))
        GR_APPLY_TRANSLATION,       (data: 8 bytes  (2 WWFixed))
        GR_APPLY_TRANSFORM,         (data: 26 bytes (4 WWFixed, 2 DWFixed))
        GR_APPLY_TRANSLATION_DWORD, (data: 8 bytes  (2 sdwords))
        GR_SET_TRANSFORM,           (data: 26 bytes (4 WWFixed, 2 DWFixed))
        GR_SET_NULL_TRANSFORM,
        GR_SET_DEFAULT_TRANSFORM,
        GR_INIT_DEFAULT_TRANSFORM,
        GR_SAVE_TRANSFORM,
        GR_RESTORE_TRANSFORM,
                (Output opcodes:)
        GR_DRAW_LINE,               (data: 8 bytes  (4 swords))
        GR_DRAW_LINE_TO,            (data: 4 bytes  (2 swords))
        GR_DRAW_REL_LINE_TO         (data: 8 bytes  (2 WWFixed))
        GR_DRAW_HLINE,              (data: 6 bytes  (3 swords))
        GR_DRAW_HLINE_TO,           (data: 2 bytes  (sword))
        GR_DRAW_VLINE,              (data: 6 bytes  (3 swords))
        GR_DRAW_VLINE_TO,           (data: 2 bytes  (sword))
        GR_DRAW_POLYLINE,           (data: variable (word (# of points), points)
        GR_DRAW_ARC,                (data: 14 bytes (ArcCloseType, 6 swords))
        GR_DRAW_ARC_3POINT,         (data: 14 bytes (ArcCloseType, 6 swords))
        GR_DRAW_ARC_3POINT_TO,      (data: 10 bytes (ArcCloseType, 4 swords))
        GR_DRAW_REL_ARC_3POINT_TO,  (data: 18 bytes (ArcCloseType, 4 WWFixed))
        GR_DRAW_RECT,               (data: 8 bytes  (4 swords))
        GR_DRAW_RECT_TO,            (data: 4 bytes  (2 swords))
        GR_DRAW_ROUND_RECT,         (data: 10 bytes (word, 4 swords))
        GR_DRAW_ROUND_RECT_TO,      (data: 6 bytes  (word, 2 swords))
        GR_DRAW_SPLINE,             (data: variable (word (# of points), points))
        GR_DRAW_SPLINE_TO,          (data: variable (word (# of points), points))
        GR_DRAW_CURVE,              (data: 16 bytes (8 swords))
        GR_DRAW_CURVE_TO,           (data: 12 bytes (6 swords))
        GR_DRAW_REL_CURVE_TO,       (data: 24 bytes (6 WWFixed))
        GR_DRAW_ELLIPSE,            (data: 8 bytes  (4 swords))
        GR_DRAW_POLYGON,            (data: variable (word (# of points), points))
        GR_DRAW_POINT,              (data: 4 bytes  (2 words))
        GR_DRAW_POINT_CP,
        GR_BRUSH_POLYLINE,          (data: variable (word (# of points), 2 bytes,
                                            points))
        GR_DRAW_CHAR,               (data: 5 bytes)     (Chars, 2 swords))
        GR_DRAW_CHAR_CP,            (data: 1 byte)  (Chars))
        GR_DRAW_TEXT,               (data: variable (sword, sword, 
                                     word (length of string), 
                                            string (not null terminated)))
        GR_DRAW_TEXT_CP,            (data: variable (word (length of string),
                                            string (not null terminated)))
        GR_DRAW_TEXT_PTR,           (data: 6 bytes  (2 swords, (char *)))
        GR_DRAW_TEXT_OPTR,          (data: 6 bytes  (2 swords, optr))
        GR_DRAW_PATH,
        GR_FILL_RECT,               (data: 8 bytes  (4 swords))
        GR_FILL_RECT_TO,            (data: 4 bytes  (2 swords))
        GR_FILL_ROUND_RECT,         (data: 10 bytes (4 swords, word))
        GR_FILL_ROUND_RECT_TO,      (data: 6 bytes  (2 swords, word))
        GR_FILL_ARC,                (data: 14 bytes (ArcCloseType, 6 swords))
        GR_FILL_POLYGON,            (data: variable (word (# of points),
                                            RegionFillRule, points))
        GR_FILL_ELLIPSE,            (data: 8 bytes  (2 swords))
        GR_FILL_PATH,               data: 1 byte     (RegionFillRule))
        GR_FILL_ARC_3POINT,         (data: 14 bytes (ArcCloseType, 6 swords))
        GR_FILL_ARC_3POINT_TO       (data: 10 bytes (ArcCloseType, 4 swords))
        GR_FILL_BITMAP,             (data: 6 bytes  (2 swords, word))
        GR_FILL_BITMAP_CP,          (data: 2 bytes  (word))
        GR_FILL_BITMAP_OPTR,
        GR_DRAW_BITMAP,             (data: 6 bytes  (2 swords, word))
        GR_DRAW_BITMAP_CP,          (data: 2 bytes  (word))
        GR_DRAW_BITMAP_OPTR,        (data: 6 bytes  (2 swords, optr))
        GR_DRAW_BITMAP_PTR,         (data: 6 bytes  (2 swords, *))
        GSE_BITMAP_SLICE,           (data: variable)
                (Drawing Attribute opcodes:)
        GR_SAVE_STATE,
        GR_RESTORE_STATE,
        GR_SET_MIX_MODE,            (data: 1 byte    (MixMode))
        GR_MOVE_TO,                 (data: 4 bytes  (2 swords))
        GR_REL_MOVE_TO,             (data: 8 bytes  (2 WWFixed))
        GR_CREATE_PALETTE,
        GR_DESTROY_PALETTE,
        GR_SET_PALETTE_ENTRY,       (data: 4 bytes  (Color, 3 bytes))
        GR_SET_PALETTE,             (data: variable (word (# of entries), 
                                            entries (3 bytes each)))
        GR_SET_LINE_COLOR,          (data: 3 bytes  (3 bytes))
        GR_SET_LINE_MASK,           (data: 1 byte    (SysDrawMask))
        GR_SET_LINE_COLOR_MAP,      (data: 1 byte    (ColorMapMode))
        GR_SET_LINE_WIDTH,          (data: 4 bytes  (WWFixed))
        GR_SET_LINE_JOIN,           (data: 1 byte    (LineJoin))
        GR_SET_LINE_END,            (data: 1 byte    (LineEnd))
        GR_SET_LINE_ATTR,           (data: 9 bytes  (CF_RGB, 3 bytes, SysDrawMask,
                                        ColorMapMode, LineEnd, LineJoin, LineStyle)
        GR_SET_MITER_LIMIT,         (data: 4 bytes  (WWFixed))
        GR_SET_LINE_STYLE,          (data: 2 bytes  (LineStyle, index))
        GR_SET_LINE_COLOR_INDEX,    (data: 1 byte    (Color))
        GR_SET_CUSTOM_LINE_MASK,    (data: 8 bytes  (8 bytes))
        GR_SET_CUSTOM_LINE_STYLE,   (data: variable (word (index),
                                            word (# of on-off dash pairs),
                                            pairs (each pair is 2 bytes)))
        GR_SET_AREA_COLOR,          (data: 3 bytes  (3 bytes)
        GR_SET_AREA_MASK,           (data: 1 byte    (SysDrawMask))
        GR_SET_AREA_COLOR_MAP,      (data: 1 byte    (ColorMapMode))
        GR_SET_AREA_ATTR,           (data: 6 bytes  (CF_RGB, 3 bytes, SysDrawMask, 
                                            ColorMapMode))
        GR_SET_AREA_COLOR_INDEX,    (data: 1 byte    (Color))
        GR_SET_CUSTOM_AREA_MASK,    (data: 8 bytes  (8 bytes))
        GR_SET_AREA_PATTERN,        (data: 2 bytes  (GraphicPattern))
        GR_SET_CUSTOM_AREA_PATTERN, (data: variable (GraphicPattern, 
                                            word (size of data)
                                            pattern data))
        GR_SET_TEXT_COLOR,          (data: 3 bytes  (3 bytes))
        GR_SET_TEXT_MASK,           (data: 1 byte    (SysDrawMask))
        GR_SET_TEXT_COLOR_MAP,      (data: 1 byte    (ColorMapMode))
        GR_SET_TEXT_STYLE,          (data: 2 bytes  (2 TextStyles))
        GR_SET_TEXT_MODE,           (data: 2 bytes  (2 TextModes))
        GR_SET_TEXT_SPACE_PAD,      (data: 3 bytes  (WBFixed))
        GR_SET_TEXT_ATTR,           (data: 20 bytes (CF_RGB, 3 bytes, SysDrawMask,
                                            ColorMapMode, 2 TextStyles, 
                                            2 TextModes, WBFixed, FontID, word))
        GR_SET_FONT,                (data: 5 bytes  (WBFixed, FontID))
        GR_SET_TEXT_COLOR_INDEX,    (data: 1 byte    (Color))
        GR_SET_CUSTOM_TEXT_MASK,    (data: 8 bytes  ()
        GR_SET_TRACK_KERN,          (data: 2 bytes  (sword))
        GR_SET_FONT_WEIGHT,         (data: 2 bytes  (FontWeight))
        GR_SET_FONT_WIDTH,          (data: 2 bytes  (FontWidth))
        GR_SET_SUPERSCRIPT_ATTR,    (data: 2 bytes  (position, scale))
        GR_SET_SUBSCRIPT_ATTR,      (data: 2 bytes  (position, scale))
        GR_SET_TEXT_PATTERN,        (data: 2 bytes  (GraphicPattern))
        GR_SET_CUSTOM_TEXT_PATTERN, (data: variable (GraphicPattern, 
                                            word (size of data),
                                            pattern data))
                (Path opcodes:)
        GR_BEGIN_PATH,              (data: 1 byte    (PathCombineParam))
        GR_END_PATH,
        GR_SET_CLIP_RECT,           (data: 8 bytes  (4 swords))
        GR_SET_WIN_CLIP_RECT,       (data: 8 bytes  (4 swords))
        GR_CLOSE_SUB_PATH,
        GR_SET_CLIP_PATH,           (data: 1 byte    (flags))
        GR_SET_WIN_CLIP_PATH,       (data: 1 byte    (flags))
        GR_SET_STROKE_PATH                                  */

----------
#### GStringErrorType
    typedef enum /* word */ {
        GSET_NO_ERROR,
        GSET_DISK_FULL
    } GStringErrorType;

----------
#### GStringKillType
    typedef ByteEnum GStringKillType;
        #define GSKT_KILL_DATA          0
        #define GSKT_LEAVE_DATA         1

----------
#### GStringSetPosType
    typedef ByteEnum GStringSetPosType;
        #define GSSPT_SKIP_1                0
        #define GSSPT_RELATIVE              1
        #define GSSPT_BEGINNING             2
        #define GSSPT_END                   3

----------
#### GStringType
    typedef ByteEnum GStringType;
        #define GST_CHUNK               0
        #define GST_STREAM              1
        #define GST_VMEM                2
        #define GST_PTR                 3
        #define GST_PATH                4

----------
#### Handle
    typedef word Handle;

----------
#### HatchDash
    typedef struct {
        WWFixed     HD_on;
        WWFixed     HD_off;
    } HatchDash;

----------
#### HatchLine
    typedef struct {
        PointWWFixed    HL_origin;
        WWFixed         HL_deltaX;
        WWFixed         HL_deltaY;
        WWFixed         HL_angle;
        ColorQuad       HL_color;
        word            HL_numDashes;
            /* array of HatchDash structures follows here */
    } HatchLine;

----------
#### HatchPattern
    typedef struct {
        word HP_numLines;
            /* array of HatchLine structures follows here */
    } HatchPattern;

----------
#### HeapAllocFlags
    typedef ByteFlags HeapAllocFlags;
        #define HAF_ZERO_INIT               0x80
        #define HAF_LOCK                    0x40
        #define HAF_NO_ERR                  0x20
        #define HAF_UI                      0x10
        #define HAF_READ_ONLY               0x08
        #define HAF_OBJECT_RESOURCE         0x04
        #define HAF_CODE                    0x02
        #define HAF_CONFORMING              0x01
        #define HAF_STANDARD                (0)
        #define HAF_STANDARD_NO_ERR         (HAF_NO_ERR)
        #define HAF_STANDARD_LOCK           (HAF_LOCK)
        #define HAF_STANDARD_NO_ERR_LOCK    (HAF_NO_ERR | HAF_LOCK)

----------
#### HeapCongestion
    typedef enum /* word */ {
        HC_SCRUBBING,
        HC_CONGESTED,
        HC_DESPERATE
    } HeapCongestion;

----------
#### HeapFlags
    typedef ByteFlags HeapFlags;
        #define HF_FIXED                0x80
        #define HF_SHARABLE             0x40
        #define HF_DISCARDABLE          0x20
        #define HF_SWAPABLE             0x10
        #define HF_LMEM                 0x08
        #define HF_DISCARDED            0x02
        #define HF_SWAPPED              0x01
        #define HF_STATIC               (HF_DISCARDABLE | HF_SWAPABLE)
        #define HF_DYNAMIC              HF_SWAPABLE

----------
#### HugeArrayDirectory
    typedef struct {
        LMemBlockHeader         HAD_header;
        VMBlockHandle           HAD_data;
        ChunkHandle             HAD_dir;
        VMBlockHandle           HAD_xdir;
        VMBlockHandle           HAD_self;
        word                    HAD_size;
    } HugeArrayDirectory;

----------
#### IACPConnectFlags
    typedef WordFlags IACPConnectFlags;
        #define IACPCF_OBEY_LAUNCH_MODEL            0x0020
        #define IACPCF_CLIENT_OD_SPECIFIED          0x0010
        #define IACPCF_FIRST_ONLY                   0x0008
        #define IACPCF_SERVER_MODE                  0x0007
**Include:** iacp.goh

----------
#### IACPServerFlags
    typedef ByteFlags IACPServerFlags;
        #define IACPSF_MULTIPLE_INSTANCES                       0x80
**Include:** iacp.goh

----------
#### IACPServerMode
    typedef ByteEnum IACPServerMode;
        #define IACPSM_NOT_USER_INTERACTIBLE        0
        #define IACPSM_IN_FLUX                      1
        #define IACPSM_USER_INTERACTIBLE            2
**Include:** iacp.goh

----------
#### IACPSide
    typedef enum {
        IACPS_CLIENT,
        IACPS_SERVER
    } IACPSide;
**Include:** iacp.goh

----------
#### ImageFlags
    typedef ByteFlags ImageFlags;
        #define IF_IGNORE_MASK      0x10
        #define IF_BORDER           0x08
        #define IF_BITSIZE          0x07 /* Should hold an ImageBitSize */
        #define IBS_1           0
        #define IBS_2           1
        #define IBS_4           2
        #define IBS_8           3
        #define IBS_16          4

----------
#### IMCFeatures
    typedef ByteFlags IMCFeatures;
        #define IMCF_MAP                        0x01
        #define IMC_DEFAULT_FEATURES            IMCF_MAP
        #define IMC_DEFAULT_TOOLBOX_FEATURES    0
        #define IMC_MAP_MONIKER_SIZE            1024

----------
#### ImpexDataClasses
    typedef WordFlags ImpexDataClasses;
        #define IDC_TEXT                0x8000
        #define IDC_GRAPHICS            0x4000
        #define IDC_SPREADSHEET         0x2000
        #define IDC_FONT                0x1000

----------
#### ImpexFileSelectionData
    typedef struct {
        FileLongName                IFSD_selection;
        PathName                    IFSD_path;
        word                        IFSD_disk;
        GenFileSelectorEntryFlags   IFSD_type;
    } ImpexFileSelectionData;

----------
#### ImpexMapFlags
    typedef ByteFlags ImpexMapFlags;
        #define IMF_IMPORT              0x80
        #define IMF_EXPORT              0x40

----------
#### ImpexMapFileInfoHeader
    typedef struct {
        LMemBlockHeader         IMFIH_base;
        word                    IMFIH_fieldChunk;
        word                    IMFIH_numFields;
    } ImpexMapFileInfoHeader;

----------
#### ImpexTranslationParams
    typedef struct {
        optr            ITP_impexOD;
        Message         ITP_returnMsg;
        word            ITP_dataClass;
        FileHandle      ITP_transferVMFile;
        VMChain         ITP_transferVMChain;
        dword           ITP_internal;
    } ImpexTranslationParams;

----------
#### ImportControlAttrs
    typedef WordFlags ImportControlAttrs;
        #define ICA_IGNORE_INPUT 0x8000 /* ignore input while import occurs */

----------
#### ImportControlToolboxFeatures
    typedef ByteFlags ImportControlToolboxFeatures;
        #define IMPORTCTF_DIALOG_BOX                    0x01

----------
#### InitFileCharConvert
    typedef ByteEnum InitFileCharConvert;
        #define IFCC_INTACT         0   /* Leave all characters unchanged. */
        #define IFCC_UPCASE         1   /* Make all characters upper case. */
        #define IFCC_DOWNCASE       2   /* Make all characters lower case. */

This enumerated type describes how **InitFileRead...()** routines should 
handle incoming strings.

----------
#### InitFileReadFlags
    typedef WordFlags InitFileReadFlags;
        #define IFRF_CHAR_CONVERT   0xc000  /* 2 bits: InitFileCharConvert type */
        #define IFRF_READ_ALL       0x2000
        #define IFRF_FIRST_ONLY     0x1000
        #define IFRF_SIZE           0x0fff

This record is used with the **InitFileRead...()** routines. The 
IFRF_CHAR_CONVERT field is used to indicate whether strings being read 
should be upcased, downcased, or left unaltered - the type is designated by a 
value of **InitFileCharConvert**. The IFRF_SIZE field is used by routines that 
take a passed buffer; this field indicates the size of the buffer (the maximum 
number of bytes that can be returned by the routine).

When setting this record, make sure you shift the IFRF_CHAR_CONVERT 
value left an offset of IFRF_CHAR_CONVERT_OFFSET.

----------
#### InkBackgroundType
    typedef enum {
        IBT_NO_BACKGROUND = 0,
        IBT_NARROW_LINED_PAPER = 2,
        IBT_MEDIUM_LINED_PAPER = 4,
        IBT_WIDE_LINED_PAPER = 6,
        IBT_NARROW_STENO_PAPER = 8,
        IBT_MEDIUM_STENO_PAPER = 10,
        IBT_WIDE_STENO_PAPER = 12,
        IBT_SMALL_GRID = 14,
        IBT_MEDIUM_GRID = 16,
        IBT_LARGE_GRID = 18,
        IBT_SMALL_CROSS_SECTION = 20,
        IBT_MEDIUM_CROSS_SECTION = 22,
        IBT_LARGE_CROSS_SECTION = 24,
        IBT_TO_DO_LIST = 26,
        IBT_PHONE_MESSAGE = 28,
        IBT_CUSTOM_BACKGROUND = 30
    } InkBackgrountType;

This enumerated type is a set of standard background pictures for use with 
the Ink Database routines.

----------
#### InkControlFeatures
    typedef ByteFlags InkControlFeatures;
        #define ICF_PENCIL_TOOL             0x02
        #define ICF_ERASER_TOOL             0x01

----------
#### InkControlToolboxFeatures
    typedef ByteFlags InkControlToolboxFeatures;
        #define ICTF_PENCIL_TOOL                0x02
        #define ICTF_ERASER_TOOL                0x01

----------
#### InkDBDisplayInfo
    typedef struct {
        dword   IDBDI_dword1;
        dword   IDBDI_dword2;
        word    IDBDI_word1;
    } InkDBDisplayInfo;

----------
#### InkDBFrame
    typedef struct {
        Rectangle IDBF_bounds;              /* bounds of data to save or coord at
                                             * which to load data */
        VMFileHandle IDBF_VMFile;           /* VM File to write to/read from */
        DBGroupAndItem IDBF_DBGroupAndItem; /* DB item to save to/load from */
        word IDBF_DBExtra;                  /* space to skip at start of block */
    } InkDBFrame;

----------
#### InkFlags
    typedef ByteFlags InkFlags;
        #define IF_HAS_TARGET                   0x20
        #define IF_DIRTY                        0x10
        #define IF_ONLY_CHILD_OF_CONTENT        0x08
        #define IF_CONTROLLED                   0x04
        #define IF_INVALIDATE_ERASURES          0x02
        #define IF_HAS_UNDO                     0x01

----------
#### InkReturnValue
    typedef enum {
        IRV_NO_REPLY,
        /* VisComp objects use VisCallChildUnderPoint to send
         * MSG_META_QUERY_IF_PRESS_IS_INK to its children, and
         * VisCallChildUnderPoint returns this value (0) if there was not child
         * under the point. No object should actually return this value. */
        IRV_NO_INK,
        /* Return this if the object wants to treat incoming event as mouse data. */
        IRV_INK_WITH_STANDARD_OVERRIDE,
        /* Return this if the object normally wants ink (the text object does this), 
         * but the user can force mouse events instead by pressing the pen and 
         * holding for some user-adjustable amount of time. */
        IRV_WAIT
        /* Return this value if the object under the point is run by a different
         * thread and you want to hold up input (don't do anything with the incoming
         * MSG_META_START_SELECT) `til obj sends MSG_GEN_APPLICATION_INK_QUERY_REPLY
         * to the applicaiton object. */
    } InkReturnValue;

This enumerated type is used by objects to let the system know whether 
incoming pointer events should be interpreted as mouse or pen data.

----------
#### InsertChildFlags
    typedef WordFlags InsertChildFlags
        #define ICF_MARK_DIRTY          0x8000
        #define ICF_OPTIONS             0x0003

This record specifies how children are to be added to an object tree.

----------
#### InsertChildOption
    typedef ByteEnum InsertChildOption
        #define ICO_FIRST                   0
        #define ICO_LAST                    1
        #define ICO_BEFORE_REFERENCE        2
        #define ICO_AFTER_REFERENCE         3

This enumerated type determines how a child is added and is used with the 
**InsertChildFlags** record. It has four enumerations, as shown above.

----------
#### InstrumentPatch
    typedef enum { 
        #define IP_ACOUSTIC_GRAND_PIANO     0
        #define IP_BRIGHT_ACOUSTIC_PIANO    1
        #define IP_ELECTRIC_GRAND_PIANO     2
        #define IP_HONKY_TONK_PIANO         3
        #define IP_ELECTRIC_PIANO_1         4
        #define IP_ELECTRIC_PIANO_2         5
        #define IP_HARPSICORD               6
        #define IP_CLAVICORD                7
        #define IP_CELESTA                  8

        #define IP_GLOCKENSPIEL             9
        #define IP_MUSIC_BOC                10
        #define IP_VIBRAPHONE               11
        #define IP_MARIMBA                  12
        #define IP_XYLOPHONE                13
        #define IP_TUBULAR_BELLS            14
        #define IP_DULCIMER                 15

        #define IP_DRAWBAR_ORGAN            16
        #define IP_PERCUSSIVE_ORGAN         17
        #define IP_ROCK_ORGAN               18
        #define IP_CHURCH_ORGAN             19
        #define IP_REED_ORGAN               20
        #define IP_ACCORDIAN                21
        #define IP_HARMONICA                22
        #define IP_TANGO_ACCORDION          23

        #define IP_ACOUSTIC_NYLON_GUITAR    24
        #define IP_ACOUSTIC_STEEL_GUITAR    25
        #define IP_ELECTRIC_JAZZ_GUITAR     26
        #define IP_ELECTRIC_CLEAN_GUITAR    27
        #define IP_ELECTRIC_MUTED_GUITAR    28
        #define IP_OVERDRIVEN_GUITAR        29
        #define IP_DISTORTION_GUITAR        30
        #define IP_GUITAR_HARMONICS         31

        #define IP_ACOUSTIC_BASS            32
        #define IP_ELECTRIC_FINGERED_BASS   33
        #define IP_ELECTRIC_PICKED_BASS     34
        #define IP_FRETLESS_BASS            35
        #define IP_SLAP_BASS_1              36
        #define IP_SLAP_BASS_2              37
        #define IP_SYNTH_BASS_1             38
        #define IP_SYNTH_BASS_2             39

        #define IP_VIOLIN                   40
        #define IP_VIOLA                    41
        #define IP_CELLO                    42
        #define IP_CONTRABASS               43
        #define IP_TREMELO_STRINGS          44
        #define IP_PIZZICATO_STRINGS        45
        #define IP_ORCHESTRAL_HARP          46
        #define IP_TIMPANI                  47
        
        #define IP_STRING_ENSAMBLE_1        48
        #define IP_STRING_ENSAMBLE_2        49
        #define IP_SYNTH_STRINGS_1          50
        #define IP_SYNTH_STRINGS_2          51
        #define IP_CHIOR_AAHS               52
        #define IP_VOICE_OOHS               53
        #define IP_SYNTH_VOICE              54
        #define IP_ORCHESTRA_HIT            55

        #define IP_TRUMPET                  56
        #define IP_TROMBONE                 57
        #define IP_TUBA                     58
        #define IP_MUTED_TRUMPET            59
        #define IP_FRENCH_HORN              60
        #define IP_BRASS_SECTION            61
        #define IP_SYNTH_BRASS_1            62
        #define IP_SYNTH_BRASS_2            63

        #define IP_SOPRANO_SAX              64
        #define IP_ALTO_SAX                 65
        #define IP_TENOR_SAX                66
        #define IP_BARITONE_SAX             67
        #define IP_OBOE                     68
        #define IP_ENGLISH_HORN             69
        #define IP_BASSOON                  70
        #define IP_CLARINET                 71

        #define IP_PICCOLO                  72
        #define IP_FLUTE                    73
        #define IP_RECORDER                 74
        #define IP_PAN_FLUTE                75
        #define IP_BLOWN_BOTTLE             76
        #define IP_SHAKUHACHI               77
        #define IP_WHISTLE                  78
        #define IP_OCARINA                  79

        #define IP_LEAD_SQUARE              80
        #define IP_LEAD_SAWTOOTH            81
        #define IP_LEAD_CALLIOPE            82
        #define IP_LEAD_CHIFF               83
        #define IP_LEAD_CHARANG             84
        #define IP_LEAD_VOICE               85
        #define IP_LEAD_FIFTHS              86
        #define IP_LEAD_BASS_LEAD           87

        #define IP_PAD_NEW_AGE              88
        #define IP_PAD_WARM                 89
        #define IP_PAD_POLYSYNTH            90
        #define IP_PAD_CHOIR                91
        #define IP_PAD_BOWED                92
        #define IP_PAD_METALLIC             93
        #define IP_PAD_HALO                 94
        #define IP_PAD_SWEEP                95

        #define IP_FX_RAIN                  96
        #define IP_FX_SOUNDTRACK            97
        #define IP_FX_CRYSTAL               98
        #define IP_FX_ATMOSPHERE            99
        #define IP_FX_BRIGHTNESS            100
        #define IP_FX_GOBLINS               101
        #define IP_FX_ECHOES                102
        #define IP_FX_SCI_FI                103

        #define IP_SITAR                    104
        #define IP_BANJO                    105
        #define IP_SHAMISEN                 106
        #define IP_KOTO                     107
        #define IP_KALIMBA                  108
        #define IP_BAG_PIPE                 109
        #define IP_FIDDLE                   110
        #define IP_SHANAI                   111

        #define IP_TINKLE_BELL              112
        #define IP_AGOGO                    113
        #define IP_STEEL_DRUMS              114
        #define IP_WOODBLOCK                115
        #define IP_TAIKO_DRUM               116
        #define IP_MELODIC_TOM              117
        #define IP_SYNTH_DRUM               118
        #define IP_REVERSE_CYMBAL           119

        #define IP_GUITAR_FRET_NOISE        120
        #define IP_BREATH_NOISE             121
        #define IP_SEASHORE                 122
        #define IP_BIRD_TWEET               123
        #define IP_TELEPHONE_RING           124
        #define IP_HELICOPTER               125
        #define IP_APPLAUSE                 126
        #define IP_GUNSHOT                  127

        #define IP_ACOUSTIC_BASS_DRUM       128
        #define IP_BASS_DRUM_1              129
        #define IP_SIDE_STICK               130
        #define IP_ACOUSTIC_SNARE           131
        #define IP_HAND_CLAP                132
        #define IP_ELECTRIC_SNARE           133
        #define IP_LOW_FLOOR_TOM            134
        #define IP_CLOSED_HI_HAT            135

        #define IP_HIGH_FLOOR_TOM           136
        #define IP_PEDAL_HI_HAT             137
        #define IP_LOW_TOM                  138
        #define IP_OPEN_HI_HAT              139
        #define IP_LOW_MID_TOM              140
        #define IP_HI_MID_TOM               141
        #define IP_CRASH_CYMBAL_1           142
        #define IP_HIGH_TOM                 143

        #define IP_RIDE_CYMBAL_1            144
        #define IP_CHINESE_CYMBAL           145
        #define IP_RIDE_BELL                146
        #define IP_TAMBOURINE               147
        #define IP_SPLASH_CYMBAL            148
        #define IP_COWBELL                  149
        #define IP_CRASH_CYMBAL_2           150
        #define IP_VIBRASLAP                151

        #define IP_RIDE_CYMBAL_2            152
        #define IP_HI_BONGO                 153
        #define IP_LOW_BONGO                154
        #define IP_MUTE_HI_CONGA            155
        #define IP_OPEN_HI_CONGA            156
        #define IP_LOW_CONGA                157
        #define IP_HI_TIMBALE               158
        #define IP_LOW_TIMBALE              159

        #define IP_HIGH_AGOGO               160
        #define IP_LOW_AGOGO                161
        #define IP_CABASA                   162
        #define IP_MARACAS                  163
        #define IP_SHORT_WHISTLE            164
        #define IP_LONG_WHISTLE             165
        #define IP_SHORT_GUIRO              166
        #define IP_LONG_GUIRO               167

        #define IP_CLAVES                   168
        #define IP_HI_WOOD_BLOCK            169
        #define IP_LOW_WOOD_BLOCK           170
        #define IP_MUTE_CUICA               171
        #define IP_OPEN_CUICA               172
        #define IP_MUTE_TRIANGLE            173
        #define IP_OPEN_TRIANGLE            174
    } InstrumentPatch;

These are standard simulated instruments. 

----------
#### InstrumentTable
    typedef enum {
        IT_STANDARD_TABLE=0             /* default table */
    } InstrumentTable;

The sound library uses this enumerated type to keep track of which table of 
simulated musical instruments to use.

----------
#### JobStatus
    typedef struct {
        char            JS_fname[13];       /* std DOS (8.3) spool filename */
        char            JS_parent[FILE_LONGNAME_LENGTH+1];
                                            /* parent app's name */
        char            JS_documentName[FILE_LONGNAME_LENGTH+1];
                                            /* document name */
        word            JS_numPages;        /* # pages in document */
        SpoolTimeStruct JS_time;            /* time spooled */
        byte            JS_printing;        /* TRUE/FALSE if we are printing */
    } JobStatus;

----------
#### Justification
    typedef ByteEnum Justification;
        #define J_LEFT          0
        #define J_RIGHT         1
        #define J_CENTER        2
        #define J_FULL          3

----------
#### KeyboardShortcut
    typedef WordFlags KeyboardShortcut;
        #define KS_PHYSICAL             0x8000
        #define KS_ALT                  0x4000
        #define KS_CTRL                 0x2000
        #define KS_SHIFT                0x1000
        #define KS_CHAR_SET             0x0f00
        #define KS_CHAR                 0x00ff
        #define KS_CHAR_SET_OFFSET      8
        #define KS_CHAR_OFFSET          0

----------
#### KeyboardType
    typedef ByteEnum KeyboardType;
        #define KT_NOT_EXTD         1
        #define KT_EXTD             2
        #define KT_BOTH             3

----------
#### KeyMapType
        typedef enum /* word */ {
        KEYMAP_US_EXTD=1,
        KEYMAP_US,
        KEYMAP_UK_EXTD,
        KEYMAP_UK,
        KEYMAP_GERMANY_EXTD,
        KEYMAP_GERMANY,
        KEYMAP_SPAIN_EXTD,
        KEYMAP_SPAIN,
        KEYMAP_DENMARK_EXTD,
        KEYMAP_DENMARK,
        KEYMAP_BELGIUM_EXTD,
        KEYMAP_BELGIUM,
        KEYMAP_CANADA_EXTD,
        KEYMAP_CANADA,
        KEYMAP_ITALY_EXTD,
        KEYMAP_ITALY,
        KEYMAP_LATIN_AMERICA_EXTD,
        KEYMAP_LATIN_AMERICA,
        KEYMAP_NETHERLANDS,
        KEYMAP_NETHERLANDS_EXTD,
        KEYMAP_NORWAY_EXTD,
        KEYMAP_NORWAY,
        KEYMAP_PORTUGAL_EXTD,
        KEYMAP_PORTUGAL,
        KEYMAP_SWEDEN_EXTD,
        KEYMAP_SWEDEN,
        KEYMAP_SWISS_FRENCH_EXTD,
        KEYMAP_SWISS_FRENCH,
        KEYMAP_SWISS_GERMAN_EXTD,
        KEYMAP_SWISS_GERMAN,
        KEYMAP_FRANCE_EXTD,
        KEYMAP_FRANCE,
    } KeyMapType;

[Data Structures A-E](rstra_e.md) <-- [Table of Contents](../routines.md) &nbsp;&nbsp; --> [Data Structures L-Z](rstrl_z.md)