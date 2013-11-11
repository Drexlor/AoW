;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]

;////////////////////////////////////////////////////////
;/// @SEE KERNEL32.DLL
;////////////////////////////////////////////////////////
__Table_Kernel32DLL_Begin:
    CloseHandle:                DD 0x0FFD97FB
    CreateToolhelp32Snapshot:   DD 0xE454DFED
    ExitProcess:                DD 0x73E2D87E
    GetCommandLineA             DD 0x36EF7370
    GetThreadContext:           DD 0x68A7C7D2
    GetTickCount:               DD 0xF791FB23
    GetProcAddress:             DD 0x7C0DFCAA
    HeapCreate:                 DD 0xB46984E7
    HeapDestroy:                DD 0xCD92833E
    HeapFree:                   DD 0x10C32616
    IsDebuggerPresent:          DD 0xA36DC676
    LoadLibraryExA:             DD 0x0753A4FC
    lstrcatA:                   DD 0xCB73463B
    lstrcpyA:                   DD 0xCB9B49FB
    lstrcmpA:                   DD 0xCB53493B
    lstrlenA:                   DD 0xDD43473B
    OutputDebugStringA:         DD 0x470D22BC
    OpenProcess:                DD 0xEFE297C0
    OpenThread:                 DD 0x58C91E6F
    Process32First:             DD 0x3249BAA7
    Process32Next:              DD 0x4776654A
    QueryPerformanceCounter:    DD 0xEA7AF15B
    ResumeThread:               DD 0x9E4A3F88
    SetThreadContext:           DD 0xE8A7C7D3
    SuspendThread:              DD 0x0E8C2CDC
    Thread32First:              DD 0xB83BB6EA
    Thread32Next:               DD 0x86FED608
    VirtualAllocEx:             DD 0x6E1A959C
    VirtualProtectEx:           DD 0x53D98756
    WriteProcessMemory:         DD 0xD83D6AA1
    WideCharToMultiByte:        DD 0xC1634AF9
__Table_Kernel32DLL_End:

;////////////////////////////////////////////////////////
;/// @SEE NTDLL.DLL
;////////////////////////////////////////////////////////
__Table_NTDLL_Begin:
    RtlAllocateHeap:            DD 0x3E192526
__Table_NTDLL_End:

;////////////////////////////////////////////////////////
;///!< Heap handler
;////////////////////////////////////////////////////////
__pHeap:                        DD 0x90909090

;////////////////////////////////////////////////////////
;/// \brief Deallocates memory from the local heap
;///
;/// \param length The length of memory
;////////////////////////////////////////////////////////
%MACRO AllocateMemory 1
    PUSH %1
    PUSH 0x00000008
    PUSH DWORD [__pHeap]
    CALL DWORD [RtlAllocateHeap]
%ENDMACRO

;////////////////////////////////////////////////////////
;/// \brief Deallocates memory from the local heap
;///
;/// \param pointer The pointer to the allocated memory
;////////////////////////////////////////////////////////
%MACRO DeallocateMemory 1
    PUSH %1
    PUSH 0x00000000
    PUSH DWORD [__pHeap]
    CALL DWORD [RtlAllocateHeap]
%ENDMACRO

;////////////////////////////////////////////////////////
;/// \brief Initialize Heap Enviroment
;////////////////////////////////////////////////////////
InitializeEnviroment:
    PUSH EBP
    MOV  EBP, ESP

    ;////////////////////////////////////////////////////
    ;/// Creates heap for our local application
    ;////////////////////////////////////////////////////
    PUSH 0x00020000                    ;// EXPAND:  1MB
    PUSH 0x00001000                    ;// INITIAL: 4KB
    PUSH 0x00040000                    ;// HEAP_CREATE_ENABLE_EXECUTE
    CALL DWORD [HeapCreate]            
    MOV  DWORD [__pHeap], EAX

    MOV  ESP, EBP
    POP  EBP
    RET

