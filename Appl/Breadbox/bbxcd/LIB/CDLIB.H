/************************************************************************
 *
 *                                 CDLaudio.H
 *
 *	Function:       Header file for CDAUDIO Library
 *                      Library with generic functions
 *                      for CD player audio access
 *
 *	161096	Jens-Michael Gross
 *              First implementation of basic access functions
 *      241096  Jens-Michael Gross
 *              Full implementation of all audio functions
 *
 ************************************************************************/

/* CD status messages */

#define CD_STATUS_DOOR_OPEN            0x0001
#define CD_STATUS_DOOR_NOT_LOCKED      0x0002
#define CD_STATUS_COOKED_AND_RAW       0x0004
#define CD_STATUS_CD_WRITER            0x0008
#define CD_STATUS_SUPPORTS_AUDIO       0x0010
#define CD_STATUS_ISO_INTERLEAVE       0x0020
#define CD_STATUS_SUPPORTS_PREFETCH    0x0080
#define CD_STATUS_SUPPORTS_VOLUME      0x0100
#define CD_STATUS_SUPPORTS_RED_BOOK    0x0200
#define CD_STATUS_DRIVE_EMPTY          0x0800
#define CD_STATUS_SUPPORTS_RW_CHANNEL  0x1000

/* cd driver error messages */

#define CD_ERROR_DRIVE_BUSY           1
#define CD_ERROR_DRIVE_NOT_READY      -2
#define CD_ERROR_CRC_ERROR            -4
#define CD_ERROR_UNKNOWN_MEDIA        -7
#define CD_ERROR_SECTOR_NOT_FOUND     -8
#define CD_ERROR_READ_ERROR           -11
#define CD_ERROR_NO_CD_INSIDE         -14
#define CD_ERROR_INVALID_MEDIA_CHANGE -15

/* redbook conversion macros */

#define RedbookMin(x)  ((x>>16)&0xff)
#define RedbookSec(x)  ((x>>8)&0xff)
#define RedbookFrm(x)  (x&0xff)
#define RedbookPos(m,s,f) ((((long)m)<<16)|(((long)s)<<8)|((long)f))

/* ***********************************************************************
   *                                                                     *
   *                              MSCDEX-routines                        *
   *                                                                     *
   *********************************************************************** */

extern void _pascal CDLib_Reset_Valid_Flags (void);
/* resets the CDLib cache */

extern word _pascal MSCDEX_Get_Version (void);
/* returns MSCDEX_Version, major in high, minor in low byte; 0= not installed */

extern byte _pascal MSCDEX_Get_Drives (void);
/* returns number of CD drives installed */

extern byte _pascal MSCDEX_Get_Drive_Letter (byte drive);
/* returns drive letter (A=0) of cdrom #drive */

/* ***********************************************************************
   *                                                                     *
   *                              CD-Drive functions                     *
   *                                                                     *
   *********************************************************************** */

extern char _pascal CD_Drive_Set (byte drive);
/* sets the current CD drive number */

extern void _pascal CD_Drive_Reset (void);
/* resets the CD drive and clears all drive status informations */

extern word _pascal CD_Drive_Get_Status (void);
/* returns status byte containing above informations */

extern char _pascal CD_Drive_Get_Change (void);
/* returns 1:changed since last call, 0:not changed
   this function uses the CD-length and trackinfo rather than
   the drivers media change function to check changes even if the
   UPC of old an new CD is the same (0).
*/

extern byte _pascal CD_Drive_Get_Volume (byte channel);
/* returns the current volume setting for that channel */

extern void _pascal CD_Drive_Set_Volume (byte channel, byte volume);
/* sets the audio volume for the given channel (0..255) */

extern void _pascal CD_Drive_Lock (byte mode);
/* mode=1:lock drive door; 0:unlock drive door */

extern void _pascal CD_Drive_Door (byte mode);
/* 0:open door; 1:close door */

