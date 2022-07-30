# 4 Data Structures
Global data structures and types are listed alphabetically below. Some data structures used by only a few routines or by only one or two classes are documented within those routines or classes.

## 4.1 Data Structures A-E

----------
#### AddUndoActionFlags
	typedef WordFlags AddUndoActionFlags;
	#define AUAF_NOTIFY_BEFORE_FREEING							0x8000
	#define AUAF_NOTIFY_IF_FREED_WITHOUT_BEING_PLAYED_BACK		0x4000

----------
#### AddUndoActionStruct
	typedef struct {
		UndoActionStruct 			AUAS_data;
		optr 						AUAS_output;
		AddUndoActionFlags 			AUAS_flags;
	} AddUndoActionStruct;

The "undo" structures work together to provide information vital to processes 
which will be working with undo events.

----------
#### AppAttachFlags
	typedef WordFlags AppAttachFlags;
		#define AAF_RESTORING_FROM_STATE		0x8000
		#define AAF_STATE_FILE_PASSED			0x4000
		#define AAF_DATA_FILE_PASSED			0x2000

These flags are passed to the process when the application is launching or 
being restored from a state file. The flags indicate whether the application is 
being launched from a state file, has a state file, and/or has a data file.

Note that if AAF_RESTORING_FROM_STATE is set, then 
AAF_STATE_FILE_PASSED will also be set.

----------
#### AppInstanceReference
	typedef struct {
		/* AIR_fileName:
		 * Application being launched. Pathname is relative to application 
		 * directory (which, of course, may be overriden with a direct path
		 * to the application). */
		PathName 				AIR_fileName;
		/* AIR_stateFile:
		 * State filename. File is assumed to be in standard directory for
		 * GEOS state files. If the first byte is "0", then there is no
		 * state file for this application. This structure is copied into the
		 * field as an aid in restarting applications, and if it comes across
		 * one with this byte as 0, it will not restart it. */
		FileLongName 			AIR_stateFile;
		/* AIR_diskHandle:
		 * Disk handle for app (passed in) IF 0, use System disk, if -1, use
		 * AIR_diskName. In the field, if this is a placeholder structure, this
		 * word is the handle of the application object we are waiting to detach. */
		DiskHandle 				AIR_diskHandle;
		/* AIR_savedDiskData:
		 * Start of data stored by DiskSave when instance is saved to state file. */
		byte 					AIR_savedDiskData[1];
	} AppInstanceReference;

----------
#### AppLaunchBlock
	typedef struct {
		/* ALB_appRef:
		 * Instance reference. Contains full pathname to application, as 
		 * referenced from app directory, plus the name of a state file. 
		 * Is enough info to launch application again, restored. (State file 
		 * need not be passed to GeodeLoad) */
		AppInstanceReference 	ALB_appRef;
		/* ALB_appMode:
		 * Application attach mode method. Should be one of the following:
		 * MSG_GEN_PROCESS_RESTORE_FROM_STATE:
		 *	 	State file must be passed; no data file should be passed.
		 * MSG_GEN_PROCESS_OPEN_APPLICATION:
		 *	 	State file normally should not be passed, although one could be to
		 *	 	accomplish ui templates. A data file may be passed into the 
		 *	 	application as well.
		 * MSG_GEN_PROCESS_OPEN_ENGINE:
		 *	 	State file normally should not be passed. The data file on which the 
		 *	 	engine will operate must be passed. If zero, the default data file 
		 *	 	should be used (enforced by app, not GenProcessClass).*/
		Message 				ALB_appMode;
		/* ALB_launchFlags:
		 * Miscellaneous flags to specify desired application launch type. */
		AppLaunchFlags 			ALB_launchFlags;
		/* ALB_diskHandle:
		 * Disk handle for data path. (Set as application's current path in 
		 * GenProcess' MSG_META_ATTACH handler.) */
		MemHandle 				ALB_diskHandle;
		/* ALB_path:
		 * Data path for application to use as initial path. (Usually this is 
		 * a directory of any data file passed.) (Set as application current
		 * path in GenProcess' MSG_META_ATTACH handler.)
		char 					ALB_path[PATH_BUFFER_SIZE];
		/* ALB_dataFile:
		 * Name of data file passed in to be opened (0 if none). Pathname is 
		 * relative to above path. */
		char 					ALB_dataFile[PATH_BUFFER_SIZE];
		/* ALB_genParent:
		 * Generic parent for new application (0 to put on default field). (Should 
		 * be passed NULL to MSG_GEN_FIELD_LAUNCH_APPLICATION).
		optr 					ALB_genParent;
		/* ALB_userLoadAckOutput, ALB_userLoadAckMessage:
		 * Together, these form an Action Descriptor which will be activated when 
		 * the application has been launched (used in conjunction with 
		 * ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE). (Set to NULL/0 if you don't 
		 * want to send anything). 
		 * The acknowledgement will come with three arguments: the GeodeHandle 
		 * (non-NULL if successful), a word value which will be zero if there was
		 * an error, and the word value set in ALB_userLoackAckID (below).*/
		optr 					ALB_userLoadAckOutput;
		Message 				ALB_userLoadAckMessage;
		/* ALB_userLoadAckID:
		 * ID sent out via above action descriptor, if any. */
		word 					ALB_userLoadAckID;
		/* ALB_extraData:
		 * Extra data to send to process (possibly a handle to 
		 * block containing arguments). */
		word 					ALB_extraData;
	} AppLaunchBlock;

This structure is used when an application is first starting up. It is an 
argument of various messages which will be intercepted by system classes. 
The first fields (*ALB_appRef*, *ALB_appMode*, *ALB_launchFlags*, and 
*ALB_uiLevel*) are preserved in the application's state file. The other 
information must be set correctly on launch.

----------
#### AppLaunchFlags
	typedef ByteFlags AppLaunchFlags;
		#define ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE		0x80
		#define ALF_OPEN_IN_BACK							0x40

----------
#### ApplicationStates
	typedef ByteFlags ApplicationStates;
		#define AS_QUITTING							0x80
		#define AS_DETACHING						0x40
		#define AS_FOCUSABLE 						0x20
		#define AS_MODELABLE 						0x10
		#define AS_NOT_USER_INTERACTABLE 			0x08
		#define AS_RECEIVED_APP_OBJECT_DETACH 		0x04
		#define AS_ATTACHED_TO_STATE_FILE 			0x02
		#define AS_ATTACHING 						0x01

----------
#### ArcCloseType
	typedef enum /* word */ {
		ACT_OPEN,
		ACT_CHORD,
		ACT_PIE
	} ArcCloseType;

This structure is used when filling arcs.

----------
#### AreaAttr
	typedef struct {
		byte 			AA_colorFlag;
		RGBValue 		AA_color;
		SysDrawMask 	AA_mask;
		ColorMapMode	AA_mapMode;
	} AreaAttr;

----------
#### ArgumentStackElement
	typedef struct {
		EvalStackArgumentType ASE_type;
		EvalStackArgumentData ASE_data;
	} ArgumentStackElement;

----------
#### BBFixed
	typedef struct {
		byte BBF_frac;
		byte BBF_int;
	} BBFixed;

This structure represents an 8.8 fixed point number.

----------
#### BBFixedAsWord
	typedef word BBFixedAsWord;

This structure represents an 8.8 fixed point number.

----------
#### Bitmap
	typedef struct {
		word	B_width;			/* In bitmap pixels */
		word	B_height;			/* In bitmap pixels */
		byte	B_compact;			/* A BMCompact value */
		byte	B_type;				/* A BMFormat | BMType value */
	} Bitmap;

This data structure provides some information about a simple graphics 
bitmap. It normally acts as the header for a set of bitmap data.

The bitmap data itself is organized into scan lines. If the bitmap has a mask 
(if the BMT_MASK bit is set in the *B_type* field), the first information for the 
scan line will be its mask information. There will be one bit of mask 
information for each pixel in the scan line (i.e. a number of bits equal to the 
bitmap width). The actual bitmap data for the scan line starts at the next 
byte boundary. For each pixel there will be a number of bits of color data, said 
number depending on the **BMFormat** value in the *B_type* field. The data for 
the next scan line will begin at the next byte boundary.

Thus, a 7x7 bitmap depicting an inverse "x" might appear:

	(Bitmap)	{7, 7, BMC_UNCOMPACTED, BMF_MONO };
	(byte)[]	{0x82, 		/* 10000010 */
				 0x44, 		/* 01000100 */
				 0x28, 		/* 00101000 */
				 0x10, 		/* 00010000 */
				 0x28, 		/* 00101000 */
				 0x44, 		/* 01000100 */
				 0x82 }; 	/* 10000010 */

A 3x3 color "-" shape with a a "+" shaped mask might appear:

	(Bitmap)	{ 3, 3, BMC_UNCOMPACTED, 
				 (BMF_4BIT | BMT_MASK)};
	(byte) []	{/* scan line 1: */
				 0x40, 			/* mask: 010 */
				 0, 0			/* data: 000 */

				 /* scan line 2: */
				 0xE0, 			/* mask: 111 */
				 0x43, 0x20, 	/* data: 432 */ 

				 /* scan line 3: */
				 0x40, 			/* mask: 010 */
				 0, 0 };		/* data: 000 */

If standard BMC_PACKBITS compression is used, then the mask (if any) and 
color data for the bitmap is compressed using the Macintosh PackBits 
standard. Under this system, to uncompress the data for a scan line, follow 
the loop:

1. Read a byte. 

2. If the byte read in step (1) is between -1 and -127, read the next byte and 
copy it into the target buffer from +2 to +128 times. 

3. If the byte read in step (1) is between +1 and +127, read the next 1 to 127 
bytes and copy them into the target buffer.

4. If the byte read in step (1) is -128, ignore it.

5. You're ready to read in the next batch of data; go back to step (1).

