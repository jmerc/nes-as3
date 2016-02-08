package system 
{
	import interfaces.IMapper;
	import system.Mappers.*;
	/**
	 * ...
	 * @author John
	 */
	public class MapperFactory 
	{
		static private const SUPPORTED_MAPPERS:Object = {
			0: Mapper0,
			1: Mapper1,
			2: Mapper2,
			4: Mapper4
		}
		
		static public function createMapper(mapperID:uint, nes:NES):IMapper
		{
			var mapper:Class = SUPPORTED_MAPPERS[mapperID];
			if (mapper == null) { return null; }
			return new mapper(nes) as IMapper;
		}
		
		static public function mapperSupported(mapperID:uint):Boolean
		{
			return SUPPORTED_MAPPERS.hasOwnProperty(mapperID);
		}
		
	}

}