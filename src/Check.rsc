module Check

import AST;
import Resolve;
import Message; // see standard library

import Set;

// Semantic types in QL
data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()  // incase it cannot be derived
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f)
  = {<q.answer_ref.src, q.answer_ref.name, q.question, typeOfAType(q.answer_type)> |
        /AQuestion q := f, q has answer_ref };

set[Message] check(AForm f)
 = check(f, collect(f), resolve(f).useDef);

//set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
//  set[Message] msgs = {};
//  
//  for(/AQuestion q := f) {
//    msgs += check(q, tenv, useDef);
//  }
  
  //for(/AQuestion q := f, q has answer_ref) {
  //  //for(AQuestion similar <- )
  //  if(size(useDef[q.answer_ref.src]) > 1) {
  //    msgs += {error("Duplicate answer variable name with different types", q.answer_ref.src)};
  //  }
  //}
  //
  //for(/AId id := f){
  //  if(id.name notin tenv<name>) {
  //    msgs += {error("Reference to undeclared value", id.src)};
  //  }
  //}

//  return msgs; 
//}

set[Message] check(AForm f, TEnv tenv, UseDef usedef)
 = ( {} | it + check(q, tenv, usedef) | /AQuestion q := f);

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

    for(/AExpr e <- q) {
        msgs += check(e, tenv, useDef);
    }
    
    Type expr_type = typeOf(q.answer_value, tenv, useDef);
    Type answer_type = typeOfAType(q.answer_type);
    if (expr_type != answer_type) {
      msgs += error("Expression type does not match answer type", q.answer_value.src);
    }
  }
  if (q is ifthen || q is ifthenelse) {   
    for(/AExpr e <- q) {
        msgs += check(e, tenv, useDef);
    }
    
    Type guard_type = typeOf(q.guard, tenv, useDef);
    if (guard_type != tbool()) {
      msgs += error("Guard expression type must be bool", q.guard.src);
    }
  }

  return msgs; 
}

  // Error: same name (answer_ref) but different type
  // Warning: same label
