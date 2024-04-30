
#ifndef _SCHEMEPROC_H_
#define _SCHEMEPROC_H_

#include "dspcommon.h"

#define MAX_MODULATIONS             (2)

/* Code Masks */
#define CODE_REP                    0x000ff     /* Bits 7 - 0 */    //TODO: Future
#define CODE_CONV                   0x00f00     /* Bits 11 - 8 */
#define CODE_CONV2                  0x00200     /* Bit 9 */         //TODO: Future
#define CODE_CONV3                  0x00400     /* Bit 10 */
#define CODE_LDPC                   0x0f000     /* Bits 15 - 12 */  //TODO: Future
#define CODE_GOLAY                  0x10000     /* Bit 16 */

//#define TEMP_BUF_SIZE               0x2000      /* Max packet length (bits) */

#define MOD_DEP_PARAM_OFFSET        (256)
#define MAX_MODEM_CONFIG_PARAMS     (39)

#define CORR_LENGTH                 (0x300)     /* 768 */

/* Correlator template bitmask */
#define CORR_LEN_MASK               0xfff
#define CORR_BW_MASK                0xff000
#define CORR_TYPE_MASK              0xf00000
#define CORR_TYPE_USER              0

/* Wetend write mask */
#define WETEND_WRITE_MASK_PA        0xF7
#define WETEND_WRITE_MASK_GAIN      0x1F

#define MAX_PR_ATTN_VALUE           (32767)

typedef enum {
    MOD_NONE            = 0,
    MOD_IOFDM           = 1,
    MOD_OFDM            = 2,
	MOD_BFSK            = 3,
	MOD_JANUS           = 4
} en_modulationType;                    /* Modulation type */

typedef enum {
    MODEM_PARAM_PHY_VERSION     = 0,    /* Version & build no. of the PHY layer code */
    //MODEM_PARAM_PHY_PWR       = 1,    /* not used */
    MODEM_PARAM_TX_RX           = 2,    /* Power amplifier control (0 - disable, 1 - enable, 2 = auto) */
    MODEM_PARAM_TX_ATTN         = 4,    /* TX level (dB) (Maximum - 65535) */
    //MODEM_PARAM_PRE_GAIN      = 5,    /* Superseeded by WETEND_GAIN now */
    MODEM_PARAM_AGC_MODE        = 6,    /* AGC mode (0 - disable, 1 - enable, 2 = auto) */
    MODEM_PARAM_LOOPBACK        = 7,    /* Digital loopback enable (0 - disable, 1 - DSP, 2 = FPGA DLO) */
    MODEM_PARAM_RX_ENABLE       = 8,    /* Receive enable (0 - disable, 1 - enable, 2 = auto) */
    MODEM_PARAM_RX_FC           = 9,    /* RX carrier frequency (Hx), Fs = 4 x Fc */
    MODEM_PARAM_TX_FC           = 10,   /* TX carrier frequency (Hx), Fs = 4 x Fc */
    MODEM_PARAM_CORR_ENABLE     = 11,   /* Correlator enable (bit mask for correlators 0 to 2)  */
    MODEM_PARAM_CORR1_THR       = 12,   /* Correlator 1 threshold */
    MODEM_PARAM_CORR2_THR       = 13,   /* Correlator 2 threshold */
    MODEM_PARAM_CORR3_THR       = 14,   /* Correlator 3 threshold */
    MODEM_PARAM_CORR1_TMPL      = 15,   /* Correlator 1 template */
    MODEM_PARAM_CORR2_TMPL      = 16,   /* Correlator 2 template */
    MODEM_PARAM_CORR3_TMPL      = 17,   /* Correlator 3 template */
    MODEM_PARAM_MAX_SIGLEN      = 18,   /* Maximum length of baseband signal - max sigbuf len */
    MODEM_PARAM_CORR_DIAG       = 20,   /* Correlator diagnostics enable */
    //MODEM_PARAM_CLOCK         = 21,   /* not used */
    MODEM_PARAM_CLOCK_NTF       = 22,   /* Clock notification enable */
    //MODEM_PARAM_CLOCK_SRC     = 23,   /* Superseeded by OCXO_ENABLE now */
    MODEM_PARAM_TX_DELAY        = 24,   /* Power amp delay */
    MODEM_PARAM_CORR1_INHIBIT   = 25,   /* Correlator 1 inhibit timer */
    MODEM_PARAM_CORR2_INHIBIT   = 26,   /* Correlator 2 inhibit timer */
    MODEM_PARAM_CORR3_INHIBIT   = 27,   /* Correlator 3 inhibit timer */
    //MODEM_PARAM_BOARD_TEMP    = 28,   /* not used */
    //MODEM_PARAM_FPGA_TEMP     = 29,   /* not used */
    MODEM_PARAM_DIAG_REC_TRIG   = 30,   /* Diagnostics recording trigger */
    MODEM_PARAM_FPGA_BITMASK    = 31,   /* FPGA components status bitmask */
    MODEM_PARAM_OCXO_ENABLE     = 32,   /* OCXO enable */
    MODEM_PARAM_WETEND_GAIN     = 33,   /* Wetend gain: 0,6,12,18,24,30,36,42 dB */
    MODEM_PARAM_FPGA_VREF       = 34,   /* Voltage reference */
    MODEM_PARAM_POWER_AMP_PWR   = 35,   /* Power amplifier power supply */
    MODEM_PARAM_WETEND_BITMASK  = 36,   /* FPGA WETEND_WRITE bitmask */
    MODEM_PARAM_FPGA_VREF_MIN   = 37,   /* Minimum voltage reference to supply to DAC */
    MODEM_PARAM_TX_RAW          = 38    /* TX outgoing RAW packet as BB/PB */
} en_modemParams;

