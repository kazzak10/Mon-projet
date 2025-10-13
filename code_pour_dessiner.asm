; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XDrawPoint
extern XNextEvent

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1
%define	LARGEUR 400	; largeur en pixels de la fenêtre
%define HAUTEUR 400	; hauteur en pixels de la fenêtre

global main

%include "dodecaedre.inc"
%define num_proj_valeur num_vertices * 2

section .bss
display_name:	resq	1
screen:		resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1

cosinus:	resd	360
sinus:	resd	360

proj: resd num_proj_valeur


section .data

event:		times	24 dq 0

x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0

angle:	dd	0
demiangle:	dd	180

format: db "Sommet %d: x' = %f y' = %f",10,0
cpt: dd 0
x: dd 0
y: dd 0
z: dd 0
xproj: dd 0.0
yproj: dd 0.0

section .text

calculs_trigo:		; cette fonction précalcule les cosinus et sinus des angles de 0 à 360°
					; et les sauvegarde dans les tableaux cosinus et sinus.
	boucle_trigo:
		fldpi	; st0=PI
		fimul dword[angle]	; st0=PI*angle
		fidiv dword[demiangle]	; st0=(PI*angle)/demi=angle en radians
		fsincos		; st0=cos(angleradian), st1=sin(angleradian)
		mov ecx,dword[angle]
		fstp dword[cosinus+ecx*DWORD] ; cosinus[REAL8*angle]=st0=cos(angle) puis st0=sin(angle)
		fstp dword[sinus+ecx*DWORD] ; sinus[REAL8*angle]=st0=sin(angle) puis st0 vide
		inc dword[angle]
		cmp dword[angle],360
		jbe boucle_trigo
ret

calculs_xprim_yprim:            ;cette fonction calcul x' et y'

        mov ebx, 0
        boucle_sommet:
                 mov [cpt],ebx
                 cmp ebx,[num_vertices]
                 jge fin

                 mov eax, ebx
                 imul eax, 12

                 mov ecx, 0
                 cmp ecx,3
                 jg boucle_sommet

                 movss xmm0, dword[objet + eax]          ; x
                 inc ecx
                 movss [x],xmm0

                 add eax,4
                 movss xmm1, dword[objet + eax]         ; y
                 inc ecx
                 movss [y],xmm1

                 add eax,4
                 movss xmm2, dword[objet + eax]         ; z
                 movss [z],xmm2

                 ;affectation de df,zoff,xoff
                 movss xmm3,dword[df]
                 movss xmm4,dword[zoff]
                 movss xmm5,dword[xoff]
                 movss xmm6,dword[yoff]

	calculs_xprim_yprim:       ;cette fonction calcul x'et y'

		  movss xmm7, xmm2
                  addss xmm7, xmm4

                  movss xmm8, xmm3
                  mulss xmm8 ,xmm0

                  divss xmm8, xmm7

                  addss xmm8, xmm5

                  movss [xproj], xmm8

	calcul_Yprim:

		  movss xmm7, xmm2
                  addss xmm7, xmm4

                  movss xmm8, xmm3
                  mulss xmm8, xmm1

                  divss xmm8, xmm7

                  addss xmm8, xmm6

                  movss [yproj], xmm8

                  ;On stocke x' et y'
                  mov eax, ebx
                  imul eax, 8

                  movss xmm9, dword[xproj]
                  movss dword[proj + eax], xmm9

                  add eax, 4
                  movss xmm10, dword[yproj]
                  movss dword[proj + eax], xmm10

                  ;Affichage
                  ;mov rdi,format
                  ;cvtss2sd xmm0, dword[xproj]
                  ;cvtss2sd xmm1, dword[yproj]
                  ;mov rsi,[cpt]
                  ;mov eax,3
                  ;call printf

                  inc ebx
                  jmp boucle_sommet

	fin:
        ret

	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
 
 call calculs_trigo	; précalcul des cosinus et sinus
 call calculs_xprim_yprim	; précalcul x' et y' 
 
    ; Sauvegarde du registre de base pour préparer les appels à printf
    push    rbp
    mov     rbp, rsp

    ; Récupère le nom du display par défaut (en passant NULL)
    xor     rdi, rdi          ; rdi = 0 (NULL)
    call    XDisplayName      ; Appel de la fonction XDisplayName
    ; Vérifie si le display est valide
    test    rax, rax          ; Teste si rax est NULL
    jz      closeDisplay      ; Si NULL, ferme le display et quitte

    ; Ouvre le display par défaut
    xor     rdi, rdi          ; rdi = 0 (NULL pour le display par défaut)
    call    XOpenDisplay      ; Appel de XOpenDisplay
    test    rax, rax          ; Vérifie si l'ouverture a réussi
    jz      closeDisplay      ; Si échec, ferme le display et quitte

    ; Stocke le display ouvert dans la variable globale display_name
    mov     [display_name], rax

    ; Restaure le cadre de pile sauvegardé
    mov     rsp, rbp
    pop     rbp

    ; Récupère la fenêtre racine (root window) du display
    mov     rdi,qword[display_name]   ; Place le display dans rdi
    mov     esi,dword[screen]         ; Place le numéro d'écran dans esi
    call XRootWindow                ; Appel de XRootWindow pour obtenir la fenêtre racine
    mov     rbx,rax               ; Stocke la root window dans rbx

    ; Création d'une fenêtre simple
    mov     rdi,qword[display_name]   ; display
    mov     rsi,rbx                   ; parent = root window
    mov     rdx,10                    ; position x de la fenêtre
    mov     rcx,10                    ; position y de la fenêtre
    mov     r8,LARGEUR                ; largeur de la fenêtre
    mov     r9,HAUTEUR           	; hauteur de la fenêtre
    push 0x000000                     ; couleur du fond (noir, 0x000000)
    push 0x00FF00                     ; couleur de fond (vert, 0x00FF00)
    push 1                          ; épaisseur du bord
    call XCreateSimpleWindow        ; Appel de XCreateSimpleWindow
    mov qword[window],rax           ; Stocke l'identifiant de la fenêtre créée dans window

    ; Sélection des événements à écouter sur la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,131077                 ; Masque d'événements (ex. StructureNotifyMask + autres)
    call XSelectInput

    ; Affichage (mapping) de la fenêtre
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    call XMapWindow

    ; Création du contexte graphique (GC) avec vérification d'erreur
    mov rdi, qword[display_name]
    test rdi, rdi                ; Vérifie que display n'est pas NULL
    jz closeDisplay

    mov rsi, qword[window]
    test rsi, rsi                ; Vérifie que window n'est pas NULL
    jz closeDisplay

    xor rdx, rdx                 ; Aucun masque particulier
    xor rcx, rcx                 ; Aucune valeur particulière
    call XCreateGC               ; Appel de XCreateGC pour créer le contexte graphique
    test rax, rax                ; Vérifie la création du GC
    jz closeDisplay              ; Si échec, quitte
    mov qword[gc], rax           ; Stocke le GC dans la variable gc
	
