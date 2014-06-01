;-----------------------
; Chorazewicz, Igi
; Login: ichor001 (ichor001@ucr.edu)
; Assignment: assn8
; Section: 021
; TA: Aditya Tammewar
; ----------------------

;-----------------------------------------------------------------------
; MAIN
;-----------------------------------------------------------------------

.ORIG x3000

MAIN_START:
						LD R6, MAIN_HEX_3150
						JSRR R6
						
; SUB_3300_ALL_MACHINES_BUSY
MAIN_OPTION_1:
						ADD R1, R1, #-1
						BRp MAIN_OPTION_2
						LD R6, MAIN_HEX_3300
						JSRR R6
						LEA R0, MAIN_TEXT_1
						PUTS
						
						ADD R2, R2, #0
						BRp MAIN_OPTION_1_F
						JSR MAIN_PRINT_NOT
	MAIN_OPTION_1_F:
						JSR MAIN_PRINT_BUSY
						LD R0, MAIN_CHAR_NEWLINE
						OUT
						BR MAIN_START
						
; SUB_3400_ALL_MACHINES_FREE								
MAIN_OPTION_2:
						ADD R1, R1, #-1
						BRp MAIN_OPTION_3
						LD R6, MAIN_HEX_3400
						JSRR R6
						LEA R0, MAIN_TEXT_1
						PUTS
						
						ADD R2, R2, #0
						BRp MAIN_OPTION_2_F
						JSR MAIN_PRINT_NOT
	MAIN_OPTION_2_F:
						JSR MAIN_PRINT_FREE
						LD R0, MAIN_CHAR_NEWLINE
						OUT
						BR MAIN_START

; SUB_3500_NUM_BUSY_MACHINES						
MAIN_OPTION_3:
						ADD R1, R1, #-1
						BRp MAIN_OPTION_4
						
						; calculate amount
						LD R6, MAIN_HEX_3500
						JSRR R6
						
						; prefix text
						LEA R0, MAIN_TEXT_2
						PUTS
						
						; print number
						LD R6, MAIN_HEX_4000
						JSRR R6
						
						; suffix text and formatting
						LD R0, MAIN_CHAR_SPACE
						OUT
						JSR MAIN_PRINT_BUSY
						LEA R0, MAIN_TEXT_3
						PUTS
						LD R0, MAIN_CHAR_NEWLINE
						OUT
						
						BR MAIN_START

; SUB_3600_NUM_FREE_MACHINES						
MAIN_OPTION_4:
						ADD R1, R1, #-1
						BRp MAIN_OPTION_5
						
						; calculate amount
						LD R6, MAIN_HEX_3600
						JSRR R6
						
						; prefix text
						LEA R0, MAIN_TEXT_2
						PUTS
						
						; print number
						LD R6, MAIN_HEX_4000
						JSRR R6
						
						; suffix text and formatting
						LD R0, MAIN_CHAR_SPACE
						OUT
						JSR MAIN_PRINT_FREE
						LEA R0, MAIN_TEXT_3
						PUTS
						LD R0, MAIN_CHAR_NEWLINE
						OUT
						
						BR MAIN_START

; SUB_3700_MACHINE_STATUS						
MAIN_OPTION_5:
						ADD R1, R1, #-1
						BRp MAIN_OPTION_6
						
						; prompt for an ID
						LEA R0, MAIN_TEXT_4
						PUTS
						
						; take a character, and validate it.
						LD R6, MAIN_HEX_4100
						JSRR R6
						ADD R2, R2, #0
						BRn MAIN_OPTION_5_INVALID
						
						; check upper limit
						ADD R2, R2, #-15
						BRp MAIN_OPTION_5_INVALID
						ADD R2, R2, #15
						
						; put ID into R1
						ADD R1, R2, #0
						
						; look up machine from ID
						LD R6, MAIN_HEX_3700
						JSRR R6
						
						; store status into R3
						ADD R3, R2, #0
						
						; prefix 
						LEA R0, MAIN_TEXT_5
						PUTS
						
						; print ID
						ADD R2, R1, #0
						LD R6, MAIN_HEX_4000
						JSRR R6
						
						LEA R0, MAIN_TEXT_6
						PUTS
						
						; run check on status
						ADD R1, R3, #0
						BRz MAIN_OPTION_5_F
	MAIN_OPTION_5_T:
						JSR MAIN_PRINT_FREE
						BR MAIN_OPTION_5_END
	MAIN_OPTION_5_F:
						JSR MAIN_PRINT_BUSY
