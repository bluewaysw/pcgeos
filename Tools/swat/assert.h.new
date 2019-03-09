/* Allow this file to be included multiple times
   with different settings of NDEBUG.  */
#undef assert
#undef __assert

#ifdef NDEBUG
#define assert(ignore)
#else

#define assert(expression)  \
  ((expression) ? 0 : __assert (#expression, __FILE__, __LINE__))

void __eprintf ();		/* Defined in gnulib */

#ifdef __STDC__

#define __assert(expression, file, line)  \
  (__eprintf ("Failed assertion " expression		\
	      " at line %d of `" file "'.\n", line),	\
   abort ())

#else /* no __STDC__; i.e. -traditional.  */

#define __assert(expression, file, line)  \
  (__eprintf ("Failed assertion at line %d of `%s'.\n", line, file),	\
   abort ())

#endif /* no __STDC__; i.e. -traditional.  */

#endif
