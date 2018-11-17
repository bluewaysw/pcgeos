#ifndef __CONFIG_H
#define __CONFIG_H

/* Integer 16bit type */
#define INT16 int

/* Integer 32bit type */
#define INT32 long

/* The number of bytes in a int.  */
#define SIZEOF_INT 2

/* The number of bytes in a long.  */
#define SIZEOF_LONG 4

/* The number of bytes in a short.  */
#define SIZEOF_SHORT 2

/* Define to return error messages by callback */
#define EPH_ERROR 1

/* Define to write diagnostic messages to a log file */
#define DEBUG 1

#ifdef DEBUG
void printf(const char *format, ...);
#define EPH_ERROR  1
#endif

#include <geos.h>
#include <heap.h>
#include <geode.h>
#include <resource.h>
#include <file.h>
#include <object.h>
#include <timer.h>
#include <driver.h>
#include <streamC.h>
#include <Ansi/stdio.h>
#include <Ansi/stdlib.h>
#include <Ansi/string.h>

#endif
