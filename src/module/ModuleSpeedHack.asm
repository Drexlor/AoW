;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]

;////////////////////////////////////////////////////
;///!< The multiply of the speedhack
;////////////////////////////////////////////////////
__dwMultiplier                  DB 0x50
__dwRealGetTickCount            DD 0x00000000
__dwFakeGetTickCount            DD 0x00000000
__dwRealQueryPerfomanceCounter  DD 0x00000000
__dwFakeQueryPerfomanceCounter  DD 0x00000000
__fRealGetTickCount             DD 0x00000000
__fRealQueryPerfomanceCounter   DD 0x00000000

;////////////////////////////////////////////////////
;/// \brief Initialize speedhack module
;////////////////////////////////////////////////////
InitializeSpeedhackModule:
    PUSH EBP
    MOV  EBP, ESP
    
    ;////////////////////////////////////////////////
    ;/// Redirect "GetTickCount" for speedhack
    ;////////////////////////////////////////////////
    PUSH MyGetTickCount
    PUSH DWORD [GetTickCount]
    CALL WriteDetour
    MOV  DWORD [__fRealGetTickCount], EAX

    ;////////////////////////////////////////////////
    ;/// Redirect "QueryPerformanceCounter" for speedhack
    ;////////////////////////////////////////////////
    PUSH MyQueryPerformanceCounter
    PUSH DWORD [QueryPerformanceCounter]
    CALL WriteDetour
    MOV  DWORD [__fRealQueryPerfomanceCounter], EAX

    MOV  ESP, EBP
    POP  EBP
    RET

;////////////////////////////////////////////////////
;/// \brief Redirect function of "GetTickCount"
;///
;/// \return The number of ticks
;////////////////////////////////////////////////////
MyGetTickCount:
    PUSH EBP
    MOV  EBP, ESP
    SUB  ESP, 0x04

    ;////////////////////////////////////////////////
    ;/// Call real function
    ;////////////////////////////////////////////////
    CALL DWORD [__fRealGetTickCount]

    ;////////////////////////////////////////////////
    ;/// Check if we can hook it NOW
    ;////////////////////////////////////////////////
    CMP  DWORD [__dwFakeGetTickCount], 0x00000000
    JNZ  .MyGetTickCount_Continue

    MOV  DWORD [__dwFakeGetTickCount], EAX
    JMP  .MyGetTickCount_Finish

.MyGetTickCount_Continue:
    ;////////////////////////////////////////////////
    ;/// Calculate the distance real value
    ;////////////////////////////////////////////////
    SUB  EAX, DWORD [__dwRealGetTickCount]
    MOV  DWORD [EBP - 0x04], EAX
    MUL  BYTE [__dwMultiplier]

    ADD  EAX, DWORD [__dwFakeGetTickCount]
    MOV  DWORD [__dwFakeGetTickCount], EAX
    PUSH EAX

    MOV  EAX, DWORD [EBP - 0x04]
    ADD  DWORD [__dwRealGetTickCount], EAX
    POP  EAX

.MyGetTickCount_Finish:
    MOV  ESP, EBP
    POP  EBP
    RET

;////////////////////////////////////////////////////
;/// \brief Redirect function of "GetTickCount"
;///
;/// \return The number of ticks
;////////////////////////////////////////////////////
MyQueryPerformanceCounter:
    PUSH EBP
    MOV  EBP, ESP
    SUB  ESP, 0x04

    PUSH EBX

    ;////////////////////////////////////////////////
    ;/// Call real function
    ;////////////////////////////////////////////////
    PUSH DWORD [EBP + 0x08]
    CALL DWORD [__fRealQueryPerfomanceCounter]
    MOV  EBX, DWORD [EBP + 0x08]

    ;////////////////////////////////////////////////
    ;/// Check if we can hook it NOW
    ;////////////////////////////////////////////////
    CMP  DWORD [__dwFakeQueryPerfomanceCounter], 0x00000000
    JNZ  .MyQueryPerformanceCounter_Continue

    MOV  EAX, DWORD [EBX + 0x00]
    MOV  DWORD [__dwFakeQueryPerfomanceCounter], EAX
    JMP  .MyQueryPerformanceCounter_Finish

.MyQueryPerformanceCounter_Continue:
    ;////////////////////////////////////////////////
    ;/// Calculate the distance real value
    ;////////////////////////////////////////////////
    MOV  EAX, DWORD [EBX + 0x00]
    SUB  EAX, DWORD [__dwRealQueryPerfomanceCounter]
    MOV  DWORD [EBP - 0x04], EAX
    MUL  BYTE [__dwMultiplier]

    ADD  EAX, DWORD [__dwFakeQueryPerfomanceCounter]
    MOV  DWORD [__dwFakeQueryPerfomanceCounter], EAX
    MOV  DWORD [EBX + 0x00], EAX
    
    MOV  EAX, DWORD [EBP - 0x04]
    ADD  DWORD [__dwRealQueryPerfomanceCounter], EAX
    MOV  EAX, 0x01

.MyQueryPerformanceCounter_Finish:
    POP  EBX

    MOV  ESP, EBP
    POP  EBP
    RET  0x04