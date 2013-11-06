//////////////////////////////////////////////////////////////////////
/// This file is subject to the terms and conditions defined in    ///
/// file 'LICENSE.txt', which is part of this source code package. ///
///                                                                ///
/// \author Wolftein <wolftein1@gmail.com> @2013                   ///
//////////////////////////////////////////////////////////////////////
.section .text


////////////////////////////////////////////////////////
/// Defines for the opcode table
////////////////////////////////////////////////////////
.EQU   O_UNIQUE,    0x0
.EQU   O_PREFIX,    0x1
.EQU   O_IMM8,      0x2
.EQU   O_IMM16,     0x3
.EQU   O_IMM24,     0x4
.EQU   O_IMM32,     0x5
.EQU   O_IMM48,     0x6
.EQU   O_MODRM,     0x7
.EQU   O_MODRM8,    0x8
.EQU   O_MODRM32,   0x9
.EQU   O_EXTENDED,  0xA
.EQU   O_WEIRD,     0xB
.EQU   O_ERROR,     0xC

////////////////////////////////////////////////////////
/// Number of max hook allowed
////////////////////////////////////////////////////////
.EQU HOOK_LENGTH, 100

////////////////////////////////////////////////////////
/// \brief Initialize Dissembler module [+]
////////////////////////////////////////////////////////
_InitializeDisasembler:
    pushl %ebp
    movl  %esp, %ebp
    subl  $0x4, %esp

._InitializeDisasembler_AllowWriteOnCode:    
    pushl %esp
    pushl $0x80                         /* PAGE_EXECUTE_WRITE_COPY */
    pushl $0x4
    pushl $__ppHookList
    pushl $0xFFFFFFFF
    call  *__fVirtualProtect

    pushl $HOOK_LENGTH * 0x4
    call  _MemoryAllocate
    movl  %eax, __ppHookList

._InitializeDisasembler_RemoveWriteOnCode:
    leal  -0x4(%ebp), %eax

    pushl %eax
    pushl -0x4(%ebp)
    pushl $0x4
    pushl $__ppHookList
    pushl $0xFFFFFFFF
    call  *__fVirtualProtect

    movl  %ebp, %esp
    pop   %ebp
    retl

////////////////////////////////////////////////////////
/// \brief Returns the length of the instruction [-]
///
/// \param address The address of the instruction
///
/// \return The length that takes the instruction
////////////////////////////////////////////////////////
_GetInstructionLen:
    pushal
    
    cld
    xorl  %edx, %edx

    movl  0x24(%esp), %esi
    movl  %esp, %ebp

    pushl $0x1097F71C
    pushl $0xF71C6780
    pushl $0x17389718
    pushl $0x101CB718
    pushl $0x17302C17
    pushl $0x18173017
    pushl $0xF715F547
    pushl $0x4C103748
    pushl $0x272CE7F7
    pushl $0xF7AC6087
    pushl $0x1C121C52
    pushl $0x7C10871C
    pushl $0x201C701C
    pushl $0x4767602B
    pushl $0x20211011
    pushl $0x40121625
    pushl $0x82872022
    pushl $0x47201220
    pushl $0x13101419
    pushl $0x18271013
    pushl $0x28858260
    pushl $0x15124045      
    pushl $0x5016A0C7
    pushl $0x28191812
    pushl $0xF2401812
    pushl $0x19154127
    pushl $0x50F0F011

    movl  $0x15124710, %ecx
    pushl %ecx
    pushl $0x11151247
    pushl $0x10111512
    pushl $0x47101115
    movl  $0x12472015, %eax
    pushl %eax
    pushl %eax
    pushl $0x12471A10
    addb  $0x10, %cl
    pushl %ecx
    addb  $0x20, %cl
    pushl %ecx

    xorl  %ecx, %ecx
    decl  %ecx

._GetInstructionLen_Process:
    incl  %ecx
    movl  %esp, %edi

._GetInstructionLen_Go:
    lodsb
    movb  %al, %bh

