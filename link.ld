MEMORY
{
    RAM (RWX) : ORIGIN = 0x80000000, LENGTH = 16k
}

SECTIONS
{
    everything :
    {
        . = ALIGN(4);
        *(.*) 
    } > RAM
    
    ENTRY(_start) 
}