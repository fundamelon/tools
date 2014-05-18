;-----------------------
; Chorazewicz, Igi
; Login: ichor001 (ichor001@ucr.edu)
; Assignment: assn5
; Section: 021
; TA: Aditya Tammewar
; 
; I hereby certify that the contents of this file are entirely my own work
; ----------------------

;-----------------------------------------------------------------------
; MAIN
;		- Ask the user for two operands with input validation.
;		- Check for overflow/underflow; if it will happen, abort program
;		- Multiply the operands
;		- Output the resulting equation
;-----------------------------------------------------------------------

.ORIG x3000
						; NOTE: This program uses lots of memory functions
						; to manage values for the sake of organization.
						; If necessary, this can be optimized.
						
						; get operand 1
						LD R6, MAIN_HEX_3100
						JSRR R6
						ST R2, MAIN_OPERAND_1
						
						; get operand 2
						LD R6, MAIN_HEX_3100 
						JSRR R6
						ST R2, MAIN_OPERAND_2
						
						; prepare opernads
						LD R2, MAIN_OPERAND_1
						LD R3, MAIN_OPERAND_2
						
						; test for overflow
						LD R6, MAIN_HEX_3400
						JSRR R6
						
						; perform multiplication
						LD R6, MAIN_HEX_3300
						JSRR R6
						
						; store product
						ST R2, MAIN_PRODUCT
						
						; prepare for printing
						LD R2, MAIN_OPERAND_1
						LD R3, MAIN_OPERAND_2
						LD R4, MAIN_PRODUCT
						
						; output full equation
						LD R6, MAIN_HEX_3500
						JSRR R6
						
						HALT

; Local data	
MAIN_OPERAND_1			.BLKW #1
MAIN_OPERAND_2			.BLKW #1
MAIN_PRODUCT			.BLKW #1

MAIN_DEC_10				.FILL #10

MAIN_HEX_3100			.FILL x3100 ; SUB_3100_INPUT
MAIN_HEX_3200			.FILL x3200 ; SUB_3200_OUTPUT_VALUE
MAIN_HEX_3300			.FILL x3300 ; SUB_3300_MULTIPLY
MAIN_HEX_3400			.FILL x3400 ; SUB_3400_TEST_OVERFLOW
MAIN_HEX_3500			.FILL x3500 ; SUB_3500_OUTPUT_FORMATTED

MAIN_CHAR_NEWLINE		.FILL x0A

;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3100_INPUT
;							Reads a positive 5-digit number into R2.
;							Also performs on-the-fly input validation.
;
; INPUTS				None
; OUTPUTS				(R2) <- in
;-----------------------------------------------------------------------
.ORIG x3100				
						ST R0, BACKUP_3100_R0 ; input register
						ST R1, BACKUP_3100_R1 ; loop sentinel
						ST R3, BACKUP_3100_R3 ; mult operand
						ST R4, BACKUP_3100_R4 ; value retrieval
						ST R6, BACKUP_3100_R6 ; subroutine addresses
						ST R7, BACKUP_3100_R7 ; R7 backup
						
						LEA R0, SUB_3100_INPUT_PROMPT ; prompt for input
						PUTS
						
						AND R2, R2, #0			; (R2) <- 0
						; init flags
						ST R2, SUB_3100_FLAG_NEGATIVE
						ST R2, SUB_3100_FLAG_PREFIX
						
						LD R1, SUB_3100_DEC_5	; init sentinel
						LD R4, SUB_3100_CHAR_0	; for char->value. DO NOT CHANGE
						NOT R4, R4
						ADD R4, R4, #1
						
