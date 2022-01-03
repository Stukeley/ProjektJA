; Temat: Filtr górnoprzepustowy "HP1" dla obrazów typu Bitmap.
; Opis: Algorytm nak³ada filtr "HP1" dla pikseli obrazu typu Bitmap, podanego przez u¿ytkownika przy pomocy interfejsu graficznego.
; Autor: Rafa³ Klinowski, Informatyka, rok 3, sem. 5, gr. 5, data: 15.12.2021
; Wersja: 1.0.

;-------------------------------------------------------------------------
;INCLUDE C:\masm32\include\windows.inc

.DATA
SumOfMasks QWORD ?							; suma masek z poni¿szej tablicy (zawsze sta³a, dla filtra HP1 równa 1)
Masks BYTE 0, -1, 0, -1, 5, -1, 0, -1, 0	; tablica masek 3x3
mask_80h BYTE 16 dup (80h)					; Zmienna pomocnicza do obliczenia sumy

.CODE

DllEntry PROC hInstDLL:DWORD, reason:DWORD, reserved1:DWORD

mov	eax, 1 	;TRUE
ret

DllEntry ENDP

;-------------------------------------------------------------------------
; Procedura obliczaj¹ca sumê masek, zawartych w tablicy Masks, i zapisuj¹ca j¹ do zmiennej SumOfMasks.
; Korzysta z instrukcji wektorowych do przechowania tablicy Masks w rejestrze xmm i ich zsumowania.
; Procedura nie oczekuje ani nie zwraca ¿adnych wartoœci.
;-------------------------------------------------------------------------
GetSumOfMasks proc

push RAX
push RDX

; Instrukcja wektorowa - movq, przenosz¹ca dane z tablicy w pamiêci jako wektor do rejestru XMM
movq xmm3, QWORD PTR [Masks]
movsx EAX, BYTE PTR [Masks + 8]
movdqu xmm5, xmmword ptr [mask_80h]
pxor xmm3, xmm5

pxor xmm4, xmm4
; Instrukcja wektorowa - psadbw, sumuj¹ca ró¿nice elementów dwóch wektorów; poniewa¿ suma wykonywana jest dla elementów bez znaku, wówczas musimy przed i po zsumowaniu zmieniæ zakres sumy
;						z liczby bez znaku na liczbê ze znakiem.
;						w zwi¹zku z tym równolegle odejmujemy przesuniêcia (zawarte w xmm3), a nastêpnie korygujemy za pomoc¹ instrukcji sub

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
; Funkcja obliczaj¹ca now¹ wartoœæ piksela na podstawie tablicy 3x3, zawieraj¹cej wartoœci R, G lub B dla fragmentu bitmapy.
; w rejestrze xmm4 znajduj¹ siê wartoœci pikseli R, G lub B na obszarze 3x3
; wartoœæ zwracana znajduje siê w rejestrze RAX po wywo³aniu funkcji.
;-------------------------------------------------------------------------
CalculateNewPixelValue proc

	; Dzia³anie poni¿szego fragmentu kodu:
	; 1. Do rejestru xmm3 zapisujemy Maski, przekonwertowane (za pomoc¹ "sign extend") na wartoœci 16-bitowe
	; 2. Do rejestru xmm4 zapisujemy wartoœci tablicy przekazanej jako parametr, przekonwertowane na wartoœci 16-bitowe
	; 3. Mno¿ymy poszczególne wartoœci dwóch wektorów
	; 4. Sumujemy wymno¿one wartoœci do uzyskania pojedynczej wartoœci

	; Instrukcja wektorowa - pmovsxbw, konwertuj¹ca liczby 8-bitowe na 16-bitowe i zapisuj¹ca je do wektora za pomoc¹ "sign-extend"
	;						 pmovzxbw - j.w., ale konwersja za pomoc¹ "zero-extend"
	;						 pmaddwd - mno¿¹ca odpowiadaj¹ce sobie liczby w dwóch wektorach i sumuj¹ca przyleg³e pary liczb
	;						 phaddd - sumuj¹ca przyleg³e pary liczb w wektorze

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
	; Instrukcja wektorowa - movq, przenosz¹ca 64-bitow¹ liczbê ze znakiem z lub do rejestru XMM
	;						 maxpd, zwracaj¹ca wartoœæ maksymaln¹
	;						 minpd, zwracaj¹ca wartoœæ minimaln¹

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
; Funkcja nak³adaj¹ca na fragment bitmapy filtr górnoprzepustowy.
; w rejestrze RCX znajduje siê wskaŸnik na ca³¹ bitmapê.
; w rejestrze RDX znajduje siê rozmiar bitmapy.
; w rejestrze R8 znajduje siê liczba oznaczaj¹ca szerokoœæ bitmapy.
; w rejestrze R9 znajduje siê pocz¹tkowy indeks, dla którego ma pracowaæ ta funkcja.
; na stosie znajduje siê koñcowy indeks, dla którego ma pracowaæ ta funkcja, oraz wskaŸnik na bitmapê wyjœciow¹ o rozmiarze (endIndex - startIndex + 1).
;-------------------------------------------------------------------------
ApplyFilterToImageFragmentAsm proc

	xor R10, R10

	; Przeniesiemy poszczególne parametry do zmiennych w pamiêci
	movq xmm0, RDX
	movq xmm1, R8
	movq xmm2, R9
	
									; [RSP + 40] - indeks koñcowy
									; [RSP + 48] - wskaŸnik na bitmapê wyjœciow¹

	mov R11, QWORD PTR [RSP + 40]	; R11 - koñcowy indeks (tymczasowo)

	mov RDX, QWORD PTR [RSP + 48]	; RDX - wskaŸnik na bitmapê wyjœciow¹ (tymczasowo)

	;mov EndIndex, R11

	inc R11			; R11 = endIndex - startIndex + 1 - ! to jest chyba niepotrzebne ju¿
	sub R11, R9

	mov R8, RCX		; R8 = wskaŸnik na bitmapê wejœciow¹
	mov R9, RDX		; R9 = wskaŸnik na bitmapê wyjœciow¹

	jmp SetupGlownejPetli

