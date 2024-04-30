/******************************************************************
-PetreM
-rev1.1, 2/12/2004

-PPG
- 01/30/2004 - updated file to include workaround for silicon errata 03-00-0216
- 03-00-0216 : SQSTAT should be read twice sequentially to ensure correct value.

-PM - due to slicon anomalies, CCAIR and CACMD registers are now loaded using j0
*******************************************************************
-this file contains the following macros:

-cache_enable(refresh_rate):
  -it sets a new refresh rate
  -if the cache is enabled, it leaves it enabled.
  -if the cache is not enabled, it enables it in the right way
  -at the end enables the BTB if it was not already enabled
  -this macro should be used as the first line of code in every program

-ini_linear_addressing
  -it writes 0 to all il and kl registers, i.e. sets linear addressing
  -I would use it as the second line of program

-ini_cycle_count and comp_cycle_count:
  -measure the cycles spent between these 2 macros
  -save the result at cycle_count location
  -cycle_count must be declared as a variable in the memory

-comp_program_memory
  -it computes how many 32bit words of code are between
    Benchmark and Benchmark.end labels and saves the result at pm_count
  -pm_count must be declared as a variable

-ini_cycle_count_multiple and comp_cycle_count_multiple
  -measure the cycles spent between these 2 macros, but this time
    saves the results at successive locations in memory
    beginning with cycle_count
  -useful to measure the cycle count of each iteration of
    a loop, for example
-ini_cycle_count_xpr0 and comp_cycle_count_xpr0
  -these macros compute the cycle count as ini_cycle_count and
    comp_cycle_count
  -the difference is the result is saved in xpr0
  -to use these macros, never use xpr0 in your program
  -have the advantage that the cache is not used at all
*******************************************************************/
/*****************************************************
-the execution of the cache commands is finished when
the bit 16 of the corresponding status registers is 0
-the macro wait_cache waits until the cache command
has finished the execution
-the 5 nops introduced at the end of the macro keep
the pipeline clean of eventual cache commands. These
cache commands may stall the processor when executed
before one cache command is ended
*/
#define wait_cache(CASTAT)                          \
.align_code 4;                                      \
_chk_castat?:                                       \
    xr0 = CASTAT;;                                  \
    xbitest r0 by CASTAT_COM_ACTIVE_P;;             \
.align_code 4;                                      \
    if nxseq, jump _chk_castat? (NP);nop;nop;nop;;  \
    nop;;nop;;nop;;nop;;nop;
/*****************************************************
-the macro test_cache_enabled tests the bit14 of the
cache status registers. If this bit is 1, the cache is enabled
and PC jumps to the following tasks. Otherwise,
the cache must be invalidated and then enabled
*/
#define test_cache_enabled(CASTAT, jump_label)\
  xr0 = CASTAT;;                              \
  xbitest r0 by CASTAT_ENBL_P;;               \
  if nxseq, jump jump_label (NP);;             \
	nop;;nop;;nop;;nop;;nop;
/*****************************************************
-the macro invalidate invalidates the cache. To enable
the cache, it must be first invalidated. This operation
basically cleans the cache.
*/
#define invalidate(CCAIR, CACMD, CASTAT)            \
  j0 =  j31 + 0;;								                    \
  CCAIR = j0;;  									                  \
  j0 = j31 + CACMD_INV |                            \
             (127 << CACMD_LEN_P) |                 \
              CACMD_NOSTALL;;                       \
  CACMD = j0;;                                      \
.align_code 4;                                      \
_chk_castat_inv?:                                   \
    xr0 = CASTAT;;                                  \
    xbitest r0 by CASTAT_COM_ACTIVE_P;;             \
.align_code 4;                                      \
    if nxseq, jump _chk_castat_inv? (NP);nop;nop;nop;;\
	nop;;nop;;nop;;nop;;nop;

/*****************************************************
-the macro cache_enable executes the following operations:
  -sets a new refresh rate
      -if CCLK=500MHz, refresh_rate=750
      -if CCLK=400MHz, refresh_rate=600
      -if CCLK=300MHz, refresh_rate=450
      -if CCLK=250MHz, refresh_rate=375
  -tests if each cache is already enabled or not. If it
is disabled, invalidate and then enable it. If it is enabled,
don't touch it and jump to the next step.
  -tests if BTB is already enabled. If not, enable the BTB
-as one may observe, after each cache command 5 nops
(i.e. 5 CCLK cycles) are introduced. This is to keep
the pipeline clean of eventual cache commands. These
cache commands may stall the processor when executed
before one cache command is ended
-it should be executed immediately after reset.
-It has not been designed to be used in the
middle of the code or in a project that uses overlays
*/
#define cache_enable(refresh_rate)        \
.align_code 4;                            \
  j0 = j31 + CACMD_REFRESH | refresh_rate;; \
  CACMDALL= j0;;                            \
    wait_cache(CASTAT0);                    \
    wait_cache(CASTAT2);                    \
    wait_cache(CASTAT4);                    \
    wait_cache(CASTAT6);                    \
    wait_cache(CASTAT8);                    \
    wait_cache(CASTAT10);                          \
  test_cache_enabled(CASTAT0, test_cache2);        \
          invalidate(CCAIR0, CACMD0, CASTAT0);     \
          j0 = j31 + CACMD_EN;;                    \
          CACMD0 = j0;;                            \
          nop;;nop;;nop;;nop;;nop;;                \
          wait_cache(CASTAT0);                     \
