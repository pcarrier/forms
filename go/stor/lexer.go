package stor

import (
	"bufio"
	"encoding/hex"
	"errors"
	"io"
	"strings"
	"unicode"
)

type Lexer interface {
	NextToken() (uint64, Token, error)
}

type TokenType int8

const (
	EOF TokenType = iota
	ERROR
	TAG
	NUMBER
	NULL
	UNDEFINED
	TRUE
	FALSE
	SIMPLE
	COMMENT
	BYTE_ARRAY
	STRING
	LIST_START
	LIST_END
	MAP_START
	MAP_END
)

var (
	INVALID_ESCAPE_SEQUENCE = errors.New("invalid escape sequence")
	EOF_IN_ESCAPE_SEQUENCE  = errors.New("unexpected EOF in escape sequence")
)

type Token struct {
	Type    TokenType
	Content string
}

type lexer struct {
	pos uint64
	r   *bufio.Reader
}

func NewLexer(r *bufio.Reader) Lexer {
	return &lexer{
		pos: 0,
		r:   r,
	}
}

func (l *lexer) NextToken() (uint64, Token, error) {
	for {
		r, _, err := l.r.ReadRune()
		if err != nil {
			if err == io.EOF {
				return l.pos, Token{Type: EOF}, nil
			}
			return l.pos, Token{Type: ERROR}, err
		}
		start := l.pos
		l.pos++
		switch r {
		case '[':
			return start, Token{Type: LIST_START}, nil
		case ']':
			return start, Token{Type: LIST_END}, nil
		case '{':
			return start, Token{Type: MAP_START}, nil
		case '}':
			return start, Token{Type: MAP_END}, nil
		case '@':
			content, err := l.lexNumber()
			if err != nil {
				return l.pos, Token{Type: ERROR}, err
			}
			return start, Token{Type: TAG, Content: content}, nil
		case '"':
			content, err := l.lexString()
			if err != nil {
				return l.pos, Token{Type: ERROR}, err
			}
			return start, Token{Type: STRING, Content: content}, nil
		case '#':
			r, _, err := l.r.ReadRune()
			if err != nil {
				if err == io.EOF {
					return l.pos, Token{Type: ERROR}, errors.New("unexpected EOF after #")
				}
				return l.pos, Token{Type: ERROR}, err
			}
			switch r {
			case 'n':
				return start, Token{Type: NULL}, nil
			case 'u':
				return start, Token{Type: UNDEFINED}, nil
			case 't':
				return start, Token{Type: TRUE}, nil
			case 'f':
				return start, Token{Type: FALSE}, nil
			case 'b':
				r, _, err := l.r.ReadRune()
				if err != nil {
					if err == io.EOF {
						return l.pos, Token{Type: ERROR}, errors.New("unexpected EOF after #")
					}
					return l.pos, Token{Type: ERROR}, err
				}
				if r != '"' {
					return l.pos, Token{Type: ERROR}, errors.New("expected \" after #b")
				}
				content, err := l.lexByteArray()
				if err != nil {
					return l.pos, Token{Type: ERROR}, err
				}
				return start, Token{Type: BYTE_ARRAY, Content: content}, nil
			case 'c':
				return start, Token{Type: COMMENT}, nil
			default:
				if unicode.IsDigit(r) {
					content, err := l.lexNumber()
					if err != nil {
						return l.pos, Token{Type: ERROR}, err
					}
					return start, Token{Type: SIMPLE, Content: content}, nil
				}
				return l.pos, Token{Type: ERROR}, errors.New("unexpected character after #")
			}
		default:
			if unicode.IsSpace(r) {
				continue
			}
			if unicode.IsDigit(r) || r == '-' {
				if err := l.r.UnreadRune(); err != nil {
					return l.pos, Token{Type: ERROR}, err
				}
				content, err := l.lexNumber()
				if err != nil {
					return l.pos, Token{Type: ERROR}, err
				}
				return start, Token{Type: NUMBER, Content: content}, nil
			}
			if unicode.IsLetter(r) {
				if err := l.r.UnreadRune(); err != nil {
					return l.pos, Token{Type: ERROR}, err
				}
				content, err := l.lexUnquoted()
				if err != nil {
					return l.pos, Token{Type: ERROR}, err
				}
				return start, Token{Type: STRING, Content: content}, nil
			}
		}
	}
}

