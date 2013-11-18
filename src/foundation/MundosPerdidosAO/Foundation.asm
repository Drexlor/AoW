;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]

;////////////////////////////////////////////////////
;///!< The original callback
;////////////////////////////////////////////////////
__fRealSendData          DD 0x00000000
__fSendDataMask          DB 0x89, 0x5D, 0xDC 
                         DB 0x89, 0x5D, 0xD8
                         DB 0x89, 0x5D, 0xD4
                         DB 0x89, 0x5D, 0xD0
                         DB 0x89, 0x5D, 0xCC
                         DB 0x89, 0x5D, 0xC8
                         DB 0x89, 0x5D, 0xC4
                         DB 0x89, 0x5D, 0xC0
                         DB 0x89, 0x5D, 0xB0
                         DB 0x89, 0x5D, 0xA0
                         DB 0x89, 0x5D, 0x90
                         DB 0x89, 0x5D, 0x80                         
                         DB 0x00
__fSendDataPattern       DB "xxx" 
                         DB "xxx" 
                         DB "xxx"
                         DB "xxx"
                         DB "xxx"
                         DB "xxx"
                         DB "xxx" 
                         DB "xxx" 
                         DB "xxx"
                         DB "xxx"
                         DB "xxx"
                         DB "xxx"
                         DB 0x00

;////////////////////////////////////////////////////
;/// \brief Initialize foundation enviroment
;////////////////////////////////////////////////////
InitializeFoundation:
    PUSH EBP
    MOV  EBP, ESP
    
    ;////////////////////////////////////////////////
    ;/// Redirect "SendData" for our function
    ;////////////////////////////////////////////////
    PUSH __fSendDataMask
    PUSH __fSendDataPattern
    PUSH 0x00200000
    PUSH 0x00500000
    CALL FindMemory
    
    PUSH EAX
    CALL BacktraceFunction

    PUSH BridgeSendData
    PUSH EAX
    CALL WriteDetour
    MOV  DWORD [__fRealSendData], EAX
    

    ;////////////////////////////////////////////////
    ;/// Redirect "HandleData" for our function
    ;////////////////////////////////////////////////
    ; <TODO>

    MOV  ESP, EBP
    POP  EBP
    RET

;////////////////////////////////////////////////////
;/// \brief Send data to the server
;///
;/// \param ????
;/// \param ????
;////////////////////////////////////////////////////
BridgeSendData:
    PUSH EBP
    MOV  EBP, ESP

    ;// Execute our dispatcher
    PUSH DWORD [EBP + 0x0C]
    CALL HandleOutgoingData

    ;// Execute the real callback
    PUSH DWORD [EBP + 0x0C]
    PUSH DWORD [EBP + 0x08]
    CALL DWORD [__fRealSendData] 

    MOV  ESP, EBP
    POP  EBP
    RET  0x08