;////////////////////////////////////////////////////////
;/// \brief Initialize WinAPI Enviroment
;////////////////////////////////////////////////////////
InitializeWinAPI:
    PUSH EBP
    MOV  EBP, ESP

    ;////////////////////////////////////////////////////
    ;/// Find kernel32.dll
    ;////////////////////////////////////////////////////
    PUSH 0x8FECD63F
    CALL GetModuleHandle

    ;////////////////////////////////////////////////////
    ;/// Populates all function needed from Kernel32.dll
    ;////////////////////////////////////////////////////
    PUSH (__Table_Kernel32DLL_End - __Table_Kernel32DLL_Begin) / 0x4
    PUSH (__Table_Kernel32DLL_Begin - 0x4)
    PUSH EAX
    CALL GetFunctionTable

    ;////////////////////////////////////////////////////
    ;/// Find NTDLL.dll
    ;////////////////////////////////////////////////////
    PUSH 0xCEF6E822
    CALL GetModuleHandle

    ;////////////////////////////////////////////////////
    ;/// Populates all function needed from NTDLL.dll
    ;////////////////////////////////////////////////////
    PUSH (__Table_NTDLL_End - __Table_NTDLL_Begin) / 0x4
    PUSH (__Table_NTDLL_Begin - 0x4)
    PUSH EAX
    CALL GetFunctionTable

    MOV  ESP, EBP
    POP  EBP
    RET

;////////////////////////////////////////////////////
;/// \brief Convert BSTR to CString
;///
;/// \param unicode The BSTR value
;///
;/// \return A Newly allocated CString
;////////////////////////////////////////////////////
ConvertUnicodeToString:
    PUSH EBP
    MOV  EBP, ESP
    SUB  ESP, 0x04

    ;// Get the size of the UNICODE
    PUSH 0x00
    PUSH 0x00
    PUSH 0x00
    PUSH 0x00
    PUSH 0xFFFFFFFF
    PUSH DWORD [EBP + 0x08]
    PUSH 0x00
    PUSH 0x00
    CALL DWORD [WideCharToMultiByte]
    MOV  DWORD [EBP - 0x04], EAX
    
    ;// Allocate memory for the UNICODE
    AllocateMemory EAX
    PUSH EAX

    ;// Convert UNICODE to CString
    PUSH 0x00
    PUSH 0x00
    PUSH DWORD [EBP - 0x04]
    PUSH EAX
    PUSH 0xFFFFFFFF
    PUSH DWORD [EBP + 0x08]
    PUSH 0x00
    PUSH 0x00
    CALL DWORD [WideCharToMultiByte]

    POP  EAX

    MOV  ESP, EBP
    POP  EBP
    RET  0x04

;////////////////////////////////////////////////////
;/// \brief Return the next command line
;///
;/// \param string The string where to look at
;///
;/// \return The CString of the command
;////////////////////////////////////////////////////
ParseCommandLine:
    PUSH EBP
    MOV  EBP, ESP

    CALL DWORD [GetCommandLineA]
    MOV  ESI, EAX

    PUSH ESI
    CALL DWORD [lstrlenA]
    ADD  ESI, EAX
    XOR  EBX, EBX
    
.GetNextCommandLine_Compare:
    CMP  BYTE [ESI], ' '
    JE   .GetNextCommandLine_Found_Space

    CMP  BYTE [ESI], 0x22
    JNE  .GetNextCommandLine_Continue

.GetNextCommandLine_Found_Delimiter:
    TEST EBX, EBX
    JNZ  .GetNextCommandLine_Found_String
    INC  EBX
    MOV  BYTE [ESI], 0x00

.GetNextCommandLine_Continue:
    DEC  ESI
    DEC  EAX
    TEST EAX, EAX
    JNZ  .GetNextCommandLine_Compare

.GetNextCommandLine_Found_Space:
    TEST EBX, EBX
    JNZ  .GetNextCommandLine_Continue

.GetNextCommandLine_Found_String:
    MOV  BYTE [ESI], 0x00
    INC  ESI
    MOV  EAX, ESI

    MOV  ESP, EBP
    POP  EBP
    RET  0x04

;////////////////////////////////////////////////////////
;/// \brief Get the address of a procedure
;///
;/// \param module The module of the procedure
;/// \param list   The list of all procedure
;/// \param length The length of all procedure
;////////////////////////////////////////////////////////
GetFunctionTable:
    PUSH EBP
    MOV  EBP, ESP

    MOV  EBX, DWORD [EBP + 0x08]
    MOV  EAX, DWORD [EBX + 0x3C]       ;// Get the export table rva
    LEA  ESI, [EBX + EAX + 0x78]
    LODSD
    PUSH DWORD [ESI]                   ;// [+1]

    ADD  EAX, EBX
    PUSH EAX                           ;// [+2]              
    MOV  ECX, DWORD [EAX + 0x18]       ;// Extract the number of exported
    MOV  EDX, DWORD [EAX + 0x20]       ;// Export name address table rva
    ADD  EDX, EBX                      ;// EDX = export name address table
    DEC  ECX

