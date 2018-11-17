#ifndef _HTMLFSTR_H_
#define _HTMLFSTR_H_

typedef enum {
    FSCS_NO_ERROR,		/* Buffer has data, send it */
    FSCS_DONE,			/* Same as above and form string is done */
    FSCS_ERROR,			/* An error was encountered, abort */
} FormStringCallbackStatus;

typedef FormStringCallbackStatus _pascal _export cb_FormStringCallback(
    void *postData, byte *buffer, word bufferSize, word *bufferUsed);
typedef FormStringCallbackStatus _pascal _export
    pcfm_FormStringCallback(void *postData, byte *buffer, 
    word bufferSize, word *bufferUsed, cb_FormStringCallback cb);

typedef MemHandle HTMLFormDataHandle ;

/* Structure used to define a FormString */
typedef struct {
    word numChars ;       /* How much space used in 'data' */
    word numAllocated ;   /* Keep track of space allocated in 'data' */
    word encoding;        /* encoding type of data to submit */
      #define FORM_STRING_ENCODING_URL          1
      #define FORM_STRING_ENCODING_MULTI        2
    word flags ;
      #define FORM_STRING_FLAG_IS_GET_METHOD    0x8000
    
    cb_FormStringCallback *callback;	/* vfptr to callback function  */
    MemHandle callbackData;	/* State block maintained by callback */
    dword contentLength;	/* Total length of content in this string
				   (req'd if can't be computed from data) */
    char data[] ;         /* Null terminated character string (network encoded) */
} T_formString ;

#endif