set[Message] check(AQuestion q, TEnv tenv) {
  set[Message] msgs = {};
  loc def;
  
  for (t <- tenv) {
  	// When in the same location
  	if (t.def == q.answer_ref.src) {
  		continue;
  	}
  	
  	// Same name and different type
    if(t.name == q.answer_ref.name && t.\type != typeOfAType(q.answer_type)) {
        msgs += {error("Duplicate name with different type", q.answer_ref.src)};
    } 
    // Same label (and name)
	if (t.label == q.question && t.name == q.answer_ref.name) {
        msgs += {warning("Duplicate declaration with same label", q.src)};
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
      msgs += { error("Reference to undeclared identifer", x.src) | 
      useDef[x.src] == {} };
  case uplus(AExpr x):
    msgs += {error("uplus operand not integer", x.src) | 
    typeOf(x) != tint()};
  case uminus(AExpr x):
    msgs += {error("uminus operand not integer", x.src) | 
    typeOf(x) != tint()};
  case logic_not(AExpr x):
    msgs += {error("logical not operand not boolean", x.src) | 
    typeOf(x) != tbool()};
  case mult(AExpr lhs, AExpr rhs):
    msgs += {error("* requires type of lhs and rhs to be int", e.src) | 
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(lhs, tenv, useDef) != tint()};
  case div(AExpr lhs, AExpr rhs):
    msgs += {error("/ requires type of lhs and rhs to be int", e.src) | 
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(lhs, tenv, useDef) != tint()};
  case add(AExpr lhs, AExpr rhs):
    msgs += {error("+ requires type of lhs and rhs to be int", e.src) | 
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(lhs, tenv, useDef) != tint()};
  case subt(AExpr lhs, AExpr rhs):
    msgs += {error("- requires type of lhs and rhs to be int", e.src) | 
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(lhs, tenv, useDef) != tint()};
    
  case gt(AExpr lhs, AExpr rhs):
    msgs += {error("\> requires type of lhs and rhs to be int", e.src) | 
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(lhs, tenv, useDef) != tint()};
  case ge(AExpr lhs, AExpr rhs):
    msgs += {error("\>= requires type of lhs and rhs to be int", e.src) | 
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(lhs, tenv, useDef) != tint()};
  case lt(AExpr lhs, AExpr rhs):
    msgs += {error("\< requires type of lhs and rhs to be int", e.src) | 
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(lhs, tenv, useDef) != tint()};
  case le(AExpr lhs, AExpr rhs):
    msgs += {error("\<= requires type of lhs and rhs to be int", e.src) | 
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(lhs, tenv, useDef) != tint()};

  case eq(AExpr lhs, AExpr rhs):
    msgs += {error("== requires type of lhs and rhs to be equal", e.src) | 
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef)};
  case neq(AExpr lhs, AExpr rhs):
    msgs += {error("!= requires type of lhs and rhs to be equal", e.src) | 
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef)};
  
  case and(AExpr lhs, AExpr rhs):
    msgs += {error("&& requires type of lhs and rhs to be boolean", e.src) |
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(lhs, tenv, useDef) != tbool()};
  case or(AExpr lhs, AExpr rhs):
    msgs += {error("|| requires type of lhs and rhs to be boolean", e.src) |
    typeOf(lhs, tenv, useDef) != typeOf(rhs, tenv, useDef) || typeOf(lhs, tenv, useDef) != tbool()};
  
    // etc.
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):
      // if we find it in useDef, then use the loc to get the type from TEnc  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
    case \str(str string):
      return tstr();
    case \int(int integer):
      return tint();
    case \bool(bool boolean):
      return tbool();
    case par(AExpr op):
      return typeOf(op, tenv, useDef);
    case uplus(AExpr op):
        return tint();
    case uminus(AExpr op):
        return tint();
    case logic_not(AExpr op):
        return tbool();
    case mult(AExpr lhs, AExpr rhs):
        return tint();
    case div(AExpr lhs, AExpr rhs):
        return tint();
    case add(AExpr lhs, AExpr rhs):
        return tint();
    case subt(AExpr lhs, AExpr rhs):
        return tint();
    
    case gt(AExpr lhs, AExpr rhs):
        return tbool();
    case ge(AExpr lhs, AExpr rhs):
        return tbool();
    case lt(AExpr lhs, AExpr rhs):
        return tbool();
    case le(AExpr lhs, AExpr rhs):
        return tbool();
      
    case eq(AExpr lhs, AExpr rhs):
        return tbool();
    case neq(AExpr lhs, AExpr rhs):
        return tbool();
      
    case and(AExpr lhs, AExpr rhs):
        return tbool();
    case or(AExpr lhs, AExpr rhs):
        return tbool();
    // etc.
  }
  return tunknown(); 
}
//
//Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
//  switch (e) {
//    case ref(id(_, src = loc u)):
//      // if we find it in useDef, then use the loc to get the type from TEnc  
//      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
//        return t;
//      }
//    case \str(str string):
//      return tstr();
//    case \int(int integer):
//      return tint();
//    case \bool(bool boolean):
//      return tbool();
//    case par(AExpr op):
//      return typeOf(op, tenv, useDef);
//    case uplus(AExpr op):
//      if (typeOf(op, tenv, useDef) == tint() ) {
//        return tint();
//      } // else tunknown()
//    case uminus(AExpr op):
//      if (typeOf(op, tenv, useDef) == tint() ) {
//        return tint();
//      } // else tunkown()
//    case logic_not(AExpr op):
//      if (typeOf(op, tenv, useDef) == tbool() ){
//        return tbool();
//      } // else tunknown()
//    case mult(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint() ) {
//        return tint();
//      } // else tunknown()
//    case div(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint() ) {
//        return tint();
//      } // else tunknown()
//    case add(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint() ) {
//        return tint();
//      } // else tunknown()
//    case subt(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint() ) {
//        return tint();
//      } // else tunknown()
//    
//    case gt(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint() ) {
//        return tbool();
//      } // else tunknown()
//    case ge(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint() ) {
//        return tbool();
//      } // else tunknown()
//    case lt(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint() ) {
//        return tbool();
//      } // else tunknown()
//    case le(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint() ) {
//        return tbool();
//      } // else tunknown()
//      
//    case eq(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) ) {
//        return tbool();
//      } // else tunknown()
//    case neq(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == typeOf(rhs, tenv, useDef) ) {
//        return tbool();
//      } // else tunknown()
//      
//    case and(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == tbool() && typeOf(rhs, tenv, useDef) == tbool() ) {
//        return tbool();
//      } // else tunknown()
//    case or(AExpr lhs, AExpr rhs):
//      if (typeOf(lhs, tenv, useDef) == tbool() && typeOf(rhs, tenv, useDef) == tbool() ) {
//        return tbool();
//      } // else tunknown()
//    // etc.
//  }
//  return tunknown(); 
//}

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
 
 

