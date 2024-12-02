.include "macros.asm"

.eqv DEFAULT_BUFFER_SIZE 512 			# Buffer size for reding inputs and data from file
.eqv TEXT_BUFFER_SIZE 10240				# Maximum size of file

.data
path_buffer: 			.space DEFAULT_BUFFER_SIZE
data_buffer: 			.space TEXT_BUFFER_SIZE
param_buffer: 			.space DEFAULT_BUFFER_SIZE
output_text_buffer: 	.space TEXT_BUFFER_SIZE


input_path_message: 	.asciz "Input path of the file to read and process: "
error_path_message: 	.asciz "Incorrect path or path does not exist!"
error_reading_message: 	.asciz "Reading Error!"
input_param_message: 	.asciz "Input substring: "
output_result_message: 	.asciz "Result: "
option_message: 		.asciz "Do you want to see result in console? Press \"Y\" as yes or \"N\" as no for answer:\n"
error_option_message: 	.asciz "Incorrect symbol, please try again! "

output_path: 			.asciz "output.txt"

tests_message: 			.asciz "Tests:\n"

test1_path:				.asciz "test1.txt"
test2_path:				.asciz "test2.txt"
test3_path:				.asciz "test3.txt"
test4_path:				.asciz "test4.txt"
test5_path:				.asciz "test5.txt"
test6_path:				.asciz "test6.txt"



.text
.global main
main: 
	jal 	input_read_path 		# Reading and checking path for file to read from user 
	jal 	read_data				# Reading data from file
	jal 	input_read_parameter	# Reading parameter from user
	jal 	process_data			# Processing data, searching and saving indexes for answer
	jal 	file_output
	jal 	console_output 			# Optional output in console
	jal 	tests					# Testing with other files in directory
	li 		a7 10
	ecall

input_read_path:
	addi 	sp sp -4 					# Saving return address
	sw 		ra (sp)
	
	read_input_path input_path_message, path_buffer, DEFAULT_BUFFER_SIZE # Reading input from user
	
	li 		s1 -1 						# Saving error code
	beq 	s1 a0 error_path			# If a0 = 0, then file does not exist or other error occured
	mv 		t0 a0 						# Saving the file decriptor in t0
	
	lw 		ra (sp) 					# Remembering return address
	addi 	sp sp 4

	ret
	
read_data:
	addi 	sp sp -8 					# Saving return address
	sw 		ra (sp)
	sw 		s0 4(sp)
	
read_data_buffer_loop:
    li 		a7 63						# Reading data using 512 byte buffers from file descriptor
    la 		a1 data_buffer 				# Loading address for buffer for data from file
    li 		a2 DEFAULT_BUFFER_SIZE 		# Loading size of buffer in a2
    ecall
      
    addi 	a1 a1 DEFAULT_BUFFER_SIZE	# Moving buffer address to the next 512 byte buffer
      
    li 		t3 TEXT_BUFFER_SIZE			# Maximum size of text = 10 kilobytes
    sub 	t3 a1 t3					
    la 		a2 data_buffer				# Loading starting address of buffer for data
    blt 	a2 t3 close_file			# Closing file, if there is no more data, error or 0 bytes were read
    ble 	a0 zero close_file
    j 		read_data_buffer_loop 		# Else, continue reading file
    
close_file:   
	mv 		s0 a0						# s0 = size of data
	add 	t1 a1 s0					# t1 = end of buffer for data
	addi 	t1 t1 1
	sb 		zero (t1) 					# Adding null terminator
	
  	li 		a7 57						# Closing file syscall
    ecall
    
  	lw 		ra (sp) 					# Remembering return address
  	lw 		s0 4(sp)
  	addi 	sp sp 8
  	
    ret  
    
input_read_parameter:
	addi 	sp sp -4					# Saving return address
	sw 		ra (sp)
	
	read_input_substring input_param_message, param_buffer, DEFAULT_BUFFER_SIZE
	
	lw 		ra (sp)						# Remembering return address
	addi 	sp sp 4

	ret
	