Thus a 16x4 color "=" with a matching mask would appear:

	(Bitmap) 	{15, 3, BMC_PACKBITS, BMF_4BIT | BMT_MASK } ;
	(byte) []		{/* scan line 1: */
						/* mask: 2 repetitions of 0xff */
					 0xff, 0xff, 
						/* data: 16 repetitions of 0x14 */
					 0xf0, 0x14, 
					/* scan line 2: */
						/* mask: 2 repetitions of 0x00 */
						/* data: 16 repetitions of 0x00 */
						/* total: 18 repetitions of 0x00 */
					 0xee, 0x00, 
					/* scan line 3: */
						/* mask: 2 repetitions of 0x00 */
						/* data: 16 repetitions of 0x00 */
						/* total: 18 repetitions of 0x00 */
					 0xee, 0x00, 
					/* scan line 4: */
						/* mask: 2 repetitions of 0xff */
					 0xff, 0xff, 
						/* data: 16 repetitions of 0x14 */
					 0xf0, 0x14};

**See Also:** CBitmap.

----------
#### BitmapMode
	typedef WordFlags BitmapMode;
		#define BM_EDIT_MASK					0x0002
		#define BM_CLUSTERED_DITHER				0x0001

----------
#### BLTMode
	typedef enum /* word */ {
		BLTM_COPY,
		BLTM_MOVE,
		BLTM_CLEAR
	} BLTMode;

----------
#### BMCompact
	typedef ByteEnum ByteCompact;
		#define BMC_UNCOMPACTED				0
		#define BMC_PACKBITS				1
		#define BMC_USER_DEFINED			0x80

This data structure is used to specify what sort of compaction is used to store 
a graphics bitmap.

----------
#### BMDestroy
	typedef ByteEnum BMDestroy;
		#define BMD_KILL_DATA				0
		#define BMD_LEAVE_DATA				1

----------
#### BMFormat
	typedef ByteEnum BMFormat
		#define BMF_MONO  0
		#define BMF_4BIT  1
		#define BMF_8BIT  2
		#define BMF_24BIT 3
		#define BMF_4CMYK 4
This enumerated type determines a graphics bitmap's depth.

----------
#### BMType
	typedef ByteFlags BMType;
		#define BMT_PALETTE				0x40
		#define BMT_HUGE 				0x20
		#define BMT_MASK 				0x10
		#define BMT_COMPLEX 			0x08
		#define BMT_FORMAT 				0x07
This structure is used to store various facts about a graphics bitmap.

----------
#### Boolean
	typedef word Boolean;
Booleans represent true/false values. If the Boolean is *false*, it will evaluate 
to zero; otherwise, it will be non-zero.

----------
#### Button
	typedef ByteEnum Button;
		#define BUTTON_0				0
		#define BUTTON_1				1
		#define BUTTON_2				2
		#define BUTTON_3				3

----------
#### ButtonInfo
	typedef ByteFlags ButtonInfo;
		#define BI_PRESS				0x80
		#define BI_DOUBLE_PRESS 		0x40
		#define BI_B3_DOWN 				0x20
		#define BI_B2_DOWN 				0x10
		#define BI_B1_DOWN 				0x08
		#define BI_B0_DOWN 				0x04
		#define BI_BUTTON 				0x03
This structure contains the state of a mouse's buttons.

----------
####@ byte
	typedef unsigned char byte;

----------
#### ByteEnum
	typedef byte ByteEnum;

----------
#### ByteFlags
	typedef byte ByteFlags;

----------
#### CallbackType
	typedef ByteEnum CallbackType;
		#define CT_FUNCTION_TO_TOKEN		0
		#define CT_NAME_TO_TOKEN 			1
		#define CT_CHECK_NAME_EXISTS 		2
		#define CT_CHECK_NAME_SPACE 		3
		#define CT_EVAL_FUNCTION 			4
		#define CT_LOCK_NAME 				5
		#define CT_UNLOCK 					6
		#define CT_FORMAT_FUNCTION 			7
		#define CT_FORMAT_NAME 				8
		#define CT_CREATE_CELL				9
		#define CT_EMPTY_CELL 				10
		#define CT_NAME_TO_CELL 			11
		#define CT_FUNCTION_TO_CELL 		12
		#define CT_DEREF_CELL 				13
		#define CT_SPECIAL_FUNCTION 		14

----------
#### CBitmap
	typedef struct {
		Bitmap 	CB_simple;
		word 	CB_startScan;
		word 	CB_numScans;
		word 	CB_devInfo;
		word 	CB_data;
		word 	CB_palette;
		word 	CB_xres;
		word	CB_yres;
	} CBitmap;
The CBitmap structure contains the information for a "complex" bitmap. Use 
the CBitmap structure to hold bitmaps which need to keep track of resolution 
information, a palette, or a mask.

----------
#### CellFunctionParameterFlags
	typedef ByteFlags CellFunctionParameterFlags;
		#define CFPF_DIRTY			0x80 /* apps may read or change this. */
		#define CFPF_NO_FREE_COUNT	0x07

----------
#### CellFunctionParameters
	typedef struct {
		CellFunctionParameterFlags	CFP_flags;
		VMFileHandle				CFP_file;		/* File containing cells */
		VMBlockHandle				CFP_rowBlocks[N_ROW_BLOCKS];
	} CellFunctionParameters;

This structure is used to pass specifics about a cell file to the cell library 
routines. Some of the data in the **CellFunctionParameters** structure is 
opaque to the application; others may be examined or changed by the 
application. The **CellFunctionParameters** structure contains the 
following fields:

*CFP_flags* - The cell library uses this byte for miscellaneous bookkeeping. 
When you create the structure, initialize this field to zero. 
There is only one flag which you should check or change; that 
is the flag *CFPF_dirty*. The cell library routines set this bit 
whenever they change the **CellFunctionParameters** 
structure, thus indicating that the structure ought to be 
resaved. After you save it, you may clear this bit.

*CFP_file* - This field must contain the VM file handle of the cell file. This 
field must be set each time you open the file.

*CFP_rowBlocks* - This field is an array of VM block handles, one for every existing 
or potential row block. The length of this array is 
N_ROW_BLOCKS (defined in **cell.h**). When you create a cell file, 
initialize all of these handles to zero; do not access or change 
this field thereafter.

**Include:** cell.h

**Warnings:** The cell library expects the **CellFunctionParameters** structure to remain 
motionless for the duration of a call. Therefore, if you allocate it as a DB item 
in the cell file, you must not have the structure be an ungrouped item.

----------
#### CellRange
	typedef struct {
		CellReference			CR_start;
		CellReference			CR_end;
	} CellRange;

----------
#### CellReference
	typedef struct {
		CellRowColumn			CR_row;
		CellRowColumn			CR_column;
	} CellReference;

----------
#### CellRowColumn
	typedef WordFlags CellRowColumn;
		#define CRC_ABSOLUTE				0x8000
		#define CRC_VALUE				0x7fff

----------
#### CharacterSet
	typedef ByteEnum CharacterSet;
		#define CS_BSW					0
		#define CS_CONTROL 				0xff
		#define CS_UI_FUNCS 			0xfe
		#define VC_ISANSI 				CS_BSW
		#define VC_ISCTRL 				CS_CONTROL
		#define VC_ISUI 				CS_UI_FUNCS

----------
#### CharFlags
	typedef ByteFlags CharFlags;
		#define CF_STATE_KEY				0x80
		#define CF_EXTENDED 				0x10
		#define CF_TEMP_ACCENT 				0x08
		#define CF_FIRST_PRESS 				0x04
		#define CF_REPEAT_PRESS 			0x02
		#define CF_RELEASE 					0x01

