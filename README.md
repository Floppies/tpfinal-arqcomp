# tpfinal-arqcomp
Desarrollo del TP Final de Arquitectura de Computadoras

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

<img src="imagenes/MIPS_Diagram.JPG" alt="Diagrama MIPS" width="800"/>

En este diseño estan contempladas todas las instrucciones requeridas y se han resuelto todos los riesgos.

### Módulos especiales

En el pipeline se encuentran varios registros y multiplexores para poder llevar el control de los datos y de instrucciones. Entre ellos hay ciertos módulos que se analizarán en profundidad a continuación:

#### Registros de etapas

Los registros IF/ID, ID/EX, EX/MEM y MEM/WB sirven para guardar todos los datos que se necesitan guardar en cada ciclo para pasar de una etapa a otra. Estos llevan la informacion de control y ciertos datos cruciales para el funcionamientos del MIPS.

<img src="imagenes/EX_MEM_module.JPG" alt="Ejemplo de modulo de registros de etapa" width="800"/>

#### Unidad de Control (Control Unit)

En esta unidad se decodifica la instruccion. Consiste de una series de señales que actuan como flags y que manejan el control de todas las instrucciones.

<img src="imagenes/Control_unit.PNG" alt="Modulo Control Unit" width="800"/>

Las señales de control significan lo siguiente:
- Halt: Bandera que señala que llego una instrucción HALT por ende el procesador se tiene que detener cuando ésta llegue a la última etapa.
- SizeControl: Es una señal de 5 bits que controla las funciones Store y Load en la memoria de datos.

<img src="imagenes/Size_control.PNG" alt="Funcionamientos SizeControl" width="800"/>

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

<img src="imagenes/Forwarding_unit.PNG" alt="Modulo Forwarding Unit" width="800"/>

Dependiendo de ciertas señales de control, las salidas de esta unidad son selectores de multiplexores que eligen cuales seran los Rs y Rt. Las opciones son los registros que salen del banco, los datos de la etapa EX, MEM o WB. La lógica es la siguiente:

ACA INSERTAR LA TABLA DE DECISIONES

#### Hazard Detection Unit

Esta unidad controla la inserción de "burbujas" para evitar riesgos RAW que surgen por las instrucciones LOAD.

<img src="imagenes/Hazard_detection_unit.PNG" alt="Modulo Hazard Detection Unit" width="800"/>

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











### Memoria de Programa

Esta implementada como una memoria ROM de palabras de 16 bits y un espacio de direccion de 11 bits(2K Words).

<img src="imagenes/EsquematicoPMROM.PNG" alt="PMROM schematic" width="400"/>

### Memoria de Datos

Esta implementada como una memoria RAM de palabras de 16 bits y un espacio de direccion de 11 bits(2K Words). Su lectura y escritura son sincronas al clock.

<img src="imagenes/EsquematicoDMRAM.PNG" alt="DMRAM schematic" width="400"/>

### Modulo UART

Es el mismo modulo implementado en el TP2 aunque sin el receptor. El Baudrate es de 9600 para un reloj de 50MHz. 

<img src="imagenes/EsquematicoUART.PNG" alt="UART schematic" width="800"/>

### Clocking Wizard

Se usa este modulo para tener mayor control en la señal de clock que va a ingresar a los modulos. El parametro que se especifico fue solamente la frecuencia del clock pero se puede jugar con el jitter, los delays, etc. Se setea la salida a 50MHz.

Como necesita un tiempo para estabilizar, hay una señal llamada locked que señala cuando la salida del Clock Wizard es estable. Se toma esta señal como un reset para el resto del circuito. En este caso tarda mas o menos 500 ns.

<img src="imagenes/LockedCW.PNG" alt="Clocking Wizard" width="800"/>

## Testing

Se hicieron varios testbench para probar la funcionalidad de cada modulo en particular. Todos estos tienen una metodologia no automatizada y son bastante simples de entender. Luego se realizo un testbench del sistema completo.

### Testing completo

Para el test completo se redujeron los tamaños de las memorias por simplicidad. Ambas tienen solo 9 lugares (son paramatrizables). El programa que se utilizo para la prueba es el siguente.

``` v
0001100000000100 //LDI 4
0010100000000001 //ADDI 1
0011100000000010 //SUBI 2
0000100000000000 //STO 0
0010000000000000 //ADD 0
0000100000000001 //STO 1
0011000000000000 //SUB 0
0001000000000001 //LD 1
0000000000000000 //HLT
```
El dato que se deberia enviar al ultimo es h0006.

## Analisis

### Simulación de comportamiento

Se puede observar como las instrucciones son terminadas en un solo ciclo de Clock. En el flanco de subida se ingresa la nueva instruccion y los valores de las memorias; y en el flanco de bajada se actualiza el valor del acumulador (o_Data). Ademas, se denota que el acumulador actualiza sus valores correctamente segun lo que esta en el programa de prueba.

<img src="imagenes/SimBehavInst.png" alt="Simulacion del comportamiento, monociclo" width="1000"/>

Aqui se puede visualizar que, una vez terminado el procesamiiento del programa entero y se llega a la instruccion HALT, se manda la se;al tx_done al transmisor UART y este transmite el valor del acumulador (en este caso un h0006).

<img src="imagenes/SimBehavUART.PNG" alt="Simulacion del comportamiento, UART" width="800"/>

### Simulación Post-Sintesis con tiempo

Se ve el mismo resultado del procesamiento de instruccion. Hay mas ruido en la entrada de datos que vienen desde la ROM pero, como todo esta sincronizado al clock y los cambios del pc y acumuludar se hacen en el flanco de bajada donde los datos ya estan estables, no hay errores en los calculos. Se obvio la transmision de la señal por el UART ya que toma mucho mas tiempo en comparacion a los otros procesos.

<img src="imagenes/SimTim.PNG" alt="Simulacion con timing" width="800"/>

### Analisis de Timing

En el analisis de Timing se ve que se cumplen las constraints para una frecuencia de 50MHz.

<img src="imagenes/AnalisisTiming.PNG" alt="Analisis de timing" width="800"/>

El resultado de Worst Negative Slack denota cual es la frecuencia maxima que se puede utilizar en este diseño. La frecuencia máxima es 73 MHz, aproximadamente. El calculo es el siguiente:

<img src="imagenes/MaxFreq.PNG" alt="Frecuencia Maxima" width="400"/>