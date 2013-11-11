;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]

;////////////////////////////////////////////////////////
;/// Defines for the opcode table
;////////////////////////////////////////////////////////
O_UNIQUE    EQU     0x0
O_PREFIX    EQU     0x1
O_IMM8      EQU     0x2
O_IMM16     EQU     0x3
O_IMM24     EQU     0x4
O_IMM32     EQU     0x5
O_IMM48     EQU     0x6
O_MODRM     EQU     0x7
O_MODRM8    EQU     0x8
O_MODRM32   EQU     0x9
O_EXTENDED  EQU     0xA
O_WEIRD     EQU     0xB
O_ERROR     EQU     0xC

;////////////////////////////////////////////////////////
;/// Number of max hook allowed
;////////////////////////////////////////////////////////
HOOK_LENGTH EQU     100

;////////////////////////////////////////////////////////
;///!< Hooks handler
;////////////////////////////////////////////////////////
__ppHookList:           DD 0x01234567

;////////////////////////////////////////////////////////
;/// \brief Initialize Disassembler Enviroment
;////////////////////////////////////////////////////////
InitializeDisassembler:
    PUSH EBP
    MOV  EBP, ESP

    AllocateMemory (HOOK_LENGTH * 0x04)
    MOV  DWORD [__ppHookList], EAX
    
    MOV  ESP, EBP
    POP  EBP
    RET

;////////////////////////////////////////////////////////
;/// \brief Returns the length of the instruction
;///
;/// \param address The address of the instruction
;///
;/// \return The length that takes the instruction
;////////////////////////////////////////////////////////
GetInstructionLen:
    PUSHAD

    CLD
    XOR  EDX, EDX

    MOV  ESI, DWORD [ESP + (8 * 4) + 4]
    MOV  EBP, ESP

    PUSH 0x1097F71C
    PUSH 0xF71C6780
    PUSH 0x17389718
    PUSH 0x101CB718
    PUSH 0x17302C17
    PUSH 0x18173017
    PUSH 0xF715F547
    PUSH 0x4C103748
    PUSH 0x272CE7F7
    PUSH 0xF7AC6087
    PUSH 0x1C121C52
    PUSH 0x7C10871C
    PUSH 0x201C701C
    PUSH 0x4767602B
    PUSH 0x20211011
    PUSH 0x40121625
    PUSH 0x82872022
    PUSH 0x47201220
    PUSH 0x13101419
    PUSH 0x18271013
    PUSH 0x28858260
    PUSH 0x15124045      
    PUSH 0x5016A0C7
    PUSH 0x28191812
    PUSH 0xF2401812
    PUSH 0x19154127
    PUSH 0x50F0F011
    MOV  ECX, 0x15124710
    PUSH ECX
    PUSH 0x11151247
    PUSH 0x10111512
    PUSH 0x47101115
    MOV  EAX, 0x12472015
    PUSH EAX
    PUSH EAX
    PUSH 0x12471A10
    ADD  CL, 0x10
    PUSH ECX
    SUB  CL, 0x20
    PUSH ECX

    XOR  ECX, ECX
    DEC  ECX
 
._GetInstructionLen_Process:
    INC  ECX
    MOV  EDI, ESP

._GetInstructionLen_Go:
    LODSB
    MOV  BH, AL

._GetInstructionLen_Feet:
    MOV  AH, BYTE [EDI]
    INC  EDI
    SHR  AH, 0x04
    SUB  AL, AH
    JNC  ._GetInstructionLen_Feet

    MOV  AL, BYTE [EDI - 0x01]
    AND  AL, 0x0F

    CMP  AL, O_ERROR
    JNZ  ._GetInstructionLen_I7

    POP  EDX
    NOT  EDX

._GetInstructionLen_I7:
    INC  EDX
    CMP  AL, O_UNIQUE
    JZ   ._GetInstructionLen_Exit

    CMP  AL, O_PREFIX
    JZ   ._GetInstructionLen_Process

    ADD  EDI, 0x51

    CMP  AL, O_EXTENDED
    JZ   ._GetInstructionLen_Go

    MOV  EDI, DWORD [EBP + (8 * 4) + 4]

._GetInstructionLen_I6:
    INC  EDX
    
    CMP  AL, O_IMM8
    JZ   ._GetInstructionLen_Exit

    CMP  AL, O_MODRM
    JZ   ._GetInstructionLen_Moderm

    CMP  AL, O_WEIRD
    JZ   ._GetInstructionLen_Weird

._GetInstructionLen_I5:
    INC  EDX
    CMP  AL, O_IMM16
    JZ   ._GetInstructionLen_Exit

    CMP  AL, O_MODRM8
    JZ   ._GetInstructionLen_Moderm

