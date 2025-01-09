MEMORY
{
   RAM (RWX) : ORIGIN = 0x080000000, LENGTH = 0x4000  /* 16kB RAM */
}
SECTIONS
{
    everything :
    {
	. = ALIGN(4);
	firmware.o (.text)
        *(.*)
    } >RAM
}