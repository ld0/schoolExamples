;-------------------------------------------
;-------------------------------------------
; FinalProject.asm
; Implement a Discrete Logarithm Calculator
; In x86 assembly
; L D 
; MATH4530 CSCI4130
; May 1 2015  
;-------------------------------------------
; I use standard Microsoft library functions
; and functions from the Irvine library
; to handle reading from console, writing to window, etc,
; and use a custom created functions
; to do the actual calculations.
;-------------------------------------------
; This program was written and compiled in MASM
; On Windows 7 32-bit version of Visual Studio
;-------------------------------------------
;-------------------------------------------

Include Irvine32.inc		; include these libraries 
Include Macros.inc			; to get access to a few different Windows functions
Include GraphWin.inc 
Includelib user32.lib

.686p
.mmx

; declaring variables for use
; most are intiialized to 0

.data

	showResultCount DWORD 0
	mBoxCaption BYTE "Discrete Logarithm Calculator",0
	mBoxTextGen BYTE "Please enter generator. ",0
	mBoxTextNum BYTE "Please enter number. ",0
	mBoxTextPrime BYTE "Please enter prime. ",0
	mBoxTextResult BYTE "The discrete log is: ", 10 DUP(1)	; allow room size of DWORD
	; size is 21
	resultArray BYTE 10 DUP(0)
	
	; general information storage 

	exponent DWORD 0
	prime DWORD 0
	temp1 DWORD 0
	temp2 DWORD 0
	number DWORD 0
 	floor DWORD 0
	counter DWORD 0
	generator DWORD 0

	; for use in ModPow specifically 
	; SDWORD for signed 

	mpinput SDWORD 0
	mpexponent SDWORD 0
	mpexptemp SDWORD 0
	mpresult SDWORD 1
	mpcounter SDWORD 1
	mptemp SDWORD 0
	mpIndex SDWORD 4
	mpArray DWORD 100 DUP(?)

	; for use in the list calculation
	 array DWORD 100 DUP(?) 	; just size 100
	arraySize DWORD 0
	listCalcIndex DWORD 0
	listCalcTemp DWORD 1 

	; for the comparison
	invG DWORD 0
	temp DWORD 0
	discLog DWORD 0
	cmpcounter DWORD 0
	cmpIndex DWORD 0
	cmpInnerCounter DWORD 0
	cmpH DWORD 0 

	; for the square root function
	; REAL8 for the floating point precisions 
	d_zero REAL8 0.0
	d_two REAL8 2.0
	d_small REAL8 0.0
	d_large REAL8 0.0
	d_add REAL8 0.0
	d_mult REAL8 0.0
	d_num REAL8 0.0
	d_temp REAL8 0.0
	; the biggest difference that can be had
	; between our fp result and the original number
	d_min REAL8 1.0E-17
	; result
	sqrt DWORD 0

	num_temp WORD 25
	d_num_temp REAL8 4.0	; testing purposes
	d_trash REAL8 0.0		; to pop stack values on to just get rid of them

	; for use in euclidean calcultor
	quotient SDWORD 0
	etemp SDWORD 0
	unusedtemp SDWORD 0
	newTemp SDWORD 1
	oldTemp SDWORD 0
	remainder SDWORD ?		; to be the prime
	newRemainder SDWORD ?	; to be the other number
	oldRemainder SDWORD 0
	qtimesT SDWORD 0
	euclAnswer SDWORD 0

	; -----

.code
; the main procedure
main PROC

		; get the user's values

		call GetPrime
		call GetGenerator
		call GetNumber
		
		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx
		mov eax, prime
		mov ebx, generator
		mov ecx, number
		; nop				; breakpoint used in slide demonstrations
							; to show current values

		call Go				; function that holds all other ones

		xor eax, eax
		mov eax, discLog
		; nop				; for checking

		call ShowResult

		invoke ExitProcess, 0	; all return here to leave

main ENDP

;-------------
; All functions
Go PROC
;-------------

	call CalcFloor
	call ListCalc
	call Compare
	ret

Go ENDP
;------------------

