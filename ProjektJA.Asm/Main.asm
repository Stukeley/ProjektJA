;-------------------------------------------------------------------------
;INCLUDE C:\masm32\include\windows.inc

.DATA
SumOfMasks QWORD 1							; suma masek z poni�szej tablicy (zawsze sta�a, dla filtra HP1 r�wna 1)
Masks QWORD 0, -1, 0, -1, 5, -1, 0, -1, 0	; tablica masek 3x3

ValuesR BYTE 9 dup (0)	; tablica przechowuj�ca warto�ci R pikseli z obszaru 3x3
ValuesG BYTE 9 dup (0)	; tablica przechowuj�ca warto�ci G pikseli z obszaru 3x3
ValuesB BYTE 9 dup (0)	; tablica przechowuj�ca warto�ci B pikseli z obszaru 3x3

BitmapLength QWORD 0	; zmienna przechowuj�ca rozmiar bitmapy (zapisywana w pami�ci po rozpocz�ciu algorytmu)
BitmapWidth QWORD 0		; zmienna przechowuj�ca szeroko�� (zapisywana w pami�ci po rozpocz�ciu algorytmu)
StartIndex QWORD 0		; zmienna przechowuj�ca pocz�tkowy indeks, dla kt�rego mamy przeprowadzi� algorytm (zapisywana w pami�ci po rozpocz�ciu algorytmu)
EndIndex QWORD 0		; zmienna przechowuj�ca ko�cowy indeks, dla kt�rego mamy przeprowadzi� algorytm (zapisywana w pami�ci po rozpocz�ciu algorytmu)

.CODE

DllEntry PROC hInstDLL:DWORD, reason:DWORD, reserved1:DWORD

mov	eax, 1 	;TRUE
ret

DllEntry ENDP

;-------------------------------------------------------------------------
; Funkcja obliczaj�ca now� warto�� piksela na podstawie tablicy 3x3, zawieraj�cej warto�ci R, G lub B dla fragmentu bitmapy.
; w rejestrze RCX znajduje si� adres tablicy (3x3), dla kt�rej liczymy now� warto��.
; warto�� zwracana znajduje si� w rejestrze RAX po wywo�aniu funkcji.
;-------------------------------------------------------------------------
CalculateNewPixelValue proc
	; Zapisujemy warto�ci rejestr�w R10, R11, R12 i R13 na stosie
	push R10
	push R11
	push R12
	push R13
	
	mov R11, RCX	; przechowujemy adres parametru w R11
	mov RAX, 0
	mov RBX, 0
	lea R12, Masks	; Adres tablicy (ustawiamy tylko raz)

Petla1:				; for (int y = 0; y < 3; y++)
	mov RCX, 0
	cmp RBX, 3
	je Koniec
	jmp Petla2

Petla2:				; for (int x = 0; x < 3; x++)
	mov R10, RBX
	imul R10, 3
	add R10, RCX	; R10 = 3 * y + x

	movzx RDX, BYTE PTR [R11 + R10]
	mov R13, [R12 + 8 * R10]
	imul RDX, R13	; imageFragment[x + y * 3] * Masks[x + y * 3]
	add RAX, RDX	; newPixelWeightedValue += factor;
	inc RCX
	cmp RCX, 3
	jne Petla2
	inc RBX
	jmp Petla1

Koniec:
	; Przywracamy warto�ci rejestr�w R10, R11, R12 i R13 ze stosu
	pop R13
	pop R12
	pop R11
	pop R10

	cmp RAX, 0
	jl Zero
	cmp RAX, 255
	ja DwaPiecPiec
	ret

Zero:				; if (newPixelWeightedValue < 0) newPixelWeightedValue = 0;
	mov RAX, 0
	ret

DwaPiecPiec:		; if (newPixelWeightedValue > 255) newPixelWeightedValue = 255;
	mov RAX, 255
	ret

CalculateNewPixelValue endp

;-------------------------------------------------------------------------
; Funkcja nak�adaj�ca na fragment bitmapy filtr g�rnoprzepustowy.
; w rejestrze RCX znajduje si� wska�nik na ca�� bitmap�.
; w rejestrze RDX znajduje si� rozmiar bitmapy.
; w rejestrze R8 znajduje si� liczba oznaczaj�ca szeroko�� bitmapy.
; w rejestrze R9 znajduje si� pocz�tkowy indeks, dla kt�rego ma pracowa� ta funkcja.
; na stosie znajduje si� ko�cowy indeks, dla kt�rego ma pracowa� ta funkcja, oraz wska�nik na bitmap� wyj�ciow� o rozmiarze (endIndex - startIndex + 1).
;-------------------------------------------------------------------------
ApplyFilterToImageFragmentAsm proc

	xor R10, R10

	; Przeniesiemy poszczeg�lne parametry do zmiennych w pami�ci
	mov BitmapLength, RDX
	mov BitmapWidth, R8
	mov StartIndex, R9

	mov R11, QWORD PTR [RSP + 40]	; R11 - ko�cowy indeks (tymczasowo)

	mov RDX, QWORD PTR [RSP + 48]	; RDX - wska�nik na bitmap� wyj�ciow� (tymczasowo)

	mov EndIndex, R11

	inc R11			; R11 = endIndex - startIndex + 1 - ! to jest chyba niepotrzebne ju�
	sub R11, R9

	mov R8, RCX		; R8 = wska�nik na bitmap� wej�ciow�
	mov R9, RDX		; R9 = wska�nik na bitmap� wyj�ciow�

	jmp SetupGlownejPetli