._GetInstructionLen_Feet:
    movb  (%edi), %ah
    incl  %edi
    shrb  $0x4, %ah
    subb  %ah, %al
    jnc   ._GetInstructionLen_Feet

    movb  -0x1(%edi), %al
    andb  $0xF, %al

    cmpb  $O_ERROR, %al
    jnz   ._GetInstructionLen_I7

    popl  %edx
    notl  %edx

._GetInstructionLen_I7:
    incl  %edx
    cmpb  $O_UNIQUE, %al
    jz    ._GetInstructionLen_Exit

    cmpb  $O_PREFIX, %al
    jz    ._GetInstructionLen_Process
    
    addl  $0x51, %edi
    
    cmpb  $O_EXTENDED, %al
    jz    ._GetInstructionLen_Go

    movl  0x24(%ebp), %edi

._GetInstructionLen_I6:
    incl  %edx
    cmpb  $O_IMM8, %al
    jz    ._GetInstructionLen_Exit

    cmpb  $O_MODRM, %al
    jz    ._GetInstructionLen_Moderm

    cmpb  $O_WEIRD, %al
    jz    ._GetInstructionLen_Weird

._GetInstructionLen_I5:
    incl  %edx
    cmpb  $O_IMM16, %al
    jz    ._GetInstructionLen_Exit

    cmpb  $O_MODRM8, %al
    jz    ._GetInstructionLen_Moderm

._GetInstructionLen_I4:
    incl  %edx
    cmpb  $O_IMM24, %al
    jz    ._GetInstructionLen_Exit

._GetInstructionLen_I3:
    incl  %edx

._GetInstructionLen_I2:
    incl  %edx

    pushal
    movb  $0x66, %al
    repnz scasb
    popal
    jnz   ._GetInstructionLen_C32

._GetInstructionLen_D2:
    decl  %edx
    decl  %edx

._GetInstructionLen_C32:
    cmpb  $O_MODRM32, %al
    jz    ._GetInstructionLen_Moderm

    subb  $O_IMM32, %al
    jz    ._GetInstructionLen_Opcode32

._GetInstructionLen_I1:
    incl  %edx

._GetInstructionLen_Exit:
    movl  %ebp, %esp
    movl  %edx, 0x1C(%esp)
    popal
    movl  -0x4(%esp), %eax
    retl  $0x4

._GetInstructionLen_Moderm:
    lodsb
    movb  %al, %ah
    shrb  $0x7, %al
    jb    ._GetInstructionLen_PermutationK
    jz    ._GetInstructionLen_Permutation

    addb  $0x4, %dl

    pushal
    movb  $0x67, %al
    repnz scasb
    popal
    jnz   ._GetInstructionLen_Permutation

._GetInstructionLen_D3:
    subb  $0x3, %dl
    decb  %al

._GetInstructionLen_PermutationK:
    jnz   ._GetInstructionLen_Exit
    incl  %edx
    incl  %eax

._GetInstructionLen_Permutation:
    andb  $0x7, %ah

    pushal
    movb  $0x67, %al
    repnz scasb
    popal
    jz    ._GetInstructionLen_Permutation67Check

    cmpb  $0x4, %ah
    jz    ._GetInstructionLen_PermutationIB

    cmpb  $0x5, %ah
    jnz    ._GetInstructionLen_Exit
._GetInstructionLen_Permutation5Check:
    decb  %al
    jz    ._GetInstructionLen_Exit

._GetInstructionLen_I42:
    addb  $0x4, %dl
    jmp   ._GetInstructionLen_Exit

._GetInstructionLen_Permutation67Check:
    cmpw  $0x600, %ax
    jnz   ._GetInstructionLen_Exit
    incl  %edx
    jmp   ._GetInstructionLen_I1

