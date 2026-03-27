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

Implementar el pipeline de 5 etapas un procesador RISC-V.

## Requerimientos

### Etapas a implementar

- **IF (Instruction Fetch):** Búsqueda de la instrucción en la memoria de programa.
- **ID (Instruction Decode):** Decodificación de la instrucción y lectura de registros.
- **EX (Excecute):** Ejecución de la instrucción.
- **MEM (Memory Access):** Lectura o escritura desde/hacia la memoria de datos.
- **WB (Write back):** Escritura de resultados en los registros.

### Instrucciones a implementar

- **R-type**
SLL, SRL, SRA, SLLV, SRLV, SRAV, ADD, SUB, AND, OR, XOR, NOR, SLT, SLTU

- **I-Type**
LB, LH, LW, LWU, LBU, LHU, SB, SH,SW, ADDI, ANDI, ORI, XORI, LUI, SLTI, BEQ, BNE, J, JAL

- **J-Type**
JR, JALR

Todas estas instrucciones estas especificadas en el ISA del MIPS.

**NOTA:** Se soportan 4 pseudo instrucciones.
- `nop` → `0x00000000` = Agrega una burbuja 
- `halt` → `0xFFFFFFFF`
- `j label` → `jal x0, label`
- `jr rs1` → `jalr x0, rs1, 0`

### Riesgos

El procesador debe tener soporte para los siguientes tipos:
- Estructurales: Se producen cuando dos instrucciones tratan de utilizar el mismo recurso en el mismo ciclo.
- De datos: Se intenta utilizar un dato antes de que esté preparado. Mantenimiento del orden estricto de lecturas y escrituras.
- De control: Intentar tomar una decisión sobre una condición todavía no evaluada.

Para dar soporte a los riesgos nombrados se debe implementar las dos unidades riesgos:
- Unidad de Cortocircuitos (Forwarding Unit)
- Unidad de Detección de Riesgos (Hazard Detection Unit)

### Debug Unit

Se debe simular una unidad de Debug que envíe información hacia y desde el procesador mediante UART. Se debe enviar a través de la UART:
- Registros de las etapas del RISC-V
- Contenido de los 32 registros
- Contenido de la memoria de datos (cuyo largo debe ser determinado de antemano)

El funcionamiento de la Debug Unit consiste en:
- Antes de estar disponible para ejecutar, el procesador está a la espera para recibir un programa mediante la Debug Unit.
- Una vez cargado el programa, debe permitir **dos modos de operación**:
    - **Continuo:** Se envía un comando a la FPGA por la UART y esta inicia la ejecución del programa hasta llegar al final del mismo (Instrucción HALT). Llegado ese punto se muestran todos los valores indicados en pantalla.
    - **Paso a paso:** Enviando un comando por la UART se ejecuta un ciclo de Clock. Se debe mostrar a cada paso los valores indicados.

### Otros Requerimientos

- El programa a ejecutar debe ser cargado en la memoria de programa mediante un archivo ensamblado.
- Debe implementarse un programa ensamblador que convierte código assembler de RISC-V a codigo de instruccion.
- Debe transmitirse ese programa mediante interfaz UART antes de comenzar a ejecutar.

## Diseño del RISC-V

El diseño del pipeline final con las cinco etapas es el siguiente:

<img src="imagenes/RISCV_diagram.jpg" alt="Diagrama RISC-V" width="900"/>


En este diseño estan contempladas todas las instrucciones requeridas y se han resuelto todos los riesgos.

### Módulos especiales

En el pipeline se encuentran varios registros y multiplexores para poder llevar el control de los datos y de instrucciones. Entre ellos hay ciertos módulos que se analizarán en profundidad a continuación:

#### Registros de etapas

Los registros IF/ID, ID/EX, EX/MEM y MEM/WB sirven para guardar todos los datos que se necesitan guardar en cada ciclo para pasar de una etapa a otra. Estos llevan la informacion de control y ciertos datos cruciales para el funcionamientos del MIPS.

<img src="imagenes/idexreg.png" alt="Ejemplo de modulo de registros de etapa" width="400"/>

#### Unidad de Control (Control Unit)

En esta unidad se decodifica la instruccion. Consiste de una series de señales que actuan como flags y que manejan el control de todas las instrucciones.

<img src="imagenes/control_unit.PNG" alt="Modulo Control Unit" width="300"/>

Las señales de control significan lo siguiente:
- **Halt_flag**: Bandera que señala que llego una instrucción HALT por ende el procesador se tiene que detener cuando ésta llegue a la última etapa.
- **BNE_flag**: Bandera que levanta una instrucción BNE (Branch Not Equal).
- **BEQ_flag**: Bandera que levanta una instrucción BEQ (Branch Equal).
- **Jump_flag**: Bandera que levanta una instrucción de salto incondicional.
- **Jump_reg**: Indica si el salto es hacia un registro (caso JARL).
- **Link_flag**: Bandera que señaliza que hay que guardar el PC actual y hacer un salto. Es levantada por las instrucciones JAL y JALR.
- **Reg_write**: Bandera que indica que se va a escribir en el banco de registros.
- **Mem_to_Reg**: Bandera que indica que lo que se va a escribir en el banco de registros es un dato de la memoria o el resultado de la ALU.
- **Mem_read**: Bandera que indica que se va a leer la memoria de datos.
- **Mem_write**: Bandera que indica que se va a escribir en la memoria de datos.
- **ALU_source**: Bandera que indica si un operando de la ALU va a ser el immediate o un registro.
- **ALU_op**: Señal de 2 bits que completa la información que necesita el controlador de la ALU para poder saber que operación tiene que realizar la ALU.