extern char _pascal CD_Drive_Dos_Open (void);
/* tells the driver that another application is using it */

extern char _pascal CD_Drive_Dos_Close (void);
/* tell the driver that the application is no longer using it */

/* ***********************************************************************
   *                                                                     *
   *                              CD-functions                           *
   *                                                                     *
   *********************************************************************** */

extern byte _pascal CD_Get_UPC ( byte value, byte ignore );
/* returns one of the 14 digits of a CDs UPC code */

extern long _pascal CD_Get_Length (void);
/* returns the CDs whole play time or 0 if not valid */

extern byte _pascal CD_Get_Tracks (void) ;
/* returns number of highest CD track; lowest number must be taken from TrackType */

extern byte _pascal CD_Get_Track_Type (byte track) ;
/* returns type of track (0:none, 1:audio, 2:data) */

extern long _pascal CD_Get_Track_Start (byte track) ;
/* returns start position of a track; end is the start of the next track */

extern long _pascal CD_Get_Play_Position (byte mode) ;
/* returns
   mode = 0: track (highest nibble), index (lowest nibble) and track time
   mode = 1: disc time
*/

extern char _pascal CD_Get_Play_Status(void) ;
/* returns play status (0=play,1=pause,-1=stop)*/

extern char _pascal CD_Play_Position (long start, long stop) ;
/* plays a CD from start to stop; returns 0 on success or *error*
   a stop value less than start plays until end
*/

extern char _pascal CD_Play_Stop (byte pause) ;
/* pause=1:pause; pause=0:stop */

extern char _pascal CD_Play_Resume (void);
/* resume play after pause */


#ifdef  __HIGHC__
pragma Alias(CDLib_Reset_Valid_Flags, "CDLIB_RESET_VALID_FLAGS");
pragma Alias(MSCDEX_Get_Version,      "MSCDEX_GET_VERSION");
pragma Alias(MSCDEX_Get_Drives        "MSCDEX_GET_DRIVES");
pragma Alias(MSCDEX_Get_Drive_Letter, "MSCDEX_GET_DRIVE_LETTER");
pragma Alias(CD_Drive_Set,            "CD_DRIVE_SET");
pragma Alias(CD_Drive_Reset,          "CD_DRIVE_RESET");
pragma Alias(CD_Drive_Get_Status,     "CD_DRIVE_GET_STATUS");
pragma Alias(CD_Drive_Get_Change,     "CD_DRIVE_GET_CHANGE");
pragma Alias(CD_Drive_Get_Volume,     "CD_DRIVE_GET_VOLUME");
pragma Alias(CD_Drive_Set_Volume,     "CD_DRIVE_SET_VOLUME");
pragma Alias(CD_Drive_Lock,           "CD_DRIVE_LOCK");
pragma Alias(CD_Drive_Door,           "CD_DRIVE_DOOR");
pragma Alias(CD_Drive_Dos_Open,       "CD_DRIVE_DOS_OPEN");
pragma Alias(CD_Drive_Dos_Close,      "CD_DRIVE_DOS_CLOSE");
pragma Alias(CD_Get_UPC,              "CD_GET_UPC");
pragma Alias(CD_Get_Length,           "CD_GET_LENGTH");
pragma Alias(CD_Get_Tracks,           "CD_GET_TRACKS");
pragma Alias(CD_Get_Track_Type,       "CD_GET_TRACK_TYPE");
pragma Alias(CD_Get_Track_Start,      "CD_GET_TRACK_START");
pragma Alias(CD_Get_Play_Position,    "CD_GET_PLAY_POSITION");
pragma Alias(CD_Get_Play_Status,      "CD_GET_PLAY_STATUS");
pragma Alias(CD_Play_Position,        "CD_PLAY_POSITION");
pragma Alias(CD_Play_Stop,            "CD_PLAY_STOP");
pragma Alias(CD_Play_Resume,          "CD_PLAY_RESUME");
#endif



