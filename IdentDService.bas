#include "IdentDService.bi"

Const MaxWaitHint As DWORD = 3000

Function EntryPoint Alias "EntryPoint"()As Integer
	Dim DispatchTable(1) As SERVICE_TABLE_ENTRY = Any
	DispatchTable(0).lpServiceName = @ServiceName
	DispatchTable(0).lpServiceProc = @SvcMain
	DispatchTable(1).lpServiceName = 0
	DispatchTable(1).lpServiceProc = 0
	
	If StartServiceCtrlDispatcher(@DispatchTable(0)) = 0 Then
		Return 1
	End If
	Return 0
End Function

Sub SvcMain( _
		ByVal dwNumServicesArgs As DWORD, _
		ByVal lpServiceArgVectors As LPWSTR ptr _
	)
	Dim Context As ServiceContext
	
	Context.ServiceStatusHandle = RegisterServiceCtrlHandlerEx(@ServiceName, @SvcCtrlHandlerEx, @Context)
	If Context.ServiceStatusHandle = 0 Then
		Exit Sub
	End If
	
	Context.ServiceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS
	Context.ServiceStatus.dwServiceSpecificExitCode = 0
	
	ReportSvcStatus(@Context, SERVICE_START_PENDING, NO_ERROR, MaxWaitHint)
	
	ReportSvcStatus(@Context, SERVICE_START_PENDING, NO_ERROR, MaxWaitHint)
	
	Scope
		Dim IdentDInitializeResult As Integer = InitializeIdentD(@Context.IdentD)
		If IdentDInitializeResult <> 0 Then
			ReportSvcStatus(@Context, SERVICE_STOPPED, NO_ERROR, 0)
			Exit Sub
		End If
		ReportSvcStatus(@Context, SERVICE_START_PENDING, NO_ERROR, MaxWaitHint)
	End Scope
	
	ReportSvcStatus(@Context, SERVICE_RUNNING, NO_ERROR, 0)
	
	IdentDMainLoop(@Context.IdentD)
	
	ReportSvcStatus(@Context, SERVICE_STOPPED, NO_ERROR, 0)
End Sub

Function SvcCtrlHandlerEx( _
		ByVal dwCtrl As DWORD, _
		ByVal dwEventType As DWORD, _
		ByVal lpEventData As LPVOID, _
		ByVal lpContext As LPVOID _
	)As DWORD
	
	Dim pServiceContext As ServiceContext Ptr = lpContext
	
	Select Case dwCtrl
		Case SERVICE_CONTROL_INTERROGATE
			ReportSvcStatus(pServiceContext, pServiceContext->ServiceStatus.dwCurrentState, NO_ERROR, 0)
			
		Case SERVICE_CONTROL_STOP
			ReportSvcStatus(pServiceContext, SERVICE_STOP_PENDING, NO_ERROR, MaxWaitHint)
			UninitializeIdentD(@pServiceContext->IdentD)
			
		Case Else
			Return ERROR_CALL_NOT_IMPLEMENTED
			
	End Select
	
	Return NO_ERROR
	
End Function
	
Sub ReportSvcStatus( _
		ByVal lpContext As ServiceContext Ptr, _
		ByVal dwCurrentState As DWORD, _
		ByVal dwWin32ExitCode As DWORD, _
		ByVal dwWaitHint As DWORD _
	)
	lpContext->ServiceStatus.dwCurrentState = dwCurrentState
	lpContext->ServiceStatus.dwWin32ExitCode = dwWin32ExitCode
	lpContext->ServiceStatus.dwWaitHint = dwWaitHint
	
	Select Case dwCurrentState
		Case SERVICE_STOPPED
			lpContext->ServiceStatus.dwCheckPoint = 0
			
		Case SERVICE_START_PENDING, SERVICE_STOP_PENDING
			lpContext->ServiceCheckPoint += 1
			lpContext->ServiceStatus.dwCheckPoint = lpContext->ServiceCheckPoint
			lpContext->ServiceStatus.dwControlsAccepted = 0
			
		Case SERVICE_RUNNING
			lpContext->ServiceStatus.dwCheckPoint = 0
			lpContext->ServiceStatus.dwControlsAccepted = SERVICE_ACCEPT_STOP
			
	End Select
	
	SetServiceStatus(lpContext->ServiceStatusHandle, @lpContext->ServiceStatus)
End Sub

EntryPoint()
