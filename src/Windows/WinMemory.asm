//////////////////////////////////////////////////////////////////////
/// This file is subject to the terms and conditions defined in    ///
/// file 'LICENSE.txt', which is part of this source code package. ///
///                                                                ///
/// \author Wolftein <wolftein1@gmail.com> @2013                   ///
//////////////////////////////////////////////////////////////////////
.section .text

////////////////////////////////////////////////////////
/// \brief Build the memory heap of the shellcode [+]
////////////////////////////////////////////////////////
_InitializeMemory:
    pushl %ebp
    movl  %esp, %ebp
    subl  $0x4, %esp

._InitializeMemory_AllowWriteOnCode:    
    pushl %esp
    pushl $0x80                         /* PAGE_EXECUTE_WRITE_COPY */
    pushl $0xC
    pushl $__hHeap
    pushl $0xFFFFFFFF
    call  *__fVirtualProtect

    pushl $0x20000                      /* Max expand: 1mb */
    pushl $0x1000                       /* Initial: 4kb    */
    pushl $0x00040000                   /* HEAP_CREATE_ENABLE_EXECUTE */
    pushl $HEAP_CREATE  
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax
    movl  %eax, __hHeap                 /* __hHeap = HANDLER */

    pushl $RTL_ALLOCATE_HEAP
    pushl __hNTDLL
    call  _GetProcAddress
    movl  %eax, __fHeapAllocate

    pushl $HEAP_FREE
    pushl __hKernel32
    call  _GetProcAddress
    movl  %eax, __fHeapFree
    
._InitializeMemory_RemoveWriteOnCode:
    pushl %esp
    pushl 0x4(%esp)
    pushl $0xC
    pushl $__hHeap
    pushl $0xFFFFFFFF
    call  *__fVirtualProtect

    movl  %ebp, %esp
    popl  %ebp
    retl

////////////////////////////////////////////////////////
/// \brief Destroy the heap allocated [+]
////////////////////////////////////////////////////////
_MemoryDestroy:
    pushl %ebp
    movl  %esp, %ebp

    pushl __hHeap
    pushl $HEAP_DESTROY 
    pushl __hKernel32
    call  _GetProcAddress
    call  *%eax

    movl  %ebp, %esp
    popl  %ebp
    retl

////////////////////////////////////////////////////////
/// \brief Allocates new memory [+]
///
/// \param size The length of the memory
///
/// \return A pointer to the memory allocated
////////////////////////////////////////////////////////
_MemoryAllocate:
    pushl %ebp
    movl  %esp, %ebp

    pushl 0x8(%ebp)
    pushl $0x00000008               /* HEAP_ZERO_MEMORY */
    pushl __hHeap
    call  *__fHeapAllocate

    movl  %ebp, %esp
    popl  %ebp
    retl  $0x4

////////////////////////////////////////////////////////
/// \brief Deallocates memory [+]
///
/// \param memory A pointer to the memory allocated
////////////////////////////////////////////////////////
_MemoryFree:
    pushl %ebp
    movl  %esp, %ebp

    pushl 0x8(%ebp)
    pushl $0x0
    pushl __hHeap
    call  *__fHeapFree

    movl  %ebp, %esp
    popl  %ebp
    retl  $0x4

////////////////////////////////////////////////////////
/// \brief Copy memory from source to destination [+]
///
/// \param source      The source of the memory
/// \param destination The destination of the memory
/// \param size        The length of the memory
////////////////////////////////////////////////////////
_MemoryCopy:
    pushl %ebp
    movl  %esp, %ebp
    
    pushl %esi
    pushl %edi
    pushl %ecx

    movl  0x8(%ebp), %esi
    movl  0xC(%ebp), %edi
    movl  0x10(%ebp), %ecx
    rep   movsb

    popl  %ecx
    popl  %edi
    popl  %esi

    movl  %ebp, %esp
    popl  %ebp
    retl  $0xC

////////////////////////////////////////////////////////
///!< Heap handler
////////////////////////////////////////////////////////
__hHeap:
    .byte    0x90, 0x90, 0x90, 0x90

////////////////////////////////////////////////////////
///!< Heap allocate function
////////////////////////////////////////////////////////
__fHeapAllocate:
    .byte    0x90, 0x90, 0x90, 0x90

////////////////////////////////////////////////////////
///!< Heap free function
////////////////////////////////////////////////////////
__fHeapFree:
    .byte    0x90, 0x90, 0x90, 0x90
