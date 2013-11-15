#region Copyright & License Information
/*
 * Copyright 2007-2013 The OpenRA Developers (see AUTHORS)
 * This file is part of OpenRA, which is free software. It is made
 * available to you under the terms of the GNU General Public License
 * as published by the Free Software Foundation. For more information,
 * see COPYING.
 */
#endregion

using System;
using System.Linq;
using LuaInterface;
using OpenRA.Effects;
using OpenRA.FileFormats;
using OpenRA.Mods.RA.Activities;
using OpenRA.Mods.RA.Missions;
using OpenRA.Scripting;
using OpenRA.Traits;
using WorldRenderer = OpenRA.Graphics.WorldRenderer;

namespace OpenRA.Mods.RA.Scripting
{
	public class LuaScriptInterfaceInfo : ITraitInfo, Requires<SpawnMapActorsInfo>
	{
		public readonly string[] LuaScripts = { };

		public object Create(ActorInitializer init) { return new LuaScriptInterface(this); }
	}

	public class LuaScriptInterface : IWorldLoaded, ITick
	{
		World world;
		readonly LuaScriptContext context = new LuaScriptContext();
		readonly LuaScriptInterfaceInfo info;

		public LuaScriptInterface(LuaScriptInterfaceInfo info)
		{
			this.info = info;
		}

		public void WorldLoaded(World w, WorldRenderer wr)
		{
			world = w;
			AddMapActorGlobals();
			context.Lua["World"] = w;
			context.Lua["WorldRenderer"] = wr;
			context.RegisterObject(this, "_OpenRA", false);
			context.RegisterType(typeof(WVec), "WVec", true);
			context.RegisterType(typeof(WPos), "WPos", true);
			context.RegisterType(typeof(CPos), "CPos", true);
			context.RegisterType(typeof(WRot), "WRot", true);
			context.RegisterType(typeof(WAngle), "WAngle", true);
			context.RegisterType(typeof(WRange), "WRange", true);
			context.RegisterType(typeof(int2), "int2", true);
			context.RegisterType(typeof(float2), "float2", true);
			context.LoadLuaScripts(f => FileSystem.Open(f).ReadAllText(), Game.modData.Manifest.LuaScripts);
			context.LoadLuaScripts(f => w.Map.Container.GetContent(f).ReadAllText(), info.LuaScripts);
			context.InvokeLuaFunction("WorldLoaded");
		}

		void AddMapActorGlobals()
		{
			foreach (var kv in world.WorldActor.Trait<SpawnMapActors>().Actors)
				context.Lua[kv.Key] = kv.Value;
		}

		public void Tick(Actor self)
		{
			context.InvokeLuaFunction("Tick");
		}

		[LuaGlobal]
		public object New(string typeName, LuaTable args)
		{
			var type = Game.modData.ObjectCreator.FindType(typeName);
			if (type == null)
				throw new InvalidOperationException("Cannot locate type: {0}".F(typeName));
			if (args == null)
				return Activator.CreateInstance(type);
			var argsArray = ConvertArgs(args);
			return Activator.CreateInstance(type, argsArray);
		}

		object[] ConvertArgs(LuaTable args)
		{
			var argsArray = new object[args.Keys.Count];
			for (var i = 1; i <= args.Keys.Count; i++)
			{
				var arg = args[i] as LuaTable;
				if (arg != null && arg[1] != null && arg[2] != null)
					argsArray[i - 1] = Convert.ChangeType(arg[1], Enum<TypeCode>.Parse(arg[2].ToString()));
				else
					argsArray[i - 1] = args[i];
			}
			return argsArray;
		}

		[LuaGlobal]
		public void Debug(object obj)
		{
			if (obj != null)
				Game.Debug(obj.ToString());
		}

		[LuaGlobal]
		public object TraitOrDefault(Actor actor, string className)
		{
			var type = Game.modData.ObjectCreator.FindType(className);
			if (type == null)
				return null;

			var method = typeof(Actor).GetMethod("TraitOrDefault");
			var genericMethod = method.MakeGenericMethod(type);
			return genericMethod.Invoke(actor, null);
		}

		[LuaGlobal]
		public object Trait(Actor actor, string className)
		{
			var ret = TraitOrDefault(actor, className);
			if (ret == null)
				throw new InvalidOperationException("Actor {0} does not have trait of type {1}".F(actor, className));
			return ret;
		}

		[LuaGlobal]
		public bool HasTrait(Actor actor, string className)
		{
			var ret = TraitOrDefault(actor, className);
			return ret != null;
		}

