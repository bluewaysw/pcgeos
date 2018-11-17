/***********************************************************************

       Copyright (c) Gerd Boerrigter 1998 -- All Rights Reserved

  PROJECT:      FROTZ for GEOS - an interpreter for all Infocom games.
  MODULE:       screen manipulation
  FILE:         gScreen.c

  AUTHOR:       Gerd Boerrigter

  RCS STAMP:
    $Id: $

  DESCRIPTION:
    This file contains the GEOS front end, screen manipulation.

  REVISION HISTORY:
    Date      Name      Description
    --------  --------  -----------
    98-06-06  GerdB     Initial Version.

***********************************************************************/


#include "frotz.h"
#include <color.h>

void FrotzResetGeos( void );


int user_background = -1;
int user_foreground = -1;
int user_emphasis = -1;
int user_bold_typing = -1;
int user_reverse_bg = -1;
int user_reverse_fg = -1;
int user_screen_height = -1;
int user_screen_width = -1;
int user_tandy_bit = -1;
int user_random_seed = -1;
int user_font = 1;

/*
 * clear_line
 *
 * Helper function for os_erase_area.
 *
 */

static void clear_line (int y, int left, int right)
{

}/* clear_line */

/*
 * os_erase_area
 *
 * Fill a rectangular area of the screen with the current background
 * colour. Top left coordinates are (1,1). The cursor does not move.
 *
 */

void os_erase_area (int top, int left, int bottom, int right)
{

}/* os_erase_area */

/*
 * copy_byte
 *
 * Helper function for copy_line.
 *
 */
static void copy_byte (byte far *scrn1, byte far *scrn2, byte mask)
{

}/* copy_byte */

/*
 * copy_line
 *
 * Helper function for os_scroll_area.
 *
 */
static void copy_line (int y1, int y2, int left, int right)
{

}/* copy_line */

/*
 * os_scroll_area
 *
 * Scroll a rectangular area of the screen up (units > 0) or down
 * (units < 0) and fill the empty space with the current background
 * colour. Top left coordinates are (1,1). The cursor stays put.
 *
 */
void os_scroll_area (int top, int left, int bottom, int right, int units)
{

}/* os_scroll_area */



/*
 * reset_pictures
 *
 * Free resources allocated for decompression of pictures.
 *
 */

void reset_pictures (void)
{

}/* reset_pictures */


/*
 * init_sound
 *
 * Initialise the sound board and various sound related variables.
 *
 */

bool init_sound (void)
{
    /* Indicate success */
    return TRUE;

}/* init_sound */

/*
 * reset_sound
 *
 * Free resources allocated for playing samples.
 *
 */

void reset_sound (void)
{

    os_stop_sample ();

}/* reset_sound */

/*
 * cleanup
 *
 * Shut down the IO interface: free memory, close files, restore
 * interrupt pointers and return to the previous video mode.
 *
 */

static void cleanup (void)
{

    reset_sound ();
    reset_pictures ();

}/* cleanup */


/*
 * os_init_screen
 *
 * Initialise the IO interface. Prepare the screen and other devices
 * (mouse, sound board). Set various OS depending story file header
 * entries:
 *
 *     h_config (aka flags 1)
 *     h_flags (aka flags 2)
 *     h_screen_cols (aka screen width in characters)
 *     h_screen_rows (aka screen height in lines)
 *     h_screen_width
 *     h_screen_height
 *     h_font_height (defaults to 1)
 *     h_font_width (defaults to 1)
 *     h_default_foreground
 *     h_default_background
 *     h_interpreter_number
 *     h_interpreter_version
 *     h_user_name (optional; not used by any game)
 *
 * Finally, set reserve_mem to the amount of memory (in bytes) that
 * should not be used for multiple undo and reserved for later use.
 *
 */