._GetInstructionLen_I4:
    INC  EDX
    CMP  AL, O_IMM24
    JZ   ._GetInstructionLen_Exit

._GetInstructionLen_I3:
    INC  EDX

._GetInstructionLen_I2:
    INC  EDX

    PUSHAD
    MOV  AL, 0x66
    REPNZ SCASB
    POPAD
    JNZ  ._GetInstructionLen_C32

._GetInstructionLen_D2:
    DEC  EDX
    DEC  EDX

._GetInstructionLen_C32:
    CMP  AL, O_MODRM32
    JZ   ._GetInstructionLen_Moderm

    SUB  AL, O_IMM32
    JZ   ._GetInstructionLen_Opcode32

._GetInstructionLen_I1:
    INC  EDX

._GetInstructionLen_Exit:
    MOV  ESP, EBP
    MOV  DWORD [ESP + (7 * 4)], EDX
    POPAD
    RET

._GetInstructionLen_Moderm:
    LODSB
    MOV  AH, AL
    SHR  AL, 0x07
    JB   ._GetInstructionLen_PermutationK
    JZ   ._GetInstructionLen_Permutation

    ADD  DL, 0x04

    PUSHAD
    MOV  AL, 0x67
    REPNZ SCASB
    POPAD
    JNZ  ._GetInstructionLen_Permutation

._GetInstructionLen_D3:
    SUB  DL, 0x03
    DEC  AL

._GetInstructionLen_PermutationK:
    JNZ  ._GetInstructionLen_Exit
    INC  EDX
    INC  EAX

._GetInstructionLen_Permutation:
    AND  AH, 00000111b

    PUSHAD
    MOV  AL, 0x67
    REPNZ SCASB
    POPAD
    JZ   ._GetInstructionLen_Permutation67Check

    CMP  AH, 0x04
    JZ   ._GetInstructionLen_PermutationIB

    CMP  AH, 0x05
    JNZ  ._GetInstructionLen_Exit

._GetInstructionLen_Permutation5Check:
    DEC  AL
    JZ   ._GetInstructionLen_Exit

._GetInstructionLen_I42:
    ADD  DL, 0x04
    JMP  ._GetInstructionLen_Exit

._GetInstructionLen_Permutation67Check:
    CMP  AX, 0x0600
    JNZ  ._GetInstructionLen_Exit
    INC  EDX
    JMP  ._GetInstructionLen_I1

._GetInstructionLen_PermutationIB:
    CMP  AL, 0x00
    JNZ  ._GetInstructionLen_I1
    LODSB
    AND  AL, 00000111b
    SUB  AL, 0x05
    JNZ  ._GetInstructionLen_I1
    INC  EDX
    JMP  ._GetInstructionLen_I42

._GetInstructionLen_Weird:
    TEST BYTE [ESI], 00111000b
    JNZ  ._GetInstructionLen_Moderm

    MOV  AL, O_MODRM8

    SHR  BH, 0x01
    ADC  AL, 0x00
    JMP  ._GetInstructionLen_I5

._GetInstructionLen_Opcode32:
    SUB  BH, 0xA0

    CMP  BH, 0x04
    JAE  ._GetInstructionLen_D2

    PUSHAD
    MOV  AL, 0x67
    REPNZ SCASB
    POPAD
    JNZ  ._GetInstructionLen_CheckOpcode66T

._GetInstructionLen_D4:
    DEC  EDX
    DEC  EDX

._GetInstructionLen_CheckOpcode66T:
    PUSHAD
    MOV  AL, 0x66
    REPNZ SCASB
    POPAD
    JZ   ._GetInstructionLen_I1
    JNZ  ._GetInstructionLen_D2

;////////////////////////////////////////////////////////
;/// \brief Returns the length needed by the cave
;///
;/// \param address The address of the instruction
;/// \param length  The minimus length
;///
;/// \return The length needed
;////////////////////////////////////////////////////////
GetCodeAt:
    PUSH EBP
    MOV  EBP, ESP

    PUSH ESI
    PUSH EBX

    XOR  EBX, EBX
    MOV  ESI, DWORD [EBP + 0x08]

.GetCodeAt_Loop:
    PUSH ESI
    CALL GetInstructionLen

    ADD  EBX, EAX
    CMP  EBX, DWORD [EBP + 0x0C]
    JGE  .GetCodeAt_Finish

    ADD  ESI, EAX
    JMP  .GetCodeAt_Loop

.GetCodeAt_Finish:
    MOV  EAX, EBX
        
    POP  EBX
    POP  ESI

    MOV  ESP, EBP
    POP  EBP
    RET  0x08