._GetInstructionLen_PermutationIB:
    cmpb  $0x0, %al
    jnz   ._GetInstructionLen_I1
    lodsb
    andb  $0x7, %al
    subb  $0x5, %al
    jnz   ._GetInstructionLen_I1
    incl  %edx
    jmp   ._GetInstructionLen_I42

._GetInstructionLen_Weird:
    testb $0x7, (%esi)
    jnz   ._GetInstructionLen_Moderm

    movb  $O_MODRM8, %al

    shrb  $0x1, %bh
    adcb  $0x0, %al
    jmp   ._GetInstructionLen_I5

._GetInstructionLen_Opcode32:
    subb  $0xA0, %bh
    
    cmpb  $0x4, %bh
    jae   ._GetInstructionLen_D2

    pushal
    movb  $0x67, %al
    repnz scasb
    popal
    jnz   ._GetInstructionLen_CheckOpcode66T

._GetInstructionLen_D4:
    decl  %edx
    decl  %edx

._GetInstructionLen_CheckOpcode66T:
    pushal
    movb  $0x66, %al
    repnz scasb
    popal
    jz    ._GetInstructionLen_I1
    jnz   ._GetInstructionLen_D2

////////////////////////////////////////////////////////
/// \brief Returns the length needed by the cave [+]
///
/// \param address The address of the instruction
/// \param length  The minimus length
///
/// \return The length needed
////////////////////////////////////////////////////////
_GetCodeAt:
    pushl %ebp
    movl  %esp, %ebp

    pushl %esi
    pushl %ebx

    xorl  %ebx, %ebx
    movl  0x8(%ebp), %esi

._GetCodeAt_Loop:
    pushl %esi
    call  _GetInstructionLen
    
    addl  %eax, %ebx
    cmpl  0xC(%ebp), %ebx
    jge   ._GetCodeAt_Finish

    addl  %eax, %esi
    jmp   ._GetCodeAt_Loop
._GetCodeAt_Finish:
    movl  %ebx, %eax

    popl  %ebx
    popl  %esi
    
    movl  %ebp, %esp
    pop   %ebp
    retl  $0x8


////////////////////////////////////////////////////////
/// \brief Adds a detour into a free list [+]
///
/// \param detour The detour to add into
////////////////////////////////////////////////////////
_AddDetour:
    pushl %ebp
    movl  %esp, %ebp
        
    pushl %esi
    pushl %ecx

    movl  $HOOK_LENGTH, %ecx
    movl  __ppHookList, %esi

._AddDetour_FindEntry:
    movl  (%esi), %eax
    testl %eax, %eax
    jz    ._AddDetour_FoundEntry

    addl  $0x4, %esi
    loop  ._AddDetour_FindEntry
    jmp   ._AddDetour_FindEnd

._AddDetour_FoundEntry:
    pushl 0x8(%ebp)
    popl  (%esi)

._AddDetour_FindEnd:
    popl  %ecx
    popl  %esi

    movl  %ebp, %esp
    popl  %ebp
    retl  $0x4

////////////////////////////////////////////////////////
/// \brief Get the type of the hook [+]
///
/// \param function The address of the function
///
/// \return The type of the hook
////////////////////////////////////////////////////////
_GetDetour:
    pushl %ebp
    movl  %esp, %ebp
        
    pushl %ebx
    pushl %ecx

    movl  $HOOK_LENGTH, %ecx
    movl  __ppHookList, %eax

._GetDetour_Loop:
    movl  (%eax), %ebx
    test  %ebx, %ebx
    jz    ._GetDetour_Continue

    movl  (%ebx), %ebx
    cmpl  0x8(%ebp), %ebx
    jne   ._GetDetour_Continue

    movl  (%eax), %eax
    jmp   ._GetDetour_Clean

._GetDetour_Continue:
    addl  $0x4, %eax
    loop  ._GetDetour_Loop
    xorl  %eax, %eax

._GetDetour_Clean:
    popl  %ecx
    popl  %ebx

    movl  %ebp, %esp
    pop   %ebp
    retl  $0x4

