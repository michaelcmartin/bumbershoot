//
//  CCA.c
//  CCA
//
//  Created by Michael Martin on 8/12/16.
//  Copyright © 2016 Bumbershoot Software. All rights reserved.
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