MAIN_OPTION_5_END:
						LD R0, MAIN_CHAR_NEWLINE
						OUT
						BR MAIN_START
						
MAIN_OPTION_5_INVALID:
						LEA R0, MAIN_INVALID_MSG
						PUTS
						BR MAIN_START

; SUB_3800_FIRST_FREE						
MAIN_OPTION_6:
						ADD R1, R1, #-1
						BRp MAIN_END
						
						
						; get value
						LD R6, MAIN_HEX_3800
						JSRR R6
						ADD R2, R2, #0
						BRzp MAIN_OPTION_6_ACCEPT
						
						; print message and restart
						LEA R0, MAIN_TEXT_8
						PUTS
						BR MAIN_START
						
	MAIN_OPTION_6_ACCEPT:
						; print prefix
						LEA R0, MAIN_TEXT_7
						PUTS
						; print number
						LD R6, MAIN_HEX_4000
						JSRR R6
						LD R0, MAIN_CHAR_NEWLINE
						OUT
						
						BR MAIN_START
						
						
MAIN_END:
						LEA R0, MAIN_QUIT_MSG
						PUTS
						HALT
				
; Local subroutines		
MAIN_PRINT_NOT:			ST R7, BACKUP_MAIN_R7
						LEA R0, MAIN_TEXT_NOT
						PUTS
						LD R7, BACKUP_MAIN_R7
						RET
						
MAIN_PRINT_BUSY:		ST R7, BACKUP_MAIN_R7
						LEA R0, MAIN_TEXT_BUSY
						PUTS
						LD R7, BACKUP_MAIN_R7
						RET
						
MAIN_PRINT_FREE:		ST R7, BACKUP_MAIN_R7
						LEA R0, MAIN_TEXT_FREE
						PUTS
						LD R7, BACKUP_MAIN_R7
						RET

; Local data	

MAIN_CHAR_NEWLINE		.FILL x0A
MAIN_CHAR_SPACE			.FILL x20
MAIN_CHAR_0				.FILL x30

MAIN_HEX_1000			.FILL x1000


MAIN_HEX_3150			.FILL x3150 ; SUB_3150_MENU

MAIN_HEX_3300			.FILL x3300 ; SUB_3300_ALL_MACHINES_BUSY	(option 1)
MAIN_HEX_3400			.FILL x3400 ; SUB_3400_ALL_MACHINES_FREE	(option 2)
MAIN_HEX_3500			.FILL x3500 ; SUB_3500_NUM_BUSY_MACHINES	(option 3)
MAIN_HEX_3600			.FILL x3600 ; SUB_3600_NUM_FREE_MACHINES	(option 4)
MAIN_HEX_3700			.FILL x3700 ; SUB_3700_MACHINE_STATUS		(option 5)
MAIN_HEX_3800			.FILL x3800 ; SUB_3800_FIRST_FREE			(option 6)

MAIN_HEX_4000			.FILL x4000 ; SUB_4000_OUTPUT_VALUE
MAIN_HEX_4100			.FILL x4100 ; SUB_4100_INPUT

MAIN_HEX_5000			.FILL x5000

MAIN_TEXT_NOT			.STRINGZ "NOT "
MAIN_TEXT_BUSY 			.STRINGZ "busy"
MAIN_TEXT_FREE 			.STRINGZ "free"

MAIN_TEXT_1				.STRINGZ ". All machines are "
MAIN_TEXT_2				.STRINGZ ". There are "
MAIN_TEXT_3				.STRINGZ " machines"
MAIN_TEXT_4				.STRINGZ ". Which machine? "
MAIN_TEXT_5				.STRINGZ "Machine "
MAIN_TEXT_6				.STRINGZ " is "
MAIN_TEXT_7				.STRINGZ ". The first free machine is number "
MAIN_TEXT_8				.STRINGZ ". No free machines."

