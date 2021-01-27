module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

import Node;
import List;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) 
  = cst2ast(sf.top);

AForm cst2ast(Form f) {
  return form("<f.form_id>", [cst2ast(q) | q <- f.questions], src=f@\loc); 
}

AQuestion cst2ast(Question q){
	if (q is question){
		return question("<q.question>"[1..-1], id("<q.answer_ref>", src=q.answer_ref@\loc), cst2ast(q.answer_type), src=q@\loc);
	}
	
	if (q is computed_question) {
		return computed_question("<q.question>"[1..-1], id("<q.answer_ref>", src=q.answer_ref@\loc), cst2ast(q.answer_type), cst2ast(q.answer_expr), src=q@\loc);
	}
	
	if (q is ifthen) {
		return ifthen(cst2ast(q.guard), cst2ast(q.then_questions_block), src=q@\loc);
	}
	
	if (q is ifthenelse) {
		return ifthenelse(cst2ast(q.guard), cst2ast(q.then_questions_block), cst2ast(q.else_questions_block), src=q@\loc);
	}
}
//
//AQuestion cst2ast(q:(Question)`<Str question> <Id answer_ref> : <Type answer_type>`)
// = question("<question>", id("<answer_ref>", src=answer_ref@\loc), cst2ast(answer_type), src=q@\loc);
//
//AQuestion cst2ast(q:(Question)`<Str question> <Id answer_ref> : <Type answer_type> = <Expr answer_expr>`)
// = computed_question("<question>", id("<answer_ref>", src=answer_ref@\loc), cst2ast(answer_type), cst2ast(answer_expr), src=q@\loc);
//
//AQuestion cst2ast(q:(Question)`if ( <Expr guard> ) <ABlock then_questions_block>`)
// = ifthen(cst2ast(guard), cst2ast(then_questions_block), src=q@\loc);
//
//AQuestion cst2ast(q:(Question)`if ( <Expr guard> ) <ABlock then_questions_block> else <ABlock else_questions_block>`)
// = ifthenelse(cst2ast(guard), cst2ast(if_questions_block), cst2ast(else_questions_block), src=q@\loc);

ABlock cst2ast(Block b)
 = block([cst2ast(q) | q <- b.questions], src=b@\loc);

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>", src=x@\loc), src=x@\loc);
    case (Expr)`<Str s>`: return \str("<s>"[1..-1], src=s@\loc);
    case (Expr)`<Int i>`: return \int(toInt("<i>"), src=i@\loc);
    case (Expr)`<Bool b>`: return \bool(fromString("<b>"), src=b@\loc);
    
	case (Expr)`( <Expr expr> )`: return par(cst2ast(expr), src=expr@\loc);
	case (Expr)`+ <Expr expr>`: return uplus(cst2ast(expr), src=expr@\loc);
	case (Expr)`- <Expr expr>`: return uminus(cst2ast(expr), src=expr@\loc);
	case (Expr)`! <Expr expr>`: return logic_not(cst2ast(expr), src=expr@\loc);
	
	case (Expr)`<Expr lhs> * <Expr rhs>`: return mult(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	case (Expr)`<Expr lhs> / <Expr rhs>`: return div(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	case (Expr)`<Expr lhs> + <Expr rhs>`: return add(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	case (Expr)`<Expr lhs> - <Expr rhs>`: return subt(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);

	case (Expr)`<Expr lhs> \> <Expr rhs>`: return gt(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	case (Expr)`<Expr lhs> \>= <Expr rhs>`: return ge(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	case (Expr)`<Expr lhs> \< <Expr rhs>`: return lt(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	case (Expr)`<Expr lhs> \<= <Expr rhs>`: return le(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	case (Expr)`<Expr lhs> \<= <Expr rhs>`: return le(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	case (Expr)`<Expr lhs> == <Expr rhs>`: return eq(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	case (Expr)`<Expr lhs> != <Expr rhs>`: return neq(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);

	case (Expr)`<Expr lhs> && <Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	case (Expr)`<Expr lhs> || <Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=lhs@\loc);
	
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t)
{
	switch(t)
	{
		case (Type)`string`: return string(src=t@\loc);
		case (Type)`integer`: return integer(src=t@\loc);
		case (Type)`boolean`: return boolean(src=t@\loc);
		default: throw "Unhandled type: <t>";
	}
}

test bool testImplodeExpr() =
 mult(\int(5), ref(id("Identifier"))) := cst2ast((Expr)`5 * Identifier`);

test bool testOperatorAnd() =
 and(
 	and(
 		ref(id("a", src = loc _)), 
 		ref(id("b", src = loc _))
 	), 
 	ref(id("c", src = loc _))
 ) := cst2ast((Expr)`a && b && c`);

test bool testOperatorAndLeftAssoc() =
 structurallyEqual(
 	and(
 		and(
 			ref(id("a")), 
 			ref(id("b"))
 		), 
 		ref(id("c"))
 	),
 	cst2ast((Expr)`a && b && c`)
 );

bool structurallyEqual(node a, node b) {
	if (getName(a) != getName(b)) {
		return false;
	}
	
	list[value] children_a = getChildren(a);
	list[value] children_b = getChildren(b);
	
	if(size(children_a) != size(children_b)) {
		return false;
	}
	
	for (int i <- [1..size(children_a)]) {
		value kid_a = children_a[i];
		value kid_b = children_b[i];
		
		if (node n_a := kid_a, node n_b := kid_b) {
			return structurallyEqual(n_a,n_b);
		}
		
		return kid_a == kid_b;
	}
	// Childless nodes
	return true;
}