process_data:
	addi 	sp sp -20					# Moving position of stack for using s registers and saving ra for return
	sw 		ra (sp)
	sw 		s0 4(sp)
	sw 		s1 8(sp)
	sw 		s2 12(sp)
	sw 		s3 16(sp)
	
	la 		t0 data_buffer				# Loading address of data buffer
	la 		t1 param_buffer				# Loading starting address of substring buffer
	la 		t2 output_text_buffer 		# Loading starting address of output buffer
	mv 		s0 zero 					# Current index of string in data
	mv 		s1 zero						# Index of occurrence
	mv 		s2 zero 					# Bool, if there was a first occurrence for setting index in register s0 properly
	li 		s3 0
	
process_loop:
	lb 		t4 (t0)						# Loading character from data
	lb 		t5 (t1)						# Loading character from substring
	beq 	t4 zero process_loop_end		# Ending loop if it is the end of data string
	beq 	t4 t5 equal_characters		# If characters equal, branch
	mv 		s2 zero						# Resetting index of first occurrence
	la 		t1 param_buffer				# Reseting starting address of substring buffer
	addi 	s0 s0 1
	addi 	t0 t0 1						# Moving data characters buffer on next position 
	j 		process_loop
	
	
	
equal_characters:
	beqz 	s2 set_first_occurence
	j 		continue_matching
	
set_first_occurence:
	li 		s2 1
	mv 		s1 s0

continue_matching:
	addi 	s0 s0 1						# Moving index of string data
	addi 	t0 t0 1						# Moving to next character in data
	addi 	t1 t1 1						# Moving to next character in substring
	lb 		t5 (t1) 					# Loading character from substring
	beq 	t5 zero end_of_substring	# If it is newline, then it is the end of substring and we need to save index of occurrence
	
	lb 		t4 (t0)						# Loading character from data
	beq 	t4 zero process_loop_end	# End of data
	beq 	t4 t5 continue_matching		# If equal characters, continue
	
	mv 		s2 zero						# Reseting flag
	la 		t1 param_buffer				# Reseting pointer of substring buffer
	
	addi 	s0 s0 1						# Increasing index and position in data buffer
	addi 	t0 t0 1
	
	j process_loop
	
end_of_substring:
	mv 		a0 s1						# Number to convert
	mv 		a1 t2						# Pointer on output buffer
	jal 	int_to_str
	
	mv 		t2 a1						# Pointer update
	
	li 		t3 32 						# ASCII for space ' '
	sb 		t3 (t2)
	addi 	t2 t2 1
	
	mv 		s2 zero 					# Resetting flag of first occurrence
	la 		t1 param_buffer				# Resetting starting address of substring buffer
	j 		process_loop				

process_loop_end:
	li 		s3 0 						# Adding null terminator
	sb 		s3 (t2)


    
end_process:
	lw 		ra (sp)						# Resetting s registers to сomply with the сonventions
	lw 		s0 4(sp)
	lw 		s1 8(sp)
	lw 		s2 12(sp)
	lw 		s3 16(sp)
	addi 	sp sp 20
	
	ret

file_output:
	addi 	sp sp -4
	sw 		ra (sp)

	la      a0 output_path  			# Address of the output path
    li      a7 1024         			# Syscall for opening a file
    li      a1 1            			# Loading 1 as a mode for writing
    ecall
    
    mv      s0 a0 						# Saving file descriptor

    li      a7 64           			# Syscall for writing into a file
    mv 		a0 s0
    la      a1 output_text_buffer      	# Address of the output buffer
    li      a2 DEFAULT_BUFFER_SIZE    		# Size of the buffer
    ecall
    
    li      a7 57           			# Syscall for closing a file
    ecall
    
    lw 		ra (sp)
    addi 	sp sp 4
    ret
    
