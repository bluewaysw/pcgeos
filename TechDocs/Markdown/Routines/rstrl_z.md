## 4.3 Data Structures L-Z
----------
#### Language
    typedef ByteEnum Language;
        #define L_DEFAULT               0
        #define L_GRAPHIC               0
        #define L_ENGLISH               1
        #define L_GERMAN                2
        #define L_FRENCH                3
        #define L_SPANISH               4
        #define L_ITALIAN               5
        #define L_DANISH                6
        #define L_DUTCH                 7

----------
#### LargeMouseData
    typedef struct {
        PointDWFixed                LMD_location;
        byte                        LMD_buttonInfo;
        UIFunctionsActive           LMD_uiFunctionsActive;
    } LargeMouseData;

----------
#### LayerPriority
    typedef ByteEnum LayerPriority;
        #define LAYER_PRIO_MODAL                 6
        #define LAYER_PRIO_ON_TOP                8
        #define LAYER_PRIO_STD                  12
        #define LAYER_PRIO_ON_BOTTOM            14

----------
#### LexicalOrder
    typedef ByteEnum LexicalOrder;
        #define LEX_SPACE                   0x20
        #define LEX_NONBRKSPACE             1
        #define LEX_EXCLAMATION             2
        #define LEX_EXCLAMDOWN              3
        #define LEX_QUOTE                   4
        #define LEX_GUILLEDDBLLEFT          5
        #define LEX_GUILLEDDBLRIGHT         6
        #define LEX_GUILSNGLEFT             7
        #define LEX_GUILSNGRIGHT            8
        #define LEX_QUOTEDBLLEFT            9
        #define LEX_QUOTEDBLRIGHT           10
        #define LEX_DBLQUOTELOW             11
        #define LEX_NUMBER_SIGN             12
        #define LEX_DOLLAR_SIGN             13
        #define LEX_PERCENT                 14
        #define LEX_AMPERSAND               15
        #define LEX_SNG_QUOTE               16
        #define LEX_QUOTEDSNGLEFT           17
        #define LEX_QUOTEDSNGRIGHT          18
        #define LEX_SNGQUOTELOW             19
        #define LEX_LEFT_PAREN              20
        #define LEX_RIGHT_PAREN             21
        #define LEX_ASTERISK                22
        #define LEX_PLUS                    23
        #define LEX_COMMA                   24
        #define LEX_MINUS                   25
        #define LEX_PERIOD                  26
        #define LEX_SLASH                   27
        #define LEX_ZERO                    28
        #define LEX_ONE                     29
        #define LEX_TWO                     30
        #define LEX_THREE                   31
        #define LEX_FOUR                    32
        #define LEX_FIVE                    33
        #define LEX_SIX                     34
        #define LEX_SEVEN                   35
        #define LEX_EIGHT                   36
        #define LEX_NINE                    37
        #define LEX_COLON                   38
        #define LEX_SEMICOLON               39
        #define LEX_LESS_THAN               40
        #define LEX_EQUAL                   41
        #define LEX_GREATER_THAN            42
        #define LEX_QUESTION_MARK           43
        #define LEX_QUESTIONDOWN            44
        #define LEX_AT_SIGN                 45
        #define LEX_UA                      46
        #define LEX_UA_ACUTE                47
        #define LEX_UA_GRAVE                48
        #define LEX_UA_CIRCUMFLEX           49
        #define LEX_UA_DIERESIS             50
        #define LEX_U_AE                    51
        #define LEX_UA_TILDE                52
        #define LEX_UA_RING                 53
        #define LEX_LA                      54
        #define LEX_LA_ACUTE                55
        #define LEX_LA_GRAVE                56
        #define LEX_LA_CIRCUMFLEX           57
        #define LEX_LA_DIERESIS             58
        #define LEX_L_AE                    59
        #define LEX_LA_TILDE                60
        #define LEX_LA_RING                 61
        #define LEX_UB                      62
        #define LEX_LB                      63
        #define LEX_UC                      64
        #define LEX_UC_CEDILLA              65
        #define LEX_LC                      66
        #define LEX_LC_CEDILLA              67
        #define LEX_UD                      68
        #define LEX_LD                      69
        #define LEX_UE                      70
        #define LEX_UE_ACUTE                71
        #define LEX_UE_GRAVE                72
        #define LEX_UE_CIRCUMFLEX           73
        #define LEX_UE_DIERESIS             74
        #define LEX_LE                      75
        #define LEX_LE_ACUTE                76
        #define LEX_LE_GRAVE                77
        #define LEX_LE_CIRCUMFLEX           78
        #define LEX_LE_DIERESIS             79
        #define LEX_UF                      80
        #define LEX_LF                      81
        #define LEX_UG                      82
        #define LEX_LG                      83
        #define LEX_UH                      84
        #define LEX_LH                      85
        #define LEX_UI                      86
        #define LEX_UI_ACUTE                87
        #define LEX_UI_GRAVE                88
        #define LEX_UI_CIRCUMFLEX           89
        #define LEX_UI_DIERESIS             90
        #define LEX_LI                      91
        #define LEX_LI_ACUTE                92
        #define LEX_LI_GRAVE                93
        #define LEX_LI_CIRCUMFLEX           94
        #define LEX_LI_DIERESIS             95
        #define LEX_LI_DOTLESS              96
        #define LEX_UJ                      97
        #define LEX_LJ                      98
        #define LEX_UK                      99
        #define LEX_LK                      100
        #define LEX_UL                      101
        #define LEX_LL                      102
        #define LEX_UM                      103
        #define LEX_LM                      104
        #define LEX_UN                      105
        #define LEX_UN_TILDE                106
        #define LEX_LN                      107
        #define LEX_LN_TILDE                108
        #define LEX_UO                      109
        #define LEX_UO_ACUTE                110
        #define LEX_UO_GRAVE                111
        #define LEX_UO_CIRCUMFLEX           112
        #define LEX_UO_DIERESIS             113
        #define LEX_U_OE                    114
        #define LEX_UO_TILDE                115
        #define LEX_UO_SLASH                116
        #define LEX_LO                      117
        #define LEX_LO_ACUTE                118
        #define LEX_LO_GRAVE                119
        #define LEX_LO_CIRCUMFLEX           120
        #define LEX_LO_DIERESIS             121
        #define LEX_L_OE                    122
        #define LEX_LO_TILDE                123
        #define LEX_LO_SLASH                124
        #define LEX_UP                      125
        #define LEX_LP                      126
        #define LEX_UQ                      127
        #define LEX_LQ                      128
        #define LEX_UR                      129
        #define LEX_LR                      130
        #define LEX_US                      131
        #define LEX_LS                      132
        #define LEX_GERMANDBLS              133
        #define LEX_UT                      134
        #define LEX_LT                      135
        #define LEX_UU                      136
        #define LEX_UU_ACUTE                137
        #define LEX_UU_GRAVE                138
        #define LEX_UU_CIRCUMFLEX           139
        #define LEX_UU_DIERESIS             140
        #define LEX_LU                      141
        #define LEX_LU_ACUTE                142
        #define LEX_LU_GRAVE                143
        #define LEX_LU_CIRCUMFLEX           144
        #define LEX_LU_DIERESIS             145
        #define LEX_UV                      146
        #define LEX_LV                      147
        #define LEX_UW                      148
        #define LEX_LW                      149
        #define LEX_UX                      150
        #define LEX_LX                      151
        #define LEX_UY                      152
        #define LEX_UY_ACUTE                153
        #define LEX_UY_DIERESIS             154
        #define LEX_LY                      155
        #define LEX_LY_ACUTE                156
        #define LEX_LY_DIERESIS             157
        #define LEX_UZ                      158
        #define LEX_LZ                      159
        #define LEX_LEFT_BRACKET            160
        #define LEX_BACKSLASH               161
        #define LEX_RIGHT_BRACKET           162
        #define LEX_ASCII_CIRCUMFLEX        163
        #define LEX_UNDERSCORE              164
        #define LEX_BACKQUOTE               165
        #define LEX_LEFT_BRACE              166
        #define LEX_VERTICAL_BAR            167
        #define LEX_RIGHT_BRACE             168
        #define LEX_ASCII_TILDE             169
        #define LEX_DELETE                  170
        #define LEX_DAGGER                  171
        #define LEX_DBLDAGGER               172
        #define LEX_DEGREE                  173
        #define LEX_CENT                    174
        #define LEX_STERLING                175
        #define LEX_CURRENCY                176
        #define LEX_YEN                     177
        #define LEX_SECTION                 178
        #define LEX_BULLET                  179
        #define LEX_DIAMONDBULLET           180
        #define LEX_PARAGRAPH               181
        #define LEX_REGISTERED              182
        #define LEX_COPYRIGHT               183
        #define LEX_TRADEMARK               184
        #define LEX_NOTEQUAL                185
        #define LEX_INFINITY                186
        #define LEX_PLUSMINUS               187
        #define LEX_LESSEQUAL               188
        #define LEX_GREATEREQUAL            189
        #define LEX_APPROX_EQUAL            190
        #define LEX_L_MU                    191
        #define LEX_L_DELTA                 192
        #define LEX_U_SIGMA                 193
        #define LEX_U_PI                    194
        #define LEX_L_PI                    195
        #define LEX_INTEGRAL                196
        #define LEX_ORDFEMININE             197
        #define LEX_ORDMASCULINE            198
        #define LEX_U_OMEGA                 199
        #define LEX_LOGICAL_NOT             200
        #define LEX_ROOT                    201
        #define LEX_FLORIN                  202
        #define LEX_U_DELTA                 203
        #define LEX_ELLIPSIS                204
        #define LEX_ENDASH                  205
        #define LEX_EMDASH                  206
        #define LEX_DIVISION                207
        #define LEX_FRACTION                208
        #define LEX_CNTR_DOT                209
        #define LEX_PERTHOUSAND             210
        #define LEX_LOGO                    211
        #define LEX_ACUTE                   212
        #define LEX_DIERESIS                213
        #define LEX_CIRCUMFLEX              214
        #define LEX_TILDE                   215
        #define LEX_MACRON                  216
        #define LEX_BREVE                   217
        #define LEX_DOTACCENT               218
        #define LEX_RING                    219
        #define LEX_CEDILLA                 220
        #define LEX_HUNGARUMLAT             221
        #define LEX_OGONEK                  222
        #define LEX_CARON                   223

----------
#### LexFirstOrder
    typedef ByteEnum Lex1stOrder;
        #define LEX1_SPACE                  0x20
        #define LEX1_EXCLAMATION            1
        #define LEX1_QUOTE                  2
        #define LEX1_NUMBER_SIGN            3
        #define LEX1_DOLLAR_SIGN            4
        #define LEX1_PERCENT                5
        #define LEX1_AMPERSAND              6
        #define LEX1_SNG_QUOTE              7
        #define LEX1_PARENTHESIS            8
        #define LEX1_ASTERISK               9
        #define LEX1_PLUS                   10
        #define LEX1_COMMA                  11
        #define LEX1_MINUS                  12
        #define LEX1_PERIOD                 13
        #define LEX1_SLASH                  14
        #define LEX1_ZERO                   15
        #define LEX1_ONE                    16
        #define LEX1_TWO                    17
        #define LEX1_THREE                  18
        #define LEX1_FOUR                   19
        #define LEX1_FIVE                   20
        #define LEX1_SIX                    21
        #define LEX1_SEVEN                  22
        #define LEX1_EIGHT                  23
        #define LEX1_NINE                   24
        #define LEX1_COLON                  25
        #define LEX1_SEMICOLON              26
        #define LEX1_LESS_THAN              27
        #define LEX1_EQUAL                  28
        #define LEX1_GREATER_THAN           29
        #define LEX1_QUESTION_MARK          30
        #define LEX1_AT_SIGN                31
        #define LEX1_A                      32
        #define LEX1_B                      33
        #define LEX1_C                      34
        #define LEX1_D                      35
        #define LEX1_E                      36
        #define LEX1_F                      37
        #define LEX1_G                      38
        #define LEX1_H                      39
        #define LEX1_I                      40
        #define LEX1_J                  41
        #define LEX1_K                  42
        #define LEX1_L                  43
        #define LEX1_M                  44
        #define LEX1_N                  45
        #define LEX1_O                  46
        #define LEX1_P                  47
        #define LEX1_Q                  48
        #define LEX1_R                  49
        #define LEX1_S                  50
        #define LEX1_T                  51
        #define LEX1_U                  52
        #define LEX1_V                  53
        #define LEX1_W                  54
        #define LEX1_X                  55
        #define LEX1_Y                  56
        #define LEX1_Z                  57
        #define LEX1_LEFT_BRACKET       58
        #define LEX1_BACKSLASH          59
        #define LEX1_RIGHT_BRACKET      60
        #define LEX1_ASCII_CIRCUMFLEX   61
        #define LEX1_UNDERSCORE         62
        #define LEX1_BACKQUOTE          63
        #define LEX1_LEFT_BRACE         64
        #define LEX1_VERTICAL_BAR       65
        #define LEX1_RIGHT_BRACE        66
        #define LEX1_ASCII_TILDE        67
        #define LEX1_ASCII_DELETE       68
        #define LEX1_DAGGER             69
        #define LEX1_DEGREE             70
        #define LEX1_CENT               71
        #define LEX1_STERLING           72
        #define LEX1_SECTION            73
        #define LEX1_BULLET             74
        #define LEX1_PARAGRAPH          75
        #define LEX1_REGISTERED         76
        #define LEX1_COPYRIGHT          77
        #define LEX1_TRADEMARK          78
        #define LEX1_ACUTE              79
        #define LEX1_DIERESIS           80
        #define LEX1_NOTEQUAL           81
        #define LEX1_INFINITY           82
        #define LEX1_PLUSMINUS          83
        #define LEX1_LESSEQUAL          84
        #define LEX1_GREATEREQUAL       85
        #define LEX1_YEN                86
        #define LEX1_MU                 87
        #define LEX1_DELTA              88
        #define LEX1_SIGMA              89
        #define LEX1_PI                 90
        #define LEX1_INTEGRAL           91
        #define LEX1_ORDFEMININE        92
        #define LEX1_ORDMASCULINE       93
        #define LEX1_OMEGA              94
        #define LEX1_QUESTIONDOWN       95
        #define LEX1_EXCLAMDOWN         96
        #define LEX1_LOGICALNOT         97
        #define LEX1_ROOT               98
        #define LEX1_FLORIN             99
        #define LEX1_APPROX_EQUAL       100
        #define LEX1_ELLIPSIS           101
        #define LEX1_ENDASH             102
        #define LEX1_EMDASH             103
        #define LEX1_DIVISION           104
        #define LEX1_DIAMONDBULLET      105
        #define LEX1_FRACTION           106
        #define LEX1_CURRENCY           107
        #define LEX1_CNTR_DOT           108
        #define LEX1_PERTHOUSAND        109
        #define LEX1_LOGO               110
        #define LEX1_CIRCUMFLEX         111
        #define LEX1_TILDE              112
        #define LEX1_MACRON             113
        #define LEX1_BREVE              114
        #define LEX1_DOTACCENT          115
        #define LEX1_RING               116
        #define LEX1_CEDILLA            117
        #define LEX1_HUNGARUMLAT        118
        #define LEX1_OGONEK             119
        #define LEX1_CARON              120

