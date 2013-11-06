//////////////////////////////////////////////////////////////////////
/// This file is subject to the terms and conditions defined in    ///
/// file 'LICENSE.txt', which is part of this source code package. ///
///                                                                ///
/// \author Wolftein <wolftein1@gmail.com> @2013                   ///
//////////////////////////////////////////////////////////////////////
.section .text

////////////////////////////////////////////////////////
/// \brief The UniqueID of every function
////////////////////////////////////////////////////////
.EQU GET_COMMAND_LINE,      0x36EF7370        /* GetCommandLineA */
.EQU LOAD_LIBRARY_A,        0xEC0E4E8E        /* LoadLibraryA */
.EQU MESSAGE_BOX_A,         0xBC4dA2A8        /* MessageBoxA   */

.EQU LSTRCAT,               0x68BF596E        /* strcat */
.EQU LSTRCPY,               0x69375973        /* strcpy */
.EQU LSTRLEN,               0x68DF5BA8        /* strlen */
.EQU LSTRCMP,               0x691F596A        /* strcmp */

.EQU HEAP_CREATE,           0xB46984E7        /* HeapCreate */
.EQU RTL_ALLOCATE_HEAP,     0x3E192526        /* RtlAllocateHeap */
.EQU HEAP_FREE,             0x10C32616        /* HeapFree */
.EQU HEAP_DESTROY,          0xCD92833E        /* HeapDestroy */

.EQU VIRTUAL_ALLOC_EX,      0x6E1A959C        /* VirtualAllocEx */
.EQU VIRTUAL_PROTECT_EX,    0x53D98756        /* VirtualProtectEx */

.EQU CREATE_SNAPSHOT,       0xE454DFED        /* CreateToolhelp32Snapshot */
.EQU PROCESS_FIRST,         0x3249BAA7        /* Process32First */
.EQU PROCESS_NEXT,          0x4776654A        /* Process32Next */
.EQU OPEN_PROCESS,          0xEFE297C0        /* OpenProcess */
.EQU CLOSE_HANDLE,          0x0FFD97FB        /* CloseHandle */
.EQU WRITE_PROCESS_MEMORY,  0xD83D6AA1        /* WriteProcessMemory */
.EQU OPEN_THREAD,           0x58C91E6F        /* OpenThread */
.EQU SUSPEND_THREAD,        0x0E8C2CDC        /* SuspendThread */
.EQU GET_THREAD_CONTEXT,    0x68A7C7D2        /* GetThreadContext */
.EQU SET_THREAD_CONTEXT,    0xE8A7C7D3        /* SetThreadContext */
.EQU RESUME_THREAD,         0x9E4A3F88        /* ResumeThread */
.EQU THREAD_FIRST,          0xB83BB6EA        /* Thread32First */
.EQU THREAD_NEXT,           0x86FED608        /* Thread32Next */
////////////////////////////////////////////////////////

////////////////////////////////////////////////////////
/// \brief The UniqueID of every module
////////////////////////////////////////////////////////
.EQU KERNEL_MODULE,         0x8FECD63F
.EQU NTDLL_MODULE,          0xCEF6E822
////////////////////////////////////////////////////////