;-----------------
; Extended Euclidean Algorithm calculator 
; for getting modular inverse
; Initial values:
; quotient = 0
; temp = 0
; newTemp = 1
; oldTemp = 0
; remainder = prime
; newRemainder = generator
; oldremainder = 0
;
EuclideanCalculator PROC
;------------

	; clear registers
	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx

	mov eax, generator
	mov newRemainder, eax
	xor eax, eax

	mov ebx, prime
	mov remainder, ebx
	xor ebx, ebx

	L1: ; --- 

		; examining all the values, for debugging purposes
		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx

		mov eax, quotient
		mov ebx, eTemp
		mov ecx, newTemp
		mov edx, oldTemp
		; place breakpoint here
		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx

		mov eax, remainder
		mov ebx, newRemainder
		mov ecx, oldRemainder
		; place breakpoint here
		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx

		; getting each remainder progressively smaller
		; and saving the values, kind of like
		; shifting things to the left
		; when calculating the euclidean algortihm
		; by hand. 
		; this goes until the remainder reaches 0

		xor eax, eax
		mov eax, newRemainder
		cmp eax, 0
		je euCalEnd
		
		; if it's not 0 yet
		; division has result in eax, remainder in edx
		; so can use edx to get modulos results
		; so load into eax, div ebx, get result out of edx

		xor eax, eax
		mov eax, remainder
		idiv newRemainder		; idiv for signed division
		mov quotient, eax
		
		; now to move things around
		xor eax, eax
		mov eax, etemp
		mov oldTemp, eax

		; oldTemp = etemp
		xor eax, eax
		mov eax, newTemp
		mov etemp, eax
		; etemp = newTemp
		
		xor eax, eax
		xor ebx, ebx

		mov eax, quotient
		mov ebx, etemp
		imul ebx
		; result in eax
		; qtimesT = quotient * etemp
		mov qtimesT, eax

		xor eax, eax
		xor ebx, ebx

		mov ebx, qtimesT
		mov eax, oldTemp
		sub eax, qtimesT
		; newTemp = oldTemp - qtimesT

		mov newTemp, eax		
		xor eax, eax
		mov eax, remainder
		mov oldRemainder, eax
		
		; here this remainder will be stored
		; as the last thing before it hits 0
		; so the last remainder before 0
		; will be the gcd
		
		xor eax, eax
		mov eax, newRemainder
		mov remainder, eax
		; remainder = newRemainder

		; modulus in x86: 
		; edx / eax, eax has quotient and edx remainder
		; so load into eax, div ebx, get result out of edx

		xor eax, eax
		xor edx, edx
		mov ebx, remainder 
		mov eax, oldRemainder
		idiv remainder
		mov newRemainder, edx
		jmp L1

	euCalEnd: ; ---

		xor eax, eax
		mov eax, etemp
		test eax, eax		; test if it's signed or not, essentially test if negative
		js fix
		jmp fine

	fix: ; ---

		; if temp < 0, add the prime to it
		; this uses "test" to check for a signed value (negative)
		; js means jump if signed, so it continues adding prime to the value
		; until it reaches a positive value again.
		; this works since congruences

		add eax, prime
		test eax, eax
		js fix
		mov etemp, eax

		; if it's not signed/negative

	fine: ; ---

		xor eax, eax
		mov eax, etemp
		mov euclAnswer, eax

	ret						; go back

EuclideanCalculator ENDP
; -----------------------------

