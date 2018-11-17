/*
 * jmemname.c
 *
 * Copyright (C) 1992-1996, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file provides a generic implementation of the system-dependent
 * portion of the JPEG memory manager.  This implementation assumes that
 * you must explicitly construct a name for each temp file.
 * Also, the problem of determining the amount of memory available
 * is shoved onto the user.
 */

#include <geos.h>
#include <file.h>
#include <heap.h>

#define JPEG_INTERNALS
#include "jinclude.h"
#include "jpeglib.h"
#include "jmemsys.h"		/* import the system-dependent declarations */

#ifndef HAVE_STDLIB_H		/* <stdlib.h> should declare malloc(),free() */
extern void * malloc JPP((size_t size));
extern void free JPP((void *ptr));
#endif

#ifndef SEEK_SET		/* pre-ANSI systems may not define this; */
#define SEEK_SET  0		/* if not, assume 0 is correct */
#endif

#ifdef DONT_USE_B_MODE		/* define mode parameters for fopen() */
#define READ_BINARY	"r"
#define RW_BINARY	"w+"
#else
#define READ_BINARY	"rb"
#define RW_BINARY	"w+b"
#endif

#define BACK_STORE_IS_MEMORY  1

#if BACK_STORE_IS_MEMORY
#define BACK_STORE_BLOCK_SIZE       8192
#define BACK_STORE_MAX_NUM_BLOCKS   512      /* 8K * 512 = 4 Meg */
typedef struct {
    MemHandle blockArray[BACK_STORE_MAX_NUM_BLOCKS] ;
} T_backStoreHeader ;

MemHandle BackStoreCreate(void)
{
    return MemAlloc(sizeof(T_backStoreHeader), HF_DYNAMIC|HF_SHARABLE, HAF_ZERO_INIT) ;
}

void BackStoreDestroy(MemHandle backStore)
{
    T_backStoreHeader *p_header ;
    MemHandle *p_block ;
    word i ;

    /* Destroy all the blocks in the list (if they exist) */
    p_header = MemLock(backStore) ;
    p_block = p_header->blockArray ;
    for (i=0; i<BACK_STORE_MAX_NUM_BLOCKS; i++, p_block++)  {
        if (*p_block)  {
            MemFree(*p_block) ;
            *p_block = NullHandle ;
        }
    }

    /* Unlock and free the backstore index */
    MemUnlock(backStore) ;
    MemFree(backStore) ;
}

MemHandle IBackStoreGetBlock(
              MemHandle backStore,
              word blockIndex,
              Boolean doCreate)
{
    MemHandle *p_block ;
    MemHandle block ;
    T_backStoreHeader *p_header ;

    /* Any accesses past the end are thrown out */
    if (blockIndex >= BACK_STORE_MAX_NUM_BLOCKS)
        return NullHandle ;

    p_header = MemLock(backStore) ;

    p_block = p_header->blockArray + blockIndex ;
    if ((!(*p_block)) && (doCreate))  {
        *p_block = MemAlloc(BACK_STORE_BLOCK_SIZE, HF_DYNAMIC|HF_SHARABLE, 0) ;
    }

    block = *p_block ;

    MemUnlock(backStore) ;

    return block ;
}

void IBackStoreReadOrWrite(
         MemHandle backStore,
         byte FAR *p_data,
         dword offset,
         word size,
         Boolean doWrite)
{
    word indexStart ;
    word indexEnd ;
    word index ;
    word sizeNeeded ;
    MemHandle block ;
    word pos ;
    byte *p_block ;

    /* Determine the start and end block */
    indexStart = offset / BACK_STORE_BLOCK_SIZE ;
    indexEnd = (offset + size - 1) / BACK_STORE_BLOCK_SIZE ;

    /* Determine the position in the first block and how much to read */
    pos = offset % BACK_STORE_BLOCK_SIZE ;
    sizeNeeded = BACK_STORE_BLOCK_SIZE - pos ;
    if (sizeNeeded > size)
        sizeNeeded = size ;

    /* Loop through all the blocks that span this access */
    for (index=indexStart; index<=indexEnd; index++)  {
        /* If we got a size of zero, quit */
        if ((size == 0) || (sizeNeeded == 0))
            break ;

        /* Get a block.  If we are writing, do creates */
        block = IBackStoreGetBlock(backStore, index, doWrite) ;
        if (block)  {
            p_block = MemLock(block) ;
            if (doWrite)  {
                /* Copy in the data */
                memcpy(p_block + pos, p_data, sizeNeeded) ;
            } else {
                /* Copy out the data */
                memcpy(p_data, p_block + pos, sizeNeeded) ;
            }
            MemUnlock(block) ;
        } else {
            /* Only care if we are reading and we didn't get a block */
            /* In that case, zero out the data */
            if (!doWrite)  {
                /* Always zeros */
                memset(p_data, 0, sizeNeeded) ;
            }
        }

        /* Done this this block, subtract it out */
        size -= sizeNeeded ;
        p_data += sizeNeeded ;

        /* Determine the size of the next block */
        if (size > BACK_STORE_BLOCK_SIZE)
            sizeNeeded = BACK_STORE_BLOCK_SIZE ;
        else
            sizeNeeded = size ;

        /* Position will now always be at the beginning of the next block */
        pos = 0 ;
    }
}