////////////////////////////////////////////////////////
/// \brief Writes the jump into the address specified [+]
///
/// \param address   The address to write to
/// \param addressTo The address for the callback
////////////////////////////////////////////////////////
_WriteJump:
    pushl %ebp
    movl  %esp, %ebp

    movl  0x8(%ebp), %esi
    movl  0xC(%ebp), %eax
    subl  $0x6, %eax

    movb  $0x90, 0x0(%esi)  /* NOP     */
    movb  $0xE9, 0x1(%esi)  /* JMP FAR */
    movl  %eax,  0x2(%esi)  /* ADDRESS */
    
    movl  %ebp, %esp
    pop   %ebp
    retl  $0x8

////////////////////////////////////////////////////////
/// \brief Hook the address specified [+]
///
/// \param address   The address to write to
/// \param addressTo The address for the callback
////////////////////////////////////////////////////////
_Detour:
    pushl %ebp 
    movl  %esp, %ebp
    subl  $0x10, %esp

    pushl %ebx

._Detour_CheckExistant:
    pushl 0x8(%ebp)
    call  _GetDetour
    testl %eax, %eax
    jnz   ._Detour_Exit

._Detour_CalculateLength:
    pushl $0x6
    pushl 0x8(%ebp)
    call  _GetCodeAt
    movl  %eax, -0x10(%ebp)

._Detour_AllowWriteOnCode:  
    leal  -0x4(%ebp), %eax

    pushl -0x10(%ebp)
    pushl $0x80                        
    pushl %eax
    pushl 0x8(%ebp)
    pushl $0xFFFFFFFF
    call  *__fVirtualProtect

._Detour_BuildBridge:
    movl  -0x10(%ebp), %eax
    addl  $0x6, %eax
    pushl %eax
    call  _MemoryAllocate
    movl  %eax, -0xC(%ebp)
    
    /* Write Overwritten bytes */
    pushl -0x10(%ebp)
    pushl -0xC(%ebp)
    pushl 0x8(%ebp)
    call  _MemoryCopy

    /* Write Jump from hook to original */
    movl  -0xC(%ebp), %eax
    addl  -0x10(%ebp), %eax
    
    movl  -0x10(%ebp), %ebx
    addl  0x8(%ebp),  %ebx
    subl  %eax, %ebx

    pushl %ebx
    pushl %eax
    call  _WriteJump

    /* Write jump from original to hook */
    movl  0xC(%ebp), %eax
    subl  0x8(%ebp), %eax
    pushl %eax
    pushl 0x8(%ebp)
    call  _WriteJump

._Detour_AddDetour:
    pushl $0xC
    call  _MemoryAllocate

    pushl 0x8(%ebp)
    popl  (%eax)

    pushl -0xC(%ebp)
    popl  0x4(%eax)

    pushl -0x10(%ebp)
    popl  0x8(%eax)

    pushl %eax
    call  _AddDetour

._Detour_RemoveWriteOnCode:
    pushl $0x00
    pushl -0x4(%ebp)
    pushl -0x10(%ebp)
    pushl 0x8(%ebp)
    pushl $0xFFFFFFFF
    call  *__fVirtualProtect

._Detour_Exit:
    popl  %ebx

    movl  %ebp, %esp
    popl  %ebp
    retl  $8

////////////////////////////////////////////////////////
/// \brief Unhooks the function hooked [+]
///
/// \param address   The address of the original function
////////////////////////////////////////////////////////
_RemoveDetour:
    pushl %ebp
    movl  %esp, %ebp

    pushl %ebx
    pushl %ecx
    pushl %edx

    movl  $HOOK_LENGTH, %ecx
    movl  __ppHookList, %eax

._RemoveDetour_Loop:
    movl  (%eax), %ebx
    testl %ebx, %ebx
    jz    ._RemoveDetour_Continue

    movl  (%ebx), %edx
    cmpl  0x8(%ebp), %edx
    je    ._RemoveDetour_Found