SetupGlownejPetli:
	mov R11, StartIndex	; i = R11

GlownaPetla:		; for (int i = startIndex; i <= endIndex; i += 3)

	mov R12, R11	; centerPixelIndex = i; (R12) !<- to ewentualnie mo�na wyeliminowa�, bo i == centerPixelIndex

	mov R13, BitmapWidth ; R13 = bitmapWidth

	cmp R12, R13	; if (centerPixelIndex < bitmapWidth)
	jl KoniecGlownejPetli

	mov RAX, R11	; if (i % bitmapWidth == 0) - dzielimy RAX przez RBX, reszta zapisana w RDX
	xor RDX, RDX
	mov RBX, BitmapWidth
	div RBX

	cmp RDX, 0
	je KoniecGlownejPetli

	mov RBX, BitmapLength ; if (i >= bitmapBytesLength - bitmapWidth)
	sub RBX, BitmapWidth
	cmp R12, RBX
	jge KoniecGlownejPetli

	mov RAX, R11		; if ((i + 2 + 1) % bitmapWidth == 0) - dzielimy RAX przez RBX, reszta zapisana w RDX
	add RAX, 3
	xor RDX, RDX
	mov RBX, BitmapWidth
	div RBX

	cmp RDX, 0	
	je KoniecGlownejPetli

	xor R13, R13

GlownaPetlaY:		; for (int y = 0; y < 3; y++) (R13 = y)
	xor R14, R14
	cmp R13, 3
	je KoniecPetliXY
	jmp GlownaPetlaX

GlownaPetlaX:		; for (int x = 0; x < 3; x++) (R14 = x)

					; index = centerPixelIndex + (bitmapWidth * (y - 1) + (x - 1) * 3) (RBX)
	mov RBX, R14	; (x - 1) * 3
	dec RBX
	imul RBX, 3

	mov RAX, R13	; bitmapWidth * (y - 1)
	dec RAX
	imul RAX, BitmapWidth

	add RBX, RAX
	add RBX, R12	; + centerPixelIndex

	mov RCX, R13	; x + y * 3
	imul RCX, 3
	add RCX, R14

	mov R15B, BYTE PTR [R8 + RBX]	; R15B = bitmapBytes[index]
	lea RAX, ValuesR

	mov BYTE PTR [RAX + RCX], R15B ; valuesR[x + y * 3] = BL

	inc RBX						; R15B = bitmapBytes[index + 1]
	mov R15B, BYTE PTR [R8 + RBX]
	lea RAX, ValuesG

	mov BYTE PTR [RAX + RCX], R15B ; valuesG[x + y * 3] = BL

	inc RBX						; R15B = bitmapBytes[index + 2]
	mov R15B, BYTE PTR [R8 + RBX]
	lea RAX, ValuesB

	mov BYTE PTR [RAX + RCX], R15B ; valuesB[x + y * 3] = BL

	inc R14
	cmp R14, 3
	jne GlownaPetlaX
	inc R13
	jmp GlownaPetlaY

KoniecPetliXY:

	lea RCX, ValuesR	; adres ValuesR do RCX - przekazywany do procedury CalculateNewPixelValue
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex] = CalculateNewPixelValue(valuesR);

	mov RDX, R11	; i - startIndex
	sub RDX, StartIndex

	mov BYTE PTR [R9 + RDX], AL	; wykorzystujemy AL, czyli dolne 8 bit�w rejestru RAX (w kt�rym jest warto�� zwracana z CalculateNewPixelValue)

	lea RCX, ValuesG	; adres ValuesG do RCX - przekazywany do procedury CalculateNewPixelValue
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex + 1] = CalculateNewPixelValue(valuesG);

	mov RDX, R11	; i - startIndex + 1
	sub RDX, StartIndex
	inc RDX

	mov BYTE PTR [R9 + RDX], AL	; wykorzystujemy AL, czyli dolne 8 bit�w rejestru RAX (w kt�rym jest warto�� zwracana z CalculateNewPixelValue)

	lea RCX, ValuesB	; adres ValuesB do RCX - przekazywany do procedury CalculateNewPixelValue
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex + 2] = CalculateNewPixelValue(valuesB);

	mov RDX, R11	; i - startIndex + 2
	sub RDX, StartIndex
	add RDX, 2

	mov BYTE PTR [R9 + RDX], AL ; wykorzystujemy AL, czyli dolne 8 bit�w rejestru RAX (w kt�rym jest warto�� zwracana z CalculateNewPixelValue)

	jmp KoniecGlownejPetli

KoniecGlownejPetli:
	add R11, 3
	cmp R11, EndIndex
	jg KoniecProgramu
	jmp GlownaPetla
	
KoniecProgramu:
	mov RAX, R9
	ret


ApplyFilterToImageFragmentAsm endp
;-------------------------------------------------------------------------
END