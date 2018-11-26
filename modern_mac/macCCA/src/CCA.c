//
//  CCA.c
//  CCA
//
//  Created by Michael Martin on 8/12/16.
//  Copyright © 2016-8 Bumbershoot Software. Published under the
//  2-clause BSD license.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//
//  1. Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above
//     copyright notice, this list of conditions and the following
//     disclaimer in the documentation and/or other materials provided
//     with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
//  CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
//  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
//  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//  SUCH DAMAGE.
//

#include "CCA.h"
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

void
CCA_seed_random(void)
{
    struct timeval t;
    gettimeofday(&t, NULL);
    srandom((unsigned int)t.tv_sec);
}

CCAContext *
CCA_alloc(void)
{
    CCAContext *result = malloc(sizeof(CCAContext));
    if (!result) {
        return NULL;
    }
    result->front = malloc(sizeof(CCA));
    result->back = malloc(sizeof(CCA));
    if (!result->front || !result->back) {
        CCA_free(result);
        return NULL;
    }
    CCA_scramble(result);
    return result;
}

void
CCA_scramble(CCAContext *ctx)
{
    int y, x;
    for (y = 0; y < CCA_HEIGHT; ++y) {
        for (x = 0; x < CCA_WIDTH; ++x) {
            ctx->front->grid[y][x] = random() % CCA_STATES;
        }
    }

}

void
CCA_free(CCAContext *arg)
{
    if (arg) {
        if (arg->front) {
            free(arg->front);
        }
        if (arg->back) {
            free(arg->back);
        }
        free(arg);
    }
}

CCA *
CCA_step(CCAContext *ctx)
{
    int x, y;
    CCA *temp;
    if (!ctx) {
        return NULL;
    }
    for (y=0; y < CCA_HEIGHT; ++y) {
        for (x=0; x < CCA_WIDTH; ++x) {
            unsigned char c = ctx->front->grid[y][x];
            unsigned char target = (c+1) % CCA_STATES;
            int w = x == 0 ? CCA_WIDTH-1 : x-1;
            int e = x == CCA_WIDTH-1 ? 0 : x+1;
            int n = y == 0 ? CCA_HEIGHT-1 : y-1;
            int s = y == CCA_HEIGHT-1 ? 0 : y+1;

            if (ctx->front->grid[n][x] == target
                || ctx->front->grid[s][x] == target
                || ctx->front->grid[y][w] == target
                || ctx->front->grid[y][e] == target) {
                ctx->back->grid[y][x] = target;
            } else {
                ctx->back->grid[y][x] = c;
            }
        }
    }
    temp = ctx->back;
    ctx->back = ctx->front;
    ctx->front = temp;
    return ctx->front;
}