void os_init_screen (void)
{
    static byte zcolour[] = {
    C_BLACK,
    C_BLUE,
    C_GREEN,
    C_CYAN,
    C_RED,
    C_VIOLET,
    C_BROWN + 16,
    C_LIGHT_GREY + 16,
    C_DARK_GREY,
    C_LIGHT_BLUE + 16,
    C_LIGHT_GREEN + 16,
    C_LIGHT_CYAN + 16,
    C_LIGHT_RED + 16,
    C_LIGHT_VIOLET + 16,
    C_YELLOW,
    C_WHITE
    };

    static struct { /* information on modes 0 to 5 */
    byte vmode;
    word width;
    word height;
    byte font_width;
    byte font_height;
    byte fg;
    byte bg;
    } info[] = {
    { 0x07,  80,  25,  1,  1, C_LIGHT_GRAY + 16, C_BLACK     }, /* MONO  */
    { 0x03,  80,  25,  1,  1, C_LIGHT_GRAY + 16, C_BLUE      }, /* TEXT  */
    { 0x06, 640, 200,  8,  8, C_WHITE,           C_BLACK     }, /* CGA   */
    { 0x13, 320, 200,  5,  8, C_WHITE,           C_DARK_GREY }, /* MCGA  */
    { 0x0e, 640, 200,  8,  8, C_WHITE,           C_BLUE      }, /* EGA   */
    { 0x12, 640, 400,  8, 16, C_WHITE,           C_BLACK     }  /* AMIGA */
    };

#if 0
    static struct { /* information on modes A to E */
    word vesamode;
    word width;
    word height;
    } subinfo[] = {
    { 0x001,  40, 25 },
    { 0x109, 132, 25 },
    { 0x10b, 132, 50 },
    { 0x108,  80, 60 },
    { 0x10c, 132, 60 }
    };

    int subdisplay;

    /* Get the current video mode. This video mode will be selected
       when the program terminates. It's also useful to auto-detect
       monochrome boards. */

    asm mov ah,15
    asm int 0x10
    asm mov old_video_mode,al

    /* If the display mode has not already been set by the user then see
       if this is a monochrome board. If so, set the display mode to 0.
       Otherwise check the graphics flag of the story. Select a graphic
       mode if it is set or if this is a V6 game. Select text mode if it
       is not. */

    if (display == -1)

    if (old_video_mode == 7)
        display = '0';
    else if (h_version == V6 || (h_flags & GRAPHICS_FLAG))
        display = '5';
    else
        display = '1';

    /* Activate the desired display mode. All VESA text modes are very
       similar to the standard text mode; in fact, only here we need to
       know which VESA mode is used. */

    if (display >= '0' && display <= '5') {
    subdisplay = -1;
    display -= '0';
    _AL = info[display].vmode;
    _AH = 0;
    } else if (display == 'a') {
    subdisplay = 0;
    display = 1;
    _AL = 0x01;
    _AH = 0;
    } else if (display >= 'b' && display <= 'e') {
    subdisplay = display - 'a';
    display = 1;
    _BX = subinfo[subdisplay].vesamode;
    _AX = 0x4f02;
    }

    geninterrupt (0x10);

    /* Make various preparations */

    if (display <= _TEXT_) {

    /* Enable bright background colours */

    asm mov ax,0x1003
    asm mov bl,0
    asm int 0x10

    /* Turn off hardware cursor */

    asm mov ah,1
    asm mov cx,0xffff
    asm int 0x10

    } else {

    load_fonts (progname);

    if (display == _AMIGA_) {

         scaler = 2;

         /* Use resolution 640 x 400 instead of 640 x 480. BIOS doesn't
        help us here since this is not a standard resolution. */

         outportb (0x03c2, 0x63);

         outport (0x03d4, 0x0e11);
         outport (0x03d4, 0xbf06);
         outport (0x03d4, 0x1f07);
         outport (0x03d4, 0x9c10);
         outport (0x03d4, 0x8f12);
         outport (0x03d4, 0x9615);
         outport (0x03d4, 0xb916);

     }

    }

#if !defined(__SMALL__) && !defined (__TINY__) && !defined (__MEDIUM__)

    /* Set the amount of memory to reserve for later use. It takes
       some memory to open command, script and game files. If Frotz
       is compiled in a small memory model then memory for opening
       files is allocated on the "near heap" while other allocations
       are made on the "far heap", i.e. we need not reserve memory
       in this case. */

    reserve_mem = 4 * BUFSIZ;

#endif

    /* Amiga emulation under V6 needs special preparation. */

    if (display == _AMIGA_ && h_version == V6) {

    user_reverse_fg = -1;
    user_reverse_bg = -1;
    zcolour[LIGHTGRAY] = LIGHTGREY;
    zcolour[DARKGRAY] = DARKGREY;

    special_palette ();

    }
#endif

    /* Set various bits in the configuration byte. These bits tell
       the game which features are supported by the interpreter. */

    if (h_version == V3 && user_tandy_bit != -1)
    h_config |= CONFIG_TANDY;
    if (h_version == V3)
    h_config |= CONFIG_SPLITSCREEN;
//    if (h_version == V3 && (display == _MCGA_ || (display == _AMIGA_ && user_font != 0)))
//    h_config |= CONFIG_PROPORTIONAL;
//    if (h_version >= V4 && display != _MCGA_ && (user_bold_typing != -1 || display <= _TEXT_))
//    h_config |= CONFIG_BOLDFACE;
    if (h_version >= V4)
    h_config |= CONFIG_EMPHASIS | CONFIG_FIXED | CONFIG_TIMEDINPUT;
//    if (h_version >= V5 && display != _MONO_ && display != _CGA_)
    h_config |= CONFIG_COLOUR;
//    if (h_version >= V5 && display >= _CGA_ && init_pictures ())
//    h_config |= CONFIG_PICTURES;

    /* Handle various game flags. These flags are set if the game wants
       to use certain features. The flags must be cleared if the feature
       is not available. */

    if (h_flags & GRAPHICS_FLAG)
//    if (display <= _TEXT_)
        h_flags &= ~GRAPHICS_FLAG;
    if (h_version == V3 && (h_flags & OLD_SOUND_FLAG))
    if (!init_sound ())
        h_flags &= ~OLD_SOUND_FLAG;
    if (h_flags & SOUND_FLAG)
    if (!init_sound ())
        h_flags &= ~SOUND_FLAG;
    if (h_version >= V5 && (h_flags & UNDO_FLAG))
    if (!option_undo_slots)
        h_flags &= ~UNDO_FLAG;
    if (h_flags & MOUSE_FLAG)
//    if (subdisplay != -1 || !detect_mouse ())
//        h_flags &= ~MOUSE_FLAG;
    if (h_flags & COLOUR_FLAG)
//    if (display == _MONO_ || display == _CGA_)
//        h_flags &= ~COLOUR_FLAG;
    h_flags &= ~MENU_FLAG;

    /* Set the screen dimensions, font size and default colour */

    h_screen_width = 320;
    h_screen_height = 100;
    h_font_height = 8;
    h_font_width = 8;
    h_default_foreground = C_BLACK;
    h_default_background = C_WHITE;

//    if (subdisplay != -1) {
//    h_screen_width = subinfo[subdisplay].width;
//    h_screen_height = subinfo[subdisplay].height;
//    }

    if (user_screen_width != -1)
    h_screen_width = user_screen_width;
    if (user_screen_height != -1)
    h_screen_height = user_screen_height;

    h_screen_cols = h_screen_width / h_font_width;
    h_screen_rows = h_screen_height / h_font_height;

    if (user_foreground != -1)
    h_default_foreground = zcolour[user_foreground];
    if (user_background != -1)
    h_default_background = zcolour[user_background];

    /* Set the interpreter number (a constant telling the game which
       operating system it runs on) and the interpreter version. The
       interpreter number has effect on V6 games and "Beyond Zork". */

    h_interpreter_number = INTERP_MSDOS;
    h_interpreter_version = 'F';

//    if (display == _AMIGA_)
//    h_interpreter_number = INTERP_AMIGA;

}/* os_init_screen */

/*
 * os_reset_screen
 *
 * Reset the screen before the program stops.
 *
 */

void os_reset_screen (void)
{

    os_set_font (TEXT_FONT);
    os_set_text_style (0);
//    os_display_string ((zchar *) "[Hit any key to exit.]");
//    os_read_key (0, TRUE);

    cleanup ();
    FrotzResetGeos();

}/* os_reset_screen */

/*
 * os_restart_game
 *
 * This routine allows the interface to interfere with the process of
 * restarting a game at various stages:
 *
 *     RESTART_BEGIN - restart has just begun
 *     RESTART_WPROP_SET - window properties have been initialised
 *     RESTART_END - restart is complete
 *
 */

void os_restart_game (int stage)
{
    if ( RESTART_WPROP_SET == stage ) {
        InitGeosWindow();
    }

}/* os_restart_game */


/*
 * os_random_seed
 *
 * Return an appropriate random seed value in the range from 0 to
 * 32767, possibly by using the current system time.
 *
 */

int os_random_seed (void)
{

    if (user_random_seed == -1) {

        /* Use the time of day as seed value */
        return TimerGetCount() & 0x7fff;

    } else return user_random_seed;

}/* os_random_seed */
