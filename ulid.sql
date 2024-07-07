/*
 * Original TypeScript Implementation: https://github.com/ulid/javascript
 *
 * The MIT License (MIT)
 * 
 * Copyright (c) 2017 Alizain Feerasta
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

-- Add the "plv8" extension
CREATE EXTENSION IF NOT EXISTS "plv8";

-- Add the "pgcrypto" extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- May need to run this command to enable plv8 in specific schema
-- ALTER EXTENSION pgcrypto SET SCHEMA public;

-- initialize
CREATE OR REPLACE FUNCTION plv8_init() RETURNS void AS $$

  const ENCODING = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  const ENCODING_LEN = ENCODING.length;
  const TIME_MAX = Math.pow(2, 48) - 1;
  const TIME_LEN = 10;
  const RANDOM_LEN = 16;

  let lastTime = 0;
  let lastRandom = '';

  function replaceCharAt(str, index, char) {
    if (index > str.length - 1) {
      return str;
    }
    return str.substr(0, index) + char + str.substr(index + 1);
  }
  function incrementBase32(str) {
    let done = undefined;
    let index = str.length;
    let char;
    let charIndex;
    const maxCharIndex = ENCODING_LEN - 1;
    while (!done && index-- >= 0) {
      char = str[index];
      charIndex = ENCODING.indexOf(char);
      if (charIndex === -1) {
        return '';
      }
      if (charIndex === maxCharIndex) {
        str = replaceCharAt(str, index, ENCODING[0]);
        continue;
      }
      done = replaceCharAt(str, index, ENCODING[charIndex + 1]);
    }
    if (typeof done === "string") {
      return done;
    }
    return '';
  }
  function randomChar() {
    let rand = Math.floor(prng() * ENCODING_LEN);
    if (rand === ENCODING_LEN) {
      rand = ENCODING_LEN - 1;
    }
    return ENCODING.charAt(rand);
  }
  function encodeTime(now, len) {
    let mod;
    let str = "";
    for (; len > 0; len--) {
      mod = now % ENCODING_LEN;
      str = ENCODING.charAt(mod) + str;
      now = (now - mod) / ENCODING_LEN;
    }
    return str;
  }
  function encodeRandom(len) {
    let str = "";
    for (; len > 0; len--) {
      str = randomChar() + str;
    }
    return str;
  }
  function prng() {
    const lim = Math.pow(2, 32) - 1;
    const len = 4;
    const num = plv8.execute(`select ('x' || right(public.gen_random_bytes($1)::text, 8))::bit(32)::int as num`, [len])[0].num;
    return Math.abs(num / lim);
  }
  function updateLastRandom(value) {
    return (lastRandom = value);
  }
  function updateLastTime(value) {
    return (lastTime = value);
  }

  plv8.global = {
    TIME_LEN,
    RANDOM_LEN,

    incrementBase32,
    encodeTime,
    encodeRandom,
    updateLastRandom,
    updateLastTime,
    lastTime
  };

$$ LANGUAGE plv8 STRICT;
-- SET plv8.start_proc = 'plv8_init';
-- RESET plv8.start_proc
ALTER DATABASE postgres SET plv8.start_proc TO plv8_init;

CREATE OR REPLACE FUNCTION ulid() RETURNS text AS $$
  const { TIME_LEN, RANDOM_LEN, incrementBase32, encodeTime, encodeRandom, updateLastRandom, updateLastTime, lastTime } = plv8.global;

  const seedTime = Date.now();

  if (seedTime <= lastTime) {
    const incrementedRandom = updateLastRandom(incrementBase32(lastRandom));
    return encodeTime(lastTime, TIME_LEN) + incrementedRandom;
  }
  updateLastTime(seedTime);
  const newRandom = updateLastRandom(encodeRandom(RANDOM_LEN));
  return encodeTime(seedTime, TIME_LEN) + newRandom;
$$ LANGUAGE plv8 STRICT;