Estas señales se setean dependiendo de `i_opcode` que es igual a {funct3,opcode}, que son partes de la instruccion. La tabla de control es la siguiente:

| Instrucción / Tipo        | RegWrite | MemRead | MemWrite | ALUSrc | Branch | Jump | JumpReg | Link | ALUOp |
|--------------------------|----------|---------|----------|--------|--------|------|---------|------|-------|
| R-type (ADD, SUB, AND…)  |    1     |    0    |    0     |   0    |   0    |  0   |    0    |  0   |  10   |
| I-type ALU (ADDI, ANDI…) |    1     |    0    |    0     |   1    |   0    |  0   |    0    |  0   |  10   |
| Load (LB, LH, LW…)       |    1     |    1    |    0     |   1    |   0    |  0   |    0    |  0   |  00   |
| Store (SB, SH, SW)       |    0     |    0    |    1     |   1    |   0    |  0   |    0    |  0   |  00   |
| Branch (BEQ, BNE)        |    0     |    0    |    0     |   0    |   1    |  0   |    0    |  0   |  01   |
| J (pseudo = JAL x0)      |    0     |    0    |    0     |   X    |   0    |  1   |    0    |  0   |  XX   |
| JAL                      |    1     |    0    |    0     |   X    |   0    |  1   |    0    |  1   |  XX   |
| JR (pseudo = JALR x0)    |    0     |    0    |    0     |   1    |   0    |  0   |    1    |  0   |  XX   |
| JALR                     |    1     |    0    |    0     |   1    |   0    |  0   |    1    |  1   |  00   |
| LUI                      |    1     |    0    |    0     |   1    |   0    |  0   |    0    |  0   |  11   |

#### ALU control

<img src="imagenes/alu_control.PNG" alt="Modulo Forwarding Unit" width="400"/>

Esta unidad recibe como entradas a:
- `ALU_op` que proviene de la unidad de control.
- `i_funct` que es `funct7[5], funct3` de la instruccion.

La tabla de verdad es la siguiente:
| ALU_op | i_funct[3] (funct7) | i_funct[2:0] (funct3) | ALU_control | Operación | Instrucciones típicas |
|--------|----------------------|------------------------|-------------|-----------|------------------------|
| `00`   | `x`                  | `xxx`                  | `0000`      | `ADD`     | `load`, `store`, `auipc`, `jalr` |
| `01`   | `x`                  | `xxx`                  | `0001`      | `SUB`     | comparación de branches |
| `10`   | `0`                  | `000`                  | `0000`      | `ADD`     | `add`, `addi` |
| `10`   | `1`                  | `000`                  | `0001`      | `SUB`     | `sub` |
| `10`   | `x`                  | `001`                  | `1000`      | `SLL`     | `sll`, `slli` |
| `10`   | `x`                  | `010`                  | `0110`      | `SLT`     | `slt`, `slti` |
| `10`   | `x`                  | `011`                  | `0111`      | `SLTU`    | `sltu`, `sltiu` |
| `10`   | `x`                  | `100`                  | `0100`      | `XOR`     | `xor`, `xori` |
| `10`   | `0`                  | `101`                  | `1001`      | `SRL`     | `srl`, `srli` |
| `10`   | `1`                  | `101`                  | `1010`      | `SRA`     | `sra`, `srai` |
| `10`   | `x`                  | `110`                  | `0011`      | `OR`      | `or`, `ori` |
| `10`   | `x`                  | `111`                  | `0010`      | `AND`     | `and`, `andi` |
| `11`   | `x`                  | `xxx`                  | `1011`      | `LUI`     | `lui` |


#### Unidad de Cortocircuito (Forwarding Unit)

Esta unidad controla los datos que van a ser los operandos de la instrucción que se encuentra en la etapa ID. Sirve para eliminar los riesgos RAW que se generan a utilizar un procesador segmentado.

<img src="imagenes/forwarding_unit.PNG" alt="Modulo Forwarding Unit" width="400"/>

