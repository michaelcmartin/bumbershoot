/**********************************************************************
 *                SIMULATED EVOLUTION: SDL2 HARNESS
 *
 * This runs the simulated evolution simulation until the window is
 * closed, providing an animation of the process as it evolves.
 *
 * See simevo.h for authorship. provenance, and copyright information.
 **********************************************************************/

#include <stdlib.h>
#include <time.h>

#include "simevo.h"
#include "modern_support.h"
#include "SDL.h"

void report_bug(const evo_state_t *state, int i, const char *action)
{
    /* This function nothing in the GUI; they are instead visible
     * in the animation */
    (void) state;
    (void) i;
    (void) action;
}

void report_birth(const evo_state_t *state, int parent, int child_1, int child_2)
{
    /* This function nothing in the GUI; they are instead visible
     * in the animation */
    (void) state;
    (void) parent;
    (void) child_1;
    (void) child_2;
}

/* Main program */

int main(int argc, char **argv)
{
    SDL_Window *window;
    SDL_Renderer *renderer;
    evo_state_t state;
    int64_t seed;
    int done = 0, warp = 0, garden = 1;

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0) {
        SDL_Log("Unable to initialize SDL: %s", SDL_GetError());
        return 1;
    }

    seed = 0;
    if (argc > 1) {
        seed = atoi(argv[1]);
    }
    if (seed == 0) {
        seed = time(NULL);
    }
    seed_rng(seed);
    initialize(&state);
    SDL_Log("Seed is %lld", seed);

    if (argc > 2) {
        int cycle_target = atoi(argv[2]);
        SDL_Log("Running %d cycles before beginning animation.", cycle_target);
        while (state.cycles < cycle_target) {
            run_cycle(&state);
            seed_garden(&state);
        }
    }

    if (SDL_CreateWindowAndRenderer(450, 300, SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        SDL_Log("Unable to initialize window/renderer: %s", SDL_GetError());
        SDL_Quit();
        return 1;
    }
    SDL_SetWindowTitle(window, "Simulated Evolution");
    SDL_RenderSetLogicalSize(renderer, 150, 100);

    while (!done) {
        SDL_Event event;
        SDL_Rect r;
        int i, x, y;
        Uint32 start, end;
        start = SDL_GetTicks();
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                done = 1;
            }
            if (event.type == SDL_KEYDOWN) {
                if (event.key.keysym.sym == SDLK_w) {
                    warp = 1 - warp;
                    SDL_Log("%s warp mode at cycle %d", warp ? "Enabling" : "Disabling", state.cycles);
                }
                if (event.key.keysym.sym == SDLK_g) {
                    garden = 1 - garden;
                }
            }
        }
        run_cycle(&state);
        if (garden) {
            seed_garden(&state);
        }
        /* Draw letter/pillarbox if needed */
        SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0x00);
        SDL_RenderClear(renderer);
        /* Draw background soup */
        SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x80, 0xff);
        SDL_RenderFillRect(renderer, NULL);
        /* Draw plankton */
        SDL_SetRenderDrawColor(renderer, 0x00, 0xff, 0x00, 0xff);
        i = 0;
        r.w = 1;
        r.h = 1;
        for (y = 0; y < 100; ++y) {
            for (x = 0; x < 150; ++x) {
                if (state.plankton[i++]) {
                    r.x = x;
                    r.y = y;
                    SDL_RenderFillRect(renderer, &r);
                }
            }
        }
        /* Draw bugs */
        SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
        r.w = 3;
        r.h = 3;
        for (i = 0; i < state.num_bugs; ++i) {
            r.x = state.bugs[i].x;
            r.y = state.bugs[i].y;
            SDL_RenderFillRect(renderer, &r);
        }
        /* Send the display out */
        SDL_RenderPresent(renderer);
        end = SDL_GetTicks();
        if (!warp && end - start < 20) {
            SDL_Delay(20 - (end - start));
        }
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
