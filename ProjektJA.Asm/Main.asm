;-------------------------------------------------------------------------
;INCLUDE C:\masm32\include\windows.inc

.DATA
SumOfMasks QWORD 1
Masks QWORD 0, -1, 0, -1, 5, -1, 0, -1, 0

ValuesR BYTE 9 dup (0)	; tablica przechowuj¹ca wartoœci R pikseli z obszaru 3x3
ValuesG BYTE 9 dup (0)	; tablica przechowuj¹ca wartoœci G pikseli z obszaru 3x3
ValuesB BYTE 9 dup (0)	; tablica przechowuj¹ca wartoœci B pikseli z obszaru 3x3

BitmapLength QWORD 0
BitmapWidth QWORD 0
StartIndex QWORD 0
EndIndex QWORD 0

.CODE

DllEntry PROC hInstDLL:DWORD, reason:DWORD, reserved1:DWORD

mov	eax, 1 	;TRUE
ret

DllEntry ENDP

;-------------------------------------------------------------------------
; Funkcja obliczaj¹ca now¹ wartoœæ piksela na podstawie tablicy 3x3, zawieraj¹cej wartoœci R, G lub B dla fragmentu bitmapy.
; w rejestrze RCX znajduje siê adres tablicy (3x3), dla której liczymy now¹ wartoœæ.
; wartoœæ zwracana znajduje siê w rejestrze RAX po wywo³aniu funkcji.
;-------------------------------------------------------------------------
CalculateNewPixelValue proc
	mov R11, RCX	; Problem - korzystamy z R11 i R12 i R13 i R10 który jest zajêty - stos?
	mov RAX, 0
	mov RBX, 0
	LEA R12, Masks	; Adres tablicy (ustawiamy tylko raz)

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
; Funkcja nak³adaj¹ca na fragment bitmapy filtr górnoprzepustowy.
; w rejestrze RCX znajduje siê wskaŸnik na ca³¹ bitmapê.
; w rejestrze RDX znajduje siê rozmiar bitmapy.
; w rejestrze R8 znajduje siê liczba oznaczaj¹ca szerokoœæ bitmapy.
; w rejestrze R9 znajduje siê pocz¹tkowy indeks, dla którego ma pracowaæ ta funkcja.
; na stosie znajduje siê koñcowy indeks, dla którego ma pracowaæ ta funkcja, oraz wskaŸnik na bitmapê wyjœciow¹ o rozmiarze (endIndex - startIndex + 1).
;-------------------------------------------------------------------------
ApplyFilterToImageFragmentAsm proc

	xor R10, R10

					; Przeniesiemy poszczególne parametry do zmiennych w kodzie
	mov BitmapLength, RDX
	mov BitmapWidth, R8
	mov StartIndex, R9

	pop RDX

	pop R11
	mov EndIndex, R11
	;debug only
	mov EndIndex, 68855

	inc R11			; R11 = endIndex - startIndex + 1
	sub R11, R9

	mov R8, RCX		; R8 = wskaŸnik na bitmapê wejœciow¹
	mov R9, RDX		; R9 = wskaŸnik na bitmapê wyjœciow¹

Inicjalizacja:		; To mo¿e ju¿ byæ niepotrzebne

	; filteredFragment[i] = bitmapBytes[startIndex + i]
	inc R10
	cmp R10, R11
	jge SetupGlownejPetli
	jmp Inicjalizacja

SetupGlownejPetli:
	mov R11, StartIndex	; i = R11

GlownaPetla:		; for (int i = startIndex; i <= endIndex; i += 3)

	mov R12, R11	; centerPixelIndex = i; (R12)

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

	mov BL, BYTE PTR [R8 + RBX]
	lea RAX, ValuesR

	mov BYTE PTR [RAX + RCX], BL

	inc RDX
	lea RAX, ValuesG

	mov BYTE PTR [RAX + RCX], BL

	inc RDX
	lea RAX, ValuesB

	mov BYTE PTR [RAX + RCX], BL

	inc R14
	cmp R14, 3
	jne GlownaPetlaX
	inc R13
	jmp GlownaPetlaY

KoniecPetliXY:
	;mov R15, R11
	;sub R15, StartIndex ;!?

	lea RCX, ValuesR
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex] = CalculateNewPixelValue(valuesR);

	mov RDX, R11	; i - startIndex
	sub RDX, StartIndex

	mov [R9 + RDX], RAX

	lea RCX, ValuesG
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex + 1] = CalculateNewPixelValue(valuesG);

	mov RDX, R11	; i - startIndex + 1
	sub RDX, StartIndex
	inc RDX

	mov [R9 + RDX], RAX

	lea RCX, ValuesB
	call CalculateNewPixelValue

	; filteredFragment[i - startIndex + 2] = CalculateNewPixelValue(valuesB);

	mov RDX, R11	; i - startIndex + 2
	sub RDX, StartIndex
	add RDX, 2

	mov [R9 + RDX], RAX

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