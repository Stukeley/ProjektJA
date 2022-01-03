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
; w rejestrze xmm4 znajduj� si� warto�ci pikseli R, G lub B na obszarze 3x3
; warto�� zwracana znajduje si� w rejestrze RAX po wywo�aniu funkcji.
;-------------------------------------------------------------------------
CalculateNewPixelValue proc

	; Dzia�anie poni�szego fragmentu kodu:
	; 1. Do rejestru xmm3 zapisujemy Maski, przekonwertowane (za pomoc� "sign extend") na warto�ci 16-bitowe
	; 2. Do rejestru xmm4 zapisujemy warto�ci tablicy przekazanej jako parametr, przekonwertowane na warto�ci 16-bitowe
	; 3. Mno�ymy poszczeg�lne warto�ci dw�ch wektor�w
	; 4. Sumujemy wymno�one warto�ci do uzyskania pojedynczej warto�ci

	; Instrukcja wektorowa - pmovsxbw, konwertuj�ca liczby 8-bitowe na 16-bitowe i zapisuj�ca je do wektora za pomoc� "sign-extend"
	;						 pmovzxbw - j.w., ale konwersja za pomoc� "zero-extend"
	;						 pmaddwd - mno��ca odpowiadaj�ce sobie liczby w dw�ch wektorach i sumuj�ca przyleg�e pary liczb
	;						 phaddd - sumuj�ca przyleg�e pary liczb w wektorze

StartCalc:
	movq xmm5, QWORD PTR [Masks]
	pmovsxbw xmm3, xmm5

	pmaddwd xmm3, xmm4

	phaddd xmm3, xmm3
	phaddd xmm3, xmm3

	xor RAX, RAX
	movd EAX, xmm3

	movsxd RAX, EAX

Koniec:
	; Instrukcja wektorowa - movq, przenosz�ca 64-bitow� liczb� ze znakiem z lub do rejestru XMM
	;						 maxpd, zwracaj�ca warto�� maksymaln�
	;						 minpd, zwracaj�ca warto�� minimaln�

	movq xmm14, RAX		; if (newPixelWeightedValue < 0) newPixelWeightedValue = 0;

	mov RBX, 0
	movq xmm15, RBX
	maxpd xmm14, xmm15

	mov RBX, 255		; if (newPixelWeightedValue > 255) newPixelWeightedValue = 255;
	movq xmm15, RBX
	minpd xmm14, xmm15

	movq RAX, xmm14

KoniecReturn:

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
	movq xmm0, RDX
	movq xmm1, R8
	movq xmm2, R9
	
									; [RSP + 40] - indeks ko�cowy
									; [RSP + 48] - wska�nik na bitmap� wyj�ciow�

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

	movq R11, xmm2	; i = R11

GlownaPetla:		; for (int i = startIndex; i <= endIndex; i += 3)

	mov R12, R11	; centerPixelIndex = i; (R12) !<- to ewentualnie mo�na wyeliminowa�, bo i == centerPixelIndex

	movq R13, xmm1 ; R13 = bitmapWidth

	cmp R12, R13	; if (centerPixelIndex < bitmapWidth)
	jl KoniecGlownejPetli

	mov RAX, R11	; if (i % bitmapWidth == 0) - dzielimy RAX przez RBX, reszta zapisana w RDX
	xor RDX, RDX
	movq RBX, xmm1
	div RBX

	cmp RDX, 0
	je KoniecGlownejPetli

	movq RBX, xmm0 ; if (i >= bitmapBytesLength - bitmapWidth)
	movq RCX, xmm1
	sub RBX, RCX
	cmp R12, RBX
	jge KoniecGlownejPetli

	mov RAX, R11		; if ((i + 2 + 1) % bitmapWidth == 0) - dzielimy RAX przez RBX, reszta zapisana w RDX
	add RAX, 3
	xor RDX, RDX
	movq RBX, xmm1
	div RBX

	cmp RDX, 0	
	je KoniecGlownejPetli

	xor R13, R13

	pxor xmm10, xmm10	; xmm10 - tablica pomocnicza R
	pxor xmm11, xmm11	; xmm11 - tablica pomocnicza G
	pxor xmm12, xmm12	; xmm12 - tablica pomocnicza B

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
	movq RCX, xmm1
	imul RAX, RCX

	add RBX, RAX
	add RBX, R12	; + centerPixelIndex

	mov RCX, R13	; x + y * 3
	imul RCX, 3
	add RCX, R14

	xor R15, R15

	mov R15B, BYTE PTR [R8 + RBX]	; R15B = bitmapBytes[index]

	pslldq xmm10, 2	; Shift w lewo o 2 bajty
	movd xmm4, R15D
	addps xmm10, xmm4

	inc RBX						; R15B = bitmapBytes[index + 1]
	mov R15B, BYTE PTR [R8 + RBX]

	pslldq xmm11, 2
	movd xmm4, R15D
	addps xmm11, xmm4

	inc RBX						; R15B = bitmapBytes[index + 2]
	mov R15B, BYTE PTR [R8 + RBX]

	pslldq xmm12, 2
	movd xmm4, R15D
	addps xmm12, xmm4

	inc R14
	cmp R14, 3
	jne GlownaPetlaX
	inc R13
	jmp GlownaPetlaY

KoniecPetliXY:

	; odwracamy kolejno�� w xmm10, xmm11, xmm12 (zapisywali�my odwrotnie ni� powinni�my poniewa� korzystali�my z przesuni�cia bitowego w lewo)

	movdqu xmm4, xmm10
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex] = CalculateNewPixelValue(valuesR);

	mov RDX, R11	; i - startIndex
	movq RCX, xmm2
	sub RDX, RCX

	mov BYTE PTR [R9 + RDX], AL	; wykorzystujemy AL, czyli dolne 8 bit�w rejestru RAX (w kt�rym jest warto�� zwracana z CalculateNewPixelValue)

	movdqu xmm4, xmm11
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex + 1] = CalculateNewPixelValue(valuesG);

	mov RDX, R11	; i - startIndex + 1
	movq RCX, xmm2
	sub RDX, RCX
	inc RDX

	mov BYTE PTR [R9 + RDX], AL	; wykorzystujemy AL, czyli dolne 8 bit�w rejestru RAX (w kt�rym jest warto�� zwracana z CalculateNewPixelValue)

	movdqu xmm4, xmm12
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex + 2] = CalculateNewPixelValue(valuesB);

	mov RDX, R11	; i - startIndex + 2
	movq RCX, xmm2
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