SUB_3100_INPUT_LOOP:		
							GETC
							OUT
							
							; break out of loop if ENTER is pressed.
							LD R6, SUB_3100_CHAR_NEWLINE
							NOT R6, R6
							ADD R6, R6, #1
							ADD R6, R0, R6
							BRz SUB_3100_RETURN
							
							; check if it might be sign, i.e. char < '0'
							LD R6, SUB_3100_CHAR_0
							NOT R6, R6
							ADD R6, R6, #1
							ADD R6, R0, R6
							BRzp SUB_3100_SKIP_CHECK_SIGN
							
							; if current char is not prefix, reject.
							LD R6, SUB_3100_FLAG_PREFIX
							BRp SUB_3100_REJECT_CHAR
							
							; check if char == '+' - if so, do nothing.
							LD R6, SUB_3100_CHAR_PLUS
							NOT R6, R6
							ADD R6, R6, #1
							ADD R6, R0, R6
							BRz SUB_3100_INPUT_LOOP
							
							; check if char == '-' if not, reject char.
							LD R6, SUB_3100_CHAR_MINUS
							NOT R6, R6
							ADD R6, R6, #1
							ADD R6, R0, R6
							BRnp SUB_3100_REJECT_CHAR
							
							; else set flag and continue input.
							LD R6, SUB_3100_FLAG_NEGATIVE
							ADD R6, R6, #-1
							ST R6, SUB_3100_FLAG_NEGATIVE
							BR SUB_3100_INPUT_LOOP
							
	SUB_3100_REJECT_CHAR: 	; give error message
							LEA R0, SUB_3100_REJECT_PROMPT
							PUTS
							; repeat input prompt
							LEA R0, SUB_3100_INPUT_PROMPT
							PUTS
							
							; print out value given so far
							LD R6, SUB_3100_HEX_3200
							JSRR R6
							
							BR SUB_3100_INPUT_LOOP
							
	SUB_3100_SKIP_CHECK_SIGN:			
							; check if char isn't > '9'
							LD R6, SUB_3100_CHAR_9
							NOT R6, R6
							ADD R6, R6, #1
							ADD R6, R0, R6
							BRp SUB_3100_REJECT_CHAR
							
							; multiply R2 by 10
							LD R3, SUB_3100_DEC_10
							LD R6, SUB_3100_HEX_3300
							JSRR R6					 ; (R2) <- (R2) * 10
							
							ADD R0, R0, R4 ; char -> value
							ADD R2, R0, R2 ; (R2) <- (R0) + (R2)
							
							; give prefix flag a positive number
							ST R6, SUB_3100_FLAG_PREFIX
							
							; advance loop
							ADD R1, R1, #-1
							BRp SUB_3100_INPUT_LOOP
						
SUB_3100_END_INPUT:
						LD R0, SUB_3100_CHAR_NEWLINE
						OUT
SUB_3100_RETURN:		; if flag not 0, make the result negative.
						LD R6, SUB_3100_FLAG_NEGATIVE
						BRz SUB_3100_SKIP_NEGATE
						
						NOT R2, R2
						ADD R2, R2, #1
						
SUB_3100_SKIP_NEGATE:
						LD R0, BACKUP_3100_R0
						LD R1, BACKUP_3100_R1
						LD R3, BACKUP_3100_R3
						LD R4, BACKUP_3100_R4
						LD R6, BACKUP_3100_R6
						LD R7, BACKUP_3100_R7
						RET

SUB_3100_FLAG_NEGATIVE	.BLKW #1 ; negative if a '-' was input
SUB_3100_FLAG_PREFIX	.BLKW #1 ; zero while no numbers have been input

SUB_3100_DEC_5			.FILL #5
SUB_3100_DEC_10			.FILL #10

SUB_3100_HEX_3200		.FILL x3200
SUB_3100_HEX_3300		.FILL x3300

SUB_3100_CHAR_NEWLINE	.FILL x0A
SUB_3100_CHAR_PLUS		.FILL x2B
SUB_3100_CHAR_MINUS		.FILL x2D
SUB_3100_CHAR_0			.FILL x30
SUB_3100_CHAR_9			.FILL x39

BACKUP_3100_R0			.BLKW #1
BACKUP_3100_R1			.BLKW #1
BACKUP_3100_R3			.BLKW #1
BACKUP_3100_R4			.BLKW #1
BACKUP_3100_R6			.BLKW #1
BACKUP_3100_R7			.BLKW #1

SUB_3100_INPUT_PROMPT	.STRINGZ "Enter an operand: "
SUB_3100_REJECT_PROMPT	.STRINGZ "\n\tERROR: Invalid char was given.\n\tPlease continue input with: 0-9, -, or +.\n"

;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3200_OUTPUT_VALUE
; 							Prints value in R2 to console
;
; INPUTS				R2: Value
; OUTPUTS				None
;-----------------------------------------------------------------------
.ORIG x3200
						ST R0, BACKUP_3200_R0 ; output mgr
						ST R1, BACKUP_3200_R1 ; loop sentinel
						ST R2, BACKUP_3200_R2 ; value to output
						ST R3, BACKUP_3200_R3 ; val to subtract
						ST R4, BACKUP_3200_R4 ; pointer for R3
						ST R5, BACKUP_3200_R5 ; pointer to array
						ST R7, BACKUP_3200_R7 ; R7 backup
						
						; if input value is 0, just print "+0" and return
						ADD R2, R2, #0
						BRnp SUB_3200_INPUT_NONZERO
						
						LD R0, SUB_3200_CHAR_PLUS
						OUT
						LD R0, SUB_3200_CHAR_0
						OUT
						BR SUB_3200_RETURN
						
