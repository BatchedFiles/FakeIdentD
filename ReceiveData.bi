#ifndef RECEIVEDATA_BI
#define RECEIVEDATA_BI

#include "IdentD.bi"

Declare Function ReceiveData( _
	ByVal pIdentD As IdentD Ptr, _
	ByVal strReceiveData As WString Ptr _
)As Boolean

#endif