----------
#### LibraryCallType
    typedef enum /* word */ {
        LCT_ATTACH,             /* The library was just loaded. */
        LCT_DETACH,             /* The library is about to be unloaded. */
        LCT_NEW_CLIENT,         /* A new client of the library was just loaded. */
        LCT_NEW_CLIENT_THREAD,  /* A new thread was just created for a
                                 * current client of the library. */
        LCT_CLIENT_THREAD_EXIT, /* A thread was just exited for a current
                                 * client of the library. */
        LCT_CLIENT_EXIT,        /* Library's client is about to be unloaded. */
    } LibraryCallType

This type is used by library entry point routines. Library entry point routines 
take a value of this enumerated type to determine what, if anything, is to be 
done.

----------
#### LineAttr
    typedef struct {
        byte            LA_colorFlag;
        RGBValue        LA_color;
        SysDrawMask     LA_mask;
        ColorMapMode    LA_mapMode;
        LineEnd         LA_end;
        LineJoin        LA_join;
        LineStyle       LA_style;
        WWFixed         LA_width;
    } LineAttr;

----------
#### LineEnd
    typedef ByteEnum LineEnd;
        #define LE_BUTTCAP              0
        #define LE_ROUNDCAP             1
        #define LE_SQUARECAP            2
        #define LAST_LINE_END_TYPE      LE_SQUARECAP

Line ends determine how the graphics system will draw the end of a line 
segment.

----------
#### LineJoin
    typedef ByteEnum LineJoin;
        #define LJ_MITERED                  0
        #define LJ_ROUND                    1
        #define LJ_BEVELED                  2
        #define LAST_LINE_JOIN_TYPE         LJ_BEVELED

This enumerated type determines how the graphics system will draw corners 
of rectangles and polylines.

----------
#### LineStyle
    typedef ByteEnum LineStyle;
        #define LS_SOLID                    0
        #define LS_DASHED                   1
        #define LS_DOTTED                   2
        #define LS_DASHDOT                  3
        #define LS_DASHDDOT                 4
        #define LS_CUSTOM                   5
        #define MAX_DASH_ARRAY_PAIRS        5

The **LineStyle** type describes a line's "dottedness." Lines using custom 
dashes will work with the **DashPairArray** structure.

----------
#### LMemBlockHeader
    typedef struct {
        MemHandle       LMBH_handle;
        word            LMBH_offset;
        word            LMBH_flags;
        LMemTypes       LMBH_lmemType;
        word            LMBH_blockSize;
        word            LMBH_nHandles;
        word            LMBH_freeList;
        word            LMBH_totalFree;
    } LMemBlockHeader;

This structure is found at the beginning of every block which contains an 
LMem heap. You can examine any of the fields by locking the block and 
casting its address to a ***LMemBlockHeader**. You should not, however, 
change any of the fields yourself; they are managed by the LMem routines.

**Contents:** The header has the following fields:

*LMBH_handle*  
The handle of this block.

*LMBH_offset*  
The offset from the beginning of the block to the beginning of 
the heap.

*LMBH_flags*  
The **LocalMemoryFlags** currently set for the block. The flags 
are described in the entry for **LMemInitHeap()**.

*LMBH_lmemType*  
The type of LMem heap in this block. This field is a member of 
the **LMemType** enumerated type, described in the entry for 
**LMemInitHeap()**.

*LMBH_blockSize*  
The total size of this block. This size may change in either 
direction as a result of chunk allocation and heap compaction.

*LMBH_nHandles*  
The number of handles available in the chunk handle table. 
Not all of these chunks are necessarily allocated as owned or 
free chunks. The table grows automatically when necessary.

*LMBH_freeList*  
The chunk handle of the first free chunk in the linked list of 
free chunks.

*LMBH_totalFree*  
The total amount of free space in the LMem heap.

**Warnings:** Do not change the settings of the LMemBlockHeader. They are 
automatically maintained by the LMem routines.

**Include:** lmem.h

**See Also:** LMemInitHeap()

----------
#### LMemType
    typdef enum {
        LMEM_TYPE_GENERAL,
        LMEM_TYPE_WINDOW,
        LMEM_TYPE_OBJ_BLOCK,
        LMEM_TYPE_GSTATE,
        LMEM_TYPE_FONT_BLK,
        LMEM_TYPE_GSTRING,
        LMEM_TYPE_DB_ITEMS
    } LMemType;

LMem heaps are created for many different purposes. Some of these 
purposes require the heap to have special functionality. For this reason, 
when you create an LMem heap, you must specify what it will be used for. 
The following types are available:

LMEM_TYPE_GENERAL  
The LMem heap will be used for general data storage, possibly 
including a chunk, name, or element array. When an 
application creates an LMem heap, it will almost always be of 
type "General" or "Object."

LMEM_TYPE_OBJ_BLOCK  
Objects are stored in object blocks, which are LMem heaps. An 
object block has some extra header information and contains 
one chunk which contains only flags. All the objects in the block 
are stored as chunks on the heap. Applications can directly 
create object blocks.

LMEM_TYPE_WINDOW  
Windows are stored in memory as LMem heaps. The header 
contains information about the window; each region in the 
window is stored as a chunk. Applications will not directly 
create Window heaps.

LMEM_TYPE_GSTATE  
A GState is an LMem heap. The GState information is in the 
header, and the application clip-rectangle is stored in a chunk. 
Applications do not directly create GState blocks; rather, they 
call a GState creation routine, which creates the block.

LMEM_TYPE_FONT_BLOCK  
Font blocks are stored as LMem heaps. Applications do not 
create font blocks directly.

LMEM_TYPE_GSTRING  
Whenever a GString is created or loaded, a GString LMem 
heap is created, and elements are added as chunks. The heap 
is created automatically by the GString routines; applications 
should not create GString blocks.

LMEM_TYPE_DB_ITEMS  
The Virtual Memory mechanism provides routines to create 
and manage database items, short pieces of data which are 
dynamically allocated and are saved with the VM file. 
Applications do not directly allocate DB blocks; rather, they call 
DB routines, which see to it that the blocks are created. 

**Include:** lmem.h

----------
#### LocalDistanceFlags
    typedef WordFlags LocalDistanceFlags;
        #define LDF_FULL_NAMES                      0x8000
        #define LDF_PRINT_PLURAL_IF_NEEDED          0x4000

----------
#### LocalCmpStringsDosToGeosFlags
    typedef ByteFlags LocalCmpStringsDosToGeosFlags;
        #define LCSDTG_NO_CONVERT_STRING_2              0x02
        #define LCSDTGF_NO_CONVERT_STRING_1             0x01

----------
#### LocalCurrencyFormat
    typedef struct {
        byte    CurrencyFormatFlags;
        byte    currencyDigits;
        word    thousandsSeparator;
        word    decimalSeparator;
        word    listSeparator;
    } LocalCurrencyFormat;

----------
#### LocalMemoryFlags
    typedef WordFlags LocalMemoryFlags;
        #define LMF_HAS_FLAGS               0x8000
        #define LMF_IN_RESOURCE             0x4000
        #define LMF_DETACHABLE              0x2000
        #define LMF_DUPLICATED              0x1000
        #define LMF_RELOCATED               0x0800
        #define LMF_AUTO_FREE               0x0400
        #define LMF_IN_LMEM_ALLOC           0x0200
        #define LMF_IS_VM                   0x0100
        #define LMF_NO_HANDLES              0x0080
        #define LMF_NO_ENLARGE              0x0040
        #define LMF_RETURN_ERRORS           0x0020
        #define LMF_DEATH_COUNT             0x0007
        #define STD_LMEM_OBJECT_FLAGS       (LMF_HAS_FLAGS | LMF_RELOCATED)

When an LMem heap is allocated, certain flags are passed to indicate 
properties the heap should have. Some of the flags are passed only for 
system-created heaps. The flags are stored in a word-length record 
(**LocalMemoryFlags**); the record also contains flags indicating the current 
state of the heap. The **LocalMemoryFlags** are listed below:

LMF_HAS_FLAGS  
Set if the block has a chunk containing only flags. This flag is 
set for object blocks; it is usually cleared for general LMem 
heaps.

LMF_IN_RESOURCE  
Set if the block has just been loaded from a resource and has 
not been changed since being loaded. This flag is set only for 
object blocks created by the compiler.

LMF_DETACHABLE  
Set if the block is an object block which can be saved to a state 
file.

LMF_DUPLICATED  
Set if block is an object block created by the 
**ObjDuplicateBlock()** routine. This flag should not be set by 
applications.

LMF_RELOCATED  
Set if all the objects in the block have been relocated. The object 
system sets this when it has relocated all the objects in the 
block. 

LMF_AUTO_FREE  
This flag is used by several object routines. It indicates that if 
the block's in-use count drops to zero, the block may be freed. 
This flag should not be set by applications.

LMF_IN_MEM_ALLOC  
This flag is used in error-checking code to prevent the heap 
from being validated while a chunk is being allocated. For 
internal use only-do not modify.

LMF_IS_VM  
Set if the LMem heap is in a VM block and the block should be 
marked dirty whenever a chunk is marked dirty. This flag is 
automatically set by the VM code when an LMem heap is 
created in or attached to a VM file. This flag should not be set 
by applications.

LMF_NO_HANDLES  
Set if block does not use chunk handles. A block can be set to 
simulate the C **malloc()** routine; in this case, chunks are not 
relocated after being created, so chunk handles are not needed. 
Ordinarily, these blocks are created by the **malloc()** routine, 
not by applications.

LMF_NO_ENLARGE  
Indicates that the local-memory routines should not enlarge 
this block to fulfill chunk requests. This guarantees that the 
block will not be moved by a chunk allocation request; however, 
it makes these requests more likely to fail.

LMF_RETURN_ERRORS  
Set if local memory routines should return errors when 
allocation requests cannot be fulfilled. If the flag is not set, 
allocation routines will fatal-error if they cannot comply with 
requests. This flag is generally clear for expandable LMem 
blocks, since many system routines (such as **ObjInstantiate()**) 
are optimized in such a way that they cannot deal with LMem 
allocation errors.

LMF_DEATH_COUNT  
This field occupies the least significant three bits of the flag 
field. It means nothing if the value is zero. If it is non-zero, it 
indicates the number of remove-block messages left which 
must hit **BlockDeathCommon** before it will free the block. 
This flag is used by the handlers for MSG_FREE_DUPLICATE 
and MSG_REMOVE_BLOCK.

STD_LMEM_OBJ_FLAGS
This is a constant which combines the LMF_HAS_FLAGS **and** 
LMF_RELOCATED flags. These flags should be set for all object 
blocks.

**Include:** lmem.h

----------
#### LocalNumericFormat
    typedef struct {
        byte    numberFormatFlags;
        byte    decimalDigits;
        word    thousandsSeparator;
        word    decimalSeparator;
        word    listSeparator;
    } LocalNumericFormat;

----------
#### LocalQuotes
    typedef struct {
        word    frontSingle;
        word    endSingle;
        word    frontDouble;
        word    endDouble;
    } LocalQuotes;

----------
#### ManufacturerID
    typedef enum { /* word */
        MANUFACTURER_ID_GEOWORKS
    } ManufacturerID;

----------
#### MapColorToMono
    typedef ByteEnum MapColorToMono;
        #define CMT_CLOSEST             0
        #define CMT_DITHER              1

This type determines what the graphics system will do when trying to draw 
in an unavailable color. It will either draw in the closest color, or else mix two 
or more close colors to get as close as possible overall.

----------
#### MapListBlockHeader
    typedef struct {
        LMemBlockHeader         MLBH_base;
        word                    MLBH_numDestFields;
        word                    MLBH_chunk1;
    } MapListBlockHeader;

----------
#### MarginDimensions
    typedef struct {
        int     leftMargin;
        int     topMargin;
        int     rightMargin;
        int     bottomMargin;
    } MarginDimensions;

----------
#### MeasurementType
    typedef ByteEnum MeasurementType;
        #define MEASURE_US              0
        #define MEASURE_METRIC          1

----------
#### MediaType
    typedef enum /* byte */ {
        #define MEDIA_NONEXISTENT       0
        #define MEDIA_160K              1
        #define MEDIA_180K              2
        #define MEDIA_320K              3
        #define MEDIA_360K              4
        #define MEDIA_720K              5
        #define MEDIA_1M2               6
        #define MEDIA_1M44              7
        #define MEDIA_2M88              8
        #define MEDIA_FIXED_DISK        9
        #define MEDIA_CUSTOM            10
    } MediaType;

The **MediaType** enumerated type indicates how a disk is formatted. A 
member of this enumerated type is returned by some disk-information 
routines (e.g. **DriveGetDefaultMedia()**). A **MediaType** value is also 
passed to **DiskFormat()**, indicating how the disk should be formatted.

----------
#### MemGetInfoType
    typedef enum /* word */ {
        MGIT_SIZE=0,                    /* size in bytes */
        MGIT_FLAGS_AND_LOCK_COUNT=2,    /* use MGI_LOCK_COUNT and MGI_FLAGS */
        MGIT_OWNER_OR_VM_FILE_HANDLE=4,
        MGIT_ADDRESS=6,
        MGIT_OTHER_INFO=8,
        MGIT_EXEC_THREAD=10
    } MemGetInfoType;

----------
#### MemHandle
    typedef Handle MemHandle;

----------
#### Message
    typedef word Message;

----------
#### MessageError
    typedef enum /* word */ {
         MESSAGE_NO_ERROR,          /* no error was encountered */
         MESSAGE_NO_HANDLES         /* no handle could be allocated
                                     * and MF_CAN_DISCARD_IF_DESPARATE
                                     * was passed */
    } MessageErrors;

A **MessageError** is returned by **ObjMessage()** in assembly to indicate 
whether the message was successfully sent. This is not encountered by C 
applications.

----------
#### MessageFlags
    typedef WordFlags MessageFlags;
        #define MF_CALL                     0x8000      /* @call */
        #define MF_FORCE_QUEUE              0x4000
        #define MF_STACK                    0x2000      /* @stack */
        #define MF_CHECK_DUPLICATE          0x0800
        #define MF_CHECK_LAST_ONLY          0x0400
        #define MF_REPLACE                  0x0200
        #define MF_CUSTOM                   0x0100
        #define MF_FIXUP_DS                 0x0080
        #define MF_FIXUP_ES                 0x0040
        #define MF_DISCARD_IF_NO_MATCH      0x0020
        #define MF_MATCH_ALL                0x0010
        #define MF_INSERT_AT_FRONT          0x0008      /* puts at front of queue */
        #define MF_CAN_DISCARD_IF_DESPERATE 0x0004
        #define MF_RECORD                   0x0002      /* @record */
        #define MF_DISPATCH_DONT_FREE       0x0002
**MessageFlags** are specified in the assembly version of **ObjMessage()**. Most 
of these flags are set properly by Goc and the kernel in C. See the reference 
entries for the Goc keywords **@call** and **@send**.

----------
#### MessageHandle
    typedef Handle MessageHandle;

----------
#### MessageMethod
    typedef void     MessageMethod();

