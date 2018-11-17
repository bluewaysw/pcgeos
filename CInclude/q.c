/*
 * This file is used to test .goh files to ensure that they compile.  Be sure
 * to test whether a file compiles individually as well as with all the
 * others.
 *
 * Helpful aliases:
 *	alias hc /staff/pcgeos/Tools/highc/bin/hcdx86
 *	alias hcg "hc -c -g -Hnocopyr -Hnopro -Mb"
 *	alias hci "hc -c -g -Hnocopyr -Hnopro -Mb -I/n/mo/pcgeos/tony/CInclude
 *				-I/staff/pcgeos/CInclude"
 *
 *	(remember to replace "tony" with your username)
 *
 * To test, type: hci q.c
 *
 *	$Id: q.c,v 1.1 97/04/04 15:58:14 newdeal Exp $
 *
 */

/*	 file			   uses */
/*	 ----			   ---- */

#include <geos.h>

#if 1

/*	Kernel .h files */

#include <ec.h>
#include <heap.h>
#include <lmem.h>
#include <file.h>
#include <geode.h>
#include <resource.h>
#include <object.h>
#include <fileStr.h>		/* file.h, geode.h */
#include <fileEnum.h>		/* fileStr.h */
#include <driver.h>		/* lmem.h */
#include <library.h>
#include <sem.h>
#include <thread.h>		/* object.h */
#include <timer.h>
#include <vm.h>			/* fileStr.h */
#include <dbase.h>		/* vm.h */
#include <drive.h>
#include <disk.h>		/* file.h, drive.h */
#include <system.h>		/* geode.h */
#include <sysstats.h>
#include <timedate.h>
#include <initfile.h>
#include <char.h>
#include <input.h>		/* char.def */
#include <localize.h>		/* timedate.h */
#include <lexical.h>
#include <fontID.h>
#include <font.h>		/* fontID.h */
#include <graphics.h>		/* fontID.h */
#include <gstring.h>		/* graphics.h */
#include <chunkarr.h>
#include <hugearr.h>
#include <geoworks.h>
#include <uDialog.h>

#endif

