;-------------------------------------------------------------------------
;INCLUDE C:\masm32\include\windows.inc

.DATA
SumOfMasks QWORD 1
Masks QWORD 0, -1, 0, -1, 5, -1, 0, -1, 0

.CODE

DllEntry PROC hInstDLL:DWORD, reason:DWORD, reserved1:DWORD

mov	eax, 1 	;TRUE
ret

DllEntry ENDP

;-------------------------------------------------------------------------
; bitmapBytes - wskaŸnik na pierwszy element tablicy byte (8-bitowych liczb) odpowiadaj¹cy bitmapie
; bitmapBytesLength - d³ugoœæ tablicy byte
; startIndex - indeks pocz¹tkowy do przeprowadzenia algorytmu
; endIndex - indeks koñcowy do przeprowadzenia algorytmu
;-------------------------------------------------------------------------
CalculateNewPixelValue proc
	mov R11, RCX
	mov rax, 0
	mov RBX, 0
Petla1:
	mov RCX, 0
	cmp RBX, 3
	jz Koniec
	jmp Petla2
Petla2:
	mov R10, RCX
	imul R10, 3
	add R10, RBX

	movzx RDX, BYTE PTR [R11 + R10]
	LEA R12, Masks
	imul RDX, QWORD PTR [R12 + R10]
	add RAX, RDX
	inc RCX
	cmp RCX, 3
	jz Petla2
	inc RBX
	jmp Petla1
Koniec:
	cmp RAX, 0
	jl Zero
	cmp RAX, 255
	ja DwaPiecPiec
	ret

Zero:
	mov RAX, 0
	ret

DwaPiecPiec:
	mov RAX, 255
	ret

CalculateNewPixelValue endp

ApplyFilterToImageFragmentAsm proc
ApplyFilterToImageFragmentAsm endp
;-------------------------------------------------------------------------
END