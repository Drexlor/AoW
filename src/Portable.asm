//////////////////////////////////////////////////////////////////////
/// This file is subject to the terms and conditions defined in    ///
/// file 'LICENSE.txt', which is part of this source code package. ///
///                                                                ///
/// \author Wolftein <wolftein1@gmail.com> @2013                   ///
//////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////
/// \brief Return a thread of the given process [+]
///
/// \param identifier The id of the process
///
/// \return The id of the thread
////////////////////////////////////////////////////////
_GetThreadID:
    push %ebp
    movl %esp, %ebp
    subl $0x30, %esp

    pushl $THREAD_NEXT  
    pushl __hKernel32
    call  _GetProcAddress
    movl  %eax, -0x8(%ebp)

    pushl $0x0
    pushl $0x00000004               /* TH32CS_SNAPTHREAD */
    pushl $CREATE_SNAPSHOT  
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    cmp   $0xFFFFFFFF, %eax
    je    ._GetThreadID_Finish

    movl  %eax, -0x4(%ebp)
    movl  $0x1C, -0x30(%ebp)        /* THREADENTRY32.dwSize */
    movl  $0x0, -0xC(%ebp)          /* ZeroMemory(HANDLE) */

    leal  -0x30(%ebp), %eax
    pushl %eax
    pushl -0x4(%ebp)
    pushl $THREAD_FIRST  
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    testl %eax, %eax
    jz    ._GetThreadID_Close

._GetThreadID_Loop:
    movl  -0x24(%ebp), %eax
    cmpl  0x8(%ebp), %eax
    je    ._GetThreadID_Found
    
    leal  -0x30(%ebp), %eax
    pushl %eax
    pushl -0x4(%ebp)
    call  *-0x8(%ebp)

    test  %eax, %eax
    jnz   ._GetThreadID_Loop
    jz    ._GetThreadID_Close

._GetThreadID_Found:
    pushl -0x28(%ebp)               /* THREADENTRY32.th32ProcessID */
    popl  -0xC(%ebp)

._GetThreadID_Close:
    pushl -0x4(%ebp)
    pushl $CLOSE_HANDLE
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

._GetThreadID_Finish:
    movl -0xC(%ebp), %eax

    movl %ebp, %esp
    popl %ebp
    retl $0x4

////////////////////////////////////////////////////////
/// \brief Return the process id given its name [+]
///
/// \param name The name of the process
///
/// \return The id of the process
////////////////////////////////////////////////////////
_GetProcessID:
    push %ebp
    movl %esp, %ebp
    subl $0x134, %esp

    pushl $PROCESS_NEXT  
    pushl __hKernel32
    call  _GetProcAddress
    movl  %eax, -0x8(%ebp)

    pushl $0x0
    pushl $0x00000002               /* TH32CS_SNAPPROCESS */
    pushl $CREATE_SNAPSHOT  
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    cmp   $0xFFFFFFFF, %eax
    je    ._GetProcessID_Finish

    movl  %eax, -0x4(%ebp)
    movl  $0x128, -0x130(%ebp)      /* PROCESSENTRY32.dwSize */
    movl  $0x0, -0x134(%ebp)        /* ZeroMemory(HANDLE) */

    leal  -0x130(%ebp), %eax
    pushl %eax
    pushl -0x4(%ebp)
    pushl $PROCESS_FIRST  
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    testl %eax, %eax
    jz    ._GetProcessID_Close

._GetProcessID_Loop:
    leal  -0x10C(%ebp), %eax
    
    pushl 0x8(%ebp)
    pushl %eax
    call  *__fStringCompare
    test  %eax, %eax
    jz    ._GetProcessID_Found

    leal  -0x130(%ebp), %eax
    pushl %eax
    pushl -0x4(%ebp)
    call  *-0x8(%ebp)

    test  %eax, %eax
    jnz   ._GetProcessID_Loop
    jz    ._GetProcessID_Close

._GetProcessID_Found:
    pushl -0x128(%ebp)      /* PROCESSENTRY32.th32ProcessID */
    popl  -0x134(%ebp)

._GetProcessID_Close:
    pushl -0x4(%ebp)
    pushl $CLOSE_HANDLE
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

._GetProcessID_Finish:
    movl -0x134(%ebp), %eax

    movl %ebp, %esp
    popl %ebp
    retl $0x4

