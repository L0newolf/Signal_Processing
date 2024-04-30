/******************** (C) COPYRIGHT 2006 STMicroelectronics ********************
* File Name          : Readme.txt
* Author             : MCD Application Team
* Date First Issued  : 05/18/2006 : Version 1.0
* Description        : This sub-directory contains all the user-modifiable files 
*                      needed to create a new project linked with the STR91x library
*                      and working with IAR Embedded Workbench for ARM software 
*                      toolchain (version 4.41A)
********************************************************************************
* History:
* 05/22/2007 : Version 1.2
* 05/24/2006 : Version 1.1
* 05/18/2006 : Version 1.0
********************************************************************************
* THE PRESENT SOFTWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
* WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE TIME.
* AS A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY DIRECT,
* INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING FROM THE
* CONTENT OF SUCH SOFTWARE AND/OR THE USE MADE BY CUSTOMERS OF THE CODING
* INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
*******************************************************************************/

Directory contents
===================
- project .ewd/.eww/.ewp: A pre-configured project files with the provided library 
                          structure that produces a Flash or RAM executable 
                          image with IAR Embedded Workbench.

- 91x_init.s: This module initializes stack pointers,RAM size (96K) ,CP15 registers 
              and finally branches to "main" in the C library (which eventually 
              calls main()).
              It offers also the ability to select the clock source frequency to 
              be OSC, RTC or PLL (@96Mhz by default). 
             
Note:
====
 When booting from bank1, use OSC as the default clock source . 
 If you want to run  CPU @ 66 MHz or higher, PLL configuration might
 be done out in C code and the  Flash wait states configuration should be 
 executed from SRAM  to avoid read while writing in same bank.


- 91x_vect.s: This file contains exception vectors. 
              It is written in assembler and initializes the exception vectors.

- lnkarm_flash.xcl: This file is the IAR specific linking and loading file used 
                    to load in Flash and execute code and variables to target 
                    memories and regions. You can customize this file to your need.

- lnkarm_ram.xcl: This file is the IAR specific linking and loading file used to 
                  load in RAM and execute code and variables to target memories 
                  and regions. You can customize this file to your need.
                  
Note
====
The files listed above should be only used with IAR Embedded Workbench for ARM 
software toolchain (version 4.41A).


COMPATIBILITY
=============
This project is compatible with EWARM 4.41A version and if you have a previous 
version you have to re-configure the project.


How to use it
=============
In order to make the program work, you must do the following:

- double click on Project.eww file.
- load project image: Project -> Debug(ctrl+D)
- Run program : Debug->Go(F5)


******************* (C) COPYRIGHT 2006 STMicroelectronics *****END OF FILE******
