module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;
  

  
Value toVType(AType a) {
	switch(a) {
	    case string(): return vstr("");
	    case integer(): return vint(0);
	    case boolean(): return vbool(false);
	}
}

  
// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
	VEnv venv = ();
	for (/AQuestion q := f, q has answer_ref) {
		venv += ("<q.answer_ref.name>": toVType(q.answer_type));
	}

	return venv;
}


// Because of out of order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
	for(/AQuestion q := f) {
		venv = eval(q, inp, venv);
	}
	
	return venv;
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  if (q is question && q.question == inp.question) {
  	venv[q.answer_ref.name] = inp.\value;
  }
  if (q is computed_question) {
  	venv[q.answer_ref.name] = eval(q.answer_value, venv);
  }
  if (q is ifthen) {
  	if(eval(q.guard, venv).b) {
  		for(AQuestion q_nested <- q.then_questions_block.questions) {
  			venv = eval(q_nested, inp, venv);
  		}
  	}
  }
  if (q is ifthenelse) {
  	if(eval(q.guard, venv).b) {
  		for(AQuestion q_nested <- q.then_questions_block.questions) {
  			venv = eval(q_nested, inp, venv);
  		}
  	} else {
  		for(AQuestion q_nested <- q.else_questions_block.questions) {
  			venv = eval(q_nested, inp, venv);
  		}
  	}
  }
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv["<x>"];
    case \str(str string): return vstr(string);
    case \int(int integer): return vint(integer);
    case \bool(bool boolean): return vbool(boolean);
    case par(AExpr op): return eval(op, venv);
    
    case uplus(AExpr op): return vint(1 * eval(op, venv));	// essentially a no-op
    case uminus(AExpr op): return vint(-1 * eval(op, venv));
    case log_not(AExpr op): return vbool(!eval(op, venv));
    
    case mult(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n * eval(rhs, venv).n);
    case div(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n / eval(rhs, venv).n);
    case add(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n + eval(rhs, venv).n);
    case subt(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n - eval(rhs, venv).n);
    
    case gt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
    case ge(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n >= eval(rhs, venv).n);
    case lt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
    case le(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
    
    case eq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) == eval(rhs, venv));
    case neq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) != eval(rhs, venv));
    
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b || eval(rhs, venv).b);
    
    // etc.
    
    default: throw "Unsupported expression <e>";
  }
}