MAIN_QUIT_MSG			.STRINGZ ". Goodbye!"

MAIN_INVALID_MSG		.STRINGZ "\nERROR: Invalid input.\n"

BACKUP_MAIN_R7			.BLKW #1

;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3150_MENU
;							Prints out a menu with numerical options,
;							allows the user to select one, and returns
;							selection value.
;							(NOTE: Uses double subroutine mem size)
;
; INPUTS				None
; OUTPUTS				R1 <- menu option selected
;-----------------------------------------------------------------------
.ORIG x3150				
						ST R0, BACKUP_3150_R0
						ST R2, BACKUP_3150_R2
						ST R3, BACKUP_3150_R3
						ST R7, BACKUP_3150_R7

SUB_3150_START:
						LD R1, SUB_3150_TEXTPTR
						LDR R0, R1, #0
						
SUB_3150_PRINTLOOP:
						OUT
						ADD R1, R1, #1
						LDR R0, R1, #0
						BRzp SUB_3150_PRINTLOOP
						
SUB_3150_INPUT:	
						GETC
						OUT
						LD R1, SUB_3150_CHAR_0
						NOT R1, R1
						ADD R1, R1, #1
						ADD R1, R0, R1
						BRnz SUB_3150_RETRY
						
						ADD R1, R1, #-7
						BRp SUB_3150_RETRY
						ADD R1, R1, #7
						
						BR SUB_3150_END
						
SUB_3150_RETRY:
						LEA R0, SUB_3150_INVALID_CHAR
						PUTS
						BR SUB_3150_START
						
SUB_3150_END:
						LD R0, BACKUP_3150_R0
						LD R2, BACKUP_3150_R2
						LD R3, BACKUP_3150_R3
						LD R7, BACKUP_3150_R7
SUB_3150_RETURN:
						RET
						
SUB_3150_TEXTPTR		.FILL x31B0
SUB_3150_CHAR_0			.FILL x30
						
BACKUP_3150_R0			.BLKW #1
BACKUP_3150_R2			.BLKW #1
BACKUP_3150_R3			.BLKW #1
BACKUP_3150_R7			.BLKW #1

SUB_3150_INPUT_PROMPT	.STRINGZ ">"

.ORIG x3180

SUB_3150_INVALID_CHAR	.STRINGZ "\nERROR: Invalid input. Please try again.\n"

.ORIG x31B0
						.STRINGZ "***********************************\n"
						.STRINGZ "*       THE BUSYNESS SERVER       *\n"
						.STRINGZ "***********************************\n"
						.STRINGZ "1. Check if all machines are busy\n"
						.STRINGZ "2. Check if all machines are free\n"
						.STRINGZ "3. Display number of busy machines\n"
						.STRINGZ "4. Display number of free machines\n"
						.STRINGZ "5. Display status of a machine\n"
						.STRINGZ "6. Display ID of first available\n"
						.STRINGZ "7. QUIT\n"
						.FILL #-1
						


;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3300_ALL_MACHINES_BUSY
;							Checks if all machines are busy.
;
; INPUTS				None
; OUTPUTS				(R2): 1 if true, 0 if false
;-----------------------------------------------------------------------
.ORIG x3300				
						ST R1, BACKUP_3300_R1
						ST R7, BACKUP_3300_R7
						
						AND R2, R2, #0
						ADD R2, R2, #1
						
						LDI R1, SUB_3300_HEX_5000
						BRz SUB_3300_END
						
						ADD R2, R2, #-1
						
SUB_3300_END:
						LD R1, BACKUP_3300_R1
						LD R7, BACKUP_3300_R7
SUB_3300_RETURN:
						RET
						
SUB_3300_HEX_5000		.FILL x5000
						
BACKUP_3300_R1			.BLKW #1
BACKUP_3300_R7			.BLKW #1


