module Helpers

import ParseTree;

import IDE;

import Syntax;
import AST;
import CST2AST;

import Resolve;
import Check;
import Eval;

// binary
//loc l = |project://QL/examples/binary.myql|;

// test
loc l = |project://QL/examples/test.myql|;

// eval_ input
Input input_ = input("How much money?", vint(7));

AForm get_ast()
  = cst2ast(parse(#start[Form], l));

RefGraph resolve_() =
	resolve(get_ast());
	
set[Message] check_() =
	check(get_ast());
	
VEnv eval_() =
	eval(get_ast(), input_, initialEnv(get_ast()));
	
void ide() = main();

