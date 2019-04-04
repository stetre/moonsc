/* The MIT License (MIT)
 *
 * Copyright (c) 2019 Stefano Trettel
 *
 * Software repository: MoonSC, https://github.com/stetre/moonsc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */


#include "internal.h"
 
/* Delayed sends
 * @@ TODO
 * - replace rb tree with a proper priority queue
 * - pre-allocated pool to avoid Malloc/Free at every send
 */

#define send_t struct send_s
struct send_s {
    RB_ENTRY(send_s) Entry;
    uint64_t cnt;   /* send counter (to provide unique search key based on at) */
    double at;      /* when the send must be sent */
    int ref;        /* reference on Lua registry for the send (a table) */
};

static int cmp(send_t *send1, send_t *send2) 
    {
    if(send1->at < send2->at) return -1;
    if(send1->at > send2->at) return 1;
    return send1->cnt < send2->cnt ? -1 : send1->cnt > send2->cnt;
    }

static RB_HEAD(Tree, send_s) Head = RB_INITIALIZER(&Head);
RB_PROTOTYPE_STATIC(Tree, send_s, Entry, cmp) 
RB_GENERATE_STATIC(Tree, send_s, Entry, cmp) 

static send_t *Remove(send_t *send) { return RB_REMOVE(Tree, &Head, send); }
static send_t *Insert(send_t *send) { return RB_INSERT(Tree, &Head, send); }
#if 0
static send_t *Search(uint32_t cnt, double at)
    { send_t tmp; tmp.at = at; tmp.cnt = cnt; return RB_FIND(Tree, &Head, &tmp); }
#endif
static send_t *First(void)
    { send_t tmp; tmp.at = 0; tmp.cnt = 0.0; return RB_NFIND(Tree, &Head, &tmp); }
#if 0
static send_t *Next(send_t *send) { return RB_NEXT(Tree, &Head, send); }
static send_t *Prev(send_t *send) { return RB_PREV(Tree, &Head, send); }
static send_t *Min(void) { return RB_MIN(Tree, &Head); }
static send_t *Max(void) { return RB_MAX(Tree, &Head); }
static send_t *Root(void) { return RB_ROOT(&Head); }
#endif

/*------------------------------------------------------------------------------*
 |                                                                              |
 *------------------------------------------------------------------------------*/

#define _ISOC99_SOURCE_
#include <math.h> /* for HUGE_VAL */
static uint64_t NextCnt = 0;
static double Tnext = HUGE_VAL;

static int DelayPush(lua_State *L)
/* Inserts a new send in the tree */
    {
    send_t *send;
    double at = luaL_checknumber(L, 2);
    if(lua_type(L, 1) != LUA_TTABLE)
        return luaL_argerror(L, 1, "not a table");
    if((send= (send_t*)Malloc(L, sizeof(send_t))) == NULL) 
        return luaL_error(L, errstring(ERR_MEMORY));
    send->cnt = NextCnt++;
    lua_pushvalue(L, 1);
    send->ref = luaL_ref(L, LUA_REGISTRYINDEX);
    send->at = at;
    Insert(send);
    Tnext = at < Tnext ? at : Tnext;
    return 0;
    }

static int DelayPop(lua_State *L)
/* Returns the next expired send, or nil if none */
    {
    send_t *send;
    if(Tnext > now()) return 0;
    send = First();
    Remove(send);
    if(lua_rawgeti(L, LUA_REGISTRYINDEX, send->ref) != LUA_TTABLE) return unexpected(L);
    luaL_unref(L, LUA_REGISTRYINDEX, send->ref);
    Free(L, send);
    /* Update Tnext */
    send = First();
    Tnext = send ? send->at : HUGE_VAL;
    return 1;
    }

static int DelayTnext(lua_State *L)
    {
    lua_pushnumber(L, Tnext);
    return 1;
    }

static int DelayReset(lua_State *L)
/* Deletes all sends */
    {
    send_t *send;
    while((send=First()))
        {
        Remove(send);
        luaL_unref(L, LUA_REGISTRYINDEX, send->ref);
        Free(L, send);
        }
    Tnext = HUGE_VAL;
    NextCnt = 0;
    return 0;
    }


static const struct luaL_Reg Functions[] = 
    {
        { "delay_push", DelayPush },
        { "delay_pop", DelayPop },
        { "delay_tnext", DelayTnext },
        { "delay_reset", DelayReset },
        { NULL, NULL } /* sentinel */
    };


void moonsc_open_delay(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