;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3400_ALL_MACHINES_FREE
;							Checks if all machines are free.
;
; INPUTS				None
; OUTPUTS				(R2): 1 if true, 0 if false
;-----------------------------------------------------------------------
.ORIG x3400				
						ST R1, BACKUP_3400_R1
						ST R7, BACKUP_3400_R7
						
						AND R2, R2, #0
						ADD R2, R2, #1
						
						; if all machines are free, vector is all 1's
						; so it'll be 0 if 1 is added to it
						LDI R1, SUB_3400_HEX_5000
						ADD R1, R1, #1
						BRz SUB_3400_END
						
						ADD R2, R2, #-1
						
SUB_3400_END:
						LD R1, BACKUP_3400_R1
						LD R7, BACKUP_3400_R7
SUB_3400_RETURN:
						RET
						
SUB_3400_DEC_NEG_16		.FILL #-16

SUB_3400_HEX_5000		.FILL x5000
						
BACKUP_3400_R1			.BLKW #1
BACKUP_3400_R7			.BLKW #1


;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3500_NUM_BUSY_MACHINES
;							Returns amount of busy machines.
;
; INPUTS				None
; OUTPUTS				(R2): amount of busy machines
;-----------------------------------------------------------------------
.ORIG x3500				
						ST R1, BACKUP_3500_R1 
						ST R6, BACKUP_3500_R6 ; sub mgr
						ST R7, BACKUP_3500_R7
						
						LD R6, SUB_3500_HEX_3600
						JSRR R6
						
						LD R1, SUB_3500_DEC_16
						NOT R2, R2
						ADD R2, R2, #1
						ADD R2, R2, R1
						
SUB_3500_END:
						LD R1, BACKUP_3500_R1
						LD R6, BACKUP_3500_R6
						LD R7, BACKUP_3500_R7
SUB_3500_RETURN:
						RET
						
SUB_3500_DEC_16			.FILL #16
						
SUB_3500_HEX_3600		.FILL x3600 ; SUB_3600_NUM_FREE_MACHINES
SUB_3500_HEX_5000		.FILL x5000 ; BUSYNESS
						
BACKUP_3500_R1			.BLKW #1
BACKUP_3500_R6			.BLKW #1
BACKUP_3500_R7			.BLKW #1


;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3600_NUM_FREE_MACHINES
;							Returns amount of free machines.
;
; INPUTS				None
; OUTPUTS				(R2): amount of free machines
;-----------------------------------------------------------------------
.ORIG x3600				
						ST R0, BACKUP_3600_R0 ; sentinel
						ST R1, BACKUP_3600_R1 ; busyness vector
						ST R6, BACKUP_3600_R6 ; sub mgr
						ST R7, BACKUP_3600_R7
						
					
						LD R0, SUB_3600_DEC_16
						LDI R1, SUB_3600_HEX_5000
						AND R2, R2, #0
						
SUB_3600_COUNTLOOP:
							ADD R1, R1, #0
							BRz SUB_3600_END
							BRp SUB_3600_SKIP_INCREMENT
							
							ADD R2, R2, #1
							
	SUB_3600_SKIP_INCREMENT:	
						ADD R1, R1, R1
						ADD R0, R0, #-1
						BRp SUB_3600_COUNTLOOP
						
						
SUB_3600_END:
						LD R0, BACKUP_3600_R0
						LD R1, BACKUP_3600_R1
						LD R6, BACKUP_3600_R6
						LD R7, BACKUP_3600_R7
SUB_3600_RETURN:
						RET
						
SUB_3600_DEC_16			.FILL #16
						
SUB_3600_HEX_5000		.FILL x5000 ; BUSYNESS
						
BACKUP_3600_R0			.BLKW #1
BACKUP_3600_R1			.BLKW #1
BACKUP_3600_R6			.BLKW #1
BACKUP_3600_R7			.BLKW #1


