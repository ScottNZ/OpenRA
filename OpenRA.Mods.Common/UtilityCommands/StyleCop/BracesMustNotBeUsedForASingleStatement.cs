using System.Collections.Generic;
using System.Linq;
using StyleCop;
using StyleCop.CSharp;

namespace OpenRA.Mods.Common.UtilityCommands.StyleCop
{
	class BracesMustNotBeUsedForASingleStatement : IOpenRASourceAnalyzerRule
	{
		static readonly StatementType[] BlockTypes =
		{
			StatementType.If, StatementType.Else, StatementType.While, StatementType.DoWhile,
			StatementType.Fixed, StatementType.For, StatementType.Foreach, StatementType.Using,
			StatementType.Lock
		};

		public void VisitStatement(SourceAnalyzer analyzer, Statement statement, Expression parentExpression, Statement parentStatement,
			CsElement parentElement, object context)
		{
			// Only control flow statements which don't always require braces are applicable.
			if (statement.StatementType == StatementType.Block && parentStatement != null
				&& BlockTypes.Contains(parentStatement.StatementType) && statement.ChildStatements.Count == 1)
			{
				var childStatement = statement.ChildStatements.First();

				// Count lines that are not part of the statement collection,
				// such as commented lines at the beginning and ends of the block:
				// if (...)
				// {
				//     // Some comment
				//     foo();
				//     // Some other comment
				// }
				// These comments actually belong to the block, and not to the child.
				var blockNewlineCount = CountNewlines(statement.Tokens.Where(t =>
					t.Location.EndPoint.Index < childStatement.Location.StartPoint.Index ||
					t.Location.StartPoint.Index > childStatement.Location.EndPoint.Index));

				// Determines whether the child of the control flow statement is itself a control flow statement without a block.
				// If this is the case we can consider removing the braces from this statement as well.
				// For example:
				// if (...)
				// {
				//     if (...)
				//         ...
				// }
				// Here we can just do:
				// if (...)
				//     if (...)
				//         ...
				int childNewlineCount;
				if (BlockTypes.Contains(childStatement.StatementType) &&
					childStatement.ChildStatements.First().StatementType != StatementType.Block)
				{
					var attachedStatement = parentStatement.AttachedStatements.FirstOrDefault();
					if (parentStatement.StatementType == StatementType.If && attachedStatement != null
						&& attachedStatement.StatementType == StatementType.Else)
					{
						// This is an exception to the above, and concerns code like the following:
						// if (...)
						// {
						//     if (...)
						//         ...
						// }
						// else
						//    ...
						// Removing the braces here would cause the else to pair up with the second if
						// instead of the first which would give incorrect behavior, so don't suggest removing the braces.
						return;
					}

					// OK to ask the user to remove braces, unless the child's condition takes up multiple lines:
					childNewlineCount = CountControlFlowConditionNewlines(childStatement);
				}
				else
				{
					// Count lines of the child as normal. If it takes up enough lines, don't suggest removing the braces.
					// This avoids ugly things like:
					// if (...)
					//     foo = () =>
					//     {
					//         ...
					//         ...
					//     };
					// This is acceptable:
					// if (...)
					//     foo = () => bar;
					childNewlineCount = CountNewlines(childStatement.Tokens);
				}

				// Now consider both the number of lines that belong to the block and to the child statements.
				// If there are too many, don't suggest removing the braces.
				var newlineCount = blockNewlineCount + childNewlineCount;

				if (newlineCount <= 2)
					analyzer.AddViolation(parentElement, statement.Location, typeof(BracesMustNotBeUsedForASingleStatement).Name);
			}
		}

		static int CountNewlines(IEnumerable<CsToken> tokens)
		{
			return tokens.Count(t => t.CsTokenType == CsTokenType.EndOfLine);
		}

		// Counts the number of newlines in the condition of a control flow statement.
		static int CountControlFlowConditionNewlines(Statement statement)
		{
			var child = statement.ChildStatements.First();

			var token = statement.Tokens.First;
			while (token != null && token.Value.Location.EndPoint.Index < child.Location.StartPoint.Index)
				token = token.Next;

			while (token != null && token.Value.CsTokenType != CsTokenType.EndOfLine)
				token = token.Previous;

			if (token == null)
				return 0;

			return CountNewlines(statement.Tokens.TakeWhile(t =>
				t.Location.EndPoint.Index < token.Value.Location.StartPoint.Index));
		}
	}
}
