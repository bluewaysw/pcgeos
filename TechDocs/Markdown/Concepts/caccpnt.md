# 26 Access Point Library

The Access Point library acts as a sort of special address book--it keeps track of phone numbers and other information about Internet Service Providers. It can also store information about Terminal and Telnet access points. The library provides UI gadgetry by which the user may choose and edit access point entries; the library also provides routines by which programs may do the same.


## 26.1 Access Points

Access points, loosely defined, are collections of data useful for making communications connections. The Access Point library keeps track of access points by storing their information in the .INI file.

The library defines a few kinds of access points, identified by the `AccessPointType` enumerated type:

APT\_INTERNET

This access point holds data useful for connecting to an ISP. Applications making a PPP connection can use this information to make the connection.

APT\_TERMINAL

This access point holds data useful for connecting to a dialup terminal.

APT\_TELNET

This access point holds data useful for making a telnet connection.

For each access point, the AccessPoint library may keep track of any number of properties. While you may store all sorts of information about any access point, there are a number of standard properties, enumerated as `AccessPointStandardProperty` values, including name, phone number, user ID, address, and password.

Access points are referenced by word-length ID numbers.



## 26.2 Letting The User Choose

The Talk sample application shows how an application can use an AccpntControl object to provide UI for picking an access point. This example is discussed in [the Socket library documentation](csocket.md). The application also shows how to use the selected access point (in this case, an ISP) to establish a PPP connection; this part of the application is discussed further in the Socket chapter.

In this example, the controller is declared:

```
			@chunk char accpntMkr[] = "Access List";

			@object AccessPointControlClass AccpntControl = {
			    GI_states = GS_USABLE | GS_ENABLED;
			    ATTR_ACCESS_POINT_CONTROL_LIST_MONIKER = @accpntMkr;
			    HINT_ACCESS_POINT_CONTROL_MINIMIZE_SIZE;
			}
```

To present the user with a different type of access points (telnet connections, for example) set the type in the `APCI_type` instance data field:

```
@object AccessPointControlClass AccpntControl = {
    ...
    APCI_type = APT_TELNET;
}
```

You may wish to set up your program's UI such that there is a gadget which will not be enabled (will be grayed out) if there are no access points of the proper type defined. To do this, turn off the object's GS\_ENABLED flag in its declaration, and use the object's optr as the value of the `APCI_enableDisable` instance field:

```
@object ... MyObject = {
    ...
    GI_states = @default & ~GS_ENABLED;
}

@object AccessPointControlClass AccpntControl = {
    ...
    APCI_enableDisable = @MyObject;
}
```

To find out the ID number of the controller's currently selected access point, use `MSG_ACCESS_POINT_CONTROL_GET_SELECTION` .

To find out when the user has selected an access point (changed their selection), you have to be a bit trickier.

- Subclass `AccessPointControlClass` .
- Write a method for your subclass, intercepting MSG\_ACCESS\_POINT\_CONTROL\_UPDATE\_SELECTION. Be sure to use @callsuper to invoke the default handler for this message.
- Use an object of your subclass instead of a regular AccessPointControl object.

