export enum TokenType {
  SPACING,
  SYMBOL,
  STRING,
}

export enum Quoting {
  NONE,
  SINGLE,
  DOUBLE,
}

export interface Token {
  type: TokenType;
  quoting: Quoting;
  value: string;
}

export class ParseError extends Error {}

// Space, newline, carriage return, tab, form feed, vertical tab
function isSpace(char: number): boolean {
  return char === 32 || (char >= 9 && char <= 13);
}

// [0-9A-F]
function hexDigit(char: number): number | undefined {
  if (char >= 48 && char <= 57) {
    return char - 48;
  }
  if (char >= 65 && char <= 70) {
    return char - 55;
  }
  return undefined;
}

function parseEscape(src: string, i: number): [string, number] {
  const c = src.charCodeAt(i);
  switch (c) {
    case 32:
    case 34:
    case 39:
    case 92:
      return [src[i], i + 1];
    case 98:
      return ["\b", i + 1];
    case 102:
      return ["\f", i + 1];
    case 110:
      return ["\n", i + 1];
    case 114:
      return ["\r", i + 1];
    case 116:
      return ["\t", i + 1];
    case 117:
      // unicode
      i++;
      // FIXME: implement unicode
    case 118:
      return ["\v", i + 1];
  }
  const d1 = hexDigit(c);
  if (d1 === undefined) {
    throw new ParseError(`invalid escape character: ${src[i]}`);
  }
  i++;
  if (i >= src.length) {
    throw new ParseError("unterminated escape sequence");
  }
  const d2 = hexDigit(src.charCodeAt(i));
  if (d2 === undefined) {
    throw new ParseError(`invalid escape character: ${src[i]}`);
  }
  return [String.fromCharCode(d1 * 16 + d2), i + 1];
}

function parseUntilSpace(src: string, i: number): [string, number] {
  let value = "";
  while (i < src.length) {
    const c2 = src.charCodeAt(i);
    if (isSpace(c2)) {
      break;
    }
    value += src[i++];
  }
  return [value, i];
}

export function parse(src: string): Token[] {
  const tokens: Token[] = [];
  let i = 0;

  while (i < src.length) {
    const c = src.charCodeAt(i);

    if (isSpace(c)) {
      let value = "";
      while (i < src.length && isSpace(src.charCodeAt(i))) {
        value += src[i++];
      }
      tokens.push({
        type: TokenType.SPACING,
        quoting: Quoting.NONE,
        value,
      });
      continue;
    }

    // "
    if (c == 34) {
      i++;
      let value = "";
      cons: while (i < src.length) {
        const c2 = src.charCodeAt(i);
        switch (c2) {
          case 34:
            tokens.push({
              type: TokenType.STRING,
              quoting: Quoting.DOUBLE,
              value,
            });
            break cons;
          default:
            value += src[i++];
        }
      }
      if (i == src.length) {
        throw new ParseError("unterminated double quote");
      }
      i++;
      continue;
    }

    // '
    if (c == 39) {
      i++;
      let value: string;
      [value, i] = parseUntilSpace(src, i);
      tokens.push({
        type: TokenType.STRING,
        quoting: Quoting.SINGLE,
        value,
      });
      continue;
    }

    // \
    if (c == 92) {
      const c2 = src.charCodeAt(++i);
      // FIXME
    }

    // FIXME
  }

  return tokens;
}
