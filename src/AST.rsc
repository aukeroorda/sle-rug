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
  = question(str question, AId answer_ref, AType answer_type)
  | computed_question(str question, AId answer_ref, AType answer_type, AExpr answer_value)
  | ifthen(AExpr guard, ABlock then_questions_block)
  | ifthenelse(AExpr guard, ABlock then_questions_block, ABlock else_questions_block)
  ;

data ABlock(loc src = |tmp:///|)
  =  block(list[AQuestion] questions)
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
  | subt(AExpr lhs, AExpr rhs)
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
  
anno loc AId@location;

data AType(loc src = |tmp:///|)
  = \string()
  | \integer()
  | \boolean()
  ;
