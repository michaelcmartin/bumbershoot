//
//  CCA.h
//  CCA
//
//  Created by Michael Martin on 8/12/16.
//  Copyright © 2016 Bumbershoot Software. All rights reserved.
//

#ifndef CCA_h
#define CCA_h

#include <stdio.h>

#define CCA_WIDTH 80
#define CCA_HEIGHT 80
#define CCA_STATES 14

typedef struct CCA_struct {
    unsigned char grid[CCA_HEIGHT][CCA_WIDTH];
} CCA;

typedef struct CCAContext_struct {
    CCA *front, *back;
} CCAContext;

void CCA_seed_random(void);
CCAContext *CCA_alloc(void);
void CCA_scramble(CCAContext *);
void CCA_free(CCAContext *);
CCA *CCA_step(CCAContext *);

#endif /* CCA_h */
