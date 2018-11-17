/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  pmake
 * FILE:	  pmjob.h
 *
 * AUTHOR:  	  Tim Bradley: June 20, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	6/20/96   	Initial version
 *
 * DESCRIPTION:
 *	Prototypes for the job.c file.  See also job.h
 *
 *
 * 	$Id: pmjob.h,v 1.1 96/06/24 15:06:35 tbradley Exp $
 *
 ***********************************************************************/
#ifndef _PMJOB_H_
#define _PMJOB_H_

#include    <sys/types.h>
#include    <sys/stat.h>
#include    <ctype.h>
#include    "make.h"

#if defined(unix)
#    include <compat/file.h>
#    define TMPPAT "/tmp/makeXXXXX"
#endif /* defined(unix) */

#if defined(_WIN32)
#    include <windows.h>      /* for HANDLE type */
#    define TMPPAT "C:\\temp\\makeXXXXX"
#endif /* defined(_WIN32) */

/*-
 * Job Table definitions.
 *
 * Each job has several things associated with it:
 *      1) The process id of the child shell
 *      2) The graph node describing the target being made by this job
 *      3) A LstNode for the first command to be saved after the job
 *         completes. This is NILLNODE if there was no "..." in the job's
 *         commands.
 *      4) An FILE* for writing out the commands. This is only
 *         used before the job is actually started.
 *      5) A union of things used for handling the shell's output. Different
 *         parts of the union are used based on the value of the usePipes
 *         flag. If it is true, the output is being caught via a pipe and
 *         the descriptors of our pipe, an array in which output is line
 *         buffered and the current position in that buffer are all
 *         maintained for each job. If, on the other hand, usePipes is false,
 *         the output is routed to a temporary file and all that is kept
 *         is the name of the file and the descriptor open to the file.
 *      6) An identifier provided by and for the exclusive use of the
 *         Rmt module.
 *      7) A word of flags which determine how the module handles errors,
 *         echoing, etc. for the job
 *
 * The job "table" is kept as a linked Lst in 'jobs', with the number of
 * active jobs maintained in the 'nJobs' variable. At no time will this
 * exceed the value of 'maxJobs', initialized by the Job_Init function.
 *
 * When a job is finished, the Make_Update function is called on each of the
 * parents of the node which was just remade. This takes care of the upward
 * traversal of the dependency graph.
 */
#define JOB_BUFSIZE     1024
typedef struct Job {
#if defined(unix)
    int
#else /* _WIN32 */
    PROCESS_INFORMATION
#endif /* defined(unix) */
                         pid;        /* The child's process ID */
    GNode               *node;       /* The target the child is making */
    LstNode              tailCmds;   /* The node of the first command to be
				      * saved when the job has been run */
#if defined(unix)
    FILE                *cmdFILE;    /* When creating the shell script, this is
				      * where the commands go */
    char                *rmtID;      /* ID returned from Rmt module */
#else /* WIN32 */
    HANDLE		cmdOUT;
#endif /* defined(unix) */

    unsigned short       flags;      /* Flags to control treatment of job */
#define JOB_IGNERR      ((short) 0x001)   /* Ignore non-zero exits */
#define JOB_SILENT      ((short) 0x002)   /* no output */
#define JOB_SPECIAL     ((short) 0x004)   /* Target is a special one. i.e.
					   * run it locally
					   * if we can't export it and
					   * maxLocal is 0 */
#define JOB_IGNDOTS     ((short) 0x008)   /* Ignore "..." lines when processing
					   * commands */
#define JOB_REMOTE      ((short) 0x010)   /* Job is running remotely */
#define JOB_FIRST       ((short) 0x020)   /* Job is first job for the node */
#define JOB_REMIGRATE   ((short) 0x040)   /* Job needs to be remigrated */
#define JOB_RESTART     ((short) 0x080)   /* Job needs to be completely
					   * restarted */
#define JOB_RESUME      ((short) 0x100)   /* Job needs to be resumed b/c it
					   * stopped,
					   * for some reason */
#define JOB_CONTINUING  ((short) 0x200)   /* We are in the process of resuming
					   * this job.
					   * Used to avoid infinite recursion
					   * between
					   * JobFinish and JobRestart */
#define JOB_OUTPUT_SET  ((short) 0x400)   /* Output streams setup */
#if defined(unix)
    union {
        struct {
	    int         op_inPipe,      /* Input side of pipe associated
                                         * with job's output channel */
                        op_outPipe;     /* Output side of pipe associated with
                                         * job's output channel */
            char        op_outBuf[JOB_BUFSIZE + 1];
                                        /* Buffer for storing the output of the
                                         * job, line by line */
            int         op_curPos;      /* Current position in op_outBuf */
        }           o_pipe;          /* data used when catching the output via
                                      * a pipe */
        struct {
            char        of_outFile[sizeof(TMPPAT)+2];
                                        /* Name of file to which shell output
                                         * was rerouted */
            int     of_outFd;       /* Stream open to the output
                                     * file. Used to funnel all output
                                     * from a single job to one file
                                     * while still allowing
                                     * multiple shell invocations */
        }           o_file;         /* Data used when catching the output in
                                     * a temporary file */
    }           output;     /* Data for tracking a shell's output */
#endif /* defined(unix) */
} Job;

#if defined(unix)
#    define outPipe	  output.o_pipe.op_outPipe
#    define inPipe	  output.o_pipe.op_inPipe
#    define outBuf	  output.o_pipe.op_outBuf
#    define curPos	  output.o_pipe.op_curPos
#    define outFile	  output.o_file.of_outFile
#    define outFd	  output.o_file.of_outFd
#endif /* defined(unix) */

typedef void AbortMsg (char *fmt, ...);

extern Boolean      Job_CheckCommands   (GNode *gn, AbortMsg abortProc);
extern Boolean      Job_Full            (void);
extern Boolean      Job_Empty           (void);

extern int          Job_End             (void);

extern ReturnStatus Job_ParseShell      (char *line);

#if defined(unix)
extern void         Job_CatchChildren   (Boolean block);
extern void         Job_CatchOutput     (void);
#else /* _WIN32 */
extern void         Job_NTCatchOutput   (void);
extern void         Job_NTCatchChildren (unsigned long block);

#define  JOB_WAIT_TIMEOUT INFINITE /* value passed to Job_NTCatchChildren
				    * to determine how long it should block
				    * while waiting for children */

#endif /* defined(unix) */

extern void         Job_Touch           (GNode *gn, Boolean silent);
extern void         Job_Make            (GNode *gn);
extern void         Job_Init            (int maxproc, int maxlocal);
extern void         Job_Wait            (void);
extern void         Job_AbortAll        (void);

#endif _PMJOB_H_
