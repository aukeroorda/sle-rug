module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str form_id, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = question(str question, AId answer, AType answer_type)
  | ifthen(AExpr guard, list[AQuestion] questions)
  | ifthenelse(AExpr guard, list[AQuestion] then_questions, list[AQuestion] else_questions)
  | computed_question(str question, AId answer, AType answer_type, AExpr answer_value)
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | \str(str string)
  | \int(int integer)
  | \bool(bool boolean)
  | par(AExpr expr)
  | uplus(AExpr expr)
  | uminus(AExpr expr)
  | logic_not(AExpr expr)
  | mult(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | add(AExpr lhs, AExpr rhs)
  | gt(AExpr lhs, AExpr rhs)
  | ge(AExpr lhs, AExpr rhs)
  | lt(AExpr lhs, AExpr rhs)
  | le(AExpr lhs, AExpr rhs)
  | eq(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = \str()
  | \int()
  | \bool()
  ;