typedef enum {
    SCHEME_PARAM_MTYPE          = 0,    /* Modulation type (0 - None, 1 - OFDM, 2 - FH-BFSK) */
    SCHEME_PARAM_SCHEME_ENABLE  = 1,    /* Enable Scheme */
    SCHEME_PARAM_FEC            = 2,    /* Forward error correction scheme */
    //SCHEME_PARAM_CRC          = 3,    /* Implemented in host */
    SCHEME_PARAM_PKTLEN         = 4,    /* Packet Length (bytes, excluding CRC) */
    SCHEME_PARAM_TX_TRIG        = 5,    /* Transmit trigger */
    //SCHEME_PARAM_RX_TRIG      = 6,    /* Receive trigger */
    SCHEME_PARAM_PR_DEF         = 7,    /* Preamble definition */
    SCHEME_PARAM_PR_GAP         = 8,    /* Gap between preamble and packet */
    SCHEME_PARAM_PR_ATTN        = 9,    /* Preamble scaling (dB) (Maximum - 32767) */
    SCHEME_PARAM_DC_ENABLE      = 10,   /* Doppler compensation enable */
    SCHEME_PARAM_DC_LFM_SLOPE   = 11,   /* LFM slope for Doppler estimation */
    SCHEME_PARAM_DC_LFM_MAP     = 12,   /* LFM to correlator mapping */
    SCHEME_PARAM_MAX_PKT_LEN    = 13,   /* Maximum packet length (bytes, excluding CRC) */
    SCHEME_PARAM_PKT_DURATION   = 14,   /* Packet duration (ms) */
    SCHEME_PARAM_TESTPKT        = 15,   /* Testpacket (0-disable, 1-report error count, 2-report error pattern) */
    SCHEME_PARAM_RX_COUNT       = 16,   /* Number of packets received */
    SCHEME_PARAM_TX_COUNT       = 17,   /* Number of packets transmitted */
    SCHEME_PARAM_RX_DROPPED     = 18,   /* Number of packets dropped */
    SCHEME_PARAM_RX_RAW         = 19,   /* Whether to process incoming signal  */
    //SCHEME_PARAM_TX_RAW       = 20    /* TX outgoing RAW packet as BB/PB */
    SCHEME_PARAM_PR_LEN         = 21,   /* PreLen - computed from the PR_DEF and CORRn_TMPL */
    SCHEME_PARAM_PR_DURATION    = 22,   /* Preamble duration - PR_LEN/(TX_NCO*2/3)*1000 */
    SCHEME_PARAM_TX_PROC_TIME   = 23,   /* Time taken for TX processing */
    SCHEME_PARAM_RX_PROC_TIME   = 24,   /* Time taken for RX processing */
    SCHEME_PARAM_TX_ATTN        = 25    /* TX level (dB) (Maximum - 65535) */
} en_schemeParams;

/** Bit masks **/
/* Correlator Enable */
#define MODEM_PARAM_CORR_DISABLE_ALL        0
#define MODEM_PARAM_CORR1_ENABLE            0x1
#define MODEM_PARAM_CORR2_ENABLE            0x2
#define MODEM_PARAM_CORR3_ENABLE            0x4
#define MODEM_PARAM_CORR_ENABLE_ALL         (MODEM_PARAM_CORR1_ENABLE|MODEM_PARAM_CORR2_ENABLE|MODEM_PARAM_CORR3_ENABLE)

/* Diag recording trigger */
#define MODEM_PARAM_DIAG_REC_TRIG_AUTO      0x0
#define MODEM_PARAM_DIAG_REC_TRIG_CORR1     0x1
#define MODEM_PARAM_DIAG_REC_TRIG_CORR2     0x2
#define MODEM_PARAM_DIAG_REC_TRIG_CORR3     0x3
#define MODEM_PARAM_DIAG_REC_TRIG_EXT       0x4
#define MODEM_PARAM_DIAG_REC_TRIG_SW        0x5


/** Valid Values for parameters **/
/* Loopbacks */
#define MODEM_PARAM_LOOPBACK_NONE           0       /* No loopback */
#define MODEM_PARAM_LOOPBACK_DSP            1       /* Loopback in DSP*/
#define MODEM_PARAM_LOOPBACK_FPGA_DLO       2       /* Digital loopback - FPGA */

