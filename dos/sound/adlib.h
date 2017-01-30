/*
 * ADLIB.H - routines for commanding the OPL2 synthesizer chip on an
 *           Adlib or Soundblaster card.
 *
 * Michael Martin, 2017. Made available under the MIT license.
 */
#ifndef ADLIB_H_
#define ADLIB_H_

/* Reset all Adlib registers to zero. */
void adlib_reset(void);

/* Write the stated value to the specified register. */
void adlib_write(unsigned char register, unsigned char val);

#endif
