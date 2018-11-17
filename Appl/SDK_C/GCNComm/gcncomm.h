/********************************************************************
 *
 *      Copyright (c) Geoworks, Inc. 1996 -- All Rights Reserved.
 *
 * PROJECT:     GEOS Sample Applications
 * MODULE:      GCNComm/Common Header
 * FILE:        gcncomm.h
 *
 * AUTHOR:      Nathan Fiedler: December 13, 1996
 *
 * REVISION HISTORY:
 *      Name    Date            Description
 *      ----    ----            -----------
 *      NF      12/13/96        Initial version
 *
 * DESCRIPTION:
 *      This sample application demonstrates how to use GCN lists
 *      to establish a way to communicate between two applications.
 *
 *      There are two parts to this sample. The first part is the
 *      Server app. It is a simple program that simply waits to
 *      receive a notification from another program. The other
 *      program in this sample is Client. This program is what
 *      will send the notification to the Server.
 *
 *      The process begins when the Server app creates a system GCN
 *      list for itself and puts it's process object on that list,
 *      using GCNListAdd. Any notifications sent to that list will
 *      be received by the Server process object. The Server then
 *      sits and waits for something to happen.
 *
 *      The Client app is then launched by the user, and upon
 *      input from the user, it will send a notification to the
 *      Server application. It does this by recording an event
 *      using @record, then calling GCNListSend. Because the
 *      Server's GCN list is a system GCN list, any geode can send
 *      notification messages to it.
 *
 *      This header file contains the GCN list definitions common
 *      to both the Client and Server applications. Without this
 *      common header file the Client application would not know
 *      what GCN list and notification type to use when sending
 *      to the Server application.
 *
 *      In these definitions we're going to use a made-up company
 *      name "My Company". When writing your app you can substitute
 *      "MY_COMPANY" with the name of your company.
 *
 * RCS STAMP:
 *      $Id: gcncomm.h,v 1.1 97/04/04 16:41:51 newdeal Exp $
 *
 *******************************************************************/

/********************************************************************
 *              Constants
 *******************************************************************/
      /*
       * Define our manufacturer ID number. In this
       * case we're using the one for the sample apps (8).
       * It's important that you use a unique ID, otherwise
       * you run the risk of defining GCN notifications
       * that look identical to other notifications passing
       * through the system. For certain, you would not want
       * to use MANUFACTURER_ID_GEOWORKS, since that has
       * many common notification types and you would be
       * overlapping those list types if you used an ID of
       * MANUFACTURER_ID_GEOWORKS.
       *
       * If you do not have a manufacturer ID, please contact
       * Geoworks (by sending email to orders@geoworks.com)
       * and we will assign one to you.
       */
    #define MANUFACTURER_ID_MY_COMPANY 8

/********************************************************************
 *              Data Types
 *******************************************************************/
      /*
       * Create a group of Notification types to use
       * for your manufacturer ID. In this sample we
       * are only defining one, as that is all we need.
       * You could define more, one for each kind of
       * "message" you want to send from one app to
       * the other.
       */
    typedef enum {
        MY_COMPANY_NT_SAMPLE_NOTIFICATION
    } MyCompanyNotificationTypes;

      /*
       * Create whatever notification list types you need.
       * These list types usually correspond one-to-one to the
       * types enumerated above. It is possible, however, for
       * several lists to be interested in a single notification type.
       */
    typedef enum {
        MY_COMPANY_GCNLT_SAMPLE_LIST
    } MyCompanyGCNSystemListTypes;

