#include "ReceiveData.bi"

Function FindCrLfA( _
		ByVal pIdentD As IdentD Ptr, _
		ByVal pFindIndex As Integer Ptr _
	)As Boolean
	' Минус 2 потому что один байт под Lf и один, чтобы не выйти за границу
	For i As Integer = 0 To pIdentD->ClientRawBufferLength - 2
		If pIdentD->ClientRawBuffer[i] = 13 AndAlso pIdentD->ClientRawBuffer[i + 1] = 10 Then
			*pFindIndex = i
			Return True
		End If
	Next
	*pFindIndex = 0
	Return False
End Function

Function ReceiveData( _
		ByVal pIdentD As IdentD Ptr, _
		ByVal strReceiveData As WString Ptr _
	)As Boolean
	
	' Ищем в буфере символы CrLf
	' Если они есть, то возвращаем строку до CrLf
	' иначе получаем данные, добавляя их в буфер, до тех пор, пока не появятся CrLf
	Dim CrLfIndex As Integer = 0
	Dim FindCrLfResult As Boolean = FindCrLfA(pIdentD, @CrLfIndex)
	
	Do While FindCrLfResult = False
		' Проверить размер текущего накопительного буфера
		' Если он заполнен, то вернуть его весь
		
		If pIdentD->ClientRawBufferLength >= IdentD.MaxBufferLength Then
			' Буфер заполнен, вернуть его весь
			CrLfIndex = IdentD.MaxBufferlength
			pIdentD->ClientRawBufferLength = IdentD.MaxBufferLength
			Exit Do
		Else
			' Получаем данные
			Dim intReceivedBytesCount As Integer = recv(pIdentD->ClientSocket, @pIdentD->ClientRawBuffer + pIdentD->ClientRawBufferLength, IdentD.MaxBufferLength - pIdentD->ClientRawBufferLength, 0)
			
			Select Case intReceivedBytesCount
				Case SOCKET_ERROR
					' Ошибка, так как должно быть как минимум 1 байт на блокирующем сокете
					strReceiveData[0] = 0
					Return False
				Case 0
					' Клиент закрыл соединение
					strReceiveData[0] = 0
					Return False
				Case Else
					' Увеличить размер буфера на количество принятых байт
					pIdentD->ClientRawBufferLength += intReceivedBytesCount
					' Заключительный нулевой символ
					pIdentD->ClientRawBuffer[pIdentD->ClientRawBufferLength] = 0
			End Select
		End If
		FindCrLfResult = FindCrLfA(pIdentD, @CrLfIndex)
	Loop
	
	pIdentD->ClientRawBuffer[CrLfIndex] = 0
	
	MultiByteToWideChar(CP_UTF8, 0, @pIdentD->ClientRawBuffer, -1, strReceiveData, IdentD.MaxBufferLength + 1)
	
	' Сдвинуть буфер влево
	If IdentD.MaxBufferLength - CrLfIndex = 0 Then
		pIdentD->ClientRawBuffer[0] = 0
		pIdentD->ClientRawBufferLength = 0
	Else
		Dim NextCharIndex As Integer = CrLfIndex + 2
		If NextCharIndex = pIdentD->ClientRawBufferLength Then
			pIdentD->ClientRawBuffer[0] = 0
			pIdentD->ClientRawBufferLength = 0
		Else
			memmove(@pIdentD->ClientRawBuffer, @pIdentD->ClientRawBuffer + NextCharIndex, IdentD.MaxBufferLength - NextCharIndex + 1)
			pIdentD->ClientRawBufferLength -= NextCharIndex
		End If
	End If
	
	Return True
End Function
