module Helpers

import ParseTree;

import util::ValueUI;
import IDE;

import Syntax;
import AST;
import CST2AST;

import Resolve;
import Transform;
import Check;
import Eval;
import Compile;

// binary
public loc bin = |project://QL/examples/binary.myql|;

// tax
public loc tax = |project://QL/examples/tax.myql|;

// test
public loc tst = |project://QL/examples/test.myql|;

// eval_ input
Input input_ = input("How much money?", vint(7));

AForm get_ast(loc l)
  = cst2ast(parse(#start[Form], l));

RefGraph resolve_(loc l) =
	resolve(get_ast(l));
	
AForm flatten_(loc l) =
	flatten(get_ast(l));
	
set[Message] check_(loc l) =
	check(get_ast(l));
	
VEnv eval_(loc l) =
	eval(get_ast(l), input_, initialEnv(get_ast(l)));
	
void compile_(loc l) =
	compile(get_ast(l));
	
void ide() = main();

void t_resolve(loc l) = 
	text(resolve_(l));
void t_flatten(loc l) = 
	text(flatten_( l));
void t_eval(loc l) =
	text(eval_( l));
void t_compile(loc l) =
	text(compile_(l));
