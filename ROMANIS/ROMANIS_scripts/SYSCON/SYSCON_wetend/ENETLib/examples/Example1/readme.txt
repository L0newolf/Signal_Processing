/******************** (C) COPYRIGHT 2007 STMicroelectronics ********************
* File Name          : Readme.txt
* Author             : MCD Application Team
* Version            : V2.0
* Date               : 12/07/2007
* Description        : Description of the ENET Example 1.
********************************************************************************
* THE PRESENT SOFTWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
* WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE TIME.
* AS A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY DIRECT,
* INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING FROM THE
* CONTENT OF SUCH SOFTWARE AND/OR THE USE MADE BY CUSTOMERS OF THE CODING
* INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
*******************************************************************************/

Example description
===================
This example provides a short description of how to use the ENET peripheral and
gives an example how to work with multi-descriptors for Rx/Tx.
The example permits to send three packets consecutively and recover them at the 
reception buffers using the PHY loopback mode.

Directory contents
==================
91x_conf.h  Library Configuration file
main.c      Main program
91x_it.c    Interrupt handlers
91x_it.c    Interrupt handlers headers
hw_config.c ENET Hardware Configuration & Setup
hw_config.h Header of ENET Hardware Configuration & Setup

Hardware environment
====================
This example is running on STMicroelectronics STR910-EVAL board (MB460)
and can be easily tailored to any other hardware
 
How to use it
=============
In order to make the program work, you must do the following :
- Create a project and setup all your toolchain's start-up files
- Compile the directory content files and required Library files :
  + 91x_lib.c
  + 91x_enet.c
  + 91x_gpio.c
  + 91x_scu.c
  + 91x_fmi.c    
- Link all compiled files and load your image into Flash
- Run the example
- Stop running and watch the reception buffers: buffer1, buffer2 and buffer3.

******************* (C) COPYRIGHT 2007 STMicroelectronics *****END OF FILE****
