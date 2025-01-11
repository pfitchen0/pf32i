MEMORY
{
    RAM (RWX) : ORIGIN = 0x080000000, LENGTH = 16k /* 16kB RAM */
}

SECTIONS
{
    everything :
    {
        . = ALIGN(4);
        *(.*) 
    } > RAM
    
    ENTRY(start) 
}