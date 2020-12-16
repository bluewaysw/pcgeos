/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	  SSL
 * MODULE:	  SSL library
 * FILE:	  ssl.goh
 *
 * AUTHOR:  	  Brian Chin: Nov  16, 1998
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	brianc	11/16/98   	Initial version
 *
 * DESCRIPTION:
 *	SSL library C interface
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _SSL_H_
#define _SSL_H_

/* ############################################################################
 * 		       SSL data types
 * ##########################################################################*/

/* only provided for type-checking */
typedef void SSL_METHOD;
typedef void SSL_CTX;
typedef void SSL;

/* ############################################################################
 * 			       User API
 * ##########################################################################*/

void _pascal SSLeay_add_ssl_algorithms(void);

/*
 * pass returned value to SSL_CTX_new
 */
SSL_METHOD* _pascal SSLv2_client_method(void);
SSL_METHOD* _pascal SSLv3_client_method(void);
SSL_METHOD* _pascal SSLv23_client_method(void);

/*
 * SSL context.  There only needs to be one per client.
 */
SSL_CTX* _pascal _export SSL_CTX_new(SSL_METHOD *meth);
void _pascal SSL_CTX_free(SSL_CTX *);

/*
 * SSL connection.  There needs to be one per connection.
 */
SSL* __pascal SSL_new(SSL_CTX *ctx);
void _pascal SSL_free(SSL *ssl);

/*
 * Set socket for SSL connection, per connection, after SocketCreate.
 */
int _pascal SSL_set_fd(SSL *ssl, int fd);

/*
 * Connect, after SocketConnect.
 */
int _pascal SSL_connect(SSL *ssl);

/*
 * Read and write through socket after SSL_connect, in place of SocketRecv
 * and SocketSend.  Error from ThreadGetError() if return <= 0.
 */
int _pascal SSL_read(SSL *ssl,char *buf,int num);
int _pascal SSL_write(SSL *ssl,char *buf,int num);

/*
 * Shutdown, before SocketClose, and before SSL_free.
 */
int _pascal SSL_shutdown(SSL *s);

/*
 * version
 */
SSL_METHOD * _pascal SSL_get_ssl_method(SSL *s);
int _pascal SSL_set_ssl_method(SSL *s, SSL_METHOD *meth);

#endif /* _SSL_H_ */