SUB_3200_INPUT_NONZERO:
						AND R0, R0, #0
						LD R1, SUB_3200_HEX_0010
						LEA R5, SUB_3200_OUT_ARRAY
						
SUB_3200_INIT_ARR:			; initialize array
							STR R0, R5, #0
							ADD R5, R5, #1
							ADD R1, R1, #-1
							BRp SUB_3200_INIT_ARR
							
						; set flag
						AND R1, R1, #0
						ST R1, SUB_3200_FLAG_LEADING
						
						; sign char <- '+'
						LD R1, SUB_3200_CHAR_PLUS
						ST R1, SUB_3200_SIGN_CHAR
						
						; if R2 < 0, make it positive, set sign char to '-'
						ADD R2, R2, #0
						BRzp SUB_3200_SKIP_MAKE_POSITIVE
						
						LD R1, SUB_3200_CHAR_MINUS
						ST R1, SUB_3200_SIGN_CHAR
						NOT R2, R2
						ADD R2, R2, #1
						
SUB_3200_SKIP_MAKE_POSITIVE:
						
						LEA R4, SUB_3200_DEC_10000 ; initial subtract val
						LEA R5, SUB_3200_OUT_ARRAY ; array address
						LD R0, SUB_3200_SIGN_CHAR ; store sign
						STR R0, R5, #0
						ADD R5, R5, #1 ; offset due to sign
						
						LDR R3, R4, #0 ; initial load
						
SUB_3200_PREPLOOP:		; prep value as chars into printing array

							LD R0, SUB_3200_CHAR_0
							NOT R3, R3
							ADD R3, R3, #1
							ADD R0, R0, #-1
	SUB_3200_NEGLOOP:			; subtract each place value from R2 until negative
								ADD R0, R0, #1
								ADD R2, R3, R2
								BRzp SUB_3200_NEGLOOP
								
							; restore R2 to positive
							NOT R3, R3
							ADD R3, R3, #1
							ADD R2, R2, R3
							
							; check if result char is '0'
							LD R3, SUB_3200_CHAR_0
							NOT R3, R3
							ADD R3, R3, #1
							ADD R3, R0, R3
							BRnp SUB_3200_STORE_CHAR
							
							; check flag if any leading digits have been output
							LD R3, SUB_3200_FLAG_LEADING
							BRz SUB_3200_SKIP_STORE_CHAR
							
SUB_3200_STORE_CHAR:
							; store char and advance pointer
							STR R0, R5, #0
							ADD R5, R5, #1
							ST R0, SUB_3200_FLAG_LEADING
							
SUB_3200_SKIP_STORE_CHAR:
							ADD R4, R4, #1
							LDR R3, R4, #0
							BRp SUB_3200_PREPLOOP
						
						LEA R0, SUB_3200_OUT_ARRAY
						LD R3, SUB_3200_CHAR_0 ; negative char 0
						NOT R3, R3
						ADD R3, R3, #1
						
;						ADD R0, R0, #-1
						
;SUB_3200_OFFSET_LOOP:		; offset print start until first digit =/= 0
;							ADD R0, R0, #1
;							LDR R1, R0, #0		
;							ADD R1, R1, R3
;							BRnz SUB_3200_OFFSET_LOOP
						
						PUTS ; print value
						
SUB_3200_RETURN:
						LD R0, BACKUP_3200_R0
						LD R1, BACKUP_3200_R1
						LD R2, BACKUP_3200_R2
						LD R3, BACKUP_3200_R3
						LD R4, BACKUP_3200_R4
						LD R5, BACKUP_3200_R5
						LD R7, BACKUP_3200_R7
						RET

SUB_3200_FLAG_LEADING	.FILL #0

SUB_3200_DEC_NEG1		.FILL #-1
SUB_3200_DEC_4			.FILL #4

SUB_3200_DEC_10000      .FILL #10000
SUB_3200_DEC_1000       .FILL #1000
SUB_3200_DEC_100        .FILL #100
SUB_3200_DEC_10         .FILL #10
SUB_3200_DEC_1			.FILL #1
SUB_3200_DEC_0			.FILL #0