;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3700_MACHINE_STATUS
;							Returns status of a given machine.
;
; INPUTS				(R1): machine ID
; OUTPUTS				(R2): status
;-----------------------------------------------------------------------
.ORIG x3700				
						ST R0, BACKUP_3700_R0
						ST R1, BACKUP_3700_R1
						ST R3, BACKUP_3700_R3
						ST R7, BACKUP_3700_R7
						
						; load vector
						LDI R3, SUB_3700_HEX_5000
						
						AND R2, R2, #0
						
						; R1 gets amount to shift by
						LD R0, SUB_3700_DEC_15
						NOT R1, R1
						ADD R1, R1, #1
						ADD R1, R0, R1
						
						; skip shift if none needed
						BRz SUB_3700_SKIP_SHIFT
						
						
						
SUB_3700_SHIFTLOOP:
							ADD R3, R3, R3
							ADD R1, R1, #-1
							BRp SUB_3700_SHIFTLOOP
	SUB_3700_SKIP_SHIFT:
						
						ADD R3, R3, #0
						BRzp SUB_3700_END
						
						ADD R2, R2, #1
						
SUB_3700_END:
						LD R0, BACKUP_3700_R0
						LD R1, BACKUP_3700_R1
						LD R3, BACKUP_3700_R3
						LD R7, BACKUP_3700_R7
SUB_3700_RETURN:
						RET
						
SUB_3700_DEC_15			.FILL #15
						
SUB_3700_HEX_5000		.FILL x5000 ; BUSYNESS
						
BACKUP_3700_R0			.BLKW #1
BACKUP_3700_R1			.BLKW #1
BACKUP_3700_R3			.BLKW #1
BACKUP_3700_R7			.BLKW #1

;-----------------------------------------------------------------------
; SUBROUTINE			SUB_3800_FIRST_FREE
;							Returns ID of first free machine.
;
; INPUTS				None
; OUTPUTS				(R2): ID
;-----------------------------------------------------------------------
.ORIG x3800				
						ST R0, BACKUP_3800_R0
						ST R1, BACKUP_3800_R1
						ST R3, BACKUP_3800_R3
						ST R7, BACKUP_3800_R7
						
						
						
						AND R2, R2, #0
						LDI R3, SUB_3800_HEX_5000 ; load vector
						BRnp SUB_3800_SHIFTLOOP
						
						; if vector is 0, return -1
						ADD R2, R2, #-1
						BR SUB_3800_END
						
SUB_3800_SHIFTLOOP:
							ADD R2, R2, #1
							ADD R3, R3, R3
							BRnp SUB_3800_SHIFTLOOP
						
						; set R2 to be right-to-left numbering
						LD R1, SUB_3800_DEC_16
						NOT R2, R2 
						ADD R2, R2, #1
						ADD R2, R1, R2
						
SUB_3800_END:
						LD R0, BACKUP_3800_R0
						LD R1, BACKUP_3800_R1
						LD R3, BACKUP_3800_R3
						LD R7, BACKUP_3800_R7
SUB_3800_RETURN:
						RET
						
SUB_3800_DEC_16		.FILL #16
						
SUB_3800_HEX_5000		.FILL x5000 ; BUSYNESS
						
BACKUP_3800_R0			.BLKW #1
BACKUP_3800_R1			.BLKW #1
BACKUP_3800_R3			.BLKW #1
BACKUP_3800_R7			.BLKW #1


;-----------------------------------------------------------------------
; SUBROUTINE			SUB_4000_OUTPUT_VALUE
; 							Prints value in R2 to console
;
; INPUTS				R2: Value
; OUTPUTS				None
;-----------------------------------------------------------------------
.ORIG x4000
						ST R0, BACKUP_4000_R0 ; output mgr
						ST R1, BACKUP_4000_R1 ; loop sentinel
						ST R2, BACKUP_4000_R2 ; value to output
						ST R3, BACKUP_4000_R3 ; val to subtract
						ST R4, BACKUP_4000_R4 ; pointer for R3
						ST R5, BACKUP_4000_R5 ; pointer to array
						ST R7, BACKUP_4000_R7 ; R7 backup
						
						; if input value is 0, just print "0" and return
						ADD R2, R2, #0
						BRnp SUB_4000_INPUT_NONZERO
						
						LD R0, SUB_4000_CHAR_0
						OUT
						BR SUB_4000_RETURN
						
