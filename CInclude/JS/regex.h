/*************************************************
*       Perl-Compatible Regular Expressions      *
*************************************************/

/* Copyright (c) 1997-1999 University of Cambridge */

/* NOMBAS - Renamed file to regex.h */
/* NOMBAS - Merge with internal.h   */

#ifndef _PCRE_H
#define _PCRE_H

#include "jseopt.h"  /* NOMBAS */

#ifdef JSE_REGEXP_OBJECT  /* NOMBAS */

#define PCRE_VERSION       "2.06 21-Jun-1999"


/* This is a library of functions to support regular expressions whose syntax
and semantics are as close as possible to those of the Perl 5 language. See
the file Tech.Notes for some information on the internals.

Written by: Philip Hazel <ph10@cam.ac.uk>

           Copyright (c) 1997-1999 University of Cambridge

-----------------------------------------------------------------------------
Permission is granted to anyone to use this software for any purpose on any
computer system, and to redistribute it freely, subject to the following
restrictions:

1. This software is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

2. The origin of this software must not be misrepresented, either by
   explicit claim or by omission.

3. Altered versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

4. If PCRE is embedded in any software that is released under the GNU
   General Purpose Licence (GPL), then the terms of that licence shall
   supersede any condition above with which it is incompatible.
-----------------------------------------------------------------------------
*/

/* Options */

#define PCRE_CASELESS        0x0001
#define PCRE_MULTILINE       0x0002
#define PCRE_DOTALL          0x0004
#define PCRE_EXTENDED        0x0008
#define PCRE_ANCHORED        0x0010
#define PCRE_DOLLAR_ENDONLY  0x0020
#define PCRE_EXTRA           0x0040
#define PCRE_NOTBOL          0x0080
#define PCRE_NOTEOL          0x0100
#define PCRE_UNGREEDY        0x0200

/* Exec-time and get-time error codes */

#define PCRE_ERROR_NOMATCH        (-1)
#define PCRE_ERROR_NULL           (-2)
#define PCRE_ERROR_BADOPTION      (-3)
#define PCRE_ERROR_BADMAGIC       (-4)
#define PCRE_ERROR_UNKNOWN_NODE   (-5)
#define PCRE_ERROR_NOMEMORY       (-6)
#define PCRE_ERROR_NOSUBSTRING    (-7)

/* Types */

typedef void pcre;
typedef void pcre_extra;

/* Store get and free functions. These can be set to alternative malloc/free
functions if required. */

#if defined(JSE_MEM_DEBUG) && (0!=JSE_MEM_DEBUG)
   /* NOMBAS: code to add our own memory-debugging, catching bad allocs and frees, look
    * for JSE_MEM_DEBUG in the rest of this file for anywhere Nombas changed this
    */
#else
   /* the original code */
   extern void *(*pcre_malloc)(size_t);
   extern void  (*pcre_free)(void *);
#endif

/* Functions */

extern pcre *pcre_compile(const char *, int, const char **, int *,
  const unsigned char *);
extern int pcre_copy_substring(const char *, int *, int, int, char *, int);
extern int pcre_exec(const pcre *, const pcre_extra *, const char *,
  int, int, int, int *, int);
extern int pcre_get_substring(const char *, int *, int, int, const char **);
extern int pcre_get_substring_list(const char *, int *, int, const char ***);
extern int pcre_info(const pcre *, int *, int *);
extern unsigned const char *pcre_maketables(void);
extern pcre_extra *pcre_study(const pcre *, int, const char **);
extern const char *pcre_version(void);

/* This header contains definitions that are shared between the different
modules, but which are not relevant to the outside. */

/* To cope with SunOS4 and other systems that lack memmove() but have bcopy(),
define a macro for memmove() if USE_BCOPY is defined. */

#ifdef USE_BCOPY
#undef  memmove        /* some systems may have a macro */
#define memmove(a, b, c) bcopy(b, a, c)
#endif

/* Standard C headers plus the external interface definition */

/* NOMBAS Removed - included with jseopt.h
 * #include <ctype.h>
 * #include <limits.h>
 * #include <stddef.h>
 * #include <stdio.h>
 * #include <stdlib.h>
 * #include <string.h>
 */

/* In case there is no definition of offsetof() provided - though
 * any proper Standard C system should have one.
 */
/* NOMBAS change: on the Mac build, the Standard C definition
 * of offsetof comes after this and triggers an
 * "already-defined" error.
 */
#ifndef offsetof
#  define offsetof(p_type,field) ((size_t)&(((p_type *)0)->field))
#endif

/* These are the public options that can change during matching. */

#define PCRE_IMS (PCRE_CASELESS|PCRE_MULTILINE|PCRE_DOTALL)

/* Private options flags start at the most significant end of the two bytes.
The public options defined in pcre.h start at the least significant end. Make
sure they don't overlap! */