SUB_3200_SIGN_CHAR		.FILL #-1

SUB_3200_CHAR_PLUS		.FILL x2B
SUB_3200_CHAR_MINUS		.FILL x2D
SUB_3200_CHAR_0			.FILL x30

SUB_3200_HEX_0010		.FILL x0010
SUB_3200_HEX_3400		.FILL x3400
SUB_3200_HEX_4000		.FILL x4000

BACKUP_3200_R0			.BLKW #1
BACKUP_3200_R1			.BLKW #1
BACKUP_3200_R2			.BLKW #1
BACKUP_3200_R3			.BLKW #1
BACKUP_3200_R4			.BLKW #1
BACKUP_3200_R5			.BLKW #1
BACKUP_3200_R7			.BLKW #1

.ORIG x32F0
SUB_3200_OUT_ARRAY		.BLKW x0020

;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3300_MULTIPLY
; 							Multiplies value in R2 by R3.
;
; INPUTS				R2, R3: operands
; OUTPUTS				R2: result
;-----------------------------------------------------------------------

.ORIG x3300				
						ADD R2, R2, #0
						BRz SUB_3300_RETURN ; skip if trying to mult. 0
						
						ST R0, BACKUP_3300_R0 ; output mgr
						ST R3, BACKUP_3300_R3 ; multiplicand
						ST R4, BACKUP_3300_R4 ; mask
						ST R5, BACKUP_3300_R5 ; adder
						ST R7, BACKUP_3300_R7 ; R7 backup
						
						LD R4, SUB_3300_DEC_1 ; load mask
						ST R4, SUB_3300_MASK
						AND R5, R5, #0		 ; set adder to input
						ADD R5, R2, #0
						AND R2, R2, #0
						LD R3, BACKUP_3300_R3
						
SUB_3300_MULT_LOOP:			AND R4, R3, R4 ; cmp. multiplicand to mask
							BRz SUB_3300_DO_NOT_MULT
							
							ADD R2, R2, R5
							
							
SUB_3300_DO_NOT_MULT:		ADD R5, R5, R5 ; shift adder left
							LD R4, SUB_3300_MASK
							ADD R4, R4, R4 ; shift mask left
							ST R4, SUB_3300_MASK
							BRnp SUB_3300_MULT_LOOP
						
						LD R0, BACKUP_3300_R0
						LD R3, BACKUP_3300_R3
						LD R4, BACKUP_3300_R4
						LD R5, BACKUP_3300_R5
						LD R7, BACKUP_3300_R7
						
SUB_3300_RETURN:		RET
						
; data

SUB_3300_DEC_1			.FILL #1

SUB_3300_MASK			.BLKW #1

BACKUP_3300_R0          .BLKW #1
BACKUP_3300_R3          .BLKW #1
BACKUP_3300_R4          .BLKW #1
BACKUP_3300_R5			.BLKW #1
BACKUP_3300_R7			.BLKW #1


;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3400_TEST_OVERFLOW
; 							Tests for arithmetic overflow in case of mult.
;
; INPUTS				R2: operand
;						R3: operand
; OUTPUTS				None (will terminate program)
;-----------------------------------------------------------------------
.ORIG x3400
						ST R2, BACKUP_3400_R2 ; operand 1
						ST R3, BACKUP_3400_R3 ; operand 2
						ST R4, BACKUP_3400_R4 ; temp storage
						ST R6, BACKUP_3400_R6 ; subroutine ptr
						ST R7, BACKUP_3400_R7 ; R7 backup	
						
						; set negatives flag
						; 1 means both operands are positive
						; 0 means only one is positive, so result will be negative
						; -1 means both are neg, therefore result will be positive
						AND R6, R6, #0
						ADD R6, R6, #1
						
						ADD R2, R2, #0
						BRzp SUB_3400_SKIP_FLAG_OP1
						ADD R6, R6, #-1
SUB_3400_SKIP_FLAG_OP1:
						ADD R3, R3, #0
						BRzp SUB_3400_SKIP_FLAG_OP2
						ADD R6, R6, #-1
