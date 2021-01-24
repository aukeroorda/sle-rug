module Syntax

extend lang::std::Layout;
extend lang::std::Id;

import IO;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id form_id "{" Question* questions "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = "{" Question* "}"			// block
  | Str Id ":" Type			// Basic questions
									// Condition guarded, if-then
  | "if" "(" Expr ")" "{" Question* "}"
									// if-then-else
  | "if" "(" Expr ")" "{" Question* "}" "else" "{" Question* "}"
									// computed question
  | Str Id ":" Type "=" Expr
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
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
  | "int"
  | "bool"
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
 | "str"
 | "int"
 | "bool"
 ;

void printIds(start[Form] m) {
  visit(m) {
    case Id x: println(x);
    case Str x: println("str: <x>");
    case (Expr)`<Expr lhs> * <Expr rhs>`: println("Expr lhs <lhs> lt rhs <rhs>");
  }
}


