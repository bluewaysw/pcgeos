/* Allow this file to be included multiple times
   with different settings of NDEBUG.  */
/* $Id: assert.h,v 1.1 91/04/26 12:35:38 adam Exp $ */

#undef assert
#undef __assert

#ifdef NDEBUG
# define assert(ignore)
#else

# define assert(expression)  \
  ((expression) ? (void) 0 : __assert (#expression, __FILE__, __LINE__))

# if defined(__GNUC__)
void __eprintf ();		/* Defined in gnulib */
# else
#  if !defined(stderr)
#  include <stdio.h>
#  endif
#  if defined(__STDC__)
#   define __eprintf(str,line) fprintf(stderr, str, line)
#  else
#   define __eprintf(str,line,file) fprintf(stderr, str, line, file)
#  endif
# endif

# ifdef __STDC__

extern void abort();

# define __assert(expression, file, line)  \
  (__eprintf ("Failed assertion " expression		\
	      " at line %d of `" file "'.\n", line),	\
   abort ())

# else /* no __STDC__; i.e. -traditional.  */

# define __assert(expression, file, line)  \
  (__eprintf ("Failed assertion at line %d of `%s'.\n", line, file),	\
   abort ())

# endif /* no __STDC__; i.e. -traditional.  */

#endif