Dependiendo de ciertas señales de control, las salidas de esta unidad son selectores de multiplexores que eligen cuales seran los Rsx. Las opciones son los registros que salen del banco, los datos de la etapa EX, MEM o WB. La lógica para rs1 es la siguiente:
``` verilog
//  Forwarding rs1 for EX Stage or for JARL
    always  @(*)
    begin
        //  Forwarding from MEM Stage
        if ((EX_MEM_regwrite)&&(EX_MEM_rd == ID_EX_rs1))
            fwdA_tmp    =   MEMSTG  ;
        //  Forwarding from WB Stage
        else if ((MEM_WB_regwrite)&&(MEM_WB_rd == ID_EX_rs1))
            fwdA_tmp    =   WBSTG   ;
        //  No forwarding
        else
            fwdA_tmp    =   REGBNK  ;
    end
```
El multiplexor a la entrada de la ALU depende de un selector conectado a una de las salidas de la unidad de cortocircuito y su comportamiento es el siguiente:
``` verilog
always  @(*)
    begin
        case(sel_addr)
            ALUSTG      :   forw_tmp    =   alustg_data ;
            MEMSTG      :   forw_tmp    =   memstg_data ;
            WBSTG       :   forw_tmp    =   wbstg_data  ;
            default     :   forw_tmp    =   32'hFFFFFFFF;
        endcase
    end
            
    assign  mux_forw    =   forw_tmp    ;
```

#### Hazard Detection Unit

Esta unidad controla la inserción de "burbujas" para evitar riesgos RAW que surgen por las instrucciones LOAD.

<img src="imagenes/hdu.PNG" alt="Modulo Hazard Detection Unit" width="400"/>

 Mientras no se detecte ningún riesgo, el procesador funciona normalmente (writePC = 1). Cuando hay que esperar que se cargue un dato, se inserta la burbuja. Es decir que el PC no se actualiza al igual que todos los registros de IF/ID y los registros de ID/EX se cargan con 0s (burbuja).

``` v
    always  @(*)
    begin
        write_pc    =   1   ;
        IFID_write  =   1   ;
        IDEX_flush  =   0   ;
        IFID_flush  =   0   ;

        // On redirect, kill both younger instructions:
        // - IF/ID holds the instruction in decode
        // - ID/EX would otherwise latch that wrong-path instruction into EX
        IFID_flush  = redirect_ifid & (~stall)   ;
        IDEX_flush  = redirect_idex & (~stall)   ;

        // Stall has priority over redirect
        if (stall) begin
            write_pc    =   0   ;   //freeze PC
            IFID_write  =   0   ;   // freeze IF/ID
            IDEX_flush  =   1   ;   // bubble into EX (zero out control bits in ID/EX)
            IFID_flush  =   0   ;   // keep current ID instruction (do not kill it)
        end
    end
```
- `redirect_ifid` es 1 cuando hay algun salto condicional o incondicional detectado en id.
- `redirect_idex` sucede cuando hay un salto condicional o cuando hay una bandera de salto incondicional en EX. Esto se debe a cuando hay un redirect por JARL.

#### Módulos con modificaciones especiales para ciertas instrucciones

- Para las instrucciones JAL y JARL se agrega el flag Link que sirve para que en vez de tomar el immediate como segundo opoerando de la ALU se tome la siguiente instrucción y esta direccion se la que se guarde en el registro 31 (el último registro del banco).
- Para manejar los loads y stores con tamaños diferentes se utiliza funct3 de las instrucciones que es llevada a traves del pipeline hasta la MEM stage. Esto permite guardar y cargar datos con tamaños de WORD, HALFWORD y BYTE y signed y unsigned.
- Para controlar el halt del pipeline cuyo requerimiento es que la instruccion del HALT llegue hasta la ultima etapa, el pipeline se detenga (`write_pc = 0`) y el pipeline quede con todos sus registros de etapa en 0, se agrego un registro llamada `halt_in_pipe`. La logica para conseguir este comportamiento es la siguiente:
``` v
// Latch: once HALT is in ID, stop fetching new instructions
    always @(posedge i_clk or posedge i_rst)
    begin
        if (i_rst)
        begin
            halt_in_pipe    <=  1'b0    ;
        end
        // Ignore HALT instructions that are being flushed due to a redirect.
        else if (cpu_en & ID_halt & ~IF_ID_flush)
        begin
            halt_in_pipe    <=  1'b1    ;
        end
    end

    // Pipeline empty: assert one cycle after WB_halt deasserts
    always @(posedge i_clk or posedge i_rst)
    begin
        if (i_rst)
        begin
            wb_halt_d   <=  1'b0    ;
            pipe_empty  <=  1'b0    ;
        end
        else
        begin
            wb_halt_d   <=  WB_halt ;
            if (wb_halt_d && ~WB_halt)
                pipe_empty  <=  1'b1    ;
        end
    end
```
- Para controlar la carga de registros en el banco de registros se utiliza un multiplexor con un selector `i_sel = {WB_link, WB_memtoreg}` y tiene el siguiente comportamiento:
```v
always  @(*)
    begin
        case(i_sel)
            ALU     :   data_tmp    =   i_aluresult ;
            MEMDATA :   data_tmp    =   i_wbstgdata ;
            LINK    :   data_tmp    =   i_nextinst  ;
            default :   data_tmp    =   32'hFFFFFFFF;
        endcase
    end
```
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