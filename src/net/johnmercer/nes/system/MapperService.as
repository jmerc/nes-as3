// Todo - make subclasses Mapper0, Mapper1, etc..
// and have Mapper.as return a reference to the specific mapper

package net.johnmercer.nes.system 
{
	import net.johnmercer.nes.system.Mappers.*;
	import net.johnmercer.nes.views.*;
	/**
	 * ...
	 * @author John Owen Mercer
	 */
	public class MapperService 
	{
		
		public function MapperService(emulator:Emulator) 
		{
		}
		
		public static function getMapper(emulator:Emulator, rom:ROM):IMapper
		{
			var mapper:IMapper;
			switch (rom.mapper)
			{
				case 0:
					mapper = new Mapper0(emulator);
					break;
				case 1:
					mapper = new Mapper1(emulator);
					break;
				default:
					emulator.log("Mapper ID: " + rom.mapper + " not yet supported");
					return null;
					break;
			}
			mapper.loadRom(rom);
			return mapper;
		}
		
		
	}

}