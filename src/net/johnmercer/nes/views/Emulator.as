package net.johnmercer.nes.views 
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
	import net.johnmercer.nes.enums.*;
	import net.johnmercer.nes.system.*;
	import net.johnmercer.nes.tests.instrtestv4.*;
	import net.johnmercer.nes.tests.instrtestv5.*;
	import net.johnmercer.nes.tests.interfaces.*;
	import net.johnmercer.nes.tests.nestest.*;
	
	/**
	 * ...
	 * @author John Owen Mercer
	 */
	public class Emulator extends Sprite
	{
		private const INFO_LENGTH:int = 50;
		
		private var _cpu:CPU;
		private var _rom:ROM;
		
		// UI
		private var _titleTextField:TextField;
		private var _infoTextField:TextField;
		private var _button:SimpleButton;
		
		private var _width:Number;
		private var _height:Number;
		
		private var _infoTextArray:Vector.<String>;
		private var _updateText:Boolean = false;
		
		
		public function Emulator(width:Number, height:Number) 
		{
			_width = width;
			_height = height;
			
			var titleTextFormat:TextFormat = new TextFormat();
			titleTextFormat.color = 0xFF0000;
			titleTextFormat.size = 24;
			titleTextFormat.bold = true;
			titleTextFormat.font = "Arial";
			
			_titleTextField = new TextField();
			_titleTextField.defaultTextFormat = titleTextFormat;
			//_titleTextField.text = "Nintendo Entertainment System";
			_titleTextField.text = "Console";
			_titleTextField.width = _titleTextField.textWidth + 4;
			_titleTextField.height = _titleTextField.textHeight + 4;
			_titleTextField.x = (_width - _titleTextField.width) / 2;
			_titleTextField.y = (_height - _titleTextField.height) / 4;
			
			var infoTextFormat:TextFormat = new TextFormat();
			infoTextFormat.color = 0xFFFFFF;
			infoTextFormat.size = 12;
			infoTextFormat.font = "Courier";
			
			_infoTextField = new TextField();
			_infoTextField.embedFonts = false
			_infoTextField.defaultTextFormat = infoTextFormat;
			_infoTextField.wordWrap = true;
			_infoTextField.text = "Welcome...";
			_infoTextField.width = _width;
			_infoTextField.height = _height / 2;
			_infoTextField.x = 0;
			_infoTextField.y = _height / 2;
			
			_infoTextArray = new Vector.<String>();
			_updateText = false;
			
			// Create system
			_rom = new ROM(this);
			_cpu = new CPU(this);

			addChild(_titleTextField);
			addChild(_infoTextField);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			startEmulation();
		}
		
		private function onEnterFrame(e:Event):void
		{
			if (_updateText)
			{
				_updateText = false;
				// Build string
				var text:String = "";
				for each (var line:String in _infoTextArray)
				{
					text += "\n" + line;
				}
				_infoTextField.text = text;
				_infoTextField.scrollV = _infoTextField.maxScrollV;
			}
		}

		
		public function log(text:String):void
		{
			if (_infoTextArray.push(text) > INFO_LENGTH)
			{
				_infoTextArray.shift();
			}
			_updateText = true;
		}
		
		public function waitForRom(e:Event):void
		{
			// Check to see if we've finished loading
			if (!_rom.loading)
			{
				removeEventListener(Event.ENTER_FRAME, waitForRom);
				if (_rom.validFile)
				{
					startEmulation();
				}
				else
				{
					log("Failed to load ROM");
				}
			}
		}
		
		public function enableMouseStep():void
		{
			addEventListener(MouseEvent.CLICK, onMouseClick);
		}
		
		private function onMouseClick(e:Event):void
		{
		}
		
		public function startEmulation():void
		{
			var test:ITest;
			switch(Globals.MODE)
			{
				case Globals.NESTEST:
					test = new Nestest(this);
					test.startTest(_cpu, _rom);
					break;
				case Globals.INSTRTESTV4:
					test = new InstrTestV4(this);
					test.startTest(_cpu, _rom);
					break;
				case Globals.INSTRTESTV5:
					test = new InstrTestV5(this);
					test.startTest(_cpu, _rom);
					break;
			}
		}
		
		
	}

}