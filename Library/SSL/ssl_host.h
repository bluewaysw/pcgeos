#ifndef HEADER_SSL_HOST_H 
#define HEADER_SSL_HOST_H 

#ifdef  __cplusplus
extern "C" {
#endif

typedef ByteEnum SSLHostFunctionNumber;   
#define SSLHFN_SSLV2_CLIENT_METHOD		0
#define SSLHFN_SSLEAY_ADD_SSL_ALGORITHMS	1
#define SSLHFN_SSL_CTX_NEW			2
#define SSLHFN_SSL_CTX_FREE			3
#define SSLHFN_SSL_NEW				4
#define SSLHFN_SSL_FREE				5
#define SSLHFN_SSL_SET_FD			6
#define SSLHFN_SSL_CONNECT			7
#define SSLHFN_SSL_SHUTDOWN			8
#define SSLHFN_SSL_READ				9
#define SSLHFN_SSL_WRITE			10
#define SSLHFN_SSLV23_CLIENT_METHOD		11
#define SSLHFN_SSLV3_CLIENT_METHOD		12
#define SSLHFN_SSL_GET_SSL_METHOD		13
#define SSLHFN_SET_CALLBACK			14
#define SSLHFN_SSL_SET_TLSEXT_HOST_NAME		15


extern Boolean _far _pascal SSLCheckHost();
extern dword _far _pascal SSLCallHost(SSLHostFunctionNumber callID, 
					dword data, dword data2, word data3);


#ifdef  __cplusplus
}
#endif
#endif
