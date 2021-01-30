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
  = Id \ Reserved   		// relative complement, i.e. any Id, but not reserved ones
  | Str literal
  |	Int literal
  | Bool literal
  > "(" Expr ")"	        // parentheses
  | right (
     "+" Expr               // unary plus
  |	 "-" !>>[0-9] Expr      // unary minus
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
  = ;  
  
lexical Str = ;

lexical Int 
  = ;

lexical Bool = ;



