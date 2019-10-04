/*
 * main.c
 *
 * Frotz V2.32 main function
 *
 * This is an interpreter for Infocom V1 to V6 games. It also supports
 * the recently defined V7 and V8 games. Please report bugs to
 *
 *    s.jokisch@avu.de
 *
 * Frotz is freeware. It may be used and distributed freely provided
 * no commercial profit is involved. (c) 1995-1997 Stefan Jokisch
 *
 */

#include "frotz.h"

#ifndef __MSDOS__
#define cdecl
#endif

#include <sem.h>
#include <thread.h>
extern SemaphoreHandle waitForFinished;
extern int finished;

extern void interpret (void);
/* jfh - let's give it a return value to indicate success or failure
 * so we can close the file gracefully */
extern Boolean init_memory (void);
extern void init_undo (void);
extern void reset_memory (void);
extern void FrotzDoQuit( void );

/* Story file name, id number and size */

// char *story_name = 0;

enum story story_id = UNKNOWN;
long story_size = 0;

/* Story file header data */

zbyte h_version = 0;
zbyte h_config = 0;
zword h_release = 0;
zword h_resident_size = 0;
zword h_start_pc = 0;
zword h_dictionary = 0;
zword h_objects = 0;
zword h_globals = 0;
zword h_dynamic_size = 0;
zword h_flags = 0;
zbyte h_serial[6] = { 0, 0, 0, 0, 0, 0 };
zword h_abbreviations = 0;
zword h_file_size = 0;
zword h_checksum = 0;
zbyte h_interpreter_number = 0;
zbyte h_interpreter_version = 0;
zbyte h_screen_rows = 0;
zbyte h_screen_cols = 0;
zword h_screen_width = 0;
zword h_screen_height = 0;
zbyte h_font_height = 1;
zbyte h_font_width = 1;
zword h_functions_offset = 0;
zword h_strings_offset = 0;
zbyte h_default_background = 0;
zbyte h_default_foreground = 0;
zword h_terminating_keys = 0;
zword h_line_width = 0;
zbyte h_standard_high = 1;
zbyte h_standard_low = 0;
zword h_alphabet = 0;
zword h_extension_table = 0;
zbyte h_user_name[8] = { 0, 0, 0, 0, 0, 0, 0, 0 };

zword hx_table_size = 0;
zword hx_mouse_x = 0;
zword hx_mouse_y = 0;
zword hx_unicode_table = 0;

/* Stack data */

zword stack[STACK_SIZE];
zword *sp = 0;
zword *fp = 0;

/* IO streams */

bool ostream_screen = TRUE;
bool ostream_script = FALSE;
bool ostream_memory = FALSE;
bool ostream_record = FALSE;
bool istream_replay = FALSE;
bool message = FALSE;

/* Current window and mouse data */

int cwin = 0;
int mwin = 0;

int mouse_y = 0;
int mouse_x = 0;

/* Window attributes */

bool enable_wrapping = FALSE;
bool enable_scripting = FALSE;
bool enable_scrolling = FALSE;
bool enable_buffering = FALSE;

/* User options */

int option_attribute_assignment = 0;
int option_attribute_testing = 0;
int option_context_lines = 0;
int option_object_locating = 0;
int option_object_movement = 0;
int option_left_margin = 0;
int option_right_margin = 0;
int option_ignore_errors = 0;
int option_piracy = 0;
int option_undo_slots = MAX_UNDO_SLOTS;
int option_expand_abbreviations = 0;
int option_script_cols = 80;

/* Size of memory to reserve (in bytes) */

long reserve_mem = 0;

/*
 * runtime_error
 *
 * An error has occured. Ignore it or pass it to os_fatal.
 *
 */

void runtime_error (const char *s)
{

    if (!option_ignore_errors)
    { flush_buffer (); os_fatal (s); }

}/* runtime_error */

/*
 * z_piracy, branch if the story file is a legal copy.
 *
 *  no zargs used
 *
 */

void z_piracy (void)
{

    branch (!option_piracy);

}/* z_piracy */

/*
 * main
 *
 * Prepare and run the game.
 *
 */
#ifdef __GEOS__

word main ( word valueToPass )
{

#else

int cdecl main (int argc, char *argv[])
{
    os_process_arguments (argc, argv);

#endif
		/* jfh - if init fails then forget it */
		if (init_memory ()) {

			os_init_screen ();

			init_undo ();

			z_restart ();

			interpret ();
		/* on quitting, the program gose thru MSG_GEN...CLOSE_APP  then
		 * comes back here to dump this thread.  I need to try and get
		 * here first, huh?  */
			reset_memory ();

			os_reset_screen ();
			}

//		if (waitForFinished) ThreadVSem( waitForFinished );

	 /* we'll shut down if we've quit a game, but if we had a bad load
	  * (finished still = 0 ) we'll let the user try another game file. */
	 if (finished) FrotzDoQuit();

	 /* jfh - gotta destroy the zmachine thread */
	 ThreadDestroy(0,0,0);


	 return 0;

}/* main */