		[LuaGlobal]
		public object TraitInfoOrDefault(string actorType, string className)
		{
			var type = Game.modData.ObjectCreator.FindType(className);
			if (type == null || !Rules.Info.ContainsKey(actorType))
				return null;

			return Rules.Info[actorType].Traits.GetOrDefault(type);
		}

		[LuaGlobal]
		public object TraitInfo(string actorType, string className)
		{
			var ret = TraitInfoOrDefault(actorType, className);
			if (ret == null)
				throw new InvalidOperationException("Actor type {0} does not have trait info of type {1}".F(actorType, className));
			return ret;
		}

		[LuaGlobal]
		public bool HasTraitInfo(string actorType, string className)
		{
			var ret = TraitInfoOrDefault(actorType, className);
			return ret != null;
		}

		[LuaGlobal]
		public object[] TableToArray(LuaTable table)
		{
			return table.Values.Cast<object>().ToArray();
		}

		[LuaGlobal]
		public void RunAfterDelay(double delay, Action func)
		{
			world.AddFrameEndTask(w => w.Add(new DelayedAction((int)delay, func)));
		}

		[LuaGlobal]
		public void PlaySpeechNotification(Player player, string notification)
		{
			Sound.PlayNotification(player, "Speech", notification, player != null ? player.Country.Race : null);
		}

		[LuaGlobal]
		public void PlaySoundNotification(Player player, string notification)
		{
			Sound.PlayNotification(player, "Sounds", notification, player != null ? player.Country.Race : null);
		}

		[LuaGlobal]
		public void WaitFor(Actor actor, Func<bool> func)
		{
			actor.QueueActivity(new WaitFor(func));
		}

		[LuaGlobal]
		public void CallFunc(Actor actor, Action func)
		{
			actor.QueueActivity(new CallFunc(func));
		}

		[LuaGlobal]
		public void AddKilledEventHandler(Actor actor, Action<Actor, AttackInfo> func)
		{
			actor.AddTrait(new KilledAction(func));
		}

		[LuaGlobal]
		public void AddRemovedEventHandler(Actor actor, Action<Actor> func)
		{
			actor.AddTrait(new RemovedAction(func));
		}

		[LuaGlobal]
		public void AddAddedEventHandler(Actor actor, Action<Actor> func)
		{
			actor.AddTrait(new AddedAction(func));
		}

		[LuaGlobal]
		public int GetFacing(object vec, double currentFacing)
		{
			if (vec is CVec)
				return Util.GetFacing((CVec)vec, (int)currentFacing);
			if (vec is WVec)
				return Util.GetFacing((WVec)vec, (int)currentFacing);
			throw new ArgumentException("Unsupported vector type: {0}".F(vec.GetType()));
		}

		[LuaGlobal]
		public WRange GetWRangeFromCells(double cells)
		{
			return WRange.FromCells((int)cells);
		}

		[LuaGlobal]
		public void SetWinState(Player player, string winState)
		{
			player.WinState = Enum<WinState>.Parse(winState);
		}

		[LuaGlobal]
		public void PlayRandomMusic()
		{
			MissionUtils.PlayMissionMusic();
		}

		[LuaGlobal]
		public bool IsDead(Actor actor)
		{
			return actor.IsDead();
		}

		[LuaGlobal]
		public void PlayMovieFullscreen(string movie, Action onComplete)
		{
			Media.PlayFMVFullscreen(world, movie, onComplete);
		}
	}

	public class KilledAction : INotifyKilled
	{
		readonly Action<Actor, AttackInfo> a;
		public KilledAction(Action<Actor, AttackInfo> a) { this.a = a; }
		public void Killed(Actor self, AttackInfo e) { a(self, e); }
	}

	public class RemovedAction : INotifyRemovedFromWorld
	{
		readonly Action<Actor> a;
		public RemovedAction(Action<Actor> a) { this.a = a; }
		public void RemovedFromWorld(Actor self) { a(self); }
	}

	public class AddedAction : INotifyAddedToWorld
	{
		readonly Action<Actor> a;
		public AddedAction(Action<Actor> a) { this.a = a; }
		public void AddedToWorld(Actor self) { a(self); }
	}
	
	public class TransformedAction : INotifyTransformed
	{
		readonly Action<Actor> a;
		public TransformedAction(Action<Actor> a) { this.a = a; }
		public void OnTransformed(Actor toActor) { a(toActor); }
	}

	public class InfiltrateAction : IAcceptInfiltrator
	{
		readonly Action<Actor, Actor> a;
		public InfiltrateAction(Action<Actor, Actor> a) { this.a = a; }
		public void OnInfiltrate(Actor self, Actor spy) { a(self, spy); }
	}
}