SUB_3400_SKIP_FLAG_OP2:
						ST R6, SUB_3400_FLAG_NEGATIVES
						
						; get length of first operand
						LD R6, SUB_3400_HEX_3600
						JSRR R6
						
						; (R4) <- MSB R2
						ADD R4, R3, #0
						
						; (R2) <- operand 2
						LD R2, BACKUP_3400_R3
						; get length of second operand
						LD R6, SUB_3400_HEX_3600
						JSRR R6
						
						ADD R3, R3, R4
						LD R4, SUB_3400_DEC_NEG15
						ADD R3, R3, R4
						BRzp SUB_3400_OVERFLOW
																	
						LD R2, BACKUP_3400_R2
						LD R3, BACKUP_3400_R3
						LD R4, BACKUP_3400_R4
						LD R6, BACKUP_3400_R6
						LD R7, BACKUP_3400_R7
						
SUB_3400_RETURN:
						RET
						
; messages and termination in case of addition overflow during algorithm
SUB_3400_OVERFLOW:
						; if result was going to be negative,
						; then we'd have arithmetic underflow.
						LD R0, SUB_3400_FLAG_NEGATIVES
						BRz SUB_3400_UNDERFLOW
						
						LEA R0, SUB_3400_OVERFLOW_MSG
						PUTS
						HALT
SUB_3400_UNDERFLOW:
						LEA R0, SUB_3400_UNDERFLOW_MSG
						PUTS
						HALT
						
SUB_3400_FLAG_NEGATIVES	.BLKW #1
						
SUB_3400_DEC_NEG15		.FILL #-15
						
SUB_3400_HEX_3600		.FILL x3600 ; SUB_3600_GET_MSB

BACKUP_3400_R2          .BLKW #1
BACKUP_3400_R3          .BLKW #1
BACKUP_3400_R4          .BLKW #1
BACKUP_3400_R6			.BLKW #1
BACKUP_3400_R7			.BLKW #1

SUB_3400_OVERFLOW_MSG	.STRINGZ "\tERROR: Holy Overflow, Batman!"
SUB_3400_UNDERFLOW_MSG	.STRINGZ "\tERROR: Holy Underflow, Batman!"
						

;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3500_OUTPUT_FORMATTED
; 							Prints formatted multiplication equation to console
;
; INPUTS				R2: operand 1
;						R3: operand 2
;						R4: product
; OUTPUTS				None
;-----------------------------------------------------------------------
.ORIG x3500
						ST R0, BACKUP_3500_R0 ; output mgr
						ST R2, BACKUP_3500_R2 ; operand
						ST R3, BACKUP_3500_R3 ; operand
						ST R4, BACKUP_3500_R4 ; product
						ST R6, BACKUP_3500_R6 ; subroutine ptr
						ST R7, BACKUP_3500_R7 ; R7 backup
						
						; output first operand
						LD R6, SUB_3500_HEX_3200
						JSRR R6
						
						; output operation representation
						LD R0, SUB_3500_CHAR_SPACE
						OUT
						LD R0, SUB_3500_CHAR_ASTERISK
						OUT
						LD R0, SUB_3500_CHAR_SPACE
						OUT
						
						; (R2) <- (R3)
						ADD R2, R3, #0
						
						; output second operand
						LD R6, SUB_3500_HEX_3200
						JSRR R6
						
						; output equation representation
						LD R0, SUB_3500_CHAR_SPACE
						OUT
						LD R0, SUB_3500_CHAR_EQUALS
						OUT
						LD R0, SUB_3500_CHAR_SPACE
						OUT
						
						; (R2) <- (R4)
						ADD R2, R4, #0
						
						; output product
						LD R6, SUB_3500_HEX_3200
						JSRR R6
						
						LD R0, BACKUP_3500_R0
						LD R2, BACKUP_3500_R2
						LD R3, BACKUP_3500_R3
						LD R4, BACKUP_3500_R4
						LD R6, BACKUP_3500_R0
						LD R7, BACKUP_3500_R7
						RET

SUB_3500_HEX_3200		.FILL x3200 ; SUB_3200_OUTPUT_VALUE

SUB_3500_CHAR_NEWLINE	.FILL x0A
SUB_3500_CHAR_SPACE		.FILL x20
SUB_3500_CHAR_ASTERISK	.FILL x2A
SUB_3500_CHAR_EQUALS	.FILL x3D

BACKUP_3500_R0			.BLKW #1
BACKUP_3500_R2			.BLKW #1
BACKUP_3500_R3			.BLKW #1
BACKUP_3500_R4			.BLKW #1
BACKUP_3500_R6			.BLKW #1
BACKUP_3500_R7			.BLKW #1

