//////////////////////////////////////////////////////////////////////
/// This file is subject to the terms and conditions defined in    ///
/// file 'LICENSE.txt', which is part of this source code package. ///
///                                                                ///
/// \author Wolftein <wolftein1@gmail.com> @2013                   ///
//////////////////////////////////////////////////////////////////////
.section .text

////////////////////////////////////////////////////////
/// \brief Initialize this module [+]
////////////////////////////////////////////////////////
_InitializeWinAPI:
    pushl %ebp
    movl  %esp, %ebp
    subl  $0xC, %esp

    pushl $KERNEL_MODULE
    call  _GetModuleHandle
    movl  %eax, -0x8(%ebp)

._InitializeWinAPI_AllowWriteOnCode: 
    leal  -0x4(%ebp), %eax

    pushl %eax
    pushl $0x80                             /* PAGE_EXECUTE_WRITE_COPY */
    pushl $0x1C
    pushl $__hKernel32
    pushl $0xFFFFFFFF
    pushl $VIRTUAL_PROTECT_EX
    pushl -0x8(%ebp)
    call  _GetProcAddress
    movl  %eax, -0xC(%ebp)
    call  *%eax

    pushl -0xC(%ebp)
    popl  __fVirtualProtect  

    pushl -0x8(%ebp)
    popl  __hKernel32            
._InitializeWinAPI_Procedures:
    pushl $LSTRCAT
    pushl __hKernel32
    call  _GetProcAddress
    movl  %eax, __fStringCat

    pushl $LSTRCPY
    pushl __hKernel32
    call  _GetProcAddress
    movl  %eax, __fStringCopy

    pushl $LSTRLEN
    pushl __hKernel32
    call  _GetProcAddress
    movl  %eax, __fStringLen

    pushl $LSTRCMP
    pushl __hKernel32
    call  _GetProcAddress
    movl  %eax, __fStringCompare

._InitializeWinAPI_FindNTDLL:
    pushl $NTDLL_MODULE
    call  _GetModuleHandle
    movl  %eax, __hNTDLL

._InitializeWinAPI_RemoveWriteOnCode:
    leal  -0x4(%ebp), %eax

    pushl %eax
    pushl -0x4(%ebp)
    pushl $0x1C
    pushl $__hKernel32
    pushl $0xFFFFFFFF
    call  *__fVirtualProtect

    movl  %ebp, %esp
    popl  %ebp
    retl

////////////////////////////////////////////////////////
/// \brief Gets the module handle of a library [+]
///
/// \param id The identifier of the module
///
/// \return The handle of the module 
////////////////////////////////////////////////////////
_GetModuleHandle:
    pushl %ebp
    movl  %esp, %ebp

    pushl %edi
    pushl %esi
    pushl %ebx

    movl  %fs:(0x30), %ebx               /* Process enviroment block */
    movl  0x0C(%ebx), %ebx               /* Peb->Ldr */
    movl  0x14(%ebx), %ebx               /* Peb->Ldr.InMemoryOrder.Flink 1st */

._GetModuleHandle_Loop:
    testl %ebx, %ebx                     /* No more modules to export */
    jz    ._GetModuleHandle_CalculateEnd

    movl  0x28(%ebx), %esi               /* Module name (UNICODE) */
    movzx 0x26(%ebx), %ecx               /* Set ECX to the length */
    xorl  %edi, %edi

._GetModuleHandle_Generate:
    xorl  %eax, %eax
    lodsb
    testb %al, %al
    jz    ._GetModuleHandle_ZeroUnicode

    rorl  $0xD, %edi
    addl  %eax, %edi

._GetModuleHandle_ZeroUnicode:
    loop  ._GetModuleHandle_Generate

._GetModuleHandle_Compare:
    cmpl  %edi, 0x8(%ebp)
    je    ._GetModuleHandle_Found

    movl  (%ebx), %ebx                   /* Walk to the next module */
    jmp   ._GetModuleHandle_Loop

._GetModuleHandle_Found:
    movl  0x10(%ebx), %eax               /* EAX = Base module address */

