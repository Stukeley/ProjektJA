;-------------------------------------------------------------------------
;INCLUDE C:\masm32\include\windows.inc
.CODE

DllEntry PROC hInstDLL:DWORD, reason:DWORD, reserved1:DWORD

mov	eax, 1 	;TRUE
ret

DllEntry ENDP

;-------------------------------------------------------------------------
; This is an example function. It's here to show
; where to put your own functions in the DLL
;-------------------------------------------------------------------------

ApplyFilterToImageFragmentAsm proc bitmapBytes: DWORD, bitmapBytesLength: DWORD, startIndex: DWORD, endIndex: DWORD

mov	EAX, 1
ret

ApplyFilterToImageFragmentAsm endp

END
;-------------------------------------------------------------------------