----------
#### MinIncrementType
    typedef union {
        MinUSMeasure                MIT_US;
        MinMetricMeasure            MIT_METRIC;
        MinPointMeasure             MIT_POINT;
        MinPicaMeasure              MIT_PICA;
    } MinIncrementType;

----------
#### MinMetricMeasure
    typedef ByteEnum MinMetricMeasure;
        #define MMM_MILLIMETER                  0
        #define MMM_HALF_CENTIMETER             1
        #define MMM_CENTIMETER                  2

----------
#### MinPicaMeasure
    typedef ByteEnum MinPicaMeasure;
        #define MPM_PICA                    0
        #define MPM_INCH                    1

----------
#### MinPointMeasure
    typedef ByteEnum MinPointMeasure;
        #define MPM_25_POINT                    0
        #define MPM_50_POINT                    1
        #define MPM_100_POINT                   2

----------
#### MinUSMeasure
    typedef ByteEnum MinUSMeasure;
        #define MUSM_EIGHTH_INCH                0
        #define MUSM_QUARTER_INCH               1
        #define MUSM_HALF_INCH                  2
        #define MUSM_ONE_INCH                   3

----------
#### MixMode
    typedef ByteEnum MixMode;
        #define MM_CLEAR        0   /* clear destination */
        #define MM_COPY         1   /* new drawing is opaque */
        #define MM_NOP          2   /* no drawing */
        #define MM_AND          3   /* logical AND of new and old colors */
        #define MM_INVERT       4   /* inverse of old color */
        #define MM_XOR          5   /* XOR of new and old colors */
        #define MM_SET          6   /* set destination black */
        #define MM_OR           7   /* logical OR of new and old colors */

The **MixMode** determines what the graphics system will do when drawing 
one thing on top of another.

----------
#### MonoTransfer
    typedef struct {
        byte MT_gray[256];
    } MonoTransfer;

----------
#### MouseReturnFlags
    typedef WordFlags MouseReturnFlags;
        #define MRF_PROCESSED                       0x8000
        #define MRF_REPLAY                          0x4000
        #define MRF_PREVENT_PASS_THROUGH            0x2000
        #define MRF_SET_POINTER_IMAGE               0x1000
        #define MRF_CLEAR_POINTER_IMAGE             0x0800

These flags are used in various parts of the system that work with mouse 
input. Which values are appropriate to pass will vary based on context.

----------
#### MouseReturnParams
    typedef struct {
        word                    unused;
        MouseReturnFlags        flags;
        optr                    ptrImage;
    } MouseReturnParams;

This structure is used in certain areas of the system which work with mouse 
input.

----------
#### NameArrayAddFlags
    typedef WordFlags NameArrayAddFlags;
        #define NAAF_SET_DATA_ON_REPLACE 0x8000

----------
#### NameArrayElement
    typedef struct {
        RefElementHeader NAE_meta;
    } NameArrayElement;

----------
#### NameArrayHeader
    typedef struct{
        ElementArrayHeader      NAH_meta;
        word                    NAH_dataSize;   /* Size of data section of
                                                 * each element */
    } NameArrayHeader;

Every name array must begin with a **NameArrayHeader**. Since name 
arrays are special kinds of element arrays, the **NameArrayHeader** must 
itself begin with an **ElementArrayHeader**. The structure contains one 
additional field, *NAH_dataSize*. This field specifies how long the data section 
of every element is. Applications may examine this field, but they must not 
change it.

----------
#### NameArrayMaxElement
    typedef struct {
        RefElementHeader NAME_meta;
        byte NAME_data[NAME_ARRAY_MAX_DATA_SIZE];
        char NAME_name[NAME_ARRAY_MAX_NAME_SIZE];
    } NameArrayMaxElement;

----------
### NO_ERROR_RETURNED
    #define NO_ERROR_RETURNED               0

----------
#### NoteType
    typedef ByteEnum NoteType;
        #define NT_INK          0
        #define NT_TEXT         1

----------
#### NotificationType
    typedef struct {
        ManufacturerID          NT_manuf;
        word            NT_type;
    } NotificationType;

----------
#### NotifyInkHasTarget
    typedef struct {
        optr    NIHT_optr;
    } NotifyInkHasTarget;

----------
#### NULL
    #undef NULL
    #define NULL        0

----------
#### NullChunk
    #define NullChunk       ((ChunkHandle) 0)

----------
#### NullClass
    #define NullClass       ((ClassStruct *) 0)

----------
#### NullHandle
    #define NullHandle      ((Handle) 0)

----------
#### NullOptr
    #define NullOptr        ((optr) 0)

----------
#### NumberFormatFlags
    typedef ByteFlags NumberFormatFlags;
        #define NFF_LEADING_ZERO                0x01

----------
#### NumberType
    typedef ByteEnum NumberType;
        #define NT_VALUE                0
        #define NT_BOOLEAN              1
        #define NT_DATE_TIME            2

----------
#### ObjChunkFlags
    typedef ByteFlags ObjChunkFlags;
        #define OCF_VARDATA_RELOC           0x10
        #define OCF_DIRTY                   0x08
        #define OCF_IGNORE_DIRTY            0x04
        #define OCF_IN_RESOURCE             0x02
        #define OCF_IS_OBJECT               0x01

This record is stored at the beginning of each chunk and gives specific 
information about the chunk. The flags are internal.

----------
#### ObjLMemBlockHeader
    typedef struct {
        LMemBlockHeader     OLMBH_header;   /* standard LMem block header */
        word                OLMBH_inUseCount;
        word                OLMBH_interactibleCount;
        optr                OLMBH_output;
        word                OLMBH_resourceSize;
    } ObjLMemBlockHeader;

This is the standard Object Block header that begins every object block; you 
can set additional header fields with the **@header** Goc keyword. The fields of 
this structure are

*OLMBH_header*  
The standard LMem block header. See the 
**LMemBlockHeader** structure type.

*OLMBH_inUseCount*  
The "in use" count for the block. If not zero, then the block may 
not safely be freed.

*OLMBH_interactibleCount*  
The "interactable" count for the block. If not zero, then one or 
more objects in the block are either visible to the user or about 
to be activated by the user (e.g. via keyboard shortcut). A block 
with a non-zero interactible count may not be swapped.

*OLMBH_output*  
The optr of the object that will be notified about changes in 
resource status, such as in-use count changing to or from zero. 
Messages may also be sent to this output object via the 
**TravelOption** TO_OBJ_BLOCK_OUTPUT.

*OLMBH_resourceSize*  
The size of the object block (resource).

----------
#### ObjRelocation
    typedef struct {
        ObjRelocationType       OR_type;
        word                    OR_offset;
    } ObjRelocation;

----------
#### ObjRelocationSource
    typedef ByteEnum ObjRelocationSource;
        #define ORS_NULL                            0
        #define ORS_OWNING_GEODE                    1
        #define ORS_KERNEL                          2
        #define ORS_LIBRARY                         3
        #define ORS_CURRENT_BLOCK                   4
        #define ORS_VM_HANDLE                       5
        #define ORS_OWNING_GEODE_ENTRY_POINT        6
        #define ORS_NON_STATE_VM                    7
        #define ORS_UNKNOWN_BLOCK                   8
        #define ORS_EXTERNAL                        9
        #define RID_SOURCE_OFFSET                   12

----------
#### ObjRelocationType
    typedef ByteEnum ObjRelocationType;
        #define RELOC_END_OF_LIST                       0
        #define RELOC_RELOC_HANDLE                      1
        #define RELOC_RELOC_SEGMENT                     2
        #define RELOC_RELOC_ENTRY_POINT                 3

----------
#### OperatorStackElement
    typedef struct {
        EvalStackOperatorType OSE_type;
        EvalStackOperatorType OSE_data;
    } OperatorStackElement;

----------
#### OperatorType
    typedef ByteEnum OperatorType;
        #define OP_RANGE_SEPARATOR                      0
        #define OP_NEGATION                             1
        #define OP_PERCENT                              2
        #define OP_EXPONENTIATION                       3
        #define OP_MULTIPLICATION                       4
        #define OP_DIVISION                             5
        #define OP_MODULO                               6
        #define OP_ADDITION                             7
        #define OP_SUBTRACTION                          8
        #define OP_EQUAL                                9
        #define OP_NOT_EQUAL                            10
        #define OP_LESS_THAN                            11
        #define OP_GREATER_THAN                         12
        #define OP_LESS_THAN_OR_EQUAL                   13
        #define OP_GREATER_THAN_OR_EQUAL                14
        #define OP_STRING_CONCAT                        15
        #define OP_RANGE_INTERSECTION                   16
        #define OP_NOT_EQUAL_GRAPHIC                    17
        #define OP_DIVISION_GRAPHIC                     18
        #define OP_LESS_THAN_OR_EQUAL_GRAPHIC           19
        #define OP_GREATER_THAN_OR_EQUAL_GRAPHIC        20
        #define OP_PERCENT_MODULO                       21
        #define OP_SUBTRACTION_NEGATION                 22

----------

----------
#### optr
    typedef dword optr;

----------
#### PageLayout
    typedef union {
        PageLayoutPaper             PL_paper;
        PageLayoutEnvelope          PL_envelope;
        PageLayoutLabel             PL_label;
    } PageLayout;

----------
#### PageLayoutEnvelope
    typedef WordFlags PageLayoutEnvelope;
        #define PLE_PATH                0x0040
        #define PLE_ORIENTATION         0x0010
        #define PLE_TYPE                0x0004

----------
#### PageLayoutLabel
    typedef WordFlags PageLayoutLabel;
        #define PLL_ROWS            0x7e00          /* labels down */
        #define PLL_COLUMNS         0x01f8          /* labels across */
        #define PLL_TYPE            0x0004          /* PT_LABEL */

----------
#### PageLayoutPaper
    typedef WordFlags PageLayoutPaper;
        #define PLP_ORIENTATION         0x0008
        #define PLP_TYPE                0x0004

----------
#### PageSize
    typedef struct {
        word            unused;
        word            PS_width;
        word            PS_height;
        PageLayout      PS_layout;
    } PageSize;

----------
#### PageSizeCtrlAttrs
    typedef WordFlags PageSizeCtrlAttrs;
        #define PZCA_ACT_LIKE_GADGET            0x8000
        #define PZCA_PAPER_SIZE                 0x4000
        #define PZCA_INITIALIZE                 0x2000

----------
#### PageSizeCtrlFeatures
    typedef ByteFlags PageSizeControlFeatures;
        #define PSIZECF_MARGINS             0x04
        #define PSIZECF_ALL                 0x02
        #define PSIZECF_PAGE_TYPE           0x01

----------
#### PageSizeReport
    typedef struct {
        dword               PSR_width;
        dword               PSR_height;
        PageLayout          PSR_layout;
        PCMarginParams      PSR_margins;
    } PageSizeReport:

----------
#### PageType
    typedef enum {
        PT_PAPER,
        PT_ENVELOPE,
        PT_LABEL
    } PageType;

----------
#### PaperOrientation
    typedef ByteEnum PaperOrientation;
        #define PO_PORTRAIT             0x00
        #define PO_LANDSCAPE            0x01

----------
#### ParallelUnit
    typedef enum
        {
            PARALLEL_LPT1 = 0,
            PARALLEL_LPT2 = 2,
            PARALLEL_LPT3 = 4,
            PARALLEL_LPT4 = 6,
        } ParallelUnit;

----------
#### ParserFlags
    typedef ByteFlags ParserFlags;
        #define PF_HAS_LOOKAHEAD                0x80
        #define PF_CONTAINS_DISPLAY_FUNC        0x40
        #define PF_OPERATORS                    0x20
        #define PF_NUMBERS                      0x10
        #define PF_CELLS                        0x08
        #define PF_FUNCTIONS                    0x04
        #define PF_NAMES                        0x02
        #define PF_NEW_NAMES                    0x01

----------
#### ParserParameters
    typedef struct {
        CommonParameters    PP_common;
        word                PP_parserBufferSize;
        ParserFlags         PP_flags;
        dword               PP_textPtr;
        ScannerToken        PP_currentToken;
        ScannerToken        PP_lookAheadToken;
        byte                PP_error;       /* ParserScannerEvaluatorError */
        word                PP_tokenStart;
        word                PP_tokenEnd;
    } ParserParameters;

----------
#### ParserScannerEvaluatorError
    typedef ByteEnum ParserScannerEvaluatorError;
        /*
         * Scanner errors
         */
        #define PSEE_BAD_NUMBER                     0
        #define PSEE_BAD_CELL_REFERENCE             1
        #define PSEE_NO_CLOSE_QUOTE                 2
        #define PSEE_COLUMN_TOO_LARGE               3
        #define PSEE_ROW_TOO_LARGE                  4
        #define PSEE_ILLEGAL_TOKEN                  5
        /*
         * Parser errors
         */
        #define PSEE_GENERAL                        6
        #define PSEE_TOO_MANY_TOKENS                7
        #define PSEE_EXPECTED_OPEN_PAREN            8
        #define PSEE_EXPECTED_CLOSE_PAREN           9
        #define PSEE_BAD_EXPRESSION                 10
        #define PSEE_EXPECTED_END_OF_EXPRESSION     11
        #define PSEE_MISSING_CLOSE_PAREN            12
        #define PSEE_UNKNOWN_IDENTIFIER             13
        #define PSEE_NOT_ENOUGH_NAME_SPACE          14
        /*
         * Serious evaluator errors
         */
        #define PSEE_OUT_OF_STACK_SPACE             15
        #define PSEE_NESTING_TOO_DEEP               16
        /*
         * Evaluator errors that are returned as the result of formulas.
         * These are returned on the argument stack.
         */
        #define PSEE_ROW_OUT_OF_RANGE               17
        #define PSEE_COLUMN_OUT_OF_RANGE            18
        #define PSEE_FUNCTION_NO_LONGER_EXISTS      19
        #define PSEE_BAD_ARG_COUNT                  20
        #define PSEE_WRONG_TYPE                     21
        #define PSEE_DIVIDE_BY_ZERO                 22
        #define PSEE_UNDEFINED_NAME                 23
        #define PSEE_CIRCULAR_REF                   24
        #define PSEE_CIRCULAR_DEP                   25
        #define PSEE_CIRC_NAME_REF                  26
        #define PSEE_NUMBER_OUT_OF_RANGE            27
        #define PSEE_GEN_ERR                        28
        #define PSEE_NA                             29
        /*
         * Dependency errors
         */
        #define PSEE_TOO_MANY_DEPENDENCIES          30
        #define PSEE_SSHEET_BASE                    0xc0
        #define PSEE_FLOAT_BASE                     250
        #define PSEE_APP_BASE                       230
        #define PSEE_FLOAT_POS_INFINITY             PSEE_FLOAT_BASE
        #define PSEE_FLOAT_NEG_INFINITY             (PSEE_FLOAT_BASE + 1)
        #define PSEE_FLOAT_GEN_ERR                  (PSEE_FLOAT_BASE + 2)

----------
### ParserToken
    typedef struct {
        ParserTokenType         PT_type;
        ParserTokenData         PT_data;
    } ParserToken;

----------
#### ParserTokenCellData
    typedef struct {
        CellReference           PTCD_cellRef;
    } ParserTokenCellData;

