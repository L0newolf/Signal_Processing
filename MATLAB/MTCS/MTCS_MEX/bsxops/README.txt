This package BSXOPS is used to force MATLAB operators to behave
BSXFUN-like, i.e. operate multi-dimensional array expansion.

A. Installation:
    Copy the unzip files in a directory, run the mfile bsxops_install

B. Usage:
    By default the "bsxfun mode" is disabled. To enable, call bsxops(1).
    Call bsxops(0) to go back to MATLAB original mode.
    
C. Caution: when enabled, this package overloads many MATLAB original
	operators, and it should be used with care.

D. If speed is a concern, due to overhead of overloaded functions, it
   is not recommended to enable bsxops when working with small arrays.

E. Direct use (not overloaded): Explicit bsx (sub)classes objects can be
   created and used. See Example2 below. Note that there is no bsxchar
   subclass built, because Matlab original char class is SEALED. Work
   around is using bsxint16 class instead. Subclasses works on Matlab
   versions that support Object Oriented Programing (OOP), i.e., 2008A
   onward.

F. If bsxops is used in compiled application, bsxops(1) must be called
   before MCC command so as the compiler can detect and include private
   overloaded methods

Author: Bruno Luong <brunoluong@yahoo.com>
History: 18/April/2009 Initial release
         21/April/2009 Correct BUG min/max (two-output call)
	     13/June/2009 subclasses


Example1: OVERLOADED double operators:

>> state=bsxops(1)

state =

     1

>> (1:3) + (4:5)'

ans =

     5     6     7
     6     7     8

>> state=bsxops(0)

state =

     0

>> (1:3) + (4:5)'
??? Error using ==> plus
Matrix dimensions must agree.


Example2, direct use with subclass bsxdouble:

>> a = bsxdouble([1 2 3])

a = 

  bsxdouble

  double data:
     1     2     3

  Methods, Superclasses

>> b = bsxdouble([4 5])'

b = 

  bsxdouble

  double data:
     4
     5

  Methods, Superclasses

>> c = a + b

c = 

  bsxdouble

  double data:
     5     6     7
     6     7     8

  Methods, Superclasses

>> c = double(c)
 
c =

     5     6     7
     6     7     8
