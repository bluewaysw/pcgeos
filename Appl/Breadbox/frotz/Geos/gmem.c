#include <geos.h>
#include <file.h>
#include <Ansi/stdio.h>
#include <Ansi/stdlib.h>
#include <Ansi/string.h>

#include "frotz.h"

extern FileHandle story_fp;

/*
 * Routine to read a byte.
 */
byte _pascal
GetByte
    (
    FileHandle fh
    )
{
    byte b;
    FileRead( fh, &b, 1, FALSE );

    return( b );
}


/***********************************************************************
    fputc
************************************************************************

    A quick'n'dirty implementation of fputc
    using the GEOS file routines.

REVISION HISTORY:
    Date      Name    Description
    --------  ------  -----------
    97-03-04  GerdB   Initial version.

***********************************************************************/
int  _pascal
fputc(
    int c,
    FileHandle fh
    )
{
    byte ch = (byte) c;
    return ( FileWrite( fh, &ch, 1, FALSE ) == 1 ) ? c : EOF;

} /* fputc */


/***********************************************************************
    geos_set_byte
************************************************************************

    given a 16 bit address and an 8 bit variable,
    store the value of the variable in the byte at the address.

CALLED BY:
    SET_BYTE macro

REVISION HISTORY:
    Date      Name    Description
    --------  ------  -----------
    97-03-05  GerdB   Initial version.

***********************************************************************/
void _pascal
geos_set_byte(
    zword addr,
    zword v
    )
{
    if ( addr >= h_dynamic_size ) {
        runtime_error( "Store out of dynamic memory" );
    }
    zmp[addr] = v;

} /* geos_set_byte */


/***********************************************************************
    geos_set_word
************************************************************************

    given a 16 bit address and a 16 bit variable,
    store the value of the variable in the word at the address

CALLED BY:
    SET_WORD macro

KNOWN DEFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
    Date      Name    Description
    --------  ------  -----------
    97-03-05  GerdB   Initial version.

***********************************************************************/
void _pascal
geos_set_word(
    zword addr,
    zword v
    )
{
    if ( ( addr + 1 ) >= h_dynamic_size ) {
        runtime_error( "Store out of dynamic memory" );
    }
    zmp[ addr ]     = hi( v );
    zmp[ addr + 1 ] = lo( v );

} /* geos_set_word */


/***********************************************************************
    geos_low_byte
************************************************************************

CALLED BY:
    LOW_BYTE macro

REVISION HISTORY:
    Date      Name    Description
    --------  ------  -----------
    97-03-05  GerdB   Initial version.

***********************************************************************/
zbyte _pascal           /* byte at the address */
geos_low_byte(
    zword addr  /* 16 bit address */
    )
{
    zbyte v;

    if ( addr <= h_dynamic_size ) {
        v = zmp[ addr ];
    }
    else {
        FilePos( story_fp, addr, FILE_POS_START );
        v = (zbyte) GetByte( story_fp );
    }
    return v;

} /* geos_low_byte */


/***********************************************************************
    geos_low_word
************************************************************************

CALLED BY:
    LOW_WORD macro

REVISION HISTORY:
    Date      Name    Description
    --------  ------  -----------
    97-03-05  GerdB   Initial version.

***********************************************************************/
zword _pascal           /* word at the address */
geos_low_word(
    zword addr  /* 16 bit address */
    )
{
    zword v;

    if ( ( addr + 1 ) <= h_dynamic_size ) {
        v = ( (zword) zmp[ addr ] << 8 ) | zmp[ addr + 1 ];
    }
    else {
        FilePos( story_fp, addr, FILE_POS_START );
        v = ( (zword) GetByte( story_fp ) << 8 ) | GetByte( story_fp );
    }
    return v;

} /* geos_low_word */


/***********************************************************************
    geos_high_word
************************************************************************

CALLED BY:
    HIGH_WORD macro

REVISION HISTORY:
    Date      Name    Description
    --------  ------  -----------
    97-03-05  GerdB   Initial version.

***********************************************************************/
zword _pascal           /* word at the address */
geos_high_word(
    dword addr  /* 32 bit address */
    )
{
    zword v;

    if ( addr <= h_dynamic_size ) {
        v = ( (zword) zmp[ addr ] << 8 ) | zmp[ addr + 1 ];
    }
    else {
        FilePos( story_fp, addr, FILE_POS_START );
        v = ( (zword) GetByte( story_fp ) << 8 ) | GetByte( story_fp );
    }
    return v;

} /* geos_high_word */


/***********************************************************************
    geos_code_byte
************************************************************************

CALLED BY:
    LOW_BYTE macro

REVISION HISTORY:
    Date      Name    Description
    --------  ------  -----------
    97-04-30  GerdB   Initial version.

***********************************************************************/
zbyte _pascal           /* byte at the address */
geos_code_byte(
    long  addr   /* 32 bit address */
    )
{
    zbyte v;

    if ( ( addr + 1 ) <= h_dynamic_size ) {
        v = zmp[ addr ];
    }
    else {
        FilePos( story_fp, addr, FILE_POS_START );
        v = (zbyte) GetByte( story_fp );
    }
    return v;

} /* geos_code_byte */
