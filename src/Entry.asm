//////////////////////////////////////////////////////////////////////
/// This file is subject to the terms and conditions defined in    ///
/// file 'LICENSE.txt', which is part of this source code package. ///
///                                                                ///
/// \author Wolftein <wolftein1@gmail.com> @2013                   ///
//////////////////////////////////////////////////////////////////////
.section .text
    
    ////////////////////////////////////////////////////
    /// ENTRY_POINT
    ////////////////////////////////////////////////////
    .globl main

__Begin:
    ////////////////////////////////////////////////////
    /// INCLUDE
    ////////////////////////////////////////////////////
    .include "src/Windows/WinDefinition.asm"
    .include "src/Windows/WinAPI.asm"
    .include "src/Windows/WinMemory.asm"
    .include "src/Assembler.asm"

////////////////////////////////////////////////////
/// \brief Execution point of the foundation code
////////////////////////////////////////////////////
Foundation:
    push  %ebp
    movl  %esp, %ebp

    call  _InitializeWinAPI       /* Initialize Toolkit        */
    call  _InitializeMemory       /* Initialize Memory Manager */
    call  _InitializeDisasembler  /* Initialize Dissambler     */

    pushl $.Foundation_Library
    pushl $LOAD_LIBRARY_A
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    pushl $MESSAGE_BOX_A
    pushl %eax
    call  _GetProcAddress

    pushl $0
    pushl $.Foundation_MessageTitle
    pushl $.Foundation_Message
    pushl $0
    call  *%eax
    
    //pushl $Foundation_MessageBox
    //pushl %eax
    //call  _Detour
    retl

Foundation_MessageBox:
    push  %ebp
    movl  %esp, %ebp

    pushl $0
    pushl $.Foundation_MessageTitle
    pushl $.Foundation_Message
    pushl $0

    pushl $.Foundation_Library
    pushl $LOAD_LIBRARY_A
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    pushl $MESSAGE_BOX_A
    pushl %eax
    call  _GetProcAddress

    pushl %eax
    call  _GetDetour
    call  *%eax

    movl  %ebp, %esp
    popl  %ebp
    retl  $0x10

.Foundation_MessageTitle:
    .byte 'H', 'e', 'l', 'l', 'o', 0x00

.Foundation_Message:
    .byte 'W', 'o', 'l', 'f', 't', 'e', 'i', 'n', ' '
    .byte 's', 'a', 'y', 's', ' '
    .byte 'h', 'e', 'l', 'l', 'o', 0x00

.Foundation_Library:
    .byte 'u', 's', 'e', 'r', '3', '2', '.', 'd', 'l', 'l', 0x00

__Injector:
    ////////////////////////////////////////////////////
    /// INCLUDE
    ////////////////////////////////////////////////////
    .include "src/Portable.asm"

////////////////////////////////////////////////////
/// \brief Entry point of the application
////////////////////////////////////////////////////
main:
    /* Initialize Toolkit        */
    call  _InitializeWinAPI       

    /* Initialize Memory Manager */
    call  _InitializeMemory     

    /* Initialize Dissambler     */  
    call  _InitializeDisasembler

    /* GetCommandLine            */
    call  _GetCommandLine

    /* Execute Remote code */
    pushl $(__Injector - __Begin) 
    pushl $__Begin
    pushl $(Foundation - __Begin)
    pushl %eax
    call  _ExecuteRemoteCode
    retl

////////////////////////////////////////////////////
/// \brief Return the name of the target
///
/// \return The name of the target
////////////////////////////////////////////////////
_GetCommandLine:
    pushl %ebp
    movl  %esp, %ebp

    pushl $GET_COMMAND_LINE
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

._GetCommandLine_AppendToEnd:
    pushl %eax
    movl  %eax, %esi
    call  *__fStringLen
    addl  %eax, %esi
    xorl  %ebx, %ebx

._GetCommandLine_Compare:
    cmpb  $' ', (%esi)
    je    ._GetCommandLine_Found
    
    cmpb  $0x22, (%esi)
    je    ._GetCommandLine_Delimiter
    jmp   ._GetCommandLine_Loop

._GetCommandLine_Delimiter:
    testl %ebx, %ebx
    jnz   ._GetCommandLine_FoundString
    incl  %ebx
    movl  $0x00, (%esi)

._GetCommandLine_Loop:
    decl  %esi
    decl  %eax
    test  %eax, %eax
    jnz   ._GetCommandLine_Compare

._GetCommandLine_Found:
    testl %ebx, %ebx
    jnz   ._GetCommandLine_Loop

._GetCommandLine_FoundString:
    incl  %esi
    movl  %esi, %eax


    movl  %ebp, %esp
    pop   %ebp
    retl