._RemoveDetour_Continue:
    addl  $0x4, %eax
    loop  ._RemoveDetour_Loop
    jmp   ._RemoveDetour_Clean

._RemoveDetour_Found:
    movl  $0x0, (%eax)

    pushl %ebx
    pushl 0x8(%ebx)
    pushl 0x4(%ebx)
    pushl 0x0(%ebx)
    call  _MemoryCopy
    call  _MemoryFree
._RemoveDetour_Clean:
    popl  %edx
    popl  %ecx
    popl  %ebx

    movl  %ebp, %esp
    pop   %ebp
    retl  $0x4

////////////////////////////////////////////////////////
/// \brief Unhook every function hooked [+]
////////////////////////////////////////////////////////
_RemoveAllDetour:
    pushl %ebp
    movl  %esp, %ebp

    pushl %ebx
    pushl %ecx

    movl  $HOOK_LENGTH, %ecx
    movl  __ppHookList, %eax

._RemoveAllDetour_Loop:
    movl  (%eax), %ebx
    testl %ebx, %ebx
    jz    ._RemoveAllDetour_Continue

    pushl %eax                          /* [+1] */

    pushl %ebx
    pushl 0x8(%ebx)
    pushl 0x4(%ebx)
    pushl 0x0(%ebx)
    call  _MemoryCopy
    call  _MemoryFree

    popl  %eax                          /* [-1] */
    movl  $0x0, (%eax)

 ._RemoveAllDetour_Continue:
    addl  $0x4, %eax
    loop  ._RemoveAllDetour_Loop

._RemoveAllDetour_Clean:
    popl  %ecx
    popl  %ebx

    movl  %ebp, %esp
    pop   %ebp
    retl

////////////////////////////////////////////////////////
/// \brief Compare a buffer with the given pattern and
///        mask.
///
/// \param buffer  The buffer that holds the bytes
/// \param pattern The patter for the comparition
/// \param mask    The mask of the pattern
///
/// \return True if the memory is the same
////////////////////////////////////////////////////////
_CompareMemory:
    pushl %ebp
    movl  %esp, %ebp

    // TODO

    movl  %ebp, %esp
    pop   %ebp
    retl  $12

////////////////////////////////////////////////////////
/// \brief Find a pattern from the start of an offset
///
/// \param offset  The offset in memory to start
/// \param size    The size of the search
/// \param pattern The patter for the compare
/// \param mask    The mask of the pattern
///
/// \return The offset within the start of the pattern
////////////////////////////////////////////////////////
_FindMemory:
    pushl %ebp
    movl  %esp, %ebp

    // TODO
    
    movl  %ebp, %esp
    pop   %ebp
    retl  $16

////////////////////////////////////////////////////////
/// \brief Given an offset within a function, find the
///        the start of the function [+]
///
/// \param offset  The offset in memory
///
/// \return The start address of the function
////////////////////////////////////////////////////////
_BacktraceFunction:
    pushl %ebp
    movl  %esp, %ebp

    pushl %ebx

    movl  0x8(%ebp), %eax

._BacktraceFunction_Loop:
    movb  (%eax), %bl
    cmpb  $0xE5, %bl
    jne   ._BacktraceFunction_Continue

    movb  -0x1(%eax), %bl
    cmpb  $0x89, %bl
    jne   ._BacktraceFunction_Continue

    movb  -0x2(%eax), %bl
    cmpb  $0x55, %bl
    jne   ._BacktraceFunction_Continue

    subl  $0x2, %eax
    jmp   ._BacktraceFunction_Found

._BacktraceFunction_Continue:
    dec   %eax
    jmp   ._BacktraceFunction_Loop

._BacktraceFunction_Found:
    popl  %ebx

    movl  %ebp, %esp
    pop   %ebp
    retl  $4

////////////////////////////////////////////////////////
///!< Hook List (Pointer)
////////////////////////////////////////////////////////
__ppHookList:
    .byte    0x90, 0x90, 0x90, 0x90
