package net.johnmercer.nes.system
{
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	import net.johnmercer.nes.enums.*;
	import net.johnmercer.nes.system.*;
	import net.johnmercer.nes.view.*;
	
	/**
	 * ...
	 * @author John Owen Mercer
	 */
	public class ROM
	{
		// Flags
		private var _loading:Boolean;
		private var _validFile:Boolean;
		private var _sram:Boolean;
		private var _chrRam:Boolean;
		private var _trainer:Boolean;
		private var _mapper:uint;
		private var _TVSystem:uint;
		
		// Memory Blocks
		private var _trainerRom:ByteArray;
		private var _prgRom:ByteArray;
		private var _chrRom:ByteArray;
		
		// View
		private var _emulatorView:Emulator;
		
		private var _fileLoader:URLLoader;
		
		public function ROM(view:Emulator)
		{
			_emulatorView = view;
			_validFile = false;
			_loading = false;
		}
		
		public function loadFile(fileName:String):void
		{
			// Read in file
			var fileRequest:URLRequest = new URLRequest(fileName);
			_fileLoader = new URLLoader(fileRequest);
			_fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			_fileLoader.addEventListener(Event.COMPLETE, onFileLoaded);
			_fileLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileLoadError);
			_fileLoader.addEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
			
			_loading = true;
		}
		
		private function onFileLoaded(e:Event):void
		{
			_fileLoader.removeEventListener(Event.COMPLETE, onFileLoaded);
			_fileLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileLoadError);
			_fileLoader.removeEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
			
			_loading = false;
			var romData:ByteArray = _fileLoader.data;
			
			_emulatorView.log("File Loaded, Size: " + romData.bytesAvailable);
			parseRom(romData);
		
		}
		
		private function onFileLoadError(e:Event):void
		{
			_fileLoader.removeEventListener(Event.COMPLETE, onFileLoaded);
			_fileLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileLoadError);
			_fileLoader.removeEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
			
			_loading = false;
			_emulatorView.log("FileLoadError: " + e.type);
		}
		
		private function parseRom(romData:ByteArray):void
		{
			var header:ByteArray;
			var prgRomSize:uint;
			var chrRomSize:uint;
			
			if (romData.bytesAvailable < 16)
			{
				_emulatorView.log("parseRom: Invalid file length");
				return;
			}
			
			header = new ByteArray();
			romData.readBytes(header, 0, 16);
			
			// Look for iNES sentinel
			_validFile = header.readUnsignedByte() == 0x4E ? true : false;
			_validFile = header.readUnsignedByte() == 0x45 ? _validFile && true : false;
			_validFile = header.readUnsignedByte() == 0x53 ? _validFile && true : false;
			_validFile = header.readUnsignedByte() == 0x1A ? _validFile && true : false;
			if (_validFile == false)
			{
				_emulatorView.log("parseRom: Invalid Header Tag");
				return;
			}
			
			prgRomSize = header.readUnsignedByte() * 16384;
			chrRomSize = header.readUnsignedByte() * 8192;
			_chrRam = chrRomSize == 0 ? true : false;
			var flag6:uint = header.readUnsignedByte();
			var flag7:uint = header.readUnsignedByte();
			var prgRamSize:uint = header.readUnsignedByte();
			prgRamSize = prgRamSize == 0 ? 8192 : prgRamSize;
			var flag9:uint = header.readUnsignedByte();
			var flag10:uint = header.readUnsignedByte();
			
			// Parse Flags
			_sram = (flag6 & 0x02) ? true : false;
			_trainer = (flag6 & 0x04) ? true : false;
			_mapper = (flag6 & 0xF0) >> 4;
			_mapper |= (flag7 & 0xF0);
			
			if (_sram)
				_emulatorView.log("parseRom: SRAM in CPU $6000-$7FFF Present");
				
			_emulatorView.log("parseRom: Mapper Type: " + _mapper.toString(16));
			
			_TVSystem = flag9 & 0x01;
			if (_TVSystem == Globals.NTSC)
				_emulatorView.log("parseRom: TV System is NTSC");
			else
				_emulatorView.log("parseRom: TV System is PAL");
			
			var nes2Header:Boolean = flag7 & 0x04 ? true : false;
			if (nes2Header)
			{
				_emulatorView.log("parseRom: NES2.0 File found, not able to parse at this time.");
				_validFile = false;
				return;
			}
			
			// Load Trainer
			if (_trainer)
			{
				if (romData.bytesAvailable < 512)
				{
					_emulatorView.log("parseRom: Invalid file length - Trainer");
					_validFile = false;
					return;
				}
				_trainerRom = new ByteArray();
				romData.readBytes(_trainerRom, 0, 512);
				_emulatorView.log("parseRom: 512-byte trainer at $7000-$71FF");
			}
			
			// Read PRG Rom Data
			_prgRom = new ByteArray();
			_prgRom.endian = Endian.LITTLE_ENDIAN;
			
			if (romData.bytesAvailable < prgRomSize)
			{
				_emulatorView.log("parseRom: Invalid file lenth - PRG ROM");
				_validFile = false;
				return;
			}
			romData.readBytes(_prgRom, 0, prgRomSize);
			_emulatorView.log("parseRom: PRG ROM Size: " + prgRomSize);			
			
			_chrRom = new ByteArray();
			// Read CHR Rom Data
			if (chrRomSize && chrRomSize <= romData.bytesAvailable)
			{
				romData.readBytes(_chrRom, 0, chrRomSize);
				_emulatorView.log("parseRom: CHR ROM Size: " + chrRomSize);
			}
			
			_emulatorView.log("parseRom: PRG RAM Size: " + prgRamSize);
			if (romData.bytesAvailable == 0)
			{
				_emulatorView.log("parseRom: Finished Parsing ROM");
				_validFile = true;
			}
			else
			{
				_emulatorView.log("parseRom: " + romData.bytesAvailable + " bytes unparsed");
			}
		}
				
		// Getters/Setters
		public function get mapper():uint 
		{
			return _mapper;
		}
		
		public function set mapper(value:uint):void 
		{
			_mapper = value;
		}
		
		public function get trainerRom():ByteArray 
		{
			return _trainerRom;
		}
		
		public function set trainerRom(value:ByteArray):void 
		{
			_trainerRom = value;
		}
		
		public function get prgRom():ByteArray 
		{
			return _prgRom;
		}
		
		public function set prgRom(value:ByteArray):void 
		{
			_prgRom = value;
		}
		
		public function get chrRom():ByteArray 
		{
			return _chrRom;
		}
		
		public function set chrRom(value:ByteArray):void 
		{
			_chrRom = value;
		}
		
		public function get validFile():Boolean 
		{
			return _validFile;
		}
		
		public function set validFile(value:Boolean):void 
		{
			_validFile = value;
		}
		
		public function get loading():Boolean 
		{
			return _loading;
		}
		
		public function set loading(value:Boolean):void 
		{
			_loading = value;
		}
	
	}

}