SUB_4000_INPUT_NONZERO:
						AND R0, R0, #0
						LD R1, SUB_4000_HEX_0010
						LEA R5, SUB_4000_OUT_ARRAY
						
SUB_4000_INIT_ARR:			; initialize array
							STR R0, R5, #0
							ADD R5, R5, #1
							ADD R1, R1, #-1
							BRp SUB_4000_INIT_ARR
							
						; set flag
						AND R1, R1, #0
						ST R1, SUB_4000_FLAG_LEADING
						
						; sign char <- '+'
						LD R1, SUB_4000_CHAR_PLUS
						ST R1, SUB_4000_SIGN_CHAR
						
						; if R2 < 0, make it positive, set sign char to '-'
						ADD R2, R2, #0
						BRzp SUB_4000_SKIP_MAKE_POSITIVE
						
						LD R1, SUB_4000_CHAR_MINUS
						ST R1, SUB_4000_SIGN_CHAR
						NOT R2, R2
						ADD R2, R2, #1
						
SUB_4000_SKIP_MAKE_POSITIVE:
						
						LEA R4, SUB_4000_DEC_10000 ; initial subtract val
						LEA R5, SUB_4000_OUT_ARRAY ; array address
						
						LDR R3, R4, #0 ; initial load
						
SUB_4000_PREPLOOP:		; prep value as chars into printing array

							LD R0, SUB_4000_CHAR_0
							NOT R3, R3
							ADD R3, R3, #1
							ADD R0, R0, #-1
	SUB_4000_NEGLOOP:			; subtract each place value from R2 until negative
								ADD R0, R0, #1
								ADD R2, R3, R2
								BRzp SUB_4000_NEGLOOP
								
							; restore R2 to positive
							NOT R3, R3
							ADD R3, R3, #1
							ADD R2, R2, R3
							
							; check if result char is '0'
							LD R3, SUB_4000_CHAR_0
							NOT R3, R3
							ADD R3, R3, #1
							ADD R3, R0, R3
							BRnp SUB_4000_STORE_CHAR
							
							; check flag if any leading digits have been output
							LD R3, SUB_4000_FLAG_LEADING
							BRz SUB_4000_SKIP_STORE_CHAR
							
SUB_4000_STORE_CHAR:
							; store char and advance pointer
							STR R0, R5, #0
							ADD R5, R5, #1
							ST R0, SUB_4000_FLAG_LEADING
							
SUB_4000_SKIP_STORE_CHAR:
							ADD R4, R4, #1
							LDR R3, R4, #0
							BRp SUB_4000_PREPLOOP
						
						LEA R0, SUB_4000_OUT_ARRAY
						LD R3, SUB_4000_CHAR_0 ; negative char 0
						NOT R3, R3
						ADD R3, R3, #1
						
;						ADD R0, R0, #-1
						
;SUB_4000_OFFSET_LOOP:		; offset print start until first digit =/= 0
;							ADD R0, R0, #1
;							LDR R1, R0, #0		
;							ADD R1, R1, R3
;							BRnz SUB_4000_OFFSET_LOOP
						
						PUTS ; print value
						
SUB_4000_RETURN:
						LD R0, BACKUP_4000_R0
						LD R1, BACKUP_4000_R1
						LD R2, BACKUP_4000_R2
						LD R3, BACKUP_4000_R3
						LD R4, BACKUP_4000_R4
						LD R5, BACKUP_4000_R5
						LD R7, BACKUP_4000_R7
						RET

SUB_4000_FLAG_LEADING	.FILL #0

SUB_4000_DEC_NEG1		.FILL #-1
SUB_4000_DEC_4			.FILL #4

SUB_4000_DEC_10000      .FILL #10000
SUB_4000_DEC_1000       .FILL #1000
SUB_4000_DEC_100        .FILL #100
SUB_4000_DEC_10         .FILL #10
SUB_4000_DEC_1			.FILL #1
SUB_4000_DEC_0			.FILL #0

SUB_4000_SIGN_CHAR		.FILL #-1

