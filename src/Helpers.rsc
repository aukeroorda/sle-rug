module Helpers

import ParseTree;

import IDE;

import Syntax;
import AST;
import CST2AST;

import Resolve;
import Check;

loc l = |project://QL/examples/binary.myql|;
 
AForm get_ast()
  = cst2ast(parse(#start[Form], l));

RefGraph resolve_(AForm f) =
	resolve(f);
	
set[Message] check_(AForm f) =
	check(f);
	
void ide() = main();