----------
#### Chars
	typedef ByteEnum Chars;
		#define C_NULL				0x0 /* NULL */
		#define C_CTRL_A			0x1 /* <ctrl>-A */
		#define C_CTRL_B			0x2 /* <ctrl>-B */
		#define C_CTRL_C			0x3 /* <ctrl>-C */
		#define C_CTRL_D			0x4 /* <ctrl>-D */
		#define C_CTRL_E			0x5 /* <ctrl>-E */
		#define C_CTRL_F			0x6 /* <ctrl>-F */
		#define C_CTRL_G			0x7 /* <ctrl>-G */
		#define C_CTRL_H			0x8 /* <ctrl>-H */
		#define C_TAB				0x9 /* TAB */
		#define C_LINEFEED			0xa /* LINE FEED */
		#define C_CTRL_K			0xb /* <ctrl>-K */
		#define C_CTRL_L			0xc /* <ctrl>-L */
		#define C_ENTER				0xd /* ENTER or CR */
		#define C_SHIFT_OUT			0xe /* <ctrl>-N */
		#define C_SHIFT_IN			0xf /* <ctrl>-O */
		#define C_CTRL_P			0x10 /* <ctrl>-P */
		#define C_CTRL_Q			0x11 /* <ctrl>-Q */
		#define C_CTRL_R			0x12 /* <ctrl>-R */
		#define C_CTRL_S			0x13 /* <ctrl>-S */
		#define C_CTRL_T			0x14 /* <ctrl>-T */
		#define C_CTRL_U			0x15 /* <ctrl>-U */
		#define C_CTRL_V			0x16 /* <ctrl>-V */
		#define C_CTRL_W			0x17 /* <ctrl>-W */
		#define C_CTRL_X			0x18 /* <ctrl>-X */
		#define C_CTRL_Y			0x19 /* <ctrl>-Y */
		#define C_CTRL_Z			0x1a /* <ctrl>-Z */
		#define C_ESCAPE			0x1b /* ESC */
		#define C_NULL_WIDTH		0x19 /* null width character */
		#define C_GRAPHIC			0x1a /* Graphic in text. */
		#define C_THINSPACE			0x1b /* 1/4 width space */
		#define C_ENSPACE			0x1c /* En-space, fixed width */
		#define C_EMSPACE			0x1d /* Em-space, fixed width. */
		#define C_NONBRKHYPHEN		0x1e /* Non breaking hyphen. */
		#define C_OPTHYPHEN			0x1f /* Optional hyphen, only drawn at eol */
		#define C_SPACE				` '
		#define C_EXCLAMATION		`!'
		#define C_QUOTE				`"'
		#define C_NUMBER_SIGN		`#'
		#define C_DOLLAR_SIGN		`$'
		#define C_PERCENT			`%'
		#define C_AMPERSAND			`&'
		#define C_SNG_QUOTE			0x27
		#define C_LEFT_PAREN		`('
		#define C_RIGHT_PAREN		`)'
		#define C_ASTERISK			`*'
		#define C_PLUS				`+'
		#define C_COMMA				`,'
		#define C_MINUS				`-'
		#define C_PERIOD			 '.'
		#define C_SLASH				`/'
		#define C_ZERO				`0'
		#define C_ONE				`1'
		#define C_TWO				`2'
		#define C_THREE 			`3'
		#define C_FOUR 				`4'
		#define C_FIVE 				`5'
		#define C_SIX 				`6'
		#define C_SEVEN 			`7'
		#define C_EIGHT 			`8'
		#define C_NINE 				`9'
		#define C_COLON 			`:'
		#define C_SEMICOLON 		`;'
		#define C_LESS_THAN 		`<'
		#define C_EQUAL 			`='
		#define C_GREATER_THAN 		`>'
		#define C_QUESTION_MARK 	`?'
		#define C_AT_SIGN			0x40
		#define C_CAP_A 			`A'
		#define C_CAP_B 			`B'
		#define C_CAP_C 			`C'
		#define C_CAP_D 			`D'
		#define C_CAP_E 			`E'
		#define C_CAP_F 			`F'		
		#define C_CAP_G 			`G'
		#define C_CAP_H 			`H'
		#define C_CAP_I 			`I'
		#define C_CAP_J 			`J'
		#define C_CAP_K 			`K'
		#define C_CAP_L 			`L'
		#define C_CAP_M 			`M'
		#define C_CAP_N 			`N'
		#define C_CAP_O 			`O'
		#define C_CAP_P 			`P'
		#define C_CAP_Q 			`Q'
		#define C_CAP_R 			`R'
		#define C_CAP_S 			`S'
		#define C_CAP_T 			`T'
		#define C_CAP_U 			`U'
		#define C_CAP_V 			`V'
		#define C_CAP_W 			`W'
		#define C_CAP_X 			`X'
		#define C_CAP_Y 			`Y'
		#define C_CAP_Z 			`Z'
		#define C_LEFT_BRACKET		`['
		#define C_BACKSLASH			0x5c
		#define C_RIGHT_BRACKET		`]'
		#define C_ASCII_CIRCUMFLEX	`^'
		#define C_UNDERSCORE		`_'
		#define C_BACKQUOTE			``'
		#define C_SMALL_A			`a'
		#define C_SMALL_B			`b'
		#define C_SMALL_C			`c'
		#define C_SMALL_D 			`d'
		#define C_SMALL_E 			`e'
		#define C_SMALL_F 			`f'
		#define C_SMALL_G 			`g'
		#define C_SMALL_H 			`h'
		#define C_SMALL_I 			`i'
		#define C_SMALL_J 			`j'
		#define C_SMALL_K 			`k'
		#define C_SMALL_L 			`l'
		#define C_SMALL_M 			`m'
		#define C_SMALL_N 			`n'
		#define C_SMALL_O 			`o'
		#define C_SMALL_P 			`p'
		#define C_SMALL_Q 			`q'
		#define C_SMALL_R 			`r'
		#define C_SMALL_S 			`s'
		#define C_SMALL_T 			`t'
		#define C_SMALL_U 			`u'
		#define C_SMALL_V 			`v'
		#define C_SMALL_W 			`w'
		#define C_SMALL_X 			`x'
		#define C_SMALL_Y 			`y'
		#define C_SMALL_Z 			`z'
		#define C_LEFT_BRACE 		`{'
		#define C_VERTICAL_BAR 		`|'
		#define C_RIGHT_BRACE 		`}'
		#define C_ASCII_TILDE 		`~'
		#define C_DELETE			0x7f
		#define C_UA_DIERESIS		0x80
		#define C_UA_RING			0x81
		#define C_UC_CEDILLA		0x82
		#define C_UE_ACUTE			0x83
		#define C_UN_TILDE			0x84
		#define C_UO_DIERESIS		0x85
		#define C_UU_DIERESIS		0x86
		#define C_LA_ACUTE			0x87
		#define C_LA_GRAVE			0x88
		#define C_LA_CIRCUMFLEX		0x89
		#define C_LA_DIERESIS		0x8a
		#define C_LA_TILDE			0x8b
		#define C_LA_RING			0x8c
		#define C_LC_CEDILLA		0x8d
		#define C_LE_ACUTE			0x8e
		#define C_LE_GRAVE			0x8f
		#define C_LE_CIRCUMFLEX		0x90
		#define C_LE_DIERESIS		0x91
		#define C_LI_ACUTE			0x92
		#define C_LI_GRAVE			0x93
		#define C_LI_CIRCUMFLEX		0x94
		#define C_LI_DIERESIS		0x95
		#define C_LN_TILDE			0x96
		#define C_LO_ACUTE			0x97
		#define C_LO_GRAVE			0x98
		#define C_LO_CIRCUMFLEX		0x99
		#define C_LO_DIERESIS		0x9a
		#define C_LO_TILDE			0x9b
		#define C_LU_ACUTE			0x9c
		#define C_LU_GRAVE			0x9d
		#define C_LU_CIRCUMFLEX		0x9e
		#define C_LU_DIERESIS		0x9f
		#define C_DAGGER			0xa0
		#define C_DEGREE			0xa1
		#define C_CENT				0xa2
		#define C_STERLING			0xa3
		#define C_SECTION			0xa4
		#define C_BULLET			0xa5
		#define C_PARAGRAPH			0xa6
		#define C_GERMANDBLS		0xa7
		#define C_REGISTERED		0xa8
		#define C_COPYRIGHT			0xa9
		#define C_TRADEMARK			0xaa
		#define C_ACUTE				0xab
		#define C_DIERESIS			0xac
		#define C_NOTEQUAL			0xad
		#define C_U_AE				0xae
		#define C_UO_SLASH			0xaf
		#define C_INFINITY			0xb0
		#define C_PLUSMINUS			0xb1
		#define C_LESSEQUAL			0xb2
		#define C_GREATEREQUAL		0xb3
		#define C_YEN				0xb4
		#define C_L_MU				0xb5
		#define C_L_DELTA			0xb6
		#define C_U_SIGMA			0xb7
		#define C_U_PI				0xb8
		#define C_L_PI				0xb9
		#define C_INTEGRAL			0xba
		#define C_ORDFEMININE		0xbb
		#define C_ORDMASCULINE		0xbc
		#define C_U_OMEGA			0xbd
		#define C_L_AE				0xbe
		#define C_LO_SLASH			0xbf
		#define C_QUESTIONDOWN		0xc0
		#define C_EXCLAMDOWN		0xc1
		#define C_LOGICAL_NOT		0xc2
		#define C_ROOT				0xc3
		#define C_FLORIN			0xc4
		#define C_APPROX_EQUAL		0xc5
		#define C_U_DELTA			0xc6
		#define C_GUILLEDBLLEFT		0xc7
		#define C_GUILLEDBLRIGHT	0xc8
		#define C_ELLIPSIS			0xc9
		#define C_NONBRKSPACE		0xca
		#define C_UA_GRAVE			0xcb
		#define C_UA_TILDE			0xcc
		#define C_UO_TILDE			0xcd
		#define C_U_OE				0xce
		#define C_L_OE				0xcf
		#define C_ENDASH			0xd0
		#define C_EMDASH			0xd1
		#define C_QUOTEDBLLEFT		0xd2
		#define C_QUOTEDBLRIGHT		0xd3
		#define C_QUOTESNGLEFT		0xd4
		#define C_QUOTESNGRIGHT		0xd5
		#define C_DIVISION			0xd6
		#define C_DIAMONDBULLET		0xd7
		#define C_LY_DIERESIS		0xd8
		#define C_UY_DIERESIS		0xd9
		#define C_FRACTION			0xda
		#define C_CURRENCY			0xdb
		#define C_GUILSNGLEFT		0xdc
		#define C_GUILSNGRIGHT		0xdd
		#define C_LY_ACUTE			0xde
		#define C_UY_ACUTE			0xdf
		#define C_DBLDAGGER			0xe0
		#define C_CNTR_DOT			0xe1
		#define C_SNGQUOTELOW		0xe2
		#define C_DBLQUOTELOW		0xe3
		#define C_PERTHOUSAND		0xe4
		#define C_UA_CIRCUMFLEX		0xe5
		#define C_UE_CIRCUMFLEX		0xe6
		#define C_UA_ACUTE			0xe7
		#define C_UE_DIERESIS		0xe8
		#define C_UE_GRAVE			0xe9
		#define C_UI_ACUTE			0xea
		#define C_UI_CIRCUMFLEX		0xeb
		#define C_UI_DIERESIS		0xec
		#define C_UI_GRAVE			0xed
		#define C_UO_ACUTE			0xee
		#define C_UO_CIRCUMFLEX		0xef
		#define C_LOGO				0xf0
		#define C_UO_GRAVE			0xf1
		#define C_UU_ACUTE			0xf2
		#define C_UU_CIRCUMFLEX		0xf3
		#define C_UU_GRAVE			0xf4
		#define C_LI_DOTLESS		0xf5
		#define C_CIRCUMFLEX		0xf6
		#define C_TILDE				0xf7
		#define C_MACRON			0xf8
		#define C_BREVE				0xf9
		#define C_DOTACCENT			0xfa
		#define C_RING				0xfb
		#define C_CEDILLA			0xfc
		#define C_HUNGARUMLAT		0xfd
		#define C_OGONEK			0xfe
		#define C_CARON				0xff
		/*
		 * common shortcuts for low 32 codes
		 */
		#define C_NUL				C_NULL
		#define C_STX				C_CTRL_B
		#define C_ETX				C_CTRL_C
		#define C_BEL				C_CTRL_G
		#define C_BS				C_CTRL_H
		#define C_HT				C_CTRL_I
		#define C_VT				C_CTRL_K
		#define C_FF				C_CTRL_L
		#define C_SO				C_CTRL_N
		#define C_SI				C_CTRL_O
		#define C_DC1				C_CTRL_Q
		#define C_DC2				C_CTRL_R
		#define C_DC3				C_CTRL_S
		#define C_DC4				C_CTRL_T
		#define C_CAN				C_CTRL_X
		#define C_EM				C_CTRL_Y
		#define C_ESC				C_ESCAPE
		/*
		 * Some alternative names
		 */
		#define C_CR				C_ENTER
		#define C_CTRL_M			C_ENTER
		#define C_CTRL_I			C_TAB
		#define C_CTRL_J			C_LINEFEED
		#define C_LF				C_LINEFEED
		#define C_CTRL_N			C_SHIFT_OUT
		#define C_CTRL_O			C_SHIFT_IN
		#define C_FS				C_ENSPACE
		#define C_FIELD_SEP			C_FS
		#define C_HYPHEN			C_MINUS
		#define C_GRAVE				C_BACKQUOTE
		#define C_PARTIAL_DIFF		C_L_DELTA
		#define C_SUM				C_U_SIGMA
		#define C_PRODUCT			C_U_PI
		#define C_RADICAL			C_ROOT
		#define C_LOZENGE			C_DIAMONDBULLET