SUB_4000_CHAR_PLUS		.FILL x2B
SUB_4000_CHAR_MINUS		.FILL x2D
SUB_4000_CHAR_0			.FILL x30

SUB_4000_HEX_0010		.FILL x0010
SUB_4000_HEX_3400		.FILL x3400
SUB_4000_HEX_4000		.FILL x4000

BACKUP_4000_R0			.BLKW #1
BACKUP_4000_R1			.BLKW #1
BACKUP_4000_R2			.BLKW #1
BACKUP_4000_R3			.BLKW #1
BACKUP_4000_R4			.BLKW #1
BACKUP_4000_R5			.BLKW #1
BACKUP_4000_R7			.BLKW #1

.ORIG x40F0
SUB_4000_OUT_ARRAY		.BLKW x0020



;-----------------------------------------------------------------------
; SUBROUTINE			SUB_4100_INPUT
;							Reads a positive 2-digit number into R2.
;							Also performs on-the-fly input validation.
;							Range of allowable input is #0 to #15.
;
; INPUTS				None
; OUTPUTS				(R2) <- in
;-----------------------------------------------------------------------
.ORIG x4100				
						ST R0, BACKUP_4100_R0 ; input register
						ST R1, BACKUP_4100_R1 ; loop sentinel
						ST R3, BACKUP_4100_R3 ; mult operand
						ST R4, BACKUP_4100_R4 ; value retrieval
						ST R6, BACKUP_4100_R6 ; subroutine addresses
						ST R7, BACKUP_4100_R7 ; R7 backup
						
						LEA R0, SUB_4100_INPUT_PROMPT ; prompt for input
						PUTS
						
						AND R2, R2, #0			; (R2) <- 0
						; init flags
						ST R2, SUB_4100_FLAG_NEGATIVE
						ST R2, SUB_4100_FLAG_PREFIX
						
						LD R1, SUB_4100_DEC_2	; init sentinel
						LD R4, SUB_4100_CHAR_0	; for char->value. DO NOT CHANGE
						NOT R4, R4
						ADD R4, R4, #1
						
SUB_4100_INPUT_LOOP:		
							GETC
							OUT
							
							; break out of loop if ENTER is pressed.
							LD R6, SUB_4100_CHAR_NEWLINE
							NOT R6, R6
							ADD R6, R6, #1
							ADD R6, R0, R6
							BRz SUB_4100_RETURN
							
							; check if it might be sign, i.e. char < '0'
							LD R6, SUB_4100_CHAR_0
							NOT R6, R6
							ADD R6, R6, #1
							ADD R6, R0, R6
							BRzp SUB_4100_SKIP_CHECK_SIGN
							
							BRp SUB_4100_REJECT_CHAR
														
	SUB_4100_REJECT_CHAR: 	; give error message
							LEA R0, SUB_4100_REJECT_PROMPT
							PUTS
							; repeat input prompt
							LEA R0, SUB_4100_INPUT_PROMPT
							PUTS
							
							; print out value given so far
							LD R6, SUB_4100_HEX_4200
							JSRR R6
							
							BR SUB_4100_INPUT_LOOP
							
	SUB_4100_SKIP_CHECK_SIGN:			
							; check if char isn't > '9'
							LD R6, SUB_4100_CHAR_9
							NOT R6, R6
							ADD R6, R6, #1
							ADD R6, R0, R6
							BRp SUB_4100_REJECT_CHAR
							
							; multiply R2 by 10
							LD R3, SUB_4100_DEC_10
							LD R6, SUB_4100_HEX_4300
							JSRR R6					 ; (R2) <- (R2) * 10
							
							ADD R0, R0, R4 ; char -> value
							ADD R2, R0, R2 ; (R2) <- (R0) + (R2)
							
							; give prefix flag a positive number
							ST R6, SUB_4100_FLAG_PREFIX
							
							; advance loop
							ADD R1, R1, #-1
							BRp SUB_4100_INPUT_LOOP
						
SUB_4100_END_INPUT:
						LD R0, SUB_4100_CHAR_NEWLINE
						OUT