////////////////////////////////////////////////////////
/// \brief Walk though the opcode table and fix
///        reallocation table / jmp / call to memory
///
/// \param oldAddress The old address
/// \param address    The new address for the opcodes
/// \param opcodes    The array of opcodes
/// \param length     The length of the opcode array
////////////////////////////////////////////////////////
_WalkReallocationTable:
    push  %ebp
    movl  %esp, %ebp

    pushl %ebx
    pushl %ecx
    pushl %esi
    
    movl  0x10(%ebp), %esi
    movl  0x14(%ebp), %ecx
    movl  0x8(%ebp),  %ebx

._WalkReallocationTable_Loop:
    movw  (%esi), %ax
    incl  %esi
    decl  %ecx

._WalkReallocationTable_I1: 
    cmpb  $0xA3, %al     /* MOV DWORD PTR SS:[...] */
    je    ._WalkReallocationTable_Compare

    cmpb  $0x68, %al     /* PUSH ... */
    je    ._WalkReallocationTable_Compare
    
    cmpw  $0x058F, %ax   /* POP DWORD PTR SS:[...] */
    je    ._WalkReallocationTable_CheckOpcodeI2

    cmpw  $0x35FF, %ax   /* PUSH DWORD PTR SS:[...] */
    je    ._WalkReallocationTable_CheckOpcodeI2

    cmpw  $0x15FF, %ax   /* CALL DWORD PTR SS:[...] */
    je    ._WalkReallocationTable_CheckOpcodeI2
    
    cmpl  $0x0, %ecx
    jg    ._WalkReallocationTable_Loop

._WalkReallocationTable_CheckOpcodeI2:
    decl  %ecx
    incl  %esi

._WalkReallocationTable_Compare:
    cmpl  (%esi), %ebx
    jg    ._WalkReallocationTable_ContinueAfterCheck

    movl  %ebx, %eax
    addl  0x14(%ebp), %eax
    cmpl  (%esi), %eax
    jle   ._WalkReallocationTable_ContinueAfterCheck

    movl  (%esi), %eax
    subl  %ebx, %eax
    addl  0xC(%ebp), %eax
    movl  %eax, (%esi)

._WalkReallocationTable_ContinueAfterCheck:
    addl  $0x4, %esi
    subl  $0x4, %ecx
    
    cmpl  $0x0, %ecx
    jg    ._WalkReallocationTable_Loop

._WalkReallocationTable_Exit:
    popl  %esi
    popl  %ecx
    popl  %ebx

    movl  %ebp, %esp
    popl  %ebp
    retl  $0x10

////////////////////////////////////////////////////////
/// \brief Inject and execute code into remote process
///
/// \param process   The name of the process
/// \param entry     The entry point of the code injected
/// \param code      The start of the code to execute
/// \param length    The length of the code
////////////////////////////////////////////////////////
_ExecuteRemoteCode:
    push %ebp
    movl %esp, %ebp
    subl $0x2F4, %esp

._ExecuteRemoteCode_FindProcess:
    pushl 0x8(%ebp)
    call  _GetProcessID
    test  %eax, %eax
    jz    ._ExecuteRemoteCode_Exit
    pushl %eax                   /* [+1] -> _GetThreadID */

._ExecuteRemoteCode_OpenProcess:
    pushl %eax
    pushl $0xFFFFFFFF
    pushl $(0x0008 | 0x0020)     /* PROCESS_VM_WRITE | PROCESS_VM_OPERATION */ 
    pushl $OPEN_PROCESS
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax
    test  %eax, %eax
    jz    ._ExecuteRemoteCode_Exit

    movl  %eax, -0x4(%ebp)

._ExecuteRemoteCode_AllowWriteOnCode: 
    leal  -0x2F4(%ebp), %eax

    pushl %eax
    pushl $0x80                             /* PAGE_EXECUTE_WRITE_COPY */
    pushl $0x10
    pushl $._ExecuteRemoteCode_Opcode
    pushl $0xFFFFFFFF
    pushl $VIRTUAL_PROTECT_EX
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax
    jmp   ._ExecuteRemoteCode_AllocateRemote

