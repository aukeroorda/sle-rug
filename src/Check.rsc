module Check

import AST;
import Resolve;
import Message; // see standard library

import Set;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  return {<q.src, q.answer_ref.name, q.question, typeOfAType(q.answer_type)> |
  			/AQuestion q := f, q has answer_ref }; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  for(/AQuestion q := f) {
  	msgs += check(q, tenv, useDef);
  }
  
  //for(/AQuestion q := f, q has answer_ref) {
  //	//for(AQuestion similar <- )
  //	if(size(useDef[q.answer_ref.src]) > 1) {
  //	 	msgs += {error("Duplicate answer variable name with different types", q.answer_ref.src)};
  //	}
  //}
  //
  //for(/AId id := f){
  //	if(id.name notin tenv<name>) {
  //		msgs += {error("Reference to undeclared value", id.src)};
  //	}
  //}

  return msgs; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  if (q is question) {
  	msgs += check(q, tenv);
  }
  if (q is computed_question){
  	msgs += check(q, tenv);
  	Type expr_type = typeOf(q.answer_value, tenv, useDef);
  	Type answer_type = typeOfAType(q.answer_type);
  	if (expr_type != answer_type) {
  		msgs += error("Expression type does not match answer type", q.answer_value.src);
  	}
  }
  if (q is ifthen || q is ifthenelse) {
  	Type guard_type = typeOf(q.guard, tenv, useDef);
  	if (guard_type != tbool()) {
  		msgs += error("Expression type must be bool", q.guard.src);
  	}
  }

  return msgs; 
}

set[Message] check(AQuestion q, TEnv tenv) {
	set[Message] msgs = {};
	loc def;
	
	for (t <- tenv) {
		if(t.label == q.question && t.def != q.src) {
			if(t.\type != typeOfAType(q.answer_type)) {
				msgs += {error("Duplicate declaration with different type", q.src)};
			} else {
				msgs += {warning("Duplicate declaration with same label", q.src)};
			}
		}
	}
	
	return msgs;
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
	case uplus(AExpr x):
	  msgs += {error("uplus operand not integer", x.src) | typeOf(x) == tint()};
	case uminus(AExpr x):
	  msgs += {error("uminus operand not integer", x.src) | typeOf(x) == tint()};
	case logic_not(AExpr x):
	  msgs += {error("logical not operand not boolean", x.src) | typeOf(x) == tbool()};
	case mult(AExpr lhs, AExpr rhs):
	  msgs += {error("* requires type of lhs and rhs to be int", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(lhs, tenv, useDef) == tint()};
	case div(AExpr lhs, AExpr rhs):
	  msgs += {error("/ requires type of lhs and rhs to be int", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(lhs, tenv, useDef) == tint()};
	case add(AExpr lhs, AExpr rhs):
	  msgs += {error("+ requires type of lhs and rhs to be int", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(lhs, tenv, useDef) == tint()};
	case subt(AExpr lhs, AExpr rhs):
	  msgs += {error("- requires type of lhs and rhs to be int", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(lhs, tenv, useDef) == tint()};
	  
	case gt(AExpr lhs, AExpr rhs):
	  msgs += {error("\> requires type of lhs and rhs to be int", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(lhs, tenv, useDef) == tint()};
	case ge(AExpr lhs, AExpr rhs):
	  msgs += {error("\>= requires type of lhs and rhs to be int", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(lhs, tenv, useDef) == tint()};
	case lt(AExpr lhs, AExpr rhs):
	  msgs += {error("\< requires type of lhs and rhs to be int", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(lhs, tenv, useDef) == tint()};
	case le(AExpr lhs, AExpr rhs):
	  msgs += {error("\<= requires type of lhs and rhs to be int", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(lhs, tenv, useDef) == tint()};

	case eq(AExpr lhs, AExpr rhs):
	  msgs += {error("== requires type of lhs and rhs to be equal", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef)};
	case neq(AExpr lhs, AExpr rhs):
	  msgs += {error("!= requires type of lhs and rhs to be equal", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef)};
	
	case and(AExpr lhs, AExpr rhs):
	  msgs += {error("&& requires type of lhs and rhs to be boolean", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(lhs, tenv, useDef) == tbool()};
	case or(AExpr lhs, AExpr rhs):
	  msgs += {error("|| requires type of lhs and rhs to be boolean", e.src) | typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) && typeOf(lhs, tenv, useDef) == tbool()};
	
    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    // etc.
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 Type typeOfAType(AType atype) {
 	switch(atype) {
 		case string(): return tstr();
 		case integer(): return tint();
 		case boolean(): return tbool();
 		default: return tunknown();
 	}
 }
 
 

