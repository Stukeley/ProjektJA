;-------------------------------------------------------------------------
;INCLUDE C:\masm32\include\windows.inc
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

ApplyFilterToImageFragmentAsm proc

; Jako test przekazywanych danych zsumujemy 10 pierwszych bajtów z tablicy i zwrócimy wynik
; w RCX zapisze sie wskaznik do danych (pierwszy parametr)
; w RDX rozmiar tablicy
; w R8 indeks pocz¹tkowy
; w R9 indeks koñcowy
; w razie przekazywania wiêkszej iloœci parametrów znajd¹ siê one na stosie
mov RAX, 0
xor RBX, RBX
Petla:
	movzx R8, BYTE PTR [RCX + RAX]
	add RBX, R8
	inc RAX
	cmp RAX, 10
	je Koniec
	jmp Petla
Koniec:
	mov RAX, RBX
	ret

ApplyFilterToImageFragmentAsm endp

END
;-------------------------------------------------------------------------
