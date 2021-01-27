module Transform

import Syntax;
import Resolve;
import AST;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {

	// First resolve all nested ifthen(else) statements
//	f = outermost visit(f) {
//		case ifthen(
//				outer_guard, 
//				block(
//					ifthen(
//						inner_guard,
//						then_questions_block
//					)
//				)
//			) => ifthen(and(outer_guard, inner_guard), then_questions_block)
//
//		case ifthen(
//				outer_guard,
//				block(
//					ifthenelse(
//						inner_guard,
//						then_questions_block,
//						else_questions_block
//					)
//				)
//			) => ifthen(and(outer_guard, inner_guard), then_questions_block) +
//				 ifthen(not(inner_guard), else_questions_block)
//				 
//		//case ifthenelse(outer_guard, outer_block)
//		
//	}

	AExpr bool_true = \bool(true);
	// flatten questions
	f = form(f.form_id, ([] | it + flatten(q, bool_true) | AQuestion q <- f.questions));

	// Flatten expressions
	f = innermost visit(f) {
		case and(\bool(true), x) => x
		case and(x, \bool(true)) => x
	}
	
	// Flatten expressions
	//f = visit (f) {
	//	case question(question, answer_ref, answer_type) =>
	//		ifthen(AExpr(\bool(true)), question, answer, answer_type)
	//	case ifthen(guard, then_questions_block) =>
	//		[ifthen(guard, q.question, q.answer_ref, answer_type) | 
	//			question()]
	//};
	
	// Lastly ensure all top-level questions are if_then_else-guarded questions
	//f = visit (f) {
	//	case 
	//};
  return f; 
}

list[AQuestion] flatten(AQuestion q, AExpr cond) {
	list[AQuestion] new_qs = [];
	
	if (q is question || q is computed_question) {
		return [ifthen(cond, block([q]))];
	}
	
	
	if (q has then_questions_block) {
		new_qs += ([] | it + flatten(nested_q, and(cond, q.guard)) | nested_q <- q.then_questions_block.questions);
	}
	if (q has else_questions_block) {
		new_qs += ([] | it + flatten(nested_q, and(cond, logic_not(q.guard))) | nested_q <- q.else_questions_block.questions);
	}
	
	return new_qs;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   return f; 
 } 
 
 
 

