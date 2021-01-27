module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
// Not documented yet, but source is here:
// https://github.com/usethesource/rascal/blob/master/src/org/rascalmpl/library/lang/html5/DOM.rsc

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

/* Plan:
	form -> htmlForm
	if guard -> add header to fieldset with  <legend>guard</legend>
	questionBlock -> fieldset (add attribute "disabled" to disable all questions inside it)
	
	question -> <label>q.question.name:</label>
  				<input type="text" id="q.answer_ref.nam" name="q.answer_ref.nam"><br><br>
  		with input type dependent on q.answer_type
	
 */
void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  return html(
  	body(
  		([] | it + ast2html(q) | q <- f.questions)
  	)
  );
}

str form2js(AForm f) {
  return "";
}

HTML5Node ast2html(AQuestion q) {
	if (q has question) {
	return input(\type("text"), \label(q.question));
	}
	return br();;
}