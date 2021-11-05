;-------------------------------------------------------------------------
;INCLUDE C:\masm32\include\windows.inc
.CODE

DllEntry PROC hInstDLL:DWORD, reason:DWORD, reserved1:DWORD

mov	eax, 1 	;TRUE
ret

DllEntry ENDP

;-------------------------------------------------------------------------
; bitmapBytes - wska�nik na pierwszy element tablicy byte (8-bitowych liczb) odpowiadaj�cy bitmapie
; bitmapBytesLength - d�ugo�� tablicy byte
; startIndex - indeks pocz�tkowy do przeprowadzenia algorytmu
; endIndex - indeks ko�cowy do przeprowadzenia algorytmu
;-------------------------------------------------------------------------

ApplyFilterToImageFragmentAsm proc

; Jako test przekazywanych danych zsumujemy 10 pierwszych bajt�w z tablicy i zwr�cimy wynik
; w RCX zapisze sie wskaznik do danych (pierwszy parametr)
; w RDX rozmiar tablicy
; w R8 indeks pocz�tkowy
; w R9 indeks ko�cowy
; w razie przekazywania wi�kszej ilo�ci parametr�w znajd� si� one na stosie
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
