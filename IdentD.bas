#include "IdentD.bi"
#include "ReceiveData.bi"

Const ListenAddress = "0.0.0.0"
Const ListenPort = "113"

Function InitializeIdentD( _
		ByVal pIdentD As IdentD Ptr _
	)As Integer
	
	pIdentD->ClientRawBuffer[0] = 0
	pIdentD->ClientRawBufferLength = 0
	Scope
		Dim objWsaData As WSAData = Any
		If WSAStartup(MAKEWORD(2, 2), @objWsaData) <> NO_ERROR Then
			Return 1
		End If
	End Scope
	
	pIdentD->ListenSocket = CreateSocketAndListen(@ListenAddress, @ListenPort)
	If pIdentD->ListenSocket = INVALID_SOCKET Then
		WSACleanup()
		Return 2
	End If
	
	Return 0
End Function

Sub UninitializeIdentD( _
		ByVal pIdentD As IdentD Ptr _
	)
	
	CloseSocketConnection(pIdentD->ListenSocket)
	WSACleanup()
End Sub

Function IdentDMainLoop( _
		ByVal lpParam As LPVOID _
	)As DWORD
	
	Dim pIdentD As IdentD Ptr = lpParam
	
	Dim RemoteAddress As SOCKADDR_IN = Any
	Dim RemoteAddressLength As Long = SizeOf(RemoteAddress)
	pIdentD->ClientSocket = accept(pIdentD->ListenSocket, CPtr(SOCKADDR Ptr, @RemoteAddress), @RemoteAddressLength)
	
	Do While pIdentD->ClientSocket <> INVALID_SOCKET
		Dim ReceiveTimeOut As DWORD = 90 * 1000
		setsockopt(pIdentD->ClientSocket, SOL_SOCKET, SO_RCVTIMEO, CPtr(ZString Ptr, @ReceiveTimeOut), SizeOf(DWORD))
		
		'Server responds not only with
		'6191,23:USERID:WINNT:stjohns, but also with
		'6191,23:DOMAIN:WINNT:somedomain, and
		'6191,23:EXECUTABLE:WINNT:C:\Windows\System\Explorer.exe if applicable.
		
		Dim ClientRequest As WString * (IdentD.MaxBufferLength + 1) = Any
		
		If ReceiveData(pIdentD, @ClientRequest) = False Then
			Exit Do
		End If
		
		If lstrlen(@ClientRequest) > 0 Then
			#if __FB_DEBUG__ <> 0
				Print ClientRequest
			#endif
			
			Dim ServerResponse As WString * (IdentD.MaxBufferLength * 2 + 1) = Any
			lstrcpy(@ServerResponse, ClientRequest)
			lstrcat(@ServerResponse, @!" : USERID : WINNT : Qubick\r\n")
			
			#if __FB_DEBUG__ <> 0
				Print ServerResponse
			#endif
			
			Dim Utf8 As ZString * (IdentD.MaxBufferLength * 6 + 1) = Any
			
			Dim Utf8Length As Integer = WideCharToMultiByte(CP_UTF8, 0, @ServerResponse, -1, @Utf8, IdentD.MaxBufferLength * 6, 0, 0) - 1
			send(pIdentD->ClientSocket, @Utf8, Utf8Length, 0)
		End If
		
		CloseSocketConnection(pIdentD->ClientSocket)
		pIdentD->ClientSocket = accept(pIdentD->ListenSocket, CPtr(SOCKADDR Ptr, @RemoteAddress), @RemoteAddressLength)
	Loop
	Return 0
End Function
