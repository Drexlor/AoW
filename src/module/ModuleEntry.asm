;//////////////////////////////////////////////////////////////////////
;/// This file is subject to the terms and conditions defined in    ///
;/// file 'LICENSE.txt', which is part of this source code package. ///
;//////////////////////////////////////////////////////////////////////
[SEGMENT .text]

    ;////////////////////////////////////////////////////
    ;/// Define all modules includes
    ;////////////////////////////////////////////////////
    %include 'src/module/ModuleSpeedhack.asm'

    ;////////////////////////////////////////////////////
    ;/// Define foundation
    ;////////////////////////////////////////////////////
    %ifdef FND_MUNDOS_PERDIDOS
        %include 'src/foundation/MundosPerdidosAO/Foundation.asm'
    %elif defined(FND_HISPANO)
        %include 'src/foundation/HispanoAO/Foundation.asm'
    %endif

;////////////////////////////////////////////////////
;/// \brief Initialize foundation enviroment
;////////////////////////////////////////////////////
InitializeModule:
    PUSH EBP
    MOV  EBP, ESP
    
    ;////////////////////////////////////////////////////
    ;/// Initialize SpeedHACK module
    ;////////////////////////////////////////////////////
    CALL InitializeSpeedhackModule

    ;////////////////////////////////////////////////
    ;/// Initialize Foundation module
    ;////////////////////////////////////////////////
    CALL InitializeFoundation

    MOV  ESP, EBP
    POP  EBP
    RET