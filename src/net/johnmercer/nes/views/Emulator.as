package net.johnmercer.nes.views 
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
	import net.johnmercer.nes.enums.Globals;
	import net.johnmercer.nes.system.*;
	import net.johnmercer.nes.tests.Nestest;
	import net.johnmercer.nes.tests.Nestest;
	
	/**
	 * ...
	 * @author John Owen Mercer
	 */
	public class Emulator extends Sprite
	{
		private var _cpu:CPU;
		private var _rom:ROM;
		private var _mapper:Mapper;
		
		private var _testFile:String = "nestest.nes";
		private var _romFile:String = "Super Mario Bros.nes";
		private var _fileRequest:URLRequest;
		private var _fileLoader:URLLoader;
		private var _romData:ByteArray;
		
		// UI
		private var _titleTextField:TextField;
		private var _infoTextField:TextField;
		private var _button:SimpleButton;
		
		private var _width:Number;
		private var _height:Number;
		
		
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
			
			
			// Create system
			_rom = new ROM(this);
			
			
			addChild(_titleTextField);
			addChild(_infoTextField);
			
			_rom.loadFile(_testFile);
			
			addEventListener(Event.ENTER_FRAME, waitForRom);
		}
		
		
		public function log(text:String):void
		{
			_infoTextField.appendText("\n" + text);
			_infoTextField.scrollV++;
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
		
		
		private function onMouseClick(e:Event):void
		{
			_cpu.execute();
		}
		
		public function startEmulation():void
		{
			//addEventListener(MouseEvent.CLICK, onMouseClick);
			_mapper = new Mapper(this);
			_mapper.loadRom(_rom);
			_cpu = new CPU(this, _rom, _mapper);
			var test:Nestest = new Nestest(this);
			
			if (test.runTest(_cpu, 0xC000) == true)
			{
				log("NES Test Passed!");
			}
		}
		
	}

}