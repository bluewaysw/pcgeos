/***********************************************************************
 *
 *	Copyright (c) Geoworks 1998.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  WWW2 Library
 * MODULE:	  WW2Core
 * FILE:	  cmd.h
 *
 * AUTHOR:  	  Allen Yuen: Aug 17, 1998
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	allen   	8/17/98   	Initial version
 *
 * DESCRIPTION:
 *
 *	Command class for callback.
 *      //depot/liberty/project/ellery/980805/library/www/wwcore/cmd.h#1
 *
 *	$Id: //depot/pcgeos/CInclude/WWW2/WW2Core/cmd.h#1 $
 *
 ***********************************************************************/
#ifndef _CMD_H_
#define _CMD_H_



/***************************************************************************
CLASS
    Command

    Command are callback objects.

KEYWORDS

CLASS TREE
<pre>
    Command
</pre>
****************************************************************************/
typedef struct Command {
    //////////
    //
    // Main processing.
    //
    // Parameters_
    //
    // [out] 
    // [in]  
    //
    // Return_value_ 
    //
    // See_also_ 
    //
    // Overrides_
    //
    // Status_ Functional
    //
    void (*Destructor) (struct Command *pself);
    void (*Execute) (struct Command *pself);
    void (*Preempt) (struct Command *pself);
    void (*Done) (struct Command *pself);
} Command;

    //////////
    //
    // Execute a command object. This function is provided for 
    // client to run a command from a different thread.
    //
    // Parameters_
    //
    // [out] 
    // [in]  cmd    Comand to be executed.
    //
    // Return_value_ 
    //
    // See_also_ 
    //
    // Overrides_
    //
    // Status_ Functional
    //
word ExecuteCommand(MemHandle cmdPtrHptr);



/***************************************************************************
CLASS
    Command with arguments.

    This is similar to Command class, but it takes arguments and returns
    a value. The arguments and return value are similar to that the 
    signature of C main routine:

    int main(int argc, char *argv[]) {...}

    We added two more arguments for return values:

    int CommandArg::ExecuteArg(int argc, char *argv[], 
                               int argr, char *argrv[]);

KEYWORDS

CLASS TREE
<pre>
    CommandArg
</pre>
****************************************************************************/
typedef struct {

    //////////
    //
    // Execute a command object that takes arguments. 
    //
    // Parameters_
    //
    // [in]  cmd    Command to be executed.
    // [in]  argc   Number of arguments in argv.
    // [in]  argv   Array of void pointers.
    // [in]  argr   Number of arguments in argrv expected from callee.
    // [out] argrv  Array of char pointers. If the return value is non-zero,
    //              the pointer data will be freed by caller of this routine 
    //              via "delete []..." on each of the argrv[] element for argr
    //              number of elements.
    //
    // Return_value_ Defined by the derived classes.
    //
    // See_also_ Command
    //
    // Overrides_
    //
    // Status_ Functional
    //
    int (*Execute) (int argc, const char *argv[], 
                        int argr, char *argrv[]) /* = 0 */;

} CommandArg;

    //////////
    //
    // Execute a command object that takes arguments. 
    //
    // Parameters_
    //
    // [in]  cmd    Command to be executed.
    // [in]  argc   Number of arguments in argv.
    // [in]  argv   Array of void pointers.
    // [in]  argr   Number of arguments in argrv expected from callee.
    // [out] argrv  Array of void pointers. The pointers will be freed
    //              by caller of this routine via "delete []...".
    //
    // Return_value_ int, return value from Cmd::ExecuteArg(...).
    //
    // See_also_ Command
    //
    // Overrides_
    //
    // Status_ Functional
    //
int ExecuteCommandArg(CommandArg *cmd, 
                      int argc, const char *argv[],
                      int argr, char *argrv[]);

#endif /* _CMD_H_ */