console_output:
	addi 	sp sp -4					# Saving return address
	sw 		ra (sp)

	la 		a0 option_message			# Loading mesage to offer user an optional output
	li 		a7 4
	ecall
	
    la      a0 param_buffer          	# Address to store option input
    li      a1 2                		# Size of reading only one character from console, 2 = 1 character + 1 "\n"
    li      a7 8                		# Syscall for reading input from user
    ecall
    
    li      t3, 'Y'              		# ASCII code for 'Y'
    li      t4, 'N'              		# ASCII code for 'N'

    la      t0 param_buffer           	# Address of the input buffer
    lb      t1 (t0)            			# Load the first character
    
    beq     t1 t3 print        			# If input is 'Y', print result in console
    beq     t1 t4 console_output_end  	# If input is 'N', branch to end
    
    li 		a0 10        				# Printing newline in console
    li 		a7 11
    ecall

    la      a0 error_option_message		# Error message, letting user to try again
    li      a7 4                		# Syscall for writing to stdout
    ecall
    
    li 		a0 10        				# Printing newline in console
    li 		a7 11
    ecall
    
    j       console_output

print:
    li 		a0 10        				# Printing newline in console
    li 		a7 11
    ecall

 	la 		a0 output_result_message    # Result message
 	li      a7 4
 	ecall

    la      a0 output_text_buffer       # Loading address and printing data of the output buffer
    li      a7 4
    ecall
    
    li 		a0 10        				# Printing newline in console
    li 		a7 11
    ecall
    
    lw 		ra (sp)						# Remembering return address
    addi 	sp sp 4
    
    ret
    
console_output_end:
	lw 		ra (sp)						# Remembering return address
    addi 	sp sp 4
    
    li 		a0 10        				# Printing newline in console
    li 		a7 11
    ecall
    
	ret
	
	
tests:
	addi 	sp sp -4
	sw 		ra (sp)
	
	la 		a0 tests_message			# Load message that shows a start of tests
	li 		a7 4
	ecall
	
	la 		a0 test1_path				# Test 1
	li 		a7 4
	ecall
	
	li 		a0 10						# Printing newline in console
	li 		a7 11
	ecall
	
	la 		a0 test1_path
	jal 	test						# Testing process for test file
	
	
	la 		a0 test2_path				# Test 2
	li 		a7 4
	ecall
	
	li 		a0 10						# Printing newline in console
	li 		a7 11
	ecall
	
	la 		a0 test2_path
	jal 	test						# Testing process for test file
	
	la 		a0 test3_path				# Test 3
	li 		a7 4
	ecall
	
	li 		a0 10						# Printing newline in console
	li 		a7 11
	ecall
	
	la 		a0 test3_path
	jal 	test						# Testing process for test file
	
	
	la 		a0 test4_path				# Test 4
	li 		a7 4
	ecall
	
	li 		a0 10						# Printing newline in console
	li 		a7 11
	ecall
	
	la 		a0 test4_path
	jal 	test						# Testing process for test file


	la 		a0 test5_path				# Test 5
	li 		a7 4
	ecall
	
	li 		a0 10						# Printing newline in console
	li 		a7 11
	ecall
	
	la 		a0 test5_path
	jal 	test						# Testing process for test file
	
	
	la 		a0 test6_path				# Test 6
	li 		a7 4
	ecall
	
	li 		a0 10						# Printing newline in console
	li 		a7 11
	ecall
	
	la 		a0 test6_path
	jal 	test						# Testing process for test file

	lw 		ra (sp)						# Remembering return address
	addi 	sp sp 4
			
	ret
	
	
test:
	addi 	sp sp -4					# Saving return address
	sw 		ra (sp)
	
	la 		t0 data_buffer				# Loading and clearing data_buffer
	
clear_data_buffer_loop:
	lb 		t1 (t0)									# Loading current character
	beq 	t1 zero clear_param_buffer_loop_prep	# If null terminator, then end clearing
	sb 		zero (t0)								# Clearing current position
	addi 	t0 t0 1									# Moving pointer to the next position
	j 		clear_data_buffer_loop
	
clear_param_buffer_loop_prep:
	
	la 		t0 output_text_buffer		# Loading and clearing param_buffer