#define PCRE_FIRSTSET           0x8000  /* first_char is set */
#define PCRE_STARTLINE          0x4000  /* start after \n for multiline */
#define PCRE_INGROUP            0x2000  /* compiling inside a group */

/* Options for the "extra" block produced by pcre_study(). */

#define PCRE_STUDY_MAPPED   0x01     /* a map of starting chars exists */

/* Masks for identifying the public options which are permitted at compile
time, run time or study time, respectively. */

#define PUBLIC_OPTIONS \
  (PCRE_CASELESS|PCRE_EXTENDED|PCRE_ANCHORED|PCRE_MULTILINE| \
   PCRE_DOTALL|PCRE_DOLLAR_ENDONLY|PCRE_EXTRA|PCRE_UNGREEDY)

#define PUBLIC_EXEC_OPTIONS (PCRE_ANCHORED|PCRE_NOTBOL|PCRE_NOTEOL)

#define PUBLIC_STUDY_OPTIONS 0   /* None defined */

/* Magic number to provide a small check against being handed junk. */

#define MAGIC_NUMBER  0x50435245UL   /* 'PCRE' */

/* Miscellaneous definitions */

/* NOMBAS added #if and #endif statements */
#if !defined(__OS2__) && !defined(__JSE_PALMOS__)
typedef int BOOL;
#endif

/* NOMBAS Removed
 * #define FALSE   0
 * #define TRUE    1
 */

/* These are escaped items that aren't just an encoding of a particular data
value such as \n. They must have non-zero values, as check_escape() returns
their negation. Also, they must appear in the same order as in the opcode
definitions below, up to ESC_z. The final one must be ESC_REF as subsequent
values are used for \1, \2, \3, etc. There is a test in the code for an escape
greater than ESC_b and less than ESC_X to detect the types that may be
repeated. If any new escapes are put in-between that don't consume a character,
that code will have to change. */

enum { ESC_A = 1, ESC_B, ESC_b, ESC_D, ESC_d, ESC_S, ESC_s, ESC_W, ESC_w,
       ESC_Z, ESC_z, ESC_REF };

/* Opcode table: OP_BRA must be last, as all values >= it are used for brackets
that extract substrings. Starting from 1 (i.e. after OP_END), the values up to
OP_EOD must correspond in order to the list of escapes immediately above. */

enum {
  OP_END,            /* End of pattern */

  /* Values corresponding to backslashed metacharacters */

  OP_SOD,            /* Start of data: \A */
  OP_NOT_WORD_BOUNDARY,  /* \B */
  OP_WORD_BOUNDARY,      /* \b */
  OP_NOT_DIGIT,          /* \D */
  OP_DIGIT,              /* \d */
  OP_NOT_WHITESPACE,     /* \S */
  OP_WHITESPACE,         /* \s */
  OP_NOT_WORDCHAR,       /* \W */
  OP_WORDCHAR,           /* \w */
  OP_EODN,           /* End of data or \n at end of data: \Z. */
  OP_EOD,            /* End of data: \z */

  OP_OPT,            /* Set runtime options */
  OP_CIRC,           /* Start of line - varies with multiline switch */
  OP_DOLL,           /* End of line - varies with multiline switch */
  OP_ANY,            /* Match any character */
  OP_CHARS,          /* Match string of characters */
  OP_NOT,            /* Match anything but the following char */

  OP_STAR,           /* The maximizing and minimizing versions of */
  OP_MINSTAR,        /* all these opcodes must come in pairs, with */
  OP_PLUS,           /* the minimizing one second. */
  OP_MINPLUS,        /* This first set applies to single characters */
  OP_QUERY,
  OP_MINQUERY,
  OP_UPTO,           /* From 0 to n matches */
  OP_MINUPTO,
  OP_EXACT,          /* Exactly n matches */

  OP_NOTSTAR,        /* The maximizing and minimizing versions of */
  OP_NOTMINSTAR,     /* all these opcodes must come in pairs, with */
  OP_NOTPLUS,        /* the minimizing one second. */
  OP_NOTMINPLUS,     /* This first set applies to "not" single characters */
  OP_NOTQUERY,
  OP_NOTMINQUERY,
  OP_NOTUPTO,        /* From 0 to n matches */
  OP_NOTMINUPTO,
  OP_NOTEXACT,       /* Exactly n matches */

  OP_TYPESTAR,       /* The maximizing and minimizing versions of */
  OP_TYPEMINSTAR,    /* all these opcodes must come in pairs, with */
  OP_TYPEPLUS,       /* the minimizing one second. These codes must */
  OP_TYPEMINPLUS,    /* be in exactly the same order as those above. */
  OP_TYPEQUERY,      /* This set applies to character types such as \d */
  OP_TYPEMINQUERY,
  OP_TYPEUPTO,       /* From 0 to n matches */
  OP_TYPEMINUPTO,
  OP_TYPEEXACT,      /* Exactly n matches */

