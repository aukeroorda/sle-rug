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
//loc l = |project://QL/examples/binary.myql|;

// tax
loc l = |project://QL/examples/tax.myql|;

// test
//loc l = |project://QL/examples/test.myql|;

// eval_ input
Input input_ = input("How much money?", vint(7));

AForm get_ast()
  = cst2ast(parse(#start[Form], l));

RefGraph resolve_() =
	resolve(get_ast());
	
AForm flatten_() =
	flatten(get_ast());
	
set[Message] check_() =
	check(get_ast());
	
VEnv eval_() =
	eval(get_ast(), input_, initialEnv(get_ast()));
	
void compile_() =
	compile(get_ast());
	
void ide() = main();

void t_resolve() = 
	text(resolve_());
void t_flatten() = 
	text(flatten_());
void t_eval() =
	text(eval_());

void t_compile() =
	text(compile_());
