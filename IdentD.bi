#ifndef IDENTD_BI
#define IDENTD_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "Network.bi"

Type IdentD
	Const MaxBufferLength As Integer = 4096 - 1
	
	Dim ListenSocket As SOCKET
	Dim ClientSocket As SOCKET
	
	Dim ClientRawBuffer As ZString * (MaxBufferLength + 1)
	Dim ClientRawBufferLength As Integer
End Type

Declare Function InitializeIdentD( _
	ByVal pIdentD As IdentD Ptr _
)As Integer

Declare Sub UninitializeIdentD( _
	ByVal pIdentD As IdentD Ptr _
)

Declare Function IdentDMainLoop( _
	ByVal lpParam As LPVOID _
)As DWORD

#endif