SetupGlownejPetli:
	; Inicjalizujemy sumê masek - jeden raz na wywo³anie programu
	call GetSumOfMasks

	movq R11, xmm2	; i = R11

GlownaPetla:		; for (int i = startIndex; i <= endIndex; i += 3)

	mov R12, R11	; centerPixelIndex = i; (R12) !<- to ewentualnie mo¿na wyeliminowaæ, bo i == centerPixelIndex

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

	; odwracamy kolejnoœæ w xmm10, xmm11, xmm12 (zapisywaliœmy odwrotnie ni¿ powinniœmy poniewa¿ korzystaliœmy z przesuniêcia bitowego w lewo)

	movdqu xmm4, xmm10
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex] = CalculateNewPixelValue(valuesR);

	mov RDX, R11	; i - startIndex
	movq RCX, xmm2
	sub RDX, RCX

	mov BYTE PTR [R9 + RDX], AL	; wykorzystujemy AL, czyli dolne 8 bitów rejestru RAX (w którym jest wartoœæ zwracana z CalculateNewPixelValue)

	movdqu xmm4, xmm11
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex + 1] = CalculateNewPixelValue(valuesG);

	mov RDX, R11	; i - startIndex + 1
	movq RCX, xmm2
	sub RDX, RCX
	inc RDX

	mov BYTE PTR [R9 + RDX], AL	; wykorzystujemy AL, czyli dolne 8 bitów rejestru RAX (w którym jest wartoœæ zwracana z CalculateNewPixelValue)

	movdqu xmm4, xmm12
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex + 2] = CalculateNewPixelValue(valuesB);

	mov RDX, R11	; i - startIndex + 2
	movq RCX, xmm2
	sub RDX, RCX
	add RDX, 2

	mov BYTE PTR [R9 + RDX], AL ; wykorzystujemy AL, czyli dolne 8 bitów rejestru RAX (w którym jest wartoœæ zwracana z CalculateNewPixelValue)

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