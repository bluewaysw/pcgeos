/***********************************************************************
 *
 * PROJECT:       GPCBrow
 * FILE:          htmldrv.h
 *
 ***********************************************************************/

#ifndef __HTMLDRV_H
#define __HTMLDRV_H

#include <product.h>

#include <math.h>
#include <timedate.h>

#include <htmlfstr.h>
#include <awatcher.h>


/***********************************************************************
 *      Native Mime (graphics/text/helper app) drivers
 ***********************************************************************/

/* protocol version of compatible MIME image drivers */
#if PROGRESS_DISPLAY
/* upped for new API */
#define MIME_DRV_PROTOMAJOR 4
#else
#define MIME_DRV_PROTOMAJOR 3
#endif
#define MIME_DRV_PROTOMINOR 0

/* token for auto-recognition of Mime drivers */
#define MIME_DRV_TOKEN "MIMD"
#define MIME_DRV_MFID  16431

/*** Entry: Import as graphic *************************************************/

#define MIME_ENTRY_GRAPHIC 0

typedef byte MimeRes ;
#define MIME_RES_DISPLAY_DEFAULT  0   /* usually default for browser */
#define MIME_RES_MONOCHROME       1
#define MIME_RES_4_GREY           2
#define MIME_RES_16_COLOR         3
#define MIME_RES_16_GREY          4
#define MIME_RES_256_COLOR        5
#define MIME_RES_256_GREY         6
#define MIME_RES_24_BIT           7
#define MIME_RES_UNKNOWN          8


/*
 * Data returned about image in addition to VMBlockHandle of content.
 */
typedef struct {

  word          IAD_type;               /* Type of returned graphics data */
    #define IAD_TYPE_GSTRING    0
    #define IAD_TYPE_ANIMATION  1
    #define IAD_TYPE_BITMAP     2

  XYSize        IAD_size;               /* Size of bounding box */
  Point         IAD_origin;             /* Upper left corner of bounding box
                                           (typically 0,0) */
  Boolean       IAD_completeGraphic ;   /* TRUE if a complete graphic, else FALSE */
} ImageAdditionalData;


/*
 * MIME Graphic Entry Parameters explained:
 *
 * Inputs:
 *     char *mimeType             -- Mime type declared
 *     char *file                 -- Filename of image file
 *     VMFileHandle vmf           -- File handle to working cache
 *     MimeRes resolution         -- Expected color resolution of mime
 *     AllocWatcherHandle watcher -- Handle for watching avail memory.
 *     _ImportProgressParams_     -- data for importing progress update
 *     _LoadProgressParams_       -- data for loading progress update
 * Outputs:
 *     dword usedMem              -- Amount of memory actually used
 *     ImageAdditionalData *iad   -- Additional data (see above)
 *     VMBlockHandle              -- Handle to newly created mime data
 *                                   or NullHandle if not created.
 */

#define MIME_MAXBUF 32

/* Nice generic structure containing the state of the Mime import activity */
typedef word MimeStatusFlags;
#define MIME_STATUS_ABORT 0x8000
typedef struct {
    MimeStatusFlags MS_mimeFlags ;
} MimeStatus ;

#if PROGRESS_DISPLAY

/* import thread wait time fro load thread */
#define PROGRESS_INI_CAT "progressDisplay"
#define PROGRESS_INI_WAIT_KEY "loadWait"
#define PROGRESS_DEFAULT_WAIT 60
#define PROGRESS_INI_CL_KEY "contentLength"
#define PROGRESS_DEFAULT_CL (4*1024)
#define PROGRESS_INI_HEIGHT_KEY "height"
#define PROGRESS_DEFAULT_HEIGHT 30

#include <htmlprog.h>

/* import progress data */
typedef struct {
    LoadProgressData *IPD_loadProgressDataP;  /* load progress data */
    void _pascal *IPD_callback;         /* import progress callback routine */
    optr IPD_textObj;                   /* text obj to receive graphic */
    ImageAdditionalData IPD_iad;        /* graphic info */
    word IPD_nameT;			/* NameToken for graphic */
    VMBlockHandle IPD_bitmap;           /* bitmap being imported */
    VMFileHandle IPD_vmFile;            /* file containing bitmap */
    /* the following are changed by the import thread, so cannot be used
       from other threads */
    word IPD_firstLine, IPD_lastLine;   /* current scanline range */

    /* administration of the cache item holding the current chain */
    dword IPD_cacheItem;                /* currently occupied cache item */
} ImportProgressData;

