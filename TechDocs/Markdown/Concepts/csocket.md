# 25 Socket Library

This chapter describes interactions with the Socket library, used for managing communications between threads -- threads on different machines or two GEOS threads on the same machine (via the "loopback" communication domain). It provides an API which is mostly independent of the medium used for inter-machine communication.

It is common to spawn a separate thread to poll a socket for incoming data; See [the Multithreading chapter](cmultit.md) to learn about managing threads. Sample applications are located in APPL\\SDK\_C\\MultThrd. Some socket operations require knowledge of the communications network used.

## 25.1 Introduction

The Socket library manages communications both between machines and between threads on the same machine. It provides a level of abstraction above individual communication protocols ( *e.g.* , IrLMP, TCP/IP). Programs using the Socket library can send and receive information packets without knowing much about the communications protocol by which those packets are being transmitted. Also, programs using the Socket library need not know about the hardware communication ports used -- whether communication is being carried out over an IR serial port, a modem, or a network connection -- the API is the same.

The Socket library supports different "delivery types"-- different levels of reliability in transmitting data. There is a trade-off: the more reliable delivery types require more set-up work by the programs using them. The following delivery types are available:

**Datagram**

Unreliable transmission of discrete packets. Packets may arrive out of order or not at all. It is up to the data sender to determine if re-transmission is necessary. This is the least demanding delivery type to set up, because it doesn't require any two-way connection.

**Sequenced Packet**

Sequenced Packet delivery means reliable transmission of discrete packets. The packets arrive in the order sent. The Socket library manages error checking and re-transmissions, as necessary. The program using a sequenced packet socket is responsible for establishing a two-way communications connection.

**Stream**

Stream delivery means the reliable transmission of a stream of bytes, as opposed to other delivery types which require that data be broken up into packets. The Socket library manages a stream of bytes, breaking it up into packets, transmitting the packets, and reconstructing the byte stream from packets on the other side. The Socket library also manages error-checking and re-transmission, as necessary. The program using a stream socket is responsible for establishing a two-way communications connection.

#### Addresses

Each side of the connection is represented by an address. An address is made up of several parts:

**Domain**

The network over which the connection is being made. Domains include TCP/IP, IRLAP, and "loopback" (used for connections between two threads on the same machine).

**Address Data**

This data identifies a machine on a network domain. The format of the address depends on the domain. In the case of TCP/IP, a sample address might be the string "geoworks.com". IrLAP addresses are 32-bit numbers. If the domain is "loopback", then no address information is necessary -- the sending and receiving machines are one and the same.

**Port**

This token identifies one side of a connection within one machine. Ports allow multiple data sockets to operate over one connection. Thus, connecting to "geoworks.com", one might send mail messages using port 25 and file-transfer commands via port 21. Port numbers are either 16-bit or 32-bit, depending on the domain.

The amount of overhead associated with sending and receiving data depends upon the devices involved, the domain, and the delivery type. When testing, experiment with different domains (if available), delivery types, and packet sizes to find a good balance of reliability and rapidity.

For any domain, there may be more than one address format. For instance, the TCP/IP address "geoworks.com" is conveniently human-readable, but cannot be used at the socket level to actually make a connection. Instead, you must resolve "geoworks.com" to a 32-bit address number. All socket operations require "primitive" addresses -- addresses resolved to their simplest form. To resolve an address, call `SocketResolve()` . We will discuss the details of working with addresses in more detail below.

#### Errors

Many of the Socket library routines return error values. Sometimes these error values are return values of routines; if you call a routine that can return an error value, be sure to check the return value and react appropriately to errors. Some routines don't return an error value directly, instead returning a flag to indicate that something has gone wrong. To find out exactly what went wrong, call `ThreadGetError()` .

Those Socket library routines that return error values do not set the thread error value. Calling `ThreadGetError()` after calling such a routine would not detect any error encountered by that routine.

`ThreadGetError()` returns a word-sized value. The low byte of this word is a `SocketError` value; the high byte is a `SpecSocketDrError` value. If the returned word is zero, that means that there was no error.

In general, a `SpecSocketDrError` value indicates a low-level error, and a `SocketError` value indicates a high-level error. In many cases, there will be a `SocketError` in the low byte, but the high byte will be clear -- there was no problem with the low-level communication medium, but a protocol exception may have occurred.

In general, only the low byte (the `SocketError` value) is useful in determining how to handle the exception. The high byte might affect what error message is displayed to the user. For example, it probably doesn't matter to your program whether the high byte was SSDE\_LINE\_BUSY or SSDE\_NO\_DIALTONE. In either case, it just means that communication could not be established. However, users might want to know the nature of the problem so that they can figure out how fix it.

Some of the more common `SocketError` values are listed below. In addition, certain routines may make use of other `SocketError` values, which will be discussed with those routines.

SE\_NORMAL

There is no error. SE\_NORMAL is guaranteed to equal zero.

SE\_OUT\_OF\_MEMORY

The Socket library ran out of memory. Perhaps it was trying to receive or send a data packet that was too large.

SE\_SOCKET\_IN\_USE

The socket was busy doing something else. Perhaps you tried to connect it, but it was already connected.

SE\_SOCKET\_BUSY

The socket was temporarily busy doing something else. Perhaps you should try again a few times.

SE\_MEDIUM\_BUSY

The hardware port which would be used to carry out the requested operation was busy. You might wait for the hardware port to become free; you could call `SocketCheckMediumConnection()` to see if the port is being used for a socket connection.

SE\_ALL\_PORTS\_BUSY

To carry out the requested operation, the Socket library tried to use a port number; however all port numbers were already busy.

SE\_SOCKET\_NOT\_BOUND

The socket was not bound ( *i.e.* , associated with a port number), but needed to be bound to carry out the requested operation. To bind a socket, call `SocketBind()` .

SE\_SOCKET\_NOT\_LISTENING

The socket wasn't listening for incoming connections, and needed to be in this state to carry out the requested operation. To make a socket listen, call `SocketListen()` .

SE\_SOCKET\_LISTENING

The socket was busy listening for incoming connections when you asked it to carry out another operation. Remember that you often want separate sockets to handle listening and data transfer.

SE\_SOCKET\_NOT\_CONNECTED

The socket was not connected, but a connection is required for the operation you requested. To connect the socket, call `SocketConnect()` .

SE\_SOCKET\_CLOSED

The socket was closed, making the requested operation impossible.

SE\_CONNECTION\_CLOSED

The other side of your socket's connection has closed that connection; to close up your side of the connection, call `SocketClose()` .

SE\_CONNECTION\_FAILED

The connection was lost, probably due to some low-level link failure. There may have been a problem with the physical connection or with the domain-specific software.

SE\_CONNECTION\_RESET

The connection was lost, probably due to this side of the connection intentially making a low-level disconnection; *e.g.* , the sort of disconnection that results from `SocketCloseDomainMedium()` or the Socket's owning thread exiting.

SE\_TIMED\_OUT

The Socket library was unable to carry out the requested operation before the time-out time was reached. Beware: Depending on the domain, for certain phases of certain operations, there may be low-level time-outs which can occur even if you have specified a longer or an infinite time-out.