;////////////////////////////////////////////////////////
;/// \brief Adds a detour into a free list
;///
;/// \param detour The detour to add into
;////////////////////////////////////////////////////////
AddDetour:
    PUSH EBP
    MOV  EBP, ESP

    PUSH ESI
    PUSH ECX

    MOV  ECX, HOOK_LENGTH
    MOV  ESI, DWORD [__ppHookList]

.AddDetour_FindEntry:
    MOV  EAX, DWORD [ESI]
    TEST EAX, EAX
    JZ   .AddDetour_FoundEntry

    ADD  ESI, 0x04
    LOOP .AddDetour_FindEntry
    JMP  .AddDetour_FindEnd

.AddDetour_FoundEntry:
    PUSH DWORD [EBP + 0x08]
    POP  DWORD [ESI]

.AddDetour_FindEnd:
    POP  ECX
    POP  ESI

    MOV  ESP, EBP
    POP  EBP
    RET  0x04

;////////////////////////////////////////////////////////
;/// \brief Get the type of the hook [+]
;///
;/// \param function The address of the function
;///
;/// \return The type of the hook
;////////////////////////////////////////////////////////
GetDetour:
    PUSH EBP
    MOV  EBP, ESP
        
    PUSH EBX
    PUSH ECX

    MOV  ECX, HOOK_LENGTH
    MOV  EAX, DWORD [__ppHookList]

.GetDetour_Loop:
    MOV  EBX, DWORD [EAX]
    TEST EBX, EBX
    JZ   .GetDetour_Continue

    MOV  EBX, DWORD [EBX]
    CMP  EBX, DWORD [EBP + 0x08]
    JNE  .GetDetour_Continue

    MOV  EAX, DWORD [EAX]
    JMP  .GetDetour_Clean

.GetDetour_Continue:
    ADD  EAX, 0x04
    LOOP .GetDetour_Loop
    
    XOR  EAX, EAX

.GetDetour_Clean:
    POP  ECX
    POP  EBX

    MOV  ESP, EBP
    POP  EBP
    RET  0x04

;////////////////////////////////////////////////////////
;/// \brief Writes the jump into the address specified [+]
;///
;/// \param address   The address to write to
;/// \param addressTo The address for the callback
;////////////////////////////////////////////////////////
WriteJump:
    PUSH EBP
    MOV  EBP, ESP

    PUSH ESI

    MOV  ESI, DWORD [EBP + 0x08]
    MOV  EAX, DWORD [EBP + 0x0C]
    SUB  EAX, 0x06

    MOV  BYTE  [ESI + 0x00], 0x90
    MOV  BYTE  [ESI + 0x01], 0xE9
    MOV  DWORD [ESI + 0x02], EAX

    POP  ESI

    MOV  ESP, EBP
    POP  EBP
    RET  0x08

;////////////////////////////////////////////////////////
;/// \brief Hook the address specified
;///
;/// \param address   The address to write to
;/// \param addressTo The address for the callback
;////////////////////////////////////////////////////////
WriteDetour:
    PUSH EBP
    MOV  EBP, ESP
    SUB  ESP, 0x0C

    PUSH EBX

.WriteDetour_CheckIfExist:
    PUSH DWORD [EBP + 0x08]
    CALL GetDetour
    
    TEST EAX, EAX
    JNZ  .WriteDetour_Exit

.WriteDetour_GetLenght:
    PUSH 0x06
    PUSH DWORD [EBP + 0x08]
    CALL GetCodeAt
    MOV  DWORD [EBP - 0x10], EAX

.WriteDetour_AllowWrite:
    LEA  EAX,  [EBP - 0x04]
    PUSH EAX
    PUSH 0x80
    PUSH DWORD [EBP - 0x10]
    PUSH DWORD [EBP + 0x08]
    PUSH 0xFFFFFFFF
    CALL DWORD [VirtualProtectEx]

.WriteDetour_BuildBridge:
    MOV  EAX, DWORD [EBP - 0x10]
    ADD  EAX, 0x06
    
    AllocateMemory EAX
    MOV  DWORD [EBP - 0x0C], EAX

    ;// Write Overwritten bytes
    PUSH DWORD [EBP - 0x10]
    PUSH DWORD [EBP - 0x0C]
    PUSH DWORD [EBP + 0x08]
    CALL CopyMemory

    ;// Write jump from hook to original
    MOV  EAX, DWORD [EBP - 0x0C]
    ADD  EAX, DWORD [EBP - 0x10]

    MOV  EBX, DWORD [EBP - 0x10]
    ADD  EBX, DWORD [EBP + 0x08]
    SUB  EBX, EAX

    PUSH EBX
    PUSH EAX
    CALL WriteJump

    ;// Write jump from original to hook
    MOV  EAX, DWORD [EBP + 0x0C]
    SUB  EAX, DWORD [EBP + 0x08]

    PUSH EAX
    PUSH DWORD [EBP + 0x08]
    CALL WriteJump