func (l *lexer) lexNumber() (string, error) {
	var sb strings.Builder
	for {
		r, _, err := l.r.ReadRune()
		if err != nil {
			if err == io.EOF {
				return sb.String(), nil
			}
			return "", err
		}
		l.pos++
		// TODO: We're very lenient: 0-e..e goes through.
		if unicode.IsDigit(r) || r == '-' || r == 'e' || r == '.' {
			sb.WriteRune(r)
		} else {
			if err := l.r.UnreadRune(); err != nil {
				return "", err
			}
			return sb.String(), nil
		}
	}
}

func (l *lexer) lexUnquoted() (string, error) {
	var sb strings.Builder
	for {
		r, _, err := l.r.ReadRune()
		if err != nil {
			if err == io.EOF {
				return sb.String(), nil
			}
			return "", err
		}
		l.pos++
		if unicode.IsSpace(r) {
			return sb.String(), nil
		}
		sb.WriteRune(r)
	}
}

func (l *lexer) lexString() (string, error) {
	var sb strings.Builder
	for {
		r, _, err := l.r.ReadRune()
		if err != nil {
			if err == io.EOF {
				return sb.String(), nil
			}
			return "", err
		}
		l.pos++
		switch r {
		case '\\':
			r, _, err := l.r.ReadRune()
			if err != nil {
				if err == io.EOF {
					return "", EOF_IN_ESCAPE_SEQUENCE
				}
				return "", err
			}
			l.pos++
			switch r {
			case '"':
				sb.WriteRune('"')
			case '\\':
				sb.WriteRune('\\')
			case 'a':
				sb.WriteRune('\a')
			case 'b':
				sb.WriteRune('\b')
			case 'f':
				sb.WriteRune('\f')
			case 'n':
				sb.WriteRune('\n')
			case 'r':
				sb.WriteRune('\r')
			case 't':
				sb.WriteRune('\t')
			case 'v':
				sb.WriteRune('\v')
			default:
				return "", INVALID_ESCAPE_SEQUENCE
			}
		case '"':
			return sb.String(), nil
		}
		sb.WriteRune(r)
	}
}

func (l *lexer) lexByteArray() (string, error) {
	var sb strings.Builder
	for {
		b, err := l.r.ReadByte()
		if err != nil {
			if err == io.EOF {
				return sb.String(), nil
			}
			return "", err
		}
		l.pos++
		switch b {
		case '\\':
			b1, err := l.r.ReadByte()
			if err != nil {
				if err == io.EOF {
					return "", EOF_IN_ESCAPE_SEQUENCE
				}
				return "", err
			}
			l.pos++
			switch b1 {
			case '"':
				sb.WriteRune('"')
			case '\\':
				sb.WriteRune('\\')
			case 'a':
				sb.WriteRune('\a')
			case 'b':
				sb.WriteRune('\b')
			case 'f':
				sb.WriteRune('\f')
			case 'n':
				sb.WriteRune('\n')
			case 'r':
				sb.WriteRune('\r')
			case 't':
				sb.WriteRune('\t')
			case 'v':
				sb.WriteRune('\v')
			default:
				if b1 >= '0' && b1 <= '9' || b1 >= 'a' && b1 <= 'f' || b1 >= 'A' && b1 <= 'F' {
					b2, err := l.r.ReadByte()
					if err != nil {
						if err == io.EOF {
							return "", EOF_IN_ESCAPE_SEQUENCE
						}
						return "", err
					}
					l.pos++
					if b1 >= '0' && b1 <= '9' || b1 >= 'a' && b1 <= 'f' || b1 >= 'A' && b1 <= 'F' {
						out := make([]byte, 1)
						_, err := hex.Decode(out, []byte{b1, b2})
						if err != nil {
							return "", err
						}
						sb.WriteByte(out[0])
					} else {
						return "", err
					}
				} else {
					return "", INVALID_ESCAPE_SEQUENCE
				}
			}
		case '"':
			return sb.String(), nil
		default:
			sb.WriteByte(b)
		}
	}
}