----------
#### ParserTokenData
    typedef union {
        ParserTokenNumberData               PTD_number;
        ParserTokenStringData               PTD_string;
        ParserTokenNameData                 PTD_name;
        ParserTokenCellData                 PTD_cell;
        ParserTokenFunctionData             PTD_function;
        ParserTokenOperatorData             PTD_operator;
    } ParserTokenData;

----------
#### ParserTokenFunctionData
    typedef struct {
        word        PTFD_functionID;
    } ParserTokenFunctionData;

----------
#### ParserTokenNameData
    typedef struct {
        word        PTND_name;
    } ParserTokenNameData;

----------
#### ParserTokenNumberData
    typedef struct {
        FloatNum        PTND_value;
    } ParserTokenNumberData;

----------
#### ParserTokenOperatorData
    typedef struct {
        OperatorType            PTOD_operatorID;
    } ParserTokenOperatorData;

----------
#### ParserTokenStringData
    typedef struct {
        word        PTSD_length;
    } ParserTokenStringData;

----------
#### ParserTokenType
    typedef ByteEnum ParserTokenType;
        #define PARSER_TOKEN_NUMBER                 0
        #define PARSER_TOKEN_STRING                 1
        #define PARSER_TOKEN_CELL                   2
        #define PARSER_TOKEN_END_OF_EXPRESSION      3
        #define PARSER_TOKEN_OPEN_PAREN             4
        #define PARSER_TOKEN_CLOSE_PAREN            5
        #define PARSER_TOKEN_NAME                   6
        #define PARSER_TOKEN_FUNCTION               7
        #define PARSER_TOKEN_CLOSE_FUNCTION         8
        #define PARSER_TOKEN_ARG_END                9
        #define PARSER_TOKEN_OPERATOR               10

----------
#### PathCombineType
    typedef enum /* word */ {
        PCT_NULL,           /* wipe out old path */
        PCT_REPLACE,        /* replace old path with upcoming path */
        PCT_UNION,          /* union old path with new */
        PCT_INTERSECTION    /* intersect old path with new */
    } PathCombineType;

----------
#### PathName
    typedef char PathName[PATH_BUFFER_SIZE];

----------
#### PatternType
    typedef ByteEnum PatternType;
        #define PT_SOLID                    0
        #define PT_SYSTEM_HATCH             1
        #define PT_SYSTEM_BITMAP            2
        #define PT_USER_HATCH               3
        #define PT_USER_BITMAP              4
        #define PT_CUSTOM_HATCH             5
        #define PT_CUSTOM_BITMAP            6

----------
#### PCDocSizeParams
    typedef struct {
        dword   PCDSP_width;
        dword   PCDSP_height;
    } PCDocSizeParams;

Use this structure to communicate document sizes to a Print Control.

----------
#### PCMarginParams
    typedef struct {
        word    PCMP_left;          /* left margin */
        word    PCMP_top;           /* top margin */
        word    PCMP_right;         /* right margin */
        word    PCMP_bottom;        /* bottom margin */
    } PCMarginParams

This structure holds information about a document's or printer's margins.

----------
#### PCProgressType
    typedef enum {
        PCPT_PAGE,
        PCPT_PERCENT,
        PCPT_TEXT
    } PCProgressType;

----------
#### Point
    typedef struct {
        sword P_x;
        sword P_y;
    } Point;

----------
#### PointDWord
    typedef struct {
        sdword PD_x;
        sdword PD_y;
    } PointDWord;

----------
#### PointDWFixed
    typedef struct {
        DWFixed PDF_x;
        DWFixed PDF_y;
    } PointDWFixed;

----------
#### PointerDef
    typedef struct {
        sbyte   PD_hotX;
        sbyte   PD_hotY;
        byte    PD_mask[STANDARD_CURSOR_IMAGE_SIZE];
        byte    PD_image[STANDARD_CURSOR_IMAGE_SIZE];
    } PointerDef;
         STANDARD_CURSOR_IMAGE_SIZE = 32

This structure defines a mouse pointer.

----------
#### PointWWFixed
    typedef struct {
        WWFixed     PF_x;
        WWFixed     PF_y;
    } PointWWFixed;

These structures are used to specify graphics point coordinates. Which point 
structure to use depends on size of the coordinate space and accuracy 
required.

----------
#### PrintControlAttrs
    typedef WordFlags PrintControlAttrs;
        #define PCA_MARK_APP_BUSY       0x2000      /* mark busy while printing */
        #define PCA_VERIFY_PRINT        0x1000      /* verify before printing */
        #define PCA_SHOW_PROGRESS       0x0800      /* show print progress dialog box */
        #define PCA_PROGRESS_PERCENT    0x0400      /* show progress by percentage */
        #define PCA_PROGRESS_PAGE       0x0200      /* show progress by page */
        #define PCA_FORCE_ROTATION      0x0100      /* Force rotation of output */
        #define PCA_COPY_CONTROLS       0x0080      /* Copy controls are available */
        #define PCA_PAGE_CONTROLS       0x0040      /* Page range controls available */
        #define PCA_QUALITY_CONTROLS    0x0020      /* Quality controls available */
        #define PCA_USES_DIALOG_BOX     0x0010      /* Dialog box should appear */
        #define PCA_GRAPHICS_MODE       0x0008      /* Supports graphics mode output */
        #define PCA_TEXT_MODE           x0004       /* Supports text mode output */
        #define PCA_DEFAULT_QUALITY     0x0002      /* default print quality */

----------
#### PrintControlFeatures
        typedef ByteFlags PrintControlFeatures;
        #define PRINTCF_PRINT_TRIGGER   0x02    /* wants a print trigger */
        #define PRINTCF_FAX_TRIGGER     0x01    /* wants a fax trigger */

----------
#### PrintControlStatus
    typedef enum {
        PCS_PRINT_BOX_VISIBLE,
        PCS_PRINT_BOX_NOT_VISIBLE
    } PrintControlStatus;

----------
#### PrintControlToolboxFeatures
    typedef ByteFlags PrintControlToolboxFeatures;
        #define PRINTCTF_PRINT_TRIGGER  0x02    /* wants a print tool trigger */
        #define PRINTCTF_FAX_TRIGGER    0x01    /* wants a fax tool trigger */

----------
#### PrinterDriverType
    typedef enum PrinterDriverType;
        PDT_PRINTER,
        PDT_PLOTTER,
        PDT_FACSIMILE,
        PDT_CAMERA,
        PDT_OTHER,
    } PrinterDriverType;

This enumerated type indicates the type of printer driver that we are 
dealing with.

----------
#### PrinterOutputModes
    typedef ByteFlags PrinterOutputModes;
        #define POM_GRAPHICS_LOW        0x10
        #define POM_GRAPHICS_MEDIUM     0x08
        #define POM_GRAPHICS_HIGH       0x04
        #define POM_TEXT_DRAFT          0x02
        #define POM_TEXT_NLQ            0x01
        #define PRINT_GRAPHICS = (POM_GRAPHICS_LOW | POM_GRAPHICS_MEDIUM |
                                 POM_GRAPHICS_HIGH )
        #define PRINT_TEXT = (POM_TEXT_DRAFT | POM_TEXT_NLQ)

----------
#### PrintQualityEnum
    typedef enum {
        PQT_HIGH,
        PQT_MEDIUM,
        PQT_LOW
    } PrintQualityEnum;

----------
#### ProtocolNumber
    typedef struct {
        word    PN_major;
        word    PN_minor;
    } ProtocolNumber;

Defines the protocol level of a file, geode, or document. *PN_major* represents 
significant compatibility comparisons, and *PN_minor* represents less 
significant differences. If the major protocol is different between two items, 
they are incompatible. If the minor protocol is different, they may or may not 
be incompatible.

----------
#### QueueHandle
    typedef Handle QueueHandle;

----------
#### QuickSortParameters
    typedef struct _QuickSortParameters {
        word _pascal (*QSP_compareCallback) (void *     el1, 
                                             void *     el2,
                                             word       valueForCallback));
        void _pascal (*QSP_lockCallback) (void *el, word valueForCallback));
        void _pascal (*QSP_unlockCallback) (void *el, word valueForCallback));
        word        QSP_insertLimit;
        word        QSP_medianLimit;

        /* These are set internally by the quicksort algorithm and should not
         * be set by the caller: */
        word        QSP_nLesser;
        word        QSP_nGreater;
    } QuickSortParameters;

This structure is passed to **ArrayQuickSort**. The fields have the following 
meanings:

**QSP_compareCallback*  
This routine is called to compare elements. It should be 
declared _pascal. It should return a positive value if **el1* ought 
to come before *\*el2* in the sorted list; a negative value if **el1* 
ought to come after **el2* in the sorted list; and zero if it doesn't 
matter which comes first.

**QSP_lockCallback*  
This routine is called before **ArrayQuickSort** examines or 
changes any element. It should be declared _pascal. You can 
pass a null function pointer, indicating that no locking callback 
routine should be called.

**QSP_lockCallback*  
This routine is called after **ArrayQuickSort** examines or 
changes any element. It should be declared _pascal. You can 
pass a null function pointer, indicating that no unlocking 
callback routine should be called.

*QSP_insertLimit*  
If there are fewer than *QSP_insertLimit* elements in a sublist, 
**ArrayQuickSort** will use an insertion sort for that sublist, 
rather than a QuickSort.

*QSP_medianLimit*  
If there are fewer than *QSP_medianLimit* elements in a sublist, 
**ArrayQuickSort** will use the first element as a partition, 
instead of searching for the median element.

----------
#### RangeEnumCallbackParams
    typedef struct {
        RangeEnumParams     *RECP_params;
        word                RECP_row;
        word                RECP_column;
        word                RECP_cellData;
    } RangeEnumCallbackParams;

This structure is passed to the callback routine for **RangeEnum()**.

----------
#### RangeEnumFlags
    typedef ByteFlags RangeEnumFlags;
        #define REF_ALL_CELLS                   0x80
        #define REF_NO_LOCK                     0x40
        #define REF_COLUMN_FLAGS                0x20
        #define REP_MATCH_COLUMN_FLAGS          0x10
        #define REF_CELL_ALLOCATED              0x08
        #define REF_CELL_FREED                  0x04
        #define REF_OTHER_ALLOC_OR_FREE         0x02
        #define REF_COLUMN_FLAGS_MODIFIED       0x01

These flags are used by RangeEnum().

----------
#### RangeEnumParams
    typedef struct {
        PCB(RANGE_ENUM_CALLBACK_RETURN_TYPE, REP_callback,
                                        (RangeEnumCallbackParams));
        Rectangle               REP_bounds;
        byte                    REP_columnFlags;
        word                    *REP_columnFlagsArray;
        CellFunctionParameters  *REP_cfp;
        byte                    REP_matchFlags;
        word                    *REP_locals;
    } RangeEnumParams;

This structure is used by two routines, **RangeEnum()** and 
**CellGetExtent()**. When it is used by **RangeEnum()**, the structure specifies 
all the details about how **RangeEnum()** will function. **CellGetExtent()** is 
passed a blank **RangeEnumParams** structure; it fills in the *REP_bounds* 
field.

The callback routine, if any, should be declared _pascal.

**Include:** cell.h

----------
#### RangeInsertParams
    typedef struct {
        Rectangle       RIP_bounds;
        Point           RIP_delta;
        dword           RIP_cfp;
    } RangeInsertParams;
**RangeInsert()** is passed the address of a **RangeInsertParams** structure. 
This structure specifies three things:

*RIP_bounds* - Which cells should be shifted.

*RIP_delta* - How far the cells should be shifted and in which direction.

*RIP_cfp* - The address of the CellFunctionParameters structure. You 
don't have to initialize this; the routine will do so automatically.

**Include:** cell.h

**See Also:** RangeInsert()

----------
#### RangeSortError
    typedef enum /* word */ {
        RSE_NO_ERROR,
        RSE_UNABLE_TO_ALLOC,
    } RangeSortError;

----------
#### RangeSortCellExistFlags
    typedef ByteFlags RangeSortCellExistsFlags;
        #define RSCEF_SECOND_CELL_EXISTS    0x02
        #define RSCEF_FIRST_CELL_EXISTS     0x01

----------
#### RangeSortFlags
    typedef ByteFlags RangeSortFlags;
        #define RSF_SORT_ROWS               0x80
        #define RSF_SORT_ASCENDING          0x40
        #define RSF_IGNORE_CASE             0x20

----------
#### RangeSortParams
    typedef struct {
        Rectangle       RSP_range;
        Point           RSP_active;
        dword           RSP_callback;
        byte            RSP_flags; /* RangeSortFlags */
        dword           RSP_cfp;
        word            RSP_sourceChunk;
        word            RSP_destChunk;
        word            RSP_base;
        dword           RSP_lockedEntry;
        byte            RSP_cachedFlags;
    } RangeSortParams;

----------
#### Rectangle
    typedef struct {
        sword   R_left;
        sword   R_top;
        sword   R_right;
        sword   R_bottom;
    } Rectangle;

This structure represents a graphics rectangle.

----------
#### RectDWord
    typedef struct {
        sdword  RD_left;
        sdword  RD_top;
        sdword  RD_right;
        sdword  RD_bottom;
    } RectDWord;

This structure represents a graphics rectangle.

----------
#### RectRegion
    typedef struct {
        word    RR_y1M1;
        word    RR_eo1;     /* EOREGREC */
        word    RR_y2;
        word    RR_x1;
        word    RR_x2;
        word    RR_eo2;     /* EOREGREC */
        word    RR_eo3;     /* EOREGREC */
    } RectRegion;

----------
#### RefElementHeader
    typedef struct {
         WordAndAHalf REH_refCount;
    } RefElementHeader;

----------
#### Region
    typedef word Region;
        #define EOREGREC                0x8000
        #define EOREG_HIGH               0x80

This structure represents a region of a graphics coordinate space.

Regions are described in terms of a rectangular array (thus the similarity to 
bitmaps). Instead of specifying an on/off value for each pixel, however, 
regions assume that the region will be fairly undetailed and that the data 
structure can thus be treated in the manner of a sparse array. Only the cells 
in which the color value of a row changes are recorded. The tricky part here 
is keeping in mind that when figuring out whether or not a row is the same 
as a previous row, the system works its way up from the bottom, so that you 
should compare each row with the row beneath it to determine whether it 
needs an entry.

The easiest region to describe is the null region, which is a special case 
described by a single word with the value EOREGREC (a constant whose 
name stands for *E*nd *O*f *REG*ion *REC*ord value). Describing a non-null region 
requires several numbers.

The first four numbers of the region description give the bounds of the region. 
Next come one or more series of numbers. Each series describes a row, 
specifying which pixels of that row are part of the region. The only rows 
which need to be described are those which are different from the row below. 
The first number of each row description is the row number, its *y* coordinate. 
The last number of each series is a special token, EOREGREC, which lets the 
kernel know that the next number of the description will be the start of 
another row. Between the row number and EOREGREC are the column 
numbers where the pixels toggle on and off. The first number after the row 
number corresponds to the first column in which the pixel is on; the next 
number is the first subsequent column in which the pixel is off; and so on.

----------
#### RegionFillRule
    typedef ByteEnum RegionFillRule;
        #define ODD_EVEN            0
        #define WINDING             1

