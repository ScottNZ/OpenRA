#region Copyright & License Information
/*
 * Copyright 2007-2015 The OpenRA Developers (see AUTHORS)
 * This file is part of OpenRA, which is free software. It is made
 * available to you under the terms of the GNU General Public License
 * as published by the Free Software Foundation. For more information,
 * see COPYING.
 */
#endregion

using System.Collections.Generic;
using StyleCop;
using StyleCop.CSharp;

namespace OpenRA.Mods.Common.UtilityCommands.StyleCop
{
	[SourceAnalyzer(typeof(CsParser))]
	public class OpenRASourceAnalyzer : SourceAnalyzer
	{
		readonly List<IOpenRASourceAnalyzerRule> rules = new List<IOpenRASourceAnalyzerRule>
		{
			new BracesMustNotBeUsedForASingleStatement()
		};

		public override void AnalyzeDocument(CodeDocument document)
		{
			var doc = (CsDocument)document;
			if (doc.RootElement != null && !doc.RootElement.Generated)
				doc.WalkDocument(null, VisitStatement);
		}

		bool VisitStatement(Statement statement, Expression parentExpression, Statement parentStatement, CsElement parentElement, object context)
		{
			foreach (var rule in rules)
				rule.VisitStatement(this, statement, parentExpression, parentStatement, parentElement, context);
			return true;
		}
	}

	interface IOpenRASourceAnalyzerRule
	{
		void VisitStatement(SourceAnalyzer analyzer, Statement statement, Expression parentExpression, Statement parentStatement,
			CsElement parentElement, object context);
	}
}