Text characters may be represented by the standard C type char or by the 
GEOS type Chars. The difference shows up in debugging. If printing the value 
of a string as char, then the debugger will output ASCII text. If the string is 
treated as Chars, then the debugger will print out the constant names.

**Include:** char.h

----------
#### ChunkArrayHeader
	typedef struct {
		word	CAH_count;			/* # of elements in chunk array */
		word	CAH_elementSize;	/* Size of each element (in bytes) */
		word	CAH_curOffset;		/* For internal use only */
		word	CAH_offset;			/* Offset from start of chunk to first element */
	} ChunkArrayHeader;
Every chunk array begins with a **ChunkArrayHeader**. This structure 
contains information about the chunk array. Applications should never 
change the contents of the **ChunkArrayHeader**; only the chunk array 
routines should do this. However, applications can examine the header if 
they wish.

**Contents:** There are four word-length fields in the **ChunkArrayHeader**:

*CAH_count* - This word contains the number of elements in the chunk array.

*CAH_elementSize* - This word contains the size of each element (in bytes). If the 
elements are variable-sized, *CAH_elementSize* will be zero.

*CAH_curOffset* - This word is used by **ChunkArrayEnum()** for bookkeeping.

*CAH_offset* - This is the offset from the start of the chunk to the first element 
in the array.

----------
#### ChunkHandle
	typedef word ChunkHandle;
Chunk handles are offsets into a local memory heap. To find the current 
location of a chunk in an LMem heap, combine the segment address of the 
heap with the chunk handle. From this location you can read the current 
offset of the chunk itself.

**See Also:** optr, LMemDeref()

----------
#### ChunkMapList
	typedef struct {
		word	CML_source;
		word	CML_dest;
	} ChunkMapList;

----------
#### ClassFlags
	typedef ByteFlags ClassFlags;
		#define CLASSF_HAS_DEFAULT						0x80
		#define CLASSF_MASTER_CLASS 						0x40
		#define CLASSF_VARIANT_CLASS 						0x20
		#define CLASSF_DISCARD_ON_SAVE 						0x10
		#define CLASSF_NEVER_SAVED						0x08
		#define CLASSF_HAS_RELOC 						0x04
		#define CLASSF_C_HANDLERS 						0x02
This record is stored in the **ClassStruct** structure's *Class_flags* field. These 
flags are internal and may not be set or retrieved directly. See the entry on 
**@class** for more information about these flags.

----------
#### ClassStruct
	typedef	struct	_ClassStruct {
		struct _ClassStruct *Class_superClass;	/* superclass pointer */
		word		Class_masterOffset;			/* offset to master offset in chunk */
		word 		Class_methodCount;			/* number of methods in this class */
		word 		Class_instanceSize;			/* size of entire master group */
		word 		Class_vdRelocTable;			/* offset to vardata relocation table */
		word 		Class_relocTable;			/* offset to relocation table */
		ClassFlags 	Class_flags;				/* a record of ClassFlags */
		byte 		Class_masterMessages;		/* internal flags for optimization */
	} ClassStruct;

This is the structure that defines a class. It is internal and used only very 
rarely by anything other than the kernel and the UI.

----------
#### ClipboardItemFlags
	typedef WordFlags ClipboardItemFlags;
		#define CIF_QUICK				0x4000
		#define TIF_NORMAL				0x0000

----------
#### ClipboardItemFormat
	typedef enum /* word */ {
		CIF_TEXT,
		CIF_GRAPHICS_STRING,
		CIF_FILES,
		CIF_SPREADSHEET,
		CIF_INK,
		CIF_GROBJ,
		CIF_GEODEX,
		CIF_BITMAP,
		CIF_SOUND_SYNTH,
		CIF_SOUND_SAMPLE
	} ClipboardItemFormat;

----------
#### ClipboardItemFormatID
	typedef dword ClipboardItemFormatID;

----------
#### ClipboardItemFormatInfo
	typedef struct {
		ClipboardItemFormatID		CIFI_format;
		word						CIFI_extra1;
		word						CIFI_extra2;
		VMChain						CIFI_vmChain;
		GeodeToken					CIFI_renderer;
	} ClipboardItemFormatInfo;

----------
#### ClipboardItemHeader
	typedef struct {
		optr						CIH_owner;
		ClipboardItemFlags			CIH_flags;
		ClipboardItemNameBuffer		CIH_name;
		word						CIH_formatCount;
		optr						CIH_sourceID;
		FormatArray					CIH_formats;
		dword						CIH_reserved;
	} ClipboardItemHeader;

----------
#### ClipboardItemNameBuffer
	typedef char ClipboardItemNameBuffer[CLIPBOARD_ITEM_NAME_LENGTH+1];

----------
#### ClipboardQueryArgs
See **ClipboardQueryItem()**.

----------
#### ClipboardQuickNotifyFlags
	typedef WordFlags ClipboardQuickNotifyFlags;
		#define CQNF_ERROR						0x8000
		#define CQNF_SOURCE_EQUAL_DEST 			0x4000
		#define CQNF_MOVE 						0x2000
		#define CQNF_COPY 						0x1000
		#define CQNF_NO_OPERATION 				0x0800
		#define CQNF_UNUSED 					0x04ff
These flags give information about the success or failure of a quick transfer 
operation.

----------
#### ClipboardQuickTransferFeedback
	typedef enum {
		CQTF_SET_DEFAULT,
		CQTF_CLEAR_DEFAULT,
		CQTF_MOVE,
		CQTF_COPY,
		CQTF_CLEAR
	} ClipboardQuickTransferFeedback;

----------
#### ClipboardQuickTransferFlags
	typedef WordFlags ClipboardQuickTransferFlags;
		#define CQTF_IN_PROGRESS			0x8000
		#define CQTF_COPY_ONLY				0x4000
		#define CQTF_USE_REGION				0x2000
		#define CQTF_NOTIFICATION			0x1000

----------
#### ClipboardQuickTransferRegionInfo
	typedef struct {
		word	CQTRI_paramAX;
		word	CQTRI_paramBX;
		word	CQTRI_paramCX;
		word	CQTRI_paramDX;
		Point	CQTRI_regionPos;
		dword	CQTRI_strategy;
		dword	CQTRI_region;
	} ClipboardQuickTransferRegionInfo;

----------
#### ClipboardRequestArgs
See entry for **ClipboardRequestItemFormat()**.

----------
#### CMYKTransfer
	typedef struct {
		byte	CMYKT_cyan[256];
		byte	CMYKT_magenta[256];
		byte	CMYKT_yellow[256];
		byte	CMYKT_black[256];
	} CMYKTransfer;

