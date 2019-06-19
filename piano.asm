DATAS SEGMENT
	key   		  dw ?
	x 			  dw 0
	y			  dw 0
	keyheight  	  dw 60
	top_y		  dw 0
	bottom_y	  dw 60
	l_topwidth    dw 29
	r_topwidth 	  dw 26
	l_bottomwidth dw 47
	r_bottomwidth dw 44
	hint          db 'Black Key  :  S D   G H J', 0dh, 0ah
				  db 'White Key  : Z X C V B N M', 0dh, 0ah,0ah
				  db 'Press 1    : Little Star', 0dh,0ah
				  db 'Press 2    : Mary had a little lamb',0dh,0ah,0ah,0ah
				  db 'Press Enter: Exit','$'
	white_keynote dw 262 ; C
    	  		  dw 294 ; D
    	  		  dw 330 ; E
    	 		  dw 349 ; F
    	  		  dw 392 ; G
    	  		  dw 440 ; A
    	  		  dw 494 ; B
    black_keynote dw 277 ; C#
    			  dw 311 ; D#
    			  dw 370 ; F#
    			  dw 415 ; G#
    			  dw 466 ; A#
    song1_freq    dw 262, 262, 392, 392, 440, 440, 392
    			  dw 349, 349, 330, 330, 294, 294, 262
    			  dw 392, 392, 349, 349, 330, 330, 294
    			  dw 392, 392, 349, 349, 330, 330, 294
    			  dw 262, 262, 392, 392, 440, 440, 392
    			  dw 349, 349, 330, 330, 294, 294, 262
    			  dw -1
    song1_time    dw 6 DUP(25),50
    			  dw 6 DUP(25),50
    			  dw 6 DUP(25),50
    			  dw 6 DUP(25),50
    			  dw 6 DUP(25),50
    			  dw 6 DUP(25),50
    song2_freq	  dw 330, 294, 262, 294, 3 DUP(330)  ; bar1,2
    			  dw 294, 294, 294, 330, 392, 392    ; bar3,4
    			  dw 330, 294, 262, 294, 4 DUP(330)  ; bar5,6 
    			  dw 294, 294, 330, 294, 262, 0ffffh ; bar7,8
    song2_time    dw 6 DUP(25), 50					 ; bar1,2
    			  dw 2 DUP(25,25,50)				 ; bar3,4
    			  dw 12 DUP(25),100					 ; bar5,6,7,8
DATAS ENDS

STACKS SEGMENT
STACKS ENDS

CODES SEGMENT
    ASSUME CS:CODES,DS:DATAS,SS:STACKS
START:
main proc far
    MOV AX,DATAS
    MOV DS,AX
    call init_view
	call show_keys
    call show_str
new_note:
	mov ah,0
	int 16h
;press '\n' exit
    cmp al,0dh    
    je  exit
    cmp al,31h			; song1
    je  song1
    cmp al,32h			; song2
    je  song2
    jmp skip
song1:
	lea si,song1_freq
	lea bp,ds:song1_time
	call play_songs
	jmp new_note
song2:
	lea si,song2_freq
	lea bp,ds:song2_time
	call play_songs
	jmp new_note
skip:
    call key_to_note
    cmp ax,'n'		; not piano key
    je  new_note
    mov si,ax
    mov di,[bx][si]
    mov bx,10		; 10 * 10ms
    call soundf
    call show_keys
    jmp new_note
    
exit:
    mov ah,0  ;clear screen
    mov al,06
    int 10h
    MOV AH,4CH
    INT 21H
    ret
main endp
;---------------------------
init_view proc near
	push ax
	push bx
	push cx
	push dx
; from (0,0) to (18h,4fh)    
    mov ax,0600h
    mov	bh,07
    mov	cx,0
    mov dx,184fh
    int 10h
    
; 640 * 200 display mode
    mov ah,0
    mov al,06
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
init_view endp

show_keys proc near
	push ax
	push bx
	push cx
	push dx
	push di
	push si	

	mov ah,0bh
	mov bh,1
	mov bl,5
	int 10h
;------------------------
; show top white keys
	mov cx,7
	mov bx,l_topwidth
	mov al,1
	mov dx,top_y
	mov x,0
lp1:
	cmp cx,4
	jne skip1
	sub x,bx
	add x,2
	mov bx,r_topwidth
skip1:
	call draw_rectangle 
	add x,bx
	add x,bx
	loop lp1

;------------------------
; show bottom white keys
	mov cx,7
	mov bx,l_bottomwidth
	mov al,1
	mov dx,bottom_y
	mov x,0
lp2:
	cmp cx,4
	jne skip2
	mov bx,r_bottomwidth
skip2:
	call draw_rectangle 
	add x,bx
	add x,2
	loop lp2

;------------------------
; show black keys
	mov cx,5
	mov bx,l_topwidth
	mov al,0
	mov dx,top_y
	mov x,29
lp3:
	cmp cx,3
	jne skip3
	mov x,173
	mov bx,r_topwidth
skip3:
	call draw_rectangle 
	add x,bx
	add x,bx
	loop lp3
	
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
show_keys endp

;------------------------ 
; inlet parameters: di-note freq, bx-lasting time 
soundf proc near
	push ax
	push bx
	push cx
	push dx
	push di
	mov al,0b6h		; write timer mode reg
	out 43h,al
	mov dx,12h
	mov ax,348ch
;	0x12348c / f
	div di
	out 42h,al		; write timer2 count low byte
	mov al,ah
	out 42h,al		; write timer2 count high byte
	in  al,61h		; get current port setting
	mov ah,al
	or  al,3
	out 61h,al
