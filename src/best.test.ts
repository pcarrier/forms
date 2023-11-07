import { expect, test } from "vitest";
import { Quoting, TokenType, parse } from "./best";

test("tokenizes an empty source", () => {
  expect(parse("")).toEqual([]);
});

test("tokenizes a space", () => {
  expect(parse(" ")).toEqual([
    { quoting: Quoting.NONE, type: TokenType.SPACING, value: " " },
  ]);
});

test("tokenizes an empty string", () => {
  expect(parse('""')).toEqual([
    { quoting: Quoting.DOUBLE, type: TokenType.STRING, value: "" },
  ]);
});

test("tokenizes a string", () => {
  expect(parse('"hello"')).toEqual([
    { quoting: Quoting.DOUBLE, type: TokenType.STRING, value: "hello" },
  ]);
});

test("tokenizes strings", () => {
  expect(parse("'hello \"concatenative\"'world")).toEqual([
    { quoting: Quoting.SINGLE, type: TokenType.STRING, value: "hello" },
    { quoting: Quoting.NONE, type: TokenType.SPACING, value: " " },
    { quoting: Quoting.DOUBLE, type: TokenType.STRING, value: "concatenative" },
    { quoting: Quoting.SINGLE, type: TokenType.STRING, value: "world" },
  ]);
});