  OP_CRSTAR,         /* The maximizing and minimizing versions of */
  OP_CRMINSTAR,      /* all these opcodes must come in pairs, with */
  OP_CRPLUS,         /* the minimizing one second. These codes must */
  OP_CRMINPLUS,      /* be in exactly the same order as those above. */
  OP_CRQUERY,        /* These are for character classes and back refs */
  OP_CRMINQUERY,
  OP_CRRANGE,        /* These are different to the three seta above. */
  OP_CRMINRANGE,

  OP_CLASS,          /* Match a character class */
  OP_REF,            /* Match a back reference */

  OP_ALT,            /* Start of alternation */
  OP_KET,            /* End of group that doesn't have an unbounded repeat */
  OP_KETRMAX,        /* These two must remain together and in this */
  OP_KETRMIN,        /* order. They are for groups the repeat for ever. */

  /* The assertions must come before ONCE and COND */

  OP_ASSERT,         /* Positive lookahead */
  OP_ASSERT_NOT,     /* Negative lookahead */
  OP_ASSERTBACK,     /* Positive lookbehind */
  OP_ASSERTBACK_NOT, /* Negative lookbehind */
  OP_REVERSE,        /* Move pointer back - used in lookbehind assertions */

  /* ONCE and COND must come after the assertions, with ONCE first, as there's
  a test for >= ONCE for a subpattern that isn't an assertion. */

  OP_ONCE,           /* Once matched, don't back up into the subpattern */
  OP_COND,           /* Conditional group */
  OP_CREF,           /* Used to hold an extraction string number */

  OP_BRAZERO,        /* These two must remain together and in this */
  OP_BRAMINZERO,     /* order. */

  OP_BRA             /* This and greater values are used for brackets that
                        extract substrings. */
};

/* The highest extraction number. This is limited by the number of opcodes
left after OP_BRA, i.e. 255 - OP_BRA. We actually set it somewhat lower. */

#define EXTRACT_MAX  99

/* The texts of compile-time error messages are defined as macros here so that
they can be accessed by the POSIX wrapper and converted into error codes.  Yes,
I could have used error codes in the first place, but didn't feel like changing
just to accommodate the POSIX wrapper. */

#define ERR1  "\\ at end of pattern"
#define ERR2  "\\c at end of pattern"
#define ERR3  "unrecognized character follows \\"
#define ERR4  "numbers out of order in {} quantifier"
#define ERR5  "number too big in {} quantifier"
#define ERR6  "missing terminating ] for character class"
#define ERR7  "invalid escape sequence in character class"
#define ERR8  "range out of order in character class"
#define ERR9  "nothing to repeat"
#define ERR10 "operand of unlimited repeat could match the empty string"
#define ERR11 "internal error: unexpected repeat"
#define ERR12 "unrecognized character after (?"
#define ERR13 "too many capturing parenthesized sub-patterns"
#define ERR14 "missing )"
#define ERR15 "back reference to non-existent subpattern"
#define ERR16 "erroffset passed as NULL"
#define ERR17 "unknown option bit(s) set"
#define ERR18 "missing ) after comment"
#define ERR19 "too many sets of parentheses"
#define ERR20 "regular expression too large"
#define ERR21 "failed to get memory"
#define ERR22 "unmatched parentheses"
#define ERR23 "internal error: code overflow"
#define ERR24 "unrecognized character after (?<"
#define ERR25 "lookbehind assertion is not fixed length"
#define ERR26 "malformed number after (?("
#define ERR27 "conditional group contains more than two branches"
#define ERR28 "assertion expected after (?("

/* All character handling must be done as unsigned characters. Otherwise there
are problems with top-bit-set characters and functions such as isspace().
However, we leave the interface to the outside world as char *, because that
should make things easier for callers. We define a short type for unsigned char
to save lots of typing. I tried "uchar", but it causes problems on Digital
Unix, where it is defined in sys/types, so use "uschar" instead. */

typedef unsigned char uschar;

/* The real format of the start of the pcre block; the actual code vector
runs on as long as necessary after the end. */

typedef struct real_pcre {
  unsigned long int magic_number;
  const unsigned char *tables;
  unsigned short int options;
  unsigned char top_bracket;
  unsigned char top_backref;
  unsigned char first_char;
  unsigned char code[1];
} real_pcre;

/* The real format of the extra block returned by pcre_study(). */

typedef struct real_pcre_extra {
  unsigned char options;
  unsigned char start_bits[32];
} real_pcre_extra;


/* Structure for passing "static" information around between the functions
doing the compiling, so that they are thread-safe. */

