/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  putc.h
 *
 * AUTHOR:  	  Josh Putnam: Dec 11, 1992
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	12/11/92   	Initial version
 *
 * DESCRIPTION:
 *	This is a version of putc for use with MetaWare code only
 *      The MetaWare version makes too many calls, so we use this
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _PUTC_H_
#define _PUTC_H_





#if defined(__HIGHC__) 
/*
 *  We need our own version of putc because the MetaBlam version is not
 *  a macro! It just calls fwrite(&c,1,1,str), which is far too inefficient.
 * 
 *  This version of putc is meant to work with the tools, so it is optimized
 *  with them in mind. That means it will handle normal buffering well,
 *  but it will not handle non-buffered streams or line buffered streams
 *  well. These assumptions make this macro a lot simpler, but it also
 *  means that the macro will have to change if the tools do.
 * 
 *  Here are the reasons we call putc:
 *   
 *  to initialize the buffer (see note below)
 *  to flush the buffer
 *  to handle a text/line buffered stream
 *  to handle an append stream
 * 
 *
 * They've optimized for no buffering (_IONBF), and that allows them to 
 * save a buffer. It means they always have to check if a non-buffered 
 * stream needs a buffer though, so putc has to check that the buffer
 * is initialized. This is a pain, so we pass it off to putc.
 *
 * 
 */
#define PUTCTEST(str) ((str)->_file <=2)

#ifdef PUTCDEBUG
static void putc_debug_function(FILE *str)
{
    static FILE *ff=NULL;
    if(!ff){
	ff = fopen("putc.log","w");
    }
    fprintf(ff,
	    "ptr %x\tcnt\t%d\tbase %x\tend%x\n",      
	    (str)->_ptr,(str)->_cnt,(str)->_base,            
	    _bufendtab[(str)->_file]);
}
#endif
#define putc(c,str) \
    ((((str)->_cnt == 0) ||                     /* buffer needs to flush */ \
      ((str)->_base == 0) ||                    /* buffer needs init     */ \
      _iob_fioflag[(str)->_file] & _FIOTEXT ||  /* if text mode or       */ \
      _iob_fioflag[(str)->_file] & _FIOAPPEND|| /* or str is append mode */ \
      (str)->_flag & (_IONBF || _IOLBF))?       /* or is not full buff.  */ \
     fputc(c,str):                              /* call fputc (wimp out) */ \
     ((str)->_cnt--,                            /* reduce buffer's count */ \
      (*(str)->_ptr++ = c))                     /* store and return value*/ \
     )

#endif


#endif /* _PUTC_H_ */
