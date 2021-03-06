#ifndef NETWORK_BI
#define NETWORK_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"

Declare Function ConnectToServer( _
	ByVal Server As WString Ptr, _
	ByVal Port As WString Ptr, _
	ByVal LocalAddress As WString Ptr, _
	ByVal LocalPort As WString Ptr _
)As SOCKET

Declare Function CreateSocketAndListen( _
	ByVal LocalAddress As WString Ptr, _
	ByVal LocalPort As WString Ptr _
)As SOCKET

Declare Sub CloseSocketConnection( _
	ByVal mSock As SOCKET _
)

Declare Function CreateSocketAndBind( _
	ByVal LocalAddress As WString Ptr, _
	ByVal LocalPort As WString Ptr _
)As SOCKET

Declare Function ResolveHost( _
	ByVal Server As WString Ptr, _
	ByVal Port As WString Ptr _
)As addrinfoW Ptr

#endif