#define _ImportProgressParams_ ImportProgressData *importProgressDataP

typedef void _pascal _export proc_ImportProgressCallback(_ImportProgressParams_);
typedef void _pascal pcfm_ImportProgressCallback(_ImportProgressParams_, void *pf);

#define _MimeGraphicParams_   \
            TCHAR *mimeType, \
            TCHAR *file, \
            VMFileHandle vmf, \
            ImageAdditionalData *iad, \
            MimeRes resolution, \
            AllocWatcherHandle watcher, \
            dword *usedMem, \
            MimeStatus *mimeStatus, \
	    _ImportProgressParams_

#else  /* PROGRESS_DISPLAY */

#define _MimeGraphicParams_   \
            TCHAR *mimeType, \
            TCHAR *file, \
            VMFileHandle vmf, \
            ImageAdditionalData *iad, \
            MimeRes resolution, \
            AllocWatcherHandle watcher, \
            dword *usedMem, \
            MimeSatus *mimeStatus

#endif  /* PROGRESS_DISPLAY */

#define MIME_LIMIT_NONE       0xFF000001


/*
 * Data format of IAD_TYPE_ANIMATION:
 *
 * An animation transfer item consists of a VMChain, whose header block is
 * returned by the import driver. The header block must have the following
 * structure:
 *
 *   1. A VMChainTree header. VMCT_offset points to the first VMChain element
 *      of item 3 (see below). VMCT_count contains the number of frames in
 *      the animation.
 *
 *   2. An array of <frames> AnimationFrame structures.
 *
 *   3. An array of <frames> VMChain entries pointing to Huge Bitmaps holding
 *      the individual frames of the animation. All frames must be the same
 *      size. Frames should be compacted and matched to the current screen
 *      resolution whenever possible. If a frame may contain transparency,
 *      it is drawn over the empty background, not over its predecessor.
 */

typedef struct {
  /* Animation is just a VMChain tree.  See above. */
  VMChainTree AH_tree ;

  /* Number of times this animation should loop */
  word AH_loopCount ;
      #define ANIMATION_LOOP_FOREVER    0xFFFF
} AnimationHeader ;


typedef struct {

  ByteFlags     AF_flags;

    /* Set the following flag if the frame doesn't contain a single
       transparent pixel. This may be used for optimized redraws: */

    #define ANIMATION_FLAG_NOT_TRANSPARENT 0x01

  /* Bounding box of changes from previous frame, relative to upper left
     corner of the frame. It is not an error to make the box too big (but
     it may lead to sub-optimal performance). If in doubt, make the box
     (0,0)-(width-1,height-1) to force the entire image to redraw.
     The change box of the first frame describes the changes from the last
     to the first frame. */

  Rectangle     AF_changeBox;

  /* Delay time after display of frame (in 1/100 of a second). A time of
     0 indicates the end of the loop. */

  word          AF_delayTime;

} AnimationFrame;


/*
 * Internal data structure of a HugeBitmap. We can use this to create
 * HugeBitmaps from scratch or to quickly get properties of a graphic.
 */
typedef struct {
    HugeArrayDirectory EB_header;
    CBitmap            EB_bm;
    BitmapMode         EB_flags;
    MemHandle          EB_color;
    /* other stuff here, don't use size of EditableBitmap */
} EditableBitmap;


typedef VMBlockHandle _pascal _export entry_MimeDrvGraphic(_MimeGraphicParams_);
typedef VMBlockHandle _pascal pcfm_MimeDrvGraphic(_MimeGraphicParams_,void *pf);


/*** Entry: Get driver info ***************************************************/

