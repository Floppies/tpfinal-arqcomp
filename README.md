# TP Final - ArqComp
Desarrollo del TP Final de Arquitectura de Computadoras

## Table of contents
- [TP Final - ArqComp](#tp-final---arqcomp)
  - [Table of contents](#table-of-contents)
  - [Consigna](#consigna)
  - [Requerimientos](#requerimientos)
    - [Etapas a implementar](#etapas-a-implementar)
    - [Instrucciones a implementar](#instrucciones-a-implementar)
    - [Riesgos](#riesgos)
    - [Debug Unit](#debug-unit)
    - [Otros Requerimientos](#otros-requerimientos)
  - [Diseño del MIPS](#diseño-del-mips)
    - [Módulos especiales](#módulos-especiales)
      - [Registros de etapas](#registros-de-etapas)
      - [Unidad de Control (Control Unit)](#unidad-de-control-control-unit)
      - [Unidad de Cortocircuito (Forwarding Unit)](#unidad-de-cortocircuito-forwarding-unit)
      - [Hazard Detection Unit](#hazard-detection-unit)
      - [Módulos con modificaciones especiales para ciertas instrucciones](#módulos-con-modificaciones-especiales-para-ciertas-instrucciones)
    - [Solución de Riesgos](#solución-de-riesgos)
      - [Riesgos RAW (LDE)](#riesgos-raw-lde)
      - [Riesgos de Control](#riesgos-de-control)
  - [Diseño de la Debug Unit](#diseño-de-la-debug-unit)
    - [Debug Controller](#debug-controller)
    - [Send Controller](#send-controller)
  - [Diseño Completo](#diseño-completo)
  - [Testing](#testing)
    - [Testeo de instrucciones especiales](#testeo-de-instrucciones-especiales)
    - [Testeo de riesgos solucionados](#testeo-de-riesgos-solucionados)
    - [Análisis de Tiempo](#análisis-de-tiempo)
  - [Bibliografía](#bibliografía)

## Consigna

Implementar el pipeline de 5 etapas del procesador MIPS.

## Requerimientos

### Etapas a implementar

- **IF (Instruction Fetch):** Búsqueda de la instrucción en la memoria de programa.
- **ID (Instruction Decode):** Decodificación de la instrucción y lectura de registros.
- **EX (Excecute):** Ejecución de la instrucción.
- **MEM (Memory Access):** Lectura o escritura desde/hacia la memoria de datos.
- **WB (Write back):** Escritura de resultados en los registros.

### Instrucciones a implementar

- **R-type**
SLL, SRL, SRA, SLLV, SRLV, SRAV, ADDU, SUBU, AND, OR, XOR, NOR, SLT

- **I-Type**
LB, LH, LW, LWU, LBU, LHU, SB, SH,SW, ADDI, ANDI, ORI, XORI, LUI, SLTI, BEQ, BNE, J, JAL

- **J-Type**
JR, JALR

Todas estas instrucciones estas especificadas en el ISA del MIPS.

### Riesgos

El procesador debe tener soporte para los siguientes tipos:
- Estructurales. Se producen cuando dos instrucciones tratan de utilizar el mismo recurso en el mismo ciclo.
- De datos. Se intenta utilizar un dato antes de que esté preparado. Mantenimiento del orden estricto de lecturas y escrituras.
- De control. Intentar tomar una decisión sobre una condición todavía no evaluada.

Para dar soporte a los riesgos nombrados se debe implementar las dos unidades riesgos:
- Unidad de Cortocircuitos (Forwarding Unit)
- Unidad de Detección de Riesgos (Hazard Detection Unit)

### Debug Unit

Se debe simular una unidad de Debug que envíe información hacia y desde el procesador mediante UART. Se debe enviar a través de la UART:
- Contenido de los 32 registros
- PC
- Contenido de la memoria de datos usada
- Cantidad de ciclos de clock desde el inicio

El funcionamiento de la Debug Unit consiste en:
- Antes de estar disponible para ejecutar, el procesador está a la espera para recibir un programa mediante la Debug Unit.
- Una vez cargado el programa, debe permitir **dos modos de operación**:
    - Continuo: Se envía un comando a la FPGA por la UART y esta inicia la ejecución del programa hasta llegar al final del mismo (Instrucción HALT). Llegado ese punto se muestran todos los valores indicados en pantalla.
    - Paso a paso: Enviando un comando por la UART se ejecuta un ciclo de Clock. Se debe mostrar a cada paso los valores indicados.

### Otros Requerimientos

- El programa a ejecutar debe ser cargado en la memoria de programa mediante un archivo ensamblado.
- Debe implementarse un programa ensamblador que convierte código assembler de MIPS a codigo de instruccion.
- Debe transmitirse ese programa mediante interfaz UART antes de comenzar a ejecutar.

## Diseño del MIPS

El diseño del pipeline final con las cinco etapas es el siguiente:

<img src="imagenes/MIPS_Diagram.jpg" alt="Diagrama MIPS" width="800"/>

En este diseño estan contempladas todas las instrucciones requeridas y se han resuelto todos los riesgos.

### Módulos especiales

En el pipeline se encuentran varios registros y multiplexores para poder llevar el control de los datos y de instrucciones. Entre ellos hay ciertos módulos que se analizarán en profundidad a continuación:

#### Registros de etapas

Los registros IF/ID, ID/EX, EX/MEM y MEM/WB sirven para guardar todos los datos que se necesitan guardar en cada ciclo para pasar de una etapa a otra. Estos llevan la informacion de control y ciertos datos cruciales para el funcionamientos del MIPS.

<img src="imagenes/EX_MEM_module.JPG" alt="Ejemplo de modulo de registros de etapa" width="800"/>

#### Unidad de Control (Control Unit)

En esta unidad se decodifica la instruccion. Consiste de una series de señales que actuan como flags y que manejan el control de todas las instrucciones.

<img src="imagenes/Control_Unit.PNG" alt="Modulo Control Unit" width="800"/>

Las señales de control significan lo siguiente:
- Halt: Bandera que señala que llego una instrucción HALT por ende el procesador se tiene que detener cuando ésta llegue a la última etapa.
- SizeControl: Es una señal de 5 bits que controla las funciones Store y Load en la memoria de datos.

<img src="imagenes/Size_control.jpg" alt="Funcionamientos SizeControl" width="200"/>

- BNE: Bandera que levanta una instrucción BNE (Branch Not Equal).
- BEQ: Bandera que levanta una instrucción BEQ (Branch Equal).
- JumpI: Bandera que levanta una instrucción de salto incondicional.
- SelectAddr: Señal de 2 bits que elige la direccipon del salto ya sea el contenido de un registro, un jump target address o una branch address.
- Link: Bandera que señaliza que hay que guardar el PC actual y hacer un salto. Es levantada por las instrucciones JAL y JALR.
- RegWrite: Bandera que indica que se va a escribir en el banco de registros.
- MemtoReg: Bandera que indica que lo que se va a escribir en el banco de registros es un dato de la memoria o el resultado de la ALU.
- MemRead: Bandera que indica que se va a leer la memoria de datos.
- MemWrite: Bandera que indica que se va a escribir en la memoria de datos.
- ALUSrc: Bandera que indica si un operando de la ALU va a ser el immediate o un registro.
- ALUOp: Señal de 3 bits que completa la información que necesita el controlador de la ALU para poder saber que operación tiene que realizar la ALU.
- RegDst: Señal de 2 bits que indica cuál será el registro de destino: el rd, el rt o el registro 31 (para la instruccion JAL y JARL).

Dependiendo la instrucción se setean de manera diferente. Un ejemplo sería el siguiente:

ACA INSERTAR UNA TABLA O UNA IMAGEN CON LAS SEÑALES DE CONTROL

#### Unidad de Cortocircuito (Forwarding Unit)

Esta unidad controla los datos que van a ser los operandos de la instrucción que se encuentra en la etapa ID. Sirve para eliminar los reisgos RAW que se generan a utilizar un procesador segmentado.

<img src="imagenes/Forwarding_unit.PNG" alt="Modulo Forwarding Unit" width="400"/>

Dependiendo de ciertas señales de control, las salidas de esta unidad son selectores de multiplexores que eligen cuales seran los Rs y Rt. Las opciones son los registros que salen del banco, los datos de la etapa EX, MEM o WB. La lógica es la siguiente:

ACA INSERTAR LA TABLA DE DECISIONES

#### Hazard Detection Unit

Esta unidad controla la inserción de "burbujas" para evitar riesgos RAW que surgen por las instrucciones LOAD.

<img src="imagenes/Hazard_detection_unit.PNG" alt="Modulo Hazard Detection Unit" width="400"/>

 Mientras no se detecte ningún riesgo, el procesador funciona normalmente (writePC = 1). Cuando hay que esperar que se cargue un dato, se inserta la burbuja. Es decir que el PC no se actualiza al igual que todos los registros de IF/ID y los registros de ID/EX se cargan con 0s (burbuja).

``` v
    always  @(*)
        begin
            if((ID_EX_memread)&&((ID_EX_rd == IF_ID_rs)|| (ID_EX_rd == IF_ID_rt)))
            begin
                write_pc    =   0   ;
                stall_ID    =   1   ;
                nop_EX      =   1   ;
            end
            else
            begin
                write_pc    =   1   ;
                stall_ID    =   0   ;
                nop_EX      =   0   ;
            end
        end
```

#### Módulos con modificaciones especiales para ciertas instrucciones

- Para las instrucciones JAL y JARL se agrega el flag Link que sirve para que en vez de tomar el immediate como segundo opoerando de la ALU se tome la siguiente instrucción y esta direccion se la que se guarde en el registro 31 (el último registro del banco).
- Para manejar los loads y stores con tamaños diferentes se agrega una entrada de Size Control a la memoria que permite guardar y cargar datos con tamaños de WORD, HALFWORD y BYTE.
- La señal que permite actualizar el registro del Program Counter tiene la lógica de solo ser 1 cuando no hay una señal activa de HALT y la Unidad de Detección de Riesgos permite que se actualiza el PC.

### Solución de Riesgos

#### Riesgos RAW (LDE)

Estos riesgos son solucionados mediante dos métodos:
- Forwarding o corto-circuito: Cuando una instrucción de tipo I o R en el que los rt o rs correspondan a un rd de una instrucción precedente que no sea un LOAD (es decir que ya tenga su resultado en la etapa EX) la unidad de cortocircuito trae los datos necesarios para evitar detener el pipeline o tener datos incoherentes.
- Stalls y burbujas: Cuando una intrucción tipo I o R cuyo rs o rt depende de un rd modificado por un Load precedente, se tiene que "parar" el pipeline e introduciendo una burbuja. El dato necesitado del Load se encuentre en la etapa MEM.

El siguente es un ejemplo:

```assembly
...
lw r1, 0(r2)
sub r2, r1, r3
add r2, r1, r4
...
```

<img src="imagenes/load_example.PNG" alt="Ejemplo load" width="400"/>

En esta situación, en el tercer ciclo la instrucción **sub** va a usar el registro r1 modificado por el **lw** pero este dato recién va a estar listo en el siguiente ciclo cuando **lw** este en la etapa de MEM. Por ende, este diseño retiene a la instrucción **sub** en la etapa ID, el PC no sigue a la siguiente instrucción y, en la etapa EX se inserta una burbuja, es decir una instrucción que no haga nada. Por ende, cada load retrasa el pipeline un ciclo.

#### Riesgos de Control

Estos riesgos surgen cuando hay un salto en el código, como en el siguiente ejemplo:

```assembly
...
sub r2, r3, r4
beq r1, r2, loop
add r4, r5 ,r6

loop:
xor r3,r4,r5
...
```

<img src="imagenes/jump_example.PNG" alt="Ejemplo jump" width="400"/>

En este caso, la instrucción **beq** indica que, si r1 y r2 son iguales, la próxima instrucción que debe ejecutarse con es el **add** siguiente sino el **xor** que esta en la etiqueta **loop**. En este diseño, **beq** puede detectar el salto en el segundo ciclo, cuando esta en la etapa ID. Los pasos que se toma en este punto, el ciclo 3, es que para el próximo ciclo se haga un "flush" en la etapa ID (es decir que se quiten todos los datos de la instrucción **add** que ya no tiene que ser ejecutada) y que se elija la instrucción correcta, el **xor**. En consecuencia de esto, entre la instrucción **beq** y **xor** va a haber un burbuja. Por ende, cada salto retrasa el pipeline un ciclo.

## Diseño de la Debug Unit

INSERTAR DIAGRAMA DE BLOQUES DEL DISEÑO

La unidad de Debuggeo consiste de 3 módulos:
- Debug Controller: Es la máquina de estados principal que se encarga de recibir el programa, recibir el modo de operación, correr el programa e iniciar el envió de datos.
- Send Controller: Es una máquina de estados secundaria que se encarga de mandar todos los datos requeridos y al finalizar enviar una señal al Debug Controller.
- Clock Control: Se encarga de contar todos los ciclos de clock en los cuales el procesador está funcionando y de darle el pulso de trabajo.

*La unidad de UART que se encarga de recibir y enviar los datos está separada de toda esta lógica y es exactamente igual que la realizada en el segundo trabajo práctico de la materia.*

### Debug Controller

<img src="imagenes/debug_cotrol_states.PNG" alt="debug control" width="800"/>

Los estados son los siguientes:
- E0 - RECVPROG - 0001 : Recibiendo el programa. Este mismo es enviado en líneas de 32 bits. Se sale de este estado al recibir la última instrucción que debería ser una HALT.
- E1 - RECVMODE - 0010 : Recibe el comando para saber el modo de operación que desea el usuario. Este puede ser Paso a Paso (cuando recibo un 32h10001000) o Continuo (cuando recibo cualquier otro dato).
- E2 - RUNPROG - 0100 : El procesador empieza a funcionar ya sea por un ciclo o hasta llegar a la instrucción HALT.
- E3 - SENDDATA - 1000 : Se levanta una flag para que el Send Controller empiece a enviar los datos. Cuando este responde una señal de que el envió terminó, se vuelve al estado inicial.

El diagrama del módulo es el siguiente:

INSERTAR DIAGRAMA DE BLOQUE

### Send Controller

<img src="imagenes/send_control_states.PNG" alt="send control" width="800"/>

Los estados son los siguientes:
- E0 - WAIT - 00001 : La máquina de estado está a la espera de que el Debug Controller levanta la flag para enviar los datos.
- E1 - SENDPC - 00010 : Se envía el contenido del registro PC, es decir la dirección de la última instrucción ejecutada.
- E2 - SENDDM - 00100 : Se envía todo el contenido de la memoria de datos.
- E3 - SENDRB - 01000 : Se envía todo el contenido de la memoria de datos.
- E4 - SENDCLK - 10000 : Se envía la cantidad de clocks que guarda el Clock Control.

El diagrama del módulo es el siguiente:

INSERTAR DIAGRAMA DE BLOQUE

## Diseño Completo

El Diagrama completo esta formado por:

- El MIPS segmentado. (En este diagrama esta señalizado con el color verde y esta simplificado).
- Las memorias, señalizadas en el diagrama con el color magenta. Son 2 memorias RAM que incluyen a la memoria de instrucciones y la memoria de datos, y el banco de registros.
- La unidad UART de color amarillo. Son los mismos módulos usados en el Trabajo N2.
- La Debug Unit en color azul. Consta del módulo de Control del debugging, la unidad que controla el envio y el control del clock.
- También, en color violeta, está el módulo Clock Wizard.

<img src="imagenes/Diagrama_Completo.JPG" alt="Diagrama completo" width="800"/>

## Testing

### Testeo de instrucciones especiales

### Testeo de riesgos solucionados

### Análisis de Tiempo

## Bibliografía

ACA HAY QUE PONER LINKS