----------
#### Color
	typedef ByteEnum Color;
		#define C_BLACK					0
		#define C_BLUE 					1
		#define C_GREEN 				2
		#define C_CYAN 					3
		#define C_RED 					4
		#define C_VIOLET 				5
		#define C_BROWN 				6
		#define C_LIGHT_GRAY 			7
		#define C_DARK_GRAY 			8
		#define C_LIGHT_BLUE 			9
		#define C_LIGHT_GREEN 			10
		#define C_LIGHT_CYAN 			11
		#define C_LIGHT_RED 			12
		#define C_LIGHT_VIOLET 			13
		#define C_YELLOW 				14
		#define C_WHITE 				15

		#define C_GRAY_0 				0x10
		#define C_GRAY_7 				0x11
		#define C_GRAY_13				0x12
		#define C_GRAY_20				0x13
		#define C_GRAY_27 				0x14
		#define C_GRAY_33 				0x15
		#define C_GRAY_40 				0x16
		#define C_GRAY_47 				0x17
		#define C_GRAY_53 				0x18
		#define C_GRAY_60 				0x19
		#define C_GRAY_68 				0x1a
		#define C_GRAY_73 				0x1b
		#define C_GRAY_80 				0x1c
		#define C_GRAY_88 				0x1d
		#define C_GRAY_93 				0x1e
		#define C_GRAY_100 				0x1f

		#define C_UNUSED_0 				0x20
		#define C_UNUSED_1 				0x21
		#define C_UNUSED_2 				0x22
		#define C_UNUSED_3 				0x23
		#define C_UNUSED_4 				0x24
		#define C_UNUSED_5 				0x25
		#define C_UNUSED_6 				0x26
		#define C_UNUSED_7 				0x27

		#define C_R0_G0_B0 				0x28
		#define C_R0_G0_B1 				0x29
		#define C_R0_G0_B2 				0x2a
		#define C_R0_G0_B3 				0x2b
		#define C_R0_G0_B4 				0x2c
		#define C_R0_G0_B5 				0x2d
		#define C_R0_G1_B0 				0x2e
		#define C_R0_G1_B1 				0x2f
		#define C_R0_G1_B2 				0x30
		#define C_R0_G1_B3 				0x31
		#define C_R0_G1_B4 				0x32
		#define C_R0_G1_B5 				0x33
		#define C_R0_G2_B0 				0x34
		#define C_R0_G2_B1 				0x35
		#define C_R0_G2_B2 				0x36
		#define C_R0_G2_B3 				0x37
		#define C_R0_G2_B4 				0x38
		#define C_R0_G2_B5 				0x39

		#define C_R0_G3_B0 				0x3a
		#define C_R0_G3_B1 				0x3b
		#define C_R0_G3_B2 				0x3c
		#define C_R0_G3_B3 				0x3d
		#define C_R0_G3_B4 				0x3e
		#define C_R0_G3_B5 				0x3f
		#define C_R0_G4_B0 				0x40
		#define C_R0_G4_B1 				0x41
		#define C_R0_G4_B2 				0x42
		#define C_R0_G4_B3 				0x43
		#define C_R0_G4_B4 				0x44
		#define C_R0_G4_B5 				0x45
		#define C_R0_G5_B0 				0x46
		#define C_R0_G5_B1 				0x47
		#define C_R0_G5_B2 				0x48
		#define C_R0_G5_B3 				0x49
		#define C_R0_G5_B4 				0x4a
		#define C_R0_G5_B5 				0x4b

		#define C_R1_G0_B0 				0x4c
		#define C_R1_G0_B1 				0x4d
		#define C_R1_G0_B2 				0x4e
		#define C_R1_G0_B3 				0x4f
		#define C_R1_G0_B4 				0x50
		#define C_R1_G0_B5 				0x51
		#define C_R1_G1_B0 				0x52
		#define C_R1_G1_B1 				0x53
		#define C_R1_G1_B2 				0x54
		#define C_R1_G1_B3 				0x55
		#define C_R1_G1_B4 				0x56
		#define C_R1_G1_B5 				0x57
		#define C_R1_G2_B0 				0x58
		#define C_R1_G2_B1 				0x59
		#define C_R1_G2_B2 				0x5a
		#define C_R1_G2_B3 				0x5b
		#define C_R1_G2_B4 				0x5c
		#define C_R1_G2_B5 				0x5d

		#define C_R1_G3_B0 				0x5e
		#define C_R1_G3_B1 				0x5f
		#define C_R1_G3_B2 				0x60
		#define C_R1_G3_B3 				0x61
		#define C_R1_G3_B4 				0x62
		#define C_R1_G3_B5 				0x63
		#define C_R1_G4_B0 				0x64
		#define C_R1_G4_B1 				0x65
		#define C_R1_G4_B2 				0x66
		#define C_R1_G4_B3 				0x67
		#define C_R1_G4_B4 				0x68
		#define C_R1_G4_B5 				0x69
		#define C_R1_G5_B0 				0x6a
		#define C_R1_G5_B1 				0x6b
		#define C_R1_G5_B2 				0x6c
		#define C_R1_G5_B3 				0x6d
		#define C_R1_G5_B4 				0x6e
		#define C_R1_G5_B5 				0x6f

		#define C_R2_G0_B0 				0x70
		#define C_R2_G0_B1 				0x71
		#define C_R2_G0_B2 				0x72
		#define C_R2_G0_B3 				0x73
		#define C_R2_G0_B4 				0x74
		#define C_R2_G0_B5 				0x75
		#define C_R2_G1_B0 				0x76
		#define C_R2_G1_B1 				0x77
		#define C_R2_G1_B2 				0x78
		#define C_R2_G1_B3 				0x79
		#define C_R2_G1_B4 				0x7a
		#define C_R2_G1_B5 				0x7b
		#define C_R2_G2_B0 				0x7c
		#define C_R2_G2_B1 				0x7d
		#define C_R2_G2_B2 				0x7e
		#define C_R2_G2_B3 				0x7f
		#define C_R2_G2_B4 				0x80
		#define C_R2_G2_B5 				0x81

		#define C_R2_G3_B0 				0x82
		#define C_R2_G3_B1 				0x83
		#define C_R2_G3_B2 				0x84
		#define C_R2_G3_B3 				0x85
		#define C_R2_G3_B4 				0x86
		#define C_R2_G3_B5 				0x87
		#define C_R2_G4_B0 				0x88
		#define C_R2_G4_B1 				0x89
		#define C_R2_G4_B2 				0x8a
		#define C_R2_G4_B3 				0x8b
		#define C_R2_G4_B4 				0x8c
		#define C_R2_G4_B5 				0x8d
		#define C_R2_G5_B0 				0x8e
		#define C_R2_G5_B1 				0x8f
		#define C_R2_G5_B2 				0x90
		#define C_R2_G5_B3 				0x91
		#define C_R2_G5_B4 				0x92
		#define C_R2_G5_B5 				0x93

		#define C_R3_G0_B0 				0x94
		#define C_R3_G0_B1 				0x95
		#define C_R3_G0_B2 				0x96
		#define C_R3_G0_B3 				0x97
		#define C_R3_G0_B4 				0x98
		#define C_R3_G0_B5 				0x99
		#define C_R3_G1_B0 				0x9a
		#define C_R3_G1_B1 				0x9b
		#define C_R3_G1_B2 				0x9c
		#define C_R3_G1_B3 				0x9d
		#define C_R3_G1_B4 				0x9e
		#define C_R3_G1_B5 				0x9f
		#define C_R3_G2_B0 				0xa0
		#define C_R3_G2_B1 				0xa1
		#define C_R3_G2_B2 				0xa2
		#define C_R3_G2_B3 				0xa3
		#define C_R3_G2_B4 				0xa4
		#define C_R3_G2_B5 				0xa5

		#define C_R3_G3_B0 				0xa6
		#define C_R3_G3_B1 				0xa7
		#define C_R3_G3_B2 				0xa8
		#define C_R3_G3_B3 				0xa9
		#define C_R3_G3_B4 				0xaa
		#define C_R3_G3_B5 				0xab
		#define C_R3_G4_B0 				0xac
		#define C_R3_G4_B1 				0xad
		#define C_R3_G4_B2 				0xae
		#define C_R3_G4_B3 				0xaf
		#define C_R3_G4_B4 				0xb0
		#define C_R3_G4_B5 				0xb1
		#define C_R3_G5_B0 				0xb2
		#define C_R3_G5_B1 				0xb3
		#define C_R3_G5_B2 				0xb4
		#define C_R3_G5_B3 				0xb5
		#define C_R3_G5_B4 				0xb6
		#define C_R3_G5_B5 				0xb7

		#define C_R4_G0_B0 				0xb8
		#define C_R4_G0_B1 				0xb9
		#define C_R4_G0_B2 				0xba
		#define C_R4_G0_B3 				0xbb
		#define C_R4_G0_B4 				0xbc
		#define C_R4_G0_B5 				0xbd
		#define C_R4_G1_B0 				0xbe
		#define C_R4_G1_B1 				0xbf
		#define C_R4_G1_B2 				0xc0
		#define C_R4_G1_B3 				0xc1
		#define C_R4_G1_B4 				0xc2
		#define C_R4_G1_B5 				0xc3
		#define C_R4_G2_B0 				0xc4
		#define C_R4_G2_B1 				0xc5
		#define C_R4_G2_B2 				0xc6
		#define C_R4_G2_B3 				0xc7
		#define C_R4_G2_B4 				0xc8
		#define C_R4_G2_B5 				0xc9

		#define C_R4_G3_B0 				0xca
		#define C_R4_G3_B1 				0xcb
		#define C_R4_G3_B2 				0xcc
		#define C_R4_G3_B3 				0xcd
		#define C_R4_G3_B4 				0xce
		#define C_R4_G3_B5 				0xcf
		#define C_R4_G4_B0 				0xd0
		#define C_R4_G4_B1 				0xd1
		#define C_R4_G4_B2 				0xd2
		#define C_R4_G4_B3 				0xd3
		#define C_R4_G4_B4 				0xd4
		#define C_R4_G4_B5 				0xd5
		#define C_R4_G5_B0 				0xd6
		#define C_R4_G5_B1 				0xd7
		#define C_R4_G5_B2 				0xd8
		#define C_R4_G5_B3 				0xd9
		#define C_R4_G5_B4 				0xda
		#define C_R4_G5_B5 				0xdb

		#define C_R5_G0_B0 				0xdc
		#define C_R5_G0_B1 				0xdd
		#define C_R5_G0_B2 				0xde
		#define C_R5_G0_B3 				0xdf
		#define C_R5_G0_B4 				0xe0
		#define C_R5_G0_B5 				0xe1
		#define C_R5_G1_B0 				0xe2
		#define C_R5_G1_B1 				0xe3
		#define C_R5_G1_B2 				0xe4
		#define C_R5_G1_B3 				0xe5
		#define C_R5_G1_B4 				0xe6
		#define C_R5_G1_B5 				0xe7
		#define C_R5_G2_B0 				0xe8
		#define C_R5_G2_B1 				0xe9
		#define C_R5_G2_B2 				0xea
		#define C_R5_G2_B3 				0xeb
		#define C_R5_G2_B4 				0xec
		#define C_R5_G2_B5 				0xed
		#define C_R5_G3_B0 				0xee
		#define C_R5_G3_B1 				0xef
		#define C_R5_G3_B2 				0xf0
		#define C_R5_G3_B3 				0xf1
		#define C_R5_G3_B4 				0xf2
		#define C_R5_G3_B5 				0xf3
		#define C_R5_G4_B0 				0xf4
		#define C_R5_G4_B1 				0xf5
		#define C_R5_G4_B2 				0xf6
		#define C_R5_G4_B3 				0xf7
		#define C_R5_G4_B4 				0xf8
		#define C_R5_G4_B5 				0xf9
		#define C_R5_G5_B0 				0xfa
		#define C_R5_G5_B1 				0xfb
		#define C_R5_G5_B2 				0xfc
		#define C_R5_G5_B3 				0xfd
		#define C_R5_G5_B4 				0xfe
		#define C_R5_G5_B5 				0xff

		#define C_LIGHT_GREY			C_LIGHT_GRAY
		#define C_DARK_GREY				C_DARK_GRAY
		#define C_BW_GREY				0x84

