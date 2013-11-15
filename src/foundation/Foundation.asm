;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]

    ;////////////////////////////////////////////////////
    ;/// Define all modules includes
    ;////////////////////////////////////////////////////
    %include 'src/foundation/Foundation_Module_Speedhack.asm'

__oldFunction DD 0

;////////////////////////////////////////////////////
;/// \brief Initialize foundation enviroment
;////////////////////////////////////////////////////
InitializeFoundation:
    PUSH EBP
    MOV  EBP, ESP
    
    ;////////////////////////////////////////////////////
    ;/// Initialize SpeedHACK module
    ;////////////////////////////////////////////////////
    ;CALL InitializeSpeedhackModule

    ;//////////// MPAO => Logger de paquetes sin encriptacion :) 
    PUSH MyFunction
    PUSH 0x005878A0
    CALL WriteDetour

    PUSH 0x005878A0
    CALL GetDetour
    MOV  EAX, DWORD [EAX + 0x04]
    MOV  DWORD [__oldFunction], EAX

    MOV  ESP, EBP
    POP  EBP
    RET

MyFunction:
    PUSH EBP
    MOV  EBP, ESP
    SUB  ESP, 0x04

    PUSH ESI

    PUSH DWORD [EBP + 0x08]
    CALL ConvertUnicodeToString
    MOV  ESI, EAX

    CMP  WORD [ESI], 0x3737
    JE   .TimeFor1000Magic

    ;// La encriptacion me la paso por los huevos :D
    ;PUSH ESI
    ;MOV  ESI, EAX
    ;PUSH EAX
    ;CALL DWORD [OutputDebugStringA] 

    PUSH DWORD [EBP + 0x0C]
    PUSH DWORD [EBP + 0x08]
    CALL DWORD [__oldFunction]
    JMP  .Finish

.TimeFor1000Magic:
    PUSH DWORD [EBP + 0x0C]
    PUSH DWORD [EBP + 0x08]
    CALL DWORD [__oldFunction]
    PUSH DWORD [EBP + 0x0C]
    PUSH DWORD [EBP + 0x08]
    CALL DWORD [__oldFunction]
    PUSH DWORD [EBP + 0x0C]
    PUSH DWORD [EBP + 0x08]
    CALL DWORD [__oldFunction]
    PUSH DWORD [EBP + 0x0C]
    PUSH DWORD [EBP + 0x08]
    CALL DWORD [__oldFunction]
    PUSH DWORD [EBP + 0x0C]
    PUSH DWORD [EBP + 0x08]
    CALL DWORD [__oldFunction]
.Finish:
    DeallocateMemory ESI

    POP  ESI
    
    MOV  ESP, EBP
    POP  EBP
    RET  0x08