This enumerated type determines how a path or region should be filled. 
Winding fill is more versatile, but requires that the path or polygon's edges 
run in the correct direction.

----------
#### ReleaseNumber
    typedef struct {
        word    RN_major;
        word    RN_minor;
        word    RN_change;
        word    RN_engineering;
    } ReleaseNumber;

Used to record what version a file, document, or geode is. This represents the 
release level; the most significant numbers are *RN_major* and *RN_minor*. The 
other fields are typically used only internally to a manufacturer.

----------
#### ResolveStandardPathFlags
    typedef WordFlags FileResolveStandardPathFlags;
        #define FRSPF_ADD_DRIVE_NAME            0x0002
        #define FRSPF_RETURN_FIRST_DIR          0x0001

----------
#### RGBColorAsDWord
    typedef dword RGBColorAsDWord;
        RGB_RED(val) ( val & 0xff)
        RGB_GREEN(val) ( (val >> 8) & 0xff )
        RGB_BLUE(val) ( (val >> 16) & 0xff )
        RGB_INDEX(val) ( (val >> 24) & 0xff )

See the **ColorQuad** data structure to find out the meanings of the fields.

----------
#### RGBDelta
    typedef struct {
        byte    RGBD_red;
        byte    RGBD_green;
        byte    RGBD_blue;
    } RGBDelta;

----------
#### RGBTransfer
    typedef struct {
        byte    RGBT_red[256];
        byte    RGBT_green[256];
        byte    RGBT_blue[256];
    } RGBTransfer;

----------
#### RGBValue
    typedef struct {
        byte    RGB_red;
        byte    RGB_green;
        byte    RGB_blue;
    } RGBValue;

----------
#### SampleFormat
    typedef struct {
        DACSampleFormat SMID_format:15;
        DACReferenceByte SMID_reference:1;
    } SampleFormat;

----------
#### SampleFormatDescription
    typedef struct {
         word   SFD_manufact;
         word   SFD_format;
         word   SFD_rate;
         word   SFD_playFlags;
    } SampleFormatDescription;

This structure acts as a header for a sampled sound, giving format 
information needed to properly interpret the sound data.

----------
#### SansFace
    typedef byte SansFace;
        #define SF_A_CLOSED 0x0080
        #define SF_A_OPEN 0x0000

----------
#### sbyte
    typedef char sbyte;

----------
#### ScannerToken
    typedef struct {
        ScannerTokenType                ST_type;
        ScannerTokenData                ST_data;
    } ScannerToken;

----------
#### ScannerTokenCellData
    typedef struct {
        CellReference           STCD_cellRef;
    } ScannerTokenCellData;

----------
#### ScannerTokenData
    typedef union {
        ScannerTokenNumberData                  STD_number;
        ScannerTokenStringData                  STD_string;
        ScannerTokenCellData                    STD_cell;
        ScannerTokenIdentifierData              STD_identifier;
        ScannerTokenOperatorData                STD_operator;
    } ScannerTokenData;

----------
#### ScannerTokenIdentifierData
    typedef struct {
        word        STID_start;
    } ScannerTokenIdentifierData;

----------
#### ScannerTokenNumberData
    typedef struct {
        FloatNum        STND_value;
    } ScannerTokenNumberData;

----------
#### ScannerTokenOperatorData
    typedef struct {
        OperatorType            STOD_operatorID;
    } ScannerTokenOperatorData;

----------
#### ScannerTokenStringData
    typedef struct {
        word    STSD_start;
        word    STSD_length;
    } ScannerTokenStringData;

----------
#### ScannerTokenType
    typedef ByteEnum ScannerTokenType;
        #define SCANNER_TOKEN_NUMBER                        0
        #define SCANNER_TOKEN_STRING                        1
        #define SCANNER_TOKEN_CELL                          2
        #define SCANNER_TOKEN_END_OF_EXPRESSION             3
        #define SCANNER_TOKEN_OPEN_PAREN                    4
        #define SCANNER_TOKEN_CLOSE_PAREN                   5
        #define SCANNER_TOKEN_IDENTIFIER                    6
        #define SCANNER_TOKEN_OPERATOR                      7
        #define SCANNER_TOKEN_LIST_SEPARATOR                8

----------
#### ScriptAttrAsWord
    typedef word ScriptAttrAsWord;
        /*  High byte is a vertical offset, as a fraction of the font size.
            Low byte is a fractional scale to use.
            Thus, setting a subscript attr to 0x8020 would result in subscript
            characters being printed half a line down and at 1/4 normal size. */

This structure specifies the offset and scale factor with which sub- and 
superscript characters should draw.

----------
#### ScriptFace
    typedef byte ScriptFace;
        #define SF_CURSIVE 0x0080
        #define SF_CALLIGRAPHIC 0x0000

----------
#### sdword
    typedef long sdword;

----------
#### segment
    typedef word segment;

----------
#### SemaphoreError
    typedef enum {
        SE_NO_ERROR,            /* No error occurred */
        SE_TIMEOUT,             /* The semaphore timed out before
                                 * it could be grabbed by the thread */
        SE_PREVIOUS_OWNER_DIED  /* The current holder of the semaphore
                                 * exited abnormally */
    } SemaphoreError;

Determines the error encountered by semaphore and threadlock routines 
such as **ThreadPSem()** and **ThreadPTimedSem()**.

----------
#### SerialBaud
    typedef enum
        {
            SERIAL_BAUD_115200          = 1,
            SERIAL_BAUD_57600           = 2,
            SERIAL_BAUD_38400           = 3,
            SERIAL_BAUD_19200           = 6,
            SERIAL_BAUD_14400           = 8,
            SERIAL_BAUD_9600            = 12,
            SERIAL_BAUD_7200            = 16,
            SERIAL_BAUD_4800            = 24,
            SERIAL_BAUD_3600            = 32,
            SERIAL_BAUD_2400            = 48,
            SERIAL_BAUD_2000            = 58,
            SERIAL_BAUD_1800            = 64,
            SERIAL_BAUD_1200            = 96,
            SERIAL_BAUD_600             = 192,
            SERIAL_BAUD_300             = 384
        } SerialBaud;

----------
#### SerialFormat
    typedef ByteFlags SerialFormat;
        #define SERIAL_FORMAT_DLAB_OFFSET       (7)
        #define SERIAL_FORMAT_DLAB              (0x01 << SERIAL_FORMAT_DLAB_OFFSET)

        #define SERIAL_FORMAT_BREAK_OFFSET      (6)
        #define SERIAL_FORMAT_BREAK             (0x01 << SERIAL_FORMAT_BREAK_OFFSET)

        #define SERIAL_FORMAT_PARITY_OFFSET     (3)
        #define SERIAL_FORMAT_PARITY            (0x07 << SERIAL_FORMAT_PARITY_OFFSET)

        #define SERIAL_FORMAT_EXTRA_STOP_OFFSET (2)
        #define SERIAL_FORMAT_EXTRA_STOP        (0x01 << \ 
                                                SERIAL_FORMAT_EXTRA_STOP_OFFSET)

        #define SERIAL_FORMAT_LENGTH_OFFSET     (0)
        #define SERIAL_FORMAT_LENGTH            (0x03 << SERIAL_FORMAT_LENGTH_OFFSET)

----------
#### SerialMode
    typedef enum {
            SERIAL_MODE_RAW,
            SERIAL_MODE_RARE,
            SERIAL_MODE_COOKED
    } SerialMode;

----------
#### SerialModem
    typedef ByteFlags SerialModem;
        #define SERIAL_MODEM_OUT2_OFFSET    (3)
        #define SERIAL_MODEM_OUT2           (0x01 << SERIAL_MODEM_OUT2_OFFSET)

        #define SERIAL_MODEM_OUT1_OFFSET    (2)
        #define SERIAL_MODEM_OUT1           (0x01 << SERIAL_MODEM_OUT1_OFFSET)

        #define SERIAL_MODEM_RTS_OFFSET     (1)
        #define SERIAL_MODEM_RTS            (0x01 << SERIAL_MODEM_RTS_OFFSET)

        #define SERIAL_MODEM_DTR_OFFSET     (0)
        #define SERIAL_MODEM_DTR            (0x01 << SERIAL_MODEM_DTR_OFFSET)

----------
#### SerialPortNum
    typedef enum
        {
            SERIAL_COM1         = 0,
            SERIAL_COM2         = 2,
            SERIAL_COM3         = 4,
            SERIAL_COM4         = 6,
            SERIAL_COM5         = 8,
            SERIAL_COM6         = 10,
            SERIAL_COM7         = 12,
            SERIAL_COM8         = 14
        } SerialPortNum;

----------
#### SerialUnit
    typedef enum
        {
            SERIAL_COM1         = 0,
            SERIAL_COM2         = 2,
            SERIAL_COM3         = 4,
            SERIAL_COM4         = 6,
            SERIAL_COM5         = 8,
            SERIAL_COM6         = 10,
            SERIAL_COM7         = 12,
            SERIAL_COM8         = 14
        } SerialUnit;

----------
#### SemaphoreHandle
    typedef Handle SemaphoreHandle;

----------
#### SerifFace
    typedef byte SerifFace;
        #define SF_SLAB     0x00c0
        #define SF_MODERN   0x0080
        #define SF_TRANS    0x0040
        #define SF_OLD      0x0000

----------
#### SetPalType
    typedef ByteEnum SetPalType;
        #define SPT_DEFAULT             0
        #define SPT_CUSTOM              1

----------
#### ShiftState
    typedef ByteFlags ShiftState;
        #define SS_LALT                 0x80
        #define SS_RALT                 0x40
        #define SS_LCTRL                0x20
        #define SS_RCTRL                0x10
        #define SS_LSHIFT               0x08
        #define SS_RSHIFT               0x04
        #define SS_FIRE_BUTTON_1        0x02
        #define SS_FIRE_BUTTON_2        0x01

Modifiers which will be incorporated into input information. Corresponds to 
alt keys, control keys, shift keys, or special system modifiers. Note that these 
bits will only be set if not already accounted for; that is, if you are passed the 
character "E", the shift modifiers of this structure will not be marked.

----------
#### SoundDriverCapability
    typedef WordFlags SoundDriverCapability;
        #define SDC_NOISE               0x8000
        #define SDC_WAVEFORM            0x6000
        #define SDC_TIMBRE              0x1800
        #define SDC_ENVELOPE            0x0600

    typedef WordFlags SoundDriverNoiseCapability;
        #define SDNC_NO_NOISE           0x0000
        #define SDNC_WHITE_NOISE            0x8000

    typedef WordFlags SoundDriverWaveFormCapability
        #define SDWFC_NONE              0x0000
        #define SDWFC_SELECT            0x2000
        #define SDWFC_GENERATE          0x4000

    typedef WordFlags SoundDriverTimbreCapability;
        #define SDTC_TONE_GENERATOR 0x0000
        #define SDTC_ADDITIVE           0x0800
        #define SDTC_MODULATOR          0x1000
        #define SDTC_SELECTIVE          0x1800

    typedef WordFlags SoundDriverEnvelopeCapability;
        #define SDEC_NONE               0x0000
        #define SDEC_ADSR               0x0200
        #define SDEC_DSP                0x0400

These fields encode information about what the sound driver is capable of in 
terms of music synthesis.

----------
#### SoundPlayFlags
    typedef WordFlags SoundPlayFlags;
        #define SPF_HIGH_PRIORITY               0x8000

----------
#### SoundPriority
    typedef enum {
         SP_SYSTEM_LEVEL=10,        /* most urgent */
         SP_ALARM=20,
         SP_STANDARD=30,
         SP_GAME=40,
         SP_BACKGROUND=50           /* least urgent */
    } SoundPriority;

    #define SP_IMMEDIATE            -1
    #define SP_THEME                +1

If the user's sound device can't play all requested sounds, it will use 
**SoundPriority** values to determine which sounds are the most important.

The highest priority sound you may construct using these values is 
(SP_SYSTME_LEVEL + SP_IMMEDIATE). The least priority sound would be 
(SP_BACKGROUND + SP_THEME).

----------
#### SoundSteamDeltaTimeType
    typedef enum {
         SSDTT_MSEC=8,                  /* wait for N mili seconds */
         SSDTT_TICKS=10,                /* wait for N ticks */
         SSDTT_TEMPO=12,                /* wait for N beats */
    } SoundStreamDeltaTimeType;
        /* The following macros may help when constructing music buffers */
        #define DeltaTick(time)         SSDTT_TICKS, time
        #define DeltaMS(time)           SSDTT_MSEC, time
        #define DeltaTempo(time)        SSDTT_TEMPO, time

These are the units by which you can specify a sound's duration: 
milliseconds, timer "ticks" (each 1/60 second), or by means of an 
independently supplied tempo.

----------
#### SoundStreamEvents
    typedef enum {
         SSE_VOICE_ON=0,            /* turn on voice event */
         SSE_VOICE_OFF=2,           /* turn off voice event */
         SSE_CHANGE=4,              /* change instrument */
         SSE_GENERAL=6              /* system-specific event */
    } SoundStreamEvents;
        /* The following macros may help when constructing music buffers */
        #define General(command)  SSE_GENERAL, command

        #define Rest(duration)  General(GE_NO_EVENT), DeltaTick(duration)

        #define VoiceOn(voice,freq,attack)  SSE_VOICE_ON, voice, freq, attack
        #define VoiceOff(voice) SSE_VOICE_OFF, voice
        #define ChangeEnvelope(voice, instrument, table)  \
                                SSE_CHANGE, voice, instrument, table

        #define SoundNote(voice,freq,duration,attack)  \
                        VoiceOn(voice, freq, attack), DeltaTempo(duration), VoiceOff(voice)
        #define Staccato(voice,freq,duration,attack) \
                        VoiceOn(voice, freq, attack), DeltaTempo(((duration*0x03)/0x04)), \
                        VoiceOff(voice), DeltaTempo((duration/0x4))
        #define Natural(voice,freq,duration,attack) \
                        VoiceOn(voice, freq, attack), DeltaTempo(((duration*0x07)/0x08)),
                        VoiceOff(voice), DeltaTempo((duration/0x8))
        #define Legato(voice,freq,duration,attack)  \
                        SoundNote(voice, freq, duration, attack)

These are the "events" that make up a music buffer. 

----------
#### SoundStreamSize
    typedef word SoundStreamSize;
        #define SSS_ONE_SHOT 128    /* 128 bytes (very small) */
        #define SSS_SMALL 256       /* 256 bytes */
        #define SSS_MEDIUM 512      /* 512 bytes (nice size) */
        #define SSS_LARGE 1024 

----------
#### SoundStreamType
    #define SST_ONE_SHOT        128
    #define SST_SMALL           256
    #define SST_MEDIUM          512
    #define SST_LARGE           1024

----------
#### SpecialFunctions
    typedef enum /* word */ {
        SF_FILENAME,
        SF_PAGE,
        SF_PAGES,
    } SpecialFunctions;