typedef struct compile_data {
  const uschar *lcc;            /* Points to lower casing table */
  const uschar *fcc;            /* Points to case-flippint table */
  const uschar *cbits;          /* Points to character type table */
  const uschar *ctypes;         /* Points to table of type maps */
} compile_data;

/* Structure for passing "static" information around between the functions
doing the matching, so that they are thread-safe. */

typedef struct match_data {
  int    errorcode;             /* As it says */
  int   *offset_vector;         /* Offset vector */
  int    offset_end;            /* One past the end */
  int    offset_max;            /* The maximum usable for return data */
  const uschar *lcc;            /* Points to lower casing table */
  const uschar *ctypes;         /* Points to table of type maps */
  BOOL   offset_overflow;       /* Set if too many extractions */
  BOOL   notbol;                /* NOTBOL flag */
  BOOL   noteol;                /* NOTEOL flag */
  BOOL   endonly;               /* Dollar not before final \n */
  const uschar *start_subject;  /* Start of the subject string */
  const uschar *end_subject;    /* End of the subject string */
  const uschar *end_match_ptr;  /* Subject position at end match */
  int     end_offset_top;       /* Highwater mark at end of match */
} match_data;

/* Bit definitions for entries in the pcre_ctypes table. */

#define ctype_space   0x01
#define ctype_letter  0x02
#define ctype_digit   0x04
#define ctype_xdigit  0x08
#define ctype_word    0x10   /* alphameric or '_' */
#define ctype_meta    0x80   /* regexp meta char or zero (end pattern) */

/* Offsets for the bitmap tables in pcre_cbits. Each table contains a set
of bits for a class map. */

#define cbit_digit    0      /* for \d */
#define cbit_word    32      /* for \w */
#define cbit_space   64      /* for \s */
#define cbit_length  96      /* Length of the cbits table */

/* Offsets of the various tables from the base tables pointer, and
total length. */

#define lcc_offset      0
#define fcc_offset    256
#define cbits_offset  512
#define ctypes_offset (cbits_offset + cbit_length)
#define tables_length (ctypes_offset + 256)

/* End of internal.h */

/* Have to include stdlib.h in order to ensure that size_t is defined;
it is needed here for malloc. */

/* NOMBAS Removed - included with jseopt.h
 * #include <sys/types.h>
 * #include <stdlib.h>
  */
/* Allow for C++ users */

/* NOMBAS Removed
 * #ifdef __cplusplus
 * extern "C" {
 * #endif
 */

/* NOMBAS - Include POSIX interface */
/* This is the header for the POSIX wrapper interface to the PCRE Perl-
Compatible Regular Expression library. It defines the things POSIX says should
be there. I hope. */

/* Have to include stdlib.h in order to ensure that size_t is defined. */

#include <ansi/stdlib.h>

/* Allow for C++ users */

#ifdef __cplusplus
extern "C" {
#endif

/* Options defined by POSIX. */

#define REG_ICASE     0x01
#define REG_NEWLINE   0x02
#define REG_NOTBOL    0x04
#define REG_NOTEOL    0x08

/* Error values. Not all these are relevant or used by the wrapper. */

enum {
  REG_ASSERT = 1,  /* internal error ? */
  REG_BADBR,       /* invalid repeat counts in {} */
  REG_BADPAT,      /* pattern error */
  REG_BADRPT,      /* ? * + invalid */
  REG_EBRACE,      /* unbalanced {} */
  REG_EBRACK,      /* unbalanced [] */
  REG_ECOLLATE,    /* collation error - not relevant */
  REG_ECTYPE,      /* bad class */
  REG_EESCAPE,     /* bad escape sequence */
  REG_EMPTY,       /* empty expression */
  REG_EPAREN,      /* unbalanced () */
  REG_ERANGE,      /* bad range inside [] */
  REG_ESIZE,       /* expression too big */
  REG_ESPACE,      /* failed to get memory */
  REG_ESUBREG,     /* bad back reference */
  REG_INVARG,      /* bad argument */
  REG_NOMATCH      /* match failed */
};


/* The structure representing a compiled regular expression. */

typedef struct {
  void *re_pcre;
  size_t re_nsub;
  size_t re_erroffset;
} regex_t;

/* The structure in which a captured offset is returned. */

typedef int regoff_t;

typedef struct {
  regoff_t rm_so;
  regoff_t rm_eo;
} regmatch_t;

/* The functions */

/* NOMBAS: ecma_ was added to these functions to avoid link conflicts */
extern int ecma_regcomp(regex_t *, const char *, int);
extern int ecma_regexec(regex_t *, const char *, size_t, regmatch_t *, int);
extern size_t ecma_regerror(int, const regex_t *, char *, size_t);
extern void ecma_regfree(regex_t *);

#ifdef __cplusplus
}
#endif

#endif /* NOMBAS */

#endif /* End of pcre.h */
