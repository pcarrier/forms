package stor

import (
	"bufio"
	"reflect"
	"strings"
	"testing"
)

func Test_lexer_NextToken(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		tokens  []Token
		wantErr bool
	}{
		{name: "empty", input: "", tokens: []Token{
			{Type: EOF},
		}},
		{name: "number", input: "-4.2e-4", tokens: []Token{
			{Type: NUMBER, Content: "-4.2e-4"},
			{Type: EOF},
		}},
		{name: "tag", input: " @18  ", tokens: []Token{
			{Type: TAG, Content: "18"},
			{Type: EOF},
		}},
		{name: "true", input: "#t", tokens: []Token{
			{Type: TRUE},
			{Type: EOF},
		}},
		{name: "tagged null", input: "@42#n", tokens: []Token{
			{Type: TAG, Content: "42"},
			{Type: NULL},
			{Type: EOF},
		}},
		{name: "interleaved identifiers", input: "hello_1->world #u", tokens: []Token{
			{Type: STRING, Content: "hello_1->world"},
			{Type: UNDEFINED},
			{Type: EOF},
		}},
		{name: "byte array", input: "#b\"\\\"\\00\"", tokens: []Token{
			{Type: BYTE_ARRAY, Content: "\"\x00"},
			{Type: EOF},
		}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			l := NewLexer(bufio.NewReader(strings.NewReader(tt.input)))
			for _, expectedToken := range tt.tokens {
				_, actualToken, err := l.NextToken()
				if err != nil {
					t.Errorf("NextToken() error = %v", err)
				}
				if !reflect.DeepEqual(actualToken, expectedToken) {
					t.Errorf("NextToken() token = %v, expected %v", actualToken, expectedToken)
				}
			}
		})
	}
}
