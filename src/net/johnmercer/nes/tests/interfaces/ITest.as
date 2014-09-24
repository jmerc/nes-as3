package net.johnmercer.nes.tests.interfaces
{
	import net.johnmercer.nes.system.CPU;
	import net.johnmercer.nes.system.MapperService;
	import net.johnmercer.nes.system.ROM;
	
	public interface ITest 
	{
		function startTest(cpu:CPU, rom:ROM):void
	}
	
}