clear_param_buffer_loop:	
	lb 		t1 (t0)						# Loading current character
	beq 	t1 zero process_test		# If null terminator, then end clearing
	sb 		zero (t0)					# Clearing current position
	addi 	t0 t0 1						# Moving pointer to the next position
	j 		clear_param_buffer_loop
	
process_test:
	li 		a7 1024						# Reading a file from path with syscall
	li 		a1 0						# Enabling reading mode with 0 in a1 register
	ecall
	
	li 		s1 -1						# Saving error code
	beq 	s1 a0 error_path			# If a0 = 0, then file does not exist or other error occured
	jal 	read_data					# Reading data from test file
	jal 	input_read_parameter		# Input parameter as substring to find in console
	jal 	process_data				# Processing data
	jal 	test_console_output			# Output result in console (without option)
	
	lw 		ra (sp)						# Remembering return address
	addi 	sp sp 4
	ret
	
test_console_output:
	addi 	sp sp -4					# Saving return address
	sw 		ra (sp)
	
 	la 		a0 output_result_message    # Result message
 	li      a7 4
 	ecall

    la      a0 output_text_buffer       # Loading address and printing data of the output buffer
    li      a7 4
    ecall
    
    li 		a0 10        				# Printing newline in console
    li 		a7 11
    ecall
    
    li 		a0 10        				# Printing newline in console
    li 		a7 11
    ecall

	lw 		ra (sp)						# Remembering return address
	addi 	sp sp 4
	ret

# Input: a0 = number to convert from int to str, a1 = address of buffer for string
# Output: a1 = updated address of buffer after saving a string

int_to_str:
    addi 	sp sp -28         	# Moving position of stack for using s registers and saving ra for return
    sw 		ra (sp)
    sw 		s0 4(sp)
    sw 		s1 8(sp)
    sw 		s2 12(sp)
    sw 		s3 16(sp)
    sw 		s4 20(sp)
    sw 		s5 24(sp)

    mv 		s0 a0               # Number to convert from int to str in s0 register
    mv 		s1 a1               # s1 is pointer on output buffer for current number
    addi 	s2 s1 16          	# s2 is temporary buffer with size of maximum 16 digits
    li 		s3 10

    beqz 	s0 int_zero        	# If number to convert is zero, then converting it in int_zero

convert_loop:					# While s0 is not equal zero
    rem 	s4 s0 s3           	# s4 is a last digit of current number: s4 = s0 % 10
    addi 	s4 s4 48          	# Converting digit into ASCII by adding 48
    addi 	s2 s2 -1          	# Moving position backwards in temporary buffer
    sb 		s4 (s2)             # Storing character in buffer
    div 	s0 s0 s3           	# Removing last digit by dividing: s0 = s0 / 10
    bnez 	s0 convert_loop

copy_loop:
    lb 		s4 (s2)             # Loading character from temporary buffer
    sb 		s4 (s1)             # Saving it in output buffer
    sb 		zero (s2)			# Reseting memory to zero in temporary buffer in current position to reuse it in tests
    addi 	s2 s2 1           	# Moving position in temporary buffer
    addi 	s1 s1 1           	# Moving position in output buffer
    lb 		s5 (s2)             # Checking if it is the end of temporary buffer
    bnez 	s5 copy_loop       	# If it is not, continue
	j 		int_to_str_end
    

int_zero:
    li 		s4 48               # ASCII code for '0'
    sb 		s4 (s1)             # Stroring '0' into buffer
    addi 	s1 s1 1           	# Moving buffer's pointer
    j 		int_to_str_end

int_to_str_end:
	mv 		a1 s1				# Return a1
    lw 		ra (sp)				# Resetting s registers to сomply with the сonventions
    lw 		s0 4(sp)
    lw 		s1 8(sp)
    lw 		s2 12(sp)
    lw 		s3 16(sp)
    lw 		s4 20(sp)
    lw 		s5 24(sp)
    addi 	sp sp 28
    
    ret

error_path:
	li 		a7 4						# Output message for error
	la 		a0 error_path_message
	ecall
	
	li 		a7 10						# Syscall finishing a program
	ecall
	
	