/*
 *  Returns a list of supported MIME types and their standard extensions
 *  in a string-list of the following format. The list has to be allocated
 *  in the passed buffer, which must hold at least MIME_INFO_MAXBUF characters.
 *
 *      MIME type 1 (lower case, zero terminated)
 *        Extension 1 (up to 3 characters, upper case, zero terminated)
 *        Extension 2 (any length)
 *        :
 *        \0
 *      MIME type 2
 *      :
 *      \0
 */

#define MIME_ENTRY_INFO 1

#define _MimeInfoParams_ \
            char *buf

#define MIME_INFO_MAXBUF 512

typedef char * _pascal _export entry_MimeDrvInfo(_MimeInfoParams_);
typedef char * _pascal pcfm_MimeDrvInfo(_MimeInfoParams_, void *pf);


/*** Entry: Import as text ****************************************************/

#define MIME_ENTRY_TEXT 2

/*
 * MIME Text Entry Parameters explained:
 *
 * Inputs:
 *     char *mimeType             -- Mime type declared
 *     char *file                 -- Filename of image file
 *     AllocWatcherHandle watcher -- Handle for watching avail memory.
 * Outputs:
 *     TextAdditionalData *tad    -- Additional data (see above)
 *     dword usedMem              -- Amount of memory actually used, if
 *                                   Hypertext Transfer Item is returned.
 *     dword                      -- Depends on tad->TAD_type (see above)
 */

#define _MimeTextParams_   \
            TCHAR *url, \
            TCHAR *mimeType, \
            TCHAR *file, \
            VMFileHandle vmf, \
            TextAdditionalData *tad, \
            AllocWatcherHandle watcher, \
            dword *usedMem

/*
 * Data returned about text to explain interpretation of dword returned:
 */
typedef struct {

  word          TAD_type;               /* Type of returned data: */

    #define TAD_TYPE_NOP         0      /* Nothing has been returned, the
                                           browser is requested not to advance
                                           to the requested URL at all. */

    #define TAD_TYPE_HTML_OPTR   1      /* An optr to a buffer containing a
                                           message in HTML format. If the
                                           chunk handle of the optr is zero,
                                           the message is assumed to be stored
                                           in a block on the global heap that
                                           can be freed after processing. */

    #define TAD_TYPE_ITEM        2      /* The VMBlockHandle of a Hypertext
                                           Transfer Item that was created in
                                           the passed VM file. In this case,
                                           the alloc watcher must be used. */

    #define TAD_TYPE_REQUEST_IMG 3      /* The browser should call the driver
                                           again through the Graphic entry
                                           point to get a GString version of
                                           the graphic. Nothing has been
                                           returned. */

} TextAdditionalData;

typedef dword _pascal _export entry_MimeDrvText(_MimeTextParams_);
typedef dword _pascal pcfm_MimeDrvText(_MimeTextParams_,void *pf);


/*** Entry: Import as graphic extended ********************************/

#define MIME_ENTRY_GRAPHIC_EX 3	
			// protocol 4.2

#define MIME_GREX_NO_ANIMATIONS				0x00000001
#define MIME_GREX_NO_SCANLINE_COMPRESS		0x00000002

typedef VMBlockHandle _pascal _export entry_MimeDrvGraphicEx(_MimeGraphicParams_, dword extFlags);
typedef VMBlockHandle _pascal pcfm_MimeDrvGraphicEx(_MimeGraphicParams_,dword extFlags,void *pf);



/***********************************************************************
 *      Impex style drivers
 ***********************************************************************/

#define IMPEX_DRV_PROTOMAJOR 4
#define IMPEX_DRV_PROTOMINOR 0

/* token for auto-recognition of graphics drivers */
#define IMPEX_DRV_TOKEN "TLGR"
#define IMPREX_DRV_MFID  0


/***********************************************************************
 *      URL drivers
 ***********************************************************************/

/* protocol version of compatible URL drivers */
#if PROGRESS_DISPLAY
/* new API */
/*#define URL_DRV_PROTOMAJOR 6*/
/* for referer support */
#define URL_DRV_PROTOMAJOR 7
#else
/*#define URL_DRV_PROTOMAJOR 5*/
/* for referer support */
#define URL_DRV_PROTOMAJOR 6
#endif
#define URL_DRV_PROTOMINOR 0

