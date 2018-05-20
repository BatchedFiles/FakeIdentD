#include "Main.bi"
#include "IdentD.bi"

Function EntryPoint Alias "EntryPoint"()As Integer
	Dim pIdentD As IdentD = Any
	
	Dim IdentDInitializeResult As Integer = InitializeIdentD(@pIdentD)
	If IdentDInitializeResult <> 0 Then
		Return IdentDInitializeResult
	End If
	
	IdentDMainLoop(@pIdentD)
	
	UninitializeIdentD(@pIdentD)
	
	Return 0
End Function

EntryPoint()
