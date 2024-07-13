/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Gandalf
MODULE:		Main (builder shell)
FILE:		main.h

AUTHOR:		Paul L. DuBois, Feb 17, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 2/17/95	Initial version.

DESCRIPTION:
	Function defn's used internally in the Main module

	$Id: main.h,v 1.2 98/10/13 22:18:14 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _MAIN_H_
#define _MAIN_H_

/* Have Basco pop up a compile error dialog, then display
 * erroneous line
 */
extern void GandalfCompileError(MemHandle comTask);

/* Pop up a simple error dialog box; deals with locking & unlocking string
 */
extern void GandalfError(optr errorString);

extern void UpdateLastLoadedButton();

extern void EmitStandardInclude(MemHandle, word flags, TCHAR* line);
extern void EmitLoadModule(MemHandle task, TCHAR* line);


#define doLineAdd(task, line, string) sprintf(&line[1], string); BascoLineAdd(task, line);
#define doBlockAdd(task, block, string) sprintf(&block[1], string); BascoBlockAdd(task, block);

#endif /* _MAIN_H_ */