wait1:
	mov cx,663		; control lasting time of note (10ms)
	call waitf
delay:
	loop delay
	dec bx
	jnz wait1
	mov al,ah
	out 61h,al
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
soundf endp

;------------------------ 
waitf proc near
	push ax
waitf1:
	in  al,61h
	and al,10h		; check PB4
	cmp al,ah
	je  waitf1
	mov ah,al
	loop waitf1
	pop ax
	ret
waitf endp
;------------------------
show_str proc near
	push ax
	push cx
	push dx
	mov cx,16
lp:				;print linefeed
	mov dl,0ah
	mov ah,2
	int 21h
	loop lp
	
	lea dx,hint
	mov  ah,9
	int  21h
	pop dx
	pop cx
	pop ax
	ret
show_str endp
;-----------------------
key_to_note proc near
	push si
	cmp  ah,2ch
	jb	 skip
	cmp  ah,32h
	ja   skip
white_key:
	mov  bx,offset white_keynote
	mov  al,ah
	xor  ah,ah
	sub  ax,2ch
	mov  si,'w'
	call press_key
	add  ax,ax
	jmp  quit
skip:
	cmp  ah,1fh
	jb   other_key
	cmp  ah,24h
	ja   other_key
	cmp  ah,21h
	je   other_key
black_key:
	mov  bx,offset black_keynote
	mov  al,ah
	xor  ah,ah
	sub  ax,1fh
	cmp  ax,3
	jb   left_blackkey
	dec  ax
left_blackkey:
	mov  si,'b'
	call press_key
	add  ax,ax
	jmp  quit
other_key:
	mov ax,'n'
quit:
	pop  si
	ret
key_to_note endp
;-------------------------
; inlet parameters: si-key type, ax-key num
press_key proc near
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	
	mov key,ax

	cmp si,'w'
	jne black_key
white_topkey:
; change top white key color
	push ax
	push cx
	push key
	cmp key,3
	jb  left_topkey
right_topkey:
	mov bx,r_topwidth
	mov x,147
	mov ax,r_topwidth
	sub key,3
	jmp get_topx
left_topkey:
	mov bx,l_topwidth
	mov x,0
	mov ax,l_topwidth
get_topx:
	mov  cx,key
	add  cx,cx
	mul  cx
	add  x,ax
	pop  key
	pop  cx
	pop  ax

	mov al,0  			; black color
	mov dx,top_y
	call draw_rectangle

white_bottomkey:
; change bottom white key color
	push ax
	push cx
	push key
	cmp key,3
	jb  left_bottomkey
right_bottomkey:
	mov bx,r_bottomwidth
	mov x,147
	mov ax,r_bottomwidth
	sub key,3
	jmp get_bottomx
left_bottomkey:
	mov bx,l_bottomwidth
	mov x,0
	mov ax,l_bottomwidth
get_bottomx:
	add  ax,2
	mov  cx,key
	mul  cx
	add  x,ax
	pop  key
	pop  cx
	pop  ax

	mov al,0  			; black color
	mov dx,bottom_y
	call draw_rectangle	
	jmp  quit

black_key:
; change black key color
	push ax
	push cx
	push key
	cmp key,2
	jb  left_blackkey
right_blackkey:
	mov bx,r_topwidth
	mov x,173			; first black key location
	mov ax,r_topwidth
	sub key,2
	jmp get_bkeyx
left_blackkey:
	mov bx,l_topwidth
	mov x,29
	mov ax,l_topwidth
get_bkeyx:
	mov  cx,key
	add  cx,cx
	mul  cx
	add  x,ax
	pop  key
	pop  cx
	pop  ax
	mov al,1  			; white color
	mov dx,top_y
	call draw_rectangle
quit:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
press_key endp

;---------------------------
; inlet parameters: al-color, bx-width, dx-locatoin(y), x-location(x)
draw_rectangle proc near   
	push ax
	push bx
	push cx
	push dx
	push si
	push di
draw:
	mov ah,0ch
	mov di,keyheight	; height
lp1:
	mov si,bx			; width
	mov cx,x			; location(x)
lp2:
	int 10h
	inc cx
	dec si
	jnz lp2
	inc dx
	dec di
	jnz lp1
	
	pop  di
	pop  si
	pop	 dx
	pop  cx
	pop  bx
	pop  ax
	ret
draw_rectangle endp 
;---------------------------
; inlet parameters: si-frequent offset, bp-lasting time offset
play_songs proc near
	push bx
	push si
	push di
	push bp
lp:
	mov  di,[si]
	cmp  di,-1
	je   exit
	call note_to_key
	mov  bx,ds:[bp]
	call soundf
	call show_keys
	add  si,2
	add  bp,2
	jmp  lp
exit:
	pop  bp	
	pop  di
	pop	 si
	pop  bx
	ret
play_songs endp
;---------------------------
; inlet parameters: di-note freq
note_to_key proc near
	push ax
	push bx
	push cx
	push di
	push si
; scan white keys	
	mov  bx,0
	mov  cx,7
	lea  si,white_keynote
scan1:
	cmp  di,[si]
	jne  skip1
	mov  si,'w'
	jmp  found
skip1:
	inc  bx
	add  si,2
	loop scan1
	
; scan black keys
	mov  bx,0
	mov  cx,5
	lea  si,black_keynote
scan2:
	cmp  di,[si]
	jne  skip2
	mov  si,'b'
	jmp  found
skip2:
	inc  bx
	add  si,2
	loop scan2	

found: 
	mov  ax,bx
	call press_key
	
	pop  si
 	pop  di
 	pop  cx
 	pop  bx
 	pop  ax
	ret
note_to_key endp
CODES ENDS
    END START






