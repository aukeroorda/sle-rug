module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = 
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  |  	// unary plus
  |		// unary minus
  |		// logical not
  >		// multiplication
  |		// division
  >		// addition
  |		// subtraction
  >		// greater than
  |		// greater-equal than
  |		// less than
  |		// less-equal than
  >		// equality
  |		// inequality
  >		// logical and
  >		// logical or
  |		// literal
 ;
  
syntax Type
  = Str
  | Int
  | Bool
 ;
  
lexical Str = [\"][!\"]*[\"];	// opening quote followed by non-quotes, followed by closing quote

lexical Int 
 = [1-9][0-9]*		// positive integral
 | [0]				// zero
 | [\-][1-9][0-9]*	// negative integral
;

lexical Bool
 = "true"
 | "false"
;



