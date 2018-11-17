/* varcall.h      Handles calling run-time linked functions with variable parameters
 */

/* (c) COPYRIGHT 1993-98           NOMBAS, INC.
 *                                 64 SALEM ST.
 *                                 MEDFORD, MA 02155  USA
 *
 * ALL RIGHTS RESERVED
 *
 * This software is the property of Nombas, Inc. and is furnished under
 * license by Nombas, Inc.; this software may be used only in accordance
 * with the terms of said license.  This copyright notice may not be removed,
 * modified or obliterated without the prior written permission of Nombas, Inc.
 *
 * This software is a Trade Secret of Nombas, Inc.
 *
 * This software may not be copied, transmitted, provided to or otherwise made
 * available to any other person, company, corporation or other entity except
 * as specified in the terms of said license.
 *
 * No right, title, ownership or other interest in the software is hereby
 * granted or transferred.
 *
 * The information contained herein is subject to change without notice and
 * should not be construed as a commitment by Nombas, Inc.
 */

#ifndef _VARCALL_H
#define _VARCALL_H
#ifdef __cplusplus
   extern "C" {
#endif

/* These routines give a pretty generic way to call any function with a
 * variable number of parameters. The only restrictions are that all
 * parameters are promoted to 4 bytes and that all called functions are
 * expecting parameters in the standard 'C' way.
 */

#define VARCALL_MAX_PARAMS 20

typedef ulong (JSE_CFUNC FAR_CALL *varcall_call)
     (ulong,ulong,ulong,ulong,ulong,ulong,ulong,ulong,ulong,ulong,
      ulong,ulong,ulong,ulong,ulong,ulong,ulong,ulong,ulong,ulong);


struct varcall
{
  void *proc_addr;
  int num_params;
  ulong params[VARCALL_MAX_PARAMS];
};

#define varcallInit(this,proc) ((this)->proc_addr = (proc),(this)->num_params = 0)
#define varcallAddParam(this,param) if( (this)->num_params<VARCALL_MAX_PARAMS ) (this)->params[(this)->num_params++] = (param)
#define varcallReadParam(this,param) ((this)->params[param])
#define varcallCall(this) ((varcall_call)(this)->proc_addr)\
    ( (this)->params[0],(this)->params[1],(this)->params[2],(this)->params[3], \
      (this)->params[4],(this)->params[5],(this)->params[6],(this)->params[7],\
      (this)->params[8],(this)->params[9],(this)->params[10],(this)->params[11],\
      (this)->params[12],(this)->params[13],(this)->params[14],(this)->params[15],\
      (this)->params[16],(this)->params[17],(this)->params[18],(this)->params[19]\
    )

/* ---------------------------------------------------------------------- */

#ifdef __cplusplus
}
#endif
#endif