._GetModuleHandle_CalculateEnd:
    popl  %ebx
    popl  %esi
    popl  %edi

    movl  %ebp, %esp
    popl  %ebp
    retl  $0x4

////////////////////////////////////////////////////////
/// \brief Gets the function from Kernel32.dll module [+]
///
/// \param module The module to search from
/// \param id The identifier of the function
///
/// \return The address of the function
////////////////////////////////////////////////////////
_GetProcAddress:
    pushl %ebp
    movl  %esp, %ebp

    pushl %edi
    pushl %esi
    pushl %edx
    pushl %ebx

    movl  0x08(%ebp), %ebx               /* Parameter: #1 */
    movl  0x3C(%ebx), %eax               /* Get NT header rva */
    leal  0x78(%ebx, %eax), %esi         /* Get the export table rva */
    lodsl
    pushl (%esi)                         /* [+1] */

    addl  %ebx, %eax
    pushl %eax                           /* [+2] */
    movl  0x18(%eax), %ecx               /* Extract the number of exported */
    movl  0x20(%eax), %edx               /* Export name address table rva */
    addl  %ebx, %edx                     /* EAX = export name address table */

._GetProcAddress_Calculate:
    
    decl  %ecx
    movl  (%edx, %ecx, 0x04), %esi       /* Get the rva of the export name */
    addl  %ebx, %esi                     /* Calculate the virtual address */
    xorl  %edi, %edi

._GetProcAddress_Generate:
    xorl  %eax, %eax
    lodsb
    cmpb  %ah, %al
    je    ._GetProcAddress_Compare
    rorl  $0xD, %edi
    addl  %eax, %edi
    jmp   ._GetProcAddress_Generate

._GetProcAddress_Compare:
    cmpl  %edi, 0xC(%ebp)
    jnz   ._GetProcAddress_Calculate

    popl  %edi                           /* [-2] */
    movl  0x24(%edi), %edx               /* Extract the rva of the ordinals */
    addl  %ebx, %edx                     /* Make it virtual address */
    mov   (%edx, %ecx, 0x02), %cx        /* Extract the current symbol */
    movl  0x1C(%edi), %edx               /* Extract the rva of the address */
    addl  %ebx, %edx                     /* Make it virtual address */
    movl  (%edx, %ecx, 0x04), %eax       /* Get the rva of the exported */
    addl  %ebx, %eax                     /* Make it virtual address */

._GetProcAddress_CalculateEnd:
    popl  %ecx                           /* [-1] */
    pushl %eax                           /* [+1] */
    subl  %edi, %eax
    cmpl  %ecx, %eax                     /* [-1] */
    popl  %eax
    ja    ._GetProcAddress_End
    xchg  %eax, %esi

._GetProcAddress_End:
    popl  %ebx
    popl  %edx
    popl  %esi
    popl  %edi
    
    movl  %ebp, %esp
    popl  %ebp
    retl  $0x8

////////////////////////////////////////////////////////
///!< Kernel32 Handle
////////////////////////////////////////////////////////
__hKernel32:
    .byte    'W', 'o', 'l', 'f'

////////////////////////////////////////////////////////
///!< NTDLL Handle
////////////////////////////////////////////////////////
__hNTDLL:
    .byte    't', 'e', 'i', 'n'

////////////////////////////////////////////////////////
///!< String cat function
////////////////////////////////////////////////////////
__fStringCat:
    .byte    0x89, '0', '9', '/'

////////////////////////////////////////////////////////
///!< String copy function
////////////////////////////////////////////////////////
__fStringCopy:
    .byte    '0', '4', '/', '1'

////////////////////////////////////////////////////////
///!< String len function
////////////////////////////////////////////////////////
__fStringLen:
    .byte    '9', '9', '7', 0x90

////////////////////////////////////////////////////////
///!< String compare function
////////////////////////////////////////////////////////
__fStringCompare:
    .byte    0x91, 0x92, 0x93, 0x94

////////////////////////////////////////////////////////
///!< Virtual Protect function
////////////////////////////////////////////////////////
__fVirtualProtect:
    .byte   0x95, 0x96, 0x97, 0x98
