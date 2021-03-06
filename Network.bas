#include once "Network.bi"

Sub CloseSocketConnection(ByVal mSock As SOCKET)
	shutdown(mSock, SD_BOTH)
	closesocket(mSock)
End Sub

Function ResolveHost(ByVal sServer As WString Ptr, ByVal Port As WString Ptr)As addrinfoW Ptr
	Dim hints As addrinfoW
	
	hints.ai_family = AF_UNSPEC ' AF_INET или AF_INET6
	hints.ai_socktype = SOCK_STREAM
	hints.ai_protocol = IPPROTO_TCP
	
	Dim pResult As addrinfoW Ptr = 0
	If GetAddrInfoW(sServer, Port, @hints, @pResult) = 0 Then
		Return pResult
	End If
	Return 0
End Function

Function CreateSocketAndBind(ByVal sServer As WString Ptr, ByVal Port As WString Ptr)As SOCKET
	Dim iSocket As SOCKET = socket_(AF_UNSPEC, SOCK_STREAM, IPPROTO_TCP)
	
	If iSocket <> INVALID_SOCKET Then
		Dim localIpList As addrinfoW Ptr = ResolveHost(sServer, Port)
		
		If localIpList <> 0 Then
			Dim pPtr As addrinfoW Ptr = localIpList
			Dim BindResult As Integer = Any
			
			Do
				BindResult = bind(iSocket, Cast(LPSOCKADDR, pPtr->ai_addr), pPtr->ai_addrlen)
				If BindResult = 0 Then
					Exit Do
				End If
				pPtr = pPtr->ai_next
			Loop Until pPtr = 0
			
			FreeAddrInfoW(localIpList)
			
			If BindResult = 0 Then
				Return iSocket
			End If
		End If
		
		CloseSocketConnection(iSocket)
	End If
	
	Return INVALID_SOCKET
End Function

Function CreateSocketAndListen(ByVal LocalAddress As WString Ptr, ByVal LocalPort As WString Ptr)As SOCKET
	Dim iSocket As SOCKET = CreateSocketAndBind(LocalAddress, LocalPort)
	
	If iSocket <> INVALID_SOCKET Then
		If listen(iSocket, 1) <> SOCKET_ERROR Then
			Return iSocket
		End If
		CloseSocketConnection(iSocket)
	End If
	
	Return INVALID_SOCKET
End Function

Function ConnectToServer(ByVal sServer As WString Ptr, ByVal Port As WString Ptr, ByVal LocalAddress As WString Ptr, ByVal LocalPort As WString Ptr)As SOCKET
	Dim iSocket As SOCKET = CreateSocketAndBind(LocalAddress, LocalPort)
	If iSocket <> INVALID_SOCKET Then
		Dim localIpList As addrinfoW Ptr = ResolveHost(sServer, Port)
		If localIpList <> 0 Then
			Dim pPtr As addrinfoW Ptr = localIpList
			Dim ConnectResult As Integer = Any
			Do
				ConnectResult = connect(iSocket, Cast(LPSOCKADDR, pPtr->ai_addr), pPtr->ai_addrlen)
				If ConnectResult = 0 Then
					Exit Do
				End If
				pPtr = pPtr->ai_next
			Loop Until pPtr = 0
			FreeAddrInfoW(localIpList)
			If ConnectResult = 0 Then
				Return iSocket
			End If
		End If
		CloseSocketConnection(iSocket)
	End If
	Return INVALID_SOCKET
End Function
