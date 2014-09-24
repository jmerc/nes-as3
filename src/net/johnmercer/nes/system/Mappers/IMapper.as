package net.johnmercer.nes.system.Mappers 
{
	import net.johnmercer.nes.system.*;
	public interface IMapper 
	{
		function loadRom(rom:ROM):void
		
		// TODO: Cartridge Expansion Rom
		
		function readPrgRamByte(addr:uint):int;
		function readPrgRamUnsignedByte(addr:uint):uint;
		function readPrgRamWord(addr:uint):int;
		function readPrgRamUnsignedWord(addr:uint):uint;
		function writePrgRamByte(addr:uint, value:uint):void;
		
		function readPrgRomByte(addr:uint):int;
		function readPrgRomUnsignedByte(addr:uint):uint;
		function readPrgRomWord(addr:uint):int;
		function readPrgRomUnsignedWord(addr:uint):uint;
		function writePrgRomByte(addr:uint, value:uint):void;
		
	}
	
}