While the application is using the selected access point, it can "lock" the access point to prevent the access point's parameters from being modified while it's in use. (See [Locking and Unlocking](#264-locking-and-unlocking).)


### 26.2.1 Multiple-Selection Access Point Controllers

Recent versions of the Access Point library support controllers which allow the user to select more than one access point at a time. This feature is available on devices with version numbers "Responder Build 4...." and higher. See "Software Version Number" in the Nokia 9000 documentation for information about finding out the software version of the user's device.

To create such an `AccpntControl` object, give it the hint `HINT_ACCESS_POINT_CONTROL_MULTISELECTABLE`. To get a list of the currently selected access points, use `MSG_ACCESS_POINT_CONTROL_GET_MULTIPLE_SELECTIONS`. The prototype for this message is:

```
@message word MSG_ACCESS_POINT_CONTROL_GET_MULTIPLE_SELECTIONS(
                          word    *buffer,
                          word     maxIDs);
```

**buffer**

A buffer in which to store the IDs of the currently selected access point entries.

**maxIDs**

The number of selections to place in *buffer*. Use `MSG_ACCESS_POINT_CONTROL_GET_NUM_SELECTIONS` to get the number of currently selected entries.


## 26.3 Searching For an Access Point

Perhaps instead of allowing the user to choose an access point, the program should use a known access point. The following code example shows how a program might search for an access point, given its type and name.

Code Display 26-1 Searching for an Access Point

```
@start  TemplateStringsResource, data;
    @chunk  TCHAR TargetName[] = "Stuckeys Sales Server";
@end    TemplateStringsResource;

@method TemplateProcessClass, MSG_TP_SEND {
    MemHandle     aBlock;
    ChunkHandle   theList;  /* Chunk Array of entry IDs of access points */
    word          theID = ACCESS_POINT_INVALID_ID ;

    aBlock = MemAllocLMem( LMEM_TYPE_GENERAL, 0 );
    MemLock( aBlock );
    theList = AccessPointGetEntries( aBlock , 0, APT_INTERNET );

    ChunkArrayEnumHandles( aBlock, theList, &theID, FunkyCallback);

    MemUnlock( aBlock );
    MemFree(aBlock);

    if (theID == ACCESS_POINT_INVALID_ID ) {
      /* didn't find the access point--deal with it */
    } else {
      /* found the access point--use it */
    }
}

Boolean _pascal FunkyCallback( void *el, void *retVal ) {
    char nomen[128];
    int  nomenSize;
    int  cmpResult;
    char *accessPointName;

    AccessPointGetStringPropertyBuffer( *((word *)el), APSP_NAME, 
                                           nomen, &nomenSize );

    MemLock( OptrToHandle(@TargetName) );
    cmpResult = LocalCmpStrings( LMemDeref( @TargetName ) , nomen, 0);
    MemUnlock( OptrToHandle(@TargetName) );

    if (cmpResult) return(FALSE); 					/* if they don't match, return FALSE so 
					   we can keep searching. */	

    *(word *)retVal = *(word *)el;					/* We found a match. grab its ID */
    return(TRUE);				 	/* ...and we can stop searching now. */
}
```

The `AccessPointGetEntries()` routine returns a chunk array containing a list of access point IDs.

We then use the `ChunkArrayEnumHandles()` routine to call a callback routine to examine each ID in turn. There are many other ways we could have cycled through these entries--see the documentation of chunk arrays in [the Local Memory chapter](clmem.md) to find out which is best for your purpose.

Given an access point's ID number, we find out the name associated with that ID by calling `AccessPointGetStringPropertyBuffer()` . To specify that we're interested in the name, we pass APSP\_NAME; we could also have passed some other `AccessPointStandardProperty` value, or even a pointer to a string to search for the value of some custom property.

While the application is using the selected access point, it can "lock" the access point to prevent the access point's parameters from being modified while it's in use. (See [Locking and Unlocking](#264-locking-and-unlocking) .)



## 26.4 Locking and Unlocking

If something were to alter an access point's parameters while your application was using that access point, bad things might happen. To prevent anything from changing the access point's parameters, use the `AccessPointLock()` routine. When done using the access point, use the `AccessPointUnlock()` routine to unlock it. To check whether or not an access point is being used for a connection, use the routine `AccessPointInUse()`.



## 26.5 Adding an Access Point

To add a new access point:

- Use the `AccessPointCreateEntry()` routine to create the access point. To create an internet access point, use the syntax:

```
newID = AccessPointCreateEntry( 0, APT_INTERNET );
```

- Using the ID returned by `AccessPointCreateEntry()` , set the appropriate properties for the access point.



## 26.6 Deleting an Access Point

To delete an existing access point:

- Call `AccessPointDestroyEntry()` .