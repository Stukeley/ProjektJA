;-------------------------------------------------------------------------
;INCLUDE C:\masm32\include\windows.inc

.DATA
SumOfMasks QWORD 1							; suma masek z poni�szej tablicy (zawsze sta�a, dla filtra HP1 r�wna 1)
Masks QWORD 0, -1, 0, -1, 5, -1, 0, -1, 0	; tablica masek 3x3

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

	; Instrukcja wektorowa - movq, przenosz�ca 64-bitow� liczb� ze znakiem z lub do rejestru XMM
	;						 maxpd, zwracaj�ca warto�� maksymaln�
	;						 minpd, zwracaj�ca warto�� minimaln�

	movq xmm14, RAX		; if (newPixelWeightedValue < 0) newPixelWeightedValue = 0;
	mov R13, 0
	movq xmm15, R13
	maxpd xmm14, xmm15

	mov R13, 255		; if (newPixelWeightedValue > 255) newPixelWeightedValue = 255;
	movq xmm15, R13
	minpd xmm14, xmm15

	movq RAX, xmm14

	pop R13
	pop R12
	pop R11
	pop R10

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
	; Instrukcja wektorowa - cvtsi2sd, zamieniaj�ca liczb� ca�kowit� na wektor
	cvtsi2sd xmm0, RDX
	cvtsi2sd xmm1, R8
	cvtsi2sd xmm2, R9
	
									; [RSP + 40] - indeks ko�cowy
									; [RSP + 48] - wska�nik na bitmap� wyj�ciow�
									; [RSP + 56] - wska�nik na pomocnicz� tablic� warto�ci R
									; [RSP + 64] - wska�nik na pomocnicz� tablic� warto�ci G
									; [RSP + 72] - wska�nik na pomocnicz� tablic� warto�ci B

	mov R11, QWORD PTR [RSP + 40]	; R11 - ko�cowy indeks (tymczasowo)

	mov RDX, QWORD PTR [RSP + 48]	; RDX - wska�nik na bitmap� wyj�ciow� (tymczasowo)

	;mov EndIndex, R11

	inc R11			; R11 = endIndex - startIndex + 1 - ! to jest chyba niepotrzebne ju�
	sub R11, R9

	mov R8, RCX		; R8 = wska�nik na bitmap� wej�ciow�
	mov R9, RDX		; R9 = wska�nik na bitmap� wyj�ciow�

	jmp SetupGlownejPetli

SetupGlownejPetli:
	cvtsd2si R11, xmm2	; i = R11

GlownaPetla:		; for (int i = startIndex; i <= endIndex; i += 3)

	mov R12, R11	; centerPixelIndex = i; (R12) !<- to ewentualnie mo�na wyeliminowa�, bo i == centerPixelIndex

	; Instrukcja wektorowa - cvtsd2si, zamieniaj�ca wektor na liczb� ca�kowit�
	cvtsd2si R13, xmm1 ; R13 = bitmapWidth

	cmp R12, R13	; if (centerPixelIndex < bitmapWidth)
	jl KoniecGlownejPetli

	mov RAX, R11	; if (i % bitmapWidth == 0) - dzielimy RAX przez RBX, reszta zapisana w RDX
	xor RDX, RDX
	cvtsd2si RBX, xmm1
	div RBX

	cmp RDX, 0
	je KoniecGlownejPetli

	cvtsd2si RBX, xmm0 ; if (i >= bitmapBytesLength - bitmapWidth)
	cvtsd2si RCX, xmm1
	sub RBX, RCX
	cmp R12, RBX
	jge KoniecGlownejPetli

	mov RAX, R11		; if ((i + 2 + 1) % bitmapWidth == 0) - dzielimy RAX przez RBX, reszta zapisana w RDX
	add RAX, 3
	xor RDX, RDX
	cvtsd2si RBX, xmm1
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
	cvtsd2si RCX, xmm1
	imul RAX, RCX

	add RBX, RAX
	add RBX, R12	; + centerPixelIndex

	mov RCX, R13	; x + y * 3
	imul RCX, 3
	add RCX, R14

	mov R15B, BYTE PTR [R8 + RBX]	; R15B = bitmapBytes[index]
	mov RAX, QWORD PTR [RSP + 56]

	mov BYTE PTR [RAX + RCX], R15B ; valuesR[x + y * 3] = BL

	inc RBX						; R15B = bitmapBytes[index + 1]
	mov R15B, BYTE PTR [R8 + RBX]
	mov RAX, QWORD PTR [RSP + 64]

	mov BYTE PTR [RAX + RCX], R15B ; valuesG[x + y * 3] = BL

	inc RBX						; R15B = bitmapBytes[index + 2]
	mov R15B, BYTE PTR [R8 + RBX]
	mov RAX, QWORD PTR [RSP + 72]

	mov BYTE PTR [RAX + RCX], R15B ; valuesB[x + y * 3] = BL

	inc R14
	cmp R14, 3
	jne GlownaPetlaX
	inc R13
	jmp GlownaPetlaY

KoniecPetliXY:

	mov RCX, QWORD PTR [RSP + 56]	; adres ValuesR do RCX - przekazywany do procedury CalculateNewPixelValue
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex] = CalculateNewPixelValue(valuesR);

	mov RDX, R11	; i - startIndex
	cvtsd2si RCX, xmm2
	sub RDX, RCX

	mov BYTE PTR [R9 + RDX], AL	; wykorzystujemy AL, czyli dolne 8 bit�w rejestru RAX (w kt�rym jest warto�� zwracana z CalculateNewPixelValue)

	mov RCX, QWORD PTR [RSP + 64]	; adres ValuesG do RCX - przekazywany do procedury CalculateNewPixelValue
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex + 1] = CalculateNewPixelValue(valuesG);

	mov RDX, R11	; i - startIndex + 1
	cvtsd2si RCX, xmm2
	sub RDX, RCX
	inc RDX

	mov BYTE PTR [R9 + RDX], AL	; wykorzystujemy AL, czyli dolne 8 bit�w rejestru RAX (w kt�rym jest warto�� zwracana z CalculateNewPixelValue)

	mov RCX, QWORD PTR [RSP + 72]	; adres ValuesB do RCX - przekazywany do procedury CalculateNewPixelValue
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex + 2] = CalculateNewPixelValue(valuesB);

	mov RDX, R11	; i - startIndex + 2
	cvtsd2si RCX, xmm2
	sub RDX, RCX
	add RDX, 2

	mov BYTE PTR [R9 + RDX], AL ; wykorzystujemy AL, czyli dolne 8 bit�w rejestru RAX (w kt�rym jest warto�� zwracana z CalculateNewPixelValue)

	jmp KoniecGlownejPetli

KoniecGlownejPetli:
	add R11, 3
	cmp R11, QWORD PTR [RSP + 40]
	jg KoniecProgramu
	jmp GlownaPetla
	
KoniecProgramu:
	mov RAX, R9
	ret


ApplyFilterToImageFragmentAsm endp
;-------------------------------------------------------------------------
END