boucle: ; Boucle de gestion des événements
    mov     rdi, qword[display_name]
    cmp     rdi, 0              ; Vérifie que le display est toujours valide
    je      closeDisplay        ; Si non, quitte
    mov     rsi, event          ; Passe l'adresse de la structure d'événement
    call    XNextEvent          ; Attend et récupère le prochain événement

    cmp     dword[event], ConfigureNotify ; Si l'événement est ConfigureNotify (ex: redimensionnement)
    je      dessin                        ; Passe à la phase de dessin

    cmp     dword[event], KeyPress        ; Si une touche est pressée
    je      closeDisplay                  ; Quitte le programme
    jmp     boucle                        ; Sinon, recommence la boucle


;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:

;couleur de la ligne 1
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0xFF0000	; Couleur du crayon ; rouge
call XSetForeground
; coordonnées de la ligne 1
mov dword[x1],50
mov dword[y1],50
mov dword[x2],200
mov dword[y2],350
; dessin de la ligne 1
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]	; coordonnée source en x
mov r8d,dword[y1]	; coordonnée source en y
mov r9d,dword[x2]	; coordonnée destination en x
push qword[y2]		; coordonnée destination en y
call XDrawLine

;couleur de la ligne 2
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x00FF00	; Couleur du crayon ; vert
call XSetForeground
; coordonnées de la ligne 2
mov dword[x1],50
mov dword[y1],350
mov dword[x2],200
mov dword[y2],50
; dessin de la ligne 2
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]	; coordonnée source en x
mov r8d,dword[y1]	; coordonnée source en y
mov r9d,dword[x2]	; coordonnée destination en x
push qword[y2]		; coordonnée destination en y
call XDrawLine

;couleur de la ligne 3
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x00FFFF	; Couleur du crayon ; bleu
call XSetForeground
; coordonnées de la ligne 3	
mov dword[x1],275
mov dword[y1],50
mov dword[x2],275
mov dword[y2],350
; dessin de la ligne 3
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]	; coordonnée source en x
mov r8d,dword[y1]	; coordonnée source en y
mov r9d,dword[x2]	; coordonnée destination en x
push qword[y2]		; coordonnée destination en y
call XDrawLine

;couleur de la ligne 4
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0xFF00FF	; Couleur du crayon ; violet
call XSetForeground
; coordonnées de la ligne 4	
mov dword[x1],350
mov dword[y1],50
mov dword[x2],350
mov dword[y2],350
; dessin de la ligne 4
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x1]	; coordonnée source en x
mov r8d,dword[y1]	; coordonnée source en y
mov r9d,dword[x2]	; coordonnée destination en x
push qword[y2]		; coordonnée destination en y
call XDrawLine

; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################
jmp flush

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	