----------
#### SpoolError
    typedef enum /* word */ {
        SERROR_NO_SPOOL_FILE,
        SERROR_NO_PRINT_DRIVER,
        SERROR_NO_PORT_DRIVER,
        SERROR_NO_PRINTERS,
        SERROR_NO_MODE_AVAIL,
        SERROR_CANT_ALLOC_BITMAP,
        SERROR_NO_VIDMEM_DRIVER,
        SERROR_MANUAL_PAPER_FEED,
        SERROR_CANT_LOAD_PORT_DRIVER,
        SERROR_PORT_BUSY,
        SERROR_TEST_NO_PAPER,
        SERROR_TEST_OFFLINE,
        SERROR_TEST_PARALLEL_ERROR,
        SERROR_MISSING_COM_PORT,
        SERROR_PRINT_ON_STARTUP
    } SpoolError;

----------
#### SpoolFileName
    typedef struct {
        char    SFN_base[5];
        char    SFN_num[3];
        char    SFN_ext[5];
    } SpoolFileName;

----------
#### SpoolInfoType
    typedef enum /* word */ {
        SIT_JOB_INFO,
        SIT_QUEUE_INFO
    } SpoolInfoType;

----------
#### SpoolOpStatus
    typedef enum /* word */ {
        SPOOL_OPERATION_SUCCESSFUL,
        SPOOL_JOB_NOT_FOUND,
        SPOOL_QUEUE_EMPTY,
        SPOOL_QUEUE_NOT_EMPTY,
        SPOOL_QUEUE_NOT_FOUND,
        SPOOL_CANT_VERIFY_PORT,
        SPOOL_OPERATION_FAILED
    } SpoolOpStatus;

----------
#### SpoolTimeStruct
    typedef struct {
        byte    STS_second;         /* second of the minute (0-59) */
        byte    STS_minute;         /* minute of the hour (0-59) */
        byte    STS_hour;           /* hour of the day (0-23) */
    } SpoolTimeStruct;

----------
#### SpoolVerifyAction
    typedef enum {
        SVA_NO_MESSAGE,
        SVA_WARNING,
        SVA_PRINTING
    } SpoolVerifyAction;

----------
#### StandardDialogBoxType
    typedef enum {
        SDBT_FILE_NEW_CANNOT_CREATE_TEMP_NAME,
        SDBT_FILE_NEW_INSUFFICIENT_DISK_SPACE,
        SDBT_FILE_NEW_ERROR,
        SDBT_FILE_NEW_WRITE_PROTECTED,
        SDBT_FILE_OPEN_SHARING_DENIED,
        SDBT_FILE_OPEN_FILE_NOT_FOUND,
        SDBT_FILE_OPEN_INVALID_VM_FILE,
        SDBT_FILE_OPEN_INSUFFICIENT_DISK_SPACE,
        SDBT_FILE_OPEN_ERROR,
        SDBT_FILE_OPEN_READ_ONLY,
        SDBT_FILE_OPEN_VM_DIRTY,
        SDBT_FILE_OPEN_APP_MORE_RECENT_THAN_DOC,
        SDBT_FILE_OPEN_DOC_MORE_RECENT_THAN_APP,
        SDBT_FILE_SAVE_INSUFFICIENT_DISK_SPACE,
        SDBT_FILE_SAVE_ERROR,
        SDBT_FILE_SAVE_WRITE_PROTECTED,
        SDBT_FILE_SAVE_AS_FILE_EXISTS,
        SDBT_FILE_SAVE_AS_SHARING_DENIED,
        SDBT_FILE_CLOSE_SAVE_CHANGES,
        SDBT_FILE_CLOSE_ATTACH_DIRTY,
        SDBT_FILE_REVERT_CONFIRM,
        SDBT_FILE_REVERT_ERROR,
        SDBT_FILE_ATTACH_DISK_NOT_FOUND,
        SDBT_CANNOT_OPEN_VOLUME_SELECTED,
        SDBT_QUERY_SAVE_AS_TEMPLATE,
        SDBT_QUERY_SAVE_AS_EMPTY,
        SDBT_QUERY_SAVE_AS_DEFAULT,
        SDBT_QUERY_SAVE_AS_MULTI_USER,
        SDBT_QUERY_SAVE_AS_PUBLIC,
        SDBT_QUERY_RESET_EMPTY_FILE,
        SDBT_QUERY_RESET_DEFAULT_FILE,
        SDBT_CANNOT_OPEN_EMPTY_FILE
    } StandardDialogBoxType;

----------
#### StandardDialogParams
    typedef struct {
        word                                 SDP_customFlags;
        char                                *SDP_customString;
        char                                *SDP_stringArg1;
        char                                *SDP_stringArg2;
        StandardDialogResponseTriggerTable  *SDP_customTriggers;
    } StandardDialogParams;

----------
#### StandardDialogOptrParams
    typedef struct {
        word    SDOP_customFlags;
        optr    SDOP_customString;
        optr    SDOP_stringArg1;
        optr    SDOP_stringArg2;
        optr    SDOP_customTriggers;
    } StandardDialogOptrParams;

----------
#### StandardDialogResponseTriggerEntry
    typedef struct {
        optr    SDRTE_moniker;
        word    SDRTE_responseValue;
    } StandardDialogResponseTriggerEntry;

----------
#### StandardDialog1ResponseTriggerTable
    typedef struct {
         word                                   SD1RTT_numTriggers;
         StandardDialogResponseTriggerEntry     SD1RTT_trigger1;
    } StandardDialog1ResponseTriggerTable;

----------
#### StandardDialog2ResponseTriggerTable
    typedef struct {
         word                                   SD2RTT_numTriggers;
         StandardDialogResponseTriggerEntry     SD2RTT_trigger1;
         StandardDialogResponseTriggerEntry     SD2RTT_trigger2;
    } StandardDialog2ResponseTriggerTable;

----------
#### StandardDialog3ResponseTriggerTable
    typedef struct {
         word                                   SD3RTT_numTriggers;
         StandardDialogResponseTriggerEntry     SD3RTT_trigger1;
         StandardDialogResponseTriggerEntry     SD3RTT_trigger2;
         StandardDialogResponseTriggerEntry     SD3RTT_trigger3;
    } StandardDialog3ResponseTriggerTable;

----------
#### StandardDialog4ResponseTriggerTable
    typedef struct {
         word                                   SD4RTT_numTriggers;
         StandardDialogResponseTriggerEntry     SD4RTT_trigger1;
         StandardDialogResponseTriggerEntry     SD4RTT_trigger2;
         StandardDialogResponseTriggerEntry     SD4RTT_trigger3;
         StandardDialogResponseTriggerEntry     SD4RTT_trigger4;
    } StandardDialog4ResponseTriggerTable;

----------
#### StandardPath
    typedef enum /* word */ {
        SP_NOT_STANDARD_PATH=0,
        SP_TOP=1,
        SP_APPLICATION=3,
        SP_DOCUMENT=5,
        SP_SYSTEM=7,
        SP_PRIVATE_DATA=9,
        SP_STATE=11,
        SP_FONT=13,
        SP_SPOOL=15,
        SP_SYS_APPLICATION=17,
        SP_PUBLIC_DATA=19,
        SP_MOUSE_DRIVERS=21,
        SP_PRINTER_DRIVERS=23,
        SP_FILE_SYSTEM_DRIVERS=25,
        SP_VIDEO_DRIVERS=27,
        SP_SWAP_DRIVERS=29,
        SP_KEYBOARD_DRIVERS=31,
        SP_FONT_DRIVERS=33,
        SP_IMPORT_EXPORT_DRIVERS=35,
        SP_TASK_SWITCH_DRIVERS=37,
        SP_HELP_FILES=39,
        SP_TEMPLATE=41,
        SP_POWER_DRIVERS=43,
        SP_DOS_ROOM=45,
        SP_HWR=47,
        SP_WASTE_BASKET=49,
        SP_BACKUP=51,
        SP_PAGER_DRIVERS=53
        SP_DUMMY=256
    } StandardPath;

Most routines which are passed disk handles can also be passed members of 
the **StandardPath** enumerated type. Standard paths let applications access 
files in a disk-independent manner. Standard paths are usually arranged in 
a certain hierarchy; for example, the STATE directory usually belongs to the 
PRIVDATA directory. However, this is entirely at the user's discretion; 
applications may not make any assumption about how the standard paths 
are arranged.

----------
#### StandardSoundType
    typedef enum /* word */ {
        SST_ERROR,                  /* Sound produced when an Error box comes up. */
        SST_WARNING,                /* General warning beep sound */
        SST_NOTIFY,                 /* General notify beep */
        SST_NO_INPUT,               /* Sound produced when the user's
                                     * keystrokes/mouse presses are not going
                                     * anywhere */
        SST_CUSTOM_BUFFER=0xfffe,   /* Allows applications to play a custom
                                     * note buffer and does all the checking
                                     * for sound being off, etc. */
        SST_CUSTOM_NOTE=0xffff      /* Allows applications to play a custom
                                     * note and does all the checking for sound
                                     * being off, etc. */
    } StandardSoundType;

----------
#### StreamBlocker
    typedef enum{
            STREAM_BLOCK            = 2,
            STREAM_NO_BLOCK         = 0
    } StreamBlocker;

----------
#### StreamError
    typedef enum{
            STREAM_WOULD_BLOCK,
            STREAM_CLOSING,
            STREAM_CANNOT_ALLOC,
            STREAM_BUFFER_TOO_LARGE,
            STREAM_CLOSED,
            STREAM_SHORT_READ_WRITE
    } StreamError;

----------
#### StreamOpenFlags
    typedef enum {
            STREAM_OPEN_NO_BLOCK                = 0x01,
            STREAM_OPEN_TIMEOUT             = 0x02
    } StreamOpenFlags

----------
#### StreamToken
    typedef Handleword StreamToken;

----------
#### StreamRoles
    typedef enum {
            STREAM_ROLES_WRITER             = 0,
            STREAM_ROLES_READER             = -1,
            STREAM_ROLES_BOTH               = -2
    } StreamRoles;

----------
#### StyleChunkDesc
    typedef struct {
        VMFileHandle        SCD_vmFile;
        word                SCD_vmBlockOrMemHandle;
        ChunkHandle         SCD_chunk;
    } StyleChunkDesc;

----------
#### StyleElementFlags
    typedef WordFlags StyleElementFlags;
        #define SEF_DISPLAY_IN_TOOLBOX                      0x8000

----------
#### StyleElementHeader
    typedef struct {
        NameArrayElement        SEH_meta;
        word                    SEH_baseStyle;
        StyleElementFlags       SEH_flags;
        dword                   SEH_privateData;
    } StyleElementHeader;

----------
#### StyleSheetElementHeader
    typedef struct {
         RefElementHeader           SSEH_meta;
         word                       SSEH_style;
    } StyleSheetElementHeader;

----------
#### SupportedEnvelopeFormat
    typedef enum {
         SEF_NO_FORMAT,
         SEF_SBI_FORMAT,
         SEF_CTI_FORMAT
    } SupportedEnvelopeFormat;

These values specify how a sound device can simulate musical instruments, 
if it can at all.

----------
#### sword
    typedef signed short sword;

----------
#### SysConfigFlags
    typedef ByteFlags SysConfigFlags;
        #define SCF_UNDER_SWAT          0x80
        #define SCF_2ND_IC              0x40
        #define SCF_RTC                 0x20
        #define SCF_COPROC              0x10
        #define SCF_RESTARTED           0x08
        #define SCF_CRASHED             0x04
        #define SCF_MCA                 0x02
        #define SCF_LOGGING             0x01

The above flags indicate the system configuration. Any or all of these flags 
may be set at a time; if a flag is set, the description is true. These flags are 
used by the kernel and can be retrieved with **SysGetConfig()**.

----------
#### SysDrawMask
    typedef ByteFlags SysDrawMask;
        #define SDM_INVERSE             0x80
        #define SDM_MASK                0x7f

----------
#### SysGetInfoType
**See:** SysGetInfo().

----------
#### SysMachineType
    typedef ByteEnum SysMachineType;
        #define SMT_UNKNOWN             0
        #define SMT_PC                  1
        #define SMT_PC_CONV             2
        #define SMT_PC_JR               3
        #define SMT_PC_XT               4
        #define SMT_PC_XT_286           5
        #define SMT_PC_AT               6
        #define SMT_PS2_30              7
        #define SMT_PS2_50              8
        #define SMT_PS2_60              9
        #define SMT_PS2_80              10
        #define SMT_PS1                 11

A byte-sized value indicating the type of machine running GEOS. This value 
can be retrieved with **SysGetConfig()**.

----------
#### SysNotifyFlags
**See:** SysNotify().

----------
#### SysProcessorType
    typedef ByteEnum SysProcessorType;
        #define SPT_8088                0
        #define SPT_8086                0
        #define SPT_80186               1
        #define SPT_80286               2
        #define SPT_80386               3
        #define SPT_80486               4

This enumerated type is a byte that indicates the type of processor on the 
system running GEOS. It can be retrieved with **SysGetConfig()**.

----------
#### SysShutdownType
**See:** SysShutdown().

----------
#### SysStats
    typedef struct {
        dword           SS_idleCount;       /* Idle ticks in the last second. */
        SysSwapInfo     SS_swapOuts;        /* Outward-bound swap activity. */
        SysSwapInfo     SS_swapIns;         /* Inward-bound swap actividy. */
        word            SS_contextSwitches; /* Context switches in last second. */
        word            SS_interrupts;      /* Interrupts in the last second. */
        word            SS_runQueue;        /* Runnable threads at end of
                                             * last second. */
    } SysStats;

This structure is returned by **SysStatistics()** and represents the current 
performance statistics of GEOS.

----------
#### SysSwapInfo
    typedef struct {
        word    SSI_paragraphs;     /* Number of paragraphs swapped. */
        word    SSI_blocks;         /* Number of blocks swapped. */
    } SysSwapInfo;

Structure used to represent current swap activity in **SysStats** structure.

----------
#### SystemDrawMask
    typedef ByteEnum SystemDrawMask;
        #define SDM_TILE                0
        #define SDM_SHADED_BAR          1
        #define SDM_HORIZONTAL          2
        #define SDM_VERTICAL            3
        #define SDM_DIAG_NE             4
        #define SDM_DIAG_NW             5
        #define SDM_GRID                6
        #define SDM_BIG_GRID            7
        #define SDM_BRICK               8
        #define SDM_SLANT_BRICK         9
        #define SDM_0                   89
        #define SDM_12_5                81
        #define SDM_25                  73
        #define SDM_37_5                65
        #define SDM_50                  57
        #define SDM_62_5                49
        #define SDM_75                  41
        #define SDM_87_5                33
        #define SDM_100                 25
        #define SDM_CUSTOM              0x7f
        #define SET_CUSTOM_PATTERN      SDM_CUSTOM

----------
#### SystemHatch
    typedef ByteEnum SystemHatch;
        #define SH_VERTICAL             0
        #define SH_HORIZONTAL           1
        #define SH_45_DEGREE            2
        #define SH_135_DEGREE           3
        #define SH_BRICK                4
        #define SH_SLANTED_BRICK        5

----------
#### TargetLevel
    typedef enum /* word */ {
        TL_TARGET                   = 0,
        TL_CONTENT,
        TL_GENERIC_OBJECTS          = 1000,
        TL_GEN_SYSTEM,
        TL_GEN_FIELD,
        TL_GEN_APPLICATION,
        TL_GEN_PRIMARY,
        TL_GEN_DISPLAY_CTRL,
        TL_GEN_DISPLAY,
        TL_GEN_VIEW,
        TL_LIBRARY_LEVELS           = 2000,
        TL_APPLICATION_OBJECTS      = 3000,
    } TargetLevel;