.WriteDetour_AddDetour:
    AllocateMemory 0x0C

    PUSH DWORD [EBP + 0x08]
    POP  DWORD [EAX + 0x00]

    PUSH DWORD [EBP - 0x0C]
    POP  DWORD [EAX + 0x04]

    PUSH DWORD [EBP - 0x10]
    POP  DWORD [EAX + 0x08]

    PUSH EAX
    CALL AddDetour

.WriteDetour_RemoveWriteOnCode:
    PUSH 0x00
    PUSH DWORD [EBP - 0x04]
    PUSH DWORD [EBP - 0x10]
    PUSH DWORD [EBP + 0x08]
    PUSH 0xFFFFFFFF
    CALL DWORD [VirtualProtectEx]

.WriteDetour_Exit:
    POP  EBX

    MOV  ESP, EBP
    POP  EBP
    RET  0x08

;////////////////////////////////////////////////////////
;/// \brief Unhooks the function hooked
;///
;/// \param address The address of the original function
;////////////////////////////////////////////////////////
RemoveDetour:
    PUSH EBP
    MOV  EBP, ESP

    PUSH EBX
    PUSH ECX
    PUSH EDX

    MOV  ECX, HOOK_LENGTH
    MOV  EAX, DWORD [__ppHookList]

.RemoveDetour_Loop:
    MOV  EBX, DWORD [EAX]
    TEST EBX, EBX
    JZ   .RemoveDetour_Continue

    MOV  EDX, DWORD [EBX]
    CMP  EDX, DWORD [EBP + 0x08]
    JE   .RemoveDetour_Found

.RemoveDetour_Continue:
    ADD  EAX, 0x04
    LOOP .RemoveDetour_Loop
    JMP  .RemoveDetour_Clean

.RemoveDetour_Found:
    MOV  DWORD [EAX], 0x00
    PUSH DWORD [EBX + 0x08]
    PUSH DWORD [EBX + 0x04]
    PUSH DWORD [EBX + 0x00]
    CALL CopyMemory
    DeallocateMemory EBX

.RemoveDetour_Clean:
    POP  EDX
    POP  ECX
    POP  EBX

    MOV  ESP, EBP
    POP  EBP
    RET  0x04

;////////////////////////////////////////////////////////
;/// \brief Unhook every function hooked
;////////////////////////////////////////////////////////
RemoveAllDetour:
    PUSH EBP
    MOV  EBP, ESP

    PUSH EBX
    PUSH ECX

    MOV  ECX, HOOK_LENGTH
    MOV  EAX, DWORD [__ppHookList]

.RemoveAllDetour_Loop:
    MOV  EBX, DWORD [EAX]
    TEST EBX, EBX
    JZ   .RemoveAllDetour_Continue

    MOV  DWORD [EAX], 0x00
    PUSH DWORD [EBX + 0x08]
    PUSH DWORD [EBX + 0x04]
    PUSH DWORD [EBX + 0x00]
    CALL CopyMemory
    DeallocateMemory EBX

.RemoveAllDetour_Continue:
    ADD  EAX, 0x04
    LOOP .RemoveAllDetour_Loop

.RemoveAllDetour_Clean:
    POP  ECX
    POP  EBX

    MOV  ESP, EBP
    POP  EBP
    RET

;////////////////////////////////////////////////////////
;/// \brief Given an offset within a function, find the
;///        the start of the function
;///
;/// \param offset  The offset in memory
;///
;/// \return The start address of the function
;////////////////////////////////////////////////////////
BacktraceFunction:
    PUSH EBP
    MOV  EBP, ESP

    PUSH EBX

    MOV  EAX, DWORD [EBP + 0x08]

.BacktraceFunction_Loop:
    MOV  BL, BYTE [EAX]
    CMP  BL, 0xE5
    JNE  .BacktraceFunction_Continue

    MOV  BL, BYTE [EAX - 0x01]
    CMP  BL, 0x89
    JNE  .BacktraceFunction_Continue

    MOV  BL, BYTE [EAX - 0x02]
    CMP  BL, 0x55
    JNE  .BacktraceFunction_Continue

    SUB  EAX, 0x02
    JMP  .BacktraceFunction_Found

.BacktraceFunction_Continue:
    DEC  EAX
    JMP  .BacktraceFunction_Loop

.BacktraceFunction_Found:
    POP  EBX

    MOV  ESP, EBP
    POP  EBP
    RET  0x04
