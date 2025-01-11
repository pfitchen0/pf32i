#define GPIO_ADDR 0x40000000

void wait(void) {
  volatile unsigned int t0 = 1 << 8; 
  while (t0 != 0) {
    t0--;
  }
}

int main (void) {
  volatile unsigned int *gp = (unsigned int *)GPIO_ADDR;

  while (1) {
    *gp = 0;
    wait();
    *gp = 1;
    wait();
  }

  return 0;
}