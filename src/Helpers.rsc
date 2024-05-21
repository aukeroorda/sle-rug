module Helpers

import ParseTree;
import vis::ParseTree;
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

// tax eval_ input
//Input tax_input_ = input("Did you sell a house in 2010?", vbool(true));
Input tax_input_ = input("Private debts for the sold house:", vint(20000));

void tree_l(loc l)
  = renderParsetree(parse(#start[Form], l));

AForm get_ast(loc l)
  = cst2ast(parse(#start[Form], l));

RefGraph resolve_(loc l) =
	resolve(get_ast(l));
	
AForm flatten_(loc l) =
	flatten(get_ast(l));
	
set[Message] check_(loc l) =
	check(get_ast(l));
	
VEnv eval_(loc l) =
	eval(get_ast(l), tax_input_, initialEnv(get_ast(l)));
	
void compile_(loc l) =
	compile(get_ast(l));
	
void compile_flat_(loc l) =
	compile_flat(get_ast(l));
	
void ide() = main();

void t_resolve(loc l) = 
	text(resolve_(l));
void t_flatten(loc l) = 
	text(flatten_( l));
void t_eval(loc l) =
	text(eval_( l));
void t_compile(loc l) =
	text(compile_(l));
