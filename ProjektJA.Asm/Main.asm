; Temat: Filtr g�rnoprzepustowy "HP1" dla obraz�w typu Bitmap.
; Opis: Algorytm nak�ada filtr "HP1" dla pikseli obrazu typu Bitmap, podanego przez u�ytkownika przy pomocy interfejsu graficznego.
; Autor: Rafa� Klinowski, Informatyka, rok 3, sem. 5, gr. 5, data: 15.12.2021
; Wersja: 1.0.

;-------------------------------------------------------------------------
;INCLUDE C:\masm32\include\windows.inc

.DATA
SumOfMasks QWORD ?							; suma masek z poni�szej tablicy (zawsze sta�a, dla filtra HP1 r�wna 1)
Masks BYTE 0, -1, 0, -1, 5, -1, 0, -1, 0	; tablica masek 3x3
mask_80h BYTE 16 dup (80h)					; Zmienna pomocnicza do obliczenia sumy

.CODE

DllEntry PROC hInstDLL:DWORD, reason:DWORD, reserved1:DWORD

mov	eax, 1 	;TRUE
ret

DllEntry ENDP

;-------------------------------------------------------------------------
; Procedura obliczaj�ca sum� masek, zawartych w tablicy Masks, i zapisuj�ca j� do zmiennej SumOfMasks.
; Korzysta z instrukcji wektorowych do przechowania tablicy Masks w rejestrze xmm i ich zsumowania.
; Procedura nie oczekuje ani nie zwraca �adnych warto�ci.
;-------------------------------------------------------------------------
GetSumOfMasks proc

push RAX
push RDX

; Instrukcja wektorowa - movq, przenosz�ca dane z tablicy w pami�ci jako wektor do rejestru XMM
movq xmm3, QWORD PTR [Masks]
movsx EAX, BYTE PTR [Masks + 8]
movdqu xmm5, xmmword ptr [mask_80h]
pxor xmm3, xmm5

pxor xmm4, xmm4
; Instrukcja wektorowa - psadbw, sumuj�ca r�nice element�w dw�ch wektor�w; poniewa� suma wykonywana jest dla element�w bez znaku, w�wczas musimy przed i po zsumowaniu zmieni� zakres sumy
;						z liczby bez znaku na liczb� ze znakiem.
;						w zwi�zku z tym r�wnolegle odejmujemy przesuni�cia (zawarte w xmm3), a nast�pnie korygujemy za pomoc� instrukcji sub

psadbw xmm4, xmm3
movd EDX, xmm4
sub RAX, 8 * 80h
add RAX, RDX

mov SumOfMasks, RAX

pop RDX
pop RAX

ret

GetSumOfMasks endp

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

	; to ni�ej - todo
	;movdqu xmm10, xmmword ptr [Masks]
	;movdqu xmm11, xmmword ptr [RCX]

	;pmullw xmm11, xmm10

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
	movsx R13, BYTE PTR [R12 + 1 * R10]
	imul RDX, R13	; imageFragment[x + y * 3] * Masks[x + y * 3]
	add RAX, RDX	; newPixelWeightedValue += factor;
	inc RCX
	cmp RCX, 3
	jne Petla2
	inc RBX
	jmp Petla1

Koniec:
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

	; Dzielimy wynik (zmiennoprzecinkowo) przez sum� masek by zapobiec zmianie jasno�ci obrazu wyj�ciowego (tylko gdy suma jest r�na od 0).
	; Instrukcja wektorowa - divss, dziel�ca wektor (reprezentuj�cy liczb� zmiennoprzecinkow�) przez drugi.
	; Ponadto wykorzystano wektorow� instrukcje pxor, oraz instrukcje konwertuj�ce cvtsi2ss i cvttss2si.
	cmp SumOfMasks, 0
	je KoniecReturn

	pxor xmm3, xmm3
	pxor xmm4, xmm4

	cvtsi2ss xmm3, RAX
	cvtsi2ss xmm4, SumOfMasks
	divss xmm3, xmm4
	cvtss2si RAX, xmm3

	jmp KoniecReturn

KoniecReturn:
	; Przywracamy warto�ci rejestr�w R10, R11, R12 i R13 ze stosu
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
	; Inicjalizujemy sum� masek - jeden raz na wywo�anie programu
	call GetSumOfMasks

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