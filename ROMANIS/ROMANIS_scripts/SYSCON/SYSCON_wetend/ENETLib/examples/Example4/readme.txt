/******************** (C) COPYRIGHT 2007 STMicroelectronics ********************
* File Name          : Readme.txt
* Author             : MCD Application Team
* Version            : V2.0
* Date               : 12/07/2007
* Description        : Description of the ENET Example 4.
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
gives an example how to use the Auto-Negotiation process to configure the 
operation mode and how to enable the PHY interrupt. The interrupt enabled is the
Auto-Negociation complete PHY interrupt.
The example permits to configure the operating method using the Auto-Negotiation 
process. 


Directory contents
==================
91x_conf.h  Library Configuration file
main.c      Main program
91x_it.c    Interrupt handlers
91x_it.h    Interrupt handlers headers
hw_config.c ENET Hardware Configuration & Setup
hw_config.h Header of ENET Hardware Configuration & Setup
lcd.c       LCD driver for the Liquid Crystal Display Module of the STR910 EVAL

Hardware environment
====================
- This example is running on STMicroelectronics STR910-EVAL board (MB460)
  and can be easily tailored to any other hardware
- Connect your PC to the STR91x eval-board using an Ethernet crossover 
  cable.
- Change your PC Network Card configuration to auto detect Speed & Duplex: in the 
  card network properties click on Advanced and choose auto detect in Speed 
  & Duplex property.  

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
  + 91x_wiu.c
  + 91x_vic.c      
- Link all compiled files and load your image into Flash
- Run the example.
- The LCD will display the result of the Auto-Negotiation process.
- If you change the operating mode of your PC (for example to 100Mb/s or to 10Mb/s) 
  the LCD will display the new resulting mode.


******************* (C) COPYRIGHT 2007 STMicroelectronics *****END OF FILE****