void BackStoreRead(
         MemHandle backStore,
         void FAR *p_data,
         dword offset,
         word size)
{
    IBackStoreReadOrWrite(backStore, p_data, offset, size, FALSE) ;
}

void BackStoreWrite(
         MemHandle backStore,
         void FAR *p_data,
         dword offset,
         word size)
{
    IBackStoreReadOrWrite(backStore, p_data, offset, size, TRUE) ;
}

#endif

/*
 * Memory allocation and freeing are controlled by the regular library
 * routines malloc() and free().
 */

GLOBAL(void *)
jpeg_get_small (j_common_ptr cinfo, size_t sizeofobject)
{
  return (void *) malloc(sizeofobject);
}

GLOBAL(void)
jpeg_free_small (j_common_ptr cinfo, void * object, size_t sizeofobject)
{
  free(object);
}


/*
 * "Large" objects are treated the same as "small" ones.
 * NB: although we include FAR keywords in the routine declarations,
 * this file won't actually work in 80x86 small/medium model; at least,
 * you probably won't be able to process useful-size images in only 64KB.
 */

GLOBAL(void FAR *)
jpeg_get_large (j_common_ptr cinfo, size_t sizeofobject)
{
  return (void FAR *) malloc(sizeofobject);
}

GLOBAL(void)
jpeg_free_large (j_common_ptr cinfo, void FAR * object, size_t sizeofobject)
{
  free(object);
}


/*
 * This routine computes the total memory space available for allocation.
 * It's impossible to do this in a portable way; our current solution is
 * to make the user tell us (with a default value set at compile time).
 * If you can actually get the available space, it's a good idea to subtract
 * a slop factor of 5% or so.
 */

#ifndef DEFAULT_MAX_MEM		/* so can override from makefile */
#define DEFAULT_MAX_MEM         65536    /* default: 64K */
#endif

GLOBAL(long)
jpeg_mem_available (j_common_ptr cinfo, long min_bytes_needed,
		    long max_bytes_needed, long already_allocated)
{
  return cinfo->mem->max_memory_to_use - already_allocated;
}


/*
 * Backing store (temporary file) management.
 * Backing store objects are only used when the value returned by
 * jpeg_mem_available is less than the total space needed.  You can dispense
 * with these routines if you have plenty of virtual memory; see jmemnobs.c.
 */


METHODDEF(void)
read_backing_store (j_common_ptr cinfo, backing_store_ptr info,
		    void FAR * buffer_address,
		    long file_offset, long byte_count)
{
#if BACK_STORE_IS_MEMORY
  BackStoreRead(info->temp_file, buffer_address, file_offset, byte_count) ;
#else
  FilePos(info->temp_file, file_offset, FILE_POS_START);

  /* always return a buffer full of zeroes if reading fails for some reason -
     this should allow us to go on in a more graceful way even if the backing
     store has run out of memory. */

  if(FileRead(info->temp_file, buffer_address, byte_count, FALSE) != byte_count)
    jzero_far(buffer_address, byte_count);
#endif
}


METHODDEF(void)
write_backing_store (j_common_ptr cinfo, backing_store_ptr info,
		     void FAR * buffer_address,
		     long file_offset, long byte_count)
{
#if BACK_STORE_IS_MEMORY
  BackStoreWrite(info->temp_file, buffer_address, file_offset, byte_count) ;
#else
  FilePos(info->temp_file, file_offset, FILE_POS_START);
  FileWrite(info->temp_file, buffer_address, byte_count, FALSE);
#endif
}


METHODDEF(void)
close_backing_store (j_common_ptr cinfo, backing_store_ptr info)
{
#if BACK_STORE_IS_MEMORY
  BackStoreDestroy(info->temp_file) ;
#else
  FileClose(info->temp_file, TRUE);     /* close the file */
  FileSetStandardPath(SP_PRIVATE_DATA);
  FileDelete(info->temp_name); /* delete the file */
#endif
  TRACEMSS(cinfo, 1, JTRC_TFILE_CLOSE, info->temp_name);
}


/*
 * Initial opening of a backing-store object.
 */

GLOBAL(void)
jpeg_open_backing_store (j_common_ptr cinfo, backing_store_ptr info,
			 long total_bytes_needed)
{
  char temp_name[]="WASTE\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

#if BACK_STORE_IS_MEMORY
  info->temp_file = BackStoreCreate() ;
#else
  FileSetStandardPath(SP_PRIVATE_DATA);
  info->temp_file = FileCreateTempFile(temp_name,
    (FILE_CREATE_TRUNCATE | (FILE_ACCESS_RW | FILE_DENY_RW)),
    0);
#endif

EC(if (info->temp_file == NullHandle)
    ERREXITS(cinfo, JERR_TFILE_CREATE, info->temp_name); )

  strcpy(info->temp_name,temp_name);    /* remember temp file name */
  MASSIGN(info->read_backing_store, read_backing_store);
  MASSIGN(info->write_backing_store, write_backing_store);
  MASSIGN(info->close_backing_store, close_backing_store);
  TRACEMSS(cinfo, 1, JTRC_TFILE_OPEN, info->temp_name);
}


/*
 * These routines take care of any system-dependent initialization and
 * cleanup required.
 */

GLOBAL(long)
jpeg_mem_init (j_common_ptr cinfo)
{
  return DEFAULT_MAX_MEM;	/* default for max_memory_to_use */
}

GLOBAL(void)
jpeg_mem_term (j_common_ptr cinfo)
{
  /* no work */
}