test_cache2:                                       \
  test_cache_enabled(CASTAT2, test_cache4);        \
          invalidate(CCAIR2, CACMD2, CASTAT2);     \
          j0 = j31 + CACMD_EN;;                    \
          CACMD2 = j0;;                            \
          nop;;nop;;nop;;nop;;nop;;                \
          wait_cache(CASTAT2);                     \
test_cache4:                                       \
  test_cache_enabled(CASTAT4, test_cache6);        \
          invalidate(CCAIR4, CACMD4, CASTAT4);     \
          j0 = j31 + CACMD_EN;;                    \
          CACMD4 = j0;;                            \
          nop;;nop;;nop;;nop;;nop;;                \
          wait_cache(CASTAT4);                     \
test_cache6:                                       \
  test_cache_enabled(CASTAT6, test_cache8);        \
          invalidate(CCAIR6, CACMD6, CASTAT6);     \
          j0 = j31 + CACMD_EN;;                    \
          CACMD6 = j0;;                            \
          nop;;nop;;nop;;nop;;nop;;                \
          wait_cache(CASTAT6);                     \
test_cache8:                                       \
  test_cache_enabled(CASTAT8, test_cache10);       \
          invalidate(CCAIR8, CACMD8, CASTAT8);     \
          j0 = j31 + CACMD_EN;;                    \
          CACMD8 = j0;;                            \
          nop;;nop;;nop;;nop;;nop;;                \
          wait_cache(CASTAT8);                     \
test_cache10:                                      \
  test_cache_enabled(CASTAT10, test_BTB);          \
          invalidate(CCAIR10,CACMD10,CASTAT10);    \
          j0 = j31 + CACMD_EN;;                    \
          CACMD10 = j0;;                           \
          nop;;nop;;nop;;nop;;nop;;                \
          wait_cache(CASTAT10);                    \
test_BTB:                                          \
.align_code 4;                                     \
	XR0 = SQSTAT;;                                   \
	XR0 = SQSTAT;;                                   \
	XBITEST R0 BY SQSTAT_BTBEN_P;;                   \
	IF NXSEQ, JUMP BTB_already_enabled (NP);;        \
    nop;;nop;;nop;;nop;;nop;;                      \
  BTBEN;;                                          \
.align_code 4;                                     \
BTB_already_enabled:                               \
   nop;


//this macro initializes the cycle counter of the benchmark
#define ini_cycle_count \
  xr0 = CCNT0;; \
  xr1 = 0x5;; \
  xr0 = r0 + r1;; \
  [j31 + cycle_count] = xr0;

//this macro computes the benchmark cycle count
#define comp_cycle_count \
  xr1 = CCNT0;; \
  xr0 =  [j31 + cycle_count];; \
  xr0 = r1 - r0;; \
  [j31 + cycle_count] = xr0;

//this macro computes the program memory occupied by the benchmark
#define comp_program_memory \
  xr1 = Benchmark;; \
  xr0 = Benchmark.end;; \
  xr0 = r0 - r1;; \
  [j31 + pm_count] = xr0;

//this macro writes 0 in all the length registers, so setting all
//address generators in linear addressing mode
#define ini_linear_addressing  \
  jl0=j31+0;;   kl0=k31+0;; \
  jl1=j31+0;;   kl1=k31+0;;  \
  jl2=j31+0;;   kl2=k31+0;; \
  jl3=j31+0;;   kl3=k31+0;

//this macro initializes the cycle counter of the benchmark when
//more counts must be saved into memory
//j30 must be previously initialized at cycle_count
//and cycle_count should be set as a buffer
#define ini_cycle_count_multiple \
  xr0 = CCNT0;; \
  xr1 = 0x5;; \
  xr0 = r0 + r1;; \
  [j30+0] = xr0;

//this macro computes the benchmark cycle count and
//saved the result at j30
#define comp_cycle_count_multiple \
  xr1 = CCNT0;; \
  xr0 =  [j30 + 0];; \
  xr0 = r1 - r0;; \
  [j30+=1] = xr0;

//this macro initializes the cycle counter of the benchmark
#define ini_cycle_count_xpr0 \
  xr1:0 = pr1:0;;            \
  xr0 = CCNT0;;              \
  xr2 = 0x6;;                \
  nop;;                      \
  xr0 = r0 + r2;;            \
  nop;;                      \
  xpr1:0 = r1:0;             \

//this macro computes the benchmark cycle count
#define comp_cycle_count_xpr0 \
  xr2 = CCNT0;;               \
  xr1:0 =  pr1:0;;            \
  xr0 = r2 - r0;;             \
  xpr1:0 = r1:0;              \