SE\_CANT\_LOAD\_DRIVER

The Socket library was unable to load a driver necessary to carry out the requested operation.

SE\_UNKNOWN\_DOMAIN

The Socket library didn't recognize the domain name.

SE\_DESTINATION\_UNREACHABLE

The requested destination address was unreachable over the network.

SE\_LINK\_FAILED

The low-level link used for this connection failed or could not be established. There may have been a problem with the physical connection or with the domain-specific software.

SE\_SYSTEM\_SHUTDOWN

This error signals that GEOS is shutting down. Your program should probably either end its connections gracefully or attempt to delay the shutdown. Note that it is possible for a shutdown to occur without generating this signal.

SE\_INFO\_NOT\_AVAILABLE

The requested information was not available.

SE\_DOMAIN\_REQUIRES\_16BIT\_PORTS

You tried to use a 32-bit port number in a domain that does not support them. Use MANUFACTURER\_ID\_SOCKET\_16BIT\_PORT as the `ManufacturerID` of your port number.

SE\_INTERRUPT

The operation was stymied by `SocketInterrupt()` .

SE\_INTERNAL\_ERROR

The Socket library did something wrong. You should take advantage of whatever developer support to which you have access. They will want a back-trace and other information necessary to duplicate the error.



## 25.2 Simple Example

The sample application Appl/SDK\_C/Talk provides an example of a simple application using the Socket library.

