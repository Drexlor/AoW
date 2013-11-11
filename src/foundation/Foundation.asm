;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]


;////////////////////////////////////////////////////
;/// \brief Initialize foundation enviroment
;////////////////////////////////////////////////////
InitializeFoundation:
    PUSH EBP
    MOV  EBP, ESP

    JMP  .Continue
.Name:
    DB   'user32.dll', 0

.MessageTitle:
    DB   'AoW Revolution v2.0', 0
.Message:
    DB   'The true power of AoW', 0
.Function:
    DB   'MessageBoxA', 0

.Continue:

    ;// <Code of the user goes here> // 
    PUSH 0x00000000
    PUSH 0x00000000
    PUSH .Name
    CALL DWORD [LoadLibraryExA]

    PUSH .Function
    PUSH EAX
    CALL DWORD [GetProcAddress]

    PUSH 0
    PUSH .MessageTitle
    PUSH .Message
    PUSH 0
    CALL EAX

    MOV  ESP, EBP
    POP  EBP
    RET