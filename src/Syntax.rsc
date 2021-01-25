module Syntax

extend lang::std::Layout;
extend lang::std::Id;

import IO;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id form_id "{" Question* questions "}"; 

syntax Question =
	// Basic questions
    question: Str question Id answer_ref ":" Type answer_type
	// computed question
  | computed_question: Str question Id answer_ref ":" Type answer_type "=" Expr answer_expr
	// Condition guarded, if-then
  | ifthen: "if" "(" Expr guard ")" Block then_questions_block
	// if-then-else
  | ifthenelse: "if" "(" Expr guard ")" Block then_questions_block "else" Block else_questions_block 
  ; 

syntax Block
 = "{" Question* questions "}";

syntax Expr 
  = Id \ Reserved   		// relative complement, i.e. any Id, but not reserved ones
  | Str literal
  |	Int literal
  | Bool literal
  > "(" Expr ")"	        // parentheses
  | right (
     "+" Expr               // unary plus
  |	 "-" Expr               // unary minus
  |	 "!" Expr               // logical not
  )
  >	left (
	Expr "*" Expr           // multiplication
  |	Expr "/" Expr	        // division
  )
  >	left (
	Expr "+" Expr	        // addition
  |	Expr "-" Expr           // subtraction
  )
  >	left (
    Expr "\>" Expr	        // greater than
  |	Expr "\>=" Expr         // greater-equal than
  |	Expr "\<" Expr          // less than
  |	Expr "\<=" Expr         // less-equal than
  )
  >	left (
	Expr "==" Expr	        // equality
  |	Expr "!=" Expr          // inequality
  )
  >	left Expr "&&" Expr     // logical and
  >	left Expr "||" Expr	    // logical or
 ;
  
syntax Type
  = "string"
  | "integer"
  | "boolean"
 ;
  
lexical Str = "\"" ![\"]*  "\"";	// opening quote followed by non-quotes, followed by closing quote

lexical Int 
 = [1-9][0-9]*		// positive integral
 | [0]				// zero
 | [\-][1-9][0-9]*	// negative integral
;

lexical Bool
 = "true"
 | "false"
;

keyword Reserved
 = "true"
 | "false"
 | "if"
 | "else"
 | "string"
 | "integer"
 | "boolean"
 ;
 
// based on http://tutor.rascal-mpl.org/Recipes/Languages/Pico/Syntax/Syntax.html#/Recipes/Languages/Pico/Syntax/Syntax.html
//layout Layout = WhitespaceAndComment* !>> [\ \t\n\r%];
//lexical WhitespaceAndComment 
   //= [\ \t\n\r]
   //| @category="Comment" "//" ![\n]* $	// EOL-style comments
   //;

void printIds(start[Form] m) {
  visit(m) {
    case Id x: println(x);
    case Str x: println("str: <x>");
    case Expr x: println("expr found: <x>");
    case (Expr)`<Expr lhs> * <Expr rhs>`: println("Expr lhs <lhs> multiplied by rhs <rhs>");
  }
}