**Include:** color.h

----------
#### ColorFlag
	typedef ByteEnum ColorFlag;
		#define CF_INDEX		0
		#define CF_GRAY			1
		#define CF_SAME			2
		#define CF_RGB			0x80
Several color-related commands accept colors in a variety of formats. The 
**ColorFlag** enumerated type is used to specify how the color is being 
described. The **ColorFlag** is normally used as part of a **ColorQuad**. See 
**ColorQuad** for information about how to interpret color specifications using 
**ColorFlags**.

----------
#### ColorMapMode
	typedef ByteFlags ColorMapMode;
		#define CMM_ON_BLACK 0x04	/* Set this bit if you're drawing on black */
		#define CMM_MAP_TYPE 0x01	/* Either CMT_CLOSEST or CMT_DITHER) */
		#define LAST_MAP_MODE	(CMM_MAP_TYPE | CMM_ON_BLACK)
This structure defines how the system will try to simulate colors not in the 
palette. If the map type is CMT_CLOSEST, the closest available color will be 
used. If the map type is CMT_DITHER, the system will mix together two or 
more close colors in a dithered pattern. If you will be drawing against a black 
background, you may wish to set the CMM_ON_BLACK flag.

----------
#### ColorQuad
	typedef struct {
		byte 			CQ_redOrIndex;
		ColorFlag		CQ_info;
		byte 			CQ_green;
		byte 			CQ_blue;
	} ColorQuad;
This structure represents a color. The *CQ_info* field determines how the color 
is being described. 

If the info field is CF_INDEX, then the color is being specified by its index, its 
place in the window's palette. The index is in the *CQ_redOrIndex* field; the 
the *CQ_green* and *CQ_blue* fields are meaningless for this specification.

If the info field is CF_RGB, then the color is specified by RGB (red, green, and 
blue) components. *CQ_redOrIndex* contains the color's red component, a 
number ranging from 0 to 255. The *CQ_green* and *CQ_blue* fields contain the 
color's green and blue components, respectively.

If the info field is CF_GRAY, then the color is being expressed as a grey scale. 
This is basically an optimized way of describing RGB colors where the red, 
green, and blue components are equal. The *CQ_redOrIndex* field contains the 
brightess, a number between 0 and 255. The *CQ_green* and *CQ_blue* fields are 
ignored.

When defining hatch patterns, it is possible have a CF_SAME info field. This 
means that the hatch lines should use the "same" color when drawing. That 
is, when hatching text, the text color will be used; when filling an area, the 
area color will be used. The *CQ_redOrIndex*, *CQ_green*, and *CQ_blue* fields are 
all ignored.

----------
#### ColorQuadAsDWord
	typedef dword ColorQuadAsDWord;

----------
#### ColorTransfer
	typedef struct {
		RGBDelta				CT_data[125]; 
	} ColorTransfer;
This structure consists of a 5x5x5 matrix of **RGBDelta** structures. This and 
be used to specify what sorts of adjustments to make to the color when 
displaying to a specific device. For instance, some color printers will wipe out 
certain colors if they try to use the amounts of ink suggested by the raw RGB 
values. The **ColorTransfer** structure thus serves to hold an array of "fudge 
factors" to tell the printer to use more or less ink than the raw RGB values 
would suggest.

----------
#### ColorTransferData
	typedef union {
		MonoTransfer		CTD_mono;
		RGBTransfer			CTD_rgb;
		CMYKTransfer		CTD_cmyk;
	} ColorTransferData;

----------
#### ColorTransferType
	typedef ByteEnum ColorTransferType;
		#define CTT_MONO				 0
		#define CTT_RGB 				 1
		#define CTT_CMYK 				 2

----------
#### CommonParameters
	typedef struct {
		word	CP_row;
		word	CP_column;
		word	CP_maxRow;
		word	CP_maxColumn;
		void	* CP_callback;
		void	* CP_cellParams; /* ptr to an instance of SpreadsheetClass */
	} CommonParameters;

----------
#### CompChildFlags
	typedef WordFlags CompChildFlags;
		#define CCF_MARK_DIRTY		0x8000
		#define CCF_REFERENCE		0x7fff
		#define 	CCO_FIRST			0x0000
		#define		CCO_LAST			0x7FFF
		#define CCF_REFERENCE_OFFSET 0
A record used when adding, moving, or removing children in an object tree. 
The record has one flag and a value, as follows:

CCF_MARK_DIRTY  
A flag indicating whether the object should be marked dirty at 
the end of the operation.

CCF_REFERENCE  
A child number; when adding or moving a child, this is the child 
number after which the new object should be inserted. It can be 
any number less than 32768, or it can be either of the two 
constants shown above (CCO_FIRST or CCO_LAST).

----------
#### CountryType
	typedef enum /* word */ {
		CT_UNITED_STATES=1,
		CT_CANADA,
		CT_UNITED_KINGDOM,
		CT_GERMANY,
		CT_FRANCE,
		CT_SPAIN,
		CT_ITALY,
		CT_DENMARK,
		CT_NETHERLANDS,
	} CountryType;

----------
#### CRangeEnumParams
	typedef struct {
		RangeEnumParams			CREP_params;
		void					*CREP_locals;
	    PCB(RANGE_ENUM_CALLBACK_RETURN_TYPE, CREP_callback,
					(RangeEnumCallbackParams));
	} CRangeEnumParams;

The *CREP_callback* routine should be declared _pascal.

----------
#### CurrencyFormatFlags
	typedef ByteFlags CurrencyFormatFlags;
		#define CFF_LEADING_ZERO					0x20
		#define CFF_SPACE_AROUND_SYMBOL 			0x10
		#define CFF_USE_NEGATIVE_SIGN 				0x08
		#define CFF_SYMBOL_BEFORE_NUMBER 			0x04
		#define CFF_NEGATIVE_SIGN_BEFORE_NUMBER 	0x02
		#define CFF_NEGATIVE_SIGN_BEFORE_SYMBOL 	0x01

----------
#### CustomDialogBoxFlags
	typedef WordFlags CustomDialogBoxFlags;
		#define CDBF_SYSTEM_MODAL				0x8000
		#define CDBF_DIALOG_TYPE				0x6000
		#define CDBF_INTERACTION_TYPE			0x1e00

----------
#### CustomDialogType
	typedef ByteEnum CustomDialogType;
		#define CDT_QUESTION					0
		#define CDT_WARNING						1
		#define CDT_NOTIFICATION 				2
		#define CDT_ERROR 						3
		#define CDBF_DIALOG_TYPE_OFFSET			13
		#define CDBF_INTERACTION_TYPE_OFFSET	9

----------
#### DACPlayFlags
	typedef ByteFlags DACPlayFlags;
	#define DACPF_CATENATE 0x80

----------
#### DACReferenceByte
	typedef enum {
		 DACRB_NO_REFERENCE_BYTE,
		 DACRB_WITH_REFERENCE_BYTE
	} DACReferenceByte;

----------
#### DACSampleFormat
	typedef enum {
		DACSF_8_BIT_PCM,
		DACSF_2_TO_1_ADPCM,
		DACSF_3_TO_1_ADPCM,
		DACSF_4_TO_1_ADPCM
	} DACSampleFormat;
This structure specifies what sort of sampling should be used when recording 
or playing a sampled sound.

----------
#### DashPairArray
**See:** LineStyle

----------
#### DateTimeFormat
	typedef enum /* word */ {
		DTF_LONG,
		DTF_LONG_CONDENSED,
		DTF_LONG_NO_WEEKDAY,
		DTF_LONG_NO_WEEKDAY_CONDENSED,
		DTF_SHORT,
		DTF_ZERO_PADDED_SHORT,
		DTF_MD_LONG,
		DTF_MD_LONG_NO_WEEKDAY,
		DTF_MD_SHORT,
		DTF_MY_LONG,
		DTF_MY_SHORT,
		DTF_MONTH,
		DTF_WEEKDAY,
		DTF_HMS,
		DTF_HM,
		DTF_H,
		DTF_MS,
		DTF_HMS_24HOUR,
		DTF_HM_24HOUR,
	} DateTimeFormat;

----------
#### DayOfTheWeek
	typedef enum {
		DOTW_SUNDAY,
		DOTW_MONDAY,
		DOTW_TUESAY,
		DOTW_WEDNESDAY,
		DOTW_THURSDAY,
		DOTW_FRIDAY,
		DOTW_SATURDAY
	} DayOfTheWeek;
This enumerated type is used in the **TimerDateAndTime** structure.

----------
#### DBGroup
	typedef word DBGroup;
This is the handle of a DB group. It is the VM handle of a DB group block. DB 
group handles do not change when a file is copied, or when it is closed and 
reopened.

----------
#### DBGroupAndItem
	typedef	dword DBGroupAndItem;
This is a dword which contains the group and item handles of a database 
item. The high word is the item's Group handle; the low word is the item's 
Item handle. 

Macros are provided to create and parse the **DBGroupAndItem**:

**DBCombineGroupAndItem()**  
Creates a **DBGroupAndItem** from given group and item 
handles.

	DBCombineGroupAndItem(group, item);

