package views 
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
	import interfaces.INESUI;
	import system.*;
	import utils.RomLoader;
	
	/**
	 * ...
	 * @author John Owen Mercer
	 */
	public class Emulator extends Sprite implements INESUI
	{
		private const INFO_LENGTH:int = 50;
		
		private var _nes:NES;
		
		private var _width:Number;
		private var _height:Number;
		
		private var _nesOutput:Bitmap;
		private var _statusText:TextField;
		private var _romData:ByteArray;
		private var _status:String;
		private var _buffer:Vector.<uint>;
		private var _bufferBitmapData:BitmapData;
		private var _bufferScaleMatrix:Matrix;
		
		public function Emulator(width:Number, height:Number) 
		{
			_width = width;
			_height = height;
			
			// Create main NES output
			_nesOutput = new Bitmap(new BitmapData(512, 480, false, 0));
			_bufferBitmapData = new BitmapData(256, 240, false, 0);
			_bufferScaleMatrix = new Matrix();
			_bufferScaleMatrix.scale(2, 2);
			addChild(_nesOutput);
			
			_nesOutput.x = (_width - _nesOutput.width) * 0.5;
			_nesOutput.y = 10;
			
			// Create status output
			var titleTextFormat:TextFormat = new TextFormat();
			titleTextFormat.color = 0xFF0000;
			titleTextFormat.size = 18;
			titleTextFormat.bold = true;
			titleTextFormat.font = "Arial";
			
			_statusText = new TextField();
			addChild(_statusText);
			
			_statusText.defaultTextFormat = titleTextFormat;
			_statusText.text = "Nintendo Entertainment System";
			_statusText.width = _width - 10;
			_statusText.height = _statusText.textHeight + 4;
			_statusText.x = 10
			_statusText.y = _nesOutput.height;
			
			// Load ROM
			var romLoader:RomLoader = new RomLoader();
			romLoader.loadFile("Super Mario Bros.nes", romLoaderCallback);
			//romLoader.loadFile("Super Mario Bros 2.nes", romLoaderCallback);
			//romLoader.loadFile("Super Mario Bros 3.nes", romLoaderCallback);
			//romLoader.loadFile("Tetris.nes", romLoaderCallback);
			//romLoader.loadFile("zelda.nes", romLoaderCallback);
			//romLoader.loadFile("Zelda II.nes", romLoaderCallback);
			//romLoader.loadFile("Mario Bros.nes", romLoaderCallback);
			//romLoader.loadFile("Pac-Man.nes", romLoaderCallback);
			//romLoader.loadFile("Mega Man.nes", romLoaderCallback);
			
			
			
			addEventListener(Event.ADDED_TO_STAGE, onStage);
		}
		
		private function onStage(e:Event):void
		{
			// Create nes options
			var options:Object = {
				ui: this,
				input: new KeyboardInput(stage)
			};			
			
			_nes = new NES(options);
			//_nes.runTest("NESTEST");
			
			if (_romData)
			{
				_nes.loadRom(_romData);
				_nes.start();
			}
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function romLoaderCallback(romData:ByteArray, error:String):void
		{
			if (error) { return; }
			
			loadROM(romData);
		}
		
		private function loadROM(romData:ByteArray):void
		{
			_romData = romData;
			if (_nes)
			{
				_nes.loadRom(romData);
				_nes.start();
			}
		}
		
		public function onEnterFrame(e:Event):void
		{
			if (_buffer)
			{
				_bufferBitmapData.setVector(new Rectangle(0, 0, 256, 240), _buffer);
				_nesOutput.bitmapData.draw(_bufferBitmapData, _bufferScaleMatrix);
				_buffer = null;
			}
		}
		
		/* INTERFACE interfaces.INESUI */
		
		public function updateStatus(value:String):void 
		{
			_statusText.text = value;
		}
		
		public function writeFrame(buffer:Vector.<uint>):void 
		{
			_buffer = buffer;
		}
		
	}

}