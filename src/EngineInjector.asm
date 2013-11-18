;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]

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
;/// \brief Return a thread of the given process
;///
;/// \param identifier The id of the process
;///
;/// \return The id of the thread
;////////////////////////////////////////////////////////
GetAvailableThreadID:
    PUSH EBP
    MOV  EBP, ESP
    SUB  ESP, 0x30

    PUSH 0x00
    PUSH 0x00000004
    CALL DWORD [CreateToolhelp32Snapshot]

    CMP  EAX, 0xFFFFFFFF
    JE   .GetAvailableThreadID_Finish

    MOV  DWORD [EBP - 0x04], EAX
    MOV  DWORD [EBP - 0x30], 0x1C
    MOV  DWORD [EBP - 0x0C], 0x00

    LEA  EAX, [EBP - 0x30]
    PUSH EAX
    PUSH DWORD [EBP - 0x04]
    CALL DWORD [Thread32First]

    TEST EAX, EAX
    JZ   .GetAvailableThreadID_Close

.GetAvailableThreadID_Loop:
    MOV  EAX, DWORD [EBP - 0x24]
    CMP  EAX, DWORD [EBP + 0x08]
    JE   .GetAvailableThreadID_Found

    LEA  EAX, [EBP - 0x30]
    PUSH EAX
    PUSH DWORD [EBP - 0x04]
    CALL DWORD [Thread32Next]

    TEST EAX, EAX
    JNZ  .GetAvailableThreadID_Loop
    JZ   .GetAvailableThreadID_Close

.GetAvailableThreadID_Found:
    PUSH DWORD [EBP - 0x28]
    POP  DWORD [EBP - 0x0C]

.GetAvailableThreadID_Close:
    PUSH DWORD [EBP - 0x04]
    CALL DWORD [CloseHandle]

.GetAvailableThreadID_Finish:
    MOV  EAX, DWORD [EBP - 0x0C]

    MOV  ESP, EBP
    POP  EBP
    RET  0x04

;////////////////////////////////////////////////////////
;/// \brief Return the process id given its name
;///
;/// \param name The name of the process
;///
;/// \return The id of the process
;////////////////////////////////////////////////////////
GetProcessID:
    PUSH EBP
    MOV  EBP, ESP
    SUB  ESP, 0x0134

    PUSH 0x00
    PUSH 0x00000002
    CALL DWORD [CreateToolhelp32Snapshot]

    CMP  EAX, 0xFFFFFFFF
    JE   .GetProcessID_Finish

    MOV  DWORD [EBP - 0x04], EAX
    MOV  DWORD [EBP - 0x0130], 0x0128
    MOV  DWORD [EBP - 0x0134], 0x0000

    LEA  EAX, [EBP - 0x0130]
    PUSH EAX
    PUSH DWORD [EBP - 0x04]
    CALL DWORD [Process32First]

    TEST EAX, EAX
    JZ   .GetProcessID_Close

.GetProcessID_Loop:
    LEA  EAX, [EBP - 0x010C]

    PUSH DWORD [EBP + 0x08]
    PUSH EAX
    CALL DWORD [lstrcmpA]
    TEST EAX, EAX
    JZ   .GetProcessID_Found

    LEA  EAX, [EBP - 0x0130]
    PUSH EAX
    PUSH DWORD [EBP - 0x04]
    CALL DWORD [Process32Next]

    TEST EAX, EAX
    JNZ  .GetProcessID_Loop
    JZ   .GetProcessID_Close

.GetProcessID_Found:
    PUSH DWORD [EBP - 0x0128]
    POP  DWORD [EBP - 0x0134]

.GetProcessID_Close:
    PUSH DWORD [EBP - 0x04]
    CALL DWORD [CloseHandle]

.GetProcessID_Finish:
    MOV  EAX, DWORD [EBP - 0x0134]

    MOV  ESP, EBP
    POP  EBP
    RET  0x04

;////////////////////////////////////////////////////////
;/// \brief Walk though the opcode table and fix
;///        reallocation table / jmp / call to memory
;///
;/// NOTE: NEED REWORK FOR FUCK SAKE!!!!!!!!!!!!!!!!!!!!!
;///
;/// \param oldAddress The old address
;/// \param address    The new address for the opcodes
;/// \param opcodes    The array of opcodes
;/// \param length     The length of the opcode array
;////////////////////////////////////////////////////////
ReallocateOpcode:
    PUSH EBP
    MOV  EBP, ESP

    PUSH EBX
    PUSH ECX
    PUSH ESI

    MOV  ESI, DWORD [EBP + 0x10]
    MOV  ECX, DWORD [EBP + 0x14]
    MOV  EBX, DWORD [EBP + 0x08]