**DBExtractGroupFromGroupAndItem()**  
Extracts the **DBGroup** from a given **DBGroupAndItem**.

	DBExtractGroupFromGroupAndItem(groupAndItem);

**DBExtractItemFromGroupAndItem()**  
Extracts the **DBItem** from a given **DBGroupAndItem**.

	DBExtractItemFromGroupAndItem(groupAndItem);

**Include:** geos.h

----------
#### DBItem
	typedef word DBItem;
This is the handle of a DB item. The **DBItem** and **DBGroup** together 
uniquely identify a DB item in a specified file.

----------
#### DBReturn
	typedef struct {
		word	DBR_group;
		word	DBR_item;
		word	unused1;
		word	unused2;
	} DBReturn;

----------
#### DefaultPrintSizes
	typedef struct {
		word	paperWidth;
		word	paperHeight;
		word	documentWidth;
		word	documentHeight;
	} DefaultPrintSizes;

----------
#### DevicePresent
	typedef enum /* word */ {
		DP_NOT_PRESENT=0xffff,
		DP_CANT_TELL=0,
		DP_PRESENT=1,
		DP_INVALID_DEVICE=0xfffe
	} DevicePresent;

----------
#### DirPathInfo
	typedef word DirPathInfo;
		#define DPI_EXISTS_LOCALLY					0x8000
		#define DPI_ENTRY_NUMBER_IN_PATH			0x7f00
		#define DPI_ENTRY_NUMBER_IN_PATH_OFFSET		8
		#define DPI_STD_PATH						0x00ff
		#define DPI_STD_PATH_OFFSET					0

----------
#### DiskCopyCallback
	typedef enum /* word */ {
		CALLBACK_GET_SOURCE_DISK,
		CALLBACK_REPORT_NUM_SWAPS,
		CALLBACK_GET_DEST_DISK,
		CALLBACK_VERIFY_DEST_DESTRUCTION,
		CALLBACK_REPORT_FORMAT_PCT,
		CALLBACK_REPORT_COPY_PCT
	} DiskCopyCallback;

----------
#### DiskCopyError
	typedef enum /* word */ {
		ERR_DISKCOPY_INSUFFICIENT_MEM=0xd0,
		ERR_CANT_COPY_FIXED_DISKS,
		ERR_CANT_READ_FROM_SOURCE,
		ERR_CANT_WRITE_TO_DEST,
		ERR_INCOMPATIBLE_FORMATS,
		ERR_OPERATION_CANCELLED,
		ERR_CANT_FORMAT_DEST,
	} DiskCopyError;

----------
#### DiskFindResult
	typedef enum /* word */ {
		DFR_UNIQUE,
		DFR_NOT_UNIQUE,
		DFR_NOT_FOUND,
	} DiskFindResult;

----------
#### DiskHandle
	typedef Handle DiskHandle;

----------
#### DiskInfoStruct
	typedef struct {
		word		DIS_blockSize;
		sdword		DIS_freeSpace;
		sdword		DIS_totalSpace;
		VolumeName		DIS_name;
	} DiskInfoStruct;

----------
#### DiskRestoreError
	typedef enum /* word */ {
		DRE_DISK_IN_DRIVE,
		DRE_DRIVE_NO_LONGER_EXISTS,
		DRE_REMOVABLE_DRIVE_DOESNT_HOLD_DISK,
		DRE_USER_CANCELED_RESTORE,
		DRE_COULDNT_CREATE_NEW_DISK_HANDLE,
		DRE_REMOVABLE_DRIVE_IS_BUSY,
	} DiskRestoreError;

----------
#### DisplayAspectRatio
	typedef ByteEnum DisplayAspectRatio;
		#define DAR_NORMAL				0
		#define DAR_SQUISHED			1
		#define DAR_VERY_SQUISHED		2

----------
#### DisplayClass
	typedef ByteEnum DisplayClass;
		#define DC_TEXT					0
		#define DC_GRAY_1 				1
		#define DC_GRAY_2 				2
		#define DC_GRAY_4 				3
		#define DC_GRAY_8 				4
		#define DC_COLOR_2 				5
		#define DC_COLOR_4 				6
		#define DC_CF_RGB 				7

----------
#### DisplaySize
	typedef ByteEnum DisplaySize;
		#define DS_TINY				0
		#define DS_STANDARD			1
		#define DS_LARGE			2
		#define DS_HUGE				3

----------
#### DisplayType
	typedef ByteFlags DisplayType;
		#define DT_DISP_SIZE					0xc0
		#define DT_DISP_ASPECT_RATIO			0x30
		#define DT_DISP_CLASS					0x0f

----------
#### DistanceUnit
	typedef ByteEnum DistanceUnit;
		#define DU_POINTS							0
		#define DU_INCHES 							1
		#define DU_CENTIMETERS						2
		#define DU_MILLIMETERS 						3
		#define DU_PICAS 							4
		#define DU_EUR_POINTS 						5
		#define DU_CICEROS							6
		#define DU_POINTS_OR_MILLIMETERS 			7
		#define DU_INCHES_OR_CENTIMETERS 			8
		#define LOCAL_DISTANCE_BUFFER_SIZE 			32

----------
#### DocQuitStatus
	typedef enum /* word */ {
		DQS_OK,
		DQS_CANCEL,
		DQS_DELAYED,
		DQS_SAVE_ERROR
	} DocQuitStatus;

----------
#### DocumentSize
	typedef struct {
		int		leftMargin;
		int		topMargin;
		int		width;
		int		height;
	} DocumentSize;

----------
#### DosCodePage
	typedef enum /* word */ {
		CODE_PAGE_US=437,
		CODE_PAGE_MULTILINGUAL=850,
		CODE_PAGE_MULTILINGUAL_EURO=858,
		CODE_PAGE_PORTUGUESE=860,
		CODE_PAGE_CANADIAN_FRENCH=863,
		CODE_PAGE_NORDIC=865
	} DosCodePage;

----------
#### DosDotFileName
	typedef char DosDotFileName[DOS_DOT_DOS_FILE_NAME_SIZE];

----------
#### DosExecFlags
	typedef ByteFlags DosExecFlags;
		#define DEF_PROMPT				0x80	/* prompt user to return to GEOS */
		#define DEF_FORCED_SHUTDOWN		0x40	/* force shutdown; no abort */
		#define DEF_INTERACTIVE			0x20	/* program is interactive shell */
Flags used with **DosExec()**. **DosExec()** executes a DOS program based on 
these flags.

----------
#### DosFileInfoStruct
	typedef struct {
		byte DFIS_attributes;
		dword DFIS_modTimeDate;
		dword DFIS_fileSize;
		char DFIS_name[DOS_DOT_FILE_NAME_LENGTH_ZT];
		word DFIS_pathInfo;
	} DosFileInfoStruct;

----------
#### DosNoDotFileName
	typedef char DosNoDotFileName[DOS_NO_DOT_DOS_FILE_NAME_SIZE];

----------
#### DrawMask
	typedef byte DrawMask[8];
The graphics system uses this structure for defining custom draw masks.

----------
####  DriveType
	typedef ByteEnum DriveType;
		#define DRIVE_5_25				0
		#define DRIVE_3_5				1
		#define DRIVE_FIXED				2
		#define DRIVE_RAM				3
		#define DRIVE_CD_ROM			4
		#define DRIVE_8					5
		#define DRIVE_UNKNOWN			0xf
	} DriveType;

Several routines (in particular, **DriveGetStatus()**) provide information 
about drives used by the computer running GEOS. These routines return a 
member of the **DriveTypes** enumerated type. Note that while the type is 
byte-length, all of the values are guaranteed to fit in four bits; thus, routines 
like **DriveGetStatus()** can return a **DriveTypes** value in the low four bits 
and other flags in the high four bits of a single byte.

----------
#### DriverAttrs
	typedef WordFlags DriverAttrs;
		#define DA_FILE_SYSTEM					0x8000
		#define DA_CHARACTER					0x4000
		#define DA_HAS_EXTENDED_INFO			0x2000
This record contains flags that indicate a given driver's attributes. This 
record is stored in the driver's **DriverInfoStruct** structure.

----------
#### DriverExtendedInfoStruct
	typedef struct {
		DriverInfoStruct	DEIS_common;	/* The base driver info structure */
		MemHandle			DEIS_resource;	/* Handle of driver's DriverExtendedInfo
											 * table. */
	} DriverExtendedInfoStruct;

This structure is used by Preferences to locate the names of devices 
supported by a particular driver.

----------
#### DriverExtendedInfoTable
	typedef struct {
		LMemBlockHeader		DEIT_common;
		word				DEIT_numDevices;
		ChunkHandle			DEIT_ChunkHandle;
		word				DEIT_infoTable;
	} DriverExtendedInfoTable;

----------
#### DriverInfoStruct
	typedef struct {
		 void (*DIS_strategy)();				/* Pointer to strategy routine */
		 DriverAttrs	DIS_driverAttributes;	/* driver's attribute flags */
		 DriverType		DIS_driverType;			/* driver's type */
	} DriverInfoStruct;
This structure defines the characteristics of a particular driver. In general, 
applications will not need to access this structure unless they use a driver 
directly.

----------
#### DriverType
	typedef enum {
		DRIVER_TYPE_VIDEO = 1,			/* Video drivers */
		DRIVER_TYPE_INPUT,				/* Input (keyboard, mouse) drivers */
		DRIVER_TYPE_MASS_STORAGE,		/* Disk/Drive drivers */
		DRIVER_TYPE_STREAM,				/* Stream and port drivers */
		DRIVER_TYPE_FONT,				/* Font drivers */
		DRIVER_TYPE_OUTPUT,				/* Output (not video and printer) drivers */
		DRIVER_TYPE_LOCALIZATION,		/* Localization drivers */
		DRIVER_TYPE_FILE_SYSTEM,		/* File system drivers */
		DRIVER_TYPE_PRINTER,			/* Printer drivers */
		DRIVER_TYPE_SWAP,				/* Swap drivers */
		DRIVER_TYPE_POWER_MANAGEMENT,	/* Power management drivers */
		DRIVER_TYPE_TASK_SWITCH,		/* Task switch drivers */
		DRIVER_TYPE_NETWORK				/* Network file system drivers */
	} DriverType;