;------------------------------
; modulus power.
; x86 division is a modulus division
; division is ebx/eax with the answer in eax and the remainder in edx.
; This uses binary arithmetic to figure out a solution. 
; A counter is kept that is multiplied by 2 each time, 
; until it's no longer lesser than the exponent number;
; once this happens, the counter is subtracted form the exponent and the result multiplied mod the number.
; If the counter still fits within the exponent, 
; the result is multiplied again (& counter halved and index dec.),
; but if it isn't, the counter still halved and index dec., all until it hits 0.
; The counter being multiplied by 2 and then storing result in effect makes the binary subtraction possible;
; if it would be a 0, the number isn't multiplied to the total, but if it were a 1, it would be.
ModPow PROC
;-------------------------------

	xor eax, eax
	mov eax, floor
	mov mpexponent, eax		; mpexponent = floor

	; clear registers
	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx

	lea eax, mpArray
	mov ebx, euclAnswer
	mov mpinput, ebx
	mov [eax], ebx

	; testing
	; mov ecx, [eax]
	; nop				; in ecx there should be euclAnswer, 15

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx

	L1:  ; ----

		mov eax, mpcounter
		mov ebx, mpexponent
		cmp eax, ebx
		; nop
		jnb L1b
		; while the counter is less than the exponent

		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx

		mov eax, mptemp
		lea ebx, mpArray
		add ebx, mpindex
		sub ebx, 8
		mov edx, [ebx]
		mov ecx, mpcounter
		; edx should be result array at (index), 
		; eax temp, 
		; ecx mpcounter

		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx

		lea ecx, mpArray
		mov edx, mpindex
		add ecx, mpindex
		sub ecx, 4
		mov eax, [ecx]
		mov ebx, [ecx]
						; ecx = mpArray + index. eax and ebx both have arrayAt(index).
		mul ebx
		xor edx, edx		; have to clear out edx for the div
		; squared
		div prime			; mod prime
		mov mptemp, edx
		; temp = mpArray[index]*mpArray[mpindex] mod prime

		; counter * 2
		xor eax, eax
		mov eax, mpcounter
		mov ebx, 2			; ebx has 2
		mul ebx				; eax * ebx, result in eax
		mov mpcounter, eax		; counter is now counter * 2

		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx

		lea eax, mpArray		; load effective address of mpArray
		add eax, mpindex
		mov ebx, mptemp
		mov [eax], ebx			; mpArray.add(temp)
		; nop				; ebx shouldh ave temp
		; test it. edx and ebx should have the same things
		; mov edx, [eax]
		; nop

		mov ecx, mpindex	
		add ecx, 4
		mov mpindex, ecx			; index += 4
		; nop

		jmp L1

	L1b: ; ---

		xor eax, eax
		mov eax, mpindex
		sub eax, 4
		mov mpindex, eax

	L2: ; ---		

		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx

		mov eax, mpcounter 
		; nop
		cmp eax, 0
		jbe next

		; if exponent-counter isn't signed, or less than zero,
		; save this result. 
		; otherwise, skip ahead
		xor eax, eax
		xor ebx, ebx
		mov edx, mpcounter
		mov ecx, mpexponent
		mov eax, mpexponent
		sub eax, mpcounter
		mov mpexptemp, eax
		; nop			
		; edx mpcounter, 
		; ecx exp, 
		; eax exp - mpcounter
		test eax, eax
		js L2b		; jump if signed, so don't actually save that result.

		xor eax, eax
		mov eax, mpexptemp	; this is only if exp - counter is not lesser than 0
		mov mpexponent, eax
		nop
		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx

		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx

		lea eax, mpArray		; load the effective address of mpArray
		mov ebx, [eax]			;
		mov ecx, [eax + 4]
		mov edx, mpindex
		; nop
		xor ebx, ebx
		xor eax, eax
		xor ecx, ecx
		xor edx, edx
		lea eax, mpArray
		mov edx, eax
		add eax, mpindex
		mov ebx, [eax]			; mpArray[index]
		; nop
		xor eax, eax
		mov eax, mpresult
		; nop
		mul ebx				; eax = result * mpArray[index]
		; nop
		div prime
		; nop
		mov mpresult, edx

		xor eax, eax
		; continue

	L2b: ; --- 

		xor eax, eax
		mov eax, mpindex	; index - 4
		nop
		sub eax, 4
		mov mpindex, eax
		; nop

		xor eax, eax
		xor ecx, ecx
		xor ebx, ebx
		xor edx, edx
		mov ebx, 2
		mov ecx, mpcounter	; counter / 2
		mov eax, mpcounter
		div ebx
		mov mpcounter, eax
		; nop
		jmp L2

	next: ; --- 

		; nop
		xor eax, eax
		xor ebx, ebx
		mov eax, mpresult 
		mov ebx, mptemp
		; nop

ModPow ENDP
;------------

;----------------
; calculate floor
; requires a push to the stack
; to save a value
CalcFloor PROC
;----------------

	call SquareRoot	; get the square root 

	xor ebx, ebx

	mov ebx, sqrt		; answer from the square root function
	add ebx, 1		; 1 + square root. will truncate down to integer
	mov floor, ebx

	ret