.GetFunctionTable_Calculate:
    MOV  ESI, DWORD [EDX + ECX * 0x04] ;// Get RVA of the export name
    ADD  ESI, EBX                      ;// Calculate VA
    XOR  EDI, EDI
    PUSH ECX                           ;// [+3]

.GetFunctionTable_Generate:
    XOR  EAX, EAX
    LODSB
    CMP  AH, AL
    JE   .GetFunctionTable_Compare
    ROR  EDI, 0x0D
    ADD  EDI, EAX
    JMP  .GetFunctionTable_Generate

.GetFunctionTable_Compare:
    MOV  ECX, DWORD [EBP + 0x10]
    MOV  ESI, DWORD [EBP + 0x0C]

.GetFunctionTable_Compare_Value:
    CMP  EDI, DWORD [ESI + ECX * 0x04] ;// The export Table
    JNE  .GetFunctionTable_Compare_Next

    PUSH ECX                           ;// [+4]
    PUSH EDX                           ;// [+5]

    MOV  ECX, DWORD [EBP - 0x0C]       ;// [=3]
    MOV  EDI, DWORD [EBP - 0x08]       ;// [=2]
    MOV  EDX, DWORD [EDI + 0x24]       ;// Extract the rva of the ordinals
    ADD  EDX, EBX                      ;// Make it VA
    MOV  AX,  WORD [EDX + ECX * 0x02]  ;// Extract the current symbol
    MOV  EDX, DWORD [EDI + 0x1C]       ;// Extract the rva of the address
    ADD  EDX, EBX                      ;// Make it VA
    MOV  EAX,DWORD [EDX + EAX * 0x04]  ;// Get the rva of the exported 
    ADD  EAX, EBX                      ;// Make it VA

    POP  EDX                           ;// [+4]
    POP  ECX                           ;// [+3]
    MOV  DWORD [ESI + ECX * 0x04], EAX               
    JMP  .GetFunctionTable_Continue

.GetFunctionTable_Compare_Next:
    LOOP .GetFunctionTable_Compare_Value

.GetFunctionTable_Continue:
    POP  ECX                           ;// [+2]
    LOOP .GetFunctionTable_Calculate

    MOV  ESP, EBP 
    POP  EBP
    RET  0x04

;////////////////////////////////////////////////////////
;/// \brief Gets the module handle of a library [+]
;///
;/// \param id The identifier of the module
;///
;/// \return The handle of the module 
;////////////////////////////////////////////////////////
GetModuleHandle:
    PUSH EBP
    MOV  EBP, ESP

    MOV  EBX, DWORD [FS:0x30]          ;// Process enviroment block
    MOV  EBX, DWORD [EBX + 0x0C]       ;// Peb->Ldr
    MOV  EBX, DWORD [EBX + 0x14]       ;// Peb->Ldr.InMemoryOrder.Flink 1st

.GetModuleHandle_Loop:
    TEST EBX, EBX
    JZ   .GetModuleHandle_Clean

    MOV  ESI, DWORD [EBX + 0x28]       ;// Module name (UNICODE)
    MOVZX ECX, WORD [EBX + 0x26]
    XOR  EDI, EDI

.GetModuleHandle_Generate:
    XOR  EAX, EAX
    LODSB
    TEST AL, AL
    JZ   .GetModuleHandle_Generate_Continue

    ROR  EDI, 0x0D
    ADD  EDI, EAX

.GetModuleHandle_Generate_Continue:
    LOOP .GetModuleHandle_Generate

    CMP  EDI, DWORD [EBP + 0x08]
    JE   .GetModuleHandle_Found

    MOV  EBX, DWORD [EBX + 0x00]       ;// Walk to the next module
    JMP  .GetModuleHandle_Loop

.GetModuleHandle_Found:
    MOV  EAX, DWORD [EBX + 0x10]

.GetModuleHandle_Clean:
    MOV  ESP, EBP
    POP  EBP
    RET  0x04

;////////////////////////////////////////////////////////
;/// \brief Copy memory from source to destination
;///
;/// \param source      The source of the memory
;/// \param destination The destination of the memory
;/// \param size        The length of the memory
;////////////////////////////////////////////////////////
CopyMemory:
    PUSH EBP
    MOV  EBP, ESP

    PUSH ESI
    PUSH EDI
    PUSH ECX

    MOV  ESI, DWORD [EBP + 0x08]
    MOV  EDI, DWORD [EBP + 0x0C]
    MOV  ECX, DWORD [EBP + 0x10]
    REP  MOVSB

    POP  ECX
    POP  EDI
    POP  ESI

    MOV  ESP, EBP
    POP  EBP
    RET  0x0C