----------
#### TestRectReturnType
    typedef ByteEnum TestRectReturnType;
        #define TRRT_OUT            0
        #define TRRT_PARTIAL        1
        #define TRRT_IN             2

----------
#### TextAttr
    typedef struct {
        byte                TA_colorFlag;
        RGBValue            TA_color;
        SysDrawMask         TA_mask;
        GraphicPattern      TA_pattern;
        TextStyle           TA_styleSet;
        TextStyle           TA_styleClear;
        TextMode            TA_modeSet;
        TextMode            TA_modeClear;
        WBFixed             TA_spacePad;
        FontID              TA_font;
        WBFixed             TA_size;
        sword               TA_trackKern;
    } TextAttr;

----------
#### TextMode
    typedef ByteFlags TextMode;
        #define TM_TRACK_KERN                       0x40
        #define TM_PAIR_KERN                        0x20
        #define TM_PAD_SPACES                       0x10
        #define TM_DRAW_BASE                        0x08
        #define TM_DRAW_BOTTOM                      0x04
        #define TM_DRAW_ACCENT                      0x02
        #define TM_DRAW_OPTIONAL_HYPHENS            0x01

----------
#### TextStyle
    typedef ByteFlags TextStyle;
        #define TS_OUTLINE                  0x40
        #define TS_BOLD                     0x20
        #define TS_ITALIC                   0x10
        #define TS_SUPERSCRIPT              0x08
        #define TS_SUBSCRIPT                0x04
        #define TS_STRIKE_THRU              0x02
        #define TS_UNDERLINE                0x01

----------
#### ThreadException
    typedef enum {
        TE_DIVIDE_BY_ZERO=0,
        TE_OVERFLOW=4,
        TE_BOUND=8,
        TE_FPU_EXCEPTION=12,
        TE_SINGLE_STEP=16,
        TE_BREAKPOINT=20
    } ThreadException;

Processor exceptions used primarily for debugging, these are used with 
**ThreadHandleException()**.

----------
#### ThreadGetInfoType
    typedef enum {
        TGIT_PRIORITY_AND_USAGE,    /* high byte is thread's recent CPU usage
                                     * low byte is thread's base priority */
        TGIT_THREAD_HANDLE,         /* handle of the thread */
        TGIT_QUEUE_HANDLE,          /* handle of thread's event queue */
    } ThreadGetInfoType;

Used with the routine **ThreadGetInfo()**, it determines the type of 
information returned by that routine. Use the macros TGI_PRIORITY and 
TGI_RECENT_CPU_USAGE to separate the TGIT_PRIORITY_AND_USAGE 
value into its components.

----------
#### ThreadHandle
    typedef Handle ThreadHandle;

----------
#### ThreadLockHandle
    typedef Handle ThreadLockHandle;

----------
#### ThreadModifyFlags
    typedef ByteFlags ThreadModifyFlags;
        #define TMF_BASE_PRIO               0x80
        #define TMF_ZERO_USAGE              0x40

Used with **ThreadModify()**, these flags determine what aspect of the thread 
is modified.

----------
#### TimerCompressedDate
    typedef WordFlags TimerCompressedDate;
        #define TCD_YEAR        0xfe00  /* years since 1980; e.g. 1988 is `8' */
        #define TCD_MONTH       0x01e0  /* months (1 - 12) (0 illegal) */
        #define TCD_DAY         0x001f  /* days (1-31) (0 illegal) */

----------
#### TimerDateAndTime
    typedef struct {
        word            TDAT_year;      /* Year based on 1980. (10 => 1990) */
        word            TDAT_month;     /* Number of month (1 through 12) */
        word            TDAT_day;       /* Number of day in month (1 through 31) */
        DaysOfTheWeek   TDAT_dayOfWeek; /* DayOfTheWeek enumeration */
        word            TDAT_hours;     /* Hour of the day (0 through 23) */
        word            TDAT_minutes;   /* Minute in the hour (0 through 59) */
        word            TDAT_seconds;   /* Second in the minute (0 through 59) */
    } TimerDateAndTime;

This structure is used to keep track of the current time and date.

----------
#### TimerHandle
    typedef Handle TimerHandle;

----------
#### TimerType
**See:** TimerStart().

----------
#### ToggleState
    typedef ByteFlags ToggleState;
        #define TS_CAPSLOCK             0x80
        #define TS_NUMLOCK              0x40
        #define TS_SCROLLLOCK           0x20

This structure describes the state of certain "toggles" which will affect how 
input is interpreted. These toggles correspond to the caps lock, num lock, and 
scroll lock keys.

----------
#### TokenChars
    typedef char TokenChars[TOKEN_CHARS_LENGTH]; /* TOKEN_CHARS_LENGTH=4 */

----------
#### TokenDBItem
    typedef DBGroupAndItem TokenDBItem;

----------
#### TokenEntry
    typedef struct {
        GeodeToken      TE_token;       /* A GeodeToken structure for this file */
        TokenDBItem     TE_monikerList; /* A list of monikers for this token */
        TokenFlags      TE_flags;       /* Flags indicating relocation status */
        ReleaseNumber   TE_release;     /* Release number of the token DB */
        ProtocolNumber  TE_protocol;    /* Protocol number of the toke DB */
    } TokenEntry;

Used for the token entry in the map item of the token database, this structure 
identifies the structures and other information of each token. The 
*TE_monikerList* field points to a chunk containing the item numbers of the 
chunks of the token.

----------
#### TokenFlags
    typedef WordFlags TokenFlags;
        #define TF_NEED_RELOCATION              0x8000

Used by token management routines, this flags record indicates whether the 
token has fields which must be relocated when the token is loaded or 
unloaded.

----------
#### TokenGroupEntry
    typedef struct {
        TokenIndexType  TGE_type;           /* The type of structure this is. */
        GroupType       TGE_groupType;      /* The type of the group item. */
        word            TGE_groupNum;       /* The number of the group. */
        word            TGE_groupSize;      /* The size of the group. */
    } TokenGroupEntry;

Used to index token groups in the token database.

----------
#### TokenGroupType
    typedef enum {
        TGT_MAP_GROUP,              /* The TokenGroupEntry is a map group. */
        TGT_MONIKER_LIST_GROUP,     /* The TokenGroupEntry is a moniker list group. */
        TGT_TEXT_MONIKER_GROUP,     /* The TokenGroupEntry is a text moniker group. */
        TGT_CGA_MONIKER_GROUP,      /* The TokenGroupEntry is a CGA moniker group. */
        TGT_EGA_MONIKER_GROUP,      /* The TokenGroupEntry is an EGA moniker group. */
        TGT_VGA_MONIKER_GROUP,      /* The TokenGroupEntry is a VGA moniker group. */
        TGT_HGC_MONIKER_GROUP,      /* The TokenGroupEntry is an HGC moniker group. */
    } TokenGroupType;

This enumerated type describes which type of moniker group is stored in the 
particular chunk.

----------
#### TokenIndexType
    typedef enum {
        TIT_TOKEN_ENTRY,        /* The type is a TokenEntry structure. */
        TIT_GROUP_ENTRY,        /* The type is a GroupEntry structure. */
    } TokenIndexType;

Used to indicate the types of structures that may be stored in the token 
database's map item.

----------
#### TokenMonikerInfo
    typedef struct {
        TokenDBItem TMI_moniker;
        word        TMI_fileFlag;   /* 0 if token is in shared token DB file; 
                                     * Non-0 if it's in local file */
    } TokenMonikerInfo;

----------
#### TokenRangeFlags
    typedef WordFlags TokenRangeFlags;
        #define TRF_ONLY_GSTRING            0x8000
        #define TRF_ONLY_PASSED_MANUFID     0x4000
        #define TRF_UNUSED                  0x3fff

----------
#### TransError
    typedef enum {
         TE_NO_ERROR, /* No error */
         TE_ERROR, /* General error */
         TE_INVALID_FORMAT, /* Format is invalid */
         TE_IMPORT_NOT_SUPPORTED, /* Format is not supported for export */
         TE_EXPORT_NOT_SUPPORTED, /* Format is not supported for export */
         TE_IMPORT_ERROR, /* General error during import */
         TE_EXPORT_ERROR, /* General error during export */
         TE_FILE_ERROR, /* Generic file error */
         TE_DISK_FULL, /* The disk is full */
         TE_FILE_OPEN, /* Error in opening a file */
         TE_FILE_READ, /* Error in reading from a file */
         TE_FILE_WRITE, /* Error in writing to a file */
         TE_FILE_TOO_LARGE, /* File is too large to process */
         TE_OUT_OF_MEMORY, /* Insufficient memory for import/export /
         TE_METAFILE_CREATION_ERROR, /* Error in creating the metafile */
         TE_EXPORT_FILE_EMPTY, /* File to be exported is empty */
         TE_CUSTOM /* Custom error message */
    } TransError;

This enumerated type contains error values the impex library may wish to 
generate when translating.

----------
#### TransErrorInfo
    typedef struct {
         TransError     transError; 
         /* NOTE: customMsgHandle will be valid only if transError is TE_CUSTOM. */  
        word            customMsgHandle;
    } TransErrorInfo; 

----------
#### TransferBlockID
    typedef dword TransferBlockID;
        #define BlockIDFromFileAndBlock(f,b)    (((dword)(f) << 16) | (b))
        #define FileFromTransferBlockID(id)     ((VMFileHandle) ((id) >> 16))
        #define BlockFromTransferBlockID(id)    ((VMBlockHandle) (id))

----------
#### TransMatrix
    typedef struct {
        WWFixed         TM_e11;
        WWFixed         TM_e12;
        WWFixed         TM_e21;
        WWFixed         TM_e22;
        DWFixed         TM_e31;
        DWFixed         TM_e32;
    } TransMatrix;

The six variable elements of a coordinate transformation matrix.

----------
#### TravelOption
    typedef enum {
         TO_NULL,
         TO_SELF,
         TO_OBJ_BLOCK_OUTPUT,
         TO_PROCESS
    } TravelOption;
    /* VisClass defines one other travel option: */
    typedef enum {
         TO_VIS_PARENT=_FIRST_VisClass
    } VisTravelOption;
    /* GenClass defines some more travel options: */
    typedef enum /* word */ {
         TO_GEN_PARENT=_FIRST_GenClass,
         TO_FOCUS,
         TO_TARGET,
         TO_MODEL,
         TO_APP_FOCUS,
         TO_APP_TARGET,
         TO_APP_MODEL,
         TO_SYS_FOCUS,
         TO_SYS_TARGET,
         TO_SYS_MODEL
    } GenTravelOption;

This enumerated type can be used to specify the recipient of a message. Note 
that the values set up in the **TravelOption**, **VisTravelOption**, and 
**GenTravelOption** have been set up as discrete values.

----------
#### TRUE
    #define TRUE        -1  /* use as return value, not for comparisons */
    #define FALSE        0

----------
#### UIFunctionsActive
    typedef ByteFlags UIFunctionsActive;
        #define UIFA_SELECT             0x80
        #define UIFA_MOVE_COPY          0x40
        #define UIFA_FEATURES           0x20
        #define UIFA_CONSTRAIN          0x10
        #define UIFA_PREF_A             0x08
        #define UIFA_PREF_B             0x04
        #define UIFA_PREF_C             0x02
        #define UIFA_IN                 0x01
        #define UIFA_ADJUST             0x08
        #define UIFA_EXTEND             0x04
        #define UIFA_MOVE               0x08
        #define UIFA_COPY               0x04
        #define UIFA_POPUP              0x08
        #define UIFA_PAN                0x04

These flags describe the context of the user's input, providing some modal 
information. 

----------
#### UIInterfaceLevel
    typedef enum /* word */ {
        UIIL_NOVICE,
        UIIL_BEGINNING_INTERMEDIATE,
        UIIL_ADVANCED_INTERMEDIATE,
        UIIL_ADVANCED,
        UIIL_GURU
    } UIInterfaceLevel;

----------
#### UndoActionDataFlags
    typedef struct {
        dword       UADF_flags;
        word        UADF_extraflags;
    } UndoActionDataFlags;

----------
#### UndoActionDataPtr
    typedef struct {
        void        *UADP_ptr;
        word        UADP_size;
    } UndoActionDataPtr;

----------
#### UndoActionDataType
    typedef enum /* word */ {
        UADT_FLAGS,
        UADT_PTR,
        UADT_VM_CHAIN,
    } UndoActionDataType;

----------
#### UndoActionDataUnion
    typedef union {
        /* To find out the type of data stored in this
         * union, check the value of the UndoActionStruct's
         * UAS_dataType field. */
        UndoActionDataFlags             UADU_flags;
        UndoActionDataPtr               UADU_ptr;
        UndoActionDataVMChain           UADU_vmChain;
    } UndoActionDataUnion;
    #define NULL_UNDO_CONTEXT 0

----------
#### UndoActionDataVMChain
    typedef struct {
        /* This structure is filled in by the code for
         * MSG_META_UNDO. VMChains passed to 
         * MSG_GEN_PROCESS_UNDO_ADD_ACTION should lie in the undo
         * file (which can be obtained by sending 
         * MSG_GEN_PROCESS_UNDO_GET_FILE). */
        VMChain                 UADVMC_vmChain;
        VMFileHandle            UADVMC_file;
    } UndoActionDataVMChain;

----------
#### UndoActionStruct
    typedef struct {
        UndoActionDataType          UAS_dataType;
        UndoActionDataUnion         UAS_data;
        dword                       UAS_appType;
    } UndoActionStruct;

----------
#### UtilAsciiToHexError
    typedef enum /* word */ {
        UATH_NON_NUMERIC_DIGIT_IN_STRING,
        UATH_CONVERT_OVERFLOW,
    } UtilAsciiToHexError;

----------
#### UtilHexToAsciiFlags
    typedef WordFlags UtilHexToAsciiFlags;
        #define UHTAF_INCLUDE_LEADING_ZEROS     0x0002
        #define UHTAF_NULL_TERMINATE            0x0001

----------
#### VarDataCHandler
    typedef struct {
        word    VDCH_dataType;
        void    (*VDCH_handler) (MemHandle mh, ChunkHandle ch,
                                VarDataEntry *extraData,
                                word dataType, void *handlerData);
    } VarDataCHandler;

An entry in a class' vardata handler table. The first field is the data type, 
which acts as the entry's index in the handler table. The second field is a far 
pointer to the handler routine.

----------
#### VarDataEntry
    typedef struct {
        word    VDE_dataType;   /* vardata data type */
        word    VDE_entrySize;  /* size of extra data; this field only exists
                                 * if the type has extra data. */
    } VarDataEntry;
    #define VDE_extraData       sizeof(VarDataEntry);

Structure of a variable data entry. If the data type has no extra data, there 
will be no *VDE_entrySize* field. The extra data begins at offset 
*VDE_extraData*, defined above.