/* standard location for URL drivers */
#define URL_DRV_SP  SP_SYSTEM
#define URL_DRV_DIR _TEXT("www")

/* token for auto-recognition of URL drivers */
#define URL_DRV_TOKEN "URLD"
#define URL_DRV_MFID  16431


/*** Entry: Retrieve URL to file **********************************************/

#define URL_ENTRY_MAIN 0

/*
 * Inputs:
 *     request   MemHandle of a block whose header is described by
 *               URLRequestBlock. This block doesn't have to be locked at the
 *               time of the call, and it must be freed by the caller after
 *               return in any case because it is used for returning data.
 *
 *     postData  Handle to a block of data that will be posted.  If no
 *               data is to be posted, pass NULL. This block most be freed
 *               by the caller after return if it doesn't intend to reuse it.
 *
 * Outputs:
 *     word      Any of URL_RET_*, indicating the result of the request,
 *               possible with one or more URB_RF_* flags set.
 */

#define _URLCallbackParams_ \
            TCHAR *msg,      /* Text string with status message. */\
            long progress,  /* Number of bytes loaded, -1 if not applicable. */\
            long total,     /* Number of bytes to load, -1 if unknown. */\
            dword token     /* Identifier passed to URL driver. */

typedef void _pascal _export proc_URLDrvCallback(_URLCallbackParams_);
typedef void _pascal pcfm_URLDrvCallback(_URLCallbackParams_, void *pf);

/* Data type used for passing around timestamps between the URL Driver and the
   caller. Time is encoded as in the ANSI C time_t datatype (hence the name).
   It specifies seconds elapsed since Midnight (UTC) January 1, 1970. */
typedef long URLDrv_time_t;
#define URL_TIME_UNKNOWN ((URLDrv_time_t)-1)

/* these bitfields must be int-aligned, hence the strange order */
typedef struct {
    unsigned CDT_year:6;  /* 1980-based */
    unsigned CDT_month:4;  /* 1 - 12 */
    unsigned CDT_seconds:6;  /* 0 - 59 */
    unsigned CDT_day:5;  /* 1 - 31 */
    unsigned CDT_minutes:6;  /* 0 - 59 */
    unsigned CDT_hours:5;  /* 0 - 23 */
} CompressedDateTime;

typedef struct {
  LMemBlockHeader       URB_meta;       /* header of LMem heap */

  /*** Input fields: ***/

  WordFlags             URB_reqFlags;
    #define URB_RQ_ALWAYS       0x0001  /* don't use URB_laterDate or caching */

  /* Application-defined identifier for this loading thread. */
  dword                 URB_token;

  /* URL to be loaded is passed here. The routine may change the
     contents of this buffer if the URL has been moved etc. */
  ChunkHandle           URB_url;

  /* A suggested destination filename is passed here. The routine may change
     this name if the received file was stored in a different place. */
  ChunkHandle           URB_file;

  /* Date that this document has to be later than to be downloaded. Pass
     URL_TIME_UNKNOWN if you don't want a date check and just want a
     download. */
  URLDrv_time_t         URB_laterDate;

  /* Pointer or vptr to a callback function used to transmit progress messages
     back to the caller. NULL means no callback. */
  proc_URLDrvCallback   *URB_progress;


  /*** Output fields: ***/

  /* Points to a buffer in which the MIME type is returned, or 0 if it could
     not be determined safely. */
  ChunkHandle           URB_mimeType;

  /* Timestamp of content, if a file was returned. May be URL_TIME_UNKNOWN if
     no date was associated with the content (e.g. by the server). */
  URLDrv_time_t         URB_date;

  /* Expiration date of content, if a file was returned. May be
     URL_TIME_UNKNOWN if no expiration was specified. */
  URLDrv_time_t         URB_expireDate;

  /* HTML message, if a message or an error was returned. NullOptr if the URL
     could be resolved to a local file, or an optr to an HTML error message if
     anything went wrong. The chunk handle portion must be zero, as the
     message must be stored in a block on the global heap which is freed after
     displaying the message. If the chunk handle is non-zero, the chunk will
     not be freed. */
  optr                  URB_message;

#if PROGRESS_DISPLAY
  /* loading progress data */
  LoadProgressData      *URB_loadProgressDataP;
#endif

  /* referer URL */
  ChunkHandle           URB_referer;

  /* for cache validation */
  dword                 URB_cacheTime;
  dword                 URB_maxAge;
  CompressedDateTime    URB_lastModDate;

  /* email account management commands */
  ChunkHandle           URB_extraData;

  /* error code from URL driver, valid if URB_message is set, 0 for no
     specific error */
  word                  URB_errorCode;

} URLRequestBlock;

