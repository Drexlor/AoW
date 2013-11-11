;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]
    ;////////////////////////////////////////////////
    ;/// Define The entry point
    ;////////////////////////////////////////////////
    GLOBAL _EngineEntry;

;////////////////////////////////////////////////////////
;/// ENGINE_COMMON_BEGIN
;////////////////////////////////////////////////////////
_Engine_Common_Begin:

    ;////////////////////////////////////////////////
    ;/// Define all common includes
    ;////////////////////////////////////////////////
    %INCLUDE 'src/EngineAPI.asm'
    %INCLUDE 'src/EngineDisassembler.asm'

;////////////////////////////////////////////////////////
;/// ENGINE_COMMON_END
;////////////////////////////////////////////////////////
_Engine_Common_End:

;////////////////////////////////////////////////////////
;/// FOUNDATION_BEGIN
;////////////////////////////////////////////////////////
_Foundation_Begin:

    ;////////////////////////////////////////////////
    ;/// Define only server includes
    ;////////////////////////////////////////////////
    %INCLUDE 'src/foundation/Foundation.asm'

_Foundation_Entry:
    ;////////////////////////////////////////////////////////
    ;/// Initialize WinAPI Enviroment
    ;////////////////////////////////////////////////////////
    CALL InitializeEnviroment

    ;////////////////////////////////////////////////////////
    ;/// Initialize Disassembler Enviroment
    ;////////////////////////////////////////////////////////
    CALL InitializeDisassembler

    ;////////////////////////////////////////////////////////
    ;/// Initialize Foundation Enviroment
    ;////////////////////////////////////////////////////////
    CALL InitializeFoundation

    ;////////////////////////////////////////////////////////
    ;/// Goodbye
    ;////////////////////////////////////////////////////////
    RET
    
;////////////////////////////////////////////////////////
;/// FOUNDATION_END
;////////////////////////////////////////////////////////
_Foundation_End:

    ;////////////////////////////////////////////////
    ;/// Define only client includes
    ;////////////////////////////////////////////////
    %INCLUDE 'src/EngineInjector.asm'

;////////////////////////////////////////////////////////
;/// \brief Entry point of the application
;////////////////////////////////////////////////////////
_EngineEntry:
    ;////////////////////////////////////////////////////////
    ;/// Initialize WinAPI Enviroment
    ;////////////////////////////////////////////////////////
    CALL InitializeEnviroment

    ;////////////////////////////////////////////////////////
    ;/// Initialize Disassembler Enviroment
    ;////////////////////////////////////////////////////////
    CALL InitializeDisassembler

    INT  3
    NOP
    NOP
    
    ;////////////////////////////////////////////////////////
    ;/// Parse command line and return the name of the process
    ;////////////////////////////////////////////////////////
    CALL ParseCommandLine

    ;////////////////////////////////////////////////////////
    ;/// Inject the code into the game
    ;////////////////////////////////////////////////////////
    PUSH (_Foundation_End - _Engine_Common_Begin)
    PUSH (_Engine_Common_Begin)
    PUSH (_Foundation_Entry - _Engine_Common_Begin)
    PUSH EAX
    CALL ExecuteCodeOnApplication

    ;////////////////////////////////////////////////////////
    ;/// Goodbye
    ;////////////////////////////////////////////////////////
    RET