CalcFloor ENDP
;--------------

;---------------------------
; Takes g (generator) and p (prime)
; List 1: g^0, g^1, g^2 , . . . , g^n
; and applies mod p.
; The values 0...n aren't saved along side them, 
; since I'm just using the array indexes instead to maek it faster.
ListCalc PROC
; ---------------------------

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx

	mov eax, arraySize
	mov ebx, listCalcTemp
	mov ecx, OFFSET array
	add ecx, listCalcIndex
	mov edx, [ecx]

	; nop	
	; eax is size, ebx g^i (actually g^size), 
	; edx should be the latter mod prime

	; clear registers
	xor eax, eax	
	xor ebx, ebx			; clear out ebx
	xor edx, edx			; clear out edx
	xor ecx, ecx			; clear out ecx

	mov eax, OFFSET array
	mov ebx, 1			; g^0, start value
	mov [eax], ebx			; put g^0 in array's first spot
	mov edx, arraySize 
	inc edx
	mov arraySize, edx		; now 1

	; this goes through 0-floor number of items. 
	; I'm using arraySize as both a counter of loop iterations and 
	; to keep track of how many items are in the array for use later

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx

		mov eax, arraySize
		mov ebx, listCalcTemp
		mov ecx, OFFSET array
		add ecx, listCalcIndex
		mov edx, [ecx]

		; nop ; optional
		; eax is size, ebx g^i (actually g^size), 
		; edx should be the latter mod prime

	L1: ; ----

		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx

		mov ecx, arraySize
		cmp ecx, floor			; is the loop over?
		je listCalcEnd

		xor ecx, ecx
		mov ecx, OFFSET array
		add ecx, listCalcIndex

		mov eax, listCalcTemp	; mul uses eax
		mov ebx, generator		
		mul ebx				; g ^ i now on ebx
		mov listCalcTemp, eax
		div prime				; mod result in edx
		mov [ecx], edx			; store in the array (number^2 mod prime)
		xor ecx, ecx
		mov ecx, listCalcIndex
		add ecx, 4			; move to the next array spot (4 because it's doublewords)
		mov listCalcIndex, ecx
		xor ecx, ecx
		
		; keep track of the size 
		xor eax, eax		; clear it 
		mov eax, arraySize	; move arraySize to eax
		inc eax			; arraySize++
		mov arraySize, eax	; put it back
		xor eax, eax		; clear it out again

		; before going back, let's check 
		xor eax, eax
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx

		mov eax, arraySize
		mov ebx, listCalcTemp
		mov ecx, OFFSET array
		add ecx, listCalcIndex
		sub ecx, 4
		mov edx, [ecx]

		; nop	; eax is size, 
		; ebx g^i (actually g^size), 
		; edx should be the latter mod prime

		jmp L1				; continue

	listCalcEnd: ; ---

		ret

ListCalc ENDP
;----------------

;-------------------------------------------------------------
; Square root function.
; Uses fld (floating point load) and fst (floating point store).
; This uses midpoints to check for the square root of a number by squaring it and checking if it's right.
; If the midpoint is too big, take the midpoint of that and zero,
; and if it's too small, take the midpoint of itself and the last midpoint.
; This repeats until a number close enough to the square root is found.
; The function uses a small value (1.0E-17) as a "close enough" gauge for square root.
; in x86 floating point there are several fp registers,
; but any arithmetic operations can only use register 0 and/or 1, for some reason, so values are swapped a lot.
; 
SquareRoot PROC
;-------------------------------------------------------------

	fild num_temp		; convert integer num_temp to fp 
					; and store on  stack
	fst d_large		; large = x 
	fstp d_num		; dnum = x
					; stack clear
	
	; divide x / 2 and save in addition total
	fld d_num			; x 
	fdiv d_two		; x/2
	fstp d_add		; add = x/2
	
	; square addition total and store in mult
	fld d_add			; s0 = add
	fmul d_add		; s0 = add^2
	fstp d_mult
	
	; x needs to go back in big value and addition total
	fld d_num			; s0 = x
	fst d_large		; large = x
	fstp d_add		; add = x
	
	calc: ; ------
	
		; addition total needs to be divided by 2 
		; and stored back in itself
		fld d_add			; s0 = add
		fdiv d_two		; s0 = add/2
		fstp d_add		; add = add/2
	
		; square add total and store in multiplication total
		fld d_add			; s0 = add
		fmul d_add		; s0 = add^2
		fstp d_mult		; mult = add^2
	
		; now we have to compare the mult total with x
		; floating point comparisons are awful in x86, 
		; so here's a way to get around it 
		; here, a convoluted way to check equality
		; by using a minimum considered value
		fld d_mult
		fld d_min
		fsub d_num 		; subtract large^2 - number
		fabs				; get the absolute value 
		fcomi ST(0),ST(1)	; compare the two values on the top.
		je found			; if the square root is found, leave

		; so it's not equal.
		; if our number is smaller, go to "tooLow"
		ja tooLow			
		; else, if our number is bigger, go to "tooHigh"
		jb tooHigh

		; we shouldn't ever get here. run
		mov eax, 0
		mov sqrt, eax
		ret

	tooHigh: ; ----

		; let's get rid of those two numbers
		fstp d_trash
		fstp d_trash
		; now s0 and s1 are empty
		; store addition in the big value
		; change of plans
		fld d_add		; s0 = add
		fstp d_large	; large has add
		; let's go back		
		jmp calc

	tooLow: ; ---

		; let's get rid of those two numbers
		fstp d_trash
		fstp d_trash
		; now s0 and s1 are empty
		; divide big value by 2 and put in small value
		fld d_large
		fdiv d_two
		fstp d_small
		; add addition to big value and put in addition
		fld d_add
		fadd d_large
		fstp d_add
		; for some reason still 2 on stack? 
		fstp d_trash
		fstp d_trash
		; go back
		jmp calc
	
	found: ; ----

		; found it! add is the answer
		fld d_add
		fist sqrt		; store it as an integer in sqrt
	
	ret			; go back
		
SquareRoot ENDP
; ----

;---------------
; Compares the list calculated above with one created on the go. 
; This is list 2:
; h, h*g^-n, h*g^-2n, etc.
; List 2 is calculated step by step, comparing with first list's reuslts 
; until a match is found.
; The variable invG is the inverse (g^-1) as calculated by a previously 
; used method, and then I use the modPow to get the g^-n
;
Compare PROC
;---------------

	xor eax, eax
	mov eax, arraySize
	; nop			; check value

	; clear all registers
	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx

	mov eax, number
	mov cmpH, eax
	xor eax, eax

	; call the Euclidean calculator function
	; to get the multiplicative modular inverse
	; for the input on this function

	call EuclideanCalculator

	xor eax, eax
	mov eax, EuclAnswer
	mov mpinput, eax

	call ModPow

	; get the inverse of g
	xor eax, eax
	mov eax, mpresult
	mov invG, eax
	xor eax, eax		; clear eax
	mov eax, number	; get number
	mov temp, eax		; stored in temp
	xor eax, eax

	L1: ; ---

		xor ecx, ecx
		mov cmpInnerCounter, ecx	; inner counter is 0
		mov cmpIndex, ecx		; inner index is 0
		xor eax, eax
		xor edx, edx

		; for note

		mov eax, floor
		mov ecx, cmpcounter
		inc ecx				; floor-1
		cmp ecx, floor			; is ecx at the floor yet?
		je compareEnd			; if so, leave
		xor eax, eax
		xor ebx, ebx			
		jmp L2

	L1a: ; ---

		; cmpH = cmpH * invG (mod prime)
		xor eax, eax
		xor ebx, ebx
		xor edx, edx

		mov eax, cmpH
		mov ebx, invG
		mul ebx
		; result is in eax
		xor ebx, ebx
		mov ebx, prime
		div ebx 
		; eax (cmpH*invG) / prime = edx
		mov cmpH, edx
		; cmpH has modulos result

		xor eax, eax
		xor ebx, ebx
		xor edx, edx
		mov ecx, cmpcounter
		inc ecx
		mov cmpcounter, ecx		; counter++
		jmp L1

		L2: ; --- 

			mov ebx, cmpInnerCounter
			inc ebx		; i < array.length
			cmp ebx, arraySize
			jge L1a
			; if it's not greater than or equal to the length of array
			; go ahead and save the inner counter 
	
			mov cmpInnerCounter, ebx
			xor eax, eax
			mov edx, OFFSET array
			add edx, cmpIndex
			mov eax, [edx]
			mov edx, cmpH
			cmp eax, cmpH
			je found
		
			xor ebx, ebx
			xor edx, edx

			mov edx, cmpIndex	; increment the index by size of dwords
			add edx, 4
			mov cmpIndex, edx	; save new number
			jmp L2			; go back

	; if teh discrete log is found

	found: ; ---

		xor eax, eax			; eax = 0
		xor ebx, ebx
		xor ecx, ecx
		mov eax, floor			; mul uses eax
							; outer loop counter * floor
		mov ecx, cmpcounter
		mul ecx				; result in eax
		; outer counter * floor + inner loop counter

		mov ebx, cmpInnerCounter
		add eax, ebx
		mov discLog, eax
		jmp quit				; skip the error condition

	compareEnd: ; ----

		xor eax, eax
		; eax has 0 - error code
		mov discLog, eax

	quit: ; ---

		ret

Compare ENDP
;------

;------------
GetPrime PROC
; Prompts the user for the prime (p)
; and saves the prime and the size of the prime
;-------------

	push MB_OKCANCEL
	push OFFSET mBoxCaption
	push OFFSET mBoxTextPrime
	push null
	call MessageBoxA

	call ReadInt
	mov prime, eax
	ret

GetPrime ENDP
;----------------

;------------
GetGenerator PROC
; Prompts the user for the prime (p)
; and saves the prime and the size of the prime
;-------------

	push MB_OKCANCEL
	push OFFSET mBoxCaption
	push OFFSET mBoxTextGen
	push null
	call MessageBoxA

	call ReadInt
	mov generator, eax
	ret

GetGenerator ENDP
;----------------

;------------
GetNumber PROC
; Prompts the user for the number
;-------------

	push MB_OKCANCEL
	push OFFSET mBoxCaption
	push OFFSET mBoxTextNum
	push null
	call MessageBoxA

	call ReadInt
	mov number, eax
	ret

GetNumber ENDP
;----------------

;-----------
; Display result
; to get the number in discLog, if it's a multidigit number, divide by 10 and get remainders
; remainders are pushed to stack in the order they arrive, so that when they're popped 
; they will be in correct order. 
; Example - if the result is 57
; 57/10 = 5 remainder 7. 7 is converted to ASCII and put on stack
; stack now has (7)
; 5/10 = 0 remainder 5. 5 is converted to ASCII and put on the stack
; stack now has (7 5)
; stack is last-on-first-off, so 5 is popped and afterwards 7. 
; 
ShowResult PROC
;------------

	xor eax, eax
	mov eax, discLog
	; nop					; checking value before proceeding

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx
	
	mov eax, discLog
	cmp eax, 10
	jge next					; if it's under 10 characters (single digit), 
							; just add it to the string result and go

	add eax, 48				; get it to ascii 
	lea ecx, mBoxTextResult		; load the effctive address - the starting place for the text string result
	add ecx, 21				; 21 charatcers until the next available space
	mov [ecx], eax
		
	jmp display				; since it's just 1 character long, go

	next: ; --

		xor eax, eax
		mov eax, discLog
		xor ecx, ecx

	L1: ; ---

		xor edx, edx			; clear out edx for the division
		mov ebx, 10			; /10 
		div ebx				; eax / ebx. quotient in eax, remainder in edx
		add edx, 48			; get it to ascii
		push edx				; save on stack
		inc ecx
		cmp eax, 0
		jg L1

		xor eax, eax
		xor edx, edx
		lea edx, mBoxTextResult
		add edx, 21	; to the available spot

	; getting values off stack 

	L2: ; ---

		cmp ecx, 0
		je display
		inc edx
		pop eax		; on to eax
		mov [edx], eax
		dec ecx
		jmp L2

	display: ; ---

		push MB_OKCANCEL
		push OFFSET mBoxCaption
		push OFFSET mBoxTextResult
		push null
		call MessageBoxA

	ShowResultEnd:
	
	ret


ShowResult ENDP

;--------------

end main

; ------------