#define _URLMainParams_ \
            MemHandle request, \
            HTMLFormDataHandle postData

typedef word _pascal _export entry_URLDrvMain(_URLMainParams_);
typedef word _pascal pcfm_URLDrvMain(_URLMainParams_, void *pf);

#define URB_RF_NOCACHE     0x0100       /* delete file after use, don't cache */
#define URB_RF_FILE_REDIR  0x0200       /* passed filename was overriden */
#define URB_RF_UNTOUCHED   0x0400       /* laterDate condition was not met */

#define URB_RF_RET         0x00FF       /* mask: return code */
#define URLRequestGetRet(x) ((x) & URB_RF_RET)
#define URLRequestMakeRet(x) (x)

/* Return codes signalling that something displayable has come back: */
#define URL_RET_FILE            1   /* mimeType valid, see URB_file */
#define URL_RET_MESSAGE         2   /* HTML message, see URB_message */
#define URL_RET_URL_REDIR       3   /* url changed, see URB_url */
#if PROGRESS_DISPLAY
#define URL_RET_PROGRESS	4   /* load progress finished */
#define URL_RET_PROGRESS_ABORT  5   /* load progress aborted */
#endif

/* Return codes indicating specific failure conditions */
#define URL_RET_FIRST_FAILURE   100

#define URL_RET_INSTANCE_LIMIT  100     /* Could not load URL because no more
                                           loader instances can be started.
                                           Non thread-safe drivers should
                                           return this value whenever they
                                           are re-entered. */

#define URL_RET_ABORTED         101     /* Page was not loaded because the
                                           driver was told to abort. */

#define URL_RET_NO_MEMORY       102     /* Couldn't allocate enough memory */

#define URL_RET_NO_DISKSPACE    103     /* Document wouldn't fit onto disk.
                                           *ret contains minimum number of
                                           additional bytes needed. */

#define URL_RET_AUTHORIZATION   104     /* Authorization failed */


/*** Entry: Abort URL retrieval ***********************************************/

#define URL_ENTRY_ABORT 1

/*
 *   token      Token of load process to be aborted asap. A driver may choose
 *              to abort all currently running processes at the same time.
 */

#define _URLAbortParams_ \
            dword token, \
            URLDrvAbortState state

typedef word URLDrvAbortState ;
#define URL_ABORT_STATE_NORMAL                          0
#define URL_ABORT_STATE_IGNORE_USER_INTERRUPT_MESSAGE   1

typedef void _pascal _export entry_URLDrvAbort(_URLAbortParams_);
typedef void _pascal pcfm_URLDrvAbort(_URLAbortParams_, void *pf);


/*** Entry: Get driver info ***************************************************/

#define URL_ENTRY_INFO 2

/*
 *  Returns a list of supported URL schemes in a string-list of the format:
 *  The list has to be allocated in the passed buffer, which must hold at
 *  least URL_INFO_MAXBUF characters.
 *
 *      Scheme type 1 (without the ":", zero terminated)
 *      Scheme type 2
 *      :
 *      \0
 */

#define _URLInfoParams_ \
            TCHAR *buf

#define URL_INFO_MAXBUF 512

typedef char * _pascal _export entry_URLDrvInfo(_URLInfoParams_);
typedef char * _pascal pcfm_URLDrvInfo(_URLInfoParams_, void *pf);


/*** Entry: Flush driver privdate data **************************************/

#define URL_ENTRY_FLUSH 3

/*
 *  Flush driver privdate data.
 */

typedef void _pascal _export entry_URLDrvFlush(void);
typedef void _pascal pcfm_URLDrvFlush(void *pf);

#endif