SUB_4100_RETURN:		; if flag not 0, make the result negative.
						LD R6, SUB_4100_FLAG_NEGATIVE
						BRz SUB_4100_SKIP_NEGATE
						
						NOT R2, R2
						ADD R2, R2, #1
						
SUB_4100_SKIP_NEGATE:
						LD R0, BACKUP_4100_R0
						LD R1, BACKUP_4100_R1
						LD R3, BACKUP_4100_R3
						LD R4, BACKUP_4100_R4
						LD R6, BACKUP_4100_R6
						LD R7, BACKUP_4100_R7
						RET

SUB_4100_FLAG_NEGATIVE	.BLKW #1 ; negative if a '-' was input
SUB_4100_FLAG_PREFIX	.BLKW #1 ; zero while no numbers have been input

SUB_4100_DEC_2			.FILL #2
SUB_4100_DEC_10			.FILL #10

SUB_4100_HEX_4200		.FILL x4200
SUB_4100_HEX_4300		.FILL x4300

SUB_4100_CHAR_NEWLINE	.FILL x0A
SUB_4100_CHAR_PLUS		.FILL x2B
SUB_4100_CHAR_MINUS		.FILL x2D
SUB_4100_CHAR_0			.FILL x30
SUB_4100_CHAR_9			.FILL x39

BACKUP_4100_R0			.BLKW #1
BACKUP_4100_R1			.BLKW #1
BACKUP_4100_R3			.BLKW #1
BACKUP_4100_R4			.BLKW #1
BACKUP_4100_R6			.BLKW #1
BACKUP_4100_R7			.BLKW #1

SUB_4100_INPUT_PROMPT	.STRINGZ ">"
SUB_4100_REJECT_PROMPT	.STRINGZ "\n\tERROR: Invalid char was given.\n\tPlease continue input with: 0-9\n"



;-----------------------------------------------------------------------
; SUBROUTINE			SUB_4300_MULTIPLY
; 							Multiplies value in R2 by R3.
;
; INPUTS				R2, R3: operands
; OUTPUTS				R2: result
;-----------------------------------------------------------------------

.ORIG x4300				
						ADD R2, R2, #0
						BRz SUB_4300_RETURN ; skip if trying to mult. 0
						
						ST R0, BACKUP_4300_R0 ; output mgr
						ST R3, BACKUP_4300_R3 ; multiplicand
						ST R4, BACKUP_4300_R4 ; mask
						ST R5, BACKUP_4300_R5 ; adder
						ST R7, BACKUP_4300_R7 ; R7 backup
						
						LD R4, SUB_4300_DEC_1 ; load mask
						ST R4, SUB_4300_MASK
						AND R5, R5, #0		 ; set adder to input
						ADD R5, R2, #0
						AND R2, R2, #0
						LD R3, BACKUP_4300_R3
						
SUB_4300_MULT_LOOP:			AND R4, R3, R4 ; cmp. multiplicand to mask
							BRz SUB_4300_DO_NOT_MULT
							
							ADD R2, R2, R5
							
							
SUB_4300_DO_NOT_MULT:		ADD R5, R5, R5 ; shift adder left
							LD R4, SUB_4300_MASK
							ADD R4, R4, R4 ; shift mask left
							ST R4, SUB_4300_MASK
							BRnp SUB_4300_MULT_LOOP
						
						LD R0, BACKUP_4300_R0
						LD R3, BACKUP_4300_R3
						LD R4, BACKUP_4300_R4
						LD R5, BACKUP_4300_R5
						LD R7, BACKUP_4300_R7
						
SUB_4300_RETURN:		RET
						
; data

SUB_4300_DEC_1			.FILL #1

SUB_4300_MASK			.BLKW #1

BACKUP_4300_R0          .BLKW #1
BACKUP_4300_R3          .BLKW #1
BACKUP_4300_R4          .BLKW #1
BACKUP_4300_R5			.BLKW #1
BACKUP_4300_R7			.BLKW #1

; ----------------------------------------------------------------------

.ORIG x5000
BUSYNESS				.FILL x00A0
	
.END

