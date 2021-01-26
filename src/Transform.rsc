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

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   return f; 
 } 
 
 
 