This enumerated type has one value for each type of driver in the system. It 
is used primarily with **GeodeUseDriver()** and its associated routines. Each 
driver stores its type in its **DriverInfoStruct** structure.

----------
#### DWFixed
	typedef struct {
		word	WWF_frac;
		dword	WWF_int;
	} DWFixed;

----------
#### dword
	typedef unsigned long dword;

----------
#### DWordFlags
	typedef dword DWordFlags;

----------
#### ElementArrayHeader
	typedef struct {
		ChunkArrayHeader	EAH_meta;		/* chunk array header structure */
		word				EAH_freePtr;	/* First free element */
	} ElementArrayHeader;
Every element array must begin with an **ElementArrayHeader**. Since 
element arrays are special kinds of chunk arrays, the 
**ElementArrayHeader** must itself begin with a **ChunkArrayHeader**. The 
structure contains one additional field, *EAH_freePtr*. This is used to keep 
track of the freed elements in the element array. Applications should not 
examine or change this field.

----------
#### EndOfSongFlags
	typedef ByteFlags EndOfSongFlags;
			#define EOSF_UNLOCK 0x0080		/* unlock block at EOS ? */
			#define EOSF_DESTROY 0x0040		/* destroy block at EOS ? */

			#define UNLOCK_ON_EOS EOSF_UNLOCK
			#define DESTROY_ON_EOS EOSF_DESTROY

----------
#### EntryPointRelocation
	typedef struct {
		char	EPR_geodeName[GEODE_NAME_SIZE];
		word	EPR_entryNumber;
	} EntryPointRelocation;

----------
#### EnvelopeOrientation
	typedef ByteEnum EnvelopeOrientation;
		#define EO_PORTAIT_LEFT				0x00
		#define EO_PORTAIT_RIGHT			0x01
		#define EO_LANDSCAPE_UP				0x02
		#define EO_LANDSCAPE_DOWN			0x03

----------

#### EnvelopePath
	typedef ByteEnum EnvelopePath;
		#define EP_LEFT				0x00
		#define EP_CENTER			0x01
		#define EP_RIGHT			0x02

----------
#### Errors
		#define ERROR_UNSUPPORTED_FUNCTION					1
		#define ERROR_FILE_NOT_FOUND 						2
		#define ERROR_PATH_NOT_FOUND 						3
		#define ERROR_TOO_MANY_OPEN_FILES 					4
		#define ERROR_ACCESS_DENIED 						5
		#define ERROR_INSUFFICIENT_MEMORY 					8
		#define ERROR_INVALID_VOLUME 						15
		#define ERROR_IS_CURRENT_DIRECTORY 					16
		#define ERROR_DIFFERENT_DEVICE 						17
		#define ERROR_NO_MORE_FILES 						18
		#define ERROR_WRITE_PROTECTED 						19
		#define ERROR_UNKNOWN_VOLUME 						20
		#define ERROR_DRIVE_NOT_READY 						21
		#define ERROR_CRC_ERROR 							23
		#define ERROR_SEEK_ERROR 							25
		#define ERROR_UNKNOWN_MEDIA 						26
		#define ERROR_SECTOR_NOT_FOUND 						27
		#define ERROR_WRITE_FAULT 							29
		#define ERROR_READ_FAULT 							30
		#define ERROR_GENERAL_FAILURE 						31
		#define ERROR_SHARING_VIOLATION 					32
		#define ERROR_ALREADY_LOCKED 						33
		#define ERROR_SHARING_OVERFLOW 						36
		#define ERROR_SHORT_READ_WRITE 						128
		#define ERROR_INVALID_LONGNAME 						129
		#define ERROR_FILE_EXISTS 							130
		#define ERROR_DOS_EXEC_IN_PROGRESS 					131
		#define ERROR_FILE_IN_USE 							132
		#define ERROR_ARGS_TOO_LONG 						133
		#define ERROR_DISK_UNAVAILABLE 						134
		#define ERROR_DISK_STALE 							135
		#define ERROR_FILE_FORMAT_MISMATCH 					136
		#define ERROR_CANNOT_MAP_NAME 						137
		#define ERROR_DIRECTORY_NOT_EMPTY 					138
		#define ERROR_ATTR_NOT_SUPPORTED 					139
		#define ERROR_ATTR_NOT_FOUND 						140
		#define ERROR_ATTR_SIZE_MISMATCH 					141
		#define ERROR_ATTR_CANNOT_BE_SET 					142
		#define ERROR_CANNOT_MOVE_DIRECTORY 				143
		#define ERROR_PATH_TOO_LONG 						144
		#define ERROR_ARGS_INVALID 							145
		#define ERROR_CANNOT_FIND_COMMAND_INTERPRETER 		146
		#define ERROR_NO_TASK_DRIVER_LOADED 				147

----------
#### ErrorCheckingFlags
	typedef WordFlags ErrorCheckingFlags;
		#define ECF_REGION					0x8000
		#define ECF_HEAP_FREE_BLOCKS 		0x4000
		#define ECF_LMEM_INTERNAL 			0x2000
		#define ECF_LMEM_FREE_AREAS 		0x1000
		#define ECF_LMEM_OBJECT 			0x0800
		#define ECF_BLOCK_CHECKSUM 			0x0400
		#define ECF_GRAPHICS 				0x0200
		#define ECF_SEGMENT 				0x0100
		#define ECF_NORMAL 					0x0080
		#define ECF_VMEM 					0x0040
		#define ECF_APP 					0x0020
		#define ECF_LMEM_MOVE 				0x0010
		#define ECF_UNLOCK_MOVE 			0x0008
		#define ECF_VMEM_DISCARD 			0x0004
Error checking flags are used when setting the system's error-checking level 
with **SysSetECLevel()**. The flags above may be individually set or cleared. 
It is important to use error checking when debugging; it can help catch 
obscure bugs that might otherwise go unnoticed until after a product ships.

----------
#### EvalErrorData
	typedef struct {
		byte	EED_errorCode;		/* ParserScannerEvaluatorError */
	} EvalErrorData;

----------
#### EvalFlags
	typedef ByteFlags EvalFlags;
		#define EF_MAKE_DEPENDENCIES			0x80
		#define EF_ONLY_NAMES 					0x40
		#define EF_KEEP_LAST_CELL 				0x20
		#define EF_NO_NAMES 					0x10
		#define EF_ERROR_PUSHED 				0x08
		#define EVAL_MAX_NESTED_LEVELS			32

----------
#### EvalFunctionData
	typedef struct {
		FunctionID		EFD_functionID;
		word			EFD_nArgs;
	} EvalFunctionData;

----------
#### EvalNameData
	typedef struct {
		word 	END_name;
	} EvalNameData;

----------
#### EvalOperatorData
	typedef struct {
		OperatorType		EOD_opType;
	} EvalOperatorData;

----------
#### EvalStackArgumentData
	typedef union {
		EvalStringData			ESAD_string;
		EvalRangeData			ESAD_range;
		EvalErrorData			ESAD_error;
	} EvalStackArgumentData;

----------
#### EvalParameters
	typedef struct {
		CommonParameters	EP_common;
		EvalFlags			EP_flags;
		word				EP_fpStack;
		word				EP_depHandle;
		word				EP_nestedLevel;
		dword				EP_nestedAddresses[EVAL_MAX_NESTED_LEVELS];
	} EvalParameters;

----------
#### EvalRangeData
	typedef struct {
		CellReference			ERD_firstCell;
		CellReference			ERD_lastCell;
	} EvalRangeData;

----------
#### EvalStackArgumentType
	typedef ByteFlags EvalStackArgumentType;
		#define ESAT_EMPTY					0x80
		#define ESAT_ERROR 					0x40
		#define ESAT_RANGE 					0x20
		#define ESAT_STRING 				0x10
		#define ESAT_NUMBER 				0x08
		#define ESAT_NUM_TYPE 				0x03
		#define ESAT_TOP_OF_STACK 			0
		#define ESAT_NAME 					(ESAT_RANGE | ESAT_STRING)
		#define ESAT_FUNCTION 				(ESAT_NUMBER | ESAT_STRING)

----------
#### EvalStackOperatorData
	typedef union {
		EvalOperatorData			ESOD_operator;
		EvalFunctionData			ESOD_function;
	} EvalStackOperatorData;

----------
#### EvalStackOperatorType
	typedef ByteEnum EvalStackOperatorType;
		#define ESOT_OPERATOR				0
		#define ESOT_FUNCTION 				1
		#define ESOT_OPEN_PAREN 			2
		#define ESOT_TOP_OF_STACK 			3

----------
#### EvalStringData
	typedef struct {
		word	ESD_length;
	} EvalStringData;

----------
#### EventHandle
	typedef Handle		EventHandle;

----------
#### ExitFlags
	typedef ByteFlags ExitFlags;
		#define EF_PANIC				0x80
		#define EF_RUN_DOS				0x40
		#define EF_OLD_EXIT				0x20
		#define EF_RESET				0x10
		#define EF_RESTART				0x08

----------
#### ExportControlFeatures
	typedef ByteFlags ExportControlFeatures;
		#define EXPORTCF_BASIC						0x01

----------
#### ExportControlToolboxFeatures
	typedef ByteFlags ExportControlToolboxFeatures;
		#define EXPORTCTF_DIALOG_BOX				0x01

[Routines U-Z](rroutu_z.md) <-- [Table of Contents](../routines.md) &nbsp;&nbsp; --> [Data Structures F-K](rstrf_k.md)