;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3600_GET_MSB
; 							Counts the position of the most significant bit
;							(as arbitrary unsigned 16-bit data)
;
; INPUTS				R2: start value
; OUTPUTS				R3: index, 15 to 0, of MSB
;-----------------------------------------------------------------------
.ORIG x3600
						
						ST R2, BACKUP_3600_R2 ; input val
						ST R4, BACKUP_3600_R4 ; mask
						ST R7, BACKUP_3600_R7 ; R7 backup
						
						; if 0 was passed, simply return 0
						ADD R2, R2, #0
						BRz SUB_3600_RETURN_ZERO
						
						; if input was positive skip the change
						BRp SUB_3600_SKIP_MAKE_POSITIVE
						
						; else (R2) <- -(R2)
						NOT R2, R2
						ADD R2, R2, #1
SUB_3600_SKIP_MAKE_POSITIVE:
						ST R2, SUB_3600_INPUT_VAL
						
						; init the memory values
						AND R4, R4, #0
						LD R4, SUB_3600_HEX_8000
						ST R4, SUB_3600_MASK
						
						LD R4, SUB_3600_DEC_16
						ST R4, SUB_3600_INDEX
						
SUB_3600_COUNTLOOP:
							LD R4, SUB_3600_MASK
							
							; shift the mask
							LD R2, SUB_3600_MASK
							LD R6, SUB_3600_HEX_3700
							JSRR R6
							ST R3, SUB_3600_MASK
							
							LD R3, SUB_3600_INDEX
							ADD R3, R3, #-1
							ST R3, SUB_3600_INDEX
							
							LD R2, SUB_3600_INPUT_VAL
							AND R4, R2, R4
							BRz SUB_3600_COUNTLOOP
						BR SUB_3600_RETURN
											
SUB_3600_RETURN_ZERO:		
						AND R3, R3, #0 ; (R3) <- #0
SUB_3600_RETURN:
						LD R2, BACKUP_3600_R2
						LD R4, BACKUP_3600_R4
						LD R7, BACKUP_3600_R7
						RET

SUB_3600_DEC_16			.FILL #16

SUB_3600_HEX_3700		.FILL x3700 ; SUB_RIGHTSHIFT_3700
SUB_3600_HEX_8000		.FILL x8000

SUB_3600_MASK			.BLKW #1
SUB_3600_INDEX			.BLKW #1

SUB_3600_INPUT_VAL		.BLKW #1

BACKUP_3600_R2			.BLKW #1
BACKUP_3600_R4			.BLKW #1
BACKUP_3600_R7			.BLKW #1

;-----------------------------------------------------------------------
; SUBROUTINE			SUB_RIGHTSHIFT_3700
;							Shifts the binary value of a register to the right
;
; INPUTS				R2: input value
; OUTPUTS				R3: shifted value
;-----------------------------------------------------------------------
.ORIG x3700				
						
						ST R1, BACKUP_3700_R1 ; mask 2
						ST R2, BACKUP_3700_R2 ; input val
						ST R4, BACKUP_3700_R4 ; loop sentinel
						ST R7, BACKUP_3700_R7 ; R7 backup
						
						LD R0, SUB_3700_HEX_0001
						LD R1, SUB_3700_HEX_0002
						
						AND R3, R3, #0 ; (R3) <- #0
						LD R4, SUB_3700_HEX_000F
						
SUB_3700_SHIFTLOOP:
							LD R2, BACKUP_3700_R2
							AND R2, R2, R1
							BRz SUB_3700_SKIP_ADD_BIT
							ADD R3, R3, R0
	SUB_3700_SKIP_ADD_BIT:
							ADD R0, R0, R0
							ADD R1, R1, R1
							ADD R4, R4, #-1
							BRp SUB_3700_SHIFTLOOP
							
						LD R1, BACKUP_3700_R1
						LD R2, BACKUP_3700_R2
						LD R4, BACKUP_3700_R4
						LD R7, BACKUP_3700_R7
						RET
						
SUB_3700_HEX_0001		.FILL x0001
SUB_3700_HEX_0002		.FILL x0002
SUB_3700_HEX_000F		.FILL x000F
						
BACKUP_3700_R1			.BLKW #1
BACKUP_3700_R2			.BLKW #1
BACKUP_3700_R4			.BLKW #1
BACKUP_3700_R7			.BLKW #1
	
.END

