.macro read_input_path %message, %buffer, %buffer_size
    la 		a0 %message 			# Loading message for user
	li 		a7 4
	ecall
	
	la 		a0 %buffer				# Buffer for saving a path
	li 		a1 %buffer_size			# Size of buffer with path
	li 		a7 8 					# Reading string input with file path from user
	ecall
	
	li 		t0 '\n' 				# Loading newline symbol
	mv 		t1 a0					# Saving address of buffer in t1
	
reading_loop:
	lb 		t2 (t1) 				# Loading current character
	beq 	t2 t0 replace_newline 	# If character is newline, replace it
	addi 	t1 t1 1 				# Moving to next character
	j reading_loop
	
replace_newline:
	sb 		zero (t1)				# Replacing newline with a null terminator
	li 		a7 1024					# Reading a file from path with syscall
	li 		a1 0					# Enabling reading mode with 0 in a1 register
	ecall
.end_macro

.macro read_input_substring %message, %buffer, %buffer_size
    la 		a0 %message 			# Loading message for user
	li 		a7 4
	ecall
	
	la 		a0 %buffer				# Buffer for saving a path
	li 		a1 %buffer_size			# Size of buffer with path
	li 		a7 8 					# Reading string input with file path from user
	ecall
	
	li 		t0 '\n' 				# Loading newline symbol
	mv 		t1 a0					# Saving address of buffer in t1
	
reading_loop:
	lb 		t2 (t1) 				# Loading current character
	beq 	t2 t0 replace_newline	# If character is newline, end reading
	addi 	t1 t1 1 				# Moving to next character
	j reading_loop
	
replace_newline:
	sb 		zero (t1)				# Replacing newline with a null terminator

.end_macro