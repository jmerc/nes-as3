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
		private var flag6:uint;
		private var flag7:uint;
		private var prgRamSize:uint;
		private var flag9:uint;
		private var flag10:uint;
		private var sram:Boolean;
		private var trainer:Boolean;
		private var mapper:uint;
		private var TVSystem:uint;
		private var nes2Header:Boolean;
		private var trainerRom:ByteArray;
		private var prgRom:ByteArray;
		private var chrRom:ByteArray;
		private var emulatorView:Emulator;
		private var header:ByteArray;
		private var validFile:Boolean;
		private var prgRomSize:uint;
		private var chrRomSize:uint;
		private var chrRam:Boolean;
		
		private var loading:Boolean;
		private var fileLoader:URLLoader;
		
		public function ROM(view:Emulator) 
		{
			emulatorView = view;
			validFile = false;
			loading = false;
		}	
		
		public function loadFile(fileName:String):void
		{
			// Read in file
			var fileRequest:URLRequest = new URLRequest(fileName);
			fileLoader = new URLLoader(fileRequest);
			fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			fileLoader.addEventListener(Event.COMPLETE, onFileLoaded);
			fileLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileLoadError);
			fileLoader.addEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
			
			loading = true;
		}
		
		private function onFileLoaded(e:Event):void
		{
			fileLoader.removeEventListener(Event.COMPLETE, onFileLoaded);
			fileLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileLoadError);
			fileLoader.removeEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);

			loading = false;
			var romData:ByteArray = fileLoader.data;
			
			emulatorView.log("File Loaded, Size: " + romData.bytesAvailable);
			parseRom(romData);
			
		}
		
		private function onFileLoadError(e:Event):void
		{
			fileLoader.removeEventListener(Event.COMPLETE, onFileLoaded);
			fileLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onFileLoadError);
			fileLoader.removeEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);

			loading = false;
			emulatorView.log("FileLoadError: " + e.type);
		}
		
		private function parseRom(romData:ByteArray):void
		{
			if (romData.bytesAvailable < 16)
			{
				emulatorView.log("parseRom: Invalid file length");
				return;
			}
			
			header = new ByteArray();
			romData.readBytes(header, 0, 16);
			
			// Look for iNES sentinel
			validFile = header.readUnsignedByte() == 0x4E ? true : false;
			validFile = header.readUnsignedByte() == 0x45 ? validFile && true : false;
			validFile = header.readUnsignedByte() == 0x53 ? validFile && true : false;
			validFile = header.readUnsignedByte() == 0x1A ? validFile && true : false;
			if (validFile == false)
			{
				emulatorView.log("parseRom: Invalid Header Tag");
				return;
			}
			
			prgRomSize = header.readUnsignedByte() * 16384;
			chrRomSize = header.readUnsignedByte() * 8192;
			chrRam = chrRomSize == 0 ? true : false;
			flag6 = header.readUnsignedByte();
			flag7 = header.readUnsignedByte();
			prgRamSize = header.readUnsignedByte();
			prgRamSize = prgRamSize == 0 ? 8192 : prgRamSize;
			flag9 = header.readUnsignedByte();
			flag10 = header.readUnsignedByte();
			
			// Parse Flags
			sram = (flag6 & 0x02) ? true : false;
			trainer = (flag6 & 0x04) ? true : false;
			mapper = (flag6 & 0xF0) >> 4;
			mapper |= (flag7 & 0xF0);
			
			if (sram) emulatorView.log("parseRom: SRAM in CPU $6000-$7FFF Present");
			emulatorView.log("parseRom: Mapper Type: " + mapper.toString(16));
			
			TVSystem = flag9 & 0x01;
			if (TVSystem == Globals.NTSC) emulatorView.log("parseRom: TV System is NTSC");
			else emulatorView.log("parseRom: TV System is PAL");
			
			nes2Header = flag7 & 0x04 ? true : false;
			if (nes2Header)
			{
				emulatorView.log("parseRom: NES2.0 File found, not able to parse at this time.");
				validFile = false;
				return;
			}
			
			// Load Trainer
			if (trainer)
			{
				if (romData.bytesAvailable < 512)
				{
					emulatorView.log("parseRom: Invalid file length - Trainer");
					validFile = false;
					return;
				}
				trainerRom = new ByteArray();
				romData.readBytes(trainerRom, 0, 512);
				emulatorView.log("parseRom: 512-byte trainer at $7000-$71FF");
			}
			
			// Read PRG Rom Data
			prgRom = new ByteArray();
			
			if (romData.bytesAvailable < prgRomSize)
			{
				emulatorView.log("parseRom: Invalid file lenth - PRG ROM");
				validFile = false;
				return;
			}
			romData.readBytes(prgRom, prgRomSize);
			emulatorView.log("parseRom: PRG ROM Size: " + prgRomSize);
			
			chrRom = new ByteArray();
			// Read CHR Rom Data
			if (chrRomSize && chrRomSize <= romData.bytesAvailable)
			{
				romData.readBytes(chrRom, 0, chrRomSize);
				emulatorView.log("parseRom: CHR ROM Size: " + chrRomSize);
			}
			
			emulatorView.log("parseRom: PRG RAM Size: " + prgRamSize);
			if (romData.bytesAvailable == 0)
			{
				emulatorView.log("parseRom: Finished Parsing ROM");
			}
			else
			{
				emulatorView.log("parseRom: " + romData.bytesAvailable + " bytes unparsed");
			}
			
		}
		
	}

}