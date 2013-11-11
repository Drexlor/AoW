;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]

    ;////////////////////////////////////////////////////
    ;/// Define all modules includes
    ;////////////////////////////////////////////////////
    %include 'src/foundation/Foundation_Module_Speedhack.asm'

;////////////////////////////////////////////////////
;/// \brief Initialize foundation enviroment
;////////////////////////////////////////////////////
InitializeFoundation:
    PUSH EBP
    MOV  EBP, ESP
    
    ;////////////////////////////////////////////////////
    ;/// Initialize SpeedHACK module
    ;////////////////////////////////////////////////////
    CALL InitializeSpeedhackModule

    ;//////////// MPAO => Logger de paquetes sin encriptacion :) 
    PUSH MyFunction
    PUSH 0x005878A0
    CALL WriteDetour


    MOV  ESP, EBP
    POP  EBP
    RET

MyFunction:
    PUSH EBP
    MOV  EBP, ESP
    SUB  ESP, 0x04

    ;// La encriptacion me la paso por los huevos :D
    PUSH DWORD [EBP + 0x08]
    CALL ConvertUnicodeToString
    MOV  ESI, EAX
    PUSH EAX
    CALL DWORD [OutputDebugStringA] 
    DeallocateMemory ESI

    PUSH 0x005878A0
    CALL GetDetour
    PUSH DWORD [EBP + 0x0C]
    PUSH DWORD [EBP + 0x08]
    CALL DWORD [EAX + 0x04]

    MOV  ESP, EBP
    POP  EBP
    RET  0x08