.ReallocateOpcode_Loop:
    MOV  AX, WORD [ESI + 0x00]
    INC  ESI
    DEC  ECX

.ReallocateOpcode_I1:
    ;// MOV DWORD PTR SS:[...]
    CMP  AL, 0xA3
    JE   .ReallocateOpcode_Compare

    ;// MOV EAX, DWORD PTR DS:[...]
    CMP  AL, 0xA1
    JE   .ReallocateOpcode_Compare

    ;// PUSH ...
    CMP  AL, 0x68
    JE   .ReallocateOpcode_Compare

    ;// MOV ESI, DWORD PTR DS:[...]
    CMP  AX, 0x358B
    JE   .ReallocateOpcode_I2

    ;// POP DWORD PTR SS:[...]
    CMP  AX, 0x058F
    JE   .ReallocateOpcode_I2

    ;// PUSH DWORD PTR SS:[...]
    CMP  AX, 0x35FF
    JE   .ReallocateOpcode_I2

    ;// CALL DWORD PTR SS:[...]
    CMP  AX, 0x15FF
    JE   .ReallocateOpcode_I2

    ;// MUL BYTE PTR DS:[...]
    CMP  AX, 0x25F6
    JE   .ReallocateOpcode_I2

    ;// CMP DWORD PTR DS:[...]
    CMP  AX, 0x3D83
    JE   .ReallocateOpcode_I2

    ;// MOV BL, BYTE PTR DS:[...]
    CMP  AX, 0x1D8A
    JE   .ReallocateOpcode_I2

    CMP  AX, 0x052B
    JE   .ReallocateOpcode_I2

    CMP  AX, 0x0503
    JE   .ReallocateOpcode_I2
    
    CMP  AX, 0x1D2B
    JE   .ReallocateOpcode_I2

    CMP  AX, 0x1D03
    JE   .ReallocateOpcode_I2

    CMP  AX, 0x1D89
    JE   .ReallocateOpcode_I2
    
    CMP  AX, 0x0501
    JE   .ReallocateOpcode_I2
    
    CMP  ECX, 0x00
    JG   .ReallocateOpcode_Loop

.ReallocateOpcode_I2:
    DEC  ECX
    INC  ESI

.ReallocateOpcode_Compare:
    CMP  EBX, DWORD [ESI + 0x00]
    JG   .ReallocateOpcode_Continue

    MOV  EAX, EBX
    ADD  EAX, DWORD [EBP + 0x14]
    CMP  EAX, DWORD [ESI + 0x00]
    JLE  .ReallocateOpcode_Continue

    MOV  EAX, DWORD [ESI + 0x00]
    SUB  EAX, EBX
    ADD  EAX, DWORD [EBP + 0x0C]
    MOV  DWORD [ESI + 0x00], EAX

.ReallocateOpcode_Continue:
    ADD  ESI, 0x04
    SUB  ECX, 0x04

    CMP  ECX, 0x00
    JG   .ReallocateOpcode_Loop

.ReallocateOpcode_Exit:
    POP  ESI
    POP  ECX
    POP  EBX

    MOV  ESP, EBP
    POP  EBP
    RET  0x10

;////////////////////////////////////////////////////////
;/// \brief Inject and execute code into remote process
;///
;/// \param process   The name of the process
;/// \param entry     The entry point of the code injected
;/// \param code      The start of the code to execute
;/// \param length    The length of the code
;////////////////////////////////////////////////////////
ExecuteCodeOnApplication:
    PUSH EBP
    MOV  EBP, ESP
    SUB  ESP, 0x02F4

.ExecuteCodeOnApplication_FindProcess:
    PUSH DWORD [EBP + 0x08]
    CALL GetProcessID
    
    TEST EAX, EAX
    JZ   .ExecuteCodeOnApplication_Exit
    PUSH EAX

.ExecuteCodeOnApplication_OpenProcess:
    PUSH EAX
    PUSH 0xFFFFFFFF
    PUSH (0x0008 | 0x0020)
    CALL DWORD [OpenProcess]

    TEST EAX, EAX
    JZ   .ExecuteCodeOnApplication_Exit

    MOV  DWORD [EBP - 0x04], EAX
    JMP  .ExecuteCodeOnApplication_AllocateRemote