To understand how the program works, you should, of course, look at its source code. The following is a high-level overview of what the Talk example illustrates: a simple client-server connection in which the server awaits connections, the client connects, and then the two exchange data. Note: this application assumes that the host device (the client) has already connected to the server. Remote connections are usually made through PPP or Point-to-Point Protocol. See `SocketOpenDomainMedium()` discussed in [Hardware Ports](#2533-hardware-ports) .

The example performs the following steps:

1. **Allocate memory in which to store data.**  
   When sending or receiving data, you need to provide a pointer to a buffer containing the data to be sent or received. Thus, the buffer should be in a block which can either be locked down as needed or is in fixed memory. Programs often spawn a separate thread to receive data from the socket; if this thread needs to lock down a memory block in which to store the data, then make sure that the thread can lock down the memory block. See [the Multithreading chapter](cmultit.md) to learn about managing threads.  
   (If you follow the multi-threaded approach, be aware that when the Socket's owning thread exits, it frees the Socket. To allow a Socket to survive the exit of its thread, use `SocketSetIntSocketOption()` to change its owning thread.)  
   For this simple example, we're using a small buffer to handle the receipt of data, so we declare it as a global variable so it resides in the application's fixed memory:

```
char recvBuf[16];
```

- **Client Side: Make Sure Connected to Domain**  
  Depending on the nature of the device and application, you may need to make sure that the device is connected to the communication domain. In the Talk sample application, we make sure that the device is dialed in to an ISP: an `AccessPointControl` object prompts the user to choose an ISP, and a call to `SocketOpenDomainMedium()` opens a PPP connection to that ISP.
- **Client Side: Get Address For Other Side of Connection.**  
  The Talk application allows the user to connect with another machine by specifying that machine's address. The Talk application creates a controller gadget by which the user can specify an address. `SocketGetAddressController()` returns the controller class' pointer; `ObjInstantiate()` creates an object of the class.  
  The following code is called when the application opens. It creates the controller gadget, initializes its data, and places it in a dialog box.

```
ctrlClass = 
  SocketGetAddressController(theAddress.SA_domain));

ctrlOb = 
  ObjInstantiate( 
    HandleOf(GeodeGetOptrNS(@AddressDialog)),
    ctrlClass);

@call ctrlOb::MSG_SOCKET_ADDRESS_CONTROL_SET_ACTION(
  ConstructOptr(0,TO_PROCESS), MSG_CTP_VALID);

@call
  GeodeGetOptrNS(@AddressDialog)::MSG_GEN_ADD_CHILD(
    ctrlOb, CCO_FIRST);

@call ctrlOb::MSG_GEN_SET_USABLE(VUM_NOW);
```

When the user enters an address, the following code is called. It gets the selected address from the address controller and packages it up into a form the Socket library can use.

`MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES` returns a chunk with raw address data based on the address entered by the user. `SocketResolve()` reduces this raw address data to a primitive form that can be used for making connections.

```
adArray = @call ctrlOb::MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES();

address1 = ChunkArrayElementToPtrHandles(
  HandleOf(ctrlOb), adArray, 0,0);

theAddress.SA_addressSize = 
  SocketResolve(
    theAddress.SA_domain, (byte *)&address1[1],
    address1->SACA_opaqueSize, addressBuffer,
    MAX_ADDRESS_SIZE);

LMemFreeHandles(HandleOf(ctrlOb), adArray);
```

- **Client Side: Create and Connect Socket.**  
  The Client side now creates a socket for its side of the connection and attempts to connect to the address extracted from the address controller. The socket will be of the stream delivery type.

```
dataSocket = SocketCreate(SDT_STREAM);

SocketConnect(
  dataSocket, (SocketAddress *) &theAddress,
  SOCKET_NO_TIMEOUT);
```

- **Server Side: Create Socket and Accept Connection(s)**  
  On the server side, the application spawns a separate thread to handle incoming connections.

There are two "sockets" created on this, the server side of the connection. The first socket is bound to a particular port, and "listens" for incoming connections. It is possible to accept more than one connection over the listening socket--each accepted connection is represented by another socket to represent this side of the new particular connection.

```
listenSocket = SocketCreate(SDT_STREAM);

SocketBind(listenSocket, theAddress.SA_port, 0);

SocketListen(listenSocket, 5);

dataSocket = SocketAccept(
  listenSocket, SOCKET_NO_TIMEOUT);
```

- **Either Side: Send Data**  
  In this example, the data to send is taken from a text object. The program loads the text into a block of memory, locks the block down to get a pointer to it, then transmits the data.

```
textBlock = @call
  GeodeGetOptrNS(@InText)::
  MSG_VIS_TEXT_GET_ALL_BLOCK(NullHandle);

textPtr = MemLock(textBlock);

textSize = LocalStringSize(textPtr);

SocketSend(
  dataSocket, textPtr, textSize, 0, 
  (SocketAddress *)0);

MemFree(textBlock);
```

- **Either Side: Wait For and Receive Data**  
  The application's listening thread waits for data to arrive and stores it away in a buffer when it does arrive. It processes the incoming data and gets ready for the next piece of data.

```
while ((
  datasize = SocketRecv(
    dataSocket, recvBuf, sizeof recvBuf, 
    SOCKET_NO_TIMEOUT, 0, (SocketAddress *)0))
  != 0)

{ @call 
  GeodeGetOptrNS(@OutText)::MSG_VIS_TEXT_APPEND_PTR(
    recvBuf, datasize); }
```

- **Either Side: Close Connection**  
  The application has a Close button. When the user presses this button, the application shuts down its side of the connection. The `SocketCloseSend()` routine partially shuts down the socket so that it can receive data, but cannot send it; also, the routine sends a signal to the other side that the connection is closing.

```
if (listenSocket) { 
  SocketClose(listenSocket);
  listenSocket = 0; }

SocketCloseSend(dataSocket);
```

- **Either Side: Detect Closed Connection and Close Socket**  
  When receiving data, if either side seems to have received a zero-length packet, it checks to see if an exception has occurred, specifically to see if the connection has closed. (When `SocketRecv()` detects an error, it sets the thread error value, which may be retrieved via `ThreadGetError()` .) If the connection has closed, then Talk closes the sockets on this side of the connection.

```
if (ThreadGetError() == SE_CONNECTION_CLOSED) { 
  if (listenSocket) {
    SocketClose(listenSocket);
    listenSocket = 0; }
  SocketClose(dataSocket); }
```

- **Both Sides: Sockets Freed When Thread Exits**  
  Lest you are worried about these Sockets you have created but not freed, know that they will be freed automatically when the owning thread exits. (To allow a Socket to survive its thread's exit, you must assign the Socket to a new thread.)



## 25.3 Addresses

In the example above, the application queried the user for a connection address. This is a fairly common case. However, some programs need to use hard-wired addresses. Perhaps you want to allow connections over all available domains. Thus, a few words about addresses may be in order.

Addresses are usually represented via the `SocketAddress` structure:

```
typedef struct {
	SocketPort 		SA_port;
	word 		SA_domainSize;
	char *		SA_domain;
	word 		SA_addressSize;
} SocketAddress;
/* domain-specific address data here */
```

**SA\_port**

Port numbers identify a particular line of communication within a machine. Port numbers may be 32-bit or 16-bit, depending on the domain. They are specified via the `SocketPort` structure, made up of a 16-bit `ManufacturerID` and 16-bit arbitrarily-chosen token number. If the domain uses 16-bit socket numbers, then use MANUFACTURER\_ID\_SOCKET\_16BIT\_PORTas the `ManufacturerID` . If the domain allows 32-bit socket numbers, then you may use MANUFACTURER\_ID\_SOCKET\_16BIT\_PORT or some other `ManufacturerID` , probably your own ID or that of some standard service provider. This numbering scheme helps to avoid overlapping port numbers.

**SA\_domain** , **SA\_domainSize**

The domain identifies the protocol of the network by which the addressed machine may be reached. The domain is specified by a string. In a `SocketAddress` structure, `SA_domain` is a pointer to the null-terminated domain name string and `SA_domainSize` is the size of the buffer containing the domain name string.

Many communications protocols are hard-wired to work with a particular domain. To find out all domains available to the user's device, call `SocketGetDomain().` (See [Letting the User Choose an Address](#2531-letting-the-user-choose-an-address) .)

**SA\_addressSize** , **Address Data**

The format of the address data used to identify a machine within a domain depends on that domain. The `SA_addressSize` field of the `SocketAddress` structure contains the size of the address data. The buffer containing the address data should fall immediately after the `SocketAddress` structure. Read the documentation for a given domain to find out the format for its addresses.  
You'll want to make sure that space for this data is, in fact, allocated at the end of the structure. If you declare a socket address, you will define a struct, probably based on `SocketAddress` , that has the fields of `SocketAddress` , but also has a buffer to hold the resolved address data. More likely than not, you won't need to declare or define such a structure -- you're more likely to use `SocketCreateResolvedAddress()` or bypass the creation of this structure altogether.

Before using an address, make sure that it is in its primitive form. For instance, an IP address like "geoworks.com" is not in its primitive form -- the IP address must be translated into a four-byte number before it can be used. Use `SocketResolve()` (described below) to transform an address into its primitive form. Note that the address passed to `SocketResolve()` is not in a `SocketAddress` structure.


### 25.3.1 Letting the User Choose an Address

```
SocketAddressControllerClass, SocketGetDomains(), SocketGetAddressController(), SocketCreateResolvedAddress(), SocketResolve(), SocketInterruptResolve()
```

Given a domain, you can request the Socket library to provide UI gadgetry so that the user can choose an address within that domain. Many programs only support socket connections over one domain. However, if you need a list of all domains supported in the user's environment, call `SocketGetDomains()` .

The `SocketGetDomains()` routine takes the optr of a chunk array and fills in that array with elements. Each element contains a (non-null-terminated) string which is the name of a supported domain. This chunk array has a standard `ChunkArrayHeader` header and variable-sized elements.

If you want the routine to allocate the chunk array for you, pass an optr that contains a NullChunk ( *i.e.* , a null ChunkHandle):

```
MemHandle	myHandle;
Optr	myOptr;
myHandle = OptrToHandle(myHandle);
myOptr = ConstructOptr(myHandle, NULL);
```

For more information about working with chunk arrays, see [the Local Memory chapter](../../Memory/LMem/index.htm). In short, to manage the chunk array of domain names:

1. Lock down the local memory heap with `MemLock()` .
2. Use `LMemDerefHandles()` to get a pointer to the chunk array.
3. To get the number of domains, call `ChunkArrayGetCount()` .
4. To get a pointer to the nth string in the chunk array, call `ChunkArrayElementToPtr()` or `ChunkArrayElementToPtrHandles()` .
5. When finished reading domain strings, call `MemUnlock()` on the local memory heap.

Given a domain name, you can create some UI gadgetry for choosing addresses within that domain. As shown in the Appl/SDK\_C/Talk example, call `SocketGetAddressController()` to get the class of an appropriate controller. This class is guaranteed to support the messages shown below:

Code Display 25-1 SocketAddressControllerClass

```
/* Domain-specific subclasses of SocketAddressControllerClass all support 
 * the following messages. MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES is probably 
 * the most commonly used message. */

/*
 * Build the block of data that holds the addresses selected by the user
 * to pass to the transport driver. If OK, returns ChunkArray of SACAddress
 * structures in same block as controller. Else, returns 0.

 * As of this writing, all address controllers return at most one address 
 * in the list of addresses. 

 * The returned address(es) are not in its primitive form; use 
 * SocketResolve() to transform the address into something usable.
 */
 @message word MSG_SOCKET_ADDRESS_CONTROL_GET_ADDRESSES();

  typedef struct {
	word 		SACA_opaqueSize;
	/* label byte 		SACA_opaque;    Pass this to SocketResolve */ 
	/* after the opaque address, there is a null-terminated
	 *  human-readable form of the address. */
} SACAddress;

/*
 * Inform the subclass of the type of medium selected by the user
 * so it can customize its appearance appropriately, should the controller
 * handle media that have different ways of addressing.
 */
@message void MSG_SOCKET_ADDRESS_CONTROL_SET_MEDIUM (
				MediumType mediumType);

/*
 * Set the current user-editable address to the passed address.
 */
@message void MSG_SOCKET_ADDRESS_CONTROL_SET_ADDRESSES(optr addr);

/*
 * Inform the controller of the message and destination object it should use to
 * notify the invoker that a valid address exists.
 */
@message void MSG_SOCKET_ADDRESS_CONTROL_SET_ACTION (
				optr dest,
				word actionMsg);

/*
 * Let the containing dialog know whether the address we've got is a
 * valid one, so it can decide whether to allow the user to send the
 * message.
 */
@message void MSG_SOCKET_ADDRESS_CONTROL_SET_VALID_STATE(Boolean valid);
```

You cannot use an address with Socket library routines unless that address is in its primitive form. This primitive form is created by taking a higher-level form of the address and passing it to the `SocketCreateResolvedAddress()` routine or the `SocketResolve()` routine. Exactly how the Socket library resolves the address depends upon the domain.

Recall that addresses returned by the address controller are not in their primitive form. The primitive form of an address can be volatile: feel free to re-use them if making several connections over a short period of time, but re-resolve the address if it's been a long time since it was last resolved. Note that there can be a large overhead when it comes to resolving addresses. Also note that IRLAP numeric addresses are especially volatile, changing every time the protocol connection starts, *i.e.,* every time the IRLAP driver is loaded, either for the first time or after more than a minute of inactivity.

The `SocketCreateResolvedAddress()` routine takes a pointer to a domain name and raw address data and returns a buffer with a `SocketAddress` structure and the address data. Depending on what you're going to use the address for, you may need to fill in the structure's `SA_port` field.

`SocketResolve()` is the same as `SocketCreateResolvedAddress()` except that `SocketResolve()` takes a buffer to hold the resolved address data. If the buffer isn't big enough, `SocketResolve()` returns SE\_BUFFER\_TOO\_SMALL. Depending on the domain, calling `SocketResolve()` on an address already in its primitive form may have undesired results.

The resolution process may or may not require network access, depending on the domain and the input format. Depending on the domain, the addressing system may be volatile. Under these conditions, put off resolving the address as long as possible, until just before using the address; there will be less time for the address to go bad. If the network goes down, the Socket library might not be able to resolve addresses. In this case, `SocketCreateResolvedAddress()` or `SocketResolve()` returns SE\_TEMPORARY\_ERROR.

If you wish to interrupt the resolution process (perhaps you allow the user to cancel the operation), use the `SocketInterruptResolve()` function. This function attempts to halt the resolution process. It is, however, unreliable. It may not succeed in interrupting the resolution process; it may also interrupt other resolves happening at the same time.



### 25.3.2 Managing Addresses

```
SocketGetAddressSize(), SocketGetSocketName(), SocketGetPeerName()
```

Most programs blindly use addresses supplied by the user or use only hard-wired addresses. Only a few programs need to access and manipulate addresses. The Socket library provides a few utility routines for this purpose.

To find out the maximum address data size for a given domain, call `SocketGetAddressSize()` . This can be helpful when allocating memory to handle a full address, such as that returned by the `SocketGetSocketName()` and `SocketGetPeerName()` functions.

If a socket is connected, call `SocketGetPeerName()` to get the address of the socket at the other end of the connection. To find out the address used to represent the socket's own side of the connection, call `SocketGetSocketName()` .



### 25.3.3 Hardware Ports

```
SocketGetDomainMedia(), SocketGetAddressMedium(), SocketCheckMediumConnection(), SocketGetMediumAddress(), SocketOpenDomainMedium(), SocketCloseDomainMedium()
```

Most socket connections involve the use of some hardware "port" -- some physical connection to the outside world. To determine which sort of hardware ports the user's machine uses to connect to a given domain, call `SocketGetDomainMedia()` . This returns a chunk array of `MediumType` structures. Given a choice of domains to make a given connection, consider which medium would be used to make the connection.

To find out which port the Socket library would use to connect to a given address, call `SocketGetAddressMedium()` . Depending on the medium, you might try to connect to the other site via some other domain or decide not to make the connection at all.

To check a given hardware port is being used for an active connection, call `SocketCheckMediumConnection()` . If a point-to-point connection exists, this routine returns the address of the remote site. If there is a connection, but not a specific address, then the routine returns a null address. If there is no connection through the hardware port, the routine returns a `SocketError` value.

To find out the address of the local machine on a connection over a particular medium, use the`SocketGetMediumAddress()` routine. This is the address another machine would use to connect to this machine via that medium.

The `SocketOpenDomainMedium()` routine opens a "raw" connection using the specified medium. Exactly what is meant by a "raw" connection depends upon the domain involved. In the case of TCP, this routine will dial the modem and create a PPP connection to the PPP server but will not send any TCP packets.

It is possible to "hang up" a hardware port. Call `SocketCloseDomainMedium()` to force a domain to close a medium. You may request that the medium only be closed if it is not being used ( *i.e.* , there are no active connections using the medium). If any socket connections are using the port, they will receive the error SE\_CONNECTION\_RESET. Later, we will discuss orderly ways to close a connection, being careful to send proper notification to the other side of the connection.



## 25.4 Making a Connection

```
SocketCreate(), SocketConnect(), SocketInterrupt()
```

To make a connection, a program creates a socket and specifies an address to which to connect that socket.

To create a new socket, call `SocketCreate()` . You must specify the socket's delivery type: datagram, sequential packet, or stream.

Before sending or receiving data over a sequential packet or stream socket, you must "connect" it to the place it will be sending the data to or receiving it from.

Depending on the medium and device, you may need to make sure that the device is connected to a network. For example, for a Nokia 9000i Communicator to make a TCP/IP connection, it must first have made a PPP connection. Use the `SocketOpenDomainMedium()` routine to make the "raw" network connection.

To make a connection, call `SocketConnect()` . Pass the socket created via `SocketCreate()` , the address to connect to, and a time-out value. If it returns SE\_NORMAL, then the connection was established successfully. If it returns SE\_CONNECTION\_REFUSED, the remote site wasn't prepared to accept the connection. If it returns SE\_CONNECTION\_ERROR, the connection didn't go through for some miscellaneous reason. If it returns SE\_NON\_UNIQUE\_CONNECTION, then the attempted connection would have been identical to another connection: same source address, source port, destination address, destination port, and delivery type. There would be no way to tell these connections apart. If you try to open the same connection from both sides simultaneously, they may both fail with SE\_NON\_UNIQUE\_CONNECTION.

To cancel the connection operation, call `SocketInterrupt()` .

Datagram sockets cannot form a true connection -- they are unreliable. Sockets must be able to send and receive datagram packets without relying on a permanent connection. However, using `SocketConnect()` with a datagram socket specifies a default destination address to use when sending packets.



## 25.5 Accepting a Connection

```
SocketBind(), SocketBindInDomain(), SocketListen(), SocketAccept() 
```

There's a bit of work involved in setting up a program to receive connections from other sockets. The program must create a socket and associate it with a port. If there is to be a sequenced-packet or stream delivery connection, then the program needs to do some more work to listen for and accept these connections.

If a program creates a socket that accepts connections, the program should probably spawn a separate thread for each accepted connection. If this is not practical, then see `SocketCheckReady()` for a way to monitor several sockets with a single thread.

Call `SocketCreate()` to create a socket for this side of the connection. If the socket is to receive datagram packets, then it must be of type datagram. If the other socket in the connection will be a sequenced packet or stream delivery type, then the socket accepting the connection must be either sequenced packet or stream delivery type; however, the two sockets need not be of the same type.

(If you follow the multi-threaded approach, be aware that when the Socket's owning thread exits, it frees the Socket. To allow a Socket to survive the exit of its thread, use `SocketSetIntSocketOption()` to change its owning thread.)

The other side of the connection attempts to hook up to a port number on this side of the connection. If a socket is to intercept connections to a certain port, it must somehow associate itself with that port. Use the `SocketBind()` or `SocketBindInDomain()` routines to associate a socket with a port number. `SocketBind()` associates the socket with a port number. `SocketBindInDomain()` associates the socket with a port number but only within a specific domain.

For any given domain, normally only one socket on the machine may be bound to any port number. Thus, if you call `SocketBindInDomain()` to bind socket A to port 3 in the TCP/IP domain, then:

- You could use `SocketBindInDomain()` to bind socket B to port 3 in the IRLAP domain, but
- You couldn't use `SocketBindInDomain()` to bind socket C to port 3 in the TCP/IP domain, and
- You couldn't use `SocketBind()` to bind socket D to port 3.

There are some ways around this restriction:

- To force `SocketBind()` or `SocketBindInDomain()` to re-use some port that another socket has bound, then pass the SBF\_REUSE\_PORT flag. Otherwise, be prepared to receive SE\_PORT\_IN\_USE or SE\_BIND\_CONFLICT. Even the SBF\_REUSE\_PORT flag won't allow you to use both `SocketBind()` and `SocketBindInDomain()` on a single port. E.g., in the example above, you could use `SocketBindInDomain()` with SBF\_REUSE\_PORT to bind socket C to port 3 in the TCP/IP domain, but you could not use `SocketBind()` with SBF\_REUSE\_PORT to bind socket D to port 3. You may not use SBF\_REUSE\_PORT with datagram-based sockets.
- If there are only non-datagram-based sockets bound to a port, you may bind a datagram-based socket to that port without setting SBF\_REUSE\_PORT. The reverse is also true. Recall that only a datagram socket can connect with another datagram socket; non-datagram sockets connect only with other non-datagram sockets.
- A given socket may only be bound to one port. Trying to bind it to another port results in SE\_SOCKET\_ALREADY\_BOUND. Create another socket to bind to the other port.

Always check for bind conflicts. Bind conflicts may occur even though a program is well-behaved: other programs may have bound ports to a socket. For reasons described in [Loading on Connection](#256-loading-on-connection) , sometimes the Socket library itself may monitor a port.

When setting up a sequenced packet or stream delivery connection, a bit more set-up work is necessary. These delivery types require a "connection."

To listen for incoming sequenced packet or stream connections, call `SocketListen()` . The socket must be bound to a port before it can listen. To allow more than one connection through the port, specify the maximum number of connections as an argument to `SocketListen()` . The `SocketListen()` routine causes a socket to listen for incoming connections. If another socket is listening at the port, `SocketListen()` returns SE\_PORT\_ALREADY\_LISTENING.

To make a socket wait for and accept a connection, call `SocketAccept()` . The socket must be listening for connections (processed by `SocketListen()` ). Because the thread blocks until a connection is made or `SocketAccept()` times out, programs normally don't call this routine in their main execution thread. As in the Appl/SDK\_C/Talk sample application, a separate thread handles accepting a connection and receiving data from the connection.

If a connection is made, `SocketAccept()` returns a `Socket` used to represent the connection. Do not confuse this connected socket with the listening socket. You might be able to accept more connections from the listening socket.

If `SocketAccept()` returns SE\_LISTEN\_QUEUE\_EMPTY, then there were no connections waiting to be accepted.



## 25.6 Loading on Connection

```
SocketAddLoadOnMsg(), SocketAddLoadOnMsgInDomain(), SocketRemoveLoadOnMsg(), SocketRemoveLoadOnMsgInDomain()
```

It's all very well that you can tell a running program to accept packets and connections over sockets. However, it seems unreasonable to ask the user to run these programs by hand any time there might be a pending connection.

You can tell the Socket library to load a particular geode when it receives data on a particular port, or on a particular port via a particular domain. For an example, see the Appl/SDK\_C/Talk sample application: if you run Talk and press the Autoload button, the Socket library knows to start up the Talk program because it senses that it is receiving an incoming Talk connection.

When the program starts up, it should probably create a socket, bind it to the appropriate port, and make that socket listen. If the listening socket is then destroyed, then any unaccepted connections are canceled.

The Socket library writes out an entry to the GEOS.INI file in the \[socket] category and with key "LoadOnMsg". The Socket library consults these GEOS.INI file entries when it starts up and will act accordingly when it receives packets.

To make the Socket library load a program when receiving packets on a particular port, call `SocketAddLoadOnMsg()` . Specify the program by means of its path. To load a program when receiving packets on a particular port on a particular domain, call `SocketAddLoadOnMsgInDomain()` .

To remove the entries from the GEOS.INI file and tell the Socket library not to try to load the program when receiving packets, call either `SocketRemoveLoadOnMsg()` or `SocketRemoveLoadOnMsgInDomain()` .

To listen for incoming data in this manner, the Socket library effectively binds a socket to monitor the port. Thus

- `SocketAddLoadOnMsg()` and `SocketAddLoadOnMsgInDomain()` can run into bind conflicts just as `SocketBind()` and `SocketBindInDomain()` do.
- `SocketAddLoadOnMsg()` interferes with `SocketAddLoadOnMsgInDomain()` and `SocketBindInDomain()` on the same port.
- `SocketAddLoadOnMsgInDomain()` interferes with `SocketAddLoadOnMsg()` and `SocketBind()` on the same port.



## 25.7 Sending and Receiving Data

```
SocketSend(), SocketRecv(), SocketSetIntSocketOption(), SocketGetIntSocketOption(), SocketSetSocketOption(), SocketGetSocketOption()
```

Once both sides of a socket communication are set up, they're ready to send data back and forth. The `SocketSend()` and `SocketRecv()` routines, described below, allow a socket to transmit and receive data, respectively.

The amount of overhead associated with sending and receiving data depends on the devices involved, the domain, and the delivery type. Be certain that if just one byte of data is sent at a time, time performance will suffer.

Whenever possible, the sender should gather up small pieces of data and send them in one large packet. The optimal size of a packet depends on the device, domain, and delivery type. When designing a communications protocol, it would be worthwhile to figure out which sorts of data may be combined into larger blocks. Note that in some domains, the driver will try to do this gathering of small blocks into large packets for you.



### 25.7.1 Urgent Data

The Socket library supports the notion of urgent data. This allows a short packet of data to cut in front of other packets. To send a packet marked urgent, pass the SSF\_URGENT flag to `SocketSend()` .

In some domains, only one byte of data in a packet can be marked urgent. In such a domain, passing SSF\_URGENT with a 32-byte packet to `SocketSend()` results in two packets being sent: a 1-byte urgent packet and a 31-byte non-urgent packet. The data of the 1-byte urgent packet is the last byte of the original 32-byte packet. Check your domain documentation for size limits on urgent packets.

Urgent data may be delivered out of order. It may arrive out of sync with non-urgent packets; it may arrive out of order with other urgent packets. There is no queue for urgent data. Each urgent data packet received causes the previous urgent data to be discarded.

The `SocketRecv()` routine, in charge of receiving incoming packets, may be instructed to receive only urgent data or only non-urgent data. If there is pending urgent data and `SocketRecv()` is told to poll for normal data, it will return an error value, SE\_URGENT, signalling that the program should call `SocketRecv()` again, this time to receive urgent data. (If, instead, you call `SocketRecv()` telling it to receive normal data again, it will return any pending normal data; it will not generate the SE\_URGENT exception for the pending piece of urgent data -- unless *another* piece of urgent data has arrived in the meantime.)

Datagram connections do not support urgent data; `SocketRecv()` generates an SE\_URGENT error on a datagram connection, it's really generating a SE\_EXCEPTION value. If you receive such an error, it is a sign that the network is having troubles and packets *may* not be getting through.

You may force incoming urgent data to be treated in the same manner as normal data by setting the socket's "in-line" option. See SO\_INLINE for information about socket options.



### 25.7.2 SocketSend() and SocketRecv()

The `SocketSend()` routine sends data over a socket. It takes several arguments:

**Socket**

The socket through which to send data

**Buffer**

A buffer containing the data to send

**Buffer Size**

The size of the data buffer.

**Optional Address**

Address to which to send data. If you pass an address here, make sure that you set the Address flag in the Flags field. If you don't set the Address flag, then this Optional Address argument may be a null pointer.

For sequenced packet or stream delivery type sockets, optional address is ignored.

For datagram delivery type sockets, specify the destination address of the packet in this parameter unless the socket has a default destination address as described below.

Datagram sockets can use the `SocketConnect()` routine to specify a default destination address. If they have no default address, you must specify the destination address for the packet. If there is a default destination address and you pass this optional address, then the optional address overrides the default for this send.

The following flags are available:

**SSF\_ADDRESS**

To pass an optional address.

**SSF\_URGENT**

To mark the data packet as urgent.

**SSF\_OPEN\_LINK**

To open the link if it is closed or to close the current link if it is idle and open it to a different location. If you do not set this flag, the datagram will only be sent if the link is opened to the desired remote link address.

Note that in some domains, the driver may delay before sending small packets of data because it is waiting for more packets to combine into one large packet. In many cases, this leads to more efficient communication. You may turn off this behavior by setting the "no delay" option. See SO\_NODELAY for information about setting socket options.

The `SocketRecv()` routine receives data from the socket. After filling the passed buffer with data, the socket discards its copy of the received data to make room for the next piece of incoming data.

Sequenced packet or datagram delivery sockets can only receive whole packets. If you grab data from the socket but don't grab all the data in the packet, the remaining data is lost. Thus, it's a good idea to establish a maximum packet size for sockets using these delivery types. If you're not sure how much room you'll need to receive a packet, call `SocketRecv()` with the SRF\_PEEK flag. This allows you to "peek" at the incoming data without causing the socket to discard its copy.

The `SocketRecv()` routine takes the following arguments:

**Socket**

The socket from which to grab the data.

**Buffer**

Buffer to fill with data.

**Buffer Size**

Size of the data buffer. A packet-based socket will not retain data that does not fit in the buffer. A stream socket, however, will.

**Time-out**

The number of 1/60 second ticks to wait for incoming data. Pass SOCKET\_NO\_TIMEOUT to wait forever.

**Optional Address**

If you pass the Address flag of the Flags argument, then pass an empty `SocketAddress` buffer. (The buffer's `SA_domain` , `SA_domainSize` , and `SA_addressSize` fields must be initialized.) Make sure the buffer has room for the address data after the `SocketAddress` structure. Note that if either the domain name buffer or the address buffer isn't long enough to hold its string, the resulting truncated string isn't null-terminated.

If you do not set the Address flag, this Optional Address argument may be a null pointer.

The following flags are available:

**SRF\_ADDRESS**

Return the source address in the Optional Address buffer.

**SRF\_URGENT**

Return the first packet which has been marked urgent. (See [Urgent Data](#2571-urgent-data) .)

**SRF\_PEEK**

Force the socket to not discard the data received.

The `SocketRecv()` routine returns the size of the received buffer. If this size is zero, there may be an error in the connection. Use `ThreadGetError()` to check for an error. If `ThreadGetError()` returns SE\_NORMAL, then there was no error and you received a zero-length packet. For a datagram connection, an SE\_EXCEPTION error indicates that the network is having problems and some datagrams *may* not be getting through.



### 25.7.3 Options

To customize a socket's sending and receiving behavior, use `SocketSetIntSocketOption()` (or `SocketSetSocketOption()` if you are using Assembly language). The following options are available:

**SO\_RECV\_BUF** : **Receive Buffer** Size  
To change the size of the buffer used to hold incoming data.

**SO\_SEND\_BUF** : **Send Buffer** Size

To change the size of the buffer used to hold outgoing data.

**SO\_INLINE** : **In-line** urgent data

To force urgent data to be treated the same as normal data. This allows you to poll for both urgent and normal data with a single `SocketRecv()` command. Of course, setting this option means that you will not receive urgent data as soon as possible.

**SO\_NODELAY** : **No Delay** for small packets

To force a driver to send small packets without waiting for other packets to bundle together. Drivers often delay sending small packets, waiting for other packets to bundle together in one larger packet. This is oftentimes more efficient.

**SO\_OWNER** : **Owning Thread** for socket

To specify a new owning thread for a socket. When the owning thread detaches from the Socket library (this happens automatically when the thread exits), the socket will be freed; any attempts to use the freed socket will result in errors. To make a socket survive its thread, you must assign it to a new thread. This option does not actually affect how the socket sends or receives data.

You may find out the current options for a socket by calling `SocketGetIntSocketOption()` (`SocketGetSocketOption()` if you're using Assembly language).



## 25.8 Closing the Connection

```
SocketInterrupt(), SocketClose(), SocketCloseSend(), SocketReset(), SocketCloseDomainMedium()
```

To halt either an accept or receive operation in progress, call `SocketInterrupt()` . If no such operation is in progress but the socket is listening or connected, the next such operation will be interrupted. Look out for the error SE\_SOCKET\_NOT\_INTERRUPTIBLE; this signals that a non-interruptible operation is taking place on the socket.

When it comes time to close the connection and/or free a socket, call `SocketClose()` or `SocketCloseSend()` .

`SocketCloseSend()` works only with connected sockets. It partially shuts down the socket so that it can no longer send data; it can, however, still receive data. (Passing a partially closed socket to `SocketSend()` results in an SE\_SOCKET\_CLOSED error.) `SocketCloseSend()` sends an SE\_CONNECTION\_CLOSED exception packet to the other side of the connection to let it know that it's starting to shut itself down. Upon receipt of this exception packet, the other side of the connection will probably want to begin closing itself down as well.

Not all domains support closing the "send" part of a socket. In this case, the routine will return SE\_CLOSE\_SEND\_NOT\_SUPPORTED and you must use `SocketClose()` instead to close the connection and free the socket.

`SocketClose()` closes the socket (shutting down both incoming and outgoing data) and frees it. This routine may be used on a socket in any state. You must use `SocketClose()` to close (and free) a datagram socket.

To close a connection with extreme prejudice, call `SocketReset()` . Use this routine with caution as it bypasses all normal protocol-level handshaking and unilaterally kills the connection. When using this routine, you should still call `SocketClose()` to free the socket data structures and flush any unread data.

The `SocketCloseDomainMedium()` routine can close all connections over a given medium without sending any notifications. It effectively hangs up the connection. You pass a flag to specify whether the routine should only hang up if there are no active connections through the medium, or hang regardless. For more information about socket media and this routine, see [Hardware Ports](#2533-hardware-ports) .



## 25.9 Checking the Connection

```
SocketCheckListen(), SocketCheckReady()
```

The Socket library provides utility routines that query the status of a connection. This can be helpful when figuring out why a connection may not be working or confirming that a connection is working.

Use `SocketCheckListen()` on a port to find out the domain and medium for the first connection request on the port; that is, the first connection request which has not yet been accepted. Think of this as a limited form of "caller ID" -- a chance to find out about the incoming connection before accepting it. If `SocketCheckListen()` returns SE\_PORT\_NOT\_LISTENING, it means there is no socket that is bound to the port and listening.

To "peek" at the next packet of incoming data, call `SocketRecv()` and pass the SRF\_PEEK flag. This allows you to get the size of the next packet of incoming data and to look at its contents without destroying it.

To check one or more sockets to see if they have received data, received connection requests, or are ready to write, call `SocketCheckReady()` . It can check connections for incoming data or just incoming urgent data.

For programs which need to poll many sockets, `SocketCheckReady()` provides a tidy means to do this without spawning a thread for each socket.

The `SocketCheckReady()` routine takes an array of `SocketCheckRequest` structures. Each one of these structures contains a socket and a condition. `SocketCheckReady()` looks at each `SocketCheckRequest` structure in the array and returns the index of the first structure whose socket meets the condition.

Thus, to determine if a given socket is properly set up so that you can send data through it, pass `SocketCheckReady()` a one-element array (represented in pseudo-code):

```
{ mySocket, SC_WRITE, 0 }
```

To check several sockets to see whether any of them had received any connection requests, pass to `SocketCheckReady()` an array of the form (represented in pseudo-code):

```
{ socket1, SC_ACCEPT, 0 },
{ socket2, SC_ACCEPT, 0 },
{ socket3, SC_ACCEPT, 0 }
```

For any socket, you may check for one or more of the following conditions, as represented by `SocketCondition` values:

**SC\_ACCEPT**

If a socket is listening for a connection, this condition indicates that another socket is trying to connect to the listening socket.

**SC\_READ**

If a socket is connected, this condition indicates that a packet of data has come in and is ready to be read.

**SC\_EXCEPTION**

If a socket is connected, this condition indicates that the socket has discovered something wrong with its connection.

**SC\_URGENT**

If a socket is connected, this condition indicates that it has received a packet of data that was marked urgent.

**SC\_WRITE**

This condition indicates that data may be sent through the socket.

If you query a socket about a condition that does not apply to its current state ( *e.g.* , ask a non-listening socket if it is ready to accept connections), then `SocketCheckReady()` returns SE\_IMPROPER\_CONDITION.



## 25.10 Domain-Specific Information

Some portions of the Socket library API are domain specific; depending on which domain you're using, the domain name, address formats, port numbering schemes, etc. may differ.The following sections describe information specific to particular domains. Not all domains are available on any given device.


### 25.10.1 TCP/IP--GEOS Specific

The TCP/IP domain is a popular standard used for internet communications. The GEOS-specific version supports 32-bit port numbers. GEOS TCP/IP data may be transmitted via a regular TCP/IP network, though both the sending and receiving machines must support GEOS TCP/IP.

**Domain Name:**

"TCPIP\_GEOS"

**Port Numbers:**

32-bit values.

**Opaque Address Format:**

This address will be either a `TcpAccPntExtendedAddress` ,a `TcpOnlyExtendedAddress` , or a `TcpNonAccPntExtendedAddress` .

TcpAccPntExtendedAddress: Use this structure when referring to an address identified by an access point ID number.

TcpOnlyExtendedAddress: Use this structure to identify a TCP address by its address instead of by its ID.

TcpNonAccPntExtendedAddress: Use this structure to identify a TCP address that is not a known access point. You will need to specify a link address (a phone number) as well as an IP address.

Notes:

- On some devices (including the Nokia 9000i Communicator), you cannot make a TCP/IP connection or send packets until the device has a "raw" connection to the network--a PPP connection. Calling `SocketOpenDomainMedium()` with the TCP medium creates a PPP connection. The modem will dial, and the machine will connect to the PPP server, but no TCP level packets will be sent. If the PPP connection is already made, this routine will return SE\_NORMAL, just as if the connection had been just now made. If the modem is already in use, an SE\_MEDIUM\_BUSY error will be returned. Use the `SocketCloseDomaninMedium()` to hang up the phone when done.

- The Talk sample application shows how a device can make a raw PPP connection with the Internet Service Provider (ISP), getting the necessary information about the ISP from the built-in Access Point library. (Notice how the object AccpntControl is declared; notice the sample's TalkAddressClass handler for `MSG_GEN_GUP_INTERACTION_COMMAND` , which queries the AccessPointControl for the selected ISP and extracts the useful information about that ISP; finally, the MSG\_CTP\_CONNECT handler dials the phone to make the PPP connection.)

Code Display 25-2 Making the Raw TCP/IP Connection

Here we see three snippets of code from the Talk sample application  
The AccessPointControl allows the user to choose an ISP:

```
@chunk char accpntMkr[] = "Access List";

@object AccessPointControlClass AccpntControl = {
	GI_states = GS_USABLE|GS_ENABLED;
	HINT_ACCESS_POINT_CONTROL_MINIMIZE_SIZE;
	ATTR_ACCESS_POINT_CONTROL_LIST_MONIKER = @accpntMkr; }
```

In @method TalkAddressClass, MSG\_GEN\_GUP\_INTERACTION\_COMMAND, we get information we'll need about the ISP

```
point = @call \
GeodeGetOptrNS(@AccpntControl)::MSG_ACCESS_POINT_CONTROL_GET_SELECTION();

/* store link info into address buffer */
rawAddress.UTA_link.TAPEA_linkSize = 3;
rawAddress.UTA_link.TAPEA_linkType = LT_ID;
rawAddress.UTA_link.TAPEA_accPntID = point;

/* the text of the address follows the link info */
alen = @call GeodeGetOptrNS(@IPText)::MSG_VIS_TEXT_GET_ALL_PTR( 
						(char *)&(rawAddress.UTA_ip[0]));

if (alen > MAX_IP_ADDR_STRING_LENGTH) FatalError(0);  /* too much text */

/* resolve the raw address into a SocketAddress */
theAddress.SA_addressSize = SocketResolve(theAddress.SA_domain,
					(byte *)(&rawAddress),
					sizeof(TcpAccPntExtendedAddress)+alen,
					(byte *)(&addressBuffer),
					MAX_ADDRESS_SIZE);

In MSG\_CTP\_CONNECT's handler, we make the PPP connection:

```
rval = SocketOpenDomainMedium((SocketAddress *) &theAddress, SOCKET_NO_TIMEOUT);
```

- TCP/IP only supports one byte of urgent data in a packet. If you send a multi-byte packet marked urgent, it will be divided into two packets (on the receiving side). For example, a 32-byte packet marked urgent would be broken up into a 31-byte normal packet and a one-byte urgent packet.
  
  If you set the SSF\_URGENT flag to `SocketSend()` when sending a multi-byte packet, the last byte of the packet will be marked urgent.
  
  Recall that you can set the in-line option to specify that urgent data should be treated as normal data. In this case, urgent data will be treated as a normal 1-byte packet.
- If you're not familiar with TCP/IP, *TCP/IP illustrated* by W. Richard Stevens provides a good introduction.
  
  The TCP/IP standard is defined in a number of RFCs. The RFCs listed below may be of interest. If you research these documents, note that the first is an index to the others.
  
  1720 J. Postel, I. Architecture Board (IAB), "INTERNET OFFICIAL PROTOCOL STANDARDS", 11/23/1994. (Obsoletes RFC1610) (Obsoleted by RFC1780) (STD 1)
  
  1700 J. Reynolds, J. Postel, "ASSIGNED NUMBERS", 10/20/1994. (Obsoletes RFC1340)
  
  1122 R. Braden, "Requirements for Internet hosts - communication layers", 10/01/1989.
  
  1123 R. Braden, "Requirements for Internet hosts - application and support", 10/01/1989.
  
  0791 J. Postel, "Internet Protocol", 09/01/1981. (Obsoletes RFC0760)
  
  0950 J. Mogul, J. Postel, "Internet standard subnetting procedure", 08/01/1985.
  
  0919 J. Mogul, "Broadcasting Internet datagrams", 10/01/1984.
  
  0922 J. Mogul, "Broadcasting Internet datagrams in the presence of subnets", 10/01/1984.
  
  0792 J. Postel, "Internet Control Message Protocol", 09/01/1981. (Obsoletes RFC0777)
  
  0768 J. Postel, "User Datagram Protocol", 08/28/1980.
  
  0793 J. Postel, "Transmission Control Protocol", 09/01/1981. (Updates RFC0761)
  
  1034 P. Mockapetris, "Domain names - concepts and facilities", 11/01/1987. (Obsoletes RFC0973) (Updated by RFC1101)
  
  1035 P. Mockapetris, "Domain names - implementation and specification", 11/01/1987. (Obsoletes RFC0973) (Updated by RFC1348)
  
  0974 C. Partridge, "Mail routing and the domain system", 01/01/1986.
  
  1531 R. Droms, "Dynamic Host Configuration Protocol", 10/07/1993. (Obsoleted by RFC1541)
  
  1533 S. Alexander, R. Droms, "DHCP Options and BOOTP Vendor Extensions", 10/08/1993. (Obsoletes RFC1497)
  
  1534 R. Droms, "Interoperation Between DHCP and BOOTP", 10/08/1993.
  
  1144 V. Jacobson, "Compressing TCP/IP headers for low-speed serial links", 02/01/1990.
  
  1547 D. Perkins, "Requirements for an Internet Standard Point-to-Point Protocol", 12/09/1993.
  
  1662 W. Simpson, "PPP in HDLC-like Framing", 07/21/1994. (Obsoletes RFC1549)
  
  1334 B. Lloyd, W. Simpson, "PPP Authentication Protocols", 10/20/1992.
  
  1661 W. Simpson, "The Point-to-Point Protocol (PPP)", 07/21/1994. (Obsoletes RFC1548)
  
  1570 W. Simpson, "PPP LCP Extensions", 01/11/1994. (Updates RFC1548)
  
  1663 D. Rand, "PPP Reliable Transmission", 07/21/1994.
  
  1332 PS G. McGregor, "The PPP Internet Protocol Control Protocol (IPCP)", 05/26/1992. (Obsoletes RFC1172)

- Some (16-bit) constants (defined in **sockmisc.h** ) are available with the port numbers for common TCP services:

```
#define  ECHO            7  /* TCP/UDP */
#define  DISCARD         9  /* TCP/UDP */
#define  FTP_DATA        20 /* TCP */
#define  FTP             21 /* TCP */
#define  TELNET_SERVER   23 /* TCP */
#define  NAME_SERVER     42 /* UDP */
#define  WHOIS           43 /* TCP */
#define  DOMAIN_SERVER   53 /* TCP/UDP */
#define  FINGER          79 /* TCP */
```

- The address data information with a `SocketAddress` structure takes the following form for the TCP domain:
  
  ```
  typedef struct {
  	word     TOEA_linkSize; 				/* 0 */
  	byte    TOEA_ipAddr[4]; /* IP address */
  }  TcpOnlyResolvedAddress;
  ```
  
  A variation on this structure is used for storing the address information for a TCP access point address. Along with the address information, there are three bytes of information about the nature of the link: the first of these bytes should have value LT\_ID, so that the driver will know that the next two bytes represent a link ID; the other two bytes should be the access point's ID.
  
  ```
  typedef struct {
  	word	TAPRA_linkSize; /* 3 */
  	byte	TAPRA_linkType; /* LinkType (LT_ID) */
  	word	TAPRA_accPntID;
  	byte	  TAPRA_ipAddr[4]; /* IP address */
  }  TcpAccPntResolvedAddress;
  ```



### 25.10.2 TCP/IP--Standard

This is the standard TCP/IP domain, popular protocol for internet communications.

**Domain Name:**

"TCPIP"

**Port Numbers:**

16-bit values.

**Opaque Address Format:**

This address will be either a `TcpAccPntExtendedAddress` ,a `TcpOnlyExtendedAddress` , or a `TcpNonAccPntExtendedAddress` .

TcpAccPntExtendedAddress: Use this structure when referring to an address identified by an access point ID number.

TcpOnlyExtendedAddress: Use this structure to identify a TCP address by its address instead of by its ID.

TcpNonAccPntExtendedAddress: Use this structure to identify a TCP address that is not a known access point. You will need to specify a link address (a phone number) as well as an IP address.

Notes:

- The notes for GEOS TCP/IP apply to the TCP/IP standard as well.
- You cannot use the sequential packets delivery type with standard TCP/IP.



### 25.10.3 Loopback

The loopback domain can only be used for communications between sockets on the same machine.

**Domain Name:**

"loopback"

**Port Numbers:**

32-bit values.

**Opaque Address Format:**

There is no address data: The loopback domain is used for intra-machine communication.