----------
#### VarDataFlags
    typedef WordFlags VarDataFlags;
        #define VDF_TYPE            0xfffc  /* 14-bit data type */
        #define VDF_EXTRA_DATA      0x0002  /* set if has extra data */
        #define VDF_SAVE_TO_STATE   0x0001  /* set if type saved to state */

This is a word record containing three fields. This word is stored in the 
vardata structure's VDE_dataType field (see VarDataEntry, above).

----------
#### VarDataKey
    typedef word VardataKey;

----------
#### VarObjRelocation
    typedef struct {
        VarDataFlags    VOR_type;       /* type and tag */
        word            VOR_offset;
    } VarObjRelocation;

----------
#### VChar
    typedef ByteEnum VChar;
        #define VC_NULL                 0x0 /* NULL */
        #define VC_CTRL_A               0x1 /* <ctrl>-A */
        #define VC_CTRL_B               0x2 /* <ctrl>-B */
        #define VC_CTRL_C               0x3 /* <ctrl>-C */
        #define VC_CTRL_D               0x4 /* <ctrl>-D */
        #define VC_CTRL_E               0x5 /* <ctrl>-E */
        #define VC_CTRL_F               0x6 /* <ctrl>-F */
        #define VC_CTRL_G               0x7 /* <ctrl>-G */
        #define VC_CTRL_H               0x8 /* <ctrl>-H */
        #define VC_CTRL_I               0x9 /* <ctrl>-I */
        #define VC_CTRL_J               0xa /* <ctrl>-J */
        #define VC_CTRL_K               0xb /* <ctrl>-K */
        #define VC_CTRL_L               0xc /* <ctrl>-L */
        #define VC_CTRL_M               0xd /* <ctrl>-M */
        #define VC_CTRL_N               0xe /* <ctrl>-N */
        #define VC_CTRL_O               0xf /* <ctrl>-O */
        #define VC_CTRL_P               0x10 /* <ctrl>-P */
        #define VC_CTRL_Q               0x11 /* <ctrl>-Q */
        #define VC_CTRL_R               0x12 /* <ctrl>-R */
        #define VC_CTRL_S               0x13 /* <ctrl>-S */
        #define VC_CTRL_T               0x14 /* <ctrl>-T */
        #define VC_CTRL_U               0x15 /* <ctrl>-U */
        #define VC_CTRL_V               0x16 /* <ctrl>-V */
        #define VC_CTRL_W               0x17 /* <ctrl>-W */
        #define VC_CTRL_X               0x18 /* <ctrl>-X */
        #define VC_CTRL_Y               0x19 /* <ctrl>-Y */
        #define VC_CTRL_Z               0x1a /* <ctrl>-Z */
        #define VC_ESCAPE               0x1b /* ESC */
        #define VC_BLANK                0x20 /* space */
        /*
         * Numeric keypad keys
         */
        #define VC_NUMPAD_ENTER             0xd /* only on PS/2 keyboards */
        #define VC_NUMPAD_DIV               `/' /* only on PS/2 keyboards */
        #define VC_NUMPAD_MULT              `*'
        #define VC_NUMPAD_PLUS              `+'
        #define VC_NUMPAD_MINUS             `-'
        #define VC_NUMPAD_PERIOD            `.'
        #define VC_NUMPAD_0                 `0'
        #define VC_NUMPAD_1                 `1'
        #define VC_NUMPAD_2                 `2'
        #define VC_NUMPAD_3                 `3'
        #define VC_NUMPAD_4                 `4'
        #define VC_NUMPAD_5                 `5'
        #define VC_NUMPAD_6                 `6'
        #define VC_NUMPAD_7                 `7'
        #define VC_NUMPAD_8                 `8'
        #define VC_NUMPAD_9                 `9'
        /*
         * Extended keyboard codes -- non-ASCII
         */
        #define VC_F1               0x80 /* Function keys */
        #define VC_F2               0x81
        #define VC_F3               0x82
        #define VC_F4               0x83
        #define VC_F5               0x84
        #define VC_F6               0x85
        #define VC_F7               0x86
        #define VC_F8               0x87
        #define VC_F9               0x88
        #define VC_F10              0x89
        #define VC_F11              0x8a /* only on PS/2 keyboards */
        #define VC_F12              0x8b /* only on PS/2 keyboards */
        #define VC_F13              0x8c /* non-standard key */
        #define VC_F14              0x8d /* non-standard key */
        #define VC_F15              0x8e /* non-standard key */
        #define VC_F16              0x8f /* non-standard key */
        #define VC_UP               0x90 /* Cursor keys */
        #define VC_DOWN             0x91
        #define VC_RIGHT            0x92
        #define VC_LEFT             0x93
        #define VC_HOME             0x94 /* Scroll commands */
        #define VC_END              0x95
        #define VC_PREVIOUS         0x96
        #define VC_NEXT             0x97
        #define VC_INS              0x98 /* INS */
        #define VC_DEL              0x9a /* DEL */
        #define VC_PRINTSCREEN      0x9b /* from <shift>-NUMPAD_MULT */
        #define VC_PAUSE            0x9c /* from <ctrl>-NUMLOCK */
        #define VC_BREAK            0x9e /* from <ctrl>- or <alt>-combo */
        #define VC_SYSTEMRESET      0x9f /* <ctrl>-<alt>-<del> combo */
        /*
        * Joystick control keys (0xa0 - 0xa9)
        */
        #define VC_JOYSTICK_0           0xa0    ; joystick 0 degrees
        #define VC_JOYSTICK_45          0xa1    ; joystick 45 degrees
        #define VC_JOYSTICK_90          0xa2    ; joystick 90 degrees
        #define VC_JOYSTICK_135         0xa3    ; joystick 135 degrees
        #define VC_JOYSTICK_180         0xa4    ; joystick 180 degrees
        #define VC_JOYSTICK_225         0xa5    ; joystick 225 degrees
        #define VC_JOYSTICK_270         0xa6    ; joystick 270 degrees
        #define VC_JOYSTICK_315         0xa7    ; joystick 315 degrees
        #define VC_FIRE_BUTTON_1        0xa8    ; fire button #1
        #define VC_FIRE_BUTTON_2        0xa9    ; fire button #2
        /*
         * Shift Keys           (0xe0 - 0xe7)
         */
        #define VC_LALT                 0xe0
        #define VC_RALT                 0xe1
        #define VC_LCTRL                0xe2
        #define VC_RCTRL                0xe3
        #define VC_LSHIFT               0xe4
        #define VC_RSHIFT               0xe5
        #define VC_SYSREQ               0xe6 /* Not on base PC keyboard */
        #define VC_ALT_GR               0xe7
        /*
         * Toggle state keys (0xe8 - 0xef)
         */
        #define VC_CAPSLOCK             0xe8
        #define VC_NUMLOCK              0xe9
        #define VC_SCROLLLOCK           0xea
        /*
         * Extended state keys (0xf0 - 0xf7)
         */
        #define VC_INVALID_KEY          0xff
        #define VC_BACKSPACE            VC_CTRL_H
        #define VC_TAB                  VC_CTRL_I
        #define VC_LF                   VC_CTRL_J
        #define VC_ENTER                VC_CTRL_M

----------
#### VisRulerType
    typedef ByteEnum VisRulerType;
        #define VRT_INCHES              0
        #define VRT_CENTIMETERS         1
        #define VRT_POINTS              2
        #define VRT_PICAS               3
        #define VRT_CUSTOM              CUSTOM_RULER_DEFINITION
        #define VRT_NONE                NO_RULERS
        #define VRT_DEFAULT             SYSTEM_DEFAULT

----------
#### VisTextVariableType
    typedef enum {
         VTVT_PAGE_NUMBER,
         VTVT_PAGE_NUMBER_IN_SECTION,
         VTVT_NUMBER_OF_PAGES,
         VTVT_NUMBER_OF_PAGES_IN_SECTION,
         VTVT_SECTION_NUMBER,
         VTVT_NUMBER_OF_SECTIONS,
         VTVT_CREATION_DATE_TIME,
         VTVT_MODIFICATION_DATE_TIME,
         VTVT_CURRENT_DATE_TIME,
         VTVT_STORED_DATE_TIME,
    } VisTextVariableType;

----------
#### VisTravelOption
The **VisClass** defines an enumerated value to be used in the place of a 
standard **TravelOption**. See the entry for **TravelOption** to see all possible 
values.

----------
#### VisUpdateMode
    typedef ByteEnum VisUpdateMode;
        #define VUM_MANUAL                          0
        #define VUM_NOW                             1
        #define VUM_DELAYED_VIA_UI_QUEUE            2
        #define VUM_DELAYED_VIA_APP_QUEUE           3

----------
#### VMAccessFlags
    typedef ByteFlags VMAccessFlags;
        #define VMAF_FORCE_READ_ONLY                            0x80
        #define VMAF_FORCE_READ_WRITE                           0x40
        #define VMAF_ALLOW_SHARED_MEMORY                        0x20
        #define VMAF_FORCE_DENY_WRITE                           0x10
        #define VMAF_DISALLOW_SHARED_MULTIPLE                   0x08
        #define VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION            0x04

----------
#### VMAttributes
    typedef ByteFlags VMAttributes;
        #define VMA_SYNC_UPDATE                     0x80
        #define VMA_BACKUP                          0x40
        #define VMA_OBJECT_RELOC                    0x20
        #define VMA_PRESERVE_HANDLES                0x10
        #define VMA_NOTIFY_DIRTY                    0x08
        #define VMA_NO_DISCARD_IF_IN_USE            0x04
        #define VMA_COMPACT_OBJ_BLOCK               0x02
        #define VMA_SINGLE_THREAD_ACCESS            0x01
        /*
         * Attributes that must be set for object blocks: */
        #define VMA_OBJECT_ATTRS    (VMA_OBJECT_RELOC | VMA_PRESERVE_HANDLES |
                                     VMA_NO_DISCARD_IF_IN_USE |
                                     VMA_SINGLE_THREAD_ACCESS)

----------
#### VMBlockHandle
    typedef word VMBlockHandle;

----------
#### VMChain
    typedef dword VMChain;

----------
#### VMChainLink
    typedef struct {
        VMBlockHandle           VMC_next;
    } VMChainLink;

----------
#### VMChainTree
    typedef struct {
        VMChainLink     VMCT_meta;
        word            VMCT_offset;
        word            VMCT_count;
    } VMChainTree;

----------
#### VMFileHandle
    typedef Handle VMFileHandle;

----------
#### VMInfoStruct
    typedef struct {
        MemHandle       mh;
        word            size;
        word            userId;
    } VMInfoStruct;

----------
#### VMOpenType
    typedef ByteEnum VMOpenType;
        #define VMO_OPEN                        0
        #define VMO_TEMP_FILE                   1
        #define VMO_CREATE                      2
        #define VMO_CREATE_ONLY                 3
        #define VMO_CREATE_TRUNCATE             4
        #define VMO_NATIVE_WITH_EXT_ATTRS       0x80

----------
#### VMOperation
    typedef enum {
        VMO_READ,
        VMO_INTERNAL,
        VMO_SAVE,
        VMO_SAVE_AS,
        VMO_REVERT,
        VMO_UPDATE,
        VMO_WRITE
    } VMOperation;

----------
#### VMRelocType
    typedef enum {
        VMRT_UNRELOCATE_BEFORE_WRITE,
        VMRT_RELOCATE_AFTER_READ,
        VMRT_RELOCATE_AFTER_WRITE,
        VMRT_RELOCATE_FROM_RESOURCE,
        VMRT_UNRELOCATE_FROM_RESOURCE,
    } VMRelocType;

----------
#### VMStartExclusiveReturnValue
    typedef enum {
         VMSERV_NO_CHANGES,
         VMSERV_CHANGES,
         VMSERV_TIMEOUT
    } VMStartExclusiveReturnValue;
**VMGrabExclusive()** returns a member of this enumerated type. It may 
have one of the following values:

VMSERV_NO_CHANGES  
No other thread has changed this file since the last time this 
thread had access to the file.

VMSERV_CHANGES  
The file may have been altered since the last time this thread 
had access to it; the thread should take appropriate actions 
(such as re-reading any cached data).

VMSERV_TIMEOUT  
This call to **VMGrabExclusive()** failed and timed out without 
getting access to the file.

----------
#### VolumeName
    typedef char VolumeName[VOLUME_BUFFER_SIZE];

----------
#### WBFixed
    typedef struct {
        byte    WBF_frac;
        word    WBF_int;
    } WBFixed;

----------
#### wchar
    typedef unsigned int wchar;

----------
#### WindowHandle
    typedef Handle WindowHandle;

----------
#### WinInfoType
    typedef enum /* word */ {
        WIT_PRIVATE_DATA =0,
        WIT_COLOR =2,
        WIT_INPUT_OBJ =4,
        WIT_EXPOSURE_OBJ =6,
        WIT_STRATEGY =8,
        WIT_FLAGS =10,
        WIT_LAYER_ID =12,
        WIT_PARENT_WIN =14,
        WIT_FIRST_CHILD_WIN =16,
        WIT_LAST_CHILD_WIN =18,
        WIT_PREV_SIBLING_WIN =20,
        WIT_NEXT_SIBLING_WIN =22,
        WIT_PRIORITY=24,
    } WinInfoType;

----------
#### WinInvalFlag
    typedef ByteEnum WinInvalFlag;
        #define WIF_INVALIDATE                  0
        #define WIF_DONT_INVALIDATE             1

----------
#### WinPassFlags
    typedef WordFlags WinPassFlags;
        #define WPF_CREATE_GSTATE               0x8000
        #define WPF_ROOT                        0x4000
        #define WPF_SAVE_UNDER                  0x2000
        #define WPF_INIT_EXCLUDED               0x1000
        #define WPF_PLACE_BEHIND                0x0800
        #define WPF_PLACE_LAYER_BEHIND          0x0400
        #define WPF_LAYER                       0x0200
        #define WPF_ABS                         0x0100
        #define WPF_PRIORITY                    0x00ff

----------
#### WinPriority
    typedef ByteEnum WinPriority;
        #define WIN_PRIO_POPUP                   4
        #define WIN_PRIO_MODAL                   6
        #define WIN_PRIO_ON_TOP                  8
        #define WIN_PRIO_COMMAND                10
        #define WIN_PRIO_STD                    12
        #define WIN_PRIO_ON_BOTTOM              14

----------
#### word
    typedef unsigned int word;

----------
#### WordAndAHalf
    typedef struct {
        word    WAAH_low;
        byte    WAAH_high;
    } WordAndAHalf;

----------
#### WordFlags
    typedef word WordFlags;

----------
#### WWFixed
    typedef struct {
        word    WWF_frac;
        word    WWF_int;
    } WWFixed;

----------
#### WWFixedAsDWord
    typedef dword WWFixedAsDWord

----------
#### XYOffset
    typedef struct {
        sword   XYO_x;
        sword   XYO_y;
    } XYOffset;

A graphics coordinate offset.

----------
#### XYSize
    typedef struct {
        word    XYS_width;
        word    XYS_height;
    } XYSize;

A graphics size, in two dimensions.

----------
#### XYValueAsDWord
    typedef dword XYValueAsDWord;

A graphics size, in two dimensions, expressed as a DWord.

[Data Structures F-K](rstrf_k.md) <-- [Table of Contents](../routines.md)