.ExecuteCodeOnApplication_Opcode:
    DB   0x68, 0x00, 0x00, 0x00, 0x00
    DB   0x9C
    DB   0x60
    DB   0xE8, 0x00, 0x00, 0x00, 0x00
    DB   0x61
    DB   0x9D
    DB   0xC3

.ExecuteCodeOnApplication_AllocateRemote:
    PUSH 0x40
    PUSH 0x00001000
    PUSH DWORD [EBP + 0x14]
    PUSH 0x00000000
    PUSH DWORD [EBP - 0x04]
    CALL DWORD [VirtualAllocEx]
    MOV  DWORD [EBP - 0x08], EAX

.ExecuteCodeOnApplication_FixOpcodeReallocation:
    PUSH DWORD [EBP + 0x14]
    PUSH 0x0040
    CALL DWORD [LocalAlloc]
    MOV  DWORD [EBP - 0x0C], EAX

    ;// Copy the code opcodes into the new memory
    PUSH DWORD [EBP + 0x14]
    PUSH EAX
    PUSH DWORD [EBP + 0x10]
    CALL CopyMemory

    ;// Fix reallocation opcodes
    PUSH DWORD [EBP + 0x14]
    PUSH DWORD [EBP - 0x0C]
    PUSH DWORD [EBP - 0x08]
    PUSH DWORD [EBP + 0x10]
    CALL ReallocateOpcode

    ;// Write it to the remote process
    PUSH 0x00000000
    PUSH DWORD [EBP + 0x14]
    PUSH DWORD [EBP - 0x0C]
    PUSH DWORD [EBP - 0x08]
    PUSH DWORD [EBP - 0x04]
    CALL DWORD [WriteProcessMemory]

    ;// Free the memory allocated
    PUSH DWORD [EBP - 0x0C]
    CALL DWORD [LocalFree]
    
.ExecuteCodeOnApplication_PrepareRemoteThread:
    CALL GetAvailableThreadID

    ;// Open a handle to the thread
    PUSH EAX
    PUSH 0x00000000
    PUSH (0x0008 | 0x0010 | 0x0002)
    CALL DWORD [OpenThread]
    MOV  DWORD [EBP - 0x10], EAX

    ;// Suspend the thread for running
    PUSH EAX
    CALL DWORD [SuspendThread]

    ;// CONTEXT_CONTROL = True
    MOV  DWORD [EBP - 0x02F0], (0x10000 | 0x01)

    ;// Retrieve Thread context
    LEA  EAX, [EBP - 0x02F0]
    PUSH EAX
    PUSH DWORD [EBP - 0x10]
    CALL DWORD [GetThreadContext]

.ExecuteCodeOnApplication_PatchOpcode:
    PUSH 0x40
    PUSH 0x00001000
    PUSH 0x10
    PUSH 0x00000000
    PUSH DWORD [EBP - 0x04]
    CALL DWORD [VirtualAllocEx]

    ;// Save the old EIP
    PUSH DWORD [EBP - 0x0238]
    POP  DWORD [EBP - 0x24]

    ;// Set the new EIP
    PUSH EAX
    POP  DWORD [EBP - 0x0238]

    ;// Patch the bridge for executing our code
    MOV  EBX, DWORD [EBP - 0x08]
    ADD  EBX, DWORD [EBP + 0x0C]
    SUB  EBX, EAX
    SUB  EBX, 0x0C
    MOV  DWORD [.ExecuteCodeOnApplication_Opcode + 0x08], EBX

    MOV  EBX, DWORD [EBP - 0x24]
    MOV  DWORD [.ExecuteCodeOnApplication_Opcode + 0x01], EBX

    ;// Write it to the remote process
    PUSH 0x00000000
    PUSH 0x10
    PUSH .ExecuteCodeOnApplication_Opcode
    PUSH EAX
    PUSH DWORD [EBP - 0x04]
    CALL DWORD [WriteProcessMemory]

    ;// Set the new thread context
    LEA  EAX, [EBP - 0x02F0]
    PUSH EAX
    PUSH DWORD [EBP - 0x10]
    CALL DWORD [SetThreadContext]

    ;// Resume thread
    PUSH DWORD [EBP - 0x10]
    CALL DWORD [ResumeThread]

.ExecuteCodeOnApplication_Exit:
    MOV  ESP, EBP
    POP  EBP
    RET  0x10