._ExecuteRemoteCode_Opcode:
    .byte 0x68, 0x00, 0x00, 0x00, 0x00
    .byte 0x9C
    .byte 0x60
    .byte 0xE8, 0x00, 0x00, 0x00, 0x00
    .byte 0x61
    .byte 0x9D
    .byte 0xC3
    
._ExecuteRemoteCode_AllocateRemote:
    pushl $0x40                     /* PAGE_EXECUTE_READWRITE */
    pushl $0x00001000               /* MEM_COMMIT */
    pushl 0x14(%ebp)
    pushl $0x000000000
    pushl -0x4(%ebp)
    pushl $VIRTUAL_ALLOC_EX
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax
    movl  %eax, -0x8(%ebp)

._ExecuteRemoteCode_FixReallocationTable:
    pushl 0x14(%ebp)
    call  _MemoryAllocate
    movl  %eax, -0xC(%ebp)

    /* Copy the code opcodes into the new memory */
    pushl 0x14(%ebp)
    pushl %eax
    pushl 0x10(%ebp)
    call  _MemoryCopy

    /* Fix reallocation opcodes */
    pushl 0x14(%ebp)
    pushl -0xC(%ebp)
    pushl -0x8(%ebp)
    pushl 0x10(%ebp)
    call  _WalkReallocationTable

    /* Write it to the remote process */
    pushl $0x000000000
    pushl 0x14(%ebp)
    pushl -0xC(%ebp)
    pushl -0x8(%ebp)
    pushl -0x4(%ebp)
    pushl $WRITE_PROCESS_MEMORY
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    /* Free the memory allocated */
    pushl -0xC(%ebp)
    call  _MemoryFree

._ExecuteRemoteCode_PrepareRemoteThread:
    call  _GetThreadID
    
    /* Open Thread */
    pushl %eax
    pushl $0x000000000
    pushl $(0x0008 | 0x0010 | 0x0002) /* THREAD_GET_CONTEXT |
                                         THREAD_SET_CONTEXT |
                                         THREAD_SUSPEND_RESUME */
    pushl $OPEN_THREAD
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax
    movl  %eax, -0x10(%ebp)

    /* Suspend Thread */
    pushl -0x10(%ebp)
    pushl $SUSPEND_THREAD
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    /* Set CONTEXT_CONTROL to True */
    movl  $(0x10000 | 0x01), -0x2F0(%ebp)

    /* Retrieve ThreadContext */
    leal  -0x2F0(%ebp), %eax
    pushl %eax
    pushl -0x10(%ebp)
    pushl $GET_THREAD_CONTEXT
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

._ExecuteRemoteCode_PatchCave:
    pushl $0x40                     /* PAGE_EXECUTE_READWRITE */
    pushl $0x00001000               /* MEM_COMMIT */
    pushl $0x10
    pushl $0x000000000
    pushl -0x4(%ebp)
    pushl $VIRTUAL_ALLOC_EX
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax
    pushl %eax

    /* Save EIP */
    pushl -0x238(%ebp)
    popl  -0x24(%ebp)

    /* Patch EIP */
    popl  -0x238(%ebp)

    /* Patch the bridge we made for executing our code */
    movl  -0x8(%ebp), %ebx  /* VA: */
    addl  0xC(%ebp), %ebx   /* VA + Relative */
    subl  %eax, %ebx        /* VA + Relative - Patch */
    subl  $0xC, %ebx        /* VA + Relative - Patch - 0xC */
    movl  %ebx, (._ExecuteRemoteCode_Opcode + 0x8)

    movl  -0x24(%ebp), %ebx
    movl  %ebx, (._ExecuteRemoteCode_Opcode + 0x1)

    /* Write it to the remote process */
    pushl $0x000000000
    pushl $0x10
    pushl $._ExecuteRemoteCode_Opcode
    pushl %eax
    pushl -0x4(%ebp)
    pushl $WRITE_PROCESS_MEMORY
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    /* Set the new thread context */
    leal  -0x2F0(%ebp), %eax
    pushl %eax
    pushl -0x10(%ebp)
    pushl $SET_THREAD_CONTEXT
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    /* Resume thread */
    pushl -0x10(%ebp)
    pushl $RESUME_THREAD
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

._ExecuteRemoteCode_Exit:
    movl  %ebp, %esp
    popl  %ebp
    retl  $0x10
