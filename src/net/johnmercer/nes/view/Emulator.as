package net.johnmercer.nes.view 
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
	import net.johnmercer.nes.system.*;
	
	/**
	 * ...
	 * @author John Owen Mercer
	 */
	public class Emulator extends Sprite
	{
		private var cpu:CPU;
		private var rom:ROM;
		
		private var _fileName:String = "nestest.nes";
		//private var _fileName:String = "Super Mario Bros.nes";
		private var _fileRequest:URLRequest;
		private var _fileLoader:URLLoader;
		private var _romData:ByteArray;
		
		private var _loadingFile:Boolean = false;
		
		private var _titleTextField:TextField;
		private var _infoTextField:TextField;
		
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
			
			_titleTextField = new TextField();
			_titleTextField.defaultTextFormat = titleTextFormat;
			_titleTextField.text = "Nintendo Entertainment System";
			_titleTextField.width = _titleTextField.textWidth + 4;
			_titleTextField.height = _titleTextField.textHeight + 4;
			_titleTextField.x = (_width - _titleTextField.width) / 2;
			_titleTextField.y = (_height - _titleTextField.height) / 4;
			
			var infoTextFormat:TextFormat = new TextFormat();
			infoTextFormat.color = 0xFFFFFF;
			infoTextFormat.size = 12;
			
			_infoTextField = new TextField();
			_infoTextField.defaultTextFormat = infoTextFormat;
			_infoTextField.wordWrap = true;
			_infoTextField.text = "Welcome...";
			_infoTextField.width = _width;
			_infoTextField.height = _height / 2;
			_infoTextField.x = 0;
			_infoTextField.y = _height / 2;
			
			// Create system
			rom = new ROM(this);
			cpu = new CPU(this);
			
			
			//addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			addChild(_titleTextField);
			addChild(_infoTextField);
			
			// Load Rom
			rom.loadFile(_fileName);
			cpu.loadRom(rom);
			cpu.start(0xC0000);
			cpu.execute(1000);
		}
		
		
		public function log(text:String):void
		{
			_infoTextField.appendText("\n" + text);
			_infoTextField.scrollV++;
		}
		
	}

}