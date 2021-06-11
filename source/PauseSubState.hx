package;

import openfl.Lib;
#if windows
import llua.Lua;
#end
import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Exit to menu'];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var perSongOffset:FlxText;
	
	var offsetChanged:Bool = false;

	#if siiva
	// for displaying autoplay params
	var showParam:Bool = false;
	var textParam:FlxText;
	var edit:Int = -1;
	#end

	public function new(x:Float, y:Float)
	{
		super();

		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyString();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);
		perSongOffset = new FlxText(5, FlxG.height - 18, 0, "Additive Offset (Left, Right): " + PlayState.songOffset + " - Description - " + 'Adds value to global offset, per song.', 12);
		perSongOffset.scrollFactor.set();
		perSongOffset.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		#if cpp
			add(perSongOffset);
		#end

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		#if siiva
		textParam = new FlxText(500, 20, 700, "", 20);
		add(textParam);
		#end

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;
		var rightP = controls.RIGHT_P;
		var accepted = controls.ACCEPT;
		var oldOffset:Float = 0;
		var songPath = 'assets/data/' + PlayState.SONG.song.toLowerCase() + '/';

		if (upP)
		{
			changeSelection(-1);
   
		}else if (downP)
		{
			changeSelection(1);
		}
		
		#if cpp
			else if (leftP)
			{
				oldOffset = PlayState.songOffset;
				PlayState.songOffset -= 1;
				sys.FileSystem.rename(songPath + oldOffset + '.offset', songPath + PlayState.songOffset + '.offset');
				perSongOffset.text = "Additive Offset (Left, Right): " + PlayState.songOffset + " - Description - " + 'Adds value to global offset, per song.';

				// Prevent loop from happening every single time the offset changes
				if(!offsetChanged)
				{
					grpMenuShit.clear();

					menuItems = ['Restart Song', 'Exit to menu'];

					for (i in 0...menuItems.length)
					{
						var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
						songText.isMenuItem = true;
						songText.targetY = i;
						grpMenuShit.add(songText);
					}

					changeSelection();

					cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
					offsetChanged = true;
				}
			}else if (rightP)
			{
				oldOffset = PlayState.songOffset;
				PlayState.songOffset += 1;
				sys.FileSystem.rename(songPath + oldOffset + '.offset', songPath + PlayState.songOffset + '.offset');
				perSongOffset.text = "Additive Offset (Left, Right): " + PlayState.songOffset + " - Description - " + 'Adds value to global offset, per song.';
				if(!offsetChanged)
				{
					grpMenuShit.clear();

					menuItems = ['Restart Song', 'Exit to menu'];

					for (i in 0...menuItems.length)
					{
						var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
						songText.isMenuItem = true;
						songText.targetY = i;
						grpMenuShit.add(songText);
					}

					changeSelection();

					cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
					offsetChanged = true;
				}
			}
		#end

		if (accepted)
		{
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "Resume":
					close();
				case "Restart Song":
					FlxG.resetState();
				case "Exit to menu":
					if(PlayState.loadRep)
					{
						FlxG.save.data.botplay = false;
						FlxG.save.data.scrollSpeed = 1;
						FlxG.save.data.downscroll = false;
					}
					PlayState.loadRep = false;
					#if windows
					if (PlayState.luaModchart != null)
					{
						PlayState.luaModchart.die();
						PlayState.luaModchart = null;
					}
					#end
					if (FlxG.save.data.fpsCap > 290)
						(cast (Lib.current.getChildAt(0), Main)).setFPSCap(290);
					
					if (PlayState.isStoryMode)
						FlxG.switchState(new StoryMenuState());
					else
						FlxG.switchState(new FreeplayState());
			}
		}

		#if siiva
		if (FlxG.keys.justPressed.J)
		{
			// for reference later!
			// PlayerSettings.player1.controls.replaceBinding(Control.LEFT, Keys, FlxKey.J, null);

			// hi just gonna borrow this place
			showParam = !showParam;
		}

		if (FlxG.keys.justPressed.C)
		{
			PlayState.autoplay = !PlayState.autoplay;
			trace("Autoplay " + (PlayState.autoplay ? "enabled" : "disabled"));
		}

		if (FlxG.keys.justPressed.P)
		{
			PlayState.perfectAuto = !PlayState.perfectAuto;
			trace("Perfect autoplay " + (PlayState.perfectAuto ? "enabled" : "disabled"));
		}

		if (showParam)
		{
			if (PlayState.autoplay)
			{
				var PARAM_NUM = 6;
				if (edit == -1)
					edit = 0;

				if (PlayState.perfectAuto)
					textParam.text = "PERFECT ENABLED\n";
				else
					textParam.text = "AUTO ENABLED\n";

				// param modifier
				if (FlxG.keys.justPressed.T)
					edit = (edit + (PARAM_NUM - 1)) % PARAM_NUM; // -1 fails lol
				if (FlxG.keys.justPressed.G)
					edit = (edit + 1) % PARAM_NUM;

				var left = FlxG.keys.justPressed.F;
				var right = FlxG.keys.justPressed.H;
				if (left || right)
				{
					switch (edit)
					{
						case 0:
							if (left && Note.delayMin > 0)
								Note.delayMin -= 1;
							else if (right && Note.delayMin < Note.delayMax)
								Note.delayMin += 1;
						case 1:
							if (left && Note.delayMax > Note.delayMin)
								Note.delayMax -= 1;
							else if (right)
								Note.delayMax += 1;
						case 2:
							if (left && Note.delayStd > 1e-5) // float comparison epic
								Note.delayStd -= 0.1;
							else if (right)
								Note.delayStd += 0.1;
						case 3:
							if (left && PlayState.antiInfiHoldThres > 1)
								PlayState.antiInfiHoldThres -= 1;
							else if (right)
								PlayState.antiInfiHoldThres += 1;
						case 4:
							if (!PlayState.perfectAuto)
							{
								if (left && PlayState.holdDelayMin > 2)
									PlayState.holdDelayMin -= 1;
								else if (right)
									PlayState.holdDelayMin += 1;
							}
							else
							{
								if (left && PlayState.holdPerfDelayMin > 2)
									PlayState.holdPerfDelayMin -= 1;
								else if (right)
									PlayState.holdPerfDelayMin += 1;
							}
						case 5:
							if (!PlayState.perfectAuto) {
								if (left && PlayState.holdDelayMax > 2)
									PlayState.holdDelayMax -= 1;
								else if (right)
									PlayState.holdDelayMax += 1;
							}
							else {
								if (left && PlayState.holdPerfDelayMax > 2)
									PlayState.holdPerfDelayMax -= 1;
								else if (right)
									PlayState.holdPerfDelayMax += 1;
							}
					}
				}
			}
			else
			{
				edit = -1;
				textParam.text = "AUTO DISABLED\n";
			}

			textParam.text += "Min delay: " + (edit == 0 ? "< " : "  ") + Note.delayMin + (edit == 0 ? " >" : "  ") + "\n";
			textParam.text += "Max delay: " + (edit == 1 ? "< " : "  ") + Note.delayMax + (edit == 1 ? " >" : "  ") + "\n";
			textParam.text += "Std delay: " + (edit == 2 ? "< " : "  ") + Note.delayStd + (edit == 2 ? " >" : "  ") + "\n";
			textParam.text += "Inf thres: " + (edit == 3 ? "< " : "  ") + PlayState.antiInfiHoldThres + (edit == 3 ? " >" : "  ") + "\n";
			textParam.text += "Hold min : " + (edit == 4 ? "< " : "  ") + (PlayState.perfectAuto ? PlayState.holdPerfDelayMin : PlayState.holdDelayMin) + (edit == 4 ? " >" : "  ") + "\n";
			textParam.text += "Hold max : " + (edit == 5 ? "< " : "  ") + (PlayState.perfectAuto ? PlayState.holdPerfDelayMax : PlayState.holdDelayMax) + (edit == 5 ? " >" : "  ") + "\n";
		}
		else
			textParam.text = "";
		#end
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}