/* Test Packet */
#define SCHEME_PARAM_TESTPKT_DISABLE        0       /* Test packet TX disabled */
#define SCHEME_PARAM_TESTPKT_ERR_COUNT      1       /* Test packet - report error count */
#define SCHEME_PARAM_TESTPKT_ERR_PATTERN    2       /* Test packet - report error pattern */

/* TX Trigger */
#define SCHEME_PARAM_TX_TRIG_AUTO           0x0
#define SCHEME_PARAM_TX_TRIG_CORR1          0x1
#define SCHEME_PARAM_TX_TRIG_CORR2          0x2
#define SCHEME_PARAM_TX_TRIG_CORR3          0x3
#define SCHEME_PARAM_TX_TRIG_EXT            0x4
#define SCHEME_PARAM_TX_TRIG_SW             0x5

/* RAW packet RX */
#define SCHEME_PARAM_RX_RAW_DISABLE         0       /* RAW signal reception disabled */
#define SCHEME_PARAM_RX_RAW_BASEBAND        1       /* RAW baseband signal reception enabled. No processing of incoming signal is done */
#define SCHEME_PARAM_RX_RAW_BOTH            2       /* RAW signal as well as the processed signal is send to host */

/* RAW packet TX */
#define MODEM_PARAM_TX_RAW_BASEBAND         1       /* TX a baseband signal out */
#define MODEM_PARAM_TX_RAW_PASSBAND         2       /* TX a passband signal out */

/* Preamble definition */
#define SCHEME_PARAM_PR_DEF_COR1_COEFF      0x100   /* Preamble is same as cor 1 coeff */
#define SCHEME_PARAM_PR_DEF_COR2_COEFF      0x200   /* Preamble is same as cor 2 coeff */
#define SCHEME_PARAM_PR_DEF_COR3_COEFF      0x300   /* Preamble is same as cor 3 coeff */

extern int corr1Buf[2*CORR_LENGTH];
extern int corr2Buf[2*CORR_LENGTH];
extern int corr3Buf[2*CORR_LENGTH];

/* Modem configuration values */
extern int modemConfig[MAX_MODEM_CONFIG_PARAMS];
/* Various scheme config values */
extern int schemeConfig[MAX_SCHEME_COUNT][MAX_SCHEME_PARAMS];

/** Various Function Pointers **/
/* Process functions */
typedef uint32_t (*ModProcTX)(float*, BufferPtr_t, uint32_t, uint8_t);
typedef void (*ModProcRX)(BufferPtr_t, float*, uint32_t, uint8_t);
/* getDefaultParams() function */
typedef en_dspRetType (*ModParams)(int *);
/* Param set */
typedef int (*ModSet)(uint8_t, uint32_t, int);
/* Signal length calculation function */
typedef int (*computeSigLen)(uint32_t, uint8_t);

typedef en_dspRetType (*ModValidCheck)(uint8_t);

typedef struct __ModProcessor__ {
    uint32_t        noOfParams;
    ModParams       getDefaultParams;
    ModSet          modSet;
    ModProcTX       processTx;
    ModProcRX       processRx;
    ModValidCheck   validationCheck;
    computeSigLen   cSL;
} ModProcessor;

/* Initialization */
void
SchemeProc_init(void);

/* Controls which TxProc and RxProc is called */
void
SchemeProc_registerModulationType(en_modulationType modType, ModProcessor modProcFuncs);

/* Set Param */
uint32_t
SchemeProc_setSchemeParam(uint8_t scheme, uint32_t param, uint32_t value);

/* Get Param */
uint32_t
SchemeProc_getSchemeParam(uint8_t scheme, uint32_t param);

/*
 * The FEC, interleaving etc is handled by these functions.
 * The appropriate ModProcessor methods are called for baseband
 * conversion for specific modulation types.
 */
/* Process TX */
void
SchemeProc_processTx(BufferPtr_t databuf, BufferPtr_t sigbuf, uint8_t scheme);

/* Process RX */
void
SchemeProc_processRx(BufferPtr_t sigbuf, BufferPtr_t databuf, uint8_t scheme);

/*
 * Compute Signal Length
 * bits: uncoded packet length in bits
 * Returns number of words in buffer
 */
uint16_t
SchemeProc_computeSignalLength(uint32_t bits, uint8_t scheme);

/* Compute Overall Code Rate */
float
SchemeProc_computeCodeRate(uint8_t scheme);

/* Update RX count */
uint32_t
SchemeProc_UpdateRXCount(uint8_t scheme);

/* Update TX count */
uint32_t
SchemeProc_UpdateTXCount(uint8_t scheme);

/* Update RX drop count */
uint32_t
SchemeProc_UpdateDropCount(uint8_t scheme);

/* Reset Scheme Counts */
en_dspRetType
SchemeProc_resetSchemeCount(uint8_t scheme);

uint32_t
SchemeProc_getCurTimestamp(void);

uint32_t
SchemeProc_computePreDuration(uint8_t scheme);

uint32_t
SchemeProc_computePktDuration(uint8_t scheme);

uint32_t
SchemeProc_computeBBRawPktDuration(uint16_t signalLen);

#endif //_SCHEMEPROC_H_
