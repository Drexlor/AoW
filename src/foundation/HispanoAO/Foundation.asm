;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]

;////////////////////////////////////////////////////
;///!< The original callback
;////////////////////////////////////////////////////
__fHandleDataMask        DB 0x38, 0x45, 0x98
                         DB 0x75, 0x11
                         DB 0xC7, 0x45, 0xFC, 0x05, 0x90, 0x90, 0x90
                         DB 0xE8, 0x90, 0x90, 0x90, 0x90
                         DB 0xE9, 0x90, 0x90, 0x90, 0x90
                         DB 0xC7, 0x45, 0xFC, 0x06, 0x90, 0x90, 0x90
                         DB 0xB9, 0x90, 0x90, 0x90, 0x90
                         DB 0xFF, 0x15, 0x90, 0x90, 0x90
                         DB 0x38, 0x45, 0x98
                         DB 0x75, 0x11
                         DB 0xC7, 0x45, 0xFC, 0x07, 0x90, 0x90, 0x90
                         DB 0xE8, 0x90, 0x90, 0x90, 0x90
                         DB 0xE9, 0x90, 0x90, 0x90, 0x90
                         DB 0x00
__fHandleDataPattern     DB "xxx" 
                         DB "xx" 
                         DB "xxxx???"
                         DB "x????"
                         DB "x????"
                         DB "xxxx???"
                         DB "x????" 
                         DB "xx???" 
                         DB "xxx"
                         DB "xx"
                         DB "xxxx???"
                         DB "x????"
                         DB 0x00
__fHandleDataCallMask    DB 0xE8, 0x90, 0x90, 0x90, 0x90, 0x00
__fHandleDataCallPattern DB "xxxxx", 0x00
__fHandleDataCallReturn  DD 0x00000000

;////////////////////////////////////////////////////
;/// \brief Initialize foundation enviroment
;////////////////////////////////////////////////////
InitializeFoundation:
    PUSH EBP
    MOV  EBP, ESP
    
    ;////////////////////////////////////////////////
    ;/// Redirect "SendData" for our function
    ;////////////////////////////////////////////////
    ; <TODO>
    
    ;////////////////////////////////////////////////
    ;/// Replace Call HandleIncomingData
    ;////////////////////////////////////////////////
    PUSH __fHandleDataMask
    PUSH __fHandleDataPattern
    PUSH 0x00200000
    PUSH 0x00500000
    CALL FindMemory
    
    PUSH EAX
    CALL BacktraceFunction

    MOV  DWORD [__fHandleDataCallMask + 0x01], EAX
    
    PUSH __fHandleDataCallMask
    PUSH __fHandleDataCallPattern
    PUSH 0x00200000
    PUSH 0x00500000
    CALL FindMemory

    PUSH MyHandleDataRedirect
    PUSH EAX
    CALL WriteDetour
    MOV  DWORD [__fHandleDataCallReturn], EAX

    MOV  ESP, EBP
    POP  EBP
    RET
    
;////////////////////////////////////////////////////
;/// \brief Handle code inside Socket1_Read(.., ..)
;////////////////////////////////////////////////////
MyHandleDataRedirect:
    PUSH DWORD [EBP - 0x0C]
    CALL HandleIncommingData
